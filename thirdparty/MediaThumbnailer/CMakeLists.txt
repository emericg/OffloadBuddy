cmake_minimum_required(VERSION 3.20)

project(MediaThumbnailer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

option(BACKEND_FFMPEG "" ON)
option(BACKEND_GSTREAMER "" OFF)
option(BACKEND_MINIVIDEO "" OFF)

set(CORE_COMPONENTS Core Gui Quick)
set(CORE_LIBRARIES Qt6::Core Qt6::Gui Qt6::Quick)
find_package(Qt6 6.5 REQUIRED COMPONENTS ${CORE_COMPONENTS})

add_library(MediaThumbnailer STATIC
    MediaThumbnailer.h
    MediaThumbnailer_threadpool.cpp MediaThumbnailer_threadpool.h
    MediaThumbnailer_async.cpp MediaThumbnailer_async.h
    ThumbnailerBackend.cpp ThumbnailerBackend.h

    ${BACKEND_SOURCES}
    ThumbnailerBackend_ffmpeg.cpp ThumbnailerBackend_ffmpeg.h
)

################################################################################

if(BACKEND_FFMPEG)
    find_library(AVFORMAT_LIB avformat)
    find_library(AVCODEC_LIB avcodec)
    find_library(AVUTIL_LIB avutil)
    find_library(SWSCALE_LIB swscale)

    set(BACKEND_LIBRARIES ${AVFORMAT_LIB} ${AVCODEC_LIB} ${AVUTIL_LIB} ${SWSCALE_LIB})
    set(BACKEND_SOURCES ThumbnailerBackend_ffmpeg.cpp ThumbnailerBackend_ffmpeg.h)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_FFMPEG)
endif()

if(BACKEND_GSTREAMER)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_GSTREAMER)

    #target_link_libraries(MediaThumbnailer PRIVATE
    #    PkgConfig::GSTREAMER
    #    PkgConfig::GSTREAMER-VIDEO
    #)
endif()

if(BACKEND_MINIVIDEO)
    #target_link_libraries(MediaThumbnailer PRIVATE minivideo)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_MINIVIDEO)
endif()

################################################################################

################################################################################

target_link_libraries(MediaThumbnailer PRIVATE ${CORE_LIBRARIES} ${BACKEND_LIBRARIES})
target_include_directories(MediaThumbnailer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
