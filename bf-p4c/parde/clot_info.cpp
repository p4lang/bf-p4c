#include <array>
#include <vector>

#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/device.h"
#include "bf-p4c/logging/logging.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "clot_info.h"

std::string ClotInfo::print() const {
    std::stringstream out;

    unsigned total_unused_fields_in_clots = 0;
    unsigned total_unused_bits_in_clots = 0;
    unsigned total_bits = 0;

    out << "CLOT Allocation:" << std::endl;

    TablePrinter tp(out, {"CLOT", "Fields", "Bits", "Property"},
                          TablePrinter::Align::CENTER);

    std::set<int> unaligned_clots;
    for (auto c : clots_) {
        bool first_in_clot = true;
        unsigned bits_in_clot = 0;
        bitvec bits_unused;
        for (auto f : c->all_fields()) {
            if (is_clot_candidate(f)) {
                total_unused_fields_in_clots++;
                bits_unused.setrange(c->bit_offset(f), f->size);
            }

            std::stringstream bits;
            bits << f->size
                 << " [" << c->bit_offset(f) << ".." << (c->bit_offset(f) + f->size - 1) << "]";

            bool is_phv = c->is_phv_field(f);
            bool is_csum = c->is_csum_field(f);

            std::string attr;
            if (is_phv || is_csum) {
                attr += " (";
                if (is_phv) attr += " phv";
                if (is_csum) attr += " csum";
                attr += " ) ";
            }

            tp.addRow({first_in_clot ? std::to_string(c->tag) : "",
                       std::string(f->name),
                       bits.str(),
                       attr});

            bits_in_clot = std::max(bits_in_clot, c->bit_offset(f) + f->size);
            first_in_clot = false;
        }

        total_unused_bits_in_clots += bits_unused.popcount();
        total_bits += bits_in_clot;

        if (bits_in_clot % 8 != 0) unaligned_clots.insert(c->tag);
        unsigned bytes = bits_in_clot / 8;

        tp.addRow({"", "", std::to_string(bytes) + " bytes", ""});
        tp.addBlank();
    }

    tp.addSep();
    tp.addRow({"", "Total Bits", std::to_string(total_bits), ""});
    tp.print();

    unsigned total_unused_fields = 0;
    unsigned total_unused_bits = 0;

    out << std::endl;
    out << "all unused fields :" << std::endl;
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

    out << "total unused fields: " << total_unused_fields << std::endl;
    out << "total unused bits: " << total_unused_bits << std::endl;
    out << "total unused fields allocated in CLOTs: " << total_unused_fields_in_clots << std::endl;
    out << "total unused bits allocated in CLOTs: " << total_unused_bits_in_clots << std::endl;

    // Bug-check.
    if (!unaligned_clots.empty()) {
        std::clog << out.str();
        std::stringstream out;
        bool first_tag = true;
        int count = 0;
        for (auto tag : unaligned_clots) {
            out << (first_tag ? "" : ", ") << tag;
            first_tag = false;
            count++;
        }
        BUG("CLOT%s %s not byte-aligned", count > 1 ? "s" : "", out.str());
    }

    return out.str();
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
    std::map<const IR::BFN::ParserState*, bitvec> state_bit_occupancy;

    unsigned num_live_clots = 0;

 public:
    explicit NaiveClotAlloc(ClotInfo& clotInfo,
                            const CollectParserInfo& parserInfo) :
        clotInfo(clotInfo),
        parserInfo(parserInfo) { }

    /// Provides accounting information for a parse state. Tracks total bits extracted, and number
    /// of bits that are not PHV-allocated.
    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused, unsigned total) :
            state(state), unused_bits(unused), total_bits(total) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bits = 0;
        unsigned total_bits = 0;

        // Implements lexicographic ordering according to (unused_bits, total_bits, state id).
        bool operator<(const ClotAlloc& rhs) const {
            if (unused_bits < rhs.unused_bits) return true;
            if (unused_bits > rhs.unused_bits) return false;
            if (total_bits < rhs.total_bits) return true;
            if (total_bits > rhs.total_bits) return false;
            return state->id < rhs.state->id;
        }
    };

    /// Figure out which fields live in which bits/bytes: populates @ref field_to_byte_idx, @ref
    /// byte_idx_to_field, and @ref state_bit_occupancy.
    void compute_maps() {
        for (auto kv : clotInfo.parser_state_to_fields_) {
            auto state = kv.first;
            auto& fields_in_state = kv.second;

            for (auto f : fields_in_state) {
                unsigned f_offset = clotInfo.offset(state, f);
                state_bit_occupancy[state].setrange(f_offset, f->size);

                unsigned start_byte =  f_offset / 8;
                unsigned end_byte = (f_offset + f->size - 1) / 8;

                for (unsigned i = start_byte; i <= end_byte; i++) {
                    field_to_byte_idx[state][f].insert(i);
                    byte_idx_to_field[state][i].insert(f);
                }
            }
        }

        if (LOGGING(4)) {
            std::clog << "=====================================================" << std::endl;

            for (auto kv : field_to_byte_idx) {
                std::clog << "state: " << kv.first->name << std::endl;
                for (auto fb : kv.second) {
                    std::clog << "  " << fb.first->name << " in byte";
                    for (auto id : fb.second)
                        std::clog << " " << id;
                    std::clog << std::endl;
                }
            }

            std::clog << "-----------------------------------------------------" << std::endl;

            for (auto kv : byte_idx_to_field) {
                std::clog << "state: " << kv.first->name << std::endl;
                for (auto bf : kv.second) {
                    std::clog << "  Byte " << bf.first << " has:";
                    for (auto f : bf.second)
                        std::clog << " " << f->name;
                    std::clog << std::endl;
                }
            }

            std::clog << "=====================================================" << std::endl;
        }
    }

    /// Determines whether any part of the given field is PHV-allocated. This can happen when the
    /// field itself is PHV-allocated, or when the field is packed with a PHV-allocated field
    /// (e.g., if the field is not byte-aligned and shares a container with a PHV-allocated field).
    bool is_packed_with_phv_field(const PHV::Field* f) {
        auto& states = clotInfo.field_to_parser_states_.at(f);
        for (auto state : states) {
            for (auto id : field_to_byte_idx.at(state).at(f)) {
                for (auto ff : byte_idx_to_field.at(state).at(id)) {
                    if (!clotInfo.is_clot_candidate(ff))
                        return true;
                }
            }
        }

        return false;
    }

    // Memoization table.
    std::map<const PHV::Field*, bool> can_allocate_to_clot_;

    bool can_allocate_to_clot(const PHV::Field* f) {
        if (!can_allocate_to_clot_.count(f))
            can_allocate_to_clot_[f] =
                clotInfo.is_clot_candidate(f) &&
                !is_packed_with_phv_field(f);

        return can_allocate_to_clot_.at(f);
    }

    bool is_checksum_field(const PHV::Field* f) {
        return clotInfo.checksum_dests_.count(f);
    }

    /// Produces a pair of ClotAlloc lists -- one for each gress. Each list is sorted in descending
    /// order.
    std::array<std::vector<ClotAlloc>, 2> compute_requirement() {
        std::array<std::vector<ClotAlloc>, 2> req;

        for (auto& hdrs : clotInfo.parser_state_to_fields_) {
            auto* state = hdrs.first;

            // Fields may overlap. This bit-vector tracks whether each bit in the state is unused
            // (i.e., is not PHV-allocated).
            bitvec state_bits_unused;

            // Figure out which bits are unused. At the same time, compute the actual total bits in
            // the parser state.
            unsigned state_total_bits = 0;
            for (auto f : hdrs.second) {
                 unsigned offset = clotInfo.offset(state, f);
                 if (can_allocate_to_clot(f)) state_bits_unused.setrange(offset, f->size);

                 state_total_bits = std::max(state_total_bits, (unsigned) (offset + f->size));
            }

            // Count up the number of unused bits in the parser state.
            unsigned state_unused_bits = state_bits_unused.popcount();

            ClotAlloc ca(state, state_unused_bits, state_total_bits);
            req[state->gress].push_back(ca);
        }

        // XXX(zma) replace this with optimization based on parse graph analysis

        std::stable_sort(req[0].begin(), req[0].end());
        std::stable_sort(req[1].begin(), req[1].end());

        std::reverse(req[0].begin(), req[0].end());
        std::reverse(req[1].begin(), req[1].end());

        for (auto i : {0, 1} )
            for (auto ca : req[i])
                 LOG3("state " << ca.state->name << " has " << ca.unused_bits << " unused bits");

        return req;
    }

    /// Determines the amount of inter-CLOT gap needed at the beginning (when @arg head_or_tail is
    /// true) or end (when @arg head_or_tail is false) of a given parse state.
    unsigned calculate_gap_needed(const IR::BFN::ParserState* state, bool head_or_tail) {
        LOG5("finding " << (head_or_tail ? "head" : "tail") << " gap needed for " << state->name);
        const IR::BFN::Parser* parser = parserInfo.parser(state);

        auto& preds_or_succs = head_or_tail ? parserInfo.graph(parser).predecessors()
                                            : parserInfo.graph(parser).successors();

        auto& credit_map = head_or_tail ? tail_gap_credit_map
                                        : head_gap_credit_map;

        // Find the largest gap needed for any predecessor/successor state.
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

                    // Figure out the number of bits in the state s by finding the bit range of the
                    // fields in the state.
                    bool first_field = true;
                    int max_offset = 0;
                    int min_offset = 0;
                    for (auto f : fields_in_state) {
                        int field_min_offset = clotInfo.offset(s, f);
                        int field_max_offset = field_min_offset + f->size - 1;

                        if (first_field) {
                            min_offset = field_min_offset;
                            max_offset = field_max_offset;
                            first_field = false;
                        } else {
                            min_offset = std::min(min_offset, field_min_offset);
                            max_offset = std::max(max_offset, field_max_offset);
                        }
                    }

                    int bits_in_s = first_field ? 0 : max_offset - min_offset + 1;

                    // P4C-965 if s is small (less than 3 bytes), we need to check its
                    // preds/succs, as their gap requirement may spill into current state.
                    if (bits_in_s < INTER_CLOTS_BYTE_GAP * 8) {
                        int head_or_tail_gap_for_s = calculate_gap_needed(s, head_or_tail);
                        gap_needed_for_s = std::max(head_or_tail_gap_for_s - bits_in_s, 0);
                    }
                }

                LOG5(gap_needed_for_s << " bits of " << (head_or_tail ? "head" : "tail")
                    << " gap needed for neighbour state " << s->name);

                gap_needed = std::max(gap_needed, gap_needed_for_s);
            }
        }

        LOG5("-> " << gap_needed << " bits of " << (head_or_tail ? "head" : "tail")
            << " gap needed for state " << state->name);
        BUG_CHECK(gap_needed >= 0, "negative gap needed?");

        return (unsigned)gap_needed;
    }

    // This is the core routine to allocate a CLOT to a given parse state. The key idea is that
    // given the list of fields in that state, we try to find the head and tail offsets for the
    // CLOT, such that:
    //
    //   - the head and tail gap constraint is satisfied (see comment above about this);
    //   - the head offset lands at the start of a byte;
    //   - the tail offset lands at the end of a byte;
    //   - every bit in the CLOT is part of a field;
    //   - if the bit pointed to by the head offset is part of a field, then it is the first bit of
    //     that field; and
    //   - if the bit pointed to by the tail offset is part of a field, then it is the last bit of
    //     that field.
    //
    // Fields that land between the head and tail offsets can then be allocated to a CLOT.
    bool allocate(const ClotAlloc& ca) {
        LOG3("try allocate " << ca.state->name << ", unused = " << ca.unused_bits);

        if (ca.unused_bits == 0)
            return false;

        auto head_gap_needed = calculate_gap_needed(ca.state, true  /* head */);
        auto tail_gap_needed = calculate_gap_needed(ca.state, false /* tail */);

        LOG3("  " << head_gap_needed << " bits of head gap needed");
        LOG3("  " << tail_gap_needed << " bits of tail gap needed");

        auto& fields_in_state = clotInfo.parser_state_to_fields_[ca.state];

        if (fields_in_state.size() == 0)
            return false;

        // The offset of the first field in the state can be non-zero if the previous state didn't
        // shift for whatever reason.
        unsigned state_min_byte_offset = byte_idx_to_field[ca.state].begin()->first;
        unsigned state_max_byte_offset = byte_idx_to_field[ca.state].rbegin()->first;

        unsigned num_bytes_in_state = state_max_byte_offset - state_min_byte_offset + 1;

        if (head_gap_needed + tail_gap_needed >= 8 * num_bytes_in_state)
            return false;

        // Start by pointing to the first/last byte in the state that satisfies the head/tail-gap
        // constraint.
        int head_byte_offset = state_min_byte_offset + (head_gap_needed + 7) / 8;
        int tail_byte_offset = state_max_byte_offset - (tail_gap_needed + 7) / 8;

        // Earn "credit" by starting at the gap offsets and advancing the pointers towards each
        // other until we find offsets that satisfy the conditions above, and are not
        // PHV-allocated.
        //
        // TODO(zma) In many cases, it's a win to rollback on head
        // and skip forward on tail to find byte boundary to maximize CLOT
        // contiguity. This involves double allocating the head/tail fields
        // to both CLOTs and PHV. This also means setting additional packing/slicing
        // constraints on PHV allocation, as deparser can only deparse whole containers.
        //
        // For now, skip forward on head and rollback on tail to find byte boundary

        // Advance the head offset before moving the tail offset.
        bool moving_head = true;
        while (head_byte_offset <= tail_byte_offset) {
            if (moving_head) {
                // Make sure the first bit of the head_byte_offset is occupied by a field.
                if (!state_bit_occupancy[ca.state].getbit(head_byte_offset * 8)) {
                    head_byte_offset++;
                    continue;
                }
            }

            bool moved = false;

            auto fields =
                byte_idx_to_field[ca.state][moving_head ? head_byte_offset : tail_byte_offset];
            for (auto f : fields) {
                auto field_bytes = field_to_byte_idx[ca.state][f];
                int min_field_byte = *field_bytes.begin();
                int max_field_byte = *field_bytes.rbegin();

                if ((moving_head && head_byte_offset != min_field_byte)
                        || (!moving_head && tail_byte_offset != max_field_byte)
                        || !can_allocate_to_clot(f)) {
                    // Advance past f.
                    if (moving_head) head_byte_offset = max_field_byte + 1;
                    else if (min_field_byte == 0) return false;
                    else
                        tail_byte_offset = min_field_byte - 1;

                    moved = true;
                    break;
                }
            }

            if (moved) continue;

            if (!moving_head) break;

            // Just finished moving the head offset. Now move the tail offset, but first adjust if
            // necessary to make sure we are within the CLOT's capacity.
            int max_tail_byte_offset = head_byte_offset + MAX_BYTES_PER_CLOT - 1;
            tail_byte_offset = std::min(tail_byte_offset, max_tail_byte_offset);

            // Also make sure all bits between the start of the head_byte_offset and the end of the
            // tail_byte_offset are occupied by a field.
            int first_unoccupied_bit_offset = head_byte_offset * 8 + 1;
            while (first_unoccupied_bit_offset < (tail_byte_offset + 1) * 8 &&
                   state_bit_occupancy[ca.state].getbit(first_unoccupied_bit_offset))
                first_unoccupied_bit_offset++;

            tail_byte_offset = first_unoccupied_bit_offset / 8 - 1;

            moving_head = false;
        }

        if (head_byte_offset > tail_byte_offset)
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
                    LOG3("  " << "can overlay with state " << s->name << " clot " << overlay_tag);
                    break;
                }
            }
        }

        for (auto f : fields_in_state) {
            // Only consider the field if it lies entirely in the CLOT.
            auto field_bytes = field_to_byte_idx[ca.state][f];
            int min_field_byte = *field_bytes.begin();
            int max_field_byte = *field_bytes.rbegin();
            if (min_field_byte < head_byte_offset || max_field_byte > tail_byte_offset)
                continue;

            if (clot == nullptr) {
                if (overlay_tag == -1)
                    num_live_clots++;

                clot = new Clot();

                clot->start = head_byte_offset;
                clotInfo.add_clot(clot, ca.state);
                LOG3("  " << "allocate clot " << clot->tag << " to " << ca.state->name);
            }

            Clot::FieldKind kind;
            if (is_checksum_field(f)) kind = Clot::FieldKind::CHECKSUM;
            else if (!can_allocate_to_clot(f)) kind = Clot::FieldKind::PHV;
            else
                kind = Clot::FieldKind::OTHER;

            unsigned f_offset = clotInfo.offset(ca.state, f) - 8 * head_byte_offset;

            if (LOGGING(4)) {
                std::string kind_str;
                switch (kind) {
                case Clot::FieldKind::CHECKSUM: kind_str = "checksum "; break;
                case Clot::FieldKind::PHV: kind_str = "phv "; break;
                case Clot::FieldKind::OTHER: kind_str = ""; break;
                }

                LOG4("  adding " << kind_str << "field " << f->name << " at byte " << f_offset);
            }
            clot->add_field(kind, f, f_offset);
        }

        unsigned head_gap_credit =
            8 * (head_byte_offset - state_min_byte_offset) - head_gap_needed;
        unsigned tail_gap_credit =
            8 * (state_max_byte_offset - tail_byte_offset) - tail_gap_needed;

        head_gap_credit_map[ca.state] = head_gap_credit;
        tail_gap_credit_map[ca.state] = tail_gap_credit;

        LOG3("  " << head_gap_credit << " bits of head credit earned");
        LOG3("  " << tail_gap_credit << " bits of tail credit earned");

        return true;
    }

    void allocate(const std::vector<ClotAlloc>& req) {
        for (unsigned i = 0; i < req.size(); ++i) {
            if (clotInfo.num_clots_allocated() == TOTAL_CLOTS_AVAIL ||
                num_live_clots == MAX_CLOTS_LIVE)
                break;

            allocate(req[i]);
        }
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        // Make sure we clear our state from previous invocations of the visitor.
        auto result = Visitor::init_apply(root);
        clear();
        return result;
    }

    const IR::Node *apply_visitor(const IR::Node *root, const char *) override {
        compute_maps();

        std::array<std::vector<ClotAlloc>, 2> req = compute_requirement();

        allocate(req[0]);  // ingress
        allocate(req[1]);  // egress

        const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
        Logging::FileLog parserLog(pipe->id, "parser.log", true /* append */);

        LOG2(clotInfo.print());

        return root;
    }

    void clear() {
        tail_gap_credit_map.clear();
        head_gap_credit_map.clear();
        field_to_byte_idx.clear();
        byte_idx_to_field.clear();
        can_allocate_to_clot_.clear();
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
