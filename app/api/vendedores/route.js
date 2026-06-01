import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

export async function GET() {
  try {
    const { data, error } = await supabase
      .from("profiles")
      .select("id, full_name")
      .eq("role", "vendedor");

    if (error) {
      console.error(error);
      return Response.json([]);
    }

    const vendedores = data.map(v => ({
      codigo_vendedor: v.id,
      nombre_vendedor: v.full_name?.trim()
    }));

    return Response.json(vendedores);

  } catch (err) {
    console.error(err);
    return Response.json([]);
  }
}