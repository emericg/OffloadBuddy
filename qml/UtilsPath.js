// UtilsPath.js
// Version 0.1

/*!
 * Take an url or string, and make sure we output a clean string path.
 */
function cleanUrl(urlIn) {
    var pathOut = '';

    if (!(typeof urlIn === 'string' || urlIn instanceof String)) {
        urlIn = urlIn.toString();
    }

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
 * Take an url or string from a file, return the path of the folder containing that file.
 */
function fileToFolder(filePath) {
    var folderPath = '';

    if (!(typeof filePath === 'string' || filePath instanceof String)) {
        filePath = filePath.toString();
    }

    if (typeof filePath === 'string' || filePath instanceof String) {
        folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
    } else {
        console.log("fileToFolder(filePath) has been given an unknown type...");
    }

    return folderPath;
}

/* ************************************************************************** */

function isMediaFile(filePath, permissive) {
    return (isVideoFile(filePath, permissive) || isPictureFile(filePath, permissive));
}

function isVideoFile(filePath, permissive) {
    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;
    permissive = permissive || false;

    if (extension === "mov" || extension === "mp4" || extension === "m4v" ||
        extension === "mkv" || extension === "webm") {
        valid = true;
    } else if (permissive === true) {
        if (extension === "avi" || extension === "divx") {
            valid = true;
        }
    }

    return valid;
}

function isPictureFile(filePath, permissive) {
    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;
    permissive = permissive || false;

    if (extension === "jpg" || extension === "jpeg" ||
        extension === "png" || extension === "gpr" ||
        extension === "webp") {
        valid = true;
    } else if (permissive === true) {
        if (extension === "tga" || extension === "bmp" ||
            extension === "tif" || extension === "tiff") {
            valid = true;
        }
    }

    return valid;
}

function isAudioFile(filePath, permissive) {
    var extension = filePath.split('.').pop().toLowerCase();
    var valid = false;
    permissive = permissive || false;

    if (extension === "mp3" ||
        extension === "mka" ||
        extension === "m4a" || extension === "aac" ||
        extension === "ogg" || extension === "opus") {
        valid = true;
    } else if (permissive === true) {
        if (extension === "mp1" || extension === "mp2") {
            valid = true;
        }
    }

    return valid;
}
