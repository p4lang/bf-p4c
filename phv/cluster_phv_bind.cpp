#include "cluster_phv_bind.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Bind::PHV_Bind
//
//***********************************************************************************

PHV_Bind::PHV_Bind(PhvInfo &phv_f, PHV_MAU_Group_Assignments &phv_m)
    : phv_i(phv_f),
      phv_mau_group_assignments_i(phv_m),
      phv_mau_i(phv_m.phv_mau_map()),
      t_phv_i(phv_m.t_phv_map())  {
    //
    sanity_check_container_fields("PHV_Bind::PHV_Bind()..");
    //
    LOG3(*this);
    //
}  // PHV_Bind


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Bind::sanity_check_container_fields(const std::string& msg) {
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_container_fields";
    //
    // set difference phv_i fields, fields_i must be 0
    //
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, PHV_Bind &phv_bind) {
    out << std::endl
        << "++++++++++ PHV_Bind PHV Containers to Fields ++++++++++"
        << std::endl
        << phv_bind.fields()
        << std::endl;

    return out;
}
