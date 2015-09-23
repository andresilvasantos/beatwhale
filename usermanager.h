#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>

class VideoItem;
class QQmlEngine;
class QJSEngine;
class UserManagerPrivate;
class UserManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int orderFilter READ orderFilter WRITE setOrderFilter NOTIFY orderFilterChanged)
    Q_PROPERTY(int durationFilter READ durationFilter WRITE setDurationFilter NOTIFY durationFilterChanged)
    Q_PROPERTY(bool musicOnlyFilter READ musicOnlyFilter WRITE setMusicOnlyFilter NOTIFY musicOnlyFilterChanged)

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

    int orderFilter() const;
    void setOrderFilter(const int& orderFilter);

    int durationFilter() const;
    void setDurationFilter(const int& durationFilter);

    bool musicOnlyFilter() const;
    void setMusicOnlyFilter(const bool& musicOnly);

signals:
    void orderFilterChanged(const int& orderFilter);
    void durationFilterChanged(const int& durationFilter);
    void musicOnlyFilterChanged(const bool& musicOnlyFilter);

    void createAccountVerificationSuccess();
    void createAccountVerificationFailed(const QString& message);

    void createAccountSuccess();
    void createAccountFailed(const QString& message);

    void deleteAccountSuccess();
    void deleteAccountFailed(const QString& message);

    void forgotDetailsSuccess();
    void forgotDetailsFailed(const QString& message);

    void changePasswordSuccess();
    void changePasswordFailed(const QString& message);

    void volumeChanged(const qreal& volume);

    void loginSuccess();
    void loginFailed(const QString& message);

    void documentUpdated();

    void queueItemAdded(QObject *item);

public slots:
    Q_INVOKABLE QString generateActivationCode();
    Q_INVOKABLE void createAccountVerification(const QString& username, const QString& email, const QString& code);
    Q_INVOKABLE void createAccount(const QString& username, const QString &password, const QString& email);
    Q_INVOKABLE void deleteAccount();
    Q_INVOKABLE void forgotDetails(const QString& email);
    Q_INVOKABLE void changePassword(const QString& newPassword);

    Q_INVOKABLE void login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

    Q_INVOKABLE void removedFromQueue(const int& index);
    Q_INVOKABLE void addedToQueue(const QString &id, const QString &title, const QString &subTitle, const QString &thumbnail, const QString &duration);
    Q_INVOKABLE void queueCleared();

    Q_INVOKABLE qreal volume();
    Q_INVOKABLE void setVolume(const qreal& volume);

    void startListeningToChanges();
    bool stopListeningToChanges();

    void updateDocument(const QJsonDocument& document);

private slots:
    void createAccountVerificationReply();
    void createAccountReply();
    void deleteAccountReply();
    void forgotDetailsReply();
    void changePasswordReply();

    void loginReply(const bool& success, const bool &authProblem);

    void listeningToChangesFailed(const QString &id);

    void uploadDocument();
    void changesMade(const QString &id, const QString &revision);
    void documentUpdate(const bool& success, const QString& id, const QJsonDocument& document);
    void documentUpdatedFeedback(const bool& success, const QString& id);
    void documentRevisionRetrieved(const bool &success, const QString &id, const QString &revision);
    void documentSettingsRetrieved(const bool &success, const QString &id, const QJsonDocument &document);

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
