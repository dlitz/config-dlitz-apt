#!/bin/bash
# dlitz 2023
#
# This is a one-off script that I used to reconstruct the *.buildinfo and
# *.changes files for versions 0.0.1 through 0.0.4.
#
# I had uploaded the packages to an aptly apt repo, which deletes and
# discards those files.  This script downloads the source packages from
# the repo and rebuilds them.  The resulting .deb packages are bit-for-bit
# identical to the binary packages from the repo.

set -eux
dir="$PWD"

debspawn_image_name=reconstruct-config-dlitz-apt-bookworm-amd64

versions=(
    0.0.1
    0.0.2
    0.0.3
    0.0.4
)

set_vars() {
    case "$1" in
        *)
            srcpkg=config-dlitz-apt
            binpkgs=(
                config-dlitz-apt-aptly
                config-dlitz-apt-bookworm-backports
                config-dlitz-apt-bullseye-backports
            )
            ;;
    esac
}

sign_files=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --sign)
            sign_files=1
            ;;
        --no-sign)
            sign_files=
            ;;
        *)
            printf '%s: bad argument\n' "$0"
            exit 2
            ;;
    esac
    shift 1
done

for version in "${versions[@]}" ; do
    set_vars "$version"

    cd "$dir"
    mkdir "$version"
    mkdir "$version/dl"
    mkdir "$version/src"
    mkdir "$version/results-amd64"
    mkdir "$version/combined"

    cd "$dir/$version/dl"
    apt-get source --only-source --download-only "${srcpkg}=${version}"
    apt-get download "${binpkgs[@]/%/=$version}"

    cd "$dir/$version/src"

    cp -ant . ../dl/${srcpkg}*
    dpkg-source --require-strong-checksums --require-valid-signature --no-overwrite-dir -x "${srcpkg}_${version}.dsc"

    cd "$dir/$version/src/$srcpkg-${version}"
    dpkg-genchanges -DDistribution=dlitz-aptly --build=source > ../"${srcpkg}_${version}_source.changes"

    cd "$dir/$version"
    cmp dl/${srcpkg}_${version}.dsc src/${srcpkg}_${version}.dsc
    cmp dl/${srcpkg}_${version}.tar.xz src/${srcpkg}_${version}.tar.xz
    debspawn build --only=binary --results-dir=results-amd64 "${debspawn_image_name}" src/"${srcpkg}_${version}.dsc"
    for bpname in "${binpkgs[@]}" ; do
        bindeb=${bpname}_${version}_all.deb
        cmp dl/"$bindeb" results-amd64/"$bindeb"
    done
    changestool results-amd64/"${srcpkg}_${version}_amd64.changes" setdistribution dlitz-aptly
    changestool results-amd64/"${srcpkg}_${version}_amd64.changes" verify

    # For each file in dl/*, compare it to all other files with that name.
    for p in dl/*; do
        f="${p##*/}"
        while IFS= read -d '' -u $fd p2; do
            cmp "$p" "$p2"
        done {fd}< <( find * -name "$f" -print0 )
        exec {fd}<&-
    done

    cd "$dir/$version"
    cp -vt ./combined/ dl/*_*
    cp -nvt ./combined/ src/*_* results-amd64/*_*

    cd "$dir/$version/combined"
    grep -qE '^Distribution: dlitz-aptly$' "${srcpkg}_${version}_amd64.changes"
    grep -qE '^Distribution: dlitz-aptly$' "${srcpkg}_${version}_source.changes"
    changestool "${srcpkg}_${version}_amd64.changes" verify
    changestool "${srcpkg}_${version}_source.changes" verify

    # Verify downloaded file content are the same as what was built
    ( cd "$dir/$version/dl" ; b3sum * ) | b3sum -c
done

for version in "${versions[@]}" ; do
    set_vars "$version"

    cd "$dir/$version/combined"
    changestool "${srcpkg}_${version}_amd64.changes" verify
    changestool "${srcpkg}_${version}_source.changes" verify
    if [ "${sign_files}" ]; then
        debsign --no-re-sign "${srcpkg}_${version}_source.changes"
        debsign --no-re-sign "${srcpkg}_${version}_amd64.changes"
        changestool "${srcpkg}_${version}_amd64.changes" verify
        changestool "${srcpkg}_${version}_source.changes" verify

        for f in \
            "${srcpkg}_${version}_source.changes" \
            "${srcpkg}_${version}_amd64.changes" \
            "${srcpkg}_${version}.dsc" \
            "${srcpkg}_${version}_amd64.buildinfo" ; \
        do
            gpgv --keyring /usr/share/keyrings/dlitz-personal.gpg "$f"
        done
    fi
done

cd "$dir"
mkdir "$dir/all-dl"
mkdir "$dir/all-combined"
find "${versions[@]/%//dl}" -type f -execdir cp -nvt "$dir/all-dl" {} +
find "${versions[@]/%//combined}" -type f -execdir cp -nvt "$dir/all-combined" {} +

cd "$dir/all-combined"
( cd "$dir/all-dl" ; b3sum * ) | b3sum -c

if [ "${sign_files}" ]; then
    for version in "${versions[@]}" ; do
        set_vars "$version"
        for f in \
            "${srcpkg}_${version}_source.changes" \
            "${srcpkg}_${version}_amd64.changes" \
            "${srcpkg}_${version}.dsc" \
            "${srcpkg}_${version}_amd64.buildinfo" ; \
        do
            gpgv --keyring /usr/share/keyrings/dlitz-personal.gpg "$f"
        done
    done
    for f in *.changes *.dsc *.buildinfo; do
        gpgv --keyring /usr/share/keyrings/dlitz-personal.gpg "$f"
    done
fi

echo 'All done!'
