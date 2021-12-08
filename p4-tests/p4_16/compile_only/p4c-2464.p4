# 1 "eagle.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "eagle.p4"
/*!
 * @file patch_panel.p4
 * @brief  main functions for Eagle switch.
 * @author 
 * @date 
 */




# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 2
# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tofino.p4" 2

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<5> QueueId_t; // Queue id
typedef bit<10> MirrorId_t; // Mirror id
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w64;

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_TCAM = 16w0x0001;
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

    bit<9> ingress_port; // Ingress physical port id.

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

    bit<5> qid; // Egress (logical) queue id into which
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

    bit<3> mirror_type; // The user-selected mirror field list
                                        // index.
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

    bit<5> egress_qid; // Egress (physical) queue id via which
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

    bit<3> mirror_type;

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
    bit<9> port_num; // Port number

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
    void count(in I index);
}

/// DirectCounter
extern DirectCounter<W> {
    DirectCounter(CounterType_t type);
    void count();
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
    bit<8> execute(in I index, in MeterColor_t color);
    bit<8> execute(in I index);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
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
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, int<6> scale,
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, bit<64> factor); // configure as factor * op(x)
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
    Mirror();

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
    Resubmit();

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type.
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
# 24 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 2

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

@pkginfo(arch="TNA", version="1.0.1")
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
# 12 "eagle.p4" 2


# 1 "headers.p4" 1
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






typedef bit<14> stats_index_t;

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_VLAN_INNER = 16w0x9100;
const ether_type_t ETHERTYPE_SVLAN = 16w0x88a8;
const ether_type_t ETHERTYPE_MPLS_UNICAST = 16w0x8847;
const ether_type_t ETHERTYPE_MPLS_MULTICAST = 16w0x8848;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
typedef bit<16> udp_port_type_t;
const udp_port_type_t PORT_GTP = 3386;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}


header snap_h {
    bit<8> dsap;
    bit<8> ssap;
    bit<8> snap_control;
    bit<24> oui;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<4> pcp_cfi; //pcp = (3:1) cfi = 0
    bit<4> vlan_top;
    bit<8> vlan_bot;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_n_h {
    bit<8> label_top;
    bit<4> label_bot;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
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

header ip46_h {
   bit<4> version;
   bit<4> reserved;
}

header ipv6_h {
    bit<4> traffic_class;
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

header gtp_h {
    bit<3> version;
    bit<1> protocol_type;
    bit<1> reserved;
    bit<1> ext_flag;
    bit<1> seq_num_flag;
    bit<1> n_pdu_flag;
    bit<8> message_type;
    bit<16> message_length;
    bit<32> teid;
    bit<16> sequence_number;
    bit<8> n_pdu;
    bit<8> next_extension;
}

header gre_h {
    bit<1> checksum_flag;
    bit<12> reserved;
    bit<3> ver;
    bit<16> protocol_type;
}

header grechecksum_h {
    bit<16> checksum;
    bit<16> reserved;
}

header ospf_h {
    bit<8> version;
    bit<8> type;
    bit<16> pkt_length;
    bit<64> dont_care;
    bit<16> checksum;
    bit<16> autype;
    bit<64> authentication;
}

header igmp_v2_h {
    bit<8> type;
    bit<8> max_rsp;
    bit<16> checksum;
    bit<32> group_address;
}

header igmp_v3_extra_h {
    bit<16> dont_care;
    bit<16> num_sources;
}

header l23signature_h {
    bit<32> signature_top;
    bit<32> signature_bot;
    bit<32> rx_timestamp;
    bit<32> pgid;
    bit<32> sequence;
    bit<32> txtstamp;
}

/*
 * Ingress metadata, not used but required to use tna.p4
 */
@flexible
header example_bridge_h {
   bit<1> l47_timestamp_insert;
   bit<1> l23_txtstmp_insert;
   bit<1> l23_rxtstmp_insert;
   bit<32> ingress_mac_timestamp;
}

struct port_metadata_t {
    //temporary since we have only 64-bits port metadata for tofino1
    // will be 192 bits in T2
    bit<32> port_signature_top;
    //bit<28> port_signature_bot;
    bit<4> port_type;
}

struct ingress_metadata_t {
    port_metadata_t port_properties;
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> tx_timestamp;
    bit<8> l47_ob_egressport;
    bit<16> l47_ob_ethertype;
    example_bridge_h bridge;
}

/*
 * Egress metadata, 
 */
struct egress_metadata_t {
    example_bridge_h bridge;
    bit<16> udp_checksum_tmp;
    bit<16> tcp_checksum_tmp;
    bit<16> gre_checksum_tmp;
    bit<16> inner_tcp_checksum_tmp;
    bit<16> inner_udp_checksum_tmp;
    bit<32> timestamp_delta;
    bool checksum_insert_udp;
    bool checksum_insert_tcp;
    bool checksum_insert_gre;
    bool checksum_insert_inner_udp;
    bool checksum_insert_inner_tcp;
}

struct header_t {
    ethernet_h ethernet;
    snap_h snap;
    vlan_tag_h vlan_tag_0;
    vlan_tag_h vlan_tag_1;
    vlan_tag_h vlan_tag_2;
    mpls_h mpls_0;
    ip46_h ip_version_0;
    mpls_n_h mpls_1;
    ip46_h ip_version_1;
    mpls_n_h mpls_2;
    ip46_h ip_version_2;
    mpls_n_h mpls_3;
    ip46_h ip_version_3;
    mpls_n_h mpls_4;
    ip46_h ip_version_4;
    mpls_n_h mpls_5;
    ip46_h ip_version_5;
    mpls_n_h mpls_6;
    ip46_h ip_version_6;
    ipv4_h ipv4;
    ipv6_h ipv6;
    gre_h gre;
    grechecksum_h gre_checksum;
    ospf_h ospf;
    igmp_v2_h igmp;
    igmp_v3_extra_h igmpv3;
    icmp_h icmp;
    tcp_h tcp;
    udp_h udp;
    gtp_h gtp;
    ip46_h inner_ip_version;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
    l23signature_h first_payload;
    // Add more headers here.
}

parser SimplePacketParser(packet_in pkt, inout header_t hdr) {
    state start { // parse Ethernet
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}
# 15 "eagle.p4" 2
# 1 "packet_parser_ingress.p4" 1
/*!
 * @file packet_parser_ingress.p4
 * @brief  main functions for Eagle switch.
 * @author 
 * @date 
 */




# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 12 "packet_parser_ingress.p4" 2


# 1 "headers.p4" 1
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
# 15 "packet_parser_ingress.p4" 2

parser PacketParserIngress(packet_in pkt,
                    out header_t hdr,
                    out ingress_metadata_t meta,
                    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
      pkt.extract(ig_intr_md);
      meta.port_properties =
        port_metadata_unpack<port_metadata_t>(pkt);
      meta.src_port = 0;
      meta.dst_port = 0;
      meta.tx_timestamp = 0;
      meta.l47_ob_egressport = 0;
      meta.l47_ob_ethertype = 0;
      meta.bridge.l47_timestamp_insert = 0;
      meta.bridge.l23_txtstmp_insert = 0;
      meta.bridge.l23_rxtstmp_insert = 0;
      transition parseEthernet;
    }

    state parseEthernet {
      pkt.extract(hdr.ethernet);
      transition select(hdr.ethernet.ether_type) {
        0 &&& 0xf800: parseSnapHeader; /* < 1536 */
        ETHERTYPE_VLAN: parseVlan;
        ETHERTYPE_SVLAN: parseVlan;
        ETHERTYPE_MPLS_UNICAST: parseMpls;
        ETHERTYPE_MPLS_MULTICAST: parseMpls;
        ETHERTYPE_IPV4: parseIpv4;
        ETHERTYPE_IPV6: parseIpv6;
        default: parseL23;
      }
    }

    state parseSnapHeader {
      pkt.extract(hdr.snap);
      transition select(hdr.snap.ether_type) {
          ETHERTYPE_MPLS_UNICAST: parseMpls;
          ETHERTYPE_MPLS_MULTICAST: parseMpls;
          ETHERTYPE_IPV4: parseIpv4;
          ETHERTYPE_IPV6: parseIpv6;
          default: parseL23;
      }
    }

    state parseVlan {
      pkt.extract(hdr.vlan_tag_0);
      transition select(hdr.vlan_tag_0.ether_type) {
          0 &&& 0xf800: parseSnapHeader; /* < 1536 */
          ETHERTYPE_VLAN_INNER: parseVlan1;
          ETHERTYPE_VLAN: parseVlan1;
          ETHERTYPE_SVLAN: parseVlan1;
          ETHERTYPE_MPLS_UNICAST: parseMpls;
          ETHERTYPE_MPLS_MULTICAST: parseMpls;
          ETHERTYPE_IPV4: parseIpv4;
          ETHERTYPE_IPV6: parseIpv6;
          default: parseL23;
      }
    }

    state parseVlan1 {
      pkt.extract(hdr.vlan_tag_1);
      transition select(hdr.vlan_tag_1.ether_type) {
          0 &&& 0xf800: parseSnapHeader; /* < 1536 */
          ETHERTYPE_VLAN_INNER: parseVlan2;
          ETHERTYPE_VLAN: parseVlan2;
          ETHERTYPE_SVLAN: parseVlan2;
          ETHERTYPE_MPLS_UNICAST: parseMpls;
          ETHERTYPE_MPLS_MULTICAST: parseMpls;
          ETHERTYPE_IPV4: parseIpv4;
          ETHERTYPE_IPV6: parseIpv6;
          default: parseL23;
      }
    }
    //last vlan, accept anything that is not decoded 
    state parseVlan2 {
      pkt.extract(hdr.vlan_tag_2);
      transition select(hdr.vlan_tag_2.ether_type) {
          0 &&& 0xf800: parseSnapHeader; /* < 1536 */
          ETHERTYPE_MPLS_UNICAST: parseMpls;
          ETHERTYPE_MPLS_MULTICAST: parseMpls;
          ETHERTYPE_IPV4: parseIpv4;
          ETHERTYPE_IPV6: parseIpv6;
          default: parseL23;
      }
    }

    state parseMpls {
      pkt.extract(hdr.mpls_0);
      pkt.extract(hdr.ip_version_0);
      meta.l47_ob_egressport = hdr.mpls_0.ttl;
      meta.l47_ob_ethertype = hdr.mpls_0.label[19:4];
      meta.bridge.l47_timestamp_insert = hdr.mpls_0.exp[0:0];
      transition select(hdr.mpls_0.bos, hdr.ip_version_0.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls1;
          default: parseL23;
      }
    }

    state parseMpls1 {
      pkt.extract(hdr.mpls_1);
      pkt.extract(hdr.ip_version_1);
      transition select(hdr.mpls_1.bos, hdr.ip_version_1.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls2;
          default: parseL23;
      }
    }

    state parseMpls2 {
      pkt.extract(hdr.mpls_2);
      pkt.extract(hdr.ip_version_2);
      transition select(hdr.mpls_2.bos, hdr.ip_version_2.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls3;
          default: parseL23;
      }
    }

    state parseMpls3 {
      pkt.extract(hdr.mpls_3);
      pkt.extract(hdr.ip_version_3);
      transition select(hdr.mpls_3.bos, hdr.ip_version_3.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls4;
        default: parseL23;
      }
    }

    state parseMpls4 {
      pkt.extract(hdr.mpls_4);
      pkt.extract(hdr.ip_version_4);
      transition select(hdr.mpls_4.bos, hdr.ip_version_4.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls5;
        default: parseL23;
      }
    }

    state parseMpls5 {
      pkt.extract(hdr.mpls_5);
      pkt.extract(hdr.ip_version_5);
      transition select(hdr.mpls_5.bos, hdr.ip_version_5.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls6;
          default: parseL23;
      }
    }

    state parseMpls6 {
      pkt.extract(hdr.mpls_6);
      pkt.extract(hdr.ip_version_6);
      transition select(hdr.mpls_6.bos, hdr.ip_version_6.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          default: parseL23;
      }
    }

    state parseMplsIpv4 {
      pkt.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseMplsIpv6 {
      pkt.extract(hdr.ipv6);
      transition select(hdr.ipv6.next_hdr) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
         default: parseL23;
      }
    }

    state parseIpv4 {
      pkt.extract(hdr.ip_version_6);
      pkt.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseIpv6 {
      pkt.extract(hdr.ip_version_6);
      pkt.extract(hdr.ipv6);
      transition select(hdr.ipv6.next_hdr) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      meta.src_port = hdr.tcp.src_port;
      meta.dst_port = hdr.tcp.dst_port;
      meta.tx_timestamp = hdr.first_payload.signature_bot;
      transition accept;
    }

    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      meta.src_port = hdr.udp.src_port;
      meta.dst_port = hdr.udp.dst_port;
      meta.tx_timestamp = hdr.first_payload.signature_top;
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
      transition accept;
    }
}
# 16 "eagle.p4" 2
# 1 "packet_parser_egress.p4" 1
/*!
 * @file packet_parser_egress.p4
 * @brief  main functions for Eagle switch.
 * @author 
 * @date 
 */




# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 12 "packet_parser_egress.p4" 2


# 1 "headers.p4" 1
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
# 15 "packet_parser_egress.p4" 2

parser PacketParserEgress(packet_in pkt,
                    inout header_t hdr, inout egress_metadata_t eg_md ) {

    Checksum() gre_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    Checksum() inner_udp_checksum;
    Checksum() inner_tcp_checksum;

    state start {
        transition parseEthernet;
    }

    state parseEthernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN: parseVlan;
            ETHERTYPE_SVLAN: parseVlan;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: accept;
        }
    }

    state parseSnapHeader {
        pkt.extract(hdr.snap);
        transition select(hdr.snap.ether_type) {
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: accept;
        }
    }

    state parseVlan {
        pkt.extract(hdr.vlan_tag_0);
        transition select(hdr.vlan_tag_0.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN &&& 0xefff: parseVlan1;
            ETHERTYPE_SVLAN: parseVlan1;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: accept;
        }
    }

    state parseVlan1 {
        pkt.extract(hdr.vlan_tag_1);
        transition select(hdr.vlan_tag_1.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN &&& 0xefff: parseVlan2;
            ETHERTYPE_SVLAN: parseVlan2;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: accept;
        }
    }
    //last vlan, accept anything that is not decoded 
    state parseVlan2 {
        pkt.extract(hdr.vlan_tag_2);
        transition select(hdr.vlan_tag_2.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: accept;
        }
    }

    state parseMpls {
        pkt.extract(hdr.mpls_0);
        pkt.extract(hdr.ip_version_0);
        transition select(hdr.mpls_0.bos, hdr.ip_version_0.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls1;
           default: accept;
        }
    }

    state parseMpls1 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.ip_version_1);
        transition select(hdr.mpls_1.bos, hdr.ip_version_1.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls2;
           default: accept;
        }
    }

    state parseMpls2 {
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.ip_version_2);
        transition select(hdr.mpls_2.bos, hdr.ip_version_2.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls3;
           default: accept;
        }
    }

    state parseMpls3 {
        pkt.extract(hdr.mpls_3);
        pkt.extract(hdr.ip_version_3);
        transition select(hdr.mpls_3.bos, hdr.ip_version_3.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls4;
           default: accept;
        }
    }

    state parseMpls4 {
        pkt.extract(hdr.mpls_4);
        pkt.extract(hdr.ip_version_4);
        transition select(hdr.mpls_4.bos, hdr.ip_version_4.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls5;
           default: accept;
        }
    }

    state parseMpls5 {
        pkt.extract(hdr.mpls_5);
        pkt.extract(hdr.ip_version_5);
        transition select(hdr.mpls_5.bos, hdr.ip_version_5.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           (1w0x0, 4w0x0 &&& 4w0x0): parseMpls6;
           default: accept;
        }
    }

     state parseMpls6 {
        pkt.extract(hdr.mpls_6);
        pkt.extract(hdr.ip_version_6);
        transition select(hdr.mpls_6.bos, hdr.ip_version_6.version) {
           (1w0x1, 4w0x4): parseMplsIpv4;
           (1w0x1, 4w0x6): parseMplsIpv6;
           default: accept;
        }
    }

    state parseMplsIpv4 {
      pkt.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseMplsIpv6 {
      pkt.extract(hdr.ipv6);
      transition select(hdr.ipv6.next_hdr) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseIpv4 {
      pkt.extract(hdr.ip_version_6);
      pkt.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseIpv6 {
      pkt.extract(hdr.ip_version_6);
      pkt.extract(hdr.ipv6);
      transition select(hdr.ipv6.next_hdr) {
        IP_PROTOCOLS_TCP: parseTcp;
        IP_PROTOCOLS_UDP: parseUdp;
        default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      tcp_checksum.subtract({hdr.tcp.checksum});
      tcp_checksum.subtract({hdr.first_payload});
      tcp_checksum.subtract_all_and_deposit(eg_md.tcp_checksum_tmp);
      transition accept;
    }


    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      udp_checksum.subtract({hdr.udp.checksum});
      udp_checksum.subtract({hdr.first_payload});
      udp_checksum.subtract_all_and_deposit(eg_md.udp_checksum_tmp);
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
      transition accept;
    }
}
# 17 "eagle.p4" 2
# 1 "hash_generator.p4" 1
/*!
 * @file hash_generator.p4
 * @brief Generate hash calculation based on destination/src ip and destination/src ports
 */



# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 9 "hash_generator.p4" 2

# 1 "headers.p4" 1
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
# 11 "hash_generator.p4" 2

control calculate_hash(inout header_t hdr,
    inout ingress_metadata_t meta,
    out bit<8> hashRes) {
    /******************************/
  Hash<bit<32>>(HashAlgorithm_t.CRC32) coreSelHash; // CRC32 hash algorithm with default polynomial 
  //Hash<bit<8>>(HashAlgorithm_t.IDENTITY) truncate_hash;
  bit<32> srcDig; // smaller of the hash fields extracted from IPv4/6 src or dst addresses
  bit<32> srcDigPart0; // condensed upper half of IPv6 src address
  bit<32> srcDigPart1; // condensed lower half of IPv6 src address
  bit<32> dstDig; // bigger of the hash fields extracted from IPv4/6 src or dst addresses
  bit<32> dstDigPart0; // condensed upper half of IPv6 dst address
  bit<32> dstDigPart1; // condensed lower half of IPv6 dst address
  bit<32> diffDig; // srcDig - dstDig
  bit<16> srcPort; // src_port of UDP/TCP header when srcDig is IP SA, dst_port if srcDig is IP DA
  bit<16> dstPort; // src_port of UDP/TCP header when dstDig is IP SA, dst_port if dstDig is IP DA
  bit<16> diffPort; // difference between srcPort and dstPort, use in case srcDig == dstDig
  bit<32> loDig;
  bit<32> hiDig;
  bit<16> loPort;
  bit<16> hiPort;
  bit<1> swap = 0;
  bit<32> final_hash;

  /******************************
   * Crunches IPv6 src and dst addresses into 2 32-bit halves each using XOR
   * @param none
   * @return none
   */
  action crunchIpv6Addr() {
    srcDigPart0 = hdr.ipv6.src_addr[127:96] ^ hdr.ipv6.src_addr[95:64];
    srcDigPart1 = hdr.ipv6.src_addr[63:32] ^ hdr.ipv6.src_addr[31:0];
    dstDigPart0 = hdr.ipv6.dst_addr[127:96] ^ hdr.ipv6.dst_addr[95:64];
    dstDigPart1 = hdr.ipv6.dst_addr[63:32] ^ hdr.ipv6.dst_addr[31:0];
  }

  /**
   * Crunches the compressed IPv6 address halves into a single 32-bit number
   * @param none
   * @return none
   */
  action calcDiffPort()
  {
    diffPort = meta.src_port - meta.dst_port;
  }

  action maptov6() {
    srcDig = (srcDigPart0 ^ srcDigPart1) ;
    dstDig = (dstDigPart0 ^ dstDigPart1) ;
  }

  action maptov4() {
    srcDig = hdr.ipv4.src_addr & 0x7fffffff;
    dstDig = hdr.ipv4.dst_addr & 0x7fffffff;
  }

  action maptoZero() {
    srcDig = 0;
    dstDig = 0;
  }

  action stealAbit() {
    srcDig = srcDig & 0x7fffffff;
    dstDig = dstDig & 0x7fffffff;
    meta.src_port = meta.src_port & 0x7fff;
    meta.dst_port= meta.dst_port & 0x7fff;
  }

  /**
   * Calculates the differences between the 32-bit hash fields
   * @param none
   * @return none
   */
  action noSwapOrder() {
    loPort = meta.src_port;
    hiPort = meta.dst_port;
    loDig = srcDig;
    hiDig = dstDig;
  }

  action swapOrder() {
    loPort = meta.dst_port;
    hiPort = meta.src_port;
    loDig = dstDig;
    hiDig = srcDig;
  }

  action calcDiffDig() {
    diffDig = srcDig - dstDig;
    calcDiffPort();
  }

  /******************************/
  apply
  {
    /*if (hdr.ipv6.isValid()) 
    {
      crunchIpv6Addr();
      maptov6();
    }
    else*/ if (hdr.ipv4.isValid())
    {
      maptov4();
    }
    else
      maptoZero();
    stealAbit();
    //Calculate the difference of the hash fields
    calcDiffDig();
    if ( diffDig == 0 )
    {
      if (diffPort & 0x8000 == 0)
      {
        swapOrder();
      }
      else
      {
        noSwapOrder();
      }
    }
    else if (diffDig & 0x80000000 == 0)
    {
      swapOrder();
    }
    else
    {
      noSwapOrder();
    }

    /*if (swap == 0)
      noSwapOrder();
    else 
      swapOrder();*/

    final_hash = coreSelHash.get({hiDig, loDig, hiPort, loPort});
    hashRes = final_hash[7:0];
  }
}
# 18 "eagle.p4" 2
# 1 "outbound_l47.p4" 1
/*!
 * @file outbound_l47.p4
 * @brief Remove MPLS (overhead) labels and sends the packet out
 */



# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 9 "outbound_l47.p4" 2

# 1 "headers.p4" 1
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
# 11 "outbound_l47.p4" 2

control outbound_l47(inout header_t hdr,
  inout ingress_metadata_t meta ) {

  bit<16> ethertype;
  /******************************/

  action popMpls()
  {
    hdr.mpls_0.setInvalid();
    hdr.ip_version_0.setInvalid();
    hdr.mpls_1.setInvalid();
    meta.bridge.setValid();
  }

  action assignEthertype() {
    hdr.ethernet.ether_type = meta.l47_ob_ethertype;
    popMpls();
  }

  action assignVlanEthertype() {
    hdr.vlan_tag_0.ether_type = meta.l47_ob_ethertype;
    popMpls();
  }

  action assignQinQEthertype() {
    hdr.vlan_tag_1.ether_type = meta.l47_ob_ethertype;
    popMpls();
   }


  /******************************/
  apply
  {
    //assume it will always have 2 MPLS 
    // this is only applied on pkts 
    // from L47 compute node traffic
    if (hdr.vlan_tag_1.isValid())
    {
      assignQinQEthertype();
    }
    else if (hdr.vlan_tag_0.isValid())
    {
      assignVlanEthertype();
    }
    else
    {
      assignEthertype();
    }
  }
}

control outbound_l47_insert_timestamp(inout header_t hdr,
  inout egress_metadata_t eg_md,
  in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr) {

  action insert_udp_timestamp() {
    hdr.first_payload.signature_top = eg_intr_from_prsr.global_tstamp[31:0];
    eg_md.checksum_insert_udp = true;
  }

  action insert_tcp_timestamp() {
    hdr.first_payload.signature_bot = eg_intr_from_prsr.global_tstamp[31:0];
    eg_md.checksum_insert_tcp = true;
  }

  action set_udp_changed() {
    eg_md.checksum_insert_udp = true;
  }

  action set_tcp_changed() {
    eg_md.checksum_insert_tcp = true;
  }

  /*****************************************/
  apply
  {
    //insert_compute_node_timestampTbl.apply();
    if ( hdr.inner_tcp.isValid())
    {
      insert_tcp_timestamp();
    }
    else if ( hdr.inner_udp.isValid())
    {
      insert_udp_timestamp();
    }
    else if ( hdr.tcp.isValid())
    {
      insert_tcp_timestamp();
      set_tcp_changed();
    }
    else if (hdr.udp.isValid())
    {
      insert_udp_timestamp();
      set_udp_changed();
    }
  }
}
# 19 "eagle.p4" 2
# 1 "inbound_l47.p4" 1
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */



# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 9 "inbound_l47.p4" 2

# 1 "headers.p4" 1
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
# 11 "inbound_l47.p4" 2


control inbound_l47_gen_lookup(inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        out bit<8> lookup_queue_offset,
        out bit<8> lookup_queue_range,
        out bit<8> lookup_queue_max,
        out bit<1> l47_match,
        out bit<1> timestamp_calc,
        out stats_index_t stat_index) {

  const bit<32> table_sz = 512;
  bit<4> vid_top = 0;
  bit<8> vid_bot = 0;
  stats_index_t index = 0;
  Counter<bit<64>, stats_index_t> (1<<14, CounterType_t.PACKETS_AND_BYTES) flow_stats;
 /**********************************/

  action setCnPort(PortId_t egPort,
    bit<8> queue_range,
    bit<8> queue_offset,
    bit<8> queue_max_range,
    bit<1> timestamp_ext,
    stats_index_t stats_index )
  {
    ig_intr_tm_md.ucast_egress_port = egPort;
    lookup_queue_range = queue_range;
    lookup_queue_offset = queue_offset;
    lookup_queue_max = queue_max_range;
    l47_match = 1;
    timestamp_calc = timestamp_ext;
    index = stats_index;
  }

  action setQueue()
  {
    lookup_queue_range = 0;
    lookup_queue_offset = 0;
    lookup_queue_max = 0;
    l47_match = 0;
    timestamp_calc = 0;
    index = 0;
  }

  table EgressCnTbl {
    key = {
      vid_top: exact;
      vid_bot: exact;
      hdr.ipv4.dst_addr : lpm;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setCnPort;
      setQueue;
    }
    default_action = setQueue;
    size = table_sz;
  }

  table EgressCnv6Tbl {
    key = {
      vid_top: exact;
      vid_bot: exact;
      hdr.ipv6.dst_addr : lpm;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setCnPort;
      setQueue;
    }
    default_action = setQueue;
    size = table_sz;
  }

  /******************************/
  apply
  {
    if (hdr.vlan_tag_0.isValid())
    {
      vid_top = hdr.vlan_tag_0.vlan_top;
      vid_bot = hdr.vlan_tag_0.vlan_bot;
    }
    else
    {
      vid_top = 0;
      vid_bot = 0;
    }

    if (hdr.ipv4.isValid())
    {
      EgressCnTbl.apply();
    }
    else if (hdr.ipv6.isValid())
    {
      EgressCnv6Tbl.apply();
    }
    if (l47_match == 1)
      flow_stats.count(index);
  }
}

control inbound_l47_insert_vlan(inout header_t hdr,
in bit<5> ingress_port, in bit<8> queue_no) {
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.vlan_top = ingress_port[4:1];
    hdr.vlan_tag_0.vlan_bot[7:7] = ingress_port[0:0];
    hdr.vlan_tag_0.vlan_bot[6:0]= queue_no[6:0];
  }

  action insertVlan() {
    bit<16> ethertype = hdr.ethernet.ether_type;
    hdr.vlan_tag_0.ether_type = ethertype;
    insertVlanOverhead();
  }

  action insertVlan_1() {
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
    bit<16> ethertype = hdr.ethernet.ether_type;
    hdr.vlan_tag_0.ether_type = ethertype;
    insertVlanOverhead();
  }

  action insertVlan_2() {
    hdr.vlan_tag_2 = hdr.vlan_tag_1;
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
    bit<16> ethertype = hdr.ethernet.ether_type;
    hdr.vlan_tag_0.ether_type = ethertype;
    insertVlanOverhead();
  }

  /******************************/
  apply
  {
    if (hdr.vlan_tag_1.isValid())
    {
      insertVlan_2();
    }
    else if (hdr.vlan_tag_0.isValid())
    {
      insertVlan_1();
    }
    else
    {
      insertVlan();
    }
  }
}

control inbound_l47_calc_latency( inout header_t hdr,
                                  in ingress_intrinsic_metadata_t ig_intr_md,
                                  in bit<32> rx_tstamp,
                                  out bit<32> latency) {

  action calc_udp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_top;
  }

  action calc_tcp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_bot;
  }

  /*****************************************/
  apply
  {
    if (hdr.inner_tcp.isValid())
    {
      calc_tcp_timestamp();
    }
    else if (hdr.inner_udp.isValid())
    {
      calc_udp_timestamp();
    }
    else if (hdr.tcp.isValid())
    {
      calc_tcp_timestamp();
    }
    else if (hdr.udp.isValid())
    {
      calc_udp_timestamp();
    }
  }
}
# 20 "eagle.p4" 2
# 1 "timestamp.p4" 1
/*!
 * @file timestamp.p4
 * @brief insert timestamp for L23
 */



# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 9 "timestamp.p4" 2

# 1 "headers.p4" 1
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
# 11 "timestamp.p4" 2

control timestamp_insertion(inout header_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr ) {

    action insert_rx_timestamp() {
      hdr.first_payload.rx_timestamp = eg_md.bridge.ingress_mac_timestamp;
    }

    action insert_tx_timestamp() {
      hdr.first_payload.txtstamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    action set_udp_changed() {
      eg_md.checksum_insert_udp = true;
    }

    action set_tcp_changed() {
      eg_md.checksum_insert_tcp = true;
    }

  /***************************************************/
  apply
  {
    if(eg_md.bridge.l23_txtstmp_insert == 1)
    {
        insert_tx_timestamp();
        if (hdr.tcp.isValid())
            set_tcp_changed();
        else if (hdr.udp.isValid())
            set_udp_changed();
    }
    else if (eg_md.bridge.l23_rxtstmp_insert == 1)
        insert_rx_timestamp();
        if (hdr.tcp.isValid())
            set_tcp_changed();
        else if (hdr.udp.isValid())
            set_udp_changed();
  }
}
# 21 "eagle.p4" 2
# 1 "latency_stat.p4" 1
/*!
 * @file latency_stat.p4
 * @brief latency_statistic calculation
 */



# 1 "/home/vgurevich/bf-sde-9.1.0.11-pr/install/share/p4c/p4include/tna.p4" 1
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
# 9 "latency_stat.p4" 2

# 1 "headers.p4" 1
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
# 11 "latency_stat.p4" 2

control latency_stat(inout header_t hdr,
                            in stats_index_t stat_index,
                            in bit<32> latency )(bit<32> num_stats) {
   Register<bit<32>, stats_index_t>(num_stats) data_storage;

   RegisterAction<bit<32>, stats_index_t, bit<32>>(data_storage)
   write_data = {
       void apply(inout bit<32> register_data, out bit<32> result) {
           result = register_data;
           register_data = register_data + latency;
       }
   };


  /***************************************************/
  apply
  {
    write_data.execute(stat_index);
  }
}
# 22 "eagle.p4" 2

/**
 * Ingress parser
 * @param in pkt input packet
 * @param out hdr header(s) extracted from the packet
 * @param out ig_md ingress metadata
 * @param out ig_intr_md ingress intrinsic metadata
 * @return none
 */
parser SxIngParser(packet_in pkt,
       out header_t hdr,
       out ingress_metadata_t meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParserIngress() pkt_parser;

    state start {
      pkt_parser.apply(pkt, hdr, meta, ig_intr_md);
      transition accept;
    }
}

/**
 * Ingress pipeline: Sets the destination port for incoming packets.
 * @param inout hdr extracted header(s)
 * @param inout ig_md ingress metadata
 * @param in ig_intr_md ingress intrinsic metadata
 * @param in ig_intr_prsr_md ingress intrinsic metadata for parser
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @param out ig_intr_md_for_tm ingress intrinsic metadata for traffic manager
 * @return none
 */
control SxIngPipeline(inout header_t hdr,
         inout ingress_metadata_t meta,
         in ingress_intrinsic_metadata_t ig_intr_md,
         in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
         inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
  /*
   * Ingress per port stat counters
   */
  Counter<bit<32>, PortId_t> (256, CounterType_t.PACKETS_AND_BYTES) igPortStatCnt;

  Hash<bit<8>>(HashAlgorithm_t.IDENTITY) queue_hash;
  Hash<bit<5>>(HashAlgorithm_t.IDENTITY) truncate_ingress_port;
  const bit<32> table_sz = 512;
  bit<1> parser_err = 0;
  bit<32> xor_signature;
  bit<4> engine_id;
  bit<8> sel_hash;
  bit<8> queue_range;
  bit<8> queue_offset;
  bit<8> queue_max;
  bit<1> l47_match;
  bit<1> timestamp_calc;
  bit<8> queue; // (hashRes & queueRange) + baseQueueNo
  bit<8> compare_range = 0;
  bit<8> and_compare_range = 0;
  bit<8> diff_range_mask = 0;
  bit<8> wrap_queue;
  bit<8> final_queue;
  bit<5> l47_inbound_ingress_port;
  bit<32> pkt_latency;
  stats_index_t stat_index;
  latency_stat(1<<14) l47_latency;
  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32;
  /**
   * Sets egress port.
   * @param egPort egress port
   * @return none 
   */
  action setEgPort(PortId_t egPort) {
    ig_intr_tm_md.ucast_egress_port = egPort;
  }

  table L23OutboundTbl {
    key = {
      engine_id: exact;
      ig_intr_md.ingress_port : exact;
      meta.port_properties.port_type: exact;
    }
    actions = {
      setEgPort;
      NoAction;
    }
    default_action = NoAction;
    size = 8;
  }

  action assignEPort() {
    ig_intr_tm_md.ucast_egress_port = (bit<9>)meta.l47_ob_egressport;
  }

  // for port type front panel, try to match 8-byte signature
  action check_signature() {
    xor_signature = meta.port_properties.port_signature_top ^ hdr.first_payload.signature_top;
    meta.bridge.setValid();
  }

  action mark_l23_tx_timestamp_ins() {
    engine_id = hdr.first_payload.signature_bot[3:0];
    meta.bridge.l23_txtstmp_insert = hdr.first_payload.signature_bot[4:4];
  }

  action mark_l23_rx_timestamp_ins() {
    engine_id = hdr.first_payload.signature_bot[3:0];
    meta.bridge.l23_rxtstmp_insert = hdr.first_payload.signature_bot[4:4];
  }

  action calculate_queue() {
    //modulo is not supported
    queue = sel_hash & queue_range;
    diff_range_mask = queue_range - queue_max;
    l47_inbound_ingress_port = truncate_ingress_port.get(ig_intr_md.ingress_port);
  }

  action compare_max_queue() {
    compare_range = queue - queue_max;
  }

  action truncate_rx_tstamp() {
    meta.bridge.ingress_mac_timestamp = identityHash32.get(ig_intr_md.ingress_mac_tstamp);
  }

/***************************************************
  /*
   * main execution body for ingress pipeline
   */
  apply {
    truncate_rx_tstamp();
    //calculate hash based on packet headers
    calculate_hash.apply(hdr, meta, sel_hash);
    //lookup egress port and queue parameters for l47 
    inbound_l47_gen_lookup.apply(hdr, ig_intr_md, ig_intr_tm_md,
      queue_offset, queue_range, queue_max, l47_match, timestamp_calc, stat_index);
    //calculate latency assuming it is l47 payload
    inbound_l47_calc_latency.apply(hdr, ig_intr_md, meta.bridge.ingress_mac_timestamp, pkt_latency);
    //if input port is a l47 port 
    if (meta.port_properties.port_type == 3)
    {
      assignEPort();
      outbound_l47.apply(hdr, meta);
    }
    else
    {
      // match if signature exist in payload 
      check_signature();
      //If L23 type packets
      if (xor_signature == 0)
      {
        if (meta.port_properties.port_type == 1)
        {
          mark_l23_rx_timestamp_ins();
        }
        else
        {
          mark_l23_tx_timestamp_ins();
        }
        L23OutboundTbl.apply();
      }
      else
      {
        calculate_queue();
        compare_max_queue();
        // this means it's th generated queue > maxRange
        // queue = hash - Max, which should guarantee the value is < MaxRange
        if (diff_range_mask == 0 || compare_range == 0)
        {
          wrap_queue = queue;
        }
        else if ((compare_range & 0x80) == 0)
        {
          wrap_queue = compare_range;
        }
        else
        {
          wrap_queue = queue;
        }
        if (l47_match == 1)
        {
          final_queue = queue_offset + wrap_queue;
          inbound_l47_insert_vlan.apply(hdr, l47_inbound_ingress_port, final_queue);
        }
      }
    }
    /*if (timestamp_calc == 1)
    {
      l47_latency.apply(hdr, stat_index, pkt_latency);
    }*/
  }
}

/**
 * Ingress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param in ig_md ingress metadata
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @return none
 */
control SxIngDeparser(packet_out pkt,
          inout header_t hdr,
          in ingress_metadata_t ig_md,
          in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
  apply{
    pkt.emit(ig_md.bridge);
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.vlan_tag_0);
    pkt.emit(hdr.vlan_tag_1);
    pkt.emit(hdr.vlan_tag_2);
    pkt.emit(hdr.mpls_0);
    pkt.emit(hdr.ip_version_0);
    pkt.emit(hdr.mpls_1);
    pkt.emit(hdr.ip_version_1);
    pkt.emit(hdr.mpls_2);
    pkt.emit(hdr.ip_version_2);
    pkt.emit(hdr.mpls_3);
    pkt.emit(hdr.ip_version_3);
    pkt.emit(hdr.mpls_4);
    pkt.emit(hdr.ip_version_4);
    pkt.emit(hdr.mpls_5);
    pkt.emit(hdr.ip_version_5);
    pkt.emit(hdr.mpls_6);
    pkt.emit(hdr.ip_version_6);
    pkt.emit(hdr.ipv4);
    pkt.emit(hdr.ipv6);
    pkt.emit(hdr.tcp);
    pkt.emit(hdr.udp);
    pkt.emit(hdr.first_payload);
  }
}

/**
 * Egress parser
 * @param in pkt input packet
 * @param out hdr header(s) extracted from the packet
 * @param out eg_md egress metadata
 * @param out eg_intr_md egress intrinsic metadata
 * @return none
 */
parser SxEgrParser(packet_in pkt,
       out header_t hdr,
       out egress_metadata_t eg_md,
       out egress_intrinsic_metadata_t eg_intr_md) {

  PacketParserEgress() pkt_parser;

  state start {
    pkt.extract(eg_intr_md); // need to extract egress intrinsic metadata
    pkt.extract(eg_md.bridge);
    pkt_parser.apply(pkt, hdr, eg_md);
    eg_md.checksum_insert_udp = false;
    eg_md.checksum_insert_tcp = false;
    transition accept;
  }
}

/**
 * Egress pipeline
 * @param inout hdr extracted header(s)
 * @param inout eg_md egress metadata
 * @param in eg_intr_md egress intrinsic metadata
 * @param in eg_intr_prsr_md egress intrinsic metadata for parser
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @param out eg_intr_md_for_oport egress intrinsic metadata for output port
 * @return none
 */
control SxEgrPipeline(inout header_t hdr,
          inout egress_metadata_t eg_md,
          in egress_intrinsic_metadata_t eg_intr_md,
          in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
          inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
          inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
  /*
   * main execution body of the egress pipeline
   */



  /*******************************************/
  apply{
    if(eg_md.bridge.l47_timestamp_insert == 1)
      outbound_l47_insert_timestamp.apply(hdr, eg_md, eg_intr_md_from_prsr);
    else
      timestamp_insertion.apply(hdr, eg_md, eg_intr_md_from_prsr);
  }
}

/*
 * Egress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param inout hdr header(s) extracted
 * @param in eg_md egress metadata
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @return none
 */
control SxEgrDeparser(packet_out pkt,
          inout header_t hdr,
          in egress_metadata_t eg_md,
          in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

  Checksum() tcp_checksum;
  Checksum() gre_checksum;
  Checksum() udp_checksum;
  Checksum() inner_udp_checksum;
  Checksum() inner_tcp_checksum;

  apply{
    if (eg_md.checksum_insert_tcp)
    {
      hdr.tcp.checksum = tcp_checksum.update({
        hdr.first_payload,
        eg_md.tcp_checksum_tmp
      });
    }
    if (eg_md.checksum_insert_udp)
    {
      hdr.udp.checksum = udp_checksum.update({
        hdr.first_payload,
        eg_md.udp_checksum_tmp
      });
    }
    /*if (eg_md.checksum_insert_gre)
    {
      hdr.gre_checksum.checksum = gre_checksum.update({
        hdr.first_payload,
        eg_md.timestamp_delta,
        eg_md.gre_checksum_tmp
      });
    }
    if (eg_md.checksum_insert_inner_tcp)
    {
      hdr.inner_tcp.checksum = inner_tcp_checksum.update({
        hdr.first_payload,
        eg_md.timestamp_delta,
        eg_md.inner_tcp_checksum_tmp
      });
    }
    if(eg_md.checksum_insert_inner_udp)
    {
      hdr.inner_udp.checksum = inner_udp_checksum.update({
        hdr.first_payload,
        eg_md.timestamp_delta,
        eg_md.inner_udp_checksum_tmp
      });
    }*/
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.vlan_tag_0);
    pkt.emit(hdr.vlan_tag_1);
    pkt.emit(hdr.vlan_tag_2);
    pkt.emit(hdr.mpls_0);
    pkt.emit(hdr.ip_version_0);
    pkt.emit(hdr.mpls_1);
    pkt.emit(hdr.ip_version_1);
    pkt.emit(hdr.mpls_2);
    pkt.emit(hdr.ip_version_2);
    pkt.emit(hdr.mpls_3);
    pkt.emit(hdr.ip_version_3);
    pkt.emit(hdr.mpls_4);
    pkt.emit(hdr.ip_version_4);
    pkt.emit(hdr.mpls_5);
    pkt.emit(hdr.ip_version_5);
    pkt.emit(hdr.mpls_6);
    pkt.emit(hdr.ip_version_6);
    pkt.emit(hdr.ipv4);
    pkt.emit(hdr.ipv6);
    pkt.emit(hdr.tcp);
    pkt.emit(hdr.udp);
    pkt.emit(hdr.first_payload);
  }
}

/*
 * Pipeline construction
 */
Pipeline(SxIngParser(), SxIngPipeline(), SxIngDeparser(), SxEgrParser(), SxEgrPipeline(), SxEgrDeparser()) pipe;

Switch(pipe) main;
