cmake_minimum_required(VERSION 3.4.1)
# Target Project
project (luajitclient)
include(ExternalProject)
set(EXT "so")
set(HOSTCC clang)
set(HOSTLD clang)
if (ANDROID_ABI) 
	set(TGT_AR "${CMAKE_AR} rs")
	set(TGT_CMD "${CMAKE_C_COMPILER} --target=${CMAKE_CXX_COMPILER_TARGET} --sysroot=${CMAKE_SYSROOT}")
	set(TGT_STRIP "${ANDROID_TOOLCHAIN_PREFIX}strip${ANDROID_TOOLCHAIN_SUFFIX}")
	set(TGT_SYS Linux)
	set(TGT_OS android)
	set(ARCH ${ANDROID_ABI})
	set(BLD_CMD make  LUAJIT_ENABLE_LUA52COMPAT=ON
		HOST_CC=clang HOST_LD=clang CC=${TGT_CMD}
		TARGET_SYS=${TGT_SYS} TARGET_LD=${TGT_CMD}
		TARGET_AR=${TGT_AR}  TARGET_STRIP="${TGT_STRIP}" 
		DESTDIR=${CMAKE_INSTALL_PREFIX}/${TGT_OS}-${ARCH} PREFIX= 
		install)
else()
	execute_process(COMMAND xcrun --sdk ${OS} --show-sdk-path 
		OUTPUT_VARIABLE SYSROOT
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	execute_process(COMMAND xcode-select -print-path
		OUTPUT_VARIABLE DEVDIR
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	string(REGEX REPLACE "(\r|\n)+$" "" DEVDIR "${DEVDIR}")
	message("BUILD with: ${SYSROOT}")
	set(CROSS ${DEVDIR}/Toolchains/XcodeDefault.xctoolchain/usr/bin/)
	if (( OS STREQUAL iphoneos) OR (OS STREQUAL iphonesimulator))
		if (NOT DEPLOY_VERSION_MIN) 
			set(DEPLOY_VERSION_MIN 12.4)
		endif()
		set(TGT_SYS iOS)
		if ( OS STREQUAL iphoneos)
			message("BUILD for iOS ")
			set(TGT_OS iOS)
		else()
			message("BUILD for iOS simulator")
			set(TGT_OS iOSim)
			set(TGTSUFFIX -simulator)
		endif()
		message("build for ${OS}")
		set(TGTFLAGS "${TGTFLAGS} -fembed-bitcode -target ${ARCH}-apple-ios${DEPLOY_VERSION_MIN}${TGTSUFFIX} -isysroot ${SYSROOT}")
	else()
		if (NOT DEPLOY_VERSION_MIN) 
			set(DEPLOY_VERSION_MIN 10.9)
		endif()
		set(TGT_OS macos)
		set(TGT_SYS Darwin)
		set(TGTMORE "MACOSX_DEPLOYMENT_TARGET=${DEPLOY_VERSION_MIN}")	
		set(EXT dylib)
		message("BUILD for MacOS ")
		#on macos should not set embed-bitcode -- or image_base unable to set
		set(TGTFLAGS "${TGTFLAGS} -target ${ARCH}-apple-macos${DEPLOY_VERSION_MIN} -isysroot ${SYSROOT}")
	endif()
	set(TGTXSHLDFLAGS "-fPIC -dynamiclib -single_module")
	set(BLD_CMD make LUAJIT_ENABLE_LUA52COMPAT=ON	Q=	
		HOST_CC=${HOSTCC} HOST_LD=${HOSTLD} CC=clang CROSS=${CROSS}
		TARGET_FLAGS=${TGTFLAGS}
		TARGET_SYS=${TGT_SYS} ${TGTMORE}
		TARGET_XSHLDFLAGS=${TGTXSHLDFLAGS}
		DESTDIR=${CMAKE_INSTALL_PREFIX}/${TGT_OS}-${ARCH} PREFIX= 
		)
endif()
# This Project Depends on External Project(s)
ExternalProject_Add (mluajit
	PREFIX          ${CMAKE_CURRENT_BINARY_DIR}/luajit
	# Begin: Download Archive from Web Server
	#URL
	#URL_HASH        SHA1=<expected_sha1sum_of_above_tgz_file>
	GIT_REPOSITORY  https://github.com/openresty/luajit2.git
	GIT_TAG         "origin/v2.1-agentzh"
	GIT_SHALLOW     ON
	GIT_PROGRESS ON
	#DOWNLOAD_NO_PROGRESS ON
	# End: Download Archive from Web Server
	UPDATE_COMMAND    ""
	CONFIGURE_COMMAND ""
	BUILD_IN_SOURCE ON
	BUILD_COMMAND ${BLD_CMD} all
	BUILD_ALWAYS ON
	INSTALL_COMMAND ${BLD_CMD} install
	)
ExternalProject_Add_StepTargets(mluajit install)
# The above ExternalProject_Add(...) construct wil take care of \
# 1. Downloading sources
# 2. Building Object files
# 3. Install under DCMAKE_INSTALL_PREFIX Directory

# Acquire Installation Directory of
set(install_dir ${CMAKE_INSTALL_PREFIX}/${TGT_OS}-${ARCH})

# Begin: Importing Headers & Library of Third Party built using ExternalProject_Add(...)
# Include PATH that has headers required by Target Project
include_directories (${install_dir}/include/luajit-2.1)

# Import librarues from External Project required by Target Project
add_library (myluajit SHARED IMPORTED)
add_dependencies(myluajit mluajit-install)
set_target_properties (myluajit PROPERTIES IMPORTED_LOCATION ${install_dir}/lib/libluajit-5.1.${EXT})

add_custom_target(libluajit ALL echo built
	DEPENDS myluajit
	)
