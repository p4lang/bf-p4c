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


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct empty_metadata_t {
}

struct clone_i2e_data_t {
    bit<8> custom_tag;
    EthernetAddress srcAddr;
}

struct resubmit_metadata_t {
    bit<64> field1;
}

struct metadata_t {
   bit<64> field1;
   bit<8> custom_clone_id;
   bit<8> custom_tag;
   EthernetAddress srcAddr;
}

struct headers_t {
    ethernet_t       ethernet;
}

parser IngressParserImpl(packet_in pkt,
                         out headers_t hdr,
                         inout metadata_t user_meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in resubmit_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control cIngress(inout headers_t hdr,
                 inout metadata_t user_meta,
                 in    psa_ingress_input_metadata_t  istd,
                 inout psa_ingress_output_metadata_t ostd)
{
    action clone() {
        hdr.ethernet.srcAddr = 48w256;
        ostd.clone = true;
        ostd.clone_session_id = (CloneSessionId_t) 10w10;
        user_meta.custom_clone_id = 1;
    }

    action pkt_write() {
        ostd.drop = false;
        hdr.ethernet.dstAddr = 48w4;
        ostd.egress_port = (PortId_t)7;
    }
    apply {
        pkt_write();
        if (istd.packet_path != PSA_PacketPath_t.CLONE_I2E) {
            clone();
        }
    }

}

parser EgressParserImpl(packet_in buffer,
                        out headers_t hdr,
                        inout metadata_t user_meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in clone_i2e_data_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        buffer.extract(hdr.ethernet);
        transition accept;
    }
}

control cEgress(inout headers_t hdr,
                inout metadata_t user_meta,
                in    psa_egress_input_metadata_t  istd,
                inout psa_egress_output_metadata_t ostd)
{
    apply{
        if (istd.packet_path == PSA_PacketPath_t.CLONE_I2E) {
           hdr.ethernet.srcAddr = user_meta.srcAddr;
        }
    } 
}

control CommonDeparserImpl(packet_out packet,
                           inout headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

control IngressDeparserImpl(packet_out buffer,
                            out clone_i2e_data_t clone_i2e_meta,
                            out resubmit_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() cp;
    apply {
        if(psa_clone_i2e(istd)) {
            clone_i2e_meta.custom_tag = (bit<8>) meta.custom_clone_id;
            if (meta.custom_clone_id == 1) {
                clone_i2e_meta.srcAddr = 0xf;
            }
        }
        cp.apply(buffer, hdr);
    }
}

control EgressDeparserImpl(packet_out buffer,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(buffer, hdr);
    }
}

IngressPipeline(IngressParserImpl(),
                cIngress(),
                IngressDeparserImpl()) ip;

EgressPipeline(EgressParserImpl(),
               cEgress(),
               EgressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
