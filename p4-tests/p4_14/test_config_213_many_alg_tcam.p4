#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}


header_type meta_t {
     fields {
         partition_index : 10;
         pad_0 : 10;
         vrf : 12;
     }
}


header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
metadata meta_t meta;


parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default : ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.protocol){
       0x06 : parse_tcp;
       default : ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}


action set_partition_index(idx){
    modify_field(meta.partition_index, idx);
}

action ipv4_lpm_hit(){
    subtract(ipv4.ttl, ipv4.ttl, 1);
}

action lpm_miss(param0){
    modify_field(ipv4.ttl, param0);
    drop();
}

table ipv4_lpm_partition {
    reads {
        meta.vrf: exact;
        ipv4.dstAddr: lpm;
    }
    actions {
        set_partition_index;
    }
    size : 1024;
}

/* @pragma atcam_number_partitions 1024 */
@pragma pack 1
@pragma ways 4
@pragma atcam_partition_index meta.partition_index
table ipv4_alg_tcam {
    reads {
        meta.partition_index: exact;
        meta.vrf: exact;
        ipv4.dstAddr: lpm;
    }
/*
    actions {
        ipv4_lpm_hit;
        lpm_miss;
    }
*/
    action_profile : ap;
    size: 65536;
}

action_profile ap {
    actions {
        ipv4_lpm_hit;
        lpm_miss;
    }
    size : 65536;
}

control ingress {
    apply(ipv4_lpm_partition);
    apply(ipv4_alg_tcam); 
}
