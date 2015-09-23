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
    Q_PROPERTY(bool windowControlButtonsEnabled READ windowControlButtonsEnabled NOTIFY windowControlButtonsEnabledChanged)
    Q_PROPERTY(bool maximized READ maximized NOTIFY maximizedChanged)
    Q_PROPERTY(bool fullscreen READ fullscreen NOTIFY fullscreenChanged)
    Q_ENUMS(CursorType)

public:
    enum CursorType
    {
        CURSORTYPE_NORMAL,
        CURSORTYPE_BUTTON,
        CURSORTYPE_DRAG,
        CURSORTYPE_DRAGGING,
        CURSORTYPE_FULLSCREEN
    };

    static ApplicationManager* singleton();
    static void declareQML();

    QString beatwhaleAPIUrl() const;

    Q_INVOKABLE QString version() const;

    QWindow* window() const;
    void setWindow(QWindow *window);

    bool windowControlButtonsEnabled() const;
    void setWindowControlButtonsEnabled(const bool& enabled);

    Q_INVOKABLE bool maximized() const;
    Q_INVOKABLE bool fullscreen() const;

    bool grabbingWindowMoveHandle() const;
    Q_INVOKABLE void setGrabbingWindowMoveHandle(bool grabbing);

    bool grabbingWindowResizeHandle() const;
    Q_INVOKABLE void setGrabbingWindowResizeHandle(bool grabbing);

    int mouseX() const;
    void setMouseX(const int& mouseX);
    int mouseY() const;
    void setMouseY(const int& mouseY);

    bool dragging() const;
    Q_INVOKABLE QString dragInfo() const;

    Q_INVOKABLE void setCursor(const CursorType& cursorType);

    void setNotificationsEnabled(const bool& enabled);

signals:
    void windowControlButtonsEnabledChanged(bool enabled);
    void maximizedChanged(bool maximized);
    void fullscreenChanged(bool fullscreen);

    void mouseXChanged(int mouseX);
    void mouseYChanged(int mouseY);

    void draggingChanged(bool dragging);

    void notification(QString message, int duration);
    void showTooltip(QString text, qreal displacementX, qreal displacementY, int duration);
    void hideTooltip();

public slots:
    void loadConfiguration();
    void checkForUpdates();

    Q_INVOKABLE void quit();
    Q_INVOKABLE void saveWindowData();

    Q_INVOKABLE void showMinimized();
    Q_INVOKABLE bool showNormal();
    Q_INVOKABLE void showMaximized();
    Q_INVOKABLE void showFullscreen(bool fullscreen = true);

    Q_INVOKABLE void dragStarted(const QString& dragInfo);
    Q_INVOKABLE void dragFinished();

    Q_INVOKABLE void triggerNotification(const QString& message, const int &duration = 2500);
    Q_INVOKABLE void triggerTooltip(const QString& tooltip, const qreal& displacementX, const qreal& displacementY, const int& duration = 1500);
    Q_INVOKABLE void cancelTooltip();

private slots:
    void loadConfigurationReply();
    //void checkForUpdatesReply();

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
