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
import Dash 0.1

/*!
 \brief Tool for introspecting Card properties.

 Some properties of Cards we need to determine category-wide (like card sizes in grid),
 so we should not do them per-Card but in the category renderer.

 This component creates an invisible card filled with maximum mapped data and calculates
 or measures card properties for this configuration.
 */

Item {
    id: cardTool

    /*!
     \brief Number of cards.
     */
    property int count

    /*!
     \brief Width of the category view.
     */
    property real viewWidth

    /*!
     \brief Scaling factor of selected Carousel item.
     */
    readonly property real carouselSelectedItemScaleFactor: 1.38  // XXX assuming 1.38 carousel scaling factor for cards

    /*!
     \brief Template supplied for the category.
     */
    property var template

    /*!
     \brief Component mapping supplied for the category.
     */
    property var components

    /*!
     \brief The category layout for this card tool.
     */
    property string categoryLayout: {
        var layout = template["category-layout"];

        // carousel fallback mode to grid
        if (layout === "carousel" && count <= Math.ceil(carouselTool.realPathItemCount)) layout = "grid";
        return layout;
    }

    property var cardComponent: CardCreatorCache.getCardComponent(cardTool.template, cardTool.components);

    // FIXME: Saviq
    // Only way for the card below to actually be laid out completely.
    // If invisible or in "data" array, some components are not taken into account.
    width: 0
    height: 0
    clip: true

    /*!
     type:real \brief Width to be enforced on the card in this configuration.

     If undefined, should use implicit width of the actual card.
     */
    property var cardWidth: {
        switch (categoryLayout) {
            case "grid":
            case "vertical-journal":
                var size = template["card-size"];
                if (template["card-layout"] === "horizontal") size = "large";
                switch (size) {
                    case "small": {
                        if (viewWidth <= units.gu(45)) return units.gu(12);
                        else return units.gu(14);
                    }
                    case "large": {
                        if (viewWidth >= units.gu(70)) return units.gu(42);
                        else return viewWidth - units.gu(2);
                    }
                }
                if (viewWidth <= units.gu(45)) return units.gu(18);
                else if (viewWidth >= units.gu(70)) return units.gu(20);
                else return units.gu(23);
            case "carousel":
            case "horizontal-list":
                return carouselTool.minimumTileWidth;
            case undefined:
            case "organic-grid":
            case "journal":
            default:
                return undefined;
        }
    }

    /*!
     type:real \brief Height to be enforced on the card in this configuration.

     If undefined, should use implicit height of the actual card.
     */
    readonly property var cardHeight: {
        switch (categoryLayout) {
            case "journal":
                if (template["card-size"] >= 12 && template["card-size"] <= 38) return units.gu(template["card-size"]);
                return units.gu(18.5);
            case "grid":
            case "horizontal-list":
                return cardLoader.item ? cardLoader.item.implicitHeight : 0
            case "carousel":
                return cardWidth / (components ? components["art"]["aspect-ratio"] : 1)
            case undefined:
            case "organic-grid":
            case "vertical-journal":
            default:
                return undefined;
        }
    }

    /*!
     type:real \brief Height of the card's header.
    */
    readonly property int headerHeight: cardLoader.item ? cardLoader.item.headerHeight : 0
    property size artShapeSize: cardLoader.item ? cardLoader.item.artShapeSize : 0

    /*!
     \brief Desired alignment of title
     */
    readonly property int titleAlignment: {
        if (template["card-layout"] === "horizontal"
            || typeof components["title"] !== "object"
            || components["title"]["align"] === "left") return Text.AlignLeft;

        var keys = ["mascot", "emblem", "subtitle", "attributes", "summary"];

        for (var key in keys) {
            key = keys[key];
            try {
                if (typeof components[key] === "string"
                    || typeof components[key]["field"] === "string") return Text.AlignLeft;
            } catch (e) {
                continue;
            }
        }

        return Text.AlignHCenter;
    }

    QtObject {
        id: carouselTool

        property real minimumTileWidth: {
            if (cardTool.viewWidth === undefined) return undefined;
            if (cardTool.viewWidth <= units.gu(40)) return units.gu(18);
            if (cardTool.viewWidth >= units.gu(128)) return units.gu(26);
            return units.gu(18 + Math.round((cardTool.viewWidth - units.gu(40)) / units.gu(11)));
        }

        readonly property real pathItemCount: 4.8457 /// (848 / 175) reference values

        property real realPathItemCount: {
            var scaledMinimumTileWidth = minimumTileWidth / cardTool.carouselSelectedItemScaleFactor;
            var tileWidth = Math.max(cardTool.viewWidth / pathItemCount, scaledMinimumTileWidth);
            return Math.min(cardTool.viewWidth / tileWidth, pathItemCount);
        }
    }

    Item {
        id: attributesModel
        property int numOfAttributes: 0
        property var model: []
        property bool hasAttributes: {
            var attributes = components["attributes"];
            var hasAttributesFlag = (attributes != undefined) && (attributes["field"] != undefined);

            if (hasAttributesFlag) {
                if (attributes["max-count"]) {
                    numOfAttributes = attributes["max-count"];
                }
            }
            return hasAttributesFlag
        }

        onNumOfAttributesChanged: {
            model = []
            for (var i = 0; i < numOfAttributes; i++) {
                model.push( {"value":"text"+(i+1), "icon":"image://theme/ok" } );
            }
        }
    }

    Loader {
        id: cardLoader
        readonly property var fields: ["art", "mascot", "title", "subtitle", "summary", "attributes"]
        readonly property var maxData: {
            "art": Qt.resolvedUrl("graphics/pixel.png"),
            "mascot": Qt.resolvedUrl("graphics/pixel.png"),
            "title": "—\n—",
            "subtitle": "—",
            "summary": "—\n—\n—\n—\n—",
            "attributes": attributesModel.model
        }
        sourceComponent: cardTool.cardComponent
        onLoaded: {
            item.objectName = "cardToolCard";
            item.asynchronous = false;
            item.components = Qt.binding(function() { return cardTool.components; });
            item.width = Qt.binding(function() { return cardTool.cardWidth || item.implicitWidth; });
            item.height = Qt.binding(function() { return cardTool.cardHeight || item.implicitHeight; });
        }
        Connections {
            target: cardTool
            onTemplateChanged: cardLoader.updateCardData();
            onComponentsChanged: cardLoader.updateCardData();
        }
        function updateCardData() {
            var data = {};
            for (var k in fields) {
                var component = cardTool.components[fields[k]];
                var key = fields[k];
                if ((typeof component === "string" && component.length > 0) ||
                    (typeof component === "object" && component !== null
                    && typeof component["field"] === "string" && component["field"].length > 0)) {
                    data[key] = maxData[key];
                }
            }
            item.cardData = data;
        }
    }
}
