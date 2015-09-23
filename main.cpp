#include <QtGui/QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QSettings>

#include "applicationmanager.h"
#include "usermanager.h"
#include "youtubeapimanager.h"
#include "playlistsmanager.h"
#include "videoitem.h"
#include "playlist.h"
#include "sslsafenetworkfactory.h"
#include "closeeventfilter.h"
#include "mouseeventfilter.h"

#include <databasemanager.h>
#include <componentslibrary.h>

#include <QmlVlc.h>
#include <QmlVlcConfig.h>
#include <QmlVlcPlayerProxy.h>

QString logFileName;

void myMessageHandler(QtMsgType, const QMessageLogContext&, const QString &message)
{
//    QFile outFile(logFileName);
//    outFile.open(QIODevice::WriteOnly | QIODevice::Append);
//    QTextStream ts(&outFile);
//    QDateTime date;
//    QString dateStr = date.currentDateTime().toString("[dd/MM/yy | hh:mm:ss]");
//    ts << dateStr << " - " << message << endl;
}

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    //logFileName = "log.txt";
//    qInstallMessageHandler(myMessageHandler);

#ifdef Q_OS_WIN
    //qputenv("VLC_PLUGIN_PATH", QString(QCoreApplication::applicationDirPath() + "/vlc_plugins/"));
    //qDebug() << qgetenv("VLC_PLUGIN_PATH");
#else
    setenv("VLC_PLUGIN_PATH", QString(QCoreApplication::applicationDirPath() + "/vlc_plugins").toLatin1(), 1);
    qDebug() << getenv("VLC_PLUGIN_PATH");
#endif

    QFontDatabase::addApplicationFont(":/fonts/openSans");
    QFontDatabase::addApplicationFont(":/fonts/openSansBold");
    QFontDatabase::addApplicationFont(":/fonts/harabara");

    ApplicationManager::singleton()->loadConfiguration();

    ApplicationManager::declareQML();
    UserManager::declareQML();
    YoutubeAPIManager::declareQML();
    PlaylistsManager::declareQML();
    VideoItem::declareQML();
    Playlist::declareQML();

    Components::initResources();

    QTime time = QTime::currentTime();
    qsrand((uint)time.msec());

    RegisterQmlVlc();
    QmlVlcConfig& config = QmlVlcConfig::instance();
    config.enableAdjustFilter( true );
    config.enableMarqueeFilter( true );
    config.enableLogoFilter( true );
    config.enableDebug( false );

    qRegisterMetaType<QmlVlcPlayerProxy::State>("QmlVlcPlayerProxy::State");

    QQmlApplicationEngine engine;
    engine.setNetworkAccessManagerFactory(new SSLSafeNetworkFactory);
    engine.load(QUrl("qrc:/qml/main.qml"));
    QObject *topLevel = engine.rootObjects().value(0);
    QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);
    CloseEventFilter closeFilter;
    MouseEventFilter mouseFilter;
    window->installEventFilter(&closeFilter);
    window->installEventFilter(&mouseFilter);

#ifdef Q_OS_WIN
    window->setFlags(window->flags() | Qt::FramelessWindowHint);
#else
    ApplicationManager::singleton()->setWindowControlButtonsEnabled(false);
#endif

    ApplicationManager::singleton()->setWindow(window);

    return app.exec();
}
