// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

def sampleId(Map meta) {
    def id = meta.id
    if (!(id instanceof String) || !(id ==~ /[A-Za-z0-9][A-Za-z0-9_.-]*/))
        throw new IllegalArgumentException('meta.id must contain only letters, digits, dot, underscore or hyphen, starting with a letter or digit')
    return id
}

def quote(Object value) {
    return "'" + value.toString().replace("'", "'\"'\"'") + "'"
}

def metadataJson(Map fields) {
    // Serialization only: the converter owns all schema and format validation.
    return groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(fields)) + '\n'
}
