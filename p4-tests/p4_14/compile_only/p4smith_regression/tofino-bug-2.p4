/* p4smith seed: 412812955 */
#include <tofino/intrinsic_metadata.p4>
header_type codpiece {
  fields {
    adjectives : 48;
    ethnocentrisms : 8;
  }
}

header_type showgirls {
  fields {
    rubberiest : 8 (saturating);
    kaye : 16;
    shampooers : 32;
    rich : 128;
    paraprofessionals : 8 (signed);
    perceptibly : 48;
  }
}

header_type flanges {
  fields {
    narratives : 8 (saturating);
    pressies : 128;
    occupy : 64;
    incisions : 64;
    victuals : 16 (signed, saturating);
  }
}

header_type funniness {
  fields {
    prettys : 128;
  }
}

header_type romero {
  fields {
    partisans : 128;
    colour : 32 (signed);
    scaliness : 8;
    chlorofluorocarbons : 16;
    transvestite : 128;
  }
}

header codpiece unimpressive;

header showgirls menaces;

header flanges orchestrating;

header funniness enchantress;

header romero pronged;

parser start {
  return parse_unimpressive;
}

parser parse_unimpressive {
  extract(unimpressive);
  return select (latest.ethnocentrisms) {
    68 : parse_menaces;
  }
}

parser parse_menaces {
  extract(menaces);
  return select (latest.kaye) {
    8952 : parse_orchestrating;
  }
}

parser parse_orchestrating {
  extract(orchestrating);
  return select (current(0, 8)) {
    46 : parse_enchantress;
  }
}

parser parse_enchantress {
  extract(enchantress);
  return select (current(0, 8)) {
    90 : parse_pronged;
  }
}

parser parse_pronged {
  extract(pronged);
  return ingress;
}

field_list tubs {
  unimpressive.adjectives;
  pronged.colour;
  orchestrating.victuals;
  menaces.shampooers;
  enchantress;
  orchestrating.occupy;
  orchestrating.pressies;
}

field_list vinous {
  unimpressive.adjectives;
  pronged.colour;
  menaces.perceptibly;
}

field_list defencelessnesss {
  orchestrating.narratives;
  unimpressive.adjectives;
  unimpressive.ethnocentrisms;
  orchestrating.occupy;
  pronged.partisans;
  orchestrating.incisions;
  menaces.paraprofessionals;
  enchantress.prettys;
  menaces.kaye;
}

field_list_calculation outraced {
  input {
    vinous;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation terminate {
  input {
    tubs;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation forthright {
  input {
    defencelessnesss;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation mindfulnesss {
  input {
    defencelessnesss;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field menaces.kaye {
  verify mindfulnesss;
}

action travestying(val) {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, val);
}

action rasmussens() {
  subtract(pronged.chlorofluorocarbons, menaces.kaye, 34821);
  bit_or(menaces.kaye, menaces.kaye, orchestrating.victuals);
  remove_header(pronged);
  copy_header(unimpressive, unimpressive);
  subtract(pronged.colour, menaces.shampooers, pronged.colour);
}

action homonyms(slammer) {
  add_to_field(pronged.scaliness, 25);
  subtract(orchestrating.victuals, 20003, orchestrating.victuals);
}

action_profile divas {
  actions {
    travestying;
  }
  size : 9;
}

table pompano {
  actions {
    travestying;
    }
  }

table sf {
  reads {
    unimpressive : valid;
    unimpressive.adjectives : exact;
    menaces : valid;
    menaces.rubberiest : lpm;
    menaces.kaye : exact;
    menaces.shampooers : ternary;
    menaces.paraprofessionals : exact;
    orchestrating : valid;
    orchestrating.narratives : ternary;
    orchestrating.pressies : exact;
    orchestrating.occupy : ternary;
    orchestrating.victuals : ternary;
    enchantress.prettys mask 183 : exact;
    pronged : valid;
    pronged.colour : exact;
    pronged.scaliness mask 10 : exact;
  }
  action_profile : divas;
}

table archaeologys {
  actions {
    homonyms;
    rasmussens;
    }
  }

table monorail {
  reads {
    orchestrating : valid;
    orchestrating.narratives : lpm;
    orchestrating.victuals : exact;
    enchantress : valid;
  }
  actions {
    homonyms;
    travestying;
  }
}

control ingress {
  apply(sf);
  apply(archaeologys);
  if (valid(menaces)) {
    
  }
  apply(monorail);
}
