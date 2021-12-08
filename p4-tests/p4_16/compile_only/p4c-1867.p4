# 1 "int_demo.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "int_demo.p4"
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

#include "core.p4"
#include "tna.p4"

# 24 "int_demo.p4" 2

typedef PortId_t port_t;

# 1 "constants.p4" 1
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




/* indicate INT by UDP/TCP destination port */
const bit<16> L4_INT_PORT = 0x4242;
# 28 "int_demo.p4" 2

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




/*
 * IEEE Std 802.1Q-2018, section 9.6
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
# 28 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 2

header ethernet_h {
    ether_addr_t daddr;
    ether_addr_t saddr;
    ethertype_t type;
}

header vlan_h {
    bit<3> pcp; // Priority Code Point (section 6.9.3)
    bit<1> dei; // Drop Eligible Indicator (section 6.9.3)
    bit<12> vid;
    ethertype_t type;
}
# 30 "int_demo.p4" 2
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
# 31 "int_demo.p4" 2
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
# 32 "int_demo.p4" 2
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
# 33 "int_demo.p4" 2
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
# 34 "int_demo.p4" 2
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
    bit<8> int_type; /* INT header type */
    bit<8> rsvd1; /* Reserved */
    bit<8> len; /* Total length of INT Metadata, INT Stack */
                            /* and Shim Header in 4-byte words */
    bit<6> dscp; /* Original IP DSCP value (optional) */
    bit<2> rsvd2; /* Reserved */
}

/* INT header */
/* 16 instruction bits are defined in four 4b fields to allow concurrent */
/* lookups of the bits without listing 2^16 combinations */
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
# 35 "int_demo.p4" 2

header bridged_metadata_h {
    bit<7> padding;
    port_t ingress_port;
    bit<48> ingress_timestamp;
}

# 1 "metadata.p4" 1
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




/* switch internal variables for INT logic implementation */
struct int_metadata_t {
    bit<32> switch_id;
    bit<16> length;
    bit<16> insert_word_cnt;
    bit<16> insert_byte_cnt;
    bit<8> int_hdr_word_len;
}

struct egress_metadata_t {
    port_t ingress_port;
    bit<48> ingress_timestamp; // arrival at ingress MAC
    bit<48> egress_timestamp; // arrival at egress
    bit<16> l3_mtu;
    bit<16> old_checksum_data;
    bit<16> upper_layer_checksum;
    bit<8> next_header; // used in checksum
    int_metadata_t int_metadata;
}
# 43 "int_demo.p4" 2

// include ingress parser, control and deparser
# 1 "int_demo_ingress.p4" 1
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




struct ingress_headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
}

struct ingress_metadata_t {
}

parser ingress_parser(
        packet_in pkt,
        out ingress_headers_t hdr,
        out ingress_metadata_t ingress_metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(ingress_intrinsic_metadata);
        pkt.advance(PORT_METADATA_SIZE);
        hdr.bridged_metadata.setValid();
        hdr.bridged_metadata.ingress_port = ingress_intrinsic_metadata.ingress_port;
        hdr.bridged_metadata.ingress_timestamp = ingress_intrinsic_metadata.ingress_mac_tstamp;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control ingress_control(
        inout ingress_headers_t hdr,
        inout ingress_metadata_t ingress_metadata,
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

    apply {
        forward.apply();
    }
}

control ingress_deparser(
        packet_out pkt,
        inout ingress_headers_t hdr,
        in ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}
# 46 "int_demo.p4" 2

// include egress parser, control and deparser
# 1 "int_demo_egress.p4" 1
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




struct egress_headers_t {
    bridged_metadata_h bridged_metadata;
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

# 1 "int_outer_encap.p4" 1
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
        inout egress_headers_t hdr,
        in int_metadata_t int_metadata)
{
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.tot_length = hdr.ipv4.tot_length + int_metadata.insert_byte_cnt;
  }

        if (hdr.ipv6.isValid()) {
            hdr.ipv6.payload_len = hdr.ipv6.payload_len + int_metadata.insert_byte_cnt;
        }

        if (hdr.udp.isValid()) {
            hdr.udp.length = hdr.udp.length + int_metadata.insert_byte_cnt;
        }

        if (hdr.intl4_shim.isValid()) {
            hdr.intl4_shim.len = hdr.intl4_shim.len + int_metadata.int_hdr_word_len;
        }
    }
}
# 41 "int_demo_egress.p4" 2
# 1 "int_metadata_insert.p4" 1
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
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in int_metadata_t int_metadata,
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
            (bit<16>) egress_metadata.ingress_port;
        hdr.int_level1_port_ids.egress_port_id =
            (bit<16>) egress_intrinsic_metadata.egress_port;
    }
    action int_set_header_2() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = (bit<32>) egress_metadata.egress_timestamp - (bit<32>) egress_metadata.ingress_timestamp;
    }
    action int_set_header_3() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = (bit<8>) egress_intrinsic_metadata.egress_qid;
        hdr.int_q_occupancy.q_occupancy = (bit<24>) egress_intrinsic_metadata.enq_qdepth;
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
        const entries = {
            0: int_set_header_0003_i0();
            1: int_set_header_0003_i1();
            2: int_set_header_0003_i2();
            3: int_set_header_0003_i3();
            4: int_set_header_0003_i4();
            5: int_set_header_0003_i5();
            6: int_set_header_0003_i6();
            7: int_set_header_0003_i7();
            8: int_set_header_0003_i8();
            9: int_set_header_0003_i9();
            10: int_set_header_0003_i10();
            11: int_set_header_0003_i11();
            12: int_set_header_0003_i12();
            13: int_set_header_0003_i13();
            14: int_set_header_0003_i14();
            15: int_set_header_0003_i15();
        }
    }

    /* Similar tables can be defined for instruction bits 4-7 and bits 8-11 */
    /* e.g., int_inst_0407, int_inst_0811 */

    apply{
        int_inst_0003.apply();
        // int_inst_0407.apply();
        // int_inst_0811.apply();
    }
}
# 42 "int_demo_egress.p4" 2
# 1 "int_egress.p4" 1
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
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    action int_save_int_header_data() {
        egress_metadata.int_metadata.insert_word_cnt = (bit<16>) hdr.int_header.hop_metadata_len;
        egress_metadata.int_metadata.length = egress_metadata.l3_mtu - hdr.ipv6.payload_len;
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
        egress_metadata.int_metadata.switch_id = switch_id;
        egress_metadata.int_metadata.insert_byte_cnt =
            egress_metadata.int_metadata.insert_word_cnt << 2;
        egress_metadata.int_metadata.int_hdr_word_len =
            (bit<8>) hdr.int_header.hop_metadata_len;
        egress_metadata.l3_mtu = l3_mtu;
    }

    table int_prep {
        key = {}
        actions = {
            int_transit;
        }
        default_action = int_transit(0x42434445, 1500);
        size = 1;
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
                int_prep.apply();
                int_save_int_header_data_table.apply();
                // check MTU limit
                egress_metadata.int_metadata.length = egress_metadata.int_metadata.length -
                    egress_metadata.int_metadata.insert_byte_cnt;
                if (egress_metadata.int_metadata.length <= 0) {
                    int_mtu_limit_hit();
                } else {
                    int_hop_cnt_decrement();
                    int_metadata_insert.apply(hdr,
                                              egress_metadata,
                                              egress_metadata.int_metadata,
                                              egress_intrinsic_metadata);
                    int_outer_encap.apply(hdr, egress_metadata.int_metadata);
                }
            }
        }
    }
}
# 43 "int_demo_egress.p4" 2

parser egress_parser (
        packet_in pkt,
        out egress_headers_t hdr,
        out egress_metadata_t egress_metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    state start {
        pkt.extract(egress_intrinsic_metadata);
        pkt.extract(hdr.bridged_metadata);
        egress_metadata.ingress_port = hdr.bridged_metadata.ingress_port;
        egress_metadata.ingress_timestamp = hdr.bridged_metadata.ingress_timestamp;
        egress_metadata.egress_timestamp = 0;
        egress_metadata.next_header = 0;
        egress_metadata.l3_mtu = 0;
        egress_metadata.old_checksum_data = 0;
        egress_metadata.upper_layer_checksum = 0;
        egress_metadata.int_metadata = {0, 0, 0, 0, 0};
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x0800: parse_ipv4;
            0x86DD: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        egress_metadata.next_header = hdr.ipv4.protocol;
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        egress_metadata.next_header = hdr.ipv6.nexthdr;
        transition select(hdr.ipv6.nexthdr) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        egress_metadata.upper_layer_checksum = hdr.tcp.cksum;
        transition select(hdr.tcp.dst_port) {
            L4_INT_PORT: parse_intl4_shim;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        egress_metadata.upper_layer_checksum = hdr.udp.cksum;
        transition select(hdr.udp.dst_port) {
            L4_INT_PORT: parse_intl4_shim;
            default: accept;
        }
    }

    state parse_intl4_shim {
        pkt.extract(hdr.intl4_shim);
        transition parse_int_header;
    }

    state parse_int_header {
        pkt.extract(hdr.int_header);
        transition accept;
    }
}

control egress_control (
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    int_egress_control() int_egress;
    int_metadata_insert_control() int_metadata_insert;

    apply {
        bit<16> hword_1 = 0;
        bit<16> hword_2 = 0;
        bit<16> hword_3 = 0;

        hword_1[15:8] = hdr.intl4_shim.len;
        hword_1[7:2] = hdr.intl4_shim.dscp;
        hword_1[1:0] = hdr.intl4_shim.rsvd2;
        egress_metadata.old_checksum_data = hword_1;
            /*
            hdr.int_header.ver,
            hdr.int_header.rep,
            hdr.int_header.c,
            hdr.int_header.e,
            hdr.int_header.m,
            hdr.int_header.rsvd1,
            hdr.int_header.rsvd2,
            hdr.int_header.hop_metadata_len,
            hdr.int_header.remaining_hop_cnt
            */
        egress_metadata.egress_timestamp = egress_intrinsic_metadata_from_parser.global_tstamp;
        int_egress.apply(hdr, egress_metadata, egress_intrinsic_metadata);
        int_metadata_insert.apply(hdr, egress_metadata, egress_metadata.int_metadata, egress_intrinsic_metadata);
        hdr.bridged_metadata.setInvalid();
        if (hdr.tcp.isValid()) {
            hdr.tcp.cksum = egress_metadata.upper_layer_checksum;
        } else if (hdr.udp.isValid()) {
            hdr.udp.cksum = egress_metadata.upper_layer_checksum;
        }
    }
}

control egress_deparser (
        packet_out pkt,
        inout egress_headers_t hdr,
        in egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    Checksum() ipv4_checksum;
    Checksum() checksum;

    apply {
        bit<16> tmp;
        bit<16> hword_1 = 0;

        if (hdr.ipv4.isValid()) {
            hdr.ipv4.cksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.ds,
                hdr.ipv4.tot_length,
                hdr.ipv4.id,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.saddr,
                hdr.ipv4.daddr
            });
        }
        checksum.subtract({
            egress_metadata.old_checksum_data
        });
        hword_1[15:8] = hdr.intl4_shim.len;
        hword_1[7:2] = hdr.intl4_shim.dscp;
        hword_1[1:0] = hdr.intl4_shim.rsvd2;
        checksum.add({
            hword_1
        });
        pkt.emit(hdr);
    }
}
# 49 "int_demo.p4" 2

Pipeline(
    ingress_parser(),
    ingress_control(),
    ingress_deparser(),
    egress_parser(),
    egress_control(),
    egress_deparser()
) pipe;

Switch(pipe) main;
