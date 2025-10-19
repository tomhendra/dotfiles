#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

declare -a repos=("courses" "tapeo" "tomhendra.dev" "tomkit")

clone_repo () {
  repo="$1"

  git clone git@github.com:${username}/${repo}.git ${dir}/${repo} && echo "${repo} cloned to ${dir}/${repo}"
}

for i in "${repos[@]}"
do
  clone_repo ${i}
done
