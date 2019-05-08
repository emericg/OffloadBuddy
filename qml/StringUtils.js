
/*!
 * durationToString_condensed()
 */
function durationToString_condensed(duration) {
    var text = ''

    if (duration > 1000) {
        var hours = Math.floor(duration / 3600000);
        var minutes = Math.floor((duration - (hours * 3600000)) / 60000);
        var seconds = Math.round((duration - (hours * 3600000) - (minutes * 60000)) / 1000);

        if (hours > 0) text += pad(hours).toString() + ":"
        text += pad(minutes).toString() + ":"
        text += pad(seconds).toString()
    } else if (duration > 0) {
        text = "~00:01";
    } else {
        text = "00:xx";
    }

    return text
}

/*!
 * durationToString_ffmpeg()
 */
function durationToString_ffmpeg(duration) {
    var text = ''

    if (duration > 0) {
        var hours = Math.floor(duration / 3600000);
        var minutes = Math.floor((duration - (hours * 3600000)) / 60000);
        var seconds = Math.floor((duration - (hours * 3600000) - (minutes * 60000)) / 1000);
        var milliseconds = Math.floor((duration - (hours * 3600000) - (minutes * 60000)) - (seconds * 1000));

        if (hours > 0)
            text += pad(hours).toString()
        if (hours == 0)
            text += "00"
        text += ":"
        if (minutes > 0)
            text += pad(minutes).toString()
        if (minutes == 0)
            text += "00"
        text += ":"
        if (seconds > 0) {
            text += pad(seconds).toString()
        if (seconds == 0)
            text += "00"
        if (milliseconds)
            text += "." + milliseconds.toString()
        }
    } else {
        text = "00:00:00";
    }

    return text
}

/*!
 * durationToString_short()
 */
function durationToString_short(duration) {
    var text = ''

    if (duration > 1000) {
        var hours = Math.floor(duration / 3600000);
        var minutes = Math.floor((duration - (hours * 3600000)) / 60000);
        var seconds = Math.round((duration - (hours * 3600000) - (minutes * 60000)) / 1000);

        text += pad(hours).toString() + ":"
        text += pad(minutes).toString() + ":"
        text += pad(seconds).toString() + ":"
    } else if (duration > 0) {
        text = "00:00:01";
    } else {
        text = "00:00:00";
    }

    return text
}
