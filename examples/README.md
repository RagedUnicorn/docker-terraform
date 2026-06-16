# Terraform Docker Examples

This directory contains a minimal Terraform configuration and a Docker Compose
file that demonstrates a realistic workflow with the image.

## Files

- `main.tf` - a trivial, provider-less configuration (no resources, no network).
  `init`, `validate`, `plan` and `apply` all run fully offline.
- `docker-compose.yml` - a workflow example with a writable workspace, host
  UID/GID matching, a persistent provider plugin cache and a place to inject
  cloud credentials.

## Running the Example

### Using Docker directly

```bash
# From the repository root - run each subcommand on its own.
# The workspace must be writable: Terraform writes state and the lock file here.
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform:latest init
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform:latest plan
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform:latest apply -auto-approve
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform:latest output
```

### Using Docker Compose

```bash
docker compose -f examples/docker-compose.yml run --rm terraform init
docker compose -f examples/docker-compose.yml run --rm terraform plan
docker compose -f examples/docker-compose.yml run --rm terraform apply
```

### Expected Output

`terraform apply` on this config creates no infrastructure and prints:

```
greeting = "Hello, world!"
```

Override the input variable to change the greeting:

```bash
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform:latest \
  apply -auto-approve -var name=terraform
```

## Notes for Real Configurations

- **Writable workspace.** Do not mount `/workspace` read-only - Terraform writes
  `terraform.tfstate`, `.terraform.lock.hcl` and `.terraform/`.
- **File ownership.** The image runs as the non-root `terraform` user. Match your
  host user with `--user "$(id -u):$(id -g)"` (docker run) or the `user:` field
  (compose) so generated files stay owned by you.
- **Provider cache.** `terraform init` downloads provider plugins (often hundreds
  of MB). The compose example mounts a named volume and sets
  `TF_PLUGIN_CACHE_DIR` so plugins survive across runs.
- **Credentials.** Pass cloud credentials via environment variables or a mounted
  credentials file - never bake them into an image.
