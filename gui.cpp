#include "gui.h"

#define APP_VERSION QString("v1.0.1")
#define APP_NAME QString("physics")
#define APP_NAME_FULL tr("Bullet Physics Playground")

Gui::Gui(bool savePNG, bool savePOV, QWidget *parent) : QMainWindow(parent) {
  ui.setupUi(this);

  // setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(tr("%1 %2").arg(APP_NAME_FULL).arg(APP_VERSION));
  //  setWindowIcon(QIcon(":images/icon.png"));

  settings = new QSettings();

  // ui.viewer = new Viewer(this, savePNG, savePOV);

  //  ui.cmdline = new CommandLine(this);
  ui.cmdline->setFocus();

  connect(ui.cmdline, SIGNAL(execute(QString)), this, SLOT(command(QString)));

  loadSettings();
}

#define pi (3.1415926535f)

static double r2d(double radians) { return radians * 180 / pi; }

void Gui::loadSettings() {
  settings->beginGroup("gui");

  restoreGeometry(settings->value("geometry", saveGeometry() ).toByteArray());
  restoreState(settings->value("state", saveState() ).toByteArray());
  move(settings->value("pos", pos()).toPoint());
  resize(settings->value("size", size()).toSize());

  if ( settings->value("maximized", isMaximized() ).toBool()) {
    showMaximized();
  }

  settings->endGroup();
}

void Gui::saveSettings() {
  settings->beginGroup("gui");

  settings->setValue("geometry", saveGeometry());
  settings->setValue("state", saveState());
  settings->setValue("maximized", isMaximized());

  if ( !isMaximized() ) {
    settings->setValue("pos", pos());
    settings->setValue("size", size());
  }

  settings->endGroup();
}

void Gui::closeEvent(QCloseEvent *) {
  // qDebug() << "Gui::closeEvent";
  saveSettings();
}

void Gui::command(QString cmd) {
  log("> " + cmd);
  cmd = cmd.toLower();

  if (cmd.startsWith("home")) {
    log("moving into home position.");
    ui.viewer->rm->cmdHome();
  } else if (cmd.startsWith("m")) {
    QStringList s = cmd.split(" ");
    double x = s.at(1).toDouble();
    double y = s.at(2).toDouble();
    double z = s.at(3).toDouble();
    
    log(QString("moving to <%1, %2, %3>.").arg(x).arg(y).arg(z));

    ui.viewer->rm->cmdMoveTo(x, y, z);
  } else if (cmd.startsWith("?") || cmd.startsWith("help")) {
    log("available commands:");
    log(" - home ");
    log(" - move [x][y][z] move end effector to <x,y,z>");
  }
}

void Gui::log(QString text) {
  ui.cmdlog->appendPlainText(text);
}

void Gui::updateValues() {
}
