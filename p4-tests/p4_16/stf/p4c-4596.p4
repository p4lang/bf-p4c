# 1 "/root/p4c-4596/tf2_pwoff/tf2_pwoff.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/root/p4c-4596/tf2_pwoff/tf2_pwoff.p4"
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
# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/t2na.p4" 1




# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_specs.p4" 1



/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/

# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 17 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_specs.p4" 2

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
# 6 "/bfn/bf-p4c-compilers/build/p4c/p4include/t2na.p4" 2






# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_arch.p4" 1



/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/

# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_base.p4" 1



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




# 1 "/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 26 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_base.p4" 2

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
                                        //    - bit 2 disables mirroring
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
# 17 "/bfn/bf-p4c-compilers/build/p4c/p4include/tofino2_arch.p4" 2

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
# 13 "/bfn/bf-p4c-compilers/build/p4c/p4include/t2na.p4" 2
# 21 "/root/p4c-4596/tf2_pwoff/tf2_pwoff.p4" 2

# 1 "/root/p4c-4596/tf2_pwoff/headers.p4" 1
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




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
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

// VXLAN -- RFC 7348
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

header hdr_h {
    bit<8> pos;
    bit<8> type;
}

header bridged_h {
    bit<16> f1;
    bit<16> f2;
    bit<16> f3;
    bit<32> f4;
    bit<8> f5;
    bit<8> f6;
    bit<16> f7;
}

header fabric_pad_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<28> pad;
}

header fake_tag_h {
    bit<16> f1;
    bit<16> f2;
}

header fabric_h {
    bit<8> f1;
    bit<8> f2;
    bit<32> f3;
    bit<16> f4;
    bit<16> f5;
    bit<16> f6;
    bit<16> f7;
}

struct header_t {
    bridged_h bridged_md;
    fabric_h fabric;
    fabric_pad_h fabric_pad;
    fake_tag_h fake_tag;
    ethernet_h ethernet;
    vlan_tag_h[2] vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    vxlan_h vxlan;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    udp_h inner_udp;
    hdr_h[31] myhdr;
    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}
# 23 "/root/p4c-4596/tf2_pwoff/tf2_pwoff.p4" 2
# 1 "/root/p4c-4596/tf2_pwoff/util.p4" 1
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




parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
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
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
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
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 24 "/root/p4c-4596/tf2_pwoff/tf2_pwoff.p4" 2

@pa_auto_init_metadata
@pa_parser_group_monogress
struct metadata_t {
    bit<2> iseop;
    bit<2> test1;
    bool test;
    bit<16> flowid;
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
        //vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type) {
            (ETHERTYPE_IPV4) : parse_ipv4;
            (ETHERTYPE_IPV6) : parse_ipv6;
            //(ETHERTYPE_VLAN, ETHERTYPE_VLAN) : parse_qinq;
            (ETHERTYPE_VLAN) : parse_vlan;
            //ETHERTYPE_IPV4 : parse_ipv4;
            //ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        //pkt.extract(hdr.vlan_tag[0]);
        //transition select(hdr.vlan_tag[0].ether_type) {
        transition select(hdr.vlan_tag.last.ether_type) {
            (ETHERTYPE_IPV4) : parse_ipv4;
            (ETHERTYPE_IPV6) : parse_ipv6;
            (ETHERTYPE_VLAN) : parse_vlan;
            default : accept;
        }
    }

    state parse_qinq {
        //pkt.extract(hdr.vlan_tag.next);
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
        //transition select(hdr.vlan_tag.last.ether_type) {
            // (ETHERTYPE_IPV4) : parse_ipv4;
            // (ETHERTYPE_IPV6) : parse_ipv6;
            // (ETHERTYPE_VLAN) : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
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
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        //pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        //pkt.emit(hdr.arp); // Ingress only.
        //pkt.emit(hdr.ipv4);
        //pkt.emit(hdr.bridged_md);
        //pkt.emit(hdr.fabric_pad);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {


            // if (reg == 0) {
            //     temp = reg + (bit<16>)ig_intr_tm_md.ucast_egress_port;
            // } else {
            //     temp = reg + 0;
            //     reg = 0;
            // }

            // port = temp;

    // Register<bit<16>, bit<16>>(65536, 0) port_reg;
    // RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act = {
    //     void apply(inout bit<16> reg, out bit<16> port){
    //         // if (reg == 0) {
    //         //     reg = (bit<16>)ig_intr_tm_md.ucast_egress_port;
    //         // }
    //         bit<16> temp;
    //         if (reg > (bit<16>)ig_intr_tm_md.ucast_egress_port) {
    //             temp = 0b11;
    //         } else if (reg == (bit<16>)ig_intr_tm_md.ucast_egress_port) {
    //             temp = 0b10;
    //         } else {
    //             temp = 0b00;
    //         }

    //         port = temp;
    //         // port = reg;
    //     }
    // };


    Register<bit<16>, bit<16>>(65536, 0) port_reg;
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act = {
        void apply(inout bit<16> reg, out bit<16> port){
            if (reg == 0) {
                reg = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            }
            port = reg;
        }
    };
    // 要注意不走voq的报文，如组播等
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act2 = {
        void apply(inout bit<16> reg, out bit<16> port){
            bit<16> temp;
            if (reg == 0) {
                //temp = reg + (bit<16>)ig_intr_tm_md.ucast_egress_port;
                port = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            } else {
                //temp = reg + 0;
                port = reg;
                reg = 0;
            }
            port = temp;
        }
    };

    action build_flow() {
        ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act.execute(ig_md.flowid);
    }
    action eop_flow() {
        ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act2.execute(ig_md.flowid);
    }

    table test {
        key = {
            ig_md.iseop : exact;
        }
        actions = {
            build_flow;
            eop_flow;
        }
    }
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) selector_hash;
    // ActionSelector(32768, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    ActionProfile(16384) action_profile_lag;

    ActionSelector(action_profile_lag,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   4096, // max_group_size
                   16) fabric_lag_selector; //num_groups

    action set_fabric_lag_port(bool port) {
        // ig_intr_tm_md.ucast_egress_port = (bit<9>)port;
        // ig_md.common.dev_port = port;
        // ig_md.iseop = port;
        ig_md.test = port;
    }

    action set() {
        set_fabric_lag_port(ig_md.iseop >= ig_md.test1);
    }

    @pragma selector_enable_scramble 1
    table fabric_lag {
        key = {
            ig_md.iseop : exact;// dst_device can be bfn or fpga as long as they have unique ids.
            ig_md.flowid : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
            set;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    action set_icos(bit<3> icos) {
        ig_intr_tm_md.ingress_cos = icos;
    }
    action set_queue(bit<7> qid) {
        ig_intr_tm_md.qid = qid;
    }
    action set_icos_and_queue(bit<3> icos, bit<7> qid) {
        ig_intr_tm_md.ingress_cos = icos;
        ig_intr_tm_md.qid = qid;
    }

    action set_port_to_1() {
        ig_intr_tm_md.ucast_egress_port = 1;
    }
    @stage(6)
    table traffic_class_78 {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
            set_port_to_1;
        }
        size = 32;
        default_action = set_port_to_1;
    }
    @stage(6)
    table traffic_class_710 {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
        }
        size = 32;
        default_action = NoAction;
    }
    table high_priority_queue {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
        }
        size = 32;
        default_action = NoAction;
    }

    action set_port_t() {

    }

    action set_port() {
        ig_intr_tm_md.ucast_egress_port = 8;
    }

    table port {
        key = {
            ig_md.iseop : exact;
        }
        actions = {
            NoAction;
            set_port;
            set_port_t;
        }

        default_action = set_port;
    }

    apply {
        //ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;

        ig_md.iseop = hdr.ethernet.dst_addr[1:0];
        //ig_intr_tm_md.ucast_egress_port = 1;
        // test.apply();
        // 

        port.apply();
        fabric_lag.apply();

        ig_intr_tm_md.ucast_egress_port = 0;

        switch(high_priority_queue.apply().action_run) {
            NoAction : {
                // if this table is executed, then egress port is set 1. Otherwise, egress port is 0
                traffic_class_78.apply();
            }
        }

        if (ig_md.test) {
            ig_md.iseop = hdr.ethernet.dst_addr[1:0];
        }
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_ethernet;
    }

    // state parse_bridged_md {
    //     pkt.extract(hdr.bridged_md);
    //     pkt.extract(hdr.fabric_pad);
    //     transition parse_ipv4;
    // }

    state parse_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select (hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        //pkt.emit(hdr);
        //pkt.emit(hdr.bridged_md);
        //pkt.emit(hdr.fabric_pad);
        //pkt.emit(hdr.fabric);
        //pkt.emit(hdr.fake_tag);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_udp);
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    // // Create direct counters
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES, true) direct_counter_teop;

    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;

    bit<32> a = 32w0;
    bit<32> b = 32w0;

    action nop() { }

    // action hit_src() {
    //     // Call direct counter. Note that no index parameter is required because
    //     // the index is implicitely generated from the entry of the the 
    //     // associated match table.
    //     direct_counter.count();
    // }

    // table count_src {
    //     key = {
    //         hdr.ethernet.src_addr : ternary;
    //     }

    //     actions = {
    //         hit_src;
    //         @defaultonly nop;
    //     }

    //     size = 1024;
    //     const default_action = nop;
    //     // Associate this table with a direct counter
    //     counters = direct_counter;
    // }

    action hit_src_teop() {
        // hdr.ipv4.setInvalid();
        // hdr.ethernet.ether_type = 0xffff;
        direct_counter_teop.count();
        //hdr.ipv4.ttl.setInvalid();
        //hdr.inner_ipv4.dst_addr = a;
        a = a + 32w10;
    }

    @stage(2)
    table count_src_teop {
        key = {
            //hdr.ethernet.src_addr : ternary;
            hdr.inner_ipv4.total_len[15:8] : ternary @name("dip_l3class_id");
            hdr.inner_ipv4.total_len[7:0] : ternary @name("sip_l3class_id");
        }

        actions = {
            hit_src_teop;
            @defaultonly nop;
        }

        size = 1024;
        const default_action = nop;
        // Associate this table with a direct counter
        counters = direct_counter_teop;
    }

    // action add_fabric_fake_tag() {
    //     hdr.fabric.setValid();
    //     hdr.fabric.f1 = 7;
    //     hdr.fabric.f2 = 6;
    //     hdr.fabric.f3 = 5;
    //     hdr.fabric.f4 = 4;
    //     hdr.fabric.f5 = 3;
    //     hdr.fabric.f6 = 2;
    //     hdr.fabric.f7 = 1;
    //     hdr.fake_tag.setValid();
    //     hdr.fake_tag.f1 = eg_intr_md.pkt_length;
    // }

    // action add_fabric() {
    //     hdr.fabric.setValid();
    //     hdr.fabric.f1 = 7;
    //     hdr.fabric.f2 = 6;
    //     hdr.fabric.f3 = 5;
    //     hdr.fabric.f4 = 4;
    //     hdr.fabric.f5 = 3;
    //     hdr.fabric.f6 = 2;
    //     hdr.fabric.f7 = 1;
    // }

    // table pkt_rewrite {
    //     key = {
    //         eg_intr_md.pkt_length : exact;
    //     }

    //     actions = {
    //         add_fabric_fake_tag;
    //         add_fabric;
    //     }

    //     const default_action = add_fabric;
    // }

    // action add_ethernet_header() {
    //     hdr.ethernet.setValid();
    //     hdr.ethernet.src_addr = 48w0;
    //     hdr.ethernet.dst_addr = 48w0;
    //     hdr.ethernet.ether_type = 16w2048;
    // }

    // action add_ipv4_header() {
    //     hdr.ipv4.setValid();
    //     hdr.ipv4.version = 4w4;
    //     hdr.ipv4.ihl = 4w5;
    //     hdr.ipv4.identification = 0;
    //     hdr.ipv4.frag_offset = 0;
    //     hdr.ipv4.diffserv = 0;

    //     hdr.ipv4.flags = 2;//3 bit, 010 表示不能分片
    //     hdr.ipv4.protocol = 17;

    //     // Total length = packet length + 50
    //     // IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    //     hdr.ipv4.total_len = hdr.inner_ipv4.total_len + 16w50;

    //     hdr.ipv4.src_addr = 32w0;
    //     hdr.ipv4.dst_addr = 32w0;
    //     hdr.ipv4.ttl = 64;
    //     hdr.ipv4.diffserv[7:2] = 0;
    // }

    // action add_udp_header() {
    //     hdr.udp.setValid();
    //     hdr.udp.src_port = 16w1234;
    //     hdr.udp.dst_port = 16w4789;
    //     hdr.udp.checksum = 0;//todo calculate
    //     // UDP length = packet length + 30
    //     // UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    //     hdr.udp.hdr_length = hdr.inner_ipv4.total_len + 16w30;
    // }

    // action add_vxlan_header(bit<24> vni) {
    //     hdr.vxlan.setValid();
    //     hdr.vxlan.flags = 8w0x08;
    //     //hdr.vxlan.reserved = 0;
    //     hdr.vxlan.vni = vni;
    //     //hdr.vxlan.reserved2 = 0;
    // }

    // action encap(bit<24> vni) {
    //     add_vxlan_header(vni);
    //     add_udp_header();
    //     add_ipv4_header();
    //     add_ethernet_header();
    // }

    // table encap_vxlan {
    //     // key = {
    //     //     eg_intr_md.pkt_length : exact;
    //     // }

    //     actions = {
    //         encap;
    //     }

    //     const default_action = encap(100);
    // }

    apply {
        //count_src.apply();
        // b =hdr.inner_ipv4.src_addr;

        // a =hdr.inner_ipv4.dst_addr;

        // a = a + b;

        // if (count_src_teop.apply().hit) {
        //     //
        // }

        // hdr.inner_ipv4.dst_addr = a;


        //pkt_rewrite.apply();
        //encap_vxlan.apply();
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
