/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "TouchEventSequenceWrapper.h"
#include <private/qquickwindow_p.h>

TouchEventSequenceWrapper::TouchEventSequenceWrapper(QTest::QTouchEventSequence eventSequence, QQuickItem *item)
    : QObject(0)
    , m_eventSequence(eventSequence)
    , m_item(item)
{
}

void TouchEventSequenceWrapper::commit(bool processEvents)
{
    m_eventSequence.commit(processEvents);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
    if (m_item->window()) {
        QQuickWindowPrivate *wp = QQuickWindowPrivate::get(m_item->window());
        wp->flushDelayedTouchEvent();
    }
#endif
}

void TouchEventSequenceWrapper::move(int touchId, int x, int y)
{
    m_eventSequence.move(touchId, QPoint(x, y));
}

void TouchEventSequenceWrapper::press(int touchId, int x, int y)
{
    m_eventSequence.press(touchId, QPoint(x, y));
}

void TouchEventSequenceWrapper::release(int touchId, int x, int y)
{
    m_eventSequence.release(touchId, QPoint(x, y));
}

void TouchEventSequenceWrapper::stationary(int touchId)
{
    m_eventSequence.stationary(touchId);
}
