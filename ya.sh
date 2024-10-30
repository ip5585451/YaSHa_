#!/bin/bash

echo "Проверка подключения ADB..."
adb devices | grep -w "device" | grep -v "List of devices attached" > /dev/null
if [ $? -ne 0 ]; then
    echo "Устройство ADB не обнаружено. Пожалуйста, подключите устройство и включите отладку по USB."
    exit 1
fi
echo "Устройство ADB подключено."

echo "Скачивание yasha_1.zip..."
curl -L -o yasha_1.zip --progress-bar "https://github.com/ip5585451/YaSHa_/raw/refs/heads/main/yasha_1.zip"
if [ $? -ne 0 ]; then
    echo "Не удалось скачать yasha_1.zip."
    exit 1
fi

echo "Скачивание yasha_2.zip..."
curl -L -o yasha_2.zip --progress-bar "https://github.com/ip5585451/YaSHa_/raw/refs/heads/main/yasha_2.zip"
if [ $? -ne 0 ]; then
    echo "Не удалось скачать yasha_2.zip."
    exit 1
fi
echo "Скачивание завершено."

echo "Распаковка архивов..."
unzip -o yasha_1.zip -d yasha_files
if [ $? -ne 0 ]; then
    echo "Не удалось распаковать yasha_1.zip."
    exit 1
fi

unzip -o yasha_2.zip -d yasha_files
if [ $? -ne 0 ]; then
    echo "Не удалось распаковать yasha_2.zip."
    exit 1
fi
echo "Распаковка завершена."

echo "Получение root-доступа и перемонтирование /system..."
adb root
adb remount
adb shell mount | grep '/system' | grep 'rw,' > /dev/null
if [ $? -ne 0 ]; then
    echo "Не удалось перемонтировать /system в режим чтения-записи."
    exit 1
fi
echo "/system перемонтирован в режим чтения-записи."

apps=("YandexMusic" "YandexAuth" "YandexNavi" "YandexUma")

for app in "${apps[@]}"; do
    echo "Обработка $app..."

    echo "Создание директории /system/priv-app/$app..."
    adb shell mkdir -p /system/priv-app/$app
    adb shell chmod 755 /system/priv-app/$app

    echo "Копирование $app.apk..."
    adb push "yasha_files/$app/$app.apk" /system/priv-app/$app/

    echo "Создание директории oat/arm64..."
    adb shell mkdir -p /system/priv-app/$app/oat/arm64
    adb shell chmod 755 /system/priv-app/$app/oat
    adb shell chmod 755 /system/priv-app/$app/oat/arm64

    echo "Копирование odex и vdex файлов..."
    adb push "yasha_files/$app/oat/arm64/$app.odex" /system/priv-app/$app/oat/arm64/
    adb push "yasha_files/$app/oat/arm64/$app.vdex" /system/priv-app/$app/oat/arm64/

    echo "Установка прав 644 на файлы..."
    adb shell chmod 644 /system/priv-app/$app/$app.apk
    adb shell chmod 644 /system/priv-app/$app/oat/arm64/$app.odex
    adb shell chmod 644 /system/priv-app/$app/oat/arm64/$app.vdex

    echo "Установка SELinux контекста..."
    adb shell chcon -R u:object_r:system_file:s0 /system/priv-app/$app
done

echo "Очистка временных файлов..."
rm -rf yasha_1.zip yasha_2.zip yasha_files

echo "Перезагрузка устройства..."
adb reboot

echo "Готово."
