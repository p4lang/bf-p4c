#include "pseudo_parser.h"
#include "target.h"
#include "misc.h"
#include "hdr.h"

void FlatrockPseudoParser::input(VECTOR(value_t) args, value_t data) {
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "pov_flags_pos") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1);
            pov_flags_pos = kv.value.i;
        } else if (kv.key == "pov_state_pos") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1);
            pov_state_pos = kv.value.i;
        } else {
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
}

void FlatrockPseudoParser::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    _regs.egress.pprsr_pov_bmd_ext.st_start = pov_state_pos;
    _regs.egress.pprsr_pov_bmd_ext.flg_start = pov_flags_pos;
    _regs.egress.pprsr_comp_hdr_bmd_ext.off_start = Hdr::hdr.off_pos;
    _regs.egress.pprsr_comp_hdr_bmd_ext.id_start = Hdr::hdr.seq_pos;
    _regs.egress.pprsr_comp_hdr_bmd_ext.len_start = Hdr::hdr.len_pos;
}

void FlatrockPseudoParser::output(json::map &json) {
    auto *regs = new Target::Flatrock::parser_regs;
    declare_registers(regs);
    write_config(*regs, json, false);
}
