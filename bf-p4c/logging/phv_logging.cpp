#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/logging/manifest.h"
#include "bf-p4c/logging/phv_logging.h"

Visitor::profile_t CollectPhvLoggingInfo::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    sliceWriteToActions.clear();
    sliceReadToActions.clear();
    sliceXbarToTables.clear();
    actionsToTables.clear();
    tableNames.clear();
    return rv;
}

bool CollectPhvLoggingInfo::preorder(const IR::MAU::Table* tbl) {
    if (tbl->match_table && tbl->match_table->externalName())
        tableNames[tbl->name] = tbl->match_table->externalName();
    else
        tableNames[tbl->name] = tbl->name;
    return true;
}

bool CollectPhvLoggingInfo::preorder(const IR::MAU::Action* act) {
    const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
    if (actionsToTables.count(act) != 0)
        return true;   // action is in multiple tables. Even if that's
                       // the case, by the time we reach here it is
                       // irrelevant.
    actionsToTables[act] = tbl;
    // Call action analysis pass to gather information about field usage.
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap fieldActionsMap;
    aa.set_field_actions_map(&fieldActionsMap);
    act->apply(aa);

    for (auto& fieldAction : Values(fieldActionsMap)) {
        le_bitrange writeRange;
        auto* writeField = phv.field(fieldAction.write.expr, &writeRange);
        if (writeField == nullptr) continue;
        PHV::FieldSlice write(writeField, writeRange);
        sliceWriteToActions[write].insert(act);
        LOG4("Action " << act->name << " writes slice " << write);
        for (auto& readAction : fieldAction.reads) {
            if (readAction.type != ActionAnalysis::ActionParam::PHV)
                continue;
            le_bitrange readRange;
            auto* readField = phv.field(readAction.expr, &readRange);
            if (readField == nullptr) continue;
            PHV::FieldSlice read(readField, readRange);
            sliceReadToActions[read].insert(act);
        }
    }
    return true;
}

bool CollectPhvLoggingInfo::preorder(const IR::MAU::TableKey* read) {
    const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
    le_bitrange range;
    auto* field = phv.field(read->expr, &range);
    PHV::FieldSlice slice(field, range);
    if (tableNames.count(tbl->name) == 0) return true;
    sliceXbarToTables[slice].insert(tableNames.at(tbl->name));
    return true;
}

void PhvLogging::end_apply(const IR::Node *root) {
    // Populate resources structures.
    populateContainerGroups("mau");
    populateContainerGroups("deparser");

    logHeaders();
    logContainers();
    logger.log();
    Logging::Manifest::getManifest().addLog(root->to<IR::BFN::Pipe>()->id, "phv", "phv.json");
}

void PhvLogging::logHeaders() {
    /// Map of all headers and their fields.
    ordered_map<cstring, ordered_set<const PHV::Field*>> headerFields;

    /* Determine set of all allocated fields and the headers to which they belong */
    for (const auto& f : phv) {
        bitvec allocatedBits;
        f.foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            headerFields[f.header()].insert(&f);
            bitvec sliceBits(alloc.field_bit, alloc.width);
            allocatedBits |= sliceBits;
        });

        // Ignore unallocated fields if they are unreferenced.
        if (!info.uses.is_referenced(&f)) continue;

        // Include bits that are CLOT-allocated.
        if (auto allocated_slices = clot.allocated_slices(&f)) {
            for (auto entry : *allocated_slices) {
                auto range = entry.first->range();
                bitvec sliceBits(range.lo, range.size());
                allocatedBits |= sliceBits;
            }
        }

        bitvec allBitsInField(0, f.size);
        if (allocatedBits != allBitsInField) {
            int unallocated = 0;
            for (auto b : allocatedBits) {
                if (b > unallocated) {
                    le_bitrange unallocatedRange = StartLen(unallocated, b - unallocated);
                    PHV::FieldSlice unallocatedSlice(&f, unallocatedRange);
                    unallocatedSlices.insert(unallocatedSlice);
                }
                unallocated = b + 1;
            }
            if (unallocated < f.size) {
                le_bitrange unallocatedRange = StartLen(unallocated, f.size - unallocated);
                PHV::FieldSlice unallocatedSlice(&f, unallocatedRange);
                unallocatedSlices.insert(unallocatedSlice);
            }
        }
    }

    /* Add header structures to the log file */
    for (auto kv : headerFields) {
        std::string headerName(kv.first);
        auto* s = new Phv_Schema_Logger::Structures(headerName, "header");
        for (const auto* f : kv.second) {
            std::string fieldName(f->name);
            s->append(fieldName); }
        logger.append_structures(s); }
}

void PhvLogging::populateContainerGroups(cstring groupType) {
    // Extract MAU group specific information from phvSpec
    const auto& phvSpec = Device::phvSpec();
    auto phvGroup = groupType == "mau" ? PhvSpec::MAU : PhvSpec::DEPARSER;
    for (auto r : phvSpec.physicalAddressSpec(phvGroup)) {
        auto bit_width = int(r.first.size());
        for (unsigned block = 0; block < r.second.blocks; block++) {
            auto groupRes = new Resources(bit_width, std::string(groupType), r.second.blockSize);
            for (unsigned a = 0; a < r.second.blockSize; a++)
                groupRes->append(r.second.start + block * r.second.incr + a);
            logger.append_resources(groupRes);
        }
    }
}

/// @returns a string indicating the type of the container.
const char * PhvLogging::containerType(const PHV::Container c) const {
    if (c.is(PHV::Kind::normal)) return "normal";
    if (c.is(PHV::Kind::tagalong)) return "tagalong";
    if (c.is(PHV::Kind::mocha)) return "mocha";
    if (c.is(PHV::Kind::dark)) return "dark";
    ::error("Unsupported PHV container type for %1%", c);
    return "normal";
}

const char * PhvLogging::getFieldType(const PHV::Field* f) const {
    // How to identify compiler added fields ($?)
    if (f->padding) return "padding";
    if (f->bridged) return "bridged";
    if (f->metadata && f->is_intrinsic()) return "imeta";
    // if (f->privatized()) return Records::field_class_t::COMPILER_ADDED;
    if (f->metadata) return "meta";
    if (f->pov) return "pov";
    return "pkt";
}

const char * PhvLogging::getGress(const PHV::Field* f) const {
    if (f->gress == INGRESS) return "ingress";
    if (f->gress == EGRESS) return "egress";
    return "ghost";
}

const char * PhvLogging::getDeparserAccessType(const PHV::Field* f) const {
    if (f->metadata && f->is_intrinsic()) return "imeta";
    if (f->bridged) return "bridge";
    if (f->pov) return "pov";
    if (f->is_checksummed()) return "checksum";
    if (f->deparsed()) return "pkt";
    return "";
}

void
PhvLogging::getAllDeparserUses(const PHV::Field* f, ordered_set<PhvLogging::PardeInfo>& rv) const {
    if (f->padding) return;
    LOG4("Deparser uses of Field: " << f);
    for (const FieldDefUse::locpair use : defuse.getAllUses(f->id)) {
        const IR::BFN::Unit *use_unit = use.first;
        if (auto d = use_unit->to<IR::BFN::Deparser>()) {
            LOG4("    Used in " << d->toString());
            PardeInfo entry("deparser");
            rv.insert(entry);
        }
    }
}

void
PhvLogging::getAllParserDefs(const PHV::Field* f, ordered_set<PhvLogging::PardeInfo>& rv) const {
    if (f->padding) return;
    LOG4("Parser defs of Field: " << f);
    for (const FieldDefUse::locpair def : defuse.getAllDefs(f->id)) {
        const IR::BFN::Unit *def_unit = def.first;
        // If this is an implicit parser initialization added because of uninitialized reads, ignore
        // it.
        if (def.second->is<ImplicitParserInit>()) continue;
        if (auto ps = def_unit->to<IR::BFN::ParserState>()) {
            LOG4("    Defined in parser state " << ps->name);
            PardeInfo entry("parser", std::string(ps->name));
            rv.insert(entry);
        }
    }
}

void PhvLogging::addTableKeys(const PHV::FieldSlice &sl, PhvLogging::Records *r) const {
    auto dType = getDeparserAccessType(sl.field());
    LOG4("Adding input xbar read for slice: " << sl);
    if (info.sliceXbarToTables.count(sl)) {
        for (auto& tableName : info.sliceXbarToTables.at(sl)) {
            if (tableAlloc.count(tableName) == 0)
                continue;
            for (int stage : tableAlloc.at(tableName))
                r->append_reads(new Access(stage,
                                           "" /* action_name */,
                                           dType,
                                           "xbar",
                                           "" /* parser_state_name */,
                                           tableName.c_str()));
        }
    }
}

void PhvLogging::addVLIWReads(const PHV::FieldSlice& sl, PhvLogging::Records* r) const {
    auto dType = getDeparserAccessType(sl.field());
    LOG4("Adding VLIW Read for slice: " << sl);
    if (info.sliceReadToActions.count(sl)) {
        LOG4("  Found VLIW read for this slice");
        for (const IR::MAU::Action* act : info.sliceReadToActions.at(sl)) {
            if (info.actionsToTables.count(act) == 0)
                continue;
            const IR::MAU::Table* t = info.actionsToTables.at(act);
            if (info.tableNames.count(t->name) == 0)
                continue;
            std::string tableName(info.tableNames.at(t->name));
            std::string actionName(cstring(act->name));
            if (tableAlloc.count(tableName) == 0)
                continue;
            for (int stage : tableAlloc.at(tableName))
                r->append_reads(new Access(stage,
                                           actionName,
                                           dType,
                                           "vliw",
                                           "" /* parser_state_name */,
                                           tableName));
        }
    }
}

void PhvLogging::addVLIWWrites(const PHV::FieldSlice& sl, PhvLogging::Records* r) const {
    auto dType = getDeparserAccessType(sl.field());
    LOG4("Adding VLIW Write for slice: " << sl);
    if (info.sliceWriteToActions.count(sl)) {
        for (const IR::MAU::Action* act : info.sliceWriteToActions.at(sl)) {
            if (info.actionsToTables.count(act) == 0)
                continue;
            const IR::MAU::Table* t = info.actionsToTables.at(act);
            if (info.tableNames.count(t->name) == 0)
                continue;
            std::string tableName(info.tableNames.at(t->name));
            std::string actionName(cstring(act->name));
            LOG4("Table name in VLIW write: " << tableName);
            if (tableAlloc.count(tableName) == 0)
                continue;
            for (int stage : tableAlloc.at(tableName))
                r->append_writes(new Access(stage,
                                           actionName,
                                           dType,
                                           "vliw",
                                           "" /* parser_state_name */,
                                           tableName));
        }
    }
}

void PhvLogging::logContainers() {
    const auto& phvSpec = Device::phvSpec();
    // Populate container structures.
    ordered_map<const PHV::Container, std::vector<PHV::Field::alloc_slice>> allocation;
    for (auto& field : phv) {
        for (auto& slice : field.get_alloc())
            allocation[slice.container].emplace_back(slice); }

    for (auto kv : allocation) {
        auto c = kv.first;
        auto cid = phvSpec.physicalAddress(phvSpec.containerToId(c), PhvSpec::MAU);
        auto containerEntry = new Container(c.size(), containerType(c),
                                            phvSpec.deparserGroupId(c), phvSpec.mauGroupId(c),
                                            cid);
        for (auto sl : kv.second) {
            std::string fieldName(sl.field->name);
            auto r = new Records(getFieldType(sl.field),
                                 sl.field_bit, sl.field_hi(),
                                 fieldName,
                                 getGress(sl.field),
                                 sl.container_bit, sl.container_hi());
            ordered_set<PardeInfo> parde;
            // Add all the parser/deparser writes/reads.
            getAllParserDefs(sl.field, parde);
            getAllDeparserUses(sl.field, parde);
            auto dType = getDeparserAccessType(sl.field);
            std::for_each(parde.begin(), parde.end(),
                          [&](PardeInfo& entry) {
                              if (entry.unit == "parser")
                                  r->append_writes(new Access(entry.unit,
                                                              "" /* action_name */,
                                                              dType,
                                                              "ibuf",
                                                              entry.parserState));
                              else if (entry.unit == "deparser")
                                  r->append_reads(new Access(entry.unit,
                                                             "", /* action name */
                                                             dType));
                          });

            // Add all the MAU reads/writes.
            PHV::FieldSlice slice(sl.field, sl.field_bits());
            addTableKeys(slice, r);
            addVLIWReads(slice, r);
            addVLIWWrites(slice, r);

            containerEntry->append(r); }
        logger.append_containers(containerEntry);
    }
}
