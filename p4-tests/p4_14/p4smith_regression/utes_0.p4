/* p4smith seed: 121251466 */
#include <tofino/intrinsic_metadata.p4>
header_type probationer {
  fields {
    thanhs : 32 (saturating);
  }
}

header_type penetrates {
  fields {
    iqs : 16;
  }
}

header_type whitehorses {
  fields {
    daffy : 16 (signed);
    disclaims : 16;
  }
}

header probationer picturing;

header penetrates revel;

header whitehorses paraguayans;

register amigos {
  width : 16;
  instance_count : 249;
}

parser start {
  return parse_picturing;
}

parser parse_picturing {
  extract(picturing);
  return select (current(0, 8)) {
    20 : parse_revel;
    151 : parse_paraguayans;
  }
}

parser parse_revel {
  extract(revel);
  return select (latest.iqs) {
    37376 : parse_paraguayans;
  }
}

parser parse_paraguayans {
  extract(paraguayans);
  return ingress;
}

field_list clairvoyance {
  paraguayans.daffy;
  paraguayans.disclaims;
  picturing;
  revel.iqs;
  picturing.thanhs;
}

field_list_calculation endorphin {
  input {
    clairvoyance;
  }
  algorithm : crc32;
  output_width : 128;
}

field_list_calculation demotivating {
  input {
    clairvoyance;
  }
  algorithm : crc32;
  output_width : 64;
}

field_list_calculation singapore {
  input {
    clairvoyance;
  }
  algorithm : crc32;
  output_width : 16;
}

field_list_calculation vindicate {
  input {
    clairvoyance;
  }
  algorithm : crc16;
  output_width : 128;
}

calculated_field revel.iqs {
  verify demotivating;
  verify endorphin if (revel.iqs == 14);
  verify endorphin if (picturing.thanhs == 6);
  update singapore if (revel.iqs == 16);
}

action dillinger() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action weeing() {
  copy_header(picturing, picturing);
  register_write(amigos, 112, paraguayans.daffy);
  bit_xor(paraguayans.disclaims, revel.iqs, 35543);
  remove_header(revel);
  bit_and(revel.iqs, paraguayans.daffy, 6398);
}

table subdivides {
  actions {
    dillinger;
    }
  }

table depopulation {
  actions {
    dillinger;
    }
  }

table congolese {
  reads {
    picturing : valid;
    picturing.thanhs : lpm;
    paraguayans.daffy : ternary;
  }
  actions {
    dillinger;
    weeing;
  }
}

table sherees {
  actions {
    dillinger;
    }
  }

table hugo {
  actions {
    dillinger;
    weeing;
    }
  }

control ingress {
  if (valid(revel)) {
    apply(subdivides);
  }
  if (valid(paraguayans)) {
    apply(depopulation);
  }
  if ((997804138 != paraguayans.disclaims)) {
    apply(congolese);
  }
  apply(sherees);
  apply(hugo);
}
