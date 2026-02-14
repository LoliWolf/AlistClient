# Fix Projector Navigation Spec

## Why

Currently, clicking the "Projector" menu item in the file list screen causes the app to "jump" and return to the file list. This happens because the navigation uses `id: stackId` (targeting the nested file list navigator), but `FileListNavigator`'s `onGenerateRoute` is hardcoded to always return a `FileListScreen`, ignoring the requested route name. As a result, requesting `projectorConfig` actually loads a new `FileListScreen` instance.

## What Changes

* Change the navigation to `projectorConfig` to use the **root navigator** instead of the nested file list navigator.

* This involves removing the `id` parameter and the `stackId` argument.

* Update `ProjectorConfigScreen` to stop expecting and using `stackId`.

## Impact

* Affected specs: Projector Feature

* Affected code:

  * `lib/screen/file_list/file_list_screen.dart`

  * `lib/screen/projector/projector_config_screen.dart`

## ADDED Requirements

None.

## MODIFIED Requirements

### Requirement: Projector Navigation

The system SHALL navigate to `ProjectorConfigScreen` on the root navigator when the projector menu item is clicked.

#### Scenario: Success case

* **WHEN** user clicks "Projector" in the file list menu

* **THEN** `ProjectorConfigScreen` opens (covering the bottom navigation bar).

## REMOVED Requirements

None.

<br />

实施时需关注\
**返回导航 (Back Navigation)**

* **风险:** 当页面被推入 Root Navigator 后，它不再由文件列表页内部管理。
* **检查点:** 确认 `ProjectorConfigScreen` 是否自带 `Scaffold` 和 `AppBar`（包含返回按钮）。如果没有，用户可能会困在配置页无法返回。

- **数据传递 (Data Context)**
  * **风险:** 之前嵌套在 `FileList` 中时，可能隐式依赖了一些 Context 或 Provider。
  * **检查点:** 既然切断了嵌套关系，需确认 `ProjectorConfigScreen` 是否需要从 `FileList` 传递特定参数？如果它是一个完全独立的功能，则无此担忧。
- **路由定义 (Route Definition)**
  * **检查点:** 确认 Root Navigator 的路由表中已经注册了 `projectorConfig`，或者 Root Navigator 的 `onGenerateRoute` 能够正确处理这个路由名称。

