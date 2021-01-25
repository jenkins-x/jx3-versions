#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="ghe"

export GIT_USERNAME="dev1"
export GH_OWNER="${GIT_USERNAME}"

export GH_HOST="https://github.beescloud.com/"
export GIT_SERVER_HOST="github.beescloud.com"

export JX_ADMIN_CREATE_ARGS="-git-server $GH_HOST --git-name ghe"

# the gitops repository template to use
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-kubernetes"

export CUSTOMISE_GITOPS_REPO="kpt pkg get https://github.com/jenkins-x/jx3-gitops-template.git/infra/gcloud-cluster-only/bin@master bin"

# to enable spring / gradle...
#export RUN_TEST="bddjx -ginkgo.focus=spring-boot-http-gradle -test.v"

`dirname "$0"`/../ci.sh
