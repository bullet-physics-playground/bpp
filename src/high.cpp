#include <QtGui>

#include "high.h"

Highlighter::Highlighter(QTextDocument *parent) : QSyntaxHighlighter(parent) {
  HighlightingRule rule;
  
  constantFormat.setForeground(Qt::darkGreen);
  rule.pattern = QRegExp("[-+]?(?:(?:\\d+\\.\\d+)|(?:\\.\\d+)|(?:\\d+\\.?))");
  rule.format = constantFormat;
  highlightingRules.append(rule);

  classFormat.setForeground(Qt::darkMagenta);
  rule.pattern = QRegExp("\\b[A-Za-z][A-Za-z0-9_]*\\b");
  rule.format = classFormat;
  highlightingRules.append(rule);

  functionFormat.setForeground(Qt::blue);
  rule.pattern = QRegExp("\\b[A-Za-z0-9_]+ *(?=\\()");
  rule.format = functionFormat;
  highlightingRules.append(rule);

  keywordFormat.setForeground(Qt::darkBlue);
  keywordFormat.setFontWeight(QFont::Bold);
  QStringList keywordPatterns;
  
  keywordPatterns
	<< "\\bdo\\b" << "\\bend\\b" << "\\bfor\\b" << "\\bwhile\\b"
	<< "\\bif\\b" << "\\bthen\\b" << "\\belse\\b" << "\\belseif\\b"
	<< "\\brepeat\\b" << "\\buntil\\b" << "\\bfunction\\b" << "\\blocal\\b"
	<< "\\breturn\\b" << "\\bin\\b" << "\\bbreak\\b" << "\\bnot\\b"
	<< "\\bnil\\b" << "\\band\\b" << "\\bor\\b" << "\\btrue\\b"
	<< "\\bfalse\\b";
  foreach (QString pattern, keywordPatterns) {
	rule.pattern = QRegExp(pattern);
	rule.format = keywordFormat;
	highlightingRules.append(rule);
  }
  quotationFormat.setForeground(Qt::darkGreen);
  rule.pattern = QRegExp("\"[^\"]*\"");
  rule.format = quotationFormat;
  highlightingRules.append(rule);
  
  rule.pattern = QRegExp("'[^']*'");
  rule.format = quotationFormat;
  highlightingRules.append(rule);
  
  singleLineCommentFormat.setForeground(Qt::black);
  singleLineCommentFormat.setFontItalic(true);
  rule.pattern = QRegExp("--[^\n]*");
  rule.format = singleLineCommentFormat;
  highlightingRules.append(rule);
}

void Highlighter::highlightBlock(const QString &text) {
  foreach (HighlightingRule rule, highlightingRules) {
	QRegExp expression(rule.pattern);
	int index = text.indexOf(expression);
	while (index >= 0) {
		int length = expression.matchedLength();
		setFormat(index, length, rule.format);
		index = text.indexOf(expression, index + length);
	  }
  }
}
