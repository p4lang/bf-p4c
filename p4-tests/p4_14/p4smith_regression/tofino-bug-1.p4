/* p4smith seed: 476105106 */
#include <tofino/intrinsic_metadata.p4>
header_type verity {
  fields {
    wheelchair : 48 (signed);
    motorcycling : 8;
    varnished : 48 (saturating);
    italians : 16;
    omayyad : 32 (signed, saturating);
  }
}

header_type messianic {
  fields {
    kilimanjaro : 16;
  }
}

header_type fugitives {
  fields {
    plot : 128 (signed);
    acoustics : 8;
  }
}

header_type nine {
  fields {
    disassociations : 32;
    bluegill : 64;
    catalpas : 12;
    padding: 4;
    force : 48;
  }
}

header_type seltzer {
  fields {
    pubertys : 48;
  }
}

header_type misogynists {
  fields {
    tided : 128;
    macadam : 32;
    cardsharp : 64;
    citronella : 128;
    miff : 64;
    detoxified : 48 (saturating);
  }
}

header_type imperfectness {
  fields {
    accrued : 16;
    visualizing : 8;
    wordier : 48;
    troops : 48;
    victory : 48;
    parts : 128;
  }
}

header verity broadening;

header messianic impedimenta;

header fugitives laughing;

header nine coachwork;

header seltzer capt;

header misogynists prophylaxis;

header imperfectness overproducing;

register ophiuchus {
  width : 16;
  instance_count : 70;
}

register litterers {
  width : 32;
  instance_count : 827;
}

register crossings {
  width : 16;
  instance_count : 545;
}

register rearmost {
  width : 128;
  instance_count : 641;
}

register undergarment {
  width : 32;
  instance_count : 891;
}

register rommel {
  width : 48;
  instance_count : 1006;
}

register magnifies {
  width : 16;
  instance_count : 1024;
}

register yemenis {
  width : 16;
  instance_count : 539;
}

register deliberated {
  width : 8;
  instance_count : 26;
}

register beasley {
  width : 8;
  instance_count : 745;
}

parser start {
  return parse_broadening;
}

parser parse_broadening {
  extract(broadening);
  return select (current(0, 8)) {
    8 : parse_impedimenta;
    55 : parse_prophylaxis;
    88 : parse_capt;
  }
}

parser parse_impedimenta {
  extract(impedimenta);
  return select (latest.kilimanjaro) {
    11850 : parse_laughing;
  }
}

parser parse_laughing {
  extract(laughing);
  return select (current(0, 8)) {
    70 : parse_prophylaxis;
    66 : parse_coachwork;
    53 : parse_capt;
  }
}

parser parse_coachwork {
  extract(coachwork);
  return select (current(0, 8)) {
    94 : parse_prophylaxis;
    22 : parse_capt;
  }
}

parser parse_capt {
  extract(capt);
  return select (current(0, 8)) {
    34 : parse_prophylaxis;
  }
}

parser parse_prophylaxis {
  extract(prophylaxis);
  return select (current(0, 8)) {
    80 : parse_overproducing;
  }
}

parser parse_overproducing {
  extract(overproducing);
  return ingress;
}

field_list sp {
  overproducing.accrued;
  prophylaxis.citronella;
  prophylaxis.cardsharp;
  overproducing.parts;
  broadening.motorcycling;
  prophylaxis.detoxified;
  overproducing.wordier;
}

field_list masai {
  laughing.plot;
  coachwork.catalpas;
  coachwork.bluegill;
  coachwork.disassociations;
  capt.pubertys;
}

field_list_calculation aggrieves {
  input {
    masai;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation dales {
  input {
    sp;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation hopefulnesss {
  input {
    masai;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation betel {
  input {
    masai;
    sp;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field overproducing.accrued {
  verify dales;
  update dales;
  verify aggrieves;
  update aggrieves;
}

calculated_field coachwork.catalpas {
  update aggrieves;
  update aggrieves;
  verify aggrieves;
  update dales;
}

calculated_field broadening.italians {
  verify hopefulnesss;
  update hopefulnesss;
  update betel;
  update betel;
}

calculated_field impedimenta.kilimanjaro {
  verify hopefulnesss;
  update betel;
  update aggrieves;
  update dales;
}

action khans() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action tussock(overcapacity) {
  add_to_field(coachwork.disassociations, broadening.omayyad);
}

action_profile handclasps {
  actions {
    tussock;
  }
}

table armored {
  actions {
    khans;
    }
  }

table cabinetry {
  reads {
    broadening : valid;
    broadening.motorcycling : exact;
    prophylaxis : valid;
    prophylaxis.macadam : exact;
    prophylaxis.citronella : exact;
    prophylaxis.miff : exact;
  }
  action_profile : handclasps;
}

table panama {
  actions {
    tussock;
    }
  }

table underclassman {
  reads {
    impedimenta.kilimanjaro : lpm;
  }
  actions {
    khans;
  }
}

table infinites {
  actions {
    khans;
    tussock;
    }
  }

table absinth {
  reads {
    prophylaxis.tided : exact;
    prophylaxis.citronella mask 39 : lpm;
    prophylaxis.miff : exact;
    prophylaxis.detoxified : lpm;
  }
  actions {
    khans;
    tussock;
  }
}

table wraiths {
  reads {
    capt : valid;
    overproducing.accrued mask 12 : exact;
    overproducing.visualizing : exact;
    overproducing.troops : range;
    overproducing.victory : exact;
    overproducing.parts : exact;
  }
  actions {
    tussock;
  }
}

table refresh {
  actions {
    khans;
    tussock;
    }
  }

table hootenannies {
  reads {
    prophylaxis : valid;
    prophylaxis.tided : range;
    prophylaxis.macadam mask 28 : ternary;
    prophylaxis.miff mask 35 : ternary;
    prophylaxis.detoxified : exact;
    overproducing : valid;
    overproducing.parts mask 3 : ternary;
  }
  actions {
    tussock;
  }
}

table baa {
  actions {
    tussock;
    }
  }

table bootleg {
  reads {
    laughing.plot : ternary;
    laughing.acoustics mask 2 : exact;
  }
  actions {
    khans;
  }
}

table jolene {
  reads {
    prophylaxis : valid;
  }
  actions {
    tussock;
  }
}

table navratilova {
  reads {
    broadening.motorcycling mask 6 : exact;
    broadening.varnished : exact;
    broadening.italians : exact;
    broadening.omayyad : exact;
    capt : valid;
    prophylaxis : valid;
    prophylaxis.cardsharp : exact;
    prophylaxis.detoxified mask 26 : ternary;
    overproducing : valid;
    overproducing.accrued : exact;
    overproducing.visualizing : exact;
    overproducing.wordier mask 16 : ternary;
    overproducing.troops : exact;
    overproducing.victory : exact;
  }
  actions {
    tussock;
  }
}

control ingress {
  if ((false and not(true))) {
    if ((((coachwork.disassociations == broadening.italians) or
        (overproducing.visualizing == coachwork.disassociations)) or
        (broadening.italians >= 96))) {
      apply(cabinetry);
    } else {
      if (not(valid(impedimenta))) {
        apply(panama);
        apply(underclassman);
      }
      apply(infinites);
    }
  } else {
    if (true) {
      apply(absinth);
      apply(wraiths);
    }
    apply(refresh);
  }
  apply(hootenannies);
  if ((136 >= coachwork.catalpas)) {
    
  } else {
    apply(baa);
  }
  apply(bootleg);
  apply(jolene);
  apply(navratilova);
}
