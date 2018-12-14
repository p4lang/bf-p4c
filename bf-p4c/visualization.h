#ifndef _EXTENSIONS_BF_P4C_VISUALIZATION_H_
#define _EXTENSIONS_BF_P4C_VISUALIZATION_H_

#include <boost/range/irange.hpp>
#include <vector>
#include <set>
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

 private:
    enum node_t { USED_BY, USED_FOR, DETAILS };

    static std::string toString(node_t node) {
        switch (node) {
            case USED_BY:  return "used_by";
            case USED_FOR: return "used_for";
            case DETAILS:  return "details";
            default:  BUG("Unknown node type %d", node);
        }
    }

    /// Root node for resources to be output in context.json
    struct JsonResource {
        // The values for each context JSON node. We want unique instances of each string
        std::map<node_t, std::set<std::string>> json_vectors;

        std::set<node_t> singular_value_nodes;
        std::set<node_t> allowed_empty_nodes;

     public:
        /** Whether the vector for a node type is empty for this type */
        bool is_empty(node_t node) {
            return json_vectors[node].empty();
        }

        /** Whether the vector for a node type only has one value for this type */
        bool is_singular(node_t node) {
            return json_vectors[node].size() == 1;
        }

        void check_sanity(node_t node) {
            if (is_empty(node)) {
                BUG_CHECK(allowed_empty_nodes.count(node),
                    "Node %d cannot have an empty value in the context JSON",
                    node);
            }

            if (!is_singular(node)) {
                BUG_CHECK(!singular_value_nodes.count(node),
                    "Node %d must only have a single value in the context JSON",
                    node);
            }
        }

        /** The first element of for this node */
        std::string at(node_t node) {
            if (json_vectors.at(node).size() > 0)
                return *(json_vectors.at(node).begin());
            else
                return std::string("not found");
        }

        /** A pointer to the set of that node type */
        std::set<std::string> *values(node_t node) {
            return &json_vectors[node];
        }

        std::string total_value(node_t node);
        void add(node_t node, const std::string value);
        void append(JsonResource *jr);

        void dbprint(std::ostream &out) const {
            for (auto kv : json_vectors)
                out << " " << toString(kv.first) << ": " << kv.second;
        }

        JsonResource() {}
    };


    Util::JsonObject *_resourcesNode = nullptr;

    struct XBarByteResource : JsonResource {
        XBarByteResource() {}
        // Cross bar bytes can be shared by multiple tables for different purposes, and
        // the detail can be different due to possible overlay of bytes
    };

    struct HashBitResource : JsonResource {
        HashBitResource() {
            singular_value_nodes = { USED_BY };
        }
        // Each hash bit is reserved to a single table or side effect.  However, because the
        // same bit can be the select bits/RAM line bit for two different ways in the same
        // table, then they can be shared
    };

    // This represents the 48 bits of hash distribution before the hash distribution units
    // are expanded, masked and shifted
    struct HashDistResource : JsonResource {
        HashDistResource() {
            allowed_empty_nodes = { DETAILS };
        }
        // Hash Distribution units can be used for multiple purposes (i.e. two wide addresses
        // between tables
    };

    struct MemoriesResource {
        cstring                   _tableName;
        const TableResourceAlloc *_use;

        MemoriesResource(cstring name, const TableResourceAlloc *use) :
            _tableName(name), _use(use) {}
    };

    struct ActionBusByteResource : JsonResource {
        ActionBusByteResource() {}
    };

    struct IMemColorResource : JsonResource {
        IMemColorResource() {
            allowed_empty_nodes = { USED_FOR };
        }
        unsigned int color = 0;
        gress_t gress = INGRESS;
    };

    /// Collectors for generating the resource schema.
    /// These maps are updated either at the end of the allocation or
    /// when compilation fails to output the set of resources already
    /// allocated.
    struct ResourceCollectors {
        ordered_map<int, XBarByteResource>                 _xBarBytesUsage;
        ordered_map<std::pair<int, int>, HashBitResource>  _hashBitsUsage;
        ordered_map<std::pair<int, int>, HashDistResource> _hashDistUsage;
        std::vector<MemoriesResource>                      _memoriesUsage;
        ordered_map<int, ActionBusByteResource>            _actionBusBytesUsage;
        ordered_map<int, std::vector<IMemColorResource>>   _imemColorUsage;
        /// map logical ids to table names
        ordered_map<int, cstring>                          _logicalIds;

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
                                const std::string &used_by,
                                const std::string &used_for = "",
                                const std::string &detail = "") {
        auto *usages = new Util::JsonArray();
        auto *use = new Util::JsonObject();
        if (!used_by.empty()) {
            // Strip the leading . as p4i shouldn't see it
            use->emplace("used_by", new Util::JsonValue(used_by.substr(used_by[0] == '.'? 1 : 0)));
            if (!used_for.empty())
                use->emplace("used_for", new Util::JsonValue(used_for));
            if (!detail.empty())
                use->emplace("detail", new Util::JsonValue(detail));
        } else {
            use->emplace("used_by", new Util::JsonValue("--UNUSED--"));
        }
        usages->append(use);
        parent->emplace("usages", usages);
    }

    /// The vector version of the usages node, where there are multiple
    /// used_for usages.
    static void usagesToCtxJson(Util::JsonObject *parent,
                                std::set<std::string> *used_by,
                                std::set<std::string> *used_for,
                                const std::string &detail) {
        auto *usages = new Util::JsonArray();
        if (!used_by->empty()) {
            // we need to output an element in the usages array for the cross-product of
            // used_by and used_for. The detail set is the collection of all details.
            for (auto each_use : *used_by)
                std::for_each(used_for->begin(), used_for->end(),
                              [usages, each_use, detail] (const std::string& u) {
                    auto *use = new Util::JsonObject();
                    // Strip the leading . as p4i shouldn't see it
                    auto use_by = each_use.substr(each_use[0] == '.' ? 1 : 0);
                    use->emplace("used_by", new Util::JsonValue(use_by));
                    use->emplace("used_for", new Util::JsonValue(u));
                    if (!detail.empty())
                        use->emplace("detail", new Util::JsonValue(detail));
                    usages->append(use); });
        } else {
            auto *use = new Util::JsonObject();
            use->emplace("used_by", new Util::JsonValue("--UNUSED--"));
            usages->append(use);
        }
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
    void add_xbar_bytes_usage(unsigned int stageNo, const IXBar::Use &alloc);
    void add_hash_dist_usage(unsigned int stageNo, const IXBar::HashDistUse &alloc);
    void add_action_bus_bytes_usage(unsigned int stageNo, const ActionDataBus::Use &alloc,
                                    cstring tableName);
    void add_vliw_usage(unsigned int stageNo, const InstructionMemory::Use &alloc,
                        gress_t gress, cstring tableName);

    void gen_xbar_bytes(unsigned int stageNo, Util::JsonObject *stage);
    void gen_hash_bits(unsigned int stageNo, Util::JsonObject *stage);
    void gen_hashdist(unsigned int stageNo, Util::JsonObject *stage);
    /// Output the _memoriesUsage object into a json representation to be
    /// consumed by p4i. See memory related nodes in the context.json
    /// schema: rams, map_rams, gateways, meter_alus, statistic_alus,
    /// tcams.
    void gen_memories(unsigned int stageNo, Util::JsonObject *stage);
    void gen_action_bus_bytes(unsigned int stageNo, Util::JsonObject *stage);
    void gen_action_slots(unsigned int stageNo, Util::JsonObject *stage);
    void gen_vliw(unsigned int stageNo, Util::JsonObject *stage);
    void gen_exm_search_buses(unsigned int stageNo, Util::JsonObject *stage);
    void gen_exm_result_buses(unsigned int stageNo, Util::JsonObject *stage);
    void gen_tind_result_buses(unsigned int stageNo, Util::JsonObject *stage);
};

}  // namespace BFN

#endif /* _EXTENSIONS_BF_P4C_VISUALIZATION_H_ */
