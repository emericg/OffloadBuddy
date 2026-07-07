cmake_minimum_required(VERSION 3.20)

project(MediaThumbnailer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

################################################################################

option(BACKEND_FFMPEG "" OFF)
option(BACKEND_GSTREAMER "" ON)
option(BACKEND_MINIVIDEO "" OFF)

################################################################################

if(BACKEND_FFMPEG)

    set(BACKEND_SOURCES ThumbnailerBackend_ffmpeg.cpp ThumbnailerBackend_ffmpeg.h)

    find_library(AVFORMAT_LIB avformat)
    find_library(AVCODEC_LIB avcodec)
    find_library(AVUTIL_LIB avutil)
    find_library(SWSCALE_LIB swscale)
    set(BACKEND_LIBRARIES ${AVFORMAT_LIB} ${AVCODEC_LIB} ${AVUTIL_LIB} ${SWSCALE_LIB})

elseif(BACKEND_GSTREAMER)

    set(BACKEND_SOURCES ThumbnailerBackend_gstreamer.cpp ThumbnailerBackend_gstreamer.h)

    # PkgConfig
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0)

    # Official SDK CMake files
    #list(APPEND CMAKE_PREFIX_PATH "C:/gstreamer/1.0/msvc_x86_64")
    #find_package(GStreamer REQUIRED)

elseif(BACKEND_MINIVIDEO)

    set(BACKEND_SOURCES ThumbnailerBackend_minivideo.cpp ThumbnailerBackend_minivideo.h)
    set(BACKEND_LIBRARIES Minivideo::Minivideo)

endif()

################################################################################

set(CORE_COMPONENTS Core Gui Quick)
set(CORE_LIBRARIES Qt6::Core Qt6::Gui Qt6::Quick)
find_package(Qt6 6.5 REQUIRED COMPONENTS ${CORE_COMPONENTS})

add_library(MediaThumbnailer STATIC
    MediaThumbnailer.h
    MediaThumbnailer_threadpool.cpp MediaThumbnailer_threadpool.h
    MediaThumbnailer_async.cpp MediaThumbnailer_async.h

    ThumbnailerBackend.cpp ThumbnailerBackend.h
    ${BACKEND_SOURCES}
)

if(BACKEND_FFMPEG)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_FFMPEG)
elseif(BACKEND_GSTREAMER)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_GSTREAMER)
    target_link_libraries(MediaThumbnailer PRIVATE PkgConfig::GSTREAMER)
elseif(BACKEND_MINIVIDEO)
    target_compile_definitions(MediaThumbnailer PRIVATE ENABLE_MINIVIDEO)
endif()

target_link_libraries(MediaThumbnailer PUBLIC ${CORE_LIBRARIES})
target_link_libraries(MediaThumbnailer PRIVATE ${BACKEND_LIBRARIES})

target_include_directories(MediaThumbnailer PUBLIC ${CMAKE_CURRENT_LIST_DIR})

################################################################################
