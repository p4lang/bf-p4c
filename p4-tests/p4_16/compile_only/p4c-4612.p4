/* -*- P4_16 -*- */
#include <core.p4>
#include<tna.p4>

/* CONSTANTS */

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_IPV6 = 0x86DD;
const bit<16> TYPE_ARP = 0x806;
const bit<8>  TYPE_TCP  = 6;
const bit<8>  TYPE_UDP  = 17;

#define REGISTER_LENGTH 63488
#define TIMESTAMP_WIDTH 48
#define IDLE_TIMEOUT 5000
#define ACTIVE_TIMEOUT 300000

#ifdef CASE_FIX
#define PULL_FLOW_WIDTH 32
#else
#define PULL_FLOW_WIDTH 8
#endif

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<128> ipv6_addr;

header ethernet_t {
    bit<224> extra_info;
    bit<16>   etherType;
}

header ieee_t {
    macAddr_t addr1;
    macAddr_t addr2;
    macAddr_t addr3;
    macAddr_t addr4;
    bit<16>   ieeeType;

}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    tos;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header ipv6_t {
    bit<4>    version;
    bit<8>    trafficClass;
    bit<20>   flowLabel;
    bit<16>   payloadLen;
    bit<8>    nextHdr;
    bit<8>    hopLimit;
    ipv6_addr srcAddr;
    ipv6_addr dstAddr;
}

header tcp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;

}

header udp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
    }

struct header_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ipv6_t       ipv6;
    tcp_t        tcp;
    udp_t        udp;
    ieee_t       ieee;
    // vlan_tag_t       vlan;
    // arp_rarp_t       arp;
    // arp_rarp_ipv4_t  arp_ipv4;
}

struct metadata_t {
    /* empty */
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
    ip4Addr_t ip1;
    ip4Addr_t ip2;
    bit<32> flowlet_register_index;
    bit<32>  ipcache_index;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> port1;
    bit<16> port2;
    bit<32> out_act1;
    bit<32> curr_time;
    bit<32> last_time;
    bit<32> inactive_duration;
    bit<32> active_start;
    bit<32> active_duration;
    bit<64> total_active;
    bit<32> val;
    bit<1> isForward;
}


struct pair{
    bit<8> first;
    bit<8> second;
}


struct empty_header_t {}

struct empty_metadata_t {}


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/


// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(packet_in packet,
                out header_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {

    state start{
        transition meta_init;
    }

    state meta_init{
        meta = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
        transition ethernet;
    }
    state ethernet {

        packet.extract(hdr.ethernet);

        transition select(hdr.ethernet.etherType){

            TYPE_IPV4: ipv4;
            // ETHERTYPE_VLAN : vlan;
            // ETHERTYPE_ARP : arp;
            default: accept;
        }


    }

    state ipv4 {
        packet.extract(hdr.ipv4);

        transition select(hdr.ipv4.protocol){
            TYPE_TCP: tcp;
            TYPE_UDP: udp;
            default: accept;
        }
    }


    state tcp {
       packet.extract(hdr.tcp);
       transition accept;
    }


    state udp {
    packet.extract(hdr.udp);
    transition accept;
    }
}




// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

//Currently only ipv4

control Compare_Key(inout header_t hdr,
        inout metadata_t meta)
        {

            apply
            {
                    if(hdr.ipv4.isValid())
                    {
                        meta.ip1 = min(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr);
                        meta.ip2 = max(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr);
                    }
                    else
                    {
                        meta.ip1 = 0;
                        meta.ip2 = 0;
                    }

                    if(hdr.tcp.isValid())
                    {
                        meta.port1 = min(hdr.tcp.srcPort, hdr.tcp.dstPort);
                        meta.port2 = max(hdr.tcp.srcPort, hdr.tcp.dstPort);
                    }

                    else if(hdr.udp.isValid())
                    {
                        meta.port1 = min(hdr.udp.srcPort, hdr.udp.dstPort);
                        meta.port2 = max(hdr.udp.srcPort, hdr.udp.dstPort);
                    }
                    else
                    {
                        meta.port1 = 0;
                        meta.port2 = 0;
                    }

                }
        }


control Find_Forward(inout header_t hdr,
        inout metadata_t meta)
        {

            Hash<bit<16>>(HashAlgorithm_t.CRC16) sym_hash;
            Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_1;

            Register<pair, bit<32>>(REGISTER_LENGTH, {8w0,8w0}) flow_cache;

            RegisterAction<pair, bit<32>, bit<1>>(flow_cache) flow_cache_register_action0 = {
                void apply(inout pair flag, out bit<1> isFwd) {
                    if(flag.first == 8w0)
                    {
                        if(flag.second == 8w0)
                        {
                            flag.first = 8w1;
                            isFwd = 1;
                        }
                        else
                        {
                            isFwd = 0;
                        }
                    }
                    else
                    isFwd = 1;
                }
            };

            RegisterAction<pair, bit<32>, bit<1>>(flow_cache) flow_cache_register_action1 = {
                void apply(inout pair flag, out bit<1> isFwd) {
                    if(flag.second == 8w0)
                    {
                        if(flag.first == 8w0)
                        {
                            flag.second = 8w1;
                            isFwd = 1;
                        }
                        else
                        {
                            isFwd = 0;
                        }
                    }
                    else
                    isFwd = 1;
                }
            };


        apply
        {
                    meta.ipcache_index = (bit<32>)sym_hash.get({meta.ip1, meta.ip2});
                    if(meta.ip1 == hdr.ipv4.srcAddr)
                        meta.isForward = flow_cache_register_action0.execute(meta.ipcache_index);
                    else
                        meta.isForward = flow_cache_register_action1.execute(meta.ipcache_index);
		            // // end-of-flow direction


                    // find the register index for this flow
                    if (meta.isForward == 1) {
                            meta.srcAddr = hdr.ipv4.srcAddr;
                            meta.dstAddr = hdr.ipv4.dstAddr;
                            if(hdr.tcp.isValid()){
                            meta.srcPort = hdr.tcp.srcPort;
                            meta.dstPort = hdr.tcp.dstPort;
                            }
                            else if(hdr.udp.isValid()){
                            meta.srcPort = hdr.udp.srcPort;
                            meta.dstPort = hdr.udp.dstPort;
                            }
                            else
                            {
                                meta.srcPort = 0;
                                meta.dstPort = 0;
                            }

                    } else {
                            meta.srcAddr = hdr.ipv4.dstAddr;
                            meta.dstAddr = hdr.ipv4.srcAddr;
                            if(hdr.tcp.isValid()){
                            meta.srcPort = hdr.tcp.dstPort;
                            meta.dstPort = hdr.tcp.srcPort;
                            }
                            else if(hdr.udp.isValid()){
                            meta.srcPort = hdr.udp.dstPort;
                            meta.dstPort = hdr.udp.srcPort;
                            }
                            else
                            {
                                meta.srcPort = 0;
                                meta.dstPort = 0;
                            }
                    }

                    if(hdr.ipv4.isValid())
                    meta.flowlet_register_index = (bit<32>)hash_1.get({meta.ip1, meta.ip2, meta.port1, meta.port2, hdr.ipv4.protocol});
        }

        }

control Simple_Features(inout header_t hdr,
        inout metadata_t meta)
        {
            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) pkt_count;

            RegisterAction<bit<32>, bit<32>, bit<32>>(pkt_count) pkt_count_action = {
                void apply(inout bit<32> n_pkts) {
                    n_pkts = n_pkts + 1;
                }
            };

            Register<bit<8>, bit<32>>(REGISTER_LENGTH, 0) protocols;

            RegisterAction<bit<8>, bit<32>, bit<8>>(protocols) protocols_register_action_ipv4 = {
                void apply(inout bit<8> proto) {
                    proto = hdr.ipv4.protocol;
                }
            };

            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) src_ip;

            RegisterAction<bit<32>, bit<32>, bit<32>>(src_ip) src_ip_register_action_ipv4 = {
                void apply(inout bit<32> sip) {
                    sip = meta.srcAddr;
                }
            };


            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) dst_ip;

            RegisterAction<bit<32>, bit<32>, bit<32>>(dst_ip) dst_ip_register_action_ipv4 = {
                void apply(inout bit<32> dip) {
                    dip = meta.dstAddr;
                }
            };


            Register<bit<16>, bit<16>>(REGISTER_LENGTH, 0) src_port;

            RegisterAction<bit<16>, bit<32>, bit<16>>(src_port) src_port_register_action = {
                void apply(inout bit<16> sport) {
                    sport = meta.srcPort;
                }
            };


            Register<bit<16>, bit<16>>(REGISTER_LENGTH, 0) dst_port;

            RegisterAction<bit<16>, bit<32>, bit<16>>(dst_port) dst_port_register_action = {
                void apply(inout bit<16> dport) {
                    dport = meta.dstPort;
                }
            };

             Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) syn_counter;

            RegisterAction<bit<32>, bit<32>, bit<32>>(syn_counter) syn_counter_register_action = {
                void apply(inout bit<32> scounter) {
                    scounter = scounter + 1;
                }
            };

            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) psh_counter;

            RegisterAction<bit<32>, bit<32>, bit<32>>(psh_counter) psh_counter_register_action = {
                void apply(inout bit<32> pcounter) {
                    pcounter = pcounter + 1;
                }
            };

            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) ack_counter;

            RegisterAction<bit<32>, bit<32>, bit<32>>(ack_counter) ack_counter_register_action = {
                void apply(inout bit<32> acounter) {
                    acounter = acounter + 1;
                }
            };

            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) flow_total_length;

            RegisterAction<bit<32>, bit<32>, bit<32>>(flow_total_length) flow_total_length_register_action_ipv4 = {
                void apply(inout bit<32> ftl) {
                    ftl = ftl + (bit<32>)hdr.ipv4.totalLen;
                }
            };

            apply
            {
                    pkt_count_action.execute(meta.flowlet_register_index);
                    protocols_register_action_ipv4.execute(meta.flowlet_register_index);
                    src_ip_register_action_ipv4.execute(meta.flowlet_register_index);
                    dst_ip_register_action_ipv4.execute(meta.flowlet_register_index);


                    src_port_register_action.execute(meta.flowlet_register_index);
                    dst_port_register_action.execute(meta.flowlet_register_index);
                    flow_total_length_register_action_ipv4.execute(meta.flowlet_register_index);

                    if(hdr.tcp.isValid())
                    {
                        if(hdr.tcp.syn == 1)
                        {
                            syn_counter_register_action.execute(meta.flowlet_register_index);
                        }
                        if(hdr.tcp.psh == 1)
                        {
                            psh_counter_register_action.execute(meta.flowlet_register_index);
                        }
                        if(hdr.tcp.ack == 1)
                        {
                            ack_counter_register_action.execute(meta.flowlet_register_index);
                        }


                    }

            }
        }


control Forward_Features(inout header_t hdr,
        inout metadata_t meta)
        {

            Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) forward_total_length;

            RegisterAction<bit<32>, bit<32>, bit<32>>(forward_total_length) forward_total_length_register_action_ipv4 = {
                void apply(inout bit<32> fwtl) {
                            fwtl = fwtl + (bit<32>)hdr.ipv4.totalLen;
                    }
                };

            Register<bit<16>, bit<16>>(REGISTER_LENGTH, 0) fw_win_byt;

            RegisterAction<bit<16>, bit<32>, bit<16>>(fw_win_byt) fw_win_byt_register_action = {
                void apply(inout bit<16> fwin) {
                    if (fwin == 0) {
                            fwin = hdr.tcp.window;
                    }

                }
            };

            apply
            {


                    if(meta.isForward == 1)
                    {
                        forward_total_length_register_action_ipv4.execute(meta.flowlet_register_index);
                        if(hdr.tcp.isValid())
                        {
                            fw_win_byt_register_action.execute(meta.flowlet_register_index);
                        }
                    }


            }
    }

control Time_Features(inout header_t hdr,
inout metadata_t meta, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md)
{

    //msbs
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) flow_start_time_stamp;

    RegisterAction<bit<32>, bit<32>, bit<32>>(flow_start_time_stamp) flow_start_time_stamp_register_action = {
        void apply(inout bit<32> fst, out bit<32> flts) {
            if(fst == 0) {
                    @in_hash{fst = meta.curr_time;}
            }
            flts = fst;
        }
    };

    //msbs of last time stamp
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) last_time_stamp;

    RegisterAction<bit<32>, bit<32>, bit<32>>(last_time_stamp) last_time_stamp_register_action = {
        void apply(inout bit<32> lts, out bit<32> ltd) {
            if(lts == 0) {
                    @in_hash{lts = meta.curr_time;}
                    ltd = lts;
            }
            else{
            ltd = lts;
            lts = meta.curr_time;
            }
        }
    };

    //msbs of active start time stamp
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) active_start_time_stamp;

    RegisterAction<bit<32>, bit<32>, bit<32>>(active_start_time_stamp) active_start_time_stamp_register_action = {
        void apply(inout bit<32> ast, out bit<32> alts) {
            if(ast == 0) {
                    @in_hash{ast = meta.curr_time;}
                    alts = ast;
            }
            else if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                alts = ast;
                ast = meta.curr_time;

            }
            else
            {
                alts = ast;
            }
        }
    };


    // //msbs of flow duration
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) flow_duration;

    RegisterAction<bit<32>, bit<32>, bit<32>>(flow_duration) flow_duration_register_action = {
        void apply(inout bit<32> fd1) {
            @in_hash{fd1 = (bit<32>)meta.val[31:3];}
        }
    };

    // //msbs
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) active_min;

    RegisterAction<bit<32>, bit<32>, bit<32>>(active_min) active_min_register_action = {
        void apply(inout bit<32> am) {
            if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                if(am == 0)
                {
                    am = meta.active_duration;
                }
                else
                {
                    am = min(am, meta.active_duration);
                }
            }
        }
    };

    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) flow_inter_time;

    RegisterAction<bit<32>, bit<32>, bit<32>>(flow_inter_time) flow_inter_time_register_action = {
        void apply(inout bit<32> fit) {
            if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                if(fit == 0)
                {
                    fit = meta.inactive_duration;
                }
                else
                {
                    fit = min(fit, meta.inactive_duration);
                }
            }
        }
    };

    // active mean
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) active_mean;

    RegisterAction<bit<32>, bit<32>, bit<32>>(active_mean) active_mean_register_action = {
        void apply(inout bit<32> am) {
            if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                if(am == 0)
                {
                    am = meta.active_duration;
                }
                else
                {
                    am = am + meta.active_duration;
                }
            }
        }
    };

    // Active segments
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) active_segs;

    RegisterAction<bit<32>, bit<32>, bit<32>>(active_segs) active_segs_register_action = {
        void apply(inout bit<32> as) {
            if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                as = as + 1;
            }
        }
    };

    // subflow fwd bytes
    Register<bit<32>, bit<32>>(REGISTER_LENGTH, 0) subflow_fwd_bytes;

    RegisterAction<bit<32>, bit<32>, bit<32>>(subflow_fwd_bytes) subflow_fwd_bytes_register_action = {
        void apply(inout bit<32> sfb) {
            if(meta.inactive_duration > IDLE_TIMEOUT)
            {
                sfb = sfb + (bit<32>)hdr.ipv4.totalLen;
            }
        }
    };

    // pull_flow
    Register<bit<PULL_FLOW_WIDTH>, bit<32>>(REGISTER_LENGTH, 0) pull_flow;

    RegisterAction<bit<PULL_FLOW_WIDTH>, bit<32>, bit<PULL_FLOW_WIDTH>>(pull_flow) pull_flow_register_action = {
        void apply(inout bit<PULL_FLOW_WIDTH> pf) {
            bool pull = meta.inactive_duration > IDLE_TIMEOUT || meta.active_duration > ACTIVE_TIMEOUT;
            if(pull)
            {
                pf = 1;
            }
            else
            {
                pf = 0;
            }
        }
    };


    apply
    {
        meta.curr_time = (bit<32>)ig_prsr_md.global_tstamp[28:0];

        //msbs
        meta.out_act1 = flow_start_time_stamp_register_action.execute(meta.flowlet_register_index);


        meta.val = meta.curr_time - meta.out_act1;

        flow_duration_register_action.execute(meta.flowlet_register_index);
        meta.last_time = last_time_stamp_register_action.execute(meta.flowlet_register_index);

        meta.inactive_duration = meta.curr_time - meta.last_time;

        meta.active_start = active_start_time_stamp_register_action.execute(meta.flowlet_register_index);

        meta.active_duration = meta.last_time - meta.active_start;

        active_min_register_action.execute(meta.flowlet_register_index);

        flow_inter_time_register_action.execute(meta.flowlet_register_index);

        active_mean_register_action.execute(meta.flowlet_register_index);

        active_segs_register_action.execute(meta.flowlet_register_index);

        if(meta.isForward == 1)
        subflow_fwd_bytes_register_action.execute(meta.flowlet_register_index);

        pull_flow_register_action.execute(meta.flowlet_register_index);


    }
}


control SwitchIngress(inout header_t hdr,
inout metadata_t meta,
in ingress_intrinsic_metadata_t ig_intr_md,
in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    Compare_Key() comp_key;
    Find_Forward() find_fwd;
    Simple_Features() simple_feats;
    Forward_Features() fwd_feats;
    Time_Features() time_feats;

    apply
    {
        comp_key.apply(hdr, meta);
        find_fwd.apply(hdr, meta);
        simple_feats.apply(hdr, meta);
        fwd_feats.apply(hdr, meta);
        time_feats.apply(hdr, meta, ig_prsr_md);
    }
}



/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
