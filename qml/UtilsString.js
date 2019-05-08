// UtilsString.js
// Version 0.1

/*!
 * durationToString_short()
 */
function durationToString_short(duration) {
    var time_ = Math.floor(duration / 1000);
    var secs = time_ % 60;
    time_ = Math.floor(time_ / 60);
    var mins = time_ % 60;
    time_ = Math.floor(time_ / 60);

    if (secs < 10)
    {
        secs = "0" + secs;
    }
    if (mins < 10)
    {
        mins = "0" + mins;
    }
    if (time_ === 0)
    {
        time_ = "";
    }
    else
    {
        time_ += ":";
    }

    return time_ + mins + ":" + secs;
}

/*!
 * durationToString()
 */
function durationToString(duration) {
    var text = '';

    if (duration > 0) {
        var hours = Math.floor(duration / 3600000);
        var minutes = Math.floor((duration - (hours * 3600000)) / 60000);
        var seconds = Math.floor((duration - (hours * 3600000) - (minutes * 60000)) / 1000);
        var ms = (duration - (hours * 3600000) - (minutes * 60000)) - (seconds * 1000);

        if (hours > 0) {
            text += hours.toString();

            if (hours > 1)
                text += " " + qsTr("hours") + " ";
            else
                text += " " + qsTr("hour") + " ";
        }
        if (minutes > 0) {
            text += minutes.toString() + " " + qsTr("min") + " ";
        }
        if (seconds > 0) {
            text += seconds.toString() + " " + qsTr("sec") + " ";
        }
        if (ms > 0) {
            text += ms.toString() + " " + qsTr("ms");
        }
    } else {
        text = qsTr("NULL duration");
    }

    return text;
}

/* ************************************************************************** */

/*!
 * bytesToString_short()
 */
function bytesToString_short(bytes) {
    var text = '';

    if (bytes/1000000000 >= 128.0)
        text = (bytes/1000000000).toFixed(0) + " " + qsTr("GB");
    else if (bytes/1000000000 >= 1.0)
        text = (bytes/1000000000).toFixed(1) + " " + qsTr("GB");
    else
        text = (bytes/1000000).toFixed(1) + " " + qsTr("MB");

    return text;
}

/*!
 * bitrateToString()
 */
function bitrateToString(bitrate) {
    var text = '';

    if (bitrate > 0) {
        if (bitrate < 10000000) { // < 10 Mb
            text = (bitrate / 1000) + " " + qsTr("Kb/s");
        } else if (bitrate < 100000000) { // < 100 Mb
            text = (bitrate / 1000 / 1000) + " " + qsTr("Mb/s");
        } else {
            text = (bitrate / 1000 / 1000) + " " + qsTr("Mb/s");
        }
    } else {
        text = qsTr("NULL bitrate");
    }

    return text;
}

/*!
 * framerateToString()
 */
function framerateToString(framerate) {
    var text = '';

    if (framerate > 0) {
        text = framerate.toFixed(2) + " " + qsTr("fps");
    } else {
        text = qsTr("NULL framerate");
    }

    return text;
}

/*!
 * orientationToString()
 */
function orientationToString(orientation) {
    var text = '';

    if (orientation > 0) {
        if (orientation === 1)
            text = qsTr("Mirror");
        else if (orientation === 2)
            text = qsTr("Flip");
        else if (orientation === 3)
            text = qsTr("Rotate 180°");
        else if (orientation === 4)
            text = qsTr("Rotate 90°");
        else if (orientation === 5)
            text = qsTr("Mirror and rotate 90°");
        else if (orientation === 6)
            text = qsTr("Flip and rotate 90°");
        else if (orientation === 7)
            text = qsTr("Rotate 270°");
    } else {
        text = qsTr("No transformation");
    }

    return text;
}

/* ************************************************************************** */

/*!
 * altitudeToString()
 */
function altitudeToString(value, precision, unit) {
    var text = '';

    if (unit === 0) {
        text = value.toFixed(precision) + " " + qsTr("m");
    } else {
        text = (value / 0.3048).toFixed(precision) + " " + qsTr("ft");
    }

    return text;
}

/*!
 * altitudeUnit()
 */
function altitudeUnit(unit) {
    var text = '';

    if (unit === 0) {
        text = qsTr("meter");
    } else {
        text = qsTr("feet");
    }

    return text;
}

/*!
 * distanceToString()
 */
function distanceToString(value, precision, unit) {
    var text = '';

    if (unit === 0) {
        text = value.toFixed(precision) + " " + qsTr("km");
    } else {
        text = (value / 1609.344).toFixed(precision) + " " + qsTr("mi");
    }

    return text;
}

/*!
 * speedToString()
 */
function speedToString(value, precision, unit) {
    return distanceToString(value, precision, unit) + "/h";
}

/*!
 * speedUnit()
 */
function speedUnit(unit) {
    var text = '';

    if (unit === 0) {
        text = qsTr("km/h");
    } else {
        text = qsTr("mi/h");
    }

    return text;
}

/* ************************************************************************** */

/*!
 * 'video aspect ratio' to string()
 *
 * See: https://en.wikipedia.org/wiki/Aspect_ratio_(image)
 */
function varToString(width, height) {
    var ar_string = '';
    var ar_float = 1.0;
    var ar_invert = false;

    if (width >= height) {
        ar_float = width / height;
    } else {
        ar_float = height / width;
        ar_invert = true;
    }

    if (ar_float > 1.24 && ar_float < 1.26) {
        ar_string = "5:4";
    } else if (ar_float > 1.323 && ar_float < 1.343) {
        ar_string = "4:3";
    } else if (ar_float > 1.42 && ar_float < 1.44) {
        ar_string = "1.43:1";
    } else if (ar_float > 1.49 && ar_float < 1.51) {
        ar_string = "3:2";
    } else if (ar_float > 1.545 && ar_float < 1.565) {
        ar_string = "14:9";
    } else if (ar_float > 1.59 && ar_float < 1.61) {
        ar_string = "16:10";
    } else if (ar_float > 1.656 && ar_float < 1.676) {
        ar_string = "5:3";
    } else if (ar_float > 1.767 && ar_float < 1.787) {
        ar_string = "16:9";
    } else if (ar_float > 1.84 && ar_float < 1.86) {
        ar_string = "1.85:1";
    } else if (ar_float > 1.886 && ar_float < 1.906) {
        ar_string = "1.896:1";
    } else if (ar_float > 1.99 && ar_float < 2.01) {
        ar_string = "2.0:1";
    } else if (ar_float > 2.19 && ar_float < 2.22) {
        ar_string = "2.20:1";
    } else if (ar_float > 2.34 && ar_float < 2.36) {
        ar_string = "2.35:1";
    } else if (ar_float > 2.38 && ar_float < 2.40) {
        ar_string = "2.39:1";
    } else if (ar_float > 2.54 && ar_float < 2.56) {
        ar_string = "2.55:1";
    } else if (ar_float > 2.75 && ar_float < 2.77) {
        ar_string = "2.76:1";
    } else {
        ar_string = ar_float.toFixed(2) + ":1";
    }

    if (ar_invert) {
        var splits = ar_string.split(':');
        ar_string = splits[1] + ":" + splits[0];
    }

    return ar_string;
}

/*!
 * 'display aspect ratio' to string()
 *
 * See: https://en.wikipedia.org/wiki/Display_aspect_ratio
 * Note: we take waaay more margin than with video aspect ratio in order to have
 * more chance to catch aspect ratios from weird definitions...
 */
function darToString(width, height) {
    var ar_string = '';
    var ar_float = 1.0;
    var ar_invert = false;

    if (width >= height) {
        ar_float = width / height;
    } else {
        ar_float = height / width;
        ar_invert = true;
    }

    // desktop displays
    if (ar_float > 1.2 && ar_float < 1.3) { // 1.25
        ar_string = "5:4";
    } else if (ar_float > 1.3 && ar_float < 1.35) { // 1.333
        ar_string = "4:3";
    } else if (ar_float > 1.45 && ar_float < 1.55) { // 1.5
        ar_string = "3:2";
    } else if (ar_float > 1.55 && ar_float < 1.65) { // 1.6
        ar_string = "16:10";
    } else if (ar_float > 1.75 && ar_float < 1.80) { // 1.777
        ar_string = "16:9";
    } else if (ar_float > 1.88 && ar_float < 1.92) { // 1,896
        ar_string = "256:135";
    } else if (ar_float > 2.3 && ar_float < 2.4) { // 2.333
        ar_string = "21:9";
    } else if (ar_float > 3.5 && ar_float < 3.6) { // 3.555
        ar_string = "32:9";
    }
    // mobile display // add more as we go...
    else if (ar_float === 2) { // 2
        ar_string = "18:9";
    } else if (ar_float > 2 && ar_float < 2.1) { // 2,0555
        ar_string = "18.5:9";
    } else if (ar_float > 2.1 && ar_float < 2.14) { // 2,111
        ar_string = "19:9";
    } else if (ar_float > 2.14 && ar_float < 2.2) { // 2,1666
        ar_string = "19.5:9";
    }

    if (ar_invert) {
        var splits = ar_string.split(':');
        ar_string = splits[1] + ":" + splits[0];
    }

    return ar_string;
}
