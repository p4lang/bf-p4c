# 1 "npb.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "npb.p4"
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
 ******************************************************************************/

# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/core.p4" 1
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
# 24 "npb.p4" 2

# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/t2na.p4" 1
/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */


# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/tofino2arch.p4" 1
/*
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */




# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/tofino2arch.p4" 2
# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/tofino2.p4" 1
/*
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */




# 1 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/tofino2.p4" 2

//XXX Open issues:
// Meter color
// Math unit
// Action selector
// Digest
// Coalesce mirroring

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<7> QueueId_t; // Queue id
typedef bit<4> CloneId_t; // Clone id
typedef bit<8> MirrorId_t; // Mirror id
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w192;

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_TCAM = 16w0x0001;
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
    CRC8,
    CRC16,
    CRC32,
    CRC64,
    CUSTOM
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

    @padding bit<3> _pad2;

    bit<9> ingress_port; // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp; // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    bit<9> ucast_egress_port; // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bit<1> bypass_egress; // Request flag for the warp mode
                                        // (egress bypass).

    bit<1> deflect_on_drop; // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos; // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    bit<7> qid; // Egress (logical) queue id into which
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

    bit<16> level1_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    bit<9> level2_exclusion_id; // Exclusion id for multicast
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
    bit<3> digest_type;

    bit<3> resubmit_type;

    bit<4> mirror_type; // The user-selected mirror field list
                                        // index.

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bit<1> mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bit<1> mirror_multicast_ctrl; // Mirror enable multicast if true.
    bit<9> mirror_egress_port; // Mirror packet egress port.
    bit<7> mirror_qid; // Mirror packet qid.
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
    @padding bit<7> _pad0;

    bit<9> egress_port; // Egress port id.
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

    @padding bit<1> _pad6;

    bit<7> egress_qid; // Egress (physical) queue id within a MAC via which
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

    bit<4> mirror_type;

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
    bit<9> mirror_egress_port; // Mirror packet egress port.
    bit<7> mirror_qid; // Mirror packet qid.
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
    bit<1> force_tx_error; // force a hardware transmission error
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
    @padding bit<15> _pad2;
    bit<9> port_num; // Port number

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

extern void invalidate<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

extern bit<32> sizeInBits<H>(in H h);

extern bit<32> sizeInBytes<H>(in H h);

/// Counter
/// Indexed counter with `size’ independent counter values.
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
    void count(in I index);
}

/// DirectCounter
extern DirectCounter<W> {
    DirectCounter(CounterType_t type, @optional bool true_egress_accounting);
    void count();
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type, @optional bool true_egress_accounting);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in I index, in MeterColor_t color);
    bit<8> execute(in I index);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type, @optional bool true_egress_accounting);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in MeterColor_t color);
    bit<8> execute();
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
    U enqueue(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* fifo push */
    U dequeue(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* fifo pop */
    U push(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* stack push */
    U pop(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* stack pop */
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
    U1 enqueue(out U2 rv2);  /* fifo push */
    U1 dequeue(out U2 rv2);  /* fifo pop */
    U1 push(out U2 rv2);  /* stack push */
    U1 pop(out U2 rv2);  /* stack pop */
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
    U1 enqueue(out U2 rv2, out U3 rv3);  /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3);  /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3);  /* stack push */
    U1 pop(out U2 rv2, out U3 rv3);  /* stack pop */
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
    U1 enqueue(out U2 rv2, out U3 rv3, out U4 rv4);  /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3, out U4 rv4);  /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3, out U4 rv4);  /* stack push */
    U1 pop(out U2 rv2, out U3 rv3, out U4 rv4);  /* stack pop */
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
    Mirror();

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
    Resubmit();

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in T hdr);
}

extern Digest<T> {
    /// define a digest stream to the control plane
    Digest();

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
    Alpm(@optional bit<32> number_partitions, @optional bit<32> subtrees_per_partition);
}
# 24 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/tofino2arch.p4" 2

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
    @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

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

@pkginfo(arch="T2NA", version="0.6.0")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 21 "/home/vgurevich/bf-sde-9.2.0/install/share/p4c/p4include/t2na.p4" 2
# 26 "npb.p4" 2
# 38 "npb.p4"
# 1 "features_t2.p4" 1
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
 ******************************************************************************/

// List of all supported #define directives.

// ===== pkt header defines =================================

// ----- applies to: transport -----
# 36 "features_t2.p4"
// ----- applies to: outer -----
# 46 "features_t2.p4"
// ----- applies to: inner -----



// ----- applies to: outer and inner -----



// ===== feature defines ====================================

// ----- parser -----







// ----- switch: mirroring -----





// ----- switch: cpu -----
# 79 "features_t2.p4"
// ----- switch: dtel -----






// ----- switch: other -----

// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE




// ----- npb: sfc -----






// ----- npb: sff -----




// ----- npb: sf #0 -----
# 119 "features_t2.p4"
// ----- npb: sf #2  -----
# 134 "features_t2.p4"
// ----- tofino 1 fitting -----





// ----- debug and miscellaneous -----




// ----- bug fixes -----





// ----- other wanted / needed features that don't fit -----
# 39 "npb.p4" 2


# 1 "field_widths.p4" 1






    // -------------------------------------
    // Switch Widths
    // -------------------------------------
# 28 "field_widths.p4"
    // -------------------------------------
    // NPB Widths
    // -------------------------------------
# 42 "npb.p4" 2
# 1 "table_sizes.p4" 1
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
 ******************************************************************************/




// --------------------------------------------




// --------------------------------------------

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Tofino 1
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
# 194 "table_sizes.p4"
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Tofino 2
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Switch
// -----------------------------------------------------------------------------

const bit<32> PORT_TABLE_SIZE = 256;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// IP Hosts/Routes
const bit<32> RMAC_TABLE_SIZE = 64;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 1024;

// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 256; // ingress
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 256; // ingress

const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512; // egress
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 1024; // egress
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32; // egress
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256; // egress

// ECMP/Nexthop
const bit<32> NEXTHOP_TABLE_SIZE = 8192;
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024; // derek: unused; removed this table
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; removed this table

// ECMP/Nexthop
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096; // aka NUM_TUNNELS
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096; // derek: unused in switch.p4
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; changed table type to normal table

// Lag
const bit<32> LAG_TABLE_SIZE = 1024; // switch.p4 was 1024
const bit<32> LAG_GROUP_TABLE_SIZE = 16; // switch.p4 was 256
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 16; // switch.p4 was 64
const bit<32> LAG_SELECTOR_TABLE_SIZE = 128; // 256 * 64 // switch.p4 was 16384

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 2048; // derek: was told to change this from the 512 in the spec.
//const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE                          = 8192; // derek: ideally this should be 8192
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144; // derek: ideally this should be 8192
//const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE                          = 4096; // derek: ideally this should be 8192
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024;

// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 128;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 128;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 128;

const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;
const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

// -----------------------------------------------------------------------------
// NPB
// -----------------------------------------------------------------------------

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH = 8192; // unused now
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH = 1024; // was 256;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 256;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH = 8192; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH = 128;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_FLW_CLS_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SFF_SCHD_TABLE_SIZE = 64;
const bit<32> NPB_ING_SFF_SCHD_GROUP_TABLE_SIZE = 32;
const bit<32> NPB_ING_SFF_SCHD_MAX_MEMBERS_PER_GROUP = 32;
const bit<32> NPB_ING_SFF_SCHD_SELECTOR_TABLE_SIZE = 1024; // 32 * 32
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 8192;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE = 2096;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH = 8192;

const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH = 8; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH = 8; // unused in latest spec
# 43 "npb.p4" 2
# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////
/*
@pa_container_size("ingress", "hdr.transport.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.outer.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.inner.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.$valid", 16)
*/
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

header vlan_tag_grouped_h {
    bit<16> pcp_cfi_vid;
    bit<16> ether_type;
}

header e_tag_h {
    bit<3> pcp;
    bit<1> dei;
    bit<12> ingress_cid_base;
    bit<2> rsvd_0;
    bit<2> grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}

header vn_tag_h {
    bit<1> dir;
    bit<1> ptr;
    bit<14> dvif_id;
    bit<1> loop;
    bit<3> rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}


//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////

// Address Resolution Protocol -- RFC 6747

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos;
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

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

#ifdef CASE_FIX
header ipv4_option_word_h {
    bit<32>     data;
}
typedef ipv4_option_word_h[10] ipv4_options_h;
#else
header ipv4_options_h {
    varbit<320> options;
}
#endif

  header ipv6_h {
      bit<4> version;
      bit<8> tos;
      bit<20> flow_label;
      bit<16> payload_len;
      bit<8> next_hdr;
      bit<8> hop_limit;
      ipv6_addr_t src_addr;
      ipv6_addr_t dst_addr;
}


header dummy_h {
      bit<8> unused;
}


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
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

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verifTag;
    bit<32> checksum;
}


//////////////////////////////////////////////////////////////
// Transport Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header (word 0, base word 0)
header nsh_base_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
}

// NSH Service Path Header (word 1, base word 1)
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header (word 2, ext type 1 words 0-3)
header nsh_md1_context_h {
    bit<128> md;
}

// fixed sized version of this is needed for lookahead (word 2, ext type 2 word 0)
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header (external)
header nsh_type1_h {
    // word 0: base word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

 // --------------------

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

 // --------------------

    // word 2: ext type 1 word 0-3
 bit<8> ver; // word 0
//	bit<8>                          scope;     // word 0
 bit<8> reserved3; // word 0
//	bit<16>                         reserved3; // word 0
 bit<16> lag_hash; // word 0

 bit<16> vpn; // word 1
 bit<16> sfc_data; // word 1

 bit<8> reserved4; // word 2
 bit<8> scope; // word 2
 bit<16> sap; // word 2

 bit<32> timestamp; // word 3
}


//-----------------------------------------------------------
// ERSPAN
//-----------------------------------------------------------

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type III -- IETFv3
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt; // Security group tag
    bit<1> p;
    bit<5> ft; // Frame type
    bit<6> hw_id;
    bit<1> d; // Direction
    bit<2> gra; // Timestamp granularity
    bit<1> o; // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}



//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}


//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// VXLAN
//-----------------------------------------------------------

header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}


//-----------------------------------------------------------
// GRE
//-----------------------------------------------------------

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R; // deprecated in RFC 2784
    bit<1> K; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> S; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> s; // deprecated in RFC 2784
    bit<3> recurse; // deprecated in RFC 2784
    bit<5> flags; // deprecated in RFC 2784
    bit<3> version;
    bit<16> proto;
}

header gre_optional_h {
    bit<32> data;
}

header gre_extension_sequence_h {
    bit<32> seq_num;
}


//-----------------------------------------------------------
// NVGRE
//-----------------------------------------------------------

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}


//-----------------------------------------------------------
// Authentication Header
//-----------------------------------------------------------

header auth_fixed_h {
    bit<8> next_header;
    bit<8> payload_len;
    bit<16> reserved;
    bit<32> spi;
    bit<32> seq_num;
}

header auth_variable_h {
    //varbit<8192> icv;
    varbit<320> icv;
}



//-----------------------------------------------------------
// ESP - IPsec
//-----------------------------------------------------------

header esp_h {
    //bit<32> spi;
    bit<16> spi_hi;
    bit<16> spi_lo;
    bit<32> seq_num;
}


//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------
// GTP-U: v1
// GTP-C: v2

header gtp_v1_base_h {
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
}

// header gtp_v1_extension_h {
//     bit<8>       ext_len;
//     varbit<8192> contents;
//     bit<8>       next_ext_hdr;
// }

header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
    //bit<24> seq_num;
    //bit<8>  spare;
}



//////////////////////////////////////////////////////////////
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<128> opaque;
}




//////////////////////////////////////////////////////////////
// DTel
//////////////////////////////////////////////////////////////

// Telemetry report header -- version 0.5
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v0_5.pdf
header dtel_report_v05_h {
    bit<4> version;
    bit<4> next_proto;
    bit<3> d_q_f;
    bit<15> reserved;
    bit<6> hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

// DTel report base header
header dtel_report_base_h {
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;




    bit<1> pad2;
    bit<7> queue_id;

}

// DTel drop report header
header dtel_drop_report_h {
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

// Telemetry report header -- version 1.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v1_0.pdf
header dtel_report_v10_h {
    bit<4> version;
    bit<4> length;
    bit<3> next_proto;
    bit<6> metadata_bits;
    bit<6> reserved;
    bit<3> d_q_f;
    bit<6> hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

// Optional metadata present in the telemetry report.
struct dtel_report_metadata_0 {
    bit<16> ingress_port;
    bit<16> egress_port;
}

struct dtel_report_metadata_2 {
    bit<8> queue_id;
    bit<24> queue_occupancy;
}

struct dtel_report_metadata_3 {
    bit<32> timestamp;
}

struct dtel_report_metadata_4 {
    bit<8> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}

//////////////////////////////////////////////////////////////
// Barefoot Specific Headers
//////////////////////////////////////////////////////////////

header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

// CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

// CPU header
//TODO(msharif): Update format of the CPU header.
// header cpu_h {
//    bit<8> flags; /*
//        bit<1> tx_bypass;
//        bit<1> capture_ts;
//        bit<1> multicast;
//        bit<5> reserved;
//    */
//    bit<8> qid;
//    bit<16> reserved;
//    bit<16> port_or_group;
//    bit<16> port;
//    bit<16> port_lag_index;
//    bit<16> bd;
//    bit<16> reason_code; // Also used as a 16-bit bypass flag.
//    bit<16> ether_type;
//}

// header timestamp_h {
//     bit<48> timestamp;
// }



//////////////////////////////////////////////////////////////
// Lookahead/Snoop Headers
//////////////////////////////////////////////////////////////

header snoop_enet_my_mac_h {
    bit<16> dst_addr_hi;
    bit<32> dst_addr_lo;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header snoop_enet_cpu_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]
# 624 "headers.p4"
    bit<5> cpu_egress_queue;
    bit<1> cpu_tx_bypass;
    bit<1> cpu_capture_ts;
 bit<1> reserved;
    bit<16> cpu_ingress_port;
    bit<16> cpu_port_lag_index;
    bit<16> cpu_ingress_bd;
    bit<16> cpu_reason_code;
    bit<16> cpu_ether_type;
}

header snoop_head_enet_vlan_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]
} // 14B + 4B = 18B

header snoop_head_enet_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 10B = 24B

header snoop_head_enet_vlan_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 4B + 10B = 28B
# 44 "npb.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/




// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 46 "types.p4"
//#define ETHERTYPE_VN   0x892F
# 87 "types.p4"
//#define MPLS_DEPTH 3


// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;





typedef PortId_t switch_port_t; // defined in tna
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef QueueId_t switch_qid_t; // defined in tna

typedef ReplicationId_t switch_rid_t; // defined in tna
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<8> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

typedef bit<12> switch_nexthop_t;
typedef bit<12> switch_outer_nexthop_t;






typedef bit<32> switch_hash_t;

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_smac_index_t;

typedef bit<8> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_cpu_reason_t SWITCH_CPU_REASON_IG_PORT_MIRRROR = 254;
const switch_cpu_reason_t SWITCH_CPU_REASON_EG_PORT_MIRRROR = 255;


struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9> port;
}

//#define switch_drop_reason_width 8
typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID = 117;
const switch_drop_reason_t SWITCH_DROP_REASON_SFC_TABLE_MISS = 118;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------

typedef bit<8> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 8w0x01;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_ACL = 8w0x02;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_MCAST = 8w0x04;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFF = 8w0x08;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_REWRITE = 8w0x10; // derek: used in common ingress and egress code...make sure they have the same value!

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 8w0xff;


typedef bit<8> switch_egress_bypass_t;
//const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE         = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SF_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SFF = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x10; // derek: used in common ingress and egress code...make sure they have the same value!
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x80;

// Add more egress bypass flags here.

const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;


// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// Metering -------------------------------------------------------------------

//#define switch_copp_meter_id_width 8
typedef bit<8> switch_copp_meter_id_t;

//#define switch_meter_index_width 10
typedef bit<10> switch_meter_index_t;

//#define switch_mirror_meter_id_width 8
typedef bit<8> switch_mirror_meter_id_t;

// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

//typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
//  switch_multicast_rpf_group_t rpf_group;
}

// Mirroring ------------------------------------------------------------------

typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;






/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */


// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
//  bit<48> timestamp;



    switch_mirror_session_t session_id;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src; // 8
    switch_mirror_type_t type; // 8
    bit<7> _pad1; // 7  \ 16 total
    switch_port_t port; // 9  /
    switch_bd_t bd; // 16
    bit<6> _pad2; // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
    switch_cpu_reason_t reason_code; // 16
}

// Tunneling ------------------------------------------------------------------

enum switch_tunnel_mode_t { PIPE, UNIFORM }

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NSH = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ERSPAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 8;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN = 9;

//#ifndef switch_tunnel_index_width
//#define switch_tunnel_index_width 16
//#endif
typedef bit<16> switch_tunnel_index_t;
typedef bit<32> switch_tunnel_id_t;

//struct switch_header_inner_inner_t {
//	bool ethernet_isValid;
//	bool ipv4_isValid;
//	bool ipv6_isValid;
//}

struct switch_tunnel_metadata_t {
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
    switch_tunnel_type_t type;
    switch_tunnel_id_t id;

    switch_tunnel_index_t index;
 bit<8> nvgre_flow_id;
//  switch_ifindex_t ifindex;
//  bit<16> hash;

 bool terminate;
 bool encap;
}

struct switch_tunnel_metadata_reduced_t {
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
 switch_tunnel_type_t type;

 bit<8> nvgre_flow_id;
 bool terminate;
 bool encap;
}

// Data-plane telemetry (DTel) ------------------------------------------------
/* report_type bits for drop and flow reflect dtel_acl results,
 * i.e. whether drop reports and flow reports may be triggered by this packet.
 * report_type bit for queue is not used by bridged / deflected packets,
 * reflects whether queue report is triggered by this packet in cloned packets.
 */
typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;

const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE = 0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE = 0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE = 0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT = 0b10000000;

typedef bit<8> switch_ifa_sample_id_t;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1> ifa_gen_clone; // Ingress only, indicates desire to clone this packet
    bit<1> ifa_cloned; // Egress only, indicates this is an ifa cloned packet
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id;
    switch_mirror_session_t clone_session_id; // Used for IFA interop
    bit<32> hash;
    bit<2> drop_report_flag; // Egress only.
    bit<2> flow_report_flag; // Egress only.
    bit<1> queue_report_flag; // Egress only.
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    bit<5> _pad5;
    bit<19> qdepth;
    bit<32> egress_timestamp;
}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
    bit<9> egress_port;
}

//-----------------------------------------------------------------------------
// NSH Metadata
//-----------------------------------------------------------------------------

struct nsh_metadata_t {
    bool start_of_path; // ingress / egress
    bool end_of_path; // ingress / egress
    bool truncate_enable; // ingress / egress
    bit<14> truncate_len; // ingress / egress
//	bool                            sf1_active;             // ingress / egress

    bit<8> si_predec; // ingress only
    bool sfc_enable; // ingress only (for sfp sel)
    bit<12> sfc; // ingress only (for sfp sel)
 bit<16> hash_1; // ingress only (for sfp sel)
    bool l2_fwd_en; // ingress only
 bit<32> hash_2; // ingress only (for dedup)

    bit<10> dsap; // egress only (for egress sf)
    bool strip_tag_e; // egress only
    bool strip_tag_vn; // egress only
    bool strip_tag_vlan; // egress only
    bit<8> add_tag_vlan_bd; // egress only
    bool terminate_outer; // egress only
    bool terminate_inner; // egress only
    bool dedup_en; // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Flags
//XXX Force the fields that are XORd to NOT share containers.
struct switch_ingress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    //  bool acl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
 bool dmac_miss;
    //  bool glean;
    // Add more flags here.
}

struct switch_egress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
//  bool acl_deny;
    bool rmac_hit;
    // Add more flags here.
}

// Checks
struct switch_ingress_checks_t {
    // Add more checks here.
}

struct switch_egress_checks_t {
    // Add more checks here.
}

struct switch_lookup_fields_t {
 // l2
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;
 bit<2> pad; // to keep everything byte-aligned, so that the parser can extract to this struct.
 vlan_id_t vid;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_tos;
 bit<3> ip_flags;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
 bit<32> ip_src_addr_v4;
 bit<32> ip_dst_addr_v4;
    @pa_alias("ingress" , "ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_dst_addr[31:0]", "ig_md.lkp_1.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_src_addr[31:0]", "ig_md.lkp_2.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_dst_addr[31:0]", "ig_md.lkp_2.ip_dst_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_src_addr[31:0]", "eg_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_dst_addr[31:0]", "eg_md.lkp_1.ip_dst_addr_v4" )
    bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t tunnel_id;

    switch_tunnel_type_t tunnel_outer_type; // egress only
    switch_tunnel_type_t tunnel_inner_type; // egress only

    switch_drop_reason_t drop_reason;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
 switch_cpu_reason_t cpu_reason;
//  bit<48> timestamp;
 bool rmac_hit;

    // Add more fields here.

    // ---------------
    // nsh meta data
    // ---------------
    bool nsh_md_start_of_path;
    bool nsh_md_end_of_path;
    bool nsh_md_l2_fwd_en;
//  bool                            nsh_md_sf1_active;

 bool nsh_md_dedup_en;

    // ---------------
    // dedup stuff
    // ---------------





}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_acl_extension_t {
# 645 "types.p4"
    bit<8> tcp_flags;

}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
//  bit<16> hash;

//  bool terminate;
    bool terminate_0; // unused, but removing causes a compiler error
//  bool terminate_1;
//  bool terminate_2;
}

// ----------------------------------------
# 680 "types.p4"
// ----------------------------------------

typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;




    switch_bridged_metadata_tunnel_extension_t tunnel;




}

// --------------------------------------------------------------------------------
// Ingress Port Metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
//  switch_ifindex_t                ifindex;

 bit<1> l2_fwd_en;


/*
    switch_yid_t exclusion_id;

	// for packets w/o nsh header:
    bit<SSAP_ID_WIDTH>              sap;
    bit<VPN_ID_WIDTH>               vpn;
    bit<24>                         spi;
    bit<8>                          si;
    bit<8>                          si_predec;
*/

}

// --------------------------------------------------------------------------------
// Ingress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
//@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")

@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

//@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
//@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")




struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress  port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress  port/lag index */ /* derek: passed to egress */
    bit<4> egress_port_lag_hash_sel; /* egress  port/lag hash_sel */
    switch_bd_t bd;
    switch_nexthop_t nexthop; /* derek: egress table pointer #1 */
    switch_outer_nexthop_t outer_nexthop; /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;
 switch_nexthop_t unused_nexthop;

//  bit<48> timestamp;
    bit<32> hash;
//  bit<32> hash_nsh;

    switch_ingress_flags_t flags;
//  switch_ingress_checks_t checks;
 switch_ingress_bypass_t bypass;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp_0;
    switch_lookup_fields_t lkp_1; // initially non-scoped, later scoped, version of fields
    switch_lookup_fields_t lkp_2; // non-scoped version of fields

    switch_multicast_metadata_t multicast;
 switch_mirror_metadata_t mirror;

    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields /* derek: egress table pointer #3 (tunnel_0.index) */
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields

 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

//#ifdef UDF_ENABLE
//    bit<1>                  parse_udf_reached;
//#endif

 bool copp_enable;
 switch_copp_meter_id_t copp_meter_id;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------------
// Egress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)





struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
//  switch_kt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

    bit<32> timestamp;
//  bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
//  switch_egress_checks_t checks;
 switch_egress_bypass_t bypass;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp_1; //     scoped version of fields
//  switch_tunnel_type_t   lkp_1_tunnel_outer_type;
//  switch_tunnel_type_t   lkp_1_tunnel_inner_type;
    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields
 switch_mirror_metadata_t mirror;
 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

 bool copp_enable;
 switch_copp_meter_id_t copp_meter_id;

//  bit<6>                                              action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id;
//  bit<10>                                             action_3_meter_id;
//  bit<8>                                              action_3_meter_overhead;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------
// Headers
// --------------------------------------------------------------------------

struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}

// -----------------------------------------------------------------------------

struct switch_header_transport_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;


    ipv4_h ipv4;







    gre_h gre;



 gre_extension_sequence_h gre_sequence;
    erspan_type2_h erspan_type2;
    //erspan_type3_h erspan_type3;


}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;


    e_tag_h e_tag;


    vn_tag_h vn_tag;

    vlan_tag_h[2] vlan_tag;




    ipv4_h ipv4;
    ipv4_options_h ipv4_options;

    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;

    vxlan_h vxlan;

    gre_h gre;
    gre_optional_h gre_optional;

    nvgre_h nvgre;


    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;


    //auth_fixed_h auth_fixed;
    //auth_variable_h auth_variable;

    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;
}

// -----------------------------------------------------------------------------

struct switch_header_inner_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;

    ipv4_h ipv4;

    ipv6_h ipv6;


    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;


    gre_h gre;



    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;


}

// -----------------------------------------------------------------------------

struct switch_header_inner_inner_t {
 dummy_h ethernet;
 dummy_h ipv4;
 dummy_h ipv6;
}

// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc 
    // ===========================

    switch_bridged_metadata_h bridged_md;
 // switch_mirror_metadata_h mirror;
    fabric_h fabric;
    cpu_h cpu;

    // ===========================
    // transport
    // ===========================

 switch_header_transport_t transport;

    // ===========================
    // outer
    // ===========================

 switch_header_outer_t outer;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_t inner;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_inner_t inner_inner;

    // ===========================
    // layer7
    // ===========================

    udf_h udf;

}
# 45 "npb.p4" 2
# 1 "util.p4" 1
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
 ******************************************************************************/

# 1 "types.p4" 1
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
 ******************************************************************************/
# 24 "util.p4" 2

// -----------------------------------------------------------------------------

control HashMask(
 inout switch_lookup_fields_t lkp_1,
 in bit<4> lkp_1_hash_sel
) {
 bit<9> lkp_1_hash_sel_bitmask_ = 0x1ff;

 // -----------------------------------------

 action hash_sel_hit(
  bit<9> lkp_1_hash_sel_bitmask
 ) {
  lkp_1_hash_sel_bitmask_ = lkp_1_hash_sel_bitmask;
 }

 table hash_sel {
  key = {
   lkp_1_hash_sel : exact;
  }

  actions = {
   NoAction;
   hash_sel_hit;
  }

  const default_action = NoAction;
  size = 16;
 }

 // -----------------------------------------

 apply {
  // convert select to bitmask
  hash_sel.apply();

  // mask
# 73 "util.p4"
 }
}

// -----------------------------------------------------------------------------

// Flow hash calculation.

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
 @symmetric("ig_md.lkp_1.ip_src_addr_v4", "ig_md.lkp_1.ip_dst_addr_v4")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;

 apply {
  hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
//			lkp.ip_dst_addr[31:0],
   lkp.ip_src_addr_v4,
   lkp.ip_dst_addr_v4,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id
  });
 }
}

control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
 @symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;

 apply {
  hash[31:0] = ipv6_hash.get({
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id
  });
 }
}

control NonIpHash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
 @symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

 apply {
  hash [31:0] = non_ip_hash.get({
   lkp.mac_type,
   lkp.mac_src_addr,
   lkp.mac_dst_addr
  });
 }
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
 inout switch_bridged_metadata_h bridged_md,
 in switch_ingress_metadata_t ig_md
) {
 bridged_md.setValid();
 bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
 bridged_md.base = {
  ig_md.port,
  ig_md.port_lag_index,
  ig_md.bd,
  ig_md.nexthop,
//		ig_md.lkp.pkt_type,
  ig_md.cpu_reason,
//		ig_md.timestamp,
  ig_md.flags.rmac_hit,

  // nsh metadata
  ig_md.nsh_md.start_of_path,
  ig_md.nsh_md.end_of_path,
  ig_md.nsh_md.l2_fwd_en,
//		ig_md.nsh_md.sf1_active,
  ig_md.nsh_md.dedup_en
 };


 bridged_md.tunnel = {
  ig_md.tunnel_0.index,
  ig_md.outer_nexthop,
//		ig_md.hash[15:0],

  ig_md.tunnel_0.terminate // unused, but removing causes a compiler error
//		ig_md.tunnel_1.terminate,
//		ig_md.tunnel_2.terminate
 };
# 180 "util.p4"
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
 in switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 bit<13> hash;



 hash = ig_md.hash[32/2+12:32/2]; // cap  at 13 bits


 // Set PRE hash values
//  ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
//	ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
 ig_intr_md_for_tm.level2_mcast_hash = hash;
 ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
}

// -----------------------------------------------------------------------------

action set_eg_intr_md(
 in switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {




 eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
 eg_intr_md_for_dprsr.mirror_io_select = 1;


}
# 46 "npb.p4" 2

# 1 "l3.p4" 1
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
 ******************************************************************************/

// DEREK: NOT USING THIS TABLE ANYMORE -- USING THE TABLE IN TUNNEL.P4 INSTEAD.

# 1 "acl.p4" 1
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
 ******************************************************************************/




# 1 "scoper.p4" 1
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
 ******************************************************************************/




// ============================================================================

control Scoper(
  in switch_lookup_fields_t lkp_in,
  in switch_drop_reason_t drop_reason,

  inout switch_lookup_fields_t lkp
) {

 apply {




  // l2
  lkp.mac_src_addr = lkp_in.mac_src_addr;
  lkp.mac_dst_addr = lkp_in.mac_dst_addr;
  lkp.mac_type = lkp_in.mac_type;
  lkp.pcp = lkp_in.pcp;
  lkp.pad = lkp_in.pad;
  lkp.vid = lkp_in.vid;

  // l3
  lkp.ip_type = lkp_in.ip_type;
  lkp.ip_proto = lkp_in.ip_proto;
  lkp.ip_tos = lkp_in.ip_tos;
  lkp.ip_flags = lkp_in.ip_flags;
  lkp.ip_src_addr = lkp_in.ip_src_addr;
  lkp.ip_dst_addr = lkp_in.ip_dst_addr;
  // Comment the two below as they are alias fields and do not need to be written again.
  //lkp.ip_src_addr_v4   = lkp_in.ip_src_addr_v4;
  //lkp.ip_dst_addr_v4   = lkp_in.ip_dst_addr_v4;
  lkp.ip_len = lkp_in.ip_len;

  // l4
  lkp.tcp_flags = lkp_in.tcp_flags;
  lkp.l4_src_port = lkp_in.l4_src_port;
  lkp.l4_dst_port = lkp_in.l4_dst_port;

  // tunnel
  lkp.tunnel_type = lkp_in.tunnel_type;
  lkp.tunnel_id = lkp_in.tunnel_id;
  lkp.tunnel_outer_type = lkp_in.tunnel_outer_type;
  lkp.tunnel_inner_type = lkp_in.tunnel_inner_type;

  lkp.drop_reason = lkp_in.drop_reason;

 }
}

// ============================================================================

control ScoperOuter(
  in switch_header_outer_t hdr_1,
  in switch_tunnel_metadata_t tunnel,
  in switch_drop_reason_t drop_reason,

  inout switch_lookup_fields_t lkp
) {

 // -----------------------------
 // L2
 // -----------------------------

 action scope_l2_none() {
  lkp.mac_src_addr = 0;
  lkp.mac_dst_addr = 0;
  lkp.mac_type = 0;
  lkp.pcp = 0;
 }

 action scope_l2() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.ethernet.ether_type;
  lkp.pcp = 0;
 }


 action scope_l2_e_tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.e_tag.ether_type;
  //lkp.pcp          = hdr_1.e_tag.pcp;
  lkp.pcp = 0; // do not populate w/ e-tag
 }



 action scope_l2_vn_tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vn_tag.ether_type;
  lkp.pcp = 0;
 }


 action scope_l2_1tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vlan_tag[0].ether_type;
  lkp.pcp = hdr_1.vlan_tag[0].pcp;
 }

 action scope_l2_2tags() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vlan_tag[1].ether_type;
  lkp.pcp = hdr_1.vlan_tag[0].pcp;
 }

 table scope_l2_ {
  key = {
   hdr_1.ethernet.isValid(): exact;


   hdr_1.e_tag.isValid(): exact;



   hdr_1.vn_tag.isValid(): exact;


   hdr_1.vlan_tag[0].isValid(): exact;
   hdr_1.vlan_tag[1].isValid(): exact;
  }
  actions = {
   scope_l2_none;
   scope_l2;


   scope_l2_e_tag;



   scope_l2_vn_tag;


   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {



   (false, false, false, false, false): scope_l2_none();

   (true, false, false, false, false): scope_l2();

   (true, true, false, false, false): scope_l2_e_tag();
   (true, false, true, false, false): scope_l2_vn_tag();

   (true, false, false, true, false): scope_l2_1tag();
   (true, true, false, true, false): scope_l2_1tag();
   (true, false, true, true, false): scope_l2_1tag();

   (true, false, false, true, true ): scope_l2_2tags();
   (true, true, false, true, true ): scope_l2_2tags();
   (true, false, true, true, true ): scope_l2_2tags();
# 225 "scoper.p4"
        }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = 0;
  lkp.ip_tos = 0;
  lkp.ip_proto = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_tos = hdr_1.ipv4.tos;
  lkp.ip_proto = hdr_1.ipv4.protocol;
  lkp.ip_flags = hdr_1.ipv4.flags;
  lkp.ip_src_addr = (bit<128>) hdr_1.ipv4.src_addr;
  lkp.ip_dst_addr = (bit<128>) hdr_1.ipv4.dst_addr;
  lkp.ip_len = hdr_1.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_tos = hdr_1.ipv6.tos;
  lkp.ip_proto = hdr_1.ipv6.next_hdr;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_1.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_1.ipv6.dst_addr;
  lkp.ip_len = hdr_1.ipv6.payload_len;

 }

 table scope_l3_ {
  key = {
   hdr_1.ipv4.isValid(): exact;

   hdr_1.ipv6.isValid(): exact;

  }
  actions = {
   scope_l3_none;
   scope_l3_v4;
   scope_l3_v6;
  }
  const entries = {

   (false, false): scope_l3_none();
   (true, false): scope_l3_v4();
   (false, true ): scope_l3_v6();




  }
 }

 // -----------------------------
 // L4
 // -----------------------------

 action scope_l4_none() {
  lkp.l4_src_port = 0;
  lkp.l4_dst_port = 0;
  lkp.tcp_flags = 0;
 }

 action scope_l4_tcp() {
  lkp.l4_src_port = hdr_1.tcp.src_port;
  lkp.l4_dst_port = hdr_1.tcp.dst_port;
  lkp.tcp_flags = hdr_1.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_1.udp.src_port;
  lkp.l4_dst_port = hdr_1.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_1.sctp.src_port;
  lkp.l4_dst_port = hdr_1.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 table scope_l4_ {
  key = {
   hdr_1.tcp.isValid(): exact;
   hdr_1.udp.isValid(): exact;
   hdr_1.sctp.isValid(): exact;
  }
  actions = {
   scope_l4_tcp;
   scope_l4_udp;
   scope_l4_sctp;
   scope_l4_none;
  }
  const entries = {
   (false, false, false): scope_l4_none();
   (true, false, false): scope_l4_tcp();
   (false, true, false): scope_l4_udp();
   (false, false, true ): scope_l4_sctp();
  }
 }

 // -----------------------------
 // L3 / L4
 // -----------------------------

 action scope_l3_none_l4_none() { scope_l3_none(); scope_l4_none(); }
 action scope_l3_v4_l4_none() { scope_l3_v4(); scope_l4_none(); }
 action scope_l3_v6_l4_none() { scope_l3_v6(); scope_l4_none(); }
 action scope_l3_v4_l4_tcp() { scope_l3_v4(); scope_l4_tcp(); }
 action scope_l3_v6_l4_tcp() { scope_l3_v6(); scope_l4_tcp(); }
 action scope_l3_v4_l4_udp() { scope_l3_v4(); scope_l4_udp(); }
 action scope_l3_v6_l4_udp() { scope_l3_v6(); scope_l4_udp(); }
 action scope_l3_v4_l4_sctp() { scope_l3_v4(); scope_l4_sctp(); }
 action scope_l3_v6_l4_sctp() { scope_l3_v6(); scope_l4_sctp(); }

 table scope_l34_ {
  key = {
   hdr_1.ipv4.isValid(): exact;

   hdr_1.ipv6.isValid(): exact;


   hdr_1.tcp.isValid(): exact;
   hdr_1.udp.isValid(): exact;
   hdr_1.sctp.isValid(): exact;
  }
  actions = {
   scope_l3_v4_l4_tcp;
   scope_l3_v6_l4_tcp;
   scope_l3_v4_l4_udp;
   scope_l3_v6_l4_udp;
   scope_l3_v4_l4_sctp;
   scope_l3_v6_l4_sctp;
   scope_l3_v4_l4_none;
   scope_l3_v6_l4_none;
   scope_l3_none_l4_none;
  }
  const entries = {

   (false, false, false, false, false): scope_l3_none_l4_none();

   (true, false, false, false, false): scope_l3_v4_l4_none();
   (false, true, false, false, false): scope_l3_v6_l4_none();
   (true, false, true, false, false): scope_l3_v4_l4_tcp();
   (false, true, true, false, false): scope_l3_v6_l4_tcp();
   (true, false, false, true, false): scope_l3_v4_l4_udp();
   (false, true, false, true, false): scope_l3_v6_l4_udp();
   (true, false, false, false, true ): scope_l3_v4_l4_sctp();
   (false, true, false, false, true ): scope_l3_v6_l4_sctp();
# 392 "scoper.p4"
  }
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------
// Derek: Not using this, because it chews up too much vliw resources in tofino....
/*
	action scope_l2_none_l3_none_l4_none()  { scope_l2_none();   scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_none_l4_none()  { scope_l2();        scope_l3_none(); scope_l4_none(); }
	action scope_l2_etag_l3_none_l4_none()  { scope_l2_e_tag();  scope_l3_none(); scope_l4_none(); }
	action scope_l2_vntag_l3_none_l4_none() { scope_l2_vn_tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none()  { scope_l2_1tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_2tag_l3_none_l4_none()  { scope_l2_2tags();  scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()    { scope_l2();        scope_l3_v4();   scope_l4_none(); }
	action scope_l2_etag_l3_v4_l4_none()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_none(); }
	action scope_l2_vntag_l3_v4_l4_none()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_2tag_l3_v4_l4_none()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_none(); }

	action scope_l2_0tag_l3_v6_l4_none()    { scope_l2();        scope_l3_v6();   scope_l4_none(); }
	action scope_l2_etag_l3_v6_l4_none()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_none(); }
	action scope_l2_vntag_l3_v6_l4_none()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_2tag_l3_v6_l4_none()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_tcp()     { scope_l2();        scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v4_l4_tcp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v4_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v4_l4_tcp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v6_l4_tcp()     { scope_l2();        scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v6_l4_tcp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v6_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v6_l4_tcp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v4_l4_udp()     { scope_l2();        scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_etag_l3_v4_l4_udp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v4_l4_udp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v4_l4_udp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_udp()     { scope_l2();        scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_etag_l3_v6_l4_udp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v6_l4_udp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v6_l4_udp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v4_l4_sctp()    { scope_l2();        scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v4_l4_sctp()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v4_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v4_l4_sctp()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_sctp(); }

	action scope_l2_0tag_l3_v6_l4_sctp()    { scope_l2();        scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v6_l4_sctp()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v6_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v6_l4_sctp()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_sctp(); }

	table scope_l234_ {
		key = {
			hdr_1.ethernet.isValid(): exact;
			hdr_1.e_tag.isValid(): exact;
			hdr_1.vn_tag.isValid(): exact;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[1].isValid(): exact;

			hdr_1.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_1.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_1.tcp.isValid():  exact;
			hdr_1.udp.isValid():  exact;
			hdr_1.sctp.isValid(): exact;
		}
		actions = {
			scope_l2_0tag_l3_v4_l4_tcp;
			scope_l2_etag_l3_v4_l4_tcp;
			scope_l2_vntag_l3_v4_l4_tcp;
			scope_l2_1tag_l3_v4_l4_tcp;
			scope_l2_2tag_l3_v4_l4_tcp;

			scope_l2_0tag_l3_v6_l4_tcp;
			scope_l2_etag_l3_v6_l4_tcp;
			scope_l2_vntag_l3_v6_l4_tcp;
			scope_l2_1tag_l3_v6_l4_tcp;
			scope_l2_2tag_l3_v6_l4_tcp;

			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_etag_l3_v4_l4_udp;
			scope_l2_vntag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
			scope_l2_2tag_l3_v4_l4_udp;

			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_etag_l3_v6_l4_udp;
			scope_l2_vntag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
			scope_l2_2tag_l3_v6_l4_udp;

			scope_l2_0tag_l3_v4_l4_sctp;
			scope_l2_etag_l3_v4_l4_sctp;
			scope_l2_vntag_l3_v4_l4_sctp;
			scope_l2_1tag_l3_v4_l4_sctp;
			scope_l2_2tag_l3_v4_l4_sctp;

			scope_l2_0tag_l3_v6_l4_sctp;
			scope_l2_etag_l3_v6_l4_sctp;
			scope_l2_vntag_l3_v6_l4_sctp;
			scope_l2_1tag_l3_v6_l4_sctp;
			scope_l2_2tag_l3_v6_l4_sctp;

			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_etag_l3_v4_l4_none;
			scope_l2_vntag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_2tag_l3_v4_l4_none;

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_etag_l3_v6_l4_none;
			scope_l2_vntag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			scope_l2_2tag_l3_v6_l4_none;

			scope_l2_0tag_l3_none_l4_none;
			scope_l2_etag_l3_none_l4_none;
			scope_l2_vntag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			scope_l2_2tag_l3_none_l4_none;

			scope_l2_none_l3_none_l4_none;
		}
		const entries = {
			(false, false, false, false, false,     false, false,     false, false, false): scope_l2_none_l3_none_l4_none();

			(true,  false, false, false, false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,  false, false, false,     false, false,     false, false, false): scope_l2_etag_l3_none_l4_none();
			(true,  false, true,  false, false,     false, false,     false, false, false): scope_l2_vntag_l3_none_l4_none();
			(true,  false, false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  true,  false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, true,  true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  true,  false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  false, true,  true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();

			(true,  false, false, false, false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,  false, false, false,     true,  false,     false, false, false): scope_l2_etag_l3_v4_l4_none();
			(true,  false, true,  false, false,     true,  false,     false, false, false): scope_l2_vntag_l3_v4_l4_none();
			(true,  false, false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  true,  false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, true,  true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  true,  false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  false, true,  true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();

			(true,  false, false, false, false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,  false, false, false,     false, true,      false, false, false): scope_l2_etag_l3_v6_l4_none();
			(true,  false, true,  false, false,     false, true,      false, false, false): scope_l2_vntag_l3_v6_l4_none();
			(true,  false, false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  true,  false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, true,  true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  true,  false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  false, true,  true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();

			(true,  false, false, false, false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,  false, false, false,     true,  false,     true,  false, false): scope_l2_etag_l3_v4_l4_tcp();
			(true,  false, true,  false, false,     true,  false,     true,  false, false): scope_l2_vntag_l3_v4_l4_tcp();
			(true,  false, false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();

			(true,  false, false, false, false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,  false, false, false,     false, true,      true,  false, false): scope_l2_etag_l3_v6_l4_tcp();
			(true,  false, true,  false, false,     false, true,      true,  false, false): scope_l2_vntag_l3_v6_l4_tcp();
			(true,  false, false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();

			(true,  false, false, false, false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,  false, false, false,     true,  false,     false, true,  false): scope_l2_etag_l3_v4_l4_udp();
			(true,  false, true,  false, false,     true,  false,     false, true,  false): scope_l2_vntag_l3_v4_l4_udp();
			(true,  false, false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  true,  false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, true,  true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  true,  false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  false, true,  true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();

			(true,  false, false, false, false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,  false, false, false,     false, true,      false, true,  false): scope_l2_etag_l3_v6_l4_udp();
			(true,  false, true,  false, false,     false, true,      false, true,  false): scope_l2_vntag_l3_v6_l4_udp();
			(true,  false, false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  true,  false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, true,  true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  true,  false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  false, true,  true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();

			(true,  false, false, false, false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,  false, false, false,     true,  false,     false, false, true ): scope_l2_etag_l3_v4_l4_sctp();
			(true,  false, true,  false, false,     true,  false,     false, false, true ): scope_l2_vntag_l3_v4_l4_sctp();
			(true,  false, false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();

			(true,  false, false, false, false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,  false, false, false,     false, true,      false, false, true ): scope_l2_etag_l3_v6_l4_sctp();
			(true,  false, true,  false, false,     false, true,      false, false, true ): scope_l2_vntag_l3_v6_l4_sctp();
			(true,  false, false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
		}
	}
*/
 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
  lkp.tunnel_type = 0;
  lkp.tunnel_id = 0;
 }
/*
	action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_1.vlan_tag[0].vid;
	}
*/
 action scope_tunnel_vni() {
  lkp.tunnel_type = lkp.tunnel_type;
  lkp.tunnel_id = lkp.tunnel_id;
 }

 table scope_tunnel_ {
  key = {
   lkp.tunnel_type: exact;
/*
			tunnel.type: ternary;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[0].vid: ternary;
*/
  }
  actions = {
   scope_tunnel_vni;
//          scope_tunnel_vlan;
   scope_tunnel_none;
  }
  const entries = {
/*
			// highest -> lowest priority in tcam
			(0, true,  0): scope_tunnel_none(); // tag has priority only
			(0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
			(_, true,  _): scope_tunnel_vni();
			(_, false, _): scope_tunnel_vni();
			(0, false, _): scope_tunnel_none();
*/
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
  }
  const default_action = scope_tunnel_vni;
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
  scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l34_.apply();
//		scope_tunnel_.apply();
  scope_tunnel_vni();

  lkp.drop_reason = drop_reason;
 }
}

// ============================================================================

control ScoperInner(
  in switch_header_inner_t hdr_2,
  in switch_lookup_fields_t lkp_2,
  in switch_tunnel_metadata_t tunnel,
  in switch_drop_reason_t drop_reason,

  inout switch_lookup_fields_t lkp
) {

 // -----------------------------
 // L2
 // -----------------------------

 action scope_l2_none() {
  lkp.mac_src_addr = 0;
  lkp.mac_dst_addr = 0;
  lkp.mac_type = 0;
  lkp.pcp = 0;
 }

 action scope_l2() {
  lkp.mac_src_addr = hdr_2.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
  lkp.mac_type = hdr_2.ethernet.ether_type;
  lkp.pcp = 0;
 }

 action scope_l2_1tag() {
  lkp.mac_src_addr = hdr_2.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
  lkp.mac_type = hdr_2.vlan_tag[0].ether_type;
  lkp.pcp = hdr_2.vlan_tag[0].pcp;
 }

 table scope_l2_ {
  key = {
   hdr_2.ethernet.isValid(): exact;
   hdr_2.vlan_tag[0].isValid(): exact;
  }
  actions = {
   scope_l2_none;
   scope_l2;
   scope_l2_1tag;
  }
  const entries = {
   (false, false): scope_l2_none();

   (true, false): scope_l2();

   (true, true ): scope_l2_1tag();
  }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = 0;
  lkp.ip_tos = 0;
  lkp.ip_proto = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_tos = hdr_2.ipv4.tos;
  lkp.ip_proto = hdr_2.ipv4.protocol;
  lkp.ip_flags = hdr_2.ipv4.flags;
  lkp.ip_src_addr = (bit<128>) hdr_2.ipv4.src_addr;
  lkp.ip_dst_addr = (bit<128>) hdr_2.ipv4.dst_addr;
  lkp.ip_len = hdr_2.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_tos = hdr_2.ipv6.tos;
  lkp.ip_proto = hdr_2.ipv6.next_hdr;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_2.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_2.ipv6.dst_addr;
  lkp.ip_len = hdr_2.ipv6.payload_len;

 }

 table scope_l3_ {
  key = {
   hdr_2.ipv4.isValid(): exact;

   hdr_2.ipv6.isValid(): exact;

  }
  actions = {
   scope_l3_none;
   scope_l3_v4;
   scope_l3_v6;
  }
  const entries = {

   (false, false): scope_l3_none();
   (true, false): scope_l3_v4();
   (false, true ): scope_l3_v6();




  }
 }

 // -----------------------------
 // L4
 // -----------------------------

 action scope_l4_none() {
  lkp.l4_src_port = 0;
  lkp.l4_dst_port = 0;
  lkp.tcp_flags = 0;
 }

 action scope_l4_tcp() {
  lkp.l4_src_port = hdr_2.tcp.src_port;
  lkp.l4_dst_port = hdr_2.tcp.dst_port;
  lkp.tcp_flags = hdr_2.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_2.udp.src_port;
  lkp.l4_dst_port = hdr_2.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_2.sctp.src_port;
  lkp.l4_dst_port = hdr_2.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 table scope_l4_ {
  key = {
   hdr_2.tcp.isValid(): exact;
   hdr_2.udp.isValid(): exact;
   hdr_2.sctp.isValid(): exact;
  }
  actions = {
   scope_l4_tcp;
   scope_l4_udp;
   scope_l4_sctp;
   scope_l4_none;
  }
  const entries = {
   (false, false, false): scope_l4_none();
   (true, false, false): scope_l4_tcp();
   (false, true, false): scope_l4_udp();
   (false, false, true ): scope_l4_sctp();
  }
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------

 action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_0tag_l3_none_l4_none() { scope_l2(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_none() { scope_l2(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_1tag_l3_v4_l4_none() { scope_l2_1tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_0tag_l3_v6_l4_none() { scope_l2(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_1tag_l3_v6_l4_none() { scope_l2_1tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_tcp() { scope_l2(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v4_l4_tcp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v6_l4_tcp() { scope_l2(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v6_l4_tcp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v4_l4_udp() { scope_l2(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v4_l4_udp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v6_l4_udp() { scope_l2(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v6_l4_udp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v4_l4_sctp() { scope_l2(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v4_l4_sctp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_0tag_l3_v6_l4_sctp() { scope_l2(); scope_l3_v6(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v6_l4_sctp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_sctp(); }

 table scope_l234_ {
  key = {
   hdr_2.ethernet.isValid(): exact;
   hdr_2.vlan_tag[0].isValid(): exact;

   hdr_2.ipv4.isValid(): exact;

   hdr_2.ipv6.isValid(): exact;


   hdr_2.tcp.isValid(): exact;
   hdr_2.udp.isValid(): exact;
   hdr_2.sctp.isValid(): exact;
  }
  actions = {
   scope_l2_0tag_l3_v4_l4_tcp;
   scope_l2_1tag_l3_v4_l4_tcp;
   scope_l2_0tag_l3_v6_l4_tcp;
   scope_l2_1tag_l3_v6_l4_tcp;
   scope_l2_0tag_l3_v4_l4_udp;
   scope_l2_1tag_l3_v4_l4_udp;
   scope_l2_0tag_l3_v6_l4_udp;
   scope_l2_1tag_l3_v6_l4_udp;
   scope_l2_0tag_l3_v4_l4_sctp;
   scope_l2_1tag_l3_v4_l4_sctp;
   scope_l2_0tag_l3_v6_l4_sctp;
   scope_l2_1tag_l3_v6_l4_sctp;
   scope_l2_0tag_l3_v4_l4_none;
   scope_l2_1tag_l3_v4_l4_none;
   scope_l2_0tag_l3_v6_l4_none;
   scope_l2_1tag_l3_v6_l4_none;
   scope_l2_0tag_l3_none_l4_none;
   scope_l2_1tag_l3_none_l4_none;
   scope_l2_none_l3_none_l4_none;
  }
  const entries = {

   (false, false, false, false, false, false, false): scope_l2_none_l3_none_l4_none();

   (true, false, false, false, false, false, false): scope_l2_0tag_l3_none_l4_none();
   (true, true, false, false, false, false, false): scope_l2_1tag_l3_none_l4_none();

   (true, false, true, false, false, false, false): scope_l2_0tag_l3_v4_l4_none();
   (true, true, true, false, false, false, false): scope_l2_1tag_l3_v4_l4_none();

   (true, false, false, true, false, false, false): scope_l2_0tag_l3_v6_l4_none();
   (true, true, false, true, false, false, false): scope_l2_1tag_l3_v6_l4_none();

   (true, false, true, false, true, false, false): scope_l2_0tag_l3_v4_l4_tcp();
   (true, true, true, false, true, false, false): scope_l2_1tag_l3_v4_l4_tcp();

   (true, false, false, true, true, false, false): scope_l2_0tag_l3_v6_l4_tcp();
   (true, true, false, true, true, false, false): scope_l2_1tag_l3_v6_l4_tcp();

   (true, false, true, false, false, true, false): scope_l2_0tag_l3_v4_l4_udp();
   (true, true, true, false, false, true, false): scope_l2_1tag_l3_v4_l4_udp();

   (true, false, false, true, false, true, false): scope_l2_0tag_l3_v6_l4_udp();
   (true, true, false, true, false, true, false): scope_l2_1tag_l3_v6_l4_udp();

   (true, false, true, false, false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
   (true, true, true, false, false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

   (true, false, false, true, false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
   (true, true, false, true, false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
# 958 "scoper.p4"
  }
 }

 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
  lkp.tunnel_type = 0;
  lkp.tunnel_id = 0;
 }
/*
	action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_2.vlan_tag[0].vid;
	}
*/
 action scope_tunnel_vni() {
  lkp.tunnel_type = lkp_2.tunnel_type;
  lkp.tunnel_id = lkp_2.tunnel_id;
 }

 table scope_tunnel_ {
  key = {
   lkp_2.tunnel_type: exact;
/*
			tunnel_type: ternary;
			hdr_2.vlan_tag[0].isValid(): exact;
			hdr_2.vlan_tag[0].vid: ternary;
*/
  }
  actions = {
   scope_tunnel_vni;
//          scope_tunnel_vlan;
   scope_tunnel_none;
  }
  const entries = {
/*
			// highest -> lowest priority in tcam
			(0, true,  0): scope_tunnel_none(); // tag has priority only
			(0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
			(_, true,  _): scope_tunnel_vni();
			(_, false, _): scope_tunnel_vni();
			(0, false, _): scope_tunnel_none();
*/
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
  }
  const default_action = scope_tunnel_vni;
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
//		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l234_.apply();
//		scope_tunnel_.apply();
  scope_tunnel_vni();

//		lkp.drop_reason = drop_reason;
 }

}

// ============================================================================
/*
control Scoper_l7(
	in udf_h hdr_udf,
	inout switch_lookup_fields_t lkp
) {
	// -----------------------------
		
	action set_udf() {
#ifdef UDF_ENABLE
		lkp.udf = hdr_udf.opaque;
#endif 
	}

	action clear_udf() {
#ifdef UDF_ENABLE
		lkp.udf = 0;
#endif
	}

	table validate_udf {
		key = {
			hdr_udf.isValid() : exact;
		}

		actions = {
			NoAction;
			set_udf;
			clear_udf;
		}

		const default_action = NoAction;
		const entries = {
			(true)  : set_udf();
			(false) : clear_udf();
		}
	}

	// -----------------------------

	apply {
#ifdef UDF_ENABLE
		validate_udf.apply();
#endif // UDF_ENABLE
	}

}
*/
# 27 "acl.p4" 2

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 107 "acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 175 "acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 224 "acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 278 "acl.p4"
// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 in switch_header_outer_t hdr_1,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
//			hdr_1.e_tag.isValid()                  : ternary @name("hdr.e_tag.$valid");
//			hdr_1.vn_tag.isValid()                 : ternary @name("hdr.vn_tag.$valid");
  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control IngressIpAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control IngressIpv4Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   NoAction_;
   hit();
  }
  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control IngressIpv6Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}



//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 in udf_h hdr_udf,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   hdr_udf.opaque : ternary;

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------
   flow_class_ : ternary @name("flow_class");
  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

// ----------------------------------------------------------------------------
// Ingress Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
// @param mac_acl_enable : Add a ACL slice for L2 traffic. If mac_acl_enable is false, IPv4 ACL is
// applied to IPv4 and non-IP traffic.
// @param mac_packet_class_enable : Controls whether MAC ACL applies to all traffic entering the
// interface, including IP traffic, or to non-IP traffic only.
// ----------------------------------------------------------------------------

control IngressAcl(
 inout switch_lookup_fields_t lkp,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 inout switch_header_transport_t hdr_0,
 in switch_header_outer_t hdr_1,
 in switch_header_inner_t hdr_2,
 in udf_h hdr_udf,
 in bit<8> int_ctrl_flags
) (



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512,
 switch_uint32_t l7_table_size=512
) {

 // ---------------------------------------------------




 IngressIpv4Acl(ipv4_table_size) ipv4_acl;

 IngressIpv6Acl(ipv6_table_size) ipv6_acl;


 IngressMacAcl(mac_table_size) mac_acl;

 IngressL7Acl(l7_table_size) l7_acl;


 switch_nexthop_t nexthop;
 bool drop;
 bool terminate;
 bool scope;
 switch_cpu_reason_t cpu_reason;
 bool copy_to_cpu;
 bool redirect_to_cpu;
 switch_copp_meter_id_t copp_meter_id;
 bit<8> flow_class;

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/

 // -------------------------------------
 // Table: COPP
 // -------------------------------------

 action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason_, in switch_copp_meter_id_t copp_meter_id_) {
  ig_intr_md_for_tm.copy_to_cpu = 1w1;
  ig_md.cpu_reason = cpu_reason_;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  nexthop = 0;
  drop = false;
  terminate = false;
  scope = false;
  copy_to_cpu = false;
  redirect_to_cpu = false;
  cpu_reason = 0;
//		copp_meter_id                = 0; // TODO: this may be data and therefore not need to be initialized
  flow_class = 0;

  ig_md.nsh_md.truncate_enable = false;
  ig_md.nsh_md.dedup_en = false;
  ig_md.nsh_md.sfc_enable = false;

  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  mac_acl.apply(
   lkp,
   hdr_0,
   hdr_1,
   ig_md,
   ig_intr_md_for_dprsr,
   ip_len, ip_len_is_rng_bitmask,
   l4_src_port, l4_src_port_is_rng_bitmask,
   l4_dst_port, l4_dst_port_is_rng_bitmask,
   int_ctrl_flags,
   // ----- results -----
   nexthop,
   drop,
   terminate,
   scope,
   copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
  );

  // ----- l3/4 -----
# 878 "acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   ipv6_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    nexthop,
    drop,
    terminate,
    scope,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    nexthop,
    drop,
    terminate,
    scope,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
   );
  }


  // ----- l7 -----

  if (hdr_udf.isValid()) {
   l7_acl.apply(
    lkp,
    hdr_0,
    hdr_udf,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    nexthop,
    drop,
    terminate,
    scope,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
   );
  }


  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition

  // ----- terminate -----

  if(terminate == true) {
   ig_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
    ig_md.tunnel_2.terminate = true;
   }
  }

  // ----- scope -----


  if(scope == true) {
   if(hdr_0.nsh_type1.scope == 0) {

    // note: need to change scope here so that the lag
    // hash gets the new values....


    Scoper.apply(
     ig_md.lkp_2,
     ig_md.drop_reason_2,

     ig_md.lkp_1
    );
# 987 "acl.p4"
//				ig_md.nsh_md.hash_1 = ig_md.nsh_md.hash_2;
   }

   hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//			scope_inc.apply();
  }


  // ----- truncate -----

  if(ig_md.nsh_md.truncate_enable) {

   ig_intr_md_for_dprsr.mtu_trunc_len = ig_md.nsh_md.truncate_len + 45;

  }

  // ----- copy to cpu -----

  if(copy_to_cpu == true) {
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
  } else if(redirect_to_cpu == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0b1;
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
  }

  ig_md.copp_enable = copy_to_cpu;
  ig_md.copp_meter_id = copp_meter_id;

 }
}

// ============================================================================
// ============================================================================
// Egress ACL =================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control EgressMacAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

   // -------------------------------------------
//			hdr_1.e_tag.isValid()                  : ternary @name("hdr.e_tag.$valid");
//			hdr_1.vn_tag.isValid()                 : ternary @name("hdr.vn_tag.$valid");
  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control EgressIpAcl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control EgressIpv4Acl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control EgressIpv6Acl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action NoAction_() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   NoAction_;
   hit();
  }

  const default_action = NoAction_;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}



//-----------------------------------------------------------------------------

control EgressAcl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 inout switch_header_transport_t hdr_0,
 in switch_header_outer_t hdr_1,
 in bit<8> int_ctrl_flags
) (



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512
) {

 // ---------------------------------------------------




 EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;

 EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;


 EgressMacAcl(mac_table_size) egress_mac_acl;

 bool drop;
 bool terminate;
 bool copy_to_cpu;
 bool redirect_to_cpu;
 switch_cpu_reason_t cpu_reason;
 switch_copp_meter_id_t copp_meter_id;

 // -------------------------------------
 // Table: Terminate
 // -------------------------------------

/*
	action terminate_table_none() {
//		eg_md.nsh_md.terminate_popcount = 0;
	}

	action terminate_table_outer() {
		eg_md.tunnel_1.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
	}

//	action terminate_table_inner() {
//		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
//	}

	action terminate_table_both() {
		eg_md.tunnel_1.terminate = true;
		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 2;
	}

	table terminate_table {
		key = {
			hdr_0.nsh_type1.scope        : exact;

			eg_md.nsh_md.terminate_outer : exact; // prev
			terminate                    : exact; // curr
			eg_md.nsh_md.terminate_inner : exact; // next
		}
		actions = {
			terminate_table_none;
			terminate_table_outer;
//			terminate_table_inner;
			terminate_table_both;
		}
		const entries = {
			//  prev,  curr,  next
			// --------------------
			// scope is "outer" -- ignore terminate prev bit (there is nothing before present scope)
			(0, false, false, false) : terminate_table_none();
			(0, true,  false, false) : terminate_table_none();
			(0, false, true,  false) : terminate_table_outer();
			(0, true,  true,  false) : terminate_table_outer();
			(0, false, false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, true,  false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, false, true,  true ) : terminate_table_both();
			(0, true,  true,  true ) : terminate_table_both();

			// scope is "inner" -- ignore terminate next bit (there is nothing after present scope)
			(1, false, false, false) : terminate_table_none();
			(1, true,  false, false) : terminate_table_outer();
			(1, false, true,  false) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  false) : terminate_table_both();
			(1, false, false, true ) : terminate_table_none();
			(1, true,  false, true ) : terminate_table_outer();
			(1, false, true,  true ) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  true ) : terminate_table_both();
		}
	}
*/

 // -------------------------------------
 // Table: COPP
 // -------------------------------------
# 1526 "acl.p4"
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  drop = false;
  terminate = false;
  copy_to_cpu = false;
  redirect_to_cpu = false;
  cpu_reason = 0;
//		copp_meter_id                = 0; // TODO: this may be data and therefore not need to be initialized

  eg_md.nsh_md.strip_tag_e = false;
  eg_md.nsh_md.strip_tag_vn = false;
  eg_md.nsh_md.strip_tag_vlan = false;
  eg_md.nsh_md.add_tag_vlan_bd = 0;
  eg_md.nsh_md.truncate_enable = false;
  eg_md.nsh_md.dedup_en = false;
  eg_md.nsh_md.terminate_outer = false;
  eg_md.nsh_md.terminate_inner = false;

  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  egress_mac_acl.apply(
   lkp,
   hdr_1,
   eg_md,
   eg_intr_md_for_dprsr,
   ip_len, ip_len_is_rng_bitmask,
   l4_src_port, l4_src_port_is_rng_bitmask,
   l4_dst_port, l4_dst_port_is_rng_bitmask,
   int_ctrl_flags,
   // ----- results -----
   drop,
   terminate,
   copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
  );

  // ----- l3/4 -----
# 1589 "acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   egress_ipv6_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    drop,
    terminate,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   egress_ipv4_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    drop,
    terminate,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
   );
  }


  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition

  // ----- terminate -----

  // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
  if(terminate || eg_md.nsh_md.terminate_inner) {
   eg_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
    eg_md.tunnel_2.terminate = true;
   }
  }

  // ----- scope -----

  // note: don't need to adjust scope here, as nobody else looks at the data after this.

  // ----- copy to cpu -----
# 1660 "acl.p4"
 }
}
# 26 "l3.p4" 2
# 1 "l2.p4" 1
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
 ******************************************************************************/




//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on bd and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//
// @param dst_addr : destination MAC address.
// @param ig_md : Ingess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------
//control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
 in mac_addr_t dst_addr,
 inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t table_size
) {

 bool copp_enable_;
 switch_copp_meter_id_t copp_meter_id_;

 //-------------------------------------------------------------

 action dmac_miss(bool copp_enable, switch_copp_meter_id_t copp_meter_id) {
  ig_md.egress_port_lag_index = SWITCH_FLOOD;
  ig_md.flags.dmac_miss = true;

  copp_enable_ = copp_enable;
  copp_meter_id_ = copp_meter_id;
 }

 action dmac_hit(switch_port_lag_index_t port_lag_index, bit<4> port_lag_hash_sel, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.egress_port_lag_index = port_lag_index;
  ig_md.egress_port_lag_hash_sel = port_lag_hash_sel;

  copp_enable_ = copp_enable;
  copp_meter_id_ = copp_meter_id;
 }

 action dmac_multicast(switch_mgid_t index, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.multicast.id = index;
  ig_md.egress_port_lag_index = 0; // derek added
  ig_md.egress_port_lag_hash_sel = 0; // derek added

  copp_enable_ = copp_enable;
  copp_meter_id_ = copp_meter_id;
 }

 action dmac_redirect(switch_nexthop_t nexthop_index, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.nexthop = nexthop_index;

  copp_enable_ = copp_enable;
  copp_meter_id_ = copp_meter_id;
 }

 table dmac {
  key = {
   ig_md.bd : exact;
   dst_addr : exact;
  }

  actions = {
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;
  }

  const default_action = dmac_miss(false, 0);
  size = table_size;
 }

 //-------------------------------------------------------------

 apply {
  ig_md.flags.dmac_miss = false;

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
   dmac.apply();
  }


  ig_md.copp_enable = copp_enable_;
        ig_md.copp_meter_id = copp_meter_id_;

 }
}

//-----------------------------------------------------------------------------

control IngressBd(
 in switch_bd_t bd,
 in switch_pkt_type_t pkt_type
) (
 switch_uint32_t table_size
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action count() { stats.count(); }

 table bd_stats {
  key = {
   bd : exact;
   pkt_type : exact;
  }

  actions = {
   count;
   @defaultonly NoAction;
  }

  const default_action = NoAction;

  // 3 entries per bridge domain for unicast/broadcast/multicast packets.
  size = 3 * table_size;
  counters = stats;
 }

 apply {
  bd_stats.apply();
 }
}

//-----------------------------------------------------------------------------

control EgressBd(
 in switch_header_transport_t hdr,
 in switch_bd_t bd,
 in switch_pkt_src_t pkt_src,
 out switch_smac_index_t smac_idx
) (
 switch_uint32_t table_size
) {
/*
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	action count() {
		stats.count();
	}

	table bd_stats {
		key = {
			bd : exact;
//          pkt_type : exact;
		}

		actions = {
			count;
			@defaultonly NoAction;
		}

		size = 3 * table_size;
		counters = stats;
	}
*/
 action set_bd_properties(
  switch_smac_index_t smac_index
 ) {

  smac_idx = smac_index;

 }

 table bd_mapping {
  key = { bd : exact; }
  actions = {
   NoAction;
   set_bd_properties;
  }

  const default_action = NoAction;
  size = table_size;
 }

 apply {
  smac_idx = 0; // extreme added

  bd_mapping.apply();
//		if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
//			bd_stats.apply();
 }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanDecap(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) {

 // ---------------------
 // Apply
 // ---------------------

 apply {
  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
   // Remove the vlan tag by default.
   if (hdr.vlan_tag[0].isValid()) {
    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
    hdr.vlan_tag[0].setInvalid();
   }
  }
 }
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanXlate(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) (
 switch_uint32_t bd_table_size,
 switch_uint32_t port_bd_table_size
) {

 action set_vlan_untagged() {
  //NoAction.
 }
# 283 "l2.p4"
 action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {



  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
  hdr.vlan_tag[0].pcp = pcp; // derek: added this here...barefoot set it in qos.p4, which we don't have.
  hdr.vlan_tag[0].cfi = 0;
  hdr.vlan_tag[0].vid = vid;
  hdr.ethernet.ether_type = 0x8100;
 }

 table port_bd_to_vlan_mapping {
  key = {
   eg_md.port_lag_index : exact @name("port_lag_index");
   eg_md.bd : exact @name("bd");
  }

  actions = {
   set_vlan_untagged;
   set_vlan_tagged;
  }

  const default_action = set_vlan_untagged;
  size = port_bd_table_size;
  //TODO : fix table size once scale requirements for double tag is known
 }

 table bd_to_vlan_mapping {
  key = { eg_md.bd : exact @name("bd"); }
  actions = {
   set_vlan_untagged;
   set_vlan_tagged;
  }

  const default_action = set_vlan_untagged;
  size = bd_table_size;
 }
# 350 "l2.p4"
 apply {
  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
   if (!port_bd_to_vlan_mapping.apply().hit) {
    bd_to_vlan_mapping.apply();
   }
  }



 }
}
# 27 "l3.p4" 2

control IngressUnicast(
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t rmac_table_size = 1024
) {

    //-----------------------------------------------------------------------------
    // Router MAC lookup
    // key: destination MAC address.
    // - Route the packet if the destination MAC address is owned by the switch.
    //-----------------------------------------------------------------------------
/*
    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }

    action rmac_miss() {
        ig_md.flags.rmac_hit = false;
    }

    table rmac {
        key = {
            hdr.ethernet.dst_addr : exact;
        }

        actions = {
            rmac_hit;
            @defaultonly rmac_miss;
        }

        const default_action = rmac_miss;
        size = rmac_table_size;
    }
*/
 //-----------------------------------------------------------------------------
 // Apply
 //-----------------------------------------------------------------------------

    apply {
//		rmac.apply();
    }
}
# 48 "npb.p4" 2
# 1 "nexthop.p4" 1
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
 ******************************************************************************/

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param ig_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_ingress_metadata_t ig_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {
/*
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
#ifdef RESILIENT_ECMP_HASH_ENABLE
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.RESILIENT,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#else
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#endif
*/
    action set_nexthop_properties(
  switch_port_lag_index_t port_lag_index,
  bit<4> port_lag_hash_sel,
        switch_bd_t bd
 ) {
        ig_md.egress_port_lag_index = port_lag_index;
  ig_md.egress_port_lag_hash_sel = port_lag_hash_sel;
    }

    action set_nexthop_properties_post_routed_flood(
  switch_bd_t bd,
  switch_mgid_t mgid
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_port_lag_hash_sel = 0;
        ig_md.multicast.id = mgid;
    }
/*
    action set_nexthop_properties_glean(
	) {
        ig_md.flags.glean = true;
    }
*/
    action set_nexthop_properties_drop(
 ) {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }
/*
    action set_ecmp_properties(
		switch_port_lag_index_t port_lag_index,
		bit<4> port_lag_hash_sel,
        switch_bd_t bd,
        switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, port_lag_hash_sel, bd);
    }

    action set_ecmp_properties_drop(
	) {
        set_nexthop_properties_drop();
    }

    action set_ecmp_properties_post_routed_flood(
        switch_bd_t bd,
        switch_mgid_t mgid,
        switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(
		switch_nexthop_t nexthop_index
	) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }
*/
    action set_tunnel_properties(
  switch_bd_t bd,
  switch_tunnel_index_t tunnel_index
 ) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel_0.index = tunnel_index;
        ig_md.egress_port_lag_hash_sel = 0;
        ig_md.egress_port_lag_index = 0;
    }
/*
    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }
*/



    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
//          set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {






        switch(nexthop.apply().action_run) {
//          NoAction : { ecmp.apply(); }
            default : {}
        }


    }
}

// ----------------------------------------------------------------------------
// OuterFib (aka Outer Nexthop)
// ----------------------------------------------------------------------------

control OuterFib(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
//  Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
//  ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
//  ActionSelector(ecmp_action_profile,
//                 selector_hash,
//                 SelectorMode_t.FAIR,
//                 ECMP_MAX_MEMBERS_PER_GROUP,
//                 ecmp_group_table_size) ecmp_selector;

    action set_nexthop_properties(
  switch_port_lag_index_t port_lag_index,
  bit<4> port_lag_hash_sel,
        switch_outer_nexthop_t nexthop_index
 ) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
  ig_md.egress_port_lag_hash_sel = port_lag_hash_sel;
    }

    table fib {
        key = {
            ig_md.tunnel_0.index : exact;
//          ig_md.hash[31:0] : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
//      implementation = ecmp_selector;
        size = fib_table_size;
    }

    apply {

        fib.apply();

    }
}
# 49 "npb.p4" 2
# 1 "port.p4" 1
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
 ******************************************************************************/

# 1 "rewrite.p4" 1

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
 ******************************************************************************/




# 1 "l2.p4" 1
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
 ******************************************************************************/
# 28 "rewrite.p4" 2

control Rewrite(inout switch_header_outer_t hdr,
    inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel
)(
    switch_uint32_t nexthop_table_size,
    switch_uint32_t bd_table_size) {

//	EgressBd(bd_table_size) egress_bd;
 switch_smac_index_t smac_index;

 // ---------------------------------------------
 // Table: Nexthop Rewrite
 // ---------------------------------------------

 action rewrite_l2_with_tunnel( // tun type
  switch_tunnel_type_t type
 ) {

  tunnel.type = type;

 }

 action rewrite_l3( // dmac + bd
//		mac_addr_t dmac,
  switch_bd_t bd
 ) {
//		hdr.ethernet.dst_addr = dmac;
  eg_md.bd = bd;
 }

 action rewrite_l3_with_tunnel_id( // dmac + bd + tun type + tun id
//		mac_addr_t dmac,

  switch_tunnel_type_t type,
  switch_tunnel_id_t id
 ) {

//		hdr.ethernet.dst_addr = dmac;
  eg_md.bd = SWITCH_BD_DEFAULT_VRF;

  tunnel.type = type;
  tunnel.id = id;

 }

 action rewrite_l3_with_tunnel_bd( // dmac + bd + tun type
//		mac_addr_t dmac,
  switch_bd_t bd,

  switch_tunnel_type_t type
 ) {

//		hdr.ethernet.dst_addr = dmac;
  eg_md.bd = bd;

  tunnel.type = type;

 }

 action rewrite_l3_with_tunnel( // dmac + tun type
//		mac_addr_t dmac,

  switch_tunnel_type_t type
 ) {

//		hdr.ethernet.dst_addr = dmac;
//		eg_md.bd = (switch_bd_t) eg_md.vrf;

  tunnel.type = type;

 }

 table nexthop_rewrite {
  key = { eg_md.nexthop : exact; }
  actions = {
   NoAction;
   rewrite_l2_with_tunnel;
   rewrite_l3;
   rewrite_l3_with_tunnel;
   rewrite_l3_with_tunnel_bd;
   rewrite_l3_with_tunnel_id;
  }

  const default_action = NoAction;
  size = nexthop_table_size;
 }

 // ---------------------------------------------
 // Table: SMAC Rewrite
 // ---------------------------------------------
/*
	action rewrite_smac(mac_addr_t smac) {
		hdr.ethernet.src_addr = smac;
	}

	table smac_rewrite {
		key = { smac_index : exact; }
		actions = {
			NoAction;
			rewrite_smac;
		}

		const default_action = NoAction;
	}
*/
 // ---------------------------------------------
 // Apply
 // ---------------------------------------------

 apply {
  smac_index = 0;

  // Should not rewrite packets redirected to CPU.



  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
   nexthop_rewrite.apply();
  }


//		egress_bd.apply(hdr, eg_md.bd,                          eg_md.pkt_src,
//			smac_index);

//		if (!EGRESS_BYPASS(REWRITE) && eg_md.flags.routed) {
//			smac_rewrite.apply();
//		}
 }
}
# 24 "port.p4" 2

//-----------------------------------------------------------------------------
// Port Mirroring
//-----------------------------------------------------------------------------

control PortMirror(
  in switch_port_t port,
  in switch_pkt_src_t src,
  inout switch_mirror_metadata_t mirror_md,
  in bit<8> cpu_reason_code, // extreme added
  inout bit<8> cpu_reason // extreme added
)(
  switch_uint32_t table_size=288
) {

 action set_mirror_id(switch_mirror_session_t session_id) {
  mirror_md.type = 1;
  mirror_md.src = src;
  mirror_md.session_id = session_id;
  cpu_reason = cpu_reason_code; // extreme added
 }

 table port_mirror {
  key = { port : exact; }
  actions = {
   NoAction;
   set_mirror_id;
  }

  const default_action = NoAction;
  size = table_size;
 }

 apply {
  port_mirror.apply();
 }
}

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
  inout switch_header_t hdr,
  inout switch_ingress_metadata_t ig_md,
  inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
  inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
  switch_uint32_t port_vlan_table_size,
  switch_uint32_t bd_table_size,
  switch_uint32_t port_table_size=288,
  switch_uint32_t vlan_table_size=4096
) {



 ActionProfile(bd_table_size) bd_action_profile;

 bool valid_cpu;

 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 // Helper action:

 switch_cpu_reason_t cpu_reason_;
 bool copy_to_cpu_;
 bool redirect_to_cpu_;
 switch_copp_meter_id_t copp_meter_id_;

 action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason, in switch_copp_meter_id_t copp_meter_id) {
  ig_intr_md_for_tm.copy_to_cpu = 1w1;
  ig_md.cpu_reason = cpu_reason;
 }

 // --------------------------

 // Helper action:

 action terminate_cpu_packet() {

  // ig_md.bypass = hdr.cpu.reason_code;                                             // Done in parser
  // ig_md.port = (switch_port_t) hdr.cpu.ingress_port;                              // Done in parser
  // ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index; // Done in parser
  // hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;                             // Wants to be done in parser (see bf-case 10933)

  //XXX(msharif) : Fix this for Tofino2
  // ig_intr_md_for_tm.qid = hdr.cpu.egress_queue;

  ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass; // Not done in parser, since ig_intr_md_for_tm doesn't exist there.


  valid_cpu = true;
 }

 // --------------------------

 action set_cpu_port_properties_with_nsh(
//		switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
  switch_yid_t exclusion_id
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc
 ) {

//		ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

  terminate_cpu_packet();

 }

 action set_cpu_port_properties_without_nsh(
//		switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
  switch_yid_t exclusion_id,
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc

  bit<12> sap,
  bit<12> vpn,
  bit<24> spi,
  bit<8> si,
  bit<8> si_predec
 ) {

//		ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

  terminate_cpu_packet();

  hdr.transport.nsh_type1.sap = (bit<16>)sap; // 16 bits
  hdr.transport.nsh_type1.vpn = (bit<16>)vpn; // 16 bits
  hdr.transport.nsh_type1.spi = spi; // 24 bits
  hdr.transport.nsh_type1.si = si; //  8 bits
  ig_md.nsh_md.si_predec = si_predec; //  8 bits

 }

 // --------------------------

 action set_port_properties_with_nsh(
  switch_yid_t exclusion_id
# 190 "port.p4"
 ) {
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;







 }

 action set_port_properties_without_nsh(
  switch_yid_t exclusion_id,
# 211 "port.p4"
  bit<12> sap,
  bit<12> vpn,
  bit<24> spi,
  bit<8> si,
  bit<8> si_predec
 ) {
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
# 226 "port.p4"
  hdr.transport.nsh_type1.sap = (bit<16>)sap; // 16 bits
  hdr.transport.nsh_type1.vpn = (bit<16>)vpn; // 16 bits
  hdr.transport.nsh_type1.spi = spi; // 24 bits
  hdr.transport.nsh_type1.si = si; //  8 bits
  ig_md.nsh_md.si_predec = si_predec; //  8 bits
 }

 // --------------------------

 table port_mapping {
  key = {
   ig_md.port : exact;
   hdr.cpu.isValid() : exact;
//			hdr.cpu.ingress_port : exact; // DEREK: IS THIS NEEDED / WHAT IS IT FOR?

   hdr.transport.nsh_type1.isValid() : exact;
  }

  actions = {
   set_port_properties_with_nsh; // {nsh, cpu} = {0, 0}
   set_port_properties_without_nsh; // {nsh, cpu} = {1, 0}
   set_cpu_port_properties_with_nsh; // {nsh, cpu} = {0, 1}
   set_cpu_port_properties_without_nsh; // {nsh, cpu} = {1, 1}
  }

  size = port_table_size * 4; // derek: was 2 in switch, but doubling to 4 because we added nsh valid to it.
 }

 // ----------------------------------------------
 // Table: BD Mapping
 // ----------------------------------------------

 action port_vlan_miss() {
  //ig_md.flags.port_vlan_miss = true;
 }

 action set_bd_properties(
  switch_bd_t bd ,
  switch_rid_t rid
 ) {
  ig_md.bd = bd;



 }

 // (port, vlan) --> bd mapping -- Following set of entres are needed:
 //   (port, 0, *)    L3 interface.
 //   (port, 1, vlan) L3 sub-interface.
 //   (port, 0, *)    Access port + untagged packet.
 //   (port, 1, vlan) Access port + packets tagged with access-vlan.
 //   (port, 1, 0)    Access port + .1p tagged packets.
 //   (port, 1, vlan) L2 sub-port.
 //   (port, 0, *)    Trunk port if native-vlan is not tagged.

 table port_vlan_to_bd_mapping {
  key = {
   ig_md.port_lag_index : exact;
//			hdr.transport.vlan_tag[0].isValid() : ternary;
//			hdr.transport.vlan_tag[0].vid : ternary;
   hdr.outer.vlan_tag[0].isValid() : ternary;
   hdr.outer.vlan_tag[0].vid : ternary;
  }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = NoAction;
  implementation = bd_action_profile;
  size = port_vlan_table_size;
 }

 // (*, vlan) --> bd mapping
 table vlan_to_bd_mapping {
  key = {
//			hdr.transport.vlan_tag[0].vid : exact;
   hdr.outer.vlan_tag[0].vid : exact;
  }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = port_vlan_miss;
  implementation = bd_action_profile;
  size = vlan_table_size;
 }

 table cpu_to_bd_mapping {
  key = { ig_md.bd : exact; }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = port_vlan_miss;
  implementation = bd_action_profile;
  size = bd_table_size;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
  valid_cpu = false;
/*
		switch (port_mapping.apply().action_run) {
			set_port_properties : {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.transport.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
		}
*/
  if(port_mapping.apply().hit) {
   if(hdr.cpu.isValid()) {
    cpu_to_bd_mapping.apply();
   } else {
    if (!port_vlan_to_bd_mapping.apply().hit) {
     if (hdr.transport.vlan_tag[0].isValid()) {

// derek: removing this for tofino 1, because it causes a bunch of valids to not fit (compiler bug?)
      vlan_to_bd_mapping.apply();

     }
    }
   }
  }
# 379 "port.p4"
  // derek: this copy-to-cpu feature was added here, because port mirroring
  // (above) is not fitting....
# 389 "port.p4"
 }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
// ----------------------------------------------------------------------------

control LAG(
 inout switch_ingress_metadata_t ig_md,
 in bit<(32/2)> hash,
 out switch_port_t egress_port
) {
 bit<16> lag_hash;

 Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;



 ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
 ActionSelector(lag_action_profile,
                selector_hash,
//	               SelectorMode_t.FAIR,
                SelectorMode_t.RESILIENT,
                LAG_MAX_MEMBERS_PER_GROUP,
                LAG_GROUP_TABLE_SIZE) lag_selector;

 // ----------------------------------------------
 // Table: LAG
 // ----------------------------------------------

 action set_lag_port(switch_port_t port) {
  egress_port = port;
 }







 action lag_miss() { }

 table lag {
  key = {



   ig_md.egress_port_lag_index : exact @name("port_lag_index");



   hash : selector;



  }

  actions = {
   lag_miss;
   set_lag_port;



  }

  const default_action = lag_miss;
  size = LAG_TABLE_SIZE;
  implementation = lag_selector;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
        lag_hash = selector_hash.get({ig_md.lkp_1.mac_src_addr,
                                      ig_md.lkp_1.mac_dst_addr,
                                      ig_md.lkp_1.mac_type,
                                      ig_md.lkp_1.ip_src_addr,
                                      ig_md.lkp_1.ip_dst_addr,
                                      ig_md.lkp_1.ip_proto,
                                      ig_md.lkp_1.l4_dst_port,
                                      ig_md.lkp_1.l4_src_port});
  lag.apply();
 }
}

//-----------------------------------------------------------------------------
// Egress Port Mapping
//-----------------------------------------------------------------------------

control EgressPortMapping(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in switch_port_t port
) (
 switch_uint32_t table_size=288
) {




 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 action port_normal(
  switch_port_lag_index_t port_lag_index
 ) {
  eg_md.port_lag_index = port_lag_index;
 }

 action cpu_rewrite() {
  // ----- add fabric header -----







  // ----- add cpu header -----
  hdr.cpu.setValid();
/*
		hdr.cpu.egress_queue = 0;
		hdr.cpu.tx_bypass = 0;
		hdr.cpu.capture_ts = 0;
		hdr.cpu.reserved = 0;
*/
  // Both these line are here instead of parser out due to compiler... "error: Field is
  // extracted in the parser into multiple containers, but the container
  // slices after the first aren't byte aligned"
  hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
  hdr.cpu.port_lag_index = (bit<16>) eg_md.port_lag_index;
/*
		hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
		hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
		hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
*/



  hdr.outer.ethernet.ether_type = 0x9001;

 }

 action port_cpu(
  switch_port_lag_index_t port_lag_index,
  switch_meter_index_t meter_index
 ) {

  cpu_rewrite();




 }

 table port_mapping {
  key = {
   port : exact;
  }

  actions = {
   port_normal;
   port_cpu;
  }

  size = table_size;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
  port_mapping.apply();




 }
}
# 50 "npb.p4" 2
# 1 "validation.p4" 1
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
 ******************************************************************************/




// ============================================================================
// Transport Validation
// ============================================================================

control PktValidation(
        in switch_header_transport_t hdr, // src
  in bool ipv4_checksum_err, // src
  in switch_tunnel_metadata_t tunnel, // src
        inout switch_lookup_fields_t lkp, // dst
        out switch_drop_reason_t drop_reason // dst
) {

    const switch_uint32_t table_size = 64;

    // -----------------------------
 // L2
    // -----------------------------

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action malformed_non_ip_pkt(bit<8> reason) {
        malformed_pkt(reason);
    }

    action valid_unicast_pkt_untagged() {
    }

    action valid_unicast_pkt_tagged() {
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
        }

        actions = {
            malformed_non_ip_pkt;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
        }

        size = table_size;
        /* const entries = {
            (_, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_non_ip_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }

    // -----------------------------
 // L3, v4
    // -----------------------------


    action malformed_ipv4_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        // Set common lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_ipv4_pkt;
        }

        size = table_size;
    }


// Current encap requirments do not include UDP in the transport stack
//     // -----------------------------
// 	// L4
//     // -----------------------------
// 
//     action set_udp_ports() {
//         lkp.l4_src_port = hdr.udp.src_port;
//         lkp.l4_dst_port = hdr.udp.dst_port;
//     }
// 
//     // Not much of a validation as it only sets the lookup fields.
//     table validate_other {
//         key = {
//             hdr.udp.isValid() : exact;
//         }
// 
//         actions = {
// 			NoAction;
//             set_udp_ports;
//         }
// 
//         const default_action = NoAction;
//         const entries = {
// /*
//             (true, false, false, false, false, false) : set_tcp_ports();
//             (false, true, false, false, false, false) : set_udp_ports();
//             (false, false, true, false, false, false) : set_sctp_ports();
//             (false, false, false, true, false, false) : set_icmp_type();
//             (false, false, false, false, true, false) : set_igmp_type();
//             (false, false, false, false, false, true) : set_arp_opcode();
// */
//             (true) : set_udp_ports();
//         }
//     }
// 
// 
//     // -----------------------------
// 	   // L4
//     // -----------------------------
// 
//     action set_udp_ports() {
//     }
// 
//     // Not much of a validation as it only sets the lookup fields.
//     table validate_other {
//         key = {
//             hdr.udp.isValid() : exact;
//         }
// 
//         actions = {
// 			NoAction;
//             set_udp_ports;
//         }
// 
//         const default_action = NoAction;
//         const entries = {
//             (true) : set_udp_ports();
//         }
//     }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
   // highest -> lowest priority in tcam
            (0, true, 0): validate_tunnel_none(); // tag has priority only
            (0, true, _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true, _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -------------------------------------
    // Extreme Networks - Added
    // -------------------------------------

    // Validate Extreme NSH underlay header.
    //
    // Currently, we only support parsing of our own, fixed length Extreme
    // (MD-Type1), NSH. This validation logic will drop any NSH pkt that does
    // not conform. In the future, when PHV resources are less tight, we plan
    // to add support for parsing non-Extreme NSH as well.
    //
    //   Drop the packet if:
    //
    //        version != 0                     -> Base Header          
    //              o == 1  (oam)                     :                
    //            ttl == 0                            :                
    //            len != 6  (4B words)                :                
    //        md_type != 1                            :                
    //     next_proto != 3  (enet)                    :                
    //             si == 0                     -> Service Path Header      
    //       md_class != ?  (todo)             -> Variable Length Context Header
    //           type != ?  (todo)                    :                
    //         md_len != 8  (bytes)                   :                
    //           todo == ?  (any checks here?) -> Variable Length Metadata   

    table validate_nsh {

        key = {
            hdr.nsh_type1.version : range;
            hdr.nsh_type1.o : ternary;
            hdr.nsh_type1.ttl : ternary;
            hdr.nsh_type1.len : range;
            hdr.nsh_type1.md_type : range;
            hdr.nsh_type1.next_proto : range;
            hdr.nsh_type1.si : ternary;
            //hdr.nsh_type1.md_class : ternary;
            //hdr.nsh_type1.type : ternary;
            //hdr.nsh_type1.md_len : range;
            //hdr.nsh_type1.xxx : ternary;
        }

        actions = {
            NoAction;
            malformed_pkt;
        }

        size = table_size;
        const default_action = NoAction;
        const entries = {
            // Can a range match type be a don't care? (it compiles..)
            (2w1 .. 2w3, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID);
            (_, 1, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_OAM);
   // Derek: Consider removing this ttl check.  The RFC allows
   // an incoming TTL of 0 for backwards compatibility....
            (_, _, 0, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO);
            (_, _, _, 6w0 .. 6w5, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID);
            (_, _, _, 6w7 .. 6w63, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID);
            (_, _, _, _, 4w0 .. 4w0, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID);
            (_, _, _, _, 4w2 .. 4w15, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID);
            (_, _, _, _, _, 8w0 .. 8w0, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, 8w4 .. 8w255, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, _, 0):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO);
//          (_, _, _, _, _, _, _, 7w0 .. 7w7):
//          malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID);
//          (_, _, _, _, _, _, _, 7w9 .. 7w127):
//          malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID);
            // todo: Instead of all the above ranges, would it be better to
            // create a single bit key field (len_eq_5) based on a length
            // compare?
        }
    }

    // -----------------------------
 // Apply
    // -----------------------------

    apply {
        // -------------------------------------
        // Extreme Networks - Modified
        // -------------------------------------
/*
        switch(validate_ethernet.apply().action_run) {
            malformed_non_ip_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_ENABLE
                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
#endif

                validate_other.apply();
            }
        }
    }
*/
        if (hdr.nsh_type1.isValid()) { // extreme added
            // --- PACKET HAS UNDERLAY ---
            switch(validate_nsh.apply().action_run) { // extreme added
                malformed_pkt : {} // extreme added
                default: { // extreme added
                    switch(validate_ethernet.apply().action_run) {
                        malformed_non_ip_pkt : {}

                        default : {

                            if (hdr.ipv4.isValid()) {
                                validate_ipv4.apply();
                            }

                            //validate_other.apply();

                            validate_tunnel.apply();
                        }
                    }
                } // extreme added
            } // extreme added
        }

        // currently only NSH transport supported
        // if NSH invalid, then there will be no transport headers to validate
        // else { // extreme added
        //     // --- PACKET DOES NOT HAVE UNDERLAY ---
        //             switch(validate_ethernet.apply().action_run) {
        //                 malformed_non_ip_pkt : {}
        //                 default : {
        //                     if (hdr.ipv4.isValid()) {
        //                         validate_ipv4.apply();
        //                     }
        // 
        //                     validate_other.apply();
        // 
        //                     validate_tunnel.apply();
        //                 }
        //             }
        // } // extreme added
    }
}

// ============================================================================
// Outer Validation
// ============================================================================

control OuterPktValidation(
    in switch_header_outer_t hdr, // src
 in bool ipv4_checksum_err, // src
 in switch_tunnel_metadata_reduced_t tunnel, // src
    inout switch_lookup_fields_t lkp, // dst
    out switch_drop_reason_t drop_reason // dst
) {

    const switch_uint32_t table_size = 64;

    // -----------------------------
 // L2
    // -----------------------------

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action malformed_non_ip_pkt(bit<8> reason) {
        malformed_pkt(reason);
    }

    action valid_unicast_pkt_untagged() {
    }

    action valid_unicast_pkt_tagged() {
    }

    action valid_unicast_pkt_double_tagged() {
    }


    action valid_unicast_pkt_e_tagged() {
    }



    action valid_unicast_pkt_vn_tagged() {
    }


    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[1].isValid() : ternary;

            hdr.e_tag.isValid() : ternary;


            hdr.vn_tag.isValid() : ternary;

        }

        actions = {
            malformed_non_ip_pkt;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
            valid_unicast_pkt_double_tagged;

            valid_unicast_pkt_e_tagged;


            valid_unicast_pkt_vn_tagged;

        }

        size = table_size;
        /* const entries = {
            (_, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_non_ip_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }

    // -----------------------------
 // L3, v4
    // -----------------------------

    action malformed_ipv4_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        // Set common lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_ipv4_pkt;
        }

        size = table_size;
    }

    // -----------------------------
 // L3, v6
    // -----------------------------



    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv6_pkt() {
        // Set common lookup fields
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv6_pkt;
            malformed_ipv6_pkt;
        }

        size = table_size;
    }



    // -----------------------------
 // L4
    // -----------------------------

    action set_tcp_ports() {
    }

    action set_udp_ports() {
    }

    action set_sctp_ports() {
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.sctp.isValid() : exact;
        }

        actions = {
   NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_sctp_ports;
        }

        const default_action = NoAction;
        const entries = {
            ( true, false, false) : set_tcp_ports();
            (false, true, false) : set_udp_ports();
            (false, false, true) : set_sctp_ports();
        }
    }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
   // highest -> lowest priority in tcam
            (0, true, 0): validate_tunnel_none(); // tag has priority only
            (0, true, _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true, _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -----------------------------
 // Apply
    // -----------------------------

    apply {
        // -------------------------------------
        // Extreme Networks - Modified
        // -------------------------------------

/*
        switch(validate_ethernet.apply().action_run) {
            malformed_non_ip_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_ENABLE
                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
#endif
                validate_other.apply();

				validate_tunnel.apply();
            }
        }
*/
    validate_ethernet.apply();

                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }

                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }

                validate_other.apply();

    validate_tunnel.apply();
    }
}

// ============================================================================
// Inner Validation
// ============================================================================

control InnerPktValidation(
    in switch_header_inner_t hdr, // src
 in bool ipv4_checksum_err, // src
 in switch_tunnel_metadata_reduced_t tunnel, // src
    inout switch_lookup_fields_t lkp, // dst
    inout switch_drop_reason_t drop_reason // dst
) (
 bool test=true
) {

    // -------------------------------------
    // L2
    // -------------------------------------

    action valid_unicast_pkt_untagged() {
        // Set the common L2 lookup fields

    }

    action valid_unicast_pkt_tagged() {
    }

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
        }

        actions = {
            NoAction;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
            malformed_pkt;
        }
    }

    // -------------------------------------
    // L3, v4
    // -------------------------------------

    action valid_ipv4_pkt() {
        // Set the common IP lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.ttl : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }
        /*
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }

    // -------------------------------------
    // L3, v6
    // -------------------------------------


    action valid_ipv6_pkt() {
        // Set the common IP lookup fields
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }
        const entries = {
            (0 &&& 0, 0) : malformed_pkt(SWITCH_DROP_REASON_IP_IHL_INVALID);
            (6, 0 &&& 0) : valid_ipv6_pkt();
            (0 &&& 0, 0 &&& 0) : malformed_pkt(SWITCH_DROP_REASON_IP_VERSION_INVALID);
        }
    }


    // -------------------------------------
    // L4
    // -------------------------------------

    action set_tcp_ports() {
    }

    action set_udp_ports() {
    }

    action set_sctp_ports() {
    }

    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.sctp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_sctp_ports;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false) : set_tcp_ports();
            (false, true, false) : set_udp_ports();
            (false, false, true) : set_sctp_ports();
        }
    }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
   // highest -> lowest priority in tcam
            (0, true, 0): validate_tunnel_none(); // tag has priority only
            (0, true, _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true, _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -----------------------------
 // Apply
    // -----------------------------

    apply {
/*
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_TUNNEL_ENABLE
                else if (hdr.ipv6.isValid()) {
					if(test == true) {
                        validate_ipv6.apply();
					}
                }
#endif

                validate_other.apply();

  				validate_tunnel.apply();
            }
        }
*/
    validate_ethernet.apply();

                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
//#ifdef IPV6_TUNNEL_ENABLE

               else if (hdr.ipv6.isValid()) {
     if(test == true) {
                        validate_ipv6.apply();
     }
                }


                validate_other.apply();

      validate_tunnel.apply();
    }
}

// ============================================================================
// Parser Validation
// ============================================================================

// From tofino2.p4:  todo: are these mutually exclusive?
// ------------------------------------------------------
// typedef error ParserError_t;
// const bit<16> PARSER_ERROR_OK            = 16w0x0000;
// const bit<16> PARSER_ERROR_NO_TCAM       = 16w0x0001;
// const bit<16> PARSER_ERROR_PARTIAL_HDR   = 16w0x0002;
// const bit<16> PARSER_ERROR_CTR_RANGE     = 16w0x0004;
// const bit<16> PARSER_ERROR_TIMEOUT_USER  = 16w0x0008;
// const bit<16> PARSER_ERROR_TIMEOUT_HW    = 16w0x0010;
// const bit<16> PARSER_ERROR_SRC_EXT       = 16w0x0020;
// const bit<16> PARSER_ERROR_PHV_OWNER     = 16w0x0080;
// const bit<16> PARSER_ERROR_MULTIWRITE    = 16w0x0100;
// const bit<16> PARSER_ERROR_ARAM_MBE      = 16w0x0400;
// const bit<16> PARSER_ERROR_FCS           = 16w0x0800;
// const bit<16> PARSER_ERROR_CSUM_MBE      = 16w0x1000;

control ParserValidation(
        inout switch_header_t hdr,
  in switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        out ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

    // see slide 97 of the BF Training Material (Data Plane Programming):
    // default actions can be changed at runtime using the APIs.
    // todo: do we need to invalidate udf header here too?
    action drop() { ig_intr_md_for_dprsr.drop_ctl = 1; exit; }
    action except() { ig_intr_md_for_dprsr.drop_ctl = 0; }
//     action copy_to_cpu()   { ig_intr_md_for_tm.copy_to_cpu = 1; }
// #ifdef MIRROR_INGRESS_ENABLE
//     action mirror_to_cpu() { ig_intr_md_for_dprsr.mirror_type = 1; }
// #endif // MIRROR_INGRESS_ENABLE

    table handle_parser_errors {
        key = {
            //hdr.udf.isValid() : exact;
            //ig_md.parse_udf_reached : exact;
            ig_intr_from_prsr.parser_err: exact;
        }

        actions = {
            drop;
            except;
//             copy_to_cpu;
// #ifdef MIRROR_INGRESS_ENABLE
//             mirror_to_cpu;
// #endif // MIRROR_INGRESS_ENABLE
            NoAction;
        }

        const default_action = drop;
        const entries = {
            // the parser is able to roll off the end of small packets
            // when extracting the opaque UDF data. we want to make an
            // exception for this case, and not drop these frame.
            //(false,  1, (PARSER_ERROR_PARTIAL_HDR & PARSER_ERROR_SRC_EXT)) : except();
            //(false,  1, (0xFFFF &&& PARSER_ERROR_PARTIAL_HDR)) : except(); 
            PARSER_ERROR_PARTIAL_HDR: except();
        }
    }

    // -----------------------------

 apply {
        if (ig_intr_from_prsr.parser_err != 0) {
            handle_parser_errors.apply();
        }
 }
}
# 51 "npb.p4" 2
# 1 "rewrite.p4" 1

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
 ******************************************************************************/
# 52 "npb.p4" 2
# 1 "tunnel.p4" 1
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
 ******************************************************************************/




# 1 "scoper.p4" 1
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
 ******************************************************************************/
# 27 "tunnel.p4" 2

//#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
//#error "IPv6 tunneling cannot be enabled without enabling IPv6"
//#endif

//-----------------------------------------------------------------------------
// Ingress Tunnel RMAC: Transport
//-----------------------------------------------------------------------------

control IngressTunnelRMAC(
 inout switch_header_transport_t hdr_0,
 inout switch_lookup_fields_t lkp_0,
 inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t table_size = 128
) {

 // -------------------------------------
 // Table: RMAC
 // -------------------------------------


 action rmac_hit(
 ) {
  ig_md.flags.rmac_hit = true;
 }

 action rmac_miss(
 ) {
  ig_md.flags.rmac_hit = false;
 }

 table rmac {
  key = {



   hdr_0.ethernet.dst_addr : exact;

  }

  actions = {
   NoAction;
   rmac_hit;
   rmac_miss; // extreme added
  }

//		const default_action = NoAction;
  const default_action = rmac_miss;
  size = table_size;
 }


 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(hdr_0.ethernet.isValid()) {
//		if(ig_md.nsh_md.l2_fwd_en == true) {
   // network tapped
   rmac.apply();
  } else {
   // optically tapped
   ig_md.flags.rmac_hit = true;
  }



 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Transport (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnel(
 inout switch_ingress_metadata_t ig_md,
 inout bool ig_md_flags_ipv4_checksum_err,
 inout switch_header_transport_t hdr_0,
 inout switch_lookup_fields_t lkp_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, // extreme added
 out bool hit
) (
 switch_uint32_t ipv4_src_vtep_table_size=1024,
 switch_uint32_t ipv6_src_vtep_table_size=1024,
 switch_uint32_t ipv4_dst_vtep_table_size=1024,
 switch_uint32_t ipv6_dst_vtep_table_size=1024
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtep;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtep;





 // -------------------------------------
 // Table: IPv4/v6 Src VTEP
 // -------------------------------------

 // Derek note: These tables are unused in latest switch.p4 code from barefoot

 action src_vtep_hit(
  switch_port_lag_index_t port_lag_index,
  bit<12> sap,
  bit<12> vpn
 ) {
  stats_src_vtep.count();

  ig_md.port_lag_index = port_lag_index;
  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
 }

 action src_vtep_miss(
 ) {
  stats_src_vtep.count();
 }

 // -------------------------------------

 table src_vtep {
  key = {




   hdr_0.ipv4.src_addr : ternary @name("src_addr");


//			tunnel_0.type           : exact @name("tunnel_type");
   lkp_0.tunnel_type : exact @name("tunnel_type");
  }

  actions = {
   src_vtep_miss;
   src_vtep_hit;
  }

  const default_action = src_vtep_miss;
  counters = stats_src_vtep;
  size = ipv4_src_vtep_table_size;
 }

 // -------------------------------------
 // -------------------------------------
# 221 "tunnel.p4"
 // -------------------------------------
 // Table: IPv4/v6 Dst VTEP
 // -------------------------------------

 action dst_vtep_hit(
//		switch_bd_t bd,

  bit<3> drop







 ) {
  stats_dst_vtep.count();

//		ig_md.bd = bd;

  ig_intr_md_for_dprsr.drop_ctl = drop;






 }

 action dst_vtep_tunid_hit(
 ) {
  stats_dst_vtep.count();
 }

 action NoAction_(
 ) {
  stats_dst_vtep.count();
 }

 // -------------------------------------

 table dst_vtep {
  key = {
# 275 "tunnel.p4"
   hdr_0.ipv4.dst_addr : ternary @name("dst_addr");


//			tunnel_0.type           : exact @name("tunnel_type");
   lkp_0.tunnel_type : exact @name("tunnel_type");
  }

  actions = {
   NoAction_;
   dst_vtep_hit;
   dst_vtep_tunid_hit;
  }

  const default_action = NoAction_;
  counters = stats_dst_vtep;
  size = ipv4_dst_vtep_table_size;
 }

 // -------------------------------------
 // -------------------------------------
# 366 "tunnel.p4"
 // -------------------------------------
 // Table: VNI to BD
 // -------------------------------------
/*
    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

	// -------------------------------------
	// -------------------------------------

#ifdef IPV6_TRANSPORT_INGRESS_ENABLE
    // Tunnel id -> BD Translation
    table vni_to_bd_mappingv6 {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtepv6_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }
#endif
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  // outer RMAC lookup for tunnel termination.
//		switch(rmac.apply().action_run) {
//			rmac_hit : {

    if (hdr_0.ipv4.isValid()) {
//				if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV4) {

     hit = src_vtep.apply().hit;

     switch(dst_vtep.apply().action_run) {
      dst_vtep_hit : {
      }
      dst_vtep_tunid_hit : {
       // Vxlan
//							vni_to_bd_mapping.apply();
      }
     }
# 443 "tunnel.p4"
    } else {
     hit = false;
    }

//			}
//		}

 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Network (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelNetwork(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp_0,
 inout switch_header_transport_t hdr_0,

 inout switch_tunnel_metadata_t tunnel_0
) (
 switch_uint32_t sap_table_size=32w1024
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------




 action NoAction_ (
 ) {
  stats.count();
 }

 action sap_hit (
  bit<12> sap,
  bit<12> vpn
 ) {
  stats.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
 }

 // ---------------------------------

 table sap {
  key = {
   hdr_0.nsh_type1.sap : exact @name("sap");

   // tunnel
//			tunnel_0.type          : exact @name("tunnel_type");
//			tunnel_0.id            : exact @name("tunnel_id");
   lkp_0.tunnel_type : exact @name("tunnel_type");
   lkp_0.tunnel_id : exact @name("tunnel_id");
  }

  actions = {
   NoAction_;
   sap_hit;
  }

  const default_action = NoAction_;
  counters = stats;
  size = sap_table_size;
 }




 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {


  sap.apply();


 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuter(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,

 in switch_lookup_fields_t lkp_2,
 in switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
//	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;
/*
	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_exm.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			hdr_0.nsh_type1.sap : exact @name("sap");

			// l3
			lkp.ip_type         : exact @name("ip_type");
			lkp.ip_src_addr     : exact @name("ip_src_addr");
			lkp.ip_dst_addr     : exact @name("ip_dst_addr");

			// tunnel
			lkp.tunnel_type     : exact @name("tunnel_type");
			lkp.tunnel_id       : exact @name("tunnel_id");
		}

		actions = {
			NoAction_exm;
			sap_exm_hit;
		}

		const default_action = NoAction_exm;
		counters = stats_exm;
		size = sap_exm_table_size;
	}
*/
 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<12> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_tcam.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   hdr_0.nsh_type1.sap : ternary @name("sap");

   // l3
   lkp.ip_type : ternary @name("ip_type");
   lkp.ip_src_addr : ternary @name("ip_src_addr");
   lkp.ip_dst_addr : ternary @name("ip_dst_addr");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

//		if(!sap_exm.apply().hit) {
   sap_tcam.apply();
//		}

  if(terminate_ == true) {
   ig_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
    ig_md.tunnel_2.terminate = true;
   }
  }

  if(scope_ == true) {
   if(hdr_0.nsh_type1.scope == 0) {

    Scoper.apply(
     lkp_2,
     ig_md.drop_reason_2,

     ig_md.lkp_1
    );
# 706 "tunnel.p4"
   }

//			scope_inc.apply();
   hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
  }
 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Inner (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelInner(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,

 in switch_lookup_fields_t lkp_2,
 in switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;

 action NoAction_exm (
 ) {
  stats_exm.count();
 }

 action sap_exm_hit(
  bit<12> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_exm.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_exm {
  key = {
   hdr_0.nsh_type1.sap : exact @name("sap");

   // tunnel
   lkp.tunnel_type : exact @name("tunnel_type");
   lkp.tunnel_id : exact @name("tunnel_id");
  }

  actions = {
   NoAction_exm;
   sap_exm_hit;
  }

  const default_action = NoAction_exm;
  counters = stats_exm;
  size = sap_exm_table_size;
 }

 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<12> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_tcam.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   hdr_0.nsh_type1.sap : ternary @name("sap");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(!sap_exm.apply().hit) {
   sap_tcam.apply();
  }

  if(terminate_ == true) {
   ig_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
    ig_md.tunnel_2.terminate = true;
   }
  }

  if(scope_ == true) {
   if(hdr_0.nsh_type1.scope == 0) {

    Scoper.apply(
     lkp_2,
     ig_md.drop_reason_2,

     ig_md.lkp_1
    );
# 880 "tunnel.p4"
   }

//			scope_inc.apply();
   hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
  }
 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap / Encap Transport
//-----------------------------------------------------------------------------

control TunnelDecapTransportIngress(
 inout switch_header_transport_t hdr_0,
 // ----- current header data -----
//	inout switch_header_transport_t hdr_0,
 in switch_tunnel_metadata_t tunnel_0,
 // ----- next header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  if(tunnel_0.terminate) {
   // ----- l2 -----
//			// (none -- done in egress)
//			hdr_0.ethernet.setInvalid();
//			hdr_0.vlan_tag[0].setInvalid();

   // ----- l3 / l4 / tunnel -----
   // (none -- instead, we do this by simply not deparsing any transport l3 / 4 / tunnels)

   // ----- fix the next layer's l2, if we had an l3 tunnel -----

   if(!hdr_1.ethernet.isValid()) {
    // Pkt doesn't have an l2 header...add one.
    // TODO: Do we need to set da/sa?  If so, what to (perhaps copy it from the transport)?
//				hdr_1.ethernet.dst_addr = hdr_0.ethernet.dst_addr;
//				hdr_1.ethernet.src_addr = hdr_0.ethernet.src_addr;
    if(hdr_1.ipv4.isValid()) {
     hdr_1.ethernet.ether_type = 0x0800;
    } else {
     hdr_1.ethernet.ether_type = 0x86dd;
    }
   }
   hdr_1.ethernet.setValid(); // always set valid (it may already be valid)


/*
			if(tunnel_1.terminate && tunnel_2.terminate) {

				// get from inner-inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else if(tunnel_1.terminate) {

				// get from inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else {

				// get from outer
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			}
*/

  }
 }
}

//-----------------------------------------------------------------------------

control TunnelEncapTransportIngress(
 inout switch_header_transport_t hdr_0,
 // ----- current header data -----
//  inout switch_header_transport_t hdr_0,
 in switch_tunnel_metadata_t tunnel_0,
 // ----- next header data -----
 inout switch_header_outer_t hdr_1
) (
 switch_tunnel_mode_t mode
) {

 apply {
/*
		if(tunnel_0.encap) {
			// ----- l2 -----
			// add an ethernet header, for egress parser -- only need to set the etype (not the da/sa)....
			hdr_0.ethernet.setValid();
			hdr_0.ethernet.ether_type = ETHERTYPE_NSH;

			// ----- l3 / l4 / tunnel -----
			// (none -- done in egress)
		}
*/
 }

}

//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
 // ----- current header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {


  if(tunnel_1.terminate) {
   // ----- l2 -----

   // keep my l2 when mine is valid and the next layer's isn't -- except when the next layer is being terminated and the next-next layer's is
   if(hdr_1.ethernet.isValid() && !hdr_2.ethernet.isValid() && !(tunnel_2.terminate && hdr_3.ethernet.isValid())) {
    // keep l2
   } else {
    // remove l2
    hdr_1.ethernet.setInvalid();


    hdr_1.e_tag.setInvalid();


    hdr_1.vn_tag.setInvalid();


    hdr_1.vlan_tag[0].setInvalid(); // extreme added
    hdr_1.vlan_tag[1].setInvalid(); // extreme added
   }

   // ----- l3 -----
   hdr_1.ipv4.setInvalid();

   hdr_1.ipv6.setInvalid();


   // ----- l4 -----
   hdr_1.tcp.setInvalid();
   hdr_1.udp.setInvalid();
   hdr_1.sctp.setInvalid(); // extreme added

   // ----- tunnel -----

   hdr_1.vxlan.setInvalid();

   hdr_1.gre.setInvalid();
   hdr_1.gre_optional.setInvalid();

   hdr_1.nvgre.setInvalid();


   hdr_1.gtp_v1_base.setInvalid(); // extreme added
   hdr_1.gtp_v1_optional.setInvalid(); // extreme added


   // ----- fix outer ethertype, if we had an l3 tunnel -----


   // this is organized from highest priority to lowest priority
   if(tunnel_2.terminate) {

    // get from inner-inner
    if(hdr_1.vlan_tag[1].isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vlan_tag[1].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[1].ether_type = 0x86dd;
     }
    } else if(hdr_1.vlan_tag[0].isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vlan_tag[0].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[0].ether_type = 0x86dd;
     }

    } else if(hdr_1.vn_tag.isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vn_tag.ether_type = 0x0800;
     } else {
      hdr_1.vn_tag.ether_type = 0x86dd;
     }


    } else if(hdr_1.e_tag.isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.e_tag.ether_type = 0x0800;
     } else {
      hdr_1.e_tag.ether_type = 0x86dd;
     }

    } else {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.ethernet.ether_type = 0x0800;
     } else {
      hdr_1.ethernet.ether_type = 0x86dd;
     }
    }

   } else {

    // get from inner
    if(hdr_1.vlan_tag[1].isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vlan_tag[1].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[1].ether_type = 0x86dd;
     }
    } else if(hdr_1.vlan_tag[0].isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vlan_tag[0].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[0].ether_type = 0x86dd;
     }

    } else if(hdr_1.vn_tag.isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vn_tag.ether_type = 0x0800;
     } else {
      hdr_1.vn_tag.ether_type = 0x86dd;
     }


    } else if(hdr_1.e_tag.isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.e_tag.ether_type = 0x0800;
     } else {
      hdr_1.e_tag.ether_type = 0x86dd;
     }

    } else {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.ethernet.ether_type = 0x0800;
     } else {
      hdr_1.ethernet.ether_type = 0x86dd;
     }
    }

   }

  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
 // ----- previous header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- current header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(tunnel_2.terminate) {
   // ----- l2 -----

   // keep my l2 when mine is valid and the next layer's isn't
   if(hdr_2.ethernet.isValid() && !hdr_3.ethernet.isValid()) {
    // keep l2
   } else {
    // remove l2
    hdr_2.ethernet.setInvalid();
    hdr_2.vlan_tag[0].setInvalid(); // extreme added
   }

   // ----- l3 -----
   hdr_2.ipv4.setInvalid();

   hdr_2.ipv6.setInvalid();


   // ----- l4 -----
   hdr_2.tcp.setInvalid();
   hdr_2.udp.setInvalid();
   hdr_2.sctp.setInvalid(); // extreme added

   // ----- tunnel -----

   hdr_2.gre.setInvalid();


   hdr_2.gtp_v1_base.setInvalid(); // extreme added
   hdr_2.gtp_v1_optional.setInvalid(); // extreme added


   // ----- fix outer ethertype, if we had an l3 tunnel -----

   // this is organized from highest priority to lowest priority
   if(hdr_2.vlan_tag[0].isValid()) {
    if(hdr_3.ipv4.isValid()) {
     hdr_2.vlan_tag[0].ether_type = 0x0800;
    } else {
     hdr_2.vlan_tag[0].ether_type = 0x86dd;
    }
   } else {
    if(hdr_3.ipv4.isValid()) {
     hdr_2.ethernet.ether_type = 0x0800;
    } else {
     hdr_2.ethernet.ether_type = 0x86dd;
    }
   }
/*
  #if defined(FIX_L3_TUN_LYR_BY_LYR) && !defined(FIX_L3_TUN_ALL_AT_ONCE)
			// this is organized from highest priority to lowest priority
			if(hdr_1.vlan_tag[1].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
				}
			} else if(hdr_1.vlan_tag[0].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
				}
    #ifdef VNTAG_ENABLE
			} else if(hdr_1.vn_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
    #ifdef ETAG_ENABLE
			} else if(hdr_1.e_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
			} else {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
				}
			}
	#endif
*/
  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - L2 Ethertype Fix
//-----------------------------------------------------------------------------

control TunnelDecapFixEthertype(
 // ----- current header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
) {
 // -------------------------------------
 // Table
 // -------------------------------------

 action fix_l2_decap_hdr_1() {
  hdr_1.ethernet.setInvalid();


  hdr_1.e_tag.setInvalid();


  hdr_1.vn_tag.setInvalid();


  hdr_1.vlan_tag[0].setInvalid(); // extreme added
  hdr_1.vlan_tag[1].setInvalid(); // extreme added
 }

 action fix_l2_decap_hdr_2() {
  hdr_2.ethernet.setInvalid();
  hdr_2.vlan_tag[0].setInvalid(); // extreme added
 }
# 1470 "tunnel.p4"
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply{



 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
 inout bool terminate_a,
 inout bool terminate_b,
 inout switch_header_transport_t hdr_0
) {

 action new_scope(bit<8> scope_new) {
  hdr_0.nsh_type1.scope = scope_new;
//		terminate_a = false;
//		terminate_b = false;
 }

 table scope_dec {
  key = {
   hdr_0.nsh_type1.scope : exact;
   terminate_a : exact;
   terminate_b : exact;
  }
  actions = {
   NoAction;
   new_scope;
  }
  const entries = {
   // no decrement
   (0, false, false) : new_scope(0);
   (1, false, false) : new_scope(1);
   (2, false, false) : new_scope(2);
   (3, false, false) : new_scope(3);
   // decrement by one
   (0, true, false) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, true, false) : new_scope(0);
   (2, true, false) : new_scope(1);
   (3, true, false) : new_scope(2);
   // decrement by one (these should never occur)
   (0, false, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, false, true ) : new_scope(0);
   (2, false, true ) : new_scope(1);
   (3, false, true ) : new_scope(2);
   // decrement by two
   (0, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (2, true, true ) : new_scope(0);
   (3, true, true ) : new_scope(1);
  }
  const default_action = NoAction;
 }

 // -------------------------

 apply {
  scope_dec.apply();
 }
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

control TunnelRewrite(
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in switch_tunnel_metadata_t tunnel
) (
 switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
 switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,
 switch_uint32_t nexthop_rewrite_table_size=512,
 switch_uint32_t src_addr_rewrite_table_size=1024,
 switch_uint32_t smac_rewrite_table_size=1024
) {

 EgressBd(BD_TABLE_SIZE) egress_bd;
 switch_smac_index_t smac_index;

 // -------------------------------------
 // Table: Nexthop Rewrite (DMAC & BD)
 // -------------------------------------

 // Outer nexthop rewrite
 action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
  eg_md.bd = bd;
  hdr_0.ethernet.dst_addr = dmac;
 }

 table nexthop_rewrite {
  key = {
   eg_md.outer_nexthop : exact;
  }

  actions = {
   NoAction;
   rewrite_tunnel;
  }

  const default_action = NoAction;
  size = nexthop_rewrite_table_size;
 }

 // -------------------------------------
 // Table: SIP Rewrite
 // -------------------------------------

 // Tunnel source IP rewrite
 action rewrite_ipv4_src(ipv4_addr_t src_addr) {



 }

 action rewrite_ipv6_src(ipv6_addr_t src_addr) {



 }

 table src_addr_rewrite {
  key = { eg_md.bd : exact; }
  actions = {
   rewrite_ipv4_src;
   rewrite_ipv6_src;
  }

  size = src_addr_rewrite_table_size;
 }

 // -------------------------------------
 // Table: DIP Rewrite
 // -------------------------------------

 // Tunnel destination IP rewrite
# 1644 "tunnel.p4"
 // -------------------------------------
 // Table: SMAC Rewrite
 // -------------------------------------

 // Tunnel source MAC rewrite
 action rewrite_smac(mac_addr_t smac) {
  hdr_0.ethernet.src_addr = smac;
 }

 table smac_rewrite {
  key = { smac_index : exact; }
  actions = {
   NoAction;
   rewrite_smac;
  }

  const default_action = NoAction;
  size = smac_rewrite_table_size;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   nexthop_rewrite.apply();

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   egress_bd.apply(hdr_0, eg_md.bd, eg_md.pkt_src,
    smac_index);
# 1698 "tunnel.p4"
  smac_rewrite.apply();

 }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------

control TunnelEncap(
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 inout switch_tunnel_metadata_t tunnel_
) (
 switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
 switch_uint32_t vni_mapping_table_size=1024
) {

 bit<16> payload_len;
 bit<8> ip_proto;

 // -------------------------------------
/*
	action set_vni(switch_tunnel_id_t id) {
		tunnel_.id = id;
	}

	table bd_to_vni_mapping {
		key = { eg_md.bd : exact; }

		actions = {
			NoAction;
			set_vni;
		}

		size = vni_mapping_table_size;
	}
*/
 //=============================================================================
 // Copy L3/4 Outer -> Inner
 //=============================================================================

 action copy_ipv4_header() {




 }

 action copy_ipv6_header() {



 }

 // --------------------------------
 // --------------------------------

 action rewrite_inner_ipv4_udp() {
  payload_len = hdr_1.ipv4.total_len;
  copy_ipv4_header();
  ip_proto = 4;
 }

 action rewrite_inner_ipv4_unknown() {
  payload_len = hdr_1.ipv4.total_len;
  copy_ipv4_header();
  ip_proto = 4;
 }

 // --------------------------------
# 1793 "tunnel.p4"
 // --------------------------------

 table encap_outer {
  key = {
   hdr_1.ipv4.isValid() : exact;



   hdr_1.udp.isValid() : exact;
   // hdr_1.tcp.isValid() : exact;
  }

  actions = {
   rewrite_inner_ipv4_udp;
   rewrite_inner_ipv4_unknown;




  }

  const entries = {






   (true, false) : rewrite_inner_ipv4_unknown();
   (true, true ) : rewrite_inner_ipv4_udp();


  }
 }

 //=============================================================================
 // Copy L2 Outer -> Inner
 // Writes Tunnel header, rewrites some of Outer
 //=============================================================================

 //-----------------------------------------------------------------------------
 // Helper actions to add various headers.
 //-----------------------------------------------------------------------------

 // there is no UDP supported in the transport
 // action add_udp_header(bit<16> src_port, bit<16> dst_port) {
 //     hdr_0.udp.setValid();
 //     hdr_0.udp.src_port = src_port;
 //     hdr_0.udp.dst_port = dst_port;
 //     hdr_0.udp.checksum = 0;
 //     // hdr_0.udp.length = 0;
 // }

 // -------------------------------------
 // Extreme Networks - Modified
 // -------------------------------------

 action add_gre_header(bit<16> proto, bit<1> K, bit<1> S) {
# 1863 "tunnel.p4"
 }

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action add_gre_header_seq() {




 }

 action add_l2_header() {
  hdr_0.ethernet.setValid();
 }

 // -------------------------------------

 action add_erspan_header_type2(bit<10> session_id) {
# 1892 "tunnel.p4"
 }

 // action add_erspan_header(bit<32> timestamp, bit<10> session_id) {
 // 	hdr_0.erspan_type3.setValid();
 // 	hdr_0.erspan_type3.timestamp = timestamp;
 // 	hdr_0.erspan_type3.session_id = (bit<10>) session_id;
 // 	hdr_0.erspan_type3.version = 4w0x2;
 // 	hdr_0.erspan_type3.sgt = 0;
 // 	hdr_0.erspan_type3.vlan = 0;
 // }

 // -------------------------------------

 action add_ipv4_header(bit<8> proto) {
# 1925 "tunnel.p4"
 }

 action add_ipv6_header(bit<8> proto) {
# 1944 "tunnel.p4"
 }

 //-----------------------------------------------------------------------------
 // Actual actions.
 //-----------------------------------------------------------------------------

 // =====================================
 // ----- Rewrite, IPv4 Stuff -----
 // =====================================

 action rewrite_ipv4_gre() {
# 1973 "tunnel.p4"
 }

 action rewrite_ipv4_erspan() {
# 1992 "tunnel.p4"
 }

 // =====================================
 // ----- Rewrite, IPv6 Stuff -----
 // =====================================

 action rewrite_ipv6_gre() {
# 2018 "tunnel.p4"
 }
/*
	action rewrite_ipv6_erspan(switch_mirror_session_t session_id) {
		add_l2_header();
		// ----- l3 -----
//		hdr_0.inner_ethernet = hdr_0.ethernet;
		add_ipv6_header(IP_PROTOCOLS_GRE);
		// Payload length = packet length + 8
		//   GRE (4)
		hdr_0.ipv6.payload_len = payload_len + 16w30; // 8 GRE + 8 ERSPAN + 14 ETHERNET

		// ----- tunnel -----
		add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2(session_id);

		// ----- l2 -----
		hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
	}
*/
 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action rewrite_mac_in_mac() {
  add_l2_header();
  hdr_0.ethernet.ether_type = 0x894F;
 }

 // -------------------------------------

 table tunnel {
  key = {
   tunnel_.type : exact;
  }

  actions = {
   NoAction;

   rewrite_mac_in_mac; // extreme added
   rewrite_ipv4_gre; // extreme added
   rewrite_ipv6_gre; // extreme added
   rewrite_ipv4_erspan; // extreme added
//			rewrite_ipv6_erspan;  // extreme added
  }

  const default_action = NoAction;

  // ---------------------------------
  // Extreme Networks - Added
  // ---------------------------------
  /*
		// Note that this table should just be programmed with the
		// following constants, but the language doesn't seem to allow it....
		const entries = {
			(SWITCH_TUNNEL_TYPE_NSH)      = rewrite_mac_in_mac();  // extreme added
			(SWITCH_TUNNEL_TYPE_GRE)      = rewrite_ipv4_gre();    // extreme added
			(SWITCH_TUNNEL_TYPE_ERSPAN)   = rewrite_ipv4_erspan(); // extreme added
		}
		*/
  // ---------------------------------
 }

 //=============================================================================
 // Apply
 //=============================================================================

 apply {

  if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE && tunnel_.id == 0) {
//			bd_to_vni_mapping.apply(); // Derek: since tunnel.id is only used by vxlan, getting rid of this table (for now, anyway).
  }

  if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE) {
   // Copy L3/L4 header into inner headers.
   encap_outer.apply();

   // Add outer L3/L4/Tunnel headers.
   tunnel.apply();
  }

 }
}
# 53 "npb.p4" 2
# 1 "multicast.p4" 1



// =============================================================================
// =============================================================================
// =============================================================================

control MulticastReplication (
 inout switch_header_transport_t hdr_0,
 in switch_rid_t replication_id,
 in switch_port_t port,
 inout switch_egress_metadata_t eg_md
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1: 
 // =========================================================================


 action rid_hit_unique_copies(
  switch_bd_t bd,

  bit<24> spi,
  bit<8> si,

  switch_nexthop_t nexthop_index,
  switch_tunnel_index_t tunnel_index,
  switch_outer_nexthop_t outer_nexthop_index
 ) {
  eg_md.bd = bd;

  hdr_0.nsh_type1.spi = spi;
  hdr_0.nsh_type1.si = si;

  eg_md.nexthop = nexthop_index;
  eg_md.tunnel_0.index = tunnel_index;
  eg_md.outer_nexthop = outer_nexthop_index;
 }

 action rid_hit_identical_copies(
  switch_bd_t bd
 ) {
  eg_md.bd = bd;
 }

 action rid_miss() {
 }

 table rid {
  key = {
   replication_id : exact;
  }
  actions = {
   rid_miss;
   rid_hit_identical_copies;
   rid_hit_unique_copies;
  }

  size = table_size;
  const default_action = rid_miss;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Replication ID Lookup
  // =====================================


  if(replication_id != 0) {
   rid.apply();
  }

 }
}
# 54 "npb.p4" 2
# 1 "copp.p4" 1



control IngressCopp (
 in bool copp_enable,
 in switch_copp_meter_id_t copp_meter_id,

 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
) {
# 47 "copp.p4"
 //-------------------------------------------------------------

 apply {
# 58 "copp.p4"
 }

}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control EgressCopp (
 in bool copp_enable,
 in switch_copp_meter_id_t copp_meter_id,

 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
) {
# 110 "copp.p4"
 //-------------------------------------------------------------

 apply {
# 121 "copp.p4"
 }
}
# 55 "npb.p4" 2
# 1 "dtel.p4" 1
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
 ******************************************************************************/

// Data-plane telemetry (DTel).

//-----------------------------------------------------------------------------
// Deflect on drop configuration checks if deflect on drop is enabled for a given queue/port pair.
// DOD must be only enabled for unicast traffic.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control DeflectOnDrop(
        in switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size=1024) {

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
//          ig_md.qos.qid: ternary @name("qid"); // derek hack
            ig_md.multicast.id : ternary;
            ig_md.cpu_reason : ternary; // to avoid validity issues, replaces
                                         // ig_intr_md_for_tm.copy_to_cpu
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

    apply {
        config.apply();
    }
}

//-----------------------------------------------------------------------------
// Mirror on drop configuration
// Checks if mirror on drop is enabled for a given drop reason.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {
    action mirror() {
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    action mirror_and_set_d_bit() {
        dtel_md.report_type = dtel_md.report_type | SWITCH_DTEL_REPORT_TYPE_DROP;
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
            mirror_and_set_d_bit;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

    apply {
        config.apply();
    }
}


//-----------------------------------------------------------------------------
// Simple bloom filter for drop report suppression to avoid generating duplicate reports.
//
// @param hash : Hash value used to query the bloom filter.
// @param flag : A flag indicating that the report needs to be suppressed.
//-----------------------------------------------------------------------------
control DropReport(in switch_header_outer_t hdr,
                   in switch_egress_metadata_t eg_md,
                   in bit<32> hash, inout bit<2> flag) {
    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 0) array1;
    Register<bit<1>, bit<17>>(1 << 17, 0) array2;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[0:0] = filter1.execute(hash[16:0]);
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:15]);
    }
}

//-----------------------------------------------------------------------------
// Generates queue reports if hop latency (or queue depth) exceeds a configurable thresholds.
// Quota-based report suppression to avoid generating excessive amount of reports.
// @param port : Egress port
// @param qid : Queue Id.
// @param qdepth : Queue depth.
//-----------------------------------------------------------------------------
struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency; // Qunatized latency
}

// Quota policy -- The policy maintains counters to track the number of generated reports.

// @param flag : indicating whether to generate a telemetry report or not.
control QueueReport(inout switch_egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {
    // Quota for a (port, queue) pair.
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
//          if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_md.qos.qdepth) {
            if (reg.latency <= eg_md.dtel.latency) {
                flag = 1;
            }
        }
    };

    action set_qmask(bit<32> quantization_mask) {
        // Quantize the latency.
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }
    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }

    table queue_alert {
        key = {
//          eg_md.qos.qid : exact @name("qid"); // derek hack
            eg_md.port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }

            // Send a report if quantized latency is changed.
            if (reg.latency != eg_md.dtel.latency) {
                reg.latency = eg_md.dtel.latency;
                flag = 1;
            }
        }
    };

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };


    action reset_quota_(bit<16> index) {
        qalert = reset_quota.execute(index);
    }

    action update_quota_(bit<16> index) {
        qalert = update_quota.execute(index);
    }

    action check_latency_and_update_quota_(bit<16> index) {
        qalert = check_latency_and_update_quota.execute(index);
    }

    table check_quota {
        key = {
            eg_md.pkt_src : exact;
            qalert : exact;
//          eg_md.qos.qid : exact @name("qid"); // derek hack
            eg_md.port : exact @name("port");
        }

        actions = {
            NoAction;
            reset_quota_;
            update_quota_;
            check_latency_and_update_quota_;
        }

        const default_action = NoAction;
        size = 3 * queue_table_size;
    }

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}


control FlowReport(in switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<16>>(1 << 16, 0) array1;
    Register<bit<16>, bit<16>>(1 << 16, 0) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    apply {
# 351 "dtel.p4"
    }
}

control IngressDtel(in switch_header_outer_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   DTEL_MAX_MEMBERS_PER_GROUP,
                   DTEL_GROUP_TABLE_SIZE) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = { hash : selector; }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {
# 396 "dtel.p4"
    }
}


control DtelConfig(inout switch_header_outer_t hdr,
                   inout bit<32> hdr_transport_timestamp, // derek hack
                   inout switch_egress_metadata_t eg_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };

    action mirror_switch_local() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_switch_local_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }

    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_f_bit_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | (
            SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_drop() {
        // Generate telemetry drop report.
        eg_md.mirror.type = 3;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_drop_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }

    action mirror_clone() {
        // Generate (sampled) clone on behalf of downstream IFA capable devices
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.dtel.session_id = eg_md.dtel.clone_session_id;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.d_q_f = (bit<3>) report_type;
        hdr.dtel.reserved = 0;
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
//      hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.timestamp = (bit<32>) hdr_transport_timestamp; // derek hack
        hdr.dtel.switch_id = switch_id;
    }

    action update_and_mirror_truncate(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type) {
        update(switch_id, hw_id, next_proto, report_type);
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.d_q_f = (bit<3>) report_type;
        hdr.dtel.reserved[14:13] = etrap_status; // etrap indication
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
//      hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.timestamp = (bit<32>) hdr_transport_timestamp; // derek hack
        hdr.dtel.switch_id = switch_id;
    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.tos[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {

        hdr.ipv6.tos[7:2] = dscp;

    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[2:2] = dscp_bit_value;

    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[3:3] = dscp_bit_value;

    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[4:4] = dscp_bit_value;

    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[5:5] = dscp_bit_value;

    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[6:6] = dscp_bit_value;

    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[7:7] = dscp_bit_value;

    }

    /* config table is responsible for triggering the flow/queue report generation for normal
     * traffic and updating the dtel report headers for telemetry reports.
     *
     * pkt_src        report_type     drop_ flow_ queue drop_  drop_ action
     *                                flag  flag  _flag reason report
     *                                                         valid
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_INGRESS DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_INGRESS DROP            0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP            *     *     *     *      y     update(d)
     *
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dqf)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     1     *      *     update(dqf)
     * DEFLECTED      DROP | FLOW     *     *     1     *      *     update(dqf)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(df)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     *     *      *     drop
     * DEFLECTED      DROP | FLOW     *     *     *     *      *     update(df)
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dq)
     * DEFLECTED      DROP            0b11  *     1     *      *     update(dq)
     * DEFLECTED      DROP            *     *     1     *      *     update(dq)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(d)
     * DEFLECTED      DROP            0b11  *     *     *      *     drop
     * DEFLECTED      DROP            *     *     *     *      *     update(d)
     * DEFLECTED      *               *     *     0     *      *     drop
     * DEFLECTED      *               *     *     1     *      *     update(q)
     *
     * CLONED_EGRESS  FLOW | QUEUE    *     *     *     *      n     update(qf)
     * CLONED_EGRESS  QUEUE           *     *     *     *      n     update(q)
     * CLONED_EGRESS  FLOW            *     *     *     *      n     update(f)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_EGRESS  DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dq)
     *                | QUEUE
     * CLONED_EGRESS  DROP | QUEUE    0b11  *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | QUEUE    *     *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(d)
     *
     * BRIDGED        FLOW | SUPPRESS *     *     1     0      *     mirror_sw
     * BRIDGED        FLOW            *     0b00  1     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  1     0      *     mirror_sw_l
     * BRIDGED        *               *     *     1     0      *     mirror_sw_l
     * BRIDGED        FLOW | SUPPRESS *     *     *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b00  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     TCPfl *     0      *     mirror_sw_l
     *
     * BRIDGED        DROP            *     *     *     0      *     NoAction
     * User specified entries for egress drop_reason values: mirror or NoAction
     * BRIDGED        DROP            *     *     1     value  *     mirror_drop
     * BRIDGED        DROP            *     *     *     value  *     action
     * BRIDGED        *               *     *     1     value  *     mirror_sw_l
     * Drop report catch all entries
     * BRIDGED        DROP            *     *     1     *      *     mirror_drop
     * BRIDGED        DROP            *     *     *     *      *     mirror_drop
     * BRIDGED        *               *     *     1     *      *     mirror_sw_l
     *
     * *              *               *     *     *     *      *     NoAction
     * This table is asymmetric as hw_id is pipe specific.
     */

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            eg_md.dtel.drop_report_flag : ternary;
            eg_md.dtel.flow_report_flag : ternary;
            eg_md.dtel.queue_report_flag : ternary;
            eg_md.drop_reason : ternary;
            eg_md.mirror.type : ternary;
            hdr.dtel_drop_report.isValid() : ternary;
# 681 "dtel.p4"
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
# 718 "dtel.p4"
        }

        const default_action = NoAction;
    }

    apply {



    }
}

control IntEdge(inout switch_egress_metadata_t eg_md)(
                switch_uint32_t port_table_size=288) {

    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        eg_md.dtel.clone_session_id = session_id;
    }

    action set_ifa_edge() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }

    table port_lookup {
        key = {
            eg_md.port : exact;
        }
        actions = {
            NoAction;
            set_clone_mirror_session_id;
            set_ifa_edge;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            port_lookup.apply();
    }
}

control EgressDtel(inout switch_header_outer_t hdr,
                   inout bit<32> hdr_transport_timestamp, // derek hack
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;
    IntEdge() int_edge;

    action convert_ingress_port(switch_port_t port) {
        hdr.dtel_report.ingress_port = port;
    }

    table ingress_port_conversion {
        key = {
          hdr.dtel_report.ingress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact;
        }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

    action convert_egress_port(switch_port_t port) {
        hdr.dtel_report.egress_port = port;
    }

    table egress_port_conversion {
        key = {
          hdr.dtel_report.egress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact;
        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    apply {
# 835 "dtel.p4"
    }
}
# 56 "npb.p4" 2

# 1 "npb_ing_parser.p4" 1



parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum_transport;
    Checksum() ipv4_checksum_outer;
    Checksum() ipv4_checksum_inner;

    value_set<switch_cpu_port_value_set_t>(4) cpu_port;

    //value_set<bit<32>>(20) my_mac_lo;
    //value_set<bit<16>>(20) my_mac_hi;
    value_set<bit<32>>(8) my_mac_lo;
    value_set<bit<16>>(8) my_mac_hi;

 //bit<8>  protocol_outer;
 //bit<8>  protocol_inner;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
//      ig_md.timestamp      = ig_intr_md.ingress_mac_tstamp;



        hdr.transport.nsh_type1.timestamp = 0;

        ig_md.flags.rmac_hit = false;

        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_0.tunnel_id = 0;
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_1.tunnel_id = 0;
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_2.tunnel_id = 0;
# 73 "npb_ing_parser.p4"
        // initialize lookup struct to zeros
        ig_md.lkp_1.mac_src_addr = 0;
        ig_md.lkp_1.mac_dst_addr = 0;
        ig_md.lkp_1.mac_type = 0;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.pad = 0;
        ig_md.lkp_1.vid = 0;
        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_1.ip_proto = 0;
        //ig_md.lkp_1.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = 0;
        ig_md.lkp_1.ip_src_addr = 0;
        ig_md.lkp_1.ip_dst_addr = 0;
        ig_md.lkp_1.ip_len = 0;
        ig_md.lkp_1.tcp_flags = 0;
        ig_md.lkp_1.l4_src_port = 0;
        ig_md.lkp_1.l4_dst_port = 0;
        //ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE; // do this always (above)
        //ig_md.lkp_1.tunnel_id = 0;                         // do this always (above)
        ig_md.lkp_1.drop_reason = 0;




        // initialize lookup struct (2) to zeros
        ig_md.lkp_2.mac_src_addr = 0;
        ig_md.lkp_2.mac_dst_addr = 0;
        ig_md.lkp_2.mac_type = 0;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.pad = 0;
        ig_md.lkp_2.vid = 0;
        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_2.ip_proto = 0;
        //ig_md.lkp_2.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags = 0;
        ig_md.lkp_2.ip_src_addr = 0;
        ig_md.lkp_2.ip_dst_addr = 0;
        ig_md.lkp_2.ip_len = 0;
        ig_md.lkp_2.tcp_flags = 0;
        ig_md.lkp_2.l4_src_port = 0;
        ig_md.lkp_2.l4_dst_port = 0;
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE; // do this always (above)
        //ig_md.lkp_2.tunnel_id = 0;                         // do this always (above)
        ig_md.lkp_2.drop_reason = 0;


//      ig_md.inner_inner.ethernet_isValid = false;
//      ig_md.inner_inner.ipv4_isValid = false;
//      ig_md.inner_inner.ipv6_isValid = false;

        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Port Metadata
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
  ig_md.nsh_md.l2_fwd_en = (bool)port_md.l2_fwd_en;
        transition check_from_cpu;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // CPU Packet Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////



    state check_from_cpu {
        transition select(
            pkt.lookahead<ethernet_h>().ether_type,
            ig_intr_md.ingress_port) {

            cpu_port: check_my_mac_lo_cpu;
            default: check_my_mac_lo;
        }
    }
# 171 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // My-MAC Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    //  My   L2   MAU                   First   
    //  MAC  Fwd  Path                  Stack
    //  ----------------------------    ------------
    //  0    0    SFC Optical-Tap       Outer       
    //  0    1    Bridging              Outer       
    //  1    x    SFC Network-Tap       Transport   
    //            or SFC Bypass (nsh)   Transport

    state check_my_mac_lo {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi;
            default: parse_outer_ethernet; // Bridging path
        }
    }

    state check_my_mac_lo_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi_cpu;
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }

    state check_my_mac_hi {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet; // SFC Network-Tap / SFC Bypass Path
            default: parse_outer_ethernet; // Bridging path
        }
    }

    state check_my_mac_hi_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet_cpu; // SFC Network-Tap / SFC Bypass Path
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport (ETH-T)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_transport_ethernet {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);
# 236 "npb_ing_parser.p4"
        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;



        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.transport.ethernet.ether_type;


        transition select(hdr.transport.ethernet.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x88A8: parse_transport_vlan;

            0x0800: parse_transport_ipv4;

            default: parse_udf;
        }
    }

    // -------------------------------------------------------------------------
    state parse_transport_ethernet_cpu {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);




        pkt.extract(hdr.cpu);




        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
  ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;

  hdr.transport.ethernet.ether_type = hdr.cpu.ether_type; // done in port.p4 for now (see bf-case 10933)

// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE







// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;


// populate for L3-tunnel case (where there's no L2 present)        

        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.cpu.ether_type;


        transition select(hdr.cpu.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x88A8: parse_transport_vlan;

            0x0800: parse_transport_ipv4;

           default: parse_udf;
        }
    }


    // -------------------------------------------------------------------------
    state parse_transport_vlan {

     pkt.extract(hdr.transport.vlan_tag[0]);
# 332 "npb_ing_parser.p4"
// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_1.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_1.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_1.mac_type = hdr.transport.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.transport.vlan_tag[0].ether_type;


        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;

            0x0800: parse_transport_ipv4;

            default: parse_udf;
        }
    }




    ///////////////////////////////////////////////////////////////////////////
    // Layer3 - Transport
    ///////////////////////////////////////////////////////////////////////////

    state parse_transport_ipv4 {
     pkt.extract(hdr.transport.ipv4);

        ipv4_checksum_transport.add(hdr.transport.ipv4);
        ig_md.flags.ipv4_checksum_err_0 = ipv4_checksum_transport.verify();
# 383 "npb_ing_parser.p4"
        transition select(hdr.transport.ipv4.protocol) {
           47: parse_transport_gre;
           default : parse_udf;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Transport
    ///////////////////////////////////////////////////////////////////////////    

    //-------------------------------------------------------------------------
    // GRE - Transport
    //-------------------------------------------------------------------------

    state parse_transport_gre {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;

        transition select(
            hdr.transport.gre.C,
            hdr.transport.gre.R,
            hdr.transport.gre.K,
            hdr.transport.gre.S,
            hdr.transport.gre.s,
            hdr.transport.gre.recurse,
            hdr.transport.gre.flags,
            hdr.transport.gre.version,
            hdr.transport.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,0x0800): parse_outer_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_outer_ipv6;

            (0,0,0,1,0,0,0,0,0x88BE): parse_transport_erspan_t2;
          //(0,0,0,1,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_transport_erspan_t3;

            default: parse_udf;
        }
    }




    //-------------------------------------------------------------------------
    // ERSPAN - Transport
    //-------------------------------------------------------------------------



    state parse_transport_erspan_t2 {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = 0; // todo: should this be populated?
        transition parse_outer_ethernet;
    }

    // state parse_transport_erspan_t3 {
    //     pkt.extract(hdr.transport.gre_sequence);
    //     pkt.extract(hdr.transport.erspan_type3);
    //     ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
    //     transition select(hdr.transport.erspan_type3.o) {
    //         1: parse_erspan_type3_platform;
    //         default: parse_inner_ethernet;
    //     }
    // }
    // 
    // state parse_transport_erspan_type3_platform {
    //     pkt.extract(hdr.transport.erspan_platform);
    //     transition parse_outer_ethernet;
    // }




    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);
        transition select(hdr.transport.nsh_type1.next_proto) {
            0x3: parse_outer_ethernet;
            default: parse_udf; // todo: support ipv4? ipv6?
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);


        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.outer.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br;


            0x8926 : parse_outer_vn;


            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0806 : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_ethernet_cpu {
        pkt.extract(hdr.outer.ethernet);



        pkt.extract(hdr.cpu);

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
  ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;

  hdr.outer.ethernet.ether_type = hdr.cpu.ether_type; // done in port.p4 for now (see bf-case 10933)

// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE


        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.cpu.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.cpu.ether_type) {


            0x893F : parse_outer_br;


            0x8926 : parse_outer_vn;


            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0806 : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_br {
     pkt.extract(hdr.outer.e_tag);


        ig_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_2.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag


        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }



    state parse_outer_vn {
     pkt.extract(hdr.outer.vn_tag);


        ig_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.vn_tag.ether_type;


        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }



    state parse_outer_vlan_0 {

     pkt.extract(hdr.outer.vlan_tag[0]);






        ig_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

        ig_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.pcp = hdr.outer.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.outer.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[0].ether_type;


        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1;
            0x88A8 : parse_outer_vlan_1;



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_vlan_1 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[1].ether_type;


        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_arp {
        // pkt.extract(hdr.outer.arp);
        // transition accept;
        transition parse_udf;

    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

//     state parse_outer_ipv4 {
//         pkt.extract(hdr.outer.ipv4);
//         protocol_outer = hdr.outer.ipv4.protocol;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
//         ig_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_outer.add(hdr.outer.ipv4);
//         transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
//             (5, 0): parse_outer_ipv4_no_options_frags;
//             default : parse_udf;
//         }
//     }
// 
//     state parse_outer_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
//         transition select(hdr.outer.ipv4.protocol) {
//             IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
//             IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
//     }

//     state parse_outer_ipv4 {
//         pkt.extract(hdr.outer.ipv4);
// #ifdef INGRESS_PARSER_POPULATES_LKP_1
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
//         ig_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_outer.add(hdr.outer.ipv4);
//         transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
//             (5, 0): parse_outer_ipv4_no_options_frags;
//             default : parse_udf;
//         }
//     }
// 
//     state parse_outer_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
//         transition select(hdr.outer.ipv4.protocol) {
//             IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
//             IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
//             IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
//             IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
//             IP_PROTOCOLS_UDP: parse_outer_udp;
//             IP_PROTOCOLS_TCP: parse_outer_tcp;
//             IP_PROTOCOLS_SCTP: parse_outer_sctp;
//             IP_PROTOCOLS_GRE: parse_outer_gre;
//             //IP_PROTOCOLS_AUTH: parse_outer_auth_fixed;
//             IP_PROTOCOLS_ESP: parse_outer_esp_overload;
//             default: parse_udf;
//         }
//     }


    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);

        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        ig_md.lkp_1.ip_src_addr = (bit<128>)hdr.outer.ipv4.src_addr;
        ig_md.lkp_1.ip_dst_addr = (bit<128>)hdr.outer.ipv4.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;

        ipv4_checksum_outer.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl) {
            0x5 : parse_outer_ipv4_no_options;
#ifdef CASE_FIX                       
              6 : parse_outer_ipv4_options_1;
              7 : parse_outer_ipv4_options_2;
              8 : parse_outer_ipv4_options_3;
              9 : parse_outer_ipv4_options_4;
             10 : parse_outer_ipv4_options_5;
             11 : parse_outer_ipv4_options_6;
             12 : parse_outer_ipv4_options_7;
             13 : parse_outer_ipv4_options_8;
             14 : parse_outer_ipv4_options_9;
             15 : parse_outer_ipv4_options_10;
#else
            0x6 &&& 0xE : parse_outer_ipv4_options; /* 6..7 */
            0x8 &&& 0x8 : parse_outer_ipv4_options; /* 8..15 */
#endif                        
            default: reject; /* 0..4 */
        }
    }
                
#ifdef CASE_FIX
    state parse_outer_ipv4_options_1 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_2 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_3 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_4 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_5 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_6 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        pkt.extract(hdr.outer.ipv4_options[5]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_7 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        pkt.extract(hdr.outer.ipv4_options[5]);
        pkt.extract(hdr.outer.ipv4_options[6]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_8 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        pkt.extract(hdr.outer.ipv4_options[5]);
        pkt.extract(hdr.outer.ipv4_options[6]);
        pkt.extract(hdr.outer.ipv4_options[7]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_9 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        pkt.extract(hdr.outer.ipv4_options[5]);
        pkt.extract(hdr.outer.ipv4_options[6]);
        pkt.extract(hdr.outer.ipv4_options[7]);
        pkt.extract(hdr.outer.ipv4_options[8]);
        transition parse_outer_ipv4_no_options;
    }

    state parse_outer_ipv4_options_10 {
        pkt.extract(hdr.outer.ipv4_options[0]);
        pkt.extract(hdr.outer.ipv4_options[1]);
        pkt.extract(hdr.outer.ipv4_options[2]);
        pkt.extract(hdr.outer.ipv4_options[3]);
        pkt.extract(hdr.outer.ipv4_options[4]);
        pkt.extract(hdr.outer.ipv4_options[5]);
        pkt.extract(hdr.outer.ipv4_options[6]);
        pkt.extract(hdr.outer.ipv4_options[7]);
        pkt.extract(hdr.outer.ipv4_options[8]);
        pkt.extract(hdr.outer.ipv4_options[9]);
        transition parse_outer_ipv4_no_options;
    }

#else
    state parse_outer_ipv4_options {
        pkt.extract(hdr.outer.ipv4_options,
            ((bit<32>)hdr.outer.ipv4.ihl - 32w5) * 32);
        transition parse_outer_ipv4_no_options;
    }
#endif
    state parse_outer_ipv4_no_options {
        transition select(hdr.outer.ipv4.frag_offset, hdr.outer.ipv4.protocol) {
            (0, 1): parse_outer_icmp_igmp_overload;
            (0, 2): parse_outer_icmp_igmp_overload;
            (0, 4): parse_outer_ipinip_set_tunnel_type;
            (0, 41): parse_outer_ipv6inip_set_tunnel_type;
            (0, 17): parse_outer_udp;
            (0, 6): parse_outer_tcp;
            (0, 0x84): parse_outer_sctp;
            (0, 47): parse_outer_gre;
            //(0, IP_PROTOCOLS_AUTH): parse_outer_auth_fixed;
            (0, 0x32): parse_outer_esp_overload;
            default: parse_udf;
        }
    }




//     state parse_outer_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.outer.ipv6);
//         protocol_outer = hdr.outer.ipv6.next_hdr;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1        
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         transition select(hdr.outer.ipv6.next_hdr) {
//             IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }


    state parse_outer_ipv6 {

        pkt.extract(hdr.outer.ipv6);

        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;

        transition select(hdr.outer.ipv6.next_hdr) {
            58: parse_outer_icmp_igmp_overload;
            4: parse_outer_ipinip_set_tunnel_type;
            41: parse_outer_ipv6inip_set_tunnel_type;
            17: parse_outer_udp;
            6: parse_outer_tcp;
            0x84: parse_outer_sctp;
            47: parse_outer_gre;
            //IP_PROTOCOLS_AUTH: parse_outer_auth_fixed;
            0x32: parse_outer_esp_overload;
            default: parse_udf;
        }



    }


    // // shared fanout/branch state to save tcam resource
    // state branch_outer_l3_protocol {
    //     transition select(protocol_outer) {
    //         IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
    //         IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
    //         IP_PROTOCOLS_UDP: parse_outer_udp;
    //         IP_PROTOCOLS_TCP: parse_outer_tcp;
    //         IP_PROTOCOLS_SCTP: parse_outer_sctp;
    //         IP_PROTOCOLS_GRE: parse_outer_gre;
    //         IP_PROTOCOLS_AUTH: parse_outer_auth_fixed;
    //         IP_PROTOCOLS_ESP: parse_outer_esp_overload;
    //         default: parse_udf;
    //    }
    // }


    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_outer_icmp_igmp_overload {

         ig_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);


        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan;



            (_, 2123): parse_outer_gtp_c;
            (2123, _): parse_outer_gtp_c;
            (_, 2152): parse_outer_gtp_u;
            (2152, _): parse_outer_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u;            

            default : parse_udf;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);

        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition parse_udf;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);

        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
# 999 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------



    state parse_outer_vxlan {
        pkt.extract(hdr.outer.vxlan);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;
        transition parse_inner_ethernet;
    }




    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
        transition parse_inner_ipv4;



    }

    state parse_outer_ipv6inip_set_tunnel_type {

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
        transition parse_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre {
        pkt.extract(hdr.outer.gre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_1.tunnel_id = 0;

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.R,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.s,
            hdr.outer.gre.recurse,
            hdr.outer.gre.flags,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {

          // C R K S s r f v

            (0,0,1,0,0,0,0,0,0x6558): parse_outer_nvgre;

            (0,0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;



            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional;
            default: parse_udf;
        }
    }

    state parse_outer_gre_optional {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;



            default: parse_udf;
        }
    }



    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
     pkt.extract(hdr.outer.nvgre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;
        ig_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; // from switch

        transition parse_inner_ethernet;
    }



    // //-------------------------------------------------------------------------
    // // Authentication Header (AH) - Outer
    // //-------------------------------------------------------------------------
    // 
    // state parse_outer_auth_fixed {
    // 	pkt.extract(hdr.outer.auth_fixed);
    //     transition parse_outer_auth_variable;
    // }
    // 
    // state parse_outer_auth_variable {
    //     //pkt.extract(hdr.outer.auth_variable,
    //     //   (bit<32>)  hdr.outer.auth_fixed.payload_len - 32w1) * 32);
    // 
    //     pkt.extract(hdr.outer.auth_variable,
    //     (bit<32>)(((bit<16>)hdr.outer.auth_fixed.payload_len - 1) * 32));
    // 
    //     //pkt.advance(((bit<32>)hdr.outer.auth_fixed.payload_len - 32w1) * 32);
    // 
    //     transition select(hdr.outer.auth_fixed.next_header) {
    //         IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
    //         IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
    //         IP_PROTOCOLS_UDP: parse_outer_udp;
    //         IP_PROTOCOLS_TCP: parse_outer_tcp;
    //         IP_PROTOCOLS_SCTP: parse_outer_sctp;
    //         IP_PROTOCOLS_GRE: parse_outer_gre;
    //         IP_PROTOCOLS_ESP: parse_outer_esp_overload;
    //         default: parse_udf;    
    //     }
    // }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_esp_overload {

         ig_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
         ig_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;

        transition parse_udf;
    }

    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF

    state parse_outer_gtp_c {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_c {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
     transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u;
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_u {
        pkt.extract(hdr.outer.gtp_v1_base);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_u_with_optional {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4;
            (0, 6): parse_inner_ipv6;
            default: parse_udf;
        }
    }




    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner.ethernet);


        ig_md.lkp_2.mac_src_addr = hdr.inner.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.inner.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.inner.ethernet.ether_type) {
            0x0806: parse_inner_arp;
            0x8100: parse_inner_vlan;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : parse_udf;
        }
    }

    state parse_inner_vlan {

        pkt.extract(hdr.inner.vlan_tag[0]);






        ig_md.lkp_2.pcp = hdr.inner.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.inner.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.inner.vlan_tag[0].ether_type;


        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0806: parse_inner_arp;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : parse_udf;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_arp {
        // pkt.extract(hdr.inner.arp);
        // transition accept;
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

//     state parse_inner_ipv4 {
//         pkt.extract(hdr.inner.ipv4);
//         protocol_inner = hdr.inner.ipv4.protocol;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
// 
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;
// 
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
//         //ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
//         ig_md.lkp_2.ip_src_addr   = (bit<128>)hdr.inner.ipv4.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = (bit<128>)hdr.inner.ipv4.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
//         
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_inner.add(hdr.inner.ipv4);
//         transition select(
//             hdr.inner.ipv4.ihl,
//             hdr.inner.ipv4.frag_offset) {
//             (5, 0): parse_inner_ipv4_no_options_frags;
//             default: parse_udf;
//         }
//     }
// 
//     state parse_inner_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
//         transition select(hdr.inner.ipv4.protocol) {
//             IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
//             IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
//     }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);


        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?

        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type = 0x0800;

        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_2.ip_proto = hdr.inner.ipv4.protocol;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags = hdr.inner.ipv4.flags;
        ig_md.lkp_2.ip_src_addr = (bit<128>)hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr = (bit<128>)hdr.inner.ipv4.dst_addr;
        ig_md.lkp_2.ip_len = hdr.inner.ipv4.total_len;


        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum_inner.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset) {
            (5, 0): parse_inner_ipv4_no_options_frags;
            default: parse_udf;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.protocol) {
            1: parse_inner_icmp_igmp_overload;
            2: parse_inner_icmp_igmp_overload;
            17: parse_inner_udp;
            6: parse_inner_tcp;
            0x84: parse_inner_sctp;

            47: parse_inner_gre;

            0x32: parse_inner_esp_overload;
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }
    }


//     state parse_inner_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.inner.ipv6);
//         protocol_inner = hdr.inner.ipv6.next_hdr;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
//         
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
//         //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
// 
//         transition select(hdr.inner.ipv6.next_hdr) {
//             IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner.ipv6);


        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type = 0x86dd;

        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_2.ip_proto = hdr.inner.ipv6.next_hdr;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_src_addr = hdr.inner.ipv6.src_addr;
        ig_md.lkp_2.ip_dst_addr = hdr.inner.ipv6.dst_addr;
        ig_md.lkp_2.ip_len = hdr.inner.ipv6.payload_len;


        transition select(hdr.inner.ipv6.next_hdr) {
            58: parse_inner_icmp_igmp_overload;
            17: parse_inner_udp;
            6: parse_inner_tcp;
            0x84: parse_inner_sctp;

            47: parse_inner_gre;

            0x32: parse_inner_esp_overload;
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }



    }


//     // shared fanout/branch state to save tcam resource
//     state branch_inner_l3_protocol {
//         transition select(protocol_inner) {
//             IP_PROTOCOLS_UDP: parse_inner_udp;
//             IP_PROTOCOLS_TCP: parse_inner_tcp;
//             IP_PROTOCOLS_SCTP: parse_inner_sctp;
// #ifdef INNER_GRE_ENABLE
//             IP_PROTOCOLS_GRE: parse_inner_gre;
// #endif // INNER_GRE_ENABLE
//             IP_PROTOCOLS_ESP: parse_inner_esp_overload;
//             IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
//             IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
//             default : parse_udf;
//        }
//     }    

    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.     
    state parse_inner_icmp_igmp_overload {

        ig_md.lkp_2.l4_src_port = pkt.lookahead<bit<16>>();

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);

        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port;

        transition select(hdr.inner.udp.src_port, hdr.inner.udp.dst_port) {

            (_, 2123): parse_inner_gtp_c;
            (2123, _): parse_inner_gtp_c;
            (_, 2152): parse_inner_gtp_u;
            (2152, _): parse_inner_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u;            

            default: parse_udf;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);

        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags = hdr.inner.tcp.flags;

        transition parse_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);

        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type {

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_type {

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_esp_overload {

         ig_md.lkp_2.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
         ig_md.lkp_2.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;

        transition parse_udf;
    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre {
        pkt.extract(hdr.inner.gre);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.R,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.s,
            hdr.inner.gre.recurse,
            hdr.inner.gre.flags,
            hdr.inner.gre.version,
            hdr.inner.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF

    state parse_inner_gtp_c {
        //gtp_v2_base_h snoop_inner_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        //transition select(
        //    snoop_inner_gtp_v2_base.version,
        //    snoop_inner_gtp_v2_base.T) {

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_c {
        //pkt.extract(hdr.inner.gtp_v2_base);
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        //ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v2_base.teid;

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_u {
        pkt.extract(hdr.inner.gtp_v1_base);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_u_with_optional {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
  hdr.inner_inner.ipv4.setValid();
//      ig_md.inner_inner.ipv4_isValid = true;
  transition parse_udf;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();
//      ig_md.inner_inner.ipv6_isValid = true;
  transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_udf {

        //ig_md.parse_udf_reached = 1;
        pkt.extract(hdr.udf);

        transition accept;
    }

}
# 58 "npb.p4" 2
# 1 "npb_ing_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
        in switch_header_t hdr, // src
        inout switch_ingress_metadata_t ig_md // dst
) {

    // -----------------------------
 // Apply
    // -----------------------------

    apply {

        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if (hdr.outer.ipv4.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.outer.ipv6.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;

        if (hdr.inner.ipv4.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.inner.ipv6.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;

  // -----------------------------------------------------------------------

  // ipv6: would like to do this stuff in the parser, but can't because tos
  // field isn't byte aligned...

  // ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"


  if(hdr.outer.ipv6.isValid()) {
   ig_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
  }

  if(hdr.outer.ipv4.isValid()) {
   ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
  }



  if(hdr.inner.ipv6.isValid()) {
   ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
  }

  if(hdr.inner.ipv4.isValid()) {
   ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
  }


    }
}
# 59 "npb.p4" 2
# 1 "npb_ing_top.p4" 1
# 1 "npb_ing_sfc_top.p4" 1
# 1 "tunnel.p4" 1
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
 ******************************************************************************/
# 2 "npb_ing_sfc_top.p4" 2





control npb_ing_sfc_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {


 IngressTunnel(
  IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
  IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
 ) tunnel_transport;


 IngressTunnelNetwork(NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH) tunnel_network;




 IngressTunnelOuter(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH) tunnel_outer;

 IngressTunnelInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy

 // =========================================================================
 // W/O NSH... Table #0: FlowType Classifier / SFC Classifier
 // =========================================================================
/*
#ifdef TRANSPORT_ENABLE
  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE

	action tunnel_transport_sap_hit (
		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn
	) {
		hdr_0.nsh_type1.sap     = (16)sap;
		hdr_0.nsh_type1.vpn     = (16)vpn;
	}

	// ---------------------------------

	table tunnel_transport_sap {
		key = {
			hdr_0.nsh_type1.sap    : exact @name("sap");
			tunnel_0.type          : exact @name("tunnel_type");
			tunnel_0.id            : exact @name("tunnel_id");
		}

		actions = {
			NoAction;
			tunnel_transport_sap_hit;
		}

		size = NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH;
	}
  #endif
#endif
*/
 // =========================================================================
 // W/  NSH... Table #0:
 // =========================================================================

 action ing_sfc_sf_sel_hit(
  bit<8> si_predec

 ) {
  ig_md.nsh_md.si_predec = si_predec;

 }

 // ---------------------------------

 action ing_sfc_sf_sel_miss(
 ) {
//		ig_md.nsh_md.si_predec  = 0;
  ig_md.nsh_md.si_predec = hdr_0.nsh_type1.si;
 }

 // ---------------------------------

 table ing_sfc_sf_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   ing_sfc_sf_sel_hit;
   ing_sfc_sf_sel_miss;
  }

  const default_action = ing_sfc_sf_sel_miss;
  size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ---------------------------------------------------------------------
  // Classify
  // ---------------------------------------------------------------------

  // -----------------------------------------------------------------------------------------------------
  // | transport  | trasnport |
  // | nsh valid  | eth valid | result
  // +------------+-----------+----------------
  // | 1          | x         | internal  fabric -> sfc no tables...instead grab fields from nsh header
  // | 0          | 1         | normally  tapped -> sfc transport table, sap mapping table, inner table
  // | 0          | 0         | optically tapped -> sfc outer     table,                    inner table
  // -----------------------------------------------------------------------------------------------------

  if(hdr_0.nsh_type1.isValid()) {

   // -----------------------------------------------------------------
   // Packet already has  a NSH header on it (is already classified) --> just copy it to internal NSH structure
   // -----------------------------------------------------------------

   // metadata
   ig_md.nsh_md.start_of_path = false;
   ig_md.nsh_md.sfc_enable = false;

   // -----------------------------------------------------------------

   ing_sfc_sf_sel.apply();

  } else {

   // -----------------------------------------------------------------
   // Packet doesn't have a NSH header on it (needs classification) --> try to classify / populate internal NSH structure
   // -----------------------------------------------------------------

   // ----- metadata -----
   ig_md.nsh_md.start_of_path = true; // * see design note below
   ig_md.nsh_md.sfc_enable = false; // * see design note below

   // ----- header -----
   hdr_0.nsh_type1.setValid();

   // base: word 0
   hdr_0.nsh_type1.next_proto = 0x3;
   // (nothing to do, will be done in egress)

   // base: word 1
//			hdr_0.nsh_type1.spi                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.si                           = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE

   // ext: type 1 - word 1-3
   hdr_0.nsh_type1.scope = 0;
//			hdr_0.nsh_type1.sap                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.vpn                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
   hdr_0.nsh_type1.sfc_data = 0;



//			hdr_0.nsh_type1.timestamp                    = 0;                     // FOR SIMS


   // * design note: we have to ensure that all sfc tables have hits, otherwise
   // we can end up with a partially classified packet -- which would be bad.
   // one "cheap" (resource-wise) way of doing this is to initially set all
   // the control signals valid, and then have any table that misses clear them....

   // -----------------------------------------------------------------

//			if(ig_md.flags.rmac_hit == true) { // note: hit is forced "false" if there is no transport present
   if(hdr_0.ethernet.isValid()) {

    // ---------------------------
    // ----- normally tapped -----
    // ---------------------------

    bool hit;


    tunnel_transport.apply(ig_md, ig_md.flags.ipv4_checksum_err_0, hdr_0, ig_md.lkp_0, tunnel_0, ig_intr_md_for_dprsr, hit);


//				if(hit) {
//					tunnel_transport_sap.apply();
     tunnel_network.apply(ig_md, ig_md.lkp_0, hdr_0, tunnel_0);
//				}


   } else {

    // ----------------------------
    // ----- optically tapped -----
    // ----------------------------

    // -----------------------
    // Tunnel - Outer
    // -----------------------


    tunnel_outer.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);

   }

   // -----------------------
   // Tunnel - Inner
   // -----------------------

   tunnel_inner.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);

  }

  // always terminate transport headers
  tunnel_0.terminate = true;

 }
}
# 2 "npb_ing_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_top.p4" 1
//#include "npb_ing_sf_npb_basic_adv_acl.p4"
# 1 "npb_ing_sf_npb_basic_adv_sfp_sel.p4" 1

control npb_ing_sf_npb_basic_adv_sfp_hash (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in bit<16> mac_type,
 in bit<8> ip_proto,
 in bit<16> l4_src_port,
 in bit<16> l4_dst_port,
 out bit<16> hash
) {
 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1 (main lkp struct):
 // =========================================================================

 bit<10> flow_class_internal = 0;

 action ing_flow_class_hit (
  bit<10> flow_class
 ) {
  // ----- change nsh -----

  // change metadata
  flow_class_internal = flow_class;
 }

 // ---------------------------------

 table ing_flow_class {
  key = {
   hdr_0.nsh_type1.vpn : ternary @name("vpn");
   mac_type : ternary @name("mac_type");
   ip_proto : ternary @name("ip_proto");
   l4_src_port : ternary @name("l4_src_port");
   l4_dst_port : ternary @name("l4_dst_port");
  }

  actions = {
   NoAction;
   ing_flow_class_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_FLW_CLS_TABLE_DEPTH;
 }

 // =========================================================================
 // Hash #1 (main lkp struct):
 // =========================================================================

//	Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_func;
//	Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;
 Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;

 action compute_hash(
 ) {
  hash = hash_func.get({
   hdr_0.nsh_type1.vpn,
   flow_class_internal
  });
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  ing_flow_class.apply();
  compute_hash();
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_sfp_sel (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Table #1: Action Selector
 // =========================================================================
# 116 "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
 // Use an Action Selector with the table...
    Hash<bit<16>>(
  HashAlgorithm_t.IDENTITY
 ) selector_hash;
/*
    Hash<switch_uint16_t>(
		HashAlgorithm_t.IDENTITY
	) selector_hash;
*/
/*
	Hash<bit<16>>(
		HashAlgorithm_t.CRC16
	) selector_hash;
*/
/*
	Hash<bit<32>>(
		HashAlgorithm_t.CRC32
	) selector_hash;
*/
 ActionProfile(NPB_ING_SFF_SCHD_SELECTOR_TABLE_SIZE) schd_action_profile;
    ActionSelector(
  schd_action_profile,
  selector_hash,
//		SelectorMode_t.FAIR,
  SelectorMode_t.RESILIENT,
  NPB_ING_SFF_SCHD_MAX_MEMBERS_PER_GROUP,
  NPB_ING_SFF_SCHD_GROUP_TABLE_SIZE
 ) schd_selector;





 // ---------------------------------

 action ing_schd_hit (
  bit<24> spi,
  bit<8> si,

  bit<8> si_predec
 ) {
  hdr_0.nsh_type1.spi = spi;
  hdr_0.nsh_type1.si = si;

  // change metadata
  ig_md.nsh_md.si_predec = si_predec;
 }

 // ---------------------------------

 table ing_schd {
  key = {
   ig_md.nsh_md.sfc : exact @name("sfc");

//			hdr_0.nsh_type1.vpn       : selector;
//			flow_class_internal       : selector;
   ig_md.nsh_md.hash_1 : selector;

  }

  actions = {
   NoAction;
   ing_schd_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_SCHD_TABLE_SIZE;

  implementation = schd_selector;

 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  if(ig_md.nsh_md.sfc_enable == true) {
   ing_schd.apply();
  }
 }

}
# 3 "npb_ing_sf_npb_basic_adv_top.p4" 2




control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
    inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 IngressAcl(
  INGRESS_IPV4_ACL_TABLE_SIZE,


  INGRESS_IPV6_ACL_TABLE_SIZE,

  INGRESS_MAC_ACL_TABLE_SIZE,
  INGRESS_L7_ACL_TABLE_SIZE
 ) acl;

 // temporary internal variables
//	bit<2>  action_bitmask_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: policy
 //   [1:1] act #2: unused (was dedup)

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 bit<8> int_ctrl_flags = 0;

 action ing_sf_action_sel_hit(
//		bit<2>  action_bitmask,



//      bit<3>  discard
 ) {
//		action_bitmask_internal = action_bitmask;




//      ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
//		action_bitmask_internal = 0;
//		int_ctrl_flags = 0;
 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   NoAction;
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #2: IP Length Range
 // =========================================================================

 bit<16> ip_len = 0;
 bool ip_len_is_rng_bitmask = false;


 action ing_sf_ip_len_rng_hit(
  bit<16> rng_bitmask
 ) {
  ip_len = rng_bitmask;
  ip_len_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_ip_len_rng_miss(
 ) {
  ip_len = ig_md.lkp_1.ip_len;
  ip_len_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_ip_len_rng {
  key = {
   ig_md.lkp_1.ip_len : range @name("ip_len");
  }

  actions = {
   NoAction;
   ing_sf_ip_len_rng_hit;
   ing_sf_ip_len_rng_miss;
  }

  const default_action = ing_sf_ip_len_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Src Port Range
 // =========================================================================

 bit<16> l4_src_port = 0;
 bool l4_src_port_is_rng_bitmask = false;


 action ing_sf_l4_src_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_src_port = rng_bitmask;
  l4_src_port_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_l4_src_port_rng_miss(
 ) {
  l4_src_port = ig_md.lkp_1.l4_src_port;
  l4_src_port_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_l4_src_port_rng {
  key = {
   ig_md.lkp_1.l4_src_port : range @name("l4_src_port");
  }

  actions = {
   NoAction;
   ing_sf_l4_src_port_rng_hit;
   ing_sf_l4_src_port_rng_miss;
  }

  const default_action = ing_sf_l4_src_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Dst Port Range
 // =========================================================================

 bit<16> l4_dst_port = 0;
 bool l4_dst_port_is_rng_bitmask = false;


 action ing_sf_l4_dst_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_dst_port = rng_bitmask;
  l4_dst_port_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_l4_dst_port_rng_miss(
 ) {
  l4_dst_port = ig_md.lkp_1.l4_dst_port;
  l4_dst_port_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_l4_dst_port_rng {
  key = {
   ig_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
   NoAction;
   ing_sf_l4_dst_port_rng_hit;
   ing_sf_l4_dst_port_rng_miss;
  }

  const default_action = ing_sf_l4_dst_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
   ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - 1; // decrement sp_index





   // =====================================
   // Action(s)
   // =====================================

//			if(action_bitmask_internal[0:0] == 1) {

    // -------------------------------------
    // Action #0 - Policy
    // -------------------------------------


    ing_sf_ip_len_rng.apply();





    ing_sf_l4_src_port_rng.apply();





    ing_sf_l4_dst_port_rng.apply();





    acl.apply(
     ig_md.lkp_1,
     ig_md,
     ig_intr_md_for_dprsr,
     ig_intr_md_for_tm,
     ip_len,
     ip_len_is_rng_bitmask,
     l4_src_port,
     l4_src_port_is_rng_bitmask,
     l4_dst_port,
     l4_dst_port_is_rng_bitmask,
     hdr_0,
     hdr_1,
     hdr_2,
     hdr_udf,
     int_ctrl_flags
    );
//			}

//			if(action_bitmask_internal[1:1] == 1) {

    // -------------------------------------
    // Action #1 - Deduplication
    // -------------------------------------
# 309 "npb_ing_sf_npb_basic_adv_top.p4"
//			}

  }
/*
		npb_ing_sf_npb_basic_adv_sfp_sel.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm
		);
*/
 }
}
# 3 "npb_ing_top.p4" 2
//#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
# 1 "npb_ing_sf_multicast_top.p4" 1



control npb_ing_sf_multicast_top_part1 (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH
) {

 // temporary internal variables
//  bit<1> action_bitmask_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: multicast

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 action ing_sf_action_sel_hit(
//		bit<1> action_bitmask,
  switch_mgid_t mgid
 ) {
//		action_bitmask_internal = action_bitmask;

  ig_md.multicast.id = mgid;

  ig_md.egress_port_lag_index = 0;
  ig_md.egress_port_lag_hash_sel = 0;
 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
//		action_bitmask_internal = 0;
 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  size = table_size;
  const default_action = ing_sf_action_sel_miss;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

//			ig_md.nsh_md.sf1_active = true;

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // =====================================
   // Action(s)
   // =====================================

//			if(action_bitmask_internal[0:0] == 1) {

    // There used to be a table here that took sfc and gave mgid.  It has been removed in the latest iteration.

//			}

  } else {
//			ig_md.nsh_md.sf1_active = false;
  }

 }
}

// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_multicast_top_part2 (
 inout switch_header_transport_t hdr_0,
 in switch_rid_t replication_id,
 in switch_port_t port,
 inout switch_egress_metadata_t eg_md
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1: 
 // =========================================================================
/*
#ifdef MULTICAST_ENABLE
	action rid_hit_nsh(
		switch_bd_t bd,

		bit<24>               spi,
		bit<8>                si,

		switch_nexthop_t nexthop_index,
		switch_tunnel_index_t tunnel_index,
		switch_outer_nexthop_t outer_nexthop_index
	) {
		eg_md.bd = bd;

		hdr_0.nsh_type1.spi     = spi;
		hdr_0.nsh_type1.si      = si;

		eg_md.nexthop = nexthop_index;
		eg_md.tunnel_0.index = tunnel_index;
		eg_md.outer_nexthop = outer_nexthop_index;
	}

	action rid_hit(
		switch_bd_t bd
	) {
		eg_md.bd = bd;
	}

	action rid_miss() {
	}

	table rid {
		key = {
			replication_id : exact;
		}
		actions = {
			rid_miss;
			rid_hit;
			rid_hit_nsh;
		}

		size = table_size;
		const default_action = rid_miss;
	}
#endif
*/
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================
/*
		if(eg_md.nsh_md.sf1_active == true) {

			// =====================================
			// Decrement SI
			// =====================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is because of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So we move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

			// NOTE: THIS IS DONE IN EGRESS INSTEAD OF INGRESS, BECAUSE WE DON"T FIT OTHERWISE!

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif
			// =====================================
			// Action(s)
			// =====================================

		}
*/
  // =====================================
  // Replication ID Lookup
  // =====================================
/*
#ifdef MULTICAST_ENABLE
		if(replication_id != 0) {
			rid.apply();
		}
#endif
*/
 }
}
# 5 "npb_ing_top.p4" 2
# 1 "npb_ing_sff_top.p4" 1
control npb_ing_sff_top (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 bit<8> hdr_nsh_type1_si_predec; // local copy used for pre-decrementing prior to forwarding lookup.

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy

 // =========================================================================
 // Table #1 - SI  Decrement
 // =========================================================================

 // this table just does a 'pop count' on the bitmask....

//	bit<8> nsh_si_dec_amount;
 bit<2> ig_md_nsh_md_sf_bitmask_2_1;

 action new_si(
  bit<8> dec
 ) {
//		ig_md.nsh_md.si = ig_md.nsh_md.si |-| (bit<8>)dec; // saturating subtract
//		nsh_si_dec_amount = dec;
  hdr_nsh_type1_si_predec = dec;
 }

 // NOTE: SINCE THE FIRST SF HAS ALREADY RUN, WE ONLY NEED TO ACCOUNT FOR
 // THE REMAINING SFs...

 // this is code we'd like to use, but it doesn't work! -- barefoot bug?
/*
	table ing_sff_dec_si {
		key = {
			ig_md.nsh_md.sf_bitmask[2:1] : exact;
		}
		actions = {
			new_si;
		}
		const entries = {
			(0)  : new_si(0); // 0 bits set
			(1)  : new_si(1); // 1 bits set
			(2)  : new_si(1); // 1 bits set
			(3)  : new_si(2); // 2 bits set
		}
	}
*/
/*
	table ing_sff_dec_si {
		key = {
			hdr_0.nsh_type1.si : exact;
//			ig_md.nsh_md.sf_bitmask[2:1] : exact;
			ig_md_nsh_md_sf_bitmask_2_1 : exact;
		}
		actions = {
			new_si;
		}
		const entries = {
			(   0 , 0 ) : new_si(   0 );  (   0 , 1 ) : new_si(   0 );  (   0 , 2 ) : new_si(   0 );  (   0 , 3 ) : new_si(   0 );
			(   1 , 0 ) : new_si(   1 );  (   1 , 1 ) : new_si(   0 );  (   1 , 2 ) : new_si(   0 );  (   1 , 3 ) : new_si(   0 );
			(   2 , 0 ) : new_si(   2 );  (   2 , 1 ) : new_si(   1 );  (   2 , 2 ) : new_si(   1 );  (   2 , 3 ) : new_si(   0 );
			(   3 , 0 ) : new_si(   3 );  (   3 , 1 ) : new_si(   2 );  (   3 , 2 ) : new_si(   2 );  (   3 , 3 ) : new_si(   1 );
			(   4 , 0 ) : new_si(   4 );  (   4 , 1 ) : new_si(   3 );  (   4 , 2 ) : new_si(   3 );  (   4 , 3 ) : new_si(   2 );
			(   5 , 0 ) : new_si(   5 );  (   5 , 1 ) : new_si(   4 );  (   5 , 2 ) : new_si(   4 );  (   5 , 3 ) : new_si(   3 );
			(   6 , 0 ) : new_si(   6 );  (   6 , 1 ) : new_si(   5 );  (   6 , 2 ) : new_si(   5 );  (   6 , 3 ) : new_si(   4 );
			(   7 , 0 ) : new_si(   7 );  (   7 , 1 ) : new_si(   6 );  (   7 , 2 ) : new_si(   6 );  (   7 , 3 ) : new_si(   5 );
			(   8 , 0 ) : new_si(   8 );  (   8 , 1 ) : new_si(   7 );  (   8 , 2 ) : new_si(   7 );  (   8 , 3 ) : new_si(   6 );
			(   9 , 0 ) : new_si(   9 );  (   9 , 1 ) : new_si(   8 );  (   9 , 2 ) : new_si(   8 );  (   9 , 3 ) : new_si(   7 );
			(  10 , 0 ) : new_si(  10 );  (  10 , 1 ) : new_si(   9 );  (  10 , 2 ) : new_si(   9 );  (  10 , 3 ) : new_si(   8 );
			(  11 , 0 ) : new_si(  11 );  (  11 , 1 ) : new_si(  10 );  (  11 , 2 ) : new_si(  10 );  (  11 , 3 ) : new_si(   9 );
			(  12 , 0 ) : new_si(  12 );  (  12 , 1 ) : new_si(  11 );  (  12 , 2 ) : new_si(  11 );  (  12 , 3 ) : new_si(  10 );
			(  13 , 0 ) : new_si(  13 );  (  13 , 1 ) : new_si(  12 );  (  13 , 2 ) : new_si(  12 );  (  13 , 3 ) : new_si(  11 );
			(  14 , 0 ) : new_si(  14 );  (  14 , 1 ) : new_si(  13 );  (  14 , 2 ) : new_si(  13 );  (  14 , 3 ) : new_si(  12 );
			(  15 , 0 ) : new_si(  15 );  (  15 , 1 ) : new_si(  14 );  (  15 , 2 ) : new_si(  14 );  (  15 , 3 ) : new_si(  13 );
			(  16 , 0 ) : new_si(  16 );  (  16 , 1 ) : new_si(  15 );  (  16 , 2 ) : new_si(  15 );  (  16 , 3 ) : new_si(  14 );
			(  17 , 0 ) : new_si(  17 );  (  17 , 1 ) : new_si(  16 );  (  17 , 2 ) : new_si(  16 );  (  17 , 3 ) : new_si(  15 );
			(  18 , 0 ) : new_si(  18 );  (  18 , 1 ) : new_si(  17 );  (  18 , 2 ) : new_si(  17 );  (  18 , 3 ) : new_si(  16 );
			(  19 , 0 ) : new_si(  19 );  (  19 , 1 ) : new_si(  18 );  (  19 , 2 ) : new_si(  18 );  (  19 , 3 ) : new_si(  17 );
			(  20 , 0 ) : new_si(  20 );  (  20 , 1 ) : new_si(  19 );  (  20 , 2 ) : new_si(  19 );  (  20 , 3 ) : new_si(  18 );
			(  21 , 0 ) : new_si(  21 );  (  21 , 1 ) : new_si(  20 );  (  21 , 2 ) : new_si(  20 );  (  21 , 3 ) : new_si(  19 );
			(  22 , 0 ) : new_si(  22 );  (  22 , 1 ) : new_si(  21 );  (  22 , 2 ) : new_si(  21 );  (  22 , 3 ) : new_si(  20 );
			(  23 , 0 ) : new_si(  23 );  (  23 , 1 ) : new_si(  22 );  (  23 , 2 ) : new_si(  22 );  (  23 , 3 ) : new_si(  21 );
			(  24 , 0 ) : new_si(  24 );  (  24 , 1 ) : new_si(  23 );  (  24 , 2 ) : new_si(  23 );  (  24 , 3 ) : new_si(  22 );
			(  25 , 0 ) : new_si(  25 );  (  25 , 1 ) : new_si(  24 );  (  25 , 2 ) : new_si(  24 );  (  25 , 3 ) : new_si(  23 );
			(  26 , 0 ) : new_si(  26 );  (  26 , 1 ) : new_si(  25 );  (  26 , 2 ) : new_si(  25 );  (  26 , 3 ) : new_si(  24 );
			(  27 , 0 ) : new_si(  27 );  (  27 , 1 ) : new_si(  26 );  (  27 , 2 ) : new_si(  26 );  (  27 , 3 ) : new_si(  25 );
			(  28 , 0 ) : new_si(  28 );  (  28 , 1 ) : new_si(  27 );  (  28 , 2 ) : new_si(  27 );  (  28 , 3 ) : new_si(  26 );
			(  29 , 0 ) : new_si(  29 );  (  29 , 1 ) : new_si(  28 );  (  29 , 2 ) : new_si(  28 );  (  29 , 3 ) : new_si(  27 );
			(  30 , 0 ) : new_si(  30 );  (  30 , 1 ) : new_si(  29 );  (  30 , 2 ) : new_si(  29 );  (  30 , 3 ) : new_si(  28 );
			(  31 , 0 ) : new_si(  31 );  (  31 , 1 ) : new_si(  30 );  (  31 , 2 ) : new_si(  30 );  (  31 , 3 ) : new_si(  29 );
			(  32 , 0 ) : new_si(  32 );  (  32 , 1 ) : new_si(  31 );  (  32 , 2 ) : new_si(  31 );  (  32 , 3 ) : new_si(  30 );
			(  33 , 0 ) : new_si(  33 );  (  33 , 1 ) : new_si(  32 );  (  33 , 2 ) : new_si(  32 );  (  33 , 3 ) : new_si(  31 );
			(  34 , 0 ) : new_si(  34 );  (  34 , 1 ) : new_si(  33 );  (  34 , 2 ) : new_si(  33 );  (  34 , 3 ) : new_si(  32 );
			(  35 , 0 ) : new_si(  35 );  (  35 , 1 ) : new_si(  34 );  (  35 , 2 ) : new_si(  34 );  (  35 , 3 ) : new_si(  33 );
			(  36 , 0 ) : new_si(  36 );  (  36 , 1 ) : new_si(  35 );  (  36 , 2 ) : new_si(  35 );  (  36 , 3 ) : new_si(  34 );
			(  37 , 0 ) : new_si(  37 );  (  37 , 1 ) : new_si(  36 );  (  37 , 2 ) : new_si(  36 );  (  37 , 3 ) : new_si(  35 );
			(  38 , 0 ) : new_si(  38 );  (  38 , 1 ) : new_si(  37 );  (  38 , 2 ) : new_si(  37 );  (  38 , 3 ) : new_si(  36 );
			(  39 , 0 ) : new_si(  39 );  (  39 , 1 ) : new_si(  38 );  (  39 , 2 ) : new_si(  38 );  (  39 , 3 ) : new_si(  37 );
			(  40 , 0 ) : new_si(  40 );  (  40 , 1 ) : new_si(  39 );  (  40 , 2 ) : new_si(  39 );  (  40 , 3 ) : new_si(  38 );
			(  41 , 0 ) : new_si(  41 );  (  41 , 1 ) : new_si(  40 );  (  41 , 2 ) : new_si(  40 );  (  41 , 3 ) : new_si(  39 );
			(  42 , 0 ) : new_si(  42 );  (  42 , 1 ) : new_si(  41 );  (  42 , 2 ) : new_si(  41 );  (  42 , 3 ) : new_si(  40 );
			(  43 , 0 ) : new_si(  43 );  (  43 , 1 ) : new_si(  42 );  (  43 , 2 ) : new_si(  42 );  (  43 , 3 ) : new_si(  41 );
			(  44 , 0 ) : new_si(  44 );  (  44 , 1 ) : new_si(  43 );  (  44 , 2 ) : new_si(  43 );  (  44 , 3 ) : new_si(  42 );
			(  45 , 0 ) : new_si(  45 );  (  45 , 1 ) : new_si(  44 );  (  45 , 2 ) : new_si(  44 );  (  45 , 3 ) : new_si(  43 );
			(  46 , 0 ) : new_si(  46 );  (  46 , 1 ) : new_si(  45 );  (  46 , 2 ) : new_si(  45 );  (  46 , 3 ) : new_si(  44 );
			(  47 , 0 ) : new_si(  47 );  (  47 , 1 ) : new_si(  46 );  (  47 , 2 ) : new_si(  46 );  (  47 , 3 ) : new_si(  45 );
			(  48 , 0 ) : new_si(  48 );  (  48 , 1 ) : new_si(  47 );  (  48 , 2 ) : new_si(  47 );  (  48 , 3 ) : new_si(  46 );
			(  49 , 0 ) : new_si(  49 );  (  49 , 1 ) : new_si(  48 );  (  49 , 2 ) : new_si(  48 );  (  49 , 3 ) : new_si(  47 );
			(  50 , 0 ) : new_si(  50 );  (  50 , 1 ) : new_si(  49 );  (  50 , 2 ) : new_si(  49 );  (  50 , 3 ) : new_si(  48 );
			(  51 , 0 ) : new_si(  51 );  (  51 , 1 ) : new_si(  50 );  (  51 , 2 ) : new_si(  50 );  (  51 , 3 ) : new_si(  49 );
			(  52 , 0 ) : new_si(  52 );  (  52 , 1 ) : new_si(  51 );  (  52 , 2 ) : new_si(  51 );  (  52 , 3 ) : new_si(  50 );
			(  53 , 0 ) : new_si(  53 );  (  53 , 1 ) : new_si(  52 );  (  53 , 2 ) : new_si(  52 );  (  53 , 3 ) : new_si(  51 );
			(  54 , 0 ) : new_si(  54 );  (  54 , 1 ) : new_si(  53 );  (  54 , 2 ) : new_si(  53 );  (  54 , 3 ) : new_si(  52 );
			(  55 , 0 ) : new_si(  55 );  (  55 , 1 ) : new_si(  54 );  (  55 , 2 ) : new_si(  54 );  (  55 , 3 ) : new_si(  53 );
			(  56 , 0 ) : new_si(  56 );  (  56 , 1 ) : new_si(  55 );  (  56 , 2 ) : new_si(  55 );  (  56 , 3 ) : new_si(  54 );
			(  57 , 0 ) : new_si(  57 );  (  57 , 1 ) : new_si(  56 );  (  57 , 2 ) : new_si(  56 );  (  57 , 3 ) : new_si(  55 );
			(  58 , 0 ) : new_si(  58 );  (  58 , 1 ) : new_si(  57 );  (  58 , 2 ) : new_si(  57 );  (  58 , 3 ) : new_si(  56 );
			(  59 , 0 ) : new_si(  59 );  (  59 , 1 ) : new_si(  58 );  (  59 , 2 ) : new_si(  58 );  (  59 , 3 ) : new_si(  57 );
			(  60 , 0 ) : new_si(  60 );  (  60 , 1 ) : new_si(  59 );  (  60 , 2 ) : new_si(  59 );  (  60 , 3 ) : new_si(  58 );
			(  61 , 0 ) : new_si(  61 );  (  61 , 1 ) : new_si(  60 );  (  61 , 2 ) : new_si(  60 );  (  61 , 3 ) : new_si(  59 );
			(  62 , 0 ) : new_si(  62 );  (  62 , 1 ) : new_si(  61 );  (  62 , 2 ) : new_si(  61 );  (  62 , 3 ) : new_si(  60 );
			(  63 , 0 ) : new_si(  63 );  (  63 , 1 ) : new_si(  62 );  (  63 , 2 ) : new_si(  62 );  (  63 , 3 ) : new_si(  61 );
			(  64 , 0 ) : new_si(  64 );  (  64 , 1 ) : new_si(  63 );  (  64 , 2 ) : new_si(  63 );  (  64 , 3 ) : new_si(  62 );
			(  65 , 0 ) : new_si(  65 );  (  65 , 1 ) : new_si(  64 );  (  65 , 2 ) : new_si(  64 );  (  65 , 3 ) : new_si(  63 );
			(  66 , 0 ) : new_si(  66 );  (  66 , 1 ) : new_si(  65 );  (  66 , 2 ) : new_si(  65 );  (  66 , 3 ) : new_si(  64 );
			(  67 , 0 ) : new_si(  67 );  (  67 , 1 ) : new_si(  66 );  (  67 , 2 ) : new_si(  66 );  (  67 , 3 ) : new_si(  65 );
			(  68 , 0 ) : new_si(  68 );  (  68 , 1 ) : new_si(  67 );  (  68 , 2 ) : new_si(  67 );  (  68 , 3 ) : new_si(  66 );
			(  69 , 0 ) : new_si(  69 );  (  69 , 1 ) : new_si(  68 );  (  69 , 2 ) : new_si(  68 );  (  69 , 3 ) : new_si(  67 );
			(  70 , 0 ) : new_si(  70 );  (  70 , 1 ) : new_si(  69 );  (  70 , 2 ) : new_si(  69 );  (  70 , 3 ) : new_si(  68 );
			(  71 , 0 ) : new_si(  71 );  (  71 , 1 ) : new_si(  70 );  (  71 , 2 ) : new_si(  70 );  (  71 , 3 ) : new_si(  69 );
			(  72 , 0 ) : new_si(  72 );  (  72 , 1 ) : new_si(  71 );  (  72 , 2 ) : new_si(  71 );  (  72 , 3 ) : new_si(  70 );
			(  73 , 0 ) : new_si(  73 );  (  73 , 1 ) : new_si(  72 );  (  73 , 2 ) : new_si(  72 );  (  73 , 3 ) : new_si(  71 );
			(  74 , 0 ) : new_si(  74 );  (  74 , 1 ) : new_si(  73 );  (  74 , 2 ) : new_si(  73 );  (  74 , 3 ) : new_si(  72 );
			(  75 , 0 ) : new_si(  75 );  (  75 , 1 ) : new_si(  74 );  (  75 , 2 ) : new_si(  74 );  (  75 , 3 ) : new_si(  73 );
			(  76 , 0 ) : new_si(  76 );  (  76 , 1 ) : new_si(  75 );  (  76 , 2 ) : new_si(  75 );  (  76 , 3 ) : new_si(  74 );
			(  77 , 0 ) : new_si(  77 );  (  77 , 1 ) : new_si(  76 );  (  77 , 2 ) : new_si(  76 );  (  77 , 3 ) : new_si(  75 );
			(  78 , 0 ) : new_si(  78 );  (  78 , 1 ) : new_si(  77 );  (  78 , 2 ) : new_si(  77 );  (  78 , 3 ) : new_si(  76 );
			(  79 , 0 ) : new_si(  79 );  (  79 , 1 ) : new_si(  78 );  (  79 , 2 ) : new_si(  78 );  (  79 , 3 ) : new_si(  77 );
			(  80 , 0 ) : new_si(  80 );  (  80 , 1 ) : new_si(  79 );  (  80 , 2 ) : new_si(  79 );  (  80 , 3 ) : new_si(  78 );
			(  81 , 0 ) : new_si(  81 );  (  81 , 1 ) : new_si(  80 );  (  81 , 2 ) : new_si(  80 );  (  81 , 3 ) : new_si(  79 );
			(  82 , 0 ) : new_si(  82 );  (  82 , 1 ) : new_si(  81 );  (  82 , 2 ) : new_si(  81 );  (  82 , 3 ) : new_si(  80 );
			(  83 , 0 ) : new_si(  83 );  (  83 , 1 ) : new_si(  82 );  (  83 , 2 ) : new_si(  82 );  (  83 , 3 ) : new_si(  81 );
			(  84 , 0 ) : new_si(  84 );  (  84 , 1 ) : new_si(  83 );  (  84 , 2 ) : new_si(  83 );  (  84 , 3 ) : new_si(  82 );
			(  85 , 0 ) : new_si(  85 );  (  85 , 1 ) : new_si(  84 );  (  85 , 2 ) : new_si(  84 );  (  85 , 3 ) : new_si(  83 );
			(  86 , 0 ) : new_si(  86 );  (  86 , 1 ) : new_si(  85 );  (  86 , 2 ) : new_si(  85 );  (  86 , 3 ) : new_si(  84 );
			(  87 , 0 ) : new_si(  87 );  (  87 , 1 ) : new_si(  86 );  (  87 , 2 ) : new_si(  86 );  (  87 , 3 ) : new_si(  85 );
			(  88 , 0 ) : new_si(  88 );  (  88 , 1 ) : new_si(  87 );  (  88 , 2 ) : new_si(  87 );  (  88 , 3 ) : new_si(  86 );
			(  89 , 0 ) : new_si(  89 );  (  89 , 1 ) : new_si(  88 );  (  89 , 2 ) : new_si(  88 );  (  89 , 3 ) : new_si(  87 );
			(  90 , 0 ) : new_si(  90 );  (  90 , 1 ) : new_si(  89 );  (  90 , 2 ) : new_si(  89 );  (  90 , 3 ) : new_si(  88 );
			(  91 , 0 ) : new_si(  91 );  (  91 , 1 ) : new_si(  90 );  (  91 , 2 ) : new_si(  90 );  (  91 , 3 ) : new_si(  89 );
			(  92 , 0 ) : new_si(  92 );  (  92 , 1 ) : new_si(  91 );  (  92 , 2 ) : new_si(  91 );  (  92 , 3 ) : new_si(  90 );
			(  93 , 0 ) : new_si(  93 );  (  93 , 1 ) : new_si(  92 );  (  93 , 2 ) : new_si(  92 );  (  93 , 3 ) : new_si(  91 );
			(  94 , 0 ) : new_si(  94 );  (  94 , 1 ) : new_si(  93 );  (  94 , 2 ) : new_si(  93 );  (  94 , 3 ) : new_si(  92 );
			(  95 , 0 ) : new_si(  95 );  (  95 , 1 ) : new_si(  94 );  (  95 , 2 ) : new_si(  94 );  (  95 , 3 ) : new_si(  93 );
			(  96 , 0 ) : new_si(  96 );  (  96 , 1 ) : new_si(  95 );  (  96 , 2 ) : new_si(  95 );  (  96 , 3 ) : new_si(  94 );
			(  97 , 0 ) : new_si(  97 );  (  97 , 1 ) : new_si(  96 );  (  97 , 2 ) : new_si(  96 );  (  97 , 3 ) : new_si(  95 );
			(  98 , 0 ) : new_si(  98 );  (  98 , 1 ) : new_si(  97 );  (  98 , 2 ) : new_si(  97 );  (  98 , 3 ) : new_si(  96 );
			(  99 , 0 ) : new_si(  99 );  (  99 , 1 ) : new_si(  98 );  (  99 , 2 ) : new_si(  98 );  (  99 , 3 ) : new_si(  97 );
			( 100 , 0 ) : new_si( 100 );  ( 100 , 1 ) : new_si(  99 );  ( 100 , 2 ) : new_si(  99 );  ( 100 , 3 ) : new_si(  98 );
			( 101 , 0 ) : new_si( 101 );  ( 101 , 1 ) : new_si( 100 );  ( 101 , 2 ) : new_si( 100 );  ( 101 , 3 ) : new_si(  99 );
			( 102 , 0 ) : new_si( 102 );  ( 102 , 1 ) : new_si( 101 );  ( 102 , 2 ) : new_si( 101 );  ( 102 , 3 ) : new_si( 100 );
			( 103 , 0 ) : new_si( 103 );  ( 103 , 1 ) : new_si( 102 );  ( 103 , 2 ) : new_si( 102 );  ( 103 , 3 ) : new_si( 101 );
			( 104 , 0 ) : new_si( 104 );  ( 104 , 1 ) : new_si( 103 );  ( 104 , 2 ) : new_si( 103 );  ( 104 , 3 ) : new_si( 102 );
			( 105 , 0 ) : new_si( 105 );  ( 105 , 1 ) : new_si( 104 );  ( 105 , 2 ) : new_si( 104 );  ( 105 , 3 ) : new_si( 103 );
			( 106 , 0 ) : new_si( 106 );  ( 106 , 1 ) : new_si( 105 );  ( 106 , 2 ) : new_si( 105 );  ( 106 , 3 ) : new_si( 104 );
			( 107 , 0 ) : new_si( 107 );  ( 107 , 1 ) : new_si( 106 );  ( 107 , 2 ) : new_si( 106 );  ( 107 , 3 ) : new_si( 105 );
			( 108 , 0 ) : new_si( 108 );  ( 108 , 1 ) : new_si( 107 );  ( 108 , 2 ) : new_si( 107 );  ( 108 , 3 ) : new_si( 106 );
			( 109 , 0 ) : new_si( 109 );  ( 109 , 1 ) : new_si( 108 );  ( 109 , 2 ) : new_si( 108 );  ( 109 , 3 ) : new_si( 107 );
			( 110 , 0 ) : new_si( 110 );  ( 110 , 1 ) : new_si( 109 );  ( 110 , 2 ) : new_si( 109 );  ( 110 , 3 ) : new_si( 108 );
			( 111 , 0 ) : new_si( 111 );  ( 111 , 1 ) : new_si( 110 );  ( 111 , 2 ) : new_si( 110 );  ( 111 , 3 ) : new_si( 109 );
			( 112 , 0 ) : new_si( 112 );  ( 112 , 1 ) : new_si( 111 );  ( 112 , 2 ) : new_si( 111 );  ( 112 , 3 ) : new_si( 110 );
			( 113 , 0 ) : new_si( 113 );  ( 113 , 1 ) : new_si( 112 );  ( 113 , 2 ) : new_si( 112 );  ( 113 , 3 ) : new_si( 111 );
			( 114 , 0 ) : new_si( 114 );  ( 114 , 1 ) : new_si( 113 );  ( 114 , 2 ) : new_si( 113 );  ( 114 , 3 ) : new_si( 112 );
			( 115 , 0 ) : new_si( 115 );  ( 115 , 1 ) : new_si( 114 );  ( 115 , 2 ) : new_si( 114 );  ( 115 , 3 ) : new_si( 113 );
			( 116 , 0 ) : new_si( 116 );  ( 116 , 1 ) : new_si( 115 );  ( 116 , 2 ) : new_si( 115 );  ( 116 , 3 ) : new_si( 114 );
			( 117 , 0 ) : new_si( 117 );  ( 117 , 1 ) : new_si( 116 );  ( 117 , 2 ) : new_si( 116 );  ( 117 , 3 ) : new_si( 115 );
			( 118 , 0 ) : new_si( 118 );  ( 118 , 1 ) : new_si( 117 );  ( 118 , 2 ) : new_si( 117 );  ( 118 , 3 ) : new_si( 116 );
			( 119 , 0 ) : new_si( 119 );  ( 119 , 1 ) : new_si( 118 );  ( 119 , 2 ) : new_si( 118 );  ( 119 , 3 ) : new_si( 117 );
			( 120 , 0 ) : new_si( 120 );  ( 120 , 1 ) : new_si( 119 );  ( 120 , 2 ) : new_si( 119 );  ( 120 , 3 ) : new_si( 118 );
			( 121 , 0 ) : new_si( 121 );  ( 121 , 1 ) : new_si( 120 );  ( 121 , 2 ) : new_si( 120 );  ( 121 , 3 ) : new_si( 119 );
			( 122 , 0 ) : new_si( 122 );  ( 122 , 1 ) : new_si( 121 );  ( 122 , 2 ) : new_si( 121 );  ( 122 , 3 ) : new_si( 120 );
			( 123 , 0 ) : new_si( 123 );  ( 123 , 1 ) : new_si( 122 );  ( 123 , 2 ) : new_si( 122 );  ( 123 , 3 ) : new_si( 121 );
			( 124 , 0 ) : new_si( 124 );  ( 124 , 1 ) : new_si( 123 );  ( 124 , 2 ) : new_si( 123 );  ( 124 , 3 ) : new_si( 122 );
			( 125 , 0 ) : new_si( 125 );  ( 125 , 1 ) : new_si( 124 );  ( 125 , 2 ) : new_si( 124 );  ( 125 , 3 ) : new_si( 123 );
			( 126 , 0 ) : new_si( 126 );  ( 126 , 1 ) : new_si( 125 );  ( 126 , 2 ) : new_si( 125 );  ( 126 , 3 ) : new_si( 124 );
			( 127 , 0 ) : new_si( 127 );  ( 127 , 1 ) : new_si( 126 );  ( 127 , 2 ) : new_si( 126 );  ( 127 , 3 ) : new_si( 125 );
			( 128 , 0 ) : new_si( 128 );  ( 128 , 1 ) : new_si( 127 );  ( 128 , 2 ) : new_si( 127 );  ( 128 , 3 ) : new_si( 126 );
			( 129 , 0 ) : new_si( 129 );  ( 129 , 1 ) : new_si( 128 );  ( 129 , 2 ) : new_si( 128 );  ( 129 , 3 ) : new_si( 127 );
			( 130 , 0 ) : new_si( 130 );  ( 130 , 1 ) : new_si( 129 );  ( 130 , 2 ) : new_si( 129 );  ( 130 , 3 ) : new_si( 128 );
			( 131 , 0 ) : new_si( 131 );  ( 131 , 1 ) : new_si( 130 );  ( 131 , 2 ) : new_si( 130 );  ( 131 , 3 ) : new_si( 129 );
			( 132 , 0 ) : new_si( 132 );  ( 132 , 1 ) : new_si( 131 );  ( 132 , 2 ) : new_si( 131 );  ( 132 , 3 ) : new_si( 130 );
			( 133 , 0 ) : new_si( 133 );  ( 133 , 1 ) : new_si( 132 );  ( 133 , 2 ) : new_si( 132 );  ( 133 , 3 ) : new_si( 131 );
			( 134 , 0 ) : new_si( 134 );  ( 134 , 1 ) : new_si( 133 );  ( 134 , 2 ) : new_si( 133 );  ( 134 , 3 ) : new_si( 132 );
			( 135 , 0 ) : new_si( 135 );  ( 135 , 1 ) : new_si( 134 );  ( 135 , 2 ) : new_si( 134 );  ( 135 , 3 ) : new_si( 133 );
			( 136 , 0 ) : new_si( 136 );  ( 136 , 1 ) : new_si( 135 );  ( 136 , 2 ) : new_si( 135 );  ( 136 , 3 ) : new_si( 134 );
			( 137 , 0 ) : new_si( 137 );  ( 137 , 1 ) : new_si( 136 );  ( 137 , 2 ) : new_si( 136 );  ( 137 , 3 ) : new_si( 135 );
			( 138 , 0 ) : new_si( 138 );  ( 138 , 1 ) : new_si( 137 );  ( 138 , 2 ) : new_si( 137 );  ( 138 , 3 ) : new_si( 136 );
			( 139 , 0 ) : new_si( 139 );  ( 139 , 1 ) : new_si( 138 );  ( 139 , 2 ) : new_si( 138 );  ( 139 , 3 ) : new_si( 137 );
			( 140 , 0 ) : new_si( 140 );  ( 140 , 1 ) : new_si( 139 );  ( 140 , 2 ) : new_si( 139 );  ( 140 , 3 ) : new_si( 138 );
			( 141 , 0 ) : new_si( 141 );  ( 141 , 1 ) : new_si( 140 );  ( 141 , 2 ) : new_si( 140 );  ( 141 , 3 ) : new_si( 139 );
			( 142 , 0 ) : new_si( 142 );  ( 142 , 1 ) : new_si( 141 );  ( 142 , 2 ) : new_si( 141 );  ( 142 , 3 ) : new_si( 140 );
			( 143 , 0 ) : new_si( 143 );  ( 143 , 1 ) : new_si( 142 );  ( 143 , 2 ) : new_si( 142 );  ( 143 , 3 ) : new_si( 141 );
			( 144 , 0 ) : new_si( 144 );  ( 144 , 1 ) : new_si( 143 );  ( 144 , 2 ) : new_si( 143 );  ( 144 , 3 ) : new_si( 142 );
			( 145 , 0 ) : new_si( 145 );  ( 145 , 1 ) : new_si( 144 );  ( 145 , 2 ) : new_si( 144 );  ( 145 , 3 ) : new_si( 143 );
			( 146 , 0 ) : new_si( 146 );  ( 146 , 1 ) : new_si( 145 );  ( 146 , 2 ) : new_si( 145 );  ( 146 , 3 ) : new_si( 144 );
			( 147 , 0 ) : new_si( 147 );  ( 147 , 1 ) : new_si( 146 );  ( 147 , 2 ) : new_si( 146 );  ( 147 , 3 ) : new_si( 145 );
			( 148 , 0 ) : new_si( 148 );  ( 148 , 1 ) : new_si( 147 );  ( 148 , 2 ) : new_si( 147 );  ( 148 , 3 ) : new_si( 146 );
			( 149 , 0 ) : new_si( 149 );  ( 149 , 1 ) : new_si( 148 );  ( 149 , 2 ) : new_si( 148 );  ( 149 , 3 ) : new_si( 147 );
			( 150 , 0 ) : new_si( 150 );  ( 150 , 1 ) : new_si( 149 );  ( 150 , 2 ) : new_si( 149 );  ( 150 , 3 ) : new_si( 148 );
			( 151 , 0 ) : new_si( 151 );  ( 151 , 1 ) : new_si( 150 );  ( 151 , 2 ) : new_si( 150 );  ( 151 , 3 ) : new_si( 149 );
			( 152 , 0 ) : new_si( 152 );  ( 152 , 1 ) : new_si( 151 );  ( 152 , 2 ) : new_si( 151 );  ( 152 , 3 ) : new_si( 150 );
			( 153 , 0 ) : new_si( 153 );  ( 153 , 1 ) : new_si( 152 );  ( 153 , 2 ) : new_si( 152 );  ( 153 , 3 ) : new_si( 151 );
			( 154 , 0 ) : new_si( 154 );  ( 154 , 1 ) : new_si( 153 );  ( 154 , 2 ) : new_si( 153 );  ( 154 , 3 ) : new_si( 152 );
			( 155 , 0 ) : new_si( 155 );  ( 155 , 1 ) : new_si( 154 );  ( 155 , 2 ) : new_si( 154 );  ( 155 , 3 ) : new_si( 153 );
			( 156 , 0 ) : new_si( 156 );  ( 156 , 1 ) : new_si( 155 );  ( 156 , 2 ) : new_si( 155 );  ( 156 , 3 ) : new_si( 154 );
			( 157 , 0 ) : new_si( 157 );  ( 157 , 1 ) : new_si( 156 );  ( 157 , 2 ) : new_si( 156 );  ( 157 , 3 ) : new_si( 155 );
			( 158 , 0 ) : new_si( 158 );  ( 158 , 1 ) : new_si( 157 );  ( 158 , 2 ) : new_si( 157 );  ( 158 , 3 ) : new_si( 156 );
			( 159 , 0 ) : new_si( 159 );  ( 159 , 1 ) : new_si( 158 );  ( 159 , 2 ) : new_si( 158 );  ( 159 , 3 ) : new_si( 157 );
			( 160 , 0 ) : new_si( 160 );  ( 160 , 1 ) : new_si( 159 );  ( 160 , 2 ) : new_si( 159 );  ( 160 , 3 ) : new_si( 158 );
			( 161 , 0 ) : new_si( 161 );  ( 161 , 1 ) : new_si( 160 );  ( 161 , 2 ) : new_si( 160 );  ( 161 , 3 ) : new_si( 159 );
			( 162 , 0 ) : new_si( 162 );  ( 162 , 1 ) : new_si( 161 );  ( 162 , 2 ) : new_si( 161 );  ( 162 , 3 ) : new_si( 160 );
			( 163 , 0 ) : new_si( 163 );  ( 163 , 1 ) : new_si( 162 );  ( 163 , 2 ) : new_si( 162 );  ( 163 , 3 ) : new_si( 161 );
			( 164 , 0 ) : new_si( 164 );  ( 164 , 1 ) : new_si( 163 );  ( 164 , 2 ) : new_si( 163 );  ( 164 , 3 ) : new_si( 162 );
			( 165 , 0 ) : new_si( 165 );  ( 165 , 1 ) : new_si( 164 );  ( 165 , 2 ) : new_si( 164 );  ( 165 , 3 ) : new_si( 163 );
			( 166 , 0 ) : new_si( 166 );  ( 166 , 1 ) : new_si( 165 );  ( 166 , 2 ) : new_si( 165 );  ( 166 , 3 ) : new_si( 164 );
			( 167 , 0 ) : new_si( 167 );  ( 167 , 1 ) : new_si( 166 );  ( 167 , 2 ) : new_si( 166 );  ( 167 , 3 ) : new_si( 165 );
			( 168 , 0 ) : new_si( 168 );  ( 168 , 1 ) : new_si( 167 );  ( 168 , 2 ) : new_si( 167 );  ( 168 , 3 ) : new_si( 166 );
			( 169 , 0 ) : new_si( 169 );  ( 169 , 1 ) : new_si( 168 );  ( 169 , 2 ) : new_si( 168 );  ( 169 , 3 ) : new_si( 167 );
			( 170 , 0 ) : new_si( 170 );  ( 170 , 1 ) : new_si( 169 );  ( 170 , 2 ) : new_si( 169 );  ( 170 , 3 ) : new_si( 168 );
			( 171 , 0 ) : new_si( 171 );  ( 171 , 1 ) : new_si( 170 );  ( 171 , 2 ) : new_si( 170 );  ( 171 , 3 ) : new_si( 169 );
			( 172 , 0 ) : new_si( 172 );  ( 172 , 1 ) : new_si( 171 );  ( 172 , 2 ) : new_si( 171 );  ( 172 , 3 ) : new_si( 170 );
			( 173 , 0 ) : new_si( 173 );  ( 173 , 1 ) : new_si( 172 );  ( 173 , 2 ) : new_si( 172 );  ( 173 , 3 ) : new_si( 171 );
			( 174 , 0 ) : new_si( 174 );  ( 174 , 1 ) : new_si( 173 );  ( 174 , 2 ) : new_si( 173 );  ( 174 , 3 ) : new_si( 172 );
			( 175 , 0 ) : new_si( 175 );  ( 175 , 1 ) : new_si( 174 );  ( 175 , 2 ) : new_si( 174 );  ( 175 , 3 ) : new_si( 173 );
			( 176 , 0 ) : new_si( 176 );  ( 176 , 1 ) : new_si( 175 );  ( 176 , 2 ) : new_si( 175 );  ( 176 , 3 ) : new_si( 174 );
			( 177 , 0 ) : new_si( 177 );  ( 177 , 1 ) : new_si( 176 );  ( 177 , 2 ) : new_si( 176 );  ( 177 , 3 ) : new_si( 175 );
			( 178 , 0 ) : new_si( 178 );  ( 178 , 1 ) : new_si( 177 );  ( 178 , 2 ) : new_si( 177 );  ( 178 , 3 ) : new_si( 176 );
			( 179 , 0 ) : new_si( 179 );  ( 179 , 1 ) : new_si( 178 );  ( 179 , 2 ) : new_si( 178 );  ( 179 , 3 ) : new_si( 177 );
			( 180 , 0 ) : new_si( 180 );  ( 180 , 1 ) : new_si( 179 );  ( 180 , 2 ) : new_si( 179 );  ( 180 , 3 ) : new_si( 178 );
			( 181 , 0 ) : new_si( 181 );  ( 181 , 1 ) : new_si( 180 );  ( 181 , 2 ) : new_si( 180 );  ( 181 , 3 ) : new_si( 179 );
			( 182 , 0 ) : new_si( 182 );  ( 182 , 1 ) : new_si( 181 );  ( 182 , 2 ) : new_si( 181 );  ( 182 , 3 ) : new_si( 180 );
			( 183 , 0 ) : new_si( 183 );  ( 183 , 1 ) : new_si( 182 );  ( 183 , 2 ) : new_si( 182 );  ( 183 , 3 ) : new_si( 181 );
			( 184 , 0 ) : new_si( 184 );  ( 184 , 1 ) : new_si( 183 );  ( 184 , 2 ) : new_si( 183 );  ( 184 , 3 ) : new_si( 182 );
			( 185 , 0 ) : new_si( 185 );  ( 185 , 1 ) : new_si( 184 );  ( 185 , 2 ) : new_si( 184 );  ( 185 , 3 ) : new_si( 183 );
			( 186 , 0 ) : new_si( 186 );  ( 186 , 1 ) : new_si( 185 );  ( 186 , 2 ) : new_si( 185 );  ( 186 , 3 ) : new_si( 184 );
			( 187 , 0 ) : new_si( 187 );  ( 187 , 1 ) : new_si( 186 );  ( 187 , 2 ) : new_si( 186 );  ( 187 , 3 ) : new_si( 185 );
			( 188 , 0 ) : new_si( 188 );  ( 188 , 1 ) : new_si( 187 );  ( 188 , 2 ) : new_si( 187 );  ( 188 , 3 ) : new_si( 186 );
			( 189 , 0 ) : new_si( 189 );  ( 189 , 1 ) : new_si( 188 );  ( 189 , 2 ) : new_si( 188 );  ( 189 , 3 ) : new_si( 187 );
			( 190 , 0 ) : new_si( 190 );  ( 190 , 1 ) : new_si( 189 );  ( 190 , 2 ) : new_si( 189 );  ( 190 , 3 ) : new_si( 188 );
			( 191 , 0 ) : new_si( 191 );  ( 191 , 1 ) : new_si( 190 );  ( 191 , 2 ) : new_si( 190 );  ( 191 , 3 ) : new_si( 189 );
			( 192 , 0 ) : new_si( 192 );  ( 192 , 1 ) : new_si( 191 );  ( 192 , 2 ) : new_si( 191 );  ( 192 , 3 ) : new_si( 190 );
			( 193 , 0 ) : new_si( 193 );  ( 193 , 1 ) : new_si( 192 );  ( 193 , 2 ) : new_si( 192 );  ( 193 , 3 ) : new_si( 191 );
			( 194 , 0 ) : new_si( 194 );  ( 194 , 1 ) : new_si( 193 );  ( 194 , 2 ) : new_si( 193 );  ( 194 , 3 ) : new_si( 192 );
			( 195 , 0 ) : new_si( 195 );  ( 195 , 1 ) : new_si( 194 );  ( 195 , 2 ) : new_si( 194 );  ( 195 , 3 ) : new_si( 193 );
			( 196 , 0 ) : new_si( 196 );  ( 196 , 1 ) : new_si( 195 );  ( 196 , 2 ) : new_si( 195 );  ( 196 , 3 ) : new_si( 194 );
			( 197 , 0 ) : new_si( 197 );  ( 197 , 1 ) : new_si( 196 );  ( 197 , 2 ) : new_si( 196 );  ( 197 , 3 ) : new_si( 195 );
			( 198 , 0 ) : new_si( 198 );  ( 198 , 1 ) : new_si( 197 );  ( 198 , 2 ) : new_si( 197 );  ( 198 , 3 ) : new_si( 196 );
			( 199 , 0 ) : new_si( 199 );  ( 199 , 1 ) : new_si( 198 );  ( 199 , 2 ) : new_si( 198 );  ( 199 , 3 ) : new_si( 197 );
			( 200 , 0 ) : new_si( 200 );  ( 200 , 1 ) : new_si( 199 );  ( 200 , 2 ) : new_si( 199 );  ( 200 , 3 ) : new_si( 198 );
			( 201 , 0 ) : new_si( 201 );  ( 201 , 1 ) : new_si( 200 );  ( 201 , 2 ) : new_si( 200 );  ( 201 , 3 ) : new_si( 199 );
			( 202 , 0 ) : new_si( 202 );  ( 202 , 1 ) : new_si( 201 );  ( 202 , 2 ) : new_si( 201 );  ( 202 , 3 ) : new_si( 200 );
			( 203 , 0 ) : new_si( 203 );  ( 203 , 1 ) : new_si( 202 );  ( 203 , 2 ) : new_si( 202 );  ( 203 , 3 ) : new_si( 201 );
			( 204 , 0 ) : new_si( 204 );  ( 204 , 1 ) : new_si( 203 );  ( 204 , 2 ) : new_si( 203 );  ( 204 , 3 ) : new_si( 202 );
			( 205 , 0 ) : new_si( 205 );  ( 205 , 1 ) : new_si( 204 );  ( 205 , 2 ) : new_si( 204 );  ( 205 , 3 ) : new_si( 203 );
			( 206 , 0 ) : new_si( 206 );  ( 206 , 1 ) : new_si( 205 );  ( 206 , 2 ) : new_si( 205 );  ( 206 , 3 ) : new_si( 204 );
			( 207 , 0 ) : new_si( 207 );  ( 207 , 1 ) : new_si( 206 );  ( 207 , 2 ) : new_si( 206 );  ( 207 , 3 ) : new_si( 205 );
			( 208 , 0 ) : new_si( 208 );  ( 208 , 1 ) : new_si( 207 );  ( 208 , 2 ) : new_si( 207 );  ( 208 , 3 ) : new_si( 206 );
			( 209 , 0 ) : new_si( 209 );  ( 209 , 1 ) : new_si( 208 );  ( 209 , 2 ) : new_si( 208 );  ( 209 , 3 ) : new_si( 207 );
			( 210 , 0 ) : new_si( 210 );  ( 210 , 1 ) : new_si( 209 );  ( 210 , 2 ) : new_si( 209 );  ( 210 , 3 ) : new_si( 208 );
			( 211 , 0 ) : new_si( 211 );  ( 211 , 1 ) : new_si( 210 );  ( 211 , 2 ) : new_si( 210 );  ( 211 , 3 ) : new_si( 209 );
			( 212 , 0 ) : new_si( 212 );  ( 212 , 1 ) : new_si( 211 );  ( 212 , 2 ) : new_si( 211 );  ( 212 , 3 ) : new_si( 210 );
			( 213 , 0 ) : new_si( 213 );  ( 213 , 1 ) : new_si( 212 );  ( 213 , 2 ) : new_si( 212 );  ( 213 , 3 ) : new_si( 211 );
			( 214 , 0 ) : new_si( 214 );  ( 214 , 1 ) : new_si( 213 );  ( 214 , 2 ) : new_si( 213 );  ( 214 , 3 ) : new_si( 212 );
			( 215 , 0 ) : new_si( 215 );  ( 215 , 1 ) : new_si( 214 );  ( 215 , 2 ) : new_si( 214 );  ( 215 , 3 ) : new_si( 213 );
			( 216 , 0 ) : new_si( 216 );  ( 216 , 1 ) : new_si( 215 );  ( 216 , 2 ) : new_si( 215 );  ( 216 , 3 ) : new_si( 214 );
			( 217 , 0 ) : new_si( 217 );  ( 217 , 1 ) : new_si( 216 );  ( 217 , 2 ) : new_si( 216 );  ( 217 , 3 ) : new_si( 215 );
			( 218 , 0 ) : new_si( 218 );  ( 218 , 1 ) : new_si( 217 );  ( 218 , 2 ) : new_si( 217 );  ( 218 , 3 ) : new_si( 216 );
			( 219 , 0 ) : new_si( 219 );  ( 219 , 1 ) : new_si( 218 );  ( 219 , 2 ) : new_si( 218 );  ( 219 , 3 ) : new_si( 217 );
			( 220 , 0 ) : new_si( 220 );  ( 220 , 1 ) : new_si( 219 );  ( 220 , 2 ) : new_si( 219 );  ( 220 , 3 ) : new_si( 218 );
			( 221 , 0 ) : new_si( 221 );  ( 221 , 1 ) : new_si( 220 );  ( 221 , 2 ) : new_si( 220 );  ( 221 , 3 ) : new_si( 219 );
			( 222 , 0 ) : new_si( 222 );  ( 222 , 1 ) : new_si( 221 );  ( 222 , 2 ) : new_si( 221 );  ( 222 , 3 ) : new_si( 220 );
			( 223 , 0 ) : new_si( 223 );  ( 223 , 1 ) : new_si( 222 );  ( 223 , 2 ) : new_si( 222 );  ( 223 , 3 ) : new_si( 221 );
			( 224 , 0 ) : new_si( 224 );  ( 224 , 1 ) : new_si( 223 );  ( 224 , 2 ) : new_si( 223 );  ( 224 , 3 ) : new_si( 222 );
			( 225 , 0 ) : new_si( 225 );  ( 225 , 1 ) : new_si( 224 );  ( 225 , 2 ) : new_si( 224 );  ( 225 , 3 ) : new_si( 223 );
			( 226 , 0 ) : new_si( 226 );  ( 226 , 1 ) : new_si( 225 );  ( 226 , 2 ) : new_si( 225 );  ( 226 , 3 ) : new_si( 224 );
			( 227 , 0 ) : new_si( 227 );  ( 227 , 1 ) : new_si( 226 );  ( 227 , 2 ) : new_si( 226 );  ( 227 , 3 ) : new_si( 225 );
			( 228 , 0 ) : new_si( 228 );  ( 228 , 1 ) : new_si( 227 );  ( 228 , 2 ) : new_si( 227 );  ( 228 , 3 ) : new_si( 226 );
			( 229 , 0 ) : new_si( 229 );  ( 229 , 1 ) : new_si( 228 );  ( 229 , 2 ) : new_si( 228 );  ( 229 , 3 ) : new_si( 227 );
			( 230 , 0 ) : new_si( 230 );  ( 230 , 1 ) : new_si( 229 );  ( 230 , 2 ) : new_si( 229 );  ( 230 , 3 ) : new_si( 228 );
			( 231 , 0 ) : new_si( 231 );  ( 231 , 1 ) : new_si( 230 );  ( 231 , 2 ) : new_si( 230 );  ( 231 , 3 ) : new_si( 229 );
			( 232 , 0 ) : new_si( 232 );  ( 232 , 1 ) : new_si( 231 );  ( 232 , 2 ) : new_si( 231 );  ( 232 , 3 ) : new_si( 230 );
			( 233 , 0 ) : new_si( 233 );  ( 233 , 1 ) : new_si( 232 );  ( 233 , 2 ) : new_si( 232 );  ( 233 , 3 ) : new_si( 231 );
			( 234 , 0 ) : new_si( 234 );  ( 234 , 1 ) : new_si( 233 );  ( 234 , 2 ) : new_si( 233 );  ( 234 , 3 ) : new_si( 232 );
			( 235 , 0 ) : new_si( 235 );  ( 235 , 1 ) : new_si( 234 );  ( 235 , 2 ) : new_si( 234 );  ( 235 , 3 ) : new_si( 233 );
			( 236 , 0 ) : new_si( 236 );  ( 236 , 1 ) : new_si( 235 );  ( 236 , 2 ) : new_si( 235 );  ( 236 , 3 ) : new_si( 234 );
			( 237 , 0 ) : new_si( 237 );  ( 237 , 1 ) : new_si( 236 );  ( 237 , 2 ) : new_si( 236 );  ( 237 , 3 ) : new_si( 235 );
			( 238 , 0 ) : new_si( 238 );  ( 238 , 1 ) : new_si( 237 );  ( 238 , 2 ) : new_si( 237 );  ( 238 , 3 ) : new_si( 236 );
			( 239 , 0 ) : new_si( 239 );  ( 239 , 1 ) : new_si( 238 );  ( 239 , 2 ) : new_si( 238 );  ( 239 , 3 ) : new_si( 237 );
			( 240 , 0 ) : new_si( 240 );  ( 240 , 1 ) : new_si( 239 );  ( 240 , 2 ) : new_si( 239 );  ( 240 , 3 ) : new_si( 238 );
			( 241 , 0 ) : new_si( 241 );  ( 241 , 1 ) : new_si( 240 );  ( 241 , 2 ) : new_si( 240 );  ( 241 , 3 ) : new_si( 239 );
			( 242 , 0 ) : new_si( 242 );  ( 242 , 1 ) : new_si( 241 );  ( 242 , 2 ) : new_si( 241 );  ( 242 , 3 ) : new_si( 240 );
			( 243 , 0 ) : new_si( 243 );  ( 243 , 1 ) : new_si( 242 );  ( 243 , 2 ) : new_si( 242 );  ( 243 , 3 ) : new_si( 241 );
			( 244 , 0 ) : new_si( 244 );  ( 244 , 1 ) : new_si( 243 );  ( 244 , 2 ) : new_si( 243 );  ( 244 , 3 ) : new_si( 242 );
			( 245 , 0 ) : new_si( 245 );  ( 245 , 1 ) : new_si( 244 );  ( 245 , 2 ) : new_si( 244 );  ( 245 , 3 ) : new_si( 243 );
			( 246 , 0 ) : new_si( 246 );  ( 246 , 1 ) : new_si( 245 );  ( 246 , 2 ) : new_si( 245 );  ( 246 , 3 ) : new_si( 244 );
			( 247 , 0 ) : new_si( 247 );  ( 247 , 1 ) : new_si( 246 );  ( 247 , 2 ) : new_si( 246 );  ( 247 , 3 ) : new_si( 245 );
			( 248 , 0 ) : new_si( 248 );  ( 248 , 1 ) : new_si( 247 );  ( 248 , 2 ) : new_si( 247 );  ( 248 , 3 ) : new_si( 246 );
			( 249 , 0 ) : new_si( 249 );  ( 249 , 1 ) : new_si( 248 );  ( 249 , 2 ) : new_si( 248 );  ( 249 , 3 ) : new_si( 247 );
			( 250 , 0 ) : new_si( 250 );  ( 250 , 1 ) : new_si( 249 );  ( 250 , 2 ) : new_si( 249 );  ( 250 , 3 ) : new_si( 248 );
			( 251 , 0 ) : new_si( 251 );  ( 251 , 1 ) : new_si( 250 );  ( 251 , 2 ) : new_si( 250 );  ( 251 , 3 ) : new_si( 249 );
			( 252 , 0 ) : new_si( 252 );  ( 252 , 1 ) : new_si( 251 );  ( 252 , 2 ) : new_si( 251 );  ( 252 , 3 ) : new_si( 250 );
			( 253 , 0 ) : new_si( 253 );  ( 253 , 1 ) : new_si( 252 );  ( 253 , 2 ) : new_si( 252 );  ( 253 , 3 ) : new_si( 251 );
			( 254 , 0 ) : new_si( 254 );  ( 254 , 1 ) : new_si( 253 );  ( 254 , 2 ) : new_si( 253 );  ( 254 , 3 ) : new_si( 252 );
			( 255 , 0 ) : new_si( 255 );  ( 255 , 1 ) : new_si( 254 );  ( 255 , 2 ) : new_si( 254 );  ( 255 , 3 ) : new_si( 253 );
		}
	}
*/
/*
	table ing_sff_dec_si {
		key = {
			ig_md.nsh_md.sf_bitmask : exact;
		}
		actions = {
			new_si;
		 }
		const entries = {
			0  : new_si(0); // 0 bits set
			1  : new_si(0); // 1 bits set -- but don't count bit 0
			2  : new_si(1); // 1 bits set
			3  : new_si(1); // 2 bits set -- but don't count bit 0
			4  : new_si(1); // 1 bits set
			5  : new_si(1); // 2 bits set -- but don't count bit 0
			6  : new_si(2); // 2 bits set
			7  : new_si(2); // 3 bits set -- but don't count bit 0
		}
		const default_action = new_si(0);
	}
*/

 // =========================================================================
 // Table #2: ARP
 // =========================================================================

 action drop_pkt (
 ) {
  ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
  ig_md.nsh_md.end_of_path = false;
 }

 // =====================================

 action unicast(
  switch_nexthop_t nexthop_index,

  bool end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;

  ig_md.nsh_md.end_of_path = end_of_chain;
 }

 // =====================================

 action multicast(
  bool end_of_chain
 ) {
  ig_md.nsh_md.end_of_path = end_of_chain;
 }

 // =====================================
 // Table
 // =====================================

 table ing_sff_fib {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");

//			hdr_nsh_type1_si_predec : exact @name("si");
   ig_md.nsh_md.si_predec : exact @name("si");



  }

  actions = {
   drop_pkt;
   multicast;
   unicast;
  }

  // Derek: drop packet on miss...
  //
  // RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
  // do not correspond to a valid next hop in a valid SFP, that packet MUST
  // be dropped by the SFF.

  const default_action = drop_pkt;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 // Need to do one table lookups here:
 //
 // 1: forwarding lookup, after any sf's have reclassified the packet.

 apply {
//		ig_md.nsh_md.end_of_path = false;

  // +---------------+---------------+-----------------------------+
  // | hdr nsh valid | our nsh valid | signals / actions           |
  // +---------------+---------------+-----------------------------+
  // | n/a           | FALSE         | --> (classification failed) |
  // | FALSE         | TRUE          | --> we  classified          |
  // | TRUE          | TRUE          | --> was classified          |
  // +---------------+---------------+-----------------------------+

//		if(ig_md.nsh_md.valid == 1) {

   // Note: All of this code has to come after, serially, the first service function.
   // This is because the first service function can reclassify / change just about
   // anything with regard to the packet and it's service path.

   // -------------------------------------
   // Perform Flow Scheduling
   // -------------------------------------
/*
			npb_ing_sf_npb_basic_adv_sfp_sel.apply(
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
*/
   // -------------------------------------
   // Pre-Decrement SI
   // -------------------------------------

   // Here we decrement the SI for all SF's we are going to do in the
   // chip.  We have to do all the decrements prior to the forwarding
   // lookup.  However, each SF still needs to do it's own decrement so
   // the the next SF gets the correct value.  Thus we don't want to
   // save this value permanently....


//			ig_md_nsh_md_sf_bitmask_2_1 = ig_md.nsh_md.sf_bitmask[2:1];

//			ing_sff_dec_si.apply(); // do a pop-count on the bitmask

//			hdr_nsh_type1_si_predec = hdr_0.nsh_type1.si |-| (bit<8>)nsh_si_dec_amount; // saturating subtract
//			hdr_nsh_type1_si_predec = (bit<8>)nsh_si_dec_amount; // saturating subtract

   // -------------------------------------
   // Perform Forwarding Lookup
   // -------------------------------------

   ing_sff_fib.apply();

   // -------------------------------------
   // Check SI
   // -------------------------------------

   // RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
   // will discard any NSH packet with an SI of 0, as there will be no
   // valid next SF information."

//			if((ig_md_nsh_md_si == 0) && (ig_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtract)
//				ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//			}

   // NOTE: MOVED TO EGRESS

//		}

 }

}
# 6 "npb_ing_top.p4" 2

# 1 "scoper.p4" 1
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
 ******************************************************************************/
# 8 "npb_ing_top.p4" 2

control npb_ing_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {


//  Scoper_l7() scoper_l7;



 npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1;

//	npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2;



 TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
 TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 TunnelEncapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_encap_transport_ingress;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // Derek: Don't know what we want to do with this signal for the 
  // npb path.  For now, just setting it to 0 here (it's set in port.p4,
  // but probably not using the fields we want to be used for the npb)

  ig_intr_md_for_tm.level2_exclusion_id = 0;

  // -----------------------------------------------------------------
  // Set Initial Scope
  // -----------------------------------------------------------------

  if(hdr_0.nsh_type1.scope == 0) {

   // do nothing
# 71 "npb_ing_top.p4"
  } else {

   Scoper.apply(
    ig_md.lkp_2,
    ig_md.drop_reason_2,

    ig_md.lkp_1
   );
# 88 "npb_ing_top.p4"
  }

  // -----------------------------------------------------------------
  // Set Initial Scope (L7)
  // -----------------------------------------------------------------






  // -----------------------------------------------------------------

  // populate udf in lkp struct for the following cases:
  //   scope==inner
  //   scope==outer and no inner stack present
  // todo: do we need to qualify this w/ hdr_udf.isValid()? (the thinking is it will just work w/o doing so)


//      if(hdr_0.nsh_type1.scope==1 || (hdr_0.nsh_type1.scope==0 && !hdr_2.ethernet.isValid())) {
//              scoper_l7.apply(hdr_udf, ig_md.lkp);
//      }


  // -------------------------------------
  // SFC
  // -------------------------------------

  npb_ing_sfc_top.apply (
   hdr_0,
   tunnel_0,
   hdr_1,
   tunnel_1,
   hdr_2,
   tunnel_2,
   hdr_udf,

   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr,
   ig_intr_md_for_dprsr,
   ig_intr_md_for_tm
  );

  // -------------------------------------
  // Pre-Generate Flow Schd Hashes
  // -------------------------------------


  npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.apply(
   hdr_0,
   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr,
   ig_intr_md_for_dprsr,
   ig_intr_md_for_tm,

   ig_md.lkp_1.mac_type,
   ig_md.lkp_1.ip_proto,
   ig_md.lkp_1.l4_src_port,
   ig_md.lkp_1.l4_dst_port,
   ig_md.nsh_md.hash_1
  );

  // -------------------------------------
# 164 "npb_ing_top.p4"
  // -------------------------------------
/*
  #ifdef SF_0_ALLOW_SCOPE_CHANGES

    #ifdef INGRESS_PARSER_POPULATES_LKP_2
    #else
		ScoperInner.apply(
			hdr_2,
			tunnel_2,
			ig_md.drop_reason_2,

			ig_md.lkp_2
		);
    #endif

		npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm,

			ig_md.lkp_2.mac_type,
			ig_md.lkp_2.ip_proto,
			ig_md.lkp_2.l4_src_port,
			ig_md.lkp_2.l4_dst_port,
			ig_md.nsh_md.hash_2
		);
  #endif // SF_0_ALLOW_SCOPE_CHANGES
*/


  // -------------------------------------
  // SF #0 - Policy
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_ACL != 0)) {
   npb_ing_sf_npb_basic_adv_top.apply (
    hdr_0,
    hdr_1,
    hdr_2,
    hdr_udf,

    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

   // -------------------------------------

   npb_ing_sf_npb_basic_adv_sfp_sel.apply(
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SFF Reframing
  // -------------------------------------

  // Decaps ------------------------------

  tunnel_decap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);



  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);
# 255 "npb_ing_top.p4"
  // Encaps ------------------------------

  tunnel_0.encap = true;
  tunnel_encap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1);

  // -------------------------------------
  // SFF
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SFF != 0)) {
   npb_ing_sff_top.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SF #1 - Multicast
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_MCAST != 0)) {
   npb_ing_sf_multicast_top_part1.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }
 }
}
# 60 "npb.p4" 2
# 1 "npb_ing_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_ing_deparser.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/
# 23 "npb_ing_deparser.p4" 2

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------

control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.





    apply {
# 75 "npb_ing_deparser.p4"
    }
}

//-----------------------------------------------------------------------------

control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

 IngressMirror() mirror;

    apply {
  mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** PRE-TRANSPORT *****
        pkt.emit(hdr.transport.nsh_type1);

        // ***** TRANSPORT *****
//      pkt.emit(hdr.transport.ethernet);
//      pkt.emit(hdr.transport.vlan_tag);

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);

        pkt.emit(hdr.outer.e_tag);


        pkt.emit(hdr.outer.vn_tag);

        pkt.emit(hdr.outer.vlan_tag);




        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        pkt.emit(hdr.outer.vxlan);

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        pkt.emit(hdr.outer.nvgre);


        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);



        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        pkt.emit(hdr.inner.ipv6);

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);


        pkt.emit(hdr.inner.gre);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);



        pkt.emit(hdr.udf);

    }
}
# 61 "npb.p4" 2
# 1 "npb_egr_parser.p4" 1



parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    bit<8> scope;
    bool l2_fwd_en;
    bool rmac_hit;

 bit<8> protocol_outer;
 bit<8> protocol_inner;


    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;


        // initialize lookup struct to zeros
        eg_md.lkp_1.mac_src_addr = 0;
        eg_md.lkp_1.mac_dst_addr = 0;
        eg_md.lkp_1.mac_type = 0;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.pad = 0;
        eg_md.lkp_1.vid = 0;
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        eg_md.lkp_1.ip_proto = 0;
        eg_md.lkp_1.ip_tos = 0;
        eg_md.lkp_1.ip_flags = 0;
        eg_md.lkp_1.ip_src_addr = 0;
        eg_md.lkp_1.ip_dst_addr = 0;
        eg_md.lkp_1.ip_len = 0;
        eg_md.lkp_1.tcp_flags = 0;
        eg_md.lkp_1.l4_src_port = 0;
        eg_md.lkp_1.l4_dst_port = 0;
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        eg_md.lkp_1.tunnel_id = 0;
        eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE; // note: outer here means "current scope - 2"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE; // note: inner here means "current scope - 1"


//      eg_md.inner_inner.ethernet_isValid = false;
//      eg_md.inner_inner.ipv4_isValid = false;
//      eg_md.inner_inner.ipv6_isValid = false;
# 69 "npb_egr_parser.p4"
        transition parse_bridged_pkt;

    }

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

  // ---- extract base bridged metadata -----
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type             = hdr.bridged_md.base.pkt_type;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
//      eg_md.ingress_timestamp    = hdr.bridged_md.base.timestamp;
        eg_md.flags.rmac_hit = hdr.bridged_md.base.rmac_hit;

        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel_0.index = hdr.bridged_md.tunnel.index;
//      eg_md.tunnel_0.hash        = hdr.bridged_md.tunnel.hash;

//      eg_md.tunnel_0.terminate   = hdr.bridged_md.tunnel.terminate_0;
//      eg_md.tunnel_1.terminate   = hdr.bridged_md.tunnel.terminate_1;
//      eg_md.tunnel_2.terminate   = hdr.bridged_md.tunnel.terminate_2;


  // ----- extract nsh bridged metadata -----
        eg_md.nsh_md.start_of_path = hdr.bridged_md.base.nsh_md_start_of_path;
  eg_md.nsh_md.end_of_path = hdr.bridged_md.base.nsh_md_end_of_path;
  eg_md.nsh_md.l2_fwd_en = hdr.bridged_md.base.nsh_md_l2_fwd_en;
//      eg_md.nsh_md.sf1_active    = hdr.bridged_md.base.nsh_md_sf1_active;

  // ----- extract dedup bridged metadata -----
//#ifdef SF_2_DEDUP_ENABLE
  eg_md.nsh_md.dedup_en = hdr.bridged_md.base.nsh_md_dedup_en;
//#endif







        // ----- add cpu header by default -----
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) hdr.bridged_md.base.ingress_port;
        //hdr.cpu.port_lag_index     = (bit<16>) hdr.bridged_md.base.ingress_port_lag_index;
        hdr.cpu.ingress_bd = (bit<16>) hdr.bridged_md.base.ingress_bd;
        hdr.cpu.reason_code = (bit<16>) hdr.bridged_md.base.cpu_reason;

        // -----------------------------
        // packet will always have NSH present

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

        transition select(
            (bit<1>)hdr.bridged_md.base.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md.base.rmac_hit) {

            (1, 0): parse_outer_ethernet_scope0; // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;    // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh; // SFC Network-Tap / SFC Bypass Path
        }

    }

    state parse_ig_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
//      eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;




        // ----- add cpu header by default -----
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) 0; // derek, what to set to?
        //hdr.cpu.port_lag_index     = (bit<16>) 0; // derek, what to set to?
        hdr.cpu.ingress_bd = (bit<16>) 0; // derek, what to set to?
        hdr.cpu.reason_code = (bit<16>) SWITCH_CPU_REASON_IG_PORT_MIRRROR;
// Derek: I think this is broken -- packet may have an nsh header at the start instead of an ethernet header -- code needs to look more like above "transition select"?
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;

        transition accept;
    }

    state parse_deflected_pkt {
# 208 "npb_egr_parser.p4"
    }

    state parse_eg_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
//      eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
# 226 "npb_egr_parser.p4"
        // ----- add cpu header by default -----
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) 0; // derek, what to set to?
        //hdr.cpu.port_lag_index     = (bit<16>) 0; // derek, what to set to?
        hdr.cpu.ingress_bd = (bit<16>) 0; // derek, what to set to?
        hdr.cpu.reason_code = (bit<16>) SWITCH_CPU_REASON_EG_PORT_MIRRROR;
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type; // derek: does this need to be done after reframings?

        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd; // for cpu header
        // eg_md.ingress_port = cpu_md.md.port; // for cpu header
        eg_md.cpu_reason = cpu_md.reason_code; // for cpu header
# 261 "npb_egr_parser.p4"
        // ----- add cpu header by default -----
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) cpu_md.port;
        //hdr.cpu.port_lag_index     = (bit<16>) cpu_md.port_lag_index;
        hdr.cpu.ingress_bd = (bit<16>) cpu_md.bd;
        hdr.cpu.reason_code = (bit<16>) cpu_md.reason_code;

        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type; // derek: does this need to be done after reframings? // derek: this line is needed in the code, but get a compiler error!


        transition accept;
    }

    state parse_dtel_drop_metadata_from_egress {
# 305 "npb_egr_parser.p4"
        transition reject;

    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.outer.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {
# 335 "npb_egr_parser.p4"
        transition reject;

    }

    state parse_dtel_switch_local_metadata {
# 364 "npb_egr_parser.p4"
        transition reject;

    }

    state parse_simple_mirrored_metadata {
# 400 "npb_egr_parser.p4"
        transition reject;

    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Transport Layer 2 (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // NSH
    ///////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        pkt.extract(hdr.transport.ethernet);
        transition select(hdr.transport.ethernet.ether_type) {
            0x8100: parse_transport_vlan;
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);
        scope = hdr.transport.nsh_type1.scope;

        transition select(scope, hdr.transport.nsh_type1.next_proto) {
            (0, 0x3): parse_outer_ethernet_scope0;


            (1, 0x3): parse_outer_ethernet_scope1;




            default: reject; // todo: support ipv4? ipv6?
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope0 {
        pkt.extract(hdr.outer.ethernet);
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br_scope0;


            0x8926 : parse_outer_vn_scope0;

            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_br_scope0 {
     pkt.extract(hdr.outer.e_tag);

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //eg_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag

        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }



    state parse_outer_vn_scope0 {
     pkt.extract(hdr.outer.vn_tag);

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;

        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_vlan_0_scope0 {
     pkt.extract(hdr.outer.vlan_tag[0]);

        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;







        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1_scope0;
            0x88A8 : parse_outer_vlan_1_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }

    state parse_outer_vlan_1_scope0 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;




        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope1 {
        pkt.extract(hdr.outer.ethernet);
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br_scope1;



            0x8926 : parse_outer_vn_scope1;


            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_br_scope1 {
     pkt.extract(hdr.outer.e_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;


        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    state parse_outer_vn_scope1 {
     pkt.extract(hdr.outer.vn_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    state parse_outer_vlan_0_scope1 {
     pkt.extract(hdr.outer.vlan_tag[0]);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;
# 677 "npb_egr_parser.p4"
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1_scope1;
            0x88A8 : parse_outer_vlan_1_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vlan_1_scope1 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;





        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope0 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;

        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        eg_md.lkp_1.ip_src_addr = (bit<128>)hdr.outer.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr = (bit<128>)hdr.outer.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.

        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset,
            hdr.outer.ipv4.protocol) {

            (5, 0, 1): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, 2): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, _): branch_outer_l3_protocol_scope0;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope0 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;

        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;


        transition select(hdr.outer.ipv6.next_hdr) {
            58: parse_outer_icmp_igmp_overload_scope0;
            default: branch_outer_l3_protocol_scope0;
        }



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope0 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_type_scope0;
           41: parse_outer_ipv6inip_set_tunnel_type_scope0;
           17: parse_outer_udp_scope0;
           6: parse_outer_tcp_scope0;
           0x84: parse_outer_sctp_scope0;
           47: parse_outer_gre_scope0;
           0x32: parse_outer_esp_overload_scope0;
           default: accept;
       }
    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope1 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset) {

            (5, 0): branch_outer_l3_protocol_scope1;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope1 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        transition branch_outer_l3_protocol_scope1;



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope1 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_type_scope1;
           41: parse_outer_ipv6inip_set_tunnel_type_scope1;
           17: parse_outer_udp_scope1;
           6: parse_outer_tcp_scope1;
           0x84: parse_outer_sctp_scope1;
           47: parse_outer_gre_scope1;
           default: accept;
       }
    }


    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_outer_icmp_igmp_overload_scope0 {

        eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();

        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp_scope0 {
        pkt.extract(hdr.outer.udp);


        eg_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan_scope0;



            (_, 2123): parse_outer_gtp_c_scope0;
            (2123, _): parse_outer_gtp_c_scope0;
            (_, 2152): parse_outer_gtp_u_scope0;
            (2152, _): parse_outer_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope0;

            default : accept;
        }
    }

    state parse_outer_udp_scope1 {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan_scope1;



            (_, 2123): parse_outer_gtp_c_scope1;
            (2123, _): parse_outer_gtp_c_scope1;
            (_, 2152): parse_outer_gtp_u_scope1;
            (2152, _): parse_outer_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope1;

            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp_scope0 {
        pkt.extract(hdr.outer.tcp);

        eg_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition accept;
    }

    state parse_outer_tcp_scope1 {
        pkt.extract(hdr.outer.tcp);
        transition accept;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp_scope0 {
        pkt.extract(hdr.outer.sctp);

        eg_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition accept;
    }

    state parse_outer_sctp_scope1 {
        pkt.extract(hdr.outer.sctp);
        transition accept;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
# 972 "npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////



    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan_scope0 {
        pkt.extract(hdr.outer.vxlan);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;

        transition parse_inner_ethernet_scope0;
    }

    state parse_outer_vxlan_scope1 {
        pkt.extract(hdr.outer.vxlan);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_VXLAN; // note: inner here means "current scope - 1"
        transition parse_inner_ethernet_scope1;
    }




    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv4_scope0;



    }

    state parse_outer_ipv6inip_set_tunnel_type_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv6_scope0;



    }


    state parse_outer_ipinip_set_tunnel_type_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv4_scope1;



    }

    state parse_outer_ipv6inip_set_tunnel_type_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv6_scope1;



    }



    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre_scope0 {
        pkt.extract(hdr.outer.gre);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;


        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.R,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.s,
            hdr.outer.gre.recurse,
            hdr.outer.gre.flags,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {

          // C R K S s r f v

            (0,0,1,0,0,0,0,0,0x6558): parse_outer_nvgre_scope0;

            (0,0,0,0,0,0,0,0,0x0800): parse_inner_ipv4_scope0;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6_scope0;



            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional_scope0;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional_scope0;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_scope1 {
        pkt.extract(hdr.outer.gre);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GRE; // note: inner here means "current scope - 1"

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.R,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.s,
            hdr.outer.gre.recurse,
            hdr.outer.gre.flags,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {

          // C R K S s r f v

            (0,0,1,0,0,0,0,0,0x6558): parse_outer_nvgre_scope1;

            (0,0,0,0,0,0,0,0,0x0800): parse_inner_ipv4_scope1;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6_scope1;



            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional_scope1;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional_scope1;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional_scope1;
            default: accept;
        }
    }


    state parse_outer_gre_optional_scope0 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope0;
            0x86dd: parse_inner_ipv6_scope0;



            default: accept;
        }
    }

    state parse_outer_gre_optional_scope1 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope1;
            0x86dd: parse_inner_ipv6_scope1;



            default: accept;
        }
    }




    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre_scope0 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;

     transition parse_inner_ethernet_scope0;
    }

    state parse_outer_nvgre_scope1 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NVGRE; // note: inner here means "current scope - 1"
     transition parse_inner_ethernet_scope1;
    }



    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_esp_overload_scope0 {

         eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
         eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;

        transition accept;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF

    state parse_outer_gtp_c_scope0 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c_scope0;
            default: accept;
        }
    }

    state extract_outer_gtp_c_scope0 {

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;

     transition accept;
    }

    state parse_outer_gtp_c_scope1 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPC; // note: inner here means "current scope - 1"
     transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u_scope0 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u_scope0;
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional_scope0;
            default: accept;
        }
    }

    state extract_outer_gtp_u_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope0;
            6: parse_inner_ipv6_scope0;
            default: accept;
        }
    }

    state extract_outer_gtp_u_with_optional_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope0;
            (0, 6): parse_inner_ipv6_scope0;
            default: accept;
        }
    }


    state parse_outer_gtp_u_scope1 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u_scope1;
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_u_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope1;
            6: parse_inner_ipv6_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_u_with_optional_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope1;
            (0, 6): parse_inner_ipv6_scope1;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_inner_ethernet_scope0 {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope0;
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    state parse_inner_vlan_scope0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------            

    state parse_inner_ethernet_scope1 {
        pkt.extract(hdr.inner.ethernet);

        eg_md.lkp_1.mac_src_addr = hdr.inner.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.inner.ethernet.ether_type;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.vid = 0;

        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope1;
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }

    state parse_inner_vlan_scope1 {
        pkt.extract(hdr.inner.vlan_tag[0]);

        eg_md.lkp_1.pcp = hdr.inner.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.inner.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.inner.vlan_tag[0].ether_type;






        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------            

    state parse_inner_ipv4_scope0 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;
            transition select(
                hdr.inner.ipv4.ihl,
                hdr.inner.ipv4.frag_offset) {

           (5, 0): branch_inner_l3_protocol_scope0;
           default : accept;
       }
    }

    state parse_inner_ipv6_scope0 {

        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;
        transition branch_inner_l3_protocol_scope0;



    }

    state branch_inner_l3_protocol_scope0 {
        transition select(protocol_inner) {
           17: parse_inner_udp_scope0;
           6: parse_inner_tcp_scope0;
           0x84: parse_inner_sctp_scope0;

           47: parse_inner_gre_scope0;

           4: parse_inner_ipinip_set_tunnel_type_scope0;
           41: parse_inner_ipv6inip_set_tunnel_type_scope0;
        }
    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_ipv4_scope1 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x0800;

        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.inner.ipv4.flags;
        eg_md.lkp_1.ip_src_addr = (bit<128>)hdr.inner.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr = (bit<128>)hdr.inner.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset,
            hdr.inner.ipv4.protocol) {
            (5, 0, 1): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, 2): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, _): branch_inner_l3_protocol_scope1;
            default : accept;
       }
    }

    state parse_inner_ipv6_scope1 {

        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x86dd;

        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.inner.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.inner.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv6.payload_len;

        transition select(hdr.inner.ipv6.next_hdr) {
            58: parse_inner_icmp_igmp_overload_scope1;
            default: branch_inner_l3_protocol_scope1;
        }



    }

    state branch_inner_l3_protocol_scope1 {
        transition select(protocol_inner) {
           17: parse_inner_udp_scope1;
           6: parse_inner_tcp_scope1;
           0x84: parse_inner_sctp_scope1;

           47: parse_inner_gre_scope1;

           0x32: parse_inner_esp_overload_scope1;
           4: parse_inner_ipinip_set_tunnel_type_scope1;
           41: parse_inner_ipv6inip_set_tunnel_type_scope1;
        }
    }


    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_inner_icmp_igmp_overload_scope1 {
        eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope0 {
        pkt.extract(hdr.inner.udp);
        transition select(hdr.inner.udp.src_port, hdr.inner.udp.dst_port) {

            (_, 2123): parse_inner_gtp_c_scope0;
            (2123, _): parse_inner_gtp_c_scope0;
            (_, 2152): parse_inner_gtp_u_scope0;
            (2152, _): parse_inner_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope0;

            default: accept;
        }
    }

    state parse_inner_tcp_scope0 {
        pkt.extract(hdr.inner.tcp);
        transition accept;
    }

    state parse_inner_sctp_scope0 {
        pkt.extract(hdr.inner.sctp);
        transition accept;
    }

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope1 {
        pkt.extract(hdr.inner.udp);
        eg_md.lkp_1.l4_src_port = hdr.inner.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.udp.dst_port;
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {


            (_, 2123): parse_inner_gtp_c_scope1;
            (2123, _): parse_inner_gtp_c_scope1;
            (_, 2152): parse_inner_gtp_u_scope1;
            (2152, _): parse_inner_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope1;

            default: accept;
        }
    }

    state parse_inner_tcp_scope1 {
        pkt.extract(hdr.inner.tcp);
        eg_md.lkp_1.tcp_flags = hdr.inner.tcp.flags;
        eg_md.lkp_1.l4_src_port = hdr.inner.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.tcp.dst_port;
        transition accept;
    }

    state parse_inner_sctp_scope1 {
        pkt.extract(hdr.inner.sctp);
        eg_md.lkp_1.l4_src_port = hdr.inner.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.sctp.dst_port;
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type_scope0 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_type_scope0 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_inner_ipv6;



    }


    state parse_inner_ipinip_set_tunnel_type_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_type_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_esp_overload_scope1 {
        eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
        eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
        transition accept;
    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre_scope0 {
        pkt.extract(hdr.inner.gre);

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.R,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.s,
            hdr.inner.gre.recurse,
            hdr.inner.gre.flags,
            hdr.inner.gre.version,
            hdr.inner.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gre_scope1 {
        pkt.extract(hdr.inner.gre);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.R,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.s,
            hdr.inner.gre.recurse,
            hdr.inner.gre.flags,
            hdr.inner.gre.version,
            hdr.inner.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_inner_inner_ipv6;
            default: accept;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF

    state parse_inner_gtp_c_scope0 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c_scope0;
            default: accept;
        }
    }
    state extract_inner_gtp_c_scope0 {
     transition accept;
    }


    state parse_inner_gtp_c_scope1 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c_scope1;
            default: accept;
        }
    }
    state extract_inner_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u_scope0 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u_scope0;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional_scope0;
            default: accept;
        }
    }

    state extract_inner_gtp_u_scope0 {
        pkt.extract(hdr.inner.gtp_v1_base);
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state extract_inner_gtp_u_with_optional_scope0 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }


    state parse_inner_gtp_u_scope1 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u_scope1;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional_scope1;
            default: accept;
        }
    }

    state extract_inner_gtp_u_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state extract_inner_gtp_u_with_optional_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
  hdr.inner_inner.ipv4.setValid();
//      eg_md.inner_inner.ipv4_isValid = true;
  transition accept;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();
//      eg_md.inner_inner.ipv6_isValid = true;
  transition accept;
    }





// ///////////////////////////////////////////////////////////////////////////////
// // Transport Encaps
// ///////////////////////////////////////////////////////////////////////////////
// 
// //-----------------------------------------------------------------------------
// // Encapsulated Remote Switch Port Analyzer (ERSPAN)
// //-----------------------------------------------------------------------------
// 
// state parse_erspan_t1 {
//     pkt.extract(hdr.erspan_type1);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T1
//     transition parse_inner_ethernet;
// }
// 
// state parse_erspan_t2 {
//     pkt.extract(hdr.erspan_type2);
//     //verify(hdr.erspan_typeII.version == 1, error.Erspan2VersionNotOne);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T2
//     transition parse_inner_ethernet;
// }
// 
// // state parse_erspan_t3 {
// //     pkt.extract(hdr.erspan_type3);
// //     //verify(hdr.erspan_typeIII.version == 2, error.Erspan3VersionNotTwo);
// //     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T3
// //     transition select(hdr.erspan_type3.o) {
// //         1: parse_erspan_type3_platform;
// //         default: parse_inner_ethernet;
// //     }
// // }
// // 
// // state parse_erspan_type3_platform {
// //     pkt.extract(hdr.erspan_platform);
// //     transition parse_inner_ethernet;
// // }
// 
// 


}
# 62 "npb.p4" 2
# 1 "npb_egr_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
        in switch_header_t hdr, // src
        inout switch_egress_metadata_t eg_md // dst
) {

    // -----------------------------
 // Apply
    // -----------------------------

    apply {

        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if(hdr.transport.nsh_type1.scope == 0) {
            if (hdr.outer.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.outer.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        } else {
            if (hdr.inner.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.inner.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        }

        // -----------------------------------------------------------------------

  // ipv6: would like to do this stuff in the parser, but can't because tos
  // field isn't byte aligned...

  // ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"

  if(hdr.transport.nsh_type1.scope == 0) {
   // ----- outer -----

   if(hdr.outer.ipv6.isValid()) {
    eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
   }

//			if(hdr.outer.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//			}
  } else {
   // ----- inner -----

   if(hdr.inner.ipv6.isValid()) {
    eg_md.lkp_1.ip_tos = hdr.inner.ipv6.tos;
   }

//			if(hdr.inner.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
//			}
  }
# 85 "npb_egr_set_lkp.p4"
    }
}
# 63 "npb.p4" 2
# 1 "npb_egr_top.p4" 1




# 1 "npb_egr_sff_top.p4" 1
control npb_egr_sff_top_part1 (
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Table
 // =========================================================================

 // RFC 8300, Page 9: Decrementing (the TTL) from an incoming value of 0 shall
 // result in a TTL value of 63.   The handling of an incoming 0 TTL allows
 // for better, although not perfect, interoperation with pre-standard
 // implementations that do not support this TTL field.

    action new_ttl(bit<6> ttl) {
        hdr_0.nsh_type1.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr_0.nsh_type1.ttl : exact; }
        actions = { new_ttl; discard; }
  size = 64;
        const entries = {
            0 : new_ttl(63);
//          1  : discard();
            1 : new_ttl(0);
            2 : new_ttl(1);
            3 : new_ttl(2);
            4 : new_ttl(3);
            5 : new_ttl(4);
            6 : new_ttl(5);
            7 : new_ttl(6);
            8 : new_ttl(7);
            9 : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // SFF
  // =====================================

  // -------------------------------------
  // Reframer
  // -------------------------------------

  // Three mutually-exclusive reframing scenarios are supported:
  //
  // 1: First  in chain --> encap
  // 2: Middle in chain --> rewrite
  // 3: Last   in chain --> decap
  //
  // Note that the example in the RFC shows either a first/middle or last -- but not
  // combinations of these.  Howver, conceivabably I suppose you could have a last
  // (i.e. decap) followed by a first (i.e. encap).  Regardless, the RFC example
  // doesn't show this, and so we don't support it (currently anyway).
  //
  // To support these three reframing scenarios, I look at three signals:
  //
  // +---------------+---------------+--------------+-------------------------------------+
  // | hdr nsh valid | our nsh valid | terminate    | signals / actions                   |
  // +---------------+---------------+--------------+-------------------------------------+
  // | n/a           | FALSE         | n/a          | --> (classification failed)         |
  // | FALSE         | TRUE          | FALSE        | --> first  / encap                  |
  // | FALSE         | TRUE          | TRUE         | --> first  / encap   & last / decap |
  // | TRUE          | TRUE          | FALSE        | --> middle / rewrite                |
  // | TRUE          | TRUE          | TRUE         | --> last   / decap                  |
  // +---------------+---------------+--------------+-------------------------------------+
  //
  // Note: The above truth table just shows how my logic handles the three scenarios,
  // although you could devise other ways to look at these signals and still get the
  // same results.

  // ----------------------------------------
  // Move NSH Metadata to NSH Header
  // ----------------------------------------

//		if((eg_md.nsh_md.valid == 1) && (hdr_0.nsh_type1.isValid())) {
//		if(hdr_0.nsh_type1.isValid()) {
  if(eg_md.nsh_md.start_of_path == false) {

   // ---------------
   // need to do a rewrite...
   // ---------------

   npb_egr_sff_dec_ttl.apply();

  } else {

   // ---------------
   // need to do a encap...
   // ---------------

//			hdr_0.nsh_type1.setValid();

   // base: word 0
   hdr_0.nsh_type1.version = 0x0;
   hdr_0.nsh_type1.o = 0x0;
   hdr_0.nsh_type1.reserved = 0x0;
   hdr_0.nsh_type1.ttl = 0x3f; // 63 is the rfc's recommended default value.
   hdr_0.nsh_type1.len = 0x6; // in 4-byte words (1 + 1 + 4).
   hdr_0.nsh_type1.reserved2 = 0x0;
   hdr_0.nsh_type1.md_type = 0x1; // 0 = reserved, 1 = fixed len, 2 = variable len.
//			hdr_0.nsh_type1.next_proto               = 0x3;  // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

   // base: word 1
   // (nothing to do)

   // ext: type 1 - word 0-3
   hdr_0.nsh_type1.ver = 0x2; // word 0
   hdr_0.nsh_type1.reserved3 = 0x0; // word 0

   hdr_0.nsh_type1.lag_hash = 0x0; // word 0


   hdr_0.nsh_type1.reserved4 = 0x0; // word 2


   hdr_0.nsh_type1.timestamp = 0x0; // word 3 // FOR SIMS


  }

 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sff_top_part2 (
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =============================
  // SFF (continued)
  // =============================

  // -------------------------------------
  // Check TTL & SI
  // -------------------------------------

  // RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
  // will discard any NSH packet with an SI of 0, as there will be no
  // valid next SF information."

//		if((hdr_0.nsh_type1.si == 0) && (eg_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtracts)
//			eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//		}

//		if(eg_md.tunnel_0.terminate == false) { // check for si of 0 (or underflow, since we used a saturating subtracts)
  if(eg_md.nsh_md.end_of_path == false) { // check for si of 0 (or underflow, since we used a saturating subtracts)

   // ---------------
   // need to do a rewrite...
   // ---------------

   if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
    eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
   }
  } else {

   // ---------------
   // need to do a decap...
   // ---------------

   hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....
  }

  // -------------------------------------
  // Fowrarding Lookup
  // -------------------------------------

  // Derek: I guess the forwarding lookup would normally
  // be done here.  However, since Tofino requires the outport
  // to set in ingress, it has to be done there instead....

 }

}
# 6 "npb_egr_top.p4" 2

# 1 "npb_egr_sf_proxy_top.p4" 1
# 1 "npb_egr_sf_proxy_hdr_strip.p4" 1

control npb_egr_sf_proxy_hdr_strip (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 action hdr_strip_1__from_vlan_tag0__to_eth() {
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();
 }

 action hdr_strip_1__from_vlan_tag0__to_e_tag() {

  hdr_1.e_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();

 }

 action hdr_strip_1__from_vlan_tag0__to_vn_tag() {

  hdr_1.vn_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();

 }

 // --------------------------------

 action hdr_strip_1__from_vn_tag_____to_eth() {

  hdr_1.ethernet.ether_type = hdr_1.vn_tag.ether_type;
  hdr_1.vn_tag.setInvalid();

 }

 // --------------------------------

 action hdr_strip_1__from_e_tag______to_eth() {

  hdr_1.ethernet.ether_type = hdr_1.e_tag.ether_type;
  hdr_1.e_tag.setInvalid();

 }

 // --------------------------------

 action hdr_strip_2__from_vlan_tag0__to_eth() {
  // tag0 to eth
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;

  hdr_1.e_tag.setInvalid();


  hdr_1.vn_tag.setInvalid();

  hdr_1.vlan_tag[0].setInvalid();
 }

 // --------------------------------

 bool hdr_1_e_tag_isValid;
 bool hdr_1_vn_tag_isValid;

 table hdr_strip {
  key = {

   hdr_1.e_tag.isValid() : exact;


   hdr_1.vn_tag.isValid() : exact;

   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;


   eg_md.nsh_md.strip_tag_e : ternary;


   eg_md.nsh_md.strip_tag_vn : ternary;

   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
   hdr_strip_1__from_e_tag______to_eth();
   hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet



   // case 0 (---- + vlan delete, only vlan          are valid):
   (false, false, true, _, _, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

   // case 1 (e/vn + ---- delete, only e/vn          are valid):
   (true, false, false, true, _, _ ): hdr_strip_1__from_e_tag______to_eth(); // pkt: 0   tags + e  ==> delete e        (e    to eth)
   (false, true, false, _, true, _ ): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

   // case 2 (---  + vlan delete, both e/vn and vlan are valid):
   (true, false, true, false, _, true ): hdr_strip_1__from_vlan_tag0__to_e_tag(); // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)
   (false, true, true, _, false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag(); // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

   // case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
   (true, false, true, true, _, false): hdr_strip_1__from_e_tag______to_eth(); // pkt: 1-2 tags + e  ==> delete e        (e    to eth)
   (false, true, true, _, true, false): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

   // case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
   (true, false, true, true, _, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)
   (false, true, true, _, true, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)
# 193 "npb_egr_sf_proxy_hdr_strip.p4"
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {

   hdr_1_e_tag_isValid = hdr_1.e_tag.isValid();





   hdr_1_vn_tag_isValid = hdr_1.vn_tag.isValid();




  hdr_strip.apply();
 }

}
# 2 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_hdr_edit.p4" 1

control npb_egr_sf_proxy_hdr_edit (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 bit<3> pcp_ = 0;
 vlan_id_t vid_ = 0;

 bool hdr_1_ethernet_isEtypeStag;
 bool hdr_1_e_tag_isEtypeStag;
 bool hdr_1_vn_tag_isEtypeStag;

 // -----------------------------------------------------------------
 // Table: bd_to_vlan_mapping
 // -----------------------------------------------------------------

    action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {
  pcp_ = pcp;
  vid_ = vid;
    }

    table bd_to_vlan_mapping {
        key = { eg_md.nsh_md.add_tag_vlan_bd : exact @name("bd"); }
        actions = {
   set_vlan_tagged;
   NoAction;
        }

        const default_action = NoAction;
        size = 512;
    }

 // -----------------------------------------------------------------
 // Table: hdr_add
 // -----------------------------------------------------------------

 // helper action
 action hdr_add_vlan_tag(vlan_id_t vid, bit<3> pcp) {
  // copy from 0 to 1
//		hdr_1.vlan_tag[1].setValid(); // will be set by the individual actions
  hdr_1.vlan_tag[1].pcp = hdr_1.vlan_tag[0].pcp;
  hdr_1.vlan_tag[1].cfi = hdr_1.vlan_tag[0].cfi;
  hdr_1.vlan_tag[1].vid = hdr_1.vlan_tag[0].vid;
  hdr_1.vlan_tag[1].ether_type = hdr_1.vlan_tag[0].ether_type;

  // add 0
  hdr_1.vlan_tag[0].setValid(); // might already be valid, which is fine
  hdr_1.vlan_tag[0].pcp = pcp;
  hdr_1.vlan_tag[0].cfi = 0;
  hdr_1.vlan_tag[0].vid = vid;
//		hdr_1.vlan_tag[0].ether_type = ?; // will be set by the individual actions
 }

 // --------------------------------

 action hdr_add_0__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_0__from_e_tag___to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;

 }

 action hdr_add_0__from_vn_tag__to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;

 }

 // --------------------------------

 action hdr_add_1__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_1__from_e_tag___to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;

 }

 action hdr_add_1__from_vn_tag__to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;

 }

 // --------------------------------

 table hdr_add {
  key = {
   hdr_1_ethernet_isEtypeStag : exact;

   hdr_1.e_tag.isValid() : exact;
   hdr_1_e_tag_isEtypeStag : exact;


   hdr_1.vn_tag.isValid() : exact;
   hdr_1_vn_tag_isEtypeStag : exact;

   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
   hdr_add_0__from_e_tag___to_vlan_tag0();
   hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
   hdr_add_1__from_e_tag___to_vlan_tag0();
   hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4



   // ====   =============   =============   =====    =====
   // eth    e               vn              vl[0]    vl[1]
   // ====   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (false, false, false, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, true, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, false, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, true, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (false, false, false, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, true, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, false, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, true, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

   // case 2 (e/vn to vlan)
   (false, true, false, false, false, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty
   (false, true, false, false, true, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

   (false, false, false, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
   (false, false, true, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

   // case 3 (e/vn to vlan)
   (false, true, false, false, false, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full
   (false, true, false, false, true, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full

   (false, false, false, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
   (false, false, true, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
# 259 "npb_egr_sf_proxy_hdr_edit.p4"
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
  if(hdr_1.ethernet.ether_type == 0x88a8) hdr_1_ethernet_isEtypeStag = true; else hdr_1_ethernet_isEtypeStag = false;

  if(hdr_1.e_tag.ether_type == 0x88a8) hdr_1_e_tag_isEtypeStag = true; else hdr_1_e_tag_isEtypeStag = false;


  if(hdr_1.vn_tag.ether_type == 0x88a8) hdr_1_vn_tag_isEtypeStag = true; else hdr_1_vn_tag_isEtypeStag = false;



  if(bd_to_vlan_mapping.apply().hit) {
   hdr_add.apply();
  }

 }

}
# 3 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_truncate.p4" 1

control npb_egr_sf_proxy_truncate (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
    if(eg_md.nsh_md.truncate_enable) {

        eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;

        }

 }

}
# 4 "npb_egr_sf_proxy_top.p4" 2
//#include "npb_egr_sf_proxy_meter.p4"




# 1 "acl.p4" 1
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
 ******************************************************************************/
# 10 "npb_egr_sf_proxy_top.p4" 2

control npb_egr_sf_proxy_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 EgressAcl(
  EGRESS_IPV4_ACL_TABLE_SIZE,


  EGRESS_IPV6_ACL_TABLE_SIZE,

  EGRESS_MAC_ACL_TABLE_SIZE
 ) acl;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: policy
 //   [1:1] act #2: header strip
 //   [2:2] act #3: header edit
 //   [3:3] act #4: truncate
 //   [4:4] act #5: meter
 //   [5:5] act #6: dedup

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 bit<8> int_ctrl_flags = 0;

 action egr_sf_action_sel_hit(
//		bit<6>                                                action_bitmask,



  bit<10> dsap
//		bit<NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id,
//		bit<8>                                                action_3_meter_overhead
//		bit<3>                                                discard
 ) {
//		eg_md.action_bitmask          = action_bitmask;



  eg_md.nsh_md.dsap = dsap;

//		eg_md.action_3_meter_id       = action_3_meter_id;
//		eg_md.action_3_meter_overhead = action_3_meter_overhead;

//		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // =====================================

 action egr_sf_action_sel_miss(
 ) {
//		eg_md.action_bitmask          = 0;
//		int_ctrl_flags                = 0;
//		eg_md.nsh_md.dsap             = 0;
 }

 // =====================================

 table egr_sf_action_sel {
  key = {
      hdr_0.nsh_type1.spi : exact @name("spi");
      hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   NoAction;
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }

  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #x: Ip Length Range
 // =========================================================================

 bit<16> ip_len = 0;
 bool ip_len_is_rng_bitmask = false;


 action egr_sf_ip_len_rng_hit(
  bit<16> rng_bitmask
 ) {
  ip_len = rng_bitmask;
  ip_len_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_ip_len_rng_miss(
 ) {
  ip_len = eg_md.lkp_1.ip_len;
  ip_len_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_ip_len_rng {
  key = {
   eg_md.lkp_1.ip_len : range @name("ip_len");
  }

  actions = {
   NoAction;
   egr_sf_ip_len_rng_hit;
   egr_sf_ip_len_rng_miss;
  }

  const default_action = egr_sf_ip_len_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Src Port Range
 // =========================================================================

 bit<16> l4_src_port = 0;
 bool l4_src_port_is_rng_bitmask = false;


 action egr_sf_l4_src_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_src_port = rng_bitmask;
  l4_src_port_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_l4_src_port_rng_miss(
 ) {
  l4_src_port = eg_md.lkp_1.l4_src_port;
  l4_src_port_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_l4_src_port_rng {
  key = {
   eg_md.lkp_1.l4_src_port : range @name("l4_src_port");
  }

  actions = {
   NoAction;
   egr_sf_l4_src_port_rng_hit;
   egr_sf_l4_src_port_rng_miss;
  }

  const default_action = egr_sf_l4_src_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Dst Port Range
 // =========================================================================

 bit<16> l4_dst_port = 0;
 bool l4_dst_port_is_rng_bitmask = false;


 action egr_sf_l4_dst_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_dst_port = rng_bitmask;
  l4_dst_port_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_l4_dst_port_rng_miss(
 ) {
  l4_dst_port = eg_md.lkp_1.l4_dst_port;
  l4_dst_port_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_l4_dst_port_rng {
  key = {
   eg_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
   NoAction;
   egr_sf_l4_dst_port_rng_hit;
   egr_sf_l4_dst_port_rng_miss;
  }

  const default_action = egr_sf_l4_dst_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  eg_md.nsh_md.dsap = 0;

  // ==================================
  // Action Lookup
  // ==================================

  if(egr_sf_action_sel.apply().hit) {

   // ==================================
   // Decrement SI
   // ==================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // ==================================
   // Actions(s)
   // ==================================

//			if(eg_md.action_bitmask[0:0] == 1) {

    // ----------------------------------
    // Action #0 - Policy
    // ----------------------------------


    egr_sf_ip_len_rng.apply();





    egr_sf_l4_src_port_rng.apply();





    egr_sf_l4_dst_port_rng.apply();





    acl.apply(
     eg_md.lkp_1,
     eg_md,
     eg_intr_md_for_dprsr,
     ip_len,
     ip_len_is_rng_bitmask,
     l4_src_port,
     l4_src_port_is_rng_bitmask,
     l4_dst_port,
     l4_dst_port_is_rng_bitmask,
     hdr_0,
     hdr_1,
     int_ctrl_flags
    );
//			}

//			if(eg_md.action_bitmask[1:1] == 1) {

    // ----------------------------------
    // Action #1 - Hdr Strip
    // ----------------------------------
    npb_egr_sf_proxy_hdr_strip.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

//			}

//			if(eg_md.action_bitmask[2:2] == 1) {

    // ----------------------------------
    // Action #2 - Hdr Edit
    // ----------------------------------
    npb_egr_sf_proxy_hdr_edit.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

//			}

//			if(eg_md.action_bitmask[3:3] == 1) {

    // ----------------------------------
    // Action #3 - Truncate
    // ----------------------------------
    npb_egr_sf_proxy_truncate.apply (
     hdr_0,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

//			}

//			if(eg_md.action_bitmask[4:4] == 1) {

    // ----------------------------------
    // Action #4 - Meter
    // ----------------------------------
# 362 "npb_egr_sf_proxy_top.p4"
//			}

//			if(eg_md.action_bitmask[5:5] == 1) {

    // ----------------------------------
    // Action #5 - Deduplication
    // ----------------------------------
# 379 "npb_egr_sf_proxy_top.p4"
//			}

  }
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
/*
control npb_egr_sf_proxy_top_part2 (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: unused (was header strip)
	//   [1:1] act #2: unused (was header edit)
	//   [2:2] act #3: unused (reserved for truncate)
	//   [3:3] act #4: meter
	//   [4:4] act #5: dedup

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.nsh_md.sf_bitmask[2:2] == 1) {

			// ==================================
			// Actions(s)
			// ==================================

			if(eg_md.action_bitmask[0:0] == 1) {

				// ----------------------------------
				// Action #0 - Policy
				// ----------------------------------

#ifdef SF_2_RNG_TABLE_ENABLE
				egr_sf_ip_len_rng.apply();
#endif

				// multiple small policy tables....
				acl.apply(
					eg_md.lkp,
					eg_md,
					eg_intr_md_for_dprsr,
					ip_len_rng_bitmask_internal
				);
			}

			if(eg_md.action_bitmask[1:1] == 1) {

				// ----------------------------------
				// Action #1 - Hdr Strip
				// ----------------------------------
				npb_egr_sf_proxy_hdr_strip.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[2:2] == 1) {

				// ----------------------------------
				// Action #2 - Hdr Edit
				// ----------------------------------
				npb_egr_sf_proxy_hdr_edit.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[3:3] == 1) {

				// ----------------------------------
				// Action #3 - Truncate
				// ----------------------------------
				npb_egr_sf_proxy_truncate.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[4:4] == 1) {

				// ----------------------------------
				// Action #4 - Meter
				// ----------------------------------
#ifdef SF_2_METER_ENABLE
				npb_egr_sf_proxy_meter.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}

			if(eg_md.action_bitmask[5:5] == 1) {

				// ----------------------------------
				// Action #5 - Deduplication
				// ----------------------------------
#ifdef SF_2_DEDUP_ENABLE
				npb_egr_sf_proxy_dedup.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}
		}
	}
}
*/
# 8 "npb_egr_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */







//#define DEPTH      32w131072
//#define DEPTH_POW2 17

//#define DEPTH      32w262144
//#define DEPTH_POW2 18



// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
 bit<16> hash;
 bit<16> data;
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
 in bit<16> flowtable_hash_lo, // address
 in bit<16> flowtable_hash_hi, // data -- always 16 bits
 in bit<16> ssap,

 out bit<3> duplicate
) {

 // =========================================================================
 // Register Array
 // =========================================================================

 // This code works similar to how vpp's flow collector works...on a hash
 // collision, the current flow occupying the slot is simply replaced with
 // the new flow (i.e. the old flow is simply booted out of the cache).

 Register <pair_t, bit<16>>(32w65536) test_reg; // syntax seems to be <data type, index type>

 // =========================================================================

 RegisterAction<pair_t, bit<16>, bit<3>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<3> return_value // return value
  ) {
   if(reg_value.hash == (bit<16>)flowtable_hash_hi) {
    // existing flow
    // --------
    if(reg_value.data == (bit<16>)ssap) {
     // same ssap
     // ---------
     return_value = 0; // pass packet
    } else {
     // different ssap
     // ---------
     return_value = 1; // drop packet
    }
   } else {
    // new flow (entry collision, overwrite old flow)
    // --------
    // update entry
    reg_value.hash = (bit<16>)flowtable_hash_hi;
    reg_value.data = (bit<16>)ssap;

    return_value = 0; // pass packet
   }
  }
 };

 // =========================================================================
 // Apply Block
 // =========================================================================

 apply {
  duplicate = register_array.execute(flowtable_hash_lo);
 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// Ingress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_hash (
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 out bit<32> hash
) {
 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 143 "npb_ing_sf_npb_basic_adv_dedup.p4"
  hash = h.get ({
   vpn,
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_src_port,
   lkp.l4_dst_port
  });
 }

}

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
 in bool enable,
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 in bit<32> hash,
 in bit<16> ssap, // for dedup
 inout bit<3> drop_ctl
) {
 npb_dedup_reg() npb_dedup_reg_0;
 npb_dedup_reg() npb_dedup_reg_1;
 npb_dedup_reg() npb_dedup_reg_2;
 npb_dedup_reg() npb_dedup_reg_3;
 npb_dedup_reg() npb_dedup_reg_4;
 npb_dedup_reg() npb_dedup_reg_5;
 npb_dedup_reg() npb_dedup_reg_6;
 npb_dedup_reg() npb_dedup_reg_7;
 npb_dedup_reg() npb_dedup_reg_8;
 npb_dedup_reg() npb_dedup_reg_9;
 npb_dedup_reg() npb_dedup_reg_10;
 npb_dedup_reg() npb_dedup_reg_11;
 npb_dedup_reg() npb_dedup_reg_12;
 npb_dedup_reg() npb_dedup_reg_13;
 npb_dedup_reg() npb_dedup_reg_14;
 npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

 // =========================================================================

 bit<32> flowtable_hash = 0;

 bit<16> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits
 bit<4> flowtable_hash_chk; // always 16 bits

 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 244 "npb_ing_sf_npb_basic_adv_dedup.p4"
/*
		flowtable_hash    = h.get ({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
		flowtable_hash_lo  = flowtable_hash[15: 0];
		flowtable_hash_hi  = flowtable_hash[31:16];
		flowtable_hash_chk = flowtable_hash[31:28];
*/
  flowtable_hash_lo = hash[15: 0];
  flowtable_hash_hi = hash[31:16];
  flowtable_hash_chk = hash[31:28];


  // note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
  // we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

  // ***** call dedup function *****
  if(enable) {
          if(flowtable_hash_chk == 0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   }

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			}
*/
  }
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// Egress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_proxy_dedup (
 in bool enable,
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 in bit<16> ssap, // for dedup
 inout bit<3> drop_ctl
) {
 npb_dedup_reg() npb_dedup_reg_0;
 npb_dedup_reg() npb_dedup_reg_1;
 npb_dedup_reg() npb_dedup_reg_2;
 npb_dedup_reg() npb_dedup_reg_3;
 npb_dedup_reg() npb_dedup_reg_4;
 npb_dedup_reg() npb_dedup_reg_5;
 npb_dedup_reg() npb_dedup_reg_6;
 npb_dedup_reg() npb_dedup_reg_7;
 npb_dedup_reg() npb_dedup_reg_8;
 npb_dedup_reg() npb_dedup_reg_9;
 npb_dedup_reg() npb_dedup_reg_10;
 npb_dedup_reg() npb_dedup_reg_11;
 npb_dedup_reg() npb_dedup_reg_12;
 npb_dedup_reg() npb_dedup_reg_13;
 npb_dedup_reg() npb_dedup_reg_14;
 npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

 // =========================================================================

 bit<32> flowtable_hash = 0;

 bit<16> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits
 bit<4> flowtable_hash_chk; // always 16 bits

 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 418 "npb_ing_sf_npb_basic_adv_dedup.p4"
  flowtable_hash = h.get ({
   vpn,
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_src_port,
   lkp.l4_dst_port
  });

  flowtable_hash_lo = flowtable_hash[15: 0];
  flowtable_hash_hi = flowtable_hash[31:16];
  flowtable_hash_chk = flowtable_hash[31:28];


  // note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
  // we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

  // ***** call dedup function *****
  if(enable) {
          if(flowtable_hash_chk == 0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   } else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
   }

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop_ctl);
			}
*/
  }
 }
}
# 9 "npb_egr_top.p4" 2

# 1 "scoper.p4" 1
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
 ******************************************************************************/
# 11 "npb_egr_top.p4" 2

control npb_egr_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,

 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {





 TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // -------------------------------------
  // Ingress Dedup (continued from ingress side)
  // -------------------------------------
# 74 "npb_egr_top.p4"
  // -------------------------------------
  // SFF Part 1 --> *** before reframing ***
  // -------------------------------------

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SFF != 0)) {
   npb_egr_sff_top_part1.apply (
    hdr_0,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
  }

  // -------------------------------------
  // Set Initial Scope
  // -------------------------------------

  if(hdr_0.nsh_type1.scope == 0) {

   // do nothing
# 106 "npb_egr_top.p4"
   // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
//			eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
//			eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE;

  } else {

   // do nothing
# 123 "npb_egr_top.p4"
   // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
//			eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
//			eg_md.lkp_1.tunnel_inner_type = eg_md.tunnel_1.type;

  }

  // -------------------------------------
  // SF(s): Part 1 --> *** before reframing ***
  // -------------------------------------

  npb_egr_sf_multicast_top_part2.apply (
   hdr_0,
   eg_intr_md.egress_rid,
   eg_intr_md.egress_port,
   eg_md
  );

  // -------------------------------------

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SF_ACL != 0)) {
   npb_egr_sf_proxy_top.apply (
    hdr_0,
    hdr_1,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
  }

  // -------------------------------------
  // SFF Reframing
  // -------------------------------------

  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);

  // -------------------------------------
  // SF(s): Part 2 --> *** after reframing ***
  // -------------------------------------
/*
		npb_egr_sf_proxy_top_part2.apply (
			hdr_0,
			hdr_1,
			eg_md,
			eg_intr_md,
			eg_intr_md_from_prsr,
			eg_intr_md_for_dprsr,
			eg_intr_md_for_oport
		);
*/
  // -------------------------------------
  // SFF: Part 2 --> *** after reframing ***
  // -------------------------------------

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SFF != 0)) {
   npb_egr_sff_top_part2.apply (
    hdr_0,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
  }

 }
}
# 64 "npb.p4" 2
# 1 "npb_egr_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_egr_deparser.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/
# 23 "npb_egr_deparser.p4" 2

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.

    Mirror() mirror;


    apply {

        if (eg_intr_md_for_dprsr.mirror_type == 1) {
# 51 "npb_egr_deparser.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
# 63 "npb_egr_deparser.p4"
        }

    }
}

//-----------------------------------------------------------------------------

control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

 EgressMirror() mirror;



    Checksum() ipv4_checksum_outer;

    apply {
  mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
# 103 "npb_egr_deparser.p4"
        if (hdr.outer.ipv4.isValid()) {

            hdr.outer.ipv4.hdr_checksum = ipv4_checksum_outer.update({
                    hdr.outer.ipv4.version,
                    hdr.outer.ipv4.ihl,
                    hdr.outer.ipv4.tos,
                    hdr.outer.ipv4.total_len,
                    hdr.outer.ipv4.identification,
                    hdr.outer.ipv4.flags,
                    hdr.outer.ipv4.frag_offset,
                    hdr.outer.ipv4.ttl,
                    hdr.outer.ipv4.protocol,
                    hdr.outer.ipv4.src_addr,
                    hdr.outer.ipv4.dst_addr});
        }


        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);
# 143 "npb_egr_deparser.p4"
        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);




  pkt.emit(hdr.cpu);


        pkt.emit(hdr.outer.e_tag);


        pkt.emit(hdr.outer.vn_tag);

        pkt.emit(hdr.outer.vlan_tag);




        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        pkt.emit(hdr.outer.vxlan);

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        pkt.emit(hdr.outer.nvgre);


        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);

        pkt.emit(hdr.outer.dtel); // Egress only.
        pkt.emit(hdr.outer.dtel_report); // Egress only.
        pkt.emit(hdr.outer.dtel_switch_local_report); // Egress only.
        pkt.emit(hdr.outer.dtel_drop_report); // Egress only.

        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        pkt.emit(hdr.inner.ipv6);

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);

        pkt.emit(hdr.inner.gre);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);


    }
}
# 65 "npb.p4" 2


# 1 "npb_ing_hdr_stack_counters.p4" 1
control IngressHdrStackCounters(
    in switch_header_t hdr
) {


    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) udf_hdr_cntrs;



    // ------------------------------------------------------------
    // local variables to support ifdefs

    // error: PHV allocation creates an invalid container action within a Tofino ALU
    // bool hdr_transport_ipv4_isValid;
    // bool hdr_transport_gre_isValid;
    // bool hdr_transport_gre_sequence_isValid;
    // bool hdr_transport_erspan_type2_isValid;

    bool hdr_outer_ipv6_isValid;
    bool hdr_inner_ipv6_isValid;

    bool hdr_inner_gtp_v1_base_isValid;
    bool hdr_inner_gtp_v1_optional_isValid;
    bool hdr_inner_gre_isValid;




    // ------------------------------------------------------------
    // CPU Header -------------------------------------------------
    // ------------------------------------------------------------

    action bump_cpu_hdr_cntr() {
        cpu_hdr_cntrs.count();
    }

    table cpu_hdr_cntr_tbl {
        key = {
            hdr.cpu.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_cpu_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_cpu_hdr_cntr;
        counters = cpu_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_cpu_hdr_cntr; 
//             true:  bump_cpu_hdr_cntr; 
//         }
    }





    // ------------------------------------------------------------
    // transport stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr.transport.ethernet.isValid(): exact;
            hdr.transport.vlan_tag[0].isValid(): exact;
            hdr.transport.nsh_type1.isValid(): exact;
            // hdr_transport_ipv4_isValid: exact;
            // hdr_transport_gre_isValid: exact;
            // hdr_transport_gre_sequence_isValid: exact;
            // hdr_transport_erspan_type2_isValid: exact;

            hdr.transport.ipv4.isValid(): exact;
            hdr.transport.gre.isValid(): exact;

            hdr.transport.gre_sequence.isValid(): exact;
            hdr.transport.erspan_type2.isValid(): exact;


        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }


        size = 9;






        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_transport_stack_hdr_cntr;
        // const default_action = bump_transport_stack_unexpected_hdr_cntr;
        counters = transport_stack_hdr_cntrs;

        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//
//             //enet  vlan0   nsh    ipv4   gre    greSeq erspan 
// 
//             // None
//             ( false, false, false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, false ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE1
//             ( true,  false, false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE2
//             ( true,  false, false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//
// #elif defined(GRE_TRANSPORT_INGRESS_ENABLE)
//
//             //enet  vlan0   nsh    ipv4   gre
// 
//             // None
//             ( false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true  ): bump_transport_stack_hdr_cntr;
// 
// #else
// 
//             //enet  vlan0   nsh
// 
//             // None
//             ( false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true  ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false ): bump_transport_stack_hdr_cntr;
// 
// #endif // #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//         }
    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }

    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr.outer.ethernet.isValid(): exact;

            hdr.outer.e_tag.isValid(): exact;


            hdr.outer.vn_tag.isValid(): exact;

            hdr.outer.vlan_tag[0].isValid(): exact;
            hdr.outer.vlan_tag[1].isValid(): exact;

            hdr.outer.ipv4.isValid(): exact;
            hdr_outer_ipv6_isValid: exact;

            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;

            hdr.outer.gre.isValid(): exact;
            hdr.outer.gre_optional.isValid(): exact;

            hdr.outer.vxlan.isValid(): exact;


            hdr.outer.nvgre.isValid(): exact;

            hdr.outer.gtp_v1_base.isValid(): exact;
            hdr.outer.gtp_v1_optional.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        counters = outer_stack_hdr_cntrs;

// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     1



        size = 210; // was 190 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // None (invalid)                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2                                                                                  
        //     ( true,  false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV4                                                                           
        //     ( true,  false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV6                                                                           
        //     ( true,  false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / UDP                                                                      
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / TCP                                                                       
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / SCTP                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / GRE                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                             
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 

        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / L4 / VXLAN                                                               
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / NVGRE
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U                                                                
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                             
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // IPV4                                                                               
        //     ( false, false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // IPV6                                                                                
        //     ( false, false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / UDP                                                                            
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / TCP                                                                            
        //     ( false, false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / SCTP                                                                           
        //     ( false, false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                            
        //     // L3 / GRE                                                                            
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / VXLAN                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / NVGRE                                                                     
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U w/ Sequence Number                                                  
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }





// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     0
//   1      1      0     1
# 747 "npb_ing_hdr_stack_counters.p4"
// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     1
//   0      1      1     1        
# 1041 "npb_ing_hdr_stack_counters.p4"
// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     0
//   1      0      0     1
//   0      1      1     0
//   0      1      0     1
# 1276 "npb_ing_hdr_stack_counters.p4"
    }


    // ------------------------------------------------------------
    // inner stack ------------------------------------------------
    // ------------------------------------------------------------

    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }

    table inner_stack_hdr_cntr_tbl {
        key = {

            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            hdr.inner.ipv4.isValid(): exact;
            hdr.inner.ipv6.isValid(): exact;

            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;


            hdr.inner.gre.isValid(): exact;


            hdr.inner.gtp_v1_base.isValid(): exact;
            hdr.inner.gtp_v1_optional.isValid(): exact;

        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        counters = inner_stack_hdr_cntrs;




        size = 45; // Was 47 prior to removing arp
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre    gtp_v1 gtp_v1_opt
        // 
        //     // None (invalid)
        //     ( false, false, false, false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2
        //     ( true,  false, false, false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3
        //     ( true,  false, true,  false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP
        //     ( true,  false, true,  false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / TCP
        //     ( true,  false, true,  false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / SCTP
        //     ( true,  false, true,  false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / GRE
        //     ( true,  false, true,  false, false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP / GTP-U
        //     ( true,  false, true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP / GTP-U w/ Sequence Number
        //     ( true,  false, true,  false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3
        //     ( false, false, true,  false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP
        //     ( false, false, true,  false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / TCP
        //     ( false, false, true,  false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / SCTP
        //     ( false, false, true,  false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / GRE
        //     ( false, false, true,  false, false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP / GTP-U
        //     ( false, false, true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP / GTP-U w/ Sequence Number
        //     ( false, false, true,  false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        // }
# 1631 "npb_ing_hdr_stack_counters.p4"
    }





    // ------------------------------------------------------------
    // Layer7 UDF -------------------------------------------------
    // ------------------------------------------------------------

    action bump_udf_hdr_cntr() {
        udf_hdr_cntrs.count();
    }

    table udf_hdr_cntr_tbl {
        key = {
            hdr.udf.isValid(): exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_udf_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_udf_hdr_cntr;
        counters = udf_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_udf_hdr_cntr; 
//             true:  bump_udf_hdr_cntr; 
//         }
    }



    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

    // Stubs (for #defines)

// error: PHV allocation creates an invalid container action within a Tofino ALU
// #if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//     hdr_transport_ipv4_isValid = hdr.transport.ipv4.isValid();
//     hdr_transport_gre_isValid = hdr.transport.gre.isValid();
// #else
//     hdr_transport_ipv4_isValid = false;
//     hdr_transport_gre_isValid = false;
// #endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//         
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//     hdr_transport_gre_sequence_isValid = hdr.transport.gre_sequence.isValid();
//     hdr_transport_erspan_type2_isValid = hdr.transport.erspan_type2.isValid();
// #else
//     hdr_transport_gre_sequence_isValid = false;
//     hdr_transport_erspan_type2_isValid = false;
// #endif // ERSPAN_TRANSPORT_INGRESS_ENABLE



        hdr_outer_ipv6_isValid = hdr.outer.ipv6.isValid();
        hdr_inner_ipv6_isValid = hdr.inner.ipv6.isValid();







        hdr_inner_gtp_v1_base_isValid = hdr.inner.gtp_v1_base.isValid();
        hdr_inner_gtp_v1_optional_isValid = hdr.inner.gtp_v1_optional.isValid();






        hdr_inner_gre_isValid = hdr.inner.gre.isValid();






        // Tables

        cpu_hdr_cntr_tbl.apply();

        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();

        udf_hdr_cntr_tbl.apply();

    }

}
# 68 "npb.p4" 2


//@pa_auto_init_metadata

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchIngress(
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // ---------------------------------------------------------------------

 IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE, PORT_TABLE_SIZE, VLAN_TABLE_SIZE) ingress_port_mapping;






 DMAC(MAC_TABLE_SIZE) dmac;

//	IngressBd(BD_TABLE_SIZE) bd_stats;
//	IngressUnicast(RMAC_TABLE_SIZE) unicast;
 Ipv4Hash() ipv4_hash;
 Ipv6Hash() ipv6_hash;
 NonIpHash() non_ip_hash;
// 	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
 Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
 OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
 LAG() lag;
   IngressDtel() dtel;

 // ---------------------------------------------------------------------

 apply {

  ig_intr_md_for_dprsr.drop_ctl = 0; // no longer present in latest switch.p4
  ig_md.multicast.id = 0; // no longer present in latest switch.p4





  IngressSetLookup.apply(hdr, ig_md); // set lookup structure fields that parser couldn't        


  IngressHdrStackCounters.apply(hdr);


  // -----------------------------------------------------
# 143 "npb.p4"
  ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

//		unicast.apply(hdr.transport, ig_md);


  if((ig_md.flags.rmac_hit == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
   // ----- Bridging Path -----

 // the new parser puts bridging in outer

   dmac.apply(ig_md.lkp_1.mac_dst_addr, ig_md);




  } else {
   // ----- NPB Path -----

   npb_ing_top.apply (
    hdr.transport,
    ig_md.tunnel_0,
    hdr.outer,
    ig_md.tunnel_1,
    hdr.inner,
    ig_md.tunnel_2,
    hdr.inner_inner,
    hdr.udf,

    ig_md,
    ig_intr_md,
    ig_intr_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

  }
# 187 "npb.p4"
  HashMask.apply(ig_md.lkp_1, ig_md.egress_port_lag_hash_sel);

  if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
   non_ip_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else {
   ipv6_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  }


  // this code should be removed if lag hash masking ever fits
  nexthop.apply(ig_md);
  outer_fib.apply(ig_md);






  if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
  } else {
//			lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
   lag.apply(ig_md, ig_md.hash[32 -1:32/2], ig_intr_md_for_tm.ucast_egress_port);
  }

  IngressCopp.apply(ig_md.copp_enable, ig_md.copp_meter_id, ig_md, ig_intr_md_for_tm);

  // Only add bridged metadata if we are NOT bypassing egress pipeline.
  if (ig_intr_md_for_tm.bypass_egress == 1w0) {
   add_bridged_md(hdr.bridged_md, ig_md);
  }

//		ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
  dtel.apply(hdr.outer, ig_md.lkp_1, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

  set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
# 235 "npb.p4"
 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchEgress(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -------------------------------------------------------------------------

 EgressSetLookup() egress_set_lookup;
 EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
 VlanDecap() vlan_decap;
 Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
 TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
 TunnelRewrite() tunnel_rewrite;
 VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
//	NSHTypeFixer() nsh_type_fixer;
//	MulticastReplication(RID_TABLE_SIZE) multicast_replication;
 MulticastReplication(NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE) multicast_replication;
   EgressDtel() dtel;
   DtelConfig() dtel_config;

 // -------------------------------------------------------------------------

 apply {

//		eg_intr_md_for_dprsr.drop_ctl = 0;
  eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];

  egress_set_lookup.apply(hdr, eg_md); // set lookup structure fields that parser couldn't                

  egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

  multicast_replication.apply (
   hdr.transport,
   eg_intr_md.egress_rid,
   eg_intr_md.egress_port,
   eg_md
  );




  if((eg_md.flags.rmac_hit == false) && (eg_md.nsh_md.l2_fwd_en == true)) {
   // do nothing (bridging the packet)
  } else {

   npb_egr_top.apply (
    hdr.transport,
    eg_md.tunnel_0,
    hdr.outer,
    eg_md.tunnel_1,
    hdr.inner,
    eg_md.tunnel_2,
    hdr.inner_inner,

    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );

  }


  // nexthop                code: operates on 'outer'
  rewrite.apply(hdr.outer, eg_md, eg_md.tunnel_0);

  // outer nexthop (tunnel) code: operates on 'transport'
  vlan_decap.apply(hdr.transport, eg_md);
  tunnel_encap.apply(hdr.transport, hdr.outer, eg_md, eg_md.tunnel_0);
  tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
  if (eg_md.tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE) { // derek added this check
   vlan_xlate.apply(hdr.transport, eg_md);
  }

  EgressCopp.apply(eg_md.copp_enable, eg_md.copp_meter_id, eg_md, eg_intr_md_for_dprsr);

  dtel.apply(hdr.outer, hdr.transport.nsh_type1.timestamp, eg_md, eg_intr_md, eg_md.dtel.hash);
  dtel_config.apply(hdr.outer, hdr.transport.nsh_type1.timestamp, eg_md, eg_intr_md_for_dprsr);

  set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);


 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
