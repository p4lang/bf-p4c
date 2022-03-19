#include <core.p4>
#include <tna.p4>

/*************************************************************************

*********************** H E A D E R S  ***********************************

*************************************************************************/

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> plength;
    bit<16> checksum;
}

@flexible
header resubmit_h {
    PortId_t port_id; // 9 bits - uses 16 bit container
    bit<48> _pad2;
}

/* Local metadata */

struct hash_metadata_t {
    bit<104> flowId;
    bit<10> s1Index;
    bit<10> s2Index;
    bit<32> mKeyCarried;
    bit<32> mKey;
    bit<32> mCountCarried;
    bit<32> hash_flowId_s1;
    bit<32> hash_flowId_s2;
    bit<32> count_s2;
    bit<32> FlowTrackerID;
    bit<13> FlowIndex;
    bit<104> FlowTrackerId;
    bit<32> flowTrackId;
    //bit<32>     IngressTS;
    bit<16> VTS2;
    bit<16> IPGc_com;
    bit<16> Diff;
    bit<32> Diff_2;
    bit<32> Diff_3;
    bit<32> VirtualClk;
    bit<16> IPGc;
    bit<16> IPGccc;
    bit<32> IPGc_2;
    bit<32> IPGc_3;

    bit<48> TS;
    bit<48> TS_1;
    bit<48> TS_2;
    bit<48> TS_3;
    bit<48> rTS;
    bit<8> FL_3;
    bit<8> TS_msb_fl1;
    bit<16> TS_lsb;
    bit<16> TS_lsb1;
    bit<32> Current_TS;
    bit<32> Current_TS_2;
    bit<32> Current_TS_3;
    bit<32> Last_TS;
    bit<32> Last_TS_2;
    bit<32> Last_TS_3;
    bit<16> TS_last;
    bit<16> TS_current;
    bit<8> FL;
    bit<8> FL1;
    bit<8> IPG_w_flag;
    bit<8> IPG_w_flag_2;
    bit<8> IPG_w_flag_3;
    bit<16> IPG_w1;
    bit<16> IPG_w2;
    bit<8> FlowTrackerFlag;

    //bit<48>  test16;
    //bit<48>  test18;
    //bit<13>  Index;
    bit<1> IPGflag;

    //bit<8> TS_ub;

    bit<16> TS_last_new;

    //bit<8> TS_ub_new;
    bit<16> TS_lb_last;
    bit<8> TS_ub_last;

    bit<16> TS_lb_last_2;
    bit<8> TS_ub_last_2;

    //bit<16> TS_lb_last_3;
    //bit<8>  TS_ub_last_3;

    //bit<8> IPGc_tmp;
    bit<8> IPGc_tmp_2;
    bit<8> IPGc_tmp;
    bit<16> IPGc_tmp_ttt;
    //bit<8> IPGc_tmp_3;
      bit<32> IPGc_tmp_t;


}

struct header_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    tcp_t tcp;
}


struct ingress_metadata_t {

    hash_metadata_t hash_meta;
    resubmit_h resubmit_data;

}

struct egress_metadata_t {

}


const bit<16> ETHERTYPE_ARP = 0x0806;
const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

const bit<8> IPPROTO_ICMP = 0x01;
const bit<8> IPPROTO_IPv4 = 0x04;
const bit<8> IPPROTO_TCP = 0x06;
const bit<8> IPPROTO_UDP = 0x11;

const bit<16> ARP_HTYPE_ETHERNET = 0x0001;
const bit<16> ARP_PTYPE_IPV4 = 0x0800;
const bit<8> ARP_HLEN_ETHERNET = 6;
const bit<8> ARP_PLEN_IPV4 = 4;
const bit<16> ARP_OPER_REQUEST = 1;
const bit<16> ARP_OPER_REPLY = 2;

const bit<8> ICMP_ECHO_REQUEST = 8;
const bit<8> ICMP_ECHO_REPLY = 0;

const bit<16> GTP_UDP_PORT = 2152;
const bit<16> UDP_PORT_VXLAN = 4789;

const bit<32> MAC_LEARN_RECEIVER = 1;
const bit<32> ARP_LEARN_RECEIVER = 1025;

typedef bit<9> port_t;
//const port_t port = 136;
const port_t port = 129;
const port_t CPU_PORT = 255;

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
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




       //pkt.advance(64);
       pkt.advance(PORT_METADATA_SIZE);

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

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(
        packet_in packet,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

   state start {
        packet.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        packet.extract(ig_md.resubmit_data);
        transition parse_ethernet;
    }

    state parse_port_metadata {
        packet.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

   state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

   state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IPPROTO_UDP : parse_udp;
            IPPROTO_TCP : parse_tcp;
            default : accept;
        }
    }

   state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

   state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
       }
  }


// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------

control SwitchIngressDeparser(
        packet_out packet,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Resubmit() resubmit;

    apply {

        if (ig_dprsr_md.resubmit_type == 1) {
            resubmit.emit();
        } else if (ig_dprsr_md.resubmit_type == 2) {
            resubmit.emit(ig_md.resubmit_data);
        }

        /*packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);*/

        packet.emit(hdr);
  }
}

// ---------------------------------------------------------------------------
// Egress Parser
// ---------------------------------------------------------------------------

parser SwitchEgressParser(
        packet_in packet,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

  TofinoEgressParser() tofino_parser;

 state start {
        tofino_parser.apply(packet, eg_intr_md);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out packet,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
       //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;

    apply {

    }

}


control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

        bit<13> mIndex;

        /*********** Math Unit Functions ******************************/

        MathUnit<bit<16>>(MathOp_t.MUL, 1, 512) right_shift_by_9;

        /****** Register definition ***********************************/

        Register <bit<32>, _> (32w8192) rFlowTracker ;
        Register <bit<16>, _> (32w8192) rIPG_w ;
        Register <bit<16>, _> (32w8192) rTS ;
        Register <bit<8>, _> (32w8192) rFL ;
        Register <bit<1>, _> (32w8192) rIPGflag ;

        /******** Only for computation *******************************/

        Register <bit<32>, _> (32w1) rIPGcCal ;

       /******** Flow ID extraction ***********************************/

        action extract_flow_id () {

             meta.hash_meta.flowId[31:0] = hdr.ipv4.srcAddr ;
             meta.hash_meta.flowId[63:32] = hdr.ipv4.dstAddr ;
             meta.hash_meta.flowId[71:64] = hdr.ipv4.protocol;
             meta.hash_meta.flowId[87:72] = hdr.tcp.srcPort ;
             meta.hash_meta.flowId[103:88] = hdr.tcp.dstPort ;
       }

       /**********  Calculate Table Index and Set IPG flag for first pkt of a flow ****************/

        Hash<bit<13>>(HashAlgorithm_t.CRC32) hTableIndex;
        Hash<bit<32>>(HashAlgorithm_t.CRC32) hFlowTracker;

        action compute_FlowID() {
            {
            meta.hash_meta.flowTrackId = hFlowTracker.get(meta.hash_meta.flowId);
            }
        }

        /***** Check whether the slot is vacant or not  *****/

        RegisterAction<bit<1>, bit<13>, bit<1>>(rIPGflag) rIPGflag_action = {
              void apply(inout bit<1> value, out bit<1> readvalue){

              readvalue = value;
              value = 1;
            }
        };
        action compute_FlowIndex_and_set_IPGflag() {
            {
             mIndex = hTableIndex.get(meta.hash_meta.flowId);
             meta.hash_meta.IPGflag = rIPGflag_action.execute(mIndex);
            }
        }

       /******************************************************************************************/
       /******* Case I : Insert the new entry when slot is vacant ********************************/
       /******************************************************************************************/

       /**********  Insert new Flow in the hash table ****************/

       RegisterAction<bit<32>, bit<13>, bit<32>>(rFlowTracker) rFlowTracker_action_1 = {
              void apply(inout bit<32> value){
              value = meta.hash_meta.flowTrackId;
          }
       };
       /***************** Set Ingress Timestamp  *********************/

       RegisterAction<bit<16>, bit<13>, bit<16>>(rTS) rTS_action_1 = {
              void apply(inout bit<16> value){
                 value = (bit<16>) (meta.hash_meta.TS[28:19]);
          }
       };

       /***************  Initialized weighted IPG *********************/

       RegisterAction<bit<16>, bit<13>, bit<8>>(rIPG_w) rIPG_w_action_1 = {
              void apply(inout bit<16> value){
                  value = 7000;
          }
       };

       /******************* Compute Flow Length  **********************/

       RegisterAction<bit<8>, bit<13>, bit<8>>(rFL) rFL_action_1 = {
              void apply(inout bit<8> value){
                value = 0;
          }
       };

      /*****************************************************************************************/
      /************************ Common for Case II and Case III  *******************************/
      /*****************************************************************************************/

      RegisterAction<bit<32>, bit<13>, bit<8>>(rFlowTracker) rFlowTracker_action = {
              void apply(inout bit<32> value, out bit<8> readvalue){

              if ( value == meta.hash_meta.flowTrackId ) {
                   readvalue = 0;
              } else {
                   readvalue = 1;}
           }
       };

       /******************************************************************************************/
       /*********************** Case II : Update the existing entry ******************************/
       /******************************************************************************************/

       /************** Ingress Timestamp ********************************/

       RegisterAction<bit<16>, bit<13>, bit<16>>(rTS) rTS_action_2 = {
              void apply(inout bit<16> value, out bit<16> readvalue){
                  bit<16> tmp;
                  if (value > (bit<16>) (meta.hash_meta.TS[28:19])) {
                     tmp = value + 0x8000;
                     readvalue = tmp;
                  } else { tmp = value; readvalue = tmp;}
                  value = (bit<16>) (meta.hash_meta.TS[28:19]);
          }
       };

      RegisterAction<bit<32>, bit<1>, bit<8>>(rIPGcCal) rIPGcCal_action_2 = {
              void apply(inout bit<32> value, out bit<8> readvalue){
                value = 2;
                if (meta.hash_meta.IPGc > 0x80) {
                    readvalue = 1;
                } else { readvalue = 2;}
            }
       };

      /**** Update IPG weighted (approximated calclution) **************/

      RegisterAction<bit<16>, bit<13>, bit<8>>(rIPG_w) rIPG_w_action_1_2 = {
              void apply(inout bit<16> value, out bit<8> readvalue){

                    if (value > 8192){
                        readvalue = 1;}
                    else {readvalue = 2;}
                    value = value + meta.hash_meta.IPGc;
             }
       };

     RegisterAction<bit<16>, bit<13>, bit<8>>(rIPG_w) rIPG_w_action_2_2 = {
              void apply(inout bit<16> value, out bit<8> readvalue){

                    if (value > 8192){
                      readvalue = 1;}
                    else {readvalue = 2;}

                    if (value >= meta.hash_meta.IPGccc) {
                          value = value - right_shift_by_9.execute(value);
                    } else {
                          value = value + meta.hash_meta.IPGc;
                    }
             }
       };
       /***************** Flow Length **************************************/

       RegisterAction<bit<8>, bit<13>, bit<8>>(rFL) rFL_action1_2 = {
              void apply(inout bit<8> value, out bit<8> readvalue){

                   if (value == 12) {
                       value = 0;
                       readvalue = 1;
                    }
                    else {
                       if (meta.hash_meta.IPG_w_flag_2 == 2) {
                            value = value + 1;}
                       readvalue = 2;
                    }
            }
       };
       RegisterAction<bit<8>, bit<13>, bit<8>>(rFL) rFL_action2_2 = {
              void apply(inout bit<8> value, out bit<8> readvalue){
                readvalue = 2;
          }
       };
       /*******************************************************************************************/
       /*************************** Case III ******************************************************/
       /*******************************************************************************************/

      /**** Update IPG weighted (approximated calclution) ************************/

       RegisterAction<bit<16>, bit<13>, bit<8>>(rIPG_w) rIPG_w_action_3 = {
              void apply(inout bit<16> value, out bit<8> readvalue){

                    /* set rate to increase the IPG_w value, different schemes
                       can be to increase the precision */
                    if (value > 10000){
                      readvalue = 1;}
                    else {readvalue = 2;}
                    value = value + right_shift_by_9.execute(value);
            }
       };


      /**********************  Required Actions for Case II  ******************************/

       action computeIPGc_2_1() {
                 meta.hash_meta.IPGc = meta.hash_meta.Diff + meta.hash_meta.TS_current;
       }
       action computeIPGc_2_2() {
                 meta.hash_meta.IPGc = meta.hash_meta.TS_current - meta.hash_meta.TS_last_new;
       }
       action computeTS_current() {
                 meta.hash_meta.TS_current = (bit<16>)(meta.hash_meta.TS[28:19]);
                 meta.hash_meta.TS_last_new = (bit<16>)(meta.hash_meta.TS_last[9:0]);
       }
       action computeTS_last() {
                 meta.hash_meta.TS_last = rTS_action_2.execute(mIndex);
       }
       action check_FT_flag() {
                 meta.hash_meta.FlowTrackerFlag = rFlowTracker_action.execute(mIndex);
       }

     /**************************** Apply *********************************************************************/

      apply {

        if (hdr.tcp.isValid()) {

     /******** Preproecssing for HH detection ************************/

        extract_flow_id() ;
        compute_FlowID() ;
        compute_FlowIndex_and_set_IPGflag() ;
        meta.hash_meta.TS = ig_intr_md.ingress_mac_tstamp ;
        meta.hash_meta.FL = 2 ;

    /************************* Case I *******************************/

      if ( meta.hash_meta.IPGflag == 0 || ig_intr_md.resubmit_flag == 1 ) {

          rFlowTracker_action_1.execute(mIndex);
          rTS_action_1.execute(mIndex);
          rIPG_w_action_1.execute(mIndex);
          rFL_action_1.execute(mIndex);
     }
     else {
          check_FT_flag();

          /****************** Case II  ******************************/

          if (meta.hash_meta.FlowTrackerFlag == 0) {

                  computeTS_last();
                  if (meta.hash_meta.TS_last[15:15] == 0x1) {
                      computeTS_current();
                      meta.hash_meta.Diff = 1024 - meta.hash_meta.TS_last_new;
                      computeIPGc_2_1();
                      meta.hash_meta.IPGc_tmp = rIPGcCal_action_2.execute(0);
                      if (meta.hash_meta.IPGc_tmp == 1) {
                          meta.hash_meta.IPG_w_flag_2 = rIPG_w_action_1_2.execute(mIndex);
                      } else {
                          meta.hash_meta.IPGccc = meta.hash_meta.IPGc << 9;
                          meta.hash_meta.IPG_w_flag_2 = rIPG_w_action_2_2.execute(mIndex);
                      }
                      meta.hash_meta.FL = rFL_action1_2.execute(mIndex);

                  } else {
                      computeTS_current();
                      computeIPGc_2_2();
                      meta.hash_meta.IPGc_tmp = rIPGcCal_action_2.execute(0);
                      if (meta.hash_meta.IPGc_tmp == 1) {
                           meta.hash_meta.IPG_w_flag_2 = rIPG_w_action_1_2.execute(mIndex);
                      } else {
                          meta.hash_meta.IPGccc = meta.hash_meta.IPGc << 9;
                          meta.hash_meta.IPG_w_flag_2 = rIPG_w_action_2_2.execute(mIndex);
                      }
                      meta.hash_meta.FL = rFL_action2_2.execute(mIndex);

                  }

          }
          /******************** Case III *******************************************/
         else {
                  /*** IPGw Calculation  *********************************/

                  meta.hash_meta.IPG_w_flag_3 = rIPG_w_action_3.execute(mIndex);

                  /****** Resubmission pkt *******************************/

                  if (meta.hash_meta.IPG_w_flag_3 == 1) {
                        //meta.resubmit_data.port_id = port;
                        ig_intr_dprsr_md.resubmit_type = 1;
                  }

                  /*******************************************************/
                  }
               }
            }

        /***** For analysis, only HH flows can be forwarded to the output port ********/

        if (ig_intr_dprsr_md.resubmit_type == 0) {
              if (meta.hash_meta.FL == 1) {
                     ig_tm_md.ucast_egress_port = port; }
            }
         }
      }

      /*********************  E G R E S S   P R O C E S S I N G  ********************************************/

      control SwitchEgress(
           inout header_t hdr,
           inout egress_metadata_t meta,
           in egress_intrinsic_metadata_t eg_intr_md,
           in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
           inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
           inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

           apply{ }
      }

     /********************************  S W I T C H  ********************************************************/

      Pipeline(SwitchIngressParser(),
           SwitchIngress(),
           SwitchIngressDeparser(),
           SwitchEgressParser(),
           SwitchEgress(),
           SwitchEgressDeparser()) pipe;


     Switch(pipe) main;


    /************************************* End ************************************************/
