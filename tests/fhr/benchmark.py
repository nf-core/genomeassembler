#!/usr/bin/env python3
"""Measure native converter commands on synthetic, uncompressed FASTA files.

Run with the Python environment from tests/fhr/requirements.txt. This measures
converter processes, not Nextflow, containers, assembly quality or concurrency.
"""
import argparse
from datetime import datetime
from importlib.metadata import version
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile
from zoneinfo import ZoneInfo

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--sizes-mib', type=int, nargs='+', default=[16, 64, 256])
parser.add_argument('--repeats', type=int, default=3)
parser.add_argument('--contigs', type=int, default=1000)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
if min(args.sizes_mib) <= 0 or args.repeats <= 0 or args.contigs <= 0:
    parser.error('sizes, repeats and contigs must be positive')
if sys.platform not in ('darwin', 'linux'):
    parser.error('RSS measurement supports macOS and Linux')
if version('fhr') != '0.3.0':
    parser.error('benchmark requires FHR-File-Converter 0.3.0')

# A fresh wrapper per command prevents cumulative RUSAGE_CHILDREN maxima from
# contaminating later measurements. ru_maxrss is bytes on macOS, KiB on Linux.
measurement = '''
import json, resource, subprocess, sys, time
start = time.monotonic()
subprocess.run(sys.argv[1:], check=True, stdout=subprocess.DEVNULL)
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
print(json.dumps(dict(seconds=time.monotonic()-start,
                     peak_rss_bytes=int(rss if sys.platform == 'darwin' else rss*1024))))
'''
results = []
for size in args.sizes_mib:
    for repeat in range(1, args.repeats + 1):
        with tempfile.TemporaryDirectory(prefix='fhr-memory-') as temporary:
            work = Path(temporary)
            fasta = work / 'input.fa'
            # Stream the fixture so its generation does not inflate measured RSS.
            with fasta.open('wb') as handle:
                for contig in range(args.contigs):
                    handle.write(f'>contig{contig}\n'.encode())
                    remaining = size * 1024**2 // args.contigs
                    block = (b'ACGT' * 20 + b'\n') * 1024
                    while remaining:
                        chunk = block[:min(remaining, len(block))]
                        handle.write(chunk)
                        remaining -= len(chunk)
                    handle.write(b'\n')
            metadata = dict(schema='https://raw.githubusercontent.com/FAIR-bioHeaders/FHR-Specification/v0.3.0/fhr.json', schemaVersion=1, version='1.0', genome='Synthetic benchmark',
                            taxon=dict(name='Synthetic taxon', uri='https://identifiers.org/taxonomy:9606'),
                            metadataAuthor=[dict(name='Benchmark')], assemblyAuthor=[dict(name='Synthetic')],
                            masking='not-masked', dateCreated=datetime.now(ZoneInfo('America/Detroit')).date().isoformat())
            (work / 'metadata.json').write_text(json.dumps(metadata))
            commands = [
                ('combine', ['fhr-fasta-combine', 'metadata.json', 'input.fa', '-o', 'annotated.fasta']),
                ('validate_fasta', ['fhr-fasta-validate', 'annotated.fasta']),
                ('extract_json', ['fhr-convert', 'annotated.fasta', 'extracted.json']),
                ('convert_yaml', ['fhr-convert', 'extracted.json', 'metadata.yaml']),
                ('validate_yaml', ['fhr-validate', 'metadata.yaml']),
            ]
            for step, command in commands:
                executable = shutil.which(command[0])
                if executable is None:
                    raise RuntimeError(f'Missing converter command: {command[0]}')
                measured = subprocess.run([sys.executable, '-c', measurement, executable, *command[1:]],
                                          cwd=work, check=True, text=True, stdout=subprocess.PIPE)
                record = dict(input_bytes=fasta.stat().st_size, requested_mib=size,
                              contigs=args.contigs, repeat=repeat, step=step, **json.loads(measured.stdout))
                results.append(record)
                print(f'{size} MiB repeat {repeat} {step}: {record["peak_rss_bytes"]/1024**2:.1f} MiB RSS', flush=True)
report = dict(converter_version=version('fhr'), python_version=platform.python_version(),
              system=platform.system(), machine=platform.machine(),
              measured_at=datetime.now(ZoneInfo('America/Detroit')).isoformat(), results=results)
args.output.write_text(json.dumps(report, indent=2) + '\n')
