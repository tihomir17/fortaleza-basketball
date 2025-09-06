// Web resize handler for Fortaleza Basketball Analytics
// This file provides additional resize handling and window management

class WindowResizeManager {
  constructor() {
    this.MIN_WIDTH = 1024;
    this.MIN_HEIGHT = 600;
    this.MAX_WIDTH = 1920;
    this.MAX_HEIGHT = 1080;
    this.isResizing = false;
    this.resizeTimeout = null;
    
    this.init();
  }
  
  init() {
    // Add event listeners
    window.addEventListener('resize', this.handleResize.bind(this));
    window.addEventListener('orientationchange', this.handleOrientationChange.bind(this));
    
    // Check initial size
    this.checkWindowSize();
    
    // Add keyboard shortcuts for testing
    this.addKeyboardShortcuts();
  }
  
  handleResize() {
    if (this.isResizing) return;
    
    this.isResizing = true;
    
    // Debounce resize events
    if (this.resizeTimeout) {
      clearTimeout(this.resizeTimeout);
    }
    
    this.resizeTimeout = setTimeout(() => {
      this.checkWindowSize();
      this.isResizing = false;
    }, 100);
  }
  
  handleOrientationChange() {
    // Handle orientation changes (for mobile/tablet)
    setTimeout(() => {
      this.checkWindowSize();
    }, 500);
  }
  
  checkWindowSize() {
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    console.log(`Window size: ${width}x${height}`);
    
    if (width < this.MIN_WIDTH || height < this.MIN_HEIGHT) {
      this.showSizeWarning(width, height);
    } else {
      this.hideSizeWarning();
    }
    
    // Update CSS custom properties for responsive design
    document.documentElement.style.setProperty('--window-width', `${width}px`);
    document.documentElement.style.setProperty('--window-height', `${height}px`);
  }
  
  showSizeWarning(width, height) {
    let warning = document.getElementById('size-warning');
    if (!warning) {
      warning = document.createElement('div');
      warning.id = 'size-warning';
      warning.className = 'size-warning-overlay';
      document.body.appendChild(warning);
    }
    
    warning.innerHTML = `
      <div class="size-warning-content">
        <div class="warning-icon">⚠️</div>
        <h2>Window Size Too Small</h2>
        <p>This application requires a minimum window size of <strong>${this.MIN_WIDTH}×${this.MIN_HEIGHT}</strong> pixels.</p>
        <p>Current size: <strong>${width}×${height}</strong> pixels</p>
        <div class="size-indicator">
          <div class="size-bar">
            <div class="size-fill" style="width: ${Math.min(100, (width / this.MIN_WIDTH) * 100)}%"></div>
          </div>
          <span>Width: ${width}/${this.MIN_WIDTH}px</span>
        </div>
        <div class="size-indicator">
          <div class="size-bar">
            <div class="size-fill" style="width: ${Math.min(100, (height / this.MIN_HEIGHT) * 100)}%"></div>
          </div>
          <span>Height: ${height}/${this.MIN_HEIGHT}px</span>
        </div>
        <p class="instruction">Please resize your browser window to continue.</p>
      </div>
    `;
  }
  
  hideSizeWarning() {
    const warning = document.getElementById('size-warning');
    if (warning) {
      warning.remove();
    }
  }
  
  addKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // F11 for fullscreen toggle
      if (e.key === 'F11') {
        e.preventDefault();
        this.toggleFullscreen();
      }
      
      // Ctrl+Shift+R for resize test
      if (e.ctrlKey && e.shiftKey && e.key === 'R') {
        e.preventDefault();
        this.testResize();
      }
    });
  }
  
  toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(err => {
        console.log('Error attempting to enable fullscreen:', err);
      });
    } else {
      document.exitFullscreen();
    }
  }
  
  testResize() {
    // Test function to simulate different window sizes
    const testSizes = [
      { width: 800, height: 600, name: 'Too Small' },
      { width: 1024, height: 600, name: 'Minimum' },
      { width: 1366, height: 768, name: 'Standard' },
      { width: 1920, height: 1080, name: 'Maximum' }
    ];
    
    let currentTest = 0;
    const testInterval = setInterval(() => {
      if (currentTest >= testSizes.length) {
        clearInterval(testInterval);
        return;
      }
      
      const size = testSizes[currentTest];
      console.log(`Testing size: ${size.name} (${size.width}x${size.height})`);
      
      // Simulate resize (this won't actually resize the window, but will trigger our handler)
      window.dispatchEvent(new Event('resize'));
      
      currentTest++;
    }, 2000);
  }
}

// Initialize the resize manager when the page loads
document.addEventListener('DOMContentLoaded', () => {
  window.resizeManager = new WindowResizeManager();
});

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = WindowResizeManager;
}
