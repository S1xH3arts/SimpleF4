# SimpleF4 examples

These files are examples/documentation and are not automatically executed.

## Module development

See:

```text
examples/modules/example_status_module/
```

It demonstrates the recommended module layout, dependencies, runtime status and
Modules-page settings.

## Useful APIs

```lua
SimpleF4.RegisterModule(...)
SimpleF4.GetModuleStatus(...)
SimpleF4.SetModuleRuntimeStatus(...)
SimpleF4.Notify({...})
SimpleF4.RegisterLevelProvider(...)
```

## Localisation

Every user-facing string should use:

```lua
SimpleF4.L("MyLanguageKey")
```

Add the key to each bundled language file. Missing community-module keys can
fall back to English when the English key is registered.
