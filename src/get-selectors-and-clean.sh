#!/usr/bin/env bash

OUTPUT_DIR=$1

SELECTOR=""
defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

if git log -m HEAD ^"$defaultBranch" --name-only --pretty=format: | grep -q "^helmfiles/"; then
  changedNamespaces=$(git log -m HEAD ^"$defaultBranch" --name-only --pretty=format: | grep "^helmfiles/" | cut -d "/" -f 2 | sort -u)
  for namespace in ${changedNamespaces}; do
    SELECTOR="${SELECTOR} --selector namespace=${namespace}"
    rm -rf ${OUTPUT_DIR}/cluster/namespaces/${namespace}.yaml
    rm -rf ${OUTPUT_DIR}/cluster/resources/${namespace}
    rm -rf ${OUTPUT_DIR}/customresourcedefinitions/${namespace}
    rm -rf ${OUTPUT_DIR}/namespaces/${namespace}
  done
  >&2 echo helmfile with selector ${SELECTOR}
fi

if [ -z "${SELECTOR}" ]; then
  >&2 echo helmfile without selector
  rm -rf ${OUTPUT_DIR}/*/*/
fi

jx gitops repository create >&2

echo ${SELECTOR}
