cmake_minimum_required(VERSION 3.20)

project(libexif VERSION "0.6.26.0")

option(BUILD_STATIC_LIBS "Build static library" ON)
option(BUILD_SHARED_LIBS "Build shared library" ON)


# Build configuration
################################################################################

set(CMAKE_POSITION_INDEPENDENT_CODE ON)


# Platform specific build configuration
################################################################################

if(${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")
    message(STATUS "Building with Visual Studio C++ compiler")
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()


# Source files
################################################################################

include_directories(.)

# Source code
set(libexif_SRC
    config.h
    libexif/exif-byte-order.c
    libexif/exif-content.c
    libexif/exif-data.c
    libexif/exif-entry.c
    libexif/exif-format.c
    libexif/exif-gps-ifd.c
    libexif/exif-ifd.c
    libexif/exif-loader.c
    libexif/exif-log.c
    libexif/exif-mem.c
    libexif/exif-mnote-data.c
    libexif/exif-mnote-data-priv.h
    libexif/exif-tag.c
    libexif/exif-utils.c
    libexif/exif.h
    libexif/i18n.h
    libexif/apple/exif-mnote-data-apple.c libexif/apple/exif-mnote-data-apple.h
    libexif/apple/mnote-apple-entry.c libexif/apple/mnote-apple-entry.h
    libexif/apple/mnote-apple-tag.c libexif/apple/mnote-apple-tag.h
    libexif/canon/exif-mnote-data-canon.c libexif/canon/exif-mnote-data-canon.h
    libexif/canon/mnote-canon-entry.c libexif/canon/mnote-canon-entry.h
    libexif/canon/mnote-canon-tag.c libexif/canon/mnote-canon-tag.h
    libexif/fuji/mnote-fuji-entry.c libexif/fuji/mnote-fuji-entry.h
    libexif/fuji/exif-mnote-data-fuji.c libexif/fuji/exif-mnote-data-fuji.h
    libexif/fuji/mnote-fuji-tag.c libexif/fuji/mnote-fuji-tag.h
    libexif/olympus/mnote-olympus-entry.c libexif/olympus/mnote-olympus-entry.h
    libexif/olympus/exif-mnote-data-olympus.c libexif/olympus/exif-mnote-data-olympus.h
    libexif/olympus/mnote-olympus-tag.c libexif/olympus/mnote-olympus-tag.h
    libexif/pentax/mnote-pentax-entry.c libexif/pentax/mnote-pentax-entry.h
    libexif/pentax/exif-mnote-data-pentax.c libexif/pentax/exif-mnote-data-pentax.h
    libexif/pentax/mnote-pentax-tag.c libexif/pentax/mnote-pentax-tag.h
)

# Public headers
set(libexif_HEADERS
    libexif/exif-byte-order.h
    libexif/exif-data-type.h
    libexif/exif-ifd.h
    libexif/exif-mem.h
    libexif/exif-utils.h
    libexif/exif-content.h
    libexif/exif-entry.h
    libexif/exif-loader.h
    libexif/exif-mnote-data.h
    libexif/exif-data.h
    libexif/exif-format.h
    libexif/exif-log.h
    libexif/exif-tag.h
)


# Build
################################################################################

# Build library
if (BUILD_SHARED_LIBS)
    message("** Building shared library")
    add_library(exif_shared SHARED ${libexif_SRC})
    target_link_libraries(exif_shared ${EXTRA_LIBS})
    set_target_properties(exif_shared PROPERTIES OUTPUT_NAME exif)
endif (BUILD_SHARED_LIBS)

if (BUILD_STATIC_LIBS)
    message("** Building static library")
    add_library(exif_static STATIC ${libexif_SRC})
    target_link_libraries(exif_static ${EXTRA_LIBS})
    set_target_properties(exif_static PROPERTIES OUTPUT_NAME exif)
endif (BUILD_STATIC_LIBS)


# Deployment
################################################################################

# pkg-config integration
set(PROJECT_VERSION "${VERSION}")
set(LIB_SUFFIX "" CACHE STRING "Define suffix of directory name")
set(EXEC_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX} CACHE PATH "Installation prefix for executables and object code libraries" FORCE)
set(BIN_INSTALL_DIR ${EXEC_INSTALL_PREFIX}/bin CACHE PATH "Installation prefix for user executables" FORCE)
set(LIB_INSTALL_DIR ${EXEC_INSTALL_PREFIX}/lib${LIB_SUFFIX} CACHE PATH "Installation prefix for object code libraries" FORCE)
set(INCLUDE_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/include/libexif CACHE PATH "Installation prefix for header files" FORCE)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libexif.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/libexif.pc)

# Install the shared library and its header into the system (optional step, requires root credentials)
# Relative to $<INSTALL_PREFIX>
if (BUILD_SHARED_LIBS)
    install(TARGETS exif_shared DESTINATION lib/)
endif (BUILD_SHARED_LIBS)
if (BUILD_STATIC_LIBS)
    install(TARGETS exif_static DESTINATION lib/)
endif (BUILD_STATIC_LIBS)

install(FILES ${libexif_HEADERS} DESTINATION include/libexif/)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libexif.pc DESTINATION lib/pkgconfig/)
