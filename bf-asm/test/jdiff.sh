#!/bin/bash

curdir=`pwd`
json_diff_file="json_diff.txt"

TRY_BINDIRS="
    $PWD
    $PWD/..
    $PWD/../*
    $TESTDIR/..
    $TESTDIR/../*
"

function findbin () {
    found=""
    if [ -x "$BUILDDIR/$1" ]; then
        echo $BUILDDIR/$1
        return
    fi
    for d in $TRY_BINDIRS; do
        if [ -x "$d/$1" ]; then
            if [ -z "$found" -o "$d/$1" -nt "$found" ]; then
                found="$(cd $d; pwd -P)/$1"
            fi
        fi
    done
    if [ -z "$found" ]; then
        echo >&2 "Can't find $1 executable"
        echo false
        exit
    else
        echo $found
    fi
}

if [ ! -x "$JSON_DIFF" ]; then
    JSON_DIFF=$(findbin json_diff)
fi

dir1=$curdir/$1
dir2=$curdir/$2

echo "dir1="$dir1
echo "dir2="$dir2

> $json_diff_file
for f1 in $dir1/*.cfg.json*; do
    f2="$dir2/${f1##*/}"
    if [ ! -r $f2 ]; then
        f2="$f2.gz"
    fi
    echo "Comparing $f1 vs $f2"
    if zcmp -s $f1 $f2; then
        continue
    elif [ "$f1" = "$dir1/regs.pipe.cfg.json" ]; then
        $JSON_DIFF -i mau $f1 $f2
        if [ $? -gt 128 ]; then
            echo "***json_diff crashed"
        fi
        continue
    fi
    $JSON_DIFF $f1 $f2 >> $json_diff_file
done

if [ -r $dir1/tbl-cfg ]; then
    { $JSON_DIFF $CTXT_DIFFARGS $dir1/tbl-cfg $dir2/tbl-cfg;
      if [ $? -gt 128 ]; then echo "***json_diff crashed"; fi; } >> \
          $json_diff_file 
fi
