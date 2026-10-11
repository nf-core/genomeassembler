#!/usr/bin/env python3
"""Check phasing prerequisites and arguments through real samplesheet initialization."""
import argparse
import csv
import gzip
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--nextflow', default='nextflow')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='phasing-validation-') as temporary:
    work = Path(temporary)
    (work / 'assets').mkdir()
    for source, destination in [('assets/schema_input.json', 'assets/schema_input.json'),
                                ('nextflow_schema.json', 'nextflow_schema.json')]:
        shutil.copy(root / source, work / destination)
    for name in ['hifi', 'hic1', 'hic2']:
        (work / f'{name}.fastq.gz').write_bytes(gzip.compress(b'@read\nACGT\n+\nIIII\n'))
    (work / 'samples.csv').write_text('sample,hifireads,hic_F,hic_R,hifiasm_hic_phasing,hic_trim\n'
        f'sample,{work}/hifi.fastq.gz,{work}/hic1.fastq.gz,{work}/hic2.fastq.gz,true,false\n')
    (work / 'nextflow.config').write_text(f"includeConfig '{root}/nextflow.config'\n"
        f"params.input = '{work}/samples.csv'\nparams.outdir = '{work}/results'\n")
    (work / 'main.nf').write_text('''
include { PIPELINE_INITIALISATION } from '@ROOT@/subworkflows/local/utils_nfcore_genomeassembler_pipeline/main'
workflow {
    PIPELINE_INITIALISATION(false, false, true, [], params.outdir, params.input, false, false, false)
    PIPELINE_INITIALISATION.out.samplesheet.toList().subscribe { rows ->
        assert rows.size() == 1
        assert rows[0].meta.hifiasm_hic_phasing
        println 'PASS: compatible phasing arguments'
    }
}
'''.replace('@ROOT@', str(root)))
    cases = [(field, flag) for field in ['hifiasm_args', 'assembler_hifi_args']
             for flag in ['-1 paternal.yak', '-2 maternal.yak', '-1paternal.yak', '-2=maternal.yak']]
    for field, value in cases + [('hifiasm_args', '-f 0')]:
        (work / 'args.json').write_text(json.dumps({field: value}))
        result = subprocess.run([args.nextflow, 'run', 'main.nf', '-ansi-log', 'false',
                                 '-params-file', 'args.json'], cwd=work, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if value == '-f 0':
            assert result.returncode == 0 and 'PASS:' in result.stdout, result.stdout
        else:
            assert result.returncode != 0, result.stdout
            assert 'trio inputs -1 and -2 are incompatible' in result.stdout, result.stdout
        print(f'PASS: {field}={value}', flush=True)

    # Change actual samplesheet fields, keeping referenced files valid so failures
    # exercise the pipeline guards rather than missing-file/schema errors.
    (work / 'assembly.fa').write_text('>contig\nACGT\n')
    base = dict(sample='sample', hifireads=str(work / 'hifi.fastq.gz'),
                hic_F=str(work / 'hic1.fastq.gz'), hic_R=str(work / 'hic2.fastq.gz'),
                hifiasm_hic_phasing='true', hic_trim='false', strategy='single', assembler='hifiasm')
    prerequisite_error = 'requires single-strategy hifiasm assembly with HiFi reads only and no supplied assembly'
    invalid_cases = [
        ('derived hap1 collision', {}, 'derived haplotype IDs collide', 'sample-hap1'),
        ('derived hap2 collision', {}, 'derived haplotype IDs collide', 'sample-hap2'),
        ('hybrid strategy', dict(strategy='hybrid'), prerequisite_error, None),
        ('scaffold strategy', dict(strategy='scaffold', assembler='flye_hifiasm'), prerequisite_error, None),
        ('wrong assembler', dict(assembler='flye'), prerequisite_error, None),
        ('missing HiFi', dict(hifireads=''), prerequisite_error, None),
        ('ONT present', dict(ontreads=str(work / 'hifi.fastq.gz')), prerequisite_error, None),
        ('supplied assembly', dict(assembly=str(work / 'assembly.fa')), prerequisite_error, None),
        ('missing Hi-C forward', dict(hic_F=''), 'requires both hic_F and hic_R', None),
        ('missing Hi-C reverse', dict(hic_R=''), 'requires both hic_F and hic_R', None),
        ('trimmed Hi-C', dict(hic_trim='true'), 'requires untrimmed Hi-C reads', None),
    ]
    (work / 'args.json').write_text('{}')
    for label, overrides, expected, collision in invalid_cases:
        rows = [base | overrides]
        if collision:
            rows.append(base | dict(sample=collision, hifiasm_hic_phasing='false'))
        columns = sorted(set().union(*(row.keys() for row in rows)))
        with (work / 'samples.csv').open('w', newline='') as handle:
            writer = csv.DictWriter(handle, fieldnames=columns)
            writer.writeheader()
            writer.writerows(rows)
        result = subprocess.run([args.nextflow, 'run', 'main.nf', '-ansi-log', 'false',
                                 '-params-file', 'args.json'], cwd=work, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        assert result.returncode != 0 and expected in result.stdout, result.stdout
        print(f'PASS: {label}', flush=True)
