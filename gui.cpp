#include "gui.h"

Gui::Gui(QWidget *parent, bool savePNG, bool savePOV) : QWidget(parent) {
  ui.setupUi(this);

  qDebug() << "gui cons";

  m_viewer = new Viewer(this, savePNG, savePOV);

  qDebug() << "viewer post cons";

  QVBoxLayout *layout = new QVBoxLayout;
  layout->addWidget(m_viewer);
  ui.widget->setLayout(layout);

  m_cmdline = new CommandLine("", this);

  QVBoxLayout *layout1 = new QVBoxLayout;
  layout1->addWidget(m_cmdline);
  ui.lineEdit->setLayout(layout1);
  m_cmdline->setFocus();

  connect(m_cmdline, SIGNAL(execute(QString)), this, SLOT(command(QString)));
}

#define pi (3.1415926535f)

static double r2d(double radians)
{
  return radians * 180 / pi;
}

void Gui::command(QString cmd) {
  log("> " + cmd);
  cmd = cmd.toLower();

  if (cmd.startsWith("home")) {
    log("moving into home position.");
    m_viewer->rm->cmdHome();
  } else if (cmd.startsWith("m")) {
    QStringList s = cmd.split(" ");
    double x = s.at(1).toDouble();
    double y = s.at(2).toDouble();
    double z = s.at(3).toDouble();
    
    log(QString("moving to <%1, %2, %3>.").arg(x).arg(y).arg(z));

    m_viewer->rm->cmdMoveTo(x, y, z);
  } else if (cmd.startsWith("?") || cmd.startsWith("help")) {
    log("available commands:");
    log(" - home ");
    log(" - move [x][y][z] move end effector to <x,y,z>");
  }
}

void Gui::log(QString text) {
  ui.textEdit->append(text);
}

void Gui::updateValues() {
}
