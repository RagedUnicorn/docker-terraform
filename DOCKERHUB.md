# Terraform Alpine Docker Image

![Docker Terraform](https://raw.githubusercontent.com/RagedUnicorn/docker-terraform/master/docs/docker_terraform.png)

A lightweight Terraform CLI build on Alpine Linux. The official Terraform release
is GPG- and checksum-verified at build time, then shipped as a non-root,
single-purpose image with `terraform` as its entrypoint.

## Quick Start

```bash
# Pull latest version
docker pull ragedunicorn/terraform:latest

# Or pull a specific version
docker pull ragedunicorn/terraform:1.9.8-alpine3.22.1-1

# Show the version
docker run --rm ragedunicorn/terraform:latest version

# Run against a configuration in the current directory
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
```

## Features

- 🪶 **Small footprint**: minimal Alpine-based runtime image
- 🔐 **Verified download**: GPG signature and SHA256 checksum verified at build time
- 🎯 **Single purpose**: `terraform` is the entrypoint, nothing else bundled
- 🔒 **Runs as non-root**: executes as the unprivileged `terraform` user
- 🏗️ **Multi-platform**: supports `linux/amd64` and `linux/arm64`
- 🧩 **git + openssh + ca-certificates**: ready for module sources and registry/backend HTTPS

## Usage Examples

### Standard workflow

```bash
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest plan
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform:latest apply
```

### Match host user for bind-mount ownership

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace ragedunicorn/terraform:latest init
```

### Persist the provider plugin cache

```bash
docker run --rm \
  -v "$(pwd)":/workspace \
  -v terraform-plugin-cache:/home/terraform/.terraform.d/plugin-cache \
  -e TF_PLUGIN_CACHE_DIR=/home/terraform/.terraform.d/plugin-cache \
  ragedunicorn/terraform:latest init
```

### Pass cloud credentials via the environment

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_REGION \
  -v "$(pwd)":/workspace ragedunicorn/terraform:latest apply
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

- `1.9.8-alpine3.22.1-1` - Initial release with Terraform 1.9.8 and Alpine 3.22.1
- `1.9.8-alpine3.22.1-2` - Rebuild of the same versions (base CVE patch, fixes)
- `1.9.8-alpine3.22.2-1` - Alpine Linux patch update
- `1.10.0-alpine3.22.1-1` - Terraform version update (build resets to 1)

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
