#include "applicationmanager.h"

#include <QApplication>
#include <QWindow>
#include <QtQml>

ApplicationManager *ApplicationManager::_singleton = 0;

class ApplicationManagerPrivate
{
public:
    ApplicationManagerPrivate() :
        version("0.7.2"),
        window(0),
        fullscreen(false),
        maximized(false),
        mouseX(0),
        mouseY(0),
        dragging(false),
        notificationsEnabled(true),
        networkManager(0)
    {}

    virtual ~ApplicationManagerPrivate()
    {
        if(networkManager) delete networkManager;
    }

    QString version;

    QWindow *window;
    bool fullscreen;
    bool maximized;

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

QString ApplicationManager::version() const
{
    Q_D(const ApplicationManager);
    return d->version;
}

void ApplicationManager::setWindow(QWindow *window)
{
    Q_D(ApplicationManager);
    d->window = window;
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
        QApplication::restoreOverrideCursor();
        break;
    }
}

void ApplicationManager::setNotificationsEnabled(const bool &enabled)
{
    Q_D(ApplicationManager);
    d->notificationsEnabled = enabled;
}

void ApplicationManager::checkForUpdates()
{
    Q_D(ApplicationManager);

    QSettings settings("beatwhale_config.ini", QSettings::IniFormat);
    QUrl versionUrl = settings.value("version_url").toString();

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(versionUrl));
    connect(reply, SIGNAL(finished()), SLOT(checkForUpdatesReply()));
}

void ApplicationManager::checkForUpdatesReply()
{
    Q_D(ApplicationManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    disconnect(reply, SIGNAL(finished()), this, SLOT(checkForUpdatesReply()));

    QByteArray replyBA = reply->readAll();

    if(replyBA.indexOf("version") == -1) return;

    replyBA = replyBA.right(replyBA.count() - replyBA.indexOf("version"));
    int start = replyBA.indexOf(">") + 1;

    QString newVersion = replyBA.mid(start, replyBA.indexOf("<") - start);

    QStringList newVersionTypes = newVersion.split(".");
    QStringList currentVersionTypes = d->version.split(".");

    if(newVersionTypes.count() != 3) return;

    for(int i = 0; i < 3; ++i)
    {
        if(newVersionTypes.at(i).toInt() > currentVersionTypes.at(i).toInt())
        {
            triggerNotification("New version available. Go to www.beatwhale.com to download.");
            break;
        }
    }
}

void ApplicationManager::showNormal()
{
    Q_D(ApplicationManager);

    if(d->fullscreen)
    {
        if(d->maximized) d->window->showMaximized();
        else d->window->showNormal();
        setCursor(CURSORTYPE_NORMAL);
        d->fullscreen = false;
    }
}

void ApplicationManager::showFullscreen()
{
    Q_D(ApplicationManager);

    if(!d->fullscreen)
    {
        d->maximized = d->window->visibility() == QWindow::Maximized;
        d->window->showFullScreen();
        setCursor(CURSORTYPE_FULLSCREEN);
        d->fullscreen = true;
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

void ApplicationManager::triggerNotification(const QString &message)
{
    Q_D(ApplicationManager);
    if(!d->notificationsEnabled) return;
    emit notification(message);
}
