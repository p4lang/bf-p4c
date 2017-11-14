#include <queue>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "clot_info.h"

void ClotInfo::dbprint(std::ostream &out) const {
    for (auto c : clots_) {
        out << "clot " << c->tag << " : " << std::endl;
        out << "  all_fields: ";
        for (auto f : c->all_fields)
            out << f << " ";
        out << std::endl;
        out << "  phv_fields: ";
        for (auto f : c->phv_fields)
            out << f << " ";
        out << std::endl;
    }
}

static unsigned num_bytes(unsigned bits) {
    return (bits + 7) / 8;
}

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clot;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clot) : phv(phv), clot(clot) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clot.clear();
        return rv;
    }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        if (extract->source->is<IR::BFN::PacketRVal>()) {
            if (auto f = phv.field(extract->dest->field))
                clot.all_fields_[state].push_back(f);
        }
        return false;
    }
};

class NaiveClotAlloc : public Visitor {
    static const int MAX_CLOTS_PER_STATE = 2;  // TODO(zma) move to pardeSpec
    static const int MAX_BYTES_PER_CLOT = 64;
    static const int TOTAL_CLOTS_AVAIL = 16;

    ClotInfo& clot;
    const PhvUse &uses;

 public:
    NaiveClotAlloc(ClotInfo& clot, const PhvUse& uses) :
        clot(clot), uses(uses) {}

    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused, unsigned total) :
            state(state), unused_bytes(unused), total_bytes(total) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bytes = 0;
        unsigned total_bytes = 0;
        bool operator<(const ClotAlloc& rhs) const {
            return unused_bytes < rhs.unused_bytes;
        }
    };

    bool is_clot_candidate(const PHV::Field* field) {
        return !uses.is_used_mau(field) && uses.is_used_parde(field);
    }

    std::priority_queue<ClotAlloc*> compute_requirement() {
       std::priority_queue<ClotAlloc*> q;

       for (auto& hdrs : clot.all_fields_) {
           unsigned state_unused_bytes = 0;
           unsigned state_total_bytes = 0;

           for (auto f : hdrs.second) {
               if (is_clot_candidate(f))
                   state_unused_bytes += num_bytes(f->size);
               state_total_bytes += num_bytes(f->size);
           }

           LOG3("state " << hdrs.first->name << " has " << state_unused_bytes << " unused bytes");

           auto r = new ClotAlloc(hdrs.first, state_unused_bytes, state_total_bytes);
           q.push(r);
       }

       return q;
    }

    void allocate(ClotAlloc* ca) {
        if (ca->total_bytes <= MAX_BYTES_PER_CLOT) {
            Clot* cl = new Clot();
            clot.add(cl, ca->state);

            for (auto f : clot.all_fields_[ca->state]) {
                if (!is_clot_candidate(f))
                    cl->phv_fields.push_back(f);
                cl->all_fields.push_back(f);
            }
        } else {
            // TODO(zma) state larger than 64 bytes
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
        // sort all parser states in decreasing order of num of bytes
        // that do not participate in the mau pipe

        std::priority_queue<ClotAlloc*> q = compute_requirement();

        while (!q.empty() && clot.clots().size() <= TOTAL_CLOTS_AVAIL) {
            auto t = q.top();
            allocate(t);
            q.pop();
        }

        return n;
    }
};

AllocateClot::AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses) {
    addPasses({
        &uses,
        new CollectClotInfo(phv, clot),
        new NaiveClotAlloc(clot, uses),
        });
}

