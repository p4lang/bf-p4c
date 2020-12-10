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
                switch_uint32_t ecmp_table_size,
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
    action set_nexthop_properties(
		switch_port_lag_index_t port_lag_index,
        switch_bd_t bd
	) {
        ig_md.egress_port_lag_index = port_lag_index;
    }

    action set_nexthop_properties_post_routed_flood(
		switch_bd_t bd,
		switch_mgid_t mgid
	) {
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }
/*
    action set_nexthop_properties_glean(
	) {
        ig_md.flags.glean = true;
    }
*/
    action set_nexthop_properties_drop(
	) {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }
/*
    action set_ecmp_properties(
		switch_port_lag_index_t port_lag_index,
        switch_bd_t bd,
        switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd);
    }

    action set_ecmp_properties_drop(
	) {
        set_nexthop_properties_drop();
    }

    action set_ecmp_properties_post_routed_flood(
        switch_bd_t bd,
        switch_mgid_t mgid,
        switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(
		switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }
*/
    action set_nexthop_properties_tunnel(
		switch_bd_t bd,
		switch_tunnel_index_t tunnel_index
	) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel_0.index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
    }
/*
    action set_ecmp_properties_tunnel(
		switch_bd_t bd,
		switch_tunnel_index_t tunnel_index,
		switch_nexthop_t nexthop_index
	) {
        set_nexthop_properties_tunnel(bd, tunnel_index);
        ig_md.nexthop = nexthop_index;
    }
*/
/*
    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_ecmp_properties_tunnel;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }
*/
#ifdef INIT_BANNED_ON_NEXTHOP
    @no_field_initialization
#endif
    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
//          set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_nexthop_properties_tunnel;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {






        switch(nexthop.apply().action_run) {
//          NoAction : { ecmp.apply(); }
            default : {}
        }


    }
}

// ----------------------------------------------------------------------------
// OuterFib (aka Outer Nexthop)
// ----------------------------------------------------------------------------

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

    action set_nexthop_properties(
		switch_port_lag_index_t port_lag_index,
        switch_outer_nexthop_t nexthop_index
	) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel_0.index : exact;
//          ig_md.hash[31:0] : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
//      implementation = ecmp_selector;
        size = fib_table_size;
    }

    apply {
#ifdef TUNNEL_ENABLE
        fib.apply();
#endif
    }
}
