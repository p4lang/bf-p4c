#ifndef BF_P4C_MAU_GEN_PRIM_JSON_H_
#define BF_P4C_MAU_GEN_PRIM_JSON_H_

#include "lib/json.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/mau/mau_visitor.h"

namespace PHV {
class Field;
}  // namespace PHV

// Generate Primitive Info for actions before instruction adjustment. Once
// instruction adjustment is applied it merges/splits instructions and we loose
// the initial p4 info on the operands. This info is passed off to the assembler
// to plug into respective actions which is then picked up by the model for
// logging
// Following Primitives are supported:
// - ModifyFieldPrimitive
// - DirectAluPrimitive
// - ExecuteStatefulAluPrimitive
// - DropPrimitive
// - AddHeaderPrimitive
// - RemoveHeaderPrimitive
// - ShiftPrimitive
// - ExecuteMeterPrimitive
class GeneratePrimitiveInfo : public MauInspector {
 private:
    const PhvInfo &phv;
    Util::JsonObject &_primNode;
    Util::JsonArray *_tables = nullptr;
    bool preorder(const IR::MAU::Table *tbl) override;
    void add_primitive(Util::JsonArray *primitives, Util::JsonObject *prim);
    void gen_action_json(const IR::MAU::Action *act, Util::JsonObject *_action);
    Util::JsonObject *add_op_json(Util::JsonObject *prim, const std::string op,
            const std::string type, cstring name);
    void validate_add_op_json(Util::JsonObject *_primitive, const std::string
            op_name, const IR::Expression *exp);
    Util::JsonObject *add_stful_op_json(Util::JsonObject *prim, const
            std::string op, const std::string op_pfx, const std::string type,
            cstring name);
    void add_hash_dist_json(Util::JsonObject *_primitive, const std::string
            prim_name, const std::string dst_type, const cstring dst_name,
            const IR::Expression *dst, const IR::MAU::HashDist *hd);
    Visitor::profile_t init_apply(const IR::Node *root) override;
    void end_apply() override;

 public:
    explicit GeneratePrimitiveInfo(const PhvInfo &p, Util::JsonObject &primNode)
        : phv(p), _primNode(primNode) {
        visitDagOnce = false;
        _tables = new Util::JsonArray();
    }
};

#endif /* BF_P4C_MAU_GEN_PRIM_JSON_H_ */
