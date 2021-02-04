
#include <boost/range/irange.hpp>
#include <ctime>
#include <algorithm>

#include "common/asm_output.h"
#include "common/run_id.h"
#include "logging/manifest.h"
#include "mau/resource.h"
#include "mau/action_data_bus.h"
#include "mau/input_xbar.h"
#include "mau/instruction_memory.h"
#include "mau/memories.h"
#include "version.h"

#include "resources.h"
#include "resources_parser.h"
#include "resources_clot.h"

namespace BFN {

static std::string typeName(Memories::Use::type_t type) {
    switch (type) {
        case Memories::Use::EXACT:      return "match_entry_ram";
        case Memories::Use::ATCAM:      return "algorithmic_tcam";
        case Memories::Use::TERNARY:    return "ternary_match";
        case Memories::Use::GATEWAY:    return "gateway";
        case Memories::Use::TIND:       return "ternary_indirection_ram";
        case Memories::Use::COUNTER:    return "statistics_ram";
        case Memories::Use::METER:      return "meter_ram";
        case Memories::Use::STATEFUL:   return "stateful_ram";
        case Memories::Use::SELECTOR:   return "select_ram";
        case Memories::Use::ACTIONDATA: return "action_ram";
        case Memories::Use::IDLETIME:   return "idletime";
        default: BUG("Unknown memory type");
    }
}

static std::string stripLeadingDot(const std::string &str) {
    return str[0] == '.' ? str.substr(1) : str;
}

static std::string accumulateDetail(const std::set<std::string> &detail) {
    std::string result = *detail.begin();
    std::for_each(++(detail.begin()), detail.end(), [&](const std::string &s) {
        result += ", " + s; });
    return result;
}

static ResourcesLogging::PhvResourceUsage *logPhvContainers(const PhvSpec &spec) {
    using PhvContainerType = Resources_Schema_Logger::PhvContainerType;

    auto result = new ResourcesLogging::PhvResourceUsage();

    // Map the type to the available container addresses.
    std::map<PHV::Type, std::vector<int>> containersByType;
    for (auto cid : spec.physicalContainers()) {
        auto c = spec.idToContainer(cid);
        auto addr = spec.physicalAddress(cid, PhvSpec::MAU);
        containersByType[c.type()].push_back(addr);
    }

    // Build PhvContainerType JSON objects for each container type.
    for (auto kind : spec.containerKinds()) {
        for (auto size : spec.containerSizes()) {
            auto &addresses = containersByType[PHV::Type(kind, size)];
            if (!addresses.size()) continue;

            const auto units = addresses.size();
            const auto width = int(size);
            auto pct = new PhvContainerType(units, width);
            pct->get_addresses().insert(pct->get_addresses().end(),
                                        addresses.begin(),
                                        addresses.end());

            switch (kind) {
            case PHV::Kind::normal:
                result->append_normal(pct); break;
            case PHV::Kind::tagalong:
                result->append_tagalong(pct); break;
            case PHV::Kind::mocha:
                result->append_mocha(pct); break;
            case PHV::Kind::dark:
                result->append_dark(pct); break;
            default:
                BUG("Unknown PHV container kind");
            }
        }
    }

    return result;
}

void ResourcesLogging::XbarByteResource::append(const std::string &ub,
                                                const std::string &uf,
                                                const std::string &d) {
    usedBy.insert(stripLeadingDot(ub));
    usedFor.insert(stripLeadingDot(uf));
    detail.insert(stripLeadingDot(d));
}

void ResourcesLogging::HashBitResource::append(std::string ub,
                                               const std::string &uf,
                                               const std::string &d) {
    ub = stripLeadingDot(ub);

    if (!usedBy.empty()) {
        BUG_CHECK(usedBy == ub, "Only one value allowed for a node type %s %s %s",
            ub.c_str(), uf.c_str(), d.c_str());
    }

    usedBy = ub;
    usedFor.insert(stripLeadingDot(uf));
    detail.insert(stripLeadingDot(d));
}

void ResourcesLogging::HashDistResource::append(const std::string &ub, const std::string &uf) {
    usedBy.insert(stripLeadingDot(ub));
    usedFor.insert(stripLeadingDot(uf));
}

void ResourcesLogging::ActionBusByteResource::append(const std::string &ub) {
    usedBy.insert(stripLeadingDot(ub));
}

void ResourcesLogging::IMemColorResource::append(const std::string &ub, const std::string &d) {
    usedBy.insert(stripLeadingDot(ub));
    detail.insert(stripLeadingDot(d));
}

bool ResourcesLogging::preorder(const IR::BFN::Pipe *p) {
    stageResources.clear();

    ParserResourcesLogging pvis;
    p->apply(pvis);
    parserResources = pvis.getLogger();

    ClotResourcesLogging cvis(clotInfo);
    p->apply(cvis);
    clotResources = cvis.getLoggers();

    return true;
}

bool ResourcesLogging::preorder(const IR::MAU::Table *tbl) {
    cstring tblName = "";
    if (!tbl->match_table) {
        if (!tbl->conditional_gateway_only()) {
            LOG1("Can't find name for table" << *tbl);
            return true;
        } else {
            tblName = tbl->build_gateway_name();
        }
    } else {
        tblName = canon_name(tbl->match_table->externalName());
    }
    collectTableUsage(tblName, tbl);
    return true;
}

void ResourcesLogging::end_apply(const IR::Node *root) {
    using MauResources = Resources_Schema_Logger::MauResources;

    auto mauResources = new MauResources(Device::numStages());
    int stages = stageResources.size();
    for (auto s : boost::irange(0, stages)) {
        auto stageLog = logStage(s);
        mauResources->append(stageLog);
    }

    auto phvContainers = logPhvContainers(Device::phvSpec());

    auto resources = new ResourceUsage(
        mauResources,
        parserResources,
        phvContainers);

    // Output clot info for JBAY
    for (auto &cp : clotResources) resources->append_clots(cp);

    auto logger = new Resources_Schema_Logger(
        filePath.c_str(),
        Logging::Logger::buildDate(),
        BF_P4C_VERSION,
        BackendOptions().programName + ".p4",
        RunId::getId(),
        RESOURCES_SCHEMA_VERSION,
        resources);

    logger->log();
    Logging::Manifest::getManifest().addResources(root->to<IR::BFN::Pipe>()->id, manifestPath);
}

void ResourcesLogging::collectTableUsage(cstring name, const IR::MAU::Table *table) {
    LOG1("collectTableUsage: " << name);
    if (!table->global_id()) {
        // \TODO: for partial allocation, we'll eventually need to list all the
        // tables, including the ones that are not allocated in the resources node.
        // For now, we just ignore them, rather than issuing an error
        // P4C_UNIMPLEMENTED("visualization of un-allocated tables not yet implemented (%1%: %2%)",
        //                  name, table->logical_id);
        return;
    }

    unsigned stage = table->stage();
    // Ensure there is enough space to log information to
    if (stage >= stageResources.size()) stageResources.resize(stage + 1);
    auto logicalTableId = *table->global_id();  // table name is 'name'
    const TableResourceAlloc *alloc = table->resources;

    if (stageResources[stage].logicalIds.count(logicalTableId)) {
        BUG("Logical id: %d is used twice in stage: %d", logicalTableId, stage);
    }
    stageResources[stage].logicalIds[logicalTableId] = name;

    LOG3("\tadding resource table: " << name);

    stageResources[stage].memories.push_back(MemoriesResource(name, alloc));

    collectXbarBytesUsage(stage, alloc->match_ixbar);
    collectXbarBytesUsage(stage, alloc->salu_ixbar);
    collectXbarBytesUsage(stage, alloc->meter_ixbar);
    collectXbarBytesUsage(stage, alloc->selector_ixbar);
    collectXbarBytesUsage(stage, alloc->gateway_ixbar);

    for (auto &hash_dist : alloc->hash_dists) {
        collectHashDistUsage(stage, hash_dist);
    }

    collectActionBusBytesUsage(stage, alloc, name);

    // TODO action slots

    collectVliwUsage(stage, alloc->instr_mem, table->gress, name);

    LOG1("collectTableUsage: " << name << " done!");
}

void ResourcesLogging::collectXbarBytesUsage(unsigned int stage, const IXBar::Use &alloc) {
    if (alloc.use.empty())
        return;

    auto &stageResource = stageResources[stage];

    LOG2("add_xbar_bytes_usage (stage=" << stage << "), table: " << alloc.used_by);
    for (auto &byte : alloc.use) {
        LOG3("\tadding resource: xbar bytes " << byte.loc.getOrd(alloc.ternary));
        stageResource.xbarBytes[byte.loc.getOrd(alloc.ternary)].append(
            alloc.used_by,
            alloc.used_for(),
            byte.visualization_detail());
    }

    // Used for the upper 12 bits of gateways
    for (auto &bits : alloc.bit_use) {
        for (int b = 0; b < bits.width; b++) {
            int bit = bits.bit + b + IXBar::HASH_INDEX_GROUPS * TableFormat::RAM_GHOST_BITS;
            auto key = std::make_pair(bit, bits.group);

            /*LOG3("\tadding resource hash_bits from bit_use(" << bit << ", " << bits.group
                  << "): {" << std::to_string(hbr) << "}");*/
            stageResource.hashBits[key].append(
                alloc.used_by,
                alloc.used_for(),
                bits.field + std::to_string(bits.lo + b));
        }
    }

    // Used for the bits to do exact match/atcam match
    int wayIndex = 0;
    for (auto &way : alloc.way_use) {
        for (int bitOffset = 0; bitOffset < IXBar::RAM_LINE_SELECT_BITS; bitOffset++) {
            int bit = bitOffset + way.slice * IXBar::RAM_LINE_SELECT_BITS;
            auto key = std::make_pair(bit, way.group);

            /*LOG3("\tadding resource hash_bits from way_use(" << bit << ", " << way.group
                 << "): {" << std::to_string(hbr) << "}");*/
            stageResource.hashBits[key].append(
                alloc.used_by,
                alloc.used_for(),
                "Hash Way " + std::to_string(wayIndex) + " RAM line select");
        }

        for (auto bit : bitvec(way.mask)) {
            bit += IXBar::RAM_SELECT_BIT_START;
            auto key = std::make_pair(bit, way.group);

            /*LOG3("\tadding resource hash_bits from way_use(" << bit << ", " << way.group
                 << "): {" << std::to_string(hbr) << "}");*/
            stageResource.hashBits[key].append(
                alloc.used_by,
                alloc.used_for(),
                "Hash Way " + std::to_string(wayIndex) + " RAM select");
        }

        wayIndex++;
    }

    // Used for the bits provided to the selector
    if (alloc.meter_alu_hash.allocated) {
        auto &mah = alloc.meter_alu_hash;
        for (auto bit : mah.bit_mask) {
            auto key = std::make_pair(bit, mah.group);

            /*LOG3("\tadding resource hash_bits from select_use(" << bit << ", " << mah.group
                 << "): {" << std::to_string(hbr) << "}");*/
            stageResource.hashBits[key].append(
                alloc.used_by,
                alloc.used_for(),
                "Selection Hash Bit " + std::to_string(bit));
        }
    }
    // Used for the bits for hash distribution
    auto &hdh = alloc.hash_dist_hash;
    if (hdh.allocated) {
        for (auto bit : hdh.galois_matrix_bits) {
            int position = -1;
            for (auto bit_start : hdh.galois_start_bit_to_p4_hash) {
                int init_hb = bit_start.first;
                auto br = bit_start.second;
                if (bit >= init_hb && bit < init_hb + br.size())
                    position = br.lo + (bit - init_hb);
            }
            auto key = std::make_pair(bit, hdh.group);

            /*LOG3("\tadding resource hash_bits from hash_dist(" << bit << ", " << hdh.group
                 << "): {" << std::to_string(hbr) << "}");*/
            stageResource.hashBits[key].append(
                alloc.used_by,
                alloc.used_for(),
                "Hash Dist Bit " + std::to_string(position));
        }
    }

    LOG2("add_xbar_bytes_usage (stage=" << stage << "), table: " << alloc.used_by << " done!");
}

void ResourcesLogging::collectHashDistUsage(unsigned int stage, const IXBar::HashDistUse &hdUse) {
    for (auto &irAlloc : hdUse.ir_allocations) {
        collectXbarBytesUsage(stage, irAlloc.use);
    }

    int hashId = hdUse.unit / IXBar::HASH_DIST_SLICES;
    int unitInHashId = hdUse.unit % IXBar::HASH_DIST_SLICES;
    auto key = std::make_pair(hashId, unitInHashId);

    LOG2("add_hash_dist_usage (stage=" << stage << "), table: " << hdUse.used_by
         << " done!");
    stageResources[stage].hashDist[key].append(hdUse.used_by.c_str(), hdUse.used_for());
}

void ResourcesLogging::collectActionBusBytesUsage(unsigned int stage,
                                                  const TableResourceAlloc *res,
                                                  cstring tableName) {
    auto &action_data_xbar = res->action_data_xbar;
    auto &meter_xbar = res->meter_xbar;

    for (auto &rs : action_data_xbar.action_data_locs) {
        int byte_sz = ActionData::slot_type_to_bits(rs.location.type) / 8;
        for (auto i = 0; i < byte_sz; i++) {
            stageResources[stage].actionBusBytes[rs.location.byte+i].append(tableName.c_str());
        }
    }

    for (auto &rs : meter_xbar.action_data_locs) {
        int byte_sz = ActionData::slot_type_to_bits(rs.location.type) / 8;
        for (auto i = 0; i < byte_sz; i++) {
            stageResources[stage].actionBusBytes[rs.location.byte+i].append(tableName.c_str());
        }
    }

    LOG2("add_action_bus_bytes_usage (stage=" << stage << "), table :" << tableName << " done!");
}

void ResourcesLogging::collectVliwUsage(unsigned int stage, const InstructionMemory::Use &alloc,
                                   gress_t gress, cstring tableName) {
    for (auto &entry : alloc.all_instrs) {
        auto instr = entry.second;
        int row = instr.row;

        IMemColorResource imr;
        imr.color = instr.color;
        imr.gress = gress;
        imr.append(tableName.c_str(), entry.first.c_str());  // used by, detail

        bool shared_slot = false;
        for (auto& r : stageResources[stage].imemColor[row]) {
            if (r.color == imr.color && r.gress == imr.gress)  {
                r. append(tableName.c_str(), entry.first.c_str());  // used by, detail
                shared_slot = true;
                break;
            }
        }

        if (shared_slot)
            continue;

        stageResources[stage].imemColor[row].push_back(imr);
    }

    LOG2("add_vliw_usage (stage=" << stage << "), table :" << tableName << " done!");
}

ResourcesLogging::XbarResourceUsage *ResourcesLogging::logXbarBytes(unsigned stageNo) const {
    using XbarByteUsage = Resources_Schema_Logger::XbarByteUsage;

    const auto exactSize = IXBar::EXACT_GROUPS * IXBar::EXACT_BYTES_PER_GROUP;
    const auto ternarySize = IXBar::BYTE_GROUPS * IXBar::TERNARY_BYTES_PER_BIG_GROUP;
    const auto size = exactSize + ternarySize;

    auto xr = new XbarResourceUsage(exactSize, size, ternarySize);

    for (auto &kv : stageResources[stageNo].xbarBytes) {
        const auto byteNumber = kv.first;
        const std::string byteType = (byteNumber >= exactSize) ? "ternary" : "exact";
        const auto &use = kv.second;
        const auto detail = accumulateDetail(use.detail);

        auto xb = new XbarByteUsage(byteNumber, byteType);

        // Perform cross product of used by/used for and assign
        // all results the same aggregated detail
        for (auto &ub : use.usedBy) {
            for (auto &uf : use.usedFor) {
                auto eu = new ElementUsage(ub, detail, uf);
                xb->append(eu);
            }
        }

        xr->append(xb);
    }

    return xr;
}

ResourcesLogging::HashBitsResourceUsage *ResourcesLogging::logHashBits(unsigned stageNo) const {
    using HashBitUsage = Resources_Schema_Logger::HashBitUsage;

    const auto nBits = 10 * IXBar::HASH_INDEX_GROUPS + IXBar::HASH_SINGLE_BITS;
    const auto nFunctions = IXBar::HASH_GROUPS;

    auto hbru = new HashBitsResourceUsage(nBits, nFunctions);

    for (auto &kv : stageResources[stageNo].hashBits) {
        const auto hashBitNumber = kv.first.first;
        const auto hashFunction = kv.first.second;
        const auto &use = kv.second;
        const auto detail = accumulateDetail(use.detail);

        auto hbu = new HashBitUsage(hashBitNumber, hashFunction);

        for (auto &uf : use.usedFor) {
            auto eu = new ElementUsage(use.usedBy, detail, uf);
            hbu->append(eu);
        }

        hbru->append(hbu);
    }

    return hbru;
}

ResourcesLogging::HashDistResourceUsage *ResourcesLogging::logHashDist(unsigned stageNo) const {
    using HashDistUnitUsage = Resources_Schema_Logger::HashDistributionUnitUsage;

    const auto nHashIds = IXBar::HASH_DIST_UNITS;
    const auto nUnitIds = IXBar::HASH_DIST_SLICES;

    auto hdru = new HashDistResourceUsage(nHashIds, nUnitIds);

    for (auto &kv : stageResources[stageNo].hashDist) {
        const auto hashId = kv.first.first;
        const auto unitId = kv.first.second;
        const auto &use = kv.second;

        auto hduu = new HashDistUnitUsage(hashId, unitId);

        for (auto &ub : use.usedBy) {
            for (auto &uf : use.usedFor) {
                auto eu = new ElementUsage(ub, "", uf);
                hduu->append(eu);
            }
        }

        hdru->append(hduu);
    }

    return hdru;
}

void ResourcesLogging::logMemories(unsigned int stageNo, RamResourceUsage *ramsRes,
                    MapRamResourceUsage *mapRamsRes, GatewayResourceUsage *gatewaysRes,
                    StashResourceUsage *stashesRes, MeterAluResourceUsage *meterRes,
                    StatisticAluResourceUsage *statisticsRes, TcamResourceUsage *tcamsRes) const {
    using GatewayUsage = Resources_Schema_Logger::GatewayUsage;
    using MapRamUsage = Resources_Schema_Logger::MapRamUsage;
    using MeterAluUsage = Resources_Schema_Logger::MeterAluUsage;
    using RamUsage = Resources_Schema_Logger::RamUsage;
    using StashUsage = Resources_Schema_Logger::StashUsage;
    using StatisticAluUsage = Resources_Schema_Logger::StatisticAluUsage;
    using TcamUsage = Resources_Schema_Logger::TcamUsage;

    for (auto &res : stageResources[stageNo].memories) {
        for (auto &use : res.use->memuse) {
            Memories::Use memuse = use.second;
            std::string usedBy = stripLeadingDot(memuse.used_by);
            std::string usedFor = typeName(memuse.type);

            LOG3("MemUse: (" << res.tableName << ", p4name: " << usedBy
                 << " " << memuse.type << ")");
            switch (memuse.type) {
            case Memories::Use::EXACT:
            case Memories::Use::ATCAM:
            case Memories::Use::TIND:
            case Memories::Use::ACTIONDATA:
                for (auto &r : memuse.row) {
                    for (auto &col : r.col) {
                        int way = memuse.get_way(r.row, col);
                        auto ru = new RamUsage(col, r.row, (way != -1 ? new int(way): nullptr));
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        ru->append(eu);
                        ramsRes->append(ru);
                    }

                    auto stashUnit = r.stash_unit;
                    if (stashUnit == 0 || stashUnit == 1) {
                        auto su = new StashUsage(r.row, stashUnit);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        su->append(eu);
                        stashesRes->append(su);
                    }
                }
                break;
            case Memories::Use::TERNARY:
                for (auto &r : memuse.row)
                    for (auto &c : r.col) {
                        auto tu = new TcamUsage(c, r.row);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        tu->append(eu);
                        tcamsRes->append(tu);
                    }
                LOG1("TCAMS");
                break;
            case Memories::Use::GATEWAY: {
                auto row = memuse.row[0].row;
                auto unit = memuse.gateway.unit;
                auto gu = new GatewayUsage(row, unit);
                auto eu = new ElementUsage(usedBy, "", usedFor);
                gu->append(eu);
                gatewaysRes->append(gu);
                break; }
            case Memories::Use::COUNTER:
            case Memories::Use::METER:
            case Memories::Use::STATEFUL:
            case Memories::Use::SELECTOR:
                // meters and stats
                if (!memuse.home_row.empty()) {
                    auto row = memuse.home_row.at(0).first / 2;
                    auto eu = new ElementUsage(usedBy, "", usedFor);

                    if (memuse.type == Memories::Use::COUNTER) {
                        auto sau = new StatisticAluUsage(row);
                        sau->append(eu);
                        statisticsRes->append(sau);
                    } else {
                        auto mau = new MeterAluUsage(row);
                        mau->append(eu);
                        meterRes->append(mau);
                    }
                }

                // rams and map rams
                for (auto &r : memuse.row) {
                    for (auto &col : r.col) {
                        auto ru = new RamUsage(col, r.row);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        ru->append(eu);
                        ramsRes->append(ru);
                    }

                    for (auto unit_id : r.mapcol) {
                        auto mru = new MapRamUsage(r.row, unit_id);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        mru->append(eu);
                        mapRamsRes->append(mru);
                    }
                }

                // color map rams
                for (auto &r : memuse.color_mapram)
                    for (auto &unit_id : r.col) {
                        auto mru = new MapRamUsage(r.row, unit_id);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        mru->append(eu);
                        mapRamsRes->append(mru);
                    }
                break;
            case Memories::Use::IDLETIME:
                for (auto &r : memuse.row)
                    for (auto &unit_id : r.col) {
                        auto mru = new MapRamUsage(r.row, unit_id);
                        auto eu = new ElementUsage(usedBy, "", usedFor);
                        mru->append(eu);
                        mapRamsRes->append(mru);
                    }
                break;
            default:
                BUG("Unhandled memory use type %d in ResourcesLogging::gen_memories", memuse.type);
            }
        }
    }
}

ResourcesLogging::LogicalTableResourceUsage* ResourcesLogging::logLogicalTables(int stage) const {
    using LogicalTableUsage = Resources_Schema_Logger::LogicalTableUsage;

    auto logicalRes = new LogicalTableResourceUsage(StageUse::MAX_LOGICAL_IDS);  // size
    for (auto &lid : stageResources[stage].logicalIds) {
        const int id = lid.first % StageUse::MAX_LOGICAL_IDS;
        auto ltu = new LogicalTableUsage(id);
        auto eu = new ElementUsage(lid.second.c_str());  // used_by
        ltu->append(eu);
        logicalRes->append(ltu);
    }

    return logicalRes;
}

ResourcesLogging::ActionDataResourceUsage*
ResourcesLogging::logActionBusBytes(unsigned int stageNo) const {
    using ActionDataByteUsage = Resources_Schema_Logger::ActionDataByteUsage;

    const int size = ActionDataBus::ADB_BYTES;

    auto adru = new ActionDataResourceUsage(size);

    for (auto &kv : stageResources[stageNo].actionBusBytes) {
        const auto byteNumber = kv.first;
        const auto &use = kv.second;

        auto adbu = new ActionDataByteUsage(byteNumber);

        for (auto &usedBy : use.usedBy) {
            auto eu = new ElementUsage(usedBy);
            adbu->append(eu);
        }

        adru->append(adbu);
    }

    return adru;
}

void ResourcesLogging::logActionSlots(MauStageResourceUsage *msru) const {
    using ActionSlotUsage = Resources_Schema_Logger::ActionSlotUsage;

    // \TODO: where do we get these ones from?
    for ( auto slot : { 8, 16, 32} ) {
        const int maximum_slots = 32;
        const int number_used = 0;
        auto asu = new ActionSlotUsage(maximum_slots, number_used, slot);
        msru->append(asu);
    }
}

ResourcesLogging::VliwResourceUsage* ResourcesLogging::logVliw(unsigned int stageNo) const {
    using VliwColorUsage = Resources_Schema_Logger::VliwColorUsage;
    using VliwUsage = Resources_Schema_Logger::VliwUsage;

    const int size = InstructionMemory::IMEM_ROWS;

    auto vru = new VliwResourceUsage(size);

    for (auto &kv : stageResources[stageNo].imemColor) {
        const auto instructionNumber = kv.first;

        auto vu = new VliwUsage(instructionNumber);

        for (auto &use : kv.second) {
            auto vcu = new VliwColorUsage(use.color, toString(use.gress).c_str());

            auto detail = accumulateDetail(use.detail);
            for (auto &ub : use.usedBy) {
                auto eu = new ElementUsage(ub, detail);
                vcu->append(eu);
            }

            vu->append(vcu);
        }

        vru->append(vu);
    }

    return vru;
}

ResourcesLogging::ExactMatchSearchBusResourceUsage*
ResourcesLogging::logExactMemSearchBuses(unsigned int stageNo) const {
    using ExactMatchSearchBusUsage = Resources_Schema_Logger::ExactMatchSearchBusUsage;

    const int size = 2 * Memories::SRAM_ROWS;

    auto emsbru = new ExactMatchSearchBusResourceUsage(size);

    std::map<int, ExactMatchSearchBusUsage*> idToUsages;  // for sharing buses
    for (auto &res : stageResources[stageNo].memories) {
        for (auto &use : res.use->memuse) {
            auto memuse = use.second;
            auto usedFor = typeName(memuse.type);

            // While there are search buses available for selectors, these
            // are separate from exact match search buses, which is what is
            // referred to here.
            switch (memuse.type) {
            case Memories::Use::EXACT:
            case Memories::Use::ATCAM:
            case Memories::Use::GATEWAY: {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                if (bus < 0) break;
                int id = 2 * row + (bus & 1);

                if (idToUsages.count(id) == 0) {
                    idToUsages[id] = new ExactMatchSearchBusUsage(id);
                }

                auto usedBy = res.tableName.substr(res.tableName[0] == '.' ? 1 : 0);
                auto eu = new ElementUsage(usedBy, "", usedFor);
                idToUsages[id]->append(eu);
                break;
            }
            default: break;
            }
        }
    }

    for (auto &kv : idToUsages) {
        emsbru->append(kv.second);
    }

    return emsbru;
}

ResourcesLogging::ExactMatchResultBusResourceUsage*
ResourcesLogging::logExactMemResultBuses(unsigned int stageNo) const {
    using ExactMatchResultBusUsage = Resources_Schema_Logger::ExactMatchResultBusUsage;

    const int size = 2 * Memories::SRAM_ROWS;

    auto emrbru = new ExactMatchResultBusResourceUsage(size);

    std::map<int, ExactMatchResultBusUsage*> idToUsages;  // Support for sharing buses
    for (auto &res : stageResources[stageNo].memories) {
        for (auto &use : res.use->memuse) {
            Memories::Use memuse = use.second;
            std::string usedFor = typeName(memuse.type);

            switch (memuse.type) {
            case Memories::Use::EXACT:
            case Memories::Use::ATCAM: {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].result_bus;
                if (bus < 0) bus = memuse.row[0].bus;
                if (bus < 0) break;

                int id = 2 * row + (bus & 1);
                if (idToUsages.count(id) == 0) {
                    idToUsages[id] = new ExactMatchResultBusUsage(id);
                }

                auto usedBy = res.tableName.substr(res.tableName[0] == '.' ? 1 : 0);
                auto eu = new ElementUsage(usedBy, "", usedFor);
                idToUsages[id]->append(eu);
                break;
            }
            /*  // Keep this around for when figure out how to distingush bus type.
            case Memories::Use::GATEWAY: {
                auto row = memuse.row[0].row;
                auto unit = memuse.gateway.unit;
                // FIXME: How do we know if this is a tind bus or exm bus?
                if (memuse.gateway.payload_unit == 0 || memuse.gateway.payload_unit == 1) {
                    auto *exm_result_usage = new Util::JsonObject();
                    auto result_bus_unit = 2 * memuse.gateway.payload_row;
                    result_bus_unit += memuse.gateway.payload_unit;

                    int id = result_bus_unit;
                    // TODO: Create appropriate usage object with id

                    auto usedBy = res.tableName.substr(res.tableName[0] == '.' ? 1 : 0);
                    auto eu = new ElementUsage(usedBy, "", usedFor);
                    // TODO: append eu to usage object
                }
                break;
            }*/

            default: break;
            }
        }
    }

    // now append all the ids found to the ids array
    for (auto &kv : idToUsages) {
        emrbru->append(kv.second);
    }

    return emrbru;
}

ResourcesLogging::TindResultBusResourceUsage*
ResourcesLogging::logTindResultBuses(unsigned int stageNo) const {
    using TindResultBusUsage = Resources_Schema_Logger::TindResultBusUsage;

    const int size = 2 * Memories::SRAM_ROWS;

    auto trbru = new TindResultBusResourceUsage(size);

    std::map<int, TindResultBusUsage*> idToUsages;  // Support for sharing buses
    for (auto &res : stageResources[stageNo].memories) {
        for (auto &use : res.use->memuse) {
            Memories::Use memuse = use.second;
            std::string usedFor = typeName(memuse.type);

            switch (memuse.type) {
            case Memories::Use::TIND: {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;

                int id = 2 * row + bus;
                if (idToUsages.count(id) == 0) {
                    idToUsages[id] = new TindResultBusUsage(id);
                }

                auto usedBy = res.tableName.substr(res.tableName[0] == '.' ? 1 : 0);
                auto eu = new ElementUsage(usedBy, "", usedFor);
                idToUsages[id]->append(eu);
                break;
            }
            case Memories::Use::GATEWAY: {
                // auto row = memuse.row[0].row;
                // auto unit = memuse.gateway.unit;
                // FIXME: How do we know if this is a tind bus or exm bus?
                if (memuse.gateway.payload_unit == 0 || memuse.gateway.payload_unit == 1) {
                    auto id = 2 * memuse.gateway.payload_row +
                        memuse.gateway.payload_unit;
                    if (idToUsages.count(id) == 0) {
                        idToUsages[id] = new TindResultBusUsage(id);
                    }

                    auto usedBy = res.tableName.substr(res.tableName[0] == '.' ? 1 : 0);
                    auto eu = new ElementUsage(usedBy, "", usedFor);
                    idToUsages[id]->append(eu);
                }
                break;
            }
            default:
                break;
            }
        }
    }

    // now append all the ids found to the ids array
    for (auto &kv : idToUsages) {
        trbru->append(kv.second);
    }

    return trbru;
}

ResourcesLogging::MauStageResourceUsage *ResourcesLogging::logStage(int stageNo) {
    LOG1("generating resources for stage " << stageNo);

    auto xbarBytes = logXbarBytes(stageNo);
    auto hashBits = logHashBits(stageNo);
    auto hashDist = logHashDist(stageNo);

    auto ramsRes = new RamResourceUsage(
        Memories::SRAM_COLUMNS,  // nColums
        Memories::SRAM_ROWS);  // nRows

    auto mapRamsRes = new MapRamResourceUsage(
        Memories::SRAM_ROWS,  // nRows
        Memories::MAPRAM_COLUMNS);  // nUnits

    auto gatewaysRes = new GatewayResourceUsage(
        Memories::SRAM_ROWS,  // nRows
        Memories::GATEWAYS_PER_ROW);  // nUnits

    auto stashesRes = new StashResourceUsage(
        Memories::SRAM_ROWS,  // nRows
        Memories::GATEWAYS_PER_ROW);  // nUnits

    auto meterRes = new MeterAluResourceUsage(4);  // nAlus
    auto statisticsRes = new StatisticAluResourceUsage(4);  // nAlus

    auto tcamsRes = new TcamResourceUsage(
        Memories::TCAM_COLUMNS,  // nColums
        Memories::TCAM_ROWS);  // nRows

    logMemories(stageNo, ramsRes, mapRamsRes, gatewaysRes,
                stashesRes, meterRes, statisticsRes, tcamsRes);

    auto logicalTables = logLogicalTables(stageNo);

    auto actionData = logActionBusBytes(stageNo);
    auto vliw = logVliw(stageNo);
    auto exactSearch = logExactMemSearchBuses(stageNo);
    auto exactResult = logExactMemResultBuses(stageNo);
    auto tindResult = logTindResultBuses(stageNo);

    auto msru = new MauStageResourceUsage(
        actionData,
        exactResult,
        exactSearch,
        gatewaysRes,
        hashBits,
        hashDist,
        logicalTables,
        mapRamsRes,
        meterRes,
        ramsRes,
        stageNo,
        stashesRes,
        statisticsRes,
        tcamsRes,
        tindResult,
        vliw,
        xbarBytes);

    logActionSlots(msru);

    return msru;
}

}  // namespace BFN
