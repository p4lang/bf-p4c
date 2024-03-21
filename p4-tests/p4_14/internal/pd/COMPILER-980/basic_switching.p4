/*
Copyright 2013-present Barefoot Networks, Inc. 

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

// This is P4 sample source for basic_switching

#include "includes/headers.p4"
#include "includes/parser.p4"
#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

// Test program exceeds Tof1 egress parse depth
@pragma command_line --disable-parse-max-depth-limit

header_type nat_metadata_t {
    fields {
        ingress_nat_mode : 2;          /* 0: none, 1: inside, 2: outside */
        egress_nat_mode : 2;           /* nat mode of egress_bd */
        nat_nexthop : 16;              /* next hop from nat */
        nat_nexthop_type : 1;          /* ecmp or nexthop */
        nat_hit : 1;                   /* fwd and rewrite info from nat */
        nat_rewrite_index : 14;        /* NAT rewrite index */
        update_checksum : 1;           /* update tcp/udp checksum */
        update_udp_checksum : 1;       /* update udp checksum */
        update_tcp_checksum : 1;       /* update tcp checksum */
        update_inner_udp_checksum : 1; /* update inner udp checksum */
        update_inner_tcp_checksum : 1; /* update inner tcp checksum */
        l4_len : 16;                   /* l4 length */
    }
}

metadata nat_metadata_t nat_metadata;

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

action nop() {
}

action _drop() {
    drop();
}

table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_egr; nop;
    }
}

table acl {
    reads {
        ethernet.dstAddr : ternary;
        ethernet.srcAddr : ternary;
    }
    actions {
        nop;
        _drop;
    }
}

action remove_vxlan_udp_header() {
    copy_header(ipv4, inner_ipv4);
    copy_header(udp, inner_udp);
    copy_header(ethernet, inner_ethernet);

    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
    remove_header(inner_udp);
    remove_header(vxlan);
    modify_field(nat_metadata.update_inner_udp_checksum, 1);
    modify_field(nat_metadata.update_udp_checksum, 1);
}

table remove_vxlan {
    actions {
        remove_vxlan_udp_header;
    }
}

action set_udp_header() {
    modify_field(udp.srcPort, 0x1122);
    modify_field(nat_metadata.update_inner_udp_checksum, 1);
    modify_field(nat_metadata.update_udp_checksum, 1);
}

table set_udp {
    actions {
        set_udp_header;
    }
}
control ingress {
    apply(forward);
}

control egress {
    apply(acl);
    if (valid(vxlan)) {
        apply(remove_vxlan);
    }
    if (valid(udp)) {
        apply(set_udp);
    }
}


