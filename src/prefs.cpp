#include <QMessageBox>

#include <QFont>
#include <QFontDialog>

#include "prefs.h"

Prefs::Prefs(QWidget* parent) :
    QDialog(parent) {

    this->setupUi(this);

    _settings = new QSettings("", "");

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

    this->defaultmap["editor/fontfamily"] = found_family;
    this->defaultmap["editor/fontsize"]   = 12;

    this->defaultmap["povray/preview"] =
            "Work in progress..";

    connect(this->fontChooser, SIGNAL(activated(const QString &)),
            this, SLOT(fontFamilyChanged(const QString &)));

    connect(this->fontSize, SIGNAL(editTextChanged(const QString &)),
            this, SLOT(fontSizeChanged(const QString &)));
}

void Prefs::fontFamilyChanged(const QString &family) {
    _settings->setValue("editor/fontfamily", family);
    emit fontChanged(family, getValue("editor/fontsize").toUInt());
}

void Prefs::fontSizeChanged(const QString &size) {
    uint intsize = size.toUInt();

    _settings->setValue("editor/fontsize", intsize);

    emit fontChanged(getValue("editor/fontfamily").toString(), intsize);
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

QVariant Prefs::getValue(const QString &key) const {
    return _settings->value(key, this->defaultmap[key]);
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

    QString povCmd = getValue("povray/preview").toString();
    povPreview->setPlainText(povCmd);
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
    emit povPreviewChanged(getValue("povray/preview").toString());

    // TODO save settings
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
