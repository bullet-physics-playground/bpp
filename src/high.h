#ifndef LUAHIGHLIGHTER_H
#define LUAHIGHLIGHTER_H

#include <QSyntaxHighlighter>

#define LONG_QUOTA_LEVEL 10

class MyTextBlockUserData : public QTextBlockUserData
{
public:
    struct HighlightInfo{
        QString name;
        int offset;
        int len;
    };
    MyTextBlockUserData(){}
    virtual ~MyTextBlockUserData(){}
    void addRule(const QString& name, int offset, int len){
        HighlightInfo info;
        info.name = name;
        info.offset = offset;
        info.len = len;
        infoList.append(info);
    }
    void clear() { infoList.clear(); }
    QList<HighlightInfo>  infoList;
};

class LuaHighlighter : public QSyntaxHighlighter
{
Q_OBJECT
public:
    explicit LuaHighlighter(QTextDocument *parent = 0);

    void addUserKeyword(const QString& keyword);

protected:
    enum BlockState{
        BS_Dummy,
        BS_BlockComment,
        BS_Dummy_Quota,
        BS_DoubleQuota,
        BS_SingleQuota,
        BS_LongQuota,
        BS_LastLongQuata = BS_LongQuota + LONG_QUOTA_LEVEL-1,
        BS_LastState,
    };
    struct HighlightingRule
    {
        HighlightingRule():blockState(BS_Dummy){}
        QRegExp pattern;
        QTextCharFormat format;
        QRegExp endPattern;
        QString name;
        BlockState blockState;
    };

    void highlightBlock(const QString &text);

    void setFormat(int start, int count, const HighlightingRule& rule){
        QSyntaxHighlighter::setFormat(start,count,rule.format);
        MyTextBlockUserData* p = static_cast<MyTextBlockUserData*>(currentBlockUserData());
        if(p){
            p->addRule(rule.name,start,count);
        }
    }

private:

    int matchBlockEnd(const QString &text, int index, const HighlightingRule& rule);
    int matchPatten(const QString &text, int offset, HighlightingRule& rule, int& matchedLength);
    QVector<HighlightingRule> highlightingRules;

    QRegExp commentStartExpression;
    QRegExp commentEndExpression;

    QRegExp quotationStart;
    QRegExp quotationEnd;

    QTextCharFormat keywordFormat;
    QTextCharFormat classFormat;
    QTextCharFormat singleLineCommentFormat;
    QTextCharFormat multiLineCommentFormat;
    QTextCharFormat quotationFormat;
    QTextCharFormat functionFormat;
    QTextCharFormat userKeyword;

};

#endif // LUAHIGHLIGHTER_H
