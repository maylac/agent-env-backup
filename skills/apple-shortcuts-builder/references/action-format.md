# Action Format Reference

Use this reference when composing `shortcut.json` for `scripts/build_shortcut.py`.

## Minimal Config

```json
{
  "name": "Shortcut Name",
  "actions": [
    {"id": "is.workflow.actions.gettext", "params": {"WFTextActionText": "Hello"}},
    {"id": "is.workflow.actions.setclipboard", "params": {"WFLocalOnly": true}}
  ]
}
```

## Common Action IDs

| User-facing action | Identifier | Common params |
| --- | --- | --- |
| Take Screenshot | `is.workflow.actions.takescreenshot` | none |
| Copy to Clipboard | `is.workflow.actions.setclipboard` | `WFLocalOnly`, `WFExpirationDate` |
| Text | `is.workflow.actions.gettext` | `WFTextActionText` |
| Show Result | `is.workflow.actions.showresult` | usually implicit input |
| Open App | `is.workflow.actions.openapp` | `WFAppIdentifier` |
| Run Shortcut | `is.workflow.actions.runworkflow` | `WFWorkflowName`, `WFShowWorkflow` |
| Get Clipboard | `is.workflow.actions.getclipboard` | none |
| URL | `is.workflow.actions.url` | `WFURLActionURL` |
| Get Contents of URL | `is.workflow.actions.downloadurl` | `WFURL`, advanced HTTP params |
| Save File | `is.workflow.actions.documentpicker.save` | `WFAskWhereToSave`, `WFFileDestinationPath` |
| Save to Photo Album | `is.workflow.actions.savetocameraroll` | `WFCameraRollSelectedGroup` |
| Delete Files | `is.workflow.actions.file.delete` | `WFDeleteFileConfirmDeletion` |

## Screenshot to Clipboard

```json
{
  "name": "Screenshot to Clipboard",
  "workflow_types": ["NCWidget"],
  "actions": [
    {"id": "is.workflow.actions.takescreenshot"},
    {"id": "is.workflow.actions.setclipboard", "params": {"WFLocalOnly": true}}
  ]
}
```

## Raw Actions

Use `raw_actions` only when hand-authoring the full Shortcuts plist action dictionaries:

```json
{
  "name": "Raw Example",
  "raw_actions": [
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.takescreenshot",
      "WFWorkflowActionParameters": {"UUID": "6D72D98D-5332-48E5-A1F2-21A37C78521A"}
    }
  ]
}
```

## Notes

- Omit `WFInput` for normal previous-action flow when the Shortcuts app can infer the input.
- Add explicit variable attachments only when implicit flow does not work. Prefer deriving the exact structure from an exported working shortcut.
- Keep action IDs and parameters grounded in existing exports, local metadata, or current documentation. Do not invent identifiers from display names.
