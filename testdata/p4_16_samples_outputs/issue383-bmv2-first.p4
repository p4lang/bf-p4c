#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

struct alt_t {
    bit<1> valid;
    bit<7> port;
}

@MNK_annotation("(test flatten)") struct row_t {
    alt_t alt0;
    alt_t alt1;
}

header bitvec_hdr {
    row_t row;
}

struct col_t {
    bitvec_hdr bvh;
}

struct local_metadata_t {
    row_t      row0;
    row_t      row1;
    col_t      col;
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
}

struct parsed_packet_t {
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
}

struct tst_t {
    row_t      row0;
    row_t      row1;
    col_t      col;
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
}

parser parse(packet_in pk, out parsed_packet_t h, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    state start {
        pk.extract<bitvec_hdr>(h.bvh0);
        pk.extract<bitvec_hdr>(h.bvh1);
        pk.extract<bitvec_hdr>(local_metadata.col.bvh);
        transition accept;
    }
}

control ingress(inout parsed_packet_t h, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    tst_t s;
    bitvec_hdr bh;
    action do_act() {
        h.bvh1.row.alt1.valid = 1w0;
        local_metadata.col.bvh.row.alt0.valid = 1w0;
    }
    table tns {
        key = {
            h.bvh1.row.alt1.valid                : exact @name("h.bvh1.row.alt1.valid") ;
            local_metadata.col.bvh.row.alt0.valid: exact @name("local_metadata.col.bvh.row.alt0.valid") ;
        }
        actions = {
            do_act();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        tns.apply();
        bh.row.alt0.valid = h.bvh0.row.alt0.valid;
        s.row0.alt0 = local_metadata.row1.alt1;
        s.row1.alt0.valid = 1w1;
        s.row1.alt1.port = local_metadata.row0.alt1.port + 7w1;
        s.col.bvh.row.alt0.valid = 1w0;
        local_metadata.col.bvh.row.alt0.valid = 1w0;
        local_metadata.row0.alt0 = local_metadata.row1.alt1;
        local_metadata.row1.alt0.valid = 1w1;
        local_metadata.row1.alt1.port = local_metadata.row0.alt1.port + 7w1;
        clone3<row_t>(CloneType.I2E, 32w0, local_metadata.row0);
    }
}

control egress(inout parsed_packet_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control deparser(packet_out b, in parsed_packet_t h) {
    apply {
        b.emit<bitvec_hdr>(h.bvh0);
        b.emit<bitvec_hdr>(h.bvh1);
    }
}

control verifyChecksum(inout parsed_packet_t hdr, inout local_metadata_t local_metadata) {
    apply {
    }
}

control compute_checksum(inout parsed_packet_t hdr, inout local_metadata_t local_metadata) {
    apply {
    }
}

V1Switch<parsed_packet_t, local_metadata_t>(parse(), verifyChecksum(), ingress(), egress(), compute_checksum(), deparser()) main;
