#include "cluster_phv_slicing.h"
#include "lib/log.h"
#include "base/logging.h"

//***********************************************************************************
// Mark field if used in move-based (defined below) operations.
// A field can be used (read or write) in multiple instructions.
// This pass collects all operations on a field, and append a record of the operation
// (represented as a tuple3 (op, mode, dst/src)) to the vec of operations in the field.
//***********************************************************************************
bool PHV_Field_Operations::preorder(const IR::MAU::Instruction *inst) {
    // see mau/instruction-selection.cpp for all supported instructions
    // operations considered as move-based ops:
    // - set
    // operations not considered as move-based ops
    // - add, sub, substract
    // - bit-mask set
    // - invalidate
    // operations not handled by instruction-selection pass:
    // - noop, load-const, pair-dpf
    // - shifts, byte-rotate-merge, conditional-move/mux
    // - stateful alu instructions (count, meter, extern)

    // 'set' is a special case of 'deposit-field', with no rotation of source data,
    // and all destination data will be replaced.
    // TODO hanw, more ops to moved_based_ops ?
    static const std::set<cstring> move_based_ops = {"set"};
    bool is_move_op = move_based_ops.count(inst->name);

    dst_i = nullptr;
    // get pointer to inst
    if (!inst->operands.empty()) {
        dst_i = const_cast<PhvInfo::Field*> (phv.field(inst->operands[0]));
        if (dst_i) {
            // insert operation in field.operations with tuple3<operation, mode>
            // most of the information in the tuple is for debugging purpose
            auto op = std::make_tuple(is_move_op, inst->name, PhvInfo::Field_Ops::W);
            dst_i->operations.push_back(op);
        }
        // get src operands (if more than 1?)
        if (inst->operands.size() > 1) {
            // iterate 1+
            for (auto operand = ++inst->operands.begin();
                    operand != inst->operands.end();
                    ++operand) {
                PhvInfo::Field* field = phv.field(*operand);
                if (field) {
                    // insert operation in field.operations with tuple3
                    auto op = std::make_tuple(is_move_op, inst->name, PhvInfo::Field_Ops::R);
                    field->operations.push_back(op);
                }
            }
        }
    }
    return true;
}

//***********************************************************************************
// Slicing takes two steps
// 1. iterate all field in a cluster, check if all operations on a field are move based.
//  - if true, the cluster can be sliced.
//  - else, the cluster cannot sliced.
// 2. slicing the cluster by half, or +/- 1 bit around the center.
//***********************************************************************************
const IR::Node *
Cluster_Slicing::apply_visitor(const IR::Node *node, const char *name) {
    LOG3("..........Cluster_PHV_Slicing::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    std::list<Cluster_PHV *> clusters_remove;
    std::list<Cluster_PHV *> clusters_add;
    LOG3("....... Cluster to be sliced ("
        << phv_mau_i.phv_clusters().size()
        << ")..."
        );
    for (auto &cl : phv_mau_i.phv_clusters()) {
        // decide if a cluster is sliceable.
        // A cluster is sliceable if:
        // - all fields in the cluster are uniform in size
        // - no POV fields
        // - no ccgf fields
        // - all operations on fields are move-based (define move)
        //
        // do not slice non-uniform cluster
        if (!cl->uniform_width()) {
            LOG3("... skip non-uniform clusters ...");
            continue;
        }
        if (cl->max_width() <= 1) {
            // cannot slice cluster with field of size 1
            continue;
        }
        bool sliceable = true;
        for (auto &f : cl->cluster_vec()) {
            // do not slice pov group
            if (f->pov) {
                sliceable = false;
                break;
            }
            // do not slice cluster with ccgf (container contiguous group fields)
            if (f->ccgf != NULL) {
                sliceable = false;
                break;
            }
            for (auto &op : f->operations) {
                // element 0 in tuple is 'is_move_op'
                if (std::get<0>(op) != true) {
                    sliceable = false;
                    break;
                }
            }
            if (!sliceable)
                break;
        }
        // create new clusters
        if (sliceable) {
            LOG3("... cluster is sliceable ..." << cl->max_width());
            std::string id = cl->id();
            Cluster_PHV *m_lo = new Cluster_PHV(cl->cluster_vec()[0], id);
            Cluster_PHV *m_hi = new Cluster_PHV(cl->cluster_vec()[0], id);
            m_lo->sliceable(true);
            m_hi->sliceable(true);
            for (auto &f : cl->cluster_vec()) {
                int phv_use_lo_0, phv_use_hi_0, phv_use_lo_1, phv_use_hi_1;
                phv_use_lo_0 = phv_use_hi_0 = phv_use_lo_1 = phv_use_hi_1 = 0;
                // if cluster has been sliced before, use _lo and _hi from the slices.
                if (cl->sliceable()) {
                    phv_use_lo_0 = cl->field_slices()[f].first;
                    phv_use_hi_0 = phv_use_lo_0 + cl->max_width() / 2 - 1;
                    phv_use_lo_1 = phv_use_lo_0 + cl->max_width() / 2;
                    phv_use_hi_1 = cl->field_slices()[f].second;
                }
                // else use _lo and _hi from original field.
                else {
                    phv_use_lo_0 = f->phv_use_lo;
                    phv_use_hi_0 = f->phv_use_lo + f->size / 2 - 1;
                    phv_use_lo_1 = f->phv_use_lo + f->size / 2;
                    phv_use_hi_1 = f->phv_use_hi;
                }
                LOG3("... cluster sliced width ..."
                        << phv_use_lo_0
                        << "..."
                        << phv_use_hi_0
                        << "..."
                        << phv_use_lo_1
                        << "..."
                        << phv_use_hi_1
                        << "...");
                m_lo->field_slices().emplace(f,
                        std::make_pair(phv_use_lo_0, phv_use_hi_0));
                m_lo->max_width(phv_use_hi_0 - phv_use_lo_0 + 1);
                m_hi->field_slices().emplace(f,
                        std::make_pair(phv_use_lo_1, phv_use_hi_1));
                m_hi->max_width(phv_use_hi_1 - phv_use_lo_1 + 1);
                LOG3("... "
                        << m_lo->max_width()
                        << "..."
                        << m_hi->max_width());
            }
            clusters_add.push_back(m_lo);
            clusters_add.push_back(m_hi);
            // remove clusters already sliced
            clusters_remove.push_back(cl);
        }
    }
    // remove sliced PHV
    for (auto &cl : clusters_remove) {
        phv_mau_i.phv_clusters().remove(cl);
    }
    // add generated PHV
    for (auto &cl : clusters_add) {
        // modify cluster reflect slicing
        phv_mau_i.phv_clusters().push_back(cl);
    }
    LOG3("....... Cluster after slicing ("
        << phv_mau_i.phv_clusters().size()
        << ")...");
    return node;
}

//***********************************************************************************
// fit clusters to slices again at the end of the pass
//***********************************************************************************
void Cluster_Slicing::end_apply() {
    // phv_mau_i.status (phv_mau_i.phv_clusters());
    // phv_mau_i.status (phv_mau_i.aligned_container_slices());
    phv_mau_i.container_pack_cohabit(phv_mau_i.phv_clusters(),
                                     phv_mau_i.aligned_container_slices());
}
