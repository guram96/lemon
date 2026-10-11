/// Built-in emulator manifest.
///
/// Detection paths, core-to-system rows, and argument templates live in this
/// JSON document. A leading `~` is the probe home.
const emulatorManifestJson = r'''
{
  "emulators": [
    {
      "id": "retroarch",
      "name": "RetroArch",
      "kind": "retroarch",
      "cores": [
        {"match": "nestopia_libretro", "systems": ["nes"]},
        {"match": "fceumm_libretro", "systems": ["nes"]},
        {"match": "snes9x_libretro", "systems": ["snes"]},
        {"match": "mupen64plus_next_libretro", "systems": ["n64"]},
        {"match": "gambatte_libretro", "systems": ["gb", "gbc"]},
        {"match": "mgba_libretro", "systems": ["gb", "gbc", "gba"]},
        {"match": "melonds_libretro", "systems": ["nds"]},
        {"match": "genesis_plus_gx_libretro", "systems": ["megadrive", "genesis"]},
        {"match": "swanstation_libretro", "systems": ["psx"]},
        {"match": "mednafen_psx_hw_libretro", "systems": ["psx"]},
        {"match": "pcsx2_libretro", "systems": ["ps2"]},
        {"match": "dolphin_libretro", "systems": ["gc", "wii"]},
        {"match": "ppsspp_libretro", "systems": ["psp"]},
        {"match": "flycast_libretro", "systems": ["dreamcast"]},
        {"match": "fbneo_libretro", "systems": ["fbneo", "arcade"]},
        {"match": "mame_libretro", "systems": ["mame", "arcade"]}
      ],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/RetroArch.app"},
            {"path": "~/Applications/RetroArch.app"}
          ],
          "coresDirectories": [
            "~/Library/Application Support/RetroArch/cores"
          ],
          "coreExtension": ".dylib",
          "args": ["-L", "{core}", "{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "retroarch"},
            {"path": "/usr/bin/retroarch"}
          ],
          "coresDirectories": ["~/.config/retroarch/cores"],
          "coreExtension": ".so",
          "args": ["-L", "{core}", "{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/RetroArch/retroarch.exe"},
            {"path": "C:/RetroArch-Win64/retroarch.exe"},
            {"path": "~/RetroArch-Win64/retroarch.exe"}
          ],
          "coresDirectories": ["~/AppData/Roaming/RetroArch/cores"],
          "coreExtension": ".dll",
          "args": ["-L", "{core}", "{rom}"]
        }
      }
    },
    {
      "id": "snes9x",
      "name": "Snes9x",
      "kind": "standalone",
      "systems": ["snes"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/Snes9x.app"},
            {"path": "~/Applications/Snes9x.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "snes9x"},
            {"path": "/usr/games/snes9x"},
            {"path": "/usr/local/bin/snes9x"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/Snes9x/snes9x-x64.exe"},
            {"path": "~/Snes9x/snes9x-x64.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "mgba",
      "name": "mGBA",
      "kind": "standalone",
      "systems": ["gb", "gbc", "gba"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/mGBA.app"},
            {"path": "~/Applications/mGBA.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "mgba"},
            {"path": "/usr/bin/mgba"},
            {"path": "/usr/local/bin/mgba"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/mGBA/mGBA.exe"},
            {"path": "~/mGBA/mGBA.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "duckstation",
      "name": "DuckStation",
      "kind": "standalone",
      "systems": ["psx"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/DuckStation.app"},
            {"path": "~/Applications/DuckStation.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "duckstation-qt"},
            {"path": "/usr/bin/duckstation-qt"},
            {"path": "/usr/local/bin/duckstation-qt"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/DuckStation/duckstation-qt-x64-ReleaseLTCG.exe"},
            {"path": "~/DuckStation/duckstation-qt-x64-ReleaseLTCG.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "pcsx2",
      "name": "PCSX2",
      "kind": "standalone",
      "systems": ["ps2"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/PCSX2.app"},
            {"path": "~/Applications/PCSX2.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "pcsx2"},
            {"path": "/usr/games/pcsx2"},
            {"path": "/usr/local/bin/pcsx2"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/PCSX2/pcsx2-qt.exe"},
            {"path": "~/PCSX2/pcsx2-qt.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "dolphin",
      "name": "Dolphin",
      "kind": "standalone",
      "systems": ["gc", "wii"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/Dolphin.app"},
            {"path": "~/Applications/Dolphin.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "dolphin-emu"},
            {"path": "/usr/games/dolphin-emu"},
            {"path": "/usr/local/bin/dolphin-emu"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/Dolphin/Dolphin.exe"},
            {"path": "~/Dolphin/Dolphin.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "ppsspp",
      "name": "PPSSPP",
      "kind": "standalone",
      "systems": ["psp"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/PPSSPPSDL.app"},
            {"path": "/Applications/PPSSPP.app"},
            {"path": "~/Applications/PPSSPPSDL.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "ppsspp"},
            {"path": "/usr/games/ppsspp"},
            {"path": "/usr/local/bin/ppsspp"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/PPSSPP/PPSSPPWindows64.exe"},
            {"path": "~/PPSSPP/PPSSPPWindows64.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "melonds",
      "name": "melonDS",
      "kind": "standalone",
      "systems": ["nds"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/melonDS.app"},
            {"path": "~/Applications/melonDS.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "melonDS"},
            {"path": "/usr/bin/melonDS"},
            {"path": "/usr/local/bin/melonDS"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/melonDS/melonDS.exe"},
            {"path": "~/melonDS/melonDS.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "flycast",
      "name": "Flycast",
      "kind": "standalone",
      "systems": ["dreamcast"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/Flycast.app"},
            {"path": "~/Applications/Flycast.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "flycast"},
            {"path": "/usr/bin/flycast"},
            {"path": "/usr/local/bin/flycast"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/Flycast/flycast.exe"},
            {"path": "~/Flycast/flycast.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "azahar",
      "name": "Azahar",
      "kind": "standalone",
      "systems": ["n3ds"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/Azahar.app"},
            {"path": "~/Applications/Azahar.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "azahar"},
            {"path": "/usr/bin/azahar"},
            {"path": "/usr/local/bin/azahar"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/Azahar/azahar.exe"},
            {"path": "~/Azahar/azahar.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    },
    {
      "id": "rpcs3",
      "name": "RPCS3",
      "kind": "standalone",
      "systems": ["ps3"],
      "platforms": {
        "macos": {
          "executables": [
            {"path": "/Applications/RPCS3.app"},
            {"path": "~/Applications/RPCS3.app"}
          ],
          "args": ["{rom}"]
        },
        "linux": {
          "executables": [
            {"findOnPath": "rpcs3"},
            {"path": "/usr/bin/rpcs3"},
            {"path": "/usr/local/bin/rpcs3"}
          ],
          "args": ["{rom}"]
        },
        "windows": {
          "executables": [
            {"path": "C:/Program Files/RPCS3/rpcs3.exe"},
            {"path": "~/RPCS3/rpcs3.exe"}
          ],
          "args": ["{rom}"]
        }
      }
    }
  ]
}
''';
