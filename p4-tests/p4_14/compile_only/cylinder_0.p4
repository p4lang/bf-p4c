/* p4smith seed: 263101805 */
#include <tofino/intrinsic_metadata.p4>
header_type rattlebrain {
  fields {
    panchromatic : 5;
    routes : 3 (signed);
    scalars : 8;
    thinned : 48 (saturating);
    adj : 32;
  }
}

header_type epoxys {
  fields {
    timon : 8;
    departures : 16;
    breakwaters : 47;
    furtherances : 9;
  }
}

header_type transfusions {
  fields {
    histrionicss : 4;
    sags : 2;
    shrews : 9;
    ucla : 3;
    unctions : 4;
    midyears : 2;
    berlitzs : 48 (signed);
  }
}

header_type tenser {
  fields {
    photosynthesized : 16;
    also : 48;
    pressies : 16;
    hyphened : 48;
  }
}

header_type swears {
  fields {
    jimmy : 7;
    southpaws : 8;
    salaciously : 12;
    byob : 48;
    overpass : 11;
    colloidal : 2;
  }
}

header_type produces {
  fields {
    sinusitiss : 7;
    foodstuffs : 3;
    reseeded : 11;
    saxophones : 10 (saturating);
    titillation : 6 (saturating);
    winchester : 11;
  }
}

header_type overclouded {
  fields {
    inlet : 16 (saturating);
  }
}

header rattlebrain propellants;

header epoxys bozo;

header transfusions loped;

header tenser ringlings;

header swears spammed;

header produces harlots;

header overclouded blavatsky;

parser start {
  return parse_propellants;
}

parser parse_propellants {
  extract(propellants);
  return select (current(0, 8)) {
    38 : parse_bozo;
    56 : parse_harlots;
  }
}

parser parse_bozo {
  extract(bozo);
  return select (current(0, 8)) {
    47 : parse_spammed;
    58 : parse_ringlings;
    37 : parse_loped;
  }
}

parser parse_loped {
  extract(loped);
  return select (current(0, 8)) {
    55 : parse_spammed;
    127 : parse_ringlings;
  }
}

parser parse_ringlings {
  extract(ringlings);
  return select (current(0, 8)) {
    127 : parse_harlots;
    26 : parse_spammed;
  }
}

parser parse_spammed {
  extract(spammed);
  return select (latest.southpaws) {
    22 : parse_blavatsky;
    40 : parse_harlots;
  }
}

parser parse_harlots {
  extract(harlots);
  return select (latest.winchester) {
    568 : parse_blavatsky;
  }
}

parser parse_blavatsky {
  extract(blavatsky);
  return ingress;
}

field_list reexplains {
  propellants.thinned;
  ringlings.pressies;
  bozo;
  propellants.scalars;
  ringlings.photosynthesized;
  ringlings.hyphened;
  propellants.adj;
  blavatsky.inlet;
}

field_list_calculation spongers {
  input {
    reexplains;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation blvd {
  input {
    reexplains;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation cordon {
  input {
    reexplains;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation telnet {
  input {
    reexplains;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field bozo.departures {
  verify telnet;
  verify spongers;
  update cordon;
  verify spongers;
}

calculated_field ringlings.photosynthesized {
  update cordon;
  update cordon;
  verify telnet;
  verify spongers;
}

calculated_field ringlings.pressies {
  verify telnet;
  verify spongers;
}

calculated_field blavatsky.inlet {
  update telnet;
  update telnet;
}

action organelles() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action miscellanies(suffered) {
  add(propellants.adj, 4113014329884664524, 2740133348312062573);
  add_header(loped);
  modify_field(bozo.breakwaters, bozo.breakwaters);
  modify_field(harlots.saxophones, harlots.saxophones);
  copy_header(loped, loped);
  add_to_field(propellants.scalars, propellants.scalars);
}

action academy(riverfront) {
  remove_header(harlots);
  bit_xor(propellants.adj, propellants.adj, propellants.adj);
  subtract_from_field(ringlings.pressies, ringlings.photosynthesized);
}

action venal() {
  modify_field(spammed.byob, ringlings.also);
  subtract_from_field(propellants.scalars, propellants.scalars);
  modify_field_rng_uniform(propellants.adj, 0, 65535);
  bit_and(ringlings.photosynthesized, ringlings.pressies, ringlings.photosynthesized);
  subtract_from_field(ringlings.pressies, ringlings.pressies);
}

action lawbreakers(helplessly, bookable) {
  subtract(propellants.scalars, 3454224282795015558, propellants.scalars);
  subtract_from_field(propellants.adj, 875665834271260276);
  subtract_from_field(blavatsky.inlet, blavatsky.inlet);
}

action_profile crocodiles {
  actions {
    lawbreakers;
    venal;
    miscellanies;
    organelles;
  }
  size : 32;
}

table dobermans {
  actions {
    organelles;
    }
  }

table feint {
  reads {
    bozo : valid;
    loped : valid;
    loped.shrews mask 4 : exact;
    loped.ucla : exact;
    loped.unctions : ternary;
    loped.midyears mask 0 : exact;
    loped.berlitzs : exact;
    spammed : valid;
    spammed.jimmy : ternary;
    spammed.southpaws : exact;
    spammed.salaciously : exact;
    spammed.byob : exact;
    harlots : valid;
  }
  action_profile : crocodiles;
}

table helipads {
  reads {
    propellants : valid;
    propellants.panchromatic : exact;
    propellants.scalars : exact;
    propellants.thinned : exact;
    propellants.adj : exact;
    bozo : valid;
    bozo.departures : exact;
    bozo.breakwaters mask 45 : exact;
    bozo.furtherances : exact;
    loped.berlitzs mask 20 : exact;
    ringlings.hyphened : exact;
    spammed.jimmy : ternary;
  }
  actions {
    venal;
  }
}

table conceptualizing {
  reads {
    harlots : valid;
    blavatsky : valid;
    blavatsky.inlet : exact;
  }
  actions {
    academy;
    miscellanies;
  }
}

table hollowness {
  actions {
    
    }
  }

table kazoos {
  reads {
    propellants.panchromatic : exact;
    bozo : valid;
    bozo.breakwaters : exact;
    spammed : valid;
    spammed.jimmy : exact;
    spammed.southpaws : ternary;
    spammed.salaciously mask 5 : exact;
    spammed.byob : ternary;
    spammed.overpass : ternary;
  }
  actions {
    lawbreakers;
  }
}

table chundering {
  actions {
    miscellanies;
    organelles;
    venal;
    }
  }

table nudists {
  reads {
    propellants : valid;
    propellants.panchromatic : exact;
    propellants.routes : exact;
    propellants.scalars : range;
    propellants.thinned : exact;
    propellants.adj : exact;
    blavatsky : valid;
    blavatsky.inlet : exact;
  }
  actions {
    
  }
}

table rca {
  actions {
    academy;
    lawbreakers;
    venal;
    }
  }

table diptychs {
  reads {
    propellants : valid;
    propellants.scalars : ternary;
    propellants.thinned : ternary;
    propellants.adj : exact;
    loped.histrionicss mask 0 : ternary;
    loped.sags : ternary;
    loped.shrews mask 8 : exact;
    loped.midyears : exact;
  }
  actions {
    venal;
  }
}

table testosterones {
  actions {
    academy;
    miscellanies;
    }
  }

table lured {
  reads {
    propellants : valid;
    propellants.scalars : exact;
    propellants.thinned : exact;
    propellants.adj : exact;
    loped.sags mask 0 : ternary;
    loped.shrews mask 8 : ternary;
    loped.ucla : exact;
    loped.unctions mask 1 : exact;
    loped.midyears mask 0 : ternary;
    spammed : valid;
    spammed.jimmy : ternary;
    spammed.southpaws : exact;
    spammed.byob : ternary;
    spammed.overpass : exact;
    spammed.colloidal : exact;
    harlots.sinusitiss : ternary;
    harlots.foodstuffs : exact;
    harlots.saxophones : exact;
  }
  actions {
    miscellanies;
  }
}

table rumour {
  reads {
    propellants : valid;
    propellants.panchromatic : exact;
    propellants.adj : ternary;
    spammed : valid;
    spammed.jimmy mask 1 : exact;
    spammed.southpaws : exact;
    spammed.salaciously : exact;
    spammed.byob : ternary;
    spammed.colloidal mask 0 : exact;
  }
  actions {
    miscellanies;
    organelles;
    venal;
  }
}

table carport {
  actions {
    
    }
  }

table desisted {
  reads {
    propellants.adj mask 0 : exact;
    loped : valid;
  }
  actions {
    academy;
    lawbreakers;
    miscellanies;
  }
}

table hofstadters {
  reads {
    bozo.timon mask 1 : exact;
    bozo.departures : exact;
    bozo.breakwaters : exact;
    bozo.furtherances : exact;
    loped : valid;
    loped.sags mask 0 : exact;
    loped.ucla : exact;
    ringlings : valid;
    harlots.sinusitiss : exact;
    harlots.reseeded mask 10 : exact;
    harlots.saxophones : ternary;
    harlots.titillation : exact;
  }
  actions {
    organelles;
    venal;
  }
}

table godlessly {
  reads {
    propellants : valid;
    bozo : valid;
    harlots.foodstuffs : exact;
    harlots.titillation : exact;
    blavatsky.inlet : exact;
  }
  actions {
    venal;
  }
}

table aborigines {
  reads {
    bozo : valid;
    loped.histrionicss mask 3 : ternary;
    loped.berlitzs : ternary;
    ringlings.photosynthesized : exact;
    ringlings.hyphened : exact;
    spammed.southpaws : exact;
    spammed.salaciously mask 1 : exact;
  }
  actions {
    
  }
}

table impoverished {
  reads {
    loped : valid;
    loped.berlitzs : ternary;
    ringlings : valid;
    ringlings.pressies : exact;
  }
  actions {
    
  }
}

table postmeridian {
  reads {
    bozo.timon : ternary;
    bozo.departures : range;
    bozo.breakwaters mask 47 : exact;
    bozo.furtherances : ternary;
    blavatsky.inlet mask 2 : exact;
  }
  actions {
    
  }
}

table emanuels {
  reads {
    propellants.routes mask 0 : exact;
    bozo : valid;
    bozo.timon : exact;
    bozo.departures mask 14 : range;
    bozo.furtherances : exact;
    loped.ucla : exact;
    loped.berlitzs : ternary;
    ringlings : valid;
    spammed : valid;
    spammed.jimmy mask 4 : exact;
    spammed.southpaws : ternary;
    spammed.salaciously : exact;
    spammed.byob : exact;
    spammed.overpass : exact;
  }
  actions {
    organelles;
    venal;
  }
}

table discontentment {
  reads {
    harlots : valid;
    harlots.foodstuffs : exact;
    harlots.saxophones mask 4 : ternary;
    harlots.titillation mask 0 : exact;
    harlots.winchester : exact;
    blavatsky.inlet mask 5 : exact;
  }
  actions {
    miscellanies;
    venal;
  }
}

table shortcrust {
  reads {
    blavatsky : valid;
    blavatsky.inlet : exact;
  }
  actions {
    academy;
    lawbreakers;
  }
}

table marks {
  actions {
    academy;
    }
  }

table dachas {
  actions {
    lawbreakers;
    organelles;
    }
  }

table pryor {
  reads {
    loped : valid;
    spammed.salaciously : exact;
    harlots.winchester mask 0 : exact;
    blavatsky.inlet : ternary;
  }
  actions {
    academy;
    lawbreakers;
  }
}

table subbranches {
  reads {
    bozo : valid;
    bozo.furtherances : exact;
    loped.histrionicss : ternary;
    loped.sags : exact;
    loped.unctions : ternary;
    loped.midyears mask 1 : ternary;
    loped.berlitzs : exact;
    ringlings.photosynthesized : exact;
    ringlings.also : exact;
    ringlings.pressies mask 9 : range;
    ringlings.hyphened : exact;
  }
  actions {
    organelles;
  }
}

table spenser {
  reads {
    loped : valid;
    loped.histrionicss : exact;
    loped.unctions : ternary;
    loped.midyears : exact;
    loped.berlitzs : exact;
    ringlings : valid;
    ringlings.photosynthesized mask 13 : ternary;
    ringlings.also : exact;
    ringlings.pressies mask 1 : exact;
    ringlings.hyphened : ternary;
    spammed : valid;
    harlots : valid;
    harlots.sinusitiss mask 2 : exact;
    harlots.foodstuffs : exact;
    harlots.reseeded : exact;
    harlots.saxophones : exact;
    harlots.titillation : exact;
  }
  actions {
    
  }
}

table electras {
  reads {
    bozo : valid;
    bozo.timon : exact;
    bozo.departures : range;
    bozo.breakwaters : ternary;
    bozo.furtherances : exact;
  }
  actions {
    academy;
    miscellanies;
  }
}

table fhas {
  reads {
    ringlings.hyphened mask 8 : ternary;
    spammed.salaciously mask 0 : exact;
    spammed.overpass : ternary;
    harlots : valid;
    harlots.sinusitiss : exact;
    harlots.foodstuffs : exact;
    harlots.reseeded mask 4 : exact;
    harlots.titillation : exact;
    harlots.winchester : exact;
  }
  actions {
    
  }
}

table cohesively {
  actions {
    
    }
  }

table preempts {
  reads {
    propellants.panchromatic : ternary;
    propellants.routes : ternary;
    propellants.scalars mask 7 : ternary;
    propellants.thinned : exact;
    propellants.adj : exact;
    bozo : valid;
    bozo.furtherances mask 2 : exact;
    loped : valid;
    loped.histrionicss : ternary;
    loped.shrews : ternary;
    spammed : valid;
    spammed.byob : exact;
  }
  actions {
    lawbreakers;
  }
}

table splotched {
  reads {
    ringlings.photosynthesized : exact;
    ringlings.also mask 27 : exact;
    ringlings.pressies : ternary;
    ringlings.hyphened : ternary;
    spammed : valid;
    spammed.jimmy : ternary;
    spammed.southpaws : range;
    spammed.salaciously : range;
    spammed.byob : ternary;
    spammed.overpass : exact;
    harlots.sinusitiss mask 5 : exact;
    harlots.reseeded : exact;
    harlots.saxophones mask 4 : range;
    harlots.titillation mask 5 : exact;
    harlots.winchester : exact;
  }
  actions {
    miscellanies;
  }
}

table futurists {
  reads {
    harlots : valid;
    harlots.foodstuffs : exact;
    harlots.saxophones : exact;
    harlots.winchester : range;
    blavatsky : valid;
  }
  actions {
    miscellanies;
  }
}

table blends {
  actions {
    academy;
    venal;
    }
  }

table herculean {
  reads {
    propellants : valid;
    propellants.routes mask 1 : exact;
    loped.sags : ternary;
    loped.shrews : exact;
    loped.midyears : exact;
    loped.berlitzs : ternary;
    harlots.foodstuffs : ternary;
    harlots.saxophones : range;
    harlots.titillation : exact;
    harlots.winchester : ternary;
    blavatsky : valid;
  }
  actions {
    lawbreakers;
  }
}

table meniscuss {
  reads {
    propellants : valid;
    loped : valid;
    loped.unctions mask 3 : ternary;
    loped.berlitzs : exact;
    ringlings : valid;
    ringlings.photosynthesized : range;
    ringlings.also : exact;
    ringlings.pressies : ternary;
    ringlings.hyphened : exact;
    spammed.colloidal : exact;
    harlots : valid;
  }
  actions {
    academy;
    organelles;
  }
}

table absentee {
  actions {
    lawbreakers;
    organelles;
    }
  }

table whelms {
  reads {
    propellants : valid;
    propellants.panchromatic : exact;
    propellants.routes : exact;
    propellants.scalars mask 3 : exact;
    propellants.thinned : ternary;
    propellants.adj : exact;
    ringlings.also : exact;
    ringlings.pressies : exact;
  }
  actions {
    
  }
}

table cotswold {
  reads {
    blavatsky : valid;
    blavatsky.inlet : exact;
  }
  actions {
    academy;
    venal;
  }
}

table holy {
  reads {
    propellants : valid;
    loped.sags : exact;
    loped.midyears mask 0 : exact;
  }
  actions {
    organelles;
  }
}

table crufted {
  reads {
    propellants.routes : exact;
    propellants.adj : ternary;
    loped : valid;
    loped.histrionicss : exact;
    loped.sags : exact;
    loped.shrews : exact;
    loped.ucla : ternary;
    loped.unctions : ternary;
    ringlings : valid;
    ringlings.photosynthesized : ternary;
    ringlings.also : exact;
    ringlings.pressies : exact;
    ringlings.hyphened : ternary;
    spammed.jimmy : ternary;
    spammed.salaciously : exact;
    spammed.overpass : exact;
    spammed.colloidal mask 0 : exact;
  }
  actions {
    academy;
  }
}

control ingress {
  if ((valid(harlots) and true)) {
    if (false) {
      if (not(false)) {
        apply(feint);
        apply(helipads);
      }
    } else {
      apply(conceptualizing);
      apply(hollowness);
    }
    if (not(valid(spammed))) {
      if (not(not(false))) {
        if ((not(valid(harlots)) and (valid(bozo) or false))) {
          
        } else {
          apply(kazoos);
          apply(chundering);
          apply(nudists);
        }
      } else {
        apply(rca) {
          hit {
            apply(diptychs);
            apply(testosterones);
            apply(lured);
          }
        }
        apply(rumour);
      }
      apply(carport);
    } else {
      apply(desisted);
      apply(hofstadters);
    }
    apply(godlessly);
  } else {
    if ((((loped.ucla >= 255) or true) or (valid(blavatsky) and
        (blavatsky.inlet == ringlings.photosynthesized)))) {
      apply(aborigines);
      apply(impoverished);
    } else {
      apply(postmeridian);
      if ((true or (propellants.thinned != loped.berlitzs))) {
        
      } else {
        apply(emanuels);
        apply(discontentment);
      }
      apply(shortcrust);
    }
    if (not(not((ringlings.hyphened != loped.berlitzs)))) {
      
    } else {
      apply(marks);
      apply(dachas);
      if ((not(false) and ((3429 != 2632) or false))) {
        apply(pryor);
      } else {
        apply(subbranches);
      }
    }
    if ((((ringlings.photosynthesized == ringlings.pressies) and
        (157 > loped.sags)) and (valid(blavatsky) or true))) {
      if ((false and valid(spammed))) {
        if (((true or valid(bozo)) and (valid(bozo) or
            (spammed.southpaws <= 255)))) {
          apply(spenser);
        } else {
          apply(electras);
          apply(fhas);
          apply(cohesively);
        }
        if ((not(valid(ringlings)) and (true or (propellants.scalars != 106)))) {
          
        } else {
          apply(preempts);
        }
        apply(splotched);
      }
    }
  }
  if (((valid(ringlings) and (harlots.sinusitiss > 105)) or
      ((propellants.thinned != propellants.thinned) and
      (ringlings.photosynthesized != blavatsky.inlet)))) {
    if ((((141 <= propellants.routes) or (187 <= bozo.timon)) or
        ((ringlings.also != loped.berlitzs) and true))) {
      apply(futurists);
      apply(blends);
    } else {
      apply(herculean);
    }
    apply(meniscuss);
    apply(absentee);
  } else {
    apply(whelms);
    apply(cotswold);
    apply(holy);
  }
  apply(crufted);
}
