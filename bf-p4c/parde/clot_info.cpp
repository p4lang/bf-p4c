#include <array>
#include <vector>

#include "bf-p4c/common/utils.h"
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

class NaiveClotAlloc : public Visitor {
    static const int MAX_CLOTS_PER_STATE = 2;  // TODO(zma) move to pardeSpec
    static const int MAX_BYTES_PER_CLOT = 64;
    static const int TOTAL_CLOTS_AVAIL = 16;
    static const int INTER_CLOTS_BYTE_GAP = 3;

    ClotInfo& clotInfo;
    /*const BuildParserOverlay2& mutexStates;*/

    struct ParserStatePredecessor : public Inspector {
        ParserStatePredecessor() {}

        const IR::BFN::ParserState* get(const IR::BFN::ParserState* state) {
            if (pred.count(state))
                return pred.at(state);
            return nullptr;
        }

     private:
        std::map<const IR::BFN::ParserState*, const IR::BFN::ParserState*> pred;

        bool preorder(const IR::BFN::ParserState* state) override {
            auto p = findContext<IR::BFN::ParserState>();
            if (p) {
                pred[state] = p;
                LOG3("pred of " << state->name << " is " << p->name);
            }
            return true;
        }
    } predecessor;

    std::map<const IR::BFN::ParserState*, unsigned> state_gap_credit;

 public:
    explicit NaiveClotAlloc(ClotInfo& clotInfo /*, const BuildParserOverlay2& mutexStates*/) :
        clotInfo(clotInfo) /*, mutexStates(mutexStates)*/ { }

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

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);
        root->apply(predecessor);
        return rv;
    }

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

    bool allocate(const ClotAlloc& ca) {
        LOG3("try allocate " << ca.state->name << ", unused = " << ca.unused_bytes);

        if (ca.unused_bytes == 0)
            return false;

        unsigned gap_needed = 0;

        auto* pred = predecessor.get(ca.state);

        if (pred) {
            auto& state_clots = clotInfo.parser_state_to_clots();

            // XXX(zma) needs to optimize this ...
            if (state_clots.count(pred) && state_clots.at(pred).size() > 0) {
                unsigned pred_gap_credit = 0;
                if (state_gap_credit.count(pred))
                    pred_gap_credit = state_gap_credit.at(pred);
                gap_needed = INTER_CLOTS_BYTE_GAP * 8 - pred_gap_credit;
                LOG3(gap_needed << " bits of gap needed");
            }
        }

        // FIXME(zma) state larger than 64 bytes
        /*if (ca.total_bytes > MAX_BYTES_PER_CLOT)
            return false;
        */

        // extract whole header in clot
        Clot* clot = nullptr;
        unsigned offset = 0;

        std::vector<const PHV::Field*> to_be_allocated;

        bool seen_unused_field = false;
        for (auto f : clotInfo.all_fields_[ca.state]) {
            if (!seen_unused_field && !clotInfo.is_clot_candidate(f)) {
                offset += f->size;
                continue;
            }

            to_be_allocated.push_back(f);
        }

        seen_unused_field = true;
        unsigned last_fields_to_delete = 0;
        unsigned gap_credit = 0;

        for (auto it = to_be_allocated.rbegin(); it != to_be_allocated.rend(); ++it) {
            auto* f = *it;
            if (!seen_unused_field && !clotInfo.is_clot_candidate(f)) {
                gap_credit += f->size;
                last_fields_to_delete++;
                continue;
            }
        }

        for (unsigned i = 0; i < last_fields_to_delete; i++)
            to_be_allocated.pop_back();

        // see if can find a mutex state and reuse clot

        int reuse_tag = 0;
        // TODO add overlay logic here

        for (auto f : to_be_allocated) {
            if (gap_needed > offset + 1) {
                offset += f->size;
                continue;
            }

            if (clot == nullptr) {
                if (reuse_tag > 0)
                    clot = new Clot(reuse_tag);
                else
                    clot = new Clot();

                clot->start = offset;
                clotInfo.add(clot, ca.state);
            }

            if (!clotInfo.is_clot_candidate(f))
                clot->phv_fields.push_back(f);

            clot->all_fields.push_back(f);

            offset += f->size;
        }

        state_gap_credit[ca.state] = gap_credit;

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
        LOGGING(3) ? new DumpParser("before_clot_allocation.dot") : nullptr,
        /*&parser_overlay,*/
        new CollectClotInfo(phv, clotInfo),
        new NaiveClotAlloc(clotInfo/*, parser_overlay*/),
    });
}

