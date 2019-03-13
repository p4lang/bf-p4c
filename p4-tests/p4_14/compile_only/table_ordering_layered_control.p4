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
        f11 : 32;
        f12 : 32;
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

/* Set of table dependencies to force brig table placement to place
   tables in a suboptimal order.

   Match dependencies: t2 -> t7 -> t8 -> t9 -> t10
   Control dependencies: t1 -> t2
   Tables t3, t4, t5, and t6 do not have any dependencies but are very large.

   Because the match dependence chain for t2 is hidden by its control dependence
   on t1, all of t3 through t6 are placed first, occupying the first two stages
   and forcing the longest dependence chain to only begin at stage 2. If the chain
   starting at t2 were to be placed first, and the large tables were to be split
   across the remaining space, the number of stages used could be reduced from
   7 to 5. */


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
    size : 95536;
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

action setf12(val) {
    modify_field(data.f12, val);
}

table t11 {
    reads {
        data.f11 : exact;
    }
    actions {
        noop;
        setf12;
    }
}

table t12 {
    reads {
        data.f12 : exact;
    }
    actions {
        noop;
    }
}


control ingress {
    apply(t11) {
        hit {
            apply(t12);
            apply(t1) {
                hit {
                    apply(t2);
                }
            }
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