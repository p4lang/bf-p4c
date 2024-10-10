# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
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
 * $Id: $
 *
 ******************************************************************************/





# 1 "/usr/local/share/p4c/p4_14include/tofino/constants.p4" 1
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
# 41 "/usr/local/share/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Digest receivers
# 53 "/usr/local/share/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Clone soruces
// (to be used with eg_intr_md_from_parser_aux.clone_src)




/////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Default priorities
# 30 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/usr/local/share/p4c/p4_14include/tofino/intrinsic_metadata.p4" 1
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
# 31 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/usr/local/share/p4c/p4_14include/tofino/primitives.p4" 1
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
# 32 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/usr/local/share/p4c/p4_14include/tofino/pktgen_headers.p4" 1
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
# 33 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/usr/local/share/p4c/p4_14include/tofino/stateful_alu_blackbox.p4" 1
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
# 34 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/usr/local/share/p4c/p4_14include/tofino/wred_blackbox.p4" 1
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

blackbox_type wred {

    attribute wred_input {
        /*  Reference to the input field to compute the moving average on.
            The maximum input bit width supported is 32 bits.  */
        type: bit<32>;
    }

    attribute direct {
        /* Mutually exclusive with 'static' attribute.
           Must be a match table reference */
        type: table;
        optional;
    }

    attribute static {
        /* Mutually exclusive with 'direct' attribute.
           Must be a table reference */
        type: table;
        optional;
    }

    attribute instance_count {
        /* Mutually exclusive with 'direct' attribute. */
        type: int;
        optional;
    }

    attribute drop_value {
        /* Specifies the lower bound for which the computed moving average should result in a drop. */
        type: int;
        optional;
    }

    attribute no_drop_value {
        /* Specifies the upper bound for which the computed moving average should not result in a drop. */
        type: int;
        optional;
    }

    /*
    Execute the moving average for a given cell in the array and writes
    the result to the output parameter.
    If the wred is direct, then 'index' is ignored as the table
    entry determines which cell to reference.

    Callable from:
    - Actions

    Parameters:
    - destination: A field reference to store the moving average state.
                   The maximum output bit width is 8 bits.
    - index: Optional. The offset in the wred array to update. Necessary
             unless the wred is declared as direct, in which case it should
             not be present.
    */
    method execute (out bit<32> destination, optional in int index){
        reads {wred_input}
    }
}

/***************************************************************************/
# 35 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2




# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h" 1
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
 * $Id: $
 *
 ******************************************************************************/


/* Tofino */
# 51 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
// Profiles control, default is DC_BASIC_PROFILE
//#define DC_BASIC_PROFILE
//#define ENT_DC_GENERAL_PROFILE
//#define ENT_FIN_POSTCARD_PROFILE
//#define MSDC_PROFILE

// Individual features control
//#define ACL_DISABLE
//#define INGRESS_ACL_RANGE_DISABLE
//#define EGRESS_ACL_RANGE_DISABLE
//#define BFD_OFFLOAD_ENABLE
//#define EGRESS_FILTER
//#define FAST_FAILOVER_ENABLE
//#define FLOWLET_ENABLE
//#define ILA_ENABLE
//#define INT_ENABLE
//#define INT_EP_ENABLE
//#define INT_DIGEST_ENABLE
//#define INT_OVER_L4_ENABLE
//#define INT_L4_CHECKSUM_UPDATE_ENABLE /* only controls TCP & ICMP checksums */
//#define INT_L4_UDP_CHECKSUM_ZERO_ENABLE
//#define INT_TRANSIT_ENABLE

//#define IPV4_DISABLE
//#define IPV6_DISABLE
//#define INNER_IPV6_DISABLE
//#define L2_DISABLE
//#define L2_MULTICAST_DISABLE

//#define L3_DISABLE
//#define L3_MULTICAST_DISABLE
//#define MIRROR_DISABLE
//#define DTEL_DROP_REPORT_ENABLE

//#define MPLS_UDP_ENABLE
//#define MULTICAST_DISABLE



//#define PKTGEN_ENABLE

//#define SS_QOS_CLASSIFICATION_ENABLE
//#define ACL_QOS_ENABLE
//#define QOS_METERING_ENABLE


//#define RACL_STATS_ENABLE
//#define EGRESS_ACL_STATS_ENABLE
//#define EGRESS_OUTER_BD_STATS_ENABLE
//#define MIRROR_ACL_STATS_ENABLE
//#define RESILIENT_HASH_ENABLE
//#define SFLOW_ENABLE
//#define SRV6_ENABLE
//#define STATS_DISABLE
//#define STORM_CONTROL_DISABLE
//#define STP_DISABLE
//#define TUNNEL_DISABLE
//#define IPV4_TUNNEL_DISABLE
//#define IPV6_TUNNEL_DISABLE

//#define WCMP_ENABLE
//#define MIRROR_ACL_ENABLE
//#define DTEL_FLOW_STATE_TRACK_ENABLE
//#define DTEL_DROP_FLOW_STATE_TRACK_ENABLE
//#define DTEL_QUEUE_REPORT_ENABLE
//#define DTEL_REPORT_LB_ENABLE
//#define DTEL_REPORT_ENABLE
//#define DTEL_WATCH_INNER_ENABLE
//#define INGRESS_MAC_ACL_DISABLE
//#define EGRESS_MAC_ACL_DISABLE

//#define INGRESS_UC_SELF_FWD_CHECK_DISABLE
//#define TUNNEL_INDEX_BRIDGE_ENABLE
//#define TUNNEL_V4_VXLAN_ONLY
//#define TUNNEL_PARSING_DISABLE

//#define INGRESS_PORT_IN_EGRESS_SYSTEM_ACL_ENABLE
//#define HASH_32BIT_ENABLE
//#define ROCEV2_MIRROR_ENABLE

//#define EGRESS_PORT_MIRROR_ENABLE

//#define EGRESS_ACL_MIRROR_ENABLE
//#define DTEL_ACL_ACTION_MIRROR_ENABLE


//#define MLAG_ENABLE




//#define PARSER_EXTRACT_OUTER_ENABLE
//#define QOS_ACL_ENABLE

//#define SYSTEM_FLOW_ACL_ENABLE

//#define ALT_TUNNEL_TERM_ENABLE
//#define ALT_PKT_VALIDATE_ENABLE
//#define ALT_INGRESS_DROP_ENABLE
//#define CPU_TX_YID_REWRITE_ENABLE
//#define DSCP_IN_IP_ACL_KEY_ENABLE
//#define FLOW_LABEL_IN_IPV6_HASH_KEY_ENABLE

//#define IPV4_FRAG_IN_IP_ACL_KEY_ENABLE
//#define STP_STATE_IN_IP_ACL_KEY_ENABLE
//#define IPV4_FRAG_IN_SYSTEM_ACL_KEY_ENABLE
//#define TCP_FLAGS_LOU_ENABLE
//#define MAC_PKT_CLASSIFY_ENABLE
# 167 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
//#define FLOW_WATCHLIST_INDIRECT_RANGE_MATCH
//#define L2_MULTICAST_TERNARY_MATCH_ENABLE


//#define DTEL_BF_1_WAY_HASH_ENABLE
//#define DTEL_BF_2_WAY_HASH_ENABLE
//#define DTEL_BF_3_WAY_HASH_ENABLE
//#define ALT_IP_PKT_VALIDATE_ENABLE
//#define EGRESS_PORT_MIRROR_OPTIMIZATION
//#define CALCULATE_LATENCY_OPTIMIZATION_ENABLE
//#define USER_ACL_DMAC_LABEL_ENABLE
//#define USER_ACL_ACL_LABEL_ENABLE
//#define USER_ACL_FIB_LABEL_ENABLE
//#define SYSTEM_ACL_DMAC_LABEL_ENABLE
//#define SYSTEM_ACL_ACL_LABEL_ENABLE
//#define SYSTEM_ACL_FIB_LABEL_ENABLE
//#define P4_IP_TYPE_EXTENSION_ENABLE
//#define IP_OPTION_IN_IP_ACL_KEY_ENABLE

//#define GRE_INNER_IP_HASHING_ENABLE
//#define NON_IP_HASH_NODE_SYMMETRY
//#define DTEL_COMMON_HASH_ENABLE
//#define DTEL_ACL_ENABLE
//#define DTEL_ACL_STATS_ENABLE
//#define DTEL_ACL_RANGE_DISABLE
//#define DTEL_ACL_IPV6_DISABLE
//#define ETYPE_IN_DTEL_ACL_KEY_ENABLE
//#define DSCP_IN_DTEL_ACL_KEY_ENABLE
//#define DTEL_ACL_SEPARATE_STAGES
//#define ALT_DOD_CONTROL
//#define TCP_FLAGS_IN_EGRESS_ACL_KEY_ENABLE
# 374 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
// common features for all MSDC profiles
# 390 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
// common features for MSDC and MSDC DTel profiles
# 401 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
//#define PFC_DROP_ENABLE






// unique features for each MSDC profile or profile group
# 500 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
// end of all MSDC profiles
# 699 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4features.h"
// Defines for switchapi library
# 40 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/drop_reason_codes.h" 1
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
 * $Id: $
 *
 ******************************************************************************/
# 41 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/cpu_reason_codes.h" 1

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
 * $Id: $
 *
 ******************************************************************************/
/* 
 * other reason codes shared between P4 program and APIs 
 * Must match the definitions in switch_hostif.h file
 */
# 42 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_pktgen.h" 1
# 9 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_pktgen.h"
/* AppIds 0-7 for various pktgen applications */
# 43 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/defines.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/* Boolean */



/* Packet types */
# 37 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/defines.p4"
/* IP types */






/* Multicast modes */







/* URPF modes */




/* NAT modes */




/* ARP opcodes */




/* Egress tunnel types */
# 138 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/defines.p4"
/* Learning Receivers */






/* Nexthop Type */





/* ifindex to indicate flood */


/* fabric device to indicate mutlicast */


/* port type */







/* BYPASS LOOKUP */
# 185 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/defines.p4"
/* Tunnel Termination Type */



/* ALL_RID */





/* 3-bit DROP_CTL field */
# 44 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h" 1
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
 * $Id: $
 *
 ******************************************************************************/



// default undefs


// default table sizes
# 128 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
// 3 IP protocols supported * sessions + 1 default rule + 1 stash rule
# 190 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
/******************************************************************************
 *  Min Table Size profile
 *****************************************************************************/
# 410 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
// 16K MACs


// Tunnels - 4K IPv4 + 1K IPv6







// Ingress ACLs





// IP Hosts/Routes






// ECMP/Nexthop
# 443 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
/* Keep MSDC DTEL configs after MSDC_TABLE_SIZES */
# 458 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
/******************************************************************************
 *  M0_PROFILE                                                                *
 *****************************************************************************/
# 887 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/p4_table_sizes.h"
// override disable
# 45 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/headers.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type llc_header_t {
    fields {
        dsap : 8;
        ssap : 8;
        control_ : 8;
    }
}

header_type snap_header_t {
    fields {
        oui : 24;
        type_ : 16;
    }
}

header_type roce_header_t {
    fields {
        ib_grh : 320;
        ib_bth : 96;
    }
}

header_type roce_v2_header_t {
    fields {
        ib_bth : 96;
    }
}

header_type fcoe_header_t {
    fields {
        version : 4;
        type_ : 4;
        sof : 8;
        rsvd1 : 32;
        ts_upper : 32;
        ts_lower : 32;
        size_ : 32;
        eof : 8;
        rsvd2 : 24;
    }
}

header_type fcoe_fc_header_t {
    fields {
        version : 4;
        reserved : 100;
        sof : 8;
        r_ctl : 8;
        d_id : 24;
        cs_ctl : 8;
        s_id : 24;
        type_ : 8;
        f_ctl : 24;
        seq_id : 8;
        df_ctl : 8;
        seq_cnt : 16;
        ox_id : 16;
        rx_id : 16;
    }
}

header_type fip_header_t {
    fields {
        version : 4;
        rsvd : 12;
        oper_code : 16;
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

header_type ieee802_1ah_t {
    fields {
        pcp : 3;
        dei : 1;
        uca : 1;
        reserved : 3;
        i_sid : 24;
    }
}

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16 (saturating);
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type ipv4_option_32b_t {
  fields { option_fields : 32; }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16 (saturating);
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type tcp_t {
    fields {
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

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16 (saturating);
        checksum : 16;
    }
}

// First 32-bits of IGMP header
header_type igmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

// for DTel watchlist, avoid additional metadata to unify udp and tcp ports
header_type inner_l4_ports_t {
    fields {
        srcPort : 16;
        dstPort : 16;
    }
}

// for DTel report triggering, parsed after inner_l4_ports
header_type inner_tcp_info_t {
    fields {
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

header_type sctp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        verifTag : 32;
        checksum : 32;
    }
}

header_type gre_t {
    fields {
        C : 1;
        R : 1;
        K : 1;
        S : 1;
        s : 1;
        recurse : 3;
        flags : 5;
        ver : 3;
        proto : 16;
    }
}

header_type nvgre_t {
    fields {
        tni : 24;
        flow_id : 8;
    }
}

/* erspan III header - 12 bytes */
header_type erspan_header_t3_t {
    fields {
        version : 4;
        vlan : 12;
        priority_span_id : 16;
        timestamp : 32;
        ft_d_other: 32;
/*  ft_d_other_sgt aggregates next fields:
        sgt       : 16;
        pdu_frame        : 1;
        frame_type       : 5;
        hw_id            : 6;
        direction        : 1; // ingress (0) or egress (1)
        granularity      : 2;
        optional_sub_hdr : 1;
*/
    }
}

header_type ipsec_esp_t {
    fields {
        spi : 32;
        seqNo : 32;
   }
}

header_type ipsec_ah_t {
    fields {
        nextHdr : 8;
        length_ : 8;
        zero : 16;
        spi : 32;
        seqNo : 32;
    }
}

header_type arp_rarp_t {
    fields {
        hwType : 16;
        protoType : 16;
        hwAddrLen : 8;
        protoAddrLen : 8;
        opcode : 16;
    }
}

header_type arp_rarp_ipv4_t {
    fields {
        srcHwAddr : 48;
        srcProtoAddr : 32;
        dstHwAddr : 48;
        dstProtoAddr : 32;
    }
}

header_type eompls_t {
    fields {
        zero : 4;
        reserved : 12;
        seqNo : 16;
    }
}

header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

header_type vxlan_gpe_t {
    fields {
        flags : 8;
        reserved : 16;
        next_proto : 8;
        vni : 24;
        reserved2 : 8;
    }
}

header_type nsh_t {
    fields {
        oam : 1;
        context : 1;
        flags : 6;
        reserved : 8;
        protoType: 16;
        spath : 24;
        sindex : 8;
    }
}

header_type nsh_context_t {
    fields {
        network_platform : 32;
        network_shared : 32;
        service_platform : 32;
        service_shared : 32;
    }
}


/* GENEVE HEADERS
   3 possible options with known type, known length */

header_type genv_t {
    fields {
        ver : 2;
        optLen : 6;
        oam : 1;
        critical : 1;
        reserved : 6;
        protoType : 16;
        vni : 24;
        reserved2 : 8;
    }
}


/* TODO: Would it be convenient to have some kind of sizeof macro ? */


header_type genv_opt_A_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 32;
    }
}




header_type genv_opt_B_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 64;
    }
}




header_type genv_opt_C_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 32;
    }
}

header_type trill_t {
    fields {
        version : 2;
        reserved : 2;
        multiDestination : 1;
        optLength : 5;
        hopCount : 6;
        egressRbridge : 16;
        ingressRbridge : 16;
    }
}

header_type lisp_t {
    fields {
        flags : 8;
        nonce : 24;
        lsbsInstanceId : 32;
    }
}

header_type vntag_t {
    fields {
        direction : 1;
        pointer : 1;
        destVif : 14;
        looped : 1;
        reserved : 1;
        version : 2;
        srcVif : 12;
    }
}

header_type bfd_t {
    fields {
        version : 3;
        diag : 5;
        state_flags : 8;
        /*
         * state : 2;
         * p : 1;
         * f : 1;
         * c : 1;
         * a : 1;
         * d : 1;
         * m : 1;
         */
        detectMult : 8;
        len : 8;
        myDiscriminator : 32;
        yourDiscriminator : 32;
        desiredMinTxInterval : 32;
        requiredMinRxInterval : 32;
        requiredMinEchoRxInterval : 32;
    }
}

header_type sflow_hdr_t {
    fields {
        version : 32;
        addrType : 32;
        ipAddress : 32;
        subAgentId : 32;
        seqNumber : 32;
        uptime : 32;
        numSamples : 32;
    }
}

header_type sflow_sample_t {
    fields {
        enterprise : 20;
        format : 12;
        sampleLength : 32;
        seqNumer : 32;
        srcIdType : 8;
        srcIdIndex : 24;
        samplingRate : 32;
        samplePool : 32;
        numDrops : 32;
        inputIfindex : 32;
        outputIfindex : 32;
        numFlowRecords : 32;
    }
}

header_type sflow_raw_hdr_record_t {
    // this header is attached to each pkt sample (flow_record)
    fields {
        enterprise : 20;
        format : 12;
        flowDataLength_hi : 16; // order reversed with protocol?
        flowDataLength : 16; // order reversed with protocol?
        headerProtocol : 32;
        frameLength_hi : 16;
        frameLength : 16;
        bytesRemoved_hi : 16;
        bytesRemoved : 16;
        headerSize_hi : 16; // not sure what len is this - not in spec?
        headerSize : 16; // not sure what len is this - not in spec?
    }
}


header_type sflow_sample_cpu_t {
    fields {
        sampleLength : 16;
        samplePool : 32;
        inputIfindex : 16;
        outputIfindex : 16;
        numFlowRecords : 8;
        sflow_session_id : 3;
        pipe_id : 2;
    }
}
# 539 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/headers.p4"
header_type fabric_header_t {
    fields {
        packetType : 3;
        headerVersion : 2;
        packetVersion : 2;
        mcast : 1;




        fabricColor : 3;
        fabricQos : 5;


        dstDevice : 8;
        dstPortOrGroup : 16;
    }
}

header_type fabric_header_unicast_t {
    fields {
        routed : 1;
        outerRouted : 1;
        tunnelTerminate : 1;
        ingressTunnelType : 5;

        nexthopIndex : 16;
    }
}

header_type fabric_header_multicast_t {
    fields {
        routed : 1;
        outerRouted : 1;
        tunnelTerminate : 1;
        ingressTunnelType : 5;

        ingressIfindex : 16;
        ingressBd : 16;

        mcastGrpA : 16;
        mcastGrpB : 16;
        ingressRid : 16;
        l1ExclusionId : 16;
    }
}

header_type fabric_header_mirror_t {
    fields {
        rewriteIndex : 16;
        egressPort : 10;
        egressQueue : 5;
        pad : 1;
    }
}
# 612 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/headers.p4"
header_type fabric_header_cpu_t {
    fields {




        egressQueue : 5;
        txBypass : 1;

        capture_tstamp_on_tx : 1;
        dtelIntPresent: 1;

        ingressPort: 16;
        ingressIfindex : 16;
        ingressBd : 16;

        reasonCode : 16;
    }
}


header_type fabric_header_timestamp_t {
  fields {
      arrival_time_hi : 16;
      arrival_time : 32;
  }
}

header_type fabric_header_sflow_t {
    fields {
        sflow_session_id : 16;
    }
}

header_type fabric_header_bfd_event_t {
    fields {
        bfd_session_id : 16;
        bfd_event_id : 16; // e.g timeout, remote param change..
    }
}

header_type fabric_payload_header_t {
    fields {
        etherType : 16;
    }
}

// INT headers
header_type int_header_t {
    fields {
        ver : 4;
        rep : 2;
        c : 1;
        e : 1;
        d : 1;
        rsvd1 : 2;
        ins_cnt : 5;
        max_hop_cnt : 8;
        total_hop_cnt : 8;
        instruction_bitmap_0003 : 4; // split the bits for lookup
        instruction_bitmap_0407 : 4;
        instruction_bitmap_0811 : 4;
        instruction_bitmap_1215 : 4;
        rsvd2_digest : 16;
    }
}
// INT meta-value headers - different header for each value type
header_type int_switch_id_header_t {
    fields {
        switch_id : 32;
    }
}
header_type int_port_ids_header_t {
    fields {
        pad_1 : 7;
        ingress_port_id : 9;
        egress_port_id : 16;
    }
}
header_type int_ingress_port_id_header_t {
    fields {
        ingress_port_id_1 : 16;
        ingress_port_id_0 : 16;
    }
}
header_type int_hop_latency_header_t {
    fields {
        hop_latency : 32;
    }
}
header_type int_q_occupancy_header_t {
    fields {
        rsvd : 3;
        qid : 5;
        q_occupancy0 : 24;
    }
}
header_type int_ingress_tstamp_header_t {
    fields {
        ingress_tstamp : 32;
    }
}
header_type int_egress_port_id_header_t {
    fields {
        egress_port_id : 32;
    }
}
header_type int_egress_tstamp_header_t {
    fields {
        egress_tstamp : 32;
    }
}
header_type int_q_congestion_header_t {
    fields {
        q_congestion : 32;
    }
}
header_type int_egress_port_tx_utilization_header_t {
    fields {
        egress_port_tx_utilization : 32;
    }
}

// generic int value (info) header for extraction
header_type int_value_t {
    fields {
        val : 32;
    }
}

header_type intl45_marker_header_t {
    fields {
        f0 : 32;
        f1 : 32;
    }
}

header_type intl45_head_header_t {
    fields {
        int_type :8;
        len :16;
        rsvd1 :8;
    }
}

// Based on draft-ietf-6man-segment-routing-header-15
header_type ipv6_srh_t {
    fields {
        nextHdr : 8;
        hdrExtLen : 8;
        routingType : 8;
        segLeft : 8;
        lastEntry : 8;
        flags : 8;
        tag : 16;
    }
}

header_type ipv6_srh_segment_t {
    fields {
        sid : 128;
    }
}

header_type dtel_report_header_t {
    fields {
/*
        version             : 4;
        next_proto          : 4;
        dropped             : 1;
        congested_queue     : 1;
        path_tracking_flow  : 1;
        reserved1           : 5;
        reserved2           : 10;
        hw_id               : 6;
*/
        merged_fields : 32;
        sequence_number : 32;
        timestamp : 32;
    }
}

header_type postcard_header_t {
    fields {
        switch_id : 32;
        ingress_port : 16;
        egress_port : 16;
        queue_id : 8;
        queue_depth : 24;
        egress_tstamp : 32;
    }
}

header_type mirror_on_drop_header_t {
    fields {
        switch_id : 32;
        ingress_port : 16;
        egress_port : 16;
        queue_id : 8;
        drop_reason : 8;
        pad : 16;
    }
}
# 46 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/* enable all advanced features */
//#define ADV_FEATURES
# 50 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
/* Tunnel types */
# 194 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
@pragma parser_value_set_size 1
parser_value_set udp_port_vxlan;
# 256 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser start {
    return select(current(96, 16)) { // ether.type



        default : parse_ethernet;
    }
}


@pragma packet_entry
parser start_i2e_mirrored {
    extract(ethernet);
    return ingress;
}

@pragma packet_entry
parser start_e2e_mirrored {
    extract(ethernet);
    return ingress;
}
# 369 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
@pragma pa_container_size ingress ethernet.dstAddr 32 16
@pragma pa_container_size ingress ethernet.srcAddr 32 16





header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;



        0x9000 : parse_fabric_header;

        0x9002: parse_mtel_least_int;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

header llc_header_t llc_header;

parser parse_llc_header {
    extract(llc_header);
    return select(llc_header.dsap, llc_header.ssap) {
        0xAAAA : parse_snap_header;
        0xFEFE : parse_set_prio_med;
        default: ingress;
    }
}

header snap_header_t snap_header;

parser parse_snap_header {
    extract(snap_header);
    return select(latest.type_) {
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

header fcoe_header_t fcoe;

parser parse_fcoe {
    extract(fcoe);
    return ingress;
}

header fcoe_fc_header_t fcoe_fc;

parser parse_fcoe_fc {
    extract(fcoe_fc);
    return ingress;
}

header fip_header_t fip;

parser parse_fip {
    extract(fip);
    return ingress;
}


header vlan_tag_t vlan_tag_[2];

parser parse_vlan {
    extract(vlan_tag_[0]);
    return select(latest.etherType) {
        0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

parser parse_qinq {
    extract(vlan_tag_[0]);
    return select(latest.etherType) {
        0x8100 : parse_qinq_vlan;
        default : ingress;
    }
}

parser parse_qinq_vlan {
    extract(vlan_tag_[1]);
    return select(latest.etherType) {
        0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}


/* all the tags but the last one */
header mpls_t mpls[3];

/* TODO: this will be optimized when pushed to the chip ? */
parser parse_mpls {
# 473 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
    return ingress;

}
# 504 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_mpls_udp {
    set_metadata(tunnel_metadata.mpls_in_udp, 1);
    return parse_mpls;
}

parser parse_mpls_inner_ipv4 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv4;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv6;
}

parser parse_vpls {
    return ingress;
}

parser parse_pw {
    return ingress;
}
# 552 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
// This ensures hdrChecksum and protocol fields are allocated to different
// containers so that the deparser can calculate the IPv4 checksum correctly.
// We are enforcing a stronger constraint than necessary. In reality, even if
// protocol and hdrChecksum are allocated to the same 32b container, it is OK
// as long as hdrChecksum occupies the first or last 16b. It should just not be
// in the middle of the 32b container. But, there is no pragma to enforce such
// a constraint precisely. So, using pa_fragment.
@pragma pa_fragment ingress ipv4.hdrChecksum
@pragma pa_fragment egress ipv4.hdrChecksum






header ipv4_t ipv4;
@pragma pa_no_overlay ingress ipv4_option_32b.option_fields
@pragma pa_no_overlay egress ipv4_option_32b.option_fields
header ipv4_option_32b_t ipv4_option_32b;

field_list ipv4_checksum_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4_option_32b.option_fields;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum {

    verify ipv4_checksum;
    update ipv4_checksum;




}
# 640 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_ipv4 {





    return select(current(4, 4), current(48, 16)) { //ipv4.ihl, ipv4.flags, ipv4.fragOffset
        0x50000 mask 0xf3fff : parse_ipv4_no_options; // No fragmentation, ipv4.ihl=5
        0x60000 mask 0xf3fff: parse_ipv4_option_32b; // No fragmentation, ipv4.ihl=6
        0x00000 mask 0x03fff: parse_ipv4_other; // No fragmentation, ipv4.ihl > 6
        0x02000 mask 0x03fff : parse_ipv4_fragmented_first_pkt; // Fragmented, ipv4.fragOffset=0 (first packet)
        default : parse_ipv4_fragmented_other_pkt;
    }
}

parser parse_ipv4_fragmented_first_pkt {
    set_metadata(l3_metadata.lkp_ip_frag, 3);
    return select(current(4, 4)) { //ipv4.ihl
        5 : parse_ipv4_no_options;
        6 : parse_ipv4_option_32b; // Extract a single 4-byte option
        default : parse_ipv4_other;
    }
}

parser parse_ipv4_fragmented_other_pkt {
    set_metadata(l3_metadata.lkp_ip_frag, 2);
    return select(current(4, 4)) { //ipv4.ihl
        5 : parse_ipv4_no_options;
        6 : parse_ipv4_option_32b; // Extract a single 4-byte option
        default : parse_ipv4_other;
    }
}

parser parse_ipv4_other {
    // Packet will be dropped in the pipeline.
    extract(ipv4);
    return ingress;
}

parser parse_ipv4_option_32b {
    extract(ipv4);
    extract(ipv4_option_32b);
    return select(ipv4.fragOffset, ipv4.protocol) {
        1 : parse_icmp;
        6 : parse_tcp;
        17 : parse_udp;

        47 : parse_gre;
# 698 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_ipv4_no_options {
    extract(ipv4);
    return select(ipv4.fragOffset, ipv4.protocol) {
        1 : parse_icmp;
        6 : parse_tcp;
        17 : parse_udp;

        47 : parse_gre;
# 724 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_ipv4_in_ip {




    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 3);

        return parse_inner_ipv4;
}


parser parse_ipv6_in_ip {




    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 3);

    return parse_inner_ipv6;
}


parser parse_ethernet_in_ip {




//    set_metadata(tunnel_metadata.ingress_tunnel_type,
//                 INGRESS_TUNNEL_TYPE_ETHERNET_IN_IP);

        return parse_inner_ethernet;
}
# 789 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
header ipv6_t ipv6;

parser parse_udp_v6 {
    extract(udp);




    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);

    return select(latest.dstPort) {
        67 : parse_set_prio_med;
        68 : parse_set_prio_med;
        546 : parse_set_prio_med;
        547 : parse_set_prio_med;
        520 : parse_set_prio_med;
        521 : parse_set_prio_med;
        1985 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_gre_v6 {
    extract(gre);
    return select(latest.C, latest.R, latest.K, latest.S, latest.s,
                  latest.recurse, latest.flags, latest.ver, latest.proto) {

        0x0800 : parse_gre_ipv4;

        0x86dd : parse_gre_ipv6;


        default: ingress;
    }
}

parser parse_ipv6 {

    extract(ipv6);
    return select(latest.nextHdr) {
        58 : parse_icmp;
        6 : parse_tcp;
# 844 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
        17 : parse_udp_v6;
        47 : parse_gre_v6;

        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;

        default: ingress;
    }



}
# 973 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
header icmp_t icmp;
# 1015 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_icmp {
    extract(icmp);



    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.typeCode);
# 1052 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
    return select(icmp.typeCode) {
        0x8200 mask 0xfe00 : parse_set_prio_med; 0x8400 mask 0xfc00 : parse_set_prio_med; 0x8800 mask 0xff00 : parse_set_prio_med; default: ingress;
    }
}

header igmp_t igmp;

parser parse_igmp {
    extract(igmp);



    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.typeCode);

    return ingress;
}




@pragma pa_fragment egress tcp.checksum
@pragma pa_fragment egress tcp.urgentPtr

/** CODE_HACK p4c causes tcp.srcPort to be incorrectly overlaid with gre fields, which is causing
  * some packet tests to fail. This pragma prevents tcp.srcPort from being overlaid. It can be
  * removed once p4c includes analysis that accounts for added and removed headers in deciding
  * overlays.
  */
@pragma pa_no_overlay egress tcp.srcPort

header tcp_t tcp;
# 1168 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_tcp {
    extract(tcp);





    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);
    set_metadata(l3_metadata.lkp_outer_tcp_flags, latest.flags);
# 1209 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
    return select(tcp.dstPort) {
        179 mask 0xffff: parse_set_prio_med; 639 mask 0xffff: parse_set_prio_med; default: ingress;
    }
}

header roce_v2_header_t roce_v2;

parser parse_roce_v2 {

    set_metadata(l3_metadata.rocev2_opcode, current(0, 8));
    // Note : rsvd and aeth_syndrome fields are mutually exclusive and we can potentially overlay them based on opcode
    set_metadata(l3_metadata.rocev2_dst_qp_plus_rsvd, current(40, 32));
    set_metadata(l3_metadata.rocev2_aeth_syndrome, current(96, 8)); // First byte of ACK extended transport header

    return ingress;
}




header udp_t udp;
# 1275 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_udp {
    extract(udp);




    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);
# 1315 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
    return select(udp.dstPort) {
        4791 mask 0xffff: parse_roce_v2; 67 mask 0xffff: parse_set_prio_med; 68 mask 0xffff: parse_set_prio_med; 546 mask 0xffff: parse_set_prio_med; 547 mask 0xffff: parse_set_prio_med; 520 mask 0xffff: parse_set_prio_med; 521 mask 0xffff: parse_set_prio_med; 1985 mask 0xffff: parse_set_prio_med; 6343 mask 0xffff: parse_sflow; default: ingress;
       
    }
}

header sctp_t sctp;

parser parse_sctp {
    extract(sctp);
    return ingress;
}




header gre_t gre;
# 1350 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_gre {
    extract(gre);
    return select(latest.C, latest.R, latest.K, latest.S, latest.s,
                  latest.recurse, latest.flags, latest.ver, latest.proto) {




        0x0800 : parse_gre_ipv4;

        0x86dd : parse_gre_ipv6;


        0x22EB : parse_erspan_t3;



        default: ingress;
    }
}



parser parse_gre_ipv4 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv4;
}


parser parse_gre_ipv6 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv6;
}


header nvgre_t nvgre;
header ethernet_t inner_ethernet;

// See comment above pa_fragment for outer IPv4 header.
@pragma pa_fragment ingress inner_ipv4.hdrChecksum
@pragma pa_fragment egress inner_ipv4.hdrChecksum




header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;

field_list inner_ipv4_checksum_list {
        inner_ipv4.version;
        inner_ipv4.ihl;
        inner_ipv4.diffserv;
        inner_ipv4.totalLen;
        inner_ipv4.identification;
        inner_ipv4.flags;
        inner_ipv4.fragOffset;
        inner_ipv4.ttl;
        inner_ipv4.protocol;
        inner_ipv4.srcAddr;
        inner_ipv4.dstAddr;
}

field_list_calculation inner_ipv4_checksum {
    input {
        inner_ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field inner_ipv4.hdrChecksum {

    verify inner_ipv4_checksum;
    update inner_ipv4_checksum;




}

header udp_t outer_udp;

parser parse_nvgre {
    extract(nvgre);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 5);
    set_metadata(tunnel_metadata.tunnel_vni, latest.tni);
    return parse_inner_ethernet;
}

@pragma not_parsed egress
@pragma not_parsed ingress
@pragma not_deparsed ingress



header erspan_header_t3_t erspan_t3_header;

parser parse_erspan_t3 {
    extract(erspan_t3_header);
    return select(latest.ft_d_other) {
        0x000 mask 0x7c01: parse_inner_ethernet;

        0x800 mask 0x7c01: parse_inner_ipv4;

        default : ingress;
    }
}

parser parse_arp_rarp_req {
    set_metadata(l2_metadata.arp_opcode, 1);
    return parse_set_prio_med;
}

parser parse_arp_rarp_res {
    set_metadata(l2_metadata.arp_opcode, 2);
    return parse_set_prio_med;
}

parser parse_arp_rarp {
    return select (current(48,16)) {
      0x1 : parse_arp_rarp_req;
      0x2 : parse_arp_rarp_res;
      default : ingress;
    }
}

header eompls_t eompls;

parser parse_eompls {
    //extract(eompls);
    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ethernet;
}


header vxlan_t vxlan;

parser parse_vxlan {
    extract(vxlan);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 1);
    set_metadata(tunnel_metadata.tunnel_vni, latest.vni);
    return parse_inner_ethernet;
}
# 1515 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
header genv_t genv;

parser parse_geneve {
    extract(genv);
    set_metadata(tunnel_metadata.tunnel_vni, latest.vni);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 4);
    return select(genv.ver, genv.optLen, genv.protoType) {
        0x6558 : parse_inner_ethernet;
        0x0800 : parse_inner_ipv4;

        0x86dd : parse_inner_ipv6;

        default : ingress;
    }
}

header nsh_t nsh;
header nsh_context_t nsh_context;

parser parse_nsh {
    extract(nsh);
    extract(nsh_context);
    return select(nsh.protoType) {
        0x0800 : parse_inner_ipv4;

        0x86dd : parse_inner_ipv6;

        0x6558 : parse_inner_ethernet;
        default : ingress;
    }
}

header lisp_t lisp;

parser parse_lisp {
    extract(lisp);
    return select(current(0, 4)) {
        0x4 : parse_inner_ipv4;

        0x6 : parse_inner_ipv6;

        default : ingress;
    }
}

parser parse_inner_ipv4 {
    extract(inner_ipv4);

    set_metadata(ipv4_metadata.lkp_ipv4_sa, latest.srcAddr);
    set_metadata(ipv4_metadata.lkp_ipv4_da, latest.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, latest.protocol);
    set_metadata(l3_metadata.lkp_ip_ttl, latest.ttl);

    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        0x501 : parse_inner_icmp;
        0x506 : parse_inner_tcp;
        0x511 : parse_inner_udp;
        default: ingress;
    }
}

header inner_l4_ports_t inner_l4_ports;

header icmp_t inner_icmp;

parser parse_inner_icmp {
    extract(inner_icmp);



    set_metadata(l3_metadata.lkp_l4_sport, latest.typeCode);

    return ingress;
}


@pragma pa_fragment egress inner_tcp.checksum
@pragma pa_fragment egress inner_tcp.urgentPtr
header tcp_t inner_tcp;

header inner_tcp_info_t inner_tcp_info; // fot DTel use only

parser parse_inner_tcp {



    extract(inner_tcp);





    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);




    set_metadata(l3_metadata.lkp_tcp_flags, latest.flags);
    return ingress;
}




header udp_t inner_udp;
# 1653 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_inner_udp {



    extract(inner_udp);





    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);

    return ingress;
}

header sctp_t inner_sctp;

parser parse_inner_sctp {
    extract(inner_sctp);
    return ingress;
}

parser parse_inner_ipv6 {

    extract(inner_ipv6);

    set_metadata(ipv6_metadata.lkp_ipv6_sa, latest.srcAddr);
    set_metadata(ipv6_metadata.lkp_ipv6_da, latest.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, latest.nextHdr);
    set_metadata(l3_metadata.lkp_ip_ttl, latest.hopLimit);

    return select(latest.nextHdr) {
        58 : parse_inner_icmp;
        6 : parse_inner_tcp;
        17 : parse_inner_udp;
        default: ingress;
    }



}

parser parse_inner_ethernet {
    extract(inner_ethernet);






    return select(latest.etherType) {

        0x0800 : parse_inner_ipv4;

        0x86dd : parse_inner_ipv6;


        default: ingress;
    }
}

header trill_t trill;

parser parse_trill {
    extract(trill);
    return parse_inner_ethernet;
}

header vntag_t vntag;

parser parse_vntag {
    extract(vntag);
    return parse_inner_ethernet;
}
# 1738 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
header sflow_hdr_t sflow;
header sflow_sample_t sflow_sample;
header sflow_raw_hdr_record_t sflow_raw_hdr_record;

parser parse_sflow {



    return ingress;
}
# 1759 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
header fabric_header_t fabric_header;
header fabric_header_unicast_t fabric_header_unicast;
header fabric_header_multicast_t fabric_header_multicast;
header fabric_header_mirror_t fabric_header_mirror;
header fabric_header_cpu_t fabric_header_cpu;
header fabric_header_sflow_t fabric_header_sflow;
header fabric_header_bfd_event_t fabric_header_bfd;
header fabric_payload_header_t fabric_payload_header;
header fabric_header_timestamp_t fabric_header_timestamp;

parser parse_fabric_header {
    extract(fabric_header);
# 1780 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
    return parse_fabric_header_cpu;

}

parser parse_fabric_header_unicast {
    extract(fabric_header_unicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_multicast {
    extract(fabric_header_multicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_mirror {
    extract(fabric_header_mirror);
    return parse_fabric_payload_header;
}




parser parse_fabric_header_cpu {
    extract(fabric_header_cpu);
    set_metadata(ingress_metadata.bypass_lookups, latest.reasonCode);
    return select(latest.reasonCode) {
# 1816 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
        default : parse_fabric_payload_header;
    }
}
# 1841 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_fabric_payload_header {
    extract(fabric_payload_header);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}
# 1859 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_set_prio_med {
    set_metadata(ig_prsr_ctrl.priority, 3);
    return ingress;
}

parser parse_set_prio_high {
    set_metadata(ig_prsr_ctrl.priority, 5);
    return ingress;
}

parser parse_set_prio_max {
    set_metadata(ig_prsr_ctrl.priority, 7);
    return ingress;
}
# 1889 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4"
parser parse_mtel_least_int {



    return ingress;
}


# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/dtel_parser.p4" 1
# 1897 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/includes/parser.p4" 2
# 47 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2

# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/mtel/mtel.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
# 49 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2

/* METADATA */
header_type ingress_metadata_t {
    fields {
        ingress_port : 9; /* input physical port */
        port_lag_index : 10; /* ingress port index */
        egress_port_lag_index : 10;/* egress port index */
        ifindex : 14; /* ingress interface index */
        egress_ifindex : 14; /* egress interface index */
        port_type : 2; /* ingress port type */

        outer_bd : 14; /* outer BD */
        bd : 14; /* BD */

        drop_flag : 1; /* if set, drop the packet */
        drop_reason : 8; /* drop reason */

        control_frame: 1; /* control frame */
        bypass_lookups : 16; /* list of lookups to skip */
        egress_outer_bd : 14;
        egress_outer_dmac : 48;
    }
}

header_type egress_metadata_t {
    fields {



        bypass : 1; /* bypass egress pipeline */
        port_type : 2; /* egress port type */
        payload_length : 16; /* payload length for tunnels */
        smac_idx : 9; /* index into source mac table */
        bd : 14; /* egress inner bd */
        outer_bd : 14; /* egress inner bd */
        mac_da : 48; /* final mac da */
        routed : 1; /* is this replica routed */
        same_bd_check : 14; /* ingress bd xor egress bd */
        drop_reason : 8; /* drop reason */
        ifindex : 14; /* egress interface index */
        egress_port : 9; /* original egress port */
    }
}
# 104 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
/* Global config information */
header_type global_config_metadata_t {
    fields {
        enable_dod : 1; /* Enable Deflection-on-Drop */
        switch_id : 32; /* Switch Id */
    }
}
# 119 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
@pragma pa_atomic egress egress_metadata.port_type
@pragma pa_solitary egress egress_metadata.port_type
# 136 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
// Workaround for COMPILER-788


@pragma pa_solitary ingress ingress_metadata.ingress_port

// Workaround for COMPILER-844




metadata ingress_metadata_t ingress_metadata;





// Workaround for COMPILER-844



metadata egress_metadata_t egress_metadata;



metadata global_config_metadata_t global_config_metadata;

# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch_config.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * System global parameters
 */

action set_config_parameters(enable_flowlet) {
    /* initialization */

    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md.ingress_mac_tstamp);

    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);



}

table switch_config_params {
    actions {
        set_config_parameters;
    }
    default_action : set_config_parameters;
    size : 1;
}

control process_global_params {
    /* set up global controls/parameters */






}
# 163 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Input processing - port and packet related
 */

/*****************************************************************************/
/* Validate outer packet header                                              */
/*****************************************************************************/
action set_valid_outer_unicast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);



}

action set_valid_outer_unicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);



}
# 59 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
action set_valid_outer_unicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);



}

action set_valid_outer_multicast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);



}

action set_valid_outer_multicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);



}
# 96 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
action set_valid_outer_multicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);



}

action set_valid_outer_broadcast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}

action set_valid_outer_broadcast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}
# 126 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
action set_valid_outer_broadcast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}

action malformed_outer_ethernet_packet(drop_reason) {


    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);

}

table validate_outer_ethernet {
    reads {
        ethernet.srcAddr : ternary;
        ethernet.dstAddr : ternary;
        vlan_tag_[0].valid : ternary;



    }
    actions {
        malformed_outer_ethernet_packet;
        set_valid_outer_unicast_packet_untagged;
        set_valid_outer_unicast_packet_single_tagged;





        set_valid_outer_unicast_packet_qinq_tagged;
        set_valid_outer_multicast_packet_untagged;
        set_valid_outer_multicast_packet_single_tagged;
        set_valid_outer_multicast_packet_qinq_tagged;
        set_valid_outer_broadcast_packet_untagged;
        set_valid_outer_broadcast_packet_single_tagged;
        set_valid_outer_broadcast_packet_qinq_tagged;
    }
    size : 512;
}

control process_validate_outer_header {
    /* validate the ethernet header */
    apply(validate_outer_ethernet) {
        malformed_outer_ethernet_packet {
        }
        default {





            if (valid(ipv4)) {
                validate_outer_ipv4_header();
            } else {
                if (valid(ipv6)) {
                    validate_outer_ipv6_header();
                }
            }






        }
    }
}


/*****************************************************************************/
/* Ingress port lookup                                                       */
/*****************************************************************************/

action set_port_lag_index(port_lag_index, port_type, neighbor_id) {
    modify_field(ingress_metadata.port_lag_index, port_lag_index);
    modify_field(ingress_metadata.port_type, port_type);

    modify_field(nexthop_metadata.nexthop_offset, neighbor_id);

}

table ingress_port_mapping {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_port_lag_index;
    }
    default_action: set_port_lag_index;
    size : 288;
}

field_list ingress_tstamp_hi_hash_fields {
    ig_intr_md.ingress_mac_tstamp;
}

field_list_calculation ingress_tstamp_hi_hash_fields_calc {
    input { ingress_tstamp_hi_hash_fields; }
    algorithm : identity_msb;
    output_width : 16;
}


action set_ingress_port_properties(port_lag_label, exclusion_id,
                                   qos_group, tc_qos_group,
                                   tc, color,
                                   learning_enabled,
                                   trust_dscp, trust_pcp,
                                   mac_pkt_classify) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, exclusion_id);
    modify_field(acl_metadata.port_lag_label, port_lag_label);
    modify_field(qos_metadata.ingress_qos_group, qos_group);



    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(ig_intr_md_for_tm.packet_color, color);
    modify_field(qos_metadata.trust_dscp, trust_dscp);
    modify_field(qos_metadata.trust_pcp, trust_pcp);
    modify_field(l2_metadata.port_learning_enabled, learning_enabled);






    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md.ingress_mac_tstamp);

    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);




}




table ingress_port_properties {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ingress_port_properties;
    }
    size : 290;
}

control process_ingress_port_mapping {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_mapping);
    }
    apply(ingress_port_properties);
}

/*****************************************************************************/
/* Ingress port-vlan mapping lookups                                         */
/*****************************************************************************/

//-------------------------
// BD Properties
//-------------------------
action set_bd_properties(bd, vrf, stp_group, learning_enabled,
                         bd_label, stats_idx, rmac_group,
                         ipv4_unicast_enabled, ipv6_unicast_enabled,
                         ipv4_urpf_mode, ipv6_urpf_mode,
                         igmp_snooping_enabled, mld_snooping_enabled,
                         ipv4_multicast_enabled, ipv6_multicast_enabled,
                         mrpf_group,
                         ipv4_mcast_key, ipv4_mcast_key_type,
                         ipv6_mcast_key, ipv6_mcast_key_type,
                         ingress_rid) {
    modify_field(ingress_metadata.bd, bd);



    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(l3_metadata.vrf, vrf);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);

    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(multicast_metadata.ipv6_multicast_enabled,
                 ipv6_multicast_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);





    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(multicast_metadata.igmp_snooping_enabled,
                 igmp_snooping_enabled);
    modify_field(multicast_metadata.ipv4_multicast_enabled,
                 ipv4_multicast_enabled);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);






    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action port_vlan_mapping_miss() {
    modify_field(l2_metadata.port_vlan_mapping_miss, 1);
}

action local_sid_miss() {
}

action_profile bd_action_profile {
    actions {
        set_bd_properties;
        port_vlan_mapping_miss;
        local_sid_miss;
    }
    size : 5120;
}

//---------------------------------------------------------
// {port, vlan} -> BD mapping
// For Access ports, L3 interfaces and L2 sub-ports
//---------------------------------------------------------

@pragma ignore_table_dependency my_sid
table port_vlan_to_bd_mapping {
    reads {
        ingress_metadata.port_lag_index : ternary;
        vlan_tag_[0] : valid;
        vlan_tag_[0].vid : ternary;
        // {port_lag_idx, 0, *}    entry for every L3 interface
        // {port_lag_idx, 1, vlan} entry for every L3 sub-interface
        // {port_lag_idx, 0, *}    entry for every access port/lag + untagged packet
        // {port_lag_idx, 1, vlan} entry for every access port/lag + packets tagged with access_vlan
        // {port_lag_idx, 1, 0}    entry for every access port/lag + .1p tagged packets
        // {port_lag_idx, 1, vlan} entry for every l2 sub-port (if supported)
        // {port_lag_idx, 0, *}    entry for every trunk port/lag if native-vlan is not tagged
        // {port_lag_index, *, *} -> port_vlan_mapping_miss action. Low priority catch-all entry - one for every non-trunk port.
    }
    action_profile: bd_action_profile;

    const default_action: nop();

    size : 1024;
}

//--------------------------------------------------------
// vlan->BD mapping for trunk ports
//--------------------------------------------------------



table vlan_to_bd_mapping {
    reads {
        vlan_tag_[0].vid : exact;
        // one entry for every vlan
    }
    action_profile: bd_action_profile;

    const default_action: nop();

    size : 4096;
}

//--------------------------------------------------------
// BD properties for cpu-tx packets
//--------------------------------------------------------
@pragma ignore_table_dependency my_sid
table cpu_packet_transform {
    reads {
        fabric_header_cpu.ingressBd mask 0xFFF: exact;
        // One entry for every vlan
    }
    action_profile: bd_action_profile;

    const default_action: nop();

    size : 5120;
}

//-------------------------------
// ifindex properties
//-------------------------------
action_profile ifindex_action_profile {
    actions {
        ifindex_properties;
    }
    size : 290;
}

action ifindex_properties(ifindex) {
    modify_field(ingress_metadata.ifindex, ifindex);
    modify_field(l2_metadata.same_if_check, ifindex);
}

//-------------------------------
// ifindex derivation 
//-------------------------------
table ifindex_mapping {
    reads {
        fabric_header_cpu : valid;
        fabric_header_cpu.ingressPort : ternary;
        ig_intr_md.ingress_port : exact;
        // Two entries for every port
        // {true , port, cpu_port }
        // {false,    *, port}
    }
    actions {
        ifindex_properties;
    }
    default_action: ifindex_properties(0);
    size : 580;
}

//-------------------------------------
// ifindex derivation for L2 sub-ports
//-------------------------------------
# 469 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
//-------------------------------------------
// Control flow for BD/Interface derivation
//------------------------------------------
control process_port_vlan_mapping {
    // BD Derivation
    if(valid(fabric_header_cpu)) {
        apply(cpu_packet_transform);
    } else {
        apply(port_vlan_to_bd_mapping) {
            miss { apply(vlan_to_bd_mapping); }
        }
    }

    // ifindex Derivation
    apply(ifindex_mapping);

    // Copy outer packet metadata to lkup fields

    apply(adjust_lkp_fields);

}

/*****************************************************************************/
// Ingress vlan membership check
/*****************************************************************************/

register ingress_vlan_mbr_reg{
    width : 1;
    static : ingress_vlan_mbr;
    instance_count : 294912;
}

blackbox stateful_alu ingress_vlan_mbr_alu{
    reg: ingress_vlan_mbr_reg;
    update_lo_1_value: read_bitc;
    output_value: alu_lo;
    output_dst: l2_metadata.ingress_vlan_mbr_check_fail;
}


@pragma field_list_field_slice ig_intr_md.ingress_port 6 0 // Ports 0-71 ( local to the pipeline )
@pragma field_list_field_slice ingress_metadata.bd 11 0 // First 4K BDs which are reserved for VLANs
field_list ingress_pv_fields {
    ig_intr_md.ingress_port;
    ingress_metadata.bd;
}

field_list_calculation ingress_pv_hash {
    input { ingress_pv_fields; }
    algorithm { identity; }
    output_width : 19;
}

action ingress_vlan_mbr_check() {
    ingress_vlan_mbr_alu.execute_stateful_alu_from_hash(ingress_pv_hash);
}

table ingress_vlan_mbr {
    actions { ingress_vlan_mbr_check; }
    default_action : ingress_vlan_mbr_check;
    size : 1;
}

control process_ingress_vlan_mbr {
    if ((ingress_metadata.bd & 0x3000) == 0) {
        apply(ingress_vlan_mbr);
    }
}

/*****************************************************************************/
/* Ingress BD stats based on packet type                                     */
/*****************************************************************************/
# 560 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
counter ingress_bd_stats {
    type : packets_and_bytes;
    instance_count : 16384;
    min_width : 32;
}

action update_ingress_bd_stats() {
    count(ingress_bd_stats, l2_metadata.bd_stats_idx);
}

table ingress_bd_stats {
    actions {
        update_ingress_bd_stats;
    }
    default_action : update_ingress_bd_stats;
    size : 16384;
}



control process_ingress_bd_stats {

    apply(ingress_bd_stats);

}


/*****************************************************************************/
/* LAG lookup/resolution                                                     */
/*****************************************************************************/
field_list lag_hash_fields {







    hash_metadata.hash2;



}

field_list_calculation lag_hash {
    input {
        lag_hash_fields;
    }
# 621 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
    algorithm {
     identity;
 crc_16_dect;
    }
    output_width : 14;

}

action_selector lag_selector {
    selection_key : lag_hash;



    selection_mode : fair;

}
# 651 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
action set_lag_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}


action set_lag_miss() {
}

action_profile lag_action_profile {
    actions {
        set_lag_miss;
        set_lag_port;



    }
    size : 1024;
    dynamic_action_selection : lag_selector;
}

table lag_group {
    reads {
        ingress_metadata.egress_port_lag_index : exact;
    }
    action_profile: lag_action_profile;
    size : 1024;
}
# 710 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
control process_lag {
# 724 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
        apply(lag_group);




}


/*****************************************************************************/
/* Egress port lookup                                                        */
/*****************************************************************************/



action egress_port_type_normal(qos_group, port_lag_label, mlag_member) {

    modify_field(egress_metadata.port_type, 0);

    modify_field(qos_metadata.egress_qos_group, qos_group);

    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
    modify_field(acl_metadata.egress_port_lag_label, port_lag_label);
# 759 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
}

action egress_port_type_fabric() {





}

action egress_port_type_cpu() {
    modify_field(egress_metadata.port_type, 2);
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
    cpu_rx_rewrite();







}




table egress_port_mapping {
    reads {
        eg_intr_md.egress_port : exact;
    }
    actions {
        egress_port_type_normal;



        egress_port_type_cpu;
    }
    size : 290;
}


/*****************************************************************************/
/* Egress VLAN translation                                                   */
/*****************************************************************************/
# 818 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
action set_egress_if_params_tagged(vlan_id) {
    add_header(vlan_tag_[0]);
    modify_field(vlan_tag_[0].etherType, ethernet.etherType);
    modify_field(vlan_tag_[0].vid, vlan_id);
    modify_field(ethernet.etherType, 0x8100);
}
action set_egress_if_params_tagged_with_bd_as_vlan() {
    add_header(vlan_tag_[0]);
    modify_field(vlan_tag_[0].etherType, ethernet.etherType);
    modify_field(vlan_tag_[0].vid, egress_metadata.outer_bd, 0xFFF);
    modify_field(ethernet.etherType, 0x8100);
}

action set_egress_if_params_untagged() {
}





table egress_vlan_xlate {
    reads {
        eg_intr_md.egress_port : ternary;
        egress_metadata.outer_bd : ternary;
        vlan_tag_[0] : valid;
        // {port, BD, *} -> nop entry for every L3-interface
        // {port, BD, *} -> set_tagged entry for every L3-sub-interface
        // {port, BD, *} -> nop entry for access ports
        // {port, native-vlan-BD, 0} -> nop for trunk ports with untagged native_vlan OR
        // {port, native-vlan-BD, 0} -> set_tagged for trunk ports with tagged native_vlan
        // {port, *, 1} -> qinq_tagged_with_bd_as_vlan entry for every trunk port (packet arrived on qinq tunnel port)
        // {port, *, 0} -> set_tagged_with_bd_as_vlan entry for every trunk port 
    }
    actions {
        set_egress_if_params_untagged;
        set_egress_if_params_tagged;
        set_egress_if_params_tagged_with_bd_as_vlan;




    }
    size : 1024;
}

control process_vlan_xlate {
    apply(egress_vlan_xlate);
}

/*****************************************************************************/
/* Overwrite RID for packets coming on peer-link */
/*****************************************************************************/
# 887 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/port.p4"
control process_peer_link_properties {



}

/*****************************************************************************/
/* capture timestamp                                                         */
/*****************************************************************************/
# 164 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Layer-2 processing
 */

header_type l2_metadata_t {
    fields {
        lkp_mac_sa : 48;
        lkp_mac_da : 48;
        lkp_pkt_type : 3;
        lkp_mac_type : 16;
        lkp_pcp: 3;
        non_ip_packet : 1; /* non ip packet */
        arp_opcode : 2; /* encoded opcode for arp/rarp frames */

        l2_nexthop : 16; /* next hop from l2 */
        l2_nexthop_type : 1; /* ecmp or nexthop */
        l2_redirect : 1; /* l2 redirect action */
        l2_src_miss : 1; /* l2 source miss */
        l2_src_move : 14; /* l2 source interface mis-match */
        l2_dst_miss : 1; /* l2 uc/mc/bc destination miss */
        stp_group: 12; /* spanning tree group id */
        stp_state : 3; /* spanning tree port state */
        bd_stats_idx : 14; /* ingress BD stats index */
        learning_enabled : 1; /* is learning enabled */
        port_learning_enabled : 1; /* is learning enabled on port */
        port_vlan_mapping_miss : 1; /* port vlan mapping miss */
        ingress_stp_check_fail : 1; /* ingress spanning tree check failed */
        egress_stp_check_fail : 1; /* egress spanning tree check failed */
        same_if_check : 14; /* same interface check */
        ingress_vlan_mbr_check_fail : 1; /* ingress vlan membership check failed */
        egress_vlan_mbr_check_fail : 1; /* egress vlan membership check failed */




        dmac_label : 8;
    }
}






@pragma pa_alias ingress l2_metadata.lkp_mac_sa ethernet.srcAddr
@pragma pa_alias ingress l2_metadata.lkp_mac_da ethernet.dstAddr

@pragma pa_container_size ingress l2_metadata.same_if_check 16
# 86 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4"
metadata l2_metadata_t l2_metadata;

/*****************************************************************************/
/* Ingress Spanning tree check                                               */
/*****************************************************************************/
register ingress_stp_reg{
    width : 1;
    static : ingress_stp;
    instance_count : 294912;
}

blackbox stateful_alu ingress_stp_alu{
    reg: ingress_stp_reg;
    update_lo_1_value: read_bit;
    output_value: alu_lo;
    output_dst: l2_metadata.ingress_stp_check_fail;
}


@pragma field_list_field_slice ig_intr_md.ingress_port 6 0 // Ports 0-71 ( local to the pipeline )
@pragma field_list_field_slice ingress_metadata.bd 11 0 // First 4K BDs which are reserved for VLANs
field_list ingress_stp_fields {
    ig_intr_md.ingress_port;
    ingress_metadata.bd;
}

field_list_calculation ingress_stp_hash {
    input { ingress_stp_fields; }
    algorithm { identity; }
    output_width : 19;
}

action ingress_stp_check() {
    ingress_stp_alu.execute_stateful_alu_from_hash(ingress_stp_hash);
}

table ingress_stp {
    actions { ingress_stp_check; }
    default_action : ingress_stp_check;
    size : 1;
}

control process_ingress_stp {





}


/*****************************************************************************/
/* Source MAC lookup                                                         */
/*****************************************************************************/
action smac_miss() {
    modify_field(l2_metadata.l2_src_miss, 1);
}

action smac_hit(ifindex) {
    bit_xor(l2_metadata.l2_src_move, ingress_metadata.ifindex, ifindex);
}




table smac {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_mac_sa : exact;
    }
    actions {
        nop;
        smac_miss;
        smac_hit;
    }
    size : 16384;
    support_timeout: true;
}

/*****************************************************************************/
/* Destination MAC lookup                                                    */
/*****************************************************************************/



action dmac_hit(ifindex, port_lag_index) {

    modify_field(ingress_metadata.egress_ifindex, ifindex);
    modify_field(ingress_metadata.egress_port_lag_index, port_lag_index);
    bit_xor(l2_metadata.same_if_check, ingress_metadata.ifindex, ifindex);



}
# 197 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4"
action dmac_miss() {
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
    modify_field(l2_metadata.l2_dst_miss, 1);



}


action dmac_redirect_nexthop(nexthop_index) {
    modify_field(l2_metadata.l2_redirect, 1);
    modify_field(l2_metadata.l2_nexthop, nexthop_index);
    modify_field(l2_metadata.l2_nexthop_type, 0);
}

action dmac_redirect_ecmp(ecmp_index) {
    modify_field(l2_metadata.l2_redirect, 1);
    modify_field(l2_metadata.l2_nexthop, ecmp_index);
    modify_field(l2_metadata.l2_nexthop_type, 1);
}

action dmac_redirect_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
}


action dmac_drop() {
    drop();
}

table dmac {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_mac_da : exact;
    }
    actions {




        nop;
        dmac_hit;



        dmac_miss;

        dmac_redirect_nexthop;
        dmac_redirect_ecmp;

        dmac_drop;




    }
    default_action : dmac_miss;
    size : 16384;
}


control process_mac {

    if (((ingress_metadata.bypass_lookups & 0x0080) == 0) and
        (ingress_metadata.port_type == 0)) {
        apply(smac);
    }
    if (((ingress_metadata.bypass_lookups & 0x0001) == 0)) {
        apply(dmac);
    }

}


/*****************************************************************************/
/* MAC learn notification                                                    */
/*****************************************************************************/
field_list mac_learn_digest {
    ingress_metadata.bd;
    l2_metadata.lkp_mac_sa;
    ingress_metadata.ifindex;
}

action generate_learn_notify() {
    generate_digest(0, mac_learn_digest);
}

table learn_notify {
    reads {
        l2_metadata.l2_src_miss : ternary;
        l2_metadata.l2_src_move : ternary;
        l2_metadata.stp_state : ternary;
    }
    actions {
        nop;
        generate_learn_notify;
    }
    size : 512;
}


control process_mac_learning {

  if ((l2_metadata.learning_enabled == 1) and (l2_metadata.port_learning_enabled == 1)){
        apply(learn_notify);
    }

}


/*****************************************************************************/
/* Validate packet                                                           */
/*****************************************************************************/
# 340 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4"
action set_unicast() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
}

action set_unicast_and_ipv6_src_is_link_local() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(ipv6_metadata.ipv6_src_is_link_local, 1);
}

action set_multicast() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    add_to_field(l2_metadata.bd_stats_idx, 1);
}

action set_multicast_and_ipv6_src_is_link_local() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(ipv6_metadata.ipv6_src_is_link_local, 1);
    add_to_field(l2_metadata.bd_stats_idx, 1);
}

action set_broadcast() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    add_to_field(l2_metadata.bd_stats_idx, 2);
}

action set_malformed_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

table validate_packet {
    reads {
        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l3_metadata.lkp_ip_type : ternary;
        l3_metadata.lkp_ip_ttl : ternary;

        l3_metadata.lkp_ip_version : ternary;





        ipv4_metadata.lkp_ipv4_sa mask 0xFF000000 : ternary;

        ipv6_metadata.lkp_ipv6_sa mask 0xFFFF0000000000000000000000000000 : ternary;

    }
    actions {
        nop;
        set_unicast;
        set_unicast_and_ipv6_src_is_link_local;
        set_multicast;
        set_multicast_and_ipv6_src_is_link_local;
        set_broadcast;
        set_malformed_packet;
    }
    size : 512;
}


control process_validate_packet {
    if (((ingress_metadata.bypass_lookups & 0x0040) == 0) and
        (ingress_metadata.drop_flag == 0)) {
        apply(validate_packet);
    }
}


/*****************************************************************************/
/* Egress BD lookup                                                          */
/*****************************************************************************/

counter egress_bd_stats {
    type : packets_and_bytes;
    direct : egress_bd_stats;
    min_width : 32;
}

table egress_bd_stats {
    reads {
        egress_metadata.bd : exact;
        l2_metadata.lkp_pkt_type: exact;
    }
    actions {
        nop;
    }
    size : 16384;
}


control process_egress_bd_stats {

    apply(egress_bd_stats);

}


action set_egress_bd_properties(smac_idx, mtu_index, nat_mode, bd_label) {
    modify_field(egress_metadata.smac_idx, smac_idx);
    modify_field(nat_metadata.egress_nat_mode, nat_mode);
    modify_field(acl_metadata.egress_bd_label, bd_label);
    modify_field(l3_metadata.mtu_index, mtu_index);
}

table egress_bd_map {
    reads {
        egress_metadata.bd : exact;
    }
    actions {
        nop;
        set_egress_bd_properties;
    }
    size : 5120;
}


control process_egress_bd {

    apply(egress_bd_map);

}

/*****************************************************************************/
/* Egress Outer BD lookup                                                    */
/*****************************************************************************/
# 485 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4"
control process_egress_outer_bd_stats {



}

action set_egress_outer_bd_properties(smac_idx, sip_idx, mtu_index, outer_bd_label) {
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_src_index, sip_idx);
    modify_field(l3_metadata.mtu_index, mtu_index);
}


table egress_outer_bd_map {
    reads {
        egress_metadata.outer_bd : exact;
    }
    actions {
        nop;
        set_egress_outer_bd_properties;
    }
    size : 5120;
}

control process_egress_outer_bd {



}

/*****************************************************************************/
/* Egress VLAN decap                                                         */
/*****************************************************************************/

action remove_vlan_single_tagged() {
    modify_field(ethernet.etherType, vlan_tag_[0].etherType);
    remove_header(vlan_tag_[0]);
}
# 536 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l2.p4"
table vlan_decap {
    reads {



        vlan_tag_[0] : valid;



    }
    actions {
        nop;
        remove_vlan_single_tagged;



    }
    size: 512;
}

control process_vlan_decap {
    apply(vlan_decap);
}

/*****************************************************************************/
/* Egress Spanning tree check                                               */
/*****************************************************************************/
register egress_stp_reg{
    width : 1;
    static : egress_stp;
    instance_count : 294912;
}

blackbox stateful_alu egress_stp_alu{
    reg: egress_stp_reg;
    update_lo_1_value: read_bit;
    output_value: alu_lo;
    output_dst: l2_metadata.egress_stp_check_fail;
}

@pragma field_list_field_slice eg_intr_md.egress_port 6 0 // Ports 0-71 ( local to the pipeline )
@pragma field_list_field_slice egress_metadata.bd 11 0 // First 4K BDs which are mapped 1:1 to VLAN
field_list egress_stp_fields {
    eg_intr_md.egress_port;
    egress_metadata.bd;
}

field_list_calculation egress_stp_hash {
    input { egress_stp_fields; }
    algorithm { identity; }
    output_width : 19;
}

action egress_stp_check() {
    egress_stp_alu.execute_stateful_alu_from_hash(egress_stp_hash);
}

table egress_stp {
    actions { egress_stp_check; }
    default_action : egress_stp_check;
    size : 1;
}

control process_egress_stp {





}
# 165 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l3.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Layer-3 processing
 */

/*
 * L3 Metadata
 */

header_type l3_metadata_t {
    fields {



        lkp_ip_type : 2;

        lkp_ip_version : 4;
        lkp_ip_proto : 8;
        lkp_dscp : 8;
        lkp_ip_ttl : 8;
        lkp_l4_sport : 16;
        lkp_l4_dport : 16;
        lkp_outer_l4_sport : 16;
        lkp_outer_l4_dport : 16;
        lkp_outer_tcp_flags : 8;
        lkp_inner_l4_sport : 16;
        lkp_inner_l4_dport : 16;
        lkp_inner_tcp_flags : 8;
        lkp_tcp_flags : 8;
        lkp_ip_llmc : 1;
        lkp_ip_mc : 1;
        lkp_ip_frag : 2; /* Flag indicating IP packet is fragmented.
                                                    00 : Not fragmented.
                                                    10 : Fragmented with non-zero offset.
                                                    11 : Fragmented with fragOffset of zero. */
        vrf : 14; /* VRF */
        rmac_group : 10; /* Rmac group, for rmac indirection */
        rmac_hit : 1; /* dst mac is the router's mac */






        fib_hit : 1; /* fib hit */
        fib_hit_myip : 1; /* fib hit on router ip address */
        fib_nexthop : 16; /* next hop from fib */
        fib_nexthop_type : 1; /* ecmp or nexthop */
        fib_label : 8; /* destination fib label */
        fib_partition_index : 12; /* partition index for atcam */
        same_bd_check : 14; /* ingress bd xor egress bd */
        nexthop_index : 16; /* nexthop/rewrite index */
        nexthop_dmac : 48;
        ipv6_da_idx12 : 12;
        ipv6_da_var16 : 16;
        ipv6_da_var40 : 40;
        routed : 1; /* is packet routed? */
        outer_routed : 1; /* is outer packet routed? */
        mtu_index : 8; /* index into mtu table */
        l3_copy : 1; /* copy packet to CPU */
        l3_mtu_check : 16 (saturating); /* result of mtu check */

        egress_l4_sport : 16;
        egress_l4_dport : 16;

        rocev2_opcode : 8;
        rocev2_ack_req_rsvd : 8;
        rocev2_dst_qp_plus_rsvd : 32;
        rocev2_aeth_syndrome : 8;

    }
}
# 156 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l3.p4"
metadata l3_metadata_t l3_metadata;

/*****************************************************************************/
/* Validate outer IP header                                                */
/*****************************************************************************/
# 206 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l3.p4"
/*****************************************************************************/
/* Router MAC lookup                                                         */
/*****************************************************************************/
action rmac_hit() {
    modify_field(l3_metadata.rmac_hit, 1);
}

action rmac_miss() {
    modify_field(l3_metadata.rmac_hit, 0);
}




table rmac {
    reads {
        l3_metadata.rmac_group : exact;
        l2_metadata.lkp_mac_da : exact;
    }
    actions {
        rmac_hit;
        rmac_miss;
    }
    size : 512;
}


/*****************************************************************************/
/* FIB hit actions for nexthops and ECMP                                     */
/*****************************************************************************/
# 282 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l3.p4"
action fib_hit_nexthop(nexthop_index, acl_label) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);



}

action fib_hit_myip(nexthop_index, acl_label) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);
    modify_field(l3_metadata.fib_hit_myip, 1);



}

action fib_hit_ecmp(ecmp_index, acl_label) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, ecmp_index);
    modify_field(l3_metadata.fib_nexthop_type, 1);



}


action fib_redirect_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
}
# 341 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/l3.p4"
control process_urpf_bd {






}


/*****************************************************************************/
/* Egress L3 rewrite                                                         */
/*****************************************************************************/
action rewrite_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table smac_rewrite {
    reads {
        egress_metadata.smac_idx : exact;
    }
    actions {
        rewrite_smac;
    }
    size : 512;
}


action ipv4_unicast_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv4.ttl, -1);
}

action ipv4_multicast_rewrite() {
    add_to_field(ipv4.ttl, -1);
}

action ipv6_unicast_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv6.hopLimit, -1);
}

action ipv6_multicast_rewrite() {
    add_to_field(ipv6.hopLimit, -1);
}

action mpls_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(mpls[0].ttl, -1);
}

table l3_rewrite {
    reads {
        ipv4 : valid;

        ipv6 : valid;




        ipv4.dstAddr mask 0xF0000000 : ternary;

        ipv6.dstAddr mask 0xFF000000000000000000000000000000 : ternary;

    }
    actions {
        nop;
        ipv4_unicast_rewrite;




        ipv6_unicast_rewrite;







    }
}

control process_mac_rewrite {

    if (egress_metadata.routed == 1) {
        apply(l3_rewrite);
        apply(smac_rewrite);
    }

}


/*****************************************************************************/
/* Egress MTU check                                                          */
/*****************************************************************************/

action ipv4_mtu_check(l3_mtu_plus_one) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu_plus_one, ipv4.totalLen);
}

action ipv6_mtu_check(l3_mtu_plus_one) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu_plus_one, ipv6.payloadLen);
}

action mtu_miss() {
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}


@pragma ternary 1




table mtu {
    reads {
        l3_metadata.mtu_index : exact;
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        mtu_miss;
        ipv4_mtu_check;

        ipv6_mtu_check;

    }
    size : 512;
}


control process_mtu {

    apply(mtu);

}
# 166 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * IPv4 processing
 */

/*
 * IPv4 metadata
 */
header_type ipv4_metadata_t {
    fields {
        lkp_ipv4_sa : 32;
        lkp_ipv4_da : 32;
        ipv4_unicast_enabled : 1; /* is ipv4 unicast routing enabled */



    }
}
# 52 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4"
metadata ipv4_metadata_t ipv4_metadata;


/*****************************************************************************/
/* Validate outer IPv4 header                                                */
/*****************************************************************************/
action set_valid_outer_ipv4_packet() {
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(l3_metadata.lkp_dscp, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, ipv4.version);




}

action set_validate_outer_ipv4_packet_with_option() {
    modify_field(l3_metadata.lkp_ip_type, 5);
    modify_field(l3_metadata.lkp_dscp, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, ipv4.version);




}

action set_valid_outer_ipv4_llmc_packet() {
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(l3_metadata.lkp_dscp, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, ipv4.version);
    modify_field(l3_metadata.lkp_ip_llmc, 1);




}

action set_valid_outer_ipv4_mc_packet() {
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(l3_metadata.lkp_dscp, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, ipv4.version);
    modify_field(l3_metadata.lkp_ip_mc, 1);




}

action set_malformed_outer_ipv4_packet(drop_reason) {


    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);

}

table validate_outer_ipv4_packet {
    reads {
        ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
        ipv4.version : ternary;
        ipv4.ihl: ternary;
        ipv4.ttl : ternary;
        ipv4.srcAddr mask 0xFF000000 : ternary;



    }
    actions {
        set_valid_outer_ipv4_packet;




        set_malformed_outer_ipv4_packet;
    }
    size : 512;
}


control validate_outer_ipv4_header {

    apply(validate_outer_ipv4_packet);

}






/*****************************************************************************/
/* IPv4 FIB local hosts lookup                                               */
/*****************************************************************************/

table ipv4_fib_local_hosts {
    reads {
        l3_metadata.vrf : exact; ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss; fib_hit_nexthop; fib_hit_ecmp; fib_hit_myip;
    }
    size : 8192;
}


/*****************************************************************************/
/* IPv4 FIB lookup                                                           */
/*****************************************************************************/
table ipv4_fib {
    reads {
        l3_metadata.vrf : exact; ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_myip;
        fib_hit_ecmp;



    }
    size : 40960;
}
# 194 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4"
@pragma alpm 1
@pragma ways 6
@pragma pa_solitary ingress ipv4_fib_lpm__metadata.ipv4_fib_lpm_partition_index
# 216 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4"
table ipv4_fib_lpm {
    reads {



        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : lpm;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;



    }
    size : 28672;
}


control process_ipv4_fib {





    apply(ipv4_fib_local_hosts) {
        on_miss {

            apply(ipv4_fib) {
                on_miss {
                    apply(ipv4_fib_lpm);
                }
            }

        }
    }


}
# 308 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4"
control process_ipv4_urpf {
# 327 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv4.p4"
}
# 167 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * IPv6 processing
 */

/*
 * IPv6 Metadata
 */
header_type ipv6_metadata_t {
    fields {
        lkp_ipv6_sa : 128; /* ipv6 source address */
        lkp_ipv6_da : 128; /* ipv6 destination address*/
        lkp_srh_da : 128;

        ipv6_unicast_enabled : 1; /* is ipv6 unicast routing enabled on BD */
        ipv6_src_is_link_local : 1; /* source is link local address */



        flow_label : 20; /* Flow Label from ipv6 header */
    }
}


@pragma pa_mutually_exclusive ingress ipv4_metadata.lkp_ipv4_sa ipv6_metadata.lkp_ipv6_sa
@pragma pa_mutually_exclusive ingress ipv4_metadata.lkp_ipv4_da ipv6_metadata.lkp_ipv6_da
# 77 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4"
metadata ipv6_metadata_t ipv6_metadata;


/*****************************************************************************/
/* Validate outer IPv6 header                                                */
/*****************************************************************************/
action set_valid_outer_ipv6_packet() {
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(l3_metadata.lkp_dscp, ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_version, ipv6.version);




}

action set_valid_outer_ipv6_llmc_packet() {
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(l3_metadata.lkp_dscp, ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_version, ipv6.version);




    modify_field(l3_metadata.lkp_ip_llmc, 1);
}

action set_valid_outer_ipv6_mc_packet() {
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(l3_metadata.lkp_dscp, ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_version, ipv6.version);




    modify_field(l3_metadata.lkp_ip_mc, 1);
}

action set_malformed_outer_ipv6_packet(drop_reason) {


    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);

}

/*
 * Table: Validate ipv6 packet
 * Lookup: Ingress
 * Validate and extract ipv6 header
 */
table validate_outer_ipv6_packet {
    reads {
        ipv6.version : ternary;
        ipv6.hopLimit : ternary;
        ipv6.srcAddr mask 0xFFFF0000000000000000000000000000 : ternary;



    }
    actions {
        set_valid_outer_ipv6_packet;




        set_malformed_outer_ipv6_packet;
    }
    size : 512;
}


control validate_outer_ipv6_header {

    apply(validate_outer_ipv6_packet);

}


/*****************************************************************************/
/* IPv6 FIB lookup                                                           */
/*****************************************************************************/
/*
 * Actions are defined in l3.p4 since they are
 * common for both ipv4 and ipv6
 */
# 181 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4"
/*
 * Table: Ipv6 LPM Lookup
 * Lookup: Ingress
 * Ipv6 route lookup for longest prefix match entries
 */





@pragma alpm 1
@pragma ways 6






table ipv6_fib_lpm {
    reads {





        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : lpm;

    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : 16384;
}


/*
 * Table: Ipv6 Host Lookup
 * Lookup: Ingress
 * Ipv6 route lookup for /128 entries
 */

table ipv6_fib {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_myip;
        fib_hit_ecmp;




    }
    size : 16384;
}


/*
 * Lookup: Ingress
 * Ipv6 route lookup for /64 entries
 */
# 269 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4"
control process_ipv6_fib {





    apply(ipv6_fib) {




                on_miss {
                    apply(ipv6_fib_lpm);
                }




    }




}
# 329 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4"
control process_ipv6_urpf {
# 340 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ipv6.p4"
}
# 168 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Tunnel processing
 */

/*
 * Tunnel metadata
 */
header_type tunnel_metadata_t {
    fields {
        ingress_tunnel_type : 4; /* tunnel type from parser */
        tunnel_vni : 24; /* tunnel id */
        mpls_enabled : 1; /* is mpls enabled on BD */
        mpls_ttl : 8; /* Mpls Ttl */
        mpls_exp : 3; /* Mpls Traffic Class */
        mpls_in_udp: 1; /* bit to indicate if mpls is in udp */
        egress_tunnel_type : 5; /* type of tunnel */
        tunnel_index : 8; /* tunnel index */
        tunnel_dst_index : 16; /* index to tunnel dst ip */
        tunnel_src_index : 8; /* index to tunnel src ip */
        tunnel_smac_index : 8; /* index to tunnel src mac */
        tunnel_dmac_index : 12; /* index to tunnel dst mac */
        vnid : 24; /* tunnel vnid */
        tunnel_lookup : 1; /* lookup tunnel table */
        tunnel_terminate : 1; /* is tunnel being terminated? */
        l3_tunnel_terminate : 1; /* tunnel termination with ip payload */
        tunnel_if_check : 1; /* tun terminate xor originate */
        egress_header_count: 4; /* number of mpls header stack */
        inner_ip_proto : 8; /* Inner IP protocol */
        src_vtep_hit : 1; /* hit in the src vtep table */
        vtep_ifindex : 14; /* vtep ingress ifindex */
        tunnel_term_type : 1; /* Point-to-point or multipoint-to-point tunnel */
    }
}
# 67 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
//@pragma pa_container_size ingress tunnel_metadata.tunnel_lookup 8
metadata tunnel_metadata_t tunnel_metadata;

/*****************************************************************************/
/* Outer router mac lookup                                                   */
/*****************************************************************************/
# 498 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
/*############################################################################/
/# Older Tunnel termination scheme                                           #/
/############################################################################*/
# 893 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
action ipv4_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, ipv4.ttl);

    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
    modify_field(l3_metadata.lkp_tcp_flags, l3_metadata.lkp_outer_tcp_flags);
# 912 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
}

action ipv6_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv6_metadata.lkp_ipv6_sa, ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_ttl, ipv6.hopLimit);

    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
    modify_field(l3_metadata.lkp_tcp_flags, tcp.flags);
# 933 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
}

action non_ip_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l2_metadata.non_ip_packet, 1);







}




table adjust_lkp_fields {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;

        ipv6_lkp;

    }
}

table tunnel_lookup_miss {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;

        ipv6_lkp;

    }
}

action tunnel_check_pass() {
}

table tunnel_check {
    reads {
        tunnel_metadata.ingress_tunnel_type : ternary;
        tunnel_metadata.tunnel_lookup : ternary;
        tunnel_metadata.src_vtep_hit : ternary;
        tunnel_metadata.tunnel_term_type : ternary;
    }
    actions {
        nop;
        tunnel_check_pass;
    }
}

/*****************************************************************************/
/* Ingress tunnel processing                                                 */
/*****************************************************************************/
control process_tunnel {
# 1044 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
}
# 1095 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
control validate_mpls_header {



}
# 1462 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
/*****************************************************************************/
/* Tunnel decap processing                                                   */
/*****************************************************************************/
control process_tunnel_decap {
# 1485 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
}
# 1924 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
action f_insert_ipv4_header(proto) {
    add_header(ipv4);
    modify_field(ipv4.protocol, proto);
    modify_field(ipv4.ttl, 64);
    modify_field(ipv4.version, 0x4);
    modify_field(ipv4.ihl, 0x5);
    modify_field(ipv4.diffserv, 0);
    modify_field(ipv4.identification, 0);
    modify_field(ipv4.flags, 0x2);
}

action f_insert_ipv6_header(proto) {
    add_header(ipv6);
    modify_field(ipv6.version, 0x6);
    modify_field(ipv6.nextHdr, proto);
    modify_field(ipv6.hopLimit, 64);
    modify_field(ipv6.trafficClass, 0);
    modify_field(ipv6.flowLabel, 0);
}

@pragma ternary 1
table tunnel_encap_process_outer {
    reads {
        tunnel_metadata.egress_tunnel_type : exact;



    }
    actions {
        nop;
# 2005 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
    }
    size : 512;
}


/*****************************************************************************/
/* Tunnel rewrite                                                            */
/*****************************************************************************/
action set_ipv4_tunnel_rewrite_details(ipv4_sa) {
    modify_field(ipv4.srcAddr, ipv4_sa);
}
# 2130 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
table tunnel_rewrite {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        nop;
# 2167 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
    }
    size : 4096;
}
# 2262 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
/*****************************************************************************/
/* Tunnel destination MAC rewrite                                            */
/*****************************************************************************/
action rewrite_tunnel_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}

table tunnel_dmac_rewrite {
    reads {
        tunnel_metadata.tunnel_dmac_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_dmac;
    }
    size : 4096;
}

/*****************************************************************************/
/* Tunnel encap processing                                                   */
/*****************************************************************************/
control process_tunnel_encap {
    if (tunnel_metadata.egress_tunnel_type != 0) {
# 2324 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
    }
}

/*****************************************************************************/
/* Tunnel ID processing                                                      */
/*****************************************************************************/
# 2394 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/tunnel.p4"
control process_tunnel_id {





}
# 169 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * ACL processing : MAC, IPv4, IPv6, RACL/PBR
 */

/*
 * ACL metadata
 */
header_type acl_metadata_t {
    fields {
        acl_deny : 1; /* ifacl/vacl deny action */
        racl_deny : 1; /* racl deny action */
        egress_acl_deny : 1; /* egress acl deny action */

        acl_nexthop : 16; /* next hop from ifacl/vacl */
        racl_nexthop : 16; /* next hop from racl */
        acl_nexthop_type : 1; /* ecmp or nexthop */
        racl_nexthop_type : 1; /* ecmp or nexthop */

        acl_redirect : 1; /* ifacl/vacl redirect action */
        racl_redirect : 1; /* racl redirect action */
        port_lag_label : 16; /* port/lag label for acls */
        //if_label : 16;                         /* if label for acls */
        bd_label : 16; /* bd label for acls */
        acl_stats_index : 12; /* acl stats index */
        mirror_acl_stats_index : 12; /* mirror acl stats index */
        racl_stats_index : 12; /* ingress racl stats index */
        egress_acl_stats_index : 12; /* egress acl stats index */
        dtel_acl_stats_index : 12; /* dtel acl stats index */
        acl_partition_index : 16; /* acl atcam partition index */
        egress_port_lag_label : 16; /* port/lag label for acls */
        //egress_if_label : 16;                  /* if label for egress acls */
        egress_bd_label : 16; /* bd label for egress acls */
        ingress_src_port_range_id : 8; /* ingress src port range id */
        ingress_dst_port_range_id : 8; /* ingress dst port range id */
        egress_src_port_range_id : 8; /* egress src port range id */
        egress_dst_port_range_id : 8; /* egress dst port range id */
        copp_meter_id : 8; /* copp meter-id */
        copp_meter_id_2 : 8; /* copp meter-id for system_acl_2 */
        mac_pkt_classify : 1; /* enables MAC-packet classify */
        acl_entry_hit : 1; /* user ACL hit bit */
        acl_label : 8;
        inner_outer_ip_type : 2; /* inner if exists, else outer */
        inner_outer_etype : 16; /* inner if exists, else outer */
        inner_outer_ipv4_sa : 32; /* inner if exists, else outer */
        inner_outer_ipv4_da : 32; /* inner if exists, else outer */
        inner_outer_ipv6_sa : 128; /* inner if exists, else outer */
        inner_outer_ipv6_da : 128; /* inner if exists, else outer */
        inner_outer_ip_proto : 8; /* inner if exists, else outer */
        inner_outer_ip_dscp : 8; /* inner if exists, else outer */
        inner_outer_ip_sport : 16; /* inner if exists, else outer */
        inner_outer_ip_dport : 16; /* inner if exists, else outer */
        inner_outer_src_port_range_id : 8; /* inner if exists, else outer */
        inner_outer_dst_port_range_id : 8; /* inner if exists, else outer */
        inner_outer_is_inner: 1; /* 1 indicates inner fields */
    }
}
# 97 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
//#define INGRESS_ACL_KEY_CFI              l2_metadata.lkp_cfi
# 153 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
//        INGRESS_ACL_KEY_IP_FRAGMENT : ternary; 
# 407 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
header_type i2e_metadata_t {
    fields {
        ingress_tstamp : 32;
        ingress_tstamp_hi : 16;
        mirror_session_id : 16;
    }
}
# 425 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
@pragma pa_solitary ingress acl_metadata.port_lag_label
@pragma pa_atomic ingress acl_metadata.port_lag_label
# 471 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
metadata acl_metadata_t acl_metadata;
metadata i2e_metadata_t i2e_metadata;

/*****************************************************************************/
/* Egress ACL l4 port range                                                  */
/*****************************************************************************/


action set_egress_src_port_range_id(range_id) {
    modify_field(acl_metadata.egress_src_port_range_id, range_id);
}

table egress_l4_src_port {
    reads {
        l3_metadata.lkp_outer_l4_sport : range;
    }
    actions {
        nop;
        set_egress_src_port_range_id;
    }
    size: 256;
}

action set_egress_dst_port_range_id(range_id) {
    modify_field(acl_metadata.egress_dst_port_range_id, range_id);
}

table egress_l4_dst_port {
    reads {
        l3_metadata.lkp_outer_l4_dport : range;
    }
    actions {
        nop;
        set_egress_dst_port_range_id;
    }
    size: 256;
}




control process_egress_l4port {


    apply(egress_l4_src_port);
    apply(egress_l4_dst_port);


}

/*****************************************************************************/
/* Ingress ACL l4 port range                                                 */
/*****************************************************************************/

action set_ingress_src_port_range_id(range_id) {
    modify_field(acl_metadata.ingress_src_port_range_id, range_id);
}

table ingress_l4_src_port {
    reads {
        l3_metadata.lkp_l4_sport : range;
    }
    actions {
        nop;
        set_ingress_src_port_range_id;
    }
    size: 512;
}

action set_ingress_dst_port_range_id(range_id) {
    modify_field(acl_metadata.ingress_dst_port_range_id, range_id);
}

table ingress_l4_dst_port {
    reads {
        l3_metadata.lkp_l4_dport : range;
    }
    actions {
        nop;
        set_ingress_dst_port_range_id;
    }
    size: 512;
}


control process_ingress_l4port {

    apply(ingress_l4_src_port);
    apply(ingress_l4_dst_port);

}

/*****************************************************************************/
/* ACL Actions                                                               */
/*****************************************************************************/
action acl_deny(acl_stats_index, acl_meter_index, acl_copy_reason,
                ingress_cos, tc, color, label) {




    modify_field(acl_metadata.acl_deny, 1);

    modify_field(acl_metadata.acl_stats_index, acl_stats_index);

    modify_field(fabric_metadata.reason_code, acl_copy_reason);
# 594 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action acl_permit(acl_stats_index, acl_meter_index, acl_copy_reason,
                  nat_mode, ingress_cos, tc, color, label) {
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);

    modify_field(fabric_metadata.reason_code, acl_copy_reason);

    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
# 619 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

field_list i2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}

field_list e2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}

action acl_mirror(session_id, acl_stats_index, acl_meter_index, nat_mode,
                  ingress_cos, tc, color, label) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
# 653 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action acl_redirect_nexthop(nexthop_index, acl_stats_index, acl_meter_index,
                            acl_copy_reason, nat_mode,
                            ingress_cos, tc, color, label) {
    modify_field(acl_metadata.acl_redirect, 1);




    modify_field(acl_metadata.acl_nexthop, nexthop_index);
    modify_field(acl_metadata.acl_nexthop_type, 0);

    modify_field(acl_metadata.acl_stats_index, acl_stats_index);

    modify_field(fabric_metadata.reason_code, acl_copy_reason);

    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
# 687 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action acl_redirect_ecmp(ecmp_index, acl_stats_index, acl_meter_index,
                         acl_copy_reason, nat_mode,
                         ingress_cos, tc, color, label) {
    modify_field(acl_metadata.acl_redirect, 1);




    modify_field(acl_metadata.acl_nexthop, ecmp_index);
    modify_field(acl_metadata.acl_nexthop_type, 1);

    modify_field(acl_metadata.acl_stats_index, acl_stats_index);

    modify_field(fabric_metadata.reason_code, acl_copy_reason);

    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
# 721 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action acl_set_qos_fields(tc, color, acl_meter_index) {
    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(ig_intr_md_for_tm.packet_color, color);



}

/*****************************************************************************/
/* MAC ACL                                                                   */
/*****************************************************************************/

table mac_acl {
    reads {
        acl_metadata.port_lag_label : ternary; acl_metadata.bd_label : ternary; l2_metadata.lkp_mac_sa : ternary; l2_metadata.lkp_mac_da : ternary; l2_metadata.lkp_mac_type : ternary;






    }
    actions {
        nop;
        acl_deny;
        acl_permit;

        acl_redirect_nexthop;
        acl_redirect_ecmp;


        acl_mirror;

    }
    size : 512;
}


control process_mac_acl {

    if (((ingress_metadata.bypass_lookups & 0x0004) == 0)) {
        apply(mac_acl);
    }

}

/*****************************************************************************/
/* FCOE ACL                                                                  */
/*****************************************************************************/
# 796 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* TCP Flags                                                                 */
/*****************************************************************************/
# 822 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* IPv4 ACL                                                                  */
/*****************************************************************************/
# 869 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
table ip_acl {
    reads {



        acl_metadata.port_lag_label : ternary; acl_metadata.bd_label : ternary; ipv4_metadata.lkp_ipv4_sa : ternary; ipv4_metadata.lkp_ipv4_da : ternary; l3_metadata.lkp_ip_proto : ternary; l3_metadata.lkp_ip_ttl : ternary; l3_metadata.lkp_tcp_flags : ternary; acl_metadata.ingress_src_port_range_id : ternary; acl_metadata.ingress_dst_port_range_id : ternary;







        l2_metadata.lkp_mac_type : ternary;


        l3_metadata.lkp_dscp : ternary;


        l3_metadata.rmac_hit : ternary;







    }
    actions {
        nop;
        acl_deny;
        acl_permit;

        acl_redirect_nexthop;
        acl_redirect_ecmp;


        acl_mirror;

    }
    size : 1024;
}



/*****************************************************************************/
/* IPv6 ACL                                                                  */
/*****************************************************************************/
# 954 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
table ipv6_acl {
    reads {



        acl_metadata.port_lag_label : ternary; acl_metadata.bd_label : ternary; ipv6_metadata.lkp_ipv6_sa : ternary; ipv6_metadata.lkp_ipv6_da : ternary; l3_metadata.lkp_ip_proto : ternary; l3_metadata.lkp_ip_ttl : ternary; l3_metadata.lkp_tcp_flags : ternary; acl_metadata.ingress_src_port_range_id : ternary; acl_metadata.ingress_dst_port_range_id : ternary;







        l2_metadata.lkp_mac_type : ternary;


        l3_metadata.lkp_dscp : ternary;


        l3_metadata.rmac_hit : ternary;

    }
    actions {
        nop;
        acl_deny;
        acl_permit;

        acl_redirect_nexthop;
        acl_redirect_ecmp;


        acl_mirror;

    }
    size : 512;
}


/*****************************************************************************/
/* QoS ACLs                                                                  */
/*****************************************************************************/
# 1049 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* ACL Control flow                                                          */
/*****************************************************************************/
control process_tcp_flags {



}

control process_ip_acl {
    if (((ingress_metadata.bypass_lookups & 0x0004) == 0)) {
        if (l3_metadata.lkp_ip_type == 1) {




            apply(ip_acl);

        } else {
            if (l3_metadata.lkp_ip_type == 2) {




                apply(ipv6_acl);

            }
        }
    }
}

/*****************************************************************************/
/* RACL actions                                                              */
/*****************************************************************************/
action racl_deny(acl_stats_index, acl_copy_reason,
                 ingress_cos, tc, color, label) {
    modify_field(acl_metadata.racl_deny, 1);

    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
# 1109 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action racl_permit(acl_stats_index, acl_copy_reason,
                   ingress_cos, tc, color, label, acl_meter_index) {

    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
# 1136 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action racl_redirect_nexthop(nexthop_index, acl_stats_index,
                             acl_copy_reason,
                             ingress_cos, tc, color, label, acl_meter_index) {
    modify_field(acl_metadata.racl_redirect, 1);




    modify_field(acl_metadata.acl_nexthop, nexthop_index);
    modify_field(acl_metadata.acl_nexthop_type, 0);


    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
# 1172 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

action racl_redirect_ecmp(ecmp_index, acl_stats_index,
                          acl_copy_reason,
                          ingress_cos, tc, color, label, acl_meter_index) {
    modify_field(acl_metadata.racl_redirect, 1);




    modify_field(acl_metadata.acl_nexthop, ecmp_index);
    modify_field(acl_metadata.acl_nexthop_type, 1);


    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
# 1208 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}


/*****************************************************************************/
/* IPv4 RACL                                                                 */
/*****************************************************************************/
# 1242 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
control process_ipv4_racl {



}

/*****************************************************************************/
/* IPv6 RACL                                                                 */
/*****************************************************************************/
# 1276 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
control process_ipv6_racl {



}

/*****************************************************************************/
/* Mirror ACL actions                                                        */
/*****************************************************************************/
action mirror_acl_mirror(session_id, acl_stats_index) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);

    modify_field(acl_metadata.mirror_acl_stats_index, acl_stats_index);

}

/*****************************************************************************/
/* IPv4 Mirror ACL                                                           */
/*****************************************************************************/

table ipv4_mirror_acl {
    reads {
        acl_metadata.port_lag_label : ternary; ipv4_metadata.lkp_ipv4_sa : ternary; ipv4_metadata.lkp_ipv4_da : ternary; l3_metadata.lkp_ip_proto : ternary; l3_metadata.lkp_dscp : ternary; l3_metadata.lkp_tcp_flags : ternary; acl_metadata.ingress_src_port_range_id : ternary; acl_metadata.ingress_dst_port_range_id : ternary;

     l3_metadata.rocev2_opcode : ternary;
        l3_metadata.rocev2_dst_qp_plus_rsvd : ternary;
        l3_metadata.rocev2_aeth_syndrome : ternary;


        l2_metadata.lkp_mac_type : ternary;

    }
    actions {
        nop;
        mirror_acl_mirror;
    }
    size : 512;
}


control process_ipv4_mirror_acl {

    apply(ipv4_mirror_acl);

}

/*****************************************************************************/
/* IPv6 Mirror ACL                                                           */
/*****************************************************************************/

table ipv6_mirror_acl {
    reads {
        acl_metadata.port_lag_label : ternary; ipv6_metadata.lkp_ipv6_sa : ternary; ipv6_metadata.lkp_ipv6_da : ternary; l3_metadata.lkp_ip_proto : ternary; l3_metadata.lkp_dscp : ternary; l3_metadata.lkp_tcp_flags : ternary; acl_metadata.ingress_src_port_range_id : ternary; acl_metadata.ingress_dst_port_range_id : ternary;

        l2_metadata.lkp_mac_type : ternary;

    }
    actions {
        nop;
        mirror_acl_mirror;
    }
    size : 512;
}


control process_ipv6_mirror_acl {

    apply(ipv6_mirror_acl);

}

/*****************************************************************************/
/* DTEL ACL Prepare                                                          */
/*****************************************************************************/
# 1528 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* DTEL ACL actions                                                          */
/*****************************************************************************/
# 1648 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* IPv4 DTEL ACL                                                             */
/*****************************************************************************/
# 1697 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* IPv6 DTEL ACL                                                             */
/*****************************************************************************/
# 1746 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* DTEL ACL Control                                                          */
/*****************************************************************************/
control process_dtel_acl {
# 1790 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}

/*****************************************************************************/
/* ACL stats                                                                 */
/*****************************************************************************/

counter acl_stats {
    type : packets_and_bytes;
    instance_count : 2048;
    min_width : 16;
}

action acl_stats_update() {
    count(acl_stats, acl_metadata.acl_stats_index);
}

table acl_stats {
    actions {
        acl_stats_update;
    }
    default_action : acl_stats_update;
    size : 2048;
}



counter mirror_acl_stats {
 type : packets_and_bytes;
 instance_count : 1024;
 min_width : 16;
}

action mirror_acl_stats_update() {
  count(mirror_acl_stats, acl_metadata.mirror_acl_stats_index);
}

table mirror_acl_stats {
  actions {
    mirror_acl_stats_update;
  }
  default_action : mirror_acl_stats_update;
 size : 1024;
}
# 1879 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
control process_ingress_acl_stats {

    apply(acl_stats);

}

control process_ingress_mirror_acl_stats {

  apply(mirror_acl_stats);

}

control process_ingress_racl_stats {



}

/*****************************************************************************/
/* CoPP                                                                      */
/*****************************************************************************/

meter copp {
    type: packets;
    static: system_acl;
    result: ig_intr_md_for_tm.packet_color;
    instance_count: 512;
}



counter copp_stats {
    type : packets;
    direct : copp_drop;
}

action copp_drop() {
  modify_field(ig_intr_md_for_tm.copy_to_cpu, 0);
}

table copp_drop {
    reads {
        ig_intr_md_for_tm.packet_color : ternary;
        acl_metadata.copp_meter_id : ternary;
    }
    actions {
        nop;
        copp_drop;



    }
    size : 512;
}


/*****************************************************************************/
/* System ACL                                                                */
/*****************************************************************************/
counter drop_stats {
    type : packets;
    instance_count : 1024;
}

counter drop_stats_2 {
    type : packets;
    instance_count : 1024;
}
# 2037 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
action redirect_to_cpu_with_reason(reason_code, qid, meter_id, icos) {
    copy_to_cpu_with_reason(reason_code, qid, meter_id, icos);
    drop();



}

action redirect_to_port(dst_port) {



    modify_field(ig_intr_md_for_tm.ucast_egress_port, dst_port);
}

action redirect_to_cpu(qid, meter_id, icos) {
    copy_to_cpu(qid, meter_id, icos);
    drop();



}

field_list cpu_info {
    ingress_metadata.bd;
    ingress_metadata.ifindex;
    fabric_metadata.reason_code;
    ingress_metadata.ingress_port;
}

action copy_to_cpu(qid, meter_id, icos) {
    modify_field(ig_intr_md_for_tm.qid, qid);
    modify_field(ig_intr_md_for_tm.ingress_cos, icos);

    modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);




    execute_meter(copp, meter_id, ig_intr_md_for_tm.packet_color);
    modify_field(acl_metadata.copp_meter_id, meter_id);

}

action copy_to_cpu_with_reason(reason_code, qid, meter_id, icos) {
    modify_field(fabric_metadata.reason_code, reason_code);
    copy_to_cpu(qid, meter_id, icos);
}

action drop_packet() {
    drop();
}

action drop_packet_with_reason(drop_reason) {
    count(drop_stats, drop_reason);
    drop();
}

action drop_cancel() {
  modify_field(ig_intr_md_for_tm.drop_ctl,0,1);
}
# 2196 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
table system_acl {
    reads {






        acl_metadata.port_lag_label : ternary;



        acl_metadata.bd_label : ternary;


        ingress_metadata.ifindex : ternary;

        // should we add port_lag_index here?

        /* drop reasons */
        l2_metadata.lkp_mac_type : ternary;
        l2_metadata.port_vlan_mapping_miss : ternary;
        l2_metadata.ingress_vlan_mbr_check_fail : ternary;



        acl_metadata.acl_deny : ternary;







        meter_metadata.storm_control_color : ternary;




        ingress_metadata.drop_flag : ternary;

        l3_metadata.rmac_hit : ternary;
        l3_metadata.fib_hit_myip : ternary;

        nexthop_metadata.nexthop_glean : ternary;


        /*
         * other checks, routed link_local packet, l3 same if check,
         * expired ttl
         */
# 2261 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
        l3_metadata.routed : ternary;
        ipv6_metadata.ipv6_src_is_link_local : ternary;
        l2_metadata.same_if_check : ternary;



        l3_metadata.same_bd_check : ternary;
        l3_metadata.lkp_ip_ttl : ternary;





        l2_metadata.l2_src_miss : ternary;
        l2_metadata.l2_src_move : ternary;

        ipv4_metadata.ipv4_unicast_enabled : ternary;

        ipv6_metadata.ipv6_unicast_enabled : ternary;



        l2_metadata.l2_dst_miss : ternary;

        l2_metadata.lkp_pkt_type : ternary;
        l2_metadata.arp_opcode : ternary;
        /* egress information */

        ingress_metadata.egress_ifindex : ternary;



        fabric_metadata.reason_code : ternary;
# 2307 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
        ipv4.ihl : ternary;
# 2328 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
}
    actions {
        nop;
        redirect_to_cpu;
        redirect_to_cpu_with_reason;
        copy_to_cpu;
        copy_to_cpu_with_reason;
        drop_packet;
        drop_packet_with_reason;
# 2360 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
    }
    size : 512;
}


action same_check_drop(drop_reason) {
    modify_field(ingress_metadata.drop_reason, drop_reason);
    modify_field(ingress_metadata.drop_flag, 1);
    drop();
}

action mirror_and_drop_same_check_drop(drop_reason) {
    modify_field(ingress_metadata.drop_reason, drop_reason);



}

table same_port_check_enable {
    reads {
        ingress_metadata.ingress_port : exact;
        ig_intr_md_for_tm.ucast_egress_port : exact;



    }
    actions {
        nop;
        same_check_drop;



    }
    default_action: nop;
    size : 288;
}
# 2444 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
action drop_stats_update() {
    count(drop_stats_2, ingress_metadata.drop_reason);



}

table drop_stats {
    actions {
        drop_stats_update;
    }
    default_action : drop_stats_update;
    size : 1024;
}
# 2480 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
control process_system_acl {

    if (((ingress_metadata.bypass_lookups & 0x0020) == 0)) {





                apply(same_port_check_enable) {
                    nop {
# 2498 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
        apply(system_acl);

                    }
                }





        if (ingress_metadata.drop_flag == 1) {
            apply(drop_stats);
        }
# 2521 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
   apply(copp_drop);


    }
}

/*****************************************************************************/
/* Egress ACL                                                                */
/*****************************************************************************/



/*****************************************************************************/
/* Egress ACL Actions                                                        */
/*****************************************************************************/
action egress_acl_deny(acl_copy_reason, acl_stats_index) {
    modify_field(acl_metadata.egress_acl_deny, 1);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);

    modify_field(acl_metadata.egress_acl_stats_index, acl_stats_index);

}

action egress_acl_permit(acl_copy_reason, acl_stats_index,acl_meter_index) {
    modify_field(fabric_metadata.reason_code, acl_copy_reason);

    modify_field(acl_metadata.egress_acl_stats_index, acl_stats_index);




}

/*****************************************************************************/
/* Egress Mac ACL                                                            */
/*****************************************************************************/
# 2572 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
/*****************************************************************************/
/* Egress IPv4 ACL                                                           */
/*****************************************************************************/

table egress_ip_acl {
    reads {
        acl_metadata.egress_port_lag_label : ternary; acl_metadata.egress_bd_label : ternary; ipv4.srcAddr : ternary; ipv4.dstAddr : ternary; ipv4.protocol : ternary;




        acl_metadata.egress_src_port_range_id : ternary;
        acl_metadata.egress_dst_port_range_id : ternary;


        ipv4.diffserv : ternary;




    }
    actions {
        nop;
        egress_acl_deny;
        egress_acl_permit;
    }
    size : 512;
}


/*****************************************************************************/
/* Egress IPv6 ACL                                                           */
/*****************************************************************************/




table egress_ipv6_acl {
    reads {
        acl_metadata.egress_port_lag_label : ternary; acl_metadata.egress_bd_label : ternary; ipv6.srcAddr : ternary; ipv6.dstAddr : ternary; ipv6.nextHdr : ternary;




        acl_metadata.egress_src_port_range_id : ternary;
        acl_metadata.egress_dst_port_range_id : ternary;


        ipv6.trafficClass : ternary;




    }
    actions {
        nop;
        egress_acl_deny;
        egress_acl_permit;
    }
    size : 512;
}




/*****************************************************************************/
/* Egress ACL Control flow                                                   */
/*****************************************************************************/
control process_egress_acl {

    if (valid(ipv4)) {

        apply(egress_ip_acl);

    } else {
        if (valid(ipv6)) {

            apply(egress_ipv6_acl);





        }
    }

}

/*****************************************************************************/
/* Egress ACL stats                                                          */
/*****************************************************************************/

counter egress_acl_stats {
    type : packets_and_bytes;
    instance_count : 1024;
    min_width : 16;
}

action egress_acl_stats_update() {
    count(egress_acl_stats, acl_metadata.egress_acl_stats_index);
}

table egress_acl_stats {
    actions {
        egress_acl_stats_update;
    }
    default_action : egress_acl_stats_update;
    size : 1024;
}


control process_egress_acl_stats {

    apply(egress_acl_stats);

}

/*****************************************************************************/
/* Egress System ACL                                                         */
/*****************************************************************************/
# 2723 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
action egress_mirror(session_id) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_egress_pkt_to_egress(session_id, e2e_mirror_info);
}

action egress_mirror_and_drop(reason_code) {
    // This is used for cases like mirror on drop where
    // original frame needs to be dropped after mirror copy is made







    drop();
}
# 2749 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
action egress_copy_to_cpu() {
    clone_egress_pkt_to_egress(250, cpu_info);
}

action egress_redirect_to_cpu() {
    egress_copy_to_cpu();
    drop();
}

action egress_copy_to_cpu_with_reason(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
    egress_copy_to_cpu();
}

action egress_redirect_to_cpu_with_reason(reason_code) {
    egress_copy_to_cpu_with_reason(reason_code);
    drop();
}

// Example of coal_mirroring with small sample header
action egress_mirror_coal_hdr(session_id, id) {






}

action egress_insert_cpu_timestamp() {






}
# 2794 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
table egress_system_acl {
    reads {
        fabric_metadata.reason_code : ternary;

        ig_intr_md_for_tm.packet_color : ternary;





        eg_intr_md.egress_port : ternary;
        eg_intr_md.deflection_flag : ternary;
        l3_metadata.l3_mtu_check : ternary;
# 2815 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
        wred_metadata.drop_flag : ternary;


        acl_metadata.egress_acl_deny : ternary;
# 2832 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/acl.p4"
        ingress_metadata.ingress_port : ternary;

    }
    actions {
        nop;
        drop_packet;
        egress_copy_to_cpu;
        egress_redirect_to_cpu;
        egress_copy_to_cpu_with_reason;
        egress_redirect_to_cpu_with_reason;
        egress_mirror_coal_hdr;




        egress_mirror;
        egress_mirror_and_drop;




    }
    size : 512;
}

control process_egress_system_acl {
    if (egress_metadata.bypass == 0) {
        apply(egress_system_acl);
    }
}
# 170 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nat.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * NAT processing
 */

header_type nat_metadata_t {
    fields {
        ingress_nat_mode : 2; /* 0: none, 1: inside, 2: outside */
        egress_nat_mode : 2; /* nat mode of egress_bd */
        nat_nexthop : 16; /* next hop from nat */
        nat_nexthop_type : 1; /* ecmp or nexthop */
        nat_hit : 1; /* fwd and rewrite info from nat */
        nat_rewrite_index : 14; /* NAT rewrite index */
        update_checksum : 1; /* update tcp/udp checksum */
        update_udp_checksum : 1; /* update udp checksum */
        update_tcp_checksum : 1; /* update tcp checksum */
        update_inner_udp_checksum : 1; /* update inner udp checksum */
        update_inner_tcp_checksum : 1; /* update inner tcp checksum */
        l4_len : 16; /* l4 length */
    }
}

metadata nat_metadata_t nat_metadata;
# 149 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nat.p4"
control process_ingress_nat {
# 165 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nat.p4"
}


/*****************************************************************************/
/* Egress NAT rewrite                                                        */
/*****************************************************************************/
# 295 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nat.p4"
control process_egress_nat {






}

control process_l4_checksum {



}
# 171 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Multicast processing
 */

header_type multicast_metadata_t {
    fields {
        ipv4_mcast_key_type : 1; /* 0 bd, 1 vrf */
        ipv4_mcast_key : 14; /* bd or vrf value */
        ipv6_mcast_key_type : 1; /* 0 bd, 1 vrf */
        ipv6_mcast_key : 14; /* bd or vrf value */
        outer_mcast_route_hit : 1; /* hit in the outer multicast table */
        outer_mcast_mode : 2; /* multicast mode from route */
        mcast_route_hit : 1; /* hit in the multicast route table */
        mcast_route_s_g_hit : 1; /* hit in the multicast S,G route table */
        mcast_bridge_hit : 1; /* hit in the multicast bridge table */
        mcast_copy_to_cpu : 1; /* copy to cpu flag */
        ipv4_multicast_enabled : 1; /* is ipv4 multicast enabled on BD */
        ipv6_multicast_enabled : 1; /* is ipv6 multicast enabled on BD */
        igmp_snooping_enabled : 1; /* is IGMP snooping enabled on BD */
        mld_snooping_enabled : 1; /* is MLD snooping enabled on BD */
        bd_mrpf_group : 14; /* rpf group from bd lookup */
        mcast_rpf_group : 14; /* rpf group from mcast lookup */
        mcast_rpf_fail : 1; /* RPF check failed */
        flood_to_mrouters : 1; /* Flood to router ports only */
        mcast_mode : 2; /* multicast mode from route */
        multicast_route_mc_index : 16; /* multicast index from mfib */
        multicast_bridge_mc_index : 16; /* multicast index from igmp/mld snoop */
        inner_replica : 1; /* is copy is due to inner replication */
        replica : 1; /* is this a replica */






    }
}


@pragma pa_solitary ingress multicast_metadata.multicast_route_mc_index
@pragma pa_atomic ingress multicast_metadata.multicast_route_mc_index
@pragma pa_solitary ingress multicast_metadata.multicast_bridge_mc_index
@pragma pa_atomic ingress multicast_metadata.multicast_bridge_mc_index


/* This field is part of bridged metadata.  The fabric
   profile puts a lot of pressure on 16-bit containers.
   Even though the natural container size of this field is 16,
   it can safely be allocated in a 32-bit container based
   on the packing constraints of the egress instance of
   fabric_header_multicast. */
//@pragma pa_container_size ingress ig_intr_md_for_tm.mcast_grp_a 16





metadata multicast_metadata_t multicast_metadata;

/*****************************************************************************/
/* Outer IP multicast RPF check                                              */
/*****************************************************************************/
# 105 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_outer_multicast_rpf {






}


/*****************************************************************************/
/* Outer IP mutlicast lookup actions                                         */
/*****************************************************************************/
# 175 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
/*****************************************************************************/
/* Outer IPv4 multicast lookup                                               */
/*****************************************************************************/
# 224 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_outer_ipv4_multicast {
# 240 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* Outer IPv6 multicast lookup                                               */
/*****************************************************************************/
# 291 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_outer_ipv6_multicast {
# 306 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* Process outer IP multicast                                                */
/*****************************************************************************/
control process_outer_multicast {
# 325 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* IP multicast RPF check                                                    */
/*****************************************************************************/
# 357 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_multicast_rpf {





}


/*****************************************************************************/
/* IP multicast lookup actions                                               */
/*****************************************************************************/

//#ifdef FWD_RESULTS_OPTIMIZATION_ENABLE
        // Note : Only L2 multicast case is handled for now
action multicast_bridge_hit(mc_index, copy_to_cpu) {
    modify_field(ingress_metadata.egress_ifindex, 0);
//    modify_field(ingress_metadata.egress_port_lag_index, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);
//    modify_field(multicast_metadata.mcast_bridge_hit, TRUE);
}

action multicast_bridge_miss() {
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}

//#else
 action multicast_bridge_star_g_hit(mc_index, copy_to_cpu) {
    modify_field(multicast_metadata.multicast_bridge_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_bridge_hit, 1);
    modify_field(multicast_metadata.mcast_copy_to_cpu, copy_to_cpu);
}

action multicast_bridge_s_g_hit(mc_index, copy_to_cpu) {
    modify_field(multicast_metadata.multicast_bridge_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_bridge_hit, 1);
    modify_field(multicast_metadata.mcast_copy_to_cpu, copy_to_cpu);
}

action multicast_route_star_g_miss() {
  //    modify_field(l3_metadata.l3_copy, TRUE);
}

action multicast_route_sm_star_g_hit(mc_index, mcast_rpf_group, copy_to_cpu) {
    modify_field(multicast_metadata.mcast_mode, 1);
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_route_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);
    modify_field(multicast_metadata.mcast_copy_to_cpu, copy_to_cpu);
}

action multicast_route_bidir_star_g_hit(mc_index, mcast_rpf_group, copy_to_cpu) {
    modify_field(multicast_metadata.mcast_mode, 2);
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_route_hit, 1);

    bit_or(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
           multicast_metadata.bd_mrpf_group);



    modify_field(multicast_metadata.mcast_copy_to_cpu, copy_to_cpu);
}

action multicast_route_s_g_hit(mc_index, mcast_rpf_group, copy_to_cpu) {
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_mode, 1);
    modify_field(multicast_metadata.mcast_route_hit, 1);
    modify_field(multicast_metadata.mcast_route_s_g_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);
    modify_field(multicast_metadata.mcast_copy_to_cpu, copy_to_cpu);
}

action multicast_redirect_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
}
//#endif /* FWD_RESULTS_OPTIMIZATION_ENABLE */



/*****************************************************************************/
/* IPv4 multicast lookup                                                     */
/*****************************************************************************/
# 530 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_ipv4_multicast {
# 556 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* IPv6 multicast lookup                                                     */
/*****************************************************************************/
# 633 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
control process_ipv6_multicast {
# 658 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* IP multicast processing                                                   */
/*****************************************************************************/
control process_multicast {
# 675 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
}


/*****************************************************************************/
/* Multicast flooding                                                        */
/*****************************************************************************/
action set_bd_flood_mc_index(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
}

table bd_flood {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_pkt_type : exact;



    }
    actions {
        nop;
        set_bd_flood_mc_index;
    }
    size : 16384;
}

control process_multicast_flooding {

    apply(bd_flood);

}


/*****************************************************************************/
/* Multicast replication processing                                          */
/*****************************************************************************/
# 744 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
action inner_replica_from_rid(bd) {
  // Native -> Native OR Encap -> Native
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(multicast_metadata.replica, 1);



    modify_field(egress_metadata.routed, l3_metadata.routed);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
}

action unicast_replica_from_rid(outer_bd, dmac_idx) {
    modify_field(egress_metadata.outer_bd, outer_bd);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}

@pragma ignore_table_dependency mirror






table rid {
    reads {
        eg_intr_md.egress_rid : exact;
    }
    actions {
        nop;
# 784 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/multicast.p4"
    }
    size : 32768;
}

//#if !defined(L3_MULTICAST_DISABLE)
action set_replica_copy_bridged() {
    modify_field(egress_metadata.routed, 0);
}




table replica_type {
    reads {
        multicast_metadata.replica : exact;
        egress_metadata.same_bd_check : ternary;
    }
    actions {
        nop;
        set_replica_copy_bridged;
    }
    size : 512;
}

//#endif /* L3_MULTICAST_DISABLE */

/* We have to split replication processing into two control
blocks because we want rid and mirror table to be in
stage 0. But, the compiler does not do this when
rid, mcast_egress_rid and replica_type tables are
under the same gateway condition. process_rid should
be invoked before process_mirroring, and
process_replication should be invoked after */

control process_rid {


    if(eg_intr_md.egress_rid != 0) {
        /* set info from rid */
        apply(rid);
    }

}

control process_replication {






}

/*
 * PIM BIDIR DF check optimization description
 Assumption : Number of RPs in the network is X
 PIM_DF_CHECK_BITS : X

 For each RP, there is list of interfaces for which the switch is
 the designated forwarder.

 For example:
 RP1 : BD1, BD2, BD5
 RP2 : BD3, BD5
 ...
 RP16 : BD1, BD5

 RP1  is allocated value 0x0001
 RP2  is allocated value 0x0002
 ...
 RP16 is allocated value 0x8000

 With each BD, we store a bitmap of size PIM_DF_CHECK_BITS with all
 RPx that it belongs to set.

 BD1 : 0x8001 (1000 0000 0000 0001)
 BD2 : 0x0001 (0000 0000 0000 0001)
 BD3 : 0x0002 (0000 0000 0000 0010)
 BD5 : 0x8003 (1000 0000 0000 0011)

 With each (*,G) entry, we store the RP value.

 DF check : <RP value from (*,G) entry> & <mrpf group value from bd>
 If 0, rpf check fails.

 Eg, If (*,G) entry uses RP2, and packet comes in BD3 or BD5, then RPF
 check passes. If packet comes in any other interface, logical and
 operation will yield 0.
 */
# 172 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Nexthop related processing
 */

/*
 * nexthop metadata
 */

@pragma pa_no_overlay ingress nexthop_metadata.nexthop_type

header_type nexthop_metadata_t {
    fields {
        nexthop_type : 1; /* final next hop index type */
        nexthop_glean : 1; /* Glean adjacency */

        nexthop_offset : 8; /* Offset next group */

    }
}
# 54 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
metadata nexthop_metadata_t nexthop_metadata;

/*****************************************************************************/
/* Forwarding result lookup and decisions                                    */
/*****************************************************************************/


action set_l2_redirect() {
    modify_field(nexthop_metadata.nexthop_type, l2_metadata.l2_nexthop_type);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);
    modify_field(ingress_metadata.egress_port_lag_index, 0);



}

action set_l2_redirect_base() {
    modify_field(l3_metadata.nexthop_index, l2_metadata.l2_nexthop);
    set_l2_redirect();
}


action set_acl_redirect() {

    modify_field(nexthop_metadata.nexthop_type, acl_metadata.acl_nexthop_type);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);
    modify_field(ingress_metadata.egress_port_lag_index, 0);




}

action set_acl_redirect_base() {

    modify_field(l3_metadata.nexthop_index, acl_metadata.acl_nexthop);
    set_acl_redirect();

}

action set_racl_redirect() {
    modify_field(nexthop_metadata.nexthop_type, acl_metadata.racl_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);
    modify_field(ingress_metadata.egress_port_lag_index, 0);



}

action set_racl_redirect_base() {
    modify_field(l3_metadata.nexthop_index, acl_metadata.racl_nexthop);
    set_racl_redirect();
}

action set_fib_redirect() {
    modify_field(nexthop_metadata.nexthop_type, l3_metadata.fib_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_fib_redirect_base() {
    modify_field(l3_metadata.nexthop_index, l3_metadata.fib_nexthop);
    set_fib_redirect();
}

action set_nat_redirect() {
    modify_field(nexthop_metadata.nexthop_type, nat_metadata.nat_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_nat_redirect_base() {
    modify_field(l3_metadata.nexthop_index, nat_metadata.nat_nexthop);
    set_nat_redirect();
}


action set_l2_redirect_offset() {
    add(l3_metadata.nexthop_index, l2_metadata.l2_nexthop, nexthop_metadata.nexthop_offset);
    set_l2_redirect();
}

action set_acl_redirect_offset() {

    add(l3_metadata.nexthop_index, acl_metadata.acl_nexthop, nexthop_metadata.nexthop_offset);
    set_acl_redirect();

}

action set_racl_redirect_offset() {
    add(l3_metadata.nexthop_index, acl_metadata.racl_nexthop, nexthop_metadata.nexthop_offset);
    set_racl_redirect();
}

action set_fib_redirect_offset() {
    add(l3_metadata.nexthop_index, l3_metadata.fib_nexthop, nexthop_metadata.nexthop_offset);
    set_fib_redirect();
}

action set_nat_redirect_offset() {
    add(l3_metadata.nexthop_index, nat_metadata.nat_nexthop, nexthop_metadata.nexthop_offset);
    set_nat_redirect();
}


action set_cpu_redirect(cpu_ifindex) {
    modify_field(l3_metadata.routed, 0);
    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ingress_metadata.egress_port_lag_index, cpu_ifindex);



}

action set_rmac_non_ip_drop() {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, 94);
}

action set_multicast_route() {



    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ingress_metadata.egress_port_lag_index, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_route_mc_index);
    modify_field(l3_metadata.routed, 1);
    modify_field(l3_metadata.same_bd_check, 0xFFFF);
}

action set_multicast_rpf_fail_bridge() {



    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ingress_metadata.egress_port_lag_index, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_bridge_mc_index);
    modify_field(multicast_metadata.mcast_rpf_fail, 1);
}

action set_multicast_rpf_fail_flood_to_mrouters() {



    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
    modify_field(multicast_metadata.mcast_rpf_fail, 1);
    modify_field(multicast_metadata.flood_to_mrouters, 1);
}

action set_multicast_bridge() {



    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ingress_metadata.egress_port_lag_index, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_bridge_mc_index);
}

action set_multicast_rpf_fail_flood() {



    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
    modify_field(multicast_metadata.mcast_rpf_fail, 1);
}

action set_multicast_miss_flood() {



    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}

action set_multicast_drop() {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, 59);
}

action set_multicast_miss_flood_to_mrouters() {



    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
    modify_field(multicast_metadata.flood_to_mrouters, 1);
}

action set_cpu_tx_flood() {
    modify_field(ingress_metadata.egress_ifindex, 0x3FFF);
}




table fwd_result {
    reads {

        l2_metadata.l2_redirect : ternary;


        acl_metadata.acl_redirect : ternary;



        l3_metadata.rmac_hit : ternary;
        l3_metadata.fib_hit : ternary;



        l2_metadata.lkp_pkt_type : ternary;
        l3_metadata.lkp_ip_type : ternary;
# 289 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
        // only for ecmp group add

        l2_metadata.l2_nexthop_type : ternary;
        l3_metadata.fib_nexthop_type : ternary;
        acl_metadata.acl_nexthop_type : ternary;

        ingress_metadata.drop_flag : ternary;
        ingress_metadata.port_type : ternary;
        ingress_metadata.bypass_lookups : ternary;
    }
    actions {
        nop;

        set_l2_redirect_base;

        set_fib_redirect_base;
        set_cpu_redirect;
        set_acl_redirect_base;





        set_l2_redirect_offset;

        set_fib_redirect_offset;
        set_acl_redirect_offset;

 set_rmac_non_ip_drop;
# 331 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
        set_cpu_tx_flood;
    }
    size : 512;
}

control process_fwd_results {
    if (not((ingress_metadata.bypass_lookups == 0x3FFF))) {
        apply(fwd_result);
    }
}


/*****************************************************************************/
/* ECMP lookup                                                               */
/*****************************************************************************/

action select_ecmp_nexthop(port_lag_index, nhop_index) {
    modify_field(ingress_metadata.egress_port_lag_index, port_lag_index);
    modify_field(l3_metadata.nexthop_index, nhop_index);
}
# 402 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
action set_wcmp() {
}

field_list l3_hash_fields {







    hash_metadata.hash1;



}

field_list_calculation ecmp_hash {
    input {
        l3_hash_fields;
    }
# 436 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
    algorithm {
     identity;
 crc_16_dect;
    }
    output_width : 14;

}

action_selector ecmp_selector {
    selection_key : ecmp_hash;



    selection_mode : fair;

}

action_profile ecmp_action_profile {
    actions {

        select_ecmp_nexthop;
# 469 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
    }
    size : 131072;
    dynamic_action_selection : ecmp_selector;
}


@pragma selector_num_max_groups 4096

table ecmp_group {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    action_profile: ecmp_action_profile;
    size : 4096;
}

/*****************************************************************************/
/* WCMP lookup                                                               */
/*****************************************************************************/
# 509 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
/*****************************************************************************/
/* Nexthop lookup                                                            */
/*****************************************************************************/
/*
 * If dest mac is not know, then unicast packet needs to be flooded in
 * egress BD
 */
action set_nexthop_details_for_post_routed_flood(bd, uuc_mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, uuc_mc_index);
    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ingress_metadata.egress_port_lag_index, 0);

    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);




}

action set_nexthop_details_with_tunnel(bd, tunnel_dst_index, tunnel) {





    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);

    bit_and(ig_intr_md_for_tm.disable_ucast_cutthru, l2_metadata.non_ip_packet, 1);
    modify_field(tunnel_metadata.tunnel_dst_index, tunnel_dst_index);
    modify_field(ingress_metadata.egress_ifindex, 0x0);



}

action set_nexthop_details_for_glean(ifindex) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    modify_field(nexthop_metadata.nexthop_glean, 1);

    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, 0x3FFF);

}

action set_nexthop_details_for_drop() {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, 93);
}

action set_nexthop_details_for_redirect_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
}



action set_nexthop_details(ifindex, bd, tunnel) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);

    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);





}

table nexthop_details {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_nexthop_details;
        set_nexthop_details_with_tunnel;
        set_nexthop_details_for_post_routed_flood;



 set_nexthop_details_for_glean;

        set_nexthop_details_for_drop;
    }
    default_action: nop;
    size : 32768;
}

action set_nexthop_port_lag(port_lag_index) {
    modify_field(ingress_metadata.egress_port_lag_index, port_lag_index);
}

table nexthop {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_nexthop_port_lag;
    }
    default_action: nop;
    size : 32768;
}
# 648 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
register ttl_eval {
    width : 8;
    instance_count : 1;
}

 blackbox stateful_alu ttl_4 {
    reg : ttl_eval;
    condition_lo: ipv4.ttl >= 4;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value : 4;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: ipv4.ttl;
    output_predicate : 1;
    output_value : alu_lo;
    output_dst: ipv4.ttl;
}

action set_ttl_4() {
    ttl_4.execute_stateful_alu(0);
}

action ttl4_drop() {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, 96);
}

table ttl4_set {
    reads {
       ipv4.ttl : exact;
    }
    actions {
        nop; // do nothing
        set_ttl_4; // force TTL to 4, if >=4
        ttl4_drop; // drop for ttl < 4
    }
    default_action: nop;
    // set default action to set_ttl_4 to enable ttl4 processing
    // entries {0..3} => ttl4_drop (program from runtime)
    size : 64;
}


control process_nexthop {
    if (nexthop_metadata.nexthop_type == 1) {






        /* resolve ecmp */
# 707 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/nexthop.p4"
            apply(ecmp_group);


            if(valid(ipv4) and (nexthop_metadata.nexthop_offset != 0)) {
                apply(ttl4_set);
            }





    } else {
        /* resolve nexthop */
        apply(nexthop);
    }
}
# 173 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/rewrite.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Packet rewrite processing
 */


/*****************************************************************************/
/* Packet rewrite lookup and actions                                         */
/*****************************************************************************/

//-------------------------
# 98 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/rewrite.p4"
//-------------------------

action set_l2_rewrite_with_tunnel(tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 0);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);



    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);

}

action set_l2_rewrite_with_tunnel_dst_index(tunnel_index, tunnel_type, tunnel_dst_index) {
    modify_field(egress_metadata.routed, 0);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);



    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);

    modify_field(tunnel_metadata.tunnel_dst_index, tunnel_dst_index);
}

action set_l2_rewrite() {
    modify_field(egress_metadata.routed, 0);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(egress_metadata.outer_bd, ingress_metadata.bd);
}

action set_l3_rewrite_with_tunnel_vnid(bd, dmac, tunnel_index, tunnel_type, vnid) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd); // bd of default vrf 1
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);



    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);

    modify_field(tunnel_metadata.vnid, vnid);
}

action set_l3_rewrite_with_tunnel(bd, dmac, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);



    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);

}

action set_l3_rewrite_with_tunnel_and_ingress_vrf(dmac, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, l3_metadata.vrf);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);



    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);

}

action set_l3_rewrite(bd, dmac) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
}
# 262 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/rewrite.p4"
table rewrite {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_l2_rewrite;
# 279 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/rewrite.p4"
        set_l3_rewrite;
# 294 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/rewrite.p4"
    }

    size : 32768;



}

control process_rewrite {

  apply(rewrite);






}

//-------------------------

//-------------------------
# 174 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/security.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Security related processing - Storm control, IPSG, etc.
 */

/*
 * security metadata
 */
# 43 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/security.p4"
/*****************************************************************************/
/* Storm control                                                             */
/*****************************************************************************/

counter storm_control_stats {
    type : packets;
    direct : storm_control_stats;
}

table storm_control_stats {
    reads {
        meter_metadata.storm_control_color: exact;
        l2_metadata.lkp_pkt_type : ternary;
        ig_intr_md.ingress_port: exact;
        l2_metadata.l2_dst_miss : ternary;
    }
    actions {
        nop;
    }
    size: 1024;
}


meter storm_control_meter {
    type : bytes;
    static : storm_control;
    result : meter_metadata.storm_control_color;
    instance_count : 512;
}

action set_storm_control_meter(meter_idx) {
    execute_meter(storm_control_meter, meter_idx,
                  meter_metadata.storm_control_color);
}

table storm_control {
    reads {
        ig_intr_md.ingress_port : exact;
        l2_metadata.lkp_pkt_type : ternary;
        l2_metadata.l2_dst_miss : ternary;
    }
    actions {
        nop;
        set_storm_control_meter;
    }
    size : 512;
}


control process_storm_control {

    if (ingress_metadata.port_type == 0) {
        apply(storm_control);
    }

}

control process_storm_control_stats {


    apply(storm_control_stats);


}
# 143 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/security.p4"
control process_ip_sourceguard {
# 155 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/security.p4"
}
# 175 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Fabric processing for multi-device system
 */


header_type fabric_metadata_t {
    fields {
        packetType : 3;
        fabric_header_present : 1;
        reason_code : 16; /* cpu reason code */





    }
}
# 50 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
@pragma pa_solitary ingress fabric_metadata.reason_code
metadata fabric_metadata_t fabric_metadata;

/*****************************************************************************/
/* Fabric header - destination lookup                                        */
/*****************************************************************************/
action terminate_cpu_packet() {




    modify_field(ig_intr_md_for_tm.ucast_egress_port,
                 fabric_header.dstPortOrGroup);

    modify_field(egress_metadata.bypass, fabric_header_cpu.txBypass);
# 74 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
    modify_field(ethernet.etherType, fabric_payload_header.etherType);

    remove_header(fabric_header);

    remove_header(fabric_header_cpu);
    remove_header(fabric_payload_header);
}
# 171 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
@pragma ternary 1
table fabric_ingress_dst_lkp {

    reads {
        fabric_header.dstDevice : exact;



    }

    actions {

        nop;

        terminate_cpu_packet;
# 197 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
    }
}

/*****************************************************************************/
/* Fabric header - source lookup                                             */
/*****************************************************************************/
# 220 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
action non_ip_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
}

action ipv4_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv4.protocol);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
}

action ipv6_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv6_metadata.lkp_ipv6_sa, ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
}

table native_packet_over_fabric {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_over_fabric;
        ipv4_over_fabric;

        ipv6_over_fabric;

    }
    size : 1024;
}

action rewrite_l2_exclusion_id(exclusion_id, rid) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, rid);
}

table l2_exclusion_id_rewrite {
    reads {
        fabric_header_cpu.ingressPort : exact;
    }
    actions {
      rewrite_l2_exclusion_id;
    }
    size : 512;
}

control process_cpu_packet {






}

/*****************************************************************************/
/* Ingress fabric header processing                                          */
/*****************************************************************************/
control process_ingress_fabric {
    if (ingress_metadata.port_type != 0) {
        apply(fabric_ingress_dst_lkp);
# 301 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
    }
}

/*****************************************************************************/
/* Fabric LAG resolution                                                     */
/*****************************************************************************/
# 368 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
control process_fabric_lag {



}


/*****************************************************************************/
/* Fabric rewrite actions                                                    */
/*****************************************************************************/
action cpu_rx_rewrite() {
# 393 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/fabric.p4"
    add_header(fabric_header);
    modify_field(fabric_header.headerVersion, 0);
    modify_field(fabric_header.packetVersion, 0);
    modify_field(fabric_header.mcast, 0);
    modify_field(fabric_header.packetType, 5);
    add_header(fabric_header_cpu);
    modify_field(fabric_header_cpu.ingressPort, ingress_metadata.ingress_port);
    modify_field(fabric_header_cpu.ingressIfindex, ingress_metadata.ifindex);
    modify_field(fabric_header_cpu.ingressBd, ingress_metadata.bd);
    modify_field(fabric_header_cpu.reasonCode, fabric_metadata.reason_code);







    add_header(fabric_payload_header);
    modify_field(fabric_payload_header.etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x9000);
}

action fabric_rewrite(tunnel_index) {
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
}
# 176 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/egress_filter.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Egress filtering logic, used only in open source version.
 */
/*****************************************************************************/
/* Egress filtering logic                                                    */
/*****************************************************************************/
# 68 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/egress_filter.p4"
control process_egress_filter {
# 83 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/egress_filter.p4"
}
# 177 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/mirror.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Mirror processing
 */

action set_mirror_bd(bd, session_id, queue_id) {
    modify_field(egress_metadata.bd, bd);
    modify_field(i2e_metadata.mirror_session_id, session_id);

    modify_field(ig_intr_md_for_tm.qid, queue_id);

}

action set_mirror_q(queue_id) {
    modify_field(ig_intr_md_for_tm.qid, queue_id);
}

action f_insert_erspan_common_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(gre);
    add_header(erspan_t3_header);
    modify_field(gre.C, 0);
    modify_field(gre.R, 0);
    modify_field(gre.K, 0);
    modify_field(gre.S, 0);
    modify_field(gre.s, 0);
    modify_field(gre.recurse, 0);
    modify_field(gre.flags, 0);
    modify_field(gre.ver, 0);
    modify_field(gre.proto, 0x22EB);

    modify_field(erspan_t3_header.timestamp, i2e_metadata.ingress_tstamp);

    modify_field(erspan_t3_header.priority_span_id, i2e_metadata.mirror_session_id);
    modify_field(erspan_t3_header.version, 2);
    modify_field(erspan_t3_header.vlan, 0);
}

action f_insert_erspan_t3_header() {
    f_insert_erspan_common_header();
    modify_field(erspan_t3_header.ft_d_other, 0);
}

action f_insert_ipv4_erspan_t3_header(sip, dip, tos, ttl) {
    f_insert_erspan_t3_header();
    add_header(ipv4);
    modify_field(ipv4.protocol, 47);
    modify_field(ipv4.ttl, ttl);
    modify_field(ipv4.version, 0x4);
    modify_field(ipv4.ihl, 0x5);
    modify_field(ipv4.identification, 0);
    modify_field(ipv4.flags, 0x2);
    modify_field(ipv4.diffserv, tos);
    // IPv4 (20) + GRE (4) + Erspan (12)
    add(ipv4.totalLen, eg_intr_md.pkt_length, 36);
    modify_field(ipv4.srcAddr, sip);
    modify_field(ipv4.dstAddr, dip);
}


action ipv4_erspan_t3_rewrite_with_eth_hdr(smac, dmac, sip, dip, tos, ttl, queue_id) {
    f_insert_ipv4_erspan_t3_header(sip, dip, tos, ttl);
    modify_field(ethernet.etherType, 0x0800);
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, dmac);

    modify_field(ig_intr_md_for_tm.qid, queue_id);

}

action ipv4_erspan_t3_rewrite_with_eth_hdr_and_vlan_tag(smac, dmac, sip, dip, tos, ttl, vlan_tpid, vlan_id, cos, queue_id) {
    f_insert_ipv4_erspan_t3_header(sip, dip, tos, ttl);
    add_header(vlan_tag_[0]);
    modify_field(ethernet.etherType, vlan_tpid);
    modify_field(vlan_tag_[0].etherType, 0x0800);
    modify_field(vlan_tag_[0].vid, vlan_id);
    modify_field(vlan_tag_[0].pcp, cos);
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, dmac);

    modify_field(ig_intr_md_for_tm.qid, queue_id);

}
# 156 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/mirror.p4"
@pragma ignore_table_dependency rid
@pragma egress_pkt_length_stage 0



table mirror {
    reads {
        i2e_metadata.mirror_session_id : exact;
    }
    actions {
        nop;
        set_mirror_bd;

        ipv4_erspan_t3_rewrite_with_eth_hdr;
        ipv4_erspan_t3_rewrite_with_eth_hdr_and_vlan_tag;
# 181 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/mirror.p4"
//Used for local mirror

        set_mirror_q;

    }
    size : 1024;
}

control process_mirroring {

    apply(mirror);

}

/*****************************************************************************/
/* Ingress Port Mirroring                                                    */
/*****************************************************************************/

action set_ingress_port_mirror_index(session_id) {
  modify_field(i2e_metadata.mirror_session_id, session_id);
  clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);
}






table ingress_port_mirror {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {
    set_ingress_port_mirror_index;
    nop;
  }
  size: 290;
}

control process_ingress_port_mirroring {
  apply(ingress_port_mirror);
}

/*****************************************************************************/
/* Egress Port Mirroring                                                     */
/*****************************************************************************/

action set_egress_port_mirror_index(session_id) {
  modify_field(i2e_metadata.mirror_session_id, session_id);
  clone_egress_pkt_to_egress(session_id, e2e_mirror_info);
}






table egress_port_mirror {
  reads {
    eg_intr_md.egress_port : exact;
  }
  actions {
    set_egress_port_mirror_index;
    nop;
  }
  size: 290;
}

control process_egress_port_mirroring {
  apply(egress_port_mirror);
}
# 178 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*****************************************************************************/
/* HASH calculation                                                          */
/*****************************************************************************/
header_type hash_metadata_t {
    fields {




        hash1 : 16;
        hash2 : 16;

        entropy_hash : 16;
    }
}

@pragma pa_atomic ingress hash_metadata.hash1
@pragma pa_solitary ingress hash_metadata.hash1
@pragma pa_atomic ingress hash_metadata.hash2
@pragma pa_solitary ingress hash_metadata.hash2
metadata hash_metadata_t hash_metadata;
# 53 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
@pragma all_fields_optional
field_list lkp_ipv4_hash1_fields {
    ipv4_metadata.lkp_ipv4_sa;
    ipv4_metadata.lkp_ipv4_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

@pragma all_fields_optional
field_list lkp_inner_ipv4_hash1_fields {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    l3_metadata.lkp_inner_l4_dport;
    l3_metadata.lkp_inner_l4_sport;
}


// UNUSED
//field_list lkp_ipv4_hash2_fields {
//    l2_metadata.lkp_mac_sa;
//    l2_metadata.lkp_mac_da;
//    ipv4_metadata.lkp_ipv4_sa;
//    ipv4_metadata.lkp_ipv4_da;
//    l3_metadata.lkp_ip_proto;
//    l3_metadata.lkp_l4_sport;
//    l3_metadata.lkp_l4_dport;
//}

field_list_calculation lkp_ipv4_hash1 {
    input {
        lkp_ipv4_hash1_fields;
   }
# 97 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }




    output_width : 16;

}

field_list_calculation lkp_inner_ipv4_hash1 {
    input {
        lkp_inner_ipv4_hash1_fields;
   }
# 126 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }




    output_width : 16;

}


// UNUSED
//field_list_calculation lkp_ipv4_hash2 {
//    input {
//        lkp_ipv4_hash2_fields;
//    }
//#if defined(BMV2) && defined(INT_ENABLE)
//    algorithm : crc16_custom;
//#else
//    algorithm : crc16;
//#endif
//    output_width : 16;
//}

action compute_lkp_ipv4_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_ipv4_hash1, 65536);

}

action compute_lkp_inner_ipv4_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_inner_ipv4_hash1, 65536);

}


@pragma all_fields_optional
field_list lkp_ipv6_hash1_fields {
    ipv6_metadata.lkp_ipv6_sa;
    ipv6_metadata.lkp_ipv6_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;



}

@pragma all_fields_optional
field_list lkp_inner_ipv6_hash1_fields {
    inner_ipv6.srcAddr;
    inner_ipv6.dstAddr;
    inner_ipv6.nextHdr;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;



}
// UNUSED
//field_list lkp_ipv6_hash2_fields {
//    l2_metadata.lkp_mac_sa;
//    l2_metadata.lkp_mac_da;
//    ipv6_metadata.lkp_ipv6_sa;
//    ipv6_metadata.lkp_ipv6_da;
//    l3_metadata.lkp_ip_proto;
//    l3_metadata.lkp_l4_sport;
//    l3_metadata.lkp_l4_dport;
//}

field_list_calculation lkp_ipv6_hash1 {
    input {
        lkp_ipv6_hash1_fields;
    }
# 224 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }




    output_width : 16;

}

field_list_calculation lkp_inner_ipv6_hash1 {
    input {
        lkp_inner_ipv6_hash1_fields;
    }
# 253 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }




    output_width : 16;

}

// UNUSED
//field_list_calculation lkp_ipv6_hash2 {
//    input {
//        lkp_ipv6_hash2_fields;
//    }
//#if defined(BMV2) && defined(INT_ENABLE)
//    algorithm : crc16_custom;
//#else
//    algorithm : crc16;
//#endif
//    output_width : 16;
//}

action compute_lkp_ipv6_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_ipv6_hash1, 65536);

}

action compute_lkp_inner_ipv6_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_inner_ipv6_hash1, 65536);

}

@pragma all_fields_optional
field_list lkp_non_ip_hash1_fields {

    ingress_metadata.ifindex;

    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
}

@pragma all_fields_optional
field_list inner_ethernet_hash1_fields {

    tunnel_metadata.tunnel_vni;

    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ethernet.etherType;
}

field_list_calculation lkp_non_ip_hash1 {
    input {
        lkp_non_ip_hash1_fields;
    }
# 334 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }
    output_width : 16;

}

field_list_calculation inner_ethernet_hash1 {
    input {
        inner_ethernet_hash1_fields;
    }
# 358 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    algorithm {
        crc16;
 crc_16_dect;
 crc_16_genibus;
 crc_16_dnp;
 crc_16_teledisk;
    }
    output_width : 16;

}

action compute_lkp_non_ip_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_non_ip_hash1, 65536);

}

action compute_inner_ethernet_hash() {




    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        inner_ethernet_hash1, 65536);

}




table compute_ipv4_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_ipv4_hash;
    }



}

table compute_inner_ipv4_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_inner_ipv4_hash;
    }



}

table compute_inner_ipv6_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_inner_ipv6_hash;
    }



}

table compute_ipv6_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_ipv6_hash;
    }



}







table compute_non_ip_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_non_ip_hash;
    }



}

table compute_inner_ethernet_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_inner_ethernet_hash;
    }



}

action compute_other_hashes() {
    shift_right(hash_metadata.hash2, hash_metadata.hash1, 2);

    modify_field(ig_intr_md_for_tm.level1_mcast_hash, hash_metadata.hash1);

    shift_right(ig_intr_md_for_tm.level2_mcast_hash, hash_metadata.hash1, 3);
    modify_field(hash_metadata.entropy_hash, hash_metadata.hash1);
}


@pragma ternary 1




table compute_other_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_other_hashes;
    }



}

control process_hashes_1 {
# 557 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/hashes.p4"
    if (((tunnel_metadata.tunnel_terminate == 0) and valid(ipv4)) or
        ((tunnel_metadata.tunnel_terminate == 1) and valid(inner_ipv4))) {
        apply(compute_ipv4_hashes);
    } else


    if (((tunnel_metadata.tunnel_terminate == 0) and valid(ipv6)) or
         ((tunnel_metadata.tunnel_terminate == 1) and valid(inner_ipv6))) {
        apply(compute_ipv6_hashes);
    } else

    {

        apply(compute_non_ip_hashes);

    }

}

control process_hashes_2 {
    apply(compute_other_hashes);
}
# 179 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/meter.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Meter processing
 */

/*
 * Meter metadata
 */
 header_type meter_metadata_t {
     fields {
         storm_control_color : 2;
         qos_meter_color : 2;
         packet_color : 2; /* packet color */



         meter_index : 16; /* meter index */
         egress_meter_index : 16; /* meter index */
         egress_meter_drop : 1; /* egress meter drop */
         egress_meter_packet_color : 2; /* packet color */
     }
 }

metadata meter_metadata_t meter_metadata;
# 90 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/meter.p4"
/*****************************************************************************/
/* Meters                                                                    */
/*****************************************************************************/
# 141 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/meter.p4"
control process_meter_index {





}

control process_meter_action {





}

control process_egress_meter_index {





}

control process_egress_meter_action {





}
# 180 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/sflow.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Sflow processing
 */
# 44 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/sflow.p4"
/* ---------------------- sflow ingress processing ------------------------ */
# 89 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/sflow.p4"
control process_ingress_sflow {



}


/* ----- egress processing ----- */
# 181 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/bfd.p4" 1
# 487 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/bfd.p4"
/* stubs when bfd offload is not enabled */
control process_bfd_mirror_to_cpu {
}
control process_egress_bfd_packet {
}
control process_egress_bfd_tx_timers {
}
control process_bfd_packet {
}
control process_bfd_rx_packet {
}
control process_bfd_tx_packet {
}
control process_bfd_recirc {
}
# 182 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4" 1

/*****************************************************************************/
/* Qos Processing                                                            */
/*****************************************************************************/

header_type qos_metadata_t {
    fields {
        ingress_qos_group: 5;
        tc_qos_group: 5;
        egress_qos_group: 5;





        lkp_tc: 8;

        trust_dscp: 1;
        trust_pcp: 1;
    }
}

metadata qos_metadata_t qos_metadata;
# 40 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4"
/*****************************************************************************/
/* Ingress QOS Map                                                           */
/*****************************************************************************/
# 52 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4"
action set_ingress_tc_and_color(tc, color) {
    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(ig_intr_md_for_tm.packet_color, color);
}

action set_ingress_tc(tc) {
    modify_field(qos_metadata.lkp_tc, tc);
}

action set_ingress_color(color) {
  modify_field(ig_intr_md_for_tm.packet_color, color);
}

table ingress_qos_map_dscp {
    reads {
        qos_metadata.ingress_qos_group: ternary;
        l3_metadata.lkp_dscp: ternary;
    }

    actions {
        nop; set_ingress_tc; set_ingress_color; set_ingress_tc_and_color;
    }

    size: 512;
}

table ingress_qos_map_pcp {
    reads {
        qos_metadata.ingress_qos_group: ternary;
        l2_metadata.lkp_pcp: ternary;
    }

    actions {
        nop; set_ingress_tc; set_ingress_color; set_ingress_tc_and_color;
    }

    size: 512;
}
# 127 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4"
control process_ingress_qos_map {
    if (((ingress_metadata.bypass_lookups & 0x0008) == 0)) {
# 141 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4"
      if ((qos_metadata.trust_dscp == 1) and (l3_metadata.lkp_ip_type != 0)) {
        apply(ingress_qos_map_dscp);
      } else if ((qos_metadata.trust_pcp == 1) and ((valid(vlan_tag_[0])) or (ingress_metadata.port_type == 2))) {
        apply(ingress_qos_map_pcp);
      }




    }
}


/*****************************************************************************/
/* Queuing                                                                   */
/*****************************************************************************/


action set_icos(icos) {
    modify_field(ig_intr_md_for_tm.ingress_cos, icos);
}

action set_queue(qid) {
    modify_field(ig_intr_md_for_tm.qid, qid);
}

action set_icos_and_queue(icos, qid) {
    modify_field(ig_intr_md_for_tm.ingress_cos, icos);
    modify_field(ig_intr_md_for_tm.qid, qid);
}

table traffic_class {
    reads {



        qos_metadata.lkp_tc: ternary;



    }

    actions {
        nop;
        set_icos;
        set_queue;
        set_icos_and_queue;
    }
    size: 512;
}


control process_traffic_class{

    apply(traffic_class);

}

/*****************************************************************************/
/* Egress QOS Map                                                            */
/*****************************************************************************/
# 260 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/qos.p4"
control process_egress_qos_map {





}

/*****************************************************************************/
/* Egress Queue Stats                                                        */
/*****************************************************************************/
counter egress_queue_stats {
    type : packets_and_bytes;
    direct : egress_queue_stats;
}

table egress_queue_stats {
    reads {
        eg_intr_md.egress_port : exact;
        ig_intr_md_for_tm.qid : exact ;
    }
    actions {
        nop;
    }
    default_action: nop();
    size : 2560;
}

control process_egress_queue_stats {

  /* Note : This logic doesn't take care of packets dropped or sent to cpu by egress system acl */
  apply(egress_queue_stats);

}

/*****************************************************************************/
/* Ingress PPG Stats                                                        */
/*****************************************************************************/
counter ingress_ppg_stats {
    type : packets_and_bytes;
    direct : ingress_ppg_stats;
}

table ingress_ppg_stats {
    reads {
        ingress_metadata.ingress_port : exact;
        ig_intr_md_for_tm.ingress_cos : exact ;
    }
    actions {
        nop;
    }
    default_action: nop();
    size : 4096;
}

control process_ingress_ppg_stats {

  /* Note : This logic doesn't take care of packets dropped or sent to cpu by system acl */
  apply(ingress_ppg_stats);

}
# 183 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/sr.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Segment routing processing
 */
# 345 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/sr.p4"
//
//
//control process_srv6_rewrite {
//#ifdef SRV6_ENABLE
//  //    apply(process_srh_len);
//  //    apply(srv6_rewrite);
//#endif /* SRV6_ENABLE */
//}
//
//control process_srv6 {
//#ifdef SRV6_ENABLE
//    if (valid(ipv6)) {
//        apply(srv6_sid);
//    }
//#endif /* SRV6_ENABLE */
//}
# 184 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/flowlet.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Flowlet related processing
 */

# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/flowlet_bmv2.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/

/*
 * Flowlet related processing for BMv2
 */
# 29 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/flowlet.p4" 2


/*
 * flowlet metadata
 */

// This is an arbitrary large prime number to make sure enough number of bits
// in flowlet-id will be changed and hence, CRC16 hash value have enough
// entropy to pick all memebers of a ECMP/LAG group.



header_type flowlet_metadata_t {
    fields {
        id : 16; /* flowlet id */
        enable : 1;
    }
}

metadata flowlet_metadata_t flowlet_metadata;

register flowlet_state {
    width : 64;
    instance_count : 8192;
}

blackbox stateful_alu flowlet_alu {
    reg : flowlet_state;
    initial_register_hi_value : 0;
    initial_register_lo_value : 0;
    //TODO inactivity_tout should be configurable.
    // (global_ts - flowlet_lastseen) > inactivity_tout
    condition_lo : i2e_metadata.ingress_tstamp - register_lo > 1;
    update_lo_2_value : i2e_metadata.ingress_tstamp;
    update_hi_1_value : register_hi + 997;
    update_hi_1_predicate: condition_lo;
    update_hi_2_value : register_hi;
    update_hi_2_predicate: not condition_lo;
    output_value : alu_hi;
    output_dst : flowlet_metadata.id;
}

action flowlet_lookup() {
    flowlet_alu.execute_stateful_alu_from_hash(flowlet_hash);
}


field_list flowlet_hash_fields {
    hash_metadata.hash1;
}

field_list_calculation flowlet_hash {
    input {
        flowlet_hash_fields;
    }
    algorithm : identity;
    output_width : 13;
}

table flowlet {
    actions {
        flowlet_lookup;
    }
    default_action : flowlet_lookup;
    size : 1;
}

control process_flowlet {
# 108 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/flowlet.p4"
}
# 185 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/pktgen.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/

/*
 * pktgen processing
 */

control process_pktgen {
# 46 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/pktgen.p4"
}
# 186 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/failover.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Fast failover processing
 */
# 185 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/failover.p4"
control process_pktgen_port_down {



}

control process_pktgen_nhop_down {



}

control process_lag_fallback {





}
# 187 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/ila.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
# 188 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/wred.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * WRED processing
 */


header_type wred_metadata_t {
    fields {
        drop_flag : 1;
        index : 8;
        stats_index : 13;
    }
}







metadata wred_metadata_t wred_metadata;

/*****************************************************************************/
/* Ingress Classification                                                    */
/*****************************************************************************/

action set_ingress_tc_and_color_for_ecn(tc, color) {
    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(ig_intr_md_for_tm.packet_color, color);
}

table ecn_acl {
  reads {
        acl_metadata.port_lag_label : ternary;
        l3_metadata.lkp_dscp: ternary;
        tcp.flags : ternary;
  }
  actions {
    nop;
    set_ingress_tc_and_color_for_ecn;
  }
 size : 512;
}


control process_ecn_acl {

  apply(ecn_acl);

}


/*****************************************************************************/
/* Egress ECN Marking                                                        */
/*****************************************************************************/

blackbox wred wred_early_drop {
    wred_input : eg_intr_md.deq_qdepth;
    static : wred_index;
    instance_count : 512;
    drop_value: 1;
    no_drop_value: 0;
}

/*
 *  +-----+-----+
 *  | ECN FIELD |
 *  +-----+-----+
 *    ECT   CE
 *    0     0         Not-ECT
 *    0     1         ECT(1)
 *    1     0         ECT(0)
 *    1     1         CE
 */


action set_ipv4_ecn_bits() {
    modify_field(wred_metadata.drop_flag, 0);
    modify_field(ipv4.diffserv, 0x3, 0x03);
}

action set_ipv6_ecn_bits() {
    modify_field(wred_metadata.drop_flag, 0);
    modify_field(ipv6.trafficClass, 0x3, 0x03);
}

action wred_drop() {
    modify_field(wred_metadata.drop_flag, 1);
    drop();
}

action wred_nop() {
    //Reset the wred stats index for nop case
    modify_field(wred_metadata.stats_index, 0);
}

action wred_set_index(index, stats_index) {
    wred_early_drop.execute(wred_metadata.drop_flag, index);
    modify_field(wred_metadata.index, index);
    modify_field(wred_metadata.stats_index, stats_index);
}




table wred_action {
    reads {
        wred_metadata.index : exact;
        wred_metadata.drop_flag : exact;
        ipv4.diffserv mask 0x03 : ternary;

        ipv6.trafficClass mask 0x03 : ternary;

        ipv4.valid : ternary;
        ipv6.valid : ternary;
    }

    actions {
        wred_nop;
        wred_drop;

        set_ipv6_ecn_bits;

        set_ipv4_ecn_bits;
    }
    size : 1536;
}

counter wred_stats {
  type : packets_and_bytes;
  direct: wred_mark_drop_stats;
  min_width : 32;
}

table wred_mark_drop_stats {
  reads {
    wred_metadata.stats_index: exact;

    wred_metadata.drop_flag: exact;

  }
  actions {
    nop;
  }
  size : 8192;
}




table wred_index {
    reads {
        ig_intr_md_for_tm.qid : exact;
        eg_intr_md.egress_port : exact;
        ig_intr_md_for_tm.packet_color : exact;
    }
    actions {
        wred_set_index;
    }
    size : 4096;
}


control process_wred {

    apply(wred_index);
    apply(wred_action);

}

control process_wred_stats {

    apply(wred_mark_drop_stats);

}
# 189 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/

/*
 * DTel code shared by INT, Postcard, Mirror on Drop (Drop Report) and Queue Report
 */
# 71 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
header_type dtel_metadata_t {
    fields {
        // flow hash for mirror load balancing and flow state change detection
        flow_hash : 32;

        // mirror id for mirror load balancing
        mirror_session_id : 10;

        // quantized latency for flow state change detection
        quantized_latency : 32;

        // local digest at egress pipe for flow state change detection
        local_digest : 16;

        // encodes 2 bit information for flow state change detection
        // MSB = 1 if old == 0 in any filter --> new flow.
        // LSB = 1 if new == old in any filter --> no value change
        // suppress report if bfilter_output == 1 (MSB == 0 and LSB == 1).
        bfilter_output : 2;

        // indicates if queue latency and/or depth exceed thresholds
        queue_alert : 1;

        // common index for port-qid tuple for queue report tables
        queue_alert_index : 10;

        // for regular egress indicates if queue latency and/or depth changed
        queue_change : 1;

        // is 1 if we can still send more queue_report packets that have not changes
        queue_report_quota : 1;

        // True if hit Mirror on Drop watchlist with watch action
        // higher bit is set if DoD is requested in the watchlist
        mod_watchlist_hit : 2;

        // True if queue-based deflect on drop is enabled
        queue_dod_enable : 1;

        // At ingress and egress for not mirrored packets, true if drop reports
        // are to be suppressed on a per flow basis (from drop watchlist). At
        // egress for mirrored packets, after mirror_on_drop_encap table, value
        // indicates whether this specific report packet should be dropped.
        drop_flow_suppress : 1;

        // Upper 6 bits represent the dscp of report packets
        // Lower 2 bits can be used to pass control from ingress to egress
        dscp_report : 8;
    }
}






// queue_alert is input to SALU, put it solitary and 8bit container to save hash bits
@pragma pa_solitary egress dtel_md.queue_alert



@pragma pa_container_size egress dtel_md.queue_alert 8

// Workaround for COMPILER-844
# 154 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
metadata dtel_metadata_t dtel_md;

/*******************************************************************************
 Control blocks exposed to switch.p4
 ******************************************************************************/
control process_dtel_ingress_prepare {





}

control process_dtel_watchlist {
# 186 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
}

control process_dtel_mod_watchlist {



}

control process_dtel_queue_watchlist {
// must be after egress port and qid are resolved





}

control process_dtel_prepare_egress {
# 218 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
}

control process_dtel_deflect_on_drop {
# 230 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
}

control process_dtel_queue_alert_update {



}

control process_dtel_local_report2 {
    // run only for not mirrored packets
    // separated from report1 to break the table dependency chain
# 251 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
    // defined in dtel_int.p4 and dtel_postcard.p4



}

control process_dtel_local_report1 {
    // run only for not mirrored packets
# 271 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
}

control process_dtel_local_report3 {



}

control process_dtel_drop_suppress_prepare {



}

control process_dtel_insert {
// run only for not mirrored packets




}

control process_dtel_port_convert {
// run only for mirrored packets
// convert h/w port to front panel port for DTel mirror packets
// ifdefs are to apply the code only when we are sure that
// the mirror copy is for dtel
# 338 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
       // DTEL_DROP_REPORT_ENABLE || DTEL_QUEUE_REPORT_ENABLE
}

control process_dtel_report_encap {
// run only for mirrored packets
// must happen after process_tunnel_encap_outer
# 364 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
    process_dtel_report_header_update();

}

control process_dtel_report_header_update {
# 378 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
}

control process_dtel_record_egress_port {







}

/*******************************************************************************
 Common logic for dtel_report_header
 ******************************************************************************/
# 419 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
/*******************************************************************************
 Record egress port
 ******************************************************************************/
# 464 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
/*******************************************************************************
 Switch h/w port to front panel port conversion
 ******************************************************************************/

action ig_port_convert(port) {
// assume DTel mirror packet will not be copied to CPU by egress_system_acl
    modify_field(ingress_metadata.ingress_port, port);
}


// dtel_ig_port_convert runs for mirror copy,
// others run for not a mirror copy
@pragma ignore_table_dependency int_transit_qalert
@pragma ignore_table_dependency dtel_postcard_e2e
@pragma ignore_table_dependency int_sink_local_report

@pragma ternary 1





table dtel_ig_port_convert {
    reads {
        ingress_metadata.ingress_port : exact;
    }
    actions {
        ig_port_convert;
        nop;
    }
    size: 290;
}

action eg_port_convert(port) {
    modify_field(egress_metadata.egress_port, port);
}

// dtel_eg_port_convert runs for mirror copy,
// others run for not a mirror copy
@pragma ignore_table_dependency int_transit_qalert
@pragma ignore_table_dependency dtel_postcard_e2e
@pragma ignore_table_dependency int_sink_local_report

@pragma ternary 1




table dtel_eg_port_convert {
    reads {
        egress_metadata.egress_port : exact;
    }
    actions {
        eg_port_convert;
        nop;
    }
    size: 290;
}

/*******************************************************************************
 Mirror on Drop
 ******************************************************************************/
# 722 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
/*******************************************************************************
 DTel flow hash
******************************************************************************/

field_list dtel_flow_hash_fields_outer {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;




    l3_metadata.lkp_outer_l4_sport;
    l3_metadata.lkp_outer_l4_dport;

}

field_list dtel_flow_hash_fields_inner {
    lkp_ipv4_hash1_fields;



}

field_list_calculation dtel_flow_hash_outer_calc {
    input { dtel_flow_hash_fields_outer; }
    algorithm : crc32_msb;
    output_width : 32;
}

field_list_calculation dtel_flow_hash_inner_calc {
    input { dtel_flow_hash_fields_inner; }
    algorithm : crc32_lsb;
    output_width : 32;
}

action compute_flow_hash_outer() {
    modify_field_with_hash_based_offset(
        dtel_md.flow_hash, 0,
        dtel_flow_hash_outer_calc, 4294967296);
}

action compute_flow_hash_inner() {
    modify_field_with_hash_based_offset(
        dtel_md.flow_hash, 0,
        dtel_flow_hash_inner_calc, 4294967296);
}




table dtel_flow_hash_outer {
    actions { compute_flow_hash_outer; }
    default_action : compute_flow_hash_outer;
}

// run before adjust_lkp table as it changes the fields that dtel_flow_hash_inner needs
table dtel_flow_hash_inner {
    actions { compute_flow_hash_inner; }
    default_action : compute_flow_hash_inner;
}



field_list dtel_flow_hash_field {
    dtel_md.flow_hash;
}

field_list dtel_flow_eg_hash_fields {
    dtel_md.flow_hash;

    eg_intr_md.egress_rid;

}

/*******************************************************************************
 DTel mirror session selection
 ******************************************************************************/

field_list dtel_session_selection_hash_fields {
    hash_metadata.hash1;
}

field_list_calculation session_selection_hash {
    input {
        dtel_session_selection_hash_fields;
    }
    algorithm : crc16;
    output_width : 14;
}

action_selector dtel_session_selector {
    selection_key : session_selection_hash;
    selection_mode : fair;
}

action set_mirror_session(mirror_id) {
    modify_field(dtel_md.mirror_session_id, mirror_id);
}

action_profile dtel_selector_action_profile {
    actions {
        nop;
        set_mirror_session;
    }
    size : 120;
    dynamic_action_selection : dtel_session_selector;
}




table dtel_mirror_session {
    reads { ethernet: valid; }
    action_profile: dtel_selector_action_profile;
    //size : DTEL_MAX_SESSION_GROUP;
    size: 2;
}

/*******************************************************************************
 Latency calculation table and actions
 ******************************************************************************/
# 883 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
/*******************************************************************************
 Queue latency and depth threshold detection
 ******************************************************************************/
# 1107 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel.p4"
/*******************************************************************************
 Stateful flow state change detection
 ******************************************************************************/
# 190 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_int.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
# 59 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_int.p4"
/*******************************************************************************
 INT tables for ingress pipeline
 Identify role (source, transit, or sink)
    sink is set by int_set_sink table, which also clears INT L45 DSCP if
      received on an edge port (note does not yet clear INT L45 DSCP if sink)
    source is set by int_watchlist table only if sink is not set
    transit if valid(int_header)

    If sink,
        if stateful suppression is enabled checks changes
        send upstream i2e report if stateful or stateless suppress see changes
    If source, nothing more than applying int_watchlist
    if transit,
        set path_tracking_flow at ingress to indicate packet had INT. Do it at
        ingress so that ingress dropped packet can also know that.
 ******************************************************************************/


/*******************************************************************************
 INT sink ingress control block process_dtel_int_sink
 if packet has int_header and endpoint is enabled
    set int_metadata.sink
    if packet has digest
      update bfilters and detect upstream flow state change (if feature is enabled)
*******************************************************************************/

control process_dtel_int_sink {
# 105 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_int.p4"
}

control process_dtel_make_upstream_digest {



}

control process_dtel_int_set_sink {



}
# 204 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_int.p4"
/*******************************************************************************
 INT sink ingress control block process_dtel_int_upstream_report
 Send upstream report if upstream flow state changes
 ******************************************************************************/

control process_dtel_int_upstream_report {
# 219 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_int.p4"
}
# 191 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2
# 1 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/dtel_postcard.p4" 1
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
 * $Id: $
 *
 ******************************************************************************/
/*
 * Postcard processing
 * At ingress apply watchlist
 * At egress if report all / any flow changes / queue report for not dropped packets
 *   generate an e2e clone
 * add switch local headers (poscart header) and update telemetry report header
 */

header_type postcard_metadata_t {
    fields {
        report : 1; // set if watchlist is hit
        suppress_enb : 1; // set if must track flow state changes (!report_all)
    }
}






metadata postcard_metadata_t postcard_md;
# 192 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4" 2

action nop() {
}

action on_miss() {
}

control ingress {
//----------------------------------------------------------------------
# 1437 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
//----------------------------------------------------------------------

    /* input mapping - derive an ifindex */
    process_ingress_port_mapping();

    /* read and apply system configuration parametes */
    process_global_params();






    /* process outer packet headers */
    process_validate_outer_header();

    /* process bfd rx packets */
    process_bfd_rx_packet();

    /* derive bd and its properties  */
    process_port_vlan_mapping();

    /* spanning tree state checks */
    process_ingress_stp();

    /* ingress fabric processing */
    process_ingress_fabric();


    /* tunnel termination processing */
    process_tunnel();


    /* IPSG */
    process_ip_sourceguard();

    /* ingress sflow determination */
    process_ingress_sflow();


    /* storm control */
    if(l3_metadata.rmac_hit == 0 and multicast_metadata.mcast_route_hit == 0 and multicast_metadata.mcast_bridge_hit == 0) {
      process_storm_control();
    }






    /* common (tx and rx) bfd processing */
    process_bfd_packet();
# 1500 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* validate packet */
    process_validate_packet();

    /* perform ingress l4 port range */
    process_ingress_l4port();

    /* l2 lookups */
    process_mac();
# 1527 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    process_ingress_port_mirroring();
# 1546 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    if (l2_metadata.lkp_pkt_type == 1) {




        apply(rmac) {
            rmac_hit {

                if (((ingress_metadata.bypass_lookups & 0x0002) == 0)) {
                    if ((l3_metadata.lkp_ip_type == 1) and
                        (ipv4_metadata.ipv4_unicast_enabled == 1)) {
                            process_ipv4_urpf();
                            process_ipv4_fib();




                    } else {
                        if ((l3_metadata.lkp_ip_type == 2) and
                            (ipv6_metadata.ipv6_unicast_enabled == 1)) {
                            process_ipv6_urpf();
                            process_ipv6_fib();
                        }
                    }

                    process_urpf_bd();
                }
            }
        }
    } else {
        process_multicast();
    }
# 1589 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* router ACL/PBR */
    if (((ingress_metadata.bypass_lookups & 0x0004) == 0)) {
        if ((l2_metadata.lkp_pkt_type == 1 and l3_metadata.rmac_hit == 1) or (l2_metadata.lkp_pkt_type == 2)) {

            if (l3_metadata.lkp_ip_type == 1) {
                process_ipv4_racl();
            } else if (l3_metadata.lkp_ip_type == 2) {
                process_ipv6_racl();
            }
        }
    }



    /* port and vlan ACL */



    if (l3_metadata.lkp_ip_type == 0) {



        process_mac_acl();

    } else {
        process_ip_acl();
    }


    /* ingress NAT */
    process_ingress_nat();
# 1635 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* prepare metadata for DTel */
    process_dtel_ingress_prepare();



    /* int_sink process for packets with int_header */
    process_dtel_int_sink();
# 1650 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* compute hashes based on packet type  */

    process_hashes_1();

    process_hashes_2();

    /* apply DTel watchlist */
    process_dtel_watchlist();
# 1667 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* decide final forwarding choice */
    process_fwd_results();


    /* Ingress vlan membership check */
    process_ingress_vlan_mbr();
# 1683 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* update statistics */
    process_ingress_bd_stats();
    process_ingress_acl_stats();

    if(l3_metadata.rmac_hit == 0 and multicast_metadata.mcast_route_hit == 0 and multicast_metadata.mcast_bridge_hit == 0) {
      process_storm_control_stats();
    }
# 1699 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* ingress qos map */
    process_ingress_qos_map();
# 1712 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* flowlet */
    process_flowlet();

    /* meter index */
    process_meter_index();
# 1727 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* ecmp/nexthop lookup */
    process_nexthop();
# 1739 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* IPv4 Mirror ACL */

    apply(ipv4_mirror_acl) {
        miss {
            /* INT i2e mirror */
            process_dtel_int_upstream_report();
        }
    }






    /* meter action/stats */
    process_meter_action();

    /* set queue id for tm */
    process_traffic_class();

    /* IPv6 Mirror ACL */
    if (l3_metadata.lkp_ip_type == 2) {
        process_ipv6_mirror_acl();
    }


    process_dtel_mod_watchlist();



    apply(nexthop_details) {
        nop {
            if (ingress_metadata.egress_ifindex == 0x3FFF) {
                /* resolve multicast index for flooding */
                process_multicast_flooding();
            }
        }
    }

    if(ingress_metadata.port_lag_index != 0) {
       /* resolve final egress port for unicast traffic */
       process_lag();
    }
# 1796 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
    /* generate learn notify digest if permitted */
    process_mac_learning();




    /* IPv6 Mirror ACL */
    process_ingress_mirror_acl_stats();

    /* resolve fabric port to destination device */
    process_fabric_lag();

    /* apply DTel queue related watchlist after queue is chosen */
    process_dtel_queue_watchlist();

    /* RACL stats */
    process_ingress_racl_stats();


    /* PPG Stats */
    process_ingress_ppg_stats();


    /* system acls */
    if (ingress_metadata.port_type != 1) {
        process_system_acl();
    }






    /* ECN ACL */
    process_ecn_acl();

    /* Peer-link */
    /* YID rewrite for CPU-TX or peer-link cases */
    if (ingress_metadata.port_type == 2) {
      process_cpu_packet();
    } else {
      process_peer_link_properties();
    }

//----------------------------------------------------------------------

//----------------------------------------------------------------------
}

control egress {

//----------------------------------------------------------------------
# 2690 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
//----------------------------------------------------------------------
    /*
     * if bfd rx pkt is for recirc to correct pipe,
     * skip the rest of the pipeline
     */
    process_bfd_recirc();

    /* Process lag selection fallback */
    process_lag_fallback();

    /* Egress Port Mirroring */






    /* Record egress port for telemetry in case of DoD */
    if (not (eg_intr_md_from_parser_aux.clone_src != 0)) {
        process_dtel_record_egress_port();
    }

    /* check for -ve mirrored pkt */
    if (egress_metadata.bypass == 0) {
        if (eg_intr_md.deflection_flag == 0) {

            /* multi-destination replication */
            process_rid();

            /* check if pkt is mirrored */
            if (not (eg_intr_md_from_parser_aux.clone_src != 0)) {
                process_egress_bfd_packet();
                process_dtel_prepare_egress();
            } else {
                /* mirror processing */

                process_mirroring();

                process_bfd_mirror_to_cpu();
            }

            /* multi-destination replication */
            process_replication();

            if (not (eg_intr_md_from_parser_aux.clone_src != 0)) {
                /* DTel processing -- detect local change and e2e */
                process_dtel_local_report1();
            } else {
                process_dtel_drop_suppress_prepare();
            }
# 2752 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
            /* determine egress port properties */
            apply(egress_port_mapping) {
                egress_port_type_normal {
# 2763 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
                    /* apply nexthop_index based packet rewrites */
                    process_rewrite();



                    if ((eg_intr_md_from_parser_aux.clone_src == 0)) {
                        /* strip vlan header */
                        process_vlan_decap();
                    }


                    /* perform tunnel decap */
                    process_tunnel_decap();



                    /* egress qos map */
                    process_egress_qos_map();
# 2802 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
                }
            }







            /* DTel processing -- detect local change */
            process_dtel_local_report2();







            /* DTel processing -- e2e */
            process_dtel_local_report3();

            if (egress_metadata.port_type == 0) {

                /* perform egress l4 port range */
                process_egress_l4port();

                /* egress bd properties */
                process_egress_bd();






                /* egress acl */
                process_egress_acl();

                if (not (eg_intr_md_from_parser_aux.clone_src != 0)) {
                    /* wred processing */
                    process_wred();
                }

                /* rewrite source/destination mac if needed */
                process_mac_rewrite();






                /* egress nat processing */
                process_egress_nat();


                /* update egress bd stats */
                process_egress_bd_stats();


                /* update egress acl stats */
                process_egress_acl_stats();
            }







            if ((eg_intr_md_from_parser_aux.clone_src != 0)) {
                /* DTel processing -- convert h/w port to frontend port */
                process_dtel_port_convert();
                process_dtel_report_encap();
            } else {
                /* DTel processing -- insert header */
                process_dtel_insert();
            }
# 2889 "/mnt/p4c/extensions/p4_tests/p4_14/switch/p4src/switch.p4"
            /* perform tunnel encap */
            process_tunnel_encap();






            /* egress stp check */
            process_egress_stp();


            /* egress mtu checks */
            process_mtu();

            /* update L4 checksums (if needed) */
            process_l4_checksum();

            if (egress_metadata.port_type == 0) {
                /* egress vlan translation */
                process_vlan_xlate();




            }

            /* egress filter */
            process_egress_filter();

        } else {
            process_dtel_deflect_on_drop();

        }
    }

    /* WRED stats */
    process_wred_stats();

    /* Queue Stats */
    process_egress_queue_stats();

    /* Capture timestamp */




    /* apply egress acl */
    process_egress_system_acl();
//----------------------------------------------------------------------

//----------------------------------------------------------------------
}
