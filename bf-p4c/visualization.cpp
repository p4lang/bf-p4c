#include <libgen.h>
#include <algorithm>
#include <cstdio>
#include <fstream>
#include <set>
#include <string>

#include "mau/resource.h"
#include "visualization.h"

namespace BFN {

Visualization::Visualization() : _stageResources() {
    _resourcesNode = new Util::JsonObject();
    auto *pipesNode = new Util::JsonArray();
    _resourcesNode->emplace("pipes", pipesNode);
}

/** A string built from the concatenation of strings in that node vector */
std::string Visualization::JsonResource::total_value(node_t node) {
    auto _values = values(node);
    std::string rv;
    for (size_t i = 0; i < _values->size(); i++) {
        rv += (*_values)[i];
        if (i != _values->size() - 1)
            rv += ", ";
    }
    return rv;
}

/** Adding a string value to a particular vector */
void Visualization::JsonResource::add(node_t node, const std::string value) {
    if (value.empty())
        return;
    json_vectors[node].push_back(value);
    check_sanity(node);
}

/** Appending the values in a JsonResource to the vector in this JsonResource */
void Visualization::JsonResource::append(JsonResource *jr) {
    for (auto kv : jr->json_vectors) {
        auto node = kv.first;
        if (singular_value_nodes.count(node) && !is_empty(node))
            BUG_CHECK(at(node, 0) == jr->at(node, 0), "Only one value allowed for a node type");
        else
            add(node, jr->at(node, 0));
    }
}

bool Visualization::preorder(const IR::BFN::Pipe *p) {
    Util::JsonArray *pipesNode = dynamic_cast<Util::JsonArray *>(_resourcesNode->get("pipes"));
    auto *pipe = new Util::JsonObject();
    auto pipe_id = pipesNode->size();
    pipe->emplace("pipe_id", new Util::JsonValue(pipe_id));
    auto *parser = new Util::JsonObject();
    parser->emplace("nParsers", new Util::JsonValue(18));  // \TODO: get from device
    parser->emplace("parsers", new Util::JsonArray());
    pipe->emplace("parser", parser);
    auto *mauStages = new Util::JsonArray();
    pipe->emplace("mau_stages", mauStages);
    pipe->emplace("deparser", new Util::JsonArray());
    pipesNode->append(pipe);

    auto *phase0 = new Util::JsonObject();
    if (p->phase0Info)
        usagesToCtxJson(phase0, p->phase0Info->tableName + "", p->phase0Info->actionName + "");
    else
        usagesToCtxJson(phase0, "");
    pipe->emplace("phase0", phase0);
    return true;
}

Util::JsonObject *Visualization::getStage(unsigned int stage, unsigned int pipe) {
    assert(_resourcesNode);
    Util::JsonArray *p = dynamic_cast<Util::JsonArray *>(_resourcesNode->get("pipes"));
    if (p == nullptr) return nullptr;
    Util::JsonObject *thePipe = dynamic_cast<Util::JsonObject *>((*p)[pipe]);
    if (thePipe == nullptr) return nullptr;
    Util::JsonArray *stages = dynamic_cast<Util::JsonArray *>(thePipe->get("mau_stages"));
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
    gen_xbar(stage, theStage);
    gen_hashbits(stage, theStage);
    gen_hashdist(stage, theStage);
    gen_memories(stage, theStage);
    gen_actions(stage, theStage);
}

void Visualization::add_xbar_usage(unsigned int stage, const IXBar::Use &alloc) {
    if (alloc.use.empty())
        return;

    LOG2("add_xbar_usage (stage=" << stage << "), table: " << alloc.used_by);
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
            int bit = bits.bit + b;
            auto key = std::make_pair(bit, bits.group);

            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, bits.field + std::to_string(bits.lo + b));

           _stageResources[stage]._hashBitsUsage[key].append(&hbr);

            LOG3("\tadding resource hash_bits from bit_use(" << bit << ", " << bits.group
                  << "): {" << hbr << "}");
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
            _stageResources[stage]._hashBitsUsage[key].append(&hbr);

            LOG3("\tadding resource hash_bits from way_use(" << bit << ", " << way.group
                 << "): {" << hbr << "}");
        }
        way_index++;
    }

    // Used for the bits provided to the selector
    for (auto &select : alloc.select_use) {
        for (int i = 0; i < IXBar::HASH_INDEX_GROUPS; i++) {
            for (int j = 0; j < TableFormat::RAM_GHOST_BITS; j++) {
                int bit = i * TableFormat::RAM_GHOST_BITS + j;

                HashBitResource hbr;
                hbr.add(USED_BY, alloc.used_by);
                hbr.add(USED_FOR, alloc.used_for());
                hbr.add(DETAILS, "Selection Hash Bit " + std::to_string(bit));

                auto key = std::make_pair(bit, select.group);
                _stageResources[stage]._hashBitsUsage[key].append(&hbr);

                LOG3("\tadding resource hash_bits from select_use(" << bit << ", " << select.group
                     << "): {" << hbr << "}");
            }
        }

        for (int i = 0; i < IXBar::HASH_SINGLE_BITS - 1; i++) {
            int bit = i + TableFormat::RAM_GHOST_BITS * IXBar::HASH_INDEX_GROUPS;

            HashBitResource hbr;
            hbr.add(USED_BY, alloc.used_by);
            hbr.add(USED_FOR, alloc.used_for());
            hbr.add(DETAILS, "Selection Hash Bit " + std::to_string(bit));

            auto key = std::make_pair(bit, select.group);
            _stageResources[stage]._hashBitsUsage[key].append(&hbr);

            LOG3("\tadding resource hash_bits from select_use(" << bit << ", " << select.group
                 << "): {" << hbr << "}");
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

            _stageResources[stage]._hashBitsUsage[key].append(&hbr);
        }
    }

    LOG2("add_xbar_usage (stage=" << stage << "), table: " << alloc.used_by << " done!");
}

void Visualization::add_hash_dist_usage(unsigned int stage, const IXBar::HashDistUse &hd_use) {
    add_xbar_usage(stage, hd_use.use);
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


void Visualization::gen_xbar(unsigned int stageNo, Util::JsonObject *stage) {
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

void Visualization::gen_hashbits(unsigned int stageNo, Util::JsonObject *stage) {
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
    hash_distr_res->emplace("nHashIds", new Util::JsonValue(IXBar::HASH_DIST_SLICES));
    hash_distr_res->emplace("nUnitIds", new Util::JsonValue(IXBar::HASH_DIST_UNITS));
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
    // \TODO: what do we do for un-allocated tables? id == -1?
    if (table->logical_id < 0) {
        P4C_UNIMPLEMENTED("visualization of un-allocated tables not yet implemented (%1%: %2%)",
                         name, table->logical_id);
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

    // collect table resources
    const TableResourceAlloc *alloc = table->resources;
    LOG3("\tadding resource table: " << name);
    _stageResources[stage]._memoriesUsage.push_back(MemoriesResource(name, alloc));

    add_xbar_usage(stage, alloc->match_ixbar);
    add_xbar_usage(stage, alloc->salu_ixbar);
    add_xbar_usage(stage, alloc->meter_ixbar);
    add_xbar_usage(stage, alloc->selector_ixbar);
    add_xbar_usage(stage, alloc->gateway_ixbar);
    for (auto &hash_dist : alloc->hash_dists)
        add_hash_dist_usage(stage, hash_dist);
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
    #if 0
    for (int r = 0; r < Memories::SRAM_ROWS; r++) {
        const cstring &tbl = (r % 2) == 0 ? stats_alus[r/2] : meter_alus[r/2];
        if (tbl || BFN::Visualization::OUTPUT_UNUSED) {
            auto *jsram = new Util::JsonObject();
            jsram->emplace("row", new Util::JsonValue(r));
            BFN::Visualization::usagesToCtxJson(jsram, tbl);
            if (r % 2 == 0)
                statistics_alus->append(jsram);
            else
                jmeter_alus->append(jsram);
        }
    }
    #endif
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

    auto p4name = [this](const MemoriesResource &res) {
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
            LOG3("MemUse: (" << res._tableName << ", p4name: " << p4name(res)
                 << memuse.type << ")");
            switch (memuse.type) {
            case Memories::Use::EXACT:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res), "match_entry_ram", r.row, c, "column");
                break;
            case Memories::Use::ATCAM:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res), "algorithmic_tcam", r.row, c, "column");
                break;
            case Memories::Use::TERNARY:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(tcams, p4name(res), "ternary_match", r.row, c, "column");
                break;
            case Memories::Use::GATEWAY:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(gateways, p4name(res), cstring(), r.row, c, "unit_id");
                break;
            case Memories::Use::TIND:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res), "ternary_indirection_ram", r.row, c, "column");
                break;
            case Memories::Use::COUNTER:
            case Memories::Use::METER:
            case Memories::Use::STATEFUL:
            case Memories::Use::SELECTOR:
                // \TODO: figure out the correct resource usage for counters/meters/stats/selectors
                // which types of memories
                for (auto &r : memuse.row) {
                    auto *item = new Util::JsonObject();
                    item->emplace("row", new Util::JsonValue(r.row));
                    usagesToCtxJson(item, p4name(res) + "");
                    if (r.row % 2 == 0) statistics_alus->append(item);
                    else                jmeter_alus->append(item);
                }
#if 0
                // use = &mem.sram_use;
                // mapuse = &mem.mapram_use;
                for (auto &r : row) {
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res), "...", r.row, c, "column");
                    for (auto c : r.mapcol)
                        mkItem(maprams, r.row, c, "unit_id");
                }
                for (auto &r : color_mapram)
                    for (auto &col : r.col)
                        mkItem(maprams, r.row, col, "unit_id");
#endif
                break;
            case Memories::Use::ACTIONDATA:
                for (auto &r : memuse.row)
                    for (auto &c : r.col)
                        mkItem(rams, p4name(res), "action_ram", r.row, c, "column");
                break;
                // bus = &mem.sram_print_search_bus;
            case Memories::Use::IDLETIME:
                for (auto &r : memuse.row)
                    for (auto &c : r.mapcol)
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

void Visualization::gen_actions(unsigned int /* stageNo */, Util::JsonObject *stage) {
    // \TODO: where do we get these ones from?
    auto *action_bus_bytes = new Util::JsonObject();
    action_bus_bytes->emplace("size", new Util::JsonValue(ActionDataBus::ADB_BYTES));
    action_bus_bytes->emplace("bytes", new Util::JsonArray());
    stage->emplace("action_bus_bytes", action_bus_bytes);

    auto *action_slots = new Util::JsonArray();
    for ( auto slot : { 8, 16, 32} ) {
        auto * s = new Util::JsonObject();
        s->emplace("slot_bit_width", new Util::JsonValue(slot));
        s->emplace("maximum_slots", new Util::JsonValue(32));
        s->emplace("number_used", new Util::JsonValue(0));
        action_slots->append(s);
    }
    stage->emplace("action_slots", action_slots);


    auto *vliw = new Util::JsonObject();
    vliw->emplace("size", new Util::JsonValue(32));
    vliw->emplace("instructions", new Util::JsonArray());
    stage->emplace("vliw", vliw);
}


std::ostream &operator<<(std::ostream &out, const Visualization &vis) {
    if (vis._resourcesNode)
        vis._resourcesNode->serialize(out);
    return out;
}

}  // namespace BFN
