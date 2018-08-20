pragma Singleton
import QtQuick 2.0

Item { // PLAIN AND BORING
    // Colors
    property string colorSidebar: "#4E596E"
    property string colorSidebarText: "#ffffff"

    property string colorHeaderBackground: "#eef0f1"
    property string colorHeaderTitle: "#353637"
    property string colorHeaderText: "#000000"

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
    readonly property int fontSizeContentTitle: 24
    readonly property int fontSizeContentText: 15

    function loadTheme(themeIndex) {

        if (themeIndex >= 3) {
            themeIndex = 0
            console.log("ThemeEngine::loadTheme(" + themeIndex + ") ERROR Unknown theme!")
        }

        if (themeIndex === 0) {

            // "PLAIN AND BORING"

            colorSidebar =          "#4E596E"
            colorSidebarText =      "#ffffff"

            colorHeaderBackground = "#eef0f1"
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

        } else if (themeIndex === 1) {

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

        } else if (themeIndex === 2) {

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
