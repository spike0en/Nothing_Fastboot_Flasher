# Nothing & CMF Fastboot Flashing Scripts

### About 📋:

- This collection of fastboot flashing scripts is designed for flashing stock [Nothing OS firmware](https://github.com/spike0en/nothing_archive) on Nothing & CMF devices, supporting both Windows and bash platforms.
- The script helps users revert to stock ROMs or unbrick devices, especially when the super partition size remains unchanged. It's useful when custom recoveries fail to flash the stock ROM due to partition issues. The script can also be adapted to flash custom ROMs that use the same partition size as the stock firmware.

### Usage ⚙️:

- Refer to [this guide](https://github.com/spike0en/nothing_archive?tab=readme-ov-file#flashing-the-stock-rom-using-fastboot-) for preparing the flashing folder with the respective stock firmware images and run the flashing script for your respective platform.
- Alternatively, users can dump the `payload.bin` using [payload_dumper_go](https://github.com/ssut/payload-dumper-go) by unpacking a full stock firmware zip and then place the script suited to your operating system in the directory where the `*.img` files from `payload.bin` have been extracted. Finally, reboot your device to the bootloader and then run the flashing script.
- The script can be executed by double-clicking the `flash_all.bat` file on Windows or by running the following command in a terminal on a bash-supported operating system (after navigating to the directory where the `*.img` files from `payload.bin` have been extracted):

  ```bash
  chmod +x flash_all.sh
  bash flash_all.sh
  ```

### Notes 📝:

- A working internet connection is required to download the latest version of `platform-tools` if it's not already present in the working directory.
- Make sure to download the script that corresponds to your device model's codename and platform (Windows or bash).
- The script flashes the ROM on slot A and erases the partitions on slot B to free up space for the new partitions. Slot switching is not included, as the inactive slot would lose data. The script focuses on flashing partitions to slot A.
- Ensure that you have working [Google USB drivers](https://developer.android.com/studio/run/win-usb) installed before running the script.
- Scripts must be executed in bootloader mode with fastboot access. Also, verify that the `Android Bootloader Interface` is listed in your Windows Device Manager.
- Do not reboot your device into the system before confirming all partitions have been successfully flashed.
- For best results, use the latest Windows installation with functional `curl`, `tar`, and `PowerShell`. Missing binaries in modified installations can cause errors.
- If the `platform-tools` download or unzip process fails, or if `fastboot.exe` is not executable despite following the above steps, manually download the latest version from [here](https://developer.android.com/tools/releases/platform-tools). Unzip it into the same directory as the script, ensuring the following structure:

  ```bash
  ├── platform-tools-latest/
  │   ├── platform-tools/
  │   │   ├── ...binaries
  ├── flashing script (flash_all.bat / flash_all.sh)
  └── Required stock firmware image files
  ```

### Acknowledgments 🤝:

- Special thanks to [HELLBOY017](https://github.com/HELLBOY017/Pong_fastboot_flasher), [AntoninoScordino](https://github.com/nothing-Pacman/flashtool), and all [contributors](https://github.com/HELLBOY017/Pong_fastboot_flasher/graphs/contributors) for refining the scripts for Qualcomm and MediaTek platforms.

---
