#include <iostream>
#include "logging.h"
#include "phv_schema.h"

using namespace Logging;

int main()
{
    Phv_Schema_Logger logger("today",           // build date
                             "test version",    // compiler version
                             // empty_vector,   // structures
                             "0.1",             // schema version
                             // empty_vector,   // containers
                             "test_phv_schema"  // program name
                             // empty_vector,   // pov_structures
                             // empty_vector    // resources
                             );
    auto s = new Phv_Schema_Logger::Structures(Phv_Schema_Logger::Structures::HEADER, "h1");
    s->append("f1");
    s->append("f2");
    logger.append_structures(s);

    using Container = Phv_Schema_Logger::Container;
    auto c = new Container(10,
                           Container::bit_width_t::I_32,
                           10,
                           2,
                           Container::container_type_t::NORMAL);
    using Records = Phv_Schema_Logger::Container::Records;
    auto r = new Records(2, 0, Records::field_class_t::PKT, Records::gress_t::INGRESS,
                         "field1", 16, 14);
    using Access = Phv_Schema_Logger::Access;
    r->append_writes(new Access(Access::location_type_t::PARSER,
                                "ps1", Access::location_detail_t::XBAR,
                                "action1", "table1",
                                Access::deparser_access_type_t::PKT));
    r->append_reads(new Access(Access::location_type_t::PARSER,
                               "ps2", Access::location_detail_t::XBAR,
                               "action2", "table2",
                               Access::deparser_access_type_t::PKT));
    r->append_reads(new Access(Access::location_type_t::DEPARSER));
    r->append_reads(new Access(3));
    c->append(r);
    logger.append_containers(c);

    logger.log();
    return 0;
}
