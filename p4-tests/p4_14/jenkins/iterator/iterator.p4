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

#include "tofino/intrinsic_metadata.p4"

action n() {}
action N(x) {modify_field(ig_intr_md_for_tm.rid, x);}

table p0 {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {N;}
  size: 288;
}
table exm {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {n;}
}
table tcam {
  reads {
    ig_intr_md.ingress_port : ternary;
  }
  actions {n;}
}
@pragma use_hash_action 1
table ha {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {n;}
  default_action : n();
  size: 512;
}
counter ha_cntr {
  type: packets;
  direct: ha;
}

@pragma alpm 1
table alpm {
  reads {
    ig_intr_md.ingress_port : lpm;
  }
  actions {n;}
}

parser start {
  return ingress;
}
control ingress {
  if (0 == ig_intr_md.resubmit_flag) {
    apply(p0);
  }
  apply(exm);
  apply(tcam);
  apply(ha);
  apply(alpm);
}
