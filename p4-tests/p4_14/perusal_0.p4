/* p4smith seed: 407820081 */
#include <tofino/intrinsic_metadata.p4>
header_type mussier {
  fields {
    ordures : 5;
    dogcarts : 16 (signed);
    placebos : 32;
    hectometres : 8;
    natty : 3;
    admixed : 8;
  }
}

header_type dendrites {
  fields {
    complication : 5;
    confinements : 8;
    razzed : 7;
    noncrystalline : 9;
    prisoners : 11;
    welcomes : 48 (signed, saturating);
    extensions : 16 (signed, saturating);
  }
}

header_type cesspool {
  fields {
    odditys : 2;
    shipbuilders : 2 (signed, saturating);
    nagy : 16;
    rastabans : 8 (signed, saturating);
    histologists : 4;
  }
}

header_type salinger {
  fields {
    epistle : 5;
    jam : 7;
    showjumping : 8;
    slyer : 8;
    packinghouses : 4 (signed, saturating);
    commingles : 48;
  }
}

header_type unethical {
  fields {
    hipsters : 6;
    impartially : 2 (signed, saturating);
    thence : 8 (signed);
    hatstands : 16 (signed);
  }
}

header mussier shamelessness;

header dendrites countersignatures;

header cesspool airbags;

header salinger jerky;

header unethical sapsucker;

parser start {
  return parse_shamelessness;
}

parser parse_shamelessness {
  extract(shamelessness);
  return select (latest.hectometres) {
    71 : parse_countersignatures;
    27 : parse_jerky;
  }
}

parser parse_countersignatures {
  extract(countersignatures);
  return select (latest.complication) {
    4 : parse_airbags;
    9 : parse_sapsucker;
  }
}

parser parse_airbags {
  extract(airbags);
  return select (latest.nagy) {
    5392 : parse_jerky;
    27569 : parse_sapsucker;
  }
}

parser parse_jerky {
  extract(jerky);
  return select (latest.slyer) {
    29 : parse_sapsucker;
  }
}

parser parse_sapsucker {
  extract(sapsucker);
  return ingress;
}

field_list israeli {
  airbags;
  shamelessness.natty;
  jerky.slyer;
  shamelessness.placebos;
}

field_list preys {
  airbags.histologists;
  jerky.commingles;
  shamelessness.ordures;
  countersignatures.confinements;
  shamelessness.admixed;
  airbags.nagy;
  jerky.jam;
  shamelessness.natty;
}

field_list illinoisans {
  countersignatures.razzed;
  shamelessness.placebos;
  shamelessness.ordures;
  jerky.packinghouses;
  countersignatures.extensions;
  jerky.commingles;
  sapsucker.hatstands;
  jerky.epistle;
  countersignatures.welcomes;
  shamelessness.natty;
  shamelessness.dogcarts;
}

field_list natalies {
  countersignatures.extensions;
  jerky.jam;
  shamelessness.placebos;
  airbags.odditys;
  sapsucker.thence;
  jerky.showjumping;
}

field_list_calculation nudges {
  input {
    israeli;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation reinforces {
  input {
    preys;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation clerks {
  input {
    illinoisans;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field shamelessness.dogcarts {
  update clerks;
}

calculated_field sapsucker.hatstands {
  verify nudges;
  verify clerks;
  update clerks;
}

calculated_field airbags.nagy {
  update clerks;
  verify clerks;
  verify nudges;
}

calculated_field countersignatures.extensions {
  verify reinforces;
}

action bids() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action causal(malaysians, sarnoff, recommences) {
  add_to_field(sapsucker.thence, shamelessness.hectometres);
  subtract(shamelessness.placebos, shamelessness.placebos, shamelessness.placebos);
}

action carbides() {
  modify_field_rng_uniform(airbags.shipbuilders, 0, 7);
  modify_field_rng_uniform(jerky.epistle, 9, 15);
  add(jerky.packinghouses, 1, 7);
  subtract(countersignatures.confinements, shamelessness.admixed, countersignatures.confinements);
  modify_field_rng_uniform(countersignatures.prisoners, 1662, 2047);
  modify_field(shamelessness.hectometres, airbags.rastabans);
  modify_field(countersignatures.complication, shamelessness.ordures);
}

action cycladess(combo, inauspiciously, cautioning) {
  bit_or(airbags.rastabans, sapsucker.thence, shamelessness.admixed);
  add(airbags.odditys, 0, airbags.shipbuilders);
  add_header(countersignatures);
}

action_profile cranny {
  actions {
    carbides;
    causal;
  }
  size : 30;
}

action_profile nations {
  actions {
    cycladess;
    carbides;
    causal;
    bids;
  }
  size : 13;
}

action_profile lifts {
  actions {
    cycladess;
    carbides;
    causal;
    bids;
  }
  size : 4;
}

action_profile flashcards {
  actions {
    carbides;
  }
  size : 32;
}

table wikis {
  actions {
    bids;
    }
  }

table ru {
  actions {
    bids;
    cycladess;
    }
  }

table wont {
  reads {
    shamelessness : valid;
    shamelessness.ordures mask 4 : exact;
    shamelessness.dogcarts : exact;
    shamelessness.placebos mask 0 : exact;
    shamelessness.hectometres mask 2 : exact;
    airbags.odditys : ternary;
    airbags.shipbuilders : exact;
    airbags.nagy : exact;
  }
  action_profile : flashcards;
}

table flightier {
  action_profile : nations;
  }

table photocells {
  reads {
    shamelessness.ordures : exact;
    shamelessness.natty : exact;
    shamelessness.admixed : exact;
    countersignatures.confinements : exact;
    countersignatures.welcomes : exact;
    countersignatures.extensions : lpm;
    airbags : valid;
    airbags.odditys : exact;
    airbags.shipbuilders : exact;
    airbags.nagy : ternary;
    airbags.rastabans : ternary;
    airbags.histologists mask 0 : exact;
    jerky : valid;
    jerky.commingles : exact;
    sapsucker.impartially : lpm;
    sapsucker.thence : exact;
    sapsucker.hatstands : ternary;
  }
  action_profile : lifts;
}

table medicos {
  reads {
    sapsucker : valid;
  }
  actions {
    bids;
    carbides;
    cycladess;
  }
}

table exhorts {
  reads {
    shamelessness.ordures : exact;
    shamelessness.dogcarts : exact;
    shamelessness.placebos : exact;
    countersignatures : valid;
    airbags.odditys : exact;
    airbags.shipbuilders : exact;
    airbags.nagy : exact;
    airbags.rastabans : exact;
    airbags.histologists : exact;
    jerky.jam : range;
    jerky.showjumping mask 1 : lpm;
    jerky.slyer : exact;
    jerky.packinghouses : lpm;
  }
  actions {
    cycladess;
  }
}

table glamoured {
  reads {
    shamelessness : valid;
    shamelessness.ordures : lpm;
    shamelessness.dogcarts : ternary;
    shamelessness.placebos : ternary;
    shamelessness.hectometres : ternary;
    shamelessness.admixed : exact;
    jerky : valid;
    jerky.epistle : exact;
    jerky.showjumping : exact;
    jerky.commingles mask 40 : exact;
    sapsucker : valid;
    sapsucker.hipsters : exact;
    sapsucker.impartially : exact;
    sapsucker.thence : exact;
  }
  action_profile : cranny;
}

table hawking {
  reads {
    jerky : valid;
    jerky.jam : exact;
    jerky.showjumping : exact;
    jerky.slyer : exact;
    jerky.packinghouses : exact;
    sapsucker : valid;
  }
  actions {
    cycladess;
  }
}

table savour {
  reads {
    shamelessness : valid;
    shamelessness.dogcarts : lpm;
    countersignatures.confinements : lpm;
    countersignatures.razzed : exact;
    countersignatures.noncrystalline : exact;
    countersignatures.prisoners : exact;
    countersignatures.extensions : ternary;
    airbags.odditys : ternary;
    airbags.shipbuilders : exact;
    airbags.nagy : exact;
    airbags.rastabans : exact;
    airbags.histologists : exact;
  }
  actions {
    
  }
}

table repudiating {
  actions {
    carbides;
    causal;
    cycladess;
    }
  }

table innersole {
  reads {
    countersignatures : valid;
    countersignatures.complication : lpm;
    countersignatures.confinements : exact;
    countersignatures.noncrystalline : lpm;
    countersignatures.welcomes : lpm;
    countersignatures.extensions : lpm;
    jerky : valid;
    jerky.epistle : lpm;
    jerky.jam : lpm;
    jerky.slyer : exact;
    jerky.packinghouses : exact;
  }
  actions {
    
  }
}

table concertinaing {
  actions {
    
    }
  }

table runways {
  reads {
    shamelessness : valid;
    shamelessness.ordures : lpm;
    countersignatures : valid;
    countersignatures.complication : ternary;
    countersignatures.confinements : exact;
    countersignatures.razzed : lpm;
    countersignatures.noncrystalline mask 6 : lpm;
    airbags : valid;
    airbags.odditys : lpm;
  }
  actions {
    
  }
}

control ingress {
  if ((shamelessness.natty != countersignatures.prisoners)) {
    apply(ru);
    apply(wont);
    apply(flightier);
  } else {
    apply(photocells);
  }
  apply(medicos);
  if (not((sapsucker.thence < 107))) {
    apply(exhorts);
    apply(glamoured);
    apply(hawking);
  }
  apply(savour);
  apply(repudiating);
  apply(innersole);
  apply(concertinaing);
  apply(runways);
}
