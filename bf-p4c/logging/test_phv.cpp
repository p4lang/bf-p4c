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
                             "2.0.0",            // schema version
                             "tofino");          // target

    using Structure = Phv_Schema_Logger::Structure;
    using Container = Phv_Schema_Logger::Container;
    using Field = Phv_Schema_Logger::Field;
    using FieldInfo = Phv_Schema_Logger::FieldInfo;
    using Slice = Phv_Schema_Logger::Slice;
    using FieldSlice = Phv_Schema_Logger::FieldSlice;
    using SourceLocation = Phv_Schema_Logger::SourceLocation;
    using SolitaryConstraint = Phv_Schema_Logger::SolitaryConstraint;
    using SolitaryBeforeStageConstraint = Phv_Schema_Logger::SolitaryBeforeStageConstraint;
    using Constraint = Phv_Schema_Logger::Constraint;
    using Access = Phv_Schema_Logger::Access;
    using MAULocation = Phv_Schema_Logger::MAULocation;
    using ParserLocation = Phv_Schema_Logger::ParserLocation;
    using DeparserLocation = Phv_Schema_Logger::DeparserLocation;
    using ContainerSlice = Phv_Schema_Logger::ContainerSlice;

    // Structures
    auto structure1 = new Structure("h1", "header");
    auto f1_fs_slice = new Slice(0, 7);
    auto f1_sl = new FieldSlice("f1", f1_fs_slice);
    auto f2_fs_slice = new Slice(0, 15);
    auto f2_sl = new FieldSlice("f2", f2_fs_slice);
    structure1->append(f1_sl);
    structure1->append(f2_sl);
    logger.append_structures(structure1);

    // Field1
    auto f1_info = new FieldInfo(32, "pkt", "f1", "ingress", "");
    auto field1 = new Field(f1_info, "allocated", "h1");
    auto slice1 = new Slice(0, 7);
    auto f1_slice1 = new FieldSlice("f1", slice1);
    field1->append_field_slices(f1_slice1);
    auto f1_phv_sl1 = new Slice(8, 15);
    auto f1_phv_phv_sl1 = new Slice(8, 15);
    auto f1_phv_field_slice1 = new FieldSlice("f1", f1_phv_sl1);
    auto f1_phv_slice1 = new ContainerSlice(f1_phv_field_slice1, 0, f1_phv_phv_sl1);
    field1->append_phv_slices(f1_phv_slice1);
    auto constraint_slice1 = new Slice(0, 7);
    auto constraint_field_slice1 = new FieldSlice("f1", constraint_slice1);
    auto f1_constraints = new Constraint(constraint_field_slice1);
    auto src_location1 = new SourceLocation("test.p4", 56);
    auto pipeline_location1 = new Access(MAULocation("xbar", 2, "mau", "m_action1", "m_table1"));
    auto solitary_constraint1 = new SolitaryConstraint("alu",
                                        "Can not pack field with any other field",
                                        src_location1, pipeline_location1);
    f1_constraints->append(solitary_constraint1);
    field1->append_constraints(f1_constraints);
    logger.append_fields(field1);

    // Field2
    auto f2_info = new FieldInfo(16, "pkt", "f2", "ingress", "");
    auto field2 = new Field(f2_info, "partially allocated", "h1");
    auto slice2 = new Slice(0, 15);
    auto f2_slice1 = new FieldSlice("f2", slice2);
    field2->append_field_slices(f2_slice1);
    auto f2_phv_sl2 = new Slice(0, 8);
    auto f2_phv_phv_sl2 = new Slice(0, 8);
    auto f2_phv_field_slice2 = new FieldSlice("f2", f2_phv_sl2);
    auto f2_phv_slice2 = new ContainerSlice(f2_phv_field_slice2, 128, f2_phv_phv_sl2);
    field2->append_phv_slices(f2_phv_slice2);
    auto constraint_slice2 = new Slice(3, 5);
    auto constraint_field_slice2 = new FieldSlice("f2", constraint_slice2);
    auto f2_constraints = new Constraint(constraint_field_slice2);
    auto src_location2 = new SourceLocation("test.p4", 34);
    auto pipeline_location2 = new Access(DeparserLocation("pkt", "deparser"));
    auto sbs_constraint2 = new SolitaryBeforeStageConstraint(1, "alu",
        "Can not pack field with any other fields or slices after a program point", src_location2,
        pipeline_location2);
    f2_constraints->append(sbs_constraint2);
    field2->append_constraints(f2_constraints);
    logger.append_fields(field2);

    // Container1
    auto container1 = new Container(32, "normal", "ingress", 10, 10, 2);
    auto slice_info1 = new Slice(2, 7);
    auto field_slice1 = new FieldSlice("f1", slice_info1);
    auto phv_slice1 = new Slice(0, 7);
    auto container_slice1 = new ContainerSlice(field_slice1, 8, phv_slice1);
    auto write_access1 = new Access(MAULocation("xbar", 2, "mau", "m_action1", "m_table1"));
    auto read_access1 = new Access(ParserLocation("const", "start", "parser"));
    container_slice1->append_writes(write_access1);
    container_slice1->append_reads(read_access1);
    container1->append(container_slice1);
    logger.append_containers(container1);

    // Container2
    auto container2 = new Container(16, "tagalong", "ingress", 0, 0, 4);
    auto slice_info2 = new Slice(0, 1);
    auto field_slice2 = new FieldSlice("f2", slice_info2);
    auto phv_slice2 = new Slice(0, 1);
    auto container_slice2 = new ContainerSlice(field_slice2, 16, phv_slice2);
    auto write_access2 = new Access(MAULocation("xbar", 0, "mau", "m_action2", "m_table2"));
    auto read_access2 = new Access(DeparserLocation("pkt", "deparser"));
    container_slice2->append_writes(write_access2);
    container_slice2->append_reads(read_access2);
    container2->append(container_slice2);
    logger.append_containers(container2);

    logger.log();
    return 0;
}
