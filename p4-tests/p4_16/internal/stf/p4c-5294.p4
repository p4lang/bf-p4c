//p4_16

// Bundle Protocol Translator
// Translates incoming bundles from BPv6 to BPv7 and vice versa (with limitations)

// Ingress Parser extracts data from bundles into P4 data types
// Ingress Match-action/control logic converts into translated data types (and sets up forwarding logic)
// Ingress Deparser sends out the new version onto the wire
// Egress doesn't do anything special, but can be used in future if needed

#include <core.p4>
#include <tna.p4>

#ifndef TEST_ID
#define TEST_ID 1
#endif


// Contains all Bundle Protocol specific headers
// Included in headers.p4 file


/*   BPv7 Headers   */
const bit<8> CBOR_MASK_MT = 8w0b11100000;                   // CBOR Major Type Mask
const bit<8> CBOR_MASK_AI = 8w0b00011111;                  // CBOR Additional Info Mask

header bpv7_start_code_h {
    bit<8> bpv7_start_code;
}

header bpv7_prim_initial_byte_h {
    bit<8> initial_byte;
}
header bpv7_version_num_h {
    bit<8> version_num;
}


header bpv7_bundle_flags_8bit_h {
    bit<8> header_field;
}
header bpv7_bundle_flags_16bit_h  {
    bit<16> header_field;
}
header bpv7_bundle_flags_32bit_h  {
    bit<32> header_field;
}
header bpv7_bundle_flags_64bit_h  {
    bit<64> header_field;
}
header bpv7_bundle_flags_72bit_h  {
    bit<72> header_field;
}


header bpv7_crc_type_h {
   bit<8> crc_type;
}

// Destination indicator
header bpv7_dest_eid_ind_h {
    bit<3> mt;
    bit<5> vt;
}
// header bpv7_dest_eid_ind_h {
//     bit<8> h_field;
// }
header bpv7_dest_eid_8bit_h {
    bit<8> h_field;
}
header bpv7_dest_eid_16bit_h{
    bit<16> h_field;
}
header bpv7_dest_eid_32bit_h{
    bit<32> h_field;
}
header bpv7_dest_eid_64bit_h{
    bit<64> h_field;
}
header bpv7_dest_eid_72bit_h{
    bit<72> h_field;
}


// Source indicator
header bpv7_src_eid_ind_h {
    bit<3> mt;
    bit<5> vt;
}

header bpv7_src_eid_8bit_h {
    bit<8> h_field;
}
header bpv7_src_eid_16bit_h{
    bit<16> h_field;
}
header bpv7_src_eid_32bit_h{
    bit<32> h_field;
}
header bpv7_src_eid_64bit_h{
    bit<64> h_field;
}
header bpv7_src_eid_72bit_h{
    bit<72> h_field;
}

// Origin indicator
header bpv7_report_ind_h {
    bit<8> h_field;
}

header bpv7_report_eid_ind_h {
    bit<8> h_field;
}
header bpv7_report_eid_8bit_h {
    bit<8> h_field;
}
header bpv7_report_eid_16bit_h{
    bit<16> h_field;
}
header bpv7_report_eid_32bit_h{
    bit<32> h_field;
}
header bpv7_report_eid_64bit_h{
    bit<64> h_field;
}
header bpv7_report_eid_72bit_h{
    bit<72> h_field;
}

// Time since creation
header bpv7_creation_timestamp_time_ind_h {
    bit<3> mt;
    bit<5> vt;
}
header bpv7_creation_timestamp_time_16bit_h{
    bit<16> h_field;
}
header bpv7_creation_timestamp_time_24bit_h {
    bit<24> h_field;
}
header bpv7_creation_timestamp_time_32bit_h{
    bit<32> h_field;
}
header bpv7_creation_timestamp_time_40bit_h {
    bit<40> h_field;
}
header bpv7_creation_timestamp_time_64bit_h{
    bit<64> h_field;
}
header bpv7_creation_timestamp_time_72bit_h{
    bit<72> h_field;
}
header bpv7_creation_timestamp_time_adu_1_h {
    bit<3> mt;
    bit<5> vt;
}
header bpv7_creation_timestamp_time_adu_2_h {
    bit<8> adu_field;
}
header bpv7_creation_timestamp_time_adu_3_h {
    bit<16> adu_field;
}
header bpv7_creation_timestamp_time_adu_4_h {
    bit<32> adu_field;
}
header bpv7_creation_timestamp_time_adu_5_h {
    bit<64> adu_field;
}

// Total lifetime of the packet
header bpv7_lifetime_time_ind_h {
    bit<3> mt;
    bit<5> vt;
}
header bpv7_lifetime_time_8bit_h {
    bit<8> h_field;
}
header bpv7_lifetime_time_16bit_h{
    bit<16> h_field;
}
header bpv7_lifetime_time_32bit_h{
    bit<32> h_field;
}
header bpv7_lifetime_time_64bit_h{
    bit<64> h_field;
}
header bpv7_lifetime_time_72bit_h{
    bit<72> h_field;
}

// CRC indicator
header bpv7_crc_ind_h {
    bit<8> crc;
}
header bpv7_crc_16_bit_h {
    bit<16> crc_16_bit;
}
header bpv7_crc_32_bit_h {
    bit<32> crc_32_bit;
}

// Previous node extension block
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

// header age_data_ind {
//     bit<3> major_type;
//     bit<5> value_type;
// }

#if TEST_ID == 1
// TEST 1
header bpv7_age_block_initial_byte_h {
    bit<8> age_field_1;
}
header bpv7_age_block_type_ind_h {
    bit<8> age_field_2;
}
header bpv7_age_block_num_ind_h {
    bit<8> age_field_3;
}
header bpv7_age_block_flags_ind_h {
    bit<8> age_field_4;
}
header bpv7_age_block_crc_type_h {
    bit<8> age_field_5;
}
header bpv7_age_block_data_ind_h {
    bit<8> age_field_6;
 }
header bpv7_age_block_data_08_bits_h {
    bit<8>  age_field_7;
}
header bpv7_age_block_header_h { }
header bpv7_age_block_header_2_h { }
header bpv7_age_block_header_3_h { }

#elif TEST_ID == 2
// TEST 2
header bpv7_age_block_header_h {
    bit<8> age_field_1;
    bit<8> age_field_2;
    bit<8> age_field_3;
    bit<8> age_field_4;
    bit<8> age_field_5;
    bit<8> age_field_6;
    bit<8> age_field_7;
}
header bpv7_age_block_header_2_h { }
header bpv7_age_block_header_3_h { }

#elif TEST_ID == 3
// TEST 3
header bpv7_age_block_header_h {
    bit<8> age_field_1;
    bit<8> age_field_2;
    bit<8> age_field_3;
    bit<8> age_field_4;
}

header bpv7_age_block_header_2_h {
    bit<8> age_field_5;
    bit<8> age_field_6;
    bit<8> age_field_7;
}

header bpv7_age_block_header_3_h { }

#elif TEST_ID == 4
// TEST 4
header bpv7_age_block_header_h {
    bit<8> age_field_1;
    bit<8> age_field_2;
    bit<8> age_field_3;
}

header bpv7_age_block_header_2_h {
    bit<8> age_field_4;
    bit<8> age_field_5;
}

header bpv7_age_block_header_3_h {
    bit<8> age_field_6;
    bit<8> age_field_7;
}

#endif

// The CBOR indicator for which block number this is
header age_num_ind {
    bit<8> h_field;
}
// The CBOR object that indicates a bytestring is coming followed by the following size in bytes
header age_data_ind {
    bit<3> major_type;
    bit<5> value_type;
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

// End of Bundle
header bpv7_stop_code_h {
	bit<8> stop_code;
}

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

// Lookahead Structs
struct cbor_t {
    bit<3> mt_1;
    bit<5> vt_1;
}
struct cbor_array_t {
    bit<3> mt_1;
    bit<5> vt_1;
    bit<3> mt_2;
    bit<5> vt_2;
}
struct nested_cbor_array_t {
    bit<3> mt_1;
    bit<5> vt_1;
    bit<3> mt_2;
    bit<5> vt_2;
    bit<3> mt_3;
    bit<5> vt_3;
    bit<3> mt_4;
    bit<5> vt_4;
}
// Note: Order of declaration of matters for this struct!
// - Headers are deparsed/emitted in order of declaration
// - Invalid headers are not emitted
struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;

    // Primary Header
    bpv7_start_code_h          bpv7_start_code;
    bpv7_prim_initial_byte_h   bpv7_prim_initial_byte;
    bpv7_version_num_h         bpv7_version_num;

    bpv7_bundle_flags_8bit_h   bpv7_bundle_flags_8bit;
    bpv7_bundle_flags_16bit_h  bpv7_bundle_flags_16bit;
    bpv7_bundle_flags_32bit_h  bpv7_bundle_flags_32bit;
    bpv7_bundle_flags_64bit_h  bpv7_bundle_flags_64bit;
    bpv7_bundle_flags_72bit_h  bpv7_bundle_flags_72bit;

    bpv7_crc_type_h            bpv7_crc_type;

    bpv7_dest_eid_ind_h        bpv7_dest_eid_ind;
    bpv7_dest_eid_8bit_h       bpv7_dest_eid_8bit;
    bpv7_dest_eid_16bit_h      bpv7_dest_eid_16bit;
    bpv7_dest_eid_32bit_h      bpv7_dest_eid_32bit;
    bpv7_dest_eid_64bit_h      bpv7_dest_eid_64bit;
    bpv7_dest_eid_72bit_h      bpv7_dest_eid_72bit;

    bpv7_src_eid_ind_h         bpv7_src_eid_ind;

    bpv7_src_eid_8bit_h        bpv7_src_eid_8bit;
    bpv7_src_eid_16bit_h       bpv7_src_eid_16bit;
    bpv7_src_eid_32bit_h       bpv7_src_eid_32bit;
    bpv7_src_eid_64bit_h       bpv7_src_eid_64bit;
    bpv7_src_eid_72bit_h       bpv7_src_eid_72bit;

    bpv7_report_eid_ind_h      bpv7_report_ind;
    bpv7_report_eid_8bit_h     bpv7_report_8bit;
    bpv7_report_eid_16bit_h    bpv7_report_16bit;
    bpv7_report_eid_32bit_h    bpv7_report_32bit;
    bpv7_report_eid_64bit_h    bpv7_report_64bit;
    bpv7_report_eid_72bit_h    bpv7_report_72bit;

    bpv7_creation_timestamp_time_ind_h       bpv7_creation_timestamp_time_ind;

    bpv7_creation_timestamp_time_16bit_h     bpv7_creation_timestamp_time_16bit;
    bpv7_creation_timestamp_time_24bit_h     bpv7_creation_timestamp_time_24bit;
    bpv7_creation_timestamp_time_32bit_h     bpv7_creation_timestamp_time_32bit;
    bpv7_creation_timestamp_time_40bit_h     bpv7_creation_timestamp_time_40bit;
    bpv7_creation_timestamp_time_64bit_h     bpv7_creation_timestamp_time_64bit;
    bpv7_creation_timestamp_time_72bit_h     bpv7_creation_timestamp_time_72bit;

    bpv7_creation_timestamp_time_adu_1_h     bpv7_creation_timestamp_time_adu_1;
    bpv7_creation_timestamp_time_adu_2_h     bpv7_creation_timestamp_time_adu_2;
    bpv7_creation_timestamp_time_adu_3_h     bpv7_creation_timestamp_time_adu_3;
    bpv7_creation_timestamp_time_adu_4_h     bpv7_creation_timestamp_time_adu_4;
    bpv7_creation_timestamp_time_adu_5_h     bpv7_creation_timestamp_time_adu_5;

    bpv7_lifetime_time_ind_h        bpv7_lifetime_time_ind;
    bpv7_lifetime_time_8bit_h       bpv7_lifetime_time_8bit;
    bpv7_lifetime_time_16bit_h      bpv7_lifetime_time_16bit;
    bpv7_lifetime_time_32bit_h      bpv7_lifetime_time_32bit;
    bpv7_lifetime_time_64bit_h      bpv7_lifetime_time_64bit;
    bpv7_lifetime_time_72bit_h      bpv7_lifetime_time_72bit;

    bpv7_crc_ind_h                  bpv7_crc_ind;
    bpv7_crc_16_bit_h               bpv7_crc_16_bit;
    bpv7_crc_32_bit_h               bpv7_crc_32_bit;

    // Extension Nodes
	bpv7_extension_prev_node_h      bpv7_extension_prev_node;
    bpv7_extension_ecos_h           bpv7_extension_ecos;

#if TEST_ID == 1
    bpv7_age_block_initial_byte_h   age_initial_byte;
    bpv7_age_block_type_ind_h       age_type_ind;
    bpv7_age_block_num_ind_h        age_num_ind;
    bpv7_age_block_flags_ind_h      age_flags_ind;
    bpv7_age_block_crc_type_h       age_crc_ind;
    bpv7_age_block_data_ind_h       age_data_ind;
    bpv7_age_block_data_08_bits_h   age_data_08_bits;
#endif

    bpv7_age_block_header_h         b7_age_header;
    bpv7_age_block_header_2_h       b7_age_header_2;
    bpv7_age_block_header_3_h       b7_age_header_3;
    bpv7_payload_h                  bpv7_payload;



  	// Application Data Unit (ADU) Headers for v6 and v7
  	adu_1_h           adu_1;
  	adu_2_h           adu_2;
  	adu_3_h           adu_3;
  	adu_4_h           adu_4;
  	adu_5_h           adu_5;
  	adu_6_h           adu_6;
  	adu_7_h           adu_7;
  	adu_8_h           adu_8;
  	adu_9_h           adu_9;
  	adu_10_h          adu_10;
  	adu_11_h          adu_11;
  	adu_12_h          adu_12;
  	adu_13_h          adu_13;
    bpv7_stop_code_h  bpv7_stop_code;


}


// Can freely change this, only used for capturing information we care about for debugging
// Maximum allowed data in a digest is 47 bytes
struct debug_digest_t {
    bit<8> hdr_version_num;
    bit<8> initial_byte;
    bit<8> block_type;
    bit<8> block_num;
    bit<8> block_flags;
    bit<8> crc_type;
    bit<8> block_data_initial_byte;
    bit<8> bundle_age;

}

struct metadata_headers_t {
    bit<8> counter;
    bool checksum_upd_ipv4; // True if IPv4 checksum should be updated
    bool checksum_upd_udp; // True if UDP checksum should be updated
  	bool checksum_err_ipv4_igprs; // True if IPv4 checksum was correct
  	bool incomingV7; // True if a BPv7 bundle was ingested
  	bool incomingV6; // True if a BPv6 bundle was ingested

	debug_digest_t debug_metadata; // Used to bridge debug info from ingress match-action stage to ingress deparser
}


/***    INGRESS PROCESSING   ***/

/***    Ingress Parser   ***/
parser IngressParser(packet_in                 pkt,
		     out headers_t                     hdr,
         //out headers_t                     test_hdr,

		     out metadata_headers_t            meta,
		     out ingress_intrinsic_metadata_t  ig_intr_md)
{
	Checksum() ipv4_checksum;
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
			0x9f: parse_v7;
			default: accept;
		}
	}
	state parse_v6{
		meta.incomingV6 = true;
		transition accept;
	}

    // Logic for parsing Bundle Protocol version 7 headers.
    // Assumes that transport layer headers have been extracted and next byte is
    // start of bundle (i.e. CBOR indefinite-length array starparse_t code, 0x9f)

    #if TEST_ID == 1
    // TEST 1 split into 7 headers of fixed, bit<8> fields - 56 bits
    state parse_age_block_init_bytes  {
        pkt.extract(hdr.age_initial_byte);
        transition parse_age_block_type;
    }
    state parse_age_block_type{
        pkt.extract(hdr.age_type_ind);
        transition parse_age_num;
    }
    state parse_age_num {
        pkt.extract(hdr.age_num_ind);
        transition parse_age_flags;
    }
    state parse_age_flags {
        pkt.extract(hdr.age_flags_ind);
        transition parse_age_crc_type;
    }
    state parse_age_crc_type {
        pkt.extract(hdr.age_crc_ind);
        transition parse_age_data_no_crc;
    }
    state parse_age_data_no_crc {
        pkt.extract(hdr.age_data_ind);
        transition parse_age_data_08_bits_no_crc;
    }
    state parse_age_data_08_bits_no_crc {
        pkt.extract(hdr.age_data_08_bits);
        transition parse_end_of_age_block;
     }
    state parse_end_of_age_block {
        transition parse_v7_payload_header;
    }

    #elif TEST_ID == 2
    // TEST 2 ALL IN ONE HEADER  7 fixed fields of bit<8> bytes - 56 bits
    state parse_age_block_init_bytes  {
        pkt.extract(hdr.b7_age_header);
        transition parse_end_of_age_block;
    }
    state parse_end_of_age_block {
        transition parse_v7_payload_header;
    }
    // END TEST 2


    #elif TEST_ID == 3
    // TEST 3 - 7 bit<8> fields in two headers
    // 4 in b7_age_header
    // 3 in b7_age_header_2
    state parse_age_block_init_bytes  {
        pkt.extract(hdr.b7_age_header);
        transition parse_age_block_type;
    }
    state parse_age_block_type{
        pkt.extract(hdr.b7_age_header_2);
        transition parse_end_of_age_block;
    }
    state parse_end_of_age_block {
        transition parse_v7_payload_header;
    }
    // END TEST 3


    #elif TEST_ID == 4
    // TEST 4 - 7 bit<8> fields in two headers
    // 3 in b7_age_header
    // 2 in b7_age_header_2
    // 2 in b7_age_header_3
    state parse_age_block_init_bytes  {
        pkt.extract(hdr.b7_age_header);
        transition parse_age_block_type;
    }
    state parse_age_block_type{
        pkt.extract(hdr.b7_age_header_2);
        transition parse_age_num;
    }
    state parse_age_num {
        pkt.extract(hdr.b7_age_header_3);
        transition parse_end_of_age_block;
    }
    state parse_end_of_age_block {
        transition parse_v7_payload_header;
    }
    // END TEST 4

    #endif


    // EXAMPLE FLOW CONTROL METHODS
    // state parse_age_num {
    //     pkt.extract(hdr.age_num_ind);
    //     transition select(hdr.age_num_ind.h_field) {
    //         0 .. 23 : parse_age_flags;
    //         24 : parse_age_num_ext_08_bits;
    //         25 : parse_age_num_ext_16_bits;
    //         26 : parse_age_num_ext_32_bits;
    //         27 : parse_age_num_ext_64_bits;
    //         // _ : parse_age_flags;
    //     }
    // }
    // state parse_age_data {
    //     pkt.extract (hdr.age_data_ind);
    //     transition select(hdr.age_data_ind.major_type, hdr.age_data_ind.value_type)  {
    //        (2, 1) : parse_age_data_08_bits_no_crc;
    //        (2, 2) : parse_age_data_16_bits_no_crc;
    //        (2, 3) : parse_age_data_24_bits_no_crc;
    //        (2, 4) : parse_age_data_32_bits_no_crc;
    //        (2, 5) : parse_age_data_40_bits_no_crc;
    //        (2, 6) : parse_age_data_48_bits_no_crc;
    //        (2, 7) : parse_age_data_56_bits_no_crc;
    //        (2, 8) : parse_age_data_64_bits_no_crc;
    //        (2, 9) : parse_age_data_72_bits_no_crc;
    //        (2, 10) : parse_age_data_80_bits_no_crc;
    //     }
    // }


    state parse_v7 {
            meta.incomingV7 = true;
            pkt.extract(hdr.bpv7_start_code);
            pkt.extract(hdr.bpv7_prim_initial_byte);
            pkt.extract(hdr.bpv7_version_num);
            transition parse_flags;
    }

    ////   BEGIN PRIMARY BLOCK PROCESSING  ////

    state parse_flags {
        bit<8> cbor_int = pkt.lookahead<bit<8>>();
        transition select(cbor_int) {
                    8w24 &&& CBOR_MASK_AI: parse_bpv7_bundle_flags_16bit;
                    8w25 &&& CBOR_MASK_AI: parse_bpv7_bundle_flags_32bit;
            8w26 &&& CBOR_MASK_AI: parse_bpv7_bundle_flags_64bit;
            8w27 &&& CBOR_MASK_AI: parse_bpv7_bundle_flags_72bit;
        }
    }
    state parse_bpv7_bundle_flags_16bit {
        pkt.extract(hdr.bpv7_bundle_flags_16bit);
        transition parse_bpv7_prim_crc_type;
    }
    state parse_bpv7_bundle_flags_32bit {
        pkt.extract(hdr.bpv7_bundle_flags_32bit);
        transition parse_bpv7_prim_crc_type;
    }
    state parse_bpv7_bundle_flags_64bit {
        pkt.extract(hdr.bpv7_bundle_flags_64bit);
        transition parse_bpv7_prim_crc_type;
    }
    state parse_bpv7_bundle_flags_72bit {
        pkt.extract(hdr.bpv7_bundle_flags_72bit);
        transition parse_bpv7_prim_crc_type;
    }
    state parse_bpv7_prim_crc_type {
       pkt.extract(hdr.bpv7_crc_type);
       transition parse_dest_eid;
     }

    state parse_dest_eid {
        pkt.extract(hdr.bpv7_dest_eid_ind);
        transition select(hdr.bpv7_dest_eid_ind.mt, hdr.bpv7_dest_eid_ind.vt) {
            (3w4, 5w2) : parse_dest_array;   // ipn format
            _ : reject;
        }
    }
    state parse_dest_array {
        cbor_array_t array = pkt.lookahead<cbor_array_t>();
        transition select (array.mt_1, array.vt_1, array.mt_2, array.vt_2) {
            (3w0, 5w0 .. 5w23, 3w4, 5w2) : parse_nested_dest_array;                // contains an nested array
            (3w4, 5w2, 3w0, 5w0 .. 5w23) : parse_nested_dest_array;                // contains an nested array
            (3w0, 5w0 .. 5w23, 3w0, 5w0 .. 5w23) : parse_bpv7_dest_eid_16bit;     // contains only small ints
        }
    }
    state parse_nested_dest_array {
        pkt.extract(hdr.bpv7_dest_eid_32bit);
        transition parse_src_eid;
    }
    state parse_bpv7_dest_eid_8bit {
        pkt.extract(hdr.bpv7_dest_eid_8bit);
        transition parse_src_eid;
    }
    state parse_bpv7_dest_eid_16bit {
        pkt.extract(hdr.bpv7_dest_eid_16bit);
        transition parse_src_eid;
    }
    state parse_bpv7_dest_eid_32bit {
        pkt.extract(hdr.bpv7_dest_eid_32bit);
        transition parse_src_eid;
    }
    state parse_bpv7_dest_eid_64bit {
        pkt.extract(hdr.bpv7_dest_eid_64bit);
        transition parse_src_eid;
    }
    state parse_bpv7_dest_eid_72bit {
        pkt.extract(hdr.bpv7_dest_eid_72bit);
        transition parse_src_eid;
    }

    state parse_src_eid {
        pkt.extract(hdr.bpv7_src_eid_ind);
        transition select(hdr.bpv7_src_eid_ind.mt, hdr.bpv7_src_eid_ind.vt) {
            (3w4, 5w2) : parse_src_array;   // ipn format
            _ : reject;
        }
    }
    state parse_src_array {
        cbor_array_t array = pkt.lookahead<cbor_array_t>();
        transition select (array.mt_1, array.vt_1, array.mt_2, array.vt_2) {
            (3w0, 5w0 .. 5w23, 3w4, 5w2) : parse_nested_src_array;                // contains an nested array
            (3w4, 5w2, 3w0, 5w0 .. 5w23) : parse_nested_src_array;                // contains an nested array
            (3w0, 5w0 .. 5w23, 3w0, 5w0 .. 5w23) : parse_bpv7_src_eid_16bit;
        }
    }

    state parse_nested_src_array {
        pkt.extract(hdr.bpv7_src_eid_32bit);
        transition parse_report_eid;
    }
    state unsupported {
        transition reject;
    }
    state parse_bpv7_src_eid_8bit {
        pkt.extract(hdr.bpv7_src_eid_8bit);
        transition parse_report_eid;
    }
    state parse_bpv7_src_eid_16bit {
        pkt.extract(hdr.bpv7_src_eid_16bit);
        transition parse_report_eid;
    }
    state parse_bpv7_src_eid_32bit {
        pkt.extract(hdr.bpv7_src_eid_32bit);
        transition parse_report_eid;
    }
    state parse_bpv7_src_eid_64bit {
        pkt.extract(hdr.bpv7_src_eid_64bit);
        transition parse_report_eid;
    }
    state parse_bpv7_src_eid_72bit {
        pkt.extract(hdr.bpv7_src_eid_72bit);
        transition parse_report_eid;
    }


    state parse_report_eid {
        pkt.extract(hdr.bpv7_report_ind);
        transition parse_bpv7_report_eid_32bit;
    }
    state parse_bpv7_report_eid_8bit {
        pkt.extract(hdr.bpv7_report_8bit);
        transition parse_creation_timestamp_time;
    }
    state parse_bpv7_report_eid_16bit {
        pkt.extract(hdr.bpv7_report_16bit);
        transition parse_creation_timestamp_time;
    }
    state parse_bpv7_report_eid_32bit {
        pkt.extract(hdr.bpv7_report_32bit);
        transition parse_creation_timestamp_time;
    }
    state parse_bpv7_report_eid_64bit {
        pkt.extract(hdr.bpv7_report_64bit);
        transition parse_creation_timestamp_time;
    }
    state parse_bpv7_report_eid_72bit {
        pkt.extract(hdr.bpv7_report_72bit);
        transition parse_creation_timestamp_time;
    }
    state parse_creation_timestamp_time {
        pkt.extract(hdr.bpv7_creation_timestamp_time_ind);
        transition select(hdr.bpv7_creation_timestamp_time_ind.mt, hdr.bpv7_creation_timestamp_time_ind.vt) {
            (3w4, 5w2) : parse_creation_timestamp_time_array;
            _ : reject;
        }
    }
    state parse_creation_timestamp_time_array {
        cbor_array_t arr = pkt.lookahead<cbor_array_t>();
        transition select (arr.mt_1, arr.vt_1, arr.mt_2, arr.vt_2) {
            (3w0, 5w24,   _, _) : parse_bpv7_creation_timestamp_time_16bit;
            (3w0, 5w25,   _, _) : parse_bpv7_creation_timestamp_time_32bit;
            (3w0, 5w26,   _, _) : parse_bpv7_creation_timestamp_time_64bit;
            (3w0, 5w27,   _, _) : parse_bpv7_creation_timestamp_time_72bit;
        }
    }
    state parse_bpv7_creation_timestamp_time_16bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_16bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    state parse_bpv7_creation_timestamp_time_24bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_24bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    state parse_bpv7_creation_timestamp_time_32bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_32bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    state parse_bpv7_creation_timestamp_time_40bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_40bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    state parse_bpv7_creation_timestamp_time_64bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_64bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    state parse_bpv7_creation_timestamp_time_72bit {
        pkt.extract(hdr.bpv7_creation_timestamp_time_72bit);
        transition parse_bpv7_creation_timestamp_time_adu_1;
    }
    // parse the second position in the time array, the sequence number
    state parse_bpv7_creation_timestamp_time_adu_1 {
        pkt.extract(hdr.bpv7_creation_timestamp_time_adu_1);
        transition select (hdr.bpv7_creation_timestamp_time_adu_1.mt, hdr.bpv7_creation_timestamp_time_adu_1.vt) {
            (3w0 , 5w24) : parse_bpv7_creation_timestamp_time_adu_2;
            (3w0 , 5w25) : parse_bpv7_creation_timestamp_time_adu_3;
            (3w0 , 5w26) : parse_bpv7_creation_timestamp_time_adu_4;
            (3w0 , 5w27) : parse_bpv7_creation_timestamp_time_adu_5;
            (3w0 , _)    : parse_bpv7_lifetime_time;
        }
    }
    state parse_bpv7_creation_timestamp_time_adu_2 {
        pkt.extract(hdr.bpv7_creation_timestamp_time_adu_2);
        transition parse_bpv7_lifetime_time;
    }
    state parse_bpv7_creation_timestamp_time_adu_3 {
        pkt.extract(hdr.bpv7_creation_timestamp_time_adu_3);
        transition parse_bpv7_lifetime_time;
    }
    state parse_bpv7_creation_timestamp_time_adu_4 {
        pkt.extract(hdr.bpv7_creation_timestamp_time_adu_4);
        transition parse_bpv7_lifetime_time;
    }
    state parse_bpv7_creation_timestamp_time_adu_5 {
        pkt.extract(hdr.bpv7_creation_timestamp_time_adu_5);
        transition parse_bpv7_lifetime_time;
    }


    state parse_bpv7_lifetime_time {
        pkt.extract(hdr.bpv7_lifetime_time_ind);
        transition select(hdr.bpv7_lifetime_time_ind.mt, hdr.bpv7_lifetime_time_ind.vt) {
            // (3w0, 5w0 .. 5w23) :  parse_crc;
            (3w0, 5w24) : parse_bpv7_lifetime_time_8bit;
            (3w0, 5w25) : parse_bpv7_lifetime_time_16bit;
            (3w0, 5w26) : parse_bpv7_lifetime_time_32bit;
            (3w0, 5w27) : parse_bpv7_lifetime_time_64bit;
            (3w0, _) :    parse_crc;
        }
    }
    state parse_bpv7_lifetime_time_8bit {
        pkt.extract(hdr.bpv7_lifetime_time_8bit);
        transition parse_crc;
    }
    state parse_bpv7_lifetime_time_16bit {
        pkt.extract(hdr.bpv7_lifetime_time_16bit);
        transition parse_crc;
    }
    state parse_bpv7_lifetime_time_32bit {
        pkt.extract(hdr.bpv7_lifetime_time_32bit);
        transition parse_crc;
    }
    state parse_bpv7_lifetime_time_64bit {
        pkt.extract(hdr.bpv7_lifetime_time_64bit);
        transition parse_crc;
    }
    state parse_bpv7_lifetime_time_72bit {
        pkt.extract(hdr.bpv7_lifetime_time_72bit);
        transition parse_crc;
    }

    state parse_crc {
        pkt.extract(hdr.bpv7_crc_ind);
        transition select(hdr.bpv7_crc_ind.crc) {
          0x42 : extract_bpv7_16_bit_crc;
          0x44 : extract_bpv7_32_bit_crc;
          default: parse_end_of_primary_block;
        }
    }

    state extract_bpv7_16_bit_crc {
        pkt.extract(hdr.bpv7_crc_16_bit);
        transition parse_end_of_primary_block;
    }

    state extract_bpv7_32_bit_crc {
        pkt.extract(hdr.bpv7_crc_32_bit);
        transition parse_end_of_primary_block;
    }

    // this is to direct all outgoing through one state
    state parse_end_of_primary_block {
       // transition parse_bpv7_prev_block_init_bytes;
      transition parse_v7_prev_node_block;
    }// }

    // ////       END PRIMARY BLOCK PARSING    ////



    // ////       END PRIMARY BLOCK PARSING    ////
    // ////   BEGIN EXTENSION BLOCK PROCESSING ////


    state parse_v7_prev_node_block {
            pkt.extract(hdr.bpv7_extension_prev_node);
            transition parse_v7_ecos_block;
    }


    state parse_v7_ecos_block {
            pkt.extract(hdr.bpv7_extension_ecos);
            transition parse_v7_age_block;
    }

    state parse_v7_age_block {

            transition parse_age_block_init_bytes;
    }

    state parse_v7_payload_header {
            pkt.extract(hdr.bpv7_payload);
            transition select(hdr.bpv7_payload.adu_initial_byte) {
                    1 &&& CBOR_MASK_AI: parse_v7_adu_1;
                    2 &&& CBOR_MASK_AI: parse_v7_adu_2;
                    3 &&& CBOR_MASK_AI : parse_v7_adu_3;
                    4 &&& CBOR_MASK_AI : parse_v7_adu_4;
                    5 &&& CBOR_MASK_AI : parse_v7_adu_5;
                    6 &&& CBOR_MASK_AI : parse_v7_adu_6;
                    7 &&& CBOR_MASK_AI : parse_v7_adu_7;
                    8 &&& CBOR_MASK_AI : parse_v7_adu_8;
                    9 &&& CBOR_MASK_AI : parse_v7_adu_9;
                    10 &&& CBOR_MASK_AI : parse_v7_adu_10;
                    11 &&& CBOR_MASK_AI : parse_v7_adu_11;
                    12 &&& CBOR_MASK_AI : parse_v7_adu_12;
                    13 &&& CBOR_MASK_AI : parse_v7_adu_13;
                    _ : accept;
            }
    }

    state parse_v7_adu_1 {
            pkt.extract(hdr.adu_1);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_2 {
            pkt.extract(hdr.adu_2);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_3 {
            pkt.extract(hdr.adu_3);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_4 {
            pkt.extract(hdr.adu_4);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_5 {
            pkt.extract(hdr.adu_5);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_6 {
            pkt.extract(hdr.adu_6);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_7 {
            pkt.extract(hdr.adu_7);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_8 {
            pkt.extract(hdr.adu_8);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_9 {
            pkt.extract(hdr.adu_9);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_10 {
            pkt.extract(hdr.adu_10);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_11 {
            pkt.extract(hdr.adu_11);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_12 {
            pkt.extract(hdr.adu_12);
            transition parse_v7_stop_code;
    }

    state parse_v7_adu_13 {
            pkt.extract(hdr.adu_13);
            transition parse_v7_stop_code;
    }

    state parse_v7_stop_code {
            pkt.extract(hdr.bpv7_stop_code);
        transition accept;
    }


}

/***    Ingress Match-Action   ***/
control Ingress(inout headers_t                          hdr,
                // inout headers_t                          test_hdr,
		inout metadata_headers_t                         meta,
		in ingress_intrinsic_metadata_t                  ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t      ig_prsr_md,
		inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
		inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
	// For TTL testing
	bit<8> ret = 0;
	action checksum_upd_ipv4(bool update) {
		meta.checksum_upd_ipv4 = update;
	}
	action checksum_upd_udp(bool update) {
		meta.checksum_upd_udp = update;
	}
	action send(PortId_t port) {
		ig_tm_md.ucast_egress_port = port; // egress port for unicast packets. must be presented to TM for unicast
		#ifdef BYPASS_EGRESS
			ig_tm_md.bypass_egress = 1; // request flag for the warp mode (egress bypass)
		#endif
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
			#ifdef ONE_STAGE
				@defaultonly NoAction;
			#endif
		}
	#ifdef ONE_STAGE
		const default_action = NoAction();
	#endif
		size = 65536;
	}
	apply {
		ig_dprsr_md.digest_type = DIGEST_TYPE_DEBUG; // Telling deparser that it will receive debugging digests
	// Note: ttl field is used for debugging purposes. Can determine what headers were parsed correctly by examining output packet's ttl field.
	if (hdr.ipv4.isValid()) {
		    hdr.ipv4.ttl = 1;
			ret = 8w1;
		if (hdr.udp.isValid()) {
			hdr.ipv4.ttl = 2;
			ret = 8w2;
       }
	}
	if (meta.incomingV6) {
		hdr.ipv4.ttl = 99;
	} else {
		hdr.ipv4.ttl = ret;
	}
	checksum_upd_udp(true); // Always update udp checksum
	checksum_upd_ipv4(true); // Always update ipv4 checksum
	ipv4_host.apply();

#if TEST_ID == 1
	// TEST 1
	meta.debug_metadata.initial_byte              =  hdr.age_initial_byte.age_field_1;
	meta.debug_metadata.block_type                =  hdr.age_type_ind.age_field_2;
	meta.debug_metadata.block_num                 =  hdr.age_num_ind.age_field_3;
	meta.debug_metadata.block_flags               =  hdr.age_flags_ind.age_field_4;
	meta.debug_metadata.crc_type                  =  hdr.age_crc_ind.age_field_5;
	meta.debug_metadata.block_data_initial_byte   =  hdr.age_data_ind.age_field_6;
	meta.debug_metadata.bundle_age                =  hdr.age_data_08_bits.age_field_7;

#elif TEST_ID == 2
	// TEST 2
	meta.debug_metadata.initial_byte              =  hdr.b7_age_header.age_field_1;
	meta.debug_metadata.block_type                =  hdr.b7_age_header.age_field_2;
	meta.debug_metadata.block_num                 =  hdr.b7_age_header.age_field_3;
	meta.debug_metadata.block_flags               =  hdr.b7_age_header.age_field_4;
	meta.debug_metadata.crc_type                  =  hdr.b7_age_header.age_field_5;
	meta.debug_metadata.block_data_initial_byte   =  hdr.b7_age_header.age_field_6;
	meta.debug_metadata.bundle_age                =  hdr.b7_age_header.age_field_7;

#elif TEST_ID == 3
	//TEST 3
	meta.debug_metadata.initial_byte              =  hdr.b7_age_header.age_field_1;
	meta.debug_metadata.block_type                =  hdr.b7_age_header.age_field_2;
	meta.debug_metadata.block_num                 =  hdr.b7_age_header.age_field_3;
	meta.debug_metadata.block_flags               =  hdr.b7_age_header.age_field_4;
	meta.debug_metadata.crc_type                  =  hdr.b7_age_header_2.age_field_5;
	meta.debug_metadata.block_data_initial_byte   =  hdr.b7_age_header_2.age_field_6;
	meta.debug_metadata.bundle_age                =  hdr.b7_age_header_2.age_field_7;

#elif TEST_ID == 4
	// TEST 4
	meta.debug_metadata.initial_byte              =  hdr.b7_age_header.age_field_1;
	meta.debug_metadata.block_type                =  hdr.b7_age_header.age_field_2;
	meta.debug_metadata.block_num                 =  hdr.b7_age_header.age_field_3;
	meta.debug_metadata.block_flags               =  hdr.b7_age_header_2.age_field_4;
	meta.debug_metadata.crc_type                  =  hdr.b7_age_header_2.age_field_5;
	meta.debug_metadata.block_data_initial_byte   =  hdr.b7_age_header_3.age_field_6;
	meta.debug_metadata.bundle_age                =  hdr.b7_age_header_3.age_field_7;
#else
#error "Unknown TEST_ID"
#endif
 }
}

/***    Ingress Deparser   ***/
control IngressDeparser(packet_out                        pkt,
			inout headers_t                               hdr,
     // inout headers_t                                 test_hdr,
			in metadata_headers_t                         meta,
			in ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
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
		if (meta.checksum_upd_udp) {
		}
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
parser EgressParser(packet_in                       pkt,
					out egress_headers_t            hdr,
        //  out  egress_headers_t           test_hdr,
					out egress_metadata_t           meta,
					out egress_intrinsic_metadata_t eg_intr_md)
{
	state start {
		pkt.extract(eg_intr_md);
		transition accept;
	}
}
/***    Egress Match-Action   ***/
control Egress(
		inout egress_headers_t                            hdr,
   		inout egress_metadata_t                           meta,
		in egress_intrinsic_metadata_t                    eg_intr_md,
		in egress_intrinsic_metadata_from_parser_t        eg_prsr_md,
		inout egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md,
		inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
	apply {
	}
}
/***    Egress Deparser   ***/
control EgressDeparser(packet_out                           pkt,
				inout egress_headers_t                      hdr,
				in egress_metadata_t                        meta,
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

