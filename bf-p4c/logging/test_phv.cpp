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
                             Phv_Schema_Logger::target_t::TOFINO);  // target
    auto s = new Phv_Schema_Logger::Structures("h1",
                                               Phv_Schema_Logger::Structures::type_t::HEADER);
    s->append("f1");
    s->append("f2");
    logger.append_structures(s);

    using Container = Phv_Schema_Logger::Container;
    auto c = new Container(Container::bit_width_t::I_32,
                           Container::container_type_t::NORMAL,
                           10,
                           10,
                           2);
    using Records = Phv_Schema_Logger::Container::Records;
    auto r = new Records(Records::field_class_t::PKT, 0, 14, "field1",
                         Records::gress_t::INGRESS,
                         2, 16);
    using Access = Phv_Schema_Logger::Access;
    r->append_writes(new Access(Access::location_t(Access::location_type_t::PARSER),
                                "action1",
                                Access::deparser_access_type_t::PKT,
                                Access::location_detail_t::XBAR,
                                "ps1", "table1"));
    r->append_reads(new Access(Access::location_t(Access::location_type_t::PARSER),
                               "action2",
                               Access::deparser_access_type_t::PKT,
                               Access::location_detail_t::XBAR,
                               "ps2", "table2"));
    r->append_reads(new Access(Access::location_type_t::DEPARSER));
    r->append_reads(new Access(3));
    c->append(r);
    logger.append_containers(c);

    logger.log();
    return 0;
}
