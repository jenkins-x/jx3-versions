#!/usr/bin/env bash
set -e
set -x

# BDD test specific part
export BDD_NAME="bdd-ghe"

# the gitops repository template to use
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-gke-terraform-vault"

# to enable spring / gradle...
#export RUN_TEST="bddjx -ginkgo.focus=spring-boot-http-gradle -test.v"


# add extra git token
export GIT_USERNAME="dev1"
export JX_BDD_GIT_CREDENTIALS="https://${GIT_USERNAME//[[:space:]]}:${GH_ACCESS_TOKEN//[[:space:]]}@github.beescloud.com"

# lets default to using github enterprise
export JX_ADMIN_CREATE_ARGS="--git-name ghe --git-server https://github.beescloud.com --env-git-owner ${GIT_USERNAME}"


`dirname "$0"`/../ci.sh
