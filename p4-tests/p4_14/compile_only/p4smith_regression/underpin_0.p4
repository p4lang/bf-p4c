/* p4smith seed: 617926672 */
#include <tofino/intrinsic_metadata.p4>
header_type daze {
  fields {
    specifics : 16;
  }
}

header_type progenys {
  fields {
    wormwoods : 16;
    predestination : 16;
    louisianans : 32;
    pitchblendes : 8;
    sweaters : 48;
    farmed : 16;
  }
}

header daze strengtheners;

header progenys alongside;

parser start {
  return parse_strengtheners;
}

parser parse_strengtheners {
  extract(strengtheners);
  return select (latest.specifics) {
    23136 : parse_alongside;
  }
}

parser parse_alongside {
  extract(alongside);
  return ingress;
}

action kaylas() {
  modify_field(standard_metadata.egress_spec, 1);
}

action knuckleheads() {
  copy_header(alongside, alongside);
  remove_header(strengtheners);
  bit_and(alongside.predestination, 64926, alongside.predestination);
  add_header(strengtheners);
}

table growling {
  actions {
    kaylas;
    }
  }

table dishtowels {
  reads {
    alongside.wormwoods mask 252 : exact;
  }
  actions {
    kaylas;
    knuckleheads;
  }
}

table deigning {
  reads {
    alongside.sweaters : exact;
    strengtheners.specifics : ternary;
    alongside.louisianans mask 18 : exact;
  }
  actions {
    kaylas;
  }
}

table viking {
  reads {
    alongside.louisianans mask 234 : ternary;
    strengtheners.specifics mask 169 : exact;
    strengtheners : valid;
  }
  actions {
    kaylas;
  }
}

table bradley {
  reads {
    alongside.louisianans mask 226 : exact;
    alongside.louisianans mask 83 : exact;
  }
  actions {
    kaylas;
  }
}

control ingress {
  if ((alongside.pitchblendes <= 2031)) {
    apply(growling);
  }
  apply(dishtowels);
  if (((730 > 1079) and (alongside.pitchblendes < alongside.pitchblendes))) {
    apply(deigning);
  }
  if ((3751 > alongside.pitchblendes)) {
    apply(viking);
  }
  apply(bradley);
}
