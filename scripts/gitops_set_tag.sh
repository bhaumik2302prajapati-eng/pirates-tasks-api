#!/usr/bin/env bash
# Usage: gitops_set_tag.sh <staging|production> <image-tag>
# Writes the new image tag into gitops/envs/<env>/values.yaml and pushes it.
set -euo pipefail
ENV_NAME="$1"; TAG="$2"
FILE="gitops/envs/${ENV_NAME}/values.yaml"
sed -i -E "s|^(  tag: ).*|\1\"${TAG}\"|" "$FILE"
if git diff --quiet; then echo "tag is already ${TAG}, nothing to commit"; exit 0; fi
git config user.name "pirates-pipeline"
git config user.email "pirates-pipeline@users.noreply.github.com"
git add "$FILE"
git commit -m "deploy: ${ENV_NAME} -> ${TAG}"
for i in 1 2 3; do
  git push origin HEAD:main && exit 0
  git pull --rebase origin main
done
exit 1
