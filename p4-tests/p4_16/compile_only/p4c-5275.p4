# 1 "../../bundle_translator_v3/bundle_translator_v3.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "../../bundle_translator_v3/bundle_translator_v3.p4"
//p4_16

// Bundle Protocol Translator
// Translates incoming bundles from BPv6 to BPv7 and vice versa (with limitations)

// Ingress Parser extracts data from bundles into P4 data types
// Ingress Match-action/control logic converts into translated data types (and sets up forwarding logic)
// Ingress Deparser sends out the new version onto the wire
// Egress doesn't do anything special, but can be used in future if needed

#include <core.p4>
#include <tna.p4>

# 1 "../../bundle_translator_v3/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




# 1 "../../bundle_translator_v3/bundle_headers.p4" 1
// Contains all Bundle Protocol specific headers
// Included in headers.p4 file

/*   BPv6 Headers   */

// Primary Block (CBHE Version)
header bpv6_version {
    bit<8> version;
}

// **** Variation of Bundle Flags ***//
header bpv6_bundle_flags_8 {
    bit<8> bundle_flags;
}
header bpv6_bundle_flags_16 {
    bit<16> bundle_flags;
}
header bpv6_bundle_flags_24 {
    bit<24> bundle_flags;
}
header bpv6_bundle_flags_32 {
    bit<32> bundle_flags;
}
header bpv6_bundle_flags_40 {
    bit<40> bundle_flags;
}
header bpv6_bundle_flags_48 {
    bit<48> bundle_flags;
}
header bpv6_bundle_flags_56 {
    bit<56> bundle_flags;
}
header bpv6_bundle_flags_64 {
    bit<64> bundle_flags;
}

//*** Variation of Block Length ***//
header bpv6_block_length_8 {
    bit<8> block_length;
}
header bpv6_block_length_16 {
    bit<16> block_length;
}
header bpv6_block_length_24 {
    bit<24> block_length;
}
header bpv6_block_length_32 {
    bit<32> block_length;
}
header bpv6_block_length_40 {
    bit<40> block_length;
}
header bpv6_block_length_48 {
    bit<48> block_length;
}
header bpv6_block_length_56 {
    bit<56> block_length;
}
header bpv6_block_length_64 {
    bit<64> block_length;
}

//*** Variation of DST NODE NUM ***//
header bpv6_dst_node_num_8 {
    bit<8> dst_node_num;
}
header bpv6_dst_node_num_16 {
    bit<16> dst_node_num;
}
header bpv6_dst_node_num_24 {
    bit<24> dst_node_num;
}
header bpv6_dst_node_num_32 {
    bit<32> dst_node_num;
}
header bpv6_dst_node_num_40 {
    bit<40> dst_node_num;
}
header bpv6_dst_node_num_48 {
    bit<48> dst_node_num;
}
header bpv6_dst_node_num_56 {
    bit<56> dst_node_num;
}
header bpv6_dst_node_num_64 {
    bit<64> dst_node_num;
}

// //*** Variation of DST SERV NUM ***//

header bpv6_dst_serv_num_8{
    bit<8> dst_serv_num;
}
header bpv6_dst_serv_num_16{
    bit<16> dst_serv_num;
}
header bpv6_dst_serv_num_24{
    bit<24> dst_serv_num;
}
header bpv6_dst_serv_num_32{
    bit<32> dst_serv_num;
}
header bpv6_dst_serv_num_40{
    bit<40> dst_serv_num;
}
header bpv6_dst_serv_num_48{
    bit<48> dst_serv_num;
}
header bpv6_dst_serv_num_56{
    bit<56> dst_serv_num;
}
header bpv6_dst_serv_num_64{
    bit<64> dst_serv_num;
}

//*** Variation of SRC NODE NUM ***//
header bpv6_src_node_num_8{
    bit<8> src_node_num;
}
header bpv6_src_node_num_16{
    bit<16> src_node_num;
}
header bpv6_src_node_num_24{
    bit<24> src_node_num;
}
header bpv6_src_node_num_32{
    bit<32> src_node_num;
}
header bpv6_src_node_num_40{
    bit<40> src_node_num;
}
header bpv6_src_node_num_48{
    bit<48> src_node_num;
}
header bpv6_src_node_num_56{
    bit<56> src_node_num;
}
header bpv6_src_node_num_64{
    bit<64> src_node_num;
}

//*** Variation of SRC SERV NUM ***//
header bpv6_src_serv_num_8{
    bit<8> src_serv_num;
}
header bpv6_src_serv_num_16{
    bit<16> src_serv_num;
}
header bpv6_src_serv_num_24{
    bit<24> src_serv_num;
}
header bpv6_src_serv_num_32{
    bit<32> src_serv_num;
}
header bpv6_src_serv_num_40{
    bit<40> src_serv_num;
}
header bpv6_src_serv_num_48{
    bit<48> src_serv_num;
}
header bpv6_src_serv_num_56{
    bit<56> src_serv_num;
}
header bpv6_src_serv_num_64{
    bit<64> src_serv_num;
}

//*** Variation of REP NODE NUM ***//
header bpv6_rep_node_num_8{
    bit<8> rep_node_num;
}
header bpv6_rep_node_num_16{
    bit<16> rep_node_num;
}
header bpv6_rep_node_num_24{
    bit<24> rep_node_num;
}
header bpv6_rep_node_num_32{
    bit<32> rep_node_num;
}
header bpv6_rep_node_num_40{
    bit<40> rep_node_num;
}
header bpv6_rep_node_num_48{
    bit<48> rep_node_num;
}
header bpv6_rep_node_num_56{
    bit<56> rep_node_num;
}
header bpv6_rep_node_num_64{
    bit<64> rep_node_num;
}

//*** Variation of REP SERV NUM ***//
header bpv6_rep_serv_num_8{
    bit<8> rep_serv_num;
}
header bpv6_rep_serv_num_16{
    bit<16> rep_serv_num;
}
header bpv6_rep_serv_num_24{
    bit<24> rep_serv_num;
}
header bpv6_rep_serv_num_32{
    bit<32> rep_serv_num;
}
header bpv6_rep_serv_num_40{
    bit<40> rep_serv_num;
}
header bpv6_rep_serv_num_48{
    bit<48> rep_serv_num;
}
header bpv6_rep_serv_num_56{
    bit<56> rep_serv_num;
}
header bpv6_rep_serv_num_64{
    bit<64> rep_serv_num;
}

//*** Variation of CUST NODE NUM ***//
header bpv6_cust_node_num_8{
    bit<8> cust_node_num;
}
header bpv6_cust_node_num_16{
    bit<16> cust_node_num;
}
header bpv6_cust_node_num_24{
    bit<24> cust_node_num;
}
header bpv6_cust_node_num_32{
    bit<32> cust_node_num;
}
header bpv6_cust_node_num_40{
    bit<40> cust_node_num;
}
header bpv6_cust_node_num_48{
    bit<48> cust_node_num;
}
header bpv6_cust_node_num_56{
    bit<56> cust_node_num;
}
header bpv6_cust_node_num_64{
    bit<64> cust_node_num;
}

//*** Variation of CUST SERV NUM ***//
header bpv6_cust_serv_num_8{
    bit<8> cust_serv_num;
}
header bpv6_cust_serv_num_16{
    bit<16> cust_serv_num;
}
header bpv6_cust_serv_num_24{
    bit<24> cust_serv_num;
}
header bpv6_cust_serv_num_32{
    bit<32> cust_serv_num;
}
header bpv6_cust_serv_num_40{
    bit<40> cust_serv_num;
}
header bpv6_cust_serv_num_48{
    bit<48> cust_serv_num;
}
header bpv6_cust_serv_num_56{
    bit<56> cust_serv_num;
}
header bpv6_cust_serv_num_64{
    bit<64> cust_serv_num;
}

//*** Variation of CREATION TIME STAMP ***//
header bpv6_creation_ts_40{
    bit<40> creation_ts;
}
header bpv6_creation_ts_48{
    bit<48> creation_ts;
}
header bpv6_creation_ts_56{
    bit<56> creation_ts;
}
header bpv6_creation_ts_64{
    bit<64> creation_ts;
}

//*** Variation of CREATION TIME STAMP SEQ NUM ***//
header bpv6_creation_ts_seq_num_8{
    bit<8> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_16{
    bit<16> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_24{
    bit<24> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_32{
    bit<32> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_40{
    bit<40> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_48{
    bit<48> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_56{
    bit<56> creation_ts_seq_num;
}
header bpv6_creation_ts_seq_num_64{
    bit<64> creation_ts_seq_num;
}

//*** Variation of LIFETIME ***//
header bpv6_lifetime_8{
    bit<8> lifetime;
}
header bpv6_lifetime_16{
    bit<16> lifetime;
}
header bpv6_lifetime_24{
    bit<24> lifetime;
}
header bpv6_lifetime_32{
    bit<32> lifetime;
}
header bpv6_lifetime_40{
    bit<40> lifetime;
}
header bpv6_lifetime_48{
    bit<48> lifetime;
}
header bpv6_lifetime_56{
    bit<56> lifetime;
}
header bpv6_lifetime_64{
    bit<64> lifetime;
}

//*** Variation of DICTIONARY LENGTH ***//
header bpv6_dict_len_8{
    bit<8> dict_len;
}
header bpv6_dict_len_16{
    bit<16> dict_len;
}
header bpv6_dict_len_24{
    bit<24> dict_len;
}
header bpv6_dict_len_32{
    bit<32> dict_len;
}
header bpv6_dict_len_40{
    bit<40> dict_len;
}
header bpv6_dict_len_48{
    bit<48> dict_len;
}
header bpv6_dict_len_56{
    bit<56> dict_len;
}
header bpv6_dict_len_64{
    bit<64> dict_len;
}



header bpv6_rest_of_primary {
    // bit<8> dst_node_num; // This field should be named differently for a non-CBHE version (e.g. dst_sch_offset)
    // bit<8> dst_serv_num; // This field should be named differently for a non-CBHE version (e.g. dst_ssp_offset)
    // bit<8> src_node_num;
    // bit<8> src_serv_num;
    // bit<8> rep_node_num;
    // bit<8> rep_serv_num;
    // bit<8> cust_node_num;
    bit<8> cust_serv_num;
    bit<40> creation_ts;
    bit<8> creation_ts_seq_num; // Timestamp seq num can cause issues if it gets too big. (ION always increments seq num, only resets if you restart ION)
    bit<24> lifetime;
    bit<8> dict_len; // should be 0 for Compressed Bundle Header Encoding (CBHE) RFC 6260
}



//****************************************************************************************
// Previous Hop Insertion Block (RFC 6259)
// A note on RFC 6259 terminology: "Inserting Node" is the Previous Hop Node ('previous hop' from perspective of the receiving node) 
header bpv6_extension_phib_h {
    bit<8> block_type_code;
    bit<8> block_flags;
    bit<8> block_data_len;
    // Inserting Node's EID Scheme Name - 
    //      A null-terminated array of bytes that comprises the scheme name of an M-EID of the node inserting this PHIB.
    //      Example: ["i", "p", "n", "\0"] aka [0x69, 0x70, 0x6e, 0x00]
    bit<32> prev_hop_scheme_name;
    // Inserting Node's EID SSP - 
    //      A null-terminated array of bytes that comprises the scheme-specific part (SSP) of an M-EID of the node inserting this PHIB.
    //      Example: ["2", ".", "0", "\0"] aka [0x32, 0x2e, 0x30, 0x00]
    bit<32> prev_hop;
}

// Bundle Age Extension Block (https://datatracker.ietf.org/doc/html/draft-irtf-dtnrg-bundle-age-block-01)
header bpv6_extension_age_h {
    bit<8> block_type_code; // should be 20 (0x14) in ION implementation
    bit<8> block_flags;
    bit<8> block_data_len;
    bit<8> bundle_age;
}

// Payload Block
header bpv6_payload_h {
    bit<8> block_type_code; // should be 1
    bit<8> block_flags;
    bit<8> payload_length;
}

/*   BPv7 Headers   */

const bit<8> CBOR_INDEF_LEN_ARRAY_START_CODE = 8w0x9f;
const bit<8> CBOR_INDEF_LEN_ARRAY_STOP_CODE = 8w0xff;

const bit<8> CBOR_MASK_MT = 8w0b11100000; // CBOR Major Type Mask
const bit<8> CBOR_MASK_AI = 8w0b00011111; // CBOR Additional Info Mask

// Start of Bundle Code (0x9f)
header bpv7_start_code_h {
    bit<8> start_code;
}

// Primary Block (Part 1)
header bpv7_primary_1_h {
    bit<8> prim_initial_byte;
    bit<8> version_num;
    bit<16> bundle_flags;
    bit<8> crc_type;
    bit<40> dest_eid;
    bit<40> src_eid;
    bit<40> report_eid;
    bit<8> creation_timestamp_time_initial_byte;
    bit<72> creation_timestamp_time;
    // The ION implementation currently ALWAYS increments the creation timestamp sequence number. (This number is only reset when ION is reset on a node)
    // This means that the seq. number can become very large, causing problems if the P4 program isn't designed to handle the various CBOR cases correctly.
    // This is an example of the code required to properly parse a CBOR unsigned integer field (although not fully tested). See BPv7 parser to see how these headers are handled in parser.
    bit<8> creation_timestamp_seq_num_initial_byte;
}

// Primary Block (Part 2, may or may not be needed)
// Case: Timestamp Seq. Number requires 1 additional byte to create the CBOR argument
header bpv7_primary_2_1_h {
    bit<8> creation_timestamp_seq_num;
}

// Case: Timestamp Seq. Number requires 2 additional bytes to create the CBOR argument
header bpv7_primary_2_2_h {
    bit<16> creation_timestamp_seq_num;
}

// Case: Timestamp Seq. Number requires 4 additional bytes to create the CBOR argument
header bpv7_primary_2_4_h {
    bit<32> creation_timestamp_seq_num;
}

// Case: Timestamp Seq. Number requires 8 additional bytes to create the CBOR argument
header bpv7_primary_2_8_h {
    bit<64> creation_timestamp_seq_num;
}

// Primary Block (Part 3, always used)
// These are the fields that come after the creation timestamp
header bpv7_primary_3_h {
    bit<40> lifetime;
    bit<24> crc_field_integer;
}

// Previous Node Extension Block
header bpv7_extension_prev_node_h {
    bit<8> initial_byte;
    bit<8> block_type;
    bit<8> block_num;
    bit<8> block_flags;
    bit<8> crc_type;
    bit<8> block_data_initial_byte;
    bit<8> prev_node_array_initial_byte;
    bit<8> uri_scheme;
    bit<8> prev_node_eid_initial_byte;
    bit<8> node_num;
    bit<8> serv_num;
}

// Extended Class of Service Extension Block (https://datatracker.ietf.org/doc/draft-burleigh-dtn-ecos/00/)
// This is assuming that block type 193 is ION's type code for an extended class of service block.
// After peeking at ION's source code (.../bpv7/test/bpchat), 80% sure that this is an extended class of service block.
// However, the format of the pcap doesn't match up with the internet draft... 
header bpv7_extension_ecos_h {
    bit<8> initial_byte;
    bit<16> block_type;
    bit<8> block_num;
    bit<8> block_flags;
    bit<8> crc_type;
    bit<8> block_data_initial_byte;
    bit<8> ecos_array_start;
    bit<32> ecos_data;
}

// Bundle Age Extension Block
header bpv7_extension_age_h {
    bit<8> initial_byte;
    bit<8> block_type;
    bit<8> block_num;
    bit<8> block_flags;
    bit<8> crc_type;
    bit<8> block_data_initial_byte;
    bit<8> bundle_age;
}

// Payload Block
header bpv7_payload_h {
    bit<8> initial_byte;
 bit<8> block_type;
 bit<8> block_num;
 bit<8> block_flags;
 bit<8> crc_type;
    bit<8> adu_initial_byte; // This makes the strong assumption that ADU length is less than 24. If ADU len >= 24, then there's additional bytes (to determine the ADU length) before reaching the actual ADU/payload
}

// End of Bundle
header bpv7_stop_code_h {
 bit<8> stop_code;
}

/*   Payload (Application Data Unit) Headers (Used for both BPv6 and BPv7)   */
header adu_1_h {
 bit<8> adu;
}

header adu_2_h {
 bit<16> adu;
}

header adu_3_h {
 bit<24> adu;
}

header adu_4_h {
 bit<32> adu;
}

header adu_5_h {
 bit<40> adu;
}

header adu_6_h {
 bit<48> adu;
}

header adu_7_h {
 bit<56> adu;
}

header adu_8_h {
 bit<64> adu;
}

header adu_9_h {
 bit<72> adu;
}

header adu_10_h {
 bit<80> adu;
}

header adu_11_h {
 bit<88> adu;
}

header adu_12_h {
 bit<96> adu;
}

header adu_13_h {
 bit<104> adu;
}
# 25 "../../bundle_translator_v3/headers.p4" 2

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;

const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const bit<3> DIGEST_TYPE_DEBUG = 0x1;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}


struct looksie_t_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct looksie_t_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct looksie_t_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

struct block_length_t_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct block_length_t_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct block_length_t_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

struct dst_node_num_t_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct dst_node_num_t_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct dst_node_num_t_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

struct dst_serv_num_t_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct dst_serv_num_t_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct dst_serv_num_t_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

struct src_node_num_t_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct src_node_num_t_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct src_node_num_t_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for bundle length parsing
struct lifetime_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct lifetime_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct lifetime_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for cust serv num parsing
struct cust_serv_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct cust_serv_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct cust_serv_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for cust node num parsing
struct cust_node_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct cust_node_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct cust_node_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for rep serv num parsing
struct rep_serv_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct rep_serv_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct rep_serv_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for rep serv num parsing
struct rep_node_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct rep_node_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct rep_node_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

//struct for creation ts parsing
struct creationts_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
    bit<1> init_4;
    bit<7> body_4;
//part2
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
    bit<1> init_7;
    bit<7> body_7;
}


//struct for src serv num parsing
struct src_serv_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct src_serv_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct src_serv_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

struct creation_timestamp_seq_num_part1 {
    bit<1> init_1;
    bit<7> body_1;
    bit<1> init_2;
    bit<7> body_2;
    bit<1> init_3;
    bit<7> body_3;
}

struct creation_timestamp_seq_num_part2 {
    bit<1> init_4;
    bit<7> body_4;
    bit<1> init_5;
    bit<7> body_5;
    bit<1> init_6;
    bit<7> body_6;
}

struct creation_timestamp_seq_num_part3 {
    bit<1> init_7;
    bit<7> body_7;
}

// Note: Order of declaration of matters for this struct!
// - Headers are deparsed/emitted in order of declaration
// - Invalid headers are not emitted
struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;

 // V6 Headers
    // bpv6_primary_cbhe_h bpv6_primary_cbhe;

    //ALL VARIATIONS OF PRIMARY HEADER FIELD POSSIBLE SIZES//
    bpv6_version version;

    bpv6_bundle_flags_8 bundleFlags8;
    bpv6_bundle_flags_16 bundleFlags16;
    bpv6_bundle_flags_24 bundleFlags24;
    bpv6_bundle_flags_32 bundleFlags32;
    bpv6_bundle_flags_40 bundleFlags40;
    bpv6_bundle_flags_48 bundleFlags48;
    bpv6_bundle_flags_56 bundleFlags56;
    bpv6_bundle_flags_64 bundleFlags64;

    bpv6_block_length_8 blockLength8;
    bpv6_block_length_16 blockLength16;
    bpv6_block_length_24 blockLength24;
    bpv6_block_length_32 blockLength32;
    bpv6_block_length_40 blockLength40;
    bpv6_block_length_48 blockLength48;
    bpv6_block_length_56 blockLength56;
    bpv6_block_length_64 blockLength64;

    bpv6_dst_node_num_8 dstNodeNum8;
    bpv6_dst_node_num_16 dstNodeNum16;
    bpv6_dst_node_num_24 dstNodeNum24;
    bpv6_dst_node_num_32 dstNodeNum32;
    bpv6_dst_node_num_40 dstNodeNum40;
    bpv6_dst_node_num_48 dstNodeNum48;
    bpv6_dst_node_num_56 dstNodeNum56;
    bpv6_dst_node_num_64 dstNodeNum64;

    bpv6_dst_serv_num_8 dstServNum8;
    bpv6_dst_serv_num_16 dstServNum16;
    bpv6_dst_serv_num_24 dstServNum24;
    bpv6_dst_serv_num_32 dstServNum32;
    bpv6_dst_serv_num_40 dstServNum40;
    bpv6_dst_serv_num_48 dstServNum48;
    bpv6_dst_serv_num_56 dstServNum56;
    bpv6_dst_serv_num_64 dstServNum64;

    bpv6_src_node_num_8 srcNodeNum8;
    bpv6_src_node_num_16 srcNodeNum16;
    bpv6_src_node_num_24 srcNodeNum24;
    bpv6_src_node_num_32 srcNodeNum32;
    bpv6_src_node_num_40 srcNodeNum40;
    bpv6_src_node_num_48 srcNodeNum48;
    bpv6_src_node_num_56 srcNodeNum56;
    bpv6_src_node_num_64 srcNodeNum64;

    bpv6_src_serv_num_8 srcServNum8;
    bpv6_src_serv_num_16 srcServNum16;
    bpv6_src_serv_num_24 srcServNum24;
    bpv6_src_serv_num_32 srcServNum32;
    bpv6_src_serv_num_40 srcServNum40;
    bpv6_src_serv_num_48 srcServNum48;
    bpv6_src_serv_num_56 srcServNum56;
    bpv6_src_serv_num_64 srcServNum64;

    bpv6_rep_node_num_8 repNodeNum8;
    bpv6_rep_node_num_16 repNodeNum16;
    bpv6_rep_node_num_24 repNodeNum24;
    bpv6_rep_node_num_32 repNodeNum32;
    bpv6_rep_node_num_40 repNodeNum40;
    bpv6_rep_node_num_48 repNodeNum48;
    bpv6_rep_node_num_56 repNodeNum56;
    bpv6_rep_node_num_64 repNodeNum64;

    bpv6_rep_serv_num_8 repServNum8;
    bpv6_rep_serv_num_16 repServNum16;
    bpv6_rep_serv_num_24 repServNum24;
    bpv6_rep_serv_num_32 repServNum32;
    bpv6_rep_serv_num_40 repServNum40;
    bpv6_rep_serv_num_48 repServNum48;
    bpv6_rep_serv_num_56 repServNum56;
    bpv6_rep_serv_num_64 repServNum64;

    bpv6_cust_node_num_8 custNodeNum8;
    bpv6_cust_node_num_16 custNodeNum16;
    bpv6_cust_node_num_24 custNodeNum24;
    bpv6_cust_node_num_32 custNodeNum32;
    bpv6_cust_node_num_40 custNodeNum40;
    bpv6_cust_node_num_48 custNodeNum48;
    bpv6_cust_node_num_56 custNodeNum56;
    bpv6_cust_node_num_64 custNodeNum64;

    bpv6_cust_serv_num_8 custServNum8;
    bpv6_cust_serv_num_16 custServNum16;
    bpv6_cust_serv_num_24 custServNum24;
    bpv6_cust_serv_num_32 custServNum32;
    bpv6_cust_serv_num_40 custServNum40;
    bpv6_cust_serv_num_48 custServNum48;
    bpv6_cust_serv_num_56 custServNum56;
    bpv6_cust_serv_num_64 custServNum64;

    bpv6_creation_ts_40 creationTs40;
    bpv6_creation_ts_48 creationTs48;
    bpv6_creation_ts_56 creationTs56;
    bpv6_creation_ts_64 creationTs64;

    bpv6_creation_ts_seq_num_8 creationTsSeqNum8;
    bpv6_creation_ts_seq_num_16 creationTsSeqNum16;
    bpv6_creation_ts_seq_num_24 creationTsSeqNum24;
    bpv6_creation_ts_seq_num_32 creationTsSeqNum32;
    bpv6_creation_ts_seq_num_40 creationTsSeqNum40;
    bpv6_creation_ts_seq_num_48 creationTsSeqNum48;
    bpv6_creation_ts_seq_num_56 creationTsSeqNum56;
    bpv6_creation_ts_seq_num_64 creationTsSeqNum64;

    bpv6_lifetime_8 lifetime8;
    bpv6_lifetime_16 lifetime16;
    bpv6_lifetime_24 lifetime24;
    bpv6_lifetime_32 lifetime32;
    bpv6_lifetime_40 lifetime40;
    bpv6_lifetime_48 lifetime48;
    bpv6_lifetime_56 lifetime56;
    bpv6_lifetime_64 lifetime64;

    bpv6_dict_len_8 dictLength8;
    bpv6_dict_len_16 dictLength16;
    bpv6_dict_len_24 dictLength24;
    bpv6_dict_len_32 dictLength32;
    bpv6_dict_len_40 dictLength40;
    bpv6_dict_len_48 dictLength48;
    bpv6_dict_len_56 dictLength56;
    bpv6_dict_len_64 dictLength64;

    bpv6_rest_of_primary restOfPrimary;
    bpv6_extension_phib_h bpv6_extension_phib;
    bpv6_extension_age_h bpv6_extension_age;
    bpv6_payload_h bpv6_payload;

 // V7 Headers
 bpv7_start_code_h bpv7_start_code;
 bpv7_primary_1_h bpv7_primary_1;
 bpv7_primary_2_1_h bpv7_primary_2_1;
 bpv7_primary_2_2_h bpv7_primary_2_2;
 bpv7_primary_2_4_h bpv7_primary_2_4;
 bpv7_primary_2_8_h bpv7_primary_2_8;
 bpv7_primary_3_h bpv7_primary_3;
 bpv7_extension_prev_node_h bpv7_extension_prev_node;
 bpv7_extension_ecos_h bpv7_extension_ecos;
 bpv7_extension_age_h bpv7_extension_age;
 bpv7_payload_h bpv7_payload;

 // Application Data Unit (ADU) Headers for v6 and v7
 adu_1_h adu_1;
 adu_2_h adu_2;
 adu_3_h adu_3;
 adu_4_h adu_4;
 adu_5_h adu_5;
 adu_6_h adu_6;
 adu_7_h adu_7;
 adu_8_h adu_8;
 adu_9_h adu_9;
 adu_10_h adu_10;
 adu_11_h adu_11;
 adu_12_h adu_12;
 adu_13_h adu_13;



 // Stop Code for V7
 bpv7_stop_code_h bpv7_stop_code;
}

// Can freely change this, only used for capturing information we care about for debugging
// Maximum allowed data in a digest is 47 bytes
struct debug_digest_t {
 bit<8> hdr_version_num;

    bit<8> initial_byte;
    // bit<8> block_type;
    bit<24> block_num;
    bit<16> block_flags;
    // bit<8> crc_type;
    // bit<8> block_data_initial_byte;
    // bit<8> bundle_age;
}

struct metadata_headers_t {
    bool checksum_upd_ipv4; // True if IPv4 checksum should be updated 
    bool checksum_upd_udp; // True if UDP checksum should be updated
 bool checksum_err_ipv4_igprs; // True if IPv4 checksum was correct

 bool incomingV7; // True if a BPv7 bundle was ingested
 bool incomingV6; // True if a BPv6 bundle was ingested

 debug_digest_t debug_metadata; // Used to bridge debug info from ingress match-action stage to ingress deparser
}
# 15 "../../bundle_translator_v3/bundle_translator_v3.p4" 2

/***    INGRESS PROCESSING   ***/

/***    Ingress Parser   ***/
parser IngressParser(packet_in pkt,
       out headers_t hdr,
       out metadata_headers_t meta,
       out ingress_intrinsic_metadata_t ig_intr_md)
{
 Checksum() ipv4_checksum;
 // looksie_t_part1 l;


 // Required for TNA
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

 // Required for TNA
    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

 // Required for TNA
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

 state parse_ethernet {
  pkt.extract(hdr.ethernet);
  transition select(hdr.ethernet.ether_type) {
   ETHERTYPE_IPV4: parse_ipv4;
   // should support more ethertypes
   default: accept;
  }
 }

 state parse_ipv4 {
  pkt.extract(hdr.ipv4);
  ipv4_checksum.add(hdr.ipv4);
  meta.checksum_err_ipv4_igprs = ipv4_checksum.verify(); // Currently not doing anything with this

  transition select(hdr.ipv4.protocol) {
   8w0x11: parse_udp;
   // should support more transport protocols
   default: accept;
  }
 }

 state parse_udp {
  pkt.extract(hdr.udp);

  transition parse_version;
 }

 state parse_version {
  bit<8> start_byte = pkt.lookahead<bit<8>>();

  transition select(start_byte) {
   0x06: parse_v6;
   // 0x9f: parse_v7;
   default: accept;
  }
 }

# 1 "../../bundle_translator_v3/parse_v6.p4" 1
// Logic for parsing Bundle Protocol version 6 headers.
// Assumes that transport layer headers have been extracted and next byte is start of bundle (i.e. Bundle protocol version number 6, 0x06)
// #include "parse_v6_part2.p4"

state parse_v6 {
    meta.incomingV6 = true;
    // pkt.extract(hdr.bpv6_primary_cbhe);
    pkt.extract(hdr.version);
    transition parse_bundle_flags_8;
}


// // //**Trying Seth's shortening method**//

state parse_bundle_flags_8{
    looksie_t_part1 l = pkt.lookahead<looksie_t_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_looksie_part2;
//3 byte
        (1,1,0): parse_bundle_flags_24_part_2;
//2 byte
        (1,0,0) : parse_bundle_flags_16_part_2;
        (1,0,1) : parse_bundle_flags_16_part_2;
//1 byte
        (0,0,0) : parse_bundle_flags_8_part_2;
        (0,0,1) : parse_bundle_flags_8_part_2;
        (0,1,0) : parse_bundle_flags_8_part_2;
        (0,1,1) : parse_bundle_flags_8_part_2;
    }
}

state parse_looksie_part2{
    looksie_t_part2 l = pkt.lookahead<looksie_t_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_looksie_part3;
//6 bytes
        (1,1,0):parse_bundle_flags_48_part_2;
// 5 bytes
        (1,0,0) : parse_bundle_flags_40_part_2;
        (1,0,1) : parse_bundle_flags_40_part_2;
// 4 bytes
        (0,0,0) : parse_bundle_flags_32_part_2;
        (0,0,1) : parse_bundle_flags_32_part_2;
        (0,1,0) : parse_bundle_flags_32_part_2;
        (0,1,1) : parse_bundle_flags_32_part_2;
    }
}

state parse_looksie_part3{
    looksie_t_part3 l = pkt.lookahead<looksie_t_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_bundle_flags_64;
//7 bytes
        (0):parse_bundle_flags_56_part_2;
    }
}

state parse_bundle_flags_8_part_2{
    pkt.extract(hdr.bundleFlags8);
    transition parse_block_length_8;
}

state parse_bundle_flags_16_part_2{
    pkt.extract(hdr.bundleFlags16);
    transition parse_block_length_8;
}

state parse_bundle_flags_24_part_2{
    pkt.extract(hdr.bundleFlags24);
    transition parse_block_length_8;
}

state parse_bundle_flags_32_part_2{
    pkt.extract(hdr.bundleFlags32);
    transition parse_block_length_8;
}

state parse_bundle_flags_40_part_2{
    pkt.extract(hdr.bundleFlags40);
    transition parse_block_length_8;
}

state parse_bundle_flags_48_part_2{
    pkt.extract(hdr.bundleFlags48);
    transition parse_block_length_8;
}

state parse_bundle_flags_56_part_2{
    pkt.extract(hdr.bundleFlags56);
    transition parse_block_length_8;
}

state parse_bundle_flags_64{
    pkt.extract(hdr.bundleFlags64);
    transition parse_block_length_8;
}



//Block Length*******************************************//

state parse_block_length_8{
    block_length_t_part1 l = pkt.lookahead<block_length_t_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_block_length_part2;
//3 byte
        (1,1,0): parse_block_length_24_part_2;
//2 byte
        (1,0,0) : parse_block_length_16_part_2;
        (1,0,1) : parse_block_length_16_part_2;
//1 byte
        (0,0,0) : parse_block_length_8_part_2;
        (0,0,1) : parse_block_length_8_part_2;
        (0,1,0) : parse_block_length_8_part_2;
        (0,1,1) : parse_block_length_8_part_2;
    }
}

state parse_block_length_part2{
    block_length_t_part2 l = pkt.lookahead<block_length_t_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_block_length_part3;
//6 bytes
        (1,1,0):parse_block_length_48_part_2;
// 5 bytes
        (1,0,0) : parse_block_length_40_part_2;
        (1,0,1) : parse_block_length_40_part_2;
// 4 bytes
        (0,0,0) : parse_block_length_32_part_2;
        (0,0,1) : parse_block_length_32_part_2;
        (0,1,0) : parse_block_length_32_part_2;
        (0,1,1) : parse_block_length_32_part_2;
    }
}
state parse_block_length_part3{
    block_length_t_part3 l = pkt.lookahead<block_length_t_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_block_length_64;
//7 bytes
        (0):parse_block_length_56_part_2;
    }
}

state parse_block_length_8_part_2{
    pkt.extract(hdr.blockLength8);
    transition parse_dst_node_num_8;
}
state parse_block_length_16_part_2{
    pkt.extract(hdr.blockLength16);
    transition parse_dst_node_num_8;
}

state parse_block_length_24_part_2{
    pkt.extract(hdr.blockLength24);
    transition parse_dst_node_num_8;
}

state parse_block_length_32_part_2{
    pkt.extract(hdr.blockLength32);
    transition parse_dst_node_num_8;
}

state parse_block_length_40_part_2{
    pkt.extract(hdr.blockLength40);
    transition parse_dst_node_num_8;
}

state parse_block_length_48_part_2{
    pkt.extract(hdr.blockLength48);
    transition parse_dst_node_num_8;
}

state parse_block_length_56_part_2{
    pkt.extract(hdr.blockLength56);
    transition parse_dst_node_num_8;
}

state parse_block_length_64{
    pkt.extract(hdr.blockLength64);
    transition parse_dst_node_num_8;
}

// //**** Parsing varation of sizes for DST Node Num ****//

//Block Length*******************************************//

state parse_dst_node_num_8{
    dst_node_num_t_part1 d = pkt.lookahead<dst_node_num_t_part1>();

    transition select(d.init_1, d.init_2, d.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_dst_node_num_part2;
//3 byte
        (1,1,0): parse_dst_node_num_24_part_2;
//2 byte
        (1,0,0) : parse_dst_node_num_16_part_2;
        (1,0,1) : parse_dst_node_num_16_part_2;
//1 byte
        (0,0,0) : parse_dst_node_num_8_part_2;
        (0,0,1) : parse_dst_node_num_8_part_2;
        (0,1,0) : parse_dst_node_num_8_part_2;
        (0,1,1) : parse_dst_node_num_8_part_2;
    }
}

state parse_dst_node_num_part2{
    dst_node_num_t_part2 d = pkt.lookahead<dst_node_num_t_part2>();

    transition select(d.init_4,d.init_5, d.init_6) {
// > 6 bytes
        (1,1,1):parse_dst_node_num_part3;
//6 bytes
        (1,1,0):parse_dst_node_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_dst_node_num_40_part_2;
        (1,0,1) : parse_dst_node_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_dst_node_num_32_part_2;
        (0,0,1) : parse_dst_node_num_32_part_2;
        (0,1,0) : parse_dst_node_num_32_part_2;
        (0,1,1) : parse_dst_node_num_32_part_2;
    }
}
state parse_dst_node_num_part3{
    dst_node_num_t_part3 d = pkt.lookahead<dst_node_num_t_part3>();

    transition select(d.init_7) {
//8 bytes
        (1):parse_dst_node_num_64;
//7 bytes
        (0):parse_dst_node_num_56_part_2;
    }
}

state parse_dst_node_num_8_part_2{
    pkt.extract(hdr.dstNodeNum8);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_16_part_2{
    pkt.extract(hdr.dstNodeNum16);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_24_part_2{
    pkt.extract(hdr.dstNodeNum24);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_32_part_2{
    pkt.extract(hdr.dstNodeNum32);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_40_part_2{
    pkt.extract(hdr.dstNodeNum40);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_48_part_2{
    pkt.extract(hdr.dstNodeNum48);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_56_part_2{
    pkt.extract(hdr.dstNodeNum56);
    transition parse_dst_serv_num_8;
}

state parse_dst_node_num_64{
    pkt.extract(hdr.dstNodeNum64);
    transition parse_dst_serv_num_8;
}

state parse_dst_serv_num_8{
    dst_serv_num_t_part1 d = pkt.lookahead<dst_serv_num_t_part1>();

    transition select(d.init_1, d.init_2, d.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_dst_serv_num_part2;
//3 byte
        (1,1,0): parse_dst_serv_num_24_part_2;
//2 byte
        (1,0,0) : parse_dst_serv_num_16_part_2;
        (1,0,1) : parse_dst_serv_num_16_part_2;
//1 byte
        (0,0,0) : parse_dst_serv_num_8_part_2;
        (0,0,1) : parse_dst_serv_num_8_part_2;
        (0,1,0) : parse_dst_serv_num_8_part_2;
        (0,1,1) : parse_dst_serv_num_8_part_2;
    }
}

state parse_dst_serv_num_part2{
    dst_serv_num_t_part2 d = pkt.lookahead<dst_serv_num_t_part2>();

    transition select(d.init_4,d.init_5, d.init_6) {
// > 6 bytes
        (1,1,1):parse_dst_serv_num_part3;
//6 bytes
        (1,1,0):parse_dst_serv_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_dst_serv_num_40_part_2;
        (1,0,1) : parse_dst_serv_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_dst_serv_num_32_part_2;
        (0,0,1) : parse_dst_serv_num_32_part_2;
        (0,1,0) : parse_dst_serv_num_32_part_2;
        (0,1,1) : parse_dst_serv_num_32_part_2;
    }
}
state parse_dst_serv_num_part3{
    dst_serv_num_t_part3 d = pkt.lookahead<dst_serv_num_t_part3>();

    transition select(d.init_7) {
//8 bytes
        (1):parse_dst_serv_num_64;
//7 bytes
        (0):parse_dst_serv_num_56_part_2;
    }
}

state parse_dst_serv_num_8_part_2{
    pkt.extract(hdr.dstServNum8);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_16_part_2{
    pkt.extract(hdr.dstServNum16);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_24_part_2{
    pkt.extract(hdr.dstServNum24);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_32_part_2{
    pkt.extract(hdr.dstServNum32);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_40_part_2{
    pkt.extract(hdr.dstServNum40);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_48_part_2{
    pkt.extract(hdr.dstServNum48);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_56_part_2{
    pkt.extract(hdr.dstServNum56);
    transition parse_src_node_num_8;
}

state parse_dst_serv_num_64{
    pkt.extract(hdr.dstServNum64);
    transition parse_src_node_num_8;
}

// //**** Parsing varation of sizes for SRC Node Num ****//

state parse_src_node_num_8{
    src_node_num_t_part1 d = pkt.lookahead<src_node_num_t_part1>();

    transition select(d.init_1, d.init_2, d.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_src_node_num_part2;
//3 byte
        (1,1,0): parse_src_node_num_24_part_2;
//2 byte
        (1,0,0) : parse_src_node_num_16_part_2;
        (1,0,1) : parse_src_node_num_16_part_2;
//1 byte
        (0,0,0) : parse_src_node_num_8_part_2;
        (0,0,1) : parse_src_node_num_8_part_2;
        (0,1,0) : parse_src_node_num_8_part_2;
        (0,1,1) : parse_src_node_num_8_part_2;
    }
}

state parse_src_node_num_part2{
    src_node_num_t_part2 d = pkt.lookahead<src_node_num_t_part2>();

    transition select(d.init_4,d.init_5, d.init_6) {
// > 6 bytes
        (1,1,1):parse_src_node_num_part3;
//6 bytes
        (1,1,0):parse_src_node_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_src_node_num_40_part_2;
        (1,0,1) : parse_src_node_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_src_node_num_32_part_2;
        (0,0,1) : parse_src_node_num_32_part_2;
        (0,1,0) : parse_src_node_num_32_part_2;
        (0,1,1) : parse_src_node_num_32_part_2;
    }
}
state parse_src_node_num_part3{
    src_node_num_t_part3 d = pkt.lookahead<src_node_num_t_part3>();

    transition select(d.init_7) {
//8 bytes
        (1):parse_src_node_num_64;
//7 bytes
        (0):parse_src_node_num_56_part_2;
    }
}

state parse_src_node_num_8_part_2{
    pkt.extract(hdr.srcNodeNum8);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_16_part_2{
    pkt.extract(hdr.srcNodeNum16);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_24_part_2{
    pkt.extract(hdr.srcNodeNum24);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_32_part_2{
    pkt.extract(hdr.srcNodeNum32);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_40_part_2{
    pkt.extract(hdr.srcNodeNum40);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_48_part_2{
    pkt.extract(hdr.srcNodeNum48);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_56_part_2{
    pkt.extract(hdr.srcNodeNum56);
    transition parse_src_serv_num_8;
}

state parse_src_node_num_64{
    pkt.extract(hdr.srcNodeNum64);
    transition parse_src_serv_num_8;
}

// // //**** Parsing varation of sizes for SRC Serv Num ****//
state parse_src_serv_num_8{
    src_serv_num_part1 l = pkt.lookahead<src_serv_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_src_serv_num_part2;
//3 byte
        (1,1,0): parse_src_serv_num_24_part_2;
//2 byte
        (1,0,0) : parse_src_serv_num_16_part_2;
        (1,0,1) : parse_src_serv_num_16_part_2;
//1 byte
        (0,0,0) : parse_src_serv_num_8_part_2;
        (0,0,1) : parse_src_serv_num_8_part_2;
        (0,1,0) : parse_src_serv_num_8_part_2;
        (0,1,1) : parse_src_serv_num_8_part_2;
    }
}

state parse_src_serv_num_part2{
    src_serv_num_part2 l = pkt.lookahead<src_serv_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_src_serv_num_part3;
//6 bytes
        (1,1,0):parse_src_serv_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_src_serv_num_40_part_2;
        (1,0,1) : parse_src_serv_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_src_serv_num_32_part_2;
        (0,0,1) : parse_src_serv_num_32_part_2;
        (0,1,0) : parse_src_serv_num_32_part_2;
        (0,1,1) : parse_src_serv_num_32_part_2;
    }
}

state parse_src_serv_num_part3{
    src_serv_num_part3 l = pkt.lookahead<src_serv_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_src_serv_num_64;
//7 bytes
        (0):parse_src_serv_num_56_part_2;
    }
}

state parse_src_serv_num_8_part_2{
    pkt.extract(hdr.srcServNum8);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_16_part_2{
    pkt.extract(hdr.srcServNum16);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_24_part_2{
    pkt.extract(hdr.srcServNum24);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_32_part_2{
    pkt.extract(hdr.srcServNum32);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_40_part_2{
    pkt.extract(hdr.srcServNum40);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_48_part_2{
    pkt.extract(hdr.srcServNum48);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_56_part_2{
    pkt.extract(hdr.srcServNum56);
    transition parse_rep_node_num_8;
}

state parse_src_serv_num_64{
    pkt.extract(hdr.srcServNum64);
    transition parse_rep_node_num_8;
}


// // // //**** Parsing varation of sizes for Rep Node Num ****//
state parse_rep_node_num_8{
    rep_node_num_part1 l = pkt.lookahead<rep_node_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_rep_node_num_part2;
//3 byte
        (1,1,0): parse_rep_node_num_24_part_2;
//2 byte
        (1,0,0) : parse_rep_node_num_16_part_2;
        (1,0,1) : parse_rep_node_num_16_part_2;
//1 byte
        (0,0,0) : parse_rep_node_num_8_part_2;
        (0,0,1) : parse_rep_node_num_8_part_2;
        (0,1,0) : parse_rep_node_num_8_part_2;
        (0,1,1) : parse_rep_node_num_8_part_2;
    }
}

state parse_rep_node_num_part2{
    rep_node_num_part2 l = pkt.lookahead<rep_node_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_rep_node_num_part3;
//6 bytes
        (1,1,0):parse_rep_node_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_rep_node_num_40_part_2;
        (1,0,1) : parse_rep_node_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_rep_node_num_32_part_2;
        (0,0,1) : parse_rep_node_num_32_part_2;
        (0,1,0) : parse_rep_node_num_32_part_2;
        (0,1,1) : parse_rep_node_num_32_part_2;
    }
}

state parse_rep_node_num_part3{
    rep_node_num_part3 l = pkt.lookahead<rep_node_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_rep_node_num_64;
//7 bytes
        (0):parse_rep_node_num_56_part_2;
    }
}

state parse_rep_node_num_8_part_2{
    pkt.extract(hdr.repNodeNum8);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_16_part_2{
    pkt.extract(hdr.repNodeNum16);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_24_part_2{
    pkt.extract(hdr.repNodeNum24);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_32_part_2{
    pkt.extract(hdr.repNodeNum32);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_40_part_2{
    pkt.extract(hdr.repNodeNum40);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_48_part_2{
    pkt.extract(hdr.repNodeNum48);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_56_part_2{
    pkt.extract(hdr.repNodeNum56);
    transition parse_rep_serv_num_8;
}

state parse_rep_node_num_64{
    pkt.extract(hdr.repNodeNum64);
    transition parse_rep_serv_num_8;
}


// // // //**** Parsing varation of sizes for Rep Serv Num ****//
state parse_rep_serv_num_8{
    rep_serv_num_part1 l = pkt.lookahead<rep_serv_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_rep_serv_num_part2;
//3 byte
        (1,1,0): parse_rep_serv_num_24_part_2;
//2 byte
        (1,0,0) : parse_rep_serv_num_16_part_2;
        (1,0,1) : parse_rep_serv_num_16_part_2;
//1 byte
        (0,0,0) : parse_rep_serv_num_8_part_2;
        (0,0,1) : parse_rep_serv_num_8_part_2;
        (0,1,0) : parse_rep_serv_num_8_part_2;
        (0,1,1) : parse_rep_serv_num_8_part_2;
    }
}

state parse_rep_serv_num_part2{
    rep_serv_num_part2 l = pkt.lookahead<rep_serv_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_rep_serv_num_part3;
//6 bytes
        (1,1,0):parse_rep_serv_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_rep_serv_num_40_part_2;
        (1,0,1) : parse_rep_serv_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_rep_serv_num_32_part_2;
        (0,0,1) : parse_rep_serv_num_32_part_2;
        (0,1,0) : parse_rep_serv_num_32_part_2;
        (0,1,1) : parse_rep_serv_num_32_part_2;
    }
}

state parse_rep_serv_num_part3{
    rep_serv_num_part3 l = pkt.lookahead<rep_serv_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_rep_serv_num_64;
//7 bytes
        (0):parse_rep_serv_num_56_part_2;
    }
}

state parse_rep_serv_num_8_part_2{
    pkt.extract(hdr.repServNum8);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_16_part_2{
    pkt.extract(hdr.repServNum16);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_24_part_2{
    pkt.extract(hdr.repServNum24);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_32_part_2{
    pkt.extract(hdr.repServNum32);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_40_part_2{
    pkt.extract(hdr.repServNum40);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_48_part_2{
    pkt.extract(hdr.repServNum48);
    transition parse_cust_node_num_8;
}

state parse_rep_serv_num_56_part_2{
    pkt.extract(hdr.repServNum56);
    transition parse_cust_node_num_8;
}


state parse_rep_serv_num_64{
    pkt.extract(hdr.repServNum64);
    transition parse_cust_node_num_8;
}

// // // //**** Parsing varation of sizes for Cust Node Num ****//
state parse_cust_node_num_8{
    cust_node_num_part1 l = pkt.lookahead<cust_node_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_cust_node_num_part2;
//3 byte
        (1,1,0): parse_cust_node_num_24_part_2;
//2 byte
        (1,0,0) : parse_cust_node_num_16_part_2;
        (1,0,1) : parse_cust_node_num_16_part_2;
//1 byte
        (0,0,0) : parse_cust_node_num_8_part_2;
        (0,0,1) : parse_cust_node_num_8_part_2;
        (0,1,0) : parse_cust_node_num_8_part_2;
        (0,1,1) : parse_cust_node_num_8_part_2;
    }
}

state parse_cust_node_num_part2{
    cust_node_num_part2 l = pkt.lookahead<cust_node_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_cust_node_num_part3;
//6 bytes
        (1,1,0):parse_cust_node_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_cust_node_num_40_part_2;
        (1,0,1) : parse_cust_node_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_cust_node_num_32_part_2;
        (0,0,1) : parse_cust_node_num_32_part_2;
        (0,1,0) : parse_cust_node_num_32_part_2;
        (0,1,1) : parse_cust_node_num_32_part_2;
    }
}

state parse_cust_node_num_part3{
    cust_node_num_part3 l = pkt.lookahead<cust_node_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_cust_node_num_64;
//7 bytes
        (0):parse_cust_node_num_56_part_2;
    }
}

state parse_cust_node_num_8_part_2{
    pkt.extract(hdr.custNodeNum8);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_16_part_2{
    pkt.extract(hdr.custNodeNum16);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_24_part_2{
    pkt.extract(hdr.custNodeNum24);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_32_part_2{
    pkt.extract(hdr.custNodeNum32);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_40_part_2{
    pkt.extract(hdr.custNodeNum40);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_48_part_2{
    pkt.extract(hdr.custNodeNum48);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_56_part_2{
    pkt.extract(hdr.custNodeNum56);
    transition parse_cust_serv_num_8;
}

state parse_cust_node_num_64{
    pkt.extract(hdr.custNodeNum64);
    transition parse_cust_serv_num_8;
}


// // //**** Parsing varation of sizes for Cust Serv Num ****//
state parse_cust_serv_num_8{
    cust_serv_num_part1 l = pkt.lookahead<cust_serv_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_cust_serv_num_part2;
//3 byte
        (1,1,0): parse_cust_serv_num_24_part_2;
//2 byte
        (1,0,0) : parse_cust_serv_num_16_part_2;
        (1,0,1) : parse_cust_serv_num_16_part_2;
//1 byte
        (0,0,0) : parse_cust_serv_num_8_part_2;
        (0,0,1) : parse_cust_serv_num_8_part_2;
        (0,1,0) : parse_cust_serv_num_8_part_2;
        (0,1,1) : parse_cust_serv_num_8_part_2;
    }
}

state parse_cust_serv_num_part2{
    cust_serv_num_part2 l = pkt.lookahead<cust_serv_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):cust_serv_num_part3;
//6 bytes
        (1,1,0):parse_cust_serv_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_cust_serv_num_40_part_2;
        (1,0,1) : parse_cust_serv_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_cust_serv_num_32_part_2;
        (0,0,1) : parse_cust_serv_num_32_part_2;
        (0,1,0) : parse_cust_serv_num_32_part_2;
        (0,1,1) : parse_cust_serv_num_32_part_2;
    }
}

state cust_serv_num_part3{
    cust_serv_num_part3 l = pkt.lookahead<cust_serv_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_cust_serv_num_64;
//7 bytes
        (0):parse_cust_serv_num_56_part_2;
    }
}

state parse_cust_serv_num_8_part_2{
    pkt.extract(hdr.custServNum8);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_16_part_2{
    pkt.extract(hdr.custServNum16);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_24_part_2{
    pkt.extract(hdr.custServNum24);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_32_part_2{
    pkt.extract(hdr.custServNum32);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_40_part_2{
    pkt.extract(hdr.custServNum40);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_48_part_2{
    pkt.extract(hdr.custServNum48);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_56_part_2{
    pkt.extract(hdr.custServNum56);
    transition parse_creation_ts_40;
}

state parse_cust_serv_num_64{
    pkt.extract(hdr.custServNum64);
    transition parse_creation_ts_40;
}

// * * * * * * * * * PARSED TO HERE * * * * * * * * * * * * //



// // // //**** Parsing varation of sizes for Creation Time Stamp ****//


state parse_creation_ts_40{
    bit<33> start_byte = pkt.lookahead<bit<33>>();
    bit<1> slicedBit = start_byte[0:0];

    transition select(slicedBit){
        0: parse_creation_ts_40_part_2;
        1: parse_creation_ts_48;
    }
}
state parse_creation_ts_40_part_2{
    pkt.extract(hdr.creationTs40);
    transition parse_creation_ts_seq_num_8;
}


state parse_creation_ts_48{
    bit<41> start_byte = pkt.lookahead<bit<41>>();
    bit<1> slicedBit = start_byte[0:0];

    transition select(slicedBit){
        0: parse_creation_ts_48_part_2;
        1: parse_creation_ts_56;
    }
}
state parse_creation_ts_48_part_2{
    pkt.extract(hdr.creationTs48);
    transition parse_creation_ts_seq_num_8;
}


state parse_creation_ts_56{
    bit<49> start_byte = pkt.lookahead<bit<49>>();
    bit<1> slicedBit = start_byte[0:0];

    transition select(slicedBit){
        0: parse_creation_ts_56_part_2;
        1: parse_creation_ts_64;
    }
}
state parse_creation_ts_56_part_2{
    pkt.extract(hdr.creationTs56);
    transition parse_creation_ts_seq_num_8;
}


state parse_creation_ts_64{
    pkt.extract(hdr.creationTs64);
    transition parse_creation_ts_seq_num_8;
}

// **** Parsing varation of sizes for Creation Timestamp Seq Num ****//

state parse_creation_ts_seq_num_8{
    creation_timestamp_seq_num_part1 l = pkt.lookahead<creation_timestamp_seq_num_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_creation_timestamp_seq_num_part2;
//3 byte
        (1,1,0): parse_creation_ts_seq_num_24_part_2;
//2 byte
        (1,0,0) : parse_creation_ts_seq_num_16_part_2;
        (1,0,1) : parse_creation_ts_seq_num_16_part_2;
//1 byte
        (0,0,0) : parse_creation_ts_seq_num_8_part_2;
        (0,0,1) : parse_creation_ts_seq_num_8_part_2;
        (0,1,0) : parse_creation_ts_seq_num_8_part_2;
        (0,1,1) : parse_creation_ts_seq_num_8_part_2;
    }
}

state parse_creation_timestamp_seq_num_part2{
    creation_timestamp_seq_num_part2 l = pkt.lookahead<creation_timestamp_seq_num_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_creation_timestamp_seq_num_part3;
//6 bytes
        (1,1,0):parse_creation_ts_seq_num_48_part_2;
// 5 bytes
        (1,0,0) : parse_creation_ts_seq_num_40_part_2;
        (1,0,1) : parse_creation_ts_seq_num_40_part_2;
// 4 bytes
        (0,0,0) : parse_creation_ts_seq_num_32_part_2;
        (0,0,1) : parse_creation_ts_seq_num_32_part_2;
        (0,1,0) : parse_creation_ts_seq_num_32_part_2;
        (0,1,1) : parse_creation_ts_seq_num_32_part_2;
    }
}

state parse_creation_timestamp_seq_num_part3{
    creation_timestamp_seq_num_part3 l = pkt.lookahead<creation_timestamp_seq_num_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_creation_ts_seq_num_64;
//7 bytes
        (0):parse_creation_ts_seq_num_56_part_2;
    }
}

state parse_creation_ts_seq_num_8_part_2{
    pkt.extract(hdr.creationTsSeqNum8);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_16_part_2{
    pkt.extract(hdr.creationTsSeqNum16);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_24_part_2{
    pkt.extract(hdr.creationTsSeqNum24);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_32_part_2{
    pkt.extract(hdr.creationTsSeqNum32);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_40_part_2{
    pkt.extract(hdr.creationTsSeqNum40);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_48_part_2{
    pkt.extract(hdr.creationTsSeqNum48);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_56_part_2{
    pkt.extract(hdr.creationTsSeqNum56);
    transition parse_lifetime_8;
}

state parse_creation_ts_seq_num_64{
    pkt.extract(hdr.creationTsSeqNum64);
    transition parse_lifetime_8;
}

// //**************************Parse lifetime field*******************//

state parse_lifetime_8{
    lifetime_part1 l = pkt.lookahead<lifetime_part1>();

    transition select(l.init_1, l.init_2, l.init_3) {
// > 3 bytes
        (1, 1, 1) : parse_lifetime_part2;
//3 byte
        (1,1,0): parse_lifetime_24_part_2;
//2 byte
        (1,0,0) : parse_lifetime_16_part_2;
        (1,0,1) : parse_lifetime_16_part_2;
//1 byte
        (0,0,0) : parse_lifetime_8_part_2;
        (0,0,1) : parse_lifetime_8_part_2;
        (0,1,0) : parse_lifetime_8_part_2;
        (0,1,1) : parse_lifetime_8_part_2;
    }
}

state parse_lifetime_part2{
    lifetime_part2 l = pkt.lookahead<lifetime_part2>();

    transition select(l.init_4,l.init_5, l.init_6) {
// > 6 bytes
        (1,1,1):parse_lifetime_part3;
//6 bytes
        (1,1,0):parse_lifetime_48_part_2;
// 5 bytes
        (1,0,0) : parse_lifetime_40_part_2;
        (1,0,1) : parse_lifetime_40_part_2;
// 4 bytes
        (0,0,0) : parse_lifetime_32_part_2;
        (0,0,1) : parse_lifetime_32_part_2;
        (0,1,0) : parse_lifetime_32_part_2;
        (0,1,1) : parse_lifetime_32_part_2;
    }
}

state parse_lifetime_part3{
    lifetime_part3 l = pkt.lookahead<lifetime_part3>();

    transition select(l.init_7) {
//8 bytes
        (1):parse_lifetime_64;
//7 bytes
        (0):parse_lifetime_56_part_2;
    }
}

state parse_lifetime_8_part_2{
    pkt.extract(hdr.lifetime8);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_16_part_2{
    pkt.extract(hdr.lifetime16);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_24_part_2{
    pkt.extract(hdr.lifetime24);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_32_part_2{
    pkt.extract(hdr.lifetime32);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_40_part_2{
    pkt.extract(hdr.lifetime40);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_48_part_2{
    pkt.extract(hdr.lifetime48);
    transition parse_dict_len_8_part_2;
}

state parse_lifetime_56_part_2{
    pkt.extract(hdr.lifetime56);
    transition parse_dict_len_8_part_2;
}


state parse_lifetime_64{
    pkt.extract(hdr.lifetime64);
    transition parse_dict_len_8_part_2;
}

state parse_dict_len_8_part_2{
    pkt.extract(hdr.dictLength8);
    transition accept;
}
# 87 "../../bundle_translator_v3/bundle_translator_v3.p4" 2
 // #include "parse_v7.p4"
}

/***    Ingress Match-Action   ***/
control Ingress(inout headers_t hdr,
  inout metadata_headers_t meta,
  in ingress_intrinsic_metadata_t ig_intr_md,
  in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
  inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
 action checksum_upd_ipv4(bool update) {
  meta.checksum_upd_ipv4 = update;
 }

 action checksum_upd_udp(bool update) {
  meta.checksum_upd_udp = update;
 }

 action send(PortId_t port) {
  ig_tm_md.ucast_egress_port = port; // egress port for unicast packets. must be presented to TM for unicast



 }

 action drop() {
  ig_dprsr_md.drop_ctl = 1; // disable packet replication --bit 1 disables copy-to-cpu
 }

 table ipv4_host {
  key = {
   hdr.ipv4.dst_addr : exact; // Match IP addresses exactly (not LPM)
  }

  actions = {
   send;
   drop;



  }





  size = 65536;
 }

 apply {
  ig_dprsr_md.digest_type = DIGEST_TYPE_DEBUG; // Telling deparser that it will receive debugging digests

  // Note: ttl field is used for debugging purposes. Can determine what headers were parsed correctly by examining output packet's ttl field.
  hdr.ipv4.ttl = 1;
  if (hdr.ipv4.isValid()) {
   hdr.ipv4.ttl = 2;
   if (hdr.udp.isValid()) {
    hdr.ipv4.ttl = 3;
    if(hdr.bundleFlags16.isValid()){
     hdr.ipv4.ttl = 5;
    }
    if(hdr.blockLength8.isValid()){
     hdr.ipv4.ttl = hdr.ipv4.ttl + 8;
    }
    if(hdr.dstNodeNum8.isValid()){
     hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    }
    // if(hdr.dstServNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.srcNodeNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.srcServNum8.isValid()){ //-one of these
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.repNodeNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.repServNum8.isValid()){ //-one of these
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    //All headers above^^^ are valid


    // if(hdr.custNodeNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.custServNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.creationTs40.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.creationTsSeqNum8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.lifetime24.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }
    // if(hdr.dictLength8.isValid()){
    // 	hdr.ipv4.ttl = hdr.ipv4.ttl + 1;
    // }

    // meta.debug_metadata.block_num = hdr.dstNodeNum24.dst_node_num;
    // meta.debug_metadata.block_flags = hdr.dstNodeNum16.dst_node_num;
    // meta.debug_metadata.hdr_version_num = hdr.dstNodeNum8.dst_node_num;


    // if (meta.incomingV7) {
    // 	#include "control_v7.p4" // Translate v7 to v6
    // } else if (meta.incomingV6) {
    // 	#include "control_v6.p4" // Translate v6 to v7
    // }

    checksum_upd_udp(true); // Always update udp checksum
   }
   checksum_upd_ipv4(true); // Always update ipv4 checksum
   ipv4_host.apply();
  }
 }
}

/***    Ingress Deparser   ***/
control IngressDeparser(packet_out pkt,
   inout headers_t hdr,
   in metadata_headers_t meta,
   in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
 Checksum() ipv4_checksum;
 Checksum() udp_checksum;

 Digest<debug_digest_t>() debug_digest;

 apply {
  if (ig_dprsr_md.digest_type == DIGEST_TYPE_DEBUG) {
   // If statement is required, even though there's currently no other digest types
   debug_digest.pack(meta.debug_metadata);
  }

  if (meta.checksum_upd_ipv4) {
   // Recalculating IP checksum because incremental checksum update didn't work.
   hdr.ipv4.hdr_checksum = ipv4_checksum.update(
    {hdr.ipv4.version,
     hdr.ipv4.ihl,
     hdr.ipv4.diffserv,
     hdr.ipv4.total_len,
     hdr.ipv4.identification,
     hdr.ipv4.flags,
     hdr.ipv4.frag_offset,
     hdr.ipv4.ttl,
     hdr.ipv4.protocol,
     hdr.ipv4.src_addr,
     hdr.ipv4.dst_addr});
  }

  // if (meta.checksum_upd_udp) {
  // 	/* 
  // 	   Recalculating UDP checksum because incremental checksum update didn't work
  // 	   Important notes:
  // 	    - UDP checksum requires 16-bit aligned values, which means 8-bit padding needs to be added in certain places.
  // 	    - The ADU padding is very brittle and not the "correct" way of doing this.
  // 	        - Would be better to have separate cases for each ADU (i.e. if we have ADU of length 2, then only add adu_2 to the checksum)
  // 	        - Current hacky version takes advantage of the fact that adu fields that weren't used/parsed/extracted into have all 0 values (not guaranteed behavior)
  // 	            - Unused ADU fields are adding zero-values to the checksum, which doesn't affect the final checksum value
  //                 - Because of 16-bit alignment requirement, some octets of 0s need to be added to ensure alignment is maintained. (not sure exactly how the math works out)
  //             - If we did incremental checksum, adding ADU manually to checksum wouldn't be necessary
  // 	    - For debugging purposes there are comments with # of bits in each field
  // 	*/

  // 	if (meta.incomingV7) {
  // 		// Bundle is now BPv6, need to recalculate checksum
  // 		hdr.udp.checksum = udp_checksum.update(data = {
  // 			hdr.ipv4.src_addr, // 32
  // 			hdr.ipv4.dst_addr, // 32
  // 			8w0, // 8
  // 			hdr.ipv4.protocol, // 8

  // 			hdr.udp.hdr_length, // 16
  // 			hdr.udp.src_port, // 16
  // 			hdr.udp.dst_port, // 16
  // 			hdr.udp.hdr_length, // 16

  // 			hdr.bpv6_primary_cbhe.version, // 8
  // 			hdr.bpv6_primary_cbhe.bundle_flags, // 16
  // 			hdr.bpv6_primary_cbhe.block_length, // 8
  // 			hdr.bpv6_primary_cbhe.dst_node_num, // 8
  // 			hdr.bpv6_primary_cbhe.dst_serv_num, // 8
  // 			hdr.bpv6_primary_cbhe.src_node_num, // 8
  // 			hdr.bpv6_primary_cbhe.src_serv_num, // 8
  // 			hdr.bpv6_primary_cbhe.rep_node_num, // 8
  // 			hdr.bpv6_primary_cbhe.rep_serv_num, // 8
  // 			hdr.bpv6_primary_cbhe.cust_node_num, // 8
  // 			hdr.bpv6_primary_cbhe.cust_serv_num, // 8
  // 			hdr.bpv6_primary_cbhe.creation_ts, // 40
  // 			hdr.bpv6_primary_cbhe.creation_ts_seq_num, // 8
  // 			hdr.bpv6_primary_cbhe.lifetime, // 24
  // 			hdr.bpv6_primary_cbhe.dict_len, // 8
  // 			// Everything above is 16-bit aligned

  // 			// Extension blocks aren't translated so don't need to add them to checksum

  // 			hdr.bpv6_payload.block_type_code, // 8
  // 			hdr.bpv6_payload.block_flags, // 8
  // 			hdr.bpv6_payload.payload_length, // 8

  // 			hdr.adu_1.adu, // 8
  // 			8w0,           // 8
  // 			hdr.adu_2.adu, // 16
  // 			hdr.adu_3.adu, // 24
  // 			8w0,           // 8
  // 			hdr.adu_4.adu, // 32
  // 			hdr.adu_5.adu, // 40
  // 			8w0,           // 8
  // 			hdr.adu_6.adu,
  // 			hdr.adu_7.adu,
  // 			8w0,
  // 			hdr.adu_8.adu,
  // 			hdr.adu_9.adu,
  // 			8w0,
  // 			hdr.adu_10.adu,
  // 			hdr.adu_11.adu,
  // 			8w0,
  // 			hdr.adu_12.adu,
  // 			hdr.adu_13.adu
  // 		}, zeros_as_ones = true);
  // 	} else if (meta.incomingV6) {
  // 		// Bundle is now BPv7, need to recalculate checksum
  // 		hdr.udp.checksum = udp_checksum.update(data = {
  // 			hdr.ipv4.src_addr, // 32
  // 			hdr.ipv4.dst_addr, // 32
  // 			8w0, // 8
  // 			hdr.ipv4.protocol, // 8

  // 			hdr.udp.hdr_length, // 16
  // 			hdr.udp.src_port, // 16
  // 			hdr.udp.dst_port, // 16
  // 			hdr.udp.hdr_length, // 16

  // 			hdr.bpv7_start_code.start_code, // 8
  // 			hdr.bpv7_primary_1.prim_initial_byte, // 8
  // 			hdr.bpv7_primary_1.version_num, // 8
  // 			hdr.bpv7_primary_1.bundle_flags, // 16
  // 			hdr.bpv7_primary_1.crc_type, //8
  // 			hdr.bpv7_primary_1.dest_eid, // 40
  // 			hdr.bpv7_primary_1.src_eid, // 40
  // 			hdr.bpv7_primary_1.report_eid, // 40
  // 			hdr.bpv7_primary_1.creation_timestamp_time_initial_byte, //8
  // 			hdr.bpv7_primary_1.creation_timestamp_time, // 72
  // 			hdr.bpv7_primary_1.creation_timestamp_seq_num_initial_byte, // 8

  // 			// Creation timestamp seq. num is hardcoded to be small in translation so don't need to worry including these in checksum right now: bpv7_primary_2_1, bpv7_primary_2_2, bpv7_primary_2_4, bpv7_primary_2_8

  // 			hdr.bpv7_primary_3.lifetime, // 40
  // 			hdr.bpv7_primary_3.crc_field_integer, // 24
  // 			// Everything above is 16-bit aligned

  // 			// Extension blocks aren't translated so don't need to add them to checksum

  // 			hdr.bpv7_payload.initial_byte, // 8
  // 			hdr.bpv7_payload.block_type, // 8
  // 			hdr.bpv7_payload.block_num, // 8
  // 			hdr.bpv7_payload.block_flags, // 8
  // 			hdr.bpv7_payload.crc_type, // 8
  // 			hdr.bpv7_payload.adu_initial_byte, // 8

  // 			hdr.adu_1.adu, // 8
  // 			8w0,           // 8
  // 			hdr.adu_2.adu, // 16
  // 			hdr.adu_3.adu, // 24
  // 			8w0,           // 8
  // 			hdr.adu_4.adu, // 32
  // 			hdr.adu_5.adu, // 40
  // 			8w0,
  // 			hdr.adu_6.adu,
  // 			hdr.adu_7.adu,
  // 			8w0,
  // 			hdr.adu_8.adu,
  // 			hdr.adu_9.adu,
  // 			8w0,
  // 			hdr.adu_10.adu,
  // 			hdr.adu_11.adu,
  // 			8w0,
  // 			hdr.adu_12.adu,
  // 			hdr.adu_13.adu
  // 		}, zeros_as_ones = true);

  // 	}
  // }

  pkt.emit(hdr);
 }
}

/***    EGRESS PROCESSING   ***/
// Egress processing currently only contains the required boiler plate code

struct egress_headers_t {
}
struct egress_metadata_t {
}

/***    Egress Parser   ***/
parser EgressParser(packet_in pkt,
     out egress_headers_t hdr,
     out egress_metadata_t meta,
     out egress_intrinsic_metadata_t eg_intr_md)
{
 state start {
  pkt.extract(eg_intr_md);
  transition accept;
 }
}
/***    Egress Match-Action   ***/
control Egress(
  inout egress_headers_t hdr,
  inout egress_metadata_t meta,
  in egress_intrinsic_metadata_t eg_intr_md,
  in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
  inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
  inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
 apply {
 }
}
/***    Egress Deparser   ***/
control EgressDeparser(packet_out pkt,
    inout egress_headers_t hdr,
    in egress_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
 apply {
  pkt.emit(hdr);
 }
}

/***    Final Package   ***/

// Create a Pipeline instance
Pipeline(
 IngressParser(),
 Ingress(),
 IngressDeparser(),
 EgressParser(),
 Egress(),
 EgressDeparser()
) pipe;

// Our switch will use one pipe instance for all pipes (i.e. all pipes do the same thing)
Switch(pipe) main;
