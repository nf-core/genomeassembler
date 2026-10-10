#!/usr/bin/env python3
"""Exercise the real FHR-Nextflow composition without running genome assembly."""
import argparse
import csv
import shutil
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


def run(directory, config, *, success=True, sample_id=None, disabled=False):
    (directory / 'metadata.json').write_text(json.dumps(config), encoding='utf-8')
    completed = subprocess.run(
        [args.nextflow, 'run', 'main.nf', '-ansi-log', 'false',
         '--metadata', str(directory / 'metadata.json'),
         *(['--sample_id', sample_id] if sample_id else []),
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
    (work / 'nextflow.config').write_text('''
nextflow.enable.dsl = 2
trace.overwrite = true
params.sample_id = null
params.outdir = '@WORK@/results'
params.publish_dir_mode = 'copy'
params.fhr_container = 'fhr-nextflow:0.1.0'
includeConfig '@ROOT@/conf/modules/fhr.config'
profiles { docker { docker.enabled = true } }
'''.replace('@ROOT@', str(root)).replace('@WORK@', str(work)))
    (work / 'main.nf').write_text('''
include { FHR_EXPORT; loadFhrConfig; fhrRecord; assemblyOutputs; fhrSampleId } from '@ROOT@/subworkflows/local/fhr/main'
include { addPolishedAssembly } from '@ROOT@/subworkflows/local/polishing/utils'
workflow {
    config = loadFhrConfig(params.metadata)
    assert assemblyOutputs([strategy: 'single', assembler_hifi: 'hifiasm',
        assembly: file('a/genome.fa'), polished: [polished_dorado: file('b/genome.fa.gz')]])
        .any { it[1] == 'polish_dorado' }
    // Exercise the same helper used by Medaka, Dorado and Pilon production paths.
    first = addPolishedAssembly([polished: [:]], 'medaka', file('a/genome.fa'))
    second = addPolishedAssembly(first, 'pilon', file('b/genome.fa.gz'))
    third = addPolishedAssembly(second, 'dorado', file('a/genome.fa'))
    assert first.polished.keySet() == ['medaka'] as Set
    assert third.polished.keySet() == ['medaka', 'pilon', 'dorado'] as Set
    legacy = addPolishedAssembly([polished: [polished_dorado: file('a/genome.fa')]], 'pilon', file('b/genome.fa.gz'))
    assert legacy.polished.keySet() == ['dorado', 'pilon'] as Set
    ids = ['sample+1', 'sample:1', '../bad', 'fhr-encoded-73616d706c652b31']
    assert ids.collect { fhrSampleId(it) }.toSet().size() == ids.size()
    samples = Channel.of(
        [id: params.sample_id ?: 'alpha-hap1', source_sample: 'alpha', strategy: 'single',
         assembler_hifi: 'hifiasm', assembly: file('a/genome.fa'),
         scaffolds: [hic: file('b/genome.fa.gz')], polished: third.polished],
        [id: 'beta', strategy: 'single', assembler_hifi: 'flye', assembly: file('b/genome.fa.gz')]
    )
    records = samples.flatMap { meta -> assemblyOutputs(meta) }
        .map { meta, stage, assembly, subdir -> fhrRecord(meta, stage, assembly, config) }
    // Duplicate stage records mimic parallel Hi-C/RagTag final rows.
    FHR_EXPORT(params.disable_export.toString() == 'true' ? Channel.empty() : records.flatMap { record -> [record, record] })
}
'''.replace('@ROOT@', str(root)).replace('@WORK@', str(work)))
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
    assert len(yaml_files) == 6, yaml_files
    expected = {'alpha-hap1-' + stage for stage in ['initial_assembly', 'scaffold_hic', 'polish_medaka', 'polish_pilon', 'polish_dorado']} | {'beta-initial_assembly'}
    assert {path.name.removesuffix('.fhr.yaml') for path in yaml_files} == expected
    with (work / 'trace.txt').open() as trace:
        tasks = list(csv.DictReader(trace, delimiter='\t'))
    assert sum('FHR_PREPARE_SEQUENCE' in task['name'] for task in tasks) == 6
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
    print('PASS: six unique YAML/FASTA pairs including all retained polish stages, compressed/plain input, CRLF preservation, per-sample metadata, haplotype inheritance and real checksums')
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
    print('PASS: missing sample, required field and unknown FHR field are rejected')
    # Preserve the samplesheet-ID contract while keeping internal filenames safe.
    for sample in ['sample+1', 'sample:1', '../bad', 'fhr-encoded-73616d706c652b31']:
        shutil.rmtree(work / 'results')
        config['samples'][sample] = {'genome': sample, 'taxon': config['samples']['alpha']['taxon']}
        run(work, config, sample_id=sample)
        encoded = 'fhr-encoded-' + sample.encode('utf-8').hex()
        outputs = list((work / 'results' / encoded).rglob('*.fhr.yaml'))
        assert len(outputs) == 5, outputs
        assert all(path.name.startswith(encoded + '-') for path in outputs)
        assert all(read_metadata(path).genome == sample for path in outputs)
    print('PASS: punctuation, traversal-like IDs and encoding-prefix collisions are safely encoded')
    run(work, config, disabled=True)
    assert len((work / 'trace.txt').read_text().splitlines()) == 1
    print('PASS: disabled export schedules no FHR tasks')
