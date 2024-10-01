/*
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

#include <core.p4>
#include "psa.p4"


typedef bit<48> ethernet_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

header ethernet_t {
    ethernet_addr_t dstAddr;
    ethernet_addr_t srcAddr;
    bit<16> etherType;
}

header ipv4_t {
  bit<4> version;
  bit<4> ihl;
  bit<6> dscp;
  bit<2> ecn;
  bit<16> total_len;
  bit<16> identification;
  bit<1> reserved;
  bit<1> do_not_fragment;
  bit<1> more_fragments;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> protocol;
  bit<16> header_checksum;
  ipv4_addr_t src_addr;
  ipv4_addr_t dst_addr;
}

header ipv6_t {
  bit<4> version;
  bit<6> dscp;
  bit<2> ecn;
  bit<20> flow_label;
  bit<16> payload_length;
  bit<8> next_header;
  bit<8> hop_limit;
  ipv6_addr_t src_addr;
  ipv6_addr_t dst_addr;
}

struct empty_metadata_t {
}

struct metadata_t {
   bool isValidIpv4;
   bit<16> field1;
   PortId_t ingress_port;
   PortId_t ingress_port2;
   PSA_MeterColor_t color_value;
}

struct headers_t {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    ipv6_t      ipv6;
}

parser IngressParserImpl(packet_in pkt,
                         out headers_t headers,
                         inout metadata_t user_meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        user_meta.ingress_port = istd.ingress_port;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(headers.ethernet);
        transition select(headers.ethernet.etherType) {
          0x0800: parse_ipv4;
          0x86dd: parse_ipv6;
          _: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(headers.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(headers.ipv6);
        transition accept;
    }

}

control cIngress(inout headers_t headers,
                 inout metadata_t user_meta,
                 in    psa_ingress_input_metadata_t  istd,
                 inout psa_ingress_output_metadata_t ostd)
{
    Meter<bit<12>>(1024, PSA_MeterType_t.PACKETS) meter0;
    action create_metadata(bit<12> idx) {
        headers.ethernet.etherType = 0xFF;
        user_meta.isValidIpv4 = headers.ipv4.isValid();
        user_meta.color_value = meter0.execute(idx);
        user_meta.ingress_port2 = istd.ingress_port;
    }

    table create {
        key = {
            headers.ethernet.etherType: exact;
            user_meta.ingress_port: exact;
        }
        actions = {
            create_metadata;
        }
    }

    action check_metadata1() {
        headers.ethernet.etherType = headers.ethernet.etherType | 0xFA;
    }

    action check_metadata2() {
        headers.ethernet.etherType = headers.ethernet.etherType | 0xFB;
    }

    table check {
        key = {
            user_meta.isValidIpv4: exact;
            user_meta.color_value: exact;
        }
        actions = {
            check_metadata1;
            check_metadata2;
        }
        const entries = {
            (true , PSA_METERCOLOR_GREEN) : check_metadata1();
            (false, PSA_METERCOLOR_RED  ) : check_metadata2();
        }
    }

    apply {
        create.apply();
        check.apply();
    }
}

parser EgressParserImpl(packet_in buffer,
                        out headers_t headers,
                        inout metadata_t user_meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        buffer.extract(headers.ethernet);
        transition accept;
    }
}

control cEgress(inout headers_t headers,
                inout metadata_t user_meta,
                in    psa_egress_input_metadata_t  istd,
                inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control CommonDeparserImpl(packet_out packet,
                           inout headers_t headers)
{
    apply {
        packet.emit(headers.ethernet);
    }
}

control IngressDeparserImpl(packet_out buffer,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t headers,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(buffer, headers);
    }
}

control EgressDeparserImpl(packet_out buffer,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t headers,
                           in metadata_t meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(buffer, headers);
    }
}

IngressPipeline(IngressParserImpl(),
                cIngress(),
                IngressDeparserImpl()) ip;

EgressPipeline(EgressParserImpl(),
               cEgress(),
               EgressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
