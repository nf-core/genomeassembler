# FHR-Nextflow source

Vendored unchanged from https://github.com/FAIR-bioHeaders/FHR-Nextflow at
commit `6fac9f57bf11d4e63461f2dca5f69d4856fa3cc8` (0.1.0-dev).
The reusable modules are MPL-2.0; see `upstream/LICENSE` and their source notices.
The Dockerfile is adapted from `environment/Dockerfile` to install `procps`,
which Nextflow requires for container task tracing. Converter and base-image pins
are unchanged.

FHR-File-Converter 0.3.0 supplies schema validation, conversion and checksums.
The upstream suite is an unreleased development prototype. No release or public
container image is implied by the local `fhr-nextflow:0.1.0` build tag.
