function internalEmailFromPhone(phone) {
  const digits = String(phone || "").replace(/\D/g, "");
  if (!digits) throw new Error("رقم الهاتف غير صحيح");
  return `phone_${digits}@zoma.local`;
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
