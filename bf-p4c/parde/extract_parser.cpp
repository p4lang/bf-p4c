#include "extract_parser.h"

#include <boost/range/adaptor/reversed.hpp>

#include <algorithm>
#include <vector>

#include "ir/ir.h"
#include "lib/log.h"
#include "tofino/parde/add_parde_metadata.h"

namespace Tofino {

namespace {

/// A helper type that represents a transitive predecessor of the current state
/// in the parse graph.
struct Ancestor {
    Ancestor(const IR::Tofino::ParserState* state,
             const IR::Tofino::ParserMatch* match);

    /// The ancestor state.
    const IR::Tofino::ParserState* state;

    /// The outgoing edge of the ancestor state that we traversed to reach the
    /// current state.
    const IR::Tofino::ParserMatch* match;
    bool canBePartOfLoop;
};

/// The stack of ancestors we traversed to reach the current state.
typedef std::vector<Ancestor> AncestorStack;

Ancestor::Ancestor(const IR::Tofino::ParserState* state,
                   const IR::Tofino::ParserMatch* match)
        : state(state), match(match), canBePartOfLoop(true) {
    // If a state extracts a header which isn't part of a header stack, we don't
    // allow it to be part of a loop. Such a loop would trigger an error at
    // runtime anyway since the parser can't overwrite a PHV container it has
    // already written to.
    forAllMatching<IR::Primitive>(&match->stmts, [&](const IR::Primitive* prim) {
        if (prim->name != "extract") return;
        if (!prim->operands[0]->is<IR::HeaderRef>()) return;
        if (!prim->operands[0]->is<IR::HeaderStackItemRef>())
            canBePartOfLoop = false;
    });
}

}  // namespace

class GetTofinoParser : public Inspector {
 public:
    static const IR::Tofino::Parser*
    extract(gress_t gress, const IR::P4Parser* parser,
            bool filterSetMetadata = false);

    void addMatch(IR::Tofino::ParserState *, match_t,
                  const IR::Vector<IR::Expression> &, const IR::ID &);
    IR::Tofino::ParserState *state(cstring);

 private:
    GetTofinoParser(gress_t gress, bool filterSetMetadata)
        : gress(gress), filterSetMetadata(filterSetMetadata) { }

    bool preorder(const IR::ParserState *) override;

    AncestorStack                               ancestorStack;
    gress_t                                     gress = INGRESS;
    map<cstring, IR::Tofino::ParserState *>     states;
    bool                                        filterSetMetadata;
};

/* static */ const IR::Tofino::Parser*
GetTofinoParser::extract(gress_t gress, const IR::P4Parser* parser,
                         bool filterSetMetadata /* = false */) {
    GetTofinoParser getter(gress, filterSetMetadata);
    parser->apply(getter);
    auto startState = getter.state("start");
    return new IR::Tofino::Parser(gress, startState);
}

// XXX(seth): This pass should go away; we should just perform this lowering
// directly when converting to Tofino IR.
class SplitExtractEmit : public PardeTransform {
    IR::Node *preorder(IR::Primitive *p) override {
        if (p->name != "extract" && p->name != "emit")
            return p;
        assert(p->operands.size() == 1);
        auto *hdr = p->operands[0]->to<IR::HeaderRef>();
        if (!hdr) return p;
        auto *rv = new IR::Vector<IR::Expression>;
        auto *hdr_type = hdr->type->to<IR::Type_StructLike>();
        assert(hdr_type);
        for (auto field : hdr_type->fields) {
            IR::Expression *fref = new IR::Member(field->type, hdr, field->name);
            rv->push_back(new IR::Primitive(p->srcInfo, p->name, fref)); }
        if (p->name == "extract" && !hdr->baseRef()->is<IR::Metadata>()) {
            rv->push_back(new IR::Primitive(p->srcInfo, "set_metadata",
                new IR::Member(IR::Type::Bits::get(1), hdr, "$valid"),
                new IR::Constant(1))); }
        return rv;
    }
};

class LowerParser : public PassManager {
 public:
  explicit LowerParser(const IR::Tofino::Pipe* pipe) {
      setName("LowerParser");
      passes.push_back(new SplitExtractEmit);
      passes.push_back(new AddMetadataShims(pipe));
  }
};

ParserInfo extractParser(const IR::Tofino::Pipe* pipe,
                         const IR::P4Parser* igParser,
                         const IR::P4Control* igDeparser,
                         const IR::P4Parser* egParser /* = nullptr */,
                         const IR::P4Control* egDeparser /* = nullptr */) {
  CHECK_NULL(igParser);
  CHECK_NULL(igDeparser);

  // Convert the parsers. If no egress parser was provided, we generate one from
  // the ingress parser by removing all 'set_metadata' primitives.
  auto tofinoIgParser = GetTofinoParser::extract(INGRESS, igParser);
  auto tofinoEgParser = egParser != nullptr
      ? GetTofinoParser::extract(EGRESS, egParser)
      : GetTofinoParser::extract(EGRESS, igParser, /* filterSetMetadata = */ true);

  // Convert the deparsers, generating the egress deparser if necessary.
  const auto* tofinoIgDeparser = new IR::Tofino::Deparser(INGRESS, igDeparser);
  const auto* tofinoEgDeparser = egDeparser != nullptr
      ? new IR::Tofino::Deparser(EGRESS, egDeparser)
      : new IR::Tofino::Deparser(EGRESS, tofinoEgParser);

  LowerParser lowerParser(pipe);
  return {
      tofinoIgParser->apply(lowerParser),
      tofinoIgDeparser->apply(lowerParser),
      tofinoEgParser->apply(lowerParser),
      tofinoEgDeparser->apply(lowerParser)
  };
}

bool GetTofinoParser::preorder(const IR::ParserState *p) {
    if (p->name == "accept" || p->name == "reject")
        return false;
    auto *s = states[p->name] = new IR::Tofino::ParserState(p, gress);
    if (s->name != p->name)
        states[s->name] = s;
    return true;
}

class FindStackExtract : public Inspector {
    const IR::HeaderRef         *hdr;
    int                         &index;
    bool preorder(const IR::HeaderStackItemRef *hs) override {
        auto prim = findContext<IR::Primitive>();
        if (!prim || prim->name != "extract") return true;  // do we need this check?
        LOG3("   FindStackExtract(" << hs->toString() << ")  hdr=" << hdr->toString() <<
             "  hs->base=" << hs->base()->toString());
        if (hs->base()->toString() == hdr->toString()) {
            auto idx = dynamic_cast<const IR::Constant *>(hs->index());
            if (idx)
                index = std::max(index, idx->asInt()); }
        return true; }
 public:
    FindStackExtract(const IR::HeaderRef *h, int &out) : hdr(h), index(out) {}
    FindStackExtract(const IR::Expression *e, int &out)
    : hdr(dynamic_cast<const IR::HeaderRef *>(e)), index(out) {
        if (!hdr) BUG("not a valid header ref"); }
};

class RewriteExtractNext : public Transform {
    AncestorStack&                ancestorStack;
    std::map<cstring, int>        adjust;
    bool                          filterSetMetadata;

    const IR::Expression *preorder(IR::Member *name) override;
    const IR::Vector<IR::Expression> *preorder(IR::IndexedVector<IR::StatOrDecl> *vec) override {
        auto *rv = new IR::Vector<IR::Expression>;
        for (auto stmt : *vec) {
            auto *n = apply_visitor(stmt);
            if (!n) continue;
            else if (auto *e = n->to<IR::Expression>())
                rv->push_back(e);
            else if (auto *v = n->to<IR::Vector<IR::Expression>>())
                rv->insert(rv->end(), v->begin(), v->end()); }
        prune();  // don't visit children again
        return rv; }
    const IR::Node *preorder(IR::MethodCallStatement *s) override {
        return transform_child(s->methodCall); }
    const IR::Expression *preorder(IR::MethodCallExpression *e) override {
        if (auto meth = e->method->to<IR::Member>()) {
            if (meth->member == "extract")
                return new IR::Primitive(meth->srcInfo, "extract", e->arguments);
        } else {
            BUG("invalid method call %s", e); }
        return e; }
    const IR::Expression *preorder(IR::AssignmentStatement *s) override {
        if (!canEvaluateInParser(s->right))
            ::error("Assignment cannot be supported in the parser: %1%", s->right);
        if (filterSetMetadata) return nullptr;
        return new IR::Primitive(s->srcInfo, "set_metadata", s->left, s->right); }
    const IR::Expression *preorder(IR::Statement *) override { BUG("Unhandled statement kind"); }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // Peel off any Cast expression. This accepts more programs than we can
        // actually implement; some casts can't be performed at parse time.
        if (expression->is<IR::Cast>()) {
            expression = expression->to<IR::Cast>()->expr;
        }

        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>() ||
               expression->is<IR::ArrayIndex>();
    }

 public:
    bool                        failed = false;
    RewriteExtractNext(AncestorStack& ancestorStack, bool filterSetMetadata)
        : ancestorStack(ancestorStack), filterSetMetadata(filterSetMetadata) { }
};

const IR::Expression *RewriteExtractNext::preorder(IR::Member *m) {
    if (m->member != "next" && m->member != "last") return m;
    int index = -1;
    // XXX(seth): This isn't sound. There could be more than one path through
    // the parse graph that reaches this point, and each path may have extracted
    // this header stack a different number of times.
    for (auto ancestor : boost::adaptors::reverse(ancestorStack)) {
        ancestor.match->stmts.apply(FindStackExtract(m->expr, index));
        if (index >= 0) break;
    }
    cstring hdrname = m->expr->toString();
    index += adjust[hdrname];
    if (m->member == "next")
        ++index;
    LOG2("   rewrite " << m << " => [" << index << "]");
    if (index >= m->expr->type->to<IR::Type_Stack>()->size->to<IR::Constant>()->asInt()) {
        failed = true;
        return m; }
    if (auto prim = findContext<IR::Primitive>())
        if (prim->name == "extract")
            adjust[hdrname]++;
    return new IR::HeaderStackItemRef(m->srcInfo,
        m->expr->type->to<IR::Type_Stack>()->elementType->to<IR::Type_Header>(),
        m->expr, new IR::Constant(index));
}

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, match_t match_val,
                               const IR::Vector<IR::Expression> &stmts, const IR::ID &action) {
    LOG2("GetParser::addMatch(" << s->p4state->toString() << ", " << match_val <<
         ", " << (ancestorStack.size() + 1) << ")");

    auto match = new IR::Tofino::ParserMatch(match_val, stmts);
    s->match.push_back(match);

    ancestorStack.emplace_back(s, match);
    match->next = state(action);
    ancestorStack.pop_back();

    // If there is a parser state with this name, but we couldn't generate it,
    // its probably because we've unrolled a loop filling a header stack
    // completely.
    // XXX: Should we set some parser error code?
    if (match->next != nullptr) return;
    if (action == "accept" || action == "reject") return;
    if (!states.count(action))
        error("%s: No definition for %s", action.srcInfo, action);
}

static match_t buildListMatch(const IR::Vector<IR::Expression> *list) {
    match_t     rv;
    for (auto el : *list) {
        int width = el->type->width_bits();
        rv.word0 <<= width;
        rv.word1 <<= width;
        uintmax_t mask = -1, v;
        mask = ~(mask << width);
        if (auto k = el->to<IR::Constant>()) {
            v = k->asLong();
        } else if (auto mval = el->to<IR::Mask>()) {
            v = mval->right->to<IR::Constant>()->asLong();
            rv.word0 |= mask & ~v;
            rv.word1 |= mask & ~v;
            mask &= v;
            v = mval->left->to<IR::Constant>()->asLong();
        } else {
            BUG("Invalid select case expression %1%", el); }
        rv.word0 |= mask & ~v;
        rv.word1 |= mask & v; }
    return rv;
}

static match_t buildMatch(int match_size, const IR::Expression *key) {
    if (key->is<IR::DefaultExpression>())
        return match_t();
    else if (auto k = key->to<IR::Constant>())
        return match_t(match_size, k->asLong(), ~0ULL);
    else if (auto mask = key->to<IR::Mask>())
        return match_t(match_size, mask->left->to<IR::Constant>()->asLong(),
                                   mask->right->to<IR::Constant>()->asLong());
    else if (auto list = key->to<IR::ListExpression>())
        return buildListMatch(&list->components);
    else
        BUG("Invalid select case expression %1%", key);
    return match_t();
}

IR::Tofino::ParserState *GetTofinoParser::state(cstring name) {
    if (states.count(name) == 0) return nullptr;
    if (ancestorStack.size() >= 256) return nullptr;
    auto rv = states[name];

    // Check if we've already reached this state on this path, and if so, make
    // sure that the resulting loop is legal.
    bool isLegalLoop = true;
    for (auto ancestor : boost::adaptors::reverse(ancestorStack)) {
        isLegalLoop &= ancestor.canBePartOfLoop;
        if (ancestor.state != rv) continue;
        if (!isLegalLoop) return nullptr;
        rv = new IR::Tofino::ParserState(ancestor.state->p4state, gress);
        rv->name = cstring::make_unique(states, name);
        states[rv->name] = rv;
        break;
    }

    if (!rv->match.empty()) return rv;
    RewriteExtractNext rewrite(ancestorStack, filterSetMetadata);
    const IR::Vector<IR::Expression> *stmts;
    stmts = rv->p4state->components.Node::apply(rewrite)->to<IR::Vector<IR::Expression>>();
    if (rewrite.failed)
        // FIXME should be setting an appropriate parser exception?
        return nullptr;
    rv->select = *rv->select.apply(rewrite);
    int match_size = 0;
    for (auto s : rv->select)
        match_size += s->type->width_bits();

    LOG2("GetParser::state(" << name << ")");
    if (!rv->p4state->selectExpression) {
    } else if (auto *path = rv->p4state->selectExpression->to<IR::PathExpression>()) {
        addMatch(rv, match_t(), *stmts, path->path->name);
    } else if (auto *sel = rv->p4state->selectExpression->to<IR::SelectExpression>()) {
        for (auto ce : sel->selectCases)
            addMatch(rv, buildMatch(match_size, ce->keyset), *stmts,
                     ce->state->path->name);
    } else {
        BUG("Invalid select expression %1%", rv->p4state->selectExpression); }

    return rv;
}

}  // namespace Tofino
