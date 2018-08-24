#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>

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

field_list ipv4_field_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc {
    input {
        ipv4_field_list;
    }
    algorithm : csum16;
    output_width: 16;
}

calculated_field ipv4.hdrChecksum {
    update ipv4_chksum_calc;
}

parser start {
    return parse_ethernet;
}

@pragma packet_entry
parser start_i2e_mirrored {
    extract(ethernet);
    return select(latest.etherType) {
        0xbabe : parse_vlan;
        default : ingress;
    }
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0xbabe : parse_vlan;
        default : ingress;
    }
}

parser parse_vlan {
    extract(vlan_tag_);
    return select(latest.etherType) {
	0xbabe : parse_ipv4;
        default : ingress;
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
header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return ingress; 
}

action noop() {
    no_op();
}

header_type metadata_t {
  fields {
    do_ing_mirroring : 1;
    do_egr_mirroring : 1;
    ing_mir_ses : 10;
    egr_mir_ses : 10;
  }
}

metadata metadata_t md;

table ing_mir {
  actions { do_ing_mir; }
  default_action : do_ing_mir;
  size : 1;
}

action do_ing_mir() {
  clone_ingress_pkt_to_egress(md.ing_mir_ses);
}

control ingress {
    if (1 == md.do_ing_mirroring) {
        apply(ing_mir);
    }
}

control egress {
}
