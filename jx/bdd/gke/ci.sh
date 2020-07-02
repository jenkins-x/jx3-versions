#!/usr/bin/env bash
set -e
set -x

echo HOME=$HOME

# setup environment
KUBECONFIG="/tmp/jxhome/config"

#export XDG_CONFIG_HOME="/builder/home/.config"
mkdir -p /home/.config
cp -r /home/.config /builder/home/.config

jx version
jx help
/home/.jx3/plugins/jx-admin-0.0.29
#jx admin --help
#jx secret --help


export GH_USERNAME="jenkins-x-labs-bot"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="cb-kubecd"

export PROJECT_ID=jenkins-x-labs-bdd
export CREATED_TIME=$(date '+%a-%b-%d-%Y-%H-%M-%S')
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-bdd-gke"
export ZONE=europe-west1-c
export LABELS="branch=${BRANCH_NAME,,},cluster=bdd-gke,create-time=${CREATED_TIME,,}"

# lets setup git
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD test with JX_HOME = $JX_HOME"

mkdir -p $XDG_CONFIG_HOME/git
# replace the credentials file with a single user entry
echo "https://${GH_USERNAME//[[:space:]]}:${GH_ACCESS_TOKEN//[[:space:]]}@github.com" > $XDG_CONFIG_HOME/git/credentials

echo "using git credentials: $XDG_CONFIG_HOME/git/credentials"
ls -al $XDG_CONFIG_HOME/git/credentials

echo "creating cluster $CLUSTER_NAME in project $PROJECT_ID with labels $LABELS"

# lets find the current cloud resources version
export CLOUD_RESOURCES_VERSION=$(grep  'version: ' /workspace/source/git/github.com/jenkins-x-labs/cloud-resources.yml | awk '{ print $2}')
echo "found cloud-resources version $CLOUD_RESOURCES_VERSION"

git clone -b v${CLOUD_RESOURCES_VERSION} https://github.com/jenkins-x-labs/cloud-resources.git
cloud-resources/gcloud/create_cluster.sh

echo "using the version stream ref: $PULL_PULL_SHA"

# create the boot git repository
/home/.jx3/plugins/jx-admin-0.0.29 create -b --env dev --provider=gke --version-stream-ref=$PULL_PULL_SHA --env-git-owner=$GH_OWNER --project=$PROJECT_ID --cluster=$CLUSTER_NAME --zone=$ZONE --repo env-$CLUSTER_NAME-dev --no-operator
#jx admin create -b --env dev --provider=gke --version-stream-ref=$PULL_PULL_SHA --env-git-owner=$GH_OWNER --project=$PROJECT_ID --cluster=$CLUSTER_NAME --zone=$ZONE

echo "now installing the operator"

# now installing the operator
#jx admin operator --url https://${GH_USERNAME//[[:space:]]}:${GH_ACCESS_TOKEN//[[:space:]]}@github.com/${GH_OWNER}/environment-${CLUSTER_NAME}-dev.git
/home/.jx3/plugins/jx-admin-0.0.29 operator --url https://github.com/${GH_OWNER}/env-${CLUSTER_NAME}-dev.git --username $GH_USERNAME --token $GH_ACCESS_TOKEN


# wait for vault to get setup
#jx secret vault wait -d 30m
/home/.jx3/plugins/jx-secret-0.0.34 vault wait -d 30m

export VAULT_ADDR=https://vault.vault-infra:8200

# lets port forward
# import secrets...
echo "secrets:
secrets:
  adminUser:
    username: admin
    password: $JENKINS_PASSWORD
  docker:
    url: ""
    username: todo
    password: todo
  hmacToken: todo
  pipelineUser:
    username: $GH_USERNAME
    token: $GH_ACCESS_TOKEN
    email: $GH_EMAIL" > /tmp/secrets.yaml

#jx secret import -f /tmp/secrets.yaml --git-url https://github.com/${GH_OWNER}/environment-${CLUSTER_NAME}-dev.git
/home/.jx3/plugins/jx-secret-0.0.34 import -f /tmp/secrets.yaml --git-url https://github.com/${GH_OWNER}/environment-${CLUSTER_NAME}-dev.git


# TODO verify env / install
sleep 100

# lets make sure jx defaults to helm3
#export JX_HELM3="true"

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# diagnostic commands to test the image's kubectl
kubectl version

kubectl config set-context --current --namespace=jx

# TODO
#jx ns jx

# for some reason we need to use the full name once for the second command to work!
kubectl get environments
kubectl get env
kubectl get env dev -oyaml

# TODO not sure we need this?
#helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io


export JX_DISABLE_DELETE_APP="true"

export GIT_ORGANISATION="$GH_OWNER"



# run the BDD tests
#bddjx -ginkgo.focus=golang -test.v
bddjx -ginkgo.focus=javascript -test.v

echo cleaning up cloud resources
curl https://raw.githubusercontent.com/jenkins-x-labs/cloud-resources/v$CLOUD_RESOURCES_VERSION/gcloud/cleanup-cloud-resurces.sh | bash
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE --quiet
