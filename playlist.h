#ifndef PLAYLIST_H
#define PLAYLIST_H

#include <QObject>

class VideoItem;
class PlaylistPrivate;
class Playlist : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)

public:
    explicit Playlist(QObject *parent = 0);
    virtual ~Playlist();

    static void declareQML();

    QString name() const;
    void setName(const QString& name);

    Q_INVOKABLE bool containsItem(const QString& id) const;

    Q_INVOKABLE void addItem(const QString& id, const QString& title, const QString& subTitle, const QString& thumbnail,
                             const QString& duration, QString timestamp = QString());
    Q_INVOKABLE void addItems(const QStringList& ids, const QStringList& titles, const QStringList& subTitles, const QStringList& thumbnails,
                             const QStringList& durations, QString timestamp = QString());
    Q_INVOKABLE bool removeItem(const QString& id);
    Q_INVOKABLE void removeItems(const QStringList& id);
    Q_INVOKABLE QList<QObject*> items() const;

signals:
    void nameChanged(const QString& name, const QString& oldName);
    void playlistChanged();

    void itemAdded(VideoItem*);
    void itemsAdded(QList<VideoItem*>);
    void itemRemoved(const QString& id);
    void itemsRemoved(const QStringList& ids);

public slots:

private:
    Q_DECLARE_PRIVATE(Playlist)
    PlaylistPrivate * const d_ptr;

};

#endif // PLAYLIST_H
