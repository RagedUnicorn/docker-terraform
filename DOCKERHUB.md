# Terraform Alpine Docker Image

![Docker Terraform](https://raw.githubusercontent.com/RagedUnicorn/docker-terraform/master/docs/docker_terraform_banner.png)

A lightweight Terraform CLI build on Alpine Linux. The official Terraform release
is GPG- and checksum-verified at build time, then shipped as a non-root,
single-purpose image with `terraform` as its entrypoint.

## Quick Start

```bash
# Pull latest version
docker pull ragedunicorn/terraform:latest

# Or pull a specific version (see the Tags tab for the available versions)
docker pull ragedunicorn/terraform:<terraform-version>-alpine<alpine-version>-<build>

# Show the version
docker run --rm ragedunicorn/terraform:latest version

# Run against a configuration in the current directory
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
```

On Windows, use the PowerShell form - `${PWD}` **with braces** and the colon
inside the quotes (without braces PowerShell parses `$PWD:` as a
scope-qualified variable, as in `$env:PATH`, and rejects the argument):

```powershell
# Run against a configuration in the current directory
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform:latest init
```

## Features

- 🪶 **Small footprint**: minimal Alpine-based runtime image
- 🔐 **Verified download**: GPG signature and SHA256 checksum verified at build time
- 🎯 **Single purpose**: `terraform` is the entrypoint, nothing else bundled
- 🔒 **Runs as non-root**: executes as the unprivileged `terraform` user
- 🏗️ **Multi-platform**: supports `linux/amd64` and `linux/arm64`
- 🧩 **git + openssh-client + ca-certificates**: ready for module sources and registry/backend HTTPS

## Usage Examples

### Standard workflow

```bash
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest plan
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest apply
```

PowerShell:

```powershell
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform:latest init
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform:latest plan
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform:latest apply
```

### Match host user for bind-mount ownership

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
```

On Windows hosts this is not needed: Docker Desktop bind mounts do not carry
Unix file ownership, so `--user` matching has no effect (and `id` does not
exist in PowerShell).

### Persist the provider plugin cache

```bash
docker run --rm \
  -v "$(pwd)":/workspace \
  -v terraform-plugin-cache:/home/terraform/.terraform.d/plugin-cache \
  -e TF_PLUGIN_CACHE_DIR=/home/terraform/.terraform.d/plugin-cache \
  ragedunicorn/terraform:latest init
```

PowerShell:

```powershell
docker run --rm `
  -v "${PWD}:/workspace" `
  -v terraform-plugin-cache:/home/terraform/.terraform.d/plugin-cache `
  -e TF_PLUGIN_CACHE_DIR=/home/terraform/.terraform.d/plugin-cache `
  ragedunicorn/terraform:latest init
```

### Pass cloud credentials via the environment

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_REGION \
  -v "$(pwd)":/workspace ragedunicorn/terraform:latest apply
```

PowerShell:

```powershell
docker run --rm `
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_REGION `
  -v "${PWD}:/workspace" ragedunicorn/terraform:latest apply
```

## Runtime Notes

- **Writable working directory.** Terraform writes `terraform.tfstate`,
  `.terraform.lock.hcl` and `.terraform/`. Do not mount `/workspace` read-only.
- **Bind-mount ownership.** The container runs as the non-root `terraform` user;
  match your host user with `--user "$(id -u):$(id -g)"` so files stay yours.
- **Each subcommand is a separate invocation** (`init` → `plan` → `apply`).

## Tags

This image uses versioning that includes all component versions:

**Format:** `{terraform_version}-alpine{alpine_version}-{build_number}`

### Version Examples

`X.Y.Z` is the Terraform version, `A.B.C` the Alpine version:

- `X.Y.Z-alpineA.B.C-1` - Terraform X.Y.Z on Alpine A.B.C, first build
- `X.Y.Z-alpineA.B.C-2` - Rebuild of the same versions (base CVE patch, fixes)
- `X.Y.Z-alpineA.B.D-1` - Alpine Linux patch update
- `X.Y+1.0-alpineA.B.C-1` - Terraform version update (build resets to 1)
- `X.Y.Z` - Most recent build of Terraform X.Y.Z
- `latest` - Most recent stable release

The available versions are listed in the [Tags tab](https://hub.docker.com/r/ragedunicorn/terraform/tags).

## License

This image's build tooling is MIT-licensed. The bundled **Terraform binary** is
distributed by HashiCorp under the **Business Source License 1.1 (BSL-1.1)** -
source-available, not OSI open source. See the
[HashiCorp LICENSE](https://github.com/hashicorp/terraform/blob/main/LICENSE).
For a fully open source alternative, see [OpenTofu](https://opentofu.org/)
(MPL-2.0).

## Links

- **GitHub**: [https://github.com/RagedUnicorn/docker-terraform](https://github.com/RagedUnicorn/docker-terraform)
- **Issues**: [https://github.com/RagedUnicorn/docker-terraform/issues](https://github.com/RagedUnicorn/docker-terraform/issues)
- **Releases**: [https://github.com/RagedUnicorn/docker-terraform/releases](https://github.com/RagedUnicorn/docker-terraform/releases)
