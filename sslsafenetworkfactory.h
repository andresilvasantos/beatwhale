#ifndef SSLSAFENETWORKFACTORY_H
#define SSLSAFENETWORKFACTORY_H

#include <QQmlNetworkAccessManagerFactory>

class SSLSafeNetworkFactory : public QObject, public QQmlNetworkAccessManagerFactory
{
    Q_OBJECT

public:
    virtual QNetworkAccessManager *create(QObject *parent);
};

#endif // SSLSAFENETWORKFACTORY_H

