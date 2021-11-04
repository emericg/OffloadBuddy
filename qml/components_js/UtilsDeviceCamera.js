// UtilsDeviceCamera.js
// Version 2
.pragma library

/* ************************************************************************** */

function getDevicePicture(device) {
    var deviceBrand = device.brand
    var deviceName = device.model
    var deviceType = device.deviceType
    var camera_model = "qrc:/cameras/";

    // Using device name
    if (deviceBrand === "GoPro") {
        if (deviceName.includes("HERO10") ||
            deviceName.includes("HERO9")) {
            camera_model += "gopro_H9"
        } else if (deviceName.includes("HERO8")) {
            camera_model += "gopro_H8"
        } else if (deviceName.includes("HERO7 White") ||
                   deviceName.includes("HERO7 Silver")) {
            camera_model += "gopro_H7w"
        } else if (deviceName.includes("HERO7") ||
                   deviceName.includes("HERO6") ||
                   deviceName.includes("HERO5")) {
            camera_model += "gopro_H5"
        } else if (deviceName.includes("Session")) {
            camera_model += "gopro_session"
        } else if (deviceName.includes("HERO4")) {
            camera_model += "gopro_H4"
        } else if (deviceName.includes("HERO3") || deviceName.includes("Hero3")) {
            camera_model += "gopro_H3"
        } else if (deviceName.includes("FUSION") || deviceName.includes("Fusion")) {
            camera_model += "gopro_fusion"
        } else if (deviceName.includes("MAX") || deviceName.includes("Max")) {
            camera_model += "gopro_max"
        } else if (deviceName.includes("HD2")) {
            camera_model += "gopro_H2"
        } else {
            camera_model += "generic_actioncam"
        }
    } else if (deviceBrand === "Insta360") {
        if (deviceName.includes("One R")) {
            camera_model += "insta360_one_r"
        } else if (deviceName.includes("One X2")) {
            camera_model += "insta360_one_x2"
        } else if (deviceName.includes("One X")) {
            camera_model += "insta360_one_x"
        } else if (deviceName.includes("GO2") || deviceName.includes("GO")) {
            camera_model += "insta360_go2"
        } else {
            camera_model += "generic_actioncam"
        }
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
