#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/phv/analysis/dark_live_range.h"
#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/phv/utils/liverange_opti_utils.h"
#include "bf-p4c/common/table_printer.h"

bool DarkLiveRange::overlaps(
        const int num_max_min_stages,
        const DarkLiveRangeEntry& range1,
        const DarkLiveRangeEntry& range2) {
    const int DEPARSER = num_max_min_stages + 1;
    bitvec f1Uses;
    bitvec f2Uses;
    unsigned index = 0;
    for (int i = 0; i <= DEPARSER; i++) {
        for (unsigned j : { READ, WRITE }) {
            StageAndAccess stageAndAccess = std::make_pair(i, PHV::FieldUse(j));
            if (range1.count(stageAndAccess)) {
                if (!range1.at(stageAndAccess).second) {
                    // Ignore dark uses for the purposes of deciding overlay
                    f1Uses.setbit(index);
                    LOG5("\t\t  Setting f1 bit " << index << ", stage " << i << ": " <<
                            PHV::FieldUse(j));
                } else {
                    LOG5("\t\t\tNot setting f1 bit " << index << ", stage " << i << ": " <<
                         "DARK " << PHV::FieldUse(j));
                }
            }
            if (range2.count(stageAndAccess)) {
                if (!range2.at(stageAndAccess).second) {
                    f2Uses.setbit(index);
                    LOG5("\t\t  Setting f2 bit " << index << ", stage " << i << ": " <<
                            PHV::FieldUse(j));
                } else {
                    LOG5("\t\t\tNot setting f2 bit " << index << ", stage " << i << ": " <<
                         "DARK " << PHV::FieldUse(j));
                }
            }
            ++index;
        }
    }
    LOG4("\t\tField 1 use: " << f1Uses << ", Field 2 use: " << f2Uses);
    bitvec combo = f1Uses & f2Uses;
    LOG4("\t\tcombo: " << combo << ", empty? " << (combo.popcount() != 0));
    return (combo.popcount() != 0);
}

bool DarkLiveRange::increasesDependenceCriticalPath(
        const IR::MAU::Table* use,
        const IR::MAU::Table* init) const {
    const int maxStages = dg.max_min_stage_per_gress[use->gress];
    int use_stage = dg.min_stage(use);
    int init_stage = dg.min_stage(init);
    int init_dep_tail = dg.dependence_tail_size_control_anti(init);
    LOG5("\t\tuse table: " << use->name << ", init table: " << init->name);
    LOG5("\t\tuse_stage: " << use_stage << ", init_stage: " << init_stage << ", init_dep_tail: " <<
         init_dep_tail);
    if (use_stage < init_stage) return false;
    int new_init_stage = use_stage + 1;
    LOG5("\t\tnew_init_stage: " << new_init_stage << ", maxStages: " << maxStages);
    if (new_init_stage + init_dep_tail > maxStages)
        return true;
    return false;
}


Visitor::profile_t DarkLiveRange::init_apply(const IR::Node* root) {
    livemap.clear();
    overlay.clear();
    doNotInitActions.clear();
    fieldToUnitUseMap.clear();
    doNotInitToDark.clear();
    doNotInitTables.clear();
    BUG_CHECK(dg.finalized, "Dependence graph is not populated.");
    LOG3("Printing dependency graph");
    LOG3(dg);
    // For each use of the field, parser implies stage `dg.max_min_stage + 2`, deparser implies
    // stage `dg.max_min_stage + 1` (12 for Tofino), and a table implies the corresponding
    // dg.min_stage.
    DEPARSER = dg.max_min_stage + 1;
    livemap.setDeparserStageValue(DEPARSER);
    LOG1("Deparser is at " << DEPARSER << ", max stage: " << dg.max_min_stage);
    return Inspector::init_apply(root);
}

bool DarkLiveRange::preorder(const IR::MAU::Table* tbl) {
    uint64_t totalKeySize = 0;
    for (const auto* key : tbl->match_key) {
        le_bitrange bits;
        const auto* field = phv.field(key->expr, &bits);
        if (!field) continue;
        totalKeySize += bits.size();
    }
    if (!tbl->match_table) return true;
    const auto* sz = tbl->match_table->getSizeProperty();
    if (!sz) return true;
    if (!sz->fitsUint64()) return true;
    uint64_t tableSize = sz->asUint64();
    uint64_t totalBits = totalKeySize * tableSize;
    if (totalBits > Memories::SRAM_ROWS * Memories::SRAM_COLUMNS * Memories::SRAM_DEPTH * 128) {
        doNotInitTables.insert(tbl);
        LOG4("\tDo not insert initialization in table: " << tbl->name);
    }
    return true;
}

bool DarkLiveRange::preorder(const IR::MAU::Action* act) {
    GetHashDistReqs ghdr;
    act->apply(ghdr);
    if (ghdr.is_hash_dist_needed()) {
        LOG2("\tCannot initialize at action " << act->name << " because it requires " <<
             "the hash distribution unit.");
        doNotInitActions.insert(act);
    }
    return true;
}

void DarkLiveRange::setFieldLiveMap(const PHV::Field* f) {
    LOG4("    Setting live range for field " << f);
    // minUse = earliest stage for uses of the field.
    // maxUse = latest stage for uses of the field.
    // minDef = earliest stage for defs of the field.
    // maxDef = latest stage for defs of the field.
    // Set the min values initially to the deparser, and the max values to the parser initially.
    for (const FieldDefUse::locpair use : defuse.getAllUses(f->id)) {
        const IR::BFN::Unit* use_unit = use.first;
        if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
            // Ignore parser use if field is marked as not parsed.
            if (notParsedFields.count(f)) {
                LOG4("\t  Ignoring field " << f << " use in parser");
                continue;
            }
            LOG4("\t  Used in parser.");
            livemap.addAccess(f, 0 /* stage */, READ, use_unit, false);
            livemap.addAccess(f, PARSER, READ, use_unit, false);
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            // Ignore deparser use if field is marked as not deparsed.
            if (notDeparsedFields.count(f)) continue;
            LOG4("\t  Used in deparser.");
            livemap.addAccess(f, DEPARSER, READ, use_unit, false);
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            int use_stage = dg.min_stage(t);
            LOG4("\t  Used in stage " << use_stage << " in table " << t->name);
            livemap.addAccess(f, use_stage, READ, use_unit, !defuse.hasNonDarkContext(use));
            if (!defuse.hasNonDarkContext(use)) LOG4("\t\tCan use in a dark container.");
        } else {
            BUG("Unknown unit encountered %1%", use_unit->toString());
        }
        fieldToUnitUseMap[f][use_unit] |= PHV::FieldUse(READ);
    }

    // Set live range for every def of the field.
    for (const FieldDefUse::locpair def : defuse.getAllDefs(f->id)) {
        const IR::BFN::Unit* def_unit = def.first;
        // If the field is specified as pa_no_init, and it has an uninitialized read, we ignore the
        // compiler-inserted parser initialization.
        if (noInitFields.count(f) && defuse.hasUninitializedRead(f->id)) {
            if (def_unit->is<IR::BFN::ParserState>()) {
                LOG4("Ignoring def of field " << f << " with uninitialized read and def in "
                     "parser state " << DBPrint::Brief << def_unit);
                continue;
            }
        }
        // If the field is not specified as pa_no_init and has a def in the parser, check if the def
        // is of type ImplicitParserInit, and if it is, we can safely ignore this def.
        if (def_unit->is<IR::BFN::ParserState>() || def_unit->is<IR::BFN::Parser>()) {
            if (def.second->is<ImplicitParserInit>()) {
                LOG4("\t\tIgnoring implicit parser init.");
                continue;
            }
            if (notParsedFields.count(f)) LOG4("\t\tIgnoring because field set to not parsed");
            if (!notParsedFields.count(f) && !(f->bridged && f->gress == INGRESS)) {
                LOG4("\t  Field defined in parser.");
                livemap.addAccess(f, PARSER, WRITE, def_unit, false);
                livemap.addAccess(f, 0 /* first stage */, READ, def_unit, false);
                continue;
            }
        } else if (def_unit->is<IR::BFN::Deparser>()) {
            if (notDeparsedFields.count(f)) continue;
            LOG4("\t  Defined in deparser.");
            livemap.addAccess(f, DEPARSER, WRITE, def_unit, false);
        } else if (def_unit->is<IR::MAU::Table>()) {
            const auto* t = def_unit->to<IR::MAU::Table>();
            int def_stage = dg.min_stage(t);
            LOG4("\t  Defined in stage " << def_stage << " in table " << t->name);
            livemap.addAccess(f, def_stage, WRITE, def_unit,
                    !defuse.hasNonDarkContext(def));
            if (!defuse.hasNonDarkContext(def)) LOG4("\t\tCan use in a dark container");
        } else {
            BUG("Unknown unit encountered %1%", def_unit->toString());
        }
        fieldToUnitUseMap[f][def_unit] |= PHV::FieldUse(WRITE);
    }
}

void DarkLiveRange::end_apply() {
    // If there are no stages required, do not run this pass.
    if (dg.max_min_stage < 0) return;
    // Set of fields whose live ranges must be calculated.
    ordered_set<const PHV::Field*> fieldsConsidered;
    for (const PHV::Field& f : phv) {
        if (clot.fully_allocated(&f)) continue;
        if (f.is_deparser_zero_candidate()) continue;
        // Ignore unreferenced fields because they are not allocated anyway.
        if (!uses.is_referenced(&f)) continue;
        // Ignore POV fields.
        if (f.pov) continue;
        fieldsConsidered.insert(&f);
    }
    for (const auto* f : fieldsConsidered) setFieldLiveMap(f);
    if (LOGGING(1)) LOG1(livemap.printDarkLiveRanges());
    for (const auto* f1 : fieldsConsidered) {
        // Do not dark overlay ghost fields.
        if (f1->isGhostField()) continue;
        for (const auto* f2 : fieldsConsidered) {
            if (f1 == f2) continue;
            if (f2->isGhostField()) continue;
            // No overlay possible if fields are of different gresses.
            if (f1->gress != f2->gress) {
                overlay(f1->id, f2->id) = false;
                continue;
            }
            if (!livemap.count(f1) || !livemap.count(f2)) {
                // Overlay possible because one of these fields is not live at all.
                overlay(f1->id, f2->id) = true;
                continue;
            }
            auto& access1 = livemap.at(f1);
            auto& access2 = livemap.at(f2);
            LOG3("    (" << f1->name << ", " << f2->name << ")");
            if (!overlaps(dg.max_min_stage, access1, access2)) {
                LOG4("      Overlay possible between " << f1 << " and " << f2);
                overlay(f1->id, f2->id) = true;
            }
        }
    }
}

boost::optional<DarkLiveRange::ReadWritePair> DarkLiveRange::getFieldsLiveAtStage(
        const ordered_set<PHV::AllocSlice>& fields,
        const int stage) const {
    const PHV::AllocSlice* readField = nullptr;
    const PHV::AllocSlice* writtenField = nullptr;
    bool readDarkOk = false;
    bool writeDarkOk = false;
    for (auto& sl : fields) {
        if (livemap.hasAccess(sl.field(), stage, READ)) {
            if (readField != nullptr) {
                LOG4("Slices " << readField << " and " << sl << " already read in stage " <<
                     ((stage == DEPARSER) ? "deparser" : std::to_string(stage)));
                return boost::none;
            }
            readField = &sl;
            readDarkOk = livemap.canBeDark(sl.field(), stage, READ);
        }
        if (livemap.hasAccess(sl.field(), stage, WRITE)) {
            if (writtenField != nullptr) {
                LOG4("Slices " << writtenField << " and " << sl << " both written in stage " <<
                     stage);
                return boost::none;
            }
            writtenField = &sl;
            writeDarkOk = livemap.canBeDark(sl.field(), stage, WRITE);
        }
    }
    if (readField)
        LOG5("\t\t  Adding slice " << *readField << " READ in stage " << stage << ", dark " <<
             (readDarkOk ? "OK" : "NOT OK"));
    if (writtenField)
        LOG5("\t\t  Adding slice " << *writtenField << " WRITE in stage " << stage << ", dark "
             << (writeDarkOk ? "OK" : "NOT OK"));
    return std::make_pair(readField, writtenField);
}

bool DarkLiveRange::validateLiveness(const OrderedFieldSummary& rv) const {
    const OrderedFieldInfo* lastSlice = nullptr;
    static PHV::FieldUse read(READ);
    static PHV::FieldUse write(WRITE);
    for (auto& info : rv) {
        if (lastSlice == nullptr) {
            lastSlice = &info;
            continue;
        }
        if (info.minStage.second == read) {
            // If the min stage is a read, then the initialization must happen in the previous
            // stage. Therefore, we need to calculate a real min stage that is 1 less than the min
            // stage calculated earlier.
            int realMinStage = info.minStage.first - 1;
            if (lastSlice->maxStage.second == write && lastSlice->maxStage.first >= realMinStage) {
                LOG5("\t\t  Found overlapping slices in terms of live range: ");
                LOG5("\t\t\t" << lastSlice->field.field()->name << " [" << lastSlice->minStage.first
                        << lastSlice->minStage.second << ", " << lastSlice->maxStage.first <<
                        lastSlice->maxStage.second << "]");
                LOG5("\t\t\t" << info.field.field()->name << " [" << lastSlice->minStage.first <<
                        lastSlice->minStage.second << ", " << lastSlice->maxStage.first <<
                        lastSlice->maxStage.second << "]");
                return false;
            }
        }
        lastSlice = &info;
    }
    return true;
}

boost::optional<DarkLiveRange::OrderedFieldSummary> DarkLiveRange::produceFieldsInOrder(
        const ordered_set<PHV::AllocSlice>& fields) const {
    OrderedFieldSummary rv;
    const PHV::AllocSlice* lastField = nullptr;
    for (int i = 0; i <= DEPARSER; i++) {
        auto fieldsLiveAtStage = getFieldsLiveAtStage(fields, i);
        if (!fieldsLiveAtStage) return boost::none;
        if (fieldsLiveAtStage->first != nullptr) {
            auto& readAccess = livemap.at(fieldsLiveAtStage->first->field(), i, READ);
            if (lastField != fieldsLiveAtStage->first) {
                lastField = fieldsLiveAtStage->first;
                OrderedFieldInfo info(*lastField, std::make_pair(i, PHV::FieldUse(READ)),
                        readAccess);
                rv.push_back(info);
            } else {
                rv[rv.size() - 1].addAccess(std::make_pair(i, PHV::FieldUse(READ)), readAccess);
            }
        }
        if (fieldsLiveAtStage->second != nullptr) {
            auto& writeAccess = livemap.at(fieldsLiveAtStage->second->field(), i, WRITE);
            if (lastField != fieldsLiveAtStage->second) {
                lastField = fieldsLiveAtStage->second;
                OrderedFieldInfo info(*lastField, std::make_pair(i, PHV::FieldUse(WRITE)),
                        writeAccess);
                rv.push_back(info);
            } else {
                rv[rv.size() - 1].addAccess(std::make_pair(i, PHV::FieldUse(WRITE)), writeAccess);
            }
        }
    }
    LOG5("\tNumber of alloc slices sorted by liveness: " << rv.size());
    for (auto& info : rv) {
        std::stringstream ss;
        ss << "\t\t" << info.field << " : [" << info.minStage.first <<
             info.minStage.second << ", " << info.maxStage.first << info.maxStage.second <<
             "].  Units: ";
        for (const auto* u : info.units)
            ss << DBPrint::Brief << u << " ";
        LOG5(ss.str());
    }
    if (!validateLiveness(rv)) return boost::none;
    return rv;
}

bool DarkLiveRange::ignoreReachCondition(
        const OrderedFieldInfo& currentField,
        const OrderedFieldInfo& lastField,
        const ordered_set<std::pair<const IR::BFN::Unit*, const IR::BFN::Unit*>>& conflicts) const {
    bool rv = true;
    for (auto& conflict : conflicts) {
        const auto* t1 = conflict.first->to<IR::MAU::Table>();
        const auto* t2 = conflict.second->to<IR::MAU::Table>();
        if (!t1 || !t2 || t1 != t2) return false;
        // Here both the conflicting units are the same.
        LOG6("\t\t\t\tt1: " << t1->name << ", " << t2->name);
        bool currentAccessAtTable = livemap.hasAccess(currentField.field.field(), dg.min_stage(t1),
                WRITE);
        bool lastAccessAtTable = livemap.hasAccess(lastField.field.field(), dg.min_stage(t1), READ);
        LOG6("\t\t\t\t  current: " << currentAccessAtTable << ", lastAccessAtTable: " <<
                lastAccessAtTable);
        // FIXME: Determine right condition
        if (!currentAccessAtTable || !lastAccessAtTable)
            rv = false;
    }
    return rv;
}

bool DarkLiveRange::isGroupDominatorEarlierThanFirstUseOfCurrentField(
        const OrderedFieldInfo& currentField,
        const ordered_set<const IR::BFN::Unit*>& doms,
        const IR::MAU::Table* groupDominator) const {
    bool singleDom = (doms.size() == 1);
    for (const auto* u : doms) {
        // If there is only one dominator in the list of trimmed dominators, check that the
        // only strict dominator in there is the same as the group dominator. If it is, then it is
        // fine for the initialization point to be at the group dominator.
        const auto* t = u->to<IR::MAU::Table>();
        if (!t) return false;
        LOG5("\t\t\t\t  Group dominator: " << groupDominator->name << ", dom: " << t->name);
        if (singleDom && t == groupDominator) {
            LOG5("\t\t\t\tOnly strict dominator same as group dominator. Initialization ok.");
            return true;
        }
        if (dg.min_stage(groupDominator) > dg.min_stage(t)) {
            LOG5("\t\t\t\tGroup dominator happens in same logical stage or later (stage " <<
                 dg.min_stage(groupDominator) << ") than use table " << t->name << " (" <<
                 dg.min_stage(t) << ")");
            return false;
        }
    }
    // If group dominator stage is the same as the trimmed dominator, then we need to make sure
    // that the trimmed dominator is a read (and not a write) because we would be inserting an
    // initialization at the group dominator table. The check here makes sure that the group
    // dominator will occur earlier than the min stage for the current field, which effectively
    // implements the invariant above.
    // XXX(Deep): This is too conservative. This check is necessary only if we actually need to
    // initialize the field.
    if (currentField.minStage.first == dg.min_stage(groupDominator) &&
            currentField.minStage.second == PHV::FieldUse(PHV::FieldUse::READ)) {
        LOG5("\t\t\t\tInitialization at group dominator will happen later than the first "
                "use of currentField " << currentField.field);
        return false;
    }

    // All the strict dominators are in later stages compared to the group dominator.
    return true;
}

boost::optional<PHV::DarkInitMap> DarkLiveRange::findInitializationNodes(
        const PHV::ContainerGroup& group,
        const PHV::Container& c,
        const ordered_set<PHV::AllocSlice>& fields,
        const PHV::Transaction& alloc) const {
    // If one of the fields has been marked as "do not init to dark" (primarily because we did not
    // find dominator nodes for use nodes of those fields), then return false early.
    for (const auto& sl : fields)
        if (doNotInitToDark.count(sl.field()))
            return boost::none;
    // iterate over stages. gather the stages where each of the slices are alive
    // for initialization, we move pairwise between fields in the container (in increasing order of
    // liveness, where increasing means use in larger stage numbers). find the initialization point
    // for the live-later field and then move to the next pair. A field may appear multiple times
    // for initialization in this scheme (unlike metadata initialization).
    // question: what if multiple slices are alive at the same stage? it can happen when dark
    // overlay mixes with parser overlay and metadata overlay due to live range shrinking.
    auto fieldsInOrder = produceFieldsInOrder(fields);
    if (!fieldsInOrder) return boost::none;

    const OrderedFieldInfo* lastField = nullptr;
    unsigned idx = 0;
    PHV::DarkInitMap rv;
    PHV::DarkInitEntry* firstDarkInitEntry = nullptr;
    for (const auto& info : *fieldsInOrder) {
        LOG2("\tTrying to allocate field " << idx << ": " << info.field << " in container " <<
                c);
        LOG2("\t\tRelevant units:");
        for (const auto* u : info.units) {
            std::stringstream ss;
            ss << "\t\t  " << DBPrint::Brief << u;
            if (const auto* t = u->to<IR::MAU::Table>())
                ss << " (Stage " << dg.min_stage(t) << ")";
            LOG2(ss.str());
        }
        if (idx == 0) {
            LOG2("\t  Field with earliest live range: " << info.field << " already allocated "
                 "to " << c);
            lastField = &info;
            PHV::AllocSlice dest(info.field);
            dest.setLiveness(info.minStage, info.maxStage);
            firstDarkInitEntry = new PHV::DarkInitEntry(dest);
            firstDarkInitEntry->setNop();
            LOG3("\t\t\tCreating dark init primitive (not pushed): " << *firstDarkInitEntry);
            ++idx;
            continue;
        }
        BUG_CHECK(lastField && lastField->field != info.field,
                  "DarkLiveRange should never see the same field " "consecutively.");
        LOG2("\t  Need to move field: " << info.field << " into container " << c <<
             ", and move last field " << lastField->field << " into a dark container");
        LOG2("\t\tLive range: (" << info.minStage.first << info.minStage.second << ", " <<
             info.maxStage.first << info.maxStage.second << ")");
        // Check the uses of fields initialized so far in this container with the uses relevant to
        // this particular field.
        unsigned idx_g = 0;
        for (const auto& g_info : *fieldsInOrder) {
            if (idx_g++ == idx) break;
            if (phv.isFieldMutex(info.field.field(), g_info.field.field())) {
                LOG2("\t\tExclusive with field " << (idx_g - 1) << ": "<< g_info.field);
                // FIXME: How does this effect the return vector.
                continue;
            }
            LOG2("\t\tNon-exclusive with field " << g_info.field);
            LOG2("\t\t  Can all defuses of " << info.field << " reach the defuses of " <<
                 g_info.field << "?");
            auto reach_condition = canFUnitsReachGUnits(info.units, g_info.units,
                    domTree.getFlowGraph());
            if (reach_condition.size() > 0) {
                bool ignoreReach = ignoreReachCondition(info, g_info, reach_condition);
                if (!ignoreReach) {
                    LOG2("\t\t  Yes. Therefore, move to dark not possible.");
                    return boost::none;
                }
            }
            LOG2("\t\t\tNo. Trying to find an initialization node.");
        }

        // Populate the list of dominators for the current live range slice of the field.
        ordered_set<const IR::BFN::Unit*> f_nodes;
        f_nodes.insert(info.units.begin(), info.units.end());
        unsigned idx_2 = 0;
        for (const auto& info_2 : *fieldsInOrder) {
            if (idx_2++ <= idx) continue;
            LOG2("\t\t\tNow adding " << info_2.units.size() << " units for " << info_2.field <<
                 " : (" << info_2.minStage.first << info_2.minStage.second << ", " <<
                 info_2.maxStage.first << info_2.maxStage.second << ")");
            for (auto* u : info_2.units)
                LOG2("\t\t\t  " << DBPrint::Brief << u);
            f_nodes.insert(info_2.units.begin(), info_2.units.end());
        }
        bool onlyDeparserUse = false;
        if (f_nodes.size() == 1) {
            const auto* u = *(f_nodes.begin());
            if (u->is<IR::BFN::Deparser>()) {
                onlyDeparserUse = true;
                LOG2("\t\t  Initialize in last stage always_init VLIW block.");
            }
        }
        if (!onlyDeparserUse) {
            LOG2("\t\tTrimming the list of use nodes in the set of defuses.");
            getTrimmedDominators(f_nodes, domTree);
            if (hasParserUse(f_nodes)) {
                LOG2("\t\t  Defuse units of field " << info.field << " includes the parser. "
                        "Cannot find initialization point.");
                return boost::none;
            }
            if (LOGGING(2)) {
                for (const auto* u : f_nodes) {
                    if (u->is<IR::BFN::Deparser>()) {
                        LOG2("\t\t\t" << DBPrint::Brief << u);
                    } else {
                        LOG2("\t\t\t" << DBPrint::Brief << u << " (stage " <<
                             dg.min_stage(u->to<IR::MAU::Table>()) << ")");
                    }
                }
            }
        }
        bool moveCurrentToDark = mustMoveToDark(*lastField, *fieldsInOrder);
        if (moveCurrentToDark)
            LOG2("\t\tMove the previous field " << lastField->field << " into a dark container "
                 "after stage " << lastField->maxStage.first << lastField->maxStage.second);
        else
            LOG2("\t\tNo need to move field " << lastField->field << " into a dark container");
        bool initializeCurrentField = onlyDeparserUse;
        if (!onlyDeparserUse)
            initializeCurrentField = mustInitializeCurrentField(info, f_nodes);
        if (initializeCurrentField)
            LOG2("\t\tMust initialize container " << c << " for current field " << info.field <<
                 " after stage " << lastField->maxStage.first << lastField->maxStage.second);
        else
            LOG2("\t\tNo need to initialize container " << c << " for current field " <<
                 info.field);

        bool initializeFromDark = mustInitializeFromDarkContainer(info, *fieldsInOrder);
        if (initializeFromDark)
            LOG2("\t\tMust initialize container " << c << " for current field " << info.field <<
                 " from dark container after stage " << lastField->maxStage.first <<
                 lastField->maxStage.second);
        if (initializeCurrentField && !initializeFromDark)
            LOG2("\t\tMust initialize container " << c << " for current field " << info.field <<
                 " using 0 after stage " << lastField->maxStage.first <<
                 lastField->maxStage.second);

        if (onlyDeparserUse && initializeCurrentField && initializeFromDark) {
            auto init = generateInitForLastStageAlwaysInit(info, rv);
            if (!init) return boost::none;
            rv.push_back(*init);
            continue;
        } else if (onlyDeparserUse) {
            // FIXME
            LOG2("\t\tCurrently do not support initialization from 0 in always init block.");
            return boost::none;
        }

        const IR::MAU::Table* groupDominator = getGroupDominator(info.field.field(), f_nodes,
                info.field.field()->gress);
        if (groupDominator == nullptr) {
            LOG2("\t\tCannot find group dominator to write " << lastField->field << " into a "
                 "dark container.");
            return boost::none;
        }

        while (groupDominator != nullptr) {
            // Check that the group dominator can be used to add the move instruction without
            // lengthening the dependence chain.
            bool groupDominatorAfterLastUsePrevField =
                (dg.min_stage(groupDominator) > lastField->maxStage.first) ||
                ((dg.min_stage(groupDominator) == lastField->maxStage.first) &&
                 lastField->maxStage.second == PHV::FieldUse(READ));
            bool groupDominatorBeforeFirstUseCurrentField =
                isGroupDominatorEarlierThanFirstUseOfCurrentField(info, f_nodes, groupDominator);

            if (!groupDominatorAfterLastUsePrevField) {
                LOG2("\t\tCannot find initialization point for previous field " << lastField->field
                     << " because group dominator's stage (" << dg.min_stage(groupDominator) <<
                     ") is before the last use of the previous field (" << lastField->maxStage.first
                     << lastField->maxStage.second << ")");
                return boost::none;
            }


            // Check that the initialization point cannot reach the units using the last field.
            const IR::BFN::Unit* groupDominatorUnit = groupDominator->to<IR::BFN::Unit>();
            auto reach_condition = canFUnitsReachGUnits({ groupDominatorUnit }, lastField->units,
                    domTree.getFlowGraph());
            if (reach_condition.size() > 0) {
                bool ignoreReach = ignoreReachCondition(info, *lastField, reach_condition);
                if (!ignoreReach) {
                    LOG2("\t\tCannot find initialization point because group dominator can reach "
                         "one of the uses of the last field " << lastField->field);
                    return boost::none;
                }
            }
            // Check that units using the last field can reach the initialization point.
            bool goToNextDominator = false;
            for (auto* u : lastField->units) {
                auto reach_condition = canFUnitsReachGUnits({ u }, { groupDominatorUnit },
                        domTree.getFlowGraph());
                if (reach_condition.size() == 0) {
                    LOG2("\t\tUse unit " << DBPrint::Brief << u << " of previous field " <<
                            lastField->field << " cannot reach initialization point " <<
                            DBPrint::Brief << groupDominatorUnit);
                    goToNextDominator = true;
                }
            }

            // If we are initializing the current field, then make sure that the initialization
            // point does not cause a lengthening of the critical path.
            if (initializeCurrentField) {
                for (auto* u : f_nodes) {
                    const auto* t = u->to<IR::MAU::Table>();
                    if (!t) continue;
                    if (increasesDependenceCriticalPath(t, groupDominator)) {
                        LOG2("\t\tCannot initialize at " << groupDominator->name << " because "
                             "it would increase the critical path through the dependency graph "
                             "(via use at " << DBPrint::Brief << u);
                        goToNextDominator = true;
                    }
                }
            }

            if (doNotInitTables.count(groupDominator)) {
                LOG2("\t\tTable " << groupDominator->name << " requires more than one stage."
                     " Therefore, we will not initialize at that table.");
                goToNextDominator = true;
            }

            // Only find initialization point if this group dominator is the right candidate.
            if (!goToNextDominator) {
                LOG2("\t\tTrying to initialize at table " << groupDominator->name << " (Stage " <<
                        dg.min_stage(groupDominator) << ")");
                auto darkInitPoints = getInitPointsForTable(group, c, groupDominator, *lastField,
                        info, rv, moveCurrentToDark, initializeCurrentField, initializeFromDark,
                        alloc);
                if (!groupDominatorBeforeFirstUseCurrentField) {
                    // TODO: Relax by accounting for valid uses directly from dark containers.
                    LOG3("\t\tCannot initialize current field before its first use.");
                } else if (!darkInitPoints) {
                    LOG3("\t\tDid not get any initialization points; need to move up in the flow "
                            "graph.");
                } else if (darkInitPoints) {
                    // Found initializations. Now set up the return vector accordingly.
                    LOG3("\t\t" << darkInitPoints->size() << " initializations found");
                    for (auto init : *darkInitPoints) {
                        LOG3("\t\t  Adding to return vector: " << init);
                        rv.push_back(init);
                    }
                    break;
                }
            }
            auto newGroupDominator = domTree.getNonGatewayImmediateDominator(groupDominator,
                    groupDominator->thread());
            if (!newGroupDominator) {
                LOG2("\t\tCould not find an initialization points for previous field " <<
                        lastField->field);
                return boost::none;
            } else if (*newGroupDominator == groupDominator) {
                LOG2("\t\tReached the beginning of the flow graph. Cannot initialize previous "
                     "field " << lastField->field);
                return boost::none;
            } else {
                groupDominator = *newGroupDominator;
                LOG2("\t\tSetting new group dominator to " << groupDominator);
            }
        }

        if (idx == 1 && firstDarkInitEntry != nullptr) {
            LOG3("Need to push the first dark init primitive corresponding to " <<
                    *firstDarkInitEntry);
            if (moveCurrentToDark) {
                LOG3("  Live range must extend to the initialization point");
                firstDarkInitEntry->setDestinationMaxLiveness(
                        std::make_pair(dg.min_stage(groupDominator), PHV::FieldUse(READ)));
                LOG3("  New dark primitive: " << *firstDarkInitEntry);
                rv.insert(rv.begin(), *firstDarkInitEntry);
            }
        }

        // Add check here for critical path increase due to this movement.

        // Arrive at a common node for all these units to initialize the container c to 0, and to
        // move the existing contents of container c to a dark container.
        ++idx;
        lastField = &info;
    }
    return rv;
}

// Difference between LiveRangeShrinking and DarkOverlay is that live range shrinking initializes
// the current field, whereas DarkOverlay moves the previous field to dark and brings the current
// field into a normal container (2 initializations potentially).
boost::optional<PHV::DarkInitMap> DarkLiveRange::getInitPointsForTable(
        const PHV::ContainerGroup& group,
        const PHV::Container& c,
        const IR::MAU::Table* t,
        const OrderedFieldInfo& lastField,
        const OrderedFieldInfo& currentField,
        PHV::DarkInitMap& initMap,
        bool moveLastFieldToDark,
        bool initializeCurrentField,
        bool initializeFromDark,
        const PHV::Transaction& alloc) const {
    PHV::DarkInitMap rv;

    // If the last field is to be moved into a dark container, make sure that the uses of that slice
    // (for that live range) is not mutually exclusive with the table t, where the move is supposed
    // to happen.
    bool lastMutexSatisfied = true;
    if (moveLastFieldToDark)
        lastMutexSatisfied = mutexSatisfied(lastField, t);

    // If the current field is to be initialized, make sure that the uses of that slice (for the
    // corresponding live range) is not mutually exclusive with the table t, where the
    // initialization is to be performed.
    bool currentMutexSatisfied = true;
    if (initializeCurrentField)
        currentMutexSatisfied = mutexSatisfied(currentField, t);

    if (!lastMutexSatisfied || !currentMutexSatisfied) return boost::none;

    PHV::DarkInitEntry* prevSlice = nullptr;

    // Check if moving lastField to dark container (if required) is possible.
    if (moveLastFieldToDark) {
        auto lastFieldInit = getInitForLastFieldToDark(c, group, t, lastField, alloc);
        if (!lastFieldInit) return boost::none;
        LOG3("\t\t\tA. Creating dark init primitive for moving last field to dark : " <<
             *lastFieldInit);
        rv.push_back(*lastFieldInit);
        auto srcSlice = lastFieldInit->getSourceSlice();
        if (srcSlice) {
            if (initMap.size() > 0) {
                PHV::DarkInitEntry* lastSlice = &initMap[initMap.size() - 1];
                PHV::StageAndAccess newLatestStage = std::make_pair(dg.min_stage(t),
                        PHV::FieldUse(READ));
                lastSlice->setDestinationLatestLiveness(newLatestStage);
                LOG3("\t\t\t  Extending liveness of " << *lastSlice << " to " <<
                     newLatestStage.first << newLatestStage.second);
            }
        }
    } else {
        // Reset the liveness for this slice based on the initialization point.
        if (initMap.size() > 0) {
            prevSlice = &initMap[initMap.size() - 1];
        } else {
            PHV::AllocSlice dest(lastField.field);
            dest.setLiveness(lastField.minStage, std::make_pair(dg.min_stage(t),
                        PHV::FieldUse(READ)));
            PHV::DarkInitEntry noInitDark(dest);
            noInitDark.setNop();
            LOG3("\t\t\tB. Creating dark init primitive: " << noInitDark);
            rv.push_back(noInitDark);
        }
    }

    // Check if there is an allocation for field currentField. If there is, then it must be in a
    // dark container, which can then be moved back into this container (c).
    boost::optional<PHV::DarkInitEntry> currentFieldInit;
    if (initializeCurrentField && initializeFromDark)
        currentFieldInit = getInitForCurrentFieldFromDark(c, t, currentField, initMap, alloc);
    else if (initializeCurrentField && !initializeFromDark)
        currentFieldInit = getInitForCurrentFieldWithZero(c, t, currentField, alloc);
    if (!currentFieldInit) return boost::none;
    rv.push_back(*currentFieldInit);

    if (prevSlice != nullptr) {
        PHV::StageAndAccess newLatestStage = std::make_pair(dg.min_stage(t), PHV::FieldUse(READ));
        prevSlice->setDestinationLatestLiveness(newLatestStage);
    }

    return rv;
}

boost::optional<PHV::Allocation::ActionSet> DarkLiveRange::getInitActions(
        const PHV::Container& c,
        const OrderedFieldInfo& field,
        const IR::MAU::Table* t,
        const PHV::Transaction& alloc) const {
    PHV::Allocation::ActionSet moveActions;
    const PHV::Field* f = field.field.field();
    for (const auto* act : tablesToActions.getActionsForTable(t)) {
        if (cannotInitInAction(c, act, alloc)) {
            LOG2("\t\t\t  Cannot init " << field.field << " in do not init action " << act->name);
            return boost::none;
        }
        // If field is already written in this action, do not initialize here.
        if (actionConstraints.written_in(field.field, act)) continue;
        auto& actionReads = actionConstraints.actionReadsSlices(act);
        auto actionWrites = actionConstraints.actionWritesSlices(act);
        auto inits = alloc.getMetadataInits(act);
        for (const auto* g : inits) {
            LOG5("\t\t\t  Noting down initialization of " << g->name << " for action " <<
                 act->name);
            actionWrites.insert(PHV::FieldSlice(g, StartLen(0, g->size)));
        }
        // If any of the fields read or written by the action are mutually exclusive with the field
        // to be initialized, then do not initialize the field in this table.
        for (const auto& g : actionReads) {
            if (phv.isFieldMutex(f, g.field())) {
                LOG5("\t\t\t\tIgnoring table " << t->name << " as a node for moving " <<
                     field.field << " because it is mutually exclusive with slice " <<
                     g << " read by action " << act->name);
                return boost::none;
            }
        }
        for (const auto& g : actionWrites) {
            if (phv.isFieldMutex(f, g.field())) {
                LOG5("\t\t\t\tIgnoring table " << t->name << " as a node for moving " <<
                     field.field << " because it is mutually exclusive with slice " << g <<
                     " written by action " << act->name);
                return boost::none;
            }
        }
        moveActions.insert(act);
    }
    if (moveActions.size() > 0) {
        LOG5("\t\t\t\tInitialization actions:");
        for (const auto* act : moveActions)
            LOG5("\t\t\t\t  " << act->name);
    }
    return moveActions;
}

boost::optional<PHV::DarkInitEntry> DarkLiveRange::getInitForLastFieldToDark(
        const PHV::Container& c,
        const PHV::ContainerGroup& group,
        const IR::MAU::Table* t,
        const OrderedFieldInfo& field,
        const PHV::Transaction& alloc) const {
    // Find out all the actions in table t, where we need to insert moves into the dark container.
    // DXm[a...b] = Xn[a...b]
    auto moveActions = getInitActions(c, field, t, alloc);
    if (!moveActions) return boost::none;

    auto darkCandidates = group.getAllContainersOfKind(PHV::Kind::dark);
    LOG5("\t\t\t\tOverlay container: " << c);
    for (auto dark : darkCandidates)
        LOG5("\t\t\t\tCandidate dark container: " << dark);

    // Get best dark container to move the field into.
    const PHV::Container darkCandidate = getBestDarkContainer(darkCandidates, field, alloc);
    if (darkCandidate == PHV::Container()) {
        LOG4("\t\t\t  Could not find a dark container to move field " << field.field << " into");
        return boost::none;
    }
    LOG5("\t\t\t  Best container for dark: " << darkCandidate);

    PHV::AllocSlice srcSlice(field.field);
    srcSlice.setLiveness(field.minStage, std::make_pair(dg.min_stage(t), PHV::FieldUse(READ)));
    LOG5("\t\t\t\tCreated source slice " << srcSlice << " live between [" << field.minStage.first <<
         field.minStage.second << ", " << dg.min_stage(t) << PHV::FieldUse(READ) << "]");

    PHV::AllocSlice dstSlice(field.field.field(), darkCandidate, field.field.field_slice(),
            field.field.container_slice());
    // Set maximum liveness for this slice.
    dstSlice.setLiveness(std::make_pair(dg.min_stage(t), PHV::FieldUse(WRITE)),
            std::make_pair(dg.max_min_stage, PHV::FieldUse(WRITE)));
    LOG5("\t\t\t\tCreated destination slice " << dstSlice << " live between [" << dg.min_stage(t) <<
         PHV::FieldUse(WRITE) << ", " << dg.max_min_stage << PHV::FieldUse(WRITE) << "]");
    PHV::DarkInitEntry rv(dstSlice, srcSlice, *moveActions);
    return rv;
}

boost::optional<PHV::DarkInitEntry> DarkLiveRange::getInitForCurrentFieldWithZero(
        const PHV::Container& c,
        const IR::MAU::Table* t,
        const OrderedFieldInfo& field,
        const PHV::Transaction& alloc) const {
    // TODO:
    // Check if any pack conflicts are violated.
    // Initializing at table t requires that there is a dependence now from the previous uses of
    // prevField to table t.

    // TODO: Check if field is always written first on all paths.

    // Find out all actions in table t, where we need to initialize @field to 0 in container @c.
    // c[a...b] = 0
    auto initActions = getInitActions(c, field, t, alloc);
    if (!initActions) return boost::none;

    PHV::AllocSlice dstSlice(field.field);
    dstSlice.setLiveness(std::make_pair(dg.min_stage(t), PHV::FieldUse(WRITE)), field.maxStage);
    LOG5("\t\t\t\tCreated destination slice " << dstSlice << " live between [" << dg.min_stage(t) <<
            PHV::FieldUse(WRITE) << ", " << field.maxStage.first << field.maxStage.second << "]");
    PHV::DarkInitEntry rv(dstSlice, *initActions);
    return rv;
}

boost::optional<PHV::DarkInitEntry>
DarkLiveRange::generateInitForLastStageAlwaysInit(
        const OrderedFieldInfo& field,
        const PHV::DarkInitMap& darkInitMap) const {
    PHV::AllocSlice dstSlice(field.field);
    dstSlice.setLiveness(std::make_pair(livemap.getDeparserStageValue() - 1, PHV::FieldUse(WRITE)),
            field.maxStage);
    PHV::DarkInitEntry rv(dstSlice);
    for (auto it = darkInitMap.rbegin(); it != darkInitMap.rend(); ++it) {
        PHV::AllocSlice dest = it->getDestinationSlice();
        bool found = (dest.field() == field.field.field() &&
                      dest.field_slice() == field.field.field_slice() &&
                      dest.container_slice() == field.field.container_slice() &&
                      dest.width() == field.field.width());
        if (found) {
            rv.addSource(dest);
            rv.setLastStageAlwaysInit();
            LOG3("\t\t\tAdding initialization from dark in last stage: " << rv);
            return rv;
        }
    }
    BUG("Did not find allocation for slice %1% in a dark container", field.field);
    return boost::none;
}


boost::optional<PHV::DarkInitEntry> DarkLiveRange::getInitForCurrentFieldFromDark(
        const PHV::Container& c,
        const IR::MAU::Table* t,
        const OrderedFieldInfo& field,
        PHV::DarkInitMap& initMap,
        const PHV::Transaction& alloc) const {
    auto initActions = getInitActions(c, field, t, alloc);
    if (!initActions) return boost::none;
    // Start from the last element in the initMap vector, and find the latest AllocSlice that
    // matches the field slice for the current field.
    PHV::AllocSlice dstSlice(field.field);
    dstSlice.setLiveness(std::make_pair(dg.min_stage(t), PHV::FieldUse(WRITE)), field.maxStage);
    PHV::DarkInitEntry rv(dstSlice, *initActions);
    for (auto it = initMap.rbegin(); it != initMap.rend(); ++it) {
        PHV::AllocSlice dest = it->getDestinationSlice();
        bool found = (dest.field() == field.field.field() &&
                dest.field_slice() == field.field.field_slice() &&
                dest.container_slice() == field.field.container_slice() &&
                dest.width() == field.field.width());
        if (found) {
            PHV::StageAndAccess newReadStage = std::make_pair(dg.min_stage(t), PHV::FieldUse(READ));
            PHV::StageAndAccess newWriteStage = std::make_pair(dg.min_stage(t),
                    PHV::FieldUse(WRITE));
            // Current initialization point becomes start of liveness of new slice and end of
            // liveness of source slice.
            it->setDestinationLatestLiveness(newReadStage);
            rv.setDestinationEarliestLiveness(newWriteStage);
            dest.setLatestLiveness(newReadStage);
            rv.addSource(dest);
            LOG3("\t\t\tAdding initialization from dark: " << rv);
            return rv;
        }
    }
    BUG("Did not find allocation for slice %1% in a dark container", field.field);
    return boost::none;
}

const PHV::Container DarkLiveRange::getBestDarkContainer(
        const ordered_set<PHV::Container>& darkContainers,
        const OrderedFieldInfo& nextField,
        const PHV::Transaction& alloc) const {
    // PHV::Container bestContainer;
    // int bestScore = -1;
    // This is the number of stages we see in the table dependency graph. The score is this number
    // minus the number of stages allocated already to the dark container. Smaller scores are
    // better.
    // const unsigned maxStages = dg.max_min_stage + 1;
    auto fieldGress = nextField.field.field()->gress;
    // Get the best dark container for the purpose.
    for (auto c : darkContainers) {
        auto containerGress = alloc.gress(c);
        // Change to checking if dark containers are available at the particular stage range.
        if (containerGress) continue;
        auto parserGroupGress = alloc.parserGroupGress(c);
        auto deparserGroupGress = alloc.deparserGroupGress(c);
        bool containerGressOk =
            (!containerGress) || (containerGress && *containerGress == fieldGress);
        bool parserGressOk =
            (!parserGroupGress) || (parserGroupGress && *parserGroupGress == fieldGress);
        bool deparserGressOk =
            (!deparserGroupGress) || (deparserGroupGress && *deparserGroupGress == fieldGress);
        if (containerGressOk && parserGressOk && deparserGressOk) return c;
    }
    return PHV::Container();
}

const IR::MAU::Table* DarkLiveRange::getGroupDominator(
        const PHV::Field* f,
        const ordered_set<const IR::BFN::Unit*>& f_units,
        gress_t gress) const {
    ordered_map<const IR::MAU::Table*, const IR::BFN::Unit*> tablesToUnits;
    for (const auto* u : f_units) {
        if (u->is<IR::BFN::Deparser>()) {
            auto t = domTree.getNonGatewayImmediateDominator(nullptr, gress);
            if (!t) {
                LOG2("\t\t\tNo table dominators for use unit: " << DBPrint::Brief << u);
                return nullptr;
            }
            tablesToUnits[*t] = (*t)->to<IR::BFN::Unit>();
            continue;
        }
        const auto* t = u->to<IR::MAU::Table>();
        BUG_CHECK(t, "Non-deparser non-table use found.");
        tablesToUnits[t] = u;
    }
    if (tablesToUnits.size() == 0) return nullptr;
    ordered_set<const IR::MAU::Table*> tables;
    if (tablesToUnits.size() == 1) {
        auto& kv = *(tablesToUnits.begin());
        tables.insert(kv.first);
        if (defuse.hasUseAt(f, kv.second)) return domTree.getNonGatewayGroupDominator(tables);
        return kv.first;
    }
    for (auto& kv : tablesToUnits) tables.insert(kv.first);
    return domTree.getNonGatewayGroupDominator(tables);
}

bool DarkLiveRange::mustMoveToDark(
        const OrderedFieldInfo& field,
        const OrderedFieldSummary& fieldsInOrder) const {
    bool foundOriginalFieldInfo = false;
    for (auto& info : fieldsInOrder) {
        if (info == field) {
            foundOriginalFieldInfo = true;
            continue;
        }
        if (!foundOriginalFieldInfo) continue;
        // These are field slices after @field.
        if (info.field == field.field)
            return true;
    }
    return false;
}

bool DarkLiveRange::mustInitializeCurrentField(
        const OrderedFieldInfo& field,
        const ordered_set<const IR::BFN::Unit*>& fieldUses) const {
    ordered_set<const IR::MAU::Table*> tableUses;
    for (const auto* u : fieldUses) {
        if (u->is<IR::BFN::Deparser>()) continue;
        const IR::MAU::Table* t = u->to<IR::MAU::Table>();
        BUG_CHECK(t, "Field use unit %1% cannot be a non-table entity", u);
        tableUses.insert(t);
    }
    for (const auto* t : tableUses) {
        for (const auto* act : tablesToActions.getActionsForTable(t)) {
            // FIXME: Add metadata initialization points here.
            if (!actionConstraints.written_in(field.field, act)) {
                LOG3("\t\t  " << field.field << " not written in action " << act->name <<
                     " in table " << t->name);
                return true;
            } else {
                LOG3("\t\t  " << field.field << " is written in action " << act->name <<
                     " in table " << t->name);
            }
        }
    }
    return false;
}

bool DarkLiveRange::mustInitializeFromDarkContainer(
        const OrderedFieldInfo& field,
        const OrderedFieldSummary& fieldsInOrder) const {
    // If the slice represented by @field is found earlier in @fieldsInOrder, then it means that
    // field was already live earlier in the pipeline, and therefore, it will have been moved to a
    // dark container earlier.
    bool foundFieldUseBeforeOriginalInfo = false;
    for (auto& info : fieldsInOrder) {
        if (info == field) return foundFieldUseBeforeOriginalInfo;
        if (info.field == field.field) foundFieldUseBeforeOriginalInfo = true;
    }
    BUG("We should never reach this point. How did we pass a slice info object not within "
        "fieldsInOrder?");
    return false;
}

bool DarkLiveRange::cannotInitInAction(
        const PHV::Container& c,
        const IR::MAU::Action* action,
        const PHV::Transaction& alloc) const {
    // If the PHVs in this action are already unaligned, then we cannot add initialization in this
    // action.
    if (actionConstraints.cannot_initialize(c, action, alloc)) {
        LOG4("\t\t\tAction analysis indicates a pre-existing write using PHV/action data/non-zero "
             "const to container " << c << " in " << action->name << ". Cannot initialize here.");
        return true;
    }
    return doNotInitActions.count(action);
}

bool DarkLiveRange::mutexSatisfied(const OrderedFieldInfo& info, const IR::MAU::Table* t) const {
    ordered_set<const IR::MAU::Table*> tableUses;
    for (const auto* u : info.units)
        if (u->is<IR::MAU::Table>())
            tableUses.insert(u->to<IR::MAU::Table>());
    for (const auto* tbl : tableUses) {
        if (tableMutex(t, tbl)) {
            LOG4("\t\t\tIgnoring table " << t->name << " beause it is mutually exclusive with "
                 "use table " << tbl->name << " of field " << info.field);
            return false;
        }
    }
    return true;
}

cstring DarkLiveRange::DarkLiveRangeMap::printDarkLiveRanges() const {
    std::stringstream ss;
    auto numStages = DEPARSER;
    const int PARSER = -1;
    ss << std::endl << "Uses for fields to determine dark overlay potential:" << std::endl;
    std::vector<std::string> headers;
    headers.push_back("Field");
    headers.push_back("Bit Size");
    headers.push_back("P");
    for (int i = 0; i < numStages; i++)
        headers.push_back(std::to_string(i));
    headers.push_back("D");
    TablePrinter tp(ss, headers, TablePrinter::Align::LEFT);
    for (auto entry : livemap) {
        std::vector<std::string> row;
        row.push_back(std::string(entry.first->name));
        row.push_back(std::to_string(entry.first->size));
        PHV::FieldUse use_type;
        if (entry.second.count(std::make_pair(PARSER, PHV::FieldUse(WRITE))))
            use_type |= PHV::FieldUse(WRITE);
        if (entry.second.count(std::make_pair(PARSER, PHV::FieldUse(READ))))
            use_type |= PHV::FieldUse(READ);
        row.push_back(std::string(use_type.toString()));
        for (int i = 0; i <= DEPARSER; i++) {
            PHV::FieldUse use_type;
            if (entry.second.count(std::make_pair(i, PHV::FieldUse(READ))))
                use_type |= PHV::FieldUse(READ);
            if (entry.second.count(std::make_pair(i, PHV::FieldUse(WRITE))))
                use_type |= PHV::FieldUse(WRITE);
            row.push_back(std::string(use_type.toString()));
        }
        tp.addRow(row);
    }
    tp.print();
    return ss.str();
}

bool DarkOverlay::suitableForDarkOverlay(const PHV::AllocSlice& slice) const {
    if (slice.field()->no_pack() && (slice.container().size() - slice.width() > 7))
        return false;
    return true;
}

DarkOverlay::DarkOverlay(
        PhvInfo& p,
        const ClotInfo& c,
        const DependencyGraph& g,
        FieldDefUse& f,
        const PHV::Pragmas& pragmas,
        const PhvUse& u,
        const ActionPhvConstraints& actions,
        const BuildDominatorTree& d,
        const MapTablesToActions& m,
        const MauBacktracker& a)
    : initNode(p, c, g, f, pragmas, u, d, actions, a, tableMutex, m) {
    addPasses({
        &tableMutex,
        &initNode
    });
}
