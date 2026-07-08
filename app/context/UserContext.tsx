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

      try {
        setLoading(true);

        if (!sessionUser) {
          setUser(null);
          setProfile(null);
          setRole(null);
          return;
        }

        setUser(sessionUser);

        const { data, error } = await supabase
          .from("profiles")
          .select("*")
          .eq("id", sessionUser.id)
          .maybeSingle();

        if (error) {
          console.error("Error cargando profile:", error);
        }

        if (!mounted) return;

        setProfile(data ?? null);
        setRole(data?.role ?? null);
      } catch (err) {
        console.error("UserContext:", err);

        if (!mounted) return;

        setProfile(null);
        setRole(null);
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    };

    const init = async () => {
      try {
        const {
          data: { session },
          error,
        } = await supabase.auth.getSession();

        if (error) {
          console.error("Error obteniendo sesión:", error);
        }

        await loadUser(session?.user ?? null);
      } catch (err) {
        console.error("Error inicializando sesión:", err);

        if (mounted) {
          setLoading(false);
        }
      }
    };

    init();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      console.log("AUTH:", event);

      loadUser(session?.user ?? null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
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