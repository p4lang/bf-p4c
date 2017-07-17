// This test includes 'eg_intr_md_from_parser_aux.egress_global_tstamp' in a
// field list used for mirroring, and additionally reads from
// 'eg_intr_md_from_parser_aux.egress_global_ver'. This mix of cases (one
// sometimes comes from the mirrored field list, one never does) should compile
// successfully.

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>

#define ETHERTYPE_VLAN         0x8100
#define ETHERTYPE_IPV4         0x0800

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header ethernet_t ethernet;
header vlan_tag_t vlan_tag;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        default : ingress;
    }
}

parser parse_vlan {
    extract(vlan_tag);
    return ingress;
}

action nop() {
}

action set_egr() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 2);
}

table forward {
    actions { set_egr; }
    size : 1;
}

field_list mirror_info {
    eg_intr_md_from_parser_aux.egress_global_tstamp;
}

action e2e_mirror() {
    clone_egress_pkt_to_egress(1, mirror_info);
}

table egress_mirror {
    reads { eg_intr_md_from_parser_aux.egress_global_tstamp : ternary; }
    actions { e2e_mirror; }
    size : 1024;
}

action do_change_eth_src() {
    modify_field(ethernet.srcAddr, eg_intr_md_from_parser_aux.egress_global_tstamp);
}

table change_eth_src {
    reads {
      eg_intr_md_from_parser_aux.egress_global_tstamp : ternary;
      eg_intr_md_from_parser_aux.egress_global_ver : ternary;
    }
    actions { do_change_eth_src; }
    size : 1024;
}

control ingress {
    apply(forward);
}

control egress {
    if (pkt_is_not_mirrored) {
         apply(egress_mirror);
    } else {
         apply(change_eth_src);
    }
}
