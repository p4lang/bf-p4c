/* p4smith seed: 521037580 */
#include <tofino/intrinsic_metadata.p4>
header_type solderers {
  fields {
    stepping : 16;
    desires : 32;
  }
}

header_type fates {
  fields {
    gamma : 32;
    ghostwriter : 8;
  }
}

header_type irresolutenesss {
  fields {
    rachmaninoff : 8;
    bunkhouses : 128;
  }
}

header_type ox {
  fields {
    decibels : 8;
    adjourned : 16 (saturating);
    crockett : 16 (signed, saturating);
    definitenesss : 128;
  }
}

header solderers marinaras;

header fates paterfamiliass;

header irresolutenesss clamours;

header ox showering;

parser start {
  return parse_marinaras;
}

parser parse_marinaras {
  extract(marinaras);
  return select (current(0, 8)) {
    223 : parse_paterfamiliass;
  }
}

parser parse_paterfamiliass {
  extract(paterfamiliass);
  return select (current(0, 8)) {
    71 : parse_clamours;
  }
}

parser parse_clamours {
  extract(clamours);
  return select (current(0, 8)) {
    134 : parse_showering;
  }
}

parser parse_showering {
  extract(showering);
  return ingress;
}

field_list mortising {
  showering.definitenesss;
  clamours.bunkhouses;
  clamours.bunkhouses;
  marinaras.desires;
  showering.adjourned;
  showering.definitenesss;
  paterfamiliass.gamma;
}

field_list honorific {
  showering.definitenesss;
  clamours.rachmaninoff;
  marinaras;
  clamours;
  marinaras.desires;
  showering.definitenesss;
  paterfamiliass.gamma;
  showering.definitenesss;
  marinaras.stepping;
  showering;
}

field_list_calculation drawings {
  input {
    honorific;
  }
  algorithm : csum16;
  output_width : 32;
}

field_list_calculation unprepared {
  input {
    mortising;
  }
#ifdef __p4c__
  algorithm : csum16;
#else
  algorithm : xor16;
#endif
  output_width : 16;
}

field_list_calculation trustworthiest {
  input {
    honorific;
  }
  algorithm : csum16;
  output_width : 48;
}

field_list_calculation farrakhan {
  input {
    honorific;
  }
#ifdef __p4c__
  algorithm : csum16;
#else
  algorithm : xor16;
#endif
  output_width : 16;
}

calculated_field clamours.bunkhouses {
#ifdef __p4c__
  update unprepared;
  verify farrakhan;
  update farrakhan;
  verify farrakhan;
#else
  update unprepared if (clamours.bunkhouses == 60);
  verify farrakhan if (paterfamiliass.gamma == 14);
  update farrakhan;
  verify farrakhan if (valid(clamours));
#endif
}

calculated_field clamours.rachmaninoff {
#ifdef __p4c__
  verify trustworthiest;
  update unprepared;
#else
  verify trustworthiest if (marinaras.stepping == 15);
  update unprepared if (valid(showering));
#endif
}

calculated_field paterfamiliass.gamma {
#ifdef __p4c__
  verify drawings;
  update unprepared;
  update drawings;
  update drawings;
#else
  verify drawings if (clamours.bunkhouses == 112);
  update unprepared if (valid(marinaras));
  update drawings if (valid(clamours));
  update drawings;
#endif
}

action orientals() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action josefa(egoisms, imperiousness) {
  bit_xor(showering.adjourned, showering.adjourned, showering.crockett);
  copy_header(clamours, clamours);
}

action moderators() {
  remove_header(marinaras);
  modify_field(marinaras.stepping, showering.adjourned);
  add_header(marinaras);
  copy_header(clamours, clamours);
  bit_xor(showering.crockett, showering.crockett, showering.crockett);
}

action consummation(bursarys, whale) {
  subtract(paterfamiliass.ghostwriter, 243, showering.decibels);
  modify_field(showering.crockett, marinaras.stepping);
  copy_header(clamours, clamours);
  add_header(marinaras);
  remove_header(paterfamiliass);
  add(showering.adjourned, showering.adjourned, 10608);
  bit_and(showering.decibels, showering.decibels, showering.decibels);
  add_to_field(marinaras.desires, 268865437);
}

action issuance() {
  modify_field(marinaras.stepping, showering.crockett);
  subtract(marinaras.desires, 162046532, paterfamiliass.gamma);
  add(showering.crockett, showering.crockett, 10662);
}

table sammys {
  actions {
    orientals;
    }
  }

table assaulter {
  reads {
    showering : valid;
    showering.decibels mask 101 : range;
  }
  actions {
    josefa;
    orientals;
  }
}

table sucker {
  reads {
    marinaras.stepping mask 243 : ternary;
    marinaras.desires : ternary;
  }
  actions {
    consummation;
    josefa;
  }
}

control ingress {
  if (not((marinaras.stepping >= 113))) {
    apply(sammys);
  }
  if (valid(paterfamiliass)) {
    apply(assaulter);
  }
  apply(sucker);
}
