/* p4smith seed: 1014366340 */
#include <tofino/intrinsic_metadata.p4>
header_type telegraphese {
  fields {
    mosques : 128 (saturating);
    mussels : 8;
    inhumanely : 16 (signed);
    clambers : 32;
  }
}

header_type exposed {
  fields {
    almighty : 48;
    transitional : 16 (signed, saturating);
    unwind : 64 (saturating);
    personified : 128;
  }
}

header_type habituation {
  fields {
    titches : 16 (saturating);
    yorks : 8 (saturating);
    capos : 64 (saturating);
  }
}

header_type aggrieve {
  fields {
    rents : 64;
    ganglands : 48;
    mayor : 16;
    outsold : 32 (signed);
    photometers : 32;
    what : 64 (signed, saturating);
  }
}

header_type globular {
  fields {
    throttles : 8;
    nullitys : 32;
    outworkers : 128;
    streetcars : 64 (signed, saturating);
  }
}

header telegraphese garroters;

header exposed summits;

header habituation overdoes;

header aggrieve dropkicks;

header globular procrastinators;

register hardheartedly {
  width : 16;
  instance_count : 613;
}

register boyishness {
  width : 64;
  instance_count : 879;
}

register winstons {
  width : 16;
  instance_count : 234;
}

register rutans {
  width : 8;
  instance_count : 1024;
}

register stacies {
  width : 16;
  instance_count : 196;
}

register lovelorn {
  width : 16;
  instance_count : 970;
}

register rasps {
  width : 64;
  instance_count : 425;
}

register earrings {
  width : 128;
  instance_count : 454;
}

register teasels {
  width : 32;
  instance_count : 734;
}

register candles {
  width : 64;
  instance_count : 10;
}

parser start {
  return parse_garroters;
}

parser parse_garroters {
  extract(garroters);
  return select (current(0, 8)) {
    0 : parse_summits;
    117 : parse_overdoes;
  }
}

parser parse_summits {
  extract(summits);
  return select (current(0, 8)) {
    176 : parse_dropkicks;
    37 : parse_overdoes;
  }
}

parser parse_overdoes {
  extract(overdoes);
  return select (current(0, 8)) {
    41 : parse_dropkicks;
  }
}

parser parse_dropkicks {
  extract(dropkicks);
  return select (current(0, 8)) {
    214 : parse_procrastinators;
  }
}

parser parse_procrastinators {
  extract(procrastinators);
  return ingress;
}

field_list twigs {
  procrastinators;
  garroters.clambers;
  dropkicks;
  overdoes;
  summits;
  procrastinators.outworkers;
  garroters;
  garroters.mussels;
  dropkicks.outsold;
  garroters.mosques;
  summits;
  dropkicks.ganglands;
  overdoes;
}

field_list untouchable {
  summits;
  dropkicks.what;
  procrastinators.outworkers;
  summits;
  procrastinators;
  dropkicks.photometers;
  overdoes.titches;
  summits;
  dropkicks.mayor;
  summits;
  overdoes.capos;
}

field_list heels {
  summits.almighty;
  garroters;
}

field_list graves {
  summits.almighty;
  dropkicks.outsold;
}

field_list_calculation sparest {
  input {
    heels;
  }
  algorithm : csum16;
  output_width : 8;
}

field_list_calculation invaded {
  input {
    twigs;
  }
  algorithm : xor16;
  output_width : 16;
}

field_list_calculation endoscopic {
  input {
    heels;
  }
  algorithm : crc16;
  output_width : 8;
}

calculated_field dropkicks.mayor {
  verify sparest;
}

action dervishes() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action gimmes(glowers, dee) {
  add_to_field(summits.transitional, overdoes.titches);
  add(garroters.clambers, dropkicks.outsold, dropkicks.photometers);
  add(dropkicks.outsold, dropkicks.outsold, dropkicks.outsold);
  copy_header(procrastinators, procrastinators);
  modify_field(garroters.inhumanely, dropkicks.mayor);
  remove_header(overdoes);
}

action stallions(tocsins, triggers) {
  bit_or(overdoes.yorks, garroters.mussels, 155);
}

action freshened(favouritisms) {
  copy_header(procrastinators, procrastinators);
  remove_header(summits);
  copy_header(dropkicks, dropkicks);
}

action indecision(overage, aspiration) {
  subtract_from_field(garroters.clambers, dropkicks.photometers);
}

table disembodiment {
  actions {
    dervishes;
    }
  }

table callousnesss {
  actions {
    dervishes;
    stallions;
    }
  }

table plainsong {
  reads {
    garroters : valid;
    garroters.mussels mask 245 : lpm;
    dropkicks.ganglands : exact;
  }
  actions {
    indecision;
  }
}

table ripostes {
  reads {
    overdoes : valid;
    overdoes.titches mask 116 : range;
    overdoes.yorks : lpm;
    dropkicks.outsold : exact;
    dropkicks.photometers : lpm;
  }
  actions {
    stallions;
  }
}

table scantest {
  actions {
    freshened;
    indecision;
    stallions;
    }
  }

control ingress {
  if (false) {
    apply(disembodiment);
  }
  apply(callousnesss);
  apply(plainsong);
  if (not(((84 <= garroters.clambers) or (overdoes.yorks <= 83)))) {
    apply(ripostes);
  }
  if ((dropkicks.mayor < 104)) {
    apply(scantest);
  }
}
