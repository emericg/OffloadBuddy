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
 * aspectratioToString()
 */
function aspectratioToString(width, height) {
    var text = ''

    var ar_d = width / height;

    if (ar_d > 1.24 && ar_d < 1.26) {
        text = "5:4";
    } else if (ar_d > 1.323 && ar_d < 1.343) {
        text = "4:3";
    } else if (ar_d > 1.42 && ar_d < 1.44) {
        text = "1.43:1";
    } else if (ar_d > 1.49 && ar_d < 1.51) {
        text = "3:2";
    } else if (ar_d > 1.545 && ar_d < 1.565) {
        text = "14:9";
    } else if (ar_d > 1.59 && ar_d < 1.61) {
        text = "16:10";
    } else if (ar_d > 1.656 && ar_d < 1.676) {
        text = "5:3";
    } else if (ar_d > 1.767 && ar_d < 1.787) {
        text = "16:9";
    } else if (ar_d > 1.84 && ar_d < 1.86) {
        text = "1.85:1";
    } else if (ar_d > 1.886 && ar_d < 1.906) {
        text = "1.896:1";
    } else if (ar_d > 1.99 && ar_d < 2.01) {
        text = "2.0:1";
    } else if (ar_d > 2.19 && ar_d < 2.22) {
        text = "2.20:1";
    } else if (ar_d > 2.34 && ar_d < 2.36) {
        text = "2.35:1";
    } else if (ar_d > 2.38 && ar_d < 2.40) {
        text = "2.39:1";
    } else if (ar_d > 2.54 && ar_d < 2.56) {
        text = "2.55:1";
    } else if (ar_d > 2.75 && ar_d < 2.77) {
        text = "2.76:1";
    } else {
        text = ar_d.toFixed(2) + ":1";
    }

    return text;
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
