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
#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#ifndef BMV2TOFINO
#include <tofino/stateful_alu_blackbox.p4>
#endif
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        prio      : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header ethernet_t ethernet;
header vlan_tag_t vlan_tag;
header ipv4_t ipv4;

header_type metadata_t {
    fields {
        prio      : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}
metadata metadata_t m;

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_TPID 0x8100

parser start {
    extract(ethernet);
    set_metadata(m.etherType, ethernet.etherType);
    return select(ethernet.etherType) {
        ETHERTYPE_TPID: parse_vlan_tag;
        ETHERTYPE_IPV4: parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag);
    set_metadata(m.etherType, vlan_tag.etherType);
    return select(vlan_tag.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default        : ingress;
    }
}
parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action _drop() {
    drop();
}

action _nop() {
}

action assign_vlan(prio, cfi, vid) {
    modify_field(m.prio, prio);
    modify_field(m.cfi,  cfi);
    modify_field(m.vid,  vid);
}

action_profile vlan_profile {
    actions {
        assign_vlan;
    }
    size : 2048;
}

table subnet_based_vlan {
    reads {
        ipv4.srcAddr : lpm;
    }
    action_profile : vlan_profile;
    size : 4096;
}

table mac_based_vlan {
    reads {
        ethernet.srcAddr : exact;
    }
    action_profile : vlan_profile;
    size : 16384;
}

table protocol_based_vlan {
    reads {
        m.etherType : exact;
    }
    action_profile : vlan_profile;
    size : 1024;
}

table port_based_vlan {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    action_profile : vlan_profile;
    size : 512;
}

action do_set_vlan_tag() {
    add_header(vlan_tag);
    modify_field(vlan_tag.prio, m.prio);
    modify_field(vlan_tag.cfi,  m.cfi);
    modify_field(vlan_tag.vid,  m.vid);
    modify_field(vlan_tag.etherType, m.etherType);
}

table set_vlan_tag {
    actions {
        do_set_vlan_tag;
    }
    default_action : do_set_vlan_tag;
    size : 1;
}

action do_set_vid() {
    modify_field(vlan_tag.vid,  m.vid);
}

table set_vid {
    actions {
        do_set_vid;
    }
    default_action : do_set_vid;
    size : 1;
}

action do_forward(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table forward {
    actions {
        do_forward;
    }
    default_action : do_forward(1);
    size : 1;
}

control ingress {
    if ((not valid(vlan_tag)) or (vlan_tag.vid == 0)) {
        apply(subnet_based_vlan) {
            miss {
                apply(mac_based_vlan) {
                    miss {
                        apply(protocol_based_vlan) {
                            miss {
                                apply(port_based_vlan);
                            }
                        }
                    }
                }
            }
        }
    }

    if (not valid(vlan_tag)) {
        apply(set_vlan_tag);
    } else if (vlan_tag.vid == 0) {
        apply(set_vid);
    }

    apply(forward);
}

control egress {
}
