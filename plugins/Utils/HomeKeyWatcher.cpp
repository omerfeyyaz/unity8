/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include "HomeKeyWatcher.h"

#include <QQuickWindow>

using namespace UnityUtil;

HomeKeyWatcher::HomeKeyWatcher(QQuickItem *parent)
    : HomeKeyWatcher(new Timer, new ElapsedTimer, parent)
{
}

HomeKeyWatcher::HomeKeyWatcher(UnityUtil::AbstractTimer *timer,
        UnityUtil::AbstractElapsedTimer *elapsedTimer,
        QQuickItem *parent)
    : QQuickItem(parent)
    , m_windowBeingTouched(false)
    , m_homeKeyPressed(false)
    , m_windowLastTouchedTimer(elapsedTimer)
    , m_activationTimer(timer)
{
    m_windowLastTouchedTimer->start();

    connect(this, &QQuickItem::windowChanged,
            this, &HomeKeyWatcher::setupFilterOnWindow);

    connect(m_activationTimer, &UnityUtil::AbstractTimer::timeout,
        this, &HomeKeyWatcher::emitActivatedIfNoTouchesAround);
    m_activationTimer->setInterval(msecsWithoutTouches);
}

HomeKeyWatcher::~HomeKeyWatcher()
{
    delete m_windowLastTouchedTimer;
    delete m_activationTimer;
}

bool HomeKeyWatcher::eventFilter(QObject *watched, QEvent *event)
{
    Q_ASSERT(!m_filteredWindow.isNull());
    Q_ASSERT(watched == static_cast<QObject*>(m_filteredWindow.data()));
    Q_UNUSED(watched);

    update(event);

    // We're only monitoring, never filtering out events
    return false;
}

void HomeKeyWatcher::update(QEvent *event)
{
    if (event->type() == QEvent::KeyPress) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);

        m_homeKeyPressed = true;

        if (keyEvent->key() == Qt::Key_Super_L && !keyEvent->isAutoRepeat()
                && !m_windowBeingTouched
                && m_windowLastTouchedTimer->elapsed() >= msecsWithoutTouches) {
            m_activationTimer->start();
        }

    } else if (event->type() == QEvent::KeyRelease) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);

        if (keyEvent->key() == Qt::Key_Super_L) {
            m_homeKeyPressed = false;
        }

    } else if (event->type() == QEvent::TouchBegin) {

        m_activationTimer->stop();
        m_windowBeingTouched = true;

    } else if (event->type() == QEvent::TouchEnd) {

        m_windowBeingTouched = false;
        m_windowLastTouchedTimer->start();
    }
}

void HomeKeyWatcher::setupFilterOnWindow(QQuickWindow *window)
{
    if (!m_filteredWindow.isNull()) {
        m_filteredWindow->removeEventFilter(this);
        m_filteredWindow.clear();
    }

    if (window) {
        window->installEventFilter(this);
        m_filteredWindow = window;
    }
}

void HomeKeyWatcher::emitActivatedIfNoTouchesAround()
{
    if (!m_homeKeyPressed && !m_windowBeingTouched &&
            (m_windowLastTouchedTimer->elapsed() > msecsWithoutTouches)) {
        Q_EMIT activated();
    }
}
