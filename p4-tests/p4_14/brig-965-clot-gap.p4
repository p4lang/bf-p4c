#include <tofino/constants.p4>
#if __TARGET_TOFINO__ == 2
#include <tofino2/intrinsic_metadata.p4>
#else
#include <tofino/intrinsic_metadata.p4>
#endif
#include <tofino/primitives.p4>

#define VLAN_DEPTH             2
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
header vlan_tag_t vlan_tag_;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        0x8ABC : long_parse_0;
        default : ingress;
    }
}

parser parse_vlan {
    extract(vlan_tag_);
    return select(latest.etherType) {
        0x8ABC : long_parse_0;
        default : ingress;
    }
}

header_type dummy_t {
  fields { foo : 16; }
}
header dummy_t d0;
header dummy_t d1;

parser long_parse_0 {
    extract(d0);
    return select(current(0,8)) {
        0xCC : long_parse_1;
        default : ingress;
    }
}
parser long_parse_1 {
    extract(d1);
    return ingress;
}

control ingress {}
