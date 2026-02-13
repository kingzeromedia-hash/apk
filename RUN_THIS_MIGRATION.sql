-- 1. Create the user_role type if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('super_admin', 'school_admin');
    END IF;
END $$;

-- 2. Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'school_admin',
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create essential policies for profiles if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Public profiles are viewable by everyone') THEN
        CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
    END IF;
END $$;

-- 5. Enable pgcrypto for password hashing
create extension if not exists "pgcrypto";

-- 6. Update the super admin credentials for zamresults@gmail.com
-- Sets password to 'benjaminking'
-- Sets phone to '+260979888349' (formatted from 0979888349)
UPDATE auth.users
SET 
  encrypted_password = crypt('benjaminking', gen_salt('bf')),
  phone = '+260979888349',
  phone_confirmed_at = now(),
  email_confirmed_at = now(),
  updated_at = now(),
  raw_app_meta_data = raw_app_meta_data || '{"provider": "email", "providers": ["email", "phone"]}'::jsonb
WHERE email = 'zamresults@gmail.com';

-- 7. Ensure the user exists in profiles with super_admin role
INSERT INTO public.profiles (id, role, full_name)
SELECT id, 'super_admin'::user_role, 'Super Admin'
FROM auth.users
WHERE email = 'zamresults@gmail.com'
ON CONFLICT (id) DO UPDATE 
SET role = 'super_admin';
