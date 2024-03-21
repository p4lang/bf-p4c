/*******************************************************************************
 * INTEL CORPORATION CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2021 Intel Corporation
 * All Rights Reserved.
 *
 * This software and the related documents are Intel copyrighted materials,
 * and your use of them is governed by the express license under which they
 * were provided to you ("License"). Unless the License provides otherwise,
 * you may not use, modify, copy, publish, distribute, disclose or transmit this
 * software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or
 * implied warranties, other than those that are expressly stated in the License.
 *
 ******************************************************************************/

#include "t5na.p4"

struct metadata_t {
    bit<32>     f1;
    bit<32>     f2;
    PortId_t    ingress_port;
}

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers_t {
    data_h      data;
}


// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
       packet_in packet,
       out headers_t hdrs,
       out metadata_t meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        packet.extract(hdrs.data);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        in headers_t hdrs,
        inout metadata_t meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action bridge_add_ig_intr_md() {
        meta.ingress_port = ig_intr_md.ingress_port;
    }

    action bridge_add_meta(bit<32> dst_mac_addr_low,
                           bit<32> src_mac_addr_low) {
        meta.f1 = dst_mac_addr_low;
        meta.f2 = src_mac_addr_low;
    }

    table set_bridged_meta {
        actions = {
            NoAction;
            bridge_add_ig_intr_md;
            bridge_add_meta;
        }

        default_action = NoAction;
    }

    action set_output_port(PortId_t port_id) {
        ig_tm_md.ucast_egress_port = port_id;
    }

    table output_port {
        actions = {
            set_output_port;
        }
    }

    apply {
        set_bridged_meta.apply();
        output_port.apply();
    }
}

// ---------------------------------------------------------------------------
// Egress
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout headers_t hdrs,
        inout metadata_t meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {
        if (meta.ingress_port != eg_intr_md.egress_port) {
            hdrs.data.f1 = meta.f1;
            hdrs.data.f2 = meta.f2;
        }
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out packet,
                             inout headers_t hdrs,
                             in metadata_t meta,
                             in egress_intrinsic_metadata_t eg_intr_md,
                             in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
        packet.emit(hdrs);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;


Switch(pipe) main;
