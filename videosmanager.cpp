#include "videosmanager.h"

#include <QtQml>
#include <QUuid>

VideosManager *VideosManager::_singleton = 0;

class VideosManagerPrivate
{
public:

};

VideosManager::VideosManager(QObject *parent) :
    QObject(parent),
    d_ptr(new VideosManagerPrivate)
{
}

VideosManager::~VideosManager()
{
    delete d_ptr;
}

VideosManager *VideosManager::singleton()
{
    if(!_singleton)
    {
        _singleton = new VideosManager;
    }
    return _singleton;
}

void VideosManager::declareQML()
{
    qmlRegisterSingletonType<VideosManager>("BeatWhaleAPI", 1, 0, "VideosManager", qmlVideosManagerSingleton);
}
