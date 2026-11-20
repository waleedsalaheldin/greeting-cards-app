"""Patch the Android project that `flutter create` generates.

Safe to run more than once: every change checks whether it is already there.

- App name in Arabic + AdMob app id + INTERNET permission (AndroidManifest)
- minSdk >= 23, targetSdk/compileSdk >= 36 (Google Play)
- Skip release lint (crashes on some setups)
- R8 keep rules for WorkManager/Room (used by AdMob; release crashed without them)
- kotlin.incremental=false (fixes Windows builds when project and pub cache are on different drives)
- Release signing with the upload key when KEYSTORE_PATH is set
"""
import os
import pathlib
import sys

ANDROID = pathlib.Path(__file__).resolve().parent.parent / "android"
ROOT = ANDROID / "app"
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"

PROGUARD_RULES = """# WorkManager / Room are used by Google Mobile Ads.
# Without these, R8 strips the generated database class and the release app
# crashes on launch: "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.room.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**
"""


def fail(msg):
    print(f"patch_android: {msg}", file=sys.stderr)
    sys.exit(1)


def patch_manifest():
    path = ROOT / "src" / "main" / "AndroidManifest.xml"
    text = path.read_text(encoding="utf-8")

    app_id = os.environ.get("ADMOB_APP_ID", "").strip() or TEST_ADMOB_APP_ID
    # A wrong App ID makes the app crash on launch. The App ID has "~",
    # the ad unit ID has "/" and is a common mix-up.
    if not app_id.startswith("ca-app-pub-") or "~" not in app_id:
        print("::warning::ADMOB_APP_ID looks wrong (must look like "
              "ca-app-pub-XXXX~YYYY). Using Google's test App ID instead.")
        app_id = TEST_ADMOB_APP_ID

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

    key = "com.google.android.gms.ads.APPLICATION_ID"
    if key in text:
        # Already there: just update the value.
        i = text.index(key)
        vstart = text.index('android:value="', i) + len('android:value="')
        vend = text.index('"', vstart)
        text = text[:vstart] + app_id + text[vend:]
    else:
        meta = (
            '        <meta-data\n'
            f'            android:name="{key}"\n'
            f'            android:value="{app_id}"/>\n'
        )
        if "</application>" not in text:
            fail("</application> not found in manifest")
        text = text.replace("</application>", meta + "    </application>", 1)
    path.write_text(text, encoding="utf-8")
    print("manifest patched")


def patch_gradle_properties():
    path = ANDROID / "gradle.properties"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    if "kotlin.incremental" not in text:
        text = text.rstrip("\n") + "\nkotlin.incremental=false\n"
        path.write_text(text, encoding="utf-8")
    print("gradle.properties patched")


def write_proguard_rules():
    (ROOT / "proguard-rules.pro").write_text(PROGUARD_RULES, encoding="utf-8")
    print("proguard-rules.pro written")


def _insert_after_release_block(text, line):
    """Insert `line` as the first line inside buildTypes { release { ... } }."""
    bt = text.find("buildTypes {")
    if bt == -1:
        fail("buildTypes block not found")
    rel = text.find("release {", bt)
    if rel == -1:
        fail("release block not found inside buildTypes")
    pos = rel + len("release {")
    return text[:pos] + "\n            " + line + text[pos:]


def patch_gradle():
    kts = ROOT / "build.gradle.kts"
    groovy = ROOT / "build.gradle"
    signing = bool(os.environ.get("KEYSTORE_PATH"))

    if kts.exists():
        text = kts.read_text(encoding="utf-8")
        text = text.replace(
            "minSdk = flutter.minSdkVersion",
            "minSdk = maxOf(flutter.minSdkVersion, 23)",
        ).replace(
            "targetSdk = flutter.targetSdkVersion",
            "targetSdk = maxOf(flutter.targetSdkVersion, 36)",
        ).replace(
            "compileSdk = flutter.compileSdkVersion",
            "compileSdk = maxOf(flutter.compileSdkVersion, 36)",
        )
        if "checkReleaseBuilds" not in text:
            if "android {" not in text:
                fail("android block not found in build.gradle.kts")
            text = text.replace(
                "android {",
                "android {\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }\n",
                1,
            )
        if "proguard-rules.pro" not in text:
            text = _insert_after_release_block(
                text,
                'proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")',
            )
        if signing and 'create("release")' not in text:
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
        if "checkReleaseBuilds" not in text:
            text = text.replace(
                "android {",
                "android {\n    lint {\n        checkReleaseBuilds false\n        abortOnError false\n    }\n",
                1,
            )
        if "proguard-rules.pro" not in text:
            text = _insert_after_release_block(
                text,
                "proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'",
            )
        if signing and "signingConfigs {" not in text:
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
    patch_gradle_properties()
    write_proguard_rules()
    patch_gradle()
