#ifndef _NPB_ING_DEPARSER_
#define _NPB_ING_DEPARSER_

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
/*
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            mirror.emit<switch_port_mirror_ingress_metadata_h>(ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                0,
                ig_md.port,
                ig_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                ig_md.egress_port,
    #else
                ig_md.port_lag_index,
    #endif
                ig_md.timestamp,
//  #if __TARGET_TOFINO__ == 1
//               0,
//  #endif
//              ig_md.mirror.session_id
				ig_md.cpu_reason
				,
				0,
				ig_md.qos.qid,
				0,
				ig_md.qos.qdepth
            });
        } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
*/
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
  #ifdef CPU_ACL_EGRESS_ENABLE
            mirror.emit<switch_cpu_mirror_ingress_metadata_h>(ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                0,
                ig_md.port,
                ig_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                ig_md.egress_port,
    #else
                ig_md.port_lag_index,
    #endif
                ig_md.timestamp,
                ig_md.cpu_reason
/*
				,
				0,
				ig_md.qos.qid,
				0,
				ig_md.qos.qdepth
*/
            });
  #endif
        } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_DTEL_DROP) {
#ifdef DTEL_ENABLE
/*
            mirror.emit<switch_dtel_drop_mirror_metadata_h>(ig_md.dtel.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                ig_md.timestamp,
#if __TARGET_TOFINO__ == 1
                0,
#endif
                ig_md.dtel.session_id,
                ig_md.hash,
                ig_md.dtel.report_type,
                0,
                ig_md.port,
                0,
                ig_md.egress_port,
                0,
                ig_md.qos.qid,
                ig_md.drop_reason
            });
*/
#endif /* DTEL_ENABLE */
        }
#endif /* MIRROR_INGRESS_ENABLE */
    }
}

//-----------------------------------------------------------------------------

control IngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) ( // constructor parameters
    MODULE_DEPLOYMENT_PARAMS
) {

	IngressMirror() mirror;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** PRE-TRANSPORT *****
        //pkt.emit(hdr.transport.nsh_type1);
        pkt.emit(hdr.transport.nsh_type1_internal);

        // ***** TRANSPORT *****
        //pkt.emit(hdr.transport.ethernet);
        //pkt.emit(hdr.transport.vlan_tag);

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);

        if(OUTER_ETAG_ENABLE) {
            pkt.emit(hdr.outer.e_tag);
        }
        
        if(OUTER_VNTAG_ENABLE) {
            pkt.emit(hdr.outer.vn_tag);
        }

        pkt.emit(hdr.outer.vlan_tag);
        
        if(OUTER_EoMPLS_ENABLE || OUTER_EoMPLS_PWCW_ENABLE || OUTER_IPoMPLS_ENABLE) {
            pkt.emit(hdr.outer.mpls_0);
            pkt.emit(hdr.outer.mpls_1);
            // if(MPLS_DEPTH_OUTER == 4 || MPLS_DEPTH_OUTER == 6) {
            if(MPLS_DEPTH_OUTER == 4) {
                pkt.emit(hdr.outer.mpls_2);
                pkt.emit(hdr.outer.mpls_3);
            }
            // if(MPLS_DEPTH_OUTER == 6) {
            //     pkt.emit(hdr.outer.mpls_4);
            //     pkt.emit(hdr.outer.mpls_5);
            // }
        }
        if(OUTER_EoMPLS_PWCW_ENABLE) {
            pkt.emit(hdr.outer.mpls_pw_cw);
        }
            
        pkt.emit(hdr.outer.ipv4);
            
        if(OUTER_IPV6_ENABLE) {
            pkt.emit(hdr.outer.ipv6);
        }

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        if(OUTER_GENEVE_ENABLE) {
            pkt.emit(hdr.outer.geneve);
        }

        if(OUTER_VXLAN_ENABLE) {
            pkt.emit(hdr.outer.vxlan);
        }

        if(OUTER_GRE_ENABLE) {
            pkt.emit(hdr.outer.gre);
            pkt.emit(hdr.outer.gre_optional);
        }

        if(OUTER_NVGRE_ENABLE) {
            pkt.emit(hdr.outer.nvgre);
        }
        
        if(OUTER_GTP_ENABLE) {
            pkt.emit(hdr.outer.gtp_v1_base);
            pkt.emit(hdr.outer.gtp_v1_optional);
        }

        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        if(INNER_IPV6_ENABLE) {
            pkt.emit(hdr.inner.ipv6);
        }

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);

        if(INNER_GRE_ENABLE) {
            pkt.emit(hdr.inner.gre);
            pkt.emit(hdr.inner.gre_optional);
        }

        if(INNER_GTP_ENABLE) {
            pkt.emit(hdr.inner.gtp_v1_base);
            pkt.emit(hdr.inner.gtp_v1_optional);
        }

        if(UDF_ENABLE) {
            pkt.emit(hdr.udf);
        }
    }
}

#endif /* _NPB_ING_DEPARSER_ */
