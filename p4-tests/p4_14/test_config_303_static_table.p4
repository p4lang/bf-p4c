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
        bm_0 : 8;
        bm_1 : 8;

        i2e_0 : 8;
        i2e_1 : 16;
        i2e_2 : 32;
        i2e_3 : 48;
        i2e_4 : 64;
        i2e_5 : 80;
        i2e_6 : 96;

        e2e_0 : 8;
        e2e_1 : 16;
        e2e_2 : 32;
        e2e_3 : 48;
        e2e_4 : 64;
        e2e_5 : 80;
        e2e_6 : 96;
        e2e_7 : 128;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;

@pragma pa_container_size ingress meta.i2e_0 8
@pragma pa_container_size ingress meta.i2e_1 16
@pragma pa_container_size ingress meta.i2e_2 32
@pragma pa_container_size ingress meta.i2e_3 16 32
@pragma pa_container_size ingress meta.i2e_4 32 32
@pragma pa_container_size ingress meta.i2e_5 16 32 32
@pragma pa_container_size ingress meta.i2e_6 32 32 32

@pragma pa_container_size egress meta.e2e_0 8
@pragma pa_container_size egress meta.e2e_1 16
@pragma pa_container_size egress meta.e2e_2 32
@pragma pa_container_size egress meta.e2e_3 16 32
@pragma pa_container_size egress meta.e2e_4 32 32
@pragma pa_container_size egress meta.e2e_5 16 32 32
@pragma pa_container_size egress meta.e2e_6 32 32 32
@pragma pa_container_size egress meta.e2e_7 32
metadata meta_t meta;

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
  extract(ipv4);
  return select(latest.fragOffset, latest.protocol) {
    6 : parse_tcp;
    default: ingress;
  }
}

parser parse_tcp {
  extract(tcp);
  return ingress;
}

field_list i2e_0 { meta.i2e_0; }
field_list i2e_1 { meta.i2e_1; }
field_list i2e_2 { meta.i2e_2; }
field_list i2e_3 { meta.i2e_3; }
field_list i2e_4 { meta.i2e_4; }
field_list i2e_5 { meta.i2e_5; }
field_list i2e_6 { meta.i2e_6; }

field_list e2e_0 { meta.e2e_0; }
field_list e2e_1 { meta.e2e_1; }
field_list e2e_2 { meta.e2e_2; }
field_list e2e_3 { meta.e2e_3; }
field_list e2e_4 { meta.e2e_4; }
field_list e2e_5 { meta.e2e_5; }
field_list e2e_6 { meta.e2e_6; }
field_list e2e_7 { meta.e2e_7; }

action do_nothing(){}

action set_bm(a, b, p){
   modify_field(meta.bm_0, a);
   modify_field(meta.bm_1, b);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

action ic0() { modify_field(meta.i2e_0, 0); clone_ingress_pkt_to_egress(0, i2e_0); }
action ic1() { modify_field(meta.i2e_1, 1); clone_ingress_pkt_to_egress(1, i2e_1); }
action ic2() { modify_field(meta.i2e_2, 2); clone_ingress_pkt_to_egress(2, i2e_2); }
action ic3() { modify_field(meta.i2e_3, 3); clone_ingress_pkt_to_egress(3, i2e_3); }
action ic4() { modify_field(meta.i2e_4, 4); clone_ingress_pkt_to_egress(4, i2e_4); }
action ic5() { modify_field(meta.i2e_5, 5); clone_ingress_pkt_to_egress(5, i2e_5); }
action ic6() { modify_field(meta.i2e_6, 6); clone_ingress_pkt_to_egress(6, i2e_6); }

action set_pkt(p){
   modify_field(ethernet.dstAddr, 0xffffffffffff);
}

action ec0() { modify_field(meta.e2e_0, 0); clone_egress_pkt_to_egress(0, e2e_0); }
action ec1() { modify_field(meta.e2e_1, 1); clone_egress_pkt_to_egress(1, e2e_1); }
action ec2() { modify_field(meta.e2e_2, 2); clone_egress_pkt_to_egress(2, e2e_2); }
action ec3() { modify_field(meta.e2e_3, 3); clone_egress_pkt_to_egress(3, e2e_3); }
action ec4() { modify_field(meta.e2e_4, 4); clone_egress_pkt_to_egress(4, e2e_4); }
action ec5() { modify_field(meta.e2e_5, 5); clone_egress_pkt_to_egress(5, e2e_5); }
action ec6() { modify_field(meta.e2e_6, 6); clone_egress_pkt_to_egress(6, e2e_6); }
action ec7() { modify_field(meta.e2e_7, 7); clone_egress_pkt_to_egress(7, e2e_7); }

table it0 {
   reads {
       ethernet.etherType mask 0xff: exact;
   }
   actions {
       set_bm;
       do_nothing;
   }
   size : 256;
}

table it1 {
   reads {
       ethernet.etherType mask 0xff: exact;
   }
   actions {
       ic0;
       ic1;
       ic2;
       ic3;
       ic4;
       ic5;
       ic6;
       do_nothing;
   }
   size : 256;
}

table et0 {
   reads {
       meta.bm_0 : exact;
       meta.bm_1 : exact;
   }
   actions {
       set_pkt;
       do_nothing;
   }
   size : 2048;
}

table et1 {
   reads {
       eg_intr_md_from_parser_aux.clone_src : exact;
       eg_intr_md.pkt_length : exact;
       ethernet.etherType : exact;
   }
   actions {
       ec0;
       ec1;
       ec2;
       ec3;
       ec4;
       ec5;
       ec6;
       ec7;
       do_nothing;
   }
   size : 1024;
}

control ingress {
   apply(it0);
   apply(it1);
}

control egress {
   if (eg_intr_md_from_parser_aux.clone_src == 0){
       apply(et0);
   }
   apply(et1);
}
