CONFIG += c++11

SOURCES += $${PWD}/MediaThumbnailer_threadpool.cpp \
           $${PWD}/MediaThumbnailer_async.cpp \
           $${PWD}/ThumbnailerBackend.cpp

HEADERS += $${PWD}/MediaThumbnailer.h \
           $${PWD}/MediaThumbnailer_threadpool.h \
           $${PWD}/MediaThumbnailer_async.h \
           $${PWD}/ThumbnailerBackend.h

INCLUDEPATH += $${PWD}

contains(DEFINES, ENABLE_FFMPEG) {
    SOURCES += $${PWD}/ThumbnailerBackend_ffmpeg.cpp
    HEADERS += $${PWD}/ThumbnailerBackend_ffmpeg.h
}
contains(DEFINES, ENABLE_GSTREAMER) {
    SOURCES += $${PWD}/ThumbnailerBackend_gstreamer.cpp
    HEADERS += $${PWD}/ThumbnailerBackend_gstreamer.h
}
contains(DEFINES, ENABLE_MINIVIDEO) {
    SOURCES += $${PWD}/ThumbnailerBackend_minivideo.cpp
    HEADERS += $${PWD}/ThumbnailerBackend_minivideo.h
}
