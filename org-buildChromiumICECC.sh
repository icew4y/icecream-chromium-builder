#!/bin/bash

if [ "$#" -lt 1 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
   echo "Usage : buildChromiumICECC.sh [Build options] [Test modules] [Options]"
   echo ""
   echo "Build options:"
   echo "  Debug                  Debug build"
   echo "  Release                Release build"
   echo "  Ozone                  Ozone port build (Only release build)"
   echo "  Arm                    ARM port build (Only release build)"
   echo "  ChromeOS               ChromeOS build (Only debug build)"
   echo "  Android                Android build (Only debug build)"
   echo ""
   echo "Test modules:"
   echo "  all_tests              All Tests"
   echo "  blink_tests            Blink Test "
   echo "  content_browsertests   Content module browser test"
   echo "  content_unittests      Content module unit test"
   echo "  unit_tests             Chrome UI unit test"
   echo ""
   echo "Options:"
   echo " --sync                  buildChromiumICECC.sh --sync"
   exit 1
fi

export CCACHE_PREFIX=icecc
export CCACHE_BASEDIR=$HOME/chromium
export CHROME_DEVEL_SANDBOX=/usr/local/sbin/chrome-devel-sandbox
export ICECC_CLANG_REMOTE_CPP=1

# Please set your path to ICECC_VERSION and CHROMIUM_SRC.
export ICECC_VERSION=$HOME/chromium/clang.tar.gz
export CHROMIUM_SRC=$HOME/chromium/src

export PATH=$CHROMIUM_SRC/third_party/llvm-build/Release+Asserts/bin:$PATH
export PATH=$CHROMIUM_SRC/native_client/toolchain/linux_x86/pnacl_newlib/bin/pnacl-clang:$PATH
export CHROMIUM_BUILDTOOLS_PATH=$CHROMIUM_SRC/buildtools

# Do gclient sync.
if [ "$1" == --sync ] || [ "$1" == sync ];
then
  export TMP_CLANG_DIR=tmp-clang
  timestamp=$(date +"%T")
  echo "[$timestamp] Start gclient sync."
  gclient sync
  timestamp=$(date +"%T")
  echo "[$timestamp] Finish gclient sync."

  timestamp=$(date +"%T")
  echo "[$timestamp] Create a new clang based on patched Chromium."
  if [ ! -d $TMP_CLANG_DIR ]; then
    mkdir $TMP_CLANG_DIR
  fi
  cd tmp-clang
  /opt/icecream/bin/icecc-create-env --clang $CHROMIUM_SRC/third_party/llvm-build/Release+Asserts/bin/clang /opt/icecream/bin/compilerwrapper
  mv *.tar.gz $ICECC_VERSION
  cd ..
  rm -rf $TMP_CLANG_DIR
  timestamp=$(date +"%T")
  echo "[$timestamp] Finish gclient sync and create the new clang.tar.gz."
  exit 0
fi

# Set Chromium gn build arguments.
export GN_DEFINES='is_component_build=true'
export GN_DEFINES=$GN_DEFINES' enable_nacl=false treat_warnings_as_errors=false'
export GN_DEFINES=$GN_DEFINES' proprietary_codecs=true ffmpeg_branding="Chrome"'
# export GN_DEFINES=$GN_DEFINES' linux_use_bundled_binutils=false clang_use_chrome_plugins=false cc_wrapper="ccache" ffmpeg_use_atomics_fallback=true use_jumbo_build=false '
export GN_DEFINES=$GN_DEFINES' linux_use_bundled_binutils=false clang_use_chrome_plugins=false ffmpeg_use_atomics_fallback=true use_jumbo_build=false '
export GN_DEFINES=$GN_DEFINES' google_api_key="???" google_default_client_id="??.com" google_default_client_secret="??"'
timestamp=$(date +"%T")
echo "[$timestamp] 1. Configuration"

# Start building Chromium using the gn configuration.
if [ "$1" == Debug ];
then
  export GN_DEFINES=$GN_DEFINES' dcheck_always_on=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Debug "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Release ];
then
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Release "--args=is_debug=false $GN_DEFINES"
elif [ "$1" == GCC ];
then
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/GCC "--args=is_debug=false enable_nacl=false treat_warnings_as_errors=false is_clang=false linux_use_bundled_binutils=false clang_use_chrome_plugins=false ffmpeg_use_atomics_fallback=true use_jumbo_build=true "
elif [ "$1" == Ozone ];
then
  export GN_DEFINES=$GN_DEFINES' use_ozone=true enable_mus=true use_xkbcommon=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Ozone "--args=is_debug=false $GN_DEFINES"
elif [ "$1" == Arm ];
then
  export GN_DEFINES=$GN_DEFINES' target_cpu = "arm"'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Arm "--args=is_debug=false $GN_DEFINES"
elif [ "$1" == ChromeOS ];
then
  export GN_DEFINES=$GN_DEFINES' target_os="chromeos"'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/ChromeOS "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Android ];
then
  export GN_DEFINES=$GN_DEFINES' target_os="android" target_cpu="arm64"'
  echo "GN_DEFINES: "$GN_DEFINES
  gclient runhooks
  gn gen out/Android "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Ozone ];
then
  export GN_DEFINES=$GN_DEFINES' use_ozone=true enable_mus=true use_xkbcommon=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Ozone "--args=is_debug=true $GN_DEFINES"
else
  echo "Undefined Debug or Release."
  exit 0
fi
echo ""

start_timestamp=$(date +"%T")
if [ "$1" == Android ];
then
  echo "[$start_timestamp] 2. Start compiling Chromium on $1 mode with ICECC"
  time ninja -k 166 -j 166 -C out/"$1" chrome_public_apk
else
  echo "[$start_timestamp] 2. Start compiling Chromium on $1 mode with ICECC"
  if [ "$2" == all_tests ]
  then
    export ALL_TESTS='unit_tests components_unittests browser_tests cc_unittests blink_tests app_shell_unittests services_unittests content_browsertests webkit_unit_tests'
    time ninja -k 166 -j 166 -C out/"$1" chrome $ALL_TESTS
  else
    time ninja -k 166 -j 166 -C out/"$1" chrome ${@:2}
  fi
fi

end_timestamp=$(date +"%T")
echo ""
echo "[$end_timestamp] 3. Finish to compile Chromium."
