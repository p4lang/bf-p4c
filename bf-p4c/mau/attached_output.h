#ifndef BF_P4C_MAU_ATTACHED_OUTPUT_H_
#define BF_P4C_MAU_ATTACHED_OUTPUT_H_

#include "ir/ir.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/phv/phv_fields.h"

class LayoutChoices;

typedef std::map<const IR::MAU::AttachedMemory*,
                 ActionFormat::TotalALUPlacement> MeterOutputPlacement;

/**
 *  This pass handles the allocation of action data bus for meter and stateful
 *  ALU output.
 *
 *  Tofino supports two types of meter processing in each of the 4 meter ALU's:
 *  traditional meter implementation defined in RFC2698 and low-pass filter.
 *  This pass handles the LPF processing.
 *
 *  In addition, Tofino supports stateful ALU processing. The output from
 *  stateful ALU should be allocated on the action data bus in a similar way as
 *  LPF output. Therefore this pass also handles stateful ALU output.
 *
 *  Both meter ALU and stateful ALU outputs are referred to as 'MeterOutput'
 *  henceforth.
 *
 *  I explicitly kept the member class and member field name the same as the
 *  ActionFormat class.  If we prefer to reuse ActionFormat class to implement
 *  Meter output, it will be easier to merge the two classes.
 */
struct MeterFormat {
    // assume the backend invariant that IR::MAU::AttachedMemory* is never changed.
    int action_bytes[ActionFormat::LOCATIONS] = {0, 0, 0};

    // for each format, generate total_layouts
    struct Use {
        ActionFormat::TotalALUPlacement action_data_format;
        const IR::MAU::AttachedMemory* attached = nullptr;
        bitvec total_layouts[ActionFormat::CONTAINER_TYPES];

        // map action data bus slot to the home row slot
        using ActionDataBusSlot = std::pair<int /* type */, int /* byte_offset */>;
        using HomeRowBusSlot = std::pair<int /* field_lo */, int /* field_hi */>;
        using SlotToField = std::map<ActionDataBusSlot, std::set<HomeRowBusSlot>>;

        void clear() {
            action_data_format.clear();
        }

        // given a slot used on action data bus, setup a map to look up the field_bit
        // used by the alu.
        void setup_slot_to_field_bit_mapping(SlotToField& adb_to_hr, cstring action_name) const {
            if (!action_data_format.count(action_name))
                return;
            auto adf = action_data_format.at(action_name);
            for (auto &alu : adf) {
                ActionDataBusSlot adb = std::make_pair(alu.gen_index(), alu.start);
                for (auto &arg_loc : alu.arg_locs) {
                    HomeRowBusSlot hrs = std::make_pair(arg_loc.field_bit, arg_loc.field_hi());
                    if (!adb_to_hr.count(adb)) {
                        std::set<HomeRowBusSlot> hrs_set;
                        hrs_set.insert(hrs);
                        adb_to_hr.emplace(adb, hrs_set);
                    } else {
                        auto &entry = adb_to_hr.at(adb);
                        entry.insert(hrs);
                    }
                }
            }
        }
    };
};

/**
 * Visit all actions in the program. If an action uses the output of a meter or
 * stateful ALU and saves the output to a phv, this pass will insert the action
 * data for ALU to a map.  By the end of the pass, the map will contain all
 * action data that come from the output of each meter and stateful ALU. The
 * map is used a subsequent pass to allocate action data bus slot for each
 * meter output.
 */
class CollectMeterOutput : public MauInspector {
 public:
    CollectMeterOutput(const PhvInfo &p, MeterOutputPlacement &m) :
        phv(p), meter_output_placement(m) {}

 private:
    // given the resul
    void create_action_data_from_meter_alu(ActionFormat::ActionDataForSingleALU &adp,
            const ActionAnalysis::ActionParam &read, int container_bit);
    void create_placement(const ActionAnalysis::ContainerActionsMap &cam, cstring name);

    bool preorder(const IR::MAU::Table* tbl) override;

    const PhvInfo &phv;
    MeterOutputPlacement &meter_output_placement;
};

class AllocMeterOutput : public MauInspector {
 public:
    AllocMeterOutput(LayoutChoices &l, MeterOutputPlacement &m) :
        layoutChoices(l), meter_output_placement(m) {}

 private:
    void alloc_format(ActionFormat::TotalALUPlacement &init_alu_format);
    void setup_layout(ActionFormat::TotalALUPlacement &placement,
            const IR::MAU::Table* tbl, const IR::MAU::AttachedMemory* am);
    bool preorder(const IR::MAU::Table* tbl) override;

    LayoutChoices &layoutChoices;
    MeterOutputPlacement &meter_output_placement;
};

class MeterOutputSetup : public PassManager {
 public:
    MeterOutputSetup(const PhvInfo &p, LayoutChoices &l) {
        addPasses({
            new CollectMeterOutput(p, meter_output_placement),
            new AllocMeterOutput(l, meter_output_placement),
        });
    }

 private:
    MeterOutputPlacement meter_output_placement;
};

#endif /* BF_P4C_MAU_ATTACHED_OUTPUT_H_*/
