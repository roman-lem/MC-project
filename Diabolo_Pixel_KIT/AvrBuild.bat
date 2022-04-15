@ECHO OFF
"D:\Programs\avr\AvrAssembler2\avrasm2.exe" -S "D:\RT\Diabolo_Pixel_KIT\labels.tmp" -fI -W+ie -C V2E -o "D:\RT\Diabolo_Pixel_KIT\Diabolo_Pixel_KIT.hex" -d "D:\RT\Diabolo_Pixel_KIT\Diabolo_Pixel_KIT.obj" -e "D:\RT\Diabolo_Pixel_KIT\Diabolo_Pixel_KIT.eep" -m "D:\RT\Diabolo_Pixel_KIT\Diabolo_Pixel_KIT.map" "D:\RT\Diabolo_Pixel_KIT\Diabolo_Pixel_KIT.asm"
