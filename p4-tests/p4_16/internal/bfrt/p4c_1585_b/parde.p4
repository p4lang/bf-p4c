/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2018 Barefoot Networks, Inc.
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

#include "npb_ing_parser.p4"
#include "npb_egr_parser.p4"

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
// Segment routing extension header parser
//-----------------------------------------------------------------------------
//parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
//    state start {
//#ifdef SRV6_ENABLE
//        transition parse_srh;
//#else
//        transition reject;
//#endif
//    }
//
//    state parse_srh {
//        //TODO(msharif) : implement SRH parser.
//        transition reject;
//    }
//}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {
#ifdef MIRROR_ENABLE
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            mirror.emit(
                ig_md.mirror.session_id,
                {ig_md.mirror.src, ig_md.mirror.type, ig_md.timestamp, ig_md.mirror.session_id});

        } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_DTEL_DROP) {
#ifdef DTEL_ENABLE
            mirror.emit(ig_md.dtel.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                ig_md.timestamp,
                ig_md.dtel.session_id,
                ig_md.dtel.hash,
                ig_md.dtel.report_type,
                ig_md.port,
                ig_md.egress_port,
                ig_md.qos.qid,
                ig_md.drop_reason
            });

#endif /* DTEL_ENABLE */
        }
#endif /* MIRROR_ENABLE */
    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {
#ifdef MIRROR_ENABLE
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            mirror.emit(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_timestamp,
                eg_md.mirror.session_id});
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
            mirror.emit(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_port,
                eg_md.bd,
                eg_md.ingress_ifindex,
                eg_md.cpu_reason});
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL) {
#ifdef DTEL_ENABLE
            mirror.emit(eg_md.dtel.session_id, {
                eg_md.mirror.src, eg_md.mirror.type,
                eg_md.ingress_timestamp,
                eg_md.dtel.session_id,
                eg_md.dtel.hash,
                eg_md.dtel.report_type,
                eg_md.ingress_port,
                eg_md.port,
                eg_md.qos.qid,
                eg_md.qos.qdepth,
                eg_md.timestamp[31:0]
            });
#endif /* DTEL_ENABLE */
        }
#endif /* MIRROR_ENABLE */
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

    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ig_md.bd, ig_md.ifindex, ig_md.lkp.mac_src_addr});
        }

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** UNDERLAY *****
        pkt.emit(hdr.nsh_extr_underlay);
// #ifdef ERSPAN_UNDERLAY_ENABLE
//         pkt.emit(hdr.erspan_type1_underlay);
//         pkt.emit(hdr.erspan_type2_underlay);
// #endif /* ERSPAN_UNDERLAY_ENABLE */

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre);

        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
#ifdef GTP_ENABLE
        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v1_optional);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v2_optional_teid);
#endif  /* GTP_ENABLE */

#ifdef MPLS_ENABLE
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.mpls_pw_cw);
#endif  /* MPLS_ENABLE */

        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
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

    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
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

/*
        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress Only.
        pkt.emit(hdr.cpu); // Egress Only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        //pkt.emit(hdr.erspan_type3); // Egress only.
        //pkt.emit(hdr.erspan_platform); // Egress only.

        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
*/

        // ***** UNDERLAY *****
#ifdef SPBM_ENABLE
        pkt.emit(hdr.b_ethernet_underlay);
        pkt.emit(hdr.b_tag_underlay);
        pkt.emit(hdr.i_tag_underlay);
#endif  /* SPBM_ENABLE */
        pkt.emit(hdr.ethernet_underlay);
        pkt.emit(hdr.vlan_tag_underlay);
        pkt.emit(hdr.nsh_extr_underlay);

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress Only.
        pkt.emit(hdr.cpu); // Egress Only.
        pkt.emit(hdr.timestamp); // Egress only.

        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre); // Egress Only.
#ifdef ERSPAN_TYPE2_ENABLE
        pkt.emit(hdr.erspan_type2); // Egress Only.
#endif /* ERSPAN_TYPE2_ENABLE */
#ifdef ERSPAN_ENABLE
        pkt.emit(hdr.erspan_type3); // Egress Only.
        pkt.emit(hdr.erspan_platform); // Egress Only.
#endif /* ERSPAN_ENABLE */

        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
#ifdef GTP_ENABLE
        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v1_optional);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v2_optional_teid);
#endif  /* GTP_ENABLE */
#ifdef MPLS_ENABLE
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.mpls_pw_cw);
#endif  /* MPLS_ENABLE */

        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
