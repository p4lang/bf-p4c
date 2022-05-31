# 1 "test/liraflow/forensics.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "test/liraflow/forensics.p4"
// vim: ts=4:sw=4:et:syntax=c

# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 4 "test/liraflow/forensics.p4" 2
# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tna.p4" 1

# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 1



# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 5 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 2
# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tofino.p4" 1



/**
 Version Notes:

 1.0.1:
 - Initial release
 1.0.2:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH
 1.0.3:
 - Add portable macros and types

*/




# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 20 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tofino.p4" 2

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

    @padding bit<(4 - 9 % 8)> _pad2;

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
    @padding bit<(8 - 9 % 8)> _pad0;

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

    @padding bit<(8 - 5 % 8)> _pad8;

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
    @padding bit<(16 - 9 % 8)> _pad2;
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

extern void funnel_shift_right<T>(inout T dst, in T src1, in T src2, int shift_amount);

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
# 6 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 2

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

@pkginfo(arch="TNA", version="1.0.3")
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
# 3 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tna.p4" 2
# 5 "test/liraflow/forensics.p4" 2

// Test program exceeds Tof1 egress parse depth
@command_line("--disable-parse-max-depth-limit")

# 1 "test/liraflow/precision.p4" 1
// vim: ts=4:sw=4:et:syntax=c

// basic register for storing flow idenifying information
// actions: compare, overwrite
# 19 "test/liraflow/precision.p4"
// one stage of PRECISION: addresses, ports, icmp and a counter
// actions: increment counter (and return value), return value without change, set value (unused)
// _count contains 30 bits of flow-size estimate and 2 bits identifying stage number S
# 7 "test/liraflow/forensics.p4" 2

# 1 "test/liraflow/headers.p4" 1
// vim: ts=4:sw=4:et:syntax=c

// #define NO_SUBSAMPLE
// #define REPORT_FRAGMENTS

// bits of hash per stage (15 => 32K entries)



# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 11 "test/liraflow/headers.p4" 2
# 1 "/home/yxia/bfn/bf-p4c-compilers/build/p4c/p4include/tna.p4" 1
# 12 "test/liraflow/headers.p4" 2

// simple register storing 1 value of type S
# 22 "test/liraflow/headers.p4"
const bit<4> TEMPLATE_INDEX_IPV4 = 4;
const bit<4> TEMPLATE_INDEX_IPV6 = 6;

// port where template and recirculation comes from (ignoring pipe)
const bit<7> PKTGEN_INDEX = 68;

const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86DD;
const bit<16> ETHERTYPE_CONTROL = 0x9000;

const bit<8> IPPROTO_UDP = 0x11;
const bit<8> IPPROTO_TCP = 0x06;
const bit<8> IPPROTO_ICMP = 0x01;
const bit<8> IPPROTO_ICMP6 = 0x3A;

const bit<12> TCPFLAG_FIN = 0x01;
const bit<12> TCPFLAG_RST = 0x04;

typedef bit<4> header_type_t;
typedef bit<4> header_info_t;
const header_type_t HEADER_TYPE_NONE = 0x0;
const header_type_t HEADER_TYPE_MIRROR = 0x1;
const header_type_t HEADER_TYPE_CONTROL = 0x2;
const header_info_t HEADER_INFO_TEMPLATE = 0xF;
const header_info_t HEADER_INFO_MIRROR_DROP = 0xE;
const header_info_t HEADER_INFO_MIRROR_RECORD_FULL = 0xD;
const header_info_t HEADER_INFO_MIRROR_RECORD_HEAVY = 0xC;
const header_info_t HEADER_INFO_MIRROR_REPLACED = 0xB;

const MirrorId_t MIRROR_CONTROLLER = 1;
const MirrorId_t MIRROR_RECIRCULATE = 2;

// to disable subsampling, just pretend that everything is unknown and not inserted
# 68 "test/liraflow/headers.p4"
struct ip_pair {
    bit<32> src;
    bit<32> dst;
}

// padding for recirculated packets
// pktgen produces 6 bytes too many, we need to do the same to recirculation so we can process both
header pktgen_pad_h {
    bit<48> pad;
}

// common header for mirroring and control packets (as lookahead)
header internal_header_h {
    header_type_t type;
    header_info_t info;
}

header mirror_metadata_h {
    header_type_t type;
    header_info_t info;
    bit<7> pad1;
    PortId_t ingress_port;
    bit<7> pad2;
    PortId_t egress_port;
    bit<6> pad3;
    MirrorId_t mirror_session;
    bit<48> ingress_mac_tstamp;
    bit<48> ingress_global_tstamp;
    bit<32> estimate;
    bit<32> carry_min;
    bit<2> pad4;
    bit<30> flow_hash;
}

// packets from control plane need to specify partial checksum of payload (i.e., IPFIX template) so we can update
header control_h {
    header_type_t type;
    header_info_t info;
    bit<4> template_index;
    bit<3> pad;
    PortId_t egress_port;
    bit<16> payload_checksum;
}

header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> ether_type;
}

header eth_pad_h {
    bit<32> pad;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ipv4_options_h {
    varbit<320> options;
}

header ipv6_h {
    bit<4> version;
    bit<8> tclass;
    bit<20> flow;
    bit<16> len;
    bit<8> nexthdr;
    bit<8> ttl;
    bit<128> src_addr;
    bit<128> dst_addr;
}

header ipv6_opt_hdr_h {
    bit<8> nexthdr;
    bit<8> opt_len;
    bit<48> payload;
}

header ipv6_opt_payload_h {
    varbit<320> payload; // currently max. supported length: 6 + 5 * 8 octets
}



// common for tcp/udp so we do not need to use control flow
header ports_h {
    bit<16> sport;
    bit<16> dport;
}

header udp_h {
    bit<16> len;
    bit<16> checksum;
}

header tcp_h {
    bit<32> seq;
    bit<32> ack;
    bit<4> offset;
    bit<12> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urg;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header ipfix_header_h {
    bit<16> version;
    bit<16> len;
    bit<32> tstamp;
    bit<32> seq;
    bit<32> obs_domain;
}

// additional header for template body
header ipfix_template_h {
    bit<16> set_id;
    bit<16> len;
    bit<16> template_id;
    bit<16> num_fields;
}

// header and payload of record packet (should match run_pd_rpc.py)
header ipfix_record_h {
    bit<16> template_id;
    bit<16> len;
    bit<32> packetDeltaCount; // 2
    bit<32> flowStartSeconds; // 150
    bit<16> ingressInterface; // 10
    bit<16> egressInterface; // 14
    //bit<8>   ipVersion;                // 60
    bit<8> protocolIdentifier; // 4
    bit<16> tcpControlBits; // 6
    bit<32> octetDeltaCount; // 1
    bit<16> sourceTransportPort; // 7
    bit<16> destinationTransportPort; // 11
}

header ipfix_v4_data_h {
    bit<32> sourceIPv4Address; // 8
    bit<32> destinationIPv4Address; // 12
}

header ipfix_v6_data_h {
    bit<128> sourceIPv6Address; // 27
    bit<128> destinationIPv6Address; // 28
}
# 9 "test/liraflow/forensics.p4" 2

# 1 "test/liraflow/ingress.p4" 1
// vim: ts=4:sw=4:et:syntax=c

const int IPV4_HOST_SIZE = 8192;
const int IPV6_HOST_SIZE = 8192;
const int IPV4_LPM_SIZE = 4096;
const int IPV6_LPM_SIZE = 4096;
const int MIRROR_SIZE = 512;
const int IPFIX_ROUTE_SIZE = 16;
const int IPFIX_FILTER_SIZE = 128;

const bit<3> DEPARSER_MIRROR = 0x3;

struct ingress_headers_t {
    control_h ctrl;
    mirror_metadata_h mirror;
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv4_options_h ipv4_options;
    ipv6_h ipv6;
    ipv6_opt_hdr_h ipv6_opt_1_hdr; ipv6_opt_payload_h ipv6_opt_1_payload;
    ipv6_opt_hdr_h ipv6_opt_2_hdr; ipv6_opt_payload_h ipv6_opt_2_payload;
    ports_h ports;
    tcp_h tcp;
    udp_h udp;
    icmp_h icmp;
}

struct ingress_meta_t {
    header_type_t mirror_header_type;
    header_info_t mirror_header_info;
    PortId_t ingress_port;
    PortId_t egress_port;
    MirrorId_t mirror_session;
    bit<48> ingress_mac_tstamp;
    bit<48> ingress_global_tstamp;
    bit<30> flow_hash;
    bit<1> template_ok;
    bit<6> flow_match;
    bit<32> estimate;
    bit<32> carry_min;
    bit<32> random_large;
    bit<12> random_small;
    bit<32> ipv6_src_low;
    bit<32> ipv6_dst_low;
    bit<32> ipv6_hash;
}

parser IngressParser( packet_in pkt,
                     out ingress_headers_t hdr,
                     out ingress_meta_t meta,
                     out ingress_intrinsic_metadata_t ig_intr_md)
{
    internal_header_h internal;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        meta.estimate = 0;
        meta.carry_min = 0;
        transition select(ig_intr_md.ingress_port[6:0]) {
            PKTGEN_INDEX: parse_pktgen;
            default : parse_ethernet;
        }
    }

    state parse_pktgen {
        // either a control packet or a recirculated mirror packet
        pkt.advance(48);
        internal = pkt.lookahead<internal_header_h>();

        transition select(internal.type, internal.info) {
            (HEADER_TYPE_CONTROL, _): parse_control;
            (HEADER_TYPE_MIRROR , _): parse_mirror;
            default : reject;
        }
    }

    state parse_control {
        pkt.extract(hdr.ctrl);
        transition accept;
    }

    state parse_mirror {
        pkt.extract(hdr.mirror);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID : parse_vlan_tag;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_CONTROL: parse_control;
            default : accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        pkt.extract(hdr.ipv4_options, (bit<32>)(hdr.ipv4.ihl - 4w5) << 5);
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            (0, IPPROTO_TCP ): parse_tcp;
            (0, IPPROTO_UDP ): parse_udp;
            (0, IPPROTO_ICMP): parse_icmp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            0: parse_ipv6_opt_1;
            60: parse_ipv6_opt_1;
            43: parse_ipv6_opt_1;
            44: parse_ipv6_opt_1;
            51: parse_ipv6_opt_1;
            50: parse_ipv6_opt_1;
            60: parse_ipv6_opt_1;
            135: parse_ipv6_opt_1;
            139: parse_ipv6_opt_1;
            140: parse_ipv6_opt_1;
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            IPPROTO_ICMP6: parse_icmp;
            default : accept;
        }
    }

    state parse_ipv6_opt_1 {
        pkt.extract(hdr.ipv6_opt_1_hdr);
        pkt.extract(hdr.ipv6_opt_1_payload, (bit<32>)hdr.ipv6_opt_1_hdr.opt_len[1:0] << 6);
        transition select(hdr.ipv6_opt_1_hdr.nexthdr) {
/*

            0: parse_ipv6_opt_2;
            60: parse_ipv6_opt_2;
            43: parse_ipv6_opt_2;
            44: parse_ipv6_opt_2;
            51: parse_ipv6_opt_2;
            50: parse_ipv6_opt_2;
            60: parse_ipv6_opt_2;
            135: parse_ipv6_opt_2;
            139: parse_ipv6_opt_2;
            140: parse_ipv6_opt_2;
            IPPROTO_TCP  : parse_tcp;
            IPPROTO_UDP  : parse_udp;
            IPPROTO_ICMP6: parse_icmp;
            default      : accept;
        }
    }

    state parse_ipv6_opt_2 {
        pkt.extract(hdr.ipv6_opt_2_hdr);
        pkt.extract(hdr.ipv6_opt_2_payload, (bit<32>)hdr.ipv6_opt_2_hdr.opt_len[1:0] << 6);
        transition select(hdr.ipv6_opt_2_hdr.nexthdr) {
*/
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            IPPROTO_ICMP6: parse_icmp;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.ports);
        pkt.extract(hdr.tcp);
        hdr.icmp.type = 0;
        hdr.icmp.code = 0;
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.ports);
        pkt.extract(hdr.udp);
        hdr.icmp.type = 0;
        hdr.icmp.code = 0;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
}

control Ingress(inout ingress_headers_t hdr,
                inout ingress_meta_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        meta.egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
        meta.egress_port = 0;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = { send; drop; @defaultonly NoAction; }
        const default_action = NoAction();
        size = IPV4_HOST_SIZE;
    }

    table ipv6_host {
        key = { hdr.ipv6.dst_addr : exact; }
        actions = { send; drop; @defaultonly NoAction; }
        const default_action = NoAction();
        size = IPV6_HOST_SIZE;
    }

    table ipv4_lpm {
        key = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }
        const default_action = send(64);
        size = IPV4_LPM_SIZE;
    }

    table ipv6_lpm {
        key = { hdr.ipv6.dst_addr : lpm; }
        actions = { send; drop; }
        const default_action = send(64);
        size = IPV6_LPM_SIZE;
    }

    // simply send the packet to the collector port
    table ipfix_route {
        key = { }
        actions = { send; @defaultonly NoAction; }
        default_action = NoAction;
        size = IPFIX_ROUTE_SIZE;
    }

    // decide whether to consider the packet; include match on other fields if necessary
    table ipfix_filter {
        key = { ig_intr_md.ingress_port: exact; }
        actions = { NoAction; }
        default_action = NoAction();
        size = IPFIX_FILTER_SIZE;
    }

    // activate specified mirror session defined in run_pd_rpc.py
    action mirror(MirrorId_t mirror_session, header_info_t info) {
        ig_dprsr_md.mirror_type = DEPARSER_MIRROR;
        meta.mirror_header_type = HEADER_TYPE_MIRROR;
        meta.mirror_header_info = info;
        meta.ingress_port = ig_intr_md.ingress_port;
        meta.mirror_session = mirror_session;
        meta.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp;
        meta.ingress_global_tstamp = ig_prsr_md.global_tstamp;
    }

    // subsampling _and_ probabilistic recirculation
    table ipfix_mirror {
        key = {
            meta.estimate : ternary;
            meta.carry_min : ternary;
            meta.random_large : ternary;
            meta.random_small : range;
        }
        actions = { mirror; }
        const default_action = mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_FULL);
        size = MIRROR_SIZE;
        const entries = {
# 1 "test/liraflow/mirror_entries.p4" 1
// match on (32:estimate, 32:carry_min, 32:random_large, 12:random_small)
// estimate, carry_min each consist of (30:count, 2:stage)

// if entry not found, mirror always - but recirculate only according to precision
(32w0 &&& 32w0, 32w0x00000004 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w4095): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000008 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w2048): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000000C &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w1365): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000010 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w1024): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000014 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w819): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000018 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w682): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000001C &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w585): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000020 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000024 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000028 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000002C &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000030 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000034 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000038 &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000003C &&& 32w0xFFFFFFFC, 32w0 &&& 32w0x00000000, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000040 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000048 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000050 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000058 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000060 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000068 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000070 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000078 &&& 32w0xFFFFFFF8, 32w0 &&& 32w0x00000001, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000080 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000090 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000A0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000B0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000C0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000D0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000E0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000000F0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0x00000003, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000100 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000120 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000140 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000160 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000180 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000001A0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000001C0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000001E0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0x00000007, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000200 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000240 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000280 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000002C0 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000300 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000340 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000380 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000003C0 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0x0000000F, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000400 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000480 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000500 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000580 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000600 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000680 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000700 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000780 &&& 32w0xFFFFFF80, 32w0 &&& 32w0x0000001F, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00000800 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000900 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000A00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000B00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000C00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000D00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000E00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00000F00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0x0000003F, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00001000 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001200 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001400 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001600 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001800 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001A00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001C00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00001E00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0x0000007F, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00002000 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00002400 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00002800 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00002C00 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00003000 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00003400 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00003800 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00003C00 &&& 32w0xFFFFFC00, 32w0 &&& 32w0x000000FF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00004000 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00004800 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00005000 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00005800 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00006000 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00006800 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00007000 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00007800 &&& 32w0xFFFFF800, 32w0 &&& 32w0x000001FF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00008000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00009000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000A000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000B000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000C000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000D000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000E000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0000F000 &&& 32w0xFFFFF000, 32w0 &&& 32w0x000003FF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00010000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00012000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00014000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00016000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00018000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0001A000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0001C000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0001E000 &&& 32w0xFFFFE000, 32w0 &&& 32w0x000007FF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00020000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00024000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00028000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0002C000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00030000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00034000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00038000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0003C000 &&& 32w0xFFFFC000, 32w0 &&& 32w0x00000FFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00040000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00048000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00050000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00058000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00060000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00068000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00070000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00078000 &&& 32w0xFFFF8000, 32w0 &&& 32w0x00001FFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00080000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00090000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000A0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000B0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000C0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000D0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000E0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x000F0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0x00003FFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00100000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00120000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00140000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00160000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00180000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x001A0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x001C0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x001E0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0x00007FFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00200000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00240000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00280000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x002C0000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00300000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00340000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00380000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x003C0000 &&& 32w0xFFFC0000, 32w0 &&& 32w0x0000FFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00400000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00480000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00500000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00580000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00600000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00680000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00700000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00780000 &&& 32w0xFFF80000, 32w0 &&& 32w0x0001FFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x00800000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00900000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00A00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00B00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00C00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00D00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00E00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x00F00000 &&& 32w0xFFF00000, 32w0 &&& 32w0x0003FFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x01000000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01200000 &&& 32w0xFFE00000, 32w0 &&& 32w0X0007FFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01400000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01600000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01800000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01A00000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01C00000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x01E00000 &&& 32w0xFFE00000, 32w0 &&& 32w0x0007FFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x02000000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x02400000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x02800000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x02C00000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x03000000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x03400000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x03800000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x03C00000 &&& 32w0xFFC00000, 32w0 &&& 32w0x000FFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x04000000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x04800000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x05000000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x05800000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x06000000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x06800000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x07000000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x07800000 &&& 32w0xFF800000, 32w0 &&& 32w0x001FFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x08000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x09000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0A000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0B000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0C000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0D000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0E000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x0F000000 &&& 32w0xFF000000, 32w0 &&& 32w0x003FFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x10000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x12000000 &&& 32w0xFE000000, 32w0 &&& 32w0X007FFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x14000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x16000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x18000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x1A000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x1C000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x1E000000 &&& 32w0xFE000000, 32w0 &&& 32w0x007FFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x20000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x24000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x28000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x2C000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x30000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x34000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x38000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x3C000000 &&& 32w0xFC000000, 32w0 &&& 32w0x00FFFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x40000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x48000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x50000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x58000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x60000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x68000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x70000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x78000000 &&& 32w0xF8000000, 32w0 &&& 32w0x01FFFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

(32w0 &&& 32w0, 32w0x80000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w512): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0x90000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w455): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xA0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w409): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xB0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w372): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xC0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w341): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xD0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w315): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xE0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w292): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);
(32w0 &&& 32w0, 32w0xF0000000 &&& 32w0xF0000000, 32w0 &&& 32w0x03FFFFFF, 12w0..12w273): mirror(MIRROR_RECIRCULATE, HEADER_INFO_MIRROR_REPLACED);

// if entry found, reduce heavy hitter mirroring probability to 256 packets => E[mirrored] = 256 + 256 * ln(Flow / 256)
(32w0x00000000 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w4095): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00000080 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000090 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000A0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000B0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000C0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000D0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000E0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000000F0 &&& 32w0xFFFFFFF0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000000, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00000100 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000120 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000140 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000160 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000180 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000001A0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000001C0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000001E0 &&& 32w0xFFFFFFE0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000001, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00000200 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000240 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000280 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000002C0 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000300 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000340 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000380 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000003C0 &&& 32w0xFFFFFFC0, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000003, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00000400 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000480 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000500 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000580 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000600 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000680 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000700 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000780 &&& 32w0xFFFFFF80, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000007, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00000800 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000900 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000A00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000B00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000C00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000D00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000E00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00000F00 &&& 32w0xFFFFFF00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000000F, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00001000 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001200 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001400 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001600 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001800 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001A00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001C00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00001E00 &&& 32w0xFFFFFE00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000001F, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00002000 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00002400 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00002800 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00002C00 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00003000 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00003400 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00003800 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00003C00 &&& 32w0xFFFFFC00, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000003F, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00004000 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00004800 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00005000 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00005800 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00006000 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00006800 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00007000 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00007800 &&& 32w0xFFFFF800, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000007F, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00008000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00009000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000A000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000B000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000C000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000D000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000E000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0000F000 &&& 32w0xFFFFF000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000000FF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00010000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00012000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00014000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00016000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00018000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0001A000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0001C000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0001E000 &&& 32w0xFFFFE000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000001FF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00020000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00024000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00028000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0002C000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00030000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00034000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00038000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0003C000 &&& 32w0xFFFFC000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000003FF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00040000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00048000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00050000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00058000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00060000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00068000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00070000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00078000 &&& 32w0xFFFF8000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000007FF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00080000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00090000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000A0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000B0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000C0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000D0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000E0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x000F0000 &&& 32w0xFFFF0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00000FFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00100000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00120000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00140000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00160000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00180000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x001A0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x001C0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x001E0000 &&& 32w0xFFFE0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00001FFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00200000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00240000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00280000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x002C0000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00300000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00340000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00380000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x003C0000 &&& 32w0xFFFC0000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00003FFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00400000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00480000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00500000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00580000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00600000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00680000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00700000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00780000 &&& 32w0xFFF80000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00007FFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x00800000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00900000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00A00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00B00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00C00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00D00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00E00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x00F00000 &&& 32w0xFFF00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0000FFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x01000000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01200000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01400000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01600000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01800000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01A00000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01C00000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x01E00000 &&& 32w0xFFE00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0001FFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x02000000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x02400000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x02800000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x02C00000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x03000000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x03400000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x03800000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x03C00000 &&& 32w0xFFC00000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0003FFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x04000000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x04800000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x05000000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x05800000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x06000000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x06800000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x07000000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x07800000 &&& 32w0xFF800000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x0007FFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x08000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x09000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0A000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0B000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0C000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0D000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0E000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x0F000000 &&& 32w0xFF000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x000FFFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x10000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x12000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x14000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x16000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x18000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x1A000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x1C000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x1E000000 &&& 32w0xFE000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x001FFFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x20000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x24000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x28000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x2C000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x30000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x34000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x38000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x3C000000 &&& 32w0xFC000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x003FFFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x40000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x48000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x50000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x58000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x60000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x68000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x70000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x78000000 &&& 32w0xF8000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x007FFFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

(32w0x80000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w3640): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0x90000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w3276): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xA0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2978): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xB0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2730): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xC0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2520): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xD0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2340): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xE0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2184): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
(32w0xF0000000 &&& 32w0xF0000000, 32w0 &&& 32w0xFFFFFFFF, 32w0 &&& 32w0x00FFFFFF, 12w0..12w2048): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);

// if entry found and not mirrored before, drop (subsampling)
(32w0x00000000 &&& 32w0x00000000, 32w0 &&& 32w0xFFFFFFFF, _, _): mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_DROP);
# 282 "test/liraflow/ingress.p4" 2
        }
    }

    Register<bit<32>, bit<15>>(1 << 15, 0) precision_reg_1_ports;RegisterAction<bit<32>, bit<15>, bit<1>>(precision_reg_1_ports) precision_cmp_1_ports = { void apply(inout bit<32> register, out bit<1> result) { result = (bit<1>)(register == hdr.ports.sport ++ hdr.ports.dport); }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_1_ports) precision_upd_1_ports = { void apply(inout bit<32> register) { register = hdr.ports.sport ++ hdr.ports.dport; }};Register<bit<16>, bit<15>>(1 << 15, 0) precision_reg_1_icmp;RegisterAction<bit<16>, bit<15>, bit<1>>(precision_reg_1_icmp) precision_cmp_1_icmp = { void apply(inout bit<16> register, out bit<1> result) { result = (bit<1>)(register == hdr.icmp.type ++ hdr.icmp.code); }};RegisterAction<bit<16>, bit<15>, void>(precision_reg_1_icmp) precision_upd_1_icmp = { void apply(inout bit<16> register) { register = hdr.icmp.type ++ hdr.icmp.code; }};Register<ip_pair, bit<15>>(1 << 15, ({0, 0})) precision_reg_1_ipv4;RegisterAction<ip_pair, bit<15>, bit<1>>(precision_reg_1_ipv4) precision_cmp_1_ipv4 = { void apply(inout ip_pair register, out bit<1> result) { result = (bit<1>)(register == ({hdr.ipv4.src_addr, hdr.ipv4.dst_addr})); }};RegisterAction<ip_pair, bit<15>, void>(precision_reg_1_ipv4) precision_upd_1_ipv4 = { void apply(inout ip_pair register) { register = ({hdr.ipv4.src_addr, hdr.ipv4.dst_addr}); }};Register<ip_pair, bit<15>>(1 << 15, ({0, 0})) precision_reg_1_ipv6;RegisterAction<ip_pair, bit<15>, bit<1>>(precision_reg_1_ipv6) precision_cmp_1_ipv6 = { void apply(inout ip_pair register, out bit<1> result) { result = (bit<1>)(register == ({meta.ipv6_src_low, meta.ipv6_dst_low})); }};RegisterAction<ip_pair, bit<15>, void>(precision_reg_1_ipv6) precision_upd_1_ipv6 = { void apply(inout ip_pair register) { register = ({meta.ipv6_src_low, meta.ipv6_dst_low}); }};Register<bit<32>, bit<15>>(1 << 15, 0) precision_reg_1_ipv6_hash;RegisterAction<bit<32>, bit<15>, bit<1>>(precision_reg_1_ipv6_hash) precision_cmp_1_ipv6_hash = { void apply(inout bit<32> register, out bit<1> result) { result = (bit<1>)(register == meta.ipv6_hash); }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_1_ipv6_hash) precision_upd_1_ipv6_hash = { void apply(inout bit<32> register) { register = meta.ipv6_hash; }};Register<bit<32>, bit<15>>(1 << 15, 1) precision_reg_1_count;RegisterAction<bit<32>, bit<15>, bit<32>>(precision_reg_1_count) precision_est_1_inc = { void apply(inout bit<32> register, out bit<32> result) { register = register + 4; result = register; }};RegisterAction<bit<32>, bit<15>, bit<32>>(precision_reg_1_count) precision_est_1_carry = { void apply(inout bit<32> register, out bit<32> result) { result = register + 4; }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_1_count) precision_est_1_write = { void apply(inout bit<32> register) { register = hdr.mirror.carry_min; }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_1_count) precision_est_1_reset = { void apply(inout bit<32> register) { register = 1; }};
    Register<bit<32>, bit<15>>(1 << 15, 0) precision_reg_2_ports;RegisterAction<bit<32>, bit<15>, bit<1>>(precision_reg_2_ports) precision_cmp_2_ports = { void apply(inout bit<32> register, out bit<1> result) { result = (bit<1>)(register == hdr.ports.sport ++ hdr.ports.dport); }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_2_ports) precision_upd_2_ports = { void apply(inout bit<32> register) { register = hdr.ports.sport ++ hdr.ports.dport; }};Register<bit<16>, bit<15>>(1 << 15, 0) precision_reg_2_icmp;RegisterAction<bit<16>, bit<15>, bit<1>>(precision_reg_2_icmp) precision_cmp_2_icmp = { void apply(inout bit<16> register, out bit<1> result) { result = (bit<1>)(register == hdr.icmp.type ++ hdr.icmp.code); }};RegisterAction<bit<16>, bit<15>, void>(precision_reg_2_icmp) precision_upd_2_icmp = { void apply(inout bit<16> register) { register = hdr.icmp.type ++ hdr.icmp.code; }};Register<ip_pair, bit<15>>(1 << 15, ({0, 0})) precision_reg_2_ipv4;RegisterAction<ip_pair, bit<15>, bit<1>>(precision_reg_2_ipv4) precision_cmp_2_ipv4 = { void apply(inout ip_pair register, out bit<1> result) { result = (bit<1>)(register == ({hdr.ipv4.src_addr, hdr.ipv4.dst_addr})); }};RegisterAction<ip_pair, bit<15>, void>(precision_reg_2_ipv4) precision_upd_2_ipv4 = { void apply(inout ip_pair register) { register = ({hdr.ipv4.src_addr, hdr.ipv4.dst_addr}); }};Register<ip_pair, bit<15>>(1 << 15, ({0, 0})) precision_reg_2_ipv6;RegisterAction<ip_pair, bit<15>, bit<1>>(precision_reg_2_ipv6) precision_cmp_2_ipv6 = { void apply(inout ip_pair register, out bit<1> result) { result = (bit<1>)(register == ({meta.ipv6_src_low, meta.ipv6_dst_low})); }};RegisterAction<ip_pair, bit<15>, void>(precision_reg_2_ipv6) precision_upd_2_ipv6 = { void apply(inout ip_pair register) { register = ({meta.ipv6_src_low, meta.ipv6_dst_low}); }};Register<bit<32>, bit<15>>(1 << 15, 0) precision_reg_2_ipv6_hash;RegisterAction<bit<32>, bit<15>, bit<1>>(precision_reg_2_ipv6_hash) precision_cmp_2_ipv6_hash = { void apply(inout bit<32> register, out bit<1> result) { result = (bit<1>)(register == meta.ipv6_hash); }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_2_ipv6_hash) precision_upd_2_ipv6_hash = { void apply(inout bit<32> register) { register = meta.ipv6_hash; }};Register<bit<32>, bit<15>>(1 << 15, 2) precision_reg_2_count;RegisterAction<bit<32>, bit<15>, bit<32>>(precision_reg_2_count) precision_est_2_inc = { void apply(inout bit<32> register, out bit<32> result) { register = register + 4; result = register; }};RegisterAction<bit<32>, bit<15>, bit<32>>(precision_reg_2_count) precision_est_2_carry = { void apply(inout bit<32> register, out bit<32> result) { result = register + 4; }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_2_count) precision_est_2_write = { void apply(inout bit<32> register) { register = hdr.mirror.carry_min; }};RegisterAction<bit<32>, bit<15>, void>(precision_reg_2_count) precision_est_2_reset = { void apply(inout bit<32> register) { register = 2; }};

    Register<bit<1>, bit<1>>(2) templates_seen;
    RegisterAction<bit<1>, bit<1>, bit<1>>(templates_seen) register_template = {
        void apply(inout bit<1> register, out bit<1> result) {
            register = 1;
        }
    };
    RegisterAction<bit<1>, bit<1>, bit<1>>(templates_seen) has_template = {
        void apply(inout bit<1> register, out bit<1> result) {
            result = register;
        }
    };

    Hash<bit<32>>(HashAlgorithm_t.CRC32) crc32;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
    Random<bit<32>>() random_large;
    Random<bit<12>>() random_small;

    apply {
        meta.ipv6_src_low = hdr.ipv6.src_addr[31:0];
        meta.ipv6_dst_low = hdr.ipv6.dst_addr[31:0];

        // indexes into hashmap
        meta.flow_hash = crc32.get({
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr,
            hdr.ipv6.src_addr,
            hdr.ipv6.dst_addr,
            hdr.ports.sport,
            hdr.ports.dport,
            hdr.icmp.type,
            hdr.icmp.code
        })[2*15 -1:0];

        bit<15> ix1 = meta.flow_hash[15 -1:0];
        bit<15> ix2 = meta.flow_hash[2*15 -1:15];

        if (hdr.ctrl.isValid()) {
            if (hdr.ctrl.info == HEADER_INFO_TEMPLATE) {
                if (hdr.ctrl.template_index == TEMPLATE_INDEX_IPV4) {
                    register_template.execute(0);
                } else {
                    register_template.execute(1);
                }
            }

            send(hdr.ctrl.egress_port);
        } else if (hdr.mirror.isValid()) {
            // mirror packet returned from egress; we should update the table entry
            // only lower 32 bit of IPv6 are compared; others are hashed
            meta.ipv6_hash = ipv6_hash.get({
                3w5,
                hdr.ipv6.dst_addr[127:32],
                4w11,
                hdr.ipv6.src_addr[127:32],
                1w1
            });

            // overwrite table
            if (hdr.mirror.carry_min[1:0] == 1) {
                precision_upd_1_ports.execute(ix1);
                precision_upd_1_icmp.execute(ix1);
                precision_upd_1_ipv4.execute(ix1);
                precision_upd_1_ipv6.execute(ix1);
                precision_upd_1_ipv6_hash.execute(ix1);
                // precision_est_1_write.execute(ix1);
            } else if (hdr.mirror.carry_min[1:0] == 2) {
                precision_upd_2_ports.execute(ix2);
                precision_upd_2_icmp.execute(ix2);
                precision_upd_2_ipv4.execute(ix2);
                precision_upd_2_ipv6.execute(ix2);
                precision_upd_2_ipv6_hash.execute(ix2);
                // precision_est_2_write.execute(ix2);
            }

            hdr.mirror.estimate = hdr.mirror.carry_min - 4;

            ipfix_route.apply();
        } else {
            // fresh packet from ethernet

            // original packet not processed further
            ig_tm_md.bypass_egress = 1;

            // only lower 32 bit of IPv6 are compared; others are hashed
            meta.ipv6_hash = ipv6_hash.get({
                3w5,
                hdr.ipv6.dst_addr[127:32],
                4w11,
                hdr.ipv6.src_addr[127:32],
                1w1
            });

            if (hdr.ipv4.isValid()) {
                // compare IPv4 address information with each stage
                if (!ipv4_host.apply().hit) {
                    ipv4_lpm.apply();
                }
                meta.template_ok = has_template.execute(0);
                meta.flow_match[1:1] = precision_cmp_1_ipv4.execute(ix1);
                meta.flow_match[2:2] = 1;
                meta.flow_match[4:4] = precision_cmp_2_ipv4.execute(ix2);
                meta.flow_match[5:5] = 1;
            } else if (hdr.ipv6.isValid()) {
                // compare IPv6 address information with each stage
                if (!ipv6_host.apply().hit) {
                    ipv6_lpm.apply();
                }
                meta.template_ok = has_template.execute(1);
                meta.flow_match[1:1] = precision_cmp_1_ipv6.execute(ix1);
                meta.flow_match[2:2] = precision_cmp_1_ipv6_hash.execute(ix1);
                meta.flow_match[4:4] = precision_cmp_2_ipv6.execute(ix2);
                meta.flow_match[5:5] = precision_cmp_2_ipv6_hash.execute(ix2);
            } else {
                meta.template_ok = has_template.execute(0);
            }

            if (ipfix_filter.apply().hit) {
                if (meta.template_ok == 1 && (hdr.ports.isValid() || hdr.icmp.isValid())) {
                    // compare ports, ICMP with each stage
                    if (hdr.ports.isValid()) {
                        meta.flow_match[0:0] = precision_cmp_1_ports.execute(ix1);
                        meta.flow_match[3:3] = precision_cmp_2_ports.execute(ix2);
                    } else {
                        meta.flow_match[0:0] = precision_cmp_1_icmp.execute(ix1);
                        meta.flow_match[3:3] = precision_cmp_2_icmp.execute(ix2);
                    }

                    if (hdr.tcp.isValid() && hdr.tcp.flags & (TCPFLAG_RST | TCPFLAG_FIN) != 0) {
                        // always generate record for TCP end-of-flow

                        if (meta.flow_match[2:0] == 3w7) {
                            meta.estimate = 1;
                            precision_est_1_reset.execute(ix1);
                            mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
                        } else if (meta.flow_match[5:3] == 3w7) {
                            meta.estimate = 2;
                            precision_est_2_reset.execute(ix2);
                            mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_HEAVY);
                        } else {
                            mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_FULL);
                        }
                    } else {
                        // find first matching stage and retrieve estimate
                        if (meta.flow_match[2:0] == 3w7) {
                            meta.estimate = precision_est_1_inc.execute(ix1);
                        } else if (meta.flow_match[5:3] == 3w7) {
                            meta.estimate = precision_est_2_inc.execute(ix2);
                        } else {
                            // no match, could replace entry with lower carry
                            bit<32> carry1 = precision_est_1_carry.execute(ix1);
                            bit<32> carry2 = precision_est_2_carry.execute(ix2);
                            // 32:carry_min = (30:flowsize, 2:stage) => min automatically chooses (and remembers) stage
                            meta.carry_min = min(carry1, carry2);
                        }

                        meta.random_large = random_large.get();
                        meta.random_small = random_small.get();

                        // recirculation, subsampling
                        ipfix_mirror.apply();
                    }
                } else if (meta.template_ok == 1) {

                    if (!hdr.ipv4.isValid() || hdr.ipv4.frag_offset == 0) {

                        // no TCP/UDP/ICMP info, always report
                        mirror(MIRROR_CONTROLLER, HEADER_INFO_MIRROR_RECORD_FULL);

                    }

                }
            }
        }
    }
}

control IngressDeparser( packet_out pkt,
                        inout ingress_headers_t hdr,
                        in ingress_meta_t meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    Mirror() mirror;

    apply {
        if (ig_dprsr_md.mirror_type == DEPARSER_MIRROR) {
            // if mirror has been set, call it here
            mirror.emit<mirror_metadata_h>(meta.mirror_session, {
                meta.mirror_header_type,
                meta.mirror_header_info,
                0,
                meta.ingress_port,
                0,
                meta.egress_port,
                0,
                meta.mirror_session,
                meta.ingress_mac_tstamp,
                meta.ingress_global_tstamp,
                meta.estimate,
                meta.carry_min,
                0,
                meta.flow_hash
            });
        }

        pkt.emit(hdr);
    }
}
# 11 "test/liraflow/forensics.p4" 2

# 1 "test/liraflow/egress.p4" 1
// vim: ts=4:sw=4:et:syntax=c

const int COLL_ADDR_SIZE = 512;



struct egress_headers_t {
    // headers of incoming packet
    pktgen_pad_h ctrl_pad;
    mirror_metadata_h mirror;
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    ports_h ports;
    tcp_h tcp;
    udp_h udp;
    icmp_h icmp;

    // new headers for path to collector
    ipv4_h r_ipv4;
    ipv6_h r_ipv6;
    ports_h r_ports;
    udp_h r_udp;
    ipfix_header_h ipfix;
    ipfix_template_h template;
    ipfix_record_h record;
    ipfix_v4_data_h datav4;
    ipfix_v6_data_h datav6;
    eth_pad_h pad; // network card sometimes drops last 6 bytes (esp. on VM); padding protects actual packet
}

struct egress_meta_t {
    control_h ctrl;
    bit<16> total_len;
    bit<16> csum_len;
    bit<32> tstamp_inc;
}

@pa_mutually_exclusive("egress", "meta.ctrl", "hdr.ethernet")
@pa_mutually_exclusive("egress", "hdr.template", "hdr.ethernet")
@pa_mutually_exclusive("egress", "hdr.prsr_pad_0[0]", "hdr.ethernet")
@pa_mutually_exclusive("egress", "hdr.prsr_pad_0[1]", "hdr.ethernet")
@pa_mutually_exclusive("egress", "hdr.prsr_pad_0[2]", "hdr.ethernet")
@pa_mutually_exclusive("egress", "hdr.prsr_pad_0[3]", "hdr.ethernet")

parser EgressParser( packet_in pkt,
                    out egress_headers_t hdr,
                    out egress_meta_t meta,
                    out egress_intrinsic_metadata_t eg_intr_md)
{
    internal_header_h internal;
    ipv6_opt_hdr_h ipv6_opt_hdr;

    state start {
        pkt.extract(eg_intr_md);
        // all packets have an internal_header; either mirror metadata or control packet
        internal = pkt.lookahead<internal_header_h>();

        transition select(internal.type, internal.info) {
            (HEADER_TYPE_CONTROL, _): parse_control;
            (HEADER_TYPE_MIRROR , _): parse_mirror;
            default : reject;
        }
    }

    state parse_control {
        pkt.extract(meta.ctrl);
        transition select(meta.ctrl.info) {
            HEADER_INFO_TEMPLATE: parse_template;
            default : reject;
        }
    }

    state parse_template {
        pkt.extract(hdr.ipfix);
        pkt.extract(hdr.template);
        transition accept;
    }

    state parse_mirror {
        pkt.extract(hdr.mirror);
        transition select(eg_intr_md.egress_port[6:0]) {
            PKTGEN_INDEX: accept;
            default : parse_ethernet;
        }
    }

    state parse_ethernet {
        // prepare IPFIX header information here
        hdr.ipfix.setValid();
        hdr.ipfix.version = 0x000A;
        hdr.ipfix.tstamp = 0;
        hdr.ipfix.obs_domain = 0;

        hdr.record.setValid();
        hdr.record.flowStartSeconds = 0;

        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID: parse_vlan_tag;
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default : consume_payload;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default : consume_payload;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5: parse_ipv4_opt_0;
            6: parse_ipv4_opt_1;
            7: parse_ipv4_opt_2;
            8: parse_ipv4_opt_3;
            9: parse_ipv4_opt_4;
            default: parse_ipv4_opt_more;
        }
    }

    state parse_ipv4_opt_more {
        pkt.advance(160);
        transition select(hdr.ipv4.ihl) {
            10: parse_ipv4_opt_0;
            11: parse_ipv4_opt_1;
            12: parse_ipv4_opt_2;
            13: parse_ipv4_opt_3;
            14: parse_ipv4_opt_4;
            15: parse_ipv4_opt_5;
            default: reject;
        }
    }

    state parse_ipv4_opt_5 {
        pkt.advance(160);
        transition parse_ipv4_opt_0;
    }

    state parse_ipv4_opt_4 {
        pkt.advance(128);
        transition parse_ipv4_opt_0;
    }

    state parse_ipv4_opt_3 {
        pkt.advance(96);
        transition parse_ipv4_opt_0;
    }

    state parse_ipv4_opt_2 {
        pkt.advance(64);
        transition parse_ipv4_opt_0;
    }

    state parse_ipv4_opt_1 {
        pkt.advance(32);
        transition parse_ipv4_opt_0;
    }

    state parse_ipv4_opt_0 {
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            (0, IPPROTO_ICMP) : parse_icmp;
            (0, IPPROTO_ICMP6): parse_icmp;
            (0, IPPROTO_TCP) : parse_tcp;
            (0, IPPROTO_UDP) : parse_udp;
            default : consume_payload;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            0: parse_ipv6_opt;
            60: parse_ipv6_opt;
            43: parse_ipv6_opt;
            44: parse_ipv6_opt;
            51: parse_ipv6_opt;
            50: parse_ipv6_opt;
            60: parse_ipv6_opt;
            135: parse_ipv6_opt;
            139: parse_ipv6_opt;
            140: parse_ipv6_opt;
            IPPROTO_ICMP : parse_icmp;
            IPPROTO_ICMP6: parse_icmp;
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            default : consume_payload;
        }
    }

    state parse_ipv6_opt {
        pkt.extract(ipv6_opt_hdr);
        hdr.ipv6.nexthdr = ipv6_opt_hdr.nexthdr;
        transition select(ipv6_opt_hdr.opt_len) {
            0: parse_ipv6_opt_end;
            1: parse_ipv6_opt_1;
            2: parse_ipv6_opt_2;
            3: parse_ipv6_opt_3;
            4: parse_ipv6_opt_4;
            5: parse_ipv6_opt_5;
            default: accept;
        }
    }

    state parse_ipv6_opt_1 {
        pkt.advance(64);
        transition parse_ipv6_opt_end;
    }

    state parse_ipv6_opt_2 {
        pkt.advance(128);
        transition parse_ipv6_opt_end;
    }

    state parse_ipv6_opt_3 {
        pkt.advance(192);
        transition parse_ipv6_opt_end;
    }

    state parse_ipv6_opt_4 {
        pkt.advance(256);
        transition parse_ipv6_opt_end;
    }

    state parse_ipv6_opt_5 {
        pkt.advance(320);
        transition parse_ipv6_opt_end;
    }

    state parse_ipv6_opt_end {
        transition select(ipv6_opt_hdr.nexthdr) {
/*
            0: parse_ipv6_opt;
            60: parse_ipv6_opt;
            43: parse_ipv6_opt;
            44: parse_ipv6_opt;
            51: parse_ipv6_opt;
            50: parse_ipv6_opt;
            60: parse_ipv6_opt;
            135: parse_ipv6_opt;
            139: parse_ipv6_opt;
            140: parse_ipv6_opt;
*/
            IPPROTO_ICMP : parse_icmp;
            IPPROTO_ICMP6: parse_icmp;
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            default : consume_payload;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition consume_payload;
    }

    state parse_tcp {
        pkt.extract(hdr.ports);
        pkt.extract(hdr.tcp);
        transition consume_payload;
    }

    state parse_udp {
        pkt.extract(hdr.ports);
        pkt.extract(hdr.udp);
        transition consume_payload;
    }

    state consume_payload {
        // drop rest of packet beyond parsed headers
        pkt.advance(32768); // 4 KB
        transition accept;
    }
}

control Egress(inout egress_headers_t hdr,
               inout egress_meta_t meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
    Register<bit<32>, bit<15>>(1 << 15, 0) aggregate_1_pkts;RegisterAction<bit<32>, bit<15>, bit<32> >(aggregate_1_pkts) report_1_pkts = { void apply(inout bit<32> register, out bit<32> result) { result = register + 1; register = 0; }};RegisterAction<bit<32>, bit<15>, void>(aggregate_1_pkts) drop_1_pkts = { void apply(inout bit<32> register) { register = register + 1; }};
    Register<bit<32>, bit<15>>(1 << 15, 0) aggregate_2_pkts;RegisterAction<bit<32>, bit<15>, bit<32> >(aggregate_2_pkts) report_2_pkts = { void apply(inout bit<32> register, out bit<32> result) { result = register + 1; register = 0; }};RegisterAction<bit<32>, bit<15>, void>(aggregate_2_pkts) drop_2_pkts = { void apply(inout bit<32> register) { register = register + 1; }};
    Register<bit<32>, bit<15>>(1 << 15, 0) aggregate_1_bytes;RegisterAction<bit<32>, bit<15>, bit<32> >(aggregate_1_bytes) report_1_bytes = { void apply(inout bit<32> register, out bit<32> result) { result = register + (bit<32>)meta.total_len; register = 0; }};RegisterAction<bit<32>, bit<15>, void>(aggregate_1_bytes) drop_1_bytes = { void apply(inout bit<32> register) { register = register + (bit<32>)meta.total_len; }};
    Register<bit<32>, bit<15>>(1 << 15, 0) aggregate_2_bytes;RegisterAction<bit<32>, bit<15>, bit<32> >(aggregate_2_bytes) report_2_bytes = { void apply(inout bit<32> register, out bit<32> result) { result = register + (bit<32>)meta.total_len; register = 0; }};RegisterAction<bit<32>, bit<15>, void>(aggregate_2_bytes) drop_2_bytes = { void apply(inout bit<32> register) { register = register + (bit<32>)meta.total_len; }};

    Register<bit<32>, bit<15>>(1 << 15, 0) saved_1_start;
    RegisterAction<bit<32>, bit<15>, bit<32>>(saved_1_start) report_1_start = {
        void apply(inout bit<32> register, out bit<32> result) {
            if (hdr.mirror.info == HEADER_INFO_MIRROR_REPLACED) {
                register = hdr.ipfix.tstamp;
            }
            result = register;
        }
    };
    Register<bit<32>, bit<15>>(1 << 15, 0) saved_2_start;
    RegisterAction<bit<32>, bit<15>, bit<32>>(saved_2_start) report_2_start = {
        void apply(inout bit<32> register, out bit<32> result) {
            if (hdr.mirror.info == HEADER_INFO_MIRROR_REPLACED) {
                register = hdr.ipfix.tstamp;
            }
            result = register;
        }
    };

    Register<bit<16>, bit<15>>(1 << 15, 0) saved_1_flags;
    RegisterAction<bit<16>, bit<15>, bit<16>>(saved_1_flags) report_1_flags = {
        void apply(inout bit<16> register, out bit<16> result) {
            if (hdr.mirror.info == HEADER_INFO_MIRROR_REPLACED) {
                register = 4w0 ++ hdr.tcp.flags;
            } else {
                register = register | (4w0 ++ hdr.tcp.flags);
            }
            result = register;
        }
    };
    Register<bit<16>, bit<15>>(1 << 15, 0) saved_2_flags;
    RegisterAction<bit<16>, bit<15>, bit<16>>(saved_2_flags) report_2_flags = {
        void apply(inout bit<16> register, out bit<16> result) {
            if (hdr.mirror.info == HEADER_INFO_MIRROR_REPLACED) {
                register = 4w0 ++ hdr.tcp.flags;
            } else {
                register = register | (4w0 ++ hdr.tcp.flags);
            }
            result = register;
        }
    };

    // header info retrieved from template packet and inserted into records
    Register<bit<16>, bit<1>>(1 << 1, 0) reg_template_id; RegisterAction<bit<16>, bit<1>, bit<16>>(reg_template_id) template_id = { void apply(inout bit<16> register, out bit<16> result) {
        if (hdr.template.template_id != 0) {
            register = hdr.template.template_id;
        }
        result = register;
    } };
    Register<bit<32>, _>(1, 0) reg_ipfix_seq; RegisterAction<bit<32>, _, bit<32>>(reg_ipfix_seq) ipfix_seq = { void apply(inout bit<32> register, out bit<32> result) {
        result = register;
        if (hdr.template.template_id == 0) {
            register = register + 1;
        }
    } };
    Register<bit<32>, _>(1, 0) reg_tstamp_base; RegisterAction<bit<32>, _, bit<32>>(reg_tstamp_base) tstamp_base = { void apply(inout bit<32> register, out bit<32> result) {
        if (hdr.ipfix.tstamp == 0) {
            result = (14w0 ++ eg_prsr_md.global_tstamp[47:30]) - register;
        } else {
            register = 14w0 ++ eg_prsr_md.global_tstamp[47:30];
            result = 32w0;
        }
    } };
    Register<bit<32>, _>(1, 0) reg_tstamp_offset; RegisterAction<bit<32>, _, bit<32>>(reg_tstamp_offset) tstamp_offset = { void apply(inout bit<32> register, out bit<32> result) {
        if (hdr.ipfix.tstamp != 0) {
            register = hdr.ipfix.tstamp;
        }
        result = register;
    } };

    // control plane determines addresses of collector (layers 2-4)
    action set_addresses_v4(bit<48> mac_saddr, bit<48> mac_daddr,
                            bit<32> ip_saddr, bit<32> ip_daddr,
                            bit<16> sport, bit<16> dport) {
        hdr.ethernet.setValid();
        hdr.ethernet.src_addr = mac_saddr;
        hdr.ethernet.dst_addr = mac_daddr;
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;

        hdr.r_ipv4.setValid();
        hdr.r_ipv4.src_addr = ip_saddr;
        hdr.r_ipv4.dst_addr = ip_daddr;
        hdr.r_ipv4.protocol = IPPROTO_UDP;
        hdr.r_ipv4.version = 4;
        hdr.r_ipv4.ihl = 5;
        hdr.r_ipv4.diffserv = 0;
        hdr.r_ipv4.identification = 0;
        hdr.r_ipv4.flags = 0;
        hdr.r_ipv4.frag_offset = 0;
        hdr.r_ipv4.ttl = 64;

        hdr.r_ports.setValid();
        hdr.r_ports.sport = sport;
        hdr.r_ports.dport = dport;

        hdr.r_udp.setValid();
    }

    action set_addresses_v6(bit<48> mac_saddr, bit<48> mac_daddr,
                            bit<128> ip_saddr, bit<128> ip_daddr,
                            bit<16> sport, bit<16> dport) {
        hdr.ethernet.setValid();
        hdr.ethernet.src_addr = mac_saddr;
        hdr.ethernet.dst_addr = mac_daddr;
        hdr.ethernet.ether_type = ETHERTYPE_IPV6;

        hdr.r_ipv6.setValid();
        hdr.r_ipv6.src_addr = ip_saddr;
        hdr.r_ipv6.dst_addr = ip_daddr;
        hdr.r_ipv6.nexthdr = IPPROTO_UDP;
        hdr.r_ipv6.version = 6;
        hdr.r_ipv6.tclass = 0;
        hdr.r_ipv6.flow = 0;
        hdr.r_ipv6.ttl = 64;

        hdr.r_ports.setValid();
        hdr.r_ports.sport = sport;
        hdr.r_ports.dport = dport;

        hdr.r_udp.setValid();
    }

    table address_data {
        key = { eg_intr_md.egress_port : exact; }
        actions = { set_addresses_v4; set_addresses_v6; @defaultonly NoAction; }
        const default_action = NoAction();
        size = COLL_ADDR_SIZE;
    }

    apply {
        eg_dprsr_md.drop_ctl = 0;

        if (eg_intr_md.egress_port[6:0] == PKTGEN_INDEX) {
            // to recirculation port, ignore packet
            hdr.ctrl_pad.setValid();
        } else {
            // set headers for IPFIX, UDP, IPv4, Ethernet
            address_data.apply();
            hdr.ctrl_pad.setInvalid();

            if (hdr.mirror.isValid() && hdr.mirror.info == HEADER_INFO_MIRROR_DROP) {
                eg_dprsr_md.drop_ctl = 1;
            } else {
                hdr.ipfix.seq = ipfix_seq.execute(0);
                meta.tstamp_inc = tstamp_base.execute(0);
                hdr.ipfix.tstamp = tstamp_offset.execute(0) + meta.tstamp_inc;
            }

            if ((meta.ctrl.isValid() && meta.ctrl.template_index == TEMPLATE_INDEX_IPV4) || hdr.ipv4.isValid()) {
                hdr.record.template_id = template_id.execute(0);
                meta.total_len = hdr.ipv4.len;
            } else if ((meta.ctrl.isValid() && meta.ctrl.template_index == TEMPLATE_INDEX_IPV6) || hdr.ipv6.isValid()) {
                hdr.record.template_id = template_id.execute(1);
                meta.total_len = hdr.ipv6.len + hdr.ipv6.minSizeInBytes();
            } else {
                hdr.record.template_id = template_id.execute(0);
            }

            const int udp_len = hdr.r_ports.minSizeInBytes() + hdr.r_udp.minSizeInBytes();
            const int ipv4_udp_len = hdr.r_ipv4.minSizeInBytes() + udp_len;
            const int ipfix_len = hdr.ipfix.minSizeInBytes() + hdr.record.minSizeInBytes();

            if (meta.ctrl.isValid() && meta.ctrl.info == HEADER_INFO_TEMPLATE) {
                // template: only set lengths for all layers
                hdr.r_ipv4.len = (bit<16>)ipv4_udp_len + hdr.ipfix.len;
                hdr.r_ipv6.len = (bit<16>)udp_len + hdr.ipfix.len;
                hdr.r_udp.len = (bit<16>)udp_len + hdr.ipfix.len;
                meta.csum_len = (bit<16>)udp_len + hdr.ipfix.len;
            } else if (hdr.mirror.isValid()) {
                hdr.pad.setValid();

                if ((hdr.ports.isValid() || hdr.icmp.isValid()) && hdr.mirror.estimate[1:0] != 0) {
                    if (hdr.mirror.info == HEADER_INFO_MIRROR_DROP) {
                        if (hdr.mirror.estimate[1:0] == 1) {
                            drop_1_pkts.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            drop_1_bytes.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            if (hdr.tcp.isValid()) {
                                report_1_flags.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            }
                        } else if (hdr.mirror.estimate[1:0] == 2) {
                            drop_2_pkts.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            drop_2_bytes.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            if (hdr.tcp.isValid()) {
                                report_2_flags.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            }
                        }
                    } else {
                        if (hdr.mirror.estimate[1:0] == 1) {
                            hdr.record.flowStartSeconds = report_1_start.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            hdr.record.packetDeltaCount = report_1_pkts.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            hdr.record.octetDeltaCount = report_1_bytes.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            if (hdr.tcp.isValid()) {
                                hdr.record.tcpControlBits = report_1_flags.execute((hdr.mirror.flow_hash[1*15 -1:(1 -1)*15]));
                            }
                        } else if (hdr.mirror.estimate[1:0] == 2) {
                            hdr.record.flowStartSeconds = report_2_start.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            hdr.record.packetDeltaCount = report_2_pkts.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            hdr.record.octetDeltaCount = report_2_bytes.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            if (hdr.tcp.isValid()) {
                                hdr.record.tcpControlBits = report_2_flags.execute((hdr.mirror.flow_hash[2*15 -1:(2 -1)*15]));
                            }
                        }
                    }
                }

                if (hdr.mirror.info == HEADER_INFO_MIRROR_REPLACED || hdr.record.packetDeltaCount == 0) {
                    hdr.record.packetDeltaCount = 1;
                    hdr.record.octetDeltaCount = (bit<32>)meta.total_len;
                }

                if (hdr.record.flowStartSeconds == 0) {
                    // new entry with missing table setting
                    hdr.record.flowStartSeconds = hdr.ipfix.tstamp;
                    hdr.record.tcpControlBits[11:0] = hdr.tcp.flags;
                }

                // insert remaining extracted fields into packet
                hdr.record.ingressInterface = 7w0 ++ hdr.mirror.ingress_port;
                hdr.record.egressInterface = 7w0 ++ hdr.mirror.egress_port;

                if (hdr.ipv4.isValid()) {
                    const int datav4_len = hdr.datav4.minSizeInBytes();
                    hdr.r_ipv4.len = ipv4_udp_len + ipfix_len + datav4_len;
                    hdr.r_ipv6.len = udp_len + ipfix_len + datav4_len;
                    hdr.r_udp.len = udp_len + ipfix_len + datav4_len;
                    hdr.ipfix.len = ipfix_len + datav4_len;
                    hdr.record.len = hdr.record.minSizeInBytes() + datav4_len;
                    meta.csum_len = udp_len + ipfix_len + datav4_len;

                    hdr.datav4.setValid();
                    hdr.datav4.sourceIPv4Address = hdr.ipv4.src_addr;
                    hdr.datav4.destinationIPv4Address = hdr.ipv4.dst_addr;
                    hdr.record.protocolIdentifier = hdr.ipv4.protocol;
                } else if (hdr.ipv6.isValid()) {
                    const int datav6_len = hdr.datav6.minSizeInBytes();
                    hdr.r_ipv4.len = ipv4_udp_len + ipfix_len + datav6_len;
                    hdr.r_ipv6.len = udp_len + ipfix_len + datav6_len;
                    hdr.r_udp.len = udp_len + ipfix_len + datav6_len;
                    hdr.ipfix.len = ipfix_len + datav6_len;
                    hdr.record.len = hdr.record.minSizeInBytes() + datav6_len;
                    meta.csum_len = udp_len + ipfix_len + datav6_len;

                    hdr.datav6.setValid();
                    hdr.datav6.sourceIPv6Address = hdr.ipv6.src_addr;
                    hdr.datav6.destinationIPv6Address = hdr.ipv6.dst_addr;
                    hdr.record.protocolIdentifier = hdr.ipv6.nexthdr;
                } else {
                    const int datav4_len = hdr.datav4.minSizeInBytes();
                    hdr.r_ipv4.len = ipv4_udp_len + ipfix_len + datav4_len;
                    hdr.r_ipv6.len = udp_len + ipfix_len + datav4_len;
                    hdr.r_udp.len = udp_len + ipfix_len + datav4_len;
                    hdr.ipfix.len = ipfix_len + datav4_len;
                    hdr.record.len = hdr.record.minSizeInBytes() + datav4_len;
                    meta.csum_len = udp_len + ipfix_len + datav4_len;

                    hdr.datav4.setValid();
                    hdr.datav4.sourceIPv4Address = 0;
                    hdr.datav4.destinationIPv4Address = 0;
                    hdr.record.protocolIdentifier = 0;
                }

                if (hdr.ports.isValid()) {
                    hdr.record.sourceTransportPort = hdr.ports.sport;
                    hdr.record.destinationTransportPort = hdr.ports.dport;
                } else if (hdr.icmp.isValid() && hdr.ipv4.isValid()) {
                    hdr.record.sourceTransportPort = 0;
                    hdr.record.destinationTransportPort = (bit<16>)(hdr.icmp.type ++ hdr.icmp.code);
                } else if (hdr.icmp.isValid() && hdr.ipv6.isValid()) {
                    hdr.record.sourceTransportPort = 0;
                    hdr.record.destinationTransportPort = (bit<16>)(hdr.icmp.type ++ hdr.icmp.code);
                } else {
                    hdr.record.sourceTransportPort = 0;
                    hdr.record.destinationTransportPort = 0;
                }

                // remove the entire incoming packet
                hdr.vlan_tag.setInvalid();
                hdr.ipv4.setInvalid();
                hdr.ipv6.setInvalid();
                hdr.ports.setInvalid();
                hdr.tcp.setInvalid();
                hdr.udp.setInvalid();
                hdr.icmp.setInvalid();
                hdr.mirror.setInvalid();
            }
        }
    }
}

control EgressDeparser( packet_out pkt,
                       inout egress_headers_t hdr,
                       in egress_meta_t meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    Checksum() ipv4_checksum;
    Checksum() udp_template_checksum;
    Checksum() udp_record_checksum;

    apply {
        if (hdr.r_ipv4.isValid()) {
            hdr.r_ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.r_ipv4.version,
                hdr.r_ipv4.ihl,
                hdr.r_ipv4.diffserv,
                hdr.r_ipv4.len,
                hdr.r_ipv4.identification,
                hdr.r_ipv4.flags,
                hdr.r_ipv4.frag_offset,
                hdr.r_ipv4.ttl,
                hdr.r_ipv4.protocol,
                hdr.r_ipv4.src_addr,
                hdr.r_ipv4.dst_addr
            });
        }
        if (hdr.record.isValid()) {
            hdr.r_udp.checksum = udp_record_checksum.update({
                hdr.r_ipv4.src_addr,
                hdr.r_ipv4.dst_addr,
                hdr.r_ipv6.src_addr,
                hdr.r_ipv6.dst_addr,
                meta.csum_len,
                8w0,
                hdr.r_ipv4.protocol,
                8w0,
                hdr.r_ipv6.nexthdr,
                hdr.r_ports.sport,
                hdr.r_ports.dport,
                hdr.r_udp.len,
                hdr.ipfix,
                hdr.record,
                hdr.datav4,
                hdr.datav6
            });
        }
        if (hdr.template.isValid()) {
            // includes partial checksum from control packet, over IPFIX template
            hdr.r_udp.checksum = udp_template_checksum.update({
                hdr.r_ipv4.src_addr,
                hdr.r_ipv4.dst_addr,
                hdr.r_ipv6.src_addr,
                hdr.r_ipv6.dst_addr,
                meta.csum_len,
                8w0,
                hdr.r_ipv4.protocol,
                8w0,
                hdr.r_ipv6.nexthdr,
                hdr.r_ports.sport,
                hdr.r_ports.dport,
                hdr.r_udp.len,
                hdr.ipfix,
                hdr.template,
                meta.ctrl.payload_checksum
            });
        }

        pkt.emit(hdr);
    }
}
# 13 "test/liraflow/forensics.p4" 2

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
