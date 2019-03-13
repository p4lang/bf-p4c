/* p4smith seed: 628108482 */
#include <tofino/intrinsic_metadata.p4>
header_type dialectics {
  fields {
    constrictor : 16;
    mickeys : 16;
    filliped : 48;
  }
}

header_type triremes {
  fields {
    wig : 32;
    muffs : 48;
    chars : 32;
    nonobligatory : 32;
    spiritedly : 16;
  }
}

header_type retrenching {
  fields {
    ru : 8;
    gigabits : 16;
    bungs : 16;
    childproof : 16;
    harmfulness : 8;
  }
}

header_type blotchier {
  fields {
    irrelevances : 8;
    rightists : 16;
    reformatory : 32;
    fijians : 32;
    bulkheads : 16;
    savage : 8;
  }
}

header_type calibration {
  fields {
    earthenware : 8;
  }
}

header dialectics broadways;

header triremes supranational;

header retrenching chanteys;

header blotchier tabulated;

header calibration chisinau;

parser start {
  return parse_broadways;
}

parser parse_broadways {
  extract(broadways);
  return select (latest.mickeys) {
    30683 : parse_chisinau;
    12128 : parse_chanteys;
    32972 : parse_supranational;
  }
}

parser parse_supranational {
  extract(supranational);
  return select (current(0, 8)) {
    136 : parse_tabulated;
    211 : parse_chanteys;
  }
}

parser parse_chanteys {
  extract(chanteys);
  return select (latest.bungs) {
    39645 : parse_tabulated;
  }
}

parser parse_tabulated {
  extract(tabulated);
  return select (current(0, 8)) {
    230 : parse_chisinau;
  }
}

parser parse_chisinau {
  extract(chisinau);
  return ingress;
}

action taciturn() {
  modify_field(standard_metadata.egress_spec, 1);
}

action cook() {
  modify_field(supranational.chars, 9);
  remove_header(chanteys);
  add_to_field(tabulated.rightists, 4);
}

action cornering() {
  subtract_from_field(broadways.mickeys, supranational.spiritedly);
  add_header(supranational);
}

action guineas(diapered, 
  corralled) {
  add(supranational.nonobligatory, chisinau.earthenware, chanteys.childproof);
  bit_or(tabulated.bulkheads, diapered, broadways.constrictor);
  add(chanteys.harmfulness, supranational.nonobligatory, diapered);
}

table collation {
  actions {
    taciturn;
    }
  }

table email {
  reads {
    supranational.muffs : range;
  }
  actions {
    cook;
    guineas;
  }
}

table thaws {
  actions {
    cook;
    }
  }

table tricepss {
  actions {
    guineas;
    }
  }

control ingress {
  if ((not((chanteys.ru > chanteys.ru)) or (8 > 3))) {
    apply(collation);
  }
  if ((tabulated.savage < chanteys.harmfulness)) {
    apply(email);
  }
  if ((tabulated.irrelevances != chisinau.earthenware)) {
    apply(thaws);
  }
  if ((chisinau.earthenware <= chanteys.ru)) {
    apply(tricepss);
  }
}
