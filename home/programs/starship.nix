{ pkgs, ... }:
{
  enable = true;
  enableZshIntegration = true;

  settings = {
    add_newline = false;
    format = "$all";
    directory.truncation_length = 5;
    battery.display = [ { threshold = 50; } ];
    gcloud.disabled = true;
  };

}
