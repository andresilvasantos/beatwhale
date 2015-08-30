#ifndef VIDEOSMANAGER_H
#define VIDEOSMANAGER_H

#include <QObject>

class QQmlContext;
class QQmlEngine;
class QJSEngine;
class VideosManagerPrivate;
class VideosManager : public QObject
{
    Q_OBJECT
public:
    static VideosManager* singleton();
    static void declareQML();

signals:

public slots:

private:
    explicit VideosManager(QObject *parent = 0);
    virtual ~VideosManager();

    static VideosManager *_singleton;

    Q_DECLARE_PRIVATE(VideosManager)
    VideosManagerPrivate * const d_ptr;

};

static QObject *qmlVideosManagerSingleton(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return VideosManager::singleton();
}

#endif // VIDEOSMANAGER_H
