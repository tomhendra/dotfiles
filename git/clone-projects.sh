#!/bin/sh

Developer="${HOME}/Developer"

# Clone project repos into Dev. Use --recursive to clone submodules.
git clone git@github.com:tomhendra/buho.git ${Developer}/buho
git clone git@github.com:tomhendra/coursework.git ${Developer}/coursework
git clone git@github.com:tomhendra/personal-site.git ${Developer}/personal-site
git clone git@github.com:tomhendra/the-lab.git ${Developer}/the-lab