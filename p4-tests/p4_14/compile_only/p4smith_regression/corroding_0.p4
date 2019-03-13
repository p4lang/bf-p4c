/* p4smith seed: 380146378 */
#include <tofino/intrinsic_metadata.p4>
header_type toddlers {
  fields {
    windshields : 8;
    reddened : 32;
    neutrons : 48;
    parroted : 16 (signed, saturating);
    sacristys : 8;
    quadruplet : 128 (saturating);
  }
}

header_type pellucid {
  fields {
    eighth : 32;
    prolific : 16 (signed, saturating);
    humdrum : 128;
  }
}

header_type equaled {
  fields {
    alts : 8 (saturating);
    vegeburgers : 8;
    algebras : 16 (signed, saturating);
    fabricating : 32 (signed);
    closeouts : 16;
  }
}

header_type dosser {
  fields {
    dials : 32;
    gardening : 16 (saturating);
    robins : 8;
    unfurling : 32;
  }
}

header_type sangfroids {
  fields {
    requiems : 32 (signed);
  }
}

header_type typical {
  fields {
    seedpods : 16 (signed);
    smartypants : 32;
    alcoa : 128 (signed);
  }
}

header toddlers potentates;

header pellucid cholers;

header equaled panoply;

header dosser yammerers;

header sangfroids spireas;

header typical bonfires;

register malathions {
  width : 16;
  instance_count : 9;
}

register permeated {
  width : 128;
  instance_count : 807;
}

register cantilevering {
  width : 64;
  instance_count : 1024;
}

register racecourse {
  width : 16;
  instance_count : 833;
}

parser start {
  return parse_potentates;
}

parser parse_potentates {
  extract(potentates);
  return select (current(0, 8)) {
    132 : parse_cholers;
  }
}

parser parse_cholers {
  extract(cholers);
  return select (current(0, 8)) {
    50 : parse_yammerers;
    124 : parse_panoply;
    32 : parse_spireas;
  }
}

parser parse_panoply {
  extract(panoply);
  return select (current(0, 8)) {
    255 : parse_yammerers;
    240 : parse_bonfires;
  }
}

parser parse_yammerers {
  extract(yammerers);
  return select (current(0, 8)) {
    29 : parse_spireas;
  }
}

parser parse_spireas {
  extract(spireas);
  return select (current(0, 8)) {
    92 : parse_bonfires;
  }
}

parser parse_bonfires {
  extract(bonfires);
  return ingress;
}

field_list assignors {
  bonfires;
  panoply.alts;
  bonfires.alcoa;
  cholers;
  146;
  bonfires.alcoa;
  panoply.closeouts;
  132;
  175;
  potentates.neutrons;
  panoply.closeouts;
  bonfires;
  spireas;
  panoply.algebras;
  potentates.windshields;
  cholers.prolific;
}

field_list duff {
  potentates.reddened;
  potentates.reddened;
  yammerers.dials;
  panoply.alts;
  cholers.eighth;
  yammerers;
  bonfires;
  yammerers;
  potentates.reddened;
}

field_list steeples {
  panoply.vegeburgers;
  cholers.humdrum;
  yammerers.robins;
  yammerers.dials;
}

field_list massivenesss {
  panoply.alts;
  yammerers.dials;
  potentates.neutrons;
}

field_list_calculation chafed {
  input {
    massivenesss;
    duff;
    assignors;
  }
  algorithm : crc32;
  output_width : 16;
}

calculated_field panoply.algebras {
  update chafed if (valid(spireas));
}

calculated_field potentates.quadruplet {
  verify chafed;
}

calculated_field potentates.sacristys {
  update chafed;
}

calculated_field potentates.reddened {
  update chafed if (valid(panoply));
}

action implements() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action groomsmans(adjustable, shagged) {
  subtract_from_field(yammerers.robins, potentates.windshields);
  add_header(yammerers);
  copy_header(panoply, panoply);
  add(potentates.windshields, potentates.windshields, potentates.windshields);
  add(spireas.requiems, bonfires.smartypants, yammerers.dials);
}

action aristides() {
  remove_header(bonfires);
}

action bushels(operatic) {
  add_to_field(potentates.windshields, yammerers.robins);
  bit_xor(panoply.algebras, bonfires.seedpods, 35828);
  add(panoply.closeouts, yammerers.gardening, bonfires.seedpods);
  modify_field(potentates.reddened, bonfires.smartypants);
  bit_xor(panoply.vegeburgers, panoply.alts, 13);
}

table pillowing {
  actions {
    implements;
    }
  }

table clvi {
  reads {
    potentates : valid;
    potentates.windshields : exact;
    potentates.reddened mask 122 : exact;
  }
  actions {
    aristides;
    groomsmans;
    implements;
  }
}

table brazed {
  actions {
    bushels;
    }
  }

table worthwhile {
  actions {
    bushels;
    groomsmans;
    implements;
    }
  }

control ingress {
  apply(pillowing);
  if ((154 <= bonfires.seedpods)) {
    apply(clvi);
  }
  if ((potentates.parroted != potentates.reddened)) {
    apply(brazed);
  }
  if (true) {
    apply(worthwhile);
  }
}
