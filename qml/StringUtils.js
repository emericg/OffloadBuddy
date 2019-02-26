/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

function pad(n, width, z) {
    z = z || '0';
    width = width || 2;

    n = n + '';
    return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
}

/*!
 * urlToPath()
 */
function urlToPath(urlString) {
    var s

    if (urlString.slice(0, 8) === "file:///") {
        var k = urlString.charAt(9) === ':' ? 8 : 7
        s = urlString.substring(k)
    } else {
        s = urlString
    }

    return decodeURIComponent(s)
}

/*!
 * bytesToString_short()
 */
function bytesToString_short(bytes) {
    var text

    if (bytes/1000000000 >= 1.0)
        text = (bytes/1000000000).toFixed(1) + " " + qsTr("GB")
    else
        text = (bytes/1000000).toFixed(1) + " " + qsTr("MB")

    return text
}

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

/*!
 * durationToString()
 */
function durationToString(duration) {
    var text = ''

    if (duration > 0) {
        var hours = Math.floor(duration / 3600000);
        var minutes = Math.floor((duration - (hours * 3600000)) / 60000);
        var seconds = Math.floor((duration - (hours * 3600000) - (minutes * 60000)) / 1000);
        var ms = (duration - (hours * 3600000) - (minutes * 60000)) - (seconds * 1000);

        if (hours > 0) {
            text += hours.toString();

            if (hours > 1)
                text += qsTr(" hours ");
            else
                text += qsTr(" hour ");
        }
        if (minutes > 0) {
            text += minutes.toString() + qsTr(" min ");
        }
        if (seconds > 0) {
            text += seconds.toString() + qsTr(" sec ");
        }
        if (ms > 0) {
            text += ms.toString() + qsTr(" ms");
        }
    } else {
        text = qsTr("NULL duration");
    }

    return text
}

/*!
 * 'video aspect ratio' to string()
 *
 * See: https://en.wikipedia.org/wiki/Aspect_ratio_(image)
 */
function varToString(width, height) {

    var ar_string = ''
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

    var ar_string = ''
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
        ar_string = "5:4"
    } else if (ar_float > 1.3 && ar_float < 1.35) { // 1.333
        ar_string = "4:3"
    } else if (ar_float > 1.45 && ar_float < 1.55) { // 1.5
        ar_string = "3:2"
    } else if (ar_float > 1.55 && ar_float < 1.65) { // 1.6
        ar_string = "16:10"
    } else if (ar_float > 1.75 && ar_float < 1.80) { // 1.777
        ar_string = "16:9"
    } else if (ar_float > 1.88 && ar_float < 1.92) { // 1,896
        ar_string = "256:135"
    } else if (ar_float > 2.3 && ar_float < 2.4) { // 2.333
        ar_string = "21:9"
    } else if (ar_float > 3.5 && ar_float < 3.6) { // 3.555
        ar_string = "32:9"
    }
    // mobile display // add more as we go...
    else if (ar_float == 2) { // 2
        ar_string = "18:9"
    } else if (ar_float > 2 && ar_float < 2.1) { // 2,0555
        ar_string = "18.5:9"
    } else if (ar_float > 2.1 && ar_float < 2.14) { // 2,111
        ar_string = "19:9"
    } else if (ar_float > 2.14 && ar_float < 2.2) { // 2,1666
        ar_string = "19.5:9"
    }

    if (ar_invert) {
        var splits = ar_string.split(':');
        ar_string = splits[1] + ":" + splits[0];
    }

    return ar_string;
}

/*!
 * bitrateToString()
 */
function bitrateToString(bitrate) {
    var text = ''

    if (bitrate > 0) {
        if (bitrate < 10000000) { // < 10 Mb
            text = (bitrate / 1000) + qsTr(" Kb/s");
        } else if (bitrate < 100000000) { // < 100 Mb
            text = (bitrate / 1000 / 1000) + qsTr(" Mb/s");
        } else {
            text = (bitrate / 1000 / 1000) + qsTr(" Mb/s");
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
    var text = ''

    if (framerate > 0) {
        text = framerate.toFixed(2) + " " + qsTr("fps")
    } else {
        text = qsTr("NULL framerate");
    }

    return text;
}

/*!
 * orientationToString()
 */
function orientationToString(orientation) {
    var text = ''

    if (orientation > 0) {
        if (orientation === 1)
            text = qsTr("Mirror")
        else if (orientation === 2)
            text = qsTr("Flip")
        else if (orientation === 3)
            text = qsTr("Rotate 180°")
        else if (orientation === 4)
            text = qsTr("Rotate 90°")
        else if (orientation === 5)
            text = qsTr("Mirror and rotate 90°")
        else if (orientation === 6)
            text = qsTr("Flip and rotate 90°")
        else if (orientation === 7)
            text = qsTr("Rotate 270°")
    } else {
        text = qsTr("No transformation");
    }

    return text;
}

/*!
 * altitudeToString()
 */
function altitudeToString(value, precision, unit) {
    var text = ''

    if (unit === 0) {
        text = value.toFixed(precision) + " " + qsTr("m")
    } else {
        text = (value / 0.3048).toFixed(precision) + " " + qsTr("ft")
    }

    return text;
}

/*!
 * altitudeUnit()
 */
function altitudeUnit(unit) {
    var text = ''

    if (unit === 0) {
        text = qsTr("meter")
    } else {
        text = qsTr("feet")
    }

    return text;
}

/*!
 * distanceToString()
 */
function distanceToString(value, precision, unit) {
    var text = ''

    if (unit === 0) {
        text = value.toFixed(precision) + " " + qsTr("km")
    } else {
        text = (value / 1609.344).toFixed(precision) + " " + qsTr("mi")
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
    var text = ''

    if (unit === 0) {
        text = qsTr("km/h")
    } else {
        text = qsTr("mi/h")
    }

    return text;
}
