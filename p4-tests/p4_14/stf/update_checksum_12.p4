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
        cksum : 16;
    }
}

header_type meta_t {
    fields {
        a : 1;
        b : 1;
        padding : 6;
    }
}

header data_t foo;
header data_t bar;
header data_t pat;
header meta_t meta;

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
    update foo_cksum if (meta.a == 1);
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
    update bar_cksum if (meta.b == 1);
}

parser start {
    set_metadata(standard_metadata.egress_spec, 0x1);
    extract(foo);
    return parse_bar;
}

parser parse_bar {
    extract(bar);
    return parse_pat;
}

parser parse_pat {
    extract(pat);
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
    modify_field(meta.a, 1);
    modify_field(meta.b, 1);
}

action set_foo_cond() {
    modify_field(meta.a, 1);
}

table test2 {
    reads {
        bar.f1 : exact;
    }
    actions {
        set_bar_f1;
        set_foo_cond;
        noop;
    }
}

control ingress {
    apply(test1);
}

control egress {
    apply(test2);
}
