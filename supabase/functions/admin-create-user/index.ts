import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return jsonResponse({ error: "Bạn chưa đăng nhập." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  const authClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  try {
    const token = authorization.replace("Bearer ", "");
    const {
      data: { user: caller },
      error: callerError,
    } = await authClient.auth.getUser(token);

    if (callerError || !caller) {
      return jsonResponse({ error: "Phiên đăng nhập không hợp lệ." }, 401);
    }

    const { data: callerProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("role, is_active")
      .eq("id", caller.id)
      .single();

    if (
      profileError ||
      callerProfile?.role !== "admin" ||
      callerProfile?.is_active !== true
    ) {
      return jsonResponse({ error: "Bạn không có quyền thêm nhân viên." }, 403);
    }

    const body = await req.json();
    const email = String(body.email ?? "").trim().toLowerCase();
    const password = String(body.password ?? "");
    const name = String(body.name ?? "").trim();
    const phone = String(body.phone ?? "").trim() || null;
    const avatarUrl = String(body.avatar_url ?? "").trim() || null;
    const role = body.is_admin === true ? "admin" : "employee";

    if (!email || !email.includes("@")) {
      return jsonResponse({ error: "Email không hợp lệ." }, 400);
    }
    if (password.length < 6) {
      return jsonResponse({ error: "Mật khẩu phải có ít nhất 6 ký tự." }, 400);
    }
    if (!name) {
      return jsonResponse({ error: "Tên nhân viên là bắt buộc." }, 400);
    }

    const { data: created, error: createError } =
      await adminClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (createError || !created.user) {
      return jsonResponse(
        { error: createError?.message ?? "Không thể tạo tài khoản." },
        400,
      );
    }

    const { error: insertError } = await adminClient.from("profiles").insert({
      id: created.user.id,
      email,
      name,
      phone,
      avatar_url: avatarUrl,
      role,
      is_active: true,
    });

    if (insertError) {
      await adminClient.auth.admin.deleteUser(created.user.id);
      return jsonResponse({ error: insertError.message }, 400);
    }

    return jsonResponse({ id: created.user.id }, 201);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : "Có lỗi xảy ra." },
      400,
    );
  }
});
