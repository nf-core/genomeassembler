include { quote; sampleId } from '../upstream/modules/utils/main'

process FHR_PREPARE_SEQUENCE {
    tag "${meta.id}"
    label 'fhr'

    input:
    tuple val(meta), val(fields), path(sequence, stageAs: 'input/*')

    output:
    tuple val(meta), val(fields), path('assembly.fasta'), emit: sequence

    script:
    sampleId(meta)
    """
    python - ${quote(sequence)} <<'PYTHON'
    import bz2
    import gzip
    import lzma
    import shutil
    import sys
    from pathlib import Path

    source = Path(sys.argv[1])
    opener = {'.gz': gzip.open, '.xz': lzma.open, '.bz2': bz2.open}.get(source.suffix, open)
    with opener(source, 'rb') as incoming, open('assembly.fasta', 'wb') as outgoing:
        shutil.copyfileobj(incoming, outgoing)
    PYTHON
    test -s assembly.fasta
    """
}
