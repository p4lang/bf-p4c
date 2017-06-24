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

/* go to parse_ethernet_mirror for mirrored packet
   eg_intr_md_from_parser_aux.clone_src != not_cloned */
@pragma dont_trim
parser start_egress_mirrored {
    return parse_ethernet_mirror;
}

parser parse_ethernet_mirror {
    extract(ethernet);
    return ingress;
}

action nop() {
}

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_egr; nop;
    }
    size : 1024;
}

action e2e_mirror(mirror_id) {
    clone_egress_pkt_to_egress(mirror_id);
}

table egress_mirror {
    reads {
        vlan_tag: valid;
        vlan_tag.vid : exact;
    }
    actions {
        e2e_mirror;
    }
    size : 16;
}

// if packet is mirrored and parsed in a different branch, change eth_src
action do_change_eth_src() {
    modify_field(ethernet.srcAddr, 0xaaaaaaaaaaaa);
}

table change_eth_src {
    actions {
        do_change_eth_src;
    }
    size : 1;
}

control ingress {
    apply(forward);
}

control egress {
    if (pkt_is_not_mirrored) {
         apply(egress_mirror);
    }

    // mirror packet parsed in different branch
    if (not valid(vlan_tag)) {
        apply(change_eth_src);
    }
}
