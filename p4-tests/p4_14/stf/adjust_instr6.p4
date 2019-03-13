
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
        b2 : 8;
        x1 : 2;
        x2 : 2;
        x3 : 2;
        x4 : 2;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action bitmasked_adt(param1, param2, param3) {
    modify_field(data.x1, param1);
    modify_field(data.x3, param2);
    modify_field(data.f1, param3);
}


action bitmasked_immed(param1, param2, param3) {
    modify_field(data.x1, param1);
    modify_field(data.x3, param2);
    modify_field(data.b1, param3);
}


action bitmasked_immed2(param1, param2, param3, param4) {
    modify_field(data.x2, param1);
    modify_field(data.x4, param2);
    modify_field(data.b1, param3);
    modify_field(data.b2, param4);
}

table test1 {
    reads {
        data.read : exact;
    }
    actions {
        bitmasked_adt;
    }
}

table test2 {
    reads {
        data.read : exact;
    }
    actions {
        bitmasked_immed;
        bitmasked_immed2;
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
