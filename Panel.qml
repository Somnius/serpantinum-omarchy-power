import "Model.js" as Model
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

Panel {
    id: root

    property var profiles: []
    property string activeProfile: ""
    property var systemInfo: ({
    })
    property string profileError: ""
    property int profileIndex: 0
    property bool acceptQueryResults: false
    property bool profileActionBusy: false
    readonly property bool showPercentage: setting("showPercentage", true) === true
    readonly property bool showSystemStats: setting("showSystemStats", true) === true
    readonly property bool reducedMotion: setting("reducedMotion", false) === true
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: !!(battery && battery.isPresent)
    readonly property real fraction: Model.batteryFraction(battery)
    readonly property string powerState: Model.batteryState(battery, UPower.onBattery, ({
        "Charging": UPowerDeviceState.Charging,
        "Discharging": UPowerDeviceState.Discharging,
        "FullyCharged": UPowerDeviceState.FullyCharged,
        "PendingCharge": UPowerDeviceState.PendingCharge
    }))
    readonly property string glyph: Model.batteryIcon(powerState, fraction)
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    function refresh() {
        if (!opened)
            return ;

        acceptQueryResults = true;
        if (!profilesProcess.running)
            profilesProcess.running = true;

        if (showSystemStats && !systemProcess.running)
            systemProcess.running = true;

        queryTimeout.restart();
    }

    function setProfile(profile) {
        if (!profile || profileActionBusy)
            return ;

        profileError = "";
        profileActionBusy = true;
        profileProcess.timedOut = false;
        profileProcess.command = ["omarchy-powerprofiles-set", UPower.onBattery ? "battery" : "ac", profile];
        profileProcess.running = true;
        profileTimeout.restart();
    }

    function updateProfiles(raw) {
        if (!acceptQueryResults)
            return ;

        var parsed = Model.parseProfiles(raw);
        profiles = parsed.profiles;
        activeProfile = parsed.active;
        profileIndex = Math.max(0, Math.min(profileIndex, profiles.length - 1));
    }

    function moveProfile(delta) {
        if (profiles.length === 0)
            return ;

        profileIndex = Math.max(0, Math.min(profiles.length - 1, profileIndex + delta));
    }

    function activateProfile() {
        if (profileIndex >= 0 && profileIndex < profiles.length)
            setProfile(String(profiles[profileIndex]));

    }

    function settleQueries() {
        if (!profilesProcess.running && !systemProcess.running)
            queryTimeout.stop();

        if (!profilesProcess.running && !systemProcess.running)
            acceptQueryResults = false;

    }

    moduleName: "somnius.serpantinum-power"
    ipcTarget: "somnius.serpantinum-power"
    onOpenedChanged: {
        if (opened) {
            profileError = "";
            refresh();
            entrance.restart();
        } else {
            acceptQueryResults = false;
            if (profilesProcess.running)
                profilesProcess.running = false;

            if (systemProcess.running)
                systemProcess.running = false;

            queryTimeout.stop();
            entrance.stop();
            content.opacity = 0;
            content.scale = 0.96;
        }
    }

    BarIconButton {
        id: button

        anchors.fill: parent
        bar: root.bar
        text: root.showPercentage && root.batteryPresent && !vertical ? Math.round(root.fraction * 100) + "% " + root.glyph : root.glyph
        slotSize: Style.bar.iconSlot * (root.showPercentage && root.batteryPresent && !vertical ? 2 : 1)
        tooltipText: root.batteryPresent ? Model.stateLabel(root.powerState) + " · " + Math.round(root.fraction * 100) + "%" : "AC power · No battery detected"
        onPressed: function(mouseButton) {
            if (mouseButton === Qt.LeftButton)
                root.toggle();

        }
    }

    KeyboardPanel {
        id: popup

        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: popup.fittedContentWidth(Style.space(390))
        contentHeight: popup.fittedContentHeight(content.implicitHeight)

        PanelKeyCatcher {
            id: keyCatcher

            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) {
                root.switchPanel(direction);
            }
            onMoveRequested: function(dx, dy) {
                if (dx !== 0)
                    root.moveProfile(dx);
                else if (dy !== 0)
                    root.moveProfile(dy);
            }
            onActivateRequested: root.activateProfile()

            Column {
                id: content

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Style.space(14)
                opacity: 0
                scale: 0.96
                transformOrigin: Item.TopRight

                Item {
                    width: parent.width
                    implicitHeight: Math.max(heroGlyph.implicitHeight, heroText.implicitHeight, heroValue.implicitHeight)

                    Text {
                        id: heroGlyph

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyph
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.displayLarge
                    }

                    Column {
                        id: heroText

                        anchors.left: heroGlyph.right
                        anchors.leftMargin: Style.space(14)
                        anchors.right: heroValue.left
                        anchors.rightMargin: Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(2)

                        Text {
                            width: parent.width
                            text: root.batteryPresent ? "Power reserve" : "Desktop power"
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.title
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Model.stateLabel(root.powerState)
                            color: root.foreground
                            opacity: 0.58
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.bold: true
                            font.letterSpacing: 1.1
                            elide: Text.ElideRight
                        }

                    }

                    Text {
                        id: heroValue

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryPresent ? Math.round(root.fraction * 100) + "%" : "AC"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.displayLarge
                        font.bold: true
                    }

                }

                Item {
                    visible: root.batteryPresent
                    width: parent.width
                    implicitHeight: visible ? Style.space(9) : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        width: Math.max(height, parent.width * root.fraction)
                        radius: height / 2
                        color: root.foreground

                        Behavior on width {
                            NumberAnimation {
                                duration: root.reducedMotion ? 0 : 420
                                easing.type: Easing.OutCubic
                            }

                        }

                        SequentialAnimation on opacity {
                            running: root.opened && root.powerState === "charging" && !root.reducedMotion
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0.5
                                duration: 900
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 1
                                duration: 900
                                easing.type: Easing.InOutSine
                            }

                        }

                    }

                }

                Text {
                    visible: !root.batteryPresent
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "No battery is present. Power profiles and live system status remain available."
                    color: root.foreground
                    opacity: 0.66
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                }

                PanelSeparator {
                    foreground: root.foreground
                }

                Column {
                    width: parent.width
                    spacing: Style.space(9)

                    PanelSectionHeader {
                        text: "POWER PROFILE"
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                    }

                    Row {
                        id: profileRow

                        readonly property real itemWidth: root.profiles.length > 0 ? (width - spacing * (root.profiles.length - 1)) / root.profiles.length : 0

                        visible: root.profiles.length > 0
                        width: parent.width
                        spacing: Style.space(6)

                        Repeater {
                            model: root.profiles

                            Button {
                                required property var modelData

                                width: profileRow.itemWidth
                                iconText: Model.profileIcon(String(modelData))
                                text: Model.formatProfile(String(modelData))
                                foreground: root.foreground
                                fontFamily: root.fontFamily
                                fontSize: Style.font.bodySmall
                                bordered: true
                                active: root.activeProfile === modelData
                                hasCursor: index === root.profileIndex
                                enabled: !root.profileActionBusy
                                onClicked: root.setProfile(String(modelData))
                            }

                        }

                    }

                    Text {
                        visible: root.profiles.length === 0
                        width: parent.width
                        text: "Power profiles are unavailable on this system."
                        color: root.foreground
                        opacity: 0.6
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                    }

                    Text {
                        visible: root.profileError !== ""
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.profileError
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                    }

                }

                PanelSeparator {
                    visible: root.showSystemStats
                    foreground: root.foreground
                }

                Column {
                    visible: root.showSystemStats
                    width: parent.width
                    spacing: Style.space(9)

                    PanelSectionHeader {
                        text: "SYSTEM STATUS"
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: Style.space(18)
                        rowSpacing: Style.space(7)

                        StatusValue {
                            visible: !!root.systemInfo.cpu
                            label: "CPU"
                            value: root.systemInfo.cpu || ""
                        }

                        StatusValue {
                            visible: !!(root.systemInfo.memory || root.systemInfo.ram)
                            label: "Memory"
                            value: root.systemInfo.memory || root.systemInfo.ram || ""
                        }

                        StatusValue {
                            visible: !!(root.systemInfo.temperature || root.systemInfo.temp)
                            label: "Temperature"
                            value: root.systemInfo.temperature || root.systemInfo.temp || ""
                        }

                        StatusValue {
                            visible: !!root.systemInfo.uptime
                            label: "Uptime"
                            value: root.systemInfo.uptime || ""
                        }

                    }

                }

            }

        }

    }

    Process {
        id: profilesProcess

        command: ["omarchy-powerprofiles-list", "--active-state"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.profiles = [];
                root.activeProfile = "";
            }
            Qt.callLater(root.settleQueries);
        }

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateProfiles(text)
        }

    }

    Process {
        id: systemProcess

        command: ["omarchy-system-stats"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.systemInfo = ({
            });

            Qt.callLater(root.settleQueries);
        }

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.acceptQueryResults)
                    return ;

                var parsed = Model.parseKeyValue(text);
                root.systemInfo = parsed;
            }
        }

    }

    Process {
        id: profileProcess

        property bool timedOut: false

        onExited: function(exitCode) {
            profileTimeout.stop();
            if (exitCode !== 0 && !timedOut)
                root.profileError = "The system declined that profile change.";

            root.profileActionBusy = false;
            if (root.opened)
                root.refresh();

        }

        stdout: StdioCollector {
            waitForEnd: true
        }

        stderr: StdioCollector {
            waitForEnd: true
        }

    }

    Timer {
        id: queryTimeout

        interval: 4000
        repeat: false
        onTriggered: {
            root.acceptQueryResults = false;
            if (profilesProcess.running)
                profilesProcess.running = false;

            if (systemProcess.running)
                systemProcess.running = false;

            root.profiles = [];
            root.activeProfile = "";
            root.systemInfo = ({
            });
        }
    }

    Timer {
        id: profileTimeout

        interval: 10000
        repeat: false
        onTriggered: {
            if (profileProcess.running) {
                profileProcess.timedOut = true;
                profileProcess.running = false;
            }
            root.profileError = "The profile change timed out.";
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.opened
        onTriggered: root.refresh()
    }

    ParallelAnimation {
        id: entrance

        NumberAnimation {
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: root.reducedMotion ? 0 : 380
            easing.type: Easing.OutQuart
        }

        NumberAnimation {
            target: content
            property: "scale"
            from: 0.96
            to: 1
            duration: root.reducedMotion ? 0 : 520
            easing.type: Easing.OutBack
            easing.overshoot: 0.8
        }

    }

    component StatusValue: Item {
        property string label: ""
        property string value: ""

        width: (parent.width - parent.columnSpacing) / 2
        implicitHeight: statusColumn.implicitHeight

        Column {
            id: statusColumn

            width: parent.width
            spacing: Style.space(2)

            Text {
                width: parent.width
                text: parent.parent.label.toUpperCase()
                color: root.foreground
                opacity: 0.5
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
            }

            Text {
                width: parent.width
                text: parent.parent.value
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
            }

        }

    }

}
