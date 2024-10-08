OffloadBuddy
============

[![GitHub action](https://img.shields.io/github/actions/workflow/status/emericg/OffloadBuddy/builds_desktop.yml?style=flat-square)](https://github.com/emericg/OffloadBuddy/actions)
[![GitHub issues](https://img.shields.io/github/issues/emericg/OffloadBuddy.svg?style=flat-square)](https://github.com/emericg/OffloadBuddy/issues)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=flat-square)](http://www.gnu.org/licenses/gpl-3.0)

OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!  
It's designed to remove the hassle of handling and transferring the many videos and pictures files from your devices like action cameras, regular cameras and smartphones...  

> Works on Linux, macOS and Windows!

### Features

- [x] Import data from SD cards, mass storage or MTP devices
  - [x] Organize and sort your media library
  - [x] Copy, merge or reencode media
  - [x] Preview videos, photos and timelapses
  - [x] Show and export GoPro telemetry & GPS traces
  - [ ] Change wrong dates (WIP)
- [x] Media transcoding
  - [x] Create short video clips (and GIFs) from your videos!
  - [x] Create videos from timelapses
  - [x] Create timelapses from videos
  - [x] Extract photos/screenshots from videos
- [x] Apply filters to transcoded media
  - [x] Reframe media, change aspect ratio
  - [x] Clip duration
  - [x] Rotate media
  - [ ] Defisheye media (WIP)
  - [ ] Stabilize videos
- [x] Telemetry handling
  - [x] Export GoPro telemetry and GPS trace
  - [x] Visualize telemetry with graphs
  - [x] Visualize GPS trace on maps
  - [ ] Video overlay
- [X] GoPro firmware updates


## Screenshots

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

You will need a C++17 compiler and Qt 6.5+ with the following 'additional librairies':  
- Qt Multimedia
- Qt Positioning
- Qt Location
- Qt Charts

On Windows, the contribs builds fine with MSVC 2019 and 2022.  
On macOS you will need Xcode 13+.  

OffloadBuddy dependencies:
- Qt (6.5+)  
- pkg-config (linux / macOS without contribs)  

Optional dependencies:
- libusb and libmtp  
- libexif  
- ffmpeg (4+)  
- MiniVideo (0.15+)  

Build dependencies:
- python 3  
- cmake  
- and a couple others (see contribs/contribs.py)  

#### Building OffloadBuddy

Clone the repository:

```bash
$ git clone https://github.com/emericg/OffloadBuddy.git
```

You can either use the libraries from your system, or use the `contribs_builder.py` script to build necessary libraries.  
You will probably need to use this script, because some libraries aren't widely available in package managers. Also, if you wish to cross compile for Android or iOS, the script will make your life so much easier.  

Build dependencies using the `contribs_builder.py` script (optional):

```bash
$ cd OffloadBuddy/contribs/
$ python3 contribs_builder.py
```

Build OffloadBuddy:

```bash
$ cd OffloadBuddy/
$ qmake6 DEFINES+=USE_CONTRIBS CONFIG+=release
$ make
```

#### Third party projects used by OffloadBuddy

* [Qt6](https://www.qt.io) ([LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* [MiniVideo](https://github.com/emericg/MiniVideo) ([LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* [ffmpeg](https://www.ffmpeg.org/) ([LGPL v2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* [libexif](https://github.com/libexif/) ([LGPL v2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* [libmtp](https://github.com/libmtp/) ([LGPL v2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* [miniz](https://github.com/richgel999/miniz/) ([MIT](https://opensource.org/licenses/MIT))
* [SingleApplication](https://github.com/itay-grudev/SingleApplication) ([MIT](https://opensource.org/licenses/MIT))
* Icons: [assets/icons/COPYING](assets/icons/COPYING)
* Graphical resources: [assets/cameras/COPYING](assets/cameras/COPYING) [assets/gfx/COPYING](assets/gfx/COPYING)


## Get involved!

#### Developers

You can browse the code on the GitHub page, submit patches and pull requests! Your help would be greatly appreciated ;-)

#### Users

You can help us find and report bugs, suggest new features, help with translation, documentation and more! Visit the Issues section of the GitHub page to start!


## License

OffloadBuddy is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.  
Read the [LICENSE](LICENSE.md) file or [consult the license on the FSF website](https://www.gnu.org/licenses/gpl-3.0.txt) directly.

> Emeric Grange <emeric.grange@gmail.com>
