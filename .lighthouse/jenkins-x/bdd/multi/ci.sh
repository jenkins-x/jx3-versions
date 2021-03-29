#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="multi-prod"

# the gitops repository template to use
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-kubernetes-production"

export TERRAFORM_FILE="terraform-multi-prod.yaml.gotmpl"

# enable the terraform gsm config
export TF_VAR_gsm=true

export PROJECT_ID=jenkins-x-labs-bdd1
export TF_VAR_project_id=$PROJECT_ID

# lets setup the production cluster
`dirname "$0"`/../terraform-ci.sh


export BDD_NAME="multi-dev"
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-gke-gsm"
export TERRAFORM_FILE="terraform-multi-dev.yaml.gotmpl"

# add a git override
export JX_GIT_OVERRIDES=".lighthouse/jenkins-x/bdd/multi/overlay.sh"


# now lets setup the dev cluster
`dirname "$0"`/../terraform-ci.sh

## cleanup secrets in google secrets manager if it was enabled
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-$BDD_NAME"
gcloud secrets list --project $PROJECT_ID --format='get(NAME)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud secrets delete  "{arg}" --quiet

export BDD_NAME="multi-prod"
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-$BDD_NAME"
gcloud secrets list --project $PROJECT_ID --format='get(NAME)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud secrets delete  "{arg}" --quiet