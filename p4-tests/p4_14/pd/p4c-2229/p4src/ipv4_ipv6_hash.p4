/* 
 * ipv4_ipv6_hash.p4
 * 
 * This file is intended to be included by simple_l3_lag_ecmp.p4 and provides
 * hash calculation, based on IPv4/IPv6 headers
 *
 * The hash module is supposed to define the following:
 *  1) Controls that will be called from the ingress() control to calculate
 *     hash. If they are not needed, then they should be empty
 *     1) calc_ipv4_hash() -- called for IPv4 packets only
 *     2) calc_ipv6_hash() -- called for IPv6 packets only
 *     3) calc_common_hash() -- called for all packets
 *  2) Action Selector lag_ecmp_selector that will be used for the 
 *     selection by lag_ecmp action profile. 
 *
 */


/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

header_type hash_meta_t {
    fields {
        hash1 : 32;
        hash2 : 32;
        hash3 : 32;
    }
}

metadata hash_meta_t hash_meta;

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

/*
 * Hash (pre) calculation
*/
field_list ipv4_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    l4_lookup.word_1;
    l4_lookup.word_2;
}

field_list ipv6_hash_fields {
    ipv6.srcAddr;
    ipv6.dstAddr;
    ipv6.nextHdr;
    l4_lookup.word_1;
    l4_lookup.word_2;
}

#define CALC_HASH_32(num, proto, algo)                           \
  field_list_calculation proto##_hash##num {                     \
    input        { proto##_hash_fields; }                        \
    algorithm    : algo;                                         \
    output_width : 32;                                           \
  }                                                              \
                                                                 \
  action do_calc_##proto##_hash##num() {                         \
    modify_field_with_hash_based_offset(                         \
        hash_meta.hash##num, 0, proto##_hash##num, 0x100000000); \
  }                                                              \
                                                                 \
  table calc_##proto##_hash##num {                               \
    actions        { do_calc_##proto##_hash##num; }              \
    default_action : do_calc_##proto##_hash##num();              \
    size           : 1;                                          \
  }

CALC_HASH_32(1, ipv4, crc_32)
CALC_HASH_32(2, ipv4, crc_32_bzip2)
CALC_HASH_32(3, ipv4, crc_32_mpeg)
CALC_HASH_32(1, ipv6, crc_32)
CALC_HASH_32(2, ipv6, crc_32_bzip2)
CALC_HASH_32(3, ipv6, crc_32_mpeg)

/*
 * These control flow functions will be called from the ingress control
 * to calculate the hash for the given packet type
 */
control calc_ipv4_hash {
    apply(calc_ipv4_hash1);
    apply(calc_ipv4_hash2);
    apply(calc_ipv4_hash3);
}

control calc_ipv6_hash {
    apply(calc_ipv6_hash1);
    apply(calc_ipv6_hash2);
    apply(calc_ipv6_hash3);
}

/*
 * This control flow function will calculate the hash for ANY packet type
 * In this case it is empty, since we do not need it.
 */
control calc_common_hash {
}

/* 
 * Final Hash Calculation. The field list is provided by one of the included
 * hash calculation modules
 */

/*
 * We have 96 bits of hash so we can easily implement any selection algorithm
 * simply concatenating these fields. We can also optimize the program by not
 * using hash2 or hash 3 if we do not need them.
 */

field_list lag_ecmp_hash_list {
    hash_meta.hash1;
    
#if HASH_WIDTH > 32
    hash_meta.hash2;
#endif
    
#if HASH_WIDTH > 64
    hash_meta.hash3;
#endif
}

field_list_calculation lag_ecmp_hash {
    input { lag_ecmp_hash_list; }
    algorithm { identity; crc_64_extend; }
    output_width: HASH_WIDTH;
}

/*
 * Here we define the main output of this module and that's lag_ecmp_selector
 */
action_selector lag_ecmp_selector {
    selection_key:  lag_ecmp_hash;
    selection_mode: SELECTION_MODE;
}



