/* p4smith seed: 241307883 */
#include <tofino/intrinsic_metadata.p4>
header_type broodmare {
  fields {
    uncovering : 7;
    rind : 9 (saturating);
  }
}

header_type goober {
  fields {
    obi : 1;
    ohio : 7;
  }
}

header_type interposes {
  fields {
    mach : 2;
    decagons : 10 (signed, saturating);
    cockchafer : 4;
    inflammatory : 8;
  }
}

header_type applies {
  fields {
    togo : 32;
  }
}

header_type pistes {
  fields {
    sheeting : 7;
    lawsuits : 2;
    dearest : 4;
    kinfolkss : 16;
    chaitanya : 4;
    smugnesss : 16;
    macedonians : 7;
  }
}

header_type cheviots {
  fields {
    jackknifed : 2;
    kitschs : 6;
  }
}

header_type originally {
  fields {
    oversubscribed : 5;
    arrayed : 4;
    swap : 32;
    redirecting : 16;
    plotter : 11 (saturating);
    rhone : 8;
    canniest : 4 (saturating);
  }
}

header broodmare blank;

header goober idiosyncrasies;

header interposes alike;

header applies extended;

header pistes mastery;

header cheviots spitefully;

header originally anchorpeople;

register dark {
  width : 32;
  instance_count : 83;
}

register terrance {
  width : 8;
  instance_count : 165;
}

parser start {
  return parse_blank;
}

parser parse_blank {
  extract(blank);
  return select (latest.rind) {
    19 : parse_idiosyncrasies;
    225 : parse_alike;
    54 : parse_mastery;
  }
}

parser parse_idiosyncrasies {
  extract(idiosyncrasies);
  return select (latest.obi) {
    0 : parse_alike;
  }
}

parser parse_alike {
  extract(alike);
  return select (latest.mach) {
    0 : parse_extended;
    0 : parse_anchorpeople;
  }
}

parser parse_extended {
  extract(extended);
  return select (current(0, 8)) {
    0 : parse_spitefully;
    78 : parse_anchorpeople;
    125 : parse_mastery;
  }
}

parser parse_mastery {
  extract(mastery);
  return select (latest.macedonians) {
    17 : parse_spitefully;
  }
}

parser parse_spitefully {
  extract(spitefully);
  return select (latest.kitschs) {
    0 : parse_anchorpeople;
  }
}

parser parse_anchorpeople {
  extract(anchorpeople);
  return ingress;
}

field_list makeshifts {
  extended.togo;
  alike.inflammatory;
  anchorpeople;
}

field_list chinos {
  extended.togo;
  alike.inflammatory;
}

field_list_calculation scrabble {
  input {
    makeshifts;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation acquirements {
  input {
    makeshifts;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation heckle {
  input {
    chinos;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation squeezers {
  input {
    chinos;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field mastery.smugnesss {
  verify acquirements;
  update scrabble;
  update scrabble;
}

action mollusc() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action weasel() {
  modify_field_rng_uniform(blank.uncovering, 0, 15);
  copy_header(idiosyncrasies, idiosyncrasies);
}

action scrounger(sigurd) {
  subtract_from_field(extended.togo, extended.togo);
  add(alike.inflammatory, alike.inflammatory, alike.inflammatory);
  modify_field(blank.uncovering, mastery.macedonians);
  modify_field_rng_uniform(anchorpeople.arrayed, 0, 31);
  remove_header(alike);
  modify_field_rng_uniform(blank.rind, 0, 127);
  modify_field(anchorpeople.canniest, alike.cockchafer);
}

action multilateral(reboils, joshed, fest) {
  bit_and(alike.inflammatory, alike.inflammatory, 2292430418484633914);
  bit_or(extended.togo, 553622076204600521, 3975236686860374034);
  add_header(blank);
  add_header(extended);
  add_header(mastery);
  add_header(anchorpeople);
  modify_field(mastery.macedonians, mastery.sheeting);
}

action_profile lieutenancys {
  actions {
    scrounger;
    weasel;
    mollusc;
  }
  size : 4;
}

action_profile religiousness {
  actions {
    multilateral;
    scrounger;
  }
  size : 20;
}

table nonprofessionals {
  actions {
    mollusc;
    }
  }

table dictation {
  action_profile : religiousness;
  }

table gabardines {
  reads {
    alike.mach mask 1 : lpm;
    alike.decagons mask 4 : exact;
    alike.cockchafer mask 0 : ternary;
    alike.inflammatory mask 3 : ternary;
    spitefully.jackknifed : exact;
    anchorpeople : valid;
  }
  actions {
    multilateral;
  }
}

control ingress {
  apply(dictation);
  apply(gabardines);
}
