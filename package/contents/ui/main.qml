import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/codex_usage_stats.py").toString().replace("file://", "")
    property var stats: ({ ok: false, error: "Loading..." })

    preferredRepresentation: compactRepresentation
    toolTipMainText: "Codex Usage"
    toolTipSubText: stats.ok
        ? "24h: " + formatTokens(stats.tokens_24h) + " | Total: " + formatTokens(stats.total_tokens)
        : stats.error

    function formatTokens(value) {
        var n = Number(value || 0)
        if (n >= 1000000) {
            return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1) + "M"
        }
        if (n >= 1000) {
            return (n / 1000).toFixed(n >= 10000 ? 0 : 1) + "K"
        }
        return String(n)
    }

    function latestLimit(which) {
        if (!stats.latest_token_snapshot || !stats.latest_token_snapshot.rate_limits) {
            return null
        }
        return stats.latest_token_snapshot.rate_limits[which] || null
    }

    function formatPercent(value) {
        var n = Number(value || 0)
        return n.toFixed(n >= 10 ? 0 : 1) + "%"
    }

    function compactText() {
        var primary = latestLimit("primary")
        if (primary && primary.used_percent !== undefined) {
            return formatPercent(primary.used_percent)
        }
        return stats.ok ? formatTokens(stats.tokens_24h) : "Codex"
    }

    function updateStats(raw) {
        try {
            stats = JSON.parse(raw)
        } catch (e) {
            stats = { ok: false, error: "Could not parse usage output" }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: [root.scriptPath]
        interval: 60000

        onNewData: function(sourceName, data) {
            root.updateStats(data.stdout)
        }

        Component.onCompleted: connectSource(root.scriptPath)
    }

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 6
        implicitHeight: Kirigami.Units.gridUnit * 2

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "utilities-system-monitor"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            PlasmaComponents.Label {
                text: root.compactText()
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 16
        implicitHeight: Kirigami.Units.gridUnit * 11

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "utilities-system-monitor"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                PlasmaComponents.Label {
                    text: "Codex Usage"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            GridLayout {
                visible: root.stats.ok
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing
                Layout.fillWidth: true

                PlasmaComponents.Label { text: "24 hours"; opacity: 0.75 }
                PlasmaComponents.Label { text: root.formatTokens(root.stats.tokens_24h); font.bold: true; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "7 days"; opacity: 0.75 }
                PlasmaComponents.Label { text: root.formatTokens(root.stats.tokens_7d); font.bold: true; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "30 days"; opacity: 0.75 }
                PlasmaComponents.Label { text: root.formatTokens(root.stats.tokens_30d); font.bold: true; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "Total"; opacity: 0.75 }
                PlasmaComponents.Label { text: root.formatTokens(root.stats.total_tokens); font.bold: true; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "Sessions"; opacity: 0.75 }
                PlasmaComponents.Label { text: String(root.stats.sessions || 0); font.bold: true; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "Primary limit"; opacity: 0.75; visible: root.latestLimit("primary") !== null }
                PlasmaComponents.Label {
                    text: root.latestLimit("primary") ? root.formatPercent(root.latestLimit("primary").used_percent) : ""
                    font.bold: true
                    visible: root.latestLimit("primary") !== null
                    Layout.alignment: Qt.AlignRight
                }
                PlasmaComponents.Label { text: "Weekly limit"; opacity: 0.75; visible: root.latestLimit("secondary") !== null }
                PlasmaComponents.Label {
                    text: root.latestLimit("secondary") ? root.formatPercent(root.latestLimit("secondary").used_percent) : ""
                    font.bold: true
                    visible: root.latestLimit("secondary") !== null
                    Layout.alignment: Qt.AlignRight
                }
            }

            PlasmaComponents.Label {
                visible: root.stats.ok && root.stats.last_thread
                text: root.stats.last_thread ? root.stats.last_thread.title : ""
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                opacity: 0.8
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                visible: !root.stats.ok
                text: root.stats.error
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.Label {
                text: "Local SQLite only"
                opacity: 0.6
                Layout.fillWidth: true
            }
        }
    }
}
