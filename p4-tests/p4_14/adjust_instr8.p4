
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
        x1 : 2;
        x2 : 2;
        x3 : 2;
        x4 : 2;
        y1 : 4;
        y2 : 2;
        y3 : 2;
        u1 : 2;
        u2 : 2;
        u3 : 12;
        v1 : 28;
        v2 : 2;
        v3 : 2;
    }
}

@pragma pa_container_size ingress data.x1 8
@pragma pa_container_size ingress data.y1 8
@pragma pa_container_size ingress data.u1 16
@pragma pa_container_size ingress data.v1 32 

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action a1() {
    modify_field(data.x1, 0);
    modify_field(data.x2, 0);
}

action a2() {
    modify_field(data.x1, 3);
    modify_field(data.x2, 2);
    modify_field(data.x3, 0);
}

action a3() {
    modify_field(data.y1, 0xe);
    modify_field(data.y2, 0x2);
}

action a4() {
    modify_field(data.y1, 0x6);
    modify_field(data.y2, 0x1);
    modify_field(data.y3, 0x1);
}

action a5() {
    modify_field(data.u3, 0xffd);
}

action a6() {
    modify_field(data.u2, 0x3);
    modify_field(data.u3, 0xff8);
}

action a7() {
    modify_field(data.v1, 0xffffffe);
    modify_field(data.v2, 0x1);
}

table test1 {
    reads {
        data.read : exact;
    }
    actions {
        a1;
        a2;
        a3;
        a4;
        a5;
        a6;
        a7;
    }
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table set_port {
    reads {
        data.read : ternary;
    }
    actions {
        setport;
    }
}

control ingress {
    apply(test1);
    apply(set_port);
}
