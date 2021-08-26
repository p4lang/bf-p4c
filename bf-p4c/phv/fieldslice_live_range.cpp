#include "fieldslice_live_range.h"

namespace PHV {

LiveRangeInfo::OpInfo
operator||(const LiveRangeInfo::OpInfo& info1, const LiveRangeInfo::OpInfo& info2) {
    if (info1 == LiveRangeInfo::OpInfo::DEAD) {
        return info2;
    } else if (info1 == LiveRangeInfo::OpInfo::LIVE) {
        if (info2 != LiveRangeInfo::OpInfo::DEAD) {
            return info2;
        } else {
            return info1;
        }
    } else if (info1 == LiveRangeInfo::OpInfo::READ) {
        if (info2 == LiveRangeInfo::OpInfo::WRITE
            || info2 == LiveRangeInfo::OpInfo::READ_WRITE) {
                return info2;
        } else {
            return info1;
        }
    } else if (info1 == LiveRangeInfo::OpInfo::WRITE) {
        if (info2 == LiveRangeInfo::OpInfo::READ
            || info2 == LiveRangeInfo::OpInfo::READ_WRITE) {
                return info2;
        } else {
            return info1;
        }
    } else {
        return info1;
    }
}

bool LiveRangeInfo::is_live_at(int stage) const {
    BUG_CHECK(live_on_stage.size() > (std::size_t)stage, "invalid stage number: %1%", stage);
    switch (live_on_stage[stage]) {
        case LiveRangeInfo::DEAD :
            return false;
        default:
            return true;
    }
}

std::ostream &operator<<(std::ostream &out, const LiveRangeInfo& info) {
    auto opinfo_to_str = [] (const LiveRangeInfo::OpInfo &opinfo) {
        if (opinfo == LiveRangeInfo::DEAD) return "DEAD";
        else if (opinfo == LiveRangeInfo::READ) return "READ";
        else if (opinfo == LiveRangeInfo::WRITE) return "WRITE";
        else if (opinfo == LiveRangeInfo::READ_WRITE) return "READ_WRITE";
        else if (opinfo == LiveRangeInfo::LIVE) return "LIVE";
        return "";
    };

    out << info.fs << std::endl;
    out << "Parser: " << opinfo_to_str(info.live_on_parser) << std::endl;
    for (int i = 0; i < Device::numStages(); i++) {
        out << "Stage_" << i << ": " << opinfo_to_str(info.live_on_stage[i]) << std::endl;
    }
    out << "Deparser: " << opinfo_to_str(info.live_on_deparser) << std::endl;
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

void
FieldSliceLiveRangeDB::DBSetter::update_live_range_info(
    const PHV::FieldSlice& fs,
    Location& use_loc,
    Location& def_loc,
    ordered_map<FieldSlice, LiveRangeInfo>& fs_info_map
) {
    std::pair<int, int> live_span;
    bool invalid_live_span = false;
    std::pair<int, int> use_range;
    std::pair<int, int> def_range;
    using OpInfo = LiveRangeInfo::OpInfo;
    if (use_loc.u == Location::PARSER) {
        fs_info_map[fs].live_on_parser = fs_info_map[fs].live_on_parser || OpInfo::READ;
        BUG_CHECK(def_loc.u == Location::PARSER,
            "use is in parser, but def is behind it");
        use_range = std::make_pair(-1, -1);
    } else if (use_loc.u == Location::DEPARSER) {
        fs_info_map[fs].live_on_deparser = fs_info_map[fs].live_on_parser || OpInfo::READ;
        use_range = std::make_pair(Device::numStages(), Device::numStages());
    } else {
        if (use_loc.stages.size() > 0) {
            auto min_max = std::minmax_element(use_loc.stages.begin(), use_loc.stages.end());
            for (int i = *min_max.first; i <= *min_max.second; i++) {
                fs_info_map[fs].live_on_stage[i] =
                    fs_info_map[fs].live_on_stage[i] || OpInfo::READ;
            }
            use_range = std::make_pair(*min_max.first, *min_max.second);
        } else {
            invalid_live_span = true;
        }
    }

    if (def_loc.u == Location::PARSER) {
        fs_info_map[fs].live_on_parser = fs_info_map[fs].live_on_parser || OpInfo::WRITE;
        def_range = std::make_pair(-1, -1);
    } else if (def_loc.u == Location::DEPARSER) {
        fs_info_map[fs].live_on_deparser = fs_info_map[fs].live_on_parser || OpInfo::WRITE;
        BUG_CHECK(use_loc.u == Location::DEPARSER,
            "def is in deparser, but use is in front of it");
        def_range = std::make_pair(Device::numStages(), Device::numStages());
    } else {
        if (def_loc.stages.size() > 0) {
            auto min_max = std::minmax_element(def_loc.stages.begin(), def_loc.stages.end());
            for (int i = *min_max.first; i <= *min_max.second; i++) {
                fs_info_map[fs].live_on_stage[i] =
                    fs_info_map[fs].live_on_stage[i] || OpInfo::WRITE;
            }
            def_range = std::make_pair(*min_max.first, *min_max.second);
        } else {
            invalid_live_span = true;
        }
    }
    if (!invalid_live_span) {
        if (use_range.first < def_range.second) {
            LOG1("use in front of def detected");
        } else if (use_range.first > def_range.second) {
            for (int i = def_range.second + 1; i <= use_range.first - 1; i++) {
                fs_info_map[fs].live_on_stage[i] =
                    fs_info_map[fs].live_on_stage[i] || OpInfo::LIVE;
            }
        }
    }
}

void FieldSliceLiveRangeDB::DBSetter::end_apply() {
    // collect all field slice
    ordered_set<PHV::FieldSlice> fs_set;
    for (const auto& act_to_fs :
        {fs_action_map->action_to_writes, fs_action_map->action_to_reads}) {
        for (const auto it : act_to_fs) {
            auto& fieldslice_set = it.second;
            for (const auto& fieldslice : fieldslice_set) {
                if (fs_set.count(fieldslice) == 0) {
                    fs_set.insert(fieldslice);
                }
            }
        }
    }

    ordered_map<FieldSlice, LiveRangeInfo> fs_info_map;
    for (const auto& fs : fs_set) {
        LiveRangeInfo info(fs);
        fs_info_map[fs] = info;
    }
    using OpInfo = LiveRangeInfo::OpInfo;
    for (const auto& fs : fs_set) {
        auto uses = defuse->getAllUses(fs.field()->id);
        for (const auto& use : uses) {
            auto use_unit = use.first;
            Location use_loc;
            auto field = fs.field();
            if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
                // Ignore parser use if field is marked as not parsed.
                if (notParsedFields.count(field)) continue;
                // There is no need to set the maxUse here, because maxUse is either -1 (if there is
                // no other use) or a non-negative value (which does not need to be updated).
                LOG4("\t  Used in parser.");
                use_loc.u = Location::PARSER;
            } else if (use_unit->is<IR::BFN::Deparser>()) {
                // Ignore deparser use if field is marked as not deparsed.
                if (notDeparsedFields.count(field)) continue;
                // There is no need to set the minUse here, because minUse is either DEPARSER (if
                // there is no other use) or a between [-1, dg.max_min_stage] (which does not need
                // to be updated).
                LOG4("\t  Used in deparser.");
                use_loc.u = Location::DEPARSER;
            } else if (use_unit->is<IR::MAU::Table>()) {
                const auto* t = use_unit->to<IR::MAU::Table>();
                use_loc.u = Location::TABLE;
                use_loc.stages = backtracker->stage(t);
            } else {
                BUG("unknown use unit");
            }
            auto defs_of_use = defuse->getDefs(use);
            // Update uses if there is no defs. It is possible that read without initialization.
            if (defs_of_use.size() == 0) {
                if (use_loc.u == Location::PARSER) {
                    fs_info_map[fs].live_on_parser = fs_info_map[fs].live_on_parser || OpInfo::READ;
                } else if (use_loc.u == Location::DEPARSER) {
                    fs_info_map[fs].live_on_deparser =
                        fs_info_map[fs].live_on_deparser || OpInfo::READ;
                } else if (use_loc.u == Location::TABLE) {
                    auto min_max =
                        std::minmax_element(use_loc.stages.begin(), use_loc.stages.end());
                    for (int i = *min_max.first; i <= *min_max.second; i++) {
                        fs_info_map[fs].live_on_stage[i] =
                            fs_info_map[fs].live_on_stage[i] || OpInfo::READ;
                    }
                } else {
                    BUG("unknown Location Type");
                }
                continue;
            }
            BUG_CHECK(defs_of_use.size() != 0, "def is empty");
            for (const auto& def : defs_of_use) {
                Location def_loc;
                const IR::BFN::Unit* def_unit = def.first;
                auto field = fs.field();
                // If the definition is of type ImplicitParserInit, then it was added to account for
                // uninitialized reads, and can be safely ignored. Account for all other parser
                // initializations, as long as the field is not marked notParsed.
                if (def_unit->is<IR::BFN::ParserState>() || def_unit->is<IR::BFN::Parser>()) {
                    // If the def is an implicit read inserted only for metadata fields to account
                    // for uninitialized reads, then ignore that initialization.
                    if (def.second->is<ImplicitParserInit>()) {
                        def_loc.u = Location::PARSER;
                        continue;
                    }
                    if (!notParsedFields.count(field)
                        && !(field->bridged && field->gress == INGRESS)) {
                        LOG4("\t  Field defined in parser.");
                        def_loc.u = Location::PARSER;
                    }
                } else if (def_unit->is<IR::BFN::Deparser>()) {
                    if (notDeparsedFields.count(field)) continue;
                    def_loc.u = Location::DEPARSER;
                    LOG4("\t  Defined in deparser.");
                } else if (def_unit->is<IR::MAU::Table>()) {
                    const auto* t = def_unit->to<IR::MAU::Table>();
                    def_loc.stages = backtracker->stage(t);
                }
                update_live_range_info(fs, use_loc, def_loc, fs_info_map);
            }
        }
    }

    for (auto it : fs_info_map) {
        self.set_liverange(it.first, it.second);
    }
}

void
FieldSliceLiveRangeDB::set_liverange(const PHV::FieldSlice& fs, const LiveRangeInfo& info) {
    live_range_map[fs.field()][fs] = info;
}

boost::optional<LiveRangeInfo>
FieldSliceLiveRangeDB::get_liverange(const PHV::FieldSlice& fieldslice) const {
    if (live_range_map.count(fieldslice.field())) {
        if (live_range_map.at(fieldslice.field()).count(fieldslice)) {
            return live_range_map.at(fieldslice.field()).at(fieldslice);
        } else {
            for (const auto pair : live_range_map.at(fieldslice.field())) {
                auto fs = pair.first;
                auto info = pair.second;
                if (fs.range().contains(fieldslice.range())) return info;
            }
        }
    }
    return boost::none;
}

}  // namespace PHV
