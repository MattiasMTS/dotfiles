{ pkgs, lib, config, inputs, username, ... }:
# NOTE: docs for nix-darwin found
# https://daiderd.com/nix-darwin/manual/index.html
{
  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    # Customize the system configuration
    defaults = {
      # customize dock
      dock = {
        autohide = true;
        show-recents = false;

        # # customize Hot Corners
        # wvous-tl-corner = 2;  # top-left - Mission Control
        # wvous-tr-corner = 13;  # top-right - Lock Screen
        # wvous-bl-corner = 3;  # bottom-left - Application Windows
        # wvous-br-corner = 4;  # bottom-right - Desktop
      };

      # customize trackpad
      trackpad = {
        Clicking = true; # enable tap to click
        TrackpadRightClick = true; # enable two finger right click
        TrackpadThreeFingerDrag = true; # enable three finger drag
      };

      # customize settings that not supported by nix-darwin directly
      # Incomplete list of macOS `defaults` commands :
      #   https://github.com/yannbertrand/macos-defaults
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" =
          false; # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" =
          0; # disable beep sound when pressing volume up/down key
        AppleInterfaceStyle = "Dark"; # dark mode
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = false; # enable press and hold

        # sets how long it takes before it starts repeating.
        InitialKeyRepeat =
          15; # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts.
        KeyRepeat = 2; # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
      };

      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.spaces" = {
          "spans-displays" = 0; # Display have seperate spaces
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop =
            0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        # "com.apple.screencapture" = {
        #   location = "~/Desktop";
        #   type = "png";
        # };
        "com.apple.AdLib" = { allowApplePersonalizedAdvertising = false; };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = true; # show full name in login window
      };
    };

    # keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
