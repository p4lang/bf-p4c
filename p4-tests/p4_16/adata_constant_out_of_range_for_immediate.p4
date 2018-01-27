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

typedef bit<9> PortId_t;

struct metadata_t { }

header h_t {
    bit<16> v;
}

struct headers_t {
    h_t h;
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                    inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.h);
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {
    apply {
        hdr.h.v = hdr.h.v - 32;
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply { }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.h);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        // Nothing to do
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
