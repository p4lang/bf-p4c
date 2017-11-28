
macro(genHeaderTemplate dir name json_name arch json_globals)
  set (__out_file ${BFASM_BINARY_DIR}/gen/${dir}/${name}.h)
  set (__cfg_file ${BFASM_BINARY_DIR}/templates/${dir}/${name}.cfg.json)
  set (__size_file ${BFASM_BINARY_DIR}/templates/${dir}/${name}.size.json)
  if (NOT "${json_globals}" STREQUAL "")
    if(NOT ${json_globals} STREQUAL "+E")
      set (__gopt "-g")
    endif()
    set (__globals ${json_globals})
  else()
    set(__globals "")
    set(__gopt "")
  endif()
  add_custom_command(OUTPUT ${__out_file}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/gen/${dir}
    COMMAND ${BFASM_BINARY_DIR}/json2cpp +ehD ${__gopt} ${__globals} -N ${arch}
            -run '${json_name}' -c ${__cfg_file} ${__size_file} > ${__out_file}
    DEPENDS ${__cfg_file} ${__size_file} json2cpp)
endmacro(genHeaderTemplate)

macro(genSourceTemplate dir name json_name arch json_globals)
  set (__out_file ${BFASM_BINARY_DIR}/gen/${dir}/${name}.cpp)
  set (__cfg_file ${BFASM_BINARY_DIR}/templates/${dir}/${name}.cfg.json)
  set (__size_file ${BFASM_BINARY_DIR}/templates/${dir}/${name}.size.json)
  if (NOT "${json_globals}" STREQUAL "")
    if(NOT ${json_globals} STREQUAL "+E")
      set (__gopt "-g")
    endif()
    set (__globals ${json_globals})
  else()
    set(__globals "")
    set(__gopt "")
  endif()
  add_custom_command(OUTPUT ${__out_file}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/gen/${dir}
    COMMAND ${BFASM_BINARY_DIR}/json2cpp +ehDD ${__gopt} ${__globals} -N ${arch}
            -run '${json_name}' -c ${__cfg_file} -I ${name}.h ${__size_file} > ${__out_file}
    DEPENDS ${__cfg_file} ${__size_file} json2cpp)
endmacro(genSourceTemplate)

macro(genRegTemplate dir file_name json_name arch args)
  set (__out_file ${BFASM_BINARY_DIR}/gen/${dir}/${file_name})
  set (__cfg_file ${BFASM_BINARY_DIR}/templates/${dir}/${json_name}.cfg.json)
  set (__size_file ${BFASM_BINARY_DIR}/templates/${dir}/${json_name}.size.json)
  add_custom_command(OUTPUT ${__out_file}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/gen/${dir}
    COMMAND ${BFASM_BINARY_DIR}/json2cpp ${args} -N ${arch}
            -c ${__cfg_file} ${__size_file} > ${__out_file}
    DEPENDS ${__cfg_file} ${__size_file} json2cpp)
  set_source_files_properties(
    ${__out_file}
    PROPERTIES GENERATED TRUE)
endmacro(genRegTemplate)

macro(add_registers dir name json_name arch)
  if ("${ARGN}" STREQUAL "")
    genSourceTemplate(${dir} ${name} ${json_name} ${arch} "")
    genHeaderTemplate(${dir} ${name} ${json_name} ${arch} "")
  else()
    genSourceTemplate(${dir} ${name} ${json_name} ${arch} ${ARGN})
    genHeaderTemplate(${dir} ${name} ${json_name} ${arch} ${ARGN})
  endif()
endmacro(add_registers)
