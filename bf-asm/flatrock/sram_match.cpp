#include "sram_match.h"

void SRamMatchTable::verify_format(Target::Flatrock) {
    format->pass1(this);
    group_info.resize(format->groups());
    std::vector<int> offsets = { 0 };
    for (unsigned i = 1; i < format->groups(); i++) {
        for (auto &field : format->group(i)) {
            auto &f0 = *field.second.by_group[0];
            if (field.second.bits.size() != f0.bits.size()) {
                error(format->lineno, "mismatch for %s between match groups 0 and %d",
                      field.first.c_str(), i);
                continue; }
            auto it = field.second.bits.begin();
            for (auto &bits : f0.bits) {
                if (offsets.size() <= i) offsets.push_back(it->lo - bits.lo);
                if (it->lo - bits.lo != offsets.at(i) || it->hi - bits.hi != offsets.at(i))
                    error(format->lineno, "mismatch for %s between match groups 0 and %d",
                          field.first.c_str(), i);
                ++it; } } }
    if (error_count > 0) return;
    for (unsigned i = 1; i < offsets.size(); i++) {
        if (offsets.at(i) < offsets.at(i-1)) {
            error(format->lineno, "match groups %d and %d out of order", i-1, i);
            // FIXME -- could sort them if they're out of order instead
            return; } }
    if ((offsets.size() & (offsets.size() - 1)) == 0) {  // power of 2 size
        int stride = (1 << format->log2size)/offsets.size();
        for (unsigned i = 1; i < offsets.size(); i++) {
            if (offsets.at(i) != i*stride) {
                error(format->lineno, "match group %d at wrong offset %d (should be %d)",
                      i, offsets.at(i), i*stride);
                return; } }
    } else {
        int sets = offsets.size()/3;
        if ((sets & (sets-1)) || sets*3U != offsets.size()) {
            error(format->lineno, "Invalid number of match groups");
            return; }
        int stride = (1 << format->log2size)/sets;
        for (unsigned i = 1; i < offsets.size(); i++) {
            if (offsets.at(i) != (i/3)*stride + (i%3)*(stride/3)) {
                error(format->lineno, "match group %d at wrong offset %d (should be %d)",
                      i, offsets.at(i), (i/3)*stride + (i%3)*(stride/3));
                return; } } }
    verify_match((format->size + 127)/128);
}

template<> void SRamMatchTable::write_attached_merge_regs(Target::Flatrock::mau_regs &regs,
            int bus, int word, int word_group) {
    error(lineno, "%s:%d: Flatrock sram match not implemented yet!", __FILE__, __LINE__);
}
template<> void SRamMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### SRam match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 0, this);
    for (auto &ixb : input_xbar)
        ixb->write_xmu_regs(regs);

    for (auto &row : layout) {
        error(lineno, "%s:%d: Flatrock STM not implemented yet!", __FILE__, __LINE__);
    }

    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

