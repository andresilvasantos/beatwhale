#include "videoitem.h"

#include <QtQml>

class VideoItemPrivate
{
public:
    QString id;
    QString title;
    QString subTitle;
    QString thumbnail;
    QString duration;
    QString timestamp;
};

VideoItem::VideoItem(QObject *parent) :
    QObject(parent),
    d_ptr(new VideoItemPrivate)
{
}

VideoItem::~VideoItem()
{
    delete d_ptr;
}

void VideoItem::declareQML()
{
    qmlRegisterType<VideoItem>("BeatWhaleAPI", 1, 0, "VideoItem");
}

QString VideoItem::id() const
{
    Q_D(const VideoItem);
    return d->id;
}

void VideoItem::setID(const QString &id)
{
    Q_D(VideoItem);
    d->id = id;
}

QString VideoItem::title() const
{
    Q_D(const VideoItem);
    return d->title;
}

void VideoItem::setTitle(const QString &title)
{
    Q_D(VideoItem);
    d->title = title;
}

QString VideoItem::subTitle() const
{
    Q_D(const VideoItem);
    return d->subTitle;
}

void VideoItem::setSubTitle(const QString &subTitle)
{
    Q_D(VideoItem);
    d->subTitle = subTitle;
}

QString VideoItem::thumbnail() const
{
    Q_D(const VideoItem);
    return d->thumbnail;
}

void VideoItem::setThumbnail(const QString &thumbnail)
{
    Q_D(VideoItem);
    d->thumbnail = thumbnail;
}

QString VideoItem::duration() const
{
    Q_D(const VideoItem);
    return d->duration;
}

void VideoItem::setDuration(const QString &duration)
{
    Q_D(VideoItem);
    d->duration = duration;
}

QString VideoItem::timestamp() const
{
    Q_D(const VideoItem);
    return d->timestamp;
}

void VideoItem::setTimestamp(const QString &timestamp)
{
    Q_D(VideoItem);
    d->timestamp = timestamp;
}
