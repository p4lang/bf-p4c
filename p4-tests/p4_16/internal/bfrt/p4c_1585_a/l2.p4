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
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#ifndef _P4_L2_
#define _P4_L2_

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param ig_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
//-----------------------------------------------------------------------------
control IngressSTP(in switch_ingress_metadata_t ig_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
    // This register is used to check the stp state of the ingress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the indes.
    const bit<32> stp_state_size = 1 << 19;
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    table mstp {
        key = {
            ig_md.port : exact;
            stp_md.group: exact;
        }

        actions = {
            NoAction;
            set_stp_state;
        }

        size = table_size;
        const default_action = NoAction;
    }

    apply {
#ifdef STP_ENABLE
        if (!BYPASS(STP)) {
            if (multiple_stp) {
                mstp.apply();
            } else {
                // First 4K BDs which are reserved for VLANs
                if (ig_md.bd[15:12] == 0) {
                    bit<32> stp_hash_ = hash.get({ig_md.bd[11:0], ig_md.port[6:0]});
                    stp_md.state_ = (switch_stp_state_t) stp_check.execute(stp_hash_);
                }
            }
        }
#endif /* STP_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param port : Egress port.
// @param bd : Egress BD.
// @param stp_state : Spanning tree state.
//-----------------------------------------------------------------------------
control EgressSTP(in switch_port_t port, in switch_bd_t bd, inout bool stp_state) {
    // This register is used to check the stp state of the egress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the index.
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
#ifdef STP_ENABLE
        // First 4K BDs which are reserved for VLANs
        if (bd[15:12] == 0) {
            bit<32> stp_hash_ = hash.get({bd[11:0], port[6:0]});
            stp_state = (bool) stp_check.execute(stp_hash_);
        }
#endif /* STP_ENABLE */
    }
}


//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param ig_md : Ingress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
// - Trigger a new MAC learn if Spannig tree state is LEARNING (if enabled).
//-----------------------------------------------------------------------------
control SMAC(in mac_addr_t src_addr,
             inout switch_ingress_metadata_t ig_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
    // local variables for MAC learning
    bool src_miss;
    switch_ifindex_t src_move;

    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(switch_ifindex_t ifindex) {
        src_move = ig_md.ifindex ^ ifindex;
    }

    table smac {
        key = {
            ig_md.bd : exact;
            src_addr : exact;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = table_size;
        idle_timeout = true;
    }

    action notify() {
        digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
        ig_md.learning.digest.bd = ig_md.bd;
        ig_md.learning.digest.src_addr = src_addr;
        ig_md.learning.digest.ifindex = ig_md.ifindex;
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
            ig_md.stp.state_ : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
    }


    apply {
        if (!BYPASS(SMAC)) {
	        smac.apply();
        }

        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

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
control DMAC_t(
        in mac_addr_t dst_addr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control DMAC(
        in mac_addr_t dst_addr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size) {

    action dmac_miss() {
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
    }

    action dmac_hit(switch_ifindex_t ifindex,
                    switch_port_lag_index_t port_lag_index) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
    }

    action dmac_multicast(switch_mgid_t index) {
        ig_intr_md_for_tm.mcast_grp_b = index;
    }

    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
    }

    action dmac_drop() {
        //TODO(msharif): Drop the packet.
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
            dmac_drop;
        }

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {
        if (!BYPASS(L2)) {
            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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
        size = table_size;
        counters = stats;
    }

    apply {
        bd_stats.apply();
    }
}

control EgressBd(in switch_header_t hdr,
                 in switch_bd_t bd,
                 in switch_pkt_type_t pkt_type,
                 out switch_bd_label_t label,
                 out switch_smac_index_t smac_idx,
                 out switch_mtu_t mtu_idx)(
                 switch_uint32_t table_size,
                 switch_uint32_t stats_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = stats_table_size;
        counters = stats;
    }

    action set_bd_properties(switch_bd_label_t bd_label,
                             switch_smac_index_t smac_index,
                             switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
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
        bd_mapping.apply();
        bd_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanDecap(inout switch_header_t hdr, in switch_port_t port) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    table vlan_decap {
        key = {
            port : ternary;
            hdr.vlan_tag[0].isValid() : exact;
        }

        actions = {
            NoAction;
            remove_vlan_tag;
        }

        const default_action = NoAction;
    }

    apply {
#ifdef QINQ_ENABLE
        vlan_decap.apply();
#else
        // Remove the vlan tag by default.
        if (hdr.vlan_tag[0].isValid()) {
            hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
            hdr.vlan_tag[0].setInvalid();
        }
#endif
    }
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param port_lag_index : Port/lag index.
// @param bd : Bridge domain
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanXlate(inout switch_header_t hdr,
                  in switch_port_lag_index_t port_lag_index,
                  in switch_bd_t bd)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }

    action set_vlan_tagged(vlan_id_t vid) {
#ifdef QINQ_ENABLE
        hdr.vlan_tag.push_front(1);
#else
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
#endif
        // hdr.vlan_tag[0].pcp =  0;
        // hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid =  vid;
        hdr.ethernet.ether_type = ETHERTYPE_VLAN;
    }

    table port_bd_to_vlan_mapping {
        key = {
            port_lag_index : exact;
            bd : exact;
        }

        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
    }

    table bd_to_vlan_mapping {
        key = { bd : exact; }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = bd_table_size;
    }

    action set_type_vlan() {
         hdr.ethernet.ether_type = ETHERTYPE_VLAN;
     }

    action set_type_qinq() {
        hdr.ethernet.ether_type = ETHERTYPE_QINQ;
    }

    action set_type_vlan_nsh() {
        hdr.ethernet_underlay.ether_type = ETHERTYPE_VLAN;
    }

    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;

            hdr.vlan_tag_underlay.isValid() : exact;
        }

        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;

            set_type_vlan_nsh;
        }

        const default_action = NoAction;
        const entries = {
//          (true, false) : set_type_vlan();
//          (true, true) : set_type_qinq();

            (true, false, false) : set_type_vlan();
            (true, true,  false) : set_type_qinq();

            (_,    _,     true ) : set_type_vlan_nsh();
        }
    }

    apply {
        if (!port_bd_to_vlan_mapping.apply().hit) {
            bd_to_vlan_mapping.apply();
        }

#ifdef QINQ_ENABLE
        set_ether_type.apply();
#endif
    }
}

#endif /* _P4_L2_ */
