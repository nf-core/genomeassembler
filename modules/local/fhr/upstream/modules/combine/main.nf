// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

include { fhrFormat; quote; sampleId; versionCheck; versionReport } from '../utils/main'

process FHR_COMBINE {
    tag "${meta.id}: ${kind}"
    label 'fhr'

    input:
    tuple val(meta), path(metadata, stageAs: 'metadata/*'), path(sequence, stageAs: 'sequence/*'), val(kind)

    output:
    tuple val(meta), path("${meta.id}.fhr.${kind}"), emit: combined
    tuple val(meta), path('versions.yml'), emit: versions

    script:
    def id = sampleId(meta)
    def type = fhrFormat(kind, ['fasta', 'gfa'])
    """
    ${versionCheck()}
    fhr-${type}-combine ${quote(metadata)} ${quote(sequence)} -o ${quote("${id}.fhr.${type}")}
    ${versionReport()}
    """
}
