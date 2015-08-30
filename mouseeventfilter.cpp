#include "mouseeventfilter.h"
#include "applicationmanager.h"

#include <QMouseEvent>
#include <QDebug>

bool MouseEventFilter::eventFilter(QObject *obj, QEvent *event)
{
    if(event->type() == QEvent::MouseMove)
    {
        QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
        if(mouseEvent)
        {
            ApplicationManager::singleton()->setMouseX(mouseEvent->pos().x());
            ApplicationManager::singleton()->setMouseY(mouseEvent->pos().y());
        }
    }
    return QObject::eventFilter(obj, event);
}
