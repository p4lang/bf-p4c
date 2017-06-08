#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

header_type m_t {
    fields {
        field_8_01  : 8;
        field_8_02  : 8;
        field_8_03  : 8;
        field_8_04  : 8;
        field_8_05  : 8;
        field_8_06  : 8;
        field_8_07  : 8;
        field_8_08  : 8;
        field_8_09  : 8;
        field_8_10  : 8;
        field_8_11  : 8;
        field_8_12  : 8;
        field_8_13  : 8;
        field_8_14  : 8;
        field_8_15  : 8;
        field_8_16  : 8;
        field_8_17  : 8;
        field_8_18  : 8;
        field_8_19  : 8;
        field_8_20  : 8;
        field_8_21  : 8;
        field_8_22  : 8;
        field_8_23  : 8;
        field_8_24  : 8;
        field_8_25  : 8;
        field_8_26  : 8;
        field_8_27  : 8;
        field_8_28  : 8;
        field_8_29  : 8;
        field_8_30  : 8;
        field_8_31  : 8;
        field_8_32  : 8;
        field_8_33  : 8;
        field_8_34  : 8;
        field_8_35  : 8;
        field_8_36  : 8;
        field_8_37  : 8;
        field_8_38  : 8;
        field_8_39  : 8;
        field_8_40  : 8;
        field_8_41  : 8;
        field_8_42  : 8;
        field_8_43  : 8;
        field_8_44  : 8;
        field_8_45  : 8;
        field_8_46  : 8;
        field_8_47  : 8;
        field_8_48  : 8;
        field_8_49  : 8;
        field_8_50  : 8;
        field_8_51  : 8;
        field_8_52  : 8;
        field_8_53  : 8;
        field_8_54  : 8;
        field_8_55  : 8;
        field_8_56  : 8;
        field_8_57  : 8;
        field_8_58  : 8;
        field_8_59  : 8;
        field_8_60  : 8;
        field_8_61  : 8;
        field_8_62  : 8;
        field_8_63  : 8;
        field_8_64  : 8;

        field_16_01  : 16;
        field_16_02  : 16;
        field_16_03  : 16;
        field_16_04  : 16;
        field_16_05  : 16;
        field_16_06  : 16;
        field_16_07  : 16;
        field_16_08  : 16;
        field_16_09  : 16;
        field_16_10  : 16;
        field_16_11  : 16;
        field_16_12  : 16;
        field_16_13  : 16;
        field_16_14  : 16;
        field_16_15  : 16;
        field_16_16  : 16;
        field_16_17  : 16;
        field_16_18  : 16;
        field_16_19  : 16;
        field_16_20  : 16;
        field_16_21  : 16;
        field_16_22  : 16;
        field_16_23  : 16;
        field_16_24  : 16;
        field_16_25  : 16;
        field_16_26  : 16;
        field_16_27  : 16;
        field_16_28  : 16;
        field_16_29  : 16;
        field_16_30  : 16;
        field_16_31  : 16;
        field_16_32  : 16;
        field_16_33  : 16;
        field_16_34  : 16;
        field_16_35  : 16;
        field_16_36  : 16;
        field_16_37  : 16;
        field_16_38  : 16;
        field_16_39  : 16;
        field_16_40  : 16;
        field_16_41  : 16;
        field_16_42  : 16;
        field_16_43  : 16;
        field_16_44  : 16;
        field_16_45  : 16;
        field_16_46  : 16;
        field_16_47  : 16;
        field_16_48  : 16;
        field_16_49  : 16;
        field_16_50  : 16;
        field_16_51  : 16;
        field_16_52  : 16;
        field_16_53  : 16;
        field_16_54  : 16;
        field_16_55  : 16;
        field_16_56  : 16;
        field_16_57  : 16;
        field_16_58  : 16;
        field_16_59  : 16;
        field_16_60  : 16;
        field_16_61  : 16;
        field_16_62  : 16;
        field_16_63  : 16;
        field_16_64  : 16;
        field_16_65  : 16;
        field_16_66  : 16;
        field_16_67  : 16;
        field_16_68  : 16;
        field_16_69  : 16;
        field_16_70  : 16;
        field_16_71  : 16;
        field_16_72  : 16;
        field_16_73  : 16;
        field_16_74  : 16;
        field_16_75  : 16;
        field_16_76  : 16;
        field_16_77  : 16;
        field_16_78  : 16;
        field_16_79  : 16;
        field_16_80  : 16;
        field_16_81  : 16;
        field_16_82  : 16;
        field_16_83  : 16;
        field_16_84  : 16;
        field_16_85  : 16;
        field_16_86  : 16;
        field_16_87  : 16;
        field_16_88  : 16;
        field_16_89  : 16;
        field_16_90  : 16;
        field_16_91  : 16;
        field_16_92  : 16;
        field_16_93  : 16;
        field_16_94  : 16;
        field_16_95  : 16;
        field_16_96  : 16;

        field_32_01  : 32;
        field_32_02  : 32;
        field_32_03  : 32;
        field_32_04  : 32;
        field_32_05  : 32;
        field_32_06  : 32;
        field_32_07  : 32;
        field_32_08  : 32;
        field_32_09  : 32;
        field_32_10  : 32;
        field_32_11  : 32;
        field_32_12  : 32;
        field_32_13  : 32;
        field_32_14  : 32;
        field_32_15  : 32;
        field_32_16  : 32;
        field_32_17  : 32;
        field_32_18  : 32;
        field_32_19  : 32;
        field_32_20  : 32;
        field_32_21  : 32;
        field_32_22  : 32;
        field_32_23  : 32;
        field_32_24  : 32;
        field_32_25  : 32;
        field_32_26  : 32;
        field_32_27  : 32;
        field_32_28  : 32;
        field_32_29  : 32;
        field_32_30  : 32;
        field_32_31  : 32;
        field_32_32  : 32;
        field_32_33  : 32;
        field_32_34  : 32;
        field_32_35  : 32;
        field_32_36  : 32;
        field_32_37  : 32;
        field_32_38  : 32;
        field_32_39  : 32;
        field_32_40  : 32;
        field_32_41  : 32;
        field_32_42  : 32;
        field_32_43  : 32;
        field_32_44  : 32;
        field_32_45  : 32;
        field_32_46  : 32;
        field_32_47  : 32;
        field_32_48  : 32;
        field_32_49  : 32;
        field_32_50  : 32;
        field_32_51  : 32;
        field_32_52  : 32;
        field_32_53  : 32;
        field_32_54  : 32;
        field_32_55  : 32;
        field_32_56  : 32;
        field_32_57  : 32;
        field_32_58  : 32;
        field_32_59  : 32;
        field_32_60  : 32;
        field_32_61  : 32;
        field_32_62  : 32;
        field_32_63  : 32;
        field_32_64  : 32;
    }
}

metadata m_t m;

parser start {
    extract(ethernet);
    return ingress;
}

action a1() {
}

table t1 {
    reads {
        m.field_8_01 : exact;
        m.field_8_02 : exact;
        m.field_8_03 : exact;
        m.field_8_04 : exact;
        m.field_8_05 : exact;
        m.field_8_06 : exact;
        m.field_8_07 : exact;
        m.field_8_08 : exact;
        m.field_8_09 : exact;
        m.field_8_10 : exact;
        m.field_8_11 : exact;
        m.field_8_12 : exact;
        m.field_8_13 : exact;
        m.field_8_14 : exact;
        m.field_8_15 : exact;
        m.field_8_16 : exact;
        m.field_8_17 : exact;
        m.field_8_18 : exact;
        m.field_8_19 : exact;
        m.field_8_20 : exact;
        m.field_8_21 : exact;
        m.field_8_22 : exact;
        m.field_8_23 : exact;
        m.field_8_24 : exact;
        m.field_8_25 : exact;
        m.field_8_26 : exact;
        m.field_8_27 : exact;
        m.field_8_28 : exact;
        m.field_8_29 : exact;
        m.field_8_30 : exact;
        m.field_8_31 : exact;
        m.field_8_32 : exact;
        m.field_8_33 : exact;
        m.field_8_34 : exact;
        m.field_8_35 : exact;
        m.field_8_36 : exact;
        m.field_8_37 : exact;
        m.field_8_38 : exact;
        m.field_8_39 : exact;
        m.field_8_40 : exact;
        m.field_8_41 : exact;
        m.field_8_42 : exact;
        m.field_8_43 : exact;
        m.field_8_44 : exact;
        m.field_8_45 : exact;
        m.field_8_46 : exact;
        m.field_8_47 : exact;
        m.field_8_48 : exact;
        m.field_8_49 : exact;
        m.field_8_50 : exact;
        m.field_8_51 : exact;
        m.field_8_52 : exact;
        m.field_8_53 : exact;
        m.field_8_54 : exact;
        m.field_8_55 : exact;
        m.field_8_56 : exact;
        m.field_8_57 : exact;
        m.field_8_58 : exact;
        m.field_8_59 : exact;
        m.field_8_60 : exact;
        m.field_8_61 : exact;
        m.field_8_62 : exact;
        m.field_8_63 : exact;
        m.field_8_64 : exact;
    }
    actions {
        a1;
    }
}

action a2() {
}

table t2 {
    reads {
        m.field_16_01 : exact;
        m.field_16_02 : exact;
        m.field_16_03 : exact;
        m.field_16_04 : exact;
        m.field_16_05 : exact;
        m.field_16_06 : exact;
        m.field_16_07 : exact;
        m.field_16_08 : exact;
        m.field_16_09 : exact;
        m.field_16_10 : exact;
        m.field_16_11 : exact;
        m.field_16_12 : exact;
        m.field_16_13 : exact;
        m.field_16_14 : exact;
        m.field_16_15 : exact;
        m.field_16_16 : exact;
        m.field_16_17 : exact;
        m.field_16_18 : exact;
        m.field_16_19 : exact;
        m.field_16_20 : exact;
        m.field_16_21 : exact;
        m.field_16_22 : exact;
        m.field_16_23 : exact;
        m.field_16_24 : exact;
        m.field_16_25 : exact;
        m.field_16_26 : exact;
        m.field_16_27 : exact;
        m.field_16_28 : exact;
        m.field_16_29 : exact;
        m.field_16_30 : exact;
        m.field_16_31 : exact;
        m.field_16_32 : exact;
    }
    actions {
        a2;
    }
}

action a3() {
}

table t3 {
    reads {
        m.field_16_33 : exact;
        m.field_16_34 : exact;
        m.field_16_35 : exact;
        m.field_16_36 : exact;
        m.field_16_37 : exact;
        m.field_16_38 : exact;
        m.field_16_39 : exact;
        m.field_16_40 : exact;
        m.field_16_41 : exact;
        m.field_16_42 : exact;
        m.field_16_43 : exact;
        m.field_16_44 : exact;
        m.field_16_45 : exact;
        m.field_16_46 : exact;
        m.field_16_47 : exact;
        m.field_16_48 : exact;
        m.field_16_49 : exact;
        m.field_16_50 : exact;
        m.field_16_51 : exact;
        m.field_16_52 : exact;
        m.field_16_53 : exact;
        m.field_16_54 : exact;
        m.field_16_55 : exact;
        m.field_16_56 : exact;
        m.field_16_57 : exact;
        m.field_16_58 : exact;
        m.field_16_59 : exact;
        m.field_16_60 : exact;
        m.field_16_61 : exact;
        m.field_16_62 : exact;
        m.field_16_63 : exact;
        m.field_16_64 : exact;
        m.field_16_65 : exact;
        m.field_16_66 : exact;
        m.field_16_67 : exact;
        m.field_16_68 : exact;
        m.field_16_69 : exact;
        m.field_16_70 : exact;
        m.field_16_71 : exact;
        m.field_16_72 : exact;
        m.field_16_73 : exact;
        m.field_16_74 : exact;
        m.field_16_75 : exact;
        m.field_16_76 : exact;
        m.field_16_77 : exact;
        m.field_16_78 : exact;
        m.field_16_79 : exact;
        m.field_16_80 : exact;
        m.field_16_81 : exact;
        m.field_16_82 : exact;
        m.field_16_83 : exact;
        m.field_16_84 : exact;
        m.field_16_85 : exact;
        m.field_16_86 : exact;
        m.field_16_87 : exact;
        m.field_16_88 : exact;
        m.field_16_89 : exact;
        m.field_16_90 : exact;
        m.field_16_91 : exact;
        m.field_16_92 : exact;
        m.field_16_93 : exact;
        m.field_16_94 : exact;
        m.field_16_95 : exact;
        m.field_16_96 : exact;
    }
    actions {
        a3;
    }
}

action a4() {
}

table t4 {
    reads {
        m.field_32_01 : exact;
        m.field_32_02 : exact;
        m.field_32_03 : exact;
        m.field_32_04 : exact;
        m.field_32_05 : exact;
        m.field_32_06 : exact;
        m.field_32_07 : exact;
        m.field_32_08 : exact;
        m.field_32_09 : exact;
        m.field_32_10 : exact;
        m.field_32_11 : exact;
        m.field_32_12 : exact;
        m.field_32_13 : exact;
        m.field_32_14 : exact;
        m.field_32_15 : exact;
        m.field_32_16 : exact;
        m.field_32_17 : exact;
        m.field_32_18 : exact;
        m.field_32_19 : exact;
        m.field_32_20 : exact;
        m.field_32_21 : exact;
        m.field_32_22 : exact;
        m.field_32_23 : exact;
        m.field_32_24 : exact;
        m.field_32_25 : exact;
        m.field_32_26 : exact;
        m.field_32_27 : exact;
        m.field_32_28 : exact;
        m.field_32_29 : exact;
        m.field_32_30 : exact;
        m.field_32_31 : exact;
        m.field_32_32 : exact;
    }
    actions {
        a4;
    }
}

action a5() {
}

table t5 {
    reads {
        m.field_32_33 : exact;
        m.field_32_34 : exact;
        m.field_32_35 : exact;
        m.field_32_36 : exact;
        m.field_32_37 : exact;
        m.field_32_38 : exact;
        m.field_32_39 : exact;
        m.field_32_40 : exact;
        m.field_32_41 : exact;
        m.field_32_42 : exact;
        m.field_32_43 : exact;
        m.field_32_44 : exact;
        m.field_32_45 : exact;
        m.field_32_46 : exact;
        m.field_32_47 : exact;
        m.field_32_48 : exact; 
        m.field_32_49 : exact;
        m.field_32_50 : exact;
        m.field_32_51 : exact;
        m.field_32_52 : exact;
        m.field_32_53 : exact;
        m.field_32_54 : exact;
        m.field_32_55 : exact;
        m.field_32_56 : exact;
        m.field_32_57 : exact;
        m.field_32_58 : exact;
        m.field_32_59 : exact;
#if 0
        m.field_32_60 : exact;
        m.field_32_61 : exact;
        m.field_32_62 : exact;
        m.field_32_63 : exact;
        m.field_32_64 : exact;
#endif
    }
    actions {
       a5;
    }
}

control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
    apply(t4);
    apply(t5);
}

control egress {
}
