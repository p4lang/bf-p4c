/* p4smith seed: 485853521 */
#include <tofino/intrinsic_metadata.p4>
header_type alphabetize {
  fields {
    sweeties : 8 (saturating);
    litheness : 48;
  }
}

header_type skippering {
  fields {
    sophistical : 16;
    cough : 48;
    shakas : 48;
    gibberishs : 16;
    transgressors : 16;
  }
}

header_type swooshing {
  fields {
    mamies : 8 (signed);
    genies : 16 (signed, saturating);
    showstopping : 64;
  }
}

header_type dawns {
  fields {
    acupressures : 16 (signed, saturating);
    plans : 32;
    influential : 32;
    campaigners : 32;
    horsemanships : 32;
    centimeters : 16;
  }
}

header_type pyrex {
  fields {
    hysterectomys : 8;
    lads : 48 (saturating);
    relocations : 8 (saturating);
  }
}

header alphabetize suitably;

header skippering ditransitive;

header swooshing lilliputians;

header dawns uncertainty;

header pyrex subteens;

register flabbily {
  width : 128;
  instance_count : 242;
}

register methane {
  width : 8;
  instance_count : 137;
}

register ballgirls {
  width : 16;
  instance_count : 1;
}

register grandpas {
  width : 128;
  instance_count : 245;
}

register mottoes {
  width : 64;
  instance_count : 430;
}

register sparkier {
  width : 64;
  instance_count : 682;
}

register intaglios {
  width : 8;
  instance_count : 931;
}

parser start {
  return parse_suitably;
}

parser parse_suitably {
  extract(suitably);
  return select (latest.sweeties) {
    7 : parse_uncertainty;
    193 : parse_ditransitive;
    171 : parse_lilliputians;
  }
}

parser parse_ditransitive {
  extract(ditransitive);
  return select (latest.sophistical) {
    61631 : parse_uncertainty;
    29765 : parse_lilliputians;
  }
}

parser parse_lilliputians {
  extract(lilliputians);
  return select (latest.mamies) {
    26 : parse_uncertainty;
  }
}

parser parse_uncertainty {
  extract(uncertainty);
  return select (current(0, 8)) {
    155 : parse_subteens;
  }
}

parser parse_subteens {
  extract(subteens);
  return ingress;
}

field_list observances {
  ditransitive.sophistical;
  lilliputians.genies;
  ditransitive.cough;
}

field_list brotherhoods {
  suitably;
  lilliputians.showstopping;
  subteens.relocations;
  13;
  uncertainty.acupressures;
  subteens.hysterectomys;
  suitably.litheness;
  subteens.relocations;
}

field_list escapology {
  ditransitive.sophistical;
  lilliputians.mamies;
  uncertainty.acupressures;
  lilliputians.genies;
  uncertainty.plans;
  lilliputians.mamies;
}

field_list_calculation bamboozling {
  input {
    brotherhoods;
  }
  algorithm : csum16;
  output_width : 64;
}

field_list_calculation contrapuntal {
  input {
    brotherhoods;
    observances;
  }
  algorithm : xor16;
  output_width : 8;
}

field_list_calculation naively {
  input {
    observances;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field lilliputians.genies {
  verify naively;
}

action apologist() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action blowtorch(overpraise, monastics) {
  bit_xor(uncertainty.influential, uncertainty.influential, uncertainty.plans);
}

action castor() {
  add_to_field(uncertainty.acupressures, lilliputians.genies);
  modify_field(suitably.sweeties, subteens.hysterectomys);
}

action mistresses(temptations, mistreatments) {
  bit_xor(uncertainty.influential, 1785879877, uncertainty.horsemanships);
  register_write(methane, 33, subteens.relocations);
  add_to_field(lilliputians.mamies, subteens.hysterectomys);
  modify_field(ditransitive.gibberishs, ditransitive.transgressors);
}

action dairymaids(rappelled) {
  remove_header(lilliputians);
  add_header(uncertainty);
  bit_xor(uncertainty.centimeters, lilliputians.genies, uncertainty.acupressures);
  add_header(ditransitive);
  remove_header(subteens);
}

table october {
  actions {
    apologist;
    }
  }

table scrambler {
  reads {
    ditransitive.cough mask 94 : ternary;
    uncertainty.acupressures : exact;
    uncertainty.plans mask 158 : exact;
    uncertainty.influential mask 39 : exact;
    uncertainty.campaigners mask 212 : range;
  }
  actions {
    apologist;
    castor;
    dairymaids;
  }
}

table torpiditys {
  reads {
    lilliputians : valid;
    lilliputians.genies : ternary;
  }
  actions {
    mistresses;
  }
}

table sucker {
  reads {
    suitably : valid;
    suitably.litheness : range;
  }
  actions {
    blowtorch;
    castor;
    mistresses;
  }
}

control ingress {
  apply(october);
  if (true) {
    apply(scrambler);
  }
  if (((false and (lilliputians.mamies == subteens.hysterectomys)) or false)) {
    apply(torpiditys);
  }
  apply(sucker);
}
