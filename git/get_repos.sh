#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

declare -a repos=("courses" "recilla" "tomhendra.dev")

clone_repo () {
  repo="$1"

  if [ -d "${dir}/${repo}" ]; then
    echo "⚠️  ${repo} already exists, skipping..."
  else
    git clone git@github.com:${username}/${repo}.git ${dir}/${repo} && echo "✅ ${repo} cloned to ${dir}/${repo}"
  fi
}

for i in "${repos[@]}"
do
  clone_repo ${i}
done
