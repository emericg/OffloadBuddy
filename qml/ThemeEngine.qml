pragma Singleton
import QtQuick 2.9

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

    // Header
    property string colorHeader
    property string colorHeaderContent
    property string colorHeaderStatusbar

    // Sidebar
    property string colorSidebar
    property string colorSidebarContent

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
    property string colorWarning
    property string colorError

    property string colorText
    property string colorSubText
    property string colorIcon
    property string colorSeparator
    property string colorHighContrast

    // Qt Quick controls & theming
    property string colorComponent
    property string colorComponentText
    property string colorComponentContent
    property string colorComponentBorder
    property string colorComponentDown
    property string colorComponentBackground
    property int componentRadius: 3
    property int componentHeight: 40

    ////////////////

    // sidebarSelector (arrow or bar)
    property string sidebarSelector: "arrow"

    ////////////////

    // Fixed palette
    readonly property string colorMaterialBlue: "#2196f3"
    readonly property string colorMaterialIndigo: "#3f51b5"
    readonly property string colorMaterialPurple: "#9c27b0"
    readonly property string colorMaterialDeepPurple: "#673ab7"
    readonly property string colorMaterialRed: "#f44336"
    readonly property string colorMaterialLightGreen: "#8bc34a"

    readonly property string colorMaterialDarkGrey: "#e0e0e0"
    readonly property string colorMaterialGrey: "#eeeeee"
    readonly property string colorMaterialLightGrey: "#fafafa"
    readonly property string colorMaterialThisblue: "#448aff"

    ////////////////

    // Fonts (sizes in pixel)
    readonly property int fontSizeHeaderTitle: 30
    readonly property int fontSizeHeaderText: 17
    readonly property int fontSizeBannerText: 20
    readonly property int fontSizeContentTitle: 24
    readonly property int fontSizeContentText: 15
    readonly property int fontSizeComponentText: 15

    ////////////////////////////////////////////////////////////////////////////

    Component.onCompleted: loadTheme(settingsManager.appTheme)
    Connections {
        target: settingsManager
        onAppThemeChanged: loadTheme(settingsManager.appTheme)
    }

    function loadTheme(themeIndex) {
        //console.log("ThemeEngine.loadTheme(" + themeIndex + ")")

        if (themeIndex >= ThemeEngine.THEME_LAST) themeIndex = 0

        if (themeIndex === currentTheme) return;

        if (themeIndex === ThemeEngine.LIGHT_AND_WARM) {

            // "LIGHT AND WARM"

            colorHeader =           "#CBCBCB"
            colorHeaderContent =    "#353637"

            colorSidebar =          "#2e2e2e"
            colorSidebarContent =   "white"

            colorActionbar =        "#8cd200"
            colorActionbarContent = "white"
            colorActionbarHighlight = "#73AD00"

            colorBackground =       "#EEEEEE"
            colorForeground =       "#E0E0E0"

            colorText =             "#222222"
            colorSubText =          "#555555"
            colorIcon =             "#333333"
            colorSeparator =        "#E4E4E4"
            colorHighContrast =     "black"

            colorPrimary =          "#ffca28"
            colorSecondary =        "#ffdd28"
            colorWarning =          "#ffac00"
            colorError =            "#dc322f"

            colorComponent =        "#DBDBDB"
            colorComponentText =    "black"
            colorComponentContent = "black"
            colorComponentBorder =  "#c1c1c1"
            colorComponentDown =    "#E4E4E4"
            colorComponentBackground = "#FAFAFA"
            componentRadius = 3

            sidebarSelector = ""

        } else if (themeIndex === ThemeEngine.DARK_AND_SPOOKY) {

            // "DARK AND SPOOKY"

            colorHeader =           "#282828"
            colorHeaderContent =    "#c0c0c0"

            colorSidebar =          "#2e2e2e"
            colorSidebarContent =   "white"

            colorActionbar =        "#FED259"
            colorActionbarContent = "white"
            colorActionbarHighlight = "#FFBA00"

            colorBackground =       "#404040"
            colorForeground =       "#555555"

            colorText =             "white"
            colorSubText =          "#EEEEEE"
            colorIcon =             "white"
            colorSeparator =        "#E4E4E4"
            colorHighContrast =     "white"

            colorPrimary =          "#ff9f1a" // indigo: "#6C5ECD"
            colorSecondary =        "#ffb81a" // indigo2: "#9388e5"
            colorWarning =          "#e38541"
            colorError =            "#dc322f"

            colorComponent =        "#555555"
            colorComponentText =    "white"
            colorComponentContent = "white"
            colorComponentBorder =  "#666666"
            colorComponentDown =    "#333333"
            colorComponentBackground = "#505050"
            componentRadius = 3

            sidebarSelector = ""

        } else if (themeIndex === ThemeEngine.PLAIN_AND_BORING) {

            // "PLAIN AND BORING"

            colorHeader =           "#E9E9E9"
            colorHeaderContent =    "#353637"

            colorSidebar =          "#607D8B"
            colorSidebarContent =   "white"

            colorActionbar =        "#fed859"
            colorActionbarContent = "white"
            colorActionbarHighlight = "#FFC831"

            colorBackground =       "white"
            colorForeground =       "#F0F0F0"

            colorText =             "black"
            colorSubText =          "#606060"
            colorIcon =             "black"
            colorSeparator =        "#E0E0E0"
            colorHighContrast =     "black"

            colorPrimary =          "#03A9F4"
            colorSecondary =        "#03c1f4"
            colorWarning =          "#FFC107"
            colorError =            "#FF5722"

            colorComponent =        "#D9D9D9"
            colorComponentText =    "black"
            colorComponentContent = "black"
            colorComponentBorder =  "#E0E0E0"
            colorComponentDown =    "#c1c1c1"
            colorComponentBackground = "#FEFEFE"
            componentRadius = 3

            sidebarSelector = "arrow"

        } else if (themeIndex === ThemeEngine.BLOOD_AND_TEARS) {

            // "BLOOD AND TEARS"

            colorHeader =           "#141414"
            colorHeaderContent =    "white"

            colorSidebar =          "#181818"
            colorSidebarContent =   "#DDDDDD"

            colorActionbar =        "#009ee2"
            colorActionbarContent = "white"
            colorActionbarHighlight = "#0089C3"

            colorBackground =       "#222222"
            colorForeground =       "#333333"

            colorText =             "#d2d2d2"
            colorSubText =          "#a3a3a3"
            colorIcon =             "#d2d2d2"
            colorSeparator =        "#666666"
            colorHighContrast =     "white"

            colorPrimary =          "#009ee2"
            colorSecondary =        "#00bee2"
            colorWarning =          "#FFDB63"
            colorError =            "#fa6871"

            colorComponent =        "white"
            colorComponentText =    "black"
            colorComponentContent = "black"
            colorComponentBorder =  "#E4E4E4"
            colorComponentDown =    "#CCCCCC"
            colorComponentBackground = "white"
            componentRadius = 1

            sidebarSelector = "bar"

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

            colorHeader =           "#F99DCE"
            colorHeaderContent =    "#944197"

            colorSidebar =          "#E31D8D"
            colorSidebarContent =   "#FFFBE2"

            colorActionbar =        "#FFE400"
            colorActionbarContent = "white"
            colorActionbarHighlight = "#FFBF00"

            colorBackground =       "white"
            colorForeground =       "#ffddee"

            colorText =             "#944197"
            colorSubText =          "#944197"
            colorIcon =             "#944197"

            colorPrimary =          "#FFE400"
            colorSecondary =        "#fff600"
            colorWarning =          "#944197"
            colorError =            "#fa6871"
            colorSeparator =        "#E4E4E4"
            colorHighContrast =     "red"

            colorComponent =        "#ff6ec7"
            colorComponentText =    "#944197"
            colorComponentContent = "white"
            colorComponentBorder =  "#F592C1"
            colorComponentDown =    "#F592C1"
            colorComponentBackground = "#fff4f9"
            componentRadius = 4

            sidebarSelector = ""
        }

        // This will emit the signal 'onCurrentThemeChanged'
        currentTheme = themeIndex
    }
}
