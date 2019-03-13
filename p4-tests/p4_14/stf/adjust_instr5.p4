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
        f1 : 32;
        b1 : 8;
        n1 : 4;
        n2 : 4;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action constant_conversion_adt(param1, param2) {
    modify_field(data.n1, 4);
    modify_field(data.n2, param1);
    modify_field(data.f1, param2);
}

action constant_conversion_immed(param1) {
    modify_field(data.n1, 7);
    modify_field(data.n2, param1);
    modify_field(data.b1, 0xab);
}

action constant_conversion_adt2(param1) {
    modify_field(data.n1, 9);
    modify_field(data.n2, param1);
    modify_field(data.f1, 0x77777f77);
}

table test1 {
    reads {
        data.read : exact;
    }
    actions {
        constant_conversion_adt;
        constant_conversion_adt2;
    }
}

table test2 {
    reads {
        data.read : exact;
    }
    actions {
        constant_conversion_immed;
    }
}

action set_port(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table port_setter {
    reads {
        data.read : exact;
    }
    actions {
        set_port;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(port_setter);
}
