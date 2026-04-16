import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/input.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/null_status.dart';
import 'package:fl_clash/widgets/pop_scope.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:fl_clash/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScriptsView extends ConsumerStatefulWidget {
  const ScriptsView({super.key});

  @override
  ConsumerState<ScriptsView> createState() => _ScriptsViewState();
}

class _ScriptsViewState extends ConsumerState<ScriptsView> {
  final _key = utils.id;

  Future<void> _handleDelScript(int id) async {
    final res = await globalState.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.script),
      ),
    );
    if (res != true) {
      return;
    }
    ref.read(scriptsProvider.notifier).del(id);
    ref.read(selectedItemProvider(_key).notifier).value = null;
    _clearEffect(id);
  }

  Future<void> _handleSyncScript(int id) async {
    final script = await ref.read(scriptProvider(id).future);
    if (script == null) return;

    if (script.url.isEmpty) {
      globalState.showMessage(
        message: TextSpan(text: appLocalizations.scriptNoUrl),
      );
      return;
    }

    try {
      final res = await request.getTextResponseForUrl(script.url);
      final content = res.data ?? '';
      if (content.isEmpty) return;
      final newScript = await script.save(content);
      ref.read(scriptsProvider.notifier).put(newScript);
      if (mounted) {
        context.showNotifier(appLocalizations.syncSuccess);
      }
    } catch (e) {
      globalState.showMessage(
        message: TextSpan(text: e.toString()),
      );
    }
  }

  Future<void> _handleSyncAllScripts(List<Script> scripts) async {
    final remoteScripts = scripts.where((s) => s.url.isNotEmpty).toList();
    if (remoteScripts.isEmpty) {
      globalState.showMessage(
        message: TextSpan(text: appLocalizations.noRemoteScripts),
      );
      return;
    }

    int successCount = 0;
    int failCount = 0;

    for (final script in remoteScripts) {
      try {
        final res = await request.getTextResponseForUrl(script.url);
        final content = res.data ?? '';
        if (content.isNotEmpty) {
          final newScript = await script.save(content);
          ref.read(scriptsProvider.notifier).put(newScript);
          successCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      if (failCount == 0) {
        context.showNotifier(appLocalizations.syncSuccess);
      } else {
        globalState.showMessage(
          message: TextSpan(
            text: appLocalizations.syncResult(successCount, failCount),
          ),
        );
      }
    }
  }

  Future<void> _clearEffect(int id) async {
    final path = await appPath.getScriptPath(id.toString());
    await File(path).safeDelete();
  }

  void _handleSelected(int id) {
    ref.read(selectedItemProvider(_key).notifier).update((value) {
      if (value == id) {
        return null;
      }
      return id;
    });
  }

  String _getSyncTimeDesc(Script script) {
    if (script.url.isEmpty) {
      return appLocalizations.local;
    }
    return script.lastUpdateTime.lastUpdateTimeDesc;
  }

  Widget _buildContent(List<Script> scripts, int? selectedScriptId) {
    if (scripts.isEmpty) {
      return NullStatus(
        illustration: ScriptEmptyIllustration(),
        label: appLocalizations.nullTip(appLocalizations.script),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16),
      itemCount: scripts.length,
      itemBuilder: (_, index) {
        final script = scripts[index];
        final isSelected = selectedScriptId == script.id;
        return CommonSelectedListItem(
          isSelected: isSelected,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  script.label,
                  style: context.textTheme.bodyLarge,
                  maxLines: 3,
                ),
              ),
              SizedBox(width: 8),
              Text(
                _getSyncTimeDesc(script),
                style: context.textTheme.labelMedium?.toLight,
              ),
            ],
          ),
          onSelected: () {
            _handleSelected(script.id);
          },
          onPressed: () {
            _handleSelected(script.id);
          },
        );
      },
    );
  }

  Future<void> _handleEditorSave(
    BuildContext _,
    String title,
    String content,
    String? url, {
    Script? script,
  }) async {
    Script newScript =
        (script?.copyWith(label: title, url: url ?? script.url) ?? Script.create(label: title, url: url ?? ''));
    newScript = await newScript.save(content);
    if (newScript.label.isEmpty) {
      final res = await globalState.showCommonDialog<String>(
        child: InputDialog(
          title: appLocalizations.save,
          value: '',
          hintText: appLocalizations.pleaseEnterScriptName,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return appLocalizations.emptyTip(appLocalizations.name);
            }
            if (value != script?.label) {
              final isExits = ref.read(scriptsProvider.notifier).isExits(value);
              if (isExits) {
                return appLocalizations.existsTip(appLocalizations.name);
              }
            }
            return null;
          },
        ),
      );
      if (res == null || res.isEmpty) {
        return;
      }
      newScript = newScript.copyWith(label: res);
    }
    if (newScript.label != script?.label) {
      final isExits = ref
          .read(scriptsProvider.notifier)
          .isExits(newScript.label);
      if (isExits) {
        globalState.showMessage(
          message: TextSpan(
            text: appLocalizations.existsTip(appLocalizations.name),
          ),
        );
        return;
      }
    }
    ref.read(scriptsProvider.notifier).put(newScript);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _handleEditorPop(
    BuildContext _,
    String title,
    String content,
    String raw, {
    Script? script,
  }) async {
    if (content == raw) {
      return true;
    }
    final res = await globalState.showMessage(
      message: TextSpan(text: appLocalizations.saveChanges),
    );
    if (res == true && mounted) {
      _handleEditorSave(context, title, content, null, script: script);
    } else {
      return true;
    }
    return false;
  }

  void _handleToEditor([int? id]) async {
    final script = await ref.read(scriptProvider(id).future);
    final title = script?.label ?? '';
    final raw = (await script?.content) ?? scriptTemplate;
    if (!mounted) {
      return;
    }
    BaseNavigator.push(
      context,
      EditorPage(
        titleEditable: true,
        title: title,
        supportRemoteDownload: true,
        sourceUrl: script?.url,
        onSave: (context, title, content, url) {
          _handleEditorSave(context, title, content, url, script: script);
        },
        onPop: (context, title, content) {
          return _handleEditorPop(context, title, content, raw, script: script);
        },
        languages: const [Language.javaScript],
        content: raw,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scripts = ref.watch(scriptsProvider).value ?? [];
    final selectedScriptId = ref.watch(selectedItemProvider(_key));
    return CommonPopScope(
      onPop: (_) {
        if (selectedScriptId != null) {
          ref.read(selectedItemProvider(_key).notifier).value = null;
          return false;
        }
        Navigator.of(context).pop();
        return false;
      },
      child: CommonScaffold(
        actions: [
          // Sync button - always visible
          CommonMinIconButtonTheme(
            child: IconButton.filledTonal(
              onPressed: selectedScriptId != null
                  ? () => _handleSyncScript(selectedScriptId)
                  : () => _handleSyncAllScripts(scripts),
              icon: Icon(Icons.sync),
            ),
          ),
          SizedBox(width: 2),
          // Delete button - only when selected
          if (selectedScriptId != null) ...[
            CommonMinIconButtonTheme(
              child: IconButton.filledTonal(
                onPressed: () {
                  _handleDelScript(selectedScriptId);
                },
                icon: Icon(Icons.delete),
              ),
            ),
            SizedBox(width: 2),
          ],
          // Edit/Add button
          CommonMinFilledButtonTheme(
            child: selectedScriptId != null
                ? FilledButton(
                    onPressed: () {
                      _handleToEditor(selectedScriptId);
                    },
                    child: Text(appLocalizations.edit),
                  )
                : FilledButton.tonal(
                    onPressed: () {
                      _handleToEditor();
                    },
                    child: Text(appLocalizations.add),
                  ),
          ),
          SizedBox(width: 8),
        ],
        body: _buildContent(scripts, selectedScriptId),
        title: appLocalizations.script,
      ),
    );
  }
}
