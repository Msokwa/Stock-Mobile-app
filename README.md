# 📈 StockScope

StockScope is a Flutter-based mobile stock market application that allows users to monitor live stock prices, analyze historical performance, stay informed with financial news, and manage a personal investment portfolio. The application integrates live market data using the Finnhub API and provides a clean, modern user interface designed in Figma.

---

## 📱 Features

### 🔐 User Authentication
- Email registration and login
- Secure authentication using Supabase


### 📊 Live Stock Market
- Live stock prices
- Daily price changes
- Percentage gain/loss
- Company information

### 📈 Interactive Charts
- Historical stock data
- Interactive line charts
- Multiple time periods
  - 1 Day
  - 1 Week
  - 1 Month
  - 1 Year

### 🔍 Search Stocks
- Search by company name
- Search by ticker symbol
- View company details

### 📰 Financial News
- Latest company news
- Stock market updates
- News images
- News source and publication date

### ⭐ Watchlist
- Save favorite stocks
- Remove stocks
- Local storage using SQLite

### 💼 Portfolio
- Track investments
- Add owned stocks
- Profit/Loss calculation
- Portfolio summary

### 🌍 Geolocation
- Detect user's country
- Display local market
- Country market selection

---

# 🛠 Technologies Used

## Frontend
- Flutter
- Dart

## Backend
- Supabase

## APIs
- Finnhub Stock API

## Local Storage
- SQLite

## Authentication
- Supabase Authentication

## Charts
- Syncfusion Flutter Charts

## HTTP Requests
- http package

## Environment Variables
- flutter_dotenv

## State Management
- Stateful Widgets

---

# 📱 Screens

- Splash Screen
- Onboarding
- Login
- Register
- Home
- Stock Details
- News
- Portfolio
- Watchlist
- Notifications
- Settings
- Profile

---

# 📊 APIs Used

## Finnhub

Used for:

- Live Stock Prices
- Company Profiles
- Historical Stock Prices
- Company News
- Stock Search

Documentation:

https://finnhub.io/docs/api

---

# 🗄 Database

SQLite stores:

- Watchlist
- Portfolio
- User Preferences

Supabase stores:

- User Authentication
- User Accounts

---

# 🚀 Getting Started





## Navigate to Project

```bash
cd StockScope
```

## Install Packages

```bash
flutter pub get
```

## Create Environment File

Create a `.env` file in the project root.

```env
FINNHUB_API_KEY=YOUR_API_KEY
```

## Run Application

```bash
flutter run
```

---

