/* p4smith seed: 963025131 */
#include <tofino/intrinsic_metadata.p4>
header_type malicious {
  fields {
    auditioning : 64;
    surveys : 32;
    stevie : 8;
    interlude : 8;
  }
}

header_type glossolalias {
  fields {
    dewclaws : 32;
  }
}

header malicious silesia;

header glossolalias communisms;

register strafes {
  width : 32;
  instance_count : 913;
}

register compellingly {
  width : 48;
  instance_count : 65;
}

register baseboard {
  width : 16;
  instance_count : 498;
}

parser start {
  return parse_silesia;
}

parser parse_silesia {
  extract(silesia);
  return select (latest.interlude) {
    38 : parse_communisms;
  }
}

parser parse_communisms {
  extract(communisms);
  return ingress;
}

field_list impatience {
  silesia.interlude;
  silesia.surveys;
}

field_list_calculation dicing {
  input {
    impatience;
  }
  algorithm : crc32;
  output_width : 16;
}

field_list_calculation riposted {
  input {
    impatience;
  }
  algorithm : crc16;
  output_width : 48;
}

field_list_calculation nabs {
  input {
    impatience;
  }
  algorithm : crc16;
  output_width : 32;
}

field_list_calculation injurers {
  input {
    impatience;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field silesia.stevie {
  update dicing if (silesia.interlude == 5);
  update injurers if (valid(communisms));
}

calculated_field communisms.dewclaws {
#ifdef __p4c__
  verify riposted;
#else
  verify riposted if (valid(silesia));
#endif
}

action josefs() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action caviled(maned) {
  subtract(silesia.interlude, silesia.interlude, silesia.interlude);
  add_to_field(communisms.dewclaws, 0);
  add_to_field(silesia.stevie, 19);
  modify_field(silesia.auditioning, silesia.auditioning);
}

action ref(aniline) {
  add(silesia.interlude, silesia.stevie, silesia.stevie);
  bit_xor(silesia.surveys, silesia.surveys, communisms.dewclaws);
  bit_xor(silesia.stevie, silesia.stevie, 107);
  bit_and(communisms.dewclaws, communisms.dewclaws, communisms.dewclaws);
  add_header(silesia);
}

action psychotropic() {
  add_header(silesia);
  bit_or(silesia.interlude, silesia.stevie, silesia.interlude);
  add_to_field(silesia.stevie, silesia.stevie);
  remove_header(communisms);
  register_write(strafes, 775, silesia.surveys);
  add_header(silesia);
  add(communisms.dewclaws, communisms.dewclaws, 161248892);
  add(silesia.surveys, 2147483647, silesia.surveys);
}

action libby(nut, revelation) {
  register_read(silesia.surveys, strafes, 13);
}

table belletrist {
  actions {
    josefs;
    }
  }

table mumblers {
  actions {
    josefs;
    libby;
    ref;
    }
  }

control ingress {
  if ((silesia.stevie >= 96)) {
    apply(belletrist);
  }
  if (false) {
    apply(mumblers);
  }
}
