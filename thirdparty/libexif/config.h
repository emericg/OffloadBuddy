/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* MSVC hacks */
#ifdef _MSC_VER
#define ssize_t int64_t
#define _CRT_SECURE_NO_WARNINGS
#if _MSC_VER < 1900
#define snprintf(buffer, count, format, ...) _snprintf_s(buffer, count, count, format, __VA_ARGS__)
#endif
#endif

/* Disable gettext */
#undef ENABLE_NLS
#undef HAVE_DCGETTEXT
#undef HAVE_GETTEXT
#undef HAVE_ICONV
#undef ICONV_CONST
#define __WATCOMC__

/* Define to 1 if translation of program messages to the user's native language is requested. */
#define GETTEXT_PACKAGE "libexif-12"
#define LOCALEDIR ""

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* Name of package */
#define PACKAGE "libexif"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "libexif-devel@lists.sourceforge.net"

/* Define to the full name of this package. */
#define PACKAGE_NAME "EXIF library"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "EXIF library 0.6.21"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libexif"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.6.21"

/* Version number of package */
#define VERSION "0.6.21"

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif
