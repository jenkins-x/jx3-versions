#!/usr/bin/env bash
set -e
set -x

export NO_JX_TEST="true"
export KIND_VERSION=0.8.1
export JX_VERSION=0.0.286

mkdir $HOME/bin
export PATH=$PATH:$HOME/bin

# setup git credential store
export XDG_CONFIG_HOME=/home/.config
git config credential.helper store

# use a sub dir for downloading to avoid clashing with the jx dir etc
mkdir downloads
cd downloads

curl -L https://github.com/jenkins-x/jx-cli/releases/download/v${JX_VERSION}/jx-cli-linux-amd64.tar.gz | tar xzv
sudo mv jx /usr/local/bin

curl -L https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64 > kind
chmod +x kind
sudo mv kind /usr/local/bin/kind

cd ..

echo "now testing the binaries:"
jx help
kind version

# TODO replace this some day with using a container image?
# download all the plugins
export JX3_HOME=/home/.jx3
sudo mkdir -p $JX3_HOME
jx upgrade

# BDD test specific part
export BDD_NAME="bdd-kind"

# lets default env vars that don't get populated if not running in jx
BRANCH_NAME="${BRANCH_NAME:-pr}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

# the gitops repository template to use
export GITOPS_TEMPLATE_PROJECT="jx3-gitops-repositories/jx3-kind-vault"

mkdir -p /builder/home
jx/bdd/ci.sh