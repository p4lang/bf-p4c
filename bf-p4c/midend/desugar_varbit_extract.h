#ifndef BF_P4C_MIDEND_DESUGAR_VARBIT_EXTRACT_H_
#define BF_P4C_MIDEND_DESUGAR_VARBIT_EXTRACT_H_

#include "ir/ir.h"
#include "bf-p4c/midend/type_checker.h"
#include "frontends/common/resolveReferences/referenceMap.h"

// Header field may have variable size (varbit), which can be encoded
// by another header field, e.g. IPv4 options length is encoded by ihl
// (see below).
//
// Tofino's parser does not have an ALU and cannot evaluate such complex
// expression. To support extraction of varbit field, we must
// decompose the length expression into a set of constructs that is
// implementable using the parser features, i.e. match and state transition.
//
// To implement this, we enumerate all possible compile time values
// of the length expression, and assign a parser state to each length
// where the varbit field is extracted.
//
//
//     header ipv4_t {
//         bit<4>  version;
//         bit<4>  ihl;
//         bit<8>  diffserv;
//         bit<16> totalLen;
//         bit<16> identification;
//         bit<3>  flags;
//         bit<13> fragOffset;
//         bit<8>  ttl;
//         bit<8>  protocol;
//         bit<16> hdrChecksum;
//         bit<32> srcAddr;
//         bit<32> dstAddr;
//         varbit<320> options;
//     }
//
//     state start {
//         verify(p.ipv4.ihl >= 5, error.NoMatch);
//         b.extract(p.ipv4, (bit<32>)(((bit<16>)p.ipv4.ihl - 5) * 32));
//         transition accept;
//     }
//
//
//  After rewrite:
//
//     state start {
//         b.extract<ipv4_t>(p.ipv4);
//         transition select(p.ipv4.ihl) {
//             4w5 &&& 4w15: parse_options_no_option;
//             4w6 &&& 4w15: parse_options_32b;
//             4w7 &&& 4w15: parse_options_64b;
//             4w8 &&& 4w15: parse_options_96b;
//             4w9 &&& 4w15: parse_options_128b;
//             4w10 &&& 4w15: parse_options_160b;
//             4w11 &&& 4w15: parse_options_192b;
//             4w12 &&& 4w15: parse_options_224b;
//             4w13 &&& 4w15: parse_options_256b;
//             4w14 &&& 4w15: parse_options_288b;
//             4w15 &&& 4w15: parse_options_320b;
//             4w0 &&& 4w15: reject;
//             4w1 &&& 4w15: reject;
//             4w2 &&& 4w15: reject;
//             4w3 &&& 4w15: reject;
//             4w4 &&& 4w15: reject;
//         }
//     }

class CollectVarbitExtract : public Inspector {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    std::map<const IR::ParserState*, const IR::BFN::TnaParser*> state_to_parser;

    std::map<const IR::ParserState*, const IR::Type_Header*> state_to_varbit_header;

    std::map<const IR::ParserState*, const IR::StructField*> state_to_varbit_field;

    std::map<const IR::ParserState*, const IR::Member*> state_to_length_var;

    std::map<const IR::ParserState*,
             std::set<const IR::Expression*>> state_to_verify_exprs;

    std::map<const IR::StructField*,
             std::map<unsigned, const IR::Constant*>> varbit_field_to_compile_time_constants;

    std::map<const IR::StructField*, std::set<unsigned>> varbit_field_to_reject_values;

    std::map<const IR::Type_Header*, const IR::StructField*> header_type_to_varbit_field;

    std::map<const IR::StructField*, const IR::MethodCallExpression*> varbit_field_to_extract_call;

 private:
    bool is_legal_runtime_value(const IR::Expression* verify,
                                const IR::Member* var, unsigned val);

    bool is_legal_runtime_value(const IR::ParserState* state,
                                const IR::Member* var, unsigned val);

    const IR::Constant* evaluate(const IR::Expression* varsize,
                                 const IR::Member* var, unsigned val);

    void enumerate_varbit_field_values(
        const IR::MethodCallExpression* call,
        const IR::ParserState* state,
        const IR::Expression* varsize, const IR::Type_Header* hdr_type);

    bool preorder(const IR::MethodCallExpression*) override;

 public:
    CollectVarbitExtract(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        refMap(refMap), typeMap(typeMap) { }
};

class RewriteVarbitExtract : public Modifier {
    const CollectVarbitExtract& cve;

    std::map<const IR::ParserState*,
             ordered_map<unsigned, const IR::ParserState*>> state_to_branches;

    std::map<const IR::StructField*,
             std::map<unsigned, IR::Type_Header*>> varbit_field_to_header_types;

 private:
    profile_t init_apply(const IR::Node* root) override;

    IR::ParserState*
    create_branch_state(const IR::BFN::TnaParser* parser,
                        const IR::Expression* select,
                        const IR::StructField* varbit_field, unsigned length);

    void create_branches(const IR::ParserState* state, const IR::StructField* varbit_field);

    bool contains_varbit_header(IR::Type_Struct*);

    bool preorder(IR::P4Program*) override;
    bool preorder(IR::Type_Struct*) override;
    bool preorder(IR::Type_Header*) override;
    bool preorder(IR::BFN::TnaParser*) override;
    bool preorder(IR::ParserState*) override;

    bool preorder(IR::MethodCallExpression*) override;
    bool preorder(IR::BlockStatement*) override;

 public:
    explicit RewriteVarbitExtract(const CollectVarbitExtract& cve) : cve(cve) {}
};

class RewriteParserVerify : public Transform {
    const CollectVarbitExtract& cve;

    IR::Node* preorder(IR::MethodCallStatement*) override;

 public:
    explicit RewriteParserVerify(const CollectVarbitExtract& cve) : cve(cve) {}
};

class DesugarVarbitExtract : public PassManager {
 public:
    explicit DesugarVarbitExtract(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        auto collect_varbit_extract = new CollectVarbitExtract(refMap, typeMap);
        auto rewrite_varbit_extract = new RewriteVarbitExtract(*collect_varbit_extract);
        auto rewrite_parser_verify = new RewriteParserVerify(*collect_varbit_extract);

        addPasses({
            collect_varbit_extract,
            rewrite_varbit_extract,
            rewrite_parser_verify,
            new P4::ClearTypeMap(typeMap),
            new BFN::TypeChecking(refMap, typeMap, true),
        });
    }
};

#endif /* BF_P4C_MIDEND_DESUGAR_VARBIT_EXTRACT_H_ */
