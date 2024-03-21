# 1 "./switch_tofino2_y0.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "./switch_tofino2_y0.p4"
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

# 1 "/p4factory/install/share/p4c/p4include/core.p4" 1
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
# 24 "./switch_tofino2_y0.p4" 2
# 1 "/p4factory/install/share/p4c/p4include/t2na.p4" 1

# 1 "/p4factory/install/share/p4c/p4include/tofino2arch.p4" 1



# 1 "/p4factory/install/share/p4c/p4include/core.p4" 1
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
# 5 "/p4factory/install/share/p4c/p4include/tofino2arch.p4" 2
# 1 "/p4factory/install/share/p4c/p4include/tofino2.p4" 1



/**
 Version Notes:

 0.6.0:
 - Initial release
 0.6.1:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH

*/

# 1 "/p4factory/install/share/p4c/p4include/core.p4" 1
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
# 15 "/p4factory/install/share/p4c/p4include/tofino2.p4" 2

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
typedef bit<4> MirrorType_t; // Mirror type
typedef bit<8> MirrorId_t; // Mirror id
typedef bit<3> ResubmitType_t; // Resubmit type
typedef bit<3> DigestType_t; // Digest type
typedef bit<16> ReplicationId_t; // Replication id

// CloneId_t will be deprecated in 9.4. Adding a typedef for any old references.
typedef MirrorType_t CloneId_t;

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w192;

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
    @padding bit<7> _pad0;

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

    @padding bit<1> _pad6;

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
    void count(in I index, @optional in bit<32> adjust_byte_count);
}

/// DirectCounter
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
# 6 "/p4factory/install/share/p4c/p4include/tofino2arch.p4" 2

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

@pkginfo(arch="T2NA", version="0.6.1")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 3 "/p4factory/install/share/p4c/p4include/t2na.p4" 2
# 25 "./switch_tofino2_y0.p4" 2

//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
// L2 Unicast

//#define STORM_CONTROL_ENABLE

// L3 Unicast



// ACLs




// Mirror
# 52 "./switch_tofino2_y0.p4"
// QoS

// #define QOS_ACL_ENABLE





// DTEL






// SFC


//#define SFC_GHOST_DISABLE
//#define SFC_TRIGGER_DISABLE
//#define SFC_TRIGGER_ALWAYS



//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------



// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 16384;

// IP Hosts/Routes
const bit<32> IPV4_HOST_TABLE_SIZE = 65536/2;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 16384/2;
const bit<32> IPV4_LPM_TABLE_SIZE = 32*1024/2;
const bit<32> IPV6_HOST_TABLE_SIZE = 192512/2;
const bit<32> IPV6_LPM_TABLE_SIZE = 16384/2;
const bit<32> IPV6_LPM64_TABLE_SIZE = 16384/2;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE = 32768;

const bit<32> NEXTHOP_TABLE_SIZE = 1 << 14;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;

// Egress ACLs
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// SFC / GHOST

const bit<32> SFC_QUEUE_IDX_SIZE = 512;
const bit<32> SFC_BUFFER_IDX_SIZE = 4;
const bit<32> SFC_PORT_CNT = 256;
const bit<32> SFC_TC_CNT = 8;
const bit<32> SFC_PAUSE_DURATION_SIZE = 1024;
const bit<32> SFC_PAUSE_DURATION_US = 2_000_000; // time in us

const bit<32> SFC_QUEUE_REG_STAGE_QD = 10;


const bit<32> sfc_suppression_filter_cnt = 1 << 16;

const bit<32> SIGNALING_DETECT_TABLE_SIZE = 8;


# 1 "../shared/headers.p4" 1
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

@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.$valid", 16)
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

header pfc_h {
    bit<16> opcode;
    bit<8> reserved_zero;
    bit<8> class_enable_vec;
    bit<16> tstamp0;
    bit<16> tstamp1;
    bit<16> tstamp2;
    bit<16> tstamp3;
    bit<16> tstamp4;
    bit<16> tstamp5;
    bit<16> tstamp6;
    bit<16> tstamp7;
    @padding
    bit<208> pad;
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

// Router Alert IP option -- RFC 2113, RFC 2711
header router_alert_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
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
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
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

// RDMA over Converged Ethernet (RoCEv2)
header rocev2_bth_h {
    bit<8> opcode;
    bit<1> se;
    bit<1> migration_req;
    bit<2> pad_count;
    bit<4> transport_version;
    bit<16> partition_key;
    bit<1> f_res1;
    bit<1> b_res1;
    bit<6> reserved;
    bit<24> dst_qp;
    bit<1> ack_req;
    bit<7> reserved2;
    bit<24> psn;
}

// Fiber Channel over Ethernet (FCoE)
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof; // Start of frame

    bit<8> r_ctl; // Routing control
    bit<24> d_id; // Destination identifier
    bit<8> cs_ctl; // Class specific control
    bit<24> s_id; // Source identifier
    bit<8> type;
    bit<24> f_ctl; // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt; // Sequence count
    bit<16> ox_id; // Originator exchange id
    bit<16> rx_id; // Responder exchange id
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

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
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

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

// ERSPAN common header for type 2/3
header erspan_h {
    bit<16> version_vlan;
    bit<16> session_id; // include cos_en_t(6) and session_id(10)
}

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<32> index; // include reserved(12) and index(20)
}

// ERSPAN Type III -- IETFv3
header erspan_type3_h {
    bit<32> timestamp;
    bit<32> ft_d_other;
    /*
    bit<16> sgt;    // Security group tag
    bit<1>  p;
    bit<5> ft;      // Frame type
    bit<6> hw_id;
    bit<1> d;       // Direction
    bit<2> gra;     // Timestamp granularity
    bit<1> o;       // Optional sub-header
    */
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}

// Generic Network Virtualization Encapsulation (Geneve)
header geneve_h {
    bit<2> version;
    bit<6> opt_len;
    bit<1> oam;
    bit<1> critical;
    bit<6> reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8> opt_type;
    bit<3> reserved;
    bit<5> opt_len;
}

// Bidirectional Forwarding Detection (BFD) -- RFC 5880
header bfd_h {
    bit<3> version;
    bit<5> diag;
    bit<8> flags;
    bit<8> detect_multi;
    bit<8> len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

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

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;




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

// Telemetry report header -- version 2.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v2_0.pdf
header dtel_report_v20_h {
    bit<4> version;
    // Telemetry Report v2.0 hw_id is 6 bits, however due to p4 constraints,
    // shrinking it to 4 bits
    bit<4> hw_id;
    // Telemetry Report v2.0 seq_number is 22 bits, however due to p4
    // constraints, expanding it to 24 bits, always leaving the top 2 bits as 0
    bit<24> seq_number;
    bit<32> switch_id;
    // Due to p4 constraints, need to treat the following as one field:
    // bit<4> rep_type;
    // bit<4> in_type;
    // bit<16> report_length;
    bit<16> report_length;
    bit<8> md_length;
    bit<3> d_q_f;
    bit<5> reserved;
    bit<16> rep_md_bits;
    bit<16> domain_specific_id;
    bit<16> ds_md_bits;
    bit<16> ds_md_status;
}

// Optional metadata present in the telemetry report.
header dtel_metadata_1_h {



    bit<7> pad0;

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;
}

header dtel_metadata_2_h {
    bit<32> hop_latency;
}

header dtel_metadata_3_h {




    bit<1> pad2;
    bit<7> queue_id;

    bit<5> pad3;
    bit<19> queue_occupancy;
}

header dtel_metadata_4_h {
    bit<16> pad;
    bit<48> ingress_timestamp;
}

header dtel_metadata_5_h {
    bit<16> pad;
    bit<48> egress_timestamp;
}

header dtel_report_metadata_15_h {




    bit<1> pad;
    bit<7> queue_id;

    bit<8> drop_reason;
    bit<16> reserved;
}

// Barefoot Specific Headers.
header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

// SFC header
// TODO: add header here
header sfc_pause_h {
    bit<8> version;
    bit<8> pause_tc;
    bit<16> pause_duration;
    // TODO: padding to 64-byte packet
    // Ethernet + IP + UDP + required fields = 14 + 20 + 8 + 4 = 46
    @padding
    bit<112> pad_0;
}

// CPU header
header cpu_h {
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<5> egress_queue;
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

header timestamp_h {
    bit<48> timestamp;
}
# 139 "./switch_tofino2_y0.p4" 2
# 1 "../shared/types.p4" 1
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
# 38 "../shared/types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
# 58 "../shared/types.p4"
// proshare-mc-2    1674, Intel Proshare Multicast
# 73 "../shared/types.p4"
// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------

const bit<32> MIN_TABLE_SIZE = 512;

const bit<32> LAG_TABLE_SIZE = 1024;
const bit<32> LAG_GROUP_TABLE_SIZE = 256;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 16384; // 256 * 64

const bit<32> ECMP_MAX_MEMBERS_PER_GROUP = 64;

const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;





typedef PortId_t switch_port_t;




const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef bit<7> switch_port_padding_t;


typedef QueueId_t switch_qid_t;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_ifindex_t;
typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf




typedef bit<8> switch_vrf_t;




typedef bit<14> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;




typedef bit<10> switch_user_metadata_t;






typedef bit<32> switch_hash_t;
# 191 "../shared/types.p4"
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;




typedef bit<32> switch_ig_port_lag_label_t;

typedef bit<16> switch_eg_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;

typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;

typedef bit<8> switch_fib_label_t;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

enum bit<4> PortSpeed {
    Unset = 0x0,
    GbE_10 = 0x1,
    GbE_25 = 0x2,
    GbE_40 = 0x3,
    GbE_50 = 0x4,
    GbE_100 = 0x5,
    GbE_200 = 0x6,
    GbE_400 = 0x7,
    GbE_800 = 0x8
}

enum bit<2> LinkToType {
    Unknown = 0,
    Switch = 1,
    Server = 2
}


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_DST_LOOPBACK = 32;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PORT_METER = 75;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_ACL_METER = 76;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PORT_METER = 77;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_METER = 78;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_REASON_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_NON_IP_ROUTER_MAC = 94;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV4_DISABLE = 99;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PFC_WD_DROP = 101;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PFC_WD_DROP = 102;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_NAT = 16w0x0200;

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;


typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x08;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_METER = 8w0x80;

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

// LOU ------------------------------------------------------------------------

typedef bit<8> switch_l4_port_label_t;

// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<10> switch_stp_group_t;

struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

// Sflow ----------------------------------------------------------------------
typedef bit<8> switch_sflow_id_t;
const switch_sflow_id_t SWITCH_SFLOW_INVALID_ID = 8w0xff;

struct switch_sflow_metadata_t {
    switch_sflow_id_t session_id;
    bit<1> sample_packet;
}

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;


typedef bit<10> switch_meter_index_t;


typedef bit<8> switch_mirror_meter_id_t;

// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;

typedef bit<5> switch_qos_group_t;


typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;


typedef bit<11> switch_etrap_index_t;

//MYIP type
typedef bit<2> switch_myip_type_t;
const switch_myip_type_t SWITCH_MYIP_NONE = 0;
const switch_myip_type_t SWITCH_MYIP = 1;
const switch_myip_type_t SWITCH_MYIP_SUBNET = 2;


struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_pkt_color_t acl_meter_color;
    switch_pkt_color_t port_color;
    switch_pkt_color_t flow_color;
    switch_pkt_color_t storm_control_color;
    switch_meter_index_t port_meter_index;
    switch_meter_index_t acl_meter_index;
    switch_qid_t qid;
    switch_ingress_cos_t icos; // Ingress only.
    bit<19> qdepth; // Egress only.
    PortSpeed port_speed; // Egress only
    LinkToType link_to_type; // Egress only
    switch_etrap_index_t etrap_index;
    switch_pkt_color_t etrap_color;
    switch_tc_t etrap_tc;
    bit<1> etrap_state;
}

// Learning -------------------------------------------------------------------
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

struct switch_learning_digest_t {
    switch_bd_t bd;
    switch_port_lag_index_t port_lag_index;
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t bd_mode;
    switch_learning_mode_t port_mode;
    switch_learning_digest_t digest;
}

// Multicast ------------------------------------------------------------------
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// WRED/ECN -------------------------------------------------------------------

typedef bit<10> switch_wred_index_t;

typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11; // Congestion encountered

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
enum bit<1> MirrorIoSelect_t {
    BeforeMau = 0,
    AfterMau = 1
}
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;







/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */


// Common metadata used for mirroring.
@flexible()
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
    PortId_t egress_port;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;

}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_port_padding_t _pad1;
    switch_port_t port;
    switch_bd_t bd;
    bit<6> _pad2;
    switch_port_lag_index_t port_lag_index;
    switch_cpu_reason_t reason_code;
}

// Tunneling ------------------------------------------------------------------
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 3;

enum switch_tunnel_term_mode_t { P2P, P2MP };




typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
    bit<8> nvgre_flow_id;
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






typedef bit<6> switch_dtel_hw_id_t;

// Outer header sizes for DTEL Reports
/* Up to the beginning of the DTEL Report v0.5 header
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 4 (CRC) = 46 bytes */
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
/* Outer headers + part of DTEL Report v2 length not included in report_length
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 12 (DTEL) + 4 (CRC) = 58 bytes */
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;

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

typedef bit<4> switch_ingress_nat_hit_type_t;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_NONE = 0;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NONE = 1;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NAPT = 2;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NAT = 3;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NONE = 4;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NAPT = 5;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NAT = 6;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NONE = 7;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NAPT = 8;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NAT = 9;

typedef bit<1> switch_nat_zone_t;
const switch_nat_zone_t SWITCH_NAT_INSIDE_ZONE_ID = 0;
const switch_nat_zone_t SWITCH_NAT_OUTSIDE_ZONE_ID = 1;

struct switch_nat_ingress_metadata_t {
  switch_ingress_nat_hit_type_t hit;
  switch_nat_zone_t ingress_zone;
  bit<16> dnapt_index;
  bit<16> snapt_index;
  bool nat_disable;
  bool dnat_pool_hit;
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



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
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



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
    switch_port_t egress_port;
}

// Source Flow Control related types (SFC) ------------------------------------------------


typedef bit<1> ping_pong_t;
typedef bit<32> const_t;





// Allow combinations of ingress pipe 9bit egress port + 7bit egress queue
typedef bit<16> sfc_ingress_queue_idx_t;
// This applies to: sfc_queue_idx_t, sfc_buffer_pool_idx_t
typedef bit<8> sfc_queue_idx_t;
//typedef bit<SFC_QUEUE_IDX_PAD_16BIT_BITS> sfc_queue_idx_pad_16bit_t;
typedef bit<2> sfc_buffer_pool_idx_t;
typedef bit<6> sfc_buffer_pool_idx_pad_8bit_t;

typedef bit<16> sfc_suppression_filter_idx_t;

typedef bit<18> buffer_memory_t;
typedef bit<5> buffer_memory_pad_24bit_t;
typedef bit<11> tm_hw_queue_id_t;
typedef bit<2> pipe_id_t;
typedef bit<16> sfc_pause_duration_us_t;
typedef bit<2> sfc_queue_threshold_idx_t;

enum bit<3> SfcPacketType {
    Unset = 0,
    None = 1, // No SFC packet
    Data = 2, // Normal SFC data packet, SFC is enabled
    Trigger = 3, // SFC pause packet after mirroring, SFC is enabled
    Signal = 4, // SFC pause packet after SFC pause packet construction, SFC is enabled
    TcSignalEnabled = 5 // No SFC packet, but a packet on a SignalingEnabledTC
}
typedef bit<5> SfcPacketType_pad_8bit_t;

struct sfc_qd_threshold_register_t {
    bit<32> queue_depth;
    bit<32> threshold;
}

struct sfc_pause_epoch_register_t {
    bit<32> current_epoch_start;
    bit<32> bank_idx_changed;
}

// Metadata for SFC used in ghost thread
struct sfc_ghost_metadata_t {
    sfc_queue_threshold_idx_t queue_threshold_idx;
    bit<16> ingress_port_queue_idx;
    bool qlength_over_threshold;
}

// Metadata for SFC used in ingress thread
struct switch_sfc_ingress_metadata_t {
    SfcPacketType type;
    // [1:1]: switch bank
    // [0:0]: bank idx
    bit<2> switch_bank_idx;
    MirrorId_t signaling_mirror_session_id;
    bool qlength_over_threshold;
    bit<32> suppression_hash;
    sfc_queue_idx_t queue_register_idx;
    sfc_queue_threshold_idx_t queue_threshold_idx;
}

@flexible
struct switch_bridged_metadata_sfc_extension_t {
    SfcPacketType type;
    sfc_queue_idx_t queue_register_idx;
    sfc_queue_threshold_idx_t queue_threshold_idx;
}

// Metadata for SFC used in egress thread
@flexible
struct switch_sfc_egress_metadata_t {
    // Pick up from bridged or bridge md
    SfcPacketType type;
    sfc_queue_idx_t queue_register_idx;
    sfc_queue_threshold_idx_t queue_threshold_idx;
    switch_tc_t pause_tc;
    // Set in egress
    PortSpeed egress_port_speed;
    // Calculate in egress
    buffer_memory_t q_drain_lengths;
    sfc_pause_duration_us_t pause_duration_us;
}

header switch_sfc_pause_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;
    sfc_queue_idx_t queue_register_idx;
    switch_tc_t pause_tc;
    switch_nexthop_t nexthop;
    sfc_queue_threshold_idx_t queue_threshold_idx;
    //compiler tells me that the above are 134 bits, not byte-align
//    bit<2>                  _pad2;
}


//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
@pa_container_size("ingress", "ig_md.checks.same_if", 16)



struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool dmac_miss;
    switch_myip_type_t myip;
    bool glean;
    bool storm_control_drop;
    bool acl_meter_drop;
    bool port_meter_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;
    bool pfc_wd_drop;
    bool bypass_egress;
    // Add more flags here.
}

struct switch_egress_flags_t {
    bool routed;
    bool bypass_egress;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;
    bool port_meter_drop;
    bool acl_meter_drop;
    bool pfc_wd_drop;

    // Add more flags here.
}


// Checks
struct switch_ingress_checks_t {
    switch_port_lag_index_t same_if;
    bool mrpf;
    bool urpf;






    // Add more checks here.
}

struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;

    // Add more checks here.
}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    bit<2> ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    switch_pkt_type_t pkt_type;
    bool routed;
    bool bypass_egress;
    //TODO(msharif) : Fix the bridged metadata fields for PTP.






    switch_cpu_reason_t cpu_reason;
    bit<48> timestamp;
    switch_tc_t tc;
    switch_qid_t qid;
    switch_pkt_color_t color;

    // Add more fields here.
}

@flexible
struct switch_bridged_metadata_acl_extension_t {

    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;






}

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;




    bool terminate;
}


@pa_atomic("ingress", "hdr.bridged_md.base_qid")
@pa_container_size("ingress", "hdr.bridged_md.base_qid", 8)
@pa_container_size("ingress", "hdr.bridged_md.dtel_report_type", 8)
@pa_no_overlay("ingress", "hdr.bridged_md.base_qid")
/*
 CODE_HACK - The following hdr.bridged_md.__pad_* fields are meant to refer to
 the padding for hdr.bridged_md.base_qid, hdr.bridged_md.base_ingress_port, and
 hdr.bridged_md.dtel_egress_port. For deflected packets, these fields are
 copied directly into hdr.dtel_report by the parser. For bridged packets, the
 first two fields are copied by the parser into eg_md fields, then if the
 packet is mirrored in order to generate a DTEL report, these eg_md fields
 are copied by the deparser into mirror headers, which are then copied by the
 parser into hdr.dtel_report. If the pads are overlaid, resulting in non-zero
 values, then it would corrupt hdr.dtel_report.
*/
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_2")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_3")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_4")
/*
 CODE_HACK - The following pragmas are required because the report fields
 are being overlaid with fields that are being later being modified in the
 MAU. The drop report and queue report are added in the egress parser.
 This doesn't really solve the problem completely. The below
 pragma's only help the drop report from not getting overlayed. The queue
 report is still vulnerable to be overlaid with other fields.
*/
@pa_no_overlay("egress", "hdr.dtel_report.ingress_port")
@pa_no_overlay("egress", "hdr.dtel_report.egress_port")
@pa_no_overlay("egress", "hdr.dtel_report.queue_id")
@pa_no_overlay("egress", "hdr.dtel_drop_report.drop_reason")
@pa_no_overlay("egress", "hdr.dtel_drop_report.reserved")
# 1017 "../shared/types.p4"
@pa_no_overlay("egress", "hdr.dtel_switch_local_report.queue_occupancy")


typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;


    switch_bridged_metadata_acl_extension_t acl;





    switch_bridged_metadata_dtel_extension_t dtel;


    switch_bridged_metadata_sfc_extension_t sfc;

}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;
}

@pa_auto_init_metadata

@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")



@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")
@pa_container_size("ingress", "ig_md.egress_port_lag_index", 16)
// Ingress metadata
struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;
    switch_nexthop_t acl_nexthop;
    bool acl_port_redirect;
    switch_nexthop_t unused_nexthop;

    bit<48> timestamp;
    switch_hash_t hash;
    switch_hash_t lag_hash;

    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4;
    switch_ip_metadata_t ipv6;
    switch_ig_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_rmac_group_t rmac_group;
    switch_lookup_fields_t lkp;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_sflow_metadata_t sflow;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;

    switch_sfc_ingress_metadata_t sfc;

    mac_addr_t same_mac;

    switch_user_metadata_t user_metadata;




    bit<10> partition_key;
    bit<12> partition_index;
    switch_fib_label_t fib_label;
}

// Egress metadata
@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)

@pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8)
@pa_mutually_exclusive("egress", "hdr.dtel.timestamp", "hdr.erspan_type3.timestamp")

struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;

    /* ingress port_lag_index for cpu going packets, egress port_lag_index for
     * normal ports */
    switch_port_lag_index_t port_lag_index;

    switch_port_type_t port_type; /* egress port type */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;




    bit<32> timestamp;

    bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
    switch_egress_checks_t checks;
    switch_egress_bypass_t bypass;

    // for egress ACL
    switch_eg_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

    switch_lookup_fields_t lkp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;

    switch_sfc_egress_metadata_t sfc;

    switch_sflow_metadata_t sflow;

    switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;




    bool inner_ipv4_checksum_update_en;
}

// Header format for mirrored metadata fields
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}


struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    // switch_mirror_metadata_h mirror;
    ethernet_h ethernet;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;
    vlan_tag_h[2] vlan_tag;
    mpls_h[3] mpls;
    pfc_h pfc;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
# 1215 "../shared/types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

    rocev2_bth_h rocev2_bth;

    sfc_pause_h sfc_pause;

    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;
    geneve_h geneve;
    erspan_h erspan;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
}
# 140 "./switch_tofino2_y0.p4" 2
# 1 "../shared/util.p4" 1
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

# 1 "../shared/types.p4" 1
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
# 24 "../shared/util.p4" 2

// Flow hash calculation.
# 77 "../shared/util.p4"
control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
    apply {
        hash [31:0] = ipv4_hash.get({lkp.ip_src_addr [31:0],
                                     lkp.ip_dst_addr [31:0],
                                     lkp.ip_proto,
                                     lkp.l4_dst_port,
                                     lkp.l4_src_port});
    }
}
control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
    apply {
        hash[31:0] = ipv6_hash.get({lkp.ip_src_addr,
                                    lkp.ip_dst_addr,
                                    lkp.ip_proto,
                                    lkp.l4_dst_port,
                                    lkp.l4_src_port});
    }
}
control NonIpHash(in switch_ingress_metadata_t ig_md, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
    apply {
        hash [31:0] = non_ip_hash.get({ig_md.port,
                                       ig_md.lkp.mac_type,
                                       ig_md.lkp.mac_src_addr,
                                       ig_md.lkp.mac_dst_addr});
    }
}
control Lagv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    apply {
        hash[31:0] = lag_hash.get({lkp.ip_src_addr [31:0],
                                   lkp.ip_dst_addr [31:0],
                                   lkp.ip_proto,
                                   lkp.l4_dst_port,
                                   lkp.l4_src_port});
    }
}
control Lagv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    apply {
        hash[31:0] = lag_hash.get({lkp.ip_src_addr,
                                   lkp.ip_dst_addr,
                                   lkp.ip_proto,
                                   lkp.l4_dst_port,
                                   lkp.l4_src_port});
    }
}

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port,
        ig_md.port_lag_index,
        ig_md.bd,
        ig_md.nexthop,
        ig_md.lkp.pkt_type,
        ig_md.flags.routed,
        ig_md.flags.bypass_egress,






        ig_md.cpu_reason,
        ig_md.timestamp,
        ig_md.qos.tc,
        ig_md.qos.qid,
        ig_md.qos.color};


    bridged_md.acl = {ig_md.lkp.l4_src_port,
                      ig_md.lkp.l4_dst_port,
                      ig_md.lkp.tcp_flags,





                      ig_md.l4_src_port_label,
                      ig_md.l4_dst_port_label};
# 179 "../shared/util.p4"
    bridged_md.dtel = {ig_md.dtel.report_type,
                       ig_md.dtel.session_id,
                       ig_md.lag_hash,
                       ig_md.egress_port};



    bridged_md.sfc = {ig_md.sfc.type,
                      ig_md.sfc.queue_register_idx,
                      ig_md.sfc.queue_threshold_idx};

}

action set_ig_intr_md(in switch_ingress_metadata_t ig_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
// Set PRE hash values
//  ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.lag_hash[28:16];

//    ig_intr_md_for_dprsr.mirror_type = (bit<4>) ig_md.mirror.type;





    ig_intr_md_for_tm.qid = ig_md.qos.qid;
    ig_intr_md_for_tm.ingress_cos = ig_md.qos.icos;

}

action set_eg_intr_md(in switch_egress_metadata_t eg_md,
                      inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                      inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {







    eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
    eg_intr_md_for_dprsr.mirror_io_select = 1;


}
# 141 "./switch_tofino2_y0.p4" 2

# 1 "../shared/l3.p4" 1
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

# 1 "../shared/acl.p4" 1
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
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 63 "../shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 136 "../shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 207 "../shared/acl.p4"
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 238 "../shared/acl.p4"
//-----------------------------------------------------------------------------
// Ingress Shared IP ACL
//-----------------------------------------------------------------------------
control IngressIpAcl(inout switch_ingress_metadata_t ig_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { ig_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { ig_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { ig_md.qos.acl_meter_index = index; stats.count(); } action deny() { ig_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { ig_md.flags.acl_deny = false; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { ig_md.flags.acl_deny = false; ig_md.egress_port_lag_index = egress_port_lag_index; ig_md.acl_port_redirect = true; ig_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { ig_md.mirror.type = 1; ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; ig_md.mirror.session_id = session_id; ig_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { ig_md.dtel.report_type = ig_md.dtel.report_type | type; stats.count(); }

    table acl {
        key = {
            ig_md.lkp.ip_src_addr : ternary; ig_md.lkp.ip_dst_addr : ternary; ig_md.lkp.ip_proto : ternary; ig_md.lkp.ip_tos : ternary; ig_md.lkp.l4_src_port : ternary; ig_md.lkp.l4_dst_port : ternary; ig_md.lkp.ip_ttl : ternary; ig_md.lkp.ip_frag : ternary; ig_md.lkp.tcp_flags : ternary; ig_md.bd_label : ternary; ig_md.l4_src_port_label : ternary; ig_md.l4_dst_port_label : ternary;
            ig_md.lkp.mac_type : ternary;




            ig_md.port_lag_label : ternary;

        }

        actions = {
            deny;
            permit;






            mirror;
# 279 "../shared/acl.p4"
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress IPv4 ACL
//-----------------------------------------------------------------------------
control IngressIpv4Acl(inout switch_ingress_metadata_t ig_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { ig_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { ig_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { ig_md.qos.acl_meter_index = index; stats.count(); } action deny() { ig_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { ig_md.flags.acl_deny = false; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { ig_md.flags.acl_deny = false; ig_md.egress_port_lag_index = egress_port_lag_index; ig_md.acl_port_redirect = true; ig_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { ig_md.mirror.type = 1; ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; ig_md.mirror.session_id = session_id; ig_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { ig_md.dtel.report_type = ig_md.dtel.report_type | type; stats.count(); }



    table acl {
        key = {
            ig_md.lkp.ip_src_addr[31:0] : ternary; ig_md.lkp.ip_dst_addr[31:0] : ternary; ig_md.lkp.ip_proto : ternary; ig_md.lkp.ip_tos : ternary; ig_md.lkp.l4_src_port : ternary; ig_md.lkp.l4_dst_port : ternary; ig_md.lkp.ip_ttl : ternary; ig_md.lkp.ip_frag : ternary; ig_md.lkp.tcp_flags : ternary; ig_md.bd_label : ternary; ig_md.l4_src_port_label : ternary; ig_md.l4_dst_port_label : ternary;




            ig_md.lkp.mac_type : ternary;





            ig_md.port_lag_label : ternary;

        }

        actions = {
            deny;
            permit;
# 336 "../shared/acl.p4"
            mirror;
# 345 "../shared/acl.p4"
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress IPv6 ACL
//-----------------------------------------------------------------------------
control IngressIpv6Acl(inout switch_ingress_metadata_t ig_md,
                     out switch_nexthop_t acl_nexthop)(
                       switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { ig_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { ig_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { ig_md.qos.acl_meter_index = index; stats.count(); } action deny() { ig_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { ig_md.flags.acl_deny = false; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { ig_md.flags.acl_deny = false; ig_md.egress_port_lag_index = egress_port_lag_index; ig_md.acl_port_redirect = true; ig_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { ig_md.mirror.type = 1; ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; ig_md.mirror.session_id = session_id; ig_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { ig_md.dtel.report_type = ig_md.dtel.report_type | type; stats.count(); }

    table acl {
        key = {
            ig_md.lkp.ip_src_addr : ternary; ig_md.lkp.ip_dst_addr : ternary; ig_md.lkp.ip_proto : ternary; ig_md.lkp.ip_tos : ternary; ig_md.lkp.l4_src_port : ternary; ig_md.lkp.l4_dst_port : ternary; ig_md.lkp.ip_ttl : ternary; ig_md.lkp.ip_frag : ternary; ig_md.lkp.tcp_flags : ternary; ig_md.bd_label : ternary; ig_md.l4_src_port_label : ternary; ig_md.l4_dst_port_label : ternary;




            ig_md.lkp.mac_type : ternary;





            ig_md.port_lag_label : ternary;

        }

        actions = {
            deny;
            permit;






            mirror;
# 406 "../shared/acl.p4"
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress MAC ACL
//-----------------------------------------------------------------------------
control IngressMacAcl(inout switch_ingress_metadata_t ig_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { ig_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { ig_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { ig_md.qos.acl_meter_index = index; stats.count(); } action deny() { ig_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { ig_md.flags.acl_deny = false; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { ig_md.flags.acl_deny = false; ig_md.egress_port_lag_index = egress_port_lag_index; ig_md.acl_port_redirect = true; ig_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { ig_md.mirror.type = 1; ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; ig_md.mirror.session_id = session_id; ig_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { ig_md.dtel.report_type = ig_md.dtel.report_type | type; stats.count(); }

    table acl {
        key = {
            ig_md.lkp.mac_src_addr : ternary; ig_md.lkp.mac_dst_addr : ternary; ig_md.lkp.mac_type : ternary; ig_md.port_lag_label : ternary; ig_md.bd_label : ternary;
        }

        actions = {
            deny;
            permit;






            mirror;
# 455 "../shared/acl.p4"
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Shared IP DTEL Sample ACL
// Typically a DTEL ACL slice should use the normal shared IP ACL definition
// This is an alternate definition that adds sampling and IFA clone support
//-----------------------------------------------------------------------------
struct switch_acl_sample_info_t {
    bit<32> current;
    bit<32> rate;
}

control IngressIpDtelSampleAcl(inout switch_ingress_metadata_t ig_md,
                         out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    const bit<32> acl_sample_session_size = 256;

    Register<switch_acl_sample_info_t, bit<32>>(acl_sample_session_size) samplers;
    RegisterAction<switch_acl_sample_info_t, bit<8>, bit<1>>(samplers) sample_packet = {
        void apply(inout switch_acl_sample_info_t reg, out bit<1> flag) {
            if (reg.current > 0) {
                reg.current = reg.current - 1;
            } else {
                reg.current = reg.rate;
                flag = 1;
            }
        }
    };

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { ig_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { ig_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { ig_md.qos.acl_meter_index = index; stats.count(); } action deny() { ig_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { ig_md.flags.acl_deny = false; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; ig_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { ig_md.flags.acl_deny = false; ig_md.egress_port_lag_index = egress_port_lag_index; ig_md.acl_port_redirect = true; ig_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { ig_md.mirror.type = 1; ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; ig_md.mirror.session_id = session_id; ig_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { ig_md.dtel.report_type = ig_md.dtel.report_type | type; stats.count(); }

    action ifa_clone_sample(switch_ifa_sample_id_t ifa_sample_session) {
        ig_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }

    action ifa_clone_sample_and_set_dtel_report_type(
            switch_ifa_sample_id_t ifa_sample_session,
            switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = type;
        ig_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }

    table acl {
        key = {
            ig_md.lkp.ip_src_addr : ternary; ig_md.lkp.ip_dst_addr : ternary; ig_md.lkp.ip_proto : ternary; ig_md.lkp.ip_tos : ternary; ig_md.lkp.l4_src_port : ternary; ig_md.lkp.l4_dst_port : ternary; ig_md.lkp.ip_ttl : ternary; ig_md.lkp.ip_frag : ternary; ig_md.lkp.tcp_flags : ternary; ig_md.bd_label : ternary; ig_md.l4_src_port_label : ternary; ig_md.l4_dst_port_label : ternary;
            ig_md.lkp.mac_type : ternary;




            ig_md.port_lag_label : ternary;

        }

        actions = {
            set_dtel_report_type;




            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }





    }
}

// ----------------------------------------------------------------------------
// Comparison/Logical operation unit (LOU)
// LOU can perform logical operationis such AND and OR on tcp flags as well as comparison
// operations such as LT, GT, EQ, and NE for src/dst UDP/TCP ports.
//
// @param table_size : Total number of supported ranges for src/dst ports.
// ----------------------------------------------------------------------------
control LOU(inout switch_ingress_metadata_t ig_md) {

    const switch_uint32_t table_size = 8;

    //TODO(msharif): Change this to bitwise OR so we can allocate bits to src/dst ports at runtime.
    action set_src_port_label(bit<8> label) {
        ig_md.l4_src_port_label = label;
    }

    action set_dst_port_label(bit<8> label) {
        ig_md.l4_dst_port_label = label;
    }


    @stage(1)

    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            ig_md.lkp.l4_dst_port : range;
        }

        actions = {
            NoAction;
            set_dst_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }


    @stage(1)

    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            ig_md.lkp.l4_src_port : range;
        }

        actions = {
            NoAction;
            set_src_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action set_tcp_flags(bit<8> flags) {
        ig_md.lkp.tcp_flags = flags;
    }

    table tcp {
        key = { ig_md.lkp.tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }

        size = 256;
    }

    apply {

        l4_src_port.apply();
        l4_dst_port.apply();





    }
}

//-----------------------------------------------------------------------------
//
// Ingress System ACL
//
//-----------------------------------------------------------------------------
control IngressSystemAcl(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;

    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_md.drop_reason = drop_reason;



    }

    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id,
                       bool disable_learning) {
        ig_md.qos.qid = qid;
        // ig_md.qos.icos = icos;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
        ig_md.cpu_reason = reason_code;



    }
# 691 "../shared/acl.p4"
    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id,
                           bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }
# 709 "../shared/acl.p4"
    table system_acl {
        key = {
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.port_lag_index : ternary;

            // Lookup fields
            ig_md.lkp.pkt_type : ternary;
            ig_md.lkp.mac_type : ternary;
            ig_md.lkp.mac_dst_addr : ternary;
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_ttl : ternary;
            ig_md.lkp.ip_proto : ternary;
            ig_md.lkp.ip_frag : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
            ig_md.lkp.arp_opcode : ternary;

            // Flags
            ig_md.flags.port_vlan_miss : ternary;
            ig_md.flags.acl_deny : ternary;
            ig_md.flags.racl_deny : ternary;
            ig_md.flags.rmac_hit : ternary;
            ig_md.flags.dmac_miss : ternary;
            ig_md.flags.myip : ternary;
            ig_md.flags.glean : ternary;
            ig_md.flags.routed : ternary;

            ig_md.flags.acl_meter_drop : ternary;




            ig_md.flags.link_local : ternary;





            ig_md.checks.same_if : ternary;
# 758 "../shared/acl.p4"
            ig_md.flags.pfc_wd_drop : ternary;

            ig_md.ipv4.unicast_enable : ternary;
            ig_md.ipv6.unicast_enable : ternary;
# 773 "../shared/acl.p4"
            ig_md.drop_reason : ternary;
# 782 "../shared/acl.p4"
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;




        }

        const default_action = NoAction;
        size = table_size;
    }

    action copp_drop() {
        ig_intr_md_for_tm.copy_to_cpu = 1w0;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    table copp {
        key = {
            ig_intr_md_for_tm.packet_color : ternary;
            copp_meter_id : ternary;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            ig_md.drop_reason : exact @name("drop_reason");
            ig_md.port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0)) {
            switch(system_acl.apply().action_run) {

                copy_to_cpu : { copp.apply(); }
                redirect_to_cpu : { copp.apply(); }

                default: {}
            }
        }
        drop_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress MAC ACL
//-----------------------------------------------------------------------------
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { eg_md.flags.acl_deny = true; stats.count(); } action permit() { eg_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { eg_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { eg_md.mirror.type = 1; eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; eg_md.mirror.session_id = session_id; eg_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            eg_md.port_lag_label : ternary; eg_md.bd_label : ternary; hdr.ethernet.src_addr : ternary; hdr.ethernet.dst_addr : ternary; hdr.ethernet.ether_type : ternary;
        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Egress IPv4 ACL
//-----------------------------------------------------------------------------
control EgressIpv4Acl(in switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { eg_md.flags.acl_deny = true; stats.count(); } action permit() { eg_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { eg_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { eg_md.mirror.type = 1; eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; eg_md.mirror.session_id = session_id; eg_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            eg_md.port_lag_label : ternary; eg_md.bd_label : ternary; hdr.ipv4.src_addr : ternary; hdr.ipv4.dst_addr : ternary; hdr.ipv4.protocol : ternary; hdr.ipv4.diffserv : ternary; eg_md.lkp.tcp_flags : ternary; eg_md.lkp.l4_src_port : ternary; eg_md.lkp.l4_dst_port : ternary; eg_md.l4_src_port_label : ternary; eg_md.l4_dst_port_label : ternary;

            hdr.ethernet.ether_type : ternary;

        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Egress IPv6 ACL
//-----------------------------------------------------------------------------
control EgressIpv6Acl(in switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { eg_md.flags.acl_deny = true; stats.count(); } action permit() { eg_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { eg_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { eg_md.mirror.type = 1; eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; eg_md.mirror.session_id = session_id; eg_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            eg_md.port_lag_label : ternary; eg_md.bd_label : ternary; hdr.ipv6.src_addr : ternary; hdr.ipv6.dst_addr : ternary; hdr.ipv6.next_hdr : ternary; hdr.ipv6.traffic_class : ternary; eg_md.lkp.tcp_flags : ternary; eg_md.lkp.l4_src_port : ternary; eg_md.lkp.l4_dst_port : ternary; eg_md.l4_src_port_label : ternary; eg_md.l4_dst_port_label : ternary;

            hdr.ethernet.ether_type : ternary;

        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
//
// Egress System ACL
//
//-----------------------------------------------------------------------------
control EgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;
    switch_pkt_color_t copp_color;

    action drop(switch_drop_reason_t reason_code) {
        eg_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        eg_md.mirror.type = 0;
    }


    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_copp_meter_id_t meter_id) {
        eg_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        copp_color = (bit<2>) copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_copp_meter_id_t meter_id) {
        copy_to_cpu(reason_code, meter_id);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }


    action insert_timestamp() {




    }

    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            eg_md.flags.acl_deny : ternary;





            eg_md.checks.mtu : ternary;





            eg_md.flags.wred_drop : ternary;


            eg_md.flags.pfc_wd_drop : ternary;
# 1040 "../shared/acl.p4"
            //TODO add more
        }

        actions = {
            NoAction;
            drop;

            copy_to_cpu;
            redirect_to_cpu;

            insert_timestamp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            eg_md.drop_reason : exact @name("drop_reason");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    action copp_drop() {
        eg_intr_md_for_dprsr.mirror_type = 0;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    table copp {
        key = {
            copp_color : exact;
            copp_meter_id : exact;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SYSTEM_ACL != 0)) {
            switch(system_acl.apply().action_run) {

                copy_to_cpu : { copp.apply(); }
                redirect_to_cpu : { copp.apply(); }

                default: {}
            }
        }

        drop_stats.apply();

    }
}
# 24 "../shared/l3.p4" 2
# 1 "../shared/l2.p4" 1
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
// Spanning Tree Protocol
// @param ig_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
//-----------------------------------------------------------------------------
control IngressSTP(in switch_ingress_metadata_t ig_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
    // This register is used to check the stp state of the ingress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the indes.
    const bit<32> stp_state_size = 1 << 19;
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    table mstp {
        key = {
            ig_md.port : exact;
            stp_md.group: exact;
        }

        actions = {
            NoAction;
            set_stp_state;
        }

        size = table_size;
        const default_action = NoAction;
    }

    apply {
# 86 "../shared/l2.p4"
    }
}

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
// @param stp_state : Spanning tree state.
//-----------------------------------------------------------------------------
control EgressSTP(in switch_egress_metadata_t eg_md, in switch_port_t port, out bool stp_state) {
    // This register is used to check the stp state of the egress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the index.
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
# 117 "../shared/l2.p4"
    }
}


//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param ig_md : Ingress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
//-----------------------------------------------------------------------------
control SMAC(in mac_addr_t src_addr,
             inout switch_ingress_metadata_t ig_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
    // local variables for MAC learning
    bool src_miss;
    switch_port_lag_index_t src_move;

    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(switch_port_lag_index_t port_lag_index) {
        src_move = ig_md.port_lag_index ^ port_lag_index;
    }

    table smac {
        key = {
            ig_md.bd : exact;
            src_addr : exact;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = table_size;
        idle_timeout = true;
    }

    action notify() {
        digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }


    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
         smac.apply();
        }

        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

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
control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
        in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

    action dmac_miss() {
        ig_md.egress_port_lag_index = SWITCH_FLOOD;
        ig_md.flags.dmac_miss = true;
    }

    action dmac_hit(switch_port_lag_index_t port_lag_index) {
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }

    action dmac_multicast(switch_mgid_t index) {
        ig_md.multicast.id = index;
    }

    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
    }

    /* CODE_HACK: P4C-3103 */
    @pack(2)
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

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {



        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {

            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

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

control EgressBd(in switch_header_t hdr,
                 in switch_bd_t bd,
                 in switch_pkt_type_t pkt_type,
                 in switch_pkt_src_t pkt_src,
                 out switch_bd_label_t label,
                 out switch_smac_index_t smac_idx,
                 out switch_mtu_t mtu_idx)(
                 switch_uint32_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = 3 * table_size;
        counters = stats;
    }

    action set_bd_properties(switch_bd_label_t bd_label,
                             switch_smac_index_t smac_index,
                             switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
    }

    table bd_mapping {
        key = { bd : exact; }
        actions = {
            NoAction;
            set_bd_properties;
        }

        const default_action = NoAction;
        /* CODE_HACK size increased from 5120 to 6144 to overcome low utilization */
        size = 6144;
    }

    apply {
        bd_mapping.apply();
        if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
            bd_stats.apply();
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
control VlanDecap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    action remove_double_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[1].ether_type;
        hdr.vlan_tag.pop_front(2);
    }

    table vlan_decap {
        key = {



            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            NoAction;
            remove_vlan_tag;
            remove_double_tag;
        }

        const default_action = NoAction;
    }

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
control VlanXlate(inout switch_header_t hdr,
                  in switch_egress_metadata_t eg_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }

    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
# 432 "../shared/l2.p4"
   }

    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

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
            set_double_tagged;
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

    action set_type_vlan() {
        hdr.ethernet.ether_type = 0x8100;
    }

    action set_type_qinq() {
        hdr.ethernet.ether_type = 0x8100;
    }

    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;
        }

        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_type_vlan();
            (true, true) : set_type_qinq();
        }
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }




        }
    }
}
# 25 "../shared/l3.p4" 2

//-----------------------------------------------------------------------------
// FIB lookup
//
// @param dst_addr : Destination IPv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------
control Fib(inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t host_table_size,
            switch_uint32_t lpm_table_size,
            bool local_host_enable=false,
            switch_uint32_t local_host_table_size=1024) {
    action fib_hit(switch_nexthop_t nexthop_index, switch_fib_label_t fib_label) {
        ig_md.nexthop = nexthop_index;



        ig_md.flags.routed = true;
    }

    action fib_miss() {
        ig_md.flags.routed = false;
    }

    action fib_myip_subnet() {
        ig_md.flags.myip = SWITCH_MYIP_SUBNET;
    }

    action fib_myip() {
        ig_md.flags.myip = SWITCH_MYIP;
    }

    table fib {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr[31:0] : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    table fib_local_host {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr[31:0] : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = local_host_table_size;
    }

    Alpm(number_partitions = 2048, subtrees_per_partition = 2) algo_lpm;
    table fib_lpm {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr[31:0] : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
            fib_myip_subnet;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
        alpm = algo_lpm;
        requires_versioning = false;
    }

    apply {
        if (local_host_enable) {
            if (!fib_local_host.apply().hit) {
                if (!fib.apply().hit) {
                    fib_lpm.apply();
                }
            }
        } else {
            if (!fib.apply().hit) {
                fib_lpm.apply();
            }
        }
    }
}

control Fibv6(inout switch_ingress_metadata_t ig_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {

    action fib_hit(switch_nexthop_t nexthop_index, switch_fib_label_t fib_label) {
        ig_md.nexthop = nexthop_index;



        ig_md.flags.routed = true;
    }

    action fib_miss() {
        ig_md.flags.routed = false;
    }

    action fib_myip_subnet() {
        ig_md.flags.myip = SWITCH_MYIP_SUBNET;
    }

    action fib_myip() {
        ig_md.flags.myip = SWITCH_MYIP;
    }

    table fib {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }



    Alpm(number_partitions = 1024, subtrees_per_partition = 1) algo_lpm128;



    table fib_lpm {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
            fib_myip_subnet;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
        alpm = algo_lpm128;
        requires_versioning = false;
    }
# 215 "../shared/l3.p4"
    Alpm(number_partitions = 2048, subtrees_per_partition = 2) algo_lpm64;
    table fib_lpm64 {
        key = {
            ig_md.vrf : exact;
            ig_md.lkp.ip_dst_addr[127:64] : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
            fib_myip_subnet;
        }

        const default_action = fib_miss;
        size = lpm64_table_size;
        alpm = algo_lpm64;
        requires_versioning = false;
    }


    apply {

        if (!fib.apply().hit) {



            if (!fib_lpm.apply().hit)

            {

                fib_lpm64.apply();

            }
        }

    }
}

control MTU(in switch_header_t hdr,
            in switch_egress_metadata_t eg_md,
            inout switch_mtu_t mtu_check)(
            switch_uint32_t table_size=1024) {

    action ipv4_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv4.total_len;
    }

    action ipv6_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv6.payload_len;
    }

    action mtu_miss() {
        mtu_check = 16w0xffff;
    }

    table mtu {
        key = {
            mtu_check : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            ipv4_mtu_check;
            ipv6_mtu_check;
            mtu_miss;
        }

        const default_action = mtu_miss;
        size = table_size;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_MTU != 0))
            mtu.apply();
    }
}

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
# 325 "../shared/l3.p4"
//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(in switch_lookup_fields_t lkp,
                       inout switch_ingress_metadata_t ig_md)(
                       DMAC_t dmac,
                       switch_uint32_t ipv4_host_table_size,
                       switch_uint32_t ipv4_route_table_size,
                       switch_uint32_t ipv6_host_table_size=1024,
                       switch_uint32_t ipv6_route_table_size=512,
                       switch_uint32_t ipv6_route64_table_size=512,
                       bool local_host_enable=false,
                       switch_uint32_t ipv4_local_host_table_size=1024) {
    Fib(ipv4_host_table_size,
        ipv4_route_table_size,
        local_host_enable,
        ipv4_local_host_table_size) ipv4_fib;
    Fibv6(ipv6_host_table_size, ipv6_route_table_size, ipv6_route64_table_size)
        ipv6_fib;
    action rmac_hit() { ig_md.flags.rmac_hit = true; } action rmac_miss() { ig_md.flags.rmac_hit = false; } table rmac { key = { ig_md.rmac_group : exact; ig_md.lkp.mac_dst_addr : exact; } actions = { rmac_hit; @defaultonly rmac_miss; } const default_action = rmac_miss; size = 1024; }

    apply {
        if (rmac.apply().hit) {
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0)) {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {

                    ipv6_fib.apply(ig_md);
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.unicast_enable) {

                    ipv4_fib.apply(ig_md);
                } else {
                    // Non-ip packets with router MAC address will be dropped by system ACL.
                }
            }
        } else {
            dmac.apply(lkp.mac_dst_addr, ig_md);
        }
    }
}
# 143 "./switch_tofino2_y0.p4" 2
# 1 "../shared/nexthop.p4" 1
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
                switch_uint32_t ecmp_group_table_size,
                switch_uint32_t ecmp_selection_table_size) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;







    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;


    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd,
                                  switch_nat_zone_t zone) {



        ig_md.egress_port_lag_index = port_lag_index;



        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }

    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;



    }

    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
    }

    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd, zone);
    }

    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }
    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid, zone);
    }

    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    action set_nexthop_properties_tunnel(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
    }

    action set_ecmp_properties_tunnel(switch_bd_t bd, switch_tunnel_index_t tunnel_index, switch_nexthop_t
    nexthop_index) {
        set_nexthop_properties_tunnel(bd, tunnel_index);
        ig_md.nexthop = nexthop_index;
    }

    table ecmp {
        key = {
            ig_md.nexthop : exact;
            ig_md.hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;



        }

        const default_action = NoAction;
        size = ecmp_group_table_size;
        implementation = ecmp_selector;
    }




    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;



        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
# 177 "../shared/nexthop.p4"
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
        }



    }
}

control OuterFib(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_group_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;

    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_outer_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel.index : exact;
            ig_md.hash[31:16] : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
        implementation = ecmp_selector;
        size = fib_table_size;
    }

    apply {



    }
}
# 144 "./switch_tofino2_y0.p4" 2
# 1 "../shared/parde.p4" 1
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

# 1 "../shared/headers.p4" 1
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
# 22 "../shared/parde.p4" 2
# 1 "../shared/types.p4" 1
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
# 23 "../shared/parde.p4" 2

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {



        transition accept;

    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}



//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;





    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        transition parse_packet;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (0x0800, _) : parse_ipv4;
            (0x0806, _) : parse_arp;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x8100, _) : parse_vlan;
            (0x8906, _) : parse_fcoe;
            (0x8808, _) : parse_pfc;
            cpu_port : parse_cpu;
            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;



        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);




        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        ipv4_checksum.add(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (2, 0) : parse_igmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (47, 0) : parse_gre;
            (4, 0) : parse_ipinip;
            (41, 0) : parse_ipv6inip;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0806 : parse_arp;
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_pfc {
        pkt.extract(hdr.pfc);
        ig_md.bypass = 16w0xfffb; // SWITCH_INGRESS_BYPASS_ALL; 
        transition accept;
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);




        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            47 : parse_gre;
            4 : parse_ipinip;
            41 : parse_ipv6inip;
            default : accept;
        }



    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s,
                          hdr.gre.recurse, hdr.gre.flags, hdr.gre.version, hdr.gre.proto) {
            (0, 0, 1, 0, 0, 0, 0, 0, 0x6558) : parse_nvgre;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);





        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            4791 : parse_rocev2;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);





        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }

    state parse_rocev2 {

        pkt.extract(hdr.rocev2_bth);

        transition accept;
    }

    state parse_fcoe {



        transition accept;
    }

    state parse_nvgre {
        pkt.extract(hdr.nvgre);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.tunnel.id = hdr.nvgre.vsid;
        ig_md.tunnel.nvgre_flow_id = hdr.nvgre.flow_id;
        transition parse_inner_ethernet;
    }

    state parse_vxlan {






        transition accept;

    }

    state parse_ipinip {




        transition accept;

    }

    state parse_ipv6inip {




        transition accept;

    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            1 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            58 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    /* CODE_HACK: P4C-1768. This is a workaround to prevent this state from being split into
     * multiple parser states. If the split happens, the match register allocation algorithm
     * currently runs out of parser match registers. This pragma ensures we do not encounter this
     * case for switch. To be removed once we have better interaction between PHV allocation and the
     * parser to prevent these cases.
     */
    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;


        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _, _) : parse_deflected_pkt;
            (_, SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
            (_, _, 1) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 2) : parse_cpu_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 3) : parse_dtel_drop_metadata_from_ingress;

            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 6) : parse_sfc_pause_metadata_from_ingress;

            (_, _, 3) : parse_dtel_drop_metadata_from_egress;
            (_, _, 4) : parse_dtel_switch_local_metadata;
            (_, _, 5) : parse_simple_mirrored_metadata;
        }



    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.flags.bypass_egress = hdr.bridged_md.base.bypass_egress;






        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
        eg_md.qos.color = hdr.bridged_md.base.color;


        eg_md.l4_src_port_label = hdr.bridged_md.acl.l4_src_port_label;
        eg_md.l4_dst_port_label = hdr.bridged_md.acl.l4_dst_port_label;
        eg_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        eg_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        eg_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
# 431 "../shared/parde.p4"
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.dtel.session_id = hdr.bridged_md.dtel.session_id;


        eg_md.sfc.type = hdr.bridged_md.sfc.type;
        eg_md.sfc.queue_register_idx = hdr.bridged_md.sfc.queue_register_idx;
        eg_md.sfc.queue_threshold_idx = hdr.bridged_md.sfc.queue_threshold_idx;


        transition parse_ethernet;
    }

    state parse_deflected_pkt {

        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;

        eg_md.mirror.type = 255;

        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = hdr.bridged_md.dtel.session_id;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
# 472 "../shared/parde.p4"
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        hdr.dtel_report = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
            hdr.bridged_md.dtel.egress_port,
            0,
            hdr.bridged_md.base.qid};
        hdr.dtel_drop_report = {
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};

        transition accept;



    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;

        eg_md.mirror.type = port_md.type;


        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;

        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd;
        // eg_md.ingress_port = cpu_md.md.port;
        eg_md.cpu_reason = cpu_md.reason_code;

        eg_md.mirror.type = cpu_md.type;


        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;

        transition accept;
    }

    state parse_dtel_drop_metadata_from_egress {

        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
# 553 "../shared/parde.p4"
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.dtel_drop_report = {
            dtel_md.drop_reason,
            0};

        transition accept;



    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {

        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
# 599 "../shared/parde.p4"
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID,
            0,
            dtel_md.qid};
        hdr.dtel_drop_report = {
            dtel_md.drop_reason,
            0};

        transition accept;



    }


    state parse_sfc_pause_metadata_from_ingress {
        switch_sfc_pause_mirror_metadata_h sfc_md;
        pkt.extract(sfc_md);

        eg_md.sfc.type = SfcPacketType.Trigger;
        eg_md.sfc.queue_register_idx = sfc_md.queue_register_idx;
        eg_md.sfc.pause_tc = sfc_md.pause_tc;
        eg_md.nexthop = sfc_md.nexthop;

        transition parse_ethernet;
    }


    state parse_dtel_switch_local_metadata {

        switch_dtel_switch_local_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
# 664 "../shared/parde.p4"
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.dtel_switch_local_report = {
            0,
            dtel_md.qdepth,
            dtel_md.egress_timestamp};

        transition accept;



    }

    state parse_simple_mirrored_metadata {

        switch_simple_mirror_metadata_h simple_mirror_md;
        pkt.extract(simple_mirror_md);
        eg_md.pkt_src = simple_mirror_md.src;
        eg_md.mirror.type = simple_mirror_md.type;
        eg_md.mirror.session_id = simple_mirror_md.session_id;
        eg_md.bypass = SWITCH_EGRESS_BYPASS_ALL;
        transition parse_ethernet;



    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            cpu_port : parse_cpu;
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x8100, _) : parse_vlan;
            (0x8808, _) : parse_pfc;
            default : accept;
        }
    }

    state parse_cpu {
        eg_md.bypass = SWITCH_EGRESS_BYPASS_ALL;
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {







            (_, 6, _) : parse_ipv4_options;

            (17, 5, 0) : parse_udp;

            default : accept;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {







            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_pfc {
        pkt.extract(hdr.pfc);
        transition accept;
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
# 778 "../shared/parde.p4"
            default : accept;
        }



    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            1674 : egress_parse_sfc_pause;
            default : accept;
        }
    }

    state egress_parse_sfc_pause {

        eg_md.sfc.type = SfcPacketType.Signal;
        pkt.extract(hdr.sfc_pause);

        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_vxlan {




        transition accept;

    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }
}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {

        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(
                ig_md.mirror.session_id,
                {ig_md.mirror.src,
                 ig_md.mirror.type,
                 ig_md.timestamp,



                 ig_md.mirror.session_id});

        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {

            mirror.emit<switch_dtel_drop_mirror_metadata_h>(ig_md.dtel.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                ig_md.timestamp,



                ig_md.dtel.session_id,
                ig_md.lag_hash,
                ig_md.dtel.report_type,
                0,
                ig_md.port,
                0,
                ig_md.egress_port,
                0,
                ig_md.qos.qid,
                ig_md.drop_reason
            });


        } else if (ig_intr_md_for_dprsr.mirror_type == 6) {

            mirror.emit<switch_sfc_pause_mirror_metadata_h>(ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                ig_md.timestamp,
                ig_md.sfc.queue_register_idx,
                ig_md.qos.tc,
                ig_md.nexthop,
                ig_md.sfc.queue_threshold_idx
            });


        }

    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {

        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_timestamp,



                eg_md.mirror.session_id});
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
                eg_md.port_lag_index,
                eg_md.cpu_reason});
        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {

            mirror.emit<switch_dtel_switch_local_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src, eg_md.mirror.type,
                eg_md.ingress_timestamp,



                eg_md.dtel.session_id,
                eg_md.dtel.hash,
                eg_md.dtel.report_type,
                0,
                eg_md.ingress_port,
                0,
                eg_md.port,
                0,
                eg_md.qos.qid,
                0,
                eg_md.qos.qdepth,
                eg_md.timestamp
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {

            mirror.emit<switch_dtel_drop_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                eg_md.ingress_timestamp,



                eg_md.dtel.session_id,
                eg_md.dtel.hash,
                eg_md.dtel.report_type,
                0,
                eg_md.ingress_port,
                0,
                eg_md.port,
                0,
                eg_md.qos.qid,
                eg_md.drop_reason
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {

            mirror.emit<switch_simple_mirror_metadata_h>(eg_md.dtel.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.dtel.session_id
            });

        }

    }
}

control IngressNatChecksum(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md) {
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    apply {
# 1034 "../shared/parde.p4"
    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;







    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ig_md.bd, ig_md.port_lag_index, ig_md.lkp.mac_src_addr});
        }




        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.pfc); // Ingress only
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
# 1141 "../shared/parde.p4"
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.pfc); //egress only
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);

        pkt.emit(hdr.sfc_pause);

        pkt.emit(hdr.dtel); // Egress only.







        pkt.emit(hdr.dtel_report); // Egress only.
        pkt.emit(hdr.dtel_switch_local_report); // Egress only.

        pkt.emit(hdr.dtel_drop_report); // Egress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
    }
}
# 145 "./switch_tofino2_y0.p4" 2
# 1 "../shared/port.p4" 1
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

# 1 "../shared/rewrite.p4" 1

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




# 1 "../shared/l2.p4" 1
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
# 28 "../shared/rewrite.p4" 2

//-----------------------------------------------------------------------------
// @param hdr : Parsed headers. For mirrored packet only Ethernet header is parsed.
// @param eg_md : Egress metadata fields.
// @param table_size : Number of mirror sessions.
//
// @flags PACKET_LENGTH_ADJUSTMENT : For mirrored packet, the length of the mirrored
// metadata fields is also accounted in the packet length. This flags enables the
// calculation of the packet length excluding the mirrored metadata fields.
//-----------------------------------------------------------------------------
control MirrorRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md,
                      out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
                      switch_uint32_t table_size=1024) {
    bit<16> length;

    action add_ethernet_header(in mac_addr_t src_addr,
                               in mac_addr_t dst_addr,
                               in bit<16> ether_type) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = ether_type;
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
    }

    action add_vlan_tag(vlan_id_t vid, bit<3> pcp, bit<16> ether_type) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].pcp = pcp;
        // hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].ether_type = ether_type;
    }

    action add_ipv4_header(in bit<8> diffserv,
                           in bit<8> ttl,
                           in bit<8> protocol,
                           in ipv4_addr_t src_addr,
                           in ipv4_addr_t dst_addr) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.diffserv = diffserv;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = ttl;
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.src_addr = src_addr;
        hdr.ipv4.dst_addr = dst_addr;
    }

    action add_gre_header(in bit<16> proto) {
        hdr.gre.setValid();
        hdr.gre.proto = proto;
        hdr.gre.C = 0;
        hdr.gre.R = 0;
        hdr.gre.K = 0;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
    }

    action add_erspan_common(bit<16> version_vlan, bit<10> session_id) {
        hdr.erspan.setValid();
        hdr.erspan.version_vlan = version_vlan;
        hdr.erspan.session_id = (bit<16>) session_id;
    }

    action add_erspan_type2(bit<10> session_id) {
        add_erspan_common(0x1000, session_id);
        hdr.erspan_type2.setValid();
        hdr.erspan_type2.index = 0;
    }

    action add_erspan_type3(bit<10> session_id, bit<32> timestamp, bool opt_sub_header) {
        add_erspan_common(0x2000, session_id);
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.ft_d_other = 0x4; // timestamp granularity IEEE 1588
        if (opt_sub_header) {





        }
    }

    action rewrite_(switch_qid_t qid) {
        eg_md.qos.qid = qid;
    }

    action rewrite_rspan(switch_qid_t qid, bit<3> pcp, vlan_id_t vid) {





    }

    action rewrite_erspan_type2(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        //TODO(msharif): Support for GRE sequence number.

        eg_md.qos.qid = qid;
        add_erspan_type2((bit<10>)eg_md.mirror.session_id);
        add_gre_header(0x88BE);

        // Total length = packet length + 32
        //   IPv4 (20) + GRE (4) + Erspan (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w32;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);

    }

    action rewrite_erspan_type2_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {

        eg_md.qos.qid = qid;
        add_erspan_type2((bit<10>) eg_md.mirror.session_id);
        add_gre_header(0x88BE);

        // Total length = packet length + 32
        //   IPv4 (20) + GRE (4) + Erspan (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w32;



        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);

    }

    action rewrite_erspan_type3(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {

        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w36;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);

    }

    action rewrite_erspan_type3_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {

        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w36;



        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);

    }

    action rewrite_erspan_type3_platform_specific(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {

        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22EB);

        // Total length = packet length + 44
        //   IPv4 (20) + GRE (4) + Erspan (12) + Platform Specific (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w44;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);

    }

    action rewrite_erspan_type3_platform_specific_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {

        eg_md.qos.qid = qid;

        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22EB);

        // Total length = packet length + 44
        //   IPv4 (20) + GRE (4) + Erspan (12) + Platform Specific (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = eg_md.pkt_length + 16w44;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);

    }

    action rewrite_dtel_report(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, switch_mirror_session_t session_id,
            bit<16> max_pkt_len) {

        // Dtel report header is added later in the pipeline.
        hdr.udp.setValid();
        hdr.udp.dst_port = udp_dst_port;
        hdr.udp.checksum = 0;

        // Total length = packet length + 28
        //   Add outer IPv4 (20) + UDP (8)
        add_ipv4_header(tos, ttl, 17, sip, dip);






        hdr.ipv4.total_len = eg_md.pkt_length + 16w28;
        hdr.udp.length = eg_md.pkt_length + 16w8;




        hdr.ipv4.flags = 2;

        add_ethernet_header(smac, dmac, 0x0800);
# 315 "../shared/rewrite.p4"
        eg_intr_md_for_dprsr.mtu_trunc_len = (bit<14>)max_pkt_len;





        eg_md.pkt_length = eg_md.pkt_length +
                           DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH;



    }

    action rewrite_dtel_report_with_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, switch_mirror_session_t session_id,
            bit<16> max_pkt_len) {

        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port,
                            session_id, max_pkt_len);
        hdr.udp.src_port = eg_md.dtel.hash[15:0];

    }

    action rewrite_dtel_report_without_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, bit<16> udp_src_port,
            switch_mirror_session_t session_id, bit<16> max_pkt_len) {

        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port,
                            session_id, max_pkt_len);
        hdr.udp.src_port = udp_src_port;

    }

    action rewrite_ip_udp_lengths() {


        // Subtract outer ethernet
        hdr.ipv4.total_len = eg_md.pkt_length - 16w14;
        hdr.udp.length = eg_md.pkt_length - 16w34;




    }

    action rewrite_dtel_ifa_clone() {
        /* Indicates that IFA clone rewrite needs to occur.
         * For IFA identification using DSCP, not done in place here since
         * the rewrite differs for IPv4 and IPv6 packets. */
        eg_md.dtel.ifa_cloned = 1;
    }




    table rewrite {
        key = { eg_md.mirror.session_id : exact; }
        actions = {
            NoAction;
            rewrite_;
            rewrite_rspan;
            rewrite_erspan_type2;
            rewrite_erspan_type3;
            rewrite_erspan_type2_with_vlan;
            rewrite_erspan_type3_with_vlan;





            rewrite_dtel_report_with_entropy;
            rewrite_dtel_report_without_entropy;







        }

        const default_action = NoAction;
        size = table_size;
    }


    action adjust_length(bit<16> length_offset) {
        eg_md.pkt_length = eg_md.pkt_length + length_offset;
        eg_md.mirror.type = 0;
    }

    table pkt_length {
        key = { eg_md.mirror.type : exact; }
        actions = { adjust_length; }
        const entries = {
            //-14
            2 : adjust_length(0xFFF2);
# 451 "../shared/rewrite.p4"
            //-13
            1 : adjust_length(0xFFF3);




            3 : adjust_length(0);
            //-2
            4 : adjust_length(0xFFFE);

            //-7
            5: adjust_length(0xFFF9);






            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header) - 4 bytes of CRC */
            255: adjust_length(20);

        }
    }

    action rewrite_ipv4_udp_len_truncate() {

        // (eth + crc) = 18
        hdr.ipv4.total_len = (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len - 16w18;
        // (eth + ipv4 + crc) = 38
        hdr.udp.length = (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len - 16w38;






    }

    table pkt_len_trunc_adjustment {
        key = {
                hdr.udp.isValid() : exact ;
                hdr.ipv4.isValid() : exact;
        }

        actions = {
                NoAction;
                rewrite_ipv4_udp_len_truncate;
        }

        const default_action = NoAction;
        const entries = {
            (true, true) : rewrite_ipv4_udp_len_truncate();
        }
    }

    apply {

        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {

            pkt_length.apply();

            rewrite.apply();


            eg_md.pkt_length = eg_md.pkt_length |-| (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len;
            if (eg_md.pkt_length > 0 && eg_intr_md_for_dprsr.mtu_trunc_len > 0) {
                pkt_len_trunc_adjustment.apply();



            }


        }

    }
}

control Rewrite(inout switch_header_t hdr,
                inout switch_egress_metadata_t eg_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t bd_table_size) {
    EgressBd(bd_table_size) egress_bd;
    switch_smac_index_t smac_index;

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {




    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {







    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {






    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {






    }

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
# 592 "../shared/rewrite.p4"
            rewrite_l3;

        }




        const default_action = rewrite_l3(0, 0);

        size = nexthop_table_size;
    }

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
        size = MIN_TABLE_SIZE;
    }

    // RFC 1112
    action rewrite_ipv4_multicast() {
        //XXX might be possible on Tofino as dst_addr[23] is 0.
        //hdr.ethernet.dst_addr[22:0] = hdr.ipv4.dst_addr[22:0];
        //hdr.ethernet.dst_addr[47:24] = 0x01005E;
    }

    // RFC 2464
    action rewrite_ipv6_multicast() {
        //hdr.ethernet.dst_addr[31:0] = hdr.ipv6.dst_addr[31:0];
        //hdr.ethernet.dst_addr[47:32] = 16w0x3333;
    }

    table multicast_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.dst_addr[31:28] : ternary;
            //hdr.ipv6.isValid() : exact;
            //hdr.ipv6.dst_addr[127:96] : ternary;
        }

        actions = {
            NoAction;
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }

        const default_action = NoAction;
    }


    action rewrite_ipv4() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action rewrite_ipv6() {

        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;

    }

    table ip_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            rewrite_ipv4;
            rewrite_ipv6;
        }

        const entries = {
            (true, false) : rewrite_ipv4();
            (false, true) : rewrite_ipv6();
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        // Should not rewrite packets redirected to CPU.



        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.flags.routed) {

            nexthop_rewrite.apply();
        }

        egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.pkt_src,
            eg_md.bd_label, smac_index, eg_md.checks.mtu);

        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.flags.routed) {
            ip_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}
# 24 "../shared/port.p4" 2

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------
control PortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {

    action set_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        mirror_md.type = 1;
        mirror_md.src = src;
        mirror_md.session_id = session_id;



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

control IngressPortMapping(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t port_vlan_table_size,
        switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
        switch_uint32_t vlan_table_size=4096,
        switch_uint32_t double_tag_table_size=1024) {

    PortMirror(port_table_size) port_mirror;
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // This register is used to check whether a port is a mermber of a vlan (bd)
    // or not. (port << 12 | vid) is used as the index to read the membership
    // status.To save resources, only 7-bit local port id is used to calculate
    // the indes.
    const bit<32> vlan_membership_size = 1 << 19;
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action terminate_cpu_packet() {
        // ig_md.bypass = hdr.cpu.reason_code;
        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index =
            (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;
        ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        terminate_cpu_packet();
    }

    action set_port_properties(
            switch_yid_t exclusion_id,
            switch_learning_mode_t learning_mode,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc,
            switch_meter_index_t meter_index,
            switch_sflow_id_t sflow_session_id,
            bool mac_pkt_class,
            bit<1> sfc_enable) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = SWITCH_FLOOD;
        ig_md.flags.mac_pkt_class = mac_pkt_class;






    }

    table port_mapping {
        key = {
            ig_md.port : exact;




        }

        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }




        size = port_table_size;

    }

    action port_vlan_miss() {
        //ig_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(switch_bd_t bd,
                             switch_vrf_t vrf,
                             switch_bd_label_t bd_label,
                             switch_rid_t rid,
                             switch_stp_group_t stp_group,
                             switch_learning_mode_t learning_mode,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_rmac_group_t rmac_group,
                             switch_nat_zone_t zone) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group = rmac_group;
        ig_md.stp.group = stp_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv6_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;



    }

    // (port, vlan[0], vlan[1]) --> bd mapping
    table port_double_tag_to_bd_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[0].vid : exact;
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[1].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = double_tag_table_size;
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
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
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
            hdr.vlan_tag[0].vid : exact;
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
        key = { hdr.cpu.ingress_bd : exact; }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = bd_table_size;
    }

    action set_interface_properties(switch_if_label_t if_label) {
        ig_md.checks.same_if = SWITCH_FLOOD;
        ig_md.if_label = if_label;
    }

    table port_vlan_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_vlan_table_size;
    }

    table port_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    action set_peer_link_properties() {
        ig_intr_md_for_tm.rid = SWITCH_RID_DEFAULT;
        ig_md.flags.peer_link = true;
    }

    table peer_link {
        key = { ig_md.port_lag_index : exact; }
        actions = {
            NoAction;
            set_peer_link_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {

        port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror);


        switch (port_mapping.apply().action_run) {






            set_port_properties : {



                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }



            }
        }
# 367 "../shared/port.p4"
        // Check vlan membership
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>) ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ig_md.port[6:0], hdr.vlan_tag[0].vid});
            ig_md.flags.port_vlan_miss =
                (bool)check_vlan_membership.execute(pv_hash_);
        }




    }
}
# 392 "../shared/port.p4"
// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control LAG(inout switch_ingress_metadata_t ig_md,
            in switch_hash_t hash,
            out switch_port_t egress_port) {




    Hash<switch_uint16_t>(HashAlgorithm_t.CRC16) selector_hash;

    ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
    ActionSelector(lag_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   LAG_MAX_MEMBERS_PER_GROUP,
                   LAG_GROUP_TABLE_SIZE) lag_selector;

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    action set_peer_link_port(switch_port_t port, switch_port_lag_index_t port_lag_index) {
        egress_port = port;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
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

    apply {
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress port lookup
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
//
// @flag EGRESS_PORT_MIRROR_ENABLE: Enables egress port-base mirroring.
//-----------------------------------------------------------------------------
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;

    action port_normal(switch_port_lag_index_t port_lag_index,
                       switch_eg_port_lag_label_t port_lag_label,
                       switch_qos_group_t qos_group,

                       PortSpeed port_speed,
                       LinkToType link_to_type,

                       switch_meter_index_t meter_index,
                       switch_sflow_id_t sflow_session_id,
                       bool mlag_member) {
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;

        eg_md.qos.port_speed = port_speed;
        eg_md.qos.link_to_type = link_to_type;

        eg_md.flags.mlag_member = mlag_member;






    }

    table port_mapping {
        key = { port : exact; }

        actions = {
            port_normal;
        }

        size = table_size;
    }

    apply {
        port_mapping.apply();


        port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror);

    }
}

//-----------------------------------------------------------------------------
// CPU-RX Header Insertion
//-----------------------------------------------------------------------------
control EgressCpuRewrite(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {

    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.reserved = 0;
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.reserved2 = 0;

        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
        hdr.cpu.port_lag_index = (bit<16>) eg_md.port_lag_index;
        hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.ether_type = 0x9000;
    }

    table cpu_port_rewrite {
        key = { port : exact; }

        actions = {
            cpu_rewrite;
        }

        size = table_size;
    }

    apply {
        cpu_port_rewrite.apply();
    }
}
# 146 "./switch_tofino2_y0.p4" 2
# 1 "../shared/validation.p4" 1
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
// Packet validaion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// ============================================================================
control PktValidation(
        in switch_header_t hdr,
        inout switch_ingress_flags_t flags,
        inout switch_lookup_fields_t lkp,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        out switch_drop_reason_t drop_reason) {
//-----------------------------------------------------------------------------
// Validate outer packet header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------
    const switch_uint32_t table_size = MIN_TABLE_SIZE;

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action malformed_non_ip_pkt(bit<8> reason) {
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        malformed_pkt(reason);
    }

    action valid_non_ip_pkt_untagged(switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_non_ip_pkt_tagged(switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_non_ip_pkt_double_tagged(switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[1].ether_type;
        lkp.pcp = hdr.vlan_tag[1].pcp;
    }

    action valid_ipv6_pkt(bool is_link_local) {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        flags.link_local = is_link_local;
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
        lkp.ip_frag = ip_frag;
    }

    action malformed_ipv4_pkt(bit<8> reason, switch_ip_frag_t ip_frag) {
        // Set common lookup fields just for dtel acl and hash purposes
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv4_pkt(ip_frag);
        malformed_pkt(reason);
    }

    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv6_pkt(false);
        malformed_pkt(reason);
    }

    action valid_ipv4_pkt_untagged(switch_ip_frag_t ip_frag, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv4_pkt(ip_frag);
    }

    action valid_ipv4_pkt_tagged(switch_ip_frag_t ip_frag, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
        valid_ipv4_pkt(ip_frag);
    }

    action valid_ipv4_pkt_double_tagged(switch_ip_frag_t ip_frag, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[1].ether_type;
        lkp.pcp = hdr.vlan_tag[1].pcp;
        valid_ipv4_pkt(ip_frag);
    }

    action valid_ipv6_pkt_untagged(bool is_link_local, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv6_pkt(is_link_local);
    }

    action valid_ipv6_pkt_tagged(bool is_link_local, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
        valid_ipv6_pkt(is_link_local);
    }


    action valid_ipv6_pkt_double_tagged(bool is_link_local, switch_pkt_type_t pkt_type) {
        lkp.pkt_type = pkt_type;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[1].ether_type;
        lkp.pcp = hdr.vlan_tag[1].pcp;
        valid_ipv6_pkt(is_link_local);
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;




            hdr.ipv4.isValid() : ternary;
            flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;

            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary; //TODO define the bit range.
        }

        actions = {
            malformed_non_ip_pkt;
            malformed_ipv4_pkt;
            malformed_ipv6_pkt;
            valid_non_ip_pkt_untagged;
            valid_non_ip_pkt_tagged;
            valid_ipv4_pkt_untagged;
            valid_ipv4_pkt_tagged;
            valid_ipv6_pkt_untagged;
            valid_ipv6_pkt_tagged;





        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
        lkp.tcp_flags = hdr.tcp.flags;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
        lkp.tcp_flags = 0;
    }

    action set_icmp_type() {
        lkp.l4_src_port[7:0] = hdr.icmp.type;
        lkp.l4_src_port[15:8] = hdr.icmp.code;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
    }

    action set_igmp_type() {
        lkp.l4_src_port[7:0] = hdr.igmp.type;
        lkp.l4_src_port[15:8] = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
    }

    action set_arp_opcode() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
        lkp.arp_opcode = hdr.arp.opcode;
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
            hdr.arp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;
            set_igmp_type;
            set_arp_opcode;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false, false, false) : set_tcp_ports();
            (false, true, false, false, false) : set_udp_ports();
            (false, false, true, false, false) : set_icmp_type();
            (false, false, false, true, false) : set_igmp_type();
            (false, false, false, false, true) : set_arp_opcode();
        }
        size = 32;
    }

    apply {
        validate_ethernet.apply();
        validate_other.apply();
    }
}

// ============================================================================
// Same MAC Check
// Checks if source mac address matches with destination mac address
// ============================================================================
control SameMacCheck(inout switch_ingress_metadata_t ig_md) {

    action compute_same_mac_check() {
        ig_md.drop_reason = SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK;
    }

    table same_mac_check {
        key = {
            ig_md.same_mac : exact;
        }
        actions = {
            NoAction;
            compute_same_mac_check;
        }
        const default_action = NoAction;
        const entries = {
            (48w0x0) : compute_same_mac_check();
        }
    }

    apply {
        ig_md.same_mac = ig_md.lkp.mac_src_addr ^ ig_md.lkp.mac_dst_addr;
        if (!ig_md.flags.routed) {
            same_mac_check.apply();
        }
    }
}


// ============================================================================
// Inner packet validaion
// Validate ethernet, Ipv4 or Ipv6 common lookup fields.
// NOTE:
// For IPinIP packets, the actions are valid_ipv*. This would set the L2
// lookup fields to 0. The RMAC table is setup to ignore the dmac to process
// these packets
// ============================================================================
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_flags_t flags,
        inout switch_drop_reason_t drop_reason) {

    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = pkt_type;
    }

    action valid_ipv4_pkt(switch_pkt_type_t pkt_type) {
        // Set the common IP lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = 0x0800;
        lkp.pkt_type = pkt_type;
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.inner_ipv4.diffserv;
        lkp.ip_ttl = hdr.inner_ipv4.ttl;
        lkp.ip_proto = hdr.inner_ipv4.protocol;
        lkp.ip_src_addr = (bit<128>) hdr.inner_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.inner_ipv4.dst_addr;
    }

    action valid_ipv6_pkt(switch_pkt_type_t pkt_type) {

        // Set the common IP lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = 0x86dd;
        lkp.pkt_type = pkt_type;
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        flags.link_local = false;

    }

    action set_tcp_ports() {
        lkp.l4_src_port = hdr.inner_tcp.src_port;
        lkp.l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.inner_udp.src_port;
        lkp.l4_dst_port = hdr.inner_udp.dst_port;
    }

    action valid_ipv4_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_tcp_ports();
    }

    action valid_ipv4_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_udp_ports();
    }

    action valid_ipv6_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_tcp_ports();
    }

    action valid_ipv6_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_udp_ports();
    }

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid() : ternary;
            hdr.inner_ethernet.dst_addr : ternary;

            hdr.inner_ipv6.isValid() : ternary;
            hdr.inner_ipv6.version : ternary;
            hdr.inner_ipv6.hop_limit : ternary;

            hdr.inner_ipv4.isValid() : ternary;
            flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.ihl : ternary;
            hdr.inner_ipv4.ttl : ternary;

            hdr.inner_tcp.isValid() : ternary;
            hdr.inner_udp.isValid() : ternary;
        }

        actions = {
            NoAction;
            valid_ipv4_tcp_pkt;
            valid_ipv4_udp_pkt;
            valid_ipv4_pkt;
            valid_ipv6_tcp_pkt;
            valid_ipv6_udp_pkt;
            valid_ipv6_pkt;
            valid_ethernet_pkt;
            malformed_pkt;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        validate_ethernet.apply();
    }
}
# 147 "./switch_tofino2_y0.p4" 2
# 1 "../shared/rewrite.p4" 1

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
# 148 "./switch_tofino2_y0.p4" 2
# 1 "../shared/multicast.p4" 1
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
// IP Multicast
// @param src_addr : IP source address.
// @param grp_addr : IP group address.
// @param bd : Bridge domain.
// @param group_id : Multicast group id.
// @param s_g_table_size : (s, g) table size.
// @param star_g_table_size : (*, g) table size.
//-----------------------------------------------------------------------------
control MulticastBridge<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {





    }
}

control MulticastBridgev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {





    }
}

control MulticastRoute<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {





    }
}


control MulticastRoutev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {





    }
}

control IngressMulticast(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_s_g_table_size,
        switch_uint32_t ipv4_star_g_table_size,
        switch_uint32_t ipv6_s_g_table_size,
        switch_uint32_t ipv6_star_g_table_size) {

    // For each rendezvous point (RP), there is a list of interfaces for which
    // the switch is the designated forwarder (DF).

    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(
        ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
    MulticastRoutev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_route;

    switch_multicast_rpf_group_t rpf_check;
    bit<1> multicast_hit;

    action set_multicast_route() {
        ig_md.egress_port_lag_index = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
    }

    action set_multicast_bridge(bool mrpf) {
        ig_md.egress_port_lag_index = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
    }

    action set_multicast_flood(bool mrpf, bool flood) {
        ig_md.egress_port_lag_index = SWITCH_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;
    }

    table fwd_result {
        key = {
            multicast_hit : ternary;
            lkp.ip_type : ternary;
            ig_md.ipv4.multicast_snooping : ternary;
            ig_md.ipv6.multicast_snooping : ternary;
            ig_md.multicast.mode : ternary;
            rpf_check : ternary;
        }

        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
    }

    apply {
# 436 "../shared/multicast.p4"
    }
}


//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

    action flood(switch_mgid_t mgid) {
        ig_md.multicast.id = mgid;
    }

    table bd_flood {
        key = {
            ig_md.bd : exact @name("bd");
            ig_md.lkp.pkt_type : exact @name("pkt_type");



        }

        actions = { flood; }
        size = table_size;
    }

    apply {
        bd_flood.apply();
    }
}

control MulticastReplication(in switch_rid_t replication_id,
                             in switch_port_t port,
                             inout switch_egress_metadata_t eg_md)(
                             switch_uint32_t table_size=4096) {
    action rid_hit(switch_bd_t bd) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;
    }

    action rid_miss() {
        eg_md.flags.routed = false;
    }

    table rid {
        key = { replication_id : exact; }
        actions = {
            rid_miss;
            rid_hit;
        }

        size = table_size;
        const default_action = rid_miss;
    }

    apply {
# 501 "../shared/multicast.p4"
    }
}
# 149 "./switch_tofino2_y0.p4" 2
# 1 "../shared/qos.p4" 1
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




# 1 "../shared/acl.p4" 1
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
# 27 "../shared/qos.p4" 2

//-------------------------------------------------------------------------------------------------
// ECN Access control list
//
// @param ig_md : Ingress metadata fields.
// @param lkp : Lookup fields.
// @param pkt_color : Packet color
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control ECNAcl(in switch_ingress_metadata_t ig_md,
               in switch_lookup_fields_t lkp,
               inout switch_pkt_color_t pkt_color)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }

    table acl {
        key = {
            ig_md.port_lag_label : ternary;
            lkp.ip_tos : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            NoAction;
            set_ingress_color;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// PFC Watchdog
// Once PFC storm is detected on a queue, the PFC watchdog can drop or forward at per queue level.
// On drop action, all existing packets in the output queue and all subsequent packets destined to
// the output queue are discarded.
//
// @param port
// @param qid : Queue Id.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control PFCWd(in switch_port_t port,
               in switch_qid_t qid,
               out bool flag)(
               switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action acl_deny() {
        flag = true;
        stats.count();
    }

    table acl {
        key = {
            qid : exact;
            port : exact;
        }

        actions = {
            @defaultonly NoAction;
            acl_deny;
        }

        const default_action = NoAction;
        counters = stats;
        size = table_size;
    }

    apply {

        acl.apply();

    }
}


control PfcIngress(inout switch_header_t hdr,
                   in ingress_intrinsic_metadata_t ig_intr_md,
                   out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) pfc_ingress_stats;

    action pfc_ingress_count_and_forward() {
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        pfc_ingress_stats.count();
    }

    action do_nothing() {
        pfc_ingress_stats.count();
    }

    table pfc_ingress_count_and_forward_tbl {
        key = {hdr.pfc.isValid() : exact;}
        actions = {
            do_nothing;
            pfc_ingress_count_and_forward;
        }
        default_action = pfc_ingress_count_and_forward;
        const entries = {((bool)0x0) : do_nothing();}
        counters = pfc_ingress_stats;
    }

    apply {
        if (hdr.pfc.isValid()) {
            pfc_ingress_count_and_forward_tbl.apply();
        }
    }
}

control PfcEgress(inout switch_header_t hdr,
                  out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) pfc_egress_stats;

    action pfc_egress_count_and_drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        pfc_egress_stats.count();
    }

    action do_nothing() {
        pfc_egress_stats.count();
    }

    table pfc_egress_count_and_drop_tbl {
        key = {hdr.pfc.isValid() : exact;}
        actions = {
            do_nothing;
            pfc_egress_count_and_drop;
        }
        default_action = pfc_egress_count_and_drop;
        const entries = {((bool)0x0) : do_nothing();}
        counters = pfc_egress_stats;
    }

    apply {
        if (hdr.pfc.isValid()) {
            pfc_egress_count_and_drop_tbl.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// Ingress QosMap
// QoS Classification - map dscp/cos -> tc, color
//-------------------------------------------------------------------------------------------------
control IngressQoSMap(inout switch_header_t hdr,
                      inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t dscp_map_size=2048,
        switch_uint32_t pcp_map_size=256) {

    action set_ingress_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
    }

    action set_ingress_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
    }

    action set_ingress_tc_and_color(
            switch_tc_t tc, switch_pkt_color_t color) {
        set_ingress_tc(tc);
        set_ingress_color(color);
    }

    table dscp_tc_map {
        key = {
            ig_md.qos.group : exact;
            ig_md.lkp.ip_tos[7:2] : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        size = dscp_map_size;
    }

    table pcp_tc_map {
        key = {
            ig_md.qos.group : exact;
            ig_md.lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        size = pcp_map_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP ==
            SWITCH_QOS_TRUST_MODE_TRUST_DSCP && ig_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            dscp_tc_map.apply();
        } else if(!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP ==
                  SWITCH_QOS_TRUST_MODE_TRUST_PCP && hdr.vlan_tag[0].isValid()) {
            pcp_tc_map.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// Ingress QosMap
// QoS Classification - map Traffic Class -> icos, qid
//-------------------------------------------------------------------------------------------------
control IngressTC(inout switch_ingress_metadata_t ig_md)() {

    const bit<32> tc_table_size = 1024;

    action set_icos(switch_cos_t icos) {
        ig_md.qos.icos = icos;
    }

    action set_queue(switch_qid_t qid) {
        ig_md.qos.qid = qid;
    }

    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    table traffic_class {
        key = {
            ig_md.port : ternary @name("port");
            ig_md.qos.color : ternary @name("color");
            ig_md.qos.tc : exact @name("tc");
        }

        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }

        size = tc_table_size;
    }

    apply {

        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0)) {
            traffic_class.apply();
        }

    }
}

//-------------------------------------------------------------------------------------------------
// Ingress per PPG Packet and Byte Stats
//-------------------------------------------------------------------------------------------------
control PPGStats(inout switch_ingress_metadata_t ig_md)() {

    const bit<32> ppg_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    table ppg {
        key = {
            ig_md.port : exact @name("port");
            ig_md.qos.icos : exact @name("icos");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = ppg_table_size;
        counters = ppg_stats;
    }

    apply {
        ppg.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Egress QoS Marking
// {TC, Color} -> DSCP/PCP
//-------------------------------------------------------------------------------------------------
control EgressQoS(inout switch_header_t hdr,
                  in switch_port_t port,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t table_size=1024) {
    // Overwrites 6-bit dscp only.
    action set_ipv4_dscp(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv4_tos(switch_uint8_t tos) {
        hdr.ipv4.diffserv = tos;
    }

    // Overwrites 6-bit dscp only.
    action set_ipv6_dscp(bit<6> dscp) {

        hdr.ipv6.traffic_class[7:2] = dscp;

    }

    action set_ipv6_tos(switch_uint8_t tos) {

        hdr.ipv6.traffic_class = tos;

    }

    action set_vlan_pcp(bit<3> pcp) {
        hdr.vlan_tag[0].pcp = pcp;
    }

    table qos_map {
        key = {
            eg_md.qos.group : ternary @name("group");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.qos.color : ternary @name("color");
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv4_tos;
            set_ipv6_dscp;
            set_ipv6_tos;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {

        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_QOS != 0)) {
            qos_map.apply();
        }

    }
}

//-------------------------------------------------------------------------------------------------
// Per Queue Stats
//-------------------------------------------------------------------------------------------------
control EgressQueue(in switch_port_t port,
                    inout switch_egress_metadata_t eg_md)(
                    switch_uint32_t queue_table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;

    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.



    table queue {
        key = {
            port : exact;
            eg_md.qos.qid : exact @name("qid");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        size = queue_table_size;
        const default_action = NoAction;
        counters = queue_stats;
    }

    apply {
        queue.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Heavy-Hitter or Elephant Detection
// Identify source or desitnation IP with traffic rate exceeding a programmable threshold
//-------------------------------------------------------------------------------------------------

control ETrap(inout switch_ingress_metadata_t ig_md) {



    Meter<switch_etrap_index_t>((1<<11), (MeterType_t.BYTES)) meter;

    action set_meter_and_tc(
        switch_etrap_index_t index,
        switch_tc_t tc) {
        ig_md.qos.etrap_index = index;
        ig_md.qos.etrap_tc = tc;
    }

    table ipv4_acl {
        key = {
            ig_md.lkp.ip_src_addr[31:0] : ternary;
            ig_md.lkp.ip_dst_addr[31:0] : ternary;
        }
        actions = {
            set_meter_and_tc;
        }
        size = (1<<11)/2;
    }

    table ipv6_acl {
        key = {
            ig_md.lkp.ip_src_addr[63:0] : ternary;
            ig_md.lkp.ip_dst_addr[63:0] : ternary;
        }
        actions = {
            set_meter_and_tc;
        }
        size = (1<<11)/2;
    }

    action meter_action(switch_etrap_index_t index) {
        ig_md.qos.etrap_color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            ig_md.qos.etrap_index : exact;
        }
        actions = {
            meter_action;
        }
        size = (1<<11);
    }

    DirectRegister<bit<8>>() meter_state_reg;
    DirectRegisterAction<bit<8>, bit<8>>(meter_state_reg) meter_state_change = {
        void apply(inout bit<8> value, out bit<8> rv) {
            if (value > (bit<8>) ig_md.qos.etrap_color) {
                rv = SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE;
            } else if (value < (bit<8>) ig_md.qos.etrap_color) {
                rv = SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE |
                     SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT;
            }
            value = (bit<8>) ig_md.qos.etrap_color;
        }
    };

    action meter_state_action() {
        ig_md.dtel.report_type = meter_state_change.execute();
    }

    table meter_state {
        key = {
            ig_md.qos.etrap_index : exact;
        }
        actions = {
            meter_state_action;
        }
        size = (1<<11);
        registers = meter_state_reg;
    }

    Register<bit<8>, bit<11>>((1<<11), 0) etrap_state_reg;
    RegisterAction<bit<8>, bit<11>, bit<8>>(etrap_state_reg) etrap_state_red_action = {
        void apply(inout bit<8> val, out bit<8> rv) {
            rv = ig_md.qos.etrap_tc;
            val = 0x1;
        }
    };

    RegisterAction<bit<8>, bit<11>, bit<8>>(etrap_state_reg) etrap_state_green_action = {
        void apply(inout bit<8> val, out bit<8> rv) {
            bit<8> temp;
            if (val == 0x1) {
                temp = ig_md.qos.etrap_tc;
            } else {
                temp = ig_md.qos.tc;
            }
            rv = temp;
        }
    };

    action etrap_red_state() {
        ig_md.qos.tc = etrap_state_red_action.execute(ig_md.qos.etrap_index);
    }

    action etrap_green_state() {
        ig_md.qos.tc = etrap_state_green_action.execute(ig_md.qos.etrap_index);
    }

    table etrap_state {
        key = {
            ig_md.qos.etrap_color : exact;
        }
        actions = {
            etrap_red_state;
            etrap_green_state;
        }
        size = 3;
    }

    apply {
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
            ipv6_acl.apply();
        } else if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_acl.apply();
        }
        meter_index.apply();
        meter_state.apply();
        etrap_state.apply();
    }
}
# 150 "./switch_tofino2_y0.p4" 2
# 1 "../shared/meter.p4" 1
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




# 1 "../shared/acl.p4" 1
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
# 27 "../shared/meter.p4" 2

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param ig_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table [per pipe]
// @param meter_size : Size of storm control meters [global pool]
// Stats table size must be 512 per pipe - each port with 6 stat entries [2 colors per pkt-type]
//-------------------------------------------------------------------------------------------------
control StormControl(inout switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=256,
                     switch_uint32_t meter_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(meter_size, MeterType_t.PACKETS) meter;

    action count() {
        storm_control_stats.count();
        flag = false;
    }

    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    table stats {
        key = {
            ig_md.qos.storm_control_color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        ig_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key = {
            ig_md.port : exact;
            pkt_type : ternary;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {







    }
}

//-------------------------------------------------------------------------------------------------
// Ingress Mirror Meter
//-------------------------------------------------------------------------------------------------
control IngressMirrorMeter(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        ig_md.mirror.type = 0;
    }

    table meter_action {
        key = {
            color: exact;
            ig_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            ig_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {




    }
}

//-------------------------------------------------------------------------------------------------
// Egress Mirror Meter
//-------------------------------------------------------------------------------------------------
control EgressMirrorMeter(inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        eg_md.mirror.type = 0;
    }

    table meter_action {
        key = {
            color: exact;
            eg_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            eg_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {




    }
}
# 357 "../shared/meter.p4"
//-------------------------------------------------------------------------------------------------
// Ingress ACL Meter
//-------------------------------------------------------------------------------------------------
control IngressAclMeter(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    action count() {
        stats.count();
        ig_md.flags.acl_meter_drop = false;
    }

    action drop_and_count() {
        stats.count();
        ig_md.flags.acl_meter_drop = true;
    }

    table meter_action {
        key = {
            color: exact;
            ig_md.qos.acl_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*3;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            ig_md.qos.acl_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}
# 151 "./switch_tofino2_y0.p4" 2
# 1 "../shared/wred.p4" 1
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

//-------------------------------------------------------------------------------------------------
// Weighted Random Early Dropping (WRED)
//
// @param hdr : Parse headers. Only ipv4.diffserv or ipv6.traffic_class are modified.
// @param eg_md : Egress metadata fields.
// @param eg_intr_md
// @param flag : A flag indicating that the packet should get dropped by system ACL.
//-------------------------------------------------------------------------------------------------
control WRED(inout switch_header_t hdr,
             in switch_egress_metadata_t eg_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool wred_drop) {

    switch_wred_index_t index;

    // Flag indicating that the packet needs to be marked/dropped.
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 10;

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    // -----------------------------------------------------------
    // Select a profile and apply wred filter
    // A total of 1k profiles are supported.
    // -----------------------------------------------------------
    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>) wred.execute(eg_md.qos.qdepth, wred_index);
    }

    // Asymmetric table to get the attached WRED profile.
    table wred_index {
        key = {
           eg_intr_md.egress_port : exact @name("port");
           eg_md.qos.qid : exact @name("qid");
           eg_md.qos.color : exact @name("color");
        }

        actions = {
            NoAction;
            set_wred_index;
        }

        const default_action = NoAction;
        size = wred_size;
    }

    // -----------------------------------------------------------
    // Mark or Drop packet based on WRED profile and ECN bits
    // -----------------------------------------------------------
    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    action drop() {
        wred_drop = true;
    }

    table v4_wred_action {
        key = {
            index : exact;
            hdr.ipv4.diffserv[1:0] : exact;
        }

        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
        }

        // Requires 3 entries per WRED profile to drop or mark IPv4 packets.
        size = 3 * wred_size;
    }

    table v6_wred_action {
        key = {
            index : exact;
            hdr.ipv6.traffic_class[1:0] : exact;
        }

        actions = {
            NoAction;
            drop;
            set_ipv6_ecn;
        }

        // Requires 3 entries per WRED profile to drop or mark IPv6 packets.
        size = 3 * wred_size;
    }

    // -----------------------------------------------------------------------------------------------
    // Counts packets marked or dropped by WRED. Packets "allowed" by wred logic are not counted here.
    // -----------------------------------------------------------------------------------------------
    action count() { stats.count(); }

    table wred_stats {
        key = {
            eg_intr_md.egress_port : exact @name("port");
            eg_md.qos.qid : exact @name("qid");
            eg_md.qos.color : exact @name("color");
            wred_drop : exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = 2 * wred_size;
        counters = stats;
    }

    apply {

        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_WRED != 0))
            wred_index.apply();

        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_WRED != 0) && wred_flag == 1) {
            if(hdr.ipv4.isValid()) {
                switch(v4_wred_action.apply().action_run) {
                    NoAction : {}
                    default : { wred_stats.apply(); }
                }
            } else if(hdr.ipv6.isValid()) {
                switch(v6_wred_action.apply().action_run) {
                    NoAction : {}
                    default : { wred_stats.apply(); }
                }
            }
        }

    }
}
# 152 "./switch_tofino2_y0.p4" 2
# 1 "../shared/acl.p4" 1
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
# 153 "./switch_tofino2_y0.p4" 2
# 1 "../shared/dtel.p4" 1
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
            ig_md.qos.qid: ternary @name("qid");
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
control DropReport(in switch_header_t hdr,
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
            flag[0:0] = filter1.execute(hash[(17 - 1):0]);
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:(32 - 17)]);

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
            if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_md.qos.qdepth) {
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
            eg_md.qos.qid : exact @name("qid");
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
            eg_md.qos.qid : exact @name("qid");
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




        digest = hash.get({eg_md.dtel.latency, eg_md.ingress_port, eg_md.port, eg_md.dtel.hash});
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            flag = filter1.execute(eg_md.dtel.hash[15:0]);
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            /* CODE_HACK Workaround for reduction_or_group not working */
            flag = flag | filter2.execute(eg_md.dtel.hash[31:16]);

    }
}

control IngressDtel(in switch_header_t hdr,
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
        key = {
            hdr.ethernet.isValid() : ternary;
            hash : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {


        dod.apply(ig_md, ig_intr_for_tm);

        if (ig_md.mirror.type == 0)
            mod.apply(ig_md.drop_reason, ig_md.dtel, ig_md.mirror);


        mirror_session.apply();

    }
}


control DtelConfig(inout switch_header_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
# 420 "../shared/dtel.p4"
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
            switch_dtel_hw_id_t hw_id,




            bit<4> next_proto,

            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 502 "../shared/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved = 0;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;

    }

    action update_and_mirror_truncate(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type) {



        update(switch_id, hw_id, next_proto, report_type);

        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 551 "../shared/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status; // etrap indication
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;

    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {

        hdr.ipv6.traffic_class[7:2] = dscp;

    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[2:2] = dscp_bit_value;

    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[3:3] = dscp_bit_value;

    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[4:4] = dscp_bit_value;

    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[5:5] = dscp_bit_value;

    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[6:6] = dscp_bit_value;

    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[7:7] = dscp_bit_value;

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

            eg_md.lkp.tcp_flags[2:0] : ternary;
# 728 "../shared/dtel.p4"
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
# 765 "../shared/dtel.p4"
        }

        const default_action = NoAction;
    }

    apply {
        config.apply();
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

control EgressDtel(inout switch_header_t hdr,
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
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

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
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    apply {

        eg_md.dtel.latency =
            eg_md.timestamp[31:0] - eg_md.ingress_timestamp[31:0];
        if (eg_md.pkt_src == SWITCH_PKT_SRC_DEFLECTED && hdr.dtel_drop_report.isValid())



            eg_md.port = hdr.dtel_report.egress_port;

        ingress_port_conversion.apply();
        egress_port_conversion.apply();


        queue_report.apply(eg_md, eg_intr_md, eg_md.dtel.queue_report_flag);



        /* if DTEL_QUEUE_REPORT_ENABLE,
         * flow_report must come after queue_report,
         * since latency masking is done in table queue_alert */
        flow_report.apply(eg_md, eg_md.dtel.flow_report_flag);



        drop_report.apply(hdr, eg_md, hash, eg_md.dtel.drop_report_flag);
# 913 "../shared/dtel.p4"
    }
}
# 154 "./switch_tofino2_y0.p4" 2


# 1 "../shared/sfc_ghost.p4" 1
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

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const bit<1> ghost_total_cnt_idx = 1;

const ping_pong_t ingress_access_ping = 0;
const ping_pong_t ghost_access_ping = 1;

// TODO: This is Tofino2 only (9 bit per port, 7 bit per queue)
const const_t sfc_ingress_queue_idx_cnt = 65535;

// ---------------------------------------------------------------------------
// Common registers and variables for ping-pong tables
// ---------------------------------------------------------------------------

// Ghost thread: queue depth value
@stage(SFC_QUEUE_REG_STAGE_QD)
Register<bit<1>, sfc_ingress_queue_idx_t>(sfc_ingress_queue_idx_cnt) sfc_reg_qd_ping;
@stage(SFC_QUEUE_REG_STAGE_QD)
Register<bit<1>, sfc_ingress_queue_idx_t>(sfc_ingress_queue_idx_cnt) sfc_reg_qd_pong;


//-----------------------------------------------------------------------------
// Initialize the ghost_metadata by copying the values form the intrinsice meta
// data header (this seems to be required because of a bug as of 2020-11-03.
// Set the queue and buffer pool index for the incoming ghost packet.
//
// @param g_intr_md: the ghost intrinsic meta data
// @return g_md : The ghost meta data
//-----------------------------------------------------------------------------
control GhostSfcInit(in ghost_intrinsic_metadata_t g_intr_md,
                  out sfc_ghost_metadata_t g_md)
                  (const_t queue_idx_size) {

    Register<bit<32>, bit<2>>(32w1, 32w0) reg_over_threshold;

    RegisterAction<bit<32>, bit<2>, bool>(reg_over_threshold) check_over_threshold = {
        void apply(inout bit<32> qlength_threshold, out bool over_threshold){
            over_threshold = (bit<32>)g_intr_md.qlength > qlength_threshold;
        }
    };

    action do_check_threshold_set_q_idx(sfc_ingress_queue_idx_t ingress_port_queue_idx,
                                        sfc_queue_threshold_idx_t queue_threshold_idx) {
        g_md.ingress_port_queue_idx = ingress_port_queue_idx;
        g_md.queue_threshold_idx = queue_threshold_idx;
    }

    action set_qlength(sfc_ingress_queue_idx_t ingress_port_queue_idx,
                       bool qlength_over_threshold) {
        g_md.ingress_port_queue_idx = ingress_port_queue_idx;
        g_md.qlength_over_threshold = qlength_over_threshold;
    }

    table ghost_set_register_idx_tbl {
        key = {
            g_intr_md.pipe_id : exact@name("pipe");
            g_intr_md.qid : exact@name("qid");
        }
        actions = {
            set_qlength;
            do_check_threshold_set_q_idx;
            NoAction;
        }
        const default_action = NoAction;
    }

    action check_threshold() {
        g_md.qlength_over_threshold = check_over_threshold.execute(g_md.queue_threshold_idx);
    }

    apply {
        check_threshold();
        ghost_set_register_idx_tbl.apply();
    }
}

//-----------------------------------------------------------------------------
// Write the per-queue and per-buffer pool utilization to the shared ping-pong
// registers from the Ghost thread.
//
// @param g_md : The ghost meta data
//-----------------------------------------------------------------------------
control GhostWriteOverThreshold(in ghost_intrinsic_metadata_t g_intr_md,
                                in sfc_ghost_metadata_t g_md) {

    // Ghost thread: queue depth value
    // ping
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qd_ping) qd_write_ping_over = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qd_ping) qd_write_ping_under = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };

    // pong
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qd_pong) qd_write_pong_over = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qd_pong) qd_write_pong_under = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };

    apply {
        @stage(SFC_QUEUE_REG_STAGE_QD)
        {
            if (g_md.qlength_over_threshold) {
                if (g_intr_md.ping_pong == ghost_access_ping) {
                    qd_write_ping_over.execute(g_md.ingress_port_queue_idx);
                } else {
                    qd_write_pong_over.execute(g_md.ingress_port_queue_idx);
                }
            } else {
                if (g_intr_md.ping_pong == ghost_access_ping) {
                    qd_write_ping_under.execute(g_md.ingress_port_queue_idx);
                } else {
                    qd_write_pong_under.execute(g_md.ingress_port_queue_idx);
                }
            }
        }
    }
}




//-----------------------------------------------------------------------------
// Read the per-queue and per-buffer pool utilization to the shared ping-pong
// registers from the Ingress thread. While doing so, compare with the queue
// depth with the threshold provided in sfc and return the threshold-crossing.
//
// @param sfc : The sfc meta data
//----------------------------------------------------------------------------
control IngressReadOverThreshold(in switch_port_t egress_port,
                                 in switch_qid_t qid,
                                 in ghost_intrinsic_metadata_t g_intr_md,
                                 inout switch_sfc_ingress_metadata_t sfc) {


    // Ghost thread: queue depth value
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, bool>(sfc_reg_qd_ping) ping_qd_read = {
        void apply(inout bit<1> queue_over_threshold, out bool rv) {
            rv = (bool)queue_over_threshold;
        }
    };
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, bool>(sfc_reg_qd_pong) pong_qd_read = {
        void apply(inout bit<1> queue_over_threshold, out bool rv) {
            rv = (bool)queue_over_threshold;
        }
    };

    apply {
        @stage(SFC_QUEUE_REG_STAGE_QD)
        {
            if (g_intr_md.ping_pong == ingress_access_ping) {
                sfc.qlength_over_threshold = ping_qd_read.execute(egress_port ++ qid);
            } else {
                sfc.qlength_over_threshold = pong_qd_read.execute(egress_port ++ qid);
            }
        }
    }
}
# 157 "./switch_tofino2_y0.p4" 2

# 1 "../shared/sfc_trigger.p4" 1
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


control SfcStats(in SfcPacketType sfc_type) {

    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action unset(){ stats.count(); }
    action none(){ stats.count(); }
    action data(){ stats.count(); }
    action trigger(){ stats.count(); }
    action signal(){ stats.count(); }
    action enabled(){ stats.count(); }
    action hit(){ stats.count(); }

    table count_by_sfc_type {
        key = {
            sfc_type : ternary;
        }
        actions = {
            unset;
            none;
            data;
            trigger;
            signal;
            enabled;
        }
        counters = stats;
        const entries = {
            SfcPacketType.Unset : unset;
            SfcPacketType.None : none;
            SfcPacketType.Data : data;
            SfcPacketType.Trigger : trigger;
            SfcPacketType.Signal : signal;
            SfcPacketType.TcSignalEnabled : enabled;
        }
    }

    apply {
        count_by_sfc_type.apply();
    }
}


control IngressSfcInit(in ghost_intrinsic_metadata_t g_intr_md,
                       in switch_lookup_fields_t lkp,
                       in bit<32> timestamp_us,
                       out switch_sfc_ingress_metadata_t sfc) {

   /*
    *
    * Before these controls:
    *     IngressPortMapping
    */

    Register<sfc_pause_epoch_register_t, bit<1>>(32w1, {32w0, 32w0}) reg_filter_epoch;

    /**
     * Determine if the epoch is run out and if the filter banks should be switched.
     *
     * @param tstamp: the current timestamp
     * @param epoch_duration: the duration of a new epoch
     * @return rv_bank_switch_idx: Two values in the two lsbs:
                                    [1:1] = switch bank, yes(1) or no(0)
                                    [0:0] = bank idx to use, 0 or 1
     **/
    RegisterAction<sfc_pause_epoch_register_t, bit<1>, bit<2>>(reg_filter_epoch) get_bank_switch_idx = {
        void apply(inout sfc_pause_epoch_register_t value, out bit<2> rv_bank_switch_idx){
            if (((timestamp_us - value.current_epoch_start) > SFC_PAUSE_DURATION_US) // Set to appropriate value from control plane
                 || (timestamp_us < value.current_epoch_start)) {
                value.current_epoch_start = timestamp_us;
                // Invert value.bank_idx_changed[0:0]
                // Set value.bank_idx_changed[1:1] = 1
                value.bank_idx_changed = ~(value.bank_idx_changed & 32w1);
            } else {
                // Keep value.bank_idx_changed[0:0]
                // Set value.bank_idx_changed[1:1] = 0
                value.bank_idx_changed = value.bank_idx_changed & 32w1;
            }
            rv_bank_switch_idx = value.bank_idx_changed[1:0];
        }
    };

    action do_get_switch_bank_idx() {
        sfc.switch_bank_idx = get_bank_switch_idx.execute(1w0);
    }

    apply {
        do_get_switch_bank_idx();
  }
}


/*
 *
 * Dependencies:
 *   after:
 *     - nexthop
 *     - qos_map
 *     - traffic_class
 */
control IngressSfcPrepare(in ghost_intrinsic_metadata_t g_intr_md,
                          inout switch_ingress_metadata_t ig_md)
                          (const_t queue_idx_size) {


    IngressReadOverThreshold() ghost_read_q_over_threshold;


    Hash<bit<32>>(HashAlgorithm_t.CRC32) suppression_hash;

    // Important: traffic on RDMA control TCs has to be marked
    // as ig_md.sfc.type=SfcPacketType.TcSignalEnabled
    action do_set_sfc(SfcPacketType sfc_packet_type) {
        ig_md.sfc.type = sfc_packet_type;
    }

    action do_set_no_sfc() {
        ig_md.sfc.type = SfcPacketType.None;
    }

    table classify_sfc {
        key = {
            ig_md.qos.tc : exact@name("tc");
        }
        actions = {
            do_set_sfc;
            do_set_no_sfc;
        }
        const default_action = do_set_no_sfc;
    }

    action do_get_suppression_hash() {
        ig_md.sfc.suppression_hash = suppression_hash.get({ig_md.lkp.ip_src_addr,
                                                           ig_md.lkp.ip_dst_addr,
                                                           // Yes, the next line is dscp
                                                           ig_md.lkp.ip_tos[7:2]});
    }

    action do_set_queue_register_idx(sfc_queue_idx_t queue_register_idx,
                                     sfc_queue_threshold_idx_t queue_threshold_idx) {
        ig_md.sfc.queue_register_idx = queue_register_idx;
        ig_md.sfc.queue_threshold_idx = queue_threshold_idx;
    }

    table set_queue_register_idx {
        key = {
            ig_md.egress_port : exact@name("port");
            ig_md.qos.qid : exact@name("qid");
        }
        actions = {
            do_set_queue_register_idx;
            NoAction;
        }
        default_action = NoAction;
        size = queue_idx_size;
    }

    apply {

        do_get_suppression_hash();

        ghost_read_q_over_threshold.apply(ig_md.egress_port,
                                          ig_md.qos.qid,
                                          g_intr_md,
                                          ig_md.sfc);

        classify_sfc.apply();

        // Set the queue index for egress processing
        set_queue_register_idx.apply();

    }
}

/*
 *
 * Dependencies:
 *   after:
 *     - IngressThreadSfcPrepare
 *     - SystemAcl
 */
control IngressSfcTrigger(inout switch_ingress_metadata_t ig_md) {

    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_suppression;
    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_mirror;

    bit<1> fr0 = 0;
    bit<1> fr1 = 0;

    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank0_filter0;
    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank0_filter1;

    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank1_filter0;
    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank1_filter1;

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank0_filter0) bank0_filter0 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank0_filter1) bank0_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank1_filter0) bank1_filter0 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank1_filter1) bank1_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    action do_update_stats_suppression() {
        stats_suppression.count();
    }
    /* Putting both register accesses in the same action fails, the compiler complains:
      The action sfc_trigger_do_check_suppression_bank0 uses Register SwitchIngress.sfc_trigger.pause_filter_bank0_filter1 but does not use Register SwitchIngress.sfc_trigger.pause_filter_bank1_filter1.
      The action sfc_trigger_do_check_suppression_bank1 uses Register SwitchIngress.sfc_trigger.pause_filter_bank1_filter1 but does not use Register SwitchIngress.sfc_trigger.pause_filter_bank0_filter1.
        The Tofino architecture requires all indirect externs to be addressed with the same expression across all actions they are used in.
        You can also try to distribute individual indirect externs into separate tables.

      Therefore, the switch statement is used to the same effect, see below.
    */
    action do_check_suppression_bank0() {
        do_update_stats_suppression();
    }
    action do_check_suppression_bank1() {
        do_update_stats_suppression();
    }

    table decide_suppression {
        key = {
            ig_md.sfc.type : ternary@name("sfc_type");
            ig_md.mirror.type : ternary@name("mirror_type");
            ig_md.drop_reason : ternary@name("drop_reason");
            ig_md.sfc.qlength_over_threshold : ternary@name("qlength_over_threshold");
            ig_md.sfc.switch_bank_idx[0:0] : ternary@name("bank_idx");
        }
        actions = {
            do_update_stats_suppression;
            do_check_suppression_bank0;
            do_check_suppression_bank1;
        }
        default_action = do_update_stats_suppression;
        size = 16;
        counters = stats_suppression;
    }

    action do_update_stats_mirror() {
        stats_mirror.count();
    }

    // Trigger the switch.p4 mirror logic
    action do_set_mirroring(switch_mirror_session_t sid) {
        ig_md.mirror.session_id = sid;
        // These variables trigger the switch.p4 mirror logic
        ig_md.mirror.type = 6;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        // Statistics
        do_update_stats_mirror();
    }

    table decide_mirroring {
        key = {
            ig_md.egress_port[8:7] : ternary@name("pipe");
            ig_md.sfc.type : ternary@name("sfc_type");
            ig_md.mirror.type : ternary@name("mirror_type");
            ig_md.drop_reason : ternary@name("drop_reason");
            ig_md.sfc.qlength_over_threshold : ternary@name("qlength_over_threshold");
            fr0 : ternary;
            fr1 : ternary;
//            fr0 ++ fr1 : ternary@name("filter_result");
        }
        actions = {
            do_update_stats_mirror;
            do_set_mirroring;
        }
        default_action = do_update_stats_mirror;
        size = 16;
        counters = stats_mirror;
    }

    apply {

        /* Always clear the register banks independently of the packet
           type to avoid clock overflows from having an impact on the
           suppression. */

        // switch_bank_idx[1:1]: switch bank
        // switch_bank_idx[0:0]: bank idx to use
        if (ig_md.sfc.switch_bank_idx == 2w0b10) {
            // We switched filters, clear the old one
            pause_filter_bank1_filter0.clear(1w0,1w0);
            pause_filter_bank1_filter1.clear(1w0,1w0);
        } else if (ig_md.sfc.switch_bank_idx == 2w0b11) {
            // We switched filters, clear the old one
            pause_filter_bank0_filter0.clear(1w0,1w0);
            pause_filter_bank0_filter1.clear(1w0,1w0);
        }

        // Decide if suppression filter should be run
        switch (decide_suppression.apply().action_run) {
            do_check_suppression_bank0: {
                fr0 = bank0_filter0.execute(ig_md.sfc.suppression_hash[15:0]);
                fr1 = bank0_filter1.execute(ig_md.sfc.suppression_hash[31:16]);
            }
            do_check_suppression_bank1: {
                fr0 = bank1_filter0.execute(ig_md.sfc.suppression_hash[15:0]);
                fr1 = bank1_filter1.execute(ig_md.sfc.suppression_hash[31:16]);
            }
            default: { }
        }

        // Decide to send a trigger via mirror
        decide_mirroring.apply();

    }
}


control EgressSfcInit(in switch_qos_metadata_t qos,
                      in sfc_pause_h sfc_pause_hdr,
                      inout switch_sfc_egress_metadata_t sfc)
                      (const_t signaling_detect_table_size) {
   /*
    * After these controls:
    *     EgressPortMapping
    */

    action set_type_signaling() {
        sfc.type = SfcPacketType.Signal;
        sfc.pause_tc = sfc_pause_hdr.pause_tc;
        sfc.egress_port_speed = sfc.egress_port_speed;
        sfc.pause_duration_us = sfc_pause_hdr.pause_duration;
    }

    action clear_sfc() {
        sfc.type = SfcPacketType.None;
    }

    table detect_signaling {
        key = {
            sfc_pause_hdr.isValid(): exact @name("sfc_pause_hdr");
            qos.tc: ternary @name("tc");
            sfc.type: ternary @name("sfc_packet_type");
        }
        actions = {
            set_type_signaling;
            clear_sfc;
        }
        size = signaling_detect_table_size;
    }

    apply {

        detect_signaling.apply();

    }
}


/*
 *
 * Dependencies:
 *   after:
 *     - EgressPortMapping
 */
control EgressSfc(in egress_intrinsic_metadata_t eg_intr_md,
                  in switch_qos_metadata_t qos,
                  inout switch_header_t hdr,
                  inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                  inout switch_sfc_egress_metadata_t sfc)
                 (const_t queue_idx_size,
                  const_t pause_duration_table_size) {

    // Egress thread: queue depth value
    Register<bit<32>, sfc_queue_idx_t>(queue_idx_size) sfc_reg_qd_egress;

    // SfcPacketType.Data packet: write queue depth
    RegisterAction<bit<32>, sfc_queue_idx_t, int<32>>(sfc_reg_qd_egress) qd_write = {
        void apply(inout bit<32> value) {
            value = (bit<32>)qos.qdepth;
        }
    };
    action data_qd_write() {
        qd_write.execute(sfc.queue_register_idx);
    }

    // SfcPacketType.Trigger: read queue depth
    RegisterAction<bit<32>, sfc_queue_idx_t, bit<32>>(sfc_reg_qd_egress) qd_read = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = value - (bit<32>)sfc.queue_threshold_idx;
        }
    };
    action trigger_qd_read() {
        sfc.q_drain_lengths = (buffer_memory_t)qd_read.execute(sfc.queue_register_idx);
    }

    action do_set_pause_duration(sfc_pause_duration_us_t pause_duration) {
        sfc.pause_duration_us = pause_duration;
    }

    table tbl_set_pause_duration {
        key = {
            qos.port_speed : exact @name("port_speed");
            sfc.q_drain_lengths : exact @name("q_drain_lengths");
        }
        actions = {
            do_set_pause_duration;
            NoAction;
        }
        size = pause_duration_table_size;
    }

    //time_conversion_factor = 1000/(512*linkspeed)
    //if link speed is 100Gbps, time_conversion_factor = 195, time_conversion_factor_in_binary = 8
    //if link speed is 25Gbps, time_conversion_factor = 48, time_conversion_factor_in_binary =6
    action hundredG_conversion(){
        sfc.pause_duration_us = sfc.pause_duration_us << 8;
    }
    action twentyG_conversion(){
        sfc.pause_duration_us = sfc.pause_duration_us << 6;
    }
// Todo, this is hardcode
    action testing_conversion(){
        sfc.pause_tc = 0x1;
        sfc.pause_duration_us = 0xdac;
    }

    table tbl_time_conversion_lookup{
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            NoAction;
            twentyG_conversion;
            hundredG_conversion;
            testing_conversion;
        }
        const default_action = testing_conversion; //NoAction;
        size = 64;
    }

    action convert_to_pfc_pause(){
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.sfc_pause.setInvalid();
        //PFC pkts (802.1Qbb 66B) -- dstmac(6B),srcmac(6B),TYPE(2B8808),Opcode(2B0101),CEV(2B),Time0-7(8*2B),Pad(28B),CRC(4B)            
        hdr.ethernet.src_addr = 0x000000000000;//ori_dst_mac;
        hdr.ethernet.ether_type = 0x8808;

        hdr.pfc.setValid();
        //0x0008;//for priority 3; //0x0001;//for priority 0
        //1250 unit  each unit is 512bit time
        // TODO: need know the value format of pause_tc, it is better to have 8 bit value
        hdr.pfc = {
            16w0x0101,
            8w0,
            sfc.pause_tc,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us,
            sfc.pause_duration_us
            ,208w0
        };
    }

    action gen_sfc_star_pause(){
        bit<48> ori_src_mac;
        bit<48> ori_dst_mac;
        ori_src_mac = hdr.ethernet.src_addr;
        ori_dst_mac = hdr.ethernet.dst_addr;
        hdr.ethernet.src_addr = ori_dst_mac;
        hdr.ethernet.dst_addr = ori_src_mac;

        //L3
        bit<32> orig_src_ip;
        bit<32> orig_dst_ip;
        orig_src_ip = hdr.ipv4.src_addr;
        orig_dst_ip = hdr.ipv4.dst_addr;
        hdr.ipv4.src_addr = orig_dst_ip;
        hdr.ipv4.dst_addr = orig_src_ip;

        hdr.ipv4.total_len = 46;
        hdr.ipv4.hdr_checksum = 0;
        //udp
        hdr.udp.length = 26;
        hdr.udp.dst_port = 1674;
        hdr.udp.checksum = 0;
        //sfc star packet format
        hdr.sfc_pause.setValid();
        hdr.sfc_pause = {
                8w0,
                sfc.pause_tc,
                sfc.pause_duration_us
                ,112w0
                };
        eg_intr_md_for_dprsr.mtu_trunc_len = 64;
    }

    apply {

        if (sfc.type == SfcPacketType.Data) {
            data_qd_write();
        } else if (sfc.type == SfcPacketType.Trigger) {
            trigger_qd_read();
            tbl_set_pause_duration.apply();
            gen_sfc_star_pause();
        } else if (sfc.type == SfcPacketType.Signal) {
            tbl_time_conversion_lookup.apply();
            convert_to_pfc_pause();
        }

    }
}
# 159 "./switch_tofino2_y0.p4" 2

# 1 "../shared/ipv4_csum.p4" 1
/*
* This control implements an incremental IPv4 header checksum update when the
* TTL and DIFFSERV fields are updated.  The new values for TTL and DIFFSERV are
* inputs to this control and the header has the original values of the fields.
* This requires 10 stages and two 32 bit containers.
* Note that the double carry handling can be replaced with a single stage TCAM
* table lookup to reduce the number of stages required.  See the
* IPv4_Checksum_Compute control for an example. */
control IPv4_Checksum_Update_DIFFSERV_TTL(inout switch_header_t hdr,
in bit<8> new_diffserv,
in bit<8> new_ttl) {






    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) identity_hash16;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_a;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_b;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_c;
    bit<32> cksm;
    bit<32> o_fields;
    bit<32> n_fields;
    bit<32> carry;

    /* Step 1: Prepare two temporary 32 bit variables for removing the original
    *         TOS byte and TTL from the checksum. */
    action step_1a() {
        cksm = identity_hash32_a.get({16w0 ++ hdr.ipv4.hdr_checksum});
    }
    action step_1b() {
        cksm = cksm ^ 0xFFFF;
    }
    action step_1c() {
        o_fields = identity_hash32_b.get({16w0 ++ hdr.ipv4.ttl ++ hdr.ipv4.diffserv});
    }
    /* Step 2: Remove the original TOS byte and TTL from the checksum and prepare
    *         a temporary variable to add the new values of these fields to the
    *         checksum. */
    action step_2() {
        cksm = cksm - o_fields;
        n_fields = identity_hash32_c.get({16w0 ++ new_ttl ++ new_diffserv});
    }
    /* Step 3: Add the new fields into the checksum. */
    action step_3() {
        cksm = cksm + n_fields;
    }
    /* Step 4: Move the upper 16 bits into a temporary so they can be added back
    *         into the checksum. */
    action step_4() {
        carry = cksm >> 16;
        cksm = cksm & 0xFFFF;
    }
    /* Step 5: Add the carry back into the checksum. */
    action step_5() {
        cksm = cksm + carry;
    }
    /* Step 6 and 7: Repeat steps 4 and 5 since step 5 may have generated another
    *               carry. */
    action step_6() {
        carry = cksm >> 16;
        cksm = cksm & 0xFFFF;
    }
    action step_7() {
        cksm = cksm + carry;
    }
    /* Step 8: Invert the checksum before writing it back to the IPv4 header. */
    action step_8() {
        cksm = ~cksm;
    }
    /* Step 9: Write the new header back into the packet. */
    action step_9() {
        hdr.ipv4.hdr_checksum = identity_hash16.get({cksm[15:0]});
        hdr.ipv4.diffserv = new_diffserv;
        hdr.ipv4.ttl = new_ttl;
    }

    apply {
        step_1a();
        step_1b();
        step_1c();
        step_2();
        step_3();
        step_4();
        step_5();
        step_6();
        step_7();
        step_8();
        step_9();
    }

}

/*
* This control implements a full recalculation of the IPv4 header checksum.
* The IPv4 header should contain final values for all fields (except the
* checksum) before calling this control.
* This requires 8 stages, a TCAM table, 9 32 bit containers. */
control IPv4_Checksum_Compute(inout switch_header_t hdr) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) identity_hash16;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_a;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_b;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_c;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_d;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_e;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_f;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_g;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_h;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_i;
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
    bit<32> e;
    bit<32> f;
    bit<32> g;
    bit<32> h;
    bit<32> i;

    /* Step 1: Move fields from IPv4 header into 32 bit variables. */
    action step_1a() {
        a = identity_hash32_a.get({16w0 ++ hdr.ipv4.version ++ hdr.ipv4.ihl ++ hdr.ipv4.diffserv});
    }
    action step_1b() {
        b = identity_hash32_b.get({16w0 ++ hdr.ipv4.total_len});
    }
    action step_1c() {
        c = identity_hash32_c.get({16w0 ++ hdr.ipv4.identification});
    }
    action step_1d() {
        d = identity_hash32_d.get({16w0 ++ hdr.ipv4.flags ++ hdr.ipv4.frag_offset});
    }
    action step_1e() {
        e = identity_hash32_e.get({16w0 ++ hdr.ipv4.ttl ++ hdr.ipv4.protocol});
    }
    action step_1f() {
        f = identity_hash32_f.get({16w0 ++ hdr.ipv4.src_addr[31:16]});
    }
    action step_1g() {
        g = identity_hash32_g.get({16w0 ++ hdr.ipv4.src_addr[15: 0]});
    }
    action step_1h() {
        h = identity_hash32_h.get({16w0 ++ hdr.ipv4.dst_addr[31:16]});
    }
    action step_1i() {
        i = identity_hash32_i.get({16w0 ++ hdr.ipv4.dst_addr[15: 0]});
    }
    /* Step 2: Add the fields together to a single 32 bit value. */
    action step_2a() {
        a = a + b;
        c = c + d;
        e = e + f;
        g = g + h;
    }
    action step_2b() {
        a = a + c;
        e = e + g;
    }
    action step_2c() {
        a = a + e;
    }
    action step_2d() {
        a = a + i;
    }
    /* Step 3: Use a ternary table to handle the carry over in a single stage
    *         rather than two stages. */
    action update_carry(bit<32> carry_val) {
        a = a + carry_val;
    }
    table step_3 {
        key = { a[19:0] : ternary; }
        actions = { update_carry; }
        const default_action = update_carry(0);
        const entries = {
# 1 "../shared/carry_entries.p4" 1
0x1FFFE &&& 0xFFFFF : update_carry(1);
0x1FFFF &&& 0xFFFFF : update_carry(2);
0x10000 &&& 0xF0000 : update_carry(1);

0x2FFFC &&& 0xFFFFF : update_carry(2);
0x2FFFD &&& 0xFFFFF : update_carry(2);
0x2FFFE &&& 0xFFFFF : update_carry(3);
0x2FFFF &&& 0xFFFFF : update_carry(3);
0x20000 &&& 0xF0000 : update_carry(2);

0x3FFFC &&& 0xFFFFF : update_carry(3);
0x3FFFD &&& 0xFFFFF : update_carry(4);
0x3FFFE &&& 0xFFFFF : update_carry(4);
0x3FFFF &&& 0xFFFFF : update_carry(4);
0x30000 &&& 0xF0000 : update_carry(3);

0x4FFF8 &&& 0xFFFFF : update_carry(4);
0x4FFF9 &&& 0xFFFFF : update_carry(4);
0x4FFFA &&& 0xFFFFF : update_carry(4);
0x4FFFB &&& 0xFFFFF : update_carry(4);
0x4FFFC &&& 0xFFFFF : update_carry(5);
0x4FFFD &&& 0xFFFFF : update_carry(5);
0x4FFFE &&& 0xFFFFF : update_carry(5);
0x4FFFF &&& 0xFFFFF : update_carry(5);
0x40000 &&& 0xF0000 : update_carry(4);

0x5FFF8 &&& 0xFFFFF : update_carry(5);
0x5FFF9 &&& 0xFFFFF : update_carry(5);
0x5FFFA &&& 0xFFFFF : update_carry(5);
0x5FFFB &&& 0xFFFFF : update_carry(6);
0x5FFFC &&& 0xFFFFF : update_carry(6);
0x5FFFD &&& 0xFFFFF : update_carry(6);
0x5FFFE &&& 0xFFFFF : update_carry(6);
0x5FFFF &&& 0xFFFFF : update_carry(6);
0x50000 &&& 0xF0000 : update_carry(5);

0x6FFF8 &&& 0xFFFFF : update_carry(6);
0x6FFF9 &&& 0xFFFFF : update_carry(6);
0x6FFFA &&& 0xFFFFF : update_carry(7);
0x6FFFB &&& 0xFFFFF : update_carry(7);
0x6FFFC &&& 0xFFFFF : update_carry(7);
0x6FFFD &&& 0xFFFFF : update_carry(7);
0x6FFFE &&& 0xFFFFF : update_carry(7);
0x6FFFF &&& 0xFFFFF : update_carry(7);
0x60000 &&& 0xF0000 : update_carry(6);

0x7FFF8 &&& 0xFFFFF : update_carry(7);
0x7FFF9 &&& 0xFFFFF : update_carry(8);
0x7FFFA &&& 0xFFFFF : update_carry(8);
0x7FFFB &&& 0xFFFFF : update_carry(8);
0x7FFFC &&& 0xFFFFF : update_carry(8);
0x7FFFD &&& 0xFFFFF : update_carry(8);
0x7FFFE &&& 0xFFFFF : update_carry(8);
0x7FFFF &&& 0xFFFFF : update_carry(8);
0x70000 &&& 0xF0000 : update_carry(7);

0x8FFF0 &&& 0xFFFFF : update_carry(8);
0x8FFF1 &&& 0xFFFFF : update_carry(8);
0x8FFF2 &&& 0xFFFFF : update_carry(8);
0x8FFF3 &&& 0xFFFFF : update_carry(8);
0x8FFF4 &&& 0xFFFFF : update_carry(8);
0x8FFF5 &&& 0xFFFFF : update_carry(8);
0x8FFF6 &&& 0xFFFFF : update_carry(8);
0x8FFF7 &&& 0xFFFFF : update_carry(8);
0x8FFF8 &&& 0xFFFFF : update_carry(9);
0x8FFF9 &&& 0xFFFFF : update_carry(9);
0x8FFFA &&& 0xFFFFF : update_carry(9);
0x8FFFB &&& 0xFFFFF : update_carry(9);
0x8FFFC &&& 0xFFFFF : update_carry(9);
0x8FFFD &&& 0xFFFFF : update_carry(9);
0x8FFFE &&& 0xFFFFF : update_carry(9);
0x8FFFF &&& 0xFFFFF : update_carry(9);
0x80000 &&& 0xF0000 : update_carry(8);

0x9FFF0 &&& 0xFFFFF : update_carry(9);
0x9FFF1 &&& 0xFFFFF : update_carry(9);
0x9FFF2 &&& 0xFFFFF : update_carry(9);
0x9FFF3 &&& 0xFFFFF : update_carry(9);
0x9FFF4 &&& 0xFFFFF : update_carry(9);
0x9FFF5 &&& 0xFFFFF : update_carry(9);
0x9FFF6 &&& 0xFFFFF : update_carry(9);
0x9FFF7 &&& 0xFFFFF : update_carry(10);
0x9FFF8 &&& 0xFFFFF : update_carry(10);
0x9FFF9 &&& 0xFFFFF : update_carry(10);
0x9FFFA &&& 0xFFFFF : update_carry(10);
0x9FFFB &&& 0xFFFFF : update_carry(10);
0x9FFFC &&& 0xFFFFF : update_carry(10);
0x9FFFD &&& 0xFFFFF : update_carry(10);
0x9FFFE &&& 0xFFFFF : update_carry(10);
0x9FFFF &&& 0xFFFFF : update_carry(10);
0x90000 &&& 0xF0000 : update_carry(9);
# 178 "../shared/ipv4_csum.p4" 2
        }
    }
    /* Step 4: Invert the checksum before writing it back to the IPv4 header. */
    action a_step_4() {
        a = ~a;
    }
    table step_4 {
        actions = { a_step_4; }
        default_action = a_step_4();
    }
    /* Step 5: Update the IPv4 header. */
    action a_step_5() {
        hdr.ipv4.hdr_checksum = identity_hash16.get({a[15:0]});
    }
    table step_5 {
        actions = { a_step_5; }
        default_action = a_step_5();
    }


    apply {
        step_1a();
        step_1b();
        step_1c();
        step_1d();
        step_1e();
        step_1f();
        step_1g();
        step_1h();
        step_1i();
        step_2a();
        step_2b();
        step_2c();
        step_2d();
        step_3.apply();
        step_4.apply();
        if (hdr.ipv4.isValid()) {
            step_5.apply();
        }
    }

}
# 161 "./switch_tofino2_y0.p4" 2

// XXX(yumin): currently Brig may pack fields with SALU ops with
// other fields which were set by action data. Until Brig fixes
// it, it is safer to mark SALU related fields as solitary.
@pa_solitary("egress", "eg_md.dtel.queue_report_flag")

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        in ghost_intrinsic_metadata_t g_intr_md
        ) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    NonIpHash() non_ip_hash;
    Lagv4Hash() lagv4_hash;
    Lagv6Hash() lagv6_hash;
    LOU() lou;
    Fib(IPV4_HOST_TABLE_SIZE,
        IPV4_LPM_TABLE_SIZE,
        true,
        IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    Fibv6(IPV6_HOST_TABLE_SIZE, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    IngressIpv4Acl(INGRESS_IPV4_ACL_TABLE_SIZE) ingress_ipv4_acl;
    IngressIpv6Acl(INGRESS_IPV6_ACL_TABLE_SIZE) ingress_ipv6_acl;
    IngressIpAcl(INGRESS_IP_MIRROR_ACL_TABLE_SIZE) ingress_ip_mirror_acl;
    IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
    ECNAcl() ecn_acl;
    PFCWd(512) pfc_wd;
    IngressQoSMap() qos_map;
    IngressTC() traffic_class;
    PPGStats() ppg_stats;
//    StormControl() storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    IngressDtel() dtel;

    IngressSfcInit() sfc_init;
    IngressSfcPrepare(SFC_QUEUE_IDX_SIZE) sfc_prepare;
    IngressSfcTrigger() sfc_trigger;
    SfcStats() sfc_stats;

    action rmac_hit() { ig_md.flags.rmac_hit = true; } action rmac_miss() { ig_md.flags.rmac_hit = false; } table rmac { key = { ig_md.rmac_group : exact; ig_md.lkp.mac_dst_addr : exact; } actions = { rmac_hit; @defaultonly rmac_miss; } const default_action = rmac_miss; size = 1024; } // <- This is a preprocessor variable, that's readability!

    apply {
        pkt_validation.apply(
            hdr, ig_md.flags, ig_md.lkp, ig_intr_md_for_tm, ig_md.drop_reason);

        sfc_init.apply(g_intr_md, ig_md.lkp, ig_md.timestamp[41:10], ig_md.sfc);

        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        lou.apply(ig_md);
        smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
        bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
        if (rmac.apply().hit) {
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {
                ipv6_fib.apply(ig_md);
            } else if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.unicast_enable) {
                ipv4_fib.apply(ig_md);
            }
        } else {
            dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
        }
        if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
            ingress_ipv4_acl.apply(ig_md, ig_md.unused_nexthop);
        }
        if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
            ingress_ipv6_acl.apply(ig_md, ig_md.unused_nexthop);
        }
        ingress_ip_mirror_acl.apply(ig_md, ig_md.unused_nexthop);

        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            non_ip_hash.apply(ig_md, ig_md.lag_hash);
        } else if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            lagv4_hash.apply(ig_md.lkp, ig_md.lag_hash);
        } else {
            lagv6_hash.apply(ig_md.lkp, ig_md.lag_hash);
        }

        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_hash.apply(ig_md.lkp, ig_md.hash[31:0]);
        } else {
            ipv6_hash.apply(ig_md.lkp, ig_md.hash[31:0]);
        }

        nexthop.apply(ig_md);
        qos_map.apply(hdr, ig_md);
        traffic_class.apply(ig_md);

//        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);

        if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
            flood.apply(ig_md);
        } else {
            lag.apply(ig_md, ig_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
        }

        // How does SFC mirroring interact with other mirroring?
        // I.e. could there be interference?
        // ecn_acl and pfc_wd should not interfere

        sfc_prepare.apply(g_intr_md, ig_md);

        ecn_acl.apply(ig_md, ig_md.lkp, ig_intr_md_for_tm.packet_color);
        pfc_wd.apply(ig_md.port, ig_md.qos.qid, ig_md.flags.pfc_wd_drop);

        system_acl.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        ppg_stats.apply(ig_md);
        ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
        dtel.apply(
            hdr, ig_md.lkp, ig_md, ig_md.lag_hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }



        sfc_trigger.apply(ig_md);

        sfc_stats.apply(ig_md.sfc.type);

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
    }
}

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
    EgressIpv4Acl(EGRESS_IPV4_ACL_TABLE_SIZE) egress_ipv4_acl;
    EgressIpv6Acl(EGRESS_IPV6_ACL_TABLE_SIZE) egress_ipv6_acl;
    EgressQoS() qos;
    EgressQueue() queue;
    EgressSystemAcl() system_acl;
    PFCWd(512) pfc_wd;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    MTU() mtu;
    WRED() wred;

    EgressSfcInit(SIGNALING_DETECT_TABLE_SIZE) sfc_init;
    EgressSfc(SFC_QUEUE_IDX_SIZE, SFC_PAUSE_DURATION_SIZE) sfc;
    SfcStats() sfc_stats_start;
    SfcStats() sfc_stats_end;

    EgressDtel() dtel;
    DtelConfig() dtel_config;
    IPv4_Checksum_Compute() ipv4_csum_compute;
    EgressCpuRewrite() cpu_rewrite;

    apply {

        sfc_stats_start.apply(eg_md.sfc.type);

        eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

        sfc_init.apply(eg_md.qos, hdr.sfc_pause, eg_md.sfc);

        mirror_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        if (eg_md.flags.bypass_egress == false) {
            vlan_decap.apply(hdr, eg_md);
            qos.apply(hdr, eg_intr_md.egress_port, eg_md);
            wred.apply(hdr, eg_md, eg_intr_md, eg_md.flags.wred_drop);

            if(eg_md.sfc.type == SfcPacketType.Trigger)
                eg_md.flags.routed = true;

            rewrite.apply(hdr, eg_md);

            sfc.apply(eg_intr_md, eg_md.qos, hdr, eg_intr_md_for_dprsr, eg_md.sfc);

            ipv4_csum_compute.apply(hdr);
            if (hdr.ipv4.isValid()) {
                egress_ipv4_acl.apply(hdr, eg_md);
            } else if (hdr.ipv6.isValid()) {
                egress_ipv6_acl.apply(hdr, eg_md);
            }
            mtu.apply(hdr, eg_md, eg_md.checks.mtu);
            vlan_xlate.apply(hdr, eg_md);
            pfc_wd.apply(eg_intr_md.egress_port, eg_md.qos.qid, eg_md.flags.pfc_wd_drop);

            dtel.apply(hdr, eg_md, eg_intr_md, eg_md.dtel.hash);
            system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
            dtel_config.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        }
        cpu_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        queue.apply(eg_intr_md.egress_port, eg_md);

        sfc_stats_end.apply(eg_md.sfc.type);

    }
}



control SwitchGhost(in ghost_intrinsic_metadata_t g_intr_md) {
    sfc_ghost_metadata_t g_md;

    GhostSfcInit(SFC_QUEUE_IDX_SIZE) sfc_init;
    GhostWriteOverThreshold() write_queue_buffer_util;

    apply {
        sfc_init.apply(g_intr_md, g_md);
        write_queue_buffer_util.apply(g_intr_md, g_md);
    }
}



Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()


        ,SwitchGhost()


        ) pipe;

Switch(pipe) main;
