#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="bdd-kubevault"

# the gitops repository template to use
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-kubernetes-vault"

export TERRAFORM_FILE="terraform-kube-vault.yaml.gotmpl"

export PROJECT_ID=jenkins-x-labs-bdd1
export TF_VAR_project_id=$PROJECT_ID

`dirname "$0"`/../terraform-ci.sh
