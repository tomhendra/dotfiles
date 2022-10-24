#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

repos_array=(
  "coursework" 
  "blog-content" 
  "blog" 
  "yakk" 
  "the-lab" 
  "personal-site"
)

clone_repo () {
  repo="$1"
  
  git clone git@github.com:${username}/${i}.git ${dir}/${i}
  echo "$(whoami): ${i} cloned to ${dir}/${i}"
}

for i in "${repos_array[@]}";
do
  clone_repo ${i}
done