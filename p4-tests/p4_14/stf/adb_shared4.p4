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

/** This P4 program tests the renaming of the action data format in the table, to test whether
 *  they coordinate throughout the action data bus, and within each action format of the table.
 */

header_type data_t {
    fields {
       read : 32;
       c1 : 8;
       c2 : 8;
       c3 : 8;
       c4 : 8;
       c5 : 8;
       c6 : 8;
       h1 : 16;
       h2 : 16;
       h3 : 16;
       f1 : 32;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action first(byte1, byte2, byte3, byte4, byte5, byte6, half3) {
    modify_field(data.c1, byte1);
    modify_field(data.c2, byte2);
    modify_field(data.c3, byte3);
    modify_field(data.c4, byte4);
    modify_field(data.c5, byte5);
    modify_field(data.c6, byte6);
    modify_field(data.h3, half3);
}

action second(half1, half2, half3) {
    modify_field(data.h1, half1);
    modify_field(data.h2, half2);
    modify_field(data.h3, half3);
}

action third(byte1, byte2, half1, full1) {
    modify_field(data.c1, byte1);
    modify_field(data.c2, byte2);
    modify_field(data.h1, half1);
    modify_field(data.f1, full1);
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
       data.read : exact;
    }
    actions {
        first;
        second;
        third;
    }
}

table setting_port {
    reads {
        data.read : exact;
    }
    actions {
        setport;
    }
}

control ingress {
    apply(test1);
    apply(setting_port);
}
