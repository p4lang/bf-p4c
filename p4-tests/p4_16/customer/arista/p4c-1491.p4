#include <core.p4>
#include <tofino.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header Exell {
    bit<48> Toccopola;
    bit<48> Roachdale;
    bit<16> Miller;
}

header Breese {
    bit<4>  Churchill;
    bit<4>  Waialua;
    bit<6>  Arnold;
    bit<2>  Wimberley;
    bit<16> Wheaton;
    bit<16> Dunedin;
    bit<3>  BigRiver;
    bit<13> Sawyer;
    bit<8>  Iberia;
    bit<8>  Skime;
    bit<16> Goldsboro;
    bit<32> Fabens;
    bit<32> CeeVee;
}

struct Quebrada {
    Exell  Haugan;
    Breese Paisano;
}

header Boquillas {
    bit<9> McCaulley;
    bit<7> Everton;
}

struct Lafayette {
    bit<10>   Roosville;
    bit<9>    Homeacre;
    bit<1>    Dixboro;
    Boquillas Rayville;
}

parser Rugby(packet_in Davie, out Quebrada Cacao, out Lafayette Mankato, out ingress_intrinsic_metadata_t Rockport) {
    state start {
        Davie.extract<ingress_intrinsic_metadata_t>(Rockport);
        transition Union;
    }
    state Union {
        Davie.extract<Exell>(Cacao.Haugan);
        transition Virgil;
    }
    state Virgil {
        Davie.extract<Breese>(Cacao.Paisano);
        transition accept;
    }
}

control Florin(packet_out Requa, inout Quebrada Sudbury, in Lafayette Allgood, in ingress_intrinsic_metadata_for_deparser_t Chaska) {
    Mirror() Selawik;
    apply {
        if (Allgood.Dixboro == 1w1) {
            Selawik.emit<Boquillas>(Allgood.Roosville, Allgood.Rayville);
        }
        Requa.emit<Quebrada>(Sudbury);
    }
}

control Waipahu(inout Quebrada Shabbona, inout Lafayette Ronan, in ingress_intrinsic_metadata_t Anacortes) {
    action Corinth(bit<10> Willard) {
        Ronan.Roosville = Willard;
        Ronan.Dixboro = 1w1;
        Ronan.Rayville.McCaulley = Anacortes.ingress_port;
    }
    table Bayshore {
        actions = {
            Corinth();
        }
        key = {
            Anacortes.ingress_port: ternary;
        }
        size = 1024;
        default_action = Corinth(10w0);
    }
    apply {
        Bayshore.apply();
    }
}

control Florien(inout Quebrada Freeburg, inout Lafayette Matheson) {
    action Uintah(bit<3> Blitchton) {
        Matheson.Roosville[9:7] = Blitchton;
    }
    @ternary(1) table Avondale {
        actions = {
            Uintah();
        }
        key = {
            Matheson.Roosville[6:0]: exact;
        }
        size = 128;
    }
    apply {
        Avondale.apply();
    }
}

control Glassboro(inout Quebrada Grabill, inout Lafayette Moorcroft, in ingress_intrinsic_metadata_t Toklat, in ingress_intrinsic_metadata_from_parser_t Bledsoe, inout ingress_intrinsic_metadata_for_deparser_t Blencoe, inout ingress_intrinsic_metadata_for_tm_t AquaPark) {
    Waipahu() Vichy;
    Florien() Lathrop;
    apply {
        Vichy.apply(Grabill, Moorcroft, Toklat);
        Lathrop.apply(Grabill, Moorcroft);
    }
}

parser Clyde<H, M>(packet_in Clarion, out H Aguilita, out M Harbor, out egress_intrinsic_metadata_t IttaBena) {
    state start {
        transition accept;
    }
}

control Adona<H, M>(packet_out Connell, inout H Cisco, in M Higginson, in egress_intrinsic_metadata_for_deparser_t Oriskany) {
    apply {
    }
}

control Bowden<H, M>(inout H Cabot, inout M Keyes, in egress_intrinsic_metadata_t Basic, in egress_intrinsic_metadata_from_parser_t Freeman, inout egress_intrinsic_metadata_for_deparser_t Exton, inout egress_intrinsic_metadata_for_output_port_t Floyd) {
    apply {
    }
}

Pipeline<Quebrada, Lafayette, Quebrada, Lafayette>(Rugby(), Glassboro(), Florin(), Clyde<Quebrada, Lafayette>(), Bowden<Quebrada, Lafayette>(), Adona<Quebrada, Lafayette>()) Fayette;

Switch<Quebrada, Lafayette, Quebrada, Lafayette, _, _, _, _, _, _, _, _, _, _, _, _>(Fayette) main;

