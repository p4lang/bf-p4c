#include <libgen.h>
#include <time.h>

#include <algorithm>
#include <cstdio>
#include <fstream>
#include <set>
#include <string>

#include "common/run_id.h"
#include "ir/gress.h"
#include "mau/resource.h"
#include "parde/p4i/gen_parser_json.h"
#include "version.h"
#include "visualization.h"

namespace BFN {

static std::string typeName(Memories::Use::type_t type) {
    switch (type) {
        case Memories::Use::EXACT:      return "match_entry_ram";
        case Memories::Use::ATCAM:      return "algorithmic_tcam";
        case Memories::Use::TERNARY:    return "ternary_match";
        case Memories::Use::GATEWAY:    return "gateway";
        case Memories::Use::TIND:       return "ternary_indirection_ram";
        case Memories::Use::COUNTER:    return "counter";
        case Memories::Use::METER:      return "meter_ram";
        case Memories::Use::STATEFUL:   return "stateful_ram";
        case Memories::Use::SELECTOR:   return "select_ram";
        case Memories::Use::ACTIONDATA: return "action_ram";
        case Memories::Use::IDLETIME:   return "idletime";
        default: BUG("Unknown memory type");
    }
}

Visualization::Visualization() : _stageResources() {
    _resourcesNode = new Util::JsonObject();
    auto *pipesNode = new Util::JsonArray();
    _resourcesNode->emplace("pipes", pipesNode);
}

/** A string built from the concatenation of strings in that node vector */
std::string Visualization::JsonResource::total_value(node_t node) {
    std::string rv;
    bool first = true;
    for (auto s : *values(node)) {
        if (!first)
            rv += ", ";
        else
            first = false;
        rv += s;
    }
    return rv;
}

/** Adding a string value to a particular vector */
void Visualization::JsonResource::add(node_t node, const std::string value) {
    if (value.empty())
        return;
    // Strip the leading . from all names, as it confuses p4i
    json_vectors[node].insert(value.substr(value[0] == '.' ? 1 : 0));
    check_sanity(node);
}

/** Appending the values in a JsonResource to the vector in this JsonResource */
void Visualization::JsonResource::append(JsonResource *jr) {
    for (auto kv : jr->json_vectors) {
        auto node = kv.first;
        if (singular_value_nodes.count(node) && !is_empty(node))
            BUG_CHECK(at(node) == jr->at(node), "Only one value allowed for a node type");
        else
            add(node, jr->at(node));
    }
}

bool Visualization::preorder(const IR::BFN::Pipe *p) {
    Util::JsonArray *pipesNode = dynamic_cast<Util::JsonArray *>(_resourcesNode->get("pipes"));
    auto *pipe = new Util::JsonObject();
    auto pipe_id = pipesNode->size();
    pipe->emplace("pipe_id", new Util::JsonValue(pipe_id));
    auto *parser = new Util::JsonObject();
    parser->emplace("nParsers", new Util::JsonValue(Device::numParsersPerPipe()));
    auto* gen_parsers_json = new GenerateParserP4iJson();
    p->apply(*gen_parsers_json);
    parser->emplace("parsers", gen_parsers_json->getParsersJson());
    pipe->emplace("parser", parser);
    auto *mauStages = new Util::JsonArray();
    auto *mau = new Util::JsonObject();
    mau->emplace("nStages", new Util::JsonValue(Device::numStages()));
    mau->emplace("mau_stages", mauStages);
    pipe->emplace("mau", mau);
    pipe->emplace("deparser", new Util::JsonArray());
    pipesNode->append(pipe);

    auto *phase0 = new Util::JsonObject();
    if (p->phase0Info)
        usagesToCtxJson(phase0, p->phase0Info->tableName + "", p->phase0Info->actionName + "");
    else
        usagesToCtxJson(phase0, "");
    pipe->emplace("phase0", phase0);

    // Create the "phv_containers" node.
    pipe->emplace("phv_containers", Device::phvSpec().toJson());

    // FIXME: Populate clots for Tofino2
    // pipe->emplace("clots", ???);

    return true;
}

Util::JsonObject *Visualization::getStage(unsigned int stage, unsigned int pipe) {
    assert(_resourcesNode);
    Util::JsonArray *p = dynamic_cast<Util::JsonArray *>(_resourcesNode->get("pipes"));
    if (p == nullptr) return nullptr;
    Util::JsonObject *thePipe = dynamic_cast<Util::JsonObject *>((*p)[pipe]);
    if (thePipe == nullptr) return nullptr;
    Util::JsonObject *mau = dynamic_cast<Util::JsonObject *>(thePipe->get("mau"));
    Util::JsonArray *stages = dynamic_cast<Util::JsonArray *>(mau->get("mau_stages"));
    Util::JsonObject *s = nullptr;
    if (stages->size() > stage)
        s = dynamic_cast<Util::JsonObject *>((*stages)[stage]);
    if (s == nullptr) {  // not yet allocated
        s = new Util::JsonObject();
        s->emplace("stage_number", stage);
        stages->reserve(stage+1);  // make space
        stages->insert(stages->begin()+stage, s);
    }
    return s;
}

void Visualization::gen_stage(unsigned int stage) {
    auto *theStage = getStage(stage);
    assert(theStage);

    LOG1("generating resources for stage " << stage);
    gen_xbar_bytes(stage, theStage);
    gen_hash_bits(stage, theStage);
    gen_hashdist(stage, theStage);
    gen_memories(stage, theStage);
    gen_action_bus_bytes(stage, theStage);
    gen_action_slots(stage, theStage);
    gen_vliw(stage, theStage);
    gen_exm_search_buses(stage, theStage);
    gen_exm_result_buses(stage, theStage);
    gen_tind_result_buses(stage, theStage);
}

void Visualization::add_xbar_bytes_usage(unsigned int stage, const IXBar::Use &alloc) {
    if (alloc.use.empty())
        return;

    LOG2("add_xbar_bytes_usage (stage=" << stage << "), table: " << alloc.used_by);
    // \TODO: what if these have usages from before? We need to append to elements rather
    // than emplace the elements
    for (auto &byte : alloc.use) {
        XBarByteResource xbr;
        xbr.add(USED_BY, alloc.used_by);
        xbr.add(USED_FOR, alloc.used_for());
        xbr.add(DETAILS, byte.visualization_detail());

        _stageResources[stage]._xBarBytesUsage[byte.loc.getOrd(alloc.ternary)].append(&xbr);

        LOG3("\tadding resource: xbar bytes " << byte.loc.getOrd(alloc.ternary));
    }

    // Used for the upper 12 bits of gateways
    for (auto &bits : alloc.bit_use) {
        for (int b = 0; b < bits.width; b++) {
            int bit = bits.bit + b + IXBar::HASH_INDEX_GROUPS * TableFormat::RAM_GHOST_BITS;
            auto key = std::make_pair(bit, bits.group);

            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, bits.field + std::to_string(bits.lo + b));

            LOG3("\tadding resource hash_bits from bit_use(" << bit << ", " << bits.group
                  << "): {" << hbr << "}");
           _stageResources[stage]._hashBitsUsage[key].append(&hbr);
        }
    }

    // Used for the bits to do exact match/atcam match
    int way_index = 0;
    for (auto &way : alloc.way_use) {
        for (auto bit : bitvec(way.mask)) {
            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, "Hash Way " + std::to_string(way_index));

            auto key = std::make_pair(bit, way.group);

            LOG3("\tadding resource hash_bits from way_use(" << bit << ", " << way.group
                 << "): {" << hbr << "}");
            _stageResources[stage]._hashBitsUsage[key].append(&hbr);
        }
        way_index++;
    }

    // Used for the bits provided to the selector
    if (alloc.meter_alu_hash.allocated) {
        auto &mah = alloc.meter_alu_hash;
        for (auto bit : mah.bit_mask) {
            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, "Selection Hash Bit " + std::to_string(bit));
            auto key = std::make_pair(bit, mah.group);
            LOG3("\tadding resource hash_bits from select_use(" << bit << ", " << mah.group
                 << "): {" << hbr << "}");
            _stageResources[stage]._hashBitsUsage[key].append(&hbr);
        }
    }
    // Used for the bits for hash distribution
    auto &hdh = alloc.hash_dist_hash;
    if (hdh.allocated) {
        for (auto bit : hdh.bit_mask) {
            int position = -1;
            for (auto bit_start : hdh.bit_starts) {
                int init_hb = bit_start.first;
                auto br = bit_start.second;
                if (bit >= init_hb && bit < init_hb + br.size())
                    position = br.lo + (bit - init_hb);
            }
            auto key = std::make_pair(bit, hdh.group);

            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, "Hash Dist Bit " + std::to_string(position));
            LOG3("\tadding resource hash_bits from hash_dist(" << bit << ", " << hdh.group
                 << "): {" << hbr << "}");
            _stageResources[stage]._hashBitsUsage[key].append(&hbr);

            _stageResources[stage]._hashBitsUsage[key].append(&hbr);
        }
    }

    LOG2("add_xbar_bytes_usage (stage=" << stage << "), table: " << alloc.used_by << " done!");
}

void Visualization::add_hash_dist_usage(unsigned int stage, const IXBar::HashDistUse &hd_use) {
    add_xbar_bytes_usage(stage, hd_use.use);
    int hash_id = hd_use.use.hash_dist_hash.unit;
    for (auto unit : hd_use.use.hash_dist_hash.slice) {
        auto key = std::make_pair(hash_id, unit);
        HashDistResource hdr;

        hdr.add(USED_BY, hd_use.use.used_by);
        hdr.add(USED_FOR, hd_use.use.used_for());

        _stageResources[stage]._hashDistUsage[key].append(&hdr);
    }
    LOG2("add_hash_dist_usage (stage=" << stage << "), table: " << hd_use.use.used_by
         << " done!");
}

void Visualization::add_action_bus_bytes_usage(unsigned int stage, const ActionDataBus::Use &alloc,
                                               cstring tableName) {
    for (auto &rs : alloc.action_data_locs) {
        int byte_sz = ActionFormat::CONTAINER_SIZES[rs.location.type] / 8;
        for (auto i = 0; i < byte_sz; i++) {
            ActionBusByteResource abr;
            abr.add(USED_BY, tableName + "");
            _stageResources[stage]._actionBusBytesUsage[rs.location.byte+i].append(&abr);
        }
    }

    LOG2("add_action_bus_bytes_usage (stage=" << stage << "), table :" << tableName << " done!");
}

void Visualization::add_vliw_usage(unsigned int stage, const InstructionMemory::Use &alloc,
                                   gress_t gress, cstring tableName) {
    for (auto &entry : alloc.all_instrs) {
        auto instr = entry.second;
        int row = instr.row;
        IMemColorResource imr;
        imr.color = instr.color;
        imr.gress = gress;
        imr.add(USED_BY, tableName.c_str());
        imr.add(DETAILS, entry.first.c_str());

        bool shared_slot = false;
        for (auto& r : _stageResources[stage]._imemColorUsage[row]) {
            if (r.color == imr.color && r.gress == imr.gress)  {
                r.add(USED_BY, tableName.c_str());
                r.add(DETAILS, entry.first.c_str());
                shared_slot = true;
                break;
            }
        }

        if (shared_slot)
            continue;

        _stageResources[stage]._imemColorUsage[row].push_back(imr);
    }

    LOG2("add_vliw_usage (stage=" << stage << "), table :" << tableName << " done!");
}

void Visualization::gen_xbar_bytes(unsigned int stageNo, Util::JsonObject *stage) {
    auto *xr = new Util::JsonObject();
    xr->emplace("size",
                new Util::JsonValue(IXBar::EXACT_GROUPS * IXBar::EXACT_BYTES_PER_GROUP +
                                    IXBar::BYTE_GROUPS * IXBar::TERNARY_BYTES_PER_BIG_GROUP));
    xr->emplace("exact_size",
                new Util::JsonValue(IXBar::EXACT_GROUPS * IXBar::EXACT_BYTES_PER_GROUP));
    xr->emplace("ternary_size",
                new Util::JsonValue(IXBar::BYTE_GROUPS * IXBar::TERNARY_BYTES_PER_BIG_GROUP));
    auto *xb = new Util::JsonArray();
    xr->emplace("bytes", xb);
    std::for_each(_stageResources[stageNo]._xBarBytesUsage.begin(),
                  _stageResources[stageNo]._xBarBytesUsage.end(),
                  [xb](const std::pair<int, XBarByteResource> &p) {
                      auto byte_number = p.first;
                      auto use = p.second;
                      auto *byte_repr = new Util::JsonObject();
                      byte_repr->emplace("byte_number", new Util::JsonValue(byte_number));
                      cstring byte_type;
                      if (byte_number >= IXBar::EXACT_GROUPS * IXBar::EXACT_BYTES_PER_GROUP)
                          byte_type = "ternary";
                      else
                          byte_type = "exact";
                      byte_repr->emplace("byte_type", new Util::JsonValue(byte_type));
                      usagesToCtxJson(byte_repr, use.total_value(USED_BY),
                                      use.total_value(USED_FOR), use.total_value(DETAILS));
                      xb->append(byte_repr);
                  });
    stage->emplace("xbar_bytes", xr);
}

void Visualization::gen_hash_bits(unsigned int stageNo, Util::JsonObject *stage) {
    auto *hash_bits_res = new Util::JsonObject();
    hash_bits_res->emplace("nBits", new Util::JsonValue(10 * IXBar::HASH_INDEX_GROUPS +
                                                        IXBar::HASH_SINGLE_BITS));
    hash_bits_res->emplace("nFunctions", new Util::JsonValue(IXBar::HASH_GROUPS));
    auto *hash_bits = new Util::JsonArray();
    std::for_each(_stageResources[stageNo]._hashBitsUsage.begin(),
                  _stageResources[stageNo]._hashBitsUsage.end(),
                  [hash_bits](const std::pair<std::pair<int, int>, HashBitResource> &p) {
                      auto use = p.second;
                      auto bit_number = p.first.first;
                      auto hash_function = p.first.second;
                      auto *bit_repr = new Util::JsonObject();
                      bit_repr->emplace("hash_bit", new Util::JsonValue(bit_number));
                      bit_repr->emplace("hash_function", new Util::JsonValue(hash_function));
                      usagesToCtxJson(bit_repr, use.total_value(USED_BY),
                                      use.total_value(USED_FOR), use.total_value(DETAILS));
                      hash_bits->append(bit_repr);
                  });
    hash_bits_res->emplace("bits", hash_bits);
    stage->emplace("hash_bits", hash_bits_res);
}

void Visualization::gen_hashdist(unsigned int stageNo, Util::JsonObject *stage) {
    auto *hash_distr_res = new Util::JsonObject();
    hash_distr_res->emplace("nHashIds", new Util::JsonValue(IXBar::HASH_DIST_UNITS));
    hash_distr_res->emplace("nUnitIds", new Util::JsonValue(IXBar::HASH_DIST_SLICES));
    auto *hash_distr = new Util::JsonArray();
    std::for_each(_stageResources[stageNo]._hashDistUsage.begin(),
                  _stageResources[stageNo]._hashDistUsage.end(),
                  [hash_distr](const std::pair<std::pair<int, int>, HashDistResource> &p) {
                  auto use = p.second;
                  auto hash_id = p.first.first;
                  auto unit_id = p.first.second;
                  auto *hd_repr = new Util::JsonObject();
                  hd_repr->emplace("hash_id", new Util::JsonValue(hash_id));
                  hd_repr->emplace("unit_id", new Util::JsonValue(unit_id));

                  usagesToCtxJson(hd_repr, use.total_value(USED_BY),
                                  use.total_value(USED_FOR), use.total_value(DETAILS));
                  hash_distr->append(hd_repr);
             });
    hash_distr_res->emplace("units", hash_distr);
    stage->emplace("hash_distribution_units", hash_distr_res);
}

void Visualization::add_table_usage(cstring name, const IR::MAU::Table *table) {
    LOG1("add_table_usage: " << name);
    if (table->logical_id < 0) {
        // \TODO: for partial allocation, we'll eventually need to list all the
        // tables, including the ones that are not allocated in the resources node.
        // For now, we just ignore them, rather than issuing an error
        // P4C_UNIMPLEMENTED("visualization of un-allocated tables not yet implemented (%1%: %2%)",
        //                  name, table->logical_id);
        return;
    }

    unsigned stage = table->logical_id/StageUse::MAX_LOGICAL_IDS;
    // ensure we have enough space in the collector
    if (stage >= _stageResources.size()) {
        for (unsigned i = _stageResources.size(); i <= stage; i++)
            _stageResources.push_back(ResourceCollectors());
    }

    // logicalIds
    _stageResources[stage]._logicalIds.emplace(table->logical_id, name);

    const TableResourceAlloc *alloc = table->resources;

    LOG3("\tadding resource table: " << name);

    _stageResources[stage]._memoriesUsage.push_back(MemoriesResource(name, alloc));

    add_xbar_bytes_usage(stage, alloc->match_ixbar);
    add_xbar_bytes_usage(stage, alloc->salu_ixbar);
    add_xbar_bytes_usage(stage, alloc->meter_ixbar);
    add_xbar_bytes_usage(stage, alloc->selector_ixbar);
    add_xbar_bytes_usage(stage, alloc->gateway_ixbar);

    for (auto &hash_dist : alloc->hash_dists)
        add_hash_dist_usage(stage, hash_dist);

    add_action_bus_bytes_usage(stage, alloc->action_data_xbar, name);

    // TODO action slots

    add_vliw_usage(stage, alloc->instr_mem, table->gress, name);

    LOG1("add_table_usage: " << name << " done!");
}

void Visualization::gen_memories(unsigned int stage, Util::JsonObject *parent) {
    auto *rams_res = new Util::JsonObject();
    auto *rams = new Util::JsonArray();
    rams_res->emplace("nRows", new Util::JsonValue(Memories::SRAM_ROWS));
    rams_res->emplace("nColumns", new Util::JsonValue(Memories::SRAM_COLUMNS));
    rams_res->emplace("srams", rams);
    parent->emplace("rams", rams_res);

    auto *map_rams_res = new Util::JsonObject();
    auto *map_rams = new Util::JsonArray();
    map_rams_res->emplace("nRows", new Util::JsonValue(Memories::SRAM_ROWS));
    map_rams_res->emplace("nUnits", new Util::JsonValue(Memories::MAPRAM_COLUMNS));
    map_rams_res->emplace("maprams", map_rams);
    parent->emplace("map_rams", map_rams_res);

    auto *gateways_res = new Util::JsonObject();
    auto *gateways = new Util::JsonArray();
    gateways_res->emplace("nRows", new Util::JsonValue(Memories::SRAM_ROWS));
    gateways_res->emplace("nUnits", new Util::JsonValue(Memories::GATEWAYS_PER_ROW));
    gateways_res->emplace("gateways", gateways);
    parent->emplace("gateways", gateways_res);

    auto *jmeter_res = new Util::JsonObject();
    auto *jmeter_alus = new Util::JsonArray();
    auto *statistics_res = new Util::JsonObject();
    auto *statistics_alus = new Util::JsonArray();

    jmeter_res->emplace("nAlus", new Util::JsonValue(4));
    jmeter_res->emplace("meters", jmeter_alus);
    parent->emplace("meter_alus", jmeter_res);

    statistics_res->emplace("nAlus", new Util::JsonValue(4));
    statistics_res->emplace("stats", statistics_alus);
    parent->emplace("statistic_alus", statistics_res);

    auto *tcams_res = new Util::JsonObject();
    auto *tcams = new Util::JsonArray();
    tcams_res->emplace("nRows", new Util::JsonValue(Memories::TCAM_ROWS));
    tcams_res->emplace("nColumns", new Util::JsonValue(Memories::TCAM_COLUMNS));
    tcams_res->emplace("tcams", tcams);
    parent->emplace("tcams", tcams_res);

    auto p4name = [](const MemoriesResource &res) {
        // // find the P4Table
        // const IR::MAU::Table *table = nullptr;
        // for ( auto *t : tables)
        //     if (t->memuse->find(res._tableName) != t->memuse->end()) {
        //         table = t->table;
        //         break;
        //     }
        // if (table) return table->p4name();

        // \TODO: Should strip the leading "." from all names
        // if (res._tableName.startsWith("."))
        //     return res._tableName.substr(1);
        // else
        return res._tableName;
    };

    auto mkItem = [](Util::JsonArray *parent, const cstring tableName, const cstring matchType,
                     int r, int c, const cstring &colName) {
        auto *item = new Util::JsonObject();
        item->emplace("row", new Util::JsonValue(r));
        item->emplace(colName, new Util::JsonValue(c));
        BFN::Visualization::usagesToCtxJson(item, tableName + "", matchType + "");
        parent->append(item);
    };

    for (auto &res : _stageResources[stage]._memoriesUsage) {
        for (auto &use : res._use->memuse) {
            Memories::Use memuse = use.second;
            std::string memTypeName = typeName(memuse.type);
            std::string ext = "";

            switch (memuse.type) {
            case Memories::Use::ACTIONDATA:
                ext = "$action"; break;
#if 0
            // Not removing since we might bring some of these annotations back.
            case Memories::Use::TIND:
                ext = "$tind"; break;
            case Memories::Use::COUNTER:
                ext = "$stats"; break;
            case Memories::Use::METER:
                ext = "$meter"; break;
            case Memories::Use::STATEFUL:
                ext = "$salu"; break;
            case Memories::Use::SELECTOR:
                ext = "$sel"; break;
            case Memories::Use::IDLETIME:
                ext = "$idle"; break;
            case Memories::Use::GATEWAY:
                ext = "$gw"; break;
#endif
            default:
                break;
            }

            LOG3("MemUse: (" << res._tableName << ", p4name: " << p4name(res)
                 << memuse.type << ")");
            switch (memuse.type) {
            case Memories::Use::EXACT:
            case Memories::Use::ATCAM:
            case Memories::Use::TIND:
            case Memories::Use::ACTIONDATA:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res) + ext, memTypeName, r.row, c, "column");
                break;
            case Memories::Use::TERNARY:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(tcams, p4name(res) + ext, memTypeName, r.row, c, "column");
                LOG1("TCAMS");
                break;
            case Memories::Use::GATEWAY: {
                auto row = memuse.row[0].row;
                auto unit = memuse.gateway.unit;
                mkItem(gateways, p4name(res) + ext, memTypeName, row, unit, "unit_id");

                break; }
            case Memories::Use::COUNTER:
            case Memories::Use::METER:
            case Memories::Use::STATEFUL:
            case Memories::Use::SELECTOR:
                for (auto &r : memuse.row) {
                    auto *item = new Util::JsonObject();
                    item->emplace("row", new Util::JsonValue(r.row));
                    usagesToCtxJson(item, p4name(res).c_str(), memTypeName);
                    if (r.row % 2 == 0) statistics_alus->append(item);
                    else                jmeter_alus->append(item);
                }

                for (auto &r : memuse.row) {
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res) + ext, memTypeName, r.row, c, "column");
                    for (auto c : r.mapcol)
                        mkItem(map_rams, p4name(res) + ext, memTypeName, r.row, c, "unit_id");
                }

                for (auto &r : memuse.color_mapram)
                    for (auto &col : r.col)
                        mkItem(map_rams, p4name(res) + ext, memTypeName, r.row, col, "unit_id");

                break;
            case Memories::Use::IDLETIME:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(map_rams, p4name(res), "idletime", r.row, c, "unit_id");
                break;
            default:
                BUG("Unhandled memory use type %d in Visualization::gen_memories", memuse.type);
            }
        }
    }

    auto *logical_tables = new Util::JsonObject();
    logical_tables->emplace("size", new Util::JsonValue(StageUse::MAX_LOGICAL_IDS));
    auto *logical_ids = new Util::JsonArray();
    logical_tables->emplace("ids", logical_ids);
    for (auto &t : _stageResources[stage]._logicalIds) {
        auto *lid = new Util::JsonObject();
        lid->emplace("id", new Util::JsonValue(t.first % StageUse::MAX_LOGICAL_IDS));
        usagesToCtxJson(lid, t.second + "");
        logical_ids->append(lid);
    }
    parent->emplace("logical_tables", logical_tables);

    auto *stashes_res = new Util::JsonObject();
    auto *stashes = new Util::JsonArray();
    stashes_res->emplace("nRows", new Util::JsonValue(8));
    stashes_res->emplace("nUnits", new Util::JsonValue(1));
    stashes_res->emplace("stashes", stashes);
    parent->emplace("stashes", stashes_res);
}

void Visualization::gen_action_bus_bytes(unsigned int stageNo, Util::JsonObject *stage) {
    auto *action_bus_bytes = new Util::JsonObject();
    action_bus_bytes->emplace("size", new Util::JsonValue(ActionDataBus::ADB_BYTES));
    auto *ab = new Util::JsonArray();
    action_bus_bytes->emplace("bytes", ab);

    std::for_each(_stageResources[stageNo]._actionBusBytesUsage.begin(),
                  _stageResources[stageNo]._actionBusBytesUsage.end(),
                  [ab](const std::pair<int, ActionBusByteResource> &p) {
                      auto byte_number = p.first;
                      auto use = p.second;
                      auto *byte_repr = new Util::JsonObject();
                      byte_repr->emplace("byte_number", new Util::JsonValue(byte_number));
                      usagesToCtxJson(byte_repr, use.total_value(USED_BY),
                                      use.total_value(USED_FOR), use.total_value(DETAILS));
                      ab->append(byte_repr);
                  });

    stage->emplace("action_bus_bytes", action_bus_bytes);
}

void Visualization::gen_action_slots(unsigned int /* stageNo */, Util::JsonObject *stage) {
    // \TODO: where do we get these ones from?
    auto *action_slots = new Util::JsonArray();
    for ( auto slot : { 8, 16, 32} ) {
        auto * s = new Util::JsonObject();
        s->emplace("slot_bit_width", new Util::JsonValue(slot));
        s->emplace("maximum_slots", new Util::JsonValue(32));
        s->emplace("number_used", new Util::JsonValue(0));
        action_slots->append(s);
    }
    stage->emplace("action_slots", action_slots);
}

void Visualization::gen_vliw(unsigned int stageNo, Util::JsonObject *stage) {
    auto *vliw = new Util::JsonObject();
    vliw->emplace("size", new Util::JsonValue(InstructionMemory::IMEM_ROWS));
    auto *instructions = new Util::JsonArray();
    vliw->emplace("instructions", instructions);

    std::for_each(_stageResources[stageNo]._imemColorUsage.begin(),
                  _stageResources[stageNo]._imemColorUsage.end(),
                  [instructions](const std::pair<int, std::vector<IMemColorResource>> &p) {
                      auto row = p.first;
                      auto *instr = new Util::JsonObject();
                      instr->emplace("instruction_number", new Util::JsonValue(row));
                      auto *color_usages = new Util::JsonArray();
                      for (auto use : p.second) {
                          auto* usage = new Util::JsonObject();
                          usage->emplace("color", new Util::JsonValue(use.color));
                          usage->emplace("gress", new Util::JsonValue(::toString(use.gress)));
                          usagesToCtxJson(usage, use.total_value(USED_BY),
                                      use.total_value(USED_FOR), use.total_value(DETAILS));
                          color_usages->append(usage);
                      }
                      instr->emplace("color_usages", color_usages);
                      instructions->append(instr);
                  });

    stage->emplace("vliw", vliw);
}

void Visualization::gen_exm_search_buses(unsigned int stageNo, Util::JsonObject *stage) {
    auto *exm_search_buses = new Util::JsonObject();
    exm_search_buses->emplace("size", new Util::JsonValue(2 * Memories::SRAM_ROWS));
    auto *ids = new Util::JsonArray();
    exm_search_buses->emplace("ids", ids);

    // If sharing is ever supported for search buses, we would need
    // to keep track of something like id_to_usages to avoid defining an
    // ID multiple times.
    for (auto &res : _stageResources[stageNo]._memoriesUsage) {
        for (auto &use : res._use->memuse) {
            Memories::Use memuse = use.second;
            std::string memTypeName = typeName(memuse.type);
            std::string ext = "";

            // While there are search buses available for selectors, these
            // are separate from exact match search buses, which is what is
            // referred to here.

            switch (memuse.type) {
            case Memories::Use::EXACT:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *exm_search_usage = new Util::JsonObject();
                exm_search_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                exm_search_usage->emplace("usages", usages);
                ids->append(exm_search_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            case Memories::Use::ATCAM:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *exm_search_usage = new Util::JsonObject();
                exm_search_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                exm_search_usage->emplace("usages", usages);
                ids->append(exm_search_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            case Memories::Use::GATEWAY:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *exm_search_usage = new Util::JsonObject();
                exm_search_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                exm_search_usage->emplace("usages", usages);
                ids->append(exm_search_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            default: {
                break;
            }
            }
        }
    }
    stage->emplace("exm_search_buses", exm_search_buses);
}

void Visualization::gen_exm_result_buses(unsigned int stageNo, Util::JsonObject *stage) {
    auto *exm_result_buses = new Util::JsonObject();
    exm_result_buses->emplace("size", new Util::JsonValue(2 * Memories::SRAM_ROWS));
    auto *ids = new Util::JsonArray();
    exm_result_buses->emplace("ids", ids);

    // If sharing is ever supported for result buses, we would need
    // to keep track of something like id_to_usages to avoid defining an
    // ID multiple times.
    for (auto &res : _stageResources[stageNo]._memoriesUsage) {
        for (auto &use : res._use->memuse) {
            Memories::Use memuse = use.second;
            std::string memTypeName = typeName(memuse.type);
            std::string ext = "";

            switch (memuse.type) {
            case Memories::Use::EXACT:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *exm_result_usage = new Util::JsonObject();
                exm_result_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                exm_result_usage->emplace("usages", usages);
                ids->append(exm_result_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            case Memories::Use::ATCAM:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *exm_result_usage = new Util::JsonObject();
                exm_result_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                exm_result_usage->emplace("usages", usages);
                ids->append(exm_result_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            /*  // Keep this around for when figure out how to distingush bus type.
            case Memories::Use::GATEWAY: {
                auto row = memuse.row[0].row;
                auto unit = memuse.gateway.unit;
                // FIXME: How do we know if this is a tind bus or exm bus?
                if (memuse.gateway.payload_bus == 0 || memuse.gateway.payload_bus == 1) {
                    auto *exm_result_usage = new Util::JsonObject();
                    auto result_bus_unit = 2 * memuse.gateway.payload_row;
                    result_bus_unit += memuse.gateway.payload_bus;
                    exm_result_usage->emplace("id", new Util::JsonValue(result_bus_unit));
                    auto *usages = new Util::JsonArray;
                    exm_result_usage->emplace("usages", usages);
                    ids->append(exm_result_usage);
                    auto *usage = new Util::JsonObject();
                    auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                    usage->emplace("used_by", new Util::JsonValue(tname));
                    usage->emplace("used_for", new Util::JsonValue(memTypeName));
                    // usage->emplace("detail", new Util::JsonValue("?"));
                    usages->append(usage);
                }
                break;
            }
            */
            default: {
                break;
            }
            }
        }
    }
    stage->emplace("exm_result_buses", exm_result_buses);
}

void Visualization::gen_tind_result_buses(unsigned int stageNo, Util::JsonObject *stage) {
    auto *tind_result_buses = new Util::JsonObject();
    tind_result_buses->emplace("size", new Util::JsonValue(2 * Memories::SRAM_ROWS));
    auto *ids = new Util::JsonArray();
    tind_result_buses->emplace("ids", ids);

    // If sharing is ever supported for result buses, we would need
    // to keep track of something like id_to_usages to avoid defining an
    // ID multiple times.
    for (auto &res : _stageResources[stageNo]._memoriesUsage) {
        for (auto &use : res._use->memuse) {
            Memories::Use memuse = use.second;
            std::string memTypeName = typeName(memuse.type);
            std::string ext = "";

            switch (memuse.type) {
            case Memories::Use::TIND:
            {
                auto row = memuse.row[0].row;
                auto bus = memuse.row[0].bus;
                auto *tind_result_usage = new Util::JsonObject();
                tind_result_usage->emplace("id", new Util::JsonValue(2 * row + bus));
                auto *usages = new Util::JsonArray;
                tind_result_usage->emplace("usages", usages);
                ids->append(tind_result_usage);
                auto *usage = new Util::JsonObject();
                auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                usage->emplace("used_by", new Util::JsonValue(tname));
                usage->emplace("used_for", new Util::JsonValue(memTypeName));
                // usage->emplace("detail", new Util::JsonValue("?"));
                usages->append(usage);
                break;
            }
            case Memories::Use::GATEWAY: {
                // auto row = memuse.row[0].row;
                // auto unit = memuse.gateway.unit;
                // FIXME: How do we know if this is a tind bus or exm bus?
                if (memuse.gateway.payload_bus == 0 || memuse.gateway.payload_bus == 1) {
                    auto *tind_result_usage = new Util::JsonObject();
                    auto result_bus_unit = 2 * memuse.gateway.payload_row;
                    result_bus_unit += memuse.gateway.payload_bus;
                    tind_result_usage->emplace("id", new Util::JsonValue(result_bus_unit));
                    auto *usages = new Util::JsonArray;
                    tind_result_usage->emplace("usages", usages);
                    ids->append(tind_result_usage);
                    auto *usage = new Util::JsonObject();
                    auto tname = res._tableName.substr(res._tableName[0] == '.' ? 1 : 0);
                    usage->emplace("used_by", new Util::JsonValue(tname));
                    usage->emplace("used_for", new Util::JsonValue(memTypeName));
                    // usage->emplace("detail", new Util::JsonValue("?"));
                    usages->append(usage);
                }
                break;
            }
            default: {
                break;
            }
            }
        }
    }
    stage->emplace("tind_result_buses", tind_result_buses);
}

std::ostream &operator<<(std::ostream &out, const Visualization &vis) {
    auto res_json = new Util::JsonObject();
    res_json->emplace("schema_version", new Util::JsonValue("1.0.4"));
    res_json->emplace("program_name",
                      new Util::JsonValue(BFNContext::get().options().programName + ".p4"));
    res_json->emplace("run_id", new Util::JsonValue(RunId::getId()));
    const time_t now = time(NULL);
    char build_date[1024];
    strftime(build_date, 1024, "%c", localtime(&now));
    res_json->emplace("build_date", new Util::JsonValue(build_date));
    res_json->emplace("compiler_version", new Util::JsonValue(BF_P4C_VERSION));
    if (vis._resourcesNode)
        res_json->emplace("resources", vis._resourcesNode);
    else
        res_json->emplace("resources", new Util::JsonObject());
    res_json->serialize(out);
    return out;
}

}  // namespace BFN
