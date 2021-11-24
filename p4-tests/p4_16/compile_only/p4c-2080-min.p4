#include <tna.p4>       /* TOFINO1_ONLY */

header AquaPark {
    bit<24> Vichy;
    bit<24> Lathrop;
    bit<24> Sawyer;
    bit<24> Iberia;
    bit<16> Haugan;
}

header Clyde {
    bit<3>  Clarion;
    bit<1>  Aguilita;
    bit<12> Harbor;
    bit<16> Haugan;
}

struct Mayday {
    bit<3>  Sheldahl;
    bit<12> Harbor;
    bit<3>  Sledge;
    bit<1>  Morstein;
    bit<1>  Minto;
}

struct Sardinia {
    bit<3>  Subiaco;
    bit<1>  Aguilita;
}

struct Newfolden {
    Mayday    Dairyland;
    Sardinia  Sunflower;
}

struct Savery {
    AquaPark  Salix;
    Clyde[2]  Moose;
}

parser Osyka(packet_in Brookneal, out Savery Hoven, out Newfolden Shirley, out ingress_intrinsic_metadata_t Edwards) {
    state start { transition accept; }
}

control Greenwood(packet_out Brookneal, inout Savery Hoven, in Newfolden Shirley, in ingress_intrinsic_metadata_for_deparser_t Readsboro) {
    apply {
    }
}

action Eolia() {
}

action Tullytown(inout Savery Hoven, inout Newfolden Shirley, in egress_intrinsic_metadata_t Bessie, in egress_intrinsic_metadata_from_parser_t Leacock, inout egress_intrinsic_metadata_for_deparser_t WestPark, inout egress_intrinsic_metadata_for_output_port_t WestEnd) {
    Hoven.Moose[0].setValid();
    Hoven.Moose[0].Harbor = Shirley.Dairyland.Harbor;
    Hoven.Moose[0].Haugan = Hoven.Salix.Haugan;
    Hoven.Moose[0].Clarion = Shirley.Sunflower.Subiaco;
    Hoven.Moose[0].Aguilita = Shirley.Sunflower.Aguilita;
    Hoven.Salix.Haugan = (bit<16>)16w0x8100;
}
control Heaton(inout Savery Hoven, inout Newfolden Shirley, in egress_intrinsic_metadata_t Bessie, in egress_intrinsic_metadata_from_parser_t Leacock, inout egress_intrinsic_metadata_for_deparser_t WestPark, inout egress_intrinsic_metadata_for_output_port_t WestEnd) {
    action Somis() {
        Eolia();
    }
    @ways(2) table Aptos {
        actions = {
            Somis();
            Tullytown(Hoven, Shirley, Bessie, Leacock, WestPark, WestEnd);
        }
        key = {
            Shirley.Dairyland.Harbor   : exact;
            Bessie.egress_port & 9w0x7f: exact;
            Shirley.Dairyland.Minto    : exact;
        }
        default_action = Tullytown(Hoven, Shirley, Bessie, Leacock, WestPark, WestEnd);
        size = 128;
    }
    apply {
        Aptos.apply();
    }
}

control Ardsley(inout Savery Hoven, inout Newfolden Shirley, in ingress_intrinsic_metadata_t Edwards, in ingress_intrinsic_metadata_from_parser_t Shingler, inout ingress_intrinsic_metadata_for_deparser_t Readsboro, inout ingress_intrinsic_metadata_for_tm_t Mausdale) {
    apply {
    }
}

control Waumandee(inout Savery Hoven, inout Newfolden Shirley, in egress_intrinsic_metadata_t Bessie, in egress_intrinsic_metadata_from_parser_t Leacock, inout egress_intrinsic_metadata_for_deparser_t WestPark, inout egress_intrinsic_metadata_for_output_port_t WestEnd) {
    Heaton() Moorman;
    apply {
        {
            ;
        }
        {
            if (Shirley.Dairyland.Morstein == 1w0 && Shirley.Dairyland.Sledge != 3w2 && Shirley.Dairyland.Sheldahl != 3w3) {
                Moorman.apply(Hoven, Shirley, Bessie, Leacock, WestPark, WestEnd);
            }
        }
        ;
    }
}

parser Parmelee(packet_in Brookneal, out Savery Hoven, out Newfolden Shirley, out egress_intrinsic_metadata_t Bessie) {
    state start { transition accept; }
}

control Alcoma(packet_out Brookneal, inout Savery Hoven, in Newfolden Shirley, in egress_intrinsic_metadata_for_deparser_t WestPark) {
    apply {
        Brookneal.emit<Savery>(Hoven);
    }
}

Pipeline<Savery, Newfolden, Savery, Newfolden>(Osyka(), Ardsley(), Greenwood(), Parmelee(), Waumandee(), Alcoma()) pipe;

Switch<Savery, Newfolden, Savery, Newfolden, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;
