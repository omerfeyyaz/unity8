pkg_search_module(GIO REQUIRED gio-2.0)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
    ${GIO_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/plugins/Utils
)

set(QMLPLUGIN_SRC
    ${CMAKE_SOURCE_DIR}/plugins/Utils/activefocuslogger.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/qlimitproxymodelqml.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/unitysortfilterproxymodelqml.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/unitymenumodelpaths.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/windowkeysfilter.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/windowscreenshotprovider.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/easingcurve.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/inputwatcher.cpp
    constants.cpp
    plugin.cpp
    windowstatestorage.cpp
    plugin.cpp
    )

add_library(FakeUtils-qml SHARED
    ${QMLPLUGIN_SRC}
    )

target_link_libraries(FakeUtils-qml ${GIO_LDFLAGS})

# Because this is an internal support library, we want
# to expose all symbols in it. Consider changing this
# either to a static library or just using the
# files directly in targets.
set_target_properties(FakeUtils-qml PROPERTIES COMPILE_FLAGS -fvisibility=default)

qt5_use_modules(FakeUtils-qml Qml Quick DBus Network Gui)

add_unity8_mock(Utils 0.1 Utils TARGETS FakeUtils-qml)
