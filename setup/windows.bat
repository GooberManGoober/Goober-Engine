@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime 8.2.2
haxelib install openfl 9.4.1
haxelib install flixel 5.6.1
haxelib install flixel-addons 3.2.2
haxelib install flixel-ui 2.5.0
haxelib install flixel-tools 1.5.1
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib remove flxanimate
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git hxCodec https://github.com/polybiusproxy/hxCodec
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxcpp 4.3.2
echo Finished!
pause
