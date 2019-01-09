/*
 * Copyright 2017-present Barefoot Networks Inc.
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
#include <psa.p4>

#include "include/define.p4"
#include "include/header.p4"
#include "include/parser.p4"
#include "include/control/packetio.p4"
#include "include/control/filtering.p4"
#include "include/control/forwarding.p4"
#include "include/control/next.p4"
#include "include/control/port_counter.p4"

control FabricIngress(
    inout parsed_headers_t hdr,
    inout fabric_metadata_t fabric_metadata,
    in psa_ingress_input_metadata_t istd,
    inout psa_ingress_output_metadata_t ostd)
{
    PacketIoIngress() packet_io_ingress;
    Filtering() filtering;
    Forwarding() forwarding;
    Next() next;
    PortCountersControl() port_counters_control;

    apply {
        packet_io_ingress.apply(hdr, fabric_metadata, istd, ostd);
        filtering.apply(hdr, fabric_metadata, istd, ostd);
        forwarding.apply(hdr, fabric_metadata, istd, ostd);
        next.apply(hdr, fabric_metadata, istd, ostd);
        port_counters_control.apply(hdr, fabric_metadata, istd, ostd);
    }
}

control FabricEgress(
    inout parsed_headers_t hdr,
    inout fabric_metadata_t fabric_metadata,
    in psa_egress_input_metadata_t istd,
    inout psa_egress_output_metadata_t ostd)
{
    PacketIoEgress() pkt_io_egress;
    EgressNextControl() egress_next;
    apply {
        egress_next.apply(hdr, fabric_metadata, istd, ostd);
        pkt_io_egress.apply(hdr, fabric_metadata, istd, ostd);
    }
}

IngressPipeline(
    FabricIngressParser(),
    FabricIngress(),
    FabricIngressDeparser()) ig;

EgressPipeline(
    FabricEgressParser(),
    FabricEgress(),
    FabricEgressDeparser()) eg;

PSA_Switch(ig, PacketReplicationEngine(), eg, BufferingQueueingEngine()) main;
