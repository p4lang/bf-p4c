#include "phv.h"

void Target::Flatrock::Phv::init_regs(::Phv &phv) {
    // Allocating Tofino registers so the uids map to register encodings
    static const struct { char code[4]; unsigned size, count, parde; } sizes[] =
        { { "B", 8, 160, 128 }, { "H", 16, 40, 32 }, { "W", 32, 20, 16 } };
    phv.regs.clear();
    unsigned uid = 0, byte = 0, ixb_id = 0;
    for (unsigned i = 0; i < sizeof sizes/sizeof *sizes; i++) {
        for (unsigned j = 0; j < sizes[i].count; j++) {
            auto reg = new Register;
            memset(reg->name, 0, sizeof(reg->name));
            reg->type = Register::NORMAL;
            reg->index = j;
            reg->uid = uid++;
            reg->size = sizes[i].size;
            if (j < sizes[i].parde) {
                reg->parde_id = byte;
                byte += reg->size/8U;
            } else {
                reg->parde_id = -1; }
            reg->ixb_id = ixb_id;
            ixb_id += reg->size/8U;
            if (ixb_id % 128 == 80) ixb_id += 48;
            phv.regs.push_back(reg);
            if (sizes[i].size) {
                char buf[8];
                snprintf(buf, sizeof(buf), "R%d", uid);
                phv.names[INGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                phv.names[EGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                snprintf(buf, sizeof(buf), "%.2s%d", sizes[i].code, j);
                strncpy(reg->name, buf, sizeof(reg->name));
                phv.names[INGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                phv.names[EGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1); } } }
    BUG_CHECK(ixb_id == 512, "incorrect final ixb id");
    BUG_CHECK(byte == 256, "incorrect final parde size");
}
