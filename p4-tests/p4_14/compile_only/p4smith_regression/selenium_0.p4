/* p4smith seed: 204005731 */
#include <tofino/intrinsic_metadata.p4>
header_type ac {
  fields {
    expounders : 16;
    dissimulators : 32;
    johns : 48;
    eradicated : 32;
  }
}

header_type sihanouks {
  fields {
    slanderers : 16;
    ambulations : 16;
  }
}

header_type triers {
  fields {
    cortes : 48;
    castors : 8;
  }
}

header_type eradicators {
  fields {
    poodle : 16;
    earnestly : 64;
    notices : 16;
    doctoring : 16;
    bauds : 8;
  }
}

header_type couturier {
  fields {
    snipers : 32;
    screamers : 32;
    plenitudes : 16;
  }
}

header_type yahtzees {
  fields {
    entrance : 48;
    velasquezs : 48;
    contrails : 16;
  }
}

header ac hallucinogenics;

header sihanouks ilenes;

header triers similarity;

header eradicators sixteenths;

header couturier regicides;

header yahtzees photofinishings;

parser start {
  return parse_hallucinogenics;
}

parser parse_hallucinogenics {
  extract(hallucinogenics);
  return select (current(0, 8)) {
    3 : parse_ilenes;
    38 : parse_similarity;
  }
}

parser parse_ilenes {
  extract(ilenes);
  return select (latest.slanderers) {
    4144 : parse_similarity;
  }
}

parser parse_similarity {
  extract(similarity);
  return select (current(0, 8)) {
    28 : parse_regicides;
    58 : parse_sixteenths;
  }
}

parser parse_sixteenths {
  extract(sixteenths);
  return select (latest.poodle) {
    62290 : parse_regicides;
    58012 : parse_photofinishings;
  }
}

parser parse_regicides {
  extract(regicides);
  return select (current(0, 8)) {
    206 : parse_photofinishings;
  }
}

parser parse_photofinishings {
  extract(photofinishings);
  return ingress;
}

action thracian() {
  modify_field(standard_metadata.egress_spec, 1);
}

action distinctest(immaculately) {
  bit_or(similarity.castors, immaculately, regicides.screamers);
  add_header(similarity);
  modify_field(ilenes.ambulations, immaculately);
}

action muggiest(dulls, basel) {
  copy_header(regicides, regicides);
}

table conduits {
  actions {
    thracian;
    }
  }

table depressingly {
  reads {
    similarity : valid;
    hallucinogenics : valid;
  }
  actions {
    muggiest;
    thracian;
  }
}

table rings {
  reads {
    regicides : valid;
    similarity : valid;
    regicides.snipers : ternary;
  }
  actions {
    distinctest;
    muggiest;
    thracian;
  }
}

control ingress {
  apply(conduits);
  if (valid(regicides)) {
    apply(depressingly);
  }
  apply(rings);
}
