#!/usr/bin/env bash
set -e
set -x

echo PATH=$PATH
echo HOME=$HOME

export PATH=$PATH:/usr/local/bin

# setup environment
KUBECONFIG="/tmp/jxhome/config"

#export XDG_CONFIG_HOME="/builder/home/.config"
mkdir -p /home/.config
cp -r /home/.config /builder/home/.config

jx version
jx help

export JX3_HOME=/home/.jx3
jx admin --help
jx secret --help


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

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

echo "lets get the PR head clone URL"
export PR_SOURCE_URL=$(jx gitops pr get --git-token=$GH_ACCESS_TOKEN --head-url)

echo "using the version stream url $PR_SOURCE_URL ref: $PULL_PULL_SHA"

# create service account key used by certmanager to add A records for the dns challange by letsencrypt
gcloud iam service-accounts create $CLUSTER_NAME-dns01-solver --display-name "$CLUSTER_NAME dns01-solver" --project jenkins-x-labs-bdd
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLUSTER_NAME-dns01-solver@$PROJECT_ID.iam.gserviceaccount.com --role roles/dns.admin --project jenkins-x-labs-bdd
gcloud iam service-accounts keys create /tmp/credentials.json --iam-account $CLUSTER_NAME-dns01-solver@$PROJECT_ID.iam.gserviceaccount.com --project jenkins-x-labs-bdd
kubectl create secret generic external-dns-gcp-sa --from-file=/tmp/credentials.json
rm /tmp/credentials.json


# create the boot git repository
jx admin create -b --env dev --provider=gke --version-stream-ref=$PULL_PULL_SHA --version-stream-url=${PR_SOURCE_URL//[[:space:]]} --env-git-owner=$GH_OWNER --project=$PROJECT_ID --cluster=$CLUSTER_NAME --zone=$ZONE --repo env-$CLUSTER_NAME-dev \
  --domain $CLUSTER_NAME.jenkinsxlabs-test.com \
  --tls \
  --add=bitnami/external-dns \
  --tls-email jenkins-x-admin@googlegroups.com \
  --tls-production=false

# to install the operator separately try adding --no-operator then...
#jx admin operator --url https://github.com/${GH_OWNER}/env-${CLUSTER_NAME}-dev.git --username $GH_USERNAME --token $GH_ACCESS_TOKEN

# lets modify the git repo stuff - eventually we can remove this?
git clone https://${GH_USERNAME//[[:space:]]}:${GH_ACCESS_TOKEN//[[:space:]]}@github.com/${GH_OWNER}/env-${CLUSTER_NAME}-dev.git
cd env-${CLUSTER_NAME}-dev

# wait for vault to get setup
jx secret vault wait -d 30m

jx secret vault portforward &

# verify that we have a staging certificate from LetsEncrypt
kubectl get issuer letsencrypt-staging -ojsonpath='{.status.conditions[0].status}'
kubectl get issuer letsencrypt-staging -ojsonpath='{.status.conditions[0].message}'
jx verify tls hook-jx.$CLUSTER_NAME.jenkinsxlabs-test.com  --production=false --issuer 'Fake LE Intermediate X1'

sleep 30

# import secrets...
echo "secret:
  jx:
    adminUser:
      password: $JENKINS_PASSWORD
      username: admin
    docker:
      password: dummy
      username: admin
    mavenSettings:
      settingsXml: dummy
      securityXml: dummy
    pipelineUser:
      username: $GH_USERNAME
      token: $GH_ACCESS_TOKEN
      email: $GH_EMAIL
  lighthouse:
    hmac:
      token: 2efa226914ae6e81d062e9566646bd54bb1c0cc23" > /tmp/secrets.yaml

jx secret import -f /tmp/secrets.yaml

sleep 90

jx secret verify

jx ns jx

# diagnostic commands to test the image's kubectl
kubectl version

# for some reason we need to use the full name once for the second command to work!
kubectl get environments
kubectl get env
kubectl get env dev -oyaml

# lets wait for things to be installed correctly
make verify-install

kubectl get cm config -oyaml

export JX_DISABLE_DELETE_APP="true"
export JX_DISABLE_DELETE_REPO="true"

export GIT_ORGANISATION="$GH_OWNER"


# lets turn off color output
export TERM=dumb

echo "about to run the bdd tests...."

# run the BDD tests
bddjx -ginkgo.focus=golang -test.v
#bddjx -ginkgo.focus=javascript -test.v


echo "completed the bdd tests"

echo cleaning up cloud resources
curl https://raw.githubusercontent.com/jenkins-x-labs/cloud-resources/v$CLOUD_RESOURCES_VERSION/gcloud/cleanup-cloud-resurces.sh | bash
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE --quiet
