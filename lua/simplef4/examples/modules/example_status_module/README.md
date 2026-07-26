# Example SimpleF4 module

This folder is documentation only. It is not loaded automatically.

Recommended structure:

```text
my_module/
├── sh_module.lua
├── cl_module.lua
└── sv_module.lua
```

`sh_module.lua` registers the module, declares dependencies and contains shared
configuration.

`cl_module.lua` contains HUD/UI code and registers player-facing settings.

`sv_module.lua` contains server-only logic/net receivers if the module needs any.

Copy these files into:

```text
lua/simplef4/modules/my_module/
```

and rename the module ID/config table as needed.
