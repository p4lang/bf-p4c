/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#include "headers.p4"
#include "types.p4"

//-----------------------------------------------------------------------------
// Pktgen parser
//-----------------------------------------------------------------------------
parser PktgenParser<H>(packet_in pkt,
                       inout switch_header_t hdr,
                       inout H md) {
    state start {
#ifdef PKTGEN_ENABLE
        transition parse_pktgen;
#else
        transition reject;
#endif
    }

    state parse_pktgen {
        transition reject;
    }
}

//-----------------------------------------------------------------------------
// MPLS parser
//-----------------------------------------------------------------------------
parser MplsParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
#ifdef MPLS_ENABLE
        transition parse_mpls;
#else
        transition reject;
#endif
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            1 : accept;
            0 : parse_mpls;
        }
    }
}

//-----------------------------------------------------------------------------
// Inband network telemetry parser
//-----------------------------------------------------------------------------
parser DTelParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
        transition reject;
    }
}

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SrhParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
#ifdef SRV6_ENABLE
        transition parse_srh;
#else
        transition reject;
#endif
    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition reject;
    }
}



//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
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
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        transition parse_packet;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            ETHERTYPE_FCOE : parse_fcoe;
            ETHERTYPE_BFN  : parse_cpu;
            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, _, _) : parse_ipv4_no_options;
            (6, _, _) : parse_ipv4_options;
            default : accept;
            //TODO (ipv4.ihl > 6)
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.opaque_option);
        // ipv4_checksum.add(hdr.opaque_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMP : parse_icmp;
            IP_PROTOCOLS_IGMP : parse_igmp;
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_IPV4 : parse_ipinip;
            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_icmp;
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_IPV4 : parse_ipinip;
            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
#else
        transition reject;
#endif
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_VXLAN : parse_vxlan;
            UDP_PORT_ROCEV2 : parse_rocev2;
	        default : accept;
	    }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }

    state parse_rocev2 {
#ifdef ROCEV2_ACL_ENABLE
        pkt.extract(hdr.rocev2_bth);
#else
        transition accept;
#endif
    }

    state parse_fcoe {
#ifdef FCOE_ACL_ENABLE
        pkt.extract(hdr.fcoe_fc);
#else
        transition accept;
#endif
    }

    state parse_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;
#else
        transition accept;
#endif
    }

    state parse_ipinip {
#ifdef IPINIP
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
#else
        transition accept;
#endif
    }

    state parse_ipv6inip {
#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
#else
        transition accept;
#endif
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_ICMP : parse_inner_icmp;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_TUNNEL_ENABLE
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_inner_icmp;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
#else
        transition reject;
#endif
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

}

//=============================================================================
// Egress parser
//=============================================================================
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
#ifdef MIRROR_ENABLE
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGE, _) : parse_bridged_metadata;
            (_, SWITCH_MIRROR_TYPE_PORT) : parse_port_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONE_EGRESS, SWITCH_MIRROR_TYPE_CPU) : parse_cpu_mirrored_metadata;
        }
#else
        transition parse_bridged_metadata;
#endif
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGE;
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.nexthop;
        eg_md.qos.tc = hdr.bridged_md.tc;
        eg_md.cpu_reason = hdr.bridged_md.cpu_reason;
        eg_md.flags.routed = (bool) hdr.bridged_md.routed;
        eg_md.flags.peer_link = (bool) hdr.bridged_md.peer_link;
        eg_md.flags.capture_ts = (bool) hdr.bridged_md.capture_ts;
        eg_md.tunnel.terminate = (bool) hdr.bridged_md.tunnel_terminate;
        eg_md.pkt_type = hdr.bridged_md.pkt_type;
        eg_md.timestamp = hdr.bridged_md.timestamp;
        eg_md.qos.qid = hdr.bridged_md.qid;

#ifdef EGRESS_ACL_ENABLE
        eg_md.l4_port_label = hdr.bridged_md.l4_port_label;
#endif

#ifdef TUNNEL_ENABLE
        pkt.extract(hdr.bridged_tunnel_md);
        eg_md.outer_nexthop = hdr.bridged_tunnel_md.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_tunnel_md.index;
        eg_md.tunnel.hash = hdr.bridged_tunnel_md.hash;
#endif
        // Set bridged metadata here.

        transition parse_ethernet;
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h md;
        pkt.extract(md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = md.src;
#if __TARGET_TOFINO__ == 1
        eg_md.mirror.session_id = md.session_id[9:0];
#else
        eg_md.mirror.session_id = md.session_id[7:0];
#endif
        // eg_md.mirror.session_id = (switch_mirror_session_t) md.session_id;
        eg_md.timestamp = md.timestamp;
        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h md;
        pkt.extract(md);
        eg_md.bd = (switch_bd_t) md.bd;
        // eg_md.ingress_port = (switch_port_t) md.port;
        // eg_md.ingress_ifindex = (switch_ifindex_t) md.ifindex;
        eg_md.cpu_reason = (switch_cpu_reason_t) md.reason_code;
        transition accept;
    }


    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }


    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, _, _) : parse_ipv4_no_options;
            (6, _, _) : parse_ipv4_options;
            default : accept;
            //TODO (ipv4.ihl > 6)
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.opaque_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol) {
            // IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
#ifdef IPINIP
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
#endif
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            // IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
#endif
            default : accept;
        }
#else
        transition reject;
#endif
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_VXLAN : parse_vxlan;
	        default : accept;
	    }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
#else
        transition reject;
#endif
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_TUNNEL_ENABLE
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
#else
        transition reject;
#endif
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }
}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend
// the prepend the mirror header.
    Mirror() mirror;

    apply {
#ifdef MIRROR_ENABLE
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            hdr.mirror.port.src = ig_md.mirror.src;
            hdr.mirror.port.type = ig_md.mirror.type;
            hdr.mirror.port.timestamp = ig_md.timestamp;
            // hdr.mirror.port.session_id = (bit<16>) ig_md.mirror.session_id;
            mirror.emit(ig_md.mirror.session_id, hdr.mirror.port);
        }
#endif
    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the
// mirror header.
    Mirror() mirror;

    apply {
#ifdef MIRROR_ENABLE
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            hdr.mirror.port.src = eg_md.mirror.src;
            hdr.mirror.port.type = eg_md.mirror.type;
            hdr.mirror.port.timestamp = eg_md.timestamp;
            // hdr.mirror.port.session_id = (bit<16>) eg_md.mirror.session_id;
            mirror.emit(eg_md.mirror.session_id, hdr.mirror.port);
        }

        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
            hdr.mirror.cpu.src = eg_md.mirror.src;
            hdr.mirror.cpu.type = eg_md.mirror.type;
            // hdr.mirror.cpu.port = (bit<16>)eg_intr_md.port;
            hdr.mirror.cpu.bd = eg_md.bd;
            // hdr.mirror.cpu.eg_md.ifindex
            hdr.mirror.cpu.reason_code = eg_md.cpu_reason;
            mirror.emit(eg_md.mirror.session_id, hdr.mirror.cpu);
        }
#endif
    }
}

//=============================================================================
// Ingress Deparser
//=============================================================================
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() ingress_mirror;
    Digest<switch_learning_digest_t>() digest;

    apply {
        ingress_mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING)
        {
            digest.pack({ig_md.learning.digest.bd,
                         ig_md.learning.digest.ifindex,
                         ig_md.learning.digest.src_addr});
        }

        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.bridged_tunnel_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.opaque_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        egress_mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
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
            // hdr.opaque_option.type,
            // hdr.opaque_option.length,
            // hdr.opaque_option.value});

#ifdef TUNNEL_ENABLE
        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.total_len,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.src_addr,
            hdr.inner_ipv4.dst_addr});
#endif

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        // pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        // pkt.emit(hdr.inner_tcp);
    }
}
