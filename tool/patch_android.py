"""Patch the Android project that `flutter create` generates in CI.

- App name in Arabic + AdMob app id + INTERNET permission (AndroidManifest)
- minSdk >= 23 (needed by google_mobile_ads)
- Release signing with the upload key when KEYSTORE_PATH is set
"""
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "android" / "app"
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def fail(msg):
    print(f"patch_android: {msg}", file=sys.stderr)
    sys.exit(1)


def patch_manifest():
    path = ROOT / "src" / "main" / "AndroidManifest.xml"
    text = path.read_text(encoding="utf-8")

    app_id = os.environ.get("ADMOB_APP_ID", "").strip() or TEST_ADMOB_APP_ID

    if 'android:label="' not in text:
        fail("android:label not found in manifest")
    start = text.index('android:label="') + len('android:label="')
    end = text.index('"', start)
    text = text[:start] + "بطاقات تهنئة" + text[end:]

    if "android.permission.INTERNET" not in text:
        text = text.replace(
            "<application",
            '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
            1,
        )

    meta = (
        '        <meta-data\n'
        '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        f'            android:value="{app_id}"/>\n'
    )
    if "</application>" not in text:
        fail("</application> not found in manifest")
    text = text.replace("</application>", meta + "    </application>", 1)
    path.write_text(text, encoding="utf-8")
    print("manifest patched")


def patch_gradle():
    kts = ROOT / "build.gradle.kts"
    groovy = ROOT / "build.gradle"
    signing = bool(os.environ.get("KEYSTORE_PATH"))

    if kts.exists():
        text = kts.read_text(encoding="utf-8")
        text = text.replace(
            "minSdk = flutter.minSdkVersion",
            "minSdk = maxOf(flutter.minSdkVersion, 23)",
        )
        if signing:
            block = (
                "    signingConfigs {\n"
                '        create("release") {\n'
                '            storeFile = file(System.getenv("KEYSTORE_PATH"))\n'
                '            storePassword = System.getenv("KEYSTORE_PASSWORD")\n'
                '            keyAlias = System.getenv("KEY_ALIAS") ?: "upload"\n'
                '            keyPassword = System.getenv("KEYSTORE_PASSWORD")\n'
                "        }\n"
                "    }\n\n"
                "    buildTypes {"
            )
            if "    buildTypes {" not in text:
                fail("buildTypes block not found in build.gradle.kts")
            text = text.replace("    buildTypes {", block, 1)
            old = 'signingConfig = signingConfigs.getByName("debug")'
            if old not in text:
                fail("debug signingConfig line not found in build.gradle.kts")
            text = text.replace(old, 'signingConfig = signingConfigs.getByName("release")')
        kts.write_text(text, encoding="utf-8")
        print("build.gradle.kts patched (signing=%s)" % signing)
    elif groovy.exists():
        text = groovy.read_text(encoding="utf-8")
        text = text.replace(
            "minSdk = flutter.minSdkVersion",
            "minSdk = Math.max(flutter.minSdkVersion, 23)",
        ).replace(
            "minSdkVersion flutter.minSdkVersion",
            "minSdkVersion Math.max(flutter.minSdkVersion, 23)",
        )
        if signing:
            block = (
                "    signingConfigs {\n"
                "        release {\n"
                '            storeFile file(System.getenv("KEYSTORE_PATH"))\n'
                '            storePassword System.getenv("KEYSTORE_PASSWORD")\n'
                '            keyAlias System.getenv("KEY_ALIAS") ?: "upload"\n'
                '            keyPassword System.getenv("KEYSTORE_PASSWORD")\n'
                "        }\n"
                "    }\n\n"
                "    buildTypes {"
            )
            text = text.replace("    buildTypes {", block, 1)
            text = text.replace(
                "signingConfig = signingConfigs.debug",
                "signingConfig = signingConfigs.release",
            ).replace(
                "signingConfig signingConfigs.debug",
                "signingConfig signingConfigs.release",
            )
        groovy.write_text(text, encoding="utf-8")
        print("build.gradle patched (signing=%s)" % signing)
    else:
        fail("no app build.gradle(.kts) found")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle()
