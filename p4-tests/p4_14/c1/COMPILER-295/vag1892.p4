#ifdef __TARGET_TOFINO__
#include <tofino/intrinsic_metadata.p4>
#endif

header_type ethernet_t {
    fields {
        dstAddr    : 48;
        srcAddr    : 48;
        etherType  : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
    }
}

header ethernet_t ethernet;
header vlan_tag_t vlan_tag;
    
parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x8100 : parse_vlan_tag;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag);
    return ingress;
}
    
action set_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table port_based_egress {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_port;
    }
    size : 288;
}

table vid_based_egress {
    reads {
        vlan_tag.vid : exact;
    }
    actions {
        set_port;
    }
    size : 4096;
}
    
control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(port_based_egress);
    }
    
    if (valid(vlan_tag)) {
        apply(vid_based_egress);
    }
}
