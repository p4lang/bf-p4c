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

header_type load_t {
    fields { 
        f1 : 32;
        f2 : 32;
    }
}

header data_t data;
header load_t load;

field_list my_checksum_list {
    data.f1;
    data.f2;
    load.f1;
    load.f2;
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
        0x80 : parse_load;
        default : ingress;
    }
}

parser parse_load {
    extract(load);
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

action set_load_f2() {
    modify_field(load.f2, 0x05050608);
}

table test2 {
    actions {
        set_load_f2;
    }
    default_action : set_load_f2;
}

control ingress {
    apply(test1);
    if (valid(load)) {
        apply(test2);
    }
}
