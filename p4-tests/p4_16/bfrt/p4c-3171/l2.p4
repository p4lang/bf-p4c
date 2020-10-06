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

#ifndef _P4_L2_
#define _P4_L2_

//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on bd and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//
// @param dst_addr : destination MAC address.
// @param ig_md : Ingess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------
//control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
	in mac_addr_t dst_addr,
	inout switch_ingress_metadata_t ig_md
) (
	switch_uint32_t table_size
) {

	bool copp_enable_;
	switch_copp_meter_id_t copp_meter_id_;

	//-------------------------------------------------------------

	action dmac_miss(bool copp_enable, switch_copp_meter_id_t copp_meter_id) {
		ig_md.egress_port_lag_index = SWITCH_FLOOD;
		ig_md.flags.dmac_miss = true;

		copp_enable_ = copp_enable;
		copp_meter_id_ = copp_meter_id;
	}

	action dmac_hit(switch_port_lag_index_t port_lag_index, bit<4> port_lag_hash_sel, bool copp_enable, switch_copp_meter_id_t copp_meter_id
	) {
		ig_md.egress_port_lag_index = port_lag_index;
		ig_md.egress_port_lag_hash_sel = port_lag_hash_sel;

		copp_enable_ = copp_enable;
		copp_meter_id_ = copp_meter_id;
	}

	action dmac_multicast(switch_mgid_t index, bool copp_enable, switch_copp_meter_id_t copp_meter_id
	) {
		ig_md.multicast.id = index;
		ig_md.egress_port_lag_index = 0; // derek added
		ig_md.egress_port_lag_hash_sel = 0; // derek added

		copp_enable_ = copp_enable;
		copp_meter_id_ = copp_meter_id;
	}

	action dmac_redirect(switch_nexthop_t nexthop_index, bool copp_enable, switch_copp_meter_id_t copp_meter_id
	) {
		ig_md.nexthop = nexthop_index;

		copp_enable_ = copp_enable;
		copp_meter_id_ = copp_meter_id;
	}

	table dmac {
		key = {
			ig_md.bd : exact;
			dst_addr : exact;
		}

		actions = {
			dmac_miss;
			dmac_hit;
			dmac_multicast;
			dmac_redirect;
		}

		const default_action = dmac_miss(false, 0);
		size = table_size;
	}

	//-------------------------------------------------------------

	apply {
		ig_md.flags.dmac_miss = false;

		if (!INGRESS_BYPASS(L2)) {
			dmac.apply();
		}

#ifdef CPU_ENABLE
		ig_md.copp_enable = copp_enable_;
        ig_md.copp_meter_id = copp_meter_id_;
#endif
	}
}

//-----------------------------------------------------------------------------

control IngressBd(
	in switch_bd_t bd,
	in switch_pkt_type_t pkt_type
) (
	switch_uint32_t table_size
) {

	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	action count() { stats.count(); }

	table bd_stats {
		key = {
			bd : exact;
			pkt_type : exact;
		}

		actions = {
			count;
			@defaultonly NoAction;
		}

		const default_action = NoAction;

		// 3 entries per bridge domain for unicast/broadcast/multicast packets.
		size = 3 * table_size;
		counters = stats;
	}

	apply {
		bd_stats.apply();
	}
}

//-----------------------------------------------------------------------------

control EgressBd(
	in switch_header_transport_t hdr,
	in switch_bd_t bd,
	in switch_pkt_src_t pkt_src,
	out switch_smac_index_t smac_idx
) (
	switch_uint32_t table_size
) {
/*
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	action count() {
		stats.count();
	}

	table bd_stats {
		key = {
			bd : exact;
//          pkt_type : exact;
		}

		actions = {
			count;
			@defaultonly NoAction;
		}

		size = 3 * table_size;
		counters = stats;
	}
*/
	action set_bd_properties(
		switch_smac_index_t smac_index
	) {

		smac_idx = smac_index;

	}

	table bd_mapping {
		key = { bd : exact; }
		actions = {
			NoAction;
			set_bd_properties;
		}

		const default_action = NoAction;
		size = table_size;
	}

	apply {
		smac_idx = 0; // extreme added

		bd_mapping.apply();
//		if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
//			bd_stats.apply();
	}
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanDecap(
	inout switch_header_transport_t hdr,
	in switch_egress_metadata_t eg_md
) {

	// ---------------------
	// Apply
	// ---------------------

	apply {
		if (!EGRESS_BYPASS(REWRITE)) {
			// Remove the vlan tag by default.
			if (hdr.vlan_tag[0].isValid()) {
				hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
				hdr.vlan_tag[0].setInvalid();
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanXlate(
	inout switch_header_transport_t hdr,
	in switch_egress_metadata_t eg_md
) (
	switch_uint32_t bd_table_size,
	switch_uint32_t port_bd_table_size
) {

	action set_vlan_untagged() {
		//NoAction.
	}

















	action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {



		hdr.vlan_tag[0].setValid();
		hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
		hdr.vlan_tag[0].pcp = pcp; // derek: added this here...barefoot set it in qos.p4, which we don't have.
		hdr.vlan_tag[0].cfi = 0;
		hdr.vlan_tag[0].vid =  vid;
		hdr.ethernet.ether_type = ETHERTYPE_VLAN;
	}

	table port_bd_to_vlan_mapping {
		key = {
			eg_md.port_lag_index : exact @name("port_lag_index");
			eg_md.bd : exact @name("bd");
		}

		actions = {
			set_vlan_untagged;
			set_vlan_tagged;
		}

		const default_action = set_vlan_untagged;
		size = port_bd_table_size;
		//TODO : fix table size once scale requirements for double tag is known
	}

	table bd_to_vlan_mapping {
		key = { eg_md.bd : exact @name("bd"); }
		actions = {
			set_vlan_untagged;
			set_vlan_tagged;
		}

		const default_action = set_vlan_untagged;
		size = bd_table_size;
	}





























	apply {
		if (!EGRESS_BYPASS(REWRITE)) {
			if (!port_bd_to_vlan_mapping.apply().hit) {
				bd_to_vlan_mapping.apply();
			}
		}



	}
}

#endif /* _P4_L2_ */
