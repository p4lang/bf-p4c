#include <tofino/intrinsic_metadata.p4>
header_type binturongs {
  fields {
    clinometers : 112;
  }
}

header_type missense {
  fields {
    frumenties : 8;
  }
}

header_type borrowers {
  fields {
    ridered : 16;
    folksy : 8;
    ijtihad : 32;
    reconsigned : 32;
    cardcases : 8;
  }
}

header_type periwig {
  fields {
    counterpoises : 32;
    damper : 32;
    terrie : 8;
  }
}

header_type sequaciously {
  fields {
    stolidities : 32;
    sumerology : 32;
    freckling : 8;
  }
}

header_type acre {
  fields {
    polyps : 32;
    scumbling : 8;
    rectify : 32;
    velatura : 16;
    benson : 8;
  }
}

header_type background {
  fields {
    rameau : 32;
    nonoverlapping : 32;
    initializations : 8;
  }
}

header_type phytopathologies {
  fields {
    conformisms : 32;
    asparaginase : 8;
  }
}

header_type demandable {
  fields {
    journalizations : 32;
    angelus : 32;
    sjamboking : 32;
    floccose : 8;
  }
}

header_type blawort {
  fields {
    superstratum : 8;
    lammed : 8;
  }
}

header binturongs philologian;

header missense shafting;

header missense lactoglobulins[11];

header sequaciously kranzburgs;

header blawort superscouts;

header demandable necker;

header borrowers mucho;

header blawort refugio;

header phytopathologies distinguishability;

parser start {
  return parse_philologian;
}

parser parse_philologian {
  extract(philologian);
  return parse_shafting;
}

parser parse_shafting {
  extract(shafting);
  return parse_lactoglobulins;
}

parser parse_lactoglobulins {
  extract(lactoglobulins[next]);
  return select (latest.frumenties) {
    0 : parse_kranzburgs;
    default : parse_lactoglobulins;
  }
}

parser parse_kranzburgs {
  extract(kranzburgs);
  return parse_superscouts;
}

parser parse_superscouts {
  extract(superscouts);
  return parse_necker;
}

parser parse_necker {
  extract(necker);
  return select (latest.floccose) {
    0 : parse_refugio;
    1 : parse_mucho;
    2 : parse_distinguishability;
    default : ingress;
  }
}

parser parse_mucho {
  extract(mucho);
  return parse_refugio;
}

parser parse_refugio {
  extract(refugio);
  return parse_distinguishability;
}

parser parse_distinguishability {
  extract(distinguishability);
  return ingress;
}

action before() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
  bypass_egress();
}

action after() {
  remove_header(shafting);
}

action skip() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
}

action del_kranzburgs() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(kranzburgs);
}

action add_kranzburgs() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(kranzburgs);
  modify_field(kranzburgs.stolidities, 0);
  modify_field(kranzburgs.sumerology, 0);
  modify_field(kranzburgs.freckling, 0);
}

action del_superscouts() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(superscouts);
}

action add_superscouts() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(superscouts);
  modify_field(superscouts.superstratum, 0);
  modify_field(superscouts.lammed, 0);
}

action del_necker() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(necker);
}

action add_necker() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(necker);
  modify_field(necker.journalizations, 0);
  modify_field(necker.angelus, 0);
  modify_field(necker.sjamboking, 0);
  modify_field(necker.floccose, 0);
}

action del_mucho() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(mucho);
}

action add_mucho() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(mucho);
  modify_field(mucho.ridered, 0);
  modify_field(mucho.folksy, 0);
  modify_field(mucho.ijtihad, 0);
  modify_field(mucho.reconsigned, 0);
  modify_field(mucho.cardcases, 0);
}

action del_refugio() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(refugio);
}

action add_refugio() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(refugio);
  modify_field(refugio.superstratum, 0);
  modify_field(refugio.lammed, 0);
}

action del_distinguishability() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  remove_header(distinguishability);
}

action add_distinguishability() {
  modify_field(shafting.frumenties, lactoglobulins[0].frumenties);
  pop(lactoglobulins, 1);
  add_header(distinguishability);
  modify_field(distinguishability.conformisms, 0);
  modify_field(distinguishability.asparaginase, 0);
}

table tinnie {
  actions {
    before;
    }
    size : 1;
  }

table workmanlike {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    add_kranzburgs;
    add_superscouts;
    add_necker;
    add_mucho;
    add_refugio;
    add_distinguishability;
  }
  size : 64;
}

table kanangas {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    add_kranzburgs;
    add_superscouts;
    add_necker;
    add_mucho;
    add_refugio;
    add_distinguishability;
  }
  size : 64;
}

table rufus {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    add_kranzburgs;
    add_superscouts;
    add_necker;
    add_mucho;
    add_refugio;
    add_distinguishability;
  }
  size : 64;
}


table delanceys {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    add_kranzburgs;
    add_superscouts;
    add_necker;
    add_mucho;
    add_refugio;
    add_distinguishability;
  }
  size : 64;
}

table anginal {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    add_kranzburgs;
    add_superscouts;
    add_necker;
    add_mucho;
    add_refugio;
    add_distinguishability;
  }
  size : 64;
}

table chrissie {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

table bagatelles {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

table potomac {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

table lichenological {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

table outcavilling {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

table hawklike {
  reads {
    shafting.frumenties : exact;
  }
  actions {
    skip;
    del_kranzburgs;
    del_superscouts;
    del_necker;
    del_mucho;
    del_refugio;
    del_distinguishability;
  }
  size : 64;
}

@pragma force_table_dependency anginal
table fatsias {
  actions {
    after;
    }
    size : 1;
  }

control ingress {
  apply(tinnie);
  apply(chrissie);
  apply(bagatelles);
  apply(potomac);
  apply(lichenological);
  apply(outcavilling);
  apply(hawklike);
  apply(workmanlike);
  apply(kanangas);
  apply(rufus);
  apply(delanceys);
  apply(anginal);
  apply(fatsias);
}
