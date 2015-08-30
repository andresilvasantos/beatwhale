#include "sslsafenetworkaccessmanager.h"

#include <QNetworkReply>

SSLSafeNetworkAccessManager::SSLSafeNetworkAccessManager(QObject *parent) :
    QNetworkAccessManager(parent)
{
    QObject::connect(this,SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),this,SLOT(ignoreSSLErrors(QNetworkReply*,QList<QSslError>)));
}

void SSLSafeNetworkAccessManager::ignoreSSLErrors(QNetworkReply* reply,QList<QSslError> errors)
{
   reply->ignoreSslErrors(errors);
}

