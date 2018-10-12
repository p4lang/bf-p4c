#ifndef _top_level_h_
#define _top_level_h_

#include "target.h"
#include "json.h"

template<class TARGET> class TopLevelTarget;

class TopLevel {
protected:
    TopLevel();
public:
    json::map                           name_lookup;

    static TopLevel *all;
    virtual ~TopLevel();
    virtual void output(json::map &) = 0;
    static void output_all(json::map &ctxtJson) { all->output(ctxtJson); }
    template<class T> static TopLevelTarget<T> *regs();
#define SET_MAU_STAGE(TARGET)                                                           \
    virtual void set_mau_stage(int, const char *i, Target::TARGET::mau_regs *r) {       \
        BUG_CHECK(!"register mismatch"); }
    FOR_ALL_TARGETS(SET_MAU_STAGE)
};

template<class TARGET>
class TopLevelTarget : public TopLevel, public TARGET::top_level_regs {
public:

    TopLevelTarget();
    ~TopLevelTarget();

    void output(json::map &);
    void set_mau_stage(int stage, const char *file, typename TARGET::mau_regs *regs) {
        this->reg_pipe.mau[stage].set(file, regs); }
};

template<class T> TopLevelTarget<T> *TopLevel::regs() {
    return dynamic_cast<TopLevelTarget<T> *>(all); }

#endif /* _top_level_h_ */
