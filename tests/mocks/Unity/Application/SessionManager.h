/*
 * Copyright (C) 2014 Canonical, Ltd.
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

#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>

class Session;

class SessionManager : public QObject
{
    Q_OBJECT
public:
    explicit SessionManager(QObject *parent = 0);

    static SessionManager *singleton();

    Q_INVOKABLE Session* createSession(const QString& name, const QUrl& screenshot);

    void registerSession(Session *session);

Q_SIGNALS:
    void sessionStarting(Session *session);
    void sessionStopping(Session *session);

private:
    static SessionManager *the_session_manager;
};

#endif // SESSIONMANAGER_H
