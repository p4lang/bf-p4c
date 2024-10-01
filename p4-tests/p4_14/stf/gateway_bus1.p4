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
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        b5 : 8;
        b6 : 8;
        b7 : 8;
        b8 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }
action setb2_5(val2, val3, val4, val5, val6) {
    modify_field(data.b2, val2);
    modify_field(data.b3, val3);
    modify_field(data.b4, val4);
    modify_field(data.b5, val5);
    modify_field(data.b6, val6);
}
action setb1(val1, port) {
    modify_field(data.b1, val1);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.f1 : exact;
        data.f2 : exact;
        data.f3 : exact;
        data.b7 : exact;
    }
    actions {
        setb2_5;
        noop;
    }
}

table test2 {
    reads {
        data.f1 : exact;
    }
    actions {
        setb1;
        noop;
    }
}

control ingress {
    if (data.f4 == 0x00000001) {
        apply(test1);
    }
    apply(test2);
}
