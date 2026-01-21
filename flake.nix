{
  description = "Dexter's build of the DWM window manager";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      nixosModules.default = { pkgs, ... }: {
        services.xserver.windowManager.dwm.package = 
          self.packages.${pkgs.system}.default;
      };
      packages = forAllSystems (system: 
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;

	        pwrMgrScript = pkgs.writeShellApplication {
		        name = "pwrMgr";
		        runtimeInputs = [pkgs.systemd pkgs.xset];
		        text = ''
    	        #!/usr/bin/env sh
			        case "$(printf "🔒 lock\n🚪 leave dwm\n♻️ renew dwm\n🐻 hibernate\n🔃 reboot\n🖥️shutdown\n💤 sleep\n📺 display off" | dmenu -i -p 'Action: ')" in
				        '🔒 lock') slock ;;
				        "🚪 leave dwm") kill -TERM "$(pidof dwm)" ;;
				        "♻️ renew dwm") kill -HUP "$(pidof dwm)" ;;
				        '🐻 hibernate') systemctl hibernate -i ;;
				        '💤 sleep') systemctl suspend -i ;;
				        '🔃 reboot') systemctl reboot -i ;;
				        '🖥️shutdown') systemctl poweroff -i ;;
				        '📺 display off') xset dpms force off ;;
				        *) exit 1 ;;
			        esac
		        '';
		      };

		      screenshotScript = pkgs.writeShellApplication{
		        name = "screenshot";
		        runtimeInputs = [pkgs.maim pkgs.xdotool pkgs.xclip pkgs.tesseract];
		        text = ''
    	        #!/usr/bin/env sh
    	        output="$(date '+%y%m%d-%H%M-%S').png"
    	        xclip_img="xclip -sel clip -t image/png"
    	        xclip_txt="xclip -sel clip"

    	        case "$(printf "a selected area (copy)\ncurrent window (copy)\nfull screen (copy)\na selected area\ncurrent window\nfull screen\ncopy selected image to text" | dmenu -l 7 -i -p "Screenshot which area?")" in
    		        "a selected area") maim -u -s "pic-selected-$output" ;;
    		        "current window") maim -B -q -d 0.2 \ -i "$(xdotool getactivewindow)" "pic-window-$output" ;;
    		        "full screen") maim -q -d 0.2 "pic-full-$output" ;;
    		        "a selected area (copy)") maim -u -s | xclip -sel clip -t image/png ;;
    		        "current window (copy)") maim -q -d 0.2 \ -i "$(xdotool getactivewindow)" | $xclip_img ;;
    		        "full screen (copy)") maim -q -d 0.2 | $xclip_img ;;
    		        "copy selected image to text")
    		        tmpfile="$(mktemp /tmp/ocr-XXXXXX.png)"
    		        maim -u -s > "$tmpfile"
    		        tesseract "$tmpfile" - -l eng | $xclip_txt
    		        rm -f "$tmpfile" ;;
    	        esac
		        '';
	        };

          defaultMod = "MODKEY";
          modShift = "MODKEY|ShiftMask";
          defaultArg = "{0}";


          # argument helpers
          argI  = i: "{.i = ${i}}";
          argF  = f: "{.f = ${f}}";
          argUI = ui: "{.ui = ${ui}}";
          argSpawn = cmd: "{.v = (const char*[]){ \"${cmd}\", NULL }}";


	        rawKeybinds = [
		        # PROGS
		        { key = "XK_Return"; fun = "spawn"; arg = "SHCMD(TERMINAL)"; }
		        { mod=modShift; key = "XK_Return"; fun = "togglescratch"; arg = argUI "0"; }
		        { mod=modShift; key = "XK_i"; fun = "togglescratch"; arg = argUI "1" ; }
		        { mod=modShift; key = "XK_b"; fun = "togglescratch"; arg = argUI "2"; }
		        { key = "XK_d"; fun = "spawn"; arg = "{.v = dmenucmd }"; }
		        { key = "XK_b"; fun = "spawn"; arg = argSpawn "${pkgs.librewolf}/bin/librewolf"; }
		        { key = "XK_s"; mod = modShift; fun = "spawn"; arg = argSpawn "${screenshotScript}/bin/screenshot"; }
		        { key = "XK_BackSpace"; fun = "spawn"; arg = argSpawn "${pwrMgrScript}/bin/pwrMgr"; }
		        { key = "XK_q"; mod=modShift; fun = "spawn"; arg = argSpawn "${pwrMgrScript}/bin/pwrMgr"; }


		        # WM
		        { key = "XK_f"; fun = "togglefullscr"; }
		        { key = "XK_q"; fun = "killclient"; }
		        { key = "XK_t"; fun = "setlayout"; arg="{.v = &layouts[0]}"; }
		        { key = "XK_space"; fun = "zoom"; }
		        { mod = modShift; key = "XK_space"; fun = "togglefloating"; }
		        { mod = modShift; key = "XK_x"; fun = "togglebar"; }

		        # MASTER STACK
		        { key = "XK_o"; fun = "incnmaster"; arg = argI "+1"; }
		        { mod = modShift; key = "XK_o"; fun = "incnmaster"; arg = argI "-1"; }


		        # SWITCH/ RESIZE MASTER
		        { key = "XK_j"; fun = "focusstack"; arg = argI "+1"; }
		        { key = "XK_k"; fun = "focusstack"; arg = argI "-1"; }
		        { key = "XK_h"; fun = "setmfact"; arg = argF "-0.05"; }
		        { key = "XK_l"; fun = "setmfact"; arg = argF "+0.05"; }

		        # TAG/VIEW
		        { key = "XK_Tab"; fun = "view"; }
		        { key = "XK_0"; fun = "view"; arg = argUI "~0"; }
		        { mod = modShift; key = "XK_0"; fun = "tag"; arg = argUI "~0"; }

		        # MULTIMON
		        { key = "XK_Left"; fun = "focusmon"; arg = argI "-1"; }
		        { key = "XK_Right"; fun = "focusmon"; arg = argI "+1"; }
		        { mod=modShift; key = "XK_Left"; fun = "tagmon"; arg = argI "-1"; }
		        { mod=modShift; key = "XK_Right"; fun = "tagmon"; arg = argI "+1"; }

		        # GAPS
		        { key = "XK_z"; fun = "incrgaps"; arg = argI "+1"; }
		        { key = "XK_x"; fun = "incrgaps"; arg = argI "-1"; }
		        { key = "XK_a"; fun = "togglegaps"; }
		        { mod=modShift; key = "XK_a"; fun = "defaultgaps"; }
	        ];

          # Fill in defaults manually
          keybinds = map (k: k // {
            mod = if builtins.hasAttr "mod" k then k.mod else defaultMod;
            arg = if builtins.hasAttr "arg" k then k.arg else defaultArg;
          }) rawKeybinds;


	        # String of key+mod, used for duplicate detection
	        keyPairs = map (k: "${k.mod}-${k.key}") keybinds;

          keybindsH = ''
            static const Key keys[] = {
		        ${lib.concatStringsSep "\n  " (map (k: "{ ${k.mod}, ${k.key}, ${k.fun}, ${k.arg} },") keybinds)}
		        TAGKEYS( XK_1, 0)
		        TAGKEYS( XK_2, 1)
		        TAGKEYS( XK_3, 2)
		        TAGKEYS( XK_4, 3)
		        TAGKEYS( XK_5, 4)
		        TAGKEYS( XK_6, 5)
		        TAGKEYS( XK_7, 6)
		        TAGKEYS( XK_8, 7)
		        TAGKEYS( XK_9, 8)
            };
          '';
	        keybindFile = pkgs.writeText "keybinds.h" keybindsH;
        in
        {
          default = 
	          if builtins.length keyPairs != builtins.length (lib.unique keyPairs) then
  	          throw "Duplicate keybinds detected"
	          else
              pkgs.dwm.overrideAttrs (old: {
                src = self;
      		      buildInputs = oldAttrs.buildInputs ++ [ self.libxcb self.libxinerama self.imlib2];
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
