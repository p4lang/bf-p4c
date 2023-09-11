# 1 "bfs.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "bfs.p4"
# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/core.p4" 1
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */




/// Standard error codes.  New error codes can be declared by users.
error {
    NoError, /// No error.
    PacketTooShort, /// Not enough bits in packet for 'extract'.
    NoMatch, /// 'select' expression has no matches.
    StackOutOfBounds, /// Reference to invalid element of a header stack.
    HeaderTooShort, /// Extracting too many bits into a varbit field.
    ParserTimeout, /// Parser execution time limit exceeded.
    ParserInvalidArgument /// Parser operation was called with a value
                           /// not supported by the implementation.
}

extern packet_in {
    /// Read a header from the packet into a fixed-sized header @hdr and advance the cursor.
    /// May trigger error PacketTooShort or StackOutOfBounds.
    /// @T must be a fixed-size header type
    void extract<T>(out T hdr);
    /// Read bits from the packet into a variable-sized header @variableSizeHeader
    /// and advance the cursor.
    /// @T must be a header containing exactly 1 varbit field.
    /// May trigger errors PacketTooShort, StackOutOfBounds, or HeaderTooShort.
    void extract<T>(out T variableSizeHeader,
                    in bit<32> variableFieldSizeInBits);
    /// Read bits from the packet without advancing the cursor.
    /// @returns: the bits read from the packet.
    /// T may be an arbitrary fixed-size type.
    T lookahead<T>();
    /// Advance the packet cursor by the specified number of bits.
    void advance(in bit<32> sizeInBits);
    /// @return packet length in bytes.  This method may be unavailable on
    /// some target architectures.
    bit<32> length();
}

extern packet_out {
    /// Write @hdr into the output packet, advancing cursor.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

// TODO: remove from this file, convert to built-in
/// Check a predicate @check in the parser; if the predicate is true do nothing,
/// otherwise set the parser error to @toSignal, and transition to the `reject` state.
extern void verify(in bool check, in error toSignal);

/// Built-in action that does nothing.
@noWarn("unused")
action NoAction() {}

/// Standard match kinds for table key fields.
/// Some architectures may not support all these match kinds.
/// Architectures can declare additional match kinds.
match_kind {
    /// Match bits exactly.
    exact,
    /// Ternary match, using a mask.
    ternary,
    /// Longest-prefix match.
    lpm
}

/// Static assert evaluates a boolean expression
/// at compilation time.  If the expression evaluates to
/// false, compilation is stopped and the corresponding message is printed.
/// The function returns a boolean, so that it can be used
/// as a global constant value in a program, e.g.:
/// const bool _check = static_assert(V1MODEL_VERSION > 20180000, "Expected a v1 model version >= 20180000");
extern bool static_assert(bool check, string message);

/// Like the above but using a default message.
extern bool static_assert(bool check);
# 2 "bfs.p4" 2



# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2022 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */





# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_specs.p4" 1
/**
 * Copyright 2013-2022 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */




/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/

# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/core.p4" 1
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 29 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_specs.p4" 2

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------

typedef bit<9> PortId_t; // Port id -- ingress or egress port

typedef bit<16> MulticastGroupId_t; // Multicast group id

typedef bit<7> QueueId_t; // Queue id

typedef bit<4> MirrorType_t; // Mirror type

typedef bit<8> MirrorId_t; // Mirror id

typedef bit<3> ResubmitType_t; // Resubmit type

typedef bit<3> DigestType_t; // Digest type

typedef bit<16> ReplicationId_t; // Replication id

typedef bit<16> L1ExclusionId_t; // L1 Exclusion id

typedef bit<9> L2ExclusionId_t; // L2 Exclusion id

// CloneId_t will be deprecated in 9.4. Adding a typedef for any old references.
typedef MirrorType_t CloneId_t;

typedef error ParserError_t;


const bit<32> PORT_METADATA_SIZE = 32w192;
# 18 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/t2na.p4" 2






# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_arch.p4" 1
/**
 * Copyright 2013-2022 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */




/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/

# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_base.p4" 1
/**
 * Copyright 2013-2022 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */




/**
 Version Notes:

 0.6.0:
 - Initial release
 0.6.1:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH
 0.6.2:
 - Add portable macros and types
 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/




# 1 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/core.p4" 1
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 38 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_base.p4" 2

//XXX Open issues:
// Meter color
// Math unit
// Action selector
// Digest
// Coalesce mirroring

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_MATCH = 16w0x0001;
const bit<16> PARSER_ERROR_PARTIAL_HDR = 16w0x0002;
const bit<16> PARSER_ERROR_CTR_RANGE = 16w0x0004;
const bit<16> PARSER_ERROR_TIMEOUT_USER = 16w0x0008;
const bit<16> PARSER_ERROR_TIMEOUT_HW = 16w0x0010;
const bit<16> PARSER_ERROR_SRC_EXT = 16w0x0020;
const bit<16> PARSER_ERROR_PHV_OWNER = 16w0x0080;
const bit<16> PARSER_ERROR_MULTIWRITE = 16w0x0100;
const bit<16> PARSER_ERROR_ARAM_MBE = 16w0x0400;
const bit<16> PARSER_ERROR_FCS = 16w0x0800;
const bit<16> PARSER_ERROR_CSUM_MBE = 16w0x1000;

/// Meter
enum MeterType_t { PACKETS, BYTES }

enum bit<8> MeterColor_t { GREEN = 8w0, YELLOW = 8w1, RED = 8w3 }

/// Counter
enum CounterType_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

/// Selector mode
enum SelectorMode_t { FAIR, RESILIENT }

enum HashAlgorithm_t {
    IDENTITY,
    RANDOM,
    XOR8,
    XOR16,
    XOR32,
    CRC8,
    CRC16,
    CRC32,
    CRC64,
    CUSTOM /*< custom CRC polynomial - see the CRCPolynomial extern */
}

match_kind {
    // exact,
    // ternary,
    // lpm,               // Longest-prefix match.
    range,
    selector, // Used for implementing dynamic action selection
    dleft_hash, // Used for dleft dynamic caching
    atcam_partition_index // Used for implementing algorithmic tcam
}

error {
    // NoError,           // No error.
    // NoMatch,           // 'select' expression has no matches.
    // PacketTooShort,    // Not enough bits in packet for 'extract'.
    // StackOutOfBounds,  // Reference to invalid element of a header stack.
    // HeaderTooShort,    // Extracting too many bits into a varbit field.
    // ParserTimeout      // Parser execution time limit exceeded.
    CounterRange, // Counter initialization error.
    Timeout,
    PhvOwner, // Invalid destination container.
    MultiWrite,
    IbufOverflow, // Input buffer overflow.
    IbufUnderflow // Inbut buffer underflow.
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag; // Flag distinguishing original packets
                                        // from resubmitted packets.
    @padding bit<1> _pad1;

    bit<2> packet_version; // Read-only Packet version.

    @padding bit<(4 - 9 % 8)> _pad2;

    PortId_t ingress_port; // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp; // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    PortId_t ucast_egress_port; // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bit<1> bypass_egress; // Request flag for the warp mode
                                        // (egress bypass).

    bit<1> deflect_on_drop; // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos; // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    QueueId_t qid; // Egress (logical) queue id into which
                                        // this packet will be deposited.

    bit<3> icos_for_copy_to_cpu; // Ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

    bit<1> copy_to_cpu; // Request for copy to cpu.

    bit<2> packet_color; // Packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

    bit<1> disable_ucast_cutthru; // Disable cut-through forwarding for
                                        // unicast.

    bit<1> enable_mcast_cutthru; // Enable cut-through forwarding for
                                        // multicast.

    MulticastGroupId_t mcast_grp_a; // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

    MulticastGroupId_t mcast_grp_b; // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

    bit<13> level1_mcast_hash; // Source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash; // Source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

    L1ExclusionId_t level1_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    L2ExclusionId_t level2_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

    bit<16> rid; // L3 replication id for multicast.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp; // Global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32> global_ver; // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err; // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_deparser_t {

    bit<3> drop_ctl; // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 reserved
    DigestType_t digest_type;

    ResubmitType_t resubmit_type;

    MirrorType_t mirror_type; // The user-selected mirror field list
                                        // index.

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bit<1> mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bit<1> mirror_multicast_ctrl; // Mirror enable multicast if true.
    PortId_t mirror_egress_port; // Mirror packet egress port.
    QueueId_t mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag

    bit<3> learn_sel; // Learn quantum table selector
    bit<1> pktgen; // trigger packet generation
                                        // This is ONLY valid if resubmit_type
                                        // is not valid.
    bit<14> pktgen_address; // Packet generator buffer address.
    bit<10> pktgen_length; // Length of generated packet.

    // also need an extern for PacketGen
}
// -----------------------------------------------------------------------------
// GHOST INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata @__ghost_metadata
header ghost_intrinsic_metadata_t {
    bit<1> ping_pong; // ping-pong bit to control which version to update
    bit<18> qlength;
    bit<11> qid; // queue id for update
    bit<2> pipe_id;
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header egress_intrinsic_metadata_t {
    @padding bit<(8 - 9 % 8)> _pad0;

    PortId_t egress_port; // Egress port id.
                                        // this field is passed to the deparser

    @padding bit<5> _pad1;

    bit<19> enq_qdepth; // Queue depth at the packet enqueue
                                        // time.

    @padding bit<6> _pad2;

    bit<2> enq_congest_stat; // Queue congestion status at the packet
                                        // enqueue time.

    bit<32> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    @padding bit<5> _pad3;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    @padding bit<6> _pad4;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<32> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    bit<16> egress_rid; // L3 replication id for multicast
                                        // packets.

    @padding bit<7> _pad5;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    @padding bit<(8 - 7 % 8)> _pad6;

    QueueId_t egress_qid; // Egress (physical) queue id within a MAC via which
                                        // this packet was served.

    @padding bit<5> _pad7;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    @padding bit<7> _pad8;

    bit<1> deflection_flag; // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length; // Packet length, in bytes

    @padding bit<8> _pad9; // Pad to 4-byte alignment for egress
                                        // intrinsic metadata (HW constraint)
}


@__intrinsic_metadata
struct egress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp; // Global timestamp (ns) taken upon
                                        // arrival at egress.

    bit<32> global_ver; // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err; // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl; // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring

    MirrorType_t mirror_type;

    bit<1> coalesce_flush; // Flush the coalesced mirror buffer

    bit<7> coalesce_length; // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bit<1> mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bit<1> mirror_multicast_ctrl; // Mirror enable multicast if true.
    PortId_t mirror_egress_port; // Mirror packet egress port.
    QueueId_t mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_output_port_t {
    bit<1> capture_tstamp_on_tx; // Request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).

    bit<1> update_delay_on_tx; // Request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
}

// -----------------------------------------------------------------------------
// PACKET GENERATION
// -----------------------------------------------------------------------------
// Packet generator supports up to 16 applications and a total of 16KB packet
// payload. Each application is associated with one of the four trigger types:
// - One-time timer
// - Periodic timer
// - Port down
// - Packet recirculation
// - MAU packet trigger
// For recirculated packets, the event fires when the first 32 bits of the
// recirculated packet matches the application match value and mask.
// A triggered event may generate programmable number of batches with
// programmable number of packets per batch.

header pktgen_timer_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<(16 - 9 % 8)> _pad2;
    PortId_t port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_deparser_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_pfc_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<40> _pad2;
};

// -----------------------------------------------------------------------------
// TIME SYNCHRONIZATION
// -----------------------------------------------------------------------------

header ptp_metadata_t {
    bit<8> udp_cksum_byte_offset; // Byte offset at which the egress MAC
                                        // needs to update the UDP checksum


    bit<8> cf_byte_offset; // Byte offset at which the egress MAC
                                        // needs to re-insert
                                        // ptp_sync.correction field

    bit<48> updated_cf; // Updated correction field in ptp sync
                                        // message
}

// -----------------------------------------------------------------------------
// CHECKSUM
// -----------------------------------------------------------------------------
// Tofino checksum engine can verify the checksums for header-only checksums
// and calculate the residual (checksum minus the header field
// contribution) for checksums that include the payload.
// Checksum engine only supports 16-bit ones' complement checksums, also known
// as csum16 or internet checksum.

extern Checksum {
    /// Constructor.
    Checksum();

    /// Add data to checksum.
    /// @param data : List of fields to be added to checksum calculation. The
    /// data must be byte aligned.
    void add<T>(in T data);

    /// Subtract data from existing checksum.
    /// @param data : List of fields to be subtracted from the checksum. The
    /// data must be byte aligned.
    void subtract<T>(in T data);

    /// Verify whether the complemented sum is zero, i.e. the checksum is valid.
    /// @return : Boolean flag indicating whether the checksum is valid or not.
    bool verify();

    /// Get the calculated checksum value.
    /// @return : The calculated checksum value for added fields.
    bit<16> get();

    /// Subtract all header fields after the current state and
    /// return the calculated checksum value.
    /// Marks the end position for residual checksum header.
    /// All header fields extracted after will be automatically subtracted.
    /// @param residual : The calculated checksum value for added fields.
    void subtract_all_and_deposit<T>(out T residual);

    /// Calculate the checksum for a  given list of fields.
    /// @param data : List of fields contributing to the checksum value.
    /// @param zeros_as_ones : encode all-zeros value as all-ones.
    bit<16> update<T>(in T data, @optional in bool zeros_as_ones);
}

// ----------------------------------------------------------------------------
// PARSER COUNTER
// ----------------------------------------------------------------------------
// Tofino2 parser counter can be used to extract header stacks or headers with
// variable length. Tofino2 has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.
//
// On Tofino2, the parser counter also comes with a shallow stack (with depth of 4).
// The counter stack is useful when parsing nested TLV headers (e.g. GENEVE-like options
// where the total option length is variable and each individual option length is
// also variable).

extern ParserCounter {
    /// Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    void set<T>(in T value);

    /// Load the counter with a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Right rotate (circular) the source field by this number of bits.
    /// @param mask : Mask the rotated source field.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set<T>(in T field,
                in bit<8> max,
                in bit<8> rotate,
                in bit<8> mask,
                in bit<8> add);

    /// Push the immediate value or a header field onto the stack.
    /// @param update_with_top : update the pushed value when the top-of-stack value is updated.
    void push<T>(in T value, @optional bool update_with_top);

    /// Push the header field onto the stack.
    /// @param update_with_top : update the pushed value when the top-of-stack value is updated.
    void push<T>(in T field,
                 in bit<8> max,
                 in bit<8> rotate,
                 in bit<8> mask,
                 in bit<8> add,
                 @optional bool update_with_top);

    /// Pop the top-of-stack value from the stack.
    void pop();

    /// @return true if counter value is zero.
    bool is_zero();

    /// @return true if counter value is negative.
    bool is_negative();

    /// Add an immediate value to the parser counter.
    /// @param value : Constant to add to the counter.
    void increment(in bit<8> value);

    /// Subtract an immediate value from the parser counter.
    /// @param value : Constant to subtract from the counter.
    void decrement(in bit<8> value);
}

// ----------------------------------------------------------------------------
// PARSER PRIORITY
// ----------------------------------------------------------------------------
// Tofino ingress parser compare the priority with a configurable!!! threshold
// to determine to whether drop the packet if the input buffer is congested.
// Egress parser does not perform any dropping.
extern ParserPriority {
    /// Constructor
    ParserPriority();

    /// Set a new priority for the packet.
    void set(in bit<3> prio);
}

// ----------------------------------------------------------------------------
// HASH ENGINE
// ----------------------------------------------------------------------------
extern CRCPolynomial<T> {
    CRCPolynomial(T coeff, bool reversed, bool msb, bool extended, T init, T xor);
}

extern Hash<W> {
    /// Constructor
    /// @type_param W : width of the calculated hash.
    /// @param algo : The default algorithm used for hash calculation.
    Hash(HashAlgorithm_t algo);

    /// Constructor
    /// @param poly : The default coefficient used for hash algorithm.
    Hash(HashAlgorithm_t algo, CRCPolynomial<_> poly);

    /// Compute the hash for the given data.
    /// @param data : The list of fields contributing to the hash.
    /// @return The hash value.
    W get<D>(in D data);
}

/// Random number generator.
extern Random<W> {
    /// Constructor
    Random();

    /// Return a random number with uniform distribution.
    /// @return : ranom number between 0 and 2**W - 1
    W get();
}

/// Idle timeout
extern IdleTimeout {
    IdleTimeout();
}

// -----------------------------------------------------------------------------
// EXTERN FUNCTIONS
// -----------------------------------------------------------------------------

extern T max<T>(in T t1, in T t2);

extern T min<T>(in T t1, in T t2);

extern void funnel_shift_right<T>(out T dst, in T src1, in T src2, int shift_amount);

extern void invalidate<T>(in T field);

extern bool is_validated<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

extern bit<32> sizeInBits<H>(in H h);

extern bit<32> sizeInBytes<H>(in H h);

/// Counter
/// Indexed counter with `size’ independent counter values.
@noWarn("unused")
extern Counter<W, I> {
    /// Constructor
    /// @type_param W : width of the counter value.
    /// @type_param I : width of the counter index.
    /// @param type : counter type. Packet an byte counters are supported.
    /// @param true_egress_accounting : Use the final byte count from egress deparser after the final
    ///                                 output packet has been re-assembled (available in egress only).
    Counter(bit<32> size, CounterType_t type, @optional bool true_egress_accounting);

    /// Increment the counter value.
    /// @param index : index of the counter to be incremented.
    void count(in I index, @optional in bit<32> adjust_byte_count);
}

/// DirectCounter
@noWarn("unused")
extern DirectCounter<W> {
    DirectCounter(CounterType_t type, @optional bool true_egress_accounting);
    void count(@optional in bit<32> adjust_byte_count);
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type, @optional bool true_egress_accounting);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in I index, in MeterColor_t color, @optional in bit<32> adjust_byte_count);
    bit<8> execute(in I index, @optional in bit<32> adjust_byte_count);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type, @optional bool true_egress_accounting);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in MeterColor_t color, @optional in bit<32> adjust_byte_count);
    bit<8> execute(@optional in bit<32> adjust_byte_count);
}

/// LPF
extern Lpf<T, I> {
    Lpf(bit<32> size);
    T execute(in T val, in I index);
}

/// Direct LPF
extern DirectLpf<T> {
    DirectLpf();
    T execute(in T val);
}

/// WRED
extern Wred<T, I> {
    Wred(bit<32> size, bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val, in I index);
}

/// Direct WRED
extern DirectWred<T> {
    DirectWred(bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val);
}

/// Register
extern Register<T, I> {
    /// Instantiate an array of <size> registers. The initial value is
    /// undefined.
    Register(bit<32> size);

    /// Initialize an array of <size> registers and set their value to
    /// initial_value.
    Register(bit<32> size, T initial_value);

    /// Return the value of register at specified index.
    T read(in I index);

    /// Write value to register at specified index.
    void write(in I index, in T value);

    /// Write a value to every index in the register
    void clear(in T value, @optional in T busy);
}

/// DirectRegister
extern DirectRegister<T> {
    /// Instantiate an array of direct registers. The initial value is
    /// undefined.
    DirectRegister();

    /// Initialize an array of direct registers and set their value to
    /// initial_value.
    DirectRegister(T initial_value);

    /// Return the value of the direct register.
    T read();

    /// Write value to a direct register.
    void write(in T value);

    /// Write a value to every element of the register
    void clear(in T value, @optional in T busy);
}

extern RegisterParam<T> {
    /// Construct a read-only run-time configurable parameter that can only be
    /// used by RegisterAction.
    /// @param initial_value : initial value of the parameter.
    RegisterParam(T initial_value);

    /// Return the value of the parameter.
    T read();
}

enum MathOp_t {
    MUL, // 2^scale * f(x)         --  false,  0
    SQR, // 2^scale * f(x^2)       --  false,  1
    SQRT, // 2^scale * f(sqrt(x))   --  false, -1
    DIV, // 2^scale * f(1/x)       --  true,   0
    RSQR, // 2^scale * f(1/x^2)     --  true,   1
    RSQRT // 2^scale * f(1/sqrt(x)) --  true,  -1
};

extern MathUnit<T> {
    /// Configure a math unit for use in a register action
    MathUnit(bool invert, int<2> shift, int<6> scale,
             // Note: data tuple contains values in order from 15..0 (reversed)
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, int factor); // configure as factor * op(x)
    MathUnit(MathOp_t op, int A, int B); // configure as (A/B) * op(x)
    T execute(in T x);
};

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);
    U execute(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout T value, @optional out U rv, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction2<T, U1, U2> {
    DirectRegisterAction2(DirectRegister<T> reg);
    U1 execute(out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction3<T, U1, U2, U3> {
    DirectRegisterAction3(DirectRegister<T> reg);
    U1 execute(out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction4<T, U1, U2, U3, U4> {
    DirectRegisterAction4(DirectRegister<T> reg);
    U1 execute(out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

@noWarn("unused")
extern RegisterAction<T, H, U> {
    RegisterAction(Register<_, _> reg);
    U execute(@optional in H index, @optional out U rv2,
              @optional out U rv3, @optional out U rv4);

    U execute_log(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    U enqueue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo push */
    U dequeue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo pop */
    U push(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack push */
    U pop(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack pop */
    /// execute the action on every entry in the register
    void sweep(@optional in U busy);
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop, sweep)
    abstract void apply(inout T value, @optional out U rv1, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value,
                                     @optional out U rv1, @optional out U rv2,
                                     @optional out U rv3, @optional out U rv4);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value,
                                      @optional out U rv1, @optional out U rv2,
                                      @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction2<T, H, U1, U2> {
    RegisterAction2(Register<_, _> reg);
    U1 execute(in H index, out U2 rv2);

    U1 execute_log(out U2 rv2);
    U1 enqueue(out U2 rv2); /* fifo push */
    U1 dequeue(out U2 rv2); /* fifo pop */
    U1 push(out U2 rv2); /* stack push */
    U1 pop(out U2 rv2); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value, out U1 rv1, out U2 rv2);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value, out U1 rv1, out U2 rv);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction3<T, H, U1, U2, U3> {
    RegisterAction3(Register<_, _> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3);

    U1 execute_log(out U2 rv2, out U3 rv3);
    U1 enqueue(out U2 rv2, out U3 rv3); /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3); /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3); /* stack push */
    U1 pop(out U2 rv2, out U3 rv3); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value, out U1 rv1, out U2 rv2, out U3 rv3);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction4<T, H, U1, U2, U3, U4> {
    RegisterAction4(Register<_, _> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3, out U4 rv4);

    U1 execute_log(out U2 rv2, out U3 rv3, out U4 rv4);
    U1 enqueue(out U2 rv2, out U3 rv3, out U4 rv4); /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3, out U4 rv4); /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3, out U4 rv4); /* stack push */
    U1 pop(out U2 rv2, out U3 rv3, out U4 rv4); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value,
                                     out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value,
                                      out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

extern LearnAction<T, H, D, U> {
    LearnAction(Register<T, H> reg);
    U execute(in H index, @optional out U rv2, @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        @optional out U rv1, @optional out U rv2,
                        @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction2<T, H, D, U1, U2> {
    LearnAction2(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction3<T, H, D, U1, U2, U3> {
    LearnAction3(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction4<T, H, D, U1, U2, U3, U4> {
    LearnAction4(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

extern MinMaxAction<T, H, U> {
    MinMaxAction(Register<T, _> reg);
    U execute(@optional in H index, @optional out U rv2,
              @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, @optional out U rv1, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<8> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<8> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<8> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<8> postmod);
}
extern MinMaxAction2<T, H, U1, U2> {
    MinMaxAction2(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
}
extern MinMaxAction3<T, H, U1, U2, U3> {
    MinMaxAction3(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
}
extern MinMaxAction4<T, H, U1, U2, U3, U4> {
    MinMaxAction4(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
}

extern ActionProfile {
    /// Construct an action profile of 'size' entries.
    ActionProfile(bit<32> size);
}

extern ActionSelector {
    /// Construct a selection table for a given ActionProfile.
    ActionSelector(ActionProfile action_profile,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   bit<32> max_group_size,
                   bit<32> num_groups);

    /// Stateful action selector.
    ActionSelector(ActionProfile action_profile,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   Register<bit<1>, _> reg,
                   bit<32> max_group_size,
                   bit<32> num_groups);

    /// Construct a selection table for action profile of 'size' entries.
    @deprecated("ActionSelector must be specified with an associated ActionProfile")
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);

    @deprecated("ActionSelector must be specified with an associated ActionProfile")
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode, Register<bit<1>, _> reg);
}

extern SelectorAction {
    SelectorAction(ActionSelector sel);
    bit<1> execute(@optional in bit<32> index);
    @synchronous(execute)
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
}

extern Mirror {
    /// Constructor
    @deprecated("Mirror must be specified with the value of the mirror_type instrinsic metadata")
    Mirror();

    /// Constructor
    Mirror(MirrorType_t mirror_type);

    void emit(in MirrorId_t session_id);

    /// Write @hdr into the ingress/egress mirror buffer.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in MirrorId_t session_id, in T hdr);
}

/// Tofino supports packet resubmission at the end of ingress pipeline. When
/// a packet is resubmitted, the original packet reference and some limited
/// amount of metadata (64 bits) are passed back to the packet’s original
/// ingress buffer, where the packet is enqueued again.
extern Resubmit {
    /// Constructor
    @deprecated("Resubmit must be specified with the value of the resubmit_type instrinsic metadata")
    Resubmit();

    /// Constructor
    Resubmit(ResubmitType_t resubmit_type);

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in T hdr);
}

extern Digest<T> {
    /// define a digest stream to the control plane
    @deprecated("Digest must be specified with the value of the digest_type instrinsic metadata")
    Digest();

    /// constructor.
    Digest(DigestType_t digest_type);

    /// Emit data into the stream.  The p4 program can instantiate multiple
    /// Digest instances in the same deparser control block, and call the pack
    /// method once during a single execution of the control block
    void pack(in T data);
}

/// Tofino2 supports packet generation at the end of ingress pipeline. Packet
/// Generation can be triggered by MAU, some limited amount of metadata (128 bits)
/// can be prepended to the generated packet.
extern Pktgen {
    Pktgen();

    /// Define the prefix header for the generated packet.
    /// @param hdr : T can be a header type, a header stack, a header union,
    /// or a struct contains fields with such types.
    void emit<T>(in T hdr);
}

// Algorithmic TCAM.
// Specify the implementation of a table to be algorithmic TCAM by providing an
// instance of the extern to the 'implementation' attribute of the table.  User
// must also specify one of the table keys with 'atcam_partition_index'
// match_kind.
extern Atcam {
    /// define the parameters for ATCAM table.
    Atcam(@optional bit<32> number_partitions);
}

// Algorithmic LPM.
// Specify the implementation of a table to be algorithmic LPM by providing an
// instance of the extern to the 'implementation' attribute of the table.
extern Alpm {
    /// define the parameters for ALPM table.
    Alpm(@optional bit<32> number_partitions, @optional bit<32> subtrees_per_partition,
         @optional bit<32> atcam_subset_width, @optional bit<32> shift_granularity);
}
# 29 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/tofino2_arch.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino2.

parser IngressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr);

parser EgressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md,
    @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);

control IngressT<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional in ghost_intrinsic_metadata_t gh_intr_md);

control GhostT(in ghost_intrinsic_metadata_t gh_intr_md);

control EgressT<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional in ingress_intrinsic_metadata_t ig_intr_md);

control EgressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParserT<IH, IM> ingress_parser,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParserT<EH, EM> egress_parser,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser,
    @optional GhostT ghost);

@pkginfo(arch="T2NA", version="1.0.1")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 25 "/barefoot/bf-sde-9.11.0/install/share/p4c/p4include/t2na.p4" 2
# 6 "bfs.p4" 2


/*
* The EM tables do not need to be larger than the priority filter
* main table size of 2048 - 11 bits
*/
typedef bit<11> exact_match_id_ip_t; //2048  2**11
typedef bit<11> exact_match_id_mac_t; //2048  2**11
typedef bit<8> exact_match_id_ethertype_t;

/*
* Table sizes for both qualifiers and the final match table
*/
# 45 "bfs.p4"
/* Please note that we have 128 ports*4096 VLANs per port,
 * but we are only reserving 4K entries in the table as it
 * takes extra stage for bigger tables. This is a Exact
 * Match table, which means hashing will be used to index
 * to the entry in the table. The lower the size the higher
 * chances of collisions. We will revisit the table size
 * later.
 */





/*
 * DF based PS+ Header stripping on priority image is implemented based on
 * multicast ID in the inegress, so the entries are added on all 4 pipes
 * all the time. The size is adjsted to account for the worst case scenario
 */
# 82 "bfs.p4"
/*
* Number of bits for each match id in final match table.
* 2**SZ = the number of different match ids. Because vrf
* is part of the lookup, this is per vrf.
*/
# 99 "bfs.p4"
# 1 "./headers.p4" 1
/* NETWORKS CONFIDENTIAL & PROPRIETARY
*
* Copyright (c) 2015-2020 Barefoot Networks, Inc.
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



typedef bit<8> pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;




typedef bit<4> mirror_type_t;

const mirror_type_t MIRROR_TYPE_I2E = 1;







typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<96> ipv6_addr_t_96;
typedef bit<64> ipv6_addr_64_t;
typedef bit<16> ether_type_t;

const ether_type_t ETHERTYPE_KNET = 16w0x9000;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_ETAG = 16w0x893F;
const ether_type_t ETHERTYPE_VNTAG = 16w0x8926;
const ether_type_t ETHERTYPE_PPPOE = 16w0x8864;
const ether_type_t ETHERTYPE_PBBTE = 16w0x88E7;
const ether_type_t ETHERTYPE_ETHERNET = 16w0x6558;
const ether_type_t ETHERTYPE_INVALID = 16w0x0000;
const ether_type_t ETHERTYPE_ERSPAN_II = 16w0x88BE;
const ether_type_t ETHERTYPE_ERSPAN_III = 16w0x22EB;
const ether_type_t ETHERTYPE_FABRIC_PATH= 16w0x8903;
const ether_type_t ETHERTYPE_MPLS_UNICAST = 16w0x8847;
const ether_type_t ETHERTYPE_MPLS_MULTICAST = 16w0x8848;

typedef bit<16> gre_proto_t;
const gre_proto_t GRE_PROTO_ETHERNET = 16w0x6558;

typedef bit<16> tpid_t;
const tpid_t TPID_0x8100 = 16w0x8100;
const tpid_t TPID_0x88A8 = 16w0x88a8;
const tpid_t TPID_0x9100 = 16w0x9100;
const tpid_t TPID_0x9200 = 16w0x9200;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_SCTP = 132;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_IPV6_FRAG = 44;

typedef bit<16> pppoe_protocol_t;
const pppoe_protocol_t PPPOE_PROTOCOL_IPV4 = 0x21;
const pppoe_protocol_t PPPOE_PROTOCOL_IPV6 = 0x57;

typedef bit<16> udp_port_t;
const udp_port_t UDP_PORT_GENEVE = 6081;
const udp_port_t UDP_PORT_STD_VXLAN = 4789;
const udp_port_t UDP_PORT_CISCO_VXLAN = 48879;
const udp_port_t UDP_PORT_KVM_VXLAN = 8472;
const udp_port_t UDP_PORT_GTPC = 2123;
const udp_port_t UDP_PORT_GTPU = 2152;
const udp_port_t UDP_PORT_LISP = 4341;
const udp_port_t UDP_PORT_MPLS = 6635;
const bit<14> MAX_MTU_SIZE = 10240;

enum bit<4> hash_type_t {
    HASH_TYPE_RANDOM = 0, //Random
    HASH_TYPE_PACKET_TYPE = 1,
    HASH_TYPE_SRC_IP_ONLY = 2, //SRC IP
    HASH_TYPE_DST_IP_ONLY = 3, //DST IP
    HASH_TYPE_LAYER2 = 4, //SRC MAC, DST MAC, ETHERTYPE
    HASH_TYPE_INNER_PACKET_TYPE = 5
}

enum bit<4> packet_type_t {
     PACKET_TYPE_ETHERNET = 0,
     PACKET_TYPE_L2GRE = 1,
     PACKET_TYPE_L3GRE = 2,
     PACKET_TYPE_ERSPAN = 3,
     PACKET_TYPE_VXLAN = 4,
     PACKET_TYPE_GENEVE = 5,
     PACKET_TYPE_PPPOE = 6,
     PACKET_TYPE_MPLS_PW = 7,
     PACKET_TYPE_MPLS_L3VPN = 8,
     PACKET_TYPE_GTP = 9,
     PACKET_TYPE_LISP = 10,
     PACKET_TYPE_PBB_TE = 11,
     PACKET_TYPE_OTV = 12,
     PACKET_TYPE_IP_IN_IP = 13
}

enum bit<2> inner_ether_type_t {
     INNER_ETHER_TYPE_NONE = 0,
     INNER_ETHER_TYPE_IPV4 = 1,
     INNER_ETHER_TYPE_IPV6 = 2
}

/*Time Stamp configs*/





/*Time Stamp header values per standard*/





/* structs used by 16Sec/32nSec counter conversion */
struct pair32 {
    bit<32> nsec;
    bit<32> sec;
 }

struct pair16 {
    bit<16> val1;
    bit<16> val2;
 }
# 172 "./headers.p4"
header mac_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

header ethertype_h {
   ether_type_t ether_type;
}

header vlan_tag_h {
    tpid_t tpid;
    bit<16> vlan; //3 bits PCP + 1 bit CFI/DE + 12 bits VID
}

header fabricpath_h {
    bit<6> endnode_id;
    bit<1> univ_local;
    bit<1> indiv_group;
    bit<2> endnode_idx;
    bit<1> rsvd;
    bit<1> ooo_dl;
    bit<12> switch_id;
    bit<8> subswitch_id;
    bit<16> port_id;
    bit<48> srcAddr;
    bit<16> etherType;
    bit<10> ftag;
    bit<6> ttl;
}

header vntag_h {
    ether_type_t type;
    bit<2> Version;
    bit<1> dbit;
    bit<1> ptr_bit;
    bit<12> dest_vif;
    bit<1> looped;
    bit<3> rsvd;
    bit<12> src_vif;
}

//802.1 BR
header etag_h {
    ether_type_t type;
    bit<3> e_pcp;
    bit<1> e_dei;
    bit<12> ingress_cid_base;
    bit<2> reserved;
    bit<2> grp;
    bit<12> e_cid_base;
    bit<8> ingress_cid_ext;
    bit<8> e_cid_ext;
}

//IEEE 802.1ah PBB Frame
header pbbte_h {
    bit<3> pcp;
    bit<1> dei;
    bit<1> uca;
    bit<3> reserved;
    bit<24> i_sid;
}

header pppoe_h {
    bit<4> version;
    bit<4> type;
    bit<8> code;
    bit<16> session_id;
    bit<16> length;
    bit<16> protocol;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_pwe_cw_h {
    bit<32> data;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header ipv6_frag_h {
    bit<8> next_hdr;
    bit<8> reserved;
    bit<13> frag_offset;
    bit<2> reserved1;
    bit<1> more_frag;
    bit<32> identification;
}

struct l4_common_header_t {
    bit<16> srcport_typecode; //Src Port for TCP/UDP & Type_Code for ICMP/IGMP
    bit<16> dstport_chksum; //Dst Port for TCP/UDP & Checksum  for ICMP/IGMP
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348 -- will be reused for GENEVE as well
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

header gre_data1_h {
    bit<32> data;
}

header gre_data2_h {
    bit<64> data;
}

header gre_data3_h {
    bit<96> data;
}

// GTP User Data Messages (GTPv1)
//Reusing the same header for LISP Parsing as well as they are same size
// RFC 6830 - The Locator/ID Separation Protocol (LISP)
header gtpu_h {
    bit<3> version;
    bit<1> pt; // Protocol type
    bit<1> reserved;
    bit<1> e; // Extension header flag
    bit<1> s; // Sequence number flag
    bit<1> pn; // N-PDU number flag
    bit<8> message_type;
    bit<16> message_len;
    bit<32> teid; // Tunnel endpoint id */
}

// GTP-U Extension header
header gtpu_ext_h {
    bit<16> rsvd1;
    bit<16> rsvd2;
}

/*Following 3 headers are taken from Inband Network Telemetry (INT)
 *Dataplane specification version 2.1 from p4.org*/

/*4 Bytes of INT shim header that appears between TCP/UDP header and
 *denotes start of INT metadata info.*/
header int_shim_tcp_udp_h {
    bit<4> type; //INT-MD for now = 1
    bit<2> npt; //Next protocol header=1 as original payload follows
    bit<2> res1;
    bit<8> length; //len of following INT info in words
    bit<16> orig_port; //to copy original destination port (TCP or UDP)
}

/*12 Bytes of INT header which conveys how many chunks of INT metadata follow*/
header int_header_h {
    bit<4> ver; //set to 2 - curret INT standard
    bit<3> flags; //D,E,M - set to 0 - need to set
                              //if Discard by Sink, hop count,
                              //MTU exceeded.
    bit<12> res;
    bit<5> hop_ml; //per hop Meta data length.
         //1 per meta-data
    bit<8> rem_hop_cnt; //decremented by each hop
    bit<16> instruction_bm; //set bit 4 for ingress time stamp,
         //bit 5 for egress time stamp.
    bit<16> ds_id; //Domain specific id - future
    bit<16> ds_inst; //DS instruction - future
    bit<16> ds_flags; //DS flags - 0 for now
}

/*Actual metadata size for TS in INT header is 64 bits,
 *but barefoot provides 48 bit info for now*/
header int_ts_metadata_h {
    bit<16> pad;
    bit<48> ts;
}

header mirror_h {
    pkt_type_t pkt_type;
}

header pad_h {
    bit<(64 * 8)> data;
}

typedef bit<4> header_type_t;
typedef bit<3> header_info_t;

const header_type_t HEADER_TYPE_BRIDGE = 0xB;





header internal_header_h {
    header_type_t header_type; header_info_t header_info;
    bit<1> _Pad;
}

// Metadata used in ingress AND egress, carried in pkt hdr through the TM
// TODO - divvy up between IG, EG and brieged MD to minimize allocations for each.
header bridged_metadata_t {
    header_type_t header_type; header_info_t header_info;
    PortId_t ingress_port;
    bit<2> vlan_config;
    /*
     * If the header stripping is performed in the ingress and the resulted packet
     * is a pure L2 packet(without L3 header), we can't calculate the packet length
     * based on all possible combinations, so we will use this bit in the encap table
     * to not perform tunnel origination on these packets
     */
    bool hdr_stripping;
    /*
     * This will be used to carry the DF based config like VLAN replacement,
     * VLAN tagging, VLAN stripping, PS+ stripping etc., to the egress pipeline
     * for unicast traffic.
     * 0 - None
     * 1 - VLAN Tagging
     * 2 - VLAN Stripping
     * 3 - VLAN Replacement
     * 4 - PS+ stripping
     * 5 - DM Config
     */
    bit<3> df_config;
    /*
     * This bit will be used for cases when HDR stripping and VLAN tagging
     * or replacement are set at the same time on a DF
     */
    bit<1> vlan_stripping;
    bit<1> parse_mac_vlan_only;

    //To carry ingress time stamp as processing is in egress
    bit<48> ts;

    /*
     * This will carry the value of VLAN or PS+ stripping options or DM config when df_config is used
     */
    bit<16> df_config_value;
    bit<16> knet_mark;
}


struct ingress_header_t
{
    @flexible
    bridged_metadata_t br_md;
    fabricpath_h fabric_path;
    mac_h mac;
    vlan_tag_h tagging_vlan_tag; //This will be used for port tagging in the ingress and adding VLAN for NetServices in the egress
    vlan_tag_h[3] vlan_tag; // We will be able to parse upto 3 VLANs in the outer header, can be adjusted later if needed
//    etag_h etag;
//    vntag_h vntag;
    ethertype_h ether_II;






    ipv4_h ipv4;
    ipv6_h ipv6;
    ipv6_frag_h ipv6_frag;
//    gre_h gre;
    /*
     * This is for the optional Checksum,  sequence number & Key fields
     * Varbit is not fully implemented in Tofino and having this as
     * array causes stage allocation error during stripping(setInvalid())
     */
//    gre_data1_h gre_data1;
//    gre_data2_h gre_data2;
//    gre_data3_h gre_data3;
//    gre_data3_h erspan_data3; // Do not change the order. This is needed for ERSPAN EtherType III to work with optional platform header
//    gre_data2_h erspan_data2;
    tcp_h tcp;
    udp_h udp;
//    mpls_h[5] mpls;
//    mpls_pwe_cw_h mpls_cw;
//    vxlan_h vxlan;
//    gtpu_h gtpu;
//    gtpu_ext_h[5] gtp_ext; //Used for GTP extension header as well as GENEVE optional headers
//    mac_h inner_mac;
//    vlan_tag_h[2] inner_vlan_tag; // We will be able to parse upto 2 inner VLANs
//    ethertype_h inner_ether_II;
//    ipv4_h inner_ipv4;
//    ipv6_h inner_ipv6;
//    tcp_h inner_tcp;
//    udp_h inner_udp;
    // Add more headers here.
}
# 599 "./headers.p4"
struct egress_header_t
{
    @flexible
    //tnl_* are for the L2GRE/VxLAN tunnel origination cases
    //They are only used in the Egress
    mac_h tnl_mac;
    vlan_tag_h tnl_vlan_tag;
    ethertype_h tnl_ether_II;
    ipv4_h tnl_ipv4;
    gre_h tnl_gre;
    gre_data1_h tnl_gre_key; //For Key Field
    gre_data1_h tnl_gre_seq; //For Sequence Number Field
    udp_h tnl_udp;
    vxlan_h tnl_vxlan;
    fabricpath_h fabric_path;
    mac_h mac;
    vlan_tag_h outer_vlan_tag; //For KVO VLAN tagging cases 
    vlan_tag_h[3] vlan_tag; // We will be able to parse upto 3 VLANs in the outer header, can be adjusted later if needed
    etag_h etag;
    vntag_h vntag;
    ethertype_h ether_II;






    ipv4_h ipv4;
    ipv6_h ipv6;
    ipv6_frag_h ipv6_frag;
    gre_h gre;
    /*
     * This is for the optional Checksum,  sequence number & Key fields
     * Varbit is not fully implemented in Tofino and having this as
     * array causes stage allocation error during stripping(setInvalid())
     */
    gre_data1_h gre_data1;
    gre_data2_h gre_data2;
    gre_data3_h gre_data3;
    gre_data3_h erspan_data3; // Do not change the order. This is needed for ERSPAN EtherType III to work with optional platform header
    gre_data2_h erspan_data2;
    tcp_h tcp;
    udp_h udp;
    mpls_h[5] mpls;
    mpls_pwe_cw_h mpls_cw;
    vxlan_h vxlan;
    gtpu_h gtpu;
    gtpu_ext_h[5] gtp_ext; //Used for GTP extension header as well as GENEVE optional headers
    pad_h pad;
    mac_h inner_mac;
    vlan_tag_h inner_vlan_tag; // We will be able to parse upto 2 inner VLANs

}
# 708 "./headers.p4"
struct empty_header_t {}

struct egress_metadata_t {
    bridged_metadata_t br_md;
    l4_common_header_t l4_outer_info;
    bit<16> outer_vlan;
    bit<16> inner_vlan;
    bit<8> port_class_id;
    bit<8> ip_protocol;
    //Byte boundary
    bool hdr_stripping_enable;
    /*
     * This bit controls whether padding is done with 64 bytes or 68 bytes.
     * When Ignore VLAN option is used with PS attachments, setting this
     * bit on tool port config table, will make the min packet size as 68
     * instead of usual 64 bytes
     */
    bool extra_pad_bytes;
    /*
     * Set to true when the packet is padded to differentiate from an packet 
     * that is not padded
     */
    bool padded_pkt;
    /*
     * This is used to track how many VLANs are added or removed by DF.
     * 0 - No VLAN got added or removed
     * 1 - 1 VLAN got stripped 
     * 2 - 2 VLANs got stripped
     * 3 - 1 VLAN got added 
     */
    bit<2> df_vlans_stripped;
    bit<1> dedup_enable;
    bit<2> reserved;
    //Byte boundary
    bool outer_vlan_valid;
    bool inner_vlan_valid;
    bool ipv4_valid;
    bit<1> outer_first_fragment;
    bit<1> single_vlan_stripping;
    bit<1> double_vlan_stripping;
    inner_ether_type_t inner_ether_type;
    //Byte boundary
    bool ipv6_valid;





    bit<3> reserved1;

    packet_type_t packet_type;
    /*
     * Length value from IPv4 or IPv6 headers
     */
    bit<16> pkt_len;
    //Byte boundary





}

//Port Meta Data definition
/*
 * Please note that each individual fields are rounded up to
 * the nearest 8 bit boundary. For example bit<1> and bit<7>
 * will both get 8 byte allocated in the table.
*/
struct port_metadata_t {
    /*
     * bits 0 - 7  : VRF ID
     */
    bit<8> vrf;

     /*
     * bits 0 - 7 : port class ID. Currently for NPFilters.
     */
    bit<8> port_class_id;

    /*
     * bits 0 - 11 : VLAN ID
     *
     * Standard VLAN action value of bits 12 - 14:
     * 0 - None
     * 1 - Port Tagging with 0x8100
     * 2 - Single VLAN Stripping
     * 3 - Double VLAN Stripping
     * 4 - Port Tagging with 0x88A8
     *
     * bit 12 - 14 : Standard VLAN action
     * bit 15 : Reserved, can be reused later
     */
    bit<16> vlan_config;

    /*
     * bit 0 - 14 :	Reserved for future use
     * bit 15:	Set to 1 when any of the stripping option is enabled
     */
    bit<16> hdr_strip_options;

    bit<8> filter_vrf;

    /*
     * bits 0-7: Reserved for future use
     * Using below port_options in the p4 code adds extra stage
     * in the ingress pipeline.
     */
    bit<8> port_options;


    /* T2 has 24 bytes port metadata vs. 16 for T1 */
    bit<8> rsvd1;
    bit<8> rsvd2;

}

// Metadata used in ingress only
struct ingress_metadata_t {
    port_metadata_t port_config;



    bit<16> outer_vlan;
    bit<16> inner_vlan;
    /*
     * Reusing the srcport_typecode for hash_type during hash
     * calculation at the end of the pipeline as there is
     * no use for it at that time
     */
    l4_common_header_t l4_outer_info;
    l4_common_header_t l4_inner_info;
    bit<1> outer_first_fragment;
    bit<1> inner_first_fragment;
    bool outer_vlan_valid;
    bool inner_vlan_valid;
    packet_type_t packet_type;
    bit<1> npf_l2_match; // network port filter l2 match used in ip lookups
    bit<1> npf_l3_match; // network port filter outer l3 match used in ip lookups
    bool hash_enable;
    bool hash_mpls_include;
    inner_ether_type_t inner_ether_type;
    bit<1> ipv6_no_frag;
    bit<1> ipv6_not_first_frag;
    bit<1> has_inner;
    bit<13> random_hash_value;
    bit<1> has_knet_mark;
    bit<2> _Pad1; //reserved
    ether_type_t hash_outer_ether_type;
    ether_type_t hash_inner_ether_type;
    bit<16> hash_outer_l4_srcport;
    bit<16> hash_outer_l4_dstport;
    bit<16> hash_inner_l4_srcport;
    bit<16> hash_inner_l4_dstport;

    /*
    * 64 bits used to carry either
    * - 32 v4 bits in bits [31:0]
    * - upper 64 bits of v6 in bits[63:0]
    */

    ipv6_addr_t ip_dst_addr;
    ipv6_addr_t ip_src_addr;

    ipv6_addr_t inner_ip_dst_addr;
    ipv6_addr_t inner_ip_src_addr;

    bit<8> port_group_id;
    bit<8> ip_protocol;
    bit<8> inner_ip_protocol;
    bit<8> dsTc;
    pkt_type_t pkt_type;

    bit<32> pktGap_ingress;
    bit<32> ns_ingress;

}
# 100 "bfs.p4" 2

typedef bit<64> PacketByteCounter_t;
typedef bit<32> StatIndex_t;
@pa_parser_group_monogress



// These are the match ids that will be used the the final master
struct final_match_table_metadata_t {
 bit<11> outer_mac_src_matchid;
 bit<11> outer_mac_dst_matchid;
 bit<8> l2_outer_ethertype_matchid;
 bit<8> l2_inner_ethertype_matchid;
 bit<11> outer_outer_vlan_matchid;
 bit<11> outer_inner_vlan_matchid;
 bit<11> inner_outer_vlan_matchid;
 bit<11> inner_inner_vlan_matchid;
 bit<11> outer_ipv4_src_matchid;
 bit<11> outer_ipv4_dst_matchid;
 bit<11> inner_ipv4_src_matchid;
 bit<11> inner_ipv4_dst_matchid;
 bit<8> outer_ip_prot_matchid;
 bit<8> inner_ip_prot_matchid;
 bit<3> outer_ip_frag_matchid;
 bit<8> outer_ip_dstc_matchid;
 bit<11> outer_ipv6_src_matchid;
 bit<11> outer_ipv6_dst_matchid;
 bit<11> inner_ipv6_src_matchid;
 bit<11> inner_ipv6_dst_matchid;
 bit<11> outer_l4_srcport_matchid;
 bit<11> outer_l4_dstport_matchid;
 bit<11> inner_l4_srcport_matchid;
 bit<11> inner_l4_dstport_matchid;
 bit<4> outer_tcp_control_matchid;
 bit<8> gtp_teid_matchid;
}
# 156 "bfs.p4"
# 1 "parde.p4" 1
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




# 1 "util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
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



# 1 "headers.p4" 1
/* NETWORKS CONFIDENTIAL & PROPRIETARY
*
* Copyright (c) 2015-2020 Barefoot Networks, Inc.
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
# 27 "util.p4" 2

parser TofinoIngressParser(
    packet_in pkt,
    out ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        ig_md.outer_first_fragment = 0;
        ig_md.inner_first_fragment = 0;
        ig_md.random_hash_value = 0;
        ig_md.hash_inner_l4_dstport = 0;
        ig_md.hash_inner_l4_srcport = 0;
        ig_md.hash_outer_l4_dstport = 0;
        ig_md.hash_outer_l4_srcport = 0;
        ig_md.ipv6_not_first_frag = 0;
        ig_md.hash_outer_ether_type = ETHERTYPE_INVALID;
        ig_md.hash_inner_ether_type = ETHERTYPE_INVALID;
        ig_md.packet_type = packet_type_t.PACKET_TYPE_ETHERNET;
        ig_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_NONE;
        ig_md.outer_vlan_valid = false;
        ig_md.inner_vlan_valid = false;
        ig_md.hash_mpls_include = false;
        ig_md.inner_ip_protocol = 0;
        ig_md.l4_outer_info = {0, 0};
        ig_md.l4_inner_info = {0, 0};
        ig_md.port_group_id = 0;






 /*
	* T2 has 24 bytes metadata, we define 8
	* was having compile problems assigning
	* as array
	*/
 ig_md.port_config.vrf=0;
 ig_md.port_config.port_class_id=0;
 ig_md.port_config.vlan_config=0;
 ig_md.port_config.hdr_strip_options=0;
        ig_md.port_config.filter_vrf=0;
 ig_md.port_config.port_options=0;
 ig_md.port_config.rsvd1=0;
 ig_md.port_config.rsvd2=0;

        ig_md.hash_enable = false;
        ig_md.npf_l2_match = 0;
        ig_md.npf_l3_match = 0;
        ig_md.ipv6_no_frag = 0;
        ig_md.ip_protocol = 0;
        ig_md.outer_vlan = 0;
        ig_md.inner_vlan = 0;
        ig_md.has_inner = 0;
        ig_md.has_knet_mark = 0;
        ig_md._Pad1 = 0;
 ig_md.ip_dst_addr = 0;
 ig_md.ip_src_addr = 0;
 ig_md.inner_ip_dst_addr=0;
 ig_md.inner_ip_src_addr=0;
 ig_md.dsTc=0;
        ig_md.pkt_type=0;

        ig_md.pktGap_ingress=0;
        ig_md.ns_ingress=0;

        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        ig_md.port_config = port_metadata_unpack<port_metadata_t>(pkt);
        transition accept;
    }
}

parser TofinoEgressParser(
    packet_in pkt,
    out egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    internal_header_h int_hdr;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        eg_md.dedup_enable = 0;
        eg_md.single_vlan_stripping = 0;
        eg_md.double_vlan_stripping = 0;
        eg_md.outer_first_fragment = 0;
        eg_md.hdr_stripping_enable = false;
        eg_md.port_class_id = 0;
        eg_md.ip_protocol = 0;
        eg_md.outer_vlan_valid = false;
        eg_md.inner_vlan_valid = false;
        eg_md.packet_type = packet_type_t.PACKET_TYPE_ETHERNET;
        eg_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_NONE;
        eg_md.l4_outer_info = {0, 0};
# 141 "util.p4"
        eg_md.reserved1 = 0;

        eg_md.outer_vlan = 0;
        eg_md.inner_vlan = 0;
        eg_md.ipv4_valid = false;
        eg_md.ipv6_valid = false;
        eg_md.extra_pad_bytes = false;
        eg_md.padded_pkt = false;
        eg_md.reserved = 0;
        eg_md.df_vlans_stripped = 0;
        eg_md.pkt_len = 0;

        int_hdr = pkt.lookahead<internal_header_h>();
        transition select(int_hdr.header_type, int_hdr.header_info) {
            ( HEADER_TYPE_BRIDGE, _ ) : parse_bridge;
            default : reject; // Mirror header types can be added later
        }
    }

    state parse_bridge {
        pkt.extract(eg_md.br_md);
        transition accept;
    }
}

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 27 "parde.p4" 2

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(
    packet_in pkt,
    out ingress_header_t hdr,
    out ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_md, ig_intr_md);
        transition select((pkt.lookahead<bit<112>>())[15:0]) {
            ETHERTYPE_FABRIC_PATH : parse_fabric_path;
            default : parse_mac;
        }
    }

    state parse_fabric_path {
        pkt.extract(hdr.fabric_path);
        transition parse_mac;
    }

    state parse_mac {
        pkt.extract(hdr.mac);

        transition select(ig_md.port_config.hdr_strip_options[14:14]) {
            0 : parse_mac_vlan_no_skip;
            1 : parse_mac_vlan_only;
        }
     }

     state parse_mac_vlan_only {
         hdr.br_md.parse_mac_vlan_only = 1;
        transition select(pkt.lookahead<bit<16>>()) {
            ETHERTYPE_KNET : parse_knet;
            TPID_0x88A8 : parse_vlan_accept;
            TPID_0x9200 : parse_vlan_accept;
            TPID_0x8100 &&& 0xEFFF: parse_vlan_accept; // 0x8100 & 0x9100
            default : parse_ether_type;
        }
     }

    state parse_vlan_accept {
        pkt.extract(hdr.vlan_tag.next);
        transition select(pkt.lookahead<bit<16>>()) {
            TPID_0x88A8 : parse_vlan_accept;
            TPID_0x9200 : parse_vlan_accept;
            TPID_0x8100 &&& 0xEFFF: parse_vlan_accept; // 0x8100 & 0x9100
            default : parse_ether_type;
        }
    }

     state parse_mac_vlan_no_skip {
        hdr.br_md.parse_mac_vlan_only = 0;

        transition select(pkt.lookahead<bit<16>>()) {
//            ETHERTYPE_ETAG        : parse_etag;
//            ETHERTYPE_VNTAG       : parse_vntag;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            // 0x8100/88A8/9100/9200 - no programmable TPIDS in the first release
            ETHERTYPE_KNET : parse_knet;
            TPID_0x88A8 : parse_vlan;
            TPID_0x9200 : parse_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_vlan; // 0x8100 & 0x9100
//            ETHERTYPE_MPLS_UNICAST: parse_mpls_etherII;
//            ETHERTYPE_MPLS_MULTICAST: parse_mpls_etherII;






            default : parse_ether_type;
        }
    }

    state parse_ether_type {
        pkt.extract(hdr.ether_II);
        transition accept;
    }

    state parse_knet {
        ig_md.has_knet_mark = 1;
        transition parse_vlan;
    }

/*    state parse_etag {
        pkt.extract(hdr.etag);
        ig_md.has_inner = 1;
        transition select(pkt.lookahead<bit<16>>()) {
            TPID_0x88A8           : parse_inner_vlan;
            TPID_0x9200           : parse_inner_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_inner_vlan; // 0x8100 & 0x9100
            ETHERTYPE_IPV4        : parse_inner_ipv4_1;
            ETHERTYPE_IPV6        : parse_inner_ipv6_1;
            default               : parse_inner_ether_type;
        }
    }
*/
/*    state parse_vntag {
        pkt.extract(hdr.vntag);
        ig_md.has_inner = 1;
        transition select(pkt.lookahead<bit<16>>()) {
            TPID_0x88A8           : parse_inner_vlan;
            TPID_0x9200           : parse_inner_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_inner_vlan; // 0x8100 & 0x9100
            ETHERTYPE_IPV4        : parse_inner_ipv4_1;
            ETHERTYPE_IPV6        : parse_inner_ipv6_1;
            default               : parse_inner_ether_type;
        }
    }
*/
    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(pkt.lookahead<bit<16>>()) {
//            ETHERTYPE_ETAG        : parse_etag;
//            ETHERTYPE_VNTAG       : parse_vntag;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            TPID_0x88A8 : parse_vlan;
            TPID_0x9200 : parse_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_vlan; // 0x8100 & 0x9100
//            ETHERTYPE_MPLS_UNICAST: parse_mpls_etherII;
//            ETHERTYPE_MPLS_MULTICAST: parse_mpls_etherII;






            default : parse_ether_type;
        }
    }
# 189 "parde.p4"
/*    state parse_mpls_etherII {
        pkt.extract(hdr.ether_II);
        transition parse_mpls;
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            1 : parse_ethernet_or_ip;
        }
    }


    state parse_ethernet_or_ip {
        //Check for MPLS L2VPN case first
        transition select((pkt.lookahead<bit<112>>())[15:0]) {
#ifdef PPPOE_SUPPORT
            ETHERTYPE_PPPOE       : parse_mpls_pw_inner_mac;
#endif
            ETHERTYPE_IPV4        : parse_mpls_pw_inner_mac;//untagged inner payload
            ETHERTYPE_IPV6        : parse_mpls_pw_inner_mac;//untagged inner payload
            TPID_0x88A8           : parse_mpls_pw_inner_mac;
            TPID_0x9200           : parse_mpls_pw_inner_mac;
            TPID_0x8100 &&& 0xEFFF: parse_mpls_pw_inner_mac; // 0x8100 & 0x9100
            default               : parse_cw_or_ip;
        }
    }

    state parse_mpls_pw_inner_mac {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_MPLS_PW;
        transition parse_inner_mac;
    }

    state parse_cw_or_ip {
        //Check for MPLS L2VPN case first
        transition select((pkt.lookahead<bit<144>>())[15:0]) {
#ifdef PPPOE_SUPPORT
            ETHERTYPE_PPPOE       : parse_mpls_cw_inner_mac;
#endif
            ETHERTYPE_IPV4        : parse_mpls_cw_inner_mac;
            ETHERTYPE_IPV6        : parse_mpls_cw_inner_mac;
            TPID_0x88A8           : parse_mpls_cw_inner_mac;
            TPID_0x9200           : parse_mpls_cw_inner_mac;
            TPID_0x8100 &&& 0xEFFF: parse_mpls_cw_inner_mac; // 0x8100 & 0x9100
            default               : parse_mpls_ip;
        }
    }

    state parse_mpls_cw_inner_mac {
        pkt.extract(hdr.mpls_cw);
        transition parse_mpls_pw_inner_mac;
    }

    state parse_mpls_ip {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_MPLS_L3VPN;
        ig_md.has_inner=1;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default : accept;
        }
    }
*/
    state parse_ipv4 {
        pkt.extract(hdr.ether_II);
        pkt.extract(hdr.ipv4);
        /*
        * Place the ipv4 address in the lower 32 bits of ingress metadata.
        * Currently used in NPF and PRIOR lookups only but can be extended
        * for other tables
        */
        ig_md.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        ig_md.ip_src_addr[31:0] = hdr.ipv4.src_addr;

        ig_md.ip_protocol = hdr.ipv4.protocol;

        transition select(hdr.ipv4.frag_offset,
                          hdr.ipv4.protocol,
                          hdr.ipv4.ihl) {
            (0, IP_PROTOCOLS_TCP , 5) : parse_tcp;
            (0, IP_PROTOCOLS_UDP , 5) : parse_udp;
//            (0, IP_PROTOCOLS_GRE , 5) : parse_gre;
            (0, IP_PROTOCOLS_ICMP, 5) : parse_icmp;
            (0, IP_PROTOCOLS_IGMP, 5) : parse_icmp;
//            (0, IP_PROTOCOLS_IPV6, 5) : parse_ipv6_in_ip;
//            (0, IP_PROTOCOLS_IPV4, 5) : parse_ipv4_in_ip;
            (0, _ , 5) : parse_first_fragment;
            default : accept;
        }
    }

/*    state parse_ipv6_in_ip {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_IP_IN_IP;
        ig_md.has_inner=1;
        transition parse_inner_ipv6;
    }

    state parse_ipv4_in_ip {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_IP_IN_IP;
        ig_md.has_inner=1;
        transition parse_inner_ipv4;
    }
*/
    /*
     * No need to extract the ICMP/IGMP headers, the common header has
     * information needed for filtering.
     */
    state parse_icmp {
        ig_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        ig_md.outer_first_fragment = 1;
        transition accept;
    }

    state parse_first_fragment {
        ig_md.outer_first_fragment = 1;
        transition accept;
    }

    /*
    * TODO
    * There can be multiple next headers so this needs to be handled similar to multiple vlan or mpls.
    * Also fragments need to be handled
    */

    state parse_ipv6 {
        pkt.extract(hdr.ether_II);
        pkt.extract(hdr.ipv6);
        ig_md.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.ip_protocol = hdr.ipv6.next_hdr;

        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_IPV6_FRAG : parse_ipv6_frag;
            default : parse_ipv6_no_frag;
        }
    }

    state parse_ipv6_no_frag {
        ig_md.ipv6_no_frag = 1;
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
//            IP_PROTOCOLS_GRE : parse_gre;
            IP_PROTOCOLS_ICMP: parse_icmp;
            IP_PROTOCOLS_IGMP: parse_icmp;
//            IP_PROTOCOLS_IPV6 : parse_ipv6_in_ip;
//            IP_PROTOCOLS_IPV4 : parse_ipv4_in_ip;
            default : accept;
        }
    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.frag_offset, hdr.ipv6_frag.next_hdr) {
            (0, IP_PROTOCOLS_TCP) : parse_tcp;
            (0, IP_PROTOCOLS_UDP) : parse_udp;
//            (0, IP_PROTOCOLS_GRE) : parse_gre;
//            (0, IP_PROTOCOLS_IPV6) : parse_ipv6_in_ip;
            (0, IP_PROTOCOLS_ICMP) : parse_icmp;
            (0, IP_PROTOCOLS_IGMP) : parse_icmp;
//            (0, IP_PROTOCOLS_IPV4) : parse_ipv4_in_ip;
            default : parse_ipv6_not_first_fragment;
        }
    }

    state parse_ipv6_not_first_fragment {
        ig_md.ipv6_not_first_frag = 1;
        transition accept;
    }

/*    state parse_gre {
        pkt.extract(hdr.gre);
        ig_md.outer_first_fragment = 1;
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S) {
            (1, 1, 1): parse_gredata_3;
            (1, 1, 0): parse_gredata_2;
            (1, 0, 1): parse_gredata_2;
            (0, 1, 1): parse_gredata_2;
            (1, 0, 0): parse_gredata_1;
            (0, 1, 0): parse_gredata_1;
            (0, 0, 1): parse_gredata_1;
            (0, 0, 0): parse_gre_proto;
        }
    }

    state parse_gredata_3 {
        pkt.extract(hdr.gre_data3); //Extract 3 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gredata_2 {
        pkt.extract(hdr.gre_data2); //Extract 2 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gredata_1 {
        pkt.extract(hdr.gre_data1); //Extract 1 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gre_proto {
        transition select(hdr.gre.R, hdr.gre.S, hdr.gre.proto) {
            (0, _, ETHERTYPE_IPV4      ): parse_gre_inner_ipv4;
            (0, _, ETHERTYPE_IPV6      ): parse_gre_inner_ipv6;
            (0, 0, ETHERTYPE_ERSPAN_II ): parse_type_erspan_I;
            (0, 1, ETHERTYPE_ERSPAN_II ): parse_type_erspan_II;
            (0, _, ETHERTYPE_ERSPAN_III): parse_erspan_III;
#ifdef INT_SUPPORT
            (0, _, ETHERTYPE_MPLS_UNICAST): parse_otv;
            (0, _, ETHERTYPE_MPLS_MULTICAST): parse_otv;
#else
            (0, _, ETHERTYPE_MPLS_UNICAST): parse_mpls;
            (0, _, ETHERTYPE_MPLS_MULTICAST): parse_mpls;
#endif
            (0, _, _                   ): parse_gre_inner_mac;
            default: accept; //We are not supporting GRE packets with R(Routing) bit set, so don't look further
        }
    }
*/
# 417 "parde.p4"
/*    state parse_gre_inner_mac {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_L2GRE;
        transition parse_inner_mac;
    }

    state parse_gre_inner_ipv4 {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_L3GRE;
        ig_md.has_inner=1;
        transition parse_inner_ipv4;
    }

    state parse_gre_inner_ipv6 {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_L3GRE;
        ig_md.has_inner=1;
        transition parse_inner_ipv6;
    }

    state parse_erspan_III {
        pkt.extract(hdr.erspan_data3); //Extract 3 * 32 bits
        //Check if there is a optional platform sub header 2*32 bits - bit [0]
        //FT bit 2 can be set to 1 for encapsulated IP packets - bit[12],
        //we are not supporting it, so not parsing those frames
        transition select(hdr.erspan_data3.data[0:0], hdr.erspan_data3.data[11:11]) {
            (0,0) : parse_erspan_III_inner_mac; //Optional sub header not present
            (1,0) : parse_type_erspan_II; //Optional platform header present, extract 2 * 32 bits
            default : accept; //when bit[12] is set, don't parse any further
                              //as we are not going to perform header stripping with inner IP packets
        }
    }

    state parse_type_erspan_II {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        ig_md.has_inner=1;
        transition parse_erspan_II;
    }

    state parse_erspan_III_inner_mac {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        ig_md.has_inner=1;
        transition parse_inner_mac;
    }

    state parse_erspan_II {
        pkt.extract(hdr.erspan_data2); //Extract 2 * 32 bits
        transition parse_inner_mac;
    }

    state parse_type_erspan_I {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        ig_md.has_inner=1;
        transition parse_inner_mac;
    }
*/
    state parse_udp {
        ig_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.udp);
        ig_md.outer_first_fragment = 1;
        transition accept;
//        transition select(hdr.udp.dst_port) {
//            UDP_PORT_GENEVE     : parse_geneve;
//            UDP_PORT_STD_VXLAN  : parse_vxlan;
//            UDP_PORT_CISCO_VXLAN: parse_vxlan;
//            UDP_PORT_KVM_VXLAN  : parse_vxlan;
//            UDP_PORT_GTPU       : parse_gtpu;
//            UDP_PORT_LISP       : parse_lisp_gtpu;

//            UDP_PORT_MPLS       : parse_mpls;

 //           default: accept;
//        }
    }

/*    state parse_geneve {
        //Parse GENEVE as VxLAN header only if it didn't have optional headers
        pkt.extract(hdr.vxlan);
        transition select(hdr.vxlan.flags) {
            0 : parse_geneve_vxlan;
            1 : parse_geneve_opt1;
            2 : parse_geneve_opt2;
            3 : parse_geneve_opt3;
            4 : parse_geneve_opt4;
            5 : parse_geneve_opt5;
            default : accept; //Don't parse the packet any further
        }
    }

    state parse_geneve_vxlan {
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt1 {
        pkt.extract(hdr.gtp_ext[0]);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt2 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt3 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt4 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        pkt.extract(hdr.gtp_ext[3]);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt5 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        pkt.extract(hdr.gtp_ext[3]);
        pkt.extract(hdr.gtp_ext[4]);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }
*/
    state parse_tcp {
        ig_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.tcp);
        transition parse_first_fragment;
    }

/*    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.packet_type = packet_type_t.PACKET_TYPE_VXLAN;
        transition parse_inner_mac;
    }
*/
//    state parse_inner_mac {
        /*
        * All Inner parsers will come here except for L3GRE and MPLS L3 VPNs
        */
/*        ig_md.has_inner=1;
        pkt.extract(hdr.inner_mac);
        transition select(pkt.lookahead<bit<16>>()) {
            ETHERTYPE_IPV4        : parse_inner_ipv4_1;
            ETHERTYPE_IPV6        : parse_inner_ipv6_1;
            TPID_0x88A8           : parse_inner_vlan;
            TPID_0x9200           : parse_inner_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_inner_vlan; // 0x8100 & 0x9100
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        transition select(pkt.lookahead<bit<16>>()) {
            ETHERTYPE_IPV4        : parse_inner_ipv4_1;
            ETHERTYPE_IPV6        : parse_inner_ipv6_1;
            TPID_0x88A8           : parse_inner_vlan;
            TPID_0x9200           : parse_inner_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_inner_vlan; // 0x8100 & 0x9100
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_ether_type {
        pkt.extract(hdr.inner_ether_II);
        transition accept;
    }

    // This is different from parse_inner_ipv4, this one performs inner Ether Type extraction additionally
    state parse_inner_ipv4_1 {
        pkt.extract(hdr.inner_ether_II);
        pkt.extract(hdr.inner_ipv4);
        /*
        * Place the ipv4 address in the lower 32 bits of ingress metadata.
        * Currently used in NPF and PRIOR lookups only but can be extended
        * for other tables
        */
/*        ig_md.inner_ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        ig_md.inner_ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        ig_md.inner_ip_protocol       = hdr.inner_ipv4.protocol;

        transition select(hdr.inner_ipv4.frag_offset,
                          hdr.inner_ipv4.protocol,
                          hdr.inner_ipv4.ihl) {
            (0, IP_PROTOCOLS_TCP , 5) : parse_inner_tcp;
            (0, IP_PROTOCOLS_UDP , 5) : parse_inner_udp;
            (0, IP_PROTOCOLS_ICMP, 5) : parse_inner_icmp;
            (0, IP_PROTOCOLS_IGMP, 5) : parse_inner_icmp;
            (0, _                , 5) : parse_inner_first_fragment;
            default : accept;
        }
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        transition select(hdr.gtpu.s, hdr.gtpu.pn, hdr.gtpu.e) {
            (0, 0, 0) : parse_gtpu_inner;
            (_, _, 0) : parse_gtpu_no_extn; 
            (_, _, 1) : parse_gtpu_check_extn; 
        }
   }

   state parse_gtpu_no_extn {
        pkt.extract(hdr.gtp_ext[0]);
        transition parse_gtpu_inner;
   }

   state parse_gtpu_check_extn {
        pkt.extract(hdr.gtp_ext[0]);
        transition select(hdr.gtp_ext[0].rsvd2[7:0]) {
            0       : parse_gtpu_inner;
            default : parse_gtpu_extn_length;
        }
   }
   
   state parse_gtpu_extn_length {
        pkt.extract(hdr.gtp_ext[1]);
        transition select(hdr.gtp_ext[1].rsvd1[15:8]) {
            1 : parse_gtpu_inner;
            2 : parse_gtpu_extn2;
            default: accept; // No parsing of other extn lengths
        }
   }

   state parse_gtpu_extn2 {
        pkt.extract(hdr.gtp_ext[2]);
        transition parse_gtpu_inner;
   }

   state parse_gtpu_inner {
        ig_md.has_inner=1;
        ig_md.packet_type = packet_type_t.PACKET_TYPE_GTP;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default:accept;
        }
    }

    state parse_lisp_gtpu {
        pkt.extract(hdr.gtpu);
        ig_md.has_inner=1;
        ig_md.packet_type = packet_type_t.PACKET_TYPE_LISP;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default:accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        /*
        * Place the ipv4 address in the lower 32 bits of ingress metadata.
        * Currently used in NPF and PRIOR lookups only but can be extended
        * for other tables
        */
/*        ig_md.inner_ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        ig_md.inner_ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        ig_md.inner_ip_protocol       = hdr.inner_ipv4.protocol;

        ig_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_IPV4;
        transition select(hdr.inner_ipv4.frag_offset,
                          hdr.inner_ipv4.protocol,
                          hdr.inner_ipv4.ihl) {
            (0, IP_PROTOCOLS_TCP , 5) : parse_inner_tcp;
            (0, IP_PROTOCOLS_UDP , 5) : parse_inner_udp;
            (0, IP_PROTOCOLS_ICMP, 5) : parse_inner_icmp;
            (0, IP_PROTOCOLS_IGMP, 5) : parse_inner_icmp;
            (0, _                , 5) : parse_inner_first_fragment;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        /*
        * Place the upper 64 bits of ipv6 address in metadata
        */
/*        ig_md.inner_ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.inner_ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.inner_ip_protocol = hdr.inner_ipv6.next_hdr;



        ig_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_IPV6;
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_ICMP : parse_inner_icmp;
            IP_PROTOCOLS_IGMP : parse_inner_icmp;
            default : accept;
        }
    }

    state parse_inner_ipv6_1 {
        pkt.extract(hdr.inner_ether_II);
        pkt.extract(hdr.inner_ipv6);
        /*
        * Place the upper 64 bits of ipv6 address in metadata
        */
/*        ig_md.inner_ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.inner_ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.inner_ip_protocol = hdr.inner_ipv6.next_hdr;

        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_ICMP : parse_inner_icmp;
            IP_PROTOCOLS_IGMP : parse_inner_icmp;
            default : accept;
        }
    }

    state parse_inner_first_fragment {
        ig_md.inner_first_fragment = 1;
        transition accept;
    }

    state parse_inner_icmp {
        ig_md.l4_inner_info = pkt.lookahead<l4_common_header_t>();
        ig_md.inner_first_fragment = 1;
        transition accept;
    }

    state parse_inner_udp {
        ig_md.l4_inner_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.inner_udp);
        ig_md.inner_first_fragment = 1;
        transition select(hdr.inner_udp.dst_port) {
            default: accept;
        }
    }

    state parse_inner_tcp {
        ig_md.l4_inner_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.inner_tcp);
        transition parse_inner_first_fragment;
    }
*/
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout ingress_header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
    packet_in pkt,
    out egress_header_t hdr,
    out egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;





    state start {
        tofino_parser.apply(pkt, eg_md, eg_intr_md);
        transition select((pkt.lookahead<bit<112>>())[15:0]) {
            ETHERTYPE_FABRIC_PATH : parse_fabric_path;
            default : parse_mac;
        }
    }

    state parse_fabric_path {
        pkt.extract(hdr.fabric_path);
        transition parse_mac;
    }

    state parse_mac {
        pkt.extract(hdr.mac);

        transition select(eg_md.br_md.parse_mac_vlan_only) {
            0 : parse_mac_vlan_no_skip;
            1 : parse_mac_vlan_only;
        }
     }

     state parse_mac_vlan_only {
        transition select(pkt.lookahead<bit<16>>()) {
            TPID_0x88A8 : parse_vlan_accept;
            TPID_0x9200 : parse_vlan_accept;
            TPID_0x8100 &&& 0xEFFF: parse_vlan_accept; // 0x8100 & 0x9100
            default : parse_ether_type;
        }
     }

    state parse_vlan_accept {
        pkt.extract(hdr.vlan_tag.next);
        transition select(pkt.lookahead<bit<16>>()) {
            TPID_0x88A8 : parse_vlan_accept;
            TPID_0x9200 : parse_vlan_accept;
            TPID_0x8100 &&& 0xEFFF: parse_vlan_accept; // 0x8100 & 0x9100
            default : parse_ether_type;
        }
    }

     state parse_mac_vlan_no_skip {

        transition select(pkt.lookahead<bit<16>>()) {
            ETHERTYPE_ETAG : parse_etag;
            ETHERTYPE_VNTAG : parse_vntag;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            // 0x8100/88A8/9100/9200 - no programmable TPIDS in the first release
            TPID_0x88A8 : parse_vlan;
            TPID_0x9200 : parse_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_vlan; // 0x8100 & 0x9100
            ETHERTYPE_MPLS_UNICAST: parse_mpls_etherII;
            ETHERTYPE_MPLS_MULTICAST: parse_mpls_etherII;






            default : parse_ether_type;
        }
    }

    state parse_ether_type {
        pkt.extract(hdr.ether_II);
        transition parse_pad;
    }

    state parse_etag {
        pkt.extract(hdr.etag);
        transition parse_pad;
    }

    state parse_vntag {
        pkt.extract(hdr.vntag);
        transition parse_pad;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(pkt.lookahead<bit<16>>()) {
            ETHERTYPE_ETAG : parse_etag;
            ETHERTYPE_VNTAG : parse_vntag;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            TPID_0x88A8 : parse_vlan;
            TPID_0x9200 : parse_vlan;
            TPID_0x8100 &&& 0xEFFF: parse_vlan; // 0x8100 & 0x9100
            ETHERTYPE_MPLS_UNICAST: parse_mpls_etherII;
            ETHERTYPE_MPLS_MULTICAST: parse_mpls_etherII;






            default : parse_ether_type;
        }
    }
# 919 "parde.p4"
    state parse_mpls_etherII {
        pkt.extract(hdr.ether_II);
        transition parse_mpls;
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            1 : parse_ethernet_or_ip;
        }
    }

    state parse_ethernet_or_ip {
        //Check for MPLS L2VPN case first
        transition select((pkt.lookahead<bit<112>>())[15:0]) {



            ETHERTYPE_IPV4 : parse_mpls_pw_inner_mac;//untagged inner payload
            ETHERTYPE_IPV6 : parse_mpls_pw_inner_mac;//untagged inner payload
            TPID_0x88A8 : parse_mpls_pw_inner_mac;
            TPID_0x9200 : parse_mpls_pw_inner_mac;
            TPID_0x8100 &&& 0xEFFF: parse_mpls_pw_inner_mac; // 0x8100 & 0x9100
            default : parse_cw_or_ip;
        }
    }

    state parse_mpls_pw_inner_mac {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_MPLS_PW;
        transition parse_inner_mac;
    }

    state parse_cw_or_ip {
        //Check for MPLS L2VPN case first
        transition select((pkt.lookahead<bit<144>>())[15:0]) {



            ETHERTYPE_IPV4 : parse_mpls_cw_inner_mac;
            ETHERTYPE_IPV6 : parse_mpls_cw_inner_mac;
            TPID_0x88A8 : parse_mpls_cw_inner_mac;
            TPID_0x9200 : parse_mpls_cw_inner_mac;
            TPID_0x8100 &&& 0xEFFF: parse_mpls_cw_inner_mac; // 0x8100 & 0x9100
            default : parse_mpls_ip;
        }
    }

    state parse_mpls_cw_inner_mac {
        pkt.extract(hdr.mpls_cw);
        transition parse_mpls_pw_inner_mac;
    }

    state parse_mpls_ip {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_MPLS_L3VPN;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ether_II);
        pkt.extract(hdr.ipv4);
        eg_md.ip_protocol = hdr.ipv4.protocol;
        eg_md.pkt_len = hdr.ipv4.total_len;
        transition select(hdr.ipv4.frag_offset,
                          hdr.ipv4.protocol,
                          hdr.ipv4.ihl) {
            (0, IP_PROTOCOLS_TCP, 5) : parse_tcp;
            (0, IP_PROTOCOLS_UDP, 5) : parse_udp;
     (0, IP_PROTOCOLS_SCTP, 5) : parse_sctp;
            (0, IP_PROTOCOLS_GRE, 5) : parse_gre;
            (0, IP_PROTOCOLS_ICMP, 5) : parse_icmp;
            (0, IP_PROTOCOLS_IGMP, 5) : parse_icmp;
            (0, IP_PROTOCOLS_IPV6, 5) : parse_ipv6_in_ip;
            (0, IP_PROTOCOLS_IPV4, 5) : parse_ipv4_in_ip;
            (0, _ , 5) : parse_first_fragment;
            default : parse_pad;
        }
    }

    state parse_first_fragment {
        eg_md.outer_first_fragment = 1;
        transition parse_pad;
    }

    state parse_ipv6_in_ip {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_IP_IN_IP;
        transition parse_inner_ipv6;
    }

    state parse_ipv4_in_ip {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_IP_IN_IP;
        transition parse_inner_ipv4;
    }

    /*
    * TODO
    * There can be multiple next headers so this needs to be handled similar to multiple vlan or mpls.
    * Also fragments need to be handled
    */

    state parse_ipv6 {
        pkt.extract(hdr.ether_II);
        pkt.extract(hdr.ipv6);
        eg_md.ip_protocol = hdr.ipv6.next_hdr;
        eg_md.pkt_len = hdr.ipv6.payload_len;
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_IPV6_FRAG : parse_ipv6_frag;
            default : parse_ipv6_no_frag;
        }
    }

    state parse_ipv6_no_frag {
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
     IP_PROTOCOLS_SCTP : parse_sctp;
            IP_PROTOCOLS_GRE : parse_gre;
            IP_PROTOCOLS_ICMP: parse_icmp;
            IP_PROTOCOLS_IGMP: parse_icmp;
            IP_PROTOCOLS_IPV6: parse_ipv6_in_ip;
            IP_PROTOCOLS_IPV4: parse_ipv4_in_ip;
            default : parse_pad;
        }
    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.frag_offset, hdr.ipv6_frag.next_hdr) {
            (0, IP_PROTOCOLS_TCP) : parse_tcp;
            (0, IP_PROTOCOLS_UDP) : parse_udp;
     (0, IP_PROTOCOLS_SCTP) : parse_sctp;
            (0, IP_PROTOCOLS_GRE) : parse_gre;
            (0, IP_PROTOCOLS_ICMP): parse_icmp;
            (0, IP_PROTOCOLS_IGMP): parse_icmp;
            (0, IP_PROTOCOLS_IPV6) : parse_ipv6_in_ip;
            (0, IP_PROTOCOLS_IPV4) : parse_ipv4_in_ip;
            default : parse_pad;
        }
    }

    state parse_icmp {
        eg_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        eg_md.outer_first_fragment = 1;
        transition parse_pad;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        eg_md.outer_first_fragment = 1;
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S) {
            (1, 1, 1): parse_gredata_3;
            (1, 1, 0): parse_gredata_2;
            (1, 0, 1): parse_gredata_2;
            (0, 1, 1): parse_gredata_2;
            (1, 0, 0): parse_gredata_1;
            (0, 1, 0): parse_gredata_1;
            (0, 0, 1): parse_gredata_1;
            (0, 0, 0): parse_gre_proto;
        }
    }

    state parse_gredata_3 {
        pkt.extract(hdr.gre_data3); //Extract 3 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gredata_2 {
        pkt.extract(hdr.gre_data2); //Extract 2 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gredata_1 {
        pkt.extract(hdr.gre_data1); //Extract 1 * 32 bits
        transition parse_gre_proto;
    }

    state parse_gre_proto {
        transition select(hdr.gre.R, hdr.gre.S, hdr.gre.proto) {
            (0, _, ETHERTYPE_IPV4 ): parse_gre_inner_ipv4;
            (0, _, ETHERTYPE_IPV6 ): parse_gre_inner_ipv6;
            (0, 0, ETHERTYPE_ERSPAN_II ): parse_type_erspan_I;
            (0, 1, ETHERTYPE_ERSPAN_II ): parse_type_erspan_II;
            (0, _, ETHERTYPE_ERSPAN_III): parse_erspan_III;




            (0, _, ETHERTYPE_MPLS_UNICAST): parse_mpls;
            (0, _, ETHERTYPE_MPLS_MULTICAST): parse_mpls;

            (0, _, _ ): parse_gre_inner_mac;
            default: accept; //We are not supporting GRE packets with R(Routing) bit set, so don't look further
        }
    }
# 1126 "parde.p4"
    state parse_gre_inner_mac {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_L2GRE;
        transition parse_inner_mac;
    }

    state parse_gre_inner_ipv4 {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_L3GRE;
        transition parse_inner_ipv4;
    }

    state parse_gre_inner_ipv6 {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_L3GRE;
        transition parse_inner_ipv6;
    }

    state parse_erspan_III {
        pkt.extract(hdr.erspan_data3); //Extract 3 * 32 bits
        //Check if there is a optional platform sub header 2*32 bits - bit [0]
        //FT bit 2 can be set to 1 for encapsulated IP packets - bit[12],
        //we are not supporting it, so not parsing those frames
        transition select(hdr.erspan_data3.data[0:0], hdr.erspan_data3.data[11:11]) {
            (0,0) : parse_erspan_III_inner_mac; //Optional sub header not present
            (1,0) : parse_type_erspan_II; //Optional platform header present, extract 2 * 32 bits
            default : accept; //when bit[12] is set, don't parse any further
                              //as we are not going to perform header stripping with inner IP packets
        }
    }

    state parse_type_erspan_II {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        transition parse_erspan_II;
    }

    state parse_erspan_III_inner_mac {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        transition parse_inner_mac;
    }

    state parse_erspan_II {
        pkt.extract(hdr.erspan_data2); //Extract 2 * 32 bits
        transition parse_inner_mac;
    }

    state parse_type_erspan_I {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_ERSPAN;
        transition parse_inner_mac;
    }

    state parse_udp {
        eg_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.udp);
# 1189 "parde.p4"
        eg_md.outer_first_fragment = 1;
        transition select(hdr.udp.dst_port) {
            UDP_PORT_GENEVE : parse_geneve;
            UDP_PORT_STD_VXLAN : parse_vxlan;
            UDP_PORT_CISCO_VXLAN: parse_vxlan;
            UDP_PORT_KVM_VXLAN : parse_vxlan;
            UDP_PORT_GTPU : parse_gtpu;
            UDP_PORT_LISP : parse_lisp_gtpu;



            UDP_PORT_MPLS : parse_mpls;

            default: parse_pad;
        }
    }

state parse_sctp {
        eg_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.udp);
 transition parse_pad;
    }
# 1254 "parde.p4"
    state parse_geneve {
        //Parse GENEVE as VxLAN header only if it didn't have optional headers
        pkt.extract(hdr.vxlan);
        transition select(hdr.vxlan.flags) {
            0 : parse_geneve_vxlan;
            1 : parse_geneve_opt1;
            2 : parse_geneve_opt2;
            3 : parse_geneve_opt3;
            4 : parse_geneve_opt4;
            5 : parse_geneve_opt5;
            default : accept; //Don't parse the packet any further
        }
    }

    state parse_geneve_vxlan {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt1 {
        pkt.extract(hdr.gtp_ext[0]);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt2 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt3 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt4 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        pkt.extract(hdr.gtp_ext[3]);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }

    state parse_geneve_opt5 {
        pkt.extract(hdr.gtp_ext[0]);
        pkt.extract(hdr.gtp_ext[1]);
        pkt.extract(hdr.gtp_ext[2]);
        pkt.extract(hdr.gtp_ext[3]);
        pkt.extract(hdr.gtp_ext[4]);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GENEVE;
        transition parse_inner_mac;
    }


    state parse_tcp {
        eg_md.l4_outer_info = pkt.lookahead<l4_common_header_t>();
        pkt.extract(hdr.tcp);
# 1328 "parde.p4"
        transition parse_first_fragment;

    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_VXLAN;
        transition parse_inner_mac;
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        transition select(hdr.gtpu.s, hdr.gtpu.pn, hdr.gtpu.e) {
            (0, 0, 0) : parse_gtpu_inner;
            (_, _, 0) : parse_gtpu_no_extn;
            (_, _, 1) : parse_gtpu_check_extn;
        }
   }

   state parse_gtpu_no_extn {
        pkt.extract(hdr.gtp_ext[0]);
        transition parse_gtpu_inner;
   }

   state parse_gtpu_check_extn {
        pkt.extract(hdr.gtp_ext[0]);
        transition select(hdr.gtp_ext[0].rsvd2[7:0]) {
            0 : parse_gtpu_inner;
            default : parse_gtpu_extn_length;
        }
   }

   state parse_gtpu_extn_length {
        pkt.extract(hdr.gtp_ext[1]);
        transition select(hdr.gtp_ext[1].rsvd1[15:8]) {
            1 : parse_gtpu_inner;
            2 : parse_gtpu_extn2;
            default: accept; // No parsing of other extn lengths
        }
   }

   state parse_gtpu_extn2 {
        pkt.extract(hdr.gtp_ext[2]);
        transition parse_gtpu_inner;
   }

   state parse_gtpu_inner {
        eg_md.packet_type = packet_type_t.PACKET_TYPE_GTP;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default:accept;
        }
    }

    state parse_lisp_gtpu {
        pkt.extract(hdr.gtpu);
        eg_md.packet_type = packet_type_t.PACKET_TYPE_LISP;
        transition select(pkt.lookahead<bit<4>>()) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default:accept;
        }
    }

   state parse_inner_mac {
      pkt.extract(hdr.inner_mac);
      transition accept;
   }

    state parse_inner_ipv4 {
        eg_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_IPV4;
        transition parse_pad;
    }

    state parse_inner_ipv6 {
        eg_md.inner_ether_type = inner_ether_type_t.INNER_ETHER_TYPE_IPV6;
        transition accept;
    }

    state parse_pad {

        hdr.pad.setValid();
        hdr.pad = pkt.lookahead<pad_h>();

        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
    packet_out pkt,
    inout egress_header_t hdr,
    in egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    Checksum() tnl_ipv4_checksum;






    apply {
        if (hdr.tnl_ipv4.isValid()) {
            hdr.tnl_ipv4.hdr_checksum = tnl_ipv4_checksum.update({
                        hdr.tnl_ipv4.version,
                        hdr.tnl_ipv4.ihl,
                        hdr.tnl_ipv4.diffserv,
                        hdr.tnl_ipv4.total_len,
                        hdr.tnl_ipv4.identification,
                        hdr.tnl_ipv4.flags,
                        hdr.tnl_ipv4.frag_offset,
                        hdr.tnl_ipv4.ttl,
                        hdr.tnl_ipv4.protocol,
                        hdr.tnl_ipv4.src_addr,
                        hdr.tnl_ipv4.dst_addr
                    });
        }
# 1494 "parde.p4"
        pkt.emit(hdr);
    }
}
# 157 "bfs.p4" 2
# 1 "networkPortVlanAction.p4" 1
/**
* networkPortVlanAction.p4 - Ingress VLAN actions like Port Tagging, single VLAN and double VLAN Stripping
* Copyright Keysight Technologies 2020
*/

control vlan_actions(
    inout ingress_header_t hdr,
    inout ingress_metadata_t ig_md) {

    bool ether_type_incl = false;
    bool l4_incl = false;

    action nop() {
        ig_md.outer_vlan = hdr.vlan_tag[0].vlan;
        ig_md.outer_vlan_valid = hdr.vlan_tag[0].isValid();
        ig_md.inner_vlan = hdr.vlan_tag[1].vlan;
        ig_md.inner_vlan_valid = hdr.vlan_tag[1].isValid();
    }

    action port_tagging_0x8100() {
        hdr.tagging_vlan_tag.setValid();
        hdr.tagging_vlan_tag.vlan[11:0] = ig_md.port_config.vlan_config[11:0];
        hdr.tagging_vlan_tag.tpid = TPID_0x8100;
        ig_md.outer_vlan_valid = true;
        ig_md.inner_vlan_valid = hdr.vlan_tag[0].isValid();
        ig_md.outer_vlan[11:0] = ig_md.port_config.vlan_config[11:0];
        ig_md.inner_vlan = hdr.vlan_tag[0].vlan;
 hdr.br_md.vlan_config = 1; //Port Tagging
    }

    action port_tagging_0x88a8() {
        hdr.tagging_vlan_tag.setValid();
        hdr.tagging_vlan_tag.vlan[11:0] = ig_md.port_config.vlan_config[11:0];
        hdr.tagging_vlan_tag.tpid = TPID_0x88A8;
        ig_md.outer_vlan_valid = true;
        ig_md.inner_vlan_valid = hdr.vlan_tag[0].isValid();
        ig_md.outer_vlan[11:0] = ig_md.port_config.vlan_config[11:0];
        ig_md.inner_vlan = hdr.vlan_tag[0].vlan;
 //Port Tagging - both 0x8100 and 0x88A8 cases add a VLAN - br_md.vlan_config is just 2 bits
 hdr.br_md.vlan_config = 1;
    }

    /*
     * This action should be called for cases 
     *  1. when the user configured single VLAN stripping and the packet has atleast one VLAN tag 
     *  2. when the user configured double VLAN stripping and the packet has just one VLAN tag 
     */
    action single_vlan_stripping() {
        hdr.vlan_tag[0].setInvalid();
        ig_md.outer_vlan_valid = hdr.vlan_tag[1].isValid();
        ig_md.inner_vlan_valid = hdr.vlan_tag[2].isValid();
        ig_md.outer_vlan = hdr.vlan_tag[1].vlan;
        ig_md.inner_vlan = hdr.vlan_tag[2].vlan;
 hdr.br_md.vlan_config = 2; //Single VLAN Stripping
    }

    /*
     * This action should be called only when the user configured 
     * double VLAN stripping and the packet has atleast 2 VLAN tags 
     */
    action double_vlan_stripping() {
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        ig_md.outer_vlan_valid = hdr.vlan_tag[2].isValid();
        ig_md.outer_vlan = hdr.vlan_tag[2].vlan;
        ig_md.inner_vlan_valid = false;
        ig_md.inner_vlan = 0;
 hdr.br_md.vlan_config = 3; //double VLAN Stripping
    }

    @name("std_vlan")
    table standard_vlan_action {
 actions = {
            @defaultonly nop;
            port_tagging_0x8100;
            port_tagging_0x88a8;
            single_vlan_stripping;
            double_vlan_stripping;
 }
 key = {
            ig_md.port_config.vlan_config[14:12] : exact @name("vlan_config");
            hdr.vlan_tag[0].isValid() : exact @name("outer_tag_valid");
            hdr.vlan_tag[1].isValid() : exact @name("inner_tag_valid");
 }
 const default_action = nop;
 size = 16;
    }

    action system_properties_nop() { }

    action set_system_properties(bool mpls_include,
                                 bool l4_include,
                                 bool ether_type_include) {
        ig_md.hash_mpls_include = mpls_include;
        ether_type_incl = ether_type_include;
        l4_incl = l4_include;
    }

    @name("system_properties")
    table system_properties {
        actions = { system_properties_nop;set_system_properties; }
        default_action = system_properties_nop();
        size = 1;
    }

    apply {
        standard_vlan_action.apply();
        system_properties.apply();
        if(ether_type_incl) {
            ig_md.hash_outer_ether_type = hdr.ether_II.ether_type;
//            ig_md.hash_inner_ether_type = hdr.inner_ether_II.ether_type;
        }
        if(l4_incl) {
            ig_md.hash_outer_l4_srcport = ig_md.l4_outer_info.srcport_typecode;
            ig_md.hash_outer_l4_dstport = ig_md.l4_outer_info.dstport_chksum;
//            ig_md.hash_inner_l4_srcport = ig_md.l4_inner_info.srcport_typecode;
//            ig_md.hash_inner_l4_dstport = ig_md.l4_inner_info.dstport_chksum;
        }
    }
}
# 158 "bfs.p4" 2
# 1 "commonPacketProcessing.p4" 1
/**
 * commonPacketProcessing.p4 - This code is common for network port, dynamic filter
 *                             and tool port header stripping operations
 * Copyright Keysight Technologies 2020
 */

control ingress_packet_process(
    inout ingress_header_t hdr,
    in bit<3> drop_ctl,
    in bit<9> ingress_port,
    in bit<16> mg_id,
    in packet_type_t packet_type,
    in inner_ether_type_t inner_ether_type) {

    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets)
    @KS_stats_service_units(packets)
    Counter<PacketByteCounter_t, StatIndex_t> (
        256, CounterType_t.PACKETS_AND_BYTES) statTable;

    action nop() { }

    //For L2GRE, ERSPAN Stripping
/*    @ps_plus_gre_strip[filterType="network", psPlusFeature="PS_PLUS_GRE_STRIPPING"]
    @ps_plus_erspan_strip[filterType="network", psPlusFeature="PS_PLUS_ERSPAN_STRIPPING"]
    action strip_l2gre_header(StatIndex_t index, bit<1> vlan_stripping) {
        hdr.mac.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.erspan_data2.setInvalid();
        hdr.erspan_data3.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.tagging_vlan_tag.setInvalid();
        hdr.ether_II.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
#ifdef INT_SUPPORT
        hdr.otv.setInvalid();
#endif
	    hdr.br_md.hdr_stripping= true;
	    hdr.br_md.vlan_stripping= vlan_stripping;
	    statTable.count(index);
    }

#ifdef PBBTE_SUPPORT
    //For PBB-TE Stripping
    @ps_plus_pbbte_strip[filterType="network", psPlusFeature="PS_PLUS_PBBTE_STRIPPING"]
    action strip_pbbte_header(StatIndex_t index, bit<1> vlan_stripping) {
        hdr.mac.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.tagging_vlan_tag.setInvalid();
        hdr.ether_II.setInvalid();
        hdr.pbbte.setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    hdr.br_md.vlan_stripping= vlan_stripping;
	    statTable.count(index);
    }
#endif

    //For VXLAN & GENEVE Stripping
    @ps_plus_vxlan_strip[filterType="network", psPlusFeature="PS_PLUS_VXLAN_STRIPPING"]
    @ps_plus_geneve_strip[filterType="network", psPlusFeature="PS_PLUS_GENEVE_STRIPPING"]
    action strip_vxlan_header(StatIndex_t index, bit<1> vlan_stripping) {
        hdr.mac.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.tagging_vlan_tag.setInvalid();
        hdr.ether_II.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        hdr.vxlan.setInvalid();
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
        hdr.gtp_ext[3].setInvalid();
        hdr.gtp_ext[4].setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    hdr.br_md.vlan_stripping= vlan_stripping;
	    statTable.count(index);
    }

    //For MPLS-PW(with/without CW) Stripping
    action strip_mpls_pw_header(StatIndex_t index, bit<1> vlan_stripping) {
        hdr.mac.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.tagging_vlan_tag.setInvalid();
        hdr.ether_II.setInvalid();
	hdr.mpls_cw.setInvalid();
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
#ifndef INT_SUPPORT
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
#endif
	    hdr.br_md.hdr_stripping= true;
	    hdr.br_md.vlan_stripping= vlan_stripping;
	    statTable.count(index);
    }

    //For PPPoE and MPLS L3VPN cases
#ifdef PPPOE_SUPPORT
    @ps_plus_ppoe_strip[filterType="network", psPlusFeature="PS_PLUS_PPPOE_STRIPPING"]
#endif
    @ps_plus_mpls_strip[filterType="network", psPlusFeature="PS_PLUS_MPLS_STRIPPING"]
    action strip_header_options_ipv4(StatIndex_t index) {
#ifdef PPPOE_SUPPORT
        hdr.pppoe.setInvalid();
#endif
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
#ifndef INT_SUPPORT
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.udp.setInvalid();
#endif
        hdr.ether_II.ether_type = ETHERTYPE_IPV4;
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    //For PPPoE and MPLS L3VPN cases
    action strip_header_options_ipv6(StatIndex_t index) {
#ifdef PPPOE_SUPPORT
        hdr.pppoe.setInvalid();
#endif
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
#ifndef INT_SUPPORT
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.udp.setInvalid();
#endif
        hdr.ether_II.ether_type = ETHERTYPE_IPV6;
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    //For L3GRE, GTP & LISP
    @ps_plus_gtp_lisp_strip[filterType="network", psPlusFeature="PS_PLUS_GTP_LISP_STRIPPING"]
    action strip_outer_layer3_ipv4(StatIndex_t index) {
        hdr.ipv4.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtpu.setInvalid();
        hdr.ether_II.ether_type = ETHERTYPE_IPV4;
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    //For L3GRE, GTP & LISP
    action strip_outer_layer3_ipv6(StatIndex_t index) {
        hdr.ipv4.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtpu.setInvalid();
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
        hdr.ether_II.ether_type = ETHERTYPE_IPV6;
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    //For ETag, VnTag & Fabric Path cases
    @ps_plus_etag_vntag_fabric_path_strip[filterType="network", psPlusFeature="PS_PLUS_ETAG_VNTAG_FABRIC_PATH_STRIPPING"]
    action strip_etag_vntag_fabricpath(StatIndex_t index, bit<1> vlan_stripping) {
        hdr.etag.setInvalid();
        hdr.vntag.setInvalid();
        hdr.fabric_path.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.tagging_vlan_tag.setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    hdr.br_md.vlan_stripping= vlan_stripping;
	    statTable.count(index);
    }

    //For Fabric Path only cases
    action strip_fabricpath_only(StatIndex_t index) {
        hdr.fabric_path.setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    //For MPLS non-bos cases
    action strip_mpls_non_bos(StatIndex_t index) {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
	    hdr.br_md.hdr_stripping= true;
	    statTable.count(index);
    }

    @name("hdr_stripping")
    table hdr_stripping_tbl {
	actions = {
            @defaultonly nop;
            strip_l2gre_header;
            strip_vxlan_header;
#ifdef PBBTE_SUPPORT
            strip_pbbte_header;
#endif
            strip_mpls_pw_header;
            strip_header_options_ipv4;
            strip_header_options_ipv6;
            strip_outer_layer3_ipv4;
            strip_outer_layer3_ipv6;
            strip_etag_vntag_fabricpath;
            strip_fabricpath_only;
            strip_mpls_non_bos;
	}
	key = {
            drop_ctl          : ternary;
            ingress_port      : ternary;
            mg_id             : ternary;
            inner_ether_type  : ternary;
            packet_type       : ternary;
            hdr.etag.isValid()       : ternary @name("etag_valid");
            hdr.vntag.isValid()      : ternary @name("vntag_valid");
            hdr.fabric_path.isValid(): ternary @name("fabricpath_valid");
            hdr.mpls[0].isValid()    : ternary @name("mpls_valid");
	}
	const default_action = nop;
	size = ING_HDR_STRIPPING_TABLE_SIZE;
    }
*/
    apply {
//        hdr_stripping_tbl.apply();
    }
    /* End ingress */

}
    /* Egress packet processing */
control egress_packet_process(
    inout egress_header_t hdr,
    in bit<16> egress_rid,
    in bit<9> egress_port,
    in packet_type_t packet_type,



    in inner_ether_type_t inner_ether_type,
    inout bit<16> outer_vlan,
    inout bool outer_vlan_valid) {


    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets)
    @KS_stats_service_units(packets)
    Counter<PacketByteCounter_t, StatIndex_t> (
        1024, CounterType_t.PACKETS_AND_BYTES) statTable;
    bit<16> tagging_vlan = 0;
    bool inner_vlan = false;
    bool tag_vlan = false;

    action nop() { }

    //For L2GRE, ERSPAN Stripping
    @ps_plus_gre_strip[filterType="tool", psPlusFeature="PS_PLUS_GRE_STRIPPING"]
    @ps_plus_erspan_strip[filterType="tool", psPlusFeature="PS_PLUS_ERSPAN_STRIPPING"]
    action strip_l2gre_header(StatIndex_t index, bit<16> vlan) {
        hdr.mac.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.erspan_data2.setInvalid();
        hdr.erspan_data3.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.ether_II.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();



        inner_vlan = true;
        tagging_vlan = vlan;
     statTable.count(index);
    }
# 344 "commonPacketProcessing.p4"
    //For VXLAN & GENEVE Stripping
    @ps_plus_vxlan_strip[filterType="tool", psPlusFeature="PS_PLUS_VXLAN_STRIPPING"]
    @ps_plus_geneve_strip[filterType="tool", psPlusFeature="PS_PLUS_GENEVE_STRIPPING"]
    action strip_vxlan_header(StatIndex_t index, bit<16> vlan) {
        hdr.mac.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.ether_II.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        hdr.vxlan.setInvalid();
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
        hdr.gtp_ext[3].setInvalid();
        hdr.gtp_ext[4].setInvalid();
        inner_vlan = true;
        tagging_vlan = vlan;
     statTable.count(index);
    }

    //For MPLS-PW(with/without CW) Stripping
    action strip_mpls_pw_header(StatIndex_t index, bit<16> vlan) {
        hdr.mac.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.ether_II.setInvalid();
     hdr.mpls_cw.setInvalid();
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();

        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();

        inner_vlan = true;
        tagging_vlan = vlan;
     statTable.count(index);
    }

    //For PPPoE and MPLS L3VPN cases



    @ps_plus_mpls_strip[filterType="tool", psPlusFeature="PS_PLUS_MPLS_STRIPPING"]
    action strip_header_options_ipv4(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {



        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();

        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.udp.setInvalid();

        hdr.ether_II.ether_type = ETHERTYPE_IPV4;
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    //For PPPoE and MPLS L3VPN cases
    action strip_header_options_ipv6(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {



        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();

        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.udp.setInvalid();

        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
        hdr.ether_II.ether_type = ETHERTYPE_IPV6;
     statTable.count(index);
    }

    //For L3GRE, GTP & LISP
    @ps_plus_gtp_lisp_strip[filterType="tool", psPlusFeature="PS_PLUS_GTP_LISP_STRIPPING"]
    action strip_outer_layer3_ipv4(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {
        hdr.ipv4.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtpu.setInvalid();
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
        hdr.ether_II.ether_type = ETHERTYPE_IPV4;
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    //For L3GRE, GTP & LISP
    action strip_outer_layer3_ipv6(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {
        hdr.ipv4.setInvalid();
        hdr.gre_data1.setInvalid();
        hdr.gre_data2.setInvalid();
        hdr.gre_data3.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtpu.setInvalid();
        hdr.gtp_ext[0].setInvalid();
        hdr.gtp_ext[1].setInvalid();
        hdr.gtp_ext[2].setInvalid();
        hdr.ether_II.ether_type = ETHERTYPE_IPV6;
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    //For ETag, VnTag & Fabric Path cases
    @ps_plus_etag_vntag_fabric_path_strip[filterType="tool", psPlusFeature="PS_PLUS_ETAG_VNTAG_FABRIC_PATH_STRIPPING"]
    action strip_etag_vntag_fabricpath(StatIndex_t index, bit<16> vlan) {
        hdr.etag.setInvalid();
        hdr.vntag.setInvalid();
        hdr.fabric_path.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        inner_vlan = true;
        tagging_vlan = vlan;
     statTable.count(index);
    }

    //For Fabric Path only cases
    action strip_fabricpath_only(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {
        hdr.fabric_path.setInvalid();
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    //For MPLS non-bos cases
    action strip_mpls_non_bos(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    //For packets not getting stripped
    action set_tagging_vlan(StatIndex_t index, bit<16> vlan, bool vlan_tagging) {
        tagging_vlan = vlan;
        tag_vlan = vlan_tagging;
     statTable.count(index);
    }

    @name("hdr_stripping")
    table hdr_stripping_tbl {
 actions = {
            @defaultonly nop;
            strip_l2gre_header;
            strip_vxlan_header;



            strip_mpls_pw_header;
            strip_header_options_ipv4;
            strip_header_options_ipv6;
            strip_outer_layer3_ipv4;
            strip_outer_layer3_ipv6;
            strip_etag_vntag_fabricpath;
            strip_fabricpath_only;
            strip_mpls_non_bos;
            set_tagging_vlan;
 }
 key = {
            egress_rid : ternary;
            egress_port : ternary;
            inner_ether_type : ternary;
            packet_type : ternary;
            hdr.etag.isValid() : ternary @name("etag_valid");
            hdr.vntag.isValid() : ternary @name("vntag_valid");
            hdr.fabric_path.isValid(): ternary @name("fabricpath_valid");
            hdr.mpls[0].isValid() : ternary @name("mpls_valid");
 }
 const default_action = nop;
 size = 1024;
    }

    apply {
        hdr_stripping_tbl.apply();
        if (inner_vlan && tagging_vlan != 0) {
              hdr.inner_vlan_tag.tpid = TPID_0x8100;
              hdr.inner_vlan_tag.vlan = tagging_vlan;
              hdr.inner_vlan_tag.setValid();

              outer_vlan = tagging_vlan;
              outer_vlan_valid = true;

        }
        else if (tag_vlan && tagging_vlan != 0) {
              hdr.outer_vlan_tag.tpid = TPID_0x8100;
              hdr.outer_vlan_tag.vlan = tagging_vlan;
              hdr.outer_vlan_tag.setValid();

              outer_vlan = tagging_vlan;
              outer_vlan_valid = true;

        }
        else if (tagging_vlan != 0) {
              hdr.vlan_tag[0].tpid = TPID_0x8100;
              hdr.vlan_tag[0].vlan = tagging_vlan;
              hdr.vlan_tag[0].setValid();

              outer_vlan = tagging_vlan;
              outer_vlan_valid = true;

        }
    }
}
# 159 "bfs.p4" 2
# 1 "networkPortFilters.p4" 1
/**
* networkPortFilters -
* Copyright Keysight Technologies 2020
*/


/* Will remove these for space in now for debug */
DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) outerL2MatchCount;
DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) outerl3MatchCount;

control processNetworkPortFilters(
    inout ingress_header_t hdr,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    /*
    * Annotations for statTable used by Stats service
    * statTag correlates counters for multiple table reads in a single thread
    */
    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        512, CounterType_t.PACKETS_AND_BYTES) statTable;
    Counter<PacketByteCounter_t, StatIndex_t> (
        8, CounterType_t.PACKETS_AND_BYTES) prsrErrStatTable;


    /*
     * parser error
     */
    action pass_pkt(StatIndex_t index) {
     prsrErrStatTable.count(index);
     ig_intr_dprsr_md.drop_ctl = 0x0;
    }

    action prsr_drop_pkt(StatIndex_t index) {
     prsrErrStatTable.count(index);
     ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    @brief("parserError")
    @name("prsrErr")
    table parser_err {
    actions = {
        @defaultonly prsr_drop_pkt;
     pass_pkt;
    }
    key = {
     ig_intr_prsr_md.parser_err : exact @name("prsr_err");
    }
    const default_action = prsr_drop_pkt(0);
    size = 8;
    }

    /*
    * Network Port Filter Tables.  Consist of an outer l2, outer l3 and
    * inner l3 tables along with a direct counter for each rule.

    */
    action nop() {
    }

    /*
    * Outer L2
    */
    action pass_outer_l2() {
 outerL2MatchCount.count();
 ig_md.npf_l2_match = 0x1;
    }
    action drop_outer_l2() {
 outerL2MatchCount.count();
 ig_md.npf_l2_match = 0x1;
    }

    @brief("networkPortFilter")
    @name("outerl2")
    table outerL2 {
 actions = {
     @defaultonly nop;
     @name("pass_l2")
     pass_outer_l2;
     @name("drop_l2")
     drop_outer_l2;
 }
 key = {
     ig_md.port_config.port_class_id : exact @name("port_class_id");
     hdr.mac.dst_addr : ternary @name("mac_dst") @brief("MAC_DST");
     hdr.mac.src_addr : ternary @name("mac_src") @brief("MAC_SRC");
     hdr.ether_II.ether_type : ternary @name("ether_II.ether_type") @brief("ETHERTYPE");
     hdr.vlan_tag[0].vlan : ternary @name("outer_vlan") @brief("VLAN");
     hdr.vlan_tag[0].isValid() : ternary @name("outer_vlan_valid");
     hdr.vlan_tag[1].vlan : ternary @name("inner_vlan") @brief("INNER_VLAN");
     hdr.vlan_tag[1].isValid() : ternary @name("inner_vlan_valid");
 }
 const default_action = nop;
 size = 512;
 counters = outerL2MatchCount;
    }

    /*
    * Outer L3.
    */
    action pass_outer_l3() {
 outerl3MatchCount.count();
 ig_md.npf_l3_match = 0x1;
    }
    action drop_outer_l3() {
 outerl3MatchCount.count();
 ig_md.npf_l3_match = 0x1;
    }

    @brief("networkPortFilter")
    @name("outerl3")
    table outer_l3 {
 actions = {
     @defaultonly nop;
     pass_outer_l3;
     drop_outer_l3;
 }
 key = {
     ig_md.port_config.port_class_id : exact @name("port_class_id");
     /*
	    * if v4, then bits 95:64 are used with the v4 address (field ipv4_...)
	    * If v6, then 127:64 are used with upper 64 bits of v6 address (field ip_...)
 	    */
     hdr.ipv4.isValid() : ternary @name("v4_valid");
     hdr.ipv6.isValid() : ternary @name("v6_valid");
     ig_md.ip_dst_addr[127:64] : ternary @name("ip_dst") @brief("IP_ADDR_DST");
     ig_md.ip_src_addr[127:64] : ternary @name("ip_src") @brief("IP_ADDR_SRC");
            ig_md.ip_protocol : ternary @name("ipv4_protocol") @brief("IP_PROTOCOL");
            ig_md.l4_outer_info.srcport_typecode : ternary @name("srcport_typecode") @brief("LAYER4_SRC_PORT");
            ig_md.l4_outer_info.dstport_chksum : ternary @name("dstport_chksum") @brief("LAYER4_DST_PORT");
     hdr.tcp.flags : ternary @name("flags") @brief("TCP_CONTROL");
     ig_md.dsTc : ternary @name("dsTc") @brief("DSCP");
 }
 const default_action = nop;
 size = 512;
 counters = outerl3MatchCount;
    }

    /*
    * Inner IPv4- Final table lookup.  Drop/pass decisions made here
    */
    action pass_inner_l3(StatIndex_t index) {
 statTable.count(index);
        ig_md.pkt_type = PKT_TYPE_NORMAL;
        ig_intr_dprsr_md.drop_ctl = 0x0;
    }

    action drop_inner_l3(StatIndex_t index) {
 statTable.count(index);
        ig_intr_dprsr_md.drop_ctl = 0x1;
 ig_md.port_config.filter_vrf = 0;
    }

    @brief("networkPortFilterMain")
    @name("innerl3")
    table inner_l3 {
 actions = {
     @defaultonly nop;
     pass_inner_l3;
     drop_inner_l3;
 }
 key = {
     ig_md.port_config.port_class_id : exact @name("port_class_id");
     ig_md.npf_l2_match : ternary @name("l2_match");
     ig_md.npf_l3_match : ternary @name("l3_match");
# 185 "networkPortFilters.p4"
 }
 const default_action = nop;
 size = 512;
    }

    apply {
    parser_err.apply();
 /*
	* Move outer/inner ipv4 address to generic v4/v6 space.
	* Move v4 diffserv or v6 traffic class to dsTc field
	*/
 if (hdr.ipv4.isValid()) {
     ig_md.dsTc = hdr.ipv4.diffserv;
     ig_md.ip_dst_addr[95:64] = ig_md.ip_dst_addr[31:0];
     ig_md.ip_src_addr[95:64] = ig_md.ip_src_addr[31:0];
 }
 else if (hdr.ipv6.isValid()) {
     ig_md.dsTc = hdr.ipv6.traffic_class;
 }
/*	if (hdr.inner_ipv4.isValid()) {
	    ig_md.inner_ip_dst_addr[95:64] = ig_md.inner_ip_dst_addr[31:0];
	    ig_md.inner_ip_src_addr[95:64] = ig_md.inner_ip_src_addr[31:0];
	}
*/
 outerL2.apply();
 outer_l3.apply();
 inner_l3.apply();
    }
}
# 160 "bfs.p4" 2



# 1 "timeStampProcessing16_32.p4" 1
control ts_actions(inout ingress_header_t hdr,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_metadata_t ig_md)
{

    bit<32> ingress_ts_sec=0;
    bit<32> ingress_ts_nsec=0;

    bit<8> sync_mode_active=0;
    bit<8> load_new_time = 0;
    bit<8> cur_match_5A = 0;
    bit<8> cur_match_A5 = 0;
    bit<8> prev_match_A5 = 0;
    bit<16> upper_masked_timestamp = 0;

    bit<32> holding_time_seconds=0;
    bit<32> holding_lower_32_of_48=0;

    action nop() {}

    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        64, CounterType_t.PACKETS_AND_BYTES) statTableMacTs;

    @ps_plus_src_mac_timestamp[filterType="network", psPlusFeature="PS_PLUS_SRC_MAC_TIMESTAMPING"]
    action ts_mac_src_ingress(StatIndex_t index) {

        //For 6.3.1 release, remove 16/32 timestamp and stamp with 48 bit
        //hdr.mac.src_addr = ig_intr_md.ingress_mac_tstamp;
        hdr.mac.src_addr[47:32] = ingress_ts_sec[15:0];
        hdr.mac.src_addr[31:0] = ingress_ts_nsec;

        // TEMP value to allow for accuracy testing
        hdr.mac.dst_addr = ig_intr_md.ingress_mac_tstamp;
        hdr.ipv4.dst_addr = ig_md.pktGap_ingress;
        hdr.ipv4.src_addr = ig_md.ns_ingress;

        statTableMacTs.count(index);
    }

    table ts_mac_src_action{
 actions = {
      @defaultonly nop;
     ts_mac_src_ingress();
 }

 key = {
            ig_intr_md.ingress_port : ternary @name("ingress_port");
 }
 const default_action = nop;
 size = 64;
    }

    /*
     * This register holds whether the previous packet had A5A5 as the most significant
     * 14 bits.  It uses the value for the previous packet and then saves the value 
     * for the current packet.
     * This returns whether the 'sync' pattern of transition from A5A5 to 5A5A has been
     * detected.  
     */
    Register<bit<8>, bit<1>>(1) prev_msb_is_A5A5;
    RegisterAction<bit<8>, bit<1>, bit<8>>(prev_msb_is_A5A5) detect_pattern_action_reg = {
        void apply(inout bit<8> value, out bit<8> rv) {

        // Determine if see transition from  A5A5 to 5A5A
        if (value > 0 && cur_match_5A > 0) {
            rv = 1;
        }
        else {
            rv = 0;
        }

        // save whether current packet is A5A5
        value = cur_match_A5;
        }
    };


     action detect_pattern_action() {
        sync_mode_active = detect_pattern_action_reg.execute(0);
    }

    table detect_pattern {
        actions = {
            detect_pattern_action;
        }
        const default_action = detect_pattern_action;
        size = 1;
    }

    /* 
     * This register holds a boolean (in an 8 bit field for restriction reasons)
     * The value becomes true when the transition from A5A5 -> 5A5A is seen.
     * This will return 1 when a transition away from 5A5A to different time value
     * is seen.
     * The transition away inidcates that a 'real' new time is seen and the Sec/nSec
     * registers need to be loaded
     */
    Register<bit<8>, bit<1>>(1) set_reload_mode_if_detect_transition_reg;
    RegisterAction<bit<8>, bit<1>, bit<8>>(set_reload_mode_if_detect_transition_reg) look_for_real_time_transition_action = {
        void apply(inout bit<8> value, out bit<8> rv) {
           // Register action to look for transition away from 5A5A
           rv = 0;
           if (value > 0 && cur_match_5A == 0) {
               // time went away from 5A5A, return to load new time and stop looking for transition
               value = 0;
               rv = 1;
           }
        }
    };

    /*
     * Register action to set value to '1' to activate looking for transition away from 5A5A
     * This should be called when the transition from A5A5 to 5A5A is detected
     */
    RegisterAction<bit<8>, bit<1>, bit<8>>(set_reload_mode_if_detect_transition_reg) set_register_action = {
        void apply(inout bit<8> value, out bit<8> rv) {
           value = 1;
           rv = 0;
        }
    };


     action look_for_real_time_transition_reg_action() {
        load_new_time = look_for_real_time_transition_action.execute(0);
    }

     action set_register_reg_action() {
        load_new_time = set_register_action.execute(0);
    }

    table set_look_for_load_time_options {
        actions = {
            look_for_real_time_transition_reg_action;
            set_register_reg_action;
        }

 key = {
            sync_mode_active : exact @name("activate_sync");
 }

        const default_action = look_for_real_time_transition_reg_action;
        size = 2;
    }

    /*
     * Register holding the lower 32 bits of the 48 bit timestamp of the previous packet.
     * This is used to calculate the number of 'ns' between the current packet and the
     * previous packet.  After calculation, this is updated with the new value.
     */
    Register<bit<32>, bit<1>>(1) time_base_ingress_reg;
    // This action caluclates the difference between this packet and the previous
    RegisterAction<bit<32>, bit<1>, bit<32>>(time_base_ingress_reg) time_base_ingress_action = {
        void apply(inout bit<32> value, out bit<32> rv) {
// removing this fixes the drift issue
//           if(value == 0) {
//               rv = 0;
//               value = ig_intr_md.ingress_mac_tstamp[31:0];
//           }
//           else {
               rv = ig_intr_md.ingress_mac_tstamp[31:0] - value;
               value = ig_intr_md.ingress_mac_tstamp[31:0];
//           }
        }
    };

    // This action loads a new base value for the 48 bit counter (loading the lower 32 bits)
    RegisterAction<bit<32>, bit<1>, bit<32>>(time_base_ingress_reg) load_time_base_action = {
        void apply(inout bit<32> value, out bit<32> rv) {
           rv = 0;
           value = ig_md.pktGap_ingress;
        }
    };

    action time_base_ingress_reg_action() {
        ig_md.pktGap_ingress = time_base_ingress_action.execute(0);
    }

    // on initial load, don't return any difference from last packet
    action load_time_base_reg_action() {
        load_time_base_action.execute(0);
    }

    table set_time_base_ingress {
        actions = {
            time_base_ingress_reg_action;
            load_time_base_reg_action;
        }

 key = {
            load_new_time : exact @name("load_time");
 }

        const default_action = time_base_ingress_reg_action;
        size = 2;
    }

    /*
     * This register stores the Sec / nSec value that was stamped on the previous packet.
     * the time between packets calculated in the above register is used to determine
     * the new value.  This adds the difference to the nSec and it the nSec is > 1 sec, the 
     * second value is incremented and the remainder is stored into the nSec.
     */
    Register<pair32, bit<1>>(1) elapsed_time_ingress_reg;
    // Action to calculate the new timestamp (Sec / nSec) for this packet
    RegisterAction<pair32, bit<1>, bit<32>>(elapsed_time_ingress_reg) elapsed_time_action_ingress = {
        void apply(inout pair32 value, out bit<32> rv,out bit<32> rv1) {
            if(value.nsec + ig_md.pktGap_ingress < 1000000000) {
                value.nsec = value.nsec + ig_md.pktGap_ingress;
            }
            else {

                value.nsec = value.nsec - ig_md.ns_ingress;
                value.sec = value.sec + 1;
            }
            rv = value.sec;
            rv1 = value.nsec;
        }
    };

    // Action to load a new value into the register (when a new 'real' time is detected).
    RegisterAction<pair32, bit<1>, bit<32>>(elapsed_time_ingress_reg) load_elapsed_time_action = {
        void apply(inout pair32 value, out bit<32> rv,out bit<32> rv1) {
            value.nsec = 0;
            value.sec = ig_md.ns_ingress;
            rv = value.sec;
            rv1 = value.nsec;
        }
    };

    action elapsed_time_reg_action_ingress() {
        ingress_ts_sec = elapsed_time_action_ingress.execute(0, ingress_ts_nsec);
    }

    action load_elapsed_time_reg_action() {
        ingress_ts_sec = load_elapsed_time_action.execute(0, ingress_ts_nsec);
    }

    table update_elapsed_time_ingress {
        actions = {
            elapsed_time_reg_action_ingress;
            load_elapsed_time_reg_action;
        }

 key = {
            load_new_time : exact @name("load_time");
 }

        const default_action = elapsed_time_reg_action_ingress;
        size = 2;
    }


   /*
    * Holding timer data table is used to store the new time being loaded into the counter.
    * This saves the lower 32 bits of what is loaded into the 48 bit counter (to calculate differnce between packets).
    * This also saves the new number of seconds since the Epoch.  This is saved as a 32 bit number, but only
    * 16 bits are stored in the timestamp in the packet.
    * Note:  new time updates assume that time starts at a specific second value and that nSec = 0
    */
    action holding_timer_data_nop() {}

    action set_holding_timer_data(bit<32> time_seconds,
                                 bit<32> lower_32_of_48) {
        holding_time_seconds = time_seconds;
        holding_lower_32_of_48 = lower_32_of_48;
    }

    @name("holding_timer_data")
    table holding_timer_data {
        actions = { holding_timer_data_nop; set_holding_timer_data; }
        default_action = holding_timer_data_nop();
        size = 1;
    }


    apply {

        /* 
         * Determine if current time MSB is 5A5A or A5A5
         * This sets cur_match_5A and cur_match_A5
         */
        cur_match_5A = 0;
        cur_match_A5 = 0;
        upper_masked_timestamp = ig_intr_md.ingress_mac_tstamp[47:32] & 0xfffc;
        if (upper_masked_timestamp == 0x5A58) {
            cur_match_5A = 1;
        }
        if (upper_masked_timestamp == 0xA5A4) {
            cur_match_A5 = 1;
        }

        // Determine if previous time was A5A5 (sets prev_match_A5)
        detect_pattern.apply();

        /*
         * If sync_mode_active = 1, then set to look for transition away from 5A5A
         * This sets the 'load_new_time' variable to indicate that new time is now valid
         */
        set_look_for_load_time_options.apply();

        // Ensure that values are set in single entry for new 'Real' time
        holding_timer_data.apply();

        if(load_new_time > 0) {
            // Load new time into registers (no processing of timestamp done)
            ig_md.ns_ingress = holding_time_seconds;
            ig_md.pktGap_ingress = holding_lower_32_of_48;
            set_time_base_ingress.apply();
            update_elapsed_time_ingress.apply();
        }
        else {
            // Process timeStamp compared to previous packet
            set_time_base_ingress.apply();
            ig_md.ns_ingress = 32w1000000000 - ig_md.pktGap_ingress;
            update_elapsed_time_ingress.apply();
        }

        load_new_time = 0;
        // write TS into packet if required
 ts_mac_src_action.apply();
    }
}
# 164 "bfs.p4" 2

# 1 "dataMaskProcessing.p4" 1
control data_mask_actions(inout egress_header_t hdr,
    in bit<16> egress_rid,
    in PortId_t ingress_port,
    in PortId_t egress_port)
{
    action nop() {}

    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        64, CounterType_t.PACKETS_AND_BYTES) statTableIngress;

    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        512, CounterType_t.PACKETS_AND_BYTES) statTableEgress;

    @ps_plus_data_mask[filterType="tool", psPlusFeature="PS_PLUS_DATA_MASKING"]
    action data_mask_dst_mac_dst_ipv6_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];

 statTableEgress.count(index);
    }


    action data_mask_dst_mac_src_ipv6_dst_ipv6_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];

 statTableEgress.count(index);
    }

    action data_mask_dst_mac_src_ipv6_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_ipv6_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_src_ipv6_dst_ipv6_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_src_ipv6_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_dst_ipv6_egress(bit<64> mac_src, bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv6_dst_ipv6_egress(bit<64> mac_src, bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv6_egress(bit<64> mac_src, bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];

 statTableEgress.count(index);
    }


    action data_mask_src_ipv6_dst_ipv6_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 statTableEgress.count(index);
    }

    action data_mask_dst_ipv6_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 statTableEgress.count(index);
    }

    action data_mask_src_ipv6_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 statTableEgress.count(index);
    }

    action data_mask_src_ipv4_dst_ipv4_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.ipv4.dst_addr = mask_val;
        statTableEgress.count(index);
    }

    action data_mask_dst_mac_dst_ipv4_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
        statTableEgress.count(index);
    }

    action data_mask_dst_mac_src_ipv4_dst_ipv4_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
        statTableEgress.count(index);
    }

    action data_mask_dst_mac_src_ipv4_egress(bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
        hdr.mac.dst_addr = mac_dst[47:0];
        statTableEgress.count(index);
    }

    action data_mask_dst_ipv4_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 statTableEgress.count(index);
    }

    action data_mask_src_ipv4_egress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 statTableEgress.count(index);
    }

    action data_mask_dst_mac_egress(bit<64> mac_dst, StatIndex_t index)
    {
        hdr.mac.dst_addr = mac_dst[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_ipv4_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_src_ipv4_dst_ipv4_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_src_ipv4_egress(bit<64> mac_src, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_dst_ipv4_egress(bit<64> mac_src, bit<64> mac_dst,bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv4_dst_ipv4_egress(bit<64> mac_src, bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv4_egress(bit<64> mac_src, bit<64> mac_dst, bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.dst_addr = mac_dst[47:0];
 hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_dst_mac_egress(bit<64> mac_src, bit<64> mac_dst, StatIndex_t index)
    {
        hdr.mac.src_addr = mac_src[47:0];
        hdr.mac.dst_addr = mac_dst[47:0];
        statTableEgress.count(index);
    }

    action data_mask_src_mac_egress(bit<64> mac_src, StatIndex_t index)
    {
        hdr.mac.src_addr = mac_src[47:0];
        statTableEgress.count(index);
    }

    table data_mask_action_egress {
 actions = {
     @defaultonly nop;

            data_mask_dst_ipv6_egress();

     data_mask_src_ipv6_dst_ipv6_egress();
     data_mask_src_ipv6_egress();

            data_mask_dst_mac_dst_ipv6_egress();
            data_mask_dst_mac_src_ipv6_dst_ipv6_egress();
            data_mask_dst_mac_src_ipv6_egress();

            data_mask_src_mac_dst_ipv6_egress();
            data_mask_src_mac_src_ipv6_dst_ipv6_egress();
            data_mask_src_mac_src_ipv6_egress();
            data_mask_src_mac_dst_mac_dst_ipv6_egress();
            data_mask_src_mac_dst_mac_src_ipv6_dst_ipv6_egress();
     data_mask_src_mac_dst_mac_src_ipv6_egress();

     data_mask_dst_ipv4_egress();

     data_mask_src_ipv4_dst_ipv4_egress();
     data_mask_src_ipv4_egress();

            data_mask_dst_mac_dst_ipv4_egress();
            data_mask_dst_mac_src_ipv4_dst_ipv4_egress();
            data_mask_dst_mac_src_ipv4_egress();
     data_mask_dst_mac_egress();

            data_mask_src_mac_dst_ipv4_egress();
            data_mask_src_mac_src_ipv4_dst_ipv4_egress();
            data_mask_src_mac_src_ipv4_egress();
            data_mask_src_mac_dst_mac_dst_ipv4_egress();
            data_mask_src_mac_dst_mac_src_ipv4_dst_ipv4_egress();
     data_mask_src_mac_dst_mac_src_ipv4_egress();
            data_mask_src_mac_dst_mac_egress();
     data_mask_src_mac_egress();
 }

 /* Entries to be programmed by control plane upon DM
         * configuration on NP, TP or DF. Note that there
 	 * is also an additional "mask value" parameter
	 * which is configurable from the GUI which control 
	 * plane will have to overwrite if config changes.
	 * default at init time can be 0xFF*/
     key = {
        hdr.mac.isValid() : ternary @name("mac_valid");
        hdr.ipv4.isValid() : ternary @name("ipv4_valid");
     hdr.ipv6.isValid() : ternary @name("ipv6_valid");
     egress_port : ternary @name("tp_port");
     egress_rid : ternary @name("rid");
        }

 const default_action = nop;
 size = 512;
    }

    @ps_plus_data_mask[filterType="network", psPlusFeature="PS_PLUS_DATA_MASKING"]
    action data_mask_dst_mac_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_dst_mac_src_ipv6_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_dst_mac_src_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_src_mac_src_ipv6_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_src_mac_src_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
 statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
 statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv6_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];

 statTableIngress.count(index);
    }


    action data_mask_src_ipv6_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 statTableIngress.count(index);
    }

    action data_mask_dst_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.dst_addr[31:0] = mask_val;
 hdr.ipv6.dst_addr[63:32] = mask_val;
 hdr.ipv6.dst_addr[95:64] = mask_val;
 hdr.ipv6.dst_addr[127:96] = mask_val;
 statTableIngress.count(index);
    }

    action data_mask_src_ipv6_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv6.src_addr[31:0] = mask_val;
 hdr.ipv6.src_addr[63:32] = mask_val;
 hdr.ipv6.src_addr[95:64] = mask_val;
 hdr.ipv6.src_addr[127:96] = mask_val;
 statTableIngress.count(index);
    }

    action data_mask_src_ipv4_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.ipv4.dst_addr = mask_val;
        statTableIngress.count(index);
    }

    action data_mask_dst_mac_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_dst_mac_src_ipv4_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_dst_mac_src_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 statTableIngress.count(index);
    }

    action data_mask_src_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 statTableIngress.count(index);
    }

    action data_mask_dst_mac_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_src_ipv4_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_src_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv4_dst_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.dst_addr = mask_val;
 hdr.ipv4.src_addr = mask_val;
        hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_src_ipv4_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.ipv4.src_addr = mask_val;
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_dst_mac_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.mac.dst_addr[31:0] = mask_val;
 hdr.mac.dst_addr[47:32] = mask_val[15:0];
        hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    action data_mask_src_mac_ingress(bit<32> mask_val, StatIndex_t index)
    {
 hdr.mac.src_addr[31:0] = mask_val;
 hdr.mac.src_addr[47:32] = mask_val[15:0];
        statTableIngress.count(index);
    }

    table data_mask_action_ingress {
 actions = {
     @defaultonly nop;

            data_mask_dst_ipv6_ingress();

     data_mask_src_ipv6_dst_ipv6_ingress();
     data_mask_src_ipv6_ingress();

            data_mask_dst_mac_dst_ipv6_ingress();
            data_mask_dst_mac_src_ipv6_dst_ipv6_ingress();
            data_mask_dst_mac_src_ipv6_ingress();

            data_mask_src_mac_dst_ipv6_ingress();
            data_mask_src_mac_src_ipv6_dst_ipv6_ingress();
            data_mask_src_mac_src_ipv6_ingress();
            data_mask_src_mac_dst_mac_dst_ipv6_ingress();
            data_mask_src_mac_dst_mac_src_ipv6_dst_ipv6_ingress();
     data_mask_src_mac_dst_mac_src_ipv6_ingress();

     data_mask_dst_ipv4_ingress();

     data_mask_src_ipv4_dst_ipv4_ingress();
     data_mask_src_ipv4_ingress();

            data_mask_dst_mac_dst_ipv4_ingress();
            data_mask_dst_mac_src_ipv4_dst_ipv4_ingress();
            data_mask_dst_mac_src_ipv4_ingress();
     data_mask_dst_mac_ingress();

            data_mask_src_mac_dst_ipv4_ingress();
            data_mask_src_mac_src_ipv4_dst_ipv4_ingress();
            data_mask_src_mac_src_ipv4_ingress();
            data_mask_src_mac_dst_mac_dst_ipv4_ingress();
            data_mask_src_mac_dst_mac_src_ipv4_dst_ipv4_ingress();
     data_mask_src_mac_dst_mac_src_ipv4_ingress();
            data_mask_src_mac_dst_mac_ingress();
     data_mask_src_mac_ingress();

 }

 /* Entries to be programmed by control plane upon DM
         * configuration on NP, TP or DF. Note that there
 	 * is also an additional "mask value" parameter
	 * which is configurable from the GUI which control 
	 * plane will have to overwrite if config changes.
	 * default at init time can be 0xFF*/
     key = {
        hdr.mac.isValid() : ternary @name("mac_valid");
        hdr.ipv4.isValid() : ternary @name("ipv4_valid");
     hdr.ipv6.isValid() : ternary @name("ipv6_valid");
     ingress_port : ternary @name("np_port");
        }

 const default_action = nop;
 size = 64;
    }

    /* Configuration bits used in ingress and egress
     * bit 0     : mac src masking on NP
     * bit 1     : mac dest masking on NP
     * bit 2     : IP src masking on NP (both v4 and v6)
     * bit 3     : IP dest maskign on NP (both v4 and v6)	
     */
    apply {
 data_mask_action_ingress.apply();
 data_mask_action_egress.apply();
 /*Not updating IP/TCP/UDP checksums for this feature, as monitoring tools don't care*/
    }
}
# 166 "bfs.p4" 2
# 1 "trunk.p4" 1
/**
 * trunk.p4 - Action profiles/selector for inline port groups
 * Copyright Keysight Technologies 2021
 */

control calc_ip_hash(
    in ingress_metadata_t ig_md,
    out bit<32> hash)
     (bit<32> coeff)
{
    CRCPolynomial<bit<32>>(
        coeff = coeff,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly;
    @pragma symmetric "ig_md.inner_ip_src_addr","ig_md.inner_ip_dst_addr"
    @pragma symmetric "ig_md.hash_inner_l4_srcport","ig_md.hash_inner_l4_dstport"
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) hash_algo;

    action do_hash() {
        hash = hash_algo.get({
                ig_md.inner_ip_src_addr,
                ig_md.inner_ip_dst_addr,
                ig_md.inner_ip_protocol,
                ig_md.hash_inner_l4_srcport,
                ig_md.hash_inner_l4_dstport
            });
    }

    apply {
        do_hash();
    }
}

control calc_ip_hashes(
    in ingress_metadata_t ig_md,
    inout bit<64> hash)
{
    calc_ip_hash(coeff=0x04C11DB7) hash1;
    calc_ip_hash(coeff=0x1EDC6F41) hash2;

    apply {
        hash1.apply(ig_md, hash[31:0]);
        hash2.apply(ig_md, hash[63:32]);
    }
}

control process_trunk(
    inout ingress_header_t hdr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
    inout ingress_metadata_t ig_md)
{

    bit<64> hash = 0;

    action nop() {}

    action send(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    /*
     * df_config is dynamic filter config value.
     * 1 - VLAN Tagging
     * 2 - VLAN stripping
     * 3 - VLAN replacement
     * 4 - PS+ Hdr Stripping
     * 5 - PS+ Data Masking
     */
    action queue_send(PortId_t port,
                      bit<7> queue_id,
                      bit<3> df_config,
                      bit<16> df_config_value
                      ) {



        ig_intr_tm_md.qid = queue_id;

        ig_intr_tm_md.ucast_egress_port = port;
 hdr.br_md.df_config = df_config;
 hdr.br_md.df_config_value = df_config_value;
    }

    ActionProfile(size = 51200) port_entry;
    Hash<bit<61>>(HashAlgorithm_t.IDENTITY) final_hash;

    ActionSelector(
        action_profile = port_entry,
        hash = final_hash,
        mode = SelectorMode_t.RESILIENT,
        max_group_size = 3840,
        num_groups = 256) port_group_selector_entry;
    @selector_enable_scramble(1)
    @name("port_group")
    table port_group_tbl {
        key = {
            ig_md.port_group_id : exact;
            hash : selector;
        }
        actions = {
                  @defaultonly nop;
                  send;
                  queue_send;
                  }
        size = 256;
        implementation = port_group_selector_entry;
    }

    action outer_hash () {
        ig_md.inner_ip_src_addr = ig_md.ip_src_addr;
        ig_md.inner_ip_dst_addr = ig_md.ip_dst_addr;
        ig_md.inner_ip_protocol = ig_md.ip_protocol;
        ig_md.hash_inner_l4_srcport = ig_md.hash_outer_l4_srcport;
        ig_md.hash_inner_l4_dstport = ig_md.hash_outer_l4_dstport;
    }

    action layer2_hash () {
        ig_md.inner_ip_src_addr[47:0] = hdr.mac.src_addr;
        ig_md.inner_ip_dst_addr[47:0] = hdr.mac.dst_addr;
        ig_md.inner_ip_protocol = 0;
        ig_md.hash_inner_l4_srcport = ig_md.hash_outer_ether_type;
        ig_md.hash_inner_l4_dstport = 0;
        ig_md.inner_ip_src_addr[127:48] = 0;
        ig_md.inner_ip_dst_addr[127:48] = 0;
    }

    action src_ip_hash () {
        ig_md.inner_ip_src_addr = ig_md.ip_src_addr;
        ig_md.inner_ip_dst_addr = 0;
        ig_md.inner_ip_protocol = 0;
        ig_md.hash_inner_l4_srcport = 0;
        ig_md.hash_inner_l4_dstport = 0;
    }

    action dst_ip_hash () {
        ig_md.inner_ip_src_addr = ig_md.ip_dst_addr;
        ig_md.inner_ip_dst_addr = 0;
        ig_md.inner_ip_protocol = 0;
        ig_md.hash_inner_l4_srcport = 0;
        ig_md.hash_inner_l4_dstport = 0;
    }

    action inner_hash () { }

    @name("hash_key_selector")
    table hash_key_sel_tbl {
        key = {
            ig_md.l4_outer_info.srcport_typecode[11:8] : ternary @name("hash_type");
            hdr.ipv4.isValid() : ternary @name("ipv4_valid");
            hdr.ipv6.isValid() : ternary @name("ipv6_valid");
//            hdr.inner_ipv4.isValid()  : ternary @name("inner_ipv4_valid");
//            hdr.inner_ipv6.isValid()  : ternary @name("inner_ipv6_valid");
        }
        actions = {
                  @defaultonly nop;
                  outer_hash;
                  inner_hash;
                  layer2_hash;
                  src_ip_hash;
                  dst_ip_hash;
                  }
        size = 16;
 const default_action = nop;
    }

    apply {
        hash_key_sel_tbl.apply();
        calc_ip_hashes.apply(ig_md, hash);
        port_group_tbl.apply();
    }
}
# 167 "bfs.p4" 2

# 1 "vlan_classifier.p4" 1
/**
* vlan_classifier.p4 - VLAN classifiers
* Copyright Keysight Technologies 2020
*/

control process_vlans(
    inout ingress_header_t hdr,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_metadata_t ig_md,
    inout final_match_table_metadata_t final_match_table_metadata) {

    action nop() {
    }

    @name("setMatchIdOuterOuter")
    action set_outer_outer_vlan_match_id(bit<11> id) {
 final_match_table_metadata.outer_outer_vlan_matchid = id;
    }
    @name("outerOuterVlan")
    @brief("intersection")
    table outer_vlan_tbl{
 actions = {
            @defaultonly nop;
     @name("setOuterOuter")
            set_outer_outer_vlan_match_id;
 }
 key = {
            ig_md.outer_vlan : ternary @brief("VLAN");
     ig_md.port_config.vrf : exact @name("vrf");
 }
 const default_action = nop;
 size = 2048;
    }

    @name("setMatchIdOuterInner")
    action set_outer_inner_vlan_match_id(bit<11> id) {
 final_match_table_metadata.outer_inner_vlan_matchid = id;
    }

    @name("outerInnerVlan")
    @brief("intersection")
    table inner_vlan_tbl {
 actions = {
     @defaultonly nop;
     @name("setOuterInner")
            set_outer_inner_vlan_match_id;
 }
 key = {
     ig_md.inner_vlan : ternary @name("inner_vlan") @brief("INNER_VLAN");
     ig_md.port_config.vrf : exact @name("vrf");
 }
 const default_action = nop;
 size = 2048;
    }

/*    @name("setMatchIdInnerOuter")
    action set_inner_outer_vlan_match_id(bit<VLAN_MATCH_ID_SZ> id) {
	final_match_table_metadata.inner_outer_vlan_matchid = id;
    }

    @name("innerOuterVlan")
    @brief("intersection")
    table inner_outer_vlan_tbl{
	actions = {
            @defaultonly nop;
	    @name("setInnerOuter")
            set_inner_outer_vlan_match_id;
	}
	key = {
            hdr.inner_vlan_tag[0].vlan : ternary @name("inner_outer_vlan") @brief("INNER_OUTER_VLAN");
	    ig_md.port_config.vrf      : exact @name("vrf");
	}
	const default_action = nop;
	size = INNER_VLAN_TABLE_SIZE;
    }

    @name("setInnerInnerMatchId")
    action set_inner_inner_vlan_match_id(bit<VLAN_MATCH_ID_SZ> id) {
	final_match_table_metadata.inner_inner_vlan_matchid = id;
    }
    @name("innerInnerVlan")
    @brief("intersection")
    table inner_inner_vlan_tbl {
	actions = {
	    @defaultonly nop;
	    @name("setInnerInner")
            set_inner_inner_vlan_match_id;
	}
	key = {
            hdr.inner_vlan_tag[1].vlan : ternary @name ("inner_inner_vlan") @brief("INNER_INNER_VLAN");
	    ig_md.port_config.vrf      : exact @name("vrf");
	}
	const default_action = nop;
	size = INNER_VLAN_TABLE_SIZE;
    }
*/
    apply {
 if (ig_md.outer_vlan_valid) {
     outer_vlan_tbl.apply();
     if (ig_md.inner_vlan_valid) {
  inner_vlan_tbl.apply();
     }
 }
/*	if (hdr.inner_vlan_tag[0].isValid()) {
            inner_outer_vlan_tbl.apply();
	    if (hdr.inner_vlan_tag[1].isValid()) {
		inner_inner_vlan_tbl.apply();
	    }
	}
*/ }
}
# 169 "bfs.p4" 2
# 1 "l2_classifier.p4" 1
/**
* l2_classifier.p4 - L2 MAC ClassifierVLAN classifiers
* Copyright Keysight Technologies 2020
*/

/*  Outer l2 criteria  */

control process_l2(
 inout ingress_header_t hdr,
 in ingress_intrinsic_metadata_t ig_intr_md,
 inout ingress_metadata_t ig_md,
 inout final_match_table_metadata_t final_match_table_metadata) {

 action nop() {
 }

 /* Outer mac destination  address */
 @name("setMatchIdDstMac")
 action set_l2_outer_mac_da_matchid(bit<11> id) {
  final_match_table_metadata.outer_mac_dst_matchid = id;
 }

 @name("dstMac")
 @brief("intersection")
 table l2_outer_mac_da_tbl {
  actions = {
   @defaultonly nop;
   set_l2_outer_mac_da_matchid;
  }
  key = {
   hdr.mac.dst_addr : exact @name("mac_dst") @brief("MAC_DST");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  const default_action = nop;
  size = 512;
 }

 /* Outer mac source address */
 @name("setMatchIdSrcMac")
 action set_l2_outer_mac_sa_matchid(bit<11> id) {
 final_match_table_metadata.outer_mac_src_matchid = id;
 }

 @name("srcMac")
 @brief("intersection")
 table l2_outer_mac_sa_tbl {
  actions = {
   @defaultonly nop;
   set_l2_outer_mac_sa_matchid;
  }
  key = {
   hdr.mac.src_addr : exact @name("mac_src") @brief("MAC_SRC");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  const default_action = nop;
  size = 512;
 }

 /* Outer ether type */
 @name("setMatchIdEtherType")
 action set_l2_outer_ethertype_matchid(bit<8> id) {
  final_match_table_metadata.l2_outer_ethertype_matchid = id;
 }

 @name("etherType")
 @brief("intersection")
 table l2_outer_ethertype_tbl {
  actions = {
   @defaultonly nop;
   set_l2_outer_ethertype_matchid;
  }
  key = {
   hdr.ether_II.ether_type : exact @name("ether_type") @brief("ETHERTYPE");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  const default_action = nop;
  size = 256;
 }

 /* Inner ether type */
/*	@name("setMatchIdInnerEtherType")
	action set_l2_inner_ethertype_matchid(bit<L2_ET_MATCH_ID_SZ> id) {
		final_match_table_metadata.l2_inner_ethertype_matchid = id;
	}

	@name("innerEtherType")
	@brief("intersection")
	table l2_inner_ethertype_tbl {
		actions = {
			@defaultonly nop;
			set_l2_inner_ethertype_matchid;
		}
		key = {
			hdr.inner_ether_II.ether_type : exact @name("ether_type") @brief("INNER_ETHERTYPE");
			ig_md.port_config.vrf         : exact @name("vrf");
		}
		const default_action = nop;
		size = L2_ETHERTYPE_TABLE_SIZE;
	}
*/
 apply {
  /*
		* perform lookup - l2_outer.isValid() is part of
		* the key of these l2 tables
		*/
  l2_outer_mac_da_tbl.apply();
  l2_outer_mac_sa_tbl.apply();
  l2_outer_ethertype_tbl.apply();
//		if (ig_md.has_inner == 1) {
//			l2_inner_ethertype_tbl.apply();
//		}
 }
}
# 170 "bfs.p4" 2
# 1 "l3_classifier.p4" 1
/**
* l3_classifier.p4 - IPv4 classifiers
* Copyright Keysight Technologies 2020
*/

control process_l3(
 inout ingress_header_t hdr,
 in ingress_intrinsic_metadata_t ig_intr_md,
 inout ingress_metadata_t ig_md,
 inout final_match_table_metadata_t final_match_table_metadata) {

 action nop() {
 }

 /* Begin Outer Ipv4 Criteria */

 /* Outer ipv4 src */
 @name("setMatchIdOuterIpv4Src")
 action set_l3_ipv4_outer_src_matchid(bit<11> id) {
  final_match_table_metadata.outer_ipv4_src_matchid = id;
 }

 @name("srcIp")
 @brief("intersection")
 table ipv4_src_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_ipv4_outer_src_matchid;
  }
  key = {
   ig_md.ip_src_addr[31:0] : ternary @name("ipSrc") @brief("IPV4_SRC");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 2048;
  const default_action = nop;
 }

 /* Outer ipv4 dst */
 @name("setMatchIdOuterIpv4Dst")
 action set_l3_ipv4_outer_dst_matchid(bit<11> id) {
  final_match_table_metadata.outer_ipv4_dst_matchid = id;
 }

 @name("dstIp")
 @brief("intersection")
 table ipv4_dst_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_ipv4_outer_dst_matchid;
  }
  key = {
   ig_md.ip_dst_addr[31:0] : ternary @name("ipDst") @brief("IPV4_DST");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 2048;
  const default_action = nop;
 }

 /* ipv4 ip fragmentation */
 @name("setMatchIdOuterIpFrag")
 action set_l3_id_ipv4_frag_outer_matchid(bit<3> id) {
  final_match_table_metadata.outer_ip_frag_matchid = id;
 }

 @name("IpFrag")
 @brief("intersection")
 table ipv4_frag_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_id_ipv4_frag_outer_matchid;
  }
  key = {
   /*
			 * Non-Frag: Match id = 1
			 * 0. ipv4_valid = 0, ipv6_valid = 0, more_frag_bit = 0 (Non-IP)//one entry for each possible value of more_frag_bit
			 * 1. ipv4_valid = 0, ipv6_valid = 0, more_frag_bit = 1 (Non-IP - due to non deterministic more_frag_bit value when header is not valid)
			 * 2. ipv4_valid = 1, first_or_no_frag = 1, more_frag_bit = 0 //More frag bit is from flags
			 * 3. ipv6_valid = 1, ipv6_not_frag = 1 first_or_no_frag = 0, more_frag_bit = 0 // Non ipv6 fragment could have first_or_no_frag 0 or 1
			 * 4. ipv6_valid = 1, ipv6_not_frag = 1 first_or_no_frag = 0, more_frag_bit = 1 // Non ipv6 fragment could have first_or_no_frag 0 or 1
			 * 5. ipv6_valid = 1, ipv6_not_frag = 1 first_or_no_frag = 1, more_frag=0
			 * 6. ipv6_valid = 1, ipv6_not_frag = 1 first_or_no_frag = 1, more_frag=1 //v6 non fragment, more_frag_bit may be 1
			 * First Frag: Match id = 2
			 * 7. ipv4_valid = 1, first_or_no_frag = 1(gre or udp , more_frag_bit = 1
			 * 8. ipv6_valid = 1, first_or_no_frag = 1, ipv6_not_first_frag = 0, more_frag_bit =0//one entry for each possible value of more_frag_bit
			 * 9. ipv6_valid = 1, first_or_no_frag = 1, ipv6_not_first_frag = 0, more_frag_bit =1
			 * Not First Frag:Match id = 3
			 * 10. ipv4_valid = 1, first_or_no_frag = 0, more_frag_bit = 1 //not first fragment IPv4 packets
			 * 11. ipv4_valid = 1, first_or_no_frag = 0, more_frag_bit = 0 //literally last fragment packet
			 * 12. ipv6_valid = 1, ipv6_not_first_frag = 1, more_frag_bit = 0 //one entry for each possible value of more_frag_bit
			 * 13. ipv6_valid = 1, ipv6_not_first_frag = 1, more_frag_bit = 1
			*/
   hdr.ipv4.isValid() : exact @name("ipv4_valid");
   hdr.ipv4.flags[0:0] : exact @name("more_frag_bit");
   ig_md.outer_first_fragment : exact @name("first_or_no_frag") @brief("IP_FRAGMENT");
   hdr.ipv6.isValid() : exact @name("ipv6_valid");
   ig_md.ipv6_no_frag : exact @name("ipv6_not_frag");
   ig_md.ipv6_not_first_frag : exact @name("ipv6_not_first_frag");
  }
  size = 64;
  const default_action = nop;
 }

 /* Outer ipv4 ip protocol */
 @name("setMatchIdOuterIpProto")
 action set_l3_id_ipv4_proto_outer_matchid(bit<8> id) {
  final_match_table_metadata.outer_ip_prot_matchid = id;
 }

 @name("IpProto")
 @brief("intersection")
 table ipv4_proto_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_id_ipv4_proto_outer_matchid;
  }
  key = {
   ig_md.ip_protocol : ternary @name("ipv4_protocol") @brief("IP_PROTOCOL");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 512;
  const default_action = nop;
 }

 /* IPv4/6 Traffic Class */
 @name("setMatchIdOuterIpdsTc")
 action set_l3_ipv_dstc_outer_matchid(bit<8> id) {
  final_match_table_metadata.outer_ip_dstc_matchid = (bit<8>) id;
 }

 @name("dsTc")
 @brief("intersection")
 table ip_dsTc_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_ipv_dstc_outer_matchid;
  }
  key = {
   ig_md.port_config.vrf : exact @name("vrf");
   ig_md.dsTc : ternary @name("dsTc") @brief("DSCP");
  }
  size = 256;
  const default_action = nop;
 }

 /* outer src l4 port */
 @name("setMatchIdOuterL4SrcPort")
 action set_l4_outer_srcport_id(bit<11> id) {
  final_match_table_metadata.outer_l4_srcport_matchid = id;
 }

 @name("srcPort")
 @brief("intersection")
 table l4_outer_srcport_tbl {
  actions = {
   @defaultonly nop;
   set_l4_outer_srcport_id;
  }
  key = {
   ig_md.l4_outer_info.srcport_typecode : ternary @name("srcport_typecode") @brief("LAYER4_SRC_PORT");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 2048;
  const default_action = nop;
 }

 /* l4 dst port tbl */
 @name("setMatchIdOuterL4DstPort")
 action set_l4_outer_dstport_id(bit<11> id) {
  final_match_table_metadata.outer_l4_dstport_matchid = id;
 }

 @name("dstPort")
 @brief("intersection")
 table l4_outer_dstport_tbl {
  actions = {
   @defaultonly nop;
   set_l4_outer_dstport_id;
  }
     key = {
   ig_md.l4_outer_info.dstport_chksum : ternary @name("dstport_chksum") @brief("LAYER4_DST_PORT");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 2048;
  const default_action = nop;
 }

 /* tcp control flags */
 @name("setMatchIdOuterTcpControl")
 action set_outer_tcp_control(bit<4> id) {
  final_match_table_metadata.outer_tcp_control_matchid = id;
 }

 @name("tcpFlags")
 @brief("intersection")
 table l4_outer_tcp_control_tbl {
  actions = {
   @defaultonly nop;
   set_outer_tcp_control;
  }
  key = {
   hdr.tcp.flags : ternary @name("flags") @brief("TCP_CONTROL");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 64;
  const default_action = nop;
 }
 /* Begin Outer Ipv4 Criteria */


 /* Begin Ipv4 Inner Criteria */
 /* Inner ipv4 source */
/*	@name("setMatchIdInnerIpv4Src")
	action set_l3_ipv4_inner_src_matchid(bit<L3_MATCH_ID_SZ> id) {
		final_match_table_metadata. inner_ipv4_src_matchid = id;
	}

	@name("innerSrc")
	@brief("intersection")
	table ipv4_src_inner_tbl {
		actions = {
			@defaultonly nop;
			set_l3_ipv4_inner_src_matchid;
		}
		key = {
			ig_md.inner_ip_src_addr[31:0] : ternary @name("innerIpv4Src") @brief("INNER_IPV4_SRC_ADDR");
			ig_md.port_config.vrf         : exact @name("vrf");
		}
		size = IPV4_SRC_TABLE_SIZE;
		const default_action = nop;
	}

	/* Inner ipv4 dst */
/*	@name("setMatchIdInnerIpv4Dst")
	action set_l3_ipv4_inner_dst_matchid(bit<L3_MATCH_ID_SZ> id) {
		final_match_table_metadata.inner_ipv4_dst_matchid = id;
	}

	@name("innerDst")
	@brief("intersection")
	table ipv4_dst_inner_tbl {
		actions = {
			@defaultonly nop;
			set_l3_ipv4_inner_dst_matchid;
		}
		key = {
			ig_md.inner_ip_dst_addr[31:0] : ternary @name("innerIpv4Dst") @brief("INNER_IPV4_DST_ADDR");
			ig_md.port_config.vrf         : exact @name("vrf");
		}
		size = IPV4_DST_TABLE_SIZE;
		const default_action = nop;
	}

	/* Inner ipv4 protocol */
/*	@name("setMatchIdInnerIpv4Proto")
	action set_l3_id_ipv4_proto_inner_matchid(bit<IP_PROT_MATCH_ID_SZ> id) {
		final_match_table_metadata.inner_ip_prot_matchid = id;
	}

	@name("innerProto")
	@brief("intersection")
	table ipv4_proto_inner_tbl {
		actions = {
			@defaultonly nop;
			set_l3_id_ipv4_proto_inner_matchid;
		}
		key = {
			ig_md.inner_ip_protocol : ternary @name("innerIpProtocol") @brief("INNER_IP_PROTOCOL");
			ig_md.port_config.vrf   : exact @name("vrf");
		}
		size = IPV4_PROTO_TABLE_SIZE;
		const default_action = nop;
	}

	/* inner l4 src port tbl */
/*	@name("setMatchIdInnerL4SrcPort")
	action set_l4_inner_srcport_id(bit<L4_MATCH_ID_SZ> id) {
		final_match_table_metadata.inner_l4_srcport_matchid = id;
	}

	@name("innerSrcPort")
	@brief("intersection")
	table l4_inner_srcport_tbl {
		actions = {
			@defaultonly nop;
			set_l4_inner_srcport_id;
		}
		key = {
			ig_md.l4_inner_info.srcport_typecode : ternary @name("srcport_typecode") @brief("INNER_IPV4_L4_SRC_PORT");
			ig_md.port_config.vrf : exact @name("vrf");
		}
		size = L4_PORT_TABLE_SIZE;
		const default_action = nop;
	}

	/* inner l4 dst port tbl */
/*	@name("setMatchIdInnerL4DstPort")
	action set_l4_inner_dstport_id(bit<L4_MATCH_ID_SZ> id) {
		final_match_table_metadata.inner_l4_dstport_matchid = id;
	}

	@name("innerDstPort")
	@brief("intersection")
	table l4_inner_dstport_tbl {
		actions = {
			@defaultonly nop;
			set_l4_inner_dstport_id;
		}
		key = {
			ig_md.l4_inner_info.dstport_chksum : ternary @name("dstport_typecode") @brief("INNER_IPV4_L4_DST_PORT");
			ig_md.port_config.vrf : exact @name("vrf");
		}
		size = L4_PORT_TABLE_SIZE;
		const default_action = nop;
	}
*/
 /* Begin Ipv6 outer criteria */
 /* Outer ipv6 src */
 @name("setMatchIdOuterIpv6Src")
 action set_l3_ipv6_outer_src_matchid(bit<11> id) {
  final_match_table_metadata.outer_ipv6_src_matchid = id;
 }

 @name("srcIpv6")
 @brief("intersection")
 table ipv6_src_outer_tbl {
  actions = {
   @defaultonly nop;
   set_l3_ipv6_outer_src_matchid;
  }
  key = {
   ig_md.ip_src_addr : ternary @name("ipv6SrcAddr") @brief("IPV6_SRC");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 1024;
  const default_action = nop;
 }

 /* Outer ipv6 dst */
 @name("setMatchIdOuterIpv6Dst")
 action set_l3_ipv6_outer_dst_matchid(bit<11> id) {
  final_match_table_metadata.outer_ipv6_dst_matchid = id;
 }

 @name ("dstIpv6")
 @brief("intersection")
 table ipv6_dst_outer_tbl {
 actions = {
   @defaultonly nop;
   set_l3_ipv6_outer_dst_matchid;
  }
  key = {
   ig_md.ip_dst_addr : ternary @name("ipv6DstAddr") @brief("IPV6_DST");
   ig_md.port_config.vrf : exact @name("vrf");
  }
  size = 1024;
  const default_action = nop;
 }
 /* End Ipv6 outer criteria */

 /* Begin Ipv6 inner criteria */
 /* Inner ipv6 source */
 @name("setMatchIdInnerIpv6Src")
 action set_l3_ipv6_inner_src_matchid(bit<11> id) {
  final_match_table_metadata.inner_ipv6_src_matchid = id;
 }

/*	@name("innerSrcIpv6")
	@brief("intersection")
	table ipv6_src_inner_tbl {
		actions = {
			@defaultonly nop;
			set_l3_ipv6_inner_src_matchid;
		}
		key = {
			ig_md.inner_ip_src_addr : ternary @name("innerIpv6SrcAddr") @brief("INNER_IPV6_SRC_ADDR");
			ig_md.port_config.vrf   : exact @name("vrf");
		}
		size = IPV6_SRC_TABLE_SIZE;
		const default_action = nop;
	}

	/* Inner ipv6 dst */
/*	@name("setMatchIdInnerIpv6Dst")
	action set_l3_ipv6_inner_dst_matchid(bit<L3_MATCH_ID_SZ> id) {
		final_match_table_metadata.inner_ipv6_dst_matchid = id;
	}

	@name("innerDstIpv6")
	@brief("intersection")
	table ipv6_dst_inner_tbl {
		actions = {
			@defaultonly nop;
			set_l3_ipv6_inner_dst_matchid;
		}
		key = {
			ig_md.inner_ip_dst_addr : ternary @name("innerIpv6DstAddr") @brief("INNER_IPV6_DST_ADDR");
			ig_md.port_config.vrf   : exact @name("vrf");
		}
		size = IPV6_DST_TABLE_SIZE;
		const default_action = nop;
	}
*/ /* End Ipv6 inner criteria */


 /* Begin GTP_TEID Criteria */
 /* GTP TEID */
/*	@name("setMatchIdGtpTeid")
	action set_gtp_teid_matchid(bit<GTP_TEID_MATCH_ID_SZ> id) {
		final_match_table_metadata.gtp_teid_matchid = id;
	}

	@name("gtpTeid")
	@brief("intersection")
	table gtp_teid_tbl {
		actions = {
			@defaultonly nop;
			set_gtp_teid_matchid;
		}
		key = {
			hdr.gtpu.teid         : ternary @name("gtpTeid") @brief("GTP_TEID");  // we only need first 2 bytes; use entire 4 byte field for now since we have space, restrict if future needed  
			ig_md.port_config.vrf : exact @name("vrf");
		}
		size = GTP_TEID_TABLE_SIZE;
		const default_action = nop;
	}
*/ /* End GTP TEID Criteria */



 apply {
  if (hdr.ipv4.isValid()) {
   ipv4_dst_outer_tbl.apply();
   ipv4_src_outer_tbl.apply();
   ip_dsTc_outer_tbl.apply();
   l4_outer_srcport_tbl.apply();
   l4_outer_dstport_tbl.apply();
   ipv4_frag_outer_tbl.apply();
   ipv4_proto_outer_tbl.apply();
   l4_outer_tcp_control_tbl.apply();
  }
  else if (hdr.ipv6.isValid()) {
   ipv6_dst_outer_tbl.apply();
   ipv6_src_outer_tbl.apply();
   ip_dsTc_outer_tbl.apply();
   l4_outer_srcport_tbl.apply();
   l4_outer_dstport_tbl.apply();
   ipv4_frag_outer_tbl.apply();
   ipv4_proto_outer_tbl.apply();
   l4_outer_tcp_control_tbl.apply();
  }
//		if (ig_md.has_inner == 1) {
//			if (hdr.inner_ipv4.isValid()) {
//				ipv4_dst_inner_tbl.apply();
//				ipv4_src_inner_tbl.apply();
//				l4_inner_srcport_tbl.apply();
//				l4_inner_dstport_tbl.apply();
//				ipv4_proto_inner_tbl.apply();

//				if (hdr.gtpu.isValid()) {
//					gtp_teid_tbl.apply();
//				}

//			}

//			else if (hdr.inner_ipv6.isValid()) {
//				ipv6_dst_inner_tbl.apply();
//				ipv6_src_inner_tbl.apply();
//				l4_inner_srcport_tbl.apply();
//				l4_inner_dstport_tbl.apply();
//				ipv4_proto_inner_tbl.apply();

//				if (hdr.gtpu.isValid()) {
//					gtp_teid_tbl.apply();
//				}

 //			}

//		}
 }
}
# 171 "bfs.p4" 2
# 1 "final_match_table.p4" 1
/**
* final_match_table.p4 -
* Processes the final match table.  This tables
* processes the accumulates match ids from all
* of preceding qualifier matches.
* Copyright Keysight Technologies 2020
*/

control process_final_match_table(
 inout ingress_header_t hdr,
 in ingress_intrinsic_metadata_t ig_intr_md,
 inout ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
 inout final_match_table_metadata_t final_match_table_metadata) {

 /*
	* The statTable (indirect) for final match table. The index points
	* to a statTable entry. Multiple rules can point to the same entry.
	*/

 /*
	* Annotations for statTable used by Stats service
	* statTag correlates counters for multiple table reads in a single thread
	*/
 @KS_stats_service_counter(statTag)
 @KS_stats_service_columns(StatIndex, Packets, Bytes)
 @KS_stats_service_units(packets, bytes)
 Counter<PacketByteCounter_t, StatIndex_t> (
  2048, CounterType_t.PACKETS_AND_BYTES) statTable;

 action nop() {}

 action deny(StatIndex_t index) {
  ig_intr_dprsr_md.drop_ctl = 0x1;
  statTable.count(index);
 }

 /*
	 * df_config is dynamic filter config value.
	 * 1 - VLAN Tagging
	 * 2 - VLAN stripping
	 * 3 - VLAN replacement
	 * 4 - 2 VLAN Stripping
	 * 5 - PS+ Data Masking
	 */
 action unicast(bit<9> egress_port,
  bit<7> queue_id,
  StatIndex_t statIndex,
  bit<3> df_config,
  bit<16> df_config_value) {
  ig_intr_tm_md.ucast_egress_port = egress_port;



  ig_intr_tm_md.qid = queue_id;

  statTable.count(statIndex);
  hdr.br_md.df_config = df_config;
  hdr.br_md.df_config_value = df_config_value;
 }

 /*
	 * df_config is dynamic filter config value.
	 * 1 - VLAN Tagging
	 * 2 - VLAN stripping
	 * 3 - VLAN replacement
	 * 4 - 2 VLAN Stripping
	 * 5 - PS+ Data Masking
	 * port_group_id - for action profile based PG
	 * port_group_hash_type - hash type for action profile based PG
	 */
 action multicast(bit<16> mgid1,
  hash_type_t level1_hash_type,
  hash_type_t level2_hash_type,
  hash_type_t port_group_hash_type,
  bit<8> port_group_id,
  bit<3> df_config,
  bit<16> df_config_value,
  bool hash_enable,
  StatIndex_t statIndex) {
  ig_intr_tm_md.mcast_grp_a = mgid1; // mcast group ID 1
  /*
		 * Reusing the outer vlan variable in the ingress meta data
		 * to store the hash type values instead of a new variable.
		 * The outer vlan variable is not useful after all the filtering
		 * lookups and ingress VLAN operations are done.
		 */
  ig_md.l4_outer_info.srcport_typecode[3:0] = level1_hash_type;
  ig_md.l4_outer_info.srcport_typecode[7:4] = level2_hash_type;
  ig_md.l4_outer_info.srcport_typecode[11:8] = port_group_hash_type;
  ig_md.port_group_id = port_group_id;
  ig_md.hash_enable = hash_enable;
  statTable.count(statIndex);
  hdr.br_md.df_config = df_config;
  hdr.br_md.df_config_value = df_config_value;
 }

 /*
	 * df_config is dynamic filter config value.
	 * 1 - VLAN Tagging
	 * 2 - VLAN stripping
	 * 3 - VLAN replacement
	 * 4 - 2 VLAN Stripping
	 * 5 - PS+ Data Masking
	 * Please note that unicast action and action profile PG cannot co-exist.
	 */
 action unicast_multicast(bit<16> mgid1,
  hash_type_t level1_hash_type,
  hash_type_t level2_hash_type,
  bit<9> egress_port,
  bit<7> queue_id,
  bit<3> df_config,
  bit<16> df_config_value,
  bool hash_enable,
  StatIndex_t statIndex) {
  ig_intr_tm_md.mcast_grp_a = mgid1; // mcast group ID 1
  /*
		 * Reusing the outer vlan variable in the ingress meta data
		 * to store the hash type values instead of a new variable.
		 * The outer vlan variable is not useful after all the filtering
		 * lookups and ingress VLAN operations are done.
		 */
  ig_md.l4_outer_info.srcport_typecode[3:0] = level1_hash_type;
  ig_md.l4_outer_info.srcport_typecode[7:4] = level2_hash_type;
  ig_md.hash_enable = hash_enable;
  statTable.count(statIndex);
  hdr.br_md.df_config = df_config;
  hdr.br_md.df_config_value = df_config_value;



  ig_intr_tm_md.qid = queue_id;

  ig_intr_tm_md.ucast_egress_port = egress_port;
 }

 @brief("intersectionMainTable")
 @name("rule")
 table final_match_table {
  actions = {
   @defaultonly nop;
   deny;
   unicast;
   multicast;
   unicast_multicast;
  }
 key = {
  ig_md.port_config.filter_vrf : ternary @name("vrf");
  /* Outer Criteria*/
  final_match_table_metadata.outer_mac_src_matchid: ternary;
  final_match_table_metadata.outer_mac_dst_matchid: ternary;
  final_match_table_metadata.l2_outer_ethertype_matchid: ternary;
  final_match_table_metadata.outer_outer_vlan_matchid: ternary;
  final_match_table_metadata.outer_inner_vlan_matchid: ternary;
  final_match_table_metadata.outer_ipv4_src_matchid: ternary;
  final_match_table_metadata.outer_ipv4_dst_matchid: ternary;
  final_match_table_metadata.outer_ip_dstc_matchid: ternary;
  final_match_table_metadata.outer_ip_prot_matchid: ternary;
  final_match_table_metadata.outer_ip_frag_matchid: ternary;
  final_match_table_metadata.outer_tcp_control_matchid: ternary;
  final_match_table_metadata.outer_ipv6_src_matchid: ternary;
  final_match_table_metadata.outer_ipv6_dst_matchid: ternary;
  final_match_table_metadata.outer_l4_srcport_matchid: ternary;
  final_match_table_metadata.outer_l4_dstport_matchid: ternary;
  /* Inner Criteria*/
  final_match_table_metadata.inner_outer_vlan_matchid: ternary;
  final_match_table_metadata.inner_inner_vlan_matchid: ternary;
  final_match_table_metadata.l2_inner_ethertype_matchid: ternary;
  final_match_table_metadata.inner_ipv4_src_matchid: ternary;
  final_match_table_metadata.inner_ipv4_dst_matchid: ternary;
  final_match_table_metadata.inner_ip_prot_matchid: ternary;

  final_match_table_metadata.inner_ipv6_src_matchid: ternary;
  final_match_table_metadata.inner_ipv6_dst_matchid: ternary;

  final_match_table_metadata.inner_l4_srcport_matchid: ternary;
  final_match_table_metadata.inner_l4_dstport_matchid: ternary;
  final_match_table_metadata.gtp_teid_matchid: ternary;
 }
 size = 2048;
 const default_action = nop;
 }

 apply {
  final_match_table.apply();
 }
}
# 172 "bfs.p4" 2

# 1 "networkPortVlanTable.p4" 1
/**
* networkPortVlanTable.p4 - based on ingress port and VLAN to perform VLAN translation
* Copyright Keysight Technologies 2020
*/

control process_network_port_vlan (
    inout ingress_header_t hdr,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
    inout ingress_metadata_t ig_md) {

    action nop() { }

    action ingress_vlan_translation(bit<16> vlan) {
        hdr.vlan_tag[0].vlan[11:0] = vlan[11:0];
    }

    action from_cpu_to_port(PortId_t output_port) {
        // remove knet mark
 hdr.vlan_tag[0].setInvalid();
 ig_tm_md.ucast_egress_port = output_port;
    }

    @name("vlan_action")
    table network_port_vlan_tbl {
 actions = {
            @defaultonly nop;
            ingress_vlan_translation;
            from_cpu_to_port;
 }
 key = {
            ig_intr_md.ingress_port[8:0]: exact @name("ingress_port");
            hdr.vlan_tag[0].vlan[11:0] : exact @name("outer_vlan");
            ig_md.has_knet_mark : exact @name("has_knet_mark");
 }
 const default_action = nop;
 size = 4096;
    }

    apply {
        /*
         * Egress Parser will only work if the bridge header
         * is added correctly in the ingress. 
         * !!! DO NOT REMOVE !!!
         */
        hdr.br_md.setValid();
 hdr.br_md.header_type = HEADER_TYPE_BRIDGE;
 hdr.br_md.header_info = 0;
 hdr.br_md.ingress_port = ig_intr_md.ingress_port;
 hdr.br_md.vlan_config = 0;
 hdr.br_md.df_config = 0;
 hdr.br_md.knet_mark = 0;
 hdr.br_md.df_config_value = 0;
 hdr.br_md.hdr_stripping = false;
 hdr.br_md.vlan_stripping = 0;
        /*Need to pass to egress for all Time Stamp processing there*/
        hdr.br_md.ts = ig_intr_md.ingress_mac_tstamp;
        if (hdr.vlan_tag[0].isValid()) {
     network_port_vlan_tbl.apply();
        }
    }
}
# 174 "bfs.p4" 2
# 1 "networkPortMulticastHash.p4" 1
/**
 * networkPortMulticastHash.p4 - to choose L1 and L2 Hashing algorithm
 * Copyright Keysight Technologies 2020
 */

control process_multicast_hash(
    inout ingress_header_t hdr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
    inout ingress_metadata_t ig_md) {
    Hash<bit<13>> (HashAlgorithm_t.CRC32) hash_calc_dst_ip;
    Hash<bit<13>> (HashAlgorithm_t.CRC32) hash_calc_src_ip;
    @pragma symmetric "hdr.mac.src_addr","hdr.mac.dst_addr"
    Hash<bit<13>> (HashAlgorithm_t.CRC32) hash_calc_layer2;
//    Hash<bit<13>> (HashAlgorithm_t.CRC32)   hash_calc_mpls;
    @pragma symmetric "ig_md.ip_src_addr","ig_md.ip_dst_addr"
    @pragma symmetric "ig_md.hash_outer_l4_srcport","ig_md.hash_outer_l4_dstport"
    Hash<bit<13>> (HashAlgorithm_t.CRC32) hash_calc_outer_ip_5_tuple;
//    @pragma symmetric "ig_md.inner_ip_src_addr","ig_md.inner_ip_dst_addr"
//    @pragma symmetric "ig_md.hash_inner_l4_srcport","ig_md.hash_inner_l4_dstport"
//    Hash<bit<13>> (HashAlgorithm_t.CRC32)   hash_calc_inner_ip_5_tuple;
    bit<13> packet_type_hash = 0;
    bit<13> layer2_hash = 0;
//    bit<13> inner_packet_type_hash = 0;

    action nop() {}

    action random_level1_hash() {
        ig_intr_tm_md.level1_mcast_hash = ig_md.random_hash_value;
    }

    action outer_level1_hash() {
        ig_intr_tm_md.level1_mcast_hash = packet_type_hash;
    }

//    action inner_level1_hash() {
//        ig_intr_tm_md.level1_mcast_hash = inner_packet_type_hash;
//    }

    action layer2_level1_hash() {
        ig_intr_tm_md.level1_mcast_hash = layer2_hash;
    }

    action random_level2_hash() {
        ig_intr_tm_md.level2_mcast_hash = ig_md.random_hash_value;
    }

    action outer_level2_hash() {
        ig_intr_tm_md.level2_mcast_hash = packet_type_hash;
    }

//    action inner_level2_hash() {
//        ig_intr_tm_md.level2_mcast_hash = inner_packet_type_hash;
//    }

    action layer2_level2_hash() {
        ig_intr_tm_md.level2_mcast_hash = layer2_hash;
    }

    action src_ip_level2_hash() {
        ig_intr_tm_md.level2_mcast_hash = hash_calc_src_ip.get({ig_md.ip_src_addr});
    }

    action dst_ip_level2_hash() {
        ig_intr_tm_md.level2_mcast_hash = hash_calc_dst_ip.get({ig_md.ip_dst_addr});
    }

    @name("level1_hash_tbl")
    table level1_hash_tbl {
        key = {
            ig_md.l4_outer_info.srcport_typecode[3:0] : exact @name("hash_type");
        }
        actions = {
            @defaultonly nop;
            outer_level1_hash;
//            inner_level1_hash;
            random_level1_hash;
            layer2_level1_hash;
        }
        size = 16;
 const default_action = nop;
    }

    @name("level2_hash_tbl")
    table level2_hash_tbl {
        key = {
            ig_md.l4_outer_info.srcport_typecode[7:4] : exact @name("hash_type");
        }
        actions = {
            @defaultonly nop;
            outer_level2_hash;
//            inner_level2_hash;
            random_level2_hash;
            layer2_level2_hash;
            src_ip_level2_hash;
            dst_ip_level2_hash;
        }
        size = 16;
 const default_action = nop;
    }

    apply {
 layer2_hash = hash_calc_layer2.get({ hdr.mac.src_addr, hdr.mac.dst_addr, ig_md.hash_outer_ether_type});

/*        if (hdr.mpls[0].isValid() && ig_md.hash_mpls_include) {
            packet_type_hash = hash_calc_mpls.get({ hdr.mpls[0].label, hdr.mpls[1].label,
                    hdr.mpls[2].label, hdr.mpls[3].label,
                    hdr.mpls[4].label });

        }
	else */ if (hdr.ipv4.isValid() || hdr.ipv6.isValid()) {
            packet_type_hash = hash_calc_outer_ip_5_tuple.get({
      /* if v4, still 128 bits, upper 96 zero, v6 entire 128 */
      ig_md.ip_src_addr,
                    ig_md.ip_dst_addr,
                    ig_md.ip_protocol,
                    ig_md.hash_outer_l4_srcport,
                    ig_md.hash_outer_l4_dstport });
 }
        else {
            packet_type_hash = layer2_hash;
        }

/*        if (hdr.inner_ipv4.isValid() || hdr.inner_ipv6.isValid()) {
            inner_packet_type_hash = hash_calc_inner_ip_5_tuple.get({
		    /* if v4, still 128 bits, upper 96 zero, v6 entire 128 */
/*                    ig_md.inner_ip_src_addr,
                    ig_md.inner_ip_dst_addr,
                    ig_md.inner_ip_protocol,
                    ig_md.hash_inner_l4_srcport,
                    ig_md.hash_inner_l4_dstport
                });
        }
        else {
            inner_packet_type_hash = packet_type_hash;
        }
*/

        level1_hash_tbl.apply();
        level2_hash_tbl.apply();
    }
}
# 175 "bfs.p4" 2
# 1 "cpu_knet_classifier.p4" 1
/* -*- P4_16 -*- */





control process_ingress_control_plane(
 inout ingress_header_t hdr,
 in ingress_metadata_t ig_md,
 in bit<9> ingress_port,
 inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

        /*
        * Annotations for statTable used by Stats service
	* statTag correlates counters for multiple table reads in a single thread
	*/
 @KS_stats_service_counter(statTag)
 @KS_stats_service_columns(StatIndex, Packets, Bytes)
 @KS_stats_service_units(packets, bytes)
 Counter<PacketByteCounter_t, StatIndex_t> (
        1024, CounterType_t.PACKETS_AND_BYTES) statTableControlPlane;

 /*
	**** nop ***
	*/
 action icp_nop() {
 }

 /*
	**** To-CPU ***
	*/
 @name("toCpuWithKnetMark")
 action send_to_cpu_with_knet_mark(bit<12> knet_mark, StatIndex_t stat_index) {
  // add knet header
  hdr.br_md.knet_mark[15:15] = 0x1;
  hdr.br_md.knet_mark[11:0] = knet_mark;
  // set CPU port as destination
  ig_tm_md.copy_to_cpu = 0x1;
  statTableControlPlane.count(stat_index);
 }

 @name("exclusiveToCpuWithKnetMark")
 action exclusive_send_to_cpu_with_knet_mark(bit<12> knet_mark, StatIndex_t stat_index) {
  // add knet header
  hdr.br_md.knet_mark[15:15] = 0x1;
  hdr.br_md.knet_mark[11:0] = knet_mark;
  // set only CPU port as destination
  ig_tm_md.copy_to_cpu = 0x1;
  ig_dprsr_md.drop_ctl = 0x1;
  statTableControlPlane.count(stat_index);
 }

 @name("toCpuNoKnetMark")
 action send_to_cpu_without_knet_mark(StatIndex_t stat_index) {
  // set CPU port as destination
  ig_tm_md.copy_to_cpu = 0x1;
  statTableControlPlane.count(stat_index);
 }

 @name("exclusiveToCpuNoKnetMark")
 action exclusive_send_to_cpu_without_knet_mark(StatIndex_t stat_index) {
  // set CPU port as destination
  ig_tm_md.copy_to_cpu = 0x1;
  ig_dprsr_md.drop_ctl = 0x1;
  statTableControlPlane.count(stat_index);
 }

 /*
	**** To-port ***
	*/
 @name("toPort")
 action send_to_port(PortId_t output_port, StatIndex_t stat_index) {
  ig_tm_md.copy_to_cpu = 0x0;
  ig_dprsr_md.drop_ctl = 0x0;
  ig_tm_md.mcast_grp_a = 0x0;
  ig_tm_md.ucast_egress_port = output_port;
  statTableControlPlane.count(stat_index);
 }

        @brief("controlPlane")
 @name("ctrl_traffic")
 table ingress_control_plane_tbl {
  key = {
   ingress_port : ternary @name("input_port");
   hdr.mac.dst_addr : ternary @name("mac_dst") @brief("MAC_DST");
                        hdr.mac.src_addr : ternary @name("mac_src") @brief("MAC_SRC");
   hdr.ether_II.ether_type : ternary @name("ether_type") @brief("ETHERTYPE");
   ig_md.outer_vlan : ternary @name("outer_vlan") @brief("VLAN");
   ig_md.outer_vlan_valid : ternary @name("outer_vlan_valid");
   ig_md.inner_vlan : ternary @name("inner_vlan") @brief("INNER_VLAN");
   ig_md.inner_vlan_valid : ternary @name("inner_vlan_valid");
   ig_md.ip_protocol : ternary @name("ip_proto") @brief("IP_PROTOCOL");
   ig_md.ip_dst_addr : ternary @name("ip_dst") @brief("IPV4_DST");
  }
  actions = {
   send_to_cpu_with_knet_mark;
   send_to_cpu_without_knet_mark;
   exclusive_send_to_cpu_with_knet_mark;
   exclusive_send_to_cpu_without_knet_mark;
   send_to_port;
   icp_nop;
  }
  size = 1024;
 }

 /*
	**** apply ***
	*/
 apply {
     ingress_control_plane_tbl.apply();
 }
}
# 176 "bfs.p4" 2






# 1 "toolPortConfig.p4" 1
/**
* toolPortConfig.p4 - based on egress port, set the per port header stripping and VLAN stripping config
* Copyright Keysight Technologies 2020
*/

control process_port_config(
    inout egress_header_t hdr,
    in egress_intrinsic_metadata_t eg_intr_md,


    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,


    inout egress_metadata_t eg_md) {

    action nop() { }



    @ps_plus_trim[filterType="tool", psPlusFeature="PS_PLUS_PACKET_TRIMMING"]


    action set_port_config(bool hdr_stripping_enable,
             bit<1> dedup_enable,
                           bit<8> port_class_id,
                           bit<1> single_vlan_stripping,
                           bit<1> double_vlan_stripping,


                           bool trim_enable,
                           bit<14> trunc_len,


                           bool extra_pad_bytes) {
        eg_md.port_class_id = port_class_id;
        eg_md.single_vlan_stripping = single_vlan_stripping;
        eg_md.double_vlan_stripping = double_vlan_stripping;
        eg_md.hdr_stripping_enable = hdr_stripping_enable;
        eg_md.dedup_enable = dedup_enable;
        eg_md.extra_pad_bytes = extra_pad_bytes;


        if (trim_enable) {
            eg_intr_dprsr_md.mtu_trunc_len = trunc_len;
        }


    }

    action add_knet_header() {
        hdr.tnl_mac = hdr.mac;
        hdr.tnl_mac.setValid();
        hdr.mac.setInvalid();
        hdr.tnl_vlan_tag.vlan[11:0] = eg_md.br_md.knet_mark[11:0];
        hdr.tnl_vlan_tag.setValid();
    }

    @name("port_config")
    table egress_port_config {
 actions = {
            @defaultonly nop;
            set_port_config;
            add_knet_header;
 }
 key = {
     eg_intr_md.egress_port[8:0] : ternary @name("egress_port");
     eg_md.br_md.knet_mark[15:15] : ternary @name("has_knet_mark");
 }
 const default_action = nop;
 size = 128;
    }

    apply {


            eg_intr_dprsr_md.mtu_trunc_len = MAX_MTU_SIZE;


 egress_port_config.apply();
        /*
         * This is for the TPF as we might perform header stripping on the packet at a
         * later stage in the pipeline, but we will be able to perform TPF filtering on
         * the original egress packet based on this information
         */
        hdr.tnl_vlan_tag.tpid = ETHERTYPE_KNET;
 eg_md.outer_vlan_valid = hdr.vlan_tag[0].isValid();
 eg_md.inner_vlan_valid = hdr.vlan_tag[1].isValid();
 eg_md.ipv4_valid = hdr.ipv4.isValid();
 eg_md.ipv6_valid = hdr.ipv6.isValid();
 eg_md.outer_vlan = hdr.vlan_tag[0].vlan;
 eg_md.inner_vlan = hdr.vlan_tag[1].vlan;
    }
}
# 183 "bfs.p4" 2
# 1 "toolPortVlanTable.p4" 1
/**
* toolPortVlanTable.p4 - based on egress port and VLAN to perform VLAN stripping or VLAN replacement
* Copyright Keysight Technologies 2020
*/

control process_tool_port_vlan(
    inout egress_header_t hdr,
    in egress_intrinsic_metadata_t eg_intr_md,
    inout egress_metadata_t eg_md) {

    action nop() { }

    action single_vlan_stripping(bit<1> enable) {
        eg_md.single_vlan_stripping = enable;
    }

    action egress_vlan_translation(bit<16> vlan) {
        hdr.vlan_tag[0].vlan[11:0] = vlan[11:0];
    }

    @name("vlan_action")
    table tool_port_vlan_tbl {
 actions = {
            @defaultonly nop;
            single_vlan_stripping;egress_vlan_translation;
 }
 key = {
            eg_intr_md.egress_port[8:0]: exact @name("egress_port");
            hdr.vlan_tag[0].vlan[11:0] : exact @name("outer_vlan");
 }
 const default_action = nop;
 size = 4096;
    }

    apply {
     tool_port_vlan_tbl.apply();
        if (hdr.outer_vlan_tag.isValid()) {
         if (eg_md.single_vlan_stripping == 1 || hdr.outer_vlan_tag.vlan[11:0] == 0xFFF) {
             hdr.outer_vlan_tag.setInvalid();
         }
        }
        else if (hdr.vlan_tag[0].isValid()) {
            /*
             * Both egress_port_config and tool_port_vlan tables can set these 
             * VLAN stripping bits in the egress meta data
             */
         if (eg_md.single_vlan_stripping == 1 || hdr.vlan_tag[0].vlan[11:0] == 0xFFF) {
             hdr.vlan_tag[0].setInvalid();
         }
         if(eg_md.double_vlan_stripping == 1) {
             hdr.vlan_tag[0].setInvalid();
             hdr.vlan_tag[1].setInvalid();
            }
        } else if (hdr.inner_vlan_tag.isValid()) {
         if (eg_md.single_vlan_stripping == 1 || hdr.inner_vlan_tag.vlan[11:0] == 0xFFF) {
             hdr.inner_vlan_tag.setInvalid();
         }
        }
    }
}
# 184 "bfs.p4" 2
# 1 "toolPortFilters.p4" 1
/**
* toolPortFilters.p4
* Copyright Keysight Technologies 2020
*/

control processToolPortFilters(
    inout egress_header_t hdr,
    in egress_intrinsic_metadata_t eg_intr_md,
    inout egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {

    /*
    * Annotations for statTable used by Stats service
    * statTag correlates counters for multiple table reads in a single thread
    */
    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        512, CounterType_t.PACKETS_AND_BYTES) statTable;

    action nop() {
    }

    action pass(StatIndex_t index) {
 statTable.count(index);
        eg_intr_dprsr_md.drop_ctl = 0x0;
    }

    action deny(StatIndex_t index) {
 statTable.count(index);
        eg_intr_dprsr_md.drop_ctl = 0x1;
    }

    @brief("toolPortFilterMain")
    table toolPortFilter {
 actions = {
     @defaultonly nop;
     pass;
     deny;
 }
 key = {
            eg_md.port_class_id : exact @name("port_class_id");
     hdr.ether_II.ether_type : ternary @name("ethertype") @brief("ETHERTYPE");
     eg_md.outer_vlan : ternary @name("outer_vlan") @brief("VLAN");
     eg_md.outer_vlan_valid : ternary @name("outer_vlan_valid");
     eg_md.inner_vlan : ternary @name("inner_vlan") @brief("INNER_VLAN");
     eg_md.inner_vlan_valid : ternary @name("inner_vlan_valid");
     eg_md.ipv4_valid : ternary @name("ipv4_valid");
            hdr.ipv4.src_addr : ternary @name("ipv4_src") @brief("IPV4_SRC");
     hdr.ipv4.dst_addr : ternary @name("ipv4_dst") @brief("IPV4_DST");
            eg_md.ip_protocol : ternary @name("ip_protocol") @brief("IP_PROTOCOL");
     eg_md.ipv6_valid : ternary @name("ipv6_valid");
            hdr.ipv6.src_addr : ternary @name("ipv6_src") @brief("IPV6_SRC");
            hdr.ipv6.dst_addr : ternary @name("ipv6_dst") @brief("IPV6_DST");
            eg_md.l4_outer_info.srcport_typecode : ternary @name("l4_srcport_typecode") @brief("LAYER4_SRC_PORT");
            eg_md.l4_outer_info.dstport_chksum : ternary @name("l4_dstport_chksum") @brief("LAYER4_DST_PORT");
 }
 const default_action = nop;
 size = 512;
    }

    apply {
 toolPortFilter.apply();
    }
}
# 185 "bfs.p4" 2
# 1 "toolPortEncapTable.p4" 1
/**
* toolPortEncapTable.p4 - based on egress RID, this table will be used for NetServices VLAN tagging, header Stripping, Tunnel Encapsulation etc.,
* Copyright Keysight Technologies 2020
*/


control process_port_encap(
    inout egress_header_t hdr,
    in egress_intrinsic_metadata_t eg_intr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
    inout egress_metadata_t eg_md) {
    bool tnl_vlan_enable = false;
    bool tnl_l2gre_key = false;
    bool tnl_l2gre_seqnum= false;
    bool udp_src_hash_enable = false;
    bit<16> ipv4_len = 0;
    bit<16> udp_len = 0;
    bit<16> inner_ip_len = 0;
    /*
     * UDP source port in the VxLAN header should be in the range of 49152 - 65535 as per rfc7348
     */
    bit<16> src_port_hash = 0xC000;
   /*
    * Annotations for statTable used by Stats service
    * statTag correlates counters for multiple table reads in a single thread
    */

    @KS_stats_service_counter(statTag)
    @KS_stats_service_columns(StatIndex, Packets, Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<PacketByteCounter_t, StatIndex_t> (
        256, CounterType_t.PACKETS_AND_BYTES) statTable;

    @pragma symmetric "hdr.ipv4.src_addr","hdr.ipv4.dst_addr"
    @pragma symmetric "eg_md.l4_outer_info.srcport_typecode","eg_md.l4_outer_info.dstport_chksum"
    Hash<bit<14>> (HashAlgorithm_t.CRC32) hash_outer_ipv4_5_tuple;
    @pragma symmetric "hdr.ipv6.src_addr","hdr.ipv6.dst_addr"
    @pragma symmetric "eg_md.l4_outer_info.srcport_typecode","eg_md.l4_outer_info.dstport_chksum"
    Hash<bit<14>> (HashAlgorithm_t.CRC32) hash_outer_ipv6_5_tuple;
    @pragma symmetric "hdr.mac.src_addr","hdr.mac.dst_addr"
    Hash<bit<14>> (HashAlgorithm_t.CRC32) hash_layer2;


    Register<bit<32>, bit<8>>(size=256, initial_value=0) packet_num;
    RegisterAction<bit<32>, bit<8>, bit<32>>(packet_num)
    increment = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;
            register_data = register_data + 1;
        }
    };

    action nop() { }

    action no_action() {
    }

 action vlan_tagging_untagged(bit<16> vlan) {
  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].vlan = vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan_valid = true;
 }

 action vlan_tagging_single_tagged(bit<16> vlan) {
  hdr.vlan_tag[1].setValid();
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.inner_vlan_valid = true;
 }

 action vlan_tagging_double_tagged(bit<16> vlan) {
  hdr.vlan_tag[2].setValid();
  hdr.vlan_tag[2].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[2].tpid = hdr.vlan_tag[1].tpid;
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan = vlan;
 }

 action vlan_tagging_untagged_for_unicast() {
  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].vlan = eg_md.br_md.df_config_value;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = eg_md.br_md.df_config_value;
  eg_md.outer_vlan_valid = true;
 }

 action vlan_tagging_single_tagged_for_unicast() {
  hdr.vlan_tag[1].setValid();
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = eg_md.br_md.df_config_value;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = eg_md.br_md.df_config_value;
  eg_md.inner_vlan_valid = true;
 }

 action vlan_tagging_double_tagged_for_unicast() {
  hdr.vlan_tag[2].setValid();
  hdr.vlan_tag[2].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[2].tpid = hdr.vlan_tag[1].tpid;
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = eg_md.br_md.df_config_value;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = eg_md.br_md.df_config_value;
 }

 action vlan_stripping_for_single_tagged() {
  hdr.vlan_tag[0].setInvalid();
  eg_md.outer_vlan_valid = false;
        eg_md.df_vlans_stripped = 1;
  eg_md.outer_vlan = 0;
 }

 action vlan_stripping_for_double_tagged() {
  hdr.vlan_tag[0].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[0].tpid = hdr.vlan_tag[1].tpid;
  eg_md.outer_vlan = hdr.vlan_tag[1].vlan;
  eg_md.inner_vlan = 0;
  eg_md.inner_vlan_valid = false;
        eg_md.df_vlans_stripped = 1;
  hdr.vlan_tag[1].setInvalid();
 }

 action vlan_stripping_for_triple_tagged() {
  hdr.vlan_tag[0].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[0].tpid = hdr.vlan_tag[1].tpid;
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[2].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[2].tpid;
  eg_md.outer_vlan = hdr.vlan_tag[1].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[2].vlan;
        eg_md.df_vlans_stripped = 1;
  hdr.vlan_tag[2].setInvalid();
 }

 action double_vlan_stripping_for_double_tagged() {
  eg_md.outer_vlan_valid = false;
  eg_md.outer_vlan = 0;
  eg_md.inner_vlan_valid = false;
  eg_md.inner_vlan = 0;
        eg_md.df_vlans_stripped = 2;
  hdr.vlan_tag[0].setInvalid();
  hdr.vlan_tag[1].setInvalid();
 }

 action double_vlan_stripping_for_triple_tagged() {
  hdr.vlan_tag[0].vlan = hdr.vlan_tag[2].vlan;
  hdr.vlan_tag[0].tpid = hdr.vlan_tag[2].tpid;
  eg_md.outer_vlan = hdr.vlan_tag[2].vlan;
  eg_md.inner_vlan = 0;
  eg_md.inner_vlan_valid = false;
        eg_md.df_vlans_stripped = 2;
  hdr.vlan_tag[1].setInvalid();
  hdr.vlan_tag[2].setInvalid();
 }

    //For Dynamic filter VLAN replace cases
    //Even if the Egress Port had VLAN Stripping enabled
    //The outer VLAN of the egressing packet should be translated
    //based on the VLAN translate option on the Dynamic filter
    action vlan_translate(bit<16> vlan) {
        hdr.vlan_tag[0].vlan[11:0] = vlan[11:0];
 eg_md.outer_vlan = vlan;
    }

    action vlan_translate_for_unicast() {
        hdr.vlan_tag[0].vlan = eg_md.br_md.df_config_value;
 eg_md.outer_vlan = eg_md.br_md.df_config_value;
    }

    //For Header stripping options on a DF
    action set_header_strip_options() {
        //We will only perform HDR stripping for the given DF index
        eg_md.hdr_stripping_enable = true;
    }

/*TBD - For Dedup image - add proper changes later */

    action tagging_untagged_l2gre_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bool key_valid,
                        bit<32> key,
                        bool seqnum_valid,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_gre_key.data = key;
        tnl_vlan_enable = vlan_enable;
        tnl_l2gre_seqnum = seqnum_valid;
        tnl_l2gre_key = key_valid;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = inner_vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan_valid = true;
 statTable.count(index);
    }

    action tagging_single_tagged_l2gre_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bool key_valid,
                        bit<32> key,
                        bool seqnum_valid,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_gre_key.data = key;
        tnl_vlan_enable = vlan_enable;
        tnl_l2gre_seqnum = seqnum_valid;
        tnl_l2gre_key = key_valid;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[1].setValid();
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = inner_vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.inner_vlan_valid = true;
 statTable.count(index);
    }

    action tagging_double_tagged_l2gre_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bool key_valid,
                        bit<32> key,
                        bool seqnum_valid,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_gre_key.data = key;
        tnl_vlan_enable = vlan_enable;
        tnl_l2gre_seqnum = seqnum_valid;
        tnl_l2gre_key = key_valid;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[2].setValid();
  hdr.vlan_tag[2].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[2].tpid = hdr.vlan_tag[1].tpid;
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan = inner_vlan;
 statTable.count(index);
    }

    action l2gre_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool vlan_enable,
                        bit<16> vlan,
                        bool key_valid,
                        bit<32> key,
                        bool seqnum_valid,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_gre_key.data = key;
        tnl_vlan_enable = vlan_enable;
        tnl_l2gre_seqnum = seqnum_valid;
        tnl_l2gre_key = key_valid;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
 statTable.count(index);
    }

    action l2gre_tunnel_encap_chained() {
        hdr.tnl_mac.setValid();
        hdr.tnl_ether_II.setValid();
        hdr.tnl_ipv4.setValid();
        hdr.tnl_gre.setValid();
        hdr.tnl_ether_II.ether_type = ETHERTYPE_IPV4;
        hdr.tnl_ipv4.identification = 0;
        hdr.tnl_ipv4.frag_offset = 0;
        hdr.tnl_ipv4.protocol = IP_PROTOCOLS_GRE;
        hdr.tnl_ipv4.version = 4;
        hdr.tnl_ipv4.ihl = 5;
        hdr.tnl_ipv4.flags = 0;
        hdr.tnl_ipv4.ttl = 64;
        hdr.tnl_ipv4.diffserv= 0;
        hdr.tnl_ipv4.hdr_checksum = 0;
        hdr.tnl_vlan_tag.tpid = TPID_0x8100;
        hdr.tnl_gre.R = 0;
        hdr.tnl_gre.C = 0;
        hdr.tnl_gre.s = 0;
        hdr.tnl_gre.recurse = 0;
        hdr.tnl_gre.flags = 0;
        hdr.tnl_gre.version = 0;
        hdr.tnl_gre.proto = GRE_PROTO_ETHERNET;
    }

    action tagging_untagged_vxlan_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool src_port_hash_enable,
                        bit<16> src_port,
                        bit<16> dst_port,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bit<24> vni,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_udp.src_port = src_port;
        hdr.tnl_udp.dst_port = dst_port;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_vxlan.vni = vni;
        tnl_vlan_enable = vlan_enable;
        udp_src_hash_enable = src_port_hash_enable;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = inner_vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan_valid = true;
 statTable.count(index);
    }

    action tagging_single_tagged_vxlan_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool src_port_hash_enable,
                        bit<16> src_port,
                        bit<16> dst_port,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bit<24> vni,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_udp.src_port = src_port;
        hdr.tnl_udp.dst_port = dst_port;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_vxlan.vni = vni;
        tnl_vlan_enable = vlan_enable;
        udp_src_hash_enable = src_port_hash_enable;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[1].setValid();
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
  eg_md.outer_vlan = inner_vlan;
        eg_md.df_vlans_stripped = 3;
  eg_md.inner_vlan_valid = true;
 statTable.count(index);
    }

    action tagging_double_tagged_vxlan_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool src_port_hash_enable,
                        bit<16> src_port,
                        bit<16> dst_port,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<16> inner_vlan,
                        bit<24> vni,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_udp.src_port = src_port;
        hdr.tnl_udp.dst_port = dst_port;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_vxlan.vni = vni;
        tnl_vlan_enable = vlan_enable;
        udp_src_hash_enable = src_port_hash_enable;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
  hdr.vlan_tag[2].setValid();
  hdr.vlan_tag[2].vlan = hdr.vlan_tag[1].vlan;
  hdr.vlan_tag[2].tpid = hdr.vlan_tag[1].tpid;
  hdr.vlan_tag[1].vlan = hdr.vlan_tag[0].vlan;
  eg_md.inner_vlan = hdr.vlan_tag[0].vlan;
  hdr.vlan_tag[1].tpid = hdr.vlan_tag[0].tpid;
  hdr.vlan_tag[0].vlan = inner_vlan;
  hdr.vlan_tag[0].tpid = TPID_0x8100;
        eg_md.df_vlans_stripped = 3;
  eg_md.outer_vlan = inner_vlan;
 statTable.count(index);
    }

    action vxlan_tunnel_encap(mac_addr_t src_mac,
                        mac_addr_t dst_mac,
                        ipv4_addr_t src_ip,
                        ipv4_addr_t dst_ip,
                        bool src_port_hash_enable,
                        bit<16> src_port,
                        bit<16> dst_port,
                        bool vlan_enable,
                        bit<16> vlan,
                        bit<24> vni,
                        bit<3> drop_pkt,
   StatIndex_t index) {
        hdr.tnl_mac.src_addr = src_mac;
        hdr.tnl_mac.dst_addr = dst_mac;
        hdr.tnl_ipv4.src_addr = src_ip;
        hdr.tnl_ipv4.dst_addr = dst_ip;
        hdr.tnl_udp.src_port = src_port;
        hdr.tnl_udp.dst_port = dst_port;
        hdr.tnl_vlan_tag.vlan = vlan;
        hdr.tnl_vxlan.vni = vni;
        tnl_vlan_enable = vlan_enable;
        udp_src_hash_enable = src_port_hash_enable;
        eg_intr_dprsr_md.drop_ctl = drop_pkt;
 statTable.count(index);
    }

    action vxlan_tunnel_encap_chained() {
        hdr.tnl_mac.setValid();
        hdr.tnl_ether_II.setValid();
        hdr.tnl_ipv4.setValid();
        hdr.tnl_udp.setValid();
        hdr.tnl_vxlan.setValid();
        hdr.tnl_ether_II.ether_type = ETHERTYPE_IPV4;
        hdr.tnl_ipv4.identification = 0;
        hdr.tnl_ipv4.frag_offset= 0;
        hdr.tnl_ipv4.hdr_checksum = 0;
        hdr.tnl_ipv4.protocol = IP_PROTOCOLS_UDP;
        hdr.tnl_ipv4.version = 4;
        hdr.tnl_ipv4.ihl = 5;
        hdr.tnl_ipv4.flags = 0;
        hdr.tnl_ipv4.ttl = 64;
        hdr.tnl_ipv4.diffserv = 0;
        hdr.tnl_vlan_tag.tpid = TPID_0x8100;
        hdr.tnl_udp.checksum = 0;
        hdr.tnl_vxlan.flags = 8w0x08; //Only I bit set
        hdr.tnl_vxlan.reserved = 0;
        hdr.tnl_vxlan.reserved2 = 0;
    }


    @name("port_encap")
    table egress_port_encap {
 actions = {
            @defaultonly nop;
            vlan_tagging_untagged;
            vlan_tagging_single_tagged;
            vlan_tagging_double_tagged;
            vlan_tagging_untagged_for_unicast;
            vlan_tagging_single_tagged_for_unicast;
            vlan_tagging_double_tagged_for_unicast;
            double_vlan_stripping_for_double_tagged;
            double_vlan_stripping_for_triple_tagged;
            vlan_stripping_for_single_tagged;
            vlan_stripping_for_double_tagged;
            vlan_stripping_for_triple_tagged;
            vlan_translate;
            vlan_translate_for_unicast;
            no_action;

            l2gre_tunnel_encap;
            tagging_untagged_l2gre_tunnel_encap;
            tagging_single_tagged_l2gre_tunnel_encap;
            tagging_double_tagged_l2gre_tunnel_encap;
            vxlan_tunnel_encap;
            tagging_untagged_vxlan_tunnel_encap;
            tagging_single_tagged_vxlan_tunnel_encap;
            tagging_double_tagged_vxlan_tunnel_encap;

            set_header_strip_options;
 }
 key = {
     hdr.ipv4.isValid() : ternary @name("ipv4_valid");
     hdr.ipv6.isValid() : ternary @name("ipv6_valid");
        hdr.vlan_tag[0].isValid() : ternary @name("outer_tag_valid");
        hdr.vlan_tag[1].isValid() : ternary @name("inner_tag_valid");
        hdr.vlan_tag[2].isValid() : ternary @name("inner_tag2_valid");
     eg_intr_md.egress_rid : ternary @name("egress_rid");
     eg_md.br_md.hdr_stripping : ternary @name("hdr_stripping");
     eg_md.br_md.vlan_stripping : ternary @name("vlan_stripping");
     eg_md.br_md.df_config : ternary @name("df_config");
 }
 const default_action = nop;
 size = 4000;
    }

    /*
     * This is for pure L2 packets(without L3 header) 
     */
    action set_pkt_length_layer2(bit<16> ip_hdr_len, bit<16> udp_hdr_len) {
        ipv4_len = ip_hdr_len;
        udp_len = udp_hdr_len;
        inner_ip_len = eg_intr_md.pkt_length;
    }

    action set_pkt_length_ipv4(bit<16> ip_hdr_len, bit<16> udp_hdr_len) {
        ipv4_len = ip_hdr_len;
        udp_len = udp_hdr_len;
        inner_ip_len = hdr.ipv4.total_len;
    }

    action set_pkt_length_ipv6(bit<16> ip_hdr_len, bit<16> udp_hdr_len) {
        ipv4_len = ip_hdr_len;
        udp_len = udp_hdr_len;
        inner_ip_len = hdr.ipv6.payload_len + 40;
    }


    action pad_runt_pkt() {
        eg_intr_dprsr_md.mtu_trunc_len = 64;
        eg_md.padded_pkt = true;
    }

    /*
     * Adding a logic in the control block or action block to calculate
     * IP and or UDP Packet length depending on the incoming packet is
     * causing P4 compiler issues. 
     * This table should be prepopulated during init by the controlplane.
     */
    @name("pkt_len")
    table pkt_len_calc {
 actions = {
            @defaultonly nop;
            set_pkt_length_ipv4;
            set_pkt_length_ipv6;
            set_pkt_length_layer2;

            pad_runt_pkt;

 }
 key = {
        hdr.vlan_tag[0].isValid() : ternary @name("outer_tag_valid");
        hdr.vlan_tag[1].isValid() : ternary @name("inner_tag_valid");
        hdr.vlan_tag[2].isValid() : ternary @name("inner_tag2_valid");

     hdr.tnl_vxlan.isValid() : ternary @name("tnl_vxlan_valid");
     hdr.tnl_gre.isValid() : ternary @name("tnl_gre_valid");

     hdr.ipv4.isValid() : ternary @name("ipv4_valid");
     hdr.ipv6.isValid() : ternary @name("ipv6_valid");
        hdr.etag.isValid() : ternary @name("etag_valid");
        hdr.vntag.isValid() : ternary @name("vntag_valid");
        hdr.fabric_path.isValid(): ternary @name("fabricpath_valid");
     eg_md.br_md.vlan_config : ternary @name("vlan_config");
     eg_md.single_vlan_stripping : ternary @name("single_vlan_stripping");
     eg_md.double_vlan_stripping : ternary @name("double_vlan_stripping");

            hdr.tnl_gre_key.isValid() : ternary @name("tnl_gre_key_valid");
     hdr.tnl_gre_seq.isValid() : ternary @name("tnl_gre_seq_valid");

        eg_md.pkt_len : ternary @name("pkt_len");
        eg_intr_md.pkt_length : ternary @name("l2_len");
        eg_md.df_vlans_stripped : ternary @name("df_vlans_stripped");
     eg_md.br_md.hdr_stripping : ternary @name("hdr_stripping");
 }
 const default_action = nop;
 size = 1024;
    }

    apply {
# 633 "toolPortEncapTable.p4"
        switch(egress_port_encap.apply().action_run) {
            l2gre_tunnel_encap : { l2gre_tunnel_encap_chained(); }
            tagging_untagged_l2gre_tunnel_encap : { l2gre_tunnel_encap_chained(); }
            tagging_single_tagged_l2gre_tunnel_encap : { l2gre_tunnel_encap_chained(); }
            tagging_double_tagged_l2gre_tunnel_encap : { l2gre_tunnel_encap_chained(); }
            vxlan_tunnel_encap : { vxlan_tunnel_encap_chained(); }
            tagging_untagged_vxlan_tunnel_encap : { vxlan_tunnel_encap_chained(); }
            tagging_single_tagged_vxlan_tunnel_encap : { vxlan_tunnel_encap_chained(); }
            tagging_double_tagged_vxlan_tunnel_encap : { vxlan_tunnel_encap_chained(); }
        }
        if (hdr.tnl_gre.isValid()) {
            if (tnl_l2gre_key) {
                hdr.tnl_gre.K = 1;
                hdr.tnl_gre_key.setValid();
            }
            if (tnl_l2gre_seqnum) {
                hdr.tnl_gre.S = 1;
                hdr.tnl_gre_seq.setValid();
                hdr.tnl_gre_seq.data = increment.execute(eg_intr_md.egress_rid[7:0]);
            }
        }
        if (hdr.tnl_vxlan.isValid() || hdr.tnl_gre.isValid()) {
            hdr.pad.setInvalid();
            if (tnl_vlan_enable) {
                hdr.tnl_vlan_tag.setValid();
            }
            if (udp_src_hash_enable) {
                if (hdr.ipv4.isValid()) {
                    src_port_hash[13:0] = hash_outer_ipv4_5_tuple.get({ hdr.ipv4.src_addr,
                                                                        hdr.ipv4.dst_addr,
                                                                        hdr.ipv4.protocol,
                                                                        eg_md.l4_outer_info.srcport_typecode,
                                                                        eg_md.l4_outer_info.dstport_chksum });
                }
                else if (hdr.ipv6.isValid()) {
                    src_port_hash[13:0] = hash_outer_ipv6_5_tuple.get({ hdr.ipv6.src_addr,
                                                                        hdr.ipv6.dst_addr,
                                                                        hdr.ipv6.next_hdr,
                                                                        eg_md.l4_outer_info.srcport_typecode,
                                                                        eg_md.l4_outer_info.dstport_chksum });
                }
                else {
                    src_port_hash[13:0] = hash_layer2.get({ hdr.mac.src_addr,
                                                            hdr.mac.dst_addr,
                                                            hdr.ether_II.ether_type });
                }
                hdr.tnl_udp.src_port = src_port_hash;
            }
            pkt_len_calc.apply();
            hdr.tnl_ipv4.total_len = inner_ip_len + ipv4_len;
            hdr.tnl_udp.hdr_length = inner_ip_len + udp_len;
        }

        else
        {
            pkt_len_calc.apply();
            if (eg_md.padded_pkt && eg_md.extra_pad_bytes)
            {
                eg_intr_dprsr_md.mtu_trunc_len = 64 + 4;
            }
            else if (!eg_md.padded_pkt && hdr.pad.isValid())
            {
                hdr.pad.setInvalid();
            }
        }


    }
}
# 186 "bfs.p4" 2

control SwitchIngress(
 inout ingress_header_t hdr,
 inout ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {


 final_match_table_metadata_t final_match_table_metadata = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};




 Random<bit<13>>() random_num;

//	@name("vlan_actions")
//	vlan_actions() perform_vlan_actions;
//	@name("packet_process")
//	ingress_packet_process() perform_ingress_packet_process;
 @name("npf")
 processNetworkPortFilters() processNetworkPortFilters_0;
 @name("port_vlan")
 /* Vlan translation only for inline */
 process_network_port_vlan() process_network_port_vlan_0;

 /*
	* initialize the metadata for final match table.
	* TODO:  Is this the right way to do this?
	*/
 @name("vlan")
 process_vlans() process_vlan_entries;
 @name("l2")
 process_l2() process_l2_entries;
 @name("l3")
 process_l3() process_l3_entries;
 @name("dynamicFilter")
 process_final_match_table() process_final_match_table_0;





 @name("multicast")
 process_multicast_hash() process_multicast_hash_0;




 @name("ctrl_plane")
 process_ingress_control_plane() process_control_plane_entries;

 apply {
  /* clear "copy_to_cpu" flag, it gets set by default by platform */
  ig_intr_tm_md.copy_to_cpu = 0x0;

  /* generate random number hash for all pkts */
  ig_md.random_hash_value = random_num.get();

  /*
		* process any NP filters
		*/
  processNetworkPortFilters_0.apply(
   hdr,
   ig_intr_md,
   ig_md,
   ig_intr_prsr_md,
   ig_intr_dprsr_md);

  /*
		 * VLAN translation on network port
		 */
  process_network_port_vlan_0.apply(
   hdr,
   ig_intr_md,
   ig_intr_tm_md,
   ig_md);

  /*
		* execute any vlan actions on NP
		*/
/*		perform_vlan_actions.apply(
			hdr,
			ig_md);
*/

  /*
		* Look up the vlans
		*/
  process_vlan_entries.apply(
   hdr,
   ig_intr_md,
   ig_md,
   final_match_table_metadata);

  /*
		* Look up the l2 entries in l2 qualifier tables
		*  These include mac address and ethertype
		*/
  process_l2_entries.apply(
   hdr,
   ig_intr_md,
   ig_md,
   final_match_table_metadata);
  /*
		* Process layer3 packets v4, v6, both inner and outer
		*/
  process_l3_entries.apply(
   hdr,
   ig_intr_md,
   ig_md,
   final_match_table_metadata);


   /*
	 	* Process Ingress Timestamping (conversion to 16 Sec / 32 nSec)
	 	*/
   ts_actions.apply(
    hdr,
    ig_intr_md,
    ig_md);


  /*
		* Process the final match table.  This table is combination of
		* all of the previous looked up match ids and produces the final
		* forwarding decision
		*/
  process_final_match_table_0.apply(
   hdr,
   ig_intr_md,
   ig_md,
   ig_intr_prsr_md,
   ig_intr_dprsr_md,
   ig_intr_tm_md,
   final_match_table_metadata);
# 335 "bfs.p4"
  if (ig_md.hash_enable) {
   process_multicast_hash_0.apply(
    hdr,
    ig_intr_tm_md,
    ig_md);






  }

                // Stripping
/*		perform_ingress_packet_process.apply(
			hdr,
			ig_intr_dprsr_md.drop_ctl,
			ig_intr_md.ingress_port[8:0],
			ig_intr_tm_md.mcast_grp_a,
			ig_md.packet_type,
			ig_md.inner_ether_type);
*/
  /*
		 * process cpu-knet filtering and maybe stop
		 */
  process_control_plane_entries.apply(hdr, ig_md, ig_intr_md.ingress_port[8:0], ig_intr_tm_md, ig_intr_dprsr_md);
 }
}


control SwitchEgress(
 inout egress_header_t hdr,
 inout egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

 @name("port_config")
 process_port_config() process_port_config_0;
 @name("port_vlan")
 process_tool_port_vlan() process_tool_port_vlan_0;
 @name("tpf")
 processToolPortFilters() processToolPortFilters_0;
 @name("port_encap")
 process_port_encap() process_port_encap_0;
 @name("packet_process")
 egress_packet_process() perform_egress_packet_process;

 apply {
  process_port_config_0.apply(
   hdr,
   eg_intr_md,


   eg_intr_dprsr_md,


   eg_md);

  process_port_encap_0.apply(
   hdr,
   eg_intr_md,
   eg_intr_dprsr_md,
   eg_md);

  /*TBD - Uncomment this once infra for enabling dedup per port/PG is added*/
# 412 "bfs.p4"
/*TBD - Change once p4 image infra is in place*/

  /*
		 * execute any packet processing (Header stripping etc) on TP or DF
		 */
  if (eg_md.hdr_stripping_enable) {
   perform_egress_packet_process.apply(
    hdr,
    eg_intr_md.egress_rid,
    eg_intr_md.egress_port,
    eg_md.packet_type,
    /*
				 * Meta data for outer vlan is used in TPF. Adding the logic to set 
				 * the outer_vlan field in the egress meta data causes 13 stages 
				 * in T1 intersection image.
				 */



    eg_md.inner_ether_type,
    eg_md.outer_vlan,
    eg_md.outer_vlan_valid);

  }

  process_tool_port_vlan_0.apply(
   hdr,
   eg_intr_md,
   eg_md);

  processToolPortFilters_0.apply(
  hdr,
  eg_intr_md,
  eg_md,
  eg_intr_dprsr_md);
# 464 "bfs.p4"
  data_mask_actions.apply(
   hdr,
   eg_intr_md.egress_rid,
   eg_md.br_md.ingress_port,
   eg_intr_md.egress_port);

 }
}


Pipeline(
 SwitchIngressParser(),
 SwitchIngress(),
 SwitchIngressDeparser(),
 SwitchEgressParser(),
 SwitchEgress(),
 SwitchEgressDeparser()) pipe;

/*
  Structured annotations can be added either as an expression list or a key=value list.
  Examples of structured annotations:  

  @MyMixedExprList[1,"hello",true,1==2,5+6]
  @MyMixedKeyValueList[label="text", my_bool=true, int_val=2*3]
*/
@pkginfo(organization="Copyright Keysight Technologies 2023")
@pkginfo(contact="support@keysight.com")
@pkginfo(url="www.keysight.com")
# 506 "bfs.p4"
@pkginfo(name="FINANCE", version="1.0")
@brief("FINANCE")
@description("Finance specific filtering.")
@display[true]
@licenseList["FENDER_TS_PSPLF_16_32"]
/*  To add another license, add as list @licenseList["license1", "license2"] */
# 527 "bfs.p4"
Switch(pipe) main;
