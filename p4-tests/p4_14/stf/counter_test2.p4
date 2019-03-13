
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
       c1 : 16;
       c2 : 16;
       c3 : 16;
       c4 : 16;
       c5 : 16;
       c6 : 16;
       c7 : 16;
       c8 : 16;
       c9 : 16;
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
    modify_field(standard_metadata.egress_spec, port);
}

action c7_9(val7, val8, val9) {
    modify_field(data.c7, val7);
    modify_field(data.c8, val8);
    modify_field(data.c9, val9);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        c1_3;
    }
    size: 16384;
}

table test2 {
    reads {
        data.f2 : exact;
    }
    actions {
        c4_6;    
    }
    size: 16384;
}

table test3 {
    reads {
        data.f3 : exact;
    }
    actions {
        c7_9;
    }
    size: 1024;
}

counter cnt {
    type: packets;
    direct: test1;
}

counter cnt2 {
    type: packets;
    direct: test2;
}

counter cnt3 {
    type: packets;
    direct: test3;
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
}
