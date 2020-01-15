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
 ******************************************************************************/


/* ORIG CUSTOMER p4-14 code:

header_type udf_cntr_t
{
    fields
    {
        repeat: 32; // Length of the inner loop
        step: 32; // Increment or decrement value of inner loop
        nested_repeat: 32; // Length of the outer loop
        nested_step: 32; // Increment or decrement outer loop
        bit_mask: 2; // 8, 16, 24, or 32 bit masks
        final_value: 32; // intermediate value for pipeline
        nested_final_value: 32; // intermediate value for pipeline
        stutter: 32; // stutter value for inner loop
        enable: 1; // Inidcates to MAUs that UDF is enabled
        rollover_true: 4;
        update_inner_true: 4;
    }
}

metadata udf_cntr_t udf1_cntr;

register udf1_cntr_conditional_reg
{
    width: 64;
    instance_count: STREAM_TBL_SZ;
}

blackbox stateful_alu udf1_cntr_compute_conditional
{
    reg: udf1_cntr_conditional_reg;
    // UDF inner loop pattern is not finished
    condition_lo: register_lo + 1 <= udf1_cntr.repeat;
    // UDF inner loop stutter is not finished
    condition_hi: register_hi + 1 <= udf1_cntr.stutter;
    // If inner loop pattern is not finished and stutter is finished
    update_lo_1_predicate: condition_lo and not condition_hi;
    // ... then increment inner loop counter
    update_lo_1_value: register_lo + 1;
    // If inner loop pattern is finished and stutter is finished 
    update_lo_2_predicate: not condition_lo and not condition_hi;
    // ... then reset inner loop counter 
    update_lo_2_value: 0;
    // If stutter is not finished
    update_hi_1_predicate: condition_hi;
    //... then increment stutter counter
    update_hi_1_value: register_hi + 1;
    // Else if stutter is finished 
    update_hi_2_predicate: not condition_hi;
    // Reset stutter counter
    update_hi_2_value: 0;
    // Predicate is a four bit value encoding both condition_lo and condition_hi
    // See Stateful Processing in 10K Series PDF Slide 24 for details 
    output_value: predicate;
    output_dst: udf1_cntr.update_inner_true;
}

action do_udf1_cntr_compute_conditional()
{
    udf1_cntr_compute_conditional.execute_stateful_alu(meta.stream);
}

table compute_conditional_udf1_cntr_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_udf1_cntr_compute_conditional;
    }
    size: 1;
}
*/

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

#include "util.h"
#include "simple_packet_parser.h"

///////////////////////////// Begin Customer code ////////////////////////////
struct udf_cntr_t {
    bit<32> repeat;
    bit<32> step;
    bit<32> nested_repeat;
    bit<32> nested_step;
    bit<32> bit_mask;
    bit<32> final_value;
    bit<32> nested_final_value;
    bit<32> stutter;
    bit<1>  enable;
    bit<4>  rollover_true;
    bit<4>  update_inner_true;
}

struct metadata_t {
      udf_cntr_t udf1_cntr;
      bit <5> stream;
}
///////////////////////////// End Customer code ////////////////////////////

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
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
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
    RegisterAction<bit<1>, bit<32>, bit<1>>(bool_register_table) bool_register_table_action = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    Register<pair, bit<32>>(32w1024) test_reg;
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

    DirectRegister<pair>() test_reg_dir;
    DirectRegisterAction<pair, bit<32>>(test_reg_dir) test_reg_dir_action = {
        void apply(inout pair value, out bit<32> read_value){
            read_value = value.second;
            value.first = value.first + 1;
            value.second = value.second + 100;
        }
    };

    action register_action_dir() {
        test_reg_dir_action.execute();
    }

    table reg_match_dir {
        key = {
            hdr.ethernet.src_addr : exact;
        }
        actions = {
            register_action_dir;
        }
        size = 1024;
        registers = test_reg_dir;
    }


///////////////////////////// Begin Customer code ////////////////////////////
    Register<pair, bit<32>>(32,{0,0}) udf1_cntr_conditional_reg;

    RegisterAction<pair, bit<32>, bit<32>>(udf1_cntr_conditional_reg) udf1_cntr_compute_conditional = {
        void apply(inout pair value, out bit<32> rv) {
            rv = 32w0;
            pair in_value;
            in_value = value;
            rv = 32w1; // TODO throws "[--Werror=legacy] error: can't output 1 from a RegisterAction"
            if (in_value.second + 32w1 <= ig_md.udf1_cntr.stutter) 
                value.second = in_value.second + 32w1;
            if (!(in_value.second + 32w1 <= ig_md.udf1_cntr.stutter)) 
                value.second = (bit<32>)0;
            if (in_value.first + 32w1 <= ig_md.udf1_cntr.repeat && !(in_value.second + 32w1 <= ig_md.udf1_cntr.stutter)) 
                value.first = in_value.first + 32w1;
            if (!(in_value.first + 32w1 <= ig_md.udf1_cntr.repeat) && !(in_value.second + 32w1 <= ig_md.udf1_cntr.stutter)) 
                value.first = (bit<32>)0;
        }
    };

    action do_udf1_cntr_compute_conditional() {
        ig_md.udf1_cntr.update_inner_true = (bit<4>)udf1_cntr_compute_conditional.execute((bit<32>)ig_md.stream);
    }

    table compute_conditional_udf1_cntr_tbl {
        actions = {
            do_udf1_cntr_compute_conditional;
        }
        default_action = do_udf1_cntr_compute_conditional;
        size = 1;
    }
///////////////////////////// END Customer code ////////////////////////////

    apply {
        reg_match.apply();
        reg_match_dir.apply();
        compute_conditional_udf1_cntr_tbl.apply(); // <============== CUSTOMER CODE
        bit<32> idx_ = 1;
        // Purposely assigning bypass_egress field like this so that the
        // compiler generates a match table internally for this register
        // table. (Note that this internally generated table is not
        // published in bf-rt.json but is only published in context.json)
        ig_tm_md.bypass_egress = bool_register_table_action.execute(idx_);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser<header_t, metadata_t>(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe;

Switch(pipe) main;
