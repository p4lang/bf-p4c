#! /bin/bash

scripts_dir=$(dirname $0)
me=$0

usage() {
    echo "Usage $me [--context <context.json>] [--resources <resources.json>] [--help]"
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

context=false
resources=false
phv=false
while [[ $# -gt 0 ]] ; do
    if [ ! -z $1 ]; then
        case $1 in
            -h|--help)
                usage;
                exit 0;
                ;;
            -c|--context)
                context=$2
                shift; shift;
                ;;
            -r|--resources)
                resources=$2
                shift; shift;
                ;;
            -p|--phv)
                phv=$2
                shift; shift;
                ;;
            *)
                echo "Unknown option $1"
                ;;
        esac
    fi
done

# do not exit on error. We want to validate both context and resources as needed
set +e

rcc=0
if [ $context != false ]; then
    $scripts_dir/validate_context_json $context
    rcc=$?
fi

rcr=0
if [ $resources != false ]; then
    $scripts_dir/validate_resources_json $resources
    rcr=$?
fi

rcp=0
if [ $phv != false ]; then
    $scripts_dir/validate_phv_json $phv
    rcp=$?
fi

if [ $rcc != 0 ] || [ $rcr != 0 ] || [ $rcp != 0 ]; then
    exit 1
fi

exit 0
