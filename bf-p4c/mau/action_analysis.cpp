#include "action_analysis.h"
#include "resource.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_fields.h"

/** Calculates a total container constant, given which constants wrote to which fields in the
 *  operation
 */
unsigned ActionAnalysis::ConstantInfo::build_constant() {
    unsigned rv = 0;
    BUG_CHECK(!positions.empty(), "Building a constant over a container when no constants are "
              "contained within this container action");
    for (auto position : positions) {
        unsigned mask;
        if (position.range.size() == sizeof(unsigned) * 8)
            mask = static_cast<unsigned>(-1);
        else
            mask = (1U << position.range.size()) - 1;
        unsigned pre_shift = position.value & mask;
        rv |= (pre_shift << position.range.lo);
    }
    return rv;
}

/** Shifts a constant to the lower read bits point to determine if the constant can be used
 *  within a deposit-field
 */
unsigned ActionAnalysis::ConstantInfo::build_shiftable_constant() {
    unsigned rv = build_constant();
    bitvec rv_bv(rv);

    if (rv_bv.empty())
        return rv;

    return rv_bv.getrange(alignment.write_bits.min().index(), alignment.bitrange_size());
}

/** Because the assembly only recognizes constants between -8..7 or their corresponding
 *  container size complement, this function converts all container constants (post-shifted)
 *  to a pre-shift value between -8 and 7
 */
unsigned ActionAnalysis::ConstantInfo::valid_instruction_constant(int container_size) const {
     unsigned max_value = (1U << CONST_SRC_MAX) - 1;
     if (max_value >= constant_value) {
         return constant_value;
     }

     unsigned total_container_mask;
     if (container_size == sizeof(unsigned) * 8)
         total_container_mask = static_cast<unsigned>(-1);
     else
         total_container_mask = (1U << container_size) - 1;
     unsigned constant_mask;
     int cm_size = alignment.bitrange_size();
     if (cm_size == sizeof(unsigned) * 8)
         constant_mask = static_cast<unsigned>(-1);
     else
         constant_mask = (1U << cm_size) - 1;
     return ((total_container_mask & ~constant_mask) | constant_value);
}

void ActionAnalysis::initialize_phv_field(const IR::Expression *expr) {
    if (!phv.field(expr))
        return;

    if (isWrite()) {
        if (field_action.write_found) {
            BUG("Multiple write in a single instruction?");
        }
        ActionParam write(ActionParam::PHV, expr);
        field_action.setWrite(write);
    } else {
        field_action.reads.emplace_back(ActionParam::PHV, expr);
    }
}

void ActionAnalysis::initialize_action_data(const IR::Expression *expr) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, expr);
    if (auto *ao = field_action.reads.back().unsliced_expr()->to<IR::MAU::AttachedOutput>())
        field_action.reads.back().speciality = classify_attached_output(ao);
    if (field_action.reads.back().unsliced_expr()->is<IR::MAU::HashDist>())
        field_action.reads.back().speciality = ActionParam::HASH_DIST;
}

ActionAnalysis::ActionParam::speciality_t
ActionAnalysis::classify_attached_output(const IR::MAU::AttachedOutput *ao) {
    auto *at = ao->attached;
    if (auto mtr = at->to<IR::MAU::Meter>()) {
        if (mtr->alu_output())
            return ActionParam::METER_ALU;
        else if (mtr->color_output())
            return ActionParam::METER_COLOR;
        BUG("%s: Unrecognized implementation %s on meter %s", mtr->srcInfo,
            mtr->implementation, mtr->name);
        return ActionParam::NO_SPECIAL;
    } else if (at->is<IR::MAU::StatefulAlu>()) {
        return ActionParam::METER_ALU;
    }
    BUG("%s: Unrecognizable Attached Output %s being used in an ALU operation",
        at->srcInfo, at->name);
}

/** Similar to phv.field, it returns the IR structure that corresponds to actiondata,
 *  If it is an MAU::ActionArg, HashDist, or AttachedOutput then the type is ACTIONDATA
 *  If it is an ActionDataConstant, then the type is CONSTANT
 */
const IR::Expression *ActionAnalysis::isActionParam(const IR::Expression *e,
        le_bitrange *bits_out, ActionParam::type_t *type) {
    le_bitrange bits = { 0, e->type->width_bits() - 1};
    if (auto *sl = e->to<IR::Slice>()) {
        bits.lo = sl->getL();
        bits.hi = sl->getH();
        e = sl->e0;;
        if (e->is<IR::MAU::ActionDataConstant>())
            BUG("No ActionDataConstant should be a member of a Slice");
    }
    if (e->is<IR::MAU::ActionArg>() || e->is<IR::MAU::ActionDataConstant>()
        || e->is<IR::MAU::AttachedOutput>() || e->is<IR::MAU::HashDist>()
        || e->is<IR::MAU::RandomNumber>()) {
        if (bits_out)
            *bits_out = bits;
        if ((e->is<IR::MAU::ActionArg>() || e->is<IR::MAU::AttachedOutput>()
            || e->is<IR::MAU::HashDist>() || e->is<IR::MAU::RandomNumber>()) && type)
            *type = ActionParam::ACTIONDATA;
        if (e->is<IR::MAU::ActionDataConstant>() && type)
            *type = ActionParam::CONSTANT;
        return e;
    }
    return nullptr;
}

const IR::MAU::ActionArg *ActionAnalysis::isActionArg(const IR::Expression *e,
    le_bitrange *bits_out) {
    le_bitrange bits = { 0, e->type->width_bits() - 1 };
    if (auto *sl = e->to<IR::Slice>()) {
        bits.lo = sl->getL();
        bits.hi = sl->getH();
        e = sl->e0;
    }

    if (auto aa = e->to<IR::MAU::ActionArg>()) {
        if (bits_out)
           *bits_out = bits;
        return aa;
    }
    return nullptr;
}


std::ostream &operator<<(std::ostream &out, const ActionAnalysis::ActionParam &ap) {
    out << ap.expr;
    return out;
}


const IR::Expression *ActionAnalysis::ActionParam::unsliced_expr() const {
    if (expr == nullptr)
        return expr;
    if (auto *sl = expr->to<IR::Slice>())
        return sl->e0;
    return expr;
}


std::ostream &operator<<(std::ostream &out, const ActionAnalysis::FieldAction &fa) {
    out << fa.name << " ";
    out << fa.write;
    for (auto &read : fa.reads)
        out << ", " << read;
    return out;
}

std::ostream &operator<<(std::ostream &out, const ActionAnalysis::ContainerAction &ca) {
    out << "{ ";
    for (auto &fa : ca.field_actions) {
        out << fa << "; ";
    }
    out << "}";
    return out;
}

bool ActionAnalysis::preorder(const IR::MAU::Instruction *instr) {
    field_action.clear();
    field_action.name = instr->name;
    return true;
}

bool ActionAnalysis::preorder(const IR::MAU::ActionArg *arg) {
    if (!findContext<IR::MAU::Instruction>())
        return false;

    initialize_action_data(arg);
    return false;
}

bool ActionAnalysis::preorder(const IR::Constant *constant) {
    field_action.reads.emplace_back(ActionParam::CONSTANT, constant);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::ActionDataConstant *adc) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, adc);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::HashDist *hd) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, hd, ActionParam::HASH_DIST);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::AttachedOutput *ao) {
    auto speciality = classify_attached_output(ao);
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, ao, speciality);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::RandomNumber *rn) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, rn, ActionParam::RANDOM);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::StatefulAlu *) {
    return false;
}

bool ActionAnalysis::preorder(const IR::Primitive *) {
    return false;
}

bool ActionAnalysis::preorder(const IR::Slice *sl) {
    if (phv.field(sl)) {
        initialize_phv_field(sl);
    } else if (isActionParam(sl)) {
        initialize_action_data(sl);
    } else {
        ERROR("Slice is of IR structure not handled by ActionAnalysis");
    }
    // Constants should not be in slices ever, they should just be either refactored into
    // action data, or already separately split constants with different values
    return false;
}

bool ActionAnalysis::preorder(const IR::Cast *) {
    BUG("No casts should ever reach this point in the Tofino backend");
}

bool ActionAnalysis::preorder(const IR::Expression *expr) {
    if (phv.field(expr)) {
        initialize_phv_field(expr);
    } else {
        BUG("IR structure not yet handled by the ActionAnalysis pass");
    }
    return false;
}
bool ActionAnalysis::preorder(const IR::Member *mem) {
    if (mem->expr->is<IR::MAU::AttachedOutput>()) return true;
    return preorder(static_cast<const IR::Expression *>(mem));
}

/** Responsible for adding the instruction into which containers they actually affect.
 *  Thus multiple field based actions can be added to the same container, and then evalauted
 *  later.
 */
void ActionAnalysis::postorder(const IR::MAU::Instruction *instr) {
    if (!field_action.write_found) {
        ERROR("Nothing written in the instruction " << instr);
    }

    if (phv_alloc) {
        le_bitrange bits;

        auto *field = phv.field(field_action.write.expr, &bits);
        int split_count = 0;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
            split_count++;
        });

        bool split = true;
        if (split_count == 1)
            split = false;
        if (split_count == 0)
            ERROR("PHV not allocated for this field");

        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            auto container = alloc.container;
            if (container_actions_map->find(container) == container_actions_map->end()) {
                ContainerAction cont_action;
                cont_action.name = instr->name;
                container_actions_map->emplace(container, cont_action);
            }
            if (!split) {
                (*container_actions_map)[container].field_actions.push_back(field_action);
            } else {
                FieldAction field_action_split;
                field_action_split.name = field_action.name;
                field_action_split.requires_split = true;
                auto *write_slice = MakeSliceDestination(field_action.write.expr, alloc.field_bit,
                                              alloc.field_hi());
                ActionParam write_split(field_action.write.type, write_slice,
                                        field_action.write.speciality);
                field_action_split.setWrite(write_split);
                for (auto &read : field_action.reads) {
                    auto read_slice = MakeSliceSource(read.expr, alloc.field_bit, alloc.field_hi(),
                            field_action.write.expr);
                    field_action_split.reads.emplace_back(read.type, read_slice, read.speciality);
                }
                (*container_actions_map)[container].field_actions.push_back(field_action_split);
            }
        });
    } else {
        (*field_actions_map)[instr] = field_action;
    }
}

/** PHV allocation is not known by the time of this verification.  This check just guarantees
 *  that the action is even at all possible within Tofino.  If not, the compiler should just
 *  fail at this point.  To ensure that an action is possible in Tofino:
 *    - The operation must be able to run in parallel (i.e. no repeated lvalues, a write read
 *      later in the operation)
 *    - The operands must be in the same size
 *    - Only one action data per instruction
 */
bool ActionAnalysis::verify_P4_action_without_phv(cstring action_name) {
    ordered_map<const PHV::Field *, bitvec> written_fields;

    for (auto field_action_info : *field_actions_map) {
        auto &field_action = field_action_info.second;

        // Check reads before writes for this, as field can be used in it's own instruction
        for (auto read : field_action.reads) {
            if (read.type != ActionParam::PHV) continue;
            le_bitrange read_bitrange = {0, 0};
            auto field = phv.field(read.expr, &read_bitrange);
            bitvec read_bits(read_bitrange.lo, read_bitrange.size());
            BUG_CHECK(field, "Cannot convert an instruction read to a PHV field reference");
            if (written_fields.find(field) == written_fields.end()) continue;
            if (written_fields[field].intersects(read_bits)) {
                ::warning("Action %s has a read of a field %s after it already has been written",
                          action_name, cstring::to_cstring(read));
                warning = true;
            }
        }

        le_bitrange bits = {0, 0};
        auto field = phv.field(field_action.write.expr, &bits);
        bitvec write_bits(bits.lo, bits.size());
        BUG_CHECK(field, "Cannot convert an instruction write to a PHV field reference");
        if (written_fields.find(field) != written_fields.end()) {
            if (written_fields[field].intersects(write_bits)) {
                ::warning("Action %s has repeated lvalue %s", action_name, field->name);
                warning = true;
            }
            written_fields[field] |= write_bits;
        } else {
            written_fields[field] = write_bits;
        }

        int non_phv_count = 0;
        for (auto read : field_action.reads) {
            if (read.type == ActionParam::ACTIONDATA || read.type == ActionParam::CONSTANT)
                non_phv_count++;
            if (non_phv_count > 1) {
                ::warning("In action %s, the following instruction has multiple action data "
                          "parameters: %s", action_name, cstring::to_cstring(field_action));
                warning = true;
            }
        }

        if (!field_action.is_shift()) {
            for (auto read : field_action.reads) {
                if (read.size() != field_action.write.size()) {
                    ::warning("In action %s, write %s and read %s sizes do not match up",
                              action_name, cstring::to_cstring(field_action.write),
                              cstring::to_cstring(read));
                    warning = true;
                }
            }
        }
    }

    return true;
}

/** The purpose of this function is to calculate the alignment of the write bits for the destination
  * of an invalidate instruction. The invalidate instruction is special in that it does not have any
  * source operands, and the alignment of the write bits must thus be set separately for this
  * particular instruction. The function will return false if the total_write_bits member of
  * @cont_action cannot be set.
  */
bool ActionAnalysis::initialize_invalidate_alignment(const ActionParam &write, ContainerAction
        &cont_action) {
    BUG_CHECK(cont_action.name == "invalidate", "Expected invalidate instruction");
    le_bitrange range;
    auto *field = phv.field(write.expr, &range);
    BUG_CHECK(field, "Write in invalidate instruction has no PHV location");

    int count = 0;
    le_bitrange write_bits;
    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
        count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits = alloc.container_bits();
    });

    BUG_CHECK(count == 1, "ActionAnalysis did not split up container by container");

    return cont_action.set_invalidate_write_bits(write_bits);
}

/** The purpose of this function is calculate the location of the alignments of both PHV
 *  and action data for a single FieldAction in a ContainerAction.  Before action data
 *  allocation (done by the ActionFormat structure), we just align the write_bits and
 *  read_bits.  After action data allocation, we pull directly from the structures that hold
 *  this information for values.
 *
 *  This function will return false if the parameters are not the same size, or if the
 *  PHV allocation is done in a way where a single read field is actually found over two
 *  PHV containers, and thus cannot be aligned by itself, i.e. a single write requires two
 *  reads.  This may be too tight, but is a good initial warning check.
 */
bool ActionAnalysis::initialize_alignment(const ActionParam &write, const ActionParam &read,
    ContainerAction &cont_action, cstring &error_message, PHV::Container container,
    cstring action_name) {

    if (cont_action.is_shift() && read.type == ActionParam::CONSTANT)
        return true;

    error_message = "In the ALU operation over container " + container.toString() +
                    " in action " + action_name + ", ";
    if (write.expr->type->width_bits() != read.expr->type->width_bits()
        && !cont_action.is_shift()) {
        error_message += "the number of bits in the write and read aren't equal";
        cont_action.error_code |= ContainerAction::DIFFERENT_READ_SIZE;
        return false;
    }

    le_bitrange range;
    auto *field = phv.field(write.expr, &range);
    BUG_CHECK(field, "Write in an instruction has no PHV location");

    int count = 0;
    le_bitrange write_bits;
    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
        count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits = alloc.container_bits();
    });

    BUG_CHECK(count == 1, "ActionAnalysis did not split up container by container");

    bool initialized;
    if (read.type == ActionParam::PHV) {
        initialized = init_phv_alignment(read, cont_action, write_bits, error_message);
    } else if (ad_alloc) {
        if (read.type == ActionParam::ACTIONDATA)
            initialized = init_ad_alloc_alignment(read, cont_action, write_bits, action_name,
                                                  container);
        else
            initialized = init_constant_alignment(read, cont_action, write_bits, action_name,
                                                  container);
    } else {
        initialized = init_simple_alignment(read, cont_action, write_bits);
    }

    if (!initialized)
        cont_action.set_mismatch(read.type);

    return initialized;
}

/** This initializes the alignment of a particular PHV field.  It also guarantees that there
 *  is only one PHV read per PHV write.
 */
bool ActionAnalysis::init_phv_alignment(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits, cstring &error_message) {
    le_bitrange range;
    auto *field = phv.field(read.expr, &range);

    BUG_CHECK(field, "PHV read has no allocation");

    int count = 0;
    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
        count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
    });

    if (count > MAX_PHV_SOURCES) {
        error_message += "an individual read phv is contained within more than 2 containers, and"
                         "is considered impossible";
        return false;
    }


    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
         le_bitrange read_bits = alloc.container_bits();
         int lo;
         int hi;
         if (!cont_action.is_shift()) {
             lo = write_bits.lo + (alloc.field_bit - range.lo);
             hi = lo + read_bits.size() - 1;
         } else {
             lo = write_bits.lo;
             hi = write_bits.hi;
         }
         le_bitrange mini_write_bits(lo, hi);

         auto &phv_alignment = cont_action.phv_alignment;
         if (phv_alignment.find(alloc.container) == phv_alignment.end()) {
             TotalAlignment ta;
             ta.add_alignment(mini_write_bits, read_bits);
             phv_alignment[alloc.container] = ta;
             cont_action.counts[ActionParam::PHV]++;
         } else {
             phv_alignment[alloc.container].add_alignment(mini_write_bits, read_bits);
         }
    });
    return true;
}

/** This initializes the alignment of action data, given that the action data allocation has
 *  taken place.  Action data allocation can take place before or after phv allocation, and
 *  thus the information in the ActionDataPlacement may not match up with the actual phv
 *  allocation.  Thus this function could potentially return false.
 */
bool ActionAnalysis::init_ad_alloc_alignment(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits, cstring action_name, PHV::Container container) {
    if (read.speciality != ActionParam::NO_SPECIAL)
        return init_simple_alignment(read, cont_action, write_bits);

    auto &action_format = tbl->resources->action_format;

    auto &placements = action_format.arg_placement.at(action_name);

    // Information on where fields are stored
    auto action_data_format = action_format.action_data_format.at(action_name);

    le_bitrange read_range;
    ActionParam::type_t type = ActionParam::ACTIONDATA;
    auto action_arg = isActionParam(read.expr, &read_range, &type);
    if (action_arg == nullptr)
    BUG_CHECK(action_arg != nullptr, "Action argument not converted correctly in the "
                                     "ActionAnalysis pass");
    cstring arg_name;
    if (type == ActionParam::ACTIONDATA)
        arg_name = action_arg->to<IR::MAU::ActionArg>()->name;
    else if (type == ActionParam::CONSTANT)
        arg_name = action_arg->to<IR::MAU::ActionDataConstant>()->name;


    ActionFormat::ArgKey ak;
    ak.init(arg_name, read_range.lo, action_format.phv_alloc, container, write_bits.lo);

    BUG_CHECK(placements.find(ak) != placements.end(), "Action argument is not found to be "
              "allocated in the action format");
    auto &arg_placement = placements.at(ak);

    bool found = false;
    for (auto arg_value : arg_placement) {
        auto adp = action_data_format.at(arg_value.placement_index);
        auto arg_loc = adp.arg_locs.at(arg_value.arg_index);

        // These checks are for the scenario, when the action data placement is determined
        // before phv allocation.  This will verify that the action format guessed is even
        // possible.  If the argument can't be found, the algorithm will backtrack to the
        // action format creation
        if (static_cast<size_t>(adp.alu_size) != container.size()) continue;
        int lo = arg_loc.is_constant ? 0 : arg_loc.field_bit;
        int hi = arg_loc.field_hi();
        if (!(lo <= read_range.lo && hi >= read_range.hi)) continue;

        auto &adi = cont_action.adi;

        if (cont_action.counts[ActionParam::ACTIONDATA] == 0) {
            adi.initialize(adp.get_action_name(), adp.immediate, adp.start,
                           adp.arg_locs.size());
            adi.alignment.add_alignment(write_bits, arg_loc.slot_br());
            cont_action.counts[ActionParam::ACTIONDATA] = 1;
        } else if (adi.start != adp.start || adi.immediate != adp.immediate) {
            cont_action.counts[ActionParam::ACTIONDATA]++;
        } else {
            adi.field_affects++;
            adi.alignment.add_alignment(write_bits, arg_loc.slot_br());
        }
        found = true;
    }
    return found;
}


void ActionAnalysis::initialize_constant(const ActionParam &read,
        ContainerAction &cont_action, le_bitrange write_bits, le_bitrange read_bits) {
    cont_action.ci.initialized = true;
    cont_action.ci.alignment.add_alignment(write_bits, read_bits);

    auto constant = read.expr->to<IR::Constant>();

    // FIXME: Could use a helper function on IR::Constant, but not pressing, though
    // for the purposes must fit within a 32 bit section
    // Constant can be from MINX_INT <= x <= MAX_UINT
    BUG_CHECK(constant->value.fits_uint_p() || constant->fitsInt(), "%s: Constant "
              "value in an instruction not split correctly", constant->srcInfo);

    unsigned constant_value;
    if (constant->value.fits_uint_p())
        constant_value = constant->value.get_ui();
    else
        constant_value = static_cast<unsigned>(constant->asInt());
    cont_action.ci.positions.emplace_back(constant_value, write_bits);
}

/** Handles a IR::Constant within an Instruction to determine whether the constant will
 *  be converted to an ActionDataConstant or not.  If is the constant is to be converted,
 *  the alignment must be pulled out of the table placement algorithm.
 */
bool ActionAnalysis::init_constant_alignment(const ActionParam &read,
        ContainerAction &cont_action, le_bitrange write_bits, cstring action_name,
        PHV::Container container) {
    auto &action_format = tbl->resources->action_format;
    auto &constant_renames = action_format.constant_locations.at(action_name);
    auto action_data_format = action_format.action_data_format.at(action_name);

    ActionFormat::ArgKey ak;
    ak.init_constant(container, write_bits.lo);

    // If it is in this map, then this IR::Constant has to be converted to an
    // IR::ActionDataConstant, which itself can have a particular location in the action format
    // slot
    if (constant_renames.find(ak) == constant_renames.end()) {
        return init_simple_alignment(read, cont_action, write_bits);
    }

    auto arg_value = constant_renames.at(ak);

    auto &adp = action_data_format.at(arg_value.placement_index);
    auto &arg_loc = adp.arg_locs.at(arg_value.arg_index);

    BUG_CHECK(arg_loc.is_constant, "Constant locations in the action data format located an "
              "argument that is not a constant");

    // FIXME: Duplicate code used, but creation of a function would currently require
    // action_analysis.h to include action_format.h, which cannot happen as constructed currently
    initialize_constant(read, cont_action, write_bits, arg_loc.slot_br());
    cont_action.counts[ActionParam::CONSTANT]++;
    return true;
}

/** For action data before PHV allocation or constants.  Just guarantees that the write bits
 *  match up directly with the read bits
 */
bool ActionAnalysis::init_simple_alignment(const ActionParam &read,
         ContainerAction &cont_action, le_bitrange write_bits) {
    if (read.type == ActionParam::ACTIONDATA)
        BUG_CHECK(isActionParam(read.expr), "Action Data parameter not configured properly "
                                             "in ActionAnalysis pass");
    else if (read.type == ActionParam::CONSTANT)
        BUG_CHECK(read.expr->is<IR::Constant>(), "Constant parameter not configured properly "
                                                  "in ActionAnalysis pass");

    le_bitrange read_bits = write_bits;
    if (read.type == ActionParam::ACTIONDATA) {
        cont_action.adi.alignment.add_alignment(write_bits, read_bits);
    } else if (read.type == ActionParam::CONSTANT) {
        initialize_constant(read, cont_action, write_bits, read_bits);
    }
    cont_action.counts[read.type]++;
    return true;
}

/** After the container_actions_map structure is built, this analyzes each of the individual actions
 *  within a container, as well as the entire action to the container as an individual object.
 *  PHV allocation is assumed to be completed at this point.
 *
 *  The individual checks just verify that the reads can be correctly aligned to the write PHV.
 *     - For PHVs, this means that the total read PHV is completely capture in the write
 *     - For ActionData, whether the action data format is correctly aligned with the PHV
 *     - For Constants, TBD
 *
 *  The total container action also goes through a large verification step, which checks
 *  general constraints on total number of PHVs, ActionData and Constants used.  It'll then
 *  mark an instruction currently impossible or not yet implemented if it is either.
 */
bool ActionAnalysis::verify_P4_action_with_phv(cstring action_name) {
    if (verbose)
        LOG2("Action " << action_name << " in table " << tbl->name);
    for (auto &container_action : *container_actions_map) {
        auto &container = container_action.first;
        auto &cont_action = container_action.second;
        cont_action.verbose = verbose;

        if (verbose)
            LOG2("Action over container " << container.toString() << ": " << cont_action);
        cstring instr_name;
        bool same_action = true;
        BUG_CHECK(cont_action.field_actions.size() > 0, "Somehow a container action has no "
                                                        "field actions allocated to it");
        instr_name = cont_action.field_actions[0].name;
        for (auto &field_action : cont_action.field_actions) {
            if (instr_name != field_action.name) {
                cont_action.error_code |= ContainerAction::MULTIPLE_CONTAINER_ACTIONS;
                same_action = false;
            }
        }

        if (!same_action && error_verbose) {
            ::warning("In action %s over container %s, the action has multiple operand types %s",
                      action_name, container.toString(), cstring::to_cstring(cont_action));
            warning = true;
        }

        if (!same_action)
            continue;

        cont_action.name = instr_name;
        bool total_init = true;
        for (auto &field_action : cont_action.field_actions) {
            auto &write = field_action.write;
            if (cont_action.name == "invalidate")
                total_init &= initialize_invalidate_alignment(write, cont_action);
            for (auto &read : field_action.reads) {
                cstring init_error_message;
                bool init = initialize_alignment(write, read, cont_action, init_error_message,
                                                 container, action_name);
                if (!init && error_verbose) {
                    ::warning("%s: %s", init_error_message, cstring::to_cstring(cont_action));
                    warning = true;
                }
                total_init &= init;
            }
        }


        cstring error_message;
        bool verify = cont_action.verify_possible(error_message, container, action_name, phv);
        if (!verify && error_verbose) {
            ::warning("%s: %s", error_message, cstring::to_cstring(cont_action));
            warning = true;
        }
        check_constant_to_actiondata(cont_action, container);
        add_to_single_ad_params(cont_action);
    }

    for (auto &container_action : *container_actions_map) {
        auto &cont_action = container_action.second;
        check_single_ad_params(cont_action);
    }

    // Specifically for backtracking, as ActionFormat can be configured before PHV allocation,
    // and may not be correct.
    for (auto &container_action : *container_actions_map) {
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & ContainerAction::ACTION_DATA_MISMATCH) != 0
            || (cont_action.error_code & ContainerAction::MULTIPLE_ACTION_DATA) != 0) {
            action_data_misaligned = true;
            break;
        }
    }
    return true;
}

/** Is the bitvec rotationally contiguous, and thus can it perform as a read in a PHV set.
    Unused but useful, so kept
 */
/*
bool ActionAnalysis::ContainerAction::is_contig_rotate(bitvec check, int &shift, int size) {
    shift = 0;
    int start = check.ffs();
    int end = check.ffz(start);

    if (end == check.max().index())
        return true;

    int second_start = check.ffs(end);
    int second_end = check.ffz(second_start);

    if (start == 0 && second_end == size) {
        shift = end - start;
        return true;
    }
    return false;
}
*/

/** Rotate a bitvec so that it is now contiguous, rather than rotationally contiguous.  Not used
 *  yet as it is too difficult within the IR::Slice process.
 */
/*
bitvec ActionAnalysis::ContainerAction::rotate_contig(bitvec orig, int shift, int size) {
    bitvec subtract(0, shift);
    bitvec rv = (orig - subtract) << shift;

    rv |= (subtract >> (size - shift));
    return rv;
}
*/


bitvec ActionAnalysis::ContainerAction::total_write() const {
    bitvec total_write_;
    for (auto tot_align_info : phv_alignment)
        total_write_ |= tot_align_info.second.write_bits;
    total_write_ |= adi.alignment.write_bits;
    total_write_ |= ci.alignment.write_bits;

    return total_write_;
}

/** Guarantees that a single alignment is aligned correctly.  The checks are:
 *    - The number of bits in the write and read are the same
 *    - The write and reads are contiguous, unless the operation is a bitmasked set
 *
 *  It also checks if the fields are unaligned
 */
bool ActionAnalysis::ContainerAction::verify_one_alignment(TotalAlignment &tot_alignment,
        int size, int &unaligned_count, int &non_contiguous_count) {
    (void) size;


    if (tot_alignment.write_bits.popcount() != tot_alignment.read_bits.popcount()) {
        return false;
    }

    bool contiguous = true;
    bool aligned = true;

    if (!tot_alignment.write_bits.is_contiguous() || !tot_alignment.read_bits.is_contiguous()) {
        contiguous = false;
    }

    if ((tot_alignment.write_bits - tot_alignment.read_bits).popcount() != 0) {
        aligned = false;
    }

    // FIXME: Eventually can support rotational shifts, but not yet with IR::Slice setup
    // || !is_contig_rotate(tot_alignment.read_bits, read_rot_shift, size)) {
    if (!aligned && !contiguous)
        return false;

    if (!aligned)
        unaligned_count++;
    if (!contiguous)
        non_contiguous_count++;
    return true;
    /*
    // FIXME: Verify on an individual field by field basis on the instruction on alignment
    bitvec write_rotate = rotate_contig(tot_alignment.write_bits, write_rot_shift, size);
    bitvec read_rotate = rotate_contig(tot_alignment.read_bits, read_rot_shift, size);
    */
}

/** Verifies all stored alignments, i.e. PHV and action data.  The following constraints must
 *  be checked:
 *    - If the instruction is anything but a deposit field, (a set that isn't a bitmasked-set)
 *      then all sources must be directly aligned with the write
 *    - If the operation is a deposit-field, then at most one source can be misaligned.  If the
 *      operation has action data, then the PHV has to be aligned.  Otherwise, one of the two
 *      PHV fields can be misaligned
 *
 *  Only in deposit-field can a portion of a source (PHV container or action data bus), can be
 *  shifted.
 *
 *  This function also saves which parameters get classified as a src1.  An instruction at most
 *  can have two sources.  Src2 is always a PHV container.  Src1 can be much more loosely defined
 *  Src1 can be from action data, a small constant, or a PHV alu.  Specifically in deposit-field
 *  instruction, src1 is the only source that doesn't have to bit-aligned either.  This
 *  information is used when creating instructions in InstructionAdjustment, specifically right
 *  now MergeInstructions
 */
bool ActionAnalysis::ContainerAction::verify_alignment(int max_phv_unaligned,
        int max_ad_unaligned, int max_non_contiguous, PHV::Container container) {
    int unaligned_count = 0;
    int non_contiguous_count = 0;

    for (auto &tot_align_info : phv_alignment) {
        auto &tot_alignment = tot_align_info.second;

        // Verify on an individual field by field basis on the instruction on alignment
        bool verify = verify_one_alignment(tot_alignment, container.size(),
                                           unaligned_count, non_contiguous_count);
        if (!verify)
            return false;
    }

    if (unaligned_count > max_phv_unaligned)
        return false;

    // Only one PHV field can be non-contiguous within a deposit-field right now

    unaligned_count = 0;
    if (counts[ActionParam::ACTIONDATA] > 0) {
        bool verify = verify_one_alignment(adi.alignment, container.size(), unaligned_count,
                                           non_contiguous_count);
        if (!verify)
            return false;

        if (unaligned_count > max_ad_unaligned)
            return false;
    }

    if (non_contiguous_count > max_non_contiguous)
        return false;

    // If no src1 has been assigned, then PHV is the src1 information.  If a PHV write and read
    // bits are unaligned, then that PHV field is src1, else either PHV source could be
    // considered src1.
    bool src1_assigned = false;
    if (counts[ActionParam::CONSTANT] > 0) {
        ci.alignment.is_src1 = true;
        src1_assigned = true;
    }
    if (counts[ActionParam::ACTIONDATA] > 0) {
        adi.alignment.is_src1 = true;
        src1_assigned = true;
    }

    if (!src1_assigned) {
        for (auto &tot_align_info : phv_alignment) {
            auto &tot_alignment = tot_align_info.second;
            if (!tot_alignment.aligned()) {
                tot_alignment.is_src1 = true;
                src1_assigned = true;
            }
        }
    }

    if (!src1_assigned) {
        for (auto &tot_align_info : phv_alignment) {
            auto &tot_alignment = tot_align_info.second;
            tot_alignment.is_src1 = true;
            src1_assigned = true;
            break;
        }
    }

    return true;
}

/** For nearly all instructions, the ALU operation acts over all bits in the container.  The only
 *  instruction where this doesn't apply is the deposit-field instruction.  That instruction
 *  can have a portion masked.  Any other operation currently acts on the entire container, and
 *  all fields could be potentially affected.
 */
bool ActionAnalysis::ContainerAction::verify_overwritten(
        const PHV::Container container, const PhvInfo &phv) {
    ordered_set<const PHV::Field*> fieldsWritten;
    for (auto& field_action : field_actions) {
        const PHV::Field* write_field = phv.field(field_action.write.expr);
        if (write_field == nullptr)
            BUG("Verify Overwritten: Action does not have a write?");
        fieldsWritten.insert(write_field); }

    bitvec container_occupancy = phv.bits_allocated(container, fieldsWritten);
    bitvec total_write_bits;
    for (auto &tot_align_info : phv_alignment) {
        total_write_bits |= tot_align_info.second.write_bits;
    }

    total_write_bits |= adi.alignment.write_bits;
    total_write_bits |= ci.alignment.write_bits;
    if (name == "invalidate")
        total_write_bits |= invalidate_write_bits;

    if (total_write_bits != container_occupancy)
        return false;

    if (static_cast<size_t>(total_write_bits.popcount()) != container.size()) {
        error_code |= PARTIAL_OVERWRITE;
    }
    return true;
}


/** Ensure that a read field is the only field within that container
 */
bool ActionAnalysis::ContainerAction::verify_only_read(const PhvInfo &phv) {
    ordered_set<const PHV::Field*> fieldsRead;
    for (auto& field_action : field_actions) {
        const PHV::Field* read_field = nullptr;
        for (auto& read : field_action.reads) {
            if (read_field != nullptr && read.type == ActionParam::PHV) {
                BUG("Multiple reads found in shift");
            }
            if (read.type == ActionParam::PHV)
                read_field = phv.field(read.expr);
            BUG_CHECK(read_field, "Read field not found for shift"); }
        fieldsRead.insert(read_field); }
    BUG_CHECK(fieldsRead.size() == 1, "More than one field action in shift");

    for (auto &tot_align_info : phv_alignment) {
        auto container = tot_align_info.first;
        auto &total_alignment = tot_align_info.second;
        bitvec container_occupancy = phv.bits_allocated(container, fieldsRead);
        if (total_alignment.read_bits != container_occupancy)
            return false;
    }
    return true;
}

void ActionAnalysis::add_to_single_ad_params(ContainerAction &cont_action) {
    const IR::MAU::ActionArg *aa = nullptr;
    for (auto &field_action : cont_action.field_actions) {
        for (auto &param : field_action.reads) {
            le_bitrange aa_range = { 0, 0 };
            aa = isActionArg(param.expr, &aa_range);
            if (aa == nullptr)
                continue;
            auto pair = std::make_pair(aa->name, aa_range);
            if (single_ad_params.count(pair) > 0)
                multiple_ad_params.insert(pair);
            else
                single_ad_params.insert(std::make_pair(aa->name, aa_range));
        }
    }
}

void ActionAnalysis::check_single_ad_params(ContainerAction &cont_action) {
    if (cont_action.field_actions.size() != 1)
        return;
    const IR::MAU::ActionArg *aa = nullptr;
    for (auto &param : cont_action.field_actions[0].reads) {
        le_bitrange aa_range = { 0, 0 };
        aa = isActionArg(param.expr, &aa_range);
        if (aa == nullptr)
            continue;
        if (multiple_ad_params.count(std::make_pair(aa->name, aa_range)) > 0)
            cont_action.error_code |= ContainerAction::UNRESOLVED_REPEATED_ACTION_DATA;
    }
}

/** A verification of the constant used in a ContainerAction to make sure that it can
 *  be used without being converted to action data
 */
bool ActionAnalysis::valid_instruction_constant(unsigned value, int max_shift, int min_shift,
        int complement_size) {
    unsigned max_value = (1U << max_shift);
    unsigned min_value = (1U << min_shift);
    unsigned complement = (0xffffffffU) >> (sizeof(unsigned) * 8 - complement_size);

    if ((value < max_value) || (value >= complement - min_value && value <= complement))
        return true;
    return false;
}

/** A check to guarantee that the use of constant is legal in the action within a container.
 *  The constant does not have to be converted to action data if:
 *
 *  the constant is used in a set instruction
 *      - if the constant covers the whole container, when the container is 8 or 16 bit size
 *      - if the constant covers the whole container, the container is a 32 bit size, and
 *        the constant is between -(2^19) <= value <= 2^19 - 1
 *      - if the constant doesn't cover the whole container, and the constant is between
 *        -8 <= value <= 7
 *
 *  the constant is used in another instruction, where the constant convers the whole container,
 *  and the constant is between -8 <= value <= 7
 *
 *  This range also applies to the complement of the range i.e. an 8 bit container converts to
 *  value >= 255 - 7 OR value < -255 + 8
 *
 *  These ranges are due to instruction formats of load-consts, and one of the src fields in
 *  every instruction
 *
 *  A constant must be converted to action data if it doesn't meet the requirements, or:
 *      - the container also requires action data
 *      - multiple constants are used
 */
void ActionAnalysis::check_constant_to_actiondata(ContainerAction &cont_action,
        PHV::Container container) {
    auto &counts = cont_action.counts;
    if (counts[ActionParam::ACTIONDATA] > 1 && ad_alloc) {
        cont_action.error_code |= ContainerAction::MULTIPLE_ACTION_DATA;
    }

    if (counts[ActionParam::CONSTANT] == 0)
        return;

    if (!cont_action.ci.initialized)
        BUG("Constant not setup by the program correctly");

    if (counts[ActionParam::ACTIONDATA] > 0 && counts[ActionParam::CONSTANT] > 0) {
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
        return;
    }
    unsigned constant_value;

    // Due to the number of sources differing between Tofino and JBay in an action, respectively
    // 16 and 20, the range for instruction constants is different between architectures.
    // For Tofino it is -8..7 but for JBay it is -4..7
    int const_src_min = CONST_SRC_MAX;
#ifdef HAVE_JBAY
    if (Device::currentDevice() == "JBay")
        const_src_min = JBAY_CONST_SRC_MIN;
#endif /* HAVE_JBAY */

    if (cont_action.name == "set" && cont_action.ci.alignment.write_bits.popcount()
                                     == static_cast<int>(container.size())) {
        // Converting to load_const instruction
        constant_value = cont_action.ci.build_constant();
        if (!(valid_instruction_constant(constant_value, LOADCONST_MAX, LOADCONST_MAX,
                                         container.size()))) {
            cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            return;
        }
    } else if (cont_action.name != "set") {
        // Using the constant source directly in a non deposit-field operation
        constant_value = cont_action.ci.build_constant();
        if (!(valid_instruction_constant(constant_value, CONST_SRC_MAX, const_src_min,
                                          container.size()))) {
            cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            return;
        }
    } else if (cont_action.to_bitmasked_set) {
        // Bitmasked-set must be converted to action data
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
        return;
    } else {
        int complement_size = cont_action.ci.alignment.bitrange_size();
        // Set or deposit-field
        constant_value = cont_action.ci.build_shiftable_constant();
        if (!(valid_instruction_constant(constant_value, CONST_SRC_MAX, const_src_min,
                                           complement_size))) {
            cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
        }
        if (constant_value > ((1U << CONST_SRC_MAX) - 1)) {
            cont_action.error_code |= ContainerAction::REFORMAT_CONSTANT;
        }
    }
    cont_action.ci.constant_value = constant_value;
}

void ActionAnalysis::ContainerAction::move_source_to_bit(safe_vector<int> &bit_uses,
        ActionAnalysis::TotalAlignment &ta) {
    for (auto alignment : ta.indiv_alignments) {
        for (int bit = alignment.write_bits.lo; bit <= alignment.write_bits.hi; bit++) {
            bit_uses[bit]++;
        }
    }
}

/** This checks to make sure that all bits are operated correctly, i.e. if the operation is
 *  a set, every bit in the write is either set once or not at all or e.g. add, subtract, or,
 *  each write bit has  either two read bits, or no read bits affecting it (overwrite
 *  constraints are checked in a different verification)
 */
bool ActionAnalysis::ContainerAction::verify_source_to_bit(int operands,
        PHV::Container container) {
    safe_vector<int> bit_uses(container.size(), 0);

    for (auto &phv_ta : phv_alignment) {
        move_source_to_bit(bit_uses, phv_ta.second);
    }

    move_source_to_bit(bit_uses, adi.alignment);
    move_source_to_bit(bit_uses, ci.alignment);

    for (size_t i = 0; i < container.size(); i++) {
        if (!(bit_uses[i] == operands || bit_uses[i] == 0))
            return false;
    }

    return true;
}

/** Each PHV ALU can only pull from a local group of PHVs in an operation.  This guarantees that
 * this clustering constraint is met.
 */
bool ActionAnalysis::ContainerAction::verify_phv_mau_group(PHV::Container container) {
    auto write_container_id = Device::phvSpec().containerToId(container);
    auto write_group = Device::phvSpec().mauGroup(write_container_id);
    for (auto phv_ta : phv_alignment) {
        auto read_container = phv_ta.first;
        auto read_container_id = Device::phvSpec().containerToId(read_container);
        auto read_group = Device::phvSpec().mauGroup(read_container_id);
        if (write_group != read_group)
            return false;
    }
    return true;
}

void ActionAnalysis::ContainerAction::verify_speciality(PHV::Container container,
         cstring action_name) {
    bool speciality_found = false;
    int ad_params = 0;
    for (auto field_action : field_actions) {
        for (auto read : field_action.reads) {
            if (read.type == ActionParam::ACTIONDATA || read.type == ActionParam::CONSTANT)
                ad_params++;
            if (read.speciality != ActionParam::NO_SPECIAL)
                speciality_found = true;
        }
    }
    if (ad_params > 1 && speciality_found)
        P4C_UNIMPLEMENTED("In the ALU operation over container %s in action %s, the packing is "
                          "too complicated due to a too complex container instruction with a "
                          "speciality action data combined with other action data: %s",
                          container.toString(), action_name, *this);
}

/** Due to shifts being fairly unique when it comes to action constraints, a separate function
 *  is required. The following constraints are verified:
 *     - Only one field_action is allowed per container (Not technically a constraint, but
 *       difficult to verify this otherwise
 *     - No action data or constants are allowed as a shift, only one PHV
 *     - The writes and reads are the only fields within their containers (Again not technically
 *       a constraint, but difficult to verify as well)
 */

bool ActionAnalysis::ContainerAction::verify_shift(
        cstring &error_message, PHV::Container container, const PhvInfo &phv) {
    if (field_actions.size() > 1) {
        error_code |= MULTIPLE_SHIFTS;
        error_message += "p4c cannot support multiple shift instructions in one container";
        return false;
    }

    if (has_ad_or_constant()) {
        error_code |= ILLEGAL_ACTION_DATA;
        error_message += "no action data or constant field is allowed in a shift function";
        return false;
    }

    if (counts[ActionParam::PHV] > 1) {
        error_code |= TOO_MANY_PHV_SOURCES;
        error_message += "a shift function can only have one PHV source";
        return false;
    }

    bool total_overwrite_possible = verify_overwritten(container, phv);
    total_overwrite_possible |= verify_only_read(phv);
    if (!total_overwrite_possible) {
        error_code |= ILLEGAL_OVERWRITE;
        error_message += "either a read or write in a shift operation is not the only field "
                         "within a container";
    }
    return true;
}


/** The goal of this function is to validate a container operation given the allocation
 *  the write fields and the sources of the particular operation.  The following checks are:
 *    - If the ALU operation requires too many sources
 *    - If the ALU operation has the wrong number of operands per bit
 *    - If the number of operands matches instruction number
 *    - If the PHV clustering algorithm is incorrect
 *    - If the alignment of the bits are allowed
 *    - If an overwriting operation overwrites the entire container
 *
 *  The reason these constraints exists are due to the Action ALU Instruction Set Architecture.
 *  If any of these are not true, then this instruction is not possible on Tofino.
 */
bool ActionAnalysis::ContainerAction::verify_possible(cstring &error_message,
        PHV::Container container, cstring action_name, const PhvInfo &phv) {
    verify_speciality(container, action_name);
    error_message = "In the ALU operation over container " + container.toString() +
                    " in action " + action_name + ", ";

    bool phv_group_correct = verify_phv_mau_group(container);
    if (!phv_group_correct) {
        error_code |= MAU_GROUP_MISMATCH;
        error_message += "a read phv is in an incompatible PHV group";
        return false;
    }

    if (is_shift()) {
        return verify_shift(error_message, container, phv);
    }

    int actual_ad = ad_sources();
    int sources_needed = counts[ActionParam::PHV] + actual_ad;

    if (sources_needed > 2) {
        if (actual_ad) {  // If action data as a source
            error_code |= PHV_AND_ACTION_DATA;
            error_message += "Action " + action_name + " writes fields using the same assignment "
                "type but different source operands (both action parameter and phv)";
        } else {          // no action data sources
            error_code |= TOO_MANY_PHV_SOURCES;
            error_message += "over 2 PHV sources for the ALU operation are required, thus rendering"
                " the action impossible";
        }
        return false;
    }

    bool source_to_bit_correct = verify_source_to_bit(operands(), container);
    if (!source_to_bit_correct) {
        error_code |= BIT_COLLISION;
        error_message += "every write bit does not have a corresponding "
                         + cstring::to_cstring(operands()) + " or 0 read bits.";
        return false;
    }

    if (name != "set" && sources_needed != operands()) {
        error_code |= OPERAND_MISMATCH;
        error_message += "the number of operands does not match the number of sources";
        return false;
    }

    bitvec ad_bitmask = adi.alignment.write_bits | ci.alignment.write_bits;

    // Bitmasked-set and deposit-field instructions must only be generated for normal PHVs, not dark
    // or mocha PHVs.
    if (container.is(PHV::Kind::normal)) {
        if (sources_needed == 2 && name == "set") {
            to_deposit_field = true;
        }
        if (name == "set" && ad_bitmask.popcount() > 0 && !ad_bitmask.is_contiguous()) {
            to_bitmasked_set = true;
        }
    } else if (container.is(PHV::Kind::mocha) || container.is(PHV::Kind::dark)) {
        bool total_overwrite_possible = verify_overwritten(container, phv);
        if (total_overwrite_possible) {
            error_code |= PARTIAL_OVERWRITE;
        } else {
            error_code |= ILLEGAL_OVERWRITE;
            error_message += "fields bits in container " + cstring::to_cstring(container) + " will "
                             "be overwritten by action " + action_name;
            return false;
        }
    }

    bool can_phv_be_unaligned = (name == "set" && (actual_ad == 0));
    int phv_unaligned = can_phv_be_unaligned ? 1 : 0;

    bool can_ad_be_unaligned = name == "set" && actual_ad > 0 && ad_bitmask.is_contiguous();
    int ad_unaligned = can_ad_be_unaligned ? 1 : 0;

    int single_non_contiguous = name == "set" && !to_bitmasked_set;
    int max_non_contiguous = single_non_contiguous ? 1 : 2;

    bool aligned = verify_alignment(phv_unaligned, ad_unaligned, max_non_contiguous, container);

    if (!aligned) {
        error_code |= IMPOSSIBLE_ALIGNMENT;
        error_message += "the alignment of fields within the container renders the action "
                         "impossible";
        return false;
    }


    if (name != "set" || to_deposit_field) {
        bool total_overwrite_possible = verify_overwritten(container, phv);
        if (!total_overwrite_possible) {
            error_code |= ILLEGAL_OVERWRITE;
            error_message += "the container is not completely overwritten when the operand is "
                             "over the entire container";
            return false;
        }
    } else if (to_bitmasked_set) {
        error_code |= PARTIAL_OVERWRITE;
    }

    return true;
}

void ActionAnalysis::verify_P4_action_for_tofino(cstring action_name) {
    if (phv_alloc)
        verify_P4_action_with_phv(action_name);
    else if (error_verbose)
        verify_P4_action_without_phv(action_name);
}

void ActionAnalysis::postorder(const IR::MAU::Action *act) {
    verify_P4_action_for_tofino(act->name);
}
