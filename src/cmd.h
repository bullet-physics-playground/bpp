#ifndef CMD_LINE_H
#define CMD_LINE_H

#include <QLineEdit>
#include <QList>
#include <QString>

class CommandLine : public QLineEdit {
    Q_OBJECT

public:
    CommandLine(QWidget *parent = 0);
    QList<QString>* getHistory();

public slots:
    void executed();

signals:
    void keyPressed(QKeyEvent *e);
    void execute(QString cmd);

private:
    void keyPressEvent(QKeyEvent *e);

private:
    QList<QString> *history;
    int historyPos;
};

#endif
