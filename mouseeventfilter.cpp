#include "mouseeventfilter.h"
#include "applicationmanager.h"

#include <QQuickWindow>
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

            if(mouseEvent->buttons() && Qt::LeftButton && ApplicationManager::singleton()->grabbingWindowMoveHandle())
            {
                QPoint diffPosition = mouseEvent->pos() - mousePos.toPoint();
                QPoint newPosition = ApplicationManager::singleton()->window()->position() + diffPosition;

                int oldWindowWidth = ApplicationManager::singleton()->window()->width();
                if(ApplicationManager::singleton()->showNormal())
                {
                    int windowWidth = ApplicationManager::singleton()->window()->width();
                    ApplicationManager::singleton()->window()->setPosition(newPosition.x() + (oldWindowWidth - windowWidth) * (mousePos.x() / oldWindowWidth), newPosition.y());
                    mousePos.setX(mousePos.x() - (oldWindowWidth - windowWidth) * (mousePos.x() / oldWindowWidth));
                }
                else
                {
                    ApplicationManager::singleton()->window()->setPosition(newPosition);
                }
            }
            else if(mouseEvent->buttons() && Qt::LeftButton && ApplicationManager::singleton()->grabbingWindowResizeHandle())
            {
                QPoint diffPosition = mouseEvent->pos() - mousePos.toPoint();
                mousePos = mouseEvent->pos();

                QWindow *window = ApplicationManager::singleton()->window();
                int newWidth = window->width() + diffPosition.x();
                int newHeight = window->height() + diffPosition.y();

                if(newWidth < 800) newWidth = 800;
                if(newHeight < 600) newHeight = 600;

                window->setGeometry(window->position().x(), window->position().y(), newWidth, newHeight);
            }
        }
    }
    else if(event->type() == QEvent::MouseButtonPress)
    {
        QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
        if(mouseEvent)
        {
            mousePos = mouseEvent->pos();
        }
    }
    return QObject::eventFilter(obj, event);
}
