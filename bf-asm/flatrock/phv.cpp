#include "phv.h"

void Target::Flatrock::Phv::init_regs(::Phv &phv) {
    // Allocating Tofino registers so the uids map to register encodings
    static const struct { char code[4]; unsigned size, count; } sizes[] =
        { { "B", 8, 128 }, { "H", 16, 32 }, { "W", 32, 16 } };
    phv.regs.clear();
    unsigned uid = 0;
    for (unsigned i = 0; i < sizeof sizes/sizeof *sizes; i++) {
        for (unsigned j = 0; j < sizes[i].count; j++) {
            auto reg = new Register;
            memset(reg->name, 0, sizeof(reg->name));
            reg->type = Register::NORMAL;
            reg->index = j;
            reg->uid = uid;
            reg->size = sizes[i].size;
            uid += reg->size/8U;
            phv.regs.push_back(reg);
            if (sizes[i].size) {
                char buf[8];
                sprintf(buf, "R%d", uid);
                phv.names[INGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                phv.names[EGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                sprintf(buf, "%s%d", sizes[i].code, j);
                strcpy(reg->name, buf);
                phv.names[INGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1);
                phv.names[EGRESS][buf][0].slice = ::Phv::Slice(*reg, 0, sizes[i].size - 1); } } }
}
