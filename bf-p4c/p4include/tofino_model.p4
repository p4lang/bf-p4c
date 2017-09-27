/*
Copyright (c) 2015-2017 Barefoot Networks, Inc.

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

#ifndef TOFINO_MODEL_P4_
#define TOFINO_MODEL_P4_

#include "core.p4"

// Standard-required declarations

typedef bit<9>  PortId_t;
typedef bit<16> PacketLength_t;
typedef bit<4>  EgressInstance_t;
typedef bit<4>  InstanceType_t;
typedef bit<12> ParserStatus_t;
typedef bit<12> ParserErrorLocation_t;

// error codes

// A header stack array index exceeded the declared bound.
const ParserStatus_t p4_pe_index_out_of_bounds = 0;
// There were not enough bytes in the packet to complete an extraction operation.
const ParserStatus_t p4_pe_out_of_packet = 1;
// A calculated header length exceeded the declared maximum value.
const ParserStatus_t p4_pe_header_too_long = 2;
// A calculated header length was less than the minimum length of the
// fixed length portion of the header.
const ParserStatus_t p4_pe_header_too_short = 3;
// A select statement had no default specified but the expression
// value was not in the case list.
const ParserStatus_t p4_pe_unhandled_select = 4;
// A checksum error was detected.
const ParserStatus_t p4_pe_checksum = 5;
// This is not an exception itself, but allows the pro grammer to
// define a handler to specify the default behavior if no handler for
// the condition exists.
const ParserStatus_t p4_pe_default = 6;

// instance codes

const InstanceType_t INSTANCE_TYPE_NORMAL = 0;
const InstanceType_t INSTANCE_TYPE_INGRESS_CLONE = 1;
const InstanceType_t INSTANCE_TYPE_EGRESS_CLONE = 2;
const InstanceType_t INSTANCE_TYPE_COALESCED = 3;
const InstanceType_t INSTANCE_TYPE_INGRESS_RECIRC = 4;
const InstanceType_t INSTANCE_TYPE_REPLICATION = 5;
const InstanceType_t INSTANCE_TYPE_RESUBMIT = 6;

struct standard_ingress_input_metadata
{
    PortId_t ingress_port;             // ingress physical port id.
    PacketLength_t packet_length;      // packet length (excluding CRC)
    InstanceType_t instance_type;
    ParserStatus_t parser_status;
    ParserErrorLocation_t parser_error_location;
}

struct standard_ingress_output_metadata
{
    PortId_t ucast_egress_port;        // egress port for unicast packets.
}

struct standard_egress_input_metadata
{
    EgressInstance_t egress_instance;
    PortId_t         egress_port;
}

struct standard_egress_output_metadata
{
    PortId_t egress_port;
}

// Tofino-specific custom metadata

struct ingress_parser_control_signals
{
    bit<3>    priority;                   // set packet priority
}

struct ingress_intrinsic_metadata_t
{
    bit<1> resubmit_flag;              // flag distinguishing original packets
                                       // from resubmitted packets.

    bit<48>  ingress_global_tstamp;     // global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32>  lf_field_list;             // hack for learn filter.
}

struct ingress_in_metadata
{
    standard_ingress_input_metadata std;  // standard metadata
    ingress_intrinsic_metadata_t     ext; // hardware-specific extension
}

struct ingress_intrinsic_metadata_for_tm_t
{

    bit<16> mcast_grp_a;                // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

    bit<16> mcast_grp_b;                // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

    bit<13> level1_mcast_hash;          // source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash;          // source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

    bit<16> level1_exclusion_id;        // exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    bit<9> level2_exclusion_id;         // exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

    bit<16> rid;                        // L3 replication id for multicast.
                                        // used for pruning.
    bit<1> deflect_on_drop;             // flag indicating whether a packet can
                                        // be deflected by TM on congestion drop
}

struct ingress_out_metadata
{
    standard_ingress_output_metadata std;    // standard metadata
    ingress_intrinsic_metadata_for_tm_t ext; // hardware-specific extensions
}

struct egress_intrinsic_metadata_t
{
        bit<19> enq_qdepth;             // queue depth at the packet enqueue
                                        // time.

        bit<2> enq_congest_stat;        // queue congestion status at the packet
                                        // enqueue time.

        bit<32> enq_tstamp;             // time snapshot taken when the packet
                                        // is enqueued (in nsec).

        bit<19> deq_qdepth;             // queue depth at the packet dequeue
                                        // time.

        bit<2> deq_congest_stat;        // queue congestion status at the packet
                                        // dequeue time.

        bit<8> app_pool_congest_stat;   // dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

        bit<32> deq_timedelta;          // time delta between the packet's
                                        // enqueue and dequeue time.

        bit<16> egress_rid;             // L3 replication id for multicast
                                        // packets.

        bit<1> egress_rid_first;        // flag indicating the first replica for
                                        // the given multicast group.

        bit<5> egress_qid;              // egress (physical) queue id via which
                                        // this packet was served.

        bit<3> egress_cos;              // egress cos (eCoS) value.

        bit<1> deflection_flag;         // flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.
}

struct egress_intrinsic_metadata_from_parser_aux_t
{
    bit<8> clone_src;
    bit<48> egress_global_tstamp;
}

struct egress_in_metadata
{
    standard_egress_input_metadata              std; // standard
    egress_intrinsic_metadata_t                 ext1; // target-specific extension
    egress_intrinsic_metadata_from_parser_aux_t ext2; // target-specific extension
}

/////////////// Switch declaration

parser Parser<H>(packet_in packet, in ingress_parser_control_signals pcs, out H headers);

control IngressMatchAction<H>(inout H headers, in ingress_in_metadata iim, out ingress_out_metadata iom);
control EgressMatchAction<H>(inout H headers, in egress_in_metadata eim, out standard_egress_output_metadata eom);

control Deparser<H>(in H headers);

package IngressPipeline<H>(
        // All parsers in a pipeline must produce the same header type
        // because they feed the same pipeline
        Parser<H> parser0,
        Parser<H> parser1,
        Parser<H> parser2,
        Parser<H> parser3,
        Parser<H> parser4,
        Parser<H> parser5,
        Parser<H> parser6,
        Parser<H> parser7,
        Parser<H> parser8,
        Parser<H> parser9,
        Parser<H> parser10,
        Parser<H> parser11,
        Parser<H> parser12,
        Parser<H> parser13,
        Parser<H> parser14,
        Parser<H> parser15,
        Parser<H> parser16,
        Parser<H> parser17,
        IngressMatchAction<H> pipeline,
        Deparser<H> deparser);

package EgressPipeline<H>(
        Parser<H> parser0,
        Parser<H> parser1,
        Parser<H> parser2,
        Parser<H> parser3,
        Parser<H> parser4,
        Parser<H> parser5,
        Parser<H> parser6,
        Parser<H> parser7,
        Parser<H> parser8,
        Parser<H> parser9,
        Parser<H> parser10,
        Parser<H> parser11,
        Parser<H> parser12,
        Parser<H> parser13,
        Parser<H> parser14,
        Parser<H> parser15,
        Parser<H> parser16,
        Parser<H> parser17,
        EgressMatchAction<H> pipeline,
        Deparser<H> deparser);

package Switch(
        // Each pipeline can have different header types, indicated by don't care _
        IngressPipeline<_> ingress0,
        IngressPipeline<_> ingress1,
        IngressPipeline<_> ingress2,
        IngressPipeline<_> ingress3,

        EgressPipeline<_> egress0,
        EgressPipeline<_> egress1,
        EgressPipeline<_> egress2,
        EgressPipeline<_> egress3);


package UniformIngressPipeline<H>(
        // All parsers in a pipeline must produce the same header type
        // because they feed the same pipeline
        Parser<H> parsers0_17,
        IngressMatchAction<H> pipeline,
        Deparser<H> deparser);

package UniformEgressPipeline<H>(
        Parser<H> parsers0_17,
        EgressMatchAction<H> pipeline,
        Deparser<H> deparser);

package UniformSwitch(
        // Each pipeline can have different header types, indicated by don't care _
        UniformIngressPipeline<_> ingress0,
        UniformIngressPipeline<_> ingress1,
        UniformIngressPipeline<_> ingress2,
        UniformIngressPipeline<_> ingress3,

        UniformEgressPipeline<_> egress0,
        UniformEgressPipeline<_> egress1,
        UniformEgressPipeline<_> egress2,
        UniformEgressPipeline<_> egress3);

package SimplerSwitch<H>(
        Parser<H> commonParser,
        Deparser<H> commonDeparser,
        IngressMatchAction<H> ingress0,
        IngressMatchAction<H> ingress1,
        IngressMatchAction<H> ingress2,
        IngressMatchAction<H> ingress3,
        EgressMatchAction<H> egress0,
        EgressMatchAction<H> egress1,
        EgressMatchAction<H> egress2,
        EgressMatchAction<H> egress3);

#endif /* TOFINO_MODEL_P4_ */
