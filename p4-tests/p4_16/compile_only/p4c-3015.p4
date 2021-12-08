# 1 "/vm_share/tofino-bvr/tofino_bvr.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/vm_share/tofino-bvr/tofino_bvr.p4"
# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/core.p4" 1
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
# 2 "/vm_share/tofino-bvr/tofino_bvr.p4" 2



# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/core.p4" 1
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
# 23 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tna.p4" 2
# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/core.p4" 1
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
# 23 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tofino.p4" 2

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
# 24 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tna.p4" 2

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
# 6 "/vm_share/tofino-bvr/tofino_bvr.p4" 2


# 1 "/vm_share/tofino-bvr/include/headers.p4" 1



// pa_no_overlay is to workaround some header fields are modified unexpectedly.
@pa_no_overlay("ingress", "hdr.ipv4.diffserv")
@pa_no_overlay("ingress", "hdr.ipv4.dst_addr")
@pa_no_overlay("ingress", "hdr.arp.dst_ip")
@pa_no_overlay("ingress", "hdr.vxlan.vni")
@pa_no_overlay("ingress", "hdr.vxlan.reserved2")
@pa_no_overlay("ingress", "hdr.vxlan.flags")
@pa_no_overlay("ingress", "hdr.vxlan.reserved")
@pa_no_overlay("ingress", "hdr.inner_arp.dst_ip")
@pa_no_overlay("ingress", "hdr.inner_arp.src_addr")
@pa_no_overlay("ingress", "hdr.inner_ipv4.src_addr")
@pa_no_overlay("ingress", "hdr.inner_ipv4.dst_addr")
@pa_no_overlay("ingress", "hdr.inner_tcp.flags")
@pa_no_overlay("ingress", "hdr.inner_ethernet.src_addr")
@pa_no_overlay("ingress", "hdr.inner_ethernet.dst_addr")

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> l4_port_t;
typedef bit<16> arp_op_t;
typedef bit<8> icmp_type_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMPV4 = 1;
const ip_protocol_t IP_PROTOCOLS_ICMPV6 = 58;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_TTM = 193;

const bit<32> IP_PROTOCOLS_TTM_LEN = 8; // in octets

const arp_op_t ARPOP_ARP_REQUEST = 16w0x0001;
const arp_op_t ARPOP_ARP_REPLY = 16w0x0002;

const icmp_type_t ICMP_TYPE_REQUEST = 8w0x08;
const icmp_type_t ICMP_TYPE_REPLY = 8w0x00;
const bit<16> ICMPV4_REQUEST_INCREMENTAL_CHECKSUM_UPDATE = 16w0x0800;

// used to identify packet source
typedef bit<2> pkt_src_t;
const pkt_src_t PKT_SRC_BRIDGED = 0;
const pkt_src_t PKT_SRC_CLONED_INGRESS = 1;
const pkt_src_t PKT_SRC_CLONED_EGRESS = 2;

typedef bit<8> tcp_flags_t;
const tcp_flags_t TCP_FLAG_NON = 0x00;
const tcp_flags_t TCP_FIN_FLAG = 0x01;
const tcp_flags_t TCP_SYN_FLAG = 0x02;
const tcp_flags_t TCP_RST_FLAG = 0x04;
const tcp_flags_t TCP_PSH_FLAG = 0x08;
const tcp_flags_t TCP_ACK_FLAG = 0x10;
const tcp_flags_t TCP_URG_FLAG = 0x20;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
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
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv4_options_h {
    bit<32> options;
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
    bit<8> type;
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
    mac_addr_t src_addr;
    ipv4_addr_t src_ip;
    mac_addr_t dst_addr;
    ipv4_addr_t dst_ip;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

header fabric_header_t {
    bit<3> packetType;
    bit<2> headerVersion;
    bit<2> packetVersion;
    bit<1> pad1;

    bit<3> fabricColor;
    bit<5> fabricQos;

    bit<8> dstDevice;
    bit<16> dstPortOrGroup;
}

header fabric_header_cpu_t {
    bit<5> egressQueue;
    bit<1> txBypass;
    bit<2> reserved;

    bit<16> ingressPort;
    bit<16> ingressIfindex;
    bit<16> ingressBd;

    bit<16> reasonCode;
}

header fabric_payload_header_t {
    ether_type_t ether_type;
}

header mirror_header_t {
    pkt_src_t pkt_type;
    bit<6> pad;
}

struct header_t {
    ethernet_h ethernet;
    fabric_header_t fabric_header;
    fabric_header_cpu_t fabric_header_cpu;
    fabric_payload_header_t fabric_payload_header;
    vlan_tag_h vlan_tag;
    arp_h arp;
    ipv4_h ipv4;
    //ipv4_options_h ipv4_opts;
    ipv6_h ipv6;
    icmp_h icmpv4;
    tcp_h tcp;
    udp_h udp;
    vxlan_h vxlan;
    ethernet_h inner_ethernet;
    vlan_tag_h inner_vlan_tag;
    arp_h inner_arp;
    ipv6_h inner_ipv6;
    ipv4_h inner_ipv4;
    ipv4_options_h inner_ipv4_opts1;
    ipv4_options_h inner_ipv4_opts2;
    ipv4_options_h inner_ipv4_opts3;
    ipv4_options_h inner_ipv4_opts4;
    ipv4_options_h inner_ipv4_opts5;
    ipv4_options_h inner_ipv4_opts6;
    ipv4_options_h inner_ipv4_opts7;
    ipv4_options_h inner_ipv4_opts8;
    ipv4_options_h inner_ipv4_opts9;
    ipv4_options_h inner_ipv4_opts10;
    icmp_h inner_icmpv4;
    icmp_h inner_icmpv6;
    tcp_h inner_tcp;
    udp_h inner_udp;

    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}
# 9 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/include/tbvr_metadata.p4" 1




// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> u32_t;
typedef bit<16> u16_t;
typedef bit<8> u8_t;

typedef bit<24> vpc_id_t;
typedef bit<24> vni_t;

typedef bit<8> bit_ex_flag_t;

typedef bit<1> bit_flag_t;
typedef mac_addr_t vport_id_t;
typedef PortId_t switch_port_t;


typedef bit<3> mirror_type_t;




const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;


// ----------------------------------------------------------------------------
// enum types
//-----------------------------------------------------------------------------
enum bit<8> msg_type_t {
    MSG_TYPE_ETHERNET = 0x0,
    MSG_TYPE_ARP_REQUEST = 0x1, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_ARP_REPLY = 0x2, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_ARP_OTHERS = 0x3, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_IPV4 = 0x4, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_IPV6 = 0x5, // used by inner_l3_msg_type in parser
    MSG_TYPE_ICMPV4_REQUEST = 0x6, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_ICMPV4_REPLY = 0x7, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_ICMPV4_OTHERS = 0x8, // used by outer_msg_type/inner_l3_msg_type in parser
    MSG_TYPE_TCP = 0x9, // used by inner_l4_msg_type in parser
    MSG_TYPE_UDP = 0xa, // used by outer_msg_type/inner_l4_msg_type in parser
    MSG_TYPE_VXLAN = 0xb, // used by outer_msg_type in parser
    MSG_TYPE_UDP_TTM = 0xc,
    MSG_TYPE_OTHERS = 0xd // used by inner_l4_msg_type in parser
}

enum bit<8> vport_type_t {
    VPORT_TYPE_VXLAN = 0x0,
    VPORT_TYPE_UNDERLAY = 0x1
}

enum bit<3> packet_type_t {
    OTHERS = 0x0,
    LOCAL_IP = 0x1,
    GATEWAY_IP = 0x2,
    VTEP_IP = 0x3, // NOTE(huangbing01): add FWD_VTEP_IP?
    PHY_VPORT_IP = 0x4,
    FLOATING_IP = 0x5
}

enum bit<8> forward_type_t {
    FORWARD_NORMAL = 0x0,
    FORWARD_TO_CPU = 0x1,
    FORWARD_TO_X86_BVR = 0x2,
    FORWARD_VTEP_REPLY_ICMPV4 = 0x3,
    FORWARD_GW_REPLY_ICMPV4 = 0x4,
    FORWARD_GW_REPLY_ARP = 0x5,
    FORWARD_DROP = 0x6,
    FORWARD_ABNORMAL = 0x7
}

enum bit<8> route_type_t {
    ROUTE_TYPE_INIT = 0x0,
    ROUTE_TYPE_DIRECT = 0x1,
    ROUTE_TYPE_LOCAL = 0x2,
    ROUTE_TYPE_CUSTOM = 0x3,
    ROUTE_TYPE_ECMP = 0x4,
    ROUTE_TYPE_PUBLIC = 0x5,
    ROUTE_TYPE_DEFAULT = 0x6
}

enum bit<1> dscp_switch_type_t {
    DSCP_SWITCH_OFF = 0x0,
    DSCP_SWITCH_ON = 0x1
}

enum bit<1> active_access_flag_t {
    ACTIVE_ACCESS_DISABLE = 0x0,
    ACTIVE_ACCESS_ENABLE = 0x1
}

enum bit<1> egress_by_pass_t {
    EGRESS_BYPASS_NONE = 0x0,
    EGRESS_BYPASS_MIRROR_ACL = 0x1
}

// ----------------------------------------------------------------------------
// tbvr types
//-----------------------------------------------------------------------------
struct pkt_info_metadata_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    msg_type_t outer_msg_type; // enum msg_type_t
    msg_type_t inner_l3_msg_type; // enum msg_type_t
    msg_type_t inner_l4_msg_type; // enum msg_type_t
    u8_t is_active_access;
}

struct vpc_metadata_t {
    vpc_id_t vpc_id; // VPC ID
    mac_addr_t vport_mac; // used for replying an arp request to a vport

    vport_type_t in_vport_type; // vport type of in vport
    vport_type_t out_vport_type; // vport type of out vport

    bit_ex_flag_t public_route_switch; // if 1, means should match against public route, else not
    mac_addr_t share_vport_mac; // mac of a shared vport
}

@pa_container_size("ingress", "ig_md.bvr_md.lkp_md.l4_src_port", 16)
@pa_container_size("ingress", "ig_md.bvr_md.lkp_md.l4_dst_port", 16)
struct lookup_fields_t {
    ipv4_addr_t ip_src_addr;
    ipv4_addr_t ip_dst_addr;
    u16_t l4_src_port;
    u16_t l4_dst_port;
    u8_t ip_proto;
}

struct mirror_metadata_t {
    pkt_src_t pkt_type;
    ipv4_addr_t remote_ip;
}

struct egress_mirror_metadata_t {
    pkt_src_t pkt_type;
}

struct route_metadata_t {
    ipv4_addr_t next_hop;
    vni_t next_vni;
    route_type_t route_type;
    mac_addr_t new_src_mac;
}

struct ingress_forward_metadata_t {
    ipv4_addr_t fwd_x86_vtep_ip; // fwd_x86_vtep_ip
    u16_t fwd_x86_vtep_port; // fwd_x86_vtep_port

    forward_type_t fwd_type_of_parser; // see enum bit<8> forward_type_t, for parser module
    forward_type_t fwd_type_of_force_to_x86;// see enum bit<8> forward_type_t, for forward module
    forward_type_t fwd_type_of_vpc; // see enum bit<8> forward_type_t, for vpc module
    forward_type_t fwd_type_of_acl; // see enum bit<8> forward_type_t, for acl module
    forward_type_t fwd_type_of_route; // see enum bit<8> forward_type_t, for route module
    forward_type_t fwd_type; // see enum bit<8> forward_type_t

    dscp_switch_type_t vpc_dscp_switch; // switch of dscp for vpc
    dscp_switch_type_t vport_dscp_switch; // switch of dscp for vport
    u8_t vpc_dscp; // forward dscp of vpc
    u8_t vport_dscp; // forward dscp of vport
    u8_t out_dscp; // dscp in the out packet
}

struct ingress_bvr_metadata_t {
    pkt_info_metadata_t pkt_md; // metadata of packet
    vpc_metadata_t vpc_md; // metadata of vpc
    lookup_fields_t lkp_md; // metadata of look up for acl and mirror
    mirror_metadata_t mirror_md; // metadata of mirror
    route_metadata_t route_md; // metadata of route
    ingress_forward_metadata_t fwd_md; // metadata of forward
}

@pa_container_size("egress", "eg_md.bvr_md.fwd_vtep_port", 16)
struct egress_bvr_metadata_t {
    mac_addr_t outer_src_mac; // outer source mac address
    mac_addr_t outer_dst_mac; // outer destination mac address
    ipv4_addr_t outer_src_addr; // outer source IPv4 address
    ipv4_addr_t outer_dst_addr; // outer destination IPv4 address
    mac_addr_t inner_src_mac; // inner source mac address
    mac_addr_t inner_dst_mac; // inner destination mac address
    ipv4_addr_t inner_src_addr; // inner source IPv4/ARP address
    ipv4_addr_t inner_dst_addr; // inner destination IPv4/ARP address
    mac_addr_t overlay_dst_mac; // overlay destination mac address
    ipv4_addr_t fwd_vtep_ip; // fwd_vtep_ip
    u16_t fwd_vtep_port; // fwd_vtep_port 4789
}

//NOTE(yangguang22): can not define in headers.p4
@pa_container_size("ingress", "ig_md.custom_bridge_hdr.l4_src_port", 16)
@pa_container_size("ingress", "ig_md.custom_bridge_hdr.l4_dst_port", 16)
@pa_container_size("egress", "eg_md.custom_bridge_hdr.l4_src_port", 16)
@pa_container_size("egress", "eg_md.custom_bridge_hdr.l4_dst_port", 16)
@pa_container_size("egress", "eg_md.custom_bridge_hdr.is_active_access", 8)
header custom_bridge_h {
    //from-IngressParser
    msg_type_t inner_l3_msg_type;

    //from-Vpc
    vpc_id_t vpc_id;
    mac_addr_t vport_mac;

    //TODO(yangguang22):for tmp, with vpc
    //mac_addr_t vport_mac2;  // it is the same with vport_mac, workaround compiler bug.

    //from-Route
    ipv4_addr_t next_hop;
    bit<24> next_vni;
    route_type_t route_type;
    mac_addr_t new_src_mac;
    vport_type_t out_vport_type;

    //from-Forward
    forward_type_t fwd_type;
    ipv4_addr_t fwd_x86_vtep_ip;
    u16_t fwd_x86_vtep_port;
    u8_t out_dscp;

    //from-Acl
    u8_t is_active_access;
    u8_t ip_proto;
    u16_t l4_src_port;
    u16_t l4_dst_port;

    //from-parser
    u16_t checksum_udp_tmp;
}

struct ingress_metadata_t {
    ingress_bvr_metadata_t bvr_md;
    custom_bridge_h custom_bridge_hdr;
    MirrorId_t mirror_session_id; //Tofino bug, must set at here
}

struct egress_metadata_t {
    egress_mirror_metadata_t eg_mirror_md;
    MirrorId_t mirror_session_id; //Tofino bug, must set at here
    egress_by_pass_t by_pass;
    custom_bridge_h custom_bridge_hdr;
    egress_bvr_metadata_t bvr_md;
}
# 10 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/include/tbvr_common.p4" 1



# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/core.p4" 1
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
# 5 "/vm_share/tofino-bvr/include/tbvr_common.p4" 2
# 1 "/sde/bf-sde-9.1.1/install/share/p4c/p4include/tna.p4" 1
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
# 6 "/vm_share/tofino-bvr/include/tbvr_common.p4" 2

# 1 "/vm_share/tofino-bvr/include/headers.p4" 1
# 8 "/vm_share/tofino-bvr/include/tbvr_common.p4" 2
# 1 "/vm_share/tofino-bvr/include/tbvr_defines.p4" 1



/*
 * To save sram, we only enable arp_fdb counter during testing.
 * For production, we MUST "undef TESTING_MODE"
 * For testing, we MUST "define TESTING_MODE",
 * and we MUST set OVERLAY_ARP_FDB_TABLE_SIZE = 100000;
 */

// For testing use
// arp_fdb with counter, maximum arp_fdb number is 100000.
const bit<32> OVERLAY_ARP_FDB_TABLE_SIZE = 100000;
# 34 "/vm_share/tofino-bvr/include/tbvr_defines.p4"
const bit<16> VTEP_PORT = 16w4789;
const bit<8> VXLAN_FLAGS = 8w0x08;

const bit<48> ETHER_BROADCAST_MAC = 48w0xFFFFFFFFFFFF;
const bit<8> ETHER_MULTICAST_MAC_HIGH8_MASK = 8w0x01; // including BROADCAST
const bit<24> ETHER_MULTICAST_MAC_FOR_IPV4 = 24w0x01005E; // RFC 1112
const bit<8> ETHER_UNICAST_MAC = 8w0x01;
const bit<9> TOFINO_CPU_PCIE_PORT = 9w192;

const bit<3> FABRIC_HEADER_TYPE_CPU = 3w5;
const bit<16> ETHERTYPE_BF_FABRIC = 16w0x9000;


const bit<32> UNDERLAY_PACKET_TYPE_TABLE_SIZE = 96;
const bit<32> VPC_CONF_TABLE_SIZE = 64;
const bit<32> VPORT_TO_VPC_TABLE_SIZE = VPC_CONF_TABLE_SIZE * 10;
const bit<32> FLOATING_IP_TABLE_SIZE = 8; //NOTE(huangbing01):not used for now, set a small size
const bit<32> VPORT_ARP_TABLE_SIZE = VPC_CONF_TABLE_SIZE * 10;
const bit<32> VPORT_IN_TABLE_SIZE = VPC_CONF_TABLE_SIZE * 10;
const bit<32> VPORT_OUT_TABLE_SIZE = VPC_CONF_TABLE_SIZE * 10;

const bit<32> INGRESS_ACL_TABLE_SIZE = (512 + VPC_CONF_TABLE_SIZE * 8);
const bit<32> EGRESS_ACL_TABLE_SIZE = (512 + VPC_CONF_TABLE_SIZE * 8);

const bit<32> MIRROR_ACL_TABLE_SIZE = 10;

const bit<32> VPC_OUT_COUNTER_TABLE_SIZE = VPC_CONF_TABLE_SIZE * 8;
const bit<32> OVERLAY_PUBLIC_ROUTE_TABLE_SIZE = 512;
const bit<32> OVERLAY_ROUTE_TABLE_SIZE = (OVERLAY_PUBLIC_ROUTE_TABLE_SIZE + VPC_CONF_TABLE_SIZE * 64);
const bit<32> OVERLAY_ECMP_TABLE_SIZE = 256;

const bit<32> ECMP_MAX_GROUP_SIZE = 200;
const bit<32> ECMP_NUM_GROUPS = 256;

const bit<32> MERGE_FWD_TYPE_TABLE_SIZE = 256;

const bit<3> TBVR_PACKET_DROP_FLAG = 0x1;
const bit<3> TBVR_PACKET_NO_DROP_FLAG= 0x0;

const bit<24> ROUTE_PUBLIC_MAC_FLAG = 24w0xFA_17_3E;

const bit<16> SRC_PORT_MIN = 1024;
# 9 "/vm_share/tofino-bvr/include/tbvr_common.p4" 2
# 1 "/vm_share/tofino-bvr/include/tbvr_metadata.p4" 1
# 10 "/vm_share/tofino-bvr/include/tbvr_common.p4" 2


action forward_x86(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_TO_X86_BVR;
}

action forward_normal(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_NORMAL;
}

action forward_gw_reply_arp(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_GW_REPLY_ARP;
}

action forward_vtep_reply_icmpv4(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_VTEP_REPLY_ICMPV4;
}

action forward_drop(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_DROP;
}

action forward_abnormal(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_ABNORMAL;
}

action forward_cpu(inout forward_type_t fwd_type) {
    fwd_type = forward_type_t.FORWARD_TO_CPU;
}

/*
 * forward packet from CPU PCIE port to physical port
 *
 * |ethernet|fabric_header|fabric_header_cpu|fabric_payload_header|ip|tcp/udp|payload|
 * -->
 * |ethernet|ip|tcp/udp|payload|
 *
 */
action forward_pkts_from_cpu_to_physical_port(inout header_t hdr,
                                              out ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{

    hdr.fabric_header.setInvalid();

    ig_tm_md.ucast_egress_port = (bit<9>)hdr.fabric_header_cpu.ingressPort;
    hdr.fabric_header_cpu.setInvalid();

    hdr.ethernet.ether_type = hdr.fabric_payload_header.ether_type;
    hdr.fabric_payload_header.setInvalid();

    ig_tm_md.bypass_egress = 1w1;
}

/*
 * forward packet from dataplane to CPU PCIE port
 *
 * |ethernet|ip|tcp/udp|payload|
 * -->
 * |ethernet|fabric_header|fabric_header_cpu|fabric_payload_header|ip|tcp/udp|payload|
 *
 */
action ingress_forward_pkts_from_physical_port_to_cpu(inout header_t hdr,
                                              in bit<16> ingress_port,
                                              out ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    hdr.fabric_header.setValid();
    hdr.fabric_header.packetType = FABRIC_HEADER_TYPE_CPU;
    hdr.fabric_header.headerVersion = 0;
    hdr.fabric_header.packetVersion = 0;
    hdr.fabric_header.pad1 = 0;
    hdr.fabric_header.fabricColor = 0;
    hdr.fabric_header.fabricQos = 0;
    hdr.fabric_header.dstDevice = 0;
    hdr.fabric_header.dstPortOrGroup = 0;

    hdr.fabric_header_cpu.setValid();
    hdr.fabric_header_cpu.reserved = 0;
    hdr.fabric_header_cpu.ingressIfindex = 0;
    hdr.fabric_header_cpu.ingressBd = 0;
    hdr.fabric_header_cpu.reasonCode = 0;

    // carry ingress port for bf_knet rx filter
    hdr.fabric_header_cpu.ingressPort = ingress_port;

    hdr.fabric_payload_header.setValid();

    // save and modify ether type
    hdr.fabric_payload_header.ether_type = hdr.ethernet.ether_type;
    hdr.ethernet.ether_type = ETHERTYPE_BF_FABRIC;

    ig_tm_md.ucast_egress_port = TOFINO_CPU_PCIE_PORT;
    ig_tm_md.bypass_egress = 1w1;
}

action egress_forward_pkts_from_physical_port_to_cpu(inout header_t hdr,
                                              in bit<16> ingress_port)
{
    hdr.fabric_header.setValid();
    hdr.fabric_header.packetType = FABRIC_HEADER_TYPE_CPU;
    hdr.fabric_header.headerVersion = 0;
    hdr.fabric_header.packetVersion = 0;
    hdr.fabric_header.pad1 = 0;
    hdr.fabric_header.fabricColor = 0;
    hdr.fabric_header.fabricQos = 0;
    hdr.fabric_header.dstDevice = 0;
    hdr.fabric_header.dstPortOrGroup = 0;

    hdr.fabric_header_cpu.setValid();
    hdr.fabric_header_cpu.reserved = 0;
    hdr.fabric_header_cpu.ingressIfindex = 0;
    hdr.fabric_header_cpu.ingressBd = 0;
    hdr.fabric_header_cpu.reasonCode = 0;

    // carry egress port for bf_knet rx filter
    hdr.fabric_header_cpu.ingressPort = ingress_port;

    hdr.fabric_payload_header.setValid();

    // save and modify ether type
    hdr.fabric_payload_header.ether_type = hdr.ethernet.ether_type;
    hdr.ethernet.ether_type = ETHERTYPE_BF_FABRIC;
}
# 11 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/include/tbvr_defines.p4" 1
# 12 "/vm_share/tofino-bvr/tofino_bvr.p4" 2

# 1 "/vm_share/tofino-bvr/tbvr_parser_deparser.p4" 1



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

control IngressMirror(
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Mirror() mirror;

    apply {
        if (ig_intr_md_for_dprsr.mirror_type == MIRROR_TYPE_I2E) {
            mirror.emit<mirror_header_t>(ig_md.mirror_session_id, {
                ig_md.bvr_md.mirror_md.pkt_type,
                0});
        }
    }
}

control EgressMirror(
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {

    Mirror() mirror;

    apply {
        if (eg_intr_dprs_md.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<mirror_header_t>(eg_md.mirror_session_id, {
                eg_md.eg_mirror_md.pkt_type,
                0});
        }
    }
}

parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() udp_checksum;
    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_BF_FABRIC : parse_fabric_header;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : parse_other_ethernet;
        }
    }

    state parse_fabric_header {
        pkt.extract(hdr.fabric_header);
        pkt.extract(hdr.fabric_header_cpu);
        pkt.extract(hdr.fabric_payload_header);
        transition select(hdr.fabric_payload_header.ether_type) {
            default: accept;
        }
    }

    state parse_other_ethernet {
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition select(hdr.arp.opcode) {
            ARPOP_ARP_REQUEST : parse_arp_request;
            ARPOP_ARP_REPLY : parse_arp_reply;
            default : parse_arp_others;
        }
    }

    state parse_arp_request {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ARP_REQUEST;
        transition accept;
    }

    state parse_arp_reply {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ARP_REPLY;
        transition accept;
    }

    state parse_arp_others {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ARP_OTHERS;
        // TODO(huangbing01): all other underlay arp packets are dropped.
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        udp_checksum.subtract(hdr.ipv4.src_addr);
        udp_checksum.subtract(hdr.ipv4.dst_addr);
        ipv4_checksum.add(hdr.ipv4);
        ig_md.bvr_md.pkt_md.ipv4_checksum_err = ipv4_checksum.verify();
        // it seems that tofino do not support method 'verify' for now
        // verify(hdr.ipv4.ihl >= 5, error.HeaderTooShort);
        transition select(hdr.ipv4.ihl) {
            5 : dispatch_on_ipv4h_proto;
            default : parse_other_ipv4_ihl;
        }
    }

    // NOTE(huangbing01):no underlay packets with ip options are allowed
    state parse_other_ipv4_ihl {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_IPV4;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state dispatch_on_ipv4h_proto {
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMPV4 : parse_icmpv4;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_TTM : skip_ttm;
            default : parser_other_ipv4_proto;
        }
    }

    state parser_other_ipv4_proto {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_IPV4;
        transition accept;
    }

    state parse_icmpv4 {
        pkt.extract(hdr.icmpv4);
        transition select(hdr.icmpv4.type) {
            ICMP_TYPE_REQUEST : parse_icmpv4_request;
            ICMP_TYPE_REPLY : parse_icmpv4_reply;
            default : parse_icmpv4_other;
        }
    }

    state parse_icmpv4_request {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ICMPV4_REQUEST;
        transition accept;
    }

    state parse_icmpv4_reply {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ICMPV4_REPLY;
        transition accept;
    }

    state parse_icmpv4_other {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_ICMPV4_OTHERS;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state skip_ttm {
        pkt.advance(IP_PROTOCOLS_TTM_LEN * 8); // skip 8 bytes ttm option
        pkt.extract(hdr.udp);
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_UDP;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_DROP;
        transition reject;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract({hdr.udp.src_port});
        udp_checksum.subtract({hdr.udp.dst_port});
        udp_checksum.subtract({hdr.udp.checksum});
        ig_md.custom_bridge_hdr.checksum_udp_tmp = udp_checksum.get();
        transition select(hdr.udp.dst_port) {
            VTEP_PORT : parse_vxlan;
            default : parse_udp_other_port;
        }
    }

    state parse_udp_other_port {
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_UDP;
        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.bvr_md.pkt_md.outer_msg_type = msg_type_t.MSG_TYPE_VXLAN;
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        //NOTE(huangbing01): broadcast && multicast init in vpc
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan;
            ETHERTYPE_ARP : parse_inner_arp;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : parse_other_inner_ethernet;
        }
    }

    state parse_other_inner_ethernet {
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }

    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        transition select(hdr.inner_arp.opcode) {
            ARPOP_ARP_REQUEST : parse_inner_arp_request;
            ARPOP_ARP_REPLY : parse_inner_arp_reply;
            default : parse_inner_arp_others;
        }
    }

    state parse_inner_arp_request {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ARP_REQUEST;
        transition accept;
    }

    state parse_inner_arp_reply {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ARP_REPLY;
        transition accept;
    }

    state parse_inner_arp_others {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ARP_OTHERS;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        // it seems that tofino do not support method 'verify' for now
        //verify(hdr.inner_ipv4.ihl >= 5, error.HeaderTooShort);
        ig_md.bvr_md.lkp_md.ip_src_addr = hdr.inner_ipv4.src_addr;
        ig_md.bvr_md.lkp_md.ip_dst_addr = hdr.inner_ipv4.dst_addr;
        transition select(hdr.inner_ipv4.ihl) {
            5 : dispatch_on_inner_ipv4h_proto;
            6 : parse_inner_ipv4_options1;
            7 : parse_inner_ipv4_options2;
            8 : parse_inner_ipv4_options3;
            9 : parse_inner_ipv4_options4;
            10 : parse_inner_ipv4_options5;
            11 : parse_inner_ipv4_options6;
            12 : parse_inner_ipv4_options7;
            13 : parse_inner_ipv4_options8;
            14 : parse_inner_ipv4_options9;
            15 : parse_inner_ipv4_options10;
            default : parse_inner_other_ipv4_ihl;
        }
    }

    state parse_inner_other_ipv4_ihl {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_IPV4;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }

    state parse_inner_ipv4_options1 {
        pkt.extract(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options2 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options3 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options4 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options5 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options6 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts6);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options7 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts6);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts7);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options8 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts6);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts7);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts8);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options9 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        pkt.extract(hdr.inner_ipv4_opts9);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts6);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts7);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts8);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts9);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options10 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        pkt.extract(hdr.inner_ipv4_opts9);
        pkt.extract(hdr.inner_ipv4_opts10);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts1);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts2);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts3);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts4);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts5);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts6);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts7);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts8);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts9);
        inner_ipv4_checksum.add(hdr.inner_ipv4_opts10);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state dispatch_on_inner_ipv4h_proto {
        ig_md.bvr_md.pkt_md.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_ICMPV4 : parse_inner_icmpv4;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_TTM : skip_inner_ttm;
            default : parser_other_inner_ipv4_proto;
        }
    }

    state parser_other_inner_ipv4_proto {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_IPV4;
        ig_md.bvr_md.pkt_md.inner_l4_msg_type = msg_type_t.MSG_TYPE_OTHERS;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }

    // NOTE(huangbing01): parse active_access_flag for ACL, if can not be used in parser
    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_IPV4;
        ig_md.bvr_md.pkt_md.inner_l4_msg_type = msg_type_t.MSG_TYPE_TCP;
        // NOTE(huangbing01): ig_md.bvr_md.pkt_md.is_active_access of tcp is modified in tofino_bvr.p4
        ig_md.bvr_md.lkp_md.ip_proto = IP_PROTOCOLS_TCP;
        ig_md.bvr_md.lkp_md.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.bvr_md.lkp_md.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    // for overlay ttm packet, treat as udp packet
    state skip_inner_ttm {
        pkt.advance(IP_PROTOCOLS_TTM_LEN * 8); // skip 8 bytes ttm option
        transition parse_inner_udp;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_IPV4;
        ig_md.bvr_md.pkt_md.inner_l4_msg_type = msg_type_t.MSG_TYPE_UDP;
        ig_md.bvr_md.pkt_md.is_active_access = 1;
        ig_md.bvr_md.lkp_md.l4_src_port = hdr.inner_udp.src_port;
        ig_md.bvr_md.lkp_md.l4_dst_port = hdr.inner_udp.dst_port;
        ig_md.bvr_md.lkp_md.ip_proto = IP_PROTOCOLS_UDP;
        transition accept;
    }

    state parse_inner_icmpv4 {
        pkt.extract(hdr.inner_icmpv4);
        transition select(hdr.inner_icmpv4.type) {
            ICMP_TYPE_REQUEST : parse_inner_icmpv4_request;
            ICMP_TYPE_REPLY : parse_inner_icmpv4_reply;
            default : parse_inner_icmpv4_other;
        }
    }

    state parse_inner_icmpv4_request {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ICMPV4_REQUEST;
        ig_md.bvr_md.lkp_md.ip_proto = IP_PROTOCOLS_ICMPV4;
        ig_md.bvr_md.pkt_md.is_active_access = 1;
        transition accept;
    }

    state parse_inner_icmpv4_reply {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ICMPV4_REPLY;
        ig_md.bvr_md.lkp_md.ip_proto = IP_PROTOCOLS_ICMPV4;
        transition accept;
    }

    state parse_inner_icmpv4_other {
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_ICMPV4_OTHERS;
        transition accept;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        // for inner ipv6 packet, forward to x86 for now
        ig_md.bvr_md.pkt_md.inner_l3_msg_type = msg_type_t.MSG_TYPE_IPV6;
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_inner_icmpv6;
            default : accept;
        }
    }

    state parse_inner_icmpv6 {
        pkt.extract(hdr.inner_icmpv6);
        ig_md.bvr_md.fwd_md.fwd_type_of_parser = forward_type_t.FORWARD_TO_X86_BVR;
        transition accept;
    }
}

control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    IngressMirror() ingress_mirror;

    apply {
        ingress_mirror.apply(hdr, ig_md, ig_dprsr_md);

        pkt.emit(ig_md.custom_bridge_hdr);
        pkt.emit(hdr);
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_metadata;
    }

    state parse_metadata {
        mirror_header_t mirror_md = pkt.lookahead<mirror_header_t>();
        transition select(mirror_md.pkt_type) {
            PKT_SRC_CLONED_INGRESS : parse_ingress_mirror_pkt;
            PKT_SRC_CLONED_EGRESS : parse_egress_mirror_pkt;
            default : parse_custom_bridge_hdr;
        }
    }

    state parse_custom_bridge_hdr {
        pkt.extract(eg_md.custom_bridge_hdr);
        //NOTE(yangguang22):must init here
        eg_md.bvr_md.fwd_vtep_ip = eg_md.custom_bridge_hdr.next_hop;
        eg_md.bvr_md.fwd_vtep_port = VTEP_PORT;
        eg_md.by_pass = egress_by_pass_t.EGRESS_BYPASS_NONE;
        transition parse_ethernet;
    }

    state parse_ingress_mirror_pkt {
        mirror_header_t mirror_md;
        pkt.extract(mirror_md);
        eg_md.by_pass = egress_by_pass_t.EGRESS_BYPASS_MIRROR_ACL;
        transition parse_ethernet;
    }

    state parse_egress_mirror_pkt {
        mirror_header_t mirror_md;
        pkt.extract(mirror_md);
        eg_md.by_pass = egress_by_pass_t.EGRESS_BYPASS_MIRROR_ACL;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        eg_md.bvr_md.outer_src_mac = hdr.ethernet.src_addr;
        eg_md.bvr_md.outer_dst_mac = hdr.ethernet.dst_addr;
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition accept;
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.bvr_md.outer_src_addr = hdr.ipv4.src_addr;
        eg_md.bvr_md.outer_dst_addr = hdr.ipv4.dst_addr;
        transition select(hdr.ipv4.ihl) {
            5 : dispatch_on_ipv4h_proto;
            default : accept;
        }
    }

    state dispatch_on_ipv4h_proto {
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMPV4 : parse_icmpv4;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_TTM : skip_ttm;
            default : accept;
        }
    }

    state parse_icmpv4 {
        pkt.extract(hdr.icmpv4);
        transition accept;
    }

    state skip_ttm {
        pkt.advance(IP_PROTOCOLS_TTM_LEN * 8);
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            VTEP_PORT : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        eg_md.bvr_md.inner_src_mac = hdr.inner_ethernet.src_addr;
        eg_md.bvr_md.inner_dst_mac = hdr.inner_ethernet.dst_addr;
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan;
            ETHERTYPE_ARP : parse_inner_arp;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        transition accept;
    }

    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        eg_md.bvr_md.inner_src_addr = hdr.inner_arp.src_ip;
        eg_md.bvr_md.inner_dst_addr = hdr.inner_arp.dst_ip;
        transition accept;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        eg_md.bvr_md.inner_src_addr = hdr.inner_ipv4.src_addr;
        eg_md.bvr_md.inner_dst_addr = hdr.inner_ipv4.dst_addr;
        transition select(hdr.inner_ipv4.ihl) {
            5 : dispatch_on_inner_ipv4h_proto;
            6 : parse_inner_ipv4_options1;
            7 : parse_inner_ipv4_options2;
            8 : parse_inner_ipv4_options3;
            9 : parse_inner_ipv4_options4;
            10 : parse_inner_ipv4_options5;
            11 : parse_inner_ipv4_options6;
            12 : parse_inner_ipv4_options7;
            13 : parse_inner_ipv4_options8;
            14 : parse_inner_ipv4_options9;
            15 : parse_inner_ipv4_options10;
            default : accept;
        }
    }

    state parse_inner_ipv4_options1 {
        pkt.extract(hdr.inner_ipv4_opts1);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options2 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options3 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options4 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options5 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options6 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options7 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options8 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options9 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        pkt.extract(hdr.inner_ipv4_opts9);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state parse_inner_ipv4_options10 {
        pkt.extract(hdr.inner_ipv4_opts1);
        pkt.extract(hdr.inner_ipv4_opts2);
        pkt.extract(hdr.inner_ipv4_opts3);
        pkt.extract(hdr.inner_ipv4_opts4);
        pkt.extract(hdr.inner_ipv4_opts5);
        pkt.extract(hdr.inner_ipv4_opts6);
        pkt.extract(hdr.inner_ipv4_opts7);
        pkt.extract(hdr.inner_ipv4_opts8);
        pkt.extract(hdr.inner_ipv4_opts9);
        pkt.extract(hdr.inner_ipv4_opts10);
        transition dispatch_on_inner_ipv4h_proto;
    }

    state dispatch_on_inner_ipv4h_proto {
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_ICMPV4 : parse_inner_icmpv4;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_TTM : skip_inner_ttm;
            default : accept;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state skip_inner_ttm {
        pkt.advance(IP_PROTOCOLS_TTM_LEN * 8);
        transition parse_inner_udp;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_icmpv4 {
        pkt.extract(hdr.inner_icmpv4);
        transition accept;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_inner_icmpv6;
            default : accept;
        }
    }

    state parse_inner_icmpv6 {
        pkt.extract(hdr.inner_icmpv6);
        transition accept;
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {

    Checksum() ipv4_checksum;
    Checksum() udp_checksum;
    Checksum() inner_ipv4_checksum;

    EgressMirror() egress_mirror;

    apply {
        egress_mirror.apply(hdr, eg_md, eg_intr_dprsr_md);

        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr});
        }

        if (hdr.udp.isValid()) {
            hdr.udp.checksum = udp_checksum.update({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.udp.src_port,
                hdr.udp.dst_port,
                hdr.vxlan,
                hdr.inner_ethernet,
                hdr.inner_vlan_tag,
                hdr.inner_arp,
                hdr.inner_ipv6,
                hdr.inner_ipv4,
                hdr.inner_ipv4_opts1,
                hdr.inner_ipv4_opts2,
                hdr.inner_ipv4_opts3,
                hdr.inner_ipv4_opts4,
                hdr.inner_ipv4_opts5,
                hdr.inner_ipv4_opts6,
                hdr.inner_ipv4_opts7,
                hdr.inner_ipv4_opts8,
                hdr.inner_ipv4_opts9,
                hdr.inner_ipv4_opts10,
                hdr.inner_icmpv4,
                hdr.inner_icmpv6,
                hdr.inner_tcp,
                hdr.inner_udp,
                eg_md.custom_bridge_hdr.checksum_udp_tmp
            });
        }

        if (hdr.inner_ipv4.isValid()) {
            hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_ipv4_opts1.options,
                hdr.inner_ipv4_opts2.options,
                hdr.inner_ipv4_opts3.options,
                hdr.inner_ipv4_opts4.options,
                hdr.inner_ipv4_opts5.options,
                hdr.inner_ipv4_opts6.options,
                hdr.inner_ipv4_opts7.options,
                hdr.inner_ipv4_opts8.options,
                hdr.inner_ipv4_opts9.options,
                hdr.inner_ipv4_opts10.options});
        }

        //inner_arp have no checksum
        pkt.emit(hdr);
    }
}

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
# 14 "/vm_share/tofino-bvr/tofino_bvr.p4" 2

# 1 "/vm_share/tofino-bvr/vpc/tbvr_vpc.p4" 1



# 1 "/vm_share/tofino-bvr/vpc/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/vpc/tbvr_vpc.p4" 2
# 1 "/vm_share/tofino-bvr/vpc/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/vpc/tbvr_vpc.p4" 2
# 1 "/vm_share/tofino-bvr/vpc/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/vpc/tbvr_vpc.p4" 2
# 1 "/vm_share/tofino-bvr/vpc/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/vpc/tbvr_vpc.p4" 2

ipv4_addr_t fetch_outer_dst_ip_by_msg_type(in header_t hdr, in msg_type_t outer_msg_type) {
    if (outer_msg_type == msg_type_t.MSG_TYPE_ARP_REQUEST
        || outer_msg_type == msg_type_t.MSG_TYPE_ARP_REPLY
        || outer_msg_type == msg_type_t.MSG_TYPE_ARP_OTHERS) {
        return hdr.arp.dst_ip;
    } else {
        // outer_msg_type == msg_type_t.MSG_TYPE_ICMPV4_REQUEST
        // outer_msg_type == msg_type_t.MSG_TYPE_ICMPV4_REPLY
        // outer_msg_type == msg_type_t.MSG_TYPE_ICMPV4_OTHERS
        // outer_msg_type == msg_type_t.MSG_TYPE_UDP
        // outer_msg_type == msg_type_t.MSG_TYPE_VXLAN
        // outer_msg_type == msg_type_t.MSG_TYPE_IPV4
        return hdr.ipv4.dst_addr;
    }
}

bool is_msg_type_arp(in msg_type_t msg_type) {
    if (msg_type == msg_type_t.MSG_TYPE_ARP_REQUEST
        || msg_type == msg_type_t.MSG_TYPE_ARP_REPLY
        || msg_type == msg_type_t.MSG_TYPE_ARP_OTHERS) {
        return true;
    }
    return false;
}

bool is_msg_type_icmp(in msg_type_t msg_type) {
    if (msg_type == msg_type_t.MSG_TYPE_ICMPV4_REQUEST
        || msg_type == msg_type_t.MSG_TYPE_ICMPV4_REPLY
        || msg_type == msg_type_t.MSG_TYPE_ICMPV4_OTHERS) {
        return true;
    }
    return false;
}

bool is_l2_multicast_or_broadcast(in mac_addr_t dst_addr) {
    // can not compare a bit<48> var, maybe compiler has a bug
    if ((dst_addr[47:40] & ETHER_MULTICAST_MAC_HIGH8_MASK) == ETHER_MULTICAST_MAC_HIGH8_MASK) {
        return true;
    }
    return false;
}

control TBvrVPCIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        out ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_vport_in_counter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_vpc_in_counter;

    vni_t vni = 0;
    vpc_id_t vpc_id = 0;
    vport_id_t vport_id = 0;
    ipv4_addr_t floating_ip = 0;
    ipv4_addr_t vport_ip = 0;

    // NOTE(huangbing01): used in the first stage, if initialized, will lead into an additional stage
    packet_type_t packet_type = packet_type_t.OTHERS;
    msg_type_t outer_msg_type = msg_type_t.MSG_TYPE_OTHERS;
    msg_type_t inner_l3_msg_type = msg_type_t.MSG_TYPE_OTHERS;
    msg_type_t inner_l4_msg_type = msg_type_t.MSG_TYPE_OTHERS;

    @pa_no_overlay("ingress", "vpc_ingress_outer_dst_ip")
    ipv4_addr_t outer_dst_ip = 0;
    DirectMeter(MeterType_t.BYTES) cpu_rate_limit_meter;
    bit<8> cpu_rate_limit_color = MeterColor_t.GREEN;

    // TODO(huangbing01): a better name(with underlay_packet_type_table)
    forward_type_t fwd_type_of_packet_type_table = forward_type_t.FORWARD_NORMAL; // for vpc internal use
    forward_type_t fwd_type_of_vpc_find_procedure = forward_type_t.FORWARD_NORMAL; // for vpc internal use
    forward_type_t fwd_type_of_vpc_conf_table = forward_type_t.FORWARD_NORMAL; // for vpc internal use
    forward_type_t fwd_type_of_vport_in_table = forward_type_t.FORWARD_NORMAL; // for vpc internal use

    action packet_type_find(packet_type_t table_packet_type) {
        packet_type = table_packet_type;

        // forward to CPU rate limit
        cpu_rate_limit_color = cpu_rate_limit_meter.execute();
    }

    // TODO(huangbing01): a better name
    table underlay_packet_type_table {
        key = {
            outer_dst_ip : exact;
        }

        actions = {
            packet_type_find;
            @defaultonly forward_drop(fwd_type_of_packet_type_table);
        }

        const default_action = forward_drop(fwd_type_of_packet_type_table);
        meters = cpu_rate_limit_meter;
        size = UNDERLAY_PACKET_TYPE_TABLE_SIZE;
    }

    action vpc_overlay_hit(vpc_id_t table_vpc_id) {
        ig_md.bvr_md.vpc_md.vpc_id = table_vpc_id;
        vpc_id = table_vpc_id;
        fwd_type_of_vpc_find_procedure = forward_type_t.FORWARD_NORMAL;
    }

    // table used to find a vpc by overlay vni and dst mac(aka vport_id)
    table vport_to_vpc_table {
        key = {
            vni : exact;
            vport_id : exact;
        }

        actions = {
            vpc_overlay_hit;
            @defaultonly forward_x86(fwd_type_of_vpc_find_procedure);
        }

        const default_action = forward_x86(fwd_type_of_vpc_find_procedure);

        size = VPORT_TO_VPC_TABLE_SIZE;
    }

    action vpc_underlay_hit(vpc_id_t table_vpc_id, vport_id_t table_vport_id) {
        ig_md.bvr_md.vpc_md.vpc_id = table_vpc_id;
        vpc_id = table_vpc_id;
        vport_id = table_vport_id;
        fwd_type_of_vpc_find_procedure = forward_type_t.FORWARD_NORMAL;
    }

    // table used to find a vpc by floating ip
    table floating_ip_table {
        key = {
            floating_ip : exact;
        }

        actions = {
            vpc_underlay_hit;
            @defaultonly forward_x86(fwd_type_of_vpc_find_procedure);
        }

        const default_action = forward_x86(fwd_type_of_vpc_find_procedure);

        size = FLOATING_IP_TABLE_SIZE;
    }

    action vpc_conf_find(
            bit<1> dscp_switch,
            bit<8> dscp,
            bit<8> public_route_switch,
            mac_addr_t share_vport_mac,
            forward_type_t forward_type) {
        //ig_md.bvr_md.fwd_md.vpc_dscp_switch = dscp_switch;
        ig_md.bvr_md.fwd_md.vpc_dscp = dscp;
        ig_md.bvr_md.vpc_md.public_route_switch = public_route_switch;
        ig_md.bvr_md.vpc_md.share_vport_mac = share_vport_mac;
        fwd_type_of_vpc_conf_table = forward_type;

        direct_vpc_in_counter.count();
    }

    // table used to store config of vpc
    table vpc_conf_table {

        key = {
            vpc_id : exact;
        }

        actions = {
            vpc_conf_find;
            @defaultonly forward_x86(fwd_type_of_vpc_conf_table);
        }

        const default_action = forward_x86(fwd_type_of_vpc_conf_table);

        size = VPC_CONF_TABLE_SIZE;

        counters = direct_vpc_in_counter;
    }

    action vport_arp_hit(mac_addr_t vport_mac) {
        ig_md.bvr_md.vpc_md.vport_mac = vport_mac;
        fwd_type_of_vpc_find_procedure = forward_type_t.FORWARD_GW_REPLY_ARP;

        //TODO(yangguang22):for compilation speed, it will be deleted later
        hdr.inner_ethernet.dst_addr = hdr.inner_ethernet.src_addr;
        hdr.inner_ethernet.src_addr = vport_mac;
    }

    // table used to deal with the arp request to a vport
    table vport_arp_table {

        key = {
            vni : exact;
            vport_ip : exact;
        }

        actions = {
            vport_arp_hit;
            @defaultonly forward_x86(fwd_type_of_vpc_find_procedure);
        }

        const default_action = forward_x86(fwd_type_of_vpc_find_procedure);

        size = VPORT_ARP_TABLE_SIZE;
    }

    action vport_in_hit(vport_type_t vport_type) {
        ig_md.bvr_md.vpc_md.in_vport_type = vport_type;
        fwd_type_of_vport_in_table = forward_type_t.FORWARD_NORMAL;

        direct_vport_in_counter.count();
    }

    // table used to deal with packets sending to a vport
    table vport_in_table {

        key = {
            vpc_id : exact;
            vport_id : exact;
        }

        actions = {
            vport_in_hit;
            @defaultonly forward_x86(fwd_type_of_vport_in_table);
        }

        const default_action = forward_x86(fwd_type_of_vport_in_table);

        size = VPORT_IN_TABLE_SIZE;

        counters = direct_vport_in_counter;
    }

    apply {
        bit<16> ingress_port = (bit<16>)ig_intr_md.ingress_port;
        outer_msg_type = ig_md.bvr_md.pkt_md.outer_msg_type;
        inner_l3_msg_type = ig_md.bvr_md.pkt_md.inner_l3_msg_type;
        inner_l4_msg_type = ig_md.bvr_md.pkt_md.inner_l4_msg_type;

        bool is_l2_multicast = is_l2_multicast_or_broadcast(hdr.ethernet.dst_addr);
        bool is_outer_msg_arp = is_msg_type_arp(ig_md.bvr_md.pkt_md.outer_msg_type);
        bool is_inner_msg_icmp = is_msg_type_icmp(ig_md.bvr_md.pkt_md.inner_l3_msg_type);

        // TODO(huangbing01): if we move this judge to parser, the underlay_packet_type_table can be put into stage 0
        outer_dst_ip = fetch_outer_dst_ip_by_msg_type(hdr, ig_md.bvr_md.pkt_md.outer_msg_type);

        // will deal with all possibilities of fwd_type_of_packet_type_table
        underlay_packet_type_table.apply();
        if (packet_type == packet_type_t.VTEP_IP) {
            if (is_outer_msg_arp) {
                // vtep do not care ARP
                forward_drop(fwd_type_of_packet_type_table);

            } else if (is_l2_multicast) {
                // broadcast/multicast send to cpu.
                // NOTE(huangbing01):What's different with x86 is that NON-IP packet will be sent to CPU, too.
                if (cpu_rate_limit_color != MeterColor_t.GREEN) {
                    ig_dprsr_md.drop_ctl = 1; // Drop packet.
                }

                // will change ig_tm_md.ucast_egress_port inside
                ingress_forward_pkts_from_physical_port_to_cpu(hdr, ingress_port, ig_tm_md);

            } else if (outer_msg_type == msg_type_t.MSG_TYPE_VXLAN) {
                if (hdr.vxlan.flags != VXLAN_FLAGS || hdr.vxlan.reserved != 0 || hdr.vxlan.reserved2 != 0) {
                    // drop if vxlan flag/reserved bit is set
                    forward_drop(fwd_type_of_packet_type_table);
                } else if (inner_l3_msg_type == msg_type_t.MSG_TYPE_ARP_REPLY
                    || inner_l3_msg_type == msg_type_t.MSG_TYPE_ARP_OTHERS) {
                    forward_drop(fwd_type_of_packet_type_table);
                } else if (inner_l3_msg_type == msg_type_t.MSG_TYPE_IPV6) {
                    forward_x86(fwd_type_of_packet_type_table);
                } else {
                    // inner_l3_msg_type == msg_type_t.MSG_TYPE_ARP_REQUEST, arp for vpc subnet gateway ip
                    // and so on
                    forward_normal(fwd_type_of_packet_type_table);
                }
            } else if (outer_msg_type == msg_type_t.MSG_TYPE_ICMPV4_REQUEST){
                forward_vtep_reply_icmpv4(fwd_type_of_packet_type_table);
            } else {
                forward_drop(fwd_type_of_packet_type_table);
            }

        } else if ((packet_type == packet_type_t.LOCAL_IP)
                || (packet_type == packet_type_t.GATEWAY_IP)) {
            // forward packets whose daddr is LOCAL_IP/GATEWAY_IP to CPU PCIE port
            // NOTE(huangbing01): if function used, another stage is imported
            if (cpu_rate_limit_color != MeterColor_t.GREEN) {
                ig_dprsr_md.drop_ctl = 1; // Drop packet.
            }

            ingress_forward_pkts_from_physical_port_to_cpu(hdr, ingress_port, ig_tm_md);

        } else {
            // for floating ip/phy_vport (not supported now)
            forward_drop(fwd_type_of_packet_type_table);
        }

        // will deal with all possibilities of fwd_type_of_vpc_find_procedure
        if (outer_msg_type == msg_type_t.MSG_TYPE_VXLAN) {
            // handle overlay packet
            vni = hdr.vxlan.vni;
            if (inner_l3_msg_type == msg_type_t.MSG_TYPE_IPV4 || is_inner_msg_icmp) {
                vport_id = hdr.inner_ethernet.dst_addr;
                vport_to_vpc_table.apply();
            } else if (inner_l3_msg_type == msg_type_t.MSG_TYPE_ARP_REQUEST) {
                vport_ip = hdr.inner_arp.dst_ip;
                vport_arp_table.apply();
            } else {
                //msg_type_t.MSG_TYPE_ARP_REPLY and others
                forward_drop(fwd_type_of_vpc_find_procedure);
            }
        } else {
            // handle underlay packet
            floating_ip = hdr.inner_ipv4.dst_addr;
            floating_ip_table.apply();
        }

        // Will deal with all possibilities of fwd_type_of_vpc_conf_table
        // The two table will never hit if vpc_id is 32w0x80_00_00_00
        vpc_conf_table.apply();
        vport_in_table.apply();

        // dispatch packet by packet type and fwd_type from all tables
        if (packet_type == packet_type_t.VTEP_IP) {
            if (fwd_type_of_packet_type_table == forward_type_t.FORWARD_NORMAL
                    && fwd_type_of_vpc_find_procedure == forward_type_t.FORWARD_NORMAL
                    && fwd_type_of_vpc_conf_table == forward_type_t.FORWARD_NORMAL
                    && fwd_type_of_vport_in_table == forward_type_t.FORWARD_NORMAL) {
                // normal overlay packet
                forward_normal(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);
            } else if (fwd_type_of_packet_type_table == forward_type_t.FORWARD_NORMAL
                    && fwd_type_of_vpc_find_procedure == forward_type_t.FORWARD_GW_REPLY_ARP) {
                // overlay arp packet
                forward_gw_reply_arp(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);
            } else if (fwd_type_of_packet_type_table == forward_type_t.FORWARD_VTEP_REPLY_ICMPV4) {
                // vtep icmpv4 request packet
                forward_vtep_reply_icmpv4(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);
            } else {
                // not supported packet(e.g other vpc)
                forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);
            }
        } else {
            // packet not to vtep ip
            ig_md.bvr_md.fwd_md.fwd_type_of_vpc = fwd_type_of_packet_type_table;
        }
    }
}

control TBvrVPCEgress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_vport_out_counter;

    action vport_out_hit(/*bit<1>*/ dscp_switch_type_t dscp_switch, bit<8> dscp) {
        ig_md.bvr_md.fwd_md.vport_dscp_switch = dscp_switch;
        ig_md.bvr_md.fwd_md.vport_dscp = dscp;

        direct_vport_out_counter.count();
    }

    // table used to deal with packets sending from a vport
    table vport_out_table {

        key = {
            // only one table in this control, if local var used, may waste one stage
            ig_md.bvr_md.vpc_md.vpc_id : exact;
            ig_md.bvr_md.route_md.new_src_mac : exact;
        }

        actions = {
            vport_out_hit;
            @defaultonly forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);
        }

        const default_action = forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_vpc);

        size = VPORT_OUT_TABLE_SIZE;

        counters = direct_vport_out_counter;
    }

    apply {
        // NOTE(huangbing): only deal with FORWARD_NORMAL packet.
        // In x86 BVR, FORWARD_GW_REPLY_ARP packet will also be treated here

        ig_md.bvr_md.fwd_md.vport_dscp_switch = dscp_switch_type_t.DSCP_SWITCH_OFF;
        ig_md.bvr_md.fwd_md.vport_dscp = 0;

        if (ig_md.bvr_md.fwd_md.fwd_type_of_vpc == forward_type_t.FORWARD_NORMAL) {
            vport_out_table.apply();
        }
    }
}
# 16 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/acl/tbvr_acl.p4" 1



# 1 "/vm_share/tofino-bvr/acl/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/acl/tbvr_acl.p4" 2
# 1 "/vm_share/tofino-bvr/acl/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/acl/tbvr_acl.p4" 2
# 1 "/vm_share/tofino-bvr/acl/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/acl/tbvr_acl.p4" 2
# 1 "/vm_share/tofino-bvr/acl/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/acl/tbvr_acl.p4" 2

control TBvrIngressAcl(
        inout header_t hdr,
        inout ingress_metadata_t ig_md)() {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_pre_acl_counter;

    //temp variable used to get table data active_access_flag
    active_access_flag_t tmp_active_access_flag = active_access_flag_t.ACTIVE_ACCESS_DISABLE;

    action drop(bit_flag_t active_access_flag) {
        ig_md.bvr_md.fwd_md.fwd_type_of_acl = forward_type_t.FORWARD_DROP;
        //tmp_active_access_flag = active_access_flag;
        direct_pre_acl_counter.count();
    }

    action accept() {
        direct_pre_acl_counter.count();
    }

    //table use for acl match
    table acl {
        key = {
            ig_md.bvr_md.lkp_md.ip_src_addr : ternary; ig_md.bvr_md.lkp_md.ip_dst_addr : ternary; ig_md.bvr_md.lkp_md.ip_proto : ternary; ig_md.bvr_md.lkp_md.l4_src_port : range; ig_md.bvr_md.lkp_md.l4_dst_port : range;
            ig_md.bvr_md.vpc_md.vpc_id : ternary;
            ig_md.bvr_md.vpc_md.in_vport_type : ternary;
        }

        actions = {
            accept;
            drop;
        }

        const default_action = accept;
        size = INGRESS_ACL_TABLE_SIZE;
        counters = direct_pre_acl_counter;
    }

    apply {
        acl.apply();
        if (ig_md.bvr_md.fwd_md.fwd_type_of_acl == forward_type_t.FORWARD_DROP) {
            if (tmp_active_access_flag == active_access_flag_t.ACTIVE_ACCESS_ENABLE) {
                if (ig_md.bvr_md.pkt_md.is_active_access == 0) {
                    ig_md.bvr_md.fwd_md.fwd_type_of_acl = forward_type_t.FORWARD_NORMAL;
                }
            }
        }
    }
}

control TBvrEgressAcl(
        inout header_t hdr,
        inout egress_metadata_t eg_md)() {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_post_acl_counter;

    active_access_flag_t tmp_active_access_flag = active_access_flag_t.ACTIVE_ACCESS_DISABLE;

    action drop(bit_flag_t active_access_flag) {
        eg_md.custom_bridge_hdr.fwd_type = forward_type_t.FORWARD_DROP;
        //tmp_active_access_flag = active_access_flag;
        direct_post_acl_counter.count();
    }

    action accept() {
        direct_post_acl_counter.count();
    }

    table acl {
        key = {
            hdr.inner_ipv4.src_addr : ternary; hdr.inner_ipv4.dst_addr : ternary; eg_md.custom_bridge_hdr.ip_proto : ternary; eg_md.custom_bridge_hdr.l4_src_port : range; eg_md.custom_bridge_hdr.l4_dst_port : range;
            eg_md.custom_bridge_hdr.vpc_id : ternary;
            eg_md.custom_bridge_hdr.out_vport_type : ternary;
        }

        actions = {
            accept;
            drop;
        }

        const default_action = accept;
        size = EGRESS_ACL_TABLE_SIZE;
        counters = direct_post_acl_counter;
    }

    apply {
        if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_NORMAL
            || eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_VTEP_REPLY_ICMPV4
            || eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_GW_REPLY_ARP) {

            acl.apply();
            if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_DROP) {
                if (tmp_active_access_flag == active_access_flag_t.ACTIVE_ACCESS_ENABLE) {
                    if (eg_md.custom_bridge_hdr.is_active_access == 0) {
                        eg_md.custom_bridge_hdr.fwd_type = forward_type_t.FORWARD_NORMAL;
                    }
                }
            }
        }
    }
}
# 17 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/route/tbvr_route.p4" 1



# 1 "/vm_share/tofino-bvr/route/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/route/tbvr_route.p4" 2
# 1 "/vm_share/tofino-bvr/route/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/route/tbvr_route.p4" 2
# 1 "/vm_share/tofino-bvr/route/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/route/tbvr_route.p4" 2
# 1 "/vm_share/tofino-bvr/route/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/route/tbvr_route.p4" 2

control TBvrRoute(
        inout header_t hdr,
        inout ingress_metadata_t ig_md) {

    u16_t group_id_for_ecmp = 0;

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_route_counter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_ecmp_counter;

    Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
    ActionProfile(1024) ecmp_action_selector_ap;
    ActionSelector(
        ecmp_action_selector_ap,
        sel_hash,
        SelectorMode_t.FAIR,
        ECMP_MAX_GROUP_SIZE,
        ECMP_NUM_GROUPS
    ) ecmp_action_selector;

    action overlay_route_hit(
            ipv4_addr_t table_next_hop,
            vni_t table_next_vni,
            mac_addr_t table_new_src_mac,
            vport_type_t table_vport_type,
            u16_t table_group_id,
            route_type_t table_route_type) {

        ig_md.bvr_md.route_md.next_hop = table_next_hop;
        ig_md.bvr_md.route_md.next_vni = table_next_vni;
        ig_md.bvr_md.route_md.new_src_mac = table_new_src_mac;
        ig_md.bvr_md.vpc_md.out_vport_type = table_vport_type;

        group_id_for_ecmp = table_group_id;

        ig_md.bvr_md.route_md.route_type = table_route_type;

        direct_route_counter.count();
    }

    table overlay_route_table {
        key = {
            ig_md.bvr_md.vpc_md.vpc_id : ternary;
            hdr.inner_ipv4.src_addr : ternary;
            hdr.inner_ipv4.dst_addr : ternary;
            ig_md.bvr_md.vpc_md.public_route_switch : ternary;
        }

        actions = {
            overlay_route_hit;
            @defaultonly forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_route);
        }

        size = OVERLAY_ROUTE_TABLE_SIZE;

        const default_action = forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_route);

        counters = direct_route_counter;
    }

    action overlay_ecmp_hit(
            ipv4_addr_t table_next_hop,
            vni_t table_next_vni,
            mac_addr_t table_new_src_mac,
            vport_type_t table_vport_type) {

        ig_md.bvr_md.route_md.next_hop = table_next_hop;
        ig_md.bvr_md.route_md.next_vni = table_next_vni;
        ig_md.bvr_md.route_md.new_src_mac = table_new_src_mac;
        ig_md.bvr_md.vpc_md.out_vport_type = table_vport_type;

        direct_ecmp_counter.count();
    }

    table overlay_ecmp_table {
        key = {
            group_id_for_ecmp : exact;
            hdr.inner_ipv4.src_addr : selector;
            hdr.inner_ethernet.src_addr : selector;
        }

        actions = {
            overlay_ecmp_hit;
            @defaultonly forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_route);
        }

        size = OVERLAY_ECMP_TABLE_SIZE;

        const default_action = forward_x86(ig_md.bvr_md.fwd_md.fwd_type_of_route);

        implementation = ecmp_action_selector;

        counters = direct_ecmp_counter;
    }

    apply {
        overlay_route_table.apply();

        if (group_id_for_ecmp != 0){
            overlay_ecmp_table.apply();
        }

        //ALL
        if (ig_md.bvr_md.route_md.next_vni == 0) {
            if (ig_md.bvr_md.route_md.route_type == route_type_t.ROUTE_TYPE_PUBLIC) {
                ig_md.bvr_md.route_md.new_src_mac = ig_md.bvr_md.vpc_md.share_vport_mac;
                ig_md.bvr_md.route_md.next_vni = ig_md.bvr_md.vpc_md.vpc_id;
            } else {
                ig_md.bvr_md.route_md.next_vni = hdr.vxlan.vni;
            }
        }

        //DIRECT, LOCAL, DEFAUL
        if (ig_md.bvr_md.route_md.next_hop == 0) {
            ig_md.bvr_md.route_md.next_hop = hdr.inner_ipv4.dst_addr;
        }
    }
}
# 18 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/stat/tbvr_stat.p4" 1



# 1 "/vm_share/tofino-bvr/stat/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/stat/tbvr_stat.p4" 2
# 1 "/vm_share/tofino-bvr/stat/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/stat/tbvr_stat.p4" 2
# 1 "/vm_share/tofino-bvr/stat/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/stat/tbvr_stat.p4" 2
# 1 "/vm_share/tofino-bvr/stat/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/stat/tbvr_stat.p4" 2

control TBvrStat(
        inout egress_metadata_t eg_md) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_vpc_out_counter;

    action vpc_out_counter_hit() {
        direct_vpc_out_counter.count();
    }

    table vpc_out_counter_table {
        key = {
            eg_md.custom_bridge_hdr.vpc_id : exact;
            eg_md.custom_bridge_hdr.fwd_type : exact;
        }

        actions = {
            vpc_out_counter_hit;
        }

        size = VPC_OUT_COUNTER_TABLE_SIZE;

        const default_action = vpc_out_counter_hit;

        counters = direct_vpc_out_counter;
    }

    apply {
        vpc_out_counter_table.apply();
    }
}
# 19 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/forward/tbvr_forward.p4" 1



# 1 "/vm_share/tofino-bvr/forward/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/forward/tbvr_forward.p4" 2
# 1 "/vm_share/tofino-bvr/forward/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/forward/tbvr_forward.p4" 2
# 1 "/vm_share/tofino-bvr/forward/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/forward/tbvr_forward.p4" 2
# 1 "/vm_share/tofino-bvr/forward/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/forward/tbvr_forward.p4" 2

control TBvrEgressForward(
        inout header_t hdr,
        inout egress_metadata_t eg_md) {


    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_overlay_arp_fdb_counter;

    bool arp_fdb_tbl_apply_flag = false;

    action overlay_arp_fdb_hit(
            mac_addr_t table_mac,
            ipv4_addr_t table_remote_ip) {

        eg_md.bvr_md.overlay_dst_mac = table_mac;
        eg_md.bvr_md.fwd_vtep_ip = table_remote_ip;
        eg_md.bvr_md.fwd_vtep_port = VTEP_PORT;

        direct_overlay_arp_fdb_counter.count();

    }

    table overlay_arp_fdb_table {
        key = {
            eg_md.custom_bridge_hdr.next_vni : exact;
            eg_md.custom_bridge_hdr.next_hop : exact;
        }

        actions = {
            overlay_arp_fdb_hit;
            @defaultonly forward_x86(eg_md.custom_bridge_hdr.fwd_type);
        }

        size = OVERLAY_ARP_FDB_TABLE_SIZE;
        const default_action = forward_x86(eg_md.custom_bridge_hdr.fwd_type);

        counters = direct_overlay_arp_fdb_counter;

    }

    apply {
        if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_NORMAL) {
            if (eg_md.custom_bridge_hdr.route_type == route_type_t.ROUTE_TYPE_LOCAL) {
                if (eg_md.custom_bridge_hdr.inner_l3_msg_type == msg_type_t.MSG_TYPE_ICMPV4_REQUEST) {
                    eg_md.custom_bridge_hdr.fwd_type = forward_type_t.FORWARD_GW_REPLY_ICMPV4;
                } else {
                    eg_md.custom_bridge_hdr.fwd_type = forward_type_t.FORWARD_DROP;
                }
            } else if (eg_md.custom_bridge_hdr.route_type == route_type_t.ROUTE_TYPE_PUBLIC) {
                eg_md.bvr_md.overlay_dst_mac[47:24] = ROUTE_PUBLIC_MAC_FLAG;
                eg_md.bvr_md.overlay_dst_mac[23:0] = eg_md.custom_bridge_hdr.next_hop[23:0];
                //fwd_vtep_ip and fwd_vtep_port have already init at egress parser
            } else if (eg_md.custom_bridge_hdr.route_type == route_type_t.ROUTE_TYPE_DEFAULT) {
                eg_md.custom_bridge_hdr.fwd_type = forward_type_t.FORWARD_TO_X86_BVR;
            } else {
                arp_fdb_tbl_apply_flag = true;
            }
        }

        if (arp_fdb_tbl_apply_flag == true) {
            overlay_arp_fdb_table.apply();
        }
    }
}

control TBvrDowngradeToX86BVR(
        inout ingress_metadata_t ig_md) {

    action x86bvr_fwd_vtep_hit(
            ipv4_addr_t table_x86bvr_vtep_ip,
            u16_t table_x86bvr_vtep_port,
            forward_type_t table_global_forward_to_x86bvr){

        ig_md.bvr_md.fwd_md.fwd_x86_vtep_ip = table_x86bvr_vtep_ip;
        ig_md.bvr_md.fwd_md.fwd_x86_vtep_port = table_x86bvr_vtep_port;
        ig_md.bvr_md.fwd_md.fwd_type_of_force_to_x86 = table_global_forward_to_x86bvr;
    }

    table x86bvr_fwd_table {
        actions = {
            x86bvr_fwd_vtep_hit;
        }
    }

    apply {
        x86bvr_fwd_table.apply();
    }
}

control Ingress2EgressBridge(
        inout header_t hdr,
        inout ingress_metadata_t ig_md) {

    action custom_bridge_init(){
        ig_md.custom_bridge_hdr.setValid();

        ig_md.custom_bridge_hdr.inner_l3_msg_type = ig_md.bvr_md.pkt_md.inner_l3_msg_type;
        ig_md.custom_bridge_hdr.vpc_id = ig_md.bvr_md.vpc_md.vpc_id;
        ig_md.custom_bridge_hdr.vport_mac = ig_md.bvr_md.vpc_md.vport_mac;

        //TODO(yangguang22):for tmp, with vpc
        //ig_md.custom_bridge_hdr.vport_mac2 = ig_md.bvr_md.vpc_md.vport_mac;

        ig_md.custom_bridge_hdr.next_hop = ig_md.bvr_md.route_md.next_hop;
        ig_md.custom_bridge_hdr.next_vni = ig_md.bvr_md.route_md.next_vni;
        ig_md.custom_bridge_hdr.route_type = ig_md.bvr_md.route_md.route_type;
        ig_md.custom_bridge_hdr.new_src_mac = ig_md.bvr_md.route_md.new_src_mac;
        ig_md.custom_bridge_hdr.out_vport_type = ig_md.bvr_md.vpc_md.out_vport_type;

        ig_md.custom_bridge_hdr.fwd_type = ig_md.bvr_md.fwd_md.fwd_type;
        ig_md.custom_bridge_hdr.fwd_x86_vtep_ip = ig_md.bvr_md.fwd_md.fwd_x86_vtep_ip;
        ig_md.custom_bridge_hdr.fwd_x86_vtep_port = ig_md.bvr_md.fwd_md.fwd_x86_vtep_port;

        ig_md.custom_bridge_hdr.out_dscp = ig_md.bvr_md.fwd_md.out_dscp;

        ig_md.custom_bridge_hdr.is_active_access = ig_md.bvr_md.pkt_md.is_active_access;
        ig_md.custom_bridge_hdr.ip_proto = ig_md.bvr_md.lkp_md.ip_proto;
        ig_md.custom_bridge_hdr.l4_src_port = ig_md.bvr_md.lkp_md.l4_src_port;
        ig_md.custom_bridge_hdr.l4_dst_port = ig_md.bvr_md.lkp_md.l4_dst_port;
    }

    action merge_fwd_type_hit(forward_type_t table_fwd_type) {
        ig_md.bvr_md.fwd_md.fwd_type = table_fwd_type;
    }

    table merge_fwd_type_table{
        key = {
            //normal or x86
            ig_md.bvr_md.fwd_md.fwd_type_of_force_to_x86 : exact;
            //normal or abnormal or drop or x86
            ig_md.bvr_md.fwd_md.fwd_type_of_parser : exact;
            //normal or gw_reply_arp or vtep_reply_icmp or x86 or drop
            ig_md.bvr_md.fwd_md.fwd_type_of_vpc : exact;
            //normal or drop
            ig_md.bvr_md.fwd_md.fwd_type_of_acl : exact;
            //normal or x86
            ig_md.bvr_md.fwd_md.fwd_type_of_route : exact;
        }

        actions = {
            merge_fwd_type_hit;
            @defaultonly forward_x86(ig_md.bvr_md.fwd_md.fwd_type);
        }

        size = MERGE_FWD_TYPE_TABLE_SIZE;

        const default_action = forward_x86(ig_md.bvr_md.fwd_md.fwd_type);
    }

    apply {
        merge_fwd_type_table.apply();

        if (ig_md.bvr_md.fwd_md.vport_dscp_switch == dscp_switch_type_t.DSCP_SWITCH_ON){
            ig_md.bvr_md.fwd_md.out_dscp = ig_md.bvr_md.fwd_md.vport_dscp;
        }else if (ig_md.bvr_md.fwd_md.vpc_dscp_switch == dscp_switch_type_t.DSCP_SWITCH_ON){
            ig_md.bvr_md.fwd_md.out_dscp = ig_md.bvr_md.fwd_md.vpc_dscp;
        }else {
            ig_md.bvr_md.fwd_md.out_dscp = hdr.ipv4.diffserv;
        }

        custom_bridge_init();
    }
}
# 20 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/forward/tbvr_vtep.p4" 1
# 9 "/vm_share/tofino-bvr/forward/tbvr_vtep.p4"
control TBvrVtep(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Hash<bit<16>>(HashAlgorithm_t.CRC32) src_port_hash;
    bit<16> src_port_flag;

    action forward_normal(){
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;

        hdr.inner_ethernet.dst_addr = eg_md.bvr_md.overlay_dst_mac;
        hdr.inner_ethernet.src_addr = eg_md.custom_bridge_hdr.new_src_mac;

        hdr.vxlan.vni = eg_md.custom_bridge_hdr.next_vni;
        hdr.vxlan.flags = VXLAN_FLAGS;

        hdr.udp.src_port = src_port_flag;
        hdr.udp.dst_port = eg_md.bvr_md.fwd_vtep_port;

        hdr.ipv4.src_addr = eg_md.bvr_md.outer_dst_addr;
        hdr.ipv4.dst_addr = eg_md.bvr_md.fwd_vtep_ip;
        hdr.ipv4.diffserv = eg_md.custom_bridge_hdr.out_dscp;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;

        hdr.ethernet.src_addr = eg_md.bvr_md.outer_dst_mac;
        hdr.ethernet.dst_addr = eg_md.bvr_md.outer_src_mac;
    }

    action forward_to_x86_bvr(){
        hdr.udp.dst_port = eg_md.custom_bridge_hdr.fwd_x86_vtep_port;

        //only dst_addr is enough, no need to set src_addr, 
        hdr.ipv4.dst_addr = eg_md.custom_bridge_hdr.fwd_x86_vtep_ip;

        hdr.ethernet.src_addr = eg_md.bvr_md.outer_dst_mac;
        hdr.ethernet.dst_addr = eg_md.bvr_md.outer_src_mac;
    }

    action forward_vtep_reply_icmpv4(){
        hdr.icmpv4.type = ICMP_TYPE_REPLY;
        hdr.icmpv4.hdr_checksum = hdr.icmpv4.hdr_checksum + ICMPV4_REQUEST_INCREMENTAL_CHECKSUM_UPDATE;

        hdr.ipv4.src_addr = eg_md.bvr_md.outer_dst_addr;
        hdr.ipv4.dst_addr = eg_md.bvr_md.outer_src_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;

        hdr.ethernet.src_addr = eg_md.bvr_md.outer_dst_mac;
        hdr.ethernet.dst_addr = eg_md.bvr_md.outer_src_mac;
    }

    action forward_gw_reply_icmpv4(){
        hdr.inner_icmpv4.type = ICMP_TYPE_REPLY;
        hdr.inner_icmpv4.hdr_checksum = hdr.inner_icmpv4.hdr_checksum + ICMPV4_REQUEST_INCREMENTAL_CHECKSUM_UPDATE;

        hdr.inner_ipv4.src_addr = eg_md.bvr_md.inner_dst_addr;
        hdr.inner_ipv4.dst_addr = eg_md.bvr_md.inner_src_addr;
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;

        hdr.inner_ethernet.dst_addr = eg_md.bvr_md.inner_src_mac;
        hdr.inner_ethernet.src_addr = eg_md.bvr_md.inner_dst_mac;

        hdr.vxlan.vni = eg_md.custom_bridge_hdr.next_vni;
        hdr.vxlan.flags = VXLAN_FLAGS;

        hdr.udp.src_port = src_port_flag;
        hdr.udp.dst_port = eg_md.bvr_md.fwd_vtep_port;

        hdr.ipv4.src_addr = eg_md.bvr_md.outer_dst_addr;
        hdr.ipv4.dst_addr = eg_md.bvr_md.outer_src_addr;
        hdr.ipv4.diffserv = eg_md.custom_bridge_hdr.out_dscp;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;

        hdr.ethernet.src_addr = eg_md.bvr_md.outer_dst_mac;
        hdr.ethernet.dst_addr = eg_md.bvr_md.outer_src_mac;
    }

    action forward_gw_reply_arp(){
        hdr.inner_arp.opcode = ARPOP_ARP_REPLY;

        hdr.inner_arp.dst_addr = hdr.inner_arp.src_addr;
        hdr.inner_arp.src_addr = eg_md.custom_bridge_hdr.vport_mac;

        hdr.inner_arp.src_ip = eg_md.bvr_md.inner_dst_addr;
        hdr.inner_arp.dst_ip = eg_md.bvr_md.inner_src_addr;

        //TODO(yangguang22):for tmp, with vpc
        //hdr.inner_ethernet.dst_addr = hdr.inner_ethernet.src_addr;
        //hdr.inner_ethernet.src_addr = eg_md.custom_bridge_hdr.vport_mac2;

        hdr.udp.src_port = src_port_flag;

        hdr.ipv4.src_addr = eg_md.bvr_md.outer_dst_addr;
        hdr.ipv4.dst_addr = eg_md.bvr_md.outer_src_addr;
        hdr.ipv4.diffserv = eg_md.custom_bridge_hdr.out_dscp;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;

        hdr.ethernet.src_addr = eg_md.bvr_md.outer_dst_mac;
        hdr.ethernet.dst_addr = eg_md.bvr_md.outer_src_mac;
    }

    apply {
        src_port_flag = src_port_hash.get({
            eg_md.custom_bridge_hdr.ip_proto,
            eg_md.bvr_md.inner_src_addr,
            eg_md.bvr_md.inner_dst_addr,
            eg_md.custom_bridge_hdr.l4_src_port,
            eg_md.custom_bridge_hdr.l4_dst_port
        });

        if (src_port_flag < SRC_PORT_MIN) {
            src_port_flag = src_port_flag + SRC_PORT_MIN;
        }


        src_port_flag = 17;

        eg_dprsr_md.drop_ctl = TBVR_PACKET_NO_DROP_FLAG;

        if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_NORMAL) {
            forward_normal();
        } else if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_TO_X86_BVR) {
            forward_to_x86_bvr();
        } else if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_VTEP_REPLY_ICMPV4) {
            forward_vtep_reply_icmpv4();
        } else if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_GW_REPLY_ICMPV4) {
            forward_gw_reply_icmpv4();
        } else if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_GW_REPLY_ARP) {
            forward_gw_reply_arp();
        } else if (eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_DROP
                || eg_md.custom_bridge_hdr.fwd_type == forward_type_t.FORWARD_ABNORMAL) {
            eg_dprsr_md.drop_ctl = TBVR_PACKET_DROP_FLAG;
        } else {
            //set forward cpu and other type to drop
            eg_dprsr_md.drop_ctl = TBVR_PACKET_DROP_FLAG;
        }
    }
}
# 21 "/vm_share/tofino-bvr/tofino_bvr.p4" 2
# 1 "/vm_share/tofino-bvr/mirror/tbvr_mirror.p4" 1



# 1 "/vm_share/tofino-bvr/mirror/../include/headers.p4" 1
# 5 "/vm_share/tofino-bvr/mirror/tbvr_mirror.p4" 2
# 1 "/vm_share/tofino-bvr/mirror/../include/tbvr_metadata.p4" 1
# 6 "/vm_share/tofino-bvr/mirror/tbvr_mirror.p4" 2
# 1 "/vm_share/tofino-bvr/mirror/../include/tbvr_common.p4" 1
# 7 "/vm_share/tofino-bvr/mirror/tbvr_mirror.p4" 2
# 1 "/vm_share/tofino-bvr/mirror/../include/tbvr_defines.p4" 1
# 8 "/vm_share/tofino-bvr/mirror/tbvr_mirror.p4" 2

control TBvrIngressMirrorAcl(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_pre_mirror_counter;

    action ingress_acl_mirror(MirrorId_t session_id) {
        ig_md.mirror_session_id = session_id;
        ig_md.bvr_md.mirror_md.pkt_type = PKT_SRC_CLONED_INGRESS;
        ig_intr_md_for_dprsr.mirror_type = MIRROR_TYPE_I2E;
        direct_pre_mirror_counter.count();
    }

    table acl {
        key = {
            ig_md.bvr_md.lkp_md.ip_src_addr : ternary; ig_md.bvr_md.lkp_md.ip_dst_addr : ternary; ig_md.bvr_md.lkp_md.ip_proto : ternary; ig_md.bvr_md.lkp_md.l4_src_port : range; ig_md.bvr_md.lkp_md.l4_dst_port : range;
            ig_md.bvr_md.vpc_md.vpc_id : ternary;
            ig_md.bvr_md.vpc_md.in_vport_type : ternary;
        }

        actions = {
            ingress_acl_mirror();
        }

        size = MIRROR_ACL_TABLE_SIZE;
        counters = direct_pre_mirror_counter;
    }

    apply {
        acl.apply();
    }
}

control TBvrEgressMirrorAcl(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_post_mirror_counter;

    action egress_acl_mirror(MirrorId_t session_id) {
        eg_md.mirror_session_id = session_id;
        eg_md.eg_mirror_md.pkt_type = PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.mirror_type = MIRROR_TYPE_E2E;
        direct_post_mirror_counter.count();
    }

    table acl {
        key = {
            hdr.inner_ipv4.src_addr : ternary; hdr.inner_ipv4.dst_addr : ternary; eg_md.custom_bridge_hdr.ip_proto : ternary; eg_md.custom_bridge_hdr.l4_src_port : range; eg_md.custom_bridge_hdr.l4_dst_port : range;
            eg_md.custom_bridge_hdr.vpc_id : ternary;
            eg_md.custom_bridge_hdr.out_vport_type : ternary;
        }

        actions = {
            egress_acl_mirror();
        }

        size = MIRROR_ACL_TABLE_SIZE;
        counters = direct_post_mirror_counter;
    }

    apply {
        acl.apply();
    }
}
# 22 "/vm_share/tofino-bvr/tofino_bvr.p4" 2

// NOTE(huangbing01): UDP && ICMP is considered in parser
void mark_active_access_for_tcp(in bit<8> tcp_flags, inout pkt_info_metadata_t pkt_md) {
    if (pkt_md.inner_l4_msg_type == msg_type_t.MSG_TYPE_TCP
        && (tcp_flags & TCP_SYN_FLAG) == TCP_SYN_FLAG
        && (tcp_flags & TCP_ACK_FLAG) == TCP_FLAG_NON) {
        pkt_md.is_active_access = 1;
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    TBvrDowngradeToX86BVR() downgrade_to_x86bvr;
    TBvrVPCIngress() vpc_ingress;
    TBvrIngressAcl() acl_pre;
    TBvrIngressMirrorAcl() ingress_mirror_acl;
    TBvrRoute() bvr_route;
    TBvrVPCEgress() vpc_egress;
    Ingress2EgressBridge() ingress_2_egress_bridge;

    apply {
        if (ig_md.bvr_md.pkt_md.ipv4_checksum_err
            || ig_md.bvr_md.pkt_md.inner_ipv4_checksum_err) {
            forward_abnormal(ig_md.bvr_md.fwd_md.fwd_type_of_parser);
        } else if (ig_intr_md.ingress_port == TOFINO_CPU_PCIE_PORT) {
            // forward packets from CPU PCIE port to physical port
            forward_pkts_from_cpu_to_physical_port(hdr, ig_tm_md);
            exit;
        } else if (ig_md.bvr_md.fwd_md.fwd_type_of_parser != forward_type_t.FORWARD_DROP) {
            bit<9> egress_port = 0x0;

            downgrade_to_x86bvr.apply(ig_md);
            vpc_ingress.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
            egress_port = ig_tm_md.ucast_egress_port;

            // if we move these lines into the if below, a runtime error may happen during ingress parser
            // NOTE(huangbing01): https://support.barefootnetworks.com/hc/en-us/requests/11377
            mark_active_access_for_tcp(hdr.inner_tcp.flags, ig_md.bvr_md.pkt_md);

            acl_pre.apply(hdr, ig_md);
            ingress_mirror_acl.apply(hdr, ig_md, ig_dprsr_md);
            bvr_route.apply(hdr, ig_md);
            vpc_egress.apply(hdr, ig_md);

            // move the following two lines from right after vpc_ingress to here to save one stage
            if (egress_port == TOFINO_CPU_PCIE_PORT) {
                exit;
            }
        } else {
            // packet should be dropped, do nothing
        }

        ingress_2_egress_bridge.apply(hdr, ig_md);

        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_tm_md)
{
    TBvrEgressAcl() acl_post;
    TBvrEgressMirrorAcl() egress_mirror_acl;
    TBvrEgressForward() bvr_egress_forward;
    TBvrVtep() bvr_vtep;
    TBvrStat() bvr_stat;

    apply{
        if (eg_md.by_pass == egress_by_pass_t.EGRESS_BYPASS_NONE) {
            acl_post.apply(hdr, eg_md);
            egress_mirror_acl.apply(hdr, eg_md, eg_dprsr_md);
            bvr_egress_forward.apply(hdr, eg_md);
            bvr_vtep.apply(hdr, eg_md, eg_dprsr_md);
            bvr_stat.apply(eg_md);
        } else {
            //EGRESS_BYPASS_MIRROR_ACL
            //all mirror pkt forward cpu now, TODO mirror to other port by remote ip by tunnel
            bit<16> port = (bit<16>)eg_intr_md.egress_port;
            egress_forward_pkts_from_physical_port_to_cpu(hdr, port);
        }
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;

