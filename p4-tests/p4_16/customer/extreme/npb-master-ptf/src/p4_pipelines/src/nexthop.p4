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

#ifndef _P4_NEXTHOP_
#define _P4_NEXTHOP_

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param ig_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_ingress_metadata_t ig_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_group_table_size,
                switch_uint32_t ecmp_selection_table_size) {
/*
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
#ifdef RESILIENT_ECMP_HASH_ENABLE
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.RESILIENT,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#else
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#endif
*/
    DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count();

    }

    // IP Nexthop
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd
    ) {
        stats.count();
        ig_md.egress_port_lag_index = port_lag_index;
    }

    // Post Route Flood
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        stats.count();
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }
/*
    // Glean
    action set_nexthop_properties_glean() {
        stats.count();
        ig_md.flags.glean = true;
    }
*/
    // Drop
    action set_nexthop_properties_drop(
    ) {
        stats.count();
//      ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

#ifdef TUNNEL_ENABLE
  #ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
    // Tunnel Encap
    action set_nexthop_properties_tunnel(
        switch_bd_t bd,
        switch_tunnel_ip_index_t tunnel_index
    ) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        stats.count();
        ig_md.tunnel_0.dip_index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
		ig_md.tunnel_nexthop = ig_md.nexthop; // derek: added 6-28-21 to match latest switch.p4 code.
    }
  #else
    // Tunnel Encap
    // use this code for combined nexthop and outer-nexthop tables.
    action set_nexthop_properties_tunnel(
        switch_bd_t bd,
        switch_tunnel_ip_index_t tunnel_index,

        switch_port_lag_index_t port_lag_index, // added
        switch_tunnel_nexthop_t nexthop_index // added
    ) {
        stats.count();
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel_0.dip_index = tunnel_index;
//      ig_md.egress_port_lag_index = 0; // removed

        ig_md.tunnel_nexthop = nexthop_index; // added
        ig_md.egress_port_lag_index = port_lag_index; // added
    }
  #endif
#endif

#ifdef INIT_BANNED_ON_NEXTHOP
    @no_field_initialization
#endif
    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            no_action;
            set_nexthop_properties;
            set_nexthop_properties_drop;
//          set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;

            set_nexthop_properties_tunnel;

        }

        const default_action = no_action;
        size = nexthop_table_size;
        counters = stats;
    }

    apply {
        switch(nexthop.apply().action_run) {
            default : {}
        }
    }
}

#ifdef TUNNEL_ENABLE
//--------------------------------------------------------------------------
// Route lookup and ECMP resolution for Tunnel Destination IP
//-------------------------------------------------------------------------
control OuterFib(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {

//  Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
//  ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
//  ActionSelector(ecmp_action_profile,
//                 selector_hash,
//                 SelectorMode_t.FAIR,
//                 ECMP_MAX_MEMBERS_PER_GROUP,
//                 ecmp_group_table_size) ecmp_selector;

    DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action(
    ) {
        stats.count();
    }

    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_tunnel_nexthop_t nexthop_index
    ) {
        stats.count();
        ig_md.tunnel_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel_0.dip_index : exact @name("ig_md.tunnel_0.index");
//          ig_md.hash[31:16] : selector;
        }

        actions = {
            no_action;
            set_nexthop_properties;
        }

        const default_action = no_action;
//      implementation = ecmp_selector;
        size = fib_table_size;
        counters = stats;
    }

    apply {
        fib.apply();
    }
}
#endif

#endif
