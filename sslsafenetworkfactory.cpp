#include "sslsafenetworkfactory.h"
#include "sslsafenetworkaccessmanager.h"

QNetworkAccessManager* SSLSafeNetworkFactory::create(QObject *parent)
{
    SSLSafeNetworkAccessManager* manager = new SSLSafeNetworkAccessManager(parent);
    return manager;
}
