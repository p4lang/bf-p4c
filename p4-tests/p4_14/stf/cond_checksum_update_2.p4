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
        cksum : 16;
        h1 : 16;
        b1 : 8;
        b2 : 8;
    }
}

header_type metadata_t {
    fields {
        update_checksum_0 : 1;
        update_checksum_1 : 1;
        update_checksum_2 : 1;
        padding         : 5;
    }
}

header data_t data;
metadata metadata_t meta;

field_list my_checksum_list {
        data.f1;
        data.f2;
}

@pragma calculated_field_update_location egress
field_list_calculation my_checksum {
    input {
        my_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field data.cksum  {
    update my_checksum if (meta.update_checksum_0 == 1);
    update my_checksum if (meta.update_checksum_1 == 1);
//    update my_checksum if (meta.update_checksum_2 == 1);
}

parser start {
    extract(data);
    return ingress;
}

action noop() { }

action enable_checksum_update_0() {
    modify_field(meta.update_checksum_0, 1);
}

action enable_checksum_update_1() {
    modify_field(meta.update_checksum_1, 1);
}

action setb1(val, port) {
    modify_field(data.b1, val);
    modify_field(standard_metadata.egress_spec, port);
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
    reads {
        data.f1 : exact;
    }
    actions {
        enable_checksum_update_0;
    }
}
table test3 {
    reads {
        data.f2 : exact;
    }
    actions {
        enable_checksum_update_1;
    }
}

control ingress {
    apply(test1);
}

control egress {
    apply(test2);
    apply(test3);
}

