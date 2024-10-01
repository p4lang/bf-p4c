/* p4smith seed: 1033296708 */
#include <tofino/intrinsic_metadata.p4>
header_type everready {
  fields {
    buried : 8;
    enabler : 8;
    telemann : 16;
    amplifiers : 8;
    hollers : 8;
    hickeys : 16;
  }
}

header_type tannhausers {
  fields {
    page : 16;
    neocolonialist : 16;
    sparks : 32;
    singular : 48;
    effervescences : 32;
    shrubberies : 48;
  }
}

header everready aaliyah;

header tannhausers scythe;

parser start {
  return parse_aaliyah;
}

parser parse_aaliyah {
  extract(aaliyah);
  return select (latest.hollers) {
    59 : parse_scythe;
  }
}

parser parse_scythe {
  extract(scythe);
  return ingress;
}

action exception() {
  modify_field(standard_metadata.egress_spec, 1);
}

action domesday() {
  modify_field(aaliyah.telemann, scythe.singular);
  copy_header(scythe, scythe);
  bit_and(aaliyah.enabler, aaliyah.amplifiers, aaliyah.telemann);
  copy_header(scythe, scythe);
}

action fieldsman() {
  subtract_from_field(scythe.page, scythe.neocolonialist);
  subtract_from_field(scythe.sparks, aaliyah.enabler);
  add(aaliyah.hickeys, 9, aaliyah.telemann);
  subtract_from_field(scythe.page, scythe.effervescences);
}

action transducers() {
  subtract_from_field(aaliyah.hickeys, 0);
  add(scythe.page, aaliyah.buried, 9);
  copy_header(aaliyah, aaliyah);
  add_header(scythe);
}

action bittersweets() {
  subtract_from_field(scythe.effervescences, 0);
  modify_field(aaliyah.enabler, 5);
  copy_header(scythe, scythe);
  bit_and(scythe.effervescences, aaliyah.amplifiers, 4);
}

table whistling {
  actions {
    exception;
    }
  }

table check {
  reads {
    scythe : valid;
    aaliyah.enabler mask 150 : range;
    aaliyah.telemann mask 10 : ternary;
  }
  actions {
    domesday;
  }
}

table coarsenesss {
  actions {
    bittersweets;
    domesday;
    }
  }

control ingress {
  if ((aaliyah.enabler < 0)) {
    apply(whistling);
  }
  apply(check);
  apply(coarsenesss);
}
