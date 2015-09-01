#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QStringList>

class QQmlEngine;
class QJSEngine;
class UserManagerPrivate;
class UserManager : public QObject
{
    Q_OBJECT

public:
    static UserManager* singleton();
    static void declareQML();

    Q_INVOKABLE QString storedUsername() const;
    Q_INVOKABLE QString storedPassword() const;

    Q_INVOKABLE QString username() const;
    Q_INVOKABLE QString password() const;
    Q_INVOKABLE QString email() const;

    Q_INVOKABLE bool rememberCredentials() const;
    Q_INVOKABLE void setRememberCredentials(const bool& remember);

signals:
    void checkUniqueEmailSuccess();
    void checkUniqueEmailFailed(const QString& message);

    void checkUniqueUsernameSuccess();
    void checkUniqueUsernameFailed(const QString& message);

    void createUserDocumentSuccess();
    void createUserDocumentFailed(const QString& message);

    void createUserDatabaseSuccess();
    void createUserDatabaseFailed(const QString& message);

    void updateSettingsFileSuccess();
    void updateSettingsFileFailed(const QString& message);

    void updateDatabaseSecuritySuccess();
    void updateDatabaseSecurityFailed(const QString& message);

    void createEmailDocumentSuccess();
    void createEmailDocumentFailed(const QString& message);

    void sendCodeByEmailSuccess();
    void sendCodeByEmailFailed(const QString& message);

    void loginSuccess();
    void loginFailed(const QString& message);

    void forgotDetailsSuccess();
    void forgotDetailsFailed(const QString& message);

    void passwordChanged(const bool& success);

    void accountDeleted(const bool& success);

    void documentUpdated();

public slots:
    Q_INVOKABLE void checkUniqueEmail(const QString& email);
    Q_INVOKABLE void checkUniqueUsername(const QString& username);
    Q_INVOKABLE void createUserDocument(const QString& username, const QString& password);
    Q_INVOKABLE void createUserDatabase(const QString& username) const;
    Q_INVOKABLE void updateSettingsFile(const QString &username, const QString& email);
    Q_INVOKABLE void updateDatabaseSecurity(const QString& username) const;
    Q_INVOKABLE void createEmailDocument(const QString& email, const QString &username);

    Q_INVOKABLE QString generateActivationCode();
    Q_INVOKABLE void sendCodeByEmail(const QString& emailAddress, const QString& activationCode);

    Q_INVOKABLE void login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

    Q_INVOKABLE void forgotDetails(const QString& email);
    Q_INVOKABLE void changePassword(const QString& newPassword);

    Q_INVOKABLE void setVolume(const qreal& volume);
    Q_INVOKABLE void deleteAccount();

    void startListeningToChanges();
    bool stopListeningToChanges();

    void updateDocument(const QJsonDocument& document);

private slots:
    void checkUniqueEmailReply(const bool& connectionSuccess, const QString &id, const QJsonDocument &document);
    void checkUniqueUsernameReply(const bool& connectionSuccess, const QString &id, const QJsonDocument &document);
    void createUserDocumentReply(const bool& success, const QString &id);
    void createUserDatabaseReply(const bool& success);
    void updateSettingsFileStepRetrieveReply(const bool &success, const QString &id, const QJsonDocument &document);
    void updateSettingsFileReply(const bool &success, const QString &id);
    void updateDatabaseSecurityReply(const bool& success, const QString& id);
    void createEmailDocumentReply(const bool& success, const QString& id);
    void loginReply(const bool& success, const bool &authProblem);

    void sendCodeByEmailReply(const bool &success, const QString &message);

    void forgotDetailsStepRetrieveEmailDocumentReply(const bool &success, const QString &id, const QJsonDocument &document);
    void forgotDetailsStepUserDocumentRevReply(const bool &success, const QString &id, const QString &rev);
    void forgotDetailsStepResetPasswordReply(const bool &success, const QString &id);
    void forgotDetailsStepSendEmailReply(const bool &success, const QString &message);

    void changePasswordStepEndSessionReply(const bool &success);
    void changePasswordStepUserDocumentRevReply(const bool &success, const QString &id, const QString &rev);
    void changePasswordStepUpdateUserDocumentReply(const bool &success, const QString &id);

    void deleteAccountStepEndSessionReply(const bool &success);
    void deleteAccountStepUserDocumentRevReply(const bool &success, const QString &id, const QString &rev);
    void deleteAccountStepDeleteUserReply(const bool &success, const QString &id);
    void deleteAccountStepDeleteDatabaseReply();
    void deleteAccountStepEmailDocumentRevReply(const bool &success, const QString &id, const QString &rev);
    void deleteAccountStepDeleteEmailReply(const bool &success, const QString &id);

    void listeningToChangesFailed(const QString &id);

    void uploadDocument();
    void changesMade(const QString &id, const QString &revision);
    void documentUpdate(const bool& success, const QString& id, const QJsonDocument& document);
    void documentUpdatedFeedback(const bool& success, const QString& id);
    void documentRevisionRetrieved(const bool &success, const QString &id, const QString &revision);
    void documentSettingsRetrieved(const bool &success, const QString &id, const QJsonDocument &document);

protected:
    void updateSettingsFileStepRetrieve();

    void forgotDetailsStepRetrieveEmailDocument();
    void forgotDetailsStepUserDocumentRev();
    void forgotDetailsStepResetPassword(const QString &rev);
    void forgotDetailsStepSendEmail();

    void changePasswordStepEndSession();
    void changePasswordStepUserDocumentRev();
    void changePasswordStepUpdateUserDocument(const QString &rev);

    void deleteAccountStepEndSession();
    void deleteAccountStepUserDocumentRev();
    void deleteAccountStepDeleteUser(const QString &userDocumentRev);
    void deleteAccountStepDeleteDatabase();
    void deleteAccountStepEmailDocumentRev();
    void deleteAccountStepDeleteEmail(const QString &emailDocumentRev);

private:
    explicit UserManager(QObject *parent = 0);
    virtual ~UserManager();

    static UserManager *_singleton;

    Q_DECLARE_PRIVATE(UserManager)
    UserManagerPrivate * const d_ptr;

};

static QObject *qmlUserManagerSingleton(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return UserManager::singleton();
}

#endif // USERMANAGER_H
