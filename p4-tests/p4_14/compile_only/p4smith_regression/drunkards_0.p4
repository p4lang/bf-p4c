/* p4smith seed: 466479512 */
#include <tofino/intrinsic_metadata.p4>
header_type ravel {
  fields {
    spaceport : 32;
    andrettis : 48;
    hyperthyroids : 32;
    archaic : 32;
    inscriber : 32;
    dioramas : 48;
  }
}

header_type snitches {
  fields {
    oass : 16;
    overwhelms : 16;
    materiels : 48;
    laddie : 16;
    superwoman : 16;
  }
}

header ravel dispatched;

header snitches repatriation;

parser start {
  return parse_dispatched;
}

parser parse_dispatched {
  extract(dispatched);
  return select (current(0, 8)) {
    168 : parse_repatriation;
  }
}

parser parse_repatriation {
  extract(repatriation);
  return ingress;
}

action lamebrains() {
  modify_field(standard_metadata.egress_spec, 1);
}

action negating(clip, mauricio) {
  modify_field(dispatched.inscriber, dispatched.hyperthyroids);
  modify_field(dispatched.spaceport, 355539228);
  bit_or(dispatched.dioramas, 1337546844, 799205952);
  bit_xor(dispatched.spaceport, dispatched.archaic, dispatched.hyperthyroids);
}

action cheyennes(caldwell) {
  add(repatriation.overwhelms, repatriation.laddie, repatriation.oass);
  copy_header(repatriation, repatriation);
}

table flapping {
  actions {
    lamebrains;
    }
  }

table banters {
  reads {
    dispatched.andrettis mask 76 : range;
    repatriation : valid;
    dispatched : valid;
  }
  actions {
    cheyennes;
    negating;
  }
}

control ingress {
  apply(flapping);
  if (not((valid(repatriation) or (3023 > 0)))) {
    apply(banters);
  }
}
