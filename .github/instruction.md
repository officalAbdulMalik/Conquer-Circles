# 🎨 Figma → Flutter Conversion Instructions
> AI Agent Instruction File — Place in project root as `FIGMA_TO_FLUTTER.md`

---

## 📌 HOW TO USE THIS FILE

When you want to convert a Figma page/frame to Flutter, give the AI agent this message:

```
Follow FIGMA_TO_FLUTTER.md.
Page name: [PAGE_NAME]
File key:  [YOUR_FIGMA_FILE_KEY]
Node ID:   [YOUR_NODE_ID e.g. 12:345]
```

The agent will execute all steps automatically.

---

## 🔑 How to Find Your File Key & Node ID

```
https://figma.com/design/ABC123xyz/MyApp?node-id=12-345
                          ^^^^^^^^^                ^^^^^
                        FILE KEY              NODE ID → use as 12:345
```

To copy a frame's node-id: click the frame → right-click → **Copy link** → extract `node-id` from URL → convert dashes to colons (`12-345` → `12:345`).

---

## 🏗️ Standard Flutter Project Structure

All files MUST be created in the correct location. Never deviate from this structure:

```
your_flutter_app/
├── assets/
│   ├── images/                       ← raster images (png, jpg, webp)
│   ├── icons/                        ← SVG icons only
│   └── fonts/                        ← custom font files
│
├── lib/
│   ├── main.dart
│   ├── app.dart                      ← MaterialApp / root setup
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart    ← static strings, enums, config values
│   │   └── utils/
│   │       └── app_utils.dart        ← pure helper functions (no UI)
│   │
│   ├── theme/
│   │   ├── app_colors.dart           ← ALL Color constants
│   │   ├── app_text_styles.dart      ← ALL TextStyle constants
│   │   └── app_theme.dart            ← ThemeData configuration
│   │
│   ├── models/                       ← data models / entities only
│   │   └── [model_name].dart
│   │
│   ├── services/                     ← API, database, storage — NO UI here
│   │   └── [name]_service.dart
│   │
│   ├── controllers/                  ← state management (Provider/Bloc/Riverpod)
│   │   └── [feature]_controller.dart
│   │
│   ├── screens/                      ← one file per screen, composition only
│   │   └── [page_name]/
│   │       └── [page_name]_screen.dart
│   │
│   └── widgets/
│       ├── shared/                   ← widgets reused across multiple screens
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   └── app_loader.dart
│       └── [page_name]/              ← widgets specific to one screen
│           ├── [component]_tile.dart
│           └── [component]_card.dart
│
└── pubspec.yaml
```

---

## 🤖 AGENT — EXECUTE ALL STEPS IN ORDER

---

### STEP 1 — Fetch Design from Figma MCP

Call the Figma MCP tool using the file key and node ID from the chat message:

```
Tool: get_design_context
fileKey: [FROM CHAT]
nodeId:  [FROM CHAT]
clientFrameworks: flutter
clientLanguages: dart
```

Extract and record from the response:
- Design screenshot
- All asset download URLs (images, icons, SVGs)
- Exact color hex values
- Font names, sizes, weights, line heights, letter spacing
- Padding, margin, gap values
- Border radius values
- Layer names and component structure

---

### STEP 2 — Download ALL Assets (MANDATORY — Never Skip)

**Download every asset BEFORE writing any Flutter code. No exceptions.**

---

#### ⚠️ Why Figma Asset Downloads Fail — Read This First

Figma MCP returns **presigned S3 URLs** that look like this:

```
https://figma-alpha-api.s3.us-west-2.amazonaws.com/runs/xxx/files/image.png?X-Amz-Algorithm=AWS4&X-Amz-Credential=yyy&X-Amz-Expires=3600&token=zzz
```

These URLs have three failure modes that cause the downloaded file to be an HTML error page instead of an actual image — which is why the file shows "not supported" when opened:

| Failure | Cause | Fix |
|---------|-------|-----|
| Shell splits the URL | The `&` characters in the URL are shell operators — unquoted URLs break into multiple commands and curl downloads an error page | Always wrap the full URL in `"double quotes"` |
| File is HTML but saved as `.png` | curl saves whatever the server returns — if the URL is malformed, you get an HTML error page with a `.png` extension | Validate MIME type after every download |
| Presigned URL expired | Figma S3 URLs expire in ~1 hour — if the agent is slow or the session is long, the URL is dead | Use the Figma REST API to generate a fresh export URL |

---

#### ⚠️ Rule 0 — Fix: VS Code Agent Terminal Hanging on Downloads

When the agent runs curl commands, you may see this in the chat:

```
The terminal is waiting for a response. Let me check the terminal status...
Waiting for tool 'Run in Terminal' to respond...
```

**Why this happens:** The VS Code agent's "Run in Terminal" tool sends commands to an
interactive terminal session and waits for it to exit. If a previous command did not exit
cleanly, or the terminal is waiting for input, the agent hangs indefinitely.
curl itself is NOT broken — the terminal session is stuck.

---

**Fix 1 — Always chain all commands into a single one-liner**

Never send mkdir, curl, and validate as three separate terminal commands.
Always chain with `&&` so the terminal runs everything atomically and exits:

```bash
# CORRECT — one atomic command, terminal exits cleanly after echo
mkdir -p assets/images assets/icons assets/fonts && curl --location --fail --silent --retry 3 "[URL_1]" -o "assets/images/hero.png" && curl --location --fail --silent --retry 3 "[URL_2]" -o "assets/icons/icon_home.svg" && echo "ALL_DOWNLOADS_COMPLETE"

# WRONG — separate commands, terminal may hang between steps
mkdir -p assets/images
curl -L "[URL_1]" -o "assets/images/hero.png"
```

**Fix 2 — Always end every command block with `echo "DONE"`**

The agent detects command completion by seeing output. Always append `&& echo "DONE"`
so the agent gets a signal that the command finished and stops waiting:

```bash
curl --location --fail --silent "[URL]" -o "assets/images/file.png" && file --mime-type "assets/images/file.png" && echo "DOWNLOAD_DONE"
```

**Fix 3 — Always use `--silent` flag on curl**

Without `--silent`, curl prints a live progress bar to the terminal.
This interactive output causes some agent terminals to hang waiting for it to clear:

```bash
# CORRECT
curl --location --fail --silent --retry 3 "[URL]" -o "assets/images/file.png"

# WRONG — progress bar output hangs some agent terminals
curl -L "[URL]" -o "assets/images/file.png"
```

**Fix 4 — If the terminal is already stuck, tell the agent:**

```
The terminal is stuck waiting. Press Ctrl+C in the VS Code terminal panel to cancel,
then retry all download commands as a single chained one-liner ending with echo "DONE".
```

Or type this directly in the VS Code terminal panel to unstick it:
```
q
```
or press `Ctrl+C`, then ask the agent to retry.

**Fix 5 — Use a download script file instead of inline terminal commands**

For many assets, tell the agent to write a shell script and execute it as one command:

```bash
# Agent writes this file first
cat > /tmp/download_assets.sh << 'EOF'
#!/bin/bash
set -e
mkdir -p assets/images assets/icons assets/fonts

download_asset() {
  local url="$1"
  local output="$2"
  curl --location --fail --silent --retry 3 "$url" -o "$output"
  local mime=$(file --mime-type -b "$output")
  if [[ "$mime" != image/* ]]; then
    echo "FAILED: $output got $mime"
    rm "$output"
    exit 1
  fi
  echo "OK: $output ($mime)"
}

download_asset "[URL_1]" "assets/images/hero_banner.png"
download_asset "[URL_2]" "assets/icons/icon_home.svg"

echo "ALL_ASSETS_DOWNLOADED"
EOF

# Then agent runs it as one command
chmod +x /tmp/download_assets.sh && /tmp/download_assets.sh && echo "SCRIPT_DONE"
```

This way the agent sends **one terminal command** and waits for `SCRIPT_DONE` — no hanging.

---

#### Rule 1 — Always Wrap URLs in Double Quotes

```bash
# ❌ WRONG — shell splits at & and downloads an HTML error page
curl -L https://s3.amazonaws.com/file.png?X-Amz-Algo=xxx&token=yyy -o image.png

# ✅ CORRECT — quotes preserve the full URL intact
curl -L "https://s3.amazonaws.com/file.png?X-Amz-Algo=xxx&token=yyy" -o image.png
```

#### Rule 2 — Use Safe curl Flags on Every Download

Always use `--fail`, `--retry`, and `--location` together:

```bash
curl --location --fail --retry 3 --retry-delay 2 \
  "[FIGMA_ASSET_URL]" \
  -o "assets/images/[filename].png"
```

- `--location` follows redirects (Figma URLs often redirect)
- `--fail` makes curl exit with error code instead of saving an HTML error page
- `--retry 3` retries up to 3 times on transient failures

#### Rule 3 — Validate MIME Type After Every Download

After every curl, check the actual file type. If it is `text/html` or `text/xml`, the file is corrupt — it is an error page, not an image:

```bash
# For PNG/JPG images — must return image/png or image/jpeg
file --mime-type "assets/images/[filename].png"
# ✅ assets/images/hero_banner.png: image/png
# ❌ assets/images/hero_banner.png: text/html  ← download failed, re-download

# For SVG icons — must return image/svg+xml
file --mime-type "assets/icons/[filename].svg"
# ✅ assets/icons/icon_home.svg: image/svg+xml
# ❌ assets/icons/icon_home.svg: text/html  ← download failed, re-download

# For SVGs also check content starts with <svg or <?xml
head -c 80 "assets/icons/[filename].svg"
# ✅ <svg xmlns="http://www.w3.org/2000/svg" ...
# ❌ <!DOCTYPE html>  ← corrupt file, delete and re-download
```

If validation fails — delete the corrupt file and use the Figma REST API fallback below.

#### Rule 4 — Figma REST API Fallback (When Presigned URLs Fail or Expire)

If any presigned URL fails, generate a fresh export URL directly from the Figma API:

```bash
# Step 1: Request a fresh export URL from Figma
# Replace FILE_KEY, NODE_ID, and FIGMA_TOKEN with real values
curl -H "X-Figma-Token: [FIGMA_TOKEN]" \
  "https://api.figma.com/v1/images/[FILE_KEY]?ids=[NODE_ID]&format=png&scale=2" \
  -o figma_export.json

# Step 2: Read the fresh URL from the response
cat figma_export.json
# Response: { "images": { "NODE_ID": "https://fresh-s3-url..." } }

# Step 3: Download using the fresh URL (in quotes)
curl --location --fail --retry 3 \
  "[URL_FROM_RESPONSE]" \
  -o "assets/images/[filename].png"

# For SVG format
curl -H "X-Figma-Token: [FIGMA_TOKEN]" \
  "https://api.figma.com/v1/images/[FILE_KEY]?ids=[NODE_ID]&format=svg" \
  -o figma_export_svg.json
```

---

#### Safe Batch Download — Use a Script File (Prevents Terminal Hanging)

**Do NOT run curl commands one by one in the terminal.**
**Always write a script file and execute it as a single command.**
This prevents the VS Code agent terminal from hanging between commands.

**Step A — Agent writes the download script:**

```bash
cat > /tmp/figma_download.sh << 'DLEOF'
#!/bin/bash
set -e
mkdir -p assets/images assets/icons assets/fonts

download_asset() {
  local url="$1"
  local output="$2"
  echo "Downloading: $output"
  curl --location --fail --silent --retry 3 --retry-delay 2 "$url" -o "$output"
  local mime=$(file --mime-type -b "$output")
  if [[ "$mime" != image/* && "$mime" != application/font* && "$mime" != font/* ]]; then
    echo "FAILED: $output got MIME=$mime — corrupt or expired URL"
    rm "$output"
    exit 1
  fi
  echo "OK: $output | $mime | $(du -sh $output | cut -f1)"
}

# Agent fills in one line per asset from Figma MCP response
download_asset "[FIGMA_IMAGE_URL_1]" "assets/images/hero_banner.png"
download_asset "[FIGMA_IMAGE_URL_2]" "assets/images/profile_photo.png"
download_asset "[FIGMA_ICON_URL_1]"  "assets/icons/icon_home.svg"
download_asset "[FIGMA_ICON_URL_2]"  "assets/icons/icon_search.svg"

echo "ALL_ASSETS_DOWNLOADED_SUCCESSFULLY"
DLEOF
```

**Step B — Agent runs it as ONE terminal command:**

```bash
chmod +x /tmp/figma_download.sh && /tmp/figma_download.sh && echo "DONE"
```

The agent sends this single line, waits for `DONE`, and the terminal exits cleanly.
No hanging. No separate curl calls.

---

#### Asset Type Classification

| Figma layer type | Format to export | Save to |
|-----------------|-----------------|---------|
| Image fills, photos, illustrations | `.png` at `scale=2` for retina | `assets/images/` |
| Vector icons, logos, decorative shapes | `.svg` | `assets/icons/` |
| Custom fonts | `.ttf` or `.otf` | `assets/fonts/` |

#### Filename Rules

- ✅ Lowercase with underscores: `hero_banner.png`, `icon_home.svg`
- ✅ Descriptive and short: `onboarding_step1.png`, `tab_icon_profile.svg`
- ❌ Raw URLs, query strings, spaces, or uppercase: `Image (1).PNG`

---

#### Final Asset Validation — Run After All Downloads

```bash
# List all files with sizes — any 0-byte file is a failed download
find assets/ -type f | xargs ls -lh

# Check MIME types of all images
find assets/images -type f -exec file --mime-type {} \;

# Check all SVGs are valid (must start with <svg or <?xml)
find assets/icons -name "*.svg" -exec sh -c 'echo "--- $1 ---"; head -c 60 "$1"; echo' _ {} \;
```

**If any file fails validation — stop and report. Never write Flutter code with corrupt assets.**

---

### STEP 3 — Register Assets in pubspec.yaml

Add all asset **folders** (never individual file paths) to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/

  fonts:
    - family: [FontName]            # only if custom fonts were downloaded
      fonts:
        - asset: assets/fonts/[FontName]-Regular.ttf
        - asset: assets/fonts/[FontName]-Bold.ttf
          weight: 700
```

Then run:
```bash
flutter pub get
```

---

### STEP 4 — Sync Global Design System (Colors & Text Styles)

> ⚠️ **This step runs ONCE before any screen is built, and is READ-ONLY for all subsequent pages.**
> Colors and text styles are GLOBAL. They are never screen-specific.
> Never create `splashPrimary`, `homeBackground`, `loginTextColor` or any page-named token.

---

#### 4a — One-Time Global Design System Extraction (Do This First, Before Page 1)

Before converting any screen, fetch the Figma file's global styles using the design system page
or the root document node. This extracts ALL colors and text styles used across the entire app
in one pass.

```
Tool: get_design_context
fileKey: [FILE_KEY]
nodeId:  [ROOT OR STYLE GUIDE NODE ID]
clientFrameworks: flutter
clientLanguages: dart
```

From this response, build the complete `app_colors.dart` and `app_text_styles.dart` files
using **semantic, role-based naming only** (see naming rules below).

These files are written **once** and only appended to if a genuinely new global token is found
in a later page. They are never rewritten, and entries are never renamed per screen.

---

#### 4b — Global Color Naming Rules

Colors must be named by their **role and semantic meaning**, never by screen, component, or
Figma layer name.

**Naming decision tree — in order:**

1. Is it the brand's primary action color? → `primary`
2. Is it a secondary/accent color? → `secondary`
3. Is it a background surface? → `background`, `surface`, `surfaceVariant`
4. Is it used for text? → `textPrimary`, `textSecondary`, `textHint`, `textDisabled`
5. Is it a border or divider? → `border`, `divider`
6. Is it a status color? → `success`, `warning`, `error`, `info`
7. Is it an overlay or scrim? → `overlay`, `scrim`
8. Is it an icon tint? → `iconPrimary`, `iconSecondary`, `iconDisabled`

**Correct vs Wrong naming:**

| ❌ Wrong — screen/layer named | ✅ Correct — semantic/role named |
|-------------------------------|----------------------------------|
| `splashBackground` | `primary` |
| `splashTextColor` | `textOnPrimary` |
| `homeCardBackground` | `surface` |
| `loginButtonColor` | `primaryButton` |
| `profileDivider` | `divider` |
| `onboardingAccent` | `secondary` |
| `drawerIconColor` | `iconSecondary` |

**If two screens use the same hex value with different names — they are ONE token.**
Always merge them into the single semantic name.

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Brand ──────────────────────────────────────────
  static const Color primary         = Color(0xFF______); // main CTA, buttons, links
  static const Color primaryDark     = Color(0xFF______); // pressed/hover state
  static const Color secondary       = Color(0xFF______); // accent, highlights
  static const Color tertiary        = Color(0xFF______); // optional 3rd brand color

  // ── Backgrounds & Surfaces ─────────────────────────
  static const Color background      = Color(0xFF______); // root scaffold background
  static const Color surface         = Color(0xFF______); // cards, sheets, dialogs
  static const Color surfaceVariant  = Color(0xFF______); // subtle card alt background

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF______); // headings, body
  static const Color textSecondary   = Color(0xFF______); // subtitles, captions
  static const Color textHint        = Color(0xFF______); // placeholder text
  static const Color textDisabled    = Color(0xFF______); // disabled state
  static const Color textOnPrimary   = Color(0xFF______); // text on primary color bg

  // ── Icons ──────────────────────────────────────────
  static const Color iconPrimary     = Color(0xFF______);
  static const Color iconSecondary   = Color(0xFF______);
  static const Color iconDisabled    = Color(0xFF______);

  // ── Borders & Dividers ─────────────────────────────
  static const Color border          = Color(0xFF______);
  static const Color divider         = Color(0xFF______);

  // ── Status ─────────────────────────────────────────
  static const Color success         = Color(0xFF______);
  static const Color warning         = Color(0xFF______);
  static const Color error           = Color(0xFF______);
  static const Color info            = Color(0xFF______);

  // ── Overlay ────────────────────────────────────────
  static const Color overlay         = Color(0x80000000); // semi-transparent scrim
}
```

---

#### 4c — Global Text Style Naming Rules

Text styles are named by their **typographic role**, never by the screen or widget they appear in.

**Naming convention:**

| Role | Name | Usage |
|------|------|-------|
| Largest heading | `displayLarge` | Hero titles, splash text |
| Second heading | `displayMedium` | Section headers |
| Third heading | `displaySmall` | Card headers |
| Page title | `headlineLarge` | Screen titles in AppBar |
| Sub-section title | `headlineMedium` | Group labels |
| Small title | `headlineSmall` | List section headers |
| Main body | `bodyLarge` | Primary readable content |
| Default body | `bodyMedium` | Standard paragraphs |
| Small body | `bodySmall` | Dense or secondary text |
| UI labels | `labelLarge` | Buttons, tabs |
| Small labels | `labelMedium` | Badges, chips |
| Tiny labels | `labelSmall` | Timestamps, footnotes |
| Input text | `inputText` | TextField content |
| Placeholder | `inputHint` | TextField hint |
| Link | `link` | Tappable text |
| Caption | `caption` | Image captions, helper text |

**Correct vs Wrong naming:**

| ❌ Wrong — screen/widget named | ✅ Correct — typographic role named |
|--------------------------------|-------------------------------------|
| `splashTitle` | `displayLarge` |
| `splashSubtitle` | `bodyLarge` |
| `homeCardTitle` | `headlineSmall` |
| `loginButtonLabel` | `labelLarge` |
| `profileNameText` | `headlineMedium` |
| `drawerMenuItemText` | `bodyMedium` |

**If two screens use the same font/size/weight — they are ONE style.**
Always merge into the single typographic role name.

```dart
// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._(); // prevent instantiation

  // ── Display ────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: ___,
    letterSpacing: ___,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: ___,
  );

  // ── Headline ───────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: ___,
  );

  // ── Body ───────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: ___,
  );

  // ── Label ──────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: ___,
    letterSpacing: ___,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: ___,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: ___,
  );

  // ── Utility ────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: ___,
  );

  static const TextStyle link = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: ___,
    decoration: TextDecoration.underline,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: ___,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: ___,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: ___,
  );
}
```

---

#### 4d — Per-Page Color & Style Rules (For Every Page After the First)

When converting a new page, do this **before** using any color or text style:

**For every color found in the new page design:**
1. Extract the hex value
2. Search `app_colors.dart` for that exact hex value
3. If found → use the existing token name. Do NOT create a new one.
4. If NOT found → it is a genuinely new global token. Add it with a semantic role name using the naming rules in 4b.

**For every text style found in the new page design:**
1. Extract fontSize + fontWeight + lineHeight
2. Search `app_text_styles.dart` for a matching combination
3. If found → use the existing style name. Do NOT create a new one.
4. If NOT found → it is a genuinely new global style. Add it with a typographic role name using the naming rules in 4c.

**The agent must run this check BEFORE writing any widget or screen code.**
If a color or style is added without this check, it is a violation.

---

### STEP 5 — Write the Screen File

Create `lib/screens/[page_name]/[page_name]_screen.dart`.

**The screen file is for UI composition only. It assembles widgets. Zero logic allowed.**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared/app_button.dart';
import '../../widgets/[page_name]/[component]_tile.dart';
import '../../widgets/[page_name]/[component]_card.dart';

class [PageName]Screen extends StatelessWidget {
  const [PageName]Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const [Component]Header(),
              const SizedBox(height: 16),
              const [Component]Card(),
              const SizedBox(height: 12),
              [Component]Tile(title: 'Item', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Mandatory asset and style rules:**

| Rule | ✅ Correct | ❌ Wrong |
|------|-----------|---------|
| Raster images | `Image.asset('assets/images/file.png')` | `Image.network('https://...')` |
| SVG icons | `SvgPicture.asset('assets/icons/icon.svg')` | `Image.network(...)` |
| Colors | `AppColors.primary` | `Colors.blue` or inline `Color(0xFF...)` in widget |
| Text styles | `AppTextStyles.heading1` | Inline `TextStyle(...)` anywhere in UI files |
| Spacing | Exact from Figma — `SizedBox(height: 24)` | Guessed or approximate values |
| Border radius | Exact from Figma — `BorderRadius.circular(12)` | Guessed |
| Screen sizing | `MediaQuery.of(context).size.width` | Hardcoded `width: 375` |

---

### STEP 6 — Create All Widgets as Classes (NEVER Private Methods)

> ⚠️ **This is the most important coding rule in this file.**

**Every UI component — no matter how small — MUST be its own widget class in the `widgets/` directory. Private methods like `_buildCard()`, `_buildHeader()`, `_buildRow()` are strictly forbidden.**

#### ❌ FORBIDDEN pattern:
```dart
// NEVER do this inside a screen or any widget
Widget _buildProductCard() {
  return Container(...);
}

Widget _buildSectionTitle(String text) {
  return Text(text, style: AppTextStyles.heading2);
}
```

#### ✅ CORRECT pattern — always a separate file:
```dart
// lib/widgets/[page_name]/section_title.dart
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.heading2);
  }
}
```

#### Widget naming convention:

| Use case | Suffix | Example |
|----------|--------|---------|
| List row / menu item | `Tile` | `ProductTile`, `MenuItemTile` |
| Contained elevated box | `Card` | `ProfileCard`, `StatsCard` |
| Top area / hero | `Header` | `HomeHeader`, `CheckoutHeader` |
| Section label | `SectionTitle` | `HomeSectionTitle` |
| Bottom / tab bar | `NavBar` | `AppNavBar` |
| Modal / bottom sheet | `Sheet` | `FilterSheet` |
| Dialog | `Dialog` | `ConfirmDialog` |
| Button | `Button` | `AppButton`, `OutlineButton` |
| Input | `TextField` | `SearchTextField` |

#### Shared vs page-specific:

- **`widgets/shared/`** — used on 2 or more screens (buttons, inputs, loaders, avatars)
- **`widgets/[page_name]/`** — used only on one screen (page-specific tiles, cards, headers)

---

### STEP 7 — Separation of Concerns (Strict Boundaries)

The screen and widget layers are display-only. All logic lives in dedicated layers.

#### ❌ NEVER put in a Screen or Widget file:
- HTTP/API calls
- Database reads or writes
- SharedPreferences / local storage access
- Business rules or data transformations
- Complex `if/else` chains that compute data
- String formatting of business values

#### ✅ Where everything belongs:

| What | Where |
|------|-------|
| API calls, HTTP requests | `lib/services/[name]_service.dart` |
| App state, logic, reactions | `lib/controllers/[name]_controller.dart` |
| Data transformation, helpers | `lib/core/utils/app_utils.dart` |
| Static strings, enums, config | `lib/core/constants/app_constants.dart` |
| Data models / entities | `lib/models/[name].dart` |
| Colors | `lib/theme/app_colors.dart` |
| Text styles | `lib/theme/app_text_styles.dart` |
| Screen layout | `lib/screens/[page_name]/[page_name]_screen.dart` |
| UI components | `lib/widgets/[shared or page_name]/[name].dart` |

#### What a screen file may do:
- Lay out and compose widgets
- Pass data down via constructor params
- Call a controller method in `onTap` / `onPressed`

#### What a widget file may do:
- Render UI using props passed in
- Emit callbacks upward (never call services directly)
- Manage simple local visual state only (e.g. `isExpanded`, `isSelected`)

---

### STEP 8 — Required Packages Check

Ensure `pubspec.yaml` includes the packages your page needs:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.10            # required for all SVG icons
  cached_network_image: ^3.3.1    # only for truly dynamic remote images
  google_fonts: ^6.1.0            # only if Google Fonts are used in the design
```

Run:
```bash
flutter pub add flutter_svg
flutter pub get
```

---

### STEP 9 — Final Verification

Run and resolve all issues:
```bash
flutter analyze lib/screens/[page_name]/
flutter analyze lib/widgets/[page_name]/
flutter pub get
```

Check every box before marking this page as complete:

**Assets**
- [ ] All Figma asset URLs have been downloaded locally
- [ ] All asset folders registered in `pubspec.yaml`
- [ ] `flutter pub get` ran with no errors
- [ ] No `Image.network()` used for design assets
- [ ] `flutter_svg` used for all `.svg` files

**Design System (check before writing any widget)**
- [ ] Every color hex from Figma searched in `app_colors.dart` before adding new token
- [ ] Every text spec (size+weight+height) searched in `app_text_styles.dart` before adding
- [ ] Zero screen-named tokens (`splashX`, `homeX`, `loginX`) in theme files
- [ ] Zero component-named tokens (`buttonX`, `cardX`, `drawerX`) in theme files
- [ ] Same hex value never appears under two different token names
- [ ] Same font spec never appears under two different style names

**Code Quality**
- [ ] No inline colors anywhere — all from `AppColors`
- [ ] No inline `TextStyle` — all from `AppTextStyles`
- [ ] No private `_buildXxx()` methods — all extracted to widget files
- [ ] No business logic in screen or widget files
- [ ] Every UI component (however small) is its own widget class in `widgets/`

**Design Fidelity**
- [ ] Spacing matches Figma exactly
- [ ] Font sizes, weights, and line heights match Figma exactly
- [ ] Colors match Figma exactly
- [ ] Border radii match Figma exactly
- [ ] No pixel overflow warnings

**Final**
- [ ] `flutter analyze` shows no errors or warnings

---

## 🚨 STRICT RULES — Never Break These

1. **No network URLs** for design assets — always `Image.asset()` or `SvgPicture.asset()`
2. **No private build methods** — `_buildXxx()` is forbidden; create a widget class instead
3. **No business logic in UI** — screens and widgets are display-only
4. **No inline colors** — always `AppColors`
5. **No inline text styles** — always `AppTextStyles`
6. **No hardcoded screen dimensions** — always `MediaQuery`
7. **No guessed spacing** — use exact Figma values
8. **Always run `flutter pub get`** after every `pubspec.yaml` change
9. **Always report failed downloads** — never silently skip
10. **No duplicate color or style entries** — before adding any token, search the file for the hex value or font spec first; if it exists, use the existing name
11. **No screen-named tokens** — `splashBackground`, `homeCardColor`, `loginText` are forbidden; always use semantic role names like `primary`, `surface`, `textPrimary`
12. **No component-named tokens** — `buttonColor`, `cardBackground`, `drawerText` are forbidden; use `primary`, `surface`, `bodyMedium`
13. **Colors and text styles are global** — they live only in `app_colors.dart` and `app_text_styles.dart`; no color or TextStyle is ever defined inside a screen or widget file
14. **Same hex = same token** — if two pages use `#3A86FF`, it is one token (`primary`), not `splashBlue` and `homeBlue`
15. **Always quote Figma URLs** — every `curl` must wrap the URL in `"double quotes"`
12. **Always validate MIME type** after every download — `text/html` result means corrupt file, not an image
13. **Never write Flutter code** until all assets pass MIME validation
14. **Use Figma REST API fallback** if any presigned URL fails or returns a corrupt file
15. **Never run curl commands one-by-one** in the terminal — always write a script file and execute it as one command ending with `echo "DONE"`
16. **Always use `--silent` flag** on every curl — live progress bars cause agent terminals to hang
17. **Always end terminal command blocks with `&& echo "DONE"`** — this signals the agent that the command finished

---

## 📋 Page Conversion Log

Update after each page is completed:

| Page Name | File Key | Node ID | Status | Screen File | Notes |
|-----------|----------|---------|--------|-------------|-------|
| — | — | — | — | — | — |

---

## ⚡ Agent Quick Start Prompt

Copy this and fill in the three values:

```
Follow FIGMA_TO_FLUTTER.md in the project root.

Page name: [PAGE_NAME]
File key:  [FILE_KEY]
Node ID:   [NODE_ID]

Execute all 9 steps in order.
Download every Figma asset locally before writing any code.
Never use Image.network() for design assets.
Never create private _build methods — all components go in widgets/ as classes.
No business logic in screen or widget files.

DESIGN SYSTEM RULES (check before every widget):
- Before using any color: search app_colors.dart for the hex value. Use existing token if found.
- Before using any text style: search app_text_styles.dart for matching size+weight. Use existing if found.
- Never create screen-named tokens: splashX, homeX, loginX are forbidden.
- Never create component-named tokens: buttonX, cardX are forbidden.
- Same hex value = same token. Never duplicate under a different name.
- Colors and TextStyles are ONLY defined in app_colors.dart and app_text_styles.dart.
```

---

*`FIGMA_TO_FLUTTER.md` — Place in project root. One file governs all page conversions.*