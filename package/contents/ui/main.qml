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

    function usageLimit(group, which) {
        if (!stats.usage_limits || !stats.usage_limits[group] || !stats.usage_limits[group].rate_limits) {
            return null
        }
        return stats.usage_limits[group].rate_limits[which] || null
    }

    function formatPercent(value) {
        var n = Number(value || 0)
        return n.toFixed(n >= 10 ? 0 : 1) + "%"
    }

    function formatLimit(group, which) {
        var limit = usageLimit(group, which)
        if (!limit || limit.used_percent === undefined) {
            return "No local data"
        }
        return formatPercent(limit.used_percent)
    }

    function formatReset(group, which) {
        var limit = usageLimit(group, which)
        if (!limit || !limit.resets_at) {
            return ""
        }
        return "Resets " + Qt.formatDateTime(new Date(limit.resets_at * 1000), "ddd HH:mm")
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
        id: compactRoot

        readonly property int iconSize: Kirigami.Units.iconSizes.smallMedium

        clip: true
        implicitWidth: iconSize + Kirigami.Units.smallSpacing + compactLabel.implicitWidth
        implicitHeight: Math.max(iconSize, compactLabel.implicitHeight)

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: compactIcon

                source: "utilities-system-monitor"
                Layout.preferredWidth: compactRoot.iconSize
                Layout.preferredHeight: compactRoot.iconSize
            }

            PlasmaComponents.Label {
                id: compactLabel

                text: root.compactText()
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.max(0, compactRoot.width - compactIcon.width - parent.spacing)
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: Kirigami.Units.gridUnit * 14

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
            }

            PlasmaComponents.Label {
                visible: root.stats.ok
                text: "Usage limits"
                font.bold: true
                Layout.fillWidth: true
            }

            GridLayout {
                visible: root.stats.ok
                columns: 3
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing
                Layout.fillWidth: true

                PlasmaComponents.Label { text: ""; opacity: 0.75 }
                PlasmaComponents.Label { text: "5h"; opacity: 0.75; Layout.alignment: Qt.AlignRight }
                PlasmaComponents.Label { text: "Weekly"; opacity: 0.75; Layout.alignment: Qt.AlignRight }

                PlasmaComponents.Label { text: "Regular"; font.bold: true }
                PlasmaComponents.Label {
                    text: root.formatLimit("regular", "primary")
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }
                PlasmaComponents.Label {
                    text: root.formatLimit("regular", "secondary")
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }

                PlasmaComponents.Label { text: "5.3 Spark"; font.bold: true }
                PlasmaComponents.Label {
                    text: root.formatLimit("spark", "primary")
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }
                PlasmaComponents.Label {
                    text: root.formatLimit("spark", "secondary")
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: "Regular reset"
                    opacity: 0.65
                }
                PlasmaComponents.Label {
                    text: root.formatReset("regular", "primary")
                    opacity: 0.65
                    Layout.alignment: Qt.AlignRight
                }
                PlasmaComponents.Label {
                    text: root.formatReset("regular", "secondary")
                    opacity: 0.65
                    Layout.alignment: Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: "Spark reset"
                    opacity: 0.65
                }
                PlasmaComponents.Label {
                    text: root.formatReset("spark", "primary")
                    opacity: 0.65
                    Layout.alignment: Qt.AlignRight
                }
                PlasmaComponents.Label {
                    text: root.formatReset("spark", "secondary")
                    opacity: 0.65
                    Layout.alignment: Qt.AlignRight
                }
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
