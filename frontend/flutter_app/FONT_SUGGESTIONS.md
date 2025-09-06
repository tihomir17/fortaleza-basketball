# Font Suggestions for Game Analytics Screen

## 🎯 **Recommended Fonts for Basketball Analytics**

### **1. Poppins** (Highly Recommended)
- **Style**: Modern, geometric sans-serif
- **Best for**: Headers, titles, and key statistics
- **Why**: Clean, professional, excellent readability, modern feel
- **Usage**: Main titles, section headers, key metrics
- **Google Fonts**: `https://fonts.google.com/specimen/Poppins`

### **2. Inter** (Excellent Choice)
- **Style**: Humanist sans-serif designed for screens
- **Best for**: Body text, labels, and general content
- **Why**: Optimized for digital displays, excellent legibility
- **Usage**: Body text, filter labels, descriptions
- **Google Fonts**: `https://fonts.google.com/specimen/Inter`

### **3. Roboto** (Safe Choice)
- **Style**: Geometric sans-serif
- **Best for**: General purpose, good all-rounder
- **Why**: Google's default, widely supported, clean
- **Usage**: General text, buttons, form elements
- **Google Fonts**: `https://fonts.google.com/specimen/Roboto`

### **4. SF Pro Display** (Apple Style)
- **Style**: Humanist sans-serif
- **Best for**: iOS-style interfaces
- **Why**: Apple's system font, elegant and modern
- **Usage**: Headers, titles, premium feel
- **Note**: Requires licensing for commercial use

### **5. Montserrat** (Modern Alternative)
- **Style**: Geometric sans-serif
- **Best for**: Headers and titles
- **Why**: Modern, clean, good for sports/analytics
- **Usage**: Section headers, main titles
- **Google Fonts**: `https://fonts.google.com/specimen/Montserrat`

## 🎨 **Font Combination Recommendations**

### **Option 1: Poppins + Inter** (Recommended)
```dart
// Headers and Titles
fontFamily: 'Poppins',
fontWeight: FontWeight.w700,

// Body Text and Labels
fontFamily: 'Inter',
fontWeight: FontWeight.w500,
```

### **Option 2: Montserrat + Roboto**
```dart
// Headers and Titles
fontFamily: 'Montserrat',
fontWeight: FontWeight.w700,

// Body Text and Labels
fontFamily: 'Roboto',
fontWeight: FontWeight.w500,
```

### **Option 3: Inter + Inter** (Minimalist)
```dart
// All Text
fontFamily: 'Inter',
// Use different weights for hierarchy
fontWeight: FontWeight.w700, // Headers
fontWeight: FontWeight.w500, // Body
fontWeight: FontWeight.w400, // Labels
```

## 📱 **Implementation Steps**

### **1. Add Google Fonts to pubspec.yaml**
```yaml
dependencies:
  google_fonts: ^6.1.0
```

### **2. Import in your file**
```dart
import 'package:google_fonts/google_fonts.dart';
```

### **3. Apply fonts in the analytics screen**
```dart
// Example usage in the enhanced analytics screen
Text(
  'Game Analytics',
  style: GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  ),
),

// For body text
Text(
  'Analytics Filters',
  style: GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  ),
),
```

## 🎯 **My Recommendation**

I recommend **Poppins + Inter** combination:
- **Poppins** for headers, titles, and key statistics (modern, geometric)
- **Inter** for body text, labels, and descriptions (optimized for screens)

This combination provides:
- ✅ Excellent readability
- ✅ Modern, professional appearance
- ✅ Good hierarchy between different text elements
- ✅ Free and widely supported
- ✅ Perfect for sports analytics

## 🔧 **Quick Implementation**

To implement this in your current analytics screen, replace the font comments with:

```dart
// Replace this:
// Font suggestions: 'Poppins', 'Inter', 'Roboto'

// With this:
style: GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: theme.colorScheme.onSurface,
),
```

Would you like me to implement one of these font combinations in the analytics screen?
