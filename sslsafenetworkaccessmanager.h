#ifndef SSLSAFENETWORKACCESSMANAGER_H
#define SSLSAFENETWORKACCESSMANAGER_H

#include <QNetworkAccessManager>

class SSLSafeNetworkAccessManager : public QNetworkAccessManager
{
    Q_OBJECT

public:
    SSLSafeNetworkAccessManager(QObject *parent = 0);

public slots:
    void ignoreSSLErrors(QNetworkReply* reply, QList<QSslError> errors);
};

#endif // SSLSAFENETWORKACCESSMANAGER_H
