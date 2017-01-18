/*
 * IPv6 processing
 */

/*
 * IPv6 Metadata
 */
header_type ipv6_metadata_t {
    fields {
        lkp_ipv6_sa : 128;                     /* ipv6 source address */
        lkp_ipv6_da : 128;                     /* ipv6 destination address*/

        ipv6_unicast_enabled : 1;              /* is ipv6 unicast routing enabled on BD */
        ipv6_src_is_link_local : 1;            /* source is link local address */
        ipv6_urpf_mode : 2;                    /* 0: none, 1: strict, 3: loose */
    }
}

#if !defined(IPV4_DISABLE) && !defined(IPV6_DISABLE)
@pragma pa_alias ingress ipv4_metadata.lkp_ipv4_sa ipv6_metadata.lkp_ipv6_sa
@pragma pa_alias ingress ipv4_metadata.lkp_ipv4_da ipv6_metadata.lkp_ipv6_da
#endif /* !IPV4_DISABLE && !IPV6_DISABLE */

metadata ipv6_metadata_t ipv6_metadata;

#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE)
/*****************************************************************************/
/* Validate outer IPv6 header                                                */
/*****************************************************************************/
action set_valid_outer_ipv6_packet() {
    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV6);
    modify_field(l3_metadata.lkp_ip_tc, ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_version, ipv6.version);
}

action set_malformed_outer_ipv6_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, TRUE);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

/*
 * Table: Validate ipv6 packet
 * Lookup: Ingress
 * Validate and extract ipv6 header
 */
table validate_outer_ipv6_packet {
    reads {
        ipv6.version : ternary;
        ipv6.hopLimit : ternary;
        ipv6.srcAddr mask 0xFFFF0000000000000000000000000000 : ternary;
    }
    actions {
        set_valid_outer_ipv6_packet;
        set_malformed_outer_ipv6_packet;
    }
    size : VALIDATE_PACKET_TABLE_SIZE;
}
#endif /* L3_DISABLE && IPV6_DISABLE */

control validate_outer_ipv6_header {
#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE)
    apply(validate_outer_ipv6_packet);
#endif /* L3_DISABLE && IPV6_DISABLE */
}

#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE)
/*****************************************************************************/
/* IPv6 FIB lookup                                                           */
/*****************************************************************************/
/*
 * Actions are defined in l3.p4 since they are
 * common for both ipv4 and ipv6
 */

#ifdef ALPM
action set_ipv6_fib_partition_index(partition_index) {
    modify_field(l3_metadata.fib_partition_index, partition_index);
}

table ipv6_fib_partition {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
    }
    actions {
        set_ipv6_fib_partition_index;
    }
    size : IPV6_FIB_PARTITION_TABLE_SIZE;
}
#endif /* ALPM */

/*
 * Table: Ipv6 LPM Lookup
 * Lookup: Ingress
 * Ipv6 route lookup for longest prefix match entries
 */
#ifdef ALPM
@pragma atcam_number_partitions IPV6_FIB_PARTITION_TABLE_SIZE
@pragma atcam_partition_index l3_metadata.fib_partition_index
@pragma ways 5
#endif /* ALPM */

table ipv6_fib_lpm {
    reads {
#ifdef ALPM
        l3_metadata.fib_partition_index : exact;
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
#else /* ALPM */
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : lpm;
#endif /* ALPM */
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : IPV6_LPM_TABLE_SIZE;
}

/*
 * Table: Ipv6 Host Lookup
 * Lookup: Ingress
 * Ipv6 route lookup for /128 entries
 */
table ipv6_fib {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : IPV6_HOST_TABLE_SIZE;
}
#endif /* L3_DISABLE && IPV6_DISABLE */

control process_ipv6_fib {
#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE)
#if defined(ALPM)
    apply(ipv6_fib_partition);
#endif /* ALPM */
    apply(ipv6_fib) {
        on_miss {
            apply(ipv6_fib_lpm);
        }
    }
#endif /* L3_DISABLE && IPV6_DISABLE */
}

#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE) && !defined(URPF_DISABLE)
/*****************************************************************************/
/* IPv6 uRPF lookup                                                          */
/*****************************************************************************/
action ipv6_urpf_hit(urpf_bd_group) {
    modify_field(l3_metadata.urpf_hit, TRUE);
    modify_field(l3_metadata.urpf_bd_group, urpf_bd_group);
    modify_field(l3_metadata.urpf_mode, ipv6_metadata.ipv6_urpf_mode);
}

table ipv6_urpf_lpm {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_sa : lpm;
    }
    actions {
        ipv6_urpf_hit;
        urpf_miss;
    }
    size : IPV6_LPM_TABLE_SIZE;
}

table ipv6_urpf {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_sa : exact;
    }
    actions {
        on_miss;
        ipv6_urpf_hit;
    }
    size : IPV6_HOST_TABLE_SIZE;
}
#endif /* L3_DISABLE && IPV6_DISABLE && URPF_DISABLE */

control process_ipv6_urpf {
#if !defined(L3_DISABLE) && !defined(IPV6_DISABLE) && !defined(URPF_DISABLE)
    /* unicast rpf lookup */
    if (ipv6_metadata.ipv6_urpf_mode != URPF_MODE_NONE) {
        apply(ipv6_urpf) {
            on_miss {
                apply(ipv6_urpf_lpm);
            }
        }
    }
#endif /* L3_DISABLE && IPV6_DISABLE && URPF_DISABLE */
}
