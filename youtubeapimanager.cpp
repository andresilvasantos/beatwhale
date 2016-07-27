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
        youtubeUpdateProcess(0),
        youtubeUrlProcess(0),
        youtubeDurationProcess(0),
        onlyMusic(false),
        orderFilter(YoutubeAPIManager::ORDER_VIEWCOUNT),
        durationFilter(YoutubeAPIManager::DURATION_ANY)
    {
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

    QProcess *youtubeUpdateProcess;
    QProcess *youtubeUrlProcess;
    QProcess *youtubeDurationProcess;

    bool onlyMusic;
    QJsonDocument searchDocument;
    QStringList excludeSuggestionIDs;
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
    d->youtubeUpdateProcess = new QProcess(this);
    d->youtubeUrlProcess = new QProcess(this);
    d->youtubeDurationProcess = new QProcess(this);

    QString youtubeDLProgramPath;

#ifdef Q_OS_UNIX
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl");
#else
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl.exe");
#endif
    if(!QFile::exists(youtubeDLProgramPath))
    {
        qDebug() << "Program Youtube-DL could not be found at" << youtubeDLProgramPath;
        exit(0);
    }
    d->youtubeUpdateProcess->setProgram(youtubeDLProgramPath);
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

void YoutubeAPIManager::setAPIKey(const QString &key)
{
    Q_D(YoutubeAPIManager);
    d->youtubeAPIKey = key;
}

void YoutubeAPIManager::shutdown()
{
    delete d_ptr;
}

void YoutubeAPIManager::ignoreSSLErrors(QNetworkReply* reply,QList<QSslError> errors)
{
   reply->ignoreSslErrors(errors);
}

void YoutubeAPIManager::setMusicOnlyFilter(const bool &onlyMusic)
{
    Q_D(YoutubeAPIManager);
    d->onlyMusic = onlyMusic;
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

void YoutubeAPIManager::search(const QString &search, const QString &nextPageToken)
{
    Q_D(YoutubeAPIManager);

    d->searchDocument = QJsonDocument();

    QString orderBy;
    switch(d->orderFilter)
    {
    case ORDER_RELEVANCE:
        orderBy = "relevance";
        break;
    case ORDER_DATE:
        orderBy = "date";
        break;
    case ORDER_RATING:
        orderBy = "rating";
        break;
    case ORDER_VIEWCOUNT:
    default:
        orderBy = "viewCount";
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

    QString pageTokenParameter = nextPageToken.isEmpty() ? "" : "&pageToken=" + nextPageToken;
    QString musicFilter = d->onlyMusic ? "&videoCategoryId=10" : "";

    QUrl url("https://www.googleapis.com/youtube/v3/search?part=snippet&q=" + search + "&type=video&videoDuration=" + videoDurationStr +
             "&maxResults=50" + musicFilter + "&order=" + orderBy + pageTokenParameter + "&key=" + d->youtubeAPIKey);
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
    QJsonArray searchItems = object.value("items").toArray();

    QJsonArray items;

    QString videosCommaSeparated;
    for(int i = 0; i < searchItems.count(); ++i)
    {
        QJsonObject resultObj = searchItems.at(i).toObject();
        QJsonObject typeObj = resultObj.value("id").toObject();
        QString videoID = typeObj.value("videoId").toString();
        videosCommaSeparated.append(videoID);
        if(i < searchItems.count() - 1) videosCommaSeparated.append(",");

        QJsonObject snippetObj = resultObj.value("snippet").toObject();

        QJsonObject videoInfoObj;
        videoInfoObj.insert("id", videoID);
        videoInfoObj.insert("title", snippetObj.value("title").toString());
        videoInfoObj.insert("thumbnail", snippetObj.value("thumbnails").toObject().value("high").toObject().value("url").toString());

        items.append(videoInfoObj);
    }

    JsonHelper::modifyValue(d->searchDocument, "items", items);

    if(object.contains("nextPageToken"))
    {
        JsonHelper::modifyValue(d->searchDocument, "nextPageToken", object.value("nextPageToken").toString());
    }

    if(searchItems.count()) searchVideosDuration(videosCommaSeparated);
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
    QJsonArray searchItems = object.value("items").toArray();

    for(int i = 0; i < searchItems.count(); ++i)
    {
        QJsonObject resultObj = searchItems.at(i).toObject();
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

        QJsonArray items = d->searchDocument.object().value("items").toArray();
        QJsonObject item = items.at(i).toObject();
        items.removeAt(i);

        item.insert("duration", duration);
        items.insert(i, item);

        JsonHelper::modifyValue(d->searchDocument, "items", items);
    }

    emit searchSuccess(QString(d->searchDocument.toJson()));
}

void YoutubeAPIManager::searchVideosDurationError(QNetworkReply::NetworkError error)
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    emit searchFailed();

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

    emit searchFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::suggestion(const QString &id, const QStringList excludeSuggestionIDs)
{
    Q_D(YoutubeAPIManager);

    d->excludeSuggestionIDs = excludeSuggestionIDs;

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

    QString musicFilter = d->onlyMusic ? "&videoCategoryId=10" : "";

    QUrl url("https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=30&relatedToVideoId=" + id + "&videoDuration=" + videoDurationStr +
             musicFilter + "&key=" + d->youtubeAPIKey);
    qDebug() << url;

    QNetworkRequest request(url);
    QNetworkReply* reply = d->networkManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(suggestionFinished()));
    connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(suggestionError(QNetworkReply::NetworkError)));

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(TIMEOUT_INTERVAL);
    timer->start();
    connect(timer, SIGNAL(timeout()), SLOT(suggestionTimeout()));

    d->repliesTimeoutMap.insert(timer, reply);
}

void YoutubeAPIManager::suggestionFinished()
{
    Q_D(YoutubeAPIManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    removeTimer(reply);
    delete reply;

    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject object = document.object();
    QJsonArray searchItems = object.value("items").toArray();

    bool alreadySuggested = true;
    QString selectedID;
    QJsonObject resultObj;

    while(alreadySuggested && !searchItems.isEmpty())
    {
        int selectedIndex = rand() % searchItems.count();

        resultObj = searchItems.takeAt(selectedIndex).toObject();
        QJsonObject typeObj = resultObj.value("id").toObject();
        selectedID = typeObj.value("videoId").toString();
        if(!d->excludeSuggestionIDs.contains(selectedID)) alreadySuggested = false;
    }

    if(selectedID.isEmpty() || searchItems.isEmpty())
    {
        emit suggestionFailed();
        return;
    }

    QJsonObject snippetObj = resultObj.value("snippet").toObject();
    QString thumbnail = snippetObj.value("thumbnails").toObject().value("high").toObject().value("url").toString();
    QString title = snippetObj.value("title").toString();

    suggestionVideoDuration(selectedID, title, thumbnail);
}

void YoutubeAPIManager::suggestionError(QNetworkReply::NetworkError error)
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    emit suggestionFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::suggestionTimeout()
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = qobject_cast<QTimer*>(sender());

    if(!timer) return;

    QNetworkReply *reply = d->repliesTimeoutMap.value(timer, 0);
    if(!reply) return;

    emit suggestionFailed();

    removeTimer(reply);
    delete reply;
}
void YoutubeAPIManager::suggestionVideoDuration(const QString &id, const QString &title, const QString &thumbnail)
{
    Q_D(YoutubeAPIManager);

    QUrl url("https://www.googleapis.com/youtube/v3/videos?id=" + id + "&part=contentDetails&key=" + d->youtubeAPIKey);
    QNetworkRequest request(url);
    QNetworkReply* reply = d->networkManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(suggestionVideoDurationFinished()));
    connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(suggestionVideoDurationError(QNetworkReply::NetworkError)));

    reply->setProperty("id", id);
    reply->setProperty("title", title);
    reply->setProperty("thumbnail", thumbnail);

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(TIMEOUT_INTERVAL);
    timer->start();
    connect(timer, SIGNAL(timeout()), SLOT(suggestionVideoDurationTimeout()));

    d->repliesTimeoutMap.insert(timer, reply);
}

void YoutubeAPIManager::suggestionVideoDurationFinished()
{
    Q_D(YoutubeAPIManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    removeTimer(reply);

    QString id = reply->property("id").toString();
    QString title = reply->property("title").toString();
    QString thumbnail = reply->property("thumbnail").toString();

    delete reply;

    QJsonDocument document = QJsonDocument::fromJson(replyBA);

    QJsonObject object = document.object();
    QJsonArray searchItems = object.value("items").toArray();

    QJsonObject resultObj = searchItems.at(0).toObject();
    QJsonObject detailsObj = resultObj.value("contentDetails").toObject();
    QString videoDuration = detailsObj.value("duration").toString();

    if(!videoDuration.startsWith("PT"))
    {
        emit suggestionFailed();
        return;
    }

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

    emit suggestionSuccess(id, title, thumbnail, duration);
}

void YoutubeAPIManager::suggestionVideoDurationError(QNetworkReply::NetworkError error)
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    emit suggestionFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::suggestionVideoDurationTimeout()
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = qobject_cast<QTimer*>(sender());

    if(!timer) return;

    QNetworkReply *reply = d->repliesTimeoutMap.value(timer, 0);
    if(!reply) return;

    emit suggestionFailed();

    removeTimer(reply);
    delete reply;
}

void YoutubeAPIManager::videoUrl(const QString &videoID)
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeUpdateProcess->isOpen()) return;

    if(d->youtubeUrlProcess->isOpen()) d->youtubeUrlProcess->close();

    QStringList arguments;
    arguments << "--get-url" << "https://www.youtube.com/watch?v=" + videoID;
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

    if(d->youtubeDurationProcess->isOpen() || d->youtubeUpdateProcess->isOpen())
    {
        d->videoDurationRequests.append(videoID);
        return;
    }

    QStringList arguments;
    arguments << "--get-duration" << "https://www.youtube.com/watch?v=" + videoID;
    d->youtubeDurationProcess->setProperty("videoID", videoID);
    d->youtubeDurationProcess->setArguments(arguments);
    d->youtubeDurationProcess->open();

    connect(d->youtubeDurationProcess, SIGNAL(finished(int)), SLOT(videoDurationFinished()));
    connect(d->youtubeDurationProcess, SIGNAL(readyReadStandardOutput()), SLOT(videoDurationFinished()));
}

void YoutubeAPIManager::videoDurationFinished()
{
    Q_D(YoutubeAPIManager);

    if(d->youtubeDurationProcess != sender()) return;

    disconnect(d->youtubeDurationProcess, SIGNAL(finished(int)), this, SLOT(videoDurationFinished()));
    disconnect(d->youtubeDurationProcess, SIGNAL(readyReadStandardOutput()), this, SLOT(videoDurationFinished()));

    QString duration = d->youtubeDurationProcess->readAll();
    QString videoID = d->youtubeDurationProcess->property("videoID").toString();


    d->youtubeDurationProcess->close();

    if(!duration.isEmpty())
    {
        duration.remove("\n");
        duration.remove("\r");
        emit videoDurationSuccess(videoID, duration);
    }

    if(d->videoDurationRequests.count())
    {
        QString videoID = d->videoDurationRequests.takeFirst();
        videoDuration(videoID);
    }
}

void YoutubeAPIManager::updateYoutubeDL()
{
    Q_D(YoutubeAPIManager);

    qDebug() << "Youtube DL Update...";

    QStringList arguments;
    arguments << "--update";
    d->youtubeUpdateProcess->setArguments(arguments);
    d->youtubeUpdateProcess->open();

    connect(d->youtubeUpdateProcess, SIGNAL(finished(int)), SLOT(youtubeDLUpdateFinished()));
    connect(d->youtubeUpdateProcess, SIGNAL(readyReadStandardError()), SLOT(youtubeDLUpdateError()));
}

void YoutubeAPIManager::youtubeDLUpdateFinished()
{
    Q_D(YoutubeAPIManager);

    qDebug() << "Youtube DL Update Finished";

    if(d->youtubeUpdateProcess != sender()) return;

    qDebug() << d->youtubeUpdateProcess->readAll();

    QString youtubeDLProgramPath;
    QString youtubeDLNewProgramPath;
    QString youtubeDLBatPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl-updater.bat");

#ifdef Q_OS_MAC
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl");
    youtubeDLNewProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl.new");
#else
    youtubeDLProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl.exe");
    youtubeDLNewProgramPath = QString(QCoreApplication::applicationDirPath() + "/" + "youtube-dl.exe.new");
#endif

    if(QFile::exists(youtubeDLNewProgramPath))
    {
        QFile::remove(youtubeDLProgramPath);
        QFile::remove(youtubeDLBatPath);
        QFile::rename(youtubeDLNewProgramPath, youtubeDLProgramPath);
    }

    disconnect(d->youtubeUpdateProcess, SIGNAL(finished(int)), this, SLOT(videoDurationFinished()));
    disconnect(d->youtubeUpdateProcess, SIGNAL(readyReadStandardError()), this, SLOT(videoDurationFinished()));

    d->youtubeUpdateProcess->close();

    emit youtubeDLUpdateSuccess();
}

void YoutubeAPIManager::youtubeDLUpdateError()
{
    Q_D(YoutubeAPIManager);

    qDebug() << "Youtube DL Update Error";

    if(d->youtubeUpdateProcess != sender()) return;

    disconnect(d->youtubeUpdateProcess, SIGNAL(finished(int)), this, SLOT(videoDurationFinished()));
    disconnect(d->youtubeUpdateProcess, SIGNAL(readyReadStandardError()), this, SLOT(videoDurationFinished()));

    d->youtubeUpdateProcess->close();

    emit youtubeDLUpdateFailed();
}

void YoutubeAPIManager::removeTimer(QNetworkReply *reply)
{
    Q_D(YoutubeAPIManager);

    QTimer *timer = d->repliesTimeoutMap.key(reply, 0);
    if(timer) d->repliesTimeoutMap.remove(timer);
    delete timer;
}
