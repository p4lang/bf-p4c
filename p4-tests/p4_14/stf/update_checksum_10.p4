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
        f2 : 8;
        f3 : 8;
        f4 : 16;
        csum1 : 16;
        csum2 : 16;
        csum3 : 16;
        csum4 : 16;
    }
}

header data_t data;

field_list csum1_list {
        data.f1;
        data.f2;
}

field_list csum2_list {
        data.f3;
        data.f4;
}

field_list csum3_list {
    data.f1;
    data.f2;
    data.f3;
    data.f4;
}
field_list csum4_list {
    data.f2;
    data.f3;
    data.f4;
}
@pragma calculated_field_update_location ingress_and_egress
field_list_calculation csum1 {
    input {
        csum1_list;
    }
    algorithm : csum16;
    output_width : 16;
}
@pragma calculated_field_update_location ingress_and_egress
field_list_calculation csum2 {
    input {
        csum2_list;
    }
    algorithm : csum16;
    output_width : 16;
}
@pragma calculated_field_update_location ingress_and_egress
field_list_calculation csum3 {
    input {
        csum3_list;
    }
    algorithm : csum16;
    output_width : 16;
}
@pragma calculated_field_update_location ingress_and_egress
field_list_calculation csum4 {
    input {
        csum4_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field data.csum1  {
    update csum1;
}

calculated_field data.csum2  {
    update csum2;
}

calculated_field data.csum3  {
    update csum3;
}
calculated_field data.csum4  {
    update csum4;
}
parser start {
    set_metadata(standard_metadata.egress_spec, 0x2);
    extract(data);
    return ingress;
}

control ingress { }
