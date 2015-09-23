QT += qml quick multimedia declarative

ROOT_DIR = ../..

macx {
    CONFIG+= app_bundle
}

CONFIG += c++11

CONFIG(debug, debug|release): DESTDIR = $${ROOT_DIR}/Output/debug
CONFIG(release, debug|release): DESTDIR = $${ROOT_DIR}/Output/release

INCLUDEPATH += $$PWD

LIBS += -L$${DESTDIR} -ltop_utils
LIBS += -L$${DESTDIR} -ltop_databasemanager
LIBS += -L$${DESTDIR} -ltop_components
LIBS += -L$${DESTDIR} -ltop_vlc

win32 {
    PRE_TARGETDEPS += $${DESTDIR}/top_utils.lib
    PRE_TARGETDEPS += $${DESTDIR}/top_databasemanager.lib
    PRE_TARGETDEPS += $${DESTDIR}/top_components.lib
    PRE_TARGETDEPS += $${DESTDIR}/top_vlc.lib
}

unix {
    PRE_TARGETDEPS += $${DESTDIR}/libtop_utils.a
    PRE_TARGETDEPS += $${DESTDIR}/libtop_databasemanager.a
    PRE_TARGETDEPS += $${DESTDIR}/libtop_components.a
    PRE_TARGETDEPS += $${DESTDIR}/libtop_vlc.a
}

INCLUDEPATH += ../../TOP/TOP-Utils
INCLUDEPATH += ../../TOP/TOP-DatabaseManager
INCLUDEPATH += ../../TOP/TOP-Components
INCLUDEPATH += ../../TOP/TOP-VLC

win32 {
    VERSION = 0.8.0.0
    RC_ICONS="icon/icon.ico"
    QMAKE_TARGET_COMPANY = "BeatWhale Inc"
    QMAKE_TARGET_PRODUCT = "BeatWhale"
    QMAKE_TARGET_DESCRIPTION = ""
    QMAKE_TARGET_COPYRIGHT = "Copyright © 2015 BeatWhale Inc"
}

unix {
    ICON = beatwhale.icns
}

defineTest(qtcAddDeployment) {
for(deploymentfolder, DEPLOYMENTFOLDERS) {
    item = item$${deploymentfolder}
    greaterThan(QT_MAJOR_VERSION, 4) {
        itemsources = $${item}.files
    } else {
        itemsources = $${item}.sources
    }
    $$itemsources = $$eval($${deploymentfolder}.source)
    itempath = $${item}.path
    $$itempath= $$eval($${deploymentfolder}.target)
    export($$itemsources)
    export($$itempath)
    DEPLOYMENT += $$item
}

MAINPROFILEPWD = $$PWD

    copyCommand =
    for(deploymentfolder, DEPLOYMENTFOLDERS) {
        source = $$MAINPROFILEPWD/$$eval($${deploymentfolder}.source)
        source = $$replace(source, /, \\)
        sourcePathSegments = $$split(source, \\)
        target = $$DESTDIR/$$eval($${deploymentfolder}.target)/$$last(sourcePathSegments)
        target = $$replace(target, /, \\)
        target ~= s,\\\\\\.?\\\\,\\,
        !isEqual(source,$$target) {
            !isEmpty(copyCommand):copyCommand += &&
            isEqual(QMAKE_DIR_SEP, \\) {
                copyCommand += $(COPY_DIR) \"$$source\" \"$$target\"
            } else {
                source = $$replace(source, \\\\, /)
                target = $$DESTDIR/$$eval($${deploymentfolder}.target)
                target = $$replace(target, \\\\, /)
                copyCommand += test -d \"$$target\" || mkdir -p \"$$target\" && cp -r \"$$source\" \"$$target\"
            }
        }
    }
    !isEmpty(copyCommand) {
        copyCommand = @echo Copying application data... && $$copyCommand
        copydeploymentfolders.commands = $$copyCommand
        first.depends = $(first) copydeploymentfolders
        export(first.depends)
        export(copydeploymentfolders.commands)
        QMAKE_EXTRA_TARGETS += first copydeploymentfolders
    }

export (ICON)
export (INSTALLS)
export (DEPLOYMENT)
export (LIBS)
export (QMAKE_EXTRA_TARGETS)

}

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

TARGET = BeatWhale

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    youtubeapimanager.cpp \
    playlistsmanager.cpp \
    videoitem.cpp \
    playlist.cpp \
    usermanager.cpp \
    videosmanager.cpp \
    sslsafenetworkaccessmanager.cpp \
    sslsafenetworkfactory.cpp \
    closeeventfilter.cpp \
    applicationmanager.cpp \
    mouseeventfilter.cpp

HEADERS += \
    youtubeapimanager.h \
    playlistsmanager.h \
    videoitem.h \
    playlist.h \
    usermanager.h \
    videosmanager.h \
    sslsafenetworkaccessmanager.h \
    sslsafenetworkfactory.h \
    closeeventfilter.h \
    applicationmanager.h \
    mouseeventfilter.h

# Installation path
# target.path =

# Please do not modify the following two lines. Required for deployment.
#include(qtquick2applicationviewer/qtquick2applicationviewer.pri)
qtcAddDeployment()


RESOURCES += \
    resources.qrc

INCLUDEPATH += "../../OtherLibs/VLC/include"

win32 {
    LIBS += -L"../../OtherLibs/VLC/lib" -llibvlc
}

unix {
    LIBS += -L"../../OtherLibs/VLC/lib" -lvlc
}

#QMAKE_CXXFLAGS_RELEASE += -g
#QMAKE_CFLAGS_RELEASE += -g
#QMAKE_LFLAGS_RELEASE =
