// UtilsPath.js
// Version 0.4
.pragma library

/* ************************************************************************** */

/*!
 * Take an url or string, and make sure we output a clean string path.
 */
function cleanUrl(urlIn) {
    urlIn = Qt.resolvedUrl(urlIn)
    if (!(typeof urlIn === 'string' || urlIn instanceof String)) {
        urlIn = urlIn.toString();
    }

    var pathOut = '';
    if (typeof urlIn === 'string' || urlIn instanceof String) {
        if (urlIn.slice(0, 8) === "file:///") {
            var k = urlIn.charAt(9) === ':' ? 8 : 7;
            pathOut = urlIn.substring(k);
        } else {
            pathOut = urlIn;
        }
    } else {
        console.log("cleanUrl(urlIn) has been given an unknown type...");
    }

    return pathOut;
}

/*!
 * Take an url or string, and make sure we output a clean url.
 */
function makeUrl(urlIn) {
    //
}

/*!
 * Take an url or string from a file, return the absolute path of the folder containing that file.
 */
function fileToFolder(filePath) {
    if (!(typeof filePath === 'string' || filePath instanceof String)) {
        filePath = filePath.toString();
    }

    var folderPath = '';
    if (typeof filePath === 'string' || filePath instanceof String) {
        folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
    } else {
        console.log("fileToFolder(filePath) has been given an unknown type...");
    }

    return folderPath;
}

function openWith(filePath) {
    Qt.openUrlExternally(filePath)
}

/* ************************************************************************** */

function isMediaFile(filePath) {
    return (isVideoFile(filePath) || isAudioFile(filePath) || isPictureFile(filePath));
}

function isVideoFile(filePath) {
    if (!(typeof filePath === 'string' || filePath instanceof String)) {
        filePath = filePath.toString();
    }

    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;

    if (extension.length !== 0) {
        if (extension === "mov" || extension === "m4v" || extension === "mp4" || extension === "mp4v" ||
            extension === "3gp" || extension === "3gpp" ||
            extension === "mkv" || extension === "webm" ||
            extension === "avi" || extension === "divx" ||
            extension === "asf" || extension === "wmv") {
            valid = true;
        }
    }

    return valid;
}

function isPictureFile(filePath) {
    if (!(typeof filePath === 'string' || filePath instanceof String)) {
        filePath = filePath.toString();
    }

    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;

    if (extension.length !== 0) {
        if (extension === "jpg" || extension === "jpeg" || extension === "webp" ||
            extension === "png" || extension === "gpr" ||
            extension === "gif" ||
            extension === "heif" || extension === "heic" || extension === "avif" ||
            extension === "tga" || extension === "bmp" ||
            extension === "tif" || extension === "tiff" ||
            extension === "svg") {
            valid = true;
        }
    }

    return valid;
}

function isAudioFile(filePath) {
    if (!(typeof filePath === 'string' || filePath instanceof String)) {
        filePath = filePath.toString();
    }

    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;

    if (extension.length !== 0) {
        if (extension === "mp1" || extension === "mp2" || extension === "mp3" ||
            extension === "m4a" || extension === "mp4a" ||  extension === "m4r" || extension === "aac" ||
            extension === "mka" ||
            extension === "wma" ||
            extension === "amb" || extension === "wav" || extension === "wave" ||
            extension === "ogg" || extension === "opus" || extension === "vorbis" ) {
            valid = true;
        }
    }

    return valid;
}

/* ************************************************************************** */
