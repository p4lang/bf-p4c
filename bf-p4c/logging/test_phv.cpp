#include <iostream>
#include "logging.h"
#include "phv_schema.h"

using namespace Logging;

int main() {
    Phv_Schema_Logger logger("phv.json",         // output filename
                             "today",            // build date
                             "test version",     // compiler version
                             12,                 // nStages
                             "test_phv_schema",  // program name
                             "run_id",           // runId
                             "1.0.3",            // schema version
                             "tofino");          // target
    auto s = new Phv_Schema_Logger::Structures("h1", "header");
    s->append("f1");
    s->append("f2");
    logger.append_structures(s);

    using Container = Phv_Schema_Logger::Container;
    auto c = new Container(32, "normal", 10, 10, 2);
    using Records = Phv_Schema_Logger::Container::Records;
    auto r = new Records("pkt", 0, 14, "field1", "ingress", 2, 16);
    using Access = Phv_Schema_Logger::Access;
    r->append_writes(new Access(Access::location_t("parser"),
                                "action1", "pkt", "xbar", "ps1", "table1"));
    r->append_reads(new Access(Access::location_t("parser"),
                               "action2", "pkt", "xbar", "ps2", "table2"));
    r->append_reads(new Access(Access::location_t("deparser")));
    r->append_reads(new Access(3));
    c->append(r);
    logger.append_containers(c);

    logger.log();
    return 0;
}
