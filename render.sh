#!/bin/bash
git config --global user.email "bmk@inbo.be"
git config --global user.name "INBO CI"
git clone --depth=1 --branch=gh-pages https://$GH_OAUTH@github.com/ThierryO/drat.git
cd drat
if [[ $(git log -1 | grep --quiet "Render markdown") ]]; then
  echo "Done"
else
  Rscript "render.R"
  git add --all
  git commit -m "Render markdown"
  git push origin
fi
cd ..
