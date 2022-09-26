#ifndef _UTIL_
#define _UTIL_

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
control AddBridgedMd(
	inout switch_bridged_metadata_h bridged_md,
	in switch_ingress_metadata_t ig_md
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	apply {
		bridged_md.setValid();
		bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
		bridged_md.base = {
			ig_md.ingress_port,
#ifdef CPU_HDR_CONTAINS_EG_PORT
//			ig_md.egress_port, // derek added
#else
			ig_md.ingress_port_lag_index,
#endif
//			ig_md.bd,
			ig_md.nexthop,
//			ig_md.lkp.pkt_type,
			ig_md.flags.bypass_egress,
			ig_md.cpu_reason,
			ig_md.ingress_timestamp,
			ig_md.qos.qid,

			// Add more fields here.
			ig_md.hash,
			ig_md.flags.transport_valid,
			ig_md.nsh_md.end_of_path,
			ig_md.nsh_md.l2_fwd_en,
			ig_md.nsh_md.dedup_en
		};
/*
		bridged_md.nsh = {
			ig_md.nsh_md.end_of_path,
			ig_md.nsh_md.l2_fwd_en,
			ig_md.nsh_md.dedup_en
		};
*/
#ifdef TUNNEL_ENABLE
		if(TRANSPORT_EGRESS_ENABLE) {
			bridged_md.tunnel = {
				ig_md.tunnel_0.dip_index,
				ig_md.tunnel_nexthop
//				ig_md.hash[15:0],

//				ig_md.tunnel_0.terminate // unused, but removing causes a compiler error
//				ig_md.tunnel_1.terminate,
//				ig_md.tunnel_2.terminate
			};
		}
#endif
#ifdef DTEL_ENABLE
		bridged_md.dtel = {
//			ig_md.dtel.report_type,
//			ig_md.dtel.session_id,
//			ig_md.hash,
//			ig_md.egress_port
		};
#endif
	}
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Ingress pipeline.
control AddBridgedMdFolded(
	inout switch_bridged_metadata_folded_h bridged_md,
	in switch_egress_metadata_t eg_md
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	apply {
		bridged_md.setValid();
		bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
		bridged_md.base = {
			eg_md.ingress_port,
#ifdef CPU_HDR_CONTAINS_EG_PORT
//			eg_md.egress_port, // derek added
#else
			eg_md.egress_port_lag_index,
#endif
//			eg_md.bd,
			eg_md.nexthop,
//			eg_md.lkp.pkt_type,
			false,
			0,
			eg_md.ingress_timestamp,
			eg_md.qos.qid,

			// Add more fields here.
			eg_md.hash,
			eg_md.flags.transport_valid,
			eg_md.nsh_md.end_of_path,
			eg_md.nsh_md.l2_fwd_en,
			eg_md.nsh_md.dedup_en
		};
/*
		bridged_md.nsh = {
			eg_md.nsh_md.end_of_path,
			eg_md.nsh_md.l2_fwd_en,
			eg_md.nsh_md.dedup_en
		};
*/
#ifdef TUNNEL_ENABLE
		if(TRANSPORT_EGRESS_ENABLE) {
			bridged_md.tunnel = {
				eg_md.tunnel_0.dip_index,
				eg_md.tunnel_nexthop
//				eg_md.hash[15:0],

//				eg_md.tunnel_0.terminate // unused, but removing causes a compiler error
//				eg_md.tunnel_1.terminate,
//				eg_md.tunnel_2.terminate
			};
		}
#endif
#ifdef DTEL_ENABLE
		bridged_md.dtel = {
//			eg_md.dtel.report_type,
//			eg_md.dtel.session_id,
//			eg_md.hash,
//			eg_md.egress_port
		};
#endif
	}
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
	in switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
	ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;

	// Set PRE hash values
	bit<13> hash;
#if(switch_hash_width < 26)
	hash = (bit<13>)ig_md.hash[switch_hash_width-1   :switch_hash_width/2]; // grow to 13 bits
#else
	hash =          ig_md.hash[switch_hash_width/2+12:switch_hash_width/2]; // cap  at 13 bits
#endif
//	ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
	ig_intr_md_for_tm.level2_mcast_hash = hash;

//#ifdef QOS_ENABLE
	ig_intr_md_for_tm.qid = ig_md.qos.qid;
//	ig_intr_md_for_tm.ingress_cos = ig_md.qos.icos;
//#endif
}

// -----------------------------------------------------------------------------

action set_eg_intr_md(
	in switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
#ifdef MIRROR_ENABLE
#if __TARGET_TOFINO__ == 1
	eg_intr_md_for_dprsr.mirror_type = (bit<3>) eg_md.mirror.type;
#else
	eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
	eg_intr_md_for_dprsr.mirror_io_select = 1;
#endif
#endif
}


#endif /* _UTIL_ */
