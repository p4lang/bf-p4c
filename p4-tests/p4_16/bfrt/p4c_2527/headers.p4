/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------

#ifndef _P4_HEADERS_
#define _P4_HEADERS_

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

@pa_container_size("ingress", "hdr.transport.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.outer.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.inner.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.$valid", 16)
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos;
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

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

#ifdef IPV6_ENABLE
  header ipv6_h {
      bit<4> version;
      bit<8> tos;
      bit<20> flow_label;
      bit<16> payload_len;
      bit<8> next_hdr;
      bit<8> hop_limit;
#ifdef BUG_10439_WORKAROUND
      bit<32> src_addr_3;
      bit<32> src_addr_2;
      bit<32> src_addr_1;
      bit<32> src_addr_0;
      bit<32> dst_addr_3;
      bit<32> dst_addr_2;
      bit<32> dst_addr_1;
      bit<32> dst_addr_0;
#else
      ipv6_addr_t src_addr;
      ipv6_addr_t dst_addr;
#endif // BUG_10439_WORKAROUND
}
#endif  /* IPV6_ENABLE */

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R; // deprecated in RFC 2784
    bit<1> K; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> S; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> s; // deprecated in RFC 2784
    bit<3> recurse; // deprecated in RFC 2784
    bit<5> flags;   // deprecated in RFC 2784
    bit<3> version;
    bit<16> proto;
}

header gre_extension_sequence_h {
    bit<32> seq_num;
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

#if defined(ERSPAN_INGRESS_ENABLE) || defined(ERSPAN_EGRESS_ENABLE)

  // ERSPAN Type II -- IETFv3
  header erspan_type2_h {
      bit<4> version;
      bit<12> vlan;
      bit<6> cos_en_t;
      bit<10> session_id;
      bit<12> reserved;
      bit<20> index;
  }
  
  // ERSPAN Type III -- IETFv3
  header erspan_type3_h {
      bit<4> version;
      bit<12> vlan;
      bit<6> cos_bso_t;
      bit<10> session_id;
      bit<32> timestamp;
      bit<16> sgt;    // Security group tag
      bit<1>  p;
      bit<5> ft;      // Frame type
      bit<6> hw_id;
      bit<1> d;       // Direction
      bit<2> gra;     // Timestamp granularity
      bit<1> o;       // Optional sub-header
  }
  
  // ERSPAN platform specific subheader -- IETFv3
  header erspan_platform_h {
      bit<6> id;
      bit<58> info;
  }

#endif /* defined(ERSPAN_INGRESS_ENABLE) || defined(ERSPAN_EGRESS_ENABLE) */

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Extreme Networks - Added
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

#define SAP_ID_WIDTH                    16
#define VPN_ID_WIDTH                    16
#define FLOW_CLASS_WIDTH                 8
#define SRVC_FUNC_CHAIN_WIDTH            8
#define SRVC_FUNC_CHAIN_DATA_WIDTH      16
#define UDF_WIDTH                       88  // 11B

//////////////////////////////////////////////////////////////
// Transport Headers
//////////////////////////////////////////////////////////////

header ethernet_tagged_h {  // for snooping
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;

    bit<3> tag_pcp;
    bit<1> tag_cfi;
    vlan_id_t tag_vid;
    bit<16> ether_type_tag;
}

//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header (word 0, base word 0)
header nsh_base_h {
    bit<2>                     version;
    bit<1>                     o;
    bit<1>                     reserved;
    bit<6>                     ttl;
    bit<6>                     len; // in 4-byte words
    bit<4>                     reserved2;
    bit<4>                     md_type;
    bit<8>                     next_proto;
}

// NSH Service Path Header (word 1, base word 1)
header nsh_svc_path_h {
    bit<24>                    spi;
    bit<8>                     si;
}

// NSH MD Type1 (Fixed Length) Context Header (word 2, ext type 1 words 0-3)
header nsh_md1_context_h {
    bit<128>                   md;
}

// fixed sized version of this is needed for lookahead (word 2, ext type 2 word 0)
header nsh_md2_context_fixed_h {
    bit<16>                    md_class;
    bit<8>                     type;
    bit<1>                     reserved;
    bit<7>                     len;
}

// Single, Fixed Sized Extreme NSH Header (external)
header nsh_type1_h {
    // word 0: base word 0
    bit<2>                          version;
    bit<1>                          o;
    bit<1>                          reserved;
    bit<6>                          ttl;
    bit<6>                          len; // in 4-byte words
    bit<4>                          reserved2;
    bit<4>                          md_type;
    bit<8>                          next_proto;

	// --------------------

    // word 1: base word 1
    bit<24>                         spi;
    bit<8>                          si;

	// --------------------

    // word 2: ext type 1 word 0-3
	bit<8>                          ver;       // word 0
	bit<8>                          scope;     // word 0
//	bit<6>                          reserved3; // word 0
	bit<SAP_ID_WIDTH>               sap;       // word 0

	bit<VPN_ID_WIDTH>               vpn;       // word 1
	bit<SRVC_FUNC_CHAIN_DATA_WIDTH> sfc_data;  // word 1

	bit<32>                         reserved4; // word 2

	bit<32>                         timestamp; // word 3
}

// Single, Fixed Sized Extreme NSH Header (internal)
struct nsh_type1_internal_lkp_t {
	// ANY NSH METADATA THAT IS COLLECTED ABOUT THE PACKET GOES HERE.

    bool                            hdr_is_new;             // ingress / egress
    bit<3>                          sf_bitmask;             // ingress / egress

    bool                            sfc_is_new;             // ingress only
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc;                    // ingress only
    bit<FLOW_CLASS_WIDTH>           flow_class;             // ingress only
	bool                            l2_fwd_en;              // ingress only

	bit<SAP_ID_WIDTH>               dsap;                   // egress only
	bool                            strip_e_tag;            // egress only
	bool                            strip_vn_tag;           // egress only
	bool                            strip_vlan_tag;         // egress only
	bool                            truncate;               // egress only
	bit<14>                         truncate_len;           // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

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
    bit<16> src_port;
    bit<16> dst_port;
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
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<UDF_WIDTH> opaque;
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
    bit<32> teid;
}

header gtp_v2_base_h {
    bit<3>  version;
    bit<1>  P;
    bit<1>  T;
    bit<3>  reserved;
    bit<8>  msg_type;
    bit<16> msg_len;
    bit<32> teid;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8>  n_pdu_num;
    bit<8>  next_ext_hdr_type;
}

/*
header gtp_v1_extension_h {
    bit<8> ext_len;
    varbit<8192> contents;
    bit<8> next_ext_hdr;
}
*/

//////////////////////////////////////////////////////////////
// Lookahead/Snoop Headers
//////////////////////////////////////////////////////////////

header head_snoop_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 4B + 10B = 28B

#endif /* _P4_HEADERS_ */
