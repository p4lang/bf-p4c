#ifndef BF_P4C_LOGGING_PHV_LOGGING_H_
#define BF_P4C_LOGGING_PHV_LOGGING_H_

#include <time.h>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_spec.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/logging/logging.h"
#include "bf-p4c/version.h"
#include "ir/ir.h"
#include "phv_schema.h"

using Logging::Phv_Schema_Logger;

/** This class gathers information related to the MAU use of various fields for use during Phv
  * Logging. This pass must be run prior to Instruction Adjustment because action analysis does not
  * currently handle some IR structures (e.g. MultiOperands) introduced in that pass. This split
  * pass structure allows us to use existing infrastructure to gather MAU related information.
  */
struct CollectPhvLoggingInfo : public MauInspector {
    /// Information about PHV fields.
    const PhvInfo       &phv;

    /// Mapping of table names in the backend to the P4 name.
    ordered_map<cstring, cstring> tableNames;

    /// Action-related and table-related maps.
    /// Mapping from an action to the table which may execute it.
    ordered_map<const IR::MAU::Action*, const IR::MAU::Table*> actionsToTables;

    /// Mapping from a FieldSlice to all the actions in which it is written.
    ordered_map<const PHV::FieldSlice, ordered_set<const IR::MAU::Action*>> sliceWriteToActions;

    /// Mapping from a FieldSlice to all the actions in which it is read.
    ordered_map<const PHV::FieldSlice, ordered_set<const IR::MAU::Action*>> sliceReadToActions;

    /// Mapping from a FieldSlice to all the tables in which it is used in the input crossbar.
    ordered_map<const PHV::FieldSlice, ordered_set<cstring>> sliceXbarToTables;

    /// Clear all local state.
    profile_t init_apply(const IR::Node* root) override;
    /// Gather the P4 names of all tables allocated.
    bool preorder(const IR::MAU::Table* tbl) override;
    /// Gather action writes and reads related information and populate relevant data structures.
    bool preorder(const IR::MAU::Action* act) override;
    /// Gather information related to input xbar reads.
    bool preorder(const IR::MAU::InputXBarRead* read) override;

    explicit CollectPhvLoggingInfo(const PhvInfo& p) : phv(p) { }
};

/** This class is meant to generate logging information about PHV allocation and usage and output it
  * in JSON format defined in logging/phv_schema.json.
  */
class PhvLogging : public MauInspector {
 public:
    using Phv_Schema_Logger = Logging::Phv_Schema_Logger;
    using Container = Phv_Schema_Logger::Container;
    using Records = Phv_Schema_Logger::Container::Records;
    using Access = Phv_Schema_Logger::Access;
    using Resources = Phv_Schema_Logger::Resources;
    struct PardeInfo {
        Access::location_type_t unit;
        std::string parserState;

        bool operator < (PardeInfo other) const {
            if (unit != other.unit)
                return unit < other.unit;
            return parserState < other.parserState;
        }

        bool operator == (PardeInfo other) const {
            return (unit == other.unit && parserState == other.parserState);
        }

        explicit PardeInfo(Access::location_type_t u, std::string name = "")
            : unit(u), parserState(name) { }
    };

 private:
    /// Information about PHV fields.
    const PhvInfo       &phv;
    /// Information collected about PHV fields usage.
    const CollectPhvLoggingInfo& info;
    /// Defuse information for PHV fields.
    const FieldDefUse   &defuse;
    /// Table allocation.
    const ordered_map<cstring, ordered_set<int>>& tableAlloc;

    /// Logger class automatically generated from phv_schema.json.
    Phv_Schema_Logger   logger;

    profile_t init_apply(const IR::Node* root) override {
        return Inspector::init_apply(root);
    }

    void end_apply() override;

    /// Populates data structures related to PHV groups.
    void populateContainerGroups(Resources::group_type_t groupType);

    /// Container related methods.

    /// @returns a Container::bit_width_t::I_* value indicating the bit width of the container.
    Container::bit_width_t containerBitWidth(const PHV::Container c) const;

    /// @returns a Container::container_type_t value indicating the type of the container.
    Container::container_type_t containerType(const PHV::Container c) const;

    /// Field Slice related methods.
    /// @returns a Records::field_class_t value indicating the type of field slice.
    Records::field_class_t getFieldType(const PHV::Field* f) const;

    /// @returns the gress for a field slice.
    Records::gress_t getGress(const PHV::Field* f) const;

    Access::deparser_access_type_t getDeparserAccessType(const PHV::Field* f) const;

    void getAllParserDefs(const PHV::Field* f, ordered_set<PardeInfo>& rv) const;
    void getAllDeparserUses(const PHV::Field* f, ordered_set<PardeInfo>& rv) const;

    void addInputXBarReads(const PHV::FieldSlice& sl, Records* r) const;
    void addVLIWReads(const PHV::FieldSlice& sl, Records* r) const;
    void addVLIWWrites(const PHV::FieldSlice& sl, Records* r) const;

    /// Add header-specific information to the logger object.
    void logHeaders();

    /// Add container-specific information to the logger object.
    void logContainers();

    const std::string buildDate(void) {
      const time_t now = time(NULL);
      char bdate[1024];
      strftime(bdate, 1024, "%c", localtime(&now));
      return bdate;
    }

    static Phv_Schema_Logger::target_t getTarget(cstring deviceName) {
        static std::map<cstring, Phv_Schema_Logger::target_t> targets = {
            { "Tofino",   Phv_Schema_Logger::target_t::TOFINO },
            { "Tofino2",  Phv_Schema_Logger::target_t::TOFINO2 },
            { "Tofino2H", Phv_Schema_Logger::target_t::TOFINO2H },
            { "Tofino2M", Phv_Schema_Logger::target_t::TOFINO2M },
            { "Tofino2U", Phv_Schema_Logger::target_t::TOFINO2U }
        };
        return targets[deviceName];
    }

 public:
    explicit PhvLogging(const char *filename,
                        const PhvInfo &p,
                        const CollectPhvLoggingInfo& c,
                        const FieldDefUse &du,
                        const ordered_map<cstring, ordered_set<int>>& t)
    : phv(p), info(c), defuse(du), tableAlloc(t),
      logger(filename,
             buildDate(),
             BF_P4C_VERSION,
             Device::numStages(),
             BackendOptions().programName + ".p4",
             RunId::getId(),
             "1.0.3",  // phv_schema version
             PhvLogging::getTarget(Device::name())) { }
};

#endif  /* BF_P4C_LOGGING_PHV_LOGGING_H_ */
