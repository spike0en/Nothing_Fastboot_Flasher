#!/usr/bin/env bash

echo "#################################"
echo "#  Pacman Fastboot ROM Flasher  #"
echo "#    t.me/s/Nothing_Archive     #"
echo "#################################"

##----------------------------------------------------------##
if [ ! -d "$(pwd)/platform-tools" ]; then
    if [[ $OSTYPE == 'darwin'* ]]; then
        fastboot_dl="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
    else
        fastboot_dl="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
    fi
    curl -L "$fastboot_dl" -o "$(pwd)/platform-tools-latest.zip"
    unzip "$(pwd)/platform-tools-latest.zip"
    rm "$(pwd)/platform-tools-latest.zip"
fi

fastboot="$(pwd)/platform-tools/fastboot"

if [ ! -f "$fastboot" ] || [ ! -x "$fastboot" ]; then
    echo "Fastboot cannot be executed, exiting"
    exit 1
fi

# Partition Variables
boot_partitions="boot dtbo init_boot vendor_boot"
firmware_partitions="apusys audio_dsp ccu connsys_bt connsys_gnss connsys_wifi dpm gpueb gz lk logo mcf_ota mcupm md1img mvpu_algo pi_img scp spmfw sspm tee vcp"
logical_partitions="odm odm_dlkm product vendor vendor_dlkm system_ext system system_dlkm"
vbmeta_partitions="vbmeta vbmeta_system vbmeta_vendor"

# Default to slot 'a'
SLOT="a"

function SetActiveSlot {
    if ! "$fastboot" --set-active="$SLOT"; then
        echo "Error occurred while switching to slot $SLOT. Aborting"
        exit 1
    fi
}

function handle_fastboot_error { 
    case "$FASTBOOT_ERROR" in
        [nN] )
            exit 1
            ;;
    esac
}

function WipeData {
    if ! "$fastboot" -w; then
        read -rp "Wiping data failed, Continue? If unsure say N, Pressing Enter key without any input will continue the script. (Y/N)" FASTBOOT_ERROR
        handle_fastboot_error
    fi
}

function FlashImage {
    if ! "$fastboot" flash $1 $2; then
        read -rp "Flashing $2 failed, Continue? If unsure say N, Pressing Enter key without any input will continue the script. (Y/N)" FASTBOOT_ERROR
        handle_fastboot_error
    fi
}

function DeleteLogicalPartition {
    if ! "$fastboot" delete-logical-partition $1; then
        if ! echo $1 | grep -q "cow"; then
            read -rp "Deleting $1 partition failed, Continue? If unsure say N, Pressing Enter key without any input will continue the script. (Y/N)" FASTBOOT_ERROR
            handle_fastboot_error
        fi
    fi
}

function CreateLogicalPartition {
    if ! "$fastboot" create-logical-partition $1 $2; then
        read -rp "Creating $1 partition failed, Continue? If unsure say N, Pressing Enter key without any input will continue the script. (Y/N)" FASTBOOT_ERROR
        handle_fastboot_error
    fi
}

function ResizeLogicalPartition {
    if [ $junk_logical_partitions != "null" ]; then
        for i in $junk_logical_partitions; do
            for s in a b; do 
                DeleteLogicalPartition "${i}_${s}-cow"
                DeleteLogicalPartition "${i}_${s}"
            done
        done
    fi

    for i in $logical_partitions; do
        for s in a b; do 
            DeleteLogicalPartition "${i}_${s}-cow"
            DeleteLogicalPartition "${i}_${s}"
            CreateLogicalPartition "${i}_${s}" "1"
        done
    done
}

function WipeSuperPartition {
    if ! "$fastboot" wipe-super super_empty.img; then 
        echo "Wiping super partition failed. Fallback to deleting and creating logical partitions"
        ResizeLogicalPartition
    fi
}

function RebootFastbootD {
    echo "##########################"             
    echo "# REBOOTING TO FASTBOOTD #"       
    echo "##########################"
    if ! "$fastboot" reboot fastboot; then
        echo "Error occurred while rebooting to fastbootd. Aborting"
        exit 1
    fi
}

echo "#############################"
echo "# CHECKING FASTBOOT DEVICES #"
echo "#############################"
"$fastboot" devices

echo "#############################"
echo "# CHANGING ACTIVE SLOT TO $SLOT #"
echo "#############################"
SetActiveSlot

echo "###################"
echo "# FORMATTING DATA #"
echo "###################"
read -rp "Wipe Data? (Y/N) " DATA_RESP
case "$DATA_RESP" in
    [yY] )
        WipeData
        ;;
esac

echo "############################"
echo "# FLASHING BOOT PARTITIONS #"
echo "############################"
read -rp "Flash images on both slots? If unsure, say N. (Y/N) " SLOT_RESP
for i in $boot_partitions; do
    case "$SLOT_RESP" in
        [yY] )
            for s in a b; do
                FlashImage "${i}_${s}" "$i.img"
            done
            ;;
        * )
            FlashImage "$i" "$i.img"
            ;;
    esac
done

echo "#####################"
echo "# FLASHING FIRMWARE #"
echo "#####################"
for i in $firmware_partitions; do
    case "$SLOT_RESP" in
        [yY] )
            for s in a b; do
                FlashImage "${i}_${s}" "$i.img"
            done
            ;;
        * )
            FlashImage "$i" "$i.img"
            ;;
    esac
done

# 'preloader_raw.img' must be flashed at a different partition name
if [ "$SLOT" = "--slot=all" ]; then
    for s in a b; do
        FlashImage "preloader_${s}" "preloader_raw.img"
    done
else
    FlashImage "preloader_${SLOT}" "preloader_raw.img"
fi

echo "###################"
echo "# FLASHING VBMETA #"
echo "###################"
read -rp "Disable android verified boot?, If unsure, say N. Bootloader won't be lockable if you select Y. (Y/N) " VBMETA_RESP
case "$VBMETA_RESP" in
    [yY] )
        if [ "$SLOT_RESP" = "y" ] || [ "$SLOT_RESP" = "Y" ]; then
            for s in a b; do
                FlashImage "vbmeta_${s} --disable-verity --disable-verification" "vbmeta.img"
            done
        else
            FlashImage "vbmeta --disable-verity --disable-verification" "vbmeta.img"
        fi
        ;;
    * )
        if [ "$SLOT_RESP" = "y" ] || [ "$SLOT_RESP" = "Y" ]; then
            for s in a b; do
                FlashImage "vbmeta_${s}" "vbmeta.img"
            done
        else
            FlashImage "vbmeta" "vbmeta.img"
        fi
        ;;
esac

echo "##########################"
echo "# REBOOTING TO FASTBOOTD #"
echo "##########################"
RebootFastbootD

echo "#############"
echo "# REBOOTING #"
echo "#############"
read -rp "Reboot to system? If unsure, say Y. (Y/N) " REBOOT_RESP
case "$REBOOT_RESP" in
    [yY] )
        "$fastboot" reboot
        ;;
esac

echo "########"
echo "# DONE #"
echo "########"
echo "Stock firmware restored."
echo "You may now optionally re-lock the bootloader if you haven't disabled android verified boot."
