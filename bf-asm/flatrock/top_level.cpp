#include <target.h>

Target::Flatrock::top_level_regs::top_level_regs() {
    for (auto &scm : reg_pipe.ppu_pack.scm) {
        for (auto &tcam_mode : scm.stage_addrmap.tcam_mode) {
            tcam_mode.key_sel = 6;  // default to disabled
            tcam_mode.set_modified(false);
        }
    }
}
