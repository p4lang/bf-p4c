
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

#ifndef _P4_REWRITE_
#define  _P4_REWRITE_

#include "l2.p4"

control Rewrite(inout switch_header_transport_t hdr,
                inout switch_egress_metadata_t eg_md,
				inout switch_tunnel_metadata_t tunnel
)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t bd_table_size) {

//  EgressBd(bd_table_size) egress_bd;
    switch_smac_index_t smac_index;

	// ---------------------------------------------
	// Table: Nexthop Rewrite
	// ---------------------------------------------

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE

        tunnel.type = type;
#endif
    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {

        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id, bit<8> flow_id) {
#ifdef TUNNEL_ENABLE
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        tunnel.type = type;
        tunnel.id = id;
		tunnel.flow_id = flow_id;
#endif
    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {
#ifdef TUNNEL_ENABLE

        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
        tunnel.type = type;
#endif
    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE

        hdr.ethernet.dst_addr = dmac;
        tunnel.type = type;
//      eg_md.bd = (switch_bd_t) eg_md.vrf;
#endif
    }

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

	// ---------------------------------------------
	// Table: SMAC Rewrite
	// ---------------------------------------------
/*
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
    }
*/
	// ---------------------------------------------
	// Apply
	// ---------------------------------------------

    apply {
        smac_index = 0;

        nexthop_rewrite.apply();

//      egress_bd.apply(hdr, eg_md.bd,                          eg_md.pkt_src,
//          smac_index);

//      smac_rewrite.apply();
    }
}

#endif /* _P4_REWRITE_ */
