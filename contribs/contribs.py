#!/usr/bin/env python3

import os
import sys
import platform
import multiprocessing
import glob
import shutil
import zipfile
import tarfile
import argparse
import subprocess
import urllib.request

print("\n> OffloadBuddy contribs builder")

if sys.version_info < (3, 0):
    print("This script NEEDS Python 3. Run it with 'python3 contribs.py'")
    sys.exit()

## DEPENDENCIES ################################################################
# These software dependencies are needed for this script to run!

## linux:
# python3 cmake ninja libtool automake m4 libudev-dev

## macOS:
# brew install python cmake automake ninja
# brew install libtool pkg-config
# brew install gettext iconv libudev
# brew link --force gettext
# xcode (10+)

## Windows:
# python3 (https://www.python.org/downloads/)
# cmake (https://cmake.org/download/)
# MSVC (2017+)

## HOST ########################################################################

# Supported platforms / architectures:
# Natives:
# - Linux
# - Darwin (macOS)
# - Windows
# Cross compilation (from Linux):
# - Windows (mingw32-w64)
# Cross compilation (from macOS):
# - iOS (simulator, armv7, armv8)
# Cross compilation (from Linux or macOS):
# - Android (armv7, armv8)

OS_HOST = platform.system()
ARCH_HOST = platform.machine()
CPU_COUNT = multiprocessing.cpu_count()

print("HOST SYSTEM : " + platform.system() + " (" + platform.release() + ") [" + os.name + "]")
print("HOST ARCH   : " + ARCH_HOST)
print("HOST CPUs   : " + str(CPU_COUNT) + " cores")

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

## SETTINGS ####################################################################

contribs_dir = os.getcwd()
src_dir = contribs_dir + "/src/"

clean = False
rebuild = False
ANDROID_NDK_HOME = os.getenv('ANDROID_NDK_HOME', '')

# MSVC_GEN_VER
if "14.0" in os.getenv('VisualStudioVersion', ''):
    MSVC_GEN_VER = "Visual Studio 14 2015"
elif "15.0" in os.getenv('VisualStudioVersion', ''):
    MSVC_GEN_VER = "Visual Studio 15 2017"
else:
    MSVC_GEN_VER = "Visual Studio 16 2019"

## ARGUMENTS ###################################################################

parser = argparse.ArgumentParser(prog='contribs.py',
                                 description='OffloadBuddy contribs builder',
                                 formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument('-c', '--clean', help="clean everything and exit (downloaded files and all temporary directories)", action='store_true')
parser.add_argument('-r', '--rebuild', help="rebuild the contribs even if already built", action='store_true')
parser.add_argument('--android-ndk', dest='androidndk', help="specify a custom path to the android-ndk (if ANDROID_NDK_HOME environment variable doesn't exists)")
parser.add_argument('--msvc', dest='msvcversion', help="specify a version for Visual Studio (2015/2017/2019)")

if len(sys.argv) > 1:
    result = parser.parse_args()
    if result.clean:
        clean = result.clean
    if result.rebuild:
        rebuild = result.rebuild
    if result.androidndk:
        ANDROID_NDK_HOME = result.androidndk
    if result.msvcversion:
        if result.msvcversion == 2015:
            MSVC_GEN_VER = "Visual Studio 14 2015"
        elif result.msvcversion == 2017:
            MSVC_GEN_VER = "Visual Studio 15 2017"
        elif result.msvcversion == 2019:
            MSVC_GEN_VER = "Visual Studio 16 2019"

## CLEAN #######################################################################

if rebuild:
    if os.path.exists(contribs_dir + "/build/"):
        shutil.rmtree(contribs_dir + "/build/")

if clean:
    if os.path.exists(contribs_dir + "/src/"):
        shutil.rmtree(contribs_dir + "/src/")
    if os.path.exists(contribs_dir + "/build/"):
        shutil.rmtree(contribs_dir + "/build/")
    if os.path.exists(contribs_dir + "/env/"):
        shutil.rmtree(contribs_dir + "/env/")
    print(">> Contribs cleaned!")
    sys.exit()

if not os.path.exists(src_dir):
    os.makedirs(src_dir)

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

def copytree_wildcard(src, dst, symlinks=False, ignore=None):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for item in glob.glob(src):
        shutil.copy2(item, dst)

## TARGETS #####################################################################

TARGETS = []

if OS_HOST == "Linux":
    TARGETS.append(["linux", "x86_64"])
    #if ANDROID_NDK_HOME:
    #    TARGETS.append(["android", "armv8"])
    #    TARGETS.append(["android", "armv7"])
    #    TARGETS.append(["android", "x86_64"])
    #    TARGETS.append(["android", "x86"])
    #TARGETS.append(["windows", "x86_64"]) # Windows cross compilation

if OS_HOST == "Darwin":
    TARGETS.append(["macOS", "x86_64"])
    #TARGETS.append(["iOS", "simulator"])
    #TARGETS.append(["iOS", "armv8"])
    #TARGETS.append(["iOS", "armv7"])
    #if ANDROID_NDK_HOME:
    #    TARGETS.append(["android", "armv8"])
    #    TARGETS.append(["android", "armv7"])
    #    TARGETS.append(["android", "x86_64"])
    #    TARGETS.append(["android", "x86"])

if OS_HOST == "Windows":
    TARGETS.append(["windows", "x86_64"])
    #TARGETS.append(["windows", "x86"])
    #TARGETS.append(["windows", "armv7"]) # WinRT

## SOFTWARES ###################################################################

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
## version: git (0.6.22+)
FILE_libexif = "libexif-master.zip"
DIR_libexif = "libexif-master"

if not os.path.exists("src/" + FILE_libexif):
    print("> Downloading " + FILE_libexif + "...")
    urllib.request.urlretrieve("https://github.com/emericg/libexif/archive/master.zip", src_dir + FILE_libexif)

## taglib
## version: git (1.12 beta)
FILE_taglib = "taglib-master.zip"
DIR_taglib = "taglib-master"

if not os.path.exists("src/" + FILE_taglib):
    print("> Downloading " + FILE_taglib + "...")
    urllib.request.urlretrieve("https://github.com/taglib/taglib/archive/master.zip", src_dir + FILE_taglib)

## minivideo
## version: git (0.13+)
FILE_minivideo = "minivideo-master.zip"
DIR_minivideo = "MiniVideo-master"

if not os.path.exists("src/" + FILE_minivideo):
    print("> Downloading " + FILE_minivideo + "...")
    urllib.request.urlretrieve("https://github.com/emericg/MiniVideo/archive/master.zip", src_dir + FILE_minivideo)

## Android OpenSSL
for TARGET in TARGETS:
    if TARGET[0] == "android":
        FILE_androidopenssl = "android_openssl-master.zip"
        DIR_androidopenssl = "android_openssl"

        if not os.path.exists("src/" + FILE_androidopenssl):
            print("> Downloading " + FILE_androidopenssl + "...")
            urllib.request.urlretrieve("https://github.com/KDAB/android_openssl/archive/master.zip", src_dir + FILE_androidopenssl)
        if not os.path.isdir("env/" + DIR_androidopenssl):
            zipSSL = zipfile.ZipFile(src_dir + FILE_androidopenssl)
            zipSSL.extractall("env/")
        break

## linuxdeployqt
## version: git
if OS_HOST == "Linux":
    FILE_linuxdeployqt = "linuxdeployqt-6-x86_64.AppImage"
    if not os.path.exists("src/" + FILE_linuxdeployqt):
        print("> Downloading " + FILE_linuxdeployqt + "...")
        urllib.request.urlretrieve("https://github.com/probonopd/linuxdeployqt/releases/download/6/" + FILE_linuxdeployqt, src_dir + FILE_linuxdeployqt)

## EXECUTE #####################################################################

for TARGET in TARGETS:

    ## PREPARE environment
    OS_TARGET = TARGET[0]
    ARCH_TARGET = TARGET[1]

    build_dir = contribs_dir + "/build/" + OS_TARGET + "_" + ARCH_TARGET + "/"
    env_dir = contribs_dir + "/env/" + OS_TARGET + "_" + ARCH_TARGET + "/"

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
    CMAKE_gen = "Unix Makefiles" # Can be "Ninja" on modern environment
    build_shared = "ON"
    build_static = "OFF"

    if OS_HOST == "Linux":
        if OS_TARGET == "windows":
            if ARCH_TARGET == "i686":
                CMAKE_cmd = ["i686-w64-mingw32-cmake"]
            else:
                CMAKE_cmd = ["x86_64-w64-mingw32-cmake"]
    elif OS_HOST == "Darwin":
        if OS_TARGET == "iOS":
            CMAKE_gen = "Xcode"
            #IOS_DEPLOYMENT_TARGET="10.0"
            build_shared = "OFF"
            build_static = "ON"
            if ARCH_TARGET == "simulator":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + contribs_dir + "/tools/ios.toolchain.cmake", "-DPLATFORM=SIMULATOR64"]
            elif ARCH_TARGET == "armv7":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + contribs_dir + "/tools/ios.toolchain.cmake", "-DPLATFORM=OS"]
            elif ARCH_TARGET == "armv8":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + contribs_dir + "/tools/ios.toolchain.cmake", "-DPLATFORM=OS64"]
            else:
                # Without custom toolchain
                CMAKE_cmd = ["cmake", "-DCMAKE_SYSTEM_NAME=iOS","-DCMAKE_OSX_ARCHITECTURES=arm64","-DCMAKE_OSX_DEPLOYMENT_TARGET=10.0"]
    elif OS_HOST == "Windows":
        CMAKE_gen = MSVC_GEN_VER
        if ARCH_TARGET == "armv7":
            CMAKE_cmd = ["cmake", "-A", "ARM"]
        elif ARCH_TARGET == "armv8":
            CMAKE_cmd = ["cmake", "-A", "ARM64"]
        elif ARCH_TARGET == "x86":
            CMAKE_cmd = ["cmake", "-A", "Win32"]
        else:
            CMAKE_cmd = ["cmake", "-A", "x64"]

    if OS_HOST == "Linux" or OS_HOST == "Darwin":
        if OS_TARGET == "android":
            if ARCH_TARGET == "x86":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=clang", "-DANDROID_ABI=x86", "-DANDROID_PLATFORM=android-21"]
            elif ARCH_TARGET == "x86_64":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=clang", "-DANDROID_ABI=x86_64", "-DANDROID_PLATFORM=android-21"]
            elif ARCH_TARGET == "armv7":
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=clang", "-DANDROID_ABI=armeabi-v7a", "-DANDROID_PLATFORM=android-21"]
            else:
                CMAKE_cmd = ["cmake", "-DCMAKE_TOOLCHAIN_FILE=" + ANDROID_NDK_HOME + "/build/cmake/android.toolchain.cmake", "-DANDROID_TOOLCHAIN=clang", "-DANDROID_ABI=arm64-v8a", "-DANDROID_PLATFORM=android-21"]

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
        print("> Building libUSB")
        os.chdir(build_dir + DIR_libusb)
        os.chmod("bootstrap.sh", 509)
        os.system("./bootstrap.sh")
        os.system("./configure --prefix=" + env_dir + "/usr")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")
        # libMTP
        print("> Building libMTP")
        os.chdir(build_dir + DIR_libmtp)
        os.chmod("autogen.sh", 509)
        os.system("./autogen.sh << \"y\"")
        os.system("./configure --disable-mtpz --prefix=" + env_dir + "/usr --with-udev=" + env_dir + "/usr/lib/udev")
        os.system("make -j" + str(CPU_COUNT))
        os.system("make install")

    # libexif
    print("> Building libexif")
    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS:BOOL=" + build_shared, "-DBUILD_STATIC_LIBS:BOOL=" + build_static, "-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE", "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", ".", "--config", "Release"], cwd=build_dir + DIR_libexif + "/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install", "--config", "Release"], cwd=build_dir + DIR_libexif + "/build")

    # minivideo
    print("> Building minivideo")
    subprocess.check_call(CMAKE_cmd + ["-G", CMAKE_gen, "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS:BOOL=" + build_shared, "-DBUILD_STATIC_LIBS:BOOL=" + build_static, "-DCMAKE_INSTALL_PREFIX=" + env_dir + "/usr", ".."], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", ".", "--config", "Release"], cwd=build_dir + DIR_minivideo + "/minivideo/build")
    subprocess.check_call(["cmake", "--build", ".", "--target", "install", "--config", "Release"], cwd=build_dir + DIR_minivideo + "/minivideo/build")

    ############################################################################

    ## ffmpeg binaries download & install
    FFMPEG_version = "4.3.1"
    FFMPEG_key = ""
    FFMPEG_lgpl = "" # can be "-lgpl" or empty

    if OS_TARGET == "windows":
        FFMPEG_key = "win64"
    if OS_TARGET == "macOS":
        FFMPEG_key = "macos64"
    if OS_TARGET == "linux" or OS_TARGET == "android":
        continue

    opener = urllib.request.build_opener()
    opener.addheaders = [('User-agent', 'Mozilla/5.0')]
    urllib.request.install_opener(opener)

    ## HEADERS

    FFMPEG_FOLDER = build_dir + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-dev" + FFMPEG_lgpl
    FFMPEG_FILE = src_dir + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-dev" + FFMPEG_lgpl + ".zip"
    FFMPEG_URL = "https://emeric.io/CI/ffmpeg-zeranoe/" + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-dev" + FFMPEG_lgpl + ".zip"

    if not os.path.exists(FFMPEG_FILE):
        print("> Downloading " + FFMPEG_URL)
        urllib.request.urlretrieve(FFMPEG_URL, FFMPEG_FILE)

    if not os.path.exists(FFMPEG_FOLDER):
        print("> Extracting " + FFMPEG_FILE)
        zipFF = zipfile.ZipFile(FFMPEG_FILE)
        zipFF.extractall(build_dir)

    if os.path.exists(FFMPEG_FOLDER):
        print("> Installing " + FFMPEG_FILE)
        copytree(FFMPEG_FOLDER + "/include/", env_dir + "/usr/include")
        if OS_TARGET == "windows":
            copytree_wildcard(FFMPEG_FOLDER + "/lib/*.lib", env_dir + "/usr/lib")

    ## LIBS

    FFMPEG_FOLDER = build_dir + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-shared" + FFMPEG_lgpl
    FFMPEG_FILE = src_dir + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-shared" + FFMPEG_lgpl + ".zip"
    FFMPEG_URL = "https://emeric.io/assets/ffmpeg-zeranoe/" + "ffmpeg-" + FFMPEG_version + "-" + FFMPEG_key + "-shared" + FFMPEG_lgpl + ".zip"

    if not os.path.exists(FFMPEG_FILE):
        print("> Downloading " + FFMPEG_URL)
        urllib.request.urlretrieve(FFMPEG_URL, FFMPEG_FILE)

    if not os.path.exists(FFMPEG_FOLDER):
        print("> Extracting " + FFMPEG_FILE)
        zipFF = zipfile.ZipFile(FFMPEG_FILE)
        zipFF.extractall(build_dir)

    if os.path.exists(FFMPEG_FOLDER):
        print("> Installing " + FFMPEG_FILE)
        if OS_TARGET == "macOS":
            copytree_wildcard(FFMPEG_FOLDER + "/bin/ffmpeg", env_dir + "/usr/bin")
            copytree_wildcard(FFMPEG_FOLDER + "/bin/*.dylib", env_dir + "/usr/lib")
            os.chdir(env_dir + "/usr/lib")
            os.symlink("libavcodec.58.dylib", "libavcodec.dylib")
            os.symlink("libavdevice.58.dylib", "libavdevice.dylib")
            os.symlink("libavfilter.7.dylib", "libavfilter.dylib")
            os.symlink("libavformat.58.dylib", "libavformat.dylib")
            os.symlink("libavutil.56.dylib", "libavutil.dylib")
            os.symlink("libpostproc.55.dylib", "libpostproc.dylib")
            os.symlink("libswresample.3.dylib", "libswresample.dylib")
            os.symlink("libswscale.5.dylib", "libswscale.dylib")

        if OS_TARGET == "windows":
            copytree_wildcard(FFMPEG_FOLDER + "/bin/*.dll", env_dir + "/usr/lib")
            copytree_wildcard(FFMPEG_FOLDER + "/bin/ffmpeg.exe", env_dir + "/usr/bin")
