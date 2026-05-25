# AquaSertão Frontend (Flutter)

This is the mobile and web frontend for the AquaSertão Farm Management System.

## 🚀 How to Run the App

Due to a known limitation with the Ubuntu Flutter snap environment (missing `ld.lld`), compiling for the Linux Desktop natively may fail. To have a perfectly reliable and fast development experience, we run the app as a **local web server**.

### Option 1: Use the Startup Script (Recommended)
Simply run the included bash script from this directory:
```bash
./start_frontend.sh
```

### Option 2: Manual Command
If you prefer, you can run the command manually:
```bash
flutter run -d web-server --web-port 8082
```

## 📱 How to Simulate a Cellphone Screen

Since we are running in the browser, you can easily simulate a pixel-perfect smartphone:
1. Open **http://localhost:8082** in Google Chrome or Microsoft Edge.
2. Press **`F12`** to open Developer Tools.
3. Press **`Ctrl + Shift + M`** (or click the Device Toolbar icon).
4. Select your preferred device (e.g., iPhone 14 Pro, Pixel 7) from the top dropdown.

## 🏗️ Architecture Stack
- **Networking:** `dio`
- **State Management:** `flutter_riverpod`
- **Routing:** `go_router`
- **Storage:** `flutter_secure_storage`
