#include "closeeventfilter.h"
#include "usermanager.h"

#include <databasemanager.h>
#include <youtubeapimanager.h>

#include <QTimer>
#include <QEvent>
#include <QApplication>
#include <QThread>
#include <QDebug>

bool CloseEventFilter::eventFilter(QObject *obj, QEvent *event)
{
    if(event->type() == QEvent::Close)
    {
        UserManager::singleton()->stopListeningToChanges();
        DatabaseManager::singleton()->shutdown();
        QTimer::singleShot(200, this, SLOT(closeApplication()));
        return true;
    }
    else
    {
        return QObject::eventFilter(obj, event);
    }
}

void CloseEventFilter::closeApplication()
{
    qDebug() << "Safe exit";
    //QApplication::instance()->thread()->quit();
    exit(0);
}
