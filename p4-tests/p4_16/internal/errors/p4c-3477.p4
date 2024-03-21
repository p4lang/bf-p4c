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

header hdr1_t {
    bit<32> data;
    bit<16> csum;
}

struct headers_t {
    hdr1_t hdr1;
}

struct my_metadata_t {
}

parser SwitchIngressParser(packet_in packet,
    out headers_t hdr,
    out my_metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
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
    }
}

control SwitchIngressDeparser(packet_out packet,
    inout headers_t hdr,
    in my_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    Checksum() csum;
    bit<16> local_var;

    apply {
        hdr.hdr1.csum = csum.update({ // expect error: "Invalid local variable entry in checksum calculation"
            local_var
        });

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
