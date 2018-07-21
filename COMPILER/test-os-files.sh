#!/bin/bash

rootdir=$(dirname $0)/..
for f in $rootdir/OS/*.h
do
    node $rootdir/COMPILER/cli.js $f > /dev/null 2>&1 \
        && echo "$f passes" \
        || echo "$f fails"
done
