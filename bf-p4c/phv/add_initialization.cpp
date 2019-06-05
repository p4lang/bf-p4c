#include "bf-p4c/phv/add_initialization.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"

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

const IR::MAU::Instruction*
MapFieldToExpr::generateInitInstruction(
        const MapFieldToExpr::AllocSlice& dest,
        const MapFieldToExpr::AllocSlice& source) const {
    const auto* dest_f = dest.field;
    BUG_CHECK(dest_f, "Field is nullptr in generateInitInstruction for dest %1%", dest);
    const auto* source_f = source.field;
    BUG_CHECK(source_f, "Field is nullptr in generateInitInstruction for source %1%", source);
    const IR::Expression* destExpr = getExpr(dest_f);
    const IR::Expression* sourceExpr = getExpr(source_f);
    if (dest.width != dest_f->size) {
        le_bitrange range = dest.field_bits();
        destExpr = new IR::Slice(destExpr, range.hi, range.lo);
    }
    if (source.width != source_f->size) {
        le_bitrange range = source.field_bits();
        sourceExpr = new IR::Slice(sourceExpr, range.hi, range.lo);
    }
    auto* prim = new IR::MAU::Instruction("set", { destExpr, sourceExpr });
    return prim;
}

Visitor::profile_t ComputeFieldsRequiringInit::init_apply(const IR::Node* root) {
    actionInits.clear();
    fieldsForInit.clear();
    for (auto& f : phv) {
        for (auto& slice : f.get_alloc()) {
            // For each alloc slice in the field, check if metadata initialization is required.
            if (slice.init_points.size() == 0) continue;
            LOG4("\t  Need to initialize " << f.name << " : " << slice);
            for (const auto* act : slice.init_points) {
                actionInits[act].push_back(slice);
                fieldsForInit.insert(slice.field);
                LOG4("\t\tInitialize at action " << act->name);
            }
        }
    }
    return Inspector::init_apply(root);
}

/** This pass determines all the fields to be initialized because of live range shrinking, and
  * adds the relevant initialization operation to the corresponding actions where those fields must
  * be initialized.
  */
class AddMetadataInitialization : public Transform {
 private:
    const MapFieldToExpr&                   fieldToExpr;
    const ComputeFieldsRequiringInit&       fieldsForInit;
    const MapTablesToActions&               actionsMap;

    ordered_map<PHV::FieldSlice, PHV::Allocation::ActionSet> initializedSlices;

    profile_t init_apply(const IR::Node* root) override {
        initializedSlices.clear();
        return Transform::init_apply(root);
    }

    const IR::MAU::Action* postorder(IR::MAU::Action* act) override {
        auto* act_orig = getOriginal<IR::MAU::Action>();
        auto fieldsToBeInited = fieldsForInit.getInitsForAction(act_orig);
        if (fieldsToBeInited.size() == 0) return act;
        // Deduplicate slices here. If they are allocated to the same container (as in the case of
        // deparsed-zero slices), then we only add one initialization to the action.
        ordered_map<PHV::Container, ordered_set<le_bitrange>> allocatedContainerBits;
        std::vector<MapFieldToExpr::AllocSlice> dedupFieldsToBeInitialized;
        for (auto& slice : fieldsToBeInited) {
            if (!allocatedContainerBits.count(slice.container)) {
                allocatedContainerBits[slice.container].insert(slice.container_bits());
                dedupFieldsToBeInitialized.push_back(slice);
                continue;
            }
            bool addInit = true;
            for (auto bits : allocatedContainerBits.at(slice.container)) {
                if (bits.contains(slice.container_bits()))
                    addInit = false;
            }
            if (!addInit) {
                LOG2("\t\tSlice " << slice << " does not need to be initialized because "
                     "another overlayed slice in the same container is also initialized in "
                     "this action.");
                continue;
            }
            dedupFieldsToBeInitialized.push_back(slice);
        }
        for (auto slice : dedupFieldsToBeInitialized) {
            auto* prim = fieldToExpr.generateInitInstruction(slice);
            if (!prim) {
                ::warning("Cannot add initialization for slice");
                continue;
            }
            act->action.push_back(prim);
            initializedSlices[PHV::FieldSlice(slice.field, slice.field_bits())].insert(act);
            if (LOGGING(4)) {
                auto tbl = actionsMap.getTableForAction(act_orig);
                if (!tbl)
                    LOG4("\t\tAdding metadata initialization instruction " << prim <<
                         " to action " << act->name << " without table");
                else
                    LOG4("\t\tAdding metadata initialization instruction " << prim <<
                         " to action " << act->name << ", in table " << (*tbl)->name);
            }
        }
        return act;
    }

    void end_apply() override {
        if (!LOGGING(2)) return;
        LOG2("\t  Printing all the metadata fields that need initialization with this allocation");
        for (auto& kv : initializedSlices) {
            LOG2("\t\t" << kv.first << " needing initialization at actions:");
            for (const auto* act : kv.second)
                LOG2("\t\t\t" << act->name);
        }
    }

 public:
    explicit AddMetadataInitialization(
            const MapFieldToExpr& e,
            const ComputeFieldsRequiringInit& i,
            const MapTablesToActions& a)
        : fieldToExpr(e), fieldsForInit(i), actionsMap(a) { }
};

Visitor::profile_t ComputeDarkInitialization::init_apply(const IR::Node* root) {
    actionToInsertedInsts.clear();
    return Inspector::init_apply(root);
}

void ComputeDarkInitialization::computeInitInstruction(
        const MapFieldToExpr::AllocSlice& slice,
        const IR::MAU::Action* action) {
    const IR::Primitive* prim;
    if (slice.init_i.assignZeroToDestination) {
        LOG4("\tAdd initialization from zero in action " << action->name << " for: " << slice);
        prim = fieldToExpr.generateInitInstruction(slice);
        LOG4("\t\tAdded initialization: " << prim);
    } else {
        BUG_CHECK(slice.init_i.source != nullptr,
                "No source slice defined for allocated slice %1%", slice);
        LOG4("\tAdd initialization in action " << action->name << " for: " << slice);
        LOG4("\t  Initialize from: " << *(slice.init_i.source));
        prim = fieldToExpr.generateInitInstruction(slice, *(slice.init_i.source));
        LOG4("\t\tAdded initialization: " << prim);
    }
    auto tbl = tableActionsMap.getTableForAction(action);
    if (!tbl) BUG("No table found corresponding to action %1%", action->name);
    cstring key = getKey(*tbl, action);
    actionToInsertedInsts[key].insert(prim);
}

void ComputeDarkInitialization::end_apply() {
    for (const auto& f : phv) {
        for (const auto& slice : f.get_alloc()) {
            // Ignore NOP initializations
            if (slice.init_i.nop) continue;
            // Initialization in last MAU stage will be handled directly by another pass.
            if (slice.init_i.alwaysInitInLastMAUStage) continue;
            for (const IR::MAU::Action* initAction : slice.init_i.init_actions)
                computeInitInstruction(slice, initAction);
        }
    }

    for (auto kv : actionToInsertedInsts) {
        LOG1("\tAction: " << kv.first);
        for (auto* prim : kv.second)
            LOG1("\t  " << prim);
    }
}

const ordered_set<const IR::Primitive*>
ComputeDarkInitialization::getInitializationInstructions(
        const IR::MAU::Table* tbl,
        const IR::MAU::Action* act) const {
    static ordered_set<const IR::Primitive*> rv;
    cstring key = getKey(tbl, act);
    if (!actionToInsertedInsts.count(key)) return rv;
    return actionToInsertedInsts.at(key);
}

class AddDarkInitialization : public Transform {
 private:
    const ComputeDarkInitialization& initReqs;

    IR::Node* preorder(IR::MAU::Action* action) override {
        const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
        auto insts = initReqs.getInitializationInstructions(tbl, action);
        for (auto* prim : insts) {
            action->action.push_back(prim);
            LOG4("Adding instruction " << prim << " to action " << action->name << " and table "
                 << (tbl ? tbl->name : "NO TABLE"));
        }
        return action;
    }

 public:
    explicit AddDarkInitialization(const ComputeDarkInitialization& d) : initReqs(d) { }
};

void ComputeDependencies::noteDependencies(
        const ordered_map<PHV::AllocSlice, ordered_set<PHV::AllocSlice>>& slices,
        const ordered_map<PHV::AllocSlice, ordered_set<const IR::MAU::Table*>>& initNodes) {
    for (auto& kv : slices) {
        if (!initNodes.count(kv.first)) continue;
        for (const auto* initTable : initNodes.at(kv.first)) {
            // initTable = Table where writeSlice is initialized.
            for (const auto& readSlice : kv.second) {
                // For each slice that shares containers with write slice (kv.first)
                for (auto& use : defuse.getAllUses(readSlice.field()->id)) {
                    const auto* readTable = use.first->to<IR::MAU::Table>();
                    if (!readTable) continue;
                    LOG5("\tInit unit for " << kv.first << " : " << initTable->name);
                    LOG5("\t  Read unit for " << readSlice << " : " << readTable->name);
                    if (readTable != initTable)
                        phv.addMetadataDependency(readTable, initTable);
                }
            }
        }
    }

    LOG1("\t  Printing new dependencies to be inserted");
    for (auto kv : phv.getMetadataDeps())
        for (cstring t : kv.second)
            LOG1("\t\t" << kv.first << " -> " << t);

    LOG3("\t  Printing reverse metadata deps");
    for (auto kv : phv.getReverseMetadataDeps()) {
        std::stringstream ss;
        ss << "\t\t" << kv.first << " : ";
        for (auto t : kv.second)
            ss << t << " ";
        LOG3(ss.str());
    }
}

Visitor::profile_t ComputeDependencies::init_apply(const IR::Node* root) {
    const auto& fields = fieldsForInit.getComputeFieldsRequiringInit();
    const auto& livemap = liverange.getMetadataLiveMap();
    // Set of fields involved in metadata initialization whose usedef live ranges must be
    // considered.
    ordered_map<PHV::AllocSlice, ordered_set<PHV::AllocSlice>> initSlicesToOverlappingSlices;

    if (!phv.alloc_done())
        BUG("ComputeDependencies pass must be called after PHV allocation is complete.");

    // Generate the initFieldsToOverlappingFields map.
    // The key here is a field that must be initialized as part of live range shrinking; the values
    // are the set of fields that overlap with the key field, and so there must be dependencies
    // inserted from the reads of the value fields to the initializations inserted.
    for (const auto* f : fields) {
        // For each field, check the other slices overlapping with that field.
        // FIXME(cc): check that this should always be the full pipeline. Or this should change
        // when we compute live ranges per stage
        f->foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
            auto slices = phv.get_slices_in_container(slice.container);
            for (auto& sl : slices) {
                if (slice == sl) continue;
                // If parser mutual exclusion, then we do not need to consider these fields for
                // metadata initialization.
                if (phv.isFieldMutex(f, sl.field)) continue;
                // If slices do not overlap, then ignore.
                if (!slice.container_bits().overlaps(sl.container_bits()))
                    continue;
                // Check live range here.
                auto liverange1 = livemap.at(f->id);
                auto liverange2 = livemap.at(sl.field->id);
                if (liverange1.first <= liverange2.first || liverange1.second <= liverange2.first) {
                    LOG3("\t  Ignoring field " << sl.field->name << " (" << liverange2.first << ", "
                         << liverange2.second << ") overlapping with " << f->name << " (" <<
                         liverange1.first << ", " << liverange1.second << ") due to live ranges");
                    continue;
                }
                PHV::AllocSlice initSlice(phv.field(slice.field->id), slice.container,
                        slice.field_bit, slice.container_bit, slice.width);
                PHV::AllocSlice overlappingSlice(phv.field(sl.field->id), sl.container,
                        sl.field_bit, sl.container_bit, sl.width);
                initSlicesToOverlappingSlices[initSlice].insert(overlappingSlice);
            }
        });
    }

    for (auto& kv : initSlicesToOverlappingSlices) {
        LOG5("  Initialize slice " << kv.first);
        for (auto& sl : kv.second)
            LOG5("\t" << sl);
    }

    // Generate init slice to table map.
    ordered_map<PHV::AllocSlice, ordered_set<const IR::MAU::Table*>> slicesToTableInits;
    const auto& initMap = fieldsForInit.getAllActionInits();
    for (auto kv : initMap) {
        auto t = actionsMap.getTableForAction(kv.first);
        if (!t) BUG("Cannot find table corresponding to action %1%", kv.first->name);
        for (const auto& slice : kv.second) {
            PHV::AllocSlice initSlice(phv.field(slice.field->name), slice.container,
                    slice.field_bit, slice.container_bit, slice.width);
            slicesToTableInits[initSlice].insert(*t);
        }
    }

    for (auto& kv : slicesToTableInits) {
        LOG5("  Initializing slice " << kv.first);
        for (const auto* t : kv.second)
            LOG5("\t" << t->name);
    }

    noteDependencies(initSlicesToOverlappingSlices, slicesToTableInits);

    if (Device::currentDevice() == Device::JBAY) addDepsForDarkInitialization();

    return Inspector::init_apply(root);
}

void ComputeDependencies::summarizeDarkInits(
        StageFieldUse& fieldWrites,
        StageFieldUse& fieldReads) {
    // Add all the initializations to be inserted for dark primitives to the fieldWrites and
    // fieldReads maps.
    for (auto& f : phv) {
        f.foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            if (alloc.init_i.init_actions.size() == 0) return;
            if (alloc.init_i.nop) return;
            if (alloc.init_i.alwaysInitInLastMAUStage) return;
            ordered_set<const IR::MAU::Table*> initTables;
            for (const auto* action : alloc.init_i.init_actions) {
                auto t = actionsMap.getTableForAction(action);
                BUG_CHECK(t, "No table corresponding to action %1%", action->name);
                initTables.insert(*t);
            }
            if (alloc.init_i.assignZeroToDestination) {
                for (const auto* t : initTables)
                    fieldWrites[&f][dg.min_stage(t)].insert(t);
            }
            if (alloc.init_i.source != nullptr) {
                const PHV::Field* src = alloc.init_i.source->field;
                for (const auto* t : initTables)
                    fieldReads[src][dg.min_stage(t)].insert(t);
            }
        });
    }
}

void ComputeDependencies::addDepsForDarkInitialization() {
    static PHV::FieldUse READ(PHV::FieldUse::READ);
    static PHV::FieldUse WRITE(PHV::FieldUse::WRITE);
    static std::pair<int, PHV::FieldUse> parserMin = std::make_pair(-1, READ);
    static std::pair<int, PHV::FieldUse> deparserMax = std::make_pair(Device::numStages(), WRITE);
    // Summarize use defs for all fields.
    StageFieldUse fieldWrites;
    StageFieldUse fieldReads;
    ordered_map<PHV::Container, std::vector<PHV::Field::alloc_slice>> containerToSlicesMap;
    ordered_map<const PHV::Field*, std::vector<PHV::Field::alloc_slice>> fieldToSlicesMap;
    for (auto& f : phv) {
        LOG5("\t" << f.name);
        fieldWrites[&f] = ordered_map<int, ordered_set<const IR::MAU::Table*>>();
        fieldReads[&f] = ordered_map<int, ordered_set<const IR::MAU::Table*>>();
        bool usedInParser = false, usedInDeparser = false;
        FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllDefs(f.id), fieldWrites[&f],
                usedInParser, usedInDeparser, false /* usePhysicalStages */);
        FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllUses(f.id), fieldReads[&f],
                usedInParser, usedInDeparser, false /* usePhysicalStages */);
        if (fieldWrites.at(&f).size() > 0) LOG5("\t  Write tables:");
        for (auto& kv : fieldWrites.at(&f))
            for (auto* t : kv.second)
                LOG5("\t\t" << kv.first << " : " << t->name);
        if (fieldReads.at(&f).size() > 0) LOG5("\t Read tables:");
        for (auto& kv : fieldReads.at(&f))
            for (auto* t : kv.second)
                LOG5("\t\t" << kv.first << " : " << t->name);
        f.foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            if (parserMin == alloc.min_stage && deparserMax == alloc.max_stage) return;
            containerToSlicesMap[alloc.container].push_back(alloc);
            fieldToSlicesMap[&f].push_back(alloc);
        });
    }
    summarizeDarkInits(fieldWrites, fieldReads);
    // Sort slices in each container according to liveness.
    for (auto& kv : containerToSlicesMap) {
        if (kv.second.size() == 1) continue;
        LOG5("\tContainer: " << kv.first);
        std::sort(kv.second.begin(), kv.second.end(),
                [](const PHV::Field::alloc_slice& lhs, const PHV::Field::alloc_slice& rhs) {
            return lhs.min_stage.first < rhs.min_stage.first;
        });
        addDepsForSetsOfAllocSlices(kv.second, fieldWrites, fieldReads);
    }
    for (auto& kv : fieldToSlicesMap) {
        if (kv.second.size() == 1) continue;
        LOG5("\tField: " << kv.first);
        std::sort(kv.second.begin(), kv.second.end(),
                [](const PHV::Field::alloc_slice& lhs, const PHV::Field::alloc_slice& rhs) {
            return lhs.min_stage.first < rhs.min_stage.first;
        });
        addDepsForSetsOfAllocSlices(kv.second, fieldWrites, fieldReads, false);
    }
}

void ComputeDependencies::addDepsForSetsOfAllocSlices(
        const std::vector<PHV::Field::alloc_slice>& alloc_slices,
        const StageFieldUse& fieldWrites,
        const StageFieldUse& fieldReads,
        bool checkBitsOverlap) {
    static PHV::FieldUse READ(PHV::FieldUse::READ);
    static PHV::FieldUse WRITE(PHV::FieldUse::WRITE);
    // XXX(Deep): Handle the case where:
    // C1[0] <-- f1 {1, 2}
    // C1[1] <-- f2 {1, 3}
    // C1 <-- f3 {3, 7}
    for (unsigned i = 0; i < alloc_slices.size(); ++i) {
        const PHV::Field::alloc_slice& alloc = alloc_slices.at(i);
        if (i + 1 == alloc_slices.size()) continue;
        if (!fieldWrites.count(alloc.field) && !fieldReads.count(alloc.field)) continue;
        ordered_set<const IR::MAU::Table*> allocUses;
        ordered_set<const IR::MAU::Table*> nextAllocUses;
        // Gather all the usedefs for alloc.
        if (fieldReads.count(alloc.field)) {
            int minStageRead = (alloc.min_stage.second == READ)
                ? alloc.min_stage.first : (alloc.min_stage.first + 1);
            for (auto stage = minStageRead; stage <= alloc.max_stage.first; ++stage) {
                if (!fieldReads.at(alloc.field).count(stage)) continue;
                for (const auto* t : fieldReads.at(alloc.field).at(stage))
                    allocUses.insert(t);
            }
        }
        if (fieldWrites.count(alloc.field)) {
            int maxStageWritten = (alloc.max_stage.second == WRITE)
                ? alloc.max_stage.first
                : (alloc.max_stage.first == 0 ? 0 : alloc.max_stage.first - 1);
            for (auto stage = alloc.min_stage.first; stage <= maxStageWritten; ++stage) {
                if (!fieldWrites.at(alloc.field).count(stage)) continue;
                for (const auto* t : fieldWrites.at(alloc.field).at(stage))
                    allocUses.insert(t);
            }
        }
        if (allocUses.size() > 0) {
            LOG5("\t\tInsert dependencies from following usedefs of " << alloc);
            for (const auto* t : allocUses)
                LOG5("\t\t\t" << t->name << " (Stage " << dg.min_stage(t) << ")");
        }

        // Find the initialization point for the next alloc slice.
        const PHV::Field::alloc_slice& nextAlloc = alloc_slices.at(i + 1);
        if (checkBitsOverlap && !nextAlloc.container_bits().overlaps(alloc.container_bits())) {
            LOG5("\t\tIgnoring alloc because the previous alloc and this one do not "
                    "overlap in the container.");
            continue;
        }
        if (!checkBitsOverlap && !nextAlloc.field_bits().overlaps(alloc.field_bits())) {
            LOG5("\t\tIgnoring alloc because the previous alloc belongs to a different "
                 "slice of the field.");
            continue;
        }
        if (nextAlloc.init_i.nop) {
            // Add all the uses of the field to the set of fields to which the dependencies must
            // be inserted.
            LOG5("\t\tAdd dependencies to all usedefs of " << nextAlloc);
            // Gather all usedefs for nextAlloc.
            if (fieldReads.count(nextAlloc.field)) {
                int minStageRead = (nextAlloc.min_stage.second == READ)
                    ? nextAlloc.min_stage.first : (nextAlloc.min_stage.first + 1);
                for (auto stage = minStageRead; stage <= nextAlloc.max_stage.first; ++stage) {
                    if (!fieldReads.at(nextAlloc.field).count(stage)) continue;
                    for (const auto* t : fieldReads.at(nextAlloc.field).at(stage))
                        nextAllocUses.insert(t);
                }
            }
            if (fieldWrites.count(nextAlloc.field)) {
                int maxStageWritten = (nextAlloc.max_stage.second == WRITE)
                    ? nextAlloc.max_stage.first
                    : (nextAlloc.max_stage.first == 0 ? 0 : nextAlloc.max_stage.first - 1);
                for (int stage = nextAlloc.min_stage.first; stage <= maxStageWritten; ++stage) {
                    if (!fieldWrites.at(nextAlloc.field).count(stage)) continue;
                    for (const auto* t : fieldWrites.at(nextAlloc.field).at(stage))
                        nextAllocUses.insert(t);
                }
            }
            for (const auto* t : nextAllocUses)
                LOG5("\t\t\t" << t->name << " (Stage " << dg.min_stage(t) << ")");
        } else if (nextAlloc.init_i.alwaysInitInLastMAUStage) {
            // No need for any dependencies here.
            LOG5("\t\tNo need to insert dependencies to the last always_init block.");
        } else if (nextAlloc.init_i.init_actions.size() > 0) {
            const IR::MAU::Table* initTable = nullptr;
            for (const auto* action : nextAlloc.init_i.init_actions) {
                auto tbl = actionsMap.getTableForAction(action);
                BUG_CHECK(tbl, "No table corresponding to action %1%", action->name);
                if (initTable)
                    BUG_CHECK(initTable == *tbl, "Multiple tables found for dark primitive");
                initTable = *tbl;
            }
            LOG5("\t\tAdd dependencies to initialization point " << initTable->name <<
                    " (Stage " << dg.min_stage(initTable) << ")");
            nextAllocUses.insert(initTable);
        }

        for (const auto* fromDep : allocUses) {
            for (const auto* toDep : nextAllocUses) {
                if (fromDep == toDep) continue;
                phv.addMetadataDependency(fromDep, toDep);
            }
        }
    }
}

AddSliceInitialization::AddSliceInitialization(
        PhvInfo& p,
        FieldDefUse& d,
        const DependencyGraph& g,
        const MetadataLiveRange& r)
    : fieldToExpr(p), init(p), dep(p, g, actionsMap, init, d, r),
      computeDarkInit(p, actionsMap, fieldToExpr) {
    addPasses({
        &actionsMap,
        &fieldToExpr,
        &init,
        new AddMetadataInitialization(fieldToExpr, init, actionsMap),
        Device::currentDevice() == Device::JBAY ? &computeDarkInit : nullptr,
        Device::currentDevice() == Device::JBAY
            ? new AddDarkInitialization(computeDarkInit) : nullptr,
        &dep
    });
}
