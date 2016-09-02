#include "table_statistics.h"
#include "lib/log.h"
#include "lib/bitops.h"

#define RAM_WIDTH 128
#define RAM_ROWS 1024
#define GHOST_BITS 10
#define VERSION_BITS 4
#define BYTE 8

/* This just gathers information on the table size provided by the user
   This is very arbitrary.  The min_size and max_size could easily be 
   better tested.  */
/*
static int find_size(const IR::V1Table *tbl) {
    if (>min_size == 0 && tbl->max_size == 0 && tbl->size) 
        return 0;
    else if (tbl->size)
        return tbl->size;
    else if (tbl->min_size && tbl->max_size)
        return (tbl->min_size + tbl->max_size) / 2;
    else if (tbl->min_size)
        return tbl->min_size * 2;
    else
        return tbl->max_size / 2;
}
*/

std::ostream &operator<<(std::ostream &out, const MatchTableOption &mto)
{
    auto save = out.flags();
    out << std::endl;
    out << "  Entries per row: " << mto.entries_per_row << std::endl;
    out << "  Table Width: " << mto.table_width << std::endl;
    out << "  Utilization: " << mto.utilization << std::endl;
    out << "  Min RAMS: "    << mto.min_mems_used << std::endl;
    out << "  Max RAMS: "    << mto.max_mems_used;

    out.flags(save);
    return out;
}

static int find_min_size(const IR::V1Table *tbl) {
    if (tbl->min_size != 0)
        return tbl->min_size;
    if (tbl->size != 0)
        return tbl->size;
    if (tbl->max_size != 0)
        return tbl->max_size;
    return 0;
}

static int find_max_size(const IR::V1Table *tbl) {
    if (tbl->max_size != 0)
        return tbl->max_size;
    if (tbl->size != 0)
        return tbl->size;
    if (tbl->min_size != 0)
        return tbl->min_size;
    return 0;
}

/*  This calculates the number of RAMS/TCAMs potentially needed by the 
    particular match tables.  These are high estimates, and does not try
    to efficiently pack the tables in.  Instead it just calculates how many
    RAMs are potentially shared among the tables that aren't sized.
 */
static bool gather_match_stats(const IR::V1Table *tbl, TableStats &tstats, RamsForKb &unk_size,
                               MatchGather &table_info) {
    bool is_ternary = false;
    unk_size.is_ternary = false;
    for (auto t : tbl->reads_types) {
        if (t == "ternary" || t == "lpm") {
            is_ternary = true;
            unk_size.is_ternary = true;
            break; } }

    if (is_ternary)
         tstats.tcam_tables_count++;
    else
         tstats.sram_tables_count++;

    int match_width_bits = 0;
    int ixbar_bytes = 0;
    if (tbl->reads) {
        for (auto r : *tbl->reads) {
            if (auto mask = r->to<IR::Mask>()) {
                auto mval = mask->right->to<IR::Constant>();
                match_width_bits += bitcount(mval->value);
                if (!is_ternary)
                    ixbar_bytes += (mask->left->type->width_bits()+7)/8;
            } else if (auto prim = r->to<IR::Primitive>()) {
                if (prim->name != "valid")
                    BUG("unexpected reads expression %s", r);
                match_width_bits += 1;
            } else if (r->is<IR::Member>() || r->is<IR::Slice>()) {
                match_width_bits += r->type->width_bits();
                if (is_ternary)
                    ixbar_bytes += (r->type->width_bits() + 7)/8;
            } else {
                BUG("unexpected reads expression %s", r); } } }
    int overhead_bits = ceil_log2(tbl->actions.size());
    overhead_bits += VERSION_BITS;

    table_info.match_bits = match_width_bits;
    table_info.overhead_bits = overhead_bits;
    match_width_bits -= GHOST_BITS;

    //This section could be a place for small table analysis
    //The entry is so short that all entries would fit within one RAM
    if (match_width_bits <= 0) {
        tstats.min_srams_known++;
        tstats.max_srams_known++;
        tstats.small_sram_tables++;
        return true;
    }

    if (!is_ternary) {
         
        int high_scale = (match_width_bits + overhead_bits) / RAM_WIDTH;
        int min_size = find_min_size(tbl);
        int max_size = find_max_size(tbl);
        // If all of the match bits do not fit within one row of the RAM.
        // Need to perhaps justify this with ways.  Very small entries still need a high # of
        // ways, and thus need perhaps more information
        if (high_scale) {
             int RAMS_per_1k = (match_width_bits + overhead_bits + RAM_WIDTH - 1) / RAM_WIDTH;
             if (min_size) {
                 int min_RAMS_required = (min_size + RAM_ROWS - 1) / RAM_ROWS * RAMS_per_1k;
                 tstats.min_srams_known += min_RAMS_required;
                
                 int max_RAMS_required = (max_size + RAM_ROWS - 1) / RAM_ROWS * RAMS_per_1k;
                 tstats.max_srams_known += max_RAMS_required;

                 return true; 
             } else {
                 tstats.unknown_sram_tables++;
                 unk_size.match = (double) high_scale;
                 return false;
             }
         
        } else {            
            // If at least one entry can fit within the RAM.  May need to be calibrated for
            // small # of ways
            int kbs_per_RAM = RAM_WIDTH / (match_width_bits + overhead_bits);
            /*if (kbs_per_RAM == 1)
               ways = 4;
            else if (kbs_per_RAM == 2 || kbs_per_RAM == 3)
               ways = 2;
            else
               ways = 1;
            */
            if (min_size) { 
                int min_RAMS_required = (min_size + RAM_ROWS - 1) / RAM_ROWS;
                min_RAMS_required = (min_RAMS_required + kbs_per_RAM - 1) / kbs_per_RAM;
                tstats.min_srams_known += min_RAMS_required; 
               
                int max_RAMS_required = (max_size + RAM_ROWS - 1) / RAM_ROWS;
                max_RAMS_required = (max_RAMS_required + kbs_per_RAM - 1) / kbs_per_RAM;
                tstats.max_srams_known += max_RAMS_required;
           
                return true;

            } else {
                tstats.unknown_sram_tables++;
                unk_size.match = 1 / (double) (kbs_per_RAM);
                return false; }
        }
    } 
    return true;
}

static void gather_action_stats(const IR::MAU::Table *tbl, TableStats &tstats, 
                                RamsForKb &unk_size, ActionTableOption &ao) { 
    LOG3("Starting gathering action statistics");
    size_t max_action_data_bytes = 0;
    for (auto action : Values(tbl->actions)) {
        size_t action_data_bytes = 0;
        //Any particular reason actions have to be byte aligned?
        for (auto arg : action->args)
            action_data_bytes += (arg->type->width_bits() + 7) / 8U;
        if (action_data_bytes > max_action_data_bytes)
            max_action_data_bytes = action_data_bytes; }

    ao.action_bytes = max_action_data_bytes;
   
    if (max_action_data_bytes) {
        int action_entry_size = 1 << ceil_log2(BYTE * max_action_data_bytes);
        //Actions must be at least a byte wide
        int high_scale = action_entry_size / RAM_WIDTH;
        int min_size = find_min_size(tbl->match_table);
        int max_size = find_max_size(tbl->match_table);

        //Action entry is >= than RAM width
        if (high_scale) {


            ao.entries_per_row = 1;
            ao.table_width = high_scale;
            if (min_size) {
                int min_RAMS_required = (min_size + RAM_ROWS - 1) / RAM_ROWS * high_scale;
                tstats.min_srams_known += min_RAMS_required;

                int max_RAMS_required = (max_size + RAM_ROWS - 1) / RAM_ROWS * high_scale;
                tstats.max_srams_known += max_RAMS_required;

            } else {
                unk_size.action = (double) high_scale;
            }

        //Action entry is < than RAM width 
        } else {

            int kbs_per_RAM = RAM_WIDTH / action_entry_size;
            ao.entries_per_row = kbs_per_RAM;
            ao.table_width = 1;

            if (min_size) {

                int min_RAMS_required = (min_size + RAM_ROWS - 1) / RAM_ROWS;
                min_RAMS_required = (min_RAMS_required + kbs_per_RAM - 1) / kbs_per_RAM;
                ao.min_mems_used = min_RAMS_required;
                tstats.min_srams_known += min_RAMS_required;

                int max_RAMS_required = (min_size + RAM_ROWS - 1) / RAM_ROWS;
                max_RAMS_required = (max_RAMS_required + kbs_per_RAM - 1) / kbs_per_RAM;
                ao.max_mems_used = max_RAMS_required;
                tstats.max_srams_known += max_RAMS_required;

            } else {
                unk_size.action = action_entry_size / ((double) RAM_WIDTH);
            }
        }
    
        
    }    
    //Actions have to be stored in power of 2 storage areas?  Assume every match table gets an
    //independent SRAM to hold the information on i
}

static void calculate_packing_options(const IR::MAU::Table *tbl, TableStats &tstats, 
                                      MatchGather &table_info, ActionTableOption &ao) {
    PackingOptions po;

    po.table_info = table_info;
    po.action = ao;

    int match_bytes = (table_info.match_bits - GHOST_BITS) / BYTE + 1;
    int wasted_bits = match_bytes * BYTE - (table_info.match_bits - GHOST_BITS);

    int min_size = find_min_size(tbl->match_table);
    int max_size = find_max_size(tbl->match_table);

    LOG3(" The bytes required for a match is " << match_bytes << " as the match bits is "
          << table_info.match_bits);
    LOG3(" The min size is " << min_size << " and the max size is " << max_size);
    /* Find the layouts that don't contain immediate data */
    for (int i = 1; i < 10; i++) {
        LayoutOption lo;
        
        int necessary_width = (match_bytes * BYTE + table_info.overhead_bits) * i / RAM_WIDTH + 1;
 
        /* Overhead data besides the version data has to be less than 64 */
        while ((table_info.overhead_bits - VERSION_BITS) * i > 64 * necessary_width) {
            necessary_width++;
        }

        if (necessary_width > 8) {
            i = 10; break;
        }

        lo.match.entries_per_row = i;
        lo.match.table_width = necessary_width;
        lo.match.action_necessary = true;
        lo.match.utilization = ((double) (table_info.match_bits - GHOST_BITS) * i ) / 
                                (RAM_WIDTH * necessary_width);
        if (min_size) {
            int entry_count = i * RAM_ROWS; 
            lo.match.min_mems_used = (min_size + entry_count -1) / entry_count;
            lo.match.min_mems_used *= necessary_width;
            lo.match.max_mems_used = (max_size + entry_count - 1) / entry_count;
            lo.match.max_mems_used *= necessary_width;
        }

        LOG3(" The number of entries is " << i);
        LOG3(" The layout option is " << lo.match); 
        po.packing_structs.push_back(lo);
    }

    /* Immediate action data fits within 32 bits, test these layouts */
    if (ao.action_bytes <= 4) {
        for (int i = 1; i < 10; i++) {
            LayoutOption lo;
            int entry_bits = ((match_bytes + ao.action_bytes) * BYTE + table_info.overhead_bits);
            int necessary_width = entry_bits * i / RAM_WIDTH + 1;


            /* Overhead data besides the version data has to be less than 64 */
            while ((table_info.overhead_bits - VERSION_BITS + ao.action_bytes * BYTE) * i 
                    > 64 * necessary_width) {
                necessary_width++;
            }

            if (necessary_width > 8) {
                i = 10; break;
            }

            lo.match.entries_per_row = i;
            lo.match.table_width = necessary_width;
            lo.match.action_necessary = false;
            lo.match.utilization = ((double) (table_info.match_bits - GHOST_BITS) * i ) / 
                                    (RAM_WIDTH * necessary_width);
            if (min_size) {
                int entry_count = i * RAM_ROWS; 
                lo.match.min_mems_used = (min_size + entry_count -1) / entry_count;
                lo.match.min_mems_used *= necessary_width;
                lo.match.max_mems_used = (max_size + entry_count - 1) / entry_count;
                lo.match.max_mems_used *= necessary_width;
            }
    
            LOG3(" The number of entries is " << i);
            LOG3(" The layout option is " << lo.match); 
            po.packing_structs.push_back(lo);
           
        }
    }

    tstats.options[tbl->name] = po;
}


bool TableStatistics::preorder(const IR::MAU::Table * tbl) {
    LOG1("Gathering Statistics on table " << tbl->name);

    RamsForKb unk_size;
    MatchGather table_info;
    ActionTableOption ao;

    if (tbl->match_table) {
         bool sized = gather_match_stats(tbl->match_table, tstats, unk_size, table_info); 
         gather_action_stats(tbl, tstats, unk_size, ao);
         if (!sized) {
             tstats.ram_calcs.push_back(unk_size);
         }
         if (!table_info.is_ternary)
             calculate_packing_options(tbl, tstats, table_info, ao);
    }
    return true;
}

void TableStatistics::end_apply(const IR::Node *) {
    LOG3("Total unsized info is " << tstats.ram_calcs.size());
    for (auto info : tstats.ram_calcs) {
        LOG3("The ratio of match is " << info.match);
    }

    LOG1("Total SRAM tables are " << tstats.sram_tables_count);
    LOG1("Total TCAM tables are " << tstats.tcam_tables_count);

    LOG1("Min SRAMS known are " << tstats.min_srams_known);
    LOG1("Min TCAMS known are " << tstats.min_tcams_known);

    LOG1("Max SRAMS known are " << tstats.max_srams_known);
    LOG1("Max TCAMS known are " << tstats.max_tcams_known);

    LOG1("Total Unknown SRAM tables are " << tstats.unknown_sram_tables);
    LOG1("Total Unknown TCAM tables are " << tstats.unknown_tcam_tables);
}
