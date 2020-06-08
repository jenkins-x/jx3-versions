#!/usr/bin/env bash
set -e
set -x

git clone https://github.com/jenkins-x/jxr-kube-resources.git
cd jxr-kube-resources

echo "generating the kubernetes resources from the helm charts"

jxl boot step helm stream --dir=..

echo "done - now pushing"
git push
