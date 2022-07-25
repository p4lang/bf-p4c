# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4"
# 1 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/core.p4" 1
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
# 23 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/tna.p4" 2
# 1 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/core.p4" 1
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
# 23 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/tofino.p4" 2

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

extern bool is_validated<T>(in T field);

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
# 24 "/opt/platform_rel/demos/SWITCH-BF/BF-SDE-9.1.1-1.0.2-DEBIAN8/bf-sde-9.1.1-1.0.2/install/share/p4c/p4include/tna.p4" 2

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
# 2 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2

//#define INGRESS_HASH_IPV4_IPV6_SEPARATE

# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/headers.p4" 1
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

//@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 16, 16)
//@pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 16, 16)
//@pa_container_size("ingress", "hdr.ethernet.$valid", 16)

//@pa_container_size("ingress", "hdr.ipv4.src_addr", 16,16)
//@pa_container_size("ingress", "hdr.ipv4.dst_addr", 16,16)

//@pa_container_size("ingress", "hdr.inner_ipv4.src_addr", 16,16)
//@pa_container_size("ingress", "hdr.inner_ipv4.dst_addr", 16,16)

/*
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
*/

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

header ethertype_h {
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<16> tpid;
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
}

header fabric_vlan_h {
    bit<16> tpid;
    bit<16> modport;
}

header fabric_h {
    bit<16> type_;
    bit<16> modport;
    bit<16> outer_hash;
    bit<16> inner_hash;
}

header llc_header_h {
    bit<16> length_;
    bit<8> dsap;
    bit<8> ssap;
    bit<8> control_;
}

header snap_header_h {
    bit<24> oui;
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

header ipv6_hop_by_hop_h {
    bit<8> next_hdr;
    bit<8> length_;
    bit<48> options;
    // ...
}

header ipv6_routing_h {
    bit<8> next_hdr;
    bit<8> length_;
    bit<8> type_;
    bit<8> left;
    bit<32> reserved2;
    // ...
}

header ipv6_frag_h {
    bit<8> next_hdr;
    bit<8> reserved;
    bit<13> frag_offset;
    bit<2> reserved2;
    bit<1> more_frag;
    bit<32> id;
}

header ipv6_ah_h {
    bit<8> next_hdr;
    bit<8> length_;
    // ...
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

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verif_tag;
    bit<32> ck;
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

header option_word_h {
    bit<32> data;
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

// GTP User Data Messages (GTPv1)
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
# 6 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4" 1
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
# 42 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
# 75 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4"
/* Table size */
# 89 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4"
// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef bit<18> switch_stats_index_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

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




typedef bit<14> switch_vrf_t;




typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;




typedef bit<10> switch_user_metadata_t;



typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<3> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;
const switch_port_type_t SWITCH_PORT_TYPE_FABRIC = 2;
const switch_port_type_t SWITCH_PORT_TYPE_NP = 3;

typedef bit<2> ip_type_t;
const ip_type_t IP_TYPE_NONE = 0;
const ip_type_t IP_TYPE_IPV4 = 1;
const ip_type_t IP_TYPE_IPV6 = 2;

typedef bit<2> ip_frag_t;
const ip_frag_t IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const ip_frag_t IP_FRAG_FIRST_FRAG = 0b10; // First fragment of the fragmented packets.
const ip_frag_t IP_FRAG_NON_FIRST_FRAG = 0b11; // Fragment with non-zero offset.

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

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;



struct switch_port_metadata_t {
    switch_ifindex_t ifindex; //bit<16>
    bit<8> ipg; //bit<8>

    bit<3> port_type; //bit<4>
    bit<4> port_mode; //bit<4>
    bit<1> gre_term_en; //bit<1>

    bit<8> gre_tnl_id;
    bit<1> header_encap_gre_enable;
}
# 195 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4"
typedef bit<128> ip_addr_t;

struct ip_info_t {
     ip_type_t ip_type; /* 0: NONE 1: IPv4, 1: IPv6 */
     ip_frag_t frag;
     /* Flag indicating IP packet is fragmented.
        00 : Not fragmented.
        10 : Fragmented with fragOffset of zero.
        11 : Fragmented with non-zero offset.
     */
     bit<8> l4_proto;
     bit<16> sport;
     bit<16> dport;
}

struct port_t {
     bit<8> class_id;
     bit<1> gre_term_en;
     bit<1> down;
     bit<8> gre_tnl_id;
     bit<1> header_encap_gre_enable;
}

struct acl_result_metadata_t {
     switch_stats_index_t counter_id ;
     bit<1> match;
     bit<4> rule_type;
     bit<4> action_type;
     bit<16> action_data;
}

typedef bit<4> tunnel_type_t;
const tunnel_type_t TUNNEL_TYPE_NONE = 0;
const tunnel_type_t TUNNEL_TYPE_VXLAN = 1;
const tunnel_type_t TUNNEL_TYPE_IPINIP = 2;
const tunnel_type_t TUNNEL_TYPE_GRE = 3;
const tunnel_type_t TUNNEL_TYPE_GTP = 4;


struct switch_lookup_fields_t {

    ip_type_t ip_type;
    bit<8> ip_proto;

    bit<128> src_addr;
    bit<128> dst_addr;

    bit<8> l4_proto;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}


typedef bit<16> switch_hash_t;

//@pa_atomic("ingress", "ig_md.default_acl_res_md.action_data")
//@pa_atomic("ingress", "ig_md.ipv6_tcam_acl_res_md.action_data")
//@pa_atomic("ingress", "ig_md.system_tcam_acl_res_md.rule_type")


typedef bit<8> switch_common_type_t;
// Ingress metadata
struct switch_ingress_metadata_t {
    switch_ifindex_t ingress_ifindex;
    switch_port_type_t port_type;
    switch_port_t ingress_port;
    port_t port;
    bit<1> to_cpu;
    bit<1> sample_packet;
    bit<10> session_id;



    bit<16> error_reason;
    tunnel_type_t tunnel_type;

    switch_hash_t outer_sip_hash;
    switch_hash_t outer_dip_hash;
    switch_hash_t outer_ip_hash;
    switch_hash_t outer_port_hash;

    switch_hash_t inner_sip_hash;
    switch_hash_t inner_dip_hash;
    switch_hash_t inner_ip_hash;
    switch_hash_t inner_port_hash;

    switch_hash_t lag_hash;
    switch_hash_t random_hash;

    switch_hash_t outer_enhanced_hash_0;
    switch_hash_t inner_enhanced_hash_0;
    switch_hash_t np_hash;


    switch_lookup_fields_t outer_lkp;
    switch_lookup_fields_t inner_lkp;
    switch_lookup_fields_t dyn_lkp_0;
    switch_lookup_fields_t dyn_lkp_1;

    acl_result_metadata_t mac_tcam_acl_res_md;
    acl_result_metadata_t ipv4_tcam_acl_res_md;
    acl_result_metadata_t ipv6_tcam_acl_res_md;
    acl_result_metadata_t ipv6_hash_acl_res_md;
    acl_result_metadata_t ipv4_hash_acl_res_md;
    acl_result_metadata_t ip_tcam_acl_res_md;
    acl_result_metadata_t system_tcam_acl_res_md;
    acl_result_metadata_t default_acl_res_md;

    acl_result_metadata_t acl_res_md;

    bit<1> header_strip_enable;
    bit<1> lag_en;
    bit<8> lag_id;

    bit<16> modport;
    bit<9> portid;

    switch_common_type_t src_type;
    bit<8> hash_type;
}


struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.

}


const switch_common_type_t SWITCH_BRIDGED_TYPE = 8w0x01;
const switch_common_type_t SWITCH_MIRROR_TYPE = 8w0x02;

@pa_container_size("ingress", "hdr.bridged_md.egress_modport", 16)
@pa_container_size("ingress", "hdr.bridged_md.outer_hash", 16)
@pa_container_size("ingress", "hdr.bridged_md.inner_hash", 16)
header switch_bridged_metadata_h {
    switch_common_type_t type;
    bit<5> _pad_0;
    bit<1> header_strip_enable;
    bit<1> to_cpu;
    bit<1> header_encap_gre_enable;
    bit<7> _pad_3;
    switch_port_t ingress_port;
    bit<16> egress_modport;
    bit<16> outer_hash;
    bit<16> inner_hash;
    bit<5> _pad_2;
    switch_port_type_t port_type;
    switch_ifindex_t ingress_ifindex;
    bit<8> gre_tnl_id;
}


typedef bit<10> switch_mirror_session_t;

header switch_mirror_metadata_h {
    switch_common_type_t type;
    bit<16> ifindex;
}

// Header Strip flags ---------------------------------------------------------------
typedef bit<8> switch_header_strip_config_t;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_VLAN = 8w0x01;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_MPLS = 8w0x02;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_GTP = 8w0x04;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_GRE = 8w0x08;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_IPINIP = 8w0x10;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_VXLAN = 8w0x20;
const switch_header_strip_config_t SWITCH_HEADER_STRIP_TUNNEL = 8w0x3C;

// Add more ingress bypass flags here.



struct switch_egress_metadata_t {
    switch_port_type_t port_type; /* egress port type */
    switch_port_t port; /* Mutable copy of egress port */

    switch_port_type_t ingress_port_type; /* ingress port type */
    switch_port_t ingress_port; /* ingress port */
    switch_ifindex_t ingress_ifindex; /* ingress interface index */
    tunnel_type_t ingress_tunnel_type;

    ip_type_t inner_ip_type;

    switch_header_strip_config_t header_strip_config;

    acl_result_metadata_t acl_res_md;

    bit<8> gre_tnl_id;
    bit<1> header_encap_gre_enable;
    bit<1> to_cpu;
    bit<16> egress_modport;
    bit<16> outer_hash;
    bit<16> inner_hash;
}

struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    ethernet_h ethernet;
    fabric_h fabric;
    llc_header_h llc;
    snap_header_h snap;
    fabric_vlan_h fvlan;
    vlan_tag_h pvlan;
    vlan_tag_h[3] vlan_tag;
    ethertype_h ethertype;
    mpls_h[4] mpls;
    ipv4_h ogre_ipv4;
    gre_h ogre;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    sctp_h sctp;
    vxlan_h vxlan;

    gtpu_h gtpu;
    option_word_h gtp_opt_w1;
    option_word_h gtp_opt_w2;
    option_word_h gtp_opt_w3;

    gre_h gre;
    option_word_h gre_opt_w1;
    option_word_h gre_opt_w2;
    option_word_h gre_opt_w3;
    nvgre_h nvgre;

    ethernet_h inner_ethernet;
    vlan_tag_h[3] inner_vlan_tag;
    ethertype_h inner_ethertype;
    mpls_h[4] inner_mpls;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
    sctp_h inner_sctp;
}


struct empty_header_t {}
struct empty_metadata_t {}
# 7 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/acl.p4" 1
# 137 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/acl.p4"
action acl_miss(inout acl_result_metadata_t res_md)
{
    res_md.action_type = 8;
}

@name(".action_select_ip_port_proto") action acl_key_select_ip_port_proto(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = lkp.src_addr;
    dyn_lkp.dst_addr = lkp.dst_addr;
    dyn_lkp.l4_src_port = lkp.l4_src_port;
    dyn_lkp.l4_dst_port = lkp.l4_dst_port;
    dyn_lkp.ip_proto = lkp.ip_proto;
}

@name(".action_select_ip_port") action acl_key_select_ip_port(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = lkp.src_addr;
    dyn_lkp.dst_addr = lkp.dst_addr;
    dyn_lkp.l4_src_port = lkp.l4_src_port;
    dyn_lkp.l4_dst_port = lkp.l4_dst_port;
    dyn_lkp.ip_proto = 0;
}

@name(".action_select_ip_proto") action acl_key_select_ip_proto(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = lkp.src_addr;
    dyn_lkp.dst_addr = lkp.dst_addr;
    dyn_lkp.ip_proto = lkp.ip_proto;
    dyn_lkp.l4_src_port = 0;
    dyn_lkp.l4_dst_port = 0;
}

@name(".action_select_ip") action acl_key_select_ip(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = lkp.src_addr;
    dyn_lkp.dst_addr = lkp.dst_addr;
    dyn_lkp.l4_src_port = 0;
    dyn_lkp.l4_dst_port = 0;
    dyn_lkp.ip_proto = 0;
}

@name(".action_select_sip") action acl_key_select_sip(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = lkp.src_addr;
    dyn_lkp.dst_addr = 0;
    dyn_lkp.l4_src_port = 0;
    dyn_lkp.l4_dst_port = 0;
    dyn_lkp.ip_proto = 0;

}

@name(".action_select_dip") action acl_key_select_dip(in switch_lookup_fields_t lkp, out switch_lookup_fields_t dyn_lkp)
{
    dyn_lkp.ip_type = lkp.ip_type;
    dyn_lkp.src_addr = 0;
    dyn_lkp.dst_addr = lkp.dst_addr;
    dyn_lkp.l4_src_port = 0;
    dyn_lkp.l4_dst_port = 0;
    dyn_lkp.ip_proto = 0;
}


@name(".action_data") action acl_action(inout acl_result_metadata_t res_md,
                            bit<4> action_type,
                            bit<4> rule_type,
                            bit<16> action_data,
                            switch_stats_index_t counter_id) {

    res_md.rule_type = rule_type;
    res_md.action_type = action_type;
    res_md.action_data = action_data;
    res_md.counter_id = counter_id;
    res_md.match = 1;
}
# 236 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/acl.p4"
    //default_action = acl_key_select_ip_port_proto(ig_md.inner_lkp, dyn_lkp);


control IPv4TcamAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {

    table t {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); lkp.ip_type : ternary @name("iptype"); lkp.ip_proto : ternary @name("ipprotocol"); lkp.l4_src_port : ternary @name("srcport"); lkp.l4_dst_port : ternary @name("dstport"); lkp.src_addr[31:0] : ternary @name("srcip"); lkp.dst_addr[31:0] : ternary @name("dstip");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control IPv6TcamAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {
    table t {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); lkp.ip_type : ternary @name("iptype"); lkp.ip_proto : ternary @name("ipprotocol"); lkp.l4_src_port : ternary @name("srcport"); lkp.l4_dst_port : ternary @name("dstport"); lkp.src_addr : ternary @name("srcip6"); lkp.dst_addr : ternary @name("dstip6");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control IPTcamAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {

    @placement_priority(32)
    table t {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); ig_md.outer_lkp.ip_type : ternary @name("iptype"); ig_md.outer_lkp.ip_proto : ternary @name("ipprotocol"); ig_md.outer_lkp.l4_src_port : ternary @name("srcport"); ig_md.outer_lkp.l4_dst_port : ternary @name("dstport"); ig_md.outer_lkp.src_addr : ternary @name("srcip6"); ig_md.outer_lkp.dst_addr : ternary @name("dstip6");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}



control IPv6HashAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t dyn_lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {

    @ways(8)
    table t {
        key = {
            ig_md.port.class_id : exact @name("ingroup"); dyn_lkp.ip_type : exact @name("iptype"); dyn_lkp.ip_proto : exact @name("ipprotocol"); dyn_lkp.l4_src_port : exact @name("srcport"); dyn_lkp.l4_dst_port : exact @name("dstport"); dyn_lkp.src_addr : exact @name("srcip6"); dyn_lkp.dst_addr : exact @name("dstip6");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
            @defaultonly acl_key_select_ip_port_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_port(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_sip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);
        }

        default_action = acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control IPv4HashAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t dyn_lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {


    @pack(2)
    @ways(8)
    table t {
        key = {
            ig_md.port.class_id : exact @name("ingroup"); dyn_lkp.ip_type : exact @name("iptype"); dyn_lkp.ip_proto : exact @name("ipprotocol"); dyn_lkp.l4_src_port : exact @name("srcport"); dyn_lkp.l4_dst_port : exact @name("dstport"); dyn_lkp.src_addr[31:0] : exact @name("srcip"); dyn_lkp.dst_addr[31:0] : exact @name("dstip");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
            @defaultonly acl_key_select_ip_port_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_port(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_sip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);
        }

        default_action = acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control IPHashSipAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {

    table t {
        key = {
            ig_md.port.class_id : exact @name("ingroup"); lkp.ip_type : exact @name("iptype"); lkp.src_addr : exact @name("srcip6");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control IPHashDipAcl (inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md,
                     inout switch_lookup_fields_t lkp,
                     inout acl_result_metadata_t res_md)(
                     bit<32> entry_num) {

    table t {
        key = {
            ig_md.port.class_id : exact @name("ingroup"); lkp.ip_type : exact @name("iptype"); lkp.src_addr : exact @name("srcip6");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control MacTcamAcl (inout switch_header_t hdr,
                    inout switch_ingress_metadata_t ig_md,
                    inout acl_result_metadata_t res_md)(
                    bit<32> entry_num) {
    table t {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); hdr.ethernet.src_addr : ternary @name("srcmac"); hdr.ethernet.dst_addr : ternary @name("dstmac"); hdr.ethertype.ether_type : ternary @name("ethertype"); hdr.vlan_tag[0].isValid() : ternary @name("ovlan_valid"); hdr.vlan_tag[0].vid : ternary @name("ovlan"); hdr.vlan_tag[1].isValid() : ternary @name("ivlan_valid"); hdr.vlan_tag[1].vid : ternary @name("ivlan"); hdr.vlan_tag[2].isValid() : ternary @name("iivlan_valid"); hdr.vlan_tag[2].vid : ternary @name("iivlan");
        }

        actions = {
            acl_action(res_md); acl_miss(res_md);
        }

        const default_action = acl_miss(res_md);

        size = entry_num;
    }

    apply {
        t.apply();
    }
}

control AdvancedIPv4TcamAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp,
        inout acl_result_metadata_t res_md) (
        bit<32> entry_num) {

    @name(".advanced_ipv4_tcam_0") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_0;
    @name(".advanced_ipv4_tcam_1") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_1;
    @name(".advanced_ipv4_tcam_2") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_2;
    @name(".advanced_ipv4_tcam_3") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_3;
    @name(".advanced_ipv4_tcam_4") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_4;
    @name(".advanced_ipv4_tcam_5") IPv4TcamAcl(entry_num) ipv4_tcam_acl_tbl_5;

    apply {
        ipv4_tcam_acl_tbl_0.apply(hdr, ig_md, lkp, res_md);
        if (res_md.action_type == 8) {
            ipv4_tcam_acl_tbl_1.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv4_tcam_acl_tbl_2.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv4_tcam_acl_tbl_3.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv4_tcam_acl_tbl_4.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv4_tcam_acl_tbl_5.apply(hdr, ig_md, lkp, res_md);
        }
    }
}

control AdvancedIPv6TcamAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp,
        inout acl_result_metadata_t res_md)(
        bit<32> entry_num) {

    @name(".advanced_ipv6_tcam_0") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_0;
    @name(".advanced_ipv6_tcam_1") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_1;
    @name(".advanced_ipv6_tcam_2") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_2;
    @name(".advanced_ipv6_tcam_3") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_3;
    @name(".advanced_ipv6_tcam_4") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_4;
    @name(".advanced_ipv6_tcam_5") IPv6TcamAcl(entry_num) ipv6_tcam_acl_tbl_5;

    apply {
        ipv6_tcam_acl_tbl_0.apply(hdr, ig_md, lkp, res_md);
        if (res_md.action_type == 8) {
            ipv6_tcam_acl_tbl_1.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv6_tcam_acl_tbl_2.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv6_tcam_acl_tbl_3.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv6_tcam_acl_tbl_4.apply(hdr, ig_md, lkp, res_md);
        }
        if (res_md.action_type == 8) {
            ipv6_tcam_acl_tbl_5.apply(hdr, ig_md, lkp, res_md);
        }
    }
}

control AdvancedIPv6HashAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp,
        inout acl_result_metadata_t res_md)(
        bit<32> entry_num) {

    @name(".advanced_ip_hash_0") IPv6HashAcl(entry_num) ip_hash_acl_tbl_0;
    @name(".advanced_ip_hash_1") IPv6HashAcl(entry_num) ip_hash_acl_tbl_1;
    @name(".advanced_ip_hash_2") IPv6HashAcl(entry_num) ip_hash_acl_tbl_2;
    @name(".advanced_ip_hash_3") IPv6HashAcl(entry_num) ip_hash_acl_tbl_3;
    @name(".advanced_ip_hash_4") IPv6HashAcl(entry_num) ip_hash_acl_tbl_4;
    @name(".advanced_ip_hash_5") IPv6HashAcl(entry_num) ip_hash_acl_tbl_5;
    @name(".advanced_ip_hash_6") IPv6HashAcl(entry_num) ip_hash_acl_tbl_6;

    apply {
        res_md.match = 0;
        ip_hash_acl_tbl_0.apply(hdr, ig_md, lkp, res_md);
        ip_hash_acl_tbl_1.apply(hdr, ig_md, lkp, res_md);
        ip_hash_acl_tbl_2.apply(hdr, ig_md, lkp, res_md);
        ip_hash_acl_tbl_3.apply(hdr, ig_md, lkp, res_md);
        ip_hash_acl_tbl_4.apply(hdr, ig_md, lkp, res_md);
        ip_hash_acl_tbl_5.apply(hdr, ig_md, lkp, res_md);
        //ip_hash_acl_tbl_6.apply(hdr, ig_md, lkp, res_md);
    }
}

control AdvancedIPv4HashAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp,
        inout acl_result_metadata_t res_md)(
        bit<32> entry_num) {

    @name(".advanced_ipv4_hash_0") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_0;
    @name(".advanced_ipv4_hash_1") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_1;
    @name(".advanced_ipv4_hash_2") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_2;
    @name(".advanced_ipv4_hash_3") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_3;
    @name(".advanced_ipv4_hash_4") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_4;
    @name(".advanced_ipv4_hash_5") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_5;
    @name(".advanced_ipv4_hash_6") IPv4HashAcl(entry_num) ipv4_hash_acl_tbl_6;

    apply {
        ipv4_hash_acl_tbl_0.apply(hdr, ig_md, lkp, res_md);
        ipv4_hash_acl_tbl_1.apply(hdr, ig_md, lkp, res_md);
        ipv4_hash_acl_tbl_2.apply(hdr, ig_md, lkp, res_md);
        ipv4_hash_acl_tbl_3.apply(hdr, ig_md, lkp, res_md);
        ipv4_hash_acl_tbl_4.apply(hdr, ig_md, lkp, res_md);
        ipv4_hash_acl_tbl_5.apply(hdr, ig_md, lkp, res_md);
        //ipv4_hash_acl_tbl_6.apply(hdr, ig_md, lkp, res_md);
    }
}


control BasicIPTcamAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout acl_result_metadata_t res_md)(
        bit<32> entry_num) {
    @placement_priority(32)
    @name(".ip_tcam_0") IPTcamAcl(entry_num) ip_tcam_acl_tbl_0;

    apply {
        ip_tcam_acl_tbl_0.apply(hdr, ig_md, res_md);
    }
}

control SystemTcamAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout acl_result_metadata_t res_md,
        in bit<16> modport) {

    action forword_port(bit<4> rule_type, bit<4> action_type, switch_stats_index_t counter_id)
    {
        res_md.action_type = action_type;
        res_md.rule_type = rule_type;
        res_md.match = 1;
        res_md.action_data = modport;
        res_md.counter_id = counter_id;
 //ig_md.modport			  = modport;
    }

    @name(".system_tcam_0.t") table t {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); hdr.fvlan.isValid() : ternary @name("valid"); hdr.fvlan.modport : ternary @name("vid");
        }

        actions = {
            forword_port;
            acl_action(res_md);
        }

        size = 256;
    }

    apply {
        t.apply();
    }
}

control BasicMacTcamAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout acl_result_metadata_t res_md)(
        bit<32> entry_num) {

    @name(".mac_tcam_0") MacTcamAcl(entry_num) mac_tcam_acl_tbl_0;

    apply {
        mac_tcam_acl_tbl_0.apply(hdr, ig_md, res_md);
    }
}

control BasicAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)(
        bit<32> tcam_mac_entry_num)
{
    /*
    @name(".basic_ip_tcam_acl_stats_0")    Counter<bit<64>, bit<16>>(2*1024, CounterType_t.PACKETS)  basic_ip_tcam_acl_stats_0;
    @name(".basic_mac_tcam_acl_stats_0")   Counter<bit<64>, bit<16>>(3*1024, CounterType_t.PACKETS)  basic_mac_tcam_acl_stats_0;
    */

    BasicMacTcamAcl(tcam_mac_entry_num) basic_mac_tcam_acl;
    BasicIPTcamAcl(1024) basic_ip_tcam_acl;

    apply {
        basic_mac_tcam_acl.apply(hdr,ig_md, ig_md.mac_tcam_acl_res_md);
        basic_ip_tcam_acl.apply(hdr,ig_md, ig_md.ip_tcam_acl_res_md);

        /*
        basic_mac_tcam_acl_stats_0.count(ig_md.mac_tcam_acl_res_md.counter_id);
        basic_ip_tcam_acl_stats_0.count(ig_md.ip_tcam_acl_res_md.counter_id);
        */
    }
}

control AdvancedHashAclKeySelector (in switch_ingress_metadata_t ig_md,
                                    out switch_lookup_fields_t dyn_lkp) {

        @placement_priority(32)
        table t {
            actions = {
                @defaultonly acl_key_select_ip_port_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_port(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip_proto(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_ip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_sip(ig_md.inner_lkp, dyn_lkp); @defaultonly acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);
            }

            //default_action = acl_key_select_ip_port_proto(ig_md.inner_lkp, dyn_lkp);
            default_action = acl_key_select_dip(ig_md.inner_lkp, dyn_lkp);
        }
        apply {
            t.apply();
        }
}

control AdvancedAcl (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)(
        bit<32> tcam_ipv4_entry_num,
        bit<32> tcam_ipv6_entry_num,
        bit<32> hash_ipv4_entry_num,
        bit<32> hash_ipv6_entry_num)
{

    AdvancedIPv4TcamAcl(tcam_ipv4_entry_num) advanced_ipv4_tcam_acl;
    AdvancedIPv6TcamAcl(tcam_ipv6_entry_num) advanced_ipv6_tcam_acl;

    AdvancedIPv4HashAcl(hash_ipv4_entry_num) advanced_ipv4_hash_acl;

    AdvancedIPv6HashAcl(hash_ipv6_entry_num) advanced_ipv6_hash_acl;

    @name(".advanced_hash_acl_key_selector_0") AdvancedHashAclKeySelector() advanced_hash_acl_key_selector_0;
    @name(".advanced_hash_acl_key_selector_1") AdvancedHashAclKeySelector() advanced_hash_acl_key_selector_1;

    apply {
        advanced_ipv4_tcam_acl.apply(hdr,ig_md, ig_md.inner_lkp, ig_md.ipv4_tcam_acl_res_md);
        advanced_ipv6_tcam_acl.apply(hdr,ig_md, ig_md.inner_lkp, ig_md.ipv6_tcam_acl_res_md);

        advanced_hash_acl_key_selector_0.apply(ig_md, ig_md.dyn_lkp_0);
        advanced_hash_acl_key_selector_1.apply(ig_md, ig_md.dyn_lkp_1);


        advanced_ipv4_hash_acl.apply(hdr,ig_md, ig_md.dyn_lkp_1, ig_md.ipv4_hash_acl_res_md);

        advanced_ipv6_hash_acl.apply(hdr,ig_md, ig_md.dyn_lkp_0, ig_md.ipv6_hash_acl_res_md);
    }
}




control AclActionPerform(inout switch_ingress_metadata_t ig_md,
                         inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
                          inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    @name(".acl_type_stats") Counter<bit<64>, bit<8>> (64, CounterType_t.PACKETS_AND_BYTES) acl_type_stats;
    @name(".acl_stats_0") Counter<bit<32>, switch_stats_index_t> ((140*1024), CounterType_t.PACKETS) acl_stats_0;

    @name(".pick_ipv4_tcam_action_data") action pick_ipv4_tcam_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_ipv6_tcam_action_data") action pick_ipv6_tcam_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_ipv6_hash_action_data") action pick_ipv6_hash_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_ipv4_hash_action_data") action pick_ipv4_hash_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_ip_tcam_action_data") action pick_ip_tcam_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_mac_tcam_action_data") action pick_mac_tcam_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_system_tcam_action_data") action pick_system_tcam_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }
    @name(".pick_default_action_data") action pick_default_action_data(inout acl_result_metadata_t res_md) {
        ig_md.acl_res_md = res_md;
    }

    @name(".set_action_drop") action set_action_drop() {
        ig_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    @name(".default_action.t") table default_action_tbl {
        key = {
            ig_md.port.class_id : ternary @name("ingroup"); ig_md.port_type : ternary @name("porttype"); }



        actions = {
            acl_action(ig_md.default_acl_res_md);
        }
 /*
	const entries = {
		(_,SWITCH_PORT_TYPE_NORMAL) : acl_action(ig_md.default_acl_res_md, ACL_ACTION_FWD_PG, 7, 64, 0);
		(_,_)                       : acl_action(ig_md.default_acl_res_md, ACL_ACTION_DORP, 7, 0, 0);
	}
	*/

        size = 64;
    }

    @name(".acl_action_perform.t") table acl_action_perform_tbl {
        key = {
            ig_md.mac_tcam_acl_res_md.match : ternary;
            ig_md.ip_tcam_acl_res_md.match : ternary;
            ig_md.ipv6_hash_acl_res_md.match : ternary;
            ig_md.ipv4_hash_acl_res_md.match : ternary;
            ig_md.ipv6_tcam_acl_res_md.match : ternary;
            ig_md.ipv4_tcam_acl_res_md.match : ternary;
            ig_md.system_tcam_acl_res_md.match : ternary;
            ig_md.default_acl_res_md.match : ternary;
        }

        actions = {
            pick_mac_tcam_action_data(ig_md.mac_tcam_acl_res_md);
            pick_ip_tcam_action_data(ig_md.ip_tcam_acl_res_md);
            pick_ipv6_hash_action_data(ig_md.ipv6_hash_acl_res_md);
            pick_ipv4_hash_action_data(ig_md.ipv4_hash_acl_res_md);
            pick_ipv6_tcam_action_data(ig_md.ipv6_tcam_acl_res_md);
            pick_ipv4_tcam_action_data(ig_md.ipv4_tcam_acl_res_md);
            pick_system_tcam_action_data(ig_md.system_tcam_acl_res_md);
            pick_default_action_data(ig_md.default_acl_res_md);
            set_action_drop();
            //NoAction;
        }

        size = 64;
        //counters = acl_type_stats;
        const entries = {
            (_, _, _, _, _, _, 1,_) : pick_system_tcam_action_data(ig_md.system_tcam_acl_res_md);
            (1, _, _, _, _, _, _,_) : pick_mac_tcam_action_data(ig_md.mac_tcam_acl_res_md);
            (_, 1, _, _, _, _, _,_) : pick_ip_tcam_action_data(ig_md.ip_tcam_acl_res_md);
            (_, _, 1, _, _, _, _,_) : pick_ipv6_hash_action_data(ig_md.ipv6_hash_acl_res_md);
            (_, _, _, 1, _, _, _,_) : pick_ipv4_hash_action_data(ig_md.ipv4_hash_acl_res_md);
            (_, _, _, _, 1, _, _,_) : pick_ipv6_tcam_action_data(ig_md.ipv6_tcam_acl_res_md);
            (_, _, _, _, _, 1, _,_) : pick_ipv4_tcam_action_data(ig_md.ipv4_tcam_acl_res_md);
            (_, _, _, _, _, _, _,1) : pick_default_action_data(ig_md.default_acl_res_md);
            (_, _, _, _, _, _, _,_) : set_action_drop();
        }
        //const default_action = NoAction;
    }


    action set_header_strip_enable() {
        ig_md.header_strip_enable = 1;
    }

    action set_header_strip_disable() {
        ig_md.header_strip_enable = 0;
    }

    @name(".acl_header_strip_control.t") table acl_header_strip_control_tbl {
        key = {
            ig_md.acl_res_md.action_type :ternary;
            ig_md.acl_res_md.rule_type :ternary;
        }

        actions = {
            set_header_strip_enable();
            set_header_strip_disable();
        }
        size = 64;
        const default_action = set_header_strip_disable();

        const entries = {
            (_, 4) : set_header_strip_enable();
            (_, 5) : set_header_strip_enable();
        }
    }

    apply {
        ig_md.acl_res_md.action_data = 65535;
        ig_md.acl_res_md.action_type = 8;
        ig_md.acl_res_md.counter_id = 0;
        ig_md.acl_res_md.rule_type = 0;
        default_action_tbl.apply();
        acl_action_perform_tbl.apply();
        acl_header_strip_control_tbl.apply();
        acl_stats_0.count(ig_md.acl_res_md.counter_id);
        acl_type_stats.count((bit<8>)ig_md.acl_res_md.rule_type);
    }
}
# 8 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/lag.p4" 1
control LagHash(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action set_outer_sip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.outer_sip_hash;
    }

    action set_outer_dip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.outer_dip_hash;
    }
    action set_outer_ip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.outer_ip_hash;
    }
    action set_inner_sip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.inner_sip_hash;
    }

    action set_inner_dip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.inner_dip_hash;
    }
    action set_inner_ip_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = ig_md.inner_ip_hash;
    }

    action set_random_hash() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = (switch_hash_t) ig_md.random_hash;
    }

    action set_outer_enhanced_hash_0() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = (switch_hash_t) ig_md.outer_enhanced_hash_0;
    }

    action set_inner_enhanced_hash_0() {
       ig_md.lag_en = 1;
       ig_md.lag_id = (bit<8>) ig_md.acl_res_md.action_data;
       ig_md.lag_hash = (switch_hash_t) ig_md.inner_enhanced_hash_0;
    }

    @name(".portgroup_psc.t") table portgroup_psc_tbl {
        key = {
            ig_md.acl_res_md.action_type : ternary;
            ig_md.acl_res_md.action_data : ternary;
        }

        actions = {
            set_outer_sip_hash();
            set_outer_dip_hash();
            set_outer_ip_hash();
            set_inner_sip_hash();
            set_inner_dip_hash();
            set_inner_ip_hash();
            set_random_hash();
            set_outer_enhanced_hash_0();
            set_inner_enhanced_hash_0();
        }

        size = 1024;
    }

    apply {
        portgroup_psc_tbl.apply();
    }
}

control McastHash(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action set_outer_sip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.outer_sip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }
    action set_outer_dip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.outer_dip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }
    action set_outer_ip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level1_mcast_hash = (bit<13>) ig_md.outer_ip_hash;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.outer_ip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }

    action set_outer_enhanced_hash_0() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level1_mcast_hash = (bit<13>) ig_md.random_hash;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.outer_enhanced_hash_0;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }

    action set_inner_sip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.inner_sip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }
    action set_inner_dip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.inner_dip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }
    action set_inner_ip_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.inner_ip_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }

    action set_inner_enhanced_hash_0() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level1_mcast_hash = (bit<13>) ig_md.random_hash;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.inner_enhanced_hash_0;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }

    action set_random_hash() {
       ig_tm_md.mcast_grp_a = ig_md.acl_res_md.action_data;
       ig_tm_md.level1_mcast_hash = (bit<13>) ig_md.random_hash;
       ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.random_hash;
       ig_md.modport = 0x8000 | ig_md.acl_res_md.action_data;
    }

    @name(".mcastgroup_psc.t") table mcastgroup_psc_tbl {
        key = {
            ig_md.acl_res_md.action_type : ternary;
            ig_md.acl_res_md.action_data : ternary;
        }

        actions = {
            set_outer_sip_hash();
            set_outer_dip_hash();
            set_outer_ip_hash();
            set_outer_enhanced_hash_0();
            set_inner_sip_hash();
            set_inner_dip_hash();
            set_inner_ip_hash();
            set_inner_enhanced_hash_0();
            set_random_hash();
        }

        size = 1024;
    }

    @name(".set_l1xid")action set_port_l1xid(bit<16> l1xid) {
        ig_tm_md.level1_exclusion_id = l1xid;
    }

    @name(".set_l2xid")action set_port_l2xid(bit<9> l2xid) {
        ig_tm_md.level2_exclusion_id = l2xid;
    }

    @name(".port_xid_set.t")table port_xid_tbl {
        key = {
            ig_md.ingress_port : ternary;
        }
        actions = {
            set_port_l1xid();
            set_port_l2xid();
        }
        size = 512;
    }

    apply {
        mcastgroup_psc_tbl.apply();
        port_xid_tbl.apply();
    }
}

control LAG(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) selector_hash;
    @name(".lag_members") ActionProfile(128*1024) lag_members;
    @name(".lag_selector_reg") Register<bit<1>, _>(128*1024) selector_reg;
    @name(".lag_selector") ActionSelector(lag_members,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   selector_reg,
                   256,
                   1024) lag_selector;

    action set_lag_port(bit<16> mod_port) {
        ig_md.modport = mod_port;
//        ig_tm_md.ucast_egress_port = (bit<9>) mod_port;
    }

    @name(".portgroup.t") table t {
        key = {
            ig_md.lag_id : ternary;
            ig_md.lag_en : ternary;
            ig_md.lag_hash : selector;
        }

        actions = {
            set_lag_port;
        }

        size = 256;
        implementation = lag_selector;
    }

    apply {
        t.apply();
    }
}

control ModMap(inout switch_ingress_metadata_t ig_md,
               inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    @name(".set_stacking_lag") action set_stacking_lag(bit<16> lag_id) {
        ig_tm_md.mcast_grp_a = lag_id;
        ig_tm_md.level1_mcast_hash = (bit<13>) ig_md.random_hash;
        ig_tm_md.level2_mcast_hash = (bit<13>) ig_md.random_hash;
    }
    @name(".set_lag_port") action set_local_port(bit<9> port) {
        ig_tm_md.ucast_egress_port = port;
    }

    @name(".mod_map.t") table t {
        key = {
            ig_md.modport : ternary;
        }

        actions = {
            set_stacking_lag;
            set_local_port;
        }

        size = 512;
    }

    apply {
        t.apply();
    }
}
# 9 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/parser.p4" 1
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/headers.p4" 1
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
# 2 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/parser.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/types.p4" 1
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
# 3 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/parser.p4" 2

@pa_auto_init_metadata
//=============================================================================
// Ingress parser
//=============================================================================
parser IngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        ig_md.ingress_port = ig_intr_md.ingress_port;
        // Check for resubmit flag if packet is resubmitted.
        transition select(ig_intr_md.resubmit_flag) {
           1 : parse_resubmit;
           0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);

        ig_md.port_type = port_md.port_type;
        ig_md.ingress_ifindex = port_md.ifindex;
        ig_md.port.class_id = port_md.ipg;
     ig_md.port.gre_term_en = port_md.gre_term_en;
        ig_md.port.header_encap_gre_enable = port_md.header_encap_gre_enable;
        ig_md.port.gre_tnl_id = port_md.gre_tnl_id;

        transition select(port_md.port_type) {
            SWITCH_PORT_TYPE_NORMAL : parse_ethernet;
            SWITCH_PORT_TYPE_FABRIC : parse_fabric;
            SWITCH_PORT_TYPE_NP : parse_np;
            default : accept;
        }
    }

    state parse_np {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.fvlan);
        ig_md.np_hash = hdr.fvlan.modport;
        transition accept;
    }

    state parse_fabric {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.fabric);
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        //bit<16> ether_type = pkt.lookahead<bit<16>>();
        transition select(pkt.lookahead<bit<16>>()) {
            (0x8100) : parse_vlan;
   (0x88a8) : parse_vlan;
   (0x9100) : parse_vlan;
   (0x9200) : parse_vlan;
//            (ETHERTYPE_QINQ) : parse_vlan;
            default : parse_ethertype;
        }
    }

    state parse_ethertype {
        pkt.extract(hdr.ethertype);
        transition select(hdr.ethertype.ether_type) {
            (0x0800) : parse_ipv4;
            (0x0806) : parse_arp;
            (0x86dd) : parse_ipv6;
            (0x8847) : parse_mpls;
            (0x8848) : parse_mpls;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        //bit<16> ether_type = pkt.lookahead<bit<16>>();
        transition select(pkt.lookahead<bit<16>>()) {
            (0x8100) : parse_vlan;
   (0x88a8) : parse_vlan;
   (0x9100) : parse_vlan;
   (0x9200) : parse_vlan;
            default : parse_ethertype;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            default : parse_mpls_payload;
        }
    }

    state parse_mpls_payload {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            4w4 : parse_ipv4;
            4w6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (4, 0) : parse_ipinip;
            (41, 0) : parse_ipv6inip;
            (132, 0) : parse_sctp;
            (47, 0) : parse_gre;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }


    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            4 : parse_ipinip;
            41 : parse_ipv6inip;
            132 : parse_sctp;
            47 : parse_gre;
            default : accept;
        }
    }


    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.outer_lkp.l4_src_port = hdr.udp.src_port;
        ig_md.outer_lkp.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            2152 : parse_gtpu;
         default : accept;
     }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.outer_lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.outer_lkp.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        ig_md.outer_lkp.l4_src_port = hdr.sctp.src_port;
        ig_md.outer_lkp.l4_dst_port = hdr.sctp.dst_port;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_vxlan {
        ig_md.tunnel_type = TUNNEL_TYPE_VXLAN;
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S) {
            (0,0,0) : parse_gre_no_option;
            (0,0,1) : parse_gre_option_1;
            (0,1,0) : parse_gre_option_1;
            (1,0,0) : parse_gre_option_1;
            (0,1,1) : parse_gre_option_2;
            (1,1,0) : parse_gre_option_2;
            (1,0,1) : parse_gre_option_2;
            (1,1,1) : parse_gre_option_3;
         default : accept;
        }
    }

    state parse_gre_option_1 {
        pkt.extract(hdr.gre_opt_w1);
        transition parse_gre_no_option;
    }

    state parse_gre_option_2 {
        pkt.extract(hdr.gre_opt_w1);
        pkt.extract(hdr.gre_opt_w2);
        transition parse_gre_no_option;
    }

    state parse_gre_option_3 {
        pkt.extract(hdr.gre_opt_w1);
        pkt.extract(hdr.gre_opt_w2);
        pkt.extract(hdr.gre_opt_w3);
        transition parse_gre_no_option;
    }

    state parse_gre_no_option {
        transition select(hdr.gre.proto) {
            (0x0800) : parse_inner_ipv4;
            (0x86dd) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        transition select(hdr.gtpu.s, hdr.gtpu.e, hdr.gtpu.pn) {
            (0,0,0) : parse_gtp_no_option;
            (0,0,1) : parse_gtp_option_1;
            (0,1,0) : parse_gtp_option_2;
            (1,0,0) : parse_gtp_option_1;
            (0,1,1) : parse_gtp_option_2;
            (1,1,0) : parse_gtp_option_2;
            (1,0,1) : parse_gtp_option_2;
            (1,1,1) : parse_gtp_option_3;
         default : accept;
        }
    }

    state parse_gtp_option_1 {
        pkt.extract(hdr.gtp_opt_w1);
        transition parse_gtp_no_option;
    }

    state parse_gtp_option_2 {
        pkt.extract(hdr.gtp_opt_w1);
        pkt.extract(hdr.gtp_opt_w2);
        transition parse_gtp_no_option;
    }

    state parse_gtp_option_3 {
        pkt.extract(hdr.gtp_opt_w1);
        pkt.extract(hdr.gtp_opt_w2);
        pkt.extract(hdr.gtp_opt_w3);
        transition parse_gtp_no_option;
    }

    state parse_gtp_no_option {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version) {
             4w4 : parse_inner_ipv4;
             4w6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_ipinip {
        ig_md.tunnel_type = TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
    }

    state parse_ipv6inip {
        ig_md.tunnel_type = TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(pkt.lookahead<bit<16>>()) {
            0x8100 : parse_inner_vlan;
            0x8100 : parse_inner_vlan;
            default : parse_inner_ethertype;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        //bit<16> ether_type = pkt.lookahead<bit<16>>();
        transition select(pkt.lookahead<bit<16>>()) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ethertype;
        }
    }

    state parse_inner_ethertype {
        pkt.extract(hdr.inner_ethertype);
        transition select(hdr.inner_ethertype.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            0x8847 : parse_inner_mpls;
            0x8848 : parse_inner_mpls;
            default : accept;
        }
    }

    state parse_inner_mpls {
        pkt.extract(hdr.inner_mpls.next);
        transition select(hdr.inner_mpls.last.bos) {
            0 : parse_inner_mpls;
            default : parse_inner_mpls_payload;
        }
    }

    state parse_inner_mpls_payload {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            132 : parse_inner_sctp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.inner_lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.inner_lkp.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.inner_lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.inner_lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        ig_md.inner_lkp.l4_src_port = hdr.inner_sctp.src_port;
        ig_md.inner_lkp.l4_dst_port = hdr.inner_sctp.dst_port;
        transition accept;
    }
}

// Egress parser/control blocks
parser EgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        eg_md.port = eg_intr_md.egress_port;
        transition select(pkt.lookahead<bit<8>>()) {
            (SWITCH_BRIDGED_TYPE) : parse_bridged_pkt;
            (SWITCH_MIRROR_TYPE) : parse_mirror_pkt;
            default : accept;
        }
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.ingress_port_type = hdr.bridged_md.port_type;
        eg_md.ingress_ifindex = hdr.bridged_md.ingress_ifindex;
        eg_md.header_encap_gre_enable = hdr.bridged_md.header_encap_gre_enable;
        eg_md.gre_tnl_id = hdr.bridged_md.gre_tnl_id;
 eg_md.to_cpu = hdr.bridged_md.to_cpu;
 eg_md.egress_modport = hdr.bridged_md.egress_modport;
 eg_md.outer_hash = hdr.bridged_md.outer_hash;
 eg_md.inner_hash = hdr.bridged_md.inner_hash;
        transition parse_ethernet;
    }

    state parse_mirror_pkt {
        switch_mirror_metadata_h mirror_md;
        pkt.extract(mirror_md);
        eg_md.ingress_ifindex = mirror_md.ifindex;
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        //bit<16> ether_type = pkt.lookahead<bit<16>>();
        transition select(pkt.lookahead<bit<16>>()) {
            (0x8100) : parse_vlan;
   (0x88a8) : parse_vlan;
   (0x9100) : parse_vlan;
   (0x9200) : parse_vlan;
//            (ETHERTYPE_QINQ) : parse_vlan;
            default : parse_ethertype;
        }
    }

    state parse_ethertype {
        pkt.extract(hdr.ethertype);
        transition select(hdr.ethertype.ether_type) {
            (0x0800) : parse_ipv4;
            (0x0806) : parse_arp;
            (0x86dd) : parse_ipv6;
            (0x8847) : parse_mpls;
            (0x8848) : parse_mpls;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        //bit<16> ether_type = pkt.lookahead<bit<16>>();
        transition select(pkt.lookahead<bit<16>>()) {
            (0x8100) : parse_vlan;
   (0x88a8) : parse_vlan;
   (0x9100) : parse_vlan;
   (0x9200) : parse_vlan;
            default : parse_ethertype;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            default : parse_mpls_payload;
        }
    }

    state parse_mpls_payload {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            4w4 : parse_ipv4;
            4w6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (4, 0) : parse_ipinip;
            (41, 0) : parse_ipv6inip;
            (132, 0) : parse_sctp;
            (47, 0) : parse_gre;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }


    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            4 : parse_ipinip;
            41 : parse_ipv6inip;
            132 : parse_sctp;
            47 : parse_gre;
            default : accept;
        }
    }


    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            2152 : parse_gtpu;
         default : accept;
     }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S) {
            (0,0,0) : parse_gre_no_option;
            (0,0,1) : parse_gre_option_1;
            (0,1,0) : parse_gre_option_1;
            (1,0,0) : parse_gre_option_1;
            (0,1,1) : parse_gre_option_2;
            (1,1,0) : parse_gre_option_2;
            (1,0,1) : parse_gre_option_2;
            (1,1,1) : parse_gre_option_3;
         default : accept;
        }
    }

    state parse_gre_option_1 {
        pkt.extract(hdr.gre_opt_w1);
        transition parse_gre_no_option;
    }

    state parse_gre_option_2 {
        pkt.extract(hdr.gre_opt_w1);
        pkt.extract(hdr.gre_opt_w2);
        transition parse_gre_no_option;
    }

    state parse_gre_option_3 {
        pkt.extract(hdr.gre_opt_w1);
        pkt.extract(hdr.gre_opt_w2);
        pkt.extract(hdr.gre_opt_w3);
        transition parse_gre_no_option;
    }

    state parse_gre_no_option {
        transition select(hdr.gre.proto) {
            (0x0800) : parse_inner_ipv4;
            (0x86dd) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        transition select(hdr.gtpu.s, hdr.gtpu.e, hdr.gtpu.pn) {
            (0,0,0) : parse_gtp_no_option;
            (0,0,1) : parse_gtp_option_1;
            (0,1,0) : parse_gtp_option_2;
            (1,0,0) : parse_gtp_option_1;
            (0,1,1) : parse_gtp_option_2;
            (1,1,0) : parse_gtp_option_2;
            (1,0,1) : parse_gtp_option_2;
            (1,1,1) : parse_gtp_option_3;
         default : accept;
        }
    }

    state parse_gtp_option_1 {
        pkt.extract(hdr.gtp_opt_w1);
        transition parse_gtp_no_option;
    }

    state parse_gtp_option_2 {
        pkt.extract(hdr.gtp_opt_w1);
        pkt.extract(hdr.gtp_opt_w2);
        transition parse_gtp_no_option;
    }

    state parse_gtp_option_3 {
        pkt.extract(hdr.gtp_opt_w1);
        pkt.extract(hdr.gtp_opt_w2);
        pkt.extract(hdr.gtp_opt_w3);
        transition parse_gtp_no_option;
    }

    state parse_gtp_no_option {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version) {
             4w4 : parse_inner_ipv4;
             4w6 : parse_inner_ipv6;
            default : accept;
        }
    }

     state parse_ipinip {
        transition parse_inner_ipv4;
    }

    state parse_ipv6inip {
        transition parse_inner_ipv6;
    }

    state parse_inner_ethernet {
        eg_md.inner_ip_type = IP_TYPE_NONE;
        transition accept;
    }

    state parse_inner_ipv4 {
        eg_md.inner_ip_type = IP_TYPE_IPV4;
        transition accept;
    }

    state parse_inner_ipv6 {
        eg_md.inner_ip_type = IP_TYPE_IPV6;
        transition accept;
    }
}
# 10 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/validation.p4" 1
// ============================================================================
// Packet isValid()aion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// ============================================================================

control PktValidation(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp) {

    const int table_size = 64;


    CRCPolynomial<bit<32>> (
        coeff = 0x04C11DB7,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly0;

    CRCPolynomial<bit<32>> (
        coeff = 0x1EDC6F41,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly1;

    CRCPolynomial<bit<32>> (
        coeff = 0xA833982B,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly2;

    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) sip_hash;
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) dip_hash;
    //@symmetric("ig_md.outer_lkp.l4_src_port", "ig_md.outer_lkp.l4_dst_port")
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) port_hash;
    //@symmetric("ig_md.outer_lkp.l4_src_port", "ig_md.outer_lkp.l4_dst_port")
    //@symmetric("ig_md.outer_lkp.src_addr", "ig_md.outer_lkp.dst_addr")
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly0) enhanced_hash0;
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly1) enhanced_hash1;
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly2) enhanced_hash2;

    Random<switch_hash_t>() rand_hash;

    action compute_sip_hash(out switch_hash_t hash) {
        hash = sip_hash.get({lkp.src_addr});
    }

    action compute_dip_hash(out switch_hash_t hash) {
        hash = dip_hash.get({lkp.dst_addr});
    }

    action compute_port_hash(out switch_hash_t hash) {
        hash = port_hash.get({lkp.l4_src_port, lkp.l4_dst_port});
    }

    action compute_enhanced_hash_0() {
        ig_md.outer_enhanced_hash_0 = enhanced_hash0.get({ig_md.outer_ip_hash, ig_md.outer_sip_hash, ig_md.outer_dip_hash, ig_md.outer_port_hash, lkp.ip_proto});
    }

    action compute_enhanced_hash_1() {
        ig_md.outer_enhanced_hash_0 = enhanced_hash1.get({ig_md.outer_ip_hash, ig_md.outer_sip_hash, ig_md.outer_dip_hash, ig_md.outer_port_hash, lkp.ip_proto});
    }

    action compute_enhanced_hash_2() {
        ig_md.outer_enhanced_hash_0 = enhanced_hash2.get({ig_md.outer_ip_hash, ig_md.outer_sip_hash, ig_md.outer_dip_hash, ig_md.outer_port_hash, lkp.ip_proto});
    }

    table enhance_type_tbl {
        key = {
            ig_md.hash_type : ternary;
        }
        actions = {
            //compute_enhanced_hash_0;
            compute_enhanced_hash_1;
            compute_enhanced_hash_2;
            NoAction;
        }
    }

    action valid_ipv4_pkt(ip_frag_t ip_frag) {
        // Set common lookup fields
        lkp.ip_type = IP_TYPE_IPV4;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.dst_addr = (bit<128>) hdr.ipv4.dst_addr;
    }

    table validate_ipv4 {
        key = {
            hdr.ipv4.version : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
        }

        actions = {
            NoAction;
            valid_ipv4_pkt;
        }

        size = table_size;

        const default_action = NoAction;
        const entries = {
            (4,_,_) : valid_ipv4_pkt(0);
        }
    }

    action valid_ipv6_pkt() {
        // Set common lookup fields
        lkp.ip_type = IP_TYPE_IPV6;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.src_addr = hdr.ipv6.src_addr;
        lkp.dst_addr = hdr.ipv6.dst_addr;
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
        }

        actions = {
            NoAction;
            valid_ipv6_pkt;
        }

        const default_action = NoAction;
        const entries = {
            (6) : valid_ipv6_pkt();
        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
    }

    action set_sctp_ports() {
        lkp.l4_src_port = hdr.sctp.src_port;
        lkp.l4_dst_port = hdr.sctp.dst_port;
    }

    // Not much of a isValid()ation as it only sets the lookup fields.
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

    apply {
        if (hdr.ipv4.isValid()) {
            validate_ipv4.apply();
        } else if (hdr.ipv6.isValid()) {
            validate_ipv6.apply();
        }
        compute_sip_hash(ig_md.outer_sip_hash);
        compute_dip_hash(ig_md.outer_dip_hash);
        //compute_port_hash(ig_md.outer_port_hash);
  ig_md.outer_port_hash = lkp.l4_src_port ^ lkp.l4_dst_port;
        ig_md.outer_ip_hash = ig_md.outer_sip_hash ^ ig_md.outer_dip_hash;
        ig_md.random_hash = rand_hash.get();
        compute_enhanced_hash_0();
        enhance_type_tbl.apply();
        //validate_other.apply();
    }
}

control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout switch_lookup_fields_t lkp) {

    const int table_size = 64;

    CRCPolynomial<bit<32>> (
        coeff = 0x04C11DB7,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly0;

    CRCPolynomial<bit<32>> (
        coeff = 0x1EDC6F41,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly1;

    CRCPolynomial<bit<32>> (
        coeff = 0xA833982B,
        reversed = true,
        msb = false,
        extended = false,
        init = 0xFFFFFFFF,
        xor = 0xFFFFFFFF) poly2;

    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) sip_hash;
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) dip_hash;
    //@symmetric("ig_md.inner_lkp.l4_src_port", "ig_md.inner_lkp.l4_dst_port")
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) port_hash;
    //@symmetric("ig_md.inner_lkp.l4_src_port", "ig_md.inner_lkp.l4_dst_port")
    //@symmetric("ig_md.inner_lkp.src_addr", "ig_md.inner_lkp.dst_addr")
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly0) enhanced_hash0;
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly1) enhanced_hash1;
    Hash<switch_hash_t>(HashAlgorithm_t.CUSTOM, poly2) enhanced_hash2;

    action compute_sip_hash(out switch_hash_t hash) {
        hash = sip_hash.get({lkp.src_addr});
    }

    action compute_dip_hash(out switch_hash_t hash) {
        hash = dip_hash.get({lkp.dst_addr});
    }

    action compute_port_hash(out switch_hash_t hash) {
        hash = port_hash.get({lkp.l4_src_port, lkp.l4_dst_port});
    }

    action compute_enhanced_hash_0() {
        ig_md.inner_enhanced_hash_0 = enhanced_hash0.get({ig_md.inner_ip_hash, ig_md.inner_sip_hash, ig_md.inner_dip_hash, ig_md.inner_port_hash, lkp.ip_proto});
    }

    action compute_enhanced_hash_1() {
        ig_md.inner_enhanced_hash_0 = enhanced_hash1.get({ig_md.inner_ip_hash, ig_md.inner_sip_hash, ig_md.inner_dip_hash, ig_md.inner_port_hash, lkp.ip_proto});
    }

    action compute_enhanced_hash_2() {
        ig_md.inner_enhanced_hash_0 = enhanced_hash2.get({ig_md.inner_ip_hash, ig_md.inner_sip_hash, ig_md.inner_dip_hash, ig_md.inner_port_hash, lkp.ip_proto});
    }

    table enhance_type_tbl {
        key = {
            ig_md.hash_type : ternary;
        }
        actions = {
            //compute_enhanced_hash_0;
            compute_enhanced_hash_1;
            compute_enhanced_hash_2;
            NoAction;
        }
    }


    action valid_ipv4_pkt(ip_frag_t ip_frag) {
        // Set common lookup fields
        lkp.ip_type = IP_TYPE_IPV4;
        lkp.ip_proto = hdr.inner_ipv4.protocol;
        lkp.src_addr = (bit<128>) hdr.inner_ipv4.src_addr;
        lkp.dst_addr = (bit<128>) hdr.inner_ipv4.dst_addr;
    }

    table validate_ipv4 {
        key = {
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.flags : ternary;
            hdr.inner_ipv4.frag_offset : ternary;
        }

        actions = {
            NoAction;
            valid_ipv4_pkt;
        }

        size = table_size;

        const default_action = NoAction;
        const entries = {
            (4,_,_) : valid_ipv4_pkt(0);
        }
    }

    action valid_ipv6_pkt() {
        // Set common lookup fields
        lkp.ip_type = IP_TYPE_IPV6;
        lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        lkp.src_addr = hdr.inner_ipv6.src_addr;
        lkp.dst_addr = hdr.inner_ipv6.dst_addr;
    }

    table validate_ipv6 {
        key = {
            hdr.inner_ipv6.version : ternary;
        }

        actions = {
            NoAction;
            valid_ipv6_pkt;
        }

        const default_action = NoAction;
        const entries = {
            (6) : valid_ipv6_pkt();
        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.inner_tcp.src_port;
        lkp.l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.inner_udp.src_port;
        lkp.l4_dst_port = hdr.inner_udp.dst_port;
    }

    action set_sctp_ports() {
        lkp.l4_src_port = hdr.inner_sctp.src_port;
        lkp.l4_dst_port = hdr.inner_sctp.dst_port;
    }

    // Not much of a isValid()ation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
            hdr.inner_sctp.isValid() : exact;
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

    apply {
        if (hdr.inner_ipv4.isValid()) {
            validate_ipv4.apply();
        } else if (hdr.inner_ipv6.isValid()) {
            validate_ipv6.apply();
        }

        compute_sip_hash(ig_md.inner_sip_hash);
        compute_dip_hash(ig_md.inner_dip_hash);
        //compute_port_hash(ig_md.inner_port_hash);
        ig_md.inner_port_hash = lkp.l4_src_port ^ lkp.l4_dst_port;
        ig_md.inner_ip_hash = ig_md.inner_sip_hash ^ ig_md.inner_dip_hash;
        compute_enhanced_hash_0();
        enhance_type_tbl.apply();

        //validate_other.apply();
    }
}
# 11 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/packet_stats.p4" 1

typedef bit<8> sys_pkt_stats_index_t;
//const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_GRE         = 0 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_GTP = 1 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_VXLAN = 2 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_L2TP = 3 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_PPTP = 4 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_AH = 5 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_ESP = 6 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_4IN4 = 7 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_4IN6 = 8 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_6IN6 = 9 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_6IN4 = 10;
const sys_pkt_stats_index_t SYS_PKT_STATS_TUNNEL_BGP = 11;


const sys_pkt_stats_index_t SYS_PKT_STATS_L2_ISIS = 0 ;

const sys_pkt_stats_index_t SYS_PKT_STATS_L3_OSPF = 0 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_L3_IPSEC = 1 ;
const sys_pkt_stats_index_t SYS_PKT_STATS_L3_GRE = 2 ;


control PacketStat(
    in switch_header_t hdr,
    in switch_ingress_metadata_t ig_md) {

@name(".sys_pkt_stats_error") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_error;
@name(".sys_pkt_stats_l2") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_l2;
@name(".sys_pkt_stats_qinq") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_qinq;
@name(".sys_pkt_stats_vlan") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_vlan;
@name(".sys_pkt_stats_mpls") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_mpls;
@name(".sys_pkt_stats_iptype") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_iptype;
@name(".sys_pkt_stats_l4type") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_l4type;
@name(".sys_pkt_stats_l3") Counter<bit<64>, bit<8>>(64, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_l3;
@name(".sys_pkt_stats_tunnel") Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) sys_pkt_stats_tunnel;

action error_pkt_count(bit<8>index) {
    sys_pkt_stats_error.count(index);
}

table error_pkt_stat_tbl {
    key = {
        ig_md.error_reason : ternary;
    }
    actions = {
        error_pkt_count;
        @defaultonly NoAction;
    }
    size = 256;
}

action l2_pkt_count_isis() {
    sys_pkt_stats_l2.count(SYS_PKT_STATS_L2_ISIS);
}

action l2_pkt_count(bit<8>index) {
    sys_pkt_stats_l2.count(index);
}

table l2_pkt_stat_tbl {
    key = {
        hdr.ethernet.dst_addr : ternary;
    }
    actions = {
        l2_pkt_count;
        l2_pkt_count_isis;
        @defaultonly NoAction;
    }
    size = 64;

    const entries = {
      (0x0180C2000014) : l2_pkt_count_isis();
      (0x0180C2000015) : l2_pkt_count_isis();
    }
}


action l3_pkt_count_ospf(){
    sys_pkt_stats_l3.count(SYS_PKT_STATS_L3_OSPF);
}

action l3_pkt_count_ipsec(){
    sys_pkt_stats_l3.count(SYS_PKT_STATS_L3_IPSEC);
}

action l3_pkt_count_gre() {
    sys_pkt_stats_l3.count(SYS_PKT_STATS_L3_GRE);
}

action l3_pkt_count(bit<8>index) {
    sys_pkt_stats_l3.count(index);
}
table l3_pkt_stat_tbl {
    key = {
        hdr.ipv4.isValid() : ternary;
        hdr.ipv4.protocol : ternary;
        hdr.ipv6.isValid() : ternary;
        hdr.ipv6.next_hdr : ternary;
    }
    actions = {
        l3_pkt_count;
        l3_pkt_count_ospf;
        l3_pkt_count_ipsec;
        l3_pkt_count_gre;
        @defaultonly NoAction;
    }
    size = 64;

    const entries = {
        (true, 89 &&& 0xFF, _, _) : l3_pkt_count_ospf();
        (_, _, true, 89 &&& 0xFF) : l3_pkt_count_ospf();
        (true, 51 &&& 0xFF, _, _) : l3_pkt_count_ipsec();
        (_, _, true, 51 &&& 0xFF) : l3_pkt_count_ipsec();
        (true, 50 &&& 0xFF, _, _) : l3_pkt_count_ipsec();
        (_, _, true, 50 &&& 0xFF) : l3_pkt_count_ipsec();
        (true, 47 &&& 0xFF, _, _) : l3_pkt_count_gre();
        (_, _, true, 47 &&& 0xFF) : l3_pkt_count_gre();

    }
}

    action tunnel_pkt_count(bit<8>index) {
        sys_pkt_stats_tunnel.count(index);
    }

    //action tunnel_pkt_count_gre() {
      //  sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_GRE);
    //}

    action tunnel_pkt_count_gtp() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_GTP);
    }

    action tunnel_pkt_count_vxlan() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_VXLAN);
    }

    action tunnel_pkt_count_l2tp() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_L2TP);
    }

    action tunnel_pkt_count_4in4() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_4IN4);
    }

    action tunnel_pkt_count_4in6() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_4IN6);
    }

    action tunnel_pkt_count_6in4() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_6IN4);
    }

    action tunnel_pkt_count_6in6() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_6IN6);
    }

    action tunnel_pkt_count_bgp() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_BGP);
    }

    action tunnel_pkt_count_pptp() {
        sys_pkt_stats_tunnel.count(SYS_PKT_STATS_TUNNEL_PPTP);
    }

    table tunnel_pkt_stat_tbl {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv4.protocol : ternary;
            hdr.ipv6.next_hdr : ternary;

            hdr.inner_ipv4.isValid() : ternary;
            hdr.inner_ipv6.isValid() : ternary;

            hdr.udp.isValid() : ternary;
            hdr.tcp.isValid() : ternary;
            ig_md.outer_lkp.l4_src_port : ternary;
            ig_md.outer_lkp.l4_dst_port : ternary;

            hdr.gre.isValid() : ternary;
            hdr.gre.proto : ternary;
            hdr.gtpu.isValid() : ternary;
            hdr.vxlan.isValid() : ternary;
        }
        actions = {
            tunnel_pkt_count;
            tunnel_pkt_count_gtp;
            tunnel_pkt_count_vxlan;
            tunnel_pkt_count_4in4;
            tunnel_pkt_count_4in6;
            tunnel_pkt_count_6in6;
            tunnel_pkt_count_6in4;
            tunnel_pkt_count_l2tp;
            tunnel_pkt_count_bgp;
            tunnel_pkt_count_pptp;
            @defaultonly NoAction;
        }
        size = 64;
        const entries = {
            (_, _, _, _, _, _, _, _, _, _, false, _, true, false) : tunnel_pkt_count_gtp();
            (_, _, _, _, _, _, true, _, _, 2123 &&& 0xFFF, _, _, _, _) : tunnel_pkt_count_gtp();
            (_, _, _, _, _, _, _, _, _, _, false, _, false, true) : tunnel_pkt_count_vxlan();
            (_, _, _, _, _, _, true, false, _, 1701 &&& 0xFFFF, _, _, _, _) : tunnel_pkt_count_l2tp();
            (true, _, 115 &&& 0xFF, _, _, _, _, _, _, _, _, _, _, _) : tunnel_pkt_count_l2tp();
            (_, true, _, 115 &&& 0xFF, _, _, _, _, _, _, _, _, _, _) : tunnel_pkt_count_l2tp();
            (_, _, _, _, _, _, false, true, _, 0179 &&& 0xFFFF, _, _, _, _) : tunnel_pkt_count_bgp();
            (_, _, _, _, _, _, false, true, 0179 &&& 0xFFFF, _, _, _, _, _) : tunnel_pkt_count_bgp();
            (_, _, _, _, _, _, false, true, _, 1723 &&& 0xFFFF, _, _, _, _) : tunnel_pkt_count_pptp();
            (_, _, _, _, _, _, false, true, 1723 &&& 0xFFFF, _, _, _, _, _) : tunnel_pkt_count_pptp();
            (_, _, _, _, _, _, _, _, _, _, true, 0x880B &&& 0xFFFF, false, false) : tunnel_pkt_count_pptp();

            (true, _, _, _, true, _, _, _, _, _, false, _, _, _) : tunnel_pkt_count_4in4();
            (true, _, _, _, _, true, _, _, _, _, false, _, _, _) : tunnel_pkt_count_4in6();
            (_, true, _, _, true, _, _, _, _, _, false, _, _, _) : tunnel_pkt_count_6in4();
            (_, true, _, _, _, true, _, _, _, _, false, _, _, _) : tunnel_pkt_count_6in6();
        }
    }

    apply {
        if (hdr.vlan_tag[0].isValid()) {
            sys_pkt_stats_vlan.count(0);
            if (hdr.vlan_tag[1].isValid()) {
                sys_pkt_stats_qinq.count(0);
            }
        }
        if (hdr.mpls[0].isValid()) {
            sys_pkt_stats_mpls.count(0);
        }

        if (hdr.ipv4.isValid()) {
            sys_pkt_stats_iptype.count(0);
        } else if (hdr.ipv6.isValid()) {
            sys_pkt_stats_iptype.count(1);
        }

        if (hdr.tcp.isValid()) {
            sys_pkt_stats_l4type.count(0);
        } else if (hdr.udp.isValid()) {
            sys_pkt_stats_l4type.count(1);
        } else if (hdr.sctp.isValid()) {
            sys_pkt_stats_l4type.count(2);
        }else if(hdr.icmp.isValid()){
            sys_pkt_stats_l4type.count(3);
        }

        error_pkt_stat_tbl.apply();
        l2_pkt_stat_tbl.apply();
        l3_pkt_stat_tbl.apply();
        tunnel_pkt_stat_tbl.apply();
    }
}
# 12 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/header_strip.p4" 1
control VlanDecap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action remove_vlan_tag() {
        hdr.vlan_tag.pop_front(1);
    }

    action remove_double_tag() {
        hdr.vlan_tag.pop_front(2);
    }
    action remove_triple_tag() {
        hdr.vlan_tag.pop_front(3);
    }

    table vlan_decap {
        key = {
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[1].isValid() : ternary;
            hdr.vlan_tag[2].isValid() : ternary;
        }

        actions = {
            NoAction;
            remove_vlan_tag;
            remove_double_tag;
            remove_triple_tag;
        }
        const default_action = NoAction;

        const entries = {
            (true, true, true) : remove_triple_tag();
            (true, true, false) : remove_double_tag();
            (true, false, false) : remove_vlan_tag();
        }
    }

    apply {
        vlan_decap.apply();
    }
}

control MplsDecap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action remove_1_lable() {
        hdr.mpls.pop_front(1);
    }

    action remove_2_lable() {
        hdr.mpls.pop_front(2);
    }

    action remove_3_lable() {
        hdr.mpls.pop_front(3);
    }

    action remove_4_lable() {
        hdr.mpls.pop_front(4);
    }

    table mpls_decap {
        key = {
            hdr.mpls[0].isValid() : ternary;
            hdr.mpls[1].isValid() : ternary;
            hdr.mpls[2].isValid() : ternary;
            hdr.mpls[3].isValid() : ternary;
        }

        actions = {
            NoAction;
            remove_1_lable;
            remove_2_lable;
            remove_3_lable;
            remove_4_lable;
        }
        const default_action = NoAction;

        const entries = {
            (true, true, true, true) : remove_4_lable();
            (true, true, true, false) : remove_3_lable();
            (true, true, false, false) : remove_2_lable();
            (true, false, false,false) : remove_1_lable();
        }
    }

    apply {
        mpls_decap.apply();
        if (hdr.ipv4.isValid()) {
            hdr.ethertype.ether_type = 16w0x0800;
        } else if(hdr.ipv6.isValid()){
            hdr.ethertype.ether_type = 16w0x86dd;
        }
    }
}

control TunnelDecap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {


    action strip_ip_header() {
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }

    action strip_gre_header() {

        strip_ip_header();

        hdr.gre.setInvalid();
        hdr.gre_opt_w1.setInvalid();
        hdr.gre_opt_w2.setInvalid();
        hdr.gre_opt_w3.setInvalid();
    }

    action strip_gtp_header() {
        strip_ip_header();

        hdr.udp.setInvalid();

        hdr.gtpu.setInvalid();
        hdr.gtp_opt_w1.setInvalid();
        hdr.gtp_opt_w2.setInvalid();
        hdr.gtp_opt_w3.setInvalid();
    }

    action decap_vxlan() {
        hdr.ethernet.setInvalid();
        hdr.ethertype.setInvalid();

        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();

        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();

        strip_ip_header();

        hdr.udp.setInvalid();

        hdr.vxlan.setInvalid();
    }

    action decap_gre_inner_ipv4() {
        hdr.ethertype.ether_type = 16w0x0800;
        strip_gre_header();
    }

    action decap_gre_inner_ipv6() {
        hdr.ethertype.ether_type = 16w0x86dd;
        strip_gre_header();
    }

    action decap_gre_with_mpls() {
        strip_gre_header();
    }


    action decap_gtp_inner_ipv4() {
        hdr.ethertype.ether_type = 16w0x0800;
        strip_gtp_header();
    }

    action decap_gtp_inner_ipv6() {
        hdr.ethertype.ether_type = 16w0x86dd;
        strip_gtp_header();
    }

    action decap_gtp_with_mpls() {
        strip_gtp_header();
    }


    action decap_ipinip_inner_ipv4() {
        hdr.ethertype.ether_type = 16w0x0800;
        strip_ip_header();
    }

    action decap_ipinip_inner_ipv6() {
        hdr.ethertype.ether_type = 16w0x86dd;
        strip_ip_header();
    }

    action decap_ipinip_with_mpls() {
        strip_ip_header();
    }

    table tunnel_decap {
        key = {
            eg_md.header_strip_config : ternary;

            hdr.mpls[0].isValid() : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            eg_md.inner_ip_type : ternary;

            hdr.vxlan.isValid() : ternary;
            hdr.gre.isValid() : ternary;
            hdr.gtpu.isValid() : ternary;
        }

        actions = {
            NoAction;
            decap_vxlan;

            decap_gre_inner_ipv4;
            decap_gre_inner_ipv6;
            decap_gre_with_mpls;

            decap_gtp_inner_ipv4;
            decap_gtp_inner_ipv6;
            decap_gtp_with_mpls;

            decap_ipinip_inner_ipv4;
            decap_ipinip_inner_ipv6;
            decap_ipinip_with_mpls;
        }

        const default_action = NoAction;






        const entries = {
            (SWITCH_HEADER_STRIP_VXLAN &&& SWITCH_HEADER_STRIP_VXLAN , _, _, _, _, true, _, _) : decap_vxlan;

            (SWITCH_HEADER_STRIP_GRE &&& SWITCH_HEADER_STRIP_GRE , true, _, _, _, _, true, _) : decap_gre_with_mpls;
            (SWITCH_HEADER_STRIP_GRE &&& SWITCH_HEADER_STRIP_GRE , _, _, _, IP_TYPE_IPV4, _, true, _) : decap_gre_inner_ipv4;
            (SWITCH_HEADER_STRIP_GRE &&& SWITCH_HEADER_STRIP_GRE , _, _, _, IP_TYPE_IPV6, _, true, _) : decap_gre_inner_ipv6;

            (SWITCH_HEADER_STRIP_GTP &&& SWITCH_HEADER_STRIP_GTP , true, _, _, _, _, _, true) : decap_gtp_with_mpls;
            (SWITCH_HEADER_STRIP_GTP &&& SWITCH_HEADER_STRIP_GTP , _, _, _, IP_TYPE_IPV4, _, _, true) : decap_gtp_inner_ipv4;
            (SWITCH_HEADER_STRIP_GTP &&& SWITCH_HEADER_STRIP_GTP , _, _, _, IP_TYPE_IPV6, _, _, true) : decap_gtp_inner_ipv6;

            (SWITCH_HEADER_STRIP_IPINIP &&& SWITCH_HEADER_STRIP_IPINIP, true, _, _, _, _, _, _) : decap_ipinip_with_mpls;
            (SWITCH_HEADER_STRIP_IPINIP &&& SWITCH_HEADER_STRIP_IPINIP, _, _, _, IP_TYPE_IPV4, _, _, _) : decap_ipinip_inner_ipv4;
            (SWITCH_HEADER_STRIP_IPINIP &&& SWITCH_HEADER_STRIP_IPINIP, _, _, _, IP_TYPE_IPV6, _, _, _) : decap_ipinip_inner_ipv6;
        }
    }

    apply {
        tunnel_decap.apply();
    }
}

control EgressDecap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action set_header_strip(switch_header_strip_config_t config) {
        eg_md.header_strip_config = config;
    }

    table header_strip_config_tbl {
        key = {
            eg_md.port : ternary;
        }

        actions = {
            set_header_strip;
        }

        size = 256;
    }

    VlanDecap() vlan_decap;
    MplsDecap() mpls_decap;
    TunnelDecap() tunnel_decap;

    apply {
       header_strip_config_tbl.apply();

       if ((eg_md.header_strip_config & SWITCH_HEADER_STRIP_VLAN != 0)) {
           vlan_decap.apply(hdr, eg_md);
       }

       if ((eg_md.header_strip_config & SWITCH_HEADER_STRIP_MPLS != 0)) {
           mpls_decap.apply(hdr, eg_md);
       }
       if ((eg_md.header_strip_config & SWITCH_HEADER_STRIP_TUNNEL != 0)) {
           tunnel_decap.apply(hdr, eg_md);
       }
    }
}
# 13 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/header_encap.p4" 1
control PvlanEncap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    @name(".vlan_add")action add_pvlan_tag() {
        hdr.pvlan.setValid();
        hdr.pvlan.tpid = 0x8100;
        hdr.pvlan.vid = (bit<12>)eg_md.ingress_ifindex;
    }

    table pvlan_encap {
        key = {
            eg_md.ingress_port : ternary;
        }

        actions = {
            NoAction;
            add_pvlan_tag();
        }
        const default_action = NoAction;
    }

    apply {
        pvlan_encap.apply();
    }
}

control FvlanEncap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action add_fvlan_tag() {
        hdr.fvlan.setValid();
        hdr.fvlan.tpid = 0x9000;
        hdr.fvlan.modport = eg_md.ingress_ifindex;
    }

    table t {
        actions = {
            add_fvlan_tag();
        }
        const default_action = add_fvlan_tag;
    }

    apply {
        if (eg_md.to_cpu == 1) {
            t.apply();
        }
    }
}

control FabricEncap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    @name(".add_fabric")action add_fabric() {
        hdr.fabric.setValid();
        hdr.fabric.type_ = 0xEB00;
        hdr.fabric.modport = eg_md.egress_modport;
        hdr.fabric.outer_hash = eg_md.outer_hash;
        hdr.fabric.inner_hash = eg_md.inner_hash;
    }

    table t {
        key = {
            eg_md.port: ternary;
        }
        actions = {
            add_fabric();
            NoAction;
        }
        const default_action = NoAction;
    }

    apply {
        t.apply();
    }
}

control TunnelGreEncap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md){


    action ipv4_gre_outer_add(mac_addr_t src_addr, mac_addr_t dst_addr, ipv4_addr_t sip, ipv4_addr_t dip){
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
  hdr.ethertype.ether_type = 16w0x0800;
  hdr.ogre_ipv4.setValid();
        hdr.ogre_ipv4.version = 4;
        hdr.ogre_ipv4.ihl = 5;
        hdr.ogre_ipv4.ttl = 255;
        hdr.ogre_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.ogre_ipv4.src_addr = sip;
        hdr.ogre_ipv4.dst_addr = dip;
        hdr.ogre_ipv4.protocol = 47;
        hdr.ogre_ipv4.total_len = hdr.ipv4.total_len + 16w24;
        hdr.ogre.setValid();
        hdr.ogre.proto = 16w0x0800;
 }


    action ipv6_gre_outer_add(mac_addr_t src_addr, mac_addr_t dst_addr,ipv4_addr_t sip, ipv4_addr_t dip){
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
  hdr.ethertype.ether_type = 16w0x0800;
        hdr.ogre_ipv4.setValid();
        hdr.ogre_ipv4.version = 4;
        hdr.ogre_ipv4.ihl = 5;
        hdr.ogre_ipv4.ttl = 255;
        hdr.ogre_ipv4.src_addr = sip;
        hdr.ogre_ipv4.dst_addr = dip;
        hdr.ogre_ipv4.protocol = 47;
        hdr.ogre_ipv4.total_len = hdr.ipv6.payload_len + 16w64;
        hdr.ogre.setValid();
        hdr.ogre.proto = 16w0x086dd;
 }

 table gre_tnl_tbl{
  key = {
   eg_md.gre_tnl_id : ternary;
            hdr.ipv4.isValid(): ternary;
            hdr.ipv6.isValid(): ternary;
  }
  actions = {
            NoAction;
            ipv4_gre_outer_add;
            ipv6_gre_outer_add;
        }

        const default_action = NoAction;
 }

 apply {
        if(eg_md.header_encap_gre_enable == 1){
      gre_tnl_tbl.apply();
        }
 }


    //action set_header_gre_encap_enable() {
    //    ig_md.header_encap_gre_enable = 1;
    //}

    //action set_header_gre_encap_disable() {
    //    ig_md.header_encap_gre_enable = 0;
    //}
 }

control SmacModify(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    @name(".mac_modify")action modify_smac() {
        hdr.ethernet.src_addr = (mac_addr_t)eg_md.ingress_ifindex;
    }

    table t {
        actions = {
            NoAction;
            modify_smac();
        }
        default_action = NoAction;
    }

    apply {
        if (eg_md.ingress_port_type == SWITCH_PORT_TYPE_NORMAL) {
            t.apply();
        }
    }
}

control MirrorEncap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md) {

    @name(".sflow_encap")action sflow_encap(mac_addr_t src_addr, mac_addr_t dst_addr,
                                 ipv4_addr_t sip, ipv4_addr_t dip, bit<16> src_port, bit<16> dst_port) {
        hdr.ethernet.setValid();
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.fvlan.setValid();
        hdr.fvlan.tpid = 0x9000;
        hdr.fvlan.modport = eg_md.ingress_ifindex;
        hdr.ethertype.setValid();
        hdr.ethertype.ether_type = 16w0x0800;
        hdr.ipv4.version = 4;
        hdr.ipv4.ihl = 5;
        hdr.ipv4.ttl = 255;
        hdr.ipv4.setValid();
        hdr.ipv4.src_addr = sip;
        hdr.ipv4.dst_addr = dip;
        hdr.ipv4.protocol = 8w0x11;
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.length = eg_intr_md.pkt_length-3;
    }
    table t {
        actions = {
            sflow_encap;
        }
    }

    apply {
        t.apply();
    }
}
# 14 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 1 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/sflow.p4" 1
struct switch_sflow_info_t {
    bit<32> current;
    bit<32> rate;
}

control IngressSflow(inout switch_ingress_metadata_t ig_md) {
    const bit<32> sflow_session_size = 512;

    Register<switch_sflow_info_t, bit<32>>(sflow_session_size) samplers;
    RegisterAction<switch_sflow_info_t, bit<9>, bit<1>>(samplers) sample_packet = {
        void apply(inout switch_sflow_info_t reg, out bit<1> flag) {
            if (reg.rate != 0) {
                if (reg.current > 1) {
                    reg.current = reg.current - 1;
                    flag = 0;
                } else {
                    reg.current = reg.rate;
                    flag = 1;
                }
            } else {
                flag = 0;
            }
        }
    };

    @name(".sflow_dst_set")action sflow_mirror(switch_mirror_session_t session_id) {
        ig_md.session_id = session_id;
        ig_md.src_type = SWITCH_MIRROR_TYPE;
    }

    table t {
        actions = {
            sflow_mirror;
        }
    }

    apply {
        ig_md.sample_packet = sample_packet.execute(ig_md.ingress_port);
        if (ig_md.sample_packet == 1) {
            t.apply();
        }
    }
}
# 15 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4" 2
# 32 "/home/liubin/P4-TOFINO-YDFL/p4_16_src/tna_ydfl.p4"
// Bridged metadata fields for Egress pipeline.
action add_bridged_md(inout switch_bridged_metadata_h bridged_md,
                      in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.type = SWITCH_BRIDGED_TYPE;
    bridged_md.ingress_port = ig_md.ingress_port;
    //bridged_md.ingress_tunnel_type = ig_md.tunnel_type;
    bridged_md.port_type = ig_md.port_type;
    bridged_md.header_strip_enable = ig_md.header_strip_enable;
    bridged_md.header_encap_gre_enable = ig_md.port.header_encap_gre_enable;
    bridged_md.to_cpu = ig_md.to_cpu;
    bridged_md.ingress_ifindex = ig_md.ingress_ifindex;
    bridged_md.gre_tnl_id = ig_md.port.gre_tnl_id;
    bridged_md.egress_modport = ig_md.modport;
    bridged_md.outer_hash = ig_md.outer_enhanced_hash_0;
    bridged_md.inner_hash = ig_md.inner_enhanced_hash_0;
}

control NpPktPorcess(inout switch_header_t hdr,
                     inout switch_ingress_metadata_t ig_md) {
    SystemTcamAcl() system_acl;
    bit<16> modport = 0;
    Random<switch_hash_t>() rand_hash;

    apply {
        modport[9:0] = hdr.fvlan.modport[9:0];
        modport[12:10] = hdr.fvlan.modport[15:13];

        ig_md.random_hash = rand_hash.get();
        //ig_md.enhanced_hash_0   = hdr.fvlan.modport;
        system_acl.apply(hdr,ig_md,ig_md.system_tcam_acl_res_md, modport);
        hdr.fvlan.setInvalid();
  ig_md.outer_sip_hash = ig_md.np_hash;
  ig_md.outer_dip_hash = ig_md.np_hash;
  ig_md.outer_ip_hash = ig_md.np_hash;
        ig_md.outer_enhanced_hash_0 = ig_md.np_hash;
    }
}

control FabricPktPorcess(inout switch_header_t hdr,
                         inout switch_ingress_metadata_t ig_md) {
    bit<1> mcast = 0;
    Random<switch_hash_t>() rand_hash;
    apply {
        mcast = hdr.fabric.modport[15:15];
        ig_md.random_hash = rand_hash.get();
        if (mcast == 1) {
            acl_action(ig_md.system_tcam_acl_res_md, 1, 8, hdr.fabric.modport & 0x7FFF, 262143);
        } else {
            acl_action(ig_md.system_tcam_acl_res_md, 5, 8, hdr.fabric.modport, 262143);
        }
        ig_md.outer_enhanced_hash_0 = hdr.fabric.outer_hash;
        ig_md.inner_enhanced_hash_0 = hdr.fabric.inner_hash;
        hdr.fabric.setInvalid();
    }
}

control GreTermProcess(in switch_header_t hdr,
                       inout switch_ingress_metadata_t ig_md) {
    table t {
        actions = {
            acl_action(ig_md.system_tcam_acl_res_md);
        }
        default_action = acl_action(ig_md.system_tcam_acl_res_md, 5, 7, 4384, 262143);
    }

    apply {
        if (ig_md.port.gre_term_en == 1) {
            if(hdr.arp.isValid() || hdr.icmp.isValid()) {
                t.apply();
                ig_md.to_cpu = 1;
            }
        }
    }
}

control GreEncapFwdProcess(in switch_header_t hdr,
                           inout switch_ingress_metadata_t ig_md){

    table gre_tnl_fwd_tbl{
        key= {
            ig_md.port.gre_tnl_id : ternary;
        }
        actions = {
            acl_action(ig_md.system_tcam_acl_res_md);
        }
    }
    apply{
        gre_tnl_fwd_tbl.apply();
    }
}

control Ingress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    NpPktPorcess() np_pkt_process;
    FabricPktPorcess() fabric_pkt_process;

    PktValidation() pkt_validation;
    InnerPktValidation() inner_pkt_validation;

    PacketStat() packet_stat;

    BasicAcl(2048) basic_acl;
    AdvancedAcl(1024, 1024, (24 * 1024), (10 * 1024)) advanced_acl;
    AclActionPerform() acl_action_perform;

    LagHash() lag_hash;
    McastHash() mcast_hash;
    LAG() lag;
    ModMap() mod_map;
    GreTermProcess() gre_term;
    GreEncapFwdProcess() gre_encap_fwd;


    IngressSflow() ing_sflow;


    apply {

        if (hdr.fvlan.isValid()) {
            np_pkt_process.apply(hdr, ig_md);
        } else if (hdr.fabric.isValid()){
            fabric_pkt_process.apply(hdr, ig_md);
        } else {
            pkt_validation.apply(hdr, ig_md, ig_md.outer_lkp);
            inner_pkt_validation.apply(hdr, ig_md, ig_md.inner_lkp);

            packet_stat.apply(hdr, ig_md);

            basic_acl.apply(hdr, ig_md, ig_tm_md);
            advanced_acl.apply(hdr, ig_md, ig_tm_md);
            gre_term.apply(hdr, ig_md);
        }


        ing_sflow.apply(ig_md);


        gre_encap_fwd.apply(hdr, ig_md);
        acl_action_perform.apply(ig_md, ig_tm_md, ig_dprsr_md);

        if (ig_md.acl_res_md.action_type == 2) {
            ig_dprsr_md.drop_ctl = 1;
        } else {
            if(ig_md.acl_res_md.action_type == 5) {
                ig_md.modport = ig_md.acl_res_md.action_data;
            } else {
                lag_hash.apply(hdr, ig_md, ig_tm_md);
                mcast_hash.apply(hdr, ig_md, ig_tm_md);
                lag.apply(hdr, ig_md, ig_tm_md);
            }
            mod_map.apply(ig_md, ig_tm_md);
        }
        ig_tm_md.bypass_egress = 1w0;
        add_bridged_md(hdr.bridged_md, ig_md);
    }

}

control IngressMirror(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    Mirror() mirror;

    apply {
        if (ig_dprsr_md.mirror_type == 3w1) {
            mirror.emit<switch_mirror_metadata_h>(ig_md.session_id,
                 {
                 ig_md.src_type,
                 ig_md.ingress_ifindex
                 });
       }
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control IngressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {


    IngressMirror() mirror;


    apply {

         mirror.apply(hdr, ig_md, ig_dprsr_md);

         pkt.emit(hdr);
    }
}

control Egress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    EgressDecap() egress_decap;
    PvlanEncap() pvlan_encap;
    FvlanEncap() fvlan_encap;
    FabricEncap() fabric_encap;
    MirrorEncap() mirror_encap;


    TunnelGreEncap() egress_gre_encap;

    SmacModify() smac_modify;

    apply {
        if (hdr.bridged_md.isValid()) {
            if (hdr.bridged_md.header_strip_enable == 1) {
                egress_decap.apply(hdr, eg_md);
            }
            pvlan_encap.apply(hdr, eg_md);
     fvlan_encap.apply(hdr, eg_md);
     fabric_encap.apply(hdr, eg_md);


            if(hdr.bridged_md.header_encap_gre_enable == 1) {
                egress_gre_encap.apply(hdr, eg_md);
            }

            smac_modify.apply(hdr, eg_md);
            hdr.bridged_md.setInvalid();
        } else {
            mirror_encap.apply(hdr, eg_md, eg_intr_md);
        }
    }
}

control EgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {

    Checksum() ipv4_checksum;
    apply {
        hdr.ogre_ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ogre_ipv4.version,
            hdr.ogre_ipv4.ihl,
            hdr.ogre_ipv4.diffserv,
            hdr.ogre_ipv4.total_len,
            hdr.ogre_ipv4.identification,
            hdr.ogre_ipv4.flags,
            hdr.ogre_ipv4.frag_offset,
            hdr.ogre_ipv4.ttl,
            hdr.ogre_ipv4.protocol,
            hdr.ogre_ipv4.src_addr,
            hdr.ogre_ipv4.dst_addr});
        pkt.emit(hdr);
    }
}

Pipeline(IngressParser(),
         Ingress(),
         IngressDeparser(),
         EgressParser(),
         Egress(),
         EgressDeparser()) pipe;
Switch(pipe) main;
