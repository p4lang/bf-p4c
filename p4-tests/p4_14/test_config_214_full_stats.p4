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

header_type blah_t {
     fields {
          blah : 6;
          color : 2;
     }
}


header_type meta_t {
     fields {
         partition_index : 10;
         pad_0 : 10;
         vrf : 10;
         color : 2;
     }
}


header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
header blah_t blah;
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
    extract(blah);
    return ingress;
}

counter counter_0 {
   type: packets_and_bytes;
   static: table_0;
   instance_count: 35000;
   min_width: 64;
}

counter counter_1 {
   type: packets_and_bytes;
   static: table_1;
   instance_count: 5000;
   min_width: 64;
}

meter meter_2 {
    type : bytes;
    direct : table_2;
    result : blah.color;
}

action action_0(idx){
    count(counter_0, idx);
}

action action_1(idx){
    count(counter_1, idx);
    modify_field_rng_uniform(ipv4.ttl, 0, 0xff);//255);
}

action action_2(){
}

table table_0 {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        action_0;
    }
    size : 1024;
}

table table_1 {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        action_1;
    }
    size : 1024;
}

@pragma pack 1
table table_2 {
    reads {
        ipv4.dstAddr: exact;
    }
    actions {
        action_2;
    }
    size : 4096;
}

control ingress {
    apply(table_0);
    apply(table_1);
    apply(table_2);
}
