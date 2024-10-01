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

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        b1 : 8;
        b2 : 8;
        cksum : 16;
    }
}
header data_t data;

field_list my_checksum_list {
        data.f1;
        data.f2;
}

field_list_calculation my_checksum {
    input {
        my_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field data.cksum  {
    verify my_checksum;
}

parser start {
    extract(data);
    return ingress;
}

action noop() { }
action setb1(val, port) {
    modify_field(data.b1, val);
    modify_field(standard_metadata.egress_spec, port);
}
action kaput() {
    modify_field(data.f1, 0xdeaddead);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        setb1;
        noop;
    }
}

table test2 {
    actions {
        kaput;
    }
}

control ingress {
    apply(test1);
    if (ig_intr_md_from_parser_aux.ingress_parser_err & 0x1000 != 0x0) {
        apply(test2);
    }
}
