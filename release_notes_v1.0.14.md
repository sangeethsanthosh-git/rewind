# REWIND v1.0.14 — Pure Retro & Core Performance Edition

**Physical feel first. Instant response always.**

REWIND v1.0.14 restores the clean, authentic retro Walkman experience of v1.0.10 while applying targeted, pragmatic engineering optimizations to dramatically improve battery life, reduce GPU rasterization load, and eliminate startup friction—with zero artificial fluff or trend-chasing design bloat.

---

### 🔋 Targeted Optimizations

1. **Battery Preservation (Animation Ticker Sleep):**
   - Paused the 60 FPS oscilloscope visualizer ticker (`CrtWaveformVisualizer`) whenever music is paused.
   - Eliminates continuous wake-locks and background rendering loops when the player is idle.

2. **GPU Rasterization & Fill-Rate Efficiency:**
   - Isolated the full-screen blurred ambient wallpaper (`MainShellScreen`) behind a `RepaintBoundary`, caching the blur bitmap on the GPU so foreground scrolling and seekbar movements do not force a full-screen re-blur every frame.
   - Isolated cassette spool rotation hubs (`_CassetteSpool`) behind `RepaintBoundary` wrappers, avoiding invalidation of the cassette chassis, labels, and artwork on every frame.
   - Reduced 3D song stack card shadow blur radius to a crisp 8px, removing fragment shader bottleneck during fling scrolling.

3. **Smooth $O(1)$ List Scrolling:**
   - Added fixed item extent (`itemExtent: 68.0`) to the library and search song lists, eliminating per-item layout computation during fast flings.

4. **Instant Startup (No Artificial Delay):**
   - Reduced splash duration from 1800 ms to a snappy 400 ms.
   - Concurrently initialized background audio service and database using `Future.wait`.
   - Set native Android launch theme window background to `#09090B`, eliminating the white cold-boot flash.

5. **Pure Retro Aesthetic Preserved:**
   - Retained the clean, beloved v1.0.10 UI, theme palette, tactile physical controls, 3D hinged acrylic door, and custom Walkman chassis styling.

---

### 📦 Downloads & Verification

| Asset | Target Architecture | Size | Details |
| :--- | :--- | :--- | :--- |
| **`app-release.apk`** | **Universal (All Devices)** | **~60 MB** | Compatible with all Android devices |
| **`app-arm64-v8a-release.apk`** | **ARM64 (Modern Devices)** | **~22 MB** | Optimized 64-bit binary |
| **`app-armeabi-v7a-release.apk`** | **ARM32 (Older Devices)** | **~20 MB** | Legacy 32-bit binary |
| **`app-x86_64-release.apk`** | **x86_64 (Emulators/PCs)** | **~24 MB** | Emulator / ChromeOS binary |

---

*100% Offline • Zero Analytics • No Ads • Pure Nostalgic Audio*
