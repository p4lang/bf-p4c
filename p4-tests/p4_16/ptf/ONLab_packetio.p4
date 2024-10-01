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

#include <core.p4>
#include <v1model.p4>

#ifndef CPU_PORT
#define CPU_PORT 320
#endif

typedef bit<9> PortId;

// ---------------------- HEADERS ----------------------
@controller_header("packet_in")
header packet_in_header_t {
    PortId ingress_port;
    bit<7> _padding0;
}

@not_extracted_in_egress
@controller_header("packet_out")
header packet_out_header_t {
    PortId egress_port;
    bit<7> _padding0;
}

struct metadata_t {
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct headers_t {
    ethernet_t ethernet;
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
}

// -------------------- PARSER ------------------------

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                    inout standard_metadata_t standard_metadata) {

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }

    state start {
        transition select(standard_metadata.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }
}

// ------------------- CONTROLS ------------------

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    action send_to_cpu() {
        standard_metadata.egress_spec = CPU_PORT;
    }
    
    action set_egress_port(PortId port) {
        standard_metadata.egress_spec = port;
    }

    table table0 {
        /*
        Disabling timeout here as P4runtime doesn't allow setting timeouts.
        This way the FlowRuleTranslator will produce instances of PiTableEntry without timeout.
        */
        support_timeout = false;
        key = {
            standard_metadata.ingress_port : ternary;
            hdr.ethernet.dstAddr           : ternary;
            hdr.ethernet.srcAddr           : ternary;
            hdr.ethernet.etherType         : ternary;
        }
        actions = {
            set_egress_port();
            send_to_cpu();
        }
        default_action = send_to_cpu();
    }

    apply {
        if (hdr.packet_out.isValid()) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
        }
        else {
            table0.apply();
        }
    }
}

control PacketIoEgressControl(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    apply {
        hdr.packet_out.setInvalid();
        if (standard_metadata.egress_port == CPU_PORT) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = standard_metadata.ingress_port;
        }
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    PacketIoEgressControl() packet_io_egress_control;
    apply {
        packet_io_egress_control.apply(hdr, standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        // Nothing to do
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        // Nothing to do
    }
}
V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
