#include "bf-p4c/parde/decaf.h"

template <typename T>
static std::vector<T> to_vector(const ordered_set<T>& data) {
    std::vector<T> vec;

    for (auto d : data)
        vec.push_back(d);

    return vec;
}

template <typename T>
static std::vector<std::vector<T>> enumerate_all_subsets(const std::vector<T>& inputs) {
    std::vector<std::vector<T>> rv = {{}};

    for (auto &n : inputs) {
        std::vector<std::vector<T>> temp = rv;

        for (auto &t : temp) {
            t.push_back(n);
            rv.push_back(t);
        }
    }

    return rv;
}

void CollectWeakFields::add_weak_assign(const PHV::Field* dst,
                                        const PHV::Field* field_src,
                                        const IR::Constant* const_src,
                                        const IR::MAU::Instruction* instr) {
    BUG_CHECK(((field_src && !const_src) || (!field_src && const_src)),
              "Expect source to be either a PHV field or constant");

    if (field_src && field_src == dst) {
        LOG4("src is dst");
        return;
    }

    auto assign = const_src ? new Assign(instr, dst, const_src)
                            : new Assign(instr, dst, field_src);

    field_to_weak_assigns[dst].insert(assign);
}

void CollectWeakFields::elim_strong_field(const PHV::Field* f) {
    strong_fields.insert(f);

    field_to_weak_assigns.erase(f);
}

bool CollectWeakFields::preorder(const IR::MAU::InputXBarRead* ixbar) {
    auto f = phv.field(ixbar->expr);
    elim_strong_field(f);

    LOG2(f->name << " is not a candidate (match)");

    return false;
}

bool CollectWeakFields::preorder(const IR::MAU::Instruction* instr) {
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

bool CollectWeakFields::is_strong_by_transitivity(const PHV::Field* f,
        std::set<const PHV::Field*>& visited) {
    if (visited.count(f))
        return false;

    visited.insert(f);

    if (read_only_weak_fields.count(f))
        return false;

    if (strong_fields.count(f))
        return true;

    if (!field_to_weak_assigns.count(f))
        return true;

    for (auto assign : field_to_weak_assigns.at(f)) {
        if (assign->src->field) {
            if (is_strong_by_transitivity(assign->src->field, visited))
                return true;
        }
    }

    return false;
}

bool CollectWeakFields::is_strong_by_transitivity(const PHV::Field* f) {
    std::set<const PHV::Field*> visited;
    return is_strong_by_transitivity(f, visited);
}

void CollectWeakFields::add_read_only_weak_fields() {
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

void CollectWeakFields::get_all_constants() {
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

void CollectWeakFields::elim_by_strong_transitivity() {
    // elim all fields that have a strong source (directly or transitively)

    std::set<const PHV::Field*> to_delete;

    for (auto& kv : field_to_weak_assigns) {
        auto f = kv.first;
        if (is_strong_by_transitivity(f))
            to_delete.insert(f);
    }

    for (auto f : to_delete) {
        LOG2(f->name << " is not a candidate (has strong src)");
        elim_strong_field(f);
    }
}

void CollectWeakFields::elim_non_byte_aligned_fields() {
    // For non byte-aligned fields, we need to check all fields in a byte
    // share same decaf pov bit in order to pack them (TODO). Elim these
    // for now.

    std::set<const PHV::Field*> to_delete;

    for (auto f : read_only_weak_fields) {
        if (f->size % 8 != 0 ||
            (f->alignment && !((*(f->alignment)).isByteAligned())))
            to_delete.insert(f);
    }

    for (auto f : to_delete) {
        LOG2(f->name << " is not a candidate (non byte-aligned)");
        read_only_weak_fields.erase(f);
    }

    to_delete.clear();

    for (auto& kv : field_to_weak_assigns) {
        auto f = kv.first;
        if (f->size % 8 != 0 ||
            (f->alignment && !((*(f->alignment)).isByteAligned())))
            to_delete.insert(f);
    }

    for (auto f : to_delete) {
        LOG2(f->name << " is not a candidate (non byte-aligned)");
        field_to_weak_assigns.erase(f);
    }
}

void CollectWeakFields::dbprint(std::ostream& out) const {
    unsigned total_field_bits = 0;

    for (auto f : read_only_weak_fields) {
        total_field_bits += f->size;

        out << "\nfield: " << f->name << " : "
                  << f->size << " (read-only)" << std::endl;
    }

    for (auto& kv : field_to_weak_assigns) {
        auto dst = kv.first;

        total_field_bits += dst->size;

        out << "\nfield: " << dst->name << " : " << dst->size << std::endl;

        int id = 0;
        for (auto& assign : kv.second) {
            out << "     " << id++ << ": ";
            print_assign(assign);
        }
    }

    out << "\ntotal weak field bits: " << total_field_bits << std::endl;

    out << "\nall unique constants:" << std::endl;

    for (auto& kv : all_constants) {
        out << kv.first << ":" << std::endl;

        for (auto c : kv.second)
            out << "    0x" << std::hex << c << std::dec << std::endl;
    }
}

bool ComputeValuesAtDeparser::is_weak_assign(const IR::MAU::Instruction* instr) const {
    for (auto& fv : value_to_chains) {
        for (auto& vc : fv.second) {
            for (auto& chain : vc.second) {
                if (chain.contains(instr))
                    return true;
            }
        }
    }

    return false;
}

Visitor::profile_t
ComputeValuesAtDeparser::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);

    weak_field_groups.clear();
    value_to_chains.clear();

    group_weak_fields();

    std::vector<FieldGroup> groups_to_remove;

    for (auto& group : weak_field_groups) {
        bool ok = compute_all_reachable_values_at_deparser(group);

        if (!ok)
            groups_to_remove.push_back(group);
    }

    // erase groups we can't handle for now
    for (auto& group : groups_to_remove) {
        for (auto f : group)
            weak_fields.remove_weak_field(f);

        weak_field_groups.erase(std::remove(weak_field_groups.begin(),
                                            weak_field_groups.end(),
                                            group),
                                weak_field_groups.end());
    }

    return rv;
}

void ComputeValuesAtDeparser::group_weak_fields() {
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
            FieldGroup new_set;

            new_set.insert(f);

            for (auto assign : kv.second)
                if (assign->src->field)
                    new_set.insert(assign->src->field);

            weak_field_groups.push_back(new_set);
        }
    }

    std::stable_sort(weak_field_groups.begin(), weak_field_groups.end(),
                     [=](const FieldGroup& a,
                         const FieldGroup& b) {
        return a.size() < b.size();
    });

    LOG1("\ntotal weak field groups: " << weak_field_groups.size());
    LOG1(print(weak_field_groups));
}

std::vector<const IR::MAU::Table*>
ComputeValuesAtDeparser::get_next_tables(const IR::MAU::Table* curr_table,
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
ComputeValuesAtDeparser::enumerate_all_assign_chains(const IR::MAU::Table* curr_table,
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
ComputeValuesAtDeparser::propagate_value_on_assign_chain(const AssignChain& chain) {
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

// Perform copy/constant propagation for the group based on table dependency.
// For each field, what are the all possible values that are reachable at the
// deparser?
bool ComputeValuesAtDeparser::compute_all_reachable_values_at_deparser(
        const FieldGroup& weak_field_group) {
    LOG1("\ncompute all values for group:");
    LOG1(print(weak_field_group));

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
        LOG2("\nmore than 2 tables involved for group, skip");
        return false;
    }

    auto first_table = (table_to_assigns.begin())->first;
    auto all_chains = enumerate_all_assign_chains(first_table, table_to_assigns);

    LOG2("\ntotal assign chains: " << all_chains.size());
    LOG2(print_assign_chains(all_chains));

    for (auto& chain : all_chains) {
        auto value_map_for_chain = propagate_value_on_assign_chain(chain);

        for (auto& kv : value_map_for_chain) {
            auto field = kv.first;
            auto& value = kv.second;

            auto& value_map_for_field = value_to_chains[field];
            value_map_for_field[value].insert(chain);
        }
    }

    LOG2("\ndeparser value map for group:");
    LOG2(print_value_map(weak_field_group));

    return true;
}

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

void SynthesizePovEncoder::dbprint(std::ostream& out) const {
    out << "action_to_ctl_bit: " << action_to_ctl_bit.size() << std::endl;
    for (auto& kv : action_to_ctl_bit)
        out << kv.first->name << " : " << kv.second << std::endl;

    ordered_set<const IR::TempVar*> unique_value_pov_bits;
    for (auto& kv : value_to_pov_bit) {
        for (auto vb : kv.second)
            unique_value_pov_bits.insert(vb.second);
    }

    out << "unique value pov bits: " << unique_value_pov_bits.size() << std::endl;
    for (auto& kv : value_to_pov_bit) {
        for (auto& vp : kv.second) {
            out << kv.first->name << " : ";
            vp.first.print();
            out << " : " << vp.second << std::endl;
        }
    }

    ordered_set<const IR::TempVar*> unique_default_pov_bits;
    for (auto vb : default_pov_bit)
        unique_default_pov_bits.insert(vb.second);

    out << "unique default pov bits: " << unique_default_pov_bits.size() << std::endl;
    for (auto& kv : default_pov_bit)
        out << kv.first->name << " : " << kv.second << std::endl;
}

std::vector<const IR::Expression*>
SynthesizePovEncoder::get_valid_bits(const FieldGroup& group) {
    ordered_set<const IR::Expression*> valid_bits;

    for (auto f : group) {
        auto pov_bit = pov_bits.field_to_valid_bit.at(f);
        valid_bits.insert(pov_bit);
    }

    return to_vector(valid_bits);
}

ordered_set<const IR::MAU::Action*>
SynthesizePovEncoder::get_all_actions(const FieldGroup& group) {
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
SynthesizePovEncoder::create_action_ctl_bits(const ordered_set<const IR::MAU::Action*>& actions) {
    std::vector<const IR::TempVar*> rv;

    for (auto action : actions) {
        if (!action_to_ctl_bit.count(action))
            action_to_ctl_bit[action] = create_bit(action->name + ".$ctl");

        rv.insert(rv.begin(), action_to_ctl_bit.at(action));  // order is important
    }

    return rv;
}

bool SynthesizePovEncoder::have_same_vld_ctl_bits(const FieldGroup* a, const FieldGroup* b) {
    auto& a_ctl_bits = group_to_ctl_bits.at(a);
    auto& a_vld_bits = group_to_vld_bits.at(a);

    auto& b_ctl_bits = group_to_ctl_bits.at(b);
    auto& b_vld_bits = group_to_vld_bits.at(b);

    return a_ctl_bits == b_ctl_bits && a_vld_bits == b_vld_bits;
}

bool SynthesizePovEncoder::have_same_action_chain(const AssignChain& a, const AssignChain& b) {
    if (a.size() != b.size())
        return false;

    for (unsigned i = 0; i < a.size(); i++) {
        auto p = a.at(i);
        auto q = b.at(i);

        auto pa = values_at_deparser.weak_fields.get_action(p);
        auto qa = values_at_deparser.weak_fields.get_action(q);

        if (pa != qa)  // shallow compare enough?
            return false;
    }

    return true;
}

bool SynthesizePovEncoder::have_same_assign_chains(const PHV::Field* p, const Value& pv,
                             const PHV::Field* q, const Value& qv) {
    auto& pc = values_at_deparser.value_to_chains.at(p).at(pv);
    auto& qc = values_at_deparser.value_to_chains.at(q).at(qv);

    LOG4("p chains\n" << values_at_deparser.print_assign_chains(pc));
    LOG4("q chains\n" << values_at_deparser.print_assign_chains(qc));

    if (pc.size() != qc.size())
        return false;

    auto it1 = pc.begin();
    auto it2 = qc.begin();

    for (; it1 != pc.end() && it2 != qc.end(); ++it1, ++it2) {
        if (!have_same_action_chain(*it1, *it2)) {
            LOG3("two chain sets are not equivalent");
            return false;
        }
    }

    LOG3("two chain sets are equivalent");
    return true;
}

bool SynthesizePovEncoder::have_same_hdr_vld_bit(const PHV::Field* p, const PHV::Field* q) {
    auto pb = pov_bits.field_to_valid_bit.at(p);
    auto qb = pov_bits.field_to_valid_bit.at(q);

    return pb->equiv(*qb);
}

const IR::MAU::Instruction*
SynthesizePovEncoder::find_equiv_valid_bit_instr_for_value(const PHV::Field* f,
                                     unsigned version, const Value& value,
                                     const InstructionMap& instr_map) {
    if (version == 0) {  // 0 for default
       for (auto& fi : instr_map.default_instr) {
           if (have_same_hdr_vld_bit(f, fi.first))  // quantifier
               return fi.second;
       }
    } else {
        for (auto& fv : instr_map.value_to_instr) {
            for (auto& vi : fv.second) {
                if (have_same_hdr_vld_bit(f, fv.first)) {  // quantifier
                    if (have_same_assign_chains(f, value, fv.first, vi.first))
                        return vi.second;
                }
            }
        }
    }

    return nullptr;
}

const IR::MAU::Instruction*
SynthesizePovEncoder::find_equiv_valid_bit_instr_for_value(const PHV::Field* f,
                                     const FieldGroup& group,
                                     unsigned version, const Value& value) {
    for (auto& gi : group_to_instr_map) {
        if (have_same_vld_ctl_bits(&group, gi.first)) {   // quantifier
            if (auto equiv_instr =
                find_equiv_valid_bit_instr_for_value(f, version, value, gi.second))
                return equiv_instr;
        }
    }

    return nullptr;
}

const IR::MAU::Instruction*
SynthesizePovEncoder::create_valid_bit_instr_for_value(const PHV::Field* f,
                                 const FieldGroup& group,
                                 unsigned version, const Value& value) {
    auto equiv_instr = find_equiv_valid_bit_instr_for_value(f, group, version, value);

    if (equiv_instr) {
        LOG3(f->name << " v" << version << " has equivalent version bit with " << equiv_instr);

        if (version == 0)  // 0 for default
            default_pov_bit[f] = equiv_instr->operands[0]->to<IR::TempVar>();
        else
            value_to_pov_bit[f][value] = equiv_instr->operands[0]->to<IR::TempVar>();

        return equiv_instr;
    }

    std::string pov_bit_name = f->name + "_v" + std::to_string(version) + ".$valid";

    auto pov_bit = create_bit(pov_bit_name.c_str(), true);

    BUG_CHECK(!value_to_pov_bit[f].count(value), "value valid bit already exists?");

    if (version == 0)  // 0 for default
        default_pov_bit[f] = pov_bit;
    else
        value_to_pov_bit[f][value] = pov_bit;

    auto instr = create_set_bit_instr(pov_bit);
    return instr;
}

InstructionMap
SynthesizePovEncoder::create_instr_map(const FieldGroup& group) {
    InstructionMap instr_map;

    for (auto f : group) {
        if (weak_fields.read_only_weak_fields.count(f))
            continue;

        unsigned id = 0;

        auto dflt_instr = create_valid_bit_instr_for_value(f, group, id++, Value());
        instr_map.default_instr[f] = dflt_instr;

        for (auto& kv : values_at_deparser.value_to_chains.at(f)) {
            auto instr = create_valid_bit_instr_for_value(f, group, id++, kv.first);
            instr_map.value_to_instr[f][kv.first] = instr;
        }
    }

    return instr_map;
}

unsigned
SynthesizePovEncoder::encode_valid_bits(const std::vector<const IR::Expression*>& subset,
                  const std::vector<const IR::Expression*>& allset) {
    unsigned rv = 0;

    for (auto obj : subset) {
        auto it = std::find(allset.begin(), allset.end(), obj);

        BUG_CHECK(it != allset.end(), "valid bit not found in set?");

        unsigned offset = it - allset.begin();
        rv |= 1 << offset;
    }

    return rv;
}

unsigned
SynthesizePovEncoder::encode_assign_chain(const AssignChain& chain,
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

/* static */ const IR::Entry*
SynthesizePovEncoder::create_static_entry(unsigned key_size, unsigned key,
                                          const IR::MAU::Action* action) {
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

MatchAction*
SynthesizePovEncoder::create_match_action(const FieldGroup& group) {
    LOG1("create match action for group");
    LOG2(print(group));

    auto all_actions = get_all_actions(group);

    auto& vld_bits = group_to_vld_bits[&group] = get_valid_bits(group);

    auto& ctl_bits = group_to_ctl_bits[&group] = create_action_ctl_bits(all_actions);

    auto& instr_map = group_to_instr_map[&group] = create_instr_map(group);

    if (vld_bits.size() + ctl_bits.size() > 32) {
        P4C_UNIMPLEMENTED(
              "decaf pov encoder can only accommodate match up to 32-bit currently");
    }

    // TODO(zma) for match wider than 32-bit, we need a type wider than "unsigned"

    ordered_map<unsigned, ordered_set<const IR::MAU::Instruction*>> match_to_instrs;

    // TODO(zma) some of the headers cannot be live at the same time, need to prune
    // the vld bit onsets
    auto vld_bits_all_onsets = enumerate_all_subsets(vld_bits);

    for (auto& vld_bits_onset : vld_bits_all_onsets) {
        if (vld_bits_all_onsets.empty())
            continue;

        unsigned vld = encode_valid_bits(vld_bits_onset, vld_bits);

        std::map<unsigned, std::set<const PHV::Field*>> on_set;

        for (auto f : group) {
            if (weak_fields.read_only_weak_fields.count(f))
                continue;

            auto vld_bit_f = pov_bits.field_to_valid_bit.at(f);
            auto it = std::find(vld_bits_onset.begin(), vld_bits_onset.end(), vld_bit_f);

            if (it == vld_bits_onset.end())
                continue;

            auto& value_map_for_f = values_at_deparser.value_to_chains.at(f);

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
    }

    std::vector<const IR::Expression*> keys;

    keys.insert(keys.begin(), vld_bits.begin(), vld_bits.end());
    keys.insert(keys.end(), ctl_bits.begin(), ctl_bits.end());

    ordered_map<unsigned, const IR::MAU::Action*> match_to_action;

    for (auto& ent : match_to_instrs) {
        std::string action_name = "__act_" + std::to_string(action_cnt++);
        auto action = new IR::MAU::Action(action_name.c_str());

        for (auto instr : ent.second)
            action->action.push_back(instr);

        const IR::MAU::Action* equiv_action = nullptr;

        for (auto& ma : match_to_action) {
            if (action->action.equiv(ma.second->action))
                equiv_action = ma.second;
        }

        if (equiv_action) {
            match_to_action[ent.first] = equiv_action;
            LOG3("action " << action->name << " is equivalent with " << equiv_action->name);
        } else {
            match_to_action[ent.first] = action;
        }
    }

    auto ma = new MatchAction(keys, match_to_action);
    return ma;
}

IR::MAU::Table*
SynthesizePovEncoder::create_pov_encoder(gress_t gress, const MatchAction& match_action) {
    LOG1("create decaf pov encoder for match action");
    LOG3(match_action.print());

    static int id = 0;
    std::string table_name = toString(gress) + "_decaf_pov_encoder_" + std::to_string(id++);

    auto encoder = new IR::MAU::Table(table_name.c_str(), gress);
    encoder->is_compiler_generated = true;

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

    LOG3(encoder);

    // XXX(zma) depending how well this works, we might consider baking
    // this encoder (or multiple instances) into the silicon. Using SRAM/TCAM
    // seems under-utilizing the memory since most of these encoders only
    // have small number of entries.

    return encoder;
}

bool SynthesizePovEncoder::can_join(const MatchAction* a, const MatchAction* b) {
    if (a->keys == b->keys)  // the trivial case, we can simply concat the actions of a and b
        return true;

    // If the key sets are different, we can still join two match actions, but at the cost
    // of multiplying the number of entries. e.g. If the key sets differ in one bit, we need
    // to replicate every match for the bit's on/off set, potentially doubling the number of
    // entries. (TODO)

    return false;
}

IR::MAU::Action*
SynthesizePovEncoder::join_actions(const IR::MAU::Action* a, const IR::MAU::Action* b) {
    ordered_set<const IR::Primitive*> all_instrs;

    for (auto instr : a->action)
        all_instrs.insert(instr);

    for (auto instr : b->action)
        all_instrs.insert(instr);

    std::string action_name = "__act_" + std::to_string(action_cnt++);
    auto joined = new IR::MAU::Action(action_name.c_str());

    for (auto instr : all_instrs)
        joined->action.push_back(instr);

    LOG4("joined action " << a->name << " and " << b->name << " as " << joined->name);

    return joined;
}

MatchAction*
SynthesizePovEncoder::join_match_actions(const MatchAction* a, const MatchAction* b) {
    ordered_map<unsigned, const IR::MAU::Action*> joined_actions;

    // a's unique entries
    for (auto kv : a->entries) {
        if (!b->entries.count(kv.first))
            joined_actions[kv.first] = kv.second;
    }

    // b's unique entries
    for (auto kv : b->entries) {
        if (!a->entries.count(kv.first))
            joined_actions[kv.first] = kv.second;
    }

    for (auto kv : a->entries) {
        if (b->entries.count(kv.first)) {
            auto joined_action = join_actions(kv.second, b->entries.at(kv.first));
            joined_actions[kv.first] = joined_action;
        }
    }

    LOG3("joined match actions");

    return new MatchAction(a->keys, joined_actions);
}

std::vector<const MatchAction*>
SynthesizePovEncoder::join_match_actions(const std::vector<const MatchAction*>& match_actions) {
    std::map<const MatchAction*, const MatchAction*> joined_match_actions;
    std::vector<const MatchAction*> temp;

    for (auto a : match_actions) {
        if (joined_match_actions.count(a)) continue;

        const MatchAction* joined = nullptr;

        for (auto b : match_actions) {
            if (a == b) continue;

            if (can_join(a, b)) {
                joined = join_match_actions(a, b);
                joined_match_actions[a] = joined_match_actions[b] = joined;
                break;
            }
        }

        temp.push_back(joined ? joined : a);
    }

    if (temp == match_actions)  // nothing else to join, reached fix-point
        return temp;

    return join_match_actions(temp);  // recurse and continue
}

IR::MAU::TableSeq*
SynthesizePovEncoder::preorder(IR::MAU::TableSeq* seq) {
    prune();

    gress_t gress = VisitingThread(this);

    if (tables_to_insert.count(gress)) {
        LOG2(tables_to_insert.at(gress).size() << " tables to insert on " << gress);

        for (auto t : tables_to_insert.at(gress))
            seq->tables.push_back(t);
    }

    return seq;
}

Visitor::profile_t SynthesizePovEncoder::init_apply(const IR::Node* root) {
    auto rv = MauTransform::init_apply(root);

    tables_to_insert.clear();
    value_to_pov_bit.clear();
    action_to_ctl_bit.clear();

    // Also, within each table, we can compress the number of match entries
    // using don't care's (and use TCAM to implement table) -- this is classical
    // boolean optimization (TODO).

    std::map<gress_t, std::vector<const MatchAction*>> match_actions;

    for (auto& group : values_at_deparser.weak_field_groups) {
        auto gress = get_gress(group);
        auto match_action = create_match_action(group);

        match_actions[gress].push_back(match_action);
    }

    for (auto& gm : match_actions)
        gm.second = join_match_actions(gm.second);

    for (auto& gm : match_actions) {
        for (auto& ma : gm.second) {
            auto table = create_pov_encoder(gm.first, *ma);

            tables_to_insert[table->gress].push_back(table);
        }
    }

    return rv;
}

void InsertParserConstExtracts::create_temp_var_for_constant_bytes(gress_t gress,
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

                LOG3("created temp var " << name << " " << (void*)c
                     << " 0x" << std::hex << (unsigned)l_s_byte << std::dec);
            }

            const_as_uint64 >>= 8;
        } while (const_as_uint64 != 0);
    }
}

void InsertParserConstExtracts::dbprint(std::ostream& out) const {
    for (auto& kv : byte_to_temp_var) {
        auto gress = kv.first;

        if (byte_to_temp_var.count(gress)) {
            out << "\ntotal constant bytes: " << byte_to_temp_var.at(gress).size()
                << " at " << gress << std::endl;

            for (auto& kv : byte_to_temp_var.at(gress)) {
                out << "    0x" << std::hex << (unsigned)kv.first
                    << std::dec << " (" << (unsigned)kv.first << ")" << std::endl;
            }
        }
    }
}

Visitor::profile_t InsertParserConstExtracts::init_apply(const IR::Node* root) {
    auto rv = ParserTransform::init_apply(root);

    cid = 0;
    const_to_bytes.clear();
    byte_to_temp_var.clear();

    for (auto& kv : values_at_deparser.weak_fields.all_constants)
        create_temp_var_for_constant_bytes(kv.first, kv.second);

    return rv;
}

void InsertParserConstExtracts::insert_init_consts_state(IR::BFN::Parser* parser) {
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

IR::BFN::Parser* InsertParserConstExtracts::preorder(IR::BFN::Parser* parser) {
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

const IR::Node* RewriteWeakFieldWrites::preorder(IR::MAU::Action* action) {
    auto orig = getOriginal<IR::MAU::Action>();

    curr_to_orig[action] = orig;

    return action;
}

bool RewriteWeakFieldWrites::cache_instr(const IR::MAU::Action* orig_action,
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

const IR::Node* RewriteWeakFieldWrites::postorder(IR::MAU::Instruction* instr) {
    auto orig_instr = getOriginal<IR::MAU::Instruction>();

    bool is_weak_assign = values_at_deparser.is_weak_assign(orig_instr);

    if (is_weak_assign) {
        auto action = findContext<IR::MAU::Action>();
        auto orig_action = curr_to_orig.at(action);

        auto ctl_bit = synth_pov_encoder.action_to_ctl_bit.at(orig_action);

        auto set_ctl_bit = create_set_bit_instr(ctl_bit);

        LOG3("rewrite " << instr << " as " << set_ctl_bit);

        bool cached = cache_instr(orig_action, set_ctl_bit);

        return cached ? set_ctl_bit : nullptr;
    }

    return instr;
}

void RewriteDeparser::add_emit(IR::Vector<IR::BFN::Emit>& emits,
              const IR::Expression* source, const IR::TempVar* pov_bit) {
    auto emit_value = new IR::BFN::EmitField(source, pov_bit);
    emits.push_back(emit_value);

    LOG3(emit_value);
}

const IR::Expression*
RewriteDeparser::find_emit_source(const PHV::Field* field,
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

bool RewriteDeparser::preorder(IR::BFN::Deparser* deparser) {
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
                        std::vector<uint8_t> bytes;

                        // Original constant IR node may have already been invalidated
                        // during IR rewrite so we do a deep comparison to find original
                        // constant reference.
                        for (auto& kv : const_to_bytes) {
                            if (value.constant->equiv(*kv.first))
                                bytes = kv.second;
                        }

                        BUG_CHECK(!bytes.empty(),
                                  "Constant %1% not extracted in parser?", value.constant);

                        for (auto byte : bytes) {
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
