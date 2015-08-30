#ifndef CLOSEEVENTFILTER_H
#define CLOSEEVENTFILTER_H

#include <QObject>

class CloseEventFilter : public QObject
 {
    Q_OBJECT

public slots:
    void closeApplication();

protected:
    bool eventFilter(QObject *obj, QEvent *event);
};

#endif // CLOSEEVENTFILTER_H
