cmake_minimum_required(VERSION 3.20)

project(OffloadBuddy VERSION 0.12 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(APP_NAME ${CMAKE_PROJECT_NAME})
set(APP_VERSION ${CMAKE_PROJECT_VERSION})

option(USE_GSTREAMER "" OFF)
option(USE_FFMPEG "" OFF)
option(USE_LIBCPUID "" OFF)
option(USE_MINIVIDEO "" ON)
option(USE_LIBEXIF "" ON)
option(USE_EXIV2 "" OFF)

################################################################################

message(STATUS "[CMAKE]   CMAKE_VERSION             = ${CMAKE_VERSION}")
message(STATUS "[CMAKE]   CMAKE_PREFIX_PATH         = ${CMAKE_PREFIX_PATH}")
message(STATUS "[SYSTEM]  (HOST) SYSTEM NAME        = ${CMAKE_HOST_SYSTEM_NAME}")
message(STATUS "[SYSTEM]  (HOST) SYSTEM VERSION     = ${CMAKE_HOST_SYSTEM_VERSION}")
message(STATUS "[SYSTEM]  (HOST) SYSTEM PROCESSOR   = ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "[SYSTEM]  (TARGET) SYSTEM NAME      = ${CMAKE_SYSTEM_NAME}")
message(STATUS "[SYSTEM]  (TARGET) SYSTEM VERSION   = ${CMAKE_SYSTEM_VERSION}")
message(STATUS "[SYSTEM]  (TARGET) SYSTEM PROCESSOR = ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "[PROJECT] CURRENT_SOURCE_DIR        = ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "[PROJECT] SOURCE_DIR                = ${CMAKE_SOURCE_DIR}")
message(STATUS "[PROJECT] BUILD_TYPE                = ${CMAKE_BUILD_TYPE}")
message(STATUS "[PROJECT] TOOLCHAIN_FILE            = ${CMAKE_TOOLCHAIN_FILE}")
message(STATUS "[PROJECT] QT_HOST_PATH              = ${QT_HOST_PATH}")

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

    assets/gfx.qrc assets/cameras.qrc
    thirdparty/IconLibrary/IconLibrary_material.qrc
    thirdparty/IconLibrary/IconLibrary_fontawesome.qrc
)

qt_add_executable(${CMAKE_PROJECT_NAME} ${SOURCES} ${SOURCES_DESKTOP} ${SOURCES_MOBILE})

qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI ${CMAKE_PROJECT_NAME}
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

qt_add_translations(${CMAKE_PROJECT_NAME}
    TS_FILE_BASE ${CMAKE_PROJECT_NAME}
    TS_FILE_DIR ${CMAKE_SOURCE_DIR}/i18n/
    RESOURCE_PREFIX "/i18n"
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE src/)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE thirdparty/)

################################################################################

# Qt libraries
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Sql
    Qt6::Multimedia
    Qt6::Positioning
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
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Widgets)
endif()

################################################################################

# AppUtils
set(UTILS_DOCK_ENABLED true)
add_subdirectory(thirdparty/AppUtils)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AppUtils)

# ComponentLibrary
add_subdirectory(thirdparty/ComponentLibrary)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ComponentLibraryplugin)

# SingleApplication
set(QAPPLICATION_CLASS QApplication)
add_subdirectory(thirdparty/SingleApplication)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE SingleApplication)

# Zip extraction
add_subdirectory(thirdparty/miniz)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE miniz)

# EGM96 altitude correction
add_subdirectory(thirdparty/EGM96)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE EGM96)

# Fast thumbnailer for photo and video
add_subdirectory(thirdparty/MediaThumbnailer)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE MediaThumbnailer)

# MiniVideo
#add_subdirectory(thirdparty/minivideo)
#target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ENABLE_MINIVIDEO)

################################################################################

if(USE_MINIVIDEO)
    # MiniVideo
    add_subdirectory(contribs/build/linux_x86_64/MiniVideo-master/minivideo)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE minivideo)
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ENABLE_MINIVIDEO)
endif()

if(USE_LIBEXIF)
    # libexif
    add_subdirectory(contribs/build/linux_x86_64/libexif-master/)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE exif)
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ENABLE_LIBEXIF)
endif()

if(USE_EXIV2)
    # exiv2
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ENABLE_EXIV2)
endif()

################################################################################

## Release build? Set "no debug" macros
if(CMAKE_BUILD_TYPE STREQUAL Release)
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
        NDEBUG
        QT_NO_DEBUG
        QT_NO_DEBUG_OUTPUT
    )
endif()

################################################################################

## Linux
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    #
endif()

## macOS
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    #set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")

    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE ON
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/assets/macos/Info.plist"
        # New Xcode attributes (???)
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER           "io.emeric.qmlmobilescanner"
        XCODE_ATTRIBUTE_PRODUCT_NAME                        ${CMAKE_PROJECT_NAME}
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION             ${CMAKE_PROJECT_VERSION}
        XCODE_ATTRIBUTE_MARKETING_VERSION                   ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS             "${CMAKE_SOURCE_DIR}/assets/macos/${CMAKE_PROJECT_NAME}.entitlements"
        #XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME  AppIcon
    )
endif()

## Windows
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    #set(app_icon_windows "${CMAKE_SOURCE_DIR}/assets/windows/${CMAKE_PROJECT_NAME}.rc")

    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()

################################################################################

# Output (build)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    #ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/lib"
    #LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
)

################################################################################
