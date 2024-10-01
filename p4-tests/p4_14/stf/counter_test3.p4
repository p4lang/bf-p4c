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
#include <tofino/intrinsic_metadata.p4>

// force these into their own containers to prevent PHV conflicts between the tables
@pragma pa_container_size ingress data.c3 16
@pragma pa_container_size ingress data.c4 16

header_type data_t {
    fields {
       f1 : 32;
       f2 : 32;
       c1 : 16;
       c2 : 16;
       c3 : 16;
       c4 : 16;
       c5 : 16;
       c6 : 16;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action c1_3(val1, val2, val3) {
    modify_field(data.c1, val1);
    modify_field(data.c2, val2);
    modify_field(data.c3, val3);
}

action c4_6(val4, val5, val6, port) {
    modify_field(data.c4, val4);
    modify_field(data.c5, val5);
    modify_field(data.c6, val6);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        c1_3;
    }
    size: 512;
}

table test2 {
    reads {
        data.f2 : ternary;
    }
    actions {
        c4_6;    
    }
    size: 512;
}

counter cnt {
    type: packets;
    direct: test1;
}

counter cnt2 {
    type: packets;
    direct: test2;
}

control ingress {
    if ((data.c1 & 1) == 0) {
        apply(test1);
    }
    if ((data.f1 & 0x80) == 0) {
        apply(test2);
    }
}
