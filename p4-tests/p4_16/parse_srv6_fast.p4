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

typedef bit<9> port_t;

#include <core.p4>
#include <tna.p4>

header ethernet_h {
    bit<48> daddr;
    bit<48> saddr;
    bit<16>  type;
}

header ipv6_h {
    bit<4> version;
    bit<6> dscp;
    bit<2> ecn;
    bit<20> flowlabel;
    bit<16> payload_len;        // in octets
    bit<8> nexthdr;
    bit<8> hoplimit;
    bit<128> saddr;
    bit<128> daddr;
}

header ipv6_routing_hdr_h {
    bit<8> nexthdr;
    bit<8> length;          // Length of Option Data Field in octets
    bit<8> type;
    bit<8> segments_left;
}

header srv6_srh_h {
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

header srv6_sid_h {
    bit<128> sid;
}

header bridged_metadata_h {
}

struct ingress_metadata_t {
    bit<128> srv6_current_sid;
}

struct headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv6_h ipv6;
    ipv6_routing_hdr_h ipv6_routing_hdr;
    srv6_srh_h srv6_srh;
    srv6_sid_h[4] srv6_sid;
}

parser ingress_parser(
        packet_in pkt,
        out headers_t hdr,
        out ingress_metadata_t ingress_metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(ingress_intrinsic_metadata);
        pkt.advance(PORT_METADATA_SIZE);
        ingress_metadata.srv6_current_sid = 0;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86dd: parse_ipv6;
            default: reject;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            43: parse_ipv6_routing_header;
            default: accept;
        }
    }

    state parse_ipv6_routing_header {
        pkt.extract(hdr.ipv6_routing_hdr);
        transition select(hdr.ipv6_routing_hdr.type) {
            4: parse_srv6_srh;
            default: accept;
        }
    }

    state parse_srv6_srh {
        pkt.extract(hdr.srv6_srh);
        transition select(hdr.ipv6_routing_hdr.segments_left,
                hdr.srv6_srh.last_entry) {
            (0, 0): parse_srv6_sid_last_1;
            (0, 1): parse_srv6_sid_last_2;
            (0, 2): parse_srv6_sid_last_3;
            (1, _): parse_srv6_sid_first_1;
            (2, _): parse_srv6_sid_first_2;
            (3, _): parse_srv6_sid_first_3;
            default: accept;
        }
    }

    state parse_srv6_sid_last_1 {
        pkt.extract(hdr.srv6_sid.next);
        transition parse_ipv6_nexthdr;
    }

    state parse_srv6_sid_last_2 {
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        transition parse_ipv6_nexthdr;
    }

    state parse_srv6_sid_last_3 {
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        transition parse_ipv6_nexthdr;
    }

    state parse_srv6_sid_first_1 {
        pkt.extract(hdr.srv6_sid.next);
        ingress_metadata.srv6_current_sid = hdr.srv6_sid.last.sid;
        transition select(hdr.srv6_srh.last_entry) {
            0: parse_ipv6_nexthdr;
            1: parse_srv6_sid_last_1;
            2: parse_srv6_sid_last_2;
            default: accept;
        }
    }

    state parse_srv6_sid_first_2 {
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        ingress_metadata.srv6_current_sid = hdr.srv6_sid.last.sid;
        transition select(hdr.srv6_srh.last_entry) {
            1: parse_ipv6_nexthdr;
            2: parse_srv6_sid_last_1;
            default: accept;
        }
    }

    state parse_srv6_sid_first_3 {
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        pkt.extract(hdr.srv6_sid.next);
        ingress_metadata.srv6_current_sid = hdr.srv6_sid.last.sid;
        transition select(hdr.srv6_srh.last_entry) {
            2: parse_ipv6_nexthdr;
            default: accept;
        }
    }

    state parse_ipv6_nexthdr {
        transition select(hdr.ipv6_routing_hdr.nexthdr) {
            default: accept;
        }
    }
}

control validate_packet(
        inout ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_from_parser_t
            ingress_intrinsic_metadata_from_parser,
        inout ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        if (ingress_intrinsic_metadata_from_parser.parser_err != 0) {
            ingress_intrinsic_metadata_for_deparser.drop_ctl = 1;
            exit;
        }
    }
}

control ingress_mau(
        inout headers_t hdr,
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
            ingress_intrinsic_metadata.ingress_port: exact;
            ingress_metadata.srv6_current_sid: exact;
        }
        actions = {
            send_to;
        }
        size = 32;
    }

    apply {
        validate_packet.apply(ingress_metadata,
                ingress_intrinsic_metadata_from_parser,
                ingress_intrinsic_metadata_for_deparser);
        forward.apply();
    }
}

control ingress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}

struct egress_metadata_t {
}

parser egress_parser(
        packet_in pkt,
        out headers_t hdr,
        out egress_metadata_t egress_metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    state start {
        pkt.extract(egress_intrinsic_metadata);
        transition accept;
    }
}

control egress_mau(
        inout headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    apply {}
}

control egress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    apply {}
}

Pipeline(
    ingress_parser(),
    ingress_mau(),
    ingress_deparser(),
    egress_parser(),
    egress_mau(),
    egress_deparser()
) pipe;

Switch(pipe) main;
