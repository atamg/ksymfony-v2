
# ksymfony

A minimal Symfony app with container and deployment artifacts; ready to run locally and deploy to AWS.

## Overview

- Small Symfony app with a simple health-check controller.
- Multi-stage Docker build producing a production-ready PHP-FPM image.
- `docker-compose.yml` for local development (PHP + Nginx).
- Terraform to provision an EC2 host, ECR repository, and related infrastructure.
- GitHub Actions workflows to provision infra, run CI, scan images, build/push images, and deploy to EC2.

## Architecture at a glance

- App: PHP 8.3 + Symfony (sources in `src/`). The app exposes basic health endpoints (`/healthz`, `/readyz`).
- Containers: a multi-stage `Dockerfile` produces a small PHP-FPM runtime image; Nginx serves static assets and proxies requests to PHP-FPM in container setups.
- Local development: `docker-compose.yml` runs Nginx and PHP-FPM so you can develop against an environment close to production.
- Production infra: Terraform (under `infra/terraform/`) provisions an ECR repository and a single EC2 host. The host runs Docker and Docker Compose; CI pushes images to ECR and the host pulls and runs the compose stack under `/opt/app`.
- CI/CD: GitHub Actions build, scan (Trivy), and push images to ECR, then deploy to the EC2 host via SSH/SCP. Workflows use OIDC role assumption to avoid long-lived AWS credentials.


## Quick start - run locally

### Local requirements
- Docker Engine
- Docker Compose v2 (the `docker compose` CLI)
- GNU Make (used for convenient targets in this repo)
- (Optional) PHP 8.3 + Composer if you prefer running tests and static checks locally (outside containers)

### Using the Makefile

This repository includes a simple `Makefile` with convenient targets. From the project root run:

```bash
# show available targets
make help

# build & start services (docker-compose)
make up

# stop containers
make down

# tail logs (follow)
make logs

# run PHPUnit tests (requires vendor/ populated)
make test

# fix coding style using php-cs-fixer
make cs

# run static analysis (PHPStan)
make stan
```

You can still use `docker compose up --build` directly if you prefer.

### Run tests & checks locally (alternative)

If you have PHP and Composer installed locally you can run the commands directly:

```bash
composer install
./vendor/bin/phpunit --testdox
./vendor/bin/phpstan analyse --memory-limit=1G
./vendor/bin/php-cs-fixer fix --dry-run --diff
```

## CI/CD overview
- `release-infra.yml`: runs Terraform (S3 backend) to provision infra (tag push or manual).
- `release-build-deploy.yml`: runs tests and scans, builds and pushes images to ECR, and deploys to EC2 via SSH/SCP.
- `destroy-infra.yml`: manual Terraform destroy workflow.

### Security considerations
- Workflows use OIDC to assume roles (`TF_AWS_ROLE_ARN`, `APP_AWS_ROLE_ARN`).
- The deploy step briefly allows access from the Actions runner IP, copies the compose files to `/opt/app` on the instance, runs `docker compose pull` and `docker compose up -d`, then revokes access.
- Trivy is used in workflows to scan source code, configuration, and images for vulnerabilities and misconfigurations before deployment.

### Required GitHub vars & secrets
Set these in Settings → Secrets and variables → Actions.

### Vars (non-sensitive)
- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_VAR_GITHUB_OWNER`
- `TF_VAR_GITHUB_REPO`

### Secrets (sensitive)
- `TF_AWS_ROLE_ARN` (Terraform OIDC role)
- `TF_VAR_VPC_ID`, `TF_VAR_SUBNET_ID`, `TF_VAR_KEYPAIR`
- `TF_VAR_EXTRA_SSH_PUBLIC_KEYS` (optional)
- `TF_VAR_USER_ALLOWED_IP_LIST` (optional)
- `APP_AWS_ROLE_ARN` (build/push OIDC role)
- `EC2_USER`, `EC2_SSH_KEY`, `EC2_HOST_FINGERPRINT` (for SCP/SSH deploy)

## Troubleshooting
- Missing secrets/vars → add the keys in GitHub settings.
- Terraform permission errors → confirm the IAM role trust and required policies.
- SSH issues on deploy → verify `EC2_USER`, `EC2_SSH_KEY`, and `EC2_HOST_FINGERPRINT`.

## Next improvements
- Move to ECS/EKS for scale and zero-downtime deployments.
- Add smoke tests executed as part of the deploy.
- Serve TLS via an ALB + ACM.

