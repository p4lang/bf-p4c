#define CASE_FIX_1

# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4"
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

/*
 * Code taken from:
 * https://github.com/p4lang/p4-applications/blob/master/telemetry/specs/INT.mdk
 */

typedef bit<9> port_t;

#include "core.p4"
#include "tna.p4"

# 26 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2

# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/tofino_parsers.p4" 1
parser tofino_ingress_hdr_parser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(ingress_intrinsic_metadata);
        transition select(ingress_intrinsic_metadata.resubmit_flag) {
            1: resubmit_parser;
            0: port_metadata_parser;
        }
    }

    state resubmit_parser {
        transition reject;
    }

    state port_metadata_parser {



        pkt.advance(64);

        transition accept;
    }
}

parser tofino_egress_hdr_parser(
        packet_in pkt,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata) {

    state start {
        pkt.extract(egress_intrinsic_metadata);
        transition accept;
    }
}
# 28 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




typedef bit<48> ether_addr_t;
typedef bit<16> ethertype_t;

# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ethertypes.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




/*
 * https://www.iana.org/assignments/ieee-802-numbers/ *                ieee-802-numbers.xhtml#ieee-802-numbers-1
1
 */
# 24 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 2

header ethernet_h {
    ether_addr_t daddr;
    ether_addr_t saddr;
    ethertype_t type;
}

header vlan_h {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    ethertype_t type;
}
# 29 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv4.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/protocols.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

/*
 * https://www.iana.org/assignments/protocol-numbers/ *                      protocol-numbers.xhtml
l
 */
# 21 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv4.p4" 2

/*
 * STD 5 / RFC 791: Internet Protocol, September 1981
 * RFC 2474: Definition of the Differentiated Services Field (DS Field)
 *           in the IPv4 and IPv6 Headers, December 1998
 * RFC 3168: The Addition of Explicit Congestion Notification (ECN) to IP,
 *           September 2001
 * RFC 4301: Security Architecture for the Internet Protocol, December 2005
 * RFC 6040: Tunnelling of Explicit Congestion Notification, November 2010
 * RFC 7619: The NULL Authentication Method in the
 *           Internet Key Exchange Protocol Version 2 (IKEv2), August 2015
 * RFC 8311: Relaxing Restrictions on Explicit Congestion Notification (ECN)
 *           Experimentation, January 2018:
 * RFC 6864: Updated Specification of the IPv4 ID Field, February 2013
 */

typedef bit<32> ipv4_addr_t;

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> ds;
    bit<16> tot_length;
    bit<16> id;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> cksum;
    ipv4_addr_t saddr;
    ipv4_addr_t daddr;
}
# 30 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv6.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/protocols.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

/*
 * https://www.iana.org/assignments/protocol-numbers/ *                      protocol-numbers.xhtml
l
 */
# 21 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv6.p4" 2

/*
 * RFC 8200: Internet Protocol, Version 6 (IPv6) Specification, July 2017
 */

typedef bit<128> ipv6_addr_t;

header ipv6_h {
    bit<4> version;
    bit<6> dscp;
    bit<2> ecn;
    bit<20> flowlabel;
    bit<16> payload_len;
    bit<8> nexthdr;
    bit<8> hoplimit;
    ipv6_addr_t saddr;
    ipv6_addr_t daddr;
}

// RFC 8200, section 4, IPv6 Extension Headers
header ipv6_ext_hdr_h {
    bit<8> nexthdr;
    bit<8> length;
}

// RFC 8200, section 4.2, Options
header ipv6_options_h {
    bit<8> type;
    bit<8> length;
}

// RFC 8200, section 4.4, Routing Header
header ipv6_routing_hdr_h {
    bit<8> type;
    bit<8> segments_left;
}

// RFC 8200, section 4.5, Fragment Header
header ipv6_fragment_hdr_h {
    bit<13> fragment_offset;
    bit<2> reserved;
    bit<1> more_fragments;
    bit<32> id;
}
# 31 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/tcp.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




/*
 * STD 7 / RFC 793: Transmission Control Protocol, September 1981
 * RFC 3168: The Addition of Explicit Congestion Notification (ECN) to IP,
 *           September 2001
 */

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_nr;
    bit<32> ack_nr;
    bit<4> data_offset;
    bit<4> reserved;
    bit<1> cwr_flag;
    bit<1> ece_flag;
    bit<1> urg_flag;
    bit<1> ack_flag;
    bit<1> psh_flag;
    bit<1> rst_flag;
    bit<1> syn_flag;
    bit<1> fin_flag;
    bit<16> window;
    bit<16> cksum;
    bit<16> urgent_ptr;
}
# 32 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/udp.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




/*
 * STD 6 / RFC 768: User Datagram Protocol, August 1980
 */

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> cksum;
}
# 33 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/int.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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




/*
 * https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf
 */

/* INT shim header for TCP/UDP */
header intl4_shim_h {
    bit<8> int_type;
    bit<8> rsvd1;
    bit<8> len;
    bit<6> dscp;
    bit<2> rsvd2;
}

/* INT header */
/* 16 instruction bits are defined in four 4b fields to allow concurrent
   lookups of the bits without listing 2^16 combinations */
header int_header_h {
    bit<4> ver; /* Version (1 for this version) */
    bit<2> rep; /* Replication requested */
    bit<1> c; /* Copy */
    bit<1> e; /* Max Hop Count exceeded */
    bit<1> m; /* MTU exceeded */
    bit<7> rsvd1; /* Reserved */
    bit<3> rsvd2; /* Reserved */
    bit<5> hop_metadata_len; /* Per-hop Metadata Length */
                                        /* in 4-byte words */
    bit<8> remaining_hop_cnt; /* Remaining Hop Count */
    bit<4> instruction_mask_0003; /* Instruction bitmap bits 0-3 */
    bit<4> instruction_mask_0407; /* Instruction bitmap bits 4-7 */
    bit<4> instruction_mask_0811; /* Instruction bitmap bits 8-11 */
    bit<4> instruction_mask_1215; /* Instruction bitmap bits 12-15 */
    bit<16> rsvd3; /* Reserved */
}

/* INT meta-value headers - different header for each value type */
header int_switch_id_h {
    bit<32> switch_id;
}

header int_level1_port_ids_h {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_h {
    bit<32> hop_latency;
}

header int_q_occupancy_h {
    bit<8> q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_h {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_h {
    bit<32> egress_tstamp;
}

header int_level2_port_ids_h {
    bit<32> ingress_port_id;
    bit<32> egress_port_id;
}

header int_egress_port_tx_util_h {
    bit<32> egress_port_tx_util;
}

header int_b_occupancy_h {
    bit<8> b_id;
    bit<24> b_occupancy;
}
# 34 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2

struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    intl4_shim_h intl4_shim;
    int_header_h int_header;
    int_switch_id_h int_switch_id;
    int_level1_port_ids_h int_level1_port_ids;
    int_hop_latency_h int_hop_latency;
    int_q_occupancy_h int_q_occupancy;
    int_ingress_tstamp_h int_ingress_tstamp;
    int_egress_tstamp_h int_egress_tstamp;
    int_level2_port_ids_h int_level2_port_ids;
    int_egress_port_tx_util_h int_egress_port_tx_util;
    int_b_occupancy_h int_b_occupancy;
}

/* port id and timestamp types are defined in PSA */
struct bridged_ingress_input_metadata_t {
    port_t ingress_port;
    bit<48> ingress_timestamp;
}

/* switch internal variables for INT logic implementation */
struct int_metadata_t {
    bit<32> switch_id;
    bit<16> insert_word_cnt;
    bit<16> insert_byte_cnt;
    bit<8> int_hdr_word_len;
}

struct fwd_metadata_t {
    bit<16> l3_mtu;
    bit<16> checksum_state;
}

struct metadata_t {
    bridged_ingress_input_metadata_t bridged_istd;
    int_metadata_t int_metadata;
    fwd_metadata_t fwd_metadata;
}

# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_ingress.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

control int_ingress_control(
        inout metadata_t metadata,
        in ingress_intrinsic_metadata_t ingress_intrinsic_metadata)
{
    action bridge_ingress_istd() {
        metadata.bridged_istd.ingress_port = ingress_intrinsic_metadata.ingress_port;
        metadata.bridged_istd.ingress_timestamp = ingress_intrinsic_metadata.ingress_mac_tstamp;
    }

    apply {
        bridge_ingress_istd();
    }
}
# 80 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_outer_encap.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

control int_outer_encap_control(
        inout headers_t hdr,
        in int_metadata_t int_metadata)
{
    apply {
        /*
        if (hdr.ipv6.isValid()) {
            hdr.ipv6.payload_len = hdr.ipv6.payload_len + int_metadata.insert_byte_cnt;
        }
        */
        /* Add: UDP length update if you support UDP */

        /*
        if (hdr.intl4_shim.isValid()) {
            hdr.intl4_shim.len = hdr.intl4_shim.len + int_metadata.int_hdr_word_len;
        }
        */
    }
}
# 81 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_metadata_insert.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

control int_metadata_insert_control(
        inout headers_t hdr,
        in int_metadata_t int_metadata,
        in bridged_ingress_input_metadata_t bridged_istd,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    /* this reference implementation covers only INT instructions 0-3 */
    action int_set_header_0() {
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = int_metadata.switch_id;
    }
    action int_set_header_1() {
        hdr.int_level1_port_ids.setValid();
        hdr.int_level1_port_ids.ingress_port_id =
            (bit<16>) bridged_istd.ingress_port;
        hdr.int_level1_port_ids.egress_port_id =
            (bit<16>) egress_intrinsic_metadata.egress_port;
    }
    action int_set_header_2() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency =
            (bit<32>) ((bit<48>)egress_intrinsic_metadata.enq_tstamp - bridged_istd.ingress_timestamp);
    }
    action int_set_header_3() {
        hdr.int_q_occupancy.setValid();
        // PSA doesn't support queueing metadata yet
        hdr.int_q_occupancy.q_id = 0xFF;
        hdr.int_q_occupancy.q_occupancy = 0xFFFFFF;
    }

    /* action functions for bits 0-3 combinations, 0 is msb, 3 is lsb */
    /* Each bit set indicates that corresponding INT header should be added */
    action int_set_header_0003_i0() {
    }
    action int_set_header_0003_i1() {
        int_set_header_3();
    }
    action int_set_header_0003_i2() {
        int_set_header_2();
    }
    action int_set_header_0003_i3() {
        int_set_header_3();
        int_set_header_2();
    }
    action int_set_header_0003_i4() {
        int_set_header_1();
    }
    action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
    }
    action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i8() {
        int_set_header_0();
    }
    action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
    }
    action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i11() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }

    /* Table to process instruction bits 0-3 */
    table int_inst_0003 {
        key = {
            hdr.int_header.instruction_mask_0003 : exact;
        }
        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
        }
        default_action = int_set_header_0003_i0();
        size = 16;
    }

    /* Similar tables can be defined for instruction bits 4-7 and bits 8-11 */
    /* e.g., int_inst_0407, int_inst_0811 */

    apply{
        int_inst_0003.apply();
        // int_inst_0407.apply();
        // int_inst_0811.apply();
    }
}
# 82 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_egress.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
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

control int_egress_control(
        inout headers_t hdr,
        inout metadata_t metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    action int_save_int_header_data() {
        metadata.int_metadata.insert_word_cnt = (bit<16>) hdr.int_header.hop_metadata_len;
    }

    table int_save_int_header_data_table {
        actions = {
            int_save_int_header_data;
        }
        default_action = int_save_int_header_data;
        size = 1;
    }

    action int_hop_cnt_exceeded() {
        hdr.int_header.e = 1;
    }

    action int_mtu_limit_hit() {
        hdr.int_header.m = 1;
    }

    action int_hop_cnt_decrement() {
        hdr.int_header.remaining_hop_cnt =
            hdr.int_header.remaining_hop_cnt - 1;
    }

    action int_transit(bit<32> switch_id, bit<16> l3_mtu) {
        metadata.int_metadata.switch_id = switch_id;
        metadata.int_metadata.insert_byte_cnt =
            metadata.int_metadata.insert_word_cnt << 2;
        metadata.int_metadata.int_hdr_word_len =
            (bit<8>) hdr.int_header.hop_metadata_len;
        metadata.fwd_metadata.l3_mtu = l3_mtu;
    }

    table int_prep {
        key = {}
        actions = {
            int_transit;
        }
    }

    int_metadata_insert_control() int_metadata_insert;
    int_outer_encap_control() int_outer_encap;

    apply {
        if (hdr.int_header.isValid()) {
            if (hdr.int_header.remaining_hop_cnt == 0
                    || (hdr.int_header.e == 1)) {
                int_hop_cnt_exceeded();
            } else if ((hdr.int_header.instruction_mask_0811 == 0) &&
                        (hdr.int_header.instruction_mask_1215[3:3] == 0)) {
                /* v1.0 spec allows two options for handling unsupported
                 * INT instructions. This exmple code skips the entire
                 * hop if any unsupported bit (bit 8 to 14 in v1.0 spec) is set.
                 */
                int_save_int_header_data_table.apply();
                int_prep.apply();
                // check MTU limit
#ifndef CASE_FIX_1
                if (hdr.ipv6.payload_len + metadata.int_metadata.insert_byte_cnt
                        > metadata.fwd_metadata.l3_mtu) {
                    int_mtu_limit_hit();
                } else {
#endif
                    int_hop_cnt_decrement();
                    int_metadata_insert.apply(hdr,
                                              metadata.int_metadata,
                                              metadata.bridged_istd,
                                              egress_intrinsic_metadata);
                    int_outer_encap.apply(hdr, metadata.int_metadata);
#ifndef CASE_FIX_1
                }
#endif
            }
        }
    }
}
# 83 "/home/rvdp/github.com/rvdpdotorg/P4playground/P4_16/int_demo/p4src/int_demo.p4" 2

parser ingress_parser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    tofino_ingress_hdr_parser() tofino_ingress_parser;

    state start {
        tofino_ingress_parser.apply(pkt, ingress_intrinsic_metadata);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x0800: parse_ipv4;
            0x86DD: parse_ipv6;
            default: reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

control ingress_control(
        inout headers_t hdr,
        inout metadata_t metadata,
        in ingress_intrinsic_metadata_t ingress_intrinsic_metadata,
        in ingress_intrinsic_metadata_from_parser_t
            ingress_intrinsic_metadata_from_parser,
        inout ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser,
        inout ingress_intrinsic_metadata_for_tm_t
            ingress_intrinsic_metadata_for_tm)
{
    action send_to(port_t port) {
        ingress_intrinsic_metadata_for_tm.ucast_egress_port = port;
    }

    table forward {
        key = {
            hdr.ethernet.daddr: exact;
        }
        actions = {
            send_to;
        }
        size = 32;
    }

    int_ingress_control() int_ingress;

    apply {
        int_ingress.apply(metadata, ingress_intrinsic_metadata);
        forward.apply();
    }
}

control ingress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
    }
}

/* indicate INT by DSCP value */
const bit<6> DSCP_INT = 0x17;
const bit<6> DSCP_MASK = 0x3F;

parser egress_parser<H, M>(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{

    tofino_egress_hdr_parser() tofino_egress_parser;

    state start {
        tofino_egress_parser.apply(pkt, egress_intrinsic_metadata);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x0800: parse_ipv4;
            0x86DD: parse_ipv6;
            default: reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.ipv6.dscp) {
            DSCP_INT &&& DSCP_MASK: parse_intl4_shim;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.ipv6.dscp) {
            DSCP_INT &&& DSCP_MASK: parse_intl4_shim;
            default: accept;
        }
    }

    /* INT headers are parsed first time at egress,
     * hence subtract INT header fields from checksum
     * for incremental update
     */
    state parse_intl4_shim {
        pkt.extract(hdr.intl4_shim);
        /*
        ck.subtract({
                hdr.intl4_shim.int_type, hdr.intl4_shim.rsvd1,
                hdr.intl4_shim.len, hdr.intl4_shim.dscp, hdr.intl4_shim.rsvd2
            });
        */
        transition parse_int_header;
    }

    state parse_int_header {
        pkt.extract(hdr.int_header);
        /*
        ck.subtract({
            hdr.int_header.ver, hdr.int_header.rep,
            hdr.int_header.c, hdr.int_header.e,
            hdr.int_header.m, hdr.int_header.rsvd1,
            hdr.int_header.rsvd2, hdr.int_header.hop_metadata_len,
            hdr.int_header.remaining_hop_cnt,
            hdr.int_header.instruction_mask_0003,
            hdr.int_header.instruction_mask_0407,
            hdr.int_header.instruction_mask_0811,
            hdr.int_header.instruction_mask_1215,
            hdr.int_header.rsvd3
        });
        meta.fwd_metadata.checksum_state = ck.get_state();
        */
        transition accept;
    }
}

control egress_control<H, M>(
        inout headers_t hdr,
        inout metadata_t metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    int_egress_control() int_egress;
    // int_outer_encap_control() int_outer_encap;
    // int_metadata_insert_control() int_metadata_insert;

    apply {
        int_egress.apply(hdr, metadata, egress_intrinsic_metadata);
    }
}

control egress_deparser<H, M>(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    // InternetChecksum() ck;
    apply {
        /*
        if (hdr.ipv4.isValid()) {
            ck.clear();
            ck.add({
                hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.dscp, hdr.ipv4.ecn,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags, hdr.ipv4.fragOffset,
                hdr.ipv4.ttl, hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            });
            hdr.ipv4.hdrChecksum = ck.get();
        }
        */

        // TCP/UDP header incremental checksum update.
        // Restore the checksum state partially calculated in the parser.
        // ck.set_state(meta.fwd_metadata.checksum_state);

        // Add back relevant header fields, including new INT metadata
        /*
        if (hdr.ipv4.isValid()) {
            ck.add({
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.totalLen
            });
        }

        if (hdr.intl4_shim.isValid()) {
            ck.add({
                    hdr.intl4_shim.int_type, hdr.intl4_shim.rsvd1,
                    hdr.intl4_shim.len, hdr.intl4_shim.dscp, hdr.intl4_shim.rsvd2
                });
        }

        if (hdr.int_header.isValid()) {
            ck.add({
                    hdr.int_header.ver, hdr.int_header.rep,
                    hdr.int_header.c, hdr.int_header.e,
                    hdr.int_header.m, hdr.int_header.rsvd1,
                    hdr.int_header.rsvd2, hdr.int_header.hop_metadata_len,
                    hdr.int_header.remaining_hop_cnt,
                    hdr.int_header.instruction_mask_0003,
                    hdr.int_header.instruction_mask_0407,
                    hdr.int_header.instruction_mask_0811,
                    hdr.int_header.instruction_mask_1215,
                    hdr.int_header.rsvd3
                });
        }

        if (hdr.int_switch_id.isValid()) {
            ck.add({hdr.int_switch_id.switch_id});
        }

        if (hdr.int_level1_port_ids.isValid()) {
            ck.add({
                    hdr.int_level1_port_ids.ingress_port_id,
                    hdr.int_level1_port_ids.egress_port_id
                });
        }

        if (hdr.int_hop_latency.isValid()) {
            ck.add({hdr.int_hop_latency.hop_latency});
        }

        if (hdr.int_q_occupancy.isValid()) {
            ck.add({
                    hdr.int_q_occupancy.q_id,
                    hdr.int_q_occupancy.q_occupancy
                });
        }

        if (hdr.int_ingress_tstamp.isValid()) {
            ck.add({hdr.int_ingress_tstamp.ingress_tstamp});
        }

        if (hdr.int_egress_tstamp.isValid()) {
            ck.add({hdr.int_egress_tstamp.egress_tstamp});
        }

        if (hdr.int_level2_port_ids.isValid()) {
            ck.add({
                    hdr.int_level2_port_ids.ingress_port_id,
                    hdr.int_level2_port_ids.egress_port_id
                });
        }

        if (hdr.int_egress_port_tx_util.isValid()) {
            ck.add({hdr.int_egress_port_tx_util.egress_port_tx_util});
        }

        if (hdr.int_b_occupancy.isValid()) {
            ck.add({
                hdr.int_b_occupancy.b_id,
                    hdr.int_b_occupancy.b_occupancy
                });
        }
        if (hdr.tcp.isValid()) {
            ck.add({
                hdr.tcp.srcPort,
                hdr.tcp.dstPort,
                hdr.tcp.seqNo,
                hdr.tcp.ackNo,
                hdr.tcp.dataOffset, hdr.tcp.res,
                hdr.tcp.flags,
                hdr.tcp.window,
                hdr.tcp.urgentPtr
            });
            hdr.tcp.checksum = ck.get();
        }

        if (hdr.udp.isValid()) {
            ck.add({
                hdr.udp.srcPort,
                hdr.udp.dstPort,
                hdr.udp.length_
            });

            // If hdr.udp.checksum was received as 0, we
            // should never change it.  If the calculated checksum is
            // 0, send all 1 bits instead.
            if (hdr.udp.checksum != 0) {
                hdr.udp.checksum = ck.get();
                if (hdr.udp.checksum == 0) {
                    hdr.udp.checksum = 0xffff;
                }
            }
        }
        */

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.intl4_shim);
        pkt.emit(hdr.int_header);
        pkt.emit(hdr.int_switch_id);
        pkt.emit(hdr.int_level1_port_ids);
        pkt.emit(hdr.int_hop_latency);
        pkt.emit(hdr.int_q_occupancy);
        pkt.emit(hdr.int_ingress_tstamp);
        pkt.emit(hdr.int_egress_tstamp);
        pkt.emit(hdr.int_level2_port_ids);
        pkt.emit(hdr.int_egress_port_tx_util);
        pkt.emit(hdr.int_b_occupancy);
    }
}

Pipeline(
    ingress_parser(),
    ingress_control(),
    ingress_deparser(),
    egress_parser<headers_t, metadata_t>(),
    egress_control<headers_t, metadata_t>(),
    egress_deparser<headers_t, metadata_t>()
) pipe;

Switch(pipe) main;
