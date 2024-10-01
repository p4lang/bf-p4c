/*******************************************************************************
 * MNK LABS & CONSULTING CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2020-present MNK Labs & Consulting, LLC.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * MNK Labs & Consulting, LLC. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to
 * MNK Labs & Consulting, LLC. and its suppliers and may be covered by U.S.
 * and Foreign Patents, patents in process, and are protected by trade secret
 * or copyright law.  Dissemination of this information or reproduction of
 * this material is strictly forbidden unless prior written permission is
 * obtained from MNK Labs & Consulting, LLC.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with MNK Labs & Consulting, LLC.
 *
 * 5G Cellular User Plane Function (UPF) in bridged mode.
 *
 * upf_bridged.p4
 *
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#define MAX_MPLS 6

typedef bit<16> ifindex_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

const bit<16> ETHERTYPE_IPV4 = 16w0x0800;
const bit<16> ETHERTYPE_IPV6 = 16w0x86DD;
const bit<8> IP_PROTOCOLS_TCP = 6;
const bit<8> IP_PROTOCOLS_UDP = 17;
const bit<8> IP_PROTOCOLS_AH = 51;
const bit<8> IP_PROTOCOLS_EHS = 50;
const bit<8> IP_PROTOCOLS_SCTP = 132;


struct empty_header_t {}
struct empty_metadata_t {}

enum bit<8> tunnelTypes {
    NO_TUN     = 8w0,
    IPVX_IN_IP = 8w1,
    GTP        = 8w2,
    MPLS_VX    = 8w4
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header license_t {
    bit<16>  msg;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffServ;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    bit<32>     srcAddr;
    bit<32>     dstAddr;
    varbit<320> options;
}

header ipv6_t {
    bit<4>      version;
    bit<8>      trafficClass;
    bit<20>     flowLabel;
    bit<16>     payloadLen;
    bit<8>      nextHdr;
    bit<8>      hopLimit;
    bit<128>    srcAddr;
    bit<128>    dstAddr;
}

header sctp_t {
    bit<16>     srcPort;
    bit<16>     dstPort;
    bit<32>     verifTag;
    bit<32>     checksum;
}

header tcp_t {
    bit<16>     srcPort;
    bit<16>     dstPort;
    bit<32>     seqNo;
    bit<32>     ackNo;
    bit<4>      dataOffset;
    bit<4>      res;
    bit<8>      flags;
    bit<16>     window;
    bit<16>     checksum;
    bit<16>     urgentPtr;
    varbit<320> options;
}

header udp_t {
    bit<16>     srcPort;
    bit<16>     dstPort;
    bit<16>     length_;
    bit<16>     checksum;
}

header mpls_t {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

// GTP message format
header gtpv01_t {
    bit<3>  ver;
    bit<1>  pt;
    bit<1>  reserved;
    bit<1>  e;
    bit<1>  s;        
    bit<1>  pn;
    bit<8>  mesgType;
    bit<16> mesgLen;
    bit<32> teid;
}

header gtpv01_opt_fields_t {
    bit<16> seqnum;
    bit<8>  npdu;
    bit<8>  next_hdr;
    bit<8>  extLen;
    bit<16> contents;
    bit<8>  nextExtHdr;
}

header ah_t { // IPSec Authentication Header
    bit<8>  nextHdr;
    bit<8>  payloadLen;
    bit<16> resvd;
    bit<32> spi;
    bit<32> seqNo;
    bit<32> icv;
}

header esp_t { // IPSec Encapsulating Security Payload
    bit<32>      spi;
    bit<32>      seqNo;
}


header bridged_metadata_t {
    // TODO: user-defined metadata carried over from ingress to egress.
    ifindex_t eg_id;
}

header IPv4_up_to_ihl_only_h {
    bit<4>       version;
    bit<4>       ihl;
}

header tcp_upto_data_offset_only_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    // dataOffset in TCP hdr uses 4 bits but needs padding.
    // If 4 bits are used for it, p4c-bm2-ss complains the header
    // is not a multiple of 8 bits.
    bit<4>  dataOffset;
    bit<4>  dontCare;
}

header esp_upto_fixed_only_h {
    bit<32> spi; // Security Parameters Index
    bit<32> seqNo;
}

struct headers_t {
    bridged_metadata_t                      bridged_md;
    ethernet_t                              ethernet;
    mpls_t[MAX_MPLS]                        mpls;    
    license_t                               lic;
    ipv4_t                                  ipv4;
    ipv6_t                                  ipv6;
    udp_t                                   udp;
    tcp_t                                   tcp;
    sctp_t                                  sctp;
    ah_t                                    ah;
    esp_t                                   esp;
    gtpv01_t                                gtpv01_hdr;
    gtpv01_opt_fields_t                     gtpv01_opts;
    ethernet_t                              inner_ethernet;
    ipv4_t                                  inner_ipv4;
    ipv6_t                                  inner_ipv6;
    udp_t                                   inner_udp;
    tcp_t                                   inner_tcp;
    sctp_t                                  inner_sctp;
}


parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

struct tunnel_metadata_t {
    bit<8>  ingress_tunnel_type;
}

// TODO: add application id for SDF
struct acl_metadata_t {
    bit<1> deny;
    bit<1> permit;
    bit<1> log;
    bit<1> auth;
    bit<1> mirror;
    bit<1> chk_credit;
    bit<1> chk_max_bw_exceed;
    bit<1> policer_color;
    bit<1> block;
    bit<7> pad;
}

struct chksum_metadata_t {
    bit<16>     l4Len; // includes TCP hdr len + TCP payload len in bytes.
    bit<16> checksum_ipv4_tmp;
    bit<16> checksum_ipv6_tmp;
    bit<16> checksum_tcp_tmp;
    bit<16> checksum_sctp_tmp;
    bit<16> checksum_udp_tmp;

    bool checksum_upd_ipv4;
    bool checksum_upd_ipv6;
    bool checksum_upd_tcp;
    bool checksum_upd_sctp;
    bool checksum_upd_udp;

    bool checksum_err_ipv4_igprs;
    bool checksum_err_ipv6_igprs;
    bool checksum_err_tcp_igprs;
}

@pa_auto_init_metadata() struct metadata_t {
    tunnel_metadata_t tunnel;
    chksum_metadata_t chksum;
    acl_metadata_t    acl;
}

// Declare user-defined errors that may be signaled during parsing
error {
    IPv4HeaderTooShort,
    TCPHeaderTooShort,
    IPv4IncorrectVersion,
    IPv4ChecksumError
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t meta,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() sctp_checksum;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4 : parse_ipv4;
	    ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_gtpv01_hdr {
        pkt.extract(hdr.gtpv01_hdr);
        transition select(hdr.gtpv01_hdr.e) {
            1w0: parse_gtp_payload;
            default: parse_gtpv01_opts;
        }
    }

    state parse_gtpv01_opts {
        pkt.extract(hdr.gtpv01_opts);
        transition parse_gtp_payload;
    }

    state parse_gtp_payload {
        bit<4> version = pkt.lookahead<bit<4>>();
        meta.tunnel.ingress_tunnel_type = (bit<8>)tunnelTypes.GTP;
        transition select(version) {
            4w4: parse_inner_ipv4;
            4w6: parse_inner_ipv6;
            default: reject;
        }
    }

    state parse_ipv4 {
        // The 4-bit IHL field of the IPv4 base header is the number
        // of 32-bit words in the entire IPv4 header.  It is an error
        // for it to be less than 5.  There are only IPv4 options
        // present if the value is at least 6.  The length of the IPv4
        // options alone, without the 20-byte base header, is thus ((4
        // * ihl) - 20) bytes, or 8 times that many bits.
        pkt.extract(hdr.ipv4,
                    (bit<32>)
                    (8 *
                    (bit<32>)(4 * (bit<9>) (pkt.lookahead<IPv4_up_to_ihl_only_h>().ihl)
                    - 20)));
//       TODO: Not supported by bf-p4c.
//        verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
//        verify(hdr.ipv4.ihl >= 4w5, error.IPv4HeaderTooShort);
        // TODO meta.chksum.l4Len = hdr.ipv4.totalLen - (bit<16>)(hdr.ipv4.ihl)*4;
        ipv4_checksum.add(hdr.ipv4);
        meta.chksum.checksum_err_ipv4_igprs = ipv4_checksum.verify();

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP  : parse_tcp;
            IP_PROTOCOLS_UDP  : parse_udp;
            IP_PROTOCOLS_SCTP : parse_sctp;
            IP_PROTOCOLS_EHS  : parse_esp;
            IP_PROTOCOLS_AH   : parse_ah;
            default : accept;
        }
    }

    state parse_ah {
        pkt.extract(hdr.ah);
	transition accept;
    }

    // TODO: ESP can be combined with AH
    state parse_esp {
        pkt.extract(hdr.esp);
	transition accept;
    }

    state parse_tcp {
        // The tcp checksum cannot be verified, since we cannot compute
        // the payload's checksum.

        // The 4-bit dataOffset field of the TCP base header is the number
        // of 32-bit words in the entire TCP header.  It is an error
        // for it to be less than 5.  There are only TCP options
        // present if the value is at least 6.  The length of the TCP
        // options alone, without the 20-byte base header, is thus ((4
        // * dataOffset) - 20) bytes, or 8 times that many bits.
        // verify(hdr.tcp.dataOffset >= 4w5, error.TCPHeaderTooShort);
        pkt.extract(hdr.tcp,
                    (bit<32>)
                    (8 *
                    (bit<32>)(4 * (bit<9>) (pkt.lookahead<tcp_upto_data_offset_only_h>().dataOffset)
                    - 20)));
        tcp_checksum.add({hdr.tcp});
        meta.chksum.checksum_err_tcp_igprs = tcp_checksum.verify();
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w2152: parse_gtpv01_hdr;
        }
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        sctp_checksum.add({hdr.sctp});
        transition accept;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4,
                    (bit<32>)
                    (8 *
                    (bit<32>)(4 * (bit<9>) (pkt.lookahead<IPv4_up_to_ihl_only_h>().ihl)
                    - 20)));
//       TODO: Not supported by bf-p4c.
//        verify(hdr.inner_ipv4.version == 4w4, error.IPv4IncorrectVersion);
//        verify(hdr.inner_ipv4.ihl >= 4w5, error.IPv4HeaderTooShort);
        // TODO meta.chksum.l4Len = hdr.inner_ipv4.totalLen - (bit<16>)(hdr.inner_ipv4.ihl)*4;
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_TCP  : parse_inner_tcp;
            IP_PROTOCOLS_UDP  : parse_inner_udp;
            IP_PROTOCOLS_SCTP : parse_inner_sctp;
            8w0x4             : parse_ipv4_in_ip;
            8w0x29            : parse_ipv6_in_ip;
        }
    }
    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w17: parse_inner_udp;
            8w6: parse_inner_tcp;
            8w132: parse_inner_sctp;
            8w4: parse_ipv4_in_ip;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }

    state parse_ipv4_in_ip {
        meta.tunnel.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv4;
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
            8w132: parse_sctp;
            8w4: parse_ipv4_in_ip;
            8w17: parse_udp;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv6_in_ip {
        meta.tunnel.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv6;
    }
    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            1w1: parse_mpls_bos;
            default: parse_mpls;
        }
    }
    state parse_mpls_bos {
        transition select((pkt.lookahead<bit<4>>())) {
            4w0x4: parse_ipv4;
            4w0x6: parse_ipv6;
        }
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }
    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp,
                    (bit<32>)
                    (8 *
                    (bit<32>)(4 * (bit<9>) (pkt.lookahead<tcp_upto_data_offset_only_h>().dataOffset)
                    - 20)));
        transition accept;
    }
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout headers_t hdr,
        inout metadata_t meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action outer_ipv4_strip() {
        hdr.ipv4.setInvalid();
    }
    action outer_ipv6_strip() {
        hdr.ipv6.setInvalid();
    }
    action gtp_strip() {
        hdr.gtpv01_hdr.setInvalid();
        hdr.gtpv01_opts.setInvalid();
    }

    action allow_processing() {
        // TODO
    }
    action drop() {
        ig_dprsr_md.drop_ctl = 0x1;
    }
    table pkt_filter {
        key = {
	    // Match type is ternary to use TCAM which is fast memory.
	    // TODO: IPSec SPI
	    // Maybe parse such data in parse which supports Range (..) operator
	    hdr.ipv6.srcAddr      : ternary;
	    hdr.ipv6.dstAddr      : ternary;
	    hdr.ipv6.nextHdr      : ternary; // TCP/UDP/Ext hdrs.
	    hdr.ipv6.isValid()    : ternary;
	    hdr.ipv4.srcAddr      : ternary;
	    hdr.ipv4.dstAddr      : ternary;
            hdr.ipv4.protocol     : ternary;
            hdr.ipv4.isValid()    : ternary;
	}
	actions = { drop; allow_processing; }
        const default_action = drop;
    }

    action range_processing() {
        // TODO
    }
    /* Configure this table's entry for a single
     * port or port range.
    */
    table range_filter {
        key = {
	    hdr.tcp.dstPort       : range;
	    hdr.tcp.srcPort       : range;
	    hdr.udp.dstPort       : range;
	    hdr.udp.srcPort       : range;
	    hdr.sctp.dstPort      : range;
	    hdr.sctp.srcPort      : range;
	}
	actions = { drop; range_processing; }
	const default_action = drop;
    }

    action color() {
        // TODO
    }
    table policer {
        key = {
	    hdr.ipv6.flowLabel    : ternary;
	    hdr.ipv6.trafficClass : ternary;
	    hdr.ipv6.isValid()    : ternary;
            hdr.ipv4.diffServ     : ternary; // DSCP bits for WAN traversal.
            hdr.ipv4.isValid()    : ternary;
	}
	actions = { color; }
    }

    action set_output_port(PortId_t port_id) {
        ig_tm_md.ucast_egress_port = port_id;
    }
    table output_port {
        actions = {
            set_output_port;
        }
    }

    apply {
        if ((meta.tunnel.ingress_tunnel_type >=
	    (bit<8>)tunnelTypes.IPVX_IN_IP) &&
	    (meta.tunnel.ingress_tunnel_type <
	    (bit<8>)tunnelTypes.MPLS_VX)) { // IP tunnel
	    outer_ipv4_strip();
	    outer_ipv6_strip();
            hdr.udp.setInvalid();
            hdr.tcp.setInvalid();
            hdr.sctp.setInvalid();
	    gtp_strip();
        }
        pkt_filter.apply();
        range_filter.apply();
        policer.apply();
        output_port.apply();
        // No need for egress processing, skip it and use empty controls for egress.
        ig_tm_md.bypass_egress = 1w1;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout headers_t hdr,
                              in metadata_t meta,
                              in ingress_intrinsic_metadata_for_deparser_t
                                ig_intr_dprsr_md
                              ) {

    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    // IPv6 header does not include any checksum.
    apply {
        // Updating and checking of the checksum is done in the deparser.
        // Checksumming units are only available in the parser sections of
        // the program.
        if (meta.chksum.checksum_upd_ipv4) {
            hdr.ipv4.hdrChecksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.diffServ,
                 hdr.ipv4.totalLen,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.fragOffset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.srcAddr,
                 hdr.ipv4.dstAddr,
		 hdr.ipv4.options});
        }
        if (meta.chksum.checksum_upd_tcp) {
            hdr.tcp.checksum = tcp_checksum.update({
                hdr.ipv4.srcAddr,
                hdr.tcp.srcPort,
                meta.chksum.checksum_tcp_tmp,
		hdr.tcp.options
            });
        }
        if (meta.chksum.checksum_upd_udp) {
            hdr.udp.checksum = udp_checksum.update(data = {
                hdr.ipv4.srcAddr,
                hdr.udp.srcPort,
                meta.chksum.checksum_udp_tmp
	    }, zeros_as_ones = true);
            // UDP specific checksum handling
        }

        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_sctp);
    }
}



Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       EmptyEgressParser(),  // TODO: Add non-empty controls
       EmptyEgress(),
       EmptyEgressDeparser()) pipe;

Switch(pipe) main;

