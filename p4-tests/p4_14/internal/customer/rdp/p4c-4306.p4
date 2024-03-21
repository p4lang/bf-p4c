/* p4obfuscator seed: 1010380719 */
@pragma command_line --disable-parse-max-depth-limit

header_type ingress_parser_control_signals {
  fields {
    priority : 3;
    _pad1 : 5;
    parser_counter : 8;
  }
}

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header ingress ig_prsr_ctrl

header ingress_parser_control_signals ig_prsr_ctrl;

header_type ingress_intrinsic_metadata_t {
  fields {
    resubmit_flag : 1;
    _pad1 : 1;
    _pad2 : 2;
    _pad3 : 3;
    ingress_port : 9;
    ingress_mac_tstamp : 48;
  }
}

@pragma dont_trim

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header ingress ig_intr_md

@pragma pa_mandatory_intrinsic_field ingress ig_intr_md.ingress_port

header ingress_intrinsic_metadata_t ig_intr_md;

header_type generator_metadata_t {
  fields {
    app_id : 16;
    batch_id : 16;
    instance_id : 16;
  }
}

@pragma not_deparsed ingress

@pragma not_deparsed egress

header generator_metadata_t ig_pg_md;

header_type ingress_intrinsic_metadata_from_parser_aux_t {
  fields {
    ingress_global_tstamp : 48;
    ingress_global_ver : 32;
    ingress_parser_err : 16;
  }
}

@pragma pa_fragment ingress ig_intr_md_from_parser_aux.ingress_parser_err

@pragma pa_atomic ingress ig_intr_md_from_parser_aux.ingress_parser_err

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header ingress ig_intr_md_from_parser_aux

header ingress_intrinsic_metadata_from_parser_aux_t ig_intr_md_from_parser_aux;

header_type ingress_intrinsic_metadata_for_tm_t {
  fields {
    _pad1 : 7;
    ucast_egress_port : 9;
    drop_ctl : 3;
    bypass_egress : 1;
    deflect_on_drop : 1;
    ingress_cos : 3;
    qid : 5;
    icos_for_copy_to_cpu : 3;
    _pad2 : 3;
    copy_to_cpu : 1;
    packet_color : 2;
    disable_ucast_cutthru : 1;
    enable_mcast_cutthru : 1;
    mcast_grp_a : 16;
    mcast_grp_b : 16;
    _pad3 : 3;
    level1_mcast_hash : 13;
    _pad4 : 3;
    level2_mcast_hash : 13;
    level1_exclusion_id : 16;
    _pad5 : 7;
    level2_exclusion_id : 9;
    rid : 16;
  }
}

@pragma pa_atomic ingress ig_intr_md_for_tm.ucast_egress_port

@pragma pa_fragment ingress ig_intr_md_for_tm.drop_ctl

@pragma pa_fragment ingress ig_intr_md_for_tm.qid

@pragma pa_fragment ingress ig_intr_md_for_tm._pad2

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_b

@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_b

@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_b

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_mcast_hash

@pragma pa_fragment ingress ig_intr_md_for_tm._pad3

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_mcast_hash

@pragma pa_fragment ingress ig_intr_md_for_tm._pad4

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_exclusion_id

@pragma pa_fragment ingress ig_intr_md_for_tm.level1_exclusion_id

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_exclusion_id

@pragma pa_fragment ingress ig_intr_md_for_tm._pad5

@pragma pa_atomic ingress ig_intr_md_for_tm.rid

@pragma pa_fragment ingress ig_intr_md_for_tm.rid

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header ingress ig_intr_md_for_tm

@pragma dont_trim

@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.drop_ctl

header ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm;

header_type ingress_intrinsic_metadata_for_mirror_buffer_t {
  fields {
    _pad1 : 6;
    ingress_mirror_id : 10;
  }
}

@pragma dont_trim

@pragma pa_intrinsic_header ingress ig_intr_md_for_mb

@pragma pa_atomic ingress ig_intr_md_for_mb.ingress_mirror_id

@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_mb.ingress_mirror_id

@pragma not_deparsed ingress

@pragma not_deparsed egress

header ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;

header_type egress_intrinsic_metadata_t {
  fields {
    _pad0 : 7;
    egress_port : 9;
    _pad1 : 5;
    enq_qdepth : 19;
    _pad2 : 6;
    enq_congest_stat : 2;
    enq_tstamp : 32;
    _pad3 : 5;
    deq_qdepth : 19;
    _pad4 : 6;
    deq_congest_stat : 2;
    app_pool_congest_stat : 8;
    deq_timedelta : 32;
    egress_rid : 16;
    _pad5 : 7;
    egress_rid_first : 1;
    _pad6 : 3;
    egress_qid : 5;
    _pad7 : 5;
    egress_cos : 3;
    _pad8 : 7;
    deflection_flag : 1;
    pkt_length : 16;
  }
}

@pragma dont_trim

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header egress eg_intr_md

@pragma pa_atomic egress eg_intr_md.egress_port

@pragma pa_fragment egress eg_intr_md._pad1

@pragma pa_fragment egress eg_intr_md._pad7

@pragma pa_fragment egress eg_intr_md._pad8

@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_port

@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_cos

header egress_intrinsic_metadata_t eg_intr_md;

header_type egress_intrinsic_metadata_from_parser_aux_t {
  fields {
    egress_global_tstamp : 48;
    egress_global_ver : 32;
    egress_parser_err : 16;
    clone_digest_id : 4;
    clone_src : 4;
    coalesce_sample_count : 8;
  }
}

@pragma pa_fragment egress eg_intr_md_from_parser_aux.coalesce_sample_count

@pragma pa_fragment egress eg_intr_md_from_parser_aux.clone_src

@pragma pa_fragment egress eg_intr_md_from_parser_aux.egress_parser_err

@pragma pa_atomic egress eg_intr_md_from_parser_aux.egress_parser_err

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header egress eg_intr_md_from_parser_aux

header egress_intrinsic_metadata_from_parser_aux_t eg_intr_md_from_parser_aux;

header_type egress_intrinsic_metadata_for_mirror_buffer_t {
  fields {
    _pad1 : 6;
    egress_mirror_id : 10;
    coalesce_flush : 1;
    coalesce_length : 7;
  }
}

@pragma dont_trim

@pragma pa_intrinsic_header egress eg_intr_md_for_mb

@pragma pa_atomic egress eg_intr_md_for_mb.egress_mirror_id

@pragma pa_fragment egress eg_intr_md_for_mb.coalesce_flush

@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.egress_mirror_id

@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_flush

@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_length

@pragma not_deparsed ingress

@pragma not_deparsed egress

header egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb;

header_type egress_intrinsic_metadata_for_output_port_t {
  fields {
    _pad1 : 2;
    capture_tstamp_on_tx : 1;
    update_delay_on_tx : 1;
    force_tx_error : 1;
    drop_ctl : 3;
  }
}

@pragma dont_trim

@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_oport.drop_ctl

@pragma not_deparsed ingress

@pragma not_deparsed egress

@pragma pa_intrinsic_header egress eg_intr_md_for_oport

header egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;

action deflect_on_drop(enable_dod) {
  modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}

header_type pktgen_generic_header_t {
  fields {
    _pad0 : 3;
    pipe_id : 2;
    app_id : 3;
    key_msb : 8;
    batch_id : 16;
    packet_id : 16;
  }
}

header pktgen_generic_header_t pktgen_generic;

header_type pktgen_timer_header_t {
  fields {
    _pad0 : 3;
    pipe_id : 2;
    app_id : 3;
    _pad1 : 8;
    batch_id : 16;
    packet_id : 16;
  }
}

header pktgen_timer_header_t pktgen_timer;

header_type pktgen_port_down_header_t {
  fields {
    _pad0 : 3;
    pipe_id : 2;
    app_id : 3;
    _pad1 : 15;
    port_num : 9;
    packet_id : 16;
  }
}

header pktgen_port_down_header_t pktgen_port_down;

header_type pktgen_recirc_header_t {
  fields {
    _pad0 : 3;
    pipe_id : 2;
    app_id : 3;
    key : 24;
    packet_id : 16;
  }
}

header pktgen_recirc_header_t pktgen_recirc;

blackbox_type stateful_alu {
  attribute reg {
    type: register;
  }
  attribute selector_binding {
    type: table;
    optional;
  }
  attribute initial_register_lo_value {
    type: int;
    optional;
  }
  attribute initial_register_hi_value {
    type: int;
    optional;
  }
  attribute condition_hi {
    type: expression;
    expression_local_variables {
      register_lo, register_hi
    }
    optional;
  }
  attribute condition_lo {
    type: expression;
    expression_local_variables {
      register_lo, register_hi
    }
    optional;
  }
  attribute update_lo_1_predicate {
    type: expression;
    expression_local_variables {
      condition_lo, condition_hi
    }
    optional;
  }
  attribute update_lo_1_value {
    type: expression;
    expression_local_variables {
      register_lo, register_hi, set_bit, set_bitc, clr_bit, clr_bitc, read_bit, read_bitc
    }
    optional;
  }
  attribute update_lo_2_predicate {
    type: expression;
    expression_local_variables {
      condition_lo, condition_hi
    }
    optional;
  }
  attribute update_lo_2_value {
    type: expression;
    expression_local_variables {
      register_lo, register_hi, math_unit
    }
    optional;
  }
  attribute update_hi_1_predicate {
    type: expression;
    expression_local_variables {
      condition_lo, condition_hi
    }
    optional;
  }
  attribute update_hi_1_value {
    type: expression;
    expression_local_variables {
      register_lo, register_hi
    }
    optional;
  }
  attribute update_hi_2_predicate {
    type: expression;
    expression_local_variables {
      condition_lo, condition_hi
    }
    optional;
  }
  attribute update_hi_2_value {
    type: expression;
    expression_local_variables {
      register_lo, register_hi
    }
    optional;
  }
  attribute output_predicate {
    type: expression;
    expression_local_variables {
      condition_lo, condition_hi
    }
    optional;
  }
  attribute output_value {
    type: expression;
    expression_local_variables {
      alu_lo, alu_hi, register_lo, register_hi, predicate, combined_predicate
    }
    optional;
  }
  attribute output_dst {
    type: int;
    optional;
  }
  attribute math_unit_input {
    type: expression;
    expression_local_variables {
      register_lo, register_hi
    }
    optional;
  }
  attribute math_unit_output_scale {
    type: int;
    optional;
  }
  attribute math_unit_exponent_shift {
    type: int;
    optional;
  }
  attribute math_unit_exponent_invert {
    type: bit;
    optional;
  }
  attribute math_unit_lookup_table {
    type: string;
    optional;
  }
  attribute reduction_or_group {
    type: string;
    optional;
  }
  attribute stateful_logging_mode {
    type: string;
    optional;
  }
  method execute_stateful_alu(optional in bit<32> index) {
    reads {
      condition_hi, condition_lo, update_lo_1_predicate, update_lo_1_value, update_lo_2_predicate, update_lo_2_value, update_hi_1_predicate, update_hi_1_value, update_hi_2_predicate, update_hi_2_value, math_unit_input
    }
    writes {
      output_dst
    }
  }
  method execute_stateful_alu_from_hash(in field_list_calculation hash_field_list) {
    reads {
      condition_hi, condition_lo, update_lo_1_predicate, update_lo_1_value, update_lo_2_predicate, update_lo_2_value, update_hi_1_predicate, update_hi_1_value, update_hi_2_predicate, update_hi_2_value, math_unit_input
    }
    writes {
      output_dst
    }
  }
  method execute_stateful_log() {
    reads {
      condition_hi, condition_lo, update_lo_1_predicate, update_lo_1_value, update_lo_2_predicate, update_lo_2_value, update_hi_1_predicate, update_hi_1_value, update_hi_2_predicate, update_hi_2_value, math_unit_input
    }
  }
}

header_type mizzenmasts {
  fields {
    agog : 48;
    cogitations : 48;
    surtaxes : 16;
    version : 4;
    curved : 4;
    khrushchev : 8;
    inexpedience : 16;
    manpower : 16;
    activity : 16;
    rocketing : 8;
    epcots : 8;
    ferrari : 16;
    anesthetization : 32;
    jpeg : 32;
    dismayed : 16;
  }
}

header_type humpbacks {
  fields {
    waxworks : 48;
    forested : 48;
  }
}

header_type trivially {
  fields {
    antsy : 16;
    transforming : 7;
    hospitalised : 9;
    honduran : 16;
    pushpins : 48;
  }
}

header_type respects {
  fields {
    pimplier : 16;
    transforming : 7;
    hospitalised : 9;
    opinion : 16;
    epictetus : 16;
  }
}

header_type campbell {
  fields {
    pimplier : 16;
    honduran : 7;
    hospitalised : 9;
  }
}

header_type zamenhof {
  fields {
    vocalizes : 8;
    clitoris : 8;
    larcenys : 8;
  }
}

header_type desks {
  fields {
    dibss : 16;
    prio : 3;
    chirpier : 1;
    shuttlecocked : 12;
  }
}

header_type pianofortes {
  fields {
    ursine : 16;
  }
}

header_type scroll {
  fields {
    antsy : 16;
    version : 4;
    spam : 4;
    rightists : 8;
    session : 16;
    zambian : 16;
  }
}

header_type camemberts {
  fields {
    epcots : 16;
  }
}

header_type mcgoverns {
  fields {
    alliteratively : 20;
    forewarns : 3;
    solemnizations : 1;
    rocketing : 8;
  }
}

header_type swat {
  fields {
    extrajudicial : 32;
  }
}

header_type lakefront {
  fields {
    version : 4;
    curved : 4;
    khrushchev : 8;
    inexpedience : 16;
    manpower : 16;
    mythologies : 1;
    sawbuck : 1;
    guineas : 1;
    raggedly : 13;
    rocketing : 8;
    epcots : 8;
    ferrari : 16;
    forested : 32;
    waxworks : 32;
  }
}

header_type fruitful {
  fields {
    extrajudicial : 32;
  }
}

header_type digression {
  fields {
    extrajudicial : 64;
  }
}

header_type hamilcar {
  fields {
    extrajudicial : 96;
  }
}

header_type propagates {
  fields {
    extrajudicial : 128;
  }
}

header_type picador {
  fields {
    extrajudicial : 160;
  }
}

header_type isobar {
  fields {
    extrajudicial : 192;
  }
}

header_type leadbellys {
  fields {
    extrajudicial : 224;
  }
}

header_type spivs {
  fields {
    extrajudicial : 256;
  }
}

header_type soggier {
  fields {
    extrajudicial : 288;
  }
}

header_type fascists {
  fields {
    extrajudicial : 320;
  }
}

header_type inveigh {
  fields {
    amontillados : 4;
    forewarns : 8;
    search : 20;
    zambian : 16;
    combustibilitys : 8;
    pensioner : 8;
    forested : 128;
    waxworks : 128;
  }
}

header_type misdoing {
  fields {
    elliots : 16;
    contrerass : 16;
    linefeed : 32;
    interposed : 32;
    withholdings : 4;
    abjectly : 3;
    honduran : 9;
    solid : 16;
    checksum : 16;
    expectancys : 16;
  }
}

header_type starkey {
  fields {
    elliots : 16;
    contrerass : 16;
    toastmasters : 16;
    ieyasus : 16;
  }
}

header_type milestone {
  fields {
    elliots : 16;
    contrerass : 16;
    indistinctnesss : 16;
    ieyasus : 16;
  }
}

header_type consultation {
  fields {
    elliots : 16;
    contrerass : 16;
    marbleize : 32;
    ieyasus : 32;
  }
}

header_type monstrances {
  fields {
    elliots : 16;
    contrerass : 16;
  }
}

header mizzenmasts recolonisations;

header humpbacks conniving;

header trivially sorted;

header respects sepulchered;

header campbell balkhashs;

header zamenhof warbler;

header desks complicit[6];

header scroll bushman;

header camemberts plop;

header pianofortes opinion;

header mcgoverns legginess[6];

header swat elasticising;

header humpbacks cortex;

header desks resist[6];

header pianofortes redistricted;

header lakefront binnacle;

header fruitful percolation;

header digression fusibility;

header hamilcar pincus;

header propagates spine;

header picador ilene;

header isobar lints;

header leadbellys cantankerous;

header spivs blades;

header soggier mississippi;

header fascists tranquilizes;

header inveigh indecisiveness;

header misdoing tidys;

header starkey kudzus;

header milestone lamprey;

header consultation assignable;

header monstrances quadrilaterals;

header_type siphoned {
  fields {
    dolled : 1;
    honduran : 16;
    tush : 9;
  }
}

header_type centrefolds {
  fields {
    springy : 8;
    blameworthinesss : 7;
    modiglianis : 8;
    compromise : 8;
    hospitalised : 9;
    filibusters : 8;
    hash : 16;
    tributaries : 16;
    impacts : 16;
    crossings : 16;
    disclose : 16;
    condillac : 16;
    dislocates : 1;
    insignificances : 1;
    assess : 1;
    ensilages : 1;
    pimplier : 16;
    pushpins : 48;
  }
}

header_type pliancy {
  fields {
    lash : 32;
    detaching : 32;
    necessitating : 128;
    cumulative : 128;
  }
}

header_type leaf {
  fields {
    sauced : 48;
    unattached : 48;
    opinion : 16;
  }
}

header_type tacitus {
  fields {
    unattached : 128;
    sauced : 128;
  }
}

header_type rebate {
  fields {
    quickens : 8;
    unattached : 16;
    sauced : 16;
  }
}

header_type chessboard {
  fields {
    aggrieved : 7;
    troopships : 1;
  }
}

metadata siphoned depoliticize;

metadata centrefolds orators;

metadata pliancy neutrons;

metadata leaf goodwills;

metadata tacitus naif;

metadata rebate laywomans;

metadata chessboard granddaddy;

@pragma packet_entry

parser start {
  return misjudged;
}

@pragma packet_entry

parser start_i2e_mirrored {
  return misjudged;
}

@pragma packet_entry

parser start_e2e_mirrored {
  return misjudged;
}

@pragma parser_value_set_size 6

parser_value_set muskie;

parser misjudged {
  return select (ig_intr_md.ingress_port) {
    muskie : wilbur;
    default : afghan;
  }
}

parser wilbur {
  extract(recolonisations);
  return afghan;
}

field_list splendors {
  recolonisations.version;
  recolonisations.curved;
  recolonisations.khrushchev;
  recolonisations.inexpedience;
  recolonisations.manpower;
  recolonisations.activity;
  recolonisations.rocketing;
  recolonisations.epcots;
  recolonisations.anesthetization;
  recolonisations.jpeg;
}

field_list_calculation bashings {
  input {
    splendors;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field recolonisations.ferrari {
  update bashings;
}

parser afghan {
  extract(conniving);
  set_metadata(goodwills.sauced, latest.waxworks);
  set_metadata(goodwills.unattached, latest.forested);
  return recompensed;
}

parser recompensed {
  return select (current(0, 16)) {
    60720 : luis;
    default : stylists;
  }
}

parser luis {
  extract(sorted);
  return select (latest.honduran) {
    4 mask 4 : narcoleptic;
    default : stylists;
  }
}

parser narcoleptic {
  extract(sepulchered);
  return ingress;
}

parser stylists {
  return select (current(0, 16)) {
    0 mask 64512 : wussier;
    1024 mask 65024 : wussier;
    60160 mask 65280 : elevate;
    33024 : vitiate;
    37376 : vitiate;
    37120 : vitiate;
    34984 : vitiate;
    34916 : defrayal;
    default : digitize;
  }
}

parser elevate {
  extract(balkhashs);
  return select (current(0, 16)) {
    0 mask 64512 : wussier;
    1024 mask 65024 : wussier;
    33024 : vitiate;
    37376 : vitiate;
    37120 : vitiate;
    34984 : vitiate;
    34916 : defrayal;
    default : digitize;
  }
}

parser wussier {
  extract(warbler);
  set_metadata(goodwills.opinion, 1535);
  return ingress;
}

parser vitiate {
  extract(complicit[next]);
  return select (current(0, 16)) {
    33024 : vitiate;
    37376 : vitiate;
    37120 : vitiate;
    34984 : vitiate;
    34916 : defrayal;
    default : digitize;
  }
}

parser defrayal {
  extract(bushman);
  return select (latest.rightists) {
    0 : cooperators;
    default : ingress;
  }
}

parser cooperators {
  extract(plop);
  return select (latest.epcots) {
    33 : buoys;
    87 : pardoner;
    default : ingress;
  }
}

parser digitize {
  extract(opinion);
  set_metadata(goodwills.opinion, latest.ursine);
  return select (latest.ursine) {
    34887 : gynecologys;
    34888 : gynecologys;
    2048 : buoys;
    34525 : pardoner;
    default : ingress;
  }
}

parser gynecologys {
  extract(legginess[next]);
  return select (latest.solemnizations) {
    0 : gynecologys;
    1 : outsize;
    default : ingress;
  }
}

parser outsize {
  return select (current(0, 8)) {
    0 : constricted;
    69 : mattings;
    70 mask 254 : mattings;
    72 mask 248 : mattings;
    96 mask 240 : vladivostok;
    default : jacobin;
  }
}

parser constricted {
  extract(elasticising);
  return select (current(0, 8)) {
    69 : mattings;
    70 mask 254 : mattings;
    72 mask 248 : mattings;
    96 mask 240 : vladivostok;
    default : jacobin;
  }
}

parser mattings {
  return select (current(72, 8)) {
    4 : buoys;
    41 : buoys;
    136 : buoys;
    132 : buoys;
    6 : buoys;
    17 : buoys;
    47 : buoys;
    33 : buoys;
    default : jacobin;
  }
}

parser vladivostok {
  return select (current(48, 8)) {
    4 : pardoner;
    41 : pardoner;
    136 : pardoner;
    132 : pardoner;
    6 : pardoner;
    17 : pardoner;
    47 : pardoner;
    33 : pardoner;
    0 : pardoner;
    43 : pardoner;
    44 : pardoner;
    50 : pardoner;
    51 : pardoner;
    60 : pardoner;
    135 : pardoner;
    59 : pardoner;
    default : jacobin;
  }
}

parser jacobin {
  extract(cortex);
  return select (current(0, 16)) {
    33024 : understate;
    37376 : understate;
    37120 : understate;
    34984 : understate;
    default : genoas;
  }
}

parser understate {
  extract(resist[next]);
  return select (current(0, 16)) {
    33024 : understate;
    37376 : understate;
    37120 : understate;
    34984 : understate;
    default : genoas;
  }
}

parser genoas {
  extract(redistricted);
  return select (latest.ursine) {
    2048 : buoys;
    34525 : pardoner;
    default : ingress;
  }
}

parser buoys {
  extract(binnacle);
  return select (latest.curved) {
    0 mask 12 : ingress;
    4 mask 15 : ingress;
    5 : chastisement;
    6 : inhaled;
    7 : health;
    8 : zelig;
    9 : yesterday;
    10 : announcements;
    11 : millionaire;
    12 : steeplejack;
    13 : outdoorss;
    14 : felice;
    15 : yabbied;
    default : ingress;
  }
}

parser inhaled {
  extract(percolation);
  return chastisement;
}

parser health {
  extract(fusibility);
  return chastisement;
}

parser zelig {
  extract(pincus);
  return chastisement;
}

parser yesterday {
  extract(spine);
  return chastisement;
}

parser announcements {
  extract(ilene);
  return chastisement;
}

parser millionaire {
  extract(lints);
  return chastisement;
}

parser steeplejack {
  extract(cantankerous);
  return chastisement;
}

parser outdoorss {
  extract(blades);
  return chastisement;
}

parser felice {
  extract(mississippi);
  return chastisement;
}

parser yabbied {
  extract(tranquilizes);
  return chastisement;
}

parser pardoner {
  extract(indecisiveness);
  return select (latest.combustibilitys) {
    6 : blarney;
    17 : stamen;
    136 : selenas;
    132 : gaslights;
    33 : ruthlessness;
    default : ingress;
  }
}

parser chastisement {
  return select (binnacle.guineas, binnacle.raggedly, binnacle.epcots) {
    6 : blarney;
    17 : stamen;
    136 : selenas;
    132 : gaslights;
    33 : ruthlessness;
    default : ingress;
  }
}

parser blarney {
  extract(tidys);
  set_metadata(laywomans.unattached, latest.elliots);
  set_metadata(laywomans.sauced, latest.contrerass);
  return unchains;
}

parser stamen {
  extract(kudzus);
  set_metadata(laywomans.unattached, latest.elliots);
  set_metadata(laywomans.sauced, latest.contrerass);
  return personage;
}

parser selenas {
  extract(lamprey);
  set_metadata(laywomans.unattached, latest.elliots);
  set_metadata(laywomans.sauced, latest.contrerass);
  return ingress;
}

parser gaslights {
  extract(assignable);
  set_metadata(laywomans.unattached, latest.elliots);
  set_metadata(laywomans.sauced, latest.contrerass);
  return ingress;
}

parser ruthlessness {
  extract(quadrilaterals);
  set_metadata(laywomans.unattached, latest.elliots);
  set_metadata(laywomans.sauced, latest.contrerass);
  return ingress;
}

parser unchains {
  return select (current(0, 32)) {
    1195725856 : sprightliness;
    default : ingress;
  }
}

parser sprightliness {
  set_metadata(granddaddy.troopships, 1);
  return ingress;
}

parser personage {
  return ingress;
}

@pragma pa_no_overlay ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_no_overlay ingress ig_intr_md_for_tm.mcast_grp_b

field_list pact {
  orators.dislocates;
  orators.hospitalised;
  orators.pushpins;
}

action nop() {
  
}

action shrank() {
  drop();
}

action disc() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, sorted.hospitalised);
}

table disc {
  actions {
    disc;
    }
    default_action : disc();
    size : 1;
  }

action collocation() {
  modify_field(orators.dislocates, 1);
  modify_field(orators.hospitalised, ig_intr_md.ingress_port);
  clone_ingress_pkt_to_egress(1, pact);
}

table collocation {
  reads {
    ig_intr_md.ingress_port : ternary;
    binnacle.valid : ternary;
    indecisiveness.valid : ternary;
    naif.unattached : ternary;
    naif.sauced : ternary;
    tidys.valid : ternary;
    kudzus.valid : ternary;
    lamprey.valid : ternary;
    laywomans.unattached : ternary;
    laywomans.sauced : ternary;
  }
  actions {
    collocation;
  }
  size : 32;
}

action emigre(denmarks) {
  modify_field(ig_intr_md_for_tm.mcast_grp_b, denmarks);
}

table emigre {
  reads {
    ig_intr_md.ingress_port mask 127 : exact;
  }
  actions {
    emigre;
  }
  size : 128;
}

action yevtushenkos(tush) {
  modify_field(orators.hospitalised, ig_intr_md.ingress_port);
  modify_field(orators.pushpins, ig_intr_md_from_parser_aux.ingress_global_tstamp);
  modify_field(depoliticize.tush, tush);
  modify_field(depoliticize.dolled, 0);
  modify_field(depoliticize.honduran, 0);
}

action comparison(tush) {
  modify_field(orators.hospitalised, ig_intr_md.ingress_port);
  modify_field(orators.pushpins, ig_intr_md_from_parser_aux.ingress_global_tstamp);
  modify_field(depoliticize.tush, tush);
  modify_field(depoliticize.dolled, 1);
  modify_field(depoliticize.honduran, 0);
}

action littles() {
  modify_field(orators.hospitalised, ig_intr_md.ingress_port);
  modify_field(orators.pushpins, ig_intr_md_from_parser_aux.ingress_global_tstamp);
  modify_field(depoliticize.honduran, 1);
}

action toothpicks() {
  
}

action tricentennial() {
  drop();
}

@pragma ternary 1

table footsies {
  reads {
    ig_intr_md.ingress_port mask 127 : exact;
  }
  actions {
    yevtushenkos;
    comparison;
    littles;
    toothpicks;
    tricentennial;
  }
  default_action : tricentennial();
  size : 128;
}

action programmables() {
  modify_field(orators.hospitalised, ig_intr_md.ingress_port);
  modify_field(orators.pushpins, ig_intr_md_from_parser_aux.ingress_global_tstamp);
  modify_field(depoliticize.tush, balkhashs.hospitalised);
  modify_field(depoliticize.dolled, balkhashs.pimplier, 1);
  modify_field(depoliticize.honduran, 0);
}

action denounce() {
  drop();
}

table programmables {
  reads {
    recolonisations.cogitations : exact;
    recolonisations.anesthetization : exact;
  }
  actions {
    programmables;
    denounce;
  }
  default_action : denounce();
  size : 6;
}

table harrowed {
  actions {
    denounce;
    }
    default_action : denounce();
    size : 1;
  }

action inspections(hospitalised) {
  modify_field(ig_intr_md_for_tm.mcast_grp_b, hospitalised);
}

action valency() {
  
}

action chute() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, balkhashs.hospitalised);
}

action finalises() {
  drop();
}

@pragma ternary 1

table schusss {
  reads {
    depoliticize.honduran : ternary;
    balkhashs.valid : ternary;
    balkhashs.honduran : ternary;
    orators.springy : ternary;
  }
  actions {
    inspections;
    valency;
    chute;
    finalises;
    springy;
  }
  size : 16;
}

action infuriate() {
  modify_field(goodwills.sauced, cortex.waxworks);
  modify_field(goodwills.unattached, cortex.forested);
  modify_field(goodwills.opinion, redistricted.ursine);
}

action controvert() {
  modify_field(goodwills.sauced, cortex.waxworks);
  modify_field(goodwills.unattached, cortex.forested);
  modify_field(goodwills.opinion, 2048);
  modify_field(naif.unattached, binnacle.forested);
  modify_field(naif.sauced, binnacle.waxworks);
  modify_field(laywomans.quickens, binnacle.epcots);
}

action adidas() {
  modify_field(goodwills.sauced, cortex.waxworks);
  modify_field(goodwills.unattached, cortex.forested);
  modify_field(goodwills.opinion, 34525);
  modify_field(naif.unattached, indecisiveness.forested);
  modify_field(naif.sauced, indecisiveness.waxworks);
  modify_field(laywomans.quickens, indecisiveness.combustibilitys);
}

action compactness() {
  modify_field(goodwills.sauced, conniving.waxworks);
  modify_field(goodwills.unattached, conniving.forested);
  modify_field(goodwills.opinion, opinion.ursine);
}

action chromatically() {
  modify_field(goodwills.sauced, conniving.waxworks);
  modify_field(goodwills.unattached, conniving.forested);
  modify_field(goodwills.opinion, 2048);
  modify_field(naif.unattached, binnacle.forested);
  modify_field(naif.sauced, binnacle.waxworks);
  modify_field(laywomans.quickens, binnacle.epcots);
}

action loosen() {
  modify_field(goodwills.sauced, conniving.waxworks);
  modify_field(goodwills.unattached, conniving.forested);
  modify_field(goodwills.opinion, 34525);
  modify_field(naif.unattached, indecisiveness.forested);
  modify_field(naif.sauced, indecisiveness.waxworks);
  modify_field(laywomans.quickens, indecisiveness.combustibilitys);
}

@pragma ternary 1

table transistorise {
  reads {
    cortex.valid : exact;
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    infuriate;
    controvert;
    adidas;
    compactness;
    chromatically;
    loosen;
  }
  size : 6;
}

action lyell(trichinosiss) {
  bit_or(neutrons.lash, binnacle.forested, trichinosiss);
  modify_field(neutrons.detaching, binnacle.waxworks);
}

action anthologizes(trichinosiss) {
  modify_field(neutrons.lash, binnacle.forested);
  bit_or(neutrons.detaching, binnacle.waxworks, trichinosiss);
}

action ripper() {
  modify_field(neutrons.lash, binnacle.forested);
  modify_field(neutrons.detaching, binnacle.waxworks);
}

action sustenance(trichinosiss) {
  bit_or(neutrons.necessitating, indecisiveness.forested, trichinosiss);
  modify_field(neutrons.cumulative, indecisiveness.waxworks);
}

action crowley(trichinosiss) {
  modify_field(neutrons.necessitating, indecisiveness.forested);
  bit_or(neutrons.cumulative, indecisiveness.waxworks, trichinosiss);
}

action sinuss() {
  modify_field(neutrons.necessitating, indecisiveness.forested);
  modify_field(neutrons.cumulative, indecisiveness.waxworks);
}

table unaffected {
  reads {
    depoliticize.dolled : ternary;
    orators.compromise : exact;
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    lyell;
    anthologizes;
    ripper;
    sustenance;
    crowley;
    sinuss;
  }
  size : 6;
}

register indispensable {
  width : 8;
  instance_count : 1;
}

blackbox stateful_alu creamer {
  reg : indispensable;
  output_value : register_lo;
  output_dst : orators.springy;
}

action typologies() {
  creamer.execute_stateful_alu(0);
}

table typologies {
  actions {
    typologies;
    }
    default_action : typologies();
    size : 1;
  }

register compromise {
  width : 8;
  instance_count : 1;
}

blackbox stateful_alu receptively {
  reg : compromise;
  output_value : register_lo;
  output_dst : orators.compromise;
}

action arched() {
  receptively.execute_stateful_alu(0);
}

table arched {
  actions {
    arched;
    }
    default_action : arched();
    size : 1;
  }

field_list coroner {
  neutrons.lash;
}

field_list_calculation translators {
  input {
    coroner;
  }
  algorithm : crc32;
  output_width : 16;
}

action blip() {
  modify_field_with_hash_based_offset(orators.impacts, 0, translators, 65536);
}

field_list jubilant {
  neutrons.necessitating;
}

field_list_calculation adjoining {
  input {
    jubilant;
  }
  algorithm : crc32;
  output_width : 16;
}

action saviours() {
  modify_field_with_hash_based_offset(orators.impacts, 0, adjoining, 65536);
}

@pragma ternary 1

table scapegoats {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    blip;
    saviours;
  }
  size : 2;
}

field_list endeavouring {
  neutrons.lash;
  laywomans.quickens;
  laywomans.unattached;
  laywomans.sauced;
}

field_list_calculation concentrations {
  input {
    endeavouring;
  }
  algorithm : crc32;
  output_width : 16;
}

action sealants() {
  modify_field_with_hash_based_offset(orators.crossings, 0, concentrations, 65536);
}

field_list weakly {
  neutrons.necessitating;
  laywomans.quickens;
  laywomans.unattached;
  laywomans.sauced;
}

field_list_calculation coruscate {
  input {
    weakly;
  }
  algorithm : crc32;
  output_width : 16;
}

action reminiscing() {
  modify_field_with_hash_based_offset(orators.crossings, 0, coruscate, 65536);
}

action pumped() {
  modify_field(orators.crossings, orators.impacts);
}

@pragma ternary 1

table bloodshed {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
    tidys.valid : exact;
    lamprey.valid : exact;
    assignable.valid : exact;
    quadrilaterals.valid : exact;
    kudzus.valid : exact;
  }
  actions {
    sealants;
    reminiscing;
    pumped;
  }
  default_action : pumped();
  size : 10;
}

field_list hodgepodge {
  neutrons.lash;
  neutrons.detaching;
  laywomans.quickens;
}

field_list_calculation knocks {
  input {
    hodgepodge;
  }
  algorithm : crc32;
  output_width : 16;
}

action neighbours() {
  modify_field_with_hash_based_offset(orators.disclose, 0, knocks, 65536);
}

field_list controverting {
  neutrons.necessitating;
  neutrons.cumulative;
  laywomans.quickens;
}

field_list_calculation overcrowd {
  input {
    controverting;
  }
  algorithm : crc32;
  output_width : 16;
}

action bicyclers() {
  modify_field_with_hash_based_offset(orators.disclose, 0, overcrowd, 65536);
}

@pragma ternary 1

table landings {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    neighbours;
    bicyclers;
  }
  size : 2;
}

field_list trivialisations {
  neutrons.lash;
  neutrons.detaching;
  laywomans.quickens;
  laywomans.unattached;
  laywomans.sauced;
}

field_list_calculation hoard {
  input {
    trivialisations;
  }
  algorithm : crc32;
  output_width : 16;
}

action materialised() {
  modify_field_with_hash_based_offset(orators.condillac, 0, hoard, 65536);
}

field_list rodin {
  neutrons.necessitating;
  neutrons.cumulative;
  laywomans.quickens;
  laywomans.unattached;
  laywomans.sauced;
}

field_list_calculation milkman {
  input {
    rodin;
  }
  algorithm : crc32;
  output_width : 16;
}

action sequestration() {
  modify_field_with_hash_based_offset(orators.condillac, 0, milkman, 65536);
}

action imitated() {
  modify_field(orators.condillac, orators.disclose);
}

@pragma ternary 1

table ods {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
    tidys.valid : exact;
    lamprey.valid : exact;
    assignable.valid : exact;
    quadrilaterals.valid : exact;
    kudzus.valid : exact;
  }
  actions {
    materialised;
    sequestration;
    imitated;
  }
  default_action : imitated();
  size : 10;
}

field_list sections {
  neutrons.detaching;
}

field_list_calculation thirstiness {
  input {
    sections;
  }
  algorithm : crc32;
  output_width : 16;
}

action bakersfield() {
  modify_field_with_hash_based_offset(orators.impacts, 0, thirstiness, 65536);
}

field_list basutolands {
  neutrons.cumulative;
}

field_list_calculation desensitisation {
  input {
    basutolands;
  }
  algorithm : crc32;
  output_width : 16;
}

action purchaser() {
  modify_field_with_hash_based_offset(orators.impacts, 0, desensitisation, 65536);
}

@pragma ternary 1

table ticktacktoes {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    bakersfield;
    purchaser;
  }
  size : 2;
}

field_list criticize {
  neutrons.detaching;
  laywomans.quickens;
  laywomans.sauced;
  laywomans.unattached;
}

field_list_calculation skeptically {
  input {
    criticize;
  }
  algorithm : crc32;
  output_width : 16;
}

action threes() {
  modify_field_with_hash_based_offset(orators.crossings, 0, skeptically, 65536);
}

field_list induces {
  neutrons.cumulative;
  laywomans.quickens;
  laywomans.sauced;
  laywomans.unattached;
}

field_list_calculation forsythias {
  input {
    induces;
  }
  algorithm : crc32;
  output_width : 16;
}

action constrictor() {
  modify_field_with_hash_based_offset(orators.crossings, 0, forsythias, 65536);
}

action racegoers() {
  modify_field(orators.crossings, orators.disclose);
}

@pragma ternary 1

table mummer {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
    tidys.valid : exact;
    lamprey.valid : exact;
    assignable.valid : exact;
    quadrilaterals.valid : exact;
    kudzus.valid : exact;
  }
  actions {
    threes;
    constrictor;
    racegoers;
  }
  default_action : racegoers();
  size : 10;
}

field_list pron {
  neutrons.detaching;
  neutrons.lash;
  laywomans.quickens;
}

field_list_calculation archimedess {
  input {
    pron;
  }
  algorithm : crc32;
  output_width : 16;
}

action seven() {
  modify_field_with_hash_based_offset(orators.disclose, 0, archimedess, 65536);
}

field_list theosophist {
  neutrons.cumulative;
  neutrons.necessitating;
  laywomans.quickens;
}

field_list_calculation illegalitys {
  input {
    theosophist;
  }
  algorithm : crc32;
  output_width : 16;
}

action fielding() {
  modify_field_with_hash_based_offset(orators.disclose, 0, illegalitys, 65536);
}

@pragma ternary 1

table swashs {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
  }
  actions {
    seven;
    fielding;
  }
  size : 2;
}

field_list ombs {
  neutrons.detaching;
  neutrons.lash;
  laywomans.quickens;
  laywomans.sauced;
  laywomans.unattached;
}

field_list_calculation marcelo {
  input {
    ombs;
  }
  algorithm : crc32;
  output_width : 16;
}

action sandy() {
  modify_field_with_hash_based_offset(orators.condillac, 0, marcelo, 65536);
}

field_list massed {
  neutrons.cumulative;
  neutrons.necessitating;
  laywomans.quickens;
  laywomans.sauced;
  laywomans.unattached;
}

field_list_calculation aureliuss {
  input {
    massed;
  }
  algorithm : crc32;
  output_width : 16;
}

action perturbs() {
  modify_field_with_hash_based_offset(orators.condillac, 0, aureliuss, 65536);
}

action seafaring() {
  modify_field(orators.condillac, orators.disclose);
}

@pragma ternary 1

table wylie {
  reads {
    binnacle.valid : exact;
    indecisiveness.valid : exact;
    tidys.valid : exact;
    lamprey.valid : exact;
    assignable.valid : exact;
    quadrilaterals.valid : exact;
    kudzus.valid : exact;
  }
  actions {
    sandy;
    perturbs;
    seafaring;
  }
  default_action : seafaring();
  size : 10;
}

action indigently() {
  modify_field(orators.hash, orators.impacts);
  modify_field(orators.tributaries, orators.crossings);
}

action denature() {
  modify_field(orators.hash, orators.disclose);
  modify_field(orators.tributaries, orators.condillac);
}

table ultimately {
  reads {
    orators.compromise : exact;
  }
  actions {
    indigently;
    denature;
  }
  default_action : denature();
  size : 4;
}

action springy() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, depoliticize.tush);
  bit_or(depoliticize.honduran, depoliticize.honduran, 1);
}

action gyration() {
  
}

counter cavities {
  type : packets_and_bytes;
  direct : ditches;}

table ditches {
  reads {
    complicit[0].shuttlecocked : ternary;
    complicit[0].valid : ternary;
    complicit[1].shuttlecocked : ternary;
    complicit[1].valid : ternary;
    complicit[2].shuttlecocked : ternary;
    complicit[2].valid : ternary;
    complicit[3].valid : ternary;
    complicit[4].valid : ternary;
    complicit[5].valid : ternary;
    legginess[0].valid : ternary;
    legginess[1].valid : ternary;
    legginess[2].valid : ternary;
    legginess[3].valid : ternary;
    legginess[4].valid : ternary;
    legginess[5].valid : ternary;
    goodwills.sauced : ternary;
    goodwills.unattached : ternary;
    goodwills.opinion : ternary;
    warbler.vocalizes : ternary;
    warbler.clitoris : ternary;
    warbler.larcenys : ternary;
    naif.unattached : ternary;
    naif.sauced : ternary;
    laywomans.quickens : ternary;
    laywomans.unattached : ternary;
    laywomans.sauced : ternary;
  }
  actions {
    springy;
    gyration;
    shrank;
  }
  default_action : springy();
  size : 2048;
}

action neutralising(blameworthinesss) {
  modify_field(orators.blameworthinesss, blameworthinesss);
}

table neutralising {
  reads {
    orators.hash mask 511 : exact;
  }
  actions {
    neutralising;
    nop;
  }
  size : 512;
}

register feeding {
  width : 8;
  instance_count : 128;
}

blackbox stateful_alu monoclonal {
  reg : feeding;
  output_value : register_lo;
  output_dst : orators.modiglianis;
}

action collapse() {
  monoclonal.execute_stateful_alu(orators.blameworthinesss);
}

table collapse {
  actions {
    collapse;
    }
    default_action : collapse();
    size : 1;
  }

action thou(kris) {
  modify_field(orators.pimplier, orators.tributaries);
  modify_field(ig_intr_md_for_tm.level2_mcast_hash, orators.tributaries);
  modify_field(ig_intr_md_for_tm.mcast_grp_a, kris);
}

table emergencies {
  reads {
    depoliticize.dolled : ternary;
    orators.modiglianis : ternary;
    orators.blameworthinesss : ternary;
  }
  actions {
    springy;
    thou;
  }
  default_action : springy();
  size : 260;
}

control ingress {
  if (valid(sorted)) {
    apply(disc);
  } else {
    apply(emigre);
    apply(transistorise);
    apply(typologies);
    apply(arched);
    apply(footsies);
    if ((((valid(recolonisations) and valid(balkhashs)) and
        (recolonisations.epcots == 97)) and (recolonisations.surtaxes == 2048))) {
      apply(programmables);
    } else {
      if (valid(recolonisations)) {
        apply(harrowed);
      }
    }
    apply(unaffected);
    if ((depoliticize.dolled == 1)) {
      apply(ticktacktoes);
      apply(swashs);
      apply(mummer);
      apply(wylie);
    } else {
      apply(scapegoats);
      apply(landings);
      apply(bloodshed);
      apply(ods);
    }
    apply(ultimately);
    apply(collocation);
    apply(schusss) {
      valency {
        apply(ditches) {
          gyration {
            apply(neutralising) {
              neutralising {
                apply(collapse);
                apply(emergencies);
              }
            }
          }
        }
      }
    }
  }
}

action ethnologist() {
  modify_field(orators.dislocates, 1);
  modify_field(orators.hospitalised, eg_intr_md.egress_port);
  modify_field(orators.pushpins, eg_intr_md_from_parser_aux.egress_global_tstamp);
  clone_egress_pkt_to_egress(1, pact);
}

table ethnologist {
  reads {
    eg_intr_md.egress_port : ternary;
    binnacle.valid : ternary;
    indecisiveness.valid : ternary;
    naif.unattached : ternary;
    naif.sauced : ternary;
    tidys.valid : ternary;
    kudzus.valid : ternary;
    lamprey.valid : ternary;
    laywomans.unattached : ternary;
    laywomans.sauced : ternary;
  }
  actions {
    ethnologist;
  }
  size : 32;
}

action carbonizing(petitioners, hauliers, cummingss, rocketing, menageries, annuals) {
  add_header(recolonisations);
  modify_field(recolonisations.agog, petitioners);
  modify_field(recolonisations.cogitations, hauliers);
  modify_field(recolonisations.surtaxes, 2048);
  modify_field(recolonisations.version, 4);
  modify_field(recolonisations.curved, 5);
  modify_field(recolonisations.khrushchev, cummingss);
  modify_field(recolonisations.inexpedience, eg_intr_md.pkt_length);
  modify_field(recolonisations.manpower, 0);
  modify_field(recolonisations.activity, 16384);
  modify_field(recolonisations.rocketing, rocketing);
  modify_field(recolonisations.epcots, 97);
  modify_field(recolonisations.anesthetization, menageries);
  modify_field(recolonisations.jpeg, annuals);
  modify_field(recolonisations.dismayed, 12288);
}

action lollobrigidas() {
  remove_header(recolonisations);
}

@pragma ternary 1

table chemically {
  reads {
    recolonisations.valid : ternary;
    eg_intr_md.egress_rid : exact;
    eg_intr_md.egress_port mask 127 : ternary;
  }
  actions {
    carbonizing;
    lollobrigidas;
  }
  default_action : lollobrigidas();
  size : 128;
}

action thailand() {
  add_to_field(recolonisations.inexpedience, 18);
}

table thailand {
  actions {
    thailand;
    }
    default_action : thailand();
    size : 1;
  }

action bauers() {
  add_header(sorted);
  modify_field(sorted.antsy, 60720);
  modify_field(sorted.honduran, 2);
  modify_field(sorted.hospitalised, orators.hospitalised);
  modify_field(sorted.pushpins, orators.pushpins);
}

action classroom() {
  add_header(sorted);
  modify_field(sorted.antsy, 60720);
  modify_field(sorted.honduran, 0);
  modify_field(sorted.hospitalised, orators.hospitalised);
  modify_field(sorted.pushpins, orators.pushpins);
}

@pragma ternary 1

table bauers {
  reads {
    orators.dislocates : exact;
    orators.insignificances : exact;
    eg_intr_md.egress_port : exact;
  }
  actions {
    bauers;
    classroom;
  }
  size : 2;
}

action cosmogonist() {
  add_header(sorted);
  modify_field(sorted.antsy, 60720);
  modify_field(sorted.honduran, depoliticize.honduran);
  modify_field(sorted.hospitalised, orators.hospitalised);
  modify_field(sorted.pushpins, orators.pushpins);
}

action cauterised() {
  remove_header(sorted);
}

@pragma ternary 1

table gild {
  reads {
    eg_intr_md.egress_port : exact;
  }
  actions {
    cosmogonist;
    cauterised;
  }
  default_action : cauterised();
  size : 1;
}

action living() {
  
}

table living {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {
    living;
  }
  size : 1;
}

action preregister() {
  add_header(balkhashs);
  modify_field(balkhashs.hospitalised, depoliticize.tush);
  modify_field(balkhashs.pimplier, orators.pimplier);
}

action cushiest() {
  remove_header(balkhashs);
}

table balkhashs {
  reads {
    eg_intr_md.egress_rid : exact;
  }
  actions {
    preregister;
    cushiest;
  }
  default_action : cushiest();
  size : 65536;
}

action baums(pimplier) {
  modify_field(balkhashs.pimplier, pimplier);
}

table baums {
  reads {
    orators.pimplier mask 4095 : exact;
    eg_intr_md.egress_rid : exact;
  }
  actions {
    baums;
  }
  size : 131072;
}

counter celebrating {
  type : packets_and_bytes;
  instance_count : 512;}

action celebrating() {
  count(celebrating, eg_intr_md.egress_port);
}

table celebrating {
  reads {
    balkhashs.valid : exact;
  }
  actions {
    celebrating;
  }
  size : 1;
}

counter tetonss {
  type : packets_and_bytes;
  instance_count : 1;}

action tetonss() {
  count(tetonss, 0);
}

table tetonss {
  reads {
    balkhashs.valid : exact;
  }
  actions {
    tetonss;
  }
  size : 1;
}

action phenols() {
  modify_field(conniving.waxworks, eg_intr_md_from_parser_aux.egress_global_tstamp);
}

action nascars() {
  modify_field(conniving.forested, orators.pushpins);
}

table teabags {
  reads {
    sorted.valid : ternary;
    sorted.honduran : ternary;
    ig_intr_md.ingress_port : ternary;
    depoliticize.honduran : ternary;
    eg_intr_md.egress_port : ternary;
  }
  actions {
    nascars;
    phenols;
  }
  size : 288;
}

control egress {
  apply(ethnologist);
  apply(chemically) {
    hit {
      apply(thailand);
    }
    miss {
      apply(bauers) {
        miss {
          if ((eg_intr_md_from_parser_aux.clone_src == 0)) {
            apply(teabags);
          }
          apply(gild);
          apply(living) {
            miss {
              apply(balkhashs);
              apply(baums);
              apply(celebrating);
              apply(tetonss);
            }
          }
        }
      }
    }
  }
}

