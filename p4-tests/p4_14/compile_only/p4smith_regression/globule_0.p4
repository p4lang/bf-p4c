/* p4smith seed: 230854668 */
#include <tofino/intrinsic_metadata.p4>
header_type flatworms {
  fields {
    snorkelling : 8;
    businessmen : 32;
    asininities : 32 (saturating);
  }
}

header_type ghettoizing {
  fields {
    synopses : 16;
    elnora : 16;
    mediating : 16 (saturating);
    apiarist : 16;
    semites : 16;
  }
}

header_type lavatorys {
  fields {
    alliances : 8 (signed);
    hallies : 16;
    neh : 48;
    ruffs : 8;
  }
}

header_type faultlessly {
  fields {
    predetermine : 16;
    strangely : 16 (saturating);
    bugling : 64 (saturating);
  }
}

header_type mom {
  fields {
    bilingually : 16;
    construe : 128 (saturating);
    firecrackers : 8 (signed);
    parsley : 48 (saturating);
    brigids : 16;
    grids : 8;
  }
}

header_type squander {
  fields {
    keener : 16;
    hying : 16 (saturating);
  }
}

header flatworms acknowledgments;

header ghettoizing mashhads;

header lavatorys enchantresss;

header faultlessly companionways;

header mom maudlin;

header squander reedinesss;

register regimes {
  width : 32;
  instance_count : 718;
}

register fistfuls {
  width : 128;
  instance_count : 19;
}

register jounce {
  width : 32;
  instance_count : 157;
}

register horticulturalist {
  width : 8;
  instance_count : 1;
}

parser start {
  return parse_acknowledgments;
}

parser parse_acknowledgments {
  extract(acknowledgments);
  return select (latest.snorkelling) {
    93 : parse_companionways;
    97 : parse_mashhads;
  }
}

parser parse_mashhads {
  extract(mashhads);
  return select (latest.elnora) {
    63610 : parse_companionways;
    27837 : parse_enchantresss;
    57403 : parse_maudlin;
  }
}

parser parse_enchantresss {
  extract(enchantresss);
  return select (latest.alliances) {
    143 : parse_companionways;
    139 : parse_maudlin;
    171 : parse_reedinesss;
  }
}

parser parse_companionways {
  extract(companionways);
  return select (current(0, 8)) {
    203 : parse_maudlin;
    250 : parse_reedinesss;
  }
}

parser parse_maudlin {
  extract(maudlin);
  return select (latest.bilingually) {
    431 : parse_reedinesss;
  }
}

parser parse_reedinesss {
  extract(reedinesss);
  return ingress;
}

field_list notation {
  mashhads;
  enchantresss.ruffs;
  maudlin.bilingually;
  reedinesss.keener;
  enchantresss.hallies;
  companionways;
  maudlin;
  acknowledgments.asininities;
  enchantresss;
  mashhads.elnora;
  maudlin.grids;
  maudlin.bilingually;
}

field_list_calculation brigandages {
  input {
    notation;
  }
  algorithm : csum16;
  output_width : 8;
}

field_list_calculation sculls {
  input {
    notation;
  }
  algorithm : xor16;
  output_width : 8;
}

calculated_field mashhads.synopses {
  update brigandages if (valid(acknowledgments));
  update sculls;
  verify brigandages if (enchantresss.alliances == 5);
  verify sculls if (valid(companionways));
}

calculated_field enchantresss.ruffs {
  verify sculls;
  update brigandages if (enchantresss.neh == 12);
  verify brigandages;
}

calculated_field maudlin.construe {
  verify sculls if (enchantresss.ruffs == 6);
  update sculls;
}

calculated_field enchantresss.hallies {
  update brigandages if (maudlin.grids == 4);
  update brigandages if (valid(maudlin));
  verify brigandages if (mashhads.synopses == 9);
  update brigandages;
}

action sewers() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action medicaids(newly, parvenu) {
  register_read(acknowledgments.snorkelling, horticulturalist, 1);
  subtract_from_field(acknowledgments.asininities, acknowledgments.businessmen);
  remove_header(acknowledgments);
  add_header(mashhads);
  add(enchantresss.hallies, companionways.predetermine, mashhads.synopses);
}

action savoy() {
  subtract_from_field(maudlin.firecrackers, maudlin.firecrackers);
  subtract_from_field(reedinesss.hying, mashhads.mediating);
  register_write(horticulturalist, 1, enchantresss.ruffs);
  add_header(maudlin);
}

action jabber(particulates, hauberk) {
  copy_header(companionways, companionways);
  register_write(fistfuls, 8, maudlin.construe);
  add_header(companionways);
}

action beau() {
  bit_xor(maudlin.bilingually, companionways.strangely, maudlin.bilingually);
  copy_header(enchantresss, enchantresss);
  add(reedinesss.hying, mashhads.synopses, companionways.predetermine);
  bit_and(mashhads.elnora, mashhads.apiarist, reedinesss.keener);
  copy_header(acknowledgments, acknowledgments);
  bit_or(maudlin.firecrackers, maudlin.grids, maudlin.firecrackers);
  subtract_from_field(mashhads.mediating, maudlin.brigids);
}

table shells {
  actions {
    sewers;
    }
  }

table mitts {
  reads {
    mashhads : valid;
    mashhads.synopses mask 50 : exact;
    mashhads.elnora mask 226 : lpm;
    enchantresss.alliances : exact;
    enchantresss.hallies : ternary;
    enchantresss.neh : range;
    reedinesss : valid;
    reedinesss.hying : range;
  }
  actions {
    beau;
    savoy;
  }
}

table fourteen {
  actions {
    medicaids;
    savoy;
    }
  }

control ingress {
  apply(shells);
  apply(mitts);
  if (true) {
    apply(fourteen);
  }
}
