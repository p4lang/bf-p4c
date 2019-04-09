#include "bf-p4c/phv/add_initialization.h"

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

    return Inspector::init_apply(root);
}

AddSliceInitialization::AddSliceInitialization(
        PhvInfo& p,
        FieldDefUse& d,
        const DependencyGraph& g,
        const MetadataLiveRange& r)
    : fieldToExpr(p), init(p), dep(p, g, actionsMap, init, d, r) {
    addPasses({
        &actionsMap,
        &fieldToExpr,
        &init,
        new AddMetadataInitialization(fieldToExpr, init, actionsMap),
        &dep
    });
}
