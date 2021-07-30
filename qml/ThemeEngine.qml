pragma Singleton

import QtQuick 2.12
import QtQuick.Controls.Material 2.12

Item {
    enum ThemeNames {
        LIGHT_AND_WARM = 0,
        DARK_AND_SPOOKY = 1,
        PLAIN_AND_BORING = 2,
        BLOOD_AND_TEARS = 3,
        MIGHTY_KITTENS = 4,

        THEME_LAST
    }
    property int currentTheme: -1

    ////////////////

    property int themeStatusbar
    property string colorStatusbar

    // Header
    property string colorHeader
    property string colorHeaderContent
    property string colorHeaderHighlight

    // Sidebar
    property string colorSidebar
    property string colorSidebarContent
    property string colorSidebarHighlight

    // Action bar
    property string colorActionbar
    property string colorActionbarContent
    property string colorActionbarHighlight

    // Tablet bar
    property string colorTabletmenu
    property string colorTabletmenuContent
    property string colorTabletmenuHighlight

    // Content
    property string colorBackground
    property string colorForeground

    property string colorPrimary
    property string colorSecondary
    property string colorSuccess
    property string colorWarning
    property string colorError

    property string colorText
    property string colorSubText
    property string colorIcon
    property string colorSeparator

    property string colorLowContrast
    property string colorHighContrast

    // App specific
    property string sidebarSelector: "" // 'arrow' or 'bar'

    // Qt Quick controls & theming
    property string colorComponent
    property string colorComponentText
    property string colorComponentContent
    property string colorComponentBorder
    property string colorComponentDown
    property string colorComponentBackground

    property int componentHeight: 40
    property int componentRadius: 4
    property int componentBorderWidth: 1

    ////////////////

    // Palette colors
    readonly property string colorGrey: "#888"

    // Fixed colors
    readonly property string colorMaterialBlue: "#2196f3"
    readonly property string colorMaterialIndigo: "#3f51b5"
    readonly property string colorMaterialPurple: "#9c27b0"
    readonly property string colorMaterialDeepPurple: "#673ab7"
    readonly property string colorMaterialRed: "#f44336"
    readonly property string colorMaterialOrange: "#ff9800"
    readonly property string colorMaterialLightGreen: "#8bc34a"

    readonly property string colorMaterialDarkGrey: "#e0e0e0"
    readonly property string colorMaterialGrey: "#eeeeee"
    readonly property string colorMaterialLightGrey: "#fafafa"
    readonly property string colorMaterialThisblue: "#448aff"

    ////////////////

    // Fonts (sizes in pixel) (WIP)
    readonly property int fontSizeHeader: 30
    readonly property int fontSizeTitle: 24
    readonly property int fontSizeContentVerySmall: 12
    readonly property int fontSizeContentSmall: 14
    readonly property int fontSizeContent: 16
    readonly property int fontSizeContentBig: 18
    readonly property int fontSizeContentVeryBig: 20
    readonly property int fontSizeComponent: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 14 : 15

    ////////////////////////////////////////////////////////////////////////////

    Component.onCompleted: loadTheme(settingsManager.appTheme)
    Connections {
        target: settingsManager
        onAppThemeChanged: { loadTheme(settingsManager.appTheme) }
    }

    function loadTheme(themeIndex) {
        //console.log("ThemeEngine.loadTheme(" + themeIndex + ")")

        if (themeIndex >= ThemeEngine.THEME_LAST) themeIndex = 0

        if (themeIndex === currentTheme) return;

        if (themeIndex === ThemeEngine.LIGHT_AND_WARM) {

            // "LIGHT AND WARM"

            colorHeader =               "#D0D0D0"
            colorHeaderContent =        "#353637"
            colorHeaderHighlight =      ""

            colorSidebar =              "#2E2E2E"
            colorSidebarContent =       "white"
            colorSidebarHighlight =     ""

            colorActionbar =            "#8CD200"
            colorActionbarContent =     "white"
            colorActionbarHighlight =   "#73AD00"

            colorBackground =           "#F0F0F0"
            colorForeground =           "#E0E0E0"

            colorPrimary =              "#FFCA28"
            colorSecondary =            "#FFDD28"
            colorSuccess =              colorMaterialLightGreen
            colorWarning =              "#FFAC00"
            colorError =                "#E64B39"

            colorText =                 "#222"
            colorSubText =              "#555"
            colorIcon =                 "#333"
            colorSeparator =            "#E4E4E4"
            colorLowContrast =          "white"
            colorHighContrast =         "black"

            colorComponent =            "#DBDBDB"
            colorComponentText =        "black"
            colorComponentContent =     "black"
            colorComponentBorder =      "#C1C1C1"
            colorComponentDown =        "#E4E4E4"
            colorComponentBackground =  "#FAFAFA"

            sidebarSelector = ""
            componentRadius = 4
            componentBorderWidth = 2

        } else if (themeIndex === ThemeEngine.DARK_AND_SPOOKY) {

            // "DARK AND SPOOKY"

            colorHeader =               "#282828"
            colorHeaderContent =        "#C0C0C0"
            colorHeaderHighlight =      ""

            colorSidebar =              "#2E2E2E"
            colorSidebarContent =       "white"
            colorSidebarHighlight =     ""

            colorActionbar =            "#FEC759"
            colorActionbarContent =     "white"
            colorActionbarHighlight =   "#FFAF00"

            colorBackground =           "#404040"
            colorForeground =           "#555555"

            colorPrimary =              "#FF9F1A" // indigo: "#6C5ECD"
            colorSecondary =            "#FFB81A" // indigo2: "#9388E5"
            colorSuccess =              colorMaterialLightGreen
            colorWarning =              "#FE8F2D"
            colorError =                "#D33E39"

            colorText =                 "white"
            colorSubText =              "#DDD"
            colorIcon =                 "white"
            colorSeparator =            "#666"
            colorLowContrast =          "black"
            colorHighContrast =         "white"

            colorComponent =            "#555"
            colorComponentText =        "white"
            colorComponentContent =     "white"
            colorComponentBorder =      "#666"
            colorComponentDown =        "#333"
            colorComponentBackground =  "#505050"

            sidebarSelector = ""
            componentRadius = 3
            componentBorderWidth = 1

        } else if (themeIndex === ThemeEngine.PLAIN_AND_BORING) {

            // "PLAIN AND BORING"

            colorHeader =               "#E8E8E8"
            colorHeaderContent =        "#353637"
            colorHeaderHighlight =      ""

            colorSidebar =              "#2A5D92"
            colorSidebarContent =       "white"
            colorSidebarHighlight =     ""

            colorActionbar =            "#FFD54A"
            colorActionbarContent =     "white"
            colorActionbarHighlight =   "#FFC831"

            colorBackground =           "#FEFEFE"
            colorForeground =           "#F0F0F0"

            colorPrimary =              "#0079E3"
            colorSecondary =            "#00A0E3"
            colorSuccess =              colorMaterialLightGreen
            colorWarning =              "#FFC107"
            colorError =                "#FF5722"

            colorText =                 "black"
            colorSubText =              "#606060"
            colorIcon =                 "black"
            colorSeparator =            "#E0E0E0"
            colorLowContrast =          "white"
            colorHighContrast =         "black"

            colorComponent =            "#F3F3F3"
            colorComponentText =        "black"
            colorComponentContent =     "black"
            colorComponentBorder =      "#E0E0E0"
            colorComponentDown =        "#C1C1C1"
            colorComponentBackground =  "#F3F3F3"

            sidebarSelector = "arrow"
            componentRadius = 4
            componentBorderWidth = 1

        } else if (themeIndex === ThemeEngine.BLOOD_AND_TEARS) {

            // "BLOOD AND TEARS"

            colorHeader =               "#141414"
            colorHeaderContent =        "white"
            colorHeaderHighlight =      ""

            colorSidebar =              "#181818"
            colorSidebarContent =       "#DDD"
            colorSidebarHighlight =     ""

            colorActionbar =            "#009EE2"
            colorActionbarContent =     "white"
            colorActionbarHighlight =   "#0089C3"

            colorBackground =           "#222"
            colorForeground =           "#333"

            colorPrimary =              "#009EE2"
            colorSecondary =            "#00BEE2"
            colorSuccess =              colorMaterialLightGreen
            colorWarning =              "#FFDB63"
            colorError =                "#FA6871"

            colorText =                 "#D2D2D2"
            colorSubText =              "#A3A3A3"
            colorIcon =                 "#D2D2D2"
            colorSeparator =            "#666"
            colorLowContrast =          "black"
            colorHighContrast =         "white"

            colorComponent =            "white"
            colorComponentText =        "black"
            colorComponentContent =     "black"
            colorComponentBorder =      "#E4E4E4"
            colorComponentDown =        "#CCC"
            colorComponentBackground =  "white"

            componentRadius = 1
            sidebarSelector = "bar"
            componentBorderWidth = 1

        } else if (themeIndex === ThemeEngine.MIGHTY_KITTENS) {

            // "MIGHTY KITTENS"
            // pink "#ED65A7"
            // pink bright "#E21F8D"
            // purple "#944197"
            // green "#81BD41"
            // light green "#A5CD52"
            // blue "#0DBED4"
            // light blue "#44C5DA"
            // yellow "#FCCD13" "#FFE400"

            colorHeader =               "#FFB4DC"
            colorHeaderContent =        "#944197"
            colorHeaderHighlight =      ""

            colorSidebar =              "#E31D8D"
            colorSidebarContent =       "#FFF06D"
            colorSidebarHighlight =     ""

            colorActionbar =            "#FFE400"
            colorActionbarContent =     "white"
            colorActionbarHighlight =   "#FFBF00"

            colorBackground =           "white"
            colorForeground =           "#FFDDEE"

            colorPrimary =              "#FFE400"
            colorSecondary =            "#FFF600"
            colorSuccess =              colorMaterialLightGreen
            colorWarning =              "#944197"
            colorError =                "#FA6871"

            colorText =                 "#944197"
            colorSubText =              "#944197"
            colorIcon =                 "#944197"
            colorSeparator =            "#E4E4E4"
            colorLowContrast =          "white"
            colorHighContrast =         "red"

            colorComponent =            "#FF87D0"
            colorComponentText =        "#944197"
            colorComponentContent =     "white"
            colorComponentBorder =      "#F592C1"
            colorComponentDown =        "#FF9ED9"
            colorComponentBackground =  "#FFF4F9"

            sidebarSelector = ""
            componentRadius = 20
            componentBorderWidth = 2
        }

        // This will emit the signal 'onCurrentThemeChanged'
        currentTheme = themeIndex
    }
}
