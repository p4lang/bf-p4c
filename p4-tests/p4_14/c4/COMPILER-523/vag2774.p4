/*
mpls_strip.p4 - P4_14 PoC program to strip 8 mpls labels in presence of up to 2 VLAN tags

use simple_switch_CLI to set tables as follows:

table_set_default mpls_tbl nop
table_add mpls_tbl mpls_strip 1 1 0x0000 =>
table_add mpls_tbl mpls_strip 1 0 0x0800 =>
table_add mpls_tbl mpls_strip 1 0 0x86dd =>
table_add rewrite_tbl rewrite_outer_ethtype 0 0 =>
table_add rewrite_tbl rewrite_vlan0_ethtype 1 0 =>
table_add rewrite_tbl rewrite_vlan1_ethtype 1 1 =>
*/

#include <tofino/intrinsic_metadata.p4> // tofino only
#include <tofino/constants.p4> // tofino only

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

#define VLAN_DEPTH 2
header vlan_tag_t vlan_tag_[VLAN_DEPTH];

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}

#define MPLS_DEPTH 8
header mpls_t mpls[MPLS_DEPTH];

header_type metadata_t {
    fields {
	pw_ctrl_word_present : 1;
	mpls_tunnel_type : 16;
    }
}

metadata metadata_t meta;

parser start {
    return parse_ethernet;
}

#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_QINQ 0x88A8
#define ETHERTYPE_QINQ_OBS 0x9100
#define ETHERTYPE_MPLS 0x8847

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_QINQ : parse_vlan;
        ETHERTYPE_QINQ_OBS : parse_vlan;
	ETHERTYPE_MPLS : parse_mpls;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan_tag_[next]);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
	ETHERTYPE_MPLS : parse_mpls;
        default : ingress;
    }
}

parser parse_mpls {
    extract(mpls[next]);
    return select(latest.bos) {
        0 : parse_mpls;
        1 : parse_mpls_bos;
        default: ingress;
    }
}

parser parse_mpls_bos {
	return select(current(0, 4)) {
	0x0 : parse_mpls_pw_ctrl;
	0x4 : parse_mpls_inner_ipv4;
	0x6 : parse_mpls_inner_ipv6;
	default: ingress;
    }
}

parser parse_mpls_pw_ctrl {
    set_metadata(meta.pw_ctrl_word_present,1);
    set_metadata(meta.mpls_tunnel_type, 0);
    return ingress;
}

parser parse_mpls_inner_ipv4 {
    set_metadata(meta.mpls_tunnel_type, ETHERTYPE_IPV4);
    return ingress;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(meta.mpls_tunnel_type, ETHERTYPE_IPV6);
    return ingress;
}


action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec); // tofino only
    //modify_field(standard_metadata.egress_spec, egress_spec); // bmv2 only
}

action nop() {
    set_egr(2);
}

action _drop() {
    drop();
}

// rewrite mpls payload's ethertype to outer ethernet
action rewrite_outer_ethtype() {
    modify_field(ethernet.etherType, meta.mpls_tunnel_type);
}

// rewrite mpls payload's ethertype to vlan tag
action rewrite_vlan0_ethtype() {
    modify_field(vlan_tag_[0].etherType, meta.mpls_tunnel_type);
}

// rewrite mpls payload's ethertype to outer vlan tag
action rewrite_vlan1_ethtype() {
    modify_field(vlan_tag_[1].etherType, meta.mpls_tunnel_type);
}
   
table rewrite_tbl {
    reads {
	vlan_tag_[0]:				valid;
	vlan_tag_[1]:				valid;
    }
    
    actions { 
	rewrite_outer_ethtype;
	rewrite_vlan0_ethtype;
	rewrite_vlan1_ethtype;
	nop;
    }
    max_size: 3;
}

action mpls_strip() {
    // blindly set all MPLS tags invalid
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    remove_header(mpls[3]);
    remove_header(mpls[4]);
    remove_header(mpls[5]);
    remove_header(mpls[6]);
    remove_header(mpls[7]);
    set_egr(2);
}

table mpls_tbl {
    reads {
	mpls[0]:		        valid; 
	meta.pw_ctrl_word_present:	exact; // only strip non-IPv4/6 if pw word present
	meta.mpls_tunnel_type:		exact;
    }

    actions { 
	mpls_strip;
	nop;
    }
    max_size: 3;
}

control ingress {
    apply(mpls_tbl) {
	hit {
	    apply(rewrite_tbl);
	}
    }
}

control egress {
}

