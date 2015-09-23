#include "usermanager.h"
#include "playlistsmanager.h"
#include "playlist.h"
#include "applicationmanager.h"
#include "videoitem.h"
#include "youtubeapimanager.h"

#include <databasemanager.h>
#include <jsonhelper.h>

#include <QFile>
#include <QTextStream>
#include <QtQml>
#include <QDebug>

UserManager *UserManager::_singleton = 0;

class UserManagerPrivate
{
public:
    UserManagerPrivate() :
        networkManager(0),
        queueFile(0),
        firstTime(true),
        waitingForChanges(false),
        documentReadyForUpload(false),
        localSettings(QSettings::IniFormat, QSettings::UserScope, "BeatWhale", "beatwhale_app")
    {
    }

    virtual ~UserManagerPrivate()
    {
        if(networkManager) delete networkManager;

        if(queueFile)
        {
            queueFile->close();
            delete queueFile;
        }
    }

    QNetworkAccessManager *networkManager;

    QSettings localSettings;

    QString username;
    QString password;
    QString newPassword;
    QString email;

    QString currentRevision;
    QString currentSettingsRevision;
    QJsonDocument videosDocument;
    QJsonDocument documentToUpload;

    bool firstTime;
    bool waitingForChanges;
    bool documentReadyForUpload;

    QFile *queueFile;
    QTextStream queueFileStream;
    QStringList queueStringList;
};

UserManager::UserManager(QObject *parent) :
    QObject(parent),
    d_ptr(new UserManagerPrivate)
{
}

UserManager::~UserManager()
{
    delete d_ptr;
}

UserManager *UserManager::singleton()
{
    if(!_singleton)
    {
        _singleton = new UserManager;
    }
    return _singleton;
}

void UserManager::declareQML()
{
    qmlRegisterSingletonType<UserManager>("BeatWhaleAPI", 1, 0, "UserManager", qmlUserManagerSingleton);
}

QString UserManager::storedUsername() const
{
    Q_D(const UserManager);
    return d->localSettings.value("login/credentials/username").toString();
}

QString UserManager::storedPassword() const
{
    Q_D(const UserManager);
    return d->localSettings.value("login/credentials/password").toString();
}

QString UserManager::username() const
{
    Q_D(const UserManager);
    return d->username;
}

QString UserManager::password() const
{
    Q_D(const UserManager);
    return d->password;
}

QString UserManager::email() const
{
    Q_D(const UserManager);
    return d->email;
}

bool UserManager::rememberCredentials() const
{
    Q_D(const UserManager);
    return d->localSettings.value("login/remember").toBool();
}

void UserManager::setRememberCredentials(const bool &remember)
{
    Q_D(UserManager);

    if(remember)
    {
        d->localSettings.setValue("login/remember", true);
        d->localSettings.setValue("login/credentials/username", d->username);
        d->localSettings.setValue("login/credentials/password", d->password);
    }
    else
    {
        d->localSettings.setValue("login/remember", false);
        d->localSettings.remove("login/credentials");
    }
}

bool UserManager::musicOnlyFilter() const
{
    Q_D(const UserManager);
    return d->localSettings.value(d->username + "-general/music_only_filter", false).toBool();
}

void UserManager::setMusicOnlyFilter(const bool &musicOnly)
{
    Q_D(UserManager);

    YoutubeAPIManager::singleton()->setMusicOnlyFilter(musicOnly);
    d->localSettings.beginGroup(d->username + "-general");
    d->localSettings.setValue("music_only_filter", musicOnly);
    d->localSettings.endGroup();
    emit musicOnlyFilterChanged(musicOnly);
}

int UserManager::orderFilter() const
{
    Q_D(const UserManager);
    return d->localSettings.value(d->username + "-general/order_filter", 0).toInt();
}

void UserManager::setOrderFilter(const int &orderFilter)
{
    Q_D(UserManager);

    YoutubeAPIManager::singleton()->setOrderFilter(YoutubeAPIManager::OrderFilter(orderFilter));
    d->localSettings.beginGroup(d->username + "-general");
    d->localSettings.setValue("order_filter", orderFilter);
    d->localSettings.endGroup();
    emit orderFilterChanged(orderFilter);
}

int UserManager::durationFilter() const
{
    Q_D(const UserManager);
    return d->localSettings.value(d->username + "-general/duration_filter", 0).toInt();
}

void UserManager::setDurationFilter(const int &durationFilter)
{
    Q_D(UserManager);

    YoutubeAPIManager::singleton()->setDurationFilter(YoutubeAPIManager::DurationFilter(durationFilter));
    d->localSettings.beginGroup(d->username + "-general");
    d->localSettings.setValue("duration_filter", durationFilter);
    d->localSettings.endGroup();
    emit durationFilterChanged(durationFilter);
}

QString UserManager::generateActivationCode()
{
    QString code;

    while(code.count() < 10)
    {
        code.append(QString::number(rand() % 10));
    }

    return code;
}

void UserManager::createAccountVerification(const QString &username, const QString &email, const QString &code)
{
    Q_D(UserManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "sendemailactivation.php?email=" + email.toLower() + "&username=" + username + "&code=" + code);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(createAccountVerificationReply()));
}

void UserManager::createAccountVerificationReply()
{
    Q_D(UserManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    bool success = obj.value("success").toBool();

    if(success) emit createAccountVerificationSuccess();
    else emit createAccountVerificationFailed(obj.value("message").toString("Problem connecting to BeatWhale API. Please try again."));

    delete reply;
}

void UserManager::createAccount(const QString &username, const QString &password, const QString &email)
{
    Q_D(UserManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    QString randomHex;
    for(int i = 0; i < 16; i++)
    {
        int n = qrand() % 16;
        randomHex.append(QString::number(n,16));
    }

    QByteArray salt = QByteArray(randomHex.toStdString().c_str()).toHex();
    QString hash = QString(QCryptographicHash::hash((password.toStdString().c_str() + salt),QCryptographicHash::Sha1).toHex());

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "createaccount.php?email=" + email.toLower() + "&username=" + username + "&hash=" + hash + "&salt=" + salt);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(createAccountReply()));
}

void UserManager::createAccountReply()
{
    Q_D(UserManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    bool success = obj.value("success").toBool();

    if(success)
    {
        d->localSettings.clear();
        emit createAccountSuccess();
    }
    else
    {
        emit createAccountFailed(obj.value("message").toString("Problem connecting to BeatWhale API. Please try again."));
    }

    delete reply;
}

void UserManager::deleteAccount()
{
    Q_D(UserManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "deleteaccount.php?email=" + d->email.toLower() + "&username=" + d->username + "&rev=" + d->currentSettingsRevision);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(deleteAccountReply()));
}

void UserManager::deleteAccountReply()
{
    Q_D(UserManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    bool success = obj.value("success").toBool();

    delete reply;

    if(!success)
    {
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        emit deleteAccountFailed(obj.value("message").toString("Problem connecting to BeatWhale API. Please try again."));
        return;
    }

    d->localSettings.setValue("login/remember", false);
    d->localSettings.remove("login/credentials");

    stopListeningToChanges();

    d->username = "";
    d->password = "";
    d->email = "";

    emit deleteAccountSuccess();
}

void UserManager::forgotDetails(const QString& email)
{
    Q_D(UserManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    d->newPassword = "";

    QString randomHex;
    for(int i = 0; i < 16; i++)
    {
        int n = qrand() % 16;
        randomHex.append(QString::number(n,16));
    }

    for(int i = 0; i < 10; ++i)
    {
        d->newPassword += QString::number(rand() % 10);
    }

    QByteArray salt = QByteArray(randomHex.toStdString().c_str()).toHex();
    QString hash = QString(QCryptographicHash::hash((d->newPassword.toStdString().c_str() + salt),QCryptographicHash::Sha1).toHex());

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "forgotdetails.php?email=" + email.toLower() + "&password=" + d->newPassword + "&hash=" + hash + "&salt=" + salt);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(forgotDetailsReply()));
}

void UserManager::forgotDetailsReply()
{
    Q_D(UserManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    bool success = obj.value("success").toBool();

    d->newPassword = "";
    delete reply;

    if(!success)
    {
        emit forgotDetailsFailed(obj.value("message").toString("Problem connecting to BeatWhale API. Please try again."));
        return;
    }

    emit forgotDetailsSuccess();
}

void UserManager::changePassword(const QString &newPassword)
{
    Q_D(UserManager);

    if(!d->networkManager) d->networkManager = new QNetworkAccessManager(this);

    d->newPassword = newPassword;
    DatabaseManager::singleton()->endSession(DatabaseManager::ACCESSTYPE_REMOTE);

    QString randomHex;
    for(int i = 0; i < 16; i++)
    {
        int n = qrand() % 16;
        randomHex.append(QString::number(n,16));
    }

    QByteArray salt = QByteArray(randomHex.toStdString().c_str()).toHex();
    QString hash = QString(QCryptographicHash::hash((d->newPassword.toStdString().c_str() + salt),QCryptographicHash::Sha1).toHex());

    QUrl url(ApplicationManager::singleton()->beatwhaleAPIUrl() + "changepassword.php?username=" + d->username + "&hash=" + hash + "&salt=" + salt + "&rev=" + d->currentSettingsRevision);
    QNetworkReply *reply = d->networkManager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(changePasswordReply()));
}

void UserManager::changePasswordReply()
{
    Q_D(UserManager);

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) return;

    const QByteArray replyBA = reply->readAll();
    QJsonDocument document = QJsonDocument::fromJson(replyBA);
    QJsonObject obj = document.object();

    bool success = obj.value("success").toBool();

    delete reply;

    if(!success)
    {
        d->newPassword = "";
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        emit changePasswordFailed(obj.value("message").toString("Problem connecting to BeatWhale API. Please try again."));
        return;
    }

    d->password = d->newPassword;
    d->newPassword = "";
    DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
    emit changePasswordSuccess();
}

void UserManager::login(const QString& username, const QString& password)
{
    Q_D(UserManager);

    d->username = username;
    d->password = password;

    connect(DatabaseManager::singleton(), SIGNAL(sessionStarted(bool,bool)), SLOT(loginReply(bool,bool)));
    DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::loginReply(const bool &success, const bool& authProblem)
{
    Q_D(UserManager);

    disconnect(DatabaseManager::singleton(), SIGNAL(sessionStarted(bool,bool)), this, SLOT(loginReply(bool,bool)));

    DatabaseManager::singleton()->clearCredentials();

    if(!success)
    {
        if(authProblem)
        {
            emit loginFailed("Incorrect username or password.");
        }
        else
        {
            emit loginFailed("Connection problem. Please try again later.");
        }
        return;
    }

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), SLOT(documentSettingsRetrieved(bool,QString,QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("u_" + d->username.toLower(), "settings", DatabaseManager::ACCESSTYPE_REMOTE);

    //Check if new version exists
    QTimer::singleShot(6000, ApplicationManager::singleton(), SLOT(checkForUpdates()));

    //Ready to rock!
    emit loginSuccess();

    QFileInfo info(d->localSettings.fileName());
    d->queueFile = new QFile(info.path() + "/" + d->username + "_queue.txt");

    if(d->queueFile->open(QFile::ReadWrite))
    {
        d->queueFileStream.setDevice(d->queueFile);

        while(!d->queueFileStream.atEnd())
        {
            QString line = d->queueFileStream.readLine();
            d->queueStringList.append(line);

            QStringList itemData = line.split("#!#!");

            if(itemData.count() != 5) continue;

            VideoItem item;
            item.setID(itemData[0]);
            item.setTitle(itemData[1]);
            item.setSubTitle(itemData[2]);
            item.setThumbnail(itemData[3]);
            item.setDuration(itemData[4]);

            emit queueItemAdded(&item);
        }
    }

    YoutubeAPIManager::singleton()->setOrderFilter(YoutubeAPIManager::OrderFilter(orderFilter()));
    YoutubeAPIManager::singleton()->setDurationFilter(YoutubeAPIManager::DurationFilter(durationFilter()));
    YoutubeAPIManager::singleton()->setMusicOnlyFilter(musicOnlyFilter());
}

void UserManager::logout()
{
    Q_D(UserManager);

    stopListeningToChanges();

    d->username = "";
    d->password = "";

    DatabaseManager::singleton()->endSession(DatabaseManager::ACCESSTYPE_REMOTE);

    d->queueFile->close();
    delete d->queueFile;
    d->queueFile = 0;

    d->firstTime = true;
}

void UserManager::removedFromQueue(const int &index)
{
    Q_D(UserManager);

    d->queueFileStream.seek(0);
    d->queueFile->resize(0);

    d->queueStringList.removeAt(index);

    foreach(QString string, d->queueStringList)
    {
        d->queueFileStream << string << endl;
    }
}

void UserManager::addedToQueue(const QString &id, const QString &title, const QString &subTitle, const QString &thumbnail, const QString &duration)
{
    Q_D(UserManager);
    QString itemString(id + "#!#!" + title + "#!#!" + subTitle + "#!#!" + thumbnail + "#!#!" + duration);
    d->queueStringList.append(itemString);
    d->queueFileStream << itemString << endl;
}

void UserManager::queueCleared()
{
    Q_D(UserManager);
    d->queueFileStream.seek(0);
    d->queueFile->resize(0);
    d->queueStringList.clear();
}

qreal UserManager::volume()
{
    Q_D(UserManager);

    d->localSettings.beginGroup(d->username + "-general");
    qreal volume = d->localSettings.value("volume", -1).toDouble();
    d->localSettings.endGroup();
    return volume >= 0 ? volume : 1;
}

void UserManager::setVolume(const qreal &volume)
{
    Q_D(UserManager);

    d->localSettings.beginGroup(d->username + "-general");
    d->localSettings.setValue("volume", volume);
    d->localSettings.endGroup();
}

void UserManager::startListeningToChanges()
{
    Q_D(UserManager);

    if(d->username.count())
    {
        connect(DatabaseManager::singleton(), SIGNAL(listenToChangesFailed(QString)), SLOT(listeningToChangesFailed(QString)));
        connect(DatabaseManager::singleton(), SIGNAL(changesMade(QString,QString)), SLOT(changesMade(QString,QString)));
        connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(documentUpdatedFeedback(bool,QString)));
        DatabaseManager::singleton()->listenToChanges("u_" + d->username.toLower(), "videos", DatabaseManager::ACCESSTYPE_REMOTE);
    }
}

bool UserManager::stopListeningToChanges()
{
    Q_D(UserManager);

    if(d->username.count())
    {
        disconnect(DatabaseManager::singleton(), SIGNAL(listenToChangesFailed(QString)), this, SLOT(listeningToChangesFailed(QString)));
        disconnect(DatabaseManager::singleton(), SIGNAL(changesMade(QString,QString)), this, SLOT(changesMade(QString,QString)));
        disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), this, SLOT(documentUpdatedFeedback(bool,QString)));
        return DatabaseManager::singleton()->stopListenToChanges("u_" + d->username.toLower(), "videos", DatabaseManager::ACCESSTYPE_REMOTE);
    }
    return false;
}

void UserManager::listeningToChangesFailed(const QString& id)
{
    Q_D(UserManager);

    disconnect(DatabaseManager::singleton(), SIGNAL(listenToChangesFailed(QString)), this, SLOT(listeningToChangesFailed(QString)));
    disconnect(DatabaseManager::singleton(), SIGNAL(changesMade(QString,QString)), this, SLOT(changesMade(QString,QString)));
    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), this, SLOT(documentUpdatedFeedback(bool,QString)));
    ApplicationManager::singleton()->triggerNotification("Connection problem to BeatWhale server.");

    QTimer::singleShot(10000, this, SLOT(startListeningToChanges()));
}

void UserManager::updateDocument(const QJsonDocument &document)
{
    Q_D(UserManager);

    d->documentToUpload = document;
    d->documentReadyForUpload = true;

    uploadDocument();
}

void UserManager::uploadDocument()
{
    Q_D(UserManager);

    if(d->waitingForChanges || !d->documentReadyForUpload) return;

    QJsonObject obj = d->documentToUpload.object();
    obj.insert("_rev", QJsonValue(d->currentRevision));
    d->documentToUpload = QJsonDocument(obj);
    DatabaseManager::singleton()->updateDocument("u_" + d->username.toLower(), "videos", d->documentToUpload.toJson(), DatabaseManager::ACCESSTYPE_REMOTE);

    d->waitingForChanges = true;
}

void UserManager::changesMade(const QString &id, const QString &revision)
{
    Q_D(UserManager);

    if(id != "videos") return;

    qDebug() << "Changes made:" << revision;

    d->waitingForChanges = true;
    d->currentRevision = revision;

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), SLOT(documentUpdate(bool,QString,QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("u_" + d->username.toLower(), "videos", DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::documentUpdate(const bool &success, const QString &id, const QJsonDocument &document)
{
    Q_D(UserManager);

    if(id != "videos") return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), this, SLOT(documentUpdate(bool,QString,QJsonDocument)));
    d->waitingForChanges = false;

    if(!success || document.toJson().isEmpty())
    {
        qDebug() << "There was a problem fecthing document from cloud";

        if(d->firstTime)
        {
            changesMade(id, d->currentRevision);
            return;
        }

        documentUpdatedFeedback(false, "videos");
        return;
    }


    d->videosDocument = document;

    uploadDocument();

    d->documentReadyForUpload = false;

    if(d->firstTime)
    {
        ApplicationManager::singleton()->setNotificationsEnabled(false);
        PlaylistsManager::singleton()->setDocument(document);

        foreach(QString entry, d->videosDocument.object().keys())
        {
            if(entry == "_id" || entry == "_rev") continue;

            if(entry == "Favorites")
            {
                QJsonObject favoritesObj = d->videosDocument.object().value(entry).toObject();

                foreach(QString key, favoritesObj.keys())
                {
                    QJsonObject itemObj = favoritesObj.value(key).toObject();
                    PlaylistsManager::singleton()->addFavorite(key, itemObj.value("title").toString(), itemObj.value("subtitle").toString(), itemObj.value("thumbnail").toString(),
                                                               itemObj.value("duration").toString(), itemObj.value("timestamp").toString());
                }
            }
            else
            {
                Playlist *playlist;

                if(PlaylistsManager::singleton()->playlistNames().contains(entry))
                {
                    playlist = PlaylistsManager::singleton()->playlist(entry);
                }
                else
                {
                    playlist = new Playlist(this);
                    playlist->setName(entry);
                    PlaylistsManager::singleton()->addPlaylist(playlist);
                }

                QJsonObject playlistObj = d->videosDocument.object().value(entry).toObject();

                foreach(QString key, playlistObj.keys())
                {
                    QJsonObject itemObj = playlistObj.value(key).toObject();
                    playlist->addItem(key, itemObj.value("title").toString(), itemObj.value("subtitle").toString(), itemObj.value("thumbnail").toString(),
                                      itemObj.value("duration").toString(), itemObj.value("timestamp").toString());
                }
            }
        }
        ApplicationManager::singleton()->setNotificationsEnabled(true);

        d->firstTime = false;
    }

    emit documentUpdated();
}

void UserManager::documentUpdatedFeedback(const bool &success, const QString &id)
{
    Q_D(UserManager);

    if(id != "videos") return;

    if(success) return;

    qDebug() << "Failed to update document... going to fetch document head";

    connect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), SLOT(documentRevisionRetrieved(bool,QString,QString)));
    DatabaseManager::singleton()->retrieveRevision("u_" + d->username.toLower(), "videos", DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::documentRevisionRetrieved(const bool &success, const QString &id, const QString& revision)
{
    Q_D(UserManager);

    if(id != "videos") return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(documentRevisionRetrieved(bool,QString,QString)));

    if(!success)
    {
        qDebug() << "No success in revision retrieving";
        documentUpdatedFeedback(false, id);
        return;
    }

    d->currentRevision = revision;

    qDebug() << "Going to upload document with new revision" << d->currentRevision;

    d->waitingForChanges = false;
    uploadDocument();
}

void UserManager::documentSettingsRetrieved(const bool &success, const QString &id, const QJsonDocument &document)
{
    Q_D(UserManager);

    if(id != "settings") return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), this, SLOT(documentSettingsRetrieved(bool,QString,QJsonDocument)));

    if(success)
    {
        d->currentSettingsRevision = document.object().value("_rev").toString();
        d->email = document.object().value("email").toString();
    }
}

