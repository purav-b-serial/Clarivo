cmake_minimum_required(VERSION 3.14)
project(clarivo LANGUAGES CXX)

set(BINARY_NAME "clarivo")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/run")
set(CMAKE_VERBOSE_MAKEFILE ON)

# Prevent the default /W3 warning level from being set.
if (MSVC)
  string(REGEX REPLACE "/W[0-4]" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif ()

# Application version
set(APPLICATION_VERSION "1.0.0")

# Flutter standard settings
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application runner target
add_subdirectory("runner")

# Standard plugins
add_subdirectory(${FLUTTER_MANAGED_DIR}/ephemeral/.plugin_symlinks/flutter_secure_storage/windows)

install(CODE "set(BUILD_BUNDLE_DIR \"${CMAKE_INSTALL_PREFIX}\")")
install(CODE [[
  file(TO_CMAKE_PATH "${BUILD_BUNDLE_DIR}" BUNDLE_DIR)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target INSTALL --config Release
    RESULT_VARIABLE result
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
]])
