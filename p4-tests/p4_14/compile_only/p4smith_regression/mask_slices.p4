/* p4smith seed: 200940073 */
#include <tofino/intrinsic_metadata.p4>
header_type ceaselessness {
  fields {
    briefness : 6;
    eruditely : 2;
    wreckages : 8;
  }
}

header_type filter {
  fields {
    science : 16;
    supervene : 32;
    almoners : 8;
  }
}

header ceaselessness unique;

header filter friendships;

register lace {
  width : 16;
  instance_count : 1;
}

register clamours {
  width : 1;
  instance_count : 486;
}

register croquettes {
  width : 16;
  instance_count : 919;
}

register graceless {
  width : 1;
  instance_count : 48;
}

register rotten {
  width : 16;
  instance_count : 605;
}

parser start {
  return parse_unique;
}

parser parse_unique {
  extract(unique);
  return select (latest.wreckages) {
    127 : parse_friendships;
  }
}

parser parse_friendships {
  extract(friendships);
  return ingress;
}

field_list afrikaners {
  friendships.almoners;
  friendships.supervene;
  unique.wreckages;
  friendships.science;
}

field_list encephalitic {
  friendships.science;
  unique.wreckages;
  friendships.almoners;
  friendships.supervene;
}

field_list_calculation natalias {
  input {
    afrikaners;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field friendships.science {
  update natalias;
  verify natalias;
  update natalias;
}

action policies() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action refasten(hastier, bloodied, boyhood) {
  bit_xor(friendships.science, 4197069485669653672, 3554115962289989977);
  add_header(friendships);
  bit_or(friendships.supervene, friendships.supervene, friendships.supervene);
  modify_field_rng_uniform(unique.wreckages, 0, 31);
  bit_and(friendships.almoners, friendships.almoners, 4076683810936956303);
  modify_field_rng_uniform(unique.briefness, 0, 63);
}

action_profile siestas {
  actions {
    policies;
  }
  size : 25;
}

action_profile chestful {
  actions {
    refasten;
    policies;
  }
  size : 2;
}

table moorings {
  actions {
    policies;
    }
  }

table circuitously {
  reads {
    friendships : valid;
    friendships.science mask 0 : ternary;
    friendships.supervene : lpm;
    friendships.almoners : exact;
  }
  action_profile : chestful;
}

table reinvest {
  actions {
    refasten;
    }
  }

table damnation {
  action_profile : siestas;
  }

table satoris {
  reads {
    unique : valid;
    unique.briefness : exact;
    unique.wreckages mask 6 : exact;
    friendships.science : exact;
    friendships.supervene : ternary;
  }
  actions {
    policies;
  }
}

table busboys {
  reads {
    friendships.science : ternary;
    friendships.supervene : exact;
    friendships.almoners : exact;
  }
  actions {
    policies;
  }
}

table tolyattis {
  reads {
    unique : valid;
    unique.briefness : exact;
    unique.eruditely : exact;
    unique.wreckages mask 7 : exact;
    friendships.science : exact;
    friendships.supervene : exact;
    friendships.almoners : exact;
  }
  actions {
    policies;
    refasten;
  }
}

table died {
  reads {
    unique.wreckages mask 3 : lpm;
    friendships : valid;
  }
  actions {
    policies;
    refasten;
  }
}

table paleontologist {
  actions {
    policies;
    }
  }

table theistic {
  actions {
    
    }
  }

table uruguays {
  reads {
    unique : valid;
    unique.briefness mask 4 : lpm;
    unique.eruditely : exact;
    unique.wreckages : exact;
  }
  actions {
    
  }
}

table smuttinesss {
  reads {
    unique : valid;
    unique.wreckages : lpm;
    friendships : valid;
    friendships.science : exact;
    friendships.almoners : exact;
  }
  actions {
    policies;
  }
}

table darvon {
  actions {
    
    }
  }

table ogles {
  actions {
    
    }
  }

table fajitass {
  reads {
    unique : valid;
    unique.briefness mask 3 : ternary;
    friendships.science : exact;
    friendships.supervene : exact;
    friendships.almoners : exact;
  }
  actions {
    policies;
    refasten;
  }
}

table ventolins {
  reads {
    unique : valid;
    unique.briefness : exact;
    unique.eruditely : ternary;
    unique.wreckages : ternary;
    friendships.science : exact;
    friendships.supervene : exact;
    friendships.almoners : exact;
  }
  actions {
    policies;
    refasten;
  }
}

table milfords {
  reads {
    unique.eruditely : exact;
    unique.wreckages : exact;
    friendships.science : exact;
    friendships.supervene : exact;
  }
  actions {
    policies;
  }
}

table trudys {
  actions {
    policies;
    }
  }

table workers {
  actions {
    policies;
    }
  }

table stalls {
  actions {
    policies;
    refasten;
    }
  }

table salt {
  reads {
    unique.briefness : ternary;
    unique.eruditely : ternary;
    friendships : valid;
    friendships.supervene mask 31 : exact;
  }
  actions {
    policies;
    refasten;
  }
}

table trivia {
  actions {
    
    }
  }

table nonalignments {
  actions {
    
    }
  }

table sleeping {
  reads {
    friendships : valid;
    friendships.science : exact;
    friendships.supervene : exact;
    friendships.almoners mask 5 : exact;
  }
  actions {
    
  }
}

table renegotiations {
  actions {
    
    }
  }

table underthingss {
  actions {
    policies;
    refasten;
    }
  }

table blockaders {
  reads {
    unique : valid;
    unique.briefness : range;
    unique.eruditely : exact;
    friendships.science : exact;
  }
  actions {
    policies;
    refasten;
  }
}

table reestablishing {
  reads {
    unique : valid;
    unique.wreckages mask 6 : ternary;
  }
  actions {
    
  }
}

table playoffs {
  actions {
    policies;
    }
  }

control ingress {
  if (not(true)) {
    if (not((177 < unique.wreckages))) {
      apply(circuitously);
      apply(reinvest);
    } else {
      apply(damnation);
    }
    apply(satoris);
  }
  apply(busboys);
  if ((1867 == friendships.almoners)) {
    if (not(not((friendships.science == 54922)))) {
      apply(tolyattis);
    } else {
      if (((16 >= unique.eruditely) and (255 <= friendships.almoners))) {
        if ((not((friendships.almoners != unique.wreckages)) and
            not((unique.wreckages > 52)))) {
          apply(died);
          apply(paleontologist);
        } else {
          apply(theistic);
          apply(uruguays);
          apply(smuttinesss);
        }
        apply(darvon);
      }
    }
  } else {
    apply(ogles);
  }
  apply(fajitass);
  if (valid(friendships)) {
    apply(ventolins);
  } else {
    apply(milfords);
    if (((true or (friendships.almoners != friendships.almoners)) and
        ((friendships.supervene != 503464789) and (unique.wreckages != 
        0)))) {
      
    }
  }
  if ((not((4000 == friendships.supervene)) or
      not((1707 != friendships.supervene)))) {
    apply(trudys);
    apply(workers);
  } else {
    if ((((friendships.supervene == friendships.supervene) and
        valid(unique)) or not(false))) {
      if ((not(valid(friendships)) or (false or
          (friendships.supervene != 2007885509)))) {
        
      } else {
        apply(stalls);
        if (((1987 == friendships.almoners) or (3336 != friendships.supervene))) {
          if (true) {
            apply(salt);
            apply(trivia);
            apply(nonalignments);
          }
        } else {
          apply(sleeping);
        }
        apply(renegotiations);
      }
    } else {
      if (not((180 > unique.wreckages))) {
        apply(underthingss);
      } else {
        apply(blockaders);
        apply(reestablishing);
      }
    }
    apply(playoffs);
  }
}
