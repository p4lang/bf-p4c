

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

/** This P4 program tests whether or not the bytes and halves on the action data bus can
 *  potentially share locations with mutually exclusive full regions.  Based on the particular
 *  action format, bytes can specifically be shared when algined properly.
 */

header_type data_t {
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

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action first(byte1, byte2, byte3, byte4, half1, half2) {
    modify_field(data.c1, byte1);
    modify_field(data.c2, byte2);
    modify_field(data.c3, byte3);
    modify_field(data.c4, byte4);
    modify_field(data.h1, half1);
    modify_field(data.h2, half2);
}

action second(full1, full2) {
    modify_field(data.f3, full1);
    modify_field(data.f4, full2);
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
       data.f1 : exact;
    }
    actions {
        first;
        second;
    }
}

action third (byte1, byte2, half1) {
    modify_field(data.c1, byte1);
    modify_field(data.c2, byte2);
    modify_field(data.h1, half1);
}

table test2 {
    reads {
        data.f1 : exact;
    }
    actions {
        third;
    }
}

table setting_port {
    reads {
        data.f1 : exact;
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
