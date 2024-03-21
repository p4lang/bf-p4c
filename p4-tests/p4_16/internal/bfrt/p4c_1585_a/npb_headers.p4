

#ifndef _NPB_HEADERS_
#define _NPB_HEADERS_


//////////////////////////////////////////////////////////////
// Underlay Headers
//////////////////////////////////////////////////////////////

header ethernet_tagged_h {  // for snooping
    mac_addr_t ether_dst_addr;
    mac_addr_t ether_src_addr;
    bit<16> ether_type;

    bit<3> tag_pcp;
    bit<1> tag_cfi;
    vlan_id_t tag_vid;
    bit<16> ether_type_tag;
}


//-----------------------------------------------------------
// ERSPAN
//-----------------------------------------------------------

// Barefoot ERSPAN Type2 header is missing the sequence
// number (which means it looks like ERSPAN Type1).
// Barefoot only uses this in the egress deparser.
// Let's redefine Type1 and Type2 here correctly and use
// these for parsing.

// ERSPAN Type1 -- IETFv3
header erspan_type1_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type2 -- IETFv3
header erspan_type2_h {
    bit<32> seq_num;
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// Barefoot ERSPAN Type3 header is incomplete. Let's
// redefine it here (and use this one instead).

// ERSPAN Type3 -- IETFv3
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt;        // Security group tag
    bit<1> p;
    bit<5> ft;          // Frame type
    bit<6> hw_id;
    bit<1> d;           // Direction
    bit<2> gra;         // Timestamp granularity
    bit<1> o;           // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}


//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header
header nsh_base_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
}

// NSH Service Path Header
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header
header nsh_md1_context_h {
    bit<128> md;
}

/*
// NSH MD Type2 (Variable Length) Context Header(s)
header nsh_md2_context_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
    varbit<1024> md; // (2^7)*8
}
*/

// fixed sized version of this is needed for lookahead
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header
header nsh_extr_h {
	// base: word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

	// base: word 1
    bit<24> spi;
    bit<8> si;

	// ext: type 2 - word 0
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved3;
    bit<7> md_len;

	// ext: type 2 - word 1+
	bit<8>               extr_srvc_func_bitmask; //  1 byte
	bit<TENANT_ID_WIDTH> extr_tenant_id;         //  3 bytes
	bit<FLOW_TYPE_WIDTH> extr_flow_type;         //  1 byte?

//  bit<160> md_extr; // 20Byte fixed Extreme MD
//  bit<120> md_extr; // 20Byte fixed Extreme MD
}

// Single, Fixed Sized Extreme NSH Header
struct nsh_extr_internal_lkp_t {
	// metadata
    bit<1>               valid;        // set by sfc or incoming packet
    bit<1>               end_of_chain; // set by sff

	// base: word 0

	// base: word 1
    bit<24> spi;
    bit<8>  si;

	// ext: type 2 - word 0

	// ext: type 2 - word 1+
	bit<8>               extr_srvc_func_bitmask_local;  //  1 byte
	bit<8>               extr_srvc_func_bitmask_remote; //  1 byte
	bit<TENANT_ID_WIDTH> extr_tenant_id;                //  3 bytes
	bit<FLOW_TYPE_WIDTH> extr_flow_type;                //  1 byte?
}



//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////

header e_tag_h {
    bit<3>  pcp;
    bit<1>  dei;
    bit<12> ingress_cid_base;
    bit<2>  rsvd_0;
    bit<2>  grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}

header vn_tag_h {
    bit<1>  dir;
    bit<1>  ptr;
    bit<14> dvif_id;
    bit<1>  loop;
    bit<3>  rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}








//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header sctp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}



//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4>   zeros;
    bit<12>  rsvd;
    bit<16>  seqNum;
}


//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// IPsec - ESP
//-----------------------------------------------------------

header esp_h {
    bit<32> spi;
    bit<32> seq_num;
}


//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------

header gtp_v1_base_h {
    bit<3>  version;
    bit<1>  PT;
    bit<1>  reserved;
    bit<1>  E;
    bit<1>  S;
    bit<1>  PN;
    bit<8>  msg_type;
    bit<16> msg_len;
    bit<32> TEID;
}

header gtp_v1_optional_h {
    bit<16>  seq_num;
    bit<8>   n_pdu_num;
    bit<8>   next_ext_hdr_type;
}

/*
header gtp_v1_extension_h {
    bit<8> ext_len;
    varbit<8192> contents;
    bit<8> next_ext_hdr;
}
*/

#endif  /* _NPB_HEADERS_ */
