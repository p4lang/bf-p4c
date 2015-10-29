#ifndef _field_defuse_h_
#define _field_defuse_h_

#include "ir/ir.h"
#include "lib/bitvec.h"
#include "lib/ltbitmatrix.h"
#include <iostream>

class FieldDefUse : public ControlFlowVisitor, Inspector, P4WriteContext {
    vector<cstring>		*field_names;
    map<cstring, int>		*field_index;
    LTBitMatrix			*conflict;
    struct info {
	cstring				name;
	int				id;
	set<const IR::MAU::Table *>	def, use;
    };
    map<cstring, info>		defuse;
    class Init;

    profile_t init_apply(const IR::Node *root) override;
    void access_field(cstring field);
    bool preorder(const IR::FieldRef *f) override;
    bool preorder(const IR::Index *f) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);
public:
    FieldDefUse() : field_names(new vector<cstring>), field_index(new map<cstring, int>),
	conflict(new LTBitMatrix) { visitDagOnce = false; }
};


#endif /* _field_defuse_h_ */
