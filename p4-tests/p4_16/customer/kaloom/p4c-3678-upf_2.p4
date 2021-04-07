# 1 "upf/p4src/pipe2/upf_2.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "upf/p4src/pipe2/upf_2.p4"
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "/mnt/build/p4c/p4include/core.p4" 1
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
# 11 "upf/p4src/pipe2/upf_2.p4" 2



# 1 "/mnt/build/p4c/p4include/tna.p4" 1

# 1 "/mnt/build/p4c/p4include/tofino1arch.p4" 1



# 1 "/mnt/build/p4c/p4include/core.p4" 1
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
# 5 "/mnt/build/p4c/p4include/tofino1arch.p4" 2
# 1 "/mnt/build/p4c/p4include/tofino.p4" 1



/**
 Version Notes:

 1.0.1:
 - Initial release
 1.0.2:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH

*/

# 1 "/mnt/build/p4c/p4include/core.p4" 1
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
# 15 "/mnt/build/p4c/p4include/tofino.p4" 2

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
    RegisterAction(Register<T, I> reg);

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
# 6 "/mnt/build/p4c/p4include/tofino1arch.p4" 2

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
# 3 "/mnt/build/p4c/p4include/tna.p4" 2
# 15 "upf/p4src/pipe2/upf_2.p4" 2


# 1 "upf/include/hw_defs/hw_defs.h" 1
/****************************************************************
 * Copyright (c) Kaloom, 2020
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ***************************************************************/

/* This file defines the size of the P4 tables. It is shared by the P4 code
 * and the C++ host code.
 */




/* UPLINK */






/* DOWNLINK */
# 18 "upf/p4src/pipe2/upf_2.p4" 2
# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*
 * Default constants and table sizes
 */
const PortId_t DEFAULT_CPU_PORT = 320;
const bit<8> DEFAULT_PUNT_TYPE = 0;

typedef bit<3> ring_id_t;
const ring_id_t KC_RINGID = 0x7;
const ring_id_t POLICY_RINGID = 0x6;
const ring_id_t GTP_RINGID = 0x5;
const ring_id_t DEFAULT_RINGID_SPAN = 0x4;

typedef bit<32> table_size_t;





/*
 *  Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now

/*
 *  Header minimum size
 */
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 0x0E;
const size_t IPV4_MIN_SIZE = 0x14;
const size_t IPV6_MIN_SIZE = 0x28;
const size_t UDP_SIZE = 0x08;
const size_t GTP_MIN_SIZE = 0x08;
const size_t VLAN_SIZE = 0x04;

/*
 *  Port number definitions
 */
typedef bit<16> port_t;
const port_t PORT_GTP_U = 2152;

/*
 *  IP Protocol definitions
 */
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_ICMP = 1;
const ip_protocol_t PROTO_UDP = 17;
const ip_protocol_t PROTO_TCP = 6;
const ip_protocol_t PROTO_IPV6 = 41;
const ip_protocol_t PROTO_ICMPV6 = 58;

/*
 * GTP definitions
 */
typedef bit<8> gtp_ie_type_t;
const gtp_ie_type_t GTP_IE_TYPE_RECOVERY = 14;

/*
 *  Type definitions
 */
typedef bit<16> knid_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<8> protocol_t;

/*
 * Single index indirect counters
 */
typedef bit<1> single_indirect_counter_t;
const single_indirect_counter_t SINGLE_INDIRECT_COUNTER = 1;

/*
 * Action index indirect counters
 */
typedef bit<16> dl_flow_id_indirect_counter_t;
const dl_flow_id_indirect_counter_t DL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> ul_flow_id_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> port_stats_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_PORT_STATS_INDIRECT_COUNTER = 16;

/*
 *  Padding for extended IPV4
 */
typedef bit<32> padding_32b_t;
const padding_32b_t ZEROS_PADDING_4B = 32w0x00000000;
const padding_32b_t ONES_PADDING_4B = 32w0xFFFFFFFF;
const padding_32b_t MIXED_PADDING_4B = 32w0x0000FFFF;

/*
* Padding for IPV6
*/
typedef bit<64> padding_64b_t;
const padding_64b_t ZEROS_PADDING_8B = 64w0x0000000000000000;
const padding_64b_t ONES_PADDING_8B = 64w0xFFFFFFFFFFFFFFFF;
const padding_64b_t MIXED_PADDING_8B = 64w0x00000000FFFFFFFF;
const padding_64b_t MIXED_SINGLE_FFFF_PADDING_8B = 64w0x000000000000FFFF;

typedef bit<96> padding_96b_t;
const padding_96b_t MIXED_PADDING_12B = 96w0x00000000000000000000FFFF;


/*
 *  Mirroring
 */
typedef MirrorId_t mirror_id_t; // Defined in tna.p4
typedef bit<3> mirror_type_t;

/*
 *  Source of the packet received
 */
typedef bit<3> pkt_src_t;
const pkt_src_t PKT_SRC_BRIDGE = 0;
const pkt_src_t PKT_SRC_CLONE_INGRESS = 1;
const pkt_src_t PKT_SRC_CLONE_EGRESS = 2;

typedef bit<9> port_comp_t;
const port_comp_t PORT_BIT_OR = 0x80;
# 14 "common/p4lib/core/headers/headers.p4" 2

/*************************************************************************
********************************** L2  ***********************************
*************************************************************************/

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vlanId;
    bit<16> etherType;
}

// Address Resolution Protocol
header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8> hwAddrLen;
    bit<8> protoAddrLen;
    bit<16> opcode;
}

/*************************************************************************
********************************** L3  ***********************************
*************************************************************************/

header ipv4_t { //Enhanced IP
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    protocol_t protocol;
    bit<16> hdrChecksum;
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    protocol_t nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
}

header icmp_t {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    //bit<32>    restOfHeader;
}


/*************************************************************************
********************************** L4  ***********************************
*************************************************************************/
@pa_no_overlay("egress", "hdr.outer_udp.checksum")
@pa_no_overlay("ingress", "hdr.outer_udp.checksum")
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seq;
    bit<32> ack;
    bit<4> dataOffset;
    bit<3> res;
    bit<9> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

/*************************************************************************
******************************* Tunneling  *******************************
*************************************************************************/

header gtp_u_t {
    bit<3> version;
    bit<1> pt;
    bit<1> spare;
    bit<1> extFlag;
    bit<1> seqFlag;
    bit<1> pn;
    bit<8> msgType;
    bit<16> totalLen;
    bit<32> teid;
}

header gtp_u_options_t {
    bit<16> seqNumb;
    bit<8> npdu;
    bit<8> neh;
}

header gtp_u_ext_header_len_t {
    bit<8> len;
}

/*
 * PDU session container (GTP header extension). More details in 3GPP
 * spec. 38415 and 29281.
 * Type 0 for downlink (8 bytes)
 * Type 1 for uplink (4 bytes)
 * neh value: 0x85
 * Length of this header should be 4n, thus the padding.
 */
header gtp_u_pdu_sess_cont_dl_t {
    bit<4> type;
    bit<4> spare0;
    bit<1> ppp;
    bit<1> rqi;
    bit<6> qfi;
    bit<3> ppi;
    bit<5> spare1;
    bit<24> pad0;

    bit<8> neh;
}

header gtp_u_pdu_sess_cont_ul_t {
    bit<4> type;
    bit<4> spare0;
    bit<1> ppp;
    bit<1> rqi;
    bit<6> qfi;

    bit<8> neh;
}

/* The GTP Recovery information element */
header gtp_u_recovery_ie_t {
    gtp_ie_type_t type;
    bit<8> restart_counter;
}

/*************************************************************************
*************************  DP Control Header  ****************************
*************************************************************************/

/* Metadata for packets that are forwarded to/from CPU */
header dp_ctrl_header_t {
    bit<5> _pad0; /* This padding is needed because the ring identifier corresponds
                    * to the 3 lower bits in the first byte of the packet
                    */
    ring_id_t ring_id; /* Ring Identifier */
    bit<72> _pad1; /* 9 Bytes of padding needed to match a regular Ethernet Header size */
    bit<16> port; /* input/output port */
    bit<16> etherType; /* Ethertype of ETHERTYPE_DP_CTRL */
}

/*************************************************************************
******************** Ingress/Egress bridge Header  ***********************
*************************************************************************/

header upf_bridged_metadata_t {
// user-defined metadata carried over from ingress to egress. 128 bits.
    bit<8> session_miss; // Counter of session tables missed
                                    // Could be 3 bits, but for alignement
                                    // purposes we allocate 8 bits
    knid_t ingress_iid; // IID on which the packet arrived
    knid_t iid; // IID where the packet is forwarded
    bit<1> _pad0;
    bit<1> flow_sess_lookup;
    bit<1> policy_table; // Record if policy table has been hit
    bit<1> flow_table; // Record if flow table has been hit
    bit<1> drop; // If packet must be dropped
    bit<2> punt_type; // Used to know what kind of punt it is
                                    // Punt type:
                                    // 00: other (0x0)
                                    // 01: kc_punt (0x01)
                                    // 10: policy_punt (0x2)
                                    // 11: gtp_punt (0x3)
    bit<1> punt; // Used to know if packet must be punted
    bit<7> _pad1;
    PortId_t ucast_egress_port; // Used to transport egress port
    bit<7> _pad2;
    PortId_t ingress_port; // Store ingress prot number for counters
    bit<4> _pad3;
    bit<20> flowId; // Store flowId for action table and counters
// add more fields here.
}

/* For dependency that rely on this size, in bytes and hexadecimal */


/*************************************************************************
************************* Headers declaration ****************************
*************************************************************************/

struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl;
    ethernet_t ethernet;
    vlan_t vlan;
    arp_t arp;
    ipv4_t outer_ipv4;
    ipv6_t outer_ipv6;
    icmp_t icmp;
    udp_t outer_udp;
    tcp_t outer_tcp;
    gtp_u_t gtp_u;
    gtp_u_options_t gtp_u_options;
    gtp_u_ext_header_len_t gtp_u_ext_header_len;
    gtp_u_pdu_sess_cont_ul_t gtp_u_pdu_sess_cont_ul;
    gtp_u_pdu_sess_cont_dl_t gtp_u_pdu_sess_cont_dl;
    gtp_u_recovery_ie_t gtp_u_recovery_ie;
    ipv4_t inner_ipv4;
    ipv6_t inner_ipv6;
    udp_t inner_udp;
    tcp_t inner_tcp;
}
# 19 "upf/p4src/pipe2/upf_2.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 20 "upf/p4src/pipe2/upf_2.p4" 2

# 1 "upf/p4src/pipe2/UPFIngress5_2.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/

# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "upf/p4src/pipe2/UPFIngress5_2.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "upf/p4src/pipe2/UPFIngress5_2.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/metadata.p4" 2

header upf_port_metatdata_t {
    bit<7> _pad ;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

struct local_metadata_t {
    bit<1> policy_hit;
    bit<64> dstPrefix;
}

//=============================================================================
// Egress metadata
//=============================================================================

enum bit<2> GtpAction {
    forward = 0,
    decap = 1,
    encap = 2
}

struct upf_egress_metadata_t {
    bit<16> pkt_length; // Used to store pkt_length out of the TM
    bit<32> srcAddrv4; // Src IPv4 of egress port, given in egress port table
    bit<128> srcAddrv6; // Src IPv6 of egress port, given in egress port table
    bit<128> dstAddrv6; // Used to store original dst addr for session lookup
    protocol_t nextHdrv6; // Use to store next header for policy lookup
    ipv6_addr_t dstAddr; // Dst IP (v4 or v6) given in action id table
    bit<32> teid; // Used to store TEID given by action id table
    bit<1> protoEncap; // Given by action id table, to select encap
                                   // 0: ipv4 1: ipv6
    bit<1> n9; // Given by action id table in uplink and set
                                   // in apply block in downlink. Used for encap
                                   // purposes.
    GtpAction gtpAction; // Work to be performed by GTP
    bit<1> inner_dst_rewrite; // Used by action rewritre_inner_dst
                                   // in case of inner packet matching
                                   // in uplink.
    bit<20> flowId; // Store flow ID for counters
    ipv6_addr_t innerSrcAddrv6; // Used for inner packet matching
    ipv6_addr_t innerDstAddrv6; // Used for inner packet matching
    protocol_t innerNextHdrv6; // Used for inner packet matching
}


//=============================================================================
// Ingres metadata
//=============================================================================
struct upf_ingress_metadata_t {
    bit<1> drop; // Used to know if packet must be dropped
    bit<9> cpu_port; // Used to store CPU port
    ring_id_t ring_span; // Punt ring mechanism
    ring_id_t kc_ring_id; // Punt ring mechanism
    ring_id_t policy_ring_id; // Punt ring mechanism
    ring_id_t gtp_ring_id; // Punt ring mechanism
    bit<2> color; // Punt ring mechanism, for meters
    bit<1> activate_meters; // Punt ring mechanism, for meters
    bit<1> gtp_echo; // For GTP echo messages
    mac_addr_t srcMac; // For GTP echo messages
    mac_addr_t dstMac; // For GTP echo messages
    ipv6_addr_t srcAddrv6; // Used for GTP echo messages, and for
                                    // flow table and policy lookup. Store
                                    // original ipv6 src addr.
    ipv6_addr_t dstAddrv6; // Used to store original dst addr for
                                    // session, policy and flow lookup
    protocol_t nextHdrv6; // Use to store next header for policy
                                    // and flow lookup
    bit<32> srcAddr; // Used to store original src IPv4 for GTP
                                    // echo messages
    bit<32> dstAddr; // Used to store original dst IPv4 for GTP
                                    // echo messages

    ipv6_addr_t innerSrcAddrv6; // Used for inner packet matching
    ipv6_addr_t innerDstAddrv6; // Used for inner packet matching
    protocol_t innerNextHdrv6; // Used for inner packet matching
}
# 14 "upf/p4src/pipe2/UPFIngress5_2.p4" 2
# 1 "upf/p4src/common/ingress_port_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/ingress_port_table.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/common/ingress_port_table.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "upf/p4src/common/ingress_port_table.p4" 2
//=============================================================================
// Ingress port table
//=============================================================================

control IngressPortTable(inout headers hdr,
        in ingress_intrinsic_metadata_t ig_intr_md) {

    action store_ingress_port(){
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
    }

    action punt() {
        hdr.bridged_md.punt = 0x1;
    }

    action get_iid(knid_t iid) {
        hdr.bridged_md.ingress_iid = iid;
    }

    table port_table {
        key = {
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
        }
        actions = {
            get_iid;
            @defaultonly punt;
        }
        size = 512;
        default_action = punt;
    }

    apply {
        port_table.apply();
        store_ingress_port();
    }
}
# 15 "upf/p4src/pipe2/UPFIngress5_2.p4" 2
# 1 "upf/p4src/common/flow_table.p4" 1
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "upf/p4src/common/flow_table.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "upf/p4src/common/flow_table.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/flow_table.p4" 2
//=============================================================================
// Flow table control
//=============================================================================

control FlowTableDownlink(inout headers hdr, in bit<128> dstAddrv6, in bit<128> srcAddrv6, in protocol_t nextHdrv6)(table_size_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) flow_cntr;

    action flow_fwd_encap(knid_t iid, bit<20> flowId) {
        flow_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;

        //If flow table is hit, ig_md.flow_table = 1
        hdr.bridged_md.flow_table = 1;
    }

    table flow_table {
        key = {
            hdr.bridged_md.ingress_iid : exact;
            srcAddrv6 : exact;
            dstAddrv6 : exact;
            hdr.outer_tcp.srcPort : exact;
            hdr.outer_tcp.dstPort : exact;
            nextHdrv6 : exact;
        }
        actions = {
            flow_fwd_encap;
        }
        size = table_size;
        counters = flow_cntr;
    }

    apply {
        flow_table.apply();
    }

}

control FlowTableUplink(inout headers hdr, in bit<128> dstAddrv6, in protocol_t nextHdrv6)(table_size_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) flow_cntr;

    action flow_fwd_decap(knid_t iid, bit<20> flowId) {
        flow_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;

        //If flow table is hit, ig_md.flow_table = 1
        hdr.bridged_md.flow_table = 1;
    }

    action flow_session_lookup(knid_t iid, bit<20> flowId) {
        flow_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;
        hdr.bridged_md.flow_sess_lookup = 1;
    }

    table flow_table {
        key = {
            hdr.bridged_md.ingress_iid : exact;
            dstAddrv6 : exact;
            hdr.inner_tcp.dstPort : exact;
            nextHdrv6 : exact;
        }
        actions = {
            flow_fwd_decap;
            flow_session_lookup;
        }
        size = table_size;
        counters = flow_cntr;
    }

    apply {
        flow_table.apply();
    }
}
# 16 "upf/p4src/pipe2/UPFIngress5_2.p4" 2
# 1 "upf/p4src/common/skip_pdu_sess_cont.p4" 1
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "upf/p4src/common/skip_pdu_sess_cont.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "upf/p4src/common/skip_pdu_sess_cont.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/skip_pdu_sess_cont.p4" 2
//=============================================================================
// Skip PDU Session Container
//
// This block is only temporary until the full PDU Session Container and QFI
// support.
//=============================================================================

control SkipPDUSessCont(inout headers hdr)() {

    action set_gtp_u_options_len_invalid() {
        hdr.gtp_u_options.setInvalid();
        hdr.gtp_u_ext_header_len.setInvalid();
        hdr.gtp_u.extFlag = 0x0;
        hdr.gtp_u.seqFlag = 0x0;
        hdr.gtp_u.pn = 0x0;
    }

    action compute_len_sess_cont_type_ul(){
        // 4 byte of gtpu options
        // 1 byte of extension header length
        // 3 byte of pdu session container UL
        hdr.gtp_u.totalLen = hdr.gtp_u.totalLen - 0x8;
        hdr.outer_udp.hdrLen = hdr.outer_udp.hdrLen - 0x8;
    }

    action compute_len_sess_cont_type_dl(){
        // 4 byte of gtpu options
        // 1 byte of extension header length
        // 7 byte of pdu session container DL
        hdr.gtp_u.totalLen = hdr.gtp_u.totalLen - 0xc;
        hdr.outer_udp.hdrLen = hdr.outer_udp.hdrLen - 0xc;
    }

    action invalidate_pdu_ul_ipv4() {
        set_gtp_u_options_len_invalid();
        hdr.gtp_u_pdu_sess_cont_ul.setInvalid();
        compute_len_sess_cont_type_ul();
        hdr.outer_ipv4.totalLen = hdr.outer_ipv4.totalLen - 0x8;
    }

    action invalidate_pdu_ul_ipv6() {
        set_gtp_u_options_len_invalid();
        hdr.gtp_u_pdu_sess_cont_ul.setInvalid();
        compute_len_sess_cont_type_ul();
        hdr.outer_ipv6.payloadLen = hdr.outer_ipv6.payloadLen - 0x8;
    }

    action invalidate_pdu_dl_ipv4() {
        set_gtp_u_options_len_invalid();
        hdr.gtp_u_pdu_sess_cont_dl.setInvalid();
        compute_len_sess_cont_type_dl();
        hdr.outer_ipv4.totalLen = hdr.outer_ipv4.totalLen - 0xc;
    }

    action invalidate_pdu_dl_ipv6() {
        set_gtp_u_options_len_invalid();
        hdr.gtp_u_pdu_sess_cont_dl.setInvalid();
        compute_len_sess_cont_type_dl();
        hdr.outer_ipv6.payloadLen = hdr.outer_ipv6.payloadLen - 0xc;
    }

    table pdu_sess_cont_delete {
        key = {
            hdr.gtp_u_pdu_sess_cont_ul.isValid(): exact;
            hdr.gtp_u_pdu_sess_cont_dl.isValid(): exact;
            hdr.outer_ipv6.isValid(): exact;
        }
        actions = {
            invalidate_pdu_ul_ipv6;
            invalidate_pdu_ul_ipv4;
            invalidate_pdu_dl_ipv6;
            invalidate_pdu_dl_ipv4;
        }

        const entries = {
            (true, false, false): invalidate_pdu_ul_ipv4();
            (true, false, true): invalidate_pdu_ul_ipv6();
            (false, true, false): invalidate_pdu_dl_ipv4();
            (false, true, true): invalidate_pdu_dl_ipv6();
        }
        size = 8;
    }

    apply {
        pdu_sess_cont_delete.apply();
    }
}
# 17 "upf/p4src/pipe2/UPFIngress5_2.p4" 2

//=============================================================================
// Ingress Parser
//=============================================================================
parser UPFIngress5_2Parser(
            packet_in pkt,
            out headers hdr,
            out upf_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    /*
     *  Packet entry point.
     */
    @pa_container_size("ingress", "ig_intr_md.ingress_port", 16)
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
     }

    state parse_port_metadata {
        //Parse port metadata appended by tofino
        upf_port_metatdata_t port_md;
        pkt.extract(port_md);
        transition parse_packet;
    }

    state parse_packet {
        dp_ctrl_header_t ether = pkt.lookahead<dp_ctrl_header_t>();
        transition select(ether.etherType) {
            ETHERTYPE_DP_CTRL : parse_dp_ctrl;
            default : parse_ethernet;
        }
    }

    /*
     *  Dp-ctrl parsing.
     */
    state parse_dp_ctrl {
        pkt.extract(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            ETHERTYPE_DP_CTRL : parse_ethernet;
            default : accept;
         }
    }

    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        ig_md.srcMac = hdr.ethernet.srcAddr;
        ig_md.dstMac = hdr.ethernet.dstAddr;
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  ARP parsing.
     */
    state parse_arp {
        pkt.extract(hdr.arp);
        hdr.bridged_md.punt = 0x1;
        transition accept;
    }
    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        ig_md.srcAddr = hdr.outer_ipv4.srcAddr;
        ig_md.dstAddr = hdr.outer_ipv4.dstAddr;
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_ICMP : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        ig_md.srcAddrv6 = hdr.outer_ipv6.srcAddr;
        ig_md.dstAddrv6 = hdr.outer_ipv6.dstAddr;
        ig_md.nextHdrv6 = hdr.outer_ipv6.nextHdr;
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_ICMPV6 : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     * Parse ICMP
     */
    state parse_icmp {
        pkt.extract(hdr.icmp);
        //hdr.bridged_md.punt = 0x1;
        transition accept;
    }
    /*
    *  GTP_U parsing.
    */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (_, 0, _, 0x01) : drop; // Drop GTP echo request if S flag not set
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,0xFF) : accept;
            default : gtp_punt;
        }
    }

    /*
    *  GTP_U parsing.
    */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType, hdr.gtp_u_options.neh) {
            (0x01, _) : gtp_echo;
            // 0x85 corresponds to PDU Session Container
            (0xFF, 0x85) : parse_pdu_session_container;
            (0xFF, _) : accept;
            default : gtp_punt;
        }
    }

    state parse_pdu_session_container {
        pkt.extract(hdr.gtp_u_ext_header_len);
        transition select(hdr.gtp_u_ext_header_len.len){
            /* Here we parse based on the length and not the type
             * Extension headers are 4n bytes. n being the length
             * on which we select here.
             */
            0x2 : parse_pdu_session_container_dl;
            0x1 : parse_pdu_session_container_ul;
            default : gtp_punt;
        }
    }

    state parse_pdu_session_container_dl {
        pkt.extract(hdr.gtp_u_pdu_sess_cont_dl);
        transition select(hdr.gtp_u.msgType){
            (0x01) : gtp_echo;
            (0xFF) : accept;
            default : gtp_punt;
        }
    }

    state parse_pdu_session_container_ul {
        pkt.extract(hdr.gtp_u_pdu_sess_cont_ul);
        transition select(hdr.gtp_u.msgType){
            (0x01) : gtp_echo;
            (0xFF) : accept;
            default : gtp_punt;
        }
    }

    /*
    * Packet will be drop/punt, but we need to pass it to ingress control block for counter
    * purposes.
    */
    state drop {
        ig_md.drop = 0x1;
        transition accept;
    }

    /*
    * First gress parser has to punt if it is GTP option.
    */
    state gtp_punt {
        hdr.bridged_md.punt_type = 0x3;
        transition accept;
    }


    state gtp_echo {
        ig_md.gtp_echo = 0x1;
        transition accept;
    }
}


//=============================================================================
// Ingress5_2 control (dowlink)
//=============================================================================

control UPFIngress_Downlink_5_2(
    inout headers hdr,
    inout upf_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    IngressPortTable() ingress_port_table;
    FlowTableDownlink(40000) flow_table;
    SkipPDUSessCont() pdu_sess_cont;

    /* CPU counters */
    Counter<bit<32>,single_indirect_counter_t>(32, CounterType_t.PACKETS_AND_BYTES) send_from_cpu_cntr;

    action set_ip_lkpv4() {
        ig_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.srcAddrv6[95:64] = hdr.outer_ipv4.srcAddr;
        ig_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;

        ig_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.dstAddrv6[95:64] = hdr.outer_ipv4.dstAddr;
        ig_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        ig_md.nextHdrv6 = hdr.outer_ipv4.protocol;
    }


    // We mask the 64 lower bits of the destination address in IPv6 case
    // accordingly to IPv6 SLAAC
    action set_ip_lkpv6() {
        ig_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
    }

    table extract_info_table{
        key = {
            hdr.outer_ipv4.isValid() : exact;
            hdr.outer_ipv6.isValid() : exact;
        }
        actions = {
            set_ip_lkpv4;
            set_ip_lkpv6;
        }
        const entries = {
            (true, false): set_ip_lkpv4();
            (false, true): set_ip_lkpv6();
        }
        size = 4; // 2^2
    }

    action send_from_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = (PortId_t)hdr.dp_ctrl.port;
        hdr.dp_ctrl.setInvalid();
        send_from_cpu_cntr.count(SINGLE_INDIRECT_COUNTER);
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    action gtp_echo_response() {
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.outer_udp.checksum = 0x0;
        hdr.outer_udp.hdrLen = hdr.outer_udp.hdrLen + 2; /* Account for addition of Recovery IE */
        hdr.gtp_u.teid = 0x0;
        hdr.gtp_u.msgType = 0x2;
        hdr.gtp_u.totalLen = hdr.gtp_u.totalLen + 2; /* Account for addition of Recovery IE */
        hdr.gtp_u_recovery_ie.setValid();
        hdr.gtp_u_recovery_ie.type = GTP_IE_TYPE_RECOVERY;
        hdr.gtp_u_recovery_ie.restart_counter = 0;
        hdr.ethernet.srcAddr = ig_md.dstMac;
        hdr.ethernet.dstAddr = ig_md.srcMac;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    action drop_pkt_ingress() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        exit;
    }

    /*
    * int_load_balancing_reg register
    * Load balancing on internal ports, round robin mode
    */
    Register<bit<16>, bit<1>> (0x1) int_load_balancing_reg;
    RegisterAction< bit<16>, bit<1>, bit<16>>(int_load_balancing_reg) int_load_balancing_reg_action = {
        void apply(inout bit<16> value, out bit<16> read_value){
            if (value > 0x1be || value < 0x180){ // 0x1be=446 0x180=384
                value = 0x180;
            } else {
                value = value + 1;
            }
            read_value = value;
        }
    };

    action send_on_folded(){
        ig_intr_md_for_tm.ucast_egress_port = (bit<9>) int_load_balancing_reg_action.execute(0);
        hdr.bridged_md.setValid();
    }

    action mark_to_punt_kc() {
        hdr.bridged_md.punt = 0x1;
        hdr.bridged_md.punt_type = 0x1;
    }

    // If Kubernetes Vlan hit, punt to cpu with dedicated ring ID.
    table kc_table{
        key = {
            hdr.vlan.vlanId : exact;
        }
        actions = {
            mark_to_punt_kc;
        }
        size = 1;
    }

    table parser_marked_table {
        key = {
            ig_md.drop : exact;
            hdr.dp_ctrl.isValid() : exact;
        }
        actions = {
            drop_pkt_ingress;
            send_from_cpu;
            NoAction;
        }
        const entries = {
            (0x1, false) : drop_pkt_ingress();
            (0x0, true) : send_from_cpu();
            (0x0, false) : NoAction();
            (0x1, true) : NoAction();
        }
        size = 4; // 2^2
    }

    action swap_v4(){
        hdr.outer_ipv4.srcAddr = ig_md.dstAddr;
        hdr.outer_ipv4.dstAddr = ig_md.srcAddr;
        hdr.outer_ipv4.totalLen = hdr.outer_ipv4.totalLen + 2; /* Account for addition of Recovery IE */
    }

    action swap_v6() {
        hdr.outer_ipv6.srcAddr = ig_md.dstAddrv6;
        hdr.outer_ipv6.dstAddr = ig_md.srcAddrv6;
        hdr.outer_ipv6.payloadLen = hdr.outer_ipv6.payloadLen + 2; /* Account for addition of Recovery IE */
    }

    apply {
        // TODO: PDU session container full support
        pdu_sess_cont.apply(hdr);

        parser_marked_table.apply();
        if (ig_md.gtp_echo == 1) {
            if(hdr.outer_ipv6.isValid()){
                swap_v6();
            }
            else {
                swap_v4();
            }
            gtp_echo_response();
        }
        else {
            extract_info_table.apply();

            kc_table.apply();
            ingress_port_table.apply(hdr, ig_intr_md);
            flow_table.apply(hdr,ig_md.dstAddrv6, ig_md.srcAddrv6, ig_md.nextHdrv6);
            send_on_folded();
        }
    }
}

//=============================================================================
// Ingress5_2 Deparser
//=============================================================================
control UPFIngress5_2Deparser(
            packet_out pkt,
            inout headers hdr,
            in upf_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Checksum() outer_ipv4_checksum;

    apply{
        /* Must recompute IPv4 checksum for GTP Echo Response packets which
         * bypass the egress pipeline.
         */
        if (hdr.outer_ipv4.isValid()) {
            hdr.outer_ipv4.hdrChecksum = outer_ipv4_checksum.update({
                    hdr.outer_ipv4.version,
                    hdr.outer_ipv4.ihl,
                    hdr.outer_ipv4.diffserv,
                    hdr.outer_ipv4.totalLen,
                    hdr.outer_ipv4.identification,
                    hdr.outer_ipv4.flags,
                    hdr.outer_ipv4.fragOffset,
                    hdr.outer_ipv4.ttl,
                    hdr.outer_ipv4.protocol,
                    hdr.outer_ipv4.srcAddr,
                    hdr.outer_ipv4.dstAddr
            });
        }

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        // TODO: when PDU session container is fully supported
        pkt.emit(hdr.gtp_u_ext_header_len);
        pkt.emit(hdr.gtp_u_recovery_ie);
        pkt.emit(hdr.gtp_u_pdu_sess_cont_ul);
        pkt.emit(hdr.gtp_u_pdu_sess_cont_dl);
    }
}
# 22 "upf/p4src/pipe2/upf_2.p4" 2
# 1 "upf/p4src/pipe2/UPFEgress4_2.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/pipe2/UPFEgress4_2.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/pipe2/UPFEgress4_2.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "upf/p4src/pipe2/UPFEgress4_2.p4" 2
# 1 "upf/p4src/common/gtp.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/gtp.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/common/gtp.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "upf/p4src/common/gtp.p4" 2

/*
* Subtract 4 from the packet length to account for the 4 bytes of Ethernet
* FCS that is included in Tofino's packet length metadata.
* - ETH_MIN_SIZE (0xE)
* - SIZE OF BRIDGES METADATA (0xE)
* - VLAN_SIZE (0x4)
* = 0x24
*/


control EncapGTP(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action payload_fcs_bridged_vlan_len() {
        eg_md.pkt_length = eg_md.pkt_length - (0x4 + 0xE + 0x4 + 0xD);
    }

    action compute_len_v4() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
    }

    action compute_len_v6() {
        hdr.outer_ipv6.payloadLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
    }

    action compute_len_v4_n9() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + hdr.outer_udp.hdrLen;
    }

    action compute_len_v6_n9() {
        hdr.outer_ipv6.payloadLen = hdr.outer_udp.hdrLen;
    }

    action compute_len_gtp_udp() {
        hdr.outer_udp.hdrLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.gtp_u.totalLen = eg_md.pkt_length;
    }

    action copy_outer_ip_to_inner_ipv4() {
        // Copy outer IP to inner IP
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4 = hdr.outer_ipv4;
    }

    action copy_outer_ip_to_inner_ipv6() {
        // Copy outer IP to inner IP
        hdr.inner_ipv6.setValid();
        hdr.inner_ipv6 = hdr.outer_ipv6;
    }

    action add_gtp() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;

        hdr.gtp_u.teid = eg_md.teid;
    }

    action copy_outer_tcp_to_inner_tcp() {
        hdr.inner_tcp.setValid();
        hdr.inner_tcp = hdr.outer_tcp;
        hdr.outer_tcp.setInvalid();
    }

    action copy_outer_udp_to_inner_udp() {
        hdr.inner_udp.setValid();
        hdr.inner_udp = hdr.outer_udp;
    }

    action add_outer_udp() {
        // ADD outer UDP
        hdr.outer_udp.setValid();
        hdr.outer_udp.dstPort = PORT_GTP_U;
        hdr.outer_udp.srcPort = PORT_GTP_U;
    }

    action set_checksum_udp(){
        // Tofino does not support UDP checksum
        hdr.outer_udp.checksum = 0;
    }

    action rewrite_v4() {
        hdr.outer_ipv4.dstAddr = eg_md.dstAddr[95:64];
        hdr.outer_ipv4.srcAddr = eg_md.srcAddrv4;
    }

    action rewrite_v6() {
        hdr.outer_ipv6.dstAddr = eg_md.dstAddr;
        hdr.outer_ipv6.srcAddr = eg_md.srcAddrv6;
    }

    action modify_outer_ipv4() {
        hdr.outer_ipv4.version = 0x4;
        hdr.outer_ipv4.ihl = 0x5;
        hdr.outer_ipv4.diffserv = 0x0;
        hdr.outer_ipv4.identification = 0x1;
        hdr.outer_ipv4.ttl = 0x40;
        hdr.outer_ipv4.flags = 0x0;
        hdr.outer_ipv4.fragOffset = 0x0;
        hdr.vlan.etherType = ETHERTYPE_IPV4;
        hdr.outer_ipv4.dstAddr = eg_md.dstAddr[95:64];
        hdr.outer_ipv4.srcAddr = eg_md.srcAddrv4;

        hdr.outer_ipv4.protocol = PROTO_UDP;
    }

    action modify_outer_ipv6() {
        hdr.vlan.etherType = ETHERTYPE_IPV6;
        hdr.outer_ipv6.version = 0x6;
        hdr.outer_ipv6.trafficClass = 0x00;
        hdr.outer_ipv6.flowLabel = 0x00000;
        hdr.outer_ipv6.hopLimit = 0x40;
        hdr.outer_ipv6.dstAddr = eg_md.dstAddr;
        hdr.outer_ipv6.srcAddr = eg_md.srcAddrv6;

        hdr.outer_ipv6.nextHdr = PROTO_UDP;
    }

    action v4_to_v4(){
        copy_outer_ip_to_inner_ipv4();
        modify_outer_ipv4();
    }
    action v4_to_v6(){
        copy_outer_ip_to_inner_ipv4();
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setValid();
        modify_outer_ipv6();
    }
    action v6_to_v4(){
        copy_outer_ip_to_inner_ipv6();
        hdr.outer_ipv6.setInvalid();
        hdr.outer_ipv4.setValid();
        modify_outer_ipv4();
    }
    action v4_to_v6_n9(){
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setValid();
        modify_outer_ipv6();
    }
    action v6_to_v4_n9(){
        hdr.outer_ipv6.setInvalid();
        hdr.outer_ipv4.setValid();
        modify_outer_ipv4();
    }
    action v6_to_v6(){
        copy_outer_ip_to_inner_ipv6();
        modify_outer_ipv6();
    }

    table select_encap {
        key = {
            eg_md.gtpAction: exact;
            eg_md.protoEncap: exact;
            hdr.outer_ipv4.isValid(): exact;
            hdr.outer_ipv6.isValid(): exact;
        }
        actions = {
            rewrite_v6;
            rewrite_v4;
            v4_to_v6_n9;
            v6_to_v4_n9;
            v4_to_v4;
            v4_to_v6;
            v6_to_v4;
            v6_to_v6;
        }
        const entries = {
            (GtpAction.forward, 0, true, false): rewrite_v4();
            (GtpAction.forward, 1, false, true): rewrite_v6();
            (GtpAction.forward, 1, true, false): v4_to_v6_n9();
            (GtpAction.forward, 0, false, true): v6_to_v4_n9();
            (GtpAction.encap, 0, true, false): v4_to_v4();
            (GtpAction.encap, 1, true, false): v4_to_v6();
            (GtpAction.encap, 0, false, true): v6_to_v4();
            (GtpAction.encap, 1, false, true): v6_to_v6();
        }
        size = 16; // 2^4
    }

    table copy_inner_tcp_or_udp {
        key = {
            hdr.outer_tcp.isValid(): exact;
            hdr.outer_udp.isValid(): exact;
        }
        actions = {
            copy_outer_tcp_to_inner_tcp;
            copy_outer_udp_to_inner_udp;
        }
        const entries = {
            (true, false): copy_outer_tcp_to_inner_tcp();
            (false, true): copy_outer_udp_to_inner_udp();
        }
        size = 4; // 2^2
    }

    apply {
        payload_fcs_bridged_vlan_len();
        select_encap.apply();
        add_gtp();

        if (eg_md.gtpAction == GtpAction.encap) {
            /*
            * If we parsed a outer tcp we need to copy it to inner tcp
            * and delete it.
            */
            copy_inner_tcp_or_udp.apply();
            add_outer_udp();
        }

        /*
         * Lengths computation.
        */
        if (eg_md.protoEncap == 0x0 && eg_md.gtpAction == GtpAction.encap) {
            compute_len_v4();
        } else if (eg_md.protoEncap == 0x0 && eg_md.gtpAction == GtpAction.forward) {
            compute_len_v4_n9();
        } else if (eg_md.protoEncap == 0x1 && eg_md.gtpAction == GtpAction.forward) {
            compute_len_v6_n9();
        } else if (eg_md.protoEncap == 0x1 && eg_md.gtpAction == GtpAction.encap) {
            compute_len_v6();
        }

        if (eg_md.gtpAction == GtpAction.encap) {
            compute_len_gtp_udp();
        }
        set_checksum_udp();
    }
}

control DecapGTP(inout headers hdr) {

    action set_ipv4_ether() {
        hdr.vlan.etherType = ETHERTYPE_IPV4;
    }

    action set_ipv6_ether() {
        hdr.vlan.etherType = ETHERTYPE_IPV6;
    }

    action decap_gtp() {
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.gtp_u.setInvalid();
        hdr.gtp_u_options.setInvalid();
    }

    apply {
        decap_gtp();

        if(hdr.inner_ipv6.isValid()){
            set_ipv6_ether();
        } else {
            set_ipv4_ether();
        }
    }
}

control RewriteInnerDst(inout headers hdr,
                inout upf_egress_metadata_t eg_md) {

    action rewrite_dst_v4() {
        hdr.inner_ipv4.dstAddr = eg_md.dstAddr[95:64];
    }

    action rewrite_dst_v6() {
        hdr.inner_ipv6.dstAddr = eg_md.dstAddr;
    }

    table rewrite_inner_dst {
        key = {
            eg_md.protoEncap: exact;
        }
        actions = {
            rewrite_dst_v6;
            rewrite_dst_v4;
        }
        const entries = {
            (0x0): rewrite_dst_v4;
            (0x1): rewrite_dst_v6;
        }
        size = 2;
    }

    apply {
        rewrite_inner_dst.apply();
    }
}

control GTP(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    EncapGTP() encap;
    DecapGTP() decap;
    RewriteInnerDst() rewrite_inner_dst;

    apply {
        if (eg_md.gtpAction == GtpAction.decap) {
            decap.apply(hdr);
            if (eg_md.inner_dst_rewrite == 0x1) {
                rewrite_inner_dst.apply(hdr, eg_md);
            }
        } else {
            encap.apply(hdr, eg_md);
        }
    }
}
# 18 "upf/p4src/pipe2/UPFEgress4_2.p4" 2
# 1 "upf/p4src/common/egress_port_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/egress_port_table.p4" 2

//=============================================================================
// Egress port table
//=============================================================================

control EgressPortTable(inout headers hdr,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        inout upf_egress_metadata_t eg_md) {

    action get_port_info(mac_addr_t dstMac, mac_addr_t srcMac, bit<32> srcIpv4, bit<128> srcIpv6, bit<12> vlanId) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ethernet.srcAddr = srcMac;
        eg_md.srcAddrv4 = srcIpv4;
        eg_md.srcAddrv6 = srcIpv6;
        hdr.vlan.vlanId = vlanId;
    }


    table port_table {
        key = {
            eg_intr_md.egress_port : exact;
            hdr.bridged_md.iid : exact;
        }
        actions = {
            get_port_info;
        }
        size = 512;
    }

    apply {
        port_table.apply();
    }
}
# 19 "upf/p4src/pipe2/UPFEgress4_2.p4" 2
# 1 "upf/p4src/common/action_id_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/

# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "upf/p4src/common/action_id_table.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "upf/p4src/common/action_id_table.p4" 2
# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 13 "upf/p4src/common/action_id_table.p4" 2

//=============================================================================
// Action ID table control
//=============================================================================

control ActionIdTable(inout headers hdr, inout upf_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(table_size_t table_size) {

    action punt(){}

    action drop(){
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action fwd_decap() {
        eg_md.gtpAction = GtpAction.decap;
    }

    action fwd_encap_ipv4(bit<128> dstAddr, bit<32> teid) {
        eg_md.teid = teid;
        eg_md.protoEncap = 0;
        eg_md.dstAddr = dstAddr;
        eg_md.gtpAction = GtpAction.encap;
    }

    action fwd_gtp_ipv4(bit<128> dstAddr, bit<32> teid) {
        eg_md.teid = teid;
        eg_md.protoEncap = 0;
        eg_md.dstAddr = dstAddr;
        eg_md.gtpAction = GtpAction.forward;
    }

    action fwd_encap_ipv6(bit<128> dstAddr, bit<32> teid) {
        eg_md.teid = teid;
        eg_md.protoEncap = 1;
        eg_md.dstAddr = dstAddr;
        eg_md.gtpAction = GtpAction.encap;
    }

    action fwd_gtp_ipv6(bit<128> dstAddr, bit<32> teid) {
        eg_md.teid = teid;
        eg_md.protoEncap = 1;
        eg_md.dstAddr = dstAddr;
        eg_md.gtpAction = GtpAction.forward;
    }

    action rewrite_inner_dst_ipv6(bit<128> dstAddr) {
        eg_md.protoEncap = 1;
        eg_md.dstAddr = dstAddr;
        eg_md.inner_dst_rewrite = 0x1;
        eg_md.gtpAction = GtpAction.decap;
    }

    action rewrite_inner_dst_ipv4(bit<128> dstAddr) {
        eg_md.protoEncap = 0;
        eg_md.dstAddr = dstAddr;
        eg_md.inner_dst_rewrite = 0x1;
        eg_md.gtpAction = GtpAction.decap;
    }


    table actionId_table {
        key = {
            hdr.bridged_md.flowId : exact;
        }
        actions = {
            fwd_decap;
            fwd_encap_ipv4;
            fwd_gtp_ipv4;
            fwd_encap_ipv6;
            fwd_gtp_ipv6;
            rewrite_inner_dst_ipv4;
            rewrite_inner_dst_ipv6;
            drop;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt ;
    }

    apply {
        actionId_table.apply();
    }

}
# 20 "upf/p4src/pipe2/UPFEgress4_2.p4" 2







//=============================================================================
// Parser 4_2 (uplink)
//=============================================================================

parser UPFEgress4_2Parser(
            packet_in pkt,
            out headers hdr,
    out upf_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        /* Initialize metadata for no warnings */
        eg_md.pkt_length = 0;
        eg_md.dstAddr = 0;
        eg_md.srcAddrv4 = 0;
        eg_md.srcAddrv6 = 0;

        pkt.extract(eg_intr_md);
        transition parse_ethernet;
     }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
    *  Ethernet parsing.
    */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_bridged_metadata;
    }

    /*
    *  VLAN parsing.
    */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
    *  IPv4 parsing.
    */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_outer_ipv6;
        }
    }

    /*
    *  IPv6 parsing.
    */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_outer_ipv4;
        }
    }

    /*
    * Parse outer TCP (downlink).
    * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
    */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition select(hdr.outer_tcp.urgentPtr) {
            16w0x0000 &&& 16w0x0000 : accept;
            /* Never taken */
            16w0xFFFF &&& 16w0xFFFF : parse_gtp_u;
        }
    }

    /*
    *  Outer UDP parsing.
    */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }


    /*
    *  GTP_U parsing.
    */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,0xFF) : parse_inner_ip;
            default : accept;
        }
    }


    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType) {
            0xFF : parse_inner_ip;
            default : accept;
        }
    }

    state parse_inner_ip {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
         pkt.extract(hdr.inner_ipv4);
         transition select(hdr.inner_ipv4.protocol) {
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
         transition select(hdr.inner_ipv6.nextHdr) {
            default : accept;
        }
    }
}

//=============================================================================
// Egress 2_1 control (uplink)
//=============================================================================

control UPFEgress_Uplink_4_2(
        inout headers hdr,
    inout upf_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    EgressPortTable() port_table;
    ActionIdTable(212000) actionId_table;
    GTP() gtp;

    /* Uplink flowId counters */
    @pragma user_annotation "linked_counter:encap_cntr_uplink_egress,16,2,0"
    Counter<bit<32>, ul_flow_id_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) ul_encap_cntr0;
    @pragma user_annotation "linked_counter:encap_cntr_uplink_egress,16,2,1"
    Counter<bit<32>, ul_flow_id_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) ul_encap_cntr1;
    @pragma user_annotation "linked_counter:encap_cntr_uplink_egress,16,2,2"
    Counter<bit<32>, ul_flow_id_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) ul_encap_cntr2;
    @pragma user_annotation "linked_counter:encap_cntr_uplink_egress,16,2,3"
    Counter<bit<32>, ul_flow_id_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) ul_encap_cntr3;

    Counter<bit<32>, port_stats_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) iid_cntr;
    Counter<bit<32>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) port_cntr;

    action del_bridged_md() {
        hdr.bridged_md.setInvalid();
    }

    action transfer_flowid(){
        eg_md.flowId = hdr.bridged_md.flowId;
    }

    apply {
        iid_cntr.count(hdr.bridged_md.iid);
        port_cntr.count(eg_intr_md.egress_port);
        transfer_flowid();
        actionId_table.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        port_table.apply(hdr, eg_intr_md, eg_md);
        gtp.apply(hdr, eg_md);
        if (eg_md.flowId[17:16] == 0) {
            ul_encap_cntr0.count(eg_md.flowId[15:0]);
        } else if (eg_md.flowId[17:16] == 1) {
            ul_encap_cntr1.count(eg_md.flowId[15:0]);
        } else if (eg_md.flowId[17:16] == 2) {
            ul_encap_cntr2.count(eg_md.flowId[15:0]);
        } else {
            ul_encap_cntr3.count(eg_md.flowId[15:0]);
        }
        del_bridged_md();
    }
}

//=============================================================================
// Deparser 4_2 (uplink)
//=============================================================================

control UPFEgress4_2Deparser(
            packet_out pkt,
            inout headers hdr,
            in upf_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() outer_ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        hdr.outer_ipv4.hdrChecksum = outer_ipv4_checksum.update({
                hdr.outer_ipv4.version,
                hdr.outer_ipv4.ihl,
                hdr.outer_ipv4.diffserv,
                hdr.outer_ipv4.totalLen,
                hdr.outer_ipv4.identification,
                hdr.outer_ipv4.flags,
                hdr.outer_ipv4.fragOffset,
                hdr.outer_ipv4.ttl,
                hdr.outer_ipv4.protocol,
                hdr.outer_ipv4.srcAddr,
                hdr.outer_ipv4.dstAddr
        });

        hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr
        });

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}
# 23 "upf/p4src/pipe2/upf_2.p4" 2

Pipeline(UPFIngress5_2Parser(),
  UPFIngress_Downlink_5_2(),
  UPFIngress5_2Deparser(),
  UPFEgress4_2Parser(),
  UPFEgress_Uplink_4_2(),
  UPFEgress4_2Deparser()) pipe;

Switch(pipe) main;
