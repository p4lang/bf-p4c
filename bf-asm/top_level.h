#ifndef BF_ASM_TOP_LEVEL_H_
#define BF_ASM_TOP_LEVEL_H_

#include "target.h"
#include "json.h"

template<class REGSET> class TopLevelRegs;

class TopLevel {
 protected:
    TopLevel();
 public:
    static TopLevel *all;
    virtual ~TopLevel();
    virtual void output(json::map &) = 0;
    static void output_all(json::map &ctxtJson) { all->output(ctxtJson); }
    template<class T> static TopLevelRegs<typename T::register_type> *regs();
#define SET_MAU_STAGE(TARGET)                                                           \
    virtual void set_mau_stage(int, const char *, Target::TARGET::mau_regs *, bool) {   \
        BUG_CHECK(!"register mismatch"); }
    FOR_ALL_REGISTER_SETS(SET_MAU_STAGE)
};

template<class REGSET>
class TopLevelRegs : public TopLevel, public REGSET::top_level_regs {
 public:
    TopLevelRegs();
    ~TopLevelRegs();

    void output(json::map &);
    void set_mau_stage(int stage, const char *file, typename REGSET::mau_regs *regs,
                       bool egress_only);
};

template<class T> TopLevelRegs<typename T::register_type> *TopLevel::regs() {
    return dynamic_cast<TopLevelRegs<typename T::register_type> *>(all); }

#endif /* BF_ASM_TOP_LEVEL_H_ */
