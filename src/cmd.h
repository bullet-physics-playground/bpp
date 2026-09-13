#ifndef CMD_LINE_H
#define CMD_LINE_H

/**
 * @file cmd.h
 * @brief Single-line Lua command entry widget with a recall history.
 */

#include <QLineEdit>
#include <QList>
#include <QString>

/**
 * @brief A QLineEdit that remembers what was typed into it and forwards
 *        unhandled key presses to the rest of the application.
 *
 * CommandLine is the one-line Lua prompt at the bottom of the main window.
 * Pressing Return emits execute() with the entered text and clears the field;
 * Up and Down walk back and forth through everything entered so far. Key
 * presses that the line edit itself does not consume are re-emitted through
 * keyPressed() so the viewer can treat them as application shortcuts.
 */
class CommandLine : public QLineEdit {
  Q_OBJECT

public:
  /**
   * @brief Constructs the command line and its (initially empty) history.
   * @param parent Parent widget, passed through to QLineEdit.
   */
  CommandLine(QWidget *parent = nullptr);

  /**
   * @brief Destroys the widget and frees the history list.
   */
  ~CommandLine(); // Add destructor declaration

  /**
   * @brief Gives access to the list of previously executed commands.
   *
   * Entries are in the order they were executed, oldest first. The list is
   * owned by the CommandLine and must not be deleted by the caller.
   *
   * @return Pointer to the live history list.
   */
  QList<QString> *getHistory();

public slots:
  /**
   * @brief Accepts the text currently in the field as a command.
   *
   * Appends it to the history, resets the recall position, clears the field
   * and emits execute(). Connected to QLineEdit::returnPressed().
   */
  void executed();

signals:
  /**
   * @brief Emitted for a key press the line edit did not consume.
   *
   * Lets the surrounding application interpret the event as a user-defined
   * shortcut. Modifier-only presses and Return are swallowed instead.
   *
   * @param e The originating key event; owned by Qt and only valid for the
   *          duration of the emission.
   */
  void keyPressed(QKeyEvent *e);

  /**
   * @brief Emitted when the user has entered a command with Return.
   * @param cmd The command text, taken from the field before it was cleared.
   */
  void execute(QString cmd);

private:
  /**
   * @brief Handles Up/Down history recall and re-emits unhandled keys.
   *
   * Up and Down move @c historyPos through @c history and replace the field
   * contents; stepping past the newest entry clears the field. Anything else
   * is passed to QLineEdit::keyPressEvent() first, and if it was neither
   * accepted nor a Return, it is forwarded via keyPressed().
   *
   * @param e The key event to handle.
   */
  void keyPressEvent(QKeyEvent *e);

private:
  QList<QString> *history; ///< Commands executed so far, oldest first.
  int historyPos; ///< Index into #history being recalled, or -1 when the
                  ///< user is editing a fresh line.
};

#endif
