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
        b1 : 32;
        b2 : 32;
        f1 : 32;
        f2 : 32;
        f7 : 32;
        f8 : 32;
        f9 : 32;
        f10 : 32;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action setb1(val, port) {
    modify_field(data.b1, val);
}

action setb2(val) {
    modify_field(data.b2, val);
}

action setf1(val) {
    modify_field(data.f1, val);
}

action setf2(val) {
    modify_field(data.f2, val);
}
action setf7(val) {
    modify_field(data.f7, val);
}
action setf8(val) {
    modify_field(data.f8, val);
}
action setf9(val) {
    modify_field(data.f9, val);
}
action setf10(val) {
    modify_field(data.f10, val);
}

action noop() {

}


table t1 {
    reads {
        data.f2 : exact;
    }
    actions {
        noop;
    }
    size : 8192;
}

table t2 {
    reads {
        data.b1 : exact;
    }
    actions {
        setb1;
        noop;
    }
    size : 8192;
}

table t7 {
    reads {
        data.b1 : exact;
    }
    actions {
        setb1;
    }
}

table t8 {
    reads {
        data.f2 : exact;
    }
    actions {
        setb1;
    }
}

table t9 {
    reads {
        data.f2 : exact;
    }
    actions {
        setb1;
    }
}

table t10 {
    reads {
        data.f2 : exact;
    }
    actions {
        setb1;
    }
}

table t3 {
    reads {
        data.f1 : exact;
    }
    actions {
        setf7;
    }
    size : 65536;
}

table t4 {
    reads {
        data.f1 : exact;
    }
    actions {
        setf8;
    }
    size : 65536;
}

table t5 {
    reads {
        data.f1 : exact;
    }
    actions {
        setf9;
    }
    size : 105536;
}

table t6 {
    reads {
        data.f1 : exact;
    }
    actions {
        setf10;
    }
    size : 95536;
}


control ingress {
    apply(t1) {
        hit {
            apply(t2);
        }
    }

    apply(t3);
    apply(t4);
    apply(t5);
    apply(t6);

    apply(t7);
    apply(t8);
    apply(t9);
    apply(t10);
}