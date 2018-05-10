/* p4smith seed: 707736525 */
#include <tofino/intrinsic_metadata.p4>
header_type ashanti {
  fields {
    mitchels : 48;
  }
}

header_type rayleigh {
  fields {
    mouldier : 16;
    balloonists : 64;
    whiteouts : 16;
    nicetys : 16;
    teardrops : 8;
  }
}

header_type marilyns {
  fields {
    bohemians : 16;
    monopolizers : 64;
    stodgy : 32;
    raged : 32;
    levy : 48;
    distributing : 32;
  }
}

header_type tipsy {
  fields {
    lubricant : 16;
    parasympathetic : 16;
    seeder : 8;
  }
}

header_type rioter {
  fields {
    exclusions : 8;
    broken : 8;
    rebind : 48;
  }
}

header_type worcester {
  fields {
    chequerboard : 16;
    blathers : 16;
    cowhides : 16;
    concurs : 8;
  }
}

header ashanti seamed;

header rayleigh gymkhanas;

header marilyns splashier;

header tipsy kayos;

header rioter stigmatization;

header worcester verbenas;

parser start {
  return parse_seamed;
}

parser parse_seamed {
  extract(seamed);
  return select (current(0, 8)) {
    28 : parse_gymkhanas;
    65 : parse_verbenas;
  }
}

parser parse_gymkhanas {
  extract(gymkhanas);
  return select (latest.teardrops) {
    101 : parse_splashier;
    0 : parse_stigmatization;
    247 : parse_verbenas;
  }
}

parser parse_splashier {
  extract(splashier);
  return select (current(0, 8)) {
    101 : parse_kayos;
    248 : parse_verbenas;
  }
}

parser parse_kayos {
  extract(kayos);
  return select (latest.seeder) {
    0 : parse_stigmatization;
  }
}

parser parse_stigmatization {
  extract(stigmatization);
  return select (latest.broken) {
    95 : parse_verbenas;
  }
}

parser parse_verbenas {
  extract(verbenas);
  return ingress;
}

action libeling() {
  modify_field(standard_metadata.egress_spec, 1);
}

action apricots() {
  copy_header(splashier, splashier);
}

action conversationalists(lowenbrau, lyres) {
  bit_and(kayos.parasympathetic, gymkhanas.whiteouts, kayos.parasympathetic);
}

action lambencys(groupie, fever) {
  bit_or(verbenas.cowhides, kayos.parasympathetic, verbenas.cowhides);
}

table wrongness {
  actions {
    libeling;
    }
  }

table bigot {
  actions {
    conversationalists;
    }
  }

table quahog {
  reads {
    gymkhanas : valid;
    splashier.bohemians : exact;
    seamed : valid;
  }
  actions {
    conversationalists;
    lambencys;
  }
}

table mayos {
  actions {
    apricots;
    conversationalists;
    lambencys;
    libeling;
    }
  }

table gillian {
  reads {
    stigmatization : valid;
    stigmatization.exclusions mask 171 : range;
    gymkhanas.nicetys : exact;
  }
  actions {
    apricots;
  }
}

control ingress {
  if ((gymkhanas.teardrops == stigmatization.exclusions)) {
    apply(wrongness);
  }
  apply(bigot);
  apply(quahog);
  if ((gymkhanas.teardrops < stigmatization.broken)) {
    apply(mayos);
  }
  if ((stigmatization.broken > verbenas.concurs)) {
    apply(gillian);
  }
}
