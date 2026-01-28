{
  description = "Dexter's build of the DWM window manager";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      nixosModules.default = { lib, pkgs, config, ... }:
      let
        cfg = config.programs.dwm;
      in {
        options.programs.dwm = {
          enable = lib.mkEnableOption "Enable custom DWM fork";
          
          appKeybinds = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                mod = lib.mkOption {
                  type = lib.types.str;
                  default = "MODKEY";
                  description = "Modifier mask";
                };
                key = lib.mkOption {
                  type = lib.types.str;
                  description = "Key";
                };
                app = lib.mkOption {
                  type = lib.types.str;
                  description = "Application to spawn";
                };
              };
            });
            default = [];
            description = "Custom application launcher keybinds";
          };
        };
        config = lib.mkIf cfg.enable {
          services.xserver.windowManager.dwm = {
            enable = true;
            package = self.packages.${pkgs.stdenv.hostPlatform.system}.default {
              inherit pkgs;
              appKeybinds = cfg.appKeybinds;
            };
            extraSessionCommands = ''
              pkill -x dwm || true
            '';
          };
        };
      };
      packages = forAllSystems (system: let
        pkgs = import nixpkgs {inherit system;}; 
      in {
        default = { pkgs, appKeybinds ? [] }: 
        let
          makeKeybind = kb: ''
            { ${kb.mod}, XK_${kb.key}, spawn, {.v = (const char*[]){ "${kb.app}", NULL}} },
          '';
          formattedBinds = pkgs.lib.concatStringsSep "\n" (map makeKeybind appKeybinds);
          keybindFile = pkgs.writeText "keybinds.h" ''
static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,			          				XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_Return, spawn,          SHCMD(TERMINAL)},
	{ MODKEY|ShiftMask,             XK_Return, togglescratch,  {.ui=0}},
	{ MODKEY|ShiftMask,             XK_i, 		 togglescratch,  {.ui=1}},
	{ MODKEY|ShiftMask,             XK_b, 		 togglescratch,  {.ui=2}},

	{ MODKEY,             					XK_f,      togglefullscr,  {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },

	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_space,  zoom,      		 {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },

	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },

	{ MODKEY,                       XK_o,      incnmaster,     {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_o,      incnmaster,     {.i = -1 } },

	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },

	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },

	{ MODKEY,                       XK_Left,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_Right, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Left,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Right, tagmon,         {.i = +1 } },


	{ MODKEY,                       XK_z,  	  incrgaps,       {.i = +1 } },
	{ MODKEY,                       XK_x,  	  incrgaps,       {.i = -1 } },
	{ MODKEY,                       XK_a,  	  togglegaps,     {0}},
	{ MODKEY|ShiftMask,             XK_a,  	  defaultgaps,    {0}},
  ${formattedBinds}
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
};
          '';
        in
          pkgs.dwm.overrideAttrs (old: {
            src = self;
      		  buildInputs = old.buildInputs ++ [ pkgs.libxcb pkgs.libxinerama pkgs.imlib2];
      		  postPatch = ''
      		  cp config.my.h config.h
      		  cp ${keybindFile} keybinds.h
      		  '';
          });
        });
      defaultPackage = forAllSystems (system:
        self.packages.${system}.default
      );
    };
}
