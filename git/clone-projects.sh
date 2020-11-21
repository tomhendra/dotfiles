#!/bin/sh

dev="${HOME}/Dev"

# Clone project repos into Dev. Use --recursive to clone submodules.
git clone git@github.com:tomhendra/coursework.git ${dev}/coursework --recurse-submodules -j8
git clone git@github.com:tomhendra/personal-site.git ${dev}/personal-site