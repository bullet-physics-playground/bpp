#include <QtGui>
#include <QtWidgets>

#include <QDebug>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegExp>
#include <QSet>
#include <QStandardItemModel>
#include <QTextBrowser>
#include <QTimer>
#include <QUrl>

#include "code.h"

CodeEditor::CodeEditor(QSettings *s, QWidget *parent, bool enableCompletion)
    : QPlainTextEdit(parent), completer(nullptr), completionDocumentation(nullptr),
      languageServer(nullptr),
      lspRequestId(0), lspInitializeRequestId(-1),
      lspCompletionRequestId(-1), lspDocumentVersion(0),
      lspInitialized(false) {

  QString family;
#ifdef Q_OS_LINUX
  family = "Mono";
#elif defined(Q_OS_WIN)
  family = "Console";
#elif defined(Q_OS_MAC)
  family = "Monaco";
#else
  family = "Courier";
#endif

  family = s->value("editor/fontfamily", family).toString();
  uint size = s->value("editor/fontsize", 12).toUInt();

  setFont(family, size);

  highlighter = new LuaHighlighter(document());

  if (enableCompletion) {
    completer = new QCompleter(this);
    completer->setWidget(this);
    completer->setCaseSensitivity(Qt::CaseInsensitive);
    completer->setCompletionMode(QCompleter::PopupCompletion);
    completer->popup()->installEventFilter(this);
    connect(completer,
            static_cast<void (QCompleter::*)(const QString &)>(
                &QCompleter::activated),
            this, &CodeEditor::insertCompletion);
    connect(completer->popup(), &QAbstractItemView::entered, this,
            [this](const QModelIndex &index) {
              showCompletionDocumentation(index);
            });
    connect(this, &CodeEditor::textChanged, this, [this]() {
      if (lspInitialized && !lspOpenedUri.isEmpty())
        updateLspDocument();
    });
    connect(this, &CodeEditor::scriptLoaded, this, [this]() {
      lspOpenedUri.clear();
      if (lspInitialized)
        openLspDocument();
    });
    startLanguageServer(
        s->value("editor/languageServer", "lua-language-server").toString());
  }

  lineNumberArea = new LineNumberArea(this);

  connect(this, &CodeEditor::blockCountChanged, this,
          &CodeEditor::updateLineNumberAreaWidth);
  connect(this, &CodeEditor::updateRequest, this,
          &CodeEditor::updateLineNumberArea);
  connect(this, &CodeEditor::cursorPositionChanged, this,
          &CodeEditor::highlightCurrentLine);

  updateLineNumberAreaWidth(0);
  highlightCurrentLine();

  QAction *a = new QAction(tr("Open a file"), this);
  a->setShortcut(tr("Ctrl+1"));
  a->setShortcutContext(Qt::WidgetShortcut);
  addAction(a);
  connect(a, &QAction::triggered, this, [this]() { load(""); });

  a = new QAction(tr("Save file"), this);
  a->setShortcut(tr("Ctrl+2"));
  a->setShortcutContext(Qt::WidgetShortcut);
  addAction(a);
  connect(a, &QAction::triggered, this, [this]() { save(); });

  a = new QAction(tr("Save to file"), this);
  a->setShortcut(tr("Ctrl+3"));
  a->setShortcutContext(Qt::WidgetShortcut);
  addAction(a);
  connect(a, &QAction::triggered, this, [this]() { saveAs(""); });
}

CodeEditor::~CodeEditor() {
  stopLanguageServer();
}

void CodeEditor::stopLanguageServer() {
  if (!languageServer)
    return;

  if (languageServer->state() == QProcess::Running) {
    sendLspMessage("exit", QJsonObject());
    if (!languageServer->waitForFinished(500)) {
      languageServer->terminate();
      languageServer->waitForFinished(500);
    }
  }
  delete languageServer;
  languageServer = nullptr;
  languageServerOutput.clear();
  lspOpenedUri.clear();
  lspCompletions.clear();
  lspInitialized = false;
}

void CodeEditor::setLanguageServerExecutable(const QString &path) {
  stopLanguageServer();
  startLanguageServer(path);
}

void CodeEditor::clear() {

  setPlainText("");
  script_filename = "no_name";
  emit scriptLoaded();
}

bool CodeEditor::load(QString filename) {
  if (filename.isEmpty()) {
    filename = QString(".lua");
    filename =
        QFileDialog::getOpenFileName(this, "Open a script", script_filename,
                                     "Lua source (*.lua);;All files (*)");
    if (filename.isEmpty())
      return false;
  }

  QFile file(filename);
  if (!file.open(QIODevice::ReadOnly)) {

    /*
QMessageBox::warning(this, tr("Application error"),
                     tr("Cannot read file %1\n").arg(filename));
*/
    return false;
  }

  QTextStream os(&file);
  QString p = os.readAll();
  file.close();
  setPlainText(p);
  // Resolve to an absolute path now, before anything changes the process's
  // working directory (e.g. Gui::setCurrentFile chdir's into this script's
  // directory) - otherwise a later save() would try to write the relative
  // path against the wrong directory.
  script_filename = QFileInfo(filename).absoluteFilePath();
  emit scriptLoaded();

  return true;
}

bool CodeEditor::saveAs(QString filename) {
  if (filename.isEmpty()) {
    QFileDialog dialog(this, tr("Save a script"), script_filename,
                       tr("Lua source (*.lua);;All files (*)"));
    dialog.setAcceptMode(QFileDialog::AcceptSave);
    dialog.setDefaultSuffix("lua");
    dialog.selectFile(script_filename);

    if (dialog.exec())
      filename = dialog.selectedFiles().first();
    else
      return false;
  }

  QFile file(filename);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QMessageBox::warning(this, tr("Application error"),
                         tr("Cannot write file %1\n").arg(filename));
    return false;
  }
  QTextStream os(&file);
  os << toPlainText();
  file.close();
  script_filename = filename;

  emit scriptSaved();

  return true;
}

bool CodeEditor::save() {
  if (QString("no_name") == script_filename) {
    return saveAs("");
  } else {
    return saveAs(script_filename);
  }
}

QString CodeEditor::scriptFile() const { return script_filename; }

void CodeEditor::setFont(QString family, uint size) {

  //  qDebug() << " setFont " << family << size;

  QFont font;
  font.setFamily(family);
  font.setFixedPitch(true);
  font.setPointSize(size);

  QPlainTextEdit::setFont(font);
}

int CodeEditor::lineNumberAreaWidth() {
  int digits = 1;
  int max = qMax(1, blockCount());
  while (max >= 10) {
    max /= 10;
    ++digits;
  }

  int space = 3 + fontMetrics().horizontalAdvance(QLatin1Char('9')) * digits;

  return space;
}

void CodeEditor::updateLineNumberAreaWidth(int /* newBlockCount */) {
  setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}

void CodeEditor::updateLineNumberArea(const QRect &rect, int dy) {
  if (dy)
    lineNumberArea->scroll(0, dy);
  else
    lineNumberArea->update(0, rect.y(), lineNumberArea->width(), rect.height());

  if (rect.contains(viewport()->rect()))
    updateLineNumberAreaWidth(0);
}

void CodeEditor::resizeEvent(QResizeEvent *e) {
  QPlainTextEdit::resizeEvent(e);

  QRect cr = contentsRect();
  lineNumberArea->setGeometry(
      QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}

void CodeEditor::highlightCurrentLine() {
  QList<QTextEdit::ExtraSelection> extraSelections;

  if (!isReadOnly()) {
    QTextEdit::ExtraSelection selection;

    bool isDark = palette().window().color().lightness() < 128;
    QColor lineColor = isDark ? QColor(255, 255, 255, 20)
                              : QColor(Qt::yellow).lighter(160);

    selection.format.setBackground(lineColor);
    selection.format.setProperty(QTextFormat::FullWidthSelection, true);
    selection.cursor = textCursor();
    selection.cursor.clearSelection();
    extraSelections.append(selection);
  }

  setExtraSelections(extraSelections);
}

void CodeEditor::lineNumberAreaPaintEvent(QPaintEvent *event) {
  QPainter painter(lineNumberArea);

  bool isDark = palette().window().color().lightness() < 128;
  QColor bg = isDark ? QColor(50, 50, 50) : Qt::lightGray;
  QColor fg = isDark ? QColor(180, 180, 180) : Qt::black;

  painter.fillRect(event->rect(), bg);

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  int top = (int)blockBoundingGeometry(block).translated(contentOffset()).top();
  int bottom = top + (int)blockBoundingRect(block).height();

  while (block.isValid() && top <= event->rect().bottom()) {
    if (block.isVisible() && bottom >= event->rect().top()) {
      QString number = QString::number(blockNumber + 1);
      painter.setPen(fg);
      painter.drawText(0, top, lineNumberArea->width(), fontMetrics().height(),
                        Qt::AlignRight, number);
    }

    block = block.next();
    top = bottom;
    bottom = top + (int)blockBoundingRect(block).height();
    ++blockNumber;
  }
}

bool CodeEditor::eventFilter(QObject *watched, QEvent *event) {
  if (completer && watched == completer->popup()) {
    if (event->type() == QEvent::Hide) {
      hideCompletionDocumentation();
    } else if (event->type() == QEvent::KeyPress) {
      auto *keyEvent = static_cast<QKeyEvent *>(event);
      if (keyEvent->key() == Qt::Key_Return ||
          keyEvent->key() == Qt::Key_Enter) {
        insertSelectedCompletion();
        return true;
      }
      if (keyEvent->key() == Qt::Key_Up || keyEvent->key() == Qt::Key_Down ||
          keyEvent->key() == Qt::Key_PageUp ||
          keyEvent->key() == Qt::Key_PageDown) {
        QTimer::singleShot(0, this, [this]() {
          showCompletionDocumentation(completer->popup()->currentIndex());
        });
      }
    }
  }

  return QPlainTextEdit::eventFilter(watched, event);
}

void CodeEditor::keyPressEvent(QKeyEvent *e) {
  if (completer && completer->popup()->isVisible() &&
      (e->key() == Qt::Key_Return || e->key() == Qt::Key_Enter)) {
    insertSelectedCompletion();
    e->accept();
    return;
  }

  if (completer && e->key() == Qt::Key_Space &&
      e->modifiers() == Qt::ControlModifier) {
    showCompletion();
    e->accept();
    return;
  }

  if (e->key() == Qt::Key_S && e->modifiers() == Qt::ControlModifier) {
    // Handled explicitly here (rather than relying on the window's
    // Ctrl+S QAction shortcut) because this event would otherwise fall
    // through to keyPressed() below and get forwarded to the Viewer,
    // whose own key handling toggles the simulation on a bare 'S' key
    // regardless of modifiers.
    e->accept();
    emit savePressed();
    return;
  }

  QPlainTextEdit::keyPressEvent(e);

  if (e->isAccepted()) {
    if (completer && completer->popup()->isVisible()) {
      showCompletion();
      requestLspCompletion();
    }
    return;
  }

  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
    qDebug() << "Unknown key from a macro probably";
    return;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt,
  // Meta.
  if (key == Qt::Key_Control || key == Qt::Key_Shift || key == Qt::Key_Alt ||
      key == Qt::Key_Meta) {
    // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
    // qDebug() << "New KeySequence:" <<
    // QKeySequence(keyInt).toString(QKeySequence::NativeText); return;
  }

  // check for a combination of user clicks
  Qt::KeyboardModifiers modifiers = e->modifiers();
  QString keyText = e->text();
  // if the keyText is empty than it's a special key like F1, F5, ...
  //  qDebug() << "Pressed Key:" << keyText;

  QList<Qt::Key> modifiersList;
  if (modifiers & Qt::ShiftModifier)
    keyInt += Qt::SHIFT;
  if (modifiers & Qt::ControlModifier)
    keyInt += Qt::CTRL;
  if (modifiers & Qt::AltModifier)
    keyInt += Qt::ALT;
  if (modifiers & Qt::MetaModifier)
    keyInt += Qt::META;

  QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);

  // qDebug() << "CodeEditor::keyPressed(" << seq << ")";

  emit keyPressed(e);
}

QString CodeEditor::textUnderCursor() const {
  QTextCursor cursor = textCursor();
  cursor.select(QTextCursor::WordUnderCursor);
  return cursor.selectedText();
}

void CodeEditor::showCompletion() {
  updateCompletionModel(localCompletions() + lspCompletions);

  const QString prefix = textUnderCursor();
  completer->setCompletionPrefix(prefix);
  completer->popup()->setCurrentIndex(completer->completionModel()->index(0, 0));

  QRect rect = cursorRect();
  rect.setWidth(completer->popup()->sizeHintForColumn(0) +
                completer->popup()->verticalScrollBar()->sizeHint().width());
  completer->complete(rect);
  showCompletionDocumentation(completer->popup()->currentIndex());
}

QStringList CodeEditor::localCompletions() const {
  QSet<QString> words = {
      "and",       "break",    "do",       "else",      "elseif",
      "end",       "false",    "for",      "function",  "if",
      "in",        "local",    "nil",      "not",       "or",
      "repeat",    "return",   "then",     "true",      "until",
      "while",     "require",  "print",    "pairs",     "ipairs",
      "next",      "type",     "tonumber", "tostring",  "math",
      "string",    "table",    "v",        "btVector3", "btQuaternion",
  };

  QRegExp wordExpression("\\b[A-Za-z_][A-Za-z0-9_]*\\b");
  const QString script = toPlainText();
  int index = wordExpression.indexIn(script);
  while (index >= 0) {
    words.insert(wordExpression.cap());
    index = wordExpression.indexIn(script, index + wordExpression.matchedLength());
  }

  QStringList completions = words.values();
  completions.sort(Qt::CaseInsensitive);
  return completions;
}

void CodeEditor::updateCompletionModel(const QStringList &completions) {
  QStringList uniqueCompletions = completions;
  uniqueCompletions.removeDuplicates();
  uniqueCompletions.sort(Qt::CaseInsensitive);

  auto *model = qobject_cast<QStandardItemModel *>(completer->model());
  if (!model) {
    model = new QStandardItemModel(completer);
    completer->setModel(model);
  }
  model->clear();
  for (const QString &completion : uniqueCompletions) {
    auto *item = new QStandardItem(completion);
    item->setData(lspCompletionDocumentation.value(completion), Qt::ToolTipRole);
    model->appendRow(item);
  }
}

void CodeEditor::insertSelectedCompletion() {
  const QModelIndex index = completer->popup()->currentIndex();
  if (!index.isValid())
    return;

  insertCompletion(index.data(Qt::DisplayRole).toString());
  completer->popup()->hide();
  hideCompletionDocumentation();
}

void CodeEditor::showCompletionDocumentation(const QModelIndex &index) {
  const QString documentation = index.data(Qt::ToolTipRole).toString();
  if (documentation.isEmpty()) {
    hideCompletionDocumentation();
    return;
  }

  if (!completionDocumentation) {
    completionDocumentation = new QTextBrowser(this);
    completionDocumentation->setReadOnly(true);
    completionDocumentation->setOpenExternalLinks(true);
    completionDocumentation->setWindowFlags(Qt::ToolTip);
  }

  completionDocumentation->setHtml(
      QString("<html><body>%1</body></html>")
          .arg(documentation.toHtmlEscaped().replace("\n", "<br>")));
  completionDocumentation->resize(360, 180);
  completionDocumentation->move(completer->popup()->mapToGlobal(
      QPoint(completer->popup()->width() + 8, 0)));
  completionDocumentation->show();
}

void CodeEditor::hideCompletionDocumentation() {
  if (completionDocumentation)
    completionDocumentation->hide();
}

QString CodeEditor::lspDocumentUri() const {
  if (!script_filename.isEmpty() && script_filename != "no_name")
    return QUrl::fromLocalFile(script_filename).toString();

  return QUrl::fromLocalFile(QDir::current().filePath("untitled.lua"))
      .toString();
}

void CodeEditor::startLanguageServer(const QString &program) {
  if (program.isEmpty())
    return;

  languageServer = new QProcess(this);
  connect(languageServer, &QProcess::started, this,
          &CodeEditor::initializeLanguageServer);
  connect(languageServer, &QProcess::readyReadStandardOutput, this,
          &CodeEditor::handleLanguageServerOutput);
  languageServer->start(program, QStringList() << "--stdio");
}

void CodeEditor::sendLspMessage(const QString &method,
                                const QJsonObject &params, int requestId) {
  if (!languageServer || languageServer->state() != QProcess::Running)
    return;

  QJsonObject message;
  message["jsonrpc"] = "2.0";
  message["method"] = method;
  message["params"] = params;
  if (requestId >= 0)
    message["id"] = requestId;

  const QByteArray payload = QJsonDocument(message).toJson(QJsonDocument::Compact);
  languageServer->write("Content-Length: " + QByteArray::number(payload.size()) +
                        "\r\n\r\n" + payload);
}

void CodeEditor::initializeLanguageServer() {
  QJsonObject capabilities;
  QJsonObject textDocument;
  textDocument["completion"] = QJsonObject();
  capabilities["textDocument"] = textDocument;

  QJsonObject params;
  params["processId"] = static_cast<qint64>(QCoreApplication::applicationPid());
  params["rootUri"] = QUrl::fromLocalFile(QDir::currentPath()).toString();
  params["capabilities"] = capabilities;
  lspInitializeRequestId = ++lspRequestId;
  sendLspMessage("initialize", params, lspInitializeRequestId);
}

void CodeEditor::openLspDocument() {
  if (!lspInitialized)
    return;

  lspOpenedUri = lspDocumentUri();
  lspDocumentVersion = 1;
  QJsonObject document;
  document["uri"] = lspOpenedUri;
  document["languageId"] = "lua";
  document["version"] = lspDocumentVersion;
  document["text"] = toPlainText();
  QJsonObject params;
  params["textDocument"] = document;
  sendLspMessage("textDocument/didOpen", params);
}

void CodeEditor::updateLspDocument() {
  QJsonObject document;
  document["uri"] = lspOpenedUri;
  document["version"] = ++lspDocumentVersion;
  QJsonObject change;
  change["text"] = toPlainText();
  QJsonObject params;
  params["textDocument"] = document;
  params["contentChanges"] = QJsonArray() << change;
  sendLspMessage("textDocument/didChange", params);
}

void CodeEditor::requestLspCompletion() {
  if (!lspInitialized || lspOpenedUri.isEmpty())
    return;

  lspCompletions.clear();
  lspCompletionDocumentation.clear();
  updateCompletionModel(localCompletions());
  const QTextCursor cursor = textCursor();
  const QTextBlock block = cursor.block();
  QJsonObject position;
  position["line"] = block.blockNumber();
  position["character"] = cursor.position() - block.position();
  QJsonObject document;
  document["uri"] = lspOpenedUri;
  QJsonObject params;
  params["textDocument"] = document;
  params["position"] = position;
  lspCompletionRequestId = ++lspRequestId;
  sendLspMessage("textDocument/completion", params, lspCompletionRequestId);
}

void CodeEditor::handleLanguageServerOutput() {
  languageServerOutput += languageServer->readAllStandardOutput();
  while (true) {
    const int headerEnd = languageServerOutput.indexOf("\r\n\r\n");
    if (headerEnd < 0)
      return;

    const QByteArray header = languageServerOutput.left(headerEnd);
    QRegExp contentLength("Content-Length: (\\d+)", Qt::CaseInsensitive);
    if (contentLength.indexIn(QString::fromLatin1(header)) < 0) {
      languageServerOutput.remove(0, headerEnd + 4);
      continue;
    }

    const int length = contentLength.cap(1).toInt();
    const int messageStart = headerEnd + 4;
    if (languageServerOutput.size() < messageStart + length)
      return;

    const QByteArray payload = languageServerOutput.mid(messageStart, length);
    languageServerOutput.remove(0, messageStart + length);
    const QJsonObject response = QJsonDocument::fromJson(payload).object();
    const int responseId = response.value("id").toInt(-1);
    if (responseId == lspInitializeRequestId) {
      lspInitialized = true;
      sendLspMessage("initialized", QJsonObject());
      openLspDocument();
      if (completer->popup()->isVisible())
        requestLspCompletion();
      continue;
    }

    if (responseId != lspCompletionRequestId)
      continue;

    QJsonArray items;
    const QJsonValue result = response.value("result");
    if (result.isArray())
      items = result.toArray();
    else if (result.isObject())
      items = result.toObject().value("items").toArray();

    lspCompletions.clear();
    lspCompletionDocumentation.clear();
    for (const QJsonValue &value : items) {
      const QJsonObject item = value.toObject();
      const QString completion = item.value("insertText").toString(
          item.value("label").toString());
      if (!completion.isEmpty()) {
        lspCompletions.append(completion);
        const QJsonValue documentation = item.value("documentation");
        QString documentationText;
        if (documentation.isString())
          documentationText = documentation.toString();
        else if (documentation.isObject())
          documentationText = documentation.toObject().value("value").toString();
        if (documentationText.isEmpty())
          documentationText = item.value("detail").toString();
        lspCompletionDocumentation.insert(completion, documentationText);
      }
    }

    if (completer->popup()->isVisible())
      showCompletion();
  }
}

void CodeEditor::insertCompletion(const QString &completion) {
  QTextCursor cursor = textCursor();
  cursor.select(QTextCursor::WordUnderCursor);
  cursor.insertText(completion);
  setTextCursor(cursor);
}
