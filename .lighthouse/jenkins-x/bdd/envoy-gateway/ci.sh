#!/usr/bin/env bash
set -e
set -x

export BDD_NAME="gke-eg"

export GITOPS_INFRA_PROJECT="jx3-gitops-repositories/jx3-terraform-gke"
export GITOPS_TEMPLATE_PROJECT="yelhouti/jx3-gke-gateway"

export JX_GIT_OVERRIDES=".lighthouse/jenkins-x/bdd/envoy-gateway/overlay.sh"

export TF_VAR_gsm=true
export TF_VAR_apex_domain=jenkinsxlabs-test.com
export TF_VAR_subdomain=$CLUSTER_NAME
export TF_VAR_lets_encrypt_production=false
export TF_VAR_tls_email=jenkins-x-admin@googlegroups.com

`dirname "$0"`/../terraform-ci.sh

export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-$BDD_NAME"
export PROJECT_ID=jenkins-x-bdd-326715
gcloud secrets list --project $PROJECT_ID --format='get(NAME)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud secrets delete  "{arg}" --quiet
gcloud iam service-accounts list --project $PROJECT_ID --format='get(EMAIL)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud iam service-accounts delete "{arg}" --quiet
