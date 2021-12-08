/* p4smith seed: 462710486 */
#include <core.p4>
#include <v1model.p4>

@command_line("--disable-parse-max-depth-limit")

header boyhoods {
     bit<6> contributes;
     bit<6> anorexic;
     bit<16> beekeepers;
     bit<11> noondays;
     bit<32> functionary;
     bit<11> knight;
     bit<12> crankshafts;
     bit<32> counts;
     bit<10> corrupter;
 }
 header stilts {
     bit<7> wriggled;
     bit<2> pabulum;
     bit<48> defilements;
     bit<32> istanbuls;
     bit<8> rescind;
     bit<9> gauged;
     bit<6> appraise;
 }
 header gnats {
     bit<6> ranks;
     bit<8> erudition;
     bit<2> jugglers;
     bit<4> protozoan;
     bit<11> potpourris;
     bit<11> wallace;
     bit<32> remorsefully;
     bit<48> taegus;
     bit<16> disputations;
     bit<7> discriminant;
     bit<7> dinnerwares;
 }
 header ivanhoe {
     bit<3> designations;
     bit<9> amens;
     bit<2> windowpane;
     bit<2> nationalized;
 }
 header hittite {
     bit<5> enlistment;
     bit<32> helplessnesss;
     bit<12> spottinesss;
     bit<48> epithet;
     bit<16> lo;
     bit<7> thespians;
 }
 header domestics {
     bit<6> erratums;
     bit<3> nefertiti;
     bit<8> rapeseed;
     bit<8> batman;
     bit<32> unwariness;
     bit<10> taxidermists;
     bit<10> peregrines;
     bit<8> rents;
     bit<8> heptagons;
     bit<11> great;
     bit<32> sinews;
 }
 header impenetrable {
     bit<4> emollients;
     bit<4> concatenating;
 }
 struct headers {
     impenetrable conditioned;
     impenetrable chess;
     domestics borscht;
     hittite outplay;
     ivanhoe stargazer;
     ivanhoe feints;
     gnats logons;
     stilts goats;
     stilts insidious;
     boyhoods cricketer;
     boyhoods allegrettos;
     boyhoods rinsing;
 }
 struct metadata { }
 parser linenss(packet_in pkt,out headers hdr,inout metadata meta,
                inout standard_metadata_t std_meta) {
     state start {
         transition parse_conditioned;
     }
     state parse_conditioned {
         pkt.extract(hdr.conditioned);
         transition select(hdr.conditioned.concatenating) {
             4w7: parse_allegrettos;
             4w1: parse_chess;
         }
     }
     state parse_chess {
         pkt.extract(hdr.chess);
         transition select(hdr.chess.emollients) {4w15: parse_allegrettos;
             4w7: parse_borscht;
             4w14: parse_logons;
         }
     }
     state parse_borscht {
         pkt.extract(hdr.borscht);
         transition select(hdr.borscht.rents) {8w122: parse_outplay;
         }
     }
     state parse_outplay {
         pkt.extract(hdr.outplay);
         transition select(hdr.outplay.helplessnesss) {32w0: parse_rinsing;
             32w3083691613: parse_stargazer;
         }
     }
     state parse_stargazer {
         pkt.extract(hdr.stargazer);
         transition select(hdr.stargazer.amens) {9w433: parse_allegrettos;
             9w384: parse_logons;
             9w463: parse_feints;
         }
     }
     state parse_feints {
         pkt.extract(hdr.feints);
         transition select(hdr.feints.nationalized) {2w2: parse_cricketer;
             2w2: parse_logons;
         }
     }
     state parse_logons {
         pkt.extract(hdr.logons);
         transition select(hdr.logons.dinnerwares) {7w84: parse_goats;
         }
     }
     state parse_goats {
         pkt.extract(hdr.goats);
         transition select(hdr.goats.gauged) {9w491: parse_cricketer;
             9w377: parse_rinsing;
             9w384: parse_insidious;
         }
     }
     state parse_insidious {
         pkt.extract(hdr.insidious);
         transition select(hdr.insidious.wriggled) {7w127: parse_cricketer;
             7w87: parse_rinsing;
         }
     }
     state parse_cricketer {
         pkt.extract(hdr.cricketer);
         transition select(hdr.cricketer.crankshafts) {
             12w1962: parse_allegrettos;
         }
     }
     state parse_allegrettos {
         pkt.extract(hdr.allegrettos);
         transition select(hdr.allegrettos.crankshafts) {
             12w625: parse_rinsing;
         }
     }
     state parse_rinsing {
         pkt.extract(hdr.rinsing);
         transition accept;
     }
 }
 control rabidness(inout headers hdr,inout metadata meta) {
     apply { }
 }
 control holidays(inout headers hdr,inout metadata meta,
                  inout standard_metadata_t std_meta) {
     action lofts(in bit<16> continuation) {
         hdr.feints.nationalized = (- (2w3 ^ 2w1));
     }
     action kansas() {
         hdr.rinsing.corrupter = hdr.cricketer.corrupter;
     }
     action miriam() {
         hdr.goats.appraise = hdr.goats.appraise;
     }
     action haberdashers() {
         hdr.allegrettos.corrupter = (~ hdr.cricketer.corrupter);
     }
     action repeats() {
         hdr.insidious.appraise = hdr.goats.appraise;
     }
     action deterred(in bool harare,in bool recasts) {
         hdr.rinsing.corrupter = hdr.cricketer.corrupter;
     }
     action greshams() {
         hdr.outplay.thespians = hdr.outplay.thespians;
     }
     action amerce(in bool forgiver,in bit<32> storminesss) {
         hdr.logons.jugglers = (hdr.stargazer.nationalized &
                                   hdr.stargazer.nationalized);
     }
     action hotshots(in bool probations,in bool slate) {
         hdr.insidious.appraise = ((6w55 ^ 6w36) + (6w3 + 6w35));
     }
     action colonels() {
         hdr.rinsing.corrupter = hdr.allegrettos.corrupter;
     }
     table ghat {
         key = {
             ((((false && hdr.logons.isValid()) ||
                   (hdr.stargazer.isValid() && (bool) 1w0))
                  ||
                  ((hdr.rinsing.isValid() && hdr.conditioned.isValid()) &&
                      ((bool) 1w1 && true)))
                 &&
                 ((! (hdr.rinsing.isValid() && hdr.borscht.isValid())) ||
                     ((false && (bool) 1w0) || (! (bool) 1w1))))
             : ternary @name("streaking")
             ;
             ((((10w578 & 10w1023) |-| (10w659 | 10w867)) |
                  hdr.cricketer.corrupter)
                 |-|
                 (((~ 10w229) ^ hdr.cricketer.corrupter) |-|
                     ((- 10w970) |+| hdr.allegrettos.corrupter)))
             : ternary @name("penitentiary")
             ;
             ((((hdr.cricketer.isValid() || false) && (false && true)) &&
                  ((false && true) && (true || true)))
                 &&
                 ((((bool) 1w1 && (bool) 1w1) && (false && (bool) 1w1)) &&
                     ((hdr.stargazer.isValid() && false) &&
                         ((bool) 1w1 && false))))
             : exact @name("viscositys")
             ;
         }
         actions = {
             miriam;
         }
     }apply {
          hdr.feints.nationalized = hdr.stargazer.nationalized;
     }
 }
 control oranges(inout headers hdr,inout metadata meta,
                 inout standard_metadata_t std_meta) {
     action scudding(in bool repulsivenesss,in bit<16> unfrozen) {
         if (((((true || true) && (! (bool) 1w0)) &&
                  (! (hdr.insidious.isValid() && hdr.cricketer.isValid())))
                 &&
                 ((! (false || true)) &&
                     (((bool) 1w1 || hdr.outplay.isValid()) &&
                         (true && false)))))
             
             hdr.stargazer.nationalized = hdr.feints.nationalized;
     }
     action neighbourhood(in bit<8> ridiculousness,in bit<2> oftener) {
         hdr.conditioned.concatenating = hdr.conditioned.concatenating;
     }
     table counterfeit {
         key = {
             
         }
         actions = {
             scudding(
                      ((false && hdr.logons.isValid()) ||
                          (hdr.borscht.isValid() || false)),
                      (- (~ 16w24590)));
         }
     }
     table kashmirs {
         key = {
             ((hdr.borscht.great & (- 11w222)) + (~ (- (- 11w456)))) :
             lpm @name("tribeswomen")
             ;
             (- (- (8w81 ^ 8w58))) : lpm @name("ameliorative")
             ;
         }
         actions = {
             neighbourhood((- ((~ 8w79) ^ (8w122 & 8w106))),
                           ((~ hdr.feints.nationalized) |-|
                               ((- 2w3) + (2w1 + 2w3))));
             scudding(
                      (!
                          (((bool) 1w0 || hdr.cricketer.isValid()) ||
                              ((bool) 1w0 && true))),
                      ((- (~ 16w47406)) -
                          ((16w15255 ^ 16w57424) + (16w61858 | 16w57526))));
         }
     }
     table mansion {
         key = {
             (- ((8w0 - 8w179) & (8w159 + 8w127))) :
             ternary @name("burtons")
             ;
             ((- 8w255) + (~ 8w238)) : lpm @name("murillos")
             ;
         }
         actions = {
             neighbourhood(8w165,2w0);
         }
     }
     table tweedledee {
         key = {
             (!
                 (((false && hdr.allegrettos.isValid()) &&
                      (true && hdr.conditioned.isValid()))
                     && (((bool) 1w1 && (bool) 1w1) && (true && false))))
             : exact @name("babysittings")
             ;
         }
         actions = {
             neighbourhood((- (- (- ((8w225 & 8w191) |+| (8w108 - 8w117))))),
                           (- (hdr.logons.jugglers |-| hdr.logons.jugglers)));
             scudding(((bool) 1w1 || (bool) 1w0),(16w27171 & 16w8495));
         }
     }apply {
          hdr.allegrettos.corrupter = (~ (- 10w257));
          hdr.rinsing.corrupter = hdr.rinsing.corrupter;
          hdr.logons.jugglers = (- hdr.stargazer.nationalized);
     }
 }
 control pigmented(inout headers hdr,inout metadata meta) {
     apply { }
 }
 control regurgitate(packet_out pkt,in headers hdr) {
     apply {
         pkt.emit(hdr.conditioned);
         pkt.emit(hdr.chess);
         pkt.emit(hdr.borscht);
         pkt.emit(hdr.outplay);
         pkt.emit(hdr.stargazer);
         pkt.emit(hdr.feints);
         pkt.emit(hdr.logons);
         pkt.emit(hdr.goats);
         pkt.emit(hdr.insidious);
         pkt.emit(hdr.cricketer);
         pkt.emit(hdr.allegrettos);
         pkt.emit(hdr.rinsing);
     }
 }
 V1Switch(linenss(),rabidness(),holidays(),oranges(),pigmented(),
          regurgitate()) main;
 
