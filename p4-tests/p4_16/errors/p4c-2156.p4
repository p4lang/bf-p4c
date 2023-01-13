/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

typedef bit<8> vrf_id_t;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_t {
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
    bit<64>  fake_ether_type;
}

header vlan_tag_t {
    bit<3>   pcp;
    bit<1>   cfi;
    bit<12>  vid;
    bit<16>  ether_type;
}

header ipv4_t {
    bit<4>   version;
    bit<4>   ihl;
    bit<8>   diffserv;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_t         ethernet;
    ipv4_t             ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t
{
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in      pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition ethernet;
    }

    state ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.fake_ether_type)
        {
            0x1020304050607080: parse_ipv4; // expect error: "unsupported 64-bit select"
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

typedef bit<32> data_t;
typedef bit<32> flow_num_t;

#define MAX_FLOW_COUNT 10000

control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ipv4_host_stats;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ipv4_lpm_stats;

    Register<data_t, flow_num_t>(MAX_FLOW_COUNT) regTest;

    RegisterAction<data_t, flow_num_t, data_t>(regTest) addFlowTraffic = {
        void apply(inout data_t register_data)
        {
            register_data = register_data + (data_t)hdr.ipv4.total_len;
        }
    };


    action send(PortId_t port)
    {
        ig_tm_md.ucast_egress_port = port;
    }
    action drop()
    {
        ig_dprsr_md.drop_ctl = 1;
    }

    action hostSend(PortId_t port)
    {
        ipv4_host_stats.count();
        send(port);
    }
    action hostDrop()
    {
        ipv4_host_stats.count();
        drop();
    }

    action lpmSend(PortId_t port)
    {
        ipv4_lpm_stats.count();
        send(port);
    }
    action lpmDrop()
    {
        ipv4_lpm_stats.count();
        drop();
    }

    table ipv4_host
    {
        key =
        {
            hdr.ipv4.dst_addr: exact;
        }
        actions =
        {
            hostSend; hostDrop;
            @defaultonly NoAction;
        }
        counters = ipv4_host_stats;
        default_action = NoAction();
    }

    table ipv4_lpm
    {
        key =
        {
            hdr.ipv4.dst_addr: lpm;
        }
        actions =
        {
            lpmSend; lpmDrop;
            @defaultonly NoAction;
        }
        counters = ipv4_lpm_stats;
        default_action = NoAction();
    }



    apply
    {
        if(hdr.ipv4.isValid())
        {
            if(!ipv4_host.apply().hit)
            {
                if(!ipv4_lpm.apply().hit)
                    send(64); //default action, but without direct counter
            }

            //Count this packet towards total flow data
            bit<32> flowID = 10;
            addFlowTraffic.execute(flowID);
        }


    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr
        });
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in      pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    DirectCounter<bit<64>>(CounterType_t.PACKETS) sizeBinCounter;

    action addToHistogram()
    {
        sizeBinCounter.count();
    }
    table size_histogram
    {
        key =
        {
            eg_intr_md.pkt_length : range;
        }
        actions =
        {
            addToHistogram();
        }
        counters = sizeBinCounter;
    }


    apply
    {
        size_histogram.apply();
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
