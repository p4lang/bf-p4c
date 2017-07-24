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
    forAllMatching<IR::Tofino::Extract>(&match->stmts,
                  [&](const IR::Tofino::Extract* extract) {
        if (!extract->dest->is<IR::Member>()) return;
        auto header = extract->dest->to<IR::Member>()->expr;
        if (!header->is<IR::HeaderRef>()) return;
        if (header->is<IR::HeaderStackItemRef>()) return;
        canBePartOfLoop = false;
    });
}

}  // namespace

class GetTofinoParser : public Inspector {
 public:
    static const IR::Tofino::Parser*
    extract(gress_t gress, const IR::P4Parser* parser,
            bool filterSetMetadata = false);

    void addMatch(IR::Tofino::ParserState*, match_t,
                  const IR::Vector<IR::Tofino::ParserPrimitive>&, const IR::ID&);
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

  AddMetadataShims addMetadataShims(pipe);
  return {
      tofinoIgParser->apply(addMetadataShims),
      tofinoIgDeparser->apply(addMetadataShims),
      tofinoEgParser->apply(addMetadataShims),
      tofinoEgDeparser->apply(addMetadataShims)
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
        if (!findContext<IR::Tofino::Extract>()) return true;
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

    const IR::Expression *preorder(IR::Member *name) override;

 public:
    bool                        failed = false;
    explicit RewriteExtractNext(AncestorStack& ancestorStack)
        : ancestorStack(ancestorStack) { }
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
    if (auto call = findContext<IR::MethodCallExpression>()) {
        auto meth = call->method->to<IR::Member>();
        if (meth == nullptr || meth->member != "extract" ||
              call->arguments->size() != 1) {
            ::warning("Unexpected method call in parser: %1%", call);
            failed = true;
            return m;
        }
        adjust[hdrname]++;
    }
    return new IR::HeaderStackItemRef(m->srcInfo,
        m->expr->type->to<IR::Type_Stack>()->elementType->to<IR::Type_Header>(),
        m->expr, new IR::Constant(index));
}

class RewriteParserStatements : public Transform {
    unsigned                      currentBit = 0;
    bool                          filterSetMetadata;

    const IR::Expression *preorder(IR::Statement *s) override {
        BUG("Unhandled statement kind: %1%", s);
    }

    const IR::Node *preorder(IR::MethodCallStatement *s) override {
        return transform_child(s->methodCall);
    }

    const IR::Vector<IR::Tofino::ParserPrimitive>*
    preorder(IR::MethodCallExpression* e) override {
        auto meth = e->method->to<IR::Member>();
        if (meth == nullptr || meth->member != "extract" || e->arguments->size() != 1) {
            BUG("Unexpected method call in parser: %1%", e);
            return nullptr;
        }

        auto dest = (*e->arguments)[0];
        auto* hdr = dest->to<IR::HeaderRef>();
        BUG_CHECK(hdr != nullptr,
                  "Extracting something other than a header: %1%", dest);
        auto* hdr_type = hdr->type->to<IR::Type_StructLike>();
        BUG_CHECK(hdr_type != nullptr,
                  "Header type isn't a structlike: %1%", hdr_type);

        // Generate an extract operation for each field.
        auto* rv = new IR::Vector<IR::Tofino::ParserPrimitive>;
        for (auto field : hdr_type->fields) {
            if (field->type->is<IR::Type::Varbits>())
                P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");
            IR::Expression* fref = new IR::Member(field->type, hdr, field->name);
            auto width = field->type->width_bits();
            auto extract =
              new IR::Tofino::ExtractBuffer(meth->srcInfo, fref, currentBit, width);
            currentBit += width;
            rv->push_back(extract);
        }

        // On Tofino we can only extract with byte alignment, so if this header
        // isn't aligned, we need to add padding.
        // XXX(seth): We really should catch this error at a higher layer.
        if (currentBit % 8 != 0) {
            ::warning("Header %1% isn't byte-aligned; adding padding", hdr);
            currentBit += 8 - currentBit % 8;
        }

        // Generate an extract operation for the POV bit.
        auto validBit = new IR::Member(IR::Type::Bits::get(1), hdr, "$valid");
        rv->push_back(new IR::Tofino::ExtractConstant(meth->srcInfo, validBit,
                                                      new IR::Constant(1)));
        return rv;
    }

    const IR::Tofino::ParserPrimitive*
    preorder(IR::AssignmentStatement* s) override {
        if (filterSetMetadata) return nullptr;

        if (s->left->type->is<IR::Type::Varbits>())
            P4C_UNIMPLEMENTED("Parser writes to varbits values are not yet supported.");

        // Peel off any Cast expression. This accepts more programs than we can
        // actually implement; some casts can't be performed at parse time.
        auto rhs = s->right;
        if (rhs->is<IR::Cast>())
            rhs = rhs->to<IR::Cast>()->expr;

        if (rhs->is<IR::Constant>())
            return new IR::Tofino::ExtractConstant(s->srcInfo, s->left,
                                                   rhs->to<IR::Constant>());

        if (!canEvaluateInParser(rhs)) {
            ::error("Assignment cannot be supported in the parser: %1%", rhs);
            return new IR::Tofino::UnhandledParserPrimitive(s->srcInfo, s);
        }

        return new IR::Tofino::ExtractComputed(s->srcInfo, s->left, rhs);
    }

    bool canEvaluateInParser(const IR::Expression* expression) const {
        // We can't evaluate complex expressions on current hardware.
        return expression->is<IR::Constant>() ||
               expression->is<IR::PathExpression>() ||
               expression->is<IR::Member>() ||
               expression->is<IR::HeaderStackItemRef>() ||
               expression->is<IR::ArrayIndex>();
    }

 public:
    explicit RewriteParserStatements(bool filterSetMetadata)
        : filterSetMetadata(filterSetMetadata) { }
};

void GetTofinoParser::addMatch(IR::Tofino::ParserState *s, match_t match_val,
                               const IR::Vector<IR::Tofino::ParserPrimitive> &stmts,
                               const IR::ID &action) {
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

    // Lower calls to "next" and "last" into references to a specific header
    // stack index.
    RewriteExtractNext rewriteExtractNext(ancestorStack);
    auto components = rv->p4state->components.apply(rewriteExtractNext);
    if (rewriteExtractNext.failed) {
        // FIXME should be setting an appropriate parser exception?
        return nullptr;
    }

    // Lower the parser statements from the frontend IR to the Tofino IR.
    RewriteParserStatements rewriteStatements(filterSetMetadata);
    IR::Vector<IR::Tofino::ParserPrimitive> statements;
    for (auto statement : *components) {
        const IR::Node* rewritten = statement->apply(rewriteStatements);
        if (rewritten == nullptr) continue;
        if (rewritten->is<IR::Vector<IR::Tofino::ParserPrimitive>>()) {
            auto v = rewritten->to<IR::Vector<IR::Tofino::ParserPrimitive>>();
            statements.insert(statements.end(), v->begin(), v->end());
            continue;
        }
        BUG_CHECK(rewritten->is<IR::Tofino::ParserPrimitive>(),
                  "Unhandled parser statement: %1%", rewritten);
        statements.push_back(rewritten->to<IR::Tofino::ParserPrimitive>());
    }

    // Lower the select expression to the Tofino IR.
    // XXX(seth): This must happen after we've generated the statements above,
    // because we may select against extracts that happen in this state.
    rv->select = *rv->select.apply(rewriteExtractNext);

    int match_size = 0;
    for (auto s : rv->select)
        match_size += s->type->width_bits();

    LOG2("GetParser::state(" << name << ")");
    if (!rv->p4state->selectExpression) {
    } else if (auto *path = rv->p4state->selectExpression->to<IR::PathExpression>()) {
        addMatch(rv, match_t(), statements, path->path->name);
    } else if (auto *sel = rv->p4state->selectExpression->to<IR::SelectExpression>()) {
        for (auto ce : sel->selectCases)
            addMatch(rv, buildMatch(match_size, ce->keyset), statements,
                     ce->state->path->name);
    } else {
        BUG("Invalid select expression %1%", rv->p4state->selectExpression); }

    return rv;
}

}  // namespace Tofino
