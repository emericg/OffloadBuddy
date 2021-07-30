OffloadBuddy
============

[![GitHub action](https://img.shields.io/github/workflow/status/emericg/OffloadBuddy/CI%20builds.svg?style=flat-square)](https://github.com/emericg/OffloadBuddy/actions)
[![GitHub issues](https://img.shields.io/github/issues/emericg/OffloadBuddy.svg?style=flat-square)](https://github.com/emericg/OffloadBuddy/issues)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=flat-square)](http://www.gnu.org/licenses/gpl-3.0)

OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!  
It's designed to remove the hassle of handling and transferring the many videos and pictures files from your devices like action cameras, regular cameras and smartphones...  

> Works on Linux, macOS and Windows!

### Features:

- [x] Import data from SD cards, mass storage or MTP devices
  - [x] Organize and sort your media library
  - [x] Copy, merge or reencode media
  - [x] Preview videos, photos and timelapses
  - [x] Show and export GoPro telemetry & GPS traces
  - [ ] Change wrong dates (WIP)
- [x] Media transcoding
  - [x] Create short video clips (and GIFs) from your videos!
  - [x] Create videos from timelapses
  - [x] Create timelapse from videos
  - [x] Extract photos/screenshots from videos
- [x] Apply filters to transcoded media
  - [x] Reframe media, change aspect ratio
  - [x] Clip duration
  - [x] Rotate media (WIP)
  - [ ] Defisheye media (WIP)
  - [ ] Stabilize videos
- [x] Telemetry handling
  - [x] Export GoPro telemetry and GPS trace
  - [x] Visualize telemetry with graphs
  - [x] Visualize GPS trace on maps
  - [ ] Video overlay
- [ ] GoPro firmware updates

### Screenshots!

![overview](https://i.imgur.com/4CAhcYb.jpg)
![offload](https://i.imgur.com/9g9Shls.jpg)
![video1](https://i.imgur.com/9IN5NDZ.jpg)
![telemetry](https://i.imgur.com/RN2OPy0.jpg)
![timelapse](https://i.imgur.com/Pt4rz2H.jpg)
![video3](https://i.imgur.com/4avHEnI.jpg)
![resize](https://i.imgur.com/HCs2vKH.jpg)
![clip](https://i.imgur.com/0euEyaN.jpg)

## Documentation

#### Dependencies

You will need a C++14 capable compiler and Qt 5.12+ (with QtMultimedia, QtLocation and QtCharts).  
On Windows, the contribs builds fine with MSVC 2017.  

Build OffloadBuddy:
- Qt (5.12+)  
- pkg-config (linux / macOS without contribs)  

Optional dependencies:
- libusb and libmtp  
- libexif  
- ffmpeg (3.4+)  
- MiniVideo (0.13+)  

Build dependencies:
- python 3  
- cmake  
- and a couple others (see contribs/contribs.py)  

#### Building OffloadBuddy

Build dependencies using the 'contribs' script (optional):
```bash
$ cd OffloadBuddy/contribs/
$ python3 contribs.py
```

Build OffloadBuddy:
```bash
$ cd OffloadBuddy/
$ qmake DEFINES+=USE_CONTRIBS CONFIG+=release
$ make
```

#### Third party projects used by OffloadBuddy

* Qt [website](https://www.qt.io) ([LGPL 3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* MiniVideo [website](https://github.com/emericg/MiniVideo) ([LGPL 3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* ffmpeg [website](https://www.ffmpeg.org/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* libexif [website](https://github.com/libexif/libexif/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* libmtp [website](http://libmtp.sourceforge.net/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* SingleApplication [website](https://github.com/itay-grudev/SingleApplication) ([MIT](https://opensource.org/licenses/MIT))
* Graphical resources: [assets/COPYING](assets/COPYING)

## Get involved!

#### Developers

You can browse the code on the GitHub page, submit patches and pull requests! Your help would be greatly appreciated ;-)

#### Users

You can help us find and report bugs, suggest new features, help with translation, documentation and more! Visit the Issues section of the GitHub page to start!

## License

OffloadBuddy is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.  
Read the [LICENSE](LICENSE) file or [consult the license on the FSF website](https://www.gnu.org/licenses/gpl-3.0.txt) directly.

> Emeric Grange <emeric.grange@gmail.com>
