# Changelog

## 0.0.1

- Updated GoRouter configuration redirect function to recognize `/` (explore page) and `/package/*` (package detail pages) as public routes, allowing unauthenticated users to view public packages.
- Changed default theme colors from `ColorSchemes.darkYellow` to `ColorSchemes.darkZinc.yellow`.
- Updated `NavigationSidebar` selected logic to use `selectedKey` instead of an integer index, improving navigation robustness.
