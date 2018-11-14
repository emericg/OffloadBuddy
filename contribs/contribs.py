#!/usr/bin/env python

import os
import sys

if sys.version_info < (3, 0):
    print("This script NEEDS Python 3. Run it with 'python3 contribs.py'")
    sys.exit()

import platform
import multiprocessing
import shutil
import zipfile
import tarfile
import argparse
import subprocess
import urllib.request

print("\n> OffloadBuddy contribs builder")

## DEPENDENCIES ###############################################################

## linux:
# cmake libtool automake m4 libudev-dev

## macOS:
# brew install python cmake automake
# brew install libtool pkg-config

## Windows:
# python3 (https://www.python.org/downloads/)
# cmake (https://cmake.org/download/)
# MSVC 2017

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
# - Windows (mingw32-w64)

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

## UTILS #######################################################################

def copytree(src, dst, symlinks=False, ignore=None):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            copytree(s, d, symlinks, ignore)
        else:
            if not os.path.exists(d) or os.stat(s).st_mtime - os.stat(d).st_mtime > 1:
                shutil.copy2(s, d)

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
    print("> Downloading " + FILE_libexif + "...")
    urllib.request.urlretrieve("https://github.com/emericg/libexif/archive/master.zip", src_dir + FILE_libexif)

## minivideo
## version: git (0.10+)
FILE_minivideo = "minivideo-master.zip"
DIR_minivideo = "MiniVideo-master"

if not os.path.exists("src/" + FILE_minivideo):
    print("> Downloading " + FILE_minivideo + "...")
    urllib.request.urlretrieve("https://github.com/emericg/MiniVideo/archive/master.zip", src_dir + FILE_minivideo)

## ffmpeg
## version: 4.0.3
ffmpeg_VERSION="ffmpeg-4.0.3"
DIR_ffmpeg = ffmpeg_VERSION
FILE_ffmpeg = ffmpeg_VERSION + ".tar.xz"

if not os.path.exists("src/" + FILE_ffmpeg):
    print("> Downloading " + FILE_ffmpeg + "...")
    urllib.request.urlretrieve("http://www.ffmpeg.org/releases/" + FILE_ffmpeg, src_dir + FILE_ffmpeg)

## ffmpeg (src & bin)
ffmpeg_SRC="https://www.ffmpeg.org/releases/" + ffmpeg_VERSION + ".tar.xz"
ffmpeg_BIN_BASEURL="https://sourceforge.net/projects/avbuild/files/"
ffmpeg_BIN_PF1=["windows-desktop", "windows-desktop", "windows-store", "macOS", "iOS", "linux", "android"]
ffmpeg_BIN_PF2=["desktop-VS2017", "desktop-MINGW", "store-VS2017", "macOS", "iOS", "linux-gcc", "android-clang"]
ffmpeg_BIN_EDITION="-lite"
ffmpeg_BIN_EXT=[".7z", ".7z", ".7z", ".tar.xz", ".tar.xz", ".tar.xz", ".tar.xz"]

## linuxdeployqt
## version: git
if OS_HOST == "Linux":
    FILE_linuxdeployqt = "linuxdeployqt-continuous-x86_64.AppImage"
    if not os.path.exists("src/" + FILE_linuxdeployqt):
        print("> Downloading " + FILE_linuxdeployqt + "...")
        urllib.request.urlretrieve("https://github.com/probonopd/linuxdeployqt/releases/download/continuous/" + FILE_linuxdeployqt, src_dir + FILE_linuxdeployqt)

## CHOOSE TARGETS ##############################################################

TARGETS = []

if OS_HOST == "Linux":
    TARGETS.append(["linux", "x86_64"])
    #TARGETS.append(["windows", "x86_64"])

if OS_HOST == "Darwin":
    TARGETS.append(["macOS", "x86_64"])

if OS_HOST == "Windows":
    TARGETS.append(["windows", "x86_64"])
    #TARGETS.append(["windows", "armv7"]) # WinRT

## EXECUTE #####################################################################

for TARGET in TARGETS:

    ## PREPARE environment
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

    ## CMAKE command selection
    CMAKE_cmd = ["cmake"]
    CMAKE_gen = "Unix Makefiles"
    if OS_HOST == "Linux":
        if OS_TARGET == "windows":
            if ARCH_TARGET == "i686":
                CMAKE_cmd = ["i686-w64-mingw32-cmake"]
            else:
                CMAKE_cmd = ["x86_64-w64-mingw32-cmake"]
    elif OS_HOST == "Windows":
        if ARCH_TARGET == "x86_64":
            CMAKE_gen = "Visual Studio 15 2017 Win64"
        elif ARCH_TARGET == "armv7":
            CMAKE_gen = "Visual Studio 15 2017 ARM"
        else:
            CMAKE_gen = "Visual Studio 15 2017"

    ## ffmpeg archive selection
    if OS_HOST == "Linux":
        if OS_TARGET == "windows":
            pfid = 7
        else:
            pfid = 5
    if OS_HOST == "Darwin":
        pfid = 3
    if OS_HOST == "Windows":
        pfid = 0

    ############################################################################

    ## EXTRACT
    if OS_HOST != "Windows":
        if not os.path.isdir(build_dir + DIR_libusb):
            zipUSB = zipfile.ZipFile(src_dir + FILE_libusb)
            zipUSB.extractall(build_dir)
        if not os.path.isdir(build_dir + DIR_libmtp):
            zipMTP = zipfile.ZipFile(src_dir + FILE_libmtp)
            zipMTP.extractall(build_dir)

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
        os.chmod("bootstrap.sh", 509)
        os.system("./bootstrap.sh")
        os.system("./configure --prefix=" + env_dir + "/usr")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")
        # libMTP
        os.chdir(build_dir + DIR_libmtp)
        os.chmod("autogen.sh", 509)
        os.system("./autogen.sh << \"y\"")
        os.system("./configure --disable-mtpz --prefix=" + env_dir + "/usr --with-udev=" + env_dir + "/usr/lib/udev")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")

    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_STATIC_LIBS:BOOL=OFF", "-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE", "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", ".", "--config", "Release"], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install", "--config", "Release"], cwd=build_dir + DIR_libexif + "/build")

    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_STATIC_LIBS:BOOL=OFF", "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", ".", "--config", "Release"], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install", "--config", "Release"], cwd=build_dir + DIR_minivideo + "/minivideo/build")

    ############################################################################

    ## ffmpeg binaries download & install
    FFMPEG_FILE_DST=src_dir + ffmpeg_VERSION + "-" + ffmpeg_BIN_PF2[pfid] + ffmpeg_BIN_EDITION + ffmpeg_BIN_EXT[pfid]
    FFMPEG_FILE_DIR=build_dir + ffmpeg_VERSION + "-" + ffmpeg_BIN_PF2[pfid] + ffmpeg_BIN_EDITION
    FFMPEG_FILE_URL=ffmpeg_BIN_BASEURL + ffmpeg_BIN_PF1[pfid] + "/" + ffmpeg_VERSION + "-" + ffmpeg_BIN_PF2[pfid] + ffmpeg_BIN_EDITION + ffmpeg_BIN_EXT[pfid] + "/download"

    if not os.path.exists(FFMPEG_FILE_DST):
        print("> Downloading " + FFMPEG_FILE_DST)
        urllib.request.urlretrieve(FFMPEG_FILE_URL, FFMPEG_FILE_DST)

    if not os.path.isdir(FFMPEG_FILE_DIR):
        if ffmpeg_BIN_EXT[pfid] == ".tar.xz":
            zipFF = tarfile.open(FFMPEG_FILE_DST)
            zipFF.extractall(build_dir)
        elif ffmpeg_BIN_EXT[pfid] == ".7z":
            if os.path.isfile("C:\\Program Files\\7-Zip\\7z.exe"):
                os.system('"C:\\Program Files\\7-Zip\\7z.exe" x ' + FFMPEG_FILE_DST + " -aos -o" + build_dir)
            else:
                print("!!! CANNOT EXTRACT 7z files AUTOMATICALLY, PLEASE DO IT YOURSELF !!!")
                sys.exit(0)

    copytree(FFMPEG_FILE_DIR + "/include/", env_dir + "/usr/include")
    if TARGET[0] == "android":
        if TARGET[1] == "armv7":
            copytree(FFMPEG_FILE_DIR + "/lib/armeabi-v7a/", env_dir + "/usr/lib")
        elif TARGET[1] == "armv8":
            copytree(FFMPEG_FILE_DIR + "/lib/arm64-v8a/", env_dir + "/usr/lib")
    if TARGET[0] == "windows":
        if TARGET[1] == "x86_64":
            copytree(FFMPEG_FILE_DIR + "/bin/x64/", env_dir + "/usr/lib")
            copytree(FFMPEG_FILE_DIR + "/lib/x64/", env_dir + "/usr/lib")
    else:
        copytree(FFMPEG_FILE_DIR + "/lib/", env_dir + "/usr/lib")
