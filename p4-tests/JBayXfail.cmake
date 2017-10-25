set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF AND NOT ENABLE_STF2PTF)
set (JBAY_XFAIL_TESTS ${JBAY_XFAIL_TESTS})
endif() # HARLYN_STF

# tests that no longer fail when enable TNA translation
# possibly due to different PHV allocation
if (NOT ENABLE_TNA)
endif() # NOT ENABLE_TNA

# BEGIN: XFAILS that match glass XFAILS
#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (ENABLE_TNA)
endif()  # ENABLE_TNA

if (HARLYN_STF AND NOT ENABLE_STF2PTF AND ENABLE_TNA)
endif()  # STF FAILURE IN TNA
