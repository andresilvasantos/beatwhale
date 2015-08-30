#include "usermanager.h"
#include "playlistsmanager.h"
#include "playlist.h"
#include "applicationmanager.h"

#include <databasemanager.h>
#include <jsonhelper.h>
#include <email/emailmanager.h>

#include <QtQml>
#include <QDebug>

UserManager *UserManager::_singleton = 0;

class UserManagerPrivate
{
public:
    UserManagerPrivate() :
        firstTime(true),
        waitingForChanges(false),
        documentReadyForUpload(false),
        localSettings("beatwhale.ini", QSettings::IniFormat),
        emailManager(0)
    {
        QSettings settings("beatwhale_config.ini", QSettings::IniFormat);
        adminUsername = settings.value("database_user").toString();
        adminPassword = settings.value("database_pw").toString();
    }

    virtual ~UserManagerPrivate()
    {
        if(emailManager) delete emailManager;
    }

    QString adminUsername;
    QString adminPassword;

    QString username;
    QString password;
    QString newPassword;
    QString email;

    QSettings localSettings;

    QString currentRevision;
    QJsonDocument videosDocument;
    QJsonDocument documentToUpload;

    bool firstTime;
    bool waitingForChanges;
    bool documentReadyForUpload;

    EmailManager *emailManager;
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

void UserManager::checkUniqueEmail(const QString &email)
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool, QString, QJsonDocument)),
            SLOT(checkUniqueEmailReply(bool, QString, QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("emails", email, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::checkUniqueEmailReply(const bool& connectionSuccess, const QString &id, const QJsonDocument &document)
{
    Q_D(UserManager);

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool, QString, QJsonDocument)),
               this, SLOT(checkUniqueEmailReply(bool, QString, QJsonDocument)));

    DatabaseManager::singleton()->clearCredentials();

    if(!connectionSuccess)
    {
        emit checkUniqueEmailFailed("Connection problem.");
        return;
    }

    if(!document.isObject())
    {
        emit checkUniqueEmailFailed("Problem reaching BeatWhale database. Please try again later.");
        return;
    }

    QJsonObject object = document.object();

    if(object.contains("error"))
    {
        if(object.value("error").toString() == "not_found")
        {
            emit checkUniqueEmailSuccess();
        }
        else
        {
            emit checkUniqueEmailFailed("Problem with BeatWhale database. Please try again later.");
        }
        return;
    }

    emit checkUniqueEmailFailed("This email is already linked to a BeatWhale account.");
}

void UserManager::checkUniqueUsername(const QString &username)
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    if(username.count() < 4)
    {
        emit checkUniqueUsernameFailed("Username must have more than 4 characters.");
        return;
    }

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool, QString, QJsonDocument)),
            SLOT(checkUniqueUsernameReply(bool, QString, QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("_users", "org.couchdb.user:" + username, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::checkUniqueUsernameReply(const bool& connectionSuccess, const QString &id, const QJsonDocument &document)
{
    Q_D(UserManager);

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool, QString, QJsonDocument)),
               this, SLOT(checkUniqueUsernameReply(bool, QString, QJsonDocument)));

    DatabaseManager::singleton()->clearCredentials();

    if(!connectionSuccess)
    {
        emit checkUniqueUsernameFailed("Connection problem.");
        return;
    }

    if(!document.isObject())
    {
        emit checkUniqueUsernameFailed("Problem reaching BeatWhale database. Please try again later.");
        return;
    }

    QJsonObject object = document.object();

    if(object.contains("error"))
    {
        if(object.value("error").toString() == "not_found")
        {
            emit checkUniqueUsernameSuccess();
        }
        else
        {
            emit checkUniqueUsernameFailed("Problem with BeatWhale database. Please try again later.");
        }
        return;
    }

    emit checkUniqueUsernameFailed("Username already exists. Please choose another one.");
}

void UserManager::createUserDocument(const QString &username, const QString &password)
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    d->username = username;
    d->password = password;

    QString randomHex;
    for(int i = 0; i < 16; i++)
    {
        int n = qrand() % 16;
        randomHex.append(QString::number(n,16));
    }

    QByteArray salt = QByteArray(randomHex.toStdString().c_str()).toHex();
    QString hash = QString(QCryptographicHash::hash((password.toStdString().c_str() + salt),QCryptographicHash::Sha1).toHex());

    QJsonObject obj;
    obj.insert("name", username);
    obj.insert("password_scheme", QString("simple"));
    obj.insert("type", QString("user"));
    obj.insert("password_sha", hash);
    obj.insert("salt", QString(salt));

    QJsonDocument document(obj);
    QByteArray documentBA = document.toJson();

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(createUserDocumentReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("_users", "org.couchdb.user:" + username, documentBA, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::createUserDocumentReply(const bool& success, const QString &id)
{
    Q_D(UserManager);

    if("org.couchdb.user:" + d->username != id) return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool, QString, QString)),
               this, SLOT(createUserDocumentReply(bool, QString)));

    if(!success)
    {
        emit createUserDocumentFailed("An error occurred. Please try again.");
        return;
    }

    emit createUserDocumentSuccess();
}

void UserManager::createUserDatabase(const QString& username) const
{
    Q_D(const UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    qDebug() << "Creating user database for" << username;

    connect(DatabaseManager::singleton(), SIGNAL(databaseReplicated(bool)), SLOT(createUserDatabaseReply(bool)));
    DatabaseManager::singleton()->replicateDatabase("user_template", "u_" + username, DatabaseManager::ACCESSTYPE_REMOTE, DatabaseManager::ACCESSTYPE_REMOTE, true, false);
}

void UserManager::createUserDatabaseReply(const bool& success)
{
    Q_D(UserManager);

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(databaseReplicated(bool)), this, SLOT(createUserDatabaseReply(bool)));

    if(!success)
    {
        emit createUserDatabaseFailed("An error occurred. Please try again.");
        return;
    }

    emit createUserDatabaseSuccess();
}

void UserManager::updateSettingsFile(const QString& username, const QString &email)
{
    Q_D(UserManager);

    d->email = email;
    d->username = username;
    updateSettingsFileStepRetrieve();
}

void UserManager::updateSettingsFileStepRetrieve()
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), SLOT(updateSettingsFileStepRetrieveReply(bool,QString,QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("u_" + d->username, "settings", DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::updateSettingsFileStepRetrieveReply(const bool& connectionSuccess, const QString& id, const QJsonDocument& document)
{
    Q_D(UserManager);

    if(id != "settings") return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), this, SLOT(updateSettingsFileStepRetrieveReply(bool,QString,QJsonDocument)));

    if(!connectionSuccess || document.object().contains("error"))
    {
        d->email = "";
        d->username = "";
        emit updateSettingsFileFailed("An error occurred. Please try again.");
        return;
    }

    QJsonDocument updatedDocument = document;
    JsonHelper::modifyValue(updatedDocument, "email", d->email);

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(updateSettingsFileReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("u_" + d->username, "settings", updatedDocument.toJson(), DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::updateSettingsFileReply(const bool& success, const QString& id)
{
    Q_D(UserManager);

    if(id != "settings") return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), this, SLOT(updateSettingsFileReply(bool,QString)));

    if(!success)
    {
        d->email = "";
        d->username = "";
        emit updateSettingsFileFailed("An error occurred. Please try again.");
        return;
    }

    emit updateSettingsFileSuccess();
}

void UserManager::updateDatabaseSecurity(const QString& username) const
{
    Q_D(const UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    QJsonObject object;
    object.insert("_id", QString("_security"));
    object.insert("couchdb_auth_only", true);
    QJsonArray membersNamesArray;
    membersNamesArray.append(username);
    QJsonObject members;
    members.insert("names", membersNamesArray);
    members.insert("roles", QJsonArray());
    object.insert("members", members);
    object.insert("admins", QJsonObject());
    QJsonDocument document(object);
    QByteArray json = document.toJson();

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(updateDatabaseSecurityReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("u_" + username, "_security", json, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::updateDatabaseSecurityReply(const bool& success, const QString& id)
{
    Q_D(UserManager);

    if(id != "_security") return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), this, SLOT(updateDatabaseSecurityReply(bool,QString)));

    if(!success)
    {
        emit updateDatabaseSecurityFailed("An error occurred. Please try again.");
        return;
    }

    emit updateDatabaseSecuritySuccess();
}

void UserManager::createEmailDocument(const QString &email, const QString &username)
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    d->email = email;
    QJsonObject obj;
    obj.insert("username", username);

    QJsonDocument document(obj);
    QByteArray documentBA = document.toJson();

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(createEmailDocumentReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("emails", d->email, documentBA, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::createEmailDocumentReply(const bool &success, const QString &id)
{
    Q_D(UserManager);

    if(id != d->email) return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool, QString, QString)),
               this, SLOT(createEmailDocumentReply(bool, QString)));

    if(!success)
    {
        emit createEmailDocumentFailed("An error occurred. Please try again.");
        return;
    }

    emit createEmailDocumentSuccess();
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

void UserManager::sendCodeByEmail(const QString &emailAddress, const QString &activationCode)
{
    Q_D(UserManager);

    if(!d->emailManager) d->emailManager = new EmailManager(this);

    d->emailManager->setEmailData("info@beatwhale.com", d->adminPassword, "BeatWhale Team", "server.flexiserver150.com", 25, false);
    d->emailManager->sendEmail(emailAddress, "", "BeatWhale Confirmation Code", "Cool, we are almost there!\n\n\nJust copy the code below and paste it into the application:\n\nCode: " +
                               activationCode + "\n\n\n\nWe'll be waiting!\n-BeatWhale Team");
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
    DatabaseManager::singleton()->retrieveDocument("u_" + d->username, "settings", DatabaseManager::ACCESSTYPE_REMOTE);

    emit loginSuccess();
}

void UserManager::logout()
{
    Q_D(UserManager);

    qDebug() << "LOGOUT";

    d->username = "";
    d->password = "";

    d->firstTime = true;

    stopListeningToChanges();
}

void UserManager::forgotDetails(const QString &email)
{
    Q_D(UserManager);

    d->email = email;
    forgotDetailsStepRetrieveEmailDocument();
}

void UserManager::forgotDetailsStepRetrieveEmailDocument()
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    connect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)),
            SLOT(forgotDetailsStepRetrieveEmailDocumentReply(bool,QString,QJsonDocument)));
    DatabaseManager::singleton()->retrieveDocument("emails", d->email, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::forgotDetailsStepRetrieveEmailDocumentReply(const bool &success, const QString &id, const QJsonDocument &document)
{
    Q_D(UserManager);

    if(id != d->email) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentRetrieved(bool,QString,QJsonDocument)), this,
               SLOT(forgotDetailsStepRetrieveEmailDocumentReply(bool,QString,QJsonDocument)));


    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        d->email = "";
        emit forgotDetailsFailed("Problem connecting to BeatWhale. Please try again.");
        return;
    }

    d->username = document.object().value("username").toString();

    if(document.object().contains("error") || d->username.isEmpty())
    {
        DatabaseManager::singleton()->clearCredentials();
        d->email = "";
        emit forgotDetailsFailed("This email is not linked to any BeatWhale account.");
        return;
    }

    forgotDetailsStepUserDocumentRev();
}

void UserManager::forgotDetailsStepUserDocumentRev()
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), SLOT(forgotDetailsStepUserDocumentRevReply(bool,QString,QString)));
    DatabaseManager::singleton()->retrieveRevision("_users", "org.couchdb.user:" + d->username, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::forgotDetailsStepUserDocumentRevReply(const bool &success, const QString& id, const QString& rev)
{
    Q_D(UserManager);

    if(id != "org.couchdb.user:" + d->username) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(forgotDetailsStepUserDocumentRevReply(bool,QString,QString)));

    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        d->email = "";
        d->username = "";
        emit forgotDetailsFailed("Problem connecting to BeatWhale. Please try again.");
        return;
    }

    forgotDetailsStepResetPassword(rev);
}

void UserManager::forgotDetailsStepResetPassword(const QString& rev)
{
    Q_D(UserManager);

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

    QJsonObject obj;
    obj.insert("_rev", rev);
    obj.insert("name", d->username);
    obj.insert("password_scheme", QString("simple"));
    obj.insert("type", QString("user"));
    obj.insert("password_sha", hash);
    obj.insert("salt", QString(salt));

    QJsonDocument document(obj);
    QByteArray documentBA = document.toJson();

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(forgotDetailsStepResetPasswordReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("_users", "org.couchdb.user:" + d->username, documentBA, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::forgotDetailsStepResetPasswordReply(const bool& success, const QString &id)
{
    Q_D(UserManager);

    if("org.couchdb.user:" + d->username != id) return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool, QString, QString)),
               this, SLOT(forgotDetailsStepResetPasswordReply(bool, QString)));

    if(!success)
    {
        d->newPassword = "";
        d->email = "";
        d->username = "";
        emit forgotDetailsFailed("Problem connecting to BeatWhale. Please try again.");
        return;
    }

    //Send email
    if(!d->emailManager) d->emailManager = new EmailManager(this);

    d->emailManager->setEmailData("info@beatwhale.com", d->adminPassword, "BeatWhale Team", "server.flexiserver150.com", 25, false);
    d->emailManager->sendEmail(d->email, "", "BeatWhale Password Reset", "Here are your credentials:\n\n\nUsername: " +
                               d->username + "\nNew password: " + d->newPassword + "\n\n\nNow it's time to go back in!\n-BeatWhale Team");

    emit forgotDetailsSuccess();
}

void UserManager::changePassword(const QString &newPassword)
{
    Q_D(UserManager);

    d->newPassword = newPassword;
    changePasswordStepEndSession();
}

void UserManager::changePasswordStepEndSession()
{
    connect(DatabaseManager::singleton(), SIGNAL(sessionEnded(bool)), SLOT(changePasswordStepEndSessionReply(bool)));
    DatabaseManager::singleton()->endSession(DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::changePasswordStepEndSessionReply(const bool &success)
{
    disconnect(DatabaseManager::singleton(), SIGNAL(sessionEnded(bool)), this, SLOT(changePasswordStepEndSessionReply(bool)));

    if(!success)
    {
        emit passwordChanged(false);
        return;
    }

    changePasswordStepUserDocumentRev();
}

void UserManager::changePasswordStepUserDocumentRev()
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    connect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), SLOT(changePasswordStepUserDocumentRevReply(bool,QString,QString)));
    DatabaseManager::singleton()->retrieveRevision("_users", "org.couchdb.user:" + d->username, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::changePasswordStepUserDocumentRevReply(const bool &success, const QString& id, const QString& rev)
{
    Q_D(UserManager);

    if(id != "org.couchdb.user:" + d->username) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(changePasswordStepUserDocumentRevReply(bool,QString,QString)));

    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        d->newPassword = "";
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        emit passwordChanged(false);
        return;
    }

    changePasswordStepUpdateUserDocument(rev);
}

void UserManager::changePasswordStepUpdateUserDocument(const QString& rev)
{
    Q_D(UserManager);

    QString randomHex;
    for(int i = 0; i < 16; i++)
    {
        int n = qrand() % 16;
        randomHex.append(QString::number(n,16));
    }

    QByteArray salt = QByteArray(randomHex.toStdString().c_str()).toHex();
    QString hash = QString(QCryptographicHash::hash((d->newPassword.toStdString().c_str() + salt),QCryptographicHash::Sha1).toHex());

    QJsonObject obj;
    obj.insert("_rev", rev);
    obj.insert("name", d->username);
    obj.insert("password_scheme", QString("simple"));
    obj.insert("type", QString("user"));
    obj.insert("password_sha", hash);
    obj.insert("salt", QString(salt));

    QJsonDocument document(obj);
    QByteArray documentBA = document.toJson();

    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(changePasswordStepUpdateUserDocumentReply(bool,QString)));
    DatabaseManager::singleton()->updateDocument("_users", "org.couchdb.user:" + d->username, documentBA, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::changePasswordStepUpdateUserDocumentReply(const bool& success, const QString &id)
{
    Q_D(UserManager);

    if("org.couchdb.user:" + d->username != id) return;

    DatabaseManager::singleton()->clearCredentials();

    disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool, QString, QString)),
               this, SLOT(changePasswordStepUpdateUserDocumentReply(bool, QString)));

    if(!success)
    {
        d->newPassword = "";
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        emit passwordChanged(false);
        return;
    }

    d->password = d->newPassword;
    DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);

    emit passwordChanged(true);
}

void UserManager::setVolume(const qreal &volume)
{
    Q_D(UserManager);

    qDebug() << "TODO send settings document with new volume value" << volume;
}

void UserManager::deleteAccount()
{
    deleteAccountStepEndSession();
}

void UserManager::deleteAccountStepEndSession()
{
    connect(DatabaseManager::singleton(), SIGNAL(sessionEnded(bool)), SLOT(deleteAccountStepEndSessionReply(bool)));
    DatabaseManager::singleton()->endSession(DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepEndSessionReply(const bool &success)
{
    disconnect(DatabaseManager::singleton(), SIGNAL(sessionEnded(bool)), this, SLOT(deleteAccountStepEndSessionReply(bool)));

    if(!success)
    {
        emit accountDeleted(false);
        return;
    }

    deleteAccountStepUserDocumentRev();
}

void UserManager::deleteAccountStepUserDocumentRev()
{
    Q_D(UserManager);

    DatabaseManager::singleton()->setCredentials(d->adminUsername, d->adminPassword);

    connect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), SLOT(deleteAccountStepUserDocumentRevReply(bool,QString,QString)));
    DatabaseManager::singleton()->retrieveRevision("_users", "org.couchdb.user:" + d->username, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepUserDocumentRevReply(const bool &success, const QString& id, const QString& rev)
{
    Q_D(UserManager);

    if(id != "org.couchdb.user:" + d->username) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(deleteAccountStepUserDocumentRevReply(bool,QString,QString)));

    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        emit accountDeleted(false);
        return;
    }

    deleteAccountStepDeleteUser(rev);
}

void UserManager::deleteAccountStepDeleteUser(const QString& userDocumentRev)
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(documentDeleted(bool,QString)), SLOT(deleteAccountStepDeleteUserReply(bool,QString)));
    DatabaseManager::singleton()->deleteDocument("_users", "org.couchdb.user:" + d->username, userDocumentRev, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepDeleteUserReply(const bool &success, const QString& id)
{
    Q_D(UserManager);

    if(id != "org.couchdb.user:" + d->username) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentDeleted(bool,QString)), this, SLOT(deleteAccountStepDeleteUserReply(bool,QString)));

    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        emit accountDeleted(false);
        DatabaseManager::singleton()->startSession(d->username, d->password, DatabaseManager::ACCESSTYPE_REMOTE);
        return;
    }

    deleteAccountStepDeleteDatabase();
}

void UserManager::deleteAccountStepDeleteDatabase()
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(databaseDeleted(bool)), SLOT(deleteAccountStepDeleteDatabaseReply()));
    DatabaseManager::singleton()->deleteDatabase("u_" + d->username, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepDeleteDatabaseReply()
{
    Q_D(UserManager);

    disconnect(DatabaseManager::singleton(), SIGNAL(databaseDeleted(bool)), this, SLOT(deleteAccountStepDeleteDatabaseReply()));

    deleteAccountStepEmailDocumentRev();
}

void UserManager::deleteAccountStepEmailDocumentRev()
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), SLOT(deleteAccountStepEmailDocumentRevReply(bool,QString,QString)));
    DatabaseManager::singleton()->retrieveRevision("emails", d->email, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepEmailDocumentRevReply(const bool &success, const QString& id, const QString& rev)
{
    Q_D(UserManager);

    if(id != d->email) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(deleteAccountStepEmailDocumentRevReply(bool,QString,QString)));

    if(!success)
    {
        DatabaseManager::singleton()->clearCredentials();
        emit accountDeleted(true);
        return;
    }

    deleteAccountStepDeleteEmail(rev);
}

void UserManager::deleteAccountStepDeleteEmail(const QString& emailDocumentRev)
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(documentDeleted(bool,QString)), SLOT(deleteAccountStepDeleteEmailReply(bool,QString)));
    DatabaseManager::singleton()->deleteDocument("emails", d->email, emailDocumentRev, DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::deleteAccountStepDeleteEmailReply(const bool &success, const QString& id)
{
    Q_D(UserManager);

    if(id != d->email) return;

    disconnect(DatabaseManager::singleton(), SIGNAL(documentDeleted(bool,QString)), this, SLOT(deleteAccountStepDeleteEmailReply(bool,QString)));

    DatabaseManager::singleton()->clearCredentials();

    d->localSettings.setValue("login/remember", false);
    d->localSettings.remove("login/credentials");

    d->username = "";
    d->password = "";
    d->email = "";

    emit accountDeleted(true);
}

void UserManager::startListeningToChanges()
{
    Q_D(UserManager);

    connect(DatabaseManager::singleton(), SIGNAL(listenToChangesFailed(QString)), SLOT(listeningToChangesFailed(QString)));
    connect(DatabaseManager::singleton(), SIGNAL(changesMade(QString,QString)), SLOT(changesMade(QString,QString)));
    connect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), SLOT(documentUpdatedFeedback(bool,QString)));
    DatabaseManager::singleton()->listenToChanges("u_" + d->username, "videos", DatabaseManager::ACCESSTYPE_REMOTE);
}

bool UserManager::stopListeningToChanges()
{
    Q_D(UserManager);

    if(d->username.count())
    {
        disconnect(DatabaseManager::singleton(), SIGNAL(listenToChangesFailed(QString)), this, SLOT(listeningToChangesFailed(QString)));
        disconnect(DatabaseManager::singleton(), SIGNAL(changesMade(QString,QString)), this, SLOT(changesMade(QString,QString)));
        disconnect(DatabaseManager::singleton(), SIGNAL(documentUpdated(bool,QString,QString)), this, SLOT(documentUpdatedFeedback(bool,QString)));
        return DatabaseManager::singleton()->stopListenToChanges("u_" + d->username, "videos", DatabaseManager::ACCESSTYPE_REMOTE);
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

    QTimer::singleShot(5000, this, SLOT(startListeningToChanges()));
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
    DatabaseManager::singleton()->updateDocument("u_" + d->username, "videos", d->documentToUpload.toJson(), DatabaseManager::ACCESSTYPE_REMOTE);

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
    DatabaseManager::singleton()->retrieveDocument("u_" + d->username, "videos", DatabaseManager::ACCESSTYPE_REMOTE);
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

        documentUpdatedFeedback(false, "videos");
        return;
    }

    d->documentReadyForUpload = false;

    d->videosDocument = document;

    uploadDocument();

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
                    PlaylistsManager::singleton()->addToFavorites(key, itemObj.value("title").toString(), itemObj.value("subtitle").toString(), itemObj.value("thumbnail").toString(),
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
    DatabaseManager::singleton()->retrieveRevision("u_" + d->username, "videos", DatabaseManager::ACCESSTYPE_REMOTE);
}

void UserManager::documentRevisionRetrieved(const bool &success, const QString &id, const QString& revision)
{
    Q_D(UserManager);

    if(id != "videos") return;

    disconnect(DatabaseManager::singleton(), SIGNAL(revisionRetrieved(bool,QString,QString)), this, SLOT(documentRevisionRetrieved(bool,QString,QString)));

    if(!success)
    {
        qDebug() << "No success in revision retrieving";
        documentUpdatedFeedback(false, d->username);
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
        d->email = document.object().value("email").toString();
    }
}

