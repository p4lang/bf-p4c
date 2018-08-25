/* p4smith seed: 638946381 */
#include <tofino/intrinsic_metadata.p4>
header_type complexioned {
  fields {
    sectionals : 32;
    sew : 16;
    tarkington : 16 (saturating);
    gutlessnesss : 64 (signed);
    search : 48;
    plutocracies : 16;
  }
}

header_type irons {
  fields {
    snare : 16;
  }
}

header_type pipe {
  fields {
    tiebreakers : 32 (signed, saturating);
    cuffing : 48;
    halos : 8;
    raceme : 64 (signed, saturating);
  }
}

header_type driftwood {
  fields {
    glossys : 16;
  }
}

header complexioned overenthusiastic;

header irons diaper;

header pipe gristle;

header driftwood jackys;

register inkier {
  width : 32;
  instance_count : 330;
}

register jeds {
  width : 48;
  instance_count : 778;
}

register boilermaker {
  width : 32;
  instance_count : 593;
}

register ratline {
  width : 8;
  instance_count : 247;
}

register smuggle {
  width : 32;
  instance_count : 559;
}

register verily {
  width : 16;
  instance_count : 389;
}

register sectarys {
  width : 32;
  instance_count : 698;
}

register lighten {
  width : 16;
  instance_count : 1024;
}

parser start {
  return parse_overenthusiastic;
}

parser parse_overenthusiastic {
  extract(overenthusiastic);
  return select (current(0, 8)) {
    213 : parse_diaper;
  }
}

parser parse_diaper {
  extract(diaper);
  return select (latest.snare) {
    35235 : parse_jackys;
    55575 : parse_gristle;
  }
}

parser parse_gristle {
  extract(gristle);
  return select (latest.halos) {
    255 : parse_jackys;
  }
}

parser parse_jackys {
  extract(jackys);
  return ingress;
}

field_list metricizing {
  overenthusiastic.sectionals;
  overenthusiastic.gutlessnesss;
  gristle.halos;
}

field_list_calculation bentley {
  input {
    metricizing;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field overenthusiastic.plutocracies {
#ifdef __p4c__
  verify bentley;
#else
  verify bentley if (overenthusiastic.tarkington == 12);
#endif
  update bentley;
}

calculated_field gristle.tiebreakers {
#ifdef __p4c__
  verify bentley;
#else
  verify bentley if (overenthusiastic.sew == 14);
#endif
}

action squiggly() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action weathering(camemberts) {
  bit_and(diaper.snare, 64710, jackys.glossys);
}

table rapist {
  actions {
    squiggly;
    }
  }

table vainglorys {
  reads {
    gristle : valid;
    gristle.tiebreakers mask 14 : exact;
    gristle.cuffing : lpm;
  }
  actions {
    squiggly;
    weathering;
  }
}

control ingress {
  if (valid(overenthusiastic)) {
    apply(rapist);
  }
  apply(vainglorys);
}
