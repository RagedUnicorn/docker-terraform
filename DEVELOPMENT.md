# Development Guide

This document provides information for developers working on the Terraform Docker
image.

## Development Environment

### Prerequisites

- Docker installed and running (with BuildKit / buildx)
- Docker Compose installed

### Project Structure

```
docker-terraform/
├── Dockerfile               # Multi-stage: verified download + minimal runtime
├── docker-compose.yml       # Basic usage configuration
├── docker-compose.dev.yml   # Development environment (shell)
├── docker-compose.test.yml  # Test orchestration
├── .env                     # Default environment variables
├── examples/                # Runnable example configuration
│   ├── docker-compose.yml   # Workflow example (cache + credentials)
│   ├── main.tf              # Trivial, provider-less config
│   └── README.md
├── test/                    # Container Structure Tests
│   ├── terraform_test.yml
│   ├── terraform_command_test.yml
│   └── terraform_metadata_test.yml
└── docs/                    # Documentation assets
```

## How the Image Is Built

The Dockerfile uses two stages:

1. **Download + verify stage** - installs `curl`, `unzip`, `gnupg`, downloads the
   Terraform release zip, the `SHA256SUMS` file and its `.sig`, imports
   HashiCorp's GPG public key, verifies the signature on `SHA256SUMS`, then
   verifies the zip against that checksum and unzips the single `terraform`
   binary. **This verification is the whole point of building our own image and
   must never be skipped.**
2. **Runtime stage** - a clean Alpine image with `git`, `openssh` and
   `ca-certificates`, a non-root `terraform` user, and the verified binary copied
   in from the build stage.

The Terraform version is pinned via `ARG TERRAFORM_VERSION` and updated by
Renovate using the `# renovate:` comment above it. `TARGETARCH` is supplied
automatically by buildx (and by BuildKit for single-platform `docker build`),
which lines up with Terraform's zip arch naming (`amd64`, `arm64`).

## Development Workflow

### 1. Local Development Mode

The `docker-compose.dev.yml` file provides an interactive shell built from the
local Dockerfile:

```bash
# Build the image locally
docker compose -f docker-compose.dev.yml build

# Drop into a shell to run terraform manually
docker compose -f docker-compose.dev.yml run --rm terraform-dev

# Inside the container
terraform version
terraform -chdir=/workspace init
```

### 2. Building the Image

```bash
# Basic build (BuildKit supplies TARGETARCH automatically)
docker build -t ragedunicorn/terraform:dev .

# Build with version metadata
docker build \
  --build-arg TERRAFORM_VERSION=1.9.8 \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION=1.9.8-alpine3.22.1-1 \
  -t ragedunicorn/terraform:1.9.8-alpine3.22.1-1 .

# Multi-platform build (requires buildx). Do NOT set TARGETARCH by hand.
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg TERRAFORM_VERSION=1.9.8 \
  --build-arg VERSION=1.9.8-alpine3.22.1-1 \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  -t ragedunicorn/terraform:1.9.8-alpine3.22.1-1 .
```

### 3. Testing Your Changes

After making changes, always build and test locally. Build a single-platform
image loaded into the daemon so the Container Structure Tests can inspect it (a
multi-platform / attestation build produces an OCI index that fails with
`no such image` — see [TEST.md](TEST.md#error-no-such-image--error-retrieving-image-config)):

```bash
docker buildx build --load --provenance=false -t ragedunicorn/terraform:test .
```

#### Running Tests (Cross-Platform)

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

**Important:** Never test against remote images - they may have different labels
or configurations due to CI/CD overrides.

See [TEST.md](TEST.md) for detailed testing information.

## Making Changes

### Version Updates

This project uses [Renovate](https://docs.renovatebot.com/) to manage updates:

- **Terraform**: tracked via the GitHub releases datasource; the `v` prefix is
  stripped via an `extractVersion` rule in `renovate.json`.
- **Alpine Linux**: tracked via the Docker datasource on the `FROM` lines; regex
  `customManagers` in `renovate.json` also keep the
  `org.opencontainers.image.base.name` label and the metadata test value in sync,
  so all four update together in one PR.

When Renovate creates a PR:

1. Review the changes
2. Check that CI passes all tests
3. Test the build locally for major updates
4. Merge if everything looks good

Manual updates are rarely needed. If required, edit `ARG TERRAFORM_VERSION` in
the Dockerfile (and the `FROM alpine:X.Y.Z` lines for Alpine), then rebuild and
test. When changing Alpine manually, update all four spots together — both
`FROM` lines, the `org.opencontainers.image.base.name` label, and the metadata
test value — since they are otherwise only kept in sync automatically by
Renovate.

## Code Style and Best Practices

### Dockerfile Best Practices

1. **Verify everything**: never skip the GPG/checksum verification
2. **Single purpose**: keep `terraform` as the only entrypoint - no extra tools
3. **Layer optimization**: group related commands to minimize layers
4. **Security**: run as the non-root `terraform` user
5. **Labels**: follow OCI naming conventions

### Documentation

1. **README.md**: keep focused on user-facing information
2. **Comments**: explain non-obvious build steps in the Dockerfile
3. **Examples**: provide working examples for new features
4. **Commit messages**: use conventional format (`feat:`, `fix:`, `docs:`, …)

## Debugging

### Common Issues

**Build failures (download/verify):**

```bash
# Verbose build output
docker build --progress=plain --no-cache -t ragedunicorn/terraform:debug .
```

A failure at `gpg --verify` or `sha256sum -c` means the download did not match
the published, signed checksums - investigate before doing anything else; do not
work around the verification.

**Terraform not working:**

```bash
docker run --rm --entrypoint sh ragedunicorn/terraform:dev -c "which terraform && terraform version"
```

**Permission errors on the workspace:**

```bash
# Run as your own user so the non-root container user can write
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace ragedunicorn/terraform:dev init
```

## Contributing

### Before Submitting Changes

1. Run the full test suite
2. Update documentation if needed
3. Add tests for new behavior
4. Follow the existing style
5. Write clear commit messages

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit using conventional commits
4. Push to your fork
5. Open a Pull Request with a clear description

### Release Process

See [RELEASE.md](RELEASE.md) for information about creating releases.
