"use client";

import { useEffect, useState } from "react";
import { User } from "@supabase/supabase-js";
import { createClient, isSupabaseConfigured } from "@/lib/supabase";

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const configured = isSupabaseConfigured();

  useEffect(() => {
    if (!configured) {
      setLoading(false);
      return;
    }

    const supabase = createClient();

    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, [configured]);

  const signInWithGoogle = async () => {
    if (!configured) return;
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
  };

  /** Sign in with email/password — returns error message string or null */
  const signInWithEmail = async (
    email: string,
    password: string
  ): Promise<string | null> => {
    if (!configured) return null;
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      if (error.message.includes("Invalid login credentials")) {
        return "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
      }
      if (error.message.includes("Email not confirmed")) {
        return "กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ";
      }
      return error.message;
    }
    return null;
  };

  /** Sign up with email/password — returns error message string or null */
  const signUpWithEmail = async (
    email: string,
    password: string,
    name?: string
  ): Promise<string | null> => {
    if (!configured) return null;
    const supabase = createClient();
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: name || "" },
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });
    if (error) {
      if (error.message.includes("already registered")) {
        return "อีเมลนี้ถูกใช้งานแล้ว กรุณาเข้าสู่ระบบ";
      }
      return error.message;
    }
    return null;
  };

  /**
   * Verify OTP code sent to email after signUp.
   * type = "signup" for email confirmation OTP
   * Returns error message or null on success.
   */
  const verifyOTP = async (
    email: string,
    token: string
  ): Promise<string | null> => {
    if (!configured) return null;
    const supabase = createClient();
    const { error } = await supabase.auth.verifyOtp({
      email,
      token,
      type: "signup",
    });
    if (error) {
      if (error.message.includes("Token has expired") || error.message.includes("invalid")) {
        return "รหัสไม่ถูกต้องหรือหมดอายุแล้ว กรุณาลองใหม่";
      }
      return error.message;
    }
    return null;
  };

  /** Update display name — returns error message or null */
  const updateDisplayName = async (name: string): Promise<string | null> => {
    if (!configured) return null;
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({
      data: { full_name: name.trim() },
    });
    if (error) return error.message;
    return null;
  };

  /** Update password — returns error message or null */
  const updatePassword = async (newPassword: string): Promise<string | null> => {
    if (!configured) return null;
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) return error.message;
    return null;
  };

  const signOut = async () => {
    if (!configured) return;
    const supabase = createClient();
    await supabase.auth.signOut();
  };

  return {
    user,
    loading,
    signInWithGoogle,
    signInWithEmail,
    signUpWithEmail,
    verifyOTP,
    updateDisplayName,
    updatePassword,
    signOut,
    configured,
  };
}
