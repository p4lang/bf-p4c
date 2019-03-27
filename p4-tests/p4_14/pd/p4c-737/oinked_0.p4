/* p4smith seed: 197318280 */
#include <tofino/intrinsic_metadata.p4>
header_type blowtorchs {
  fields {
    conjecture : 32;
    backwoods : 48;
    buddies : 16;
    gazetteer : 64;
    helmholtzs : 48;
    altimeter : 16;
  }
}

header_type extortioners {
  fields {
    mesons : 16;
    sinkholes : 48;
    accommodate : 32;
    hairinesss : 8;
    nonsupport : 32;
  }
}

header_type insularity {
  fields {
    unaccountably : 32;
    schedules : 16;
    endeavouring : 16;
    incorrect : 48;
    sysadmin : 32;
    crosspatch : 16;
  }
}

header_type u {
  fields {
    seawater : 48;
    crayon : 48;
    quay : 32;
  }
}

header_type complexities {
  fields {
    garrulous : 8;
    pants : 8;
    manageress : 16;
  }
}

header_type phylactery {
  fields {
    ranchings : 16;
    gleefulness : 32;
    grab : 48;
    thrasher : 32;
    furzes : 16;
    atheists : 48;
  }
}

header blowtorchs handiest;

header extortioners taggers;

header insularity noels;

header u motors;

header complexities refinance;

header phylactery carryout;

parser start {
  return parse_handiest;
}

parser parse_handiest {
  extract(handiest);
  return select (latest.altimeter) {
    55999 : parse_refinance;
    57310 : parse_taggers;
    16515 : parse_noels;
  }
}

parser parse_taggers {
  extract(taggers);
  return select (latest.mesons) {
    5189 : parse_refinance;
    4793 : parse_noels;
  }
}

parser parse_noels {
  extract(noels);
  return select (current(0, 8)) {
    64 : parse_motors;
  }
}

parser parse_motors {
  extract(motors);
  return select (current(0, 8)) {
    0 : parse_refinance;
  }
}

parser parse_refinance {
  extract(refinance);
  return select (latest.manageress) {
    7329 : parse_carryout;
  }
}

parser parse_carryout {
  extract(carryout);
  return ingress;
}

action spillways() {
  modify_field(standard_metadata.egress_spec, 1);
}

action awfullest(charm, actualized) {
  bit_xor(noels.unaccountably, taggers.accommodate, noels.unaccountably);
  bit_or(carryout.thrasher, 596145274, carryout.thrasher);
  subtract_from_field(motors.quay, handiest.conjecture);
  add(handiest.buddies, handiest.helmholtzs, handiest.backwoods);
}

action downloads(ministers, ungraceful) {
  bit_and(motors.quay, handiest.conjecture, handiest.conjecture);
  bit_or(handiest.helmholtzs, carryout.atheists, carryout.atheists);
}

action expensively() {
  modify_field(refinance.garrulous, 96);
  add(carryout.furzes, carryout.furzes, 28111);
  modify_field(refinance.pants, 8);
}

action luxembourgers(penmen, restraints) {
  add(carryout.gleefulness, taggers.hairinesss, refinance.pants);
  bit_or(handiest.backwoods, 875777089, handiest.helmholtzs);
  bit_xor(noels.unaccountably, carryout.thrasher, taggers.nonsupport);
  add(motors.quay, handiest.conjecture, carryout.thrasher);
}

table whooping {
  actions {
    spillways;
    }
  }

table perigees {
  actions {
    downloads;
    expensively;
    spillways;
    }
  }

control ingress {
  if ((taggers.accommodate == carryout.gleefulness)) {
    apply(whooping);
  }
  apply(perigees);
}
