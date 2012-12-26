#include "lua_serial.h"

#include <QStringList>

template<>QString settingString(BaudRateType s){return BaudRateString(s);}
template<>QString settingString(DataBitsType s){return DataBitsString(s);}
template<>QString settingString(ParityType s){return ParityString(s);}
template<>QString settingString(StopBitsType s){return StopBitsString(s);}
template<>QString settingString(FlowType s){return FlowString(s);}
template<>QString settingString(const PortSettings& s){return PortSettingString(s);}

template<typename T1, typename T2,int size>
QString getString(T1 (&map)[size], T2 value){
    QString res("unkonw");
    for(int i=0;i<size;i++){
        if(map[i].value == value) {
            res = map[i].desc;
            break;
        }
    }
    res = res.toLower();
    res.replace('_','.');
    return res;
}

#define BEGIN_TYPE_MAP(type)  \
static struct type##map_t \
{\
    type  value;\
    const char* desc;\
}type##Map[] = {

#define END_TYPE_MAP() };

#ifdef  MAP_ELEMENT
#undef  MAP_ELEMENT
#endif
#define MAP_ELEMENT(val)   {BAUD##val,  #val},

BEGIN_TYPE_MAP(BaudRateType)
    MAP_ELEMENT(50)                //POSIX ONLY
    MAP_ELEMENT(75)                //POSIX ONLY
    MAP_ELEMENT(110)
    MAP_ELEMENT(134)               //POSIX ONLY
    MAP_ELEMENT(150)               //POSIX ONLY
    MAP_ELEMENT(200)               //POSIX ONLY
    MAP_ELEMENT(300)
    MAP_ELEMENT(600)
    MAP_ELEMENT(1200)
    MAP_ELEMENT(1800)              //POSIX ONLY
    MAP_ELEMENT(2400)
    MAP_ELEMENT(4800)
    MAP_ELEMENT(9600)
    MAP_ELEMENT(14400)             //WINDOWS ONLY
    MAP_ELEMENT(19200)
    MAP_ELEMENT(38400)
    MAP_ELEMENT(56000)             //WINDOWS ONLY
    MAP_ELEMENT(57600)
    MAP_ELEMENT(76800)             //POSIX ONLY
    MAP_ELEMENT(115200)
    MAP_ELEMENT(128000)            //WINDOWS ONLY
    MAP_ELEMENT(256000)            //WINDOWS ONLY
END_TYPE_MAP()

QString  BaudRateString( BaudRateType baudRate)
{
    if(baudRate>=BAUDLAST){
        return QString("%1").arg(baudRate);
    }
    return getString(BaudRateTypeMap, baudRate);
}

#ifdef  MAP_ELEMENT
#undef  MAP_ELEMENT
#endif
#define MAP_ELEMENT(val)   {DATA_##val,  #val},

BEGIN_TYPE_MAP(DataBitsType)
        MAP_ELEMENT(5)
        MAP_ELEMENT(6)
        MAP_ELEMENT(7)
        MAP_ELEMENT(8)
END_TYPE_MAP()
#define DATA_STR(val)   case DATA_##val: return #val;

QString  DataBitsString(DataBitsType dataBits)
{
    return getString(DataBitsTypeMap, dataBits);
}


#ifdef  MAP_ELEMENT
#undef  MAP_ELEMENT
#endif
#define MAP_ELEMENT(val)   {PAR_##val,  #val},

BEGIN_TYPE_MAP(ParityType)
        MAP_ELEMENT(NONE)
        MAP_ELEMENT(ODD)
        MAP_ELEMENT(EVEN)
        MAP_ELEMENT(MARK)
        MAP_ELEMENT(SPACE)
END_TYPE_MAP()
QString  ParityString(ParityType Parity)
{
    QString s = getString(ParityTypeMap, Parity);
    s = s.toUpper();
    return s.left(1);
}

#ifdef  MAP_ELEMENT
#undef  MAP_ELEMENT
#endif
#define MAP_ELEMENT(val)   {STOP_##val,  #val},

BEGIN_TYPE_MAP(StopBitsType)
        MAP_ELEMENT(1)
        MAP_ELEMENT(1_5)
        MAP_ELEMENT(2)
END_TYPE_MAP()
QString  StopBitsString(StopBitsType StopBits)
{
    return getString(StopBitsTypeMap, StopBits);
}

#ifdef  MAP_ELEMENT
#undef  MAP_ELEMENT
#endif
#define MAP_ELEMENT(val)   {FLOW_##val,  #val},
BEGIN_TYPE_MAP(FlowType)
        MAP_ELEMENT(OFF)
        MAP_ELEMENT(HARDWARE)
        MAP_ELEMENT(XONXOFF)
END_TYPE_MAP()
QString  FlowString(FlowType flow)
{
    return getString(FlowTypeMap, flow);
}

QString  PortSettingString(const PortSettings& setting)
{
    QString res;
    res += settingString(setting.BaudRate) + ",";
    res += settingString(setting.DataBits) + ",";
    res += settingString(setting.Parity) + ",";
    res += settingString(setting.StopBits) + ",";
    res += settingString(setting.FlowControl);
    return res;
}

template<typename T1, int size>
QStringList getValues(T1 (&map)[size])
{
    QStringList list;
    for(int i=0;i<size;i++){
        list.append(QString::fromLocal8Bit(map[i].desc));
    }
    return list;
}

template<typename T1, int size>
void tranverseSettingElement(T1 (&map)[size], pfnTranverse_t pfn, void* context, const QString& prefix){
    for(int i=0;i<size;i++){
        pfn(QString(map[i].desc).toLower().replace('_','.'),
            prefix+QString("|%0").arg(map[i].value),
            false,
            context);
    }
}

template<typename T>
void tranverseSetting(T setting, pfnTranverse_t pfn, void* context);

template<>
void tranverseSetting(BaudRateType setting, pfnTranverse_t pfn, void* context)
{
    (void)setting;
    pfn("Baud rate","",true, context);
    tranverseSettingElement(BaudRateTypeMap, pfn, context, "B");
}

template<>
QStringList validValues<BaudRateType>()
{
    return getValues(BaudRateTypeMap);
}

template<>
void tranverseSetting(DataBitsType setting, pfnTranverse_t pfn, void* context)
{
    (void)setting;
    pfn("Data bits","",true, context);
    tranverseSettingElement(DataBitsTypeMap, pfn, context, "D");
}

template<>
QStringList validValues<DataBitsType>()
{
    return getValues(DataBitsTypeMap);
}

template<>
void tranverseSetting(ParityType setting, pfnTranverse_t pfn, void* context)
{
    (void)setting;
    pfn("Parity","",true, context);
    tranverseSettingElement(ParityTypeMap, pfn, context, "P");
}

template<>
QStringList validValues<ParityType>()
{
    return getValues(ParityTypeMap);
}

template<>
void tranverseSetting(StopBitsType setting, pfnTranverse_t pfn, void* context)
{
    (void)setting;
    pfn("Stop bits","",true, context);
    tranverseSettingElement(StopBitsTypeMap, pfn, context, "S");
}

template<>
QStringList validValues<StopBitsType>()
{
    return getValues(StopBitsTypeMap);
}

template<>
void tranverseSetting(FlowType setting, pfnTranverse_t pfn, void* context)
{
    (void)setting;
    pfn("Flow control","",true, context);
    tranverseSettingElement(FlowTypeMap, pfn, context, "F");
}

template<>
QStringList validValues<FlowType>()
{
    return getValues(FlowTypeMap);
}

void tranverseSetting(pfnTranverse_t pfn, void* context)
{
    PortSettings *setting = new PortSettings();

    tranverseSetting(setting->BaudRate, pfn, context);
    tranverseSetting(setting->DataBits, pfn, context);
    tranverseSetting(setting->Parity, pfn, context);
    tranverseSetting(setting->StopBits, pfn, context);
    tranverseSetting(setting->FlowControl, pfn, context);

    delete setting;
}

template<typename T, typename T2>
inline void assign(T& d, T2 s){
    d = (T)s;
}

template<typename T, typename T2>
inline bool same(T d, T2 s){
    return d == (T)s;
}

void  UpdatePortSettingString(PortSettings& setting, const QString& str)
{
    if(str.at(1) != '|')return;
    int val = str.right(str.length()-2).toInt();
    switch(str.at(0).toAscii()){
        case 'B':
        assign(setting.BaudRate,val);
        return;
        case 'D':
        assign(setting.DataBits,val);
        return;
        case 'P':
        assign(setting.Parity,val);
        return;
        case 'S':
        assign(setting.StopBits,val);
        return;
        case 'F':
        assign(setting.FlowControl,val);
        return;
    }
}

bool isSameSetting(const PortSettings& setting, const QString& str)
{
    if(str.at(1) != '|')return false;
    int val = str.right(str.length()-2).toInt();
    switch(str.at(0).toAscii()){
        case 'B':
        return same(setting.BaudRate,val);
        case 'D':
        return same(setting.DataBits,val);
        case 'P':
        return same(setting.Parity,val);
        case 'S':
        return same(setting.StopBits,val);
        case 'F':
        return same(setting.FlowControl,val);
    }
    return false;
}
