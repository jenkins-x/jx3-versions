#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="gke-tls"

# the gitops repository template to use
export GITOPS_INFRA_PROJECT="jx3-gitops-repositories/jx3-terraform-gke"
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-gke-gsm"

export TERRAFORM_FILE="terraform-tls.yaml.gotmpl"

# enable the terraform gsm config
export TF_VAR_gsm=true
export TF_VAR_apex_domain=bdd.jenkins-x.rocks
export TF_VAR_subdomain=$CLUSTER_NAME
export TF_VAR_lets_encrypt_production=false
export TF_VAR_tls_email=jayex@cd.foundation

source `dirname "$0"`/../terraform-ci.sh

## cleanup secrets in google secrets manager if it was enabled
gcloud secrets list --project $PROJECT_ID --format='get(NAME)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud secrets delete  "{arg}" --quiet

gcloud iam service-accounts list --project $PROJECT_ID --format='get(EMAIL)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud iam service-accounts delete "{arg}" --quiet