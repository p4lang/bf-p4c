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
    for (auto kv : all_fields_) {
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
    for (auto kv : all_fields_) {
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

static unsigned num_bytes(unsigned bits) {
    return (bits + 7) / 8;
}

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clotInfo;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clotInfo.clear();
        return rv;
    }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        if (extract->source->is<IR::BFN::PacketRVal>()) {
            if (auto f = phv.field(extract->dest->field))
                clotInfo.all_fields_[state].push_back(f);
        }
        return false;
    }
};

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
         it's beneficical to break a field into bytes.
      2) Inter-state CLOT analysis: this is useful when the maximal gain for a CLOT
         straddles the state boundary.

*/
class NaiveClotAlloc : public Visitor {
    static const int MAX_CLOTS_PER_STATE = 2;  // TODO(zma) move to pardeSpec
    static const int MAX_BYTES_PER_CLOT = 64;
    static const int TOTAL_CLOTS_AVAIL = 16;
    static const int INTER_CLOTS_BYTE_GAP = 3;

    ClotInfo& clotInfo;
    const CollectParserInfo& parserInfo;

    std::map<const IR::BFN::ParserState*, unsigned> tail_gap_credit_map;
    std::map<const IR::BFN::ParserState*, unsigned> head_gap_credit_map;

 public:
    explicit NaiveClotAlloc(ClotInfo& clotInfo,
                            const CollectParserInfo& parserInfo) :
        clotInfo(clotInfo),
        parserInfo(parserInfo) { }

    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused, unsigned total) :
            state(state), unused_bytes(unused), total_bytes(total) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bytes = 0;
        unsigned total_bytes = 0;
        bool operator<(const ClotAlloc& rhs) const {
            if (unused_bytes < rhs.unused_bytes) return true;
            if (unused_bytes > rhs.unused_bytes) return false;
            if (total_bytes < rhs.total_bytes) return true;
            if (total_bytes > rhs.total_bytes) return false;
            return state->id < rhs.state->id;
        }
    };

    std::array<std::vector<ClotAlloc>, 2> compute_requirement() {
       std::array<std::vector<ClotAlloc>, 2> req;

       for (auto& hdrs : clotInfo.all_fields_) {
           auto* state = hdrs.first;

           unsigned state_unused_bytes = 0;
           unsigned state_total_bytes = 0;

           for (auto f : hdrs.second) {
               if (clotInfo.is_clot_candidate(f))
                   state_unused_bytes += num_bytes(f->size);
               state_total_bytes += num_bytes(f->size);
           }

           ClotAlloc ca(state, state_unused_bytes, state_total_bytes);
           req[state->gress].push_back(ca);
       }

       // XXX(zma) replace this with optimizition based on parse graph anlysis

       std::stable_sort(req[0].begin(), req[0].end());
       std::stable_sort(req[1].begin(), req[1].end());

       std::reverse(req[0].begin(), req[0].end());
       std::reverse(req[1].begin(), req[1].end());

       for (auto i : {0, 1} )
           for (auto ca : req[i])
                LOG3("state " << ca.state->name << " has " << ca.unused_bytes << " unused bytes");

       return req;
    }

    unsigned calculate_gap_needed(const IR::BFN::ParserState* state, bool head_or_tail) {
        const IR::BFN::Parser* parser = parserInfo.parser(state);
        auto& preds_or_succs = head_or_tail ? parserInfo.graph(parser).predecessors() :
                                              parserInfo.graph(parser).successors();

        auto& credit_map = head_or_tail ? tail_gap_credit_map : head_gap_credit_map;

        unsigned gap_needed = 0;

        if (preds_or_succs.count(state)) {
            for (auto s : preds_or_succs.at(state)) {
                unsigned gap_needed_for_s = 0;
                auto& state_clots = clotInfo.parser_state_to_clots();

                // XXX(zma) needs to optimize this ...
                if (state_clots.count(s) && state_clots.at(s).size() > 0) {
                    unsigned credit = 0;

                    if (credit_map.count(s))
                        credit = credit_map.at(s);
                    else  // s hasn't been allocated
                        credit = INTER_CLOTS_BYTE_GAP * 8;

                    gap_needed_for_s =
                        (unsigned)std::max(INTER_CLOTS_BYTE_GAP * 8 - static_cast<int>(credit), 0);
                }

                gap_needed = std::max(gap_needed, gap_needed_for_s);
            }
        }

        return gap_needed;
    }

    bool allocate(const ClotAlloc& ca) {
        LOG3("try allocate " << ca.state->name << ", unused = " << ca.unused_bytes);

        if (ca.unused_bytes == 0)
            return false;

        unsigned head_gap_needed = calculate_gap_needed(ca.state, true  /* head */);
        unsigned tail_gap_needed = calculate_gap_needed(ca.state, false /* tail */);

        LOG3(head_gap_needed << " bits of head gap needed");
        LOG3(tail_gap_needed << " bits of tail gap needed");

        // FIXME(zma) state larger than 64 bytes
        if (ca.total_bytes > MAX_BYTES_PER_CLOT)
            return false;

        std::vector<const PHV::Field*> to_be_allocated;

        for (auto f : clotInfo.all_fields_[ca.state])
            to_be_allocated.push_back(f);

        unsigned head_offset = 0;
        unsigned tail_offset = 0;

        // skip through first fields until head gap is satisfied
        unsigned to_delete = 0;
        unsigned skipped_bits = 0;

        for (auto f : to_be_allocated) {
            if (head_gap_needed > skipped_bits) {
                skipped_bits += f->size;
                head_offset += f->size;
                to_delete++;
            }
        }
        for (unsigned i = 0; i < to_delete; ++i)
            to_be_allocated.erase(to_be_allocated.begin());

        // skip through last fields until tail gap is satisfied
        to_delete = 0;
        skipped_bits = 0;

        for (auto it = to_be_allocated.rbegin(); it != to_be_allocated.rend(); ++it) {
            if (tail_gap_needed > skipped_bits) {
                skipped_bits += (*it)->size;
                tail_offset += (*it)->size;
                to_delete++;
            }
        }
        for (unsigned i = 0; i < to_delete; ++i)
            to_be_allocated.pop_back();

        // now see if we can earn some credit on head/tail
        unsigned head_gap_credit = 0;
        unsigned tail_gap_credit = 0;

        to_delete = 0;
        for (auto f : to_be_allocated) {
            if (clotInfo.is_clot_candidate(f))
                break;
            head_gap_credit += f->size;
            head_offset += f->size;
            to_delete++;
        }
        for (unsigned i = 0; i < to_delete; ++i)
            to_be_allocated.erase(to_be_allocated.begin());

        to_delete = 0;
        for (auto it = to_be_allocated.rbegin(); it != to_be_allocated.rend(); ++it) {
            if (clotInfo.is_clot_candidate((*it)))
                break;
            tail_gap_credit += (*it)->size;
            tail_offset += (*it)->size;
            to_delete++;
        }
        for (unsigned i = 0; i < to_delete; ++i)
            to_be_allocated.pop_back();

        // FIXME rollback or skip forward to find byte boundary
        if (head_offset % 8 != 0 || tail_offset % 8 != 0)
            return false;

        // now allocate
        Clot* clot = nullptr;

        // see if can find a mutex state and reuse clot

        int reuse_tag = 0;

        const IR::BFN::Parser* parser = parserInfo.parser(ca.state);
        auto& mutex_state_map = parserInfo.mutex(parser).mutex_state_map();
        if (mutex_state_map.count(ca.state) > 0) {
            for (auto s : mutex_state_map.at(ca.state)) {
                if (clotInfo.parser_state_to_clots().count(s) > 0) {
                    auto& clots = clotInfo.parser_state_to_clots().at(s);
                    reuse_tag = clots[0]->tag;
                    LOG3("can overlay with state " << s->name << " clot " << reuse_tag);
                    break;
                }
            }
        }

        for (auto f : to_be_allocated) {
            if (clot == nullptr) {
                if (reuse_tag > 0)
                    clot = new Clot(reuse_tag);
                else
                    clot = new Clot();

                clot->start = head_offset / 8;  // clot start is in byte, offset in bits
                clotInfo.add(clot, ca.state);
                LOG3("allocate clot " << clot->tag << " to " << ca.state->name);
            }

            if (!clotInfo.is_clot_candidate(f))
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
        for (unsigned i = 0; i < req.size(); ++i) {
            if (clotInfo.num_clots_allocated() == TOTAL_CLOTS_AVAIL)
                break;

            allocate(req[i]);
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
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
        LOGGING(3) ? new DumpParser("before_clot_allocation.dot") : nullptr,
        new CollectClotInfo(phv, clotInfo),
        new NaiveClotAlloc(clotInfo, parserInfo),
    });
}

