# Loki Setup

## Overview

Loki is used for centralized log aggregation, while Promtail collects logs and sends them to Loki.

## Configuration Files

The monitoring directory contains:

- loki-config.yml — Loki server configuration
- promtail-config.yml — Promtail log collection configuration
- docker-compose.yml — Runs Loki and Promtail together

## Start Monitoring Stack

From the monitoring directory, run:

```bash
docker compose up -d