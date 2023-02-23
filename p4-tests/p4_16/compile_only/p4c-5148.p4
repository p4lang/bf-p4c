
#include <t2na.p4>  /* TOFINO2_ONLY */

typedef bit<48> suppositions;
typedef bit<32> superannuation;
typedef bit<16> steinem;
typedef bit<8> summertime;
const bit<16> patrices = 16w4789;
const bit<8> pattersons = 8w8;
const bit<8> payment = 8w12;
const bit<9> patching = 9w0;
const bit<3> orally = 3w5;
const bit<32> minstrel = 32w2684354560;
const bit<16> older = 16w36864;
typedef bit<16> tinkerbells;
const bit<48> oddball = 48w18691697672192;
const bit<8> photogenically = 8w0;
const bit<16> pianola = 16w0;
const bit<8> philanthropic = 8w3;
const bit<8> phisher = 8w4;
const bit<4> nunnerys = 4w2;
const bit<8> novgorod = 8w3;
typedef bit<4> soreness;
const soreness occludes = 0;
const soreness octave = 1;
const soreness occupier = 2;
typedef bit<5> revised;
const revised multiplexes = 5w0;
const revised multiplex = 5w1;
const revised mosaic = 5w2;
const revised motoring = 5w4;
const revised multifariousness = 5w8;
const revised mosul = 5w16;
const revised muslims = 5w3;
const revised narnia = 5w5;
const revised muskets = 5w7;
const revised natalies = 5w9;
const revised murky = 5w15;
const revised mycenae = 5w17;
typedef bit<16> syndicates;
typedef bit<8> syracuses;
typedef bit<4> surtaxing;
const surtaxing oz = 1;
const surtaxing oversea = 2;
enum bit<8> salvages {
    negotiate = 0,
    necessitys = 1,
    near = 2,
    navigabilitys = 3,
    nonautomotive = 4,
    nondisclosures = 5,
    nintendo = 6,
    nineteenths = 7,
    neurosis = 8,
    nepaleses = 9,
    nonphysically = 10,
    normative = 11,
    novembers = 12,
    novas = 13,
    nonflowering = 14
}
enum bit<8> titillated {
    pfizers = 0,
    peskier = 1
}
enum bit<3> scrofulas {
    nylonss = 0,
    multipliers = 1,
    morally = 2,
    pheromone = 3,
    oahus = 4,
    mirthfulness = 5,
    perth = 6
}
enum bit<8> subtotals {
    moldy = 0,
    monitions = 1,
    moonscape = 2,
    moralistic = 3,
    modicums = 4,
    mizzen = 5,
    misplacing = 6,
    misname = 7,
    mishmashes = 16
}
header tilting {
    soreness sophisms;
    @padding
    bit<3> padding;
    bit<1> robustly;
}
header roustabouts {
    bit<16> scanties;
}
header surtax {
    soreness sophisms;
    bit<1> revivalists;
    bit<1> robbin;
    bit<1> rips;
    bit<1> robustly;
    bit<16> scanties;
}
@pa_container_size("ingress" , "hdr.protest.provisional" , 32)
@pa_container_size("ingress" , "hdr.protest.prod" , 32)
header proprietorship {
    superannuation provisional;
    superannuation prod;
}
header spiral {
    MeterColor_t titchy;
}
header squashier {
    bool spreadable;
    @padding
    bit<7> padding;
}
header procrastinators {
    superannuation procreation;
}
header subterfuges {
    subtotals published;
    superannuation sankaras;
}
header roswell {
    bool rossettis;
    @padding
    bit<7> scrumptiously;
}
struct supposes {
    tilting tabby;
    roustabouts surfing;
    roswell priestess;
    salvages reinventions;
    MirrorId_t salamis;
    soreness runners;
    bit<1> revivalists;
    bit<1> robbin;
    bit<1> robustly;
    bit<1> rips;
}
struct suppose {
    tilting tabby;
    roustabouts surfing;
    soreness runners;
    bit<5> revised;
    bit<1> rhizome;
    bit<1> romanticists;
    bit<1> revivalists;
    bit<1> robbin;
    bit<1> robustly;
    bool thoroughness;
    syracuses ravenously;
    salvages reinventions;
    salvages remote;
    syndicates plating;
    suppositions sargent;
    suppositions schultzs;
    superannuation schiller;
    suppositions repeals;
    superannuation repayments;
    superannuation squeezers;
    MirrorId_t salamis;
    bit<16> scanties;
}
struct playboy {
    tilting tabby;
    roustabouts surfing;
    salvages reinventions;
}
@pa_no_overlay("egress" , "hdr.tootling.salinas")
@pa_no_overlay("egress" , "hdr.tootling.policys")
@pa_no_overlay("egress" , "hdr.tootling.picnicking")
@pa_no_overlay("egress" , "hdr.tootling.specify")
@pa_no_overlay("egress" , "hdr.tootling.pomposity")
@pa_no_overlay("egress" , "hdr.tootling.rampage")
@pa_no_overlay("egress" , "hdr.tootling.spawns")
@pa_no_overlay("ingress" , "hdr.principality.prejudgment")
@pa_container_size("ingress" , "ig_md.tabby.$valid" , 8)
@pa_container_size("ingress" , "ig_md.surfing.$valid" , 8)
@pa_container_size("ingress" , "hdr.protest.$valid" , 8)
@pa_container_size("ingress" , "hdr.sweatshop.$valid" , 8)
@pa_container_size("ingress" , "hdr.subsidiarys.$valid" , 8)
@pa_container_size("ingress" , "hdr.successively.$valid" , 8)
@pa_container_size("ingress" , "hdr.springsteen.$valid" , 8)
@pa_container_size("ingress" , "ig_md.understudys.$valid" , 8)
@pa_container_size("ingress" , "ig_md.undesirability.$valid" , 8)
@pa_container_size("ingress" , "ig_md.woodcutting.$valid" , 8)
@pa_container_size("ingress" , "ig_md.woodhulls.$valid" , 8)
@pa_container_size("egress" , "eg_md.tabby.$valid" , 8)
@pa_container_size("egress" , "eg_md.surfing.$valid" , 8)
@pa_container_size("egress" , "hdr.protest.$valid" , 8)
@pa_container_size("egress" , "hdr.sweatshop.$valid" , 8)
@pa_container_size("egress" , "hdr.subsidiarys.$valid" , 8)
@pa_container_size("egress" , "hdr.successively.$valid" , 8)
@pa_container_size("egress" , "hdr.springsteen.$valid" , 8)
@pa_container_size("egress" , "eg_md.understudys.$valid" , 8)
@pa_container_size("egress" , "eg_md.undesirability.$valid" , 8)
@pa_container_size("egress" , "eg_md.woodcutting.$valid" , 8)
@pa_container_size("egress" , "eg_md.woodhulls.$valid" , 8)
@pa_container_size("ingress" , "hdr.premyslid.$valid" , 8)
@pa_container_size("ingress" , "hdr.primacy.$valid" , 8)
@pa_container_size("ingress" , "hdr.primitives.$valid" , 8)
@pa_container_size("ingress" , "hdr.principality.$valid" , 8)
@pa_container_size("ingress" , "hdr.piggishness.$valid" , 8)
@pa_container_size("ingress" , "hdr.restructure.$valid" , 8)
@pa_container_size("ingress" , "hdr.quadruplicating.$valid" , 8)
@pa_container_size("ingress" , "hdr.tangelo.$valid" , 8)
@pa_container_size("ingress" , "hdr.tenantry.$valid" , 8)
@pa_container_size("ingress" , "hdr.toileted.$valid" , 8)
@pa_container_size("ingress" , "hdr.tootling.$valid" , 8)
@pa_container_size("ingress" , "hdr.sating.$valid" , 8)
@pa_container_size("ingress" , "hdr.rattle.$valid" , 8)
@pa_container_size("ingress" , "hdr.rationalists.$valid" , 8)
@pa_container_size("ingress" , "hdr.rayburn.$valid" , 8)
@pa_container_size("ingress" , "hdr.reap.$valid" , 8)
@pa_container_size("ingress" , "hdr.recidivists.$valid" , 8)
@pa_container_size("ingress" , "hdr.recorders.$valid" , 8)
@pa_container_size("ingress" , "hdr.redecorating.$valid" , 8)
@pa_container_size("ingress" , "hdr.reef.$valid" , 8)
@pa_container_size("ingress" , "hdr.reelects.$valid" , 8)
@pa_container_size("ingress" , "hdr.reembodied.$valid" , 8)
@pa_container_size("ingress" , "hdr.refresh.$valid" , 8)
@pa_container_size("ingress" , "hdr.reilly.$valid" , 8)
@pa_container_size("ingress" , "hdr.reasserting.$valid" , 8)
@pa_container_size("ingress" , "hdr.ravened.$valid" , 8)
@pa_container_size("ingress" , "hdr.repetitious.$valid" , 8)
@pa_container_size("ingress" , "hdr.rephotographing.$valid" , 8)
@pa_container_size("ingress" , "hdr.replete.$valid" , 8)
@pa_container_size("egress" , "hdr.premyslid.$valid" , 8)
@pa_container_size("egress" , "hdr.primacy.$valid" , 8)
@pa_container_size("egress" , "hdr.primitives.$valid" , 8)
@pa_container_size("egress" , "hdr.principality.$valid" , 8)
@pa_container_size("egress" , "hdr.piggishness.$valid" , 8)
@pa_container_size("egress" , "hdr.restructure.$valid" , 8)
@pa_container_size("egress" , "hdr.quadruplicating.$valid" , 8)
@pa_container_size("egress" , "hdr.tangelo.$valid" , 8)
@pa_container_size("egress" , "hdr.tenantry.$valid" , 8)
@pa_container_size("egress" , "hdr.toileted.$valid" , 8)
@pa_container_size("egress" , "hdr.tootling.$valid" , 8)
@pa_container_size("egress" , "hdr.sating.$valid" , 8)
@pa_container_size("egress" , "hdr.rattle.$valid" , 8)
@pa_container_size("egress" , "hdr.rationalists.$valid" , 8)
@pa_container_size("egress" , "hdr.rayburn.$valid" , 8)
@pa_container_size("egress" , "hdr.reap.$valid" , 8)
@pa_container_size("egress" , "hdr.recidivists.$valid" , 8)
@pa_container_size("egress" , "hdr.recorders.$valid" , 8)
@pa_container_size("egress" , "hdr.redecorating.$valid" , 8)
@pa_container_size("egress" , "hdr.reef.$valid" , 8)
@pa_container_size("egress" , "hdr.reelects.$valid" , 8)
@pa_container_size("egress" , "hdr.reembodied.$valid" , 8)
@pa_container_size("egress" , "hdr.refresh.$valid" , 8)
@pa_container_size("egress" , "hdr.reilly.$valid" , 8)
@pa_container_size("egress" , "hdr.reasserting.$valid" , 8)
@pa_container_size("egress" , "hdr.ravened.$valid" , 8)
@pa_container_size("egress" , "hdr.repetitious.$valid" , 8)
@pa_container_size("egress" , "hdr.rephotographing.$valid" , 8)
@pa_container_size("egress" , "hdr.replete.$valid" , 8)
@pa_container_size("ingress" , "hdr.toileted.tilted" , 32)
@pa_container_size("ingress" , "hdr.rattle.postbags" , 16)
@pa_container_size("ingress" , "hdr.primacy.screamers" , 32)
@pa_container_size("ingress" , "hdr.primitives.randolph" , 32)

@pa_container_type("egress", "hdr.restructure.$valid", "normal")
@pa_container_type("egress", "hdr.tenantry.$valid", "normal")
@pa_container_type("egress", "hdr.tootling.$valid", "normal")
@pa_container_type("egress", "hdr.toileted.$valid", "normal")
@pa_container_type("egress", "hdr.sating.$valid", "normal")
@pa_container_type("egress", "hdr.rattle.$valid", "normal")
@pa_container_type("egress", "hdr.ravened.$valid", "normal")
@pa_container_type("egress", "hdr.repetitious.$valid", "normal")
@pa_container_type("egress", "hdr.rephotographing.$valid", "normal")

// P4C-5148
// pa_byte_pack pragma on pov bits for checksum fields
// Without this pragma the phv alloc packs the pov bits in different bytes and ends up using more than
// 4 bytes causing a HW violation and results in an error in the assembler
@pa_byte_pack("egress",
    "hdr.restructure.$valid"   ,
    "hdr.tenantry.$valid"      ,
    "hdr.tootling.$valid"      ,
    "hdr.toileted.$valid"      ,
    "hdr.sating.$valid"        ,
    "hdr.rattle.$valid"        ,
    "hdr.rationalists.$valid"  ,
    "hdr.ravened.$valid"
    )

typedef bit<16> stormily;
const stormily onslaughts = 16w2048;
const stormily oilskins = 16w2054;
const stormily onyxs = 16w34525;
const stormily opinionated = 16w33024;
const stormily mimosas = 16w35020;
typedef bit<8> sumter;
const sumter origamis = 1;
const sumter oscilloscope = 58;
const sumter outbacks = 4;
const sumter outlets = 6;
const sumter outlive = 17;
const sumter outcome = 41;
const sumter moriarty = 193;
const bit<32> mortarboards = 8;
const bit<8> overoptimisms = 12;
const steinem offenders = 16w1;
const steinem odell = 16w2;
const summertime orderlinesss = 8w8;
const summertime orchestrations = 8w0;
typedef bit<8> swindled;
const swindled paramedical = 0;
const swindled pappys = 1;
const swindled pastes = 2;
const swindled partition = 4;
const swindled parsed = 8;
const swindled panatellas = 16;
const swindled pastry = 32;
const swindled pedestrians = 18;
header strangeness {
    suppositions postbags;
    suppositions stashes;
    stormily prejudgment;
}
header superstitions {
    bit<4> thunderstorm;
    bit<4> ramifying;
    bit<8> pommelling;
    bit<16> tbs;
    bit<16> quite;
    bit<3> procurement;
    bit<13> pruriently;
    bit<8> teethings;
    bit<8> soweto;
    bit<16> pullets;
    superannuation stashes;
    superannuation postbags;
}
header retry {
    bit<32> scandalmonger;
}
@pa_no_overlay("egress" , "hdr.repetitious.stdio")
@pa_no_overlay("egress" , "hdr.repetitious.pour")
@pa_no_overlay("egress" , "hdr.repetitious.plannings")
header symbolization {
    bit<16> stdio;
    bit<16> pour;
    bit<32> spivs;
    bit<32> pickings;
    bit<4> polaris;
    bit<4> spanning;
    bit<8> procurement;
    bit<16> topee;
    bit<16> plannings;
    bit<16> thundercloud;
}
@pa_no_overlay("egress" , "hdr.rephotographing.stdio")
@pa_no_overlay("egress" , "hdr.rephotographing.pour")
@pa_no_overlay("egress" , "hdr.rephotographing.plannings")
header syria {
    bit<16> stdio;
    bit<16> pour;
    bit<16> punctuated;
    bit<16> plannings;
}
@pa_no_overlay("egress" , "hdr.ravened.type")
@pa_no_overlay("egress" , "hdr.ravened.pullets")
header suggestible {
    bit<8> type;
    bit<8> platypuses;
    bit<16> pullets;
}
@pa_no_overlay("egress" , "hdr.rationalists.sawfly")
@pa_no_overlay("egress" , "hdr.rationalists.stashes")
@pa_no_overlay("egress" , "hdr.rationalists.postbags")
header steeled {
    bit<16> puzos;
    bit<16> southbound;
    bit<8> purposefully;
    bit<8> soughing;
    bit<16> sawfly;
    suppositions stashes;
    superannuation stationary;
    suppositions postbags;
    superannuation postmarks;
}
header tactility {
    bit<8> procurement;
    bit<16> specify;
    bit<8> satietys;
    bit<24> tilted;
    bit<8> pita;
}
header sustenance {
    bit<4> thunderstorm;
    bit<6> teethings;
    bit<6> length;
    bit<4> theologian;
    bit<4> rubidium;
    bit<8> satietys;
    bit<24> starved;
    bit<8> stalkers;
}
header tabbys {
    bit<8> salinas;
    bit<8> policys;
    bit<8> picnicking;
    bit<7> specify;
    bit<1> pomposity;
    bit<32> rampage;
    bit<32> spawns;
}
header texts {
    bit<64> testable;
}
header suarezs {
    bit<32> screamers;
    bit<8> populisms;
}
header structuralism {
    bit<5> prefectures;
    bit<1> tempera;
    bit<2> specify;
    bit<16> rationalism;
    bit<32> randolph;
    bit<16> spaatz;
}
header subpoena {
    stormily prejudgment;
}
struct sudras {
    proprietorship protest;
    spiral sweatshop;
    procrastinators subsidiarys;
    squashier springsteen;
    subterfuges successively;
    strangeness premyslid;
    suarezs primacy;
    structuralism primitives;
    subpoena principality;
    steeled piggishness;
    superstitions restructure;
    suggestible quadruplicating;
    symbolization tangelo;
    syria tenantry;
    tactility toileted;
    tabbys tootling;
    sustenance sating;
    strangeness rattle;
    steeled rationalists;
    superstitions rayburn;
    retry reap;
    retry recidivists;
    retry recorders;
    retry redecorating;
    retry reef;
    retry reelects;
    retry reembodied;
    retry refresh;
    retry reilly;
    retry reasserting;
    suggestible ravened;
    symbolization repetitious;
    texts replete;
    syria rephotographing;
}
struct stimulants { }
struct plucked {
    bool romania;
    bit<16> scanties;
}
action stickily(inout sudras hdr,in bit<16> ingress_port) {
    hdr.primacy.setValid();
    hdr.primacy.screamers = minstrel;
    hdr.primacy.populisms = 0;
    hdr.primitives.setValid();
    hdr.primitives.specify = 0;
    hdr.primitives.randolph = 0;
    hdr.primitives.spaatz = 0;
    hdr.primitives.rationalism = ingress_port;
    hdr.principality.setValid();
    hdr.principality.prejudgment = hdr.premyslid.prejudgment;
    hdr.premyslid.prejudgment = older;
}
parser perseveres(packet_in pkt,out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {1: sleaziest;
            0: skyward;
        }
    }
    state sleaziest {
        transition reject;
    }
    state skyward {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}
parser perspire(packet_in pkt,out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}
parser permutations(packet_in pkt,out sudras hdr,out suppose eg_md,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    Checksum() tenochtitlan;
    perspire() taunts;
    state start {
        taunts.apply(pkt,eg_intr_md);
        transition skittishnesss;
    }
    state skittishnesss {
        soreness sophisms = pkt.lookahead<soreness>();
        transition select(
            sophisms) {octave: sennett;
            occupier: seethe;
            default: seersucker;
        }
    }
    state seersucker {
        pkt.extract(eg_md.tabby);
        eg_md.squeezers = hdr.successively.sankaras;
        eg_md.robustly = eg_md.tabby.robustly;
        pkt.extract(eg_md.surfing);
        pkt.extract(hdr.protest);
        pkt.extract(hdr.sweatshop);
        pkt.extract(hdr.subsidiarys);
        pkt.extract(hdr.springsteen);
        pkt.extract(hdr.successively);
        eg_md.sargent = oddball;
        transition segments;
    }
    state sennett {
        surtax rules;
        pkt.extract(rules);
        eg_md.revised = multiplex;
        eg_md.scanties = rules.scanties;
        transition select(rules.rips,rules.revivalists,
            rules.robbin) {(0,1,0): somebodies;
            (0,0,1): somoza;
            (0,1,1): soak;
            (1,0,0): someway;
            default: segments;
        }
    }
    state somebodies {
        eg_md.revised = muslims;
        transition segments;
    }
    state somoza {
        eg_md.revised = narnia;
        transition segments;
    }
    state soak {
        eg_md.revised = muskets;
        transition segments;
    }
    state someway {
        eg_md.revised = mycenae;
        transition segments;
    }
    state seethe {
        surtax rules;
        pkt.extract(rules);
        eg_md.revised = multiplex;
        eg_md.scanties = rules.scanties;
        transition select(rules.robustly) {1w1: sonograms;
            default: segments;
        }
    }
    state sonograms {
        eg_md.revised = natalies;
        transition segments;
    }
    state segments {
        pkt.extract(hdr.premyslid);
        eg_md.schultzs = hdr.premyslid.stashes;
        transition select(
            hdr.premyslid.prejudgment) {onslaughts: skitter;
            default: accept;
        }
    }
    state skitter {
        pkt.extract(hdr.restructure);
        tenochtitlan.subtract(hdr.restructure.stashes);
        tenochtitlan.subtract(hdr.restructure.postbags);
        eg_md.schiller = hdr.restructure.stashes;
        transition select(
            hdr.restructure.ramifying) {5: popularize;
            default: accept;
        }
    }
    state popularize {
        transition select(
            hdr.restructure.soweto) {origamis: sendoffs;
            outlive: slimline;
            moriarty: stanchion;
            default: accept;
        }
    }
    state sendoffs {
        pkt.extract(hdr.quadruplicating);
        transition accept;
    }
    state stanchion {
        pkt.advance((mortarboards * 8));
        pkt.extract(hdr.tenantry);
        transition accept;
    }
    state slimline {
        pkt.extract(hdr.tenantry);
        tenochtitlan.subtract({hdr.tenantry.stdio});
        tenochtitlan.subtract({hdr.tenantry.pour});
        tenochtitlan.subtract({hdr.tenantry.plannings});
        tenochtitlan.subtract({hdr.tenantry.punctuated});
        tenochtitlan.subtract({hdr.tenantry.punctuated});
        eg_md.plating = tenochtitlan.get();
        transition select(
            hdr.tenantry.plannings) {0: sloshed;
            default: sploshes;
        }
    }
    state sploshes {
        eg_md.thoroughness = true;
        transition sloshed;
    }
    state sloshed {
        transition select(hdr.tenantry.pour) {patrices: slummy;
            default: accept;
        }
    }
    state slummy {
        tactility toileted = pkt.lookahead<tactility>();
        transition select(toileted.specify,
            toileted.pita) {(pianola,photogenically): snowier;
            default: seagulls;
        }
    }
    state seagulls {
        pkt.extract(hdr.toileted);
        transition accept;
    }
    state snowier {
        pkt.extract(hdr.toileted);
        transition select(hdr.toileted.procurement,
            hdr.toileted.satietys) {(pattersons,_): sentimentalisms;
            (payment,phisher): snog;
            (payment,philanthropic): sentimentalisms;
            default: accept;
        }
    }
    state snog {
        pkt.extract(hdr.sating);
        transition select(hdr.sating.satietys,
            hdr.sating.rubidium) {(novgorod,nunnerys): sentimentalisms;
            default: accept;
        }
    }
    state sentimentalisms {
        pkt.extract(hdr.rattle);
        eg_md.repeals = hdr.rattle.stashes;
        transition select(
            hdr.rattle.prejudgment) {oilskins: senselessnesss;
            onslaughts: shaver;
            default: accept;
        }
    }
    state senselessnesss {
        pkt.extract(hdr.rationalists);
        hdr.protest.provisional = hdr.rationalists.stationary;
        hdr.protest.prod = hdr.rationalists.postmarks;
        transition accept;
    }
    state shaver {
        pkt.extract(hdr.rayburn);
        eg_md.repayments = hdr.rayburn.stashes;
        transition select(
            hdr.rayburn.ramifying) {5: poodle;
            6: she;
            7: shies;
            8: shirted;
            9: shoals;
            10: shop;
            11: showbiz;
            12: shuttlecocking;
            13: sidled;
            14: signatory;
            15: sheepfold;
            default: sinuss;
        }
    }
    state she {
        pkt.extract(hdr.reap);
        transition sinuss;
    }
    state shies {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        transition sinuss;
    }
    state shirted {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        transition sinuss;
    }
    state shoals {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        transition sinuss;
    }
    state shop {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        transition sinuss;
    }
    state showbiz {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        pkt.extract(hdr.reelects);
        transition sinuss;
    }
    state shuttlecocking {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        pkt.extract(hdr.reelects);
        pkt.extract(hdr.reembodied);
        transition sinuss;
    }
    state sidled {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        pkt.extract(hdr.reelects);
        pkt.extract(hdr.reembodied);
        pkt.extract(hdr.refresh);
        transition sinuss;
    }
    state signatory {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        pkt.extract(hdr.reelects);
        pkt.extract(hdr.reembodied);
        pkt.extract(hdr.refresh);
        pkt.extract(hdr.reilly);
        transition sinuss;
    }
    state sheepfold {
        pkt.extract(hdr.reap);
        pkt.extract(hdr.recidivists);
        pkt.extract(hdr.recorders);
        pkt.extract(hdr.redecorating);
        pkt.extract(hdr.reef);
        pkt.extract(hdr.reelects);
        pkt.extract(hdr.reembodied);
        pkt.extract(hdr.refresh);
        pkt.extract(hdr.reilly);
        pkt.extract(hdr.reasserting);
        transition sinuss;
    }
    state sinuss {
        transition accept;
    }
    state poodle {
        transition select(
            hdr.rayburn.soweto) {origamis: shantytowns;
            outlets: sissified;
            outlive: skewer;
            moriarty: skimmed;
            default: accept;
        }
    }
    state sissified {
        pkt.extract(hdr.repetitious);
        eg_md.reinventions = salvages.nonautomotive;
        eg_md.remote = salvages.nonphysically;
        eg_md.ravenously = outlets;
        transition accept;
    }
    state skimmed {
        pkt.extract(hdr.replete);
        transition skewer;
    }
    state skewer {
        pkt.extract(hdr.rephotographing);
        eg_md.reinventions = salvages.nonautomotive;
        eg_md.remote = salvages.normative;
        eg_md.ravenously = outlive;
        transition accept;
    }
    state shantytowns {
        pkt.extract(hdr.ravened);
        eg_md.reinventions = salvages.nepaleses;
        eg_md.ravenously = origamis;
        transition accept;
    }
}
control penultimate(packet_out pkt,inout sudras hdr,in suppose eg_md,
                    in egress_intrinsic_metadata_for_deparser_t poured) {
    Mirror() rudiments;
    Checksum() reteach;
    Checksum() razorback;
    Checksum() tenochtitlan;
    apply {
        if ((poured.mirror_type == oversea))
            {
            rudiments.emit<
            surtax>(eg_md.salamis,
                    {eg_md.runners,eg_md.revivalists,eg_md.robbin,
                        eg_md.rhizome,eg_md.robustly,eg_md.surfing.scanties});
        }
        if (hdr.restructure.isValid())
            {
            hdr.restructure.pullets = reteach.update(
                                          {hdr.restructure.thunderstorm,
                                              hdr.restructure.ramifying,
                                              hdr.restructure.pommelling,
                                              hdr.restructure.tbs,
                                              hdr.restructure.quite,
                                              hdr.restructure.procurement,
                                              hdr.restructure.pruriently,
                                              hdr.restructure.teethings,
                                              hdr.restructure.soweto,
                                              hdr.restructure.stashes,
                                              hdr.restructure.postbags});
        }
        if (hdr.rayburn.isValid())
            {
            hdr.rayburn.pullets = razorback.update(
                                      {hdr.rayburn.thunderstorm,
                                          hdr.rayburn.ramifying,
                                          hdr.rayburn.pommelling,
                                          hdr.rayburn.tbs,hdr.rayburn.quite,
                                          hdr.rayburn.procurement,
                                          hdr.rayburn.pruriently,
                                          hdr.rayburn.teethings,
                                          hdr.rayburn.soweto,
                                          hdr.rayburn.stashes,
                                          hdr.rayburn.postbags,
                                          hdr.reap.scandalmonger,
                                          hdr.recidivists.scandalmonger,
                                          hdr.recorders.scandalmonger,
                                          hdr.redecorating.scandalmonger,
                                          hdr.reef.scandalmonger,
                                          hdr.reelects.scandalmonger,
                                          hdr.reembodied.scandalmonger,
                                          hdr.refresh.scandalmonger,
                                          hdr.reilly.scandalmonger,
                                          hdr.reasserting.scandalmonger});
        }
        if (eg_md.thoroughness)
            {
            hdr.tenantry.plannings = tenochtitlan.update(
                                         {hdr.restructure.stashes,
                                             hdr.restructure.postbags,
                                             hdr.tenantry.stdio,
                                             hdr.tenantry.pour,
                                             hdr.tenantry.punctuated,
                                             hdr.tenantry.punctuated,
                                             hdr.toileted,hdr.tootling,
                                             hdr.sating,hdr.rattle,
                                             hdr.rationalists,hdr.ravened,
                                             hdr.repetitious,hdr.replete,
                                             hdr.rephotographing,eg_md.plating});
        }
        pkt.emit(hdr);
    }
}
control peepholes(inout sudras hdr,inout suppose eg_md,
                  in egress_intrinsic_metadata_t eg_intr_md,
                  in egress_intrinsic_metadata_from_parser_t pragmatism,
                  inout egress_intrinsic_metadata_for_deparser_t poured,
                  inout egress_intrinsic_metadata_for_output_port_t pragmatically) {
    apply {
        if ((eg_intr_md.egress_port == patching))
            {
            stickily(hdr,eg_md.scanties);
        }
        eg_md.tabby.setInvalid();
        eg_md.surfing.setInvalid();
        hdr.protest.setInvalid();
        hdr.sweatshop.setInvalid();
        hdr.subsidiarys.setInvalid();
        hdr.springsteen.setInvalid();
        hdr.successively.setInvalid();
    }
}
parser millicent(packet_in pkt,out sudras hdr,out playboy ig_md,
                 out ingress_intrinsic_metadata_t ig_intr_md) {
    perseveres() taunts;
    state start {
        taunts.apply(pkt,ig_intr_md);
        transition select(
            ig_intr_md.ingress_port) {patching: segments;
            default: skittishnesss;
        }
    }
    state skittishnesss {
        soreness sophisms = pkt.lookahead<soreness>();
        transition select(
            sophisms) {octave: sennett;
            occupier: seethe;
            default: seersucker;
        }
    }
    state seersucker {
        pkt.extract(ig_md.tabby);
        pkt.extract(ig_md.surfing);
        pkt.extract(hdr.protest);
        pkt.extract(hdr.sweatshop);
        pkt.extract(hdr.subsidiarys);
        pkt.extract(hdr.springsteen);
        pkt.extract(hdr.successively);
        transition segments;
    }
    state sennett {
        surtax rules;
        pkt.extract(rules);
        transition segments;
    }
    state seethe {
        surtax rules;
        pkt.extract(rules);
        transition segments;
    }
    state segments {
        pkt.extract(hdr.premyslid);
        transition select(
            hdr.premyslid.prejudgment) {older: seigneur;
            onslaughts: skitter;
            default: accept;
        }
    }
    state seigneur {
        pkt.extract(hdr.primacy);
        pkt.extract(hdr.primitives);
        pkt.extract(hdr.principality);
        transition select(hdr.principality.prejudgment) {default: accept;
        }
    }
    state skitter {
        pkt.extract(hdr.restructure);
        transition select(
            hdr.restructure.ramifying) {5: popularize;
            default: accept;
        }
    }
    state popularize {
        transition select(
            hdr.restructure.soweto) {outlive: slimline;
            moriarty: stanchion;
            default: accept;
        }
    }
    state stanchion {
        pkt.extract(hdr.tenantry);
        transition accept;
    }
    state slimline {
        pkt.extract(hdr.tenantry);
        transition select(hdr.tenantry.pour) {patrices: slummy;
            default: accept;
        }
    }
    state slummy {
        pkt.extract(hdr.toileted);
        transition select(hdr.toileted.specify,
            hdr.toileted.pita) {default: seagulls;
        }
    }
    state seagulls {
        transition accept;
    }
    state sentimentalisms {
        pkt.extract(hdr.rattle);
        transition select(
            hdr.rattle.prejudgment) {onslaughts: shaver;
            default: accept;
        }
    }
    state shaver {
        pkt.extract(hdr.rayburn);
        transition select(hdr.rayburn.ramifying) {5: poodle;
            default: sinuss;
        }
    }
    state sinuss {
        hdr.successively.published = subtotals.moonscape;
        transition accept;
    }
    state poodle {
        transition select(
            hdr.rayburn.soweto) {origamis: shantytowns;
            outlets: sissified;
            outlive: skewer;
            moriarty: skimmed;
            default: sonorousnesss;
        }
    }
    state sonorousnesss {
        ig_md.reinventions = salvages.nonautomotive;
        transition accept;
    }
    state sissified {
        pkt.extract(hdr.repetitious);
        ig_md.reinventions = salvages.nonautomotive;
        transition accept;
    }
    state skimmed {
        pkt.extract(hdr.replete);
        transition skewer;
    }
    state skewer {
        pkt.extract(hdr.rephotographing);
        ig_md.reinventions = salvages.nonautomotive;
        transition select(
            hdr.rephotographing.plannings) {0: accept;
            default: accept;
        }
    }
    state shantytowns {
        bit<8> quint = pkt.lookahead<bit<8>>();
        transition select(
            quint) {orderlinesss: shatters;
            orchestrations: shasta;
            default: shareholders;
        }
    }
    state shatters {
        ig_md.reinventions = salvages.nintendo;
        transition accept;
    }
    state shasta {
        ig_md.reinventions = salvages.nineteenths;
        transition accept;
    }
    state shareholders {
        ig_md.reinventions = salvages.neurosis;
        transition accept;
    }
}
control milder(packet_out pkt,inout sudras hdr,in playboy ig_md,
               in ingress_intrinsic_metadata_for_deparser_t quizzed) {
    apply {
        pkt.emit(ig_md.tabby);
        pkt.emit(ig_md.surfing);
        pkt.emit(hdr);
    }
}
control millstream(inout sudras hdr,inout playboy ig_md,
                   in ingress_intrinsic_metadata_t ig_intr_md,
                   in ingress_intrinsic_metadata_from_parser_t rabin,
                   inout ingress_intrinsic_metadata_for_deparser_t quizzed,
                   inout ingress_intrinsic_metadata_for_tm_t ragtimes) {
    apply { }
}
Pipeline(millicent(),millstream(),milder(),permutations(),peepholes(),
         penultimate()) pipe0;
Switch(pipe0) main;
