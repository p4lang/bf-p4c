/* p4smith seed: 125286370 */
#include <tofino/intrinsic_metadata.p4>
header_type spirals {
  fields {
    subbasement : 128 (signed);
    hallies : 8;
    pullover : 16 (signed, saturating);
    cummerbunds : 64;
    toes : 128;
    shipboard : 48;
  }
}

header_type tarmacs {
  fields {
    buckles : 16;
    reciprocations : 16;
  }
}

header_type salvadors {
  fields {
    samoyed : 16;
  }
}

header spirals tiaras;

header tarmacs bookshelves;

header salvadors demurrers;

register graininesss {
  width : 16;
  instance_count : 454;
}

register cockeyed {
  width : 16;
  instance_count : 1024;
}

register pinging {
  width : 8;
  instance_count : 719;
}

parser start {
  return parse_tiaras;
}

parser parse_tiaras {
  extract(tiaras);
  return select (current(0, 8)) {
    35 : parse_demurrers;
    225 : parse_bookshelves;
  }
}

parser parse_bookshelves {
  extract(bookshelves);
  return select (latest.reciprocations) {
    27463 : parse_demurrers;
  }
}

parser parse_demurrers {
  extract(demurrers);
  return ingress;
}

field_list stamps {
  tiaras;
  demurrers.samoyed;
  demurrers;
  demurrers;
  tiaras.hallies;
}

field_list rhea {
  tiaras;
  demurrers.samoyed;
  tiaras;
  demurrers.samoyed;
  bookshelves;
  demurrers.samoyed;
  demurrers;
  tiaras.shipboard;
  bookshelves.reciprocations;
  tiaras.toes;
  tiaras.pullover;
  bookshelves;
  demurrers;
  bookshelves;
  tiaras.cummerbunds;
  36;
}

field_list plantings {
  tiaras.cummerbunds;
  tiaras.cummerbunds;
}

field_list_calculation primulas {
  input {
    stamps;
  }
  algorithm : csum16;
  output_width : 32;
}

field_list_calculation essayists {
  input {
    rhea;
  }
  algorithm : crc32;
  output_width : 48;
}

field_list_calculation economize {
  input {
    plantings;
  }
  algorithm : crc16;
  output_width : 64;
}

calculated_field tiaras.toes {
#ifdef __p4c__
  verify primulas;
#else
  verify primulas if (valid(demurrers));
#endif
}

calculated_field demurrers.samoyed {
  verify primulas if (valid(demurrers));
}

action alejandro() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action briefs(jujubes) {
  add(bookshelves.buckles, tiaras.pullover, demurrers.samoyed);
  subtract(demurrers.samoyed, tiaras.pullover, 21146);
  add_to_field(tiaras.hallies, 122);
  add_to_field(bookshelves.reciprocations, 43427);
  bit_or(tiaras.pullover, tiaras.pullover, tiaras.pullover);
}

action manitoulin(pallors) {
  modify_field(tiaras.subbasement, tiaras.toes);
  copy_header(bookshelves, bookshelves);
  register_read(tiaras.pullover, graininesss, 220);
  add(tiaras.hallies, 121, 104);
  modify_field(tiaras.shipboard, 794164175);
  copy_header(demurrers, demurrers);
  modify_field(tiaras.cummerbunds, tiaras.cummerbunds);
  add_header(demurrers);
}

action rubbles(orotundity, aerate) {
  add_header(bookshelves);
  modify_field(tiaras.shipboard, 1532984000);
  remove_header(tiaras);
  bit_and(bookshelves.buckles, bookshelves.buckles, bookshelves.buckles);
  remove_header(bookshelves);
  subtract_from_field(tiaras.pullover, 2732);
  remove_header(demurrers);
  bit_and(bookshelves.reciprocations, demurrers.samoyed, bookshelves.reciprocations);
}

table hums {
  actions {
    alejandro;
    }
  }

table overdosed {
  actions {
    alejandro;
    rubbles;
    }
  }

table cooker {
  reads {
    tiaras : valid;
    tiaras.hallies : lpm;
    tiaras.shipboard mask 30 : exact;
  }
  actions {
    alejandro;
    rubbles;
  }
}

table finagle {
  actions {
    alejandro;
    briefs;
    }
  }

control ingress {
  apply(hums);
  if (false) {
    apply(overdosed);
  }
  apply(cooker);
  apply(finagle);
}
