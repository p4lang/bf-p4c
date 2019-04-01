/* p4smith seed: 67211532 */
#include <tofino/intrinsic_metadata.p4>
header_type unscrambled {
  fields {
    moiety : 16;
    fundamentally : 16;
    brays : 64;
    workaholics : 64;
    bob : 64 (signed, saturating);
    pleasantry : 16 (signed, saturating);
  }
}

header_type delhis {
  fields {
    edams : 32 (signed, saturating);
  }
}

header_type glowers {
  fields {
    theories : 64;
  }
}

header_type minoan {
  fields {
    hackishes : 64 (saturating);
    michiganite : 32;
    filibusters : 16;
    lyres : 64;
    enviousness : 32;
  }
}

header_type repletions {
  fields {
    unsearchable : 16;
  }
}

header unscrambled infatuations;

header delhis vexing;

header glowers ciders;

header minoan minnesotan;

header repletions physicists;

parser start {
  return parse_infatuations;
}

parser parse_infatuations {
  extract(infatuations);
  return select (current(0, 8)) {
    30 : parse_vexing;
    216 : parse_ciders;
    116 : parse_minnesotan;
  }
}

parser parse_vexing {
  extract(vexing);
  return select (current(0, 8)) {
    64 : parse_ciders;
  }
}

parser parse_ciders {
  extract(ciders);
  return select (current(0, 8)) {
    89 : parse_minnesotan;
    100 : parse_physicists;
  }
}

parser parse_minnesotan {
  extract(minnesotan);
  return select (latest.filibusters) {
    19706 : parse_physicists;
  }
}

parser parse_physicists {
  extract(physicists);
  return ingress;
}

field_list invoiced {
  ciders;
  vexing.edams;
}

field_list_calculation posits {
  input {
    invoiced;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field infatuations.fundamentally {
  update posits;
}

action multimillionaires() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action newtons(parers, analogizes) {
  copy_header(vexing, vexing);
  bit_or(infatuations.moiety, infatuations.pleasantry, 7639);
  subtract_from_field(physicists.unsearchable, minnesotan.filibusters);
  add(minnesotan.enviousness, minnesotan.enviousness, 1333354503);
  subtract(infatuations.fundamentally, 0, 15961);
}

action crazes(lengths, wilted) {
  add(physicists.unsearchable, infatuations.fundamentally, infatuations.moiety);
}

action peas() {
  copy_header(minnesotan, minnesotan);
  bit_and(vexing.edams, 0, vexing.edams);
  remove_header(vexing);
  subtract(infatuations.fundamentally, 7563, 30712);
  copy_header(ciders, ciders);
  bit_xor(infatuations.moiety, 44693, 1693);
  add(physicists.unsearchable, physicists.unsearchable, physicists.unsearchable);
}

table thousandfold {
  actions {
    multimillionaires;
    }
  }

table motocrosss {
  actions {
    multimillionaires;
    }
  }

table upbringing {
  actions {
    crazes;
    newtons;
    peas;
    }
  }

control ingress {
  apply(thousandfold);
  apply(motocrosss);
  if (not(true)) {
    apply(upbringing);
  }
}
