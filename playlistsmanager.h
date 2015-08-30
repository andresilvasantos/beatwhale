#ifndef PLAYLISTSMANAGER_H
#define PLAYLISTSMANAGER_H

#include <QObject>

class QQmlContext;
class QQmlEngine;
class QJSEngine;
class Playlist;
class VideoItem;
class PlaylistsManagerPrivate;
class PlaylistsManager : public QObject
{
    Q_OBJECT
public:
    static PlaylistsManager* singleton();
    static void declareQML();

    void setDocument(const QJsonDocument& document);

    Q_INVOKABLE bool isFavorited(const QString &id) const;
    Q_INVOKABLE void addToFavorites(const QString& id, const QString& title, const QString& subTitle, const QString& thumbnail, const QString &duration, QString timestamp = QString());
    Q_INVOKABLE bool removeFromFavorites(const QString& id);
    Q_INVOKABLE QList<QObject*> favorites() const;

    Q_INVOKABLE Playlist* createPlaylist();
    Q_INVOKABLE bool deletePlaylist(const QString& name);

    Q_INVOKABLE QList<QString> playlistNames() const;
    void addPlaylist(Playlist *playlist);
    Q_INVOKABLE Playlist* playlist(const QString& name) const;

signals:
    void favoritesChanged();

    void playlistAdded(const QString& name);
    void playlistCreated(const QString& name);
    void playlistRemoved(const QString& name);
    void playlistNameUpdated(const QString& name, const QString& oldName);

public slots:

protected slots:
    void playlistNameChanged(const QString& name, const QString &oldName);

    void playlistItemAdded(VideoItem *videoItem);
    void playlistItemsAdded(QList<VideoItem*> videoItems);
    void playlistItemRemoved(const QString& id);
    void playlistItemsRemoved(const QStringList& ids);

protected:

private:
    explicit PlaylistsManager(QObject *parent = 0);
    virtual ~PlaylistsManager();

    static PlaylistsManager *_singleton;

    Q_DECLARE_PRIVATE(PlaylistsManager)
    PlaylistsManagerPrivate * const d_ptr;

};

static QObject *qmlPlaylistsManagerSingleton(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return PlaylistsManager::singleton();
}

#endif // PLAYLISTSMANAGER_H
