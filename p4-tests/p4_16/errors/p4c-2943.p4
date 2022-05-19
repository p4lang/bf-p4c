#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

header b128_h {
    bit<1024> bits;
}

header b64_h {
    bit<512> bits;
}

header b32_h {
    bit<256> bits;
}

header b16_h {
    bit<128> bits;
}

header b8_h {
    bit<64> bits;
}

header b4_h {
    bit<32> bits;
}

header b2_h {
    bit<16> bits;
}

header b1_h {
    bit<8> bits;
}


header interveningData_h {
    bit<8> nextHeaderType;
}

header realData2_h {
    bit<128> data;
}

header realData_h {
    bit<8> counterIndex;
    bit<8> controlIndex;
    bit<16> control2Index;
    bit<8> r1;
    bit<8> r2;
}

struct SkipHeaders {
    b128_h b128;
    b64_h b64;
    b32_h b32;
    b16_h b16;
    b8_h b8;
    b4_h b4;
    b2_h b2;
    b1_h b1;
}

struct InterveningHeaders {
    interveningData_h i1;
    interveningData_h i2;
    interveningData_h i3;
}

struct myHeaders {
    SkipHeaders skip;
    InterveningHeaders intervene;
    realData2_h c2;
    realData_h ctr;
}

struct portMetadata_t {
    bit<8> skipKey;
}

struct metadata {
    portMetadata_t portMetadata;
}

struct emetadata {}

parser SkipData(packet_in pkt, out SkipHeaders hdr, in bit<8> skipLength) {
    state start {
        transition select(skipLength) {
            0x80 &&& 0x80 : r128;
            0x40 &&& 0x40 : r64;
            0x20 &&& 0x20 : r32;
            0x10 &&& 0x10 : r16;
            0x08 &&& 0x08 : r8;
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r128 {
        pkt.extract(hdr.b128);
        transition select(skipLength) {
            0x40 &&& 0x40 : r64;
            0x20 &&& 0x20 : r32;
            0x10 &&& 0x10 : r16;
            0x08 &&& 0x08 : r8;
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r64 {
        pkt.extract(hdr.b64);
        transition select(skipLength) {
            0x20 &&& 0x20 : r32;
            0x10 &&& 0x10 : r16;
            0x08 &&& 0x08 : r8;
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r32 {
        pkt.extract(hdr.b32);
        transition select(skipLength) {
            0x10 &&& 0x10 : r16;
            0x08 &&& 0x08 : r8;
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r16 {
        pkt.extract(hdr.b16);
        transition select(skipLength) {
            0x08 &&& 0x08 : r8;
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r8 {
        pkt.extract(hdr.b8);
        transition select(skipLength) {
            0x04 &&& 0x04 : r4;
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r4 {
        pkt.extract(hdr.b4);
        transition select(skipLength) {
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r2 {
        pkt.extract(hdr.b2);
        transition select(skipLength) {
            0x02 &&& 0x02 : r2;
            0x01 &&& 0x01 : r1;
            default : accept;
        }
    }
    state r1 {
        pkt.extract(hdr.b1);
        transition accept;
    }
}

parser InterveningDataChain(packet_in pkt, out InterveningHeaders hdr, out bit<8> nextHeader) {
    state start {
        pkt.extract(hdr.i1);
        transition select(hdr.i1.nextHeaderType) {
            0 : parse2;
            1 : finish1;
            default : finishOther;
        }
    }
    state finish1 {
        nextHeader = 1;
        transition accept;
    }
    state parse2 {
        pkt.extract(hdr.i2);
        transition select(hdr.i2.nextHeaderType) {
            0 : parse3;
            1 : finish1;
            default : finishOther;
        }
    }
    state finishOther {
        nextHeader = 2;
        transition accept;
    }
    state parse3 {
        pkt.extract(hdr.i3);
        transition select(hdr.i3.nextHeaderType) {
            1 : finish1;
            default : finishOther;
        }
    }
}

parser IngressParser(packet_in        pkt,
    out myHeaders         hdr,
    out metadata         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    SkipData() skipper;
    InterveningDataChain() interv;
    state start {
        bit<8> nextHeader;
        pkt.extract(ig_intr_md);
        meta.portMetadata = port_metadata_unpack<portMetadata_t>(pkt);
        skipper.apply(pkt,hdr.skip,meta.portMetadata.skipKey);
        interv.apply(pkt,hdr.intervene,nextHeader);
        transition select(nextHeader) {
            1 : dataExtract2;
            default : dataExtract;
        }
    }

    state dataExtract2 {
        pkt.extract(hdr.c2);
        transition dataExtract;
    }

    state dataExtract {
        pkt.extract(hdr.ctr);
        transition accept;
    }
}



control Ingress(
    inout myHeaders                       hdr,
    inout metadata                     meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Counter<bit<64>,bit<8> >(256,CounterType_t.PACKETS_AND_BYTES) counters;
    apply {
        if(hdr.ctr.isValid()) {
            counters.count(hdr.ctr.counterIndex);
        }
    }
}

control IngressDeparser(
    packet_out pkt,
    inout myHeaders headers,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata
) {
    apply {
        pkt.emit(headers);
    }
}

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


