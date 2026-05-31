pragma Singleton
pragma ComponentBehavior: Bound

// iwd/iwctl replacement for nmcli-based network service
// Original nmcli version by end-4 (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

Singleton {
    id: root

    property bool wifi: false
    property bool ethernet: false
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active) return -1
        if (!a.active && b.active) return 1
        return b.strength - a.strength
    })
    property string wifiStatus: "disconnected"
    property string networkName: ""
    property int networkStrength: 0

    readonly property string materialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                root.networkStrength > 83 ? "signal_wifi_4_bar" :
                root.networkStrength > 67 ? "network_wifi" :
                root.networkStrength > 50 ? "network_wifi_3_bar" :
                root.networkStrength > 33 ? "network_wifi_2_bar" :
                root.networkStrength > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : root.wifiStatus === "connecting" ? "signal_wifi_statusbar_not_connected"
            : root.wifiStatus === "disconnected" ? "wifi_find"
            : root.wifiStatus === "disabled" ? "signal_wifi_off"
            : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        enableWifiProc.exec(enabled
            ? ["rfkill", "unblock", "wifi"]
            : ["rfkill", "block", "wifi"])
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled)
    }

    function rescanWifi(): void {
        wifiScanning = true
        rescanProcess.running = true
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        accessPoint.askingPassword = false
        root.wifiConnectTarget = accessPoint
        connectProc.exec(["iwctl", "station", "wlan0", "connect", accessPoint.ssid])
    }

    function disconnectWifiNetwork(): void {
        disconnectProc.running = true
    }

    function openPublicWifiPortal(): void {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"])
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        network.askingPassword = false
        root.wifiConnectTarget = network
        connectProc.exec(["iwctl", "--passphrase", password, "station", "wlan0", "connect", network.ssid])
    }

    function update(): void {
        statusProc.running = true
        strengthProc.running = true
        ethernetProc.running = true
    }

    Process {
        id: enableWifiProc
        onExited: Qt.callLater(root.update)
    }

    Process {
        id: connectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: line => root.update()
        }
        stderr: SplitParser {
            onRead: line => {
                if (root.wifiConnectTarget && (
                    line.includes("passphrase") ||
                    line.includes("password") ||
                    line.includes("PSK") ||
                    line.includes("No agent")
                ))
                    root.wifiConnectTarget.askingPassword = true
            }
        }
        onExited: (exitCode) => {
            if (root.wifiConnectTarget) {
                if (exitCode !== 0) root.wifiConnectTarget.askingPassword = true
                root.wifiConnectTarget = null
            }
            root.update()
        }
    }

    Process {
        id: disconnectProc
        command: ["iwctl", "station", "wlan0", "disconnect"]
        onExited: root.update()
    }

    Process {
        id: rescanProcess
        command: ["iwctl", "station", "wlan0", "scan"]
        onExited: {
            wifiScanning = false
            getNetworks.running = true
        }
    }

    // Connection state + SSID from iwctl station show
    Process {
        id: statusProc
        command: ["bash", "-c",
            "iwctl station wlan0 show 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | " +
            "awk '/State/{print \"state:\"$2} /Connected network/{s=\"\"; for(i=3;i<=NF;i++) s=s (i==3?\"\":\" \") $i; print \"ssid:\"s}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("state:")) {
                    const s = data.slice(6).trim()
                    root.wifiEnabled = s !== ""
                    root.wifi = s === "connected"
                    root.wifiStatus = s === "connected" ? "connected"
                        : s === "connecting" ? "connecting"
                        : "disconnected"
                } else if (data.startsWith("ssid:")) {
                    root.networkName = data.slice(5).trim()
                }
            }
        }
    }

    // Signal strength from /proc/net/wireless (dBm → 0-100)
    Process {
        id: strengthProc
        command: ["awk", "/wlan0/{print $4+0}", "/proc/net/wireless"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const dbm = parseInt(data.trim()) || -100
                root.networkStrength = Math.round(Math.max(0, Math.min(100, (dbm + 90) * 100 / 60)))
            }
        }
    }

    // Ethernet: any non-wlan, non-lo interface with carrier=1
    Process {
        id: ethernetProc
        command: ["bash", "-c",
            "for f in /sys/class/net/*/carrier; do " +
            "  d=${f%/carrier}; d=${d##*/}; " +
            "  [[ \"$d\" != wlan* && \"$d\" != lo ]] && [[ $(cat $f 2>/dev/null) == 1 ]] && echo yes && break; " +
            "done"]
        running: true
        stdout: SplitParser {
            onRead: data => { root.ethernet = data.trim() === "yes" }
        }
    }

    // Network list: iwctl get-networks + python parse for SSID/signal/security
    Process {
        id: getNetworks
        running: true
        command: ["bash", "-c",
            "connected=$(iwctl station wlan0 show 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | " +
            "  awk '/Connected network/{s=\"\"; for(i=3;i<=NF;i++) s=s (i==3?\"\":\" \") $i; print s}' | xargs); " +
            "echo \"CONNECTED:$connected\"; " +
            "iwctl station wlan0 get-networks 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | " +
            "python3 -c \"" +
            "import sys, re\n" +
            "for line in sys.stdin:\n" +
            "    m = re.match(r'\\\\s+(.+?)\\\\s{2,}(psk|open|8021x|--)\\\\s+([*]+)', line)\n" +
            "    if m: print(m.group(1).strip()+'|'+str(len(m.group(3)))+'|'+m.group(2))\n" +
            "\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.length > 0)
                let connectedSsid = ""
                const networkData = []

                for (const line of lines) {
                    if (line.startsWith("CONNECTED:")) {
                        connectedSsid = line.slice(10).trim()
                    } else if (line.includes("|")) {
                        const [ssid, starsStr, security] = line.split("|")
                        if (ssid) networkData.push({
                            ssid, bssid: "", frequency: 0,
                            security: security ?? "",
                            strength: Math.min(100, (parseInt(starsStr) || 0) * 25),
                            active: ssid === connectedSsid
                        })
                    }
                }

                const rNetworks = root.wifiNetworks
                const toDestroy = rNetworks.filter(rn => !networkData.find(n => n.ssid === rn.ssid))
                for (const n of toDestroy)
                    rNetworks.splice(rNetworks.indexOf(n), 1).forEach(x => x.destroy())

                for (const network of networkData) {
                    const match = rNetworks.find(n => n.ssid === network.ssid)
                    if (match) match.lastIpcObject = network
                    else rNetworks.push(apComp.createObject(root, { lastIpcObject: network }))
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }
}
