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

ordered_set<PHV::FieldSlice> CollectPhvLoggingInfo::getSlices(
                            const IR::Expression* fieldExpr,
                            const IR::MAU::Table* tbl) {
    // Set of FieldSlices matching the field uses specified by
    // the fieldExpr (action writes/action reads/input xbar uses)
    ordered_set<PHV::FieldSlice> slices;
    le_bitrange rng;
    auto* f = phv.field(fieldExpr, &rng);
    if (f == nullptr) return slices;
    PHV::FieldSlice fs(f, rng);
    slices.insert(fs);
    // See if there are field slice allocations for this field
    // and add those which intersect the field range
    f->foreach_alloc(rng, tbl, nullptr,
        [&](const PHV::AllocSlice as) {
        PHV::FieldSlice fs(as.field(), as.field_slice());
        slices.insert(fs);
    });
    return slices;
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
        auto writeSlices = getSlices(fieldAction.write.expr, tbl);
        for (auto sl : writeSlices) sliceWriteToActions[sl].insert(act);
        for (auto& readAction : fieldAction.reads) {
            if (readAction.type != ActionAnalysis::ActionParam::PHV)
                continue;
            auto readSlices = getSlices(readAction.expr, tbl);
            for (auto sl : readSlices) sliceReadToActions[sl].insert(act);
        }
    }
    return true;
}

bool CollectPhvLoggingInfo::preorder(const IR::MAU::TableKey* read) {
    const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
    if (tableNames.count(tbl->name) == 0) return true;
    auto xbarSlices = getSlices(read->expr, tbl);
    for (auto sl : xbarSlices)
        sliceXbarToTables[sl].insert(tableNames.at(tbl->name));
    return true;
}

void PhvLogging::end_apply(const IR::Node *root) {
    // Populate resources structures.
    populateContainerGroups("mau");
    populateContainerGroups("deparser");

    logHeaders();
    logFields();
    logContainers();
    logger.log();
    Logging::Manifest::getManifest().addLog(root->to<IR::BFN::Pipe>()->id, "phv", "phv.json");
}

PHV::Field::AllocState PhvLogging::getAllocatedState(
    const PHV::Field* f) {
    bitvec allocatedBits;
    bitvec phvAllocatedBits;
    bitvec clotAllocatedBits;
    f->foreach_alloc([&](const PHV::AllocSlice& alloc) {
        bitvec sliceBits(alloc.field_slice().lo, alloc.width());
        phvAllocatedBits |= sliceBits;
    });

    // Include bits that are CLOT-allocated.
    if (auto slice_clots = clot.slice_clots(f)) {
        for (auto entry : *slice_clots) {
            auto range = entry.first->range();
            bitvec sliceBits(range.lo, range.size());
            clotAllocatedBits |= sliceBits;
        }
    }

    allocatedBits = phvAllocatedBits | clotAllocatedBits;
    PHV::Field::AllocState rv = PHV::Field::EMPTY;
    if (!info.uses.is_referenced(f)) return rv;
    if (clotAllocatedBits.popcount() != 0) rv |= PHV::Field::HAS_CLOT_ALLOCATION;
    if (phvAllocatedBits.popcount() < f->size) rv |= PHV::Field::HAS_PHV_ALLOCATION;
    if (phvAllocatedBits.popcount() == f->size) rv |= PHV::Field::FULLY_PHV_ALLOCATED;
    return (rv | PHV::Field::REFERENCED);
}

ordered_map<cstring, ordered_set<const PHV::Field*>> PhvLogging::getFields() {
    ordered_map<cstring, ordered_set<const PHV::Field*>> fields;

    /* Determine set of all allocated fields and the headers to which they belong */
    for (const auto& f : phv)
        f.foreach_alloc([&](const PHV::AllocSlice& alloc) {
            (void)alloc;
            fields[f.header()].insert(&f);
        });
    return fields;
}

ordered_map<const PHV::Field*, const PHV::Field*> PhvLogging::getFieldAliases() {
    ordered_map<const PHV::Field*, const PHV::Field*> aliasMap;

    /* Check all allocated fields for their aliases to build a reverse alias map*/
    for (const auto& f : phv) {
        if (!f.aliasSource) continue;
        if (aliasMap.count(f.aliasSource) > 0) {
            // Should this be a BUG_CHECK? Ideally this behavior should be
            // caught during PHV analysis / allocation phase and we should not
            // fail during logging.
            LOG3(" Field : " << f << " has an alias : " << f.aliasSource <<
                    " which already exists in the alias map. This could be an"
                    " issue with aliasing as an alias source cannot have multiple"
                    " alias destinations");
            continue;
        }
        aliasMap[f.aliasSource] = &f;
    }
    return aliasMap;
}
Phv_Schema_Logger::FieldSlice*
PhvLogging::logFieldSlice(const PHV::Field* f, bool use_alias = false) {
    std::string fieldName = std::string(stripThreadPrefix(f->name));
    if (use_alias && f->aliasSource)
        fieldName = std::string(stripThreadPrefix(f->aliasSource->name));
    auto si = new Slice(0, f->size - 1);
    auto fs = new FieldSlice(fieldName, si);
    return fs;
}

Phv_Schema_Logger::FieldSlice*
PhvLogging::logFieldSlice(const PHV::AllocSlice& sl,
                            bool use_alias = false) {
    auto f = sl.field();
    std::string fieldName = std::string(stripThreadPrefix(f->name));
    if (use_alias && f->aliasSource)
        fieldName = std::string(stripThreadPrefix(f->aliasSource->name));
    auto si = new Slice(sl.field_slice().lo, sl.field_slice().hi);
    auto fs = new FieldSlice(fieldName, si);
    return fs;
}

Phv_Schema_Logger::ContainerSlice*
PhvLogging::logContainerSlice(const PHV::AllocSlice& sl,
                                bool use_alias = false) {
    const auto& phvSpec = Device::phvSpec();
    auto fs = logFieldSlice(sl, use_alias);
    auto ps = new Slice(sl.container_slice().lo, sl.container_slice().hi);
    auto cid = phvSpec.physicalAddress(phvSpec.containerToId(sl.container()),
                                                   PhvSpec::MAU);
    auto cs = new ContainerSlice(fs, cid, ps);

    ordered_set<PardeInfo> parde;
    // Add all the parser/deparser writes/reads.
    getAllParserDefs(sl.field(), parde);
    getAllDeparserUses(sl.field(), parde);

    // Add PARDE reads and writes.
    addPardeReadsAndWrites(sl.field(), parde, cs);

    // Add all the MAU reads/writes.
    PHV::FieldSlice slice(sl.field(), sl.field_slice());
    addTableKeys(slice, cs);
    addVLIWReads(slice, cs);
    addVLIWWrites(slice, cs);

    // Add the list of fields in the same container which are mutually exclusive
    // with this field
    addMutexFields(sl, cs);

    return cs;
}

void PhvLogging::logFields() {
    /// Map of all headers and their fields.
    ordered_map<cstring, ordered_set<const PHV::Field*>> fields = getFields();

    auto aliases = getFieldAliases();
    /* Add fields to the log file */
    for (auto kv : fields) {
        std::string headerName(stripThreadPrefix(kv.first));
        for (const auto* f : kv.second) {
            std::string fieldName(stripThreadPrefix(f->name));

            bool use_alias = (aliases.count(f) > 0);
            if (use_alias) {
                // Field is an alias, use info from original field
                f = aliases[f];
            }

            auto state = "";
            PHV::Field::AllocState allocState = getAllocatedState(f);
            if (!f->isReferenced(allocState)) state = "unreferenced";
            else if (!f->hasAllocation(allocState)) state = "unallocated";
            else if (f->partiallyPhvAllocated(allocState))
                state = "partially allocated";
            else if (f->fullyPhvAllocated(allocState))
                state = "allocated";

            LOG3("Field: " << fieldName << ", allocState: " <<
                allocState << ", state: " << state);

            auto fi = new FieldInfo(f->size, getFieldType(f), fieldName, getGress(f), "");
            auto field = new Field(fi, state, headerName);

            for (auto& sl : f->get_alloc()) {
                auto fs = logFieldSlice(sl, use_alias);
                field->append_field_slices(logFieldSlice(sl, use_alias));
                field->append_phv_slices(logContainerSlice(sl, use_alias));

                auto c = new Constraint(fs);
                auto s_loc = new SourceLocation("DummyFile", -1);

                if (f->srcInfo != boost::none) {
                    s_loc = new SourceLocation(std::string(f->srcInfo->toPosition().fileName),
                                              f->srcInfo->toPosition().sourceLine);
                }

                // Solitary Constraints
                if (sl.field()->is_solitary()) {
                    if (sl.field()->deparsed_bottom_bits()) {
                        auto sc = new SolitaryConstraint("last_byte",
                            "SOLITARY_LAST_BYTE: Can not pack field with any other field"
                            " in its non-full last byte",
                                    s_loc);
                        c->append(sc);
                    } else {
                        if (sl.field()->getSolitaryConstraint().isALU()) {
                            auto sc = new SolitaryConstraint("alu",
                                "SOLITARY: Can not pack field with any other field",
                                        s_loc);
                            c->append(sc);
                        } else if (sl.field()->getSolitaryConstraint().isDigest()) {
                            if (sl.field()->getDigestConstraint().isMirror()) {
                                auto sc = new SolitaryConstraint("mirror",
                                "SOLITARY_MIRROR: Cannot pack this field instance with"
                                " any field that is mirrored",
                                        s_loc);
                                c->append(sc);
                            } else if (sl.field()->getDigestConstraint().isLearning()) {
                                auto sc = new SolitaryConstraint("learning_digest",
                                "SOLITARY_EXCEPT_DIGEST: Cannot pack this field with"
                                " any other field that does not belong to the same"
                                " digest field lists",
                                        s_loc);
                                c->append(sc);
                            }
                        }
                    }
                }

                // Different Container Constraint
                if (sl.field()->is_solitary() && sl.field()->getSolitaryConstraint().isALU()) {
                    for (const auto* f2 : kv.second) {
                        if (sl.field() == f2) continue;
                        if (phv.isFieldNoPack(sl.field(), f2)) {
                            std::string fieldNamePack(stripThreadPrefix(f2->name));
                            auto fPack = new FieldInfo(f2->size, getFieldType(f2),
                                             fieldNamePack, getGress(f2), "");
                            auto s_loc_Pack = new SourceLocation("DummyFile", -1);
                            if (f2->srcInfo != boost::none) {
                                s_loc_Pack = new SourceLocation(
                                                std::string(f2->srcInfo->toPosition().fileName),
                                                f2->srcInfo->toPosition().sourceLine);
                            }
                            auto dcc = new DifferentContainerConstraint(fPack, s_loc_Pack,
                                       "alu",
                                       "DIFFERENT_CONTAINER: This field instance cannot"
                                       " be packed with another field instance",
                                       s_loc);
                            c->append(dcc);
                        }
                    }
                }

                if (c->get_ConstraintReason().size() > 0)
                    field->append_constraints(c);
            }

            logger.append_fields(field);
        }
    }
}

void PhvLogging::logHeaders() {
    /// Map of all headers and their fields.
    ordered_map<cstring, ordered_set<const PHV::Field*>> headerFields = getFields();
    /* Add header structures to the log file */
    for (auto kv : headerFields) {
        std::string headerName(stripThreadPrefix(kv.first));
        auto firstSlice = *kv.second.begin();
        auto* s = new Structure(getGress(firstSlice), headerName, "header");
        for (const auto* f : kv.second) {
            auto fs = logFieldSlice(f);
            s->append(fs); }
        logger.append_structures(s); }
}

void PhvLogging::populateContainerGroups(cstring groupType) {
    // Extract MAU group specific information from phvSpec
    const auto& phvSpec = Device::phvSpec();
    // TODO: Need to model and add "tagalong" resource type
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
    if (f->is_intrinsic()) return "imeta";  // All intrinsic fields are metadata
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
    if (f->is_intrinsic()) return "imeta";
    if (f->bridged) return "bridge";
    if (f->pov) return "pov";
    if (f->is_checksummed()) return "checksum";
    if (f->is_digest() && f->getDigestConstraint().isMirror()) return "mirror_digest";
    if (f->is_digest() && f->getDigestConstraint().isResubmit()) return "resubmit_digest";
    if (f->is_digest() && f->getDigestConstraint().isLearning()) return "learning_digest";
    if (f->is_digest() && f->getDigestConstraint().isPktGen()) return "pktgen";
    if (f->metadata && f->deparsed()) return "bridge";
    if (f->metadata && !f->deparsed()) return "none";
    if (!f->metadata) return "pkt";
    ::error("Unsupported deparser access type for %1%", f->name);
    return "none";
}

std::string PhvLogging::stripDotPrefix(const cstring name) const {
    // Check if the name starts with a '.' and strip it
    if (name[0] != '.') return name.c_str();
    return name.substr(1).c_str();
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

void
PhvLogging::addPardeReadsAndWrites(const PHV::Field* f, ordered_set<PhvLogging::PardeInfo>& rv,
                                   Phv_Schema_Logger::ContainerSlice *cs) const {
    LOG4("Adding parde reads and writes for Field: " << f);
    auto dType = getDeparserAccessType(f);
    std::for_each(rv.begin(), rv.end(),
                  [&](PardeInfo& entry) {
                      if (entry.unit == "parser") {
                          std::string parserStateName(stripThreadPrefix(entry.parserState));
                          cs->append_writes(new Access(ParserLocation("ibuf",
                                                                      parserStateName,
                                                                      entry.unit))); }
                      else if (entry.unit == "deparser" && strcmp(dType, "none") != 0)
                          cs->append_reads(new Access(DeparserLocation(dType,
                                                                       entry.unit)));
                  });
}

void
PhvLogging::addTableKeys(const PHV::FieldSlice &sl, Phv_Schema_Logger::ContainerSlice *cs) const {
    LOG4("Adding input xbar read for slice: " << sl);
    if (info.sliceXbarToTables.count(sl)) {
        for (auto& tableName : info.sliceXbarToTables.at(sl)) {
            if (tableAlloc.count(tableName) == 0)
                continue;
            for (int logicalID : tableAlloc.at(tableName))
                cs->append_reads(new Access(MAULocation("xbar",
                                                        logicalID/16,
                                                        "mau",
                                                        "" /* action_name */,
                                                        stripDotPrefix(tableName))));
        }
    }
}

void
PhvLogging::addVLIWReads(const PHV::FieldSlice& sl, Phv_Schema_Logger::ContainerSlice *cs) const {
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
            for (int logicalID : tableAlloc.at(tableName))
                cs->append_reads(new Access(MAULocation("vliw",
                                                        logicalID/16,
                                                        "mau",
                                                        stripDotPrefix(actionName),
                                                        stripDotPrefix(tableName))));
        }
    }
}

void
PhvLogging::addVLIWWrites(const PHV::FieldSlice& sl, Phv_Schema_Logger::ContainerSlice *cs) const {
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
            for (int logicalID : tableAlloc.at(tableName))
                cs->append_writes(new Access(MAULocation("vliw",
                                                         logicalID/16,
                                                         "mau",
                                                         stripDotPrefix(actionName),
                                                         stripDotPrefix(tableName))));
        }
    }
}

void PhvLogging::addMutexFields(const PHV::AllocSlice& sl,
                           Phv_Schema_Logger::ContainerSlice *cs) const {
    LOG4("Adding mutually exclusive fields for slice: " << sl);
    for (const auto* f2 : phv.fields_in_container(sl.container())) {
        if (phv.isFieldMutex(sl.field(), f2)) {
            std::string fieldName(stripThreadPrefix(f2->name));
            cs->append_mutually_exclusive_with(fieldName);
        }
    }
}

void PhvLogging::logContainers() {
    const auto& phvSpec = Device::phvSpec();
    // Populate container structures.
    ordered_map<const PHV::Container, ordered_set<PHV::AllocSlice>> allocation;
    auto aliases = getFieldAliases();
    for (auto& field : phv) {
        for (auto& slice : field.get_alloc())
            allocation[slice.container()].insert(slice); }

    for (auto kv : allocation) {
        auto c = kv.first;
        auto cid = phvSpec.physicalAddress(phvSpec.containerToId(c), PhvSpec::MAU);
        auto mauGroupId = -1;
        auto deparserGroupId = -1;
        if (c.is(PHV::Kind::tagalong)) {
            mauGroupId = phvSpec.getTagalongCollectionId(c);
            // TODO: Check what's the deparserGroupId for tagalong containers
            deparserGroupId = phvSpec.getTagalongCollectionId(c);
        } else {
            mauGroupId = phvSpec.mauGroupId(c);
            deparserGroupId = phvSpec.deparserGroupId(c);
        }
        // Get gress associated with the field slices in this container
        auto firstSlice = *kv.second.begin();
        auto containerEntry = new Container(c.size(), containerType(c),
                                            getGress(firstSlice.field()),
                                            deparserGroupId, mauGroupId,
                                            cid);
        for (auto sl : kv.second) {
            bool use_alias = (aliases.count(sl.field()) > 0);
            auto f = use_alias ? aliases[sl.field()] : sl.field();
            f->foreach_alloc([&](const PHV::AllocSlice& alloc) {
               if (alloc.container() == sl.container()
                    && alloc.field_slice().lo == sl.field_slice().lo
                    && alloc.container_slice().lo == sl.container_slice().lo
                    && alloc.width() == sl.width())
                    sl = alloc;
            });
            auto cs = logContainerSlice(sl, use_alias);
            containerEntry->append(cs);
        }
        logger.append_containers(containerEntry);
    }
}
