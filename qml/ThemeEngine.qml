pragma Singleton
import QtQuick 2.9

Item {
    enum ThemeNames {
        PLAIN_AND_BORING = 0,
        DARK_AND_SPOOKY = 1,
        BLOOD_AND_TEARS = 2,
        MIGHTY_KITTEN = 3,

        LAST_THEME
    }
    property int currentTheme: -1

    // Colors
    property string colorSidebar
    property string colorSidebarContent

    property string colorHeader
    property string colorHeaderContent

    property string colorInfoBanner: "#fed859" // TODO
    property string colorInfoBannerText: "#ffffff" // TODO

    property string colorBackground
    property string colorForeground
    property string colorText
    property string colorSubText
    property string colorIcon
    property string colorPrimary
    property string colorSecondary
    property string colorWarning
    property string colorError

    // Qt Quick controls theming // DEPRECATED?
    property string colorButton: "#e0e0e0"
    property string colorButtonText: "#000000"
    property string colorButtonDown: "#bdbdbd"
    property string colorButtonHover: "#E4E4E4"
    property string colorProgressBar: "#46b0f4"
    property string colorProgressBarBg: "#E4E4E4"

    // Selector (arrow or bar)
    property string selector: "arrow"

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

        currentTheme = themeIndex

        if (themeIndex === ThemeEngine.PLAIN_AND_BORING) {

            // "PLAIN AND BORING"

            colorSidebar =          "#607D8B"
            colorSidebarContent =   "#ffffff"

            colorHeader =           "#D0D0D0"
            colorHeaderContent =    "#353637" // sub: "#000000"

            colorBackground =       "#EEEEEE"
            colorForeground =       "#E0E0E0"

            colorText =             "#000000"
            colorSubText =          "#606060"
            colorIcon =             "#000000"

            colorPrimary =          "#03A9F4"
            colorSecondary =        "#3ae374"
            colorWarning =          "#FFC107"
            colorError =            "#FF5722"

            colorButton =           "#DBDBDB"
            colorButtonDown =       "#c1c1c1"
            colorButtonText =       "#000000"
            colorButtonHover =      "#E4E4E4"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"

        } else if (themeIndex === ThemeEngine.DARK_AND_SPOOKY) {

            // "DARK AND SPOOKY"

            colorSidebar =          "#2e2e2e"
            colorSidebarContent =   "#ffffff"

            colorHeader =           "#282828"
            colorHeaderContent =    "#a0a0a0" // sub: "#a89a9a"

            colorBackground =       "#444444"
            colorForeground =       "#555555"

            colorText =             "#ffffff"
            colorSubText =          "#dddddd"
            colorIcon =             "#ffffff"

            colorPrimary =          "#ff9f1a"
            colorSecondary =        "#c56cf0"
            colorWarning =          "#ee2b57"
            colorError =            "#FFDB63"

            colorButton =           "#555555"
            colorButtonDown =       "#333333"
            colorButtonText =       "#ffffff"
            colorButtonHover =      "#E4E4E4"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"

        } else if (themeIndex === ThemeEngine.BLOOD_AND_TEARS) {

            // "BLOOD AND TEARS"

            colorSidebar =          "#181818"
            colorSidebarContent =   "#bebebe"

            colorHeader =           "#141414"
            colorHeaderContent =    "#ffffff" // sub: "#a3a3a0"

            colorBackground =       "#222222"
            colorForeground =       "#333333"

            colorText =             "#a3a3a0"
            colorSubText =          "#a3a3a0"
            colorIcon =             "#a3a3a0"

            colorPrimary =          "#009ee2"
            colorSecondary =        "#009ee2"
            colorWarning =          "#fa6871"
            colorError =            "#FFDB63"

            colorButton =           "#ffffff"
            colorButtonText =       "#000000"
            colorButtonDown =       "#bdbdbd"
            colorButtonHover =      "#E4E4E4"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "bar"

        } else if (themeIndex === ThemeEngine.MIGHTY_KITTEN) {

            // "MIGHTY KITTEN"
            // pink "#ED65A7"
            // pink bright "#E21F8D"
            // purple "#944197"
            // green "#81BD41"
            // light green "#A5CD52"
            // blue "#0DBED4"
            // light blue "#44C5DA"
            // yellow "#FCCD13" "#FFE400"

            colorSidebar =          "#E31D8D"
            colorSidebarContent =   "#FFFBE2"

            colorHeader =           "#F99DCE"
            colorHeaderContent =    "#E31D8D" // sub: "#8F4594"

            colorBackground =       "#ffffff"
            colorForeground =       "#ffe7f3"

            colorText =             "#944197"
            colorSubText =          "#944197"
            colorIcon =             "#944197"

            colorPrimary =          "#FFE400"
            colorSecondary =        "#FFE400"
            colorWarning =          "#944197"
            colorError =            "#FFDB63"

            colorButton =           "#FF3BB3"
            colorButtonText =       "#ffffff"
            colorButtonDown =       "#F592C1"
            colorButtonHover =      "#E4E4E4"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"
        }
    }
}
