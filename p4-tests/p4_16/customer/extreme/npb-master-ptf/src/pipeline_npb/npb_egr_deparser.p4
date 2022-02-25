#ifndef _NPB_EGR_DEPARSER_
#define _NPB_EGR_DEPARSER_

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
/*
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
  #ifdef MIRROR_EGRESS_PORT_ENABLE
            mirror.emit<switch_port_mirror_egress_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                eg_md.port,
    #else
                eg_md.port_lag_index,
    #endif
                eg_md.ingress_timestamp,
//  #if __TARGET_TOFINO__ == 1
//              0,
//  #endif
//              eg_md.mirror.session_id
                eg_md.cpu_reason
				,
				0,
				eg_md.qos.qid,
				0,
				eg_md.qos.qdepth
            });
  #endif
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
*/
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
  #ifdef CPU_ACL_EGRESS_ENABLE
            mirror.emit<switch_cpu_mirror_egress_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                eg_md.port,
    #else
                eg_md.port_lag_index,
    #endif
                eg_md.ingress_timestamp,
                eg_md.cpu_reason
				,
				0,
				eg_md.qos.qid,
				0,
				eg_md.qos.qdepth
            });
  #endif
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL) {
  #ifdef DTEL_ENABLE
            mirror.emit<switch_dtel_switch_local_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_timestamp,
    #if __TARGET_TOFINO__ == 1
                0,
    #endif
                eg_md.dtel.session_id,
                eg_md.dtel.hash,
                eg_md.dtel.report_type,
                0,
                eg_md.ingress_port,
                0,
                eg_md.port,
                0,
                eg_md.qos.qid,
                0,
                eg_md.qos.qdepth,
                eg_md.timestamp
            });
  #endif // DTEL_ENABLE
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_DTEL_DROP) {
  #ifdef DTEL_ENABLE
            mirror.emit<switch_dtel_drop_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_timestamp,
    #if __TARGET_TOFINO__ == 1
                 0,
    #endif
                eg_md.dtel.session_id,
                eg_md.dtel.hash,
                eg_md.dtel.report_type,
                0,
                eg_md.ingress_port,
                0,
                eg_md.port,
                0,
                eg_md.qos.qid,
                eg_md.drop_reason
            });
  #endif // DTEL_ENABLE
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_SIMPLE) {
  #ifdef DTEL_ENABLE
            mirror.emit<switch_simple_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
    #if __TARGET_TOFINO__ == 1
                0,
    #endif
                eg_md.dtel.session_id
            });
  #endif // DTEL_ENABLE
        }
#endif /* MIRROR_ENABLE */
    }
}

//-----------------------------------------------------------------------------

control EgressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) ( // constructor parameters
    MODULE_DEPLOYMENT_PARAMS
) {

	EgressMirror() mirror;
    Checksum() ipv4_checksum_transport;
    Checksum() ipv4_checksum_outer;

    apply {
		mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);

#ifdef TUNNEL_ENABLE
		if(TRANSPORT_EGRESS_ENABLE) {
			if((TRANSPORT_IPV4_EGRESS_ENABLE) && ((TRANSPORT_GRE_EGRESS_ENABLE || TRANSPORT_ERSPAN_EGRESS_ENABLE))) {
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
			}
		}
#endif
/*
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
*/
        // ***** TRANSPORT *****
		if(FOLDED_ENABLE) {
			pkt.emit(hdr.bridged_md_folded);
			pkt.emit(hdr.transport.nsh_type1_internal);
		} else {
			if(TRANSPORT_EGRESS_ENABLE) {
				pkt.emit(hdr.transport.ethernet);
				pkt.emit(hdr.transport.vlan_tag);
				pkt.emit(hdr.transport.nsh_type1);

//				if(TRANSPORT_IPV4_EGRESS_ENABLE) {
				if((TRANSPORT_IPV4_EGRESS_ENABLE                                ) && (TRANSPORT_GRE_EGRESS_ENABLE || TRANSPORT_ERSPAN_EGRESS_ENABLE)) {
		      	  pkt.emit(hdr.transport.ipv4);
				}

//				if(TRANSPORT_IPV6_EGRESS_ENABLE) {
				if((                                TRANSPORT_IPV6_EGRESS_ENABLE) && (TRANSPORT_GRE_EGRESS_ENABLE || TRANSPORT_ERSPAN_EGRESS_ENABLE)) {
			        pkt.emit(hdr.transport.ipv6);
				}
        
				if((TRANSPORT_IPV4_EGRESS_ENABLE || TRANSPORT_IPV6_EGRESS_ENABLE) && (TRANSPORT_GRE_EGRESS_ENABLE || TRANSPORT_ERSPAN_EGRESS_ENABLE)) {
			        pkt.emit(hdr.transport.gre);
				}
        
				if((TRANSPORT_IPV4_EGRESS_ENABLE || TRANSPORT_IPV6_EGRESS_ENABLE) && (                               TRANSPORT_ERSPAN_EGRESS_ENABLE)) {
			        pkt.emit(hdr.transport.gre_sequence);
			        pkt.emit(hdr.transport.erspan_type2);
			        //pkt.emit(hdr.transport.erspan_type3);
				}

#if defined(DTEL_ENABLE)
		        pkt.emit(hdr.transport.udp);
#endif // defined(DTEL_ENABLE)

		        pkt.emit(hdr.transport.dtel); // Egress only.
#ifdef INT_V2
		        pkt.emit(hdr.transport.dtel_metadata_1); // Egress only.
		        pkt.emit(hdr.transport.dtel_metadata_2); // Egress only.
		        pkt.emit(hdr.transport.dtel_metadata_3); // Egress only.
		        pkt.emit(hdr.transport.dtel_metadata_4); // Egress only.
		        pkt.emit(hdr.transport.dtel_metadata_5); // Egress only.
#else
		        pkt.emit(hdr.transport.dtel_report); // Egress only.
		        pkt.emit(hdr.transport.dtel_switch_local_report); // Egress only.
#endif
		        pkt.emit(hdr.transport.dtel_drop_report); // Egress only.
			}
		}

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);
#ifdef CPU_ENABLE
  #ifdef CPU_FABRIC_HEADER_ENABLE
		pkt.emit(hdr.fabric);
  #endif
		pkt.emit(hdr.cpu);
#endif // CPU_ENABLE
        
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
            //if(MPLS_DEPTH_OUTER == 4 || MPLS_DEPTH_OUTER == 6) {
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
    }
}

#endif /* _NPB_EGR_DEPARSER_ */
