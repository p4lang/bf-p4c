#include <core.p4>
#include <tna.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

struct headers {
    data_t data;
}


parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr,
                 inout metadata meta,
                 in ingress_intrinsic_metadata_t ig_intr_md,
                 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action setb1(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }

    action noop() {

    }

    table slicesAndAnnots {
        key = { 
            /// No Slice with no Annot
            hdr.data.f1 : exact; 
            // BF-RT : name: "hdr.data.f1", bit width: 32 
            // CJSON : name: "hdr.data.f1", bit width: 32, bit width full: 32

            /// No Slice with an Annot
            hdr.data.f2 : exact @name("f2X"); 
            // BF-RT : name: "f2X", bit width: 32 
            // CJSON : name: "f2X", bit width: 32, bit width full: 32

            /// Slice with no Annot
            hdr.data.f3[15:8] : exact; 
            // BF-RT : name: "hdr.data.f3[15:8]", bit width: 8, isFieldSlice: true 
            // CJSON : name: "hdr.data.f3", bit width: 8, bit width full: 32
            
            /// Slice with an Annot
            hdr.data.f4[15:8] : exact @name("f4X"); 
            // BF-RT : name: "f4X", bit width: 8
            // CJSON : name: "f4X", bit width: 8, bit width full: 8 
            
            /// Multiple Slices with no Annot
            hdr.data.f5[7:0] : exact; 
            // BF-RT : name: "hdr.data.f5", bit width: 8 isFieldSlice: true   
            // CJSON : name: "hdr.data.f5", bit width: 8, bit width full: 32 
            hdr.data.f5[15:8] : exact; 
            // BF-RT : name: "hdr.data.f5[15:8]", bit width: 8 isFieldSlic: true
            // CJSON : name: "hdr.data.f5", bit width: 8, bit width full: 32 
            
            /// Multiple Slices with multiple Annot 
            hdr.data.f6[7:0] : exact @name("f6X"); 
            // BF-RT : name: "f6X", bit width: 8
            // CJSON : name: "f6X", bit width: 8, bit width full: 8 
            hdr.data.f6[15:8] : exact @name("f6Y"); 
            // BF-RT : name: "f6Y", bit width: 8
            // CJSON : name: "f6Y", bit width: 8, bit width full: 8 
            
            /// Multiple Slices with single Annot
            hdr.data.f7[7:0] : exact @name("f7X"); 
            // BF-RT : name: "f7X", bit width: 8
            // CJSON : name: "f7X", bit width: 8, bit width full: 8 
            hdr.data.f7[15:8] : exact; 
            // BF-RT : name: "hdr.data.f7[15:8]", bit width: 8 isFieldSlice: true
            // CJSON : name: "hdr.data.f7", bit width: 8, bit width full: 32 
        }
        actions = { setb1; }
        default_action = setb1(0x77);
    }

    table set_port {
        actions = { set_port_act;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }
    apply {
        slicesAndAnnots.apply();
        set_port.apply();
    }

}

control DeparserI(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr,
                inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
