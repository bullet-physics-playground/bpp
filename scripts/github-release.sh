#!/usr/bin/env bash

# TYPE= argument to the script where 0 = MAJOR, 1 = MINOR, 2 = BUILD. Default to BUILD.
GIT_VERSION=$(git describe --tags)
CURRENT_VERSION=$(echo ${GIT_VERSION} | cut -d'-' -f1)
TYPE=${1:-2}

function increment_version() {
	local VERSION="$1"
	local PLACE="$2"

	IFS='.' read -r -a a <<<"$VERSION"
	((a[PLACE]++))
	echo "${a[0]}.${a[1]}.${a[2]}"
}

NEW_VERSION=$(increment_version $CURRENT_VERSION $TYPE)

sed -i -- "s/PROJECT_NUMBER = .*/PROJECT_NUMBER = \"$NEW_VERSION\"/" Doxyfile
sed -i -- "s/\!define VERSION.*/\!define VERSION \"$NEW_VERSION\"/" bpp.nsi
sed -i -- "s/#define APP_VERSION QString(\".*\")/\#define APP_VERSION QString(\"$NEW_VERSION\")/" src/main.cpp

dch -v $NEW_VERSION &&
git add Doxyfile bpp.nsi src/main.cpp debian/changelog &&
git commit -m "Bump version $NEW_VERSION" &&
git tag $NEW_VERSION &&
git push origin master &&
git push origin tag $NEW_VERSION &&
gh release create $NEW_VERSION --generate-notes
