# SPDX-License-Identifier: MPL-2.0
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

FROM python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
# Nextflow task tracing requires ps inside the container.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
RUN python -m pip install --no-cache-dir \
    'jsonschema[format]==4.26.0' 'PyYAML==6.0.3' 'pytest==8.4.2' \
    'https://github.com/FAIR-bioHeaders/FHR-File-Converter/releases/download/v0.3.0/fhr-0.3.0-py3-none-any.whl#sha256=6cbd55f3fa8dc9fe5f7e0f1fb07c431589518eaa0fe50e7b381b3505d2625e62'
