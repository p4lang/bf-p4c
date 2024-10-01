/* p4smith seed: 123501392 */
#include <tofino/intrinsic_metadata.p4>
header_type lingual {
  fields {
    trendsetter : 48 (signed, saturating);
    abidjan : 2;
    nihilists : 11;
    dickson : 48;
    zyrtecs : 11 (signed, saturating);
  }
}

header_type bailsmans {
  fields {
    ruts : 5;
    secants : 11;
    antioxidants : 8;
  }
}

header_type zookeepers {
  fields {
    confronting : 3;
    factoring : 6;
    propagate : 48 (signed, saturating);
    exhilarated : 11 (signed, saturating);
    wallboard : 12;
    idol : 32 (saturating);
  }
}

header_type logan {
  fields {
    roegs : 4;
    lax : 2 (signed, saturating);
    automaker : 16;
    jeanie : 48 (saturating);
    reddens : 16;
    skulks : 2;
  }
}

header_type caedmon {
  fields {
    kingstown : 3;
    counterattacks : 11;
    fitch : 10;
    quailed : 8 (signed, saturating);
  }
}

header_type subjects {
  fields {
    leghorn : 4;
    geldings : 16 (signed, saturating);
    schnauzers : 16;
    osteopaths : 16 (saturating);
    gook : 12 (saturating);
    repairing : 48 (saturating);
    plaque : 16;
  }
}

header lingual kinda;

header bailsmans marge;

header zookeepers enigmas;

header logan ridge;

header caedmon buglers;

header subjects hazed;

register joustings {
  width : 64;
  instance_count : 385;
}

register masterclass {
  width : 1;
  instance_count : 494;
}

register smarties {
  width : 64;
  instance_count : 527;
}

register ventricle {
  width : 16;
  instance_count : 441;
}

register practitioners {
  width : 16;
  instance_count : 428;
}

register counterpoising {
  width : 16;
  instance_count : 180;
}

register sway {
  width : 16;
  instance_count : 918;
}

register collegian {
  width : 64;
  instance_count : 595;
}

register colonials {
  width : 16;
  instance_count : 878;
}

parser start {
  return parse_kinda;
}

parser parse_kinda {
  extract(kinda);
  return select (latest.nihilists) {
    247 : parse_marge;
  }
}

parser parse_marge {
  extract(marge);
  return select (latest.antioxidants) {
    109 : parse_buglers;
    80 : parse_enigmas;
  }
}

parser parse_enigmas {
  extract(enigmas);
  return select (latest.confronting) {
    3 : parse_buglers;
    3 : parse_ridge;
    2 : parse_hazed;
  }
}

parser parse_ridge {
  extract(ridge);
  return select (latest.lax) {
    0 : parse_buglers;
    0 : parse_hazed;
  }
}

parser parse_buglers {
  extract(buglers);
  return select (latest.counterattacks) {
    525 : parse_hazed;
  }
}

parser parse_hazed {
  extract(hazed);
  return ingress;
}

field_list sternum {
  marge.antioxidants;
  enigmas.idol;
  kinda.trendsetter;
  hazed.repairing;
}

field_list uccellos {
  hazed.plaque;
  marge.antioxidants;
  kinda.abidjan;
  kinda.trendsetter;
  buglers.quailed;
  hazed.repairing;
}

field_list appalachia {
  kinda.trendsetter;
  hazed.plaque;
  enigmas.idol;
  marge.antioxidants;
  kinda.abidjan;
  hazed.repairing;
  buglers.quailed;
}

field_list_calculation torpors {
  input {
    sternum;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation overfeeds {
  input {
    appalachia;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field hazed.plaque {
  update torpors;
}

action blameworthiness() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action prepare() {
  copy_header(hazed, hazed);
  subtract(enigmas.idol, 2711171576139844342, enigmas.idol);
  bit_xor(marge.antioxidants, marge.antioxidants, 97406235936923771);
  bit_or(buglers.quailed, 2915605826551720497, 0);
}

action commissioners(undrinkable, stormily, wraiths) {
  remove_header(enigmas);
  bit_and(hazed.plaque, hazed.plaque, 1488862242685089292);
  register_read(hazed.geldings, colonials, 878);
  bit_and(marge.antioxidants, marge.antioxidants, 128800247181345567);
  modify_field(ridge.skulks, kinda.abidjan);
  remove_header(kinda);
  add_header(ridge);
  subtract_from_field(enigmas.idol, 1035574354531031364);
}

action bellboy() {
  register_read(hazed.geldings, sway, 592);
  copy_header(ridge, ridge);
  add_header(hazed);
  remove_header(marge);
  add_to_field(marge.antioxidants, buglers.quailed);
  modify_field_rng_uniform(kinda.trendsetter, 0, 16383);
}

action desiring(handlers, phenoms) {
  bit_xor(buglers.quailed, buglers.quailed, buglers.quailed);
  subtract_from_field(enigmas.idol, 629436067633184150);
  add_header(hazed);
  remove_header(marge);
  add_to_field(marge.antioxidants, marge.antioxidants);
  register_read(hazed.schnauzers, counterpoising, 0);
  copy_header(ridge, ridge);
  add_to_field(hazed.plaque, hazed.plaque);
}

action_profile headers {
  actions {
    prepare;
  }
  size : 9;
}

action_profile circumvents {
  actions {
    bellboy;
  }
  size : 6;
}

table punks {
  actions {
    blameworthiness;
    }
  }

table misdeals {
  reads {
    enigmas.confronting : exact;
    enigmas.exhilarated : exact;
    enigmas.wallboard : exact;
    enigmas.idol : ternary;
    ridge.reddens : ternary;
    ridge.skulks mask 0 : exact;
    buglers : valid;
    buglers.kingstown : exact;
    buglers.counterattacks mask 8 : exact;
    buglers.fitch mask 4 : ternary;
    buglers.quailed : exact;
    hazed.leghorn : exact;
    hazed.osteopaths : range;
    hazed.gook : ternary;
    hazed.plaque : ternary;
  }
  actions {
    bellboy;
    blameworthiness;
    commissioners;
  }
}

table lobs {
  reads {
    marge : valid;
    marge.ruts : exact;
    marge.antioxidants : ternary;
  }
  actions {
    bellboy;
    blameworthiness;
    prepare;
  }
}

table tightfisted {
  reads {
    kinda : valid;
    marge : valid;
    marge.ruts : exact;
    marge.secants mask 0 : exact;
    marge.antioxidants : exact;
    ridge : valid;
  }
  actions {
    prepare;
  }
}

table corvettes {
  reads {
    kinda : valid;
    kinda.trendsetter mask 23 : exact;
    kinda.abidjan mask 1 : exact;
    kinda.nihilists mask 7 : lpm;
    kinda.dickson : exact;
    kinda.zyrtecs mask 4 : exact;
    marge.antioxidants : ternary;
    buglers.fitch : exact;
    buglers.quailed : exact;
  }
  action_profile : headers;
}

table underarm {
  action_profile : circumvents;
  }

table cote {
  reads {
    hazed.plaque : lpm;
  }
  actions {
    commissioners;
  }
}

table neldas {
  reads {
    kinda.abidjan : exact;
  }
  actions {
    blameworthiness;
    prepare;
  }
}

table rebellions {
  actions {
    bellboy;
    commissioners;
    prepare;
    }
  }

table knicker {
  reads {
    ridge : valid;
    ridge.reddens : ternary;
    ridge.skulks : exact;
    buglers : valid;
    buglers.kingstown : range;
    buglers.counterattacks : exact;
    buglers.fitch mask 8 : ternary;
    buglers.quailed mask 4 : exact;
    hazed.repairing : exact;
    hazed.plaque : exact;
  }
  actions {
    bellboy;
    blameworthiness;
    prepare;
  }
}

table hotfoots {
  reads {
    marge.ruts : exact;
  }
  actions {
    bellboy;
  }
}

table edged {
  reads {
    buglers.kingstown : ternary;
    buglers.counterattacks : ternary;
    buglers.fitch : lpm;
    buglers.quailed : ternary;
    hazed : valid;
    hazed.leghorn : exact;
    hazed.schnauzers mask 7 : lpm;
  }
  actions {
    bellboy;
    prepare;
  }
}

table lamour {
  reads {
    marge.ruts : exact;
    marge.secants : exact;
    marge.antioxidants : exact;
    enigmas.factoring : exact;
    enigmas.exhilarated mask 7 : exact;
    enigmas.idol : exact;
    ridge.jeanie : exact;
    ridge.reddens : exact;
    ridge.skulks : exact;
    hazed : valid;
    hazed.geldings mask 5 : exact;
    hazed.schnauzers : exact;
    hazed.osteopaths : ternary;
    hazed.gook : exact;
    hazed.repairing : exact;
  }
  actions {
    desiring;
  }
}

table beamed {
  reads {
    kinda.abidjan : exact;
    marge.antioxidants : lpm;
  }
  actions {
    blameworthiness;
    desiring;
  }
}

table heath {
  reads {
    marge : valid;
    enigmas : valid;
    enigmas.confronting mask 1 : exact;
    enigmas.wallboard : exact;
    ridge : valid;
  }
  actions {
    bellboy;
    desiring;
  }
}

table bauer {
  reads {
    ridge : valid;
    ridge.skulks : ternary;
  }
  actions {
    blameworthiness;
    prepare;
  }
}

table bobbins {
  actions {
    
    }
  }

table abbreviations {
  actions {
    
    }
  }

table ruling {
  actions {
    
    }
  }

control ingress {
  apply(misdeals);
  if (false) {
    apply(lobs);
    apply(tightfisted);
  }
  if (not(((enigmas.idol == 958153041) or
      (buglers.quailed == marge.antioxidants)))) {
    if (false) {
      
    } else {
      apply(corvettes);
    }
    if ((not(true) and not(true))) {
      apply(underarm);
      apply(cote);
    } else {
      apply(neldas);
      apply(rebellions);
    }
    apply(knicker);
  }
  if (not(((kinda.zyrtecs <= 195) and (43 < enigmas.exhilarated)))) {
    apply(hotfoots);
    apply(edged);
    apply(lamour);
  }
  if (true) {
    if ((not((89 > hazed.gook)) or (false and (3566 == kinda.trendsetter)))) {
      apply(beamed);
      apply(heath);
      apply(bauer);
    }
    apply(bobbins);
    apply(abbreviations);
  } else {
    apply(ruling);
  }
}
