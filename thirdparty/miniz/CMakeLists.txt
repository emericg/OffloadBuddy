cmake_minimum_required(VERSION 3.20)

project(miniz LANGUAGES C)

add_library(miniz OBJECT miniz miniz.c miniz.h)
add_library(miniz::miniz ALIAS miniz)

target_include_directories(miniz PUBLIC ${CMAKE_CURRENT_LIST_DIR})
