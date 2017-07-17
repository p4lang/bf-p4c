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

// This is P4 sample source for basic_switching

#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

header_type h1_t {
    fields {
        f_20 : 20;
        f_4 : 4;
        f_16 : 16;
    }
}

header h1_t h1;

header_type meta_t {
    fields {
        f_24 : 24;
    }
}

metadata meta_t meta;

parser start {
    extract(h1);
    return ingress;
}

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

@pragma command_line --no-dead-code-elimination
table t1 {
    actions {
        set_egr;
    }
}

field_list NA_fields {
    4'0;
    h1.f_20;
}

field_list_calculation calc {
    input { NA_fields; }
    algorithm : identity;
    output_width : 24;
}

action do_hash() {
    modify_field_with_hash_based_offset(meta.f_24, 0, calc, 16777216);
}

table t2 {
    actions { do_hash; }
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress { }

