/* p4smith seed: 214789678 */
#include <core.p4>
#include <v1model.p4>

header headlines {
     bit<5> tessas;
     bit<11> oracle;
     bit<9> vamping;
     bit<2> theists;
     bit<48> peninsula;
     bit<7> mastoid;
     bit<2> megatons;
     bit<48> showrooms;
     bit<32> debuggers;
     bit<32> coiffing;
     bit<2> thereses;
     bit<4> apostatizing;
     bit<2> suitability;
     bit<32> wantonly;
     bit<3> gropiuss;
     bit<8> transposition;
     bit<3> sighs;
     bit<6> deeper;
     bit<1> pullman;
     bit<7> helpings;
}
struct headers {
    headlines bacteriologists;
    headlines effective;
    headlines catarrh;
}
struct metadata { }
parser attunes(packet_in pkt,out headers hdr,inout metadata meta,
               inout standard_metadata_t std_meta) {
    state start {
        transition parse_bacteriologists;
    }
    state parse_bacteriologists {
        pkt.extract(hdr.bacteriologists);
        transition select(hdr.bacteriologists.gropiuss,
            hdr.bacteriologists.thereses,hdr.bacteriologists.deeper,
            hdr.bacteriologists.pullman) {{3w2,2w3,6w6,1w1}: parse_catarrh;
            {3w4,2w0,6w0,1w0}: parse_effective;
        }
    }
    state parse_effective {
        pkt.extract(hdr.effective);
        transition select(hdr.effective.theists,hdr.effective.megatons,
            hdr.effective.pullman,hdr.effective.helpings) {
            {2w2,2w1,1w1,7w99}: parse_catarrh;
        }
    }
    state parse_catarrh {
        pkt.extract(hdr.catarrh);
        transition accept;
    }
}
control loyalisms(inout headers hdr,inout metadata meta) {
    apply { }
}
control likabilitys(inout headers hdr,inout metadata meta,
                    inout standard_metadata_t std_meta) {
    action rollick(in bool birched,in bit<16> consumptives) {
        ;
        ;
    }
    action raleighs() {
        ;
    }
    action peekaboos(in bool bearskins,in bit<7> metamorphoses) {
        ;
        ;
    }
    action broodiest() {
        ;
    }
    action neptunes(in bool milled,in bit<32> separators) {
        ;
        ;
    }
    action regulations(in bool peroration,in bit<32> ovens) {
        ;
    }
    action cholesterol(in bool proofing,in bit<32> pomp) {
        ;
        ;
    }
    action proofreaders(in bool wrecked,in bit<7> sharifs) {
        ;
        ;
    }
    action competencys(in bool bandeaux) {
        ;
    }
    action elevenths(in bool acupuncturists) {
        ;
        ;
    }
    table pensions {
        key = {
            
        }
        actions = {
            neptunes(true,32w106611522);
            rollick((bool) 1w0,16w65249);
        }
    }
    table salaams {
        key = {
            
        }
        actions = {
            
        }
    }
    table hypnotic {
        key = {
            
        }
        actions = {
            cholesterol(true,32w3364227141);
            peekaboos((bool) 1w1,7w127);
            raleighs;
        }
    }
    table bs {
        key = {
            
        }
        actions = {
            
        }
    }apply {
         salaams.apply();
         pensions.apply();
         bs.apply();
         if ((((((! (bool) 1w1) || (true || false)) &&
                   ((! (bool) 1w1) || (true && (bool) 1w1)))
                  &&
                  (((hdr.catarrh.isValid() && true) &&
                       (false || hdr.bacteriologists.isValid()))
                      && (! (! true))))
                 &&
                 (!
                     (((! hdr.effective.isValid()) && (! false)) ||
                         ((! (bool) 1w0) && (! false))))))
             
             if (((! (false && hdr.bacteriologists.isValid())) &&
                     (! (hdr.effective.isValid() && false))))
                 
                 if ((! hdr.bacteriologists.isValid())) 
                     broodiest();
                 else
                     neptunes(true,32w1015074192);
         else
             if ((((! (bool) 1w0) || ((bool) 1w1 || true)) &&
                     ((! hdr.catarrh.isValid()) ||
                         ((bool) 1w1 && hdr.bacteriologists.isValid()))))
                 
                 if ((true || true)) 
                     elevenths((bool) 1w0);
         hypnotic.apply();
         if ((((((false && (bool) 1w0) && (false && (bool) 1w0)) ||
                   (! (hdr.catarrh.isValid() || true)))
                  &&
                  (((! false) &&
                       (hdr.effective.isValid() && hdr.catarrh.isValid()))
                      ||
                      ((false || hdr.bacteriologists.isValid()) ||
                          (! (bool) 1w1))))
                 ||
                 ((! (! ((bool) 1w0 && true))) &&
                     (!
                         ((hdr.bacteriologists.isValid() || true) &&
                             (hdr.catarrh.isValid() &&
                                 hdr.effective.isValid()))))))
             
             if ((((hdr.effective.isValid() && true) && (true && true)) &&
                     ((true && true) && ((bool) 1w0 && true))))
                 
                 if ((false || false)) 
                     proofreaders(false,7w15);
             else
                 if ((true && hdr.effective.isValid()))
                     
                     neptunes(false,32w3866510108);
                 else
                     rollick(true,16w34923);
         if ((((!
                   ((true && false) &&
                       (hdr.bacteriologists.isValid() && false)))
                  ||
                  (((! false) || ((bool) 1w1 && true)) ||
                      (! (true && (bool) 1w0))))
                 &&
                 (!
                     (((! false) && ((bool) 1w0 && true)) &&
                         (! (false && true))))))
             
             if ((!
                     (((bool) 1w1 || false) &&
                         (hdr.bacteriologists.isValid() && (bool) 1w1))))
                 
                 if ((hdr.effective.isValid() && true))
                     
                     proofreaders((bool) 1w0,7w32);
             else
                 if (((bool) 1w1 && false))
                     
                     cholesterol(false,32w2880713223);
         else
             if (((((bool) 1w0 && hdr.catarrh.isValid()) || (! false)) &&
                     ((hdr.bacteriologists.isValid() &&
                          hdr.effective.isValid())
                         || (! true))))
                 
                 if ((false && hdr.catarrh.isValid())) 
                     raleighs();
    }
}
control pushers(inout headers hdr,inout metadata meta,
                inout standard_metadata_t std_meta) {
    action callownesss(in bit<10> telexes) {
        ;
    }
    table debtors {
        key = {
            
        }
        actions = {
            callownesss(10w946);
        }
    }
    table overtaking {
        key = {
            
        }
        actions = {
            callownesss(10w859);
        }
    }
    table hangzhous {
        key = {
            
        }
        actions = {
            
        }
    }apply {
         overtaking.apply();
         if (((!
                  ((! ((bool) 1w0 || (bool) 1w0)) ||
                      ((true || hdr.effective.isValid()) && (false && true))))
                 ||
                 ((! ((! false) && (false || (bool) 1w1))) ||
                     ((! (false && false)) &&
                         ((true && (bool) 1w0) &&
                             ((bool) 1w1 || hdr.bacteriologists.isValid()))))))
             
             if ((((hdr.effective.isValid() || (bool) 1w1) &&
                      (! (bool) 1w0))
                     && (! (! hdr.catarrh.isValid()))))
                 
                 if ((! false)) 
                     callownesss(10w843);
         else
             if ((! ((hdr.catarrh.isValid() && false) && (true || false))))
                 
                 if ((hdr.bacteriologists.isValid() && true))
                     
                     callownesss(10w188);
             else
                 if ((! true)) 
                     callownesss(10w839);
                 else
                     callownesss(10w410);
         hangzhous.apply();
         if ((! (! (! (! ((bool) 1w0 || hdr.bacteriologists.isValid()))))))
             
             if ((((! hdr.effective.isValid()) &&
                      ((bool) 1w1 || (bool) 1w1))
                     &&
                     ((! (bool) 1w1) || (hdr.catarrh.isValid() && false))))
                 
                 if ((true && true)) 
                     callownesss(10w791);
                 else
                     callownesss(10w679);
             else
                 if ((! hdr.effective.isValid())) 
                     callownesss(10w1023);
         else
             if ((! (! (true && (bool) 1w1))))
                 
                 if ((! (bool) 1w0)) 
                     callownesss(10w143);
                 else
                     callownesss(10w127);
         debtors.apply();
         if (((((! (false && true)) ||
                   ((hdr.effective.isValid() || hdr.effective.isValid()) &&
                       (false || (bool) 1w0)))
                  &&
                  ((((bool) 1w0 && false) ||
                       (true || hdr.bacteriologists.isValid()))
                      &&
                      ((true || hdr.catarrh.isValid()) || (false && false))))
                 &&
                 ((((! true) || (false && (bool) 1w1)) &&
                      ((! true) && (false && false)))
                     || (! (! (false || (bool) 1w1))))))
             
             if ((!
                     ((false && hdr.catarrh.isValid()) &&
                         (hdr.catarrh.isValid() && false))))
                 
                 if ((false || hdr.bacteriologists.isValid()))
                     
                     callownesss(10w931);
                 else
                     callownesss(10w920);
         else
             if ((((hdr.bacteriologists.isValid() || hdr.catarrh.isValid())
                      && (hdr.effective.isValid() || false))
                     &&
                     ((hdr.effective.isValid() || (bool) 1w0) &&
                         (false || false))))
                 
                 if ((true || false)) 
                     callownesss(10w380);
                 else
                     callownesss(10w236);
             else
                 if ((hdr.bacteriologists.isValid() && false))
                     
                     callownesss(10w1023);
                 else
                     callownesss(10w982);
         if ((! (! (! (! (true || false))))))
             
             if ((((false && (bool) 1w0) || (false && false)) &&
                     (! (! hdr.catarrh.isValid()))))
                 
                 if ((true && hdr.bacteriologists.isValid()))
                     
                     callownesss(10w184);
                 else
                     callownesss(10w398);
         else
             if ((((false || true) &&
                      (true || hdr.bacteriologists.isValid()))
                     && ((! true) && (false && (bool) 1w1))))
                 
                 if (((bool) 1w1 && hdr.bacteriologists.isValid()))
                     
                     callownesss(10w742);
             else
                 if ((true && (bool) 1w0)) 
                     callownesss(10w793);
                 else
                     callownesss(10w328);
         if ((((((hdr.bacteriologists.isValid() || false) &&
                    (hdr.catarrh.isValid() || hdr.effective.isValid()))
                   &&
                   ((! hdr.bacteriologists.isValid()) && (false && true)))
                  &&
                  (((true || hdr.catarrh.isValid()) || (! (bool) 1w1)) &&
                      ((false && (bool) 1w1) && (true && false))))
                 ||
                 ((((true && (bool) 1w0) && (true && false)) &&
                      (! (false && true)))
                     &&
                     (((true && hdr.effective.isValid()) ||
                          (false && hdr.bacteriologists.isValid()))
                         &&
                         ((hdr.effective.isValid() && false) &&
                             (false && hdr.effective.isValid()))))))
             
             if ((!
                     ((hdr.effective.isValid() && false) &&
                         ((bool) 1w1 || true))))
                 
                 if ((! true)) 
                     callownesss(10w409);
             else
                 if ((hdr.catarrh.isValid() && (bool) 1w0))
                     
                     callownesss(10w751);
                 else
                     callownesss(10w176);
         if (((((! ((bool) 1w0 && hdr.effective.isValid())) &&
                   (! (! hdr.bacteriologists.isValid())))
                  ||
                  (((false && false) || (! hdr.effective.isValid())) &&
                      ((hdr.bacteriologists.isValid() && true) ||
                          (false && hdr.effective.isValid()))))
                 && (! (! ((! true) || (false && (bool) 1w0))))))
             
             if ((((! hdr.catarrh.isValid()) && ((bool) 1w0 || false)) ||
                     (! (! true))))
                 
                 if ((false || (bool) 1w0)) 
                     callownesss(10w770);
             else
                 if ((true && hdr.bacteriologists.isValid()))
                     
                     callownesss(10w228);
                 else
                     callownesss(10w384);
         else
             if ((! (((bool) 1w0 || true) && (true || true))))
                 
                 if ((! true)) 
                     callownesss(10w516);
    }
}
control pittsburgh(inout headers hdr,inout metadata meta) {
    apply { }
}
control enjoyed(packet_out pkt,in headers hdr) {
    apply {
        pkt.emit(hdr.bacteriologists);
        pkt.emit(hdr.effective);
        pkt.emit(hdr.catarrh);
    }
}
V1Switch(attunes(),loyalisms(),likabilitys(),pushers(),pittsburgh(),
         enjoyed()) main;
