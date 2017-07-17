header_type pkt_t {
    fields {
        srcAddr : 32;
        dstAddr : 32;
        protocol : 8;
        srcPort : 16;
        dstPort : 16;
    }
}

header_type pkt2_t {
    fields {
        a : 32;
        b : 16;
    }
}

parser start {
    return parse_1;
}

header pkt_t pkt;
header pkt2_t pkt2;

@pragma terminate_parsing egress
parser parse_1 {
    extract(pkt);
    return parse_2;
}

parser parse_2 {
    extract(pkt2);
    return ingress;
}

action do_nothing(){}

action action1(){ 
    modify_field(pkt.srcAddr, 1);
}

table table1 {
   reads {
       pkt.srcPort : ternary;
   }
   actions {
       action1;
       do_nothing;
   }
}

control ingress {
   if (valid(pkt)){
           apply(table1);
   }
}