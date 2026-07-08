prefix=${CMAKE_INSTALL_PREFIX}
exec_prefix=${EXEC_INSTALL_PREFIX}
libdir=${LIB_INSTALL_DIR}
includedir=${INCLUDE_INSTALL_DIR}

Name: ${PROJECT_NAME}
Description: A library for parsing, editing, and saving EXIF data.
URL: https://github.com/libexif/libexif
Version: ${PROJECT_VERSION}
Libs: -L${LIB_INSTALL_DIR} -lexif ${EXTRA_LIBS}
Cflags: -I${INCLUDE_INSTALL_DIR}
