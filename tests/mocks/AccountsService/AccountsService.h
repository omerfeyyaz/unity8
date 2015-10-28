/*
 * Copyright (C) 2013 Canonical, Ltd.
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
 *
 * Authors: Gerry Boland <gerry.boland@canonical.com>
 *          Michael Terry <michael.terry@canonical.com>
 */

#ifndef UNITY_MOCK_ACCOUNTSSERVICE_H
#define UNITY_MOCK_ACCOUNTSSERVICE_H

#include <QObject>
#include <QString>
#include <QVariant>

class AccountsService: public QObject
{
    Q_OBJECT
    Q_ENUMS(PasswordDisplayHint)
    Q_PROPERTY (QString user
                READ user
                WRITE setUser
                NOTIFY userChanged)
    Q_PROPERTY (bool demoEdges
                READ demoEdges
                WRITE setDemoEdges
                NOTIFY demoEdgesChanged)
    Q_PROPERTY (bool enableLauncherWhileLocked
                READ enableLauncherWhileLocked
                WRITE setEnableLauncherWhileLocked // only available in mock
                NOTIFY enableLauncherWhileLockedChanged)
    Q_PROPERTY (bool enableIndicatorsWhileLocked
                READ enableIndicatorsWhileLocked
                WRITE setEnableIndicatorsWhileLocked // only available in mock
                NOTIFY enableIndicatorsWhileLockedChanged)
    Q_PROPERTY (QString backgroundFile
                READ backgroundFile
                WRITE setBackgroundFile // only available in mock
                NOTIFY backgroundFileChanged)
    Q_PROPERTY (bool statsWelcomeScreen
                READ statsWelcomeScreen
                WRITE setStatsWelcomeScreen // only available in mock
                NOTIFY statsWelcomeScreenChanged)
    Q_PROPERTY (PasswordDisplayHint passwordDisplayHint
                READ passwordDisplayHint
                NOTIFY passwordDisplayHintChanged)
    Q_PROPERTY (uint failedLogins
                READ failedLogins
                WRITE setFailedLogins
                NOTIFY failedLoginsChanged)
    Q_PROPERTY(bool hereEnabled
               READ hereEnabled
               WRITE setHereEnabled
               NOTIFY hereEnabledChanged)
    Q_PROPERTY(QString hereLicensePath
               READ hereLicensePath
               WRITE setHereLicensePath // only available in mock
               NOTIFY hereLicensePathChanged)
    Q_PROPERTY(bool hereLicensePathValid // qml sees a null string as "", so we use proxy setting for that
               READ hereLicensePathValid
               NOTIFY hereLicensePathChanged)

public:
    enum PasswordDisplayHint {
        Keyboard,
        Numeric,
    };

    explicit AccountsService(QObject *parent = 0);

    QString user() const;
    void setUser(const QString &user);
    bool demoEdges() const;
    void setDemoEdges(bool demoEdges);
    bool enableLauncherWhileLocked() const;
    void setEnableLauncherWhileLocked(bool enableLauncherWhileLocked);
    bool enableIndicatorsWhileLocked() const;
    void setEnableIndicatorsWhileLocked(bool enableIndicatorsWhileLocked);
    QString backgroundFile() const;
    void setBackgroundFile(const QString &backgroundFile);
    bool statsWelcomeScreen() const;
    void setStatsWelcomeScreen(bool statsWelcomeScreen);
    PasswordDisplayHint passwordDisplayHint() const;
    uint failedLogins() const;
    void setFailedLogins(uint failedLogins);
    bool hereEnabled() const;
    void setHereEnabled(bool enabled);
    QString hereLicensePath() const;
    void setHereLicensePath(const QString &path);
    bool hereLicensePathValid() const;

Q_SIGNALS:
    void userChanged();
    void demoEdgesChanged();
    void enableLauncherWhileLockedChanged();
    void enableIndicatorsWhileLockedChanged();
    void backgroundFileChanged();
    void statsWelcomeScreenChanged();
    void passwordDisplayHintChanged();
    void failedLoginsChanged();
    void hereEnabledChanged();
    void hereLicensePathChanged();

private:
    bool m_enableLauncherWhileLocked;
    bool m_enableIndicatorsWhileLocked;
    QString m_backgroundFile;
    QString m_user;
    bool m_statsWelcomeScreen;
    uint m_failedLogins;
    bool m_demoEdges;
    bool m_hereEnabled;
    QString m_hereLicensePath;
};

#endif
