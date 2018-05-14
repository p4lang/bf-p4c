#!/bin/bash

if [ ! -d /mnt/huge ]; then
    echo "This is the docker entry point"
    if [ -z "$NUM_HUGEPAGES" ]; then
        echo "vm.nr_hugepages = 128" >> /etc/sysctl.conf
    else
        echo "vm.nr_hugepages = $NUM_HUGEPAGES" >> /etc/sysctl.conf
    fi
    sysctl -p /etc/sysctl.conf
    mkdir /mnt/huge
    mount -t hugetlbfs nodev /mnt/huge
    echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab
fi
