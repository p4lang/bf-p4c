# setting the default target architecture in the installed driver code

macro(replace_p4c_target WDIR)
  if (EXISTS ${WDIR})
    MESSAGE("******** replacing_p4c_target in ${WDIR}")
    execute_process(COMMAND sed -e "s/bmv2-ss-p4org/tofino-native-barefoot/" main.py
      WORKING_DIRECTORY ${WDIR}
      OUTPUT_FILE main.py.tmp)

    execute_process(COMMAND mv main.py.tmp main.py
      WORKING_DIRECTORY ${WDIR})
  else()
    MESSAGE("******** ${WDIR} not found")
  endif()
endmacro()

replace_p4c_target(${P4C_ARTIFACTS_OUTPUT_DIRECTORY}/p4c_src)
replace_p4c_target(${CPACK_TEMPORARY_DIRECTORY}/${P4C_ARTIFACTS_OUTPUT_DIRECTORY}/p4c_src)
