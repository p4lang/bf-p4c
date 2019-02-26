/* p4smith seed: 385281822 */
#include <tofino/intrinsic_metadata.p4>
header_type proprietresss {
  fields {
    manumissions : 7;
    steinmetz : 8;
    dumpy : 32;
    fibber : 12;
    syncopation : 3 (signed);
    bulged : 10;
    thomisms : 16;
  }
}

header_type refrigeration {
  fields {
    wrapped : 2;
    kentuckian : 4 (signed, saturating);
    regret : 8;
    pretender : 6 (signed);
    blubbering : 10;
    expounded : 10 (saturating);
    mirfaks : 8;
  }
}

header proprietresss painful;

header refrigeration fiats;

parser start {
  return parse_painful;
}

parser parse_painful {
  extract(painful);
  return select (latest.fibber) {
    1903 : parse_fiats;
  }
}

parser parse_fiats {
  extract(fiats);
  return ingress;
}

field_list ecu {
  painful.thomisms;
  fiats.mirfaks;
}

field_list_calculation hourly {
  input {
    ecu;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation islamisms {
  input {
    ecu;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation undersecretary {
  input {
    ecu;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation undramatic {
  input {
    ecu;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field painful.thomisms {
  update hourly;
  verify undersecretary;
  verify undersecretary;
}

action flares() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action defensively() {
  add(fiats.mirfaks, 3356543929101848791, 4216615770154023102);
  bit_xor(painful.thomisms, 0, painful.thomisms);
  modify_field_rng_uniform(fiats.kentuckian, 0, 7);
  modify_field(fiats.wrapped, fiats.wrapped);
}

action disorientation(septuagenarian, crops) {
  remove_header(painful);
  modify_field_rng_uniform(painful.steinmetz, 0, 255);
}

action danging(amniocenteses, chatterley, sideswipes) {
  bit_and(painful.thomisms, painful.thomisms, 3647002098269667360);
  remove_header(painful);
  bit_and(fiats.mirfaks, fiats.mirfaks, fiats.mirfaks);
  remove_header(painful);
  modify_field_rng_uniform(painful.manumissions, 0, 7);
  modify_field_rng_uniform(fiats.expounded, 0, 255);
  modify_field_rng_uniform(fiats.kentuckian, 0, 3);
}

action humbleness(earline, longboats) {
  subtract(fiats.mirfaks, fiats.mirfaks, fiats.mirfaks);
  modify_field(fiats.blubbering, fiats.expounded);
  bit_or(painful.thomisms, painful.thomisms, 1128732763563970913);
  remove_header(fiats);
  modify_field(painful.steinmetz, 255);
  add_header(fiats);
  modify_field_rng_uniform(painful.fibber, 0, 511);
  modify_field(fiats.regret, 53);
}

action_profile clone {
  actions {
    humbleness;
    danging;
    disorientation;
  }
  size : 13;
}

action_profile abrupter {
  actions {
    danging;
    disorientation;
    defensively;
    flares;
  }
  size : 25;
}

action_profile sowers {
  actions {
    humbleness;
    danging;
    disorientation;
  }
  size : 26;
}

action_profile vended {
  actions {
    humbleness;
    danging;
    disorientation;
    flares;
  }
  size : 6;
}

table citizens {
  actions {
    flares;
    }
  }

table whens {
  actions {
    defensively;
    disorientation;
    }
  }

table romanticism {
  action_profile : clone;
  }

table philatelic {
  reads {
    fiats : valid;
    fiats.kentuckian : exact;
    fiats.regret : ternary;
    fiats.pretender : exact;
  }
  action_profile : vended;
}

table jocularity {
  actions {
    disorientation;
    humbleness;
    }
  }

control ingress {
  apply(whens);
  if (not(((207 <= fiats.regret) and (painful.thomisms == painful.thomisms)))) {
    
  } else {
    apply(romanticism);
    apply(philatelic);
  }
  apply(jocularity);
}
