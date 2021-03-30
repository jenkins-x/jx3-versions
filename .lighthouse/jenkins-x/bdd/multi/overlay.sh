#!/usr/bin/env bash
set -e
set -x


export PROD_CLUSTER_NAME=cluster-${CLUSTER_NAME%-dev}-prod-dev

echo "importing the remote production repository for cluster ${PROD_CLUSTER_NAME}"

yq e '.spec.environments[2].namespace = "myapps"' -i jx-requirements.yml
yq e '.spec.environments[2].owner = "jenkins-x-bdd"' -i jx-requirements.yml
yq e '.spec.environments[1].promotionStrategy = "Never"' -i jx-requirements.yml
yq e '.spec.environments[2].promotionStrategy = "Auto"' -i jx-requirements.yml
yq e '.spec.environments[2].remoteCluster = true' -i jx-requirements.yml
yq e ".spec.environments[2].repository = \"$PROD_CLUSTER_NAME\"" -i jx-requirements.yml

