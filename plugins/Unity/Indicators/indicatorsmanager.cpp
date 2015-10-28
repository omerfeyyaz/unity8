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
 * Author: Nick Dedekind <nick.dedekind@canonical.com>
 */

#include "indicatorsmanager.h"

#include <QSettings>
#include <QDebug>

#include <paths.h>


class IndicatorsManager::IndicatorData
{
public:
    IndicatorData(const QString& name, const QFileInfo& fileInfo)
        : m_name(name)
        , m_fileInfo(fileInfo)
        , m_verified (true)
    {
    }

    QString m_name;
    QFileInfo m_fileInfo;

    bool m_verified;
    Indicator::Ptr m_indicator;
};

IndicatorsManager::IndicatorsManager(QObject* parent)
    : QObject(parent)
    , m_loaded(false)
    , m_profile(QStringLiteral("phone"))
{
}

IndicatorsManager::~IndicatorsManager()
{
    unload();

}

void IndicatorsManager::load()
{
    unload();

    QStringList xdgLocations = shellDataDirs();//QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);

    m_fsWatcher.reset(new QFileSystemWatcher(this));

    Q_FOREACH(const QString& xdgLocation, xdgLocations)
    {
        QString indicator_path = QDir::cleanPath(xdgLocation + "/unity/indicators");
        QDir indicator_dir(indicator_path);
        if (indicator_dir.exists())
        {
            // watch folder for changes.
            m_fsWatcher->addPath(indicator_path);

            loadDir(indicator_dir);
        }
    }

    QObject::connect(m_fsWatcher.data(), &QFileSystemWatcher::directoryChanged, this, &IndicatorsManager::onDirectoryChanged);
    QObject::connect(m_fsWatcher.data(), &QFileSystemWatcher::fileChanged, this, &IndicatorsManager::onFileChanged);
    setLoaded(true);
}

void IndicatorsManager::onDirectoryChanged(const QString& directory)
{
    loadDir(QDir(directory));
}

void IndicatorsManager::onFileChanged(const QString& file)
{
    QFileInfo file_info(file);
    if (!file_info.exists())
    {
        unloadFile(file_info);
        return;
    }
    else
    {
        loadFile(QFileInfo(file));
    }
}

void IndicatorsManager::loadDir(const QDir& dir)
{
    startVerify(dir.canonicalPath());

    QFileInfoList indicator_files = dir.entryInfoList(QStringList(), QDir::Files|QDir::NoDotAndDotDot);
    Q_FOREACH(const QFileInfo& indicator_file, indicator_files)
    {
        loadFile(indicator_file);
    }

    endVerify(dir.canonicalPath());
}

void IndicatorsManager::loadFile(const QFileInfo& file_info)
{
    QSettings indicator_settings(file_info.absoluteFilePath(), QSettings::IniFormat, this);
    QString name = indicator_settings.value(QStringLiteral("Indicator Service/Name")).toString();

    auto iter = m_indicatorsData.find(name);
    if (iter != m_indicatorsData.end())
    {
        QString newFileInfoDir = QDir::cleanPath(file_info.canonicalPath());
        IndicatorData* currentData = (*iter);
        currentData->m_verified = true;

        int file_info_location = -1;
        int current_data_location = -1;

        QString currentDataDir = QDir::cleanPath(currentData->m_fileInfo.canonicalPath());

        // if we've already got this indicator, we need to make sure we're not overwriting data which is
        // from a lower priority standard path
        QStringList xdgLocations = shellDataDirs();
        for (int i = 0; i < xdgLocations.size(); i++)
        {
            QString indicatorDir = QDir::cleanPath(xdgLocations[i] + "/unity/indicators");

            if (newFileInfoDir == indicatorDir)
            {
                file_info_location = i;
            }
            if (currentDataDir == indicatorDir)
            {
                current_data_location = i;
            }

            if (file_info_location != -1 && current_data_location != -1)
            {
                break;
            }
        }

        // file location is higher (or of equal) priority. overwrite.
        if (file_info_location <= current_data_location &&
            file_info != currentData->m_fileInfo)
        {
            currentData->m_fileInfo = file_info;
            Q_EMIT indicatorLoaded(name);
        }
    }
    else
    {
        IndicatorData* data = new IndicatorData(name, file_info);
        data->m_verified = true;
        m_indicatorsData[name]= data;
        Q_EMIT indicatorLoaded(name);
    }
}

void IndicatorsManager::unload()
{
    QHashIterator<QString, IndicatorData*> iter(m_indicatorsData);
    while(iter.hasNext())
    {
        iter.next();
        Q_EMIT indicatorAboutToBeUnloaded(iter.key());
    }

    qDeleteAll(m_indicatorsData);
    m_indicatorsData.clear();

    setLoaded(false);
}

void IndicatorsManager::unloadFile(const QFileInfo& file)
{
    QMutableHashIterator<QString, IndicatorData*> iter(m_indicatorsData);
    while(iter.hasNext())
    {
        iter.next();
        IndicatorData* data = iter.value();
        if (data->m_fileInfo.absoluteFilePath() == file.absoluteFilePath())
        {
            if (!data->m_verified)
            {
                QString name = data->m_name;
                Q_EMIT indicatorAboutToBeUnloaded(name);

                delete data;
                iter.remove();
            }
        }
    }

    setLoaded(m_indicatorsData.size() > 0);
}

void IndicatorsManager::setLoaded(bool loaded)
{
    if (loaded != m_loaded)
    {
        m_loaded = loaded;
        Q_EMIT loadedChanged(m_loaded);
    }
}

QString IndicatorsManager::profile() const
{
    return m_profile;
}

void IndicatorsManager::setProfile(const QString& profile)
{
    if (m_profile != profile) {
        m_profile = profile;
        Q_EMIT profileChanged(m_profile);
    }
}

void IndicatorsManager::startVerify(const QString& path)
{
    QHashIterator<QString, IndicatorData*> iter(m_indicatorsData);
    while(iter.hasNext())
    {
        iter.next();
        IndicatorData* data = iter.value();
        if (data->m_fileInfo.canonicalPath() == path)
        {
           data->m_verified = false;
        }
    }
}

void IndicatorsManager::endVerify(const QString& path)
{
    QMutableHashIterator<QString, IndicatorData*> iter(m_indicatorsData);
    while(iter.hasNext())
    {
        iter.next();
        IndicatorData* data = iter.value();
        if (data->m_fileInfo.canonicalPath() == path)
        {
            if (!data->m_verified)
            {
                QString name = data->m_name;
                Q_EMIT indicatorAboutToBeUnloaded(name);

                delete data;
                iter.remove();
            }
        }
    }
}

Indicator::Ptr IndicatorsManager::indicator(const QString& indicator_name)
{
    if (!m_indicatorsData.contains(indicator_name))
    {
        qWarning() << Q_FUNC_INFO << "Invalid indicator name: " <<  indicator_name;
        return Indicator::Ptr();
    }

    IndicatorData *data = m_indicatorsData[indicator_name];
    if (data->m_indicator)
    {
        return data->m_indicator;
    }

    Indicator::Ptr new_indicator(new Indicator(this));
    data->m_indicator = new_indicator;
    QSettings settings(data->m_fileInfo.absoluteFilePath(), QSettings::IniFormat, this);
    new_indicator->init(data->m_fileInfo.fileName(), settings);
    new_indicator->setProfile(m_profile);
    QObject::connect(this, &IndicatorsManager::profileChanged, new_indicator.data(), &Indicator::setProfile);
    return new_indicator;
}

QVector<Indicator::Ptr> IndicatorsManager::indicators()
{
    QVector<Indicator::Ptr> list;
    Q_FOREACH(IndicatorData* data, m_indicatorsData)
    {
        Indicator::Ptr ret = indicator(data->m_name);
        if (ret)
            list.append(ret);
    }
    return list;
}

bool IndicatorsManager::isLoaded() const
{
    return m_loaded;
}
