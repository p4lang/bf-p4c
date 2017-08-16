/*
gcc -E -x c -w -I/home/yiorgos/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib -D__TARGET_TOFINO__ -DINT_TRANSIT_PLT_WITH_MCAST_PROFILE -DTUNNEL_DISABLE -DTUNNEL_OVER_IPV6_DISABLE -I/usr/local/lib/python2.7/dist-packages/p4_hlir-0.9.60-py2.7.egg/p4_hlir/p4_lib /home/yiorgos/p4factory/submodules/switch/p4src/switch.p4
*/
#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
#include "tofino/pktgen_headers.p4"
#include "tofino/stateful_alu_blackbox.p4"




header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type llc_header_t {
    fields {
        dsap : 8;
        ssap : 8;
        control_ : 8;
    }
}

header_type snap_header_t {
    fields {
        oui : 24;
        type_ : 16;
    }
}

header_type roce_header_t {
    fields {
        ib_grh : 320;
        ib_bth : 96;
    }
}

header_type roce_v2_header_t {
    fields {
        ib_bth : 96;
    }
}

header_type fcoe_header_t {
    fields {
        version : 4;
        type_ : 4;
        sof : 8;
        rsvd1 : 32;
        ts_upper : 32;
        ts_lower : 32;
        size_ : 32;
        eof : 8;
        rsvd2 : 24;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type ieee802_1ah_t {
    fields {
        pcp : 3;
        dei : 1;
        uca : 1;
        reserved : 3;
        i_sid : 24;
    }
}

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;



    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type sctp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        verifTag : 32;
        checksum : 32;
    }
}

header_type gre_t {
    fields {
        C : 1;
        R : 1;
        K : 1;
        S : 1;
        s : 1;
        recurse : 3;
        flags : 5;
        ver : 3;
        proto : 16;
    }
}

header_type nvgre_t {
    fields {
        tni : 24;
        flow_id : 8;
    }
}


header_type erspan_header_t3_t {
    fields {
        version : 4;
        vlan : 12;
        priority : 6;
        span_id : 10;
        timestamp : 32;
        sgt : 16;
        ft_d_other: 16;
    }
}



header_type erspan_platform_subheader_t {
    fields {

        mirror_on_drop : 32;
        switch_id : 32;
    }
}


header_type ipsec_esp_t {
    fields {
        spi : 32;
        seqNo : 32;
   }
}

header_type ipsec_ah_t {
    fields {
        nextHdr : 8;
        length_ : 8;
        zero : 16;
        spi : 32;
        seqNo : 32;
    }
}

header_type arp_rarp_t {
    fields {
        hwType : 16;
        protoType : 16;
        hwAddrLen : 8;
        protoAddrLen : 8;
        opcode : 16;
    }
}

header_type arp_rarp_ipv4_t {
    fields {
        srcHwAddr : 48;
        srcProtoAddr : 32;
        dstHwAddr : 48;
        dstProtoAddr : 32;
    }
}

header_type eompls_t {
    fields {
        zero : 4;
        reserved : 12;
        seqNo : 16;
    }
}

header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

header_type vxlan_gpe_t {
    fields {
        flags : 8;
        reserved : 16;
        next_proto : 8;
        vni : 24;
        reserved2 : 8;
    }
}

header_type nsh_t {
    fields {
        oam : 1;
        context : 1;
        flags : 6;
        reserved : 8;
        protoType: 16;
        spath : 24;
        sindex : 8;
    }
}

header_type nsh_context_t {
    fields {
        network_platform : 32;
        network_shared : 32;
        service_platform : 32;
        service_shared : 32;
    }
}

header_type vxlan_gpe_int_header_t {
    fields {
        int_type : 8;
        rsvd : 8;
        len : 8;
        next_proto : 8;
    }
}




header_type genv_t {
    fields {
        ver : 2;
        optLen : 6;
        oam : 1;
        critical : 1;
        reserved : 6;
        protoType : 16;
        vni : 24;
        reserved2 : 8;
    }
}





header_type genv_opt_A_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 32;
    }
}




header_type genv_opt_B_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 64;
    }
}




header_type genv_opt_C_t {
    fields {
        optClass : 16;
        optType : 8;
        reserved : 3;
        optLen : 5;
        data : 32;
    }
}

header_type trill_t {
    fields {
        version : 2;
        reserved : 2;
        multiDestination : 1;
        optLength : 5;
        hopCount : 6;
        egressRbridge : 16;
        ingressRbridge : 16;
    }
}

header_type lisp_t {
    fields {
        flags : 8;
        nonce : 24;
        lsbsInstanceId : 32;
    }
}

header_type vntag_t {
    fields {
        direction : 1;
        pointer : 1;
        destVif : 14;
        looped : 1;
        reserved : 1;
        version : 2;
        srcVif : 12;
    }
}

header_type bfd_t {
    fields {
        version : 3;
        diag : 5;
        state_flags : 8;
        detectMult : 8;
        len : 8;
        myDiscriminator : 32;
        yourDiscriminator : 32;
        desiredMinTxInterval : 32;
        requiredMinRxInterval : 32;
        requiredMinEchoRxInterval : 32;
    }
}

header_type sflow_hdr_t {
    fields {
        version : 32;
        addrType : 32;
        ipAddress : 32;
        subAgentId : 32;
        seqNumber : 32;
        uptime : 32;
        numSamples : 32;
    }
}

header_type sflow_sample_t {
    fields {
        enterprise : 20;
        format : 12;
        sampleLength : 32;
        seqNumer : 32;
        srcIdType : 8;
        srcIdIndex : 24;
        samplingRate : 32;
        samplePool : 32;
        numDrops : 32;
        inputIfindex : 32;
        outputIfindex : 32;
        numFlowRecords : 32;
    }
}

header_type sflow_raw_hdr_record_t {

    fields {
        enterprise : 20;
        format : 12;
        flowDataLength_hi : 16;
        flowDataLength : 16;
        headerProtocol : 32;
        frameLength_hi : 16;
        frameLength : 16;
        bytesRemoved_hi : 16;
        bytesRemoved : 16;
        headerSize_hi : 16;
        headerSize : 16;
    }
}


header_type sflow_sample_cpu_t {
    fields {
        sampleLength : 16;
        samplePool : 32;
        inputIfindex : 16;
        outputIfindex : 16;
        numFlowRecords : 8;
        sflow_session_id : 3;
        pipe_id : 2;
    }
}
header_type fabric_header_t {
    fields {
        packetType : 3;
        headerVersion : 2;
        packetVersion : 2;
        pad1 : 1;

        fabricColor : 3;
        fabricQos : 5;

        dstDevice : 8;
        dstPortOrGroup : 16;
    }
}

header_type fabric_header_unicast_t {
    fields {
        routed : 1;
        outerRouted : 1;
        tunnelTerminate : 1;
        ingressTunnelType : 5;

        nexthopIndex : 16;
    }
}

header_type fabric_header_multicast_t {
    fields {
        routed : 1;
        outerRouted : 1;
        tunnelTerminate : 1;
        ingressTunnelType : 5;

        ingressIfindex : 16;
        ingressBd : 16;

        mcastGrpA : 16;
        mcastGrpB : 16;
        ingressRid : 16;
        l1ExclusionId : 16;
    }
}

header_type fabric_header_mirror_t {
    fields {
        rewriteIndex : 16;
        egressPort : 10;
        egressQueue : 5;
        pad : 1;
    }
}

header_type fabric_header_cpu_t {
    fields {
        egressQueue : 5;
        txBypass : 1;
        reserved : 2;

        ingressPort: 16;
        ingressIfindex : 16;
        ingressBd : 16;

        reasonCode : 16;
    }
}

header_type fabric_header_sflow_t {
    fields {
        sflow_session_id : 16;
    }
}

header_type fabric_header_bfd_event_t {
    fields {
        bfd_session_id : 16;
        bfd_event_id : 16;
    }
}

header_type fabric_payload_header_t {
    fields {
        etherType : 16;
    }
}


header_type int_plt_header_t {
    fields {
        pl_encoding : 32;
    }
}


header_type int_header_t {
    fields {
        ver : 2;
        rep : 2;
        c : 1;
        e : 1;
        rsvd1 : 5;
        ins_cnt : 5;
        max_hop_cnt : 8;
        total_hop_cnt : 8;
        instruction_mask_0003 : 4;
        instruction_mask_0407 : 4;
        instruction_mask_0811 : 4;
        instruction_mask_1215 : 4;
        rsvd2 : 16;
    }
}

header_type int_switch_id_header_t {
    fields {
        bos : 1;
        switch_id : 31;
    }
}
header_type int_port_ids_header_t {
    fields {
        bos : 1;
        pad_1 : 6;
        ingress_port_id : 9;
        egress_port_id : 16;
    }
}
header_type int_ingress_port_id_header_t {
    fields {
        bos : 1;
        ingress_port_id_1 : 15;
        ingress_port_id_0 : 16;
    }
}
header_type int_hop_latency_header_t {
    fields {
        bos : 1;
        hop_latency : 31;
    }
}
header_type int_q_occupancy_header_t {
    fields {
        bos : 1;
        q_occupancy1 : 7;
        q_occupancy0 : 24;
    }
}
header_type int_ingress_tstamp_header_t {
    fields {
        bos : 1;
        ingress_tstamp : 31;
    }
}
header_type int_egress_port_id_header_t {
    fields {
        bos : 1;
        egress_port_id : 31;
    }
}
header_type int_q_congestion_header_t {
    fields {
        bos : 1;
        q_congestion : 31;
    }
}
header_type int_egress_port_tx_utilization_header_t {
    fields {
        bos : 1;
        egress_port_tx_utilization : 31;
    }
}


header_type int_value_t {
    fields {
        bos : 1;
        val : 31;
    }
}

header_type intl45_head_header_t {
    fields {
        int_type :8;
        rsvd0 :8;
        len :8;
        rsvd1 :8;
    }
}

header_type intl45_tail_header_t {
    fields {
        next_proto :8;
        proto_param :16;
        rsvd :8;
    }
}


header_type ipv6_srh_t {
    fields {
        nextHdr : 8;
        hdrExtLen : 8;
        routingType : 8;
        segLeft : 8;
        firstSeg : 8;
        flags : 16;
        reserved : 8;
    }
}

header_type ipv6_srh_segment_t {
    fields {
        sid : 128;
    }
}
parser start {
    return select(current(96, 16)) {



        default : parse_ethernet;
    }
}
header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;
        0x9000 : parse_fabric_header;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

header llc_header_t llc_header;

parser parse_llc_header {
    extract(llc_header);
    return select(llc_header.dsap, llc_header.ssap) {
        0xAAAA : parse_snap_header;
        0xFEFE : parse_set_prio_med;
        default: ingress;
    }
}

header snap_header_t snap_header;

parser parse_snap_header {
    extract(snap_header);
    return select(latest.type_) {
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

header roce_header_t roce;

parser parse_roce {
    extract(roce);
    return ingress;
}

header fcoe_header_t fcoe;

parser parse_fcoe {
    extract(fcoe);
    return ingress;
}


header vlan_tag_t vlan_tag_[2];

parser parse_vlan {
    extract(vlan_tag_[0]);
    return select(latest.etherType) {
        0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}

parser parse_qinq {
    extract(vlan_tag_[0]);
    return select(latest.etherType) {
        0x8100 : parse_qinq_vlan;
        default : ingress;
    }
}

parser parse_qinq_vlan {
    extract(vlan_tag_[1]);
    return select(latest.etherType) {
        0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}



header mpls_t mpls[3];


parser parse_mpls {
    return ingress;

}

parser parse_mpls_bos {
    return select(current(0, 4)) {




        default: parse_eompls;
    }

}

parser parse_mpls_udp {
    set_metadata(tunnel_metadata.mpls_in_udp, 1);
    return parse_mpls;
}

parser parse_mpls_inner_ipv4 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv4;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv6;
}

parser parse_vpls {
    return ingress;
}

parser parse_pw {
    return ingress;
}
@pragma pa_fragment ingress ipv4.hdrChecksum
@pragma pa_fragment egress ipv4.hdrChecksum
header ipv4_t ipv4;

field_list ipv4_checksum_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum {

    verify ipv4_checksum;
    update ipv4_checksum;




}
parser parse_ipv4 {

    extract(ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        0x501 : parse_icmp;
        0x506 : parse_tcp;
        0x511 : parse_udp;

        0x52f : parse_gre;





        2 : parse_set_prio_med;
        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_ipv4_in_ip {
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 3);
    return parse_inner_ipv4;
}

parser parse_ipv6_in_ip {
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 3);
    return parse_inner_ipv6;
}
header ipv6_t ipv6;

parser parse_udp_v6 {
    extract(udp);
    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);
    return select(latest.dstPort) {
        67 : parse_set_prio_med;
        68 : parse_set_prio_med;
        546 : parse_set_prio_med;
        547 : parse_set_prio_med;
        520 : parse_set_prio_med;
        521 : parse_set_prio_med;
        1985 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_gre_v6 {
    extract(gre);
    return select(latest.C, latest.R, latest.K, latest.S, latest.s,
                  latest.recurse, latest.flags, latest.ver, latest.proto) {
        0x0800 : parse_gre_ipv4;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        58 : parse_icmp;
        6 : parse_tcp;
        4 : parse_ipv4_in_ip;
        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;

        default: ingress;
    }
}
header icmp_t icmp;

parser parse_icmp {
    extract(icmp);
    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.typeCode);
    return select(latest.typeCode) {

        0x8200 mask 0xfe00 : parse_set_prio_med;
        0x8400 mask 0xfc00 : parse_set_prio_med;
        0x8800 mask 0xff00 : parse_set_prio_med;
        default: ingress;
    }
}




@pragma pa_fragment egress tcp.checksum
@pragma pa_fragment egress tcp.urgentPtr
header tcp_t tcp;
parser parse_tcp {
    extract(tcp);
    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);
    return select(latest.dstPort) {
        179 : parse_set_prio_med;
        639 : parse_set_prio_med;
        default: ingress;
    }
}

header roce_v2_header_t roce_v2;

parser parse_roce_v2 {
    extract(roce_v2);
    return ingress;
}




header udp_t udp;
parser parse_udp {
    extract(udp);
    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_outer_l4_dport, latest.dstPort);
    return select(latest.dstPort) {
        4790 : parse_vxlan_gpe;





        67 : parse_set_prio_med;
        68 : parse_set_prio_med;
        546 : parse_set_prio_med;
        547 : parse_set_prio_med;
        520 : parse_set_prio_med;
        521 : parse_set_prio_med;
        1985 : parse_set_prio_med;
        6343 : parse_sflow;





        default: ingress;
    }
}

header sctp_t sctp;

parser parse_sctp {
    extract(sctp);
    return ingress;
}




header gre_t gre;

parser parse_gre {
    extract(gre);
    return select(latest.C, latest.R, latest.K, latest.S, latest.s,
                  latest.recurse, latest.flags, latest.ver, latest.proto) {



        0x0800 : parse_gre_ipv4;
        0x86dd : parse_gre_ipv6;
        0x22EB : parse_erspan_t3;



        default: ingress;
    }
}

parser parse_gre_ipv4 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv4;
}

parser parse_gre_ipv6 {
    set_metadata(tunnel_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv6;
}

header nvgre_t nvgre;
header ethernet_t inner_ethernet;


@pragma pa_fragment ingress inner_ipv4.hdrChecksum
@pragma pa_fragment egress inner_ipv4.hdrChecksum
header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;

field_list inner_ipv4_checksum_list {
        inner_ipv4.version;
        inner_ipv4.ihl;
        inner_ipv4.diffserv;
        inner_ipv4.totalLen;
        inner_ipv4.identification;
        inner_ipv4.flags;
        inner_ipv4.fragOffset;
        inner_ipv4.ttl;
        inner_ipv4.protocol;
        inner_ipv4.srcAddr;
        inner_ipv4.dstAddr;
}

field_list_calculation inner_ipv4_checksum {
    input {
        inner_ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field inner_ipv4.hdrChecksum {

    verify inner_ipv4_checksum;
    update inner_ipv4_checksum;




}

header udp_t outer_udp;

parser parse_nvgre {
    extract(nvgre);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 5);
    set_metadata(tunnel_metadata.tunnel_vni, latest.tni);
    return parse_inner_ethernet;
}

header erspan_header_t3_t erspan_t3_header;

parser parse_erspan_t3 {
    extract(erspan_t3_header);
    return select(latest.ft_d_other) {
        0 mask 0x7c01: parse_inner_ethernet;
    0x800 mask 0x7c01: parse_inner_ipv4;


    0x3C01 mask 0x7c01: parse_mirror_on_drop_ethernet;
        default : ingress;
    }
}



field_list mirror_on_drop_list {
    ingress_metadata.platform_id;
    ingress_metadata.drop_reason;
    ingress_metadata.ingress_port;
    egress_metadata.egress_port;
}

field_list_calculation calc_mirror_on_drop {
    input {
        mirror_on_drop_list;
    }
    algorithm : identity;
    output_width : 32;
}

@pragma pa_atomic egress erspan_platform_subheader.mirror_on_drop
@pragma pa_solitary egress erspan_platform_subheader.mirror_on_drop
@pragma pa_atomic egress erspan_platform_subheader.switch_id
@pragma pa_solitary egress erspan_platform_subheader.switch_id
header erspan_platform_subheader_t erspan_platform_subheader;

parser parse_mirror_on_drop_ethernet {
    extract(erspan_platform_subheader);
    return parse_inner_ethernet;
}

parser parse_mirror_on_drop_ipv4 {
    extract(erspan_platform_subheader);
    return parse_inner_ipv4;
}


parser parse_arp_rarp {
    return parse_set_prio_med;
}

header eompls_t eompls;

parser parse_eompls {

    set_metadata(tunnel_metadata.ingress_tunnel_type, 6);
    return parse_inner_ethernet;
}

header vxlan_t vxlan;

parser parse_vxlan {
    extract(vxlan);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 1);
    set_metadata(tunnel_metadata.tunnel_vni, latest.vni);
    return parse_inner_ethernet;
}


header vxlan_gpe_t vxlan_gpe;

parser parse_vxlan_gpe {
    extract(vxlan_gpe);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 12);
    set_metadata(tunnel_metadata.tunnel_vni, latest.vni);

    return select(vxlan_gpe.flags, vxlan_gpe.next_proto)



    {
        0x0805 mask 0x08ff : parse_int_vxlan_header;
        default : parse_inner_ethernet;
    }
}


header genv_t genv;

parser parse_geneve {
    extract(genv);
    set_metadata(tunnel_metadata.tunnel_vni, latest.vni);
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 4);
    return select(genv.ver, genv.optLen, genv.protoType) {
        0x6558 : parse_inner_ethernet;
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
        default : ingress;
    }
}

header nsh_t nsh;
header nsh_context_t nsh_context;

parser parse_nsh {
    extract(nsh);
    extract(nsh_context);
    return select(nsh.protoType) {
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
        0x6558 : parse_inner_ethernet;
        default : ingress;
    }
}

header lisp_t lisp;

parser parse_lisp {
    extract(lisp);
    return select(current(0, 4)) {
        0x4 : parse_inner_ipv4;
        0x6 : parse_inner_ipv6;
        default : ingress;
    }
}
parser parse_inner_ipv4 {

    extract(inner_ipv4);
    set_metadata(ipv4_metadata.lkp_ipv4_sa, latest.srcAddr);
    set_metadata(ipv4_metadata.lkp_ipv4_da, latest.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, latest.protocol);
    set_metadata(l3_metadata.lkp_ip_ttl, latest.ttl);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        0x501 : parse_inner_icmp;
        0x506 : parse_inner_tcp;
        0x511 : parse_inner_udp;
        default: ingress;
    }
}

header icmp_t inner_icmp;

parser parse_inner_icmp {
    extract(inner_icmp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.typeCode);
    return ingress;
}



@pragma pa_alias egress inner_tcp tcp



@pragma pa_fragment egress inner_tcp.checksum
@pragma pa_fragment egress inner_tcp.urgentPtr
header tcp_t inner_tcp;

parser parse_inner_tcp {
    extract(inner_tcp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return ingress;
}




header udp_t inner_udp;
parser parse_inner_udp {
    extract(inner_udp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return ingress;
}

header sctp_t inner_sctp;

parser parse_inner_sctp {
    extract(inner_sctp);
    return ingress;
}

parser parse_inner_ipv6 {
    extract(inner_ipv6);






    return select(latest.nextHdr) {
        58 : parse_inner_icmp;
        6 : parse_inner_tcp;
        17 : parse_inner_udp;
        default: ingress;
    }
}

parser parse_inner_ethernet {
    extract(inner_ethernet);
    set_metadata(l2_metadata.lkp_mac_sa, latest.srcAddr);
    set_metadata(l2_metadata.lkp_mac_da, latest.dstAddr);
    return select(latest.etherType) {
        0x0800 : parse_inner_ipv4;



        default: ingress;
    }
}

header trill_t trill;

parser parse_trill {
    extract(trill);
    return parse_inner_ethernet;
}

header vntag_t vntag;

parser parse_vntag {
    extract(vntag);
    return parse_inner_ethernet;
}
header sflow_hdr_t sflow;
header sflow_sample_t sflow_sample;
header sflow_raw_hdr_record_t sflow_raw_hdr_record;

parser parse_sflow {



    return ingress;
}

header fabric_header_t fabric_header;
header fabric_header_unicast_t fabric_header_unicast;
header fabric_header_multicast_t fabric_header_multicast;
header fabric_header_mirror_t fabric_header_mirror;
header fabric_header_cpu_t fabric_header_cpu;
header fabric_header_sflow_t fabric_header_sflow;
header fabric_header_bfd_event_t fabric_header_bfd;
header fabric_payload_header_t fabric_payload_header;

parser parse_fabric_header {
    extract(fabric_header);
    return select(latest.packetType) {





        5 : parse_fabric_header_cpu;
        default : ingress;
    }
}

parser parse_fabric_header_unicast {
    extract(fabric_header_unicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_multicast {
    extract(fabric_header_multicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_mirror {
    extract(fabric_header_mirror);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_cpu {
    extract(fabric_header_cpu);
    set_metadata(ingress_metadata.bypass_lookups, latest.reasonCode);
    return select(latest.reasonCode) {







        default : parse_fabric_payload_header;
    }
}
parser parse_fabric_payload_header {
    extract(fabric_payload_header);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
    }
}
parser parse_set_prio_med {
    set_metadata(ig_prsr_ctrl.priority, 3);
    return ingress;
}

parser parse_set_prio_high {
    set_metadata(ig_prsr_ctrl.priority, 5);
    return ingress;
}

parser parse_set_prio_max {
    set_metadata(ig_prsr_ctrl.priority, 7);
    return ingress;
}
header int_header_t int_header;
header int_switch_id_header_t int_switch_id_header;
header int_port_ids_header_t int_port_ids_header;
header int_ingress_port_id_header_t int_ingress_port_id_header;
header int_hop_latency_header_t int_hop_latency_header;
header int_q_occupancy_header_t int_q_occupancy_header;
header int_ingress_tstamp_header_t int_ingress_tstamp_header;
header int_egress_port_id_header_t int_egress_port_id_header;
header int_q_congestion_header_t int_q_congestion_header;
header int_egress_port_tx_utilization_header_t
    int_egress_port_tx_utilization_header;

@pragma pa_allowed_to_share egress vxlan_gpe_int_header.rsvd vxlan_gpe_int_header.len
header vxlan_gpe_int_header_t vxlan_gpe_int_header;

header int_plt_header_t int_plt_header;
parser parse_plt_int_header {
    extract(int_plt_header);
    return parse_int_header;
}





parser parse_int_vxlan_header {
    extract(vxlan_gpe_int_header);
    return select (latest.int_type) {

        0x03: parse_plt_int_header;

        default: parse_int_header;
    }
}
parser parse_int_header {
    extract(int_header);

    set_metadata(int_metadata.int_hdr_word_len, latest.ins_cnt);
    return select (latest.rsvd1, latest.total_hop_cnt) {


        0x000 mask 0xfff: ingress;





        0 mask 0: ingress;

        default: parse_all_int_meta_value_heders;
    }
}
parser parse_all_int_meta_value_heders {



    extract(int_switch_id_header);
    extract(int_port_ids_header);
    extract(int_hop_latency_header);
    extract(int_q_occupancy_header);



    return ingress;

}

@pragma pa_alias ingress ig_intr_md.ingress_port ingress_metadata.ingress_port


header_type ingress_metadata_t {
    fields {
        ingress_port : 9;
        ifindex : 16;
        egress_ifindex : 16;
        port_type : 2;

        outer_bd : 16;
        bd : 16;

        drop_flag : 1;
        drop_reason : 8;

        platform_id : 6;

        control_frame: 1;
        sflow_take_sample : 32 (saturating);
        bypass_lookups : 16;
    }
}

header_type egress_metadata_t {
    fields {
        bypass : 1;
        port_type : 2;
        payload_length : 16;
        smac_idx : 9;
        bd : 16;
        outer_bd : 16;
        mac_da : 48;
        routed : 1;
        same_bd_check : 16;
        drop_reason : 8;
        ifindex : 16;

        egress_port : 9;

    }
}

header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 16;
        lf_field_list : 32;
        egress_rid : 16;
        ingress_global_timestamp : 32;
    }
}


header_type global_config_metadata_t {
    fields {
        enable_dod : 1;
        switch_id : 32;
    }
}





@pragma pa_atomic ingress ingress_metadata.port_type
@pragma pa_solitary ingress ingress_metadata.port_type
@pragma pa_atomic ingress ingress_metadata.ifindex
@pragma pa_solitary ingress ingress_metadata.ifindex
@pragma pa_atomic egress ingress_metadata.bd
@pragma pa_solitary egress ingress_metadata.bd

metadata ingress_metadata_t ingress_metadata;
metadata egress_metadata_t egress_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;
metadata global_config_metadata_t global_config_metadata;

action set_config_parameters(enable_dod, enable_flowlet, switch_id) {
    deflect_on_drop(enable_dod);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);



    modify_field(global_config_metadata.switch_id, switch_id);
}

table switch_config_params {
    actions {
        set_config_parameters;
    }
    size : 1;
}

control process_global_params {

    apply(switch_config_params);
}



action set_valid_outer_unicast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
}

action set_valid_outer_unicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_unicast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_unicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_multicast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
}

action set_valid_outer_multicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_multicast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_multicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_broadcast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
}

action set_valid_outer_broadcast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_broadcast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action set_valid_outer_broadcast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(l2_metadata.lkp_pcp, vlan_tag_[0].pcp);
}

action malformed_outer_ethernet_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

table validate_outer_ethernet {
    reads {
        ethernet.srcAddr : ternary;
        ethernet.dstAddr : ternary;
        vlan_tag_[0] : valid;
        vlan_tag_[1] : valid;
    }
    actions {
        malformed_outer_ethernet_packet;
        set_valid_outer_unicast_packet_untagged;
        set_valid_outer_unicast_packet_single_tagged;
        set_valid_outer_unicast_packet_double_tagged;
        set_valid_outer_unicast_packet_qinq_tagged;
        set_valid_outer_multicast_packet_untagged;
        set_valid_outer_multicast_packet_single_tagged;
        set_valid_outer_multicast_packet_double_tagged;
        set_valid_outer_multicast_packet_qinq_tagged;
        set_valid_outer_broadcast_packet_untagged;
        set_valid_outer_broadcast_packet_single_tagged;
        set_valid_outer_broadcast_packet_double_tagged;
        set_valid_outer_broadcast_packet_qinq_tagged;
    }
    size : 64;
}

control process_validate_outer_header {

    apply(validate_outer_ethernet) {
        malformed_outer_ethernet_packet {
        }
        default {
            if (valid(ipv4)) {
                validate_outer_ipv4_header();
            } else {
                if (valid(ipv6)) {
                    validate_outer_ipv6_header();
                }
            }





        }
    }
}





action set_ifindex(ifindex, port_type) {
    modify_field(ingress_metadata.ifindex, ifindex);
    modify_field(ingress_metadata.port_type, port_type);
}

table ingress_port_mapping {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ifindex;
    }
    size : 288;
}

action set_ingress_port_properties(if_label, exclusion_id,
                                   qos_group, tc_qos_group,
                                   tc, color,
                                   trust_dscp, trust_pcp) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, exclusion_id);
    modify_field(acl_metadata.if_label, if_label);
    modify_field(qos_metadata.ingress_qos_group, qos_group);
    modify_field(qos_metadata.tc_qos_group, tc_qos_group);
    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(meter_metadata.packet_color, color);
    modify_field(qos_metadata.trust_dscp, trust_dscp);
    modify_field(qos_metadata.trust_pcp, trust_pcp);
}

table ingress_port_properties {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ingress_port_properties;
    }
    size : 288;
}

control process_ingress_port_mapping {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_mapping);
    }
    apply(ingress_port_properties);
}





action set_bd_properties(bd, vrf, stp_group, learning_enabled,
                         bd_label, stats_idx, rmac_group,
                         ipv4_unicast_enabled, ipv6_unicast_enabled,
                         ipv4_urpf_mode, ipv6_urpf_mode,
                         igmp_snooping_enabled, mld_snooping_enabled,
                         ipv4_multicast_enabled, ipv6_multicast_enabled,
                         mrpf_group,
                         ipv4_mcast_key, ipv4_mcast_key_type,
                         ipv6_mcast_key, ipv6_mcast_key_type,
                         ingress_rid) {
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(l3_metadata.vrf, vrf);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(multicast_metadata.igmp_snooping_enabled,
                 igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(multicast_metadata.ipv4_multicast_enabled,
                 ipv4_multicast_enabled);
    modify_field(multicast_metadata.ipv6_multicast_enabled,
                 ipv6_multicast_enabled);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv4_mcast_key_type, ipv4_mcast_key_type);
    modify_field(multicast_metadata.ipv4_mcast_key, ipv4_mcast_key);
    modify_field(multicast_metadata.ipv6_mcast_key_type, ipv6_mcast_key_type);
    modify_field(multicast_metadata.ipv6_mcast_key, ipv6_mcast_key);

    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action port_vlan_mapping_miss() {
    modify_field(l2_metadata.port_vlan_mapping_miss, 1);
}

action_profile bd_action_profile {
    actions {
        set_bd_properties;
        port_vlan_mapping_miss;
    }
    size : 16384;
}

table port_vlan_mapping {
    reads {
        ingress_metadata.ifindex : exact;
        vlan_tag_[0] : valid;
        vlan_tag_[0].vid : exact;
        vlan_tag_[1] : valid;
        vlan_tag_[1].vid : exact;
    }

    action_profile: bd_action_profile;
    size : 32768;
}

control process_port_vlan_mapping {
    apply(port_vlan_mapping);

    apply(adjust_lkp_fields);

}






counter ingress_bd_stats {
    type : packets_and_bytes;
    instance_count : 16384;
    min_width : 32;
}

action update_ingress_bd_stats() {
    count(ingress_bd_stats, l2_metadata.bd_stats_idx);
}

table ingress_bd_stats {
    actions {
        update_ingress_bd_stats;
    }
    size : 16384;
}


control process_ingress_bd_stats {

    apply(ingress_bd_stats);

}






field_list lag_hash_fields {
    hash_metadata.hash2;



}

field_list_calculation lag_hash {
    input {
        lag_hash_fields;
    }







    algorithm : identity;
    output_width : 14;

}

action_selector lag_selector {
    selection_key : lag_hash;



    selection_mode : fair;

}
action set_lag_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}


action set_lag_miss() {
}

action_profile lag_action_profile {
    actions {
        set_lag_miss;
        set_lag_port;



    }
    size : 1024;
    dynamic_action_selection : lag_selector;
}

table lag_group {
    reads {
        ingress_metadata.egress_ifindex : exact;
    }
    action_profile: lag_action_profile;
    size : 1024;
}

control process_lag {






        apply(lag_group);



}





action egress_port_type_normal(ifindex, qos_group, if_label) {
    modify_field(egress_metadata.port_type, 0);
    modify_field(egress_metadata.ifindex, ifindex);
    modify_field(qos_metadata.egress_qos_group, qos_group);
    modify_field(acl_metadata.egress_if_label, if_label);
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

action egress_port_type_fabric(ifindex) {
    modify_field(egress_metadata.port_type, 1);
    modify_field(egress_metadata.ifindex, ifindex);
    modify_field(tunnel_metadata.egress_tunnel_type, 15);
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

action egress_port_type_cpu(ifindex) {
    modify_field(egress_metadata.port_type, 2);
    modify_field(egress_metadata.ifindex, ifindex);
    modify_field(tunnel_metadata.egress_tunnel_type, 16);
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

table egress_port_mapping {
    reads {
        eg_intr_md.egress_port : exact;
    }
    actions {
        egress_port_type_normal;
        egress_port_type_fabric;
        egress_port_type_cpu;
    }
    size : 288;
}





action set_egress_packet_vlan_double_tagged(s_tag, c_tag) {
    add_header(vlan_tag_[1]);
    add_header(vlan_tag_[0]);
    modify_field(vlan_tag_[1].etherType, ethernet.etherType);
    modify_field(vlan_tag_[1].vid, c_tag);
    modify_field(vlan_tag_[0].etherType, 0x8100);
    modify_field(vlan_tag_[0].vid, s_tag);
    modify_field(ethernet.etherType, 0x9100);
}

action set_egress_packet_vlan_tagged(vlan_id) {
    add_header(vlan_tag_[0]);
    modify_field(vlan_tag_[0].etherType, ethernet.etherType);
    modify_field(vlan_tag_[0].vid, vlan_id);
    modify_field(ethernet.etherType, 0x8100);
}

action set_egress_packet_vlan_untagged() {
}

table egress_vlan_xlate {
    reads {
        egress_metadata.ifindex: exact;
        egress_metadata.bd : exact;
    }
    actions {
        set_egress_packet_vlan_untagged;
        set_egress_packet_vlan_tagged;
        set_egress_packet_vlan_double_tagged;
    }
    size : 32768;
}

control process_vlan_xlate {
    apply(egress_vlan_xlate);
}
header_type l2_metadata_t {
    fields {
        lkp_mac_sa : 48;
        lkp_mac_da : 48;
        lkp_pkt_type : 3;
        lkp_mac_type : 16;
        lkp_pcp: 3;
        non_ip_packet : 1;

        l2_nexthop : 16;
        l2_nexthop_type : 1;
        l2_redirect : 1;
        l2_src_miss : 1;
        l2_src_move : 16;
        stp_group: 10;
        stp_state : 3;
        bd_stats_idx : 16;
        learning_enabled : 1;
        port_vlan_mapping_miss : 1;
        same_if_check : 16;
    }
}

metadata l2_metadata_t l2_metadata;





action set_stp_state(stp_state) {
    modify_field(l2_metadata.stp_state, stp_state);
}


@pragma ternary 1

table spanning_tree {
    reads {
        ingress_metadata.ifindex : exact;
        l2_metadata.stp_group: exact;
    }
    actions {
        set_stp_state;
    }
    size : 4096;
}


control process_spanning_tree {

    if ((ingress_metadata.port_type == 0) and
        (l2_metadata.stp_group != 0)) {
        apply(spanning_tree);
    }

}





action smac_miss() {
    modify_field(l2_metadata.l2_src_miss, 1);
}

action smac_hit(ifindex) {
    bit_xor(l2_metadata.l2_src_move, ingress_metadata.ifindex, ifindex);
}

table smac {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_mac_sa : exact;
    }
    actions {
        nop;
        smac_miss;
        smac_hit;
    }
    size : 4096;
}




action dmac_hit(ifindex) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);
}

action dmac_multicast_hit(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);



}

action dmac_miss() {
    modify_field(ingress_metadata.egress_ifindex, 65535);



}

action dmac_redirect_nexthop(nexthop_index) {
    modify_field(l2_metadata.l2_redirect, 1);
    modify_field(l2_metadata.l2_nexthop, nexthop_index);
    modify_field(l2_metadata.l2_nexthop_type, 0);
}

action dmac_redirect_ecmp(ecmp_index) {
    modify_field(l2_metadata.l2_redirect, 1);
    modify_field(l2_metadata.l2_nexthop, ecmp_index);
    modify_field(l2_metadata.l2_nexthop_type, 1);
}

action dmac_drop() {
    drop();
}




table dmac {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_mac_da : exact;
    }
    actions {




        nop;
        dmac_hit;
        dmac_multicast_hit;
        dmac_miss;
        dmac_redirect_nexthop;
        dmac_redirect_ecmp;
        dmac_drop;
    }
    size : 4096;
    support_timeout: true;
}


control process_mac {

    if (((ingress_metadata.bypass_lookups & 0x0080) == 0) and
        (ingress_metadata.port_type == 0)) {
        apply(smac);
    }
    if (((ingress_metadata.bypass_lookups & 0x0001) == 0)) {
        apply(dmac);
    }

}





field_list mac_learn_digest {
    ingress_metadata.bd;
    l2_metadata.lkp_mac_sa;
    ingress_metadata.ifindex;
}

action generate_learn_notify() {
    generate_digest(0, mac_learn_digest);
}

table learn_notify {
    reads {
        l2_metadata.l2_src_miss : ternary;
        l2_metadata.l2_src_move : ternary;
        l2_metadata.stp_state : ternary;
    }
    actions {
        nop;
        generate_learn_notify;
    }
    size : 512;
}


control process_mac_learning {

    if (l2_metadata.learning_enabled == 1) {
        apply(learn_notify);
    }

}





action set_unicast() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
}

action set_unicast_and_ipv6_src_is_link_local() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(ipv6_metadata.ipv6_src_is_link_local, 1);
}

action set_multicast() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    add_to_field(l2_metadata.bd_stats_idx, 1);
}

action set_multicast_and_ipv6_src_is_link_local() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(ipv6_metadata.ipv6_src_is_link_local, 1);
    add_to_field(l2_metadata.bd_stats_idx, 1);
}

action set_broadcast() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    add_to_field(l2_metadata.bd_stats_idx, 2);
}

action set_malformed_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

table validate_packet {
    reads {
        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l3_metadata.lkp_ip_type : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
        l3_metadata.lkp_ip_version : ternary;
        tunnel_metadata.tunnel_terminate : ternary;
        inner_ipv4.ihl : ternary;
        ipv4_metadata.lkp_ipv4_sa mask 0xFF000000 : ternary;



    }
    actions {
        nop;
        set_unicast;
        set_unicast_and_ipv6_src_is_link_local;
        set_multicast;
        set_multicast_and_ipv6_src_is_link_local;
        set_broadcast;
        set_malformed_packet;
    }
    size : 64;
}

control process_validate_packet {
    if (((ingress_metadata.bypass_lookups & 0x0040) == 0) and
        (ingress_metadata.drop_flag == 0)) {
        apply(validate_packet);
    }
}






counter egress_bd_stats {
    type : packets_and_bytes;
    direct : egress_bd_stats;
    min_width : 32;
}

table egress_bd_stats {
    reads {
        egress_metadata.bd : exact;
        l2_metadata.lkp_pkt_type: exact;
    }
    actions {
        nop;
    }
    size : 16384;
}


control process_egress_bd_stats {

    apply(egress_bd_stats);

}

action set_egress_bd_properties(smac_idx, mtu_index, nat_mode, bd_label) {
    modify_field(egress_metadata.smac_idx, smac_idx);
    modify_field(nat_metadata.egress_nat_mode, nat_mode);
    modify_field(acl_metadata.egress_bd_label, bd_label);
    modify_field(l3_metadata.mtu_index, mtu_index);
}




table egress_bd_map {
    reads {
        egress_metadata.bd : exact;
    }
    actions {
        nop;
        set_egress_bd_properties;
    }
    size : 16384;
}

control process_egress_bd {
    apply(egress_bd_map);
}




action remove_vlan_single_tagged() {
    modify_field(ethernet.etherType, vlan_tag_[0].etherType);
    remove_header(vlan_tag_[0]);
}

action remove_vlan_double_tagged() {
    modify_field(ethernet.etherType, vlan_tag_[1].etherType);
    remove_header(vlan_tag_[0]);
    remove_header(vlan_tag_[1]);
}

@pragma ternary 1
table vlan_decap {
    reads {
        vlan_tag_[0] : valid;
        vlan_tag_[1] : valid;
    }
    actions {
        nop;
        remove_vlan_single_tagged;
        remove_vlan_double_tagged;
    }
    size: 256;
}

control process_vlan_decap {
    apply(vlan_decap);
}
header_type l3_metadata_t {
    fields {
        lkp_ip_type : 2;
        lkp_ip_version : 4;
        lkp_ip_proto : 8;
        lkp_dscp : 8;
        lkp_ip_ttl : 8;
        lkp_l4_sport : 16;
        lkp_l4_dport : 16;
        lkp_outer_l4_sport : 16;
        lkp_outer_l4_dport : 16;

        vrf : 16;
        rmac_group : 10;
        rmac_hit : 1;
        urpf_mode : 2;
        urpf_hit : 1;
        urpf_check_fail :1;
        urpf_bd_group : 16;
        fib_hit : 1;
        fib_nexthop : 16;
        fib_nexthop_type : 1;
        fib_partition_index : 12;
        same_bd_check : 16;
        nexthop_index : 16;
        routed : 1;
        outer_routed : 1;
        mtu_index : 8;
        l3_copy : 1;
        l3_mtu_check : 16 (saturating);

        egress_l4_sport : 16;
        egress_l4_dport : 16;
    }
}

metadata l3_metadata_t l3_metadata;

@pragma pa_atomic ingress l3_metadata.lkp_ip_version
@pragma pa_solitary ingress l3_metadata.lkp_ip_version




action rmac_hit() {
    modify_field(l3_metadata.rmac_hit, 1);
}

action rmac_miss() {
    modify_field(l3_metadata.rmac_hit, 0);
}




table rmac {
    reads {
        l3_metadata.rmac_group : exact;
        l2_metadata.lkp_mac_da : exact;
    }
    actions {
        rmac_hit;
        rmac_miss;
    }
    size : 512;
}





action fib_hit_nexthop(nexthop_index) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);
}

action fib_hit_ecmp(ecmp_index) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, ecmp_index);
    modify_field(l3_metadata.fib_nexthop_type, 1);
}
control process_urpf_bd {






}





action rewrite_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table smac_rewrite {
    reads {
        egress_metadata.smac_idx : exact;
    }
    actions {
        rewrite_smac;
    }
    size : 512;
}


action ipv4_unicast_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv4.ttl, -1);



}

action ipv4_multicast_rewrite() {
    bit_or(ethernet.dstAddr, ethernet.dstAddr, 0x01005E000000);
    add_to_field(ipv4.ttl, -1);



}

action ipv6_unicast_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv6.hopLimit, -1);



}

action ipv6_multicast_rewrite() {
    bit_or(ethernet.dstAddr, ethernet.dstAddr, 0x333300000000);
    add_to_field(ipv6.hopLimit, -1);



}

action mpls_rewrite() {
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(mpls[0].ttl, -1);
}

table l3_rewrite {
    reads {
        ipv4 : valid;






        ipv4.dstAddr mask 0xF0000000 : ternary;



    }
    actions {
        nop;
        ipv4_unicast_rewrite;

        ipv4_multicast_rewrite;
    }
}

control process_mac_rewrite {

    if (egress_metadata.routed == 1) {
        apply(l3_rewrite);
        apply(smac_rewrite);
    }

}






action ipv4_mtu_check(l3_mtu) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu, ipv4.totalLen);
}

action ipv6_mtu_check(l3_mtu) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu, ipv6.payloadLen);
}

action mtu_miss() {
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

@pragma ternary 1
table mtu {
    reads {
        l3_metadata.mtu_index : exact;
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        mtu_miss;
        ipv4_mtu_check;



    }
    size : 512;
}


control process_mtu {

    apply(mtu);

}
header_type ipv4_metadata_t {
    fields {
        lkp_ipv4_sa : 32;
        lkp_ipv4_da : 32;
        ipv4_unicast_enabled : 1;
        ipv4_urpf_mode : 2;
    }
}

metadata ipv4_metadata_t ipv4_metadata;





action set_valid_outer_ipv4_packet() {
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(l3_metadata.lkp_dscp, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, ipv4.version);
}

action set_malformed_outer_ipv4_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

table validate_outer_ipv4_packet {
    reads {
        ipv4.version : ternary;
        ipv4.ihl: ternary;
        ipv4.ttl : ternary;
        ipv4.srcAddr mask 0xFF000000 : ternary;
    }
    actions {
        set_valid_outer_ipv4_packet;
        set_malformed_outer_ipv4_packet;
    }
    size : 64;
}


control validate_outer_ipv4_header {

    apply(validate_outer_ipv4_packet);

}





table ipv4_fib {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : 4096;
}
@pragma alpm 1
@pragma ways 6
table ipv4_fib_lpm {
    reads {



        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : lpm;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : 16384;
}


control process_ipv4_fib {




    apply(ipv4_fib) {
        on_miss {
            apply(ipv4_fib_lpm);
        }
    }

}
control process_ipv4_urpf {
}
header_type ipv6_metadata_t {
    fields {
        lkp_ipv6_sa : 128;
        lkp_ipv6_da : 128;

        ipv6_unicast_enabled : 1;
        ipv6_src_is_link_local : 1;
        ipv6_urpf_mode : 2;
    }
}
metadata ipv6_metadata_t ipv6_metadata;
control validate_outer_ipv6_header {



}
control process_ipv6_fib {
}
control process_ipv6_urpf {
}
header_type tunnel_metadata_t {
    fields {
        ingress_tunnel_type : 5;
        tunnel_vni : 24;
        mpls_enabled : 1;
        mpls_ttl : 8;
        mpls_exp : 3;
        mpls_in_udp: 1;
        egress_tunnel_type : 5;




        tunnel_index : 14;
        tunnel_dst_index : 14;

        tunnel_src_index : 9;
        tunnel_smac_index : 9;
        tunnel_dmac_index : 14;
        vnid : 24;
        tunnel_lookup : 1;
        tunnel_terminate : 1;
        tunnel_if_check : 1;
        egress_header_count: 4;
        inner_ip_proto : 8;
        src_vtep_hit : 1;



    }
}
metadata tunnel_metadata_t tunnel_metadata;
control process_ipv4_vtep {




}

control process_ipv6_vtep {




}
action ipv4_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, ipv4.ttl);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
    invalidate(ig_intr_md_for_tm.mcast_grp_a);
}

action ipv6_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv6_metadata.lkp_ipv6_sa, ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_ttl, ipv6.hopLimit);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
    invalidate(ig_intr_md_for_tm.mcast_grp_a);
}

action non_ip_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l2_metadata.non_ip_packet, 1);
    invalidate(ig_intr_md_for_tm.mcast_grp_a);
}

table adjust_lkp_fields {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;



    }
}

table tunnel_lookup_miss {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;



    }
}

action tunnel_check_pass() {
}

table tunnel_check {
    reads {
        tunnel_metadata.ingress_tunnel_type : ternary;
        tunnel_metadata.tunnel_lookup : ternary;
        tunnel_metadata.src_vtep_hit : ternary;
    }
    actions {
        nop;
        tunnel_check_pass;
    }
}




control process_tunnel {


    process_ingress_fabric();
}
control validate_mpls_header {



}
control process_tunnel_decap {
}
action inner_ipv4_udp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_udp, udp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(udp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, 4);
}

action inner_ipv4_tcp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    add_header(inner_tcp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(tcp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, 4);
}

action inner_ipv4_icmp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_icmp, icmp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(icmp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, 4);
}

action inner_ipv4_unknown_rewrite() {
    copy_header(inner_ipv4, ipv4);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, 4);
}

action inner_ipv6_udp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_udp, udp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, 41);
}

action inner_ipv6_tcp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    add_header(inner_tcp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(tcp);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, 41);
}

action inner_ipv6_icmp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_icmp, icmp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(icmp);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, 41);
}

action inner_ipv6_unknown_rewrite() {
    copy_header(inner_ipv6, ipv6);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, 41);
}

action inner_non_ip_rewrite() {



    add(egress_metadata.payload_length, eg_intr_md.pkt_length, -14);

}

table tunnel_encap_process_inner {
    reads {
        ipv4 : valid;
        ipv6 : valid;
        tcp : valid;
        udp : valid;
        icmp : valid;
    }
    actions {
        inner_ipv4_udp_rewrite;
        inner_ipv4_tcp_rewrite;
        inner_ipv4_icmp_rewrite;
        inner_ipv4_unknown_rewrite;






        inner_non_ip_rewrite;
    }
    size : 256;
}
action f_insert_ipv4_header(proto) {
    add_header(ipv4);
    modify_field(ipv4.protocol, proto);
    modify_field(ipv4.ttl, 64);
    modify_field(ipv4.version, 0x4);
    modify_field(ipv4.ihl, 0x5);
    modify_field(ipv4.diffserv, 0);
    modify_field(ipv4.identification, 0);
}

action f_insert_ipv6_header(proto) {
    add_header(ipv6);
    modify_field(ipv6.version, 0x6);
    modify_field(ipv6.nextHdr, proto);
    modify_field(ipv6.hopLimit, 64);
    modify_field(ipv6.trafficClass, 0);
    modify_field(ipv6.flowLabel, 0);
}



action f_insert_erspan_common_header() {



    copy_header(inner_ethernet, ethernet);

    add_header(gre);
    add_header(erspan_t3_header);
    modify_field(gre.C, 0);
    modify_field(gre.R, 0);
    modify_field(gre.K, 0);
    modify_field(gre.S, 0);
    modify_field(gre.s, 0);
    modify_field(gre.recurse, 0);
    modify_field(gre.flags, 0);
    modify_field(gre.ver, 0);
    modify_field(gre.proto, 0x22EB);
    modify_field(erspan_t3_header.timestamp, i2e_metadata.ingress_tstamp);
    modify_field(erspan_t3_header.span_id, i2e_metadata.mirror_session_id);
    modify_field(erspan_t3_header.version, 2);
    modify_field(erspan_t3_header.sgt, 0);
}

action f_insert_erspan_t3_header() {
    f_insert_erspan_common_header();







    modify_field(erspan_t3_header.ft_d_other, 0);

}

action ipv4_erspan_t3_rewrite() {
    f_insert_erspan_t3_header();
    f_insert_ipv4_header(47);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
}

action ipv6_erspan_t3_rewrite() {
    f_insert_erspan_t3_header();
    f_insert_ipv6_header(47);
    add(ipv6.payloadLen, egress_metadata.payload_length, 26);
}


action f_insert_erspan_mirror_on_drop_header() {
    f_insert_erspan_common_header();
    add_header(erspan_platform_subheader);
    modify_field(erspan_t3_header.ft_d_other, 0x3C01);
    modify_field_with_hash_based_offset(erspan_platform_subheader.mirror_on_drop, 0,
                                        calc_mirror_on_drop, 0x100000000);
    modify_field(erspan_platform_subheader.switch_id,
                 global_config_metadata.switch_id);
}

action ipv4_erspan_mirror_on_drop_rewrite() {
    f_insert_erspan_mirror_on_drop_header();
    f_insert_ipv4_header(47);
    add(ipv4.totalLen, egress_metadata.payload_length, 58);
}

action ipv6_erspan_mirror_on_drop_rewrite() {
    f_insert_erspan_mirror_on_drop_header();
    f_insert_ipv6_header(47);
    add(ipv6.payloadLen, egress_metadata.payload_length, 34);
}



@pragma ternary 1
table tunnel_encap_process_outer {
    reads {
        tunnel_metadata.egress_tunnel_type : exact;
        tunnel_metadata.egress_header_count : exact;
        multicast_metadata.replica : exact;
    }
    actions {
        nop;
        fabric_rewrite;
        ipv4_erspan_t3_rewrite;




        ipv4_erspan_mirror_on_drop_rewrite;





    }
    size : 256;
}





action set_tunnel_rewrite_details(outer_bd, smac_idx, dmac_idx,
                                  sip_index, dip_index) {
    modify_field(egress_metadata.outer_bd, outer_bd);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
    set_ip_index(sip_index, dip_index);
}

action set_ip_index(sip_index, dip_index) {
    modify_field(tunnel_metadata.tunnel_src_index, sip_index);
    modify_field(tunnel_metadata.tunnel_dst_index, dip_index);
}
table tunnel_rewrite {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        nop;
        cpu_rx_rewrite;

        set_tunnel_rewrite_details;
    }
    size : 16384;
}






action tunnel_mtu_check(l3_mtu) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu, egress_metadata.payload_length);
}

action tunnel_mtu_miss() {
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

table tunnel_mtu {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        tunnel_mtu_check;
        tunnel_mtu_miss;
    }
    size : 16384;
}





action rewrite_tunnel_ipv4_src(ip) {
    modify_field(ipv4.srcAddr, ip);
}







table tunnel_src_rewrite {
    reads {
        tunnel_metadata.tunnel_src_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_src;



    }
    size : 512;
}





action rewrite_tunnel_ipv4_dst(ip) {
    modify_field(ipv4.dstAddr, ip);
}







table tunnel_dst_rewrite {
    reads {
        tunnel_metadata.tunnel_dst_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_dst;



    }
    size : 16354;
}

action rewrite_tunnel_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}





table tunnel_smac_rewrite {
    reads {
        tunnel_metadata.tunnel_smac_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_smac;
    }
    size : 512;
}





action rewrite_tunnel_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}

table tunnel_dmac_rewrite {
    reads {
        tunnel_metadata.tunnel_dmac_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_dmac;
    }
    size : 16384;
}






control process_tunnel_encap {
    if ((fabric_metadata.fabric_header_present == 0) and
        (tunnel_metadata.egress_tunnel_type != 0)) {
        if ((tunnel_metadata.egress_tunnel_type != 15) and
            (tunnel_metadata.egress_tunnel_type != 16)) {
                apply(tunnel_encap_process_inner);
        }


        apply(tunnel_encap_process_outer);
        apply(tunnel_rewrite);


        apply(tunnel_mtu);


        apply(tunnel_src_rewrite);
        apply(tunnel_dst_rewrite);


        apply(tunnel_smac_rewrite);
        apply(tunnel_dmac_rewrite);

    }
}
header_type acl_metadata_t {
    fields {
        acl_deny : 1;
        racl_deny : 1;
        acl_nexthop : 16;
        racl_nexthop : 16;
        acl_nexthop_type : 1;
        racl_nexthop_type : 1;
        acl_redirect : 1;
        racl_redirect : 1;
        if_label : 16;
        bd_label : 16;
        acl_stats_index : 14;
        acl_partition_index : 16;
        egress_if_label : 16;
        egress_bd_label : 16;
        ingress_src_port_range_id : 8;
        ingress_dst_port_range_id : 8;
        egress_src_port_range_id : 8;
        egress_dst_port_range_id : 8;
    }
}

header_type i2e_metadata_t {
    fields {
        ingress_tstamp : 32;



        mirror_session_id : 16;

    }
}
@pragma pa_solitary ingress acl_metadata.if_label
@pragma pa_atomic ingress acl_metadata.if_label

metadata acl_metadata_t acl_metadata;
metadata i2e_metadata_t i2e_metadata;
control process_egress_l4port {







}
control process_ingress_l4port {




}




action acl_deny(acl_stats_index, acl_meter_index, acl_copy_reason,
                nat_mode, ingress_cos, tc, color) {
    modify_field(acl_metadata.acl_deny, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);






}

action acl_permit(acl_stats_index, acl_meter_index, acl_copy_reason,
                  nat_mode, ingress_cos, tc, color) {
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);





}

field_list i2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}

field_list e2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;

    ingress_metadata.drop_reason;
    ingress_metadata.platform_id;
    ingress_metadata.ingress_port;
    egress_metadata.egress_port;
    global_config_metadata.switch_id;

}

action acl_mirror(session_id, acl_stats_index, acl_meter_index, nat_mode,
                  ingress_cos, tc, color) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);





}

action acl_redirect_nexthop(nexthop_index, acl_stats_index, acl_meter_index,
                            acl_copy_reason, nat_mode,
                            ingress_cos, tc, color) {
    modify_field(acl_metadata.acl_redirect, 1);
    modify_field(acl_metadata.acl_nexthop, nexthop_index);
    modify_field(acl_metadata.acl_nexthop_type, 0);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);





}

action acl_redirect_ecmp(ecmp_index, acl_stats_index, acl_meter_index,
                         acl_copy_reason, nat_mode,
                         ingress_cos, tc, color) {
    modify_field(acl_metadata.acl_redirect, 1);
    modify_field(acl_metadata.acl_nexthop, ecmp_index);
    modify_field(acl_metadata.acl_nexthop_type, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);





}







table mac_acl {
    reads {
        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;

        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l2_metadata.lkp_mac_type : ternary;
    }
    actions {
        nop;
        acl_deny;
        acl_permit;
        acl_redirect_nexthop;
        acl_redirect_ecmp;

        acl_mirror;

    }
    size : 512;
}


control process_mac_acl {

    if (((ingress_metadata.bypass_lookups & 0x0004) == 0)) {
        apply(mac_acl);
    }

}
table ip_acl {
    reads {



        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;

        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        acl_metadata.ingress_src_port_range_id : exact;
        acl_metadata.ingress_dst_port_range_id : exact;

        tcp.flags : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
    }
    actions {
        nop;
        acl_deny;
        acl_permit;
        acl_redirect_nexthop;
        acl_redirect_ecmp;

        acl_mirror;

    }
    size : 1024;
}
control process_ip_acl {
    if (((ingress_metadata.bypass_lookups & 0x0004) == 0)) {
        if (l3_metadata.lkp_ip_type == 1) {




            apply(ip_acl);

        } else {
            if (l3_metadata.lkp_ip_type == 2) {
            }
        }
    }
}




action racl_deny(acl_stats_index, acl_copy_reason,
                 ingress_cos, tc, color) {
    modify_field(acl_metadata.racl_deny, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);





}

action racl_permit(acl_stats_index, acl_copy_reason,
                   ingress_cos, tc, color) {
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);





}

action racl_redirect_nexthop(nexthop_index, acl_stats_index,
                             acl_copy_reason,
                             ingress_cos, tc, color) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, nexthop_index);
    modify_field(acl_metadata.racl_nexthop_type, 0);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);





}

action racl_redirect_ecmp(ecmp_index, acl_stats_index,
                          acl_copy_reason,
                          ingress_cos, tc, color) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, ecmp_index);
    modify_field(acl_metadata.racl_nexthop_type, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);





}






table ipv4_racl {
    reads {
        acl_metadata.bd_label : ternary;

        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        acl_metadata.ingress_src_port_range_id : exact;
        acl_metadata.ingress_dst_port_range_id : exact;
    }
    actions {
        nop;
        racl_deny;
        racl_permit;
        racl_redirect_nexthop;
        racl_redirect_ecmp;
    }
    size : 1024;
}


control process_ipv4_racl {

    apply(ipv4_racl);

}
control process_ipv6_racl {



}





counter acl_stats {
    type : packets_and_bytes;
    instance_count : 8192;
    min_width : 16;
}

action acl_stats_update() {
    count(acl_stats, acl_metadata.acl_stats_index);
}

table acl_stats {
    actions {
        acl_stats_update;
    }
    size : 8192;
}


control process_ingress_acl_stats {

    apply(acl_stats);

}





meter copp {
    type: bytes;
    static: system_acl;
    result: ig_intr_md_for_tm.packet_color;
    instance_count: 128;
}





counter drop_stats {
    type : packets;
    instance_count : 256;
}

counter drop_stats_2 {
    type : packets;
    instance_count : 256;
}


field_list mirror_info {
    ingress_metadata.drop_reason;
    i2e_metadata.mirror_session_id;
    i2e_metadata.ingress_tstamp;
    ingress_metadata.platform_id;
    ingress_metadata.ingress_port;
    global_config_metadata.switch_id;
}

action mirror_on_drop() {
    modify_field(i2e_metadata.mirror_session_id, 1015);
    modify_field(ingress_metadata.platform_id, 61);
    clone_ingress_pkt_to_egress(1015, mirror_info);
    drop();
}

action mirror_on_drop_with_reason(drop_reason) {
    modify_field(ingress_metadata.drop_reason, drop_reason);
    mirror_on_drop();
}


action redirect_to_cpu_with_reason(reason_code, qid, meter_id, icos) {
    copy_to_cpu_with_reason(reason_code, qid, meter_id, icos);
    drop();



}

action redirect_to_cpu(qid, meter_id, icos) {
    copy_to_cpu(qid, meter_id, icos);
    drop();



}

field_list cpu_info {
    ingress_metadata.bd;
    ingress_metadata.ifindex;
    fabric_metadata.reason_code;
    ingress_metadata.ingress_port;
}

action copy_to_cpu(qid, meter_id, icos) {
    modify_field(ig_intr_md_for_tm.qid, qid);
    modify_field(ig_intr_md_for_tm.ingress_cos, icos);

    modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);






}

action copy_to_cpu_with_reason(reason_code, qid, meter_id, icos) {
    modify_field(fabric_metadata.reason_code, reason_code);
    copy_to_cpu(qid, meter_id, icos);
}

action drop_packet() {
    drop();
}

action drop_packet_with_reason(drop_reason) {
    count(drop_stats, drop_reason);
    drop();
}

table system_acl {
    reads {
        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;

        ingress_metadata.ifindex : ternary;


        l2_metadata.lkp_mac_type : ternary;
        l2_metadata.port_vlan_mapping_miss : ternary;
        security_metadata.ipsg_check_fail : ternary;
        acl_metadata.acl_deny : ternary;
        acl_metadata.racl_deny: ternary;
        l3_metadata.urpf_check_fail : ternary;
        ingress_metadata.drop_flag : ternary;

        l3_metadata.l3_copy : ternary;

        l3_metadata.rmac_hit : ternary;





        l3_metadata.routed : ternary;
        ipv6_metadata.ipv6_src_is_link_local : ternary;
        l2_metadata.same_if_check : ternary;
        tunnel_metadata.tunnel_if_check : ternary;
        l3_metadata.same_bd_check : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
        l2_metadata.stp_state : ternary;
        ingress_metadata.control_frame: ternary;
        ipv4_metadata.ipv4_unicast_enabled : ternary;
        ipv6_metadata.ipv6_unicast_enabled : ternary;


        ingress_metadata.egress_ifindex : ternary;

        fabric_metadata.reason_code : ternary;

    }
    actions {
        nop;
        redirect_to_cpu;
        redirect_to_cpu_with_reason;
        copy_to_cpu;
        copy_to_cpu_with_reason;
        drop_packet;
        drop_packet_with_reason;

        mirror_on_drop;
        mirror_on_drop_with_reason;

    }
    size : 512;
}

action drop_stats_update() {
    count(drop_stats_2, ingress_metadata.drop_reason);
}

table drop_stats {
    actions {
        drop_stats_update;
    }
    size : 256;
}

control process_system_acl {
    if (((ingress_metadata.bypass_lookups & 0x0020) == 0)) {
        apply(system_acl);
        if (ingress_metadata.drop_flag == 1) {
            apply(drop_stats);
        }
    }
}
control process_egress_acl {
}

action egress_mirror(session_id) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_egress_pkt_to_egress(session_id, e2e_mirror_info);
}

action egress_mirror_drop(reason_code, platform_id) {



    modify_field(ingress_metadata.drop_reason, reason_code);
    modify_field(ingress_metadata.platform_id, platform_id);
    modify_field(egress_metadata.egress_port, eg_intr_md.egress_port);

    egress_mirror(1015);
    drop();
}

action egress_copy_to_cpu() {
    clone_egress_pkt_to_egress(250, cpu_info);
}

action egress_redirect_to_cpu() {
    egress_copy_to_cpu();
    drop();
}

action egress_copy_to_cpu_with_reason(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
    egress_copy_to_cpu();
}

action egress_redirect_to_cpu_with_reason(reason_code) {
    egress_copy_to_cpu_with_reason(reason_code);
    drop();
}


action egress_mirror_coal_hdr(session_id, id) {






}

table egress_system_acl {
    reads {
        fabric_metadata.reason_code : ternary;
        eg_intr_md.egress_port : ternary;
        eg_intr_md.deflection_flag : ternary;
        l3_metadata.l3_mtu_check : ternary;
        acl_metadata.acl_deny : ternary;
    }
    actions {
        nop;
        drop_packet;
        egress_copy_to_cpu;
        egress_redirect_to_cpu;
        egress_copy_to_cpu_with_reason;
        egress_redirect_to_cpu_with_reason;
        egress_mirror_coal_hdr;

        egress_mirror;
        egress_mirror_drop;

    }
    size : 1024;
}

control process_egress_system_acl {
    if (egress_metadata.bypass == 0) {
        apply(egress_system_acl);
    }
}
header_type nat_metadata_t {
    fields {
        ingress_nat_mode : 2;
        egress_nat_mode : 2;
        nat_nexthop : 16;
        nat_nexthop_type : 1;
        nat_hit : 1;
        nat_rewrite_index : 14;
        update_checksum : 1;
        update_udp_checksum : 1;
        update_tcp_checksum : 1;
        update_inner_udp_checksum : 1;
        update_inner_tcp_checksum : 1;
        l4_len : 16;
    }
}

metadata nat_metadata_t nat_metadata;
control process_ingress_nat {
}
control process_egress_nat {






}

control process_l4_checksum {



}
header_type multicast_metadata_t {
    fields {
        ipv4_mcast_key_type : 1;
        ipv4_mcast_key : 16;
        ipv6_mcast_key_type : 1;
        ipv6_mcast_key : 16;
        outer_mcast_route_hit : 1;
        outer_mcast_mode : 2;
        mcast_route_hit : 1;
        mcast_bridge_hit : 1;
        ipv4_multicast_enabled : 1;
        ipv6_multicast_enabled : 1;
        igmp_snooping_enabled : 1;
        mld_snooping_enabled : 1;
        bd_mrpf_group : 16;
        mcast_rpf_group : 16;
        mcast_mode : 2;
        multicast_route_mc_index : 16;
        multicast_bridge_mc_index : 16;
        inner_replica : 1;
        replica : 1;






    }
}


@pragma pa_solitary ingress multicast_metadata.multicast_route_mc_index
@pragma pa_atomic ingress multicast_metadata.multicast_route_mc_index
@pragma pa_solitary ingress multicast_metadata.multicast_bridge_mc_index
@pragma pa_atomic ingress multicast_metadata.multicast_bridge_mc_index


metadata multicast_metadata_t multicast_metadata;
control process_outer_multicast_rpf {






}
control process_outer_ipv4_multicast {
}
control process_outer_ipv6_multicast {
}





control process_outer_multicast {
}






action multicast_rpf_check_pass() {
    modify_field(l3_metadata.routed, 1);
}

action multicast_rpf_check_fail() {
    modify_field(multicast_metadata.multicast_route_mc_index, 0);
    modify_field(multicast_metadata.mcast_route_hit, 0);



}

table multicast_rpf {
    reads {
        multicast_metadata.mcast_rpf_group : exact;
        multicast_metadata.bd_mrpf_group : exact;
    }
    actions {
        multicast_rpf_check_pass;
        multicast_rpf_check_fail;
    }
    size : 16384;
}


control process_multicast_rpf {





}






action multicast_bridge_star_g_hit(mc_index) {
    modify_field(multicast_metadata.multicast_bridge_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_bridge_hit, 1);
}

action multicast_bridge_s_g_hit(mc_index) {
    modify_field(multicast_metadata.multicast_bridge_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_bridge_hit, 1);
}

action multicast_route_star_g_miss() {
    modify_field(l3_metadata.l3_copy, 1);
}

action multicast_route_sm_star_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.mcast_mode, 1);
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_route_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);
}

action multicast_route_bidir_star_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.mcast_mode, 2);
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_route_hit, 1);

    bit_or(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
           multicast_metadata.bd_mrpf_group);



}

action multicast_route_s_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
    modify_field(multicast_metadata.mcast_mode, 1);
    modify_field(multicast_metadata.mcast_route_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);
}







table ipv4_multicast_bridge_star_g {
    reads {
        ingress_metadata.bd : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        nop;
        multicast_bridge_star_g_hit;
    }
    size : 2048;
}

table ipv4_multicast_bridge {
    reads {
        ingress_metadata.bd : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        multicast_bridge_s_g_hit;
    }
    size : 4096;
}



counter ipv4_multicast_route_star_g_stats {
    type : packets;
    direct : ipv4_multicast_route_star_g;
}

counter ipv4_multicast_route_s_g_stats {
    type : packets;
    direct : ipv4_multicast_route;
}

table ipv4_multicast_route_star_g {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        multicast_route_star_g_miss;
        multicast_route_sm_star_g_hit;
        multicast_route_bidir_star_g_hit;
    }
    size : 2048;
}

table ipv4_multicast_route {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        multicast_route_s_g_hit;
    }
    size : 4096;
}


control process_ipv4_multicast {


    if (((ingress_metadata.bypass_lookups & 0x0001) == 0)) {
        apply(ipv4_multicast_bridge) {
            on_miss {
                apply(ipv4_multicast_bridge_star_g);
            }
        }
    }



    if (((ingress_metadata.bypass_lookups & 0x0002) == 0) and
        (multicast_metadata.ipv4_multicast_enabled == 1)) {
        apply(ipv4_multicast_route) {
            on_miss {
                apply(ipv4_multicast_route_star_g);
            }
        }
    }

}
control process_ipv6_multicast {
}





control process_multicast {

    if (l3_metadata.lkp_ip_type == 1) {
        process_ipv4_multicast();
    } else {
        if (l3_metadata.lkp_ip_type == 2) {
            process_ipv6_multicast();
        }
    }
    process_multicast_rpf();

}





action set_bd_flood_mc_index(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);
}

table bd_flood {
    reads {
        ingress_metadata.bd : exact;
        l2_metadata.lkp_pkt_type : exact;
    }
    actions {
        nop;
        set_bd_flood_mc_index;
    }
    size : 49152;
}

control process_multicast_flooding {

    apply(bd_flood);

}






action outer_replica_from_rid(bd, tunnel_index, tunnel_type, header_count) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 0);
    modify_field(egress_metadata.routed, l3_metadata.outer_routed);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.outer_bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
    modify_field(tunnel_metadata.egress_header_count, header_count);
}

action inner_replica_from_rid(bd, tunnel_index, tunnel_type, header_count) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 1);
    modify_field(egress_metadata.routed, l3_metadata.routed);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
    modify_field(tunnel_metadata.egress_header_count, header_count);
}

table rid {
    reads {
        eg_intr_md.egress_rid : exact;
    }
    actions {
        nop;
        outer_replica_from_rid;
        inner_replica_from_rid;
    }
    size : 32768;
}

action set_replica_copy_bridged() {
    modify_field(egress_metadata.routed, 0);
}

table replica_type {
    reads {
        multicast_metadata.replica : exact;
        egress_metadata.same_bd_check : ternary;
    }
    actions {
        nop;
        set_replica_copy_bridged;
    }
    size : 16;
}


control process_replication {

    if(eg_intr_md.egress_rid != 0) {

        apply(rid);


        apply(replica_type);
    }

}
header_type nexthop_metadata_t {
    fields {
        nexthop_type : 1;
    }
}

metadata nexthop_metadata_t nexthop_metadata;




action set_l2_redirect_action() {
    modify_field(l3_metadata.nexthop_index, l2_metadata.l2_nexthop);
    modify_field(nexthop_metadata.nexthop_type, l2_metadata.l2_nexthop_type);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_acl_redirect_action() {
    modify_field(l3_metadata.nexthop_index, acl_metadata.acl_nexthop);
    modify_field(nexthop_metadata.nexthop_type, acl_metadata.acl_nexthop_type);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_racl_redirect_action() {
    modify_field(l3_metadata.nexthop_index, acl_metadata.racl_nexthop);
    modify_field(nexthop_metadata.nexthop_type, acl_metadata.racl_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    modify_field(ingress_metadata.egress_ifindex, 0);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_fib_redirect_action() {
    modify_field(l3_metadata.nexthop_index, l3_metadata.fib_nexthop);
    modify_field(nexthop_metadata.nexthop_type, l3_metadata.fib_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);
    modify_field(fabric_metadata.reason_code, 0x217);



}

action set_nat_redirect_action() {
    modify_field(l3_metadata.nexthop_index, nat_metadata.nat_nexthop);
    modify_field(nexthop_metadata.nexthop_type, nat_metadata.nat_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    invalidate(ig_intr_md_for_tm.mcast_grp_b);



}

action set_cpu_redirect_action(cpu_ifindex) {
    modify_field(l3_metadata.routed, 0);
    modify_field(ingress_metadata.egress_ifindex, cpu_ifindex);



}

action set_multicast_route_action() {



    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_route_mc_index);
    modify_field(l3_metadata.routed, 1);
    modify_field(l3_metadata.same_bd_check, 0xFFFF);
}

action set_multicast_bridge_action() {



    modify_field(ingress_metadata.egress_ifindex, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_bridge_mc_index);
}

action set_multicast_flood() {



    modify_field(ingress_metadata.egress_ifindex, 65535);
}

action set_multicast_drop() {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, 59);
}

table fwd_result {
    reads {
        l2_metadata.l2_redirect : ternary;
        acl_metadata.acl_redirect : ternary;
        acl_metadata.racl_redirect : ternary;
        l3_metadata.rmac_hit : ternary;
        l3_metadata.fib_hit : ternary;
        nat_metadata.nat_hit : ternary;
        l2_metadata.lkp_pkt_type : ternary;
        l3_metadata.lkp_ip_type : ternary;
        multicast_metadata.igmp_snooping_enabled : ternary;
        multicast_metadata.mld_snooping_enabled : ternary;
        multicast_metadata.mcast_route_hit : ternary;
        multicast_metadata.mcast_bridge_hit : ternary;
        multicast_metadata.mcast_rpf_group : ternary;
        multicast_metadata.mcast_mode : ternary;
    }
    actions {
        nop;
        set_l2_redirect_action;
        set_fib_redirect_action;
        set_cpu_redirect_action;
        set_acl_redirect_action;
        set_racl_redirect_action;




        set_multicast_route_action;
        set_multicast_bridge_action;
        set_multicast_flood;
        set_multicast_drop;

    }
    size : 512;
}

control process_fwd_results {
    if (not ((ingress_metadata.bypass_lookups == 0xFFFF))) {
        apply(fwd_result);
    }
}
action set_ecmp_nexthop_details_for_post_routed_flood(bd, uuc_mc_index,
                                                      nhop_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, uuc_mc_index);
    modify_field(l3_metadata.nexthop_index, nhop_index);
    modify_field(ingress_metadata.egress_ifindex, 0);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);



}

action set_ecmp_nexthop_details(ifindex, bd, nhop_index, tunnel) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    modify_field(l3_metadata.nexthop_index, nhop_index);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);
    bit_xor(tunnel_metadata.tunnel_if_check,
            tunnel_metadata.tunnel_terminate, tunnel);
    bit_and(ig_intr_md_for_tm.disable_ucast_cutthru,
            l2_metadata.non_ip_packet, tunnel);
}

action set_wcmp() {
}


field_list l3_hash_fields {
    hash_metadata.hash1;



}

field_list_calculation ecmp_hash {
    input {
        l3_hash_fields;
    }







    algorithm : identity;
    output_width : 14;

}

action_selector ecmp_selector {
    selection_key : ecmp_hash;



    selection_mode : fair;

}

action_profile ecmp_action_profile {
    actions {
        nop;
        set_ecmp_nexthop_details;
        set_ecmp_nexthop_details_for_post_routed_flood;



    }
    size : 16384;
    dynamic_action_selection : ecmp_selector;
}

table ecmp_group {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    action_profile: ecmp_action_profile;
    size : 1024;
}
action set_nexthop_details_for_post_routed_flood(bd, uuc_mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, uuc_mc_index);
    modify_field(ingress_metadata.egress_ifindex, 0);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);



}

action set_nexthop_details(ifindex, bd, tunnel) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);
    bit_xor(tunnel_metadata.tunnel_if_check,
            tunnel_metadata.tunnel_terminate, tunnel);
    bit_and(ig_intr_md_for_tm.disable_ucast_cutthru,
            l2_metadata.non_ip_packet, tunnel);
}

table nexthop {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_nexthop_details;
        set_nexthop_details_for_post_routed_flood;
    }
    size : 49152;
}

control process_nexthop {
    if (nexthop_metadata.nexthop_type == 1) {
            apply(ecmp_group);






    } else {

        apply(nexthop);
    }
}
action set_l2_rewrite_with_tunnel(tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 0);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(egress_metadata.outer_bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action set_l2_rewrite() {
    modify_field(egress_metadata.routed, 0);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(egress_metadata.outer_bd, ingress_metadata.bd);
}

action set_l3_rewrite_with_tunnel(bd, dmac, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action set_l3_rewrite(bd, dmac) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
}
table rewrite {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_l2_rewrite;

        set_l2_rewrite_with_tunnel;


        set_l3_rewrite;

        set_l3_rewrite_with_tunnel;
    }
    size : 49152;
}

action rewrite_ipv4_multicast() {
    modify_field(ethernet.dstAddr, ipv4.dstAddr, 0x007FFFFF);
}

action rewrite_ipv6_multicast() {
}

table rewrite_multicast {
    reads {
        ipv4 : valid;
        ipv6 : valid;
        ipv4.dstAddr mask 0xF0000000 : ternary;



    }
    actions {
        nop;
        rewrite_ipv4_multicast;



    }
}

control process_rewrite {
    if ((egress_metadata.routed == 0) or
        (l3_metadata.nexthop_index != 0)) {
        apply(rewrite);
    } else {

        apply(rewrite_multicast);

    }
}
header_type security_metadata_t {
    fields {
        ipsg_enabled : 1;
        ipsg_check_fail : 1;
    }
}

metadata security_metadata_t security_metadata;
control process_storm_control {





}

control process_storm_control_stats {





}
control process_ip_sourceguard {
}
header_type fabric_metadata_t {
    fields {
        packetType : 3;
        fabric_header_present : 1;
        reason_code : 16;





    }
}

metadata fabric_metadata_t fabric_metadata;




action terminate_cpu_packet() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port,
                 fabric_header.dstPortOrGroup);
    modify_field(egress_metadata.bypass, fabric_header_cpu.txBypass);

    modify_field(ethernet.etherType, fabric_payload_header.etherType);
    remove_header(fabric_header);
    remove_header(fabric_header_cpu);
    remove_header(fabric_payload_header);
}
@pragma ternary 1
table fabric_ingress_dst_lkp {
    reads {
        fabric_header.dstDevice : exact;
    }
    actions {
        nop;
        terminate_cpu_packet;
    }
}
action non_ip_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
}

action ipv4_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv4.protocol);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
}

action ipv6_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv6_metadata.lkp_ipv6_sa, ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);
}

table native_packet_over_fabric {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_over_fabric;
        ipv4_over_fabric;



    }
    size : 1024;
}




control process_ingress_fabric {
    if (ingress_metadata.port_type != 0) {
        apply(fabric_ingress_dst_lkp);
    }
}
control process_fabric_lag {



}





action cpu_rx_rewrite() {
    add_header(fabric_header);
    modify_field(fabric_header.headerVersion, 0);
    modify_field(fabric_header.packetVersion, 0);
    modify_field(fabric_header.pad1, 0);
    modify_field(fabric_header.packetType, 5);
    add_header(fabric_header_cpu);
    modify_field(fabric_header_cpu.ingressPort, ingress_metadata.ingress_port);
    modify_field(fabric_header_cpu.ingressIfindex, ingress_metadata.ifindex);
    modify_field(fabric_header_cpu.ingressBd, ingress_metadata.bd);
    modify_field(fabric_header_cpu.reasonCode, fabric_metadata.reason_code);
    add_header(fabric_payload_header);
    modify_field(fabric_payload_header.etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x9000);
}

action fabric_rewrite(tunnel_index) {
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
}
control process_egress_filter {
}
action set_mirror_nhop(nhop_idx, session_id) {
    modify_field(l3_metadata.nexthop_index, nhop_idx);
    modify_field(i2e_metadata.mirror_session_id, session_id);
}

action set_mirror_bd(bd, session_id) {
    modify_field(egress_metadata.bd, bd);
    modify_field(i2e_metadata.mirror_session_id, session_id);
}

@pragma ternary 1
table mirror {
    reads {
        i2e_metadata.mirror_session_id : exact;
    }
    actions {
        nop;
        set_mirror_nhop;
        set_mirror_bd;



    }
    size : 1024;
}

control process_mirroring {

    apply(mirror);

}
header_type int_metadata_i2e_t {
    fields {

        source : 1;
        plt_source : 1;
        sink : 1;
        report : 1;
    }
}



metadata int_metadata_i2e_t int_metadata_i2e;

header_type int_metadata_t {
    fields {


        insert_cnt : 8;
        remove_byte_cnt : 16;
        insert_byte_cnt : 16;
        int_hdr_word_len : 8;
        quantized_latency : 32;
        hit_state : 2;
    }
}




metadata int_metadata_t int_metadata;
field_list switch_and_port_ids {
    global_config_metadata.switch_id;

    ig_intr_md.ingress_port;
    eg_intr_md.egress_port;
}
field_list_calculation switch_n_ports {
    input { switch_and_port_ids; }
    algorithm : identity_lsb;
    output_width : 31;
}


action int_set_header_0() {
    add_header(int_switch_id_header);
    modify_field(int_switch_id_header.switch_id, global_config_metadata.switch_id);
}


action int_set_header_1() {
    add_header(int_port_ids_header);
    modify_field(int_port_ids_header.ingress_port_id, ingress_metadata.ingress_port);
    modify_field(int_port_ids_header.egress_port_id, eg_intr_md.egress_port);
}


action int_set_header_2() {
    add_header(int_hop_latency_header);







    modify_field(int_hop_latency_header.hop_latency,
                 eg_intr_md.deq_timedelta);

}


action int_set_header_3() {
    add_header(int_q_occupancy_header);
    modify_field(int_q_occupancy_header.q_occupancy1, 0);





    modify_field(int_q_occupancy_header.q_occupancy0,
                 eg_intr_md.enq_qdepth);


}



action int_set_header_0003_i0() {
}
action int_set_header_0003_i1() {
    int_set_header_3();
}
action int_set_header_0003_i2() {
    int_set_header_2();
}
action int_set_header_0003_i3() {
    int_set_header_3();
    int_set_header_2();
}
action int_set_header_0003_i4() {
    int_set_header_1();
}
action int_set_header_0003_i5() {
    int_set_header_3();
    int_set_header_1();
}
action int_set_header_0003_i6() {
    int_set_header_2();
    int_set_header_1();
}
action int_set_header_0003_i7() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_1();
}
action int_set_header_0003_i8() {
    int_set_header_0();
}
action int_set_header_0003_i9() {
    int_set_header_3();
    int_set_header_0();
}
action int_set_header_0003_i10() {
    int_set_header_2();
    int_set_header_0();
}
action int_set_header_0003_i11() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_0();
}
action int_set_header_0003_i12() {
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i13() {
    int_set_header_3();
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i14() {
    int_set_header_2();
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i15() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_1();
    int_set_header_0();
}

@pragma ternary 1
table int_inst_0003 {
    reads {
        int_header.instruction_mask_0003 : exact;
    }
    actions {
        int_set_header_0003_i0;
        int_set_header_0003_i1;
        int_set_header_0003_i2;
        int_set_header_0003_i3;
        int_set_header_0003_i4;
        int_set_header_0003_i5;
        int_set_header_0003_i6;
        int_set_header_0003_i7;
        int_set_header_0003_i8;
        int_set_header_0003_i9;
        int_set_header_0003_i10;
        int_set_header_0003_i11;
        int_set_header_0003_i12;
        int_set_header_0003_i13;
        int_set_header_0003_i14;
        int_set_header_0003_i15;
    }
    size : 17;
}

@pragma ternary 1
table int_inst_0407 {
    reads {
        int_header.instruction_mask_0407 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}

table int_inst_0811 {
    reads {
        int_header.instruction_mask_0811 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}

table int_inst_1215 {
    reads {
        int_header.instruction_mask_1215 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}


action int_set_header_0_bos() {
    modify_field(int_switch_id_header.bos, 1);
}
action int_set_header_1_bos() {
    modify_field(int_port_ids_header.bos, 1);
}
action int_set_header_2_bos() {
    modify_field(int_hop_latency_header.bos, 1);
}
action int_set_header_3_bos() {
    modify_field(int_q_occupancy_header.bos, 1);
}

table int_bos {
    reads {
        int_header.total_hop_cnt : ternary;
        int_header.instruction_mask_0003 : ternary;
        int_header.instruction_mask_0407 : ternary;
        int_header.instruction_mask_0811 : ternary;
        int_header.instruction_mask_1215 : ternary;
    }
    actions {
        int_set_header_0_bos;
        int_set_header_1_bos;
        int_set_header_2_bos;
        int_set_header_3_bos;
        nop;
    }
    size : 17;
}


action int_set_e_bit() {
    modify_field(int_header.e, 1);
}

action int_update_total_hop_cnt() {
    add_to_field(int_header.total_hop_cnt, 1);
}

table int_meta_header_update {




    reads {
        int_metadata.insert_cnt : exact;
    }
    actions {
        int_set_e_bit;
        int_update_total_hop_cnt;
    }
    size : 2;
}
control process_int_endpoint{
}

control process_int_upstream_report {
}

control process_int_sink_update_outer {



}
action copy_latency() {
    modify_field(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 0x1FFFF);}
action quantize_latency_1() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 1, 0xFFFF);}
action quantize_latency_2() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 2, 0x7FFF);}
action quantize_latency_3() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 3, 0x3FFF);}
action quantize_latency_4() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 4, 0x1FFF);}
action quantize_latency_5() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 5, 0xFFF);}
action quantize_latency_6() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 6, 0x7FF);}
action quantize_latency_7() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 7, 0x3FF);}
action quantize_latency_8() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 8, 0x1FF);}
action quantize_latency_9() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 9, 0xFF);}
action quantize_latency_10() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 10, 0x7F);}
action quantize_latency_11() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 11, 0x3F);}
action quantize_latency_12() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 12, 0x1F);}
action quantize_latency_13() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 13, 0xF);}
action quantize_latency_14() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 14, 0x7);}
action quantize_latency_15() {
    modify_field_with_shift(int_metadata.quantized_latency,
       eg_intr_md.deq_timedelta, 15, 0x3);}

table plt_quantize_latency {
    reads { ethernet: valid; }
    actions {

        quantize_latency_1;
        quantize_latency_2;
        quantize_latency_3;
        quantize_latency_4;
        quantize_latency_5;
        quantize_latency_6;
        quantize_latency_7;
        quantize_latency_8;
        quantize_latency_9;
        quantize_latency_10;
        quantize_latency_11;
        quantize_latency_12;
        quantize_latency_13;
        quantize_latency_14;
        quantize_latency_15;
        copy_latency;
    }
    size: 2;
}



action scramble_latency() {

    subtract(int_metadata.quantized_latency,
            global_config_metadata.switch_id,
            int_metadata.quantized_latency);
}

table plt_scramble_latency {
    actions {scramble_latency;}
    size : 1;
}
control process_int_egress_prep {


    apply(plt_quantize_latency);
    if (int_metadata_i2e.sink == 0) {

        apply(plt_scramble_latency);
    }


}
action int_transit() {
    modify_field(int_metadata.hit_state, 1);
    subtract(int_metadata.insert_cnt, int_header.max_hop_cnt,
                                            int_header.total_hop_cnt);



    shift_left(int_metadata.insert_byte_cnt, int_metadata.int_hdr_word_len, 2);
}


action int_reset() {




    modify_field(int_metadata.insert_cnt, 0);
    modify_field(int_metadata.int_hdr_word_len, 0);
}
table int_insert {
    reads {
        int_metadata_i2e.source : ternary;
        int_metadata_i2e.sink : ternary;
        int_header : valid;

        eg_intr_md_from_parser_aux.clone_src : ternary;



    }
    actions {

        int_transit;





        int_reset;
        nop;
    }
    size : 5;
}


action clear_upper() {


    bit_and(int_metadata.insert_byte_cnt, int_metadata.insert_byte_cnt, 0x007F );
}

table int_transit_clear_byte_cnt {

    actions{ clear_upper; }
    size : 1;
}



control process_int_insertion {

    apply(int_insert);
    if (int_metadata.hit_state != 0) {

        if (int_metadata.hit_state == 1) {
            apply(int_transit_clear_byte_cnt);
        }




        if (int_metadata.insert_cnt != 0) {
            apply(int_inst_0003);
            apply(int_inst_0407);
            apply(int_inst_0811);
            apply(int_inst_1215);
            apply(int_bos);
        }
        apply(int_meta_header_update);
    }

}


action update_int_plt_header() {

    bit_xor(int_plt_header.pl_encoding, int_plt_header.pl_encoding,
            int_metadata.quantized_latency);
}

action add_int_plt_header() {
    add_header(int_plt_header);
    add_to_field(int_metadata.insert_byte_cnt, 4);
    add_to_field(int_metadata.int_hdr_word_len, 1);

    update_int_plt_header();
}
table int_plt_encode {
    actions {
        update_int_plt_header;
    }
    size : 1;
}



control process_plt_insertion {
    if (int_metadata_i2e.source == 0 and int_metadata_i2e.sink == 0
            and valid(int_plt_header)) {

        apply(int_plt_encode);
    }


}
control process_int_egress {

    if (int_metadata_i2e.sink == 1 and not (eg_intr_md_from_parser_aux.clone_src != 0)) {
    }
    else {

        process_int_insertion();
        if (tunnel_metadata.egress_tunnel_type == 7 or
            tunnel_metadata.egress_tunnel_type == 18) {







        }
        else {


            process_plt_insertion();

        }
    }

}
action int_update_vxlan_gpe_ipv4() {
    add_to_field(ipv4.totalLen, int_metadata.insert_byte_cnt);
    add_to_field(udp.length_, int_metadata.insert_byte_cnt);
    add_to_field(vxlan_gpe_int_header.len, int_metadata.int_hdr_word_len);
}
table int_outer_encap {
    reads {
        ipv4 : valid;
        int_metadata_i2e.source : exact;
        int_metadata_i2e.sink : exact;
        erspan_t3_header : valid;
        int_metadata_i2e.plt_source : ternary;
        tunnel_metadata.egress_tunnel_type : ternary;
    }
    actions {




        int_update_vxlan_gpe_ipv4;
        nop;
    }
    size : 8;
}
control process_int_outer_encap {

    if ((int_metadata.insert_cnt != 0)
            or (int_metadata_i2e.sink == 1 and (eg_intr_md_from_parser_aux.clone_src == 3)))
    {

        apply(int_outer_encap);
    }

}
header_type hash_metadata_t {
    fields {
        hash1 : 16;
        hash2 : 16;
        entropy_hash : 16;
    }
}

@pragma pa_atomic ingress hash_metadata.hash1
@pragma pa_solitary ingress hash_metadata.hash1
@pragma pa_atomic ingress hash_metadata.hash2
@pragma pa_solitary ingress hash_metadata.hash2
metadata hash_metadata_t hash_metadata;

field_list lkp_ipv4_hash1_fields {
    ipv4_metadata.lkp_ipv4_sa;
    ipv4_metadata.lkp_ipv4_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list lkp_ipv4_hash2_fields {
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    ipv4_metadata.lkp_ipv4_sa;
    ipv4_metadata.lkp_ipv4_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list_calculation lkp_ipv4_hash1 {
    input {
        lkp_ipv4_hash1_fields;
    }



    algorithm : crc16;

    output_width : 16;
}

field_list_calculation lkp_ipv4_hash2 {
    input {
        lkp_ipv4_hash2_fields;
    }



    algorithm : crc16;

    output_width : 16;
}

action compute_lkp_ipv4_hash() {
    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_ipv4_hash1, 65536);
}

field_list lkp_ipv6_hash1_fields {
    ipv6_metadata.lkp_ipv6_sa;
    ipv6_metadata.lkp_ipv6_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list lkp_ipv6_hash2_fields {
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    ipv6_metadata.lkp_ipv6_sa;
    ipv6_metadata.lkp_ipv6_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list_calculation lkp_ipv6_hash1 {
    input {
        lkp_ipv6_hash1_fields;
    }



    algorithm : crc16;

    output_width : 16;
}

field_list_calculation lkp_ipv6_hash2 {
    input {
        lkp_ipv6_hash2_fields;
    }



    algorithm : crc16;

    output_width : 16;
}

action compute_lkp_ipv6_hash() {
    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_ipv6_hash1, 65536);
}

field_list lkp_non_ip_hash1_fields {
    ingress_metadata.ifindex;
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
}

field_list_calculation lkp_non_ip_hash1 {
    input {
        lkp_non_ip_hash1_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action compute_lkp_non_ip_hash() {
    modify_field_with_hash_based_offset(hash_metadata.hash1, 0,
                                        lkp_non_ip_hash1, 65536);
}

table compute_ipv4_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_ipv4_hash;
    }
}

table compute_ipv6_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_ipv6_hash;
    }
}

table compute_non_ip_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_lkp_non_ip_hash;
    }
}

action compute_other_hashes() {
    shift_right(hash_metadata.hash2, hash_metadata.hash1, 2);
    modify_field(ig_intr_md_for_tm.level1_mcast_hash, hash_metadata.hash1);
    shift_right(ig_intr_md_for_tm.level2_mcast_hash, hash_metadata.hash1, 3);
    modify_field(hash_metadata.entropy_hash, hash_metadata.hash1);
}

@pragma ternary 1
table compute_other_hashes {

    reads {
        ethernet: valid;
    }

    actions {
        compute_other_hashes;
    }
}

control process_hashes {
    if (((tunnel_metadata.tunnel_terminate == 0) and valid(ipv4)) or
        ((tunnel_metadata.tunnel_terminate == 1) and valid(inner_ipv4))) {

        apply(compute_ipv4_hashes);

    }







        else {

            apply(compute_non_ip_hashes);

        }



    apply(compute_other_hashes);
}
 header_type meter_metadata_t {
     fields {
         packet_color : 2;
         meter_index : 16;
     }
 }


@pragma pa_atomic ingress meter_metadata.packet_color
@pragma pa_solitary ingress meter_metadata.packet_color

@pragma pa_atomic ingress meter_metadata.meter_index
@pragma pa_solitary ingress meter_metadata.meter_index


metadata meter_metadata_t meter_metadata;





action meter_deny() {
    drop();
}

action meter_permit() {
}


counter meter_stats {
    type : packets;
    direct : meter_action;
}


table meter_action {
    reads {
        meter_metadata.packet_color : exact;
        meter_metadata.meter_index : exact;
    }

    actions {
        meter_permit;
        meter_deny;
    }
    size: 8192;
}

meter meter_index {
    type : bytes;
    direct : meter_index;
    result : meter_metadata.packet_color;
}

@pragma ternary 1
table meter_index {
    reads {
        meter_metadata.meter_index: exact;
    }
    actions {
        nop;
    }
    size: 2048;
}


control process_meter_index {

    if (((ingress_metadata.bypass_lookups & 0x0010) == 0)) {
        apply(meter_index);
    }

}

control process_meter_action {

    if (((ingress_metadata.bypass_lookups & 0x0010) == 0)) {
        apply(meter_action);
    }

}
control process_ingress_sflow {




}
control process_bfd_mirror_to_cpu {
}
control process_egress_bfd_packet {
}
control process_egress_bfd_tx_timers {
}
control process_bfd_packet {
}
control process_bfd_rx_packet {
}
control process_bfd_tx_packet {
}
control process_bfd_recirc {
}





header_type qos_metadata_t {
    fields {
        ingress_qos_group: 5;
        tc_qos_group: 5;
        egress_qos_group: 5;
        lkp_tc: 8;
        trust_dscp: 1;
        trust_pcp: 1;
    }
}

metadata qos_metadata_t qos_metadata;
control process_ingress_qos_map {
}
control process_traffic_class{



}
control process_egress_qos_map {





}
control process_sr_rewrite {




}

control process_ipv6_sr {



}
header_type flowlet_metadata_t {
    fields {
        id : 16;
        inactive_timeout : 32;
    }
}
@pragma pa_atomic ingress flowlet_metadata.id
metadata flowlet_metadata_t flowlet_metadata;

register flowlet_state {
    width : 64;
    instance_count : 8192;
}

blackbox stateful_alu flowlet_alu {
    reg : flowlet_state;
    initial_register_hi_value : 0;
    initial_register_lo_value : 0;


    condition_lo : i2e_metadata.ingress_tstamp - register_lo > 1;
    update_lo_2_value : i2e_metadata.ingress_tstamp;
    update_hi_1_value : register_hi + 997;
    update_hi_1_predicate: condition_lo;
    update_hi_2_value : register_hi;
    update_hi_2_predicate: not condition_lo;
    output_value : alu_hi;
    output_dst : flowlet_metadata.id;
}

action flowlet_lookup() {
    flowlet_alu.execute_stateful_alu_from_hash(flowlet_hash);
}


field_list flowlet_hash_fields {
    hash_metadata.hash1;
}

field_list_calculation flowlet_hash {
    input {
        flowlet_hash_fields;
    }
    algorithm : identity;
    output_width : 13;
}

table flowlet {
    actions {
        flowlet_lookup;
    }
    size : 1;
}

control process_flowlet {
}
control process_pktgen {
}
control process_pktgen_port_down {



}

control process_pktgen_nhop_down {



}

control process_lag_fallback {





}

action nop() {
}

action on_miss() {
}

control ingress {

    process_ingress_port_mapping();


    process_global_params();







        process_validate_outer_header();



        process_port_vlan_mapping();



        process_int_endpoint();


        process_bfd_rx_packet();
        process_spanning_tree();


        process_ingress_qos_map();


        process_ip_sourceguard();


        process_ingress_sflow();


        process_tunnel();


        process_storm_control();




    process_bfd_packet();

    if (ingress_metadata.port_type != 1) {




            process_validate_packet();


            process_ingress_l4port();


            process_mac();


            if (l3_metadata.lkp_ip_type == 0) {
                process_mac_acl();
            } else {
                process_ip_acl();
            }


            process_int_upstream_report();

            apply(rmac) {
                rmac_miss {
                    process_multicast();
                }
                default {
                    if (((ingress_metadata.bypass_lookups & 0x0002) == 0)) {
                        if ((l3_metadata.lkp_ip_type == 1) and
                            (ipv4_metadata.ipv4_unicast_enabled == 1)) {

                            process_ipv4_racl();
                            process_ipv4_urpf();
                            process_ipv4_fib();

                        } else {
                            if ((l3_metadata.lkp_ip_type == 2) and
                                (ipv6_metadata.ipv6_unicast_enabled == 1)) {

                                process_ipv6_sr();
                                process_ipv6_racl();
                                process_ipv6_urpf();
                                process_ipv6_fib();
                            }
                        }
                        process_urpf_bd();
                    }
                }
            }


            process_ingress_nat();



    }


    process_int_sink_update_outer();

    process_meter_index();


    process_hashes();

    process_meter_action();

    if (ingress_metadata.port_type != 1) {

        process_ingress_bd_stats();
        process_ingress_acl_stats();
        process_storm_control_stats();


        process_fwd_results();


        process_flowlet();


        process_nexthop();

        if (ingress_metadata.egress_ifindex == 65535) {

            process_multicast_flooding();
        } else {

            process_lag();
        }







        process_mac_learning();
    }

    process_fabric_lag();


    process_traffic_class();

    if (ingress_metadata.port_type != 1) {

        process_system_acl();
    }
}

control egress {
        process_bfd_recirc();


        process_lag_fallback();


        if ((eg_intr_md.deflection_flag == 0) and
            (egress_metadata.bypass == 0)) {


            if ((eg_intr_md_from_parser_aux.clone_src == 0)) {
                process_replication();
            }



            process_int_egress_prep();


            if ((eg_intr_md_from_parser_aux.clone_src != 0)) {

                process_mirroring();
                process_bfd_mirror_to_cpu();
            } else {




                process_egress_bfd_packet();
            }


            apply(egress_port_mapping) {
                egress_port_type_normal {
                    if ((eg_intr_md_from_parser_aux.clone_src == 0)) {

                        process_vlan_decap();
                    }


                    process_tunnel_decap();


                    process_sr_rewrite();


                    process_rewrite();


                    process_egress_bd();


                    process_egress_qos_map();


                    process_mac_rewrite();


                    process_mtu();


                    process_egress_nat();


                    process_egress_bd_stats();
                }
            }


            process_egress_l4port();


            process_int_egress();


            process_tunnel_encap();


            process_l4_checksum();


            process_egress_acl();


            process_int_outer_encap();

            if (egress_metadata.port_type == 0) {

                process_vlan_xlate();
            }


            process_egress_filter();
        }


        process_egress_system_acl();



}
