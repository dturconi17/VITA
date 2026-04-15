import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://kkxxjqdqynoudvyuqhmk.supabase.co";
const supabaseKey = "sb_publishable_XhAeJGKdm-FqYh6NBPkukw_8bv0jjwi";

export const supabase = createClient(supabaseUrl, supabaseKey);