#include "bf-p4c/parde/decaf.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"

namespace {

struct Value {
    const PHV::Field* field = nullptr;
    const IR::Constant* constant = nullptr;

    Value() {}
    explicit Value(const PHV::Field* f) : field(f) { }
    explicit Value(const IR::Constant* c) : constant(c) {
        if (!c->fitsUint64())
            P4C_UNIMPLEMENTED("constant too large (than uint64");
    }

    explicit Value(const Value& other)
        : field(other.field), constant(other.constant) {
        if (field && constant)
            BUG("Value cannot be both field or constant");
    }

    void print() const {
        if (field) {
            std::clog << field->name;
        } else if (constant) {
            std::clog << "0x" << std::hex << constant << std::dec;
        }
    }

    bool operator<(const Value& other) const {
        if (field && other.field)
            return field->id < other.field->id;
        else if (constant && other.constant)
            return constant->value < other.constant->value;
        else if (field && other.constant)
            return false;
        else if (constant && other.field)
            return true;

        BUG("Value is neither constant nor field?");
    }
};

struct Assign {
    Assign(const IR::MAU::Instruction* instr,
           const PHV::Field* dst,
           const IR::Constant* src) :
        dst(dst), src(new Value(src)), instr(instr) { }

    Assign(const IR::MAU::Instruction* instr,
           const PHV::Field* dst,
           const PHV::Field* src) :
        dst(dst), src(new Value(src)), instr(instr) { }

    void print() const {
        std::clog << dst->name << " <= ";
        src->print();
    }

    const PHV::Field* dst;
    const Value* src;

    const IR::MAU::Instruction* instr = nullptr;
};

class AssignChain : public std::list<const Assign*> {
 public:
    // TODO ==, <
};

static void print_fields(const ordered_set<const PHV::Field*>& group) {
    for (auto f : group)
        std::clog << "    " << f->name << std::endl;
}

struct CollectHeaderValidBits : public DeparserInspector {
    const PhvInfo &phv;
    std::map<const PHV::Field*, const IR::Expression*> field_to_valid_bit;

    explicit CollectHeaderValidBits(const PhvInfo &phv) : phv(phv) { }

    bool preorder(const IR::BFN::EmitField* emit) override {
        auto f = phv.field(emit->source->field);
        auto pov_bit = emit->povBit->field;

        field_to_valid_bit[f] = pov_bit;

        return false;
    }
};

/*
    We categorize fields that are referenced in the control flow as either strong or
    weak. The strong fields are ones that participate in match, non-move instruction, action
    data bus read, or other reasons (non packet defs, is part of a checksum update or
    digest). The weak fields are, by exclusion, the ones that are not strong. Weak fields
    also shall not have a transitive strong source. All weak fields are then decaf candidates.
*/
class CollectWeakFields : public Inspector, BFN::ControlFlowVisitor {
    const PhvInfo &phv;
    const PhvUse &uses;

    ordered_set<const PHV::Field*> strong_fields;

    ordered_map<const IR::MAU::Instruction*, const IR::MAU::Action*> instr_to_action;
    ordered_map<const IR::MAU::Action*, const IR::MAU::Table*> action_to_table;

 public:
    ordered_map<const PHV::Field*, ordered_set<const Assign*>> field_to_weak_assigns;
    ordered_set<const PHV::Field*> read_only_weak_fields;
    std::map<gress_t, ordered_set<const IR::Constant*>> all_constants;

    CollectWeakFields(const PhvInfo &phv, const PhvUse &uses) : phv(phv), uses(uses) {
        joinFlows = true;
        visitDagOnce = false;
    }

    const IR::MAU::Action* get_action(const Assign* assign) const {
        auto action = instr_to_action.at(assign->instr);
        return action;
    }

    const IR::MAU::Table* get_table(const Assign* assign) const {
        auto action = instr_to_action.at(assign->instr);
        auto table = action_to_table.at(action);
        return table;
    }

    void print_assign_context(const Assign* assign) const {
        auto action = instr_to_action.at(assign->instr);
        auto table = action_to_table.at(action);

        std::clog << "(" << table->name << " : " << action->name << ")";
    }

    void print_assign(const Assign* assign) const {
        assign->print();
        std::clog << " : ";
        print_assign_context(assign);
        std::clog << std::endl;
    }

 private:
    bool filter_join_point(const IR::Node*) override { return true; }

    void flow_merge(Visitor &other_) override {
        CollectWeakFields &other = dynamic_cast<CollectWeakFields &>(other_);

        for (auto& kv : other.field_to_weak_assigns) {
            for (auto a : kv.second)
                field_to_weak_assigns[kv.first].insert(a);
        }

        strong_fields.insert(other.strong_fields.begin(), other.strong_fields.end());

        for (auto a : strong_fields)
            elim_strong_field(a);

        for (auto& kv : other.instr_to_action)
            instr_to_action[kv.first] = kv.second;

        for (auto& kv : other.action_to_table)
            action_to_table[kv.first] = kv.second;
    }

    CollectWeakFields *clone() const override {
        return new CollectWeakFields(*this);
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);

        field_to_weak_assigns.clear();
        strong_fields.clear();

        instr_to_action.clear();
        action_to_table.clear();

        return rv;
    }

    void end_apply() override {
        elim_by_strong_transitivity();

        add_read_only_weak_fields();

        get_all_constants();

        if (LOGGING(2))
            print_all_weak_fields();

        LOG1("done collecting weak fields");
    }

    void add_weak_assign(const PHV::Field* dst,
                         const PHV::Field* field_src,
                         const IR::Constant* const_src,
                         const IR::MAU::Instruction* instr) {
        BUG_CHECK(((field_src && !const_src) || (!field_src && const_src)),
                  "Expect source to be either a PHV field or constant");

        if (field_src && field_src == dst) {
            LOG3("src is dst");
            return;
        }

        auto assign = const_src ? new Assign(instr, dst, const_src)
                                : new Assign(instr, dst, field_src);

        field_to_weak_assigns[dst].insert(assign);
    }

    void elim_strong_field(const PHV::Field* f) {
        strong_fields.insert(f);

        field_to_weak_assigns.erase(f);
    }

    static bool other_elim_reason(const PHV::Field* f) {
        return f->pov || f->metadata || f->is_digest() || f->is_intrinsic();
    }

    bool preorder(const IR::MAU::InputXBarRead* ixbar) override {
        auto f = phv.field(ixbar->expr);
        elim_strong_field(f);

        LOG2(f->name << " is not a candidate (match)");

        return false;
    }

    bool preorder(const IR::MAU::StatefulAlu*) override {
        return false;
    }

    bool preorder(const IR::MAU::Instruction* instr) override {
        auto table = findContext<IR::MAU::Table>();
        auto action = findContext<IR::MAU::Action>();

        instr_to_action[instr] = action;
        action_to_table[action] = table;

        auto dst = instr->operands[0];
        auto f_dst = phv.field(dst);

        if (!f_dst) {
            LOG2(dst << " is not a candidate (non-PHV field)");
            return false;
        }

        if (strong_fields.count(f_dst)) {
            return false;
        }

        if (instr->name != "set") {
            for (auto op : instr->operands) {
                auto f_op = phv.field(op);
                if (f_op) {
                    elim_strong_field(f_op);
                    LOG2(f_op->name << " is not a candidate (non-move instr)");
                }
            }
            return false;
        }

        auto src = instr->operands[1];
        auto f_src = phv.field(src);

        if (src->is<IR::MAU::ActionArg>()) {
            LOG2(f_dst->name << " is not a candidate (action param)");
            elim_strong_field(f_dst);
            return false;
        }

        // We eliminate fields that are checksummed in the deparser, because the
        // checksum engine can only refer to each PHV container once (no multiple
        // references of the same field). Therefore we do need the field's updated
        // value to reach the deparser in a normal container.

        if (f_dst->is_checksummed()) {
            LOG2(f_dst->name << " is not a candidate (checksummed)");
            elim_strong_field(f_dst);
            return false;
        }

        if (other_elim_reason(f_dst) || (f_src && other_elim_reason(f_src))) {
            LOG2(f_dst->name << " is not a candidate (pov|metadata|digest)");
            elim_strong_field(f_dst);
            return false;
        }

        add_weak_assign(f_dst, f_src, src->to<IR::Constant>(), instr);

        return false;
    }

    bool has_strong_source(const PHV::Field* f, std::set<const PHV::Field*>& visited) {
        if (visited.count(f))
            return false;

        visited.insert(f);

        if (strong_fields.count(f))
            return true;

        if (!field_to_weak_assigns.count(f)) {
            for (auto assign : field_to_weak_assigns.at(f)) {
                if (assign->src->field && has_strong_source(assign->src->field, visited))
                    return true;
            }
        }

        return false;
    }

    bool has_strong_source(const PHV::Field* f) {
        std::set<const PHV::Field*> visited;
        return has_strong_source(f, visited);
    }

    void add_read_only_weak_fields() {
        for (auto& kv : phv.get_all_fields()) {
            auto f = &(kv.second);

            if (!uses.is_used_mau(f))  // already a tagalong field
                continue;

            if (strong_fields.count(f))
                continue;

            if (field_to_weak_assigns.count(f))
                continue;

            if (other_elim_reason(f))
                continue;

            read_only_weak_fields.insert(f);
        }
    }

    void get_all_constants() {
        for (auto& kv : field_to_weak_assigns) {
            for (auto& assign : kv.second) {
                auto gress = kv.first->gress;
                if (assign->src->constant) {
                    bool new_constant = true;

                    for (auto uc : all_constants[gress]) {
                        if (uc->equiv(*(assign->src->constant))) {
                            new_constant = false;
                            break;
                        }
                    }

                    if (new_constant)
                        all_constants[gress].insert(assign->src->constant);
                }
            }
        }
    }

    void elim_by_strong_transitivity() {
        // elim all fields that have a strong source (directly or transitively)

        std::set<const PHV::Field*> to_delete;

        for (auto& kv : field_to_weak_assigns) {
            auto f = kv.first;
            if (has_strong_source(f))
                to_delete.insert(f);
        }

        for (auto f : to_delete) {
            LOG2(f->name << " is not a candidate (has strong src)");
            elim_strong_field(f);
        }
    }

    void print_all_weak_fields() {
        unsigned total_field_bits = 0;

        for (auto f : read_only_weak_fields) {
            total_field_bits += f->size;

            std::clog << "\nfield: " << f->name << " : "
                      << f->size << " (read-only)" << std::endl;
        }

        for (auto& kv : field_to_weak_assigns) {
            auto dst = kv.first;

            total_field_bits += dst->size;

            std::clog << "\nfield: " << dst->name << " : " << dst->size << std::endl;

            int id = 0;
            for (auto& assign : kv.second) {
                std::clog << "     " << id++ << ": ";
                print_assign(assign);
            }
        }

        std::clog << "\ntotal weak field bits: " << total_field_bits << std::endl;

        std::clog << "\nall unique constants:" << std::endl;

        for (auto& kv : all_constants) {
            std::clog << kv.first << ":" << std::endl;
            unsigned total_constant_bytes = 0;

            for (auto c : kv.second) {
                auto bits = c->type->to<IR::Type_Bits>();
                total_constant_bytes += (bits->size + 7) / 8;

                std::clog << "    0x" << std::hex << c << std::dec << std::endl;
            }

            std::clog << "\ntotal constant bytes: " << total_constant_bytes << std::endl;
        }
    }
};

class ComputeValuesAtDeparser : public Inspector {
 public:
    std::vector<ordered_set<const PHV::Field*>> weak_field_groups;

    ordered_map<const PHV::Field*,
             ordered_map<Value, ordered_set<AssignChain>>> values_at_deparser;

    const CollectWeakFields& weak_fields;

    explicit ComputeValuesAtDeparser(const CollectWeakFields& weak_fields)
        : weak_fields(weak_fields) { }

 public:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);

        weak_field_groups.clear();
        values_at_deparser.clear();

        group_weak_fields();

        for (auto& group : weak_field_groups)
            compute_all_reachable_values_at_deparser(group);

        return rv;
    }

    // Group fields that have transitive assignment to one another. Basically members
    // in a group can only take on the value of other members in the group, or constant.
    void group_weak_fields() {
        for (auto& kv : weak_fields.field_to_weak_assigns) {
            auto f = kv.first;

            bool found_union = false;

            for (auto& group : weak_field_groups) {
                if (found_union)
                    break;

                if (group.count(f)) {
                    found_union = true;
                    break;
                }

                for (auto assign : kv.second) {
                    if (assign->src->field) {
                        if (group.count(assign->src->field)) {
                            found_union = true;
                            group.insert(f);
                            break;
                        }
                    }
                }
            }

            if (!found_union) {
                ordered_set<const PHV::Field*> new_set;

                new_set.insert(f);

                for (auto assign : kv.second)
                    if (assign->src->field)
                        new_set.insert(assign->src->field);

                weak_field_groups.push_back(new_set);
            }
        }

        std::stable_sort(weak_field_groups.begin(), weak_field_groups.end(),
                         [=](const ordered_set<const PHV::Field*>& a,
                             const ordered_set<const PHV::Field*>& b) {
            return a.size() < b.size();
        });

        LOG1("\ntotal weak field groups: " << weak_field_groups.size());

        if LOGGING(1) {
            for (unsigned i = 0; i < weak_field_groups.size(); i++) {
                std::clog << i << ":" << std::endl;

                print_fields(weak_field_groups[i]);
            }
        }
    }

    std::vector<const IR::MAU::Table*>
    get_next_tables(const IR::MAU::Table* curr_table,
                    const ordered_map<const IR::MAU::Table*,
                                    ordered_set<const Assign*>>& table_to_assigns) {
        // XXX(zma) assumes only 2 tables; in general need to get the next tables
        // from table graph.

        BUG_CHECK(table_to_assigns.size() <= 2, "more than 2 tables?");

        std::vector<const IR::MAU::Table*> next_tables;

        bool found_curr_table = false;
        for (auto& kv : table_to_assigns) {
            if (found_curr_table) {
                next_tables.push_back(kv.first);
                break;
            }

            if (curr_table == kv.first)
                found_curr_table = true;
        }

        BUG_CHECK(found_curr_table, "current table not found?");

        return next_tables;
    }

    ordered_set<AssignChain>
    enumerate_all_assign_chains(const IR::MAU::Table* curr_table,
                                const ordered_map<const IR::MAU::Table*,
                                    ordered_set<const Assign*>>& table_to_assigns) {
        ordered_set<AssignChain> all_chains_at_curr_table;

        auto next_tables = get_next_tables(curr_table, table_to_assigns);

        for (auto next_table : next_tables) {
            auto all_chains_at_next_table =
                enumerate_all_assign_chains(next_table, table_to_assigns);

            for (auto chain : all_chains_at_next_table)
                all_chains_at_curr_table.insert(chain);

            for (auto assign : table_to_assigns.at(curr_table)) {
                for (auto chain : all_chains_at_next_table) {
                    chain.push_front(assign);
                    all_chains_at_curr_table.insert(chain);
                }
            }
        }

        for (auto assign : table_to_assigns.at(curr_table)) {
            AssignChain chain;
            chain.push_back(assign);
            all_chains_at_curr_table.insert(chain);
        }

        return all_chains_at_curr_table;
    }

    ordered_map<const PHV::Field*, Value>
    propagate_value_on_assign_chain(const AssignChain& chain) {
        ordered_map<const PHV::Field*, Value> rv;

        for (auto assign : chain) {
            if (assign->src->field) {
                if (rv.count(assign->src->field)) {
                    Value val(rv.at(assign->src->field));
                    rv[assign->dst] = val;
                    continue;
                }
            }

            rv[assign->dst] = *(assign->src);
        }

        return rv;
    }

    void print_assign_chain(const AssignChain& chain) {
        for (auto assign : chain) {
            std::clog << "    ";
            weak_fields.print_assign(assign);
        }
    }

    void print_assign_chains(const ordered_set<AssignChain>& chains) {
        unsigned i = 0;
        for (auto& chain : chains) {
            std::clog << i++ << ":" << std::endl;
            print_assign_chain(chain);
        }
    }

    // Perform copy/constant propagation for the group based on table dependency.
    // For each field, what are the all possible values that are reachable at the
    // deparser?
    void compute_all_reachable_values_at_deparser(
            const ordered_set<const PHV::Field*>& weak_field_group) {
        LOG1("\ncompute all values for group:");

        if (LOGGING(1))
            print_fields(weak_field_group);

        ordered_map<const IR::MAU::Table*,
                    ordered_set<const Assign*>> table_to_assigns;

        for (auto f : weak_field_group) {
            if (weak_fields.read_only_weak_fields.count(f))
                continue;

            for (auto assign : weak_fields.field_to_weak_assigns.at(f)) {
                auto table = weak_fields.get_table(assign);
                table_to_assigns[table].insert(assign);
            }
        }

        // TODO(zma) For more than 2 tables, we need to propagate the values based on
        // the lattice order of table dependency, which is non-trivial. As first
        // cut, limit to 2 tables (sufficient for the tunnel encap/decap use case).
        // We also assume the tables are independently predicated which is an overly
        // conversative assumption. A table can be predicated by another table;

        if (table_to_assigns.size() > 2) {
            LOG1("\nmore than 2 tables involved for group, skip");

            if (LOGGING(2)) {
                for (auto& kv : table_to_assigns)
                    std::clog << "    " << (kv.first)->name << std::endl;
            }

            return;
        }

        auto first_table = (table_to_assigns.begin())->first;
        auto all_chains = enumerate_all_assign_chains(first_table, table_to_assigns);

        LOG2("\ntotal assign chains: " << all_chains.size());

        if (LOGGING(2))
            print_assign_chains(all_chains);

        for (auto& chain : all_chains) {
            auto value_map_for_chain = propagate_value_on_assign_chain(chain);

            for (auto& kv : value_map_for_chain) {
                auto field = kv.first;
                auto& value = kv.second;

                auto& value_map_for_field = values_at_deparser[field];
                value_map_for_field[value].insert(chain);
            }
        }

        LOG2("\ndeparser value map for group:");

        if (LOGGING(2)) {
            for (auto f : weak_field_group) {
                std::clog << "field: " << f->name << std::endl;

                if (weak_fields.read_only_weak_fields.count(f))
                    continue;

                auto& value_map_for_field = values_at_deparser.at(f);

                std::clog << "values:" << value_map_for_field.size() << std::endl;
                for (auto& kv : value_map_for_field) {
                    auto& value = kv.first;
                    auto& chains = kv.second;

                    value.print();
                    std::clog << ":" << std::endl;
                    std::clog << "chains:" << std::endl;
                    print_assign_chains(chains);
                }
            }
        }
    }
};

static IR::TempVar* create_temp_var(cstring name, unsigned width, bool is_pov = false) {
    return new IR::TempVar(IR::Type::Bits::get(width), is_pov, name);
}

static IR::TempVar* create_bit(cstring name, bool is_pov = false) {
    return create_temp_var(name, 1, is_pov);
}

static IR::MAU::Instruction* create_set_bit_instr(const IR::TempVar* dst) {
    return new IR::MAU::Instruction("set",
            { dst, new IR::Constant(IR::Type::Bits::get(1), 1) });
}

class SynthesizePovEncoder : public MauTransform {
    const CollectHeaderValidBits& pov_bits;
    const CollectWeakFields& weak_fields;
    const ComputeValuesAtDeparser& values_at_deparser;

    std::map<gress_t, std::vector<IR::MAU::Table*>> tables_to_insert;

 public:
    ordered_map<const IR::MAU::Action*, const IR::TempVar*> action_to_ctl_bit;

    ordered_map<const PHV::Field*,
             ordered_map<Value, const IR::TempVar*>> value_to_pov_bit;

    ordered_map<const PHV::Field*, const IR::TempVar*> default_pov_bit;

    explicit SynthesizePovEncoder(
        const CollectHeaderValidBits& pov_bits,
        const ComputeValuesAtDeparser& values_at_deparser) :
            pov_bits(pov_bits),
            weak_fields(values_at_deparser.weak_fields),
            values_at_deparser(values_at_deparser) { }

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = MauTransform::init_apply(root);

        tables_to_insert.clear();
        value_to_pov_bit.clear();
        action_to_ctl_bit.clear();

        // As the first cut, we create a table for each group, which is not very
        // efficient since many of these table are computing the same function --
        // need to canonicalize any duplicate functions (TODO)
        // Also, within each table, we can compress the number of match entries
        // using don't care's (and use TCAM to implement table) -- this is classical
        // boolean optimization (TODO).

        for (auto& group : values_at_deparser.weak_field_groups) {
            auto table = synthesize_pov_encoder(group);
            tables_to_insert[table->gress].push_back(table);
        }

        return rv;
    }

    void end_apply() override {
        LOG1("done synthesizing pov encoder");
    }

    gress_t get_gress(const ordered_set<const PHV::Field*>& group) {
        auto it = group.begin();
        return (*it)->gress;
    }

    std::vector<const IR::Expression*>
    get_valid_bits(const ordered_set<const PHV::Field*>& group) {
        ordered_set<const IR::Expression*> valid_bits;

        for (auto f : group) {
            auto pov_bit = pov_bits.field_to_valid_bit.at(f);
            valid_bits.insert(pov_bit);
        }

        return to_vector(valid_bits);
    }

    ordered_set<const IR::MAU::Action*>
    get_all_actions(const ordered_set<const PHV::Field*>& group) {
        ordered_set<const IR::MAU::Action*> all_actions;

        for (auto f : group) {
            if (weak_fields.read_only_weak_fields.count(f))
                continue;

            for (auto assign : weak_fields.field_to_weak_assigns.at(f)) {
                auto action = weak_fields.get_action(assign);
                all_actions.insert(action);
            }
        }

        LOG2("all actions for group:");
        for (auto a : all_actions)
            LOG2("    " << a->name);

        return all_actions;
    }

    std::vector<const IR::TempVar*>
    create_action_ctl_bits(const ordered_set<const IR::MAU::Action*>& actions) {
        std::vector<const IR::TempVar*> rv;

        for (auto action : actions) {
            if (!action_to_ctl_bit.count(action))
                action_to_ctl_bit[action] = create_bit(action->name + ".$ctl");

            rv.insert(rv.begin(), action_to_ctl_bit.at(action));  // order is important
        }

        return rv;
    }

    struct InstructionMap {
        ordered_map<const PHV::Field*,
                 ordered_map<Value, const IR::MAU::Instruction*>> value_to_instr;

        ordered_map<const PHV::Field*, const IR::MAU::Instruction*> default_instr;
    };

    InstructionMap
    create_instr_map(const ordered_set<const PHV::Field*>& group) {
        InstructionMap instr_map;

        for (auto f : group) {
            if (weak_fields.read_only_weak_fields.count(f))
                continue;

            unsigned id = 1;

            for (auto& kv : values_at_deparser.values_at_deparser.at(f)) {
                auto& value = kv.first;

                std::string pov_bit_name = f->name + "_v" + std::to_string(id++) + ".$valid";

                auto pov_bit = create_bit(pov_bit_name.c_str(), true);

                BUG_CHECK(!value_to_pov_bit[f].count(value), "value valid bit already exists?");

                value_to_pov_bit[f][value] = pov_bit;

                instr_map.value_to_instr[f][value] = create_set_bit_instr(pov_bit);
            }

            // TODO(zma) de-duplicate equivalent bits

            std::string dflt_pov_bit_name = f->name + "_v0" + ".$valid";

            auto dflt_pov_bit = create_bit(dflt_pov_bit_name.c_str(), true);

            BUG_CHECK(!default_pov_bit.count(f), "default valid bit already exists?");

            default_pov_bit[f] = dflt_pov_bit;

            instr_map.default_instr[f] = create_set_bit_instr(dflt_pov_bit);
        }

        return instr_map;
    }

    template <typename T>
    static std::vector<T> to_vector(const ordered_set<T>& data) {
        std::vector<T> vec;

        for (auto d : data)
            vec.push_back(d);

        return vec;
    }

    unsigned
    encode_valid_bit(const PHV::Field* f,
                     const std::vector<const IR::Expression*>& valid_bits) {
        auto valid_bit = pov_bits.field_to_valid_bit.at(f);

        auto it = std::find(valid_bits.begin(), valid_bits.end(), valid_bit);

        BUG_CHECK(it != valid_bits.end(), "valid bit not found?");

        unsigned valid_bit_offset = it - valid_bits.begin();
        return 1 << valid_bit_offset;
    }

    unsigned
    encode_assign_chain(const AssignChain& chain,
                        const ordered_set<const IR::MAU::Action*>& all_actions) {
        auto all_actions_vec = to_vector(all_actions);

        unsigned encoded = 0;

        for (auto assign : chain) {
            auto action = weak_fields.get_action(assign);

            auto it = std::find(all_actions_vec.begin(), all_actions_vec.end(), action);

            BUG_CHECK(it != all_actions_vec.end(), "action not found?");

            unsigned bit_offset = it - all_actions_vec.begin();

            encoded |= 1 << bit_offset;
        }

        return encoded;
    }

    static const IR::Entry*
    create_static_entry(unsigned key_size, unsigned key, const IR::MAU::Action* action) {
        IR::Vector<IR::Expression> components;

        for (unsigned i = 0; i < key_size; i++) {
            auto bit_i = (key >> i) & 1;
            components.insert(components.begin(), new IR::Constant(bit_i));
        }

        auto keys = new IR::ListExpression(new IR::Type_Tuple, components);

        auto method = new IR::PathExpression(new IR::Path(action->name));

        auto type_action = new IR::Type_Action(new IR::TypeParameters, new IR::ParameterList);

        auto call = new IR::MethodCallExpression(type_action, method);

        auto entry = new IR::Entry(keys, call);

        // XXX why are these still in frontend types? shouldn't these have been converted to
        // IR::MAU::Action already?
        return entry;
    }

    struct MatchAction {
        MatchAction(std::vector<const IR::Expression*> k,
                    ordered_map<unsigned, const IR::MAU::Action*> e) :
            keys(k), entries(e) { }

        std::vector<const IR::Expression*> keys;
        ordered_map<unsigned, const IR::MAU::Action*> entries;
    };

    MatchAction
    create_match_action(const ordered_set<const PHV::Field*>& group) {
        LOG1("create match action for group");

        if (LOGGING(2))
            print_fields(group);

        auto all_actions = get_all_actions(group);

        auto vld_bits = get_valid_bits(group);

        auto ctl_bits = create_action_ctl_bits(all_actions);

        auto instr_map = create_instr_map(group);

        if (vld_bits.size() + ctl_bits.size() > 32)
            P4C_UNIMPLEMENTED(
                  "decaf pov encoder can only accommodate match up to 32-bit currently");

        // TODO(zma) for match wider than 32-bit, we need a type wider than "unsigned"

        ordered_map<unsigned, ordered_set<const IR::MAU::Instruction*>> match_to_instrs;

        std::map<unsigned, std::set<const PHV::Field*>> on_set;

        for (auto f : group) {
            if (weak_fields.read_only_weak_fields.count(f))
                continue;

            unsigned vld = encode_valid_bit(f, vld_bits);

            auto& value_map_for_f = values_at_deparser.values_at_deparser.at(f);

            for (auto& kv : value_map_for_f) {
                auto& value = kv.first;

                for (auto& chain : kv.second) {
                    unsigned key = encode_assign_chain(chain, all_actions);

                    key |= vld << ctl_bits.size();

                    auto instr = instr_map.value_to_instr.at(f).at(value);
                    match_to_instrs[key].insert(instr);

                    on_set[key].insert(f);
                }
            }

            // miss action, default for all fields
            auto instr = instr_map.default_instr.at(f);
            match_to_instrs[vld << ctl_bits.size()].insert(instr);
        }

        for (auto& kv : on_set) {
            auto key = kv.first;
            auto& on_set_for_key = kv.second;

            for (auto f : group) {
                if (weak_fields.read_only_weak_fields.count(f))
                    continue;

                // field is default if not on
                if (!on_set_for_key.count(f)) {
                    auto instr = instr_map.default_instr.at(f);
                    match_to_instrs[key].insert(instr);
                }
            }
        }

        std::vector<const IR::Expression*> keys;

        keys.insert(keys.begin(), vld_bits.begin(), vld_bits.end());
        keys.insert(keys.end(), ctl_bits.begin(), ctl_bits.end());

        ordered_map<unsigned, const IR::MAU::Action*> match_to_action;

        int eid = 0;
        for (auto& ent : match_to_instrs) {
            std::string action_name = "__act_" + std::to_string(eid++);
            auto action = new IR::MAU::Action(action_name.c_str());

            for (auto instr : ent.second)
                action->action.push_back(instr);

            match_to_action[ent.first] = action;
        }

        return MatchAction(keys, match_to_action);
    }

    IR::MAU::Table*
    create_pov_encoder(gress_t gress, const MatchAction& match_action) {
        LOG1("create pov encoder for group");

        static int id = 0;
        std::string table_name = gress + "_decaf_pov_encoder_" + std::to_string(id++);

        auto encoder = new IR::MAU::Table(table_name.c_str(), gress);

        auto p4_name = table_name + "_" + cstring::to_cstring(gress);
        encoder->match_table = new IR::P4Table(p4_name.c_str(), new IR::TableProperties());

        int i = 0;
        for (auto in : match_action.keys) {
            auto ixbar_read = new IR::MAU::InputXBarRead(in, IR::ID("exact"));
            ixbar_read->p4_param_order = i++;
            encoder->match_key.push_back(ixbar_read);
        }

        unsigned key_size = match_action.keys.size();

        IR::Vector<IR::Entry> static_entries;

        for (auto& ent : match_action.entries) {
            auto action = ent.second;
            encoder->actions[action->name] = action;

            auto static_entry = create_static_entry(key_size, ent.first, action);
            static_entries.push_back(static_entry);
        }

        auto nop = new IR::MAU::Action("__nop_");
        nop->default_allowed = nop->init_default = true;

        encoder->actions[nop->name] = nop;

        encoder->entries_list = new IR::EntriesList(static_entries);

        LOG3("add decaf pov encoder:");
        LOG3(encoder);

        // XXX(zma) depending how well this works, we might consider baking
        // this encoder (or multiple instances) into the silicon. Using SRAM/TCAM
        // seems under-utilizing the memory since most of these encoders only
        // have small number of entries.

        return encoder;
    }

    IR::MAU::Table*
    synthesize_pov_encoder(const ordered_set<const PHV::Field*>& group) {
        LOG1("\nsynthesize pov bits for group:");

        auto gress = get_gress(group);

        auto match_action = create_match_action(group);

        auto encoder = create_pov_encoder(gress, match_action);

        return encoder;
    }

    IR::MAU::TableSeq*
    preorder(IR::MAU::TableSeq* seq) override {
        prune();

        gress_t gress = VisitingThread(this);

        if (tables_to_insert.count(gress)) {
            for (auto t : tables_to_insert.at(gress))
                seq->tables.push_back(t);
        }

        return seq;
    }
};

class InsertParserConstExtracts : public ParserTransform {
    const ComputeValuesAtDeparser& values_at_deparser;
    unsigned cid = 0;

 public:
    std::map<gress_t,
             ordered_map<const IR::Constant*, std::vector<uint8_t>>> const_to_bytes;

    std::map<gress_t,
             ordered_map<uint8_t, const IR::TempVar*>> byte_to_temp_var;

    explicit InsertParserConstExtracts(const ComputeValuesAtDeparser& values_at_deparser)
        : values_at_deparser(values_at_deparser) { }

 private:
    void create_temp_var_for_constant_bytes(gress_t gress,
                              const ordered_set<const IR::Constant*>& constants) {
        for (auto c : constants) {
            // TODO support any large const_as_uint64
            uint64_t const_as_uint64 = c->asUint64();

            do {
                uint8_t l_s_byte = const_as_uint64 & 0xffU;
                const_to_bytes[gress][c].insert(
                    const_to_bytes[gress][c].begin(), l_s_byte);  // order is important

                if (!byte_to_temp_var[gress].count(l_s_byte)) {
                    std::string name = "$constant_" + std::to_string(cid++);

                    auto temp_var = create_temp_var(name.c_str(), 8);
                    byte_to_temp_var[gress][l_s_byte] = temp_var;

                    LOG3("created temp var for const " << (unsigned)l_s_byte);
                }

                const_as_uint64 >>= 8;
            } while (const_as_uint64 != 0);
        }

        LOG2("\ntotal constant bytes: " << byte_to_temp_var[gress].size() << " at " << gress);

        for (auto& kv : byte_to_temp_var[gress])
            LOG2("    0x" << std::hex << (unsigned)kv.first << std::dec);
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = ParserTransform::init_apply(root);

        cid = 0;
        const_to_bytes.clear();
        byte_to_temp_var.clear();

        for (auto& kv : values_at_deparser.weak_fields.all_constants)
            create_temp_var_for_constant_bytes(kv.first, kv.second);

        return rv;
    }

    void end_apply() override {
        LOG1("done insert parser constants");
    }

    void insert_init_consts_state(IR::BFN::Parser* parser) {
        auto transition = new IR::BFN::Transition(match_t(), 0, parser->start);

        auto init_consts = new IR::BFN::ParserState(
                                 createThreadName(parser->gress, "$_init_consts"),
                                 parser->gress, { }, { }, { transition });

        for (auto& kv : const_to_bytes[parser->gress]) {
            for (auto byte : kv.second) {
                auto temp_var = byte_to_temp_var.at(parser->gress).at(byte);

                auto rval = new IR::BFN::ConstantRVal(IR::Type::Bits::get(8), byte);
                auto extract = new IR::BFN::Extract(temp_var, rval);

                init_consts->statements.push_back(extract);
                LOG3("add " << extract << " to " << init_consts->name);
            }
        }

        parser->start = init_consts;
    }

    IR::BFN::Parser* preorder(IR::BFN::Parser* parser) override {
        /*
          We choose to insert the constants at the beginning of the parser,
          but it doesn't have to be the case -- there are states throughout the
          parse graph with unused extractors where we can stash these constants
          thus potentially saving some parse bandwidth on the critical path.
          The problem is that all parse paths should parse the same set of constants
          while minimizing the states on the critical path. This is a global
          instruction scheduling program in the parser -- can be solved as a general
          parser optimizaiton pass (TODO).
        */

        if (const_to_bytes.count(parser->gress))
            insert_init_consts_state(parser);

        return parser;
    }
};

class RewriteWeakFieldWrites : public MauTransform {
    const SynthesizePovEncoder& synth_pov_encoder;

    std::map<const IR::MAU::Action*, const IR::MAU::Action*> curr_to_orig;

    std::map<const IR::MAU::Action*, const IR::MAU::Instruction*> orig_action_to_new_instr;

 public:
    explicit RewriteWeakFieldWrites(const SynthesizePovEncoder& synth_pov_encoder)
        : synth_pov_encoder(synth_pov_encoder) { }

 private:
    void end_apply() override {
        LOG1("done rewrite weak fields");
    }

    const IR::Node* preorder(IR::MAU::Action* action) override {
        auto orig = getOriginal<IR::MAU::Action>();

        curr_to_orig[action] = orig;

        return action;
    }

    bool cache_instr(const IR::MAU::Action* orig_action,
                     const IR::MAU::Instruction* new_instr) {
        if (orig_action_to_new_instr.count(orig_action)) {
            auto cached_instr = orig_action_to_new_instr.at(orig_action);

            BUG_CHECK(cached_instr->equiv(*new_instr),
                      "set instr unequivalent to cached instr!");

            return false;
        }

        orig_action_to_new_instr[orig_action] = new_instr;

        return true;
    }

    const IR::Node* postorder(IR::MAU::Instruction* instr) override {
        auto action = findContext<IR::MAU::Action>();

        auto orig_action = curr_to_orig.at(action);

        if (synth_pov_encoder.action_to_ctl_bit.count(orig_action)) {
            auto ctl_bit = synth_pov_encoder.action_to_ctl_bit.at(orig_action);

            auto set_ctl_bit = create_set_bit_instr(ctl_bit);

            LOG3("rewrite " << instr << " as " << set_ctl_bit);

            bool cached = cache_instr(orig_action, set_ctl_bit);

            return cached ? set_ctl_bit : nullptr;
        }

        return instr;
    }
};

class RewriteDeparser : public DeparserModifier {
    const PhvInfo& phv;
    const SynthesizePovEncoder& synth_pov_encoder;
    const InsertParserConstExtracts& insert_parser_consts;

 public:
    RewriteDeparser(const PhvInfo& phv,
                    const SynthesizePovEncoder& synth_pov_encoder,
                    const InsertParserConstExtracts& insert_parser_consts)
        : phv(phv),
          synth_pov_encoder(synth_pov_encoder),
          insert_parser_consts(insert_parser_consts)  { }

 private:
    void end_apply() override {
        LOG1("done rewrite deparser");
    }

    void add_emit(IR::Vector<IR::BFN::Emit>& emits,
                  const IR::Expression* source, const IR::TempVar* pov_bit) {
        auto emit_value = new IR::BFN::EmitField(source, pov_bit);
        emits.push_back(emit_value);

        LOG3(emit_value);
    }

    const IR::Expression* find_emit_source(const PHV::Field* field,
                                           const IR::Vector<IR::BFN::Emit>& emits) {
        for (auto prim : emits) {
            if (auto emit = prim->to<IR::BFN::EmitField>()) {
                auto f = phv.field(emit->source->field);
                if (f == field)
                    return emit->source->field;
            }
        }

        return nullptr;
    }

    bool preorder(IR::BFN::Deparser* deparser) override {
        IR::Vector<IR::BFN::Emit> new_emits;

        auto& value_to_pov_bit = synth_pov_encoder.value_to_pov_bit;
        auto& default_pov_bit = synth_pov_encoder.default_pov_bit;

        ordered_map<const IR::Constant*, std::vector<uint8_t>> const_to_bytes;
        ordered_map<uint8_t, const IR::TempVar*> byte_to_temp_var;

        auto& c2b = insert_parser_consts.const_to_bytes;
        auto& b2t = insert_parser_consts.byte_to_temp_var;

        if (c2b.count(deparser->gress)) {
            const_to_bytes = c2b.at(deparser->gress);
            byte_to_temp_var = b2t.at(deparser->gress);
        }

        for (auto prim : deparser->emits) {
            if (auto emit = prim->to<IR::BFN::EmitField>()) {
                auto f = phv.field(emit->source->field);

                if (value_to_pov_bit.count(f)) {
                    LOG3("rewrite " << emit << " as:");

                    for (auto& kv : value_to_pov_bit.at(f)) {
                        auto& value = kv.first;
                        auto pov_bit = kv.second;

                        if (value.field) {
                            auto emit_source = find_emit_source(value.field, deparser->emits);

                            BUG_CHECK(emit_source, "emit source not found?");

                            add_emit(new_emits, emit_source, pov_bit);
                        } else {  // constant
                            for (auto byte : const_to_bytes.at(value.constant)) {
                                const IR::Expression* emit_source = byte_to_temp_var.at(byte);
                                add_emit(new_emits, emit_source, pov_bit);
                            }
                        }
                    }

                    auto dflt_pov_bit = default_pov_bit.at(f);
                    add_emit(new_emits, emit->source->field, dflt_pov_bit);

                    continue;
                }
            }

            new_emits.push_back(prim);
        }

        deparser->emits = new_emits;

        return false;
    }
};

}  // anonymous namespace

DeparserCopyOpt::DeparserCopyOpt(const PhvInfo &phv, PhvUse &uses, const DependencyGraph& dg)
    : phv(phv), uses(uses), dg(dg) {

    auto collect_hdr_valid_bits = new CollectHeaderValidBits(phv);

    auto collect_weak_fields = new CollectWeakFields(phv, uses);

    auto values_at_deparser = new ComputeValuesAtDeparser(*collect_weak_fields);

    auto synth_pov_encoder = new SynthesizePovEncoder(*collect_hdr_valid_bits, *values_at_deparser);

    auto insert_parser_consts = new InsertParserConstExtracts(*values_at_deparser);

    auto rewrite_weak_fields = new RewriteWeakFieldWrites(*synth_pov_encoder);

    auto rewrite_deparser = new RewriteDeparser(phv, *synth_pov_encoder, *insert_parser_consts);

    /* 
        TODO

        Tagalong containers, though abundant, are not unlimited. In addition, other resources also
        need to be managed. The list below is all resources need to be managed in the order of
        scarcity (most scarce to least). We need to make sure we don't over-fit any of these.
        Given a list of fields that can be decaf'd, we need to establish a partial order between
        any two fields such that one requires less resource than the other.
  
          1. tagalong PHV space (2k bits, half of normal PHV)
          2. POV bits (128 bits per gress)
          3. Parser constant extract (each state has 4xB, 2xH, 2xW constant extract bandwidth)
          4. Table resources (logical ID, memory)
          5. FD entries (abundant)
    */

    addPasses({
        &uses,
        collect_hdr_valid_bits,
        collect_weak_fields,
        values_at_deparser,
        synth_pov_encoder,     // mt
        insert_parser_consts,  // pt
        rewrite_weak_fields,   // mt
        rewrite_deparser       // dm
    });
}
