# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to JBayErrors.cmake.


set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "Destination of saturation add was allocated to bigger container than the field itself.*"
  extensions/p4_tests/p4_16/internal/p4c-3172-xfail.p4
)

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)
# Failure due to old version of p4runtime installed in jarvis docker images -- fixed by
# updating p4runtime.  Can use PYTHONPATH=/mnt/build/_deps/p4runtime-src/py:$PYTHONPATH
p4c_add_xfail_reason("tofino2"
  "google.protobuf.text_format.ParseError: .*:3 : Message type \"p4.config.v1.Table\" has no field named \"has_initial_entries\""
  extensions/p4_tests/p4_16/internal/ptf/p4c-5298.p4
)
endif() # PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "Varbit field size expression evaluates to non byte-aligned value"
  extensions/p4_tests/p4_16/internal/p4c-1478-neg.p4
  )

# Not being tracked by JBay regression yet
p4c_add_xfail_reason("tofino2"
  "Field key is not a member of header pktgen_recirc_header_t"
  extensions/p4_tests/internal/p4-programs/programs/stful/stful.p4
)

p4c_add_xfail_reason("tofino2"
  "This program violates action constraints imposed by Tofino2"
  # P4C-3155
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1323-c2.p4
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1680-2.p4
)

p4c_add_xfail_reason("tofino2"
  "Name '.*' is used for multiple Register objects in the P4Info message"
  p4_16_internal_p4_16_t2na_fifo
)

# Expected failure (negative test)
p4c_add_xfail_reason("tofino2"
  "error.*PHV allocation was not successful|Trivial allocator has found unsatisfiable constraints"
  extensions/p4_tests/p4_16/internal/p4c-2091.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino2"
  "you can introduce padding fields"
  extensions/p4_tests/p4_16/internal/p4c-1892.p4
)

# P4 program error
p4c_add_xfail_reason("tofino2"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call, as these must change simultaneously at runtime"
  p4c_1585_a
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino2"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/internal/p4c-2694.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .* table .* could not fit|The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported"
  extensions/p4_tests/p4_16/internal/p4c-1601-neg.p4
)

p4c_add_xfail_reason("tofino2"
  "warning: .*: Padding fields do not need to be explicitly set.* Tofino2 does not support action data/constant with rotated PHV source at the same time|Trivial allocator has found unsatisfiable constraints|PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/internal/p4c-3453.p4
)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*|array index 32 out of bounds"
  p4c-3614
)

p4c_add_xfail_reason("tofino2"
  "Ran out of parser match registers for .*"
  # P4C-3473
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3473-a2.p4
)

# This is really expected to fail (with this particular error message)
p4c_add_xfail_reason("tofino2"
   "error: Inferred incompatible container alignments for field egress::eg_md.field:[\r\n\t ]*.*p4c-3431.p4.77.: alignment = 6 .*[\r\n\t ]*.*eg_md.field = parse_1_md.field.*[\r\n\t ]*.*[\r\n\t ]*Previously inferred alignments:[\r\n\t ]*.*p4c-3431.p4.68.: alignment = 0 .*[\r\n\t ]*.*eg_md.field = hdr.field"
   extensions/p4_tests/p4_16/internal/p4c-3431.p4
)

# P4C-3402
p4c_add_xfail_reason("tofino2"
  "error: Two or more assignments of .* inside the register action .* are not mutually exclusive and thus cannot be implemented in Tofino Stateful ALU."
  extensions/p4_tests/p4_16/internal/p4c-3402.p4
)

p4c_add_xfail_reason("tofino2"
  "error: You can only have more than one binary operator in a statement"
  extensions/p4_tests/p4_16/internal/p4c-3402-err.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    # P4C-3914
    p4c_add_xfail_reason("tofino2"
      "error: Size of learning quanta is [0-9]+ bytes, greater than the maximum allowed 48 bytes.
Compiler will improve allocation of learning fields in future releases.
Temporary fix: try to apply @pa_container_size pragma to small fields allocated to large container in. Here are possible useful progmas you can try: .*"
      extensions/p4_tests/p4_16/internal/p4c-3914.p4
    )
endif()

# Tracked in P4C-3328
p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*."
  p4c_3043
)

# P4C-3220
p4c_add_xfail_reason("tofino2"
  "error: Incompatible outputs in RegisterAction: mem_lo and mem_hi"
  extensions/p4_tests/p4_16/internal/p4c-3220_1.p4
)

# ALT-PHV: tests that do not work yet with the alternative allocator.
# If you make an ALT-PHV test pass (or get close to it but if fails on later
# error), please update the xfails accordingly.
if (TEST_ALT_PHV_ALLOC)
# add fails here
    p4c_add_xfail_reason("tofino2"
        "tofino2 supports up to 20 stages, using 29"
	extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-p416_baremetal_tofino2.p4
    )

    p4c_add_xfail_reason("tofino2"
	"Illegal call of the pp_unique_id function on table"
	extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-msee_tofino2.p4
    )

    p4c_add_xfail_reason("tofino2"
        "table allocation .alt-phv-alloc enabled. failed to allocate tables for pipe 'DefeatFlows'"
	extensions/p4_tests/p4_16/internal/customer/lts/p4c-5323.p4
    )
endif (TEST_ALT_PHV_ALLOC)

if (NOT TEST_ALT_PHV_ALLOC)
    # Failure only with traditional compilation.
    p4c_add_xfail_reason("tofino2"
        "PHV allocation was not successful"
        extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-5223-leaf-tof2.p4
    )                        

    # Failed after P4C-4507
    p4c_add_xfail_reason("tofino2"
      "tofino2 supports up to 20 stages, using|error: table allocation .* 20 stages. Allocation state: ALT_FINALIZE_TABLE"
      extensions/p4_tests/p4_16/internal/p4c-3175.p4
    )
endif()

