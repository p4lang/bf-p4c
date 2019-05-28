#include "long_branch.h"
#include "device.h"

/** LongBrachAlloc::Info track information about a single long branch use
 *  tag:                        Tag allocated for this use or -1 if not (yet) allocated
 *  first_stage, last_stage:    Range of stages over which it is in use
 *  tables                      Tables run by the long branch
 *  optional                    Additional tables that will always run anyways if the
 *                              long branch is enabled, so can freely be added without
 *                              affecting the behavior; allow for more flexible merges
 */
LongBranchAlloc::Info::Info(const IR::MAU::Table *tbl, const IR::MAU::TableSeq *nxt) {
    first_stage = last_stage = tbl->stage();
    BUG_CHECK(first_stage >= 0, "Unplaced table %s", tbl);
    for (auto *t : nxt->tables) {
        auto st = t->stage();
        BUG_CHECK(st >= 0, "Unplaced table %s", t);
        if (st > last_stage)
            last_stage = st;
        if (st > first_stage + 1)
            tables.insert(t->unique_id());
        else
            optional.insert(t->unique_id()); }
}

bool LongBranchAlloc::Info::can_merge(const Info &a) const {
    for (auto id : tables)
        if (!a.tables.count(id) && !a.optional.count(id)) return false;
    for (auto id : a.tables)
        if (!tables.count(id) && !optional.count(id)) return false;
    return true;
}

void LongBranchAlloc::Info::merge(const Info &a) {
    // tables |= a.tables;
    // optional -= a.tables;
    for (auto id : a.tables) {
        tables.insert(id);
        optional.erase(id); }
    // optional &= a.optional
    for (auto it = optional.begin(); it != optional.end();) {
        if (a.optional.count(*it))
            ++it;
        else
            it = optional.erase(it); }
    first_stage = std::min(first_stage, a.first_stage);
    last_stage = std::max(last_stage, a.last_stage);
}

void LongBranchAlloc::add_use(Info *info) {
    if (info->tag < 0) return;
    stage_use[info->tag] |= info->stage_use();
    for (auto st = info->first_stage; st <= info->last_stage; ++st) {
        if (use[st][info->tag] && use[st][info->tag] != info)
            BUG("conflicting allocation for long branch tag %d in stage %d", info->tag, st);
        use[st][info->tag] = info; }
}

std::ostream &operator<<(std::ostream &out, LongBranchAlloc::Info &info) {
    out << info.tag << ": (" << info.first_stage << ".." << info.last_stage << ") {";
    const char *sep = " ";
    for (auto id : info.tables) {
        out << sep << id;
        sep = ", "; }
    sep = " ? ";
    for (auto id : info.optional) {
        out << sep << id;
        sep = ", "; }
    out << " }";
    return out;
}

/* Find a previously allocated long branch that we can safely merge this one with */
LongBranchAlloc::Info *LongBranchAlloc::find_merge(Info *info) {
    for (auto t = 0U; t < stage_use.size(); ++t) {
        Info *rv = nullptr;
        for (auto st = info->first_stage; st < info->last_stage; ++st) {
            if (use[st][t]) {
                if (!rv) {
                    if (!use[st][t]->can_merge(*info))
                        break;
                    rv = use[st][t];
                } else if (rv != use[st][t]) {
                    rv = nullptr;
                    break; } } }
        if (rv) return rv; }
    return nullptr;
}

LongBranchAlloc::Info *LongBranchAlloc::alloc(Info *info) {
    auto *rv = new Info(*info);
    rv->tag = 0;
    while (size_t(rv->tag) < stage_use.size() && (stage_use[rv->tag] & info->stage_use()))
        ++rv->tag;
    return rv;
}

bool LongBranchAlloc::preorder(IR::MAU::Table *tbl) {
    tbl->long_branch.clear();
    if (!findContext<IR::MAU::Table>())
        tbl->always_run = true;
    for (auto &next : tbl->next) {
        Info info(tbl, next.second);
        if (!info.tables.empty()) {
            LOG2("Need long_branch for " << tbl->name << ":" << next.first);
            if (auto *i = find_merge(&info)) {
                i->merge(info);
                add_use(i);
                tbl->long_branch[i->tag] = next.first;
                LOG3("  merged: " << *i);
            } else if (auto *i = alloc(&info)) {
                if (i->tag >= Device::numLongBranchTags())
                    error(ErrorType::ERR_OVERLIMIT, "Too many long branches", tbl);
                add_use(i);
                tbl->long_branch[i->tag] = next.first;
                LOG3("  alloc: " << *i);
            }
        }
    }
    return true;
}
