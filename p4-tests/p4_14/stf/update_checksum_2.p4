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
    update my_checksum;
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

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        setb1;
        noop;
    }
}

action modify_data() {
    modify_field(data.f1, 0x1);
    modify_field(data.f2, 0x2);
    modify_field(data.h1, 0x3);
    modify_field(data.b1, 0x4);
    modify_field(data.b2, 0x5);
}

table test2 {
    reads {
        data.f1 : exact;
    }
    actions {
        modify_data;
        noop;
    }
}

control ingress {
    apply(test1);
}

control egress {
    apply(test2);
}
