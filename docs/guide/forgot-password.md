[Documentation](../README.md) › User guide › Forgot password

# Forgot password · نسيت كلمة المرور

<img src="images/forgot-password.png" alt="Forgot password" width="300">

## English

**What it is for:** choosing a new password when you forgot yours, with a code sent to your email (redix-api #127).
**Who sees it:** everyone who is not signed in, from **Forgot your password?** on the [sign-in](sign-in.md) screen. The admin too.

1. Type your username or your email, and tap **Send the code**.
2. The screen says: **If the account has an email, a code valid for 15 minutes was sent to it.** It says the same for any username, so nobody learns who has an account. The email comes in the language the app is in.
3. Type the six digits of the email, then your new password twice, and tap **Change the password**.
4. You are back on sign-in: sign in with the new password. Every phone you were signed in on is signed out, and a lock from wrong passwords ends.

A code works once, for 15 minutes and 5 tries. **Send the code** again sends a new one, and the earlier stops working. No email arrives when your account has no email yet: your project manager types it in [Users](users.md), or you set it in [Settings](settings.md).

| Message | Meaning |
| --- | --- |
| The code is wrong or has expired. | Check the six digits, or send a new code. |
| Use at least 8 characters with a letter and a digit, not the user name. | Choose a stronger password; the code still works. |
| The new passwords do not match. | Type the same new password twice. |
| Too many requests. Try again shortly. | Wait a while before asking again. |
| No connection to the server. Try again. | The phone cannot reach REDIX; check the network. |

## العربية

**الغرض:** اختيار كلمة مرور جديدة إذا نسيتها، برمز يصل إلى بريدك (redix-api #127).
**من يراها:** كل من لم يسجّل الدخول، من **نسيت كلمة المرور؟** في شاشة [تسجيل الدخول](sign-in.md). ومسؤول النظام كذلك.

1. اكتب اسم المستخدم أو بريدك، واضغط **أرسل الرمز**.
2. تقول الشاشة: **إن كان للحساب بريد، أرسلنا إليه رمزًا صالحًا 15 دقيقة.** وتقول ذلك نفسه لأي اسم مستخدم، فلا يعرف أحد من له حساب. ويصل البريد بلغة التطبيق.
3. اكتب أرقام الرمز الستة، ثم كلمة المرور الجديدة مرتين، واضغط **تغيير كلمة المرور**.
4. تعود إلى تسجيل الدخول: ادخل بكلمة المرور الجديدة. ويُسجَّل خروجك من كل جوال كنت مسجّلاً فيه، وينتهي قفل المحاولات الخاطئة.

يعمل الرمز مرة واحدة، 15 دقيقة و5 محاولات. و**أرسل الرمز** مرة أخرى يرسل رمزًا جديدًا ويوقف السابق. ولا يصل بريد إن لم يكن لحسابك بريد بعد: يكتبه مدير مشروعك في [المستخدمون](users.md)، أو تضعه أنت في [الإعدادات](settings.md).

| الرسالة | معناها |
| --- | --- |
| الرمز غير صحيح أو انتهت صلاحيته. | تحقق من الأرقام الستة، أو أرسل رمزًا جديدًا. |
| استخدم 8 أحرف على الأقل فيها حرف ورقم، وليست اسم المستخدم. | اختر كلمة أقوى؛ ويبقى الرمز صالحًا. |
| كلمتا المرور الجديدتان غير متطابقتين. | اكتب كلمة المرور الجديدة نفسها مرتين. |
| طلبات كثيرة. حاول بعد قليل. | انتظر قليلاً قبل أن تطلب مرة أخرى. |
| لا يوجد اتصال بالخادم. حاول مرة أخرى. | لا يصل الجوال إلى REDIX؛ تحقق من الشبكة. |
