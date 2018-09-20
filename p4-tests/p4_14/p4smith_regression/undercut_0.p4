/* p4smith seed: 889246439 */
#include <tofino/intrinsic_metadata.p4>
header_type yowling {
  fields {
    pedigrees : 8 (saturating);
    koran : 32;
    tonsils : 16 (signed);
    enabling : 8 (signed);
    ruiz : 16;
  }
}

header_type fiscals {
  fields {
    carmines : 16 (saturating);
  }
}

header_type formulators {
  fields {
    enthrones : 16 (signed);
    exampling : 48;
  }
}

header_type aliment {
  fields {
    reparation : 16 (signed, saturating);
    defecating : 8;
    munchies : 8;
    accessible : 64 (signed, saturating);
  }
}

header_type nonbasic {
  fields {
    garnishs : 16 (saturating);
    inflicting : 16;
    impermanently : 32;
    workers : 8 (signed);
    barentss : 48;
    swelter : 128 (signed);
  }
}

header_type goldbricked {
  fields {
    boatload : 16;
    duellist : 64 (signed, saturating);
  }
}

header yowling examinations;

header fiscals twigs;

header formulators anaerobes;

header aliment est;

header nonbasic hamper;

header goldbricked lingual;

register garlics {
  width : 32;
  instance_count : 1;
}

register neuralgic {
  width : 128;
  instance_count : 184;
}

register phonecards {
  width : 128;
  instance_count : 618;
}

parser start {
  return parse_examinations;
}

parser parse_examinations {
  extract(examinations);
  return select (latest.ruiz) {
    58118 : parse_twigs;
  }
}

parser parse_twigs {
  extract(twigs);
  return select (latest.carmines) {
    15782 : parse_est;
    6094 : parse_anaerobes;
  }
}

parser parse_anaerobes {
  extract(anaerobes);
  return select (latest.enthrones) {
    4803 : parse_est;
  }
}

parser parse_est {
  extract(est);
  return select (latest.munchies) {
    255 : parse_lingual;
    38 : parse_hamper;
  }
}

parser parse_hamper {
  extract(hamper);
  return select (latest.garnishs) {
    56229 : parse_lingual;
  }
}

parser parse_lingual {
  extract(lingual);
  return ingress;
}

field_list sorceresses {
  anaerobes.exampling;
  lingual.boatload;
  hamper.swelter;
}

field_list purged {
  lingual;
  122;
  hamper;
  examinations.pedigrees;
  examinations.tonsils;
  examinations.enabling;
  est.defecating;
  est.accessible;
  hamper.swelter;
  est.munchies;
  109;
  est;
  hamper.swelter;
  est.accessible;
}

field_list_calculation understudied {
  input {
    purged;
  }
  algorithm : crc32;
  output_width : 48;
}

field_list_calculation naturalizations {
  input {
    purged;
  }
  algorithm : xor16;
  output_width : 48;
}

field_list_calculation jogs {
  input {
    sorceresses;
  }
  algorithm : crc16;
  output_width : 16;
}

field_list_calculation gunfire {
  input {
    sorceresses;
  }
  algorithm : xor16;
  output_width : 16;
}

calculated_field est.accessible {
  update understudied if (valid(examinations));
  verify jogs;
}

action unshackles() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action megalopolis(aggrandizement, pettifogged) {
  subtract_from_field(anaerobes.enthrones, est.reparation);
  add_header(est);
}

action dentifrices(musts) {
  bit_xor(examinations.koran, examinations.koran, examinations.koran);
  add(hamper.workers, 114, est.defecating);
  add(examinations.pedigrees, est.munchies, est.defecating);
}

action begin(rules, defrauded) {
  add_header(twigs);
  bit_xor(examinations.pedigrees, examinations.pedigrees, est.munchies);
  add_header(twigs);
  add(est.munchies, 184, hamper.workers);
  remove_header(lingual);
  add(hamper.impermanently, hamper.impermanently, hamper.impermanently);
  copy_header(twigs, twigs);
}

table sanitys {
  actions {
    unshackles;
    }
  }

table neal {
  reads {
    examinations.pedigrees mask 10 : ternary;
    examinations.tonsils mask 208 : range;
    examinations.enabling : lpm;
    examinations.ruiz : exact;
    twigs : valid;
    twigs.carmines : lpm;
    anaerobes : valid;
    anaerobes.enthrones mask 202 : exact;
  }
  actions {
    megalopolis;
  }
}

table elapsing {
  actions {
    begin;
    dentifrices;
    unshackles;
    }
  }

table broadsword {
  reads {
    examinations : valid;
    examinations.pedigrees mask 122 : range;
    examinations.koran : range;
    examinations.enabling mask 190 : lpm;
  }
  actions {
    dentifrices;
    megalopolis;
  }
}

table basally {
  actions {
    begin;
    megalopolis;
    unshackles;
    }
  }

control ingress {
  if ((est.defecating > 42)) {
    apply(sanitys);
  }
  if ((true and (valid(lingual) and false))) {
    apply(neal);
  }
  apply(elapsing);
  if ((true or ((false or false) and (valid(lingual) and (false and (
                                                                    1426471903 != 
                                                                    est.munchies)))))) {
    apply(broadsword);
  }
  apply(basally);
}
