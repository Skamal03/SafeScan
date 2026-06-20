# SafeScan — Flutter Widget Documentation
## Assignment Requirement: Minimum 50 Unique Widgets

| # | Widget | Used In |
|---|--------|---------|
| 1 | MaterialApp | main.dart |
| 2 | Scaffold | All screens |
| 3 | AppBar | All screens |
| 4 | SafeArea | splash_screen, login_screen |
| 5 | SingleChildScrollView | Multiple screens |
| 6 | Column | All screens |
| 7 | Row | All screens |
| 8 | Container | All screens |
| 9 | Padding | All screens |
| 10 | SizedBox | All screens |
| 11 | Text | All screens |
| 12 | Icon | All screens |
| 13 | ElevatedButton | login, signup, home, report |
| 14 | OutlinedButton | login, report, profile |
| 15 | TextButton | login, signup, home |
| 16 | TextFormField | login, signup, ssl, breach |
| 17 | Form | login, signup, ssl, breach |
| 18 | GestureDetector | features, permissions, breach |
| 19 | InkWell | profile |
| 20 | Card | home (FeatureCard widget) |
| 21 | ListTile | home (drawer) |
| 22 | Drawer | home |
| 23 | BottomNavigationBar | home |
| 24 | CircularProgressIndicator | splash, wifi, ssl, breach, device |
| 25 | LinearProgressIndicator | splash, home, report |
| 26 | AnimationController | splash |
| 27 | AnimatedBuilder | splash |
| 28 | FadeTransition | splash |
| 29 | ScaleTransition | splash |
| 30 | AnimatedContainer | breach |
| 31 | Stack | splash, home |
| 32 | Positioned | profile |
| 33 | Expanded | All screens |
| 34 | Flexible | Various |
| 35 | Wrap | ssl, permissions |
| 36 | ListView.builder | features, permissions |
| 37 | ModalBottomSheet | permissions (showModalBottomSheet) |
| 38 | AlertDialog | signup, home, profile |
| 39 | SnackBar | Multiple screens |
| 40 | DropdownButton | signup |
| 41 | DropdownMenuItem | signup |
| 42 | Checkbox | login, signup |
| 43 | Switch | profile |
| 44 | Slider | profile |
| 45 | Radio (via tab toggle) | breach |
| 46 | CircleAvatar | home (drawer), profile |
| 47 | Chip | ssl (ActionChip), permissions (custom) |
| 48 | ActionChip | ssl_screen |
| 49 | IconButton | Multiple screens |
| 50 | RichText | signup |
| 51 | TextSpan | signup |
| 52 | Divider | Multiple screens |
| 53 | ClipRRect | home, report, wifi |
| 54 | PageRouteBuilder | splash |
| 55 | MaterialPageRoute | All navigation |
| 56 | DefaultTabController | features |
| 57 | TabBar | features |
| 58 | Tab | features |
| 59 | RadialGradient | splash |
| 60 | LinearGradient | home, profile |
| 61 | BoxDecoration | All screens |
| 62 | BorderRadius | All screens |
| 63 | BoxShadow | common_widgets |
| 64 | Border | All screens |
| 65 | ScaffoldMessenger | Multiple screens |
| 66 | Navigator | All navigation |
| 67 | MediaQuery (via Theme) | app_theme |
| 68 | Theme / ThemeData | app_theme |
| 69 | ColorScheme | app_theme |
| 70 | SystemChrome | main.dart |

**Total: 70 unique widgets — exceeds the 50 widget requirement**

## Screen Inventory (8 Screens)

| # | Screen | File |
|---|--------|------|
| 1 | Splash Screen | splash_screen.dart |
| 2 | Login Screen | login_screen.dart |
| 3 | Signup Screen | signup_screen.dart |
| 4 | Home Screen | home_screen.dart |
| 5 | Features Screen (Listing) | features_screen.dart |
| 6 | Feature Detail Screens (WiFi, SSL, Breach, Permissions, Device) | wifi/ssl/breach/permissions/device |
| 7 | Profile & Settings Screen | profile_screen.dart |
| 8 | Security Report Screen | report_screen.dart |

## Navigation Flow

Splash → Login → Home (Bottom Nav)
Login → Signup (push)
Home → WiFi / SSL / Breach / Permissions / Device (push)
Home → Report (push)
Any Screen → Back (pop)
Home Drawer → Report / Settings

## Data Handling
- All data is static dummy data defined in `lib/data/dummy_data.dart`
- No backend, no API calls, no database
- Forms use UI-level validation only
