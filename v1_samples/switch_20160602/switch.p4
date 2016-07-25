#ifdef __TARGET_BMV2__
#define BMV2
#endif

#if defined(__TARGET_TOFINO__) && 0
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

#include "includes/p4features.h"
#include "includes/drop_reasons.h"
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/p4_table_sizes.h"
#include "includes/defines.p4"

@pragma pa_alias ingress ig_intr_md.ingress_port ingress_metadata.ingress_port

/* METADATA */
header_type ingress_metadata_t {
    fields {
        ingress_port : 9;                      /* input physical port */
        ifindex : IFINDEX_BIT_WIDTH;           /* input interface index */
        egress_ifindex : IFINDEX_BIT_WIDTH;    /* egress interface index */
        port_type : 2;                         /* ingress port type */

        outer_bd : BD_BIT_WIDTH;               /* outer BD */
        bd : BD_BIT_WIDTH;                     /* BD */

        drop_flag : 1;                         /* if set, drop the packet */
        drop_reason : 8;                       /* drop reason */
        control_frame: 1;                      /* control frame */
        sflow_take_sample : 32 (saturating);
        bypass_lookups : 16;                   /* list of lookups to skip */
    }
}

header_type egress_metadata_t {
    fields {
        bypass : 1;                            /* bypass egress pipeline */
        port_type : 2;                         /* egress port type */
        payload_length : 16;                   /* payload length for tunnels */
        smac_idx : 9;                          /* index into source mac table */
        bd : BD_BIT_WIDTH;                     /* egress inner bd */
        outer_bd : BD_BIT_WIDTH;               /* egress inner bd */
        mac_da : 48;                           /* final mac da */
        routed : 1;                            /* is this replica routed */
        same_bd_check : BD_BIT_WIDTH;          /* ingress bd xor egress bd */
        drop_reason : 8;                       /* drop reason */
        ifindex : IFINDEX_BIT_WIDTH;           /* egress interface index */
    }
}

header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 16;                        /* multicast group */
        lf_field_list : 32;                    /* Learn filter field list */
        egress_rid : 16;                       /* replication index */
        ingress_global_timestamp : 32;
    }
}

/* Global config information */
header_type global_config_metadata_t {
    fields {
        enable_dod : 1;                        /* Enable Deflection-on-Drop */
    }
}

#ifdef SFLOW_ENABLE
@pragma pa_atomic ingress ingress_metadata.sflow_take_sample
@pragma pa_solitary ingress ingress_metadata.sflow_take_sample
#endif
@pragma pa_atomic ingress ingress_metadata.port_type
@pragma pa_solitary ingress ingress_metadata.port_type
@pragma pa_atomic ingress ingress_metadata.ifindex
@pragma pa_solitary ingress ingress_metadata.ifindex
@pragma pa_atomic egress ingress_metadata.bd
@pragma pa_solitary egress ingress_metadata.bd

metadata ingress_metadata_t ingress_metadata;
metadata egress_metadata_t egress_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;
metadata global_config_metadata_t global_config_metadata;

#include "switch_config.p4"
#ifdef OPENFLOW_ENABLE
#include "openflow.p4"
#endif /* OPENFLOW_ENABLE */
#include "port.p4"
#include "l2.p4"
#include "l3.p4"
#include "ipv4.p4"
#include "ipv6.p4"
#include "tunnel.p4"
#include "acl.p4"
#include "nat.p4"
#include "multicast.p4"
#include "nexthop.p4"
#include "rewrite.p4"
#include "security.p4"
#include "fabric.p4"
#include "egress_filter.p4"
#include "mirror.p4"
#include "int_plt.p4"
#include "hashes.p4"
#include "meter.p4"
#include "sflow.p4"
#include "flowlet.p4"


action nop() {
}

action on_miss() {
}

control ingress {
    /* input mapping - derive an ifindex */
    process_ingress_port_mapping();

    /* process outer packet headers */
    process_validate_outer_header();

    /* read and apply system confuration parametes */
    process_global_params();

    /* int_source, int_terminate, plt upstream change detection */
    process_int_endpoint();

#ifdef OPENFLOW_ENABLE
    if (ingress_metadata.port_type == PORT_TYPE_CPU) {
        apply(packet_out);
    }
#endif /* OPENFLOW_ENABLE */

    /* derive bd and its properties  */
    process_port_vlan_mapping();

    /* spanning tree state checks */
    process_spanning_tree();

    /* IPSG */
    process_ip_sourceguard();

    /* ingress sflow determination */
    process_ingress_sflow();

    /* tunnel termination processing */
    process_tunnel();

    /* storm control */
    process_storm_control();

    if (ingress_metadata.port_type != PORT_TYPE_FABRIC) {
#ifndef MPLS_DISABLE
        if (not (valid(mpls[0]) and (l3_metadata.fib_hit == TRUE))) {
#endif /* MPLS_DISABLE */

            /* validate packet */
            process_validate_packet();

            /* l2 lookups */
            process_mac();

            /* port and vlan ACL */
            if (l3_metadata.lkp_ip_type == IPTYPE_NONE) {
                process_mac_acl();
            } else {
                process_ip_acl();
            }

            /* INT i2e mirror */
            process_int_upstream_report();

            process_qos();

            apply(rmac) {
                rmac_miss {
                    process_multicast();
                }
                default {
                    if (DO_LOOKUP(L3)) {
                        if ((l3_metadata.lkp_ip_type == IPTYPE_IPV4) and
                            (ipv4_metadata.ipv4_unicast_enabled == TRUE)) {
                            /* router ACL/PBR */
                            process_ipv4_racl();
                            process_ipv4_urpf();
                            process_ipv4_fib();

                        } else {
                            if ((l3_metadata.lkp_ip_type == IPTYPE_IPV6) and
                                (ipv6_metadata.ipv6_unicast_enabled == TRUE)) {
                                /* router ACL/PBR */
                                process_ipv6_racl();
                                process_ipv6_urpf();
                                process_ipv6_fib();
                            }
                        }
                        process_urpf_bd();
                    }
                }
            }

            /* ingress NAT */
            process_ingress_nat();

#ifndef MPLS_DISABLE
        }
#endif /* MPLS_DISABLE */
    }

    /* INT sink: update outer headers */
    process_int_sink_update_outer();

    process_meter_index();

    /* compute hashes based on packet type  */
    process_hashes();

    process_meter_action();

    if (ingress_metadata.port_type != PORT_TYPE_FABRIC) {
        /* update statistics */
        process_ingress_bd_stats();
        process_ingress_acl_stats();
        process_storm_control_stats();

        /* decide final forwarding choice */
        process_fwd_results();

#ifdef FLOWLET_ENABLE
        /* flowlet */
        process_flowlet();
#endif /* FLOWLET_ENABLE */

        /* ecmp/nexthop lookup */
        process_nexthop();

        if (ingress_metadata.egress_ifindex == IFINDEX_FLOOD) {
            /* resolve multicast index for flooding */
            process_multicast_flooding();
        } else {
            /* resolve final egress port for unicast traffic */
            process_lag();
        }

#ifdef OPENFLOW_ENABLE
        /* openflow processing for ingress */
        process_ofpat_ingress();
#endif /* OPENFLOW_ENABLE */

        /* generate learn notify digest if permitted */
        process_mac_learning();
    }

    /* resolve fabric port to destination device */
    process_fabric_lag();

    if (ingress_metadata.port_type != PORT_TYPE_FABRIC) {
        /* system acls */
        process_system_acl();
    }
}

control egress {

#ifdef OPENFLOW_ENABLE
    if (openflow_metadata.ofvalid == TRUE) {
        process_ofpat_egress();
    } else {
#endif /* OPENFLOW_ENABLE */
        /* check for -ve mirrored pkt */
        if ((eg_intr_md.deflection_flag == FALSE) and
            (egress_metadata.bypass == FALSE)) {

            /* INT processing part 1 */
            process_int_egress_prep();

            /* check if pkt is mirrored */
            if (pkt_is_mirrored) {

                /* mirror processing */
                process_mirroring();
            } else {

                /* multi-destination replication */
                process_replication();
            }

            /* determine egress port properties */
            apply(egress_port_mapping) {
                egress_port_type_normal {
                    if (pkt_is_not_mirrored) {
                        /* strip vlan header */
                        process_vlan_decap();
                    }

                    /* perform tunnel decap */
                    process_tunnel_decap();

                    /* apply nexthop_index based packet rewrites */
                    process_rewrite();

                    /* egress bd properties */
                    process_egress_bd();

                    /* rewrite source/destination mac if needed */
                    process_mac_rewrite();

                    /* egress mtu checks */
                    process_mtu();

                    /* egress nat processing */
                    process_egress_nat();

                    /* update egress bd stats */
                    process_egress_bd_stats();
                }
            }

            /* INT processing part 2 */
            process_int_egress();

            /* perform tunnel encap */
            process_tunnel_encap();

            /* update underlay header based on INT information inserted */
            process_int_outer_encap();

            if (egress_metadata.port_type == PORT_TYPE_NORMAL) {
                /* egress vlan translation */
                process_vlan_xlate();
            }

            /* egress filter */
            process_egress_filter();
        }

        /* apply egress acl */
        process_egress_acl();
#ifdef OPENFLOW_ENABLE
    }
#endif /* OPENFLOW_ENABLE */
}
