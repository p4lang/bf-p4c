#include "input_xbar.h"

InputXbar::InputXbar(Table *t, bool ternary, VECTOR(pair_t) &data) : stage(t->stage) {
    int numgroups = ternary ? 16 : 8;
    for (auto &kv : data) {
	if (!CHECKTYPEM(kv.key, tCMD, "group or hash descriptor"))
	    continue;
	if (kv.key[0] == "group") {
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i > numgroups) {
		error(kv.key.lineno, "invalid group descriptor");
		continue; }
	} else if (!ternary && kv.key[0] == "hash") {
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i > numgroups) {
		error(kv.key.lineno, "invalid hash group descriptor");
		continue; }
	} else {
	    error(kv.key.lineno, "expecting a group %sdescriptor",
		  ternary ? "" : "or hash "); }
    }
}
