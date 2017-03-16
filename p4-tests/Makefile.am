# Tests
check-tofino:
	make check-local TESTSUITEFLAGS='-k tofino $(TESTSUITEFLAGS) $(EXTRA_FLAGS)'

TESTSUITE_AT += \
	extensions/p4_tests/testsuite-p4_tests.at \
	$(srcdir)/extensions/p4_tests/p4_16 \
	$(srcdir)/extensions/p4_tests/p4_14

XFAIL_FILES += \
    extensions/p4_tests/xfails.text
