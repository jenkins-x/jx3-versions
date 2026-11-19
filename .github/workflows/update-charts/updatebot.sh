#!/usr/bin/env sh

git config --global --add safe.directory "$GITHUB_WORKSPACE"
jx-updatebot pr -c .github/workflows/update-charts/updatebot.yaml --no-version --git-credentials --git-token $GIT_TOKEN --git-username jenkins-x-bot-test --git-user-name jenkins-x-bot-test