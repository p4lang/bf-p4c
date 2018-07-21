/* p4smith seed: 989460419 */
#include <tofino/intrinsic_metadata.p4>
header_type unsounder {
  fields {
    compounds : 16;
    mismatching : 48;
  }
}

header_type boorish {
  fields {
    pantomiming : 8;
  }
}

header_type reanalysiss {
  fields {
    litanys : 48;
  }
}

header_type restrainer {
  fields {
    revises : 8 (signed, saturating);
  }
}

header_type ruts {
  fields {
    spaciness : 64;
  }
}

header unsounder moriarty;

header boorish dottier;

header reanalysiss nominal;

header restrainer bermudas;

header ruts smashes;

register tired {
  width : 8;
  instance_count : 405;
}

register smithereens {
  width : 8;
  instance_count : 482;
}

register entree {
  width : 8;
  instance_count : 95;
}

register chili {
  width : 32;
  instance_count : 729;
}

register shoplifters {
  width : 16;
  instance_count : 149;
}

register minus {
  width : 16;
  instance_count : 337;
}

register acculturates {
  width : 8;
  instance_count : 483;
}

register maniocs {
  width : 8;
  instance_count : 987;
}

register voluptuousness {
  width : 16;
  instance_count : 298;
}

parser start {
  return parse_moriarty;
}

parser parse_moriarty {
  extract(moriarty);
  return select (latest.compounds) {
    31367 : parse_dottier;
    23299 : parse_bermudas;
    16910 : parse_smashes;
  }
}

parser parse_dottier {
  extract(dottier);
  return select (latest.pantomiming) {
    104 : parse_nominal;
  }
}

parser parse_nominal {
  extract(nominal);
  return select (current(0, 8)) {
    249 : parse_bermudas;
    81 : parse_smashes;
  }
}

parser parse_bermudas {
  extract(bermudas);
  return select (latest.revises) {
    27 : parse_smashes;
  }
}

parser parse_smashes {
  extract(smashes);
  return ingress;
}

field_list nonabsorbents {
  smashes;
  73;
  bermudas;
  bermudas;
  moriarty;
  bermudas.revises;
  dottier.pantomiming;
  moriarty.compounds;
  nominal.litanys;
  bermudas;
  moriarty.mismatching;
  moriarty.mismatching;
  moriarty.compounds;
  smashes;
  232;
  dottier.pantomiming;
}

field_list underneath {
  138;
  dottier.pantomiming;
  smashes;
  smashes.spaciness;
  moriarty;
  moriarty;
}

field_list_calculation shiploads {
  input {
    underneath;
    nonabsorbents;
  }
  algorithm : xor16;
  output_width : 32;
}

field_list_calculation awfulness {
  input {
    nonabsorbents;
  }
  algorithm : crc16;
  output_width : 16;
}

field_list_calculation hazings {
  input {
    nonabsorbents;
  }
  algorithm : xor16;
  output_width : 16;
}

field_list_calculation bows {
  input {
    underneath;
    nonabsorbents;
  }
  algorithm : crc32;
  output_width : 128;
}

calculated_field bermudas.revises {
  verify shiploads if (valid(nominal));
  update awfulness;
  update awfulness;
  verify awfulness if (dottier.pantomiming == 0);
}

calculated_field dottier.pantomiming {
  verify bows if (valid(nominal));
  update awfulness if (valid(bermudas));
  verify awfulness;
  verify bows if (valid(smashes));
}

calculated_field moriarty.mismatching {
  update bows;
  verify hazings if (smashes.spaciness == 42);
}

action grabbier() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action readabilities(crossings, endeavoring) {
  bit_or(moriarty.compounds, 0, moriarty.compounds);
  add_to_field(dottier.pantomiming, 3);
  copy_header(smashes, smashes);
  bit_or(bermudas.revises, bermudas.revises, 0);
}

action criticism(turbiditys) {
  add_to_field(dottier.pantomiming, dottier.pantomiming);
  bit_and(bermudas.revises, bermudas.revises, 23);
  bit_or(moriarty.compounds, 0, 23584);
  remove_header(nominal);
  modify_field(smashes.spaciness, 1716110647);
  add_header(dottier);
  copy_header(nominal, nominal);
  add_header(dottier);
}

table inns {
  actions {
    grabbier;
    }
  }

table semanticists {
  reads {
    bermudas.revises mask 46 : lpm;
  }
  actions {
    criticism;
    grabbier;
    readabilities;
  }
}

table beclouds {
  reads {
    nominal.litanys : lpm;
    bermudas : valid;
    bermudas.revises mask 236 : exact;
  }
  actions {
    criticism;
    grabbier;
    readabilities;
  }
}

table postdoctoral {
  actions {
    criticism;
    readabilities;
    }
  }

control ingress {
  if (valid(dottier)) {
    apply(inns);
  }
  if ((valid(moriarty) or ((valid(nominal) and (dottier.pantomiming != 
                                               2103751603)) or ((255 > 
                                                                1467545281) or 
                                                               (1100249902 != 
                                                               moriarty.compounds))))) {
    apply(semanticists);
  }
  if ((moriarty.compounds != bermudas.revises)) {
    apply(beclouds);
  }
  apply(postdoctoral);
}
