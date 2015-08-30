#ifndef APPLICATIONMANAGER_H
#define APPLICATIONMANAGER_H

#include <QObject>
#include <QStringList>

class QWindow;
class QQmlEngine;
class QJSEngine;
class ApplicationManagerPrivate;
class ApplicationManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(qreal mouseX READ mouseX WRITE setMouseX NOTIFY mouseXChanged)
    Q_PROPERTY(qreal mouseY READ mouseY WRITE setMouseY NOTIFY mouseYChanged)
    Q_PROPERTY(qreal dragging READ dragging NOTIFY draggingChanged)

public:
    static ApplicationManager* singleton();
    static void declareQML();

    void setWindow(QWindow *window);

    int mouseX() const;
    void setMouseX(const int& mouseX);
    int mouseY() const;
    void setMouseY(const int& mouseY);

    bool dragging() const;
    Q_INVOKABLE QString dragInfo() const;

    void setNotificationsEnabled(const bool& enabled);

signals:
    void mouseXChanged(int mouseX);
    void mouseYChanged(int mouseY);

    void draggingChanged(bool dragging);
    void notification(QString message);

public slots:
    Q_INVOKABLE void showNormal();
    Q_INVOKABLE void showFullscreen();

    Q_INVOKABLE void dragStarted(const QString& dragInfo);
    Q_INVOKABLE void dragFinished();

    Q_INVOKABLE void triggerNotification(const QString& message);

private slots:

private:
    explicit ApplicationManager(QObject *parent = 0);
    virtual ~ApplicationManager();

    static ApplicationManager *_singleton;

    Q_DECLARE_PRIVATE(ApplicationManager)
    ApplicationManagerPrivate * const d_ptr;

};

static QObject *qmlApplicationManagerSingleton(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return ApplicationManager::singleton();
}

#endif // APPLICATIONMANAGER_H
