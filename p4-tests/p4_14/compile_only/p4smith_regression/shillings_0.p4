/* p4smith seed: 1044594977 */
#include <tofino/intrinsic_metadata.p4>
header_type pesos {
  fields {
    vegans : 16;
    brocade : 8 (saturating);
  }
}

header_type cautions {
  fields {
    veils : 32;
    ragamuffin : 16;
    hippos : 64;
    payments : 16 (saturating);
    underlie : 48;
    termites : 32 (signed, saturating);
  }
}

header pesos profits;

header cautions masterminds;

register blush {
  width : 16;
  instance_count : 154;
}

register shepherdess {
  width : 128;
  instance_count : 1;
}

register fishtailed {
  width : 32;
  instance_count : 795;
}

register racings {
  width : 16;
  instance_count : 129;
}

register viviennes {
  width : 8;
  instance_count : 726;
}

parser start {
  return parse_profits;
}

parser parse_profits {
  extract(profits);
  return select (latest.brocade) {
    255 : parse_masterminds;
  }
}

parser parse_masterminds {
  extract(masterminds);
  return ingress;
}

field_list boxes {
  profits.vegans;
  masterminds.hippos;
  masterminds;
  profits.vegans;
  profits.brocade;
  masterminds.hippos;
  profits;
  masterminds.ragamuffin;
  profits;
  profits.brocade;
  profits.vegans;
  profits;
}

field_list responsively {
  profits;
  masterminds.payments;
  189;
  masterminds.ragamuffin;
  profits.vegans;
  masterminds;
  masterminds;
  0;
  profits.brocade;
}

field_list sappho {
  masterminds.veils;
  masterminds.veils;
  masterminds;
  profits;
  masterminds.ragamuffin;
  masterminds;
  masterminds;
  175;
  masterminds;
  masterminds.hippos;
  masterminds.payments;
  masterminds.payments;
  profits;
  profits.brocade;
  masterminds.underlie;
  masterminds.payments;
}

field_list_calculation litanies {
  input {
    boxes;
  }
#ifdef __p4c__
  algorithm : csum16;
#else
  algorithm : crc16;
#endif
  output_width : 64;
}

calculated_field profits.vegans {
#ifdef __p4c__
  update litanies;
#else
  update litanies if (valid(profits));
#endif
  verify litanies;
  verify litanies;
  verify litanies;
}

calculated_field masterminds.termites {
  verify litanies;
#ifndef __p4c__
  verify litanies if (masterminds.underlie == 1);
#endif
}

calculated_field masterminds.ragamuffin {
#ifdef __p4c__
  verify litanies;
  update litanies;
  verify litanies;
#else
  verify litanies if (valid(masterminds));
  update litanies;
  verify litanies if (masterminds.termites == 2);
#endif
}

calculated_field masterminds.payments {
#ifdef __p4c__
  update litanies;
#else
  update litanies if (masterminds.underlie == 3);
  update litanies if (masterminds.ragamuffin == 10);
  update litanies if (profits.vegans == 16);
#endif
}

action edicts() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action quarks(arsehole, hominids) {
  remove_header(profits);
}

action hairnets(blu, overcharged) {
  remove_header(masterminds);
  modify_field(profits.vegans, 38802);
  subtract(masterminds.payments, masterminds.payments, masterminds.payments);
}

action reflections(marines, interloping) {
  remove_header(masterminds);
  register_write(blush, 29, profits.vegans);
  modify_field(masterminds.ragamuffin, 49865);
  add_to_field(masterminds.payments, masterminds.payments);
  modify_field(masterminds.underlie, 17357758);
  add_header(masterminds);
}

action leghorns(hedonistic, enfranchised) {
  register_read(profits.brocade, viviennes, 408);
  subtract(masterminds.ragamuffin, masterminds.ragamuffin, masterminds.ragamuffin);
}

table volgograd {
  actions {
    edicts;
    }
  }

table demount {
  actions {
    leghorns;
    }
  }

table idolatresss {
  actions {
    leghorns;
    quarks;
    reflections;
    }
  }

control ingress {
  apply(volgograd);
  apply(demount);
  if (((masterminds.termites == masterminds.veils) or (profits.brocade <= 255))) {
    apply(idolatresss);
  }
}
