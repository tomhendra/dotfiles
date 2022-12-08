#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

repos_array=(
  "blog" 
  "blog-content" 
  "coursework" 
  "personal-site"
  "stitch" 
  "templates" 
  "the-lab" 
  "yakk" 
)

clone_repo () {
  repo="$1"
  
  git clone git@github.com:${username}/${i}.git ${dir}/${i} && echo ${i} cloned to ${dir}/${i}"
}

for i in "${repos_array[@]}";
do
  clone_repo ${i}
done