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
// Port Mirroring
//-----------------------------------------------------------------------------

control PortMirror(
		in switch_port_t port,
		in switch_pkt_src_t src,
		inout switch_mirror_metadata_t mirror_md,
		in    bit<8> cpu_reason_code, // extreme added
		inout bit<8> cpu_reason       // extreme added
)(
		switch_uint32_t table_size=288
) {

	action set_mirror_id(switch_mirror_session_t session_id) {
		mirror_md.type = SWITCH_MIRROR_TYPE_PORT;
		mirror_md.src = src;
		mirror_md.session_id = session_id;
		cpu_reason = cpu_reason_code; // extreme added
	}

	table port_mirror {
		key = { port : exact; }
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

	bool valid_cpu;

	// ----------------------------------------------
	// Table: Port Mapping
	// ----------------------------------------------

	// Helper action:

	switch_cpu_reason_t cpu_reason_;
	bool copy_to_cpu_;
	bool redirect_to_cpu_;
	switch_copp_meter_id_t copp_meter_id_;

	action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason, in switch_copp_meter_id_t copp_meter_id) {
		ig_intr_md_for_tm.copy_to_cpu = 1w1;
		ig_md.cpu_reason = cpu_reason;
	}

	// --------------------------

	// Helper action:

	action terminate_cpu_packet() {

		// ig_md.bypass = hdr.cpu.reason_code;                                             // Done in parser
		// ig_md.port = (switch_port_t) hdr.cpu.ingress_port;                              // Done in parser
		// ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index; // Done in parser
		// hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;                             // Wants to be done in parser (see bf-case 10933)

		//XXX(msharif) : Fix this for Tofino2
		// ig_intr_md_for_tm.qid = hdr.cpu.egress_queue;
#ifdef CPU_TX_BYPASS_ENABLE
		ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass;                               // Not done in parser, since ig_intr_md_for_tm doesn't exist there.
#endif

		valid_cpu = true;
	}

	// --------------------------

	action set_cpu_port_properties_with_nsh(
//		switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
		switch_yid_t exclusion_id
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc
	) {
#ifdef CPU_ENABLE
//		ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

		terminate_cpu_packet();
#endif
	}

	action set_cpu_port_properties_without_nsh(
//		switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
		switch_yid_t exclusion_id,
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc

		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<24>                         spi,
		bit<8>                          si,
		bit<8>                          si_predec
	) {
#ifdef CPU_ENABLE
//		ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

		terminate_cpu_packet();

		hdr.transport.nsh_type1.sap       = (bit<16>)sap; // 16 bits
		hdr.transport.nsh_type1.vpn       = (bit<16>)vpn; // 16 bits
		hdr.transport.nsh_type1.spi       = spi;          // 24 bits
		hdr.transport.nsh_type1.si        = si;           //  8 bits
		ig_md.nsh_md.si_predec            = si_predec;    //  8 bits
#endif
	}

	// --------------------------

	action set_port_properties_with_nsh(
		switch_yid_t exclusion_id

#ifdef CPU_PORT_INGRESS_ENABLE
		,
		bool copy_to_cpu,
		bool redirect_to_cpu,
		switch_cpu_reason_t cpu_reason_code,
		switch_copp_meter_id_t copp_meter_id
#endif
	) {
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

#ifdef CPU_PORT_INGRESS_ENABLE
		copy_to_cpu_                = copy_to_cpu;
		redirect_to_cpu_            = redirect_to_cpu;
		cpu_reason_                 = cpu_reason_code;
		copp_meter_id_              = copp_meter_id;
#endif
	}

	action set_port_properties_without_nsh(
		switch_yid_t exclusion_id,

#ifdef CPU_PORT_INGRESS_ENABLE
		bool copy_to_cpu,
		bool redirect_to_cpu,
		switch_cpu_reason_t cpu_reason_code,
		switch_copp_meter_id_t copp_meter_id,
#endif

		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<24>                         spi,
		bit<8>                          si,
		bit<8>                          si_predec
	) {
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

#ifdef CPU_PORT_INGRESS_ENABLE
		copy_to_cpu_                = copy_to_cpu;
		redirect_to_cpu_            = redirect_to_cpu;
		cpu_reason_                 = cpu_reason_code;
		copp_meter_id_              = copp_meter_id;
#endif

		hdr.transport.nsh_type1.sap       = (bit<16>)sap; // 16 bits
		hdr.transport.nsh_type1.vpn       = (bit<16>)vpn; // 16 bits
		hdr.transport.nsh_type1.spi       = spi;          // 24 bits
		hdr.transport.nsh_type1.si        = si;           //  8 bits
		ig_md.nsh_md.si_predec            = si_predec;    //  8 bits
	}

	// --------------------------

	table port_mapping {
		key = {
			ig_md.port : exact;
			hdr.cpu.isValid() : exact;
//			hdr.cpu.ingress_port : exact; // DEREK: IS THIS NEEDED / WHAT IS IT FOR?

			hdr.transport.nsh_type1.isValid() : exact;
		}

		actions = {
			set_port_properties_with_nsh;        // {nsh, cpu} = {0, 0}
			set_port_properties_without_nsh;     // {nsh, cpu} = {1, 0}
			set_cpu_port_properties_with_nsh;    // {nsh, cpu} = {0, 1}
			set_cpu_port_properties_without_nsh; // {nsh, cpu} = {1, 1}
		}

		size = port_table_size * 4; // derek: was 2 in switch, but doubling to 4 because we added nsh valid to it.
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
		valid_cpu = false;
/*
		switch (port_mapping.apply().action_run) {
			set_port_properties : {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.transport.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
		}
*/
		if(port_mapping.apply().hit) {
			if(hdr.cpu.isValid()) {
				cpu_to_bd_mapping.apply();
			} else {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.transport.vlan_tag[0].isValid()) {
#if __TARGET_TOFINO__ == 2
// derek: removing this for tofino 1, because it causes a bunch of valids to not fit (compiler bug?)
						vlan_to_bd_mapping.apply();
#endif
					}
				}
			}
		}

#ifdef BUG_10933_WORKAROUND
		if(valid_cpu == true) {
			if(hdr.transport.ethernet.isValid()) {
				hdr.transport.ethernet.ether_type = hdr.cpu.ether_type; // Wants to be done in parser (see bf-case 10933)
			} else {
				hdr.outer.ethernet.ether_type = hdr.cpu.ether_type; // Wants to be done in parser (see bf-case 10933)
			}
		}
#endif

#ifdef MIRROR_INGRESS_PORT_ENABLE
		port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, SWITCH_CPU_REASON_IG_PORT_MIRRROR, ig_md.cpu_reason);
#endif

		// derek: this copy-to-cpu feature was added here, because port mirroring
		// (above) is not fitting....
#ifdef CPU_PORT_INGRESS_ENABLE
		if(copy_to_cpu_ == true) {
			copy_to_cpu_process_results(cpu_reason_, copp_meter_id_);
		} else if(redirect_to_cpu_ == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0b1;
			copy_to_cpu_process_results(cpu_reason_, copp_meter_id_);
		}
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

	action set_lag_port(switch_port_t port) {
		egress_port = port;
	}







	action lag_miss() { }

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

	action port_normal(
		switch_port_lag_index_t port_lag_index
	) {
		eg_md.port_lag_index = port_lag_index;
	}

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
/*
		hdr.cpu.egress_queue = 0;
		hdr.cpu.tx_bypass = 0;
		hdr.cpu.capture_ts = 0;
		hdr.cpu.reserved = 0;
*/
		// Both these line are here instead of parser out due to compiler... "error: Field is
		// extracted in the parser into multiple containers, but the container
		// slices after the first aren't byte aligned"
		hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
		hdr.cpu.port_lag_index = (bit<16>) eg_md.port_lag_index;
/*
		hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
		hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
		hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
*/
#ifdef CPU_FABRIC_HEADER_ENABLE
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN;
#else
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN2;
#endif
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
		port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror, SWITCH_CPU_REASON_EG_PORT_MIRRROR, eg_md.cpu_reason);
#endif
	}
}
