#include "applicationmanager.h"

#include <QApplication>
#include <QWindow>
#include <QtQml>

ApplicationManager *ApplicationManager::_singleton = 0;

class ApplicationManagerPrivate
{
public:
    ApplicationManagerPrivate() :
        window(0),
        fullscreen(false),
        maximized(false),
        mouseX(0),
        mouseY(0),
        dragging(false),
        notificationsEnabled(true)
    {}

    virtual ~ApplicationManagerPrivate()
    {
    }

    QWindow *window;
    bool fullscreen;
    bool maximized;

    int mouseX;
    int mouseY;

    bool dragging;
    QString dragInfo;

    bool notificationsEnabled;
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

void ApplicationManager::setNotificationsEnabled(const bool &enabled)
{
    Q_D(ApplicationManager);
    d->notificationsEnabled = enabled;
}

void ApplicationManager::showNormal()
{
    Q_D(ApplicationManager);

    if(d->fullscreen)
    {
        if(d->maximized) d->window->showMaximized();
        else d->window->showNormal();
        QApplication::restoreOverrideCursor();
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
        QApplication::setOverrideCursor(Qt::BlankCursor);
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
