/* p4smith seed: 993606253 */
#include <tofino/intrinsic_metadata.p4>
header_type casuists {
  fields {
    filmmakers : 8;
  }
}

header_type sunlights {
  fields {
    fencer : 32;
    stan : 16;
    uni : 16;
    armada : 16;
    secretariats : 16;
    whiteboards : 32;
  }
}

header casuists incinerating;

header sunlights tapered;

parser start {
  return parse_incinerating;
}

parser parse_incinerating {
  extract(incinerating);
  return select (latest.filmmakers) {
    8 : parse_tapered;
  }
}

parser parse_tapered {
  extract(tapered);
  return ingress;
}

action vacate() {
  modify_field(standard_metadata.egress_spec, 1);
}

action degeneress(domestications, lowbrows) {
  copy_header(incinerating, incinerating);
  bit_xor(tapered.fencer, 1712654547, 0);
  subtract_from_field(tapered.fencer, tapered.whiteboards);
}

action modernization() {
  subtract_from_field(tapered.whiteboards, tapered.fencer);
  add_header(tapered);
  copy_header(incinerating, incinerating);
}

table thunderhead {
  actions {
    vacate;
    }
  }

table generalized {
  reads {
    tapered : valid;
    tapered.stan : range;
  }
  actions {
    degeneress;
  }
}

table sparkler {
  reads {
    incinerating : valid;
  }
  actions {
    degeneress;
    modernization;
  }
}

control ingress {
  if ((incinerating.filmmakers > 1321)) {
    apply(thunderhead);
  }
  if (not((3225 > 0))) {
    apply(generalized);
  }
  if ((incinerating.filmmakers == incinerating.filmmakers)) {
    apply(sparkler);
  }
}
