#!/bin/bash
set -e

LATEST_URL="$LATEST_URL"
PACKAGES_BASE_URL="$PACKAGES_BASE_URL"
current="$MAUTIC_VERSION"

if [ -z "$LATEST_URL" ]; then
	echo "LATEST_URL must be defined" >&2
	exit 1
fi

if [ -z "$PACKAGES_BASE_URL" ]; then
	echo "PACKAGES_BASE_URL must be defined" >&2
	exit 1
fi

if [ -z "$current" ]; then
	current="$(curl -q -O- "$LATEST_URL")"
fi

if [ -z "$current" ]; then
	echo "unable to determine version for build" >&2
	exit 1
fi

sha1=$(curl -q -O- "$PACKAGES_BASE_URL/$current.sha1.txt")

if [ -z "$sha1" ]; then
	wget -O mautic.zip "$PACKAGES_BASE_URL/$current.zip"
	sha1="$(sha1sum mautic.zip | sed -r 's/ .*//')"
fi

for variant in apache fpm; do
	(
		set -x

		sed -ri '
			s/^(ENV MAUTIC_VERSION) .*/\1 '"$current"'/;
			s/^(ENV MAUTIC_SHA1) .*/\1 '"$sha1"'/;
			s#^(RUN curl -o mautic.zip -SL) .*(\$\{MAUTIC_VERSION\}\.zip)#\1 '"$PACKAGES_BASE_URL"'/\2#;
		' "$variant/Dockerfile"

        # To make management easier, we use these files for all variants
		cp common/* "$variant"/
	)
done

rm -vf mautic.zip

