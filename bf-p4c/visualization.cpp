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
        usagesToCtxJson(phase0, p->phase0Info->tableName, p->phase0Info->actionName);
    else
        usagesToCtxJson(phase0, cstring());
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

void Visualization::add_xbar_usage(unsigned int stage, cstring name, const IXBar::Use &alloc) {
    LOG1("add_xbar_usage (stage=" << stage << "), table: " << name);
    // \TODO: what if these have usages from before? We need to append to elements rather
    // than emplace the elements
    for (auto &byte : alloc.use) {
        LOG3("\tadding resource: xbar bytes " << byte.loc.getOrd(alloc.ternary));
        _stageResources[stage]._xBarBytesUsage.emplace(byte.loc.getOrd(alloc.ternary),
                              XBarByteResource(&byte, name, alloc.ternary ? "ternary" : "exact"));
    }
        // findExactByte(bits.field, (b + bits.lo)/8)
        // for (auto &p : Values(exact_fields.equal_range(name)))
        //     if (exact_use.at(p.group, p.byte).second/8 == byte)
        //         return &p;
    for (auto &bits : alloc.bit_use) {
        const IXBar::Loc *loc = nullptr;
        for (int b = 0; b < bits.width; b++) {
            if ((!loc || loc->byte != (b + bits.lo)/8))  // \TODO: &&
                // !(loc = alloc.findExactByte(bits.field, (b + bits.lo)/8)))
                continue;
            HashBitResource res(name, bits.field, loc, alloc.ternary ? "ternary" : "exact");
            for (auto ht : bitvec(alloc.hash_table_inputs[bits.group])) {
                LOG3("\tadding hash_bits (" << (b+bits.bit) << ", " << ht << "), name:" << name);
                _stageResources[stage]._hashBitsUsage.emplace(std::pair<int, int>(b + bits.bit, ht),
                                                             res);
            }
        }
    }
    for (auto &way : alloc.way_use) {
        for (int hash : bitvec(alloc.hash_table_inputs[way.group])) {
            for (auto bit : bitvec(way.mask)) {
                HashBitResource res(name, cstring(), nullptr, alloc.ternary ? "ternary" : "exact");
                // \TODO: we need to add multiple <name, field> pairs
                // in case we already used this bit.
                LOG3("\tadding resource hash_bits from way_use(" << bit << ", " << hash
                     << "), name:" << name);
                _stageResources[stage]._hashBitsUsage.emplace(std::pair<int, int>(bit, hash), res);
            }
        }
    }
    for (auto &select : alloc.select_use) {
        HashBitResource res(name, cstring(), nullptr, alloc.ternary ? "ternary" : "exact");
        for (int i = 0; i < IXBar::HASH_TABLES; i++) {
            if ((1U << i) & alloc.hash_table_inputs[select.group]) {
                for (int j = 0; j < IXBar::HASH_INDEX_GROUPS; j++) {
                    LOG3("\tadding hash_bits from select_use idx(" << j << ", "
                         << i << "), name:" << name);
                    _stageResources[stage]._hashBitsUsage.emplace(std::pair<int, int>(j, i), res);
                }
                for (int j = 0; j < IXBar::HASH_SINGLE_BITS; j++) {
                    LOG3("\tadding hash_bits from select_use single(" << j << ", "
                         << i << "), name:" << name);
                    _stageResources[stage]._hashBitsUsage.emplace(std::pair<int, int>(j, i), res);
                } } } }
    LOG1("add_xbar_usage (stage=" << stage << "), table: " << name << " done!");
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
                      byte_repr->emplace("byte_type", new Util::JsonValue(use._matchType));
                      char buffer[1024] = "";
                      if (use) {
                          // e.g.: "detail": "{unused[3:0], ethHdr.dmac[27:24]}"
                          snprintf(buffer, sizeof(buffer), "{%s[%d:%d]}",
                                   use._usedByte.name.c_str(), use._usedByte.lo + 7,
                                   use._usedByte.lo);
                      }
                      usagesToCtxJson(byte_repr, use._table,
                                      use._matchType + "_match", cstring(buffer));
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
                      // \TODO: where do we get the match_kind?
                      usagesToCtxJson(bit_repr, use._table, use._matchType, use._field);
                      //  + (use._loc ? " bit " + use._loc->byte : ""));
                      hash_bits->append(bit_repr);
                  });
    hash_bits_res->emplace("bits", hash_bits);
    stage->emplace("hash_bits", hash_bits_res);
}

void Visualization::gen_hashdist(unsigned int /* stageNo */, Util::JsonObject *stage) {
    auto *hash_distr_res = new Util::JsonObject();
    hash_distr_res->emplace("nHashIds", new Util::JsonValue(IXBar::HASH_DIST_SLICES));
    hash_distr_res->emplace("nUnitIds", new Util::JsonValue(IXBar::HASH_DIST_UNITS));
    auto *hash_distr = new Util::JsonArray();
    // \TODO: what do we need to store here?
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

    add_xbar_usage(stage, name, alloc->match_ixbar);
    add_xbar_usage(stage, name + "$register", alloc->salu_ixbar);
    add_xbar_usage(stage, name + "$select", alloc->selector_ixbar);
    add_xbar_usage(stage, name + "$gw", alloc->gateway_ixbar);
    int index = 0;
    for (auto hash_dist : alloc->hash_dists)
        add_xbar_usage(stage, name + "$hash_dist" + std::to_string(index++), hash_dist.use);
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
        BFN::Visualization::usagesToCtxJson(item, tableName, matchType);
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
                    usagesToCtxJson(item, p4name(res));
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
        usagesToCtxJson(lid, t.second);
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
