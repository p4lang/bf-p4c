/*
* Copyright 2020-present Nehal Baganal
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <core.p4>
#include <tna.p4>   /* TOFINO1_ONLY */

enum bit<16> ether_type_t {
    IPV4 = 0x0800
}

enum bit<8> ip_proto_t {
    TCP = 6
}

header ethernet_h {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  diffserv;
    bit<2>  ECN;
    bit<16> total_len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<1> CWR;
    bit<1> ECE;
    bit<1> URG;
    bit<1> ACK;
    bit<1> PSH;
    bit<1> RST;
    bit<1> SYN;
    bit<1> FIN;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header tcp_opt_h {
    bit<32> data;
}

header some_payload_h {
    bit<16> data;
}

typedef tcp_opt_h[10] tcp_opt_t;

header my_tstamp_t {
    bit<8> ece_flag; //To indicate that payload has ECE timestamp
    bit<8> cwr_flag; //To indicate that payload has CWR timestamp
    bit<16> cwr_tstamp_high;
    bit<32> cwr_tstamp_low;
    bit<16> ece_tstamp_high;
    bit<32> ece_tstamp_low;
    bit<32> queue_delay;
}

struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    tcp_opt_h[10] tcp_opt;
    my_tstamp_t my_tstamp;
    some_payload_h some_payload;
}

struct my_metadata_t {
    bit<16> tcp_payload_checksum;
}

parser SwitchIngressParser(packet_in packet,
    out headers_t hdr,
    out my_metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    Checksum() tcp_checksum;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        meta.tcp_payload_checksum = 0;
        transition parse_ethernet;
    }

    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ether_type_t.IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        tcp_checksum.subtract({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                8w0, hdr.ipv4.protocol
            });
        transition parse_tcp;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        tcp_checksum.subtract({
                hdr.tcp.src_port,
                hdr.tcp.dst_port,
                hdr.tcp.seq_no,
                hdr.tcp.ack_no,
                hdr.tcp.data_offset,
                hdr.tcp.res,
                hdr.tcp.CWR,
                hdr.tcp.ECE,
                hdr.tcp.URG,
                hdr.tcp.ACK,
                hdr.tcp.PSH,
                hdr.tcp.RST,
                hdr.tcp.SYN,
                hdr.tcp.FIN,
                hdr.tcp.window,
                hdr.tcp.checksum,
                hdr.tcp.urgent_ptr
            });

        transition select(hdr.tcp.data_offset){
            4w0x5: parse_tcp_no_opt;
            4w0x6: parse_tcp_opt_32b;
            4w0x7: parse_tcp_opt_64b;
            4w0x8: parse_tcp_opt_96b;
            4w0x9: parse_tcp_opt_128b;
            4w0xA: parse_tcp_opt_160b;
            4w0xB: parse_tcp_opt_192b;
            4w0xC: parse_tcp_opt_224b;
            4w0xD: parse_tcp_opt_256b;
            4w0xE: parse_tcp_opt_288b;
            4w0xF: parse_tcp_opt_320b;
            default: accept;
        }
    }

    state parse_tcp_no_opt {
        transition parse_decide_payload;
    }

    state parse_tcp_opt_32b {
        packet.extract(hdr.tcp_opt[0]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_64b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_96b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_128b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_160b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_192b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data,
                hdr.tcp_opt[5].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_224b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data,
                hdr.tcp_opt[5].data,
                hdr.tcp_opt[6].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_256b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data,
                hdr.tcp_opt[5].data,
                hdr.tcp_opt[6].data,
                hdr.tcp_opt[7].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_288b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data,
                hdr.tcp_opt[5].data,
                hdr.tcp_opt[6].data,
                hdr.tcp_opt[7].data,
                hdr.tcp_opt[8].data
            });
        transition parse_decide_payload;
    }

    state parse_tcp_opt_320b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        packet.extract(hdr.tcp_opt[9]);
        tcp_checksum.subtract({
                hdr.tcp_opt[0].data,
                hdr.tcp_opt[1].data,
                hdr.tcp_opt[2].data,
                hdr.tcp_opt[3].data,
                hdr.tcp_opt[4].data,
                hdr.tcp_opt[5].data,
                hdr.tcp_opt[6].data,
                hdr.tcp_opt[7].data,
                hdr.tcp_opt[8].data,
                hdr.tcp_opt[9].data
            });
        transition parse_decide_payload;
    }

    state parse_decide_payload {
        transition select(ig_intr_md.ingress_port){
            0 : parse_payload;
            1 : parse_some_payload;
            2 : parse_get_before_some_payload; 
            _ : parse_no_payload;
        }
    }

    state parse_no_payload {
        // This previously needed a subtract in this state
        meta.tcp_payload_checksum = tcp_checksum.get();
        transition accept;
    }

    state parse_some_payload {
        // This previously needed a subtract in this state
        packet.extract(hdr.some_payload);
        // In this case some_payload is not subtracted!!!
        meta.tcp_payload_checksum = tcp_checksum.get();
        transition accept;
    }

    state parse_get_before_some_payload {
        // This previously needed a subtract in this state
        meta.tcp_payload_checksum = tcp_checksum.get();
        packet.extract(hdr.some_payload);
        transition accept;
    }

    state parse_payload {
        packet.extract(hdr.my_tstamp);
        tcp_checksum.subtract({
                hdr.my_tstamp.cwr_flag,
                hdr.my_tstamp.ece_flag,
                hdr.my_tstamp.cwr_tstamp_high,
                hdr.my_tstamp.cwr_tstamp_low,
                hdr.my_tstamp.ece_tstamp_high,
                hdr.my_tstamp.ece_tstamp_low,
                hdr.my_tstamp.queue_delay
            });
        meta.tcp_payload_checksum = tcp_checksum.get();
        transition accept;
    }
}


control SwitchIngress(
    inout headers_t hdr,
    inout my_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_parser_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
{
    apply{
        if (hdr.tcp.isValid())
            hdr.tcp.urgent_ptr = 16w0x1100;
        if (hdr.tcp_opt[0].isValid())
            hdr.tcp_opt[0].data = 32w0x01000100;
        if (hdr.tcp_opt[1].isValid())
            hdr.tcp_opt[1].data = 32w0x02000200;
        if (hdr.tcp_opt[2].isValid())
            hdr.tcp_opt[2].data = 32w0x03000300;
        if (hdr.tcp_opt[3].isValid())
            hdr.tcp_opt[3].data = 32w0x04000400;
        if (hdr.tcp_opt[4].isValid())
            hdr.tcp_opt[4].data = 32w0x05000500;
        if (hdr.tcp_opt[5].isValid())
            hdr.tcp_opt[5].data = 32w0x06000600;
        if (hdr.tcp_opt[6].isValid())
            hdr.tcp_opt[6].data = 32w0x07000700;
        if (hdr.tcp_opt[7].isValid())
            hdr.tcp_opt[7].data = 32w0x08000800;
        if (hdr.tcp_opt[8].isValid())
            hdr.tcp_opt[8].data = 32w0x09000900;
        if (hdr.tcp_opt[9].isValid())
            hdr.tcp_opt[9].data = 32w0x0A000A00;
        if (hdr.my_tstamp.isValid())
            hdr.my_tstamp.cwr_tstamp_high = 16w0x0022;
        if (hdr.some_payload.isValid())
            hdr.some_payload.data = 16w0x0506;
        ig_intr_tm_md.ucast_egress_port = 2;
    }
}

control SwitchIngressDeparser(packet_out packet,
    inout headers_t hdr,
    in my_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    Checksum() tcp_checksum;

    apply {
        if (hdr.tcp.isValid()) {
            hdr.tcp.checksum = tcp_checksum.update({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    8w0,
                    hdr.ipv4.protocol,

                    hdr.tcp.src_port,
                    hdr.tcp.dst_port,
                    hdr.tcp.seq_no,
                    hdr.tcp.ack_no,
                    hdr.tcp.data_offset,
                    hdr.tcp.res,
                    hdr.tcp.CWR,
                    hdr.tcp.ECE,
                    hdr.tcp.URG,
                    hdr.tcp.ACK,
                    hdr.tcp.PSH,
                    hdr.tcp.RST,
                    hdr.tcp.SYN,
                    hdr.tcp.FIN,
                    hdr.tcp.window,
                    hdr.tcp.urgent_ptr,

                    hdr.tcp_opt[0].data,
                    hdr.tcp_opt[1].data,
                    hdr.tcp_opt[2].data,
                    hdr.tcp_opt[3].data,
                    hdr.tcp_opt[4].data,
                    hdr.tcp_opt[5].data,
                    hdr.tcp_opt[6].data,
                    hdr.tcp_opt[7].data,
                    hdr.tcp_opt[8].data,
                    hdr.tcp_opt[9].data,

                    hdr.some_payload.data,

                    hdr.my_tstamp.cwr_flag,
                    hdr.my_tstamp.ece_flag,
                    hdr.my_tstamp.cwr_tstamp_high,
                    hdr.my_tstamp.cwr_tstamp_low,
                    hdr.my_tstamp.ece_tstamp_high,
                    hdr.my_tstamp.ece_tstamp_low,
                    hdr.my_tstamp.queue_delay,

                    meta.tcp_payload_checksum
                });
        }

        packet.emit(hdr);
    }
}

parser SwitchEgressParser(
	packet_in pkt,
    out headers_t hdr,
	out my_metadata_t meta,
	out egress_intrinsic_metadata_t eg_intr_md
)
{
	/* This is a mandatory state, required by Tofino Architecture */
	state start {
		pkt.extract(eg_intr_md);
		transition accept;
	}
}

control SwitchEgress(
    inout headers_t hdr,
    inout my_metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_parser_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    apply {
    }
}

control SwitchEgressDeparser(packet_out packet,
    inout headers_t hdr,
    in my_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        packet.emit(hdr);
    }
}

Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
