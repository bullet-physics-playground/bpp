#include "high.h"

//#include <QDebug>

struct NoDebug;
template<typename T>
inline NoDebug& operator<<(NoDebug& n,T&){return n;}
#define qDebug()  (*(NoDebug*)0)

LuaHighlighter::LuaHighlighter(QTextDocument *parent)
    : QSyntaxHighlighter(parent)
{
    HighlightingRule rule;

    keywordFormat.setForeground(Qt::darkBlue);
    keywordFormat.setFontWeight(QFont::Bold);
    //rule.pattern = QRegExp("\\bchar|class|const|double|enum|explicit|friend|inline|int|long|namespace|operator|private|protected|public|short|signals|signed|slots|static|struct|template|typedef|typename|union|unsigned|virtual|void|volatile\\b");
    rule.pattern = QRegExp("\\b(and|break|do|else|elseif|end|false|for|function|if|in|local|nil|not|or|repeat|return|then|true|until|while)\\b");
    //rule.pattern = QRegExp("\\b(and|break)\\b");
    rule.format = keywordFormat;
    rule.name = "keyword";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);

    multiLineCommentFormat.setForeground(Qt::darkGreen);
    commentStartExpression = QRegExp("\\-\\-\\[\\[");
    commentEndExpression = QRegExp("\\]\\]");
    rule.pattern = commentStartExpression;
    rule.endPattern = commentEndExpression;
    rule.name = "block comment";
    rule.blockState = BS_BlockComment;
    rule.format = multiLineCommentFormat;
    highlightingRules.append(rule);

    quotationFormat.setForeground(Qt::darkRed);

    rule.format = quotationFormat;
    rule.pattern = QRegExp("\"\"|''");
    rule.name = "quotation";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);

    rule.format = quotationFormat;
    rule.pattern = QRegExp("\"");
    rule.endPattern = QRegExp("[^\\\\]\"");
    rule.name = "double quotation";
    rule.blockState = BS_DoubleQuota;
    highlightingRules.append(rule);

    rule.pattern = QRegExp("'");
    rule.endPattern = QRegExp("[^\\\\]'");
    rule.name = "single quotation";
    rule.blockState = BS_SingleQuota;
    highlightingRules.append(rule);

    QString s = "";
    for(int i=0;i<LONG_QUOTA_LEVEL;i++){
        quotationStart = QRegExp(QString("\\[%1\\[").arg(s));
        quotationEnd = QRegExp(QString("\\]%1\\]").arg(s));

        rule.pattern = quotationStart;
        rule.endPattern = quotationEnd;
        rule.blockState = (BlockState)(BS_LongQuota+i);
        rule.name = QString("long quotation %1").arg(i);
        highlightingRules.append(rule);
        s+="=";
    }

    classFormat.setFontWeight(QFont::Bold);
    classFormat.setForeground(Qt::darkMagenta);
    rule.pattern = QRegExp("\\bQ[A-Za-z]+\\b");
    rule.format = classFormat;
    rule.name = "class";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);

    // functionFormat.setFontItalic(true);
    functionFormat.setForeground(Qt::blue);
    rule.pattern = QRegExp("\\b[A-Za-z0-9_]+(?=\\()");
    rule.format = functionFormat;
    rule.name = "function";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);

    singleLineCommentFormat.setForeground(Qt::darkGreen);
    rule.pattern = QRegExp("\\-\\-[^\\[][^\n]*");
    rule.format = singleLineCommentFormat;
    rule.name = "line comment";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);

    userKeyword.setFontWeight(QFont::Bold);
    userKeyword.setForeground(Qt::darkMagenta);
    rule.pattern = QRegExp("\\b(__USERKEYWORD__)\\b");
    rule.format = userKeyword;
    rule.name = "user keyword";
    rule.blockState = BS_Dummy;
    highlightingRules.append(rule);
}
//! [6]
void LuaHighlighter::addUserKeyword(const QString& keyword)
{
    QRegExp& exp = highlightingRules.last().pattern;
    QString patten = exp.pattern();
    patten = patten.left(patten.length()-3)+"|"+keyword+")\\b";
    exp.setPattern(patten);
}
//! [7]
void LuaHighlighter::highlightBlock(const QString &text)
{
    setCurrentBlockState(BS_Dummy);
    MyTextBlockUserData* p = static_cast<MyTextBlockUserData*>(currentBlockUserData());
    if(p){
        p->clear();
    }else{
        p = new MyTextBlockUserData();
        setCurrentBlockUserData(p);
    }
    qDebug()<<text;
    int offset = 0;
    int prevState = previousBlockState();
    //*
    if (prevState != BS_Dummy && prevState < BS_LastState && prevState>0){
        HighlightingRule prevRule = highlightingRules.at(prevState);
        int len = matchBlockEnd(text, offset, prevRule);
        setFormat(offset, len, prevRule);
        qDebug()<<"last rule: "<<prevRule.name<<"("<<offset<<","<<len<<")";
        offset += len;
    }
    //*/

    //foreach (const HighlightingRule &rule, highlightingRules) {
        //QRegExp expression(rule.pattern);
        //int index = expression.indexIn(text, offset);
    while(offset < text.length()){
        HighlightingRule rule;
        int matchedLength = 0;
        int index = matchPatten(text,offset,rule,matchedLength);
        while (index >= 0) {
            int length = matchedLength;
            if(rule.blockState != BS_Dummy){
                qDebug()<<"block: "<<rule.name<<"start:"<<offset;
                length = matchBlockEnd(text, index+matchedLength, rule);
                length += matchedLength;
                qDebug()<<"block: "<<"length:"<<length;
            }else{
                qDebug()<<"match: "<<rule.name<<"("<<offset<<","<<length<<")";
            }
            setFormat(index, length, rule);
            offset = index + length;
            index = matchPatten(text,offset,rule,matchedLength);
        }
        if(index == -1)break;
    }
}
//! [11]

int LuaHighlighter::matchPatten(const QString &text, int offset, HighlightingRule& r, int& matchedLength)
{
    int min = -1;
    foreach (const HighlightingRule &rule, highlightingRules) {
        QRegExp expression(rule.pattern);
        int index = expression.indexIn(text, offset);
        if(min == -1){
            min = index;
            r = rule;
            matchedLength = expression.matchedLength();
        }else if(index<min && index != -1){
            min = index;
            r = rule;
            matchedLength = expression.matchedLength();
        }
    }
    return min;
}

int LuaHighlighter::matchBlockEnd(const QString &text, int startIndex, const HighlightingRule& rule)
{
    QRegExp endExp(rule.endPattern);
    int endIndex = endExp.indexIn(text, startIndex);
    int length;
    if (endIndex == -1) {
        setCurrentBlockState(rule.blockState);
        qDebug()<<"state == 1";
        length = text.length() - startIndex;
    } else {
        length = endIndex - startIndex
                        + endExp.matchedLength();
    }
    return length;
}
