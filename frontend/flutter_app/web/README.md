# Web Configuration - Fortaleza Basketball Analytics

## Window Size Constraints

This web application has been configured with specific window size constraints to prevent layout issues and exceptions during window resizing.

### Minimum Dimensions
- **Width**: 1024px
- **Height**: 600px

### Maximum Dimensions
- **Width**: 1920px
- **Height**: 1080px

## Features

### 1. Automatic Size Validation
- The application automatically checks window size on load and resize
- Shows a warning overlay when the window is too small
- Prevents the app from running in undersized windows

### 2. Responsive Warning System
- Beautiful overlay with progress bars showing current vs required dimensions
- Real-time size indicators
- Clear instructions for users

### 3. Keyboard Shortcuts
- **F11**: Toggle fullscreen mode
- **Ctrl+Shift+R**: Test resize functionality (development only)

### 4. Browser Compatibility
- Works with all modern browsers
- Handles orientation changes on mobile/tablet devices
- Prevents context menu and text selection for app-like experience

## Files Modified

### `index.html`
- Added CSS constraints and responsive design
- Integrated JavaScript resize handling
- Added warning overlay styles

### `manifest.json`
- Updated app name and description
- Set orientation to "any" for flexibility
- Added proper metadata

### `resize_handler.js` (New)
- Advanced resize management class
- Debounced resize events
- Keyboard shortcuts
- Development testing tools

## Testing

To test the resize functionality:

1. **Manual Testing**:
   - Resize browser window below 1024x600
   - Verify warning overlay appears
   - Resize back to valid dimensions
   - Confirm overlay disappears

2. **Keyboard Testing**:
   - Press `Ctrl+Shift+R` to cycle through test sizes
   - Press `F11` to toggle fullscreen

3. **Mobile Testing**:
   - Test on mobile devices with orientation changes
   - Verify responsive behavior

## Browser Support

- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+

## Performance

- Debounced resize events (100ms delay)
- Efficient DOM manipulation
- Minimal performance impact
- Smooth animations and transitions

## Security

- Prevents context menu access
- Disables text selection
- No external dependencies
- Self-contained implementation
