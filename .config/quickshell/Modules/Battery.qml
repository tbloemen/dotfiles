import Quickshell.Services.UPower
import "../Theme"

// Replaces waybar's battery module. UPowerDevice.percentage is a 0..1
// fraction (confirmed live), and .state follows the standard UPower
// DeviceState D-Bus enum: 1 Charging, 2 Discharging, 3 Empty, 4 FullyCharged,
// 5 PendingCharge, 6 PendingDischarge.
Pill {
    id: root
    visible: UPower.displayDevice.isLaptopBattery

    readonly property real pct: UPower.displayDevice.percentage * 100
    readonly property bool charging: UPower.displayDevice.state === 1
    readonly property bool critical: !charging && pct <= 10
    readonly property bool warning: !charging && pct <= 20

    // Ports waybar's style.css verbatim: #battery is unconditionally themed
    // @red; warning/critical override to a hardcoded (non-themed) alarm
    // red/yellow; charging overrides to themed @green.
    bg: charging ? Colors.green : ((warning || critical) ? "#ff0000" : Colors.red)
    fg: charging ? Colors.mantle : ((warning || critical) ? "#ffff00" : Colors.mantle)

    icon: {
        const p = pct;
        if (charging) {
            if (p >= 95)
                return "battery_charging_full";
            if (p >= 80)
                return "battery_charging_90";
            if (p >= 60)
                return "battery_charging_60";
            if (p >= 50)
                return "battery_charging_50";
            if (p >= 30)
                return "battery_charging_30";
            return "battery_charging_20";
        }
        if (p >= 95)
            return "battery_full";
        if (p >= 80)
            return "battery_6_bar";
        if (p >= 60)
            return "battery_5_bar";
        if (p >= 45)
            return "battery_4_bar";
        if (p >= 30)
            return "battery_3_bar";
        if (p >= 15)
            return "battery_2_bar";
        if (p >= 5)
            return "battery_1_bar";
        return "battery_alert";
    }
    value: Math.round(pct) + "%"
}
