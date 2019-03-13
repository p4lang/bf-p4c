/* p4smith seed: 411255803 */
#include <tofino/intrinsic_metadata.p4>
header_type overmuch {
  fields {
    phrenologys : 32;
    understandings : 16;
    quicksteps : 16;
    saprophytes : 8;
    prerecorded : 64;
    barkeepers : 32;
  }
}

header_type capulet {
  fields {
    christen : 16;
    macrames : 32;
    liturgists : 32;
    gilliams : 32;
    refillable : 32;
  }
}

header_type chinatown {
  fields {
    underway : 16;
  }
}

header_type lumbers {
  fields {
    underskirt : 16;
    gearwheels : 16;
    banishment : 16;
    maggot : 64;
  }
}

header_type coalescences {
  fields {
    slathered : 32;
    methodisms : 48;
    hegelian : 16;
    nixed : 16;
    infantrys : 16;
  }
}

header overmuch mortally;

header capulet preppy;

header chinatown deadening;

header lumbers carers;

header coalescences sputniks;

parser start {
  return parse_mortally;
}

parser parse_mortally {
  extract(mortally);
  return select (current(0, 8)) {
    0 : parse_preppy;
  }
}

parser parse_preppy {
  extract(preppy);
  return select (current(0, 8)) {
    193 : parse_deadening;
    125 : parse_sputniks;
    86 : parse_carers;
  }
}

parser parse_deadening {
  extract(deadening);
  return select (latest.underway) {
    6467 : parse_carers;
  }
}

parser parse_carers {
  extract(carers);
  return select (latest.gearwheels) {
    7139 : parse_sputniks;
  }
}

parser parse_sputniks {
  extract(sputniks);
  return ingress;
}

action reformations() {
  modify_field(standard_metadata.egress_spec, 1);
}

action emotionally() {
  add(preppy.liturgists, mortally.phrenologys, mortally.phrenologys);
  add_header(deadening);
}

action sliding(ambivalently, cantilevers) {
  copy_header(mortally, mortally);
  subtract_from_field(carers.gearwheels, sputniks.hegelian);
  remove_header(sputniks);
}

action cakewalks(splinters, wilds) {
  subtract(sputniks.hegelian, deadening.underway, carers.underskirt);
  copy_header(preppy, preppy);
}

action universal(impenitently) {
  bit_or(sputniks.hegelian, sputniks.nixed, preppy.christen);
  remove_header(deadening);
  modify_field(preppy.refillable, sputniks.slathered);
}

table carjackings {
  actions {
    reformations;
    }
  }

table archimedes {
  reads {
    carers.banishment : exact;
  }
  actions {
    cakewalks;
    emotionally;
    universal;
  }
}

table laypersons {
  reads {
    sputniks.methodisms : exact;
    mortally : valid;
  }
  actions {
    sliding;
  }
}

table guidance {
  reads {
    preppy : valid;
    deadening : valid;
    mortally.barkeepers : range;
  }
  actions {
    cakewalks;
    emotionally;
  }
}

table psychosis {
  reads {
    carers : valid;
    preppy : valid;
    sputniks.slathered mask 41 : range;
  }
  actions {
    sliding;
  }
}

control ingress {
  apply(carjackings);
  apply(archimedes);
  if (not(((((2553 > mortally.saprophytes) and (1668 > mortally.saprophytes)) or 
           (mortally.saprophytes < mortally.saprophytes)) and (1077 > 
                                                              mortally.saprophytes)))) {
    apply(laypersons);
  }
  apply(guidance);
  if ((2070 < 479)) {
    apply(psychosis);
  }
}
