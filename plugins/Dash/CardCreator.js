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

.pragma library

// %1 is the template["card-background"] string
// %2 is the template["card-background"]["elements"][0]
// %3 is the template["card-background"]["elements"][1]
var kBackgroundLoaderCode = 'Loader {\n\
                                id: backgroundLoader; \n\
                                objectName: "backgroundLoader"; \n\
                                anchors.fill: parent; \n\
                                asynchronous: root.asynchronous; \n\
                                visible: status == Loader.Ready; \n\
                                sourceComponent: UbuntuShape { \n\
                                    objectName: "background"; \n\
                                    radius: "medium"; \n\
                                    color: getColor(0) || "white"; \n\
                                    gradientColor: getColor(1) || color; \n\
                                    anchors.fill: parent; \n\
                                    image: backgroundImage.source ? backgroundImage : null; \n\
                                    property real luminance: Style.luminance(color); \n\
                                    property Image backgroundImage: Image { \n\
                                        objectName: "backgroundImage"; \n\
                                        source: { \n\
                                            if (cardData && typeof cardData["background"] === "string") return cardData["background"]; \n\
                                            else return "%1"; \n\
                                        } \n\
                                    } \n\
                                    function getColor(index) { \n\
                                        if (cardData && typeof cardData["background"] === "object" \n\
                                            && (cardData["background"]["type"] === "color" || cardData["background"]["type"] === "gradient")) { \n\
                                            return cardData["background"]["elements"][index]; \n\
                                        } else return index === 0 ? %2 : %3; \n\
                                    } \n\
                                } \n\
                            }\n';

// %1 is used as anchors of artShapeHolder
// %2 is used as image width
// %3 is used as image height
var kArtShapeHolderCode = 'Item  { \n\
                            id: artShapeHolder; \n\
                            height: root.fixedArtShapeSize.height > 0 ? root.fixedArtShapeSize.height : artShapeLoader.height; \n\
                            width: root.fixedArtShapeSize.width > 0 ? root.fixedArtShapeSize.width : artShapeLoader.width; \n\
                            anchors { %1 } \n\
                            Loader { \n\
                                id: artShapeLoader; \n\
                                objectName: "artShapeLoader"; \n\
                                active: cardData && cardData["art"] || false; \n\
                                asynchronous: root.asynchronous; \n\
                                visible: status == Loader.Ready; \n\
                                sourceComponent: Item { \n\
                                    id: artShape; \n\
                                    objectName: "artShape"; \n\
                                    property bool doShapeItem: components["art"]["conciergeMode"] !== true; \n\
                                    visible: image.status == Image.Ready; \n\
                                    readonly property alias image: artImage; \n\
                                    property alias borderSource: artShapeShape.borderSource; \n\
                                    ShaderEffectSource { \n\
                                        id: artShapeSource; \n\
                                        sourceItem: artImage; \n\
                                        anchors.centerIn: parent; \n\
                                        width: 1; \n\
                                        height: 1; \n\
                                        hideSource: doShapeItem; \n\
                                    } \n\
                                    Shape { \n\
                                        id: artShapeShape; \n\
                                        image: artShapeSource; \n\
                                        anchors.fill: parent; \n\
                                        visible: doShapeItem; \n\
                                        radius: "medium"; \n\
                                    } \n\
                                    readonly property real fixedArtShapeSizeAspect: (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) ? root.fixedArtShapeSize.width / root.fixedArtShapeSize.height : -1; \n\
                                    readonly property real aspect: fixedArtShapeSizeAspect > 0 ? fixedArtShapeSizeAspect : components !== undefined ? components["art"]["aspect-ratio"] : 1; \n\
                                    Component.onCompleted: { updateWidthHeightBindings(); if (artShapeBorderSource !== undefined) borderSource = artShapeBorderSource; } \n\
                                    Connections { target: root; onFixedArtShapeSizeChanged: updateWidthHeightBindings(); } \n\
                                    function updateWidthHeightBindings() { \n\
                                        if (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) { \n\
                                            width = root.fixedArtShapeSize.width; \n\
                                            height = root.fixedArtShapeSize.height; \n\
                                        } else { \n\
                                            width = Qt.binding(function() { return image.status !== Image.Ready ? 0 : image.width }); \n\
                                            height = Qt.binding(function() { return image.status !== Image.Ready ? 0 : image.height }); \n\
                                        } \n\
                                    } \n\
                                    CroppedImageMinimumSourceSize { \n\
                                        id: artImage; \n\
                                        objectName: "artImage"; \n\
                                        source: cardData && cardData["art"] || ""; \n\
                                        asynchronous: root.asynchronous; \n\
                                        width: %2; \n\
                                        height: %3; \n\
                                    } \n\
                                } \n\
                            } \n\
                        }\n';

var kOverlayLoaderCode = 'Loader { \n\
                            id: overlayLoader; \n\
                            anchors { \n\
                                left: artShapeHolder.left; \n\
                                right: artShapeHolder.right; \n\
                                bottom: artShapeHolder.bottom; \n\
                            } \n\
                            active: artShapeLoader.active && artShapeLoader.item && artShapeLoader.item.image.status === Image.Ready || false; \n\
                            asynchronous: root.asynchronous; \n\
                            visible: showHeader && status == Loader.Ready; \n\
                            sourceComponent: ShaderEffect { \n\
                                id: overlay; \n\
                                height: (fixedHeaderHeight > 0 ? fixedHeaderHeight : headerHeight) + units.gu(2); \n\
                                property real luminance: Style.luminance(overlayColor); \n\
                                property color overlayColor: cardData && cardData["overlayColor"] || "#99000000"; \n\
                                property var source: ShaderEffectSource { \n\
                                    id: shaderSource; \n\
                                    sourceItem: artShapeLoader.item; \n\
                                    onVisibleChanged: if (visible) scheduleUpdate(); \n\
                                    live: false; \n\
                                    sourceRect: Qt.rect(0, artShapeLoader.height - overlay.height, artShapeLoader.width, overlay.height); \n\
                                } \n\
                                vertexShader: " \n\
                                    uniform highp mat4 qt_Matrix; \n\
                                    attribute highp vec4 qt_Vertex; \n\
                                    attribute highp vec2 qt_MultiTexCoord0; \n\
                                    varying highp vec2 coord; \n\
                                    void main() { \n\
                                        coord = qt_MultiTexCoord0; \n\
                                        gl_Position = qt_Matrix * qt_Vertex; \n\
                                    }"; \n\
                                fragmentShader: " \n\
                                    varying highp vec2 coord; \n\
                                    uniform sampler2D source; \n\
                                    uniform lowp float qt_Opacity; \n\
                                    uniform highp vec4 overlayColor; \n\
                                    void main() { \n\
                                        lowp vec4 tex = texture2D(source, coord); \n\
                                        gl_FragColor = vec4(overlayColor.r, overlayColor.g, overlayColor.b, 1) * qt_Opacity * overlayColor.a * tex.a; \n\
                                    }"; \n\
                            } \n\
                        }\n';

// multiple row version of HeaderRowCode
function kHeaderRowCodeGenerator() {
    var kHeaderRowCodeTemplate = 'Row { \n\
                        id: row; \n\
                        objectName: "outerRow"; \n\
                        property real margins: units.gu(1); \n\
                        spacing: margins; \n\
                        height: root.fixedHeaderHeight != -1 ? root.fixedHeaderHeight : implicitHeight; \n\
                        anchors { %1 } \n\
                        anchors.right: parent.right; \n\
                        anchors.margins: margins; \n\
                        anchors.rightMargin: 0; \n\
                        data: [ \n\
                                %2 \n\
                                ] \n\
                    }\n';
    var args = Array.prototype.slice.call(arguments);
    var code = kHeaderRowCodeTemplate.arg(args.shift()).arg(args.join(',\n'));
    return code;
}

// multiple item version of kHeaderContainerCode
function kHeaderContainerCodeGenerator() {
    var headerContainerCodeTemplate = 'Item { \n\
                            id: headerTitleContainer; \n\
                            anchors { %1 } \n\
                            width: parent.width - x; \n\
                            implicitHeight: %2; \n\
                            data: [ \n\
                                %3 \n\
                            ]\n\
                        }\n';
    var args = Array.prototype.slice.call(arguments);
    var code = headerContainerCodeTemplate.arg(args.shift()).arg(args.shift()).arg(args.join(',\n'));
    return code;
}

// %1 is used as anchors of mascotShapeLoader
var kMascotShapeLoaderCode = 'Loader { \n\
                                id: mascotShapeLoader; \n\
                                objectName: "mascotShapeLoader"; \n\
                                asynchronous: root.asynchronous; \n\
                                active: mascotImage.status === Image.Ready; \n\
                                visible: showHeader && active && status == Loader.Ready; \n\
                                width: units.gu(6); \n\
                                height: units.gu(5.625); \n\
                                sourceComponent: UbuntuShape { image: mascotImage } \n\
                                anchors { %1 } \n\
                            }\n';

// %1 is used as anchors of mascotImage
// %2 is used as visible of mascotImage
var kMascotImageCode = 'CroppedImageMinimumSourceSize { \n\
                            id: mascotImage; \n\
                            objectName: "mascotImage"; \n\
                            anchors { %1 } \n\
                            source: cardData && cardData["mascot"] || ""; \n\
                            width: units.gu(6); \n\
                            height: units.gu(5.625); \n\
                            horizontalAlignment: Image.AlignHCenter; \n\
                            verticalAlignment: Image.AlignVCenter; \n\
                            visible: %2; \n\
                        }\n';

// %1 is used as anchors of titleLabel
// %2 is used as color of titleLabel
// %3 is used as extra condition for visible of titleLabel
// %4 is used as title width
var kTitleLabelCode = 'Label { \n\
                        id: titleLabel; \n\
                        objectName: "titleLabel"; \n\
                        anchors { %1 } \n\
                        elide: Text.ElideRight; \n\
                        fontSize: "small"; \n\
                        wrapMode: Text.Wrap; \n\
                        maximumLineCount: 2; \n\
                        font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); \n\
                        color: %2; \n\
                        visible: showHeader %3; \n\
                        width: %4; \n\
                        text: root.title; \n\
                        font.weight: cardData && cardData["subtitle"] ? Font.DemiBold : Font.Normal; \n\
                        horizontalAlignment: root.titleAlignment; \n\
                    }\n';

// %1 is used as extra anchors of emblemIcon
// %2 is used as color of emblemIcon
// FIXME The width code is a
// Workaround for bug https://bugs.launchpad.net/ubuntu/+source/ubuntu-ui-toolkit/+bug/1421293
var kEmblemIconCode = 'Icon { \n\
                            id: emblemIcon; \n\
                            objectName: "emblemIcon"; \n\
                            anchors { \n\
                                bottom: titleLabel.baseline; \n\
                                right: parent.right; \n\
                                %1 \n\
                            } \n\
                            source: cardData && cardData["emblem"] || ""; \n\
                            color: %2; \n\
                            height: source != "" ? titleLabel.font.pixelSize : 0; \n\
                            width: implicitWidth > 0 && implicitHeight > 0 ? (implicitWidth / implicitHeight * height) : implicitWidth; \n\
                        }\n';

// %1 is used as anchors of touchdown effect
var kTouchdownCode = 'UbuntuShape { \n\
                        id: touchdown; \n\
                        objectName: "touchdown"; \n\
                        anchors { %1 } \n\
                        visible: root.pressed; \n\
                        radius: "medium"; \n\
                        borderSource: "radius_pressed.sci" \n\
                    }\n';

// %1 is used as anchors of subtitleLabel
// %2 is used as color of subtitleLabel
var kSubtitleLabelCode = 'Label { \n\
                            id: subtitleLabel; \n\
                            objectName: "subtitleLabel"; \n\
                            anchors { %1 } \n\
                            anchors.topMargin: units.dp(2); \n\
                            elide: Text.ElideRight; \n\
                            maximumLineCount: 1; \n\
                            fontSize: "x-small"; \n\
                            font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); \n\
                            color: %2; \n\
                            visible: titleLabel.visible && titleLabel.text; \n\
                            text: cardData && cardData["subtitle"] || ""; \n\
                            font.weight: Font.Light; \n\
                        }\n';

// %1 is used as anchors of attributesRow
// %2 is used as color of attributesRow
var kAttributesRowCode = 'CardAttributes { \n\
                            id: attributesRow; \n\
                            objectName: "attributesRow"; \n\
                            anchors { %1 } \n\
                            color: %2; \n\
                            fontScale: root.fontScale; \n\
                            model: cardData && cardData["attributes"]; \n\
                          }\n';

// %1 is used as top anchor of summary
// %2 is used as topMargin anchor of summary
// %3 is used as color of summary
var kSummaryLabelCode = 'Label { \n\
                            id: summary; \n\
                            objectName: "summaryLabel"; \n\
                            anchors { \n\
                                top: %1; \n\
                                left: parent.left; \n\
                                right: parent.right; \n\
                                margins: units.gu(1); \n\
                                topMargin: %2; \n\
                            } \n\
                            wrapMode: Text.Wrap; \n\
                            maximumLineCount: 5; \n\
                            elide: Text.ElideRight; \n\
                            text: cardData && cardData["summary"] || ""; \n\
                            height: text ? implicitHeight : 0; \n\
                            fontSize: "small"; \n\
                            color: %3; \n\
                        }\n';

function cardString(template, components) {
    var code;

    var templateInteractive = (template == null ? true : (template["non-interactive"] !== undefined ? !template["non-interactive"] : true)) ? "true" : "false";

    code = 'AbstractButton { \n\
                id: root; \n\
                property var components; \n\
                property var cardData; \n\
                property var artShapeBorderSource: undefined; \n\
                property real fontScale: 1.0; \n\
                property var scopeStyle: null; \n\
                property int titleAlignment: Text.AlignLeft; \n\
                property int fixedHeaderHeight: -1; \n\
                property size fixedArtShapeSize: Qt.size(-1, -1); \n\
                readonly property string title: cardData && cardData["title"] || ""; \n\
                property bool asynchronous: true; \n\
                property bool showHeader: true; \n\
                implicitWidth: childrenRect.width; \n\
                enabled: %1; \n\
                \n'.arg(templateInteractive);

    var hasArt = components["art"] && components["art"]["field"] || false;
    var hasSummary = components["summary"] || false;
    var artAndSummary = hasArt && hasSummary && components["art"]["conciergeMode"] !== true;
    var isHorizontal = template["card-layout"] === "horizontal";
    var hasBackground = (!isHorizontal && (template["card-background"] || components["background"] || artAndSummary)) ||
                        (hasSummary && (template["card-background"] || components["background"]));
    var hasTitle = components["title"] || false;
    var hasMascot = components["mascot"] || false;
    var hasEmblem = components["emblem"] && !(hasMascot && template["card-size"] === "small") || false;
    var headerAsOverlay = hasArt && template && template["overlay"] === true && (hasTitle || hasMascot);
    var hasSubtitle = hasTitle && components["subtitle"] || false;
    var hasHeaderRow = hasMascot && hasTitle;
    var hasAttributes = hasTitle && components["attributes"]["field"] || false;

    if (hasBackground) {
        var templateCardBackground = (template && typeof template["card-background"] === "string") ? template["card-background"] :  "";
        var backgroundElements0;
        var backgroundElements1;
        if (template && typeof template["card-background"] === "object" && (template["card-background"]["type"] === "color" || template["card-background"]["type"] === "gradient"))  {
            if (template["card-background"]["elements"][0] !== undefined) {
                backgroundElements0 = '"%1"'.arg(template["card-background"]["elements"][0]);
            }
            if (template["card-background"]["elements"][1] !== undefined) {
                backgroundElements1 = '"%1"'.arg(template["card-background"]["elements"][1]);
            }
        }
        code += kBackgroundLoaderCode.arg(templateCardBackground).arg(backgroundElements0).arg(backgroundElements1);
    }

    if (hasArt) {
        code += 'onArtShapeBorderSourceChanged: { if (artShapeBorderSource !== undefined && artShapeLoader.item) artShapeLoader.item.borderSource = artShapeBorderSource; } \n';
        code += 'readonly property size artShapeSize: artShapeLoader.item ? Qt.size(artShapeLoader.item.width, artShapeLoader.item.height) : Qt.size(-1, -1);\n';

        var widthCode, heightCode;
        var artAnchors;
        if (isHorizontal) {
            artAnchors = 'left: parent.left';
            if (hasMascot || hasTitle) {
                widthCode = 'height * artShape.aspect'
                heightCode = 'headerHeight + 2 * units.gu(1)';
            } else {
                // This side of the else is a bit silly, who wants an horizontal layout without mascot and title?
                // So we define a "random" height of the image height + 2 gu for the margins
                widthCode = 'height * artShape.aspect'
                heightCode = 'units.gu(7.625)';
            }
        } else {
            artAnchors = 'horizontalCenter: parent.horizontalCenter;';
            widthCode = 'root.width'
            heightCode = 'width / artShape.aspect';
        }

        code += kArtShapeHolderCode.arg(artAnchors).arg(widthCode).arg(heightCode);
        var fallback = components["art"] && components["art"]["fallback"] || "";
        if (fallback !== "") {
            code += 'Connections { target: artShapeLoader.item ? artShapeLoader.item.image : null; onStatusChanged: if (artShapeLoader.item.image.status === Image.Error) artShapeLoader.item.image.source = "%1"; } \n'.arg(fallback);
        }
    } else {
        code += 'readonly property size artShapeSize: Qt.size(-1, -1);\n'
    }

    if (headerAsOverlay) {
        code += kOverlayLoaderCode;
    }

    var headerVerticalAnchors;
    if (headerAsOverlay) {
        headerVerticalAnchors = 'bottom: artShapeHolder.bottom; \n\
                                 bottomMargin: units.gu(1);\n';
    } else {
        if (hasArt) {
            if (isHorizontal) {
                headerVerticalAnchors = 'top: artShapeHolder.top; \n\
                                         topMargin: units.gu(1);\n';
            } else {
                headerVerticalAnchors = 'top: artShapeHolder.bottom; \n\
                                         topMargin: units.gu(1);\n';
            }
        } else {
            headerVerticalAnchors = 'top: parent.top; \n\
                                     topMargin: units.gu(1);\n';
        }
    }
    var headerLeftAnchor;
    var headerLeftAnchorHasMargin = false;
    if (isHorizontal && hasArt) {
        headerLeftAnchor = 'left: artShapeHolder.right; \n\
                            leftMargin: units.gu(1);\n';
        headerLeftAnchorHasMargin = true;
    } else {
        headerLeftAnchor = 'left: parent.left;\n';
    }

    var touchdownOnArtShape = !hasBackground && hasArt && !hasMascot && !hasSummary;

    if (hasHeaderRow) {
        code += 'readonly property int headerHeight: row.height;\n'
    } else if (hasMascot) {
        code += 'readonly property int headerHeight: mascotImage.height;\n'
    } else if (hasAttributes) {
        if (hasTitle && hasSubtitle) {
            code += 'readonly property int headerHeight: titleLabel.height + subtitleLabel.height + subtitleLabel.anchors.topMargin + attributesRow.height + attributesRow.anchors.topMargin;\n'
        } else if (hasTitle) {
            code += 'readonly property int headerHeight: titleLabel.height + attributesRow.height + attributesRow.anchors.topMargin;\n'
        } else {
            code += 'readonly property int headerHeight: attributesRow.height;\n'
        }
    } else if (hasSubtitle) {
        code += 'readonly property int headerHeight: titleLabel.height + subtitleLabel.height + subtitleLabel.anchors.topMargin;\n'
    } else if (hasTitle) {
        code += 'readonly property int headerHeight: titleLabel.height;\n'
    } else {
        code += 'readonly property int headerHeight: 0;\n'
    }

    var mascotShapeCode = '';
    var mascotCode = '';
    if (hasMascot) {
        var useMascotShape = !hasBackground && !headerAsOverlay;
        var mascotAnchors = '';
        if (!hasHeaderRow) {
            mascotAnchors += headerLeftAnchor;
            mascotAnchors += headerVerticalAnchors;
            if (!headerLeftAnchorHasMargin) {
                mascotAnchors += 'leftMargin: units.gu(1);\n'
            }
        } else {
            mascotAnchors = 'verticalCenter: parent.verticalCenter;'
        }

        if (useMascotShape) {
            mascotShapeCode = kMascotShapeLoaderCode.arg(mascotAnchors);
        }

        var mascotImageVisible = useMascotShape ? 'false' : 'showHeader';
        mascotCode = kMascotImageCode.arg(mascotAnchors).arg(mascotImageVisible);
        var fallback = components["mascot"] && components["mascot"]["fallback"] || "";
        if (fallback !== "") {
            code += 'Connections { target: mascotImage; onStatusChanged: if (mascotImage.status === Image.Error) mascotImage.source = "%1"; } \n'.arg(fallback);
        }
    }

    var summaryColorWithBackground = 'backgroundLoader.active && backgroundLoader.item && root.scopeStyle ? root.scopeStyle.getTextColor(backgroundLoader.item.luminance) : (backgroundLoader.item && backgroundLoader.item.luminance > 0.7 ? Theme.palette.normal.baseText : "white")';

    var hasTitleContainer = hasTitle && (hasEmblem || (hasMascot && (hasSubtitle || hasAttributes)));
    var titleSubtitleCode = '';
    if (hasTitle) {
        var titleColor;
        if (headerAsOverlay) {
            titleColor = 'root.scopeStyle && overlayLoader.item ? root.scopeStyle.getTextColor(overlayLoader.item.luminance) : (overlayLoader.item && overlayLoader.item.luminance > 0.7 ? Theme.palette.normal.baseText : "white")';
        } else if (hasSummary) {
            titleColor = 'summary.color';
        } else if (hasBackground) {
            titleColor = summaryColorWithBackground;
        } else {
            titleColor = 'root.scopeStyle ? root.scopeStyle.foreground : Theme.palette.normal.baseText';
        }

        var titleAnchors;
        var subtitleAnchors;
        var attributesAnchors;
        var titleContainerAnchors;
        var titleRightAnchor;
        var titleWidth = "undefined";

        var extraRightAnchor = '';
        var extraLeftAnchor = '';
        if (!touchdownOnArtShape) {
            extraRightAnchor = 'rightMargin: units.gu(1); \n';
            extraLeftAnchor = 'leftMargin: units.gu(1); \n';
        } else if (headerAsOverlay && !hasEmblem) {
            extraRightAnchor = 'rightMargin: units.gu(1); \n';
        }

        if (hasMascot) {
            titleContainerAnchors = 'verticalCenter: parent.verticalCenter; ';
        } else {
            titleContainerAnchors = 'right: parent.right; ';
            titleContainerAnchors += headerLeftAnchor;
            titleContainerAnchors += headerVerticalAnchors;
            if (!headerLeftAnchorHasMargin) {
                titleContainerAnchors += extraLeftAnchor;
            }
        }
        if (hasEmblem) {
            titleRightAnchor = 'right: emblemIcon.left; \n\
                                rightMargin: emblemIcon.width > 0 ? units.gu(0.5) : 0; \n';
        } else {
            titleRightAnchor = 'right: parent.right; \n'
            titleRightAnchor += extraRightAnchor;
        }

        if (hasTitleContainer) {
            // Using headerTitleContainer
            titleAnchors = titleRightAnchor;
            titleAnchors += 'left: parent.left; \n\
                             top: parent.top;';
            subtitleAnchors = 'right: parent.right; \n\
                               left: parent.left; \n';
            subtitleAnchors += extraRightAnchor;
            if (hasSubtitle) {
                attributesAnchors = subtitleAnchors + 'top: subtitleLabel.bottom;\n';
                subtitleAnchors += 'top: titleLabel.bottom;\n';
            } else {
                attributesAnchors = subtitleAnchors + 'top: titleLabel.bottom;\n';
            }
        } else if (hasMascot) {
            // Using row without titleContainer
            titleAnchors = 'verticalCenter: parent.verticalCenter;\n';
            titleWidth = "parent.width - x";
        } else {
            if (headerAsOverlay) {
                // Using anchors to the overlay
                titleAnchors = titleRightAnchor;
                titleAnchors += 'left: parent.left; \n\
                                 leftMargin: units.gu(1); \n\
                                 top: overlayLoader.top; \n\
                                 topMargin: units.gu(1);\n';
            } else {
                // Using anchors to the mascot/parent
                titleAnchors = titleRightAnchor;
                titleAnchors += headerLeftAnchor;
                titleAnchors += headerVerticalAnchors;
                if (!headerLeftAnchorHasMargin) {
                    titleAnchors += extraLeftAnchor;
                }
            }
            subtitleAnchors = 'left: titleLabel.left; \n\
                               leftMargin: titleLabel.leftMargin; \n';
            subtitleAnchors += extraRightAnchor;
            if (hasEmblem) {
                // using container
                subtitleAnchors += 'right: parent.right; \n';
            } else {
                subtitleAnchors += 'right: titleLabel.right; \n';
            }

            if (hasSubtitle) {
                attributesAnchors = subtitleAnchors + 'top: subtitleLabel.bottom;\n';
                subtitleAnchors += 'top: titleLabel.bottom;\n';
            } else {
                attributesAnchors = subtitleAnchors + 'top: titleLabel.bottom;\n';
            }
        }

        // code for different elements
        var titleLabelVisibleExtra = (headerAsOverlay ? '&& overlayLoader.active': '');
        var titleCode = kTitleLabelCode.arg(titleAnchors).arg(titleColor).arg(titleLabelVisibleExtra).arg(titleWidth);
        var subtitleCode;
        var attributesCode;

        // code for the title container
        var containerCode = [];
        var containerHeight = 'titleLabel.height';
        containerCode.push(titleCode);
        if (hasSubtitle) {
            subtitleCode = kSubtitleLabelCode.arg(subtitleAnchors).arg(titleColor);
            containerCode.push(subtitleCode);
            containerHeight += ' + subtitleLabel.height';
        }
        if (hasEmblem) {
            containerCode.push(kEmblemIconCode.arg(extraRightAnchor).arg(titleColor));
        }
        if (hasAttributes) {
            attributesCode = kAttributesRowCode.arg(attributesAnchors).arg(titleColor);
            containerCode.push(attributesCode);
            containerHeight += ' + attributesRow.height';
        }

        if (hasTitleContainer) {
            // use container
            titleSubtitleCode = kHeaderContainerCodeGenerator(titleContainerAnchors, containerHeight, containerCode);
        } else {
            // no container
            titleSubtitleCode = titleCode;
            if (hasSubtitle) {
                titleSubtitleCode += subtitleCode;
            }
            if (hasAttributes) {
                titleSubtitleCode += attributesCode;
            }
        }
    }

    if (hasHeaderRow) {
        var rowCode = [mascotCode, titleSubtitleCode];
        if (mascotShapeCode != '') {
           rowCode.unshift(mascotShapeCode);
        }
        code += kHeaderRowCodeGenerator(headerVerticalAnchors + headerLeftAnchor, rowCode)
    } else {
        code += mascotShapeCode + mascotCode + titleSubtitleCode;
    }

    if (hasSummary) {
        var summaryTopAnchor;
        if (isHorizontal && hasArt) summaryTopAnchor = 'artShapeHolder.bottom';
        else if (headerAsOverlay && hasArt) summaryTopAnchor = 'artShapeHolder.bottom';
        else if (hasHeaderRow) summaryTopAnchor = 'row.bottom';
        else if (hasTitleContainer) summaryTopAnchor = 'headerTitleContainer.bottom';
        else if (hasMascot) summaryTopAnchor = 'mascotImage.bottom';
        else if (hasAttributes) summaryTopAnchor = 'attributesRow.bottom';
        else if (hasSubtitle) summaryTopAnchor = 'subtitleLabel.bottom';
        else if (hasTitle) summaryTopAnchor = 'titleLabel.bottom';
        else if (hasArt) summaryTopAnchor = 'artShapeHolder.bottom';
        else summaryTopAnchor = 'parent.top';

        var summaryColor;
        if (hasBackground) {
            summaryColor = summaryColorWithBackground;
        } else {
            summaryColor = 'root.scopeStyle ? root.scopeStyle.foreground : Theme.palette.normal.baseText';
        }

        var summaryTopMargin = (hasMascot || hasSubtitle || hasAttributes ? 'anchors.margins' : '0');

        code += kSummaryLabelCode.arg(summaryTopAnchor).arg(summaryTopMargin).arg(summaryColor);
    }

    var touchdownAnchors;
    if (hasBackground) {
        touchdownAnchors = 'fill: backgroundLoader';
    } else if (touchdownOnArtShape) {
        touchdownAnchors = 'fill: artShapeHolder';
    } else {
        touchdownAnchors = 'fill: root'
    }
    code += kTouchdownCode.arg(touchdownAnchors);

    var implicitHeight = 'implicitHeight: ';
    if (hasSummary) {
        implicitHeight += 'summary.y + summary.height + units.gu(1);\n';
    } else if (headerAsOverlay) {
        implicitHeight += 'artShapeHolder.height;\n';
    } else if (hasHeaderRow) {
        implicitHeight += 'row.y + row.height + units.gu(1);\n';
    } else if (hasMascot) {
        implicitHeight += 'mascotImage.y + mascotImage.height;\n';
    } else if (hasTitleContainer) {
        implicitHeight += 'headerTitleContainer.y + headerTitleContainer.height + units.gu(1);\n';
    } else if (hasAttributes) {
        implicitHeight += 'attributesRow.y + attributesRow.height + units.gu(1);\n';
    } else if (hasSubtitle) {
        implicitHeight += 'subtitleLabel.y + subtitleLabel.height + units.gu(1);\n';
    } else if (hasTitle) {
        implicitHeight += 'titleLabel.y + titleLabel.height + units.gu(1);\n';
    } else if (hasArt) {
        implicitHeight += 'artShapeHolder.height;\n';
    } else {
        implicitHeight = '';
    }

    // Close the AbstractButton
    code += implicitHeight + '}\n';

    return code;
}

function createCardComponent(parent, template, components) {
    var imports = 'import QtQuick 2.2; \n\
                   import Ubuntu.Components 1.1; \n\
                   import Ubuntu.Settings.Components 0.1; \n\
                   import Dash 0.1;\n\
                   import Utils 0.1;\n';
    var card = cardString(template, components);
    var code = imports + 'Component {\n' + card + '}\n';

    try {
        return Qt.createQmlObject(code, parent, "createCardComponent");
    } catch (e) {
        console.error("ERROR: Invalid component created.");
        console.error("Template:");
        console.error(JSON.stringify(template));
        console.error("Components:");
        console.error(JSON.stringify(components));
        console.error("Code:");
        console.error(code);
        throw e;
    }
}
