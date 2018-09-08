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

pragma Singleton
import QtQuick 2.10

Item {
    enum ThemeNames {
        PLAIN_AND_BORING = 0,
        DARK_AND_SPOOKY = 1,
        BLOOD_AND_TEARS = 2,
        MIGHTY_KITTEN = 3,

        LAST_THEME
    }

    // Colors
    property string colorSidebar: "#4E596E"
    property string colorSidebarText: "#ffffff"

    property string colorHeaderBackground: "#ebedee"
    property string colorHeaderTitle: "#353637"
    property string colorHeaderText: "#000000"

    property string colorInfoBanner: "#fed859"
    property string colorInfoBannerText: "#ffffff"

    property string colorContentBackground: "#ffffff"
    property string colorContentBox: "#F7F7F7"
    property string colorContentTitle: "#353637"
    property string colorContentText: "#000000"
    property string colorContentSubBox: "#eef0f1"
    property string colorContentSubTitle: "#000000"
    property string colorContentSubText: "#000000"

    property string colorApproved: "#46b0f4"
    property string colorDangerZone: "#FF5F5F"
    property string colorSomethingsWrong: "#FFDB63"

    property string colorButtonText: "#ffffff"
    property string colorProgressbar: "#000000"

    // Fonts (sizes in pixel)
    readonly property int fontSizeHeaderTitle: 30
    readonly property int fontSizeHeaderText: 17
    readonly property int fontSizeBannerText: 20
    readonly property int fontSizeContentTitle: 24
    readonly property int fontSizeContentText: 15

    function loadTheme(themeIndex) {

        if (themeIndex >= ThemeEngine.LAST_THEME) {
            themeIndex = 0
            console.log("ThemeEngine::loadTheme(" + themeIndex + ") ERROR Unknown theme!")
        }

        if (themeIndex === ThemeEngine.PLAIN_AND_BORING) {

            // "PLAIN AND BORING"

            colorSidebar =          "#4E596E"
            colorSidebarText =      "#ffffff"

            colorHeaderBackground = "#ebedee"
            colorHeaderTitle =      "#353637"
            colorHeaderText =       "#000000"

            colorContentBackground ="#ffffff"
            colorContentBox =       "#F7F7F7"
            colorContentTitle =     "#353637"
            colorContentText =      "#000000"
            colorContentSubBox =    "#eef0f1"
            colorContentSubTitle =  "#000000"
            colorContentSubText =   "#000000"

            colorApproved =         "#46b0f4"
            colorDangerZone =       "#FF5F5F"
            colorSomethingsWrong =  "#FFDB63"

            colorButtonText =       "#ffffff"
            colorProgressbar =      "#000000"

        } else if (themeIndex === ThemeEngine.DARK_AND_SPOOKY) {

            // "DARK AND SPOOKY"

            colorSidebar =          "#2e2e2e"
            colorSidebarText =      "#ffffff"

            colorHeaderBackground = "#444444"
            colorHeaderTitle =      "#8b8e8f"
            colorHeaderText =       "#a89a9a"

            colorContentBackground ="#636363"
            colorContentBox =       "#565656"
            colorContentTitle =     "#a0a29c"
            colorContentText =      "#ffffff"
            colorContentSubBox =    "#848484"
            colorContentSubTitle =  "#353637"
            colorContentSubText =   "#405a73"

            colorApproved =         "#f0544c"
            colorDangerZone =       "#ee2b57"
            colorSomethingsWrong =  "#FFDB63"

            colorButtonText =       "#ffffff"
            colorProgressbar =      "#000000"

        } else if (themeIndex === ThemeEngine.BLOOD_AND_TEARS) {

            // "BLOOD AND TEARS"

            colorSidebar =          "#181818"
            colorSidebarText =      "#bebebe"

            colorHeaderBackground = "#141414"
            colorHeaderTitle =      "#ffffff"
            colorHeaderText =       "#a3a3a0"

            colorContentBackground ="#222222"
            colorContentBox =       "#333333"
            colorContentTitle =     "#a0a29c"
            colorContentText =      "#a3a3a0"
            colorContentSubBox =    "#565656"
            colorContentSubTitle =  "#ffffff"
            colorContentSubText =   "#a3a3a0"

            colorApproved =         "#009ee2"
            colorDangerZone =       "#fa6871"
            colorSomethingsWrong =  "#FFDB63"

            colorButtonText =       "#ffffff"
            colorProgressbar =      "#009ee2"

        } else if (themeIndex === ThemeEngine.MIGHTY_KITTEN) {

            // "MIGHTY KITTEN"

            colorSidebar =          "#ed164f"
            colorSidebarText =      "#ffffff"

            colorHeaderBackground = "#faa7d1"
            colorHeaderTitle =      "#ed164f"
            colorHeaderText =       "#ffe617"

            colorContentBackground ="#ffffff"
            colorContentBox =       "#fff5fa"
            colorContentTitle =     "#ffe617"
            colorContentText =      "#000000"
            colorContentSubBox =    "#ffe7f3"
            colorContentSubTitle =  "#f5b404"
            colorContentSubText =   "#000000"

            colorApproved =         "#f5b404"
            colorDangerZone =       "#ed164f"
            colorSomethingsWrong =  "#FFDB63"

            colorButtonText =       "#ffffff"
            colorProgressbar =      "#ffe617"
        }
    }
}
