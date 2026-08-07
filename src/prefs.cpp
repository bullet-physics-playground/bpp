#include <QMessageBox>

#include <QCoreApplication>
#include <QFileInfo>
#include <QDebug>
#include <QFileDialog>
#include <QFont>
#include <QFontDialog>
#include <QStandardPaths>
#include <QPlainTextEdit>

#include "prefs.h"

QString getDefaultLuaPath(const QString &scriptBasePath) {
  QStringList luaPaths;

  // Walk up from the script's directory to find a 'module/' directory.
  // This handles scripts in any subdirectory (e.g. demo/koppi/) so users
  // can write  require "color"  instead of  require "module/color".
  if (!scriptBasePath.isEmpty()) {
    QDir dir(scriptBasePath);
    do {
      if (QDir(dir.absolutePath() + "/module").exists()) {
        luaPaths << dir.absolutePath() + "/module/?.lua;";
        break;
      }
    } while (dir.cdUp());
  }

  QString appDir = QFileInfo(QCoreApplication::applicationFilePath()).absolutePath();
  QString appDemo = appDir + "/demo/module/?.lua;";
  if (QDir(appDir + "/demo/module").exists())
    luaPaths << appDemo;

  QString siblingDemoDir = appDir + "/../demo/module";
  if (QDir(siblingDemoDir).exists())
    luaPaths << QFileInfo(siblingDemoDir).absolutePath() + "/module/?.lua;";

  QString installDemo = "/usr/share/bpp/demo/module/?.lua;";
  if (QDir("/usr/share/bpp/demo/module").exists())
    luaPaths << installDemo;

  return luaPaths.join("");
}

Prefs::Prefs(QSettings *settings, QWidget *parent) : QDialog(parent) {

  _settings = settings;

  this->setupUi(this);

  connect(listBox,
          &QListWidget::currentItemChanged,
          this, &Prefs::changeGroup);

  setupPages();

  updateGUI();
}

Prefs::~Prefs() {
  removeDefaultSettings();
}

void Prefs::setupPages() {
  bool openLastFile = _settings->value("gui/openlastfile", false).toBool();
  if (!openLastFile) {
    openLastFile = _settings->value("openlastfile", false).toBool();
    if (openLastFile) {
      _settings->setValue("gui/openlastfile", true);
    }
  }
  this->defaultmap["gui/openlastfile"] = openLastFile;
  this->defaultmap["gui/openlastwindowstate"] =
      _settings->value("gui/openlastwindowstate", true).toBool();

  QFontDatabase db;

  foreach (int size, db.standardSizes()) {
    this->fontSize->addItem(QString::number(size));
    if (size == 12) {
      this->fontSize->setCurrentIndex(this->fontSize->count() - 1);
    }
  }

  QString fontfamily;

#ifdef Q_OS_LINUX
  fontfamily = "Mono";
#elif defined(Q_OS_WIN)
  fontfamily = "Console";
#elif defined(Q_OS_MAC)
  fontfamily = "Monaco";
#endif

  QFont font;
  font.setStyleHint(QFont::TypeWriter);
  font.setFamily(fontfamily);

  this->defaultmap["editor/fontfamily"] =
      _settings->value("editor/fontfamily", fontfamily).toString();
  this->defaultmap["editor/fontsize"] =
      _settings->value("editor/fontsize", 12).toInt();

  // LUA paths always use forward slashes; search CWD/demo first, then installed
  QString defaultLuaPath = getDefaultLuaPath();

  this->defaultmap["lua/path"] =
      _settings->value("lua/path", defaultLuaPath)
          .toString();

  QDir currDir(QDir::currentPath());
  QString currExport = currDir.filePath("export");
  QDir parentDir = currDir;
  parentDir.cdUp();
  QString parentExport = parentDir.filePath("export");
  QString defaultExportPath;
  if (QDir(currExport).exists()) {
    defaultExportPath = currExport;
  } else if (QDir(parentExport).exists()) {
    defaultExportPath = parentExport;
  } else {
    defaultExportPath = currExport;
  }

  this->defaultmap["povray/export"] =
      _settings->value("povray/export", defaultExportPath).toString();

  QString cache =
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation);

  QString defaultPovrayExe;
  QString defaultIncludes;

  QString pwd = QDir::currentPath();

#if defined (Q_OS_WIN)
  defaultPovrayExe = QString("C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe");
  defaultIncludes  = QString("+L'%1' +L'%2/includes'").arg(cache, pwd);
#elif defined (Q_OS_LINUX)
  defaultPovrayExe = QString("/usr/bin/povray");
  defaultIncludes  = QString("+L'%1' +L'%2/includes'").arg(cache, pwd);
#else
  defaultPovrayExe = QString("/usr/local/bin/povray");
  defaultIncludes  = QString("+L'%1' +L'%2/includes'").arg(cache, pwd);
#endif

  QString systemPovExe = QStandardPaths::findExecutable(defaultPovrayExe);
  if (systemPovExe.isEmpty()) systemPovExe = "POV-Ray not found!";

  QString defaultPreview = QString("%1 -c +d -A +p +Q11 +GA -CC").arg(defaultIncludes);

  QString povray = _settings->value("povray/executable", systemPovExe).toString();
  QString opts =   _settings->value("povray/preview", defaultPreview).toString();

  this->defaultmap["povray/executable"] =
      _settings
          ->value("povray/executable", povray)
          .toString();

  this->defaultmap["povray/preview"] =
      _settings->value("povray/preview", opts).toString();

#if defined(Q_OS_WIN)
  this->defaultmap["openscad/executable"] =
      _settings
          ->value("openscad/executable",
                  "C:\\Program Files\\OpenSCAD\\openscad.exe")
          .toString();
#elif defined (Q_OS_LINUX)
  this->defaultmap["openscad/executable"] =
      _settings->value("openscad/executable", "/usr/bin/openscad").toString();
#else
  this->defaultmap["openscad/executable"] =
      _settings->value("openscad/executable", "/usr/local/bin/openscad").toString();
#endif

  connect(this->checkOpenLast, &QCheckBox::toggled, this,
          &Prefs::guiOpenLastFileChanged);

  connect(this->checkWindowSave, &QCheckBox::toggled, this,
          &Prefs::guiWindowStateChanged);

  connect(this->fontChooser, static_cast<void(QComboBox::*)(const QString &)>(&QComboBox::textActivated), this,
          &Prefs::fontFamilyChanged);

  connect(this->fontSize, &QComboBox::editTextChanged, this,
          &Prefs::fontSizeChanged);

  connect(this->luaPath, &QTextEdit::textChanged, this,
          &Prefs::on_luaPathChanged);

    connect(this->povExecutable, &QLineEdit::textChanged, this,
          &Prefs::on_povExecutableChanged);

  connect(this->povExecutableBrowse, &QPushButton::clicked, this,
          &Prefs::on_povExecutableBrowse);

  connect(this->povExportDir, &QLineEdit::textChanged, this,
          &Prefs::on_povExportDirChanged);

  connect(this->povExportDirBrowse, &QPushButton::clicked, this,
          &Prefs::on_povExportDirBrowse);

  connect(this->povPreview, &QLineEdit::textChanged, this,
          &Prefs::on_povPreviewChanged);

  connect(this->scadExecutable, &QLineEdit::textChanged, this,
          &Prefs::on_scadExecutableChanged);

  connect(this->scadExecutableBrowse, &QPushButton::clicked, this,
          &Prefs::on_scadExecutableBrowse);

  // SpaceNavigator 3D mouse navigation settings
  this->defaultmap["spacenavigator/navigationMode"] =
      _settings->value("spacenavigator/navigationMode", 0).toInt();
  this->defaultmap["spacenavigator/lockHorizon"] =
      _settings->value("spacenavigator/lockHorizon", true).toBool();
  this->defaultmap["spacenavigator/autoFlySpeed"] =
      _settings->value("spacenavigator/autoFlySpeed", true).toBool();
  this->defaultmap["spacenavigator/showOrbitAxis"] =
      _settings->value("spacenavigator/showOrbitAxis", false).toBool();
  this->defaultmap["spacenavigator/zoomDirection"] =
      _settings->value("spacenavigator/zoomDirection", 0).toInt();
  this->defaultmap["spacenavigator/panZoom"] =
      _settings->value("spacenavigator/panZoom", true).toBool();

  connect(this->snNavigationMode,
          static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged),
          this, &Prefs::on_snNavigationModeChanged);

  connect(this->snZoomDirection,
          static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged),
          this, &Prefs::on_snZoomDirectionChanged);

  connect(this->checkSnLockHorizon, &QCheckBox::toggled, this,
          &Prefs::on_snLockHorizonChanged);

  connect(this->checkSnAutoFlySpeed, &QCheckBox::toggled, this,
          &Prefs::on_snAutoFlySpeedChanged);

  connect(this->checkSnShowOrbitAxis, &QCheckBox::toggled, this,
          &Prefs::on_snShowOrbitAxisChanged);

  connect(this->checkSnPanZoom, &QCheckBox::toggled, this,
          &Prefs::on_snPanZoomChanged);
}

void Prefs::guiOpenLastFileChanged(const bool checked) {
  setValue("gui/openlastfile", checked);
  emit checkOpenLastFileChanged(getValue("gui/openlastfile").toBool());
}

void Prefs::guiWindowStateChanged(const bool checked) {
  setValue("gui/openlastwindowstate", checked);
  emit checkOpenLastWindowState(getValue("gui/openlastwindowstate").toBool());
}

void Prefs::fontFamilyChanged(const QString &family) {
  setValue("editor/fontfamily", family);
  emit fontChanged(family, getValue("editor/fontsize").toUInt());
}

void Prefs::fontSizeChanged(const QString &size) {
  uint intsize = size.toUInt();

  setValue("editor/fontsize", intsize);

  emit fontChanged(getValue("editor/fontfamily").toString(), intsize);
}

void Prefs::on_luaPathChanged() {
  setValue("lua/path", luaPath->toPlainText());
  emit luaPathChanged(luaPath->toPlainText());
}

void Prefs::on_povPreviewChanged() {
  setValue("povray/preview", povPreview->text());
  emit povPreviewChanged(getValue("povray/preview").toString());
}

void Prefs::on_povExecutableChanged() {
  setValue("povray/executable", povExecutable->text());
  emit povExecutableChanged(povExecutable->text());
}

void Prefs::on_povExecutableBrowse() {
  QFileDialog *dlg = new QFileDialog(this);
  dlg->setFilter(QDir::Executable);
  dlg->selectFile(getValue("povray/executable").toString());

  QString filename;
  if (dlg->exec())
    filename = dlg->selectedFiles().first();
  else
    return;

  setValue("povray/executable", filename);
  povExecutable->setText(filename);
  emit povExecutableChanged(filename);
}

void Prefs::on_povExportDirChanged() {
  setValue("povray/export", povExportDir->text());
  emit povExportDirChanged(povExportDir->text());
}

void Prefs::on_povExportDirBrowse() {
  QString dir = QFileDialog::getExistingDirectory(
      this, tr("Select POV-Ray scene export directory"),
      getValue("povray/export").toString(),
      QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);

  if (!dir.isEmpty()) {
    setValue("povray/export", dir);
    povExportDir->setText(dir);
    emit povExportDirChanged(dir);
  }
}

void Prefs::on_scadExecutableChanged() {
  setValue("openscad/executable", scadExecutable->text());
  emit scadExecutableChanged(scadExecutable->text());
}

void Prefs::on_scadExecutableBrowse() {
  QFileDialog *dlg = new QFileDialog(this);
  dlg->setFilter(QDir::Executable);
  dlg->selectFile(getValue("openscad/executable").toString());

  QString filename;
  if (dlg->exec())
    filename = dlg->selectedFiles().first();
  else
    return;

  setValue("openscad/executable", filename);
  scadExecutable->setText(filename);
  emit scadExecutableChanged(filename);
}

void Prefs::on_snNavigationModeChanged(int index) {
  setValue("spacenavigator/navigationMode", index);
  emit snNavigationModeChanged(index);
}

void Prefs::on_snLockHorizonChanged(bool checked) {
  setValue("spacenavigator/lockHorizon", checked);
  emit snLockHorizonChanged(checked);
}

void Prefs::on_snAutoFlySpeedChanged(bool checked) {
  setValue("spacenavigator/autoFlySpeed", checked);
  emit snAutoFlySpeedChanged(checked);
}

void Prefs::on_snShowOrbitAxisChanged(bool checked) {
  setValue("spacenavigator/showOrbitAxis", checked);
  emit snShowOrbitAxisChanged(checked);
}

void Prefs::on_snZoomDirectionChanged(int index) {
  setValue("spacenavigator/zoomDirection", index);
  emit snZoomDirectionChanged(index == 0);
}

void Prefs::on_snPanZoomChanged(bool checked) {
  setValue("spacenavigator/panZoom", checked);
  emit snPanZoomChanged(checked);
}

void Prefs::keyPressEvent(QKeyEvent *e) {
#ifdef Q_OS_MAC
  if (e->modifiers() == Qt::ControlModifier && e->key() == Qt::Key_Period) {
    close();
  } else
#endif
      if ((e->modifiers() == Qt::ControlModifier && e->key() == Qt::Key_W) ||
          e->key() == Qt::Key_Escape) {
    close();
  }
}

void Prefs::removeDefaultSettings() {
  for (QSettings::SettingsMap::const_iterator iter = this->defaultmap.begin();
       iter != this->defaultmap.end(); iter++) {
    if (_settings->value(iter.key()) == iter.value()) {
      _settings->remove(iter.key());
    }
  }
}

QVariant Prefs::getValue(const QString &key) const {
  return _settings->value(key, this->defaultmap[key]);
}

void Prefs::setValue(const QString &key, QVariant value) {
  _settings->setValue(key, value);
}

void Prefs::updateGUI() {

  checkOpenLast->setChecked(getValue("gui/openlastfile").toBool());
  checkWindowSave->setChecked(getValue("gui/openlastwindowstate").toBool());

  QString fontfamily = getValue("editor/fontfamily").toString();
  int fidx = this->fontChooser->findText(fontfamily, Qt::MatchContains);
  if (fidx >= 0) {
    this->fontChooser->setCurrentIndex(fidx);
  }

  QString fontsize = getValue("editor/fontsize").toString();
  int sidx = this->fontSize->findText(fontsize);
  if (sidx >= 0) {
    this->fontSize->setCurrentIndex(sidx);
  } else {
    this->fontSize->setEditText(fontsize);
  }

  luaPath->setText(getValue("lua/path").toString());

  povExportDir->setText(getValue("povray/export").toString());
  povExecutable->setText(getValue("povray/executable").toString());
  povPreview->setText(getValue("povray/preview").toString());

  scadExecutable->setText(getValue("openscad/executable").toString());

  snNavigationMode->setCurrentIndex(getValue("spacenavigator/navigationMode").toInt());
  snZoomDirection->setCurrentIndex(getValue("spacenavigator/zoomDirection").toInt());
  checkSnLockHorizon->setChecked(getValue("spacenavigator/lockHorizon").toBool());
  checkSnAutoFlySpeed->setChecked(getValue("spacenavigator/autoFlySpeed").toBool());
  checkSnShowOrbitAxis->setChecked(getValue("spacenavigator/showOrbitAxis").toBool());
  checkSnPanZoom->setChecked(getValue("spacenavigator/panZoom").toBool());
}

void Prefs::changeGroup(QListWidgetItem *current, QListWidgetItem *previous) {
  if (!current)
    current = previous;
  tabWidgetStack->setCurrentIndex(listBox->row(current));
}

void Prefs::activateGroupPage(const QString &group, int index) {
  int ct = listBox->count();

  for (int i = 0; i < ct; i++) {
    QListWidgetItem *item = listBox->item(i);
    if (item->data(Qt::UserRole).toString() == group) {
      listBox->setCurrentItem(item);
      QTabWidget *tabWidget = (QTabWidget *)tabWidgetStack->widget(i);
      tabWidget->setCurrentIndex(index);
      break;
    }
  }
}

void Prefs::accept() {
  this->invalidParameter = false;
  on_buttonOk_clicked();
  if (!this->invalidParameter)
    QDialog::accept();
}

void Prefs::on_buttonOk_clicked() {
  emit fontChanged(getValue("editor/fontfamily").toString(),
                   getValue("editor/fontsize").toUInt());
  emit luaPathChanged(getValue("lua/path").toString());
  emit povPreviewChanged(getValue("povray/preview").toString());
  emit povExecutableChanged(getValue("povray/executable").toString());
  emit povExportDirChanged(getValue("povray/export").toString());
  emit scadExecutableChanged(getValue("openscad/executable").toString());
  emit snNavigationModeChanged(getValue("spacenavigator/navigationMode").toInt());
  emit snLockHorizonChanged(getValue("spacenavigator/lockHorizon").toBool());
  emit snAutoFlySpeedChanged(getValue("spacenavigator/autoFlySpeed").toBool());
  emit snShowOrbitAxisChanged(getValue("spacenavigator/showOrbitAxis").toBool());
  emit snZoomDirectionChanged(getValue("spacenavigator/zoomDirection").toInt() == 0);
  emit snPanZoomChanged(getValue("spacenavigator/panZoom").toBool());
}

void Prefs::changeEvent(QEvent *e) {
  if (e->type() == QEvent::LanguageChange) {
    retranslateUi(this);
    // update the widgets' tabs
    for (int i = 0; i < tabWidgetStack->count(); i++) {
      QTabWidget *tabWidget = (QTabWidget *)tabWidgetStack->widget(i);
      for (int j = 0; j < tabWidget->count(); j++) {
        QWidget *page = tabWidget->widget(j);
        tabWidget->setTabText(j, page->windowTitle());
      }
    }
    // update the items' text
    for (int i = 0; i < listBox->count(); i++) {
      QListWidgetItem *item = listBox->item(i);
      QByteArray group = item->data(Qt::UserRole).toByteArray();
      item->setText(QObject::tr(group.constData()));
    }
  } else {
    QWidget::changeEvent(e);
  }
}
