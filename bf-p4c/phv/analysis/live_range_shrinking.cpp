#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/phv/utils/liverange_opti_utils.h"

Visitor::profile_t FindInitializationNode::init_apply(const IR::Node* root) {
    LOG3("Printing dependency graph");
    LOG3(dg);
    maxStages = -1;
    doNotInitActions.clear();
    doNotInitActions.clear();
    return Inspector::init_apply(root);
}

bool FindInitializationNode::preorder(const IR::MAU::Table* tbl) {
    int stage = dg.min_stage(tbl);
    if (stage > maxStages) maxStages = stage;
    return true;
}

bool FindInitializationNode::preorder(const IR::MAU::Action* act) {
    GetHashDistReqs ghdr;
    act->apply(ghdr);
    if (ghdr.is_hash_dist_needed()) {
        LOG3("\tCannot initialize at action " << act->name << " because it requires "
             "the hash distribution unit.");
        doNotInitActions.insert(act);
    }
    return true;
}

bool FindInitializationNode::isUninitializedDef(
        const PHV::Field* f,
        const FieldDefUse::locpair& def) const {
    if (!defuse.hasUninitializedRead(f->id)) return false;
    if (def.second->is<ImplicitParserInit>()) return true;
    return false;
}

bool FindInitializationNode::summarizeUseDefs(
        const PHV::Field* f,
        const ordered_set<const IR::BFN::Unit*>& initPoints,
        ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, unsigned>>& units,
        ordered_set<const IR::BFN::Unit*>& f_dominators) const {
    // Note all units where field f is defined.
    for (auto& def : defuse.getAllDefs(f->id)) {
        if (isUninitializedDef(f, def)) {
            LOG5("\t\t\tSkipping because uninitialized read at " << DBPrint::Brief <<
                    def.first);
            continue;
        }
        units[f][def.first] |= MetadataLiveRange::WRITE;
        LOG5("\t\t  Adding write for unit " << DBPrint::Brief << def.first);
        // Write is its own dominator, so insert this node into f_dominators.
        f_dominators.insert(def.first);
        LOG3("\t\t\tAdding dominator " << DBPrint::Brief << def.first);
    }

    for (auto* u : initPoints) {
        units[f][u] |= MetadataLiveRange::WRITE;
        LOG5("\t\t  Adding write for initialization unit " << DBPrint::Brief << u);
        f_dominators.insert(u);
        LOG3("\t\t\tAdding dominator " << DBPrint::Brief << u);
    }

    // Note all units where f is used.
    for (auto& use : defuse.getAllUses(f->id)) {
        units[f][use.first] |= MetadataLiveRange::READ;
        LOG3("\t\t  Adding read for unit " << DBPrint::Brief << use.first);
        // For reads, add both the unit where the read happens as well as the non-gateway immediate
        // dominator for the read node (as that node is a candidate for initializing the value of
        // the metadata field).
        if (use.first->is<IR::BFN::Deparser>()) {
            f_dominators.insert(use.first);
            // nullptr indicates deparser to the getNonGatewayImmediateDominator() method.
            auto t = domTree.getNonGatewayImmediateDominator(nullptr, f->gress);
            if (!t) {
                LOG3("\t\t\tNo table dominators for use unit " << DBPrint::Brief << use.first);
                return false;
            }
            LOG3("\t\t\tAdding dominator for deparser " << (*t)->name);
            const auto* u = (*t)->to<IR::BFN::Unit>();
            f_dominators.insert(u);
        } else if (use.first->is<IR::MAU::Table>()) {
            const auto* t = use.first->to<IR::MAU::Table>();
            // Only insert the current table as the dominator node if it is a non-gateway table.
            bool addReadNode = false;
            if (!t->gateway_only()) {
                addReadNode = true;
                // If the field is marked no-init, then we do not actually need to consider the
                // dominator of the field because no initialization will be required for that field.
                if (noInit.count(f)) {
                    LOG3("\t\t\tNot adding dominator for field " << f->name << " marked "
                         "pa_no_init.");
                    continue;
                }
            }
            auto dom = domTree.getNonGatewayImmediateDominator(t, f->gress);
            if (!dom) {
                LOG3("\t\t\tNo non gateway dominator for use unit " << t->name);
                return false;
            }
            const auto* u = (*dom)->to<IR::BFN::Unit>();
            f_dominators.insert(u);
            // Only add read node if it has a non gateway dominator table (i.e. a potential
            // initialization point).
            if (addReadNode) f_dominators.insert(use.first);
            LOG3("\t\t\tAdding dominator " << DBPrint::Brief << u);
        }
    }
    return true;
}

bool FindInitializationNode::canInitTableReachGUnits(
        const IR::MAU::Table* table,
        const ordered_set<const IR::BFN::Unit*>& g_units) const {
    const IR::BFN::Unit* unit = table->to<IR::BFN::Unit>();
    if (!unit) BUG("How is table %1% not a unit?", table->name);
    auto rv = canFUnitsReachGUnits({ unit }, g_units, flowGraph);
    // rv now contains a set of pairs of units. Each pair represents a case where table reaches
    // a g-unit. For this method, we want to return true only if table reaches all the g-units.
    // Therefore, the number of pairs in rv should be equal to the number of g-units (because we can
    // have g_units.size() pairs maximum).
    return (rv.size() == g_units.size());
}

bool FindInitializationNode::canFUsesReachInitTable(
        const IR::MAU::Table* initTable,
        const ordered_set<const IR::BFN::Unit*>& f_units) const {
    const IR::BFN::Unit* unit = initTable->to<IR::BFN::Unit>();
    if (!unit) BUG("How is table %1% not a unit?", initTable->name);
    auto rv = canFUnitsReachGUnits(f_units, { unit }, flowGraph);
    // rv now contains a set of pairs of units. Each pair represents a case where the f-unit reaches
    // the initTable. For this method, we want to return true only if all the f-units reach the
    // initTable. Therefore, the number of pairs in rv should be equal to the number of f-units
    // (because we can have f_units.size() * 1 pairs maximum [1 stands for the number of
    // initTables]).
    return (rv.size() == f_units.size());
}

ordered_set<const IR::MAU::Table*>
FindInitializationNode::getTableUsesForField(
        const PHV::Field* f,
        bool uses,
        bool defs) const {
    ordered_set<const IR::MAU::Table*> rs;
    if (defs) {
        for (auto& def : defuse.getAllDefs(f->id)) {
            const auto* u = def.first;
            if (u->is<IR::MAU::Table>())
                rs.insert(u->to<IR::MAU::Table>());
        }
    }
    if (!uses) return rs;
    for (auto& use : defuse.getAllUses(f->id)) {
        const auto* u = use.first;
        if (u->is<IR::MAU::Table>())
            rs.insert(u->to<IR::MAU::Table>());
    }
    return rs;
}

bool FindInitializationNode::increasesDependenceCriticalPath(
        const IR::MAU::Table* use,
        const IR::MAU::Table* init) const {
    int use_stage = dg.min_stage(use);
    int init_stage = dg.min_stage(init);
    int init_dep_tail = dg.dependence_tail_size(init);
    LOG7("\t\tuse_stage: " << use_stage << ", init_stage: " << init_stage << ", init_dep_tail: " <<
         init_dep_tail);
    if (use_stage < init_stage) return false;
    int new_init_stage = use_stage + 1;
    LOG7("\t\tnew_init_stage: " << new_init_stage << ", maxStages: " << maxStages);
    if (new_init_stage + init_dep_tail > maxStages)
        return true;
    return false;
}

bool FindInitializationNode::cannotInitInAction(
        const PHV::Container& c,
        const IR::MAU::Action* action,
        const PHV::Transaction& alloc) const {
    // If the PHVs in this action are already unaligned, then we cannot add initialization in this
    // action.
    if (actionConstraints.cannot_initialize(c, action, alloc)) {
        LOG5("\t\t\tAction analysis indicates a pre-existing write using PHV/action data/non-zero "
             "const to container " << c << " in " << action->name << ". Cannot initialize here.");
        return true;
    }
    return doNotInitActions.count(action);
}

bool FindInitializationNode::mayViolatePackConflict(
        const IR::MAU::Table* initTable,
        const PHV::Field* initField,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const PHV::Transaction& alloc) const {
    // Tables containing the initialization points for all the existing fields in the container.
    ordered_set<const IR::MAU::Table*> initTablesForExistingFields;
    for (const PHV::AllocSlice& slice : container_state) {
        if (slice.field() == initField) continue;
        auto initPoints = alloc.getInitPoints(slice);
        for (const auto* act : initPoints) {
            auto t = tablesToActions.getTableForAction(act);
            if (!t) continue;
            initTablesForExistingFields.insert(*t);
            LOG5("\t\t  Need to check def of field " << initField->name << " against the table "
                 << (*t)->name << " where " << slice << " is initialized.");
        }
        for (auto& def : defuse.getAllDefs(slice.field()->id)) {
            const auto* t = def.first->to<IR::MAU::Table>();
            if (!t) continue;
            if (t == initTable) continue;
            if (tableAlloc.inSameStage(initTable, t).size() != 0 && !tableMutex(initTable, t)) {
                LOG4("\t\tInitialization table " << initTable->name << " and def table " << t->name
                     << " of " << slice << " are in the same stage, and therefore there is a pack "
                     "conflict.");
                return true; } } }

    // Check that the def tables of the field being initialized are not in the same stage as the
    // initialization tables for slices already allocated in this container. If they are, this would
    // result in a container conflict for this container, and could possibly lengthen the dependency
    // chain. Therefore, we choose not to initialize this field in this table.
    for (const auto* t : initTablesForExistingFields) {
        for (auto& def : defuse.getAllDefs(initField->id)) {
            const auto* d = def.first->to<IR::MAU::Table>();
            if (!d) continue;
            if (t == d) continue;
            if (tableAlloc.inSameStage(t, d).size() != 0 && !tableMutex(t, d)) {
                LOG4("\t\tInitialization table " << t->name << " and def table " << d->name <<
                     " of " << initField->name << " are in the same stage, and therefore there is "
                     "a pack conflict.");
                return true;
            }
        }
    }
    return false;
}

boost::optional<const PHV::Allocation::ActionSet> FindInitializationNode::getInitPointsForTable(
        const PHV::Container& c,
        const IR::MAU::Table* t,
        const PHV::Field* f,
        const ordered_set<const IR::MAU::Table*>& prevUses,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const PHV::Transaction& alloc,
        bool ignoreMutex) const {
    // If the uses of the previous field do not reach this initialization point, then the live
    // ranges might overlap.
    ordered_set<const IR::BFN::Unit*> prevUseUnits;
    for (const auto* t : prevUses) {
        const IR::BFN::Unit* u = t->to<IR::BFN::Unit>();
        if (!u) BUG("How is table %1% not a unit?", t->name);
        prevUseUnits.insert(u);
    }
    if (!canFUsesReachInitTable(t, prevUseUnits)) {
        LOG3("\t\t\tIgnoring table " << t->name << " because uses of previous "
             "field do not reach it.");
        return boost::none;
    }

    if (mayViolatePackConflict(t, f, container_state, alloc))
        return boost::none;
    // Initializing at table t requires that there is a dependence now from the previous uses of
    // table to table t. Return boost::none if this initialization would result in an increase in
    // the maximum number of stages in the dependence graph.
    for (const auto* prevUse : prevUses)
        if (increasesDependenceCriticalPath(prevUse, t))
            return boost::none;
    PHV::Allocation::ActionSet actions;
    // If the table t is mutually exclusive with any of the tables that are the uses of field f,
    // then do not initialize in this table.
    if (!ignoreMutex) {
        ordered_set<const IR::MAU::Table*> tableUses = getTableUsesForField(f);
        for (const auto* tbl : tableUses) {
            if (tableMutex(t, tbl)) {
                LOG3("\t\t\tIgnoring table " << t->name << " because it is mutually exclusive with "
                        "use " << tbl->name << " of field " << f->name);
                return boost::none;
            }
        }
    }

    for (const auto* act : tablesToActions.getActionsForTable(t)) {
        if (cannotInitInAction(c, act, alloc)) {
            LOG3("\t\t\t  Cannot init " << f->name << " in do not init action " << act);
            return boost::none;
        }
        // If field is already written in this action, then do not initialize here.
        if (actionConstraints.written_in(f, act)) continue;
        ordered_set<const PHV::Field*> actionReads = actionConstraints.actionReads(act);
        ordered_set<const PHV::Field*> actionWrites = actionConstraints.actionWrites(act);
        auto inits = alloc.getMetadataInits(act);
        for (const auto* g : inits)
            LOG3("\t\t\t  Noting down initialization of " << g->name << " for action " <<
                    act->name);
        actionWrites.insert(inits.begin(), inits.end());
        // If any of the fields read or written by the action are mutually exclusive with the field
        // to be initialized, then do not initialize the field in this table.
        for (const auto* g : actionReads) {
            if (phv.isFieldMutex(f, g)) {
                LOG3("\t\t\tIgnoring table " << t->name << " for initialization of " << t->name <<
                     " because action " << act->name << " reads field " << g->name << " which is "
                     "mutually exclusive with field " << f->name);
                return boost::none;
            }
        }
        for (const auto* g : actionWrites) {
            if (phv.isFieldMutex(f, g)) {
                LOG3("\t\t\tIgnoring table " << t->name << " for initialization of " << t->name <<
                     " because action " << act->name << " writes field " << g->name << " which is "
                     "mutually exclusive with field " << f->name);
                return boost::none;
            }
        }
        actions.insert(act);
    }
    return actions;
}

boost::optional<const PHV::Allocation::ActionSet>
FindInitializationNode::getInitializationCandidates(
        const PHV::Container& c,
        const PHV::Field* f,
        const IR::MAU::Table* groupDominator,
        const ordered_map<const IR::BFN::Unit*, unsigned>& u,
        const int lastAllowedStage,
        const ordered_set<const IR::MAU::Table*>& fStrictDominators,
        const PHV::Field* prevField,
        const ordered_map<const PHV::Field*, ordered_set<const IR::BFN::Unit*>>& g_units,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const PHV::Transaction& alloc) const {
    PHV::Allocation::ActionSet rv;
    // At this point, the group dominator could be a unit that writes to the field, or a unit that
    // strictly dominates a read to the field. It can never be a unit that reads the field.
    const IR::BFN::Unit* unit = groupDominator->to<IR::BFN::Unit>();
    if (!unit) return boost::none;
    LOG4("\t\t  Group dominator: " << DBPrint::Brief << *unit);

    // Collect the uses for the previous field so that we may check if initialization increases the
    // dependence tail length.
    auto prevUses = getTableUsesForField(prevField, true /* uses */, true /* defs */);

    // If the group dominator writes the field, then initialize at this node. This involves adding
    // initializations to the actions in the group dominator that do not write to the field (done in
    // the getInitPointsForTable() method).
    if (u.count(unit)) {
        auto access = u.at(unit);
        if (access == MetadataLiveRange::READ)
            BUG("Group dominator cannot be a node that reads the field.");
        auto initPoints = getInitPointsForTable(c, groupDominator, f, prevUses, container_state,
                alloc);
        if (!initPoints) return boost::none;
        return initPoints;
    }

    // At this point, the field is not used in table t. So, make a list of all the tables that may
    // be used to initialize this field, and check init points for those tables one by one. Stop
    // once you get successful init points for a table.
    int allowedStage = dg.min_stage(groupDominator);
    // If allowedStage < lastAllowedStage, no initialization is possible at the group dominator,
    // then try to find initialization candidates on the way down from the group dominator to the
    // strictly dominating uses of the field.
    if (allowedStage < lastAllowedStage) {
        // If there are more than 3 strict dominating uses of the field, do not initialize (This is
        // to avoid adding too many initializations for the field).
        LOG4("\t\t  Group dominator at an earlier stage (" << allowedStage << ") than allowed stage"
             " (" << lastAllowedStage << ")");
        if (fStrictDominators.size() > 3) return boost::none;
        auto all_f_table_uses = getTableUsesForField(f, true /* uses */, true /* defs */);
        bool dominatorsIncreaseCriticalPath = std::any_of(
                fStrictDominators.begin(), fStrictDominators.end(), [&](const IR::MAU::Table* t) {
            bool returnValue = false;
            // Inserting initialization at the strict dominator would induce a dependency between
            // the strict dominator and the uses of the field f. If any of these dependencies
            // increase the critical path length (corresponding to every single use of f), then we
            // set the dominatorsIncreaseCritcialPath value to true and do not initialize at the
            // strict dominators.
            for (const auto* t1 : all_f_table_uses)
                returnValue |= increasesDependenceCriticalPath(t, t1);
            return returnValue;
        });
        if (dominatorsIncreaseCriticalPath) {
            LOG4("\t\t  Initialization at one of the strict dominators would result in the "
                 "lengthening of the critical path");
            return boost::none;
        }
        for (const auto* t : fStrictDominators) {
            LOG4("\t\t  Trying to initialize at table " << t->name);
            auto initPoints = getInitPointsForTable(c, t, f, prevUses, container_state, alloc,
                    true);
            if (!initPoints) {
                LOG4("\t\t  Could not initialize at table " << t->name);
                return boost::none;
            }
            rv.insert(initPoints->begin(), initPoints->end());
        }
        LOG4("\t\t  Successfully inserted initialization at strict dominators");
        return rv;
    }

    std::vector<const IR::MAU::Table*> candidateTables;
    // First candidate is always the group dominator. If the group dominator does not work as the
    // initialization point, then try other tables in the allowed stages.
    candidateTables.push_back(groupDominator);
    for (int i = allowedStage; i >= lastAllowedStage; i--) {
        const ordered_set<const IR::MAU::Table*> tables = metaLiveMap.getTablesInStage(i);
        for (const auto* tbl : tables) {
            // Cannot initialize at gateway table.
            if (tbl->gateway_only()) continue;
            // Do not add group dominator a second time.
            if (tbl == groupDominator) continue;
            if (!domTree.strictlyDominates(tbl, groupDominator)) continue;
            candidateTables.push_back(tbl);
        }
    }
    LOG3("\t\t  Possible initialization tables: ");
    for (const auto* tbl : candidateTables)
        LOG3("\t\t\t" << tbl->name << " (stage " << dg.min_stage(tbl) << ")");

    for (const auto* tbl : candidateTables) {
        // Find the first table where initialization is possible.
        LOG3("\t\t  Checking whether initialization is possible at table " << tbl->name);
        bool reachCondition = false;
        for (auto kv : g_units) {
            if (kv.second.size() == 0) continue;
            reachCondition |= canInitTableReachGUnits(tbl, kv.second);
        }
        if (reachCondition) {
            LOG3("\t\t  Initialization at " << tbl->name << " would reach uses of previous field.");
            continue;
        }
        auto candidateActions = getInitPointsForTable(c, tbl, f, prevUses, container_state, alloc);
        if (!candidateActions) continue;
        LOG3("\t\t  Initialization possible for table " << tbl->name);
        return candidateActions;
    }
    // If initialization is not possible at any candidate table, then we reach here. So, return
    // boost::none.
    return boost::none;
}

inline bool liveRangesOverlap(
        const std::pair<int, int>& first,
        const std::pair<int, int>& second) {
    if (first.first < second.first && first.second < second.first)
        return true;
    if (second.first < first.first && second.second < first.first)
        return true;
    return false;
}

bool FindInitializationNode::identifyFieldsToInitialize(
        std::vector<const PHV::Field*>& fields,
        const ordered_map<int, std::pair<int, int>>& livemap) const {
    ordered_set<const PHV::Field*> fieldsToErase;
    size_t index1 = 0;
    size_t index2 = 0;
    for (const auto* f1 : fields) {
        ++index1;
        for (const auto* f2 : fields) {
            ++index2;
            if (f1 == f2) continue;
            if (index2 <= index1) continue;
            // If two fields with the same live range are mutually exclusive, then only consider one
            // of them for initialization.
            if (phv.isFieldMutex(f1, f2)) {
                LOG3("\t\t  Fields " << f1->name << " and " << f2->name << " are marked as "
                     "mutually exclusive.");
                if (livemap.at(f1->id) == livemap.at(f2->id))
                    fieldsToErase.insert(f2);
            }
        }
        index2 = 0;
    }

    for (const auto* f : fieldsToErase) {
        auto it = std::find(fields.begin(), fields.end(), f);
        fields.erase(it);
    }
    return true;
}

boost::optional<PHV::Allocation::LiveRangeShrinkingMap>
FindInitializationNode::findInitializationNodes(
        const PHV::Container c,
        const ordered_set<PHV::AllocSlice>& alloced,
        const PHV::Transaction& alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    // Metadata initialization that enables live range shrinking cannot occur for tagalong
    // containers as we cannot reset the container to 0 (container not accessible in the MAU).
    if (c.is(PHV::Kind::tagalong)) return boost::none;

    ordered_map<const PHV::Field*, ordered_set<PHV::AllocSlice>> field_to_slices;
    ordered_set<const PHV::Field*> fields;
    for (auto& sl : alloced) {
        fields.insert(sl.field());
        field_to_slices[sl.field()].insert(sl);
    }

    PHV::Allocation::LiveRangeShrinkingMap initPoints;
    // If there aren't multiple fields in the queried field set, then initialization is not
    // required.
    if (fields.size() <= 1) return initPoints;
    const auto& livemap = metaLiveMap.getMetadataLiveMap();
    const auto& livemapUsage = metaLiveMap.getMetadataLiveMapUsage();

    // fieldsInOrder is the set of queried fields sorted according to the live ranges. The earliest
    // live range appears first in the resulting vector while the field with the latest live range
    // appears last.
    std::vector<const PHV::Field*> fieldsInOrder;
    for (const auto* f : fields)
        fieldsInOrder.push_back(f);
    std::sort(fieldsInOrder.begin(), fieldsInOrder.end(),
        [&](const PHV::Field* f1, const PHV::Field* f2) {
            return livemap.at(f1->id).first < livemap.at(f2->id).first;
    });

    LOG3("\t  Candidate fields for initialization, and their live ranges:");
    for (const auto* f : fieldsInOrder)
        LOG3("\t\t" << f->name << " -- " << livemap.at(f->id).first << " to " <<
             livemap.at(f->id).second);

    uint8_t idx = 0;
    LOG3("\t  Initialization may be required for:");
    for (const auto* f : fieldsInOrder)
        if (idx++ != 0)
            LOG3("\t\t" << f->name);
    if (!identifyFieldsToInitialize(fieldsInOrder, livemap))
        return boost::none;
    LOG3("\t  Candidate fields for initialization, and their live ranges:");
    for (const auto* f : fieldsInOrder)
        LOG3("\t\t" << f->name << " -- " << livemap.at(f->id).first << " to " <<
             livemap.at(f->id).second);

    // The set of fields for which initialization actions have already been determined.
    ordered_set<const PHV::Field*> seenFields;
    // The set of units and the kind of access in that unit for each field.
    ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, unsigned>> units;
    idx = 0;
    const PHV::Field* lastField = nullptr;
    static PHV::Allocation::ActionSet emptySet;

    // For each metadata field that shares containers based on live ranges with other metadata:
    for (const auto* f : fieldsInOrder) {
        LOG3("\tTrying to initialize field: " << f);
        LOG3("\t\tDoes field have uninitialized read? " << defuse.hasUninitializedRead(f->id));
        std::stringstream ss;
        ss << "\t\t" << seenFields.size() << " fields already initialized for this container.";
        for (const auto* g : seenFields)
            ss << " " << g->name;
        LOG3(ss.str());

        // Set of dominator nodes for field f. These will also be the prime candidates for metadata
        // initialization, so these should not contain any gateways.
        ordered_set<const IR::BFN::Unit*> f_dominators;
        // Collect all initialization points for slices of this field. They are part of the def set
        // of this field too.
        BUG_CHECK(field_to_slices.count(f), "Cannot find candidate slice corresponding to %1%",
                  f->name);
        ordered_set<const IR::BFN::Unit*> alreadyInitializedUnits;
        for (auto& slice : field_to_slices.at(f)) {
            auto initPointsForTransaction = alloc.getInitPoints(slice);
            for (const auto* action : initPointsForTransaction) {
                auto initTable = tablesToActions.getTableForAction(action);
                BUG_CHECK(initTable, "Action %1% does not have an associated table", action->name);
                LOG3("\t\tSlice " << slice << " initialized in action " << action->name <<
                     " in table " << (*initTable)->name);
                alreadyInitializedUnits.insert((*initTable)->to<IR::BFN::Unit>());
            }
        }
        // Summarize the uses and defs of field f in the units map, and also populate f_dominators
        // with the dominator nodes for the uses and defs of f.
        LOG3("\t\tSummarizing defuse and dominator for field " << f->name);
        if (!summarizeUseDefs(f, alreadyInitializedUnits, units, f_dominators)) {
            LOG3("\t\tUses of field " << f->name << " contains a unit (deparser/table) whose non "
                 "gateway dominator is the parser. Therefore, cannot initialize metadata.");
            return boost::none;
        }

        // No initialization required for the field with the earliest live range (will be implicitly
        // initialized in the parser), so skip the rest of the loop after determining access and
        // dominator information.
        if (idx++ == 0) {
            LOG3("\t  No need to initialize field: " << f);
            seenFields.insert(f);
            lastField = f;
            continue;
        }

        // If f is an overlayable field, then it was inserted as padding by the compiler.
        // Therefore, there could be garbage in these padding fields and no initialization is
        // needed.
        if (f->overlayable) {
            LOG3("\t  No need to initialize padding field: " << f);
            seenFields.insert(f);
            lastField = f;
            initPoints[f] = emptySet;
            continue;
        }

        // Fields marked by pa_no_init do not require initialization.
        if (noInit.count(f)) {
            LOG3("\t\tField " << f->name << " marked no_init. No initialization required.");
            initPoints[f] = emptySet;
            seenFields.insert(f);
            continue;
        }

        LOG3("\t  Checking if " << f->name << " needs initialization.");
        ordered_map<const PHV::Field*, ordered_set<const IR::BFN::Unit*>> g_units;
        // Check against each field initialized so far in this container.
        for (const auto* g : seenFields) {
            if (phv.isFieldMutex(f, g)) {
                LOG3("\t\tExclusive with field " << g->name);
                continue;
            }
            LOG4("\t\tNon exclusive with field " << g->name);
            // We need to make sure that all defuses of field f cannot reach the defuses of field g.
            // The defuses of field g are first collected in the g_field_units set.
            ordered_set<const IR::BFN::Unit*> g_field_units;
            if (!units.count(g)) {
                LOG3("\t\t  Could not find any defuse units corresponding to " << g->name);
                continue;
            }
            for (auto kv : units.at(g)) {
                LOG5("\t\t  Inserting defuse unit for g: " << DBPrint::Brief << kv.first);
                g_field_units.insert(kv.first);
            }
            g_units[g].insert(g_field_units.begin(), g_field_units.end());
            LOG2("\t\tCan all defuses of " << f->name << " reach defuses of " << g->name << "?");
            auto reach_condition = canFUnitsReachGUnits(f_dominators, g_field_units,
                    flowGraph);
            // If one dominator of field f can reach any usedef of field g, then metadata
            // initialization is not possible. reach_condition contains all the pairs of units where
            // f_dominator can reach g_field_unit.
            if (reach_condition.size() > 0) {
                LOG2("\t\t  Yes. Therefore, metadata initialization not possible.");
                return boost::none;
            }
            LOG3("\t\t  No.");
        }

        if (LOGGING(1)) {
            LOG3("\t\t  Considering the following dominators");
            for (const auto* u : f_dominators)
                LOG3("\t\t\t" << DBPrint::Brief << u);
        }

        // Trim the list of dominators determined earlier to the minimal set of strict dominators.
        LOG2("\t\t  Trimming the list of dominators in the set of defuses.");
        getTrimmedDominators(f_dominators, domTree);
        if (hasParserUse(f_dominators)) {
            LOG3("\t\t  Defuse units of field " << f->name << " includes the parser. "
                 "Cannot initialize metadata.");
            return boost::none;
        }
        if (LOGGING(3)) {
            for (const auto* u : f_dominators) {
                if (u->is<IR::MAU::Table>()) {
                    LOG3("\t\t\t" << DBPrint::Brief << u << " (stage " <<
                            dg.min_stage(u->to<IR::MAU::Table>()) << ")");
                } else {
                    LOG3("\t\t\t" << DBPrint::Brief << u);
                }
            }
        }
        // Only the set of tables in which field f has been defined/used.
        ordered_set<const IR::MAU::Table*> f_table_uses;
        for (const auto* u : f_dominators) {
            if (!u->is<IR::MAU::Table>()) {
                LOG3("\t\t  Dominators of field " << f->name << " includes the ingress deparser. "
                     "Cannot initialize metadata.");
                return boost::none;
            }
            f_table_uses.insert(u->to<IR::MAU::Table>());
        }

        // If the strict dominators are all writes, then we can initialize at those nodes directly,
        // without having to go upto the group dominator. Make sure that all the actions in the
        // strict dominators write to the field (otherwise there is a potential uninitialized read
        // path left).
        auto IsUnitWrite = [&](const IR::BFN::Unit* u) {
            bool writtenInUnit = units[f][u] & MetadataLiveRange::WRITE;
            bool readInUnit = units[f][u] & MetadataLiveRange::READ;
            if (!writtenInUnit || readInUnit) return false;
            const auto* t = u->to<IR::MAU::Table>();
            BUG_CHECK(t, "Table object not found for strict dominator unit %1%", u);
            for (const auto* act : tablesToActions.getActionsForTable(t))
                if (!actionConstraints.written_in(f, act)) return false;
            return true;
        };
        bool allStrictDominatorsWrite = std::all_of(f_dominators.begin(), f_dominators.end(),
            IsUnitWrite);
        if (allStrictDominatorsWrite) {
            LOG3("\t\tAll actions of all strict dominators write to the field " << f->name);
            initPoints[f] = emptySet;
            seenFields.insert(f);
            continue;
        } else {
            LOG3("\t\tOnly some strict dominators write to the field " << f->name);
        }

        // Calculate the stage where the previously used field was last used. Initialization can be
        // done in any stage between that identified stage and the stage in which the group
        // dominator is.
        // XXX(Deep): Could we push initialization from group dominator downwards to further shrink
        // the live ranges?
        int lastUsedStage = -1;
        bool lastUsedStageWritesField = false;
        for (const auto* g : seenFields) {
            int lastUseG = livemap.at(g->id).second;
            if (lastUseG > lastUsedStage) {
                lastUsedStage = lastUseG;
                lastUsedStageWritesField = livemapUsage.at(g->id).second & MetadataLiveRange::WRITE;
            }
        }
        LOG3("\t\t  Last use of previous field detected to be: " << lastUsedStage);
        if (lastUsedStageWritesField) {
            LOG3("\t\t\tLast use includes a write.");
            lastUsedStage += 1;
        } else {
            // Writes happen after reads in the stage, so it is possible to initialize in the
            // lastUsedStage too.
            LOG3("\t\t\tLast use was a read.");
            // Set last used stage to 0, in case it was negative (indicating use in parser)
            // previously, because the earliest stage in which the metadata field can be initialized
            // is stage 0.
            if (lastUsedStage < 0)
                lastUsedStage = 0;
        }

        LOG3("\t\tChoosing the right place to initialize field " << f->name);
        const IR::MAU::Table* groupDominator;
        LOG3("\t\t  Getting non gateway group dominator");
        if (f_table_uses.size() == 0) {
            BUG("Did not find any group dominator for uses of field %1%", f->name);
        } else if (f_table_uses.size() == 1) {
            groupDominator = *(f_table_uses.begin());
        } else {
            groupDominator = domTree.getNonGatewayGroupDominator(f_table_uses);
        }
        if (groupDominator == nullptr) {
            LOG3("\t\t  Could not find group dominator to initialize at ");
            return boost::none;
        }
        LOG3("\t\t  Group dominator found: " << groupDominator->name << " (stage " <<
             dg.min_stage(groupDominator) << ")");

        LOG4("\t\t  Uses of f:");
        auto all_f_table_uses = getTableUsesForField(f, true /* uses */, true /* defs */);
        for (const auto* t : all_f_table_uses)
            LOG4("\t\t\t" << t->name);
        bool groupDominatorOK = true;

        do {
            // If the group dominator's stage is earlier than the last use of the previous field,
            // then we push the initialization down to the set of strict dominators of this field's
            // uses. So, we do not need to check the dependency length increase for the group
            // dominator (it gets checked later for each of the strict dominators).
            if (dg.min_stage(groupDominator) < lastUsedStage) break;
            groupDominatorOK = true;
            for (const auto* t : all_f_table_uses) {
                // If the stage number for an existing use of the field is equal to the stage in the
                // group dominator, this would extend the dependence chain.
                if (increasesDependenceCriticalPath(groupDominator, t)) {
                    LOG3("\t\t\tInitialization would increase critical path length because of "
                         "tables " << groupDominator->name << " and " << t->name);
                    groupDominatorOK = false;
                }
            }
            // Go to the next dominator node.
            if (!groupDominatorOK) {
                auto newDominator = domTree.getNonGatewayImmediateDominator(groupDominator,
                        f->gress);
                if (!newDominator) {
                    LOG3("\t\t\tCannot find immediate dominator for group dominator " <<
                         groupDominator->name);
                    LOG3("\t\t\tChoose not to initialize at " << groupDominator->name << " to "
                         "avoid increasing critical path length");
                    return boost::none;
                } else if (*newDominator == groupDominator) {
                    LOG3("\t\t\tReached the beginning of the flow graph. No more initialization "
                         "points available.");
                    return boost::none;
                }
                if (groupDominator == *newDominator) {
                    LOG3("\t\t\tReached the source node in the table flow graph");
                    return boost::none;
                }
                groupDominator = *newDominator;
                LOG3("\t\t  Setting group dominator to: " << groupDominator->name << " (stage " <<
                     dg.min_stage(groupDominator) << ")");
            }
        } while (!groupDominatorOK);

        auto initializationCandidates = getInitializationCandidates(c, f, groupDominator,
                units.at(f), lastUsedStage, f_table_uses, lastField, g_units, container_state,
                alloc);

        if (!initializationCandidates) {
            LOG3("\t\tCould not find any actions to initialize field in the group dominator.");
            return boost::none;
        }
        for (const auto* act : *initializationCandidates)
            LOG3("\t\t  Initialization action: " << act->name);
        initPoints[f] = *initializationCandidates;
        seenFields.insert(f);

        if (lastField == nullptr) continue;
        LOG3("\t\t  Need to insert dependencies from uses of " << lastField->name <<
             " to initialization of " << f->name);
        lastField = f;
    }
    return initPoints;
}

cstring FindInitializationNode::printLiveRangeShrinkingMap(
        const PHV::Allocation::LiveRangeShrinkingMap& m,
        cstring indent) const {
    std::stringstream ss;
    for (auto kv : m) {
        ss << indent << "Initialization for field " << kv.first->name << " :" << std::endl;
        for (const auto* act : kv.second)
            ss << indent << "  " << act->name << std::endl;
        ss << std::endl;
    }
    return ss.str();
}

LiveRangeShrinking::LiveRangeShrinking(
        const PhvInfo& p,
        const FieldDefUse& u,
        const DependencyGraph& g,
        const PragmaNoInit& i,
        const MetadataLiveRange& l,
        const ActionPhvConstraints& a,
        const BuildDominatorTree& d,
        const MauBacktracker& bt)
    : initNode(d, p, u, g, i.getFields(), tableActionsMap, l, a, tableMutex, d.getFlowGraph(), bt) {
    addPasses({
        &tableMutex,
        &tableActionsMap,
        &initNode
    });
}
