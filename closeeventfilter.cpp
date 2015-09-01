#include "closeeventfilter.h"
#include "usermanager.h"

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
        QApplication::instance()->quit();
//        QTimer::singleShot(200, this, SLOT(closeApplication()));
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
    //QApplication::instance()->quit();
    //exit(0);
}
