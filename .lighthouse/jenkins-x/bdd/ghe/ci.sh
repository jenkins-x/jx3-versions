#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="ghe"

export GIT_USERNAME="dev1"
export GH_OWNER="${GIT_USERNAME}"

export GH_HOST="https://github.beescloud.com/"
export GIT_SERVER_HOST="github.beescloud.com"

# configure the scm client
export JX_SCM="jx-scm"
export GIT_SERVER="https://${GIT_SERVER_HOST}"
export GIT_NAME="ghe"
export GIT_KIND="github"
export GIT_TOKEN="${GH_ACCESS_TOKEN}"

# the gitops repository template to use
export GITOPS_INFRA_PROJECT="jx3-gitops-repositories/jx3-terraform-gke"
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-gke-gsm"

# enable the terraform gsm config
export TF_VAR_gsm=true

echo "downloading the jx-scm binary to the PATH"

curl -L https://github.com/jenkins-x-plugins/jx-scm/releases/download/v0.0.16/jx-scm-linux-amd64.tar.gz | tar xzv
mv jx-scm /usr/local/bin

$JX_SCM repo help


`dirname "$0"`/../terraform-ci.sh

## cleanup secrets in google secrets manager if it was enabled
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-$BDD_NAME"
export PROJECT_ID=jenkins-x-labs-bdd
gcloud secrets list --project $PROJECT_ID --format='get(NAME)' --limit=unlimited --filter=$CLUSTER_NAME | xargs -I {arg} gcloud secrets delete  "{arg}" --quiet

