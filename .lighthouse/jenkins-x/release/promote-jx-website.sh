#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

pushd $(mktemp -d)
  git clone https://github.com/jenkins-x/jx-docs.git

  pushd jx-docs
    sed -i "s/release = \".*\"/release = \"${JX_VERSION}\"/" config.toml
    git commit --allow-empty -a -m "chore: upgrade jx version"
    git push
  popd
popd
