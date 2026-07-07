cmake_minimum_required(VERSION 3.20)

project(OffloadBuddy VERSION 0.12 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

################################################################################

option(USE_GSTREAMER "" OFF)
option(USE_FFMPEG "" OFF)
option(USE_LIBCPUID "" OFF)
option(USE_MINIVIDEO "" ON)
option(USE_LIBEXIF "" ON)
option(USE_EXIV2 "" OFF)

################################################################################

message(STATUS ">>> BUILDING ${PROJECT_NAME} v${PROJECT_VERSION} >>>")
message(STATUS "[CMAKE] CMAKE_VERSION               = ${CMAKE_VERSION}")
message(STATUS "[CMAKE] CMAKE_PREFIX_PATH           = ${CMAKE_PREFIX_PATH}")
message(STATUS "[BUILD] QT_HOST_PATH                = ${QT_HOST_PATH}")
message(STATUS "[BUILD] TOOLCHAIN_FILE              = ${CMAKE_TOOLCHAIN_FILE}")
message(STATUS "[BUILD] BUILD_TYPE                  = ${CMAKE_BUILD_TYPE}")
message(STATUS "[SYSTEM] (HOST) SYSTEM NAME         = ${CMAKE_HOST_SYSTEM_NAME}")
message(STATUS "[SYSTEM] (HOST) SYSTEM VERSION      = ${CMAKE_HOST_SYSTEM_VERSION}")
message(STATUS "[SYSTEM] (HOST) SYSTEM PROCESSOR    = ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "[SYSTEM] (TARGET) SYSTEM NAME       = ${CMAKE_SYSTEM_NAME}")
message(STATUS "[SYSTEM] (TARGET) SYSTEM VERSION    = ${CMAKE_SYSTEM_VERSION}")
message(STATUS "[SYSTEM] (TARGET) SYSTEM PROCESSOR  = ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "[TOP PROJECT] CMAKE_PROJECT_NAME    = ${CMAKE_PROJECT_NAME}")
message(STATUS "[TOP PROJECT] CMAKE_PROJECT_VERSION = ${CMAKE_PROJECT_VERSION}")
message(STATUS "[TOP PROJECT] CMAKE_SOURCE_DIR      = ${CMAKE_SOURCE_DIR}")
message(STATUS "[PROJECT] PROJECT_NAME              = ${PROJECT_NAME}")
message(STATUS "[PROJECT] PROJECT_VERSION           = ${PROJECT_VERSION}")
message(STATUS "[PROJECT] PROJECT_SOURCE_DIR        = ${PROJECT_SOURCE_DIR}")
message(STATUS "[PROJECT] CMAKE_CURRENT_SOURCE_DIR  = ${CMAKE_CURRENT_SOURCE_DIR}")

################################################################################

find_package(Qt6 REQUIRED COMPONENTS Core Sql Multimedia Positioning Location)
find_package(Qt6 REQUIRED COMPONENTS Gui Svg Qml Quick QuickControls2 Charts)
find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

qt_standard_project_setup(REQUIRES 6.8
                          I18N_SOURCE_LANGUAGE en
                          I18N_TRANSLATED_LANGUAGES en)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0002 NEW)
qt_policy(SET QTP0003 NEW)
qt_policy(SET QTP0004 NEW)

set(SOURCES
    src/main.cpp
    src/SettingsManager.cpp src/SettingsManager.h
    src/FirmwareManager.cpp src/FirmwareManager.h
    src/JobManager.cpp src/JobManager.h
    src/Job.h src/JobUtils.h
    src/JobWorkerFFmpeg.cpp src/JobWorkerFFmpeg.h
    src/JobWorkerThread.cpp src/JobWorkerThread.h
    src/JobWorkerASync.cpp src/JobWorkerASync.h
    src/StorageManager.cpp src/StorageManager.h
    src/StorageUtils.h
    src/MediaDirectory.cpp src/MediaDirectory.h
    src/MediaLibrary.cpp  src/MediaLibrary.h
    src/MediaUtils.h
    src/DeviceScanner.cpp src/DeviceScanner.h
    src/DeviceManager.cpp src/DeviceManager.h
    src/Device.cpp src/Device.h src/DeviceUtils.h
    src/DeviceStorage.cpp src/DeviceStorage.h
    src/DeviceCapabilities.cpp src/DeviceCapabilities.h
    src/FileScanner.cpp src/FileScanner.h
    src/ItemImage.cpp src/ItemImage.h
    src/Job.cpp
    src/Shot.cpp src/Shot.h src/ShotUtils.h
    src/ShotTelemetry.cpp
    src/ShotModel.cpp src/ShotModel.h
    src/ShotFilter.cpp src/ShotFilter.h
    src/ShotProvider.cpp src/ShotProvider.h
    src/GenericFileModel.cpp src/GenericFileModel.h
    src/GoProFileModel.cpp src/GoProFileModel.h
    src/Insta360FileModel.cpp src/Insta360FileModel.h
    src/GpmfBuffer.cpp src/GpmfBuffer.h
    src/GpmfKLV.cpp src/GpmfKLV.h
    src/GpmfTags.cpp src/GpmfTags.h
    src/GeoCoding.cpp src/GeoCoding.h

    # Assets
    assets/gfx.qrc assets/cameras.qrc
    thirdparty/IconLibrary/IconLibrary_material.qrc
    thirdparty/IconLibrary/IconLibrary_fontawesome.qrc

    # Desktop app icons
    "${PROJECT_SOURCE_DIR}/assets/windows/${PROJECT_NAME}.rc"
    "${PROJECT_SOURCE_DIR}/assets/macos/${PROJECT_NAME}.icns"
)

qt_add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${SOURCES_DESKTOP} ${SOURCES_MOBILE}
)

qt_add_qml_module(${PROJECT_NAME}
    URI ${PROJECT_NAME}
    NO_PLUGIN
    QML_FILES
        qml/Application.qml
        qml/Sidebar.qml
        qml/ScreenLibrary.qml
        qml/ScreenLibraryGrid.qml
        qml/ScreenDevice.qml
        qml/ScreenDeviceGrid.qml
        qml/ScreenDeviceInfos.qml
        qml/ScreenMedia.qml
        qml/ScreenJobs.qml
        qml/ScreenSettings.qml
        qml/ScreenAbout.qml
        qml/MediaDetailOverview.qml
        qml/MediaDetailDetails.qml
        qml/MediaDetailTelemetry.qml
        qml/MediaPreview.qml

        qml/popups/PopupDate.qml
        qml/popups/PopupDelete.qml
        qml/popups/PopupEncoding.qml
        qml/popups/PopupExit.qml
        qml/popups/PopupFirmware.qml
        qml/popups/PopupOffload.qml
        qml/popups/PopupMove.qml
        qml/popups/PopupMerge.qml
        qml/popups/PopupMediaDirectory.qml
        qml/popups/PopupTelemetry.qml

        qml/components/ActionMenuFixed.qml
        qml/components/ComboBoxFolder.qml
        qml/components/DataBarPower.qml
        qml/components/DataBarSpace.qml
        qml/components/DataBarStorage.qml
        qml/components/DataBarStorageStats.qml
        qml/components/FileWarning.qml
        qml/components/GridHighlight.qml
        qml/components/HeaderShadow.qml
        qml/components/HeaderSeparator.qml
        qml/components/ItemBannerActions.qml
        qml/components/ItemBannerMessage.qml
        qml/components/ItemBannerJob.qml
        qml/components/ItemJob.qml
        qml/components/ItemShot.qml
        qml/components/ItemMediaDirectory.qml
        qml/components/RangeSliderPlayer.qml
        qml/components/ResizeWidget.qml
        qml/components/Separator.qml
        qml/components/SeparatorPadded.qml
        qml/components/SliderPlayer.qml
)

qt_add_translations(${PROJECT_NAME}
    SOURCE_TARGETS ${PROJECT_NAME}
    TS_FILE_BASE ${PROJECT_NAME}
    TS_FILE_DIR ${CMAKE_SOURCE_DIR}/i18n/
    RESOURCE_PREFIX "/i18n"
)

################################################################################

# "Other Files" macro
function(add_other_files target)
    foreach(file IN LISTS ARGN)
        target_sources(${target} PRIVATE ${file})
        source_group("Other Files" FILES ${file})
    endforeach()
endfunction()

add_other_files(${PROJECT_NAME}
    README.md LICENSE.md
    deploy_linux.sh deploy_macos.sh deploy_windows.sh
    .github/workflows/builds_desktop.yml
    .github/workflows/flatpak.yml
    .gitignore
)

################################################################################

# Qt libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Sql
    Qt6::Multimedia
    Qt6::Positioning
    Qt6::Location
    Qt6::Sql
    Qt6::Gui
    Qt6::Svg
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Charts
)

if(NOT IOS AND NOT ANDROID)
    # for proper systray and menubar support
    find_package(Qt6 REQUIRED COMPONENTS Widgets)
    target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Widgets)
endif()

################################################################################

# AppUtils
set(UTILS_DOCK_ENABLED ON CACHE BOOL "UTILS_DOCK_ENABLED" FORCE)
add_subdirectory(thirdparty/AppUtils)
target_link_libraries(${PROJECT_NAME} PRIVATE AppUtils AppUtils_plugin)

# ComponentLibrary
add_subdirectory(thirdparty/ComponentLibrary)
target_link_libraries(${PROJECT_NAME} PRIVATE ComponentLibrary ComponentLibrary_plugin)

# SingleApplication
add_subdirectory(thirdparty/SingleApplication)
target_link_libraries(${PROJECT_NAME} PRIVATE SingleApplication)

# Zip extraction
add_subdirectory(thirdparty/miniz)
target_link_libraries(${PROJECT_NAME} PRIVATE miniz)

# EGM96 altitude correction
add_subdirectory(thirdparty/EGM96)
target_link_libraries(${PROJECT_NAME} PRIVATE EGM96)

# Fast thumbnailer for photo and video
add_subdirectory(thirdparty/MediaThumbnailer)
target_link_libraries(${PROJECT_NAME} PRIVATE MediaThumbnailer)

# Includes
target_include_directories(${PROJECT_NAME} PRIVATE src/)
target_include_directories(${PROJECT_NAME} PRIVATE thirdparty/)

# Qt official hacks...
set(QML_IMPORT_PATH
    "${CMAKE_BINARY_DIR}/"
    "${CMAKE_BINARY_DIR}/thirdparty/"
    "${CMAKE_BINARY_DIR}/thirdparty/AppUtils/"
    "${CMAKE_BINARY_DIR}/thirdparty/ComponentLibrary/"
    CACHE STRING "QML Modules import paths" FORCE)

# Qt official hacks...
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

################################################################################

if(USE_MINIVIDEO)
    # MiniVideo
    add_subdirectory(thirdparty/minivideo)
    target_link_libraries(${PROJECT_NAME} PRIVATE MiniVideo::MiniVideo)
    target_compile_definitions(${PROJECT_NAME} PRIVATE ENABLE_MINIVIDEO)
endif()

if(USE_LIBEXIF)
    # libexif
    add_subdirectory(contribs/build/linux_x86_64/libexif-master/)
    target_link_libraries(${PROJECT_NAME} PRIVATE exif)
    target_compile_definitions(${PROJECT_NAME} PRIVATE ENABLE_LIBEXIF)
endif()

if(USE_EXIV2)
    # exiv2
    target_compile_definitions(${PROJECT_NAME} PRIVATE ENABLE_EXIV2)
endif()

################################################################################

## Release build? Set "no debug" macros
target_compile_definitions(${PROJECT_NAME} PRIVATE
    $<$<CONFIG:Release>:NDEBUG>
    $<$<CONFIG:Release>:QT_NO_DEBUG>
    $<$<CONFIG:Release>:QT_NO_DEBUG_OUTPUT>
)

################################################################################

include(GNUInstallDirs)

## Linux
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    install(FILES ${PROJECT_SOURCE_DIR}/assets/linux/${PROJECT_NAME}.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications/)
    install(FILES ${PROJECT_SOURCE_DIR}/assets/linux/${PROJECT_NAME}.appdata.xml DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/appdata/)
    install(FILES ${PROJECT_SOURCE_DIR}/assets/linux/${PROJECT_NAME}.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/pixmaps/)
    install(FILES ${PROJECT_SOURCE_DIR}/assets/linux/${PROJECT_NAME}.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps/)
    install(FILES ${PROJECT_SOURCE_DIR}/LICENSE.md DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/${PROJECT_NAME}/)
endif()

## macOS
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    #set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")

    set(app_icon_macos "${PROJECT_SOURCE_DIR}/assets/macos/${PROJECT_NAME}.icns")
    set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE ON
        MACOSX_BUNDLE_INFO_PLIST "${PROJECT_SOURCE_DIR}/assets/macos/Info.plist"
        # New Xcode attributes (???)
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER           "io.emeric.offloadbuddy"
        XCODE_ATTRIBUTE_PRODUCT_NAME                        ${PROJECT_NAME}
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION             ${PROJECT_VERSION}
        XCODE_ATTRIBUTE_MARKETING_VERSION                   ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS             "${PROJECT_SOURCE_DIR}/assets/macos/${PROJECT_NAME}.entitlements"
    )
endif()

## Windows
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(app_icon_windows "${CMAKE_SOURCE_DIR}/assets/windows/${PROJECT_NAME}.rc")

    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()

################################################################################

# Output (build)
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin"
)

# Output (install)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION ${CMAKE_INSTALL_BINDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

################################################################################
