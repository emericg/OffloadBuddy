#!/usr/bin/env python

import os
import sys
import platform
import multiprocessing

import shutil
import zipfile
import argparse
import subprocess

if sys.version_info >= (3, 0):
    import urllib.request
else: # python2
    import urllib

print("\n> OffloadBuddy contribs builder")

## SANITY CHECKS ###############################################################

if platform.system() != "Windows":
    if os.getuid() == 0:
        print("This script MUST NOT be run as root")
        sys.exit()

if os.path.basename(os.getcwd()) != "contribs":
    print("This script MUST be run from the contribs/ directory")
    sys.exit()

if platform.machine() not in ("x86_64", "AMD64"):
    print("This script needs a 64bits OS")
    sys.exit()

## HOST ########################################################################

# Supported platforms / architectures:
# Natives:
# - Linux
# - Darwin (macOS)
# - Windows
# Cross compilation (from Linux):
# - Android (armv7a, armv8a)
# - Windows (mingw32-w64)
# Cross compilation (from macOS):
# - iOS (?)

OS_HOST = platform.system()
ARCH_HOST = platform.machine()
CPU_COUNT = multiprocessing.cpu_count()

print("HOST SYSTEM : " + platform.system() + " (" + platform.release() + ") [" + os.name + "]")
print("HOST ARCH   : " + ARCH_HOST)
print("HOST CPUs   : " + str(CPU_COUNT) + " cores")

## SETTINGS ####################################################################

contribs_dir = os.getcwd() + "/"
src_dir = contribs_dir + "src/"

clean = False
rebuild = False
ANDROID_NDK_HOME = os.getenv('ANDROID_NDK_HOME', '')

## ARGUMENTS ###################################################################

parser = argparse.ArgumentParser(prog='contribs.py',
                                 description='ReShoot contribs builder',
                                 formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument('-c', '--clean', help="clean everything and exit (downloaded files and all temporary directories)", action='store_true')
parser.add_argument('-r', '--rebuild', help="rebuild the contribs even if already builded", action='store_true')
parser.add_argument('--android-ndk', dest='androidndk', help="specify a custom path to the android-ndk (if ANDROID_NDK_HOME environment variable doesn't exists)")

if len(sys.argv) > 1:
    result = parser.parse_args()
    if result.clean:
        clean = result.clean
    if result.rebuild:
        rebuild = result.rebuild
    if result.androidndk:
        ANDROID_NDK_HOME = result.androidndk

## CLEAN #######################################################################

if rebuild:
    if os.path.exists(contribs_dir + "build/"):
        shutil.rmtree(contribs_dir + "build/")

if clean:
    if os.path.exists(contribs_dir + "src/"):
        shutil.rmtree(contribs_dir + "src/")
    if os.path.exists(contribs_dir + "build/"):
        shutil.rmtree(contribs_dir + "build/")
    if os.path.exists(contribs_dir + "env/"):
        shutil.rmtree(contribs_dir + "env/")
    print(">> Contribs cleaned!")
    sys.exit()

## SOFTWARES ###################################################################

if not os.path.exists(src_dir):
    os.makedirs(src_dir)

## libUSB & libMTP
## version: git (1.0.22+)
FILE_libusb = "libusb-master.tar.gz"
DIR_libusb = "libusb-master"
## version: git (1.15+)
FILE_libmtp = "libmtp-master.tar.gz"
DIR_libmtp = "libmtp-master"

if OS_HOST != "Windows":
    if not os.path.exists("src/" + FILE_libusb):
        print("> Downloading " + FILE_libusb)
        if sys.version_info >= (3, 0):
            urllib.request.urlretrieve("https://github.com/libusb/libusb/archive/master.zip", src_dir + FILE_libusb)
        else:
            urllib.urlretrieve("https://github.com/libusb/libusb/archive/master.zip", src_dir + FILE_libusb)
    if not os.path.exists("src/" + FILE_libmtp):
        print("> Downloading " + FILE_libmtp)
        if sys.version_info >= (3, 0):
            urllib.request.urlretrieve("https://github.com/libmtp/libmtp/archive/master.zip", src_dir + FILE_libmtp)
        else:
            urllib.urlretrieve("https://github.com/libmtp/libmtp/archive/master.zip", src_dir + FILE_libmtp)

## libexif
## version: git (0.6.21+)
FILE_libexif = "libexif-master.zip"
DIR_libexif = "libexif-master"

if not os.path.exists("src/" + FILE_libexif):
    print("> Downloading " + FILE_libexif)
    if sys.version_info >= (3, 0):
        urllib.request.urlretrieve("https://github.com/emericg/libexif/archive/master.zip", src_dir + FILE_libexif)
    else:
        urllib.urlretrieve("https://github.com/libexif/emericg/archive/master.zip", src_dir + FILE_libexif)

## minivideo
## version: git (0.10+)
FILE_minivideo = "minivideo-master.zip"
DIR_minivideo = "MiniVideo-master"

if not os.path.exists("src/" + FILE_minivideo):
    print("> Downloading " + FILE_minivideo)
    if sys.version_info >= (3, 0):
        urllib.request.urlretrieve("https://github.com/emericg/MiniVideo/archive/master.zip", src_dir + FILE_minivideo)
    else:
        urllib.urlretrieve("https://github.com/emericg/MiniVideo/archive/master.zip", src_dir + FILE_minivideo)

## ffmpeg
## version: 4.0.2
FILE_ffmpeg = "ffmpeg-4.0.2.tar.xz"
DIR_ffmpeg = "ffmpeg-4.0.2"

if not os.path.exists("src/" + FILE_ffmpeg):
    print("> Downloading " + FILE_ffmpeg)
    if sys.version_info >= (3, 0):
        urllib.request.urlretrieve("http://www.ffmpeg.org/releases/" + FILE_ffmpeg, src_dir + FILE_ffmpeg)
    else:
        urllib.urlretrieve("http://www.ffmpeg.org/releases/" + FILE_ffmpeg, src_dir + FILE_ffmpeg)

## linuxdeployqt
## version: git
if OS_HOST == "Linux":
    FILE_linuxdeployqt = "linuxdeployqt-continuous-x86_64.AppImage"
    if not os.path.exists("src/" + FILE_linuxdeployqt):
        print("> Downloading " + FILE_linuxdeployqt)
        if sys.version_info >= (3, 0):
            urllib.request.urlretrieve("https://github.com/probonopd/linuxdeployqt/releases/download/continuous/" + FILE_linuxdeployqt, src_dir + FILE_linuxdeployqt)
        else:
            urllib.urlretrieve("https://github.com/probonopd/linuxdeployqt/releases/download/continuous/" + FILE_linuxdeployqt, src_dir + FILE_linuxdeployqt)

## CHOOSE TARGETS ##############################################################

TARGETS = []

if OS_HOST == "Linux":
    TARGETS.append(["linux", "x86_64"])

if OS_HOST == "Darwin":
    TARGETS.append(["macOS", "x86_64"])

if OS_HOST == "Windows":
    TARGETS.append(["windows", "x86_64"])

## EXECUTE #####################################################################

for TARGET in TARGETS:

    ## PREPARE
    OS_TARGET = TARGET[0]
    ARCH_TARGET = TARGET[1]

    build_dir = contribs_dir + "build/" + OS_TARGET + "_" + ARCH_TARGET + "/"
    env_dir = contribs_dir + "env/" + OS_TARGET + "_" + ARCH_TARGET + "/"

    try:
        os.makedirs(build_dir)
        os.makedirs(env_dir)
    except:
        print() # who cares

    print("> TARGET : " + str(TARGET))
    print("- build_dir : " + build_dir)
    print("- env_dir : " + env_dir)

    ## CMAKE command
    CMAKE_cmd = ["cmake"]
    CMAKE_gen = "Unix Makefiles"
    if OS_HOST == "Linux":
        if OS_TARGET == "android":
            if ARCH_TARGET == "armv8":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=clang", "-DANDROID_ABI=arm64-v8a"]
            else:
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=gcc", "-DANDROID_ABI=armeabi-v7a"]
        if OS_TARGET == "windows":
            if ARCH_TARGET == "i686":
                CMAKE_cmd = ["i686-w64-mingw32-cmake"]
            else:
                CMAKE_cmd = ["x86_64-w64-mingw32-cmake"]
    elif OS_HOST == "Darwin":
        if OS_TARGET == "iOS":
            if ARCH_TARGET == "armv8":
                CMAKE_cmd = ["ios-armv8-cmake"]
            else:
                CMAKE_cmd = ["ios-armv7-cmake"]
    elif OS_HOST == "Windows":
        if ARCH_TARGET == "x86_64":
            CMAKE_gen = "Visual Studio 15 2017 Win64"
        elif ARCH_TARGET == "armv7":
            CMAKE_gen = "Visual Studio 15 2017 ARM"
        else:
            CMAKE_gen = "Visual Studio 15 2017"

    ## EXTRACT
    if OS_HOST != "Windows":
        if not os.path.isdir(build_dir + DIR_libmtp):
            zipMTP = zipfile.ZipFile(src_dir + FILE_libmtp)
            zipMTP.extractall(build_dir)
        if not os.path.isdir(build_dir + DIR_libusb):
            zipUSB = zipfile.ZipFile(src_dir + FILE_libusb)
            zipUSB.extractall(build_dir)

    if not os.path.isdir(build_dir + DIR_libexif):
        zipEX = zipfile.ZipFile(src_dir + FILE_libexif)
        zipEX.extractall(build_dir)

    if not os.path.isdir(build_dir + DIR_minivideo):
        zipMV = zipfile.ZipFile(src_dir + FILE_minivideo)
        zipMV.extractall(build_dir)

    ## BUILD & INSTALL
    if OS_HOST != "Windows":
        # libUSB
        os.chdir(build_dir + DIR_libusb)
        os.chmod("autogen.sh", 509)
        os.system("./autogen.sh <<< \"y\"")
        os.system("./configure --prefix=" + env_dir + "/usr")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")
        os.chdir(build_dir + DIR_libusb)
        # libMTP
        os.chdir(build_dir + DIR_libmtp)
        os.chmod("autogen.sh", 509)
        os.system("./autogen.sh <<< \"y\"")
        os.system("./configure --prefix=" + env_dir + "/usr --with-udev=" + env_dir + "/usr/lib/udev")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")
        os.chdir(build_dir + DIR_libmtp)

    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_STATIC_LIBS:BOOL=OFF", "-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE", "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", "."], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install"], cwd=build_dir + DIR_libexif + "/build")

    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_STATIC_LIBS:BOOL=OFF", "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", "."], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install"], cwd=build_dir + DIR_minivideo + "/minivideo/build")
