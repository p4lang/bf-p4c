/*
 * Copyright (c) 2015-2017 Barefoot Networks, Inc.
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

#ifndef JBAY_P4_
#define JBAY_P4_

//XXX Open issues:
// Meter color
// Math unit
// Action selector
// Digest
// Coalesce mirroring

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9>  PortId_t;               // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t;     // Multicast group id
typedef bit<5>  QueueId_t;              // Queue id
typedef bit<4>  CloneId_t;              // Clone id
typedef bit<10> MirrorId_t;             // Mirror id
typedef bit<16> ReplicationId_t;        // Replication id

typedef error ParserError_t;

/// Meter
enum MeterType_t { PACKETS, BYTES }

enum MeterColor_t { GREEN, YELLOW, RED }

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
    CRC16,
    CRC32,
    CSUM16
}

match_kind {
    // exact,
    // ternary,
    // lpm,               // Longest-prefix match.
    range,
    selector,             // Used for implementing dynamic action selection
    dleft_hash            // Used for dleft dynamic caching
}

error {
    // NoError,           // No error.
    // NoMatch,           // 'select' expression has no matches.
    // PacketTooShort,    // Not enough bits in packet for 'extract'.
    // StackOutOfBounds,  // Reference to invalid element of a header stack.
    // HeaderTooShort,    // Extracting too many bits into a varbit field.
    // ParserTimeout      // Parser execution time limit exceeded.
    CounterRange,         // Counter initialization error.
    Timeout,
    PhvOwner,             // Invalid destination container.
    MultiWrite,
    IbufOverflow,         // Input buffer overflow.
    IbufUnderflow         // Inbut buffer underflow.
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag;               // Flag distinguising original packets
                                        // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version;              // Read-only Packet version.

    bit<3> _pad2;

    PortId_t ingress_port;              // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;         // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    PortId_t ucast_egress_port;         // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bool bypass_egress;                 // Request flag for the warp mode
                                        // (egress bypass).

    bool deflect_on_drop;               // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos;                 // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    QueueId_t qid;                      // Egress (logical) queue id into which
                                        // this packet will be deposited.

    bit<3> icos_for_copy_to_cpu;        // Ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

    bool copy_to_cpu;                   // Request for copy to cpu.

    bit<2> packet_color;                // Packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

    bool disable_ucast_cutthru;         // Disable cut-through forwarding for
                                        // unicast.

    bool enable_mcast_cutthru;          // Enable cut-through forwarding for
                                        // multicast.

    MulticastGroupId_t  mcast_grp_a;    // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

    MulticastGroupId_t  mcast_grp_b;    // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

    bit<13> level1_mcast_hash;          // Source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash;          // Source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

    bit<16> level1_exclusion_id;        // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    bit<9> level2_exclusion_id;         // Exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

    ReplicationId_t rid;                // L3 replication id for multicast.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;              // Global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32> global_ver;                 // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err;                 // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_deparser_t {

    bit<3> drop_ctl;                    // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring
    bit<3> digest_type;

    bit<3> resubmit_type;

    bit<4> mirror_type;                 // The user-selected mirror field list
                                        // index.

    bit<1> mirror_io_select;            // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash;                // Mirror hash field.
    bit<3> mirror_ingress_cos;          // Mirror ingress cos for PG mapping.
    bool mirror_deflect_on_drop;        // Mirror enable deflection on drop if true.
    bool mirror_copy_to_cpu_ctrl;       // Mirror enable copy-to-cpu if true.
    bool mirror_multicast_ctrl;         // Mirror enable multicast if true.
    bit<9> mirror_egress_port;          // Mirror packet egress port.
    bit<7> mirror_qid;                  // Mirror packet qid.
    bit<8> mirror_coalesce_length;      // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    // TODO:
    // afc
    // mtu_trunc_len;
    // mtu_trunc_err_f
}
// -----------------------------------------------------------------------------
// GHOST INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata @__ghost_metadata
header ghost_intrinsic_metadata_t {
    bit<1>      ping_pong;              // ping-pong bit to control which version to update
    bit<18>     qlength;
    bit<11>     qid;                    // queue id for update
    bit<2>      pipe_id;
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header egress_intrinsic_metadata_t {
    bit<7> _pad0;

    bit<9> egress_port;                 // Egress port id.
                                        // this field is passed to the deparser

    bit<5> _pad1;

    bit<19> enq_qdepth;                 // Queue depth at the packet enqueue
                                        // time.

    bit<6> _pad2;

    bit<2> enq_congest_stat;            // Queue congestion status at the packet
                                        // enqueue time.

    bit<32> enq_tstamp;                 // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    bit<5> _pad3;

    bit<19> deq_qdepth;                 // Queue depth at the packet dequeue
                                        // time.

    bit<6> _pad4;

    bit<2> deq_congest_stat;            // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat;       // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<32> deq_timedelta;              // Time delta between the packet's
                                        // enqueue and dequeue time.

    ReplicationId_t egress_rid;         // L3 replication id for multicast
                                        // packets.

    bit<7> _pad5;

    bit<1> egress_rid_first;            // Flag indicating the first replica for
                                        // the given multicast group.

    bit<3> _pad6;

    QueueId_t egress_qid;               // Egress (physical) queue id via which
                                        // this packet was served.

    bit<5> _pad7;

    bit<3> egress_cos;                  // Egress cos (eCoS) value.

    bit<7> _pad8;

    bit<1> deflection_flag;             // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length;                 // Packet length, in bytes
}


@__intrinsic_metadata
struct egress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;              // Global timestamp (ns) taken upon
                                        // arrival at egress.

    bit<32> global_ver;                 // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err;                 // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl;                    // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring

    bit<4> mirror_type;

    bit<1> coalesce_flush;              // Flush the coalesced mirror buffer

    bit<7> coalesce_length;             // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer

    bit<1> mirror_io_select;            // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash;                // Mirror hash field.
    bit<3> mirror_ingress_cos;          // Mirror ingress cos for PG mapping.
    bool mirror_deflect_on_drop;        // Mirror enable deflection on drop if true.
    bool mirror_copy_to_cpu_ctrl;       // Mirror enable copy-to-cpu if true.
    bool mirror_multicast_ctrl;         // Mirror enable multicast if true.
    bit<9> mirror_egress_port;          // Mirror packet egress port.
    bit<7> mirror_qid;                  // Mirror packet qid.
    bit<8> mirror_coalesce_length;      // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    // TODO:
    // afc
    // mtu_trunc_len;
    // mtu_trunc_err_f
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_output_port_t {
    bool capture_tstamp_on_tx;          // Request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).

    bool update_delay_on_tx;            // Request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
    bool force_tx_error;                // force a hardware transmission error
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
    bit<3> _pad1;
    bit<2> pipe_id;                     // Pipe id
    bit<3> app_id;                      // Application id
    bit<8> _pad2;

    bit<16> batch_id;                   // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id;                  // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    bit<3> _pad1;
    bit<2> pipe_id;                     // Pipe id
    bit<3> app_id;                      // Application id
    bit<15> _pad2;
    bit<9> port_num;                    // Port number

    bit<16> packet_id;                  // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    bit<3> _pad1;
    bit<2> pipe_id;                     // Pipe id
    bit<3> app_id;                      // Application id
    bit<24> key;                        // Key from the recirculated packet

    bit<16> packet_id;                  // Start at 0 and increment to a
                                        // programmed number
}

// -----------------------------------------------------------------------------
// TIME SYNCHRONIZATION
// -----------------------------------------------------------------------------

header ptp_metadata_t {
    bit<8> cf_byte_offset;              // Byte offset at which the egress MAC
                                        // needs to re-insert
                                        // ptp_sync.correction field

    bit<8> udp_cksum_byte_offset;       // Byte offset at which the egress MAC
                                        // needs to update the UDP checksum

    bit<48> updated_cf;                 // Updated correction field in ptp sync
                                        // message
}

// -----------------------------------------------------------------------------
// CHECKSUM
// -----------------------------------------------------------------------------
// Tofino checksum engine can verify the checksums for header-only checksums
// and calculate the residual (checksum minus the header field
// contribution) for checksums that include the payload.
// Checksum engine only supports 16-bit ones' complement checksums.

extern Checksum<W> {
    /// Constructor.
    /// @param algorithm : Only HashAlgorithm_t.CSUM16 is supported.
    Checksum(HashAlgorithm_t algorithm);

    /// Add data to checksum.
    /// @param data : List of fields to be added to checksum calculation. The
    /// data must be byte aligned.
    void add<T>(in T data);

    /// Subtract data from existing checksum.
    /// @param data : List of fields to be subtracted from the checksum. The
    /// data must be byte aligned.
    void subtract<T>(in T data);

    /// Verify whether the complemented sum is zero.
    bool verify();

    W residual_checksum();

    /// Calculate the checksum for a  given list of fields.
    W update<T>(in T data);

    W update<T>(in T data, in W residul_csum);
}

// ----------------------------------------------------------------------------
// PARSER COUNTER/PRIORITY
// ----------------------------------------------------------------------------
// Tofino parser counter can be used to extract header stacks or headers with
// variable length. Tofino has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.
extern ParserCounter<W> {
    // Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Rotate the source field right by this number of bits.
    /// @param mask : Mask the rotated source field by 2**(MASK+1) - 1.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set(in W value,
             in W max,
             in W rotate,
             in W mask,
             in W add);

    /// Get the parser counter value. Can only be used in the select expression
    /// in a parser state and can only checks if the counter is zero or
    /// negative.
    /// @return : restricted parser counter value.
    W get();

    /// Add an immediate value to the parser counter.
    /// @param value : Constant to add to the counter.
    void increment(in W value);
}

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
extern Hash<W> {
    /// Constructor
    Hash(HashAlgorithm_t algo);

    /// Compute the hash for data.
    /// @param data : The data over which to calculate the hash.
    /// @return The hash value.
    W get<D>(in D data);

    /// Compute the hash for data.
    /// @param data : The data over which to calculate the hash.
    /// @param base : Minimum return value.
    /// @param max : The value use in modulo operation.
    /// @return (base + (h % max)) where h is the hash value.
    W get<D>(in D data, in W base, in W max);
}

/// Random number generator.
extern Random<W> {
    /// Constructor
    Random();

    /// Return a random number with uniform distribution.
    /// @return : ranom number between 0 and 2**W - 1
    W get(W d);
}

/// Idle timeout
extern IdleTimeout {
    IdleTimeout();
}


// -----------------------------------------------------------------------------
// EXTERN FUNCTIONS
// -----------------------------------------------------------------------------

extern T max<T>(T t1, T t2);

extern T min<T>(T t1, T t2);

/// Counter
extern Counter<W, I> {
    Counter(bit<32> size, CounterType_t type);
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
    bit<8> execute(in I index, in bit<2> color);
    bit<8> execute(in I index);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type);
    bit<8> execute(in bit<2> color);
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
extern Register<T> {
    /// Instantiate an array of <size> registers. The initial value is
    /// undefined.
    Register(bit<32> size);

    /// Initialize an array of <size> registers and set their value to
    /// initial_value.
    Register(bit<32> size, T initial_value);

    ///XXX(hanw): BRIG-212
    /// following two methods are not supported in the Barefoot backend
    /// they are present to help with the transition from v1model to tofino.p4
    /// after the transition, these two methods should be removed
    /// and the corresponding test cases should be marked as XFAILs.
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

/// Direct Register
extern DirectRegister<T> {
    DirectRegister();

    DirectRegister(T initial_value);
}

extern RegisterParam<T> {
    /// Construct a read-only run-time configurable parameter that can only be
    /// used by RegisterAction.
    /// @param initial_value : initial value of the parameter.
    RegisterParam(T initial_value);

    /// Return the value of the parameter.
    T read();
}

extern RegisterAction<T, U> {
    RegisterAction(Register<T> reg);
    abstract void apply(inout T value, @optional out U rv1, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);
    U execute<H>(@optional in H index, @optional out U rv2,
                 @optional out U rv3, @optional out U rv4); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv, rv2, rv3, rv4);
        reg.write(index, value);
        return rv;
    } */
    U execute_direct(@optional out U rv2, @optional out U rv3, @optional out U rv4);

    /* stateful logging execute at an index that increments each time */
    U execute_log(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    U enqueue(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* fifo push */
    U dequeue(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* fifo pop */
    U push(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* stack push */
    U pop(@optional out U rv2, @optional out U rv3, @optional out U rv4);  /* stack pop */

    @optional abstract void overflow(@optional inout T value,
                                     @optional out U rv1, @optional out U rv2,
                                     @optional out U rv3, @optional out U rv4);
    @optional abstract void underflow(@optional inout T value,
                                      @optional out U rv1, @optional out U rv2,
                                      @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(); /* return the match address */
    U predicate(); /* return the predicate value */
}

extern LearnAction<T, D, U> {
    LearnAction(Register<T> reg);
    abstract void apply(inout T value, in D digest, in bool learn,
                        @optional out U rv1, @optional out U rv2,
                        @optional out U rv3, @optional out U rv4);
    U execute(@optional out U rv2, @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(); /* return the match address */
    U predicate(); /* return the predicate value */
}

extern ActionSelector {
    /// Construct an action selector of 'size' entries
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);

    /// Stateful action selector.
    ActionSelector(bit<32> size,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   Register<bit<1>> reg);
}

extern ActionProfile {
    /// Construct an action profile of 'size' entries.
    ActionProfile(bit<32> size);
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

#endif  /* _JBAY_P4_ */
