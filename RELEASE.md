# Release Process

This document describes how to create a new release for the Docker Terraform project.

## Quick Start

```bash
# Tag format: v{terraform_version}-alpine{alpine_version}-{build_number}
# Take the versions from the Dockerfile (TERRAFORM_VERSION and the FROM line)
TAG=v<terraform-version>-alpine<alpine-version>-<build>
git tag -a "$TAG" -m "$TAG"
git push origin "$TAG"
```

This automatically triggers the release process via GitHub Actions.

## Version Tag Format

See [README.md](README.md#versioning) for the complete versioning documentation.

**Format:** `v{terraform_version}-alpine{alpine_version}-{build_number}`

Examples (`X.Y.Z` is the Terraform version, `A.B.C` the Alpine version):
- `vX.Y.Z-alpineA.B.C-1` - First build of Terraform X.Y.Z on Alpine A.B.C
- `vX.Y.Z-alpineA.B.C-2` - Rebuild with the same versions
- `vX.Y.Z-alpineA.B.D-1` - Alpine patch update (build resets to 1)
- `vX.Y+1.0-alpineA.B.C-1` - Terraform update (build resets to 1)

## Release Workflow

When you push a tag, GitHub Actions automatically:

1. **Builds and tests, then pushes Docker images** (`.github/workflows/docker_release.yml`)
   - Runs the full Container Structure Test suite first and fails fast if it breaks
   - Multi-platform: `linux/amd64` and `linux/arm64`
   - Pushes to both GitHub Container Registry and Docker Hub
   - Attaches SBOM and provenance (`mode=max`) attestations
   - Signs the pushed digest in both registries with cosign keyless signing (GitHub OIDC)
   - Publishes the full tag (`X.Y.Z-alpineA.B.C-N`), a bare Terraform version
     tag (`X.Y.Z`) and `latest`

2. **Creates a GitHub Release** (`create-release` job in `.github/workflows/docker_release.yml`)
   - Runs only after the images were tested and pushed successfully
   - Generates a changelog from commit history
   - Adds Docker pull commands
   - Links to the release

## When to Create a Release

Create a new release when:

1. **Renovate updates dependencies** - after merging Renovate PRs for Terraform
   or Alpine updates
2. **Bug fixes** - after fixing issues in the Dockerfile or build process
3. **Security patches** - immediately after security-related updates

### Build Number Guidelines

- **Reset to 1**: when the Terraform or Alpine version changes
- **Increment**: when rebuilding with the same versions (base CVE patch, fixes)

## Post-Release Tasks

### Update Docker Hub Documentation

`DOCKERHUB.md` is the source of truth for the Docker Hub repository
description. It deliberately contains no concrete versions (readers find those
in the Tags tab), so a release alone does not require a description update.
Only when `DOCKERHUB.md` changed since the last sync:

1. Go to [Docker Hub](https://hub.docker.com/r/ragedunicorn/terraform)
2. Click "Manage Repository" → "Description"
3. Copy the contents of `DOCKERHUB.md`
4. Save the changes

**Note**: the sync stays manual on purpose. Docker Hub only offers an
undocumented endpoint for description updates, and it needs a separate
Read/Write/Delete access token.

## Best Practices

### Commit Messages

Use conventional commit format for better changelogs:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `chore:` Maintenance tasks
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `perf:` Performance improvements

### Pre-release Testing

Before creating a release:

1. Build the image locally with your version changes
2. Run the full test suite (`TERRAFORM_TEST_VERSION=test docker compose -f docker-compose.test.yml run test-all`)
3. Verify `terraform init` + `validate` work against a trivial config
4. Check that multi-platform builds work (especially arm64)

## Troubleshooting

### Release didn't trigger

- Ensure the tag starts with `v` and follows the format (e.g. `vX.Y.Z-alpineA.B.C-N`)
- Check the GitHub Actions tab for workflow runs
- Verify you have push permissions

### Docker build failed

- Check the Docker workflow logs
- Ensure the Dockerfile builds locally
- A failure at GPG/checksum verification means the download did not match the
  signed checksums - investigate, do not work around it
- Verify multi-platform compatibility

### Docker Hub Configuration

To enable Docker Hub deployment, add these secrets to the GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add:
   - `DOCKERHUB_USERNAME`: your Docker Hub username
   - `DOCKERHUB_TOKEN`: your Docker Hub access token (not your password)

To create a Docker Hub access token:
1. Log in to Docker Hub
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a descriptive name (e.g. "GitHub Actions")
5. Copy the token and add it as the `DOCKERHUB_TOKEN` secret

## Manual Release (if needed)

If automation fails, create a release manually:

1. Go to the repository's "Releases" page
2. Click "Create a new release"
3. Choose your tag (must follow the format: `vX.Y.Z-alpineA.B.C-N`)
4. Add release notes
5. Include Docker pull commands (the tag without the leading `v`):
   ```
   docker pull ghcr.io/ragedunicorn/docker-terraform:<tag>
   docker pull ragedunicorn/terraform:<tag>
   ```
