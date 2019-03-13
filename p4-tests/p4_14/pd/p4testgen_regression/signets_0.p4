/* p4smith seed: 494376114 */
#include <tofino/intrinsic_metadata.p4>
header_type deforms {
  fields {
    tomtits : 32;
    statutes : 32;
    animosity : 16;
    shortenings : 16;
  }
}

header_type accept {
  fields {
    dropkick : 16;
    vending : 16;
  }
}

header_type anniversarys {
  fields {
    coughs : 32;
  }
}

header deforms inversions;

header accept candide;

header anniversarys vesiculate;

parser start {
  return parse_inversions;
}

parser parse_inversions {
  extract(inversions);
  return select (latest.shortenings) {
    37691 : parse_candide;
  }
}

parser parse_candide {
  extract(candide);
  return select (latest.dropkick) {
    2793 : parse_vesiculate;
  }
}

parser parse_vesiculate {
  extract(vesiculate);
  return ingress;
}

action lancer() {
  modify_field(standard_metadata.egress_spec, 1);
}

action matthias() {
  subtract_from_field(inversions.tomtits, 704595900);
  copy_header(inversions, inversions);
  bit_xor(inversions.shortenings, candide.vending, 47303);
  subtract_from_field(candide.dropkick, 6240);
}

action vitals(houseman) {
  bit_or(inversions.shortenings, 14860, candide.dropkick);
  bit_or(inversions.statutes, inversions.statutes, 1452780052);
  add(inversions.tomtits, vesiculate.coughs, inversions.statutes);
}

action repletenesss(stoups) {
  copy_header(vesiculate, vesiculate);
  remove_header(candide);
  modify_field(inversions.animosity, candide.dropkick);
  add(inversions.shortenings, 51715, 57383);
}

action humannesss(armourers, scrimshaws) {
  bit_or(inversions.tomtits, inversions.tomtits, inversions.statutes);
  copy_header(candide, candide);
  bit_and(candide.dropkick, inversions.animosity, candide.dropkick);
}

table encrusts {
  actions {
    lancer;
    }
  }

table jarful {
  reads {
    candide.dropkick mask 235 : ternary;
    inversions.statutes mask 160 : range;
    inversions.animosity mask 76 : range;
  }
  actions {
    humannesss;
    lancer;
    repletenesss;
  }
}

table stoic {
  reads {
    candide : valid;
    vesiculate : valid;
    inversions.statutes mask 120 : ternary;
  }
  actions {
    lancer;
    matthias;
    repletenesss;
  }
}

control ingress {
  if ((1534 == 0)) {
    apply(encrusts);
  }
  if (not((2077 > 2665))) {
    apply(jarful);
  }
  apply(stoic);
}
