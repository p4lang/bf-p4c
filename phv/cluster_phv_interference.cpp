#include "cluster_phv_interference.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Interference::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_Interference::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_Interference::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    // process each cluster, interference based reduction in needs
    //
    for (auto &cl : phv_requirements_i.cluster_phv_fields()) {
        //
        // cluster: each field interference with siblings
        //
        for (auto &f: cl->cluster_vec()) {
            interference_edge_i[f] = new ordered_set<const PhvInfo::Field *>;  // new set
        }
        for (auto &f1: cl->cluster_vec()) {
            for (auto &f2: cl->cluster_vec()) {
                if (f2 != f1) {
                    bool can_overlay = mutex_i(f2->id, f1->id);
                    if (!can_overlay) {
                        create_interference_edge(f2, f1);
                    }
                }
            }
        }
    }
    //
    sanity_check_interference("PHV_Interference::apply_visitor()..");
    //
    LOG3(*this);
    //
    return node;
}

void
PHV_Interference::create_interference_edge(const PhvInfo::Field *f2, const PhvInfo::Field *f1) {
    //
    assert(interference_edge_i[f2]);
    assert(interference_edge_i[f1]);
    interference_edge_i[f2]->insert(f1);
    interference_edge_i[f1]->insert(f2);
}


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Interference::sanity_check_interference(
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Interference::sanity_check_clusters";
    for (auto &cl : phv_requirements_i.cluster_phv_fields()) {
        for (auto &f1: cl->cluster_vec()) {
            for (auto &f2: cl->cluster_vec()) {
                if (interference_edge_i[f2]
                        && interference_edge_i[f2]->count(f2)) {
                    LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg);
                    LOG1("field --interference-- self ");
                    LOG1(f2);
                }
                if (interference_edge_i[f2] && interference_edge_i[f2]->count(f1)) {
                    if (mutex_i(f2->id, f1->id)) {
                        LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg);
                        LOG1("field1 --interference-- field2 should be NOT mutex ");
                        LOG1(f2);
                        LOG1(f1);
                    }
                } else {
                    if (f2 != f1
                        && interference_edge_i[f2] && !interference_edge_i[f2]->count(f1)) {
                        if (!mutex_i(f2->id, f1->id)) {
                            LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg);
                            LOG1("field1 --NO interference-- field2 should BE mutex ");
                            LOG1(f2);
                            LOG1(f1);
                        }
                    }
                }
            }
        }
    }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, PHV_Interference &phv_interference) {
    out << std::endl
        << "Begin ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    out << phv_interference.phv_requirements();
    out << std::endl
        << "End ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
