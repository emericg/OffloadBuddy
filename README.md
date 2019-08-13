OffloadBuddy
============

[![Travis](https://img.shields.io/travis/emericg/OffloadBuddy.svg?style=flat-square&logo=travis)](https://travis-ci.org/emericg/OffloadBuddy)
[![AppVeyor](https://img.shields.io/appveyor/ci/emericg/OffloadBuddy.svg?style=flat-square&logo=appveyor)](https://ci.appveyor.com/project/emericg/offloadbuddy)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=flat-square)](http://www.gnu.org/licenses/gpl-3.0)


OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!
It's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...

Works on Linux, macOS and Windows!

### Features:

- [x] Import datas from SD cards, mass storage or MTP devices (Linux & macOS)
  - [x] Organize and sort your media library
  - [x] Copy, merge or reencode medias
  - [ ] Change wrong dates (WIP)
  - [x] Show and export GoPro telemetry & GPS traces (WIP)
- [x] Create short video clips (and GIFs) from your videos!
- [x] Assemble photo timelapses into videos
- [ ] Extract photos/screenshots from videos
- [ ] Create timelapse from videos
- [x] Apply filters to medias
  - [ ] Reframe medias (WIP)
  - [x] Rotate medias (WIP)
  - [ ] Defisheye medias
  - [ ] Stabilize videos
- [ ] GoPro firmware updates


### Screenshots!

![GUI1](https://i.imgur.com/LRKR1UW.jpg)
![GUI2](https://i.imgur.com/pAsn76s.jpg)
![GUI3](https://i.imgur.com/mlbIdCa.jpg)
![GUI3](https://i.imgur.com/frkN44D.jpg)


## Documentation

### Dependencies

You will need a C++14 capable compiler and Qt 5.9+ (with QtMultimedia, QtLocation and QtCharts)
On Windows, the contribs builds fine with MSVC 2017.

Build dependencies:
- Qt (5.9+)  
- CMake  
- pkg-config (linux / macOS without contribs)  

Optional dependencies:
- libusb and libmtp  
- libexif  
- ffmpeg (3.4+)  
- MiniVideo (0.11+)  

### Building OffloadBuddy

Contribs (optional):
> $ cd OffloadBuddy/contribs  
> $ python3 contribs.py  

OffloadBuddy:
> $ cd OffloadBuddy/  
> $ qmake  
> $ make  


## Get involved!

### Developers

You can browse the code on the GitHub page, submit patches and pull requests! Your help would be greatly appreciated ;-)

### Users

You can help us find and report bugs, propose new features, help with translation, documentation and more! Visit the Issues section of the GitHub page to start!

## License

OffloadBuddy is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.  
Read the [LICENSE](LICENSE) file or [consult the license on the FSF website](https://www.gnu.org/licenses/gpl-3.0.txt) directly.

Emeric Grange <emeric.grange@gmail.com>

### Third party projects used by OffloadBuddy

* Qt [website](https://www.qt.io) ([LGPL 3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* ffmpeg [website](https://www.ffmpeg.org/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* MiniVideo [website](https://github.com/emericg/MiniVideo) ([LGPL 3](https://www.gnu.org/licenses/lgpl-3.0.txt))
* libexif [website](https://github.com/libexif/libexif/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* libmtp [website](http://libmtp.sourceforge.net/) ([LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.txt))
* SingleApplication [website](https://github.com/itay-grudev/SingleApplication) ([MIT](https://opensource.org/licenses/MIT))
* Graphical resources: please read [assets/COPYING](assets/COPYING)
