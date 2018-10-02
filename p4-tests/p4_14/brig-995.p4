#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>

#define PORT_LAG_INDEX_BIT_WIDTH               10
#define IFINDEX_BIT_WIDTH                      14
#define BD_BIT_WIDTH                           14

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

/* METADATA */
header_type ingress_metadata_t {
    fields {
        ingress_port : 9;                         /* input physical port */
        port_lag_index : PORT_LAG_INDEX_BIT_WIDTH;      /* ingress port index */
        egress_port_lag_index : PORT_LAG_INDEX_BIT_WIDTH;/* egress port index */
        ifindex : IFINDEX_BIT_WIDTH;              /* ingress interface index */
        egress_ifindex : IFINDEX_BIT_WIDTH;       /* egress interface index */
        port_type : 2;                         /* ingress port type */

        outer_bd : BD_BIT_WIDTH;               /* outer BD */
        bd : BD_BIT_WIDTH;                     /* BD */

        drop_flag : 1;                         /* if set, drop the packet */
        drop_reason : 8;                       /* drop reason */

        control_frame: 1;                      /* control frame */
        bypass_lookups : 8;                    /* list of lookups to skip */
	padding : 7;
    }
}

#define VLAN_DEPTH 2
header vlan_tag_t vlan_tag_[VLAN_DEPTH];
header ethernet_t ethernet;
header ingress_metadata_t ingress_metadata;

parser start {
    return select(current(96, 16)) { // ether.type
        default : parse_ethernet;
    }
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
	default: parse_vlan;
    }
}

parser parse_vlan {
    extract(vlan_tag_[0]);
    return select(latest.etherType) {
        0x800 : ingress;
    }
}

//-------------------------
// BD Properties
//-------------------------
action set_bd_properties(bd, vrf, stp_group, learning_enabled,
                         bd_label, stats_idx, rmac_group,
                         ipv4_unicast_enabled, ipv6_unicast_enabled,
                         ipv4_urpf_mode, ipv6_urpf_mode,
                         igmp_snooping_enabled, mld_snooping_enabled,
                         ipv4_multicast_enabled, ipv6_multicast_enabled,
                         mrpf_group,
                         ipv4_mcast_key, ipv4_mcast_key_type,
                         ipv6_mcast_key, ipv6_mcast_key_type,
                         ingress_rid) {
    modify_field(ingress_metadata.bd, bd);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action port_vlan_mapping_miss() {
    modify_field(ingress_metadata.drop_flag, 1);
}

action_profile bd_action_profile {
    actions {
        set_bd_properties;
        port_vlan_mapping_miss;
    }
    size : 1024;
}

action no_op(){}

//---------------------------------------------------------
// {port, vlan} -> BD mapping
// For Access ports, L3 interfaces and L2 sub-ports
//---------------------------------------------------------
table port_vlan_to_bd_mapping {
    reads {
        ingress_metadata.port_lag_index : ternary;
        vlan_tag_[0] : valid;
        vlan_tag_[0].vid : ternary;
    }
    action_profile: bd_action_profile;
    const default_action: no_op();
    size : 1024;
}

//--------------------------------------------------------
// vlan->BD mapping for trunk ports
//--------------------------------------------------------
table vlan_to_bd_mapping {
    reads {
        vlan_tag_[0].vid : exact;
    }
    action_profile: bd_action_profile;
    const default_action: no_op();
    size : 1024;
}

control process_port_vlan_mapping {
    apply(port_vlan_to_bd_mapping) {
	    miss { apply(vlan_to_bd_mapping); }
    }
}

control ingress {
    /* derive bd and its properties  */
    process_port_vlan_mapping();
}

control egress {}
