"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
} from "react";

import { supabase } from "@/lib/supabase";

type UserContextType = {
  user: any;
  profile: any;
  role: string | null;
  loading: boolean;
};

const UserContext = createContext<UserContextType>({
  user: null,
  profile: null,
  role: null,
  loading: true,
});

export function UserProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    const loadUser = async (sessionUser?: any) => {
      if (!mounted) return;

      if (!sessionUser) {
        setUser(null);
        setProfile(null);
        setRole(null);
        setLoading(false);
        return;
      }

      setUser(sessionUser);

      const { data } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", sessionUser.id)
        .single();

      if (!mounted) return;

      setProfile(data);
      setRole(data?.role ?? null);
      setLoading(false);
    };

    // 🔥 INIT (session inicial)
    const init = async () => {
      const { data } = await supabase.auth.getSession();
      await loadUser(data.session?.user ?? null);
    };

    init();

    // 🔥 LISTENER (cambios de auth)
    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        loadUser(session?.user ?? null);
      }
    );

    return () => {
      mounted = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  return (
    <UserContext.Provider
      value={{
        user,
        profile,
        role,
        loading,
      }}
    >
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  return useContext(UserContext);
}