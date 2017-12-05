/* Headers */
header_type banneker_t {
  fields {
    downbeat : 23;
    reissues : 31;
    banneker_padding : 2;
  }
}

header banneker_t banneker;

/* Parser */
parser start {
  return parse_banneker;
}
parser parse_banneker {
  extract(banneker);
  return ingress;
}

/* Actions */
action banneker_defections () {
  add_to_field(banneker.reissues,38);
  subtract_from_field(banneker.banneker_padding,43);
}

action banneker_charisma () {
  modify_field(banneker.banneker_padding,0);
  add_to_field(banneker.reissues,31);
}

action banneker_acquisitions () {
  modify_field(banneker.reissues,25);
  subtract_from_field(banneker.downbeat,42);
}

action banneker_monicker () {
  subtract_from_field(banneker.reissues,48);
}

action banneker_hamlets () {
  add_to_field(banneker.reissues,59);
  modify_field(banneker.downbeat,56);
}

/* Tables */
table larding {
  reads {
    banneker.downbeat : ternary;
    banneker.banneker_padding : range;
    banneker.reissues : lpm;
  }
  actions {
    banneker_defections;
    banneker_hamlets;
  }
  size : 6;
}

table raconteurs {
  reads {
    banneker.downbeat : lpm;
    banneker.reissues : ternary;
    banneker.banneker_padding : exact;
  }
  actions {
    banneker_defections;
    banneker_charisma;
    banneker_monicker;
  }
  size : 2;
}

table personnels {
  reads {
    banneker.downbeat : range;
    banneker.reissues : ternary;
  }
  actions {
    banneker_monicker;
  }
  size : 2;
}

table allegorys {
  reads {
    banneker.reissues : exact;
    banneker.downbeat : ternary;
  }
  actions {
    banneker_charisma;
  }
  size : 5;
}

table probables {
  reads {
    banneker.downbeat : lpm;
    banneker.banneker_padding : range;
    banneker.reissues : exact;
  }
  actions {
    banneker_acquisitions;
  }
  size : 0;
}

table serenenesss {
  reads {
    banneker.reissues : range;
    banneker.banneker_padding : ternary;
  }
  actions {
    banneker_defections;
  }
  size : 4;
}

table scrambles {
  reads {
    banneker.banneker_padding : lpm;
    banneker.downbeat : range;
  }
  actions {
    banneker_acquisitions;
    banneker_defections;
  }
  size : 4;
}

table bozos {
  reads {
    banneker.reissues : lpm;
    banneker.downbeat : exact;
    banneker.banneker_padding : exact;
  }
  actions {
    banneker_monicker;
    banneker_charisma;
    banneker_hamlets;
  }
  size : 4;
}
/* Controls */
control ingress {
  apply(allegorys);
  if (not valid(banneker) or not not false) {
  apply(probables);
} else {
  apply(serenenesss);
  apply(scrambles);
  apply(bozos);
}
}

control burnouses {
  apply(larding);
  apply(raconteurs);
  apply(personnels);
}

