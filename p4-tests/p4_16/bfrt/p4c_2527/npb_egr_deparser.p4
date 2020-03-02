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
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {

#ifdef ERSPAN_EGRESS_ENABLE
        if (hdr.transport.ipv4.isValid()) {
            hdr.transport.ipv4.hdr_checksum = ipv4_checksum.update({
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
#endif /* ERSPAN_EGRESS_ENABLE */

#ifdef TUNNEL_ENABLE
        hdr.outer.ipv4.hdr_checksum = inner_ipv4_checksum.update({
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
#endif

        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);

#ifdef ERSPAN_EGRESS_ENABLE
        pkt.emit(hdr.transport.ipv4);
        pkt.emit(hdr.transport.gre);
        pkt.emit(hdr.transport.gre_sequence);
        pkt.emit(hdr.transport.erspan_type2);
        pkt.emit(hdr.transport.erspan_type3);
#endif /* ERSPAN_EGRESS_ENABLE */

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);

        pkt.emit(hdr.outer.e_tag);
        pkt.emit(hdr.outer.vn_tag);
        pkt.emit(hdr.outer.vlan_tag);
        pkt.emit(hdr.outer.ipv4);
#ifdef IPV6_ENABLE
        pkt.emit(hdr.outer.ipv6);
#endif  /* IPV6_ENABLE */
        pkt.emit(hdr.outer.gre); // Egress Only.
        pkt.emit(hdr.outer.nvgre);
        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.sctp);
        pkt.emit(hdr.outer.esp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.vxlan);
#ifdef GTP_ENABLE
        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v2_base);
#endif  /* GTP_ENABLE */
#ifdef MPLS_ENABLE
        pkt.emit(hdr.outer.mpls);
        pkt.emit(hdr.outer.mpls_pw_cw);
#endif  /* MPLS_ENABLE */

        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);
#ifdef IPV6_ENABLE
        pkt.emit(hdr.inner.ipv6);
#endif  /* IPV6_ENABLE */
        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);


#ifdef PARDE_INNER_GRE_ENABLE
        pkt.emit(hdr.inner.gre);
#endif
#ifdef PARDE_INNER_ESP_ENABLE
        pkt.emit(hdr.inner.esp);
#endif
#ifdef PARDE_INNER_CONTROL_ENABLE
        pkt.emit(hdr.inner.arp);
        pkt.emit(hdr.inner.icmp);
        pkt.emit(hdr.inner.igmp);
#endif

    }
}
