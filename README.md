<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
  <a href="https://github.com/Yashjain329/imgshape/stargazers"><img src="https://img.shields.io/github/stars/Yashjain329/imgshape?style=social"></a>
  <img src="https://img.shields.io/github/forks/Yashjain329/imgshape?style=social">
  <img src="https://img.shields.io/github/last-commit/Yashjain329/imgshape">
</p>


# 📸 Imgshape

`Imgshape` is a **cross-platform Flutter app** (Android, iOS, Web) that lets users **upload, analyze, and manage images** using **Supabase** for authentication + storage and a **custom backend API** for deep image analysis and insights.

---

## 🚀 Features

* 🔑 **Authentication** with Supabase (redirect-based login)
* ☁️ **Uploads** to Supabase Storage (`user-uploads` bucket)
* 🗄️ **Metadata tracking** in a secure `user_images` table (with RLS)
* 🧠 **Automatic backend integration**

    * Every upload is automatically sent to the backend for analysis
    * Results are stored in Supabase as JSON
* 📊 **Image analysis endpoints**

    * `/analyze`
    * `/recommend`
    * `/compatibility`
    * `/download_report`
* 🎨 **Modern Glassmorphism UI** (`glass_card.dart`) and custom theme (`app_theme.dart`)
* ⚡ **Optimized performance**

    * Cached images in `home_screen.dart`
    * Lightweight builds in `profile_screen.dart`
    * Smooth file uploads with async streaming
* 📱 Multiple screens: Login, Home, Upload, Analyze, Recommend, Compatibility, Download Report

---

## ⚙️ Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ **3.22**
* Active [Supabase project](https://app.supabase.com)
* Configured backend (already prefilled in `.env`)

---

## 🛠️ Setup

### 1. Clone repository

```bash
git clone https://github.com/your-org/imgshape.git
cd imgshape
```

### 2. Configure environment

Copy the example file and set values:

```bash
cp .env.example .env
```

Fill in your Supabase and backend details:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
BACKEND_URL=https://imgshape-412998139400.asia-south1.run.app
REDIRECT_URI=com.imgshape.app://login-callback/
```

> `BACKEND_URL` and `REDIRECT_URI` are prefilled.

---

### 3. Supabase setup (storage + database)

#### a) Create Storage Bucket

1. Open [Supabase Dashboard → Storage](https://app.supabase.com)
2. Click **New bucket**
3. Name: `user-uploads`
4. Set **Public = No** (private bucket using signed URLs)

#### b) Create `user_images` Table

Paste this in Supabase SQL editor:

```sql
create extension if not exists "uuid-ossp";

create table if not exists public.user_images (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) not null,
  bucket text not null default 'user-uploads',
  path text not null,
  filename text not null,
  content_type text,
  size_bytes bigint,
  width integer,
  height integer,
  metadata jsonb,
  analysis jsonb,
  recommendation jsonb,
  compatibility jsonb,
  report jsonb,
  created_at timestamptz default timezone('utc', now())
);

create index if not exists idx_user_images_user_created
  on public.user_images(user_id, created_at);
```

#### c) Enable Row Level Security (RLS)

```sql
alter table public.user_images enable row level security;

create policy "insert_own" on public.user_images
  for insert with check (auth.uid() = user_id);

create policy "select_own" on public.user_images
  for select using (auth.uid() = user_id);

create policy "update_own" on public.user_images
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "delete_own" on public.user_images
  for delete using (auth.uid() = user_id);
```

---

### 4. Redirect URI (Deep Linking)

#### Android

Add inside `<activity>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.imgshape.app" android:host="login-callback" />
</intent-filter>
```

#### iOS

Add in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.imgshape.app</string>
    </array>
  </dict>
</array>
```

> Also declare camera & photo library permissions in Info.plist.

---

## ▶️ Running the app

```bash
flutter pub get
flutter run
```

To build web:

```bash
flutter build web --release
```

Deploy `build/web` to Netlify, Vercel, or GitHub Pages.

---

## 🧩 Project structure

```
lib/
 ├── main.dart                 # Entry point
 ├── app.dart                  # Root widget + routes
 ├── app_theme.dart            # Theme (light/dark)
 ├── config.dart               # Loads .env variables
 ├── widgets/glass_card.dart   # Reusable glassmorphism component
 ├── screens/
 │   ├── login_screen.dart
 │   ├── home_screen.dart
 │   ├── upload_screen.dart
 │   ├── analyze_screen.dart
 │   ├── recommend_screen.dart
 │   ├── compatibility_screen.dart
 │   ├── download_report_screen.dart
 │   └── profile_screen.dart
 └── services/
     ├── api_service.dart      # Calls backend APIs (/analyze, /recommend, etc.)
     ├── upload_service.dart   # Uploads to Supabase + triggers backend
     └── auth_service.dart     # Handles login/logout
```

---

## 🔗 API Endpoints

The backend (`BACKEND_URL`) exposes:

* `POST /analyze`
* `POST /recommend`
* `POST /compatibility`
* `POST /download_report`

### ✅ Automated Flow

```
User selects image
   ↓
UploadService → Supabase Storage
   ↓
Insert metadata → user_images
   ↓
Generate signed URL → send to backend API
   ↓
Backend runs analysis → returns JSON
   ↓
ApiService saves results → Supabase table
   ↓
Display insights in Analyze / Recommend / Compatibility / Report screens
```

---

## ⚙️ Example config.dart

```dart
// lib/src/config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get redirectUri => dotenv.env['REDIRECT_URI'] ?? '';
  static const int maxUploadBytes = 50 * 1024 * 1024; // 50MB
}
```

Usage:

```dart
await dotenv.load(fileName: '.env');
final supabase = Supabase.initialize(
  url: Config.supabaseUrl,
  anonKey: Config.supabaseAnonKey,
);
```

---

## 🧱 Performance Optimizations

* **CachedNetworkImage** for smooth scrolling
* **Single async fetch per screen** to avoid rebuilds
* **Optimized FutureBuilders** for stable UI loading
* **Streamlined async uploads** for responsive APKs

---

## 📜 License

This project is licensed under the **MIT License**.
See the [LICENSE](LICENSE) file for full details.

---
