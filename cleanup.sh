#!/bin/sh

printf "[location]: "
read -r "location"
if [ -d "$location" ]; then
        cd "$location" || exit
        find "$location" -type f -print0 | xargs -0 mv -t "$location" >/dev/null 2>&1
        rm -rf "*.txt" "*.nfo" "*.png" "*.jpg"
else
        echo "Dir $location doesnt exist"
fi