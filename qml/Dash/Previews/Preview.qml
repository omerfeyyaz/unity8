/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1

/*! \brief This component constructs the Preview UI.
 *
 *  Currently it displays all the widgets in a flickable column.
 */

Item {
    id: root

    /*! \brief Model containing preview widgets.
     *
     *  The model should expose "widgetId", "type" and "properties" roles, as well as
     *  have a triggered(QString widgetId, QString actionId, QVariantMap data) method,
     *  that's called when actions are executed in widgets.
     */
    property var previewModel

    //! \brief Should be set to true if this preview is currently displayed.
    property bool isCurrent: false

    //! \brief The ScopeStyle component.
    property var scopeStyle: null

    clip: true

    Binding {
        target: previewModel
        property: "widgetColumnCount"
        value: row.columns
    }

    MouseArea {
        anchors.fill: parent
    }

    Row {
        id: row

        spacing: units.gu(1)
        anchors { fill: parent; margins: spacing }

        property int columns: width >= units.gu(80) ? 2 : 1
        property real columnWidth: width / columns

        Repeater {
            model: previewModel

            delegate: ListView {
                id: column
                objectName: "previewListRow" + index
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                width: row.columnWidth
                spacing: row.spacing
                bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
                property var makeSureVisibleItem
                property real previousVisibleHeight: 0
                property real visibleHeight: height - bottomMargin
                onVisibleHeightChanged: {
                    if (makeSureVisibleItem && makeSureVisibleItem.activeFocus && previousVisibleHeight > visibleHeight) {
                        var textAreaPos = makeSureVisibleItem.mapToItem(column, 0, 0);
                        if (textAreaPos.y + makeSureVisibleItem.height > column.visibleHeight) {
                            column.contentY += textAreaPos.y + makeSureVisibleItem.height - column.visibleHeight
                        }
                    }
                    previousVisibleHeight = visibleHeight;
                }

                model: columnModel
                cacheBuffer: height

                Behavior on contentY { UbuntuNumberAnimation { } }

                delegate: PreviewWidgetFactory {
                    widgetId: model.widgetId
                    widgetType: model.type
                    widgetData: model.properties
                    isCurrentPreview: root.isCurrent
                    scopeStyle: root.scopeStyle
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: units.gu(1)
                        rightMargin: units.gu(1)
                    }

                    onTriggered: {
                        previewModel.triggered(widgetId, actionId, data);
                    }
                     onMakeSureVisible: {
                         column.previousVisibleHeight=column.visibleHeight
                         column.makeSureVisibleItem=item
                     }

                    onFocusChanged: if (focus) column.positionViewAtIndex(index, ListView.Contain)

                    onHeightChanged: if (focus) column.positionViewAtIndex(index, ListView.Contain)
                }
            }
        }
    }
}
