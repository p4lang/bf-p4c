# 1 "fabric-tofino.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "fabric-tofino.p4"
# 42 "fabric-tofino.p4"
// Depends on number of unique next_id expected




// Max size of ECMP groups

// Ideally HASHED_NEXT_TABLE_SIZE * HASHED_SELECTOR_MAX_GROUP_SIZE






# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
    ParserTimeout /// Parser execution time limit exceeded.
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
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 1
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

/* P4-16 declaration of the P4 v1.0 switch model */




# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 2

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
}

// Are these correct?
@metadata @name("standard_metadata")
struct standard_metadata_t {
    bit<9> ingress_port;
    bit<9> egress_spec;
    bit<9> egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    // The drop and recirculate_port fields are not used at all by the
    // behavioral-model simple_switch software switch as of September
    // 2018, and perhaps never was.  They may be considered
    // deprecated, at least for that P4 target device.  simple_switch
    // uses the value of the egress_spec field to determine whether a
    // packet is dropped or not, and it is recommended to use the
    // P4_14 drop() primitive action, or the P4_16 + v1model
    // mark_to_drop() primitive action, to cause that field to be
    // changed so the packet will be dropped.
    bit<1> drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
    //
    // @alias is used to generate the field_alias section of the BMV2 JSON.
    // Field alias creates a mapping from the metadata name in P4 program to
    // the behavioral model's internal metadata name. Here we use it to
    // expose all metadata supported by simple switch to the user through
    // standard_metadata_t.
    //
    // flattening fields that exist in bmv2-ss
    // queueing metadata
    @alias("queueing_metadata.enq_timestamp") bit<32> enq_timestamp;
    @alias("queueing_metadata.enq_qdepth") bit<19> enq_qdepth;
    @alias("queueing_metadata.deq_timedelta") bit<32> deq_timedelta;
    @alias("queueing_metadata.deq_qdepth") bit<19> deq_qdepth;
    // intrinsic metadata
    @alias("intrinsic_metadata.ingress_global_timestamp") bit<48> ingress_global_timestamp;
    @alias("intrinsic_metadata.egress_global_timestamp") bit<48> egress_global_timestamp;
    @alias("intrinsic_metadata.lf_field_list") bit<32> lf_field_list;
    @alias("intrinsic_metadata.mcast_grp") bit<16> mcast_grp;
    @alias("intrinsic_metadata.resubmit_flag") bit<32> resubmit_flag;
    @alias("intrinsic_metadata.egress_rid") bit<16> egress_rid;
    /// Indicates that a verify_checksum() method has failed.
    // 1 if a checksum error was found, otherwise 0.
    bit<1> checksum_error;
    @alias("intrinsic_metadata.recirculate_flag") bit<32> recirculate_flag;
    /// Error produced by parsing
    error parser_error;
}

enum CounterType {
    packets,
    bytes,
    packets_and_bytes
}

enum MeterType {
    packets,
    bytes
}

extern counter {
    counter(bit<32> size, CounterType type);
    void count(in bit<32> index);
}

extern direct_counter {
    direct_counter(CounterType type);
    void count();
}

extern meter {
    meter(bit<32> size, MeterType type);
    void execute_meter<T>(in bit<32> index, out T result);
}

extern direct_meter<T> {
    direct_meter(MeterType type);
    void read(out T result);
}

extern register<T> {
    register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

// used as table implementation attribute
extern action_profile {
    action_profile(bit<32> size);
}

// Get a random number in the range lo..hi
extern void random<T>(out T result, in T lo, in T hi);
// If the type T is a named struct, the name is used
// to generate the control-plane API.
extern void digest<T>(in bit<32> receiver, in T data);

enum HashAlgorithm {
    crc32,
    crc32_custom,
    crc16,
    crc16_custom,
    random,
    identity,
    csum16,
    xor16
}

extern void mark_to_drop();
extern void hash<O, T, D, M>(out O result, in HashAlgorithm algo, in T base, in D data, in M max);

extern action_selector {
    action_selector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

enum CloneType {
    I2E,
    E2E
}

@deprecated("Please use verify_checksum/update_checksum instead.")
extern Checksum16 {
    Checksum16();
    bit<16> get<D>(in D data);
}

/**
Verifies the checksum of the supplied data.
If this method detects that a checksum of the data is not correct it
sets the standard_metadata checksum_error bit.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Checksum type; must be bit<X> type.
@param condition  If 'false' the verification always succeeds.
@param data       Data whose checksum is verified.
@param checksum   Expected checksum of the data; note that is must be a left-value.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void verify_checksum<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);
/**
Computes the checksum of the supplied data.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Output type; must be bit<X> type.
@param condition  If 'false' the checksum is not changed
@param data       Data whose checksum is computed.
@param checksum   Checksum of the data.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void update_checksum<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);

/**
Verifies the checksum of the supplied data including the payload.
The payload is defined as "all bytes of the packet which were not parsed by the parser".
If this method detects that a checksum of the data is not correct it
sets the standard_metadata checksum_error bit.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Checksum type; must be bit<X> type.
@param condition  If 'false' the verification always succeeds.
@param data       Data whose checksum is verified.
@param checksum   Expected checksum of the data; note that is must be a left-value.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void verify_checksum_with_payload<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);
/**
Computes the checksum of the supplied data including the payload.
The payload is defined as "all bytes of the packet which were not parsed by the parser".
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Output type; must be bit<X> type.
@param condition  If 'false' the checksum is not changed
@param data       Data whose checksum is computed.
@param checksum   Checksum of the data.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void update_checksum_with_payload<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);

extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);

extern void truncate(in bit<32> length);

// The name 'standard_metadata' is reserved

// Architecture.
// M should be a struct of structs
// H should be a struct of headers, stacks or header_unions

parser Parser<H, M>(packet_in b,
                    out H parsedHdr,
                    inout M meta,
                    inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
VerifyChecksum control are: block statements, calls to the
verify_checksum and verify_checksum_with_payload methods,
and return statements. */
control VerifyChecksum<H, M>(inout H hdr,
                             inout M meta);
@pipeline
control Ingress<H, M>(inout H hdr,
                      inout M meta,
                      inout standard_metadata_t standard_metadata);
@pipeline
control Egress<H, M>(inout H hdr,
                     inout M meta,
                     inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
ComputeChecksum control are: block statements, calls to the
update_checksum and update_checksum_with_payload methods,
and return statements. */
control ComputeChecksum<H, M>(inout H hdr,
                              inout M meta);
@deparser
control Deparser<H>(packet_out b, in H hdr);

package V1Switch<H, M>(Parser<H, M> p,
                       VerifyChecksum<H, M> vr,
                       Ingress<H, M> ig,
                       Egress<H, M> eg,
                       ComputeChecksum<H, M> ck,
                       Deparser<H> dep
                       );
# 19 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/size.p4" 1
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/filtering.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/filtering.p4" 2
# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 1
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

/* P4-16 declaration of the P4 v1.0 switch model */
# 19 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/filtering.p4" 2

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../define.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 84 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../define.p4"
typedef bit<3> fwd_type_t;
typedef bit<32> next_id_t;
typedef bit<20> mpls_label_t;
typedef bit<9> port_num_t;
typedef bit<48> mac_addr_t;
typedef bit<16> mcast_group_id_t;
typedef bit<12> vlan_id_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> l4_port_t;

// SPGW types
typedef bit<2> direction_t;
typedef bit pcc_gate_status_t;
typedef bit<32> sdf_rule_id_t;
typedef bit<32> pcc_rule_id_t;

// spgw.p4 expects uplink packets with IP dst on this subnet
// 140.0.0.0/8
const ipv4_addr_t S1U_SGW_PREFIX = 2348810240;


const bit<16> ETHERTYPE_QINQ = 0x88A8;
const bit<16> ETHERTYPE_QINQ_NON_STD = 0x9100;
const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_MPLS = 0x8847;
const bit<16> ETHERTYPE_MPLS_MULTICAST =0x8848;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86dd;
const bit<16> ETHERTYPE_ARP = 0x0806;

const bit<8> PROTO_ICMP = 1;
const bit<8> PROTO_TCP = 6;
const bit<8> PROTO_UDP = 17;
const bit<8> PROTO_ICMPV6 = 58;

const bit<4> IPV4_MIN_IHL = 5;

const fwd_type_t FWD_BRIDGING = 0;
const fwd_type_t FWD_MPLS = 1;
const fwd_type_t FWD_IPV4_UNICAST = 2;
const fwd_type_t FWD_IPV4_MULTICAST = 3;
const fwd_type_t FWD_IPV6_UNICAST = 4;
const fwd_type_t FWD_IPV6_MULTICAST = 5;
const fwd_type_t FWD_UNKNOWN = 7;

const vlan_id_t DEFAULT_VLAN_ID = 12w4094;

const bit<8> DEFAULT_MPLS_TTL = 64;
const bit<8> DEFAULT_IPV4_TTL = 64;

const sdf_rule_id_t DEFAULT_SDF_RULE_ID = 0;
const pcc_rule_id_t DEFAULT_PCC_RULE_ID = 0;
const direction_t SPGW_DIR_UNKNOWN = 2w0;
const direction_t SPGW_DIR_UPLINK = 2w1;
const direction_t SPGW_DIR_DOWNLINK = 2w2;
const pcc_gate_status_t PCC_GATE_OPEN = 1w0;
const pcc_gate_status_t PCC_GATE_CLOSED = 1w1;

/* indicate INT at LSB of DSCP */
const bit<6> INT_DSCP = 0x1;

// Length of the whole INT header,
// including shim and tail, excluding metadata stack.
const bit<8> INT_HEADER_LEN_WORDS = 4;
const bit<16> INT_HEADER_LEN_BYTES = 16;

const bit<8> CPU_MIRROR_SESSION_ID = 250;
const bit<32> REPORT_MIRROR_SESSION_ID = 500;

const bit<4> NPROTO_ETHERNET = 0;
const bit<4> NPROTO_TELEMETRY_DROP_HEADER = 1;
const bit<4> NPROTO_TELEMETRY_SWITCH_LOCAL_HEADER = 2;

const bit<6> HW_ID = 1;
const bit<8> REPORT_FIXED_HEADER_LEN = 12;
const bit<8> DROP_REPORT_HEADER_LEN = 12;
const bit<8> LOCAL_REPORT_HEADER_LEN = 16;
const bit<8> ETH_HEADER_LEN = 14;
const bit<8> IPV4_MIN_HEAD_LEN = 20;
const bit<8> UDP_HEADER_LEN = 8;

action nop() {
    NoAction();
}
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../int/int_header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../int/../define.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../int/int_header.p4" 2

struct int_metadata_t {
    bit<1> source;
    bit<1> transit;
    bit<1> sink;
    bit<32> switch_id;
    bit<8> new_words;
    bit<16> new_bytes;
    bit<32> ig_tstamp;
    bit<32> eg_tstamp;
}

// INT headers - 8 bytes
header int_header_t {
    bit<2> ver;
    bit<2> rep;
    bit<1> c;
    bit<1> e;
    bit<5> rsvd1;
    bit<5> ins_cnt;
    bit<8> max_hop_cnt;
    bit<8> total_hop_cnt;
    bit<4> instruction_mask_0003; /* split the bits for lookup */
    bit<4> instruction_mask_0407;
    bit<4> instruction_mask_0811;
    bit<4> instruction_mask_1215;
    bit<16> rsvd2;
}

// INT shim header for TCP/UDP - 4 bytes
header intl4_shim_t {
    bit<8> int_type;
    bit<8> rsvd1;
    bit<8> len_words; // 4-byte words.
    bit<8> rsvd2;
}
// INT tail header for TCP/UDP - 4 bytes
header intl4_tail_t {
    bit<8> next_proto;
    bit<16> dest_port;
    bit<2> padding;
    bit<6> dscp;
}
# 22 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 2

@controller_header("packet_in")
header packet_in_header_t {
    port_num_t ingress_port;
    bit<7> _pad;
}

@not_extracted_in_egress
@controller_header("packet_out")
header packet_out_header_t {
    port_num_t egress_port;
    bit<7> _pad;
}

header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> eth_type;
}

header vlan_tag_t {
    bit<3> pri;
    bit<1> cfi;
    vlan_id_t vlan_id;
    bit<16> eth_type;
}

header mpls_t {
    bit<20> label;
    bit<3> tc;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ipv6_t {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    bit<128> src_addr;
    bit<128> dst_addr;
}

header tcp_t {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<3> res;
    bit<3> ecn;
    bit<6> ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> sport;
    bit<16> dport;
    bit<16> len;
    bit<16> checksum;
}

header icmp_t {
    bit<8> icmp_type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    bit<64> timestamp;
}
# 143 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4"
//Custom metadata definition
struct fabric_metadata_t {
    bit<16> eth_type;
    bit<16> ip_eth_type;
    vlan_id_t vlan_id;
    bit<3> vlan_pri;
    bit<1> vlan_cfi;
    mpls_label_t mpls_label;
    bit<8> mpls_ttl;
    bit<1> skip_forwarding;
    bit<1> skip_next;
    fwd_type_t fwd_type;
    next_id_t next_id;
    bit<1> is_multicast;
    bit<1> is_controller_packet_out;
    bit<1> clone_to_cpu;
    bit<8> ip_proto;
    bit<16> l4_sport;
    bit<16> l4_dport;






}

struct parsed_headers_t {
    ethernet_t ethernet;
    vlan_tag_t vlan_tag;

    vlan_tag_t inner_vlan_tag;

    mpls_t mpls;







    ipv4_t ipv4;



    tcp_t tcp;
    udp_t udp;
    icmp_t icmp;
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
# 219 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4"
}
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/filtering.p4" 2

control Filtering (inout parsed_headers_t hdr,
                   inout fabric_metadata_t fabric_metadata,
                   inout standard_metadata_t standard_metadata) {

    /*
     * Ingress Port VLAN Table.
     *
     * Filter packets based on ingress port and VLAN tag.
     */
    direct_counter(CounterType.packets_and_bytes) ingress_port_vlan_counter;

    action deny() {
        // Packet from unconfigured port. Skip forwarding and next block.
        // Do ACL table in case we want to punt to cpu.
        fabric_metadata.skip_forwarding = 1w1;
        fabric_metadata.skip_next = 1w1;
        ingress_port_vlan_counter.count();
    }

    action permit() {
        // Allow packet as is.
        ingress_port_vlan_counter.count();
    }

    action permit_with_internal_vlan(vlan_id_t vlan_id) {
        fabric_metadata.vlan_id = vlan_id;
        ingress_port_vlan_counter.count();
    }

    table ingress_port_vlan {
        key = {
            standard_metadata.ingress_port: exact @name("ig_port");
            hdr.vlan_tag.isValid(): exact @name("vlan_is_valid");
            hdr.vlan_tag.vlan_id: ternary @name("vlan_id");
        }
        actions = {
            deny();
            permit();
            permit_with_internal_vlan();
        }
        const default_action = deny();
        counters = ingress_port_vlan_counter;
        size = 2048;
    }

    /*
     * Forwarding Classifier.
     *
     * Set which type of forwarding behavior to execute in the next control block.
     * There are six types of tables in Forwarding control block:
     * - Bridging: default forwarding type
     * - MPLS: destination mac address is the router mac and ethernet type is
     *   MPLS(0x8847)
     * - IP Multicast: destination mac address is multicast address and ethernet
     *   type is IP(0x0800 or 0x86dd)
     * - IP Unicast: destination mac address is router mac and ethernet type is
     *   IP(0x0800 or 0x86dd)
     */
    direct_counter(CounterType.packets_and_bytes) fwd_classifier_counter;

    action set_forwarding_type(fwd_type_t fwd_type) {
        fabric_metadata.fwd_type = fwd_type;
        fwd_classifier_counter.count();
    }

    table fwd_classifier {
        key = {
            standard_metadata.ingress_port: exact @name("ig_port");
            hdr.ethernet.dst_addr: ternary @name("eth_dst");
            fabric_metadata.eth_type: exact @name("eth_type");
        }
        actions = {
            set_forwarding_type;
        }
        const default_action = set_forwarding_type(FWD_BRIDGING);
        counters = fwd_classifier_counter;
        size = 2048;
    }

    apply {
        // Initialize lookup metadata. Packets without a VLAN header will be
        // treated as belonging to a default VLAN ID (see parser).
        if (hdr.vlan_tag.isValid()) {
            fabric_metadata.eth_type = hdr.vlan_tag.eth_type;
            fabric_metadata.vlan_id = hdr.vlan_tag.vlan_id;
            fabric_metadata.vlan_pri = hdr.vlan_tag.pri;
            fabric_metadata.vlan_cfi = hdr.vlan_tag.cfi;
        }
        if (!hdr.mpls.isValid()) {
            // Packets with a valid MPLS header will have
            // fabric_metadata.mpls_ttl set to the packet's MPLS ttl value (see
            // parser). In any case, if we are forwarding via MPLS, ttl will be
            // decremented in egress.
            fabric_metadata.mpls_ttl = DEFAULT_MPLS_TTL + 1;
        }

        ingress_port_vlan.apply();
        fwd_classifier.apply();
    }
}
# 22 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4" 2
# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 1
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

/* P4-16 declaration of the P4 v1.0 switch model */
# 19 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4" 2

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../define.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 22 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4" 2


control Forwarding (inout parsed_headers_t hdr,
                    inout fabric_metadata_t fabric_metadata,
                    inout standard_metadata_t standard_metadata) {

    @hidden
    action set_next_id(next_id_t next_id) {
        fabric_metadata.next_id = next_id;
    }

    /*
     * Bridging Table.
     */
    direct_counter(CounterType.packets_and_bytes) bridging_counter;

    action set_next_id_bridging(next_id_t next_id) {
        set_next_id(next_id);
        bridging_counter.count();
    }

    // FIXME: using ternary for eth_dst prevents our ability to scale in
    //  bridging heavy environments. Can we come up with a multi-table approach?
    //  For example a smaller bridging_ternary and a larger bridging_exact.
    table bridging {
        key = {
            fabric_metadata.vlan_id: exact @name("vlan_id");
            hdr.ethernet.dst_addr: ternary @name("eth_dst");
        }
        actions = {
            set_next_id_bridging;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = bridging_counter;
        size = 2048;
    }

    /*
     * MPLS Table.
     */
    direct_counter(CounterType.packets_and_bytes) mpls_counter;

    action pop_mpls_and_next(next_id_t next_id) {
        fabric_metadata.mpls_label = 0;
        set_next_id(next_id);
        mpls_counter.count();
    }

    table mpls {
        key = {
            fabric_metadata.mpls_label: exact @name("mpls_label");
        }
        actions = {
            pop_mpls_and_next;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = mpls_counter;
        size = 2048;
    }

    /*
     * IPv4 Routing Table.
     */
    direct_counter(CounterType.packets_and_bytes) routing_v4_counter;

    action set_next_id_routing_v4(next_id_t next_id) {
        set_next_id(next_id);
        routing_v4_counter.count();
    }

    action nop_routing_v4() {
        routing_v4_counter.count();
    }


    @alpm(1)

    table routing_v4 {
        key = {
            hdr.ipv4.dst_addr: lpm @name("ipv4_dst");
        }
        actions = {
            set_next_id_routing_v4;
            nop_routing_v4;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = routing_v4_counter;
        size = 65536;
    }
# 140 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/forwarding.p4"
    apply {
        if (fabric_metadata.fwd_type == FWD_BRIDGING) bridging.apply();
        else if (fabric_metadata.fwd_type == FWD_MPLS) mpls.apply();
        else if (fabric_metadata.fwd_type == FWD_IPV4_UNICAST) routing_v4.apply();



    }
}
# 23 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/acl.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/acl.p4" 2
# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 1
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

/* P4-16 declaration of the P4 v1.0 switch model */
# 19 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/acl.p4" 2

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../define.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/acl.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 22 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/acl.p4" 2

control Acl (inout parsed_headers_t hdr,
             inout fabric_metadata_t fabric_metadata,
             inout standard_metadata_t standard_metadata) {

    /*
     * ACL Table.
     */
    direct_counter(CounterType.packets_and_bytes) acl_counter;

    action set_next_id_acl(next_id_t next_id) {
        fabric_metadata.next_id = next_id;
        acl_counter.count();
    }

    // Send immendiatelly to CPU - skip the rest of ingress.
    action punt_to_cpu() {
        standard_metadata.egress_spec = 192;
        fabric_metadata.skip_next = 1w1;
        acl_counter.count();
    }

    action clone_to_cpu() {
        // FIXME: works only if pkt will be replicated via PRE multicast group.
        fabric_metadata.clone_to_cpu = 1w1;
        acl_counter.count();
    }

    action drop() {
        mark_to_drop();
        fabric_metadata.skip_next = 1w1;
        acl_counter.count();
    }

    action nop_acl() {
        acl_counter.count();
    }

    table acl {
        key = {
            standard_metadata.ingress_port: ternary @name("ig_port"); // 9
            fabric_metadata.ip_proto: ternary @name("ip_proto"); // 8
            fabric_metadata.l4_sport: ternary @name("l4_sport"); // 16
            fabric_metadata.l4_dport: ternary @name("l4_dport"); // 16
            hdr.ethernet.dst_addr: ternary @name("eth_src"); // 48
            hdr.ethernet.src_addr: ternary @name("eth_dst"); // 48
            hdr.vlan_tag.vlan_id: ternary @name("vlan_id"); // 12
            fabric_metadata.eth_type: ternary @name("eth_type"); //16
            hdr.ipv4.src_addr: ternary @name("ipv4_src"); // 32
            hdr.ipv4.dst_addr: ternary @name("ipv4_dst"); // 32
            hdr.icmp.icmp_type: ternary @name("icmp_type"); // 8
            hdr.icmp.icmp_code: ternary @name("icmp_code"); // 8
        }

        actions = {
            set_next_id_acl;
            punt_to_cpu;
            clone_to_cpu;
            drop;
            nop_acl;
        }

        const default_action = nop_acl();
        size = 1024;
        counters = acl_counter;
    }

    apply {
        acl.apply();
    }
}
# 24 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/next.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/core.p4" 1
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
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/next.p4" 2
# 1 "/home/sdn/bf-sde-8.7.0/install/share/p4c/p4include/v1model.p4" 1
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

/* P4-16 declaration of the P4 v1.0 switch model */
# 19 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/next.p4" 2

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/next.p4" 2

control Next (inout parsed_headers_t hdr,
              inout fabric_metadata_t fabric_metadata,
              inout standard_metadata_t standard_metadata) {

    /*
     * General actions.
     */
    @hidden
    action output(port_num_t port_num) {
     standard_metadata.egress_spec = port_num;
    }

    @hidden
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

    @hidden
    action rewrite_dmac(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }

    @hidden
    action set_mpls_label(mpls_label_t label) {
        fabric_metadata.mpls_label = label;
    }

    @hidden
    action routing(port_num_t port_num, mac_addr_t smac, mac_addr_t dmac) {
        rewrite_smac(smac);
        rewrite_dmac(dmac);
        output(port_num);
    }

    @hidden
    action mpls_routing(port_num_t port_num, mac_addr_t smac, mac_addr_t dmac,
                        mpls_label_t label) {
        set_mpls_label(label);
        routing(port_num, smac, dmac);
    }

    /*
     * Next VLAN table.
     * Modify VLAN ID based on next ID.
     */
    direct_counter(CounterType.packets_and_bytes) next_vlan_counter;

    action set_vlan(vlan_id_t vlan_id) {
        fabric_metadata.vlan_id = vlan_id;
        next_vlan_counter.count();
    }

    table next_vlan {
        key = {
            fabric_metadata.next_id: exact @name("next_id");
        }
        actions = {
            set_vlan;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = next_vlan_counter;
        size = 2048;
    }


    /*
     * Cross-connect table.
     * Bidirectional forwarding for the same next id.
     */
    direct_counter(CounterType.packets_and_bytes) xconnect_counter;

    action output_xconnect(port_num_t port_num) {
        output(port_num);
        xconnect_counter.count();
    }

    action set_next_id_xconnect(next_id_t next_id) {
        fabric_metadata.next_id = next_id;
        xconnect_counter.count();
    }

    table xconnect {
        key = {
            standard_metadata.ingress_port: exact @name("ig_port");
            fabric_metadata.next_id: exact @name("next_id");
        }
        actions = {
            output_xconnect;
            set_next_id_xconnect;
            @defaultonly nop;
        }
        counters = xconnect_counter;
        const default_action = nop();
        size = 4096;
    }
# 160 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/next.p4"
    /*
     * Hashed table.
     * Execute an action profile selector based on next id.
     */
    @max_group_size(16)
    action_selector(HashAlgorithm.crc16, 32w32768, 32w16) hashed_selector;
    direct_counter(CounterType.packets_and_bytes) hashed_counter;

    action output_hashed(port_num_t port_num) {
        output(port_num);
        hashed_counter.count();
    }

    action routing_hashed(port_num_t port_num, mac_addr_t smac, mac_addr_t dmac) {
        routing(port_num, smac, dmac);
        hashed_counter.count();
    }

    action mpls_routing_hashed(port_num_t port_num, mac_addr_t smac, mac_addr_t dmac,
                               mpls_label_t label) {
        mpls_routing(port_num, smac, dmac, label);
        hashed_counter.count();
    }

    table hashed {
        key = {
            fabric_metadata.next_id: exact @name("next_id");
            hdr.ipv4.dst_addr: selector;
            hdr.ipv4.src_addr: selector;
            fabric_metadata.ip_proto: selector;
            fabric_metadata.l4_sport: selector;
            fabric_metadata.l4_dport: selector;
        }
        actions = {
            output_hashed;
            routing_hashed;
            mpls_routing_hashed;
            @defaultonly nop;
        }
        implementation = hashed_selector;
        counters = hashed_counter;
        const default_action = nop();
        size = 2048;
    }


    /*
     * Multicast
     * Maps next IDs to PRE multicat group IDs.
     */
    direct_counter(CounterType.packets_and_bytes) multicast_counter;

    action set_mcast_group_id(mcast_group_id_t group_id) {
        standard_metadata.mcast_grp = group_id;
        fabric_metadata.is_multicast = 1w1;
        multicast_counter.count();
    }

    table multicast {
        key = {
            fabric_metadata.next_id: exact @name("next_id");
        }
        actions = {
            set_mcast_group_id;
            @defaultonly nop;
        }
        counters = multicast_counter;
        const default_action = nop();
        size = 2048;
    }

    apply {

        // xconnect might set a new next_id.
        xconnect.apply();





        hashed.apply();

        multicast.apply();
        next_vlan.apply();
    }
}

control EgressNextControl (inout parsed_headers_t hdr,
                           inout fabric_metadata_t fabric_metadata,
                           inout standard_metadata_t standard_metadata) {
    @hidden
    action pop_mpls_if_present() {
        hdr.mpls.setInvalid();
        // Assuming there's an IP header after the MPLS one.
        fabric_metadata.eth_type = fabric_metadata.ip_eth_type;
    }

    @hidden
    action set_mpls() {
        hdr.mpls.setValid();
        hdr.mpls.label = fabric_metadata.mpls_label;
        hdr.mpls.tc = 3w0;
        hdr.mpls.bos = 1w1; // BOS = TRUE
        hdr.mpls.ttl = fabric_metadata.mpls_ttl; // Decrement after push.
        fabric_metadata.eth_type = ETHERTYPE_MPLS;
    }

    @hidden
    action push_vlan() {
        // If VLAN is already valid, we overwrite it with a potentially new VLAN
        // ID, and same CFI, PRI, and eth_type values found in ingress.
        hdr.vlan_tag.setValid();
        hdr.vlan_tag.cfi = fabric_metadata.vlan_cfi;
        hdr.vlan_tag.pri = fabric_metadata.vlan_pri;
        hdr.vlan_tag.eth_type = fabric_metadata.eth_type;
        hdr.vlan_tag.vlan_id = fabric_metadata.vlan_id;
        hdr.ethernet.eth_type = ETHERTYPE_VLAN;
    }

    /*
     * Egress VLAN Table.
     * Pops the VLAN tag if the pair egress port and VLAN ID is matched.
     */
    direct_counter(CounterType.packets_and_bytes) egress_vlan_counter;

    action pop_vlan() {
        hdr.ethernet.eth_type = fabric_metadata.eth_type;
        hdr.vlan_tag.setInvalid();
        egress_vlan_counter.count();
    }

    table egress_vlan {
        key = {
            fabric_metadata.vlan_id: exact @name("vlan_id");
            standard_metadata.egress_port: exact @name("eg_port");
        }
        actions = {
            pop_vlan;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = egress_vlan_counter;
        size = 2048;
    }

    apply {
        if (fabric_metadata.is_multicast == 1w1
             && standard_metadata.ingress_port == standard_metadata.egress_port) {
            mark_to_drop();
        }

        if (fabric_metadata.mpls_label == 0) {
            if (hdr.mpls.isValid()) pop_mpls_if_present();
        } else {
            set_mpls();
        }

        if (!egress_vlan.apply().hit) {
            // Push VLAN tag if not the default one.
            if (fabric_metadata.vlan_id != DEFAULT_VLAN_ID) {
                push_vlan();
            }
        }

        // TTL decrement and check.
        if (hdr.mpls.isValid()) {
            hdr.mpls.ttl = hdr.mpls.ttl - 1;
            if (hdr.mpls.ttl == 0) mark_to_drop();
        } else {
            if(hdr.ipv4.isValid()) {
                hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
                if (hdr.ipv4.ttl == 0) mark_to_drop();
            }






        }
    }
}
# 25 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/packetio.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/../header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 18 "/media/sf_onos/pipelines/fabric/src/main/resources/include/control/packetio.p4" 2

control PacketIoIngress(inout parsed_headers_t hdr,
                        inout fabric_metadata_t fabric_metadata,
                        inout standard_metadata_t standard_metadata) {

    apply {
        if (hdr.packet_out.isValid()) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            hdr.packet_out.setInvalid();
            fabric_metadata.is_controller_packet_out = 1w1;
            // No need for ingress processing, straight to egress.
            exit;
        }
    }
}

control PacketIoEgress(inout parsed_headers_t hdr,
                       inout fabric_metadata_t fabric_metadata,
                       inout standard_metadata_t standard_metadata) {

    apply {
        if (fabric_metadata.is_controller_packet_out == 1w1) {
            // Transmit right away.
            exit;
        }
        if (standard_metadata.egress_port == 192) {
            if (fabric_metadata.is_multicast == 1w1 &&
                fabric_metadata.clone_to_cpu == 1w0) {
                // Is multicast but clone was not requested.
                mark_to_drop();
            }
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = standard_metadata.ingress_port;
            // No need to process through the rest of the pipeline.
            exit;
        }
    }
}
# 26 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/header.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 27 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/checksum.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 24 "/media/sf_onos/pipelines/fabric/src/main/resources/include/checksum.p4"
control FabricComputeChecksum(inout parsed_headers_t hdr,
                              inout fabric_metadata_t meta)
{
    apply {
        update_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );




    }
}

control FabricVerifyChecksum(inout parsed_headers_t hdr,
                             inout fabric_metadata_t meta)
{
    apply {
        verify_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );
    }
}
# 28 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/parser.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/media/sf_onos/pipelines/fabric/src/main/resources/include/define.p4" 1
/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "/media/sf_onos/pipelines/fabric/src/main/resources/include/parser.p4" 2

parser FabricParser (packet_in packet,
                     out parsed_headers_t hdr,
                     inout fabric_metadata_t fabric_metadata,
                     inout standard_metadata_t standard_metadata) {

    bit<6> last_ipv4_dscp = 0;

    state start {
        transition select(standard_metadata.ingress_port) {
            192: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        fabric_metadata.eth_type = hdr.ethernet.eth_type;
        fabric_metadata.vlan_id = DEFAULT_VLAN_ID;
        transition select(hdr.ethernet.eth_type){
            ETHERTYPE_VLAN: parse_vlan_tag;
            ETHERTYPE_MPLS: parse_mpls;
            ETHERTYPE_IPV4: parse_ipv4;



            default: accept;
        }
    }

    state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.eth_type){
            ETHERTYPE_IPV4: parse_ipv4;



            ETHERTYPE_MPLS: parse_mpls;

            ETHERTYPE_VLAN: parse_inner_vlan_tag;

            default: accept;
        }
    }


    state parse_inner_vlan_tag {
        packet.extract(hdr.inner_vlan_tag);
        transition select(hdr.inner_vlan_tag.eth_type){
            ETHERTYPE_IPV4: parse_ipv4;



            ETHERTYPE_MPLS: parse_mpls;
            default: accept;
        }
    }


    state parse_mpls {
        packet.extract(hdr.mpls);
        fabric_metadata.mpls_label = hdr.mpls.label;
        fabric_metadata.mpls_ttl = hdr.mpls.ttl;
        // There is only one MPLS label for this fabric.
        // Assume header after MPLS header is IPv4/IPv6
        // Lookup first 4 bits for version
        transition select(packet.lookahead<bit<4>>()) {
            //The packet should be either IPv4 or IPv6.
            4: parse_ipv4;



            default: parse_ethernet;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        fabric_metadata.ip_proto = hdr.ipv4.protocol;
        fabric_metadata.ip_eth_type = ETHERTYPE_IPV4;
        last_ipv4_dscp = hdr.ipv4.dscp;
        //Need header verification?
        transition select(hdr.ipv4.protocol) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }
# 130 "/media/sf_onos/pipelines/fabric/src/main/resources/include/parser.p4"
    state parse_tcp {
        packet.extract(hdr.tcp);
        fabric_metadata.l4_sport = hdr.tcp.sport;
        fabric_metadata.l4_dport = hdr.tcp.dport;



        transition accept;

    }

    state parse_udp {
        packet.extract(hdr.udp);
        fabric_metadata.l4_sport = hdr.udp.sport;
        fabric_metadata.l4_dport = hdr.udp.dport;
        transition select(hdr.udp.dport) {






            default: accept;

        }
    }

    state parse_icmp {
        packet.extract(hdr.icmp);
        transition accept;
    }
# 241 "/media/sf_onos/pipelines/fabric/src/main/resources/include/parser.p4"
}

control FabricDeparser(packet_out packet,in parsed_headers_t hdr) {

    apply {
        packet.emit(hdr.packet_in);






        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);

        packet.emit(hdr.inner_vlan_tag);

        packet.emit(hdr.mpls);





        packet.emit(hdr.ipv4);



        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.icmp);
# 289 "/media/sf_onos/pipelines/fabric/src/main/resources/include/parser.p4"
    }
}
# 29 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4" 2
# 42 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4"
control FabricIngress (inout parsed_headers_t hdr,
                       inout fabric_metadata_t fabric_metadata,
                       inout standard_metadata_t standard_metadata) {

    PacketIoIngress() pkt_io_ingress;
    Filtering() filtering;
    Forwarding() forwarding;
    Acl() acl;
    Next() next;




    apply {





        pkt_io_ingress.apply(hdr, fabric_metadata, standard_metadata);
        filtering.apply(hdr, fabric_metadata, standard_metadata);




        if (fabric_metadata.skip_forwarding == 1w0) {
            forwarding.apply(hdr, fabric_metadata, standard_metadata);
        }
        acl.apply(hdr, fabric_metadata, standard_metadata);
        if (fabric_metadata.skip_next == 1w0) {
            next.apply(hdr, fabric_metadata, standard_metadata);
# 81 "/media/sf_onos/pipelines/fabric/src/main/resources/fabric.p4"
        }
    }
}

control FabricEgress (inout parsed_headers_t hdr,
                      inout fabric_metadata_t fabric_metadata,
                      inout standard_metadata_t standard_metadata) {

    PacketIoEgress() pkt_io_egress;
    EgressNextControl() egress_next;

    apply {

        pkt_io_egress.apply(hdr, fabric_metadata, standard_metadata);
        egress_next.apply(hdr, fabric_metadata, standard_metadata);







    }
}

V1Switch(
    FabricParser(),
    FabricVerifyChecksum(),
    FabricIngress(),
    FabricEgress(),
    FabricComputeChecksum(),
    FabricDeparser()
) main;
# 56 "fabric-tofino.p4" 2
