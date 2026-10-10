#!/usr/bin/env python3
"""Exercise real nf-schema initialization for single- and mixed-read QC choices."""
import argparse, gzip, os, shutil, subprocess, tempfile
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--nextflow', default='nextflow')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='qc-reads-') as temporary:
    work = Path(temporary)
    (work/'assets').mkdir()
    shutil.copy(root/'assets/schema_input.json', work/'assets/schema_input.json')
    shutil.copy(root/'nextflow_schema.json', work/'nextflow_schema.json')
    for name in ['hifi', 'ont']:
        (work/f'{name}.fastq.gz').write_bytes(gzip.compress(b'@read\nACGT\n+\nIIII\n'))
    (work/'samples.csv').write_text('sample,hifireads,ontreads,qc_reads\n'
        f'hifi,{work}/hifi.fastq.gz,,\n'
        f'ont,,{work}/ont.fastq.gz,hifi\n'
        f'mixed,{work}/hifi.fastq.gz,{work}/ont.fastq.gz,hifi\n')
    (work/'nextflow.config').write_text(f"includeConfig '{root}/nextflow.config'\nparams.input = '{work}/samples.csv'\nparams.outdir = '{work}/results'\n")
    (work/'main.nf').write_text(f'''
include {{ PIPELINE_INITIALISATION }} from '{root}/subworkflows/local/utils_nfcore_genomeassembler_pipeline/main'
workflow {{
    PIPELINE_INITIALISATION(false, false, true, [], params.outdir, params.input, false, false, false)
    PIPELINE_INITIALISATION.out.samplesheet.toList().subscribe {{ rows ->
        assert rows.size() == 3
        assert rows.find {{ it.meta.id == 'hifi' }}.meta.qc_reads == 'hifi'
        assert rows.find {{ it.meta.id == 'ont' }}.meta.qc_reads == 'ont'
        assert rows.find {{ it.meta.id == 'mixed' }}.meta.qc_reads == 'hifi'
        println 'PASS: single-read correction and mixed-read explicit selection'
    }}
}}
''')
    result = subprocess.run([args.nextflow, 'run', 'main.nf', '-ansi-log', 'false'], cwd=work,
                            env=os.environ, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout)
    if result.returncode: raise SystemExit(result.returncode)
    assert 'PASS:' in result.stdout
