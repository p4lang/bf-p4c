#ifndef _EXTENSIONS_BF_P4C_VISUALIZATION_H_
#define _EXTENSIONS_BF_P4C_VISUALIZATION_H_

#include <boost/range/irange.hpp>
#include <vector>
#include "common/asm_output.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/json.h"
#include "lib/ordered_map.h"
#include "mau/input_xbar.h"
#include "mau/memories.h"
#include "parde/phase0.h"

namespace BFN {

class Visualization : public Inspector {
 private:
    // profile_t init_apply(const IR::Node *root) override {
    //     root->apply(default_next);
    //     return MauInspector::init_apply(root); }
    void end_apply() override {
        // \TODO: handle multiple pipes
        int stages =  _stageResources.size();
        for (auto s : boost::irange(0, stages))
            gen_stage(s);
    }

    bool preorder(const IR::BFN::Pipe *p) override;

    bool preorder(const IR::MAU::Table *tbl) override {
        if (!tbl->match_table) {
            LOG1("Can't find name for table" << *tbl);
            return true;
        }
        auto tblName = canon_name(tbl->match_table->externalName());
        add_table_usage(tblName, tbl);
        return true;
    }
    void postorder(const IR::MAU::Selector *as) override {
        auto *tbl = findContext<IR::MAU::Table>();
        if (tbl == nullptr) {
            LOG1("Can't find table for selector" << *as);
            return;
        }
        auto name = tbl->get_use_name(as);
        if (tbl->resources->memuse.count(name))
            // selector_memory[as] = &tbl->resources->memuse.at(name);
            add_table_usage(name, tbl);  // \TODO: handle only selector resources
    }
    bool preorder(const IR::MAU::StatefulAlu *) override {
        return false;
    }

 private:
    /// Root node for resources to be output in context.json
    Util::JsonObject *_resourcesNode = nullptr;

    struct XBarByteResource {
        const IXBar::Use::Byte  _usedByte;
        cstring                 _table;
        cstring                 _matchType;

        explicit XBarByteResource(const IXBar::Use::Byte *b, cstring tblName, cstring matchType) :
            _usedByte(*b), _table(tblName), _matchType(matchType) {}

        explicit operator bool() const { return _usedByte.loc && _table && _matchType; }
    };

    struct HashBitResource {
        cstring           _table;
        cstring           _field;
        const IXBar::Loc *_loc;
        cstring           _matchType;

        explicit HashBitResource(cstring tblName, cstring fieldName, const IXBar::Loc *loc,
                                 cstring matchType) :
            _table(tblName), _field(fieldName), _loc(loc), _matchType(matchType) {}

        explicit operator bool() const {
            return _table && (_loc ? bool(*_loc) : true) && _matchType; }
    };

    struct MemoriesResource {
        cstring                   _tableName;
        const TableResourceAlloc *_use;

        explicit MemoriesResource(cstring name, const TableResourceAlloc *use) :
            _tableName(name), _use(use) {}
    };

    /// Collectors for generating the resource schema.
    /// These maps are updated either at the end of the allocation or
    /// when compilation fails to output the set of resources already
    /// allocated.
    struct ResourceCollectors {
        ordered_map<int, XBarByteResource>                _xBarBytesUsage;
        ordered_map<std::pair<int, int>, HashBitResource> _hashBitsUsage;
        std::vector<MemoriesResource>                     _memoriesUsage;
        /// map logical ids to table names
        ordered_map<int, cstring>                         _logicalIds;

        ResourceCollectors() {}
    };

    std::vector<ResourceCollectors> _stageResources;

 public:
    /// toggle whether to output unused resources
    static constexpr bool OUTPUT_UNUSED = false;

    Visualization();

    /// Skeleton to generate a "usages" node.
    /// In case the argument is the empty string, we output "--UNUSED--"
    static void usagesToCtxJson(Util::JsonObject *parent,
                                const cstring &used_by,
                                const cstring &used_for = cstring(),
                                const cstring &detail = cstring()) {
        auto *usages = new Util::JsonArray();
        auto *use = new Util::JsonObject();
        if (used_by) {
            use->emplace("used_by", new Util::JsonValue(used_by));
            if (used_for)
                use->emplace("used_for", new Util::JsonValue(used_for));
            if (detail)
                use->emplace("detail", new Util::JsonValue(detail));
        } else {
            use->emplace("used_by", new Util::JsonValue("--UNUSED--"));
        }
        usages->append(use);
        parent->emplace("usages", usages);
    }

    Util::JsonObject *getResourcesNode() { return _resourcesNode; }

    /// return a pointer to `stage` in `pipe`
    /// If the stage does not exist, create it and return the new object
    /// If the pipe does not exist, it is an error
    Util::JsonObject *getStage(unsigned int stage, unsigned int pipe = 0);

    /// Traverse the collectors and generate all the json objects
    void gen_stage(unsigned int stage);

    /// Account for all table resources
    void add_table_usage(cstring name, const IR::MAU::Table *table);

    /// output the json hierarchy into the asm file (as Yaml)
    friend std::ostream & operator<<(std::ostream &out, const Visualization &vis);

 private:
    /// Update the collectors for each different type of resource
    void add_xbar_usage(unsigned int stageNo, cstring name, const IXBar::Use &alloc);
    void add_action_usage(unsigned int /* stageNo */, cstring /* name , Table?? */) {}

    void gen_xbar(unsigned int stageNo, Util::JsonObject *stage);
    void gen_hashbits(unsigned int stageNo, Util::JsonObject *stage);
    void gen_hashdist(unsigned int stageNo, Util::JsonObject *stage);
    /// Output the _memoriesUsage object into a json representation to be
    /// consumed by p4i. See memory related nodes in the context.json
    /// schema: rams, map_rams, gateways, meter_alus, statistic_alus,
    /// tcams.
    void gen_memories(unsigned int stageNo, Util::JsonObject *stage);
    void gen_actions(unsigned int stageNo, Util::JsonObject *stage);
};

}  // namespace BFN

#endif /* _EXTENSIONS_BF_P4C_VISUALIZATION_H_ */
