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
        text = (bytes/1000000000).toFixed(0) + qsTr("GB")
    else
        text = (bytes/1000000).toFixed(1) + qsTr("MB")

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
        var seconds = Math.floor((duration - (hours * 3600000) - (minutes * 60000)) / 1000);

        if (hours > 0)
            text += pad(hours).toString()
        if (hours > 0 && minutes > 0)
            text += ":"
        if (hours == 0 && minutes == 0)
            text += "00:"
        if (minutes > 0)
            text += pad(minutes).toString()
        if (minutes > 0 && seconds > 0)
            text += ":"
        if (seconds > 0) {
            text += pad(seconds).toString()
        }
    } else if (duration > 0) {
        text = "~00:01";
    } else {
        text = "00:xx";
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
