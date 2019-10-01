# 1 "ecobalancer.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "ecobalancer.p4"
/* Copyright (C) 2019 by RDP.ru. All Right Reserved */



# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/constants.p4" 1
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
# 41 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Digest receivers
# 53 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/constants.p4"
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Clone soruces
// (to be used with eg_intr_md_from_parser_aux.clone_src)




/////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Default priorities
# 6 "ecobalancer.p4" 2
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/intrinsic_metadata.p4" 1
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
# 7 "ecobalancer.p4" 2
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/primitives.p4" 1
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
# 8 "ecobalancer.p4" 2
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/pktgen_headers.p4" 1
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
# 9 "ecobalancer.p4" 2
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4_14include/tofino/stateful_alu_blackbox.p4" 1
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
# 10 "ecobalancer.p4" 2
# 1 "defines.p4" 1
/* Copyright (C) 2019 by RDP.ru. All Right Reserved */
# 11 "ecobalancer.p4" 2
# 1 "headers.p4" 1
/* Copyright (C) 2019 by RDP.ru. All Right Reserved */

header_type pcie_t
{
  fields
  {
    pad0: 7;
    is_group: 1;
    pad1: 7;
    port: 9;
    group: 16;
  }
}

header_type eth_t
{
  fields
  {
    dst_addr: 48;
    src_addr: 48;
  }
}

header_type llc_t
{
  fields
  {
    ssap: 8;
    dsap: 8;
    ctrl: 8;
  }
}

header_type vlan_t
{
  fields
  {
    vlan_type: 16;
    prio: 3;
    cfi: 1;
    id: 12;
  }
}

header_type eth_type_t
{
  fields
  {
#ifdef CASE_FIX
    _pad0: 16;
#else
    _: 16;
#endif
  }
}

header_type pppoe_t
{
  fields
  {
    magic: 16; // ETHER_PPPOE
    version: 4;
    ptype: 4;
    code: 8;
    session: 16;
    payloadLen: 16;
  }
}

header_type pppoe_data_t
{
  fields
  {
    protocol: 16;
  }
}

header_type mpls_t
{
  fields
  {
    label: 20;
    tclass: 3;
    bottom: 1;
    ttl: 8;
  }
}

header_type mpls_cw_t
{
  fields
  {
    useless: 32;
  }
}

header_type ipv4_t
{
  fields
  {
    version: 4;
    ihl: 4;
    diffserv: 8;
    totalLen: 16;
    identification: 16;
    flag_reserve: 1;
    flag_dont_fragment: 1;
    flag_more_fragments: 1;
    fragOffset: 13;
    ttl: 8;
    protocol: 8;
    hdrChecksum: 16;
    src_addr: 32;
    dst_addr: 32;
  }
}

header_type ipv4_skip_4_t { fields { useless: 32; } }
header_type ipv4_skip_8_t { fields { useless: 64; } }
header_type ipv4_skip_12_t { fields { useless: 96; } }
header_type ipv4_skip_16_t { fields { useless: 128; } }
header_type ipv4_skip_20_t { fields { useless: 160; } }
header_type ipv4_skip_24_t { fields { useless: 192; } }
header_type ipv4_skip_28_t { fields { useless: 224; } }
header_type ipv4_skip_32_t { fields { useless: 256; } }
header_type ipv4_skip_36_t { fields { useless: 288; } }
header_type ipv4_skip_40_t { fields { useless: 320; } }

header_type ipv6_t
{
  fields
  {
    ver: 4;
    tclass: 8;
    flowl: 20;
    payloadLen: 16;
    nextHeader: 8;
    hopLimit: 8;
    src_addr_h: 96;
    src_addr_l: 32;
    dst_addr_h: 96;
    dst_addr_l: 32;
  }
}

header_type tcp_t
{
  fields
  {
    src_port: 16;
    dst_port: 16;
    seqNum: 32;
    ackNum: 32;
    headerLen: 4;
    reserved: 3;
    flag_ns: 1;
    flag_cwr: 1;
    flag_ece: 1;
    flag_urg: 1;
    flag_ack: 1;
    flag_psh: 1;
    flag_rst: 1;
    flag_syn: 1;
    flag_fin: 1;
    window: 16;
    checksum: 16;
    urgentPtr: 16;
  }
}

header_type udp_t
{
  fields
  {
    src_port: 16;
    dst_port: 16;
    len: 16;
    csum: 16;
  }
}

header_type udplite_t
{
  fields
  {
    src_port: 16;
    dst_port: 16;
    ccover : 16;
    csum : 16;
  }
}

header_type sctp_t
{
  fields
  {
    src_port : 16;
    dst_port : 16;
    tag : 32;
    csum : 32;
  }
}

header_type dccp_t
{
  fields
  {
    src_port : 16;
    dst_port : 16;
  }
}

header pcie_t pcie;
header eth_t eth;
header llc_t llc;
header vlan_t vlan[6];
header pppoe_t pppoe;
header pppoe_data_t pppoe_data;
header eth_type_t eth_type;
header mpls_t mpls[6];
header mpls_cw_t mpls_cw;
header eth_t inner_eth;
header vlan_t inner_vlan[6];
header eth_type_t inner_eth_type;
header ipv4_t ipv4;
header ipv4_skip_4_t ipv4_skip_4;
header ipv4_skip_8_t ipv4_skip_8;
header ipv4_skip_12_t ipv4_skip_12;
header ipv4_skip_16_t ipv4_skip_16;
header ipv4_skip_20_t ipv4_skip_20;
header ipv4_skip_24_t ipv4_skip_24;
header ipv4_skip_28_t ipv4_skip_28;
header ipv4_skip_32_t ipv4_skip_32;
header ipv4_skip_36_t ipv4_skip_36;
header ipv4_skip_40_t ipv4_skip_40;
header ipv6_t ipv6;
header tcp_t tcp;
header udp_t udp;
header udplite_t udplite;
header sctp_t sctp;
header dccp_t dccp;
# 12 "ecobalancer.p4" 2
# 1 "metadata.p4" 1
/* Copyright (C) 2019 by RDP.ru. All Right Reserved */

header_type port_meta_t
{
  fields
  {
    _pad1: 6;

    is_wan: 1;
    is_group : 1;
    _pad2: 7;
    neighbor_port: 9;

    filter_id: 16;
    group_id: 16;
  }
}

header_type flow_meta_t
{
  fields
  {
    pad0: 7;
    port: 9;
    hash: 16;
    ig_tstamp: 48;
  }
}

header_type l2_meta_t
{
  fields
  {
    dst: 48;
    src: 48;
    eth_type: 16;
  }
}

header_type l3_meta_t
{
  fields
  {
    src_h: 96;
    src_l: 32;
    dst_h: 96;
    dst_l: 32;
  }
}

header_type l4_meta_t
{
  fields
  {
    ip_proto: 8;
    src: 16;
    dst: 16;
  }
}

header_type l5_meta_t
{
  fields
  {
    _pad1: 7;
    http_get: 1;
  }
}

metadata port_meta_t port_meta;
metadata flow_meta_t flow_meta;
metadata l2_meta_t l2_meta;
metadata l3_meta_t l3_meta;
metadata l4_meta_t l4_meta;
metadata l5_meta_t l5_meta;
# 13 "ecobalancer.p4" 2
# 1 "parsers.p4" 1
/* Copyright (C) 2019 by RDP.ru. All Right Reserved */

@pragma parser_value_set_size 1
parser_value_set pcie_port;

parser start
{
  return select(ig_intr_md.ingress_port)
  {
    pcie_port: parse_pcie;
    default: parse_eth;
  }
}

parser parse_pcie
{
  extract(pcie);
  return parse_eth;
}

@pragma packet_entry
parser start_i2e_mirrored
{
  return parse_eth;
}

parser parse_eth
{
  extract(eth);
  return parse_eth_payload;
}

parser parse_eth_payload
{
  return select(current(0, 16))
  {
    0x0000 mask 0xFC00: parse_llc;
    0x0400 mask 0xFE00: parse_llc;
    0x8100: parse_vlan;
    0x9200: parse_vlan;
    0x9100: parse_vlan;
    0x88A8: parse_vlan;
    0x8864: parse_pppoe;
    default: parse_eth_type;
  }
}

parser parse_llc
{
  extract(llc);
  return ingress;
}

parser parse_vlan
{
  extract(vlan[next]);
  return select(current(0, 16))
  {
    0x8100: parse_vlan;
    0x9200: parse_vlan;
    0x9100: parse_vlan;
    0x88A8: parse_vlan;
    0x8864: parse_pppoe;
    default: parse_eth_type;
  }
}

parser parse_pppoe
{
  extract(pppoe);
  return select(latest.code)
  {
    0x00: parse_pppoe_data;
    default: ingress;
  }
}

parser parse_pppoe_data
{
  extract(pppoe_data);
  return select(latest.protocol)
  {
    0x0021: parse_ipv4;
    0x0057: parse_ipv6;
    default: ingress;
  }
}

parser parse_eth_type
{
  extract(eth_type);
#ifdef CASE_FIX
  set_metadata(l2_meta.eth_type, latest._pad0);
  return select(latest._pad0)
#else
  set_metadata(l2_meta.eth_type, latest._);
  return select(latest._)
#endif
  {
    0x8847: parse_mpls;
    0x8848: parse_mpls;
    0x0800: parse_ipv4;
    0x86DD: parse_ipv6;
    default: ingress;
  }
}

parser parse_mpls
{
  extract(mpls[next]);
  return select(latest.bottom)
  {
    0: parse_mpls;
    1: parse_mpls_cw_determine;
    default: ingress;
  }
}

parser parse_mpls_cw_determine
{
  return select (current(0, 8))
  {
    0x00: parse_mpls_cw;
    0x45: try_ipv4;
    0x46 mask 0xFE: try_ipv4; // 0x46 - 0x47
    0x48 mask 0xF8: try_ipv4; // 0x48 - 0x4F
    0x60 mask 0xF0: try_ipv6; // 0x60 - 0x6F
    default: parse_inner_eth;
  }
}

parser parse_mpls_cw
{
  extract(mpls_cw);
  return select (current(0, 8))
  {
    0x45: try_ipv4;
    0x46 mask 0xFE: try_ipv4; // 0x46 - 0x47
    0x48 mask 0xF8: try_ipv4; // 0x48 - 0x4F
    0x60 mask 0xF0: try_ipv6; // 0x60 - 0x6F
    default: parse_inner_eth;
  }
}

parser try_ipv4
{
  return select(current(72, 8))
  {
    0x04: parse_ipv4;
    0x29: parse_ipv4;
    0x88: parse_ipv4;
    0x84: parse_ipv4;
    0x06: parse_ipv4;
    0x11: parse_ipv4;
    0x2F: parse_ipv4;
    0x21: parse_ipv4;
    default: parse_inner_eth;
  }
}

parser try_ipv6
{
  return select(current(48, 8))
  {
    0x04: parse_ipv6;
    0x29: parse_ipv6;
    0x88: parse_ipv6;
    0x84: parse_ipv6;
    0x06: parse_ipv6;
    0x11: parse_ipv6;
    0x2F: parse_ipv6;
    0x21: parse_ipv6;
    0: parse_ipv6;
    43: parse_ipv6;
    44: parse_ipv6;
    50: parse_ipv6;
    51: parse_ipv6;
    60: parse_ipv6;
    135: parse_ipv6;
    59: parse_ipv6;
    default: parse_inner_eth;
  }
}

parser parse_inner_eth
{
  extract(inner_eth);
  return select(current(0, 16))
  {
    0x8100: parse_inner_vlan;
    0x9200: parse_inner_vlan;
    0x9100: parse_inner_vlan;
    0x88A8: parse_inner_vlan;
    default: parse_inner_eth_type;
  }
}

parser parse_inner_vlan
{
  extract(inner_vlan[next]);
  return select(current(0, 16))
  {
    0x8100: parse_inner_vlan;
    0x9200: parse_inner_vlan;
    0x9100: parse_inner_vlan;
    0x88A8: parse_inner_vlan;
    default: parse_inner_eth_type;
  }
}

parser parse_inner_eth_type
{
  extract(inner_eth_type);
#ifdef CASE_FIX
  return select(latest._pad0)
#else
  return select(latest._)
#endif
  {
    0x0800: parse_ipv4;
    0x86DD: parse_ipv6;
    default: ingress;
  }
}

parser parse_ipv4
{
  extract(ipv4);
  return select(latest.ihl)
  {
    0x0 mask 0xC: ingress;
    0x4 mask 0xF: ingress;
    0x5: parse_ipv4_proto;
    0x6: parse_ipv4_skip_4;
    0x7: parse_ipv4_skip_8;
    0x8: parse_ipv4_skip_12;
    0x9: parse_ipv4_skip_16;
    0xA: parse_ipv4_skip_20;
    0xB: parse_ipv4_skip_24;
    0xC: parse_ipv4_skip_28;
    0xD: parse_ipv4_skip_32;
    0xE: parse_ipv4_skip_36;
    0xF: parse_ipv4_skip_40;
    default: ingress;
  }
}

parser parse_ipv4_skip_4 { extract(ipv4_skip_4); return parse_ipv4_proto; }
parser parse_ipv4_skip_8 { extract(ipv4_skip_8); return parse_ipv4_proto; }
parser parse_ipv4_skip_12 { extract(ipv4_skip_12); return parse_ipv4_proto; }
parser parse_ipv4_skip_16 { extract(ipv4_skip_16); return parse_ipv4_proto; }
parser parse_ipv4_skip_20 { extract(ipv4_skip_20); return parse_ipv4_proto; }
parser parse_ipv4_skip_24 { extract(ipv4_skip_24); return parse_ipv4_proto; }
parser parse_ipv4_skip_28 { extract(ipv4_skip_28); return parse_ipv4_proto; }
parser parse_ipv4_skip_32 { extract(ipv4_skip_32); return parse_ipv4_proto; }
parser parse_ipv4_skip_36 { extract(ipv4_skip_36); return parse_ipv4_proto; }
parser parse_ipv4_skip_40 { extract(ipv4_skip_40); return parse_ipv4_proto; }

parser parse_ipv6
{
  extract(ipv6);

  return select(latest.nextHeader)
  {
    0x06: parse_tcp;
    0x11: parse_udp;
    0x88: parse_udplite;
    0x84: parse_sctp;
    0x21: parse_dccp;
    default: ingress;
  }



}

parser parse_ipv4_proto
{
  return select(ipv4.flag_more_fragments, ipv4.fragOffset, ipv4.protocol)
  {
    0x06: parse_tcp;
    0x11: parse_udp;
    0x88: parse_udplite;
    0x84: parse_sctp;
    0x21: parse_dccp;
    default: ingress;
  }
}

parser parse_tcp
{
  extract(tcp);
  set_metadata(l4_meta.src, latest.src_port);
  set_metadata(l4_meta.dst, latest.dst_port);
  return parse_tcp_payload;
}

parser parse_udp
{
  extract(udp);
  set_metadata(l4_meta.src, latest.src_port);
  set_metadata(l4_meta.dst, latest.dst_port);
  return parse_udp_payload;
}

parser parse_udplite
{
  extract(udplite);
  set_metadata(l4_meta.src, latest.src_port);
  set_metadata(l4_meta.dst, latest.dst_port);
  return ingress;
}

parser parse_sctp
{
  extract(sctp);
  set_metadata(l4_meta.src, latest.src_port);
  set_metadata(l4_meta.dst, latest.dst_port);
  return ingress;
}

parser parse_dccp
{
  extract(dccp);
  set_metadata(l4_meta.src, latest.src_port);
  set_metadata(l4_meta.dst, latest.dst_port);
  return ingress;
}

parser parse_tcp_payload
{
  return select(current(0, 32))
  {
    0x47455420: parse_tcp_payload_http_get;
    default: ingress;
  }
}

parser parse_tcp_payload_http_get
{
  set_metadata(l5_meta.http_get, 1);
  return ingress;
}

parser parse_udp_payload
{
  return ingress;
}
# 14 "ecobalancer.p4" 2

action nop() { }
action _drop() { drop(); }
action pcie_to_port() { modify_field(ig_intr_md_for_tm.ucast_egress_port, pcie.port); }
action pcie_to_group() { modify_field(ig_intr_md_for_tm.mcast_grp_a, pcie.group); }

table from_pcie
{
  reads
  {
    pcie.valid: exact;
    pcie.is_group : exact;
  }
  actions
  {
    pcie_to_port;
    pcie_to_group;
    nop;
  }
  size: 4;
}

action from_trunk() {}

action from_link(egress_group)
{
  modify_field(ig_intr_md_for_tm.level2_mcast_hash, flow_meta.hash);
  modify_field(ig_intr_md_for_tm.mcast_grp_a, egress_group);
}

table in_interface
{
  reads
  {
    ig_intr_md.ingress_port mask 0x7F: exact;
    vlan[0].valid: ternary;
  }
  actions
  {
    from_trunk;
    from_link;
    _drop;
  }
  size: 128;
}

action out_port(port) { modify_field(ig_intr_md_for_tm.ucast_egress_port, port); }
action bypass() { modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port); }

table vlan_redirection
{
  reads
  {
    vlan[0].valid: exact;
    vlan[0].id: exact;
  }
  actions
  {
    out_port;
    bypass;
    _drop;
  }
  size: 4096;
}

field_list list_inner_eth
{
  inner_eth.dst_addr;
  inner_eth.src_addr;
#ifdef CASE_FIX
  inner_eth_type._pad0;
#else
  inner_eth_type._;
#endif
}

field_list_calculation hash_inner_eth { input { list_inner_eth; } algorithm: crc32; output_width: 16; }
action calc_inner_eth() { modify_field_with_hash_based_offset(flow_meta.hash, 0, hash_inner_eth, 65536); }

@pragma ternary 1
table calc_hash_inner_eth { reads { inner_eth.valid: exact; } actions { calc_inner_eth; nop; } size: 2; }

field_list list_ipv4
{
  ipv4.dst_addr;
  ipv4.src_addr;
  ipv4.protocol;
}
field_list_calculation hash_ipv4 { input { list_ipv4; } algorithm: crc32; output_width: 16; }
action calc_ipv4() { modify_field_with_hash_based_offset(flow_meta.hash, 0, hash_ipv4, 65536); }

field_list list_ipv6
{
  ipv6.dst_addr_h;
  ipv6.dst_addr_l;
  ipv6.src_addr_h;
  ipv6.src_addr_l;
  ipv6.nextHeader;
}
field_list_calculation hash_ipv6 { input { list_ipv6; } algorithm: crc32; output_width: 16; }
action calc_ipv6() { modify_field_with_hash_based_offset(flow_meta.hash, 0, hash_ipv6, 65536); }

@pragma ternary 1
table calc_hash_ip
{
  reads
  {
    ipv4.valid: exact;
    ipv6.valid: exact;
  }
  actions
  {
    calc_ipv4;
    calc_ipv6;
    nop;
  }
  size: 2;
}

control ingress
{
  apply(from_pcie) { nop {
    apply(calc_hash_inner_eth);
    apply(calc_hash_ip);
    apply(in_interface)
    {
      from_trunk
      {
        apply(vlan_redirection);
      }
    }
  }}
}

action to_pcie()
{
  modify_field(pcie.port, ig_intr_md.ingress_port);
  modify_field(pcie.is_group, 0);
}

action to_pcie_add_header()
{
  add_header(pcie);
  to_pcie();
}

action to_pcie_remove_header()
{
  remove_header(pcie);
}

@pragma ternary 1
table to_pcie
{
  reads
  {
    pcie.valid: exact;
    eg_intr_md.egress_port: exact;
  }
  actions
  {
    to_pcie;
    to_pcie_add_header;
    to_pcie_remove_header;
  }
  size: 2;
}

action to_trunk(vlan_id)
{
  push(vlan, 1);
  modify_field(vlan[0].vlan_type, 0x8100);
  modify_field(vlan[0].id, vlan_id);
}

action to_link()
{
  pop(vlan);
}

@pragma ternary 1
table out_interface
{
  reads
  {
    pcie.valid: exact;
    ig_intr_md.ingress_port: exact;
  }
  actions
  {
    to_trunk;
    to_link;
    nop;
  }
  size: 512;
}

control egress
{
  apply(to_pcie);
  apply(out_interface);
}
