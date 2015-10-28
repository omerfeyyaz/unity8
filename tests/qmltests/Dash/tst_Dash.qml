/*
 * Copyright 2013 Canonical Ltd.
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
import "../../../qml/Dash"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

Item {
    id: shell
    width: units.gu(40)
    height: units.gu(80)

    // BEGIN To reduce warnings
    // TODO I think it we should pass down these variables
    // as needed instead of hoping they will be globally around
    property var greeter: null
    property var panel: null
    // BEGIN To reduce warnings


    Dash {
        id: dash
        anchors.fill: parent
    }

    SignalSpy {
        id: spy
    }

    UT.UnityTestCase {
        name: "Dash"
        when: windowShown

        readonly property Item dashContent: findChild(dash, "dashContent");
        readonly property var scopes: dashContent.scopes

        function init() {
            // clear and reload the scopes.
            scopes.clear();
            var dashContentList = findChild(dash, "dashContentList");
            verify(dashContentList != undefined);
            tryCompare(dashContentList, "count", 0);
            scopes.load();
            tryCompare(dashContentList, "currentIndex", 0);
            tryCompare(dashContentList, "count", 6);
            tryCompare(scopes, "loaded", true);
            tryCompareFunction(function() {
                var mockScope1Loader = findChild(dash, "scopeLoader0");
                return mockScope1Loader && mockScope1Loader.item != null; },
                true, 15000);
            tryCompareFunction(function() {
                var mockScope1Loader = findChild(dash, "scopeLoader0");
                return mockScope1Loader && mockScope1Loader.status === Loader.Ready; },
                true, 15000);
            waitForRendering(findChild(dash, "scopeLoader0").item);
        }

        function test_manage_dash_clickscope_unfavoritable() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var favScopesListCategory = findChild(dash, "scopesListCategoryfavorites");
            var favScopesListCategoryList = findChild(favScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(favScopesListCategoryList, "currentIndex", 0);

            // Click scope star area is not visible (i.e. can't be unfavorited)
            var clickScope = findChild(favScopesListCategoryList, "delegateclickscope");
            var starArea = findChild(clickScope, "starArea");
            compare(starArea.visible, false);

            // Go back
            var scopesList = findChild(dash, "scopesList");
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var backButton = findChild(findChild(scopesListPageHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);
            tryCompare(bottomEdgeController, "progress", 0);
        }

        function test_manage_dash_select_same_favorite() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var favScopesListCategory = findChild(dash, "scopesListCategoryfavorites");
            var favScopesListCategoryList = findChild(favScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(favScopesListCategoryList, "currentIndex", 0);

            // Click in first item
            mouseClick(favScopesListCategoryList.currentItem);

            // Make sure animation went back
            tryCompare(bottomEdgeController, "progress", 0);

            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
        }

        function test_manage_dash_select_different_favorite() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var favScopesListCategory = findChild(dash, "scopesListCategoryfavorites");
            var favScopesListCategoryList = findChild(favScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(favScopesListCategoryList, "currentIndex", 0);

            // Click in second item
            favScopesListCategoryList.currentIndex = 1;
            mouseClick(favScopesListCategoryList.currentItem);

            // Make sure animation went back
            tryCompare(bottomEdgeController, "progress", 0);
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 1);
        }

        function test_manage_dash_select_non_favorite() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var nonfavScopesListCategory = findChild(dash, "scopesListCategoryother");
            var nonfavScopesListCategoryList = findChild(nonfavScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(nonfavScopesListCategoryList, "currentIndex", 0);

            // Click on a non favorite scope
            mouseClick(nonfavScopesListCategoryList.currentItem);

            // Check the bottom edge (manage dash) is disabled from temp scope
            var overviewDragHandle = findChild(dash, "overviewDragHandle");
            compare(overviewDragHandle.enabled, false);

            // Check temp scope is there
            var dashTempScopeItem = findChild(dash, "dashTempScopeItem");
            tryCompare(dashTempScopeItem, "x", 0);
            tryCompare(dashTempScopeItem, "visible", true);

            // Check the manage dash is gone
            tryCompare(bottomEdgeController, "progress", 0);

            // Go back
            var dashTempScopeItemHeader = findChild(dashTempScopeItem, "scopePageHeader");
            var backButton = findChild(findChild(dashTempScopeItemHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);

            // Check temp scope is gone
            tryCompare(dashTempScopeItem, "x", dash.width);
            tryCompare(dashTempScopeItem, "visible", false);

            // Original list is still on 0
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
        }

        function test_manage_dash_search_temp_scope() {
            // TODO Search is disabled for now in manage dash
            skip();

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Do a search
            var scopesList = findChild(dash, "scopesList");
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var searchButton = findChild(scopesListPageHeader, "search_header_button");
            mouseClick(searchButton);

            // Type something
            keyClick(Qt.Key_H);

            // Click on a temp scope in the search
            tryCompareFunction( function() { return findChild(scopesList, "scopesListCategorysearchA") != null; }, true);
            var dashCategorysearchA = findChild(scopesList, "scopesListCategorysearchA");
            tryCompareFunction( function() { return findChild(dashCategorysearchA, "delegate2") != null; }, true);
            var cardTempScope = findChild(dashCategorysearchA, "delegate2");

            waitForRendering(cardTempScope);
            mouseClick(cardTempScope);

            // Check the bottom edge (overview) is disabled from temp scope
            var overviewDragHandle = findChild(dash, "overviewDragHandle");
            compare(overviewDragHandle.enabled, false);

            // Check temp scope is there
            var dashTempScopeItem = findChild(dash, "dashTempScopeItem");
            tryCompare(dashTempScopeItem, "x", 0);
            tryCompare(dashTempScopeItem, "visible", true);

            // Check the manage dash is gone
            tryCompare(bottomEdgeController, "progress", 0);

            // Go back
            var dashTempScopeItemHeader = findChild(dashTempScopeItem, "scopePageHeader");
            var backButton = findChild(findChild(dashTempScopeItemHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);

            // Check temp scope is gone
            tryCompare(dashTempScopeItem, "x", dash.width);
            tryCompare(dashTempScopeItem, "visible", false);

            // Original list is still on 0
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
        }

        function test_manage_dash_open_no_favorites() {
            // Make it so there are no scopes
            scopes.clear();
            var dashContentList = findChild(dash, "dashContentList");
            tryCompare(dashContentList, "count", 0);

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Go back
            var scopesList = findChild(dash, "scopesList");
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var backButton = findChild(findChild(scopesListPageHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);
            tryCompare(bottomEdgeController, "progress", 0);
        }

        function test_setCurrentScope() {
            var dashContentList = findChild(dash, "dashContentList");
            var startX = dash.width - units.gu(1);
            var startY = dash.height / 2;
            var stopX = units.gu(1)
            var stopY = startY;
            waitForRendering(dashContentList)
            mouseFlick(dash, startX, startY, stopX, stopY);
            mouseFlick(dash, startX, startY, stopX, stopY);
            compare(dashContentList.currentIndex, 2, "Could not flick to scope id 2");
            var dashCommunicatorService = findInvisibleChild(dash, "dashCommunicatorService");
            dashCommunicatorService.mockSetCurrentScope(0, true, false);
            tryCompare(dashContentList, "currentIndex", 0)
            dashCommunicatorService.mockSetCurrentScope(1, true, false);
            tryCompare(dashContentList, "currentIndex", 1)
        }

        function test_setCurrentScopeClosesPreview() {
            var dashContent = findChild(dash, "dashContent");
            waitForRendering(dash)

            var scopeLoader0 = findChild(dashContent, "scopeLoader0");
            var dashCategory0 = findChild(scopeLoader0, "dashCategory0");
            var delegate0 = findChild(dashCategory0, "delegate0");
            mouseClick(delegate0);

            tryCompare(dashContent, "subPageShown", true)
            waitForRendering(dash);

            var dashCommunicatorService = findInvisibleChild(dash, "dashCommunicatorService");
            dashCommunicatorService.mockSetCurrentScope(0, true, false);

            tryCompare(dashContent, "subPageShown", false)
        }

        function test_processing_indicator() {
            var processingIndicator = findChild(dash, "processingIndicator");
            verify(processingIndicator, "Can't find the processing indicator.");

            verify(!processingIndicator.visible, "Processing indicator should be visible.");

            tryCompareFunction(function() {
                return scopes.getScope(dashContent.currentIndex) != null;
            }, true);
            var currentScope = scopes.getScope(dashContent.currentIndex);
            verify(currentScope, "Can't find the current scope.");

            currentScope.setSearchInProgress(true);
            tryCompare(processingIndicator, "visible", true);

            currentScope.setSearchInProgress(false);
            tryCompare(processingIndicator, "visible", false);
        }

        function test_manage_dash_store_no_favorites() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // clear the favorite scopes
            scopes.clearFavorites();
            var dashContentList = findChild(dash, "dashContentList");
            tryCompare(dashContentList, "count", 0);

            var scopesList = findChild(dash, "scopesList");
            spy.target = scopesList.scope;
            spy.signalName = "queryPerformed";

            // Click on the store
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var searchButton = findChild(scopesListPageHeader, "store_header_button");
            mouseClick(searchButton);

            spy.wait();
            compare(spy.signalArguments[0][0], "scope://com.canonical.scopes.clickstore");
            tryCompare(bottomEdgeController, "progress", 0);
        }

        function test_manage_dash_move_current() {
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
            compare(dashContentList.currentItem.scopeId, "MockScope1");

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var favScopesListCategory = findChild(dash, "scopesListCategoryfavorites");
            var favScopesListCategoryList = findChild(favScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(favScopesListCategoryList, "currentIndex", 0);

            // Enter edit mode
            var scopesList = findChild(dash, "scopesList");
            var clickScope = findChild(favScopesListCategoryList, "delegateclickscope");
            mousePress(clickScope);
            tryCompare(scopesList, "state", "edit");
            mouseRelease(clickScope);

            var starArea = findChild(clickScope, "starArea");
            touchFlick(starArea, 0, 0, 0, -units.gu(10));

            // Exit edit mode and go back
            var scopesList = findChild(dash, "scopesList");
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var backButton = findChild(findChild(scopesListPageHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);
            mouseClick(backButton);
            tryCompare(bottomEdgeController, "progress", 0);

            tryCompare(dashContentList, "currentIndex", 0);
            compare(dashContentList.currentItem.scopeId, "clickscope");

            // Move to second scope
            touchFlick(dash, dash.width / 2, units.gu(2), dash.width / 5, units.gu(2));
            tryCompare(dashContentList, "currentIndex", 1);
            compare(dashContentList.currentItem.scopeId, "MockScope1");
        }

        function test_manage_dash_move_current_click_other() {
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
            compare(dashContentList.currentItem.scopeId, "MockScope1");

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var favScopesListCategory = findChild(dash, "scopesListCategoryfavorites");
            var favScopesListCategoryList = findChild(favScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(favScopesListCategoryList, "currentIndex", 0);

            // Enter edit mode
            var scopesList = findChild(dash, "scopesList");
            var clickScope = findChild(favScopesListCategoryList, "delegateclickscope");
            mousePress(clickScope);
            tryCompare(scopesList, "state", "edit");
            mouseRelease(clickScope);

            var starArea = findChild(clickScope, "starArea");
            touchFlick(starArea, 0, 0, 0, -units.gu(10));

            // wait for the animation to settle
            tryCompare(clickScope, "height", units.gu(6));

            // Exit edit mode
            var scopesList = findChild(dash, "scopesList");
            var scopesListPageHeader = findChild(scopesList, "pageHeader");
            var backButton = findChild(findChild(scopesListPageHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);

            // Click on third scope
            var mockScope5 = findChild(favScopesListCategoryList, "delegateMockScope5");
            waitForRendering(mockScope5)
            mouseClick(mockScope5);
            tryCompare(bottomEdgeController, "progress", 0);
            tryCompare(dashContentList, "currentIndex", 2);
            compare(dashContentList.currentItem.scopeId, "MockScope5");
        }

        function test_manage_dash_close_dashCommunicator() {
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
            compare(dashContentList.currentItem.scopeId, "MockScope1");

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            var dashCommunicatorService = findInvisibleChild(dash, "dashCommunicatorService");
            dashCommunicatorService.mockSetCurrentScope(1, true, false);

            tryCompare(bottomEdgeController, "progress", 0);
            tryCompare(dashContentList, "currentIndex", 1)
        }

        function test_preview_no_show_manage_dash_hint() {
            var dashContentList = findChild(dash, "dashContentList");
            compare(dashContentList.currentIndex, 0);
            compare(dashContentList.currentItem.scopeId, "MockScope1");

            tryCompareFunction(function() {
                var cardGrid = findChild(dashContentList, "dashCategory0");
                if (cardGrid != null) {
                    var tile = findChild(cardGrid, "delegate0");
                    return tile != null;
                }
                return false;
            },
            true);
            var tile = findChild(findChild(dashContentList, "dashCategory0"), "delegate0");
            waitForRendering(tile);
            mouseClick(tile);

            var overviewHint = findChild(dash, "overviewHint");
            tryCompare(overviewHint, "opacity", 0);
        }

        function test_close_temp_scope_preview_opening_scope() {
            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // Make sure stuff is loaded
            var nonfavScopesListCategory = findChild(dash, "scopesListCategoryother");
            var nonfavScopesListCategoryList = findChild(nonfavScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(nonfavScopesListCategoryList, "currentIndex", 0);

            // Click on a non favorite scope
            mouseClick(nonfavScopesListCategoryList.currentItem);

            // Check the bottom edge (manage dash) is disabled from temp scope
            var overviewDragHandle = findChild(dash, "overviewDragHandle");
            compare(overviewDragHandle.enabled, false);

            // Check temp scope is there
            var dashTempScopeItem = findChild(dash, "dashTempScopeItem");
            tryCompare(dashTempScopeItem, "x", 0);
            tryCompare(dashTempScopeItem, "visible", true);

            // Check the manage dash is gone
            tryCompare(bottomEdgeController, "progress", 0);

            // Open preview
            var categoryListView = findChild(dashTempScopeItem, "categoryListView");
            categoryListView.positionAtBeginning();
            tryCompareFunction(function() {
                                    var cardGrid = findChild(dashTempScopeItem, "dashCategory0");
                                    if (cardGrid != null) {
                                        var tile = findChild(cardGrid, "delegate0");
                                        return tile != null;
                                    }
                                    return false;
                                },
                                true);
            var tile = findChild(findChild(dashTempScopeItem, "dashCategory0"), "delegate0");
            waitForRendering(tile);
            mouseClick(tile);
            var subPageLoader = findChild(dashTempScopeItem, "subPageLoader");
            tryCompare(subPageLoader, "open", true);
            tryCompare(subPageLoader, "x", 0);
            tryCompare(findChild(dashTempScopeItem, "categoryListView"), "visible", false);
            var previewListRow0 = findChild(subPageLoader, "previewListRow0");
            flickToYEnd(previewListRow0);
            var widget = findChild(subPageLoader, "widget-21");
            var initialWidgetHeight = widget.height;
            var openButton = findChild(widget, "buttonopen_click");
            mouseClick(openButton);

            tryCompare(subPageLoader, "open", false);
            tryCompare(subPageLoader, "x", subPageLoader.width);

            compare(dashTempScopeItem.scope.id, "MockScope9");

            // Go back
            var dashTempScopeItemHeader = findChild(dashTempScopeItem, "scopePageHeader");
            var backButton = findChild(findChild(dashTempScopeItemHeader, "innerPageHeader"), "customBackButton");
            mouseClick(backButton);

            // Check temp scope is gone
            tryCompare(dashTempScopeItem, "x", dash.width);
            tryCompare(dashTempScopeItem, "visible", false);
        }

        function test_UriDispatcher()
        {
            var dashContentList = findChild(dash, "dashContentList");

            UriHandler.opened("scopes://clickscope");
            tryCompare(dashContentList, "currentIndex", 1);

            // Show the manage dash
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);

            // UriHandler changes to a scope and closes the manage scopes
            UriHandler.opened("scopes://MockScope1");
            tryCompare(dashContentList, "currentIndex", 0);
            tryCompare(bottomEdgeController, "progress", 0);

            // Show a preview
            var scopeLoader0 = findChild(dashContent, "scopeLoader0");
            var dashCategory0 = findChild(scopeLoader0, "dashCategory0");
            var delegate0 = findChild(dashCategory0, "delegate0");
            mouseClick(delegate0);
            tryCompare(dashContent, "subPageShown", true)

            // UriHandler changes to a scope and closes the manage scopes
            UriHandler.opened("scopes://clickscope");
            tryCompare(dashContentList, "currentIndex", 1);
            tryCompare(dashContent, "subPageShown", false);

            // Go to a temp scope
            touchFlick(dash, dash.width / 2, dash.height - 1, dash.width / 2, units.gu(2));
            var bottomEdgeController = findInvisibleChild(dash, "bottomEdgeController");
            tryCompare(bottomEdgeController, "progress", 1);
            var nonfavScopesListCategory = findChild(dash, "scopesListCategoryother");
            var nonfavScopesListCategoryList = findChild(nonfavScopesListCategory, "scopesListCategoryInnerList");
            tryCompare(nonfavScopesListCategoryList, "currentIndex", 0);
            mouseClick(nonfavScopesListCategoryList.currentItem);
            var dashTempScopeItem = findChild(dash, "dashTempScopeItem");
            tryCompare(dashTempScopeItem, "x", 0);
            tryCompare(dashTempScopeItem, "visible", true);

            // UriHandler changes to a scope and closes the temp scope
            UriHandler.opened("scopes://MockScope1");
            tryCompare(dashContentList, "currentIndex", 0);
            tryCompare(dashTempScopeItem, "x", dashTempScopeItem.width);
            tryCompare(dashTempScopeItem, "visible", false);
        }
    }
}
