#include "applicationmanager.h"
#include "youtubeapimanager.h"

#include <databasemanager.h>

#include <QApplication>
#include <QWindow>
#include <QtQml>

ApplicationManager *ApplicationManager::_singleton = 0;

class ApplicationManagerPrivate
{
public:
    ApplicationManagerPrivate() :
        version("0.8.0"),
        newVersionAvailable(false),
        window(0),
        windowControlButtonsEnabled(true),
        maximized(false),
        fullscreen(false),
        maximizedToFullscreen(false),
        grabbingWindowMoveHandle(false),
        grabbingWindowResizeHandle(false),
        mouseX(0),
        mouseY(0),
        dragging(false),
        notificationsEnabled(true),
        networkManager(0)
    {
        QSettings settings("beatwhale_config.ini", QSettings::IniFormat);
        beatwhaleAPIUrl = settings.value("beatwhale_api_url").toString();
    }

    virtual ~ApplicationManagerPrivate()
    {
        if(networkManager) delete networkManager;
    }

    QString beatwhaleAPIUrl;

    QString version;
    bool newVersionAvailable;

    QWindow *window;
    bool windowControlButtonsEnabled;
    bool maximized;
    bool fullscreen;
    bool maximizedToFullscreen;
    bool grabbingWindowMoveHandle;
    bool grabbingWindowResizeHandle;

    int mouseX;
    int mouseY;

    bool dragging;
    QString dragInfo;

    bool notificationsEnabled;

    QNetworkAccessManager *networkManager;
};

ApplicationManager::ApplicationManager(QObject *parent) :
    QObject(parent),
    d_ptr(new ApplicationManagerPrivate)
{
}

ApplicationManager::~ApplicationManager()
{
    delete d_ptr;
}

ApplicationManager *ApplicationManager::singleton()
{
    if(!_singleton)
    {
        _singleton = new ApplicationManager;
    }
    return _singleton;
}

void ApplicationManager::declareQML()
{
    qmlRegisterSingletonType<ApplicationManager>("BeatWhaleAPI", 1, 0, "ApplicationManager", qmlApplicationManagerSingleton);
}

QString ApplicationManager::beatwhaleAPIUrl() const
{
    Q_D(const ApplicationManager);
    return d->beatwhaleAPIUrl;
}

QString ApplicationManager::version() const
{
    Q_D(const ApplicationManager);
    return d->version;
}

QWindow *ApplicationManager::window() const
{
    Q_D(const ApplicationManager);
    return d->window;
}

void ApplicationManager::setWindow(QWindow *window)
{
    Q_D(ApplicationManager);
    d->window = window;

    QSettings localSettings(QSettings::IniFormat, QSettings::UserScope, "BeatWhale", "beatwhale_app");
    if(localSettings.childGroups().contains("window_geometry"))
    {
        localSettings.beginGroup("window_geometry");
        if(localSettings.value("maximized", false).toBool())
        {
            showMaximized();
        }
        else
        {
            int width = localSettings.value("width", 800).toInt();
            int height = localSettings.value("height", 600).toInt();
            if(width < 800) width = 800;
            if(height < 600) height = 600;
            d->window->setGeometry(localSettings.value("x", 0).toInt(), localSettings.value("y", 0).toInt(), width, height);
            showNormal();
        }
    }
    else
    {
        d->window->showNormal();
    }
}

bool ApplicationManager::windowControlButtonsEnabled() const
{
    Q_D(const ApplicationManager);
    return d->windowControlButtonsEnabled;
}

void ApplicationManager::setWindowControlButtonsEnabled(const bool &enabled)
{
    Q_D(ApplicationManager);
    if(d->windowControlButtonsEnabled == enabled) return;

    d->windowControlButtonsEnabled = enabled;
    emit windowControlButtonsEnabledChanged(d->windowControlButtonsEnabled);
}

bool ApplicationManager::maximized() const
{
    Q_D(const ApplicationManager);
    return d->maximized;
}

bool ApplicationManager::fullscreen() const
{
    Q_D(const ApplicationManager);
    return d->fullscreen;
}

bool ApplicationManager::grabbingWindowMoveHandle() const
{
    Q_D(const ApplicationManager);
    return d->grabbingWindowMoveHandle;
}

void ApplicationManager::setGrabbingWindowMoveHandle(bool grabbing)
{
    Q_D(ApplicationManager);
    d->grabbingWindowMoveHandle = grabbing;
}

bool ApplicationManager::grabbingWindowResizeHandle() const
{
    Q_D(const ApplicationManager);
    return d->grabbingWindowResizeHandle;
}

void ApplicationManager::setGrabbingWindowResizeHandle(bool grabbing)
{
    Q_D(ApplicationManager);
    d->grabbingWindowResizeHandle = grabbing;
}

int ApplicationManager::mouseX() const
{
    Q_D(const ApplicationManager);
    return d->mouseX;
}

void ApplicationManager::setMouseX(const int &mouseX)
{
    Q_D(ApplicationManager);
    if(d->mouseX == mouseX) return;

    d->mouseX = mouseX;
    emit mouseXChanged(d->mouseX);
}

int ApplicationManager::mouseY() const
{
    Q_D(const ApplicationManager);
    return d->mouseY;
}

void ApplicationManager::setMouseY(const int &mouseY)
{
    Q_D(ApplicationManager);
    if(d->mouseY == mouseY) return;

    d->mouseY = mouseY;
    emit mouseYChanged(d->mouseY);
}

bool ApplicationManager::dragging() const
{
    Q_D(const ApplicationManager);
    return d->dragging;
}

QString ApplicationManager::dragInfo() const
{
    Q_D(const ApplicationManager);
    return d->dragInfo;
}

void ApplicationManager::setCursor(const ApplicationManager::CursorType &cursorType)
{
    QApplication::restoreOverrideCursor();

    switch(cursorType)
    {
    case CURSORTYPE_BUTTON:
        QApplication::setOverrideCursor(Qt::PointingHandCursor);
        break;
    case CURSORTYPE_DRAG:
        QApplication::setOverrideCursor(Qt::OpenHandCursor);
        break;
    case CURSORTYPE_DRAGGING:
        QApplication::setOverrideCursor(Qt::ClosedHandCursor);
        break;
    case CURSORTYPE_FULLSCREEN:
        QApplication::setOverrideCursor(Qt::BlankCursor);
        break;
    case CURSORTYPE_NORMAL:
    default:
        break;
    }
}

void ApplicationManager::setNotificationsEnabled(const bool &enabled)
{
    Q_D(ApplicationManager);
    d->notificationsEnabled = enabled;
}

void ApplicationManager::loadConfiguration()
{
    Q_D(ApplicationManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "configuration.php");
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(loadConfigurationReply()));
}

void ApplicationManager::loadConfigurationReply()
{
    Q_D(ApplicationManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    delete reply;

    QString dbHost = obj.value("db_host").toString();
    QString youtubeAPIKey = obj.value("youtube_api_key").toString();
    QString newVersion = obj.value("beatwhale_version").toString();

    if(dbHost.isEmpty() || youtubeAPIKey.isEmpty() || newVersion.isEmpty())
    {
        QTimer::singleShot(2000, this, SLOT(loadConfiguration()));
        return;
    }

    DatabaseManager::singleton()->setBaseUrl(dbHost);
    YoutubeAPIManager::singleton()->setAPIKey(youtubeAPIKey);

    //Check if there is a new version available
    QStringList newVersionTypes = newVersion.split(".");
    QStringList currentVersionTypes = d->version.split(".");

    if(newVersionTypes.count() != 3) return;

    for(int i = 0; i < 3; ++i)
    {
        if(newVersionTypes.at(i).toInt() > currentVersionTypes.at(i).toInt())
        {
            d->newVersionAvailable = true;
            break;
        }
        else if(newVersionTypes.at(i).toInt() < currentVersionTypes.at(i).toInt())
        {
            break;
        }
    }
}

void ApplicationManager::checkForUpdates()
{
    Q_D(ApplicationManager);

    if(d->newVersionAvailable) triggerNotification("New version available. Go to www.beatwhale.com to download.", 10000);
}

void ApplicationManager::quit()
{
    saveWindowData();
    QApplication::instance()->quit();
}

void ApplicationManager::saveWindowData()
{
    Q_D(ApplicationManager);

    QSettings localSettings(QSettings::IniFormat, QSettings::UserScope, "BeatWhale", "beatwhale_app");
    localSettings.beginGroup("window_geometry");
    localSettings.setValue("x", d->window->x());
    localSettings.setValue("y", d->window->y());
    localSettings.setValue("width", d->window->width());
    localSettings.setValue("height", d->window->height());
    localSettings.setValue("maximized", d->window->visibility() == QWindow::Maximized);
    localSettings.endGroup();
}

void ApplicationManager::showMinimized()
{
    Q_D(ApplicationManager);
    d->window->showMinimized();
}

bool ApplicationManager::showNormal()
{
    Q_D(ApplicationManager);
    if(d->window->visibility() != QWindow::Windowed)
    {
        d->window->showNormal();
        d->maximized = false;
        maximizedChanged(d->maximized);
        return true;
    }

    return false;
}

void ApplicationManager::showMaximized()
{
    Q_D(ApplicationManager);

    if(d->window->visibility() == QWindow::Maximized) d->window->showNormal();
    else d->window->showMaximized();

    d->maximized = d->window->visibility() == QWindow::Maximized;
    maximizedChanged(d->maximized);
}

void ApplicationManager::showFullscreen(bool fullscreen)
{
    Q_D(ApplicationManager);

    if(fullscreen && d->window->visibility() != QWindow::FullScreen)
    {
        d->maximizedToFullscreen = d->window->visibility() == QWindow::Maximized;
        d->window->showFullScreen();
        setCursor(CURSORTYPE_FULLSCREEN);
        d->fullscreen = fullscreen;

        fullscreenChanged(d->fullscreen);
    }
    else if(!fullscreen && d->window->visibility() == QWindow::FullScreen)
    {
        if(d->maximizedToFullscreen) d->window->showMaximized();
        else d->window->showNormal();
        setCursor(CURSORTYPE_NORMAL);
        d->fullscreen = fullscreen;

        fullscreenChanged(d->fullscreen);
        d->maximized = d->window->visibility() == QWindow::Maximized;
        maximizedChanged(d->maximized);
    }
}

void ApplicationManager::dragStarted(const QString& dragInfo)
{
    Q_D(ApplicationManager);

    if(d->dragging) return;

    d->dragging = true;
    d->dragInfo = dragInfo;
    emit draggingChanged(d->dragging);
}

void ApplicationManager::dragFinished()
{
    Q_D(ApplicationManager);

    if(!d->dragging) return;

    d->dragging = false;
    emit draggingChanged(d->dragging);
}

void ApplicationManager::triggerNotification(const QString &message, const int &duration)
{
    Q_D(ApplicationManager);
    if(!d->notificationsEnabled) return;
    emit notification(message, duration);
}

void ApplicationManager::triggerTooltip(const QString &tooltip, const qreal &displacementX, const qreal &displacementY, const int &duration)
{
    Q_D(ApplicationManager);

    emit showTooltip(tooltip, displacementX, displacementY, duration);
}

void ApplicationManager::cancelTooltip()
{
    emit hideTooltip();
}
