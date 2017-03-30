#include "cluster.h"
#include "cluster_phv_container.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// Cluster::Cluster constructor
//
//***********************************************************************************

Cluster::Cluster(PhvInfo &p) : phv_i(p), uses_i(new Uses(phv_i)) {
    for (auto &field : phv_i) {
        dst_map_i[&field] = nullptr;
    }
}

//***********************************************************************************
//
// preorder walk on IR tree to insert field operands in cluster set
//
//***********************************************************************************


bool Cluster::preorder(const IR::Tofino::Pipe *pipe) {
    //
    pipe->apply(*uses_i);

    return true;
}


bool Cluster::preorder(const IR::Member* expression) {
    // class Member : Operation_Unary
    // toString = expr->toString() + "." + member
    //
    // reads manifest as member
    // if fields, they must be allocated to MAU pipe
    // e.g.,
    // table t3_1 {
    //    reads {
    //        m.field_32_33 : exact;
    //        m.field_32_34 : exact;
    // .....Member.....ingress::m.field_32_33
    // .....Member.....ingress::m.field_32_34
    //

    LOG4(".....Member....." << expression->toString());
    auto field = phv_i.field(expression);
    if (field) {
        //
        // x must be allocated to PHV
        // e.g., reads { x :
        // dst_map[x] points to singleton cluster using MAU
        //
        create_dst_map_entry(field);
        //
        // deparser constraint
        // some fields e.g., egress_port (9 bits), egress_spec (9 bits)
        // cannot share container with other fields, they expect cohabit bits = 0
        // should NOT place ing_meta_data.drop bit cohabit with egress_port
        // e.g., ing_metadata.egress_port: H1(0..8)
        //       ing_metadata.drop: H1(15)
        // ing_metadata.drop bit controlled by valid bit in egress_spec
        //
        ordered_set<const char *> egress_deparser_constraint;
        egress_deparser_constraint.insert("egress_port");
        egress_deparser_constraint.insert("egress_spec");
        for (auto &es : egress_deparser_constraint) {
            if (const char *s = strstr(field->name, es)) {
                // restrict to name ending in egress_port, i.e., discard egress_port_id
                if (strlen(s) == strlen(es)) {
                    LOG1(".....Deparser Constraint on field..... " << field->name);
                    field->deparser_no_pack = true;
                }
            }
        }
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Unary* expression) {
    LOG4(".....Unary Operation....." << expression->toString()
        << '(' << expression->expr->toString() << ')');
    auto field = phv_i.field(expression->expr);
    insert_cluster(dst_i, field);
    set_field_range(*(expression->expr));
    LOG4(field);

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression) {
    LOG4(".....Binary Operation....." << expression->toString()
        << '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    auto left = phv_i.field(expression->left);
    auto right = phv_i.field(expression->right);
    insert_cluster(dst_i, left);
    insert_cluster(dst_i, right);
    set_field_range(*(expression->left));
    set_field_range(*(expression->right));
    LOG4(left);
    LOG4(right);

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression) {
    LOG4(".....Ternary Operation....." << expression->toString()
        << '(' << expression->e0->toString()
        << ',' << expression->e1->toString()
        << ',' << expression->e2->toString()
        << ')');
    auto e0 = phv_i.field(expression->e0);
    auto e1 = phv_i.field(expression->e1);
    auto e2 = phv_i.field(expression->e2);
    insert_cluster(dst_i, e0);
    insert_cluster(dst_i, e1);
    insert_cluster(dst_i, e2);
    set_field_range(*(expression->e0));
    set_field_range(*(expression->e1));
    set_field_range(*(expression->e2));
    LOG4(e0);
    LOG4(e1);
    LOG4(e2);

    return true;
}

bool Cluster::preorder(const IR::HeaderRef *hr) {
    LOG4(".....Header Ref.....");
    //
    // parser extract, deparser emit
    // operand can be field or header
    // when header, set_field_range all fields in header
    //
    int header_size = 0;
    for (auto fid : Range(*phv_i.header(hr))) {
        auto field = phv_i.field(fid);
        set_field_range(field);
        LOG4(field);
        header_size += field->size;
    }
    //
    // attempting container contiguous groups
    //
    ordered_map<PhvInfo::Field *, int> ccg;
    PhvInfo::Field *group_accumulator = 0;
    int accumulator_bits = 0;
    for (auto fid : Range(*phv_i.header(hr))) {
        auto field = phv_i.field(fid);
        //
        // accumulate sub-byte fields to group to a byte boundary
        // so that if any field is part of MAU then entire PHV container has no holes
        // fields must be contiguous
        //
        if (!field->ccgf) {
            if (group_accumulator
                || field->size % PHV_Container::PHV_Word::b8) {
                if (!group_accumulator) {
                    group_accumulator = field;
                    accumulator_bits = 0;
                }
                field->ccgf = group_accumulator;
                group_accumulator->ccgf_fields.push_back(field);
                accumulator_bits += field->size;
                if (accumulator_bits
                    % PHV_Container::PHV_Word::b8 == 0) {
                    ccg[group_accumulator] = accumulator_bits;
                    LOG4("+++++PHV_container_contiguous_group....."
                        << accumulator_bits
                        << " "
                        << group_accumulator);
                    group_accumulator = 0;
                }
            }
        }
    }
    if (group_accumulator) {
       ccg[group_accumulator] = accumulator_bits;
       LOG4("+++++PHV_container_contiguous_group....."
           << accumulator_bits
           << " "
           << group_accumulator);
    }
    //
    // discard following container contiguous group widths
    // not byte-multiple (includes < byte)
    // > largest container width,
    //
    for (auto &entry : ccg) {
        auto owner = entry.first;
        auto ccg_width = entry.second;
        if ((ccg_width
            && ccg_width % PHV_Container::PHV_Word::b8)
            || ccg_width > PHV_Container::PHV_Word::b32) {
            for (auto &f : owner->ccgf_fields) {
                f->ccgf = 0;
            }
            owner->ccgf_fields.clear();
            LOG4("-----discarded PHV_container_contiguous_group....."
                << ccg_width
                << " "
                << owner);
        }
    }

    return true;
}

bool Cluster::preorder(const IR::Primitive* primitive) {
    LOG4(".....Primitive:Operation....." << primitive->name);
    dst_i = nullptr;
    if (!primitive->operands.empty()) {
        dst_i = phv_i.field(primitive->operands[0]);
        if (dst_i) {
            //
            // x must be allocated to PHV
            // e.g., action a: - set x, 3
            // dst_map[x] points to singleton cluster using MAU
            //
            create_dst_map_entry(dst_i);
            //
            for (auto &operand : primitive->operands) {
                auto field = phv_i.field(operand);
                insert_cluster(dst_i, field);
                set_field_range(*operand);
                LOG4("...operand... = " << field);
            }
        }
    }

    return true;
}

bool Cluster::preorder(const IR::Operation* operation) {
    // should not reach here
    LOG1("*****cluster.cpp: sanity_FAIL Operation*****" << operation->toString());

    return true;
}

bool Cluster::preorder(const IR::Expression* expression) {
    LOG4(".....Expression.....");
    auto field = phv_i.field(expression);
    if (field) {
        LOG4(field);
    }
    if (field && isWrite()) {
        field->mau_write = true;
        LOG4(".....MAU_write....." << field);
        return false;  // prune children below, e.g., complicated slice expression
    }

    return true;
}

//***********************************************************************************
//
// postorder walk on IR tree
//
//***********************************************************************************

void Cluster::postorder(const IR::Primitive* primitive) {
    if (dst_i) {
        sanity_check_clusters("postorder.."+primitive->name+"..", dst_i);
    }
    dst_i = nullptr;
}

//***********************************************************************************
//
// end of IR walk epilogue
// perform sanity checks
// obtain unique clusters
//
//***********************************************************************************

void Cluster::end_apply() {
    sanity_check_field_range("end_apply..");
    //
    for (auto &entry : dst_map_i) {
        auto lhs = entry.first;
        sanity_check_clusters("end_apply..", lhs);
    }
    //
    // transfer ccgf ownership to field in dst_map_i
    //
    for (auto &f : phv_i) {
        if (dst_map_i.count(&f))  {
            //
            // ccgf accumulations
            // transfer ownership of container to field in cluster
            //
            if (f.ccgf
                && !f.ccgf->header_stack_pov_ccgf  // not header stack pov
                && !f.ccgf_fields.size()
                && !dst_map_i.count(f.ccgf)) {  // current owner not in dst_map
                //
                PhvInfo::Field *current_owner = f.ccgf;
                PhvInfo::Field *new_owner = &f;
                new_owner->ccgf_fields.insert(
                    new_owner->ccgf_fields.begin(),
                    current_owner->ccgf_fields.begin(),
                    current_owner->ccgf_fields.end());
                current_owner->ccgf_fields.clear();  // clear previous owner
                new_owner->ccgf = new_owner;
                for (auto &m : new_owner->ccgf_fields) {
                    m->ccgf = new_owner;
                }
            }
        }
    }
    LOG4(".....After transfer ccgf ownership.....");
    LOG4(dst_map_i);
    for (auto &f : phv_i) {
        if (dst_map_i.count(&f))  {
            //
            // container contiguous group fields
            // cluster(a{a,b},x), cluster(b,y) => cluster(a{a,b},x,y)
            // a->ccgf_fields = {a,b,c}, a->ccgf=a, b->ccgf=a, c->ccgf=a
            // dst_map_i[a]=(a), dst_map_i[b]=(b)
            // (a) += (b); remove dst_map_i[b]
            // b appearing in dst_map_i[y] :-
            //     cluster(a{a,b},x), cluster(y,b) => cluster(a{a,b},x,y)
            //
            if (f.ccgf == &f) {
                for (auto &m : f.ccgf_fields) {
                    if (dst_map_i.count(m)) {
                        insert_cluster(&f, m);
                    }
                }
                // remove ccgf members duplicated as cluster members
                // ccgf owners responsible for member allocation
                // remove duplication as cluster members
                //
                ordered_set<const PhvInfo::Field *> s1 = *(dst_map_i[&f]);
                for (auto &c_e : s1) {
                    for (auto &m : c_e->ccgf_fields) {
                        if (m != c_e && s1.count(m)) {
                            dst_map_i[&f]->erase(m);
                        }
                    }
                }
            }
        }
    }
    LOG4(".....After remove ccgf member duplication.....");
    LOG4(dst_map_i);
    //
    // form unique clusters
    // forall x not elem lhs_unique_i, dst_map_i[x] = 0
    // do not remove singleton clusters as x needs MAU PHV, e.g., set x, 3
    //
    std::list<const PhvInfo::Field *> delete_list;
    for (auto &entry : dst_map_i) {
        auto lhs = entry.first;
        //
        // remove dst_map entry for fields absorbed in other clusters
        // remove singleton clusters (from headers) not used in mau
        //
        if (lhs_unique_i.count(lhs) == 0) {
            dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        } else {
            bool use_mau = uses_i->use[1][lhs->gress][lhs->id];
            if (!use_mau && entry.second) {
                for (auto &f : *(entry.second)) {
                    if (uses_i->use[1][f->gress][f->id]) {
                        use_mau = true;
                        break;
                    } else {
                        if (f->ccgf && f->ccgf == f) {
                            for (auto &m : f->ccgf_fields) {
                                if (uses_i->use[1][m->gress][m->id]) {
                                    use_mau = true;
                                    break;
                                }
                            }  // for
                        }
                        if (use_mau) {
                            break;
                        }
                    }
                }  // for
            }
            if (!use_mau) {
                dst_map_i[lhs] = nullptr;
                delete_list.push_back(lhs);
            }
        }
    }
    for (auto &fp : delete_list) {
        dst_map_i.erase(fp);                                            // erase map key
    }
    LOG4(".....After form unique clusters.....");
    LOG4(".....lhs_unique_i.....");
    LOG4(&lhs_unique_i);
    LOG4(".....dst_map_i.....");
    LOG4(dst_map_i);
    //
    // compute all fields that are not used through the MAU pipeline
    // potential candidates for T-PHV allocation
    //
    compute_fields_no_use_mau();
    //
    sort_fields_remove_non_determinism();
    //
    sanity_check_clusters_unique("end_apply..");
    //
    // output logs
    //
    LOG3(phv_i);                                                        // all Fields
    LOG3(*this);                                                        // all Clusters
    //
}  // end_apply

//
// compute fields that do not use mau pipeine
//

void Cluster::compute_fields_no_use_mau() {
    //
    // clear all computed & exported lists
    //
    pov_fields_i.clear();
    pov_fields_not_in_cluster_i.clear();
    fields_no_use_mau_i.clear();
    //
    std::set<const PhvInfo::Field *> s1;                               // all fields in phv_i
    std::set<const PhvInfo::Field *> s2;                               // cluster fields
    std::set<const PhvInfo::Field *> s3;                               // all fields-cluster fields
                                                                       // s3 = s1 - s2
    std::set<const PhvInfo::Field *> s4;                               // pov fields
    std::set<const PhvInfo::Field *> s5;                               // fields not used in MAU
                                                                       // s5 = s1 - s2 - s4
    pov_fields_i.clear();
    for (auto &field : phv_i) {
        s1.insert(&field);
        //
        // avoid duplicate allocation for povs that are
        // members of owners that represent header_stack_pov_ccgf
        // members of owners that represent simple_header_pov_ccgf
        // these members are part of owner container
        // owners if not part of MAU cluster, should be added to pov_fields
        //
        if (field.pov
           && (!field.ccgf
              || (field.ccgf
              && !field.ccgf->header_stack_pov_ccgf
              && !field.ccgf->simple_header_pov_ccgf))) {
            //
            s4.insert(&field);                                         // pov field
        }
        // pov owners not part of MAU cluster, must be added to pov_fields
        //
        if (field.pov
           && (&field == field.ccgf && !dst_map_i.count(field.ccgf))) {
            //
            s4.insert(&field);                                         // pov field
        }
        //
        // compute ccgf width
        // need PHV container of this width
        //
        field.phv_use_width(field.ccgf == &field);
        //
        // set deparsed_no_holes
        // used in parser / deparser
        //
        if (uses_i->use[0][field.gress][field.id]) {
            field.deparser_no_holes = true;
        }
    }
    pov_fields_i.assign(s4.begin(), s4.end());                         // pov_fields_i
    LOG3(std::endl << "..........All fields (" << s1.size() << ")..........");
    for (auto &entry : dst_map_i) {
        if (entry.second) {
            s2.insert(entry.first);
            for (auto entry_2 : *(entry.second)) {
                s2.insert(entry_2);
                if (entry_2->ccgf_fields.size()) {
                    for (auto &member : entry_2->ccgf_fields) {
                        s2.insert(member);
                    }
                }
            }
        }
    }
    //
    LOG3("..........Cluster fields (" << s2.size() << ")..........");
    LOG3("..........POV fields (" << pov_fields_i.size() << ")..........");
    //
    // s3 = all fields (s1) - cluster fields (s2)
    //
    set_difference(s1.begin(), s1.end(), s2.begin(), s2.end(), std::inserter(s3, s3.end()));
    //
    // s5 = s3 - pov fields (s4)
    //
    fields_no_use_mau_i.clear();
    set_difference(s3.begin(), s3.end(), s4.begin(), s4.end(), std::inserter(s5, s5.end()));
    //
    // pov fields not in cluster
    // pov_mau: pov intersect cluster fields
    // pov_no_mau: set_diff pov, pov_mau
    //
    std::set<const PhvInfo::Field *> pov_mau;
    set_intersection(s4.begin(), s4.end(), s2.begin(), s2.end(),
        std::inserter(pov_mau, pov_mau.end()));
    LOG3("..........POV fields in Cluster (" << pov_mau.size() << ")..........");
    //
    std::set<const PhvInfo::Field *> pov_no_mau;
    set_difference(s4.begin(), s4.end(), pov_mau.begin(), pov_mau.end(),
        std::inserter(pov_no_mau, pov_no_mau.end()));
    LOG3("..........POV fields not in Cluster (" << pov_no_mau.size() << ")..........");
    pov_fields_not_in_cluster_i.assign(pov_no_mau.begin(), pov_no_mau.end());
    //
    // sanity check fields use
    //
    fields_no_use_mau_i.assign(s5.begin(), s5.end());                  // fields_no_use_mau_i
    //
    LOG3("..........Fields avoiding MAU pipe ("
        << fields_no_use_mau_i.size()
        << ")..........");
    //
    sanity_check_fields_use("compute_fields_no_use_mau..", s1, s2, s3, s4, s5);
    //
    // from T_PHV candidates,
    // discard the following
    // metadata & pov
    // members of "container contiguous group"
    // fields not used in ingress or egress
    // set_field_range (entire field deparsed) for T_PHV fields_no_use_mau
    //
    std::set<const PhvInfo::Field *> delete_set;
    for (auto f : fields_no_use_mau_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        bool use_pd = uses_i->use[0][f1->gress][f1->id];  // used in parser / deparser
        //
        // normally f1->metadata in the T_PHV path can be removed
        // but bridge_metadata deparsed must be allocated
        // f1->metadata && !use_pd
        //
        if (!use_pd || f1->pov || (f1->ccgf && f1->ccgf != f1)) {
            //
            delete_set.insert(f);
        } else {
            set_field_range(f1);
        }
    }
    fields_no_use_mau_i.clear();
    set_difference(s5.begin(), s5.end(), delete_set.begin(), delete_set.end(),
        std::back_inserter(fields_no_use_mau_i));
    LOG3("..........T_PHV Fields ("
        << fields_no_use_mau_i.size()
        << ").........." << std::endl);
    //
}  // fields_no_use_mau

void
Cluster::sort_fields_remove_non_determinism() {
    //
    // sort fields by id so that future passes using these lists
    // produce determined output on each run
    // useful for debugging purposes
    // occasionally see intermittent failures that are tough to track down
    // cause of non-determinism:
    // doing things that depend on where garbage collector puts stuff in memory (somewhat random)
    // generally by comparing pointers for order
    // happens whenever iterate over `set` or `map` that uses a pointer type as the key
    // best way to avoid is to use `ordered_set`/`ordered_map` types,
    // which track order of insertion & use that as iteration order.
    // sometimes, can't avoid, need additional support functions in ordered_set
    // e.g.,
    // set_intersection, set_difference, insert ordered_set in (ordered_set of ordered_sets)
    //
    // sort exported list fields by id
    //
    pov_fields_i.sort(
        [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    pov_fields_not_in_cluster_i.sort(
        [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    fields_no_use_mau_i.sort(
        [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
}  // sort_fields_remove_non_determinism

//***********************************************************************************
//
// create dst map entry
// create a dst_map_i entry for field
// insert in lhs_unique_i
// insert_cluster
//
//***********************************************************************************

void Cluster::create_dst_map_entry(PhvInfo::Field *field) {
    assert(field);
    if (!dst_map_i[field]) {
        dst_map_i[field] = new ordered_set<const PhvInfo::Field *>;  // new set
        lhs_unique_i.insert(field);  // lhs_unique set insert field
        LOG5("lhs_unique..insert[" << std::endl << &lhs_unique_i << "lhs_unique..insert]");
        insert_cluster(field, field);
        set_field_range(field);
        LOG4(field);
    }
}

//***********************************************************************************
//
// set field range
// updates range of field slice used in computations / travel through MAU pipeline / phv
//
//***********************************************************************************

void Cluster::set_field_range(const IR::Expression& expression) {
    PhvInfo::Field::bitrange bits;
    bits.lo = bits.hi = 0;
    auto field = phv_i.field(&expression, &bits);
    if (field) {
        field->phv_use_lo = std::min(field->phv_use_lo, bits.lo);
        if (field->metadata || field->pov) {
            field->phv_use_hi = std::max(field->phv_use_hi, bits.hi);
        } else {
            set_field_range(field);
        }
    }
}

void Cluster::set_field_range(PhvInfo::Field *field, int container_width) {
    if (field) {
        field->phv_use_lo = 0;
        if (field->ccgf != field) {
            field->phv_use_hi = field->phv_use_lo + std::max(field->size, container_width) - 1;
        }
    }
}

//***********************************************************************************
//
// insert field in cluster
//
// map[a]--> cluster(a,x) + insert b
// if b == a
//     [a]-->(a,x)
// if [b]--> ==  [a]-->
//     do nothing
// if [b]-->nullptr, b not member of ccgf[f], f element of [a]
//                            avoid duplicate b, f.b in cluster as f phv-allocates for its ccgf
//     (a,x) = (a,x) U b
//     [a],[b]-->(a,x,b)
// if [b]-->(b,d,x)
//     [a]-->(a,u,v)U(b,d,x), b,d,x not member of ccgf[f], f element of [a]
//                            avoid duplicates in cluster as f phv-allocates for its ccgf
//     [b(=rhs)] set members --> [a(=lhs)], rhs cluster subsumed by lhs'
//     [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
//     lhs_unique set: -remove(b,d,x)
//     note: [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set: +insert(c)-remove(b,d,x)
//     del (b,d,x) as no map[] key points to (b,d,x)
//
//***********************************************************************************

void Cluster::insert_cluster(const PhvInfo::Field *lhs, const PhvInfo::Field *rhs) {
    if (lhs && dst_map_i[lhs] && rhs) {
        if (rhs == lhs) {   // b == a
            dst_map_i[lhs]->insert(rhs);
        } else {
            if (dst_map_i[rhs] != dst_map_i[lhs]) {   // [b]-->nullptr
                //
                // ccgf owners will phv allocate for members
                // recursively (PHV_Container::taint())
                // avoid duplication
                // e.g.,  owner's cluster as (lhs{lhs->ccgf_fields=(field,...)}, field)
                //
                if (!dst_map_i[rhs]) {
                    if (!is_ccgf_member(lhs, rhs)) {  // ccgf check
                        dst_map_i[lhs]->insert(rhs);
                        dst_map_i[rhs] = dst_map_i[lhs];
                    }
                } else {   // [b]-->(b,d,x)
                    // [a]-->(a,u,v)U(b,d,x)
                    for (auto field : *(dst_map_i[rhs])) {
                        if (!is_ccgf_member(lhs, field)) {  // ccgf check
                            dst_map_i[lhs]->insert(field);
                        }
                    }
                    // [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
                    // lhs_unique set: -remove(b,d,x)
                    for (auto field : *(dst_map_i[rhs])) {
                        dst_map_i[field] = dst_map_i[lhs];
                        lhs_unique_i.erase(field);                   // lhs_unique set erase field
                    }
                }
            }
            LOG4("..... insert_cluster ....." << lhs);
            LOG4(dst_map_i[lhs]);
            LOG5("lhs_unique..erase[" << std::endl << &lhs_unique_i << "lhs_unique..erase]");
        }
    }
}  // insert_cluster


bool
Cluster::is_ccgf_member(const PhvInfo::Field *lhs, const PhvInfo::Field *rhs) {
    // ccgf check: rhs is not a member of f.ccgf, f element of dst_map_i[lhs]
    if (lhs && rhs && dst_map_i[lhs]) {
        for (auto &f : *dst_map_i[lhs]) {
            if (std::find(f->ccgf_fields.begin(), f->ccgf_fields.end(), rhs)
               != f->ccgf_fields.end()) {
               // rhs is member of f.ccgf, f element of lhs.cluster
               LOG4("=====");
               LOG4(rhs);
               LOG4(" member of ccgf of ");
               LOG4(f);
               LOG4("=====");
               //
               return true;
            }
        }  // for
    }
    return false;
}  // is_ccgf_member

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void Cluster::sanity_check_field_range(const std::string& msg) {
    // for all fields in phv_i, check size >= range
    for (auto field : phv_i) {
        int range = field.phv_use_hi - field.phv_use_lo + 1;
        if (range > field.size) {
            LOG1("*****cluster.cpp:sanity_FAIL*****field range > size .." << msg << &field);
        }
    }
}

void Cluster::sanity_check_clusters(const std::string& msg, const PhvInfo::Field *lhs) {
    if (lhs && dst_map_i[lhs]) {
        // b --> (b,d,e); count b=1 in (b,d,e)
        if (dst_map_i[lhs]->count(lhs) != 1) {
            LOG1("*****cluster.cpp:sanity_FAIL*****cluster member count > 1.."
                << msg << lhs << "-->" << dst_map_i[lhs]);
        }
        // forall x elem (b,d,e), x-->(b,d,e)
        for (auto rhs : *(dst_map_i[lhs])) {
            if (dst_map_i[rhs] != dst_map_i[lhs]) {
                LOG1("*****cluster.cpp:sanity_FAIL*****cluster member pointers inconsistent.."
                    << msg << lhs << "-->" << rhs);
            }
        }
    }
}

void Cluster::sanity_check_clusters_unique(const std::string& msg) {
    //
    // sanity check dst_map_i[] contains unique clusters only
    // forall clusters x,y
    //     x intersect y = 0
    //
    // avoid duplicate phv alloc for ccgf members as owner accounts for ccgf phv allocation
    // for m,f member of cluster x, m != f
    //    m not element of f.ccgf
    //    header stack povs: m not member of m.ccgf
    //    sub-byte header fields: m member of m.ccgf
    //
    for (auto entry : dst_map_i) {
        if (entry.first && entry.second) {
            ordered_set<const PhvInfo::Field *> s1 = *(entry.second);
            //
            // ccgf check
            // for x,y member of cluster, x!=y, z element of x.xxgf
            //     z != y
            //
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields) {
                    if (m != f && s1.count(m)) {
                        LOG1("*****cluster.cpp:sanity_FAIL*****" << msg);
                        LOG1("ccgf member duplicated in cluster");
                        LOG1("member =");
                        LOG1(m);
                        LOG1("cluster =");
                        LOG1(&s1);
                    }
                }
            }
            //
            // unique clusters check
            //
            // ccgfs: s1.f.ccgf can intersect s2.f
            // s1 <-- s1 U f.ccgf, f element of s1
            // s2 <-- s2 U f.ccgf, f element of s2
            //
            ordered_set<const PhvInfo::Field *> sx;
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields) {
                    const PhvInfo::Field *mx = (const PhvInfo::Field *) m;
                    if (sx.count(mx)) {
                        LOG1("*****cluster.cpp:sanity_FAIL***** duplicate ccgf member ..." << msg);
                        LOG1(mx);
                    }
                    sx.insert(mx);
                }
            }
            for (auto &f : sx) {
                s1.insert(f);
            }
            //
            for (auto entry_2 : dst_map_i) {
                if (entry_2.first && entry_2.second && entry_2.first != entry.first) {
                    ordered_set<const PhvInfo::Field *> s2 = *(entry_2.second);
                    //
                    // s2 <-- s2 U f.ccgf, f element of s2
                    //
                    ordered_set<const PhvInfo::Field *> sx;
                    for (auto &f : s2) {
                        for (auto &m : f->ccgf_fields) {
                            const PhvInfo::Field *mx = (const PhvInfo::Field *) m;
                            if (sx.count(mx)) {
                                LOG1("*****cluster.cpp:sanity_FAIL***** duplicate ccgf member ....."
                                    << msg);
                                LOG1(mx);
                            }
                            sx.insert(mx);
                        }
                    }
                    for (auto &f : sx) {
                        s2.insert(f);
                    }
                    // std::vector<const PhvInfo::Field *> s3;
                    // s3.clear();
                    // std::set_intersection(s1.begin(), s1.end(), s2.begin(), s2.end(),
                        // std::back_inserter(s3));
                    // if (s3.size()) {
                    for (auto &f : s1) {
                        if (s2.count(f)) {
                            LOG1("*****cluster.cpp:sanity_FAIL***** cluster uniqueness.."
                                << msg);
                            LOG1(&s1);
                            LOG1("/\\");
                            LOG1(&s2);
                            LOG1('=');
                            // LOG1(s3);
                            LOG1("---> " << f << " <---");
                            //
                        }
                    }
                }
            }  // for
        }
    }
}

void Cluster::sanity_check_fields_use(const std::string& msg,
    std::set<const PhvInfo::Field *> all,
    std::set<const PhvInfo::Field *> cluster,
    std::set<const PhvInfo::Field *> all_minus_cluster,
    std::set<const PhvInfo::Field *> pov,
    std::set<const PhvInfo::Field *> no_mau) {
    //
    std::vector<const PhvInfo::Field *> sx;
    //
    // cluster + all_minus_cluster = all
    //
    sx.clear();
    std::set<const PhvInfo::Field *> s1(cluster.begin(), cluster.end());
    s1.insert(all_minus_cluster.begin(), all_minus_cluster.end());
    set_difference(s1.begin(), s1.end(), all.begin(), all.end(), std::back_inserter(sx));
    if (sx.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use cluster+all_minus_cluster != all .."
            << msg << sx);
    }
    //
    // cluster intersection all_minus_cluster = null
    //
    sx.clear();
    set_intersection(cluster.begin(), cluster.end(),
        all_minus_cluster.begin(), all_minus_cluster.end(),
        std::back_inserter(sx));
    if (sx.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use.. cl intersect all_minus_cluster != 0"
            << msg << sx);
    }
    //
    // all = cluster + pov + no_mau + pov_mau
    // pov_mau: pov intersect with cluster
    //
    std::set<const PhvInfo::Field *> pov_mau;  // pov intersect cluster fields
    set_intersection(pov.begin(), pov.end(), cluster.begin(), cluster.end(),
        std::inserter(pov_mau, pov_mau.end()));
    sx.clear();
    s1.clear();
    s1.insert(cluster.begin(), cluster.end());
    s1.insert(pov.begin(), pov.end());
    s1.insert(no_mau.begin(), no_mau.end());
    s1.insert(pov_mau.begin(), pov_mau.end());
    set_difference(s1.begin(), s1.end(), all.begin(), all.end(), std::back_inserter(sx));
    if (sx.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use all != cluster+pov+no_mau+pov_mau .."
            << msg << sx);
    }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// cluster output
//

std::ostream &operator<<(std::ostream &out, ordered_set<const PhvInfo::Field *>* p_cluster_set) {
    if (p_cluster_set) {
        out << "cluster<#=" << p_cluster_set->size() << ">(" << std::endl;
        int n = 1;
        for (auto &field : *p_cluster_set) {
            out << "<#" << n++ << ">\t" << field << std::endl;
        }
        out << ')' << std::endl;
    } else {
        out << "cluster = ()" << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<const PhvInfo::Field *>& cluster_vec) {
    for (auto &field : cluster_vec) {
        out << field << std::endl;
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>*>& dst_map) {
    // iterate through all elements in dst_map
    for (auto &entry : dst_map) {
        if (entry.second) {
            out << entry.first << " -->" << std::endl;
            out << entry.second;
        }
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster) {
    out << "++++++++++ Clusters (" << cluster.dst_map().size() << ") ++++++++++"
        << std::endl
        << std::endl;
    // clusters
    out << cluster.dst_map();
    //
    // output pov fields
    out << std::endl;
    out << ".......... POV Fields (" << cluster.pov_fields().size() << ") ........."
        << std::endl
        << std::endl;
    out << cluster.pov_fields();
    out << std::endl;
    //
    // output fields_no_use_mau
    out << ".......... T_PHV Fields ("
        << cluster.fields_no_use_mau().size() << ") ........."
        << std::endl
        << std::endl;
    out << cluster.fields_no_use_mau();
    return out;
}
