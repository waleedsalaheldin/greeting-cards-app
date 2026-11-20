# بطاقات تهنئة 🎉

تطبيق Android لتصميم بطاقات تهنئة عربية ومشاركتها (رمضان، الأعياد، يوم التأسيس، اليوم الوطني، الزواج، المواليد، التخرج…)، مع إعلانات AdMob.

## إزاي التطبيق بيتبني
كل ما يترفع كود جديد على `main`، GitHub Actions بيبني التطبيق أوتوماتيك.
الملفات الجاهزة بتلاقيها في تبويب **Actions** ← آخر تشغيل ← **Artifacts**:
- `app-release.apk` ← للتجربة على موبايلك
- `app-release.aab` ← للرفع على Google Play

## الأسرار (Settings ← Secrets and variables ← Actions)
| الاسم | لازم؟ | القيمة |
|---|---|---|
| `KEYSTORE_BASE64` | أيوه (عشان Google Play) | محتوى ملف KEYSTORE_BASE64.txt |
| `KEYSTORE_PASSWORD` | أيوه | محتوى ملف KEYSTORE_PASSWORD.txt |
| `ADMOB_APP_ID` | بعد ما تعمل حساب AdMob | App ID (شكله `ca-app-pub-xxx~yyy`) |
| `ADMOB_BANNER_ID` | بعد ما تعمل حساب AdMob | Banner ad unit ID (شكله `ca-app-pub-xxx/zzz`) |

من غير أسرار AdMob التطبيق بيعرض إعلانات Google **التجريبية** (مفيش منها ربح).

⚠️ **ملف مفتاح التوقيع (`upload-keystore.jks`) وكلمة السر ما يترفعوش في الكود أبداً.** احتفظ بيهم في مكان آمن.

## سياسة الخصوصية
[docs/privacy.md](docs/privacy.md)
