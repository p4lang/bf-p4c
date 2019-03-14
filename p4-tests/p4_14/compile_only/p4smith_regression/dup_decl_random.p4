/* p4smith seed: 752284071 */
#include <tofino/intrinsic_metadata.p4>
header_type colts {
  fields {
    priestesses : 5;
    premiere : 12;
    ogbomosho : 48 (signed);
    dobbins : 7 (signed, saturating);
    rope : 16 (saturating);
    tribunals : 8;
    prioritize : 8;
  }
}

header_type delineation {
  fields {
    macaques : 2;
    retype : 6;
  }
}

header_type mayan {
  fields {
    illegibly : 4;
    demigods : 32;
    decencys : 10 (saturating);
    contradiction : 16;
    blocks : 32;
    battlers : 10 (signed, saturating);
    conspirator : 8;
  }
}

header_type cirques {
  fields {
    afterglows : 12 (signed, saturating);
    antigone : 16 (signed);
    prettiest : 4;
  }
}

header colts bedazzlement;

header delineation oboists;

header mayan rents;

header cirques saleswomen;

register penumbra {
  width : 64;
  instance_count : 718;
}

register crap {
  width : 16;
  instance_count : 829;
}

register refugees {
  width : 32;
  instance_count : 618;
}

register carney {
  width : 32;
  instance_count : 1009;
}

register horizontally {
  width : 16;
  instance_count : 602;
}

register valvular {
  width : 32;
  instance_count : 614;
}

parser start {
  return parse_bedazzlement;
}

parser parse_bedazzlement {
  extract(bedazzlement);
  return select (latest.tribunals) {
    83 : parse_saleswomen;
    13 : parse_oboists;
    56 : parse_rents;
  }
}

parser parse_oboists {
  extract(oboists);
  return select (latest.macaques) {
    1 : parse_rents;
  }
}

parser parse_rents {
  extract(rents);
  return select (latest.contradiction) {
    10220 : parse_saleswomen;
  }
}

parser parse_saleswomen {
  extract(saleswomen);
  return ingress;
}

field_list bridesmaids {
  bedazzlement.prioritize;
  bedazzlement.tribunals;
  bedazzlement.rope;
}

field_list blondest {
  bedazzlement.tribunals;
  bedazzlement.rope;
  bedazzlement.prioritize;
  rents.conspirator;
}

field_list_calculation xvii {
  input {
    bridesmaids;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation schooner {
  input {
    bridesmaids;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field rents.contradiction {
  verify schooner;
  update xvii;
  update schooner;
  verify xvii;
}

calculated_field saleswomen.antigone {
  update xvii;
  update xvii;
  verify xvii;
}

calculated_field bedazzlement.rope {
  update xvii;
  update schooner;
  verify schooner;
}

action seer() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action astringencys(ls, superstate) {
  remove_header(rents);
  bit_and(bedazzlement.rope, bedazzlement.rope, 1724482924883068555);
  modify_field_rng_uniform(oboists.macaques, 0, 7);
  bit_xor(bedazzlement.prioritize, bedazzlement.tribunals, bedazzlement.prioritize);
}

action headland(exalts) {
  bit_xor(bedazzlement.rope, bedazzlement.rope, bedazzlement.rope);
  remove_header(bedazzlement);
  bit_or(rents.conspirator, bedazzlement.tribunals, bedazzlement.prioritize);
  bit_and(bedazzlement.prioritize, bedazzlement.prioritize, bedazzlement.tribunals);
  subtract_from_field(bedazzlement.tribunals, bedazzlement.tribunals);
}

action_profile subtrahends {
  actions {
    astringencys;
    seer;
  }
  size : 19;
}

action_profile mcknights {
  actions {
    astringencys;
    seer;
  }
  size : 5;
}

action_profile cardin {
  actions {
    headland;
    astringencys;
    seer;
  }
  size : 24;
}

table gravimeter {
  actions {
    seer;
    }
  }

table random {
  actions {
    astringencys;
    headland;
    }
  }

table battlefields {
  reads {
    bedazzlement : valid;
    oboists : valid;
  }
  action_profile : cardin;
}

table polygamys {
  reads {
    bedazzlement.priestesses : exact;
    bedazzlement.tribunals mask 0 : lpm;
    rents : valid;
    rents.illegibly : range;
    saleswomen.antigone : ternary;
    saleswomen.prettiest : exact;
  }
  actions {
    astringencys;
  }
}

table copperfields {
  reads {
    bedazzlement : valid;
    bedazzlement.priestesses mask 0 : lpm;
    bedazzlement.tribunals : exact;
    bedazzlement.prioritize : exact;
    oboists.macaques : ternary;
    oboists.retype : exact;
    saleswomen : valid;
    saleswomen.afterglows : ternary;
  }
  actions {
    astringencys;
    headland;
  }
}

table sight {
  reads {
    bedazzlement.ogbomosho : lpm;
    bedazzlement.dobbins mask 4 : ternary;
    bedazzlement.rope : exact;
    bedazzlement.tribunals : exact;
    bedazzlement.prioritize : ternary;
    oboists : valid;
    rents : valid;
    rents.illegibly : exact;
    rents.demigods : ternary;
    rents.contradiction : ternary;
    rents.blocks : ternary;
  }
  actions {
    
  }
}

table sauced {
  actions {
    astringencys;
    seer;
    }
  }

table warings {
  actions {
    
    }
  }

table impassably {
  reads {
    oboists : valid;
  }
  action_profile : mcknights;
}

table deceases {
  reads {
    bedazzlement.dobbins : exact;
    bedazzlement.tribunals : lpm;
    bedazzlement.prioritize : exact;
  }
  action_profile : subtrahends;
}

table touches {
  reads {
    oboists.macaques : exact;
  }
  actions {
    
  }
}

table donovan {
  reads {
    oboists : valid;
    oboists.macaques : exact;
    oboists.retype : exact;
    rents.battlers : exact;
    rents.conspirator : exact;
  }
  actions {
    headland;
    seer;
  }
}

table truer {
  reads {
    bedazzlement : valid;
    bedazzlement.prioritize : lpm;
    oboists.retype mask 5 : exact;
    rents.illegibly : range;
    rents.conspirator : exact;
    saleswomen : valid;
    saleswomen.afterglows : exact;
    saleswomen.prettiest mask 1 : exact;
  }
  actions {
    headland;
  }
}

table defaced {
  reads {
    bedazzlement.premiere mask 3 : range;
    bedazzlement.ogbomosho : lpm;
    bedazzlement.dobbins : ternary;
    bedazzlement.tribunals : ternary;
    bedazzlement.prioritize : exact;
    oboists : valid;
    oboists.retype mask 0 : exact;
    rents : valid;
    rents.illegibly : exact;
    rents.demigods : ternary;
    rents.contradiction : exact;
    rents.battlers : exact;
    rents.conspirator : exact;
  }
  actions {
    astringencys;
    headland;
    seer;
  }
}

table throe {
  reads {
    saleswomen.afterglows : exact;
    saleswomen.antigone : ternary;
    saleswomen.prettiest : exact;
  }
  actions {
    
  }
}

table augustness {
  reads {
    bedazzlement.priestesses : exact;
    bedazzlement.premiere : exact;
    bedazzlement.ogbomosho : exact;
    bedazzlement.dobbins : exact;
    bedazzlement.rope mask 7 : exact;
    oboists : valid;
    rents : valid;
    rents.demigods mask 0 : ternary;
    rents.decencys : exact;
    rents.blocks : exact;
    rents.conspirator : exact;
    saleswomen : valid;
    saleswomen.afterglows mask 2 : lpm;
    saleswomen.antigone : exact;
    saleswomen.prettiest : exact;
  }
  actions {
    astringencys;
  }
}

table hematites {
  actions {
    astringencys;
    seer;
    }
  }

table cutlasss {
  reads {
    bedazzlement : valid;
    bedazzlement.priestesses mask 2 : exact;
    bedazzlement.premiere : exact;
    bedazzlement.dobbins mask 3 : exact;
    bedazzlement.tribunals : exact;
    bedazzlement.prioritize : exact;
  }
  actions {
    seer;
  }
}

table whiteners {
  reads {
    bedazzlement : valid;
    bedazzlement.priestesses : exact;
    bedazzlement.premiere : lpm;
    bedazzlement.dobbins : exact;
    bedazzlement.rope : ternary;
    oboists : valid;
    rents : valid;
    rents.demigods : ternary;
    rents.blocks : exact;
    rents.battlers : ternary;
    rents.conspirator mask 0 : exact;
    saleswomen : valid;
    saleswomen.prettiest : exact;
  }
  actions {
    
  }
}

table honourably {
  reads {
    bedazzlement : valid;
    bedazzlement.ogbomosho : lpm;
    bedazzlement.rope : exact;
    bedazzlement.tribunals : ternary;
    rents : valid;
    rents.illegibly : exact;
    rents.demigods mask 31 : exact;
    rents.blocks : exact;
    saleswomen.antigone mask 12 : ternary;
    saleswomen.prettiest : exact;
  }
  actions {
    headland;
  }
}

table gateposts {
  actions {
    astringencys;
    headland;
    }
  }

table bibles {
  actions {
    
    }
  }

table trolls {
  reads {
    saleswomen.prettiest : exact;
  }
  actions {
    seer;
  }
}

table carbonated {
  reads {
    saleswomen : valid;
    saleswomen.antigone : lpm;
    saleswomen.prettiest : exact;
  }
  actions {
    astringencys;
    seer;
  }
}

control ingress {
  apply(random);
  if (((false and true) or (false and true))) {
    if ((60 > 623)) {
      
    } else {
      apply(battlefields);
      apply(polygamys);
    }
    apply(copperfields);
    if (((bedazzlement.prioritize != bedazzlement.tribunals) or valid(rents))) {
      apply(sight);
      apply(sauced);
      apply(warings);
    }
  } else {
    if (not((1929 != bedazzlement.prioritize))) {
      apply(impassably);
      apply(deceases);
    } else {
      apply(touches);
    }
    apply(donovan);
    apply(truer);
  }
  if (((rents.battlers <= 158) and false)) {
    apply(defaced);
    if ((false and (rents.conspirator != bedazzlement.prioritize))) {
      
    } else {
      apply(throe);
      apply(augustness);
      apply(hematites);
    }
  } else {
    apply(cutlasss);
    apply(whiteners);
    if (((false or true) and ((bedazzlement.rope != 54247) or
        valid(saleswomen)))) {
      apply(honourably);
      apply(gateposts);
      apply(bibles);
    }
  }
  apply(trolls);
  apply(carbonated);
}
