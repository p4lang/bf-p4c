/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.

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

#include "headers.p4"

control PortMapping(
        in PortId_t port,
        in vlan_tag_h vlan_tag,
        out bd_t bd_,
        out vrf_t vrf_,
        out ifindex_t ifindex_)(
        bit<32> port_table_size,
        bit<32> port_vlan_table_size,
        bit<32> bd_table_size) {

    ActionProfile(bd_table_size) bd_action_profile;

    action set_port_attributes(ifindex_t ifindex) {
        ifindex_ = ifindex;
    }

    table port_mapping {
        key = { port : exact; }
        actions = { set_port_attributes; }
        size = port_table_size;
    }

    action port_vlan_miss() {}

    action set_bd_attributes(bd_t bd, vrf_t vrf) {
        bd_ = bd;
        vrf_ = vrf;
    }

    table port_vlan_to_bd_mapping {
        key = {
            ifindex_ : exact;
            vlan_tag.vid : exact;
        }

        actions = {
            port_vlan_miss;
            set_bd_attributes;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = port_vlan_table_size;
    }

    table port_to_bd_mapping {
        key = { ifindex_ : exact; }

        actions = {
            port_vlan_miss;
            set_bd_attributes;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = port_table_size;
    }

    apply {
        port_mapping.apply();

        if (vlan_tag.isValid()) {
            if(!port_vlan_to_bd_mapping.apply().hit) {
                port_to_bd_mapping.apply();
            }
        } else {
            port_to_bd_mapping.apply();
        }
    }
}

control MAC(
    in mac_addr_t src_addr,
    in mac_addr_t dst_addr,
    in bd_t bd,
    in ifindex_t ingress_ifindex,
    out ifindex_t egress_ifindex)(
    bit<32> mac_table_size) {

    // local variables for MAC learning
    bool src_miss;
    ifindex_t src_move;

//-----------------------------------------------------------------------------
// Source MAC lookup
// key : ingress BD, source MAC address.
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a
// different interface.
//-----------------------------------------------------------------------------
    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(ifindex_t ifindex) {
        src_move = ingress_ifindex ^ ifindex;
    }

    table smac {
        key = {
            bd : exact;
            src_addr : exact;
        }

        actions = {
            smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = mac_table_size;
    }

//-----------------------------------------------------------------------------
// Destination MAC lookup
// key: ingress BD, destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//-----------------------------------------------------------------------------
    action dmac_miss() {
        egress_ifindex = 16w0xffff;
    }

    action dmac_hit(ifindex_t ifindex) {
        egress_ifindex = ifindex;
    }

    table dmac {
        key = {
            bd : exact;
            dst_addr : exact;
        }

        actions = {
            dmac_miss;
            dmac_hit;
        }

        const default_action = dmac_miss;
        size = mac_table_size;
    }

//-----------------------------------------------------------------------------
// MAC learning
// - Generate a MAC learning digest if MAC address is unknown or attached to a
// different interface or if the Spannig tree state is LEARNING.
//-----------------------------------------------------------------------------
    action notify() {
        //TODO
    }

    table mac_learning {
        key = {
            src_miss : ternary;
            src_move : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
    }

    apply {
	    smac.apply();
        dmac.apply();
        mac_learning.apply();
    }
}


control FIB(in ipv4_addr_t dst_addr,
            in vrf_t vrf,
            out nexthop_t nexthop)(
            bit<32> host_table_size,
            bit<32> lpm_table_size) {

    action fib_hit(nexthop_t nexthop_index) {
        nexthop = nexthop_index;
    }

    action fib_miss() { }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)
    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}


control Nexthop(in nexthop_t nexthop_index,
                in bit<32> hash,
                out bd_t bd_,
                out mac_addr_t dmac_)(
                bit<32> nexthop_table_size) {
    Hash<bit<14>>(HashAlgorithm_t.IDENTITY) sel_hash;
    ActionSelector(
        1024, sel_hash, SelectorMode_t.FAIR) ecmp_selector;

    action set_nexthop_attribures(bd_t bd, mac_addr_t dmac) {
        bd_ = bd;
        dmac_ = dmac;
    }

    table ecmp {
        key = {
            nexthop_index : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_nexthop_attribures;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
        implementation = ecmp_selector;
    }

    table nexthop {
        key = {
            nexthop_index : exact;
        }

        actions = {
            NoAction;
            set_nexthop_attribures;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
        }
    }
}

control Lag(in ifindex_t ifindex,
            in bit<32> hash,
            out PortId_t egress_port) {
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) sel_hash;
    ActionSelector(1024, sel_hash, SelectorMode_t.FAIR) lag_selector;

    action set_port(PortId_t port) {
        egress_port = port;
    }

    action lag_miss() { }

    table lag {
        key = {
            ifindex : exact;
            hash : selector;
        }

        actions = {
            lag_miss;
            set_port;
        }

        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }

    apply {
        lag.apply();
    }
}


