# Testing Guide

This document describes how to test the Terraform Docker image using Container
Structure Tests.

## Quick Start

```bash
# Build the image locally first (single-platform, loaded into the daemon)
docker buildx build --load --provenance=false -t ragedunicorn/terraform:test .

# Run all tests
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml run test-all

# Run individual test suites
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test          # File structure
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test-command  # Command execution
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test-metadata # Metadata
```

## Test Structure

The test suite consists of three files:

### 1. File Structure Tests (`test/terraform_test.yml`)

Validates:

- The `terraform` binary exists at `/usr/local/bin/terraform` with the expected permissions
- The `/workspace` working directory exists
- `git` is present (required for git-sourced modules)
- CA certificates are present (required for registry/backend HTTPS)

### 2. Command Execution Tests (`test/terraform_command_test.yml`)

Validates:

- `terraform version` and `terraform --help` output
- The working directory is `/workspace`
- The container runs as the non-root `terraform` user
- `git` is available at runtime
- `terraform fmt` works on a writable config
- `terraform init` + `terraform validate` succeed on a trivial, offline config

### 3. Metadata Tests (`test/terraform_metadata_test.yml`)

Validates:

- OCI-compliant labels are present and correct
- The entrypoint is `terraform` and the default command is `--help`
- The working directory is `/workspace`
- The image runs as the `terraform` user

## Running Tests

### Prerequisites

1. Docker must be installed and running
2. Build the Terraform image locally before testing

### Important: Always Test Local Builds

**⚠️ Always build and test locally to ensure consistency:**

```bash
docker buildx build --load --provenance=false -t ragedunicorn/terraform:test .
```

> **Important: build a single-platform image.** Container Structure Tests
> inspect the image through the Docker daemon, which can only read a
> single-platform image. `--load` loads exactly one platform (your host's)
> into the daemon, and `--provenance=false` prevents BuildKit from wrapping the
> result in an attestation manifest. A plain `docker build` (or a `--platform`
> multi-arch / `--push` build) produces an OCI **image index** instead, and the
> tests fail with `no such image`. See
> [Troubleshooting](#error-no-such-image--error-retrieving-image-config) below.

**Linux/macOS:**

```bash
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

**Windows (PowerShell):**

```powershell
$env:TERRAFORM_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

**Windows (Command Prompt):**

```cmd
set TERRAFORM_VERSION=test && docker compose -f docker-compose.test.yml run test-all
```

**Why local testing is important:**
- Remote images (Docker Hub, GHCR) may have different labels due to CI/CD overrides
- Ensures you are testing exactly what you built
- Avoids false positives/negatives from version mismatches

**Never pull a remote image for testing** - build locally and test the `:test` tag.

### Running Specific Test Categories

**Linux/macOS:**

```bash
# File structure tests
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test

# Command execution tests
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test-command

# Metadata tests
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml up container-test-metadata
```

**Windows (PowerShell):**

```powershell
$env:TERRAFORM_VERSION="test"; docker compose -f docker-compose.test.yml up container-test
$env:TERRAFORM_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-command
$env:TERRAFORM_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-metadata
```

## Troubleshooting Test Failures

### Error: `no such image` / `error retrieving image config`

If every test fails immediately with output like:

```
ERRO[0000] error retrieving image config: Error when inspecting image: no such image
--- FAIL
Error: Error creating container: no such image
```

…the image tag almost certainly **exists**, but was built as a multi-platform
**OCI image index (manifest list)** rather than a single image. Container
Structure Tests inspect the image through the Docker daemon, which cannot read
an index, so it reports `no such image`.

Confirm the media type:

```bash
docker image inspect ragedunicorn/terraform:test --format '{{.Descriptor.MediaType}}'
```

- `application/vnd.oci.image.manifest.v1+json` → single image, good.
- `application/vnd.oci.image.index.v1+json` → manifest list, **this is the problem**.

Rebuild as a single-platform image loaded into the daemon, then re-run:

```bash
docker buildx build --load --provenance=false -t ragedunicorn/terraform:test .
TERRAFORM_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

This happens most often with the containerd image store enabled in Docker
Desktop, where `docker build` defaults to producing an index with attestations.

### Version-specific output

`terraform version` output changes with every Terraform release, so the command
tests match a stable prefix (`Terraform v`) rather than an exact version. If you
add stricter version assertions, remember to update them on every Renovate bump.

### Metadata Test Failures

**Common causes:**

1. **Testing remote images instead of local builds** - remote labels are
   overridden by CI/CD. Always test your local `:test` build.
2. **Label value mismatches** - the `org.opencontainers.image.version` and
   `created` labels are dynamic and set at build time.
3. **Alpine version drift** - if you bump Alpine, update both the
   `org.opencontainers.image.base.name` label in the Dockerfile and the
   matching value in `test/terraform_metadata_test.yml`.

### Permission Errors

If you encounter Docker socket permission errors:

```bash
sudo docker compose -f docker-compose.test.yml run test-all
```

Or ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker "$USER"
# Log out and back in for changes to take effect
```

## CI/CD Integration

These tests run automatically in GitHub Actions:

- **On every push** to `master`
- **On every pull request** to `master`
- **Before releases** (the release workflow runs the full suite first and blocks
  the build/push if it fails)

The test workflow (`.github/workflows/test.yml`):
1. Builds the Docker image
2. Runs all Container Structure Tests
3. Runs a basic functionality smoke test (`version`, then `init` + `validate` on
   a trivial config) to catch a broken binary or missing runtime dependency that
   `version` alone would not surface
4. Blocks releases if anything fails

The `test-all` service returns:
- Exit code 0: all tests passed
- Exit code 1: one or more tests failed

## Test Maintenance

When updating the image:

1. **Terraform version updates**: usually no test changes needed (version-prefix matching)
2. **Alpine version updates**: update the `base.name` label and metadata test value
3. **New functionality**: add corresponding tests
4. **Label changes**: update the metadata test to match

Always run the full test suite before creating a release.
