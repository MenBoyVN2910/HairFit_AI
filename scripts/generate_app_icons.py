import os
import subprocess
from PIL import Image, ImageDraw

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    font_path = os.path.join(root_dir, "build", "app", "intermediates", "assets", "debug", "mergeDebugAssets", "flutter_assets", "fonts", "MaterialIcons-Regular.otf")
    font_url = font_path.replace("\\", "/")
    
    edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    
    # 1. HTML for standard app icon (1024x1024, #1A1A2E background, #E94560 scissors)
    html_standard = f"""<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<style>
@font-face {{
  font-family: 'MaterialIcons';
  src: url('{font_url}') format('opentype');
}}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{
  width: 1024px;
  height: 1024px;
  background-color: #1A1A2E;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}}
.icon {{
  font-family: 'MaterialIcons';
  font-size: 640px;
  color: #E94560;
  line-height: 1;
  text-align: center;
  user-select: none;
}}
</style>
</head>
<body>
  <div class='icon'>&#xf66d;</div>
</body>
</html>
"""

    # 2. HTML for adaptive icon foreground (transparent background, scissors sized inside 66% safe zone ~ 560px)
    html_foreground = f"""<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<style>
@font-face {{
  font-family: 'MaterialIcons';
  src: url('{font_url}') format('opentype');
}}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{
  width: 1024px;
  height: 1024px;
  background-color: transparent;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}}
.icon {{
  font-family: 'MaterialIcons';
  font-size: 560px;
  color: #E94560;
  line-height: 1;
  text-align: center;
  user-select: none;
}}
</style>
</head>
<body>
  <div class='icon'>&#xf66d;</div>
</body>
</html>
"""

    temp_std_html = os.path.join(root_dir, "temp_std.html")
    temp_fg_html = os.path.join(root_dir, "temp_fg.html")
    temp_std_png = os.path.join(root_dir, "temp_std.png")
    temp_fg_png = os.path.join(root_dir, "temp_fg.png")

    with open(temp_std_html, "w", encoding="utf-8") as f:
        f.write(html_standard)
    with open(temp_fg_html, "w", encoding="utf-8") as f:
        f.write(html_foreground)

    # Render Standard
    cmd_std = [
        edge_path,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        "--window-size=1024,1024",
        f"--screenshot={temp_std_png}",
        f"file:///{temp_std_html.replace('\\', '/')}"
    ]
    subprocess.run(cmd_std, check=True)

    # Render Foreground
    cmd_fg = [
        edge_path,
        "--headless=new",
        "--disable-gpu",
        "--default-background-color=00000000",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        "--window-size=1024,1024",
        f"--screenshot={temp_fg_png}",
        f"file:///{temp_fg_html.replace('\\', '/')}"
    ]
    subprocess.run(cmd_fg, check=True)

    img_std = Image.open(temp_std_png).convert("RGBA")
    img_fg = Image.open(temp_fg_png).convert("RGBA")

    # Generate Round Icon (masked with circle)
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, 1024, 1024), fill=255)
    img_round = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    img_round.paste(img_std, (0, 0), mask=mask)

    # Save to assets/icons/
    assets_icons_dir = os.path.join(root_dir, "assets", "icons")
    os.makedirs(assets_icons_dir, exist_ok=True)
    img_std.save(os.path.join(assets_icons_dir, "app_icon.png"), "PNG")
    img_round.save(os.path.join(assets_icons_dir, "app_icon_round.png"), "PNG")
    img_fg.save(os.path.join(assets_icons_dir, "app_icon_foreground.png"), "PNG")
    print(f"Saved master icons to {assets_icons_dir}")

    # Android mipmaps
    res_dir = os.path.join(root_dir, "android", "app", "src", "main", "res")
    densities = {
        "mipmap-mdpi": (48, 108),
        "mipmap-hdpi": (72, 162),
        "mipmap-xhdpi": (96, 216),
        "mipmap-xxhdpi": (144, 324),
        "mipmap-xxxhdpi": (192, 432),
    }

    for folder, (icon_sz, fg_sz) in densities.items():
        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        
        # ic_launcher.png
        resized_std = img_std.resize((icon_sz, icon_sz), Image.Resampling.LANCZOS)
        resized_std.save(os.path.join(target_dir, "ic_launcher.png"), "PNG")

        # ic_launcher_round.png
        resized_round = img_round.resize((icon_sz, icon_sz), Image.Resampling.LANCZOS)
        resized_round.save(os.path.join(target_dir, "ic_launcher_round.png"), "PNG")

        # ic_launcher_foreground.png (for adaptive icon)
        resized_fg = img_fg.resize((fg_sz, fg_sz), Image.Resampling.LANCZOS)
        resized_fg.save(os.path.join(target_dir, "ic_launcher_foreground.png"), "PNG")
        
        print(f"Generated {folder}: {icon_sz}x{icon_sz}, fg: {fg_sz}x{fg_sz}")

    # Clean up temp files
    for f in [temp_std_html, temp_fg_html, temp_std_png, temp_fg_png]:
        if os.path.exists(f):
            os.remove(f)

    print("Successfully generated all app icon assets!")

if __name__ == "__main__":
    main()
