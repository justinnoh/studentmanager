# Student Management System (Flutter + Supabase)

This is a student management application built with **Flutter** for the frontend and **Supabase** for the backend (Auth, Database, Edge Functions).

## Features
- **Admin**:
    - Manage students (List, Create, Update, Delete)
    - View dashboard statistics (Attendance rate, Message count)
    - 1:1 Chat with students
    - Manage attendance
- **Student**:
    - View attendance history
    - 1:1 Chat with teachers (Admins)
    - View profile

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Supabase Account](https://supabase.com/)

## Setup

### 1. Supabase Project Setup
1. Create a new Supabase project.
2. Run the following SQL queries in the Supabase SQL Editor to set up tables and policies.

#### Database Schema & Policies
```sql
-- Users Table
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'student')) DEFAULT 'student',
    phone TEXT,
    parent_name TEXT,
    parent_phone TEXT,
    age INTEGER,
    gender TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policies for Users
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "Anyone can view admins" ON public.users FOR SELECT TO authenticated USING (role = 'admin');
CREATE POLICY "Admins can insert users" ON public.users FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update users" ON public.users FOR UPDATE USING (is_admin());

-- Is Admin Function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attendance Table
CREATE TABLE public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.users(id) NOT NULL,
    check_date DATE NOT NULL,
    status TEXT CHECK (status IN ('present', 'absent', 'late')) DEFAULT 'present',
    check_time TIME WITHOUT TIME ZONE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Policies for Attendance
CREATE POLICY "Students can view own attendance" ON public.attendance FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Students can insert own attendance" ON public.attendance FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Admins can manage all attendance" ON public.attendance FOR ALL USING (is_admin());

-- Chat Rooms Table
CREATE TABLE public.chat_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.users(id) NOT NULL,
    admin_id UUID REFERENCES public.users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

-- Policies for Chat Rooms
CREATE POLICY "Participants can view rooms" ON public.chat_rooms FOR SELECT USING (auth.uid() = admin_id OR auth.uid() = student_id);
CREATE POLICY "Participants can manage rooms" ON public.chat_rooms FOR ALL USING (auth.uid() = admin_id OR auth.uid() = student_id);

-- Messages Table
CREATE TABLE public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID REFERENCES public.chat_rooms(id) NOT NULL,
    sender_id UUID REFERENCES public.users(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Policies for Messages
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_rooms WHERE id = messages.room_id AND (admin_id = auth.uid() OR student_id = auth.uid()))
);
CREATE POLICY "Participants can insert messages" ON public.messages FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.chat_rooms WHERE id = messages.room_id AND (admin_id = auth.uid() OR student_id = auth.uid()))
);
```

#### Edge Functions
This project uses a Supabase Edge Function `create-student` to handle secure user creation (bypassing client-side restrictions).

1. Install Supabase CLI.
2. Login to Supabase CLI: `supabase login`
3. Deploy the function (located in `supabase/functions/create-student`):
   ```bash
   supabase functions deploy create-student --no-verify-jwt
   ```
   *Note: `verify_jwt` is set to false to allow manual verification and better error handling.*

### 2. Flutter App Configuration
1. Navigate to `student_app/lib/core/config/supabase_config.dart`.
2. Update the `url` and `anonKey` with your own Supabase project credentials.

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 3. Run the App
```bash
cd student_app
flutter pub get
flutter run
```

## Folder Structure
- `student_app/lib`: Flutter application source code.
  - `core`: Core configurations and utilities.
  - `features`: Feature-based modules (Auth, Admin, Student).
  - `shared`: Shared widgets and models.
- `supabase`: Supabase Edge Functions.

## License
MIT
