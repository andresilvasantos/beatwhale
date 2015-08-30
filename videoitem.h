#ifndef VIDEOITEM_H
#define VIDEOITEM_H

#include <QObject>

class VideoItemPrivate;
class VideoItem : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString id READ id WRITE setID)
    Q_PROPERTY(QString title READ title WRITE setTitle)
    Q_PROPERTY(QString subTitle READ subTitle WRITE setSubTitle)
    Q_PROPERTY(QString thumbnail READ thumbnail WRITE setThumbnail)
    Q_PROPERTY(QString duration READ duration WRITE setDuration)
    Q_PROPERTY(QString timestamp READ timestamp WRITE setTimestamp)

public:
    explicit VideoItem(QObject *parent = 0);
    virtual ~VideoItem();

    static void declareQML();

    QString id() const;
    void setID(const QString& id);

    QString title() const;
    void setTitle(const QString& title);

    QString subTitle() const;
    void setSubTitle(const QString& subTitle);

    QString thumbnail() const;
    void setThumbnail(const QString& thumbnail);

    QString duration() const;
    void setDuration(const QString& duration);

    QString timestamp() const;
    void setTimestamp(const QString& timestamp);

signals:

public slots:

private:
    Q_DECLARE_PRIVATE(VideoItem)
    VideoItemPrivate * const d_ptr;

};

#endif // VIDEOITEM_H
