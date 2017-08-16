
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

header_type vlan_tag_3b_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 4;
        etherType : 16;
    }
}
header_type vlan_tag_5b_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 20;
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
        reserved : 8;
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

header_type sflow_t {
    fields {
        version : 32;
        ipVersion : 32;
        ipAddress : 32;
        subAgentId : 32;
        seqNumber : 32;
        uptime : 32;
        numSamples : 32;
    }
}

header_type sflow_internal_ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type sflow_sample_t {
    fields {
        enterprise : 20;
        format : 12;
        sampleLength : 32;
        seqNumer : 32;
        srcIdClass : 8;
        srcIdIndex : 24;
        samplingRate : 32;
        samplePool : 32;
        numDrops : 32;
        inputIfindex : 32;
        outputIfindex : 32;
        numFlowRecords : 32;
    }
}

header_type sflow_record_t {
    fields {
        enterprise : 20;
        format : 12;
        flowDataLength : 32;
        headerProtocol : 32;
        frameLength : 32;
        bytesRemoved : 32;
        headerSize : 32;
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

        ingressIfindex : 16;
        ingressBd : 16;
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
        o : 1;
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
        0x8100, 0x9100 : parse_vlan; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
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
        0x8100, 0x9100 : parse_vlan; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
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
header vlan_tag_3b_t vlan_tag_3b[2];
header vlan_tag_5b_t vlan_tag_5b[2];

parser parse_vlan {
    extract(vlan_tag_[next]);
    return select(latest.etherType) {
        0x8100, 0x9100 : parse_vlan; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
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





        17 : parse_udp_v6;
        47 : parse_gre_v6;

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

header sflow_t sflow;
header sflow_internal_ethernet_t sflow_internal_ethernet;
header sflow_sample_t sflow_sample;
header sflow_record_t sflow_record;

parser parse_sflow {
    extract(sflow);
    return ingress;
}

parser parse_bf_internal_sflow {
    extract(sflow_internal_ethernet);
    extract(sflow_sample);
    extract(sflow_record);
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
        0x8100, 0x9100 : parse_vlan; 0x8847 : parse_mpls; 0x0800 : parse_ipv4; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high; default: ingress;
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
        enable_dod : 1;
        local_ip_hit : 1;
        last_hit : 1;
        fwd_type : 5;
        next_match : 3;
        causeId : 16;
        toCpuType : 2;
        resubmit_serv_type : 4;
        cwpTtFlag : 1;
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
        loopback_en : 1;
    }
}

metadata ingress_metadata_t ingress_metadata;
metadata egress_metadata_t egress_metadata;








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

action ipat_invalid_drop() {
 modify_field(ingress_metadata.drop_reason, 1);
 drop();
}

action trunk_proc(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
 vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_ispritag_addtag(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id,
bum_carid, vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
 nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}


action trunk_ispritag_noaddtag(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id,
bum_carid, vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
 nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_nopritag_newtagnumzero_addtag(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en,
mirror_id, bum_carid, vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en,
 nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_nopritag_newtagnum_addtag(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id,
bum_carid, vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
 nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_nopritag_discard(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en,
 nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_nopritag_qinq_tag2valid(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action trunk_nopritag_qinq_tag2novalid(trunk_id, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 1);
 modify_field(l2_metadata.trunk_id, trunk_id);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_ispritag_addtag(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_ispritag_noaddtag(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_nopritag_newtagnumzero_addtag(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_nopritag_newtagnum_addtag(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_nopritag_discard(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en,
nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_nopritag_qinq_tag2valid(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action physical_nopritag_qinq_tag2novalid(sb, sp, learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.trunk_en, 0);
 modify_field(l2_metadata.sb, sb);
 modify_field(l2_metadata.spindex, sp);
 ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid, vlanacl_en, nac_en, nac_info,
 mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag);
}

action ipat_common_set(learning_enabled, mac_lmt_dlf, mac_lmt_num, block_info, mirror_en, mirror_id, bum_carid,
vlanacl_en, nac_en, nac_info, mcctrl_data, v6_fp, v6_portal, dai_en, tpid, sit, router_bridge, ttFlag) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.mac_lmt_dlf, mac_lmt_dlf);
 modify_field(l2_metadata.mac_lmt_num, mac_lmt_num);
 modify_field(l2_metadata.block_info, block_info);
 modify_field(qos_metadata.mirror_en, mirror_en);
 modify_field(qos_metadata.mirror_id, mirror_id);

 modify_field(qos_metadata.bum_carid, bum_carid);
 modify_field(qos_metadata.vlanacl_en, vlanacl_en);
 modify_field(qos_metadata.nac_en, nac_en);
 modify_field(qos_metadata.nac_info, nac_info);
 modify_field(qos_metadata.mcctrl_data, mcctrl_data);

 modify_field(l2_metadata.v6_fp, v6_fp);
 modify_field(l2_metadata.v6_portal, v6_portal);
 modify_field(l2_metadata.dai_en, dai_en);
 modify_field(l2_metadata.tpid, tpid);

 modify_field(l2_metadata.sit, sit);
 modify_field(l2_metadata.router_bridge, router_bridge);

 modify_field(l2_metadata.ovlaninfo, vlan_tag_[0].vid);
 modify_field(l2_metadata.ttFlag, ttFlag);
}

table ipat {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        ipat_invalid_drop;
        trunk_ispritag_addtag;
        trunk_ispritag_noaddtag;
        trunk_nopritag_newtagnumzero_addtag;
        trunk_nopritag_newtagnum_addtag;
        trunk_nopritag_discard;
        trunk_nopritag_qinq_tag2valid;
        trunk_nopritag_qinq_tag2novalid;
  physical_ispritag_addtag;
  physical_ispritag_noaddtag;
  physical_nopritag_newtagnumzero_addtag;
  physical_nopritag_newtagnum_addtag;
  physical_nopritag_discard;
  physical_nopritag_qinq_tag2valid;
  physical_nopritag_qinq_tag2novalid;
    }
    size : 288;
}

control process_ipat {
    if (ig_intr_md.resubmit_flag == 0) {
  apply(ipat);
 }
}

action icib_miss_drop() {
 drop();
}

action icib_invalid_drop() {
 drop();
}

action icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn) {
 modify_field(l2_metadata.fwd_type, fwd_type);
 modify_field(l2_metadata.tbl_type, tbl_type);
 modify_field(qos_metadata.carid, carid);
 modify_field(qos_metadata.countid, countid);
 modify_field(qos_metadata.classid, classid);
 modify_field(l2_metadata.outter_pri_act, outter_pri_act);
 modify_field(l2_metadata.outter_cfi_act, outter_cfi_act);
 modify_field(l2_metadata.inner_pri_act, inner_pri_act);
 modify_field(l2_metadata.inner_cfi_act, inner_cfi_act);
 modify_field(l2_metadata.urpf_type, urpf_type);
 modify_field(l2_metadata.l3_subindex, l3_subindex);
 modify_field(l2_metadata.vrfid, vrfid);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(l2_metadata.svp, svp);
 modify_field(l2_metadata.dvp, dvp);
 modify_field(l2_metadata.vlanswitch_primode, vlanswitch_primode);
 modify_field(l2_metadata.vlanswitch_oport, vlanswitch_oport);
 modify_field(l2_metadata.BrasEn, BrasEn);
}

action vlan_add_add(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ovid, ivid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);

 modify_field(l2_metadata.ovlaninfo, ovid);
 modify_field(l2_metadata.ivlaninfo, ivid);
}

action vlan_modify_add(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ovid, ivid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);



}

action vlan_modify_modify(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ovid, ivid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);
 modify_field(l2_metadata.ovlaninfo, ovid);
 modify_field(l2_metadata.ivlaninfo, ivid);
}

action vlan_outer_add(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ovid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);


}

action vlan_outer_modify(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ovid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);

}

action vlan_outer_delete(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);

}

action vlan_inner_modify(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ivid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);

}

action vlan_inner_add(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, ivid, BrasEn) {
 icib_comm_set(fwd_type, tbl_type, carid, countid, classid, outter_pri_act, outter_cfi_act, inner_pri_act, inner_cfi_act, urpf_type, l3_subindex, vrfid, vsi, svp, dvp, vlanswitch_primode, vlanswitch_oport, BrasEn);



}

table icib {
    reads {
        ig_intr_md.ingress_port : exact;
        l2_metadata.ovlaninfo : exact;
    }
    actions {
        vlan_add_add;
        vlan_modify_add;
        vlan_modify_modify;
        vlan_outer_add;
        vlan_outer_modify;
        vlan_outer_delete;
        vlan_inner_modify;
        vlan_inner_add;
    }
    size : 1024;
}

action icib_common(fwd_type, tbl_type, car_cnt_en, carid, classid) {
 modify_field(l2_metadata.fwd_type, fwd_type);
 modify_field(l2_metadata.tbl_type, tbl_type);
 modify_field(qos_metadata.car_cnt_en, car_cnt_en);
 modify_field(qos_metadata.carid, carid);
 modify_field(qos_metadata.classid, classid);
}

action icib_l3_fwd(urpf_type, sub_index, vrfid) {
 modify_field(l2_metadata.urpf_type, urpf_type);
 modify_field(l2_metadata.l3_subindex, sub_index);
 modify_field(l2_metadata.vrfid, vrfid);
}

action icib_vpls_fwd(svp, vsi) {
 modify_field(l2_metadata.svp, svp);
 modify_field(l2_metadata.vsi, vsi);
}

action icib_pwe3_fwd(svp, dvp) {
 modify_field(l2_metadata.svp, svp);
 modify_field(l2_metadata.dvp, dvp);
}

action icib_vlan_switch_fwd(pri_mod, oport) {
 modify_field(l2_metadata.vlanswitch_primode, pri_mod);
 modify_field(l2_metadata.vlanswitch_oport, oport);
}

action icib_l2orvlanifl3_fwd(svp) {
 modify_field(l2_metadata.svp, svp);
}

table icib_l3_fwd {
 actions {
  icib_l3_fwd;
 }
}

table icib_vpls_fwd {
 actions {
  icib_vpls_fwd;
 }
}

table icib_pwe3_fwd {
 actions {
  icib_pwe3_fwd;
 }
}

table icib_vlan_switch_fwd {
 actions {
  icib_vlan_switch_fwd;
 }
}

table icib_l2orvlanifl3_fwd {
 actions {
  icib_l2orvlanifl3_fwd;
 }
}

table icib_fwd_pro {
 reads {
  l2_metadata.fwd_type : exact;
 }
 actions {
        icib_miss_drop;
        icib_invalid_drop;
  icib_l3_fwd;
  icib_vpls_fwd;
  icib_pwe3_fwd;
  icib_vlan_switch_fwd;
  icib_l2orvlanifl3_fwd;
 }
 size : 32;
}

action user_mac_miss() {
 modify_field(l3_metadata.UserAuth, 0);
}

action user_mac_inv() {
 modify_field(l3_metadata.UserAuth, 0);
}

action user_mac_hit(vrfIndex, l2tpFlag, ucibIndex) {
 modify_field(l2_metadata.vrfid, vrfIndex);
 modify_field(l2_metadata.l2tpFlag, l2tpFlag);
 modify_field(l2_metadata.ucibIndex, ucibIndex);
 modify_field(l3_metadata.UserAuth, 1);
}

table user_mac {
 reads {
  l2_metadata.spindex : exact;
  l2_metadata.ovlaninfo : exact;
  l2_metadata.ivlaninfo : exact;
  l2_metadata.lkp_mac_sa : exact;
 }
 actions {
  user_mac_miss;
  user_mac_inv;
  user_mac_hit;
 }
 size : 1024;
}

action ucib_inv() {
 drop();
}

action ucib_vld(carId, statId) {
 modify_field(l2_metadata.userCarId, carId);
 modify_field(l2_metadata.userStatId, statId);
}

table ucib {
 reads {
  l2_metadata.ucibIndex : exact;
 }
 actions {
  ucib_inv;
  ucib_vld;
 }
 size : 1024;
}

table tunnel_terminate {
 actions {
  nop;
 }
 size : 1024;
}

control process_bras {
 if(l2_metadata.BrasEn == 1) {
  apply(user_mac);
  if(l2_metadata.ucibIndex != 0) {
   apply(ucib);
  }
 }





}

action outer_pri_action() {
 drop();
}

table outer_pri_modify{
 actions {
  outer_pri_action;
 }
}

action outer_cfi_action() {
 drop();
}

table outer_cfi_modify{
 actions {
  outer_cfi_action;
 }
}

action inner_pri_action() {
 drop();
}

table inner_pri_modify{
 actions {
  inner_pri_action;
 }
}

action inner_cfi_action() {
 drop();
}

table inner_cfi_modify{
 actions {
  inner_cfi_action;
 }
}


control process_icib {
 apply(icib);

}

action vlanacl_drop() {
 drop();
}

action vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(qos_metadata.outpri_act, outpri_act);
 modify_field(qos_metadata.outcfi_act, outcfi_act);
 modify_field(qos_metadata.innerpri_act, innerpri_act);
 modify_field(qos_metadata.innercfi_act, innercfi_act);
 modify_field(qos_metadata.ipri2opri, ipri2opri);
}

action vlanacl_outertag_add(learning_enabled, new_ovlan_info, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ovlan_info, new_ovlan_info);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 add_to_field(l2_metadata.new_tag_num, 1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_outertag_modify(learning_enabled, new_ovlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ovlan_info, new_ovlan_info);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_outertag_delete(learning_enabled , new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 add_to_field(l2_metadata.new_tag_num, -1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_inner_add(learning_enabled, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 add_to_field(l2_metadata.new_tag_num, 1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_inner_modify(learning_enabled, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_inner_delete(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 add_to_field(l2_metadata.new_tag_num, -1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_outertag_add_tagipri2opri(learning_enabled, new_ovlan_info, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ovlan_info, new_ovlan_info);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 add_to_field(l2_metadata.new_tag_num, 1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_outertag_modify_tagipri2opri(learning_enabled, new_ovlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ovlan_info, new_ovlan_info);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_inner_add_tagipri2opri(learning_enabled, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 add_to_field(l2_metadata.new_tag_num, 1);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

action vlanacl_inner_modify_tagipri2opri(learning_enabled, new_ivlan_info, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri) {
 modify_field(l2_metadata.learning_enabled, learning_enabled);
 modify_field(l2_metadata.new_ivlan_info, new_ivlan_info);
 vlanacl_vlan_comm_set(learning_enabled, outpri_act, outcfi_act, innerpri_act, innercfi_act, ipri2opri);
}

table vfp {
    reads {
  qos_metadata.vlanacl_vp : exact;
  qos_metadata.vlanacl_vp_gid : exact;
  qos_metadata.vlanacl_novp_trunkflag : exact;
  qos_metadata.vlanacl_novp_trunkid : exact;
  qos_metadata.vlanacl_novp_sp : exact;
  qos_metadata.vlanacl_dscp : exact;
  qos_metadata.vlanacl_dip : exact;
  qos_metadata.vlanacl_sip : exact;
  qos_metadata.vlanacl_protocol : exact;
  qos_metadata.vlanacl_icmpcode : exact;
  qos_metadata.vlanacl_icmptype : exact;
  qos_metadata.vlanacl_igmptype : exact;
  qos_metadata.vlanacl_dport : exact;
  qos_metadata.vlanacl_sport : exact;
  qos_metadata.vlanacl_snap : exact;
  qos_metadata.vlanacl_llc : exact;
  qos_metadata.vlanacl_mf : exact;
  qos_metadata.vlanacl_offsetZero : exact;
 }
    actions {
     vlanacl_vlan_comm_set;
  vlanacl_drop;
  vlanacl_outertag_add;
  vlanacl_outertag_modify;
  vlanacl_outertag_delete;
  vlanacl_inner_add;
  vlanacl_inner_modify;
  vlanacl_inner_delete;
  nop;
    }
    size : 288;
}


action modify_outer_cfi() {
 modify_field(l2_metadata.outer_tag_cfi, 2);
}

table modify_outer_cfi {
 actions {
  modify_outer_cfi;
 }
}

action modify_inner_pri() {
 modify_field(l2_metadata.inner_tag_pri, 1);
}

table modify_inner_pri {
 actions {
  modify_inner_pri;
 }
}

action modify_inner_cfi() {
 modify_field(l2_metadata.inner_tag_cfi, 2);
}

table modify_inner_cfi {
 actions {
  modify_inner_cfi;
 }
}

action copyIpriToOpri() {
 modify_field(l2_metadata.outer_tag_pri, l2_metadata.inner_tag_pri);
}

table copyIpriToOpri {
 actions {
  copyIpriToOpri;
 }
}

control process_vfp {
 if(l2_metadata.vlan_acl_en == 1) {
  apply(vfp);





  if(qos_metadata.outcfi_act == 1) {
   apply(modify_outer_cfi);
  }
  if(qos_metadata.innercfi_act == 1) {
   apply(modify_inner_cfi);
  }





 }
}

action my_station_hit(bc, mc) {
 modify_field(l3_metadata.bc, bc);
 modify_field(l3_metadata.mc, mc);
 modify_field(ingress_metadata.last_hit, 1);
}

action my_station_miss() {
 modify_field(ingress_metadata.last_hit, 0);
}

table out_my_station {
 reads {
  l2_metadata.sb : exact;
  l2_metadata.spindex : exact;
  l2_metadata.ovlaninfo : exact;
  l2_metadata.lkp_mac_da : exact;
 }
 actions {
  my_station_hit;
  nop;
 }
}

control process_my_station {
 apply(out_my_station);
}

action gre_tunnel() {
 modify_field(tunnel_metadata.tt1_key_type, 9);
 modify_field(tunnel_metadata.tt_flag, 1);
}

table gre_tunnel {
 actions {
  gre_tunnel;
 }
}

action vxlan_tunnel() {
 modify_field(tunnel_metadata.tt1_key_type, 9);
 modify_field(tunnel_metadata.tt2_key_type, 9);
 modify_field(tunnel_metadata.tt_flag, 1);
}

table vxlan_tunnel {
 actions {
  vxlan_tunnel;
 }
}

action nvgre_tunnel() {
 modify_field(tunnel_metadata.tt_flag, 1);
}

table nvgre_tunnel {
 actions {
  nvgre_tunnel;
 }
}

action trill_tunnel() {
 modify_field(tunnel_metadata.tt1_key_type, 11);
 modify_field(tunnel_metadata.tt2_key_type, 11);
}

table trill_tunnel {
 actions {
  trill_tunnel;
 }
}

action mpls_tunnel() {
 modify_field(tunnel_metadata.tt1_key_type, 11);
 modify_field(tunnel_metadata.tt2_key_type, 11);
}

table mpls_tunnel {
 actions {
  mpls_tunnel;
 }
}

action pbb_tunnel_ipv4() {
 modify_field(tunnel_metadata.tt_flag, 0);
}

table pbb_tunnel_ipv4 {
 actions {
  pbb_tunnel_ipv4;
 }
}

action pbb_tunnel_not_ipv4() {
 modify_field(tunnel_metadata.tt_flag, 0);
}

table pbb_tunnel_not_ipv4 {
 actions {
  pbb_tunnel_not_ipv4;
 }
}
action ivsi_comm_set(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk) {
 modify_field(l2_metadata.vsi_valid, vsi_valid);
 modify_field(l2_metadata.vlanlrn_mode, vlanlrn_mode);
 modify_field(l2_metadata.vlanlrn_lmt, vlanlrn_lmt);
 modify_field(l2_metadata.stg_id, stg_id);
 modify_field(l2_metadata.class_id, class_id);
 modify_field(l2_metadata.vlan_mac_lmt_dlf, vlan_mac_lmt_dlf);
 modify_field(l2_metadata.vlan_lmt_num, vlan_lmt_num);
 modify_field(l2_metadata.vrfid, vrfid);
 modify_field(l2_metadata.bypass_chk, bypass_chk);
 modify_field(qos_metadata.car_cnt_en, car_cnt_en);
 modify_field(qos_metadata.ivsi_carid, ivsi_carid);
 modify_field(qos_metadata.unuc_en, unuc_en);
 modify_field(qos_metadata.bc_en, bc_en);
 modify_field(qos_metadata.mgid, mgid);
}

action ivsi_invalid_drop() {
 drop();
}

action ivsi_mff_enable_bypasschk_disable(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk) {
 ivsi_comm_set(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk);
 modify_field(qos_metadata.search_type1, 1);
 modify_field(qos_metadata.search_profile1, 1);
 modify_field(qos_metadata.tid0, 10);
 modify_field(ingress_metadata.next_match, 1);
}

action ivsi_mff_disable_bypasschk_disable(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk) {
 ivsi_comm_set(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk);
 modify_field(ingress_metadata.next_match, 1);
}

action ivsi_mff_disable_bypasschk_enable(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk) {
 ivsi_comm_set(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk);
 modify_field(ingress_metadata.next_match, 2);
}

action ivsi_mff_enable_bypasschk_enable(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk) {
 ivsi_comm_set(vsi_valid, vlanlrn_mode, vlanlrn_lmt, stg_id, class_id, vlan_mac_lmt_dlf, vlan_lmt_num, vrfid, car_cnt_en, ivsi_carid, unuc_en, bc_en, mgid, bypass_chk);
 modify_field(qos_metadata.search_type1, 1);
 modify_field(qos_metadata.search_profile1, 1);
 modify_field(qos_metadata.tid1, 10);
 modify_field(ingress_metadata.next_match, 2);
}

table ivsi {
 reads {
  l2_metadata.vsi : exact;
 }
 actions {
  ivsi_invalid_drop;
  ivsi_mff_enable_bypasschk_disable;
  ivsi_mff_disable_bypasschk_disable;
  ivsi_mff_disable_bypasschk_enable;
  ivsi_mff_enable_bypasschk_enable;
 }
 size : 16384;
}

action bypass_chk_comm_set() {
 modify_field(qos_metadata.tid0, 6);
 modify_field(qos_metadata.tnl_terminate, tunnel_metadata.tt_flag);
 modify_field(qos_metadata.tcc_type, 1);
 modify_field(qos_metadata.search_type0, 1);
 modify_field(qos_metadata.search_profile0, 0);
}

action tag_num_no_zero_ttflag_true() {
 modify_field(qos_metadata.outer_vlan, l2_metadata.new_ovlan_info);
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
}

action tag_num_zero_ttflag_true() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.frag, 1);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);

}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
 modify_field(qos_metadata.option_flag, 1);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_icmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);

}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_igmp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagTrue_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_tcp() {
 modify_field(qos_metadata.protocol_bitmap, l2_metadata.svp);
 modify_field(qos_metadata.sportinfo, l2_metadata.oport_info);
}

action ttflagFalse_srctrunkflagFalse_default() {
 modify_field(qos_metadata.ethType, inner_ethernet.etherType);
}

table ivsi_bypass_chk {
 reads {
  tunnel_metadata.tt_flag : exact;
  l2_metadata.src_trunk_flag : exact;
  l3_metadata.tcp_valid : exact;
  l3_metadata.udp_valid : exact;
  l3_metadata.l4_pkt_type : exact;
  l2_metadata.new_tag_num : exact;
 }
 actions {
  tag_num_no_zero_ttflag_true;
  tag_num_zero_ttflag_true;

  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_icmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_igmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionTrue_tcp;
  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_icmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_igmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragTrue_ipv4OptionFalse_tcp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_icmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_igmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionTrue_tcp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_icmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_igmp;
  ttflagFalse_srctrunkflagFalse_ipv4FragFalse_ipv4OptionFalse_tcp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_icmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_igmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionTrue_tcp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_icmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_igmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragTrue_ipv4OptionFalse_tcp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_icmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_igmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionTrue_tcp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_icmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_igmp;
  ttflagFalse_srctrunkflagTrue_ipv4FragFalse_ipv4OptionFalse_tcp;
  nop;
  ttflagFalse_srctrunkflagFalse_default;
 }
}

action mstp_port_bmp(bmp_status) {
 modify_field(l2_metadata.bmp_status, bmp_status);
}

table port_bmp {
 reads {
  l2_metadata.spindex : exact;
  l2_metadata.new_ovlan_info : exact;
 }
 actions {
  mstp_port_bmp;
 }
}

table mstp_bmp {
 reads {
  l2_metadata.spindex : exact;
  l2_metadata.stg_id : exact;
 }
 actions {
  mstp_port_bmp;
 }
}

action pa_miss_drop() {
 modify_field(ingress_metadata.drop_flag, 1);
 drop();
}

action pa_block() {
 modify_field(ingress_metadata.drop_flag, 0);
 drop();
}

action pa_microctrl_drop() {
 modify_field(ingress_metadata.drop_flag, 0);
 drop();
}

action pa_miss_inner_mystation_action() {
 modify_field(ingress_metadata.drop_flag, 0);
}

action pa_hit_action(countid) {
 modify_field(qos_metadata.countid, countid);
}

action pa_hit_arp_block() {
 modify_field(ingress_metadata.causeId, 58);
}

action pa_hit_arp_unblock() {
 modify_field(l2_metadata.stp_state, 1);
 modify_field(ingress_metadata.causeId, 107);
}

action pa_hit_tocp_fwd() {
 modify_field(ingress_metadata.toCpuType, 1);
 modify_field(ingress_metadata.causeId, 107);
}

action pa_hit_tocp_drop() {
 modify_field(ingress_metadata.toCpuType, 1);
 modify_field(ingress_metadata.drop_flag, 1);
}

action pa_hit_fwd() {
 modify_field(ingress_metadata.drop_flag, 0);
}

action pa_hit_drop() {
 modify_field(ingress_metadata.drop_flag, 1);
}

table pa {
 reads {
  qos_metadata.search_type0 : exact;
  qos_metadata.search_profile0 : exact;
  qos_metadata.search_type1 : exact;
  qos_metadata.search_profile1 : exact;
  qos_metadata.tid1 : exact;
  qos_metadata.tid0 : exact;
  qos_metadata.tnl_terminate : exact;
  qos_metadata.local_mac_hit : exact;
  qos_metadata.tcc_type : exact;
  qos_metadata.outer_vlan : exact;
  qos_metadata.protocol_bitmap : exact;
  qos_metadata.trunk_flag : exact;
  qos_metadata.frag : exact;
  qos_metadata.option_flag : exact;
  qos_metadata.trunkid : exact;
  qos_metadata.sportinfo : exact;
  qos_metadata.icmp_type : exact;
  qos_metadata.l4dport : exact;
  qos_metadata.l4sport : exact;
  qos_metadata.ethType : exact;
  l2_metadata.block_flag : exact;
  l2_metadata.RmtLpbk : exact;
 }
 actions {
  pa_block;
  pa_miss_drop;
  pa_microctrl_drop;
  pa_miss_inner_mystation_action;
  pa_hit_arp_block;
  pa_hit_arp_unblock;
  pa_hit_tocp_fwd;
  pa_hit_tocp_drop;
  pa_hit_fwd;
  pa_hit_drop;
  pa_hit_action;
  nop;
 }
}

table pa1 {
 reads {
  l2_metadata.spindex : exact;
 }
 actions {
  pa_miss_drop;
  nop;
 }
 size : 256;
}


table mfibv4 {
 actions {
  nop;
 }
}

table mfibv6 {
 actions {
  nop;
 }
}

table urpfv4 {
 actions {
  nop;
 }
}

action bc_discard() {
 drop();
}


table ivsi_ext {
 reads {
  l2_metadata.vsi : exact;
 }
 actions {
  nop;
  bc_discard;
 }
}

control process_tunnel_judge {
 apply(tunnel_terminate);
 if((l2_metadata.fwd_type == 0) or
  (l2_metadata.fwd_type == 2)) {
  apply(ivsi);
  if(l2_metadata.bypass_chk == 1) {
   apply(ivsi_bypass_chk);
  }
  if((l2_metadata.vsi_valid == 0) or
    (l2_metadata.bypass_chk == 1)) {
   apply(pa) {
    pa_miss_inner_mystation_action {
     apply(inner_mystation) {
      inner_mystation_miss_maclrn,
      inner_mystation_bc_maclrn,
      inner_mystation_bc_maclrn {
       apply(maclrn) {
        maclrn_bc_proc {
         apply(ivsi_ext);
        }
       }
      }
      no_tunnel_mfibv4,
      inner_mystation_mfibv4 {
       apply(mfibv4);
      }
      no_tunnel_mfibv6,
      inner_mystation_mfibv6 {
       apply(mfibv6);
      }
      no_tunnel_urpfv4,
      inner_mystation_urpfv4 {
       apply(urpfv4);
      }
     }
    }
   }
  } else {
   apply(mstp_bmp);
   apply(port_bmp);
  }
 } else if(l2_metadata.fwd_type == 0) {
  apply(pa1);
 }
}

action inner_mystation_mac_unequal_drop() {
 modify_field(ingress_metadata.drop_flag, 1);
 modify_field(ingress_metadata.causeId, 5);
 drop();
}

action inner_mystation_bc_drop() {
 modify_field(ingress_metadata.drop_flag, 1);
 modify_field(ingress_metadata.causeId, 5);
 drop();
}

action inner_mystation_miss_maclrn() {
 modify_field(ingress_metadata.fwd_type, 1);
}

action inner_mystation_bc_maclrn() {
 modify_field(ingress_metadata.fwd_type, 19);

}

action inner_mystation_mfibv4() {
 modify_field(ingress_metadata.fwd_type, 24);
}

action inner_mystation_mfibv6() {
 modify_field(ingress_metadata.fwd_type, 24);
}

action inner_mystation_fibv4() {
 modify_field(ingress_metadata.fwd_type, 8);
}

action no_tunnel_fibv4() {
 modify_field(ingress_metadata.fwd_type, 8);
}

action inner_mystation_urpfv4() {
 modify_field(ingress_metadata.fwd_type, 8);
}

action no_tunnel_urpfv4() {
 modify_field(ingress_metadata.fwd_type, 8);
}

action inner_mystation_uc_maclrn() {
 modify_field(ingress_metadata.fwd_type, 8);
}

action inner_mystation_miss_drop() {
 drop();
}

action no_tunnel_mfibv4() {
 modify_field(ingress_metadata.fwd_type, 24);
}

action no_tunnel_mfibv6() {
 modify_field(ingress_metadata.fwd_type, 24);
}



table inner_mystation {
 reads {
  l2_metadata.sb : exact;
  l2_metadata.spindex : exact;
  l2_metadata.vsi : exact;
  l2_metadata.lkp_mac_da : exact;
  l2_metadata.router_bridge : exact;
  tunnel_metadata.tt_flag : exact;
  l2_metadata.ipv4uc_en : exact;
  l2_metadata.ipv6uc_en : exact;
 }
 actions {
  inner_mystation_miss_drop;
  inner_mystation_miss_maclrn;
  inner_mystation_mac_unequal_drop;
  inner_mystation_bc_drop;
  inner_mystation_bc_maclrn;
  inner_mystation_mfibv4;
  no_tunnel_mfibv4;
  inner_mystation_mfibv6;
  no_tunnel_mfibv6;
  inner_mystation_fibv4;
  no_tunnel_fibv4;
  inner_mystation_urpfv4;
  no_tunnel_urpfv4;
  inner_mystation_uc_maclrn;
  nop;
 }
}

action maclrn_srcblklist_drop() {
 drop();
}

action maclrn_bc_proc() {
 modify_field(l2_metadata.ivsi_ext, 1);
}

action maclrn_befwd() {
 modify_field(l2_metadata.ivsi_ext, 0);
}

table maclrn {
 reads {
  l2_metadata.vsi : exact;
  l2_metadata.lkp_mac_sa : exact;
  ingress_metadata.fwd_type : exact;
 }
 actions {

  nop;

  maclrn_srcblklist_drop;
  maclrn_bc_proc;
  maclrn_befwd;
 }
}

control process_inner_mystation {
 apply(inner_mystation);
 if((ingress_metadata.fwd_type == 1) or (ingress_metadata.fwd_type == 19)) {
  apply(maclrn);
 }
}

action be_invalid_drop() {
 drop();
}

action be_dst_blklist_drop() {
 drop();
}

action be_opcode_drop() {
 drop();
}

action be_bc() {
 modify_field(l2_metadata.ivsi_ext, 1);
}

action be_tbtp(be_opcode, oport_info) {
 modify_field(l2_metadata.be_opcode, 2);
 modify_field(l2_metadata.oport_info, oport_info);
}

action be_trunk(be_opcode, trunkid) {
 modify_field(l2_metadata.be_opcode, 2);
 modify_field(l2_metadata.trunkid, trunkid);
}

action be_dvp(be_opcode, dvp_index) {
 modify_field(l2_metadata.be_opcode, 2);
 modify_field(l2_metadata.dvp_index, dvp_index);
}

action be_opcode_mc(be_opcode, mgid) {
 modify_field(l2_metadata.be_opcode, 2);
 modify_field(qos_metadata.mgid, mgid);
}

table befwd {
 reads {
  l2_metadata.vsi : exact;
  l2_metadata.lkp_mac_da : exact;
 }
 actions {
  be_invalid_drop;
  be_dst_blklist_drop;
  be_bc;
  be_tbtp;
  be_trunk;
  be_dvp;
  be_opcode_drop;
  be_opcode_mc;
 }
}

field_list trunk_hash_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;
}

field_list_calculation trunk_hash_fields {
    input {
        trunk_hash_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action trunk_num_zero_drop() {
 drop();
}

action trunk_hash_pro() {


 drop();
}
action dvp_invalid_drop() {
 drop();
}

action dvp_vxlan_tag_zero() {
 drop();
}

action dvp_vxlan_ecmp1() {
 drop();
}

action dvp_vxlan_ecmp2() {
 drop();
}

action dvp_unsupport() {
 drop();
}

table dvp {
 reads {
  l2_metadata.dvp_index : exact;
 }
 actions {
  dvp_invalid_drop;
  dvp_vxlan_tag_zero;
  dvp_vxlan_ecmp1;
  dvp_vxlan_ecmp2;
  dvp_unsupport;
 }
}

action hash_result(hash_rlst) {
    modify_field(l2_metadata.hash_rslt, hash_rlst);
}

table trunk_hash {
 reads {
  l2_metadata.lkp_mac_da : exact;
  l2_metadata.lkp_mac_sa : exact;
  ipv4_metadata.lkp_ipv4_da : exact;
  ipv4_metadata.lkp_ipv4_sa : exact;
  ethernet.etherType : exact;
 }
 actions {
  hash_result;
 }
    size : 1024;
}
control process_befwd {
 apply(befwd) ;
}




action set_bd_ipv4_mcast_switch_ipv6_mcast_switch_flags(bd, vrf,
        rmac_group, stp_group, learning_enabled,
        ipv4_urpf_mode, ipv6_urpf_mode,
        ipv4_unicast_enabled, ipv6_unicast_enabled,
        igmp_snooping_enabled, mld_snooping_enabled,
        bd_label, stats_idx,
        ipv4_multicast_mode, ipv6_multicast_mode,
        mrpf_group, exclusion_id) {
    modify_field(l3_metadata.vrf, vrf);
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);

    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(multicast_metadata.outer_ipv4_mcast_key_type, 0);
    modify_field(multicast_metadata.outer_ipv4_mcast_key, bd);
    modify_field(multicast_metadata.outer_ipv6_mcast_key_type, 0);
    modify_field(multicast_metadata.outer_ipv6_mcast_key, bd);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
}

action set_bd_ipv4_mcast_switch_ipv6_mcast_route_flags(bd, vrf,
        rmac_group, stp_group, learning_enabled,
        ipv4_urpf_mode, ipv6_urpf_mode,
        ipv4_unicast_enabled, ipv6_unicast_enabled,
        igmp_snooping_enabled, mld_snooping_enabled,
        bd_label, stats_idx,
        ipv4_multicast_mode, ipv6_multicast_mode,
        mrpf_group, exclusion_id) {
    modify_field(l3_metadata.vrf, vrf);
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);

    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(multicast_metadata.outer_ipv4_mcast_key_type, 0);
    modify_field(multicast_metadata.outer_ipv4_mcast_key, bd);
    modify_field(multicast_metadata.outer_ipv6_mcast_key_type, 1);
    modify_field(multicast_metadata.outer_ipv6_mcast_key, vrf);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
}

action set_bd_ipv4_mcast_route_ipv6_mcast_switch_flags(bd, vrf,
        rmac_group, stp_group, learning_enabled,
        ipv4_urpf_mode, ipv6_urpf_mode,
        ipv4_unicast_enabled, ipv6_unicast_enabled,
        igmp_snooping_enabled, mld_snooping_enabled,
        bd_label, stats_idx,
        ipv4_multicast_mode, ipv6_multicast_mode,
        mrpf_group, exclusion_id) {
    modify_field(l3_metadata.vrf, vrf);
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(multicast_metadata.outer_ipv4_mcast_key_type, 1);
    modify_field(multicast_metadata.outer_ipv4_mcast_key, vrf);
    modify_field(multicast_metadata.outer_ipv6_mcast_key_type, 0);
    modify_field(multicast_metadata.outer_ipv6_mcast_key, bd);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
}

action set_bd_ipv4_mcast_route_ipv6_mcast_route_flags(bd, vrf,
        rmac_group, stp_group, learning_enabled,
        ipv4_urpf_mode, ipv6_urpf_mode,
        ipv4_unicast_enabled, ipv6_unicast_enabled,
        igmp_snooping_enabled, mld_snooping_enabled,
        bd_label, stats_idx,
        ipv4_multicast_mode, ipv6_multicast_mode,
        mrpf_group, exclusion_id) {
    modify_field(l3_metadata.vrf, vrf);
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(multicast_metadata.outer_ipv4_mcast_key_type, 1);
    modify_field(multicast_metadata.outer_ipv4_mcast_key, vrf);
    modify_field(multicast_metadata.outer_ipv6_mcast_key_type, 1);
    modify_field(multicast_metadata.outer_ipv6_mcast_key, vrf);
    modify_field(multicast_metadata.ipv4_multicast_mode, ipv4_multicast_mode);
    modify_field(multicast_metadata.ipv6_multicast_mode, ipv6_multicast_mode);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
}

action set_bd(bd, vrf, rmac_group,
        ipv4_unicast_enabled, ipv6_unicast_enabled,
        ipv4_urpf_mode, ipv6_urpf_mode,
        igmp_snooping_enabled, mld_snooping_enabled,
        bd_label, stp_group, stats_idx, learning_enabled,
        exclusion_id) {
    modify_field(l3_metadata.vrf, vrf);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(ingress_metadata.bd, bd);
    modify_field(ingress_metadata.outer_bd, bd);
    modify_field(l2_metadata.stp_group, stp_group);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
    modify_field(l2_metadata.learning_enabled, learning_enabled);

    modify_field(multicast_metadata.igmp_snooping_enabled, igmp_snooping_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
}

action port_vlan_mapping_miss() {
    modify_field(l2_metadata.port_vlan_mapping_miss, 1);
}

action_profile bd_action_profile {
    actions {
        set_bd;
        set_bd_ipv4_mcast_switch_ipv6_mcast_switch_flags;
        set_bd_ipv4_mcast_switch_ipv6_mcast_route_flags;
        set_bd_ipv4_mcast_route_ipv6_mcast_switch_flags;
        set_bd_ipv4_mcast_route_ipv6_mcast_route_flags;
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
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
    ipv4_metadata.lkp_ipv4_sa;
    ipv4_metadata.lkp_ipv4_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list_calculation lag_hash {
    input {
        lag_hash_fields;
    }
    algorithm : crc16;
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
        set_egress_packet_vlan_tagged;
        set_egress_packet_vlan_untagged;
    }
    size : 32768;
}

control process_vlan_xlate {
    apply(egress_vlan_xlate);
}

action miss_drop() {
 drop();
}

action ecib_common_set(vt, acltype, phbEn, carcntEn) {
 modify_field(qos_metadata.vt, vt);
 modify_field(qos_metadata.acltype, acltype);
 modify_field(qos_metadata.phbEn, phbEn);
 modify_field(qos_metadata.carcntEn, carcntEn);
}

action ecib_1tag_modify(ovid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 modify_field(vlan_tag_[0].vid, ovid);
}

action ecib_1tag_delete(vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 remove_header(vlan_tag_[0]);
}

action ecib_1tag_add(ovid, ivid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 add_header(vlan_tag_[0]);
 modify_field(vlan_tag_[1].vid, ivid);
 modify_field(vlan_tag_[0].vid, ovid);
}

action ecib_1tag_2tag_add(ovid, ivid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 add_header(vlan_tag_[0]);
 add_header(vlan_tag_[1]);
 modify_field(vlan_tag_[1].vid, ivid);
 modify_field(vlan_tag_[0].vid, ovid);
}

action ecib_1tag_2tag_modify(ovid, ivid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 modify_field(vlan_tag_[1].vid, ivid);
 modify_field(vlan_tag_[0].vid, ovid);
}

action ecib_1tag_2tag_delete(vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 remove_header(vlan_tag_[0]);
 remove_header(vlan_tag_[1]);
}

action ecib_2tag_modify(ovid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 modify_field(vlan_tag_[0].vid, ovid);
}

action ecib_2tag_delete(vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 remove_header(vlan_tag_[0]);
}

action ecib_2tag_add(ovid, vt, acltype, phbEn, carcntEn) {
 ecib_common_set(vt, acltype, phbEn, carcntEn);
 add_header(vlan_tag_[0]);
 modify_field(vlan_tag_[0].vid, ovid);
}

table pvv_ecib {
 reads {
  l2_metadata.DstPort_TrunkId : exact;
  l2_metadata.DstPort_TrunkId : exact;
  l2_metadata.ovlaninfo : exact;
  l2_metadata.ivlaninfo : exact;

 }
 actions {
  miss_drop;
  ecib_1tag_modify;
  ecib_1tag_delete;
  ecib_1tag_add;
  ecib_1tag_2tag_add;
  ecib_1tag_2tag_modify;
  ecib_1tag_2tag_delete;
  ecib_2tag_modify;
  ecib_2tag_delete;
  ecib_2tag_add;
 }

}

table pvp_ecib {
 reads {
  l2_metadata.DstPort_TrunkId : exact;
  l2_metadata.DstPort_TrunkId : exact;
  l2_metadata.ovlaninfo : exact;
  l2_metadata.ivlaninfo : exact;

 }
 actions {
  miss_drop;
  ecib_1tag_modify;
  ecib_1tag_delete;
  ecib_1tag_add;
  ecib_1tag_2tag_add;
  ecib_1tag_2tag_modify;
  ecib_1tag_2tag_delete;
  ecib_2tag_modify;
  ecib_2tag_delete;
  ecib_2tag_add;
 }
}



control process_epat {
 apply(epat) {
  trunk_bridge_l2_isolation,
  notrunk_bridge_l2_isolation,
  trunk_route_l3_isolation,
  notrunk_route_l3_isolation {
   apply(l2_isolate) {
    isolate_pv,
    isolate_pvv {
     apply(pvv_ecib);
    }
    isolate_pvpri {
     apply(pvp_ecib);
    }
   }
  }
 }
}


table phb {
 actions {
  nop;
 }
}

table ecar {
 actions {
  nop;
 }
}

table estat {
 actions {
  nop;
 }
}

action evlan_invalid_drop() {
 drop();
}

action evlan_l3_mac_change(smac, carcntEn, evlanCarCntId, stgId) {
 modify_field(ethernet.srcAddr, smac);
 modify_field(qos_metadata.carcntEn, carcntEn);
 modify_field(qos_metadata.evlanCarCntId, evlanCarCntId);
 modify_field(qos_metadata.stgId, stgId);
}

action evlan_l2(carcntEn, evlanCarCntId, stgId) {
 modify_field(qos_metadata.carcntEn, carcntEn);
 modify_field(qos_metadata.evlanCarCntId, evlanCarCntId);
 modify_field(qos_metadata.stgId, stgId);
}

table evlan {
 reads {
  vlan_tag_[0].vid : exact;
 }
 actions {
  evlan_invalid_drop;
  evlan_l3_mac_change;
  evlan_l2;
 }
}

action emstp_invalid_drop() {
 drop();
}

table emstp {
 reads {
  l2_metadata.DstPort_Tp : exact;
  l2_metadata.stg_id : exact;
 }
 actions {
  emstp_invalid_drop;
  nop;
 }
}

action evlanbmp_invalid_drop() {
 drop();
}

table evlanbmp {
 reads {
  l2_metadata.DstPort_Tp : exact;
  vlan_tag_[0].vid : exact;
 }
 actions {
  evlanbmp_invalid_drop;
  nop;
 }
}

control process_ecib {
 if(qos_metadata.vt == 1) {
  apply(evlan) {
   evlan_l3_mac_change,
   evlan_l2 {
    apply(emstp);
    apply(evlanbmp);
   }
  }
 }

 process_efp();

 if(qos_metadata.phbEn == 1) {
  apply(phb);
 } else if(qos_metadata.carcntEn == 1) {
  apply(ecar);
 } else if(qos_metadata.carcntEn == 2) {
  apply(estat);
 }
}


table efppre {
 actions {
  nop;
 }
}

table efp1 {
 actions {
  nop;
 }
}

table efp2 {
 actions {
  nop;
 }
}

control process_efp {
 if(qos_metadata.acltype > 0) {
  apply(efppre);
  if(tunnel_metadata.egress_tunnel_type == 13) {
   apply(efp1);
   apply(efp2);
  }
 }
}

action trunk_inv() {
 drop();
}

action trunk_vld(DstPort_Tp, DstPort_Tp_backup) {
 modify_field(l2_metadata.DstPort_Tp, DstPort_Tp);
 modify_field(l2_metadata.DstPort_Tp_backup, DstPort_Tp_backup);
}

table trunk {
 reads {
  l2_metadata.trunk_id : exact;
 }
 actions {
  trunk_inv;
  trunk_vld;
 }
 size :512;
}

action pst_inv() {
 modify_field(l2_metadata.DstPort_Tp, l2_metadata.DstPort_Tp_backup);
}

table pst {
 reads {
  l2_metadata.DstPort_Tp : exact;
 }
 actions {
  nop;
  pst_inv;
 }
 size :288;
}

field_list resubmit_ufib {
 acl_metadata.if_label;
 l3_metadata.ToBras;
    l3_metadata.SrcClassId;
    ingress_metadata.resubmit_serv_type;
}

action on_hit(SrcClassId) {
 modify_field(l3_metadata.SrcClassId, SrcClassId);
 modify_field(ingress_metadata.resubmit_serv_type, 10);
 resubmit(resubmit_ufib);
}

table ufib {
 reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
    }
 actions {
  nop;
  on_hit;
 }
 size : 8192;
}

control process_oportinfo {
 if((l3_metadata.UserAuth == 0) and (l2_metadata.BrasEn == 1)) {
  apply(ufib);
 } else {
  if(l2_metadata.oport_is_trunk == 1) {
   apply(trunk);
   apply(pst);
  }
 }
}



@pragma pa_solitary ingress l2_metadata.new_tag_num
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
        Itag1_valid : 1;
        Itag2_valid : 1;
        vlanid : 12;
        discard_tag_pkt : 1;
        tag_type : 3;
        addtag : 1;
        ovlaninfo : 16;
        ivlaninfo : 16;
        trunk_en : 1;
        trunk_id : 10;
        sb : 8;
        spindex : 8;
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
        Inew_ovlan_info : 16;
        Inew_ivlan_info : 16;
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
  tag_num : 2;
  TagHeadLen : 5;
  l2_isolation : 1;
  l3_isolation : 1;
  DstPort_TrunkId : 10;
  DstPort_TrunkFlag : 1;
  DstPort_Tp : 8;
  DstPort_Tp_backup : 8;
  BrasEn : 1;
  l2tpFlag : 1;
  ucibIndex : 16;
  userCarId : 20;
  userStatId : 20;
  ttFlag : 1;
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





action set_egress_bd_properties(nat_mode) {



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

action remove_vlan_qinq_tagged() {
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
        remove_vlan_qinq_tagged;
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
        vrf : 12;
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
        ToBras : 1;
        UserAuth : 1;
        SrcClassId : 16;
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





action fib_hit_nexthop(nexthop_index, ToBras) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);
    modify_field(l3_metadata.ToBras, ToBras);
}

action fib_hit_ecmp(ecmp_index, ToBras) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, ecmp_index);
    modify_field(l3_metadata.fib_nexthop_type, 1);
    modify_field(l3_metadata.ToBras, ToBras);
}

field_list resubmit_cwp {
 ingress_metadata.cwpTtFlag;
    ingress_metadata.resubmit_serv_type;
}


action fib_terminate_tunnel() {
 modify_field(ingress_metadata.cwpTtFlag, 1);
 modify_field(ingress_metadata.resubmit_serv_type, 11);
 resubmit(resubmit_cwp);
}
control process_urpf_bd {






}





action rewrite_ipv4_unicast_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv4.ttl, -1);
}

action rewrite_ipv4_multicast_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, 0x01005E000000, 0xFFFFFF800000);
    add_to_field(ipv4.ttl, -1);
}

action rewrite_ipv6_unicast_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(ipv6.hopLimit, -1);
}

action rewrite_ipv6_multicast_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, 0x333300000000, 0xFFFF00000000);
    add_to_field(ipv6.hopLimit, -1);
}

action rewrite_mpls_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
    modify_field(ethernet.dstAddr, egress_metadata.mac_da);
    add_to_field(mpls[0].ttl, -1);
}

table mac_rewrite {
    reads {
        egress_metadata.smac_idx : exact;
        ipv4 : valid;
        ipv6 : valid;
        mpls[0] : valid;
    }
    actions {
        nop;
        rewrite_ipv4_unicast_mac;
        rewrite_ipv4_multicast_mac;

        rewrite_ipv6_unicast_mac;
        rewrite_ipv6_multicast_mac;


        rewrite_mpls_mac;

    }
    size : 512;
}

control process_mac_rewrite {
    if (egress_metadata.routed == 1) {
        apply(mac_rewrite);
    }
}
control process_mtu {





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
        fib_terminate_tunnel;
    }
    size : 131072;
}

table ipv4_fib_1 {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
  fib_terminate_tunnel;
    }
    size : 131072;
}

table ipv4_fib_2 {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
  fib_terminate_tunnel;
    }
    size : 131072;
}

table ipv4_fib_3 {
    reads {
        l3_metadata.vrf : exact;
        ipv4_metadata.lkp_ipv4_da : exact;
    }
    actions {
        on_miss;
        fib_hit_nexthop;
        fib_hit_ecmp;
   fib_terminate_tunnel;
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

control process_fibv4 {
    apply(ipv4_fib) {
        on_miss {
            apply(ipv4_fib_1) {
          on_miss {
     apply(ipv4_fib_2) {
      on_miss {
       apply(ipv4_fib_3);
      }
     }
    }
            }
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
        tt1_key_type : 5;
        tt2_key_type : 5;
        tt_flag : 1;
        aib1_index : 18;
        aib2_index : 18;

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






action terminate_tunnel_inner_non_ip(bd, bd_label, stats_idx) {
    modify_field(tunnel_metadata.tunnel_terminate, 1);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.lkp_ip_type, 0);
    modify_field(l2_metadata.lkp_mac_sa, inner_ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, inner_ethernet.dstAddr);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);
}


action terminate_tunnel_inner_ethernet_ipv4(bd, vrf,
        rmac_group, bd_label,
        ipv4_unicast_enabled, ipv4_urpf_mode,
        igmp_snooping_enabled, stats_idx,
        ipv4_multicast_mode, mrpf_group) {
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
        ipv6_multicast_mode, mrpf_group) {
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

    modify_field(l3_metadata.lkp_ip_version, 6);
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

    modify_field(l3_metadata.lkp_ip_version, 6);
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






table tunnel {
    reads {
        tunnel_metadata.tunnel_vni : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        nop;
        terminate_tunnel_inner_non_ip;

        terminate_tunnel_inner_ethernet_ipv4;
        terminate_tunnel_inner_ipv4;


        terminate_tunnel_inner_ethernet_ipv6;
        terminate_tunnel_inner_ipv6;

    }
    size : 16384;
}


control process_tunnel {


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


    if ((tunnel_metadata.tunnel_terminate == 1) or
        ((multicast_metadata.outer_mcast_route_hit == 1) and
         (((multicast_metadata.outer_mcast_mode == 1) and
           (multicast_metadata.mcast_rpf_group == 0)) or
          ((multicast_metadata.outer_mcast_mode == 2) and
           (multicast_metadata.mcast_rpf_group != 0))))) {
        apply(tunnel);
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

    modify_field(l3_metadata.lkp_ip_version, 6);
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
    remove_header(udp);
    remove_header(vxlan);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_vxlan_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(udp);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_vxlan_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(udp);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(ipv6);
}

action decap_genv_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(udp);
    remove_header(genv);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_genv_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(udp);
    remove_header(genv);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_genv_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(udp);
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
    remove_header(udp);
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
}

action decap_inner_icmp() {
    copy_header(icmp, inner_icmp);
    remove_header(inner_icmp);
}

action decap_inner_unknown() {
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





field_list entropy_hash_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ethernet.etherType;
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
}

field_list_calculation entropy_hash {
    input {
        entropy_hash_fields;
    }
    algorithm : crc16;
    output_width : 16;
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


    modify_field(udp.srcPort, 0);



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
    modify_field(ipv6.nextHdr, proto);
    modify_field(ipv6.hopLimit, 64);
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


    modify_field(udp.srcPort, 0);



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
    modify_field(nvgre.reserved, 0);
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





action set_tunnel_rewrite_details(outer_bd, mtu_index, smac_idx, dmac_idx,
                                  sip_index, dip_index) {
    modify_field(egress_metadata.outer_bd, outer_bd);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
    modify_field(tunnel_metadata.tunnel_src_index, sip_index);
    modify_field(tunnel_metadata.tunnel_dst_index, dip_index);
    modify_field(l3_metadata.mtu_index, mtu_index);
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

        apply(tunnel_src_rewrite);
        apply(tunnel_dst_rewrite);
        apply(tunnel_smac_rewrite);
        apply(tunnel_dmac_rewrite);
    }

}

action aib_invalid_drop() {
 modify_field(ingress_metadata.causeId, 8);
 drop();
}

action aib_tocp_drop() {
 modify_field(ingress_metadata.causeId, 102);
 drop();
}

action aib_vxlan() {
    modify_field(l2_metadata.aib_opcode, 14);
    modify_field(tunnel_metadata.egress_tunnel_type, 3);
}

action aib_trans() {
    modify_field(l2_metadata.aib_opcode, 8);
}

action aib_elb_l2mc_notunnel_pri_set(tag_num, pri) {
 modify_field(l2_metadata.tag_num, tag_num);
 modify_field(l2_metadata.outer_tag_pri, pri);
 modify_field(tunnel_metadata.aib2_index, 0);
}

action aib_elb_l2mc_notunnel_nopri_set(tag_num) {
 modify_field(l2_metadata.tag_num, tag_num);
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
}

action aib_elb_l2mc_tunnel_pri_set(tag_num, pri) {
 modify_field(l2_metadata.tag_num, tag_num);
 modify_field(l2_metadata.outer_tag_pri, pri);
 modify_field(tunnel_metadata.aib2_index, 0);
}

action aib_elb_l2mc_tunnel_nopri_set(tag_num) {
 modify_field(l2_metadata.tag_num, tag_num);
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
}

action aib_elb_l3mc_notunnel_1tag_pri_set(OTag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 4);
 modify_field(l2_metadata.new_ovlan_info, OTag);
}

action aib_elb_l3mc_notunnel_2tag_pri_set(OTag, ITag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
 modify_field(l2_metadata.tag2_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 8);
 modify_field(l2_metadata.new_ovlan_info, OTag);
 modify_field(l2_metadata.new_ivlan_info, ITag);
}

action aib_elb_l3mc_notunnel_1tag_nopri_set(OTag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 4);

}

action aib_elb_l3mc_notunnel_2tag_nopri_set(OTag, ITag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.tag1_valid, 1);
 modify_field(l2_metadata.tag2_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 8);


}

action aib_elb_l3mc_tunnel_1tag_pri_set(OTag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 4);
 modify_field(l2_metadata.new_ovlan_info, OTag);
}

action aib_elb_l3mc_tunnel_2tag_pri_set(OTag, ITag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 8);
 modify_field(l2_metadata.Inew_ovlan_info, OTag);
 modify_field(l2_metadata.Inew_ivlan_info, ITag);
}

action aib_elb_l3mc_tunnel_1tag_nopri_set(OTag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 4);

}

action aib_elb_l3mc_tunnel_2tag_nopri_set(OTag, ITag) {
 modify_field(tunnel_metadata.aib2_index, 0);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
 modify_field(l2_metadata.TagHeadLen, 8);


}


action aib_tocp() {
 drop();
}

action aib_elb_virtualtunnel_car_nottflag(next_aib_index, vsi, carid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.carid_elb, carid);
}

action aib_elb_virtualtunnel_car_ttflag_l2(next_aib_index, vsi, carid, pri) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.carid_elb, carid);
 modify_field(l2_metadata.outer_tag_pri, pri);
}

action aib_elb_virtualtunnel_car_ttflag_l3_1tag(next_aib_index, vsi, carid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.carid_elb, carid);
 modify_field(l2_metadata.Itag1_valid, 1);
}

action aib_elb_virtualtunnel_car_ttflag_l3_2tag(next_aib_index, vsi, carid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.carid_elb, carid);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
}

action aib_elb_virtualtunnel_car_ttflag_l3_1tag_vlanpricfg(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.Itag1_valid, 1);
}

action aib_elb_virtualtunnel_car_ttflag_l3_2tag_vlanpricfg(next_aib_index, vsi, carid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.carid_elb, carid);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
}

action aib_elb_virtualtunnel_stat_nottflag(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
}

action aib_elb_virtualtunnel_stat_ttflag_l2(next_aib_index, vsi, statid, pri) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.outer_tag_pri, pri);
}

action aib_elb_virtualtunnel_stat_ttflag_l3_1tag(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.Itag1_valid, 1);
}

action aib_elb_virtualtunnel_stat_ttflag_l3_2tag(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
}

action aib_elb_virtualtunnel_stat_ttflag_l3_1tag_vlanpricfg(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.Itag1_valid, 1);
}

action aib_elb_virtualtunnel_stat_ttflag_l3_2tag_vlanpricfg(next_aib_index, vsi, statid) {
 modify_field(tunnel_metadata.aib2_index, next_aib_index);
 modify_field(l2_metadata.vsi, vsi);
 modify_field(qos_metadata.statid_elb, statid);
 modify_field(l2_metadata.Itag1_valid, 1);
 modify_field(l2_metadata.Itag2_valid, 1);
}

table aib1 {
 reads {
  tunnel_metadata.aib1_index : exact;
 }
 actions {
  aib_invalid_drop;
  aib_elb_l2mc_notunnel_pri_set;
  aib_elb_l2mc_notunnel_nopri_set;
  aib_elb_l2mc_tunnel_pri_set;
  aib_elb_l2mc_tunnel_nopri_set;

  aib_elb_l3mc_notunnel_1tag_pri_set;
  aib_elb_l3mc_notunnel_2tag_pri_set;
  aib_elb_l3mc_notunnel_1tag_nopri_set;
  aib_elb_l3mc_notunnel_2tag_nopri_set;
  aib_elb_l3mc_tunnel_1tag_pri_set;
    aib_elb_l3mc_tunnel_2tag_nopri_set;
  aib_tocp;

  aib_elb_virtualtunnel_car_nottflag;
  aib_elb_virtualtunnel_car_ttflag_l2;
  aib_elb_virtualtunnel_car_ttflag_l3_1tag;
  aib_elb_virtualtunnel_car_ttflag_l3_2tag;
  aib_elb_virtualtunnel_car_ttflag_l3_1tag_vlanpricfg;
  aib_elb_virtualtunnel_car_ttflag_l3_2tag_vlanpricfg;

  aib_elb_virtualtunnel_stat_nottflag;
  aib_elb_virtualtunnel_stat_ttflag_l2;
  aib_elb_virtualtunnel_stat_ttflag_l3_1tag;
  aib_elb_virtualtunnel_stat_ttflag_l3_2tag;
  aib_elb_virtualtunnel_stat_ttflag_l3_1tag_vlanpricfg;
  aib_elb_virtualtunnel_stat_ttflag_l3_2tag_vlanpricfg;


  nop;
 }
 size : 1024;
}

action aib2_trans() {

}

action aib2_vxlan_tag0() {
 ipv4_vxlan_rewrite();
}

action aib2_vxlan_tag1() {
 ipv4_vxlan_rewrite();
}

action aib2_vxlan_tag2() {
 ipv4_vxlan_rewrite();
}

table aib2 {
 reads {
  tunnel_metadata.aib2_index : exact;
 }
 actions {
  aib2_trans;
  aib2_vxlan_tag0;
  aib2_vxlan_tag1;
  aib2_vxlan_tag2;
 }
}

action evsi_invalid_drop() {
 drop();
}

action evsi_l3(smac) {
 modify_field(ethernet.srcAddr, smac);
}

table evsi {
 reads {
  l2_metadata.vsi : exact;
 }
 actions {
  evsi_invalid_drop;
  evsi_l3;
  nop;
 }
}

action aib3_invalid_drop() {
 drop();
}

action aib3_chg_dmac(dmac) {
 modify_field(ethernet.dstAddr, dmac);
}

table aib3 {
 reads {
  tunnel_metadata.aib1_index : exact;
 }
 actions {
  aib3_invalid_drop;
  aib3_chg_dmac;
 }
}

control process_aib {
 if(tunnel_metadata.aib2_index != 0) {
  apply(aib1);
 }
 if(tunnel_metadata.aib2_index != 0) {
  apply(aib2) {
   aib2_vxlan_tag0,
   aib2_vxlan_tag1,
   aib2_vxlan_tag2 {
    apply(evsi) {
     evsi_l3 {
      apply(aib3);
     }
    }
   }
  }
 }
}

action route_novlan_drop() {
 drop();
}

action trunk_bridge_noiso_pv(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
 modify_field(ethernet.srcAddr, smac);
}

action notrunk_bridge_noiso_pv(tp, smac) {
 modify_field(l2_metadata.DstPort_Tp, tp);
 modify_field(ethernet.srcAddr, smac);
}

action trunk_route_noiso_pv(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
}

action notrunk_route_noiso_pv(tp) {
 modify_field(l2_metadata.DstPort_Tp, tp);
}

action trunk_bridge_noiso_pvv(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
 modify_field(ethernet.srcAddr, smac);
}

action notrunk_bridge_noiso_pvv(tp, smac) {
 modify_field(l2_metadata.DstPort_Tp, tp);
 modify_field(ethernet.srcAddr, smac);
}

action trunk_route_noiso_pvv(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
}

action notrunk_route_noiso_pvv(tp) {
 modify_field(l2_metadata.DstPort_Tp, tp);
}

action trunk_bridge_noiso_pvpri(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
 modify_field(ethernet.srcAddr, smac);
}

action notrunk_bridge_noiso_pvpri(tp, smac) {
 modify_field(l2_metadata.DstPort_Tp, tp);
 modify_field(ethernet.srcAddr, smac);
}

action trunk_route_noiso_pvpri(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
}

action notrunk_route_noiso_pvpri(tp) {
 modify_field(l2_metadata.DstPort_Tp, tp);
}

action trunk_bridge_l2_isolation(trunk_id, smac) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
 modify_field(ethernet.srcAddr, smac);
}

action notrunk_bridge_l2_isolation(tp, smac) {
 modify_field(l2_metadata.DstPort_Tp, tp);
 modify_field(ethernet.srcAddr, smac);
}

action trunk_route_l3_isolation(trunk_id) {
 modify_field(l2_metadata.DstPort_TrunkId, trunk_id);
 modify_field(l2_metadata.DstPort_TrunkFlag, 1);
}

action notrunk_route_l3_isolation(tp) {
 modify_field(l2_metadata.DstPort_Tp, tp);
}

table epat {
 reads {
  l2_metadata.oport_info : exact;
  l2_metadata.l2_isolation : exact;
  l2_metadata.l3_isolation : exact;
 }
 actions {
  trunk_bridge_noiso_pv;
  notrunk_bridge_noiso_pv;
  trunk_route_noiso_pv;
  notrunk_route_noiso_pv;

  trunk_bridge_noiso_pvv;
  notrunk_bridge_noiso_pvv;
  trunk_route_noiso_pvv;
  notrunk_route_noiso_pvv;

  trunk_bridge_noiso_pvpri;
  notrunk_bridge_noiso_pvpri;
  trunk_route_noiso_pvpri;
  notrunk_route_noiso_pvpri;

  trunk_bridge_l2_isolation;
  notrunk_bridge_l2_isolation;
  trunk_route_l3_isolation;
  notrunk_route_l3_isolation;

  route_novlan_drop;
 }
 size : 256;
}

action isolate_pv() {

}

action isolate_pvv() {

}

action isolate_pvpri() {

}

table l2_isolate {
 reads {
  l2_metadata.DstPort_Tp : exact;
  l2_metadata.sb : exact;
  l2_metadata.spindex : exact;
 }
 actions {
  isolate_pv;
  isolate_pvv;
  isolate_pvpri;
  nop;
 }
}

action cwp_terminate_process() {
 remove_header(ethernet);
    remove_header(ipv4);
}

table cwp_terminate {
 actions {
  cwp_terminate_process;
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
        if_label : 15;
        bd_label : 16;
        mirror_session_id : 10;
    }
}
header_type qos_metadata_t {
    fields {
        outer_dscp : 8;
        marked_cos : 3;
        marked_dscp : 8;
        marked_exp : 3;
        mirror_en : 1;
        mirror_id : 8;
        bum_carid : 20;
        vlanacl_en : 1;
        nac_en : 1;
        nac_info : 11;
        mcctrl_data : 16;
        car_cnt_en : 2;
        carid : 16;
        countid : 16;
        countEn : 1;
        classid : 6;
        ivsi_carid : 16;
        unuc_en : 1;
        bc_en : 1;
        mgid : 16;
        vlanacl_vp : 1;
        vlanacl_vp_gid : 13;
        vlanacl_novp_trunkflag : 1;
        vlanacl_novp_trunkid : 10;
        vlanacl_novp_sp : 8;
        vlanacl_dscp : 6;
        vlanacl_dip : 32;
        vlanacl_sip : 32;
        vlanacl_protocol : 8;
        vlanacl_icmpcode : 8;
        vlanacl_icmptype : 8;
        vlanacl_igmptype : 8;
        vlanacl_dport : 16;
        vlanacl_sport : 16;
        vlanacl_snap : 1;
        vlanacl_llc : 1;
        vlanacl_mf : 1;
        vlanacl_offsetZero : 1;
        outpri_act : 1;
        outcfi_act : 1;
        innerpri_act : 1;
        innercfi_act : 1;
        search_type0 : 1;
        search_profile0 : 6;
        search_type1 : 1;
        search_profile1 : 6;
        tid1 : 4;
        tid0 : 4;
        tnl_terminate : 1;
        local_mac_hit : 1;
        tcc_type : 4;
        outer_vlan : 16;
        protocol_bitmap : 16;
        trunk_flag : 1;
        frag : 1;
        option_flag : 1;
        trunkid : 10;
        sportinfo : 16;
        icmp_type : 8;
        l4dport : 16;
        l4sport : 16;
        ethType : 16;
        ipri2opri : 1;
        carid_elb : 16;
        statid_elb : 16;
        acltype : 3;
        phbEn : 1;
        carcntEn : 2;
        vt : 1;
        evlanCarCntId : 20;
        stgId : 9;
    }
}

header_type i2e_metadata_t {
    fields {
        ingress_tstamp : 32;
        mirror_session_id : 16;
    }
}
@pragma pa_solitary ingress acl_metadata.if_label

metadata acl_metadata_t acl_metadata;
metadata qos_metadata_t qos_metadata;
metadata i2e_metadata_t i2e_metadata;





action acl_log() {
    modify_field(ingress_metadata.enable_dod, 0);
}

action acl_deny() {
    modify_field(acl_metadata.acl_deny, 1);
    modify_field(ingress_metadata.enable_dod, 0);
}

action acl_permit() {
    modify_field(ingress_metadata.enable_dod, 0);
}

field_list i2e_mirror_info {
    i2e_metadata.ingress_tstamp;
    i2e_metadata.mirror_session_id;
}
field_list e2e_mirror_info {
    i2e_metadata.mirror_session_id;
}

action acl_mirror(session_id) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    modify_field(i2e_metadata.ingress_tstamp, ig_intr_md_from_parser_aux.ingress_global_tstamp);
    modify_field(ingress_metadata.enable_dod, 0);
    clone_ingress_pkt_to_egress(session_id, i2e_mirror_info);
}

action acl_redirect_nexthop(nexthop_index) {
    modify_field(acl_metadata.acl_redirect, 1);

    modify_field(l3_metadata.nexthop_index, nexthop_index);
    modify_field(acl_metadata.acl_nexthop_type, 0);
    modify_field(ingress_metadata.enable_dod, 0);
}

action acl_redirect_ecmp(ecmp_index) {
    modify_field(acl_metadata.acl_redirect, 1);

 modify_field(l3_metadata.nexthop_index, ecmp_index);
    modify_field(acl_metadata.acl_nexthop_type, 1);
    modify_field(ingress_metadata.enable_dod, 0);
}

action acl_dod_en() {
    modify_field(ingress_metadata.enable_dod, 1);
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
        acl_log;
        acl_deny;
        acl_permit;
        acl_mirror;
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
        l3_metadata.ToBras : exact;
        l3_metadata.SrcClassId : ternary;
    }
    actions {
        nop;
        acl_log;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_dod_en;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
        on_miss;
    }
    size : 2048;
}

table ip_acl_1 {
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
        l3_metadata.ToBras : exact;
     l3_metadata.SrcClassId : ternary;
    }
    actions {
        nop;
        acl_log;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_dod_en;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
        on_miss;
    }
    size : 2048;
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
        l3_metadata.ToBras : exact;
    }
    actions {
        nop;
        acl_log;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
        on_miss;
    }
    size : 512;
}

table ipv6_acl_1 {
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
        l3_metadata.ToBras : exact;
    }
    actions {
        nop;
        acl_log;
        acl_deny;
        acl_permit;
        acl_mirror;
        acl_redirect_nexthop;
        acl_redirect_ecmp;
        on_miss;
    }
    size : 512;
}






control process_ip_acl {

    if (l3_metadata.lkp_ip_type == 1) {

        apply(ip_acl) {
   on_miss {
    apply(ip_acl_1);
   }
        }

    } else {
        if (l3_metadata.lkp_ip_type == 2) {

            apply(ipv6_acl);

        }
    }

}
control process_qos {



}






action racl_log() {
}

action racl_deny() {
    modify_field(acl_metadata.racl_deny, 1);
}

action racl_permit() {
}

action racl_set_nat_mode(nat_mode) {
    modify_field(nat_metadata.ingress_nat_mode, nat_mode);
}

action racl_redirect_nexthop(nexthop_index) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, nexthop_index);
    modify_field(acl_metadata.racl_nexthop_type, 0);
}

action racl_redirect_ecmp(ecmp_index) {
    modify_field(acl_metadata.racl_redirect, 1);
    modify_field(acl_metadata.racl_nexthop, ecmp_index);
    modify_field(acl_metadata.racl_nexthop_type, 1);
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
        racl_log;
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
        racl_log;
        racl_deny;
        racl_permit;
        racl_set_nat_mode;
        racl_redirect_nexthop;
        racl_redirect_ecmp;
    }
    size : 1024;
}


control process_ipv6_racl {

    apply(ipv6_racl);

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
}

action copy_to_cpu(reason_code) {
    modify_field(fabric_metadata.reason_code, reason_code);
    clone_ingress_pkt_to_egress(250, cpu_info);
}

action drop_packet() {
    drop();
}

action drop_packet_with_reason(drop_reason) {
    count(drop_stats, drop_reason);
    drop();
}

action congestion_mirror_set() {
    deflect_on_drop(1);
}

table system_acl {
    reads {
        acl_metadata.if_label : ternary;
        acl_metadata.bd_label : ternary;


        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;


        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l2_metadata.lkp_mac_type : ternary;

        ingress_metadata.ifindex : ternary;


        l2_metadata.port_vlan_mapping_miss : ternary;
        security_metadata.ipsg_check_fail : ternary;
        acl_metadata.acl_deny : ternary;
        acl_metadata.racl_deny: ternary;
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


        ingress_metadata.egress_ifindex : ternary;


        ingress_metadata.enable_dod: ternary;
    }
    actions {
        nop;
        redirect_to_cpu;
        copy_to_cpu;
        drop_packet;
        drop_packet_with_reason;
        negative_mirror;
        congestion_mirror_set;
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






action egress_port_mirror(session_id) {
    modify_field(i2e_metadata.mirror_session_id, session_id);
    clone_egress_pkt_to_egress(session_id, e2e_mirror_info);
}

action egress_port_mirror_drop(session_id) {
    egress_port_mirror(session_id);
    drop();
}
table egress_acl {
    reads {
        eg_intr_md.egress_port : ternary;
        eg_intr_md.deflection_flag : ternary;
        l3_metadata.l3_mtu_check : ternary;
    }
    actions {
        nop;
        egress_port_mirror;
        egress_port_mirror_drop;



    }
    size : 1024;
}


control process_egress_acl {

    apply(egress_acl);

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
        outer_ipv4_mcast_key_type : 1;
        outer_ipv4_mcast_key : 16;
        outer_ipv6_mcast_key_type : 1;
        outer_ipv6_mcast_key : 16;
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

    bit_and(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
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
        multicast_metadata.outer_ipv4_mcast_key_type : exact;
        multicast_metadata.outer_ipv4_mcast_key : exact;
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
        multicast_metadata.outer_ipv4_mcast_key_type : exact;
        multicast_metadata.outer_ipv4_mcast_key : exact;
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
        multicast_metadata.outer_ipv6_mcast_key_type : exact;
        multicast_metadata.outer_ipv6_mcast_key : exact;
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
        multicast_metadata.outer_ipv6_mcast_key_type : exact;
        multicast_metadata.outer_ipv6_mcast_key : exact;
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

    bit_xor(multicast_metadata.mcast_rpf_group, mcast_rpf_group,
            multicast_metadata.bd_mrpf_group);



}

action multicast_route_s_g_hit(mc_index, mcast_rpf_group) {
    modify_field(multicast_metadata.multicast_route_mc_index, mc_index);
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
        nop;
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
        nop;
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
        nop;
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
        nop;
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





field_list inner_ipv4_hash1_fields {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;
}

field_list inner_ipv4_hash2_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;
}

field_list_calculation inner_ipv4_hash1 {
    input {
        inner_ipv4_hash1_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

field_list_calculation inner_ipv4_hash2 {
    input {
        inner_ipv4_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_inner_ipv4_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, inner_ipv4_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, inner_ipv4_hash2, 8192);
}

field_list inner_ipv6_hash1_fields {
    inner_ipv6.srcAddr;
    inner_ipv6.dstAddr;
    inner_ipv6.nextHdr;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;
}

field_list inner_ipv6_hash2_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ipv6.srcAddr;
    inner_ipv6.dstAddr;
    inner_ipv6.nextHdr;
    l3_metadata.lkp_inner_l4_sport;
    l3_metadata.lkp_inner_l4_dport;
}

field_list_calculation inner_ipv6_hash1 {
    input {
        inner_ipv6_hash1_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

field_list_calculation inner_ipv6_hash2 {
    input {
        inner_ipv6_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_inner_ipv6_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, inner_ipv6_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, inner_ipv6_hash2, 8192);
}

field_list inner_non_ip_hash1_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ethernet.etherType;
}

field_list inner_non_ip_hash2_fields {
    inner_ethernet.srcAddr;
    inner_ethernet.dstAddr;
    inner_ethernet.etherType;
}

field_list_calculation inner_non_ip_hash1 {
    input {
        inner_non_ip_hash1_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

field_list_calculation inner_non_ip_hash2 {
    input {
        inner_non_ip_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_inner_non_ip_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, inner_non_ip_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, inner_non_ip_hash2, 8192);
}

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
    output_width : 8;
}

field_list_calculation lkp_ipv4_hash2 {
    input {
        lkp_ipv4_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_lkp_ipv4_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, lkp_ipv4_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, lkp_ipv4_hash2, 8192);
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
    output_width : 8;
}

field_list_calculation lkp_ipv6_hash2 {
    input {
        lkp_ipv6_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_lkp_ipv6_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, lkp_ipv6_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, lkp_ipv6_hash2, 8192);
}

field_list lkp_non_ip_hash1_fields {
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
}

field_list lkp_non_ip_hash2_fields {
    l2_metadata.lkp_mac_sa;
    l2_metadata.lkp_mac_da;
    l2_metadata.lkp_mac_type;
}

field_list_calculation lkp_non_ip_hash1 {
    input {
        lkp_non_ip_hash1_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

field_list_calculation lkp_non_ip_hash2 {
    input {
        lkp_non_ip_hash2_fields;
    }
    algorithm : crc16;
    output_width : 8;
}

action compute_lkp_non_ip_hash() {
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level1_mcast_hash,
                                        0, lkp_non_ip_hash1, 8192);
    modify_field_with_hash_based_offset(ig_intr_md_for_tm.level2_mcast_hash,
                                        0, lkp_non_ip_hash2, 8192);
}

table compute_multicast_hashes {
    reads {
        ingress_metadata.port_type : ternary;
        tunnel_metadata.tunnel_terminate : ternary;
        ipv4 : valid;
        ipv6 : valid;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        nop;
        compute_lkp_ipv4_hash;
    }
}

control process_multicast_hashes {

    apply(compute_multicast_hashes);

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






action outer_replica_from_rid(bd, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 0);
    modify_field(egress_metadata.routed, l3_metadata.routed);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action outer_replica_from_rid_with_nexthop(bd, nexthop_index, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 0);
    modify_field(egress_metadata.routed, l3_metadata.outer_routed);
    modify_field(l3_metadata.nexthop_index, nexthop_index);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action inner_replica_from_rid(bd, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 1);
    modify_field(egress_metadata.routed, l3_metadata.routed);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action inner_replica_from_rid_with_nexthop(bd, nexthop_index, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.bd, bd);
    modify_field(multicast_metadata.replica, 1);
    modify_field(multicast_metadata.inner_replica, 1);
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(l3_metadata.nexthop_index, nexthop_index);
    bit_xor(egress_metadata.same_bd_check, bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

table rid {
    reads {
        eg_intr_md.egress_rid : exact;
    }
    actions {
        nop;
        outer_replica_from_rid;
        outer_replica_from_rid_with_nexthop;
        inner_replica_from_rid;
        inner_replica_from_rid_with_nexthop;
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



    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_route_mc_index);
}

action set_multicast_bridge_action() {



    modify_field(ig_intr_md_for_tm.mcast_grp_b,
                 multicast_metadata.multicast_bridge_mc_index);
}

table fwd_result {
    reads {
        l2_metadata.l2_redirect : ternary;
        acl_metadata.acl_redirect : ternary;
        acl_metadata.racl_redirect : ternary;
        l3_metadata.rmac_hit : ternary;
        l3_metadata.fib_hit : ternary;
        nat_metadata.nat_hit : ternary;
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

    }
    size : 512;
}

control process_fwd_results {
    apply(fwd_result);
}





field_list l3_hash_fields {
    ipv4_metadata.lkp_ipv4_sa;
    ipv4_metadata.lkp_ipv4_da;
    l3_metadata.lkp_ip_proto;
    l3_metadata.lkp_l4_sport;
    l3_metadata.lkp_l4_dport;
}

field_list_calculation ecmp_hash {
    input {
        l3_hash_fields;
    }
    algorithm : crc16;
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

action set_nexthop_details(ifindex, bd, tunnel, is_trunk, trunkId) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);
    bit_xor(tunnel_metadata.tunnel_if_check,
            tunnel_metadata.tunnel_terminate, tunnel);
    modify_field(l2_metadata.oport_is_trunk, is_trunk);
    modify_field(l2_metadata.trunk_id, trunkId);
}

action set_ecmp_nexthop_details(ifindex, bd, nhop_index, tunnel) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);
    modify_field(l3_metadata.nexthop_index, nhop_index);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);
    bit_xor(l2_metadata.same_if_check, l2_metadata.same_if_check, ifindex);
    bit_xor(tunnel_metadata.tunnel_if_check,
            tunnel_metadata.tunnel_terminate, tunnel);
}
action set_nexthop_details_for_post_routed_flood(bd, uuc_mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, uuc_mc_index);
    modify_field(ingress_metadata.egress_ifindex, 0);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);



}

action set_ecmp_nexthop_details_for_post_routed_flood(bd, uuc_mc_index,
                                                      nhop_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, uuc_mc_index);
    modify_field(l3_metadata.nexthop_index, nhop_index);
    modify_field(ingress_metadata.egress_ifindex, 0);
    bit_xor(l3_metadata.same_bd_check, ingress_metadata.bd, bd);



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

action set_l3_rewrite_with_tunnel(bd, smac_idx, dmac,
                                  tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.smac_idx, smac_idx);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action set_l3_rewrite(bd, mtu_index, smac_idx, dmac) {
    modify_field(egress_metadata.routed, 1);
    modify_field(egress_metadata.smac_idx, smac_idx);
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

action set_mpls_swap_push_rewrite_l3(bd, smac_idx, dmac,
                                     label, tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(mpls[0].label, label);
    modify_field(egress_metadata.smac_idx, smac_idx);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 14);
}

action set_mpls_push_rewrite_l3(bd, smac_idx, dmac,
                                tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.smac_idx, smac_idx);
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

control process_rewrite {
    apply(rewrite);
}







header_type security_metadata_t {
    fields {
        storm_control_color : 1;
        ipsg_enabled : 1;
        ipsg_check_fail : 1;
    }
}

metadata security_metadata_t security_metadata;
control process_storm_control {



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





    actions {
        terminate_cpu_packet;
    }
}
control process_ingress_fabric {




}
control process_fabric_lag {



}





action cpu_rx_rewrite() {
    add_header(fabric_header);
    modify_field(fabric_header.headerVersion, 0);
    modify_field(fabric_header.packetVersion, 0);
    modify_field(fabric_header.pad1, 0);
    modify_field(fabric_header.packetType, 5);
    modify_field(fabric_header.ingressIfindex, ingress_metadata.ifindex);
    modify_field(fabric_header.ingressBd, ingress_metadata.bd);
    add_header(fabric_header_cpu);
    modify_field(fabric_header_cpu.reasonCode, fabric_metadata.reason_code);
    modify_field(fabric_header_cpu.ingressPort, ingress_metadata.ingress_port);
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

action nop() {
}

action on_miss() {
}

control ingress {

    if (ig_intr_md.resubmit_flag == 0) {
     process_ipat();
  process_icib();
 } else if(ingress_metadata.cwpTtFlag == 1) {

  apply(cwp_terminate);
 }


 if(((l2_metadata.ttFlag != 1 ) and ((ig_intr_md.resubmit_flag == 0)))
  or ((l2_metadata.ttFlag == 1 ) and (ig_intr_md.resubmit_flag == 1))
  or ((ingress_metadata.cwpTtFlag == 1 ) and (ig_intr_md.resubmit_flag == 1))) {
  process_bras();

  process_fibv4();
 }

 process_ip_acl();

 process_nexthop();

 process_oportinfo();
}
