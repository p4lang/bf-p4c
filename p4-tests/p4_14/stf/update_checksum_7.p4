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
        b1 : 8;
        f1 : 32;
        f2 : 32;
        cksum : 16;
    }
}

header data_t foo;
header data_t bar;

field_list foo_cksum_list {
    foo.f1;
    foo.f2;
    payload;
}

field_list_calculation foo_cksum {
    input {
        foo_cksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field foo.cksum  {
    update foo_cksum;
}

field_list bar_cksum_list {
    bar.f1;
    bar.f2;
    payload;
}

field_list_calculation bar_cksum {
    input {
        bar_cksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field bar.cksum  {
    update bar_cksum;
}

parser start {
    set_metadata(standard_metadata.egress_spec, 0x1);
    extract(foo);
    return select(latest.b1)  {
        0xff: parse_bar;
        default : ingress;
    }
}

parser parse_bar {
    extract(bar);
    return ingress;
}

action noop() { }
action set_foo_f1(val) {
    modify_field(foo.f1, val);
}

table test1 {
    reads {
        foo.f1 : exact;
    }
    actions {
        set_foo_f1;
        noop;
    }
}

action set_bar_f1(val) {
    modify_field(bar.f1, val);
}

table test2 {
    reads {
        bar.f1 : exact;
    }
    actions {
        set_bar_f1;
        noop;
    }
}

control ingress {
    apply(test1);
}

control egress {
    apply(test2);
}
