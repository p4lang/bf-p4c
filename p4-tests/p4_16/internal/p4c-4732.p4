/*
* Copyright 2020-present Nehal Baganal
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

enum bit<16> ether_type_t {
    IPV4 = 0x0800,
    ARP = 0x0806,
    TPID = 0x8100,
    IPV6 = 0x86DD,
    MPLS = 0x8847,
    RECIR = 0xEEEE
}

enum bit<8> ip_proto_t {
    TCP = 6,
    ICMP = 1,
    UDP =  17
}

header ethernet_h {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  diffserv;
    bit<2>  ECN;
    bit<16> total_len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    // bit<8> flags;
    bit<1> CWR;
    bit<1> ECE;
    bit<1> URG;
    bit<1> ACK;
    bit<1> PSH;
    bit<1> RST;
    bit<1> SYN;
    bit<1> FIN;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header tcp_opt_h {
    bit<32> data;
}

typedef tcp_opt_h[10] tcp_opt_t;

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

header icmp_h {
    bit<16> type_code;
    bit<16> checksum;
}

header my_recirculate_t {
    bit<1> recir_bit;
    bit<7> dummy;
}

header my_tstamp_t {
    bit<8> ece_flag; //To indicate that payload has ECE timestamp
    bit<8> cwr_flag; //To indicate that payload has CWR timestamp
    bit<16> cwr_tstamp_high;
    bit<32> cwr_tstamp_low;
    bit<16> ece_tstamp_high;
    bit<32> ece_tstamp_low;
    bit<32> queue_delay;
}


struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    tcp_opt_h[10] tcp_opt;
    icmp_h icmp;
    udp_h udp;
    my_tstamp_t my_tstamp;
    my_recirculate_t my_recirculate;
}

header bridged_metadata_t {
    bit<48> ingress_tstamp;
    bit<9> ingress_port;
    bit<7> dummy;
    bit<1> len_cal;
    bit<7> dummy1;
    bit<16> temp_tcp_checksum_1;
}

struct my_metadata_t {
    bridged_metadata_t bridged_metadata;
    bit<16> temp_tcp_checksum_1;
    bit<16> temp_tcp_checksum_2;
}

#define SOJOURN_TARGET          5000000  //in nsec
#define CONTROL_INTERVAL      100000000 //in nsec

typedef bit<8> data_t;
typedef bit<9> box_num_t;

struct register_operations {
    bit<32>     val1;
    bit<32>     val2;
}

struct codel_metadata_t{
    bit<32> egress_tstamp;
    bit<32> queue_delay;
    bit<32> sojourn_remainder;
    bit<1>  sojourn_violation;
    bit<1>  first_sojourn_violation;
    bit<1>  codel_drop;
    bit<8>  rev_ece_temp;
    bit<8>  test;
    bit<1>  test1;
    bit<1>  temp_ECE;
    bit<8>  temp_ece_flag;
    bit<16> temp_tstamp_high;
    bit<32> temp_tstamp_low;
    bit<8>  temp_flag;
    bit<8>  cwr_flag;
    bit<16> cwr_tstamp_high;
    bit<32> cwr_tstamp_low;
}

control CoDelEgress(
    in bit<48> ingress_tstamp,
    in bit<48> egress_tstamp,
    in bit<9> egress_port,
    in bit<9> ingress_port,
    inout headers_t hdr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    codel_metadata_t codel_metadata;

    /******** Register to store ECE data*******/
    Register<data_t, box_num_t>(32w512) data_storage;
    RegisterAction<data_t, box_num_t, data_t>(data_storage) store_data = {
        void apply(inout data_t register_data) {
            register_data = codel_metadata.test;
        }
    };

    RegisterAction<data_t, box_num_t, data_t>(data_storage) read_data = {
        void apply(inout data_t register_data, out data_t result) {
            result = register_data;
            //register_data = 8w0x0;
        }
    };


    /********ECE Flag*******/

    Register< bit<8>, bit<9> > (32w512) ece_flag_state;
    RegisterAction<bit<8>, bit<9>, bit<8> >(ece_flag_state) read_ece_flag_state = {
        void apply(inout bit<8> flag_state, out bit<8> flag_result){
            flag_result = flag_state;
            flag_state = 8w0x0;
        }
    };

    RegisterAction<bit<8>, bit<9>, bit<8> >(ece_flag_state) write_ece_flag_state = {
        void apply(inout bit<8> flag_state) {
            flag_state = codel_metadata.temp_ece_flag;
        }
    };
    /******End of ECE Flag***************/



    /********ECE Time Stamp High*******/

    Register< bit<16>, bit<9> > (32w512) ece_tstamp_high;
    RegisterAction<bit<16>, bit<9>, bit<16> >(ece_tstamp_high) read_ece_tstamp_high = {
        void apply(inout bit<16> tstamp_high, out bit<16> tstamp_high_result){
            tstamp_high_result = tstamp_high;
            tstamp_high = 16w0x0;
        }
    };

    RegisterAction<bit<16>, bit<9>, bit<16> >(ece_tstamp_high) write_ece_tstamp_high = {
        void apply(inout bit<16> tstamp_high) {
            tstamp_high = codel_metadata.temp_tstamp_high;
        }
    };
    /******End of ECE Time Stamp HIgh***************/

    /********ECE Time Stamp Low*******/
    Register< bit<32>, bit<9> > (32w512) ece_tstamp_low;
    RegisterAction<bit<32>, bit<9>, bit<32> >(ece_tstamp_low) read_ece_tstamp_low = {
        void apply(inout bit<32> tstamp_low, out bit<32> tstamp_low_result){
            tstamp_low_result = tstamp_low;
            tstamp_low = 32w0x0;
        }
    };

    RegisterAction<bit<32>, bit<9>, bit<32> >(ece_tstamp_low) write_ece_tstamp_low = {
        void apply(inout bit<32> tstamp_low) {
            tstamp_low = codel_metadata.temp_tstamp_low;
        }
    };
    /******End of ECE Time stamp Low***************/


    /********CWR Flag*******/
    Register< bit<8>, bit<9> > (32w512) cwr_flag_state;
    RegisterAction<bit<8>, bit<9>, bit<8> >(cwr_flag_state) read_cwr_flag_state = {
        void apply(inout bit<8> flag_state, out bit<8> flag_result){
            flag_result = flag_state;
            flag_state = 8w0x0;
        }
    };

    RegisterAction<bit<8>, bit<9>, bit<8> >(cwr_flag_state) write_cwr_flag_state = {
        void apply(inout bit<8> flag_state) {
            flag_state = codel_metadata.temp_flag;
        }
    };
    /******End of CWR Flag***************/


    /********CWR Time Stamp High*******/
    Register< bit<16>, bit<9> > (32w512) cwr_tstamp_high;
    RegisterAction<bit<16>, bit<9>, bit<16> >(cwr_tstamp_high) read_cwr_tstamp_high = {
        void apply(inout bit<16> tstamp_high, out bit<16> tstamp_high_result){
            tstamp_high_result = tstamp_high;
            tstamp_high = 16w0x0;
        }
    };

    RegisterAction<bit<16>, bit<9>, bit<16> >(cwr_tstamp_high) write_cwr_tstamp_high = {
        void apply(inout bit<16> tstamp_high) {
            tstamp_high = codel_metadata.temp_tstamp_high;
        }
    };
    /******End of CWR Time Stamp HIgh***************/

    /********CWR Time Stamp Low*******/
    Register< bit<32>, bit<9> > (32w512) cwr_tstamp_low;
    RegisterAction<bit<32>, bit<9>, bit<32> >(cwr_tstamp_low) read_cwr_tstamp_low = {
        void apply(inout bit<32> tstamp_low, out bit<32> tstamp_low_result){
            tstamp_low_result = tstamp_low;
            tstamp_low = 32w0x0;
        }
    };

    RegisterAction<bit<32>, bit<9>, bit<32> >(cwr_tstamp_low) write_cwr_tstamp_low = {
        void apply(inout bit<32> tstamp_low) {
            tstamp_low = codel_metadata.temp_tstamp_low;
        }
    };
    /******End of CWR Time stamp Low***************/



    //Stateful ALU1
    Register< bit<32>, bit<9> > (32w512) codel_drop_state;
    RegisterAction<bit<32>, bit<9>, bit<1> >(codel_drop_state) codel_drop_state_action = {
        void apply(inout bit<32> drop_state, out bit<1> first_soujourn_violation){
            if (drop_state== 32w0x0  && codel_metadata.sojourn_violation == 1w0x1){
                first_soujourn_violation = 1w0x1;
            } else {
                first_soujourn_violation = 1w0x0;
            }
            if (codel_metadata.sojourn_violation == 1w0x1){
                drop_state = 32w0x1;
            } else {
                drop_state = 32w0x0;
            }
        }
    };

    //Stateful ALU2
    MathUnit< bit<32> > (true, -1, 20, {
            0x46, 0x48, 0x4b, 0x4e,
            0x52, 0x56, 0x5a, 0x60,
            0x66, 0x6f, 0x79, 0x87,
            0x0, 0x0, 0x0, 0x0
        }) sqrtn;

    Register< register_operations, bit<9>> (32w512) codel_salu_2;
    RegisterAction<register_operations, bit<9>, bit<1> >(codel_salu_2) codel_salu_2_action = {
        void apply(inout register_operations inout_vals, out bit<1> out_val){
            //val2 == drop count
            //val1 == next_drop_time
            out_val = 1w0x0;
            if(codel_metadata.first_sojourn_violation == 1w0x1){
                inout_vals.val1 = codel_metadata.egress_tstamp + CONTROL_INTERVAL;
                inout_vals.val2 = 1;
            } else
            if (codel_metadata.egress_tstamp > inout_vals.val1) {
                //we want to drop
                inout_vals.val2 = inout_vals.val2 + 1;
                inout_vals.val1 = inout_vals.val1  + sqrtn.execute(inout_vals.val2);
                out_val = 1w0x1;
            }
        }
    };

    action a_compute_remainder(){
        codel_metadata.sojourn_remainder = SOJOURN_TARGET |-| codel_metadata.queue_delay;
    }

    table t_compute_remainder {
        actions = {
            a_compute_remainder;
        }
        default_action = a_compute_remainder;
    }

    action a_drop(){
        eg_intr_md_for_dprsr.drop_ctl = 3w0x1;
    }
#ifdef CASE_FIX_1
    action set_temp_1() {
                // a_drop();
                codel_metadata.test = 1;
                codel_metadata.temp_flag = 1;
                codel_metadata.temp_tstamp_high = egress_tstamp[47:32];
                codel_metadata.temp_tstamp_low = egress_tstamp[31:0];
    }

    action set_temp_2() {
                // a_drop();
                codel_metadata.test = 0;
                codel_metadata.temp_flag = 1;
                codel_metadata.temp_tstamp_high = ingress_tstamp[47:32];
                codel_metadata.temp_tstamp_low = ingress_tstamp[31:0];
    }
#endif
    apply{
        codel_metadata.egress_tstamp           = 0;
        codel_metadata.queue_delay             = 0;
        codel_metadata.first_sojourn_violation = 0;
        codel_metadata.sojourn_remainder       = 0;
        codel_metadata.sojourn_violation       = 0;
        codel_metadata.codel_drop              = 0;
        codel_metadata.test                    = 0;
        codel_metadata.test1                   = 0;

        if (hdr.ethernet.etherType == ether_type_t.IPV4) {
            // default value, otherwise the value is undefined
            // in case of "non dropping" and everything can happen
            eg_intr_md_for_dprsr.drop_ctl = 3w0x0;

            codel_metadata.egress_tstamp = (bit<32>) egress_tstamp;
            codel_metadata.queue_delay   = (bit<32>)(egress_tstamp - ingress_tstamp);

            t_compute_remainder.apply();

            if (codel_metadata.sojourn_remainder == 0){
                codel_metadata.sojourn_violation = 1;
            } else {
                codel_metadata.sojourn_violation = 0;
            }

            codel_metadata.first_sojourn_violation =
                                    codel_drop_state_action.execute(egress_port);
            codel_metadata.codel_drop = codel_salu_2_action.execute(egress_port);

            if ((codel_metadata.codel_drop == 1) &&
                (codel_metadata.sojourn_violation == 1))
            {
#if defined(CASE_FIX_1)
                set_temp_1();
                store_data.execute(egress_port); // Write register
                write_ece_flag_state.execute(egress_port);
                write_ece_tstamp_high.execute(egress_port);
                write_ece_tstamp_low.execute(egress_port);
#else
                // a_drop();
                codel_metadata.test = 1;
                store_data.execute(egress_port); // Write register

                codel_metadata.temp_flag = 1;
                write_ece_flag_state.execute(egress_port);

                codel_metadata.temp_tstamp_high = egress_tstamp[47:32];
                write_ece_tstamp_high.execute(egress_port);

                codel_metadata.temp_tstamp_low = egress_tstamp[31:0];
                write_ece_tstamp_low.execute(egress_port);
#endif
            } else if (hdr.tcp.CWR==1 && hdr.tcp.SYN != 1) {
#if defined(CASE_FIX_1)
                set_temp_2();
                store_data.execute(egress_port); // Write register
                write_ece_flag_state.execute(egress_port);
                write_ece_tstamp_high.execute(egress_port);
                write_ece_tstamp_low.execute(egress_port);
#else
                codel_metadata.test = 0;
                store_data.execute(egress_port); //Write to register

                codel_metadata.temp_flag = 1;
                write_cwr_flag_state.execute(egress_port);

                codel_metadata.temp_tstamp_high = ingress_tstamp[47:32];
                write_cwr_tstamp_high.execute(egress_port);

                codel_metadata.temp_tstamp_low = ingress_tstamp[31:0];
                write_cwr_tstamp_low.execute(egress_port);
#endif
            }
        } else {
            codel_metadata.temp_ECE = (bit<1>)read_data.execute(ingress_port);
            if (codel_metadata.temp_ECE == 1) {
                hdr.tcp.ECE = 1;
            }

            codel_metadata.temp_flag = read_cwr_flag_state.execute(egress_port);

            if (codel_metadata.temp_flag == 1) {
                if(hdr.my_tstamp.isValid()) {
                    hdr.my_tstamp.cwr_flag = 1;
                    hdr.my_tstamp.cwr_tstamp_high = read_cwr_tstamp_high.execute(egress_port);
                    hdr.my_tstamp.cwr_tstamp_low = read_cwr_tstamp_low.execute(egress_port);
                }
            } else {
                if(hdr.my_tstamp.isValid()) {
                    hdr.my_tstamp.cwr_flag =0;
                    hdr.my_tstamp.cwr_tstamp_high = 0;
                    hdr.my_tstamp.cwr_tstamp_low = 0;
                }
            }

            codel_metadata.temp_flag = read_ece_flag_state.execute(egress_port);

            if (codel_metadata.temp_flag == 1) {
                if(hdr.my_tstamp.isValid()) {
                    hdr.my_tstamp.ece_flag = 1;
                    hdr.my_tstamp.ece_tstamp_high = read_ece_tstamp_high.execute(egress_port);
                    hdr.my_tstamp.ece_tstamp_low = read_ece_tstamp_low.execute(egress_port);
                }
            } else {
                if(hdr.my_tstamp.isValid()) {
                    hdr.my_tstamp.ece_flag =0;
                    hdr.my_tstamp.ece_tstamp_high = 0;
                    hdr.my_tstamp.ece_tstamp_low = 0;
                }
            }

            hdr.ethernet.etherType = ether_type_t.IPV4;
        }
    }
}

parser SwitchIngressParser(packet_in packet,
    out headers_t hdr,
    out my_metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ether_type_t.IPV4: parse_ipv4;
            ether_type_t.ARP : accept;
            ether_type_t.RECIR : parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol, hdr.ipv4.ihl){
            (0, ip_proto_t.ICMP, 5) : parse_icmp;
            (0, ip_proto_t.TCP, 5) : parse_tcp;
            (0, ip_proto_t.UDP, 5) : parse_udp;
            ( _, _, _ ) : accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition select(hdr.tcp.data_offset){
            4w0x5: parse_tcp_no_opt;
            4w0x6: parse_tcp_opt_32b;
            4w0x7: parse_tcp_opt_64b;
            4w0x8: parse_tcp_opt_96b;
            4w0x9: parse_tcp_opt_128b;
            4w0xA: parse_tcp_opt_160b;
            4w0xB: parse_tcp_opt_192b;
            4w0xC: parse_tcp_opt_224b;
            4w0xD: parse_tcp_opt_256b;
            4w0xE: parse_tcp_opt_288b;
            4w0xF: parse_tcp_opt_320b;
            default: accept;
        }
    }

    state parse_tcp_no_opt {
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_32b {
        packet.extract(hdr.tcp_opt[0]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_64b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_96b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_128b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_160b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_192b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_224b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_256b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_288b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        transition parse_my_tstamp;
    }

    state parse_tcp_opt_320b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        packet.extract(hdr.tcp_opt[9]);
        transition parse_my_tstamp;
    }

    state parse_my_tstamp {
        transition accept;
    }

    state parse_icmp {
        packet.extract(hdr.icmp);
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

control SwitchIngress(
    inout headers_t hdr,
    inout my_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_parser_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
{
    action send(bit<9> egress_port) {
        ig_intr_tm_md.ucast_egress_port = egress_port;
    }

    action recirculate() {
        ig_intr_tm_md.ucast_egress_port = 68;
    }

    action send_ether(bit<9> egress_port) {
        ig_intr_tm_md.ucast_egress_port = egress_port;
    }

    table t_l1_forwarding {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send;
        }
        size = 64;
    }

    table ether_forwarding {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            send_ether;
        }
        size = 64;
    }

    apply {
        if (hdr.ethernet.etherType != 0x0800) {
            ether_forwarding.apply();
        } else {
            if (ig_intr_md.ingress_port != 68) {
                hdr.ethernet.etherType = 0xEEEE;
            }

            if (hdr.ethernet.etherType == 0xEEEE) {
                recirculate();
            } else {
                t_l1_forwarding.apply();
            }
        }

        meta.bridged_metadata.setValid();
        meta.bridged_metadata.ingress_tstamp = ig_intr_parser_md.global_tstamp;
        meta.bridged_metadata.ingress_port = ig_intr_md.ingress_port;

        if (hdr.ipv4.total_len[9:0] > 500) {
            meta.bridged_metadata.len_cal = 1;
        }
    }
}

control SwitchIngressDeparser(packet_out packet,
    inout headers_t hdr,
    in my_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        packet.emit(meta.bridged_metadata);
        packet.emit(hdr);
    }
}

parser SwitchEgressParser(packet_in packet,
    out headers_t hdr,
    out my_metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    Checksum() tcp_checksum;
    Checksum() tcp_checksum_1;

    state start {
        packet.extract(eg_intr_md);
        packet.extract(meta.bridged_metadata);
        transition parse_ethernet;
    }

    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ether_type_t.IPV4: parse_ipv4;
            ether_type_t.ARP : accept;
            ether_type_t.RECIR : parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, 8w0, hdr.ipv4.protocol});
        tcp_checksum_1.subtract({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, 8w0, hdr.ipv4.protocol});
        transition parse_tcp;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        tcp_checksum.subtract({hdr.tcp.CWR});
        tcp_checksum.subtract({hdr.tcp.ECE});
        tcp_checksum.subtract({hdr.tcp.URG});
        tcp_checksum.subtract({hdr.tcp.ACK});
        tcp_checksum.subtract({hdr.tcp.PSH});
        tcp_checksum.subtract({hdr.tcp.RST});
        tcp_checksum.subtract({hdr.tcp.SYN});
        tcp_checksum.subtract({hdr.tcp.FIN});
        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract_all_and_deposit(meta.temp_tcp_checksum_1);

        tcp_checksum_1.subtract({hdr.tcp.CWR});
        tcp_checksum_1.subtract({hdr.tcp.ECE});
        tcp_checksum_1.subtract({hdr.tcp.URG});
        tcp_checksum_1.subtract({hdr.tcp.ACK});
        tcp_checksum_1.subtract({hdr.tcp.PSH});
        tcp_checksum_1.subtract({hdr.tcp.RST});
        tcp_checksum_1.subtract({hdr.tcp.SYN});
        tcp_checksum_1.subtract({hdr.tcp.FIN});
        tcp_checksum_1.subtract({hdr.tcp.checksum});

        transition select(hdr.tcp.data_offset){
            4w0x5: parse_tcp_no_opt;
            4w0x6: parse_tcp_opt_32b;
            4w0x7: parse_tcp_opt_64b;
            4w0x8: parse_tcp_opt_96b;
            4w0x9: parse_tcp_opt_128b;
            4w0xA: parse_tcp_opt_160b;
            4w0xB: parse_tcp_opt_192b;
            4w0xC: parse_tcp_opt_224b;
            4w0xD: parse_tcp_opt_256b;
            4w0xE: parse_tcp_opt_288b;
            4w0xF: parse_tcp_opt_320b;
            default: accept;
        }
    }

    state parse_tcp_no_opt {
        transition parse_decide_payload;
    }

    state parse_tcp_opt_32b {
        packet.extract(hdr.tcp_opt[0]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_64b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_96b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_128b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_160b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_192b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_224b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_256b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_288b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        transition parse_decide_payload;
    }

    state parse_tcp_opt_320b {
        packet.extract(hdr.tcp_opt[0]);
        packet.extract(hdr.tcp_opt[1]);
        packet.extract(hdr.tcp_opt[2]);
        packet.extract(hdr.tcp_opt[3]);
        packet.extract(hdr.tcp_opt[4]);
        packet.extract(hdr.tcp_opt[5]);
        packet.extract(hdr.tcp_opt[6]);
        packet.extract(hdr.tcp_opt[7]);
        packet.extract(hdr.tcp_opt[8]);
        packet.extract(hdr.tcp_opt[9]);
        transition parse_decide_payload;
    }

    state parse_decide_payload {
        transition select(meta.bridged_metadata.len_cal){
            1:parse_payload;
            _ : parse_no_payload;
        }
    }

    state parse_no_payload {
        transition accept;
    }

    state parse_payload {
        packet.extract(hdr.my_tstamp);
        tcp_checksum_1.subtract({
                hdr.my_tstamp.cwr_flag,
                hdr.my_tstamp.ece_flag,
                hdr.my_tstamp.cwr_tstamp_high,
                hdr.my_tstamp.cwr_tstamp_low,
                hdr.my_tstamp.ece_tstamp_high,
                hdr.my_tstamp.ece_tstamp_low,
                hdr.my_tstamp.queue_delay
            });
        tcp_checksum_1.subtract_all_and_deposit(meta.temp_tcp_checksum_2);
        transition accept;
    }
}



control SwitchEgress(
    inout headers_t hdr,
    inout my_metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_parser_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    CoDelEgress() codel_egress;

    apply{
        codel_egress.apply(
            meta.bridged_metadata.ingress_tstamp,
            eg_intr_parser_md.global_tstamp,
            eg_intr_md.egress_port,
            meta.bridged_metadata.ingress_port,
            hdr,
            eg_intr_md_for_dprsr);

        hdr.my_tstamp.cwr_tstamp_high = meta.temp_tcp_checksum_1;
    }
}

control SwitchEgressDeparser(packet_out packet,
    inout headers_t hdr,
    in my_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() tcp_checksum_1;

    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.diffserv,
                    hdr.ipv4.ECN,
                    hdr.ipv4.total_len,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.frag_offset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr
                });
        }

        if (hdr.my_tstamp.isValid()) {
            hdr.tcp.checksum = tcp_checksum_1.update({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    8w0,
                    hdr.ipv4.protocol,
                    8w0,
                    hdr.tcp.CWR,
                    hdr.tcp.ECE,
                    hdr.tcp.URG,
                    hdr.tcp.ACK,
                    hdr.tcp.PSH,
                    hdr.tcp.RST,
                    hdr.tcp.SYN,
                    hdr.tcp.FIN,
                    hdr.my_tstamp.cwr_flag,
                    hdr.my_tstamp.ece_flag,
                    hdr.my_tstamp.cwr_tstamp_high,
                    hdr.my_tstamp.cwr_tstamp_low,
                    hdr.my_tstamp.ece_tstamp_high,
                    hdr.my_tstamp.ece_tstamp_low,
                    hdr.my_tstamp.queue_delay,
                    meta.temp_tcp_checksum_2
                });
        } else {
            hdr.tcp.checksum = tcp_checksum.update({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    8w0,
                    hdr.ipv4.protocol,
                    8w0,
                    hdr.tcp.CWR,
                    hdr.tcp.ECE,
                    hdr.tcp.URG,
                    hdr.tcp.ACK,
                    hdr.tcp.PSH,
                    hdr.tcp.RST,
                    hdr.tcp.SYN,
                    hdr.tcp.FIN,
                    meta.temp_tcp_checksum_1});
        }
        packet.emit(hdr);
    }
}

Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
