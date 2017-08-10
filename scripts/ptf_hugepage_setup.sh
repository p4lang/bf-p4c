#!/bin/bash

if [ ! -d /mnt/huge ]; then
    echo "vm.nr_hugepages = 128" >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
    mkdir /mnt/huge
    mount -t hugetlbfs nodev /mnt/huge
    echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab
fi
