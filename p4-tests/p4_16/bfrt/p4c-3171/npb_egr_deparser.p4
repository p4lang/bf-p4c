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
 ******************************************************************************/

#include "headers.p4"
#include "types.p4"

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
#ifdef MIRROR_ENABLE
    Mirror() mirror;
#endif

    apply {
#ifdef MIRROR_ENABLE
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
  #ifdef MIRROR_EGRESS_PORT_ENABLE
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
//              eg_md.ingress_timestamp,
    #if __TARGET_TOFINO__ == 1
                0,
    #endif
                eg_md.mirror.session_id});

  #endif
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
  #ifdef CPU_ACL_EGRESS_ENABLE
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
                eg_md.port_lag_index,
                eg_md.cpu_reason});
  #endif
        }
#endif
    }
}

//-----------------------------------------------------------------------------

control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

	EgressMirror() mirror;
#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
    Checksum() ipv4_checksum_transport;
#endif // defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
    Checksum() ipv4_checksum_outer;

    apply {
		mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);

#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
        if (hdr.transport.ipv4.isValid()) {
            hdr.transport.ipv4.hdr_checksum = ipv4_checksum_transport.update({
                hdr.transport.ipv4.version,
                hdr.transport.ipv4.ihl,
                hdr.transport.ipv4.tos,
                hdr.transport.ipv4.total_len,
                hdr.transport.ipv4.identification,
                hdr.transport.ipv4.flags,
                hdr.transport.ipv4.frag_offset,
                hdr.transport.ipv4.ttl,
                hdr.transport.ipv4.protocol,
                hdr.transport.ipv4.src_addr,
                hdr.transport.ipv4.dst_addr});
        }
#endif // defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)

#ifdef TUNNEL_ENABLE
        if (hdr.outer.ipv4.isValid()) {
        
            hdr.outer.ipv4.hdr_checksum = ipv4_checksum_outer.update({
                    hdr.outer.ipv4.version,
                    hdr.outer.ipv4.ihl,
                    hdr.outer.ipv4.tos,
                    hdr.outer.ipv4.total_len,
                    hdr.outer.ipv4.identification,
                    hdr.outer.ipv4.flags,
                    hdr.outer.ipv4.frag_offset,
                    hdr.outer.ipv4.ttl,
                    hdr.outer.ipv4.protocol,
                    hdr.outer.ipv4.src_addr,
                    hdr.outer.ipv4.dst_addr});
        }
#endif

        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);

#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
        pkt.emit(hdr.transport.ipv4);
#endif // defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
        pkt.emit(hdr.transport.ipv6);
#endif // GRE_TRANSPORT_EGRESS_ENABLE_V6
        
#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
        pkt.emit(hdr.transport.gre);
#endif // defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
        
#ifdef ERSPAN_TRANSPORT_EGRESS_ENABLE
        pkt.emit(hdr.transport.gre_sequence);
        pkt.emit(hdr.transport.erspan_type2);
        //pkt.emit(hdr.transport.erspan_type3);
#endif // ERSPAN_TRANSPORT_EGRESS_ENABLE

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);
#ifdef CPU_ENABLE
  #ifdef CPU_FABRIC_HEADER_ENABLE
		pkt.emit(hdr.fabric);
  #endif
		pkt.emit(hdr.cpu);
#endif // CPU_ENABLE
#ifdef ETAG_ENABLE
        pkt.emit(hdr.outer.e_tag);
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
        pkt.emit(hdr.outer.vn_tag);
#endif // VNTAG_ENABLE
        pkt.emit(hdr.outer.vlan_tag);
#ifdef MPLS_ENABLE
        pkt.emit(hdr.outer.mpls);
        pkt.emit(hdr.outer.mpls_pw_cw);
#endif // MPLS_ENABLE
        pkt.emit(hdr.outer.ipv4);
#ifdef IPV6_ENABLE
        pkt.emit(hdr.outer.ipv6);
#endif // IPV6_ENABLE
        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);
#ifdef VXLAN_ENABLE
        pkt.emit(hdr.outer.vxlan);
#endif // VXLAN_ENABLE
        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);
#ifdef NVGRE_ENABLE
        pkt.emit(hdr.outer.nvgre);
#endif // NVGRE_ENABLE        
#ifdef GTP_ENABLE
        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);
#endif // GTP_ENABLE
        pkt.emit(hdr.outer.dtel); // Egress only.
        pkt.emit(hdr.outer.dtel_report); // Egress only.
        pkt.emit(hdr.outer.dtel_switch_local_report); // Egress only.
        pkt.emit(hdr.outer.dtel_drop_report); // Egress only.
        
        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);
#ifdef IPV6_ENABLE
        pkt.emit(hdr.inner.ipv6);
#endif // IPV6_ENABLE
        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);
#ifdef INNER_GRE_ENABLE
        pkt.emit(hdr.inner.gre);
#endif // INNER_GRE_ENABLE
#ifdef INNER_GTP_ENABLE
        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);
#endif // INNER_GTP_ENABLE
        
    }
}
