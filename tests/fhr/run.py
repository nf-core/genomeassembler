#!/usr/bin/env python3
"""Exercise the real FHR-Nextflow composition without running genome assembly."""
import argparse
import gzip
import json
import os
from pathlib import Path
import subprocess
import tempfile
from datetime import datetime
from zoneinfo import ZoneInfo

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--nextflow', default='nextflow')
parser.add_argument('--profile', choices=['docker'], help='Run FHR command tasks in the bundled container')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]


def run(directory, config, *, success=True, unsafe_id=False, disabled=False):
    (directory / 'metadata.json').write_text(json.dumps(config), encoding='utf-8')
    completed = subprocess.run(
        [args.nextflow, 'run', 'main.nf', '-ansi-log', 'false',
         '--metadata', str(directory / 'metadata.json'), '--unsafe_id', str(unsafe_id).lower(),
         '--disable_export', str(disabled).lower(), '-with-trace', 'trace.txt',
         *(['-profile', args.profile] if args.profile else [])],
        cwd=directory, env=os.environ, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    diagnostics = completed.stdout
    if completed.returncode != 0:
        # Nextflow can wrap an imported function's exception without displaying
        # its cause on stdout. Check the detailed log for rejection diagnostics.
        log = directory / '.nextflow.log'
        if log.exists():
            diagnostics += '\n' + log.read_text()
    if (completed.returncode == 0) != success:
        raise AssertionError(diagnostics)
    return diagnostics


with tempfile.TemporaryDirectory(prefix='genomeassembler-fhr-') as temporary:
    work = Path(temporary)
    # Deliberately preserve CRLF and use matching basenames from separate directories.
    body = b'>contig1\r\nACGTACGT\r\n>contig2\r\nGCGC\r\n'
    (work / 'a').mkdir()
    (work / 'b').mkdir()
    (work / 'a/genome.fa').write_bytes(body)
    (work / 'b/genome.fa.gz').write_bytes(gzip.compress(body))
    (work / 'nextflow.config').write_text(f'''
nextflow.enable.dsl = 2
trace.overwrite = true
params.outdir = '{work}/results'
params.publish_dir_mode = 'copy'
params.fhr_container = 'fhr-nextflow:0.1.0'
includeConfig '{root}/conf/modules/fhr.config'
profiles {{ docker {{ docker.enabled = true }} }}
''')
    (work / 'main.nf').write_text(f'''
include {{ FHR_EXPORT; loadFhrConfig; fhrRecord; assemblyOutputs }} from '{root}/subworkflows/local/fhr/main'
workflow {{
    config = loadFhrConfig(params.metadata)
    assert assemblyOutputs([strategy: 'single', assembler_hifi: 'hifiasm',
        assembly: file('a/genome.fa'), polished: [polished_dorado: file('b/genome.fa.gz')]])
        .any {{ it[1] == 'polish_dorado' }}
    samples = Channel.of(
        [id: params.unsafe_id.toString() == 'true' ? '../bad' : 'alpha-hap1', source_sample: 'alpha', strategy: 'single',
         assembler_hifi: 'hifiasm', assembly: file('a/genome.fa'),
         scaffolds: [hic: file('b/genome.fa.gz')]],
        [id: 'beta', strategy: 'single', assembler_hifi: 'flye', assembly: file('b/genome.fa.gz')]
    )
    records = samples.flatMap {{ meta -> assemblyOutputs(meta) }}
        .map {{ meta, stage, assembly, subdir -> fhrRecord(meta, stage, assembly, config) }}
    FHR_EXPORT(params.disable_export.toString() == 'true' ? Channel.empty() : records)
}}
''')
    config = {
        'defaults': {
            'schema': 'https://raw.githubusercontent.com/FAIR-bioHeaders/FHR-Specification/v0.3.0/fhr.json',
            'schemaVersion': 1, 'version': '1.0',
            'metadataAuthor': [{'name': 'Synthetic author'}],
            'assemblyAuthor': [{'name': 'Synthetic assembler'}],
            'masking': 'not-masked',
        },
        'samples': {
            'alpha': {'genome': "Synthetic α ' $() ` example", 'taxon': {'name': 'Synthetic taxon', 'uri': 'https://identifiers.org/taxonomy:9606'}},
            'beta': {'genome': 'Synthetic beta', 'taxon': {'name': 'Synthetic taxon', 'uri': 'https://identifiers.org/taxonomy:9606'}},
        },
    }
    # A supplied historical date must be replaced by today's date.
    config['defaults']['dateCreated'] = '2000-01-01'
    run(work, config)
    yaml_files = sorted((work / 'results').rglob('*.fhr.yaml'))
    assert len(yaml_files) == 3, yaml_files
    expected = {'alpha-hap1-initial_assembly', 'alpha-hap1-scaffold_hic', 'beta-initial_assembly'}
    assert {path.name.removesuffix('.fhr.yaml') for path in yaml_files} == expected
    from fhr.cli import checksum, read_metadata, strip_header
    for yaml_path in yaml_files:
        fasta = yaml_path.with_suffix('.fasta')
        assert fasta.is_file(), fasta
        assert strip_header(fasta.read_bytes(), 'fasta') == body
        data = read_metadata(yaml_path)
        data.fhr_validate()
        assert data.dateCreated == datetime.now(ZoneInfo('America/Detroit')).date().isoformat()
        assert data.checksum == checksum(fasta.read_bytes(), 'fasta')
        assert data.genome == config['samples']['alpha' if yaml_path.name.startswith('alpha') else 'beta']['genome']
        result = subprocess.run(['fhr-fasta-validate', str(fasta)], capture_output=True, text=True)
        assert result.returncode == 0, result.stderr
    print('PASS: three YAML/FASTA pairs, compressed/plain input, CRLF preservation, per-sample metadata, haplotype inheritance and real checksums')
    # Derived sample overrides replace whole top-level fields without altering defaults.
    config['samples']['alpha-hap1'] = {'genome': 'Haplotype override', 'taxon': config['samples']['alpha']['taxon']}
    run(work, config)
    assert read_metadata(yaml_files[0]).genome == 'Haplotype override'
    print('PASS: explicit haplotype override')
    del config['samples']['beta']
    assert 'missing metadata' in run(work, config, success=False)
    config['samples']['beta'] = {'genome': 'Synthetic beta', 'taxon': config['samples']['alpha']['taxon']}
    invalid = json.loads(json.dumps(config))
    del invalid['defaults']['assemblyAuthor']
    assert 'assemblyAuthor' in run(work, invalid, success=False)
    invalid = json.loads(json.dumps(config))
    invalid['defaults']['made_up_field'] = True
    assert 'made_up_field' in run(work, invalid, success=False)
    rejected_id = run(work, config, success=False, unsafe_id=True)
    assert 'meta.id' in rejected_id, rejected_id
    print('PASS: missing sample, required field, unknown FHR field and unsafe output ID are rejected')
    run(work, config, disabled=True)
    assert len((work / 'trace.txt').read_text().splitlines()) == 1
    print('PASS: disabled export schedules no FHR tasks')
