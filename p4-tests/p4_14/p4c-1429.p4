#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/stateful_alu_blackbox.p4>

//#include <ethernet.p4>
/*
 * https://www.iana.org/assignments/ieee-802-numbers/\
 *                ieee-802-numbers.xhtml#ieee-802-numbers-1
 */

#define ETHERTYPE_IPV4                  0x0800
#define ETHERTYPE_ARP                   0x0806
#define ETHERTYPE_CTAG                  0x8100
#define ETHERTYPE_IPV6                  0x86DD
#define ETHERTYPE_MPLS                  0x8847
#define ETHERTYPE_MPLS_UPSTREAM         0x8848
#define ETHERTYPE_STAG                  0x88A8
#define ETHERTYPE_LLDP                  0x88CC

header_type ethernet_h {
        fields {
                daddr: 48;
                saddr: 48;
                ethertype: 16;
        }
}

//#include <ipv4.p4>
/*
 * RFC791
 */

header_type ipv4_h {
        fields {
                version: 4;
                ihl: 4;
                ds: 8;
                tot_len: 16;
                id: 16;
                flags: 3;
                frag_offset: 13;
                ttl: 8;
                protocol: 8;
                checksum: 16;
                saddr: 32;
                daddr: 32;
        }
}

//#define HASH_SIZE 131072
//#define HASH_BITS 17
#define HASH_SIZE 32768
#define HASH_BITS 15

#define NR_HASH_TABLES 2

header ethernet_h ethernet;
header ipv4_h ipv4;

header_type metadata_h {
    fields {
        nr_hash_tables: 2;
        hash1: HASH_BITS;
        hash2: HASH_BITS;
        collision: 1;
        counts: 32;
        saddr: 32;
        kicked_out_saddr: 32;
        kicked_out_counts: 32;
    }
}

metadata metadata_h meta;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.ethertype) {
        ETHERTYPE_IPV4: parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

field_list hash_fields {
    ipv4.saddr;
}

field_list_calculation hash1 {
    input {
        hash_fields;
    }
    algorithm: crc_32q;
    output_width: HASH_BITS;
}

field_list_calculation hash2 {
    input {
        hash_fields;
    }
    algorithm: posix;
    output_width: HASH_BITS;
}

/******************************************/
/* saddr: the occurences of each address  */
/* This hash table is indexed with hash1. */
/******************************************/
register saddr_hash_table1 {
    width: 32;
    instance_count: HASH_SIZE;
}

/*
 * HI slice: update meta.collision (1: collision; 0: no collision)
 * LO slice: store IPv4 address in register (hash slot)
 *
 * condition_lo: check if hash slot is empty
 * condition_hi: does IPv4 address match with address in hash table slot?
 *
 * if (!condition_lo and !condition_hi) then "there is a collision"
 * if (condition_lo or condition_hi) then "there is no collision"
 */
blackbox stateful_alu update_saddr_table1_alu {
    reg: saddr_hash_table1;

    condition_hi: register_lo == 0;

    update_hi_1_predicate: condition_hi;
    update_hi_1_value: meta.saddr;

    update_hi_2_predicate: not condition_hi;
    update_hi_2_value: register_lo;

    output_predicate: 1;
    output_value: alu_hi;
    output_dst: meta.kicked_out_saddr;

    update_lo_1_value: meta.saddr;
}

action update_saddr_table1() {
    update_saddr_table1_alu.execute_stateful_alu_from_hash(hash1);
#ifdef CASE_FIX
    bit_xor(meta.collision, meta.kicked_out_saddr, meta.saddr);
#endif
    /*
    */
}

table update_saddr_table1 {
    actions {
        update_saddr_table1;
    }
    default_action: update_saddr_table1;
    size: 1;
}

/******************************************/
/* counts: the occurences of each address */
/* This hash table is indexed with hash1. */
/******************************************/
register counts_hash_table1 {
    width: 32;
    instance_count: HASH_SIZE;
}

blackbox stateful_alu update_counts_table1_alu {
    reg: counts_hash_table1;

    condition_lo: meta.collision;

    update_lo_1_predicate: not condition_lo;
    update_lo_1_value: register_lo + 1;

    update_lo_2_predicate: condition_lo;
    update_lo_2_value: 1;
    
    output_predicate: 1;
    output_value: register_lo;
    output_dst: meta.kicked_out_counts;
}

action update_counts_table1() {
    update_counts_table1_alu.execute_stateful_alu_from_hash(hash1);
    modify_field(meta.collision, 0);
}

table update_counts_table1 {
    actions {
        update_counts_table1;
    }
    default_action: update_counts_table1;
    size: 1;
}

blackbox stateful_alu reset_counts_table1_alu {
    reg: counts_hash_table1;
    update_lo_1_value: 1;
    output_value: register_lo;
    output_dst: meta.kicked_out_counts;
}
action reset_counts_table1() {
    reset_counts_table1_alu.execute_stateful_alu_from_hash(hash1);
}

table reset_counts_table1 {
    actions {
        reset_counts_table1;
    }
    default_action: reset_counts_table1;
    size: 1;
}

/******************************************/
/* saddr: the occurences of each address  */
/* This hash table is indexed with hash2. */
/******************************************/
register saddr_hash_table2 {
    width: 32;
    instance_count: HASH_SIZE;
}

/*
 * HI slice: update meta.collision (1: collision; 0: no collision)
 * LO slice: store IPv4 address in register (hash slot)
 *
 * condition_lo: check if hash slot is empty
 * condition_hi: does IPv4 address match with address in hash table slot?
 *
 * if (!condition_lo and !condition_hi) then "there is a collision"
 * if (condition_lo or condition_hi) then "there is no collision"
 */
blackbox stateful_alu update_saddr_table2_alu {
    reg: saddr_hash_table2;

    output_value: register_lo;
    output_dst: meta.kicked_out_saddr;

    update_lo_1_value: meta.saddr;
}

action update_saddr_table2() {
    update_saddr_table2_alu.execute_stateful_alu_from_hash(hash2);
    modify_field(meta.collision, 1);
}

table update_saddr_table2 {
    actions {
        update_saddr_table2;
    }
    default_action: update_saddr_table2;
    size: 1;
}

/******************************************/
/* counts: the occurences of each address */
/* This hash table is indexed with hash2. */
/******************************************/
register counts_hash_table2 {
    width: 32;
    instance_count: HASH_SIZE;
}

blackbox stateful_alu increment_counts_table2_alu {
    reg: counts_hash_table2;
    update_lo_1_value: register_lo + 1;
}

action increment_counts_table2() {
    increment_counts_table2_alu.execute_stateful_alu_from_hash(hash2);
    modify_field(meta.collision, 0);
}

table increment_counts_table2 {
    actions {
        increment_counts_table2;
    }
    default_action: increment_counts_table2;
    size: 1;
}

/****************************/
/* Store kicked out values. */
/****************************/
action update_meta() {
    modify_field(meta.saddr, meta.kicked_out_saddr);
    modify_field(meta.counts, meta.kicked_out_counts);
    modify_field_with_hash_based_offset(meta.hash1, 0, hash1, HASH_SIZE);
    modify_field_with_hash_based_offset(meta.hash2, 0, hash2, HASH_SIZE);
}

table update_meta {
    actions {
        update_meta;
    }
    default_action: update_meta;
    size: 1;
}

/******************************************************/
/* collisions: total number of cuckoo hash collisions */
/******************************************************/
register collisions {
    width: 16;
    instance_count: 1;
}

blackbox stateful_alu increment_collisions_alu {
    reg: collisions;
    update_lo_1_value: register_lo + 1;
}

action increment_collisions() {
    increment_collisions_alu.execute_stateful_alu(0);
    modify_field(meta.collision, 0);
}

table increment_collisions {
    actions {
        increment_collisions;
    }
    default_action: increment_collisions;
    size: 1;
}

/******************/
/* forward packet */
/******************/
action set_egress_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
    modify_field(meta.saddr, ipv4.saddr);
    modify_field(meta.nr_hash_tables, NR_HASH_TABLES);
}

table forward_packet {
    reads {
        ethernet.daddr: exact;
    }
    actions  {
        set_egress_port;
    }
}

control try_table3 {
}

control try_table2 {
    /*
     * There was a collision in table 1.
     * Store it in table 2.
     *
     * save table1 counts in metadata
     * and
     * reset counts in table1 to 1
     */
    /*
    apply(reset_counts_table1);
    */
    apply(update_meta);
    apply(update_saddr_table2);
    if (meta.kicked_out_saddr == 0) {
        apply(increment_counts_table2);
    } else if (meta.kicked_out_saddr != meta.saddr) {
        if (meta.nr_hash_tables >= 3) {
            try_table3();
        }
    } else {
        apply(increment_counts_table2);
    }
}

control store_ipv4_saddr {
    /*
     * store ipv4.saddr in hash table 1
     * and
     * save kicked out ipv4.saddr in metadata
     */
    apply(update_saddr_table1);
    apply(update_counts_table1);
    /*
    if (meta.kicked_out_saddr == 0) {
        apply(update_counts_table1);
    } else if (meta.kicked_out_saddr != meta.saddr) {
        if (meta.nr_hash_tables >= 2) {
            try_table2();
        }
    } else {
    }
    */
}

control ingress {
    apply(forward_packet) {
        hit {
            store_ipv4_saddr();
            /*
             * collision is
             * set by: update_saddr_tableX
             * cleared by: increment_counts_tableX
             */
            if (meta.collision == 1) {
                apply(increment_collisions);
            }
        }
    }
}
