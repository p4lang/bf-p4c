#include "check_parser_multi_write.h"

#include "bf-p4c/common/utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

struct InferWriteMode : public ParserTransform {
    const PhvInfo& phv;
    const CollectParserInfo& parser_info;
    const MapFieldToParserStates& field_to_states;

    InferWriteMode(const PhvInfo& ph, const CollectParserInfo& pi,
                   const MapFieldToParserStates& fs) :
        phv(ph), parser_info(pi), field_to_states(fs) { }

    std::map<const IR::BFN::Extract*, IR::BFN::ParserWriteMode> extract_to_write_mode;

    ordered_set<const IR::BFN::Extract*> zero_inits;
    ordered_set<const IR::BFN::Extract*> dead_extracts;

    // Find the first writes, i.e. inits, given the set of extracts. The set of extracts
    // belong to the same field. An init is a write that has no prior write in the parser IR.
    ordered_set<const IR::BFN::Extract*>
    find_inits(const ordered_set<const IR::BFN::Extract*>& extracts) {
        ordered_set<const IR::BFN::Extract*> inits;

        for (auto p : extracts) {
            bool is_prev = false;

            auto ps = field_to_states.extract_to_state.at(p);
            auto parser = field_to_states.state_to_parser.at(ps);

            for (auto q : extracts) {
                if (p == q)
                    continue;

                auto qs = field_to_states.extract_to_state.at(q);

                // case 1. q is in a parser state that is an ancestor to p
                if (parser_info.graph(parser).is_ancestor(qs, ps)) {
                    is_prev = true;
                    break;
                } else if (ps == qs) {
                // case 2. p and q are in the same parser state but q happens before p
                    for (auto o : extracts) {
                        if (o == p)
                            break;
                        if (o == q) {
                            is_prev = true;
                            break;
                        }
                    }
                }
            }

            if (!is_prev)
               inits.insert(p);
        }

        return inits;
    }

    ordered_set<const IR::BFN::Extract*>
    exclude_zero_inits(const ordered_set<const IR::BFN::Extract*>& extracts) {
        auto inits = find_inits(extracts);
        ordered_set<const IR::BFN::Extract*> rv;

        for (auto e : extracts) {
            if (is_zero_extract(e) && inits.count(e)) {
                zero_inits.insert(e);
                continue;
            }

            rv.insert(e);
        }

        return rv;
    }

    bool is_zero_extract(const IR::BFN::Extract* e) {
        if (auto src = e->source->to<IR::BFN::ConstantRVal>()) {
            if (src->constant->value == 0)
                return true;
        }

        return false;
    }

    bool same_const_source(const IR::BFN::Extract* p, const IR::BFN::Extract* q) {
       auto pc = p->source->to<IR::BFN::ConstantRVal>();
       auto qc = q->source->to<IR::BFN::ConstantRVal>();

       return (pc && qc) ? *(pc->constant) == *(qc->constant) : false;
    }

    ordered_set<const IR::BFN::Extract*>
    get_previous_writes(const IR::BFN::Extract* p,
                        const ordered_set<const IR::BFN::Extract*>& extracts) {
        ordered_set<const IR::BFN::Extract*> rv;

        auto ps = field_to_states.extract_to_state.at(p);
        auto parser = field_to_states.state_to_parser.at(ps);

        for (auto q : extracts) {
            auto qs = field_to_states.extract_to_state.at(q);

            if (parser_info.graph(parser).is_reachable(qs, ps)) {
                if (!same_const_source(p, q))
                    rv.insert(q);
            } else if (ps == qs) {
                bool is_prev = false;

                for (auto o : extracts) {
                    if (o == p)
                        break;
                    if (o == q)
                        is_prev = true;
                }

                if (is_prev && !same_const_source(p, q))
                    rv.insert(q);
            }
        }

        return rv;
    }

    void mark_write_mode(IR::BFN::ParserWriteMode mode,
                         const PHV::Field* dest,
                         const ordered_set<const IR::BFN::Extract*>& extracts) {
        LOG3("mark " << dest->name << " as " << mode);

        for (auto e : extracts)
            extract_to_write_mode[e] = mode;
    }

    struct CounterExample {
        ordered_set<const IR::BFN::Extract*> prev;
        const IR::BFN::Extract* curr = nullptr;
        const bool is_error = false;

        CounterExample(ordered_set<const IR::BFN::Extract*> prev,
                       const IR::BFN::Extract* curr)
            : prev(prev), curr(curr), is_error(false) { }
        CounterExample(ordered_set<const IR::BFN::Extract*> prev,
                       const IR::BFN::Extract* curr,
                       const bool is_error)
            : prev(prev), curr(curr), is_error(is_error) { }
    };

    void print(CounterExample* example) {
        bool found_err = false;
        for (auto p : example->prev) {
            auto ps = field_to_states.extract_to_state.at(p);

            // This should be error instead, but downgraded because of P4C-1995
            if (!example->is_error)
                ::warning("%1% has previous assignment in parser state %2%.",
                            example->curr->dest->field, ps->name);
            else {
                ::error("%1% has previous assignment in parser state %2%. "
                        "This is an error because the field will either always be assigned "
                        "multiple times or there is a loopback in the parser that "
                        "always reassigns the field. Check previous warnings to see more "
                        "and remove it.",
                        example->curr->dest->field, ps->name);
                found_err = true;
            }
        }
        if (found_err)
            throw Util::CompilationError("Compilation failed! (multi-assignment in parser)");
    }

    bool is_single_write(const ordered_set<const IR::BFN::Extract*>& writes) {
        for (auto x : writes) {
            auto prev = get_previous_writes(x, writes);

            if (!prev.empty())
                return false;
        }

        return true;
    }

    bool can_absorb(const IR::BFN::Extract* prev, const IR::BFN::Extract* curr) {
       auto pc = prev->source->to<IR::BFN::ConstantRVal>();
       auto qc = curr->source->to<IR::BFN::ConstantRVal>();

       if (pc && qc) {
           auto or_prev = *(pc->constant) | *(qc->constant);
           if (or_prev.fitsUint64() && qc->constant->fitsUint64()) {
               return or_prev.asUint64() == qc->constant->asUint64();
           }
       }

       return false;
    }

    /// Determines whether extract @p write is postdominated by extract of the same
    /// field (from @p writes).
    /// Essentially we want to check 2 separate things:
    ///   1. A state/extract is postdominated by extracts of a same field as is (without loopbacks)
    ///      Example: A->B
    ///                ->C
    ///      if A, B, C extract the same field x
    ///         then is_postdominated_by_extract = true
    ///      if A, B extract the same field x, but C does not
    ///         then is_postdominated_by_extract = false
    ///   2. There is a loopback in which the same field is always extracted
    ///      (loop start is postdominate by extracts within that loop).
    ///      In this case we also have to take into account the fact that
    ///      the "loop from" state needs to be dominated by the set, otherwise
    ///      the loop might make sense when we reach this state without extracting
    ///      the field and then take the loopback once.
    ///      Example: A->B->D->A    (loopback from D to A)
    ///                ->C->
    ///      if B, C extract the same field x
    ///         then is_postdominated_by_extract = true
    ///      if A or D extract the field x
    ///         then is_postdominated_by_extract = true
    ///      if A, D does not extract x and only one of B, C extract the field x
    ///         then is_postdominated_by_extract = false
    bool is_postdominated_by_extract(const IR::BFN::Extract* write,
                                     const ordered_set<const IR::BFN::Extract*>& writes) {
        // Get states, parser, graph
        auto state = field_to_states.extract_to_state.at(write);
        auto parser = field_to_states.state_to_parser.at(state);
        auto graph = parser_info.graph(parser);
        ordered_set<const IR::BFN::ParserState*> states;
        for (auto w : writes) {
            auto ws = field_to_states.extract_to_state.at(w);
            states.insert(ws);
        }

        // Check if the state is directly postdominated by the extracts
        if (graph.is_postdominated_by_set(state, states)) {
            ::warning("Extract %1% in state %2% is postdominated by extracts of the same field.",
                      write->dest->field, state->name);
            return true;
        }
        // Check all of the loops if they have a postdomination inside
        // and also the "loop from" state is dominated by the same set
        auto lb = graph.is_loopback_reassignment(state, states);
        if (lb.first && lb.second) {
            ::warning("Extract %1% in state %2% is postdominated by extracts of the same field "
                      "within a loopback from %3% to %4%.",
                      write->dest->field, state->name, lb.second->name, lb.first->name);
            return true;
        }
        return false;
    }

    CounterExample* is_bitwise_or(const PHV::Field* dest,
                                  const ordered_set<const IR::BFN::Extract*>& writes) {
        if (dest->name.endsWith("$stkvalid"))
            return nullptr;

        CounterExample* counter_example = nullptr;

        for (auto e : writes) {
            auto prev = get_previous_writes(e, writes);

            for (auto p : prev) {
                if (e->write_mode != IR::BFN::ParserWriteMode::BITWISE_OR && !can_absorb(p, e)) {
                    if (Device::currentDevice() == Device::TOFINO &&
                        is_postdominated_by_extract(p, writes)) {
                        return new CounterExample(prev, e, true);
                    } else {
                        counter_example = new CounterExample(prev, e, false);
                    }
                }
            }
        }

        return counter_example;
    }

    CounterExample* is_clear_on_write(const ordered_set<const IR::BFN::Extract*>& writes) {
        auto inits = find_inits(writes);

        const IR::BFN::Extract* prev = nullptr;

        for (auto e : writes) {
            if (!inits.count(e) && e->write_mode == IR::BFN::ParserWriteMode::BITWISE_OR)
                return new CounterExample({prev}, e);

            prev = e;
        }

        return nullptr;
    }

    // At this time, a field's write mode is either SINGLE_WRITE or BITWISE_OR (from program
    // directly). We will try to infer the fields with multiple extracts as SINGLE_WRITE,
    // BITWISE_OR or CLEAR_ON_WRITE.
    void infer_write_mode(const PHV::Field* dest,
                          const ordered_set<const IR::BFN::Extract*>& extracts) {
        for (auto e : extracts) {
            BUG_CHECK(e->write_mode != IR::BFN::ParserWriteMode::CLEAR_ON_WRITE,
                      "field already as clear-on-write mode?");
        }

        auto writes = exclude_zero_inits(extracts);

        if (is_single_write(writes)) {
            mark_write_mode(IR::BFN::ParserWriteMode::SINGLE_WRITE, dest, extracts);
            return;
        }

        auto counter_example = is_bitwise_or(dest, writes);

        if (!counter_example) {
            mark_write_mode(IR::BFN::ParserWriteMode::BITWISE_OR, dest, extracts);
            return;
        } else if (Device::currentDevice() == Device::TOFINO) {
            auto ps = field_to_states.extract_to_state.at(counter_example->curr);

            // This should be error instead, but downgraded because of P4C-1995
            ::warning("Tofino does not support clear-on-write semantic on "
                    "re-assignment to field %1% in parser state %2%. "
                    "This may lead to a runtime-error. Try to use advance() to skip "
                    "over the re-assigned values and only extract them once.",
                    dest->name, ps->name);
            print(counter_example);
            return;
        }

        counter_example = is_clear_on_write(writes);

        if (!counter_example) {
            mark_write_mode(IR::BFN::ParserWriteMode::CLEAR_ON_WRITE, dest, extracts);
            mark_dead_clear_on_writes(extracts);
        } else {
            auto ps = field_to_states.extract_to_state.at(counter_example->curr);

            // This should be error instead, but downgraded because of P4C-1995
            ::warning("Inconsistent parser write semantic for field %1% in parser state %2%.",
                      dest->name, ps->name);
            print(counter_example);
        }
    }

    // For consecutive writes to the same field in the same state, the last write wins.
    // In example below, a.x receives two writes, with only the last write taking effect,
    // and the first extract can be dead code eliminated. The extracts are writes to the
    // field.
    //
    //    packet.extract(hdr.a);
    //    packet.extract(hdr.b);
    //
    //    hdr.a.x = hdr.b.y;
    //
    void mark_dead_clear_on_writes(const ordered_set<const IR::BFN::Extract*>& extracts) {
        std::map<const IR::BFN::ParserState*,
                 ordered_set<const IR::BFN::Extract*>> state_to_extracts;

        for (auto e : extracts) {
            auto s = field_to_states.extract_to_state.at(e);
            state_to_extracts[s].insert(e);
        }

        for (auto& kv : state_to_extracts) {
            // If more than one writes exist, the last write wins.
            // Mark all other writes as dead to be elim'd later.

            if (kv.second.size() > 1) {
                ordered_set<const IR::BFN::Extract*>::size_type i = 0;
                for (auto e : kv.second) {
                    if (i == kv.second.size() - 1)
                        break;
                    dead_extracts.insert(e);
                    i++;
                }
            }
        }
    }

    IR::Node* preorder(IR::BFN::Extract* extract) override {
        auto orig = getOriginal<IR::BFN::Extract>();

        if (zero_inits.count(orig)) {
            LOG3("removed zero init " << extract);
            // return a new ParserZeroInit IR node instead of removing it. And also mark
            // ParserZeroInit as write in TofinoContextWrite, so that extract->dest->field will be
            // recognized as write in field_defuse. The reason to do this is because if this
            // instruction is removed here, then in field_defuse, all of uses whose def is parser
            // zero initialization will disappear and result in incorrection defuse generation.
            // In addition, in lower_parser.cpp, ParserZeroInit IR node will be ignored, so that
            // this node is removed in this way.
            if (auto member = extract->dest->field->to<IR::Member>()) {
                if (member->member.name.endsWith("$valid")) {
                    return nullptr;
                }
            }
            return new IR::BFN::ParserZeroInit(new IR::BFN::FieldLVal(extract->dest->field));
        }

        if (dead_extracts.count(orig)) {
            LOG3("removed dead extract " << extract);
            return nullptr;
        }

        if (extract_to_write_mode.count(orig))
            extract->write_mode = extract_to_write_mode.at(orig);

        auto dest = phv.field(extract->dest->field);

        if (dest && dest->name.endsWith("$stkvalid"))
            extract->write_mode = IR::BFN::ParserWriteMode::BITWISE_OR;

        return extract;
    }

    profile_t init_apply(const IR::Node* root) override {
        for (auto& kv : field_to_states.field_to_extracts) {
            bool loop_state = false;

            for (auto s : field_to_states.field_to_parser_states.at(kv.first)) {
                if (s->stride) {
                    loop_state = true;
                    break;
                }
            }

            if (!loop_state)
                infer_write_mode(kv.first, kv.second);
        }

        return ParserTransform::init_apply(root);
    }
};

// Check if fields that share the same byte on the wire have conflicting
// parser write semantics.
struct CheckWriteModeConsistency : public ParserTransform {
    const PhvInfo& phv;
    const MapFieldToParserStates& field_to_states;

    std::map<const IR::BFN::Extract*, IR::BFN::ParserWriteMode> extract_to_write_mode;

    CheckWriteModeConsistency(const PhvInfo& p,
                              const MapFieldToParserStates& fs) :
        phv(p), field_to_states(fs) { }

    void check(const ordered_set<const IR::BFN::Extract*>& extracts) {
        const IR::BFN::Extract* prev = nullptr;

        for (auto curr : extracts) {
            if (prev) {
                auto a = prev->source->to<IR::BFN::InputBufferRVal>();
                auto b = curr->source->to<IR::BFN::InputBufferRVal>();

                if (a && b) {
                    if (prev->write_mode != curr->write_mode) {
                        if (a->range.hi / 8 == b->range.lo / 8) {
                            auto curr_dest = phv.field(curr->dest->field);
                            auto prev_dest = phv.field(prev->dest->field);

                            if (curr_dest->padding || prev_dest->padding) {
                                if (curr_dest->padding)
                                    extract_to_write_mode[prev] = curr->write_mode;
                                else
                                    extract_to_write_mode[curr] = prev->write_mode;
                            } else {
                                ::error("%1% and %2% share the same byte on the wire but"
                                        " have conflicting parser write semantics.",
                                         curr_dest->name, prev_dest->name);
                            }
                        }
                    }
                }
            }

            prev = curr;
        }
    }

    profile_t init_apply(const IR::Node* root) override {
        for (auto& kv : field_to_states.state_to_extracts) {
            check(kv.second);
        }

        return ParserTransform::init_apply(root);
    }

    IR::Node* preorder(IR::BFN::Extract* extract) override {
        auto orig = getOriginal<IR::BFN::Extract>();

        if (extract_to_write_mode.count(orig))
            extract->write_mode = extract_to_write_mode.at(orig);

        return extract;
    }
};

// If any egress intrinsic metadata, e.g. "eg_intr_md.egress_port" is mirrored,
// the mirrored version will overwrite the original version in the EPB. Because Tofino
// parser only supports bitwise-or semantic on rewrite, we need to transform the
// egress intrinsic metadata parsing to avoid the bitwise-or cloberring in such case.
// See COMPILER-319 and test
// glass/testsuite/p4_tests/parde/COMPILER-319/mirror-eg_intr_md.p4
//
struct FixupMirroredIntrinsicMetadata : public PassManager {
    struct FindMirroredIntrinsicMetadata : public ParserInspector {
        const PhvInfo& phv;
        std::set<const PHV::Field*> mirrored_intrinsics;

        const IR::BFN::ParserState* check_mirrored = nullptr;
        const IR::BFN::ParserState* egress_entry_point = nullptr;
        const IR::BFN::ParserState* bridged = nullptr;
        const IR::BFN::ParserState* mirrored = nullptr;

        explicit FindMirroredIntrinsicMetadata(const PhvInfo& p) : phv(p) { }

        bool preorder(const IR::BFN::ParserState* state) override {
            if (state->name.startsWith("egress::$mirror_field_list_egress")) {
                for (auto stmt : state->statements) {
                    if (auto extract = stmt->to<IR::BFN::Extract>()) {
                        auto dest = phv.field(extract->dest->field);
                        if (dest->name.startsWith("egress::eg_intr_md")) {
                            mirrored_intrinsics.insert(dest);
                        }
                    }
                }
            } else if (state->gress == EGRESS && state->name == "$entry_point") {
                egress_entry_point = state;
            } else if (state->name == "egress::$check_mirrored") {
                check_mirrored = state;
            } else if (state->name == "egress::$mirrored") {
                mirrored = state;
            } else if (state->name == "egress::$bridged_metadata") {
                bridged = state;
            }

            return true;
        }
    };

    struct RemoveExtracts : public ParserTransform {
        const PhvInfo& phv;
        const FindMirroredIntrinsicMetadata& mim;

        std::vector<const IR::BFN::Extract*> extracts;

        RemoveExtracts(const PhvInfo& p, const FindMirroredIntrinsicMetadata& m) :
            phv(p), mim(m) { }

        IR::BFN::Extract* preorder(IR::BFN::Extract* extract) override {
            auto state = findContext<IR::BFN::ParserState>();

            if (state->name == "$mirror_entry_point") {
                auto dest = phv.field(extract->dest->field);
                if (mim.mirrored_intrinsics.count(dest)) {
                    extracts.push_back(extract);
                    return nullptr;
                }
            }

            return extract;
        }
    };

    struct ReimplementEgressEntryPoint : public ParserTransform {
        const PhvInfo& phv;
        const FindMirroredIntrinsicMetadata& mim;

        ReimplementEgressEntryPoint(const PhvInfo& p,
                                    const FindMirroredIntrinsicMetadata& m) : phv(p), mim(m) { }

        IR::BFN::ParserState* new_start = nullptr;
        IR::BFN::ParserState* mirror_entry = nullptr;
        IR::BFN::ParserState* bridge_entry = nullptr;

        struct InstallEntryStates : public ParserTransform {
            const IR::BFN::ParserState* mirror_entry;
            const IR::BFN::ParserState* bridge_entry;

            InstallEntryStates(const IR::BFN::ParserState* m, const IR::BFN::ParserState* b) :
                mirror_entry(m), bridge_entry(b) { }

            IR::BFN::Transition* postorder(IR::BFN::Transition* transition) override {
                auto next = transition->next;

                if (next) {
                    if (next->name == "egress::$bridged_metadata") {
                        transition->next = bridge_entry;
                    } else if (next->name == "egress::$mirrored") {
                        transition->next = mirror_entry;
                    }
                }

                return transition;
            }
        };

        void create_new_start_state() {
            new_start = mim.check_mirrored->clone();

            auto shift = get_state_shift(mim.egress_entry_point);
            new_start->statements = *(new_start->statements.apply(ShiftPacketRVal(-shift * 8)));
            new_start->selects = *(new_start->selects.apply(ShiftPacketRVal(-shift * 8)));

            bridge_entry = mim.egress_entry_point->clone();
            bridge_entry->name = "$bridge_entry_point";

            mirror_entry = mim.egress_entry_point->clone();
            mirror_entry->name = "$mirror_entry_point";

            RemoveExtracts re(phv, mim);
            mirror_entry = mirror_entry->apply(re)->to<IR::BFN::ParserState>()->clone();

            InstallEntryStates ies(mirror_entry, bridge_entry);
            new_start = new_start->apply(ies)->to<IR::BFN::ParserState>()->clone();

            auto to_bridge = new IR::BFN::Transition(match_t(), shift, mim.bridged);
            bridge_entry->transitions = { to_bridge };

            auto to_mirror = new IR::BFN::Transition(match_t(), shift, mim.mirrored);
            mirror_entry->transitions = { to_mirror };
        }

        profile_t init_apply(const IR::Node* root) override {
            if (!mim.mirrored_intrinsics.empty())
                create_new_start_state();

            return ParserTransform::init_apply(root);
        }

        IR::BFN::Parser* preorder(IR::BFN::Parser* parser) override {
            if (parser->gress == EGRESS && new_start) {
                parser->start = new_start;
            }

            return parser;
        }
    };

    explicit FixupMirroredIntrinsicMetadata(const PhvInfo& phv) {
        auto findMirroredIntrinsicMetadata = new FindMirroredIntrinsicMetadata(phv);
        auto reimplementEgressEntry =
            new ReimplementEgressEntryPoint(phv, *findMirroredIntrinsicMetadata);

        addPasses({
            findMirroredIntrinsicMetadata,
            reimplementEgressEntry
        });
    }
};

CheckParserMultiWrite::CheckParserMultiWrite(const PhvInfo& phv) : phv(phv) {
    auto parser_info = new CollectParserInfo;
    auto field_to_states = new MapFieldToParserStates(phv);
    auto infer_write_mode = new InferWriteMode(phv, *parser_info, *field_to_states);
    auto check_write_mode_consistency = new CheckWriteModeConsistency(phv, *field_to_states);
    auto fixup_mirrored_intrinsic = new FixupMirroredIntrinsicMetadata(phv);

    bool needs_fixup = Device::currentDevice() == Device::TOFINO &&
                       BackendOptions().arch == "v1model";

    addPasses({
        LOGGING(4) ? new DumpParser("before_check_parser_multi_write") : nullptr,
        needs_fixup ? fixup_mirrored_intrinsic : nullptr,
        LOGGING(4) ? new DumpParser("after_fixup_mirrorred_intrinsic_metadata") : nullptr,
        parser_info,
        field_to_states,
        infer_write_mode,
        field_to_states,
        check_write_mode_consistency,
        LOGGING(4) ? new DumpParser("after_check_parser_multi_write") : nullptr,
    });
}
