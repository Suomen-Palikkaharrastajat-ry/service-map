{ pkgs, ... }:
{
  packages = with pkgs; [
    git
    tippecanoe
    gdal
    python3
    curl
    unzip
  ];

  enterShell = ''
    echo ""
    echo "── basemap dev environment ──────────────────────────"
    echo "  tippecanoe: $(tippecanoe --version 2>&1 | head -n1)"
    echo "  gdal:       $(ogr2ogr --version)"
    echo ""
    echo "  make basemap  — generate PMTiles basemap into dist/"
    echo ""
  '';
}
