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
// Ingress Deparser
//-----------------------------------------------------------------------------

control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.

#ifdef MIRROR_INGRESS_ENABLE
    Mirror() mirror;
#endif

    apply {
#ifdef MIRROR_INGRESS_ENABLE
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            mirror.emit<switch_port_mirror_metadata_h>(
                ig_md.mirror.session_id,
                {ig_md.mirror.src,
                 ig_md.mirror.type,
//               ig_md.timestamp,
				 0,
#if __TARGET_TOFINO__ == 1
                 0,
#endif
//               ig_md.mirror.session_id});
				 0});
        }
#endif /* MIRROR_INGRESS_ENABLE */
    }
}

//-----------------------------------------------------------------------------

control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

	IngressMirror() mirror;

    apply {
		mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** PRE-TRANSPORT *****
        pkt.emit(hdr.transport.nsh_type1);

        // ***** TRANSPORT *****
//      pkt.emit(hdr.transport.ethernet);
//      pkt.emit(hdr.transport.vlan_tag);

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);
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
#ifdef NVGRE_ENABLE
        pkt.emit(hdr.outer.nvgre);
#endif // NVGRE_ENABLE
#ifdef GTP_ENABLE
        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);
#endif // GTP_ENABLE


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

#ifdef UDF_ENABLE
        pkt.emit(hdr.udf);
#endif // UDF_ENABLE
    }
}

