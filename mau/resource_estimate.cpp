#include "resource_estimate.h"
#include "lib/bitops.h"

StageUse::StageUse(const IR::MAU::Table *tbl, int &entries) {
    memset(this, 0, sizeof(*this));
    logical_ids = 1;
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    if (tbl->layout.ternary) {
	int depth = (entries + 511U)/512U;
	int width = (tbl->layout.match_width_bits + 47)/44; // +4 bits for v/v, round up
	ternary_ixbar_groups = width;
	tcams = depth * width;
	if (tbl->layout.overhead_bits > 1) {
	    int indir_size = ceil_log2(tbl->layout.overhead_bits);
	    if (indir_size > 8)
		throw std::runtime_error("Can't have more than 64 bits of overhead in "
					 "ternary table");
	    if (indir_size < 3) indir_size = 3;
	    int entries_per_sram = (128*1024) >> indir_size;
	    srams = (entries + entries_per_sram - 1) / entries_per_sram; }
	entries = depth * 512;
    } else if (tbl->match_table) {
	int width = tbl->layout.match_width_bits + tbl->layout.overhead_bits + 4; // valid/version
	int groups = 128/width;
	if (groups) width = 1;
	else {
	    groups = 1;
	    width = (width+127)/128; }
	int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
	srams = depth * width;
	entries = depth * groups * 1024U;
    } else
	entries = 0;
    /* FIXME -- figure use for attached tables */
}
