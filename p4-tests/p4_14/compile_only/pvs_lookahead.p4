#include <tofino/intrinsic_metadata.p4>

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

header ipv4_t ipv4;

@pragma parser_value_set_size 1
parser_value_set int_diffserv;

@pragma parser_value_set_size 4
parser_value_set int_inport;

parser start {
    return parse_ipv4;
}

parser parse_ipv4 {
   return select(ig_intr_md.ingress_port){
       int_inport: parse_ipv4_original;
       default: parse_ipv4_check_diffserv;
    }
}

// The field mapping for lookahead should look like below in the assembly.
//
//      value_set int_diffserv 4:
//        field_mapping:
//          packet.lookahead(0..7) : byte0(0..7)

parser parse_ipv4_check_diffserv {
   return select(current(8,8)){ //ipv4.diffserv
       int_diffserv: parse_intl45_ipv4;
       default: parse_ipv4_original;
    }
}

parser parse_intl45_ipv4 {
    extract(ipv4);
    return ingress;
}

parser parse_ipv4_original {
    extract(ipv4);
    return ingress;
}

control ingress { }

control egress { }


