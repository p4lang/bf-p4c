#ifndef _tofino_ir_h_
#define _tofino_ir_h_
#include <ostream>
enum gress_t { INGRESS, EGRESS };

inline std::ostream &operator<<(std::ostream &out, gress_t gress) {
    return out << (gress ? "egress" : "ingress"); }

#include "parde.h"
#include "mau.h"

namespace IR {

class Tofino_Pipe : public Node {
public:
    struct thread_t {
	const Tofino_Parser	*parser;
	const MAU_TableSeq	*mau;
	const Tofino_Deparser	*deparser;
	bool operator==(const thread_t &a) const {
	    return parser == a.parser && mau == a.mau && deparser == a.deparser; }
    } thread[2] = { { nullptr, nullptr, nullptr } };  // INGRESS and EGRESS
    IRNODE_SUBCLASS(Tofino_Pipe)
    IRNODE_DEFINE_APPLY_OVERLOAD(Tofino_Pipe)
    bool operator==(const Tofino_Pipe &a) const {
	return thread[0] == a.thread[0] && thread[1] == a.thread[1]; }
    IRNODE_VISIT_CHILDREN({
	for (auto &th : thread) {
	    v.visit(th.parser);
	    v.visit(th.mau);
	    v.visit(th.deparser); } })
    void dbprint(std::ostream &out) const override;
};

namespace Tofino {
using Pipe = Tofino_Pipe;
} // end namespace Tofino

} // end namespace IR

#endif /* _tofino_ir_h_ */
