#include "playlistsmanager.h"
#include "videoitem.h"
#include "playlist.h"
#include "usermanager.h"
#include "applicationmanager.h"

#include <jsonhelper.h>

#include <QtQml>
#include <QUuid>

PlaylistsManager *PlaylistsManager::_singleton = 0;

class PlaylistsManagerPrivate
{
public:
    PlaylistsManagerPrivate()
    {}

    virtual ~PlaylistsManagerPrivate()
    {
        foreach(QObject *videoItem, favorites.values())
        {
            delete videoItem;
        }

        foreach(Playlist *playlist, playlists)
        {
            delete playlist;
        }
    }

    QJsonDocument playlistsDocument;

    QMap<QString,VideoItem*> favorites;
    QList<Playlist*> playlists;
};

PlaylistsManager::PlaylistsManager(QObject *parent) :
    QObject(parent),
    d_ptr(new PlaylistsManagerPrivate)
{
}

PlaylistsManager::~PlaylistsManager()
{
    //Commented because it was causing crash
    //delete d_ptr;
}

PlaylistsManager *PlaylistsManager::singleton()
{
    if(!_singleton)
    {
        _singleton = new PlaylistsManager;
    }
    return _singleton;
}

void PlaylistsManager::declareQML()
{
    qmlRegisterSingletonType<PlaylistsManager>("BeatWhaleAPI", 1, 0, "PlaylistsManager", qmlPlaylistsManagerSingleton);
}

void PlaylistsManager::setDocument(const QJsonDocument &document)
{
    Q_D(PlaylistsManager);

    d->favorites.clear();
    foreach(Playlist *playlist, d->playlists)
    {
        delete playlist;
    }
    d->playlists.clear();

    d->playlistsDocument = document;
}

bool PlaylistsManager::isFavorited(const QString& id) const
{
    Q_D(const PlaylistsManager);
    return d->favorites.contains(id);
}

void PlaylistsManager::addFavorite(const QString &id, const QString &title, const QString &subTitle, const QString &thumbnail,
                                      const QString& duration, QString timestamp)
{
    Q_D(PlaylistsManager);

    if(d->favorites.contains(id))
    {
        //qDebug() << "Video" << title << "already in favorites";
        return;
    }

    if(!d->playlistsDocument.object().value("Favorites").toObject().contains(id))
    {
        timestamp = QString::number(QDateTime::currentMSecsSinceEpoch());

        JsonHelper::modifyValue(d->playlistsDocument, "Favorites." + id + ".title", title);
        JsonHelper::modifyValue(d->playlistsDocument, "Favorites." + id + ".subtitle", subTitle);
        JsonHelper::modifyValue(d->playlistsDocument, "Favorites." + id + ".thumbnail", thumbnail);
        JsonHelper::modifyValue(d->playlistsDocument, "Favorites." + id + ".duration", duration);
        JsonHelper::modifyValue(d->playlistsDocument, "Favorites." + id + ".timestamp", timestamp);
        UserManager::singleton()->updateDocument(d->playlistsDocument);
    }

    VideoItem *videoItem = new VideoItem;
    videoItem->setID(id);
    videoItem->setTitle(title);
    videoItem->setSubTitle(subTitle);
    videoItem->setThumbnail(thumbnail);
    videoItem->setDuration(duration);
    videoItem->setTimestamp(timestamp);
    d->favorites.insert(id, videoItem);

    QString message;
    if(!videoItem->subTitle().isEmpty()) message = "Added item to favorites: " + videoItem->title() + " - " + videoItem->subTitle();
    else message = "Added item to favorites: " + videoItem->title();
    ApplicationManager::singleton()->triggerNotification(message);

    emit favoritesChanged();
}

bool PlaylistsManager::removeFavorite(const QString &id)
{
    Q_D(PlaylistsManager);

    if(!d->favorites.contains(id)) return false;

    if(d->playlistsDocument.object().value("Favorites").toObject().contains(id))
    {
        JsonHelper::removeKey(d->playlistsDocument, "Favorites", id);
        UserManager::singleton()->updateDocument(d->playlistsDocument);
    }

    VideoItem *videoItem = d->favorites.value(id);
    d->favorites.remove(id);

    QString message;
    if(!videoItem->subTitle().isEmpty()) message = "Removed item from favorites: " + videoItem->title() + " - " + videoItem->subTitle();
    else message = "Removed item from favorites: " + videoItem->title();
    ApplicationManager::singleton()->triggerNotification(message);

    delete videoItem;
    emit favoritesChanged();
    return true;
}

void PlaylistsManager::removeFavorites(const QStringList &ids)
{
    Q_D(PlaylistsManager);

    foreach(QString id, ids)
    {
        if(!d->favorites.contains(id)) continue;

        if(d->playlistsDocument.object().value("Favorites").toObject().contains(id))
        {
            JsonHelper::removeKey(d->playlistsDocument, "Favorites", id);
        }

        VideoItem *videoItem = d->favorites.value(id);
        d->favorites.remove(id);

        if(ids.count() == 1)
        {
            QString message;
            if(!videoItem->subTitle().isEmpty()) message = "Removed " + videoItem->title() + " - " + videoItem->subTitle() + " from favorites";
            else message = "Removed " + videoItem->title() + " from favorites";
            ApplicationManager::singleton()->triggerNotification(message);
        }

        delete videoItem;
    }
    UserManager::singleton()->updateDocument(d->playlistsDocument);

    if(ids.count() > 1)
    {
        ApplicationManager::singleton()->triggerNotification("Removed " + QString::number(ids.count()) + " items from favorites");
    }

    emit favoritesChanged();
}

QList<QObject *> PlaylistsManager::favorites() const
{
    Q_D(const PlaylistsManager);
    QList<QObject*> items;
    foreach(VideoItem *videoItem, d->favorites.values())
    {
        items.append(videoItem);
    }

    return items;
}

QList<QString> PlaylistsManager::playlistNames() const
{
    Q_D(const PlaylistsManager);

    QList<QString> playlistNames;
    foreach(Playlist *playlist, d->playlists)
    {
        playlistNames << playlist->name();
    }

    return playlistNames;
}

void PlaylistsManager::addPlaylist(Playlist *playlist)
{
    Q_D(PlaylistsManager);

    foreach(Playlist *pl, d->playlists)
    {
        if(pl->name() == playlist->name()) return;
    }

    if(!d->playlistsDocument.object().contains(playlist->name()))
    {
        QJsonObject obj = d->playlistsDocument.object();
        obj.insert(playlist->name(), QJsonValue());
        d->playlistsDocument = QJsonDocument(obj);
        UserManager::singleton()->updateDocument(d->playlistsDocument);
    }

    d->playlists.append(playlist);
    emit playlistAdded(playlist->name());

    connect(playlist, SIGNAL(nameChanged(QString,QString)), SLOT(playlistNameChanged(QString,QString)));
    connect(playlist, SIGNAL(itemAdded(VideoItem*)), SLOT(playlistItemAdded(VideoItem*)));
    connect(playlist, SIGNAL(itemsAdded(QList<VideoItem*>)), SLOT(playlistItemsAdded(QList<VideoItem*>)));
    connect(playlist, SIGNAL(itemRemoved(QString)), SLOT(playlistItemRemoved(QString)));
    connect(playlist, SIGNAL(itemsRemoved(QStringList)), SLOT(playlistItemsRemoved(QStringList)));
}

Playlist *PlaylistsManager::createPlaylist(const QString& name)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = new Playlist(this);
    if(!name.isEmpty()) playlist->setName(name);

    QString nameTmp = playlist->name();

    int count = 2;
    while(d->playlistsDocument.object().contains(playlist->name()))
    {
        playlist->setName(nameTmp + " " + QString::number(count));
        ++count;
    }

    QJsonObject obj = d->playlistsDocument.object();
    obj.insert(playlist->name(), QJsonValue());
    d->playlistsDocument = QJsonDocument(obj);
    UserManager::singleton()->updateDocument(d->playlistsDocument);

    d->playlists.append(playlist);
    emit playlistCreated(playlist->name());

    ApplicationManager::singleton()->triggerNotification("Created new playlist " + playlist->name());

    connect(playlist, SIGNAL(nameChanged(QString,QString)), SLOT(playlistNameChanged(QString,QString)));
    connect(playlist, SIGNAL(itemAdded(VideoItem*)), SLOT(playlistItemAdded(VideoItem*)));
    connect(playlist, SIGNAL(itemsAdded(QList<VideoItem*>)), SLOT(playlistItemsAdded(QList<VideoItem*>)));
    connect(playlist, SIGNAL(itemRemoved(QString)), SLOT(playlistItemRemoved(QString)));
    connect(playlist, SIGNAL(itemsRemoved(QStringList)), SLOT(playlistItemsRemoved(QStringList)));

    return playlist;
}

bool PlaylistsManager::deletePlaylist(const QString &name)
{
    Q_D(PlaylistsManager);

    Playlist *playlistToRemove = playlist(name);
    if(!playlistToRemove) return false;

    QJsonObject obj = d->playlistsDocument.object();
    obj.remove(playlistToRemove->name());
    d->playlistsDocument = QJsonDocument(obj);
    UserManager::singleton()->updateDocument(d->playlistsDocument);

    ApplicationManager::singleton()->triggerNotification("Playlist " + name + " deleted");

    d->playlists.removeAll(playlistToRemove);
    emit playlistRemoved(playlistToRemove->name());
    delete playlistToRemove;

    return true;
}

Playlist *PlaylistsManager::playlist(const QString &name) const
{
    Q_D(const PlaylistsManager);
    foreach(Playlist *playlist, d->playlists)
    {
        if(playlist->name() == name) return playlist;
    }

    return 0;
}

QStringList PlaylistsManager::itemPlaylists(const QString &id, const QString& excludingPlaylistName) const
{
    Q_D(const PlaylistsManager);

    QStringList playlists;
    foreach(Playlist *playlist, d->playlists)
    {
        if(playlist->name() == excludingPlaylistName) continue;

        if(playlist->containsItem(id))
        {
            playlists.append(playlist->name());
        }
    }
    return playlists;
}

void PlaylistsManager::playlistNameChanged(const QString& name, const QString &oldName)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = qobject_cast<Playlist*>(sender());
    if(!playlist) return;

    if(d->playlistsDocument.object().contains(playlist->name())) return;

    QJsonObject obj = d->playlistsDocument.object();
    QJsonObject playlistObj = obj.value(oldName).toObject();
    obj.remove(oldName);
    if(playlistObj.isEmpty())
    {
        obj.insert(name, QString("null"));
    }
    else
    {
        obj.insert(name, playlistObj);
    }
    d->playlistsDocument = QJsonDocument(obj);

    UserManager::singleton()->updateDocument(d->playlistsDocument);

    ApplicationManager::singleton()->triggerNotification("Playlist " + oldName + " renamed to " + name);

    emit playlistNameUpdated(name, oldName);
}

void PlaylistsManager::playlistItemAdded(VideoItem *videoItem)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = qobject_cast<Playlist*>(sender());
    if(!playlist) return;

    if(d->playlistsDocument.object().value(playlist->name()).toObject().contains(videoItem->id())) return;

    JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".title", videoItem->title());
    JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".subtitle", videoItem->subTitle());
    JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".thumbnail", videoItem->thumbnail());
    JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".duration", videoItem->duration());
    JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".timestamp", videoItem->timestamp());
    UserManager::singleton()->updateDocument(d->playlistsDocument);
}

void PlaylistsManager::playlistItemsAdded(QList<VideoItem *> videoItems)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = qobject_cast<Playlist*>(sender());
    if(!playlist) return;

    foreach(VideoItem *videoItem, videoItems)
    {
        if(d->playlistsDocument.object().value(playlist->name()).toObject().contains(videoItem->id())) return;

        JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".title", videoItem->title());
        JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".subtitle", videoItem->subTitle());
        JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".thumbnail", videoItem->thumbnail());
        JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".duration", videoItem->duration());
        JsonHelper::modifyValue(d->playlistsDocument, playlist->name() + "." + videoItem->id() + ".timestamp", videoItem->timestamp());
    }

    UserManager::singleton()->updateDocument(d->playlistsDocument);
}

void PlaylistsManager::playlistItemRemoved(const QString &id)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = qobject_cast<Playlist*>(sender());
    if(!playlist) return;

    if(!d->playlistsDocument.object().value(playlist->name()).toObject().contains(id)) return;

    JsonHelper::removeKey(d->playlistsDocument, playlist->name(), id);
    UserManager::singleton()->updateDocument(d->playlistsDocument);
}

void PlaylistsManager::playlistItemsRemoved(const QStringList &ids)
{
    Q_D(PlaylistsManager);

    Playlist *playlist = qobject_cast<Playlist*>(sender());
    if(!playlist) return;

    foreach(QString id, ids)
    {
        if(!d->playlistsDocument.object().value(playlist->name()).toObject().contains(id)) continue;
        JsonHelper::removeKey(d->playlistsDocument, playlist->name(), id);
    }

    UserManager::singleton()->updateDocument(d->playlistsDocument);
}
