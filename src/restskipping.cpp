/**
 * @file restskipping.cpp
 * @brief RestSkippingDispatcher's thread-local state (see restskipping.h).
 */

#include "restskipping.h"

#if BT_THREADSAFE
thread_local int RestSkippingDispatcher::t_pair = 0;
thread_local int RestSkippingDispatcher::t_seq = 0;
#endif
