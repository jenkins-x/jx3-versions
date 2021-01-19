#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="azure-akv"

# the gitops repository template to use
export GITOPS_INFRA_PROJECT="jx3-gitops-repositories/jx3-terraform-azure"
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-azure-akv"

# enable the terraform azure key vault config
export TF_VAR_key_vault_enabled=true

#`dirname "$0"`/../terraform-ci.sh

echo "hello world"

export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-$BDD_NAME"
