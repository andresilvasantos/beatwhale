#ifndef YOUTUBEAPIMANAGER_H
#define YOUTUBEAPIMANAGER_H

#include <QObject>

#include <QNetworkReply>

class QQmlEngine;
class QJSEngine;
class YoutubeAPIManagerPrivate;
class YoutubeAPIManager : public QObject
{
    Q_OBJECT

    Q_ENUMS(OrderFilter)
    Q_ENUMS(DurationFilter)

public:
    enum OrderFilter
    {
        ORDER_VIEWCOUNT,
        ORDER_RELEVANCE,
        ORDER_DATE,
        ORDER_RATING
    };

    enum DurationFilter
    {
        DURATION_ANY,
        DURATION_SHORT,
        DURATION_MEDIUM,
        DURATION_LONG
    };

    static YoutubeAPIManager* singleton();
    static void declareQML();

    void setAPIKey(const QString& key);

    void shutdown();

    void removeTimer(QNetworkReply *reply);


    Q_INVOKABLE void setOrderFilter(OrderFilter orderFilter);
    Q_INVOKABLE void setDurationFilter(DurationFilter durationFilter);

signals:
    void searchSuccess(const QString& documentString);
    void searchFailed();

    void videoUrlFailed(const QString& id);
    void videoUrlSuccess(const QString& id, const QString& url);
    void videoDurationFailed();
    void videoDurationSuccess(const QString& id, const QString& duration);

public slots:
    void ignoreSSLErrors(QNetworkReply *reply, QList<QSslError> errors);

    Q_INVOKABLE void search(const QString& search);
    Q_INVOKABLE void search(const QString& search, const QString& nextPageToken);
    Q_INVOKABLE void videoUrl(const QString& videoID);
    Q_INVOKABLE void videoDuration(const QString& videoID);

private slots:
    void searchFinished();
    void searchError(QNetworkReply::NetworkError error);
    void searchTimeout();

    void searchVideosDuration(const QString& videosIDs);
    void searchVideosDurationFinished();
    void searchVideosDurationError(QNetworkReply::NetworkError error);
    void searchVideosDurationTimeout();

    void videoUrlFinished();
    void videoUrlError();

    void videoDurationFinished();

private:
    explicit YoutubeAPIManager(QObject *parent = 0);
    virtual ~YoutubeAPIManager();

    static YoutubeAPIManager *_singleton;

    Q_DECLARE_PRIVATE(YoutubeAPIManager)
    YoutubeAPIManagerPrivate * const d_ptr;

};

static QObject *qmlYoutubeAPIManagerSingleton(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return YoutubeAPIManager::singleton();
}

#endif // YOUTUBEAPIMANAGER_H
