#!/usr/bin/env bash
set -e
cd ~/mirrors/toilet.git

git fetch origin --prune
git filter-repo --path docs/ --invert-paths --force
git push --mirror --force git@github.com:WeeDom/toilet-pub.git
