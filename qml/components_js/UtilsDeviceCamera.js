// UtilsDeviceCamera.js
// Version 2
.pragma library

/* ************************************************************************** */

function getDevicePicture(device) {
    var deviceName = device.model
    var deviceType = device.deviceType
    var camera_model = "qrc:/cameras/";

    // Using device name
    if (deviceName.includes("HERO10") ||
        deviceName.includes("HERO9")) {
        camera_model += "H9"
    } else if (deviceName.includes("HERO8")) {
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
        // Using device type
        if (deviceType === 2)
            camera_model += "generic_smartphone"
        else if (deviceType === 3)
            camera_model += "generic_camera"
        else
        {
            // fallback
            if (deviceName.toUpperCase().includes("VIRB") ||
                deviceName.toUpperCase().includes("CONTOUR") ||
                deviceName.toUpperCase().includes("PIXPRO") ||
                deviceName.toUpperCase().includes("OSMO")) {
                // other known actioncam product line?
                camera_model += "generic_actioncam"
            } else {
                // assume smartphone...
                camera_model += "generic_smartphone"
            }
        }
    }

    return camera_model + ".svg"
}
