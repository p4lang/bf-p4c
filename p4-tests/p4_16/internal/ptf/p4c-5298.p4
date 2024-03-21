#include <core.p4>
#include<tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<12> vlan_id_t;

header ethernet_h {
    mac_addr_t dst_addr; //3
    mac_addr_t src_addr; //3
    bit<16> ether_type; //2
}

struct vlan_tag_s{ //4
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid; //2
    bit<16> ether_type; //2
}

struct vlan_tag_two_s{
    vlan_tag_s vlan0;
    vlan_tag_s vlan1;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}



struct mpls_s {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}


header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

//https://tools.ietf.org/html/rfc4448
//https://tools.ietf.org/html/rfc4385
header pw_cw_h {
    bit<4> pw_data; // should be 0000
    bit<12> reserved;
    // bit<4> flags;
    // bit<2> frag;
    // bit<6> pw_length;
    bit<16> sequence;
}


//@flexible
header mirror_h {
    bit<7> filler;
    bit<9> ingress_port;
}

struct empty_header_t {}

struct empty_metadata_t {}

/*
@flexible
header mirror_bridged_metadata_h {
}
*/
//@flexible
header bridge_header_h {
    bit<7> output_group;//needs to be byte aligned so this extra is for that
    bit<9> ingress_port;//a port is 9 bits
}


struct MplsDouble_h { //used in parser for look ahead
    bit<20> label0;
    bit<3> exp0;
    bit<1> bos0;
    bit<8> ttl0;
    bit<20> label1;
    bit<3> exp1;
    bit<1> bos1;
    bit<8> ttl1;
}


struct MplsTriple_h { //used in parser for look ahead
    bit<20> label0;
    bit<3> exp0;
    bit<1> bos0;
    bit<8> ttl0;
    bit<20> label1;
    bit<3> exp1;
    bit<1> bos1;
    bit<8> ttl1;
    bit<20> label2;
    bit<3> exp2;
    bit<1> bos2;
    bit<8> ttl2;
}

/*
header MplsTwo_h
{
mpls_h mpls0;    
mpls_h mpls1;    
}
*/



struct MplsTwo_s
{
    mpls_s mpls0;
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header MplsThree_h //this is used so lookahead can populate the entire object
{
    MplsTwo_s mpls1;
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}
/*
struct MplsThree_s //this is used so lookahead can populate the entire object
{
    MplsTwo_s mpls1;
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}
*/

//header for route pipeline code
struct route_headers_t {
    bridge_header_h bridge_header;
    ethernet_h ethernet;
    vlan_tag_h route_tag; //used for adding an extra vlan tag for our own routing
    vlan_tag_h[2] vlan_tag;
}





typedef MirrorType_t mirror_type_t;



const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;




/*
stuct route_port_metadata_t {
    bit<1> flowVlan;
}
*/

//const bit<32> PORT_METADATA_SIZE = 32w64;
struct my_port_metadata_t {
    bit<8> output_group;
    bit<8> blank1;
    bit<16> blank2;
    bit<16> blank3;
    bit<16> blank4;
};

struct route_egress_metadata_t {
    bit<7> output_group;//needs to be byte aligned so this extra is for that
    bit<9> ingress_port;//a port is 9 bits

    MirrorId_t egr_mir_ses; // Egress mirror session ID
}
struct route_metadata_t {
    my_port_metadata_t port_metadata;

    MirrorId_t ing_mir_ses; // Ingress mirror session ID
//    MirrorId_t egr_mir_ses;   // Egress mirror session ID


     bit<3> which_digest;
 //most of this can be replaced by a 3 bit field and using ternary 
//	bit<1> mpls_3_plus;  

//    MplsThree_s mpls2; //used for table object would like to use this for digest but will not work
 MplsThree_h mpls2;

 vlan_tag_s vlan_0;
 vlan_tag_s vlan_1;
    bit<9> ingress_port; //had to add for the ingress mirror compiler bug
}


parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md,
        inout route_metadata_t ig_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        ig_md.port_metadata = port_metadata_unpack<my_port_metadata_t>(pkt);
/*#if __TARGET_TOFINO__ == 2
        // We need to advance another 128 bits since t2na metadata
        // is of 192 bits in total and my_port_metadata_t only 
        // consumes 64 bits
        pkt.advance(PORT_METADATA_SIZE-64); //port_metadata_unpack takes care of this
#endif*/
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

/*
stuct route_port_metadata_t {
    bit<1> flowVlan;
};
*/
// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser PAC_Route_IngressParser(
        packet_in pkt,
        out route_headers_t hdr,
        out route_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md, ig_md);

  hdr.bridge_header.setValid();
  hdr.bridge_header.ingress_port = /*(bit<16>)*/ig_intr_md.ingress_port;
        ig_md.ingress_port = ig_intr_md.ingress_port; //having to do this for the ingress mirror header was a compiler bug using the bridge header
//        hdr.bridge_header.output_group = 0;

        ig_md.mpls2.setValid();
  ig_md.mpls2.mpls1.mpls0.label = 0;
  ig_md.mpls2.mpls1.mpls0.bos = 0;
  ig_md.mpls2.mpls1.label = 0;
  ig_md.mpls2.mpls1.bos = 0;
  ig_md.mpls2.label = 0;
  ig_md.mpls2.bos = 0;

//		ig_md.mpls_3_plus = 0;

  ig_md.vlan_0.vid = 0;
  ig_md.vlan_1.vid = 0;

//        ig_md.src_dst_port.src_port = 0;
//        ig_md.src_dst_port.dst_port = 0;

        transition parse_ethernet;
//        transition parse_metadata;
    }

/*
    state parse_metadata {
        ig_md.port_metadata = port_metadata_unpack<route_port_metadata_t>(pkt);
        transition parse_ethernet;
    }
*/

    state set_vlan_digest {
        ig_md.which_digest = ((bit<3>)0x05);
        transition accept;
    }

    state parse_ethernet {

        pkt.extract(hdr.ethernet);

  //so that we are learning MPLS in VLAN we need to init the VIDs to 0
  //and then invalidate the vlan hdr objects

        transition select(hdr.ethernet.ether_type) {
     0x8100: parse_vlan_tag_one;
     0x8847: parseMpls;//parse_mpls_0;
        default: set_vlan_digest;
        }
    }

    //Only need to look at the first two mpls labels 
    state parseMpls {
        MplsDouble_h mpls = pkt.lookahead<MplsDouble_h>();
        transition select(mpls.bos0,mpls.bos1) {
            (1,_) : parseOneMpls;
            (0,1) : parseTwoMpls;
            (0,0) : parseThreeMpls;
            default: parseThreeMpls;
        }
    }
/*
    state parseMpls {
        MplsTriple_h mpls = pkt.lookahead<MplsTriple_h>();
        transition select(mpls.bos0,mpls.bos1,mpls.bos2) {
            (1,_,_) : parseOneMpls;
            (0,1,_) : parseTwoMpls;
            (0,0,1) : parseThreeMpls;
            (0,0,0) : parseThreeMpls;
            default: parseThreeMpls;
        }
    }
*/
    state parseOneMpls {
        ig_md.mpls2.mpls1.mpls0 = pkt.lookahead<mpls_s>();
        ig_md.which_digest = ((bit<3>)0x01);
//        pkt.extract(hdr.mpls0);

        transition accept;
    }


    state parseTwoMpls {
        ig_md.mpls2.mpls1= pkt.lookahead<MplsTwo_s>();
        ig_md.which_digest = ((bit<3>)0x02);
//        pkt.extract(hdr.mpls0);

//        pkt.extract(hdr.mpls1);
        transition accept;
    }

    state parseThreeMpls {
        ig_md.mpls2 = pkt.lookahead<MplsThree_h>();
        ig_md.which_digest = ((bit<3>)0x03);
//        pkt.extract(hdr.mpls0);

//        pkt.extract(hdr.mpls1);

//        pkt.extract(hdr.mpls2);

//        ig_md.mpls_3_plus = 1;
        transition accept;
    }

/**
*  I could not get the auto array index to work correctly when trying to 
*  initialize vlan_raw.vid
*/
    state parse_vlan_tag_one {
 ig_md.vlan_0= pkt.lookahead<vlan_tag_s>();
 pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
     0x8100: parse_vlan_tag_two;
     0x8847: parseMpls;
        default: set_vlan_digest;
        }
    }

    state parse_vlan_tag_two {
 ig_md.vlan_1= pkt.lookahead<vlan_tag_s>();
 pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
     0x8847: parseMpls;
        default: set_vlan_digest;
        }
    }

}





// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser PAC_Route_EgressParser(
        packet_in pkt,
        out route_headers_t hdr,
        out route_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);

        transition parse_metadata;
    }


//After much trial and error this worked.  stupid compiler
    state parse_metadata {
        pkt.extract(hdr.bridge_header);

        transition select(hdr.bridge_header.output_group)
        {
            0x7F: remove_route_tag_ethernet; //had a bug where egress vlans were being stacked when paired with egress mirroring  made 0x7F special value
            default: parse_ethernet;
        }
//        transition parse_ethernet;
    }

    //This is an egress mirrored packet so need to skip the route_tag vlan
    state remove_route_tag_ethernet {

        eg_md.output_group = 0;

        ethernet_h ethHeader;
        vlan_tag_h route_tag;

        pkt.extract(ethHeader);
        pkt.extract(route_tag);

        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = ethHeader.dst_addr;
        hdr.ethernet.src_addr = ethHeader.src_addr;
        hdr.ethernet.ether_type = route_tag.ether_type;

        transition accept;
    }

    state parse_ethernet {
        eg_md.output_group = hdr.bridge_header.output_group;
        pkt.extract(hdr.ethernet);//have to do this just incase we are putting on a route tag

       transition accept;
    }
}





// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control PAC_Route_EgressDeparser(
        packet_out pkt,
        inout route_headers_t hdr,
        in route_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Mirror() mirror;

    apply {

        if (eg_dprsr_md.mirror_type == MIRROR_TYPE_E2E) {
              mirror.emit<mirror_h>(eg_md.egr_mir_ses, {eg_md.output_group,eg_md.ingress_port});
        }
        pkt.emit(hdr);

    }
}

// ---------------------------------------------------------------------------
// Switch Egress MAU
// ---------------------------------------------------------------------------
control PAC_Route_Egress(
        inout route_headers_t hdr,
        inout route_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

  Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) eg_port_counter;

//        Counter<bit<32>, bit<21>>(512, CounterType_t.PACKETS_AND_BYTES) eg_port_vlan_counter;


        action no_vlan()
        {
            eg_md.output_group = 0;
            eg_md.ingress_port = hdr.bridge_header.ingress_port;
        }

        action add_vlan(vlan_id_t vid)
        {
            eg_md.output_group = 0x7F; //marking this packet as mirrored and vlan tagged
            eg_md.ingress_port = hdr.bridge_header.ingress_port;

            hdr.route_tag.setValid();
            hdr.route_tag.vid = vid;
            hdr.route_tag.pcp = 0;
            hdr.route_tag.cfi = 0;
            hdr.route_tag.ether_type = hdr.ethernet.ether_type;
            hdr.ethernet.ether_type = 0x8100;

//    		eg_port_vlan_counter.count( eg_intr_md.egress_port ++ vid, 2 ); //need to move until after hdr.bridge_header.setInvalid();
        }

        //code for removing a vlan, the compiler will not let me put this here.
        //so will need to add an other table for this in the long run
        action remove_vlan()
        {
/*                {
                    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                    hdr.vlan_tag[0].setInvalid();
                }*/
        }

        table vlan_route_tag
        {
            key = {
       hdr.bridge_header.ingress_port : exact; //hdr.bridge_header.ingress_port : exact;
       eg_intr_md.egress_port: ternary;
            }
            actions = {
                no_vlan;
                add_vlan;
//                remove_vlan;
            }
            default_action = no_vlan;
        }

        action no_mirror()
        {
            if (eg_md.output_group != 0x7F)
                eg_md.output_group = 0;
        }

        //if we start doing more will need to create a resolve action
        action mirror(MirrorId_t egr_ses)
        {
            if (eg_md.output_group != 0x7F)
                eg_md.output_group = 0;

            eg_md.egr_mir_ses = egr_ses;
//            eg_md.pkt_type = PKT_TYPE_MIRROR;
            eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
//            hdr.bridge_header.output_group = 0;
        }

        table egress_mirror
        {
            key = {
       hdr.bridge_header.ingress_port : exact;//hdr.bridge_header.ingress_port : exact;
       eg_intr_md.egress_port: ternary;
                eg_md.output_group : exact; //hdr.bridge_header.output_group : exact;
            }
            actions = {
                no_mirror;
                mirror;
            }
            default_action = no_mirror;
        }



    apply
 {
//        extra_header.apply();

        if (hdr.ethernet.isValid())
        {
            egress_mirror.apply();
            vlan_route_tag.apply();
        }
        hdr.bridge_header.setInvalid();
  eg_port_counter.count( eg_intr_md.egress_port, 2 ); //need to move until after hdr.bridge_header.setInvalid();

//        if (eg_md.output_group != 0x7F)
  //          eg_md.output_group = 0;

 }

}

//////////////////////
//Notes:
//compiler was complaining about the size of the digests(something odd changed it was not before)
// for now removing unused fields if we need some of these then will need to look into the bug
/////////////////////
struct mpls_3_digest_t {
    bit<9> og_port; //Having an issue where this is not being properly filled
    bit<48> src_mac;
    bit<48> dst_mac;
    bit<12> vlan0;
    bit<12> vlan1;

    bit<20> label0;
    bit<20> label1;
    bit<20> label2;
    bit<1> bos2;
}

struct mpls_2_digest_t {
    bit<9> og_port;
    bit<48> src_mac;
    bit<48> dst_mac;
    bit<12> vlan0;
    bit<12> vlan1;

    bit<20> label0;
    bit<20> label1;
}


struct mpls_1_digest_t {
    bit<9> og_port;
    bit<48> src_mac;
    bit<48> dst_mac;
    bit<12> vlan0;
    bit<12> vlan1;

    bit<20> label0;
}


struct vlan_digest_t
{
    bit<9> og_port;
    bit<48> src_mac;
    bit<48> dst_mac;
    bit<16> ether_type;
    bit<16> ether_type0;
    bit<12> vlan0;
    bit<16> ether_type1;
    bit<12> vlan1;
}


struct control_layer2_s
{
    bit<4> layer2_action;
    bit<9> oport;
    MirrorId_t igr_ses;
}


// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control PAC_Route_IngressDeparser(
        packet_out pkt,
        inout route_headers_t hdr,
        in route_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;

    Digest<mpls_1_digest_t>() mpls_1_digest;
    Digest<mpls_2_digest_t>() mpls_2_digest;
    Digest<mpls_3_digest_t>() mpls_3_digest;

 Digest<vlan_digest_t>() vlan_digest;

    apply
 {
  if (ig_dprsr_md.digest_type == ((bit<3>)0x01))
  {
   mpls_1_digest.pack({hdr.bridge_header.ingress_port,hdr.ethernet.src_addr,hdr.ethernet.dst_addr,hdr.vlan_tag[0].vid,hdr.vlan_tag[1].vid,ig_md.mpls2.mpls1.mpls0.label });
  }
  else if (ig_dprsr_md.digest_type == ((bit<3>)0x02))
  {
   mpls_2_digest.pack({hdr.bridge_header.ingress_port,hdr.ethernet.src_addr,hdr.ethernet.dst_addr,hdr.vlan_tag[0].vid,hdr.vlan_tag[1].vid, ig_md.mpls2.mpls1.mpls0.label, ig_md.mpls2.mpls1.label});
  }
  else if (ig_dprsr_md.digest_type == ((bit<3>)0x03))
  {
   mpls_3_digest.pack({hdr.bridge_header.ingress_port,hdr.ethernet.src_addr,hdr.ethernet.dst_addr,hdr.vlan_tag[0].vid,hdr.vlan_tag[1].vid, ig_md.mpls2.mpls1.mpls0.label, ig_md.mpls2.mpls1.label , ig_md.mpls2.label, ig_md.mpls2.bos});
  }
  else if (ig_dprsr_md.digest_type == ((bit<3>)0x05))
  {
   vlan_digest.pack({ hdr.bridge_header.ingress_port,hdr.ethernet.src_addr,hdr.ethernet.dst_addr,hdr.ethernet.ether_type,hdr.vlan_tag[0].ether_type,hdr.vlan_tag[0].vid,hdr.vlan_tag[1].ether_type,hdr.vlan_tag[1].vid });
  }

        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E)
  {
   mirror.emit<mirror_h>(ig_md.ing_mir_ses, {0,ig_md.ingress_port}); //had to add ingress_port to metadata because call below the compiler was putting the entire bridge header instead of just the port
//            mirror.emit<mirror_h>(ig_md.ing_mir_ses, {0,hdr.bridge_header.ingress_port});
        }

  pkt.emit(hdr);
 }
}


/////////
// Layer2 actions: 
//      NOP: use the default port action
//   TOPORT: sends this layer2 to the configured port no matter what the default port action
//   DIGEST: 
//     DROP: drop this layer2 no matter what the default port action
//  TOPORT_MIRROR: sends this layer2 to the configured port & mirror this layer2 to the configured port no matter what the default port action
//     NOP_MIRROR: use the default port action & mirror this layer2 to the configured port
//    DROP_MIRROR: drop this layer2 and mirror this layer2 to the configured port no matter what the default port action
/////////
//////////
// port actions:
//   TOPORT: sends this port out the configured port
//     DROP: drops the traffic from this port
// TOPORT_MIRROR: sends this port out the configured port and mirrors the traffic to the configured port
//   DROP_MIRROR: drops the traffic from this port and mirrors the traffic to the configured port
//////////
struct control_port_s
{
 bit<3> port_action; //DROP TO_PORT MIRROR_DROP MIRROR_TO_PORT
    bit<9> oport;
 bit<1> learn_port; //1 means learn layer2 0 means do not learn layer2
    MirrorId_t igr_ses;
}


////////////
//IGNORE actions:
//
//     NOP: Do nothing associated with the ignore table
//  IGNORE: If DIGEST requested do NOT do it just do the port default
//    DROP: If DIGEST requested do NOT but rather drop. If specific layer2 rule exists then do that
//  TOPORT: If DIGEST requested do NOT but rather send to configured port. If specific layer2 rule exists then do that
////////////





struct ignore_s
{
 bit<2> ignore_action;
    bit<9> oport;
}

// ---------------------------------------------------------------------------
// Switch Ingress MAU
// ---------------------------------------------------------------------------
control PAC_Route_Ingress(
        inout route_headers_t hdr,
        inout route_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

 //group output port
 bit<9> group_output_port=0;
 Random<bit<7>>() group_rnd;
 bit<7> rnd_val=0;

 //state of ignore table
 ignore_s ignore_state = {0,0};

 //routing state
 control_port_s port_state = {0,0,0,0};
 control_layer2_s layer2_state = {0,0,0};

 //counters
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_layer2; //counts the number of bytes/packets that a layer2 table rule sees
 Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) port_counter; //counts the number of bytes/packets that comes into a port
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_ignore; //counts the number of bytes/packets that the ignore table rule sees

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_port_table; //counts the number of bytes/packets that the port table rule sees

 Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) parse_error_port_counter;
 Counter<bit<32>, bit<16>>(2049, CounterType_t.PACKETS_AND_BYTES) parse_error_type_counter;

 //default actions for a port
 action port_drop(bit<1> learn_port) {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x2;

  direct_counter_port_table.count();
 }
 action port_drop_mirror(bit<1> learn_port,MirrorId_t igr_ses) {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x4;
  port_state.igr_ses = igr_ses;

  direct_counter_port_table.count();
 }

    action port_to_port(bit<1> learn_port,PortId_t port) {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x1;
  port_state.oport = port;

  direct_counter_port_table.count();
    }

    action port_to_port_mirror(bit<1> learn_port,PortId_t port,MirrorId_t igr_ses) {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x3;
  port_state.oport = port;
  port_state.igr_ses = igr_ses;

  direct_counter_port_table.count();
    }

 action port_to_group(bit<1> learn_port)
 {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x5;

  direct_counter_port_table.count();
 }

 action port_to_group_mirror(bit<1> learn_port,MirrorId_t igr_ses)
 {
  port_state.learn_port = learn_port;
  port_state.port_action= 3w0x6;
  port_state.igr_ses = igr_ses;

  direct_counter_port_table.count();
 }

 //Default rules for each port
 table port_rules_table {
  key = {
      ig_intr_md.ingress_port: exact;
   ig_md.vlan_0.vid: ternary;

  }
        actions = {
   port_drop;
   port_drop_mirror;
   port_to_port;
   port_to_port_mirror;
   port_to_group;
   port_to_group_mirror;
        }




   size = 128;


        default_action = port_drop(0);
  counters = direct_counter_port_table;
 }

 action output_group_nop()
 {

 }

 action output_group_setoutput(bit<9> oport)
 {
  group_output_port = oport;
 }

 table output_group_table {
  key = {
   rnd_val: exact;
   ig_md.port_metadata.output_group: exact;
  }
  actions = {
   output_group_nop;
   output_group_setoutput;
  }
  size=1024;
  default_action=output_group_nop;
 }

 action hit_ignore()
 {
  ignore_state.ignore_action = 2w0x3;
  direct_counter_ignore.count();
 }

 action nop_ignore()
 {
  ignore_state.ignore_action = 2w0x0;
  direct_counter_ignore.count();
 }

 action drop_ignore()
 {
  ignore_state.ignore_action= 2w0x1;
  direct_counter_ignore.count();
 }
 action to_port_ignore(bit<9> port)
 {
  ignore_state.oport = port;
  ignore_state.ignore_action = 2w0x2;
  direct_counter_ignore.count();
 }


 table ignore_stack {
        key = {
   ig_intr_md.ingress_port: ternary;
   hdr.ethernet.dst_addr :ternary;
   hdr.ethernet.src_addr :ternary;
   hdr.ethernet.ether_type: ternary;
   ig_md.vlan_0.vid: ternary;
   ig_md.vlan_1.vid: ternary;
            ig_md.mpls2.mpls1.mpls0.label: ternary;
            ig_md.mpls2.mpls1.label: ternary;
  }
        actions = {
   hit_ignore;
   nop_ignore;
   drop_ignore;
   to_port_ignore;
        }
        default_action = nop_ignore;
  counters = direct_counter_ignore;
 }

 action layer2_digest()
 {
  direct_counter_layer2.count();
  layer2_state.layer2_action = 4w0x2;
 }

    action layer2_nop()
 {
  direct_counter_layer2.count();
  layer2_state.layer2_action = 4w0x0;
 }

    action layer2_nop_mirror(MirrorId_t igr_ses)
 {
  direct_counter_layer2.count();
  layer2_state.layer2_action = 4w0x5;
  layer2_state.igr_ses = igr_ses;
 }


    action layer2_to_port(bit<9> port) {
  direct_counter_layer2.count();
  layer2_state.oport = port;
  layer2_state.layer2_action = 4w0x1;
    }

    action layer2_to_port_mirror(bit<9> port,MirrorId_t igr_ses) {
  direct_counter_layer2.count();
  layer2_state.oport = port;
  layer2_state.layer2_action = 4w0x4;
  layer2_state.igr_ses = igr_ses;
    }


 action layer2_drop(){
  direct_counter_layer2.count();
  layer2_state.layer2_action = 4w0x3;
    }

 action layer2_drop_mirror(MirrorId_t igr_ses){
  direct_counter_layer2.count();
  layer2_state.layer2_action = 4w0x6;
  layer2_state.igr_ses = igr_ses;
    }

 /**
	*  Table for learning layer2 headers seen by port
	*/
    table layer2_table {

        key = {
   ig_intr_md.ingress_port: exact;
   hdr.ethernet.dst_addr :exact;
   hdr.ethernet.src_addr :exact;
   hdr.ethernet.ether_type: exact;
   ig_md.vlan_0.vid: exact;
   ig_md.vlan_1.vid: exact;
            ig_md.mpls2.mpls1.mpls0.label: exact;
            ig_md.mpls2.mpls1.label: exact;
            ig_md.mpls2.label: exact;
            ig_md.mpls2.bos: exact;
   ig_md.which_digest: exact;
        }

        actions = {
   layer2_digest;
   layer2_nop;
   layer2_nop_mirror;
   layer2_drop;
   layer2_drop_mirror;
   layer2_to_port;
   layer2_to_port_mirror;
        }
//        size = 200000; //is corrct		
        size = 320000; //is corrct		
        default_action = layer2_nop;//not_hit_layer_table;
  counters = direct_counter_layer2;
    }

 action doPortToPortMirrorLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  ig_md.ing_mir_ses = layer2_state.igr_ses;
  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;
    }

 action doPortToPortLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }


    action doPortToPortDigest() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  ig_dprsr_md.digest_type = ig_md.which_digest;
  hdr.bridge_header.output_group = 0;
    }

    action doPortToPort() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  hdr.bridge_header.output_group = 0;
    }

    action doPortToPortPortMirrorDigest() {
  ig_dprsr_md.digest_type = ig_md.which_digest;
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }

    action doPortToPortPortMirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = port_state.oport;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }

    action doPortToGroupDigest() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  ig_dprsr_md.digest_type = ig_md.which_digest;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;
    }

    action doPortToGroup() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;
    }

    action doPortToGroupPortMirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;
    }

    action doPortToGroupPortMirrorDigest() {
  ig_dprsr_md.digest_type = ig_md.which_digest;
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;
    }

 action doPortToGroupMirrorLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  ig_md.ing_mir_ses = layer2_state.igr_ses;
  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;
    }

 action doPortToGroupLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = group_output_port;
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = (bit<7>)ig_md.port_metadata.output_group;
    }


 action doLayer2ToPortMirrorLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = layer2_state.oport ;
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;
    }

    action doLayer2ToPortLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = layer2_state.oport ;
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }


    action doLayer2ToPort() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = layer2_state.oport ;
  hdr.bridge_header.output_group = 0;
    }

 action doDropMirrorLayer2Mirror() {
  ig_tm_md.ucast_egress_port = 9w0x1ff; // Set the destination port to an invalid value
  ig_dprsr_md.drop_ctl = 0x0; //setting to 1 disables unicast and multicast
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;
    }

 action doDropLayer2Mirror() {
  ig_dprsr_md.drop_ctl = 0x1;
  ig_md.ing_mir_ses = layer2_state.igr_ses;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }

    action doDrop() {
  ig_dprsr_md.drop_ctl = 0x1;
  hdr.bridge_header.output_group = 0;
    }

    action doDropDigest() {
  ig_dprsr_md.digest_type = ig_md.which_digest;
  ig_dprsr_md.drop_ctl = 0x1;
  hdr.bridge_header.output_group = 0;
    }

    action doDropPortMirrorDigest() {
  ig_dprsr_md.digest_type = ig_md.which_digest;

  ig_tm_md.ucast_egress_port = 9w0x1ff; // Set the destination port to an invalid value
  ig_dprsr_md.drop_ctl = 0x0; //setting to 1 disables unicast and multicast
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }

    action doDropPortMirror() {
  ig_tm_md.ucast_egress_port = 9w0x1ff; // Set the destination port to an invalid value
  ig_dprsr_md.drop_ctl = 0x0; //setting to 1 disables unicast and multicast
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
    }

 action doIgnoreToPortPortMirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = ignore_state.oport ;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
 }

 action doIgnoreToPort() {
  ig_tm_md.ucast_egress_port = ignore_state.oport ;
  hdr.bridge_header.output_group = 0;
 }

 action doLayer2ToPortPortMirror() {
  ig_dprsr_md.drop_ctl = 0;
  ig_tm_md.ucast_egress_port = layer2_state.oport ;
  ig_md.ing_mir_ses = port_state.igr_ses;

  ig_tm_md.level2_mcast_hash = (bit<13>)rnd_val;

  ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
  hdr.bridge_header.output_group = 0;
 }

 /**
	*  Table that applys the actions that have been
	*  accumilated 
	*/
    table resolve_table {
        key = {
            port_state.port_action : exact;
            layer2_state.layer2_action : exact;
            ignore_state.ignore_action : ternary;
   port_state.learn_port : ternary;
        }
        actions = { doLayer2ToPort; doPortToPort; doDrop; doDropPortMirror; doIgnoreToPort;doLayer2ToPortPortMirror;doPortToPortPortMirror;doIgnoreToPortPortMirror;doDropLayer2Mirror;doPortToPortLayer2Mirror;doLayer2ToPortLayer2Mirror;doPortToGroup;doPortToGroupPortMirror;doPortToGroupLayer2Mirror; doLayer2ToPortMirrorLayer2Mirror; doPortToPortMirrorLayer2Mirror; doPortToGroupMirrorLayer2Mirror; doDropMirrorLayer2Mirror;doPortToPortDigest;doPortToPortPortMirrorDigest;doPortToGroupDigest;doPortToGroupPortMirrorDigest;doDropDigest;doDropPortMirrorDigest;}
        const default_action = doDrop();
        const entries = {
   //Toport no processing_action
   (3w0x1, 4w0x1, _, _) : doLayer2ToPort();
   (3w0x3, 4w0x1, _, _) : doLayer2ToPortPortMirror();
   (3w0x2, 4w0x1, _, _) : doLayer2ToPort();
   (3w0x4, 4w0x1, _, _) : doLayer2ToPortPortMirror();
   (3w0x5, 4w0x1, _, _) : doLayer2ToPort();
   (3w0x6,4w0x1, _, _) : doLayer2ToPortPortMirror();

   (3w0x1, 4w0x4, _, _) : doLayer2ToPortLayer2Mirror();
   (3w0x3, 4w0x4, _, _) : doLayer2ToPortMirrorLayer2Mirror();//fix doLayer2ToPortPortMirror();
   (3w0x2, 4w0x4, _, _) : doLayer2ToPortLayer2Mirror();
   (3w0x4, 4w0x4, _, _) : doLayer2ToPortMirrorLayer2Mirror();//doLayer2ToPortPortMirror();
   (3w0x5, 4w0x4, _, _) : doLayer2ToPortLayer2Mirror();
   (3w0x6,4w0x4, _, _) : doLayer2ToPortMirrorLayer2Mirror();//doLayer2ToPortPortMirror();



   (3w0x1, 4w0x0, _, _) : doPortToPort();
   (3w0x3, 4w0x0, _, _) : doPortToPortPortMirror();
   (3w0x2, 4w0x0, _, _) : doDrop();
   (3w0x4, 4w0x0, _, _) : doDropPortMirror();
   (3w0x5, 4w0x0, _, _) : doPortToGroup();
   (3w0x6,4w0x0, _, _) : doPortToGroupPortMirror();

   (3w0x1, 4w0x5, _, _) : doPortToPortLayer2Mirror();
   (3w0x3, 4w0x5, _, _) : doPortToPortMirrorLayer2Mirror();//fix doPortToPortPortMirror(LR_DIGEST_NONE);
   (3w0x2, 4w0x5, _, _) : doDropLayer2Mirror();
   (3w0x4, 4w0x5, _, _) : doDropMirrorLayer2Mirror(); //doDropPortMirror(LR_DIGEST_NONE);
   (3w0x5, 4w0x5, _, _) : doPortToGroupLayer2Mirror();
   (3w0x6,4w0x5, _, _) : doPortToGroupMirrorLayer2Mirror();//fix doPortToPortPortMirror(LR_DIGEST_NONE);


   (3w0x1, 4w0x2, 2w0x0 ,0) : doPortToPort();
   (3w0x3, 4w0x2, 2w0x0 ,0) : doPortToPortPortMirror();
   (3w0x2, 4w0x2, 2w0x0 ,0) : doDrop();
   (3w0x4, 4w0x2, 2w0x0 ,0) : doDropPortMirror();
   (3w0x5, 4w0x2, 2w0x0 ,0) : doPortToGroup();
   (3w0x6,4w0x2, 2w0x0 ,0) : doPortToGroupPortMirror(); //30


   (3w0x1, 4w0x2, 2w0x0 ,1) : doPortToPortDigest();
   (3w0x3, 4w0x2, 2w0x0 ,1) : doPortToPortPortMirrorDigest();
   (3w0x2, 4w0x2, 2w0x0 ,1) : doDropDigest();
   (3w0x4, 4w0x2, 2w0x0 ,1) : doDropPortMirrorDigest();
   (3w0x5, 4w0x2, 2w0x0 ,1) : doPortToGroupDigest();
   (3w0x6,4w0x2, 2w0x0 ,1) : doPortToGroupPortMirrorDigest();

   (3w0x1, 4w0x2, 2w0x3, _) : doPortToPort();
   (3w0x3, 4w0x2, 2w0x3, _) : doPortToPortPortMirror();
   (3w0x1, 4w0x2, 2w0x1, _) : doDrop();
   (3w0x3, 4w0x2, 2w0x1, _) : doDropPortMirror();
   (3w0x1, 4w0x2, 2w0x2, _) : doIgnoreToPort();
   (3w0x3, 4w0x2, 2w0x2, _) : doIgnoreToPortPortMirror();
   (3w0x2, 4w0x2, 2w0x3, _) : doDrop();
   (3w0x4, 4w0x2, 2w0x3, _) : doDropPortMirror();
   (3w0x2, 4w0x2, 2w0x1, _) : doDrop();
   (3w0x4, 4w0x2, 2w0x1, _) : doDropPortMirror();
   (3w0x2, 4w0x2, 2w0x2, _) : doIgnoreToPort();
   (3w0x4, 4w0x2, 2w0x2, _) : doIgnoreToPortPortMirror();
   (3w0x5, 4w0x2, 2w0x3, _) : doPortToGroup();
   (3w0x6,4w0x2, 2w0x3, _) : doPortToGroupPortMirror();
   (3w0x5, 4w0x2, 2w0x1, _) : doDrop();
   (3w0x6,4w0x2, 2w0x1, _) : doDropPortMirror();
   (3w0x5, 4w0x2, 2w0x2, _) : doIgnoreToPort();
   (3w0x6,4w0x2, 2w0x2, _) : doIgnoreToPortPortMirror();

   (3w0x1, 4w0x3, _, _) : doDrop();
   (3w0x3, 4w0x3, _, _) : doDropPortMirror();
   (3w0x2, 4w0x3, _, _) : doDrop();
   (3w0x4, 4w0x3, _, _) : doDropPortMirror();
   (3w0x5, 4w0x3, _, _) : doDrop();
   (3w0x6,4w0x3, _, _) : doDropPortMirror();

   (3w0x1, 4w0x6, _, _) : doDropLayer2Mirror();
   (3w0x3, 4w0x6, _, _) : doDropMirrorLayer2Mirror();//fix doDropPortMirror(LR_DIGEST_NONE);
   (3w0x2, 4w0x6, _, _) : doDropLayer2Mirror();
   (3w0x4, 4w0x6, _, _) : doDropMirrorLayer2Mirror();//fix doDropPortMirror(LR_DIGEST_NONE);
   (3w0x5, 4w0x6, _, _) : doDropLayer2Mirror();
   (3w0x6,4w0x6, _, _) : doDropMirrorLayer2Mirror();//fix doDropPortMirror(LR_DIGEST_NONE);
        }
  size = 66;
    }



 /*****
	*  Main function in this program
	*
	*  1) Attach the current port state to this packet, including to learn it port, mirror, default port action
	*  2) Count the packet by input port
	*  4) check to see if valid ethernet header if so
	*     a) Check against the layer2 table
	*     b) Chech against the ignore table
	*  5) resolve the actions 
	*
	* Note even if we can not parse the traffic it will do what
	* the default action on the port is
	*/
    apply {
  port_rules_table.apply(); //set the default action for the packet, get mirror state, get learning layer2 state

  rnd_val = group_rnd.get();
  output_group_table.apply();

  if (ig_prsr_md.parser_err != PARSER_ERROR_OK)
  {
   parse_error_port_counter.count(ig_intr_md.ingress_port);
   parse_error_type_counter.count(ig_prsr_md.parser_err);
  }

  //needs to be on the top of all track the input port
  port_counter.count(ig_intr_md.ingress_port); //count the packet


        if (hdr.ethernet.isValid())
        {
   layer2_table.apply();
   ignore_stack.apply();
  }

  resolve_table.apply();
    }
}
# 6 "/mnt/p4c-5298/pac_route/PAC_Route_main.p4" 2

Pipeline(PAC_Route_IngressParser(),
         PAC_Route_Ingress(),
         PAC_Route_IngressDeparser(),
         PAC_Route_EgressParser(),
         PAC_Route_Egress(),
         PAC_Route_EgressDeparser()) PAC_Route_Profile;



Switch(PAC_Route_Profile) main;
