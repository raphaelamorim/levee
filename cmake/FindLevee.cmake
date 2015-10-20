# - Find levee executable and defines a macro to generate script bundle rules
# The module defines the following variables:
#
#  LEVEE_EXECUTABLE - path to the levee program
#  LEVEE_VERSION - version of levee
#  LEVEE_FOUND - true if the program was found
#
# If levee is found, the module defines this macro:
#
#  LEVEE_BUNDLE(<Name> <InputDir> <OutputFile>)
#
# which will create  a custom rule to bundle lua files into C. <InputDir> is
# the path to a lua directory. <OutputFile> is the name of the source file
# generated by levee.
#
# The macro defines a set of variables:
#  LEVEE_${Name}_DEFINED       - true is the macro ran successfully
#  LEVEE_${Name}_INPUT         - The input source file, an alias for <InputDir>
#  LEVEE_${Name}_OUTPUT        - The source file generated by levee bundle
#  LEVEE_${Name}_SCRIPTS       - The input lua files found
#
#  ====================================================================
#  Example:
#
#   find_package(LEVEE) # or e.g.: find_package(LEVEE 0.2 REQUIRED)
#   LEVEE_BUNDLE(foo ./lua/foo ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
#   add_executable(bar main.c ${LEVEE_foo_OUTPUT})
#  ====================================================================

cmake_minimum_required(VERSION 2.8)

find_program(LEVEE_EXECUTABLE NAMES levee DOC "path to the levee executable")
mark_as_advanced(LEVEE_EXECUTABLE)

if(LEVEE_EXECUTABLE)
	find_file(LEVEE_LIB "liblevee.a" PATHS "${LEVEE_EXECUTABLE}/../../lib")
	find_file(LEVEE_INCLUDE "levee.h" PATHS "${LEVEE_EXECUTABLE}/../../include/levee")
	get_filename_component(LEVEE_INCLUDE "${LEVEE_INCLUDE}/../.." ABSOLUTE)

	execute_process(COMMAND ${LEVEE_EXECUTABLE} version --build
		OUTPUT_VARIABLE LEVEE_version_output
		ERROR_VARIABLE  LEVEE_version_error
		RESULT_VARIABLE LEVEE_version_result
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	if(NOT ${LEVEE_version_result} EQUAL 0)
		message(SEND_ERROR
			"Command \"${LEVEE_EXECUTABLE} version --build\" failed: ${LEVEE_version_error}")
	endif()

	#============================================================
	# LEVEE_BUNDLE (public macro)
	#============================================================
	#
	macro(LEVEE_BUNDLE Name InputDir OutputFile)
		if(NOT ${ARGC} EQUAL 3)
			message(SEND_ERROR "LEVEE_BUNDLE(<Name> <InputDir> <OutputFile>")
		endif()

		get_filename_component(InputDirFull ${InputDir} ABSOLUTE)
		file(GLOB_RECURSE InputFiles ${InputDirFull}/*.lua)

		add_custom_command(OUTPUT ${OutputFile}
			COMMAND
			${LEVEE_EXECUTABLE} bundle -n ${Name} -o ${OutputFile} ${InputDirFull}
			DEPENDS ${InputFiles}
			COMMENT
			"[LEVEE][${Name}] Bundling lua scripts with levee ${LEVEE_VERSION}"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

		set(LEVEE_${Name}_DEFINED  TRUE)
		set(LEVEE_${Name}_INPUT    ${InputDir})
		set(LEVEE_${Name}_OUTPUT   ${OutputFile})
		set(LEVEE_${Name}_SCRIPTS  ${InputFiles})

		unset(InputDirFull)
		unset(InputFiles)
	endmacro()

endif()

# use this include when module file is located under /usr/share/cmake/Modules
#include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)
# use this include when module file is located in build tree
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LEVEE REQUIRED_VARS  LEVEE_EXECUTABLE
	VERSION_VAR    LEVEE_VERSION)
