# MediaThumbnailer

Video thumbnailing made *very* easy!

> Supports Qt 6.8+ with CMake

> Supports ffmpeg 6+

> Supports GStreamer 1.0+


## Features

- Media thumbnailer with QQuickImageProvider support:
  - async & threadpool implementations
- Decoding backends:
  - FFmpeg backend
  - GStreamer backend (WIP)
  - MiniVideo backend (WIP)


## Quick start

### Build

To get started, simply checkout the MediaThumbnailer repository as a submodule, or copy the
MediaThumbnailer directory into your project, then include the `CMakeLists.txt` CMake project file:

```cmake
add_subdirectory(MediaThumbnailer/)
target_link_libraries(${PROJECT_NAME} PRIVATE MediaThumbnailer)
```


### Register

Register a provider on your QML engine.

The `registerToEngine()` helper creates the provider and hooks it up under the `MediaThumbnailer` scheme. The QML engine takes ownership of the provider and deletes it on teardown.

```cpp
#include "MediaThumbnailer.h"

int main()
{
    QQmlApplicationEngine engine;

    // Threadpool variant, 4 worker threads
    MediaThumbnailer_threadpool::registerToEngine(&engine, 4);

    // Async variant
    MediaThumbnailer_async::registerToEngine(&engine);
}
```

The **threadpool** provider is the recommended one: it decodes on its own `QThreadPool` and supports cancellation,
so thumbnails whose delegates are scrolled away are dropped instead of decoded to completion.

The **async** provider relies on Qt's own loader threads and cannot be cancelled.

### Use

Then use it in your QML application:

> `image://MediaThumbnailer/<path>` returns the first frame

> `image://MediaThumbnailer/<path>@<seconds>` the frame at (well, closest IDR to) a given timecode

```qml
Image {
    width: 512
    height: 256

    source: {
        var videoPath = "/path/to/your/video.mkv"
        var videoTimecode = (duration_s / 3).toFixed()
        return "image://MediaThumbnailer/" + videoPath + "@" + videoTimecode
    }
}
```


## License

This project is licensed under the terms of the [MIT license](LICENSE.md).

> Copyright (c) Emeric Grange (emeric.grange@gmail.com)
