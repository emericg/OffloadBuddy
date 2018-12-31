OffloadBuddy
============

[![Travis](https://img.shields.io/travis/emericg/OffloadBuddy.svg?style=flat-square)](https://travis-ci.org/emericg/OffloadBuddy)
[![AppVeyor](https://img.shields.io/appveyor/ci/emericg/OffloadBuddy.svg?style=flat-square)](https://ci.appveyor.com/project/emericg/offloadbuddy)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=flat-square)](http://www.gnu.org/licenses/gpl-3.0)


## Introduction

OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!
It's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...

Works with Linux, macOS and Windows!

FEATURES (WIP):
* Import datas from SD cards, mass storage or MTP devices
  * Copy, merge or reencode medias
  * Consult and export shots metadatas
  * Organize your media library
* Create short video clips or extract photos from your videos
* Create timeplapse from videos
* Assemble photo timelapses into videos
* GoPro firmware updates


### Screenshots!

![GUI1](https://i.imgur.com/tqCeaEC.png)
![GUI2](https://i.imgur.com/96E5Y29.png)
![GUI3](https://i.imgur.com/wnG32fh.png)


## Documentation

### Dependencies

You will need a C++14 capable compiler and Qt 5.9+ (with QtMultimedia, QtLocation and QtCharts)

Build dependencies:
- Qt 5.9+  
- cmake  
- pkg-config  

Optional dependencies:
- libusb and libmtp  
- libexif  
- ffmpeg (3.4 or better)  
- minivideo (0.11)  

### Building OffloadBuddy

Contribs (optional):
> $ cd OffloadBuddy/contribs  
> $ ./contribs.py  

OffloadBuddy:
> $ cd OffloadBuddy/  
> $ qmake  
> $ make  


## Licensing

OffloadBuddy is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.  
Read [LICENSE](LICENSE) or [consult the licence on the FSF website](http://www.gnu.org/licenses/gpl-3.0.txt) directly.

Emeric Grange <emeric.grange@gmail.com>


## Special thanks

* Mickael Heudre <mickheudre@gmail.com> for his invaluable QML expertise!
* Graphical resources: read [resources/COPYING](resources/COPYING)


## Get involved!

### Developers

You can browse the code here on GitHub, submit patches and pull requests! Your help would be greatly appreciated ;-)

### Users

You can help us finding bugs, proposing new features and more! Visit the "Issues" section in the GitHub menu to start.
