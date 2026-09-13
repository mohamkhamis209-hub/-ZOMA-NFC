const { createClient } = supabase;
const db = createClient(ZOMA_CONFIG.SUPABASE_URL, ZOMA_CONFIG.SUPABASE_KEY);
window.zoma = { db };

async function currentUser() {
  const { data } = await db.auth.getUser();
  return data?.user || null;
}

async function requireAuth(redirect = "login.html") {
  const u = await currentUser();
  if (!u) location.href = redirect;
  return u;
}

async function requireAdmin(redirect = "../dashboard.html") {
  const u = await requireAuth(redirect);
  if (!u) return null;
  const { data, error } = await db
    .from("admins")
    .select("id,role,display_name,is_active")
    .eq("user_id", u.id)
    .eq("is_active", true)
    .single();
  if (error || !data) {
    location.href = redirect;
    return null;
  }
  return data;
}

async function hasPermission(module, action) {
  const { data, error } = await db.rpc("has_admin_permission", {
    requested_module: module,
    requested_action: action
  });
  if (error) return false;
  return !!data;
}

async function signOut() {
  await db.auth.signOut();
  location.href = "index.html";
}

function esc(v = "") {
  return String(v).replace(/[&<>"']/g, m => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;"
  }[m]));
}

function money(v) {
  return `${Number(v || 0).toLocaleString("ar-EG")} ج.م`;
}

function toast(msg, type = "ok") {
  const e = document.getElementById("toast");
  if (!e) return alert(msg);
  e.textContent = msg;
  e.className = `toast show ${type}`;
  setTimeout(() => e.className = "toast", 2800);
}

function siteRoot() {
  return location.pathname.includes("/admin/") ? "../" : "";
}

function cardUrl(c) {
  return `${location.origin}${siteRoot()}card.html?id=${encodeURIComponent(c.public_slug)}`;
}
