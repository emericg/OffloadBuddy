cmake_minimum_required(VERSION 3.20)

project(EGM96 LANGUAGES C)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

add_library(EGM96 OBJECT EGM96 EGM96.c EGM96.h EGM96_data.h)
add_library(EGM96::EGM96 ALIAS EGM96)

target_include_directories(EGM96 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
