/* p4smith seed: 290534643 */
#include <tofino/intrinsic_metadata.p4>
header_type protesters {
  fields {
    condillac : 7;
    mudslingings : 11;
    omicrons : 6 (signed);
  }
}

header_type rankled {
  fields {
    guatemala : 5;
    fascinations : 48 (saturating);
    weer : 11;
    stumps : 8 (saturating);
    compulsively : 8;
  }
}

header_type proselytizers {
  fields {
    mira : 16;
    mustangs : 48;
    heathen : 10 (signed, saturating);
    optics : 12 (signed);
    geek : 48;
    jurywomen : 2;
  }
}

header_type promenades {
  fields {
    vouches : 3;
    kenyatta : 11;
    staplers : 8;
    moated : 10 (signed);
  }
}

header_type hydroponically {
  fields {
    card : 1;
    literacy : 4 (saturating);
    menstruate : 16;
    recklessnesss : 11 (saturating);
    turner : 16;
  }
}

header_type laps {
  fields {
    proverb : 7;
    deads : 11 (signed);
    pluralization : 12;
    sublease : 11;
    dendrite : 16;
    absentee : 12;
    trillions : 11;
  }
}

header protesters inequitably;

header rankled diacritic;

header proselytizers scums;

header promenades conscienceless;

header hydroponically threaten;

header laps purposefully;

parser start {
  return parse_inequitably;
}

parser parse_inequitably {
  extract(inequitably);
  return select (latest.omicrons) {
    1 : parse_purposefully;
    4 : parse_diacritic;
  }
}

parser parse_diacritic {
  extract(diacritic);
  return select (latest.stumps) {
    79 : parse_scums;
  }
}

parser parse_scums {
  extract(scums);
  return select (latest.jurywomen) {
    1 : parse_purposefully;
    1 : parse_conscienceless;
  }
}

parser parse_conscienceless {
  extract(conscienceless);
  return select (latest.staplers) {
    112 : parse_threaten;
  }
}

parser parse_threaten {
  extract(threaten);
  return select (latest.turner) {
    15352 : parse_purposefully;
  }
}

parser parse_purposefully {
  extract(purposefully);
  return ingress;
}

field_list moonstones {
  purposefully.proverb;
  purposefully.trillions;
  threaten.recklessnesss;
  scums.geek;
  conscienceless.moated;
  purposefully.sublease;
  inequitably;
}

field_list demos {
  inequitably.omicrons;
  threaten.card;
  threaten.recklessnesss;
  conscienceless.kenyatta;
  scums.geek;
  purposefully.sublease;
  purposefully.dendrite;
  purposefully.absentee;
  inequitably.mudslingings;
}

field_list_calculation registers {
  input {
    demos;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation slats {
  input {
    demos;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field threaten.menstruate {
  update slats;
  verify slats;
  verify slats;
}

calculated_field scums.mira {
  verify slats;
  update slats;
  verify slats;
}

action blustery() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action nop() {
}

action ce(carcasses, noyess, disabuse) {
  bit_and(diacritic.compulsively, diacritic.stumps, 3295438221257609492);
  bit_and(scums.mira, threaten.turner, threaten.turner);
  subtract(threaten.turner, 3036304612826999428, 3685835177122343863);
  bit_or(diacritic.stumps, 1997158215797941303, diacritic.stumps);
  add_header(inequitably);
  modify_field(scums.heathen, scums.heathen);
  modify_field(conscienceless.moated, conscienceless.moated);
}

action zaniest(squealer, righting) {
  modify_field(purposefully.deads, inequitably.mudslingings);
  modify_field(scums.mustangs, scums.geek);
  remove_header(purposefully);
  subtract(scums.mira, scums.mira, 1549897078812476705);
  bit_and(diacritic.compulsively, diacritic.stumps, diacritic.compulsively);
  bit_or(threaten.turner, 3647118298876015486, 1982650445931499363);
  modify_field(threaten.menstruate, threaten.menstruate);
  subtract_from_field(diacritic.stumps, diacritic.stumps);
}

action gospels(sop, recolonize, ionizes) {
  bit_xor(threaten.turner, threaten.turner, threaten.turner);
  subtract_from_field(diacritic.compulsively, diacritic.stumps);
  add(diacritic.stumps, diacritic.stumps, 4138229999398036857);
  bit_and(scums.mira, scums.mira, scums.mira);
  modify_field(diacritic.weer, purposefully.deads);
  copy_header(inequitably, inequitably);
  add_header(inequitably);
  modify_field_rng_uniform(conscienceless.staplers, 0, 255);
}

action troikas() {
  add(diacritic.stumps, 3896119334026684778, diacritic.compulsively);
  add_to_field(diacritic.compulsively, diacritic.compulsively);
  subtract(scums.mira, threaten.turner, scums.mira);
  copy_header(inequitably, inequitably);
}

action_profile petrified {
  actions {
    troikas;
    gospels;
  }
  size : 26;
}

table clinks {
  actions {
    blustery;
    }
  }

table booed {
  reads {
    inequitably : valid;
    diacritic.guatemala : lpm;
    diacritic.fascinations : ternary;
    diacritic.weer : exact;
    diacritic.stumps : ternary;
    diacritic.compulsively : exact;
    conscienceless.vouches : exact;
    conscienceless.kenyatta : ternary;
    conscienceless.staplers : exact;
    threaten.card mask 0 : exact;
    threaten.literacy : ternary;
    threaten.menstruate : exact;
    threaten.recklessnesss : range;
    threaten.turner : exact;
    purposefully : valid;
    purposefully.proverb : range;
    purposefully.pluralization : range;
    purposefully.trillions mask 3 : ternary;
  }
  actions {
    gospels;
    zaniest;
  }
}

table limbo {
  actions {
      nop;
    }
  }

table slashes {
  reads {
    diacritic : valid;
    diacritic.fascinations mask 29 : exact;
    diacritic.weer mask 0 : exact;
    conscienceless.kenyatta : exact;
    conscienceless.staplers mask 5 : exact;
    purposefully : valid;
    purposefully.absentee : ternary;
  }
  actions {
    troikas;
  }
}

table grudges {
  reads {
    diacritic : valid;
    scums : valid;
    scums.mustangs : exact;
    scums.heathen : exact;
    scums.optics mask 10 : exact;
    scums.geek : exact;
    scums.jurywomen : exact;
    conscienceless.moated : ternary;
    threaten : valid;
    purposefully.proverb : exact;
    purposefully.pluralization : ternary;
    purposefully.sublease : exact;
    purposefully.dendrite : ternary;
  }
  action_profile : petrified;
}

table rations {
  reads {
    purposefully.pluralization : exact;
    purposefully.sublease : exact;
    purposefully.dendrite : exact;
  }
  actions {
    nop;
  }
}

table mincers {
  reads {
    diacritic : valid;
    diacritic.compulsively : ternary;
    scums.mira : exact;
    scums.heathen : exact;
    scums.geek : exact;
    scums.jurywomen : lpm;
    conscienceless : valid;
  }
  actions {
    blustery;
    gospels;
  }
}

table third {
  reads {
    scums.mira : exact;
    scums.heathen : exact;
    scums.geek : ternary;
    threaten.menstruate : lpm;
    threaten.recklessnesss : ternary;
    purposefully : valid;
  }
  actions {
    ce;
    zaniest;
  }
}

table illusion {
  actions {
    nop;
    }
  }

table xmases {
  reads {
    scums.jurywomen mask 0 : ternary;
  }
  actions {
    nop;
  }
}

table groundlessly {
  reads {
    diacritic : valid;
    diacritic.guatemala : exact;
    diacritic.fascinations mask 24 : exact;
    diacritic.stumps : lpm;
    diacritic.compulsively : exact;
    purposefully.proverb : exact;
    purposefully.sublease : exact;
    purposefully.dendrite : exact;
  }
  actions {
    ce;
  }
}

control ingress {
  if ((((diacritic.compulsively == diacritic.stumps) or true) or not(false))) {
    apply(booed);
    if (not(((purposefully.sublease <= 227) and false))) {
      
    } else {
      apply(limbo);
      apply(slashes);
    }
    apply(grudges);
  } else {
    apply(rations);
  }
  apply(mincers);
  apply(third);
  apply(illusion);
  apply(xmases);
  apply(groundlessly);
}
