# DT Tracker Backend Operations Guide (Agent)

## Overview

This document summarizes the production backend architecture, deployment
process, environment management, and future security roadmap for DT
Tracker.

## Architecture

ESP32 (SIM7670 HTTPS) → Nginx (HTTPS) → Node.js / Express (PM2) →
Firebase Admin SDK → Firebase Realtime Database

The ESP32 never connects directly to Firebase. All writes go through the
backend.

------------------------------------------------------------------------

# Current Environments

  Environment   Domain                           Port   PM2
  ------------- -------------------------------- ------ --------------------
  Production    https://api.dt-tracker.com       3000   dt-tracker-prod
  Development   https://dev.dt-tracker.com       3001   dt-tracker-dev
  Staging       https://staging.dt-tracker.com   3002   dt-tracker-staging

------------------------------------------------------------------------

# Environment Files

The repository contains:

-   .env.dev
-   .env.staging
-   .env.prod

These are **NOT committed** to Git.

Each file contains at least:

``` text
PORT=
FIREBASE_DB_URL=
FIREBASE_SERVICE_ACCOUNT=
```

FIREBASE_SERVICE_ACCOUNT is stored as one-line JSON.

------------------------------------------------------------------------

# server.js

The backend loads the environment automatically:

``` js
const env = process.env.NODE_ENV || "prod";
require("dotenv").config({ path: `.env.${env}` });
```

------------------------------------------------------------------------

# PM2

ecosystem.config.js defines:

-   dt-tracker-prod
-   dt-tracker-dev
-   dt-tracker-staging

Each process sets:

NODE_ENV=prod\|dev\|staging

Useful commands:

``` bash
pm2 list
pm2 logs dt-tracker-prod
pm2 restart dt-tracker-prod --update-env
pm2 save
pm2 startup
```

------------------------------------------------------------------------

# Nginx

One server block routes requests based on hostname.

Example mapping:

-   api.dt-tracker.com → localhost:3000
-   dev.dt-tracker.com → localhost:3001
-   staging.dt-tracker.com → localhost:3002

After editing:

``` bash
sudo nginx -t
sudo systemctl reload nginx
```

------------------------------------------------------------------------

# HTTPS

Certificates are managed with Certbot.

``` bash
sudo certbot --nginx \
-d api.dt-tracker.com \
-d dev.dt-tracker.com \
-d staging.dt-tracker.com
```

------------------------------------------------------------------------

# Backend Improvements

Implemented:

-   API Versioning (/api/v1)
-   Health endpoint (/health)
-   Version endpoint (/version)
-   Joi request validation
-   Structured request logging
-   Environment-aware startup
-   PM2 auto-start
-   Native HTTPS support from ESP32

------------------------------------------------------------------------

# Firebase

Writes use Firebase Admin SDK.

Realtime Database rules only protect client access.

Current recommendation:

-   Backend writes
-   Flutter authenticated reads
-   No client writes

------------------------------------------------------------------------

# Adding a New Environment

1.  Create Firebase Realtime Database.
2.  Create new .env.`<name>`{=html}.
3.  Add Firebase credentials.
4.  Add PM2 application.
5.  Add Nginx server_name.
6.  Create DNS record.
7.  Issue Let's Encrypt certificate.
8.  Restart PM2.
9.  Reload Nginx.
10. Test:

-   /health
-   /version
-   /api/v1/ingest

------------------------------------------------------------------------

# Deployment

``` bash
git pull
npm install
pm2 restart <environment> --update-env
```

Verify:

``` bash
curl https://<domain>/health
curl https://<domain>/version
```

------------------------------------------------------------------------

# Security Roadmap

## Phase 7

Device ownership.

Database:

users/{uid}/devices/{imei}=true

Rules only allow owners to read.

## Phase 8

Device authentication.

Each tracker receives an API token.

Backend validates:

-   token
-   imei
-   device status

before accepting data.

## Phase 9

Monitoring.

Add metrics:

-   requests/min
-   active trackers
-   errors
-   latency

## Phase 10

CI/CD

GitHub Actions:

develop → Dev

staging → Staging

main → Production

## Phase 11

Swagger / OpenAPI documentation.

## Phase 12

Move Flutter reads behind backend APIs instead of direct Firebase
access.

------------------------------------------------------------------------

# Best Practices

-   Never commit .env files.
-   Never commit Firebase service account keys.
-   Keep one Firebase database per environment.
-   Use HTTPS only.
-   Restart PM2 after environment changes.
-   Test /health after every deployment.
-   Backup environment files before changes.
