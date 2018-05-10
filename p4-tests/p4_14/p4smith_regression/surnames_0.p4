/* p4smith seed: 829612908 */
#include <tofino/intrinsic_metadata.p4>
header_type butters {
  fields {
    slandered : 32;
    christensen : 64;
    because : 32;
  }
}

header_type flores {
  fields {
    files : 32;
  }
}

header_type disarmingly {
  fields {
    margrethes : 32;
  }
}

header_type roadsters {
  fields {
    rapiers : 8;
    pregames : 48;
    ballots : 32;
    sheepishnesss : 48;
  }
}

header butters sonorously;

header flores kunming;

header disarmingly jurors;

header roadsters scribe;

parser start {
  return parse_sonorously;
}

parser parse_sonorously {
  extract(sonorously);
  return select (current(0, 8)) {
    13 : parse_jurors;
    212 : parse_kunming;
    138 : parse_scribe;
  }
}

parser parse_kunming {
  extract(kunming);
  return select (current(0, 8)) {
    38 : parse_jurors;
  }
}

parser parse_jurors {
  extract(jurors);
  return select (current(0, 8)) {
    58 : parse_scribe;
  }
}

parser parse_scribe {
  extract(scribe);
  return ingress;
}

action nighest() {
  modify_field(standard_metadata.egress_spec, 1);
}

action fanged(torridness) {
  subtract_from_field(sonorously.slandered, 9);
}

table bouts {
  actions {
    nighest;
    }
  }

table mvps {
  reads {
    jurors.margrethes mask 12 : range;
    kunming.files mask 252 : ternary;
  }
  actions {
    fanged;
    nighest;
  }
}

table visit {
  reads {
    sonorously : valid;
    sonorously.christensen : exact;
  }
  actions {
    fanged;
    nighest;
  }
}

control ingress {
  apply(bouts);
  if (not((0 != 6))) {
    apply(mvps);
  }
  if ((scribe.rapiers > 0)) {
    apply(visit);
  }
}
