/* p4smith seed: 518643867 */
#include <tofino/intrinsic_metadata.p4>
header_type firebricks {
  fields {
    heiresss : 16;
    bookbindings : 16;
    armature : 16;
    dishwater : 48;
    tagus : 16;
    studbook : 8;
  }
}

header_type abner {
  fields {
    confucianism : 8;
    railed : 32;
    lake : 16;
    startle : 16;
    deans : 16;
    houseboy : 48;
  }
}

header_type pennsylvanians {
  fields {
    tappets : 16;
    leonas : 48;
  }
}

header firebricks anchor;

header abner connote;

header pennsylvanians parasympathetics;

parser start {
  return parse_anchor;
}

parser parse_anchor {
  extract(anchor);
  return select (latest.heiresss) {
    4086 : parse_connote;
  }
}

parser parse_connote {
  extract(connote);
  return select (current(0, 8)) {
    162 : parse_parasympathetics;
  }
}

parser parse_parasympathetics {
  extract(parasympathetics);
  return ingress;
}

action twining() {
  modify_field(standard_metadata.egress_spec, 1);
}

action possum(unoccupied) {
  remove_header(parasympathetics);
}

action lasses(guess) {
  add_to_field(connote.lake, guess);
  add_to_field(connote.lake, guess);
  add_header(parasympathetics);
  add_to_field(parasympathetics.tappets, guess);
}

action personifications(bursaries, 
  structuralists) {
  modify_field(anchor.armature, bursaries);
  add_to_field(connote.railed, parasympathetics.tappets);
}

action geniality(scofflaws, 
  healthiness) {
  subtract(parasympathetics.tappets, parasympathetics.tappets, scofflaws);
  subtract_from_field(anchor.tagus, 10);
  modify_field(connote.houseboy, healthiness);
}

table quadrilateral {
  actions {
    twining;
    }
  }

table inconspicuously {
  actions {
    lasses;
    twining;
    }
  }

control ingress {
  apply(quadrilateral);
  apply(inconspicuously);
}
