/*
 * Copyright (C) 2013 Canonical, Ltd.
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
import QtTest 1.0
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT
import "../../../qml/Dash"
import "CardHelpers.js" as Helpers

Rectangle {
    id: root
    width: units.gu(80)
    height: units.gu(72)
    color: "#88FFFFFF"

    property string cardData: '
    {
      "art": "'+Qt.resolvedUrl("artwork/music-player-design.png").toString()+'",
      "mascot": "'+Qt.resolvedUrl("artwork/avatar.png").toString()+'",
      "emblem": "'+Qt.resolvedUrl("artwork/emblem.png").toString()+'",
      "title": "foo",
      "subtitle": "bar",
      "summary": "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "attributes": [{"value":"text1","icon":"image://theme/ok"},{"value":"text2","icon":"image://theme/cancel"}]
    }'

    property var cardsModel: [
        {
            "name": "Art, header, summary",
            "layout": { "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header, summary - small",
            "layout": { "template": { "card-size": "small" }, "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header, summary - large",
            "layout": { "template": { "card-size": "large" }, "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header, summary - wide",
            "layout": { "components": Helpers.update(JSON.parse(Helpers.fullMapping), { "art": { "aspect-ratio": 2 } }) }
        },
        {
            "name": "Art, title - tall",
            "layout": { "components": Helpers.update(JSON.parse(Helpers.fullMapping), { "art": { "aspect-ratio": 0.7 } }) }
        },
        {
            "name": "Art, header, summary, background - horizontal",
            "layout": { "template": { "card-layout": "horizontal", "card-background": { "type": "gradient", "elements": ["grey", "white"] } },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header",
            "layout": { "components": Helpers.update(JSON.parse(Helpers.fullMapping), { "summary": undefined }) }
        },
        {
            "name": "Art, summary",
            "layout": { "components": { "art": "art", "summary": "summary" } }
        },
        {
            "name": "Header title only",
            "layout": { "components": { "title": "title" } }
        },
        {
            "name": "Art, header, summary - overlaid",
            "layout": { "template": { "overlay": true },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header - grey background",
            "layout": { "template": { "card-background": { "type": "color", "elements": ["grey"] } },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header - gradient background",
            "layout": { "template": { "card-background": { "type": "gradient", "elements": ["grey", "white"] } },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, header - image background",
            "layout": { "template": { "card-background": Qt.resolvedUrl("artwork/checkers.png") },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
        {
            "name": "Art, title - overlaid",
            "layout": { "template": { "overlay": true },
                        "components": { "art": "art", "title": "title" } }
        },
        {
            "name": "Art, header, summary - horizontal",
            "layout": { "template": { "card-layout": "horizontal" },
                        "components": JSON.parse(Helpers.fullMapping) }
        },
    ]

    CardTool {
        id: cardTool
        template: Helpers.update(JSON.parse(Helpers.defaultLayout), Helpers.tryParse(layoutArea.text, layoutError))['template'];
        components: Helpers.update(JSON.parse(Helpers.defaultLayout), Helpers.tryParse(layoutArea.text, layoutError))['components'];
        viewWidth: units.gu(40)
    }

    readonly property var card: loader.item

    Loader {
        id: loader
        anchors { top: parent.top; left: parent.left; margins: units.gu(1) }

        sourceComponent: cardTool.cardComponent
        clip: true
        onLoaded: {
            item.components = Qt.binding(function() { return cardTool.components; });
            item.cardData = Qt.binding(function() { return Helpers.mapData(dataArea.text, cardTool.components, dataError); });
            item.width = Qt.binding(function() { return cardTool.cardWidth || item.implicitWidth; });
            item.height = Qt.binding(function() { return cardTool.cardHeight || item.implicitHeight; });
            item.fixedHeaderHeight = Qt.binding(function() { return cardTool.headerHeight; });
        }
    }

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right}
        width: units.gu(40)
        color: "lightgrey"

        Column {
            anchors { fill: parent; margins: units.gu(1) }
            spacing: units.gu(1)

            OptionSelector {
                id: selector
                model: cardsModel
                delegate: OptionSelectorDelegate { text: modelData.name }
                onSelectedIndexChanged: updateAreas()
                Component.onCompleted: updateAreas()

                function updateAreas() {
                    var element = cardsModel[selectedIndex];
                    if (element) {
                        layoutArea.text = JSON.stringify(element.layout, undefined, 2) || "{}";
                        // FIXME: don't overwrite data
                        var data = JSON.parse(root.cardData);
                        Helpers.update(data, element.data);
                        dataArea.text = JSON.stringify(data, undefined, 2) || "{}";
                    } else {
                        layoutArea.text = "";
                        dataArea.text = "";
                    }

                }
            }

            TextArea {
                id: layoutArea
                anchors { left: parent.left; right: parent.right }
                height: units.gu(25)
            }

            Label {
                id: layoutError
                anchors { left: parent.left; right: parent.right }
                height: units.gu(4)
                color: "orange"
            }

            TextArea {
                id: dataArea
                anchors { left: parent.left; right: parent.right }
                height: units.gu(25)
            }

            Label {
                id: dataError
                anchors { left: parent.left; right: parent.right }
                height: units.gu(4)
                color: "orange"
            }

            Rectangle {
                color: "red"
                anchors { left: parent.left; right: parent.right }
                height: units.gu(4)
                Label {
                    text: "Toggle Visible"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: loader.visible = !loader.visible
                }
            }
        }
    }

    UT.UnityTestCase {
        id: testCase
        name: "Card"

        when: windowShown

        property Item title: findChild(card, "titleLabel")
        property Item subtitle: findChild(card, "subtitleLabel")
        property var headerRow: findChild(card, "outerRow")
        property var art: findChild(card, "artShape")
        property Item artImage: findChild(card, "artImage")
        property Item summary: findChild(card, "summaryLabel")
        property Item background: findChild(card, "background")
        property Item backgroundLoader: findChild(card, "backgroundLoader")
        property Item backgroundImage: findChild(card, "backgroundImage")
        property Item mascotImage: findChild(card, "mascotImage");

        function init() {
            cardTool.components = Qt.binding(function() { return Helpers.update(JSON.parse(Helpers.defaultLayout), Helpers.tryParse(layoutArea.text, layoutError))['components']; });
            loader.visible = true;
        }

        function cleanup() {
            selector.selectedIndex = -1;
        }

        function test_card_binding_data() {
            return [
                { tag: "Art", object: "artImage", property: "source", value: Qt.resolvedUrl("artwork/music-player-design.png"), index: 0 },
                { tag: "Summary", object: "summary", property: "text", field: "summary", index: 0 },
                { tag: "Fit", object: "art", fill: Image.PreserveAspectFit, index: 4 },
                { tag: "Mascot", object: "mascotImage", property: "source", value: Qt.resolvedUrl("artwork/avatar.png"), index: 0 },
                { tag: "Title", object: "title", property: "text", value: "foo", index: 0 },
                { tag: "Subtitle", object: "subtitle", property: "text", value: "bar", index: 0 },
            ];
        }

        function test_card_binding(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            tryCompareFunction(function() { return testCase[data.object] !== null }, true);
            var object = testCase[data.object];

            if (data.hasOwnProperty('value')) {
                tryCompare(object, data.property, data.value);
            }

            if (data.hasOwnProperty('field')) {
                tryCompare(object, data.property, card.cardData[data.field]);
            }
        }

        function test_card_size_data() {
            return [
                { tag: "Medium", width: units.gu(18), index: 0 },
                { tag: "Small", width: units.gu(12), index: 1 },
                { tag: "Large", width: units.gu(38), index: 2 },
                { tag: "Wide", width: units.gu(18), index: 0 },
                { tag: "Horizontal", width: units.gu(38), index: 5 },
                // Make sure card ends with header when there's no summary
                { tag: "NoSummary", height: function() { var cardToolRow = findChild(cardTool, "outerRow");
                                                         return cardToolRow.y + cardToolRow.height + units.gu(1) }, index: 6 },
                { tag: "HorizontalNoSummary", height: function() { return headerRow.height + units.gu(2) }, card_layout: "horizontal", index: 6 },
            ]
        }

        function test_card_size(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            if (data.hasOwnProperty("card_layout")) {
                cardTool.template['card-layout'] = data.card_layout;
                cardTool.templateChanged();
            }

            if (data.hasOwnProperty("width")) {
                tryCompare(card, "width", data.width);
            }

            if (typeof data.height === "function") {
                tryCompareFunction(function() { return card.height === data.height() }, true);
            } else if (data.hasOwnProperty("height")) {
                tryCompare(card, "height", data.height);
            }
        }

        function test_art_size_data() {
            return [
                { tag: "Medium", width: units.gu(18), fill: Image.PreserveAspectCrop, index: 0 },
                { tag: "Small", width: units.gu(12), index: 1 },
                { tag: "Large", width: units.gu(38), index: 2 },
                { tag: "Wide", height: units.gu(19), size: "large", index: 3 },
                { tag: "Tall", height: units.gu(38) / 0.7, size: "large", width: units.gu(38), index: 4 },
                { tag: "VerticalWidth", width: function() { return headerRow.width + units.gu(1) }, index: 0 },
                { tag: "HorizontalHeight", height: function() { return headerRow.height + units.gu(1) * 2 }, index: 5 },
                { tag: "HorizontalWidth", width: function() { return headerRow.x - units.gu(1) }, index: 5 },
            ]
        }

        function test_art_size(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            if (data.hasOwnProperty("size")) {
                cardTool.template['card-size'] = data.size;
                cardTool.templateChanged();
            }

            if (data.hasOwnProperty("aspect")) {
                cardTool.components['art']['aspect-ratio'] = data.aspect;
                cardTool.componentsChanged();
            }

            waitForRendering(card);

            if (data.hasOwnProperty("width")) {
                if (typeof data.width === "function") {
                    tryCompareFunction(function() { return art.width === data.width() }, true);
                } else tryCompare(art, "width", data.width);
            }

            if (data.hasOwnProperty("height")) {
                if (typeof data.height === "function") {
                    tryCompareFunction(function() { return art.height === data.height() }, true);
                } else tryCompare(art, "height", data.height);
            }

            if (data.hasOwnProperty("fill")) {
                tryCompare(artImage, "fillMode", data.fill);
            }
        }

        function test_art_shape_fixed_size() {
            selector.selectedIndex = 6;
            waitForRendering(selector);
            card.fixedArtShapeSize = Qt.size( units.gu(8), units.gu(4) );
            waitForRendering(card);
            tryCompare(art, "width", units.gu(8));
            tryCompare(art, "height", units.gu(4));
            tryCompare(art, "fixedArtShapeSizeAspect", 2);
        }

        function test_art_layout_data() {
            return [
                { tag: "Vertical", left: function() { return units.gu(1); }, index: 0},
                { tag: "Horizontal", left: function() { return art.width + units.gu(1); }, index: 5 },
            ];
        }

        function test_art_layout(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            tryCompare(headerRow, "x", data.left());
        }

        function test_header_layout_data() {
            return [
                { tag: "Vertical", top: function() { return art.y + art.height + units.gu(1) },
                  left: function() { return art.x + units.gu(1) }, index: 0 },
                { tag: "Horizontal", top: function() { return art.y + units.gu(1) },
                  left: function() { return art.x + art.width + units.gu(1) }, index: 5 },
                { tag: "Overlay", top: function() { return art.y + art.height - headerRow.height - units.gu(1) },
                  left: function() { return art.x + units.gu(1) }, index: 9 },
            ]
        }

        function test_header_layout(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            tryCompareFunction(function() { return testCase.headerRow.y === data.top() }, true);
            tryCompareFunction(function() { return testCase.headerRow.x === data.left() }, true);
        }

        function test_summary_layout_data() {
            return [
                { tag: "With header", top: function() { return headerRow.y + headerRow.height + units.gu(1); }, index: 0 },
                { tag: "Without header", top: function() { return art.y + art.height }, index: 7 },
            ]
        }

        function test_summary_layout(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            tryCompareFunction(function() { return art.height > 0 && testCase.summary.y === data.top() }, true);
        }

        function test_art_visibility() {
            selector.selectedIndex = 8;
            waitForRendering(selector);
            waitForRendering(card);

            compare(testCase.artImage, null);
            compare(testCase.art, null);
        }

        function test_background_data() {
            return [
                { tag: "Art and summary", visible: true, color: "#ffffff", index: 0 },
                { tag: "No Summary", visible: false, index: 6 },
                { tag: "Horizontal", visible: true, color: "#808080", index: 5 },
                { tag: "Grey background", visible: true, color: "#808080", index: 10 },
                { tag: "Overriden Gradient background", visible: true, color: "#808080", gradientColor: "#ffffff",
                  background: {type: "color", elements: ["grey", "white"]}, index: 10 },
                { tag: "Overriden Image background", visible: true, image: Qt.resolvedUrl("artwork/checkers.png"),
                  background: Qt.resolvedUrl("artwork/checkers.png"), index: 10 },
                { tag: "Gradient background", visible: true, color: "#808080", gradientColor: "#ffffff", index: 11 },
                { tag: "Image background", visible: true, image: Qt.resolvedUrl("artwork/checkers.png"), index: 12 },
                { tag: "Horizontal no background", visible: false, index: 14 },
            ];
        }


        function test_background(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);

            if (data.hasOwnProperty("background")) {
                card.cardData["background"] = data.background;
                card.cardDataChanged();
            }

            waitForRendering(card);

            if (data.visible) {
                tryCompare(backgroundLoader, "active", true);
            } else {
                compare(backgroundLoader, null);
            }

            if (data.hasOwnProperty("color")) {
                tryCompare(background, "color", data.color);
            }

            if (data.hasOwnProperty("gradientColor")) {
                tryCompare(background, "gradientColor", data.gradientColor);
            }

            if (data.hasOwnProperty("image")) {
                tryCompare(backgroundImage, "source", data.image);
            }
        }

        function test_fallback() {
            selector.selectedIndex = 0;
            waitForRendering(card);

            card.cardData["art"] = "somethingbroken";
            card.cardDataChanged();
            waitForRendering(card);
            tryCompare(art, "visible", false);

            cardTool.components["art"]["fallback"] = Qt.resolvedUrl("artwork/emblem.png");
            cardTool.componentsChanged();
            card.cardData["art"] = "somethingbroken";
            card.cardDataChanged();
            waitForRendering(card);
            tryCompare(art, "visible", true);

            card.cardData["mascot"] = "somethingbroken2";
            card.cardDataChanged();
            compare(mascotImage.status, Image.Error);

            cardTool.components["mascot"] = {"fallback": Qt.resolvedUrl("artwork/emblem.png")};
            cardTool.componentsChanged();
            card.cardData["mascot"] = "somethingbroken2";
            card.cardDataChanged();
            waitForRendering(card);
            tryCompare(mascotImage, "status", Image.Ready);
        }

        function test_font_weights_data() {
            return [
                { tag: "Title only", index: 8, weight: Font.Normal },
                { tag: "Title, subtitle", index: 0, weight: Font.DemiBold },
            ]
        }

        function test_font_weights(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            tryCompare(testCase.title.font, "weight", data.weight);
        }

        function test_fontColor_data() {
            return [
                { tag: "#ffffff", dark: true },
                { tag: "#fdfdfd", dark: true },
                { tag: "#f9f9f9", dark: true },
                { tag: "#000000", dark: false },
                { tag: "#ef814c", dark: false },
                { tag: "#312f2c", dark: false },
                { tag: "#be332d", dark: false },
                { tag: "#52ace4", dark: false },
                { tag: "#3a5897", dark: false },
                { tag: "#1caeeb", dark: false },
                { tag: "#87c341", dark: false },
                { tag: "#50893b", dark: false },
            ];
        }

        function test_fontColor(data) {
            selector.selectedIndex = 10;
            waitForRendering(selector);
            waitForRendering(card);

            background.color = data.tag;

            var fontColor = data.dark ? Theme.palette.normal.baseText : "white";

            tryCompareFunction(function() { return Qt.colorEqual(summary.color, fontColor); }, true);
            tryCompareFunction(function() { return Qt.colorEqual(title.color, fontColor); }, true);
            tryCompareFunction(function() { return Qt.colorEqual(subtitle.color, fontColor); }, true);
        }

        function test_emblemIcon_data() {
            return [
                { tag: "Art and summary", emblem: true, index: 0 },
                { tag: "Art and summary, small", emblem: false, index: 1 },
                { tag: "No header", emblem: false, index: 7 },
                { tag: "With background", emblem: true, index: 10 },
            ];
        }

        function test_emblemIcon(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            var emblemIcon = findChild(card, "emblemIcon");
            compare(emblemIcon !== null, data.emblem);
        }

        function test_mascotShape_data() {
            return [
                { tag: "Art and summary", shape: false, index: 0 },
                { tag: "No Summary", shape: true, index: 6 },
                { tag: "With background", shape: false, index: 10 },
            ];
        }

        function test_mascotShape(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            var shape = findChild(card, "mascotShapeLoader");

            compare(shape !== null, data.shape);
            tryCompare(mascotImage, "visible", !data.shape);
        }

        function test_touchdown_visibility() {
            selector.selectedIndex = 0;
            waitForRendering(selector);
            waitForRendering(card);

            var touchdown = findChild(card, "touchdown");

            compare(touchdown.visible, false);
            mousePress(card);
            compare(touchdown.visible, true);
            mouseRelease(card);
            compare(touchdown.visible, false);
        }

        function test_paddings_data() {
            return [
                { tag: "Art and summary", index: 0 },
                { tag: "No Summary", index: 6 },
                { tag: "No header", index: 7 },
                { tag: "Header only", index: 8 },
                { tag: "Art, header, summary - overlaid", index: 9 },
                { tag: "Art, title - overlaid", index: 13 },
            ];
        }

        function test_paddings(data) {
            selector.selectedIndex = data.index;
            waitForRendering(selector);
            waitForRendering(card);

            if (title) var titleToCard = title.mapToItem(card, 0, 0, title.width, title.height);

            // left margin
            if (mascotImage) {
                var mascotToCard = mascotImage.mapToItem(card, 0, 0, mascotImage.width, mascotImage.height);
                verify(mascotToCard.x === units.gu(1));
                if (title) {
                    verify((titleToCard.x - mascotToCard.x - mascotToCard.width) === units.gu(1));
                }
            } else if (title) {
                verify(titleToCard.x === units.gu(1));
            }

            // right margin
            var emblemIcon = findChild(card, "emblemIcon");
            if (emblemIcon) {
                var emblemToCard = emblemIcon.mapToItem(card, 0, 0, emblemIcon.width, emblemIcon.height);
                verify((card.width - emblemToCard.x - emblemToCard.width) === units.gu(1));
            } else if (title) {
                verify((card.width - titleToCard.x - titleToCard.width) === units.gu(1));
            }
        }
    }
}
