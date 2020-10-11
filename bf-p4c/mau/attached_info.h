#ifndef BF_P4C_MAU_ATTACHED_INFO_H_
#define BF_P4C_MAU_ATTACHED_INFO_H_

#include "bf-p4c/mau/mau_visitor.h"
#include "lib/ordered_set.h"
#include "lib/ordered_map.h"

class ValidateAttachedOfSingleTable : public MauInspector {
 public:
    enum addr_type_t { STATS, METER, ACTIONDATA, TYPES };
    using TypeToAddressMap = std::map<addr_type_t, IR::MAU::Table::IndirectAddress>;

 private:
    const IR::MAU::Table *tbl;
    TypeToAddressMap &ind_addrs;

    std::map<addr_type_t, const IR::MAU::BackendAttached *> users;

    cstring addr_type_name(addr_type_t type) {
        switch (type) {
            case STATS: return "stats";
            case METER: return "meter";
            case ACTIONDATA: return "action";
            default: return "";
        }
    }

    bool compatible(const IR::MAU::BackendAttached *, const IR::MAU::BackendAttached *);
    void free_address(const IR::MAU::AttachedMemory *am, addr_type_t type);

    bool preorder(const IR::MAU::Counter *cnt) override;
    bool preorder(const IR::MAU::Meter *mtr) override;
    bool preorder(const IR::MAU::StatefulAlu *salu) override;
    bool preorder(const IR::MAU::Selector *as) override;
    bool preorder(const IR::MAU::TernaryIndirect *) override {
        BUG("No ternary indirect should exist before table placement");
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override;
    bool preorder(const IR::MAU::IdleTime *) override {
        return false;
    }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", typeid(*att).name());
    }


 public:
    ValidateAttachedOfSingleTable(TypeToAddressMap &ia, const IR::MAU::Table *t)
        : tbl(t), ind_addrs(ia) {}
};

/**
 * The address is contained in an entry if the address comes from overhead.  This is also
 * when it is necessary to pass it through PHV if the stateful ALU is in a different stage
 * than the match table
 *
 * Per flow enable bit needed on a table when:
 *    - A table has at least two actions that run on hit, where one action runs the stateful
 *      ALU, and another action does not
 *    - When a table is linked with a gateway, the gateway runs a no hit stateful ALU
 *      instruction.  This is only known during table placement.
 *
 * If the stateful ALU is in a different stage than the match table, the enable bit needs to
 * move through PHV if:
 *     - Only the first bullet point, as the by running the noop instruction from the gateway
 *       the enable bit will never run 
 *     - On at least one miss action, the stateful ALU does not run.
 *
 * Meter type is necessary on a table when:
 *     - A table has two actions where the stateful instruction type is different
 *     - A table is linked to a gateway, and the stateful ALU has more than one instruction
 *       across all tables
 *
 * If the stateful ALU is in a different stage than the match table, the type needs to move
 * through PHV if:
 *     - Only the first bullet point, as in the second, the type can just come from payload from
 *       a gateway running a hash action table
 *     - On the miss action, the stateful ALU has a different stateful instruction than
 *       any of the hit actions
 */

class PhvInfo;

/// Search for references to an AttachedMemory in instruction -- returns a bitmap of which
/// operands refer to the AttachedMemory
class HasAttachedMemory : public MauInspector {
    const IR::MAU::AttachedMemory *am_match;
    unsigned _found = 0U;

    profile_t init_apply(const IR::Node *node) {
        auto rv = MauInspector::init_apply(node);
        _found = 0;
        return rv;
    }

    bool preorder(const IR::MAU::AttachedMemory *am) {
        unsigned mask = 1U;
        const Visitor::Context *ctxt = nullptr;
        if (findContext<IR::MAU::Primitive>(ctxt)) {
            BUG_CHECK(ctxt->child_index >= 0 && ctxt->child_index < 32, "mask overflow");
            mask <<= ctxt->child_index; }
        if (am_match == am)
            _found |= mask;
        return false;
    }
 public:
    explicit HasAttachedMemory(const IR::MAU::AttachedMemory *am) : am_match(am) {}
    unsigned found() const { return _found; }
};

/**
 * The purpose of this pass is to gather the requirements of what needs to pass through
 * PHV if this stateful ALU portion is split from the match portion
 */
class SplitAttachedInfo : public PassManager {
    // Can't use IR::Node * as keys in a map, as they change in transforms.  Names
    // are unique and stable, so use them instead.
    ordered_map<cstring, ordered_set<const IR::MAU::Table *>> attached_to_table_map;
    // FIXME -- can have multiple tables attached to a match table (meter + stats),
    // so this needs to map to a set of AttachedMemory...
    ordered_map<cstring, const IR::MAU::AttachedMemory *> table_to_attached_map;
    // ordered_map<cstring, bitvec> types_per_attached;  -- unused

    struct IndexTemp {
        const IR::TempVar *index = nullptr;
        const IR::TempVar *enable = nullptr;
        const IR::TempVar *type = nullptr;
    };
    std::map<cstring, IndexTemp>  index_tempvars;

    // Not linked via gateway with information
    struct AddressInfo {
        ///> If the ALU is run in every hit action of the table
        bool always_run_on_hit = true;
        ///> If the ALU is run on every miss action of the table
        bool always_run_on_miss = true;
        ///> The number of address bits stored in overhead
        int address_bits = 0;
        ///> The number of bis that are necessary to come through the hash engine
        int hash_bits = 0;
        ///> The number of meter types possible in the table's hit action.  Each action
        ///> currently supports one meter type, (i.e. which stateful instruction to run)
        ///> but different actions can have different types
        bitvec types_on_hit;
        ///> The number of meter types possible in a table's miss actions
        bitvec types_on_miss;
    };

    ordered_map<cstring, AddressInfo> address_info_per_table;

    profile_t init_apply(const IR::Node *node) {
        auto rv = PassManager::init_apply(node);
        attached_to_table_map.clear();
        table_to_attached_map.clear();
        // types_per_attached.clear();
        address_info_per_table.clear();
        return rv;
    }

    /**
     * Builds maps between tables and attached memories that can be split
     */
    class BuildSplitMaps : public MauInspector {
        SplitAttachedInfo &self;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit BuildSplitMaps(SplitAttachedInfo &s) : self(s) {}
    };


    /**
     * For each action in a table, determine if the attached memory is enabled within
     * that action, and if enabled, what meter type each action required.  Used for
     * filling the AddressInfo of a table
     */
    class EnableAndTypesOnActions : public MauInspector {
        SplitAttachedInfo &self;
        bool preorder(const IR::MAU::Action *) override;

     public:
        explicit EnableAndTypesOnActions(SplitAttachedInfo &s) : self(s) {}
    };

    class ValidateAttachedOfAllTables : public MauInspector {
        SplitAttachedInfo &self;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit ValidateAttachedOfAllTables(SplitAttachedInfo &s) : self(s) {}
    };

 public:
    SplitAttachedInfo() {
        addPasses({
            new BuildSplitMaps(*this),
            new ValidateAttachedOfAllTables(*this),
            new EnableAndTypesOnActions(*this)
        });
    }

    const IR::MAU::AttachedMemory *attached_from_table(const IR::MAU::Table *tbl) const {
        if (table_to_attached_map.count(tbl->name) == 0)
            return nullptr;
        return table_to_attached_map.at(tbl->name);
    }

 private:
    int addr_bits_to_phv_on_split(const IR::MAU::Table *tbl) const;
    bool enable_to_phv_on_split(const IR::MAU::Table *tbl) const;
    int type_bits_to_phv_on_split(const IR::MAU::Table *tbl) const;

 public:
    // public so ActionData::Format can call it (why?)
    const IR::MAU::Instruction *pre_split_addr_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv);

 private:
    const IR::MAU::Instruction *pre_split_enable_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv);
    const IR::MAU::Instruction *pre_split_type_instr(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv);

 public:
    const IR::Expression *split_enable(const IR::MAU::AttachedMemory *);
    const IR::Expression *split_index(const IR::MAU::AttachedMemory *);
    const IR::MAU::Action *create_pre_split_action(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, PhvInfo *phv);
    const IR::MAU::Action *create_post_split_action(const IR::MAU::Action *act,
        const IR::MAU::Table *tbl, bool reduction_or = false);
};

#endif  /* BF_P4C_MAU_ATTACHED_INFO_H_ */
