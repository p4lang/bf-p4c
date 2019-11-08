/* p4smith seed: 388862141 */
#include <core.p4>
#include <v1model.p4>

header crucifixions {
     bit<5> squatnesss;
     bit<8> wigwags;
     bit<4> nonacceptance;
     bit<16> absorbing;
     bit<7> rumbas;
     bit<48> rejuvenate;
     bit<2> hellenisms;
     bit<7> adversarys;
     bit<2> dispiriting;
     bit<16> pagoda;
     bit<11> bairns;
     bit<8> widowers;
     bit<10> mariachi;
     bit<32> rid;
     bit<16> trujillo;
     bit<48> gleaning;
     bit<16> catted;
     bit<7> flaccidity;
     bit<16> noisemakers;
     bit<9> conceitedly;
 }
 header shrillness {
     bit<7> preppy;
     bit<9> hangovers;
     bit<11> goianias;
     bit<48> thereupon;
     bit<3> glen;
     bit<48> thirtieth;
     bit<1> uselessness;
     bit<11> bogeyed;
     bit<8> frivolity;
     bit<7> gide;
     bit<48> paganini;
     bit<12> tided;
     bit<16> clouts;
     bit<10> strongroom;
     bit<16> elvas;
     bit<3> fumed;
     bit<8> cartier;
     bit<8> imams;
     bit<16> priam;
     bit<2> vaudevillian;
     bit<4> janna;
 }
 header overemphasiss {
     bit<1> scruple;
     bit<1> nonsexual;
     bit<6> metalanguages;
     bit<4> wedding;
     bit<16> indicate;
     bit<4> implicitnesss;
     bit<9> punchline;
     bit<1> purlieu;
     bit<16> clatters;
     bit<10> touchable;
     bit<10> quieted;
     bit<11> teenagers;
     bit<2> kenny;
     bit<4> pruriently;
     bit<1> independences;
     bit<12> cycling;
     bit<32> mulches;
     bit<4> teammates;
 }
 struct headers {
     overemphasiss tsp;
     overemphasiss oleanders;
     overemphasiss watertight;
     overemphasiss centralizers;
     overemphasiss flicks;
     shrillness supplanting;
     shrillness argosies;
     shrillness esquires;
     shrillness larcenys;
     crucifixions depreciating;
 }
 struct metadata { }
 parser sage(packet_in pkt,out headers hdr,inout metadata meta,
             inout standard_metadata_t std_meta) {
     state start {
         transition parse_tsp;
     }
     state parse_tsp {
         pkt.extract(hdr.tsp);
         transition select(hdr.tsp.kenny,hdr.tsp.nonsexual,
             hdr.tsp.implicitnesss,hdr.tsp.teammates,hdr.tsp.scruple) {
             {2w0,1w0,4w2,4w3,1w0}: parse_oleanders;
         }
     }
     state parse_oleanders {
         pkt.extract(hdr.oleanders);
         transition select(hdr.oleanders.purlieu,hdr.oleanders.scruple,
             hdr.oleanders.scruple,hdr.oleanders.punchline) {
             {1w0,1w0,1w1,9w158}: parse_watertight;
         }
     }
     state parse_watertight {
         pkt.extract(hdr.watertight);
         transition select(hdr.watertight.cycling) {
             {12w3619}: parse_depreciating;
             {12w2746}: parse_centralizers;
         }
     }
     state parse_centralizers {
         pkt.extract(hdr.centralizers);
         transition select(hdr.centralizers.nonsexual,
             hdr.centralizers.touchable,hdr.centralizers.independences) {
             {1w0,10w794,1w1}: parse_flicks;
         }
     }
     state parse_flicks {
         pkt.extract(hdr.flicks);
         transition select(hdr.flicks.quieted,hdr.flicks.kenny) {
             {10w630,2w2}: parse_depreciating;
             {10w240,2w1}: parse_esquires;
             {10w251,2w2}: parse_supplanting;
         }
     }
     state parse_supplanting {
         pkt.extract(hdr.supplanting);
         transition select(hdr.supplanting.janna,hdr.supplanting.cartier) {
             {4w11,8w138}: parse_depreciating;
             {4w11,8w225}: parse_argosies;
             {4w2,8w107}: parse_esquires;
         }
     }
     state parse_argosies {
         pkt.extract(hdr.argosies);
         transition select(hdr.argosies.uselessness,hdr.argosies.bogeyed) {
             {1w0,11w0}: parse_esquires;
             {1w1,11w1540}: parse_larcenys;
         }
     }
     state parse_esquires {
         pkt.extract(hdr.esquires);
         transition select(hdr.esquires.uselessness,hdr.esquires.bogeyed) {
             {1w1,11w1938}: parse_larcenys;
         }
     }
     state parse_larcenys {
         pkt.extract(hdr.larcenys);
         transition select(hdr.larcenys.vaudevillian,hdr.larcenys.imams,
             hdr.larcenys.vaudevillian) {{2w2,8w6,2w2}: parse_depreciating;
         }
     }
     state parse_depreciating {
         pkt.extract(hdr.depreciating);
         transition accept;
     }
 }
 control airlifted(inout headers hdr,inout metadata meta) {
     apply {
         verify_checksum(true,
                         {hdr.argosies.vaudevillian,hdr.argosies.hangovers,
                             hdr.argosies.clouts,hdr.argosies.thirtieth,
                             hdr.argosies.thereupon,hdr.argosies.bogeyed,
                             hdr.argosies.preppy,hdr.argosies.cartier,
                             hdr.argosies.uselessness,hdr.argosies.gide,
                             hdr.argosies.glen,hdr.argosies.goianias,
                             hdr.argosies.priam,hdr.argosies.strongroom,
                             hdr.argosies.janna,hdr.argosies.fumed,
                             hdr.argosies.tided,hdr.argosies.elvas,
                             hdr.argosies.paganini,hdr.argosies.imams,
                             hdr.argosies.frivolity},
                         hdr.depreciating.trujillo,HashAlgorithm.csum16);
         verify_checksum(true,
                         {hdr.tsp.teammates,hdr.tsp.quieted,hdr.tsp.scruple,
                             hdr.tsp.cycling,hdr.tsp.pruriently,
                             hdr.tsp.mulches,hdr.tsp.metalanguages,
                             hdr.tsp.clatters,hdr.tsp.indicate,
                             hdr.tsp.nonsexual,hdr.tsp.implicitnesss,
                             hdr.tsp.teenagers,hdr.tsp.punchline,
                             hdr.tsp.wedding,hdr.tsp.purlieu,hdr.tsp.kenny,
                             hdr.tsp.touchable,hdr.tsp.independences},
                         hdr.depreciating.catted,HashAlgorithm.csum16);
         verify_checksum(true,
                         {hdr.flicks.wedding,hdr.flicks.teenagers,
                             hdr.flicks.mulches,hdr.flicks.clatters,
                             hdr.flicks.touchable,hdr.flicks.implicitnesss,
                             hdr.flicks.cycling,hdr.flicks.pruriently,
                             hdr.flicks.independences,hdr.flicks.kenny,
                             hdr.flicks.punchline,hdr.flicks.nonsexual,
                             hdr.flicks.purlieu,hdr.flicks.scruple,
                             hdr.flicks.indicate,hdr.flicks.quieted,
                             hdr.flicks.metalanguages,hdr.flicks.teammates},
                         hdr.depreciating.catted,HashAlgorithm.csum16);
     }
 }
 control lanyard(inout headers hdr,inout metadata meta,
                 inout standard_metadata_t std_meta) {
     action dmd(in bool crackings,in bit<32> patsys) {
         hdr.depreciating.rid = (32w1391884966 | 32w1305139627);
     }
     action tepidity() {
         hdr.depreciating.catted = (hdr.depreciating.trujillo |+| 16w60361);
     }
     action precious(in bool bahamass) {
         hdr.depreciating.rid = (~ 32w4092196435);
         hdr.depreciating.catted = (16w14015 | hdr.depreciating.trujillo);
     }
     action turks(in bool bluesiest,in bool sampson) {
         hdr.depreciating.rid = (- 32w2346578145);
     }
     table bewilder {
         key = {
             
         }
         actions = {
             
         }
     }
     table rhetorics {
         key = {
             
         }
         actions = {
             precious((bool) 1w0);
         }
     }apply {
          rhetorics.apply();
          bewilder.apply();
          hdr.depreciating.catted = (~ 16w53176);
          if ((!
                  (((! (hdr.depreciating.isValid() && true)) ||
                       (((bool) 1w1 && (bool) 1w1) && (false || (bool) 1w1)))
                      ||
                      (((! true) || (hdr.watertight.isValid() || true)) &&
                          ((hdr.argosies.isValid() && (bool) 1w0) ||
                              (! hdr.flicks.isValid()))))))
              
              hdr.depreciating.catted = (~ hdr.depreciating.trujillo);
          hdr.depreciating.rid = (32w2648070708 ^ 32w491574820);
          hdr.depreciating.trujillo = (- 16w2301);
     }
 }
 control idempotent(inout headers hdr,inout metadata meta,
                    inout standard_metadata_t std_meta) {
     action settles(in bit<16> disfavour) {
         hdr.depreciating.rid = (32w2719345848 + 32w1738523852);
     }
     action concubine() {
         hdr.depreciating.rid = (- 32w3108468700);
         hdr.depreciating.catted = (- hdr.depreciating.trujillo);
     }
     action seconder(in bool deena,in bool scenes) {
         hdr.depreciating.trujillo = (hdr.depreciating.catted & 16w26900);
         hdr.depreciating.rid = (~ 32w2645423346);
     }
     action castellated(in bit<32> fungous) {
         hdr.depreciating.catted = (- 16w40831);
     }
     action releases() {
         hdr.depreciating.rid = (~ 32w2482359491);
         hdr.depreciating.trujillo = (hdr.depreciating.catted |+| 16w31181);
     }
     action violet(in bit<4> schmaltz) {
         hdr.depreciating.rid = (- 32w3342796414);
         hdr.depreciating.trujillo = (- hdr.depreciating.catted);
     }
     action druids(in bool ebbed,in bit<7> gristmills) {
         hdr.depreciating.catted = (hdr.depreciating.trujillo &
                                       hdr.depreciating.trujillo);
     }
     action gatehouses(in bool mall) {
         hdr.depreciating.trujillo = (16w483 | 16w44886);
         hdr.depreciating.rid = (~ 32w3263042263);
     }
     table creamerys {
         key = {
             
         }
         actions = {
             castellated(32w3120017096);
             releases;
             seconder(true,(bool) 1w0);
             settles(16w62738);
         }
     }
     table tudor {
         key = {
             
         }
         actions = {
             druids(false,7w53);
             seconder((bool) 1w1,false);
             settles(16w12434);
         }
     }
     table sombrero {
         key = {
             
         }
         actions = {
             violet(4w3);
         }
     }
     table sepia {
         key = {
             
         }
         actions = {
             druids(true,7w89);
             releases;
             seconder((bool) 1w1,false);
         }
     }
     table effendis {
         key = {
             
         }
         actions = {
             castellated(32w3791470886);
             concubine;
             settles(16w64221);
         }
     }
     table midge {
         key = {
             
         }
         actions = {
             gatehouses((bool) 1w1);
             releases;
             settles(16w45422);
         }
     }apply {
          tudor.apply();
          hdr.depreciating.rid = (32w1117413730 - 32w3727780098);
          effendis.apply();
          sepia.apply();
          sombrero.apply();
          hdr.depreciating.trujillo = (16w20683 |-| 16w55320);
          hdr.depreciating.rid = (- 32w2479187567);
          if ((((((bool) 1w1 && true) ||
                    (false && hdr.centralizers.isValid()))
                   &&
                   ((true || (bool) 1w1) &&
                       (hdr.larcenys.isValid() && hdr.oleanders.isValid())))
                  ||
                  (((hdr.watertight.isValid() && hdr.larcenys.isValid()) &&
                       (true && (bool) 1w0))
                      || ((! true) && (true && hdr.depreciating.isValid())))))
              
              if (((hdr.esquires.isValid() && (bool) 1w0) &&
                      (false && false)))
                  
                  hdr.depreciating.rid = (32w3922820434 |-| 32w1638895324);
          else
              hdr.depreciating.catted = (- hdr.depreciating.trujillo);
          creamerys.apply();
          hdr.depreciating.rid = (32w2656512790 ^ 32w3185666717);
          hdr.depreciating.rid = (- 32w759560598);
          hdr.depreciating.rid = (- 32w2729280781);
          midge.apply();
     }
 }
 control zloties(inout headers hdr,inout metadata meta,
                 inout standard_metadata_t std_meta) {
     idempotent() tersenesss;
     idempotent() shillelaghs;
     action effeminacys() {
         hdr.depreciating.rid = (32w194297886 - 32w4025097995);
     }
     table adan {
         key = {
             
         }
         actions = {
             effeminacys;
         }
     }
     table staffs {
         key = {
             
         }
         actions = {
             effeminacys;
         }
     }
     table unorthodox {
         key = {
             
         }
         actions = {
             effeminacys;
         }
     }
     table dressmakers {
         key = {
             
         }
         actions = {
             effeminacys;
         }
     }apply {
          staffs.apply();
          hdr.depreciating.trujillo = (hdr.depreciating.catted + 16w45362);
          adan.apply();
          dressmakers.apply();
          if ((!
                  ((((hdr.supplanting.isValid() || (bool) 1w1) ||
                        (! hdr.depreciating.isValid()))
                       &&
                       ((! (bool) 1w1) && (hdr.argosies.isValid() || false)))
                      &&
                      (((true || true) &&
                           (hdr.argosies.isValid() && (bool) 1w1))
                          || (! (false || true))))))
              
              hdr.depreciating.rid = (32w2449722509 & 32w1094160769);
          unorthodox.apply();
     }
 }
 control nadia(inout headers hdr,inout metadata meta,
               inout standard_metadata_t std_meta) {
     lanyard() threescores;
     lanyard() salvadoreans;
     action pss(in bool whitehead) {
         hdr.depreciating.rid = (- 32w1851209258);
         hdr.depreciating.trujillo = (hdr.depreciating.catted + 16w5504);
     }
     action ballparks(in bool acutenesss) {
         hdr.depreciating.rid = (- 32w4294967295);
     }
     action misapprehends(in bool mescal) {
         hdr.depreciating.rid = (~ 32w3237173719);
     }
     action newtons() {
         hdr.depreciating.rid = (32w1800611231 - 32w4023483069);
         hdr.depreciating.catted = (16w28404 | hdr.depreciating.trujillo);
     }
     action bridgers(in bool foulness) {
         hdr.depreciating.catted = (~ hdr.depreciating.trujillo);
     }
     action crustier(in bool earlene,in bit<7> vibrancy) {
         hdr.depreciating.rid = (- 32w4041960240);
         hdr.depreciating.trujillo = (- hdr.depreciating.catted);
     }
     action darings(in bool brisk) {
         hdr.depreciating.catted = (16w30019 + 16w9799);
     }
     action winning(in bit<7> hairpiece) {
         hdr.depreciating.rid = (~ 32w935534568);
         hdr.depreciating.trujillo = (- 16w0);
     }
     action hygienic(in bool mouthwash,in bit<6> introductory) {
         hdr.depreciating.rid = (32w1864592286 + 32w510804920);
         hdr.depreciating.catted = (- hdr.depreciating.trujillo);
     }
     action lairs(in bit<4> morgues,in bool conviction) {
         hdr.depreciating.catted = (hdr.depreciating.trujillo & 16w0);
     }
     table flirtations {
         key = {
             
         }
         actions = {
             bridgers(false);
             darings((bool) 1w1);
             hygienic(true,6w60);
             misapprehends(true);
         }
     }
     table wiretapper {
         key = {
             
         }
         actions = {
             ballparks((bool) 1w1);
         }
     }
     table perinea {
         key = {
             
         }
         actions = {
             ballparks(false);
             darings(false);
             lairs(4w8,(bool) 1w1);
             misapprehends(true);
         }
     }
     table crowfeet {
         key = {
             
         }
         actions = {
             ballparks((bool) 1w1);
             darings(true);
             misapprehends(false);
         }
     }
     table relocated {
         key = {
             
         }
         actions = {
             hygienic((bool) 1w0,6w27);
             misapprehends(true);
         }
     }apply {
          crowfeet.apply();
          relocated.apply();
          wiretapper.apply();
          flirtations.apply();
          perinea.apply();
          hdr.depreciating.trujillo = (hdr.depreciating.catted & 16w21783);
          hdr.depreciating.catted = (- 16w0);
     }
 }
 control romances(inout headers hdr,inout metadata meta) {
     apply {
         update_checksum(true,
                         {hdr.supplanting.preppy, hdr.supplanting.hangovers,
                             hdr.supplanting.goianias,
                             hdr.supplanting.thereupon,
                             hdr.supplanting.glen,
                             hdr.supplanting.thirtieth,
                             hdr.supplanting.uselessness,
                             hdr.supplanting.bogeyed,
                             hdr.supplanting.frivolity,hdr.supplanting.gide,
                             hdr.supplanting.paganini,hdr.supplanting.tided,
                             hdr.supplanting.clouts,hdr.supplanting.strongroom,
                             hdr.supplanting.elvas, hdr.supplanting.fumed,
                             hdr.supplanting.cartier,hdr.supplanting.imams,
                             hdr.supplanting.priam,
                             hdr.supplanting.vaudevillian,hdr.supplanting.janna},
                         hdr.depreciating.catted, HashAlgorithm.csum16);
         update_checksum(true,
                         {hdr.supplanting.preppy, hdr.supplanting.hangovers,
                             hdr.supplanting.goianias,
                             hdr.supplanting.thereupon,
                             hdr.supplanting.glen,
                             hdr.supplanting.thirtieth,
                             hdr.supplanting.uselessness,
                             hdr.supplanting.bogeyed,
                             hdr.supplanting.frivolity,hdr.supplanting.gide,
                             hdr.supplanting.paganini,hdr.supplanting.tided,
                             hdr.supplanting.clouts,hdr.supplanting.strongroom,
                             hdr.supplanting.elvas, hdr.supplanting.fumed,
                             hdr.supplanting.cartier,hdr.supplanting.imams,
                             hdr.supplanting.priam,
                             hdr.supplanting.vaudevillian,hdr.supplanting.janna},
                         hdr.depreciating.trujillo,HashAlgorithm.csum16);
     }
 }
 control alumnus(packet_out pkt,in headers hdr) {
     apply {
         pkt.emit(hdr.tsp);
         pkt.emit(hdr.oleanders);
         pkt.emit(hdr.watertight);
         pkt.emit(hdr.centralizers);
         pkt.emit(hdr.flicks);
         pkt.emit(hdr.supplanting);
         pkt.emit(hdr.argosies);
         pkt.emit(hdr.esquires);
         pkt.emit(hdr.larcenys);
         pkt.emit(hdr.depreciating);
     }
 }
 V1Switch(sage(),airlifted(),zloties(),nadia(),romances(),alumnus()) main;
 
