cmake_minimum_required(VERSION 3.25)

project(fgof_temp VERSION 0.1.0 LANGUAGES Fortran C)

add_library(fgof_temp
  src/fgof_temp_types.f90
  src/fgof_temp_posix.f90
  src/fgof_temp.f90
  src/fgof_temp_posix.c
)
add_library(fgof::temp ALIAS fgof_temp)

set_target_properties(fgof_temp PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_temp PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_compile_options(fgof_temp PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
  $<$<COMPILE_LANG_AND_ID:C,GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Werror>
)
