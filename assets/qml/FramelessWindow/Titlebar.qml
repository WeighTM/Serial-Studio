/*
 * Copyright (c) 2020-2021 Alex Spataru <https://github.com/alex-spataru>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12

import "../Widgets" as Widgets

Rectangle {   
    id: root

    //
    // Custom signals
    //
    signal closed()
    signal minimized()
    signal maximized()
    signal unmaximized()

    //
    // Window controls
    //
    property Window window
    property bool showIcon: false
    property bool closeEnabled: true
    property bool isFullscreen: false
    property bool minimizeEnabled: true
    property bool maximizeEnabled: true
    property bool fullscreenEnabled: false
    property color textColor: palette.text
    property bool showMacControls: Cpp_IsMac

    //
    // Access to left titlebar button widths (e.g. for implementing custom controls over
    // the window titlebar, such as the main window menubar)
    //
    readonly property real leftMargin: {
        var margin = 0

        // Calculations for macOS layout
        if (showMacControls) {
            // Default spacer
            margin = 4

            // Add space for close button
            if (closeEnabled)
                margin += 20

            // Add space for minimize button
            if (minimizeEnabled && !root.isFullscreen)
                margin += 20

            // Add space for maximize button
            if (maximizeEnabled && !root.isFullscreen)
                margin += 20

            // Add extra spacer if at least one button is visible
            if (margin > 4)
                margin += 4
        }

        // Calculations for Windows/Linux layout
        else {
            margin = 10

            if (root.showIcon)
                margin += 24

            if (margin > 10)
                margin += 8
        }

        // Return result
        return margin
    }

    //
    // Access to right titlebar button widths (e.g. for implementing custom controls over
    // the window titlebar, such as the main window menubar)
    //
    readonly property real rightMargin: {
        var margin

        // Calculations for macOS layout
        if (showMacControls) {
            // Add default spacer
            margin = 4

            // Add spacer for full-screen button
            if (fullscreenEnabled)
                margin += 18

            // Add extra spacer if FS button is displayed
            if (margin > 4)
                margin += 4
        }

        // Calculations for Windows/Linux layout
        else {
            // Default spacer
            margin = 8

            // Add space for close button
            if (closeEnabled)
                margin += 24

            // Add space for minimize button
            if (minimizeEnabled && !root.isFullscreen)
                margin += 24

            // Add space for maximize button
            if (maximizeEnabled && !root.isFullscreen)
                margin += 24

            // Add extra spacer if at least one button is visible
            if (margin > 8)
                margin += 8
        }

        // Return result
        return margin
    }

    //
    // Toggle maximized
    //
    function toggleMaximized() {
        if (window.visibility === Window.Maximized) {
            window.showNormal()
            root.unmaximized()
        }

        else {
            window.showMaximized()
            root.maximized()
        }
    }

    //
    // Toggle fullscreen state
    //
    function toggleFullscreen() {
        root.isFullscreen = !root.isFullscreen
        if (root.isFullscreen)
            window.showFullScreen()
        else
            window.showNormal()
    }

    //
    // Height calculation
    //
    height: !showMacControls ? 38 : 32

    //
    // Radius compensator rectangle
    //
    Rectangle {
        color: parent.color
        height: parent.radius
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }

    //
    // Window drag handler
    //
    Item {
        anchors.fill: parent

        DragHandler {
            grabPermissions: TapHandler.CanTakeOverFromAnything
            onActiveChanged: {
                if (active)
                    window.startSystemMove()
            }
        }
    }

    //
    // Window maximize by double click
    //
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: {
            if (root.maximizeEnabled)
                root.toggleMaximized()
        }
    }

    //
    // macOS layout
    //
    Item {
        anchors.fill: parent
        visible: showMacControls
        enabled: showMacControls

        RowLayout {
            spacing: 0
            anchors.fill: parent

            Item {
                width: 4
            }

            WindowButtonMacOS {
                name: "close"
                enabled: root.closeEnabled
                visible: root.closeEnabled
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    window.close()
                    root.closed()
                }

            }

            WindowButtonMacOS {
                name: "minimize"
                Layout.alignment: Qt.AlignVCenter
                enabled: root.minimizeEnabled && !root.isFullscreen
                visible: root.minimizeEnabled && !root.isFullscreen
                onClicked: {
                    // Workaround for QTBUG-64994
                    if (Cpp_IsMac)
                        window.flags = Qt.Window | Qt.CustomizeWindowHint | Qt.WindowMinMaxButtonsHint

                    window.showMinimized()
                    root.minimized()
                }
            }

            WindowButtonMacOS {
                name: "maximize"
                onClicked: root.toggleMaximized()
                Layout.alignment: Qt.AlignVCenter
                enabled: root.maximizeEnabled && !root.isFullscreen
                visible: root.maximizeEnabled && !root.isFullscreen
            }

            Item {
                Layout.fillWidth: true
            }

            WindowButton {
                width: 16
                height: 16
                textColor: root.textColor
                visible: root.fullscreenEnabled
                enabled: root.fullscreenEnabled
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.toggleFullscreen()
                highlightColor: Cpp_ThemeManager.highlight
                name: root.isFullscreen ? "restore" : "fullscreen"
            }

            Item {
                width: 10
            }
        }
    }

    //
    // Windows & Linux layout
    //
    Item {
        anchors.fill: parent
        visible: !showMacControls
        enabled: !showMacControls

        RowLayout {
            spacing: 0
            anchors.fill: parent

            Item {
                width: 12
            }

            WindowButton {
                visible: root.showIcon
                enabled: root.showIcon
                textColor: root.textColor
                highlightColor: root.textColor
                Layout.alignment: Qt.AlignVCenter
                source: "qrc:/images/icon-window.svg"
            }

            Item {
                Layout.fillWidth: true
            }

            WindowButton {
                name: "minimize"
                textColor: root.textColor
                Layout.alignment: Qt.AlignVCenter
                highlightColor: Cpp_ThemeManager.highlight
                enabled: root.minimizeEnabled && !root.isFullscreen
                visible: root.minimizeEnabled && !root.isFullscreen
                onClicked: {
                    // Workaround for QTBUG-64994
                    if (Cpp_IsMac)
                        window.flags = Qt.Window | Qt.CustomizeWindowHint | Qt.WindowMinMaxButtonsHint

                    window.showMinimized()
                    root.minimized()
                }
            }

            WindowButton {
                textColor: root.textColor
                onClicked: root.toggleMaximized()
                Layout.alignment: Qt.AlignVCenter
                highlightColor: Cpp_ThemeManager.highlight
                enabled: root.maximizeEnabled && !root.isFullscreen
                visible: root.maximizeEnabled && !root.isFullscreen
                name: window.visibility === Window.Maximized ? "unmaximize" : "maximize"
            }

            WindowButton {
                name: "close"
                highlightColor: "#f00"
                textColor: root.textColor
                enabled: root.closeEnabled
                visible: root.closeEnabled
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    window.close()
                    root.closed()
                }
            }

            Item {
                width: 8
            }
        }
    }

    Label {
        font.bold: true
        font.pixelSize: 14
        text: window.title
        color: root.textColor
        anchors.centerIn: parent
    }
}
