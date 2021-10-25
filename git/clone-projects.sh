#!/bin/sh

dev="${HOME}/Dev"

# Clone project repos into Dev. Use --recursive to clone submodules.
git clone git@github.com:tomhendra/buho.git ${dev}/buho
git clone git@github.com:tomhendra/coursework.git ${dev}/coursework
git clone git@github.com:tomhendra/personal-site.git ${dev}/personal-site
git clone git@github.com:tomhendra/the-lab.git ${dev}/the-lab