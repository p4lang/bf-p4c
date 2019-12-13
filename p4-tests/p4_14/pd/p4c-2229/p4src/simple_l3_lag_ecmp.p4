/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

/*
 * Hash Module. We provide 3 different modules in this solution to demostrate
 * how one can modularize a P4 program.
 * 
 * The hash module is supposed to define the following:
 *  1) Controls that will be called from the ingress() control to calculate
 *     the hash. If they are not needed, then they should be empty
 *     1) calc_ipv4_hash() -- called for IPv4 packets only
 *     2) calc_ipv6_hash() -- called for IPv6 packets only
 *     3) calc_common_hash() -- called for all packets
 *  2) Action Selector lag_ecmp_selector that will be used for the 
 *     selection by lag_ecmp action profile. 
 *
 * By defining the actual selector, the hash module encapsulates everything 
 * with regards to member selection, including:
 *  1) The input to the hash calculation algorithm, including the ability 
 *     to dynamically change it
 *  2) The hash algorithm itself, including the ability to dynamically 
 *     change it.
 *  3) The member selection algorithm (fair or resilient)
 *
 * Since the number of required hash bits also depends on the maximum group
 * size, which is a pragma attached to the action profile, we will pass this 
 * information by allowing the user to define a preprocessor variable 
 * MAX_GROUP_SIZE that will be used in the pragma as well a inside the modules.
 *
 * The rules for MAX_GROUP_SIZE are as follows:
 *
 * if MAX_GROUP_SZIE <= 120:      subgroup_select_bits = 0
 * elif MAX_GROUP_SIZE <= 3840:   subgroup_select_bits = 10
 * elif MAX_GROUP_SIZE <= 119040: subgroup_select_bits = 15
 * else: ERROR
 *
 * The rules for the hash size are:
 *
 * FAIR:      14 + subgroup_select_bits
 * RESILIENT: 51 + subgroup_select_bits
 *
 * The hash module has access to everything defined in this file by nature of
 * all the objects being global in P4, but try to be reasonable.
 *
 */

/* 
 * This is common code that will be useful to the modules to decide 
 * how much hash to calculate
 */
#if defined(RESILIENT_SELECTION)

  #define SELECTION_MODE resilient

  #if MAX_GROUP_SIZE <= 120
    #define HASH_WIDTH 51
  #elif MAX_GROUP_SIZE <= 3840
    #ifdef P4C
      #define HASH_WIDTH 61
    #else
      #define HASH_WIDTH 66
    #endif
  #elif MAX_GROUP_SIZE <= 119040
    #define HASH_WIDTH 66
  #else
    #error "Maximum Group Size cannot exceed 119040 members on Tofino"
  #endif
#else

  #define SELECTION_MODE fair

  #if MAX_GROUP_SIZE <= 120
    #define HASH_WIDTH 14
  #elif MAX_GROUP_SIZE <= 3840
    #ifdef P4C
      #define HASH_WIDTH 24
    #else
      #define HASH_WIDTH 29
    #endif
  #elif MAX_GROUP_SIZE <= 119040
    #define HASH_WIDTH 29
  #else
    #error "Maximum Group Size cannot exceed 119040 members on Tofino"
  #endif
#endif

#if defined(RANDOM_HASH)
  #include "random_hash.p4"
#elif defined(ROUND_ROBIN_HASH)
  #include "round_robin_hash.p4"
#else /* This is the default */
  #include "ipv4_ipv6_hash.p4"
#endif

#ifndef MAX_GROUP_SIZE
  #define MAX_GROUP_SIZE 120
#endif

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp       : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type option_word_t {
    fields {
        data : 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode    : 16;
        checksum    : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        seqNo       : 32;
        ackNo       : 32;
        dataOffset  : 4;
        res         : 4;
        flags       : 8;
        window      : 16;
        checksum    : 16;
        urgentPtr   : 16;
    }
}

header_type udp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        length_     : 16;  /* length is a reserved word */
        checksum    : 16;
    }
}

header_type igmp_t {
 fields {
        typeCode    : 16;
        checksum    : 16;
    }
} 


/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type l3_meta_t {
    fields {
        nexthop_id : 16;
        ttl_dec    : 8;
    }
}
metadata l3_meta_t l3_meta;

header_type l4_lookup_t {
    fields {
        word_1     : 16;
        word_2     : 16;
        first_frag : 1;
    }
}   

metadata l4_lookup_t l4_lookup;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;
header vlan_tag_t vlan_tag[2];
header ipv4_t     ipv4;
header ipv6_t     ipv6;
header option_word_t  option_word_1;
header option_word_t  option_word_2;
header option_word_t  option_word_3;
header option_word_t  option_word_4;
header option_word_t  option_word_5;
header option_word_t  option_word_6;
header option_word_t  option_word_7;
header option_word_t  option_word_8;
header option_word_t  option_word_9;
header option_word_t  option_word_10;
header icmp_t     icmp;
header igmp_t     igmp;
header tcp_t      tcp;
header udp_t      udp;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x86DD : parse_ipv6;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x86DD : parse_ipv6;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.ihl) {
        0x5 : parse_ipv4_no_options;
        0x6 : parse_ipv4_options_1;
        0x7 : parse_ipv4_options_2;
        0x8 : parse_ipv4_options_3;
        0x9 : parse_ipv4_options_4;
        0xA : parse_ipv4_options_5;
        0xB : parse_ipv4_options_6;
        0xC : parse_ipv4_options_7;
        0xD : parse_ipv4_options_8; 
        0xE : parse_ipv4_options_9; 
        0xF : parse_ipv4_options_10;
        default: ingress;
    }
}

parser parse_ipv4_options_1 {
    extract(option_word_1);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_2 {
    extract(option_word_1);
    extract(option_word_2);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_3 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_4 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_5 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_6 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    extract(option_word_6);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_7 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    extract(option_word_6);
    extract(option_word_7);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_8 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    extract(option_word_6);
    extract(option_word_7);
    extract(option_word_8);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_9 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    extract(option_word_6);
    extract(option_word_7);
    extract(option_word_8);
    extract(option_word_9);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_10 {
    extract(option_word_1);
    extract(option_word_2);
    extract(option_word_3);
    extract(option_word_4);
    extract(option_word_5);
    extract(option_word_6);
    extract(option_word_7);
    extract(option_word_8);
    extract(option_word_9);
    extract(option_word_10);
    return parse_ipv4_no_options;
}

parser parse_ipv4_no_options {
    set_metadata(l4_lookup.word_1, current(0, 16));
    set_metadata(l4_lookup.word_2, current(16, 16));

    return select(ipv4.fragOffset, ipv4.protocol) {
        0x000001 : parse_icmp;
        0x000002 : parse_igmp;
        0x000006 : parse_tcp;
        0x000011 : parse_udp;
        0x000000 mask 0x1FFF00 : parse_first_fragment;
        default  : ingress;
    }
}

field_list ipv4_checksum_fields {
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
    option_word_1.data;
    option_word_2.data;
    option_word_3.data;
    option_word_4.data;
    option_word_5.data;
    option_word_6.data;
    option_word_7.data;
    option_word_8.data;
    option_word_9.data;
    option_word_10.data;
}

parser parse_first_fragment {
    set_metadata(l4_lookup.first_frag, 1);
    return ingress;
}

parser parse_ipv6 {
    extract(ipv6);
    
    set_metadata(l4_lookup.word_1, current(0, 16));
    set_metadata(l4_lookup.word_2, current(16, 16));
    
    return select(ipv6.nextHdr) {
        0x01 : parse_icmp;
        0x02 : parse_igmp;
        0x06 : parse_tcp;
        0x11 : parse_udp;
        default: ingress;
    }
}

parser parse_icmp {
    extract(icmp);
    return parse_first_fragment;
}

parser parse_igmp {
    extract(igmp);
    return parse_first_fragment;
}

parser parse_tcp {
    extract(tcp);
    return parse_first_fragment;
}

parser parse_udp {
    extract(udp);
    return parse_first_fragment;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
/*
 * Route lookups 
 */
action set_nexthop(nexthop_id) {
    modify_field(l3_meta.nexthop_id, nexthop_id);
}

action on_miss() {}

/*
 * IPv4 Lookup
 */
table ipv4_host {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {set_nexthop; on_miss; }
    default_action: on_miss();
    size : 131072;
}

table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions { set_nexthop; }
    default_action: set_nexthop(0);
    size : 12288;
}

/*
 * IPv6 Lookup
 */
table ipv6_host {
    reads {
        ipv6.dstAddr : exact;
    }
    actions {set_nexthop;  on_miss; }
    default_action: on_miss();
    size : 32768;
}

table ipv6_lpm {
    reads {
        ipv6.dstAddr : lpm;
    }
    actions { set_nexthop; }
    default_action: set_nexthop(0);
    size : 4096;
}

/* 
 * Nexthop resolution
 */
action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

action l3_switch(new_mac_da, new_mac_sa, port) {
    modify_field(ethernet.dstAddr, new_mac_da);
    modify_field(ethernet.srcAddr, new_mac_sa);
    modify_field(l3_meta.ttl_dec, 1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

/*
 * The selector lag_ecmp_selector is defined in one of the included modules
*/

action_profile lag_ecmp {
    actions {
        send;
        discard;
        l3_switch;
    }
    size : 32768;
    dynamic_action_selection: lag_ecmp_selector;
}

#ifdef ROUND_ROBIN_HASH
@pragma selector_enable_scramble 0
#endif
@pragma selector_max_group_size MAX_GROUP_SIZE
table nexthop {
    reads {
        l3_meta.nexthop_id : exact;
    }
    action_profile: lag_ecmp;
    size : 8192;
}

control ingress {
    calc_common_hash();
    if (valid(ipv4) and (ipv4.ttl & 0xFE != 0)) {
        calc_ipv4_hash();
        apply(ipv4_host) {
            on_miss {
                apply(ipv4_lpm);
            }
        }
    } else if (valid(ipv6) and (ipv6.hopLimit & 0xFE != 0)) {
        calc_ipv6_hash();
        apply(ipv6_host) {
            on_miss {
                apply(ipv6_lpm);
            }
        }
    } 
    apply(nexthop);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action do_decrement_ttl() {
    subtract_from_field(ipv4.ttl, l3_meta.ttl_dec);
}

table decrement_ttl {
    actions        { do_decrement_ttl; }
    default_action : do_decrement_ttl();
    size           : 1;
}

action do_decrement_hopLimit() {
    subtract_from_field(ipv6.hopLimit, l3_meta.ttl_dec);
}

table decrement_hopLimit {
    actions        { do_decrement_hopLimit; }
    default_action : do_decrement_hopLimit();
    size           : 1;
}

control egress {
    if (valid(ipv4)) {
        apply(decrement_ttl);
    } else if (valid(ipv6)) {
        apply(decrement_hopLimit);
    }
}
