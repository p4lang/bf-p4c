/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

struct header_t {
    ethernet_h ethernet;
}

struct metadata_t {}

struct pair {
    bit<32>     first;
    bit<32>     second;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    const bit<32> bool_register_table_size = 1 << 10;
    Register<bit<1>, bit<32>>(bool_register_table_size, 0) bool_register_table;
    // A simple one-bit register action that returns the inverse of the value
    // stored in the register table.
    RegisterAction<bit<1>, bit<32>, bit<1>>(bool_register_table) bool_register_table_action = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    Register<pair, bit<32>>(32w1024) test_reg;
    // A simple dual-width 32-bit register action that will increment the two
    // 32-bit sections independently and return the value of one half before the
    // modification.
    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_action = {
        void apply(inout pair value, out bit<32> read_value){
            read_value = value.second;
            value.first = value.first + 1;
            value.second = value.second + 100;
        }
    };

    action register_action(bit<32> idx) {
        test_reg_action.execute(idx);
    }

    table reg_match {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            register_action;
        }
        size = 1024;
    }

    DirectRegister<bit<32>>() test_reg_dir;
    // A simple dual-width 32-bit register action that will increment the two
    // 32-bit sections independently and return the value of one half before the
    // modification.
    DirectRegisterAction<bit<32>, bit<32>>(test_reg_dir) test_reg_dir_action = {
        void apply(inout bit<32> value, out bit<32> read_value){
            read_value = value;
            //if (value  < 2147483648) {
            if (value - 2147483648 < 0) { // expect error: "constant value .* is out of range .* for stateful ALU"       
                value = value + 1;
            }
        }
    };

    action register_action_dir() {
        test_reg_dir_action.execute();
    }

    table reg_match_dir {
        key = {
            hdr.ethernet.src_addr[19:0] : exact;
        }
        actions = {
            register_action_dir;
        }
        size = 1024*1024;
        registers = test_reg_dir;
    }

    apply {
        //reg_match.apply();
        reg_match_dir.apply();
        bit<32> idx_ = 1;
        // Purposely assigning bypass_egress field like this so that the
        // compiler generates a match table internally for this register
        // table. (Note that this internally generated table is not
        // published in bf-rt.json but is only published in context.json)
        //ig_tm_md.bypass_egress = bool_register_table_action.execute(idx_);
        // Send the packet back where it came from.
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

parser EmptyEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
