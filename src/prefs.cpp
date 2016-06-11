#include <QMessageBox>

#include <QFont>
#include <QFontDialog>
#include <QFileDialog>

#include "prefs.h"

Prefs::Prefs(QSettings *settings, QWidget* parent) :
    QDialog(parent) {

    _settings = settings;

    this->setupUi(this);

    connect(listBox, SIGNAL(currentItemChanged(QListWidgetItem *,QListWidgetItem *)),
            this, SLOT(changeGroup(QListWidgetItem *, QListWidgetItem*)));

    setupPages();

    updateGUI();
}

Prefs::~Prefs() {
    removeDefaultSettings();

    delete _settings;
}

void Prefs::setupPages() {
    QFontDatabase db;

    foreach (int size, db.standardSizes()) {
        this->fontSize->addItem(QString::number(size));
        if (size == 12) {
            this->fontSize->setCurrentIndex(this->fontSize->count()-1);
        }
    }

    QString fontfamily;
#ifdef Q_WS_X11
    fontfamily = "Mono";
#elif defined (Q_WS_WIN)
    fontfamily = "Console";
#elif defined (Q_WS_MAC)
    fontfamily = "Monaco";
#endif

    QFont font;
    font.setStyleHint(QFont::TypeWriter);
    font.setFamily(fontfamily);
    QString found_family(QFontInfo(font).family());

    this->defaultmap["editor/fontfamily"] = _settings->value("editor/fontfamily", "Courier").toString();
    this->defaultmap["editor/fontsize"]   = _settings->value("editor/fontsize", 12).toInt();
    this->defaultmap["lua/path"]          = _settings->value("lua/path", "/usr/share/bpp/demo/?.lua;demo/?.lua").toString();
    this->defaultmap["povray/export"]     = _settings->value("povray/export", "export").toString();
    this->defaultmap["povray/preview"]    = _settings->value("povray/preview", "+L/usr/share/bpp/includes +L../../includes -c +d -A +p +Q11 +GA").toString();

    this->defaultmap["openscad/executable"] = _settings->value("openscad/executable", "/usr/bin/openscad").toString();

    connect(this->fontChooser, SIGNAL(activated(const QString &)),
            this, SLOT(fontFamilyChanged(const QString &)));

    connect(this->fontSize, SIGNAL(editTextChanged(const QString &)),
            this, SLOT(fontSizeChanged(const QString &)));

    connect(this->luaPath, SIGNAL(textChanged()),
            this, SLOT(on_luaPathChanged()));

    connect(this->povExportDir, SIGNAL(textChanged(QString)),
            this, SLOT(on_povExportDirChanged()));

    connect(this->povExportDirBrowse, SIGNAL(clicked(bool)),
            this, SLOT(on_povExportDirBrowse()));

    connect(this->povPreview, SIGNAL(textChanged(QString)),
            this, SLOT(on_povPreviewChanged()));

    connect(this->scadExecutable, SIGNAL(textChanged(QString)),
            this, SLOT(on_scadExecutableChanged()));

    connect(this->scadExecutableBrowse, SIGNAL(clicked(bool)),
            this, SLOT(on_scadExecutableBrowse()));
}

void Prefs::fontFamilyChanged(const QString family) {
    setValue("editor/fontfamily", family);
    emit fontChanged(family, getValue("editor/fontsize").toUInt());
}

void Prefs::fontSizeChanged(const QString size) {
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

void Prefs::on_povExportDirChanged() {
    setValue("povray/export", povExportDir->text());
    emit povExportDirChanged(povExportDir->text());
}

void Prefs::on_povExportDirBrowse() {
    QString dir = QFileDialog::getExistingDirectory(this, tr("Select POV-Ray scene export directory"),
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

void Prefs::keyPressEvent(QKeyEvent *e) {
#ifdef Q_WS_MAC
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
         iter != this->defaultmap.end();
         iter++) {
        if (_settings->value(iter.key()) == iter.value()) {
            _settings->remove(iter.key());
        }
    }
}

QVariant Prefs::getValue(QString key) const {
    return _settings->value(key, this->defaultmap[key]);
}

void Prefs::setValue(QString key, QVariant value) {
    _settings->setValue(key, value);
}

void Prefs::updateGUI() {
    QString fontfamily = getValue("editor/fontfamily").toString();
    int fidx = this->fontChooser->findText(fontfamily,Qt::MatchContains);
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
    povPreview->setText(getValue("povray/preview").toString());

    scadExecutable->setText(getValue("openscad/executable").toString());
}

void Prefs::changeGroup(QListWidgetItem *current, QListWidgetItem *previous) {
    if (!current)
        current = previous;
    tabWidgetStack->setCurrentIndex(listBox->row(current));
}

void Prefs::activateGroupPage(QString group, int index) {
    int ct = listBox->count();

    for (int i = 0; i < ct; i++) {
        QListWidgetItem* item = listBox->item(i);
        if (item->data(Qt::UserRole).toString() == group) {
            listBox->setCurrentItem(item);
            QTabWidget* tabWidget = (QTabWidget*)tabWidgetStack->widget(i);
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
    emit fontChanged(getValue("editor/fontfamily").toString(), getValue("editor/fontsize").toUInt());
    emit luaPathChanged(getValue("lua/path").toString());
    emit povPreviewChanged(getValue("povray/preview").toString());
    emit povExportDirChanged(getValue("povray/export").toString());
    emit scadExecutableChanged(getValue("openscad/executable").toString());
}

void Prefs::changeEvent(QEvent *e) {
    if (e->type() == QEvent::LanguageChange) {
        retranslateUi(this);
        // update the widgets' tabs
        for (int i=0; i<tabWidgetStack->count(); i++) {
            QTabWidget* tabWidget = (QTabWidget*)tabWidgetStack->widget(i);
            for (int j=0; j<tabWidget->count(); j++) {
                QWidget* page = tabWidget->widget(j);
                tabWidget->setTabText(j, page->windowTitle());
            }
        }
        // update the items' text
        for (int i=0; i<listBox->count(); i++) {
            QListWidgetItem *item = listBox->item(i);
            QByteArray group = item->data(Qt::UserRole).toByteArray();
            item->setText(QObject::tr(group.constData()));
        }
    } else {
        QWidget::changeEvent(e);
    }
}
