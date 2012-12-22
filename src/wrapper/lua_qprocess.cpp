#include "lua_qprocess.h"

#include <luabind/tag_function.hpp>

#include "lua_qslot.h"

LQProcessEnvironment lqprocessenvironment()
{
    return
    class_<QProcessEnvironment>("QProcessEnvironment")
    .def(constructor<>())
    .def(constructor<const QProcessEnvironment&>())
    .def("clear", &QProcessEnvironment::clear)
    .def("contains", &QProcessEnvironment::contains)
    .def("insert", (void (QProcessEnvironment::*)(const QString &, const QString &))&QProcessEnvironment::insert)
    .def("insert", (void (QProcessEnvironment::*)(const QProcessEnvironment &))&QProcessEnvironment::insert)
    .def("isEmpty", &QProcessEnvironment::isEmpty)
    .property("empty", &QProcessEnvironment::isEmpty)
    .def("remove", &QProcessEnvironment::remove)
    .def("toStringList", &QProcessEnvironment::toStringList)
    .def("value", &QProcessEnvironment::value)
    .scope[
        def("systemEnvironment", &QProcessEnvironment::systemEnvironment)
    ]
    ;
}

static setter_map<QProcess> lqprocess_set_map;

QProcess* lqprocess_init(QProcess* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqprocess_set_map);
}
template<>
void table_init_general<QProcess>(const luabind::argument & arg, const object& obj)
{
    lqprocess_init(construct<QProcess>(arg), obj);
}


namespace luabind{
    QT_EMUN_CONVERTER(QProcess::ProcessChannel)
    QT_EMUN_CONVERTER(QProcess::ProcessError)
    QT_EMUN_CONVERTER(QProcess::ProcessState)
    QT_EMUN_CONVERTER(QProcess::ProcessChannelMode)
    QT_EMUN_CONVERTER(QProcess::ExitStatus)
    QT_EMUN_CONVERTER(QIODevice::OpenMode)
    QT_EMUN_CONVERTER(QIODevice::OpenModeFlag)
    QT_EMUN_CONVERTER(QClipboard::Mode)
}

ENUM_FILTER(QProcess,processChannelMode,setProcessChannelMode)
ENUM_FILTER(QProcess,readChannel,setReadChannel)
ENUM_FILTER(QProcess,readChannelMode,setReadChannelMode)

SIGNAL_PROPERYT(lqprocess, error, QProcess, "(QProcess::ProcessError)")
SIGNAL_PROPERYT(lqprocess, finished, QProcess, "(int,QProcess::ExitStatus)")
SIGNAL_PROPERYT(lqprocess, readyReadStandardError, QProcess, "()")
SIGNAL_PROPERYT(lqprocess, readyReadStandardOutput, QProcess, "()")
SIGNAL_PROPERYT(lqprocess, started, QProcess, "()")
SIGNAL_PROPERYT(lqprocess, stateChanged, QProcess, "(QProcess::ProcessState)")
int lqprocess_getchar(QProcess* w)
{
    char ch;
    if(w->getChar(&ch)){
        return (unsigned char)ch;
    }
    return -1;
}

qint64 lqprocess_pid(QProcess* w)
{
    return (qint64)w->pid();
}

LQProcess lqprocess()
{
    return
    myclass_<QProcess,QObject>("QProcess",lqprocess_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("__init", table_init_general<QProcess>)
    .def("__call", lqprocess_init)
    .def("closeReadChannel", &QProcess::closeReadChannel)
    .def("closeWriteChannel", &QProcess::closeWriteChannel)
    .def("readAllStandardError", &QProcess::readAllStandardError)
    .def("readAllStandardOutput", &QProcess::readAllStandardOutput)
    .def("read", (QByteArray(QProcess::*)(qint64))&QProcess::read)
    .def("readAll", &QProcess::readAll)
    .def("readLine", (QByteArray(QProcess::*)(qint64))&QProcess::readLine)
    .def("readLine", tag_function<QByteArray(QProcess*)>(boost::bind((QByteArray(QProcess::*)(qint64))&QProcess::readLine,_1,0)))
    .def("getChar", lqprocess_getchar)
    .def("setStandardErrorFile", &QProcess::setStandardErrorFile)
    .def("setStandardErrorFile", tag_function<void(QProcess*,const QString&)>(boost::bind(&QProcess::setStandardErrorFile,_1,_2,QIODevice::Truncate)))
    .def("setStandardOutputFile", &QProcess::setStandardOutputFile)
    .def("setStandardOutputFile", tag_function<void(QProcess*,const QString&)>(boost::bind(&QProcess::setStandardOutputFile,_1,_2,QIODevice::Truncate)))
    .def("setStandardInputFile", &QProcess::setStandardInputFile)
    .def("setStandardOutputProcess", &QProcess::setStandardOutputProcess)
    .def("start", (void (QProcess::*)(const QString&, const QStringList&,QIODevice::OpenMode))&QProcess::start)
    .def("start", tag_function<void(QProcess*,const QString&,const QStringList&)>(boost::bind((void (QProcess::*)(const QString&, const QStringList&,QIODevice::OpenMode))&QProcess::start,_1,_2,_3,QIODevice::ReadWrite)))
    .def("start", (void (QProcess::*)(const QString&, QIODevice::OpenMode))&QProcess::start)
    .def("start", tag_function<void(QProcess*,const QString&)>(boost::bind((void (QProcess::*)(const QString&,QIODevice::OpenMode))&QProcess::start,_1,_2,QIODevice::ReadWrite)))
    .def("waitForFinished", &QProcess::waitForFinished)
    .def("waitForFinished", tag_function<bool(QProcess*)>(boost::bind(&QProcess::waitForFinished,_1,30000)))
    .def("waitForStarted", &QProcess::waitForStarted)
    .def("waitForStarted", tag_function<bool(QProcess*)>(boost::bind(&QProcess::waitForStarted,_1,30000)))
    .def("waitForBytesWritten", &QProcess::waitForBytesWritten)
    .def("waitForBytesWritten", tag_function<bool(QProcess*)>(boost::bind(&QProcess::waitForBytesWritten,_1,30000)))
    .def("waitForReadyRead", &QProcess::waitForReadyRead)
    .def("waitForReadyRead", tag_function<bool(QProcess*)>(boost::bind(&QProcess::waitForReadyRead,_1,30000)))
    .def("isSequential", &QProcess::isSequential)
    .def("close", &QProcess::close)
    .def("bytesAvailable", &QProcess::bytesAvailable)
    .def("bytesToWrite", &QProcess::bytesToWrite)

    .def("kill", &QProcess::kill)
    .def("terminate", &QProcess::terminate)

    .sig_prop(lqprocess, error)
    .sig_prop(lqprocess, finished)
    .sig_prop(lqprocess, readyReadStandardError)
    .sig_prop(lqprocess, readyReadStandardOutput)
    .sig_prop(lqprocess, started)
    .sig_prop(lqprocess, stateChanged)

    .property("processChannelMode", QProcess_processChannelMode, QProcess_setProcessChannelMode)
    .property("readChannel", QProcess_readChannel, QProcess_setReadChannel)
    .property("readChannelMode", QProcess_readChannelMode, QProcess_setReadChannelMode)
    .property("workingDirectory", &QProcess::workingDirectory, &QProcess::setWorkingDirectory)
    .class_<QProcess,QObject>::property("environment", &QProcess::environment, &QProcess::setEnvironment)
    .property("environment", &QProcess::processEnvironment, &QProcess::setProcessEnvironment)
    .property("error", (QProcess::ProcessError(QProcess::*)()const)&QProcess::error)
    .property("exitCode", &QProcess::exitCode)
    .property("exitStatus", &QProcess::exitStatus)
    .property("pid", lqprocess_pid)
    .property("state", &QProcess::state)
    .property("atEnd", &QProcess::atEnd)
    .property("sequential", &QProcess::isSequential)
    .property("canReadLine", &QProcess::canReadLine)
    ;
}

static setter_map<QApplication> lqapplication_set_map;

QApplication* lqapplication_init(QApplication* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqapplication_set_map);
}

//void lqapplication_table_init(const luabind::argument & arg, const object& obj)
//{
//    lqapplication_init(construct<QApplication>(arg), obj);
//}

//ENUM_FILTER(QApplication,layoutDirection,setLayoutDirection)
int QApplication_layoutDirection(QApplication* w)
{
    return w->layoutDirection();
}

void QApplication_setLayoutDirection(QApplication* w, int f)
{
    w->setLayoutDirection(Qt::LayoutDirection(f));
}

SIGNAL_PROPERYT(lqapplication, focusChanged, QApplication, "(QWidget*,QWidget*)")
SIGNAL_PROPERYT(lqapplication, fontDatabaseChanged, QApplication, "()")
SIGNAL_PROPERYT(lqapplication, lastWindowClosed, QApplication, "()")
SIGNAL_PROPERYT(lqapplication, aboutToQuit, QApplication, "()")
QApplication* lqapplication_instance()
{
    return qApp;
}
LQApplication lqapplication()
{
    return
    myclass_<QApplication,QObject>("QApplication",lqapplication_set_map)
    .def("__call", lqapplication_init)
    .def("aboutQt", &QApplication::aboutQt)
    .def("quit", &QApplication::quit)
    .def("closeAllWindows", &QApplication::closeAllWindows)
    .def("setAutoSipEnabled", &QApplication::setAutoSipEnabled)
    .def("setStyleSheet", &QApplication::setStyleSheet)

    .property("autoSipEnabled", &QApplication::autoSipEnabled, &QApplication::setAutoSipEnabled)
    .property("cursorFlashTime", &QApplication::cursorFlashTime, &QApplication::setCursorFlashTime)
    .property("doubleClickInterval", &QApplication::doubleClickInterval, &QApplication::setDoubleClickInterval)
    .property("globalStrut", &QApplication::globalStrut, &QApplication::setGlobalStrut)
    .property("keyboardInputInterval", &QApplication::keyboardInputInterval, &QApplication::setKeyboardInputInterval)
    .property("layoutDirection", QApplication_layoutDirection, QApplication_setLayoutDirection)
    .property("quitOnLastWindowClosed", &QApplication::quitOnLastWindowClosed, &QApplication::setQuitOnLastWindowClosed)
    .property("startDragTime", &QApplication::startDragTime, &QApplication::setStartDragTime)
    .property("startDragTime", &QApplication::startDragDistance, &QApplication::setStartDragDistance)
    .property("styleSheet", &QApplication::styleSheet, &QApplication::setStyleSheet)
    .property("wheelScrollLines", &QApplication::wheelScrollLines, &QApplication::setWheelScrollLines)
    .property("windowIcon", &QApplication::windowIcon, &QApplication::setWindowIcon)
    .property("sessionId", &QApplication::sessionId)
    .property("sessionKey", &QApplication::sessionKey)

    .sig_prop(lqapplication, focusChanged)
    .sig_prop(lqapplication, fontDatabaseChanged)
    .sig_prop(lqapplication, lastWindowClosed)
    .sig_prop(lqapplication, aboutToQuit)

    .scope[
            def("arguments", &QApplication::arguments),
            def("libraryPaths", &QApplication::libraryPaths),
            def("setLibraryPaths", &QApplication::setLibraryPaths),
            def("instance", lqapplication_instance),
            def("desktop", &QApplication::desktop),
            def("clipboard", &QApplication::clipboard)
    ]


    ;
}

const QRect lqdesktopwidget_availableGeometry(QDesktopWidget* w){ return w->availableGeometry();}
QWidget* lqdesktopwidget_screen(QDesktopWidget* w) { return w->screen(); }
const QRect lqdesktopwidget_screenGeometry(QDesktopWidget* w) { return w->screenGeometry(); }
int lqdesktopwidget_screenNumber(QDesktopWidget* w) { return w->screenNumber(); }

SIGNAL_PROPERYT(lqdesktopwidget, resized, QDesktopWidget, "(int)")
SIGNAL_PROPERYT(lqdesktopwidget, screenCountChanged, QDesktopWidget, "(int)")
SIGNAL_PROPERYT(lqdesktopwidget, workAreaResized, QDesktopWidget, "(int)")

LQDesktopWidget lqdesktopwidget()
{
    return
    class_<QDesktopWidget, QWidget>("QDesktopWidget")
    .def("availableGeometry", lqdesktopwidget_availableGeometry)
    .def("availableGeometry", (const QRect(QDesktopWidget::*)(int) const)&QDesktopWidget::availableGeometry)
    .def("availableGeometry", (const QRect(QDesktopWidget::*)(const QWidget*) const)&QDesktopWidget::availableGeometry)
    .def("availableGeometry", (const QRect(QDesktopWidget::*)(const QPoint&) const)&QDesktopWidget::availableGeometry)
    .def("screen", lqdesktopwidget_screen)
    .def("screen", &QDesktopWidget::screen)
    .def("screenGeometry", lqdesktopwidget_screenGeometry)
    .def("screenGeometry", (const QRect(QDesktopWidget::*)(int) const)&QDesktopWidget::screenGeometry)
    .def("screenGeometry", (const QRect(QDesktopWidget::*)(const QWidget*) const)&QDesktopWidget::screenGeometry)
    .def("screenGeometry", (const QRect(QDesktopWidget::*)(const QPoint&) const)&QDesktopWidget::screenGeometry)
    .def("screenNumber", lqdesktopwidget_screenNumber)
    .def("screenNumber", (int(QDesktopWidget::*)(const QWidget*) const)&QDesktopWidget::screenNumber)
    .def("screenNumber", (int(QDesktopWidget::*)(const QPoint&) const)&QDesktopWidget::screenNumber)


    .property("isVirtualDesktop", &QDesktopWidget::isVirtualDesktop)
    .property("primaryScreen", &QDesktopWidget::primaryScreen)
    .property("screenCount", &QDesktopWidget::screenCount)
    .sig_prop(lqdesktopwidget, resized)
    .sig_prop(lqdesktopwidget, screenCountChanged)
    .sig_prop(lqdesktopwidget, workAreaResized)
    ;
}

SIGNAL_PROPERYT(lqclipboard, changed, QClipboard, "(QClipboard::Mode)")
SIGNAL_PROPERYT(lqclipboard, dataChanged, QClipboard, "()")
SIGNAL_PROPERYT(lqclipboard, findBufferChanged, QClipboard, "()")
SIGNAL_PROPERYT(lqclipboard, selectionChanged, QClipboard, "()")
LQClipboard lqclipboard()
{
    return
    class_<QClipboard, QObject>("QClipboard")
    .def("clear", &QClipboard::clear)
    .def("clear", tag_function<void(QClipboard*)>(boost::bind(&QClipboard::clear,_1,QClipboard::Clipboard)))
    .def("image", &QClipboard::image)
    .def("image", tag_function<QImage(QClipboard*)>(boost::bind(&QClipboard::image,_1,QClipboard::Clipboard)))
    .def("mimeData", &QClipboard::mimeData)
    .def("mimeData", tag_function<const QMimeData *(QClipboard*)>(boost::bind(&QClipboard::mimeData,_1,QClipboard::Clipboard)))
    .def("pixmap", &QClipboard::pixmap)
    .def("pixmap", tag_function<QPixmap(QClipboard*)>(boost::bind(&QClipboard::pixmap,_1,QClipboard::Clipboard)))
    .def("setImage", &QClipboard::setImage)
    .def("setImage", tag_function<void(QClipboard*, const QImage &)>(boost::bind(&QClipboard::setImage,_1,_2,QClipboard::Clipboard)))
    .def("setMimeData", &QClipboard::setMimeData)
    .def("setMimeData", tag_function<void(QClipboard*, QMimeData*)>(boost::bind(&QClipboard::setMimeData,_1,_2,QClipboard::Clipboard)))
    .def("setPixmap", &QClipboard::setPixmap)
    .def("setPixmap", tag_function<void(QClipboard*, const QPixmap &)>(boost::bind(&QClipboard::setPixmap,_1,_2,QClipboard::Clipboard)))
    .def("setText", &QClipboard::setText)
    .def("setText", tag_function<void(QClipboard*, const QString&)>(boost::bind(&QClipboard::setText,_1,_2,QClipboard::Clipboard)))
    .def("text", (QString(QClipboard::*)(QClipboard::Mode)const)&QClipboard::text)
    .def("text", tag_function<QString(QClipboard*)>(boost::bind((QString(QClipboard::*)(QClipboard::Mode)const)&QClipboard::text,_1,QClipboard::Clipboard)))
    .def("text", (QString(QClipboard::*)(QString &,QClipboard::Mode)const)&QClipboard::text)
    .def("text", tag_function<QString(QClipboard*,QString &)>(boost::bind((QString(QClipboard::*)(QString &,QClipboard::Mode)const)&QClipboard::text,_1,_2,QClipboard::Clipboard)))

    .property("ownsClipboard", &QClipboard::ownsClipboard)
    .property("ownsFindBuffer", &QClipboard::ownsFindBuffer)
    .property("ownsSelection", &QClipboard::ownsSelection)
    .property("supportsFindBuffer", &QClipboard::supportsFindBuffer)
    .property("supportsSelection", &QClipboard::supportsSelection)
    .sig_prop(lqclipboard, changed)
    .sig_prop(lqclipboard, dataChanged)
    .sig_prop(lqclipboard, findBufferChanged)
    .sig_prop(lqclipboard, selectionChanged)
    ;
}

LQSound lqsound()
{
    return
    class_<QSound, QObject>("QSound")
    .def(constructor<const QString&>())
    .def(constructor<const QString&,QObject*>())
    .def("setLoops", &QSound::setLoops)
    .def("setLoops", (void (QSound::*)())&QSound::play)
    .def("setLoops", &QSound::stop)
    .property("fileName", &QSound::fileName)
    .property("isFinished", &QSound::isFinished)
    .property("loops", &QSound::loops)
    .property("loopsRemaining", &QSound::loopsRemaining)
    .scope[
        def("isAvailable", &QSound::isAvailable),
        def("play", (void(*)(const QString&))&QSound::play)
     ]
    ;
}

SIGNAL_PROPERYT(lqfilesystemwatcher, directoryChanged, QFileSystemWatcher, "(const QString&)")
SIGNAL_PROPERYT(lqfilesystemwatcher, fileChanged, QFileSystemWatcher, "(const QString&)")
LQFileSystemWatcher lqfilesystemwatcher()
{
    return
    class_<QFileSystemWatcher, QObject>("QFileSystemWatcher")
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("addPath", &QFileSystemWatcher::addPath)
    .def("addPaths", &QFileSystemWatcher::addPaths)
    .def("removePath", &QFileSystemWatcher::removePath)
    .def("removePaths", &QFileSystemWatcher::removePaths)
    .property("directories", &QFileSystemWatcher::directories)
    .property("files", &QFileSystemWatcher::files)
    .sig_prop(lqfilesystemwatcher, directoryChanged)
    .sig_prop(lqfilesystemwatcher, fileChanged)
    ;
}
