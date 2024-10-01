/* p4smith seed: 472562225 */
#include <tofino/intrinsic_metadata.p4>
header_type swimmers {
  fields {
    introductions : 16;
    permeability : 8;
    tompkins : 16;
    maharajahs : 32;
    vitalize : 32;
    chastisers : 32;
  }
}

header_type brusque {
  fields {
    papists : 32;
    hallucinogens : 48;
    chinos : 48;
    ventricles : 16;
    spottiness : 16;
    overcompensates : 8;
  }
}

header_type retrospects {
  fields {
    atomic : 8;
  }
}

header swimmers utilizations;

header brusque morison;

header retrospects swingers;

parser start {
  return parse_utilizations;
}

parser parse_utilizations {
  extract(utilizations);
  return select (current(0, 8)) {
    255 : parse_morison;
  }
}

parser parse_morison {
  extract(morison);
  return select (current(0, 8)) {
    61 : parse_swingers;
  }
}

parser parse_swingers {
  extract(swingers);
  return ingress;
}

action hitherto() {
  modify_field(standard_metadata.egress_spec, 1);
}

action existentialists() {
  add_header(swingers);
  add_to_field(utilizations.permeability, swingers.atomic);
  modify_field(utilizations.permeability, morison.overcompensates);
  subtract_from_field(morison.papists, utilizations.vitalize);
}

table preposterous {
  actions {
    hitherto;
    }
  }

table decanted {
  reads {
    morison.hallucinogens : exact;
  }
  actions {
    existentialists;
  }
}

table legatos {
  actions {
    existentialists;
    hitherto;
    }
  }

table prorogues {
  reads {
    morison : valid;
    morison.hallucinogens : ternary;
    swingers : valid;
  }
  actions {
    existentialists;
    hitherto;
  }
}

table depute {
  reads {
    utilizations.tompkins mask 6 : exact;
    utilizations.tompkins : exact;
    morison.spottiness mask 70 : exact;
  }
  actions {
    existentialists;
  }
}

control ingress {
  if ((2562 != swingers.atomic)) {
    apply(preposterous);
  }
  apply(decanted);
  apply(legatos);
  apply(prorogues);
  if ((swingers.atomic != 4041)) {
    apply(depute);
  }
}
