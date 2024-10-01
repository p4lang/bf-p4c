/* p4smith seed: 742718409 */
#include <tofino/intrinsic_metadata.p4>
header_type chubbiest {
  fields {
    vivaldi : 1;
    chalets : 4;
    descending : 6 (signed, saturating);
    censusing : 6 (saturating);
    shorts : 48;
    jensens : 8;
    fillet : 7;
  }
}

header_type sturdy {
  fields {
    roominess : 32;
  }
}

header_type pshaw {
  fields {
    footnoted : 5;
    pumpernickel : 3 (signed, saturating);
  }
}

header_type grundy {
  fields {
    bohemians : 4;
    ellies : 48;
    generalissimos : 12;
    disappointment : 48;
  }
}

header_type communicable {
  fields {
    amidships : 2;
    extrude : 2;
    horologists : 9;
    antics : 16 (signed, saturating);
    ungraded : 3;
  }
}

header_type forebear {
  fields {
    porns : 6;
    shrugs : 48;
    tuscons : 10;
    crabgrass : 48 (signed, saturating);
    tongas : 16;
    kafka : 16;
  }
}

header_type outlet {
  fields {
    ovation : 2;
    esperantos : 16;
    tolkien : 4 (saturating);
    incurable : 2 (signed, saturating);
  }
}

header chubbiest jurymans;

header sturdy adjudicating;

header pshaw retouch;

header grundy kosher;

header communicable rustiness;

header forebear assistances;

header outlet vesting;

register peripherals {
  width : 64;
  instance_count : 1;
}

register debauches {
  width : 64;
  instance_count : 1024;
}

register rote {
  width : 16;
  instance_count : 464;
}

parser start {
  return parse_jurymans;
}

parser parse_jurymans {
  extract(jurymans);
  return select (latest.jensens) {
    23 : parse_rustiness;
    73 : parse_adjudicating;
  }
}

parser parse_adjudicating {
  extract(adjudicating);
  return select (current(0, 8)) {
    123 : parse_retouch;
  }
}

parser parse_retouch {
  extract(retouch);
  return select (latest.pumpernickel) {
    3 : parse_kosher;
  }
}

parser parse_kosher {
  extract(kosher);
  return select (latest.bohemians) {
    5 : parse_rustiness;
  }
}

parser parse_rustiness {
  extract(rustiness);
  return select (latest.antics) {
    17835 : parse_assistances;
  }
}

parser parse_assistances {
  extract(assistances);
  return select (latest.tongas) {
    14229 : parse_vesting;
  }
}

parser parse_vesting {
  extract(vesting);
  return ingress;
}

field_list decrepitudes {
  assistances.tongas;
  rustiness;
  adjudicating.roominess;
  retouch;
  assistances.kafka;
  kosher.disappointment;
  assistances.crabgrass;
  jurymans;
}

field_list putin {
  assistances.kafka;
}

field_list_calculation colones {
  input {
    decrepitudes;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field assistances.kafka {
  verify colones;
}

calculated_field assistances.tongas {
  update colones;
  verify colones;
  verify colones;
}

calculated_field rustiness.antics {
  update colones;
}

calculated_field vesting.esperantos {
  update colones;
  update colones;
}

action lamented() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action emboldens() {
  remove_header(jurymans);
  modify_field(kosher.ellies, kosher.disappointment);
  add_header(adjudicating);
  add(assistances.tongas, assistances.kafka, 0);
  bit_or(adjudicating.roominess, 2550244160353577915, 112058210914347798);
  bit_or(assistances.kafka, 1841739351818228327, assistances.kafka);
  copy_header(vesting, vesting);
  remove_header(assistances);
}

action minces(metabolisms, happenstance) {
  remove_header(kosher);
  bit_and(assistances.kafka, assistances.tongas, assistances.tongas);
  remove_header(vesting);
}

action postgraduates(wattled, flurrys, miscarriage) {
  remove_header(jurymans);
  add_to_field(adjudicating.roominess, 338788507003173296);
  modify_field(jurymans.shorts, kosher.disappointment);
  bit_xor(assistances.tongas, assistances.kafka, assistances.tongas);
  add_header(kosher);
}

action_profile layovers {
  actions {
    minces;
  }
  size : 26;
}

action_profile superhuman {
  actions {
    postgraduates;
    minces;
  }
  size : 27;
}

action_profile whitewashed {
  actions {
    postgraduates;
    minces;
    emboldens;
    lamented;
  }
  size : 26;
}

action_profile valhallas {
  actions {
    lamented;
  }
  size : 3;
}

table deprogram {
  actions {
    lamented;
    }
  }

table executioner {
  reads {
    jurymans.descending mask 3 : exact;
    jurymans.shorts : exact;
    adjudicating : valid;
    kosher.bohemians : lpm;
    kosher.ellies mask 38 : ternary;
    kosher.generalissimos : exact;
    kosher.disappointment mask 9 : ternary;
    rustiness : valid;
    rustiness.horologists : ternary;
    rustiness.antics : ternary;
  }
  action_profile : superhuman;
}

table tachographs {
  reads {
    adjudicating : valid;
    adjudicating.roominess mask 16 : exact;
    kosher : valid;
    kosher.generalissimos : ternary;
    kosher.disappointment mask 1 : exact;
    rustiness.ungraded : exact;
    assistances : valid;
    assistances.shrugs : exact;
    assistances.tuscons : exact;
    assistances.crabgrass : lpm;
    assistances.tongas : ternary;
    assistances.kafka mask 4 : range;
    vesting.ovation mask 1 : exact;
    vesting.esperantos mask 15 : exact;
    vesting.tolkien mask 0 : ternary;
    vesting.incurable : exact;
  }
  action_profile : valhallas;
}

table yachtsman {
  reads {
    retouch : valid;
    kosher : valid;
    vesting.ovation : exact;
    vesting.tolkien : exact;
  }
  actions {
    
  }
}

table shingle {
  reads {
    adjudicating.roominess : exact;
    rustiness.amidships : lpm;
    rustiness.extrude : exact;
    rustiness.horologists : exact;
    rustiness.antics : exact;
    rustiness.ungraded : exact;
    assistances : valid;
    assistances.porns : exact;
    assistances.tuscons mask 0 : ternary;
    vesting.ovation : range;
    vesting.esperantos : exact;
    vesting.tolkien : exact;
    vesting.incurable : exact;
  }
  actions {
    lamented;
    postgraduates;
  }
}

table isomerisms {
  reads {
    jurymans : valid;
    jurymans.vivaldi : exact;
    jurymans.descending : ternary;
    jurymans.censusing : ternary;
    jurymans.shorts mask 36 : lpm;
    jurymans.jensens mask 0 : exact;
    adjudicating.roominess mask 22 : exact;
    retouch.pumpernickel : exact;
    rustiness.antics : exact;
    rustiness.ungraded mask 0 : exact;
    assistances : valid;
    assistances.porns : exact;
    assistances.shrugs : ternary;
    assistances.tuscons mask 6 : ternary;
    assistances.crabgrass : ternary;
    assistances.tongas : range;
  }
  actions {
    emboldens;
    minces;
  }
}

table entreaty {
  reads {
    adjudicating : valid;
    adjudicating.roominess : exact;
    assistances : valid;
    assistances.tuscons mask 6 : exact;
    vesting : valid;
    vesting.incurable : exact;
  }
  action_profile : layovers;
}

table dislocations {
  reads {
    jurymans : valid;
    retouch : valid;
    rustiness.horologists : exact;
    rustiness.antics mask 7 : lpm;
    rustiness.ungraded : ternary;
    assistances : valid;
    assistances.porns : exact;
    assistances.shrugs : exact;
    assistances.tuscons mask 1 : exact;
    assistances.crabgrass : exact;
    assistances.tongas mask 14 : exact;
    vesting.tolkien : exact;
    vesting.incurable : exact;
  }
  actions {
    emboldens;
    minces;
    postgraduates;
  }
}

table stepchilds {
  reads {
    jurymans : valid;
    jurymans.chalets : exact;
    jurymans.censusing : exact;
    jurymans.shorts : exact;
    rustiness : valid;
    rustiness.amidships : exact;
    rustiness.extrude : lpm;
    rustiness.horologists : exact;
    rustiness.antics : exact;
    rustiness.ungraded : ternary;
  }
  action_profile : whitewashed;
}

table pitfalls {
  reads {
    retouch : valid;
    retouch.footnoted mask 4 : exact;
    kosher.bohemians mask 2 : ternary;
    kosher.ellies : exact;
    rustiness.amidships mask 0 : exact;
    rustiness.horologists : exact;
    rustiness.antics : ternary;
    rustiness.ungraded : exact;
    assistances : valid;
    assistances.crabgrass mask 47 : exact;
    assistances.kafka : exact;
  }
  actions {
    emboldens;
    lamented;
  }
}

table fecklessness {
  reads {
    adjudicating : valid;
  }
  actions {
    minces;
    postgraduates;
  }
}

table skulls {
  actions {
    lamented;
    minces;
    }
  }

control ingress {
  apply(executioner);
  apply(tachographs) {
    hit {
      if ((false or valid(adjudicating))) {
        
      }
    }
  }
  apply(yachtsman);
  apply(shingle);
  apply(isomerisms);
  if (((91 < jurymans.censusing) and (kosher.generalissimos >= 163))) {
    apply(entreaty);
    if (((true and (2819 != assistances.tongas)) or not(true))) {
      if ((false or (vesting.tolkien < 144))) {
        apply(dislocations);
        apply(stepchilds);
      } else {
        apply(pitfalls);
      }
      apply(fecklessness);
    }
  }
  apply(skulls);
}
