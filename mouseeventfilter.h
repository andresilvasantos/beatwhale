#ifndef MOUSEEVENTFILTER_H
#define MOUSEEVENTFILTER_H

#include <QObject>
#include <QPoint>

class QMouseEvent;
class MouseEventFilter : public QObject
{
    Q_OBJECT

protected:
    bool eventFilter(QObject *obj, QEvent *event);

private:
    QPointF mousePos;

};

#endif // MOUSEEVENTFILTER_H
