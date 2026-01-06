# 학생 관리 시스템 (Flutter + Supabase)

이 프로젝트는 **Flutter** (프론트엔드)와 **Supabase** (백엔드 - Auth, Database, Edge Functions)를 사용하여 구축된 학생 관리 애플리케이션입니다.

## 주요 기능
- **관리자 (선생님)**:
    - 학생 관리 (목록 조회, 등록, 정보 수정, 삭제)
    - 대시보드 통계 확인 (출석률, 미확인 메시지 건수 등)
    - 학생과 1:1 실시간 상담 채팅
    - 출석 관리 및 체크
- **학생**:
    - 나의 출석 기록 조회
    - 선생님(관리자)과 1:1 실시간 상담 채팅
    - 내 프로필 조회

## 필수 조건
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치
- [Supabase 계정](https://supabase.com/) 생성

## 설치 및 설정 가이드

### 1. Supabase 프로젝트 설정
1. Supabase 대시보드에서 새 프로젝트를 생성합니다.
2. 좌측 메뉴의 `SQL Editor`로 이동하여 아래의 SQL 쿼리를 실행하여 테이블과 보안 정책(RLS)을 설정합니다.

#### 데이터베이스 스키마 및 권한 정책 (RLS) SQL
아래 스크립트를 복사하여 실행하세요.

```sql
-- Users (사용자) 테이블
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

-- RLS (Row Level Security) 활성화
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 정책 (Policies)
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "Anyone can view admins" ON public.users FOR SELECT TO authenticated USING (role = 'admin');
CREATE POLICY "Admins can insert users" ON public.users FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update users" ON public.users FOR UPDATE USING (is_admin());

-- 관리자 확인 함수 (보안 정의)
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

-- Attendance (출석) 테이블
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

-- 출석 관련 정책
CREATE POLICY "Students can view own attendance" ON public.attendance FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Students can insert own attendance" ON public.attendance FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Admins can manage all attendance" ON public.attendance FOR ALL USING (is_admin());

-- Chat Rooms (상담 채팅방) 테이블
CREATE TABLE public.chat_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.users(id) NOT NULL,
    admin_id UUID REFERENCES public.users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

-- 채팅방 정책
CREATE POLICY "Participants can view rooms" ON public.chat_rooms FOR SELECT USING (auth.uid() = admin_id OR auth.uid() = student_id);
CREATE POLICY "Participants can manage rooms" ON public.chat_rooms FOR ALL USING (auth.uid() = admin_id OR auth.uid() = student_id);

-- Messages (메시지) 테이블
CREATE TABLE public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID REFERENCES public.chat_rooms(id) NOT NULL,
    sender_id UUID REFERENCES public.users(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 메시지 정책
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_rooms WHERE id = messages.room_id AND (admin_id = auth.uid() OR student_id = auth.uid()))
);
CREATE POLICY "Participants can insert messages" ON public.messages FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.chat_rooms WHERE id = messages.room_id AND (admin_id = auth.uid() OR student_id = auth.uid()))
);
```

#### Edge Functions (서버리스 함수)
이 프로젝트는 관리자가 앱 내에서 새 학생 계정을 생성할 때 클라이언트의 제약을 우회하고 안전하게 처리하기 위해 Supabase Edge Function (`create-student`)을 사용합니다.

1. 로컬 컴퓨터에 Supabase CLI를 설치합니다.
2. CLI 로그인: `supabase login`
3. 함수 배포 (`supabase/functions/create-student` 폴더 기준):
   ```bash
   supabase functions deploy create-student --no-verify-jwt
   ```
   *참고: 더 나은 에러 핸들링과 수동 검증을 위해 `verify_jwt` 옵션을 끄고 배포합니다.*

### 2. Flutter 앱 설정
1. `student_app/lib/core/config/supabase_config.dart` 파일을 편집기로 엽니다.
2. 본인의 Supabase 프로젝트 URL과 Anon Key로 값을 변경합니다.

```dart
class SupabaseConfig {
  static const String url = '여기에_SUPABASE_URL_입력';
  static const String anonKey = '여기에_SUPABASE_ANON_KEY_입력';
}
```

### 3. 앱 실행 방법
터미널에서 `student_app` 폴더로 이동한 후 다음 명령어를 실행합니다.

```bash
cd student_app
flutter pub get
flutter run
```

## 폴더 구조 설명
- `student_app/lib`: Flutter 애플리케이션 소스 코드
  - `core`: 앱 전반의 설정 및 유틸리티 (Config, Logger 등)
  - `features`: 기능별 모듈 (Auth-인증, Admin-관리자, Student-학생)
  - `shared`: 공용 위젯 및 데이터 모델
- `supabase`: Supabase 설정 및 Edge Functions 소스

## 라이선스
MIT
