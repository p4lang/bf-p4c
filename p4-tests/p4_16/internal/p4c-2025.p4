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

# 1 "types.p4" 1
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




typedef PortId_t port_t;

enum bit<2> int_role_t {
    SOURCE = 0,
    TRANSIT = 1,
    SINK = 2
}
# 26 "int_demo.p4" 2
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
const bit<32> INT_PROBE_MARKER_1 = 0xFF00FF00;
const bit<32> INT_PROBE_MARKER_2 = 0xFF00FF00;

const bit<32> IPv4_ACL_TABLE_SIZE = 1024;
const bit<32> IPv6_ACL_TABLE_SIZE = 1024;
const bit<32> FORWARD_TABLE_SIZE = 1024;
# 27 "int_demo.p4" 2

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




struct ingress_metadata_t {
}

header bridged_metadata_h {
    bit<5> padding;
    int_role_t int_role;
    port_t ingress_port;
    bit<48> ingress_timestamp;
}

/* switch internal variables for INT logic implementation */
struct int_metadata_t {
    bit<32> switch_id;
    bit<16> length;
    bit<16> insert_word_cnt;
    bit<16> insert_double_word_cnt;
    bit<16> insert_byte_cnt;
    bit<8> int_hdr_word_len;
}

struct probe_marker_t {
    bit<32> marker_1;
    bit<32> marker_2;
}

struct egress_metadata_t {
    port_t ingress_port;
    bit<48> ingress_timestamp; // arrival at ingress MAC
    bit<48> egress_timestamp; // arrival at egress
    bit<16> l3_mtu;
    int_metadata_t int_metadata;
}
# 29 "int_demo.p4" 2

# 1 "ingress_parser.p4" 1
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
# 21 "ingress_parser.p4" 2
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
# 22 "ingress_parser.p4" 2
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

/* INT probe marker for TCP/UDP */
header int_probe_marker_1_h {
    bit<32> value;
}

header int_probe_marker_2_h {
    bit<32> value;
}

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
    // @padding
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
# 23 "ingress_parser.p4" 2

struct ingress_headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv6_h ipv6;
    int_probe_marker_1_h int_probe_marker_1;
    int_probe_marker_2_h int_probe_marker_2;
    intl4_shim_h intl4_shim;
    int_header_h int_header;
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
        hdr.bridged_metadata.ingress_port =
            ingress_intrinsic_metadata.ingress_port;
        hdr.bridged_metadata.ingress_timestamp =
            ingress_intrinsic_metadata.ingress_mac_tstamp;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}
# 31 "int_demo.p4" 2
# 1 "ingress_mau.p4" 1
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




control ingress_mau(
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
    action set_int_role(int_role_t role) {
        hdr.bridged_metadata.int_role = role;
    }

    table int_role {
        actions = {
            set_int_role;
        }
        size = 1;
    }

    action add_int_headers(
            bit<4> instruction_mask_0003,
            bit<4> instruction_mask_0407,
            bit<4> instruction_mask_0811,
            bit<4> instruction_mask_1215
    ) {
        hdr.int_probe_marker_1.setValid();
        hdr.int_probe_marker_1.value = INT_PROBE_MARKER_1;

        hdr.int_probe_marker_2.setValid();
        hdr.int_probe_marker_2.value = INT_PROBE_MARKER_2;

        hdr.intl4_shim.setValid();
        hdr.intl4_shim.int_type = 1;
        hdr.intl4_shim.rsvd1 = 0;
        hdr.intl4_shim.len = 8;
        hdr.intl4_shim.dscp = 0;
        hdr.intl4_shim.rsvd2 = 0;

        hdr.int_header.setValid();
        hdr.int_header.ver = 1;
        hdr.int_header.rep = 0;
        hdr.int_header.c = 0;
        hdr.int_header.e = 0;
        hdr.int_header.m = 0;
        hdr.int_header.rsvd1 = 0;
        hdr.int_header.rsvd2 = 0;
        hdr.int_header.hop_metadata_len = 0;
        hdr.int_header.remaining_hop_cnt = 255;
        hdr.int_header.instruction_mask_0003 = instruction_mask_0003;
        hdr.int_header.instruction_mask_0407 = instruction_mask_0407;
        hdr.int_header.instruction_mask_0811 = instruction_mask_0811;
        hdr.int_header.instruction_mask_1215 = instruction_mask_1215;
        hdr.int_header.rsvd3 = 0;
    }

    table int_ipv6_acl {
        key = {
            hdr.ethernet.saddr: ternary;
            hdr.ethernet.daddr: ternary;
            hdr.ipv6.saddr: ternary;
            hdr.ipv6.daddr: ternary;
            hdr.ipv6.nexthdr: exact;
        }
        actions = {
            add_int_headers;
        }
        size = IPv6_ACL_TABLE_SIZE;
    }

    action send_to(port_t port) {
        ingress_intrinsic_metadata_for_tm.ucast_egress_port = port;
    }

    action drop() {
        ingress_intrinsic_metadata_for_deparser.drop_ctl = 1;
    }

 table forward {
        key = {
            hdr.ethernet.daddr: exact;
        }
        actions = {
            send_to;
            drop;
        }
        const default_action = drop();
        size = FORWARD_TABLE_SIZE;
    }

    apply {
        int_role.apply();
        if (hdr.bridged_metadata.int_role == int_role_t.SOURCE) {
            if (hdr.ipv6.isValid()) {
                int_ipv6_acl.apply();
            }
        }
        forward.apply();
    }
}
# 32 "int_demo.p4" 2
# 1 "ingress_deparser.p4" 1
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
# 33 "int_demo.p4" 2

# 1 "egress_parser.p4" 1
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
# 21 "egress_parser.p4" 2
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
# 22 "egress_parser.p4" 2
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
# 23 "egress_parser.p4" 2

struct egress_headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv6_h ipv6;
    ipv6_ext_hdr_h ipv6_ext_hdr;
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
        egress_metadata.ingress_timestamp =
            hdr.bridged_metadata.ingress_timestamp;
        egress_metadata.egress_timestamp = 0;
        egress_metadata.l3_mtu = 0;
        egress_metadata.int_metadata = {0, 0, 0, 0, 0, 0};
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            0: parse_hop_by_hop_options;
            default: accept;
        }
    }

    state parse_hop_by_hop_options {
        pkt.extract(hdr.ipv6_ext_hdr);
        pkt.extract(hdr.int_header);
        transition accept;
    }
}
# 35 "int_demo.p4" 2
# 1 "egress_mau.p4" 1
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




# 1 "outer_encap.p4" 1
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




control outer_encap_control(
        inout egress_headers_t hdr,
        in int_metadata_t int_metadata)
{
    apply {
        if (hdr.ipv6.isValid()) {
            hdr.ipv6.payload_len =
                hdr.ipv6.payload_len + int_metadata.insert_byte_cnt;
        }

        if (hdr.ipv6_ext_hdr.isValid()) {
            hdr.ipv6_ext_hdr.length =
                hdr.ipv6_ext_hdr.length + int_metadata.insert_double_word_cnt[7:0];
        }
    }
}
# 21 "egress_mau.p4" 2
# 1 "metadata_insert.p4" 1
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




control metadata_insert_control(
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in int_metadata_t int_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
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
        hdr.int_hop_latency.hop_latency =
            (bit<32>) egress_metadata.egress_timestamp -
            (bit<32>) egress_metadata.ingress_timestamp;
    }
    action int_set_header_3() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id =
            (bit<8>) egress_intrinsic_metadata.egress_qid;
        hdr.int_q_occupancy.q_occupancy =
            (bit<24>) egress_intrinsic_metadata.enq_qdepth;
    }

    action int_set_header_4() {
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp =
            (bit<32>) egress_metadata.ingress_timestamp;
    }

    action int_set_header_5() {
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp =
            (bit<32>) egress_metadata.egress_timestamp;
    }

    action int_set_header_6() {
        hdr.int_level2_port_ids.setValid();
        hdr.int_level2_port_ids.ingress_port_id = 0; // TBD
        hdr.int_level2_port_ids.egress_port_id = 0; // TBD
    }

    action int_set_header_7() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 0; // TBD
    }

    /*
     * Action functions for bits 0-3 combinations, 0 is msb, 3 is lsb.
     * Each bit set indicates that corresponding INT header should be added.
     */
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
            hdr.int_header.instruction_mask_0003: exact;
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
            NoAction;
        }
        default_action = NoAction();
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

    /*
     * Action functions for bits 4-7 combinations, 4 is msb, 7 is lsb.
     * Each bit set indicates that corresponding INT header should be added.
     */
    action int_set_header_0407_i0() {
    }
    action int_set_header_0407_i1() {
        int_set_header_7();
    }
    action int_set_header_0407_i2() {
        int_set_header_6();
    }
    action int_set_header_0407_i3() {
        int_set_header_7();
        int_set_header_6();
    }
    action int_set_header_0407_i4() {
        int_set_header_5();
    }
    action int_set_header_0407_i5() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i6() {
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i7() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i8() {
        int_set_header_4();
    }
    action int_set_header_0407_i9() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i10() {
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i11() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i12() {
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i13() {
        int_set_header_7();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i14() {
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i15() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }

    /* Table to process instruction bits 4-7 */
    table int_inst_0407 {
        key = {
            hdr.int_header.instruction_mask_0407: exact;
        }
        actions = {
            int_set_header_0407_i0;
            int_set_header_0407_i1;
            int_set_header_0407_i2;
            int_set_header_0407_i3;
            int_set_header_0407_i4;
            int_set_header_0407_i5;
            int_set_header_0407_i6;
            int_set_header_0407_i7;
            int_set_header_0407_i8;
            int_set_header_0407_i9;
            int_set_header_0407_i10;
            int_set_header_0407_i11;
            int_set_header_0407_i12;
            int_set_header_0407_i13;
            int_set_header_0407_i14;
            int_set_header_0407_i15;
            NoAction;
        }
        default_action = NoAction();
        size = 16;
        const entries = {
            0: int_set_header_0407_i0();
            1: int_set_header_0407_i1();
            2: int_set_header_0407_i2();
            3: int_set_header_0407_i3();
            4: int_set_header_0407_i4();
            5: int_set_header_0407_i5();
            6: int_set_header_0407_i6();
            7: int_set_header_0407_i7();
            8: int_set_header_0407_i8();
            9: int_set_header_0407_i9();
            10: int_set_header_0407_i10();
            11: int_set_header_0407_i11();
            12: int_set_header_0407_i12();
            13: int_set_header_0407_i13();
            14: int_set_header_0407_i14();
            15: int_set_header_0407_i15();
        }
    }

    apply {
        int_inst_0003.apply();
        int_inst_0407.apply();
        // int_inst_0811.apply();
    }
}
# 22 "egress_mau.p4" 2

control egress_mau (
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
    metadata_insert_control() metadata_insert;
    outer_encap_control() outer_encap;

    action int_save_int_header_data() {
        egress_metadata.int_metadata.insert_word_cnt =
            (bit<16>) hdr.int_header.hop_metadata_len;
        egress_metadata.int_metadata.insert_double_word_cnt =
            (bit<16>) (hdr.int_header.hop_metadata_len >> 1);
        egress_metadata.int_metadata.length =
            egress_metadata.l3_mtu - hdr.ipv6.payload_len;
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

    apply {
        egress_metadata.egress_timestamp =
            egress_intrinsic_metadata_from_parser.global_tstamp;
        if (hdr.int_header.isValid()) {
            if (hdr.int_header.remaining_hop_cnt == 0
                    || (hdr.int_header.e == 1)) {
                int_hop_cnt_exceeded();
            } else if ((hdr.int_header.instruction_mask_0811 == 0) &&
                        (hdr.int_header.instruction_mask_1215[3:3] == 0)) {
                /* v1.0 spec allows two options for handling unsupported
                 * INT instructions. This example code skips the entire
                 * hop if any unsupported bit (bit 8 to 14 in v1.0 spec)
                 * is set.
                 */
                int_prep.apply();
                int_save_int_header_data_table.apply();
                // check MTU limit
                egress_metadata.int_metadata.length =
                    egress_metadata.int_metadata.length -
                    egress_metadata.int_metadata.insert_byte_cnt;
                if (egress_metadata.int_metadata.length <= 0) {
                    int_mtu_limit_hit();
                } else {
                    int_hop_cnt_decrement();
                    metadata_insert.apply(hdr, egress_metadata,
                        egress_metadata.int_metadata,
                        egress_intrinsic_metadata);
                    outer_encap.apply(hdr, egress_metadata.int_metadata);
                }
            }
        }
        hdr.bridged_metadata.setInvalid();
    }
}
# 36 "int_demo.p4" 2
# 1 "egress_deparser.p4" 1
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




control egress_deparser (
        packet_out pkt,
        inout egress_headers_t hdr,
        in egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}
# 37 "int_demo.p4" 2

Pipeline(
    ingress_parser(),
    ingress_mau(),
    ingress_deparser(),
    egress_parser(),
    egress_mau(),
    egress_deparser()
) pipe;

Switch(pipe) main;
