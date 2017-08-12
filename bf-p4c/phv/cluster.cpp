#include "cluster.h"
#include "cluster_phv_container.h"
#include "lib/log.h"
#include "lib/stringref.h"

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
    // attempting container contiguous groups
    //
    ordered_map<PhvInfo::Field *, int> ccgf;
    PhvInfo::Field *group_accumulator = 0;
    int accumulator_bits = 0;
    for (auto fid : phv_i.struct_info(hr).field_ids()) {
        auto field = phv_i.field(fid);
        if (!uses_i->is_referenced(field)) {
            //
            // disregard unreferenced fields before ccgf accumulation
            //
            continue;
        }
        set_field_range(field);
        LOG4(field);

        // accumulate sub-byte fields to group to a byte boundary
        // fields must be contiguous
        // aggregating beyond byte boundary can cause problems
        // e.g.,
        //   {extra$0.x1: W0(0..23), extra$0.more: B1}
        //      => 5 bytes  -- deparser problem
        //   {extra$0.x1: W0(8..31), extra$0.more: W0(0..7)}
        //      => 4 bytes -- ok
        //   {extra$0.x1.16-23: B2,extra$0.x1.8-15: B1,extra$0.x1.0-7: B0,extra$0.more: B49}
        //      => 4B
        if (!field->ccgf()) {
            bool byte_multiple = field->size % PHV_Container::PHV_Word::b8 == 0;
            if (group_accumulator || !byte_multiple) {
                if (!group_accumulator) {
                    group_accumulator = field;
                    accumulator_bits = 0;
                }
                field->set_ccgf(group_accumulator);
                group_accumulator->ccgf_fields().push_back(field);
                accumulator_bits += field->size;
                if (PHV_Container::exact_container(accumulator_bits)) {
                    ccgf[group_accumulator] = accumulator_bits;
                    LOG4("+++++PHV_container_contiguous_group....."
                        << accumulator_bits);
                    LOG4(group_accumulator);
                    group_accumulator = 0; } } } }
    if (group_accumulator) {
       ccgf[group_accumulator] = accumulator_bits;
       LOG4("+++++PHV_container_contiguous_group....."
           << accumulator_bits);
       LOG4(group_accumulator); }
    // discard container contiguous groups with:
    // - only one member
    // - widths that are larger than one byte but not byte-multiples
    // - widths that are larger than the contiguity limit/run-length that phv
    //   allocation supports
    // - parser has 4x8b, 4x16b, and 4x32b extractors, all can be written to PHV per parse state
    // - extensive metadata aggregation causes ccgf cluster bloat & pressure on phv allocation
    for (auto &entry : ccgf) {
        auto owner = entry.first;
        auto ccgf_width = entry.second;
        assert(ccgf_width > 0);
        //
        bool single_member = owner->ccgf_fields().size() == 1;
        bool sub_byte = ccgf_width < PHV_Container::PHV_Word::b8;
        bool byte_multiple = ccgf_width % PHV_Container::PHV_Word::b8 == 0;
        auto contiguity_limit = owner->metadata?
                                CCGF_contiguity_limit::Metadata * PHV_Container::PHV_Word::b8:
                                CCGF_contiguity_limit::Parser_Extract * PHV_Container::PHV_Word::b8;
        //
        bool discard = false;
        if (single_member) {
            LOG1("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "single member");
            discard = true;
        }
        if (!sub_byte && !byte_multiple) {
            LOG1("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "not byte_multiple");
            discard = true;
        }
        if (ccgf_width > contiguity_limit) {
            LOG1("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "ccgf_width=" << ccgf_width
                << " > contiguity_limit=" << contiguity_limit);
            discard = true;
        }
        if (discard) {
            for (auto &f : owner->ccgf_fields()) {
                f->set_ccgf(0);
            }
            owner->ccgf_fields().clear();
            //
            LOG1(owner);
            WARNING("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarded PHV_container_contiguous_group.....\n"
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
            LOG4("...dst... = " << dst_i);
            auto gress = dst_i->gress;
            for (auto &operand : primitive->operands) {
                auto field = phv_i.field(operand);
                if (field) {
                    insert_cluster(dst_i, field);
                    set_field_range(*operand);
                    LOG4("...operand... = " << field);
                    BUG_CHECK(gress == field->gress,
                        "***** cluster.cpp: Operation ..... mixed gress !*****\n%d:%s,%s\n%d:%s,%s",
                        dst_i->id, dst_i->name, (dst_i->gress ? " E" : " I"),
                        field->id, field->name, (field->gress ? " E" : " I"));
                }
            }
        }
    }

    return true;
}

bool Cluster::preorder(const IR::Operation* operation) {
    // should not reach here
    LOG1("*****cluster.cpp: sanity_FAIL Operation*****" << operation->toString());
    BUG("*****cluster.cpp: should not invoke preorder(IR::Operation*)*****%s",
        operation->toString());

    return true;
}

// TODO: Perhaps separate different analyses into different passes.  Eg. set
// mau_write elsewhere, since it doesn't have to do with clustering?
bool Cluster::preorder(const IR::Expression* expression) {
    LOG4(".....Expression.....");
    auto field = phv_i.field(expression);
    if (field) {
        LOG4(field);
    }
    if (field && isWrite()) {
        field->set_mau_write(true);
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
    // ccgf owner field must be in dst_map_i
    //
    for (auto &f : phv_i) {
        if (dst_map_i.count(&f))  {
            if (f.ccgf()
                && !f.ccgf()->header_stack_pov_ccgf()  // not header stack pov
                && !f.ccgf_fields().size()
                && !dst_map_i.count(f.ccgf())) {  // current owner not in dst_map
                //
                create_dst_map_entry(f.ccgf());
                insert_cluster(f.ccgf(), &f);
            }
        }
    }
    LOG4(".....After ccgf owner in dst_map_i.....");
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
            if (f.is_ccgf()) {
                for (auto &m : f.ccgf_fields()) {
                    if (dst_map_i.count(m)) {
                        insert_cluster(&f, m);
                    }
                }
                // remove ccgf members duplicated as cluster members
                // ccgf owners responsible for member allocation
                // remove duplication as cluster members
                //
                ordered_set<PhvInfo::Field *> s1 = *(dst_map_i[&f]);
                for (auto &c_e : s1) {
                    for (auto &m : c_e->ccgf_fields()) {
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
    std::list<PhvInfo::Field *> delete_list;
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
            // set_metadata lhs, ....
            // lhs should not be removed from dst_map_i as mau operation needed
            // parde (e.g., "extract", "emit") operands not used_mau should be removed from dst_map
            //
            bool need_mau = uses_i->is_used_mau(lhs);
            if (!need_mau && entry.second) {
                for (auto &f : *(entry.second)) {
                    if (uses_i->is_used_mau(f)) {
                        need_mau = true;
                        break;
                    } else {
                        if (f->is_ccgf()) {
                            for (auto &m : f->ccgf_fields()) {
                                if (uses_i->is_used_mau(m)) {
                                    need_mau = true;
                                    break;
                                }
                            }  // for
                        }
                        if (need_mau) {
                            break;
                        }
                    }
                }  // for
            }
            if (!need_mau) {
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
    set_deparsed_flag();
    //
    deparser_ccgf_phv();
    //
    // compute all fields that are not used through the MAU pipeline
    // potential candidates for T-PHV allocation
    //
    compute_fields_no_use_mau();
    //
    deparser_ccgf_t_phv();
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
// set deparsed flag on fields
//

void Cluster::set_deparsed_flag() {
    //
    for (auto &f : phv_i) {
        //
        // set field's deparsed if used in deparser
        //
        if (uses_i->is_deparsed(&f) && !(f.metadata && !f.bridged) && !f.pov) {
            //
            f.set_deparsed(true);
        }
    }
}  // set_deparsed_flag

//
// deparser ccgf accumulation
//

void Cluster::deparser_ccgf_phv() {
    //
    // scan through dst_map_i => phv related fields as t_phv fields will not be in clusters
    //
    ordered_map<gress_t, std::list<PhvInfo::Field *>> ccgf;
    ordered_map<gress_t, int> ccgf_width;
    for (auto &entry : dst_map_i) {
        PhvInfo::Field *f = entry.first;
        ordered_set<PhvInfo::Field *> *s = entry.second;
        if (s->size() == 1
            && !f->metadata && !f->pov && !f->is_ccgf() && f->size < PHV_Container::PHV_Word::b8) {
            //
            ccgf[f->gress].push_back(f);
            ccgf_width[f->gress] += f->size;
        }
    }
    auto contiguity_limit = CCGF_contiguity_limit::Parser_Extract * PHV_Container::PHV_Word::b8;
    for (auto &entry : ccgf) {
        std::list<PhvInfo::Field *> member_list = entry.second;
        PhvInfo::Field *owner = member_list.front();
        if (ccgf_width[entry.first] > contiguity_limit) {
            LOG1("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----deparser_ccgf_phv....."
                << "ccgf_width=" << ccgf_width[entry.first]
                << " > contiguity_limit=" << contiguity_limit);
            LOG1(owner);
            continue;
        }
        if (member_list.size() > 1) {
            for (auto &f : member_list) {
                //
                f->set_ccgf(owner);
                owner->ccgf_fields().push_back(f);
                //
                dst_map_i.erase(f);
            }
            dst_map_i[owner] = new ordered_set<PhvInfo::Field *>;  // new set
            dst_map_i[owner]->insert(owner);
            LOG3("..........deparser_ccgf_phv..........");
            LOG3(owner);
        }
    }
}  // deparser_ccgf_phv

void Cluster::deparser_ccgf_t_phv() {
    //
    // scan through fields_no_use_mau_i => t_phv fields
    //
    ordered_map<gress_t, std::list<PhvInfo::Field *>> ccgf;
    ordered_map<gress_t, int> ccgf_width;
    for (auto &f : fields_no_use_mau_i) {
        if (!f->metadata && !f->pov && !f->is_ccgf() && f->size < PHV_Container::PHV_Word::b8) {
            //
            ccgf[f->gress].push_back(f);
            ccgf_width[f->gress] += f->size;
        }
    }
    auto contiguity_limit = CCGF_contiguity_limit::Parser_Extract * PHV_Container::PHV_Word::b8;
    for (auto &entry : ccgf) {
        std::list<PhvInfo::Field *> member_list = entry.second;
        PhvInfo::Field *owner = member_list.front();
        if (ccgf_width[entry.first] > contiguity_limit) {
            LOG1("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----deparser_ccgf_t_phv....."
                << "ccgf_width=" << ccgf_width[entry.first]
                << " > contiguity_limit=" << contiguity_limit);
            LOG1(owner);
            continue;
        }
        if (member_list.size() > 1) {
            for (auto &f : member_list) {
                //
                f->set_ccgf(owner);
                owner->ccgf_fields().push_back(f);
                //
                fields_no_use_mau_i.remove(f);
            }
            fields_no_use_mau_i.push_back(owner);
            LOG3("..........deparser_ccgf_t_phv..........");
            LOG3(owner);
        }
    }
}  // deparser_ccgf_t_phv

//
// compute fields that do not use mau pipeine, no MAU reads or writes
// these fields do not participate as operands in MAU instructions
// they can be placed in T_PHV, by-passing MAU
//

void Cluster::compute_fields_no_use_mau() {
    //
    // clear all computed & exported lists
    //
    pov_fields_i.clear();
    pov_fields_not_in_cluster_i.clear();
    fields_no_use_mau_i.clear();
    //
    ordered_set<PhvInfo::Field *> all_fields;                          // all fields in phv_i
    ordered_set<PhvInfo::Field *> cluster_fields;                      // cluster fields
    ordered_set<PhvInfo::Field *> all_minus_cluster;                   // all - cluster fields
    ordered_set<PhvInfo::Field *> pov_fields;                          // pov fields
    ordered_set<PhvInfo::Field *> not_used_mau;                        // fields not used in MAU
                                                                       // all - cluster - pov_fields
    //
    // preprocess fields before accumulation
    //
    for (auto &field : phv_i) {
        if (field.simple_header_pov_ccgf() && !uses_i->is_referenced(&field)) {
            //
            // if singleton member, grouping of pov bits not required
            // else appoint new owner of group
            //
            std::vector<PhvInfo::Field *> members;
            for (auto &m : field.ccgf_fields()) {
                if (uses_i->is_referenced(m)) {
                    members.push_back(m);
                }
                m->set_ccgf(0);
            }
            if (members.size() > 1) {
                PhvInfo::Field *owner = members.front();
                owner->set_simple_header_pov_ccgf(true);
                for (auto &m : members) {
                    m->set_ccgf(owner);
                    owner->ccgf_fields().push_back(m);
                }
            }
            field.set_simple_header_pov_ccgf(false);
            field.set_ccgf(0);
            field.ccgf_fields().clear();
        }
    }  // for all fields
    //
    // accumulation
    //
    for (auto &field : phv_i) {
        if (!uses_i->is_referenced(&field)) {
            //
            // disregard unreferenced fields before all_fields accumulation
            //
            continue;
        }
        all_fields.insert(&field);
        //
        // avoid duplicate allocation for povs that are
        // members of owners that represent header_stack_pov_ccgf
        // members of owners that represent simple_header_pov_ccgf
        // these members are part of owner container
        // owners if not part of MAU cluster, should be added to pov_fields
        //
        if (field.pov
           && (!field.ccgf()
              || (field.ccgf()
              && !field.ccgf()->header_stack_pov_ccgf()
              && !field.ccgf()->simple_header_pov_ccgf()))) {
            //
            pov_fields.insert(&field);                                 // pov field
        }
        // pov owners not part of MAU cluster, must be added to pov_fields
        //
        if (field.pov
           && (&field == field.ccgf() && !dst_map_i.count(field.ccgf()))) {
            //
            pov_fields.insert(&field);                                 // pov field
        }
        // compute width required for ccgf owner (responsible for its members)
        // need PHV container(s) space for ccgf_width
        //
        if (field.is_ccgf()) {
            field.set_ccgf_phv_use_width();
        }
        //
        // set deparsed for ccgf owner
        // if any member used in deparser, ccgf must be in exact containers
        //
        if (field.ccgf()) {
            for (auto &m : field.ccgf_fields()) {
                if (m->deparsed()) {
                    field.set_deparsed(true);
                    break;
                }
            }
        }
    }  // for all fields
    pov_fields_i.assign(pov_fields.begin(), pov_fields.end());         // pov_fields_i
    LOG3(std::endl << "..........All fields (" << all_fields.size() << ")..........");
    for (auto &entry : dst_map_i) {
        if (entry.second) {
            cluster_fields.insert(entry.first);
            for (auto entry_2 : *(entry.second)) {
                cluster_fields.insert(entry_2);
                if (entry_2->ccgf_fields().size()) {
                    for (auto &member : entry_2->ccgf_fields()) {
                        cluster_fields.insert(member);
                    }
                }
            }
        }
    }
    //
    LOG3("..........Cluster fields (" << cluster_fields.size() << ")..........");
    LOG3("..........POV fields (" << pov_fields_i.size() << ")..........");
    //
    // all_minus_cluster = all_fields - cluster_fields
    //
    all_minus_cluster = all_fields;
    all_minus_cluster -= cluster_fields;
    //
    // not_used_mau = all_minus_cluster - pov_fields
    //
    not_used_mau = all_minus_cluster;
    not_used_mau -= pov_fields;
    //
    // pov_mau = pov intersect cluster fields
    //
    ordered_set<PhvInfo::Field *> pov_mau = pov_fields;
    pov_mau &= cluster_fields;
    LOG3("..........POV fields in Cluster (" << pov_mau.size() << ")..........");
    //
    // pov fields not in cluster
    // pov_no_mau = set_diff pov, pov_mau
    //
    ordered_set<PhvInfo::Field *> pov_no_mau = pov_fields;
    pov_no_mau -= pov_mau;
    LOG3("..........POV fields not in Cluster (" << pov_no_mau.size() << ")..........");
    pov_fields_not_in_cluster_i.assign(pov_no_mau.begin(), pov_no_mau.end());
    LOG3("..........Fields avoiding MAU pipe (" << not_used_mau.size() << ")..........");
    //
    sanity_check_fields_use(
        "compute_fields_no_use_mau..",
        all_fields,
        cluster_fields,
        all_minus_cluster,
        pov_fields,
        not_used_mau);
    //
    // from T_PHV candidates,
    // discard the following
    // metadata & pov
    // members of "container contiguous group" (owner accounts, avoid duplicate allocations)
    // fields not used in ingress or egress
    // set_field_range (entire field deparsed) for T_PHV fields_no_use_mau
    //
    ordered_set<PhvInfo::Field *> delete_set;
    for (auto &f : not_used_mau) {
        bool use_pd = uses_i->is_used_parde(f);  // used in parser / deparser
        //
        // metadata in T_PHV can be removed but bridge_metadata deparsed must be allocated
        //
        if (!use_pd
            || f->pov
            || (f->metadata && !f->bridged && !f->referenced)
            || (f->ccgf() && f->ccgf() != f)) {
            //
            delete_set.insert(f);
        } else {
            set_field_range(f);
        }
    }
    // s_diff = not_used_mau - delete_set
    ordered_set<PhvInfo::Field *> s_diff = not_used_mau;
    s_diff -= delete_set;
    fields_no_use_mau_i.assign(s_diff.begin(), s_diff.end());  // fields_no_use_mau_i
    LOG3("..........T_PHV Fields ("
        << fields_no_use_mau_i.size()
        << ").........."
        << std::endl);
    //
}  // compute_fields_no_use_mau

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
    // set_intersection (&=), set_difference (-=),
    // insert ordered_set in (ordered_set of ordered_sets)
    //
    // sort exported list fields by id
    //
    pov_fields_i.sort(
        [](PhvInfo::Field *l, PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    pov_fields_not_in_cluster_i.sort(
        [](PhvInfo::Field *l, PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    fields_no_use_mau_i.sort(
        [](PhvInfo::Field *l, PhvInfo::Field *r) {
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
        dst_map_i[field] = new ordered_set<PhvInfo::Field *>;  // new set
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
    bitrange bits;
    bits.lo = bits.hi = 0;
    auto field = phv_i.field(&expression, &bits);
    if (field) {
        // set range based on expression bit-slice use
        field->set_phv_use_lo(std::min(field->phv_use_lo(), bits.lo));
        if (field->metadata || field->pov) {
            field->set_phv_use_hi(std::max(field->phv_use_hi(), bits.hi));
        } else {
            set_field_range(field);
        }
    }
}

void Cluster::set_field_range(PhvInfo::Field *field, int container_width) {
    if (field) {
        field->set_phv_use_lo(0);
        BUG_CHECK(field->size,
            "***** cluster.cpp: set_field_range ..... field size is 0 *****%d:%s",
            field->id, field->name);
        // set hi considering no-pack constraints
        field->set_phv_use_hi(field->phv_use_lo() + std::max(field->size, container_width) - 1);
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

// barring CCGF, clustering = Union-Find
// Find: determine which subset contains a particular element
// Union: Join two subsets into a single subset
// if rhs is ccgf member, check if rhs ccgf owner in lhs cluster

void Cluster::insert_cluster(PhvInfo::Field *lhs, PhvInfo::Field *rhs) {
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
                    if (!rhs->ccgf() || !is_ccgf_owner_in_cluster(lhs, rhs)) {
                        dst_map_i[lhs]->insert(rhs);
                        dst_map_i[rhs] = dst_map_i[lhs];
                    }
                } else {   // [b]-->(b,d,x)
                    // [a]-->(a,u,v)U(b,d,x)
                    for (auto field : *(dst_map_i[rhs])) {
                        if (!field->ccgf() || !is_ccgf_owner_in_cluster(lhs, field)) {
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


/// @return true if the CCGF owner of @rhs is in the same cluster as @lhs.
bool Cluster::is_ccgf_owner_in_cluster(PhvInfo::Field *lhs, PhvInfo::Field *rhs) {
    //
    // return true if rhs' ccgf owner in cluster
    // i.e., rhs is not a member of f.ccgf_fields, f element of lhs cluster
    // check rhs.ccgf in dst_map_i[lhs]
    //
    return lhs && rhs && rhs->ccgf() && dst_map_i[lhs] && dst_map_i[lhs]->count(rhs->ccgf());
}  // is_ccgf_owner_in_cluster

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void Cluster::sanity_check_field_range(const std::string& msg) {
    // for all fields in phv_i, check size >= range
    for (auto field : phv_i) {
        if (field.phv_use_width() > field.size) {
            if (field.is_ccgf()) {
                if (field.ccgf_width() != field.phv_use_width()) {
                    LOG1("*****cluster.cpp:sanity_WARN*****"
                        << msg << ".....ccgf field phv_use_width(" << field.phv_use_width()
                        << ") != ccgf_width(" << field.ccgf_width() << ")");
                    LOG1(&field);
                }
            } else {
                LOG1("*****cluster.cpp:sanity_FAIL*****"
                    << msg << ".....field phv_use_width(" << field.phv_use_width()
                    << ") > size(" << field.size << ")");
                LOG1(&field);
            }
        }
    }
}

void Cluster::sanity_check_clusters(const std::string& msg, PhvInfo::Field *lhs) {
    if (lhs && dst_map_i[lhs]) {
        // b --> (b,d,e); count b=1 in (b,d,e)
        if (!dst_map_i[lhs]->count(lhs)) {
            // sets contain at most one of any element, sanity check non-zero
            LOG1("*****cluster.cpp:sanity_FAIL*****"
                << msg << ".....cluster member does not exist in dst_map set");
            LOG1(lhs << "-->" << dst_map_i[lhs]);
        }
        // forall x elem (b,d,e), x-->(b,d,e)
        for (auto rhs : *(dst_map_i[lhs])) {
            if (dst_map_i[rhs] != dst_map_i[lhs]) {
                LOG1("*****cluster.cpp:sanity_FAIL*****"
                    << msg << ".....cluster member pointers inconsistent");
                LOG1(lhs << "-->" << rhs);
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
            ordered_set<PhvInfo::Field *> s1 = *(entry.second);
            //
            // ccgf check
            // for x,y member of cluster, x!=y, z element of x.xxgf
            //     z != y
            //
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields()) {
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
            ordered_set<PhvInfo::Field *> sx;
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields()) {
                    PhvInfo::Field *mx = m;
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
                    ordered_set<PhvInfo::Field *> s2 = *(entry_2.second);
                    //
                    // s2 <-- s2 U f.ccgf, f element of s2
                    //
                    ordered_set<PhvInfo::Field *> sx;
                    for (auto &f : s2) {
                        for (auto &m : f->ccgf_fields()) {
                            PhvInfo::Field *mx = m;
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
                    for (auto &f : s1) {
                        if (s2.count(f)) {
                            LOG1("*****cluster.cpp:sanity_FAIL***** cluster uniqueness.."
                                << msg);
                            LOG1(&s1);
                            LOG1("/\\");
                            LOG1(&s2);
                            LOG1('=');
                            LOG1("---> " << f << " <---");
                        }
                    }
                }
            }  // for
        }
    }
}  // sanity_check_clusters_unique

void Cluster::sanity_check_fields_use(const std::string& msg,
    ordered_set<PhvInfo::Field *> all,
    ordered_set<PhvInfo::Field *> cluster,
    ordered_set<PhvInfo::Field *> all_minus_cluster,
    ordered_set<PhvInfo::Field *> pov,
    ordered_set<PhvInfo::Field *> no_mau) {
    //
    ordered_set<PhvInfo::Field *> s_check;
    //
    // all = cluster + all_minus_cluster
    //
    ordered_set<PhvInfo::Field *> s_all = cluster;
    s_all |= all_minus_cluster;
    // s_check = s_all - all
    s_check = s_all;
    s_check -= all;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use.....");
        LOG1("..... cluster+all_minus_cluster != all .....");
        LOG1(msg << s_check);
    }
    //
    // cluster intersection all_minus_cluster = null
    //
    s_check = cluster;
    s_check &= all_minus_cluster;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use.....");
        LOG1("..... cl intersect all_minus_cluster != 0 .....");
        LOG1(msg << s_check);
    }
    //
    // pov_mau = pov intersect with cluster
    //
    ordered_set<PhvInfo::Field *> pov_mau = pov;
    pov_mau &= cluster;
    // all = cluster + pov + no_mau + pov_mau
    s_all = cluster;
    s_all |= pov;
    s_all |= no_mau;
    s_all |= pov_mau;
    // s_check = s_all - all
    s_check = s_all;
    s_check -= all;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use .....");
        LOG1("..... fields_use all != cluster+pov+no_mau+pov_mau .....");
        LOG1(msg << s_check);
    }
}  // sanity_check_fields_use

//***********************************************************************************
//
// Cluster::Uses
//
// preorder walk on IR tree to set use_i, field flags
//
//***********************************************************************************

bool
Cluster::Uses::preorder(const IR::Tofino::Parser *p) {
    in_mau = false;
    in_dep = false;
    thread = p->gress;
    revisit_visited();
    return true;
}

bool
Cluster::Uses::preorder(const IR::Tofino::Deparser *d) {
    thread = d->gress;
    in_mau = true;  // treat egress_port and digests as in mau as they can't go in TPHV
    in_dep = true;
    revisit_visited();
    visit(d->egress_port);
    visit(d->digests, "digests");
    in_mau = false;
    revisit_visited();
    visit(d->emits, "emits");
    // extract deparser constraints from Deparser & Digest IR nodes ref: bf-p4c/ir/parde.def
    // set deparser constaints on field
    if (d->egress_port) {
        // IR::Tofino::Deparser has a field egress_port which points to
        // egress port in the egress pipeline and
        // egress spec in the ingress pipeline
        auto field = phv.field(d->egress_port);
        if (field) {
            field->set_deparsed_no_pack(true);
            LOG1(".....Deparser Constraint 'egress port' on field..... " << field);
        }
    }
    // TODO:
    // IR futures: distinguish each digest as an enumeration: learning, mirror, resubmit
    // as they have differing constraints -- bottom-bits, bridge-metadata mirror packing
    // learning, mirror field list in bottom bits of container, e.g.,
    // 301:ingress::$learning<3:0..2>
    // 590:egress::$mirror<3:0..2> specifies 1 of 8 field lists
    // currently, IR::Tofino::Digest node has a string field to distinguish them by name
    for (auto &entry : Values(d->digests)) {
        if (entry->name != "learning" && entry->name != "mirror") {
            continue;
        }
        auto field = phv.field(entry->select);
        field->set_deparsed_bottom_bits(true);
        LOG1(".....Deparser Constraint "
            << entry->name
            << " 'digest' on field..... "
            << field);
        if (entry->name !=  "mirror") {
            continue;
        }
        // associating a mirror field with its field list
        // used during constraint checks for bridge-metadata phv allocation
        LOG1(".....mirror field lists selected by  " << field->id << ":" << field->name);
        int fl = 0;
        for (auto s : entry->sets) {
            LOG1("\t.....field list....." << fl);
            for (auto m : *s) {
                auto m_f = phv.field(m);
                if (m_f) {
                    m_f->mirror_field_list = {field, fl};
                    LOG1("\t\t" << m_f);
                } else {
                    LOG1("\t\t" << "-f?");
                }
            }
            fl++;
        }
    }
    return false;
}

bool Cluster::Uses::preorder(const IR::MAU::TableSeq *) {
    in_mau = true;
    in_dep = false;
    revisit_visited();
    return true;
}

bool Cluster::Uses::preorder(const IR::HeaderRef *hr) {
    PhvInfo::StructInfo info = phv.struct_info(hr);
    use_i[in_mau][thread].setrange(info.first_field_id, info.size);
    deparser_i[thread].setrange(info.first_field_id, info.size);
    return false;
}

bool Cluster::Uses::preorder(const IR::Expression *e) {
    if (auto info = phv.field(e)) {
        LOG5("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
        use_i[in_mau][thread][info->id] = true;
        LOG5("dep " << info->name << " in " << thread << (in_dep ? " dep" : ""));
        deparser_i[thread][info->id] = in_dep;
        return false;
    }
    return true;
}

//
// Cluster::Uses routines that check use_i[]
//

bool
Cluster::Uses::is_referenced(PhvInfo::Field *f) {      // use in mau or parde
    assert(f);
    if (f->referenced) {
        // SetReferenced pass sets the referenced flag
        return true;
    }
    if (f->bridged) {
        // bridge metadata
        return true;
    }
    return is_used_mau(f) || is_used_parde(f);
}

bool
Cluster::Uses::is_deparsed(PhvInfo::Field *f) {      // use in deparser
    assert(f);
    bool use_deparser = deparser_i[f->gress][f->id];
    return use_deparser;
}

bool
Cluster::Uses::is_used_mau(PhvInfo::Field *f) {      // use in mau
    assert(f);
    bool use_mau = use_i[1][f->gress][f->id];
    return use_mau;
}

bool
Cluster::Uses::is_used_parde(PhvInfo::Field *f) {    // use in parser / deparser
    assert(f);
    bool use_pd = use_i[0][f->gress][f->id];
    return use_pd;
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// cluster output
//

std::ostream &operator<<(std::ostream &out, ordered_set<PhvInfo::Field *>* p_cluster_set) {
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

std::ostream &operator<<(std::ostream &out, std::vector<PhvInfo::Field *>& cluster_vec) {
    for (auto &field : cluster_vec) {
        out << field << std::endl;
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PhvInfo::Field *, ordered_set<PhvInfo::Field *>*>& dst_map) {
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

//***********************************************************************************
//
// Notes
//
//***********************************************************************************
//
// Note 1
// $mirror_id is a ‘special’ field.
// it is introduced by the parser shims for parsing mirror packets.
// for PHV allocation it should be treated like any other metadata field, as used in the IR.
// in particular expect `$mirror_id` to often be “unused” and thus not need to be allocated to a PHV
// it is extracted in the parser and used to switch parser states, but that it not actually a “use”
// of PHV allocation, the parser accesses it from the input buffer directly,
// so if no later use in MAU or deparser, the extract to PHV can be left as dead
//
// should have ingress::$mirror_id & egress::$mirror_id for phv allocation
// otherwise assembler complaint "No phv record $mirror_id"
//
// Note 2
// some fields e.g., egress_port (9 bits), egress_spec (9 bits)
// cannot share container with other fields, they expect cohabit bits = 0
// should NOT place ing_meta_data.drop bit cohabit with egress_port
// e.g., ing_metadata.egress_port: H1(0..8)
//       ing_metadata.drop: H1(15)
// ing_metadata.drop bit controlled by valid bit in egress_spec
//
// Note 3
// all digest selectors in Tofino are 3 bits, so rest of the phv is available for other uses
// mirror & resubmit both have shifts, so can use any 3 contiguous bits from any phv
// the deparser's learn_cfg has no shifter, value must be in bottom bits of container
// i.e., learning only looks at those bottom 3 bits
// allow packing after $learning in bottom bits
//
// Note 4
// ref: bf-p4c/ir/parde.def
// IR::Tofino::Deparser has a field egress_port,
// which points to the egress port in the egress pipeline & egress spec in the ingress pipeline
// Each Deparser holds a vector of digests, one of which will be the learning digest if present
//
