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

#include "rewrite.p4"

//-----------------------------------------------------------------------------
// Ingress/Egress Port Mirroring
//-----------------------------------------------------------------------------

control PortMirror(
		in switch_port_t port,
		in switch_pkt_src_t src,
		inout switch_mirror_metadata_t mirror_md, // derek added
		inout switch_cpu_reason_t cpu_reason // derek added
) (
		switch_uint32_t table_size=288
) {

	action set_mirror_id(
		switch_mirror_session_t session_id,
		switch_mirror_meter_id_t meter_index, // derek added
		switch_cpu_reason_t cpu_reason_code // derek added
	) {
		mirror_md.type = SWITCH_MIRROR_TYPE_PORT;
		mirror_md.src = src;
		mirror_md.session_id = session_id;
#ifdef MIRROR_METERS
		mirror_md.meter_index = meter_index; // derek added
#endif
//		cpu_reason = cpu_reason_code; // derek added
	}

	table port_mirror {
		key = {
			port : exact;
		}
		actions = {
			NoAction;
			set_mirror_id;
		}

		const default_action = NoAction;
		size = table_size;
	}

	apply {
		port_mirror.apply();
	}
}

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
		inout switch_header_t hdr,
		inout switch_ingress_metadata_t ig_md,
		inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
		inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
		switch_uint32_t port_vlan_table_size,
		switch_uint32_t bd_table_size,
		switch_uint32_t port_table_size=288,
		switch_uint32_t vlan_table_size=4096
) {
#ifdef MIRROR_INGRESS_PORT_ENABLE
	PortMirror(port_table_size) port_mirror;
#endif
	ActionProfile(bd_table_size) bd_action_profile;

	bit<8> junk;

	// ----------------------------------------------
	// Table: Port Mapping
	// ----------------------------------------------

	// Helper action:

	action terminate_cpu_packet() {
		// ig_md.bypass = (bit<8>) hdr.cpu.reason_code;                                 // Done in parser
//		ig_md.port = (switch_port_t) hdr.cpu.ingress_port;                              // Done in parser
//		ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index; // Done in parser
//		ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;                    // Not done in parser, since ig_intr_md_for_tm doesn't exist there.
#ifdef CPU_TX_BYPASS_ENABLE
//		ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;                           // Done in parser
//		DEREK: This next line should be deleted, but doing so causes us not to fit!?!?  ¯\_('')_/¯
// 		ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass;                            // Not done in parser, since ig_intr_md_for_tm doesn't exist there.
#endif
//		hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;                             // Wants to be done in parser (see bf-case 10933)
	}

	// --------------------------

	action set_cpu_port_properties(
		switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
		switch_yid_t exclusion_id,
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc
		bool l2_fwd_en
	) {
#ifdef CPU_ENABLE
		ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
		ig_md.nsh_md.l2_fwd_en = l2_fwd_en;

		terminate_cpu_packet();
#endif
	}

	// --------------------------

	action set_port_properties(
		// note: for regular ports, port_lag_index and l2_fwd_en come from the port_metadata table.
		switch_yid_t exclusion_id,
		switch_port_lag_index_t port_lag_index,
		bool l2_fwd_en
	) {
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
		ig_md.port_lag_index = port_lag_index;
		ig_md.nsh_md.l2_fwd_en = l2_fwd_en;
	}

	// --------------------------

	table port_mapping {
		key = {
			ig_md.port : exact;
#ifdef CPU_BD_MAP_ENABLE
			hdr.cpu.isValid() : exact;
//			hdr.cpu.ingress_port : exact; // DEREK: IS THIS NEEDED / WHAT IS IT FOR?
#endif
		}

		actions = {
			set_port_properties;
			set_cpu_port_properties;
		}

		size = port_table_size * 2;
	}

	// ----------------------------------------------
	// Table: BD Mapping
	// ----------------------------------------------

	action port_vlan_miss() {
		//ig_md.flags.port_vlan_miss = true;
	}

	action set_bd_properties(
		switch_bd_t bd ,
		switch_rid_t rid
	) {
		ig_md.bd = bd;
#ifdef MULTICAST_INGRESS_RID_ENABLE
		ig_intr_md_for_tm.rid = rid;
#endif
	}

	// (port, vlan) --> bd mapping -- Following set of entres are needed:
	//   (port, 0, *)    L3 interface.
	//   (port, 1, vlan) L3 sub-interface.
	//   (port, 0, *)    Access port + untagged packet.
	//   (port, 1, vlan) Access port + packets tagged with access-vlan.
	//   (port, 1, 0)    Access port + .1p tagged packets.
	//   (port, 1, vlan) L2 sub-port.
	//   (port, 0, *)    Trunk port if native-vlan is not tagged.

	table port_vlan_to_bd_mapping {
		key = {
			ig_md.port_lag_index : exact;
//			hdr.transport.vlan_tag[0].isValid() : ternary;
//			hdr.transport.vlan_tag[0].vid : ternary;
			hdr.outer.vlan_tag[0].isValid() : ternary;
			hdr.outer.vlan_tag[0].vid : ternary;
		}

		actions = {
			NoAction;
			port_vlan_miss;
			set_bd_properties;
		}

		const default_action = NoAction;
		implementation = bd_action_profile;
		size = port_vlan_table_size;
	}

	// (*, vlan) --> bd mapping
	table vlan_to_bd_mapping {
		key = {
//			hdr.transport.vlan_tag[0].vid : exact;
			hdr.outer.vlan_tag[0].vid : exact;
		}

		actions = {
			NoAction;
			port_vlan_miss;
			set_bd_properties;
		}

		const default_action = port_vlan_miss;
		implementation = bd_action_profile;
		size = vlan_table_size;
	}

	table cpu_to_bd_mapping {
		key = { ig_md.bd : exact; }

		actions = {
			NoAction;
			port_vlan_miss;
			set_bd_properties;
		}

		const default_action = port_vlan_miss;
		implementation = bd_action_profile;
		size = bd_table_size;
	}

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

	apply {
/*
		switch (port_mapping.apply().action_run) {
#ifdef CPU_BD_MAP_ENABLE
			set_cpu_port_properties : {
				cpu_to_bd_mapping.apply();
			}
#endif

			set_port_properties : {



					if (!port_vlan_to_bd_mapping.apply().hit) {
						if (hdr.transport.vlan_tag[0].isValid())
							vlan_to_bd_mapping.apply();
					}



			}
		}
*/
		if(port_mapping.apply().hit) {
			if(hdr.cpu.isValid()) {
#ifdef CPU_BD_MAP_ENABLE
				cpu_to_bd_mapping.apply();
#endif
			} else {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.transport.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
		}

#ifdef MIRROR_INGRESS_PORT_ENABLE
//		port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, ig_md.cpu_reason);
//		ig_md.cpu_reason = SWITCH_CPU_REASON_IG_PORT_MIRRROR;
		port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, junk);
#endif
	}
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
// ----------------------------------------------------------------------------

control LAG(
	inout switch_ingress_metadata_t ig_md,
	in bit<(switch_lag_hash_width/2)> hash,
	out switch_port_t egress_port
) {
	bit<16> lag_hash;
#ifdef SHARED_ECMP_LAG_HASH_CALCULATION
	Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
#else
	Hash<switch_uint16_t>(HashAlgorithm_t.CRC16) selector_hash;
#endif
	ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
	ActionSelector(lag_action_profile,
	               selector_hash,
//	               SelectorMode_t.FAIR,
	               SelectorMode_t.RESILIENT,
	               LAG_MAX_MEMBERS_PER_GROUP,
	               LAG_GROUP_TABLE_SIZE) lag_selector;

	// ----------------------------------------------
	// Table: LAG
	// ----------------------------------------------

	DirectCounter<bit<switch_counter_width>               >(type=CounterType_t.PACKETS_AND_BYTES) stats_in;  // direct counter
//	Counter      <bit<switch_counter_width>, switch_port_t>(512, CounterType_t.PACKETS_AND_BYTES) stats_out; // indirect counter
	Counter      <bit<switch_counter_width>, bit<19>      >(512, CounterType_t.PACKETS_AND_BYTES) stats_out; // indirect counter
 
	action set_lag_port(switch_port_t port) {
		stats_in.count();

		egress_port = port;
	}







	action lag_miss() {
		stats_in.count();

	}

	table lag {
		key = {



			ig_md.egress_port_lag_index : exact @name("port_lag_index");


#ifdef SHARED_ECMP_LAG_HASH_CALCULATION
			hash : selector;
#else
			lag_hash : selector;
#endif
		}

		actions = {
			lag_miss;
			set_lag_port;



		}

		const default_action = lag_miss;
		size = LAG_TABLE_SIZE;
		counters = stats_in;
		implementation = lag_selector;
	}

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

	apply {
        lag_hash = selector_hash.get({ig_md.lkp_1.mac_src_addr,
                                      ig_md.lkp_1.mac_dst_addr,
                                      ig_md.lkp_1.mac_type,
                                      ig_md.lkp_1.ip_src_addr,
                                      ig_md.lkp_1.ip_dst_addr,
                                      ig_md.lkp_1.ip_proto,
                                      ig_md.lkp_1.l4_dst_port,
                                      ig_md.lkp_1.l4_src_port});
		lag.apply();

//		stats_out.count(ig_md.egress_port_lag_index ++ egress_port);
	}
}

//-----------------------------------------------------------------------------
// Egress Port Mapping
//-----------------------------------------------------------------------------

control EgressPortMapping(
	inout switch_header_t hdr,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in switch_port_t port
) (
	switch_uint32_t table_size=288
) {
#ifdef MIRROR_EGRESS_PORT_ENABLE
	PortMirror(table_size) port_mirror;
#endif

	// ----------------------------------------------
	// Table: Port Mapping
	// ----------------------------------------------

	action cpu_rewrite() {
		// ----- add fabric header -----
#ifdef CPU_FABRIC_HEADER_ENABLE
		hdr.fabric.setValid();
		hdr.fabric.reserved = 0;
		hdr.fabric.color = 0;
		hdr.fabric.qos = 0;
		hdr.fabric.reserved2 = 0;
#endif
		// ----- add cpu header -----
		hdr.cpu.setValid();
		hdr.cpu.egress_queue = 0;
		hdr.cpu.tx_bypass = 0;
		hdr.cpu.capture_ts = 0;
		hdr.cpu.reserved = 0;
		// Both these line are here instead of parser out due to compiler... "error: Field is
		// extracted in the parser into multiple containers, but the container
		// slices after the first aren't byte aligned"
		hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
		hdr.cpu.port_lag_index = (bit<16>) eg_md.port_lag_index;
		hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
		hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
		hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
#ifdef CPU_FABRIC_HEADER_ENABLE
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN;
#else
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN2;
#endif
	}

	action port_normal(
		switch_port_lag_index_t port_lag_index
	) {
		eg_md.port_lag_index = port_lag_index;
	}

	action port_cpu(
		switch_port_lag_index_t port_lag_index,
		switch_meter_index_t meter_index
	) {
#ifdef CPU_ENABLE
		cpu_rewrite();
  #if defined(EGRESS_PORT_METER_ENABLE)
		eg_md.qos.port_meter_index = meter_index;
  #endif /* EGRESS_PORT_METER_ENABLE */
#endif // CPU_ENABLE
	}

	table port_mapping {
		key = {
			port : exact;
		}

		actions = {
			port_normal;
			port_cpu;
		}

		size = table_size;
	}

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

	apply {
		port_mapping.apply();

#ifdef MIRROR_EGRESS_PORT_ENABLE
		port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror, eg_md.cpu_reason);
		eg_md.cpu_reason = SWITCH_CPU_REASON_EG_PORT_MIRRROR;
#endif
	}
}
