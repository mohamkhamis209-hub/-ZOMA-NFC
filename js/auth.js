function normalizeLoginPhone(phone) {
  return String(phone || "")
    .replace(/[٠-٩]/g, d => String("٠١٢٣٤٥٦٧٨٩".indexOf(d)))
    .replace(/[۰-۹]/g, d => String("۰۱۲۳۴۵۶۷۸۹".indexOf(d)))
    .replace(/\D/g, "");
}

function internalEmailFromPhone(phone) {
  const digits = normalizeLoginPhone(phone);
  if (digits.length < 8 || digits.length > 15) {
    throw new Error("رقم الهاتف غير صحيح");
  }
  return `phone_${digits}@zoma.local`;
}

function authErrorMessage(error) {
  const status = Number(error?.status || 0);
  const code = String(error?.code || error?.name || "").toLowerCase();
  const raw = String(error?.message || error || "");
  const msg = raw.toLowerCase();

  if (status === 429 || msg.includes("rate limit") || msg.includes("too many")) {
    return "تم تجاوز عدد محاولات إنشاء الحساب مؤقتًا. انتظر عدة دقائق ثم حاول مرة واحدة فقط.";
  }
  if (status === 400 && (msg.includes("user already registered") || code.includes("already_registered"))) {
    return "رقم الهاتف مسجل بالفعل. استخدم تسجيل الدخول بدلًا من إنشاء حساب جديد.";
  }
  if (msg.includes("signup") && msg.includes("disabled")) {
    return "التسجيل متوقف من إعدادات Supabase. فعّل السماح بتسجيل مستخدمين جدد من Authentication → Settings.";
  }
  if (msg.includes("email") && (msg.includes("invalid") || msg.includes("valid"))) {
    return "تعذر قبول بريد الدخول الداخلي. تأكد من إعدادات Email Provider في Supabase.";
  }
  if (msg.includes("password") && (msg.includes("weak") || msg.includes("least") || msg.includes("short"))) {
    return "كلمة المرور غير مطابقة لسياسة Supabase. استخدم كلمة مرور أقوى.";
  }
  if (status === 400) {
    return `تعذر إنشاء الحساب. Supabase أعاد: ${raw || "طلب غير صالح"}`;
  }
  return raw || "تعذر تنفيذ العملية. حاول مرة أخرى.";
}

async function loginWithIdentifier(identifier, password) {
  const value = String(identifier || "").trim();
  let email = value;

  if (!value.includes("@")) {
    const { data, error } = await db.rpc("resolve_login_identifier", { identifier: value });
    if (error || !data) throw new Error("بيانات الدخول غير صحيحة");
    email = data;
  }

  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

window.authErrorMessage = authErrorMessage;
window.normalizeLoginPhone = normalizeLoginPhone;
window.internalEmailFromPhone = internalEmailFromPhone;
window.loginWithIdentifier = loginWithIdentifier;
