#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/mau/table_layout.h"

Visitor::profile_t FindInitializationNode::init_apply(const IR::Node* root) {
    LOG2("Printing dependency graph");
    LOG2(dg);
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
        LOG2("\tCannot initialize at action " << act->name << " because it requires "
             "the hash distribution unit.");
        doNotInitActions.insert(act);
    }
    return true;
}

bool FindInitializationNode::isUninitializedDef(const PHV::Field* f, const IR::BFN::Unit* u) const {
    if (!defuse.hasUninitializedRead(f->id)) return false;
    if (u->is<IR::BFN::ParserState>())
        if (u->to<IR::BFN::ParserState>()->name.startsWith(MetadataLiveRange::INGRESS_PARSER_ENTRY)
         || u->to<IR::BFN::ParserState>()->name.startsWith(MetadataLiveRange::EGRESS_PARSER_ENTRY))
            return true;
    return false;
}

bool FindInitializationNode::hasParserUse(ordered_set<const IR::BFN::Unit*> doms) const {
    for (const auto* u : doms)
        if (u->is<IR::BFN::Parser>() || u->is<IR::BFN::ParserState>())
            return true;
    return false;
}

bool FindInitializationNode::summarizeUseDefs(
        const PHV::Field* f,
        ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, unsigned>>& units,
        ordered_set<const IR::BFN::Unit*>& f_dominators) const {
    // Note all units where field f is defined.
    for (auto& def : defuse.getAllDefs(f->id)) {
        if (isUninitializedDef(f, def.first)) {
            LOG4("\t\t\tSkipping because uninitialized read at " << DBPrint::Brief <<
                    def.first);
            continue;
        }
        units[f][def.first] |= MetadataLiveRange::WRITE;
        LOG4("\t\t  Adding write for unit " << DBPrint::Brief << def.first);
        // Write is its own dominator, so insert this node into f_dominators.
        f_dominators.insert(def.first);
        LOG2("\t\t\tAdding dominator " << DBPrint::Brief << def.first);
    }

    // Note all units where f is used.
    for (auto& use : defuse.getAllUses(f->id)) {
        units[f][use.first] |= MetadataLiveRange::READ;
        LOG2("\t\t  Adding read for unit " << DBPrint::Brief << use.first);
        // For reads, add both the unit where the read happens as well as the non-gateway immediate
        // dominator for the read node (as that node is a candidate for initializing the value of
        // the metadata field).
        if (use.first->is<IR::BFN::Deparser>()) {
            f_dominators.insert(use.first);
            // nullptr indicates deparser to the getNonGatewayImmediateDominator() method.
            auto t = domTree.getNonGatewayImmediateDominator(nullptr, f->gress);
            if (!t) {
                LOG2("\t\t\tNo table dominators for use unit " << DBPrint::Brief << use.first);
                return false;
            }
            LOG2("\t\t\tAdding dominator for deparser " << (*t)->name);
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
                    LOG2("\t\t\tNot adding dominator for field " << f->name << " marked "
                         "pa_no_init.");
                    continue;
                }
            }
            auto dom = domTree.getNonGatewayImmediateDominator(t, f->gress);
            if (!dom) {
                LOG2("\t\t\tNo non gateway dominator for use unit " << t->name);
                return false;
            }
            const auto* u = (*dom)->to<IR::BFN::Unit>();
            f_dominators.insert(u);
            // Only add read node if it has a non gateway dominator table (i.e. a potential
            // initialization point).
            if (addReadNode) f_dominators.insert(use.first);
            LOG2("\t\t\tAdding dominator " << DBPrint::Brief << u);
        }
    }
    return true;
}

bool FindInitializationNode::canInitTableReachGUnits(
        const IR::MAU::Table* table,
        const ordered_set<const IR::BFN::Unit*>& g_units) const {
    const IR::BFN::Unit* unit = table->to<IR::BFN::Unit>();
    if (!unit) BUG("How is table %1% not a unit?", table->name);
    ordered_set<const IR::BFN::Unit*> f_units;
    f_units.insert(unit);
    return canFUnitsReachGUnits(f_units, g_units);
}

bool FindInitializationNode::canFUnitsReachGUnits(
        const ordered_set<const IR::BFN::Unit*>& f_units,
        const ordered_set<const IR::BFN::Unit*>& g_units) const {
    bool rv = false;
    auto gress = boost::make_optional(false, gress_t());
    for (const auto* u1 : f_units) {
        bool deparser1 = u1->is<IR::BFN::Deparser>();
        bool table1 = u1->is<IR::MAU::Table>();
        if (!gress) gress = u1->thread();
        if (hasParserUse({ u1 })) {
            rv = true;
            LOG4("\t\t\tParser defuse " << DBPrint::Brief << u1 << " can reach all g units.");
            continue;
        }
        const auto* t1 = table1 ? u1->to<IR::MAU::Table>() : nullptr;
        const FlowGraph& fg = *(flowGraph[*gress]);
        for (const auto* u2 : g_units) {
            // Units of different gresses cannot reach each other.
            if (gress)
                if (u2->thread() != *gress)
                    return false;
            bool deparser2 = u2->is<IR::BFN::Deparser>();
            // If f was used in a deparser and g was not in the deparser, then f cannot reach g.
            if (deparser1) {
                if (deparser2) {
                    LOG4("\t\t\tBoth units are deparser. Can reach.");
                    rv = true;
                } else {
                    LOG4("\t\t\t" << DBPrint::Brief << u1 << " cannot reach " << DBPrint::Brief <<
                         u2);
                }
                continue;
            }
            // Deparser/table use for f_unit cannot reach parser use for g_unit.
            if (table1 && hasParserUse({ u2 })) {
                LOG4("\t\t\t" << DBPrint::Brief << u1 << " cannot reach " << DBPrint::Brief << u2);
                continue;
            }
            // Deparser use for g can be reached by every unit's use in f.
            if (deparser2) {
                rv = true;
                LOG4("\t\t\t" << DBPrint::Brief << u1 << " can reach " << DBPrint::Brief << u2);
                continue;
            }

            if (!u2->is<IR::MAU::Table>())
                BUG("Non-parser, non-deparser, non-table defuse unit found.");
            const auto* t2 = u2->to<IR::MAU::Table>();
            if (fg.can_reach(t1, t2)) {
                LOG4("\t\t\t" << t1->name << " can reach " << t2->name);
                rv = true;
            } else {
                LOG4("\t\t\t" << t1->name << " cannot reach " << t2->name);
            }
        }
    }
    return rv;
}

void
FindInitializationNode::getTrimmedDominators(ordered_set<const IR::BFN::Unit*>& candidates) const {
    // By definition of dominators, all candidates are tables.
    ordered_set<const IR::BFN::Unit*> emptySet;
    ordered_set<const IR::BFN::Unit*> dominatedNodes;
    for (const auto* u1 : candidates) {
        if (hasParserUse({ u1 })) continue;
        bool table1 = u1->is<IR::MAU::Table>();
        const auto* t1 = table1 ? u1->to<IR::MAU::Table>() : nullptr;
        for (const auto* u2 : candidates) {
            if (u1 == u2) continue;
            if (hasParserUse({ u2 })) continue;
            bool table2 = u2->is<IR::MAU::Table>();
            const auto* t2 = table2 ? u2->to<IR::MAU::Table>() : nullptr;
            // If u1 dominates u2, only consider u1. So, mark u2 for deletion.
            if (domTree.strictlyDominates(t1, t2))
                dominatedNodes.insert(u2);
        }
    }
    for (const auto* u : dominatedNodes)
        candidates.erase(u);
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
    LOG6("\t\tuse_stage: " << use_stage << ", init_stage: " << init_stage << ", init_dep_tail: " <<
         init_dep_tail);
    if (use_stage < init_stage) return false;
    int new_init_stage = use_stage + 1;
    LOG6("\t\tnew_init_stage: " << new_init_stage << ", maxStages: " << maxStages);
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
        LOG4("\t\t\tAction analysis indicates a pre-existing write using PHV/action data/non-zero "
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
            LOG4("\t\t  Need to check def of field " << initField->name << " against the table "
                 << (*t)->name << " where " << slice << " is initialized.");
        }
        for (auto& def : defuse.getAllDefs(slice.field()->id)) {
            const auto* t = def.first->to<IR::MAU::Table>();
            if (!t) continue;
            if (t == initTable) continue;
            if (tableAlloc.inSameStage(initTable, t).size() != 0 && !tableMutex(initTable, t)) {
                LOG3("\t\tInitialization table " << initTable->name << " and def table " << t->name
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
                LOG3("\t\tInitialization table " << t->name << " and def table " << d->name <<
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
                LOG2("\t\t\tIgnoring table " << t->name << " because it is mutually exclusive with "
                        "use " << tbl->name << " of field " << f->name);
                return boost::none;
            }
        }
    }

    for (const auto* act : tablesToActions.getActionsForTable(t)) {
        if (cannotInitInAction(c, act, alloc)) {
            LOG2("\t\t\t  Cannot init " << f->name << " in do not init action " << act);
            return boost::none;
        }
        // If field is already written in this action, then do not initialize here.
        if (actionConstraints.written_in(f, act)) continue;
        ordered_set<const PHV::Field*> actionReads = actionConstraints.actionReads(act);
        ordered_set<const PHV::Field*> actionWrites = actionConstraints.actionWrites(act);
        auto inits = alloc.getMetadataInits(act);
        for (const auto* g : inits)
            LOG2("\t\t\t  Noting down initialization of " << g->name << " for action " <<
                    act->name);
        actionWrites.insert(inits.begin(), inits.end());
        // If any of the fields read or written by the action are mutually exclusive with the field
        // to be initialized, then do not initialize the field in this table.
        for (const auto* g : actionReads) {
            if (phv.isParserMutex(f, g)) {
                LOG2("\t\t\tIgnoring table " << t->name << " for initialization of " << t->name <<
                     " because action " << act->name << " reads field " << g->name << " which is "
                     "mutually exclusive with field " << f->name);
                return boost::none;
            }
        }
        for (const auto* g : actionWrites) {
            if (phv.isParserMutex(f, g)) {
                LOG2("\t\t\tIgnoring table " << t->name << " for initialization of " << t->name <<
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
    LOG3("\t\t  Group dominator: " << DBPrint::Brief << *unit);

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
        LOG3("\t\t  Group dominator at an earlier stage (" << allowedStage << ") than allowed stage"
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
            LOG3("\t\t  Initialization at one of the strict dominators would result in the "
                 "lengthening of the critical path");
            return boost::none;
        }
        for (const auto* t : fStrictDominators) {
            LOG3("\t\t  Trying to initialize at table " << t->name);
            auto initPoints = getInitPointsForTable(c, t, f, prevUses, container_state, alloc,
                    true);
            if (!initPoints) {
                LOG3("\t\t  Could not initialize at table " << t->name);
                return boost::none;
            }
            rv.insert(initPoints->begin(), initPoints->end());
        }
        LOG3("\t\t  Successfully inserted initialization at strict dominators");
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
    LOG2("\t\t  Possible initialization tables: ");
    for (const auto* tbl : candidateTables)
        LOG2("\t\t\t" << tbl->name << " (stage " << dg.min_stage(tbl) << ")");

    for (const auto* tbl : candidateTables) {
        // Find the first table where initialization is possible.
        LOG2("\t\t  Checking whether initialization is possible at table " << tbl->name);
        bool reachCondition = false;
        for (auto kv : g_units) {
            if (kv.second.size() == 0) continue;
            reachCondition |= canInitTableReachGUnits(tbl, kv.second);
        }
        if (reachCondition) {
            LOG2("\t\t  Initialization at " << tbl->name << " would reach uses of previous field.");
            continue;
        }
        auto candidateActions = getInitPointsForTable(c, tbl, f, prevUses, container_state, alloc);
        if (!candidateActions) continue;
        LOG2("\t\t  Initialization possible for table " << tbl->name);
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
            if (phv.isParserMutex(f1, f2)) {
                LOG2("\t\t  Fields " << f1->name << " and " << f2->name << " are marked as "
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
        const ordered_set<const PHV::Field*>& fields,
        const PHV::Transaction& alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
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

    LOG2("\t  Candidate fields for initialization, and their live ranges:");
    for (const auto* f : fieldsInOrder)
        LOG2("\t\t" << f->name << " -- " << livemap.at(f->id).first << " to " <<
             livemap.at(f->id).second);

    uint8_t idx = 0;
    LOG2("\t  Initialization may be required for:");
    for (const auto* f : fieldsInOrder)
        if (idx++ != 0)
            LOG2("\t\t" << f->name);
    if (!identifyFieldsToInitialize(fieldsInOrder, livemap))
        return boost::none;
    LOG2("\t  Candidate fields for initialization, and their live ranges:");
    for (const auto* f : fieldsInOrder)
        LOG2("\t\t" << f->name << " -- " << livemap.at(f->id).first << " to " <<
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
        LOG2("\tTrying to initialize field: " << f);
        LOG2("\t\tDoes field have uninitialized read? " << defuse.hasUninitializedRead(f->id));
        std::stringstream ss;
        ss << "\t\t" << seenFields.size() << " fields already initialized for this container.";
        for (const auto* g : seenFields)
            ss << " " << g->name;
        LOG2(ss.str());

        // Set of dominator nodes for field f. These will also be the prime candidates for metadata
        // initialization, so these should not contain any gateways.
        ordered_set<const IR::BFN::Unit*> f_dominators;
        // Summarize the uses and defs of field f in the units map, and also populate f_dominators
        // with the dominator nodes for the uses and defs of f.
        LOG2("\t\tSummarizing defuse and dominator for field " << f->name);
        if (!summarizeUseDefs(f, units, f_dominators)) {
            LOG2("\t\tUses of field " << f->name << " contains a unit (deparser/table) whose non "
                 "gateway dominator is the parser. Therefore, cannot initialize metadata.");
            return boost::none;
        }

        // No initialization required for the field with the earliest live range (will be implicitly
        // initialized in the parser), so skip the rest of the loop after determining access and
        // dominator information.
        if (idx++ == 0) {
            LOG2("\t  No need to initialize field: " << f);
            seenFields.insert(f);
            lastField = f;
            continue;
        }

        LOG2("\t  Checking if " << f->name << " needs initialization.");
        ordered_map<const PHV::Field*, ordered_set<const IR::BFN::Unit*>> g_units;
        // Check against each field initialized so far in this container.
        for (const auto* g : seenFields) {
            if (phv.isParserMutex(f, g)) {
                LOG2("\t\tExclusive with field " << g->name);
                continue;
            }
            LOG3("\t\tNon exclusive with field " << g->name);
            // We need to make sure that all defuses of field f cannot reach the defuses of field g.
            // The defuses of field g are first collected in the g_field_units set.
            ordered_set<const IR::BFN::Unit*> g_field_units;
            if (!units.count(g)) {
                LOG2("\t\t  Could not find any defuse units corresponding to " << g->name);
                continue;
            }
            for (auto kv : units.at(g)) {
                LOG4("\t\t  Inserting defuse unit for g: " << DBPrint::Brief << kv.first);
                g_field_units.insert(kv.first);
            }
            g_units[g].insert(g_field_units.begin(), g_field_units.end());
            LOG2("\t\tCan all defuses of " << f->name << " reach defuses of " << g->name << "?");
            bool reach_condition = canFUnitsReachGUnits(f_dominators, g_field_units);
            if (reach_condition) {
                LOG2("\t\t  Yes. Therefore, metadata initialization not possible.");
                return boost::none;
            }
            LOG2("\t\t  No.");
        }

        if (LOGGING(1)) {
            LOG2("\t\t  Considering the following dominators");
            for (const auto* u : f_dominators)
                LOG2("\t\t\t" << DBPrint::Brief << u);
        }

        // Trim the list of dominators determined earlier to the minimal set of strict dominators.
        LOG2("\t\t  Trimming the list of dominators in the set of defuses.");
        getTrimmedDominators(f_dominators);
        if (hasParserUse(f_dominators)) {
            LOG2("\t\t  Defuse units of field " << f->name << " includes the parser. "
                 "Cannot initialize metadata.");
            return boost::none;
        }
        if (LOGGING(2))
            for (const auto* u : f_dominators)
                LOG2("\t\t\t" << DBPrint::Brief << u << " (stage " <<
                        dg.min_stage(u->to<IR::MAU::Table>()) << ")");
        // Only the set of tables in which field f has been defined/used.
        ordered_set<const IR::MAU::Table*> f_table_uses;
        for (const auto* u : f_dominators) {
            if (!u->is<IR::MAU::Table>()) {
                LOG2("\t\t  Dominators of field " << f->name << " includes the ingress deparser. "
                     "Cannot initialize metadata.");
                return boost::none;
            }
            f_table_uses.insert(u->to<IR::MAU::Table>());
        }

        if (noInit.count(f)) {
            LOG2("\t\tField " << f->name << " marked no_init. No initialization required.");
            initPoints[f] = emptySet;
            seenFields.insert(f);
            continue;
        }

        // If the strict dominators are all writes, then we can initialize at those nodes directly,
        // without having to go upto the group dominator.
        auto IsUnitWrite = [&](const IR::BFN::Unit* u) {
            return ((units[f][u] & MetadataLiveRange::WRITE) && !(units[f][u] &
                        MetadataLiveRange::READ));
        };
        bool allStrictDominatorsWrite = std::all_of(f_dominators.begin(), f_dominators.end(),
            IsUnitWrite);
        if (allStrictDominatorsWrite) {
            LOG2("\t\tAll strict dominators write to the field " << f->name);
            initPoints[f] = emptySet;
            seenFields.insert(f);
            continue;
        } else {
            LOG2("\t\tOnly some strict dominators write to the field " << f->name);
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
        LOG2("\t\t  Last use of previous field detected to be: " << lastUsedStage);
        if (lastUsedStageWritesField) {
            LOG2("\t\t\tLast use includes a write.");
            lastUsedStage += 1;
        } else {
            // Writes happen after reads in the stage, so it is possible to initialize in the
            // lastUsedStage too.
            LOG2("\t\t\tLast use was a read.");
            // Set last used stage to 0, in case it was negative (indicating use in parser)
            // previously, because the earliest stage in which the metadata field can be initialized
            // is stage 0.
            if (lastUsedStage < 0)
                lastUsedStage = 0;
        }

        LOG2("\t\tChoosing the right place to initialize field " << f->name);
        const IR::MAU::Table* groupDominator;
        LOG2("\t\t  Getting non gateway group dominator");
        if (f_table_uses.size() == 0) {
            BUG("Did not find any group dominator for uses of field %1%", f->name);
        } else if (f_table_uses.size() == 1) {
            groupDominator = *(f_table_uses.begin());
        } else {
            groupDominator = domTree.getNonGatewayGroupDominator(f_table_uses);
        }
        if (groupDominator == nullptr) {
            LOG2("\t\t  Could not find group dominator to initialize at ");
            return boost::none;
        }
        LOG2("\t\t  Group dominator found: " << groupDominator->name << " (stage " <<
             dg.min_stage(groupDominator) << ")");

        LOG3("\t\t  Uses of f:");
        auto all_f_table_uses = getTableUsesForField(f, true /* uses */, true /* defs */);
        for (const auto* t : all_f_table_uses)
            LOG3("\t\t\t" << t->name);
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
                    LOG2("\t\t\tInitialization would increase critical path length because of "
                         "tables " << groupDominator->name << " and " << t->name);
                    groupDominatorOK = false;
                }
            }
            // Go to the next dominator node.
            if (!groupDominatorOK) {
                auto newDominator = domTree.getNonGatewayImmediateDominator(groupDominator,
                        f->gress);
                if (!newDominator) {
                    LOG2("\t\t\tCannot find immediate dominator for group dominator " <<
                         groupDominator->name);
                    LOG2("\t\t\tChoose not to initialize at " << groupDominator->name << " to "
                         "avoid increasing critical path length");
                    return boost::none;
                }
                groupDominator = *newDominator;
                LOG2("\t\t  Setting group dominator to: " << groupDominator->name << " (stage " <<
                     dg.min_stage(groupDominator) << ")");
            }
        } while (!groupDominatorOK);

        auto initializationCandidates = getInitializationCandidates(c, f, groupDominator,
                units.at(f), lastUsedStage, f_table_uses, lastField, g_units, container_state,
                alloc);

        if (!initializationCandidates) {
            LOG2("\t\tCould not find any actions to initialize field in the group dominator.");
            return boost::none;
        }
        for (const auto* act : *initializationCandidates)
            LOG2("\t\t  Initialization action: " << act->name);
        initPoints[f] = *initializationCandidates;
        seenFields.insert(f);

        if (lastField == nullptr) continue;
        LOG2("\t\t  Need to insert dependencies from uses of " << lastField->name <<
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
        ss << indent << "Initialization for field " << kv.first->name << " : ";
        for (const auto* act : kv.second)
            ss << act->name;
        ss << std::endl;
    }
    return ss.str();
}

bool MapFieldToExpr::preorder(const IR::Expression* expr) {
    if (expr->is<IR::Cast>() || expr->is<IR::Slice>())
        return true;
    const auto* f = phv.field(expr);
    if (!f) return true;
    fieldExpressions[f->id] = expr;
    return true;
}

const IR::MAU::Instruction*
MapFieldToExpr::generateInitInstruction(const MapFieldToExpr::AllocSlice& slice) const {
    const auto* f = slice.field;
    BUG_CHECK(f, "Field is nullptr in generateInitInstruction");
    const IR::Expression* zeroExpr = new IR::Constant(new IR::Type_Bits(slice.width, false), 0);
    const IR::Expression* fieldExpr = getExpr(f);
    if (slice.width == f->size) {
        auto* prim = new IR::MAU::Instruction("set", { fieldExpr, zeroExpr });
        return prim;
    } else {
        le_bitrange range = slice.field_bits();
        const IR::Expression* sliceExpr = new IR::Slice(fieldExpr, range.hi, range.lo);
        auto* prim = new IR::MAU::Instruction("set", { sliceExpr, zeroExpr });
        return prim;
    }
}

Visitor::profile_t ComputeFieldsRequiringInit::init_apply(const IR::Node* root) {
    actionInits.clear();
    fieldsForInit.clear();
    for (auto& f : phv) {
        for (auto& slice : f.get_alloc()) {
            // For each alloc slice in the field, check if metadata initialization is required.
            if (slice.init_points.size() == 0) continue;
            LOG3("\t  Need to initialize " << f.name << " : " << slice);
            for (const auto* act : slice.init_points) {
                actionInits[act].push_back(slice);
                fieldsForInit.insert(slice.field);
                LOG3("\t\tInitialize at action " << act->name);
            }
        }
    }
    return Inspector::init_apply(root);
}

const IR::MAU::Action* AddInitialization::postorder(IR::MAU::Action* act) {
    auto* act_orig = getOriginal<IR::MAU::Action>();
    auto fieldsToBeInited = fieldsForInit.getInitsForAction(act_orig);
    if (fieldsToBeInited.size() == 0) return act;
    for (auto slice : fieldsToBeInited) {
        auto* prim = fieldToExpr.generateInitInstruction(slice);
        if (!prim) {
            ::warning("Cannot add initialization for slice");
            continue;
        }
        act->action.push_back(prim);
        auto tbl = actionsMap.getTableForAction(act_orig);
        if (!tbl)
            LOG2("\t\tAdding primitive " << prim << " to action " << act->name << " without table");
        else
            LOG2("\t\tAdding primitive " << prim << " to action " << act->name << ", in table " <<
                 (*tbl)->name);
    }
    return act;
}

void ComputeDependencies::noteDependencies(
        const ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>& fields,
        const ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Table*>>& inits) {
    for (auto& kv : fields) {
        const auto* writeField = kv.first;
        if (!inits.count(writeField))
            BUG("Init entry not found for %1%", writeField->name);
        for (const auto* initTable : inits.at(writeField)) {
            // initTable = Table where writeField is initialized.
            for (const auto* readField : kv.second) {
                // For each field that shares containers with writeField.
                for (auto& use : defuse.getAllUses(readField->id)) {
                    const auto* readTable = use.first->to<IR::MAU::Table>();
                    if (!readTable) continue;
                    LOG4("\tInit unit for " << writeField->name << " : " << initTable->name);
                    LOG4("\t  Read unit for " << readField->name << " : " << readTable->name);
                    if (readTable != initTable)
                        phv.addMetadataDependency(readTable, initTable);
                }
            }
        }
    }

    LOG1("\tPrinting new dependencies to be inserted");
    for (auto kv : phv.getMetadataDeps())
        for (cstring t : kv.second)
            LOG1("\t  " << kv.first << " -> " << t);

    LOG1("\tPrinting reverse metadata deps");
    for (auto kv : phv.getReverseMetadataDeps()) {
        std::stringstream ss;
        ss << "\t  " << kv.first << " : ";
        for (auto t : kv.second)
            ss << t << " ";
        LOG1(ss.str());
    }
}

Visitor::profile_t ComputeDependencies::init_apply(const IR::Node* root) {
    const auto& fields = fieldsForInit.getComputeFieldsRequiringInit();
    const auto& livemap = liverange.getMetadataLiveMap();
    // Set of fields involved in metadata initialization whose usedef live ranges must be
    // considered.
    ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>> initFieldsToOverlappingFields;

    if (!phv.alloc_done())
        BUG("ComputeDependencies pass must be called after PHV allocation is complete.");

    // Generate the initFieldsToOverlappingFields map.
    // The key here is a field that must be initialized as part of live range shrinking; the values
    // are the set of fields that overlap with the key field, and so there must be dependencies
    // inserted from the reads of the value fields to the initializations inserted.
    for (const auto* f : fields) {
        // For each field, check the other slices overlapping with that field.
        f->foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
            auto slices = phv.get_slices_in_container(slice.container);
            for (auto& sl : slices) {
                if (slice == sl) continue;
                // If parser mutual exclusion, then we do not need to consider these fields for
                // metadata initialization.
                if (phv.isParserMutex(f, sl.field)) continue;
                // If slices do not overlap, then ignore.
                if (!slice.container_bits().overlaps(sl.container_bits()))
                    continue;
                // Check live range here.
                auto liverange1 = livemap.at(f->id);
                auto liverange2 = livemap.at(sl.field->id);
                if (liverange1.first <= liverange2.first || liverange1.second <= liverange2.first) {
                    LOG2("\t  Ignoring field " << sl.field->name << " (" << liverange2.first << ", "
                         << liverange2.second << ") overlapping with " << f->name << " (" <<
                         liverange1.first << ", " << liverange1.second << ") due to live ranges");
                    continue;
                }
                initFieldsToOverlappingFields[f].insert(sl.field);
            }
        });
    }

    for (auto kv : initFieldsToOverlappingFields) {
        LOG5("Initialize field " << kv.first->name);
        for (const auto* f : kv.second)
            LOG5("\t" << f->name);
    }

    // Generate init field to table map.
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Table*>> fieldsToTableInits;
    const auto& initMap = fieldsForInit.getAllActionInits();
    for (auto kv : initMap) {
        auto t = actionsMap.getTableForAction(kv.first);
        if (!t) BUG("Cannot find table corresponding to action %1%", kv.first->name);
        for (const auto& slice : kv.second) {
            fieldsToTableInits[slice.field].insert(*t);
        }
    }

    for (auto kv : fieldsToTableInits) {
        LOG5("Field " << kv.first->name);
        for (const auto* t : kv.second)
            LOG5("\tInit at: " << t->name);
    }

    noteDependencies(initFieldsToOverlappingFields, fieldsToTableInits);

    return Inspector::init_apply(root);
}


LiveRangeShrinking::LiveRangeShrinking(
        const PhvInfo& p,
        const FieldDefUse& u,
        const DependencyGraph& g,
        const PragmaNoInit& i,
        const MetadataLiveRange& l,
        const ActionPhvConstraints& a,
        const MauBacktracker& bt)
    : domTree(flowGraph),
      initNode(domTree, p, u, g, i.getFields(), tableActionsMap, l, a, tableMutex, flowGraph, bt) {
    addPasses({
        &tableMutex,
        &domTree,
        &tableActionsMap,
        &initNode
    });
}

AddMetadataInitialization::AddMetadataInitialization(
        PhvInfo& p,
        const FieldDefUse& d,
        const MetadataLiveRange& r)
    : fieldToExpr(p), init(p), dep(p, actionsMap, init, d, r) {
    addPasses({
        &actionsMap,
        &fieldToExpr,
        &init,
        new AddInitialization(fieldToExpr, init, actionsMap),
        &dep
    });
}
