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
    property string colorHeaderTitle        // DEPRECATED
    property string colorHeaderText         // DEPRECATED

    property string colorInfoBanner
    property string colorInfoBannerText

    property string colorBackground
    property string colorForeground
    property string colorContentBox // DEPRECATED
    property string colorContentTitle
    property string colorContentText
    property string colorContentSubBox
    property string colorContentSubTitle
    property string colorContentSubText

    property string colorText
    property string colorSubText
    property string colorIcon

    property string colorPrimary
    property string colorSecondary
    property string colorWarning
    property string colorError

    // Qt Quick controls theming // DEPRECATED
    property string colorButton: "#e0e0e0"
    property string colorButtonText: "#000000"
    property string colorButtonDown: "#bdbdbd"
    property string colorButtonHover: "#E4E4E4"
    property string colorComboBox: "#e0e0e0"
    property string colorComboBoxText: "#000000"
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

            colorSidebar =          "#4E596F"
            colorSidebarContent =   "#ffffff"

            colorHeader =           "#CBCBCB"
            colorHeaderTitle =      "#353637"
            colorHeaderText =       "#000000"

            colorBackground =      "#EEEEEE"
            colorForeground =      "#E0E0E0"

            colorContentBox =       "#F7F7F7"
            colorContentTitle =     "#353637"
            colorContentText =      "#000000"
            colorContentSubBox =    "#eef0f1"
            colorContentSubTitle =  "#000000"
            colorContentSubText =   "#000000"

            colorText =             "#000000"

            colorPrimary =          "#ffca28"
            colorWarning =          "#ffac00"
            colorError =            "#dc322f"

            colorButton =           "#e0e0e0"
            colorButtonText =       "#000000"
            colorButtonDown =       "#bdbdbd"
            colorButtonHover =      "#E4E4E4"
            colorComboBox =         "#e0e0e0"
            colorComboBoxText =     "#000000"
            colorProgressBar =      "#46b0f4"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"

        } else if (themeIndex === ThemeEngine.DARK_AND_SPOOKY) {

            // "DARK AND SPOOKY"

            colorSidebar =          "#2e2e2e"
            colorSidebarContent =   "#ffffff"

            colorHeader =           "#282828"
            colorHeaderTitle =      "#8b8e8f"
            colorHeaderText =       "#a89a9a"

            colorBackground =       "#404040"
            colorForeground =       "#555555"

            colorContentBox =       "#565656"
            colorContentTitle =     "#a0a29c"
            colorContentText =      "#ffffff"
            colorContentSubBox =    "#848484"
            colorContentSubTitle =  "#403F3C"
            colorContentSubText =   "#ffffff"

            colorText =             "#ffffff"

            colorPrimary =          "#f0544c"
            colorWarning =          "#ee2b57"
            colorError =            "#FFDB63"

            colorButton =           "#e0e0e0"
            colorButtonText =       "#000000"
            colorButtonDown =       "#bdbdbd"
            colorButtonHover =      "#E4E4E4"
            colorComboBox =         "#e0e0e0"
            colorComboBoxText =     "#000000"
            colorProgressBar =      "#f0544c"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"

        } else if (themeIndex === ThemeEngine.BLOOD_AND_TEARS) {

            // "BLOOD AND TEARS"

            colorSidebar =          "#181818"
            colorSidebarContent =   "#bebebe"

            colorHeader =           "#141414"
            colorHeaderTitle =      "#ffffff"
            colorHeaderText =       "#a3a3a0"

            colorBackground =       "#222222"
            colorForeground =       "#141414"

            colorContentBox =       "#333333"
            colorContentTitle =     "#a0a29c"
            colorContentText =      "#a3a3a0"
            colorContentSubBox =    "#565656"
            colorContentSubTitle =  "#ffffff"
            colorContentSubText =   "#a3a3a0"

            colorText =             "#a3a3a0"

            colorPrimary =          "#009ee2"
            colorWarning =          "#fa6871"
            colorError =            "#FFDB63"

            colorButton =           "#e0e0e0"
            colorButtonText =       "#000000"
            colorButtonDown =       "#bdbdbd"
            colorButtonHover =      "#E4E4E4"
            colorComboBox =         "#ffffff"
            colorComboBoxText =     "#000000"
            colorProgressBar =      "#009ee2"
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
            colorSidebarContent =   "#DCFF00"

            colorHeader =           "#faa7d1"
            colorHeaderTitle =      "#E31D8D"
            colorHeaderText =       "#8F4594"

            colorBackground =       "#ffffff"
            colorForeground =       "#faa7d1"

            colorContentBox =       "#fff5fa"
            colorContentTitle =     "#A4CC44"
            colorContentText =      "#944197"
            colorContentSubBox =    "#ffe7f3"
            colorContentSubTitle =  "#0DB8D4"
            colorContentSubText =   "#944197"

            colorText =             "#944197"

            colorPrimary =          "#FFE400"
            colorWarning =          "#944197"
            colorError =            "#FFDB63"

            colorButton =           "#ED65A7"
            colorButtonText =       "#ffffff"
            colorButtonDown =       "#F592C1"
            colorButtonHover =      "#E4E4E4"
            colorComboBox =         "#ED65A7"
            colorComboBoxText =     "#ffffff"
            colorProgressBar =      "#FFCB02"
            colorProgressBarBg =    "#E4E4E4"

            selector =              "arrow"
        }
    }
}
