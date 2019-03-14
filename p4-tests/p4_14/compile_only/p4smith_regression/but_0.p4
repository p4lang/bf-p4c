/* p4smith seed: 314345245 */
#include <tofino/intrinsic_metadata.p4>
header_type marches {
  fields {
    triremes : 4;
    dosshouse : 32 (signed, saturating);
    rockier : 2;
    glisten : 2;
    ardent : 11 (signed);
    yeagers : 4 (signed, saturating);
    atwoods : 9;
  }
}

header_type raspiest {
  fields {
    lieus : 4;
    vision : 32 (signed, saturating);
    mystiques : 48;
    waldos : 7;
    stirs : 4;
    metalworking : 9 (signed);
  }
}

header_type nonflowering {
  fields {
    travelogues : 16;
  }
}

header_type midweek {
  fields {
    subscriptions : 6;
    stunningly : 6;
    disposal : 16;
    rondos : 48;
    refund : 32 (signed);
    vaunts : 8 (signed);
    caulker : 4;
  }
}

header_type housemates {
  fields {
    reasons : 1;
    booting : 16 (saturating);
    doilys : 7 (signed);
  }
}

header_type mammary {
  fields {
    hintons : 6;
    expire : 48;
    persecutions : 48;
    academys : 8;
    municipalities : 2 (signed, saturating);
  }
}

header_type elates {
  fields {
    blackheads : 5;
    perfumers : 9 (signed);
    atmospheres : 10;
  }
}

header_type navarros {
  fields {
    physicist : 2;
    kelvins : 4;
    placarding : 10;
  }
}

header marches megalith;

header raspiest pusans;

header nonflowering fireflys;

header midweek barberries;

header housemates migratory;

header mammary furzes;

header elates burst;

header navarros thuggerys;

register enmeshment {
  width : 16;
  instance_count : 605;
}

register maoists {
  width : 64;
  instance_count : 361;
}

parser start {
  return parse_megalith;
}

parser parse_megalith {
  extract(megalith);
  return select (latest.atwoods) {
    206 : parse_furzes;
    252 : parse_barberries;
    50 : parse_thuggerys;
    148 : parse_pusans;
  }
}

parser parse_pusans {
  extract(pusans);
  return select (current(0, 8)) {
    74 : parse_migratory;
    60 : parse_furzes;
    25 : parse_fireflys;
  }
}

parser parse_fireflys {
  extract(fireflys);
  return select (latest.travelogues) {
    2318 : parse_furzes;
    3184 : parse_barberries;
    28863 : parse_thuggerys;
  }
}

parser parse_barberries {
  extract(barberries);
  return select (current(0, 8)) {
    0 : parse_migratory;
  }
}

parser parse_migratory {
  extract(migratory);
  return select (latest.reasons) {
    0 : parse_burst;
    0 : parse_furzes;
    0 : parse_thuggerys;
  }
}

parser parse_furzes {
  extract(furzes);
  return select (current(0, 8)) {
    23 : parse_burst;
    87 : parse_thuggerys;
  }
}

parser parse_burst {
  extract(burst);
  return select (latest.atmospheres) {
    236 : parse_thuggerys;
  }
}

parser parse_thuggerys {
  extract(thuggerys);
  return ingress;
}

field_list yellowhammer {
  migratory.doilys;
  pusans.lieus;
  burst.blackheads;
  megalith.dosshouse;
  pusans.stirs;
  migratory.reasons;
  pusans.metalworking;
  barberries;
  furzes.municipalities;
}

field_list pianolas {
  fireflys.travelogues;
  pusans.stirs;
  thuggerys.kelvins;
  burst;
  furzes.hintons;
  megalith.rockier;
  furzes.persecutions;
  furzes.academys;
  pusans.lieus;
  barberries.caulker;
}

field_list_calculation quiches {
  input {
    yellowhammer;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field migratory.booting {
  verify quiches;
}

calculated_field fireflys.travelogues {
  update quiches;
}

action overflows() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action muddles(culturally, estimator, frankest) {
  bit_or(fireflys.travelogues, 4283166933787736039, 1776355077987394852);
  modify_field_rng_uniform(furzes.hintons, 0, 1);
  modify_field(pusans.stirs, pusans.lieus);
}

action_profile dogies {
  actions {
    muddles;
    overflows;
  }
  size : 24;
}

table parching {
  actions {
    overflows;
    }
  }

table busied {
  reads {
    fireflys : valid;
    barberries : valid;
    burst : valid;
    burst.blackheads : exact;
    burst.perfumers mask 1 : exact;
  }
  actions {
    
  }
}

table intimacy {
  action_profile : dogies;
  }

table tomato {
  actions {
    muddles;
    overflows;
    }
  }

table rca {
  reads {
    pusans : valid;
    pusans.lieus : exact;
    pusans.metalworking : exact;
    migratory : valid;
    migratory.booting : exact;
    migratory.doilys : exact;
    burst : valid;
    burst.perfumers : exact;
  }
  actions {
    muddles;
    overflows;
  }
}

table gehenna {
  reads {
    pusans : valid;
    pusans.lieus : exact;
    pusans.vision : ternary;
    pusans.mystiques : exact;
    pusans.waldos : ternary;
    pusans.stirs : exact;
  }
  actions {
    muddles;
  }
}

table rescheduled {
  reads {
    furzes : valid;
    furzes.expire : ternary;
    furzes.persecutions : exact;
    furzes.academys : exact;
    furzes.municipalities : lpm;
    burst.blackheads : ternary;
    burst.perfumers : ternary;
    thuggerys : valid;
    thuggerys.physicist : exact;
    thuggerys.kelvins : exact;
    thuggerys.placarding mask 8 : exact;
  }
  actions {
    muddles;
    overflows;
  }
}

table homesteads {
  reads {
    pusans : valid;
  }
  actions {
    overflows;
  }
}

table contemplates {
  actions {
    muddles;
    }
  }

table englishmen {
  reads {
    megalith.triremes : exact;
    megalith.dosshouse : lpm;
    megalith.rockier : range;
    megalith.glisten : exact;
    megalith.ardent : ternary;
    pusans.lieus mask 0 : exact;
    pusans.vision : exact;
    pusans.mystiques mask 47 : exact;
    barberries : valid;
    barberries.stunningly : ternary;
    barberries.disposal : exact;
    barberries.rondos : exact;
    barberries.refund : exact;
    barberries.caulker : exact;
    migratory.reasons : exact;
    migratory.booting : ternary;
    migratory.doilys : exact;
  }
  actions {
    overflows;
  }
}

table cheerless {
  reads {
    fireflys.travelogues : exact;
    burst : valid;
    burst.blackheads : exact;
    burst.perfumers : exact;
    burst.atmospheres : exact;
  }
  actions {
    overflows;
  }
}

table subspecies {
  reads {
    pusans.vision mask 4 : exact;
    pusans.waldos : exact;
    pusans.stirs : exact;
    fireflys : valid;
    furzes : valid;
  }
  actions {
    muddles;
    overflows;
  }
}

table mooting {
  reads {
    barberries.stunningly : lpm;
    barberries.refund : exact;
    barberries.vaunts : exact;
    barberries.caulker : exact;
  }
  actions {
    
  }
}

table smarts {
  reads {
    furzes.expire : exact;
    furzes.academys : exact;
    furzes.municipalities : lpm;
    burst.perfumers mask 6 : exact;
    burst.atmospheres : range;
    thuggerys : valid;
    thuggerys.physicist mask 1 : exact;
    thuggerys.placarding : ternary;
  }
  actions {
    overflows;
  }
}

table amazonian {
  actions {
    muddles;
    overflows;
    }
  }

table thirties {
  actions {
    
    }
  }

table biodiversitys {
  actions {
    
    }
  }

table militarists {
  reads {
    migratory.reasons : range;
    burst : valid;
    burst.atmospheres mask 9 : exact;
    thuggerys.physicist : exact;
    thuggerys.kelvins : lpm;
    thuggerys.placarding mask 1 : exact;
  }
  actions {
    muddles;
  }
}

table dogsleds {
  reads {
    barberries.subscriptions : lpm;
    barberries.disposal mask 6 : exact;
    barberries.vaunts : exact;
    barberries.caulker : exact;
    thuggerys : valid;
    thuggerys.physicist : exact;
    thuggerys.kelvins : ternary;
  }
  actions {
    muddles;
    overflows;
  }
}

table nickering {
  reads {
    pusans.lieus : lpm;
    pusans.stirs : exact;
    pusans.metalworking : exact;
    barberries.stunningly : ternary;
    barberries.rondos : ternary;
    barberries.refund mask 1 : exact;
    barberries.vaunts : ternary;
    barberries.caulker : exact;
  }
  actions {
    muddles;
    overflows;
  }
}

table nepalis {
  reads {
    megalith : valid;
    megalith.dosshouse : exact;
    megalith.rockier mask 1 : range;
    megalith.yeagers mask 3 : exact;
    megalith.atwoods : lpm;
    fireflys : valid;
    barberries.stunningly : exact;
    barberries.rondos : ternary;
    barberries.refund : exact;
    migratory : valid;
  }
  actions {
    muddles;
  }
}

table calmly {
  reads {
    fireflys : valid;
    barberries.disposal : ternary;
    furzes : valid;
    furzes.hintons : exact;
    furzes.expire : exact;
    furzes.academys : exact;
  }
  actions {
    
  }
}

table childbearing {
  reads {
    furzes : valid;
  }
  actions {
    muddles;
    overflows;
  }
}

table touristic {
  reads {
    megalith : valid;
    megalith.dosshouse mask 31 : exact;
    megalith.rockier : exact;
    migratory : valid;
    migratory.reasons : ternary;
    migratory.booting mask 10 : exact;
    migratory.doilys mask 3 : exact;
    furzes : valid;
    furzes.municipalities : exact;
    burst : valid;
    burst.blackheads : exact;
    burst.perfumers : lpm;
    burst.atmospheres : exact;
    thuggerys : valid;
    thuggerys.physicist : ternary;
  }
  actions {
    muddles;
    overflows;
  }
}

table extinctions {
  reads {
    burst : valid;
    burst.blackheads mask 4 : ternary;
    burst.perfumers mask 8 : range;
    burst.atmospheres : exact;
    thuggerys : valid;
  }
  actions {
    
  }
}

table esmeraldas {
  actions {
    
    }
  }

table meridian {
  reads {
    megalith : valid;
    megalith.atwoods : exact;
    migratory.reasons : ternary;
    migratory.booting : exact;
    migratory.doilys : exact;
    furzes.expire : exact;
    furzes.persecutions : exact;
    furzes.academys : exact;
    furzes.municipalities : exact;
    burst.atmospheres : exact;
  }
  actions {
    
  }
}

table allusive {
  reads {
    furzes.persecutions : exact;
    furzes.academys : lpm;
    furzes.municipalities mask 1 : exact;
  }
  actions {
    muddles;
    overflows;
  }
}

table clefts {
  reads {
    fireflys : valid;
    fireflys.travelogues mask 0 : lpm;
    barberries : valid;
    barberries.subscriptions : exact;
    barberries.disposal : exact;
    barberries.rondos : exact;
    barberries.vaunts mask 1 : exact;
    barberries.caulker : exact;
    furzes : valid;
  }
  actions {
    overflows;
  }
}

table stitchery {
  reads {
    fireflys : valid;
    barberries.subscriptions : lpm;
    barberries.disposal mask 0 : exact;
    barberries.rondos : ternary;
    barberries.refund mask 23 : exact;
    barberries.caulker mask 1 : range;
    thuggerys : valid;
    thuggerys.physicist mask 0 : range;
    thuggerys.kelvins : ternary;
    thuggerys.placarding : exact;
  }
  actions {
    muddles;
    overflows;
  }
}

table including {
  reads {
    pusans : valid;
    pusans.lieus mask 3 : exact;
    pusans.vision : exact;
    pusans.mystiques mask 35 : exact;
    pusans.waldos : lpm;
    pusans.stirs mask 2 : exact;
  }
  actions {
    overflows;
  }
}

table incorrectnesss {
  reads {
    barberries : valid;
    barberries.subscriptions : lpm;
    barberries.disposal : exact;
    barberries.refund : ternary;
    furzes.hintons : exact;
    furzes.expire mask 13 : exact;
    furzes.persecutions : exact;
    furzes.municipalities : ternary;
    thuggerys : valid;
    thuggerys.physicist : exact;
    thuggerys.kelvins : ternary;
  }
  actions {
    muddles;
    overflows;
  }
}

table baldness {
  actions {
    overflows;
    }
  }

table alpheccas {
  reads {
    thuggerys : valid;
    thuggerys.physicist : ternary;
    thuggerys.kelvins : exact;
    thuggerys.placarding : ternary;
  }
  actions {
    muddles;
  }
}

table elves {
  actions {
    
    }
  }

table joggers {
  actions {
    overflows;
    }
  }

table takeaways {
  actions {
    
    }
  }

table esmeralda {
  reads {
    thuggerys : valid;
    thuggerys.physicist mask 1 : exact;
    thuggerys.kelvins mask 3 : ternary;
    thuggerys.placarding : exact;
  }
  actions {
    muddles;
  }
}

table orgasms {
  reads {
    thuggerys.kelvins : lpm;
    thuggerys.placarding : ternary;
  }
  actions {
    
  }
}

table pragmatists {
  reads {
    megalith : valid;
    megalith.triremes : ternary;
    megalith.dosshouse mask 21 : exact;
    megalith.glisten : exact;
    megalith.ardent : ternary;
    migratory : valid;
    furzes.persecutions : exact;
    furzes.academys : exact;
    furzes.municipalities : exact;
    burst : valid;
    burst.blackheads : exact;
    burst.perfumers mask 3 : exact;
    burst.atmospheres : lpm;
  }
  actions {
    
  }
}

control ingress {
  if (((megalith.triremes <= 171) and false)) {
    if (not((pusans.lieus != pusans.lieus))) {
      
    } else {
      apply(busied);
      if (true) {
        if (valid(migratory)) {
          apply(intimacy);
        } else {
          apply(tomato);
        }
      } else {
        apply(rca);
      }
      apply(gehenna);
    }
  } else {
    apply(rescheduled);
    apply(homesteads);
    if (((false or (furzes.hintons != 19)) and ((pusans.metalworking < 
        228) or true))) {
      if ((false or (burst.atmospheres >= 63))) {
        apply(contemplates);
        apply(englishmen);
        apply(cheerless);
      } else {
        apply(subspecies) {
          miss {
            apply(mooting);
            apply(smarts);
            apply(amazonian);
          }
          hit {
            apply(thirties);
            apply(biodiversitys);
          }
        }
        apply(militarists);
        apply(dogsleds);
      }
      if ((false and true)) {
        apply(nickering);
        apply(nepalis);
        if (true) {
          
        } else {
          apply(calmly);
        }
      } else {
        apply(childbearing);
      }
    }
  }
  if ((not((megalith.glisten <= 136)) and ((243 <= furzes.hintons) or false))) {
    if (valid(megalith)) {
      
    } else {
      apply(touristic);
      apply(extinctions);
    }
    apply(esmeraldas);
    apply(meridian) {
      hit { }
      miss { }
    }
  } else {
    apply(allusive);
    apply(clefts);
    if (valid(migratory)) {
      apply(stitchery) {
        miss { }
      }
      apply(including);
      apply(incorrectnesss);
    } else {
      apply(baldness);
      apply(alpheccas);
      if (not(not((240 >= barberries.caulker)))) {
        apply(elves);
        apply(joggers);
        apply(takeaways);
      }
    }
  }
  apply(esmeralda);
  apply(orgasms);
  apply(pragmatists);
}
