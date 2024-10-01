#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pri    : 3;
        cfi    : 1;
        vid    : 12;
    }
}

header ethernet_t ethernet;
header vlan_tag_t vlan_tag;

parser start {
    extract(ethernet);
    return select(latest.ethertype) {
        0x8100 : parse_vlan_tag;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag);
    return ingress;
}

metadata vlan_tag_t vtag;

action a1(p1, p2) {
    modify_field(vtag.pri, p1);
    modify_field(vtag.cfi, 1);
    add_to_field(vtag.vid, p2);
}

table t1 {
    actions {
        a1;
    }
}

action a2(p1) {
    modify_field(vlan_tag.pri, p1);
    modify_field(vlan_tag.cfi, vtag.cfi);
    modify_field(vlan_tag.vid, vtag.vid);
}

table t2 {
    actions {
        a2;
    }
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress {
}
