#!/usr/bin/env bash

set -x

certbot certonly \
  --quiet \
  --agree-tos \
  --email jarrydstanbrook@proton.me \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/certbot/credentials.ini \
  --domain '*.jarryd.cc' \
  --server https://acme-v02.api.letsencrypt.org/directory
