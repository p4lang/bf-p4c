/* p4smith seed: 508607341 */
#include <tofino/intrinsic_metadata.p4>
header_type eyesores {
  fields {
    reasserting : 128 (saturating);
    airdropping : 8;
  }
}

header_type demographys {
  fields {
    bullring : 32 (signed, saturating);
  }
}

header_type marketers {
  fields {
    zebu : 32 (signed, saturating);
    plot : 16 (signed, saturating);
    violoncellos : 8 (signed);
  }
}

header_type delays {
  fields {
    fiats : 128 (signed);
  }
}

header_type staceys {
  fields {
    occupations : 8;
    bellyful : 8 (saturating);
    reactivated : 128;
    kitschy : 8;
    diarists : 16;
  }
}

header_type peekaboo {
  fields {
    blackthorn : 32;
    layoffs : 48;
    impenetrabilitys : 8;
    glitched : 32 (saturating);
    quartermasters : 8;
    casehardens : 32;
  }
}

header_type potency {
  fields {
    adjudicate : 64 (signed);
    chalet : 64 (signed);
    tautologys : 128;
    plethora : 32 (saturating);
    rediscover : 64;
    cave : 128 (signed, saturating);
  }
}

header eyesores shrug;

header demographys spavined;

header marketers corrosion;

header delays republish;

header staceys officiating;

header peekaboo proclaiming;

header potency waives;

register necked {
  width : 64;
  instance_count : 1;
}

parser start {
  return parse_shrug;
}

parser parse_shrug {
  extract(shrug);
  return select (latest.airdropping) {
    2 : parse_spavined;
  }
}

parser parse_spavined {
  extract(spavined);
  return select (current(0, 8)) {
    127 : parse_republish;
    116 : parse_corrosion;
    76 : parse_proclaiming;
  }
}

parser parse_corrosion {
  extract(corrosion);
  return select (latest.plot) {
    23920 : parse_republish;
    7720 : parse_proclaiming;
  }
}

parser parse_republish {
  extract(republish);
  return select (current(0, 8)) {
    38 : parse_waives;
    37 : parse_officiating;
  }
}

parser parse_officiating {
  extract(officiating);
  return select (latest.diarists) {
    3545 : parse_proclaiming;
  }
}

parser parse_proclaiming {
  extract(proclaiming);
  return select (latest.quartermasters) {
    52 : parse_waives;
  }
}

parser parse_waives {
  extract(waives);
  return ingress;
}

field_list wrinkly {
  proclaiming.impenetrabilitys;
  waives.tautologys;
}

field_list hermetic {
  officiating.bellyful;
  proclaiming.quartermasters;
  waives.tautologys;
  proclaiming.glitched;
  proclaiming.impenetrabilitys;
  corrosion.violoncellos;
  officiating.kitschy;
  spavined.bullring;
  officiating.occupations;
  waives.cave;
}

field_list sustenances {
  republish.fiats;
  officiating.occupations;
  waives.chalet;
}

field_list_calculation trumperys {
  input {
    hermetic;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation phonier {
  input {
    hermetic;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation estella {
  input {
    hermetic;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation wally {
  input {
    wrinkly;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field officiating.diarists {
  verify wally;
  update estella;
  update trumperys;
  update estella;
}

calculated_field corrosion.plot {
  update estella;
  verify phonier;
  verify wally;
  verify phonier;
}

action crippled() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action jaywalk(baseballs) {
  bit_xor(proclaiming.impenetrabilitys, shrug.airdropping, corrosion.violoncellos);
  bit_or(proclaiming.blackthorn, waives.plethora, spavined.bullring);
  bit_or(corrosion.zebu, 2006457280, 705580643);
}

action_profile fluting {
  actions {
    jaywalk;
    crippled;
  }
  size : 24;
}

action_profile bountifulnesss {
  actions {
    jaywalk;
    crippled;
  }
  size : 0;
}

action_profile lemmings {
  actions {
    jaywalk;
  }
  size : 13;
}

action_profile wisecracks {
  actions {
    jaywalk;
    crippled;
  }
  size : 26;
}

table ta {
  actions {
    crippled;
    }
  }

table zingier {
  action_profile : fluting;
  }

table yolks {
  actions {
    jaywalk;
    }
  }

table custody {
  reads {
    proclaiming.blackthorn mask 4 : exact;
    proclaiming.glitched mask 3 : exact;
    proclaiming.quartermasters : lpm;
    proclaiming.casehardens : ternary;
    waives : valid;
    waives.cave mask 25 : ternary;
  }
  actions {
    crippled;
    jaywalk;
  }
}

table retells {
  reads {
    officiating.occupations : exact;
    officiating.reactivated mask 104 : exact;
  }
  actions {
    
  }
}

table bloop {
  reads {
    spavined.bullring : exact;
  }
  action_profile : lemmings;
}

table coastlines {
  reads {
    corrosion.zebu : exact;
    corrosion.plot mask 9 : exact;
    republish : valid;
    proclaiming.blackthorn : exact;
    waives.adjudicate : lpm;
    waives.chalet : exact;
    waives.tautologys mask 114 : ternary;
    waives.plethora : exact;
  }
  action_profile : wisecracks;
}

table glasnosts {
  reads {
    corrosion : valid;
    waives : valid;
  }
  actions {
    crippled;
  }
}

table equalizer {
  reads {
    proclaiming.blackthorn mask 4 : exact;
    proclaiming.impenetrabilitys : exact;
    proclaiming.glitched : exact;
    proclaiming.quartermasters : exact;
    proclaiming.casehardens mask 2 : exact;
    waives.adjudicate : exact;
    waives.chalet : exact;
    waives.tautologys : exact;
    waives.plethora mask 19 : exact;
    waives.rediscover mask 40 : exact;
  }
  action_profile : bountifulnesss;
}

table rsvp {
  reads {
    spavined : valid;
    spavined.bullring mask 27 : ternary;
    corrosion.zebu mask 21 : exact;
    corrosion.plot : exact;
    corrosion.violoncellos : exact;
    officiating : valid;
    officiating.occupations : range;
    officiating.bellyful : exact;
    officiating.reactivated : exact;
    officiating.kitschy mask 4 : exact;
    officiating.diarists : lpm;
    proclaiming.glitched : ternary;
    proclaiming.quartermasters : exact;
    proclaiming.casehardens : exact;
  }
  actions {
    crippled;
    jaywalk;
  }
}

table sewers {
  reads {
    republish : valid;
  }
  actions {
    
  }
}

table neighbours {
  reads {
    officiating.occupations : exact;
    officiating.bellyful : exact;
    officiating.reactivated mask 89 : lpm;
    officiating.kitschy : exact;
    officiating.diarists : exact;
    proclaiming : valid;
    proclaiming.layoffs : exact;
    proclaiming.impenetrabilitys : exact;
    proclaiming.glitched : exact;
    proclaiming.quartermasters : exact;
    proclaiming.casehardens : ternary;
    waives : valid;
    waives.tautologys : ternary;
    waives.plethora : exact;
    waives.rediscover mask 50 : exact;
    waives.cave : ternary;
  }
  actions {
    
  }
}

table exposures {
  reads {
    shrug : valid;
    shrug.reasserting : exact;
    shrug.airdropping : exact;
  }
  actions {
    crippled;
    jaywalk;
  }
}

table encomiums {
  reads {
    shrug.reasserting : exact;
    corrosion : valid;
    corrosion.zebu : exact;
    corrosion.plot : exact;
    corrosion.violoncellos : lpm;
  }
  actions {
    
  }
}

control ingress {
  if ((officiating.bellyful <= 202)) {
    apply(zingier);
    if (true) {
      apply(yolks);
    }
    apply(custody);
  }
  if ((corrosion.violoncellos == shrug.airdropping)) {
    apply(retells);
  } else {
    apply(bloop);
    apply(coastlines);
    apply(glasnosts);
  }
  apply(equalizer);
  apply(rsvp);
  apply(sewers);
  apply(neighbours);
  apply(exposures);
  apply(encomiums);
}
