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
        f3 : 32;
        f4 : 32;
        f5 : 32;
        f6 : 32;
        cksum : 16;
    }
}

header data_t data1;
header data_t data2;

field_list data1_checksum_list {
        data1.f1;
        data1.f2;
        data1.f3;
        data1.f4;
        data1.f5;
        data1.f6;
}

field_list_calculation data1_checksum {
    input {
        data1_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

// If two back-to-back headers both have checksum update, then we cannot
// put them into same CLOT. Parser can only compute checksum per CLOT.
// Another bug for another day ...
//
//calculated_field data1.cksum  {
//    update data1_checksum;
//}

field_list data2_checksum_list {
        data2.f1;
        data2.f2;
        data2.f3;
        data2.f4;
        data2.f5;
        data2.f6;
}

field_list_calculation data2_checksum {
    input {
        data2_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field data2.cksum  {
    update data2_checksum;
}

parser start {
    extract(data1);
    extract(data2);
    return ingress;
}

action noop() { }
action modify_data1() {
    modify_field(data1.f1, 0x00000001);
    modify_field(data1.f2, 0x00000010);
    modify_field(data1.f3, 0x00000100);
    modify_field(data1.f4, 0x00001000);
    modify_field(data1.f5, 0x00010000);
    modify_field(data1.f6, 0x00100000);
}

action modify_data2() {
    modify_field(data2.f5, 0xbabebabe);
    modify_field(data2.f6, 0xfafafafa);
}

action set_port() {
    modify_field(standard_metadata.egress_spec, 0x2);
}
table set_port {
    actions {
        set_port;
    }
    default_action : set_port;
}

table test1 {
    reads {
        data1.f1 : exact;
    }
    actions {
        modify_data1;
        modify_data2;
        noop;
    }
}

control ingress {
    apply(set_port);
}

control egress {
    apply(test1);
}
