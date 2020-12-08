#!/usr/bin/env bash
set -e
set -x

echo PATH=$PATH
echo HOME=$HOME

export PATH=$PATH:/usr/local/bin

# verify that we have a stagin certificate from LetsEncrypt
kubectl get issuer letsencrypt-staging -ojsonpath='{.status.conditions[0].status}'
kubectl get issuer letsencrypt-staging -ojsonpath='{.status.conditions[0].message}'

jx verify tls hook-jx.dev.jenkins-x.me  --production=false
