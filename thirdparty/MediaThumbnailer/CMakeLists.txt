cmake_minimum_required(VERSION 3.20)

project(MediaThumbnailer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

################################################################################

# Dependencies
set(CORE_COMPONENTS Core Gui Quick)
set(CORE_LIBRARIES Qt6::Core Qt6::Gui Qt6::Quick)
find_package(Qt6 6.5 REQUIRED COMPONENTS ${CORE_COMPONENTS})

################################################################################

add_definitions(-DENABLE_FFMPEG)

add_library(MediaThumbnailer STATIC
    MediaThumbnailer.h
    MediaThumbnailer_threadpool.cpp MediaThumbnailer_threadpool.h
    MediaThumbnailer_async.cpp MediaThumbnailer_async.h
    ThumbnailerBackend.cpp ThumbnailerBackend.h

    ThumbnailerBackend_ffmpeg.cpp ThumbnailerBackend_ffmpeg.h
)

find_library(AVFORMAT_LIB avformat)
find_library(AVCODEC_LIB avcodec)
find_library(AVUTIL_LIB avutil)
find_library(SWSCALE_LIB swscale)
set(PLATFORM_LIBRARIES ${AVFORMAT_LIB} ${AVCODEC_LIB} ${AVUTIL_LIB} ${SWSCALE_LIB})

target_link_libraries(MediaThumbnailer PRIVATE ${CORE_LIBRARIES} ${PLATFORM_LIBRARIES})
target_include_directories(MediaThumbnailer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
