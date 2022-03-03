# 1 "simple_l3_acl.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "simple_l3_acl.p4"
/* -*- P4_16 -*- */

# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/core.p4" 1
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

@command_line("--disable-parse-max-depth-limit")

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
# 4 "simple_l3_acl.p4" 2
# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tna.p4" 1
/**
 * Copyright 2013-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tofino1arch.p4" 1
/**
 * Copyright 2013-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */




# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/core.p4" 1
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
# 17 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tofino1arch.p4" 2
# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tofino.p4" 1
/**
 * Copyright 2013-2021 Intel Corporation.
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
 - Initial release
 1.0.2:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH

*/

# 1 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/core.p4" 1
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
# 27 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tofino.p4" 2

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<5> QueueId_t; // Queue id
typedef bit<3> MirrorType_t; // Mirror type
typedef bit<10> MirrorId_t; // Mirror id
typedef bit<3> ResubmitType_t; // Resubmit type
typedef bit<3> DigestType_t; // Digest type
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w64;

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_MATCH = 16w0x0001;
const bit<16> PARSER_ERROR_PARTIAL_HDR = 16w0x0002;
const bit<16> PARSER_ERROR_CTR_RANGE = 16w0x0004;
const bit<16> PARSER_ERROR_TIMEOUT_USER = 16w0x0008;
const bit<16> PARSER_ERROR_TIMEOUT_HW = 16w0x0010;
const bit<16> PARSER_ERROR_SRC_EXT = 16w0x0020;
const bit<16> PARSER_ERROR_DST_CONT = 16w0x0040;
const bit<16> PARSER_ERROR_PHV_OWNER = 16w0x0080;
const bit<16> PARSER_ERROR_MULTIWRITE = 16w0x0100;
const bit<16> PARSER_ERROR_ARAM_MBE = 16w0x0400;
const bit<16> PARSER_ERROR_FCS = 16w0x0800;

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

    @padding bit<14> _pad3;
    bit<18> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    @padding bit<5> _pad4;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    @padding bit<6> _pad5;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    @padding bit<14> _pad6;
    bit<18> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    bit<16> egress_rid; // L3 replication id for multicast
                                        // packets.

    @padding bit<7> _pad7;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    @padding bit<3> _pad8;

    QueueId_t egress_qid; // Egress (physical) queue id via which
                                        // this packet was served.

    @padding bit<5> _pad9;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    @padding bit<7> _pad10;

    bit<1> deflection_flag; // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length; // Packet length, in bytes
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
// Packet generator supports up to 8 applications and a total of 16KB packet
// payload. Each application is associated with one of the four trigger types:
// - One-time timer
// - Periodic timer
// - Port down
// - Packet recirculation
// For recirculated packets, the event fires when the first 32 bits of the
// recirculated packet matches the application match value and mask.
// A triggered event may generate programmable number of batches with
// programmable number of packets per batch.
header pktgen_timer_header_t {
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @padding bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @padding bit<15> _pad2;
    PortId_t port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    bit<24> key; // Key from the recirculated packet

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

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

    /// Subtract all header fields after the current state and
    /// return the calculated checksum value.
    /// Marks the end position for residual checksum header.
    /// All header fields extracted after will be automatically subtracted.
    /// @param residual: The calculated checksum value for added fields.
    void subtract_all_and_deposit<T>(out T residual);

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
// Tofino parser counter can be used to extract header stacks or headers with
// variable length. Tofino has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.

extern ParserCounter {
    /// Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    void set<T>(in T value);

    /// Load the counter with a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Right rotate (circular) the source field by this number of bits.
    /// @param mask : Mask the rotated source field by 2 ^ (mask + 1) - 1.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set<T>(in T field,
                in bit<8> max,
                in bit<8> rotate,
                in bit<3> mask,
                in bit<8> add);

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
    /// param prio : parser priority for the parsed packet.
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
    /// @type_param W : width of the calculated hash.
    Random();

    /// Return a random number with uniform distribution.
    /// @return : random number between 0 and 2**W - 1
    W get();
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
    Counter(bit<32> size, CounterType_t type);

    /// Increment the counter value.
    /// @param index : index of the counter to be incremented.
    /// @param adjust_byte_count : optional parameter indicating value to be
    //                             subtracted from counter value.
    void count(in I index, @optional in bit<32> adjust_byte_count);
}

/// DirectCounter
extern DirectCounter<W> {
    DirectCounter(CounterType_t type);
    void count(@optional in bit<32> adjust_byte_count);
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
    bit<8> execute(in I index, in MeterColor_t color, @optional in bit<32> adjust_byte_count);
    bit<8> execute(in I index, @optional in bit<32> adjust_byte_count);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
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

// This is implemented using an experimental feature in p4c and subject to
// change. See https://github.com/p4lang/p4-spec/issues/561
extern RegisterAction<T, I, U> {
    RegisterAction(Register<_, _> reg);

    U execute(in I index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */
    // Apply the implemented abstract method using an index that increments each
    // time. This method is useful for stateful logging.
    U execute_log();

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    @synchronous(execute, execute_log)
    abstract void apply(inout T value, @optional out U rv);

    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);

    U execute(); /* {
        U rv;
        T value = reg.read();
        apply(value, rv);
        reg.write(value);
        return rv;
    } */

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    @synchronous(execute)
    abstract void apply(inout T value, @optional out U rv);

    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
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

// Tofino supports mirroring both at the ingress and egress. Ingress deparser
// creates a copy of the original ingress packet and prepends the mirror header.
// Egress deparser first constructs the output packet and then prepends the
// mirror header.
extern Mirror {
    /// Constructor
    @deprecated("Mirror must be specified with the value of the mirror_type instrinsic metadata")
    Mirror();

    /// Constructor
    Mirror(MirrorType_t mirror_type);

    /// Mirror the packet.
    void emit(in MirrorId_t session_id);

    /// Write @hdr into the ingress/egress mirror buffer.
    /// @param hdr : T can be a header type.
    void emit<T>(in MirrorId_t session_id, in T hdr);
}

// Tofino supports packet resubmission at the end of ingress pipeline. When
// a packet is resubmitted, the original packet reference and some limited
// amount of metadata (64 bits) are passed back to the packet’s original
// ingress buffer, where the packet is enqueued again.
extern Resubmit {
    /// Constructor
    @deprecated("Resubmit must be specified with the value of the resubmit_type instrinsic metadata")
    Resubmit();

    /// Constructor
    Resubmit(ResubmitType_t resubmit_type);

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type.
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
# 18 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tofino1arch.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino.

parser IngressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    @optional out ingress_intrinsic_metadata_t ig_intr_md,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr);

parser EgressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    @optional out egress_intrinsic_metadata_t eg_intr_md,
    @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

control IngressT<H, M>(
    inout H hdr,
    inout M ig_md,
    @optional in ingress_intrinsic_metadata_t ig_intr_md,
    @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    @optional inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control EgressT<H, M>(
    inout H hdr,
    inout M eg_md,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    @optional in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional in ingress_intrinsic_metadata_t ig_intr_md);

control EgressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    @optional in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParserT<IH, IM> ingress_parser,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParserT<EH, EM> egress_parser,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser);

@pkginfo(arch="TNA", version="1.0.2")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);

package IngressParsers<H, M>(
    IngressParserT<H, M> prsr0,
    @optional IngressParserT<H, M> prsr1,
    @optional IngressParserT<H, M> prsr2,
    @optional IngressParserT<H, M> prsr3,
    @optional IngressParserT<H, M> prsr4,
    @optional IngressParserT<H, M> prsr5,
    @optional IngressParserT<H, M> prsr6,
    @optional IngressParserT<H, M> prsr7,
    @optional IngressParserT<H, M> prsr8,
    @optional IngressParserT<H, M> prsr9,
    @optional IngressParserT<H, M> prsr10,
    @optional IngressParserT<H, M> prsr11,
    @optional IngressParserT<H, M> prsr12,
    @optional IngressParserT<H, M> prsr13,
    @optional IngressParserT<H, M> prsr14,
    @optional IngressParserT<H, M> prsr15,
    @optional IngressParserT<H, M> prsr16,
    @optional IngressParserT<H, M> prsr17);

package EgressParsers<H, M>(
    EgressParserT<H, M> prsr0,
    @optional EgressParserT<H, M> prsr1,
    @optional EgressParserT<H, M> prsr2,
    @optional EgressParserT<H, M> prsr3,
    @optional EgressParserT<H, M> prsr4,
    @optional EgressParserT<H, M> prsr5,
    @optional EgressParserT<H, M> prsr6,
    @optional EgressParserT<H, M> prsr7,
    @optional EgressParserT<H, M> prsr8,
    @optional EgressParserT<H, M> prsr9,
    @optional EgressParserT<H, M> prsr10,
    @optional EgressParserT<H, M> prsr11,
    @optional EgressParserT<H, M> prsr12,
    @optional EgressParserT<H, M> prsr13,
    @optional EgressParserT<H, M> prsr14,
    @optional EgressParserT<H, M> prsr15,
    @optional EgressParserT<H, M> prsr16,
    @optional EgressParserT<H, M> prsr17);

package MultiParserPipeline<IH, IM, EH, EM>(
    IngressParsers<IH, IM> ig_prsr,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParsers<EH, EM> eg_prsr,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser);

package MultiParserSwitch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
                          IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    MultiParserPipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional MultiParserPipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional MultiParserPipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional MultiParserPipeline<IH3, IM3, EH3, EM3> pipe3);
# 15 "/home/vgurevich/bf-sde-9.5.0/install/share/p4c/p4include/tna.p4" 2
# 5 "simple_l3_acl.p4" 2

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

enum bit<8> ip_proto_t {
    HOPOPT = 0,
    ICMP = 1,
    IGMP = 2,
    TCP = 6,
    UDP = 17,
    IPV6_ROUTE = 43,
    IPV6_FRAGMENT = 44,
    IPSEC_ESP = 50,
    IPSEC_AH = 51,
    IPV6_OPTS = 60,
    MOBILITY = 135,
    SHIM6 = 140,
    RESERVED_FD = 253,
    RESERVED_FE = 254
}

struct l4_lookup_t {
    bit<16> word_1;
    bit<16> word_2;
}

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*
 *  Define all the headers the program will recognize             
 *  The actual sets of headers processed by each gress can potentially differ 
 * 
 * In this particular case, the actual set of the processed headers will
 * be defined in the parser module as packet_headers_t
*/

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    ether_type_t ether_type;
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
    ip_proto_t protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv4_option_word_h {
    bit<32> data;
}

header ipv4_options_h {
    varbit<320> data;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    ip_proto_t next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv6_ext_hdr_h {
    ip_proto_t next_hdr;
    bit<8> ext_len;
    bit<48> data;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv6_ext_block_h {
    bit<64> data;
}

header ipv6_ext_h {
    varbit<640> data;
}

/*
 * Layer 4 Headers 
 */
header icmp_h {
    bit<16> type_code;
    bit<16> checksum;
}

header igmp_h {
    bit<16> type_code;
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

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

/*************************************************************************
 *********** C O M M O N    P A C K E T   P R O C E S S I N G ************
 *************************************************************************/

/* 
 * The implementation is supposed to provide a parser (PacketParser) and 
 * a deparser (PacketDeparser) that parse and deparse packet_headers_t and
 * also return parser_metadata_t. All are defined in the module.
 *
 * Here we provide two implementations: both parse IPv4, Layer 4 Headers and
 * Layer 4 User-Defined Fields (UDF)
 */



# 1 "parde_no_varbit.p4" 1
/* -*- P4_16 -*- */

/*************************************************************************
 * C O M M O N   P A C K E T   P A R S I N G   A N D   D E P A R S I N G *
 *************************************************************************/

/*
 * This is the code for the common parser and deparser, used by simple_l3_acl.p4
 *
 * Given that the packet format is tightly couple with the parser code,
 * it makes sense to keep the structure of recognized headers here as well.
 *
 * Here is what the file defines:
 *
 * struct packet_headers_t  -- the list of parsed (and deparsed headers)
 * struct parser_metadata_t -- additional metadata that gets populated as a 
 *                             direct result of packet parsing
 * parser  PacketParser     -- the actual packet parsing code
 * control PacketDeparser   -- packet deparser code
 */

/* The packet headers these parser recognizes */
struct packet_headers_t {
    ethernet_h ethernet;
    vlan_tag_h[3] vlan_tag;
    ipv4_h ipv4;
    ipv4_option_word_h[10] ipv4_option_word;
    ipv6_h ipv6;
    ipv6_ext_hdr_h ipv6_ext_hdr;
    ipv6_ext_block_h[8] ipv6_ext_block;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    udp_h udp;
}

/* Additional metadata this parser can populate */

struct parser_metadata_t {
    ether_type_t l3_protocol;
    ip_proto_t l4_protocol;
    l4_lookup_t l4_lookup;
    bit<1> first_frag;
}

    /***********************  P A R S E R  **************************/
parser PacketParser(packet_in pkt,
                    out packet_headers_t hdr,
                    out parser_metadata_t parser_md)
{

    state start {
        parser_md.l3_protocol = (ether_type_t) 0;
        parser_md.l4_protocol = (ip_proto_t) 0;
        parser_md.l4_lookup = { 0, 0 };
        parser_md.first_frag = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        /* 
         * The explicit cast allows us to use ternary matching on
         * serializable enum
         */
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID &&& 0xEFFF : parse_vlan_tag;
            ether_type_t.IPV4 : parse_ipv4;
            ether_type_t.IPV6 : parse_ipv6;
            default : accept;
        }
    }
# 84 "parde_no_varbit.p4"
    state parse_vlan_tag {
        transition parse_vlan_tag_0;
    }

    state parse_vlan_tag_0 {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            ether_type_t.TPID : parse_vlan_tag_1;
            ether_type_t.IPV4 : parse_ipv4;
            default: accept;
        }
    }
    state parse_vlan_tag_1 {
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            ether_type_t.TPID : parse_vlan_tag_2;
            ether_type_t.IPV4 : parse_ipv4;
            default: accept;
        }
    }
    state parse_vlan_tag_2 {
        pkt.extract(hdr.vlan_tag[2]);
        transition select(hdr.vlan_tag[2].ether_type) {
            ether_type_t.IPV4 : parse_ipv4;
            default: accept;
        }
    }


    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        parser_md.l4_protocol = hdr.ipv4.protocol;

        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            /* 
             * Packets with other values of IHL are illegal and will be
             * dropped by the parser
             */
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ipv4_option_word[0]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        pkt.extract(hdr.ipv4_option_word[8]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        pkt.extract(hdr.ipv4_option_word[8]);
        pkt.extract(hdr.ipv4_option_word[9]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        parser_md.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP ) : parse_tcp;
            ( 0, ip_proto_t.UDP ) : parse_udp;
            ( 0, _ ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_first_fragment {
        parser_md.first_frag = 1;
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);

        parser_md.l4_protocol = hdr.ipv6.next_hdr;

        transition select(hdr.ipv6.next_hdr) {
            ip_proto_t.HOPOPT : parse_ipv6_ext;
            ip_proto_t.IPV6_OPTS : parse_ipv6_ext;
            ip_proto_t.IPV6_FRAGMENT : parse_ipv6_frag_ext;
            ip_proto_t.IPV6_ROUTE : parse_ipv6_ext;
            ip_proto_t.RESERVED_FD : parse_ipv6_ext;
            ip_proto_t.RESERVED_FE : parse_ipv6_ext;
            default: parse_ipv6_no_ext;
        }
    }

    state parse_ipv6_frag_ext {
        pkt.extract(hdr.ipv6_ext_hdr);
        parser_md.l4_protocol = hdr.ipv6_ext_hdr.next_hdr;

        transition select(
            hdr.ipv6_ext_hdr.ext_len, hdr.ipv6_ext_hdr.data[47:35]) {
            (0, 0) : parse_ipv6_after_ext;
            default: accept;
        }
    }

    state parse_ipv6_ext {
        pkt.extract(hdr.ipv6_ext_hdr);
        parser_md.l4_protocol = hdr.ipv6_ext_hdr.next_hdr;

        transition select(hdr.ipv6_ext_hdr.ext_len) {
            0 : parse_ipv6_after_ext;
            1 : parse_ipv6_ext_1;
            2 : parse_ipv6_ext_2;
            3 : parse_ipv6_ext_3;
            4 : parse_ipv6_ext_4;
            5 : parse_ipv6_ext_5;
            6 : parse_ipv6_ext_6;
            7 : parse_ipv6_ext_7;
            // default: parser-drop();
        }
    }

    state parse_ipv6_ext_1 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_2 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_3 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        pkt.extract(hdr.ipv6_ext_block[2]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_4 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        pkt.extract(hdr.ipv6_ext_block[2]);
        pkt.extract(hdr.ipv6_ext_block[3]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_5 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        pkt.extract(hdr.ipv6_ext_block[2]);
        pkt.extract(hdr.ipv6_ext_block[3]);
        pkt.extract(hdr.ipv6_ext_block[4]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_6 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        pkt.extract(hdr.ipv6_ext_block[2]);
        pkt.extract(hdr.ipv6_ext_block[3]);
        pkt.extract(hdr.ipv6_ext_block[4]);
        pkt.extract(hdr.ipv6_ext_block[5]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_ext_7 {
        pkt.extract(hdr.ipv6_ext_block[0]);
        pkt.extract(hdr.ipv6_ext_block[1]);
        pkt.extract(hdr.ipv6_ext_block[2]);
        pkt.extract(hdr.ipv6_ext_block[3]);
        pkt.extract(hdr.ipv6_ext_block[4]);
        pkt.extract(hdr.ipv6_ext_block[5]);
        pkt.extract(hdr.ipv6_ext_block[6]);
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_no_ext {
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_after_ext {
        parser_md.l4_lookup = pkt.lookahead<l4_lookup_t>();
        /* Note, we cannot get here if this is not a first fragment */
        transition select(parser_md.l4_protocol) {
            ip_proto_t.ICMP : parse_icmp;
            ip_proto_t.IGMP : parse_igmp;
            ip_proto_t.TCP : parse_tcp;
            ip_proto_t.UDP : parse_udp;
            default: parse_first_fragment;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition parse_first_fragment;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition parse_first_fragment;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_first_fragment;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition parse_first_fragment;
    }
}

    /*********************** D E P A R S E R  **************************/
control PacketDeparser(packet_out pkt,
                       in packet_headers_t hdr)
{
    apply {
        pkt.emit(hdr);
    }
}
# 174 "simple_l3_acl.p4" 2


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

typedef packet_headers_t my_ingress_headers_t;

struct my_ingress_metadata_t {
    parser_metadata_t parser_md;
    /* Add more fields if necessary */
}

parser IngressParser(packet_in pkt,
    /* User */
    out my_ingress_headers_t hdr,
    out my_ingress_metadata_t meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    /* 
     * We instantiate the packet parser, since we might also need in Egress.
     * Otherwise we could have invoked it directly, i.e. PacketParser.apply()
     */
    PacketParser() packet_parser;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        /* Invoke Common Packet Parser */
        packet_parser.apply(pkt, hdr, meta.parser_md);

        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

/* Common drop algorithm for ingress and egress. */
action set_drop(inout bit<3> drop_ctl) {
    drop_ctl = drop_ctl | 1;
}

control Ingress(
    /* User */
    inout my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    /* Intrinsic */
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action send(PortId_t port) {
            ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        set_drop(ig_dprsr_md.drop_ctl);
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }

    table ipv4_lpm {
        key = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(64);
        size = 1024;
    }

    action do_acl(bool do_redirect, PortId_t port,
        bool do_dst_mac, mac_addr_t new_dst_mac,
        bool do_src_mac, mac_addr_t new_src_mac)
    {
        /* 
         * On Tofino, only a boolean action data parameter can be used
         * as a condition
         */
        if (do_redirect) {
            send(port);
        }

        /* Ternary operation is also supported with the same restriction */
        hdr.ethernet.dst_addr = (do_dst_mac)
                                    ? new_dst_mac
                                    : hdr.ethernet.dst_addr;

        hdr.ethernet.src_addr = (do_src_mac)
                                    ? new_src_mac
                                    : hdr.ethernet.src_addr;
    }

    action do_ipmc_ether() {
        hdr.ethernet.dst_addr[47:24] = 0x01_00_5E;
        hdr.ethernet.dst_addr[23:0] = hdr.ipv4.dst_addr[23:0] & ~24w0x80_00_00;
    }

    table ipv4_acl {
        key = {
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            meta.parser_md.l4_lookup.word_1 : ternary;
            meta.parser_md.l4_lookup.word_2 : ternary;
            meta.parser_md.first_frag : ternary;
            ig_intr_md.ingress_port : ternary;
            ig_tm_md.ucast_egress_port : ternary;
        }
        actions = { NoAction; drop; send; do_acl; do_ipmc_ether; }
        size = 1024;
    }

    /* The algorithm */
    apply {
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 1) {
            if (!ipv4_host.apply().hit) {
                ipv4_lpm.apply();
            }
            ipv4_acl.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t hdr,
    in my_ingress_metadata_t meta,
    /* Intrinsic */
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    PacketDeparser() packet_deparser;

    apply {
        packet_deparser.apply(pkt, hdr);
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

typedef packet_headers_t my_egress_headers_t;

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    parser_metadata_t parser_md;
    /* Add more fields if necessary */
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in pkt,
    /* User */
    out my_egress_headers_t hdr,
    out my_egress_metadata_t meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t eg_intr_md)
{
    PacketParser() packet_parser;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);

        /* Use common packet parser */
        packet_parser.apply(pkt, hdr, meta.parser_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t hdr,
    inout my_egress_metadata_t meta,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{






    action drop() {
        set_drop(eg_dprsr_md.drop_ctl);
    }

    table ipv4_acl {
        key = {







            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            meta.parser_md.l4_lookup.word_1 : ternary;
            meta.parser_md.l4_lookup.word_2 : ternary;

            meta.parser_md.first_frag : ternary;
            eg_intr_md.egress_port : ternary;
        }
        actions = { NoAction; drop; }
        size = 2048;
    }

    apply {
        if (hdr.ipv4.isValid()) {
# 420 "simple_l3_acl.p4"
            ipv4_acl.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t hdr,
    in my_egress_metadata_t meta,
    /* Intrinsic */
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    PacketDeparser() packet_deparser;

    apply {
        packet_deparser.apply(pkt, hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
