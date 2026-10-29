// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

include { fhrFormat; quote; sampleId; versionCheck; versionReport } from '../utils/main'

process FHR_CONVERT {
    tag "${meta.id}: ${format}"
    label 'fhr'

    input:
    tuple val(meta), path(metadata, stageAs: 'input/*'), val(format)

    output:
    tuple val(meta), path("${meta.id}.fhr.${format}"), emit: converted
    tuple val(meta), path('versions.yml'), emit: versions

    script:
    def id = sampleId(meta)
    def ext = fhrFormat(format, ['json', 'yaml', 'html', 'fasta', 'gfa'])
    """
    ${versionCheck()}
    fhr-convert ${quote(metadata)} ${quote("${id}.fhr.${ext}")}
    ${versionReport()}
    """
}
