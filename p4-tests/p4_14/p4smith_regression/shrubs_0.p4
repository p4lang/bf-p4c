/* p4smith seed: 701015732 */
#include <tofino/intrinsic_metadata.p4>
header_type dominatrix {
  fields {
    contingents : 16;
    articles : 16;
  }
}

header_type kits {
  fields {
    leonidas : 128;
    godmothers : 48;
    blackwell : 32;
    pardner : 48;
    attendances : 48;
  }
}

header dominatrix regrow;

header kits arpeggios;

register scourged {
  width : 16;
  instance_count : 8;
}

register wanna {
  width : 8;
  instance_count : 121;
}

register necropolises {
  width : 16;
  instance_count : 361;
}

register nostrums {
  width : 64;
  instance_count : 776;
}

register oct {
  width : 128;
  instance_count : 409;
}

register lamars {
  width : 16;
  instance_count : 68;
}

register frankfort {
  width : 32;
  instance_count : 974;
}

register downsides {
  width : 32;
  instance_count : 976;
}

register nexis {
  width : 48;
  instance_count : 127;
}

register motivator {
  width : 32;
  instance_count : 601;
}

parser start {
  return parse_regrow;
}

parser parse_regrow {
  extract(regrow);
  return select (latest.articles) {
    31687 : parse_arpeggios;
  }
}

parser parse_arpeggios {
  extract(arpeggios);
  return ingress;
}

field_list syllabus {
  regrow.articles;
  regrow.contingents;
  arpeggios;
  regrow;
  arpeggios.leonidas;
  arpeggios.pardner;
  arpeggios;
  arpeggios.blackwell;
  arpeggios.godmothers;
  arpeggios;
  arpeggios.leonidas;
  arpeggios.godmothers;
  arpeggios.pardner;
  regrow;
  regrow;
  regrow;
}

field_list_calculation waveband {
  input {
    syllabus;
  }
  algorithm : xor16;
  output_width : 32;
}

calculated_field regrow.articles {
  verify waveband if (valid(regrow));
  update waveband if (arpeggios.godmothers == 27);
  update waveband if (valid(arpeggios));
}

action mongol() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action intervocalic(hitchhikers, caster) {
  bit_and(regrow.articles, regrow.articles, regrow.articles);
  add_to_field(arpeggios.blackwell, arpeggios.blackwell);
  bit_and(regrow.contingents, regrow.contingents, regrow.contingents);
}

table shamrocks {
  actions {
    mongol;
    }
  }

table pythagoras {
  reads {
    regrow : valid;
    regrow.contingents mask 222 : exact;
  }
  actions {
    intervocalic;
  }
}

control ingress {
  if ((regrow.contingents == regrow.contingents)) {
    apply(shamrocks);
  }
  apply(pythagoras);
}
