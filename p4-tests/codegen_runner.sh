#!/bin/bash

# Runner script to test code generation by matching regular
# expressions in generated assembly. The script runs the compiler
# (just as it would run it for any other test) and if successfully
# generated assembly, it prints it to the console.
# ctest can then use its regular expression mechanism to filter and
# decide whether the test was successful or not.

set -o pipefail

verbose=false
device="tofino"

die() {
    if [ $# -gt 0 ]; then
        echo >&2 "$@"
    fi
    exit 1
}

run() {
    if $verbose; then
        echo "$@"
    fi
    $@
    status=$?
    if [ $status -eq 124 ]; then
        echo >&2 $1 TIMEOUT
    elif [ $status -gt 128 ]; then
        echo >&2 $1 CRASH with signal $(expr $status - 128)
    elif [ $status -gt 0 ]; then
        echo >&2 $1 FAILED
    fi
    return $status
}

srcdir=${1%/}
if [ ! -d "$srcdir" ]; then
    die "Usage: $0 <srcdir> <test-source>"
fi
shift

P4C=./p4c
P4C_ARGS=""
testdir=codegen
out_ext=""

while [ $# -gt 1 ]; do
    case $1 in
    -h|-help|--help)
        echo >&2 "p4c test runner options"
        echo >&2 "   -v             verbose -- print commands before running them"
        echo >&2 "   -tofino        target tofino"
        echo >&2 "   -tofino2       target jbay"
        echo >&2 "other arguments passed to p4c-barefoot:"
        $P4C --help
        exit 0
        ;;
    -tofino)
        device="tofino"
        ;;
    -jbay)
        device="tofino2"
        ;;
    -v) if $verbose || $debug; then
            P4C_ARGS="$P4C_ARGS $1"
        fi
        verbose=true
        ;;
    --*)
        if [ -d $testdir${1#-} ]; then
            testdir="$testdir${1#-}"
        fi
        P4C_ARGS="$P4C_ARGS $1"
        ;;
    -D*)
        out_ext=$out_ext$1
        P4C_ARGS="$P4C_ARGS $1"
        ;;
    *)  P4C_ARGS="$P4C_ARGS $1"
        ;;
    esac
    shift
done

if [ ! -r $1 ]; then
    die "Can't read $1"
fi
file=$1

if [[ "$file" =~ ^"$srcdir/" || "$srcdir" == "." ]]; then
    testdir=$testdir/$(dirname ${file#$srcdir/})
elif [[ "$file" =~ ^/ ]]; then
    testdir=$(dirname $file)
else
    die "$file is not under $srcdir"
fi

name=$(basename $file .p4)

# turn on compiler debug info, regardless
P4C_ARGS="$P4C_ARGS -g"

if [ $(expr "$file" : ".*v1_2") -gt 0 -o $(expr "$file" : ".*p4_16") -gt 0 ]; then
    # XXX(cole): This is a hack.  There are some P4_16 tests written
    # against the v1model architecture; in the future, this will be
    # deprecated, and only translated P4_14 programs will use the
    # v1model architecture.  Even better, eventually architecture
    # files might include enough information to uniquely identify the
    # target, making the "--target" flag obsolete.  For the time
    # being, we grep for "v1model.p4" to determine whether a test uses
    # the v1model or TNA architecture.
    # XXX(zma) assuming tofino and jbay have same arch for now
    # XXX (calin): these arguments should be passed in by the caller
    if grep -q "tofino.p4" "$file"; then
        P4C_ARGS="$P4C_ARGS --target ${device} --arch tna"
    else
        P4C_ARGS="$P4C_ARGS --target ${device} --arch v1model"
    fi
    P4C_ARGS="$P4C_ARGS -x p4-16"
else
    P4C_ARGS="$P4C_ARGS --target ${device} --arch v1model"
    P4C_ARGS="$P4C_ARGS -x p4-14"
fi

if [ ! -x $P4C ]; then
    die "Can't find $P4C"
fi

# delete old outputs so we don't get confused if they're not overwritten
rm -f $testdir/$name${out_ext}.bfa
rm -f $testdir/$name${out_ext}.out/${device}.bin
rm -f $testdir/$name${out_ext}.out/${device}.bin.gz
rm -f $testdir/$name${out_ext}.out/*.log
rm -f $testdir/$name${out_ext}.out/*.log.gz

run $P4C $P4C_ARGS $file -o $testdir/${name}${out_ext}.out || die

# cleanup
rm -f $testdir/$name${out_ext}.out/${device}.bin
rm -f $testdir/$name${out_ext}.out/*.cfg.json
for f in $testdir/$name${out_ext}.out/*.log; do
    if [ -r $f ]; then
        gzip -f $f
    fi
done

if [ ! -r $testdir/$name${out_ext}.out/$name.bfa ]; then
    echo >&2 "$P4C did not give an error but did not generate output either"
    exit 1
else
    cat $testdir/$name${out_ext}.out/$name.bfa
fi
