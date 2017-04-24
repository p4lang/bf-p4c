#include "action_format.h"
#include "lib/log.h"

constexpr int ActionFormat::CONTAINER_SIZES[];

bool ArgumentAnalyzer::preorder(const IR::MAU::Action *af) {
    action_args.clear();
    arg_map.clear();
    ActionFormat::ArgInfo arg_info;

    for (auto arg : af->args) {
        action_args.push_back(arg->toString());
        arg_map.emplace(arg->toString(), arg_info);
    }
    return true;
}

bool ArgumentAnalyzer::preorder(const IR::Primitive *prim) {
    LOG3("Not handling action arguments in unhandled prim " << prim->name);
    return false;
}

/** Only want to gather information on Instructions, and not primitives in MAU::Action
 *  such as count, as those don't contain primitives that we need
 */
bool ArgumentAnalyzer::preorder(const IR::MAU::Instruction *) {
    instr_used.clear();
    fields_used.clear();
    return true;
}

/** Save the locations of the action arguments and the corresponding fields that they use
 */
bool ArgumentAnalyzer::preorder(const IR::Expression *e) {
    if (phv.field(e) && isWrite()) {
        fields_used.push_back(phv.field(e));
    } else {
        auto loc = std::find(action_args.begin(), action_args.end(), e->toString());
        if (loc != action_args.end()) {
            instr_used |= bitvec(loc - action_args.begin(), 1);
        }
    }
    return false;
}

void ArgumentAnalyzer::postorder(const IR::MAU::Instruction *) {
    for (auto position : instr_used) {
        arg_map[action_args[position]].append(fields_used);
    }
}


/** Create the ActionDataPlacement before PHV allocation has been completed.  Essentially 
 *  base the container size guess on specifically the width of the ActionArg.  If the argument
 *  is greater than the size of the largest container, break it into multiple containers.  
 *  This then generates the action data format
 *
 *  The container provided to the action data is the smallest container it can fit into.
 *  If the field is larger than 32 bits, say N where 2 * 32 < N < 3 * 32, then N is given two
 *  32 bit containers, and N - 64 bits determines the size of the small container.  This is
 *  an easy best estimate for PHV allocation
 */
void ArgumentAnalyzer::parse_container_non_phv(const IR::MAU::Action *af) {
    vector<ActionFormat::ActionDataPlacement> overlaps;
    for (auto arg_entry : arg_map) {
        auto arg_name = arg_entry.first;
        auto &arg_info = arg_entry.second;
        auto loc = std::find(action_args.begin(), action_args.end(), arg_name);
        if (loc == action_args.end())
            BUG("Action arg was added to the Argument Map even though never used within the "
                 "action call");
        int index = loc - action_args.begin();
        int arg_width = af->args[index]->type->width_bits();

        if (arg_info.fields.size() == 0) continue;

        for (auto *field : arg_info.fields) {
            if (field->size != arg_width)
                ERROR("Width and Information don't align");
            vector<std::pair<int, bitvec>> container_sizes;
            int starting_width = arg_width;
            while (starting_width > 32) {
                container_sizes.emplace_back(32, bitvec(0, 32));
                starting_width -= 32;
            }
            int container_size = (1 << ceil_log2(starting_width));
            container_size = container_size < 8 ? 8 : container_size;
            container_sizes.emplace_back(container_size, bitvec(0, starting_width));
            arg_info.append(container_sizes);
        }

        int start = 0;
        for (auto cont_pair : arg_info.act_bus_reqs[0]) {
            LOG3("Container information: " << arg_name << " " << cont_pair.second << " " << start);
            ActionFormat::ActionDataPlacement adp;
            adp.arg_locs.emplace_back(arg_name, cont_pair.second, start);
            adp.size = cont_pair.first;
            adp.range = cont_pair.second;
            start += cont_pair.first;
            overlaps.push_back(adp);
        }
    }
    use->action_data_format[af->name] = overlaps;
    use->arguments[af->name] = arg_map;
}

/** Creates the initial ActionDataPlacement after PHV allocation has been completed.  For each
 *  ActionArg used, this code examines the containers used by the fields affected by this
 *  ActionArg.  The code saves this information, checks if these constraints are too difficult
 *  to allocate to in the first iteration of action data formatting, and then from this
 *  information creates the ActionDataPlacement for all the containers affected.  As
 *  containers may be affected by multiple fields, this only allocates the space for one
 *  container
 */
void ArgumentAnalyzer::parse_container_phv(const IR::MAU::Action *af) {
    vector<ActionFormat::ActionDataPlacement> overlaps;
    std::map<const PHV::Container, ContainerInfo> container_info;

    // Gather every container's information
    for (auto arg_entry : arg_map) {
        auto arg_name = arg_entry.first;
        auto &arg_info = arg_entry.second;
        for (auto *field : arg_info.fields) {
            field->foreach_alloc([&](const PhvInfo::Field::alloc_slice &sl) {
                if (sl.container.size() != 32 && sl.container.size() != 16
                    && sl.container.size() != 8) {
                    ERROR("PHV not allocated for " << field->name);
                } else {
                    auto &ci = container_info[sl.container];
                    ci.sections.emplace_back(arg_name, sl.field_bit, sl.container_bit, sl.width);
                }
            });
        }
    }

    // Check if there are weird overlaps of PHVs that are not yet handled
    for (auto arg_entry : arg_map) {
        auto &arg_info = arg_entry.second;
        if (arg_info.fields.size() == 1) continue;

        vector<std::pair<int, int>> container_sets;
        bool already_tested = false;
        for (auto *field : arg_info.fields) {
            size_t index = 0;
            field->foreach_alloc([&](const PhvInfo::Field::alloc_slice &sl) {
                if (container_info.at(sl.container).sections.size() > 1) {
                    // FIXME: Todo this section. Argument accesses two fields that have other
                    // fields in them.
                    BUG("PHV layout for an action too complex to handle");
                }
                if (!already_tested) {
                    container_sets.emplace_back(sl.container.size(), sl.width);
                } else {
                    if (index >= container_sets.size()
                        || container_sets[index].first != static_cast<int>(sl.container.size())
                        || container_sets[index].second != sl.width) {
                        // FIXME: Also todo.  When a argument accesses separate fields with
                        // different PHV layouts
                        BUG("PHV layout for an aciton to complex to handle");
                    }
                    container_info.at(sl.container).shared = true;
                }
                index++;
            });
        }
    }

    // Generate the ActionDataPlacement for every single container
    for (auto ci : container_info) {
        auto &cont = ci.first;
        auto &info_vec = ci.second;
        bitvec total_mask;
        if (info_vec.shared) continue;
        for (auto sl : info_vec.sections) {
            total_mask |= bitvec(sl.container_bit, sl.width);
        }
        ActionFormat::ActionDataPlacement placement;
        for (auto sl : info_vec.sections) {
            placement.arg_locs.emplace_back(sl.arg_name, bitvec(sl.container_bit, sl.width),
                                            sl.field_bit);
        }

        placement.range = total_mask;
        placement.size = cont.size();
        overlaps.push_back(placement);
    }

    use->action_data_format[af->name] = overlaps;
    use->arguments[af->name] = arg_map;
    // Have to still step up ArgMap, used more for action bus and asm output
}

void ArgumentAnalyzer::postorder(const IR::MAU::Action *af) {
    if (alloc_done)
        parse_container_phv(af);
    else
        parse_container_non_phv(af);
}



void ActionFormat::ActionContainerInfo::reset() {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        counts[i] = 0; layouts[i].clear();
        minmaxes[i] = CONTAINER_SIZES[i] + 1;
    }
}

void ActionFormat::ActionContainerInfo::finalize_min_maxes() {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        minmaxes[i] = minmaxes[i] == (CONTAINER_SIZES[i] + 1) ? 0 : minmaxes[i];
    }
}

int ActionFormat::ActionContainerInfo::find_maximum_immed() {
    int max_byte = counts[BYTE] > 0 ? (counts[BYTE] - 1) * 8 + minmaxes[BYTE] : 0;
    int max_half = counts[HALF] > 0 ? (counts[HALF] - 1) * 16 + minmaxes[HALF] : 0;
    int max_full = counts[HALF] > 0 ? (counts[FULL] - 1) * 32 + minmaxes[FULL] : 0;
    int maximum = 0;

    if (max_byte > 0 && max_half > 0) {
        if (max_byte > max_half) {
            order = FIRST_8;
            maximum = max_half + 16;
        } else {
            order = FIRST_16;
            maximum = max_byte + 16;
        }
    } else {
        order = NOT_SET;
        maximum = std::max(std::max(max_byte, max_half), max_full);
    }
    return maximum;
}

/** The allocation scheme for the action data format and immediate format.
 */
void ActionFormat::allocate_format(Use *u) {
    LOG2("Allocating Table Format for " << tbl->name);
    use = u;
    analyze_all_actions();
    LOG2("Analysis finished");

    if (immediate_possible) {
        setup_immediate_format();
        LOG2("Immediate format setup " << tbl->name);
    }

    space_all_containers();
    LOG2("Space all containers");
    align_action_data_layouts();
    LOG2("Alignment");


    if (immediate_possible) {
        action_counts.clear();
        setup_action_counts(true);
        LOG2("Setup immediate containers");
        space_all_immediate_containers();
        LOG2("Space immediate containers");
        align_immediate_layouts();
        LOG2("Alignment immediate");
    }
}

/** Performs the argument analyzer and initializes the vector of ActionContainerInfo
 */
void ActionFormat::analyze_all_actions() {
    for (auto action : Values(tbl->actions)) {
        action->apply(ArgumentAnalyzer(phv, use, alloc_done));
    }

    setup_action_counts(false);

    if (max_bytes <= 4)
        immediate_possible = true;
}

/** Based on the container information found in the ActionDataPlacement, determines the number of
 *  8, 16, and 32 bit action data slots need for each individual action.  These values are also
 *  maximized in the max_total ActionContainerInfo, as the action data table must have the maximum
 *  of each of these action data slot reserved.  For immediate data, the minmax of the length
 *  of the container is saved.  Essentially the minimum of each container is saved, and the maximum
 *  minimum is saved in max total
 */
void ActionFormat::setup_action_counts(bool immediate) {
    max_total.reset();
    max_total.finalize_min_maxes();
    for (auto action : Values(tbl->actions)) {
        ActionContainerInfo aci;
        aci.action = action->name;
        auto *placement_vec = &(use->action_data_format.at(action->name));
        if (immediate)
            placement_vec = &(use->immediate_format.at(action->name));
        int index = 0;
        // Build the ACI;
        for (auto container : *placement_vec) {
            bool odd_container_size = true;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                if (container.size == CONTAINER_SIZES[i]) {
                    aci.counts[i]++;
                    if (aci.minmaxes[i] > container.range.max().index() + 1)
                        aci.minmaxes[i] = container.range.max().index() + 1;
                    odd_container_size = false;
                    break;
                }
            }
            if (odd_container_size)
                BUG("What happened here?");
            index++;
        }
        // Analysis of the ACI
        if (max_bytes < aci.total_bytes())
            max_bytes = aci.total_bytes();

        aci.finalize_min_maxes();
        if (immediate) {
            max_total.maximum = std::max(max_total.maximum, aci.find_maximum_immed());
        } else {
            max_total.maximize(aci);
        }
        action_counts.push_back(aci);
    }
}

/** Very basically saves all of the information into the immediate placement.  At later revision
 *  of action format, we can potentially split data between immediate and action data table, and
 *  some intelligence will have to go into that
 */
void ActionFormat::setup_immediate_format() {
    for (auto action_placement : use->action_data_format) {
        auto name = action_placement.first;
        auto placement_vec = action_placement.second;
        use->immediate_format[name] = placement_vec;
    }
}


/** For non-overlapping action data formats:
 *     - Algorithm finds locations of 8's and 16's first
 *     - Go through the fields in needs of 32 bit containers most to least
 *     - Essentially by knowing how many actions require 32 bit containers, we now know that
 *       how many 32 byte chunks we have to pack this 8 and 16 bit container chunks into
 *     -

 *  General algorithm for action data table:
 *  The general thought process is to put the 8 bit data closer to the lsb and the 16 bits
 *  closer to the msb of the action data format.  Then because 32s can potentially overlap
 *  locations on the action data bus, fit the 32 bit containers at the most optimal place for
 *  each individual action.  Thus if the max requirements for a table are 4 8 bit and 2 16 bit
 *  actions, the layout will look like:
 *  
 *  lsb: 8 8 8 8 16 16 msb

 *  The major issue with this algorithm can be described by the following scenario.  Say we have two
 *  actions with the following action data layouts:

 *  8 8 8 8 16 16
 *  8 8 16  32

 *  Now if I allocate the second action containers to be aligned with the first containers, then
 *  I cannot fit the 32 bit container, as it has to be 32 bit aligned.  Thus an action that
 *  meets this offset constraint has two requirements.  First, the counts[BYTE] % 4 == 1 or 2
 *  and the counts[HALF] % 2 == 1, and second, the action must require all FULL words to be
 *  fully needed.
 */

/** This function checks to see which actions have the 8 8 16 constraint, marks these actions,
 *  and then calculates the total layouts based upon the maximum constraint as well as the
 *  8 8 16 constraint.
 */
int ActionFormat::offset_constraints_and_total_layouts() {
    int max_offset_constraint = 0;
    for (auto &aci : action_counts) {
        if (((aci.counts[BYTE] % 4) == 1 || (aci.counts[BYTE] % 4) == 2)
             && (aci.counts[HALF] % 4) == 1) {
            if (aci.total_bytes() + 1 >= (1 << ceil_log2(max_bytes))) {
                aci.offset_constraint = true;
                if (max_offset_constraint < (aci.counts[BYTE] % 4)) {
                    max_offset_constraint = (aci.counts[BYTE] % 4);
                }
            }
        }
    }

    int max_small_bytes = max_total.counts[BYTE] + max_total.counts[HALF] * 2;
    max_small_bytes = (max_small_bytes + 3) & ~(0x3);
    if (max_small_bytes > (1 << ceil_log2(max_bytes)))
        max_small_bytes = (1 << ceil_log2(max_bytes));

    int highest_8_full = max_total.counts[BYTE] / 4;
    int lowest_16_full = (max_small_bytes - max_total.counts[HALF] * 2) / 4;

    bitvec offset_locs;

    // Essentially find the location of the 8 16 split
    for (auto &aci : action_counts) {
        if (!aci.offset_constraint) continue;

        int aci_lowest_16_full = (max_small_bytes - max_total.counts[HALF] * 2) / 4;
        if (aci_lowest_16_full == lowest_16_full)
            aci.offset_full_word = lowest_16_full;
        else
            aci.offset_full_word = highest_8_full;
        offset_locs.setbit(aci.offset_full_word);
        // FIXME: This needs to check at the next PR if the 32 things are paired for bitmasked sets
    }

    total_layouts[BYTE].setrange(0, max_total.counts[BYTE]);
    int starting_16_loc = max_small_bytes - max_total.counts[HALF] * 2;
    total_layouts[HALF].setrange(starting_16_loc, max_total.counts[HALF] * 2);

    for (auto full_word : offset_locs) {
        total_layouts[BYTE].setrange(full_word * 4, 2);
        total_layouts[HALF].setrange(full_word * 4 + 2, 2);
    }
    return max_small_bytes;
}

/** Based on the total layouts calculated, and whether the ActionContainerInfo contains that
 *  8 8 16 constraint, this function selects the bytes that each action will use in the
 *  action data format.  This is done by the examination of the total layouts
 */
void ActionFormat::space_8_and_16_containers(int max_small_bytes) {
    for (auto &aci : action_counts) {
        int count_byte = aci.counts[BYTE];
        int count_half = aci.counts[HALF];
        if (aci.offset_constraint) {
            count_byte -= 2;
            count_half -= 1;
        }

        // Coordinate this to total layouts
        for (int i = 0; i < count_byte; i++) {
            aci.layouts[BYTE].setbit(i);
        }

        for (int i = 0; i < count_half; i++) {
            aci.layouts[HALF].setrange(max_small_bytes - 2 * i - 2, 2);
        }

        if (aci.offset_constraint) {
            aci.layouts[BYTE].setrange(aci.offset_full_word * 4, 2);
            aci.layouts[HALF].setrange(aci.offset_full_word * 4 + 2, 2);
        }

        LOG3("Aci layouts for action " << aci.action << " BYTE: "
             << aci.layouts[BYTE] << " HALF: " << aci.layouts[HALF]);

        if ((aci.layouts[BYTE] & aci.layouts[HALF]).popcount() != 0)
            BUG("Collision between bytes and half word on action data format");

        if ((total_layouts[BYTE] & aci.layouts[BYTE]).popcount() < aci.counts[BYTE])
            BUG("Error in the spread of bytes in action data format");

        if ((total_layouts[HALF] & aci.layouts[HALF]).popcount() < aci.counts[HALF] * 2)
            BUG("Error in the spread of half words in action data format");
    }
}

/** This function just fills in all of the 32 bit holes for each individual action.  Because
 *  the 32 bits can potentially overlap with either 8 or 16 bit containers, the algorithm can
 *  be more cavalier about where it places the 32 bit action data
 */
void ActionFormat::space_32_containers() {
    for (auto &aci : action_counts) {
        bitvec combined = aci.layouts[BYTE] | aci.layouts[HALF];
        int count_full = aci.counts[FULL];
        for (int i = (1 << ceil_log2(max_bytes)) - 4; i >= 0; i -= 4) {
            if (count_full == 0) break;
            if (combined.getrange(i, 4) != 0)
                continue;
            aci.layouts[FULL].setrange(i, 4);
            count_full--;
        }
        if (count_full != 0)
            BUG("Could not allocate all full words in action data format");
    }
}

/** The container allocation algorithm for the action data tables
 */
void ActionFormat::space_all_containers() {
    if (max_bytes == 0)
        return;
    int max_small_bytes = offset_constraints_and_total_layouts();
    space_8_and_16_containers(max_small_bytes);
    space_32_containers();
}

/** This function links the action data arguments with containers spaced out for the action.
 *  Action arguments know their size and linked with the correct size.  The information contained
 *  in the ActionDataPlacement may result in the adjustment of the instructions within a pass after
 *  PHV allocation.
 */
void ActionFormat::align_action_data_layouts() {
    for (auto aci : action_counts) {
        int starts[CONTAINER_TYPES] = {0, 0, 0};
        auto &placement_vec = use->action_data_format[aci.action];
        for (auto &container : placement_vec) {
            int index = container.gen_index();
            int loc = aci.layouts[index].ffs(starts[index]);
            if (aci.layouts[index].getrange(loc, container.size / 8) == 0)
                BUG("Misalignment on the action data format");
            container.start = loc * 8;
            starts[index] = loc + container.size / 8;
        }
        std::sort(placement_vec.begin(), placement_vec.end(),
                [](const ActionDataPlacement &a, const ActionDataPlacement &b) {
            if (a.start == b.start) {
                BUG("Two containers in the same action are at the same place?");
            }

            if ((a.start + a.size / 8 - 1 > b.start && b.start > a.start)
                || (b.start + b.size / 8 - 1 > a.start && a.start > b.start)) {
                BUG("Two containers overlap in the same action");
            }
            return a.start < b.start;
        });
        int index = 0;
        for (auto &container : placement_vec) {
            if (container.arg_locs.size() > 1) {
                container.asm_name = "$data" + std::to_string(index);
                index++;
            } else if (container.arg_locs.size() == 1) {
                container.asm_name = container.arg_locs[0].name;
            } else {
                container.asm_name = "$no_arg";
            }
        }
    }
    if (max_bytes != 0)
        use->action_data_bytes = (1 << ceil_log2(max_bytes));
}

/** The algorithm for immediate is much simpler.  Instead of trying to best pack the action data
 *  bytes, the overarching goal in iteration 1 is to simply just minimize the number of bits
 *  needed to be stored for an action data, as you can do bit alignment in the shift and mask
 *  portion of match central.  Because action data in the immediate is limited to 32 bits, this
 *  also makes this algorithm simple.
 *
 *  The only difficult action data is actions that contain 16 bit and 8 bit action data.  The
 *  algorithm must decide which action data comes first within the immediate format. 
 *
 *  This algorithm could be improved by taking a more global view of the containers.  However,
 *  because the immediate data is small and doesn't require that many action data bus slots,
 *  it wasn't worth it on the first iteration.
 */
void ActionFormat::space_individ_immed(ActionContainerInfo &aci) {
    if (aci.order == ActionContainerInfo::FIRST_8 || aci.order == ActionContainerInfo::FIRST_16) {
        int first = HALF; int second = BYTE;
        if (aci.order == ActionContainerInfo::FIRST_8) {
            first = BYTE;
            second = HALF;
        }
        if (aci.counts[first] > 0)
            aci.layouts[first] |= bitvec(0, aci.counts[first] * (CONTAINER_SIZES[first] / 8));
        else
             BUG("Should never be reached");
        if (aci.counts[second] > 0)
            aci.layouts[second] |= bitvec(2, aci.counts[second] * (CONTAINER_SIZES[second] / 8));
        else
            BUG("Should never be reached");
    } else {
        // TODO: Could do even better byte packing potentially, not currently saving a byte
        for (int i = 0; i < CONTAINER_TYPES; i++) {
            if (aci.counts[i] > 0) {
                aci.layouts[i] |= bitvec(0, aci.counts[i] * CONTAINER_SIZES[i] / 8);
            }
        }
    }

    if ((aci.layouts[BYTE] & aci.layouts[HALF] & aci.layouts[FULL]).popcount() != 0)
        BUG("Erroneous layout of immediate data");

    for (int i = 0; i < CONTAINER_TYPES; i++)
        total_layouts_immed[i] |= aci.layouts[i];
}


/** Simply find the action data formats for immediate data for every single action */
void ActionFormat::space_all_immediate_containers() {
    std::sort(action_counts.begin(), action_counts.end(),
            [](const ActionContainerInfo &a, const ActionContainerInfo &b) {
        int t;
        if (a.order != ActionContainerInfo::NOT_SET && b.order == ActionContainerInfo::NOT_SET)
            return true;
        if (b.order == ActionContainerInfo::NOT_SET && a.order != ActionContainerInfo::NOT_SET)
            return false;
        if ((t = a.counts[HALF] - b.counts[HALF]) != 0)
            return t > 0;
        if ((t = a.minmaxes[HALF] - b.minmaxes[HALF]) != 0)
            return t > 0;
        if ((t = a.counts[BYTE] - b.counts[BYTE]) != 0)
            return t > 0;
        return a.minmaxes[BYTE] > b.minmaxes[BYTE];
    });


    for (auto &aci : action_counts) {
        space_individ_immed(aci);
    }
}

/* Similar to the align action data format, this aligns the immediate container allocation of
 *  an action to the actual arguments.  Because we are trying to minimize immediate length,
 *  the algorithm puts the containers that require the least amount of size to the back.
 *
 *  At the end of the algorithm, a bitvec describing the immediate format is calculated.
 *  This is also suboptimal, as you could potentially optimally search for the best immediate
 *  format in the number of holes one could potentially have
 */
void ActionFormat::align_immediate_layouts() {
    for (auto aci : action_counts) {
        int starts[CONTAINER_TYPES] = {0, 0, 0};
        bool already_maxed[CONTAINER_TYPES] = {false, false, false};
        auto &placement_vec = use->immediate_format.at(aci.action);
        for (auto &container : placement_vec) {
            int index = container.gen_index();
            if (container.range.max().index() + 1 == aci.minmaxes[index]
                && !already_maxed[index]) {
                int start = aci.layouts[index].max().index();
                start -= (CONTAINER_SIZES[index] / 8) - 1;
                container.start = start;
                already_maxed[index] = true;
            } else {
                int loc = aci.layouts[index].ffs(starts[index]);
                if (aci.layouts[index].getrange(loc, container.size / 8) == 0)
                    BUG("Misalignment on the immediate data format");
                container.start = loc;
                starts[index] = loc + container.size / 8;
            }
        }
        std::sort(placement_vec.begin(), placement_vec.end(),
                [](const ActionDataPlacement &a, const ActionDataPlacement &b) {
            if (a.start == b.start) {
                BUG("Two containers in the same action are at the same place?");
            }
            return a.start < b.start;
        });
        int index = 0;
        for (auto &container : placement_vec) {
            if (container.arg_locs.size() > 1) {
                container.asm_name = "$data" + std::to_string(index);
                index++;
            } else if (container.arg_locs.size() == 1) {
                container.asm_name = container.arg_locs[0].name;
            } else {
                container.asm_name = "$no_arg";
            }
            for (auto arg_loc : container.arg_locs) {
                use->immediate_mask |= (arg_loc.data_loc << (container.start * 8));
            }
        }
    }
    if (tbl->layout.no_match_data()) {
        auto max = use->immediate_mask.max();
        if (max != use->immediate_mask.end())
            use->immediate_mask.setrange(0, max.index());
    }
    LOG3("Immediate mask calculated is " << use->immediate_mask);
}
