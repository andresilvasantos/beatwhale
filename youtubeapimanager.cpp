#include "youtubeapimanager.h"

#include <jsonhelper.h>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QtQml>
#include <QDebug>
#include <QProcess>

#define TIMEOUT_INTERVAL 20000

YoutubeAPIManager *YoutubeAPIManager::_singleton = 0;

class YoutubeAPIManagerPrivate
{
public:
    YoutubeAPIManagerPrivate() :
        networkManager(0),
        youtubeUrlProcess(0),
        youtubeDurationProcess(0),
        orderFilter(YoutubeAPIManager::ORDER_RELEVANCE),
        durationFilter(YoutubeAPIManager::DURATION_ANY)
    {
        QSettings settings("beatwhale_config.ini", QSettings::IniFormat);
        youtubeAPIKey = settings.value("youtube_key").toString();
    }

    virtual ~YoutubeAPIManagerPrivate()
    {
        if(networkManager) delete networkManager;

        foreach(QTimer *timer, repliesTimeoutMap.keys())
        {
            delete timer;
        }

        if(youtubeUrlProcess) delete youtubeUrlProcess;
        if(youtubeDurationProcess) delete youtubeDurationProcess;
    }

    QString youtubeAPIKey;

    QNetworkAccessManager *networkManager;

    QMap<QTimer*, QNetworkReply*> repliesTimeoutMap;

    QProcess *youtubeUrlProcess;
    QProcess *youtubeDurationProcess;

    QJsonDocument searchDocument;
    QStringList videoDurationRequests;

    YoutubeAPIManager::OrderFilter orderFilter;
    YoutubeAPIManager::DurationFilter durationFilter;
};

YoutubeAPIManager::YoutubeAPIManager(QObject *parent) :
    QObject(parent),
    d_ptr(new YoutubeAPIManagerPrivate)
{
    Q_D(YoutubeAPIManager);

    d->networkManager = new QNetworkAccessManager(this);
    d->youtubeUrlProcess = new QProcess(this);
    d->youtubeDurationProcess = new QProcess(this);

    QString youtubeDLProgramPath;

#ifdef Q_OS_MAC
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl");
#else
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl.exe");
#endif
    if(!QFile::exists(youtubeDLProgramPath))
    {
        qDebug() << "Program Youtube-DL could not be found at" << youtubeDLProgramPath;
        exit(0);
    }
    d->youtubeUrlProcess->setProgram(youtubeDLProgramPath);
    d->youtubeDurationProcess->setProgram(youtubeDLProgramPath);

    QObject::connect(d->networkManager,SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),SLOT(ignoreSSLErrors(QNetworkReply*,QList<QSslError>)));
}

YoutubeAPIManager::~YoutubeAPIManager()
{
    shutdown();
}

YoutubeAPIManager *YoutubeAPIManager::singleton()
{
    if(!_singleton)
    {
        _singleton = new YoutubeAPIManager;
    }
    return _singleton;
}

void YoutubeAPIManager::declareQML()
{
    qmlRegisterSingletonType<YoutubeAPIManager>("BeatWhaleAPI", 1, 0, "YoutubeAPI", qmlYoutubeAPIManagerSingleton);
}

void YoutubeAPIManager::shutdown()
{
    delete d_ptr;
}

void YoutubeAPIManager::ignoreSSLErrors(QNetworkReply* reply,QList<QSslError> errors)
{
   reply->ignoreSslErrors(errors);
}

void YoutubeAPIManager::setOrderFilter(YoutubeAPIManager::OrderFilter orderFilter)
{
    Q_D(YoutubeAPIManager);
    d->orderFilter = orderFilter;
}

void YoutubeAPIManager::setDurationFilter(YoutubeAPIManager::DurationFilter durationFilter)
{
    Q_D(YoutubeAPIManager);
    d->durationFilter = durationFilter;
}

void YoutubeAPIManager::search(const QString &search)
{
    Q_D(YoutubeAPIManager);

    d->searchDocument = QJsonDocument();

    QString orderBy;
    switch(d->orderFilter)
    {
    case ORDER_DATE:
        orderBy = "date";
        break;
    case ORDER_RATING:
        orderBy = "rating";
        break;
    case ORDER_VIEWCOUNT:
        orderBy = "viewCount";
        break;
    case ORDER_RELEVANCE:
    default:
        orderBy = "relevance";
        break;
    }

    QString videoDurationStr;
    switch(d->durationFilter)
    {
    case DURATION_SHORT:
        videoDurationStr = "short";
        break;
    case DURATION_MEDIUM:
        videoDurationStr = "medium";
        break;
    case DURATION_LONG:
        videoDurationStr = "long";
        break;
    case DURATION_ANY:
    default:
        videoDurationStr = "any";
        break;
    }

    QUrl url("https://www.googleapis.com/youtube/v3/search?part=snippet&q=" + search + "&type=video&videoDuration=" + videoDurationStr +
             "&maxResults=50&order=" + orderBy + "&key=" + d->youtubeAPIKey);
    qDebug() << url;

    QNetworkRequest request(url);
    QNetworkReply* reply = d->networkManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(searchFinished()));
    connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(searchError(QNetworkReply::NetworkError)));

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(TIMEOUT_INTERVAL);
    timer->start();
    connect(timer, SIGNAL(timeout()), SLOT(searchTimeout()));

    d->repliesTimeoutMap.insert(timer, reply);
}

void YoutubeAPIManager::search(const QString &search, const QString &nextPageToken)
{
    Q_D(YoutubeAPIManager);

    d->searchDocument = QJsonDocument();

    QString orderBy;
    switch(d->orderFilter)
    {
    case ORDER_DATE:
        orderBy = "date";
        break;
    case ORDER_RATING:
        orderBy = "rating";
        break;
    case ORDER_VIEWCOUNT:
        orderBy = "viewCount";
        break;
    case ORDER_RELEVANCE:
    default:
        orderBy = "relevance";
        break;
    }

    QString videoDurationStr;
    switch(d->durationFilter)
    {
    case DURATION_SHORT:
        videoDurationStr = "short";
        break;
    case DURATION_MEDIUM:
        videoDurationStr = "medium";
        break;
    case DURATION_LONG:
        videoDurationStr = "long";
        break;
    case DURATION_ANY:
    default:
        videoDurationStr = "any";
        break;
    }

    QUrl url("https://www.googleapis.com/youtube/v3/search?part=snippet&q=" + search + "&type=video&videoDuration=" + videoDurationStr +
             "&maxResults=50&order=" + orderBy + "&pageToken=" + nextPageToken + "&key=" + d->youtubeAPIKey);
    qDebug() << url;

    QNetworkRequest request(url);
    QNetworkReply* reply = d->networkManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(searchFinished()));
    connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(searchError(QNetworkReply::NetworkError)));

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(TIMEOUT_INTERVAL);
    timer->start();
    connect(timer, SIGNAL(timeout()), SLOT(searchTimeout()));

    d->repliesTimeoutMap.insert(timer, reply);
}

void YoutubeAPIManager::searchFinished()
{
    Q_D(YoutubeAPIManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    removeTimer(reply);
    delete reply;

    QJsonDocument document = QJsonDocument::fromJson(replyBA);

    QJsonObject object = document.object();
    QJsonArray items = object.value("items").toArray();

    QString videosCommaSeparated;
    for(int i = 0; i < items.count(); ++i)
    {
        QJsonObject resultObj = items.at(i).toObject();
        QJsonObject typeObj = resultObj.value("id").toObject();
        QString videoID = typeObj.value("videoId").toString();
        videosCommaSeparated.append(videoID);
        if(i < items.count() - 1) videosCommaSeparated.append(",");

        QJsonObject snippetObj = resultObj.value("snippet").toObject();
        JsonHelper::modifyValue(d->searchDocument, videoID + ".title", snippetObj.value("title").toString());
        JsonHelper::modifyValue(d->searchDocument, videoID + ".thumbnail", snippetObj.value("thumbnails").toObject().value("high").toObject().value("url").toString());
    }

    if(object.contains("nextPageToken"))
    {
        JsonHelper::modifyValue(d->searchDocument, "nextPageToken", object.value("nextPageToken").toString());
    }

    if(items.count()) searchVideosDuration(videosCommaSeparated);
    else emit searchSuccess(QString(d->searchDocument.toJson()));
}

void YoutubeAPIManager::searchError(QNetworkReply::NetworkError error)
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    emit searchFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::searchTimeout()
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = qobject_cast<QTimer*>(sender());

    if(!timer) return;

    QNetworkReply *reply = d->repliesTimeoutMap.value(timer, 0);
    if(!reply) return;

    emit searchFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::searchVideosDuration(const QString &videosIDs)
{
    Q_D(YoutubeAPIManager);

    QUrl url("https://www.googleapis.com/youtube/v3/videos?id=" + videosIDs + "&part=contentDetails&key=" + d->youtubeAPIKey);
    QNetworkRequest request(url);
    QNetworkReply* reply = d->networkManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(searchVideosDurationFinished()));
    connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(searchVideosDurationError(QNetworkReply::NetworkError)));

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(TIMEOUT_INTERVAL);
    timer->start();
    connect(timer, SIGNAL(timeout()), SLOT(searchVideosDurationTimeout()));

    d->repliesTimeoutMap.insert(timer, reply);
}


void YoutubeAPIManager::searchVideosDurationFinished()
{
    Q_D(YoutubeAPIManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    removeTimer(reply);
    delete reply;

    QJsonDocument document = QJsonDocument::fromJson(replyBA);

    QJsonObject object = document.object();
    QJsonArray items = object.value("items").toArray();

    for(int i = 0; i < items.count(); ++i)
    {
        QJsonObject resultObj = items.at(i).toObject();
        QString videoID = resultObj.value("id").toString();
        QJsonObject detailsObj = resultObj.value("contentDetails").toObject();
        QString videoDuration = detailsObj.value("duration").toString();

        if(!videoDuration.startsWith("PT")) continue;

        videoDuration = videoDuration.remove(0, 2);
        QString hoursStr, minutesStr, secondsStr;

        //Hours
        if(videoDuration.contains("H"))
        {
            hoursStr = videoDuration.left(videoDuration.indexOf("H"));
            if(hoursStr.count() < 2) hoursStr.insert(0, "0");
            videoDuration = videoDuration.remove(0, videoDuration.indexOf("H") + 1);
        }

        //Minutes
        {
            if(videoDuration.contains("M")) {
                minutesStr = videoDuration.left(videoDuration.indexOf("M"));
            }
            while (minutesStr.count() < 2) minutesStr.insert(0, "0");
            videoDuration = videoDuration.remove(0, videoDuration.indexOf("M") + 1);
        }

        //Seconds
        {
            secondsStr = videoDuration.left(videoDuration.indexOf("S"));
            while (secondsStr.count() < 2) secondsStr.insert(0, "0");
        }

        QString duration;
        if(hoursStr.count()) duration.append(hoursStr + ":");
        if(minutesStr.count()) duration.append(minutesStr + ":");
        duration.append(secondsStr);

        JsonHelper::modifyValue(d->searchDocument, videoID + ".duration", duration);
    }

    emit searchSuccess(QString(d->searchDocument.toJson()));
}

void YoutubeAPIManager::searchVideosDurationError(QNetworkReply::NetworkError error)
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::searchVideosDurationTimeout()
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = qobject_cast<QTimer*>(sender());

    if(!timer) return;

    QNetworkReply *reply = d->repliesTimeoutMap.value(timer, 0);
    if(!reply) return;

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::videoUrl(const QString &videoID)
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeUrlProcess->isOpen()) d->youtubeUrlProcess->close();

    QStringList arguments;
    arguments << "--get-url" << "https://www.youtube.com/watch?v=" + videoID;// << "-f" << "bestvideo+bestaudio";
    d->youtubeDurationProcess->setProperty("videoID", videoID);
    d->youtubeUrlProcess->setArguments(arguments);
    d->youtubeUrlProcess->open();

    connect(d->youtubeUrlProcess, SIGNAL(readyReadStandardOutput()), SLOT(videoUrlFinished()));
    connect(d->youtubeUrlProcess, SIGNAL(readyReadStandardError()), SLOT(videoUrlError()));
}

void YoutubeAPIManager::videoUrlFinished()
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeUrlProcess != sender()) return;

    disconnect(d->youtubeUrlProcess, SIGNAL(readyReadStandardOutput()), this, SLOT(videoUrlFinished()));
    disconnect(d->youtubeUrlProcess, SIGNAL(readyReadStandardError()), this, SLOT(videoUrlError()));

    QString reply = d->youtubeUrlProcess->readAll();
    QString videoID = d->youtubeDurationProcess->property("videoID").toString();

    d->youtubeUrlProcess->close();

    reply = reply.replace("\n", "");
    reply = reply.replace("\r", "");
    reply = reply.replace(" ", "");

    emit videoUrlSuccess(videoID, reply);
}

void YoutubeAPIManager::videoUrlError()
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeUrlProcess != sender()) return;

    disconnect(d->youtubeUrlProcess, SIGNAL(readyReadStandardOutput()), this, SLOT(videoUrlFinished()));
    disconnect(d->youtubeUrlProcess, SIGNAL(readyReadStandardError()), this, SLOT(videoUrlError()));

    QString videoID = d->youtubeDurationProcess->property("videoID").toString();
    emit videoUrlFailed(videoID);
}

void YoutubeAPIManager::videoDuration(const QString &videoID)
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeDurationProcess->isOpen())
    {
        d->videoDurationRequests.append(videoID);
        return;
    }

    QStringList arguments;
    arguments << "--get-duration" << "https://www.youtube.com/watch?v=" + videoID;
    d->youtubeDurationProcess->setProperty("videoID", videoID);
    d->youtubeDurationProcess->setArguments(arguments);
    d->youtubeDurationProcess->open();

    connect(d->youtubeDurationProcess, SIGNAL(readyReadStandardOutput()), SLOT(videoDurationFinished()));
}

void YoutubeAPIManager::videoDurationFinished()
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeDurationProcess != sender()) return;

    disconnect(d->youtubeDurationProcess, SIGNAL(readyReadStandardOutput()), this, SLOT(videoDurationFinished()));

    QString duration = d->youtubeDurationProcess->readAll();
    QString videoID = d->youtubeDurationProcess->property("videoID").toString();

    d->youtubeDurationProcess->close();


    emit videoDurationSuccess(videoID, duration);


    if(d->videoDurationRequests.count())
    {
        QString videoID = d->videoDurationRequests.takeFirst();
        videoDuration(videoID);
    }
}

void YoutubeAPIManager::removeTimer(QNetworkReply *reply)
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = d->repliesTimeoutMap.key(reply, 0);
    if(timer) d->repliesTimeoutMap.remove(timer);
    delete timer;
}
