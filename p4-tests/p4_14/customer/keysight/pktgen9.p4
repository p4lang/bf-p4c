@pragma command_line --disable-parse-max-depth-limit

# 1 "pktgen9.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "pktgen9.p4"
/*------------------------------------------------------------------------
    pktgen9.p4 - Top level file that defines ingress and egress controls

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/constants.p4" 1
/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

// This file is to be kept in precise sync with constants.py




/////////////////////////////////////////////////////////////
// Parser hardware error codes
# 41 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Digest receivers
# 53 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Clone soruces
// (to be used with eg_intr_md_from_parser_aux.clone_src)




/////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Default priorities
# 8 "pktgen9.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/intrinsic_metadata.p4" 1
/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

/********************************************************************************
 *                      Intrinsic Metadata Definition for Tofino                *
 *******************************************************************************/




/* Control signals for the Ingress Parser during parsing (not used in or
   passed to the MAU) */
header_type ingress_parser_control_signals {
    fields {
        priority : 3; // set packet priority
        _pad1 : 5;
        parser_counter : 8; // parser counter
    }
}

@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_prsr_ctrl
header ingress_parser_control_signals ig_prsr_ctrl;


/* Produced by Ingress Parser */
header_type ingress_intrinsic_metadata_t {
    fields {

        resubmit_flag : 1; // flag distinguising original packets
                                        // from resubmitted packets.

        _pad1 : 1;

        _pad2 : 2; // packet version; irrelevant for s/w.

        _pad3 : 3;

        ingress_port : 9; // ingress physical port id.
                                        // this field is passed to the deparser

        ingress_mac_tstamp : 48; // ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
    }
}

@pragma dont_trim
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md.ingress_port
header ingress_intrinsic_metadata_t ig_intr_md;


/* Produced by Packet Generator */
header_type generator_metadata_t {
    fields {

        app_id : 16; // packet-generation session (app) id

        batch_id: 16; // batch id

        instance_id: 16; // instance (packet) id
    }
}

@pragma not_deparsed ingress
@pragma not_deparsed egress
header generator_metadata_t ig_pg_md;


/* Produced by Ingress Parser-Auxiliary */
header_type ingress_intrinsic_metadata_from_parser_aux_t {
    fields {
        ingress_global_tstamp : 48; // global timestamp (ns) taken upon
                                        // arrival at ingress.

        ingress_global_ver : 32; // global version number taken upon
                                        // arrival at ingress.

        ingress_parser_err : 16; // error flags indicating error(s)
                                        // encountered at ingress parser.
    }
}

@pragma pa_fragment ingress ig_intr_md_from_parser_aux.ingress_parser_err
@pragma pa_atomic ingress ig_intr_md_from_parser_aux.ingress_parser_err
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md_from_parser_aux
header ingress_intrinsic_metadata_from_parser_aux_t ig_intr_md_from_parser_aux;


/* Consumed by Ingress Deparser for Traffic Manager (TM) */
header_type ingress_intrinsic_metadata_for_tm_t {
    fields {

        // The ingress physical port id is passed to the TM directly from
        // ig_intr_md.ingress_port

        _pad1 : 7;
        ucast_egress_port : 9; // egress port for unicast packets. must
                                        // be presented to TM for unicast.

        // ---------------------

        drop_ctl : 3; // disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring
        bypass_egress : 1; // request flag for the warp mode
                                        // (egress bypass).
        deflect_on_drop : 1; // request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

        ingress_cos : 3; // ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

        // ---------------------

        qid : 5; // egress (logical) queue id into which
                                        // this packet will be deposited.
        icos_for_copy_to_cpu : 3; // ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

        // ---------------------

        _pad2: 3;

        copy_to_cpu : 1; // request for copy to cpu.

        packet_color : 2; // packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

        disable_ucast_cutthru : 1; // disable cut-through forwarding for
                                        // unicast.
        enable_mcast_cutthru : 1; // enable cut-through forwarding for
                                        // multicast.

        // ---------------------

        mcast_grp_a : 16; // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

        // ---------------------

        mcast_grp_b : 16; // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

        // ---------------------

        _pad3 : 3;
        level1_mcast_hash : 13; // source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

        // ---------------------

        _pad4 : 3;
        level2_mcast_hash : 13; // source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

        // ---------------------

        level1_exclusion_id : 16; // exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

        // ---------------------

        _pad5 : 7;
        level2_exclusion_id : 9; // exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

        // ---------------------

        rid : 16; // L3 replication id for multicast.
                                        // used for pruning.


    }
}

@pragma pa_atomic ingress ig_intr_md_for_tm.ucast_egress_port

@pragma pa_fragment ingress ig_intr_md_for_tm.drop_ctl
@pragma pa_fragment ingress ig_intr_md_for_tm.qid
@pragma pa_fragment ingress ig_intr_md_for_tm._pad2

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_a
@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_a
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_b
@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_b
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_b

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_fragment ingress ig_intr_md_for_tm._pad3

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_fragment ingress ig_intr_md_for_tm._pad4

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_exclusion_id
@pragma pa_fragment ingress ig_intr_md_for_tm.level1_exclusion_id

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_fragment ingress ig_intr_md_for_tm._pad5

@pragma pa_atomic ingress ig_intr_md_for_tm.rid
@pragma pa_fragment ingress ig_intr_md_for_tm.rid

@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md_for_tm
@pragma dont_trim
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.drop_ctl
header ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm;

/* Consumed by Mirror Buffer */
header_type ingress_intrinsic_metadata_for_mirror_buffer_t {
    fields {
        _pad1 : 6;
        ingress_mirror_id : 10; // ingress mirror id. must be presented
                                        // to mirror buffer for mirrored
                                        // packets.
    }
}

@pragma dont_trim
@pragma pa_intrinsic_header ingress ig_intr_md_for_mb
@pragma pa_atomic ingress ig_intr_md_for_mb.ingress_mirror_id
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_mb.ingress_mirror_id
@pragma not_deparsed ingress
@pragma not_deparsed egress
header ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;

/* Produced by TM */
header_type egress_intrinsic_metadata_t {
    fields {

        _pad0 : 7;
        egress_port : 9; // egress port id.
                                        // this field is passed to the deparser

        _pad1: 5;
        enq_qdepth : 19; // queue depth at the packet enqueue
                                        // time.

        _pad2: 6;
        enq_congest_stat : 2; // queue congestion status at the packet
                                        // enqueue time.

        enq_tstamp : 32; // time snapshot taken when the packet
                                        // is enqueued (in nsec).

        _pad3: 5;
        deq_qdepth : 19; // queue depth at the packet dequeue
                                        // time.

        _pad4: 6;
        deq_congest_stat : 2; // queue congestion status at the packet
                                        // dequeue time.

        app_pool_congest_stat : 8; // dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

        deq_timedelta : 32; // time delta between the packet's
                                        // enqueue and dequeue time.

        egress_rid : 16; // L3 replication id for multicast
                                        // packets.

        _pad5: 7;
        egress_rid_first : 1; // flag indicating the first replica for
                                        // the given multicast group.

        _pad6: 3;
        egress_qid : 5; // egress (physical) queue id via which
                                        // this packet was served.

        _pad7: 5;
        egress_cos : 3; // egress cos (eCoS) value.
                                        // this field is passed to the deparser

        _pad8: 7;
        deflection_flag : 1; // flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

        pkt_length : 16; // Packet length, in bytes
    }
}

@pragma dont_trim
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md

@pragma pa_atomic egress eg_intr_md.egress_port
@pragma pa_fragment egress eg_intr_md._pad1
@pragma pa_fragment egress eg_intr_md._pad7
@pragma pa_fragment egress eg_intr_md._pad8
@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_port
@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_cos

header egress_intrinsic_metadata_t eg_intr_md;

/* Produced by Egress Parser-Auxiliary */
header_type egress_intrinsic_metadata_from_parser_aux_t {
    fields {
        egress_global_tstamp : 48; // global time stamp (ns) taken at the
                                        // egress pipe.

        egress_global_ver : 32; // global version number taken at the
                                        // egress pipe.

        egress_parser_err : 16; // error flags indicating error(s)
                                        // encountered at egress
                                        // parser.

        clone_digest_id : 4; // value indicating the digest ID,
                                        // based on the field list ID.

        clone_src : 4; // value indicating whether or not a
                                        // packet is a cloned copy
                                        // (see #defines in constants.p4)

        coalesce_sample_count : 8; // if clone_src indicates this packet
                                        // is coalesced, the number of samples
                                        // taken from other packets
    }
}

@pragma pa_fragment egress eg_intr_md_from_parser_aux.coalesce_sample_count
@pragma pa_fragment egress eg_intr_md_from_parser_aux.clone_src
@pragma pa_fragment egress eg_intr_md_from_parser_aux.egress_parser_err
@pragma pa_atomic egress eg_intr_md_from_parser_aux.egress_parser_err
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md_from_parser_aux
header egress_intrinsic_metadata_from_parser_aux_t eg_intr_md_from_parser_aux;


/* Consumed by Egress Deparser */
// egress_port and egress_cos are passed to the deparser directly from the
// eg_intr_md header instance. The following commented out header is a
// stand-alone definition of this data:
/*
header_type egress_intrinsic_metadata_for_deparser_t {
    fields {

        egress_port : 16;               // egress port id. must be presented to
                                        // egress deparser for every packet, or
                                        // the packet will be dropped by egress
                                        // deparser.

        egress_cos : 8;                 // egress cos (eCoS) value. must be
                                        // presented to egress buffer for every
                                        // lossless-class packet.
    }
}

@pragma pa_atomic egress eg_intr_md_for_deparser.egress_port
@pragma pa_fragment egress eg_intr_md_for_deparser.egress_cos
@pragma not_deparsed ingress
@pragma not_deparsed egress
header egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_deparser;
*/

/* Consumed by Mirror Buffer */
header_type egress_intrinsic_metadata_for_mirror_buffer_t {
    fields {
        _pad1 : 6;
        egress_mirror_id : 10; // egress mirror id. must be presented to
                                        // mirror buffer for mirrored packets.

        coalesce_flush: 1; // flush the coalesced mirror buffer
        coalesce_length: 7; // the number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer
    }
}

@pragma dont_trim
@pragma pa_intrinsic_header egress eg_intr_md_for_mb
@pragma pa_atomic egress eg_intr_md_for_mb.egress_mirror_id
@pragma pa_fragment egress eg_intr_md_for_mb.coalesce_flush
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.egress_mirror_id
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_flush
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_length
@pragma not_deparsed ingress
@pragma not_deparsed egress
header egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb;


/* Consumed by Egress MAC (port) */
header_type egress_intrinsic_metadata_for_output_port_t {
    fields {

        _pad1 : 2;
        capture_tstamp_on_tx : 1; // request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).
        update_delay_on_tx : 1; // request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
        force_tx_error : 1; // force a hardware transmission error

        drop_ctl : 3; // disable packet output:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit (discards all regular unicast packets)
                                        //    - bit 1 disables copy-to-cpu (unused in egress)
                                        //    - bit 2 disables mirroring (packet will not be egress mirrored)
    }
}

@pragma dont_trim
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_oport.drop_ctl
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md_for_oport
header egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
# 9 "pktgen9.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/pktgen_headers.p4" 1
/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/


/********************************************************************************
 *                   Packet Generator Header Definition for Tofino              *
 *******************************************************************************/




header_type pktgen_generic_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        key_msb : 8; // Only valid for recirc triggers.
        batch_id : 16; // Overloaded to port# or lsbs of key for port down and
                        // recirc triggers.
        packet_id : 16;
    }
}
header pktgen_generic_header_t pktgen_generic;

header_type pktgen_timer_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        _pad1 : 8;
        batch_id : 16;
        packet_id : 16;
    }
}
header pktgen_timer_header_t pktgen_timer;

header_type pktgen_port_down_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        _pad1 : 15;
        port_num : 9;
        packet_id : 16;
    }
}
header pktgen_port_down_header_t pktgen_port_down;

header_type pktgen_recirc_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        key : 24;
        packet_id : 16;
    }
}
header pktgen_recirc_header_t pktgen_recirc;
# 10 "pktgen9.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/stateful_alu_blackbox.p4" 1
/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

/***************************************************************************/

blackbox_type stateful_alu {

    attribute reg {
        /*  Reference to the register table description. */
        type: register;
    }

    attribute selector_binding {
        /*  Bind this stateful ALU to the selector used by the specified match table. */
        type: table;
        optional;
    }

    attribute initial_register_lo_value {
        /*  The initial value to use for the stateful memory cell.  Used in dual-width mode as the
            low half initial value.  In single-width mode, this is the initial value of the entire memory cell.
        */
        type: int;
        optional;
    }

    attribute initial_register_hi_value {
        /*  The initial value to use for the stateful memory cell.  Only relevant in dual-width mode to
            specify the high half initial value.
        */
        type: int;
        optional;
    }

    attribute condition_hi {
        /* Condition associated with cmp hi unit.
           An expression that can be transformed into the form:
             memory +/- phv - constant operation 0
         */
        type: expression;
        expression_local_variables { int register_lo, int register_hi}
        optional;
    }

    attribute condition_lo {
        /* Condition associated with cmp lo unit.
           An expression that can be transformed into the form:
             memory +/- phv - constant operation 0
         */
        type: expression;
        expression_local_variables { int register_lo, int register_hi}
        optional;
    }


    attribute update_lo_1_predicate {
        /* Condition expression associated with running ALU 1 lo. */
        type: expression;
        expression_local_variables { bool condition_lo, bool condition_hi}
        optional;
    }

    attribute update_lo_1_value {
        /* Expression computed in ALU 1 lo.
           In single-bit mode, this ALU can only perform single_bit instructions, which perform the following:

           +-------------------+---------------------------------------------------------------------------------+
           |  Operation Name   |   Description                                                                   |
           +-------------------+---------------------------------------------------------------------------------+
           |    set_bit        |  Sets the specified bit to 1, outputs the previous bit value.                   |
           +-------------------+---------------------------------------------------------------------------------+
           |    set_bitc       |  Sets the specified bit to 1, outputs the complement of the previous bit value. |
           +-------------------+---------------------------------------------------------------------------------+
           |    clr_bit        |  Sets the specified bit to 0, outputs the previous bit value.                   |
           +-------------------+---------------------------------------------------------------------------------+
           |    clr_bitc       |  Sets the specified bit to 0, outputs the complement of the previous bit value. |
           +-------------------+---------------------------------------------------------------------------------+
           |    read_bit       |  Does not modify specified bit, outputs current bit value.                      |
           +-------------------+---------------------------------------------------------------------------------+
           |    read_bitc      |  Does not modify specified bit, outputs complement of the current bit value.    |
           +-------------------+---------------------------------------------------------------------------------+

         */
        type: expression;
        expression_local_variables {int register_lo, int register_hi,
                                    set_bit, set_bitc, clr_bit, clr_bitc, read_bit, read_bitc}
        optional;
    }

    attribute update_lo_2_predicate {
        /* Condition expression associated with running ALU 2 lo. */
        type: expression;
        expression_local_variables {bool condition_lo, bool condition_hi}
        optional;
    }

    attribute update_lo_2_value {
        /* Expression computed in ALU 2 lo. */
        type: expression;
        expression_local_variables {int register_lo, int register_hi, int math_unit}
        optional;
    }

    attribute update_hi_1_predicate {
        /* Condition expression associated with running ALU 1 hi. */
        type: expression;
        expression_local_variables {bool condition_lo, bool condition_hi}
        optional;
    }

    attribute update_hi_1_value {
        /* Expression computed in ALU 1 hi. */
        type: expression;
        expression_local_variables {int register_lo, int register_hi}
        optional;
    }

    attribute update_hi_2_predicate {
        /* Condition expression associated with running ALU 2 hi. */
        type: expression;
        expression_local_variables {bool condition_lo, bool condition_hi}
        optional;
    }

    attribute update_hi_2_value {
        /* Expression computed in ALU 2 hi. */
        type: expression;
        expression_local_variables {int register_lo, int register_hi}
        optional;
    }

    attribute output_predicate {
        /* Condition expression associated with outputting result to action data bus.
           Allowed references are 'condition_lo' and 'condition_hi'.
           Allowed operations are 'and', 'or', and 'not'.
         */
        type: expression;
        expression_local_variables {bool condition_lo, bool condition_hi}
        optional;
    }

    attribute output_value {
        /* Output result expression.
           Allowed references are 'alu_lo', 'alu_hi', 'register_lo', 'register_hi',
           'predicate', and 'combined_predicate'.
           In the case of 'register_lo' and 'register_hi', these are the values
           fetched from memory on this access, not the value to be written back
           computed by the ALU(s).
         */
        type: expression;
        expression_local_variables {int alu_lo, int alu_hi, int register_lo, int register_hi, int predicate, int combined_predicate}
        optional;
    }

    attribute output_dst {
        /* Optional field to write the stateful result to. */
        type: int;
        optional;
    }

    attribute math_unit_input {
        /* Specification of the math unit's input.
           This attribute must be defined if a math_unit is referenced in 'update_lo_2_value'.
         */
        type: expression;
        expression_local_variables {int register_lo, int register_hi}
        optional;
    }
    attribute math_unit_output_scale {
        /* Specification of the math unit's output scale.
           This is a 6-bit signed number added to the exponent, which shifts the output result.
           The default value is 0.
         */
        type: int;
        optional;
    }
    attribute math_unit_exponent_shift {
        /* Specification of the math unit's exponent shift.
           Supported shift values are -1, 0, and 1.  The default value is 0.
           This value controls the shifting of the input data exponent.
           With an exponent shift of -1, the math unit normalization is 2-bit resolution.
           Otherwise, the math unit normalization is 1-bit resolution.
         */
        type: int;
        optional;
    }
    attribute math_unit_exponent_invert {
        /* Specifies whether the math unit should invert the computed exponent.
           By default, the exponent is not inverted. Allowed values are true and false.
           Inverting allows reciprocal exponents, e.g. 1/x, 1/x**2, or 1/sqrt(x)
         */
        type: bit;
        optional;
    }

    attribute math_unit_lookup_table {
        /* Specifies the math unit's lookup table values.
           There are 16 8-bit values that can be looked up.
           This attribute must be defined if a math_unit is referenced in 'update_lo_2_value'.
           Input is specified with the most significant byte appearing first in the string.
           For example:
           0x0f 0x0e 0x0d 0x0c 0x0b 0x0a 9 8 7 6 5 4 3 2 1 0;
         */
        type: string;
        optional;
    }

    attribute reduction_or_group {
        /* Specifies that the output value to be written belongs to a group of stateful ALU
           outputs that are all OR'd together.  Using a reduction OR group breaks what
           would normally be considered a dependency.
           A typical use case is to perform a membership check in, e.g., a Bloom filter.
           For example, n unique hash functions may be used to check for membership in
           n unique registers.  If any of the hashed locations are active,
           the member is active.
         */
        type: string;
        optional;
    }

    attribute stateful_logging_mode {
        /*  Specify that stateful logging should be performed.
            Stateful logging writes a result to consecutive addresses in a register based on the mode
            of logging being performed.
            Allowed values are:
               table_hit - performing logging if the match table hits and is predicated on.
               table_miss - performing logging if the match table misses and is predicated on.
               gateway_inhibit - performing logging if the gateway table inhibits a match table and is predicated on.
               address - any time the table is predicated on.
         */
        type: string;
        optional;
    }

    /*
    Executes this stateful alu instance.

    If output_dst is defined, this writes the output_value to a destination field.

        output_dst = output_value

    Callable from:
    - Actions

    Parameters:
    - index: The offset into the stateful register to access.
      May be a constant or an address provided by the run time.
    */
    method execute_stateful_alu(optional in bit<32> index){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
        writes {output_dst}
    }

    method execute_stateful_alu_from_hash(in field_list_calculation hash_field_list){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
        writes {output_dst}
    }

    method execute_stateful_log(){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
    }
}

/***************************************************************************/
# 11 "pktgen9.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4_14include/tofino/primitives.p4" 1
/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/




/////////////////////////////////////////////////////////////
// Primitive aliases




action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}
# 12 "pktgen9.p4" 2
# 1 "stdhdrs.p4" 1
/*------------------------------------------------------------------------
    stdhdrs.p4 - Standard header definitions and Ethertypes, ports, etc.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

//=====================
//      DEFINES
//=====================

// Ethertypes
# 35 "stdhdrs.p4"
// === Standard Headers ===

header_type ethernet_t
{
    fields
    {
        dstAddr0 : 8;
        dstAddr1 : 8;
        dstAddr2 : 8;
        dstAddr3 : 8;
        dstAddr4 : 8;
        dstAddr5 : 8;
        srcAddr0 : 8;
        srcAddr1 : 8;
        srcAddr2 : 8;
        srcAddr3 : 8;
        srcAddr4 : 8;
        srcAddr5 : 8;
        etherType : 16;
    }
}

// Pkt Generator prepends pkt with pkt metadata
// We omit dmac in pktgen buffer, resulting in normal-length Ethernet hdr
header_type pktgen_ethernet_t
{
    fields
    {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        _pad1 : 8;
        batch_id : 16;
        packet_id : 16;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type ipv4_t
{
    fields
    {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr0 : 32;
        srcAddr1 : 32;
        srcAddr2 : 32;
        srcAddr3 : 32;
        dstAddr0 : 32;
        dstAddr1 : 32;
        dstAddr2 : 32;
        dstAddr3 : 32;
    }
}

header_type tcp_t
{
    fields
    {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t
{
    fields
    {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type vxlan_t
{
    fields
    {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

//
// Packet header templates for various protocols
//

header_type fabric_hdr_t
{
    fields
    {
        devPort: 16;
        etherType: 16;
    }
}



/*
header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}*/
# 13 "pktgen9.p4" 2



//========== TOFINO PARAMETERS ==============
# 28 "pktgen9.p4"
//========== OUR DESIGN CONSTANTS ==============
# 50 "pktgen9.p4"
// See parser.p4 for headers defs, instances and checksum field calcs

//========== metadata types and instances =============

header_type metadata_t
{
    fields
    {
        stream : 5; // PIPEAPP_WIDTH+SUBSTREAM_WIDTH
        stream_offset : 5;
        pgid : 10; // the pgid to put into egress instrumentation
        tx_pgid : 10; // the pgid to put into egress instrumentation
        pipe_port : 4;
        tx_pipe_port : 4;
        port_pgid_index : 15;
        pgid_pipe_port_index : 14;
        port_stream_index : 10;
        fp_port : 5;
        tx_fp_port : 5;
        rx_instrum : 1;
        tx_instrum : 1;
        // stateful values
        seq_delta : 32 (signed); // curr seq - prev seq 
        latency : 32 (signed); // timestamp delta
        lat_to_mem : 32; // latency (dv not enabled) OR dv_abs (dv_enabled)
        lat_to_mem_overflow : 32;
        lat_overflow : 32;
        bank_select : 1;
        bank_select_port_stats : 2;
        is_pktgen : 1; // 0 = external packet, 1 = internal pktgen pkt
        known_flow : 1; // 0 = new flow, 1 = known flow
        seq_incr : 1; // 1= seq incremented by one
        seq_big : 1; // 1 = seq incremented by > rx_seq_big_threshold_reg
        seq_dup : 1; // 1= seq was same as last
        seq_rvs : 1; // 1= seq decremented, i.e. out of order
        latency_overflow : 1;
        tstamp_overflow : 1;
        burst_mode : 1;
        rx_tstamp_calibrated : 32; // Calibrated Rx time stamp (= Rx_tstatmp + calib)
        mac_timestamp_enable : 1;
   }
}
metadata metadata_t meta;

# 1 "parser.p4" 1
/*------------------------------------------------------------------------
    parser.p4 - Parser declaration for handling packets between CPU and Tofino over PCIe.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

header_type ixia_big_signature_t
{
    fields
    {
        sig1: 32;
        sig2: 32;
        sig3: 32;
    }
}


// Ingress instrumentation
// Initial implementation, assume instrumentation is bit-packed in the packet
header_type ixia_extended_instrum_t
{
    fields
    {
        tstamp_hires : 3; // bit 31 (10nsec mode) OR bits 31-29 (2.5 nsec mode)
        pgpad : 19; // for byte-alignment = 29-PGID_WIDTH
        pgid : 10; // final PGID from pri flow | substream
        seqnum : 16;
    }
}

header_type ixia_extended_timestamp_t
{
    fields
    {
        upper_tstamp : 16;
        tstamp : 32;
        pad : 16;
    }
}

header_type ptp_mac_hdr_t {
    fields {
        udp_cksum_byte_offset : 8;
        cf_byte_offset : 8;
        updated_cf : 48;
    }
}

//========== packet header instances =============
header ptp_mac_hdr_t ptp;
header ethernet_t ptp_eth;
header ethernet_t outer_eth;
header pktgen_ethernet_t pktgen_eth;
header ipv4_t outer_ipv4;
header ipv6_t outer_ipv6;
header tcp_t outer_tcp;
header udp_t outer_udp;
header vxlan_t vxlan_hdr;
header ixia_big_signature_t big_sig;
header ixia_extended_instrum_t instrum;
header ixia_extended_timestamp_t instrum_tstamp;
header fabric_hdr_t fabric_hdr;

header vlan_tag_t vlan_tag[2];
header ethernet_t inner_eth;
header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;
header vlan_tag_t vlan_inner_tag[2];

//========= IPv4 CHECKSUM ================
field_list ipv4_field_list
{
    outer_ipv4.version;
    outer_ipv4.ihl;
    outer_ipv4.diffserv;
    outer_ipv4.totalLen;
    outer_ipv4.identification;
    outer_ipv4.flags;
    outer_ipv4.fragOffset;
    outer_ipv4.ttl;
    outer_ipv4.protocol;
    outer_ipv4.srcAddr;
    outer_ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc
{
    input
    {
        ipv4_field_list;
    }
    algorithm : csum16;
    output_width: 16;
}

// This declaration means: update ipv4.hdrChecksum automatically upon egress
// using the field list specified
calculated_field outer_ipv4.hdrChecksum
{
    verify ipv4_chksum_calc;
    update ipv4_chksum_calc;
}




// ------------------------------------------------------ //
//                      TCP CHECKSUM
// ------------------------------------------------------ //
field_list ipv4_tcp_checksum_list
{
    outer_ipv4.srcAddr;
    outer_ipv4.dstAddr;
    8'0;
    outer_ipv4.protocol;
    outer_ipv4.totalLen;
    outer_ipv6.srcAddr0;
    outer_ipv6.srcAddr1;
    outer_ipv6.srcAddr2;
    outer_ipv6.srcAddr3;
    outer_ipv6.dstAddr0;
    outer_ipv6.dstAddr1;
    outer_ipv6.dstAddr2;
    outer_ipv6.dstAddr3;
    outer_ipv6.payloadLen;
    outer_ipv6.nextHdr;
    8'0;
    outer_tcp.srcPort;
    outer_tcp.dstPort;
    outer_tcp.seqNo;
    outer_tcp.ackNo;
    outer_tcp.dataOffset;
    outer_tcp.res;
    outer_tcp.flags;
    outer_tcp.window;
    16'0;
    outer_tcp.urgentPtr;
    payload;
}

field_list_calculation ipv4_tcp_checksum
{
    input
    {
        ipv4_tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field outer_tcp.checksum
{
    update ipv4_tcp_checksum;
}


//========= UDP CHECKSUM ================
field_list ipv4_udp_checksum_list
{
    outer_ipv4.srcAddr;
    outer_ipv4.dstAddr;
    8'0;
    outer_ipv4.protocol;
    outer_ipv4.totalLen;
    outer_ipv6.srcAddr0;
    outer_ipv6.srcAddr1;
    outer_ipv6.srcAddr2;
    outer_ipv6.srcAddr3;
    outer_ipv6.dstAddr0;
    outer_ipv6.dstAddr1;
    outer_ipv6.dstAddr2;
    outer_ipv6.dstAddr3;
    outer_ipv6.payloadLen;
    outer_ipv6.nextHdr;
    8'0;
    outer_udp.srcPort;
    outer_udp.dstPort;
    outer_udp.length_ ;
    payload;
}

field_list_calculation ipv4_udp_checksum
{
    input
    {
        ipv4_udp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field outer_udp.checksum
{
    update ipv4_udp_checksum;
}



// ================= PARSER ================

@pragma packet_entry
parser start_i2e_mirrored {
// Same logic as parse_i2e_cpu
// p4c-tofino in 8.9.1 throws error if return parse_i2e_cpu; is used.
    set_metadata(meta.is_pktgen,0);
    extract(outer_eth);
    return select(outer_eth.etherType)
    {
        0x9090: parse_fabric_only;
        default: ingress;
    }

}

parser start
{
    return select(ig_intr_md.ingress_port)
    {
        68 mask 0x7f : parse_pktgen_eth;
        // CPU port should always do normal parsing
        64 mask 0x7f : parse_i2e_cpu;
        // Pipe 1,3 are recirc pipes
        // 9 bit port number is
        // [2bit Pipe Id]-[7bit Port Id]
        // For Pipe 0b01 and 0b11, we mask out pipe Id with 0b10 (X1).
        // i.e. if LSB of Pipe Id is 1 then it's from recirc pipe.
        // Consider recirc ports as pktgen ports
        128 mask 0x80 : parse_pktgen_eth;
        0xff mask 0xff : parse_fake_ptp;
        default : parse_outer_eth;
    }
}

parser parse_pktgen_eth
{
    set_metadata(meta.is_pktgen, 1);
    extract(pktgen_eth);
    return select(pktgen_eth.etherType)
    {
        0x0800: parse_outer_ipv4;
        0x86dd: parse_outer_ipv6;
        0x8100: parse_vlan;
        0x88A8: parse_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_fake_ptp
{
    extract(ptp_eth);
    extract(ptp);
    return parse_outer_eth;
}

parser parse_outer_eth
{
    set_metadata(meta.is_pktgen, 0);
    extract(outer_eth);
    return select(outer_eth.etherType)
    {
        0x9090: parse_fabric;
        0x0800: parse_outer_ipv4;
        0x86dd: parse_outer_ipv6;
        0x8100: parse_vlan;
        0x88A8: parse_vlan;
        0x9100: parse_vlan;
        0x9200: parse_vlan;
        0x9300: parse_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_i2e_cpu
{
    set_metadata(meta.is_pktgen,0);
    extract(outer_eth);
    return select(outer_eth.etherType)
    {
        0x9090: parse_fabric_only;
        default: ingress;
    }
}

parser parse_fabric_only
{
    extract(fabric_hdr);
    return ingress;
}
//
// EtherType indicates a packet from the CPU; extract fabric header.
//
parser parse_fabric
{
    extract(fabric_hdr);
    return select(fabric_hdr.etherType)
    {
        0x0800: parse_outer_ipv4;
        0x86dd: parse_outer_ipv6;
        0x8100: parse_vlan;
        0x88A8: parse_vlan;
        0x9100: parse_vlan;
        0x9200: parse_vlan;
        0x9300: parse_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_vlan
{
    extract(vlan_tag[0]);
    return select(latest.etherType)
    {
        0x0800: parse_outer_ipv4;
        0x86dd: parse_outer_ipv6;
        0x8100: parse_qinq_vlan;
        0x88A8: parse_qinq_vlan;
        0x9100: parse_qinq_vlan;
        0x9200: parse_qinq_vlan;
        0x9300: parse_qinq_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_qinq_vlan
{
    extract(vlan_tag[1]);
    return select(latest.etherType)
    {
        0x0800: parse_outer_ipv4;
        0x86dd: parse_outer_ipv6;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_outer_ipv4
{
    extract(outer_ipv4);
    return select(outer_ipv4.protocol)
    {
        6: parse_outer_tcp;
        17: parse_outer_udp;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_outer_ipv6
{
    extract(outer_ipv6);
    return select(outer_ipv6.nextHdr)
    {
        6: parse_outer_tcp;
        17: parse_outer_udp;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_outer_tcp
{
    extract(outer_tcp);
    return parse_big_sig_ig_instrum;
}

parser parse_outer_udp
{
    extract(outer_udp);
    return select(outer_udp.dstPort)
    {
        4789: parse_vxlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_big_sig_ig_instrum
{
    extract(big_sig);
    extract(instrum);
    extract(instrum_tstamp);
    return ingress;
}

parser parse_vxlan
{
    extract(vxlan_hdr);
    return parse_inner_eth;
}


parser parse_inner_eth
{
    extract(inner_eth);
    return select(inner_eth.etherType)
    {
        0x0800: parse_inner_ipv4;
        0x86dd: parse_inner_ipv6;
        0x8100: parse_inner_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_inner_vlan
{
    extract(vlan_inner_tag[0]);
    return select(latest.etherType)
    {
        0x0800: parse_inner_ipv4;
        0x86dd: parse_inner_ipv6;
        0x8100: parse_qinq_inner_vlan;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_qinq_inner_vlan
{
    extract(vlan_inner_tag[1]);
    return select(latest.etherType)
    {
        0x0800: parse_inner_ipv4;
        0x86dd: parse_inner_ipv6;
        default: parse_big_sig_ig_instrum;
    }
}

parser parse_inner_ipv4
{
    extract(inner_ipv4);
    return parse_big_sig_ig_instrum;
}

parser parse_inner_ipv6
{
    extract(inner_ipv6);
    return parse_big_sig_ig_instrum;
}
# 95 "pktgen9.p4" 2

//============= INGRESS PIPELINE ===================

# 1 "bank_select.p4" 1
/*------------------------------------------------------------------------
    bank_select.p4 - Module to simply store active bank for PGID and stream stats. This allows for Tx/Rx Sync of
    flow statistics through bank switching.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

action do_set_bank_select(bank_select)
{
    modify_field(meta.bank_select, bank_select);
}

table bank_select_tbl
{
    actions
    {
        do_set_bank_select;
    }
    default_action: do_set_bank_select;
    size: 1;
}

control process_bank_select_reg
{
    apply(bank_select_tbl);
}

action do_set_bank_select_port_stats(bank_select)
{
    modify_field(meta.bank_select_port_stats, bank_select);
}

table bank_select_port_stats_tbl
{
    actions
    {
        do_set_bank_select_port_stats;
    }
    default_action: do_set_bank_select_port_stats;
    size: 1;
}

control process_bank_select_port_stats_reg
{
    apply(bank_select_port_stats_tbl);
}
# 99 "pktgen9.p4" 2
# 1 "front_panel.p4" 1
/*------------------------------------------------------------------------
    front_panel.p4 - Module to retrieve port indices based on dataplane port
    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*/

control process_ingress_fp_port
{
    apply(ingress_get_fp_port_tbl);
}

table ingress_get_fp_port_tbl
{
    reads
    {
        ig_intr_md.ingress_port : ternary;
    }
    actions
    {
        _nop;

        do_get_ingress_fp_port;
    }
    default_action: _nop;
    size: 256;
}

// Front panel port represents the logical port number as seen in the GUI
// For example, Nanite has 32 ports total
// This means that 0 <= fp_port <= 31

// Pipe port is the logical port number within the pipe.
// For example, Nanite has 16 ports per pipe and two front panel pipes.
// This means that 0 <= pipe_port <= 15

action do_get_ingress_fp_port(fp_port, pipe_port, channel_pgid_offset)
{
    modify_field(meta.fp_port, fp_port);
    modify_field(meta.pipe_port, pipe_port);
    add(meta.pgid, instrum.pgid, channel_pgid_offset);
}

control process_egress_fp_port
{
    apply(egress_get_fp_port_tbl);
}

table egress_get_fp_port_tbl
{
    reads
    {
        eg_intr_md.egress_port : ternary;
    }
    actions
    {
        _nop;

        do_get_egress_fp_port;
    }
    default_action: _nop;
    size: 256;
}

// Front panel port represents the logical port number as seen in the GUI
// For example, Nanite has 32 ports total
// This means that 0 <= fp_port <= 31

// Pipe port is the logical port number within the pipe.
// For example, Nanite has 16 ports per pipe and two front panel pipes.
// This means that 0 <= pipe_port <= 15

action do_get_egress_fp_port(fp_port, pipe_port, channel_pgid_offset, channel_stream_offset)
{
    modify_field(meta.tx_fp_port, fp_port);
    modify_field(meta.tx_pipe_port, pipe_port);
    add(meta.tx_pgid, instrum.pgid, channel_pgid_offset);
    add(meta.stream_offset, meta.stream, channel_stream_offset);
}
# 100 "pktgen9.p4" 2

# 1 "ig_port_fwd.p4" 1
/*------------------------------------------------------------------------
    ig_port_fwd.p4 - Module to modify ingress metadata to route frames
    Specifies either unicast port, multicast group, or drop
    This is used to routes frames from the packet generator ports to the recirculation ports.
    This is also used to route frames from the recirculation ports to the front panel ports

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

//========= Forwarding table - Map ig_ports to eg_ports and/or mcast groups ======
action _set_eg_port(eg_port)
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, eg_port);
    // Each stream will use it's own egress queue associated with the eg_port
    // This allows rate control for each stream
    modify_field(ig_intr_md_for_tm.qid, meta.stream);
}

action do_set_unicast(eg_port)
{
    _set_eg_port(eg_port);
}

// set mcast-related metadata other than the MGID
action _set_general_md(rid, xid, yid, h1, h2)
{
    modify_field(ig_intr_md_for_tm.rid, rid);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, xid);
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, yid);
    modify_field(ig_intr_md_for_tm.level1_mcast_hash, h1);
    modify_field(ig_intr_md_for_tm.level2_mcast_hash, h2);
    _set_eg_port(511); // no unicast ports
}
// set mcast level 1 metadata including mgid and generic mc
action do_set_mcast1_md(mgid, rid, xid, yid, h1, h2)
{
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mgid);
    _set_general_md(rid, xid, yid, h1, h2);
}

action do_drop()
{
    drop();
}

// Based on input port & stream, send to one output port or to a multicast group
table ig_port_tbl
{
    reads
    {
        meta.stream : ternary;
        ig_intr_md.ingress_port : ternary;
    }
    actions
    {
        do_drop;
        do_set_unicast; // unicast pkts
        do_set_mcast1_md; // mcast pkts
    }
    size: 2048;
}

table ig_recirc_port_tbl
{
    reads
    {
        meta.stream: ternary;
        ig_intr_md.ingress_port: ternary;
    }
    actions
    {
        do_set_unicast;
    }
    size: 1024;
}


// ================= control wrappers =================
control process_port_forwarding
{
    apply(ig_port_tbl);
}
# 102 "pktgen9.p4" 2
# 1 "imix.p4" 1
/*------------------------------------------------------------------------
    imix.p4 - Module to implement IMIX per stream through truncation.
    Computes random number and range matches on number to select a mirror session
    Control plane configures a mirror session per frame size in mix.
    Control plane then computes ranges for each frame size based on the weights in the mix.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

header_type imix_t
{
    fields
    {
        random: 16;
    }
}

metadata imix_t imix;

header_type pad_t
{
    fields
    {
        pad0: 2;
    }
}

metadata pad_t pad;

field_list frame_bridged_metadata
{
    meta.stream; // 5 bits 
    meta.bank_select; // 1 bit
    pad.pad0; // 2 bits
    g_pkt_cntr.max; // 16 bits
    udf1_cntr.bit_mask; // 2 bits
    udf2_cntr.bit_mask; // 2 bits
    udf1_cntr.nested_repeat; // 32 bits
    udf2_cntr.nested_repeat; // 32 bits
    udf1_cntr.nested_step; // 32 bits
    udf2_cntr.nested_step; // 32 bits
}

action generate_random_number()
{
    modify_field_rng_uniform(imix.random, 0, 65535);
}

table generate_random_number_tbl
{
    actions
    {
        generate_random_number;
    }
    default_action: generate_random_number;
    size: 1;
}

control process_generate_random_number
{
    apply(generate_random_number_tbl);
}

action do_imix_mirror_id(mirror_id)
{
    clone_ingress_pkt_to_egress(mirror_id, frame_bridged_metadata);
}

table random_imix_mirror_id_tbl
{
    reads
    {
        meta.stream: ternary;
        imix.random: range;
        ig_intr_md.ingress_port: ternary;
    }
    actions
    {
        _nop;
        do_imix_mirror_id;
    }
    size: 320;
}


control process_imix_mirror_id
{
    apply(random_imix_mirror_id_tbl);
}

table eg_remap_stream_tbl
{
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        _nop;
        do_remap_stream;
    }
    size: 1024;
}

action do_remap_stream(stream_id, mac_timestamp_enable)
{
    modify_field(meta.stream, stream_id);
    modify_field(meta.mac_timestamp_enable, mac_timestamp_enable);
}
# 103 "pktgen9.p4" 2
# 1 "ig_stats.p4" 1
/*------------------------------------------------------------------------
    ig_stats.p4 - Module to compute statistics for ingress ports.
    Computes receive port and PGID flow statistics.
    Port statistics include protocol statistics
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
# 1 "port_stats_util.p4" 1
/*------------------------------------------------------------------------
    port_stats_util.p4 - Common Template to define Stats

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
# 11 "ig_stats.p4" 2


counter ig_port_vlan_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_vlan_statsA() { count(ig_port_vlan_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_vlan_statsA_tbl { actions { do_ig_port_vlan_statsA; } default_action: do_ig_port_vlan_statsA; size: 1; }
counter ig_port_qinq_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_qinq_statsA() { count(ig_port_qinq_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_qinq_statsA_tbl { actions { do_ig_port_qinq_statsA; } default_action: do_ig_port_qinq_statsA; size: 1; }
counter ig_port_ipv4_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_ipv4_statsA() { count(ig_port_ipv4_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_ipv4_statsA_tbl { actions { do_ig_port_ipv4_statsA; } default_action: do_ig_port_ipv4_statsA; size: 1; }
counter ig_port_ipv6_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_ipv6_statsA() { count(ig_port_ipv6_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_ipv6_statsA_tbl { actions { do_ig_port_ipv6_statsA; } default_action: do_ig_port_ipv6_statsA; size: 1; }
counter ig_port_tcp_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_tcp_statsA() { count(ig_port_tcp_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_tcp_statsA_tbl { actions { do_ig_port_tcp_statsA; } default_action: do_ig_port_tcp_statsA; size: 1; }
counter ig_port_udp_stats_cntrA { type: packets_and_bytes; instance_count: 512; } action do_ig_port_udp_statsA() { count(ig_port_udp_stats_cntrA, ig_intr_md.ingress_port); } table ig_port_udp_statsA_tbl { actions { do_ig_port_udp_statsA; } default_action: do_ig_port_udp_statsA; size: 1; }
# 37 "ig_stats.p4"
 //============= Ingress pgid pkt stats BankA===================
// Counts packets which egressed per PGID
counter ig_pgid_stats_cntrA
{
    type: packets_and_bytes;
    instance_count: 32768;
}

// count per-pgid ingress pkts/bytes
action do_ig_pgid_statsA()
{
    count(ig_pgid_stats_cntrA, meta.port_pgid_index);
}

// count pgid stats - action wrapper table
table ig_pgid_statsA_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_ig_pgid_statsA;
    }
    size: 1;
}

counter ig_pgid_stats_cntrB
{
    type: packets_and_bytes;
    instance_count: 32768;
}

// count per-pgid ingress pkts/bytes
action do_ig_pgid_statsB()
{
    count(ig_pgid_stats_cntrB, meta.port_pgid_index);
}

// count pgid stats - action wrapper table
table ig_pgid_statsB_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_ig_pgid_statsB;
    }
    size: 1;
}

//============= Ingress port pkt stats BankA===================

counter ig_port_stats_cntr_checksum_errors
{
    type: packets;
    instance_count: 512;
}

// count ingress checksum error pkts
action do_ig_port_stats_checksum_errors()
{
    count(ig_port_stats_cntr_checksum_errors, ig_intr_md.ingress_port);
}


// send pkts - action wrapper table
table ig_port_stats_checksum_errors_tbl
{
    actions
    {
        do_ig_port_stats_checksum_errors;
    }
    default_action: do_ig_port_stats_checksum_errors;
    size: 1;
}

// Counts packets which egressed per port
counter ig_port_stats_cntrA
{
    type: packets_and_bytes;
    instance_count: 512;
}

// count ingress pkts/bytes
action do_ig_port_statsA()
{
    count(ig_port_stats_cntrA, ig_intr_md.ingress_port);
}

// send pkts - action wrapper table
table ig_port_statsA_tbl
{
    actions
    {
        do_ig_port_statsA;
    }
    default_action: do_ig_port_statsA;
    size: 1;
}

register rx_ingress_stamp_regA
{
    width: 64;
    instance_count: 16384;
}

blackbox stateful_alu store_ingress_tstampA_salu
{
    reg: rx_ingress_stamp_regA;
    update_lo_1_value: rx_packet_timestamp.lower;
    update_hi_1_value: rx_packet_timestamp.upper;
}

action do_store_ingress_stampA()
{
    store_ingress_tstampA_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}

table rx_tstampA_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_store_ingress_stampA;
    }
    size: 1;
}


register rx_ingress_stamp_regB
{
    width: 64;
    instance_count: 16384;
}

blackbox stateful_alu store_ingress_tstampB_salu
{
    reg: rx_ingress_stamp_regB;
    update_lo_1_value: rx_packet_timestamp.lower;
    update_hi_1_value: rx_packet_timestamp.upper;
}

action do_store_ingress_stampB()
{
    store_ingress_tstampB_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}

table rx_tstampB_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_store_ingress_stampB;
    }
    size: 1;
}



//=============  Control wrappers ===================

control process_ig_port_stats
{
    apply(ig_port_statsA_tbl);

    if (vlan_tag[0].valid == 1 and vlan_tag[1].valid == 1) apply(ig_port_qinq_statsA_tbl); else if (vlan_tag[0].valid == 1) apply(ig_port_vlan_statsA_tbl); if (outer_ipv4.valid == 1) apply(ig_port_ipv4_statsA_tbl); if (outer_ipv6.valid == 1) apply(ig_port_ipv6_statsA_tbl); if (outer_udp.valid == 1) apply(ig_port_udp_statsA_tbl); if (outer_tcp.valid == 1) apply(ig_port_tcp_statsA_tbl);

    if ((ig_intr_md_from_parser_aux.ingress_parser_err & 0x1000) == 0x1000)
    {
        apply(ig_port_stats_checksum_errors_tbl);
    }
}

control process_ig_pgid_statsA
{
    apply(ig_pgid_statsA_tbl);
}

control process_ig_pgid_statsB
{
    apply(ig_pgid_statsB_tbl);
}

control process_ig_pgid_tstampA
{
    apply(rx_tstampA_tbl);
}

control process_ig_pgid_tstampB
{
    apply(rx_tstampB_tbl);
}
# 104 "pktgen9.p4" 2
# 1 "rx_pgid.p4" 1
/*------------------------------------------------------------------------
    rx_pgid.p4 - Module to detect new flows based on tracking of PGID found in Ixia instrumentation

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

//=============== PGID Rx flow tracking =================
register rx_pgid_flow_state_reg
{
    width: 1; // 0 = unknown flow, 1 = known flow
    instance_count: 16384;
}

/*
 * Retrieve flow state for this PGID, copy to meta
 * update reg value =>1 
 */
blackbox stateful_alu rx_pgid_known_flow_tracker_salu
{
    reg: rx_pgid_flow_state_reg; // 1-bit register, 1 = known flow, 0 = unknown
    update_lo_1_value: set_bit; // rx_pgid_flow_state_reg[meta.rxpgid] = 1 (known flow)
    output_value: alu_lo; // read rx_pgid_flow_state_reg[meta.rxpgid] into alu
    output_dst: meta.known_flow; // meta.new_flow = rx_pgid_flow_state_reg[meta.rxpgid]
}

action do_rx_pgid_track_flows()
{
    rx_pgid_known_flow_tracker_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}

table rx_pgid_flow_tbl
{
    actions {
        do_rx_pgid_track_flows;
    }
    default_action: do_rx_pgid_track_flows;
    size: 1;
}

// control wrapper
control process_rx_pgid_flow_tracking
{
    apply(rx_pgid_flow_tbl);
}
# 105 "pktgen9.p4" 2
# 1 "rx_seqnum.p4" 1
/*------------------------------------------------------------------------
    rx_seqnum.p4 -  Module to compute basic sequence stats. Compares sequence number in Ixia instrumentation to
                    previously received sequence number and calculates small, big, reverse, duplicate sequence
                    counters. Also stores maximum received sequence number.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


//=========================================
//   TABLES/ACTIONS - Rx sequence number processing
//=========================================


// =========== Detect seq_max & update seq number in rx_seq_max_reg =================

// TODO - A/B banks?
// TODO - handle wraparound
/*
 * For seq_max processing:
 * Retrieve last seq number state for this PGID
 * Detect if cur seq num > prev & update only if it is bigger
 * Store new max in reg
 */
register rx_seq_max_reg
{
    width: 32;
    instance_count: 16384;
}

blackbox stateful_alu seq_max_detector
{
    reg: rx_seq_max_reg; // prev seqnum for seq_max detection
    condition_lo: instrum.seqnum > register_lo; // if seqnum > prev

    update_lo_1_predicate: condition_lo; // if...
    update_lo_1_value: instrum.seqnum; // return val new seq
    update_lo_2_predicate: not condition_lo; // else...
    update_lo_2_value: register_lo; // return val prev seq
}

action rx_detect_seq_max()
{
    seq_max_detector.execute_stateful_alu(meta.pgid_pipe_port_index);
}

// Store curr seq num into rx_seq_max_reg 
blackbox stateful_alu store_prev_seq_max
{
    reg: rx_seq_max_reg; // 32-bit reg stores prev seq num
    update_lo_1_value: instrum.seqnum; // rx_seq_max_reg = seqnum
}

action store_prev_seq_max()
{
    store_prev_seq_max.execute_stateful_alu(meta.pgid_pipe_port_index);
}

@pragma force_table_dependency rx_pgid_flow_tbl
@pragma force_table_dependency mode_tbl
table rx_seq_max_detect_tbl
{
    reads
    {
        meta.known_flow: exact;
    }
    actions
    {
        store_prev_seq_max;
        rx_detect_seq_max;
    }
    size: 2;
}

// =========== Compute & update seq delta =================

/*
 * For seq_delta processing:
 * Retrieve last seq number state for this PGID
 * Compute current seqnum - prev seqnum
 * Store new seq num
 */
register rx_seq_delta_reg
{
    width: 32;
    instance_count: 16384;
}

blackbox stateful_alu seq_delta_calc
{
    reg: rx_seq_delta_reg; // prev seqnum for seq_delta detection
    update_lo_1_value: instrum.seqnum; // store seqnum into prev reg
    update_hi_1_value: instrum.seqnum - register_lo; // Compute delta
    output_value: alu_hi; // return...
    output_dst: meta.seq_delta; // ...into 
}

action rx_calc_seq_delta()
{
    seq_delta_calc.execute_stateful_alu(meta.pgid_pipe_port_index);
}

// Store curr seq num into rx_seq_delta_reg 
blackbox stateful_alu store_prev_seq_delta
{
    reg: rx_seq_delta_reg; // 32-bit reg stores prev seq num
    update_lo_1_value: instrum.seqnum; // rx_seq_delta_reg = seqnum
}

action store_prev_seq_delta()
{
    store_prev_seq_delta.execute_stateful_alu(meta.pgid_pipe_port_index);
}

@pragma force_table_dependency rx_pgid_flow_tbl
@pragma force_table_dependency rx_pgid_flow_tbl
table rx_seq_delta_calc_tbl
{
    reads
    {
        meta.known_flow: exact;
    }
    actions
    {
        store_prev_seq_delta;
        rx_calc_seq_delta;
    }
    size: 2;
}

// =========== Detect seq_incr by 1 =================

/*
 * For seq_incr processing:
 * Set flag meta.seq_incr if true
 * Register not read or updated, just used to "store" program
 */
register rx_seq_incr_reg
{
    width: 32;
    instance_count: 1;
}

blackbox stateful_alu seq_incr_detector
{
    reg: rx_seq_incr_reg; // dummy reg
    condition_lo: meta.seq_delta == 1; // if seqnum = prev + 1

    update_hi_1_predicate: condition_lo; // if...
    update_hi_1_value: 1; // return val 1
    update_hi_2_predicate: not condition_lo;// else...
    update_hi_2_value: 0; // return val  0
    output_value: alu_hi; // return...
    output_dst: meta.seq_incr; // ...into 
}

action rx_detect_seq_incr()
{
    seq_incr_detector.execute_stateful_alu(0);
}

@pragma force_table_dependency rx_pgid_flow_tbl
@pragma force_table_dependency rx_pgid_flow_tbl
table rx_seq_incr_detect_tbl
{
    actions
    {
        rx_detect_seq_incr;
    }
    default_action: rx_detect_seq_incr;
    size: 1;
}

// =========== Detect seq_dup  =================

/*
 * For seq_dup processing:
 * Detect if deq_delta == 0
 * Set flag meta.seq_dup if true
 */
register rx_seq_dup_reg
{
    width: 32;
    instance_count: 1;
}

blackbox stateful_alu seq_dup_detector
{
    reg: rx_seq_dup_reg; // dummy reg
    condition_lo: meta.seq_delta == 0; // if seqnum = prev

    update_hi_1_predicate: condition_lo; // if...
    update_hi_1_value: 1; // return val 1
    update_hi_2_predicate: not condition_lo;// else...
    update_hi_2_value: 0; // return val  0
    output_value: alu_hi; // return...
    output_dst: meta.seq_dup; // ...into 
}

action rx_detect_seq_dup()
{
    seq_dup_detector.execute_stateful_alu(0);
}

@pragma force_table_dependency rx_pgid_flow_tbl
table rx_seq_dup_detect_tbl
{
    actions
    {
        rx_detect_seq_dup;
    }
    default_action: rx_detect_seq_dup;
    size: 1;
}

// =========== Detect seq_rvs  =================

register rx_seq_rvs_reg
{
    width: 32;
    instance_count: 1;
}

/*
 * For seq_rvs processing:
 * Detect if deq_delta < 0
 * Set flag meta.seq_rvs if true
 */
blackbox stateful_alu seq_rvs_detector
{
    reg: rx_seq_rvs_reg; // dummy reg
    condition_lo: meta.seq_delta < 0; // if seqnum < prev

    update_hi_1_predicate: condition_lo; // if...
    update_hi_1_value: 1; // return val 1
    update_hi_2_predicate: not condition_lo;// else...
    update_hi_2_value: 0; // return val  0
    output_value: alu_hi; // return...
    output_dst: meta.seq_rvs; // ...into 
}

action rx_detect_seq_rvs()
{
    seq_rvs_detector.execute_stateful_alu(0);
}

@pragma force_table_dependency rx_pgid_flow_tbl
table rx_seq_rvs_detect_tbl
{
    actions
    {
        rx_detect_seq_rvs;
    }
    default_action: rx_detect_seq_rvs;
    size: 1;
}
// =========== Detect if seq incremented by big number =================

register rx_seq_big_threshold_reg
{
    width: 32;
    instance_count: 1;
}

/*
 * For seq_big processing (detect if sequence incremented by >= threshold)
 * Retrieve threshold value rx_seq_big_threshold_reg
 * Detect if seq_delta >= threshold
 * Set flag meta.seq_big if true
 * Register only read for threshold
 */
blackbox stateful_alu seq_big_detector
{
    reg: rx_seq_big_threshold_reg; // threshold, if delta >= this then condition true
    condition_lo: meta.seq_delta >= register_lo; // if meta.seq_delta >= seq_big_threshold

    update_hi_1_predicate: condition_lo; // if...
    update_hi_1_value: 1; // return val 1
    update_hi_2_predicate: not condition_lo;// else...
    update_hi_2_value: 0; // return val  0
    output_value: alu_hi; // return...
    output_dst: meta.seq_big; // ...into 
}

action rx_detect_seq_big()
{
    seq_big_detector.execute_stateful_alu(0);
}

@pragma force_table_dependency rx_pgid_flow_tbl
table rx_seq_big_detect_tbl
{
    actions
    {
        rx_detect_seq_big;
    }
    default_action: rx_detect_seq_big;
    size: 1;
}
// Would prefer to have one table with match keys on each seq_XXX meta flag
// but compiler bug prevents. See case #5535. Hence we use separate tables
// to trigger each type of counter.


// === count seq_big pkts A/B ===

counter rx_seq_big_cntrA
{
    type: packets;
    instance_count: 32768;
}
action count_seq_bigA()
{
        count(rx_seq_big_cntrA, meta.port_pgid_index);
}

@pragma force_table_dependency mode_tbl
@pragma force_table_dependency rx_seq_big_detect_tbl
table rx_seq_big_count_tblA
{
    actions
    {
        count_seq_bigA;
    }
    default_action: count_seq_bigA;
    size: 1;
}


// === count seq_sm pkts Bank A/B===

counter rx_seq_sm_cntrA
{
    type: packets;
    instance_count: 32768;
}

action count_seq_smA()
{
        count(rx_seq_sm_cntrA, meta.port_pgid_index);

}
@pragma force_table_dependency mode_tbl
@pragma force_table_dependency rx_seq_sm_detect_tbl
table rx_seq_sm_count_tblA
{
    actions
    {
        count_seq_smA;
    }
    default_action: count_seq_smA;
    size: 1;
}

// === count seq_rvs pkts Bank A/B===

counter rx_seq_rvs_cntrA
{
    type: packets;
    instance_count: 32768;
}

action count_seq_rvsA()
{
        count(rx_seq_rvs_cntrA, meta.port_pgid_index);
}

@pragma force_table_dependency mode_tbl
@pragma force_table_dependency rx_seq_rvs_detect_tbl
table rx_seq_rvs_count_tblA
{
    actions
    {
        count_seq_rvsA;
    }
    default_action: count_seq_rvsA;
    size: 1;
}

// === count seq_dup pkts Bank A/B===

counter rx_seq_dup_cntrA
{
    type: packets;
    instance_count: 32768;
}
action count_seq_dupA()
{
        count(rx_seq_dup_cntrA, meta.port_pgid_index);
}

@pragma force_table_dependency mode_tbl
@pragma force_table_dependency rx_seq_dup_detect_tbl
table rx_seq_dup_count_tblA
{
    actions
    {
        count_seq_dupA;
    }
    default_action: count_seq_dupA;
    size: 1;
}


control process_ig_seq_stats
{

    // calc maximum seqnum & compute seq delta
    apply(rx_seq_max_detect_tbl); // first call will just init value; subsequent calls will update only if larger
    apply(rx_seq_delta_calc_tbl); // first call will just init value; subsequent calls will update & calc delta

    // only process "deltas" if not first packet...
    if (meta.known_flow == 1)
    {
        // conditional sequence number processing
        apply(rx_seq_incr_detect_tbl);
        apply(rx_seq_dup_detect_tbl);
        apply(rx_seq_rvs_detect_tbl);
        apply(rx_seq_big_detect_tbl);
        // mode[bit 0] = bank A/B
        if (meta.seq_dup == 1)
        {
            apply(rx_seq_dup_count_tblA);
        }
        else if (meta.seq_rvs == 1)
        {
            apply(rx_seq_rvs_count_tblA);
        }
        else if (meta.seq_big == 1)
        {
            apply(rx_seq_big_count_tblA);
        }
        else if (meta.seq_incr == 0)
        {
            apply(rx_seq_sm_count_tblA);
        }
    }
}
# 106 "pktgen9.p4" 2
# 1 "rx_latency.p4" 1
/**
 * Apply a negative offset to the rx time stamp
 * @param offset in ns, please note it must be programmed in 2's complement
 * @return instrum.tstamp is modified with negative offset
 */
action do_calib_rx_tstamp(offset) {
  add(meta.rx_tstamp_calibrated, instrum_tstamp.tstamp, offset);
}

/**
 * @table Invokes do_calib_rx_tstamp(offset)
 */
table do_calib_rx_tstamp_tbl {
  reads {
    ig_intr_md.ingress_port: exact;
  }
  actions {
    do_calib_rx_tstamp;
    _nop;
  }
 default_action: _nop;
 size: 128;
}

// =========== Store first timestamp  =================
/*
* Store the timestamp, assumed called only once per flow
*/
register rx_first_stamp_reg
{
    width: 64;
    instance_count: 16384;
}


// Store curr tstamp 
blackbox stateful_alu store_first_tstamp_salu
{
    reg: rx_first_stamp_reg;
    update_lo_1_value: rx_packet_timestamp.lower;
    update_hi_1_value: rx_packet_timestamp.upper;
}

action do_store_first_stamp()
{
    store_first_tstamp_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}

table rx_store_first_tstamp_tbl
{
    actions
    {
        do_store_first_stamp;
    }
    default_action: do_store_first_stamp;
    size: 1;
}





// =========== Compute & update latency (timestamp delta) =================

action rx_latency_calc()
{
    // subtract(dst,src1,src2) => dst = src1-src2
    subtract(meta.latency, ig_intr_md.ingress_mac_tstamp, meta.rx_tstamp_calibrated);
}

action rx_latency_store_overflow(lat_overflow)
{
    modify_field(meta.lat_overflow, lat_overflow);
}

table rx_latency_store_overflow_tbl
{
    actions
    {
        rx_latency_store_overflow;
    }
    default_action: rx_latency_store_overflow;
    size: 1;
}

table rx_latency_calc_tbl
{
    actions
    {
        rx_latency_calc;
    }
    default_action: rx_latency_calc;
    size: 1;
}


// =========== Compute dv_abs  =================
action do_negate_dv()
{
    subtract(meta.lat_to_mem,0,meta.latency); // meta.dv_abs = - meta.latency
}
@pragma force_table_dependency rx_lat_delta_calc_tbl
table rx_dv_abs_negate_tbl
{
    actions
    {
        do_negate_dv;
    }
    default_action: do_negate_dv;
    size: 1;
}

action do_no_negate_dv()
{
    modify_field(meta.lat_to_mem,meta.latency); // copy 
}
@pragma force_table_dependency rx_lat_delta_calc_tbl
table rx_dv_abs_no_negate_tbl
{
    actions
    {
        do_no_negate_dv;
    }
    default_action: do_no_negate_dv;
    size: 1;
}



// =========== Detect lat_max & update rx_lat_maxA_reg =================

/*
* For lat_max processing:
* Retrieve last lat_max for this PGID
* Detect if cur lat_mem > prev & update only if it is bigger
* Store new max
*/
register rx_lat_maxA_reg
{
    width: 32;
    instance_count: 16384;
}

blackbox stateful_alu lat_max_detectorA_salu
{
    reg: rx_lat_maxA_reg; // prev lat_to_mem for lat_max detection
    condition_lo: meta.lat_to_mem > register_lo; // if lat_to_mem > prev

    update_lo_1_predicate: condition_lo; // if...
    update_lo_1_value: meta.lat_to_mem; // return val new lat_to_mem
    update_lo_2_predicate: not condition_lo; // else...
    update_lo_2_value: register_lo; // return val prev lat_to_mem
}

action do_rx_detect_lat_maxA()
{
    lat_max_detectorA_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}

@pragma force_table_dependency rx_latency_calc_tbl
table rx_lat_max_detectA_tbl
{
    actions
    {
        do_rx_detect_lat_maxA;
    }
    default_action: do_rx_detect_lat_maxA;
    size: 1;
}


// =========== Detect lat_min & update rx_lat_minA_reg =================

/*
* For lat_min processing:
* Retrieve last lat_min for this PGID
* Detect if cur lat_mem < prev & update only if it is smaller
* Store new min
*/
register rx_lat_minA_reg
{
    width: 32;
    instance_count: 16384;
}

blackbox stateful_alu lat_min_detectorA_salu
{
    reg: rx_lat_minA_reg; // prev lat_to_mem for lat_min detection
    condition_lo: meta.lat_to_mem < register_lo; // if lat_to_mem > prev

    update_lo_1_predicate: condition_lo; // if...
    update_lo_1_value: meta.lat_to_mem; // return val new lat_to_mem
    update_lo_2_predicate: not condition_lo; // else...
    update_lo_2_value: register_lo; // return val prev lat_to_mem
}

action do_rx_detect_lat_minA()
{
    lat_min_detectorA_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}


@pragma force_table_dependency rx_latency_calc_tbl
table rx_lat_min_detectA_tbl
{
    actions
    {
        do_rx_detect_lat_minA;
    }
    default_action: do_rx_detect_lat_minA;
    size: 1;
}

// ===========Accumulate lat_totA =================

/*
* For lat_tot processing:
* Retrieve last lat_tot for this PGID
* Add current lat_to_mem
* Store new tot
*/

register rx_lat_totA_reg
{
    width: 64;
    instance_count: 16384;
}
register rx_lat_totB_reg
{
    width: 64;
    instance_count: 16384;
}


blackbox stateful_alu lat_tot_detectorA_salu
{
    reg: rx_lat_totA_reg; // prev total for lat_tot detection
    condition_lo: meta.lat_to_mem + register_lo <= 0x7fffffff;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: meta.lat_to_mem + register_lo;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: meta.lat_to_mem_overflow + register_lo;
    update_hi_1_predicate: condition_lo;
    update_hi_1_value: register_hi;
    update_hi_2_predicate: not condition_lo;
    update_hi_2_value: register_hi + 1;
}
blackbox stateful_alu lat_tot_detectorB_salu
{
    reg: rx_lat_totB_reg; // prev total for lat_tot detection
    condition_lo: meta.lat_to_mem + register_lo <= 0x7fffffff;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: meta.lat_to_mem + register_lo;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: meta.lat_to_mem_overflow + register_lo;
    update_hi_1_predicate: condition_lo;
    update_hi_1_value: register_hi;
    update_hi_2_predicate: not condition_lo;
    update_hi_2_value: register_hi + 1;
}


action do_rx_calc_lat_totA()
{
    lat_tot_detectorA_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}
action do_rx_calc_lat_totB()
{
    lat_tot_detectorB_salu.execute_stateful_alu(meta.pgid_pipe_port_index);
}


@pragma force_table_dependency mode_tbl
@pragma force_table_dependency rx_latency_calc_tbl
@pragma force_table_dependency rx_copy_dv_to_lat_mem_tbl
table rx_lat_tot_detectA_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_rx_calc_lat_totA;
    }
    size: 1;
}
table rx_lat_tot_detectB_tbl
{
    reads
    {
        meta.bank_select: exact;
        meta.rx_instrum: exact;
    }
    actions
    {
        do_rx_calc_lat_totB;
    }
    size: 1;
}


action do_rx_calc_lat_high_totA()
{
    subtract(meta.lat_to_mem_overflow, meta.lat_to_mem, meta.lat_overflow);
}


table rx_lat_tot_high_detectA_tbl
{
    actions
    {
        do_rx_calc_lat_high_totA;
    }
    default_action: do_rx_calc_lat_high_totA;
    size: 1;
}

control process_rx_latency
{
    apply(rx_latency_calc_tbl);
    apply(rx_latency_store_overflow_tbl);
}

control process_abs_value_rx_latency
{
    if (meta.latency & 0x80000000 == 0)
    { // compute |delta latency| = "abs" delay variation
        apply(rx_dv_abs_no_negate_tbl);
    }
    else
    {
        apply(rx_dv_abs_negate_tbl);
    }
}

control process_value_rx_latency_overflow
{
    apply(rx_lat_tot_high_detectA_tbl);
}

//======= Control func =============
control process_ig_lat_stats
{
    apply(rx_lat_max_detectA_tbl); // assumes max initialized to 0
    apply(rx_lat_min_detectA_tbl); // assumes min initialized to MAX_INT_32
    apply(rx_lat_tot_detectA_tbl);
    apply(rx_lat_tot_detectB_tbl);
    if ((meta.known_flow == 0))
    {
        apply(rx_store_first_tstamp_tbl);
    }
}

/**
 * @control apply a rx offset to time stamp
 */
control calib_rx_tstamp {
  apply(do_calib_rx_tstamp_tbl);
}
# 107 "pktgen9.p4" 2
# 1 "rx_signature.p4" 1
/*------------------------------------------------------------------------
    rx_signature.p4 - Module to compare the parsed Ixia signature to the port's configured signature
                      Sets flag indicating that frame has instrumenation if signature matches.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_rx_instrum
{
    apply(rx_instrum_tbl);
}

table rx_instrum_tbl
{
    reads
    {
        big_sig.sig1: ternary;
        big_sig.sig2: ternary;
        big_sig.sig3: ternary;
        ig_intr_md.ingress_port : ternary;
    }
    actions
    {
        _nop;
        do_set_rx_instrum;
    }
    default_action: _nop;
    size: 288;
}

action do_set_rx_instrum()
{
    modify_field(meta.rx_instrum, 1);
}
# 108 "pktgen9.p4" 2
# 1 "rx_instrum.p4" 1
/*------------------------------------------------------------------------
    rx_instrum.p4 - Module to compute PGID register index for packet, and PGID counter index based on port indices
                    and PGID in frame

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

/*
  This control computes the PGID register index for latency, sequencing, and timestamps.
  The index is calculated by packing together the pipe port and PGID located in the instrumentation
*/

control pack_pgid_pipe_port
{
    apply(pack_pgid_pipe_port_tbl);
}

table pack_pgid_pipe_port_tbl
{
    actions
    {
        do_pack_pgid_pipe_port;
    }
    default_action: do_pack_pgid_pipe_port;
    size: 1;
}

action do_pack_pgid_pipe_port()
{
    modify_field_with_hash_based_offset(meta.pgid_pipe_port_index, 0, pgid_pipe_port_pack_hash,
                                                                      16384);
}

// The register index = (pipe_port) << 10 | pgid
// The register range is [0, 2^14 - 1] = [0, 16383]

field_list pgid_pipe_port_pack_hash_fields
{
    meta.pipe_port;
    meta.pgid;
}

field_list_calculation pgid_pipe_port_pack_hash
{
    input {pgid_pipe_port_pack_hash_fields; }
    algorithm: identity;
    output_width: 14;
}

/*
  This control computes the PGID counter index for frame and byte statistics.
  The index is calculated by packing together the fp port and PGID located in the instrumentation
*/

control pack_port_pgid
{
    apply(pack_port_pgid_tbl);
}

table pack_port_pgid_tbl
{
    actions
    {
        do_pack_port_pgid;
    }
    default_action: do_pack_port_pgid;
    size: 1;
}

action do_pack_port_pgid()
{
    modify_field_with_hash_based_offset(meta.port_pgid_index, 0, port_pgid_pack_hash, 32768);
}

// The counter index = (fp_port) << 10 | pgid
// The counter range is [0, 2^15 - 1] = [0, 32767]

field_list port_pgid_pack_hash_fields
{
    meta.fp_port;
    meta.pgid;
}

field_list_calculation port_pgid_pack_hash
{
    input {port_pgid_pack_hash_fields; }
    algorithm: identity;
    output_width: 15;
}
# 109 "pktgen9.p4" 2
# 1 "substreams.p4" 1
/*------------------------------------------------------------------------
    substreams.p4 - Extract and bit-pack the pktgen pipenum & appID into a primary stream ID

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// convenient way to extract and bit-pack
field_list pipeapp_pack_hash_fields
{
    pktgen_eth.pipe_id; // pipe 0-3 from pktgen metadata
    pktgen_eth.app_id; // app 0-7  from pktgen metadata
}
field_list_calculation pipeapp_pack_hash
{
    input { pipeapp_pack_hash_fields; }
    algorithm: identity;
    output_width: 5;
}

action do_pack_pipeapp()
{
    // pipeapp forms the stream number, no substreams
    modify_field_with_hash_based_offset(meta.stream, 0, pipeapp_pack_hash, 32);

}

// construct pipeapp from pktgen hdr
table pack_pipeapp_tbl
{
    actions
    {
        do_pack_pipeapp;
    }
    default_action: do_pack_pipeapp;
    size: 1;
}

control process_stream_ids
{
    apply(pack_pipeapp_tbl);
}

// Compute indices for stream counters and registers


control pack_stream_port
{
    apply(pack_stream_port_tbl);
}

table pack_stream_port_tbl
{
    actions
    {
        do_pack_stream_port;
    }
    default_action: do_pack_stream_port;
    size: 1;
}

action do_pack_stream_port()
{
    modify_field_with_hash_based_offset(meta.port_stream_index, 0, stream_port_pack_hash,
                                                                   1024);
}

// counter index for tx stream stats
// counter index is [0, 1024]
field_list stream_port_pack_hash_fields
{
    meta.tx_fp_port;
    meta.stream_offset;
}

field_list_calculation stream_port_pack_hash
{
    input { stream_port_pack_hash_fields; }
    algorithm: identity;
    output_width: 10;
}
# 110 "pktgen9.p4" 2
# 1 "g_pkt_cntr.p4" 1
/*------------------------------------------------------------------------
    g_pkt_cntr.p4 - Count global packets in egress pipeline per stream and port. 
                  - Implement bursts by counting packets to burst size.
                    Indices larger than burst size are dropped.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

header_type g_pkt_cntr_t
{
    fields
    {
        max : 16; // index of pkt in a series
        value : 16;
    }
}

header_type burst_pkt_cntr_t
{
    fields
    {
        max_hi : 32; // burst size for stream
        max_low: 32;
        drop : 4; // drop flag for stream
    }
}

metadata g_pkt_cntr_t g_pkt_cntr;
metadata burst_pkt_cntr_t burst_pkt_cntr;

// ==============  counter param loading ==============
// load g_pkt_cntr counter moduli into metadata for use by SALU in subsequent stage(s)
action do_load_g_pkt_cntr_counter_params(max)
{
    modify_field(g_pkt_cntr.max,max);
}

table load_g_pkt_cntr_params_tbl
{
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_load_g_pkt_cntr_counter_params;
    }
    default_action: do_load_g_pkt_cntr_counter_params;
    size: 1024;
}

// ==============  counter param loading ==============
// load burst_pkt_cntr counter moduli into metadata for use by SALU in subsequent stage(s)
action do_load_burst_pkt_cntr_counter_params(max_hi, max_low)
{
    modify_field(burst_pkt_cntr.max_hi,max_hi);
    modify_field(burst_pkt_cntr.max_low,max_low);
    modify_field(meta.burst_mode, 1);
}

table load_burst_pkt_cntr_params_tbl
{
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_load_burst_pkt_cntr_counter_params;
    }
    size: 1024;
}

// ----------- g_pkt_cntr ------------------
/*
 * Count from 0 to max
 */
register g_pkt_cntr_reg
{
    width: 16;
    instance_count: 1024;
}

// count from 0 up to max
blackbox stateful_alu g_pkt_cntr
{
    reg: g_pkt_cntr_reg;
    condition_lo : register_lo < g_pkt_cntr.max;

    // ALU lo maintains loop counter
    update_lo_1_predicate : condition_lo; // if counter not at max...
    update_lo_1_value : 1 + register_lo; // ...incr counter
    update_lo_2_predicate : not condition_lo; // if counter is max...
    update_lo_2_value : 0; // ...restart counter

    output_value : register_lo; // return next counter value
    output_dst : g_pkt_cntr.value; // ...into 
}

action do_g_pkt_cntr()
{
    g_pkt_cntr.execute_stateful_alu(meta.port_stream_index);
}

// wrapper to call SALU actionprocess_g_pkt_cntr
table g_pkt_cntr_tbl
{
    actions
    {
        do_g_pkt_cntr;
    }
    default_action: do_g_pkt_cntr;
    size: 1;
}

register burst_pkt_cntr_reg
{
    width: 64;
    instance_count: 1024;
}

// count from 0 up to max
blackbox stateful_alu burst_pkt_cntr
{
    reg: burst_pkt_cntr_reg;
    condition_lo : register_lo != burst_pkt_cntr.max_low;
    condition_hi : register_hi < burst_pkt_cntr.max_hi;
    // ALU lo maintains loop counter
    update_lo_1_predicate : condition_hi; // if counter not at max...
    update_lo_1_value : 1 + register_lo; // ...incr counter
    update_lo_2_predicate : not condition_hi; // if counter is max...
    update_lo_2_value : register_lo; // ...restart counter
    update_hi_1_predicate : condition_hi and not condition_lo;
    update_hi_1_value : 1 + register_hi;
    update_hi_2_predicate : not condition_hi;
    update_hi_2_value : register_hi;
    output_value : predicate; // return next counter value
    output_dst : burst_pkt_cntr.drop; // ...into 
}

action do_burst_pkt_cntr()
{
    burst_pkt_cntr.execute_stateful_alu(meta.port_stream_index);
}

// wrapper to call SALU actionprocess_g_pkt_cntr
table burst_pkt_cntr_tbl
{
    reads
    {
        meta.burst_mode: exact;
    }
    actions
    {
        _nop;
        do_burst_pkt_cntr;
    }
    default_action: _nop;
    size: 2;
}

control process_load_g_pkt_cntr
{
    apply(load_g_pkt_cntr_params_tbl);
}

control process_load_burst_pkt_cntr
{
    apply(load_burst_pkt_cntr_params_tbl);
}


control process_incr_g_pkt_cntr
{
    apply(g_pkt_cntr_tbl);
}

control process_incr_burst_pkt_cntr
{
    apply(burst_pkt_cntr_tbl);
}


action do_burst_drop()
{
    drop();
}


table burst_drop_tbl
{
    actions
    {
        do_burst_drop;
    }
    default_action: do_burst_drop;
    size: 1;
}
control process_burst_drops
{
    apply(burst_drop_tbl);
}
# 111 "pktgen9.p4" 2
# 1 "udf_vlist_mac_ip_tbl.p4" 1
/*------------------------------------------------------------------------
    udf_vlist_mac_ip_tbl.p4 - Module to modify protocol fields via MAU.
    Specifies protocol fields based on packet index.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


action do_modify_mac_ipv4(
        dmac0, dmac1, dmac2, dmac3, dmac4, dmac5,
        smac0, smac1, smac2, smac3, smac4, smac5,
        vid0, vid1,
        dipv4, sipv4,
        dipv6_0, dipv6_1, dipv6_2, dipv6_3,
        sipv6_0, sipv6_1, sipv6_2, sipv6_3,
        l4_src_port, l4_dest_port,
        pgid, sig3)
{
    modify_field(outer_eth.dstAddr0, dmac0);
    modify_field(outer_eth.dstAddr1, dmac1);
    modify_field(outer_eth.dstAddr2, dmac2);
    modify_field(outer_eth.dstAddr3, dmac3);
    modify_field(outer_eth.dstAddr4, dmac4);
    modify_field(outer_eth.dstAddr5, dmac5);
    modify_field(outer_eth.srcAddr0, smac0);
    modify_field(outer_eth.srcAddr1, smac1);
    modify_field(outer_eth.srcAddr2, smac2);
    modify_field(outer_eth.srcAddr3, smac3);
    modify_field(outer_eth.srcAddr4, smac4);
    modify_field(outer_eth.srcAddr5, smac5);

    modify_field(vlan_tag[0].vid, vid0);
    modify_field(vlan_tag[1].vid, vid1);

    modify_field(outer_ipv4.dstAddr, dipv4);
    modify_field(outer_ipv4.srcAddr, sipv4);

    modify_field(outer_ipv6.dstAddr0, dipv6_0);
    modify_field(outer_ipv6.srcAddr0, sipv6_0);
    modify_field(outer_ipv6.dstAddr1, dipv6_1);
    modify_field(outer_ipv6.srcAddr1, sipv6_1);
    modify_field(outer_ipv6.dstAddr2, dipv6_2);
    modify_field(outer_ipv6.srcAddr2, sipv6_2);
    modify_field(outer_ipv6.dstAddr3, dipv6_3);
    modify_field(outer_ipv6.srcAddr3, sipv6_3);

    modify_field(outer_tcp.srcPort, l4_src_port);
    modify_field(outer_tcp.dstPort, l4_dest_port);
//	modify_field(outer_udp.srcPort, l4_src_port);
//	modify_field(outer_udp.dstPort, l4_dest_port);

    modify_field(instrum.pgid, pgid);
    modify_field(big_sig.sig3, sig3);
}


table udf_vlist_mac_ip_tbl
{
    reads
    {
        meta.stream: ternary;
        g_pkt_cntr.value: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        _nop;
        do_modify_mac_ipv4;
    }
    default_action: _nop;
    size: 32770;
}

control process_udf_vlist_mac_ip
{
    apply(udf_vlist_mac_ip_tbl);
}
# 112 "pktgen9.p4" 2
# 1 "prepop_hdrs.p4" 1
/*------------------------------------------------------------------------
    prepop_hdrs.p4 - Module to modify protocol fields via MAU.
    Specifies MAC and IP addresses to insert into Ethernet and IP headers.
    Removes the pktgen header which is prepended from pktgen.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// --- populate hdr fields with looked-up values ---
// ALSO form a 16-bit meta.g_reg_index from packet # and 8 bit bank
action do_prepopulate_ether_ip(
        dmac0, dmac1, dmac2, dmac3, dmac4, dmac5,
        smac0, smac1, smac2, smac3, smac4, smac5,
        dipv4, sipv4)
{
    // invalidate pktgen hdr, create regular eth hdr, populate it
    add_header(outer_eth);
    modify_field(outer_eth.dstAddr0, dmac0);
    modify_field(outer_eth.dstAddr1, dmac1);
    modify_field(outer_eth.dstAddr2, dmac2);
    modify_field(outer_eth.dstAddr3, dmac3);
    modify_field(outer_eth.dstAddr4, dmac4);
    modify_field(outer_eth.dstAddr5, dmac5);
    modify_field(outer_eth.srcAddr0, smac0);
    modify_field(outer_eth.srcAddr1, smac1);
    modify_field(outer_eth.srcAddr2, smac2);
    modify_field(outer_eth.srcAddr3, smac3);
    modify_field(outer_eth.srcAddr4, smac4);
    modify_field(outer_eth.srcAddr5, smac5);

    // preserve etherType
    modify_field(outer_eth.etherType, pktgen_eth.etherType);
    remove_header(pktgen_eth);

    modify_field(outer_ipv4.dstAddr, dipv4);
    modify_field(outer_ipv4.srcAddr, sipv4);
}

// populate_ether - action wrapper table
table eg_prepop_hdr_and_g_reg_tbl
{
    reads
    {
        meta.stream : ternary;
        eg_intr_md.egress_port : ternary;
        meta.is_pktgen : exact;
    }
    actions
    {
        do_prepopulate_ether_ip;
    }
    size: 1024;
}

control process_prepopulate_hdr_g_reg
{
    apply(eg_prepop_hdr_and_g_reg_tbl);
}
# 113 "pktgen9.p4" 2
# 1 "timestamp.p4" 1
/*------------------------------------------------------------------------
    timestamp.p4 - Module to slice 48 bit timestamp into two 32 bit values to store into registers.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

header_type timestamp_t
{
    fields
    {
        lower: 32;
        upper: 32;
    }
}

metadata timestamp_t rx_packet_timestamp;
metadata timestamp_t tx_packet_timestamp;


@pragma field_list_field_slice eg_intr_md_from_parser_aux.egress_global_tstamp 31 0
field_list eg_tstamp_lower_field_list
{
    eg_intr_md_from_parser_aux.egress_global_tstamp;
}

field_list_calculation eg_tstamp_lower_hash
{
    input
    {
        eg_tstamp_lower_field_list;
    }
    algorithm: identity;
    output_width: 32;
}

action do_extract_eg_tstamp_lower()
{
    modify_field_with_hash_based_offset(tx_packet_timestamp.lower, 0, eg_tstamp_lower_hash, 4294967296);
}

table extract_eg_tstamp_lower_tbl
{
    actions
    {
        do_extract_eg_tstamp_lower;
    }
    default_action: do_extract_eg_tstamp_lower;
    size: 1;
}

@pragma field_list_field_slice eg_intr_md_from_parser_aux.egress_global_tstamp 47 32
field_list eg_tstamp_upper_field_list
{
    eg_intr_md_from_parser_aux.egress_global_tstamp;
}

field_list_calculation eg_tstamp_upper_hash
{
    input
    {
        eg_tstamp_upper_field_list;
    }
    algorithm: identity;
    output_width: 32;
}

action do_extract_eg_tstamp_upper()
{
    modify_field_with_hash_based_offset(tx_packet_timestamp.upper, 0, eg_tstamp_upper_hash, 4294967296);
}

table extract_eg_tstamp_upper_tbl
{
    actions
    {
        do_extract_eg_tstamp_upper;
    }
    default_action: do_extract_eg_tstamp_upper;
    size: 1;
}

control process_egress_tstamp_lower
{
    apply(extract_eg_tstamp_lower_tbl);
}

control process_egress_tstamp_upper
{
    apply(extract_eg_tstamp_upper_tbl);
}

@pragma field_list_field_slice ig_intr_md.ingress_mac_tstamp 31 0
field_list ig_tstamp_lower_field_list
{
    ig_intr_md.ingress_mac_tstamp;
}

field_list_calculation ig_tstamp_lower_hash
{
    input
    {
        ig_tstamp_lower_field_list;
    }
    algorithm: identity;
    output_width: 32;
}

action do_extract_ig_tstamp_lower()
{
    modify_field_with_hash_based_offset(rx_packet_timestamp.lower, 0, ig_tstamp_lower_hash, 4294967296);
}

table extract_ig_tstamp_lower_tbl
{
    actions
    {
        do_extract_ig_tstamp_lower;
    }
    default_action: do_extract_ig_tstamp_lower;
    size: 1;
}

@pragma field_list_field_slice ig_intr_md.ingress_mac_tstamp 47 32
field_list ig_tstamp_upper_field_list
{
    ig_intr_md.ingress_mac_tstamp;
}

field_list_calculation ig_tstamp_upper_hash
{
    input
    {
        ig_tstamp_upper_field_list;
    }
    algorithm: identity;
    output_width: 32;
}

action do_extract_ig_tstamp_upper()
{
    modify_field_with_hash_based_offset(rx_packet_timestamp.upper, 0, ig_tstamp_upper_hash, 4294967296);
}

table extract_ig_tstamp_upper_tbl
{
    actions
    {
        do_extract_ig_tstamp_upper;
    }
    default_action: do_extract_ig_tstamp_upper;
    size: 1;
}

control process_ingress_tstamp_lower
{
    apply(extract_ig_tstamp_lower_tbl);
}

control process_ingress_tstamp_upper
{
    apply(extract_ig_tstamp_upper_tbl);
}

action eg_ts_copy_act(ts_offset, l4_checksum_offset) {
    add_header(ptp);
    modify_field(ptp.cf_byte_offset, ts_offset);
    modify_field(ptp.udp_cksum_byte_offset, l4_checksum_offset);
    modify_field(ptp.updated_cf, 0);
    modify_field(eg_intr_md_for_oport.update_delay_on_tx,1);
    remove_header(instrum_tstamp);
}
table eg_ts_copy {
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions {
        eg_ts_copy_act;
        _nop;
    }
    default_action: _nop;
    size: 1024;
}

control process_eg_ts_copy
{
    apply(eg_ts_copy);
}
# 114 "pktgen9.p4" 2
# 1 "pcie_cpu_port.p4" 1
/*------------------------------------------------------------------------
    pcie_cpu_port.p4 - Module to extract PCIE CPU Port from control plane and input into metadata.
                       This is needed because each Tofino chip variant has a different PCIE CPU port.
                       Module handles switching of frame between PCPU and PCIE CPU Port.
                       This involves stripping the fabric header on frame from the PCPU and inserting fabric header
                       on frame to the PCPU.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

header_type pcie_cpu_port_t
{
    fields
    {
        enabled: 1;
        ingress_port: 9;
    }
}

metadata pcie_cpu_port_t pcie_cpu_port;


action load_cpu_enabled_parameter()
{
    modify_field(pcie_cpu_port.enabled, 1);
    modify_field(pcie_cpu_port.ingress_port,ig_intr_md.ingress_port);
}

table load_cpu_enabled_parameter_tbl
{
    reads
    {
        ig_intr_md.ingress_port: ternary;
    }
    actions
    {
        _nop;
        load_cpu_enabled_parameter;
    }
    default_action: _nop;
}

control process_load_cpu_parameters
{
    apply(load_cpu_enabled_parameter_tbl);
}

//
// Insert metadata headers for packet coming from frontpanel port
//



header_type pad_7b_t
{
    fields
    {
        pad0: 7;
    }
}
metadata pad_7b_t pad7b;

field_list send_to_cpu_bridged_md
{
    pcie_cpu_port.ingress_port; //  9 bits
    pad7b.pad0;
}

action do_clone_to_cpu(cpu_mirror_id)
{
    modify_field(pcie_cpu_port.ingress_port, ig_intr_md.ingress_port);
    clone_ingress_pkt_to_egress(cpu_mirror_id,send_to_cpu_bridged_md);
    drop();
}

table send_to_cpu_tbl
{
    actions
    {
        do_clone_to_cpu;
    }
    default_action: do_clone_to_cpu(100);
    size: 1;
}

action set_fabric_hdr()
{
    add_header(fabric_hdr);
    modify_field(fabric_hdr.devPort, pcie_cpu_port.ingress_port);
    modify_field(fabric_hdr.etherType, outer_eth.etherType);
    modify_field(outer_eth.etherType, 0x9090);
}

table set_fabric_hdr_tbl
{
    reads
    {
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        set_fabric_hdr;
        _nop;
    }
    default_action: _nop;
    size: 1;
}

//
// Set egress port and ethernet type according to the fabric_hdr passed from CPU port.
//
action set_md_from_fabric_hdr()
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, fabric_hdr.devPort);
    modify_field(outer_eth.etherType, fabric_hdr.etherType);
    remove_header(fabric_hdr);
}

//
// Handle packets coming from CPU port
//
table select_egress_port_tbl
{
    actions
    {
        set_md_from_fabric_hdr;
    }
    default_action: set_md_from_fabric_hdr;
    size: 1;
}
# 115 "pktgen9.p4" 2

//
// Common drop action
//
action common_drop_pkt()
{
  drop();
}
//
// Common no operation action
//
action _nop()
{
}

//
// This table invokes the drop action, TODO: count dropped packets
//
table common_drop_tbl
{
    actions
    {
        common_drop_pkt;
    }
    default_action: common_drop_pkt;
    size: 1;
}

//==============================================
// ============== Ingress control ==============
//==============================================
control ingress
{
   /*
    * apply rx offset to time stamp 
    */
    calib_rx_tstamp();
    process_rx_instrum();
    process_bank_select_reg();
    process_generate_random_number();
    process_ingress_fp_port();
    process_load_cpu_parameters();
    process_stream_ids();
    process_ig_port_stats();
    process_rx_latency();
    pack_port_pgid();
    pack_pgid_pipe_port();
    process_abs_value_rx_latency();
    process_ig_pgid_statsA();
    process_value_rx_latency_overflow();
    process_ingress_tstamp_lower();
    process_ingress_tstamp_upper();
    process_ig_pgid_tstampA();
    process_ig_pgid_tstampB();
    if(meta.is_pktgen == 1)
    {
        apply(ig_port_tbl);
        apply(ig_recirc_port_tbl);
    }
    else if (0 == ig_intr_md.resubmit_flag and fabric_hdr.valid == 1 and
    pcie_cpu_port.enabled == 1)
    {
        apply(select_egress_port_tbl);
    }
    else if(meta.rx_instrum == 1)
    {
        process_rx_pgid_flow_tracking();
        process_ig_seq_stats();
        process_ig_lat_stats();
        apply(common_drop_tbl);
    }
    else
    {
        apply(send_to_cpu_tbl);
    }
    process_ig_pgid_statsB();
}

//================================
//========= EGRESS PIPELINE ======
//================================
# 1 "tx_instrum.p4" 1
/*------------------------------------------------------------------------
    tx_instrum.p4 - Module to compute register index for sequence number and insert timestamp and corresponding
                    sequence number into Ixia instrumentation if there is an Ixia signature in the stream.
                    The existence of a signature is programmed by the control plane per stream. 

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

/*
  This control computes the sequence number register index
  The index is calculated by packing together the pipe port and PGID located in the instrumentation
*/

// ----------- Generate incrementing seqnums per pgid ------------------
/*
 * For seq_incr processing:
 * Just count up
 */
register tx_seq_incr_reg
{
    width: 32;
    instance_count: 16384;
}

// count by one, store per pgid
blackbox stateful_alu seq_incr_gen
{
    reg: tx_seq_incr_reg;
    update_lo_1_value : register_lo + 1; // ...incr seqnum and store it
    output_value : alu_lo; // return next seqnum
    output_dst : instrum.seqnum; // ...into 
}

action do_incr_seqnum()
{
    seq_incr_gen.execute_stateful_alu(meta.pgid_pipe_port_index);
}

// This MUST compile into a stage after PGID is composed to ensure register index is updated
// use pragma if necesary
table incr_seqnum_tbl
{
    actions
    {
        do_incr_seqnum;
    }
    default_action: do_incr_seqnum;
    size: 1;
}


// --- populate instrumentation fields other than seqnum ---
action do_populate_instrum()
{
    // Egress Timestamp 
    modify_field(instrum_tstamp.tstamp, eg_intr_md_from_parser_aux.egress_global_tstamp);
    // generated seqnum - populated in SALU seq_incr_gen
}


// populate instrumentation - action wrapper table
table eg_populate_instrum_tbl
{
    actions
    {
        do_populate_instrum;
    }
    default_action: do_populate_instrum;
    size: 1;
}

/**
 * Apply an additive offset to the tx time stamp
 * @param offset in ns
 * @return instrum.tstamp is modified with additive offset
 */
action do_calib_tx_tstamp(offset) {
  add_to_field(instrum_tstamp.tstamp, offset);
}

/**
 * @table Invokes do_calib_tx_tstamp(offset)
 */
table do_calib_tx_tstamp_tbl {
    reads
    {
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_calib_tx_tstamp;
        _nop;
    }
    default_action: _nop;
    size: 1024;
}

control process_tx_instrum
{
    apply(incr_seqnum_tbl);
    if(meta.mac_timestamp_enable == 1)
    {
        apply(eg_ts_copy);
    }
    else
    {
        apply(eg_populate_instrum_tbl);
        apply(do_calib_tx_tstamp_tbl);
    }
}

/**
 * @control apply a tx offset to time stamp
 */
control calib_tx_tstamp {
  apply(do_calib_tx_tstamp_tbl);
}

control pack_stream_pgid
{
    apply(pack_stream_pgid_tbl);
}

table pack_stream_pgid_tbl
{
    actions
    {
        do_pack_stream_pgid;
    }
    default_action: do_pack_stream_pgid;
    size: 1;
}

action do_pack_stream_pgid()
{
    modify_field_with_hash_based_offset(meta.pgid_pipe_port_index, 0, stream_pgid_pack_hash,
                                        16384);
}

field_list stream_pgid_pack_hash_fields
{
    pktgen_eth.app_id;
    meta.tx_pgid;
}

field_list_calculation stream_pgid_pack_hash
{
    input {stream_pgid_pack_hash_fields; }
    algorithm: identity;
    output_width: 14;
}

control process_tx_instrum_pktgen
{
    apply(set_tx_instrum_pktgen_tbl);
}

table set_tx_instrum_pktgen_tbl
{
    reads
    {
        meta.stream : ternary;
        eg_intr_md.egress_port : ternary;
    }
    actions
    {
        _nop;
        set_tx_instrum_pktgen;
    }
    default_action: _nop;
    size: 1024;
}

action set_tx_instrum_pktgen()
{
    modify_field(meta.tx_instrum, 1);
}
# 197 "pktgen9.p4" 2
# 1 "eg_stats.p4" 1
/*------------------------------------------------------------------------
    eg_stats.p4 - Module to compute statistics for egress ports.
    Computes transmit port and per stream statistics.
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

//============= Egress stream stats BankA===================
// Counts packets which egressed per stream
counter eg_stream_statsA_cntr
{
    type: packets_and_bytes;
    instance_count: 1024;
}

// count per-stream egress pkts/bytes
action do_eg_stream_statsA()
{
    count(eg_stream_statsA_cntr, meta.port_stream_index);
}

// count stream stats - action wrapper table
table eg_stream_statsA_tbl
{
    actions
    {
        do_eg_stream_statsA;
    }
    default_action: do_eg_stream_statsA;
    size: 1;
}

counter eg_stream_statsB_cntr
{
    type: packets_and_bytes;
    instance_count: 1024;
}

// count per-stream egress pkts/bytes
action do_eg_stream_statsB()
{
    count(eg_stream_statsB_cntr, meta.port_stream_index);
}

// count stream stats - action wrapper table
table eg_stream_statsB_tbl
{
    actions
    {
        do_eg_stream_statsB;
    }
    default_action: do_eg_stream_statsB;
    size: 1;
}

//============= Egress port pkt stats BankA===================

counter eg_port_queue_stats_cntrA
{
    type: packets_and_bytes;
    direct: eg_port_queue_statsA_tbl;
}

table eg_port_queue_statsA_tbl
{
    reads
    {
        eg_intr_md.egress_qid: exact;
        eg_intr_md.egress_port: exact;
    }
    actions
    {
        _nop;
    }
    size: 1024;
}

counter eg_port_queue_stats_cntrB
{
    type: packets_and_bytes;
    direct: eg_port_queue_statsB_tbl;
}

table eg_port_queue_statsB_tbl
{
    reads
    {
        eg_intr_md.egress_qid: exact;
        eg_intr_md.egress_port: exact;
    }
    actions
    {
        _nop;
    }
    size: 1024;
}


// Counts packets which egressed per port
counter eg_port_stats_cntrA
{
    type: packets_and_bytes;
    instance_count: 512;
}

// count egress pkts/bytes
action do_eg_port_statsA()
{
    count(eg_port_stats_cntrA, eg_intr_md.egress_port);
}

// send pkts - action wrapper table
table eg_port_statsA_tbl
{
    actions
    {
        do_eg_port_statsA;
    }
    default_action: do_eg_port_statsA;
    size: 1;
}

register tx_egress_stamp_regA
{
    width: 64;
    instance_count: 1024;
}


blackbox stateful_alu store_egress_tstampA_salu
{
    reg: tx_egress_stamp_regA;
    update_lo_1_value: tx_packet_timestamp.lower;
    update_hi_1_value: tx_packet_timestamp.upper;
}

action do_store_egress_stampA()
{
    store_egress_tstampA_salu.execute_stateful_alu(meta.port_stream_index);
}

table tx_tstampA_tbl
{
    actions
    {
        do_store_egress_stampA;
    }
    default_action: do_store_egress_stampA;
    size: 1;
}


register tx_egress_stamp_regB
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu store_egress_tstampB_salu
{
    reg: tx_egress_stamp_regB;
    update_lo_1_value: tx_packet_timestamp.lower;
    update_hi_1_value: tx_packet_timestamp.upper;
}

action do_store_egress_stampB()
{
    store_egress_tstampB_salu.execute_stateful_alu(meta.port_stream_index);
}

table tx_tstampB_tbl
{
    actions
    {
        do_store_egress_stampB;
    }
    default_action: do_store_egress_stampB;
    size: 1;
}



//=============  Control wrappers ===================

control process_eg_stream_stats
{
    if (meta.bank_select == 1)
    {
        apply(eg_stream_statsB_tbl);
        apply(tx_tstampB_tbl);
    }
    else
    {
        apply(eg_stream_statsA_tbl);
        apply(tx_tstampA_tbl);
    }
}

control process_eg_port_stats
{
    if(meta.bank_select_port_stats == 1)
    {
        apply(eg_port_queue_statsB_tbl);
    }
    else if(meta.bank_select_port_stats == 0)
    {
        apply(eg_port_queue_statsA_tbl);
    }
    apply(eg_port_statsA_tbl);
}
# 198 "pktgen9.p4" 2
# 1 "counter_udf.p4" 1
/*------------------------------------------------------------------------
    counter_udf.p4 - Module to modify protocol fields via nested counters.
    Specifies protocol fields for each UDF(User Defined Field). 

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

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
metadata udf_cntr_t udf2_cntr;

// These values are loaded on the ingress side from the packet generator
action do_load_udf1_cntr_params(repeat, step, stutter, enable)
{
    modify_field(udf1_cntr.repeat, repeat);
    modify_field(udf1_cntr.step, step);
    modify_field(udf1_cntr.enable, enable);
    modify_field(udf1_cntr.stutter, stutter);
}

table load_udf1_cntr_params_tbl
{
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_load_udf1_cntr_params;
    }
    size: 1024;
}

action do_load_udf1_cntr_params_ingress(nested_repeat, nested_step, bit_mask)
{
    modify_field(udf1_cntr.nested_repeat, nested_repeat);
    modify_field(udf1_cntr.nested_step, nested_step);
    modify_field(udf1_cntr.bit_mask, bit_mask);
}

table load_udf1_cntr_params_ingress_tbl
{
    reads
    {
        meta.stream: ternary;
        ig_intr_md.ingress_port: ternary;
    }
    actions
    {
        do_load_udf1_cntr_params_ingress;
    }
    size: 1024;
}


// These values are loaded on the ingress side from the packet generator 
action do_load_udf2_cntr_params(repeat, step, stutter, enable)
{
    modify_field(udf2_cntr.repeat, repeat);
    modify_field(udf2_cntr.step, step);
    modify_field(udf2_cntr.stutter, stutter);
    modify_field(udf2_cntr.enable, enable);
}

table load_udf2_cntr_params_tbl
{
    reads
    {
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_load_udf2_cntr_params;
    }
    size: 1024;
}

action do_load_udf2_cntr_params_ingress(nested_repeat, nested_step, bit_mask)
{
    modify_field(udf2_cntr.nested_repeat, nested_repeat);
    modify_field(udf2_cntr.nested_step, nested_step);
    modify_field(udf2_cntr.bit_mask, bit_mask);
}

table load_udf2_cntr_params_ingress_tbl
{
    reads
    {
        meta.stream: ternary;
        ig_intr_md.ingress_port: ternary;
    }
    actions
    {
        do_load_udf2_cntr_params_ingress;
    }
    size: 1024;
}


control process_load_udf_cntr_params_ingress
{
    apply(load_udf1_cntr_params_ingress_tbl);
    apply(load_udf2_cntr_params_ingress_tbl);
}

control process_load_udf1_cntr_params
{
    apply(load_udf1_cntr_params_tbl);
}

control process_load_udf2_cntr_params
{
    apply(load_udf2_cntr_params_tbl);
}

register udf1_cntr_conditional_reg
{
    width: 64;
    instance_count: 1024;
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
    udf1_cntr_compute_conditional.execute_stateful_alu(meta.port_stream_index);
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

register udf1_inner_cntr_reg
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu udf1_inner_cntr
{
    reg: udf1_inner_cntr_reg;
    // Inner repeat count has not rolled over and stutter is done 
    condition_lo: udf1_cntr.update_inner_true == 2;
    // Inner repeat count has rolled over and stutter is done
    condition_hi: udf1_cntr.update_inner_true == 1;
    update_lo_1_predicate: condition_lo;
    // Update inner loop counter
    update_lo_1_value: register_lo + udf1_cntr.step;
    update_lo_2_predicate: condition_hi;
    // Reset inner loop counter
    update_lo_2_value: 0;
    output_value: register_lo;
    output_dst: udf1_cntr.final_value;
}

action do_compute_udf1_inner_cntr()
{
    udf1_inner_cntr.execute_stateful_alu(meta.port_stream_index);
}

table compute_udf1_inner_cntr_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_compute_udf1_inner_cntr;
    }
    size: 1;
}

register udf1_nested_cntr_udf_reg
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu udf1_nested_cntr_udf
{
    reg: udf1_nested_cntr_udf_reg;
    // Outer repeat count has not rolled over
    condition_lo: register_lo + 1 <= udf1_cntr.nested_repeat;
    update_lo_1_predicate: condition_lo;
    // Update outer repeat count 
    update_lo_1_value: register_lo + 1;
    update_lo_2_predicate: not condition_lo;
    // Reset outer repeat count
    update_lo_2_value: 0;
    update_hi_1_predicate: condition_lo;
    // Increment nested counter
    update_hi_1_value: register_hi + udf1_cntr.nested_step;
    update_hi_2_predicate: not condition_lo;
    // Reset nested counter
    update_hi_2_value: 0;
    output_value: register_hi;
    output_dst: udf1_cntr.nested_final_value;
}

blackbox stateful_alu udf1_nested_cntr_udf_read
{
    reg: udf1_nested_cntr_udf_reg;
    update_hi_1_value: register_hi;
    output_value: alu_hi;
    output_dst: udf1_cntr.nested_final_value;
}


action do_udf1_nested_cntr_udf()
{
    udf1_nested_cntr_udf.execute_stateful_alu(meta.port_stream_index);
}

action do_udf1_nested_cntr_udf_read()
{
    udf1_nested_cntr_udf_read.execute_stateful_alu(meta.port_stream_index);
}


table udf1_nested_cntr_udf_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_udf1_nested_cntr_udf;
    }
    size: 1;
}

table udf1_nested_cntr_udf_read_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_udf1_nested_cntr_udf_read;
    }
    size: 1;
}

register udf1_cntr_udf_rollover_reg
{
    width: 64;
    instance_count: 1024;
}

// programmed with thresholds from control plane
// if the UDF is incrementing the initial value of register_lo is max_value + 1 and register_hi is MAX_UINT32
// if the UDF is decrementing the initial value of register_lo is 0 and register_hi is min_value - 1
blackbox stateful_alu udf1_cntr_udf_rollover
{
    reg: udf1_cntr_udf_rollover_reg;
    // Check if inner counter is less than maximum value for incrementing counter
    condition_lo: udf1_cntr.final_value < register_lo;
    // Check if inner counter is greater than minimum value for decrementing counter
    condition_hi: udf1_cntr.final_value > register_hi;
    output_value: predicate;
    output_dst: udf1_cntr.rollover_true;
}

action do_udf1_cntr_udf_rollover()
{
    udf1_cntr_udf_rollover.execute_stateful_alu(meta.port_stream_index);
}

table udf1_cntr_udf_rollover_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_udf1_cntr_udf_rollover;
    }
    size: 1;
}


action do_udf1_cntr_udf_update(update_value)
{
    add_to_field(udf1_cntr.final_value, update_value);
}

// Will be two entries per stream
// One for normal condition, and one for rollover condition
// In normal condition, update_value = inital value of UDF 
// In rollover condition for incrementing UDF, update_value = (min - (max - init) + step)
// For decrementing UDF, update_value = initial value of UDF
// In rollover condition for decrementing UDF, update_value = (max + (init - min) + step)
table update_udf1_cntr_udf_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
        udf1_cntr.rollover_true: exact;
        meta.stream: exact;
        eg_intr_md.egress_port: exact;
    }
    actions
    {
        do_udf1_cntr_udf_update;
    }
    size: 64;
}

action do_udf1_cntr_udf_update_nested()
{
    add_to_field(udf1_cntr.final_value, udf1_cntr.nested_final_value);
}

table update_udf1_cntr_udf_nested_tbl
{
    reads
    {
        udf1_cntr.enable: exact;
    }
    actions
    {
        do_udf1_cntr_udf_update_nested;
    }
    size: 1;
}



action do_udf1_cntr_ipv4_src_32()
{
    modify_field(outer_ipv4.srcAddr, udf1_cntr.final_value, 0xffffffff);
}

action do_udf1_cntr_ipv4_src_24()
{
    modify_field(outer_ipv4.srcAddr, udf1_cntr.final_value, 0xffffff);
}

action do_udf1_cntr_ipv4_src_16()
{
    modify_field(outer_ipv4.srcAddr, udf1_cntr.final_value, 0xffff);
}

action do_udf1_cntr_ipv4_src_8()
{
    modify_field(outer_ipv4.srcAddr, udf1_cntr.final_value, 0xff);
}


table udf1_cntr_udf_tbl
{
    reads
    {
        udf1_cntr.bit_mask: exact;
        udf1_cntr.enable: exact;
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_udf1_cntr_ipv4_src_32;
        do_udf1_cntr_ipv4_src_24;
        do_udf1_cntr_ipv4_src_16;
        do_udf1_cntr_ipv4_src_8;
    }
    size: 1024;
}

register udf2_cntr_conditional_reg
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu udf2_cntr_compute_conditional
{
    reg: udf2_cntr_conditional_reg;
    // UDF inner loop pattern is not finished
    condition_lo: register_lo + 1 <= udf2_cntr.repeat;
    // UDF inner loop stutter is not finished
    condition_hi: register_hi + 1 <= udf2_cntr.stutter;
    // If inner loop pattern is not finished and stutter is finished
    update_lo_1_predicate: condition_lo and not condition_hi;
    // ... then increment inner loop counter
    update_lo_1_value: register_lo + 1;
    // If inner loop patterm is finished and stutter is finished 
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
    output_dst: udf2_cntr.update_inner_true;
}

action do_udf2_cntr_compute_conditional()
{
    udf2_cntr_compute_conditional.execute_stateful_alu(meta.port_stream_index);
}

table compute_conditional_udf2_cntr_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_udf2_cntr_compute_conditional;
    }
    size: 1;
}

register udf2_inner_cntr_reg
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu udf2_inner_cntr
{
    reg: udf2_inner_cntr_reg;
    // Inner repeat count has not rolled over and stutter is done 
    condition_lo: udf2_cntr.update_inner_true == 2;
    // Inner repeat count has rolled over and stutter is done
    condition_hi: udf2_cntr.update_inner_true == 1;
    update_lo_1_predicate: condition_lo;
    // Update inner loop counter
    update_lo_1_value: register_lo + udf2_cntr.step;
    update_lo_2_predicate: condition_hi;
    // Reset inner loop counter
    update_lo_2_value: 0;
    output_value: register_lo;
    output_dst: udf2_cntr.final_value;
}

action do_compute_udf2_inner_cntr()
{
    udf2_inner_cntr.execute_stateful_alu(meta.port_stream_index);
}

table compute_udf2_inner_cntr_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_compute_udf2_inner_cntr;
    }
    size: 1;
}

register udf2_nested_cntr_udf_reg
{
    width: 64;
    instance_count: 1024;
}

blackbox stateful_alu udf2_nested_cntr_udf
{
    reg: udf2_nested_cntr_udf_reg;
    // Outer repeat count has not rolled over
    condition_lo: register_lo + 1 <= udf2_cntr.nested_repeat;
    update_lo_1_predicate: condition_lo;
    // Update outer repeat count 
    update_lo_1_value: register_lo + 1;
    update_lo_2_predicate: not condition_lo;
    // Reset outer repeat count
    update_lo_2_value: 0;
    update_hi_1_predicate: condition_lo;
    // Increment nested counter
    update_hi_1_value: register_hi + udf2_cntr.nested_step;
    update_hi_2_predicate: not condition_lo;
    // Reset nested counter
    update_hi_2_value: 0;
    output_value: register_hi;
    output_dst: udf2_cntr.nested_final_value;
}

blackbox stateful_alu udf2_nested_cntr_udf_read
{
    reg: udf2_nested_cntr_udf_reg;
    update_hi_1_value: register_hi;
    output_value: alu_hi;
    output_dst: udf2_cntr.nested_final_value;
}


action do_udf2_nested_cntr_udf()
{
    udf2_nested_cntr_udf.execute_stateful_alu(meta.port_stream_index);
}

action do_udf2_nested_cntr_udf_read()
{
    udf2_nested_cntr_udf_read.execute_stateful_alu(meta.port_stream_index);
}


table udf2_nested_cntr_udf_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_udf2_nested_cntr_udf;
    }
    size: 1;
}

table udf2_nested_cntr_udf_read_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_udf2_nested_cntr_udf_read;
    }
    size: 1;
}

register udf2_cntr_udf_rollover_reg
{
    width: 64;
    instance_count: 1024;
}

// programmed with threshold from control plane
// if the UDF is incrementing the initial value of register_lo is max_value + 1 and register_hi is MAX_UINT32
// if the UDF is decrementing the initial value of register_lo is 0 and register_hi is min_value - 1
blackbox stateful_alu udf2_cntr_udf_rollover
{
    reg: udf2_cntr_udf_rollover_reg;
    // Check if inner counter is less than maximum value for incrementing counter
    condition_lo: udf2_cntr.final_value < register_lo;
    // Check if inner counter is greater than minimum value for decrementing counter
    condition_hi: udf2_cntr.final_value > register_hi;
    output_value: predicate;
    output_dst: udf2_cntr.rollover_true;
}

action do_udf2_cntr_udf_rollover()
{
    udf2_cntr_udf_rollover.execute_stateful_alu(meta.port_stream_index);
}

table udf2_cntr_udf_rollover_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_udf2_cntr_udf_rollover;
    }
    size: 1;
}


action do_udf2_cntr_udf_update(update_value)
{
    add_to_field(udf2_cntr.final_value, update_value);
}

// Will be two entries per stream
// One for normal condition, and one for rollover condition
// In normal condition, update_value = inital value of UDF 
// In rollover condition for incrementing UDF, update_value = (min - (max - init) + step)
// For decrementing UDF, update_value = initial value of UDF
// In rollover condition for decrementing UDF, update_value = (max + (init - min) + step)
table update_udf2_cntr_udf_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
        udf2_cntr.rollover_true: exact;
        meta.stream: exact;
        eg_intr_md.egress_port: exact;
    }
    actions
    {
        do_udf2_cntr_udf_update;
    }
    size: 64;
}

action do_udf2_cntr_udf_update_nested()
{
    add_to_field(udf2_cntr.final_value, udf2_cntr.nested_final_value);
}

table update_udf2_cntr_udf_nested_tbl
{
    reads
    {
        udf2_cntr.enable: exact;
    }
    actions
    {
        do_udf2_cntr_udf_update_nested;
    }
    size: 1;
}


action do_udf2_cntr_ipv4_dest_32()
{
    modify_field(outer_ipv4.dstAddr, udf2_cntr.final_value, 0xffffffff);
}

action do_udf2_cntr_ipv4_dest_24()
{
    modify_field(outer_ipv4.dstAddr, udf2_cntr.final_value, 0xffffff);
}

action do_udf2_cntr_ipv4_dest_16()
{
    modify_field(outer_ipv4.dstAddr, udf2_cntr.final_value, 0xffff);
}

action do_udf2_cntr_ipv4_dest_8()
{
    modify_field(outer_ipv4.dstAddr, udf2_cntr.final_value, 0xff);
}


table udf2_cntr_udf_tbl
{
    reads
    {
        udf2_cntr.bit_mask: exact;
        udf2_cntr.enable: exact;
        meta.stream: ternary;
        eg_intr_md.egress_port: ternary;
    }
    actions
    {
        do_udf2_cntr_ipv4_dest_32;
        do_udf2_cntr_ipv4_dest_24;
        do_udf2_cntr_ipv4_dest_16;
        do_udf2_cntr_ipv4_dest_8;
    }
    size: 1024;
}


control process_compute_conditional_cntr_udf
{
    apply(compute_conditional_udf1_cntr_tbl);
    apply(compute_conditional_udf2_cntr_tbl);
}


control process_compute_inner_cntr_udf
{
    apply(compute_udf1_inner_cntr_tbl);
    apply(compute_udf2_inner_cntr_tbl);
}


control process_intermediate_inner_cntr_udf
{
    apply(udf1_cntr_udf_rollover_tbl);
    apply(udf2_cntr_udf_rollover_tbl);
}

control process_intermediate_outer_cntr_udf
{
    if(udf1_cntr.update_inner_true == 1)
    {
        apply(udf1_nested_cntr_udf_tbl);
    }
    else
    {
        apply(udf1_nested_cntr_udf_read_tbl);
    }
    if(udf2_cntr.update_inner_true == 1)
    {
        apply(udf2_nested_cntr_udf_tbl);
    }
    else
    {
        apply(udf2_nested_cntr_udf_read_tbl);
    }
}


control process_update_cntr_udf
{
    apply(update_udf1_cntr_udf_tbl);
    apply(update_udf2_cntr_udf_tbl);
}

control process_update_cntr_udf_nested
{
    apply(update_udf1_cntr_udf_nested_tbl);
    apply(update_udf2_cntr_udf_nested_tbl);
}

control process_cntr_udf
{
    apply(udf1_cntr_udf_tbl);
    apply(udf2_cntr_udf_tbl);
}
# 199 "pktgen9.p4" 2
//============== Egress control =================

control egress
{
    process_bank_select_port_stats_reg();
    apply(eg_remap_stream_tbl);
    process_egress_tstamp_lower();
    process_egress_tstamp_upper();
    process_egress_fp_port();
    process_load_burst_pkt_cntr();
    process_load_g_pkt_cntr();
    // if packet if from pktgen/recirc and egressing to fp port (even pipe)
    if ((meta.is_pktgen == 1 ) and ((eg_intr_md.egress_port & 128) == 0))
    {
        process_prepopulate_hdr_g_reg();
        pack_stream_port();
        process_tx_instrum_pktgen();
        process_incr_g_pkt_cntr();
        process_incr_burst_pkt_cntr();
        process_udf_vlist_mac_ip();
        pack_stream_pgid();
        if(burst_pkt_cntr.drop == 2 or burst_pkt_cntr.drop == 1)
        {
            process_burst_drops();
        }
        else
        {
            if(meta.tx_instrum == 1)
            {
                process_tx_instrum();
                process_eg_stream_stats();
            /*
            * apply additive offset to tx time stamp
            */
            }
            process_eg_port_stats();
        }
    }// i.e. if (meta.is_pktgen != 1) just emit packet per unicast entries in ig_port_tbl
    else
    {
        apply(set_fabric_hdr_tbl);
        process_eg_port_stats();
    }

}
