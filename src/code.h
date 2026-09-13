#ifndef CODEEDITOR_H
#define CODEEDITOR_H

/**
 * @file code.h
 * @brief The Lua script editor: line numbers, completion and LSP support.
 */

#include <QDebug>
#include <QSettings>

#include <QByteArray>
#include <QObject>
#include <QPlainTextEdit>
#include <QStringList>
#include <QVarLengthArray>
#include <QWidget>

#include "high.h"

class QPaintEvent;
class QResizeEvent;
class QSize;
class QCompleter;
class QJsonObject;
class QModelIndex;
class QProcess;
class QTextBrowser;

class LineNumberArea;

/**
 * @brief A plain text editor for Lua scripts with a line number margin,
 *        syntax highlighting and word completion.
 *
 * The editor owns the file it is showing: load(), save() and saveAs() manage
 * @c script_filename and announce changes through scriptLoaded() and
 * scriptSaved(). Syntax colouring is delegated to a LuaHighlighter installed
 * on the document.
 *
 * When completion is enabled the editor offers two sources of candidates,
 * merged into one popup: a local list built from the Lua keywords plus every
 * identifier appearing in the buffer, and, if a Lua language server could be
 * started, whatever that server proposes. The server is driven over stdio with
 * a minimal hand-rolled LSP client - just enough of @c initialize,
 * @c didOpen / @c didChange and @c textDocument/completion to keep the popup
 * fed - and its results carry documentation shown next to the popup.
 *
 * Key presses the editor does not consume are re-emitted through keyPressed()
 * so the rest of the application can treat them as shortcuts.
 */
class CodeEditor : public QPlainTextEdit {
  Q_OBJECT;

public:
  /**
   * @brief Builds the editor, its highlighter and optionally its completer.
   *
   * Reads the font family and size from the settings, falling back to a
   * platform-appropriate monospace face. When @p enableCompletion is true it
   * also creates the completer popup and tries to start the language server
   * named by the @c editor/languageServer setting. Registers the Ctrl+1 /
   * Ctrl+2 / Ctrl+3 open, save and save-as shortcuts.
   *
   * @param settings         Settings store to read the editor preferences from.
   * @param parent           Parent widget, passed through to QPlainTextEdit.
   * @param enableCompletion Whether to enable word completion and the language
   *                         server. Off by default, so secondary editors do not
   *                         each spawn a server process.
   */
  CodeEditor(QSettings *settings, QWidget *parent = nullptr,
             bool enableCompletion = false);

  /**
   * @brief Shuts the language server down and destroys the editor.
   */
  ~CodeEditor() override; // Add destructor declaration

  /**
   * @brief Paints the line number margin.
   *
   * Called by LineNumberArea::paintEvent(), which owns the widget but has no
   * access to the editor's block geometry. Walks the visible text blocks and
   * draws each block's one-based number right-aligned in the margin, using
   * colours picked for a light or dark palette.
   *
   * @param event The paint event of the line number widget; its rect is used
   *              to clip the work to the damaged region.
   */
  void lineNumberAreaPaintEvent(QPaintEvent *event);

  /**
   * @brief Computes how wide the line number margin needs to be.
   *
   * Sized to fit the highest line number currently in the document.
   *
   * @return The required width in pixels, including a small left padding.
   */
  int lineNumberAreaWidth();

  /**
   * @brief Returns the path of the script being edited.
   * @return The absolute path of the loaded file, the name last saved to, or
   *         the literal @c "no_name" for a buffer that has never been saved.
   */
  QString scriptFile() const;

public slots:
  /**
   * @brief Discards the buffer and starts a new, unnamed script.
   *
   * Resets the file name to @c "no_name" and emits scriptLoaded().
   */
  void clear();

  /**
   * @brief Saves the script back to the file it came from.
   *
   * Falls back to saveAs() and prompts for a name if the buffer has never been
   * saved.
   *
   * @return True if the file was written.
   */
  bool save();

  /**
   * @brief Loads a script into the editor.
   *
   * The path is resolved to an absolute one before being stored, because
   * Gui::setCurrentFile() changes the process's working directory to the
   * script's own directory; a relative name kept here would later be saved
   * against the wrong directory.
   *
   * @param filename Path to read. If empty, the user is asked for one with a
   *                 file dialog.
   * @return True if a file was chosen and read; false if the dialog was
   *         cancelled or the file could not be opened.
   */
  bool load(QString filename = QString());

  /**
   * @brief Writes the buffer to a file and adopts it as the current script.
   *
   * Emits scriptSaved() on success; reports failure to write with a message
   * box.
   *
   * @param filename Path to write. If empty, the user is asked for one with a
   *                 save dialog defaulting to the @c .lua suffix.
   * @return True if the file was written.
   */
  bool saveAs(QString filename = QString());

  /**
   * @brief Sets the editor font.
   *
   * The font is forced to fixed pitch regardless of the family requested.
   *
   * @param family Font family name.
   * @param size   Point size.
   */
  void setFont(QString family, uint size);

  /**
   * @brief Switches to a different Lua language server executable.
   *
   * Stops the running server, if any, and starts the new one. An empty path
   * leaves the editor with no server, and therefore with local completions
   * only.
   *
   * @param path Program to run; it is started with @c --stdio.
   */
  void setLanguageServerExecutable(const QString &path);

  /**
   * @brief Appends a line of text to the end of the buffer.
   * @param l The line to append.
   */
  void appendLine(QString l) { appendPlainText(l); }

  /**
   * @brief Replaces the whole buffer, keeping the cursor where it was.
   *
   * Used to push text into the editor from elsewhere without making the view
   * jump back to the top.
   *
   * @param txt The new contents.
   */
  void replaceText(QString txt) {
    int pos = textCursor().position();

    setPlainText(txt);

    QTextCursor cursor = this->textCursor();
    cursor.setPosition(pos, QTextCursor::MoveAnchor);
    setTextCursor(cursor);
  }

signals:
  /**
   * @brief Emitted whenever the buffer is replaced by load() or clear().
   */
  void scriptLoaded();

  /**
   * @brief Emitted after the script has been written to disk.
   */
  void scriptSaved();

  /**
   * @brief Emitted for a key press the editor did not consume.
   *
   * Lets the surrounding application interpret the event as a shortcut.
   *
   * @param e The originating key event; owned by Qt and only valid for the
   *          duration of the emission.
   */
  void keyPressed(QKeyEvent *e);

  /**
   * @brief Emitted when the user pressed Ctrl+S.
   *
   * Handled here rather than through a window shortcut so the key press is not
   * also forwarded to the Viewer, which would read a bare @c S as its
   * start/stop simulation key.
   */
  void savePressed();

protected:
  /**
   * @brief Filters events for the completer popup.
   *
   * Takes Return and Enter to accept the highlighted candidate, refreshes the
   * documentation pane as the selection moves, and hides that pane when the
   * popup closes.
   *
   * @param watched The object the event was sent to.
   * @param event   The event.
   * @return True if the event was consumed here.
   */
  bool eventFilter(QObject *watched, QEvent *event) override;

  /**
   * @brief Handles editor key presses.
   *
   * Accepts a completion on Return while the popup is up, opens the popup on
   * Ctrl+Space, turns Ctrl+S into savePressed(), and otherwise lets
   * QPlainTextEdit handle the key. Typing with the popup open refreshes both
   * the local and the language server candidates. Keys that were not accepted
   * are forwarded via keyPressed().
   *
   * @param e The key event to handle.
   */
  void keyPressEvent(QKeyEvent *e) override;

  /**
   * @brief Keeps the line number margin aligned with the viewport.
   * @param event The resize event.
   */
  void resizeEvent(QResizeEvent *event) override;

private slots:
  /**
   * @brief Reserves space at the left of the viewport for the line numbers.
   * @param newBlockCount New number of text blocks. Unused; the width is
   *                      recomputed from the document either way.
   */
  void updateLineNumberAreaWidth(int newBlockCount);

  /**
   * @brief Paints the subtle highlight behind the line holding the cursor.
   *
   * Chooses a translucent light or a pale yellow wash depending on whether the
   * palette is dark. Does nothing while the editor is read-only.
   */
  void highlightCurrentLine();

  /**
   * @brief Scrolls or repaints the line number margin to match the viewport.
   * @param rect The part of the viewport that needs updating.
   * @param dy   Vertical scroll distance in pixels, or 0 for a plain repaint.
   */
  void updateLineNumberArea(const QRect &rect, int dy);

  /**
   * @brief Replaces the word under the cursor with a completion.
   * @param completion The text to insert.
   */
  void insertCompletion(const QString &completion);

private:
  /**
   * @brief Returns the word the cursor is currently on.
   * @return The word under the cursor, or an empty string if there is none.
   */
  QString textUnderCursor() const;

  /**
   * @brief Rebuilds the candidate list and shows the completion popup.
   *
   * Merges the local candidates with whatever the language server last sent,
   * filters them by the word under the cursor, positions the popup under the
   * caret and shows the documentation for the first entry.
   */
  void showCompletion();

  /**
   * @brief Builds the completion candidates that need no language server.
   *
   * Combines the Lua keywords and a few names bpp itself provides with every
   * identifier that appears anywhere in the buffer, so completion still works
   * when no server is running.
   *
   * @return The candidates, de-duplicated and sorted case-insensitively.
   */
  QStringList localCompletions() const;

  /**
   * @brief Loads a candidate list into the completer's model.
   *
   * Duplicates are dropped and the entries sorted. Each item carries the
   * documentation the language server supplied for it, if any, in its tooltip
   * role.
   *
   * @param completions The candidates to show.
   */
  void updateCompletionModel(const QStringList &completions);

  /**
   * @brief Accepts the candidate currently highlighted in the popup.
   *
   * Inserts it, closes the popup and hides the documentation pane. Does
   * nothing if nothing is selected.
   */
  void insertSelectedCompletion();

  /**
   * @brief Shows the documentation for one completion candidate.
   *
   * Creates the tooltip-style browser on first use and parks it to the right
   * of the popup. Candidates with no documentation hide the pane instead.
   *
   * @param index Index of the candidate in the completion model.
   */
  void showCompletionDocumentation(const QModelIndex &index);

  /**
   * @brief Hides the completion documentation pane if it exists.
   */
  void hideCompletionDocumentation();

  /**
   * @brief Starts a Lua language server process.
   *
   * The process is launched with @c --stdio; initializeLanguageServer() runs
   * once it is up and handleLanguageServerOutput() consumes its replies. An
   * empty @p program disables the server.
   *
   * @param program Executable to run.
   */
  void startLanguageServer(const QString &program);

  /**
   * @brief Asks the language server to exit and tears the process down.
   *
   * Sends @c exit and waits briefly, then terminates the process if it has not
   * left, and clears all the LSP-related state. Safe to call when no server is
   * running.
   */
  void stopLanguageServer();

  /**
   * @brief Sends one JSON-RPC message to the language server.
   *
   * Wraps @p params in a JSON-RPC 2.0 envelope and writes it with the
   * @c Content-Length header the protocol requires. Does nothing if no server
   * is running.
   *
   * @param method    The LSP method name.
   * @param params    The method's parameters.
   * @param requestId Request id to send, making this a request rather than a
   *                  notification. Pass a negative value, the default, for a
   *                  notification.
   */
  void sendLspMessage(const QString &method, const QJsonObject &params,
                      int requestId = -1);

  /**
   * @brief Sends the LSP @c initialize request.
   *
   * Announces that the client is interested in completion and roots the server
   * at the current working directory. Called when the process starts; the
   * reply is what sets @c lspInitialized.
   */
  void initializeLanguageServer();

  /**
   * @brief Tells the server about the document, via @c textDocument/didOpen.
   *
   * Sends the current buffer and resets the document version. Does nothing
   * until the server has finished initializing.
   */
  void openLspDocument();

  /**
   * @brief Sends the edited buffer with @c textDocument/didChange.
   *
   * Uses full-document synchronisation: the whole text is sent on every
   * change, with an incremented version number.
   */
  void updateLspDocument();

  /**
   * @brief Asks the server for completions at the cursor.
   *
   * Clears the previous server candidates, falls back to the local ones while
   * the request is outstanding, and records the request id so the reply can be
   * recognised. Does nothing before the document has been opened.
   */
  void requestLspCompletion();

  /**
   * @brief Reads and dispatches messages coming back from the server.
   *
   * Accumulates stdout until a complete @c Content-Length framed message is
   * available, then handles as many as have arrived. The reply to
   * @c initialize flips the client into the initialized state and opens the
   * document; the reply to a completion request fills @c lspCompletions and
   * @c lspCompletionDocumentation and refreshes the popup if it is up. Other
   * messages are ignored.
   */
  void handleLanguageServerOutput();

  /**
   * @brief The URI the language server knows this document by.
   * @return A @c file:// URI for the script, or one for @c untitled.lua in the
   *         current directory when the buffer has no file yet.
   */
  QString lspDocumentUri() const;

  QWidget *lineNumberArea; ///< The margin widget drawing the line numbers.

  QCompleter *completer;                 ///< Drives the completion popup; null
                                         ///< when completion is disabled.
  QTextBrowser *completionDocumentation; ///< Tooltip window showing the
                                         ///< documentation for the selected
                                         ///< candidate; created on first use.
  QProcess *languageServer;              ///< The running language server, or
                                         ///< null.
  QByteArray languageServerOutput;       ///< Buffer of server output not yet
                                         ///< forming a complete message.
  QString lspOpenedUri;                  ///< URI the server currently has open;
                                         ///< empty if no document was sent.
  QStringList lspCompletions;            ///< Candidates from the last
                                         ///< completion reply.
  QHash<QString, QString> lspCompletionDocumentation; ///< Documentation text
                                                      ///< per candidate.
  int lspRequestId;           ///< Counter handing out JSON-RPC request ids.
  int lspInitializeRequestId; ///< Id of the pending @c initialize request.
  int lspCompletionRequestId; ///< Id of the most recent completion request;
                              ///< replies with any other id are ignored.
  int lspDocumentVersion;     ///< Document version reported to the server.
  bool lspInitialized;        ///< True once the server answered @c initialize.

  LuaHighlighter *highlighter; ///< Syntax highlighter on this document.

  QString script_filename; ///< Path of the edited script, or @c "no_name".
};

/**
 * @brief The margin at the left of a CodeEditor that shows line numbers.
 *
 * Deliberately thin: it knows its width and forwards painting back to the
 * editor, which is the side that can see the text block geometry.
 */
class LineNumberArea : public QWidget {
  Q_OBJECT;

public:
  /**
   * @brief Constructs the margin as a child of its editor.
   * @param editor The editor to draw line numbers for.
   */
  LineNumberArea(CodeEditor *editor) : QWidget(editor) { codeEditor = editor; }

  /**
   * @brief Reports the width the editor says the line numbers need.
   * @return A size whose width comes from CodeEditor::lineNumberAreaWidth()
   *         and whose height is unconstrained.
   */
  QSize sizeHint() const { return QSize(codeEditor->lineNumberAreaWidth(), 0); }

protected:
  /**
   * @brief Hands painting over to CodeEditor::lineNumberAreaPaintEvent().
   * @param event The paint event.
   */
  void paintEvent(QPaintEvent *event) {
    codeEditor->lineNumberAreaPaintEvent(event);
  }

private:
  CodeEditor *codeEditor; ///< The editor this margin belongs to.
};

#endif
