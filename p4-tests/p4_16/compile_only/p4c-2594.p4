# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4"
# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 2 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 1
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


# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 1
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




# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2
# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino.p4" 2

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
# 24 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2
# 1 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino_fixed.p4" 1
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

// Fixed function blocks in Tofino are configured by bf_runtime through a
// table-based API. Each table requires a unique name that is not used by the
// user-defined table in P4 program. These fixed function blocks are
// instantiated as a top level extern instances. Their names are reserved at
// top level and used by bf_runtime.
//
// These extern constructs are NOT to be used in any P4 programs.

extern PacketReplicationEngine {
    PacketReplicationEngine();
}

PacketReplicationEngine() pre;

extern MirrorEngine {
    MirrorEngine();
}

MirrorEngine() mirror;

extern PortConfigrationEngine {
    PortConfigrationEngine();
}

PortConfigrationEngine() port;

extern TrafficManager {
    TrafficManager();
}

TrafficManager() tm;

extern PacketGenerationEngine {
    PacketGenerationEngine();
}

PacketGenerationEngine() pktgen;
# 25 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2

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
# 21 "/home/kevin/sde/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 2
# 3 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/util.p4" 1



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



        pkt.advance(64);

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

// Empty egress parser/control blocks
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 4 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/headers.p4" 1



typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_BF_FABRIC = 16w0x9000;


typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 8w1;
const ip_protocol_t IP_PROTOCOLS_TCP = 8w6;
const ip_protocol_t IP_PROTOCOLS_UDP = 8w17;
const ip_protocol_t IP_PROTOCOLS_GRE = 8w47;

/* definition headers length */
const bit<16> IP_LEN = 16w20;
const bit<16> GRE_LEN = 16w4;
const bit<16> GRE_KEY_OPT_KEN = 16w4;
const bit<16> GRE_CSUM_OPT_LEN = 16w4;

/* outter ip + gre + gre_key */
const bit<16> IP_GRE_OPT_KEY_LEN = 16w28;

/* outter ip + gre + gre_key + gre_csum */
const bit<16> IP_GRE_OPT_KEY_CSUM_LEN = 16w32;

/* Ingress mirroring information */
# 47 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/headers.p4"
/* IP MTU. */


/*
* 1500 - 32(gre:4 + opt_ket:4 + opt_csum:4 +out_ip:20) = 1468 
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

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<1> flag_rs;
    bit<1> flag_df;
    bit<1> flag_mf;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header option_word_h {
    bit<32> data;
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
    bit<8> msg_type;
    bit<8> msg_code;
    bit<16> checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header arp_ipv4_h {
    mac_addr_t src_hw_addr;
    ipv4_addr_t src_proto_addr;
    mac_addr_t dst_hw_addr;
    ipv4_addr_t dst_proto_addr;
}

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

header gre_opt_key_h {
    bit<32> key;
}

header gre_opt_csum_h {
    bit<32> gw_ip;
}

header fabric_header_h {
    bit<3> packetType;
    bit<2> headerVersion;
    bit<2> packetVersion;
    bit<1> pad1;

    bit<3> fabricColor;
    bit<5> fabricQos;

    bit<8> dstDevice;
    bit<16> dstPortOrGroup;
}

header fabric_header_cpu_h {
    bit<5> egressQueue;
    bit<1> txBypass;
    bit<2> reserved;

    bit<16> ingressPort;
    bit<16> ingressIfindex;
    bit<16> ingressBd;

    bit<16> reasonCode;
}

header fabric_payload_header_h {
    bit<16> etherType;
}






header inthdr_h {
    bit<8> header_type;
}

/* 
 *Bridged metadata: 28 byte free, after that minimum packet size will be impacted.
*/
header bridge_meta_h {
    bit<8> header_type;
    bit<7> pad0; PortId_t ingress_port;
    bit<32> local_bip;

    bit<16> iph_id;
    bit<32> local_pvgw_info__vip;

    bit<48> tx_phy_port__mac;
    bit<48> tx_phy_port__gw_mac;
}

typedef bridge_meta_h ing_port_mirror_h;


/*
* no use in stage and will be storaged in TPHV.
* used to prevent compile optimization only.
*/
header payload_frag_h {
    bit<16> data;
}
# 5 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/types.p4" 1



# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/dump_header.p4" 1
# 18 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/dump_header.p4"
header dump_h {
/*
    bit<1> ingress;
    bit<1> egress;
    bit<1> from_cpu;
    bit<1> to_cpu;
    bit<1> arp_handler;
    bit<1> icmp_handler;
    bit<1> drop_by_rule;
    bit<1> check_error;
    bit<1> decap_error;
    bit<1> ingress_ip_rnet;
    bit<1> ingress_ip_vpc;
    bit<1> route_not_find;
    bit<19> reserved;
*/
    bit<32> flags;
}
# 5 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/types.p4" 2

/* vpcid of physical network (-1) */
# 21 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/types.p4"
typedef bit<64> switch_uint64_t;
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef bit<8> header_type_t;
typedef bit<8> header_info_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

/*****************sys info*************************/

struct local_pvgw_info_t {
    switch_uint32_t vip;
}

struct physical_port_t {
    switch_port_t port_id;
    ipv4_addr_t ip;
    ipv4_addr_t gw_ip;
    mac_addr_t mac;
    mac_addr_t gw_mac;
}

/*****************vpc info**************************/

struct vpc_rt_entry_t {
    switch_uint32_t remote_ip;
    switch_uint32_t vpcid;
}

struct pvgw_header_t {
    bridge_meta_h bridge;

    ethernet_h ethernet;
    fabric_header_h fabric_header;
    fabric_header_cpu_h fabric_header_cpu;
    fabric_payload_header_h fabric_payload_header;

    ipv4_h ipv4;
    option_word_h ip_opt_word_1;
    option_word_h ip_opt_word_2;
    option_word_h ip_opt_word_3;
    option_word_h ip_opt_word_4;
    option_word_h ip_opt_word_5;
    option_word_h ip_opt_word_6;
    option_word_h ip_opt_word_7;
    option_word_h ip_opt_word_8;
    option_word_h ip_opt_word_9;
    option_word_h ip_opt_word_10;

    ipv4_h inner_ipv4;

    gre_h gre;
    gre_opt_key_h gre_opt_key;
    gre_opt_csum_h gre_opt_csum;
    icmp_h icmp;
    arp_h arp;
    arp_ipv4_h arp_ipv4;

    ipv4_h new_out_ipv4;
    gre_h new_gre;
    gre_opt_key_h new_gre_opt_key;
    gre_opt_csum_h new_gre_opt_csum;

    dump_h dump;

    payload_frag_h payload_frag;
}

struct pvgw_ingress_metadata_t {
    switch_port_t ingress_port;

    bit<8> multi_or_broad_flag;
    bit<1> ipv4_checksum_err;
    switch_uint16_t inner_ipv4_checksum_val;
    switch_uint8_t ipv4_ttl;

    switch_uint32_t vpcid;
    ipv4_addr_t local_bip;

    local_pvgw_info_t local_pvgw_info;
    physical_port_t tx_phy_port;
    switch_uint16_t iph_id;

    header_type_t mirror_header_type;
    switch_uint16_t mirror_session_id;
    bit<32> dump_flag;
}

struct pvgw_egress_metadata_t {

    /* get from ingress  */
    bridge_meta_h bridge;

    switch_port_t ingress_port;
    local_pvgw_info_t local_pvgw_info;
    ipv4_addr_t local_bip;
    switch_uint16_t iph_id;
    physical_port_t tx_phy_port;

    /* get from egress parser or egress */
    vpc_rt_entry_t vpc_rte;

    header_type_t mirror_header_type;
    switch_uint16_t mirror_session_id;
    bit<32> dump_flag;
}
# 6 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/const.p4" 1



/* table size definition  */
const switch_uint32_t VPC_TABLE_SIZE = 1024;
const switch_uint32_t VPC_ROUTE_TABLE_SIZE = 990000;

const switch_uint32_t PHY_PORT_TABLE_SIZE = 32;
const switch_uint8_t PHY_PORT_MAX = 32;

const switch_uint32_t ARP_REPLY_ROUTE_TABLE_SIZE = 1024;
const switch_uint32_t ICMP_REPLY_ROUTE_TABLE_SIZE = 1024;

const switch_uint32_t BIP_MAX_PER_PVGW = 1024;

const switch_uint32_t DROP_IP_RULES_TABLE_SIZE = 1024;

/* header type */
const header_type_t HEADER_TYPE_BRIDGE1 = 0xA;
const header_type_t HEADER_TYPE_BRIDGE2 = 0xB;
const header_type_t HEADER_TYPE_MIRROR_INGRESS = 0xC;
const header_type_t HEADER_TYPE_MIRROR_EGRESS = 0xD;
const header_type_t HEADER_TYPE_RESUBMIT = 0xE;
const header_type_t HEADER_TYPE_DUMP = 0xF;

const MirrorId_t MIRROR_DUMP_ID1 = 255;
const MirrorId_t MIRROR_DUMP_ID2 = 256;
# 7 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/sys_config.p4" 1



# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/dump.p4" 1






control DumpHandler(in pvgw_header_t hdr,
  inout pvgw_ingress_metadata_t ig_md,
  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

 action hit(bit<32> dump_point) {
  // TODO
  // clone and send to ethernet cpu port
  ig_md.dump_flag = (32w0x80000000);
  ig_md.mirror_header_type = HEADER_TYPE_DUMP;
  ig_md.mirror_session_id = (switch_uint16_t)MIRROR_DUMP_ID1;
  ig_dprsr_md.mirror_type = 2;
 }

 table dump_to_cpu {
  key = {
   hdr.gre_opt_key.key : ternary;
   hdr.ipv4.src_addr : ternary;
   hdr.ipv4.dst_addr : ternary;
   hdr.inner_ipv4.src_addr : ternary;
   hdr.inner_ipv4.dst_addr : ternary;
   hdr.ethernet.ether_type : ternary;
  }

  actions = {
   hit;
   @defaultonly NoAction;
  }

  const default_action = NoAction();
  size = 10;
 }

 apply {
  dump_to_cpu.apply();
 }
}

control DumpEgressHandler(in pvgw_header_t hdr,
  inout pvgw_egress_metadata_t eg_md,
  inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{

 action hit(bit<32> dump_point) {
  // TODO
  // clone and send to ethernet cpu port
  eg_md.dump_flag = (32w0x80000000);
  eg_md.mirror_header_type = HEADER_TYPE_DUMP;
  eg_md.mirror_session_id = (switch_uint16_t)MIRROR_DUMP_ID2;
  eg_dprsr_md.mirror_type = 3;
 }

 table dump_to_cpu {
  key = {
   hdr.gre_opt_key.key : ternary;
   hdr.ipv4.src_addr : ternary;
   hdr.ipv4.dst_addr : ternary;
   hdr.inner_ipv4.src_addr : ternary;
   hdr.inner_ipv4.dst_addr : ternary;
  }

  actions = {
   hit;
   @defaultonly NoAction;
  }

  const default_action = NoAction();
  size = 10;
 }

 apply {
  dump_to_cpu.apply();
 }
}

//control DumpIng(inout pvgw_ingress_metadata_t ig_md,
//	in bit<32> point)
//{
//	apply {
//		if (ig_md.dump_flag & DUMP_START != 0) {
//			ig_md.dump_flag = ig_md.dump_flag | point;
//		}
//	}
//}

control DumpEgress(inout pvgw_egress_metadata_t eg_md,
 in bit<32> point)
{
 apply {
  if (eg_md.dump_flag & (32w0x80000000) != 0) {
   eg_md.dump_flag = eg_md.dump_flag | point;
  }
 }
}

control DumpEgressProcess(inout pvgw_header_t hdr,
    in pvgw_egress_metadata_t eg_md)
{
    action add_cpu_header(
        bit<16> reason_code) {

        hdr.fabric_header.setValid();
        hdr.fabric_header.packetType = 5;
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
        hdr.fabric_header_cpu.ingressBd = 1;
        hdr.fabric_header_cpu.reasonCode = reason_code;
        hdr.fabric_header_cpu.ingressPort = (switch_uint16_t)eg_md.ingress_port;

        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = ETHERTYPE_BF_FABRIC;

 hdr.dump.setValid();
 hdr.dump.flags = eg_md.local_bip;
    }

    apply {
 add_cpu_header(0);
    }
}
# 5 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/sys_config.p4" 2

control GetLocalPvgwInfo(inout pvgw_header_t hdr,
                inout pvgw_ingress_metadata_t ig_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) local_pvgw_info_indr_ct;

    action miss() {
        ig_dprsr_md.drop_ctl = 1;
        local_pvgw_info_indr_ct.count(0);
        exit;
    }

    action hit(ipv4_addr_t vip) {
        ig_md.local_pvgw_info.vip = vip;
    }

    table local_pvgw_info {
        actions = {
            hit;
            miss;
        }

        default_action = miss;
    }

    apply {
     /* get local pvgw info */
        local_pvgw_info.apply();
    }
}

control GetGlobalIPId(inout pvgw_header_t hdr,
                inout pvgw_ingress_metadata_t ig_md){

    Register<switch_uint16_t, bit<32>>(1) global_iph_id_reg;
    RegisterAction<switch_uint16_t, bit<32>, switch_uint16_t>(global_iph_id_reg) global_iph_id_reg_action = {
        void apply(inout switch_uint16_t value, out switch_uint16_t read_value){
            read_value = value;
            value = value + 1;
        }
    };

    apply {
     /* get global iph id */
     ig_md.iph_id = global_iph_id_reg_action.execute(0);
    }

}

control CheckDropIpRules(inout pvgw_header_t hdr,
            inout pvgw_ingress_metadata_t ig_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
            switch_uint32_t drop_ip_rules_table_size){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) drop_ip_rules_indr_ct;

    //DumpIng() dump;

    action miss() {
 //dump.apply(ig_md, DUMP_RULE_DROP);
        ig_dprsr_md.drop_ctl = 1;
        drop_ip_rules_indr_ct.count(0);
        //if (ig_md.dump_flag & DUMP_START == 0) {
        //    exit;
        //}
    }

    action hit() {
    }

    table drop_ip_rules {
        key = {
            hdr.ipv4.src_addr : lpm;
        }

        actions = {
            hit;
            miss;
        }

        const default_action = miss;
        size = drop_ip_rules_table_size;
    }

    apply {

        drop_ip_rules.apply();
    }

}

control SelectMultiBip(inout pvgw_header_t hdr,
            inout pvgw_ingress_metadata_t ig_md)(
            switch_uint32_t bip_max_per_pvgw){

    Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
    ActionProfile(bip_max_per_pvgw) action_selector_ap;
    ActionSelector(action_selector_ap,
                 sel_hash,
                 SelectorMode_t.FAIR,
                 bip_max_per_pvgw,// max group size
                 1 // max number of groups
                 ) action_selector;

    action miss() {
    }

    action hit(ipv4_addr_t bip) {
        ig_md.local_bip = bip;
    }

    table select_bip {
        key = {
            ig_md.local_pvgw_info.vip : exact;
            hdr.ipv4.src_addr : selector;
            hdr.ipv4.dst_addr : selector;
            hdr.ipv4.protocol : selector;
        }

        actions = {
            hit;
            miss;
        }

        default_action = miss;
        size = 1;
        implementation = action_selector;
    }

    apply {
        select_bip.apply();
    }

}
# 8 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/parde.p4" 1




parser IngressParser(packet_in pkt,
    out pvgw_header_t hdr,
    out pvgw_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md){
    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition meta_init;
    }

    state meta_init {
        ig_md.ingress_port = 0;

        ig_md.multi_or_broad_flag = 0;
        ig_md.ipv4_checksum_err = 0;
        ig_md.inner_ipv4_checksum_val = 0;

        ig_md.vpcid = 0;
        ig_md.local_pvgw_info = {0};
        ig_md.iph_id = 0;
        ig_md.mirror_header_type = 0;
 ig_md.dump_flag = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        ig_md.multi_or_broad_flag = pkt.lookahead<bit<8>>();
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_BF_FABRIC : parse_fabric_header;
            default : reject;
        }
    }

    state parse_fabric_header {
        pkt.extract(hdr.fabric_header);
        transition parse_fabric_header_cpu;
    }

    state parse_fabric_header_cpu {
        pkt.extract(hdr.fabric_header_cpu);
        transition parse_fabric_payload_header;
    }

    state parse_fabric_payload_header {
        pkt.extract(hdr.fabric_payload_header);
        transition accept;
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition select(hdr.arp.hw_type, hdr.arp.proto_type) {
            (0x0001, ETHERTYPE_IPV4) : parse_arp_ipv4;
            default: reject;
        }
    }

    state parse_arp_ipv4 {
        pkt.extract(hdr.arp_ipv4);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
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
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.ipv4_checksum_err = (bit<1>)ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_ICMP ) : parse_icmp;
            (IP_PROTOCOLS_GRE ) : parse_gre;
            default : accept;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.K) {
            1 : parse_gre_opt;
            default: reject;
        }
    }

    state parse_gre_opt {
        pkt.extract(hdr.gre_opt_key);
        transition select(hdr.gre.proto) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            default: reject;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.subtract({hdr.inner_ipv4.hdr_checksum});
        inner_ipv4_checksum.subtract({hdr.inner_ipv4.ttl});
        ig_md.inner_ipv4_checksum_val = inner_ipv4_checksum.get();
        transition accept;
    }

}


control IngressDeparser(
        packet_out pkt,
        inout pvgw_header_t hdr,
        in pvgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Mirror() ing_port_mirror;

    apply {

        if (hdr.inner_ipv4.isValid()) {
            hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.ttl, 8w0,
                ig_md.inner_ipv4_checksum_val
                });
        }

        if(hdr.ipv4.isValid()){
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flag_rs,
                hdr.ipv4.flag_df,
                hdr.ipv4.flag_mf,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.ip_opt_word_1,
                hdr.ip_opt_word_2,
                hdr.ip_opt_word_3,
                hdr.ip_opt_word_4,
                hdr.ip_opt_word_5,
                hdr.ip_opt_word_6,
                hdr.ip_opt_word_7,
                hdr.ip_opt_word_8,
                hdr.ip_opt_word_9,
                hdr.ip_opt_word_10
                });
        }

        if (ig_dprsr_md.mirror_type == 1) {
            /* mirror to egress for 1th fragment */
            ing_port_mirror.emit<ing_port_mirror_h>(
                (MirrorId_t)ig_md.mirror_session_id,
                {ig_md.mirror_header_type,
                0, ig_md.ingress_port,
                ig_md.local_bip,
                ig_md.iph_id,
                ig_md.local_pvgw_info.vip,
                ig_md.tx_phy_port.mac,
                ig_md.tx_phy_port.gw_mac
                });
        } else if (ig_dprsr_md.mirror_type == 2) {
            ing_port_mirror.emit<ing_port_mirror_h>(
                (MirrorId_t)ig_md.mirror_session_id,
                {ig_md.mirror_header_type,
                0, ig_md.ingress_port,
                ig_md.dump_flag,
                ig_md.iph_id,
                ig_md.local_pvgw_info.vip,
                ig_md.tx_phy_port.mac,
                ig_md.tx_phy_port.gw_mac
                });
 }

        pkt.emit(hdr.bridge);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric_header);
        pkt.emit(hdr.fabric_header_cpu);
        pkt.emit(hdr.fabric_payload_header);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.gre_opt_csum);
        pkt.emit(hdr.gre_opt_key);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.arp_ipv4);
    }
}

parser EgressParser(packet_in pkt,
    out pvgw_header_t hdr,
    out pvgw_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md){
    TofinoEgressParser() tofino_parser;
    inthdr_h inthdr;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition meta_init;
    }

    state meta_init {
        eg_md.ingress_port = 0;
        eg_md.local_pvgw_info = {0};

        eg_md.local_bip = 0;
        eg_md.iph_id = 0;
        eg_md.vpc_rte = {0,0};
        eg_md.tx_phy_port = {0,0,0,0,0};
        eg_md.mirror_header_type = 0;

        transition parse_pre;
    }

    state parse_pre {
        inthdr = pkt.lookahead<inthdr_h>();
        transition select(inthdr.header_type) {
            ( HEADER_TYPE_BRIDGE2 ) : parse_bridge;
            ( HEADER_TYPE_BRIDGE1 ) : parse_bridge;
            ( HEADER_TYPE_MIRROR_INGRESS ) : parse_bridge;
            ( HEADER_TYPE_DUMP ) : parse_bridge;
            default : reject;
        }
    }

    state parse_bridge {
        pkt.extract(eg_md.bridge);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
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
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        /* shrinking the live range of select fields, the size of match key register is 32bit only. */
        transition select(eg_md.bridge.header_type) {
            (HEADER_TYPE_BRIDGE1) : accept;
            (HEADER_TYPE_MIRROR_INGRESS) : accept;
            (HEADER_TYPE_DUMP) : parse_dump;
            (HEADER_TYPE_BRIDGE2) : parse_do_fragment;
            default : reject;
        }

    }

    state parse_dump {
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_GRE) : parse_gre;
            default : accept;
 }
    }

    state parse_do_fragment {
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);//320byte
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(192);//440byte

        pkt.extract(hdr.payload_frag);
        transition accept;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.K) {
            1 : parse_gre_opt;
            default: reject;
        }
    }

    state parse_gre_opt {
        pkt.extract(hdr.gre_opt_key);
        transition select(hdr.gre.proto) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            default: reject;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition accept;
    }
}

control EgressDeparser(
        packet_out pkt,
        inout pvgw_header_t hdr,
        in pvgw_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Checksum() new_out_ipv4_checksum;
    Checksum() ipv4_checksum;
    Mirror() egr_port_mirror;

    apply {

        if(hdr.new_out_ipv4.isValid()){
            hdr.new_out_ipv4.hdr_checksum = new_out_ipv4_checksum.update({
                hdr.new_out_ipv4.version,
                hdr.new_out_ipv4.ihl,
                hdr.new_out_ipv4.diffserv,
                hdr.new_out_ipv4.total_len,
                hdr.new_out_ipv4.identification,
                hdr.new_out_ipv4.flag_rs,
                hdr.new_out_ipv4.flag_df,
                hdr.new_out_ipv4.flag_mf,
                hdr.new_out_ipv4.frag_offset,
                hdr.new_out_ipv4.ttl,
                hdr.new_out_ipv4.protocol,
                hdr.new_out_ipv4.src_addr,
                hdr.new_out_ipv4.dst_addr
                });
        }

        if(hdr.ipv4.isValid()){
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flag_rs,
                hdr.ipv4.flag_df,
                hdr.ipv4.flag_mf,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.ip_opt_word_1,
                hdr.ip_opt_word_2,
                hdr.ip_opt_word_3,
                hdr.ip_opt_word_4,
                hdr.ip_opt_word_5,
                hdr.ip_opt_word_6,
                hdr.ip_opt_word_7,
                hdr.ip_opt_word_8,
                hdr.ip_opt_word_9,
                hdr.ip_opt_word_10
                });
        }

        if (eg_dprsr_md.mirror_type == 3) {
            /* mirror to egress for 1th fragment */
            egr_port_mirror.emit<ing_port_mirror_h>(
                (MirrorId_t)eg_md.mirror_session_id,
                {eg_md.mirror_header_type,
                0, eg_md.ingress_port,
                eg_md.local_bip,
                eg_md.iph_id,
                eg_md.local_pvgw_info.vip,
                eg_md.tx_phy_port.mac,
                eg_md.tx_phy_port.gw_mac
                });
        }

        pkt.emit(hdr.ethernet);
 /* add dump flags after eth header. */
        pkt.emit(hdr.dump);

        pkt.emit(hdr.new_out_ipv4);
        pkt.emit(hdr.new_gre);
        pkt.emit(hdr.new_gre_opt_key);
        pkt.emit(hdr.new_gre_opt_csum);

        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);

        pkt.emit(hdr.payload_frag);

    }
}
# 9 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/port.p4" 1



control IngressFindPhysicalPort(inout pvgw_header_t hdr,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
            inout physical_port_t phy_port_info)(
            switch_uint32_t phy_port_table_size) {

    /* phy port tx stats */
 DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) physical_port_dr_ct;
 action hit(ipv4_addr_t ip, mac_addr_t mac, ipv4_addr_t gw_ip, mac_addr_t gw_mac){
  phy_port_info.ip = ip;
  phy_port_info.gw_ip = gw_ip;
  phy_port_info.mac = mac;
  phy_port_info.gw_mac = gw_mac;
  physical_port_dr_ct.count();
 }

    action miss() {
        ig_dprsr_md.drop_ctl = 1;
        physical_port_dr_ct.count();
  exit;
    }

 table physical_port {
  key = {
   phy_port_info.port_id : exact;
  }

  actions = {
   hit;
   miss;
  }

  counters = physical_port_dr_ct;
  const default_action = miss;
  size = phy_port_table_size;
 }

 apply {
  physical_port.apply();
 }
}
# 10 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/cpu.p4" 1



control FromPcieCpuPort(
  inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md){

 Counter<bit<64>, switch_uint8_t>(2, CounterType_t.PACKETS_AND_BYTES) from_pcie_port_indr_ct;

    action set_egress_port() {
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }

    apply {
     if(hdr.fabric_header.isValid()) {
      set_egress_port();
            /* pkts from pcie stats */
            from_pcie_port_indr_ct.count(0);
     }else {
            /* pkts err from pcie cpu port */
      ig_dprsr_md.drop_ctl = 1;
      from_pcie_port_indr_ct.count(1);
   exit;
     }

    }
}


control ToPcieCpuPort(
  inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) to_pcie_port_indr_ct;

    action add_cpu_header(
        bit<16> reason_code) {

        hdr.fabric_header.setValid();
        hdr.fabric_header.packetType = 5;
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
        hdr.fabric_header_cpu.ingressBd = 1;
        hdr.fabric_header_cpu.reasonCode = reason_code;
        hdr.fabric_header_cpu.ingressPort = (switch_uint16_t)ig_md.ingress_port;

        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = ETHERTYPE_BF_FABRIC;
        ig_tm_md.ucast_egress_port = 192;

    }

    apply {
  add_cpu_header(0);
        /* pkts to pcie stats */
        to_pcie_port_indr_ct.count(0);
    }
}
# 11 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/vpc.p4" 1



control DoVpcTrafficStats1(inout pvgw_header_t hdr,
            inout pvgw_ingress_metadata_t ig_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
            switch_uint32_t vpc_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vpc_dr_ct;
    action hit(){
        vpc_dr_ct.count();
    }

 action miss() {
        vpc_dr_ct.count();
    }

    table vpc_stats {
        key = {
            ig_md.vpcid : exact;
        }

        actions = {
            hit;
            miss;
        }

        counters = vpc_dr_ct;
        const default_action = miss;
        size = vpc_table_size;
    }

    apply {
        vpc_stats.apply();
    }
}

control DoVpcTrafficStats2(inout pvgw_header_t hdr,
            inout pvgw_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
            switch_uint32_t vpc_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vpc_dr_ct;
    action hit(){
        vpc_dr_ct.count();
    }

 action miss() {
        vpc_dr_ct.count();
    }

//@placement_priority(-10)
    table vpc_stats {
        key = {
            eg_md.vpc_rte.vpcid : exact;
        }

        actions = {
            hit;
            miss;
        }

        counters = vpc_dr_ct;
        const default_action = miss;
        size = vpc_table_size;
    }

    apply {
        vpc_stats.apply();
    }
}


control FindVpcRoute(inout pvgw_header_t hdr,
            inout pvgw_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
            switch_uint32_t vpc_route_table_size) {

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) vpc_route_indr_ct;

 action hit(ipv4_addr_t remote_ip, switch_uint32_t vpcid){
  eg_md.vpc_rte.remote_ip = remote_ip;
  eg_md.vpc_rte.vpcid = vpcid;
 }

    action miss() {
        vpc_route_indr_ct.count(0);
        exit;
    }

//@placement_priority(-1)
 table vpc_route {
  key = {
   hdr.ipv4.dst_addr : exact;
  }

  actions = {
   hit;
   miss;
  }

  const default_action = miss;
  size = vpc_route_table_size;
 }

    apply {
        vpc_route.apply();
    }
}
# 12 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2

# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/l2.p4" 1



control L2Handler(inout pvgw_header_t hdr,
                inout pvgw_ingress_metadata_t ig_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

 apply{
  ig_md.vpcid = (32w0xffffffff);
  ig_tm_md.ucast_egress_port = ig_md.ingress_port;
 }
}
# 14 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/l3.p4" 1



control IpHandler(inout pvgw_header_t hdr,
                inout pvgw_ingress_metadata_t ig_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Counter<bit<64>, switch_uint8_t>(5, CounterType_t.PACKETS_AND_BYTES) ip_handler_indr_ct;
    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) ip_handler_ttl_indr_ct;

    //DumpIng() dump;

 apply {
  if(hdr.ipv4.isValid()) {
            if(ig_md.ipv4_checksum_err == 0) {

                if(hdr.ipv4.dst_addr == ig_md.local_pvgw_info.vip){
                    if (hdr.gre.isValid()
                        && hdr.gre_opt_key.isValid()
                        && hdr.inner_ipv4.isValid()) {

                        ig_md.vpcid = hdr.gre_opt_key.key;
                        ig_md.ipv4_ttl = hdr.inner_ipv4.ttl;

                        /* from vnet stats */
                        ip_handler_indr_ct.count(3);
                    } else {
                        /* tunnel packet decap error  */
                        //dump.apply(ig_md, DUMP_DECAP_ERR);
                        ig_dprsr_md.drop_ctl = 1;
                        ip_handler_indr_ct.count(2);
   if (ig_md.dump_flag & (32w0x80000000) == 0) {
                            exit;
   }
                    }

                } else {
                    ig_md.ipv4_ttl = hdr.ipv4.ttl;

                    /* from rnet stats */
                    ip_handler_indr_ct.count(4);
                }

            } else {
                //dump.apply(ig_md, DUMP_CHECK_ERR);
                /* ip header csum check error  */
                ig_dprsr_md.drop_ctl = 1;
                ip_handler_indr_ct.count(1);
  if (ig_md.dump_flag & (32w0x80000000) == 0) {
                    exit;
  }
            }

  }else {
            /* unknow proto pkts */
            ig_dprsr_md.drop_ctl = 1;
            ip_handler_indr_ct.count(0);
            exit;
  }

  /* TTL check */
  if(ig_md.ipv4_ttl < 2) {

            /* ip header ttl error  */
   ig_dprsr_md.drop_ctl = 1;
            ip_handler_ttl_indr_ct.count(0);
   exit;
  }
 }
}


control IpOutputEgress(inout pvgw_header_t hdr,
                  inout pvgw_ingress_metadata_t ig_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){

    apply {
        hdr.bridge.setValid();

        bit<11> tem = (bit<11>)1468;
        bit<5> high_value = (bit<5>)(hdr.ipv4.total_len >> 11);
        bit<11> low_value = (bit<11>)(hdr.ipv4.total_len);

        if(high_value > 0 || low_value > tem) {
            /* notify egress parser to do fragment. */
            hdr.bridge.header_type = HEADER_TYPE_BRIDGE2;

            ig_dprsr_md.mirror_type = 1;
            ig_md.mirror_session_id = (switch_uint16_t)ig_md.ingress_port + 1;

            ig_md.mirror_header_type = HEADER_TYPE_MIRROR_INGRESS;
        } else {
            /* not do fragment */
            hdr.bridge.header_type = HEADER_TYPE_BRIDGE1;
        }

        hdr.bridge.pad0 = 0;
        hdr.bridge.ingress_port = ig_md.ingress_port;
        hdr.bridge.local_pvgw_info__vip = ig_md.local_pvgw_info.vip;
        hdr.bridge.iph_id = ig_md.iph_id;

        hdr.bridge.tx_phy_port__mac = ig_md.tx_phy_port.mac;
        hdr.bridge.tx_phy_port__gw_mac = ig_md.tx_phy_port.gw_mac;

        hdr.bridge.local_bip = ig_md.local_bip;

    }

}

control IpOutputRnet(inout pvgw_header_t hdr,
                  inout pvgw_ingress_metadata_t ig_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) ip_output_rnet_indr_ct;

    apply {
        hdr.gre.setInvalid();
        hdr.gre_opt_key.setInvalid();
        hdr.gre_opt_csum.setInvalid();

        hdr.ipv4.setInvalid();
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;

        /* set ethernet */
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        hdr.ethernet.src_addr = ig_md.tx_phy_port.mac;
        hdr.ethernet.dst_addr = ig_md.tx_phy_port.gw_mac;
        hdr.ethernet.setValid();

        ip_output_rnet_indr_ct.count(0);
    }
}


control IpOutputVnet(inout pvgw_header_t hdr,
                  inout pvgw_egress_metadata_t eg_md,
                  inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) ip_output_vnet_indr_ct;

    apply {

        ip_output_vnet_indr_ct.count(0);
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.new_out_ipv4 = {0,0,0,0,0,0,0,0,0,0,0,0,0,0};
        /* pack gre tunnel*/
        hdr.new_gre.K = 1;
        hdr.new_gre.version = (3w1);
        hdr.new_gre.proto = ETHERTYPE_IPV4;
        hdr.new_gre_opt_key.key = eg_md.vpc_rte.vpcid;
        hdr.new_gre.flags = 0;
        hdr.new_gre.setValid();
        hdr.new_gre_opt_key.setValid();

        if (eg_md.local_bip != 0) {
            hdr.new_out_ipv4.src_addr = eg_md.local_bip;
        } else {
            hdr.new_out_ipv4.src_addr = eg_md.local_pvgw_info.vip;
        }

        hdr.new_out_ipv4.dst_addr = eg_md.vpc_rte.remote_ip;
        hdr.new_out_ipv4.ttl = 64;

        hdr.new_out_ipv4.total_len = hdr.ipv4.total_len + IP_GRE_OPT_KEY_LEN;

        hdr.new_out_ipv4.ihl = (bit<4>)(IP_LEN >> 2);
        hdr.new_out_ipv4.identification = eg_md.iph_id;
        hdr.new_out_ipv4.frag_offset = 0;
        hdr.new_out_ipv4.protocol = IP_PROTOCOLS_GRE;
        hdr.new_out_ipv4.version = 4;
        hdr.new_out_ipv4.setValid();

        /* set ethernet */
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        hdr.ethernet.src_addr = eg_md.tx_phy_port.mac;
        hdr.ethernet.dst_addr = eg_md.tx_phy_port.gw_mac;
        hdr.ethernet.setValid();

    }

}
# 15 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/arp.p4" 1




control ArpHandler(inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)(
        switch_uint32_t arp_reply_route_table_size) {

 Counter<bit<64>, switch_uint8_t>(2, CounterType_t.PACKETS_AND_BYTES) arp_reply_indr_ct;

 ToPcieCpuPort() toPcieCpuPort;
 bool is_to_cpu = false;

 action hit(){
 /* send arp reply */
        hdr.ethernet.dst_addr = hdr.arp_ipv4.src_hw_addr;
        hdr.ethernet.src_addr = ig_md.tx_phy_port.mac;

        ipv4_addr_t tmp_ipv4 = hdr.arp_ipv4.dst_proto_addr;
        hdr.arp.opcode = 2;
        hdr.arp_ipv4.dst_hw_addr = hdr.arp_ipv4.src_hw_addr;
        hdr.arp_ipv4.dst_proto_addr = hdr.arp_ipv4.src_proto_addr;
        hdr.arp_ipv4.src_hw_addr = ig_md.tx_phy_port.mac;
        hdr.arp_ipv4.src_proto_addr = tmp_ipv4;
 }

    action miss() {
    }

 table arp_reply {
  key = {
   hdr.arp_ipv4.dst_proto_addr : exact;
  }

  actions = {
   hit;
   miss;
  }

  const default_action = miss;
  size = arp_reply_route_table_size;
 }

 apply {

  if(hdr.arp.isValid() && hdr.arp_ipv4.isValid()) {
   if(hdr.arp.opcode == 1){
    if(!arp_reply.apply().hit){
     is_to_cpu = true;
    }
   }else {
     is_to_cpu = true;
   }

   if(is_to_cpu) {
    /*send to hostif*/
    toPcieCpuPort.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
   }

   /* arp pkts stats */
   arp_reply_indr_ct.count(1);
  }else {
   /* arp error pkts */
   ig_dprsr_md.drop_ctl = 1;
   arp_reply_indr_ct.count(0);
   exit;
  }

 }
}
# 16 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2
# 1 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/icmp.p4" 1



control IcmpHandler(
  inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)(
        switch_uint32_t icmp_reply_route_table_size) {

 Counter<bit<64>, switch_uint8_t>(2, CounterType_t.PACKETS_AND_BYTES) icmp_reply_indr_ct;
    ToPcieCpuPort() toPcieCpuPort;
    bool is_to_cpu = false;

 action hit(){
  /* send icmp reply */
        mac_addr_t tmp_mac = hdr.ethernet.src_addr;
        ipv4_addr_t tmp_ipv4 = hdr.ipv4.src_addr;

        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = tmp_mac;

        hdr.ipv4.src_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.dst_addr = tmp_ipv4;
        hdr.icmp.msg_type = 0;
        hdr.icmp.checksum = 0;
 }

    action miss() {
    }

 table icmp_reply {
  key = {
   hdr.ipv4.dst_addr : exact;
  }

  actions = {
   hit;
   miss;
  }

  const default_action = miss;
  size = icmp_reply_route_table_size;
 }

 apply {

  if(hdr.ipv4.isValid() && hdr.icmp.isValid()){

   if(hdr.icmp.msg_type == 8){
    if(!icmp_reply.apply().hit){
     is_to_cpu = true;
    }
   }else {
    is_to_cpu = true;
   }

   if(is_to_cpu) {
          /*send to hostif*/
          toPcieCpuPort.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
   }

   /* icmp pkts stats */
   icmp_reply_indr_ct.count(1);
  } else {
   /* icmp error pkts */
   icmp_reply_indr_ct.count(0);
  }

 }
}
# 17 "/media/sf_notes/vm-share/tencent-cloud/p4-pvgw-all/pvgw_main.p4" 2


@pa_no_overlay("ingress", "hdr.fabric_header.packetType")
@pa_no_overlay("ingress", "hdr.fabric_header.headerVersion")
@pa_no_overlay("ingress", "hdr.fabric_header.packetVersion")
@pa_no_overlay("ingress", "hdr.fabric_header.pad1")
@pa_no_overlay("ingress", "hdr.fabric_header.fabricColor")
@pa_no_overlay("ingress", "hdr.fabric_header.fabricQos")
@pa_no_overlay("ingress", "hdr.fabric_header.dstDevice")
@pa_no_overlay("ingress", "hdr.fabric_header.dstPortOrGroup")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressBd")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.reasonCode")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.egressQueue")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.txBypass")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.reserved")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressPort")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressIfindex")
@pa_no_overlay("ingress", "hdr.fabric_payload_header.etherType")

control IngressIP(
        inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    IpHandler() ipHandler;
    DoVpcTrafficStats1(VPC_TABLE_SIZE) doVpcTrafficStats1;
    SelectMultiBip(BIP_MAX_PER_PVGW) selectMultiBip;

    IpOutputEgress() ipOutputEgress;
    IpOutputRnet() ipOutputRnet;
    //DumpIng()           dump;

    apply{
        ipHandler.apply(hdr, ig_md, ig_dprsr_md);
 if (ig_dprsr_md.drop_ctl == 1) {
  return;
 }

        if(ig_md.vpcid == (32w0xffffffff)) {
            //dump.apply(ig_md, DUMP_ING_RNET);
            /* Traffic type one:  from rnet to vnet. */

            /* select multi bip */
            selectMultiBip.apply(hdr, ig_md);

            ig_tm_md.bypass_egress = 0;
            ipOutputEgress.apply(hdr, ig_md, ig_dprsr_md);

        } else {
            //dump.apply(ig_md, DUMP_ING_VNET);
            /* vpc traffic statistic */
            doVpcTrafficStats1.apply(hdr, ig_md, ig_dprsr_md);

            /* Traffic type two:  from vnet to rnet.  */
            ipOutputRnet.apply(hdr, ig_md, ig_dprsr_md);
        }
    }
}

control Ingress(
        inout pvgw_header_t hdr,
        inout pvgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    /* control */
    GetLocalPvgwInfo() getLocalPvgwInfo;
    GetGlobalIPId() getGlobalIPId;

    L2Handler() l2Handler;
    ArpHandler(ARP_REPLY_ROUTE_TABLE_SIZE) arpHandler;
    IcmpHandler(ICMP_REPLY_ROUTE_TABLE_SIZE) icmpHandler;
    IngressIP() ingressIP;

    FromPcieCpuPort() fromPcieCpuPort;

    IngressFindPhysicalPort(PHY_PORT_TABLE_SIZE) findPhysicalPort;

    ToPcieCpuPort() toPcieCpuPort;
    CheckDropIpRules(DROP_IP_RULES_TABLE_SIZE) checkDropIpRules;
    DumpHandler() dump;
    //DumpIng()                                   dump_ingress;

    apply {
        ig_md.ingress_port = ig_intr_md.ingress_port;

        l2Handler.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
        getGlobalIPId.apply(hdr, ig_md);

        ig_md.tx_phy_port.port_id = ig_intr_md.ingress_port;
        ig_tm_md.bypass_egress = 1;

        dump.apply(hdr, ig_md, ig_dprsr_md);
 //dump_ingress.apply(ig_md, DUMP_INGRESS);

        if(ig_intr_md.ingress_port == 192){
            /* packet from cpu port */
            fromPcieCpuPort.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
     //dump_ingress.apply(ig_md, DUMP_F_CPU);
        }else {
            findPhysicalPort.apply(hdr, ig_dprsr_md, ig_md.tx_phy_port);

            if(hdr.arp.isValid()) {
                /* arp */
                arpHandler.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
         //dump_ingress.apply(ig_md, DUMP_ARP);

            } else if(hdr.ipv4.isValid() && hdr.icmp.isValid()) {
                /* icmp */
                icmpHandler.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
         //dump_ingress.apply(ig_md, DUMP_ICMP);

            } else if (ig_md.multi_or_broad_flag == 1
                || hdr.ipv4.dst_addr == ig_md.tx_phy_port.ip) {
                /* send broadcast/muticast/management traffic to cpu hostif */
                toPcieCpuPort.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
         //dump_ingress.apply(ig_md, DUMP_T_CPU);
            } else {
                /* source ip check */
                checkDropIpRules.apply(hdr, ig_md, ig_dprsr_md);
         if (ig_dprsr_md.drop_ctl == 1) {
      return;
         }

                getLocalPvgwInfo.apply(hdr, ig_md, ig_dprsr_md);

                /* ip handle */
                ingressIP.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
            }
        }
    }
}


control Egress(
    /* User */
    inout pvgw_header_t hdr,
    inout pvgw_egress_metadata_t eg_md,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    FindVpcRoute(VPC_ROUTE_TABLE_SIZE) findVpcRoute;
    IpOutputVnet() ipOutputVnet;
    DoVpcTrafficStats2(VPC_TABLE_SIZE) doVpcTrafficStats2;
    DumpEgressProcess() dump_process;
    DumpEgressHandler() dump_handler;

    bit<13> tem_offset;

    action set_ip_offset(){
         hdr.ipv4.frag_offset = tem_offset;
    }

    apply {
        /* init eg_md */
        eg_md.ingress_port = eg_md.bridge.ingress_port;
        eg_md.local_pvgw_info.vip = eg_md.bridge.local_pvgw_info__vip;
        eg_md.local_bip = eg_md.bridge.local_bip;
        eg_md.iph_id = eg_md.bridge.iph_id;
        eg_md.tx_phy_port.mac = eg_md.bridge.tx_phy_port__mac;
        eg_md.tx_phy_port.gw_mac = eg_md.bridge.tx_phy_port__gw_mac;

        if (eg_md.bridge.header_type != HEADER_TYPE_DUMP) {
            tem_offset = (hdr.ipv4.frag_offset + 13w55);
            findVpcRoute.apply(hdr, eg_md, eg_dprsr_md);

            if (eg_md.bridge.header_type == HEADER_TYPE_BRIDGE2) {
                set_ip_offset();
                hdr.ipv4.total_len = hdr.ipv4.total_len - 16w440;
            } else if (eg_md.bridge.header_type == HEADER_TYPE_MIRROR_INGRESS) {
                hdr.ipv4.flag_mf = 0x1;
                hdr.ipv4.total_len = 16w460;
            }

            doVpcTrafficStats2.apply(hdr, eg_md, eg_dprsr_md);
            ipOutputVnet.apply(hdr, eg_md, eg_dprsr_md);
            dump_handler.apply(hdr, eg_md, eg_dprsr_md);
 } else {
            dump_process.apply(hdr, eg_md);
 }
    }
}

Pipeline(IngressParser(),
         Ingress(),
         IngressDeparser(),
         EgressParser(),
         Egress(),
         EgressDeparser()) pipe;

Switch(pipe) main;
