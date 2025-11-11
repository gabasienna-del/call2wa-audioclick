#!/usr/bin/env bash
set -e

PROJ_DIR="$(pwd)"
OUT_DIR="$PROJ_DIR/out"
LIBS_DIR="$PROJ_DIR/libs"
APK_NAME="call2wa-audioclick.apk"
MANIFEST="$PROJ_DIR/app/src/main/AndroidManifest.xml"

echo "[1/8] Очистка и подготовка"
rm -rf "$OUT_DIR" classes.dex "$APK_NAME"
mkdir -p "$OUT_DIR"

# на всякий случай создадим assets/xposed_init (если нет)
if [ ! -f "$PROJ_DIR/app/src/main/assets/xposed_init" ]; then
  echo "[1a] Создаю assets/xposed_init"
  mkdir -p "$PROJ_DIR/app/src/main/assets"
  echo "com.example.call2wa.HookInit" > "$PROJ_DIR/app/src/main/assets/xposed_init"
fi

# минимальный манифест (если вдруг поврежден)
if ! grep -q "<manifest" "$MANIFEST" 2>/dev/null; then
  echo "[1b] Переписываю минимальный AndroidManifest.xml"
  cat > "$MANIFEST" <<'MANI'
<manifest package="com.example.call2wa"
    xmlns:android="http://schemas.android.com/apk/res/android">
    <application/>
</manifest>
MANI
fi

echo "[2/8] Компиляция Kotlin (с xposed-api.jar и android-stub.jar)"
kotlinc "$PROJ_DIR/app/src/main/java/com/example/call2wa/HookInit.kt" \
  -classpath "$LIBS_DIR/xposed-api.jar:$LIBS_DIR/android-stub.jar" \
  -d "$OUT_DIR"

echo "[3/8] Проверка .class"
if [ -z "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
  echo "Ошибка: каталог $OUT_DIR пуст. Компиляция не удалась."
  exit 1
fi
ls -l "$OUT_DIR" >/dev/null

echo "[4/8] Преобразование в DEX"
if ! command -v dx >/dev/null 2>&1; then
  echo "Ошибка: dx не установлен. Выполни: pkg install dx"
  exit 1
fi
dx --dex --min-sdk-version=26 --output=classes.dex "$OUT_DIR"

echo "[5/8] Подготовка файлов (без aapt)"
cp "$MANIFEST" ./AndroidManifest.xml
rm -rf assets && mkdir -p assets
cp -a "$PROJ_DIR/app/src/main/assets/." assets/

echo "[6/8] Упаковка APK (zip)"
rm -f "$APK_NAME"
zip -q -r "$APK_NAME" AndroidManifest.xml assets >/dev/null
zip -q -g "$APK_NAME" classes.dex >/dev/null
ls -lh "$APK_NAME"

echo "[7/8] Подпись APK (debug key)"
mkdir -p ~/.android
KEYSTORE=~/.android/debug.keystore
if [ ! -f "$KEYSTORE" ]; then
  echo "Создаю debug keystore..."
  keytool -genkeypair -v -keystore "$KEYSTORE" -storepass android \
    -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
    -validity 10000 -dname "CN=Termux,O=Android,C=US"
fi

if ! command -v apksigner >/dev/null 2>&1; then
  echo "Ошибка: apksigner не найден. Поставь его (из build-tools) или поставь SDK. Пока APK не будет подписан."
  exit 1
fi

apksigner sign --min-sdk-version 26 --ks "$KEYSTORE" --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android "$APK_NAME"

echo "[8/8] Установка APK"
if command -v pm >/dev/null 2>&1; then
  pm install -r "$APK_NAME" || true
  echo "Готово — APK: $PWD/$APK_NAME"
else
  echo "Готово — APK: $PWD/$APK_NAME (установи вручную или через adb)"
fi
