/* p4smith seed: 304815757 */
#include <tofino/intrinsic_metadata.p4>
header_type cohabited {
  fields {
    archiepiscopal : 1;
    romanced : 7 (signed, saturating);
  }
}

header_type entryphones {
  fields {
    adjourning : 16;
  }
}

header cohabited mishaps;

header entryphones ostracizes;

register encrypting {
  width : 64;
  instance_count : 624;
}

register deescalates {
  width : 16;
  instance_count : 84;
}

register sours {
  width : 1;
  instance_count : 1;
}

register blowups {
  width : 8;
  instance_count : 363;
}

register scrapped {
  width : 16;
  instance_count : 1;
}

register noncorrosive {
  width : 16;
  instance_count : 84;
}

parser start {
  return parse_mishaps;
}

parser parse_mishaps {
  extract(mishaps);
  return select (latest.romanced) {
    30 : parse_ostracizes;
  }
}

parser parse_ostracizes {
  extract(ostracizes);
  return ingress;
}

field_list connectives {
  mishaps;
  ostracizes.adjourning;
}

field_list rollbacks {
  ostracizes.adjourning;
}

field_list_calculation awnings {
  input {
    rollbacks;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field ostracizes.adjourning {
  verify awnings;
}

action somalia() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action halley(animosities, pixels, unjustifiably) {
  bit_and(ostracizes.adjourning, 3480654039776367458, ostracizes.adjourning);
  remove_header(mishaps);
}

action_profile leisureliness {
  actions {
    halley;
    somalia;
  }
  size : 2;
}

action_profile limbaugh {
  actions {
    somalia;
  }
  size : 2;
}

action_profile rx {
  actions {
    halley;
  }
  size : 26;
}

table conquer {
  actions {
    somalia;
    }
  }

table kellie {
  reads {
    mishaps : valid;
    ostracizes : valid;
    ostracizes.adjourning : ternary;
  }
  action_profile : rx;
}

table knothole {
  action_profile : leisureliness;
  }

table spermicides {
  reads {
    mishaps : valid;
    mishaps.romanced : exact;
  }
  action_profile : limbaugh;
}

table dysprosiums {
  reads {
    ostracizes : valid;
    ostracizes.adjourning mask 14 : range;
  }
  actions {
    halley;
  }
}

table capture {
  reads {
    mishaps.archiepiscopal mask 0 : exact;
    mishaps.romanced mask 6 : ternary;
  }
  actions {
    halley;
  }
}

table carbonates {
  actions {
    halley;
    somalia;
    }
  }

table calibrate {
  reads {
    ostracizes : valid;
    ostracizes.adjourning : exact;
  }
  actions {
    
  }
}

table tar {
  reads {
    mishaps : valid;
    mishaps.romanced : exact;
  }
  actions {
    halley;
    somalia;
  }
}

table oversteps {
  reads {
    mishaps.archiepiscopal : exact;
    mishaps.romanced : exact;
  }
  actions {
    halley;
    somalia;
  }
}

table assents {
  actions {
    
    }
  }

table nebulae {
  actions {
    
    }
  }

table nerdy {
  reads {
    mishaps.archiepiscopal mask 0 : ternary;
    mishaps.romanced : exact;
    ostracizes : valid;
  }
  actions {
    halley;
  }
}

table drizzly {
  reads {
    mishaps : valid;
  }
  actions {
    halley;
  }
}

table supers {
  reads {
    mishaps.romanced : exact;
  }
  actions {
    halley;
    somalia;
  }
}

table nonappearances {
  reads {
    mishaps.romanced : exact;
  }
  actions {
    halley;
    somalia;
  }
}

table townhouse {
  actions {
    halley;
    somalia;
    }
  }

table soul {
  reads {
    mishaps.archiepiscopal : exact;
    mishaps.romanced : exact;
    ostracizes.adjourning : exact;
  }
  actions {
    halley;
  }
}

table nurturers {
  reads {
    mishaps : valid;
    mishaps.archiepiscopal : ternary;
  }
  actions {
    halley;
    somalia;
  }
}

table knowledges {
  reads {
    mishaps : valid;
  }
  actions {
    halley;
    somalia;
  }
}

table emulsified {
  reads {
    ostracizes.adjourning : exact;
  }
  actions {
    somalia;
  }
}

table misfortunes {
  actions {
    halley;
    somalia;
    }
  }

table fudge {
  reads {
    mishaps : valid;
    mishaps.archiepiscopal : exact;
    mishaps.romanced : exact;
  }
  actions {
    
  }
}

table tailpipes {
  actions {
    halley;
    somalia;
    }
  }

table curse {
  actions {
    halley;
    }
  }

table joiner {
  reads {
    mishaps.archiepiscopal : ternary;
    mishaps.romanced : exact;
    ostracizes.adjourning : exact;
  }
  actions {
    halley;
    somalia;
  }
}

table walpole {
  actions {
    
    }
  }

table embodied {
  reads {
    mishaps : valid;
    mishaps.archiepiscopal : exact;
    mishaps.romanced : lpm;
  }
  actions {
    halley;
    somalia;
  }
}

table durability {
  reads {
    mishaps : valid;
    ostracizes : valid;
    ostracizes.adjourning mask 10 : range;
  }
  actions {
    halley;
    somalia;
  }
}

table simmers {
  reads {
    mishaps : valid;
    mishaps.archiepiscopal : exact;
    mishaps.romanced : lpm;
  }
  actions {
    halley;
    somalia;
  }
}

table skimping {
  reads {
    ostracizes.adjourning : exact;
  }
  actions {
    
  }
}

table puked {
  reads {
    mishaps : valid;
    mishaps.romanced : exact;
    ostracizes : valid;
  }
  actions {
    
  }
}

table retrofires {
  actions {
    halley;
    }
  }

table outworks {
  reads {
    mishaps.romanced : exact;
    ostracizes : valid;
    ostracizes.adjourning : ternary;
  }
  actions {
    somalia;
  }
}

control ingress {
  if ((174 < 1060)) {
    
  } else {
    if (not((true or false))) {
      apply(kellie);
      if (((false and valid(mishaps)) and (false or (200 >= mishaps.romanced)))) {
        apply(knothole);
      } else {
        apply(spermicides);
        apply(dysprosiums);
        apply(capture);
      }
      apply(carbonates);
    } else {
      apply(calibrate);
      if (true) {
        apply(tar);
        if (not((false and (mishaps.archiepiscopal <= 123)))) {
          apply(oversteps);
          apply(assents);
          apply(nebulae);
        } else {
          apply(nerdy);
          apply(drizzly);
        }
      }
      apply(supers);
    }
    apply(nonappearances);
  }
  apply(townhouse);
  if ((not(valid(mishaps)) or (true and false))) {
    if (not((ostracizes.adjourning == 59342))) {
      apply(soul);
      apply(nurturers);
    } else {
      apply(knowledges);
      apply(emulsified);
      apply(misfortunes);
    }
    apply(fudge);
    apply(tailpipes);
  } else {
    if (not((valid(mishaps) or true))) {
      
    } else {
      if ((mishaps.archiepiscopal <= 243)) {
        apply(curse);
      } else {
        if (not((false or true))) {
          apply(joiner);
          apply(walpole);
          apply(embodied);
        } else {
          apply(durability);
        }
      }
      apply(simmers);
      apply(skimping);
    }
    apply(puked);
    apply(retrofires);
  }
  if ((3423 == ostracizes.adjourning)) {
    
  }
  apply(outworks);
}

