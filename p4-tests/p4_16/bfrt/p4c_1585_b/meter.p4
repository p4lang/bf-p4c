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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#ifndef _P4_METER_
#define _P4_METER_

//-------------------------------------------------------------------------------------------------
// Ingress Policer
//
// Monitors the data rate for a particular class of service and drops the traffic
// when the rate exceeds a user-defined thresholds.
//
// @param ig_md : Ingress metadata fields.
// @param qos_md : QoS related metadata fields.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the ingress policer table.
//-------------------------------------------------------------------------------------------------
control IngressPolicer(in switch_ingress_metadata_t ig_md,
                       inout switch_qos_metadata_t qos_md,
                       out bool flag)(
                       switch_uint32_t table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    // Requires 3 entries per meter index for unicast/broadcast/multicast packets.
    //XXX compiler fails with error : Cannot evaluate initializer to a compiler-time constant.
    // const switch_uint32_t meter_action_table_size = 3 * table_size;

    action meter_deny() {
        stats.count();
        flag = true;
    }

    action meter_permit() {
        stats.count();
        flag = false;
    }

    table meter_action {
        key = {
            qos_md.color : exact;
            qos_md.meter_index : exact;
        }

        actions = {
            meter_permit;
            meter_deny;
        }

        const default_action = meter_permit;
        // size = meter_action_table_size;
        counters = stats;
    }

    action set_color() {
        qos_md.color = (bit<2>) meter.execute();
    }

    table meter_index {
        key = {
            qos_md.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            set_color;
        }

        const default_action = NoAction;
        size = table_size;
        meters = meter;
    }

    apply {
#if defined(INGRESS_POLICER_ENABLE)
        if (!BYPASS(POLICER))
            meter_index.apply();

        if (!BYPASS(POLICER))
            meter_action.apply();
#endif
    }
}

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param ig_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table.
//-------------------------------------------------------------------------------------------------
control StormControl(in switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=512) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    action count() {
        storm_control_stats.count();
        flag = false;
    }

    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    table stats {
        key = {
            color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        color = (bit<2>) meter.execute(index);
    }

    //TODO(msharif) : Only apply this for unknown unicast packets (SWI-1610)
    table storm_control {
        key =  {
            ig_md.port : exact;
            pkt_type : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
#ifdef STORM_CONTROL_ENABLE
        if (!BYPASS(STORM_CONTROL))
            storm_control.apply();

        if (!BYPASS(STORM_CONTROL))
            stats.apply();
#endif
    }
}

#endif /* _P4_METER_ */
