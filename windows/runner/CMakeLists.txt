cmake_minimum_required(VERSION 3.14)

set(BINARY_NAME "clarivo")

cmake_policy(SET CMP0063 NEW)

project(runner LANGUAGES CXX)

# Flutter and application build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flutter")

# C++ standard — must be at least C++17 for flutter_local_notifications Win32
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

# Disable UNICODE so Win32 APIs use ANSI where required by some plugins.
target_compile_definitions(${BINARY_NAME} PRIVATE
  "NOMINMAX"
  "WIN32_LEAN_AND_MEAN"
)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  flutter_wrapper_app
  # Win32 APIs required for toast notifications (flutter_local_notifications)
  "runtimeobject.lib"
)

# Copy Flutter assets and DLLs into the output directory.
add_dependencies(${BINARY_NAME} flutter_assemble)
