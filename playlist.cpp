#include "playlist.h"
#include "videoitem.h"
#include "playlistsmanager.h"
#include "applicationmanager.h"

#include <QtQml>
#include <QMap>
#include <QDebug>

class PlaylistPrivate
{
public:
    PlaylistPrivate() :
        name("Unnamed Playlist")
    {}

    virtual ~PlaylistPrivate()
    {
        foreach(VideoItem *videoItem, videoItems.values())
        {
            delete videoItem;
        }
    }

    QString name;
    QMap<QString,VideoItem*> videoItems;
};

Playlist::Playlist(QObject *parent) :
    QObject(parent),
    d_ptr(new PlaylistPrivate)
{
}

Playlist::~Playlist()
{
    delete d_ptr;
}

void Playlist::declareQML()
{
    qmlRegisterType<Playlist>("BeatWhaleAPI", 1, 0, "Playlist");
}

QString Playlist::name() const
{
    Q_D(const Playlist);
    return d->name;
}

void Playlist::setName(const QString &name)
{
    Q_D(Playlist);
    if(d->name == name) return;

    QString oldName = d->name;
    d->name = name;
    emit nameChanged(d->name, oldName);
}

bool Playlist::containsItem(const QString &id) const
{
    Q_D(const Playlist);
    return d->videoItems.contains(id);
}

void Playlist::addItem(const QString &id, const QString &title, const QString &subTitle, const QString &thumbnail, const QString& duration, QString timestamp)
{
    Q_D(Playlist);

    if(d->videoItems.contains(id))
    {
        //qDebug() << "Video" << title << "already in playlist";
        return;
    }

    if(timestamp.isEmpty()) timestamp = QString::number(QDateTime::currentMSecsSinceEpoch());

    VideoItem *videoItem = new VideoItem;
    videoItem->setID(id);
    videoItem->setTitle(title);
    videoItem->setSubTitle(subTitle);
    videoItem->setThumbnail(thumbnail);
    videoItem->setDuration(duration);
    videoItem->setTimestamp(timestamp);
    d->videoItems.insert(id, videoItem);

    QString message;
    if(!videoItem->subTitle().isEmpty()) message = "Added " + videoItem->title() + " - " + videoItem->subTitle() + " to playlist " + d->name;
    else message = "Added " + videoItem->title() + " to playlist " + d->name;
    ApplicationManager::singleton()->triggerNotification(message);

    emit itemAdded(videoItem);
    emit playlistChanged();
}

void Playlist::addItems(const QStringList &ids, const QStringList &titles, const QStringList &subTitles, const QStringList &thumbnails, const QStringList &durations,
                        QString timestamp)
{
    Q_D(Playlist);

    if(ids.isEmpty()) return;

    if(timestamp.isEmpty()) timestamp = QString::number(QDateTime::currentMSecsSinceEpoch());

    QList<VideoItem*> videoItems;
    int count = 0;
    for(int i = 0; i < ids.count(); ++i)
    {
        if(d->videoItems.contains(ids.at(i))) continue;

        VideoItem *videoItem = new VideoItem;
        videoItem->setID(ids.at(i));
        videoItem->setTitle(titles.at(i));
        videoItem->setSubTitle(subTitles.at(i));
        videoItem->setThumbnail(thumbnails.at(i));
        videoItem->setDuration(durations.at(i));
        videoItem->setTimestamp(timestamp);
        d->videoItems.insert(ids.at(i), videoItem);

        videoItems.append(videoItem);
        ++count;
    }

    if(count == 1)
    {
        QString message;
        if(!videoItems.at(0)->subTitle().isEmpty()) message = "Added " + videoItems.at(0)->title() + " - " + videoItems.at(0)->subTitle() + " to playlist " + d->name;
        else message = "Added " + videoItems.at(0)->title() + " to playlist " + d->name;
        ApplicationManager::singleton()->triggerNotification(message);
    }
    else if(count > 1)
    {
        ApplicationManager::singleton()->triggerNotification("Added " + QString::number(count) + " items to playlist " + d->name);
    }

    emit itemsAdded(videoItems);
    emit playlistChanged();
}

bool Playlist::removeItem(const QString &id)
{
    Q_D(Playlist);

    if(!d->videoItems.contains(id)) return false;

    VideoItem *videoItem = d->videoItems.value(id);
    d->videoItems.remove(id);

    QString message;
    if(!videoItem->subTitle().isEmpty()) message = "Removed " + videoItem->title() + " - " + videoItem->subTitle() + " from playlist " + d->name;
    else message = "Removed " + videoItem->title() + " from playlist " + d->name;
    ApplicationManager::singleton()->triggerNotification(message);

    delete videoItem;

    emit itemRemoved(id);
    emit playlistChanged();
    return true;
}

void Playlist::removeItems(const QStringList &ids)
{
    Q_D(Playlist);

    foreach(QString id, ids)
    {
        if(!d->videoItems.contains(id)) continue;
        VideoItem *videoItem = d->videoItems.value(id);
        d->videoItems.remove(id);

        if(ids.count() == 1)
        {
            QString message;
            if(!videoItem->subTitle().isEmpty()) message = "Removed " + videoItem->title() + " - " + videoItem->subTitle() + " from playlist " + d->name;
            else message = "Removed " + videoItem->title() + " from playlist " + d->name;
            ApplicationManager::singleton()->triggerNotification(message);
        }

        delete videoItem;
    }

    if(ids.count() > 1)
    {
        ApplicationManager::singleton()->triggerNotification("Removed " + QString::number(ids.count()) + " items from playlist " + d->name);
    }

    emit itemsRemoved(ids);
    emit playlistChanged();
}

QList<QObject *> Playlist::items() const
{
    Q_D(const Playlist);
    QList<QObject*> items;
    foreach(VideoItem *videoItem, d->videoItems.values())
    {
        items.append(videoItem);
    }

    return items;
}
