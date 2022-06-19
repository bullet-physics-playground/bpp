#ifndef CODE_H
#define CODE_H

#include <QSettings>

#include <Qsci/qsciscintilla.h>

class Code : public QsciScintilla
{
    Q_OBJECT
public:
    explicit Code(QSettings *settings, QWidget *parent = nullptr);

    QString script_filename;

public slots:
    bool load(QString fileName=QString());
    bool saveAs(QString fileName=QString());
    bool save();

    QString toPlainText();
    void appendLine(QString line);

    void setFont(QString family, int size);

signals:
    void scriptLoaded();
    void scriptSaved();
    void keyPressed(QKeyEvent *e);

protected:
    void keyPressEvent(QKeyEvent *e);

};

#endif // CODE_H
