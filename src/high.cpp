#include "high.h"

#include <QApplication>
#include <QPalette>
#include <QWidget>

LuaHighlighter::LuaHighlighter(QTextDocument *parent)
    : QSyntaxHighlighter(parent) {
  HighlightingRule rule;

  bool isDark = QApplication::palette().window().color().lightness() < 128;

  keywordFormat.setForeground(isDark ? QColor(120, 160, 255) : Qt::darkBlue);
  keywordFormat.setFontWeight(QFont::Bold);
  rule.pattern =
      QRegularExpression("\\b(and|break|do|else|elseif|end|false|for|function|if|in|local|"
              "nil|not|or|repeat|return|then|true|until|while)\\b");
  rule.format = keywordFormat;
  rule.name = "keyword";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);

  multiLineCommentFormat.setForeground(isDark ? QColor(100, 180, 100) : Qt::darkGreen);
  commentStartExpression = QRegularExpression("\\-\\-\\[\\[");
  commentEndExpression = QRegularExpression("\\]\\]");
  rule.pattern = commentStartExpression;
  rule.endPattern = commentEndExpression;
  rule.name = "block comment";
  rule.blockState = BS_BlockComment;
  rule.format = multiLineCommentFormat;
  highlightingRules.append(rule);

  quotationFormat.setForeground(isDark ? QColor(255, 140, 80) : Qt::darkRed);

  rule.format = quotationFormat;
  rule.pattern = QRegularExpression("\"\"|''");
  rule.name = "quotation";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);

  rule.format = quotationFormat;
  rule.pattern = QRegularExpression("\"");
  rule.endPattern = QRegularExpression("[^\\\\]\"");
  rule.name = "double quotation";
  rule.blockState = BS_DoubleQuota;
  highlightingRules.append(rule);

  rule.pattern = QRegularExpression("'");
  rule.endPattern = QRegularExpression("[^\\\\]'");
  rule.name = "single quotation";
  rule.blockState = BS_SingleQuota;
  highlightingRules.append(rule);

  QString s = "";
  for (int i = 0; i < LONG_QUOTA_LEVEL; i++) {
    quotationStart = QRegularExpression(QString("\\[%1\\[").arg(s));
    quotationEnd = QRegularExpression(QString("\\]%1\\]").arg(s));

    rule.pattern = quotationStart;
    rule.endPattern = quotationEnd;
    rule.blockState = static_cast<BlockState>(BS_LongQuota + i);
    rule.name = QString("long quotation %1").arg(i);
    highlightingRules.append(rule);
    s += "=";
  }

  classFormat.setFontWeight(QFont::Bold);
  classFormat.setForeground(isDark ? QColor(220, 140, 255) : Qt::darkMagenta);
  rule.pattern = QRegularExpression("\\bQ[A-Za-z]+\\b");
  rule.format = classFormat;
  rule.name = "class";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);

  functionFormat.setForeground(isDark ? QColor(140, 200, 255) : Qt::blue);
  rule.pattern = QRegularExpression("\\b[A-Za-z0-9_]+(?=\\()");
  rule.format = functionFormat;
  rule.name = "function";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);

  singleLineCommentFormat.setForeground(isDark ? QColor(100, 180, 100) : Qt::darkGreen);
  rule.pattern = QRegularExpression("\\-\\-[^\\[][^\n]*");
  rule.format = singleLineCommentFormat;
  rule.name = "line comment";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);

  userKeyword.setFontWeight(QFont::Bold);
  userKeyword.setForeground(isDark ? QColor(220, 140, 255) : Qt::darkMagenta);
  rule.pattern = QRegularExpression("\\b(__USERKEYWORD__)\\b");
  rule.format = userKeyword;
  rule.name = "user keyword";
  rule.blockState = BS_Dummy;
  highlightingRules.append(rule);
}

void LuaHighlighter::addUserKeyword(const QString &keyword) {
  QRegularExpression &exp = highlightingRules.last().pattern;
  QString patten = exp.pattern();
  patten = patten.left(patten.length() - 3) + "|" + keyword + ")\\b";
  exp.setPattern(patten);
}

void LuaHighlighter::highlightBlock(const QString &text) {
  setCurrentBlockState(BS_Dummy);
  MyTextBlockUserData *p =
      static_cast<MyTextBlockUserData *>(currentBlockUserData());
  if (p) {
    p->clear();
  } else {
    p = new MyTextBlockUserData();
    setCurrentBlockUserData(p);
  }
  int offset = 0;
  int prevState = previousBlockState();
  //*
  if (prevState != BS_Dummy && prevState < BS_LastState && prevState > 0) {
    HighlightingRule prevRule = highlightingRules.at(prevState);
    int len = matchBlockEnd(text, offset, prevRule);
    setFormat(offset, len, prevRule);
    offset += len;
  }
  //*/

  // foreach (const HighlightingRule &rule, highlightingRules) {
  // QRegularExpression expression(rule.pattern);
  // int index = expression.indexIn(text, offset);
  while (offset < text.length()) {
    HighlightingRule rule;
    int matchedLength = 0;
    int index = matchPatten(text, offset, rule, matchedLength);
    while (index >= 0) {
      int length = matchedLength;
      if (rule.blockState != BS_Dummy) {
        length = matchBlockEnd(text, index + matchedLength, rule);
        length += matchedLength;
      }
      setFormat(index, length, rule);
      offset = index + length;
      index = matchPatten(text, offset, rule, matchedLength);
    }
    if (index == -1)
      break;
  }
}

int LuaHighlighter::matchPatten(const QString &text, int offset,
                                HighlightingRule &r, int &matchedLength) {
  int min = -1;
  foreach (const HighlightingRule &rule, highlightingRules) {
    QRegularExpression expression(rule.pattern);
    QRegularExpressionMatch match = expression.match(text, offset);
    int index = match.capturedStart();
    if (min == -1) {
      min = index;
      r = rule;
      matchedLength = match.capturedLength();
    } else if (index < min && index != -1) {
      min = index;
      r = rule;
      matchedLength = match.capturedLength();
    }
  }
  return min;
}

int LuaHighlighter::matchBlockEnd(const QString &text, int startIndex,
                                  const HighlightingRule &rule) {
  QRegularExpression endExp(rule.endPattern);
  QRegularExpressionMatch match = endExp.match(text, startIndex);
  int endIndex = match.capturedStart();
  int length;
  if (endIndex == -1) {
    setCurrentBlockState(rule.blockState);
    length = text.length() - startIndex;
  } else {
    length = endIndex - startIndex + match.capturedLength();
  }
  return length;
}
