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

/** This a test that currently fails in Brig as it requires more than 8 unshared full word 
 *  regions on the action data bus, a task which currently cannot be handled by Brig until
 *  a later PR
 */
header_type data_t {
    fields {
       read : 32;
       x1 : 128;
       x2 : 128;
       extra : 32;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action bigwrite(big1, big2, ex_param) {
    modify_field(data.x1, big1);
    modify_field(data.x2, big2);
    modify_field(data.extra, ex_param);
}

table test1 {
    reads {
        data.read : exact;
    }
    actions {
        bigwrite;
    }
}

control ingress {
    apply(test1);
}
