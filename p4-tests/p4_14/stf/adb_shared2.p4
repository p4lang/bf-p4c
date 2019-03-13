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

/** A second test on when the action data bus should share bytes between different BYTE/HALF,
 *  and full word sections if the section are not yet fully filled by bytes/halves, but only
 *  partially filled.
 */

header_type first_hdr_t {
    fields {
       f1 : 32;
       f2 : 32;
       c1 : 8;
       c2 : 8;
       c3 : 8;
       c4 : 8;
       h1 : 16;
       h2 : 16;
       f3 : 32;
       f4 : 32;
    }
}

header_type second_hdr_t {
    fields {
       f1 : 32;
       f2 : 32;
       c1 : 8;
       c2 : 8;
       c3 : 8;
       c4 : 8;
       h1 : 16;
       h2 : 16;
       f3 : 32;
       f4 : 32;
        
    }
}

header first_hdr_t first_hdr;
header second_hdr_t second_hdr;

parser start {
    extract(first_hdr);
    extract(second_hdr);
    return ingress;
}

action first_hdr1(byte1, byte2, byte3, half1) {
    modify_field(first_hdr.c1, byte1);
    modify_field(first_hdr.c2, byte2);
    modify_field(first_hdr.c3, byte3);
    modify_field(first_hdr.h1, half1);
}

action first_hdr2(full1, full2) {
    modify_field(first_hdr.f3, full1);
    modify_field(first_hdr.f4, full2);
}

table test1 {
    reads {
       first_hdr.f1 : exact;
    }
    actions {
        first_hdr1;
        first_hdr2;
    }
}

action second_hdr1(byte1, byte2, half1, half2) {
    modify_field(second_hdr.c1, byte1);
    modify_field(second_hdr.c2, byte2);
    modify_field(second_hdr.h1, half1);
    modify_field(second_hdr.h2, half2);
}

action second_hdr2(full1, full2) {
    modify_field(second_hdr.f3, full1);
    modify_field(second_hdr.f4, full2);
}

table test2 {
    reads {
        second_hdr.f1 : exact;
    }
    actions {
        second_hdr1;
        second_hdr2;
    }
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table setting_port {
    reads {
        first_hdr.f1 : exact;
    }
    actions {
        setport;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(setting_port);
}
