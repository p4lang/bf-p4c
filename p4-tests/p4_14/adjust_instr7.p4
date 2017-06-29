
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
        read : 16;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        h4 : 16;
        t1 : 26;
        x1 : 2;
        x2 : 2;
        x3 : 2;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action bitmasked_full(param1, param2) {
    modify_field(data.t1, param1);
    modify_field(data.x2, param2);
}

action all_bytes(byte1, byte2, byte3, byte4) {
    modify_field(data.b1, byte1);
    modify_field(data.b2, byte2);
    modify_field(data.b3, byte3);
    modify_field(data.b4, byte4);
}

action some_halves(half1, half2) {
    modify_field(data.h1, half1);
    modify_field(data.h2, half2);
}

action bitmasked_full2(param1, param2) {
    modify_field(data.t1, param1);
    modify_field(data.x2, param2);
}

action all_halves(half1, half2, half3, half4) {
    modify_field(data.h1, half1);
    modify_field(data.h2, half2);
    modify_field(data.h3, half3);
    modify_field(data.h4, half4);
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.read : exact;
    }
    actions {
         bitmasked_full;
         all_bytes;
         some_halves;
    }
}

table test2 {
    reads {
        data.read : exact;
    }
    actions {
        bitmasked_full2;
        all_halves;
    }
}

table port_setter {
    reads {
        data.read : exact;
    }
    actions {
        setport;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(port_setter);
}
