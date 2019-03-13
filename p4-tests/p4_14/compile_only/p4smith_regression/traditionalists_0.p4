/* p4smith seed: 629516227 */
#include <tofino/intrinsic_metadata.p4>
header_type madonnas {
  fields {
    forbearing : 48;
    betterment : 16 (saturating);
  }
}

header_type hairballs {
  fields {
    hijackings : 32 (signed);
    hardheartedly : 64 (signed);
    edema : 64;
    kfcs : 48 (signed, saturating);
  }
}

header_type menorahs {
  fields {
    grandeur : 16;
    workroom : 16;
    loathsome : 8 (signed);
    medallists : 16;
    nuthouses : 16;
  }
}

header_type manners {
  fields {
    rarebits : 128;
    impiety : 48 (signed, saturating);
    guam : 32;
    persimmon : 48;
    deductibles : 16;
    walkover : 16;
  }
}

header_type ascot {
  fields {
    hilbert : 48;
    rapacious : 16;
    shoeshines : 32;
    troops : 64;
  }
}

header madonnas gormandize;

header hairballs numerology;

header menorahs melissa;

header manners numskulls;

header ascot regent;

register quaking {
  width : 32;
  instance_count : 257;
}

register gardenings {
  width : 48;
  instance_count : 630;
}

parser start {
  return parse_gormandize;
}

parser parse_gormandize {
  extract(gormandize);
  return select (current(0, 8)) {
    2 : parse_numerology;
    255 : parse_numskulls;
  }
}

parser parse_numerology {
  extract(numerology);
  return select (current(0, 8)) {
    0 : parse_numskulls;
    122 : parse_melissa;
  }
}

parser parse_melissa {
  extract(melissa);
  return select (latest.medallists) {
    29064 : parse_numskulls;
  }
}

parser parse_numskulls {
  extract(numskulls);
  return select (current(0, 8)) {
    113 : parse_regent;
  }
}

parser parse_regent {
  extract(regent);
  return ingress;
}

field_list catnap {
  melissa.workroom;
  melissa;
  numerology.hijackings;
  melissa;
  regent.troops;
  gormandize.forbearing;
  gormandize.forbearing;
  numerology.hardheartedly;
  numerology.hardheartedly;
  numerology.edema;
  numskulls.impiety;
}

field_list_calculation enlivenments {
  input {
    catnap;
  }
#ifdef __p4c__
  algorithm : csum16;
#else
  algorithm : xor16;
#endif
  output_width : 8;
}

field_list_calculation flakes {
  input {
    catnap;
  }
  algorithm : xor16;
  output_width : 32;
}

field_list_calculation spiniest {
  input {
    catnap;
  }
  algorithm : csum16;
  output_width : 32;
}

calculated_field numskulls.guam {
#ifdef __p4c__
  verify spiniest;
  verify enlivenments;
#else
  verify spiniest if (valid(numerology));
  verify enlivenments if (melissa.workroom == 0);
#endif
}

action antimicrobial() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action strike(macadamizes, syndicating) {
  add(regent.rapacious, gormandize.betterment, melissa.grandeur);
  modify_field(regent.shoeshines, numskulls.guam);
  modify_field(melissa.loathsome, 81);
  add(numskulls.guam, numskulls.guam, 0);
}

action shpt(reduplicating) {
  remove_header(numerology);
  bit_and(melissa.medallists, melissa.medallists, numskulls.walkover);
  remove_header(gormandize);
  bit_and(numskulls.deductibles, melissa.workroom, numskulls.walkover);
  bit_xor(numerology.hijackings, 796257169, numerology.hijackings);
  subtract_from_field(melissa.loathsome, melissa.loathsome);
  add(regent.shoeshines, numskulls.guam, 737780096);
  bit_and(numskulls.guam, 1680802088, numskulls.guam);
}

action runes(shower, newspapers) {
  subtract(regent.rapacious, 24335, melissa.medallists);
}

table nuncio {
  actions {
    antimicrobial;
    }
  }

table limericks {
  reads {
    melissa.workroom mask 170 : ternary;
    melissa.loathsome : range;
    melissa.medallists mask 179 : lpm;
    numskulls : valid;
    numskulls.rarebits : exact;
    numskulls.persimmon : range;
    regent.troops mask 234 : range;
  }
  actions {
    strike;
  }
}

control ingress {
  if (true) {
    apply(nuncio);
  }
  if (((false and (true and (numerology.hijackings != numerology.hijackings))) or
      ((false or (melissa.grandeur > 189)) and false))) {
    apply(limericks);
  }
}
