/* p4smith seed: 241427849 */
#include <tofino/intrinsic_metadata.p4>
header_type messengers {
  fields {
    absolves : 64;
    squelchy : 8 (saturating);
  }
}

header_type hydrangeas {
  fields {
    clattered : 64;
    allegiance : 32;
    abes : 16;
    lactates : 8;
  }
}

header_type jutting {
  fields {
    contoured : 64 (signed);
  }
}

header_type macaws {
  fields {
    examiners : 32 (signed);
  }
}

header_type micheles {
  fields {
    outworking : 32;
  }
}

header_type rory {
  fields {
    fistulouss : 8 (signed);
    ownerships : 48 (saturating);
  }
}

header messengers reecho;

header hydrangeas castaway;

header jutting ests;

header macaws subeditor;

header micheles kinked;

header rory oatcake;

register literally {
  width : 16;
  instance_count : 489;
}

register rattlebrains {
  width : 8;
  instance_count : 52;
}

register waist {
  width : 64;
  instance_count : 311;
}

register lubricated {
  width : 32;
  instance_count : 487;
}

register accept {
  width : 8;
  instance_count : 46;
}

register titlists {
  width : 32;
  instance_count : 941;
}

register squall {
  width : 16;
  instance_count : 796;
}

parser start {
  return parse_reecho;
}

parser parse_reecho {
  extract(reecho);
  return select (latest.squelchy) {
    255 : parse_castaway;
    233 : parse_subeditor;
    9 : parse_kinked;
  }
}

parser parse_castaway {
  extract(castaway);
  return select (latest.lactates) {
    55 : parse_ests;
    142 : parse_subeditor;
  }
}

parser parse_ests {
  extract(ests);
  return select (current(0, 8)) {
    179 : parse_subeditor;
  }
}

parser parse_subeditor {
  extract(subeditor);
  return select (current(0, 8)) {
    253 : parse_kinked;
  }
}

parser parse_kinked {
  extract(kinked);
  return select (current(0, 8)) {
    89 : parse_oatcake;
  }
}

parser parse_oatcake {
  extract(oatcake);
  return ingress;
}

field_list bullheadedly {
  125;
  kinked;
  kinked.outworking;
  subeditor.examiners;
  subeditor;
  kinked.outworking;
  92;
  kinked.outworking;
  oatcake.ownerships;
  ests;
}

field_list reembarking {
  oatcake;
  subeditor.examiners;
  castaway;
  subeditor;
  castaway.allegiance;
  castaway.lactates;
  ests;
  reecho;
  oatcake.fistulouss;
  castaway.abes;
  oatcake.ownerships;
  oatcake.ownerships;
  castaway.allegiance;
  subeditor.examiners;
}

field_list_calculation negation {
  input {
    reembarking;
  }
#ifdef __p4c__
  algorithm : csum16;
#else
  algorithm : xor16;
#endif
  output_width : 48;
}

calculated_field castaway.clattered {
#ifndef __p4c__
  verify negation if (castaway.clattered == 60);
#endif
  verify negation;
#ifdef __p4c__
  update negation;
#else
  update negation if (valid(oatcake));
#endif
}

calculated_field oatcake.fistulouss {
#ifdef __p4c__
  verify negation;
#else
  verify negation if (reecho.squelchy == 4);
  verify negation if (valid(kinked));
  verify negation if (valid(subeditor));
#endif
}

action church() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action ironically(macaroni) {
  bit_and(subeditor.examiners, 1893792063, 2147483647);
  add_to_field(reecho.squelchy, 65);
  subtract(castaway.allegiance, 1496100368, castaway.allegiance);
  subtract(oatcake.fistulouss, 86, oatcake.fistulouss);
  register_read(reecho.absolves, waist, 66);
}

action brocades() {
  register_write(accept, 1, oatcake.fistulouss);
  bit_and(castaway.lactates, reecho.squelchy, castaway.lactates);
  register_read(kinked.outworking, lubricated, 133);
}

table blog {
  actions {
    church;
    }
  }

table mahdi {
  reads {
    reecho : valid;
  }
  actions {
    brocades;
    ironically;
  }
}

control ingress {
  if ((false and valid(ests))) {
    apply(blog);
  }
  apply(mahdi);
}
