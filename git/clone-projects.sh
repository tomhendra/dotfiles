#!/bin/sh

Developer="${HOME}/Developer"

# Clone project repos into Dev. Use --recursive to clone submodules.
git clone git@github.com:tomhendra/coursework.git ${Developer}/coursework
git clone git@github.com:tomhendra/the-lab.git ${Developer}/blog-content
git clone git@github.com:tomhendra/the-lab.git ${Developer}/blog
git clone git@github.com:tomhendra/the-lab.git ${Developer}/yakk
git clone git@github.com:tomhendra/the-lab.git ${Developer}/the-lab
git clone git@github.com:tomhendra/personal-site.git ${Developer}/personal-site