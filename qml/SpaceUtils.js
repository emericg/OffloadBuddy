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
 * bytesToString()
 */
function bytesToString(bytes) {
    var text
    if (bytes/1000000000 >= 1.0)
        text = (bytes/1000000000).toFixed(0) + qsTr("GB")
    else
        text = (bytes/1000000).toFixed(1) + qsTr("MB")

    return text
}
