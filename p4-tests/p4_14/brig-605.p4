/* p4smith seed: 489482531 */
header_type accessed {
  fields {
    precedence : 16;
    reluctant : 8;
    carmelos : 8;
  }
}

header_type tympanums {
  fields {
    vergers : 32;
    seesawing : 16;
    tycoons : 16;
  }
}

header accessed expounded;

header tympanums zoe;

parser start {
  extract(expounded);
  extract(zoe);
  return ingress;
}

action stick() {
  modify_field(standard_metadata.egress_spec, 1);
}

action excisions() {
  add_header(zoe);
  bit_xor(zoe.seesawing, 5, expounded.reluctant);
  bit_or(zoe.seesawing, expounded.reluctant, zoe.tycoons);
}

table parenthesised {
  actions {
    stick;
    }
  }

table clickers {
  reads {
    zoe.seesawing : range;
    expounded.reluctant : exact;
    expounded.carmelos : ternary;
  }
  actions {
    stick;
  }
}

table spanishs {
  reads {
    zoe : valid;
    zoe.seesawing mask 48 : ternary;
  }
  actions {
    stick;
  }
}

control ingress {
  apply(parenthesised);
  if ((valid(expounded) and (0 > expounded.carmelos))) {
    apply(clickers);
  }
  if ((zoe.tycoons < 4)) {
    apply(spanishs);
  }
}
