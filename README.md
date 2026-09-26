\## Task 1 - Reference Application



The project is based on chakilams/simple-nginx-app, vendored into this repository under app/. The static index.html was modified to display the author's name, assessment date, and a build identifier injected at Docker build time (see Task 3). The original Kubernetes manifests were replaced with a HashiCorp Nomad job specification (see Task 5).



\## Task 2 — Linux Scripting



Two POSIX-compliant shell scripts live under scripts/: sysinfo.sh (reports user, UID, hostname, kernel, ISO-8601 date, disk usage, memory usage, and Docker daemon status) and healthcheck.sh (accepts a target URL as $1, defaulting to http://localhost:8080, and exits 0/1 based on whether it receives a 200 response). Both begin with #!/bin/bash and set -euo pipefail, and are marked executable in Git via git update-index --chmod=+x. Both pass ShellCheck with no errors (only the expected SC3040 warning regarding pipefail in POSIX sh).



\### sysinfo.sh sample output

\\\\\\`

System Information

User: donoj

UID: 197609

Hostname: ADESEWA

Kernel: 3.6.9-b4195d69.x86\_64

Date: 2026-09-25T06:49:27+0000

Disk Usage

Filesystem            Size  Used Avail Use% Mounted on

C:/Program Files/Git  238G  152G   87G  64% /

Memory Usage

scripts/sysinfo.sh: line 12: free: command not found

\\\\\\`



\### healthcheck.sh sample output

\\\\\\`

Health check passed: http://localhost:8080 returned 20

\\\\\\`



\## Task 3 — Containerisation



The NGINX application is built into a production-shaped Docker image based on the pinned nginx:1.27-alpine tag (not latest). The image runs as a non-root user (appuser), exposes port 8080, and includes a HEALTHCHECK instruction. A BUILD\_SHA build argument is accepted and injected into index.html at build time, replacing a {{BUILD\_SHA}} placeholder via sed.



\### Build command

\\\\\\`

docker build --provenance=false --sbom=false --build-arg BUILD\_SHA=test123 -t nginx-app:latest ./app

\\\\\\`

(The --provenance=false --sbom=false flags disable extra build metadata that otherwise inflates the reported image size without adding real content.)



\### Run command

\\\\\\`

docker run -d -p 8080:8080 --name nginx-test nginx-app:latest

\\\\\\`



\### Image size

\\\\\\`

IMAGE              ID             DISK USAGE   CONTENT SIZE   EXTRA

nginx-app:latest   aaaa63f09783       19.6MB         5.45MB    U

\\\\\\`



\### Verifying the container serves traffic



\\curl -i http://localhost:8080/\\

\\\\\\`

HTTP/1.1 200 OK

Server: nginx/1.27.5

Date: Fri, 25 Sep 2026 06:30:12 GMT

Content-Type: text/html

Content-Length: 249

Last-Modified: Fri, 25 Sep 2026 02:00:40 GMT

Connection: keep-alive

ETag: "6ab5d5c8-f9"

Accept-Ranges: bytes



<!DOCTYPE html>

<html>

<head>

<title>DevOps Intern Final,/title>

</head>

<body>

<h1>DevOps Intern Final Assessment</h1>

<p>Name:Adesewa Don-ojomo

<p>Assessment Date: September 21, 2026</p>

<p>Build Identifier:local</p>

</body>

</html>

\\\\\\`



\\curl -i http://localhost:8080/healthz\\

\\\\\\`

HTTP/1.1 200 OK

Server: nginx/1.27.5

Date: Fri, 25 Sep 2026 06:31:33 GMT

Content-Type: application/octet-stream

Content-Length: 3

Connection: keep-alive

Content-Type: text/plain



OK



\\\\\\`

