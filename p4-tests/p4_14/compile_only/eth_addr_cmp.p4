/*
Copyright 2016-present Barefoot Networks, Inc.

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

#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr_hi : 24;
        dstAddr_lo : 24;
        srcAddr_hi : 24;
        srcAddr_lo : 24;
        etherType : 16;
    }
}


header ethernet_t ethernet;

parser start {
    extract(ethernet);
    return ingress;
}

header_type md_t {
    fields {
      src_addr      : 48;
      dst_addr      : 48;
      is_equal      : 1;
    }
}

metadata md_t md;

action addr_compare(is_equal, port) {
    modify_field(md.is_equal, is_equal);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}


table addr_compare_success {
    actions {
        addr_compare;
    }
    default_action: addr_compare(1, 1);
    size: 1;
}

table addr_compare_failure {
    actions {
        addr_compare;
    }
    default_action: addr_compare(0, 2);
    size: 1;
}

/* Main control flow */
control ingress {
    if(ethernet.srcAddr_hi == ethernet.dstAddr_hi) {
       if(ethernet.srcAddr_lo == ethernet.dstAddr_lo) {
            // drop the packet if it goes where it came from
            apply(addr_compare_failure);
        } else {
            apply(addr_compare_success);
        }
    } else {
            apply(addr_compare_success);
    }
}

control egress {
}
