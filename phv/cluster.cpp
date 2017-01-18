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
        if (!dst_map_i[field]) {
            dst_map_i[field] = new ordered_set<const PhvInfo::Field *>;  // new set
            lhs_unique_i.insert(field);  // lhs_unique set insert field
            LOG4("lhs_unique..insert[" << std::endl << &lhs_unique_i << "lhs_unique..insert]");
            //
            // x must be allocated to PHV
            // e.g., reads { x :
            // dst_map[x] points to singleton cluster using MAU
            //
            insert_cluster(field, field);
            set_field_range(field);
            LOG4(field);
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
                || field->size % static_cast<int>(PHV_Container::PHV_Word::b8)) {
                if (!group_accumulator) {
                    group_accumulator = field;
                    accumulator_bits = 0;
                }
                field->ccgf = group_accumulator;
                group_accumulator->ccgf_fields.push_back(field);
                accumulator_bits += field->size;
                if (accumulator_bits
                    % static_cast<int>(PHV_Container::PHV_Word::b8) == 0) {
                    ccg[group_accumulator] = accumulator_bits;
                    LOG4("+++++PHV_container_contiguous_group..."
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
       LOG4("+++++PHV_container_contiguous_group..."
           << accumulator_bits
           << " "
           << group_accumulator);
    }
    //
    // discard following container contiguous group widths
    // < byte,
    // > largest container width,
    // not byte-multiple
    //
    for (auto &entry : ccg) {
        auto owner = entry.first;
        auto ccg_width = entry.second;
        if ((ccg_width
            && ccg_width % static_cast<int>(PHV_Container::PHV_Word::b8))
            || ccg_width > static_cast<int>(PHV_Container::PHV_Word::b32)) {
            for (auto &f : owner->ccgf_fields) {
                f->ccgf = 0;
            }
            owner->ccgf_fields.clear();
            LOG4("-----PHV_container_contiguous_group..."
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
            if (!dst_map_i[dst_i]) {
                dst_map_i[dst_i] = new ordered_set<const PhvInfo::Field *>;  // new set
                lhs_unique_i.insert(dst_i);  // lhs_unique set insert field
                LOG4("lhs_unique..insert[" << std::endl << &lhs_unique_i << "lhs_unique..insert]");
                 //
                 // x must be allocated to PHV
                 // e.g., action a: - set x, 3
                 // dst_map[x] points to singleton cluster using MAU
                 //
                insert_cluster(dst_i, dst_i);
            }
            for (auto &operand : primitive->operands) {
                auto field = phv_i.field(operand);
                insert_cluster(dst_i, field);
                set_field_range(*operand);
                LOG4(field);
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
    LOG4(".....Expression....." << expression);
    auto field = phv_i.field(expression);
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
    // form unique clusters
    // forall x not elem lhs_unique_i, dst_map_i[x] = 0
    // do not remove singleton clusters as x needs MAU PHV, e.g., set x, 3
    // forall x, dst_map_i[x] == (x), dst_map_i[x] = 0
    //
    std::list<const PhvInfo::Field *> delete_list;
    for (auto &entry : dst_map_i) {
        auto lhs = entry.first;
        // remove dst_map entry for fields absorbed in other clusters
        // remove singleton clusters (from headers) not used in mau
        if (lhs && (lhs_unique_i.count(lhs) == 0 || !uses_i->use[1][lhs->gress][lhs->id])) {
            dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        }
    }
    for (auto &fp : delete_list) {
        dst_map_i.erase(fp);                                            // erase map key
    }
    sanity_check_clusters_unique("end_apply..");
    //
    // compute all fields that are not used through the MAU pipeline
    // potential candidates for T-PHV allocation
    //
    compute_fields_no_use_mau();
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
    // set1 = all fields in phv
    // set2 = cluster fields
    // fields not used in mau pipe = set1 - set2 - POV fields
    //
    std::set<const PhvInfo::Field *> s1;                                // all fields
    pov_fields_i.clear();
    for (auto &field : phv_i) {
        s1.insert(&field);
        //
        // discard povs that are members of header stack containing a .$push
        // these members are part of header stk pov container
        //
        if (field.pov && !field.ccgf) {
            pov_fields_i.push_back(&field);
        }
        if (field.ccgf_fields.size()) {
            int ccg_width = 0;
            for (auto &f : field.ccgf_fields) {
                ccg_width += f->size;
            }
            // ignore non byte-multiples for contiguous container groups only
            // header stack povs should remain in tact
            //
            if (field.ccgf == &field) {
                if (ccg_width && ccg_width %
                    static_cast<int>(PHV_Container::PHV_Word::b8) == 0) {
                    field.phv_use_hi = ccg_width - 1;
                } else {
                    for (auto &f : field.ccgf_fields) {
                        f->ccgf = 0;
                    }
                    field.ccgf_fields.clear();
                }
            }
        }
    }
    LOG3(std::endl << "..........All fields (" << s1.size() << ")..........");
    std::set<const PhvInfo::Field *> s2;                               // cluster fields
    for (auto entry : dst_map_i) {
        if (entry.second) {
            PhvInfo::Field *field = const_cast<PhvInfo::Field *>(entry.first);
            //
            // sub-byte container contiguous-group accumulations
            // move ownership of container to field
            //
            if (field->ccgf && !field->ccgf_fields.size()) {
                PhvInfo::Field *owner = field->ccgf;
                //
                // compute container contiguous group width
                // need PHV container of this width
                //
                field->ccgf_fields.insert(
                    field->ccgf_fields.begin(),
                    owner->ccgf_fields.begin(),
                    owner->ccgf_fields.end());
                owner->ccgf_fields.clear();  // clear previous owner
                field->phv_use_hi = owner->phv_use_hi;
                owner->phv_use_hi = owner->size - 1;
                field->ccgf = field;
            }
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
    std::set<const PhvInfo::Field *> s3;                               // all - cluster fields
    set_difference(s1.begin(), s1.end(), s2.begin(), s2.end(), std::inserter(s3, s3.end()));
    //
    // s3 - pov fields
    //
    fields_no_use_mau_i.clear();
    std::set<const PhvInfo::Field *> s4(pov_fields_i.begin(), pov_fields_i.end());
    set_difference(s3.begin(), s3.end(), s4.begin(), s4.end(),
        std::back_inserter(fields_no_use_mau_i));
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
    std::set<const PhvInfo::Field *> s5(fields_no_use_mau_i.begin(), fields_no_use_mau_i.end());
    sanity_check_fields_use("compute_fields_no_use_mau..", s1, s2, s3, s4, s5);
    //
    LOG3("..........Fields avoiding MAU pipe ("
        << fields_no_use_mau_i.size()
        << ")..........");
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
        bool use_any = uses_i->use[0][f1->gress][f1->id];
        if (f1->metadata || f1->pov || !use_any || (f1->ccgf && f1->ccgf != f1)) {
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
            field->phv_use_hi = field->phv_use_lo + field->size - 1;
        }
    }
}

void Cluster::set_field_range(PhvInfo::Field *field) {
    if (field) {
        field->phv_use_lo = 0;
        if (field->ccgf != field) {
            field->phv_use_hi = field->phv_use_lo + field->size - 1;
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
// if [b]-->nullptr
//     (a,x) = (a,x) U b
//     [a],[b]-->(a,x,b)
// if [b]-->(b,d,x)
//     [a]-->(a,u,v)U(b,d,x)
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
                if (!dst_map_i[rhs]) {
                    dst_map_i[lhs]->insert(rhs);
                    dst_map_i[rhs] = dst_map_i[lhs];
                } else {   // [b]-->(b,d,x)
                    // [a]-->(a,u,v)U(b,d,x)
                    // dst:_map_i[lhs]->insert(dst_map_i[rhs]->begin(), dst_map_i[rhs]->end());
                    for (auto field : *(dst_map_i[rhs])) {
                        dst_map_i[lhs]->insert(field);
                    }
                    // [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
                    // lhs_unique set: -remove(b,d,x)
                    ordered_set<const PhvInfo::Field *>* dst_map_i_rhs = dst_map_i[rhs];
                    for (auto field : *(dst_map_i[rhs])) {
                        dst_map_i[field] = dst_map_i[lhs];
                        lhs_unique_i.erase(field);                   // lhs_unique set erase field
                    }
                    delete dst_map_i_rhs;                            // delete std::set
                }
            }
            LOG4("lhs_unique..erase[" << std::endl << &lhs_unique_i << "lhs_unique..erase]");
        }
    }
}

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
    // sanity check dst_map_i[] contains unique clusters only
    // forall clusters x,y
    //          x intersect y = 0
    //
    for (auto entry : dst_map_i) {
        if (entry.first && entry.second) {
            ordered_set<const PhvInfo::Field *> s1 = *(entry.second);
            for (auto entry_2 : dst_map_i) {
                if (entry_2.first && entry_2.second && entry_2.first != entry.first) {
                    ordered_set<const PhvInfo::Field *> s2 = *(entry_2.second);
                    std::vector<const PhvInfo::Field *> s3;
                    s3.clear();
                    set_intersection(s1.begin(), s1.end(), s2.begin(), s2.end(),
                        std::back_inserter(s3));
                    if (s3.size()) {
                        LOG1("*****cluster.cpp:sanity_FAIL*****uniqueness.." << msg
                            << entry.first << &s1 << "..^.." << entry_2.first << &s2 << '=' << s3);
                        LOG4("lhs[" << std::endl << &s1 << "lhs]");
                        LOG4("lhs_2[" << std::endl << &s2 << "lhs_2]");
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
std::ostream &operator<<(std::ostream &out, ordered_set<const PhvInfo::Field *> *cluster_set) {
    if (cluster_set) {
        for (auto field : *cluster_set) {
            out << field << std::endl;
        }
    } else {
        out << "[X]" << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<const PhvInfo::Field *>& cluster_vec) {
    for (auto field : cluster_vec) {
        out << field << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster) {
    out << "++++++++++ Clusters (" << cluster.dst_map().size() << ") ++++++++++"
        << std::endl
        << std::endl;
    // iterate through all elements in dst_map
    for (auto entry : cluster.dst_map()) {
        if (entry.second) {
            out << entry.first << "-->(";
            for (auto entry_2 : *(entry.second)) {
                out << ' ' << entry_2;
            }
            out << ')' << std::endl;
        }
    }
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
