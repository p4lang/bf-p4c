/* p4smith seed: 643132475 */
#include <tofino/intrinsic_metadata.p4>
header_type overtired {
  fields {
    catercorner : 16;
    beholder : 8;
    dankly : 32;
    cupcakes : 32;
    marty : 32;
  }
}

header_type cochleae {
  fields {
    gewgaws : 16;
    dinnering : 32;
    slaughterhouses : 8;
    chapultepecs : 16;
    inhibits : 16;
    mutinies : 8;
  }
}

header_type categorizations {
  fields {
    swiftnesss : 32;
    homburgs : 16;
  }
}

header_type dislikes {
  fields {
    commercialized : 32;
    cryptic : 48;
    refashion : 16;
  }
}

header_type cremates {
  fields {
    gravamens : 16;
    unrealized : 16;
    aphrodisiacs : 16;
    tricentennial : 8;
  }
}

header overtired gingrich;

header cochleae quakers;

header categorizations moietys;

header dislikes overbuild;

header cremates overfed;

parser start {
  return parse_gingrich;
}

parser parse_gingrich {
  extract(gingrich);
  return select (current(0, 8)) {
    225 : parse_quakers;
  }
}

parser parse_quakers {
  extract(quakers);
  return select (latest.gewgaws) {
    30530 : parse_moietys;
    0 : parse_overfed;
    22644 : parse_overbuild;
  }
}

parser parse_moietys {
  extract(moietys);
  return select (latest.homburgs) {
    41390 : parse_overfed;
    15786 : parse_overbuild;
  }
}

parser parse_overbuild {
  extract(overbuild);
  return select (latest.refashion) {
    65535 : parse_overfed;
  }
}

parser parse_overfed {
  extract(overfed);
  return ingress;
}

action telemetrys() {
  modify_field(standard_metadata.egress_spec, 1);
}

action deprograms(fusillades, arctics) {
  subtract(gingrich.cupcakes, gingrich.dankly, 1680410435);
  subtract_from_field(overfed.gravamens, moietys.homburgs);
  add_to_field(quakers.chapultepecs, 40270);
}

action margery(hairdresser) {
  bit_xor(quakers.inhibits, 12777, quakers.chapultepecs);
  add(quakers.dinnering, overbuild.commercialized, 2053713495);
  bit_xor(gingrich.cupcakes, gingrich.marty, gingrich.cupcakes);
}

table releases {
  actions {
    telemetrys;
    }
  }

table snifters {
  reads {
    moietys.homburgs : ternary;
  }
  actions {
    margery;
  }
}

control ingress {
  if (not((quakers.mutinies == gingrich.beholder))) {
    apply(releases);
  }
  if ((((quakers.slaughterhouses == gingrich.beholder) or valid(overfed)) and 
      (quakers.slaughterhouses == quakers.slaughterhouses))) {
    apply(snifters);
  }
}
