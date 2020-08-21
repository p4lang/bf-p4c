#!/usr/bin/env bash

# name="npb_"$(date +%Y%m%d)_$(date +%H%M%s)
# 
# pushd /tmp
# 
# # create directory
# mkdir $name
# cd $name
# 
# # copy files
# cp $SDE/build/p4-examples/npb/tofino/npb.p4info.pb.txt p4info.txt
# cp $SDE/install/share/tofinopd/npb/pipe/* .
# 
# # tar & zip
# cd ..
# tar -czvf $name.tgz $name
# 
# # copy it out
# scp $name.tgz delse@engbuild9:/tmp
# 
# popd

################################################################################
# tofino1
################################################################################
if [ "$1" == "1" ]; then


    echo "ERROR: Tofino1 support is stale - Only Tofino2 is being maintained"        
    exit 1

            
    # inputs
    context_home=$SDE_INSTALL/share/tofinopd/npb/pipe/
    context_json=context.json

    tofino_home=$SDE_INSTALL/share/tofinopd/npb/pipe/
    tofino_bin=tofino.bin
    
    p4info_home=/npb-dp/build/npb/tofino/
    p4info_txt=p4info.txt

    # outputs
    p4_device_config_home=/npb-dp/build/  # for p4runtime-shell
    p4_device_config_bin=p4_device_config.bin

    tarball_home=/npb-dp/build/
    tarball=npb-pipeline-build-artifacts-T1.tar

    # remove existing tarball
    rm -f $tarball_home$tarball.gz

    # verify files exist
    if [ -f $context_home$context_json ]; then
        chmod 666 $context_home$context_json
    else
        echo "ERROR: Required input file doesn't exist: $context_home$context_json"        
        exit 1
    fi

    if [ -f $tofino_home$tofino_bin ]; then
        chmod 755 $tofino_home$tofino_bin
    else
        echo "ERROR: Required input file doesn't exist: $tofino_home$tofino_bin"        
        exit 1
    fi
    
    if [ -f $p4info_home$p4info_txt ]; then
        chmod 666 $p4info_home$p4info_txt
    else
        echo "ERROR: Required input file doesn't exist: $p4info_home$p4info_txt"        
        exit 1
    fi

    # create p4runtime-shell consumable
    # /npb-dp/scripts/p4runtime_shell/tofino.py \
    #     --ctx-json $context_home$context_json \
    #     --tofino-bin $tofino_home$tofino_bin \
    #     --out $p4_device_config_home$p4_device_config_bin \
    #     --name npb
    
    P4RT_OPTIONS="--name npb"
    P4RT_OPTIONS="$P4RT_OPTIONS --ctx-json $context_home$context_json"
    P4RT_OPTIONS="$P4RT_OPTIONS --tofino-bin $tofino_home$tofino_bin"
    P4RT_OPTIONS="$P4RT_OPTIONS --out $p4_device_config_home$p4_device_config_bin"
    eval /npb-dp/scripts/p4runtime_shell/tofino.py $P4RT_OPTIONS
    
    if [ -f $ngnpb_home$ngnpb_bin ]; then
        chmod 755 $p4_device_config_home$p4_device_config_bin
    else
        echo "ERROR: Creation of $p4_device_config_home$p4_device_config_bin failed!"
        exit 1
    fi
        
    # tar -cvf $tarball_home$tarball \
    #     -C $context_home $context_json \
    #     -C $tofino_home $tofino_bin \
    #     -C $p4info_home $p4info_txt \
    #     -C $p4_device_config_home $p4_device_config_bin

    TAR_OPTIONS="-cvf $tarball_home$tarball"
    TAR_OPTIONS="$TAR_OPTIONS -C $context_home $context_json"
    TAR_OPTIONS="$TAR_OPTIONS -C $tofino_home $tofino_bin"
    TAR_OPTIONS="$TAR_OPTIONS -C $p4info_home $p4info_txt"
    TAR_OPTIONS="$TAR_OPTIONS -C $p4_device_config_home $p4_device_config_bin"
    eval tar $TAR_OPTIONS
    
    gzip $tarball_home$tarball
    chmod 666 $tarball_home$tarball.gz
    rm $p4_device_config_home$p4_device_config_bin

    
################################################################################    
# tofino2
################################################################################
elif [ "$1" == "2" ]; then

    # outputs
    stage_home=/npb-dp/build
    

    # ---------------
    # npb.conf 
    # ---------------

    npb_conf=npb.conf
    npb_home=share/tofino2pd/npb
    npb_home2=share/p4/targets/tofino2 # needed for run_tofino_model.sh -p option
    
    if [ ! -f $SDE_INSTALL/$npb_home/$npb_conf ]; then
        echo "ERROR: Required input file doesn't exist: $npb_home$npb_conf"        
        exit 1
    fi

    if [ ! -f $SDE_INSTALL/$npb_home2/$npb_conf ]; then
        echo "ERROR: Required input file doesn't exist: $npb_home2$npb_conf"        
        exit 1
    fi
    
    # ---------------
    # context.json 
    # ---------------

    #context_json=context.json
    #context_home=share/tofino2pd/npb/pipe
    
    # extract info from npb.conf
    context_line=$(grep \"context\" $SDE_INSTALL/$npb_home/$npb_conf)
    context_json=$(echo $context_line | sed -e 's/.*\/\(.*\..*\)\".*$/\1/')
    context_home=$(echo $context_line | sed -e 's/.*\:.*"\(.*\)\/.*$/\1/')     

    if [ ! -f $SDE_INSTALL/$context_home/$context_json ]; then
        echo "ERROR: Required input file doesn't exist: $SDE_INSTALL/$context_home/$context_json"        
        exit 1
    fi

    # ---------------
    # tofino2.bin 
    # ---------------

    #tofino2_bin=tofino2.bin
    #tofino2_home=share/tofino2pd/npb/pipe

    # extract info from npb.conf
    tofino2_line=$(grep \"config\" $SDE_INSTALL/$npb_home/$npb_conf)
    tofino2_bin=$(echo $tofino2_line | sed -e 's/.*\/\(.*\..*\)\".*$/\1/')
    tofino2_home=$(echo $tofino2_line | sed -e 's/.*\:.*"\(.*\)\/.*$/\1/')     

    if [ ! -f $SDE_INSTALL/$tofino2_home/$tofino2_bin ]; then
        echo "ERROR: Required input file doesn't exist: $SDE_INSTALL/$tofino2_home/$tofino_bin"        
        exit 1
    fi

    # ---------------
    # bf-rt.json 
    # ---------------    

    #bfrt_home=share/tofino2pd/npb
    #bfrt_json=bf-rt.json

    # extract info from npb.conf
    bfrt_line=$(grep \"bfrt-config\" $SDE_INSTALL/$npb_home/$npb_conf)
    bfrt_json=$(echo $bfrt_line | sed -e 's/.*\/\(.*\..*\)\".*$/\1/')
    bfrt_home=$(echo $bfrt_line | sed -e 's/.*\:.*"\(.*\)\/.*$/\1/')     

    if [ ! -f $SDE_INSTALL/$bfrt_home/$bfrt_json ]; then
        echo "ERROR: Required input file doesn't exist: $SDE_INSTALL/$bfrt_home/$bfrt_json"        
        exit 1
    fi
    
    # ---------------
    # p4info.txt 
    # ---------------

    p4info_home=/npb-dp/build/npb/tofino2
    p4info_txt=p4info.txt

    if [ ! -f $p4info_home/$p4info_txt ]; then
        echo "ERROR: Required input file doesn't exist: $p4info_home/$p4info_txt"        
        exit 1
    fi
    
    # ---------------------------
    # Generate p4_device_config2 
    # ---------------------------

    p4_device_config2_bin=p4_device_config2.bin

    # create p4runtime-shell consumable
    # /npb-dp/scripts/p4runtime_shell/tofino.py \
    #     --ctx-json $context_home$context_json \
    #     --tofino-bin $tofino2_home$tofino2_bin \
    #     --out $p4_device_config_home$p4_device_config2_bin \
    #     --name npb

    P4RT_OPTIONS="--name npb"
    P4RT_OPTIONS="$P4RT_OPTIONS --ctx-json $SDE_INSTALL/$context_home/$context_json"
    P4RT_OPTIONS="$P4RT_OPTIONS --tofino-bin $SDE_INSTALL/$tofino2_home/$tofino2_bin"
    P4RT_OPTIONS="$P4RT_OPTIONS --out $stage_home/$p4_device_config2_bin"
    eval /npb-dp/scripts/p4runtime_shell/tofino.py $P4RT_OPTIONS
    
    if [ -f $stage_home/$p4_device_config2_bin ]; then
        chmod +x $stage_home/$p4_device_config2_bin
    else
        echo "ERROR: Creation of $stage_home/$p4_device_config2_bin failed!"
        exit 1
    fi

    # ---------------------------
    # Create tarball
    # ---------------------------

    tarball_home=/npb-dp/build
    tarball=npb-pipeline-build-artifacts-T2.tar.gz
    
    # remove existing tarball
    if [ -f $tarball_home/$tarball ]; then
        mv $tarball_home/$tarball $tarball_home/$tarball.previous
    fi

    TAR_OPTIONS="-cvzf $tarball_home/$tarball"
    TAR_OPTIONS="$TAR_OPTIONS -C $SDE_INSTALL $npb_home/$npb_conf"
    TAR_OPTIONS="$TAR_OPTIONS -C $SDE_INSTALL $npb_home2/$npb_conf"
    TAR_OPTIONS="$TAR_OPTIONS -C $SDE_INSTALL $context_home/$context_json"
    TAR_OPTIONS="$TAR_OPTIONS -C $SDE_INSTALL $tofino2_home/$tofino2_bin"
    TAR_OPTIONS="$TAR_OPTIONS -C $SDE_INSTALL $bfrt_home/$bfrt_json"
    TAR_OPTIONS="$TAR_OPTIONS -C $p4info_home $p4info_txt"
    TAR_OPTIONS="$TAR_OPTIONS -C $stage_home $p4_device_config2_bin"

    #echo "tar $TAR_OPTIONS"
    eval tar $TAR_OPTIONS

else

    echo "  usage: $0 <target>"
    echo "  (where target is 1 for tofino or 2 for tofino2)"

fi



