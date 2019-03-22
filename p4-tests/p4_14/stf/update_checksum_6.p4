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
        b1 : 8;
        f1 : 32;
        f2 : 32;
        cksum : 16;
    }
}

header_type load1_t {
    fields { 
        h1 : 16;
        f1 : 32;
        f2 : 32;
    }
}

header_type load2_t {
    fields {
        h1 : 16;
        f1 : 32;
    }
}

header_type load3_t {
    fields {
        b1 : 8;
    }
}

header data_t data;
header load1_t load1;
header load2_t load2;
header load3_t load3;

field_list my_checksum_list {
    data.f1;
    data.f2;
    payload;
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
    return select(latest.b1) {
        0x80 : parse_load1;
        0xaa : parse_load2;
        default : ingress;
    }
}

parser parse_load1 {
    extract(load1);
    return parse_load3;
}

parser parse_load2 {
    extract(load2);
    return parse_load3;
}

parser parse_load3 {
    extract(load3);
    return ingress;
}

action noop() { }
action set_data_f1(val, port) {
    modify_field(data.f1, val);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        set_data_f1;
        noop;
    }
}

action remove_load1() {
    remove_header(load1);
}

action remove_load2() {
    remove_header(load2);
}

table test2 {
    reads {
        load3.b1 : exact; 
    }
    actions {
        remove_load1;
        remove_load2;
        noop;
    }
}

control ingress {
    apply(test1);
}

control egress {
    if (valid(load3)) {
        apply(test2);
    }
}
