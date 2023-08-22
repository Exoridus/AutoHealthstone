#!/bin/bash

version=$( git describe --tags --always )
tag=$( git describe --tags --always --abbrev=0 )

if [ "$version" = "$tag" ]; then # on a tag
  current="$tag"
  previous=$( git describe --tags --abbrev=0 HEAD~ )
  if [[ $previous == *beta* ]]; then
    if [[ $tag == *beta* ]]; then
      previous=$( git describe --tags --abbrev=0 HEAD~ )
    else
      previous=$( git describe --tags --abbrev=0 --exclude="*beta*" HEAD~ )
    fi
  else
    previous=$( git describe --tags --abbrev=0 HEAD~ )
  fi
else
  current=$( git log -1 --format="%H" )
  previous="$tag"
fi

project=$( git remote get-url origin | sed 's#.*\/\(.*\)\.git#\1#' )
date=$( git log -1 --date=short --format="%ad" )
url=$( git remote get-url origin | sed -e 's/^git@\(.*\):/https:\/\/\1\//' -e 's/\.git$//' )

cat <<- EOF > CHANGELOG.md
# ${project}

## [${version}](${url}/tree/${current}) ($date)
[Full Changelog](${url}/compare/${previous}...${current}) [Previous Releases](${url}/releases)

EOF

git log --pretty="format:- %s ([%h](${url}/commits/%H))" --no-merges "$previous..$current" | sed -r \
  -e 's/(fix|feat|build|chore|ci|docs|style|refactor|perf|test)(\([^)]+\))?:\s?//' \
  >> "CHANGELOG.md"
