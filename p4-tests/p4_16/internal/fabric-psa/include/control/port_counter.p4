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

#ifndef __PORT_COUNTER__
#define __PORT_COUNTER__
#include "../define.p4"
#include "../header.p4"

control PortCountersControl(inout parsed_headers_t hdr,
    inout fabric_metadata_t fabric_metadata,
    in psa_ingress_input_metadata_t istd,
    inout psa_ingress_output_metadata_t ostd) {

    Counter<bit<32>, bit<32>>(MAX_PORTS, PSA_CounterType_t.PACKETS_AND_BYTES) egress_port_counter;
    Counter<bit<32>, bit<32>>(MAX_PORTS, PSA_CounterType_t.PACKETS_AND_BYTES) ingress_port_counter;

    apply {
        if (ostd.egress_port < MAX_PORTS) {
            egress_port_counter.count((bit<32>)ostd.egress_port);
        }
        if (istd.ingress_port < MAX_PORTS) {
            ingress_port_counter.count((bit<32>)istd.ingress_port);
        }
    }
}
#endif
