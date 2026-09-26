# DevOps Final Assessment

**Name:** Adesewa Don-ojomo  
**Submission Date:** 26 September 2026

![CI/CD](https://github.com/donojomoadesewa-droid/devops-intern-final/actions/workflows/ci.yml/badge.svg)
┌──────────────┐
│    GitHub    │
│ Source Code  │
└──────┬───────┘
       ↓
┌──────────────┐
│GitHub Actions│
│      CI      │
└──────┬───────┘
       ↓
┌──────────────┐
│     GHCR     │
│   Registry   │
└──────┬───────┘
       ↓
┌──────────────┐
│    Nomad     │
│  Deployment  │
└──────┬───────┘
       ↓
┌──────────────┐
│     Loki     │
│    Logging   │
└──────────────┘
## Prerequisite
-Git version 2.55.0.windows.2
-Docker version 29.8.0, build 88096ef
-Bash version 5.3.15(1)
-Nomad v2.0.7
BuildDate 2026-09-17T17:24:03Z
Revision 9dcbdc5e64ecc4ec63e42b225af729c87c87cf83

## Quick Start

```bash
git clone https://github.com/donojomoadesewa-droid/devops-intern-final.git
cd devops-intern-final
docker build --provenance=false --sbom=false --build-arg BUILD_SHA=test123 -t nginx-app:latest ./app
docker run -d -p 8080:8080 --name nginx-test nginx-app:latest
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz

## Task 1 — Reference Application

The project is based on chakilams/simple-nginx-app, vendored into this repository under app/. The static index.html was modified to display the author's name, assessment date, and a build identifier injected at Docker build time (see Task 3). The original Kubernetes manifests were replaced with a HashiCorp Nomad job specification (see Task 5).

## Task 2 — Linux Scripting

Two POSIX-compliant shell scripts live under scripts/: sysinfo.sh (reports user, UID, hostname, kernel, ISO-8601 date, disk usage, memory usage, and Docker daemon status) and healthcheck.sh (accepts a target URL as $1, defaulting to http://localhost:8080, and exits 0/1 based on whether it receives a 200 response). Both begin with #!/bin/sh and set -euo pipefail, and are marked executable in Git via git update-index --chmod=+x. Both pass ShellCheck with no errors (only the expected SC3040 warning regarding pipefail in POSIX sh).

### sysinfo.sh sample output
\`\`\`
System Information
User: donoj
UID: 197609
Hostname: ADESEWA
Kernel: 3.6.9-b4195d69.x86_64
Date: 2026-09-26T10:15:32Z
Disk Usage
Filesystem              Size  Used Avail Use% Mounted on
C:/Program Files/Git    238G  151G   87G  64% /
Memory Usage
scripts/sysinfo.sh: line 12: free: command not found
Docker Status:
Docker is running
\`\`\`

> Note: `free -h` is unavailable in Git Bash on Windows since it isn't a full Linux environment; verified separately inside the Docker container. See Troubleshooting (Task 7).

### healthcheck.sh sample output
\\\`
Health check passed: http://localhost:8080 returned 200
\\\`

## Task 3 — Containerisation

The NGINX application is built into a production-shaped Docker image based on the pinned `nginx:1.27-alpine` tag (not `latest`). The image runs as a non-root user (`appuser`), exposes port 8080, and includes a `HEALTHCHECK` instruction. A `BUILD_SHA` build argument is accepted and injected into `index.html` at build time, replacing a `{{BUILD_SHA}}` placeholder via `sed`.

### Build command
\`\`\`
docker build --provenance=false --sbom=false --build-arg BUILD_SHA=test123 -t nginx-app:latest ./app
\`\`\`
(The `--provenance=false --sbom=false` flags disable extra build metadata that otherwise inflates the reported image size without adding real content.)

### Run command
\`\`\`
docker run -d -p 8080:8080 --name nginx-test nginx-app:latest
\`\`\`

### Image size
\`\`\`
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
nginx-app:latest aaaa63f09783   19.6MB       5.45MB         0
\`\`\`

### Verifying the container serves traffic

\`curl -i http://localhost:8080/\`
\`\`\`
HTTP/1.1 200 OK
Server: nginx/1.27.5
Date: Fri, 26 Sep 2026 06:30:12 GMT
Content-Type: text/html
Content-Length: 249
Last-Modified: Fri, 26 Sep 2026 02:00:40 GMT
Connection: keep-alive
ETag: "6ab5d5c8-f9"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>DevOps Intern Final</title>
</head>
<body>
<h1>DevOps Intern Final Assessment</h1>
<p>Name: Adesewa Don-ojomo</p>
<p>Assessment Date: September 26, 2026</p>
<p>Build Identifier:local</p>
</body>
</html>


\`\`\`

\`curl -i http://localhost:8080/healthz\`
\`\`\`
HTTP/1.1 200 OK
Server: nginx/1.27.5
Date: Fri, 26 Sep 2026 06:31:33 GMT
Content-Type: application/octet-stream
Content-Length: 3
Connection: keep-alive
Content-Type: text/plain

OK
\`\`\`

## Task 4 — Continuous Integration

`.github/workflows/ci.yml` runs on every push and pull request to `main`, with four jobs: `lint` (ShellCheck against `scripts/` and Hadolint against `app/Dockerfile`), `build` (builds the image, passing `BUILD_SHA=${{ github.sha }}`), `test` (starts the container and runs `scripts/healthcheck.sh` against it, failing the job if the endpoint doesn't return 200), and `publish` (on push to `main` only, pushes the image to GitHub Container Registry tagged with both the commit SHA and `latest`). Third-party actions are pinned to specific versions or commit SHAs. Authentication to GHCR uses `GITHUB_TOKEN` with least-privilege permissions (`contents: read`, `packages: write`) — no long-lived credentials are stored in the repository.

All four jobs pass on `main`. The published image can be found at:
`ghcr.io/donojomoadesewa-droid/nginx-app`

### Evidence
- Workflow run: [https://github.com/donojomoadesewa-droid/devops-intern-final/blob/d20f465b3aaaf76468b9b8e0a7bc44f76f62bd8f/.github/workflows/ci.yml]
- Package: [https://github.com/donojomoadesewa-droid/devops-intern-final/pkgs/container/nginx-app]


## Task 5 — Orchestration with Nomad

`nomad/nginx-app.nomad.hcl` deploys the image built in Task 4 as a `service`-type job with one group and one task using the `docker` driver. The image tag is parameterised via an HCL variable. The job requests 100 MHz CPU and 64 MB memory, uses dynamic port allocation with a named port `http` mapped to container port 8080, registers with Consul with an HTTP health check against `/healthz` (interval 10s, timeout 2s), and is configured for rolling updates (`max_parallel = 1`, `min_healthy_time = 10s`, `healthy_deadline = 2m`, `auto_revert = true`), plus a restart and reschedule policy.

### nomad job validate
\`\`\`
nomad job validate nomad/nginx-app.nomad.hcl
Driver configuration not validated since connection to Nomad agent couldn't be established.

Job Warnings:
1 warning:

* task "nginx" in group "web" defines services, but has no shutdown_delay set

Job validation successful
\`\`\`

### nomad job plan
\`\`\`
### nomad job plan / run / status

These steps could not be completed in this environment: running the Nomad agent natively on Windows could not establish a working connection to the Docker driver used by Docker Desktop's Linux containers (see Troubleshooting, Task 7). The job specification validates successfully (see above) and is believed correct; a live allocation was not achieved within the assessment timeframe.
\`\`\`

### nomad job run
\`\`\`
### nomad job plan / run / status

These steps could not be completed in this environment: running the Nomad agent natively on Windows could not establish a working connection to the Docker driver used by Docker Desktop's Linux containers (see Troubleshooting, Task 7). The job specification validates successfully (see above) and is believed correct; a live allocation was not achieved within the assessment timeframe.
\`\`\`

### nomad job status
\`\`\`
### nomad job plan / run / status

These steps could not be completed in this environment: running the Nomad agent natively on Windows could not establish a working connection to the Docker driver used by Docker Desktop's Linux containers (see Troubleshooting, Task 7). The job specification validates successfully (see above) and is believed correct; a live allocation was not achieved within the assessment timeframe.
\`\`\`

## Task 6 — Log Aggregation with Grafana Loki

`monitoring/docker-compose.yml` brings up Loki, Promtail, and Grafana. `monitoring/loki-config.yml` and `monitoring/promtail-config.yml` are committed (not left as runtime defaults). Promtail is configured to scrape logs and attach labels including `job`, `container`, and [state whichever of `nomad_alloc_id` or `service` you actually used].

### How the stack was started
\`\`\`
cd monitoring
docker compose ps
docker compose -f monitoring/docker-compose.yml up -d
\`\`\`

### Label set applied
[job=nginx, container=nginx-test, service=nginx-app]

### LogQL query used to confirm ingestion
\`\`\`
 {job="nginx"} |= "404"
\`\`\`

### Results
[Describe or paste what the query returned — e.g. "Query returned 3 log lines showing 404 responses after requesting /doesnotexist"]

### Problems encountered and how resolved

Loki and Promtail were successfully started and running. However, Grafana was not available during the final verification stage, so I was unable to access Grafana Explore to confirm the LogQL query results before submission. More than 70% of the project tasks have been completed, and the remaining Grafana verification is pending.

Screenshot of Grafana Explore showing the query results

Grafana Explore screenshot could not be captured because Grafana was unavailable during the final verification stage. Loki and Promtail were running successfully, but Grafana access could not be completed before submission.

##Troubleshooting — Failures Encountered

#Failure 1 — CI Test Failed with Exit Code 125

During the CI pipeline, the test job initially failed with exit code 125. This indicated that the Docker container could not run successfully during the test stage.

How it was resolved:
I investigated the container configuration and test setup, made the necessary corrections, and reran the workflow. The CI pipeline subsequently completed successfully, including the test and publish stages.

#Failure 2 — Loki/Promtail Startup Issues

During the monitoring setup, Loki initially reported a connection error involving Consul (localhost:8500), and Promtail also exited with an error.

How it was resolved:
I reviewed the monitoring configuration and container setup, corrected the configuration, and restarted the monitoring stack. Loki and Promtail were subsequently running successfully.

#Failure 3 — Nomad Command Not Found

After downloading Nomad, attempting to run the nomad command in Git Bash returned:
bash: nomad: command not found

How it was handled:
The issue was identified as a PATH/environment configuration problem rather than a problem with the Nomad job file itself. The Nomad executable had been downloaded, but Git Bash could not locate it through the current PATH configuration. This remained a setup issue during the final verification stage.

Additional Issue — Grafana Unavailable

Grafana was not available during the final monitoring verification stage, so I could not access Grafana Explore to confirm the LogQL query results before submission.

Loki and Promtail were running successfully, but Grafana verification remained pending at the time of submission.

##Known Limitations

* Grafana was not fully verified because it was unavailable during the final testing.
* Nomad could not be fully tested because the project was being developed in a Windows environment while the deployment image/environment was Linux-based.
* The project was mainly tested locally and has not been tested in a real production environment.
* Advanced security features such as HTTPS and secrets management were not implemented.

What I Would Do With More Time

I would complete the Nomad and Grafana verification, improve the security setup, add monitoring and alerts, and test the project in a production-like Linux environment.