#!/bin/bash

# Runner script to test code generation by matching regular
# expressions in generated assembly. The script runs the compiler
# (just as it would run it for any other test) and if successfully
# generated assembly, it prints it to the console.
# ctest can then use its regular expression mechanism to filter and
# decide whether the test was successful or not.

set -o pipefail

verbose=false
check_bfa=false
check_context=false
keep_files=false

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
regex=""

while [ $# -gt 1 ]; do
    case $1 in
    -h|-help|--help)
        echo >&2 "p4c test runner options"
        echo >&2 "   -v             verbose -- print commands before running them"
        echo >&2 "   -bfa           check bfa"
        echo >&2 "   -context       check context.json"
        echo >&2 "   -keep-files    keep the output files"
        echo >&2 "   -regex         search for regex in bfa or context.json"
        echo >&2 "other arguments passed to p4c-barefoot:"
        $P4C --help
        exit 0
        ;;
    -v) if $verbose || $debug; then
            P4C_ARGS="$P4C_ARGS $1"
        fi
        verbose=true
        ;;
    -bfa)
        check_bfa=true
        ;;
    -context)
        check_context=true
        ;;
    -keep-files)
        keep_files=true
        ;;
    -regex)
        regex=$2
        shift
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

if ! $check_bfa && ! $check_context; then
    die "Need either -bfa or -context to know what to check!"
fi

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

if [ ! -x $P4C ]; then
    die "Can't find $P4C"
fi

# delete old outputs so we don't get confused if they're not overwritten
rm -rf $testdir/$name${out_ext}.out/*

run $P4C $P4C_ARGS $file -o $testdir/${name}${out_ext}.out || die

p4version=$(grep p4_version $testdir/${name}${out_ext}.out/manifest.json | \
                awk '{print $2;}' | tr -d '\",')
if [[ $p4version == 'p4-16' ]]; then
    pipe=$(grep pipe_name $testdir/${name}${out_ext}.out/manifest.json | \
                awk '{print $2;}' | tr -d '\",')
    outdir=$testdir/${name}${out_ext}.out/$pipe
else
    outdir=$testdir/${name}${out_ext}.out
fi

if $check_bfa && [ -r $outdir/$name.bfa ]; then
    if [[ "x$regex" != "x" ]]; then
        grep $regex $outdir/$name.bfa
    else
        cat $outdir/$name.bfa
    fi
fi

if $check_context && [ -r $outdir/context.json ]; then
    if [[ "x$regex" != "x" ]]; then
        grep $regex $outdir/context.json
    else
        cat $outdir/context.json
    fi
fi

# cleanup
if ! $keep_files; then
    rm -rf $testdir/$name${out_ext}.out
fi
