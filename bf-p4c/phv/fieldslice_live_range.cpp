#include "fieldslice_live_range.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/exceptions.h"

namespace PHV {

// result table
//    D  R  W  RW L
// D  D  R  W  RW L
// R  R  R  RW RW L
// W  W  RW W  RW L
// RW RW RW RW RW L
// L  L  L  L  L  L
LiveRangeInfo::OpInfo
operator||(const LiveRangeInfo::OpInfo& a, const LiveRangeInfo::OpInfo& b) {
    using OpInfo = LiveRangeInfo::OpInfo;
    // (1) either dead, the other
    if (a == OpInfo::DEAD) {
        return b;
    } else if (b == OpInfo::DEAD) {
        return a;
    }
    // (2) either live, return live
    if (a == OpInfo::LIVE || b == OpInfo::LIVE) {
        return OpInfo::LIVE;
    }
    // (3) then either READ_WRITE, return READ_WRITE
    if (a == OpInfo::READ_WRITE || b == OpInfo::READ_WRITE) {
        return OpInfo::READ_WRITE;
    }
    // (4) at this point, @p a and @p b can only be read or write.
    if (a != b) {
        return OpInfo::READ_WRITE;
    } else {
        return a;
    }
}

bool LiveRangeInfo::can_overlay(const LiveRangeInfo& other) const {
    BUG_CHECK(vec().size() == other.vec().size(),
              "LiveRangeInfo must have the same number of stages.");
    const int n = vec().size();
    for (int i = 0; i < n; i++) {
        const auto& op = vec()[i];
        const auto& other_op = other.vec()[i];
        // When one of the OpInfo is dead, we can overlay.
        // Even if one op might be Write, check of the next
        // stage will be cover this case.
        if (op == OpInfo::DEAD || other_op == OpInfo::DEAD) {
            continue;
        }
        // LIVE can only be overlaid when the other is DEAD.
        if (op == OpInfo::LIVE || other_op == OpInfo::LIVE) {
            return false;
        }
        // the only case when READ can be overlaid with non-Dead
        // Other's write and mine will be dead next stage.
        const auto read_ok = [&]() {
            const bool last_read = i < n - 1 && vec()[i + 1] == OpInfo::DEAD;
            if (!(other_op == OpInfo::WRITE && last_read)) {
                return false;
            }
            return true;
        };
        // the only case when a write can be overlaid with non-Dead
        // others are dead next stage.
        const auto write_ok = [&]() {
            const bool other_last_read = i < n - 1 && other.vec()[i + 1] == OpInfo::DEAD;
            if (!other_last_read) {
                return false;
            }
            return true;
        };
        // Check the special case of write-after-read overlaying.
        switch (op) {
            case OpInfo::READ_WRITE:
                if (!read_ok() || !write_ok()) {
                    return false;
                }
                break;
            case OpInfo::READ:
                if (!read_ok()) {
                    return false;
                }
                break;
            case OpInfo::WRITE:
                if (!write_ok()) {
                    return false;
                }
                break;
            default:
                continue;  // surpass warnings.
        }
    }
    return true;
}

std::vector<std::pair<PHV::StageAndAccess, PHV::StageAndAccess>> LiveRangeInfo::disjoint_ranges()
    const {
    std::vector<std::pair<PHV::StageAndAccess, PHV::StageAndAccess>> rst;
    boost::optional<int> last_defined_read;
    for (int i = 0; i < int(lives_i.size()); i++) {
        if (lives_i[i] == OpInfo::DEAD) {
            continue;
        }
        BUG_CHECK(lives_i[i] != OpInfo::LIVE, "live without definition: %1%", *this);

        // uninitialized read, not even caught by parser implicit init,
        // field can be considered as not live, we will add a short live range of [x, x).
        // NOTE that we ignore uninitialized reads in parser (i != 0) because parser reads
        // values from input buffer instead of PHV containers.
        if (i != 0 && (lives_i[i] == OpInfo::READ || lives_i[i] == OpInfo::READ_WRITE)) {
            const auto uninit_read = std::make_pair(i - 1, PHV::FieldUse(PHV::FieldUse::READ));
            const auto empty_liverange = std::make_pair(uninit_read, uninit_read);
            if (lives_i[i] == OpInfo::READ) {
                rst.emplace_back(empty_liverange);
                LOG6("uninitialized read: " << uninit_read);
                continue;
            } else {
                // The read in this READ_WRITE must be not actually initialized.
                // DO NOT skip this WRITE of READ_WRITE starting from i.
                if (!last_defined_read || last_defined_read != i) {
                    rst.emplace_back(empty_liverange);
                    LOG6("uninitialized read: " << uninit_read);
                }
            }
        }

        auto start = std::make_pair(i - 1, PHV::FieldUse(PHV::FieldUse::WRITE));
        int j = i + 1;
        while (j < int(lives_i.size()) && lives_i[j] == OpInfo::LIVE) ++j;
        if (j == int(lives_i.size()) ||
            lives_i[j] == OpInfo::DEAD || lives_i[j] == OpInfo::WRITE) {
            rst.emplace_back(std::make_pair(start, start));
            i = j - 1;
            continue;
        }
        BUG_CHECK(lives_i[j] != OpInfo::WRITE, "invalid end of live range: %1% of %2%", j, *this);
        auto end = std::make_pair(j - 1, PHV::FieldUse(PHV::FieldUse::READ));
        rst.emplace_back(std::make_pair(start, end));
        i = j;
        // when the end is READ_WRITE, it is also a start of the next live range.
        if (lives_i[j] == OpInfo::READ_WRITE) {
            last_defined_read = i;
            i--;
        }
    }
    return rst;
}

std::ostream &operator<<(std::ostream &out, const LiveRangeInfo& info) {
    auto opinfo_to_str = [](const LiveRangeInfo::OpInfo& opinfo) {
        if (opinfo == LiveRangeInfo::OpInfo::DEAD)
            return "DEAD";
        else if (opinfo == LiveRangeInfo::OpInfo::READ)
            return "READ";
        else if (opinfo == LiveRangeInfo::OpInfo::WRITE)
            return "WRITE";
        else if (opinfo == LiveRangeInfo::OpInfo::READ_WRITE)
            return "READ_WRITE";
        else if (opinfo == LiveRangeInfo::OpInfo::LIVE)
            return "LIVE";
        return "";
    };

    out << "Parser: " << opinfo_to_str(info.parser()) << std::endl;
    for (int i = 0; i < Device::numStages(); i++) {
        out << "Stage_" << i << ": " << opinfo_to_str(info.stage(i)) << std::endl;
    }
    out << "Deparser: " << opinfo_to_str(info.deparser()) << std::endl;
    return out;
}

Visitor::profile_t FieldSliceLiveRangeDB::init_apply(const IR::Node *root) {
    profile_t rv = PassManager::init_apply(root);
    live_range_map.clear();
    return rv;
}

Visitor::profile_t FieldSliceLiveRangeDB::MapFieldSliceToAction::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    action_to_writes.clear();
    action_to_reads.clear();
    return rv;
}

bool FieldSliceLiveRangeDB::MapFieldSliceToAction::preorder(const IR::MAU::Action *act) {
    auto *tbl = findContext<IR::MAU::Table>();
    BUG_CHECK(tbl != nullptr, "unable to find a table in context");
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap field_actions_map;
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);

    for (const auto &field_action : Values(field_actions_map)) {
        le_bitrange write_range;
        auto *write_field = phv.field(field_action.write.expr, &write_range);
        BUG_CHECK(write_field != nullptr, "Action does not have a write?");
        PHV::FieldSlice write(write_field, write_range);
        action_to_writes[act].insert(write);
        for (const auto &read : field_action.reads) {
            if (read.type == ActionAnalysis::ActionParam::PHV) {
                le_bitrange read_range;
                auto f_used = phv.field(read.expr, &read_range);
                PHV::FieldSlice read_fs(f_used, read_range);
                action_to_reads[act].insert(read_fs);
            }  // don't care about others
        }
    }
    return false;
}

boost::optional<FieldSliceLiveRangeDB::DBSetter::Location>
FieldSliceLiveRangeDB::DBSetter::to_location(const PHV::Field* field,
                                             const FieldDefUse::locpair& unit_expr,
                                             bool is_read) const {
    const auto* unit = unit_expr.first;
    const auto* expr = unit_expr.second;
    Location loc;
    if (unit->is<IR::BFN::ParserState>() || unit->is<IR::BFN::Parser>() ||
        unit->is<IR::BFN::GhostParser>()) {
        if (!is_read) {
            // Ignore implicit parser init when the field is marked as no_init.
            if (expr->is<ImplicitParserInit>() && not_implicit_init_fields().count(field))
                return boost::none;
        }
        loc.u = Location::PARSER;
    } else if (unit->is<IR::BFN::Deparser>()) {
        loc.u = Location::DEPARSER;
    } else if (unit->is<IR::MAU::Table>()) {
        const auto* t = unit->to<IR::MAU::Table>();
        loc.u = Location::TABLE;
        loc.stages = backtracker->stage(t);
    } else {
        BUG("unknown use unit: %1%, field: %2%", unit, field);
    }
    return loc;
}

std::pair<int, int> FieldSliceLiveRangeDB::DBSetter::update_live_status(
        LiveRangeInfo& liverange, const Location& loc, bool is_read) const {
    using OpInfo = LiveRangeInfo::OpInfo;
    const LiveRangeInfo::OpInfo op = is_read ? OpInfo::READ : OpInfo::WRITE;
    std::pair<int, int> updated_range;
    if (loc.u == Location::PARSER) {
        liverange.parser() = liverange.parser() || op;
        updated_range = std::make_pair(-1, -1);
    } else if (loc.u == Location::DEPARSER) {
        liverange.deparser() = liverange.deparser() || op;
        updated_range = std::make_pair(Device::numStages(), Device::numStages());
    } else if (loc.u == Location::TABLE) {
        BUG_CHECK(loc.stages.size() > 0, "table not allocated");
        const auto min_max = std::minmax_element(loc.stages.begin(), loc.stages.end());
        for (int i = *min_max.first; i <= *min_max.second; i++) {
            liverange.stage(i) = liverange.stage(i) || op;
        }
        updated_range = std::make_pair(*min_max.first, *min_max.second);
    } else {
        BUG("unknown Location Type");
    }
    return updated_range;
}

void FieldSliceLiveRangeDB::DBSetter::update_live_range_info(const PHV::FieldSlice& fs,
                                                             const Location& use_loc,
                                                             const Location& def_loc,
                                                             LiveRangeInfo& liverange) const {
    LOG3("update_live_range_info " << fs << ": " << def_loc.u << "," << use_loc.u);
    std::pair<int, int> use_range = update_live_status(liverange, use_loc, true);
    std::pair<int, int> def_range = update_live_status(liverange, def_loc, false);

    // mark(or) LIVE for stages in between.
    using OpInfo = LiveRangeInfo::OpInfo;
    if (def_range.second < use_range.first) {
        // NOTE: for fieldslice the its def or use table are split across multiple stages.
        // The live range starts at the first def table stage and end at the last read stage.
        for (int i = def_range.first + 1; i <= use_range.second - 1; i++) {
            liverange.stage(i) = liverange.stage(i) || OpInfo::LIVE;
        }
    } else {
        // read write within parser does not matter.
        if (use_range.first == -1 && def_range.second == -1) {
            return;
        }
        // TODO(yumin): we need to handle this case more carefully. For example,
        // There could be a table that has a dominating write of this read in control flow
        // but because of ignore_table_dependency pragma, the write table is placed after
        // the read table. Then we need to find write of the read earlier in the pipeline.
        ::warning(
            "Because of ignore_table_dependency pragma, for %1% field, the read in stage %2% "
            "cannot source its definition of the write in stage %3%. Unexpected value might be "
            "read and physical live range analysis will set its liverange to the whole pipeline,"
            " regardless of the actual physical live range.",
            cstring::to_cstring(fs), use_range.first, def_range.second);
        liverange.parser() = OpInfo::WRITE;
        for (int i = 0; i <= Device::numStages() - 1; i++) {
            liverange.stage(i) = OpInfo::LIVE;
        }
        liverange.deparser() = OpInfo::READ;
    }
}

void FieldSliceLiveRangeDB::DBSetter::end_apply() {
    // skip this when table has not been placed or alt_phv_alloc is not enabled.
    // because when alt_phv_alloc is not enabled, table placement might be incomplete.
    if (!backtracker->hasTablePlacement() || !BFNContext::get().options().alt_phv_alloc) {
        LOG1("alt-phv-alloc not enabled or no table placement found, skip FieldSliceLiveRangeDB");
        return;
    }
    // collect all field slice. Note that because defuse analysis is still based on
    // whole fields instead of slices, it is okay to use the whole field.
    // TODO(yumin):
    //   (1) use MakeSlices info from make_clsuters.
    //   (2) update defuse pass to use slice-level read/write analysis.
    ordered_set<PHV::FieldSlice> fs_set;
    ordered_map<FieldSlice, LiveRangeInfo> fs_info_map;
    for (const auto& kv : phv.get_all_fields()) {
        const auto fs = PHV::FieldSlice(&kv.second);
        fs_set.insert(fs);
        fs_info_map.emplace(fs, LiveRangeInfo());
    }

    for (const auto& fs : fs_set) {
        LOG5("compute physical live range: " << fs);
        LiveRangeInfo& liverange = fs_info_map[fs];
        const auto* field = fs.field();

        // set (W..L...R) for all paired defuses.
        for (const FieldDefUse::locpair& use : defuse->getAllUses(fs.field()->id)) {
            LOG5("found use: " << use.second);
            const auto use_loc = to_location(field, use, true);
            BUG_CHECK(use_loc, "use cannot be ignored");
            const auto& defs_of_use = defuse->getDefs(use);

            // Always update uses It is possible for field to be read without def.
            // For example,
            // (1) fields added by compiler as padding for deparsed(digested) metadata.
            // (2) a = a & 1, when a has not been written before, including auto-init-metadata
            //     is disabled on this field.
            update_live_status(liverange, *use_loc, true);

            // mark(or) W and R and all stages in between to LIVE.
            for (const auto& def : defs_of_use) {
                LOG5("found paired def: " << def.second);
                const auto* field = fs.field();
                const auto def_loc = to_location(field, def, false);
                if (def_loc) {
                    update_live_range_info(fs, *use_loc, *def_loc, fs_info_map[fs]);
                } else {
                    LOG5("ignoring parser init of " << field->name
                         << ", because @pa_auto_init_metadata is not enabled for this field.");
                }
            }
        }

        // set (w) for tailing writes (write without read)
        for (const FieldDefUse::locpair& def : defuse->getAllDefs(fs.field()->id)) {
            const auto& uses_of_def = defuse->getUses(def);
            if (!uses_of_def.empty()) {
                continue;
            }
            // implicit parser init, is not an actual write. If there is no paired
            // uses, it is safe to ignore.
            if (def.second->is<ImplicitParserInit>()) {
                continue;
            }
            const auto def_loc = to_location(field, def, false);
            if (!def_loc) {
                continue;
            }
            LOG5("found tailing write: " << def.first);
            update_live_status(liverange, *def_loc, false);
        }
    }

    for (auto it : fs_info_map) {
        self.set_liverange(it.first, it.second);
        LOG3("Live range of " << it.first << ":\n" << it.second);
    }
}

void
FieldSliceLiveRangeDB::set_liverange(const PHV::FieldSlice& fs, const LiveRangeInfo& info) {
    live_range_map[fs.field()][fs] = info;
}

const LiveRangeInfo*
FieldSliceLiveRangeDB::get_liverange(const PHV::FieldSlice& fieldslice) const {
    if (live_range_map.count(fieldslice.field())) {
        if (live_range_map.at(fieldslice.field()).count(fieldslice)) {
            return &live_range_map.at(fieldslice.field()).at(fieldslice);
        } else {
            for (const auto& pair : live_range_map.at(fieldslice.field())) {
                const auto& fs = pair.first;
                const auto& info = pair.second;
                if (fs.range().contains(fieldslice.range())) return &info;
            }
        }
    }
    return nullptr;
}

const LiveRangeInfo* FieldSliceLiveRangeDB::default_liverange() const {
    static LiveRangeInfo* whole_pipe = nullptr;
    if (whole_pipe) {
        return whole_pipe;
    }
    whole_pipe = new LiveRangeInfo();
    whole_pipe->parser() = LiveRangeInfo::OpInfo::WRITE;
    for (int i = 0; i < Device::numStages(); i++) {
        whole_pipe->stage(i) = LiveRangeInfo::OpInfo::LIVE;
    }
    whole_pipe->deparser() = LiveRangeInfo::OpInfo::READ;
    return whole_pipe;
}

}  // namespace PHV
