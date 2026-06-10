#!/bin/sh
set -eu

archive=uld_V1.00.39_01.17.tar.gz
url=https://downloadcenter.samsung.com/content/DR/201704/20170407143829533/uld_V1.00.39_01.17.tar.gz
sha512=fccda77af20b31c9b46117b013d0c40333adc87679057c2b1e513d9bae97fc7267eca74030bc039feec50edee8e4cdfebe8761c77d653646f7ea4ac102c2643f

command -v curl >/dev/null 2>&1 || {
    echo "curl is required" >&2
    exit 1
}
command -v sha512sum >/dev/null 2>&1 || {
    echo "sha512sum is required" >&2
    exit 1
}

curl -fL --retry 3 -o "${archive}.part" "$url"
printf '%s  %s\n' "$sha512" "${archive}.part" | sha512sum -c -
mv "${archive}.part" "$archive"
echo "Downloaded and verified: $archive"
