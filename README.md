# Nexora 💬

A modern, real-time chat application built with **Flutter** on the frontend and **Node.js / Express / Socket.io / Prisma** on the backend. 

Designed with a sleek dark-mode aesthetic, smooth glassmorphism, and instant messaging interactions.

🌐 **Live Backend API**: [https://nexora-mtwu.onrender.com](https://nexora-mtwu.onrender.com) (Deployed on Render)

---

## ✨ Features

- **⚡ Real-time Messaging**: Instant message delivery using WebSockets (`Socket.io`).
- **🎙️ Voice Notes & Audio Messages**: Live voice recording with animated soundwaves and in-bubble playback player.
- **📸 Photo & Media Uploads**: Camera and gallery image attachments with zoomable interactive full-screen viewer.
- **📍 Location Sharing**: Interactive pinpoint map cards with direct coordinates and location markers.
- **🖥️ Split-Screen Desktop / Web**: WhatsApp Web-style dual-pane interface with responsive navigation on wider screens.
- **🖼️ Chat Info & Shared Media Gallery**: Member rosters, Admin badges, and filterable tabs for all shared photos and voice notes.
- **🔄 Swipe-to-Reply**: Swipe right on any message bubble to quote and reply with context.
- **❤️ Emoji Reactions**: Long-press any message to react with animated emojis (`❤️`, `👍`, `😂`, `🔥`, `😮`, `👏`).
- **✓✓ Read Receipts & Ticks**: Real-time status indicators for Sent (`✓`), Delivered (`✓✓`), and Read (`✓✓`).
- **📧 Connect by Email ID**: Search and start conversations with users by their email address, username, or name.
- **✍️ Live Typing Indicators**: Real-time feedback when other participants are typing.
- **👥 Direct & Group Chats**: Support for 1-on-1 conversations and team group chats.
- **🐘 PostgreSQL & SQLite Dual-Mode**: Seamlessly switch between local development and Cloud PostgreSQL (Neon / Supabase / Render Postgres).

---

## 🛠️ Tech Stack

### Mobile (Flutter)
- **Framework**: Flutter (Dart)
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter
- **Networking**: Dio
- **Realtime**: Socket.io Client
- **Secure Storage**: Flutter Secure Storage

### Backend
- **Runtime**: Node.js & TypeScript
- **Server**: Express
- **WebSockets**: Socket.io
- **ORM / Database**: Prisma with SQLite (easily switched to PostgreSQL)
- **Authentication**: JWT (JSON Web Tokens) & bcrypt password hashing

---

## 📁 Project Structure

```
Nexora/
├── backend/
│   ├── prisma/            # Prisma schema and seed data
│   ├── src/
│   │   ├── controllers/   # Express route controllers
│   │   ├── middleware/    # Auth and error middleware
│   │   ├── routes/        # API route definitions
│   │   ├── services/      # Business logic & database operations
│   │   ├── app.ts         # Express app configuration
│   │   └── server.ts      # HTTP server & Socket.io handlers
│   └── package.json
│
└── mobile/
    ├── lib/
    │   ├── core/          # Theme, router, network clients, socket service
    │   ├── features/
    │   │   ├── auth/      # Login, registration, auth provider
    │   │   ├── chat/      # Chat screen, messages provider, models
    │   │   ├── home/      # Home conversation list & user search
    │   │   └── profile/   # Profile view & settings
    │   └── main.dart
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x+)
- [Node.js](https://nodejs.org/) (v18+)
- npm or yarn

---

### 1. Setup Backend

```bash
cd backend

# Install dependencies
npm install

# Setup database & run migrations
npx prisma migrate dev

# Seed database with sample users & chats
npm run seed

# Start development server (runs on port 3001)
npm run dev
```

---

### 2. Setup Mobile App

```bash
cd mobile

# Get Flutter packages
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Or run on Android / iOS
flutter run
```

> **Note for Android Emulators**: If testing on an Android emulator, update the API base URL in `lib/core/network/dio_client.dart` from `127.0.0.1:3001` to `10.0.2.2:3001`.

---

## 🧪 Demo Accounts

The database seed includes 5 ready-to-use test accounts:

| Email | Password | Name |
|---|---|---|
| `alice@nexora.app` | `password123` | Alice Johnson |
| `bob@nexora.app` | `password123` | Bob Smith |
| `carol@nexora.app` | `password123` | Carol White |
| `dave@nexora.app` | `password123` | Dave Lee |
| `eve@nexora.app` | `password123` | Eve Martinez |

You can also register a new account on the **Sign Up** screen anytime.

---

## 📄 License

This project is licensed under the MIT License.
