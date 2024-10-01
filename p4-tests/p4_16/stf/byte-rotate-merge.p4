#include <core.p4>
#include <tna.p4>

header data_h {
    bit<32> read;
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

@pa_container_size("ingress", "data.f1", 32)
@pa_container_size("ingress", "data.f2", 32)
@pa_container_size("ingress", "data.f3", 32)
@pa_container_size("ingress", "data.f4", 32)
struct my_ingress_headers_t {
    data_h data;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
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
        transition parse_data;
    }

    state parse_data {
        pkt.extract(hdr.data);
        transition accept;
    }
}


    /***************** M A T C H - A C T I O N  *********************/

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
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        ig_tm_md.bypass_egress     = 1;
    }


    table change_port {
        key = { hdr.data.read : exact; }
        actions = { send; }
    }

    action byte_swap1() {
        hdr.data.f1 = (
            hdr.data.f1[7:0] ++
            hdr.data.f1[15:8] ++
            hdr.data.f1[23:16] ++
            hdr.data.f1[31:24]);
    }

    action byte_swap2() {
        hdr.data.f1 = (
            hdr.data.f2[7:0] ++
            hdr.data.f2[15:8] ++
            hdr.data.f2[23:16] ++
            hdr.data.f2[31:24]);
    }

    action byte_swap3() {
        hdr.data.f1 = (
            hdr.data.f2[7:0] ++
            hdr.data.f3[15:8] ++
            hdr.data.f2[23:16] ++
            hdr.data.f3[31:24]);
    }


    action adata1(bit<8> param1, bit<8> param2) {
        hdr.data.f1[7:0] = param1;
        hdr.data.f1[31:24] = param2;
    }

    action adata2(bit<8> param1, bit<8> param2) {
        hdr.data.f1[7:0] = param1;
        hdr.data.f1[31:24] = param2;
        hdr.data.f1[23:8] = hdr.data.f2[23:8];
    }

    action adata3(bit<8> param1, bit<8> param2) {
        hdr.data.f1[7:0] = param1;
        hdr.data.f1[31:24] = param2;
        hdr.data.f1[23:8] = hdr.data.f2[15:0];
    }

    action adata4(bit<8> param1, bit<8> param2) {
        hdr.data.f1[7:0] = param1;
        hdr.data.f1[23:16] = param2;
        hdr.data.f1[15:8] = hdr.data.f2[15:8];
        hdr.data.f1[31:24] = hdr.data.f2[31:24];
    }

    action adata5(bit<8> param1, bit<8> param2, bit<8> param3, bit<8> param4) {
        hdr.data.f1[7:0] = param1;
        hdr.data.f1[23:16] = param2;
        hdr.data.f1[15:8] = hdr.data.f3[15:8];
        hdr.data.f1[31:24] = hdr.data.f3[31:24];
        hdr.data.f2[7:0] = hdr.data.f4[7:0];
        hdr.data.f2[23:16] = hdr.data.f4[23:16];
        hdr.data.f2[15:8] = param3;
        hdr.data.f2[31:24] = param4; 
    }
    

    table test1 {
        key = { hdr.data.read : exact; }
        actions = {
            byte_swap1;
            byte_swap2;
            byte_swap3;
            adata1;
            adata2;
            // adata3;
            adata4;
            adata5;
        }
    }

    apply {
        test1.apply();
        change_port.apply();
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
    apply {
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

parser EgressParser(packet_in        pkt,
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
    apply {
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
