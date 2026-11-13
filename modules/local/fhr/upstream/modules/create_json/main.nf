// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

include { metadataJson; sampleId } from '../utils/main'

process FHR_WRITE_JSON {
    tag "${meta.id}"

    input:
    tuple val(meta), val(fields)

    output:
    tuple val(meta), path("${meta.id}.fhr.json"), emit: json

    exec:
    def id = sampleId(meta)
    if (!(fields instanceof Map))
        throw new IllegalArgumentException('FHR fields must be a map')
    task.workDir.resolve("${id}.fhr.json").text = metadataJson(fields)
}
