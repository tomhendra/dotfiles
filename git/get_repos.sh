#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

declare -a repos=("coursework" "tomhendra.dev") 

clone_repo () {
  repo="$1"
  
  git clone git@github.com:${username}/${i}.git ${dir}/${i} && echo "${i} cloned to ${dir}/${i}"
}

for i in "${repos[@]}"
do
  clone_repo ${i}
done