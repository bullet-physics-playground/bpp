#ifndef LUAHIGHLIGHTER_H
#define LUAHIGHLIGHTER_H

/**
 * @file high.h
 * @brief Syntax highlighting for the Lua scripts shown in the code editor.
 */

#include <QSyntaxHighlighter>

/**
 * @brief Number of distinct Lua long-bracket levels that are recognised.
 *
 * Lua long strings and long comments may be opened with any number of equals
 * signs between the brackets (@c [[, @c [=[, @c [==[, ...). The highlighter
 * builds one rule and one block state per level, for levels 0 through
 * @c LONG_QUOTA_LEVEL-1.
 */
#define LONG_QUOTA_LEVEL 10

/**
 * @brief Per-text-block record of which highlighting rules matched where.
 *
 * QSyntaxHighlighter hands the formatted result straight to Qt, which makes it
 * awkward to ask after the fact what a given character was coloured as. The
 * highlighter therefore attaches one of these to every text block and records
 * each match into it, so other code (for example the editor's tooltip and
 * auto-completion logic) can look up the token under the cursor.
 */
class MyTextBlockUserData : public QTextBlockUserData {
public:
  /**
   * @brief One recorded rule match inside a text block.
   */
  struct HighlightInfo {
    QString name; ///< Name of the rule that matched, e.g. "keyword".
    int offset;   ///< Start of the match, in characters from the block start.
    int len;      ///< Length of the match in characters.
  };

  /**
   * @brief Constructs an empty record.
   */
  MyTextBlockUserData() {}

  /**
   * @brief Destroys the record.
   */
  virtual ~MyTextBlockUserData() {}

  /**
   * @brief Records that a rule matched a span of this block.
   * @param name   Name of the matching rule.
   * @param offset Start of the match, in characters from the block start.
   * @param len    Length of the match in characters.
   */
  void addRule(const QString &name, int offset, int len) {
    HighlightInfo info;
    info.name = name;
    info.offset = offset;
    info.len = len;
    infoList.append(info);
  }

  /**
   * @brief Drops all recorded matches, ready for the block to be rehighlighted.
   */
  void clear() { infoList.clear(); }

  QList<HighlightInfo> infoList; ///< Matches recorded for this block, in the
                                 ///< order they were found.
};

/**
 * @brief Highlights Lua source, including constructs that span several lines.
 *
 * Rules are matched left to right rather than one rule at a time over the whole
 * line, so the earliest match always wins and a comment cannot be re-coloured
 * from inside a string. Constructs that can run past the end of a line (block
 * comments, quoted strings, long brackets) carry a #BlockState that is stored
 * as the Qt block state, which is how the next line knows it starts inside an
 * unterminated construct. Colours are chosen for a light or a dark palette at
 * construction time.
 */
class LuaHighlighter : public QSyntaxHighlighter {
  Q_OBJECT
public:
  /**
   * @brief Builds the Lua highlighting rules.
   *
   * Picks a light or dark colour scheme from the current QApplication palette,
   * then appends the rules in priority order: keywords, block comments, the
   * various string forms, class names, function calls and line comments. The
   * user-keyword rule is appended last so addUserKeyword() can extend it.
   *
   * @param parent Document to highlight, passed through to QSyntaxHighlighter.
   */
  explicit LuaHighlighter(QTextDocument *parent = nullptr);

  /**
   * @brief Adds one more word to the user-keyword highlighting rule.
   *
   * Rewrites the pattern of the last rule, splicing @p keyword into its
   * alternation. Used to colour the names bpp itself injects into the Lua
   * environment. The caller must rehighlight for the change to become visible.
   *
   * @param keyword The identifier to start highlighting. It is inserted into a
   *                regular expression verbatim, so it must not contain regex
   *                metacharacters.
   */
  void addUserKeyword(const QString &keyword);

protected:
  /**
   * @brief State carried from one text block to the next.
   *
   * Stored via QSyntaxHighlighter::setCurrentBlockState(). A value other than
   * #BS_Dummy means the block ended inside a construct that is still open, and
   * doubles as the index of the rule that opened it. The long-bracket levels
   * occupy the contiguous range #BS_LongQuota to #BS_LastLongQuata.
   */
  enum BlockState {
    BS_Dummy,        ///< Nothing is open; the block ended cleanly.
    BS_BlockComment, ///< Inside an unterminated @c --[[ block comment.
    BS_Dummy_Quota,  ///< Placeholder keeping the empty-string rule in step with
                     ///< its index in the rule list.
    BS_DoubleQuota,  ///< Inside an unterminated double-quoted string.
    BS_SingleQuota,  ///< Inside an unterminated single-quoted string.
    BS_LongQuota,    ///< Inside an unterminated level-0 long bracket, @c [[.
    BS_LastLongQuata = BS_LongQuota + LONG_QUOTA_LEVEL - 1, ///< Highest long
                                                            ///< bracket level.
    BS_LastState, ///< One past the last valid state; used as a bound check.
  };

  /**
   * @brief A single highlighting rule.
   *
   * A rule with #blockState set to #BS_Dummy matches entirely within one line
   * and only uses #pattern. Any other value means the rule opens a construct,
   * and #endPattern is then used to find where it closes, possibly several
   * blocks later.
   */
  struct HighlightingRule {
    /**
     * @brief Constructs a rule that does not span blocks.
     */
    HighlightingRule() : blockState(BS_Dummy) {}
    QRegExp pattern;          ///< Matches the construct, or its opening token.
    QTextCharFormat format;   ///< Formatting applied to the match.
    QRegExp endPattern;       ///< Matches the closing token; only meaningful
                              ///< for rules that span blocks.
    QString name;             ///< Rule name, recorded in MyTextBlockUserData.
    BlockState blockState;    ///< State to carry over if the construct is still
                              ///< open at the end of the block.
  };

  /**
   * @brief Highlights one text block.
   *
   * Reimplemented from QSyntaxHighlighter. First closes off any construct left
   * open by the previous block, then repeatedly takes the earliest match of any
   * rule from the current offset and formats it, extending the span to the
   * closing token for rules that span blocks.
   *
   * @param text The text of the block to highlight.
   */
  void highlightBlock(const QString &text);

  /**
   * @brief Applies a rule's format to a span and records the match.
   *
   * Wraps QSyntaxHighlighter::setFormat() so that, besides colouring the text,
   * the match is appended to the block's MyTextBlockUserData.
   *
   * @param start Start of the span, in characters from the block start.
   * @param count Length of the span in characters.
   * @param rule  The rule that matched; supplies both the format and the name.
   */
  void setFormat(int start, int count, const HighlightingRule &rule) {
    QSyntaxHighlighter::setFormat(start, count, rule.format);
    MyTextBlockUserData *p =
        static_cast<MyTextBlockUserData *>(currentBlockUserData());
    if (p) {
      p->addRule(rule.name, start, count);
    }
  }

private:
  /**
   * @brief Finds how far a block-spanning construct extends in this block.
   *
   * Searches for the rule's closing token from @p index onwards. If it is not
   * found the construct runs past the end of the block, so the rule's block
   * state is stored as the current block state and the rest of the line is
   * claimed.
   *
   * @param text  The text of the block being highlighted.
   * @param index Character offset to start searching from.
   * @param rule  The rule whose endPattern closes the construct.
   * @return Number of characters from @p index that belong to the construct,
   *         including the closing token when one was found.
   */
  int matchBlockEnd(const QString &text, int index,
                    const HighlightingRule &rule);

  /**
   * @brief Finds the earliest match of any rule at or after an offset.
   *
   * Every rule is tried and the one matching closest to @p offset wins, which
   * is what keeps, say, a @c -- inside a string from being taken as a comment.
   *
   * @param[in]  text          The text of the block being highlighted.
   * @param[in]  offset        Character offset to start searching from.
   * @param[out] rule          Receives the winning rule.
   * @param[out] matchedLength Receives the length of the winning match.
   * @return Character offset of the earliest match, or -1 if no rule matches.
   */
  int matchPatten(const QString &text, int offset, HighlightingRule &rule,
                  int &matchedLength);

  QVector<HighlightingRule> highlightingRules; ///< All rules, in priority order;
                                               ///< indices double as block
                                               ///< states.

  QRegExp commentStartExpression; ///< Opening token of a block comment.
  QRegExp commentEndExpression;   ///< Closing token of a block comment.

  QRegExp quotationStart; ///< Opening bracket of the long quotation level being
                          ///< built in the constructor.
  QRegExp quotationEnd;   ///< Matching closing bracket for #quotationStart.

  QTextCharFormat keywordFormat;           ///< Format for Lua keywords.
  QTextCharFormat classFormat;             ///< Format for Qt-style class names.
  QTextCharFormat singleLineCommentFormat; ///< Format for @c -- comments.
  QTextCharFormat multiLineCommentFormat;  ///< Format for @c --[[ comments.
  QTextCharFormat quotationFormat;         ///< Format for string literals.
  QTextCharFormat functionFormat;          ///< Format for called identifiers.
  QTextCharFormat userKeyword;             ///< Format for names registered via
                                           ///< addUserKeyword().
};

#endif // LUAHIGHLIGHTER_H
