#include <array>
#include <vector>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "clot_info.h"


void ClotInfo::dbprint(std::ostream &out) const {
    unsigned total_allocated_clot_fields = 0;
    unsigned total_allocated_clot_bits = 0;

    for (auto c : clots_) {
        out << "clot " << c->tag << " {" << std::endl;
        out << "  all_fields: " << std::endl;
        for (auto f : c->all_fields) {
            out << "    " << f->name << " : " << f->size << std::endl;
            if (is_clot_candidate(f)) {
                total_allocated_clot_fields++;
                total_allocated_clot_bits += f->size;
            }
        }
        out << "  phv_fields: " << std::endl;
        if (c->phv_fields.size() == 0)
             out << "    <none>" << std::endl;
        for (auto f : c->phv_fields)
            out << "    " << f->name << " : " << f->size << std::endl;
        out << "}" << std::endl;
        out << std::endl;
    }

    unsigned total_unused_fields = 0;
    unsigned total_unused_bits = 0;

    out << "all unsed fields :" << std::endl;
    for (auto kv : parser_state_to_fields_) {
        for (auto f : kv.second) {
            if (is_clot_candidate(f)) {
                out << "    " << f->name << " : " << f->size << std::endl;
                total_unused_fields++;
                total_unused_bits += f->size;
            }
        }
    }

    out << std::endl;
    out << "unallocated fields :" << std::endl;
    for (auto kv : parser_state_to_fields_) {
        for (auto f : kv.second) {
            if (is_clot_candidate(f) && !allocated(f))
                out << "    " << f->name << " : " << f->size << std::endl;
        }
    }

    out << "total unused fields : " << total_unused_fields << std::endl;
    out << "total unused bits : " << total_unused_bits << std::endl;
    out << "total clot fields : " << total_allocated_clot_fields << std::endl;
    out << "total clot bits : " << total_allocated_clot_bits << std::endl;
}

/**

 This class implements a greedy CLOT allocation algorithm based on the parse graph.

 The constraints for CLOT allocation are:
    1) Each CLOT can hold up to 64 bytes of contigious data. CLOTs larger than
       32 byte (input buffer size) can spill into the next parser state.
    2) Each parser state can issue up to 2 CLOTs.
    3) Successive CLOTs must have a 3 byte gap (PHV extraction) in between.
    4) There are a total of 64 unique CLOT tags while only up to 16 CLOTs can be
       live in a packet.

  The objective is to allocate as many as "tagalong" fields (fields that do not
  particate in MAU match/action), while minimizing the number of CLOTs used.

  The greedy algorithm used here sorts parser states by number of "tagalong" bits
  in each state, and allocates on a per state basis. At a given state, if any of
  its predecessor/successors has been allocated, the gap constraint needs to be
  satisfied (these are "head" or "tail" gap in the code). If a state's first/last
  few bytes are not a CLOT (i.e. in PHV), then its predecessors/successors can use
  these bytes towards its gap (or "credit" in the code).

  TODO
      1) Currently, a field is either in CLOT or PHV. There might be cases that
         it's beneficical to break a field into slices.
      2) Inter-state CLOT analysis: this is useful when the maximal gain for a CLOT
         straddles the state boundary.

*/
class NaiveClotAlloc : public Visitor {
    static const int MAX_CLOTS_PER_STATE = 2;  // TODO(zma) move to pardeSpec
    static const int MAX_BYTES_PER_CLOT = 64;
    static const int TOTAL_CLOTS_AVAIL = 64;
    static const int MAX_CLOTS_LIVE = 16;
    static const int INTER_CLOTS_BYTE_GAP = 3;

    ClotInfo& clotInfo;
    const CollectParserInfo& parserInfo;

    std::map<const IR::BFN::ParserState*, int> tail_gap_credit_map;
    std::map<const IR::BFN::ParserState*, int> head_gap_credit_map;

    std::map<const IR::BFN::ParserState*,
             std::map<const PHV::Field*, std::set<unsigned>>> field_to_byte_idx;
    std::map<const IR::BFN::ParserState*,
             std::map<unsigned, std::set<const PHV::Field*>>> byte_idx_to_field;

    unsigned num_live_clots = 0;

 public:
    explicit NaiveClotAlloc(ClotInfo& clotInfo,
                            const CollectParserInfo& parserInfo) :
        clotInfo(clotInfo),
        parserInfo(parserInfo) { }

    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused, unsigned total) :
            state(state), unused_bits(unused), total_bits(total) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bits = 0;
        unsigned total_bits = 0;
        bool operator<(const ClotAlloc& rhs) const {
            if (unused_bits < rhs.unused_bits) return true;
            if (unused_bits > rhs.unused_bits) return false;
            if (total_bits < rhs.total_bits) return true;
            if (total_bits > rhs.total_bits) return false;
            return state->id < rhs.state->id;
        }
    };

    // figure out which fields live in which bytes
    void compute_field_byte_map() {
        for (auto kv : clotInfo.parser_state_to_fields_) {
            auto state = kv.first;
            auto& fields_in_state = kv.second;
            unsigned bits = 0;

            for (auto f : fields_in_state) {
                unsigned start_byte =  bits / 8;
                unsigned end_byte = (bits + f->size - 1) / 8;

                for (unsigned i = start_byte; i <= end_byte; i++) {
                    field_to_byte_idx[state][f].insert(i);
                    byte_idx_to_field[state][i].insert(f);
                }

                bits += f->size;
            }
        }

        if (LOGGING(4)) {
            for (auto kv : field_to_byte_idx) {
                std::cout << "state: " << kv.first->name << std::endl;
                for (auto fb : kv.second) {
                    std::cout << fb.first->name << " in byte";
                    for (auto id : fb.second)
                        std::cout << " " << id;
                    std::cout << std::endl;
                }
            }

            for (auto kv : byte_idx_to_field) {
                std::cout << "state: " << kv.first->name << std::endl;
                for (auto bf : kv.second) {
                    std::cout << "Byte " << bf.first << " has:";
                    for (auto f : bf.second)
                        std::cout << " " << f->name;
                    std::cout << std::endl;
                }
            }
        }
    }

    bool is_packed_with_phv_field(const PHV::Field* f) {
        auto state = clotInfo.field_to_parser_state_.at(f);
        for (auto id : field_to_byte_idx.at(state).at(f)) {
            for (auto ff : byte_idx_to_field.at(state).at(id)) {
                if (!clotInfo.is_clot_candidate(ff))
                    return true;
            }
        }

        return false;
    }

    bool can_allocate_to_clot(const PHV::Field* f) {
        return clotInfo.is_clot_candidate(f) && !is_packed_with_phv_field(f);
    }

    bool is_checksum_field(const PHV::Field* f) {
        return clotInfo.checksum_dests_.count(f);
    }

    std::array<std::vector<ClotAlloc>, 2> compute_requirement() {
       std::array<std::vector<ClotAlloc>, 2> req;

       for (auto& hdrs : clotInfo.parser_state_to_fields_) {
           auto* state = hdrs.first;

           unsigned state_unused_bits = 0;
           unsigned state_total_bits = 0;

           for (auto f : hdrs.second) {
               if (can_allocate_to_clot(f))
                   state_unused_bits += f->size;
               state_total_bits += f->size;
           }

           ClotAlloc ca(state, state_unused_bits, state_total_bits);
           req[state->gress].push_back(ca);
       }

       // XXX(zma) replace this with optimizition based on parse graph anlysis

       std::stable_sort(req[0].begin(), req[0].end());
       std::stable_sort(req[1].begin(), req[1].end());

       std::reverse(req[0].begin(), req[0].end());
       std::reverse(req[1].begin(), req[1].end());

       for (auto i : {0, 1} )
           for (auto ca : req[i])
                LOG3("state " << ca.state->name << " has " << ca.unused_bits << " unused bytes");

       return req;
    }

    unsigned calculate_gap_needed(const IR::BFN::ParserState* state, bool head_or_tail) {
        const IR::BFN::Parser* parser = parserInfo.parser(state);

        auto& preds_or_succs = head_or_tail ? parserInfo.graph(parser).predecessors()
                                            : parserInfo.graph(parser).successors();

        auto& credit_map = head_or_tail ? tail_gap_credit_map
                                        : head_gap_credit_map;

        int gap_needed = 0;

        if (preds_or_succs.count(state)) {
            for (auto s : preds_or_succs.at(state)) {
                int gap_needed_for_s = 0;
                auto& state_clots = clotInfo.parser_state_to_clots();

                if (state_clots.count(s->name) && state_clots.at(s->name).size() > 0) {
                    int credit = 0;

                    if (credit_map.count(s))
                        credit = credit_map.at(s);
                    else  // s hasn't been allocated
                        credit = INTER_CLOTS_BYTE_GAP * 8;

                    gap_needed_for_s = std::max(INTER_CLOTS_BYTE_GAP * 8 - credit, 0);
                } else {
                    auto& fields_in_state = clotInfo.parser_state_to_fields_[s];

                    int bits_in_s = 0;
                    for (auto f : fields_in_state)
                        bits_in_s += f->size;

                    // P4C-965 if s is small (less than 3 bytes), we need to check its
                    // preds/succs, as their gap requirement may spill into current state.
                    if (bits_in_s < INTER_CLOTS_BYTE_GAP * 8) {
                        int head_or_tail_gap_for_s = calculate_gap_needed(s, head_or_tail);
                        gap_needed_for_s = head_or_tail_gap_for_s - bits_in_s;
                    }
                }

                gap_needed = std::max(gap_needed, gap_needed_for_s);
            }
        }

        BUG_CHECK(gap_needed >= 0, "negative gap needed?");

        return (unsigned)gap_needed;
    }

    // This is the core routine to allocate CLOT for a given parse state. The key
    // idea is that given the list of fields in that state, we try to find the head
    // and tail index in the list, such that the head and tail gap constraint is
    // satisfied (see comment above about this). Everything between the head and tail
    // index can then be allocated to a CLOT.
    bool allocate(const ClotAlloc& ca) {
        LOG3("try allocate " << ca.state->name << ", unused = " << ca.unused_bits);

        if (ca.unused_bits == 0)
            return false;

        auto head_gap_needed = calculate_gap_needed(ca.state, true  /* head */);
        auto tail_gap_needed = calculate_gap_needed(ca.state, false /* tail */);

        LOG3(head_gap_needed << " bits of head gap needed");
        LOG3(tail_gap_needed << " bits of tail gap needed");

        auto& fields_in_state = clotInfo.parser_state_to_fields_[ca.state];

        if (fields_in_state.size() == 0)
            return false;

        int head_index = 0;
        int tail_index = fields_in_state.size() - 1;

        auto head_field = fields_in_state[head_index];
        unsigned head_offset = (clotInfo.field_range_.at(head_field)).lo;
        unsigned tail_offset = 0;

        // skip through first fields until head gap is satisfied

        for (int i = head_index; i <= tail_index && (head_gap_needed > head_offset); i++) {
            auto f = fields_in_state.at(i);
            head_offset += f->size;
            head_index++;
        }

        // skip through last fields until tail gap is satisfied

        for (int i = tail_index; i >= head_index && (tail_gap_needed > tail_offset); i--) {
            auto f = fields_in_state.at(i);
            tail_offset += f->size;
            tail_index--;
        }

        if (head_index > tail_index)
            return false;

        // now see if we can earn some credit on head/tail

        unsigned head_gap_credit = 0;
        unsigned tail_gap_credit = 0;

        for (int i = head_index; i <= tail_index; i++) {
            auto f = fields_in_state.at(i);
            if (can_allocate_to_clot(f))
                break;
            head_offset += f->size;
            head_gap_credit += f->size;
            head_index++;
        }

        for (int i = tail_index; i >= head_index; i--) {
            auto f = fields_in_state.at(i);
            if (can_allocate_to_clot(f))
                break;
            tail_offset += f->size;
            tail_gap_credit += f->size;
            tail_index--;
        }

        if (head_index > tail_index)
            return false;

        // TODO(zma) In many cases, it's a win to rollback on head
        // and skip forward on tail to find byte boundary to maximize CLOT
        // contiguity. This involves double allocating the head/tail fields
        // to both CLOTs and PHV. This also means setting additional packing/slicing
        // constraints on PHV allocation, as deparser can only deparse whole containers.

        // For now, skip forward or rollback to find byte boundary

        for (int i = head_index; i <= tail_index; i++) {
            if (head_offset % 8 == 0)
                break;
            auto f = fields_in_state.at(i);
            head_offset += f->size;
            head_gap_credit += f->size;
            head_index++;
        }

        for (int i = tail_index; i >= head_index; i--) {
            if (tail_offset % 8 == 0)
                break;
            auto f = fields_in_state.at(i);
            tail_offset += f->size;
            tail_gap_credit += f->size;
            tail_index--;
        }

        if (head_index > tail_index)
            return false;

        if (head_gap_needed > head_offset || tail_gap_needed > tail_offset)
            return false;

        if (head_offset % 8 != 0 || tail_offset % 8 != 0)
            return false;

        // now allocate
        Clot* clot = nullptr;

        // see if can find a mutex state and reuse clot tag
        int overlay_tag = -1;

        const IR::BFN::Parser* parser = parserInfo.parser(ca.state);
        auto& mutex_state_map = parserInfo.mutex(parser).mutex_state_map();
        if (mutex_state_map.count(ca.state) > 0) {
            for (auto s : mutex_state_map.at(ca.state)) {
                if (clotInfo.parser_state_to_clots().count(s->name) > 0) {
                    auto& clots = clotInfo.parser_state_to_clots().at(s->name);
                    overlay_tag = clots[0]->tag;
                    LOG3("can overlay with state " << s->name << " clot " << overlay_tag);
                    break;
                }
            }
        }

        for (int i = head_index; i <= tail_index; i++) {
            auto f = fields_in_state.at(i);

            if (clot == nullptr) {
                if (overlay_tag == -1)
                    num_live_clots++;

                clot = new Clot();

                clot->start = head_offset / 8;  // clot start is in byte, offset in bits
                clotInfo.add_clot(clot, ca.state);
                LOG3("allocate clot " << clot->tag << " to " << ca.state->name);
            }

            if (clot->length_in_bits() + f->size > MAX_BYTES_PER_CLOT * 8)
                break;

            if (is_checksum_field(f))
                clot->csum_fields.push_back(f);
            else if (!can_allocate_to_clot(f))
                clot->phv_fields.push_back(f);

            clot->all_fields.push_back(f);
        }

        head_gap_credit_map[ca.state] = head_gap_credit;
        tail_gap_credit_map[ca.state] = tail_gap_credit;

        LOG3(head_gap_credit << " bits of head credit earned");
        LOG3(tail_gap_credit << " bits of tail credit earned");

        return true;
    }

    void allocate(const std::vector<ClotAlloc>& req) {
        for (int i = 0; i < req.size(); ++i) {
            if (clotInfo.num_clots_allocated() == TOTAL_CLOTS_AVAIL ||
                num_live_clots == MAX_CLOTS_LIVE)
                break;

            allocate(req[i]);
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
        compute_field_byte_map();

        std::array<std::vector<ClotAlloc>, 2> req = compute_requirement();

        allocate(req[0]);  // ingress
        allocate(req[1]);  // egress

        LOG3("=== CLOT allocation ===");
        LOG3(clotInfo);

        return n;
    }
};

AllocateClot::AllocateClot(ClotInfo &clotInfo, const PhvInfo &phv, PhvUse &uses) {
    addPasses({
        &uses,
        &parserInfo,
        LOGGING(3) ? new DumpParser("before_clot_allocation") : nullptr,
        new CollectClotInfo(phv, clotInfo),
        new NaiveClotAlloc(clotInfo, parserInfo)
    });
}
