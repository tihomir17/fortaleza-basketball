# Local Mobile Testing Guide

## 🚀 Quick Start

The Flutter app is now running locally at: **http://localhost:8080**

## 📱 Testing Mobile Behavior

### Method 1: Chrome Mobile Device Simulation (Recommended)

1. **Open Chrome** and go to `http://localhost:8080`
2. **Open Developer Tools** (F12 or Cmd+Option+I)
3. **Click the Device Toggle** (📱 icon) or press Cmd+Shift+M
4. **Select a Mobile Device** from the dropdown:
   - iPhone 12 Pro (390x844)
   - iPhone 12 Pro Max (428x926)
   - Pixel 5 (393x851)
   - Or create custom dimensions

### Method 2: Test Specific Scenarios

#### Test Mobile Portrait Mode
- Device: iPhone 12 Pro (390x844)
- **Expected**: No window size warnings, menu button works

#### Test Mobile Landscape Mode
- Device: iPhone 12 Pro (844x390) - rotate to landscape
- **Expected**: No window size warnings, menu button works

#### Test Edge Cases
- Custom device: 320x480 (very small)
- Custom device: 1024x473 (your reported issue)
- **Expected**: No warnings, menu button works

## 🔍 What to Test

### 1. **Window Size Warnings**
- ✅ Should NOT appear on mobile devices
- ✅ Should appear on desktop if window < 1024x600px

### 2. **Menu Button Functionality**
- ✅ Click the menu button (hamburger icon) in the top-left
- ✅ Should open the coach menu drawer from the left
- ✅ Should work in both portrait and landscape

### 3. **Touch Targets**
- ✅ Menu button should be at least 44px (good for touch)
- ✅ Should have visual feedback when tapped

### 4. **Responsive Behavior**
- ✅ Layout should adapt to different screen sizes
- ✅ No horizontal scrolling issues

## 🐛 Debugging Tips

### Check Console Logs
1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Look for logs starting with:
   - `SidebarToggleButton: Screen width: X, isMobile: true/false`
   - `SidebarToggleButton: Opened drawer on mobile device`
   - `SidebarToggleButton: Failed to open drawer: [error]`

### Test Different Screen Sizes
```javascript
// In Chrome Console, you can test different sizes:
// Test your reported issue (1024x473)
window.resizeTo(1024, 473);

// Test mobile portrait
window.resizeTo(390, 844);

// Test mobile landscape
window.resizeTo(844, 390);
```

## 🔧 If Menu Button Doesn't Work

### Check These Issues:

1. **Screen Width Detection**
   - Look for: `Screen width: X, isMobile: true/false`
   - Should be `isMobile: true` for screens ≤ 768px

2. **Scaffold Detection**
   - Look for: `No Scaffold found with drawer`
   - This means the button can't find the drawer

3. **Error Messages**
   - Look for: `Failed to open drawer: [error]`
   - This will show the specific error

### Quick Fixes to Try:

1. **Refresh the page** after changing device simulation
2. **Check if you're logged in** (some screens might not have the menu)
3. **Try different screens** (Dashboard, Games, etc.)

## 📊 Expected Results

| Screen Size | Device Type | Window Warning | Menu Button |
|-------------|-------------|----------------|-------------|
| 390x844 | Mobile Portrait | ❌ No | ✅ Works |
| 844x390 | Mobile Landscape | ❌ No | ✅ Works |
| 1024x473 | Mobile Landscape | ❌ No | ✅ Works |
| 1024x600 | Desktop | ❌ No | ✅ Works |
| 800x600 | Desktop | ✅ Yes | ✅ Works |

## 🚀 Alternative: Real Mobile Device

If you want to test on a real mobile device:

### Option 1: Connect via USB
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB cable
4. Run: `flutter devices` to see your device
5. Run: `flutter run -d [device-id]`

### Option 2: Network Testing
1. Find your computer's IP address: `ifconfig | grep inet`
2. On your mobile device, go to: `http://[YOUR_IP]:8080`
3. Make sure both devices are on the same WiFi network

## 🎯 Success Criteria

✅ **Mobile Portrait**: No warnings, menu opens drawer
✅ **Mobile Landscape**: No warnings, menu opens drawer  
✅ **Desktop**: Warnings for small windows, sidebar toggles
✅ **Touch Targets**: 44px minimum, good visual feedback
✅ **Responsive**: Layout adapts properly

## 📝 Report Issues

If you find issues, please report:
1. **Screen size** you're testing
2. **Device simulation** used
3. **Console error messages**
4. **Expected vs actual behavior**

The app is now running at **http://localhost:8080** - start testing! 🎉
