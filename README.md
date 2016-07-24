#Jetpack Dude
A work-in-progress Game Boy game by DevEd.

#Building the ROM
In order to build the ROM, follow these steps:

Windows:
Just run build.bat.

Mac OS X:

1. Make sure you have Xcode installed. If not, you can get it for free from the App Store.

2. Run the following in Terminal (make sure you have admin!):

   git clone https://github.com/bentley/rgbds

   cd rgbds

   sudo make install

   cd ..

3. Run build.sh in Terminal. If it says "permission denied", then type "chmod 750 build.sh" and try again.

LINUX (UNTESTED):

1. Run "sudo apt-get install gcc bison git" in whatever terminal emulator you use (make sure you have admin!)

2. Once that's done, run the following (make sure you have admin!):

   git clone https://github.com/bentley/rgbds

   cd rgbds

   sudo make install

   cd ..

3. Run build.sh.
