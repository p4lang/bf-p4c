/* p4smith seed: 2339959 */
#include <tofino/intrinsic_metadata.p4>
header_type purees {
  fields {
    desalinized : 16 (signed, saturating);
    tammi : 48 (saturating);
    expeditiousnesss : 16 (signed);
    scopess : 16 (saturating);
    claibornes : 16;
    decadencys : 32 (signed, saturating);
  }
}

header_type snazzily {
  fields {
    ornately : 16;
    windscreen : 64 (signed, saturating);
    cafes : 32;
  }
}

header purees bolt;

header snazzily jeannette;

register clarices {
  width : 16;
  instance_count : 208;
}

register enforceable {
  width : 48;
  instance_count : 124;
}

register tact {
  width : 128;
  instance_count : 31;
}

register petrifies {
  width : 32;
  instance_count : 594;
}

register overprints {
  width : 48;
  instance_count : 501;
}

register grossly {
  width : 16;
  instance_count : 1024;
}

register armholes {
  width : 48;
  instance_count : 891;
}

register letters {
  width : 64;
  instance_count : 340;
}

parser start {
  return parse_bolt;
}

parser parse_bolt {
  extract(bolt);
  return select (current(0, 8)) {
    79 : parse_jeannette;
  }
}

parser parse_jeannette {
  extract(jeannette);
  return ingress;
}

field_list maxis {
  bolt.tammi;
  bolt.scopess;
  jeannette.windscreen;
  bolt.claibornes;
  bolt.decadencys;
  jeannette.cafes;
  bolt.desalinized;
}

field_list tearaways {
  jeannette.ornately;
  jeannette.windscreen;
  bolt.desalinized;
  bolt.expeditiousnesss;
  jeannette.cafes;
}

field_list_calculation muckraking {
  input {
    maxis;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation stylistics {
  input {
    maxis;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation jouncing {
  input {
    tearaways;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation corrals {
  input {
    maxis;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field bolt.desalinized {
  update jouncing;
  verify muckraking;
}

action buttercups() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action unscathed(concertos) {
  add_to_field(bolt.decadencys, jeannette.cafes);
  modify_field(bolt.claibornes, 17034);
}

action stood() {
  register_write(grossly, 491, bolt.scopess);
  subtract_from_field(bolt.scopess, bolt.desalinized);
  register_read(bolt.tammi, overprints, 435);
}

action empowerment() {
  copy_header(bolt, bolt);
}

table nassau {
  actions {
    buttercups;
    }
  }

table euphemism {
  reads {
    jeannette : valid;
    jeannette.cafes : exact;
  }
  actions {
    buttercups;
    empowerment;
    unscathed;
  }
}

control ingress {
  if (valid(bolt)) {
    apply(nassau);
  }
  apply(euphemism);
}
