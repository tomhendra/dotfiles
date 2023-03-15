#!/bin/sh

username="tomhendra"
dir="${HOME}/Developer"

repos_array=(
  "blog-content"
  "coursework"
  "tomhendra.dev"
  "stitch"
  "the-lab"
)

clone_repo () {
  repo="$1"
  
  git clone git@github.com:${username}/${i}.git ${dir}/${i} && echo ${i} cloned to ${dir}/${i}"
}

for i in "${repos_array[@]}";
do
  clone_repo ${i}
done

# ! /Users/tom/.dotfiles/git/get_repos.sh: line 20: unexpected EOF while looking for matching `"'
# ! /Users/tom/.dotfiles/git/get_repos.sh: line 24: syntax error: unexpected end of file