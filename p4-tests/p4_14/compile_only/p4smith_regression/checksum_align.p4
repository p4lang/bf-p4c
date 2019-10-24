/* p4smith seed: 157921321 */
#include <tofino/intrinsic_metadata.p4>
header_type tramps {
  fields {
    fews : 10 (signed, saturating);
    beefburger : 3;
    gimmicks : 16;
    photostatic : 3 (saturating);
    hebert : 48;
  }
}

header_type cupiditys {
  fields {
    acidified : 7;
    brainstorming : 9;
    theilers : 8;
  }
}

header tramps consortiums;

header cupiditys corinths;

register eggs {
  width : 64;
  instance_count : 1;
}

register rookeries {
  width : 8;
  instance_count : 159;
}

register copernican {
  width : 8;
  instance_count : 804;
}

register bunghole {
  width : 8;
  instance_count : 239;
}

parser start {
  return parse_consortiums;
}

parser parse_consortiums {
  extract(consortiums);
  return select (latest.gimmicks) {
    17191 : parse_corinths;
  }
}

parser parse_corinths {
  extract(corinths);
  return ingress;
}

field_list atlantics {
  consortiums.hebert;
  corinths.theilers;
}

field_list demeans {
  consortiums.hebert;
  corinths.theilers;
}

field_list swizzle {
  corinths.theilers;
  consortiums;
}

field_list_calculation levants {
  input {
    demeans;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation sportswears {
  input {
    atlantics;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation renewals {
  input {
    swizzle;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field consortiums.gimmicks {
  update levants;
  update levants;
}

action encouraged() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action winsomest(liberians, aerodynamic) {
  remove_header(consortiums);
  subtract(corinths.theilers, corinths.theilers, 1291331270751128199);
  copy_header(consortiums, consortiums);
}

action wiles(timekeeper, seeped) {
  add(corinths.theilers, 1050740360911648110, corinths.theilers);
}

action bittern(lays, spanner) {
  bit_and(corinths.theilers, corinths.theilers, 528371122627075692);
  add_header(corinths);
  copy_header(consortiums, consortiums);
  modify_field(corinths.acidified, corinths.acidified);
  remove_header(consortiums);
  modify_field_rng_uniform(corinths.brainstorming, 0, 255);
  remove_header(corinths);
}

action coarseness() {
  modify_field_rng_uniform(consortiums.gimmicks, 0, 65535);
}

action_profile fungoid {
  actions {
    winsomest;
    encouraged;
  }
  size : 0;
}

action_profile moustaches {
  actions {
    bittern;
    wiles;
    winsomest;
  }
  size : 12;
}

action_profile papists {
  actions {
    bittern;
    wiles;
    winsomest;
    encouraged;
  }
  size : 14;
}

action_profile lunatics {
  actions {
    wiles;
    winsomest;
  }
  size : 9;
}

table whereas {
  actions {
    encouraged;
    }
  }

table jaundice {
  action_profile : papists;
  }

table derailments {
  reads {
    consortiums.fews : exact;
    consortiums.beefburger : exact;
    consortiums.photostatic : exact;
    consortiums.hebert : exact;
  }
  actions {
    winsomest;
  }
}

table barker {
  actions {
    
    }
  }

table likening {
  reads {
    consortiums : valid;
    consortiums.fews : exact;
    consortiums.beefburger : ternary;
    consortiums.gimmicks : exact;
    consortiums.photostatic : range;
    consortiums.hebert : lpm;
  }
  actions {
    wiles;
  }
}

table bras {
  reads {
    consortiums.fews : exact;
    corinths.theilers mask 6 : ternary;
  }
  actions {
    coarseness;
  }
}

table weirdo {
  reads {
    consortiums : valid;
    corinths : valid;
    corinths.acidified : exact;
    corinths.brainstorming : exact;
  }
  action_profile : moustaches;
}

table inflorescence {
  reads {
    consortiums.photostatic : exact;
    consortiums.hebert : exact;
  }
  action_profile : fungoid;
}

table moulding {
  reads {
    consortiums : valid;
    consortiums.fews : exact;
    consortiums.beefburger : ternary;
    consortiums.gimmicks : exact;
    consortiums.photostatic : ternary;
    consortiums.hebert : exact;
    corinths.acidified : ternary;
    corinths.brainstorming : exact;
    corinths.theilers : ternary;
  }
  action_profile : lunatics;
}

table preferring {
  actions {
    bittern;
    }
  }

table fleshpot {
  reads {
    consortiums : valid;
    consortiums.fews mask 9 : exact;
    consortiums.gimmicks : exact;
    consortiums.photostatic : exact;
    consortiums.hebert : exact;
  }
  actions {
    
  }
}

table schwarzeneggers {
  actions {
    
    }
  }

table semitrailers {
  actions {
    
    }
  }

table tunisia {
  reads {
    consortiums : valid;
    consortiums.fews : exact;
    consortiums.gimmicks mask 11 : ternary;
    consortiums.photostatic : lpm;
    consortiums.hebert mask 10 : exact;
    corinths : valid;
    corinths.acidified : exact;
    corinths.brainstorming : exact;
  }
  actions {
    bittern;
    wiles;
  }
}

table custodians {
  reads {
    corinths.acidified : exact;
    corinths.brainstorming mask 7 : exact;
    corinths.theilers : exact;
  }
  actions {
    
  }
}

control ingress {
  apply(jaundice);
  apply(derailments);
  apply(barker);
  if (((false and false) and not((0 >= consortiums.photostatic)))) {
    apply(likening);
    apply(bras);
  } else {
    apply(weirdo);
  }
  apply(inflorescence);
  apply(moulding);
  if ((corinths.brainstorming <= 253)) {
    
  } else {
    if (true) {
      apply(preferring);
      apply(fleshpot);
      apply(schwarzeneggers);
    } else {
      apply(semitrailers);
    }
    apply(tunisia);
  }
  if (((true or (consortiums.hebert != 664794239)) and
      ((3383 == consortiums.hebert) or valid(corinths)))) {
    
  } else {
    apply(custodians);
  }
}
