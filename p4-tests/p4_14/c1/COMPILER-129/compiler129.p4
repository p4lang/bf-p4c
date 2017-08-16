
#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"




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
        sgt_other : 32;
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
        state : 2;
        p : 1;
        f : 1;
        c : 1;
        a : 1;
        d : 1;
        m : 1;
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
        _pad : 3;
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

header_type fabric_payload_header_t {
    fields {
        etherType : 16;
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

header_type coal_pkt_hdr_t {




    fields {
        session_id : 16;
    }
}

header coal_pkt_hdr_t coal_pkt_hdr;



parser start {
    return parse_ethernet;
}
header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    set_metadata(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    set_metadata(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;
        0x9000 : parse_fabric_header;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; 0x9001 : parse_sflow_cpu_header; default: ingress;
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
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; 0x9001 : parse_sflow_cpu_header; default: ingress;
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
    extract(mpls[next]);
    return select(latest.bos) {
        0 : parse_mpls;
        1 : parse_mpls_bos;
        default: ingress;
    }
}

parser parse_mpls_bos {
    return select(current(0, 4)) {
        0x4 : parse_mpls_inner_ipv4;
        0x6 : parse_mpls_inner_ipv6;
        default: parse_eompls;
    }

}

parser parse_mpls_inner_ipv4 {
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 9);
    return parse_inner_ipv4;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 9);
    return parse_inner_ipv6;
}

parser parse_vpls {
    return ingress;
}

parser parse_pw {
    return ingress;
}
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
    set_metadata(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    set_metadata(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, ipv4.protocol);
    set_metadata(l3_metadata.lkp_ip_ttl, ipv4.ttl);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        0x501 : parse_icmp;
        0x506 : parse_tcp;
        0x511 : parse_udp;
        0x52f : parse_gre;
        0x504 : parse_ipv4_in_ip;
        0x529 : parse_ipv6_in_ip;
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
@pragma overlay_subheader egress inner_ipv6 srcAddr dstAddr

header ipv6_t ipv6;

parser parse_udp_v6 {
    extract(udp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
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

    set_metadata(ipv6_metadata.lkp_ipv6_sa, latest.srcAddr);
    set_metadata(ipv6_metadata.lkp_ipv6_da, latest.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    set_metadata(l3_metadata.lkp_ip_ttl, ipv6.hopLimit);

    return select(latest.nextHdr) {
        58 : parse_icmp;
        6 : parse_tcp;
        4 : parse_ipv4_in_ip;

        17 : parse_udp;
        47 : parse_gre;
        41 : parse_ipv6_in_ip;




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
    set_metadata(l3_metadata.lkp_l4_sport, latest.typeCode);
    return select(latest.typeCode) {

        0x8200 mask 0xfe00 : parse_set_prio_med;
        0x8400 mask 0xfc00 : parse_set_prio_med;
        0x8800 mask 0xff00 : parse_set_prio_med;
        default: ingress;
    }
}




header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return select(latest.dstPort) {
        179 : parse_set_prio_med;
        639 : parse_set_prio_med;
        default: ingress;
    }
}

header udp_t udp;

header roce_v2_header_t roce_v2;

parser parse_roce_v2 {
    extract(roce_v2);
    return ingress;
}

parser parse_udp {
    extract(udp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return select(latest.dstPort) {
        4789 : parse_vxlan;
        6081: parse_geneve;
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
        0x20006558 : parse_nvgre;
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
    return parse_inner_ethernet;
}



header arp_rarp_t arp_rarp;

parser parse_arp_rarp {
    extract(arp_rarp);
    return select(latest.protoType) {
        0x0800 : parse_arp_rarp_ipv4;
        default: ingress;
    }
}

header arp_rarp_ipv4_t arp_rarp_ipv4;

parser parse_arp_rarp_ipv4 {
    extract(arp_rarp_ipv4);
    return parse_set_prio_med;
}

header eompls_t eompls;

parser parse_eompls {

    set_metadata(tunnel_metadata.ingress_tunnel_type,
                 6);
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
    set_metadata(l3_metadata.lkp_inner_l4_sport, latest.typeCode);
    return ingress;
}



@pragma pa_alias egress inner_tcp tcp



header tcp_t inner_tcp;

parser parse_inner_tcp {
    extract(inner_tcp);
    set_metadata(l3_metadata.lkp_inner_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_inner_l4_dport, latest.dstPort);
    return ingress;
}

header udp_t inner_udp;

parser parse_inner_udp {
    extract(inner_udp);
    set_metadata(l3_metadata.lkp_inner_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_inner_l4_dport, latest.dstPort);
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
    return select(latest.etherType) {
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
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

header bfd_t bfd;

parser parse_bfd {
    extract(bfd);
    return parse_set_prio_max;
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
    return parse_fabric_payload_header;
}

parser parse_fabric_payload_header {
    extract(fabric_payload_header);
    return select(latest.etherType) {
        0 mask 0xfe00: parse_llc_header;
        0 mask 0xfa00: parse_llc_header;
        0x8100 : parse_vlan; 0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; 0x9001 : parse_sflow_cpu_header; default: ingress;
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
header sflow_sample_cpu_t sflow_sample_cpu;
parser parse_sflow_cpu_header {



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
        control_frame: 1;
        sflow_take_sample : 32 (saturating);
        sflow_session_id : 3;
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
        sflow_take_sample : 32 (saturating);
    }
}

@pragma pa_atomic ingress ingress_metadata.sflow_take_sample
@pragma pa_solitary ingress ingress_metadata.sflow_take_sample
metadata ingress_metadata_t ingress_metadata;
metadata egress_metadata_t egress_metadata;


header_type global_config_metadata_t {
    fields {
        enable_dod : 1;

    }
}
metadata global_config_metadata_t global_config_metadata;





action set_config_parameters(enable_dod) {



    deflect_on_drop(enable_dod);



    modify_field_rng_uniform(ingress_metadata.sflow_take_sample, 0, 4294967295);

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
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_unicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_unicast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_unicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 1);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_multicast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_multicast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_multicast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_multicast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 2);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_broadcast_packet_untagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_broadcast_packet_single_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[0].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_broadcast_packet_double_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, vlan_tag_[1].etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action set_valid_outer_broadcast_packet_qinq_tagged() {
    modify_field(l2_metadata.lkp_pkt_type, 4);
    modify_field(l2_metadata.lkp_mac_type, ethernet.etherType);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

action malformed_outer_ethernet_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
}

table validate_outer_ethernet {
    reads {
        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
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
                } else {
                    if (valid(mpls[0])) {
                        validate_mpls_header();
                    }
                }
            }
        }
    }
}





action set_ifindex(ifindex, if_label, exclusion_id, port_type) {
    modify_field(ingress_metadata.ifindex, ifindex);
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, exclusion_id);
    modify_field(acl_metadata.if_label, if_label);
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

control process_ingress_port_mapping {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_mapping);
    }
}





action set_bd_properties(bd, vrf, stp_group, learning_enabled,
                         bd_label, stats_idx, rmac_group,
                         ipv4_unicast_enabled, ipv6_unicast_enabled,
                         ipv4_urpf_mode, ipv6_urpf_mode,
                         igmp_snooping_enabled, mld_snooping_enabled,
                         ipv4_multicast_mode, ipv6_multicast_mode, mrpf_group,
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
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
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





action egress_port_type_normal() {
    modify_field(egress_metadata.port_type, 0);

    modify_field_rng_uniform(egress_metadata.sflow_take_sample, 0, 4294967295);

}

action egress_port_type_fabric() {
    modify_field(egress_metadata.port_type, 1);
    modify_field(tunnel_metadata.egress_tunnel_type, 15);
}

action egress_port_type_cpu() {
    modify_field(egress_metadata.port_type, 2);
    modify_field(tunnel_metadata.egress_tunnel_type, 16);
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
        eg_intr_md.egress_port : exact;
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

action modify_outer_pri1(a, b, c, d, e, f) {
    modify_field(l2_metadata.field_1 , ingress_metadata.port_type);
    modify_field(l2_metadata.field_2 , 0);
    modify_field(l2_metadata.field_3 , ingress_metadata.port_type);
    modify_field(l2_metadata.field_4 , 1);
    add_to_field(l2_metadata.field_5 , 5);
    modify_field(l2_metadata.field_6 , 1);
    add_to_field(l2_metadata.field_7 , 2);
    modify_field(l2_metadata.field_8 , 3);
    add_to_field(l2_metadata.field_9 , 4);
    modify_field(l2_metadata.field_10 , 5);
    modify_field(l2_metadata.field_11 , 1);
    modify_field(l2_metadata.field_12 , 2);
    modify_field(l2_metadata.field_13 , 3);
    add_to_field(l2_metadata.field_14 , 4);
    modify_field(l2_metadata.field_15 , 5);
    modify_field(l2_metadata.field_16 , 1);
    add_to_field(l2_metadata.field_17 , 2);
    modify_field(l2_metadata.field_18 , 3);
    add_to_field(l2_metadata.field_19 , 4);
    modify_field(l2_metadata.field_20 , 5);
    modify_field(l2_metadata.field_21 , 1);
    add_to_field(l2_metadata.field_22 , 2);
    modify_field(l2_metadata.field_23 , 3);
    add_to_field(l2_metadata.field_24 , 4);
    modify_field(l2_metadata.field_25 , 5);
    add_to_field(l2_metadata.field_26 , -1);
    modify_field(l2_metadata.field_27 , 2);
    modify_field(l2_metadata.field_28 , 3);
    modify_field(l2_metadata.field_29 , 4);
    modify_field(l2_metadata.field_30 , 5);
    modify_field(l2_metadata.field_31 , 1);
    modify_field(l2_metadata.field_32 , 2);
    modify_field(l2_metadata.field_33 , 3);
    modify_field(l2_metadata.field_34 , 4);
    modify_field(l2_metadata.field_35 , 5);
    modify_field(l2_metadata.field_36 , 1);
    modify_field(l2_metadata.field_37 , 2);
    modify_field(l2_metadata.field_38 , 3);
    add_to_field(l2_metadata.field_39 , 4);
    modify_field(l2_metadata.field_40 , 5);
    modify_field(l2_metadata.field_41 , 1);
    modify_field(l2_metadata.field_42 , 2);
    add_to_field(l2_metadata.field_43 , 3);
    modify_field(l2_metadata.field_44 , 4);
    add_to_field(l2_metadata.field_45 , 5);
    modify_field(l2_metadata.field_46 , 1);
    modify_field(l2_metadata.field_47 , 2);
    modify_field(l2_metadata.field_48 , 3);
    modify_field(l2_metadata.field_49 , 4);
    modify_field(l2_metadata.field_50 , 5);
    modify_field(l2_metadata.field_51 , 1);
    modify_field(l2_metadata.field_52 , 2);
    modify_field(l2_metadata.field_53 , 3);
    add_to_field(l2_metadata.field_54 , 4);
    modify_field(l2_metadata.field_55 , 5);
    add_to_field(l2_metadata.field_56 , 1);
    modify_field(l2_metadata.field_57 , 2);
    modify_field(l2_metadata.field_58 , 3);
    add_to_field(l2_metadata.field_59 , -4);
    modify_field(l2_metadata.field_60 , 5);
    modify_field(l2_metadata.lkp_pkt_type ,1);
    modify_field(l2_metadata.lkp_mac_sa ,1);
    modify_field(l2_metadata.lkp_mac_da ,1);
    modify_field(l2_metadata.lkp_mac_type ,1);
    modify_field(l2_metadata.l2_nexthop ,1);
    modify_field(l2_metadata.l2_src_move ,1);
    modify_field(l2_metadata.stp_group ,1);
    modify_field(l2_metadata.stp_state ,1);
    modify_field(l2_metadata.bd_stats_idx ,1);
    modify_field(l2_metadata.learning_enabled ,1);
    modify_field(l2_metadata.same_if_check ,1);
    modify_field(l2_metadata.mac_lmt_dlf ,1);
    modify_field(l2_metadata.mac_lmt_num ,1);
    modify_field(l2_metadata.block_info ,1);
    modify_field(l2_metadata.tpid ,1);
    modify_field(l2_metadata.sit ,1);
    modify_field(l2_metadata.router_bridge ,1);
    modify_field(l2_metadata.is_pritag ,1);
    modify_field(l2_metadata.vlanid ,1);
    modify_field(l2_metadata.addtag ,1);
    modify_field(l2_metadata.ovlaninfo ,1);
    modify_field(l2_metadata.ivlaninfo ,1);
    modify_field(l2_metadata.trunk_en ,1);
    modify_field(l2_metadata.trunk_id ,1);
    modify_field(l2_metadata.sb ,1);
    modify_field(l2_metadata.sp ,1);
    modify_field(l2_metadata.dai_en ,1);
    modify_field(l2_metadata.ns_enable ,1);
    modify_field(l2_metadata.vdc_id ,1);
    modify_field(l2_metadata.new_ovlan_info ,1);
    modify_field(l2_metadata.new_ivlan_info ,1);
    modify_field(l2_metadata.new_tag_num ,1);
    modify_field(l2_metadata.fwd_type ,1);
    modify_field(l2_metadata.tbl_type ,1);
    modify_field(l2_metadata.classid ,1);
    modify_field(l2_metadata.outter_pri_act ,1);
    modify_field(l2_metadata.outter_cfi_act ,1);
    modify_field(l2_metadata.inner_pri_act ,1);
    modify_field(l2_metadata.inner_cfi_act ,1);
    modify_field(l2_metadata.urpf_type ,1);
    modify_field(l2_metadata.vrfid ,1);
    modify_field(l2_metadata.vsi ,1);
    modify_field(l2_metadata.svp ,1);
    modify_field(l2_metadata.dvp ,1);
    modify_field(l2_metadata.vsi_valid ,1);
    modify_field(l2_metadata.vlanswitch_primode ,1);
    modify_field(l2_metadata.vlanswitch_oport ,1);
    modify_field(l2_metadata.vlanlrn_mode ,1);
    modify_field(l2_metadata.vlanlrn_lmt ,1);
    modify_field(l2_metadata.stg_id ,1);
    modify_field(l2_metadata.class_id ,1);
    modify_field(l2_metadata.vlan_mac_lmt_dlf ,1);
    modify_field(l2_metadata.vlan_lmt_num ,1);
    modify_field(l2_metadata.bypass_chk ,1);
    modify_field(l2_metadata.port_bitmap ,1);
    modify_field(l2_metadata.ipv4uc_en ,1);
    modify_field(l2_metadata.ipv4mc_en ,1);
    modify_field(l2_metadata.mplsuc_en ,1);
    modify_field(l2_metadata.mplsmc_en ,1);
    modify_field(l2_metadata.vlanif_vpn ,1);
    modify_field(l2_metadata.trilluc_en ,1);
    modify_field(l2_metadata.vxlane_en ,1);
    modify_field(l2_metadata.nvgre_en ,1);
    modify_field(l2_metadata.vplssogre_en ,1);
    modify_field(l2_metadata.l3gre_en ,1);
    modify_field(l2_metadata.ivsi_ext ,1);
    modify_field(l2_metadata.oport_info ,1);
    modify_field(l2_metadata.trunkid ,1);
    modify_field(l2_metadata.dvp_index ,1);
    modify_field(l2_metadata.be_opcode ,1);
    modify_field(l2_metadata.oport_is_trunk ,1);
    modify_field(l2_metadata.hash_rslt ,1);
    modify_field(l2_metadata.aib_opcode ,1);
    modify_field(l2_metadata.keytype ,1);
    modify_field(l2_metadata.src_vap_user ,1);
    modify_field(l2_metadata.src_trunk_flag ,1);
    modify_field(l2_metadata.outer_tag_pri ,1);
    modify_field(l2_metadata.outer_tag_cfi ,1);
    modify_field(l2_metadata.inner_tag_pri ,1);
    modify_field(l2_metadata.inner_tag_cfi ,1);

 modify_field(l3_metadata.rmac_group , 0);
 modify_field(l3_metadata.rmac_hit , 0);
 modify_field(l3_metadata.urpf_mode , 0);
 modify_field(l3_metadata.urpf_hit , 0);
 modify_field(l3_metadata.urpf_check_fail , 0);
 modify_field(l3_metadata.urpf_bd_group , 0);
 modify_field(l3_metadata.fib_hit , 0);
 modify_field(l3_metadata.fib_nexthop , 0);
 modify_field(l3_metadata.fib_nexthop_type , 0);
 modify_field(l3_metadata.same_bd_check , 0);
 modify_field(l3_metadata.mc , 0);
 modify_field(l3_metadata.l4_pkt_type , 0);
 modify_field(l3_metadata.ipv4_valid , 0);
 modify_field(l3_metadata.tcp_valid , 0);
 modify_field(l3_metadata.udp_valid , 0);
 modify_field(l3_metadata.fragOffSet , 0);

 modify_field(l3_metadata.nexthop_index , 0);

 modify_field(l3_metadata.outer_routed , 0);
 modify_field(l3_metadata.mtu_index , 0);
 modify_field(l3_metadata.l3_mtu_check , 0);
 modify_field(l3_metadata.tunnel_type , 0);
 modify_field(l3_metadata.bc , 0);

 modify_field(l3_metadata.field_1 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_2 , 1);
 modify_field(l3_metadata.field_3 , 1);
 modify_field(l3_metadata.field_4 , 1);
 modify_field(l3_metadata.field_5 , 1);
 modify_field(l3_metadata.field_6 , 1);
 modify_field(l3_metadata.field_7 , 1);
 modify_field(l3_metadata.field_8 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_9 , 1);
 modify_field(l3_metadata.field_10 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_11 , 1);
 modify_field(l3_metadata.field_12 , 1);
 modify_field(l3_metadata.field_13 , 1);
 modify_field(l3_metadata.field_14 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_15 , 1);
 modify_field(l3_metadata.field_16 , 1);
 modify_field(l3_metadata.field_17 , 1);
 modify_field(l3_metadata.field_18 , 1);
 modify_field(l3_metadata.field_19 , 1);
 modify_field(l3_metadata.field_20 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_21 , 1);
 modify_field(l3_metadata.field_22 , 1);
 modify_field(l3_metadata.field_23 , 1);
 modify_field(l3_metadata.field_24 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_25 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_26 , 1);
 modify_field(l3_metadata.field_27 , 1);
 modify_field(l3_metadata.field_28 , 1);
 modify_field(l3_metadata.field_29 , 1);
 modify_field(l3_metadata.field_30 , 1);
 modify_field(l3_metadata.field_31 , 1);
 modify_field(l3_metadata.field_32 , 1);
 modify_field(l3_metadata.field_33 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_34 , 1);
 modify_field(l3_metadata.field_35 , 1);
 modify_field(l3_metadata.field_36 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_37 , 1);
 modify_field(l3_metadata.field_38 , 1);
 modify_field(l3_metadata.field_39 , 1);
 modify_field(l3_metadata.field_40 , 1);
 modify_field(l3_metadata.field_41 , 1);
 modify_field(l3_metadata.field_42 , 1);
 modify_field(l3_metadata.field_43 , 1);
 modify_field(l3_metadata.field_44 , ingress_metadata.drop_flag);
 modify_field(l3_metadata.field_45 , 1);
 modify_field(l3_metadata.field_46 , 1);
 modify_field(l3_metadata.field_47 , 1);
 modify_field(l3_metadata.field_48 , 1);
 modify_field(l3_metadata.field_49 , 1);
 modify_field(l3_metadata.field_50 , 1);
 modify_field(l3_metadata.field_51 , 1);
 modify_field(l3_metadata.field_52 , 1);
 modify_field(l3_metadata.field_53 , 1);
 modify_field(l3_metadata.field_54 , 1);
 modify_field(l3_metadata.field_55 , a);
 modify_field(l3_metadata.field_56 , 1);
 modify_field(l3_metadata.field_57 , b);
 modify_field(l3_metadata.field_58 , 1);
 modify_field(l3_metadata.field_59 , c);
 modify_field(l3_metadata.field_60 , 1);
 modify_field(l3_metadata.field_61 , 1);
 modify_field(l3_metadata.field_62 , 1);
 modify_field(l3_metadata.field_63 , 1);
 modify_field(l3_metadata.field_64 , d);
 modify_field(l3_metadata.field_65 , 1);
 modify_field(l3_metadata.field_66 , 1);
 modify_field(l3_metadata.field_67 , 1);
 modify_field(l3_metadata.field_68 , 1);
 modify_field(l3_metadata.field_69 , 1);
 modify_field(l3_metadata.field_70 , 1);
 modify_field(l3_metadata.field_71 , 1);
 modify_field(l3_metadata.field_72 , 1);
 modify_field(l3_metadata.field_73 , 1);
 modify_field(l3_metadata.field_74 , e);
 modify_field(l3_metadata.field_75 , 1);
 modify_field(l3_metadata.field_76 , 1);
 modify_field(l3_metadata.field_77 , 1);
 modify_field(l3_metadata.field_78 , 1);
 modify_field(l3_metadata.field_79 , a);
 modify_field(l3_metadata.field_80 , 1);
 modify_field(l3_metadata.field_81 , 1);
 modify_field(l3_metadata.field_82 , 1);
 modify_field(l3_metadata.field_83 , 1);
 modify_field(l3_metadata.field_84 , 1);
 modify_field(l3_metadata.field_85 , 1);
 modify_field(l3_metadata.field_86 , 1);
 modify_field(l3_metadata.field_87 , 1);
 modify_field(l3_metadata.field_88 , 1);
 modify_field(l3_metadata.field_89 , f);
 modify_field(l3_metadata.field_90 , 1);
 modify_field(l3_metadata.field_91 , 1);
 modify_field(l3_metadata.field_92 , 1);
 modify_field(l3_metadata.field_93 , 1);
 modify_field(l3_metadata.field_94 , 1);
 modify_field(l3_metadata.field_95 , 1);
 modify_field(l3_metadata.field_96 , 1);
 modify_field(l3_metadata.field_97 , 1);
 modify_field(l3_metadata.field_98 , 1);
 modify_field(l3_metadata.field_99 , 1);
 modify_field(l3_metadata.field_100, 1);
 modify_field(l3_metadata.field_101, 1);
 modify_field(l3_metadata.field_102, 1);
 modify_field(l3_metadata.field_103, 1);
 modify_field(l3_metadata.field_104, 1);
 modify_field(l3_metadata.field_105, 1);
 modify_field(l3_metadata.field_106, 1);
 modify_field(l3_metadata.field_107, 1);
 modify_field(l3_metadata.field_108, 1);
 modify_field(l3_metadata.field_109, 1);
 modify_field(l3_metadata.field_110, 1);
 modify_field(l3_metadata.field_111, 1);
 modify_field(l3_metadata.field_112, 1);
 modify_field(l3_metadata.field_113, 1);
 modify_field(l3_metadata.field_114, 1);
 modify_field(l3_metadata.field_115, b);
 modify_field(l3_metadata.field_116, 1);
 modify_field(l3_metadata.field_117, 1);
 modify_field(l3_metadata.field_118, 1);
 modify_field(l3_metadata.field_119, 1);
 modify_field(l3_metadata.field_120, 1);
 modify_field(l3_metadata.field_121, c);
 modify_field(l3_metadata.field_122, 1);
 modify_field(l3_metadata.field_123, 1);
 modify_field(l3_metadata.field_124, 1);
 modify_field(l3_metadata.field_125, 1);
 modify_field(l3_metadata.field_126, 1);
 modify_field(l3_metadata.field_127, 1);
 modify_field(l3_metadata.field_128, 1);
 modify_field(l3_metadata.field_129, 1);
 modify_field(l3_metadata.field_130, 1);
 modify_field(l3_metadata.field_131, 1);
 modify_field(l3_metadata.field_132, 1);
 modify_field(l3_metadata.field_133, 1);
 modify_field(l3_metadata.field_134, 1);
 modify_field(l3_metadata.field_135, 1);
 modify_field(l3_metadata.field_136, 1);
 modify_field(l3_metadata.field_137, 1);
 modify_field(l3_metadata.field_138, 1);
 modify_field(l3_metadata.field_139, 1);
 modify_field(l3_metadata.field_140, 1);
 modify_field(l3_metadata.field_141, 1);
 modify_field(l3_metadata.field_142, 1);
 modify_field(l3_metadata.field_143, 1);
 modify_field(l3_metadata.field_144, d);
 modify_field(l3_metadata.field_145, 1);
 modify_field(l3_metadata.field_146, 1);
 modify_field(l3_metadata.field_147, 1);
 modify_field(l3_metadata.field_148, 1);
 modify_field(l3_metadata.field_149, 1);
 modify_field(l3_metadata.field_150, 1);
 modify_field(l3_metadata.field_151, 1);
 modify_field(l3_metadata.field_152, 1);
 modify_field(l3_metadata.field_153, e);
 modify_field(l3_metadata.field_154, 1);
 modify_field(l3_metadata.field_155, 1);
 modify_field(l3_metadata.field_156, 1);
 modify_field(l3_metadata.field_157, 1);
 modify_field(l3_metadata.field_158, 1);
 modify_field(l3_metadata.field_159, 1);
 modify_field(l3_metadata.field_160, ingress_metadata.drop_flag);
}

action modify_outer_pri2(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri3(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri4(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri5(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri6(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri7(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri8(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri9(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri10(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri11(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri12(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri13(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri14(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri15(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri16(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri17(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri18(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri19(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

action modify_outer_pri20(a, b, c, d, e, f) {
 modify_outer_pri1(a, b, c, d, e, f);
}

table modify_outer_pri {
 reads {
  ig_intr_md.ingress_port : exact;
 }
 actions {
        modify_outer_pri1;
        modify_outer_pri2;
        modify_outer_pri3;
        modify_outer_pri4;
        modify_outer_pri5;
        modify_outer_pri6;
        modify_outer_pri7;
        modify_outer_pri8;
        modify_outer_pri9;
        modify_outer_pri10;
 }
}

table modify_outer_pri_new1 {
 reads {
  ig_intr_md.ingress_port : exact;
 }
 actions {
        modify_outer_pri1;
        modify_outer_pri2;
        modify_outer_pri3;
        modify_outer_pri4;
        modify_outer_pri5;
        modify_outer_pri6;
        modify_outer_pri7;
        modify_outer_pri8;
        modify_outer_pri9;
        modify_outer_pri11;
        modify_outer_pri12;
        modify_outer_pri13;
        modify_outer_pri14;
        modify_outer_pri15;
        modify_outer_pri16;
        modify_outer_pri17;
        modify_outer_pri18;
        modify_outer_pri19;
 }
}




header_type l2_metadata_t {
    fields {
        lkp_pkt_type : 3;
        lkp_mac_sa : 48;
        lkp_mac_da : 48;
        lkp_mac_type : 16;

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

  mac_lmt_dlf : 2;
        mac_lmt_num : 16;
        block_info : 6;
        block_flag : 1;
        RmtLpbk : 1;
        state1588 : 1;
        vdcid : 1;
        tpid : 16;
        sit : 3;
        router_bridge : 1;
        is_pritag : 1;
        tag1_valid : 1;
        tag2_valid : 1;
        vlanid : 12;
        discard_tag_pkt : 1;
        tag_type : 3;
        addtag : 1;
        ovlaninfo : 16;
        ivlaninfo : 16;
        trunk_en : 1;
        trunk_id : 10;
        sb : 8;
        sp : 8;
        netstat_en : 1;
        voice_vlan_en : 1;
        ipca_link_stat_en : 1;
        ipsg_en : 1;
        v6_fp : 1;
        v6_portal : 1;
        dai_en : 1;
        ns_enable : 1;
        state_1588 : 1;
        vdc_id : 4;
        vlan_acl_en : 1;
        new_ovlan_info : 16;
        new_ivlan_info : 16;
        new_tag_num : 8;
        fwd_type : 3;
        tbl_type : 2;
        classid : 6;
        outter_pri_act : 1;
        outter_cfi_act : 1;
        inner_pri_act : 1;
        inner_cfi_act : 1;
  urpf_type : 3;
  l3_subindex : 12;
        vrfid : 16;
        vsi : 16;
        svp : 16;
        dvp : 16;
        vsi_valid : 1;
        vlanswitch_primode : 1;
        vlanswitch_oport : 16;
        vlanlrn_mode : 1;
        vlanlrn_lmt : 1;
        stg_id : 9;
        class_id : 6;
        vlan_mac_lmt_dlf : 2;
        vlan_lmt_num : 16;
        bypass_chk : 1;
        port_bitmap : 32;
        bmp_status : 1;
        ipv4uc_en : 1;
        ipv4mc_en : 1;
        ipv6uc_en : 1;
        ipv6mc_en : 1;
        mplsuc_en : 1;
        mplsmc_en : 1;
        vlanif_vpn : 1;
        trilluc_en : 1;
        vxlane_en : 1;
        nvgre_en : 1;
        vplssogre_en : 1;
        l3gre_en : 1;
        ivsi_ext : 1;
        oport_info : 16;
        trunkid : 16;
        dvp_index : 16;
      be_opcode : 3;
      oport_is_trunk : 1;
      hash_rslt: 10;
      aib_opcode : 4;
  keytype : 5;
  keytype1 : 5;
  src_vap_user : 1;
  src_trunk_flag : 1;
  outer_tag_pri : 3;
  outer_tag_cfi : 1;
  inner_tag_pri : 3;
  inner_tag_cfi : 1;
  field_1 :2;
        field_2 :2;
        field_3 :2;
        field_4 :2;
        field_5 :4;
        field_6 :4;
        field_7 :4;
        field_8 :4;
        field_9 :4;
        field_10 :4;
        field_11 :4;
        field_12 :4;
        field_13 :4;
        field_14 :4;
        field_15 :4;
        field_16 :4;
        field_17 :4;
        field_18 :4;
        field_19 :4;
        field_20 :4;
        field_21 :4;
        field_22 :4;
        field_23 :4;
        field_24 :4;
        field_25 :4;
        field_26 :4;
        field_27 :4;
        field_28 :4;
        field_29 :4;
        field_30 :4;
        field_31 :4;
        field_32 :4;
        field_33 :4;
        field_34 :4;
        field_35 :4;
        field_36 :4;
        field_37 :4;
        field_38 :4;
        field_39 :4;
        field_40 :4;
        field_41 :4;
        field_42 :4;
        field_43 :4;
        field_44 :4;
        field_45 :4;
        field_46 :4;
        field_47 :4;
        field_48 :4;
        field_49 :4;
        field_50 :4;
        field_51 :4;
        field_52 :4;
        field_53 :4;
        field_54 :4;
        field_55 :4;
        field_56 :4;
        field_57 :4;
        field_58 :4;
        field_59 :4;
        field_60 :4;
    }
}

metadata l2_metadata_t l2_metadata;





action set_stp_state(stp_state) {
    modify_field(l2_metadata.stp_state, stp_state);
}

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

    if (l2_metadata.stp_group != 0) {
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
    size : 65536;
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
    size : 65536;
    support_timeout: true;
}


control process_mac {

    apply(smac);
    apply(dmac);

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
        l2_metadata.lkp_mac_sa mask 0x010000000000 : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l3_metadata.lkp_ip_type : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
        l3_metadata.lkp_ip_version : ternary;
        ipv4_metadata.lkp_ipv4_sa mask 0xFF000000 : ternary;

        ipv6_metadata.lkp_ipv6_sa mask 0xFFFF0000000000000000000000000000 : ternary;

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
    if (ingress_metadata.drop_flag == 0) {
        apply(validate_packet);
    }
}





action set_egress_bd_properties(smac_idx) {
    modify_field(egress_metadata.smac_idx, smac_idx);
}

@pragma ternary 1
table egress_bd_map {
    reads {
        egress_metadata.bd : exact;
    }
    actions {
        nop;
        set_egress_bd_properties;
    }
    size : 4096;
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
        lkp_ip_tc : 8;
        lkp_ip_ttl : 8;
        lkp_l4_sport : 16;
        lkp_l4_dport : 16;
        lkp_inner_l4_sport : 16;
        lkp_inner_l4_dport : 16;

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
        same_bd_check : 16;
        nexthop_index : 16;
        routed : 1;
        outer_routed : 1;
        mtu_index : 8;
        l3_mtu_check : 16 (saturating);

  tunnel_type : 4;
        bc : 1;
        mc : 1;
        l4_pkt_type : 8;
        ipv4_valid : 1;
        tcp_valid : 1;
        udp_valid : 1;
        fragOffSet : 13;

  field_1 : 1;
  field_2 : 1;
  field_3 : 1;
  field_4 : 1;
  field_5 : 1;
  field_6 : 1;
  field_7 : 1;
  field_8 : 1;
  field_9 : 1;
  field_10 : 1;
  field_11 : 1;
  field_12 : 1;
  field_13 : 1;
  field_14 : 1;
  field_15 : 1;
  field_16 : 1;
  field_17 : 1;
  field_18 : 1;
  field_19 : 1;
  field_20 : 1;
  field_21 : 1;
  field_22 : 1;
  field_23 : 1;
  field_24 : 1;
  field_25 : 1;
  field_26 : 1;
  field_27 : 1;
  field_28 : 1;
  field_29 : 1;
  field_30 : 1;
  field_31 : 1;
  field_32 : 1;
  field_33 : 1;
  field_34 : 1;
  field_35 : 1;
  field_36 : 1;
  field_37 : 1;
  field_38 : 1;
  field_39 : 1;
  field_40 : 1;
  field_41 : 1;
  field_42 : 1;
  field_43 : 1;
  field_44 : 1;
  field_45 : 1;
  field_46 : 1;
  field_47 : 1;
  field_48 : 1;
  field_49 : 1;
  field_50 : 1;
  field_51 : 1;
  field_52 : 1;
  field_53 : 1;
  field_54 : 1;
  field_55 : 1;
  field_56 : 1;
  field_57 : 1;
  field_58 : 1;
  field_59 : 1;
  field_60 : 1;
  field_61 : 1;
  field_62 : 1;
  field_63 : 1;
  field_64 : 1;
  field_65 : 1;
  field_66 : 1;
  field_67 : 1;
  field_68 : 1;
  field_69 : 1;
  field_70 : 1;
  field_71 : 1;
  field_72 : 1;
  field_73 : 1;
  field_74 : 1;
  field_75 : 1;
  field_76 : 1;
  field_77 : 1;
  field_78 : 1;
  field_79 : 1;
  field_80 : 1;
  field_81 : 1;
  field_82 : 1;
  field_83 : 1;
  field_84 : 1;
  field_85 : 1;
  field_86 : 1;
  field_87 : 1;
  field_88 : 1;
  field_89 : 1;
  field_90 : 1;
  field_91 : 1;
  field_92 : 1;
  field_93 : 1;
  field_94 : 1;
  field_95 : 1;
  field_96 : 1;
  field_97 : 1;
  field_98 : 1;
  field_99 : 1;
  field_100 : 1;
  field_101 : 1;
  field_102 : 1;
  field_103 : 1;
  field_104 : 1;
  field_105 : 1;
  field_106 : 1;
  field_107 : 1;
  field_108 : 1;
  field_109 : 1;
  field_110 : 1;
  field_111 : 1;
  field_112 : 1;
  field_113 : 1;
  field_114 : 1;
  field_115 : 1;
  field_116 : 1;
  field_117 : 1;
  field_118 : 1;
  field_119 : 1;
  field_120 : 1;
  field_121 : 1;
  field_122 : 1;
  field_123 : 1;
  field_124 : 1;
  field_125 : 1;
  field_126 : 1;
  field_127 : 1;
  field_128 : 1;
  field_129 : 1;
  field_130 : 1;
  field_131 : 1;
  field_132 : 1;
  field_133 : 1;
  field_134 : 1;
  field_135 : 1;
  field_136 : 1;
  field_137 : 1;
  field_138 : 1;
  field_139 : 1;
  field_140 : 1;
  field_141 : 1;
  field_142 : 1;
  field_143 : 1;
  field_144 : 1;
  field_145 : 1;
  field_146 : 1;
  field_147 : 1;
  field_148 : 1;
  field_149 : 1;
  field_150 : 1;
  field_151 : 1;
  field_152 : 1;
  field_153 : 1;
  field_154 : 1;
  field_155 : 1;
  field_156 : 1;
  field_157 : 1;
  field_158 : 1;
  field_159 : 1;
  field_160 : 1;
    }
}

metadata l3_metadata_t l3_metadata;





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

        ipv6 : valid;


        mpls[0] : valid;

        ipv4.dstAddr mask 0xF0000000 : ternary;

        ipv6.dstAddr mask 0xFF000000000000000000000000000000 : ternary;

    }
    actions {
        nop;
        ipv4_unicast_rewrite;

        ipv4_multicast_rewrite;


        ipv6_unicast_rewrite;

        ipv6_multicast_rewrite;



        mpls_rewrite;

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

table mtu {
    reads {
        l3_metadata.mtu_index : exact;
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        mtu_miss;
        ipv4_mtu_check;
        ipv6_mtu_check;
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
    modify_field(l3_metadata.lkp_ip_tc, ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_version, 4);
}

action set_malformed_outer_ipv4_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}

table validate_outer_ipv4_packet {
    reads {
        ipv4.version : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
        ipv4_metadata.lkp_ipv4_sa mask 0xFF000000 : ternary;
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
    size : 65536;
}

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
    size : 8192;
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


@pragma pa_alias ingress ipv4_metadata.lkp_ipv4_sa ipv6_metadata.lkp_ipv6_sa
@pragma pa_alias ingress ipv4_metadata.lkp_ipv4_da ipv6_metadata.lkp_ipv6_da


metadata ipv6_metadata_t ipv6_metadata;





action set_valid_outer_ipv6_packet() {
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(l3_metadata.lkp_ip_tc, ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_version, 6);
}

action set_malformed_outer_ipv6_packet(drop_reason) {
    modify_field(ingress_metadata.drop_flag, 1);
    modify_field(ingress_metadata.drop_reason, drop_reason);
}






table validate_outer_ipv6_packet {
    reads {
        ipv6.version : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
        ipv6_metadata.lkp_ipv6_sa mask 0xFFFF0000000000000000000000000000 : ternary;
    }
    actions {
        set_valid_outer_ipv6_packet;
        set_malformed_outer_ipv6_packet;
    }
    size : 64;
}


control validate_outer_ipv6_header {

    apply(validate_outer_ipv6_packet);

}
table ipv6_fib_lpm {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : lpm;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : 2048;
}






table ipv6_fib {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }
    size : 16384;
}


control process_ipv6_fib {


    apply(ipv6_fib) {
        on_miss {
            apply(ipv6_fib_lpm);
        }
    }

}
control process_ipv6_urpf {
}







header_type tunnel_metadata_t {
    fields {
        ingress_tunnel_type : 5;
        tunnel_vni : 24;
        mpls_enabled : 1;
        mpls_label: 20;
        mpls_exp: 3;
        mpls_ttl: 8;
        egress_tunnel_type : 5;
        tunnel_index: 14;
        tunnel_src_index : 9;
        tunnel_smac_index : 9;
        tunnel_dst_index : 14;
        tunnel_dmac_index : 14;
        vnid : 24;
        tunnel_terminate : 1;
        tunnel_if_check : 1;
        egress_header_count: 4;
    }
}
metadata tunnel_metadata_t tunnel_metadata;





action outer_rmac_hit() {
    modify_field(l3_metadata.rmac_hit, 1);
}

@pragma ternary 1
table outer_rmac {
    reads {
        l3_metadata.rmac_group : exact;
        l2_metadata.lkp_mac_da : exact;
    }
    actions {
        on_miss;
        outer_rmac_hit;
    }
    size : 256;
}






action set_tunnel_termination_flag() {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
}

action src_vtep_hit(ifindex) {
    modify_field(ingress_metadata.ifindex, ifindex);
}


table ipv4_dest_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        nop;
        set_tunnel_termination_flag;
    }
    size : 512;
}

table ipv4_src_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
    }
    actions {
        on_miss;
        src_vtep_hit;
    }
    size : 16384;
}







table ipv6_dest_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        nop;
        set_tunnel_termination_flag;
    }
    size : 512;
}

table ipv6_src_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_sa : exact;
    }
    actions {
        on_miss;
        src_vtep_hit;
    }
    size : 16384;
}



control process_ipv4_vtep {

    apply(ipv4_src_vtep) {
        src_vtep_hit {
            apply(ipv4_dest_vtep);
        }
    }

}

control process_ipv6_vtep {

    apply(ipv6_src_vtep) {
        src_vtep_hit {
            apply(ipv6_dest_vtep);
        }
    }

}






action terminate_tunnel_inner_non_ip(bd, bd_label, stats_idx,
                                     exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.lkp_ip_type, 0);
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}


action terminate_tunnel_inner_ethernet_ipv4(bd, vrf,
        rmac_group, bd_label,
        ipv4_unicast_enabled, ipv4_urpf_mode,
        igmp_snooping_enabled, stats_idx,
        ipv4_multicast_mode, mrpf_group,
        exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);

    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(ipv4_metadata.lkp_ipv4_sa, inner_ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, inner_ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv4.ttl);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action terminate_tunnel_inner_ipv4(vrf, rmac_group,
        ipv4_urpf_mode, ipv4_unicast_enabled,
        ipv4_multicast_mode, mrpf_group) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);

    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(ipv4_metadata.lkp_ipv4_sa, inner_ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, inner_ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv4.ttl);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
}



action terminate_tunnel_inner_ethernet_ipv6(bd, vrf,
        rmac_group, bd_label,
        ipv6_unicast_enabled, ipv6_urpf_mode,
        mld_snooping_enabled, stats_idx,
        ipv6_multicast_mode, mrpf_group,
        exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);

    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(ipv6_metadata.lkp_ipv6_sa, inner_ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, inner_ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv6.hopLimit);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action terminate_tunnel_inner_ipv6(vrf, rmac_group,
        ipv6_unicast_enabled, ipv6_urpf_mode,
        ipv6_multicast_mode, mrpf_group) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);

    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(ipv6_metadata.lkp_ipv6_sa, inner_ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, inner_ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv6.hopLimit);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
}


action tunnel_lookup_miss() {
    modify_field(ig_intr_md_for_tm.mcast_grp_a, 0);
}

table tunnel_miss {
    actions {
        tunnel_lookup_miss;
    }
}




table tunnel {
    reads {
        tunnel_metadata.tunnel_vni : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        tunnel_lookup_miss;
        terminate_tunnel_inner_non_ip;

        terminate_tunnel_inner_ethernet_ipv4;
        terminate_tunnel_inner_ipv4;


        terminate_tunnel_inner_ethernet_ipv6;
        terminate_tunnel_inner_ipv6;

    }
    size : 16384;
}


control process_tunnel {

    if (tunnel_metadata.ingress_tunnel_type != 0) {


        apply(outer_rmac) {
            on_miss {
                process_outer_multicast();
            }
            default {
                if (valid(ipv4)) {
                    process_ipv4_vtep();
                } else {
                    if (valid(ipv6)) {
                        process_ipv6_vtep();
                    } else {

                        if (valid(mpls[0])) {
                            process_mpls();
                        }
                    }
                }
            }
        }
    }


    if ((tunnel_metadata.tunnel_terminate == 1) or
        ((multicast_metadata.outer_mcast_route_hit == 1) and
         (((multicast_metadata.outer_mcast_mode == 1) and
           (multicast_metadata.mcast_rpf_group == 0)) or
          ((multicast_metadata.outer_mcast_mode == 2) and
           (multicast_metadata.mcast_rpf_group != 0))))) {
        apply(tunnel);
    } else {
        apply(tunnel_miss);
    }

}





action set_valid_mpls_label1() {
    modify_field(tunnel_metadata.mpls_label, mpls[0].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[0].exp);
}

action set_valid_mpls_label2() {
    modify_field(tunnel_metadata.mpls_label, mpls[1].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[1].exp);
}

action set_valid_mpls_label3() {
    modify_field(tunnel_metadata.mpls_label, mpls[2].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[2].exp);
}

table validate_mpls_packet {
    reads {
        mpls[0].label : ternary;
        mpls[0].bos : ternary;
        mpls[0] : valid;
        mpls[1].label : ternary;
        mpls[1].bos : ternary;
        mpls[1] : valid;
        mpls[2].label : ternary;
        mpls[2].bos : ternary;
        mpls[2] : valid;
    }
    actions {
        set_valid_mpls_label1;
        set_valid_mpls_label2;
        set_valid_mpls_label3;

    }
    size : 512;
}


control validate_mpls_header {

    apply(validate_mpls_packet);

}





action terminate_eompls(bd, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);

    modify_field(ingress_metadata.bd, bd);
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
}

action terminate_vpls(bd, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
}


action terminate_ipv4_over_mpls(vrf, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);

    modify_field(l3_metadata.vrf, vrf);
    modify_field(l3_metadata.lkp_ip_type, 1);
    modify_field(ipv4_metadata.lkp_ipv4_sa, inner_ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, inner_ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv4.ttl);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}



action terminate_ipv6_over_mpls(vrf, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);

    modify_field(l3_metadata.vrf, vrf);
    modify_field(l3_metadata.lkp_ip_type, 2);
    modify_field(ipv6_metadata.lkp_ipv6_sa, inner_ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, inner_ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv6.hopLimit);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}


action terminate_pw(ifindex) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
}

action forward_mpls(nexthop_index) {
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);
    modify_field(l3_metadata.fib_hit, 1);
}

@pragma ternary 1
table mpls {
    reads {
        tunnel_metadata.mpls_label: exact;
        inner_ipv4: valid;
        inner_ipv6: valid;
    }
    actions {
        terminate_eompls;
        terminate_vpls;

        terminate_ipv4_over_mpls;


        terminate_ipv6_over_mpls;

        terminate_pw;
        forward_mpls;
    }
    size : 4096;
}


control process_mpls {

    apply(mpls);

}






action decap_vxlan_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(vxlan);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_vxlan_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_vxlan_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(ipv6);
}

action decap_genv_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(genv);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_genv_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(genv);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_genv_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(genv);
    remove_header(ipv4);
    remove_header(ipv6);
}

action decap_nvgre_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_nvgre_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_nvgre_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(ipv6);
}

action decap_ip_inner_ipv4() {
    copy_header(ipv4, inner_ipv4);
    remove_header(gre);
    remove_header(ipv6);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, 0x0800);
}

action decap_ip_inner_ipv6() {
    copy_header(ipv6, inner_ipv6);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, 0x86dd);
}


action decap_mpls_inner_ipv4_pop1() {
    remove_header(mpls[0]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, 0x0800);
}

action decap_mpls_inner_ipv6_pop1() {
    remove_header(mpls[0]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, 0x86dd);
}

action decap_mpls_inner_ethernet_ipv4_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}

action decap_mpls_inner_ipv4_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, 0x0800);
}

action decap_mpls_inner_ipv6_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, 0x86dd);
}

action decap_mpls_inner_ethernet_ipv4_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}

action decap_mpls_inner_ipv4_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, 0x0800);
}

action decap_mpls_inner_ipv6_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, 0x86dd);
}

action decap_mpls_inner_ethernet_ipv4_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}


table tunnel_decap_process_outer {
    reads {
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        decap_vxlan_inner_ipv4;
        decap_vxlan_inner_ipv6;
        decap_vxlan_inner_non_ip;
        decap_genv_inner_ipv4;
        decap_genv_inner_ipv6;
        decap_genv_inner_non_ip;
        decap_nvgre_inner_ipv4;
        decap_nvgre_inner_ipv6;
        decap_nvgre_inner_non_ip;
        decap_ip_inner_ipv4;
        decap_ip_inner_ipv6;

        decap_mpls_inner_ipv4_pop1;
        decap_mpls_inner_ipv6_pop1;
        decap_mpls_inner_ethernet_ipv4_pop1;
        decap_mpls_inner_ethernet_ipv6_pop1;
        decap_mpls_inner_ethernet_non_ip_pop1;
        decap_mpls_inner_ipv4_pop2;
        decap_mpls_inner_ipv6_pop2;
        decap_mpls_inner_ethernet_ipv4_pop2;
        decap_mpls_inner_ethernet_ipv6_pop2;
        decap_mpls_inner_ethernet_non_ip_pop2;
        decap_mpls_inner_ipv4_pop3;
        decap_mpls_inner_ipv6_pop3;
        decap_mpls_inner_ethernet_ipv4_pop3;
        decap_mpls_inner_ethernet_ipv6_pop3;
        decap_mpls_inner_ethernet_non_ip_pop3;

    }
    size : 512;
}




action decap_inner_udp() {
    copy_header(udp, inner_udp);
    remove_header(inner_udp);
}

action decap_inner_tcp() {
    add_header(tcp);
    remove_header(inner_tcp);
    remove_header(udp);
}

action decap_inner_icmp() {
    copy_header(icmp, inner_icmp);
    remove_header(inner_icmp);
    remove_header(udp);
}

action decap_inner_unknown() {
    remove_header(udp);
}

table tunnel_decap_process_inner {
    reads {
        inner_tcp : valid;
        inner_udp : valid;
        inner_icmp : valid;
    }
    actions {
        decap_inner_udp;
        decap_inner_tcp;
        decap_inner_icmp;
        decap_inner_unknown;
    }
    size : 512;
}






control process_tunnel_decap {

    if (tunnel_metadata.tunnel_terminate == 1) {
        if ((multicast_metadata.inner_replica == 1) or
            (multicast_metadata.replica == 0)) {
            apply(tunnel_decap_process_outer);
            apply(tunnel_decap_process_inner);
        }
    }

}






action set_egress_tunnel_vni(vnid) {
    modify_field(tunnel_metadata.vnid, vnid);
}

table egress_vni {
    reads {
        egress_metadata.bd : exact;
        tunnel_metadata.egress_tunnel_type: exact;
    }
    actions {
        nop;
        set_egress_tunnel_vni;
    }
    size: 16384;
}





action inner_ipv4_udp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_udp, udp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(udp);
    remove_header(ipv4);
}

action inner_ipv4_tcp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    add_header(inner_tcp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(tcp);
    remove_header(ipv4);
}

action inner_ipv4_icmp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_icmp, icmp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(icmp);
    remove_header(ipv4);
}

action inner_ipv4_unknown_rewrite() {
    copy_header(inner_ipv4, ipv4);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(ipv4);
}

action inner_ipv6_udp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_udp, udp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
}

action inner_ipv6_tcp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    add_header(inner_tcp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(tcp);
    remove_header(ipv6);
}

action inner_ipv6_icmp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_icmp, icmp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(icmp);
    remove_header(ipv6);
}

action inner_ipv6_unknown_rewrite() {
    copy_header(inner_ipv6, ipv6);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
}

action inner_non_ip_rewrite() {



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
        inner_ipv6_udp_rewrite;
        inner_ipv6_tcp_rewrite;
        inner_ipv6_icmp_rewrite;
        inner_ipv6_unknown_rewrite;
        inner_non_ip_rewrite;
    }
    size : 256;
}





action f_insert_vxlan_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(udp);
    add_header(vxlan);

    modify_field(udp.srcPort, hash_metadata.entropy_hash);
    modify_field(udp.dstPort, 4789);
    modify_field(udp.checksum, 0);
    add(udp.length_, egress_metadata.payload_length, 30);

    modify_field(vxlan.flags, 0x8);
    modify_field(vxlan.reserved, 0);
    modify_field(vxlan.vni, tunnel_metadata.vnid);
    modify_field(vxlan.reserved2, 0);
}

action f_insert_ipv4_header(proto) {
    add_header(ipv4);
    modify_field(ipv4.protocol, proto);
    modify_field(ipv4.ttl, 64);
    modify_field(ipv4.version, 0x4);
    modify_field(ipv4.ihl, 0x5);
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

action ipv4_vxlan_rewrite() {
    f_insert_vxlan_header();
    f_insert_ipv4_header(17);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv6_vxlan_rewrite() {
    f_insert_vxlan_header();
    f_insert_ipv6_header(17);
    add(ipv6.payloadLen, egress_metadata.payload_length, 30);
    modify_field(ethernet.etherType, 0x86dd);
}

action f_insert_genv_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(udp);
    add_header(genv);

    modify_field(udp.srcPort, hash_metadata.entropy_hash);
    modify_field(udp.dstPort, 6081);
    modify_field(udp.checksum, 0);
    add(udp.length_, egress_metadata.payload_length, 30);

    modify_field(genv.ver, 0);
    modify_field(genv.oam, 0);
    modify_field(genv.critical, 0);
    modify_field(genv.optLen, 0);
    modify_field(genv.protoType, 0x6558);
    modify_field(genv.vni, tunnel_metadata.vnid);
    modify_field(genv.reserved, 0);
    modify_field(genv.reserved2, 0);
}

action ipv4_genv_rewrite() {
    f_insert_genv_header();
    f_insert_ipv4_header(17);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv6_genv_rewrite() {
    f_insert_genv_header();
    f_insert_ipv6_header(17);
    add(ipv6.payloadLen, egress_metadata.payload_length, 30);
    modify_field(ethernet.etherType, 0x86dd);
}

action f_insert_nvgre_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(gre);
    add_header(nvgre);
    modify_field(gre.proto, 0x6558);
    modify_field(gre.recurse, 0);
    modify_field(gre.flags, 0);
    modify_field(gre.ver, 0);
    modify_field(gre.R, 0);
    modify_field(gre.K, 1);
    modify_field(gre.C, 0);
    modify_field(gre.S, 0);
    modify_field(gre.s, 0);
    modify_field(nvgre.tni, tunnel_metadata.vnid);
    modify_field(nvgre.flow_id, hash_metadata.entropy_hash, 0xFF);
}

action ipv4_nvgre_rewrite() {
    f_insert_nvgre_header();
    f_insert_ipv4_header(47);
    add(ipv4.totalLen, egress_metadata.payload_length, 42);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv6_nvgre_rewrite() {
    f_insert_nvgre_header();
    f_insert_ipv6_header(47);
    add(ipv6.payloadLen, egress_metadata.payload_length, 22);
    modify_field(ethernet.etherType, 0x86dd);
}

action f_insert_gre_header() {
    add_header(gre);
}

action ipv4_gre_rewrite() {
    f_insert_gre_header();
    modify_field(gre.proto, ethernet.etherType);
    f_insert_ipv4_header(47);
    add(ipv4.totalLen, egress_metadata.payload_length, 38);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv6_gre_rewrite() {
    f_insert_gre_header();
    modify_field(gre.proto, 0x0800);
    f_insert_ipv6_header(47);
    add(ipv6.payloadLen, egress_metadata.payload_length, 18);
    modify_field(ethernet.etherType, 0x86dd);
}

action ipv4_ipv4_rewrite() {
    f_insert_ipv4_header(4);
    add(ipv4.totalLen, egress_metadata.payload_length, 20);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv4_ipv6_rewrite() {
    f_insert_ipv4_header(41);
    add(ipv4.totalLen, egress_metadata.payload_length, 40);
    modify_field(ethernet.etherType, 0x0800);
}

action ipv6_ipv4_rewrite() {
    f_insert_ipv6_header(4);
    add(ipv6.payloadLen, egress_metadata.payload_length, 20);
    modify_field(ethernet.etherType, 0x86dd);
}

action ipv6_ipv6_rewrite() {
    f_insert_ipv6_header(41);
    add(ipv6.payloadLen, egress_metadata.payload_length, 40);
    modify_field(ethernet.etherType, 0x86dd);
}

action f_insert_erspan_t3_header() {
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
    modify_field(erspan_t3_header.sgt_other, 0);
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


action mpls_ethernet_push1_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 1);
    modify_field(ethernet.etherType, 0x8847);
}

action mpls_ip_push1_rewrite() {
    push(mpls, 1);
    modify_field(ethernet.etherType, 0x8847);
}

action mpls_ethernet_push2_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 2);
    modify_field(ethernet.etherType, 0x8847);
}

action mpls_ip_push2_rewrite() {
    push(mpls, 2);
    modify_field(ethernet.etherType, 0x8847);
}

action mpls_ethernet_push3_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 3);
    modify_field(ethernet.etherType, 0x8847);
}

action mpls_ip_push3_rewrite() {
    push(mpls, 3);
    modify_field(ethernet.etherType, 0x8847);
}


table tunnel_encap_process_outer {
    reads {
        tunnel_metadata.egress_tunnel_type : exact;
        tunnel_metadata.egress_header_count : exact;
        multicast_metadata.replica : exact;
    }
    actions {
        nop;
        ipv4_vxlan_rewrite;
        ipv6_vxlan_rewrite;
        ipv4_genv_rewrite;
        ipv6_genv_rewrite;
        ipv4_nvgre_rewrite;
        ipv6_nvgre_rewrite;
        ipv4_gre_rewrite;
        ipv6_gre_rewrite;
        ipv4_ipv4_rewrite;
        ipv4_ipv6_rewrite;
        ipv6_ipv4_rewrite;
        ipv6_ipv6_rewrite;
        ipv4_erspan_t3_rewrite;
        ipv6_erspan_t3_rewrite;

        mpls_ethernet_push1_rewrite;
        mpls_ip_push1_rewrite;
        mpls_ethernet_push2_rewrite;
        mpls_ip_push2_rewrite;
        mpls_ethernet_push3_rewrite;
        mpls_ip_push3_rewrite;

        fabric_rewrite;
    }
    size : 256;
}





action set_tunnel_rewrite_details(outer_bd, smac_idx, dmac_idx,
                                  sip_index, dip_index) {
    modify_field(egress_metadata.outer_bd, outer_bd);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
    modify_field(tunnel_metadata.tunnel_src_index, sip_index);
    modify_field(tunnel_metadata.tunnel_dst_index, dip_index);
}


action set_mpls_rewrite_push1(label1, exp1, ttl1, smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].bos, 0x1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}

action set_mpls_rewrite_push2(label1, exp1, ttl1, label2, exp2, ttl2,
                              smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(mpls[0].bos, 0x0);
    modify_field(mpls[1].label, label2);
    modify_field(mpls[1].exp, exp2);
    modify_field(mpls[1].ttl, ttl2);
    modify_field(mpls[1].bos, 0x1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}

action set_mpls_rewrite_push3(label1, exp1, ttl1, label2, exp2, ttl2,
                              label3, exp3, ttl3, smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(mpls[0].bos, 0x0);
    modify_field(mpls[1].label, label2);
    modify_field(mpls[1].exp, exp2);
    modify_field(mpls[1].ttl, ttl2);
    modify_field(mpls[1].bos, 0x0);
    modify_field(mpls[2].label, label3);
    modify_field(mpls[2].exp, exp3);
    modify_field(mpls[2].ttl, ttl3);
    modify_field(mpls[2].bos, 0x1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}


table tunnel_rewrite {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        nop;
        set_tunnel_rewrite_details;

        set_mpls_rewrite_push1;
        set_mpls_rewrite_push2;
        set_mpls_rewrite_push3;

        cpu_rx_rewrite;






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


action rewrite_tunnel_ipv6_src(ip) {
    modify_field(ipv6.srcAddr, ip);
}


table tunnel_src_rewrite {
    reads {
        tunnel_metadata.tunnel_src_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_src;

        rewrite_tunnel_ipv6_src;

    }
    size : 512;
}





action rewrite_tunnel_ipv4_dst(ip) {
    modify_field(ipv4.dstAddr, ip);
}


action rewrite_tunnel_ipv6_dst(ip) {
    modify_field(ipv6.dstAddr, ip);
}


table tunnel_dst_rewrite {
    reads {
        tunnel_metadata.tunnel_dst_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_dst;

        rewrite_tunnel_ipv6_dst;

    }
    size : 16384;
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

        apply(egress_vni);


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
        acl_copy : 1;
        racl_deny : 1;
        acl_nexthop : 16;
        racl_nexthop : 16;
        acl_nexthop_type : 1;
        racl_nexthop_type : 1;
        acl_redirect : 1;
        racl_redirect : 1;
        if_label : 15;
        bd_label : 16;
        mirror_session_id : 10;
        acl_stats_index : 32;
    }
}
header_type qos_metadata_t {
    fields {
        outer_dscp : 8;
        marked_cos : 3;
        marked_dscp : 8;
        marked_exp : 3;
    }
}

header_type i2e_metadata_t {
    fields {
        ingress_tstamp : 32;
        mirror_session_id : 16;
    }
}

header_type coal_sample_hdr_t {

    fields {
        id: 32;
    }
}
header coal_sample_hdr_t coal_sample_hdr;

@pragma pa_solitary ingress acl_metadata.if_label
@pragma pa_atomic ingress acl_metadata.if_label

metadata acl_metadata_t acl_metadata;
metadata qos_metadata_t qos_metadata;
metadata i2e_metadata_t i2e_metadata;





action acl_deny(acl_stats_index, acl_meter_index, acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.acl_deny, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

action acl_permit(acl_stats_index, acl_meter_index, acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

field_list i2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}

field_list e2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}

action acl_mirror(session_id, acl_stats_index, acl_meter_index) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
}

action acl_redirect_nexthop(nexthop_index, acl_stats_index, acl_meter_index,
                            acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.acl_redirect, 1);
    modify_field(acl_metadata.acl_nexthop, nexthop_index);
    modify_field(acl_metadata.acl_nexthop_type, 0);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

action acl_redirect_ecmp(ecmp_index, acl_stats_index, acl_meter_index,
                         acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.acl_redirect, 1);
    modify_field(acl_metadata.acl_nexthop, ecmp_index);
    modify_field(acl_metadata.acl_nexthop_type, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
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
        acl_mirror;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
    }
    size : 512;
}


control process_mac_acl {

    apply(mac_acl);

}





table ip_acl {
    reads {
        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;

        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_sport : ternary;
        l3_metadata.lkp_l4_dport : ternary;

        tcp.flags : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
    }
    actions {
        nop;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
    }
    size : 1024;
}







table ipv6_acl {
    reads {
        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;

        ipv6_metadata.lkp_ipv6_sa : ternary;
        ipv6_metadata.lkp_ipv6_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_sport : ternary;
        l3_metadata.lkp_l4_dport : ternary;

        tcp.flags : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
    }
    actions {
        nop;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
    }
    size : 512;
}






control process_ip_acl {

    if (l3_metadata.lkp_ip_type == 1) {

        apply(ip_acl);

    } else {
        if (l3_metadata.lkp_ip_type == 2) {

            apply(ipv6_acl);

        }
    }

}
control process_qos {



}






action racl_deny(acl_stats_index, acl_meter_index, acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.racl_deny, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

action racl_permit(acl_stats_index, acl_meter_index,
                   acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

action racl_set_nat_mode(nat_mode, acl_stats_index, acl_meter_index) {
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
}

action racl_redirect_nexthop(nexthop_index, acl_stats_index, acl_meter_index,
                             acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, nexthop_index);
    modify_field(acl_metadata.racl_nexthop_type, 0);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}

action racl_redirect_ecmp(ecmp_index, acl_stats_index, acl_meter_index,
                          acl_copy, acl_copy_reason) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, ecmp_index);
    modify_field(acl_metadata.racl_nexthop_type, 1);
    modify_field(acl_metadata.acl_stats_index, acl_stats_index);
    modify_field(meter_metadata.meter_index, acl_meter_index);
    modify_field(acl_metadata.acl_copy, acl_copy);
    modify_field(fabric_metadata.reason_code, acl_copy_reason);
}







table ipv4_racl {
    reads {
        acl_metadata.bd_label : ternary;

        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_sport : ternary;
        l3_metadata.lkp_l4_dport : ternary;
    }
    actions {
        nop;
        racl_deny;
        racl_permit;
        racl_set_nat_mode;
        racl_redirect_nexthop;
        racl_redirect_ecmp;
    }
    size : 1024;
}


control process_ipv4_racl {

    apply(ipv4_racl);

}






table ipv6_racl {
    reads {
        acl_metadata.bd_label : ternary;

        ipv6_metadata.lkp_ipv6_sa : ternary;
        ipv6_metadata.lkp_ipv6_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_sport : ternary;
        l3_metadata.lkp_l4_dport : ternary;
    }
    actions {
        nop;
        racl_deny;
        racl_permit;
        racl_set_nat_mode;
        racl_redirect_nexthop;
        racl_redirect_ecmp;
    }
    size : 512;
}


control process_ipv6_racl {

    apply(ipv6_racl);

}




counter acl_stats {
    type : packets_and_bytes;
    instance_count : 8192;
}

action acl_stats_update() {
    count(acl_stats, acl_metadata.acl_stats_index);
}

table acl_stats {
    reads {
        acl_metadata.acl_stats_index : exact;
    }
    actions {
        acl_stats_update;
    }
    size : 8192;
}

control process_ingress_acl_stats {

    apply(acl_stats);

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
    ingress_metadata.ifindex;
    ingress_metadata.drop_reason;
}

action negative_mirror(session_id) {
    clone_ingress_pkt_to_egress(session_id, mirror_info);
    drop();
}

action redirect_to_cpu(reason_code) {
    copy_to_cpu(reason_code);
    drop();



}

field_list cpu_info {
    ingress_metadata.bd;
    ingress_metadata.ifindex;
    fabric_metadata.reason_code;
    ingress_metadata.ingress_port;
}

action copy_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
    clone_ingress_pkt_to_egress(250, cpu_info);
}

action acl_copy_to_cpu() {
    clone_ingress_pkt_to_egress(250, cpu_info);
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


        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l2_metadata.lkp_mac_type : ternary;

        ingress_metadata.ifindex : ternary;


        l2_metadata.port_vlan_mapping_miss : ternary;
        security_metadata.ipsg_check_fail : ternary;
        security_metadata.storm_control_color : ternary;
        acl_metadata.acl_deny : ternary;
        acl_metadata.racl_deny: ternary;
        acl_metadata.acl_copy : ternary;
        l3_metadata.urpf_check_fail : ternary;
        ingress_metadata.drop_flag : ternary;

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

    }
    actions {
        nop;
        redirect_to_cpu;
        copy_to_cpu;
        acl_copy_to_cpu;
        drop_packet;
        drop_packet_with_reason;
        negative_mirror;
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
    apply(system_acl);
    if (ingress_metadata.drop_flag == 1) {
        apply(drop_stats);
    }
}





action egress_mirror(session_id) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_egress_pkt_to_egress(session_id, e2e_mirror_info);
}

action egress_mirror_drop(session_id) {


    egress_mirror(session_id);
    drop();
}

action egress_redirect_to_cpu(reason_code) {
    egress_copy_to_cpu(reason_code);
    drop();
}

action egress_copy_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
    clone_egress_pkt_to_egress(250, cpu_info);
}


action egress_mirror_coal_hdr(session_id, id) {
}

table egress_acl {
    reads {
        eg_intr_md.egress_port : ternary;
        eg_intr_md.deflection_flag : ternary;
        l3_metadata.l3_mtu_check : ternary;
    }
    actions {
        nop;
        egress_mirror;
        egress_mirror_drop;
        egress_redirect_to_cpu;
        egress_mirror_coal_hdr;
    }
    size : 1024;
}


control process_egress_acl {

    if (egress_metadata.bypass == 0) {
        apply(egress_acl);
    }

}




header_type nat_metadata_t {
    fields {
        ingress_nat_mode : 2;
        egress_nat_mode : 2;
        nat_nexthop : 16;
        nat_hit : 1;
        nat_rewrite_index : 16;
    }
}

metadata nat_metadata_t nat_metadata;
control process_nat {
}
control process_egress_nat {
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
        ipv4_multicast_mode : 2;
        ipv6_multicast_mode : 2;
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

metadata multicast_metadata_t multicast_metadata;





action outer_multicast_rpf_check_pass() {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(l3_metadata.outer_routed, 1);
}

table outer_multicast_rpf {
    reads {
        multicast_metadata.mcast_rpf_group : exact;
        multicast_metadata.bd_mrpf_group : exact;
    }
    actions {
        nop;
        outer_multicast_rpf_check_pass;
    }
    size : 512;
}


control process_outer_multicast_rpf {






}






action outer_multicast_bridge_star_g_hit(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mc_index);
    modify_field(tunnel_metadata.tunnel_terminate, 1);



}

action outer_multicast_bridge_s_g_hit(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mc_index);
    modify_field(tunnel_metadata.tunnel_terminate, 1);



}

action outer_multicast_route_sm_star_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.outer_mcast_mode, 1);
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mc_index);
    modify_field(multicast_metadata.outer_mcast_route_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);



}

action outer_multicast_route_bidir_star_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.outer_mcast_mode, 2);
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mc_index);
    modify_field(multicast_metadata.outer_mcast_route_hit, 1);

    bit_or(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
           multicast_metadata.bd_mrpf_group);






}

action outer_multicast_route_s_g_hit(mc_index, mcast_rpf_group) {
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mc_index);
    modify_field(multicast_metadata.outer_mcast_route_hit, 1);
    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);



}






table outer_ipv4_multicast_star_g {
    reads {
        multicast_metadata.ipv4_mcast_key_type : exact;
        multicast_metadata.ipv4_mcast_key : exact;
        ipv4_metadata.lkp_ipv4_da : ternary;
    }
    actions {
        nop;
        outer_multicast_route_sm_star_g_hit;
        outer_multicast_route_bidir_star_g_hit;
        outer_multicast_bridge_star_g_hit;
    }
    size : 512;
}

table outer_ipv4_multicast {
    reads {
        multicast_metadata.ipv4_mcast_key_type : exact;
        multicast_metadata.ipv4_mcast_key : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        nop;
        on_miss;
        outer_multicast_route_s_g_hit;
        outer_multicast_bridge_s_g_hit;
    }
    size : 1024;
}


control process_outer_ipv4_multicast {


    apply(outer_ipv4_multicast) {
        on_miss {
            apply(outer_ipv4_multicast_star_g);
        }
    }

}





table outer_ipv6_multicast_star_g {
    reads {
        multicast_metadata.ipv6_mcast_key_type : exact;
        multicast_metadata.ipv6_mcast_key : exact;
        ipv6_metadata.lkp_ipv6_da : ternary;
    }
    actions {
        nop;
        outer_multicast_route_sm_star_g_hit;
        outer_multicast_route_bidir_star_g_hit;
        outer_multicast_bridge_star_g_hit;
    }
    size : 512;
}

table outer_ipv6_multicast {
    reads {
        multicast_metadata.ipv6_mcast_key_type : exact;
        multicast_metadata.ipv6_mcast_key : exact;
        ipv6_metadata.lkp_ipv6_sa : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        nop;
        on_miss;
        outer_multicast_route_s_g_hit;
        outer_multicast_bridge_s_g_hit;
    }
    size : 1024;
}


control process_outer_ipv6_multicast {


    apply(outer_ipv6_multicast) {
        on_miss {
            apply(outer_ipv6_multicast_star_g);
        }
    }

}





control process_outer_multicast {

    if (valid(ipv4)) {
        process_outer_ipv4_multicast();
    } else {
        if (valid(ipv6)) {
            process_outer_ipv6_multicast();
        }
    }
    process_outer_multicast_rpf();

}





action multicast_rpf_check_pass() {
    modify_field(l3_metadata.routed, 1);
}

action multicast_rpf_check_fail() {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, 0);
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
    size : 32768;
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

table ipv4_multicast_route_star_g {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        nop;
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


    apply(ipv4_multicast_bridge) {
        on_miss {
            apply(ipv4_multicast_bridge_star_g);
        }
    }
    if (multicast_metadata.ipv4_multicast_mode != 0) {
        apply(ipv4_multicast_route) {
            on_miss {
                apply(ipv4_multicast_route_star_g);
            }
        }
    }

}





table ipv6_multicast_bridge_star_g {
    reads {
        ingress_metadata.bd : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        nop;
        multicast_bridge_star_g_hit;
    }
    size : 512;
}

table ipv6_multicast_bridge {
    reads {
        ingress_metadata.bd : exact;
        ipv6_metadata.lkp_ipv6_sa : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        on_miss;
        multicast_bridge_s_g_hit;
    }
    size : 512;
}

table ipv6_multicast_route_star_g {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        nop;
        multicast_route_sm_star_g_hit;
        multicast_route_bidir_star_g_hit;
    }
    size : 512;
}

table ipv6_multicast_route {
    reads {
        l3_metadata.vrf : exact;
        ipv6_metadata.lkp_ipv6_sa : exact;
        ipv6_metadata.lkp_ipv6_da : exact;
    }
    actions {
        on_miss;
        multicast_route_s_g_hit;
    }
    size : 512;
}


control process_ipv6_multicast {

    apply(ipv6_multicast_bridge) {
        on_miss {
            apply(ipv6_multicast_bridge_star_g);
        }
    }
    if (multicast_metadata.ipv6_multicast_mode != 0) {
        apply(ipv6_multicast_route) {
            on_miss {
                apply(ipv6_multicast_route_star_g);
            }
        }
    }

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
}

action set_acl_redirect_action() {
    modify_field(l3_metadata.nexthop_index, acl_metadata.acl_nexthop);
    modify_field(nexthop_metadata.nexthop_type, acl_metadata.acl_nexthop_type);
}

action set_racl_redirect_action() {
    modify_field(l3_metadata.nexthop_index, acl_metadata.racl_nexthop);
    modify_field(nexthop_metadata.nexthop_type, acl_metadata.racl_nexthop_type);
    modify_field(l3_metadata.routed, 1);
}

action set_fib_redirect_action() {
    modify_field(l3_metadata.nexthop_index, l3_metadata.fib_nexthop);
    modify_field(nexthop_metadata.nexthop_type, l3_metadata.fib_nexthop_type);
    modify_field(l3_metadata.routed, 1);
    modify_field(ig_intr_md_for_tm.mcast_grp_b, 0);



}

action set_nat_redirect_action() {
    modify_field(l3_metadata.nexthop_index, nat_metadata.nat_nexthop);
    modify_field(nexthop_metadata.nexthop_type, 0);
    modify_field(l3_metadata.routed, 1);
}

action set_cpu_redirect_action() {
    modify_field(l3_metadata.routed, 0);
    modify_field(ig_intr_md_for_tm.mcast_grp_b, 0);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 64);
    modify_field(ingress_metadata.egress_ifindex, 0);



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
    modify_field(ingress_metadata.drop_reason, 44);
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
    apply(fwd_result);
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
    size : 43000;
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

action set_l3_rewrite(bd, mtu_index, dmac) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(l3_metadata.mtu_index, mtu_index);
}
action set_mpls_swap_push_rewrite_l2(label, tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(mpls[0].label, label);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 13);
}

action set_mpls_push_rewrite_l2(tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 13);
}

action set_mpls_swap_push_rewrite_l3(bd, dmac,
                                     label, tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(mpls[0].label, label);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 14);
}

action set_mpls_push_rewrite_l3(bd, dmac,
                                tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 14);
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

        set_mpls_swap_push_rewrite_l2;
        set_mpls_push_rewrite_l2;
        set_mpls_swap_push_rewrite_l3;
        set_mpls_push_rewrite_l3;
    }
    size : 43000;
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

        ipv6.dstAddr mask 0xFF000000000000000000000000000000 : ternary;

    }
    actions {
        nop;
        rewrite_ipv4_multicast;

        rewrite_ipv6_multicast;

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
        storm_control_color : 1;
        ipsg_enabled : 1;
        ipsg_check_fail : 1;
    }
}

metadata security_metadata_t security_metadata;






counter storm_control_counter {
    type : bytes;
    direct : storm_control_stats;
}

table storm_control_stats {
    reads {
        security_metadata.storm_control_color : exact;
        ingress_metadata.ingress_port: exact;
    }
    actions {
        nop;
    }
    size: 8;
}
action set_storm_control_meter(meter_idx) {




}

table storm_control {
    reads {
        ingress_metadata.ingress_port : exact;
        l2_metadata.lkp_pkt_type : ternary;
    }
    actions {
        nop;
        set_storm_control_meter;
    }
    size : 512;
}


control process_storm_control {

    apply(storm_control);

}

control process_storm_control_stats {

    apply(storm_control_stats);

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
action terminate_inner_ethernet_non_ip_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
}

action terminate_inner_ethernet_ipv4_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(ipv4_metadata.lkp_ipv4_sa, inner_ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, inner_ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv4.protocol);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}

action terminate_inner_ipv4_over_fabric() {
    modify_field(ipv4_metadata.lkp_ipv4_sa, inner_ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, inner_ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, inner_ipv4.ttl);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}

action terminate_inner_ethernet_ipv6_over_fabric() {
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(ipv6_metadata.lkp_ipv6_sa, inner_ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, inner_ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv6.nextHdr);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}

action terminate_inner_ipv6_over_fabric() {
    modify_field(ipv6_metadata.lkp_ipv6_sa, inner_ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, inner_ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, inner_ipv6.nextHdr);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_inner_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_inner_l4_dport);
}

table tunneled_packet_over_fabric {
    reads {
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        terminate_inner_ethernet_non_ip_over_fabric;
        terminate_inner_ethernet_ipv4_over_fabric;
        terminate_inner_ipv4_over_fabric;

        terminate_inner_ethernet_ipv6_over_fabric;
        terminate_inner_ipv6_over_fabric;

    }
    size : 1024;
}




control process_ingress_fabric {
    apply(fabric_ingress_dst_lkp);
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




action set_mirror_nhop(nhop_idx) {
    modify_field(l3_metadata.nexthop_index, nhop_idx);
}

action set_mirror_bd(bd) {
    modify_field(egress_metadata.bd, bd);
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
control process_int_endpoint {
}
control process_int_insertion {
}
control process_int_outer_encap {





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
    modify_field_with_hash_based_offset(hash_metadata.hash2, 0,
                                        lkp_ipv4_hash2, 65536);
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




    modify_field_with_hash_based_offset(hash_metadata.hash2, 0,
                                        lkp_ipv6_hash2, 65536);
}

field_list lkp_non_ip_hash2_fields {
    ingress_metadata.ifindex;
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
}

field_list_calculation lkp_non_ip_hash2 {
    input {
        lkp_non_ip_hash2_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action compute_lkp_non_ip_hash() {
    modify_field_with_hash_based_offset(hash_metadata.hash2, 0,
                                        lkp_non_ip_hash2, 65536);
}

table compute_ipv4_hashes {

    reads {
        ingress_metadata.drop_flag : exact;
    }

    actions {
        compute_lkp_ipv4_hash;
    }
}

table compute_ipv6_hashes {

    reads {
        ingress_metadata.drop_flag : exact;
    }

    actions {
        compute_lkp_ipv6_hash;
    }
}

table compute_non_ip_hashes {

    reads {
        ingress_metadata.drop_flag : exact;
    }

    actions {
        compute_lkp_non_ip_hash;
    }
}

action computed_two_hashes() {
    modify_field(ig_intr_md_for_tm.level1_mcast_hash, hash_metadata.hash1);
    modify_field(ig_intr_md_for_tm.level2_mcast_hash, hash_metadata.hash2);
    modify_field(hash_metadata.entropy_hash, hash_metadata.hash2);
}

action computed_one_hash() {
    modify_field(hash_metadata.hash1, hash_metadata.hash2);
    modify_field(ig_intr_md_for_tm.level1_mcast_hash, hash_metadata.hash2);
    modify_field(ig_intr_md_for_tm.level2_mcast_hash, hash_metadata.hash2);
    modify_field(hash_metadata.entropy_hash, hash_metadata.hash2);
}

@pragma ternary 1
table compute_other_hashes {
    reads {
        hash_metadata.hash1 : exact;
    }
    actions {
        computed_two_hashes;
        computed_one_hash;
    }
}

control process_hashes {
    if (((tunnel_metadata.tunnel_terminate == 0) and valid(ipv4)) or
        ((tunnel_metadata.tunnel_terminate == 1) and valid(inner_ipv4))) {
        apply(compute_ipv4_hashes);
    }

    else {
        if (((tunnel_metadata.tunnel_terminate == 0) and valid(ipv6)) or
             ((tunnel_metadata.tunnel_terminate == 1) and valid(inner_ipv6))) {
            apply(compute_ipv6_hashes);
        }

        else {
            apply(compute_non_ip_hashes);
        }

    }

    apply(compute_other_hashes);
}







 header_type meter_metadata_t {
     fields {
         meter_color : 2;
         meter_index : 16;
     }
 }






metadata meter_metadata_t meter_metadata;
control process_meter {





}
control process_ingress_sflow {





}
control process_egress_sflow {





}
control process_add_sflow_headers {





}
control process_i2e_mirror {



}
control process_sflow_take_sample {



}

action nop() {
}

action on_miss() {
}

control ingress {

 if(l2_metadata.field_1 == 1) {
  apply(modify_outer_pri);
 } else if(l2_metadata.field_1 == 2) {
  apply(modify_outer_pri_new1);
 }
}

control egress {







        if ((eg_intr_md.deflection_flag == 0) and
            (egress_metadata.bypass == 0)) {


            if ((eg_intr_md_from_parser_aux.clone_src != 0)) {


                apply(mirror);

                process_add_sflow_headers();
            } else {


                process_replication();
            }


            apply(egress_port_mapping) {
                egress_port_type_normal {
                    if ((eg_intr_md_from_parser_aux.clone_src == 0)) {

                        process_vlan_decap();


                        process_egress_sflow();
                    }


                    process_tunnel_decap();


                    process_egress_nat();


                    process_rewrite();


                    process_egress_bd();


                    process_mac_rewrite();


                    process_mtu();


                    process_int_insertion();
                }
            }


            process_sflow_take_sample();


            process_tunnel_encap();


            process_int_outer_encap();

            if (egress_metadata.port_type == 0) {

                process_vlan_xlate();
            }


            process_egress_filter();
        }


        process_egress_acl();



}
