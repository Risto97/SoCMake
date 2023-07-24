function(peakrdl_halcpp RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/halcpp)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    __ext_header_provided(${RTLLIB} libs)
    list(LENGTH libs libs_len)
    if(libs_len GREATER 0)
        set(EXT_ARG --ext ${libs})
    endif()

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD 
        ${Python3_EXECUTABLE} -m peakrdl halcpp
            ${RDL_FILES}
            ${EXT_ARG}
            -o ${OUTDIR} 
        )

    target_include_directories(${RTLLIB} INTERFACE ${OUTDIR} ${OUTDIR}/include)

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${CPP_HEADERS} ${STAMP_FILE}
        COMMAND python3 -m peakrdl halcpp
            ${RDL_FILES}
            ${EXT_ARG}
            -o ${OUTDIR} 

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_halcpp
        DEPENDS ${CPP_HEADERS} ${STAMP_FILE}
        )

    add_dependencies(${RTLLIB} ${RTLLIB}_halcpp)

endfunction()

# Find headers that have _ext.h extension and compare with libraries
# If there is a library that matches the file name add it to list
function(__ext_header_provided LIB libs)
    get_rtl_target_property(HEADERS ${LIB} HEADER_SET)
    get_rtl_target_property(FLAT_GRAPH ${LIB} FLAT_GRAPH)

    
    foreach(h ${HEADERS})
        get_filename_component(fn ${h} NAME)
        string(FIND ${fn} "_ext.h" ext_found)
        if(NOT ext_found EQUAL -1)
            foreach(l ${FLAT_GRAPH})
                string(FIND ${fn} ${l} match)
                if(NOT match EQUAL -1)
                    list(APPEND ext_libs ${l})
                endif()
            endforeach()
        endif()
    endforeach()

    list(REMOVE_DUPLICATES ext_libs)
    set(${libs} ${ext_libs} PARENT_SCOPE)

endfunction()


