############################################
# Download + verify stage
############################################
FROM alpine:3.24.1 AS build

# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION=1.15.6
# Provided automatically by buildx (linux/amd64 -> amd64, linux/arm64 -> arm64)
ARG TARGETARCH

# Build stage labels
LABEL org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/RagedUnicorn/docker-terraform" \
      org.opencontainers.image.licenses="MIT"

# Tools needed to download and cryptographically verify the release
RUN apk add --no-cache --update curl unzip gnupg

WORKDIR /tmp/build

# Download the Terraform release, then verify it end to end:
#   1. gpg-verify SHA256SUMS against SHA256SUMS.sig using HashiCorp's public key
#   2. verify the zip's checksum against the now-trusted SHA256SUMS
RUN set -eux; \
    base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"; \
    file="terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    sums="terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    curl -fsSLO "${base}/${file}"; \
    curl -fsSLO "${base}/${sums}"; \
    curl -fsSLO "${base}/${sums}.sig"; \
    # HashiCorp's published GPG public key (also mirrored on keybase.io/hashicorp
    curl -fsSL https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import; \
    gpg --verify "${sums}.sig" "${sums}"; \
    grep " ${file}\$" "${sums}" > "${file}.sha256"; \
    [ -s "${file}.sha256" ]; \
    sha256sum -c "${file}.sha256"; \
    unzip "${file}" terraform -d /out; \
    /out/terraform version

############################################
# Runtime stage
############################################
FROM alpine:3.24.1

ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="Terraform on Alpine Linux" \
      org.opencontainers.image.description="Lightweight Terraform CLI Docker image built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/RagedUnicorn/docker-terraform" \
      org.opencontainers.image.documentation="https://github.com/RagedUnicorn/docker-terraform/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.1"

# Runtime dependencies:
#   git            - Terraform shells out to git for git-sourced modules
#   openssh        - git-over-ssh module sources
#   ca-certificates - HTTPS to provider/module registries and remote backends
RUN apk add --no-cache --update git openssh ca-certificates

# Allow git to operate on bind-mounted working copies owned by another uid,
# avoiding "detected dubious ownership" errors for git-sourced modules.
RUN git config --system --add safe.directory '*'

# Non-root user with a real home so Terraform can write its CLI config,
# checkpoint cache and (optionally) a plugin cache under $HOME/.terraform.d.
# Pre-create the plugin cache dir so a named volume mounted there inherits
# terraform's ownership instead of being created root-owned and unwritable.
RUN adduser -D -h /home/terraform -s /sbin/nologin terraform && \
    mkdir -p /home/terraform/.terraform.d/plugin-cache && \
    chown -R terraform:terraform /home/terraform

COPY --from=build /out/terraform /usr/local/bin/terraform

WORKDIR /workspace
RUN chown -R terraform:terraform /workspace

USER terraform

# Terraform is the entrypoint; pass any subcommand/flags as `docker run` args
ENTRYPOINT ["terraform"]

# Default to showing help if no arguments are provided
CMD ["--help"]
