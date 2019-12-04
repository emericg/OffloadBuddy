// UtilsDevice.js
// Version 0.1
.pragma library

/* ************************************************************************** */

function getDevicePicture(deviceName) {
    var camera_model = "qrc:/cameras/";

    if (deviceName.includes("HERO8")) {
        camera_model += "H8"
    } else if (deviceName.includes("HERO7 White") ||
               deviceName.includes("HERO7 Silver")) {
        camera_model += "H7w"
    } else if (deviceName.includes("HERO7") ||
               deviceName.includes("HERO6") ||
               deviceName.includes("HERO5")) {
        camera_model += "H5"
    } else if (deviceName.includes("Session")) {
        camera_model += "session"
    } else if (deviceName.includes("HERO4")) {
        camera_model += "H4"
    } else if (deviceName.includes("HERO3") || deviceName.includes("Hero3")) {
        camera_model += "H3"
    } else if (deviceName.includes("FUSION") || deviceName.includes("Fusion")) {
        camera_model += "fusion"
    } else if (deviceName.includes("MAX") || deviceName.includes("Max")) {
        camera_model += "max"
    } else if (deviceName.includes("HD2")) {
        camera_model += "H2"
    } else {
        // fallback
        if (myDevice.deviceType === 2)
            camera_model += "generic_smartphone"
        else if (myDevice.deviceType === 3)
            camera_model += "generic_camera"
        else
            camera_model += "generic_actioncam"
    }

    //if (inverted) camera_model += "-inverted"
    return camera_model + ".svg"
}
