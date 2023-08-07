#include <core.p4>

#include <t2na.p4>
#define PORT_OUT 152

#include "../../p4-programs/p4_16_programs/common/headers.p4"
#include "../../p4-programs/p4_16_programs/common/util.p4"


header word_t {
    bit<16> word;
}
header sixty_t {
    bit<480> bits;
}
header desc_t {
    bit<1> val2;
    bit<6> pad;
    bit<9> inport;
    bit<16> err;
}

struct head_t {
    desc_t desc;
    word_t sep1;
    sixty_t h1;
    word_t sep2;
    sixty_t h2;
    word_t sep3;
    word_t sep4;
    word_t sep5;
}

struct metadata_t
{
}


// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(

packet_in pkt,
out head_t  hdr,
out metadata_t ig_md,
out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    
    state start {
	tofino_parser.apply(pkt, ig_intr_md);
	hdr.desc.setValid();
	hdr.desc.pad=0;
	hdr.desc.inport=ig_intr_md.ingress_port;
	hdr.sep1.setValid();
	hdr.sep1.word=0xBBBB;
	hdr.sep2.setValid();
	hdr.sep2.word=0xCCCC;
	hdr.sep3.setValid();
	hdr.sep3.word=0xDDDD;
	hdr.sep4.setValid();
	hdr.sep4.word=0xEEEE;
	hdr.sep5.setValid();
	hdr.sep5.word=0xFFFF;
	transition parseme;
    }
    
    state parseme {
	pkt.extract(hdr.h1);
	pkt.extract(hdr.h2);
	transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Control (aka Match-Action-Table)
// ---------------------------------------------------------------------------

control SwitchIngressControl(

inout head_t hdr,
inout metadata_t ig_md,
in ingress_intrinsic_metadata_t ig_intr_md,
in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {
        ig_tm_md.bypass_egress = 1; // skip egress ; needed as the Empty one emits nothing
	ig_tm_md.ucast_egress_port = PORT_OUT;
	if (ig_prsr_md.parser_err!=1789) { // tell the compiler NOT to drop silently erroring packets
	    hdr.desc.err=ig_prsr_md.parser_err;
	}
	if (hdr.h2.isValid()) {
	    hdr.desc.val2=1;
	} else {
	    hdr.desc.val2=0;
	}
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------

control SwitchIngressDeparser(

packet_out pkt,
inout head_t hdr,
in metadata_t ig_md,
in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(

SwitchIngressParser(),
SwitchIngressControl(),
SwitchIngressDeparser(),
EmptyEgressParser(),
EmptyEgress(),
EmptyEgressDeparser()) pipe;

Switch(pipe) main;
