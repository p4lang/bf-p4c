#include "phv.h"

void Target::JBay::Phv::init_regs(::Phv &phv) {
    // Allocating JBay regs so the uids map to mau register encodings
    static const struct { char code[2]; unsigned size, count; } groups[] =
        { { "W", 32, 4 }, { "B", 8, 4 }, { "H", 16, 6 } };
    static const struct { char code[2]; Register::type_t type; unsigned count; } types[] =
        { { "", Register::NORMAL, 12 }, { "M", Register::MOCHA, 4 }, { "D", Register::DARK, 4 } };
    unsigned uid = 0;
    phv.regs.resize(280);
    for (unsigned i = 0; i < sizeof groups/sizeof *groups; i++) {
        unsigned idx[sizeof types/sizeof *types] = { 0 };
        for (unsigned j = 0; j < groups[i].count; j++) {
            for (unsigned k = 0; k < sizeof types/sizeof *types; k++) {
                for (unsigned l = 0; l < types[k].count; l++, idx[k]++, uid++) {
                    auto reg = phv.regs[uid] = new Register;
                    memset(reg->name, 0, sizeof(reg->name));
                    sprintf(reg->name, "%s%s%d", types[k].code, groups[i].code, idx[k]);
                    reg->type = types[k].type;
                    reg->index = idx[k];
                    reg->uid = uid;
                    reg->size = groups[i].size;
                    phv.names[INGRESS].emplace(reg->name, ::Phv::Slice(*reg, 0, reg->size - 1));
                    phv.names[EGRESS].emplace(reg->name, ::Phv::Slice(*reg, 0, reg->size - 1)); 
                }
            }
        }
    }
    assert(uid == phv.regs.size());
}

int Target::JBay::Phv::Register::parser_id() const {
    unsigned grp = uid / 20U;
    unsigned off = uid % 20U;
    if (off < 16) return grp * 16U + off;
    return -1;
}

int Target::JBay::Phv::Register::deparser_id() const {
    unsigned grp = uid / 20U;
    unsigned off = uid % 20U;
    if (off < 16) return grp * 16U + off;
    return -1;
}
