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

header_type i2e_mirror_only_t {
    fields {
        data : 8;
    }
}

header_type e2e_mirror_only_t {
    fields {
        data : 16;
    }
}

header ethernet_t ethernet;
header vlan_tag_t vlan_tag;
header i2e_mirror_only_t i2e_mirror_only;
header e2e_mirror_only_t e2e_mirror_only;

parser start {
  return parse_ethernet;
}

@pragma packet_entry
parser start_i2e_mirrored {
    extract(i2e_mirror_only);
    return parse_ethernet_mirror;
}

@pragma packet_entry
parser start_e2e_mirrored {
    extract(e2e_mirror_only);
    return parse_vlan;
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

parser parse_ethernet_mirror {
    extract(ethernet);
    return ingress;
}

action i2e_mirror(mirror_id) {
    // This will result in the egress parser starting in the
    // 'start_i2e_mirrored' state.
    clone_ingress_pkt_to_egress(mirror_id);
}

table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        i2e_mirror;
    }
    size : 1024;
}

action e2e_mirror(mirror_id) {
    // This will result in the egress parser starting in the
    // 'start_e2e_mirrored' state.
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

action change_i2e_data() {
    modify_field(i2e_mirror_only.data, 0);
}

action change_e2e_data() {
    modify_field(e2e_mirror_only.data, 0);
}

table egress_mirror_check {
    reads {
        i2e_mirror_only: valid;
        e2e_mirror_only : valid;
    }
    actions {
        change_i2e_data; change_e2e_data;
    }
    size : 4;
}

control ingress {
    apply(forward);
}

control egress {
    if (pkt_is_not_mirrored) {
         apply(egress_mirror);
    }
    if (pkt_is_mirrored) {
         apply(egress_mirror_check);
    }
}

