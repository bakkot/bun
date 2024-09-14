optionx(WEBKIT_VERSION STRING "The version of WebKit to use" DEFAULT "4db913769178d2aaae20413b995bb19e7801d7f7")
optionx(WEBKIT_PREBUILT BOOL "If a pre-built version of WebKit should be used" DEFAULT ON)

if(WEBKIT_PREBUILT)
  set(DEFAULT_WEBKIT_PATH ${CACHE_PATH}/webkit)
else()
  set(DEFAULT_WEBKIT_PATH ${CWD}/src/bun.js/WebKit/WebKitBuild/${CMAKE_BUILD_TYPE})
endif()

optionx(WEBKIT_PATH FILEPATH "The path to the WebKit directory" DEFAULT ${DEFAULT_WEBKIT_PATH})

setx(WEBKIT_INCLUDE_PATH ${WEBKIT_PATH}/include)
setx(WEBKIT_LIB_PATH ${WEBKIT_PATH}/lib)

if(NOT WEBKIT_PREBUILT)
  if(EXISTS ${WEBKIT_PATH}/cmakeconfig.h)
    # You may need to run:
    # make jsc-compile-debug jsc-copy-headers
    include_directories(
      ${WEBKIT_PATH}
      ${WEBKIT_PATH}/JavaScriptCore/Headers/JavaScriptCore
      ${WEBKIT_PATH}/JavaScriptCore/PrivateHeaders
      ${WEBKIT_PATH}/bmalloc/Headers
      ${WEBKIT_PATH}/WTF/Headers
    )
  endif()

  # After this point, only prebuilt WebKit is supported
  return()
endif()

if(WIN32)
  set(WEBKIT_OS "windows")
elseif(APPLE)
  set(WEBKIT_OS "macos")
elseif(UNIX)
  set(WEBKIT_OS "linux")
else()
  message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
  set(WEBKIT_ARCH "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "amd64|x86_64|x64|AMD64")
  set(WEBKIT_ARCH "amd64")
else()
  message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

if(DEBUG)
  set(WEBKIT_SUFFIX "-debug")
elseif(ENABLE_LTO AND NOT WIN32)
  set(WEBKIT_SUFFIX "-lto")
else()
  set(WEBKIT_SUFFIX "")
endif()

set(WEBKIT_NAME bun-webkit-${WEBKIT_OS}-${WEBKIT_ARCH}${WEBKIT_SUFFIX})
set(WEBKIT_FILENAME ${WEBKIT_NAME}.tar.gz)
setx(WEBKIT_DOWNLOAD_URL https://github.com/oven-sh/WebKit/releases/download/autobuild-${WEBKIT_VERSION}/${WEBKIT_FILENAME})

register_command(
  TARGET
    clone-webkit
  COMMENT
    "Cloning WebKit"
  COMMAND
    ${CMAKE_COMMAND}
      -DDOWNLOAD_URL=${WEBKIT_DOWNLOAD_URL}
      -DDOWNLOAD_PATH=${WEBKIT_PATH}
      -P ${CWD}/cmake/scripts/DownloadUrl.cmake
  OUTPUTS
    ${WEBKIT_PATH}/package.json
)

if(APPLE)
  register_command(
    TARGET
      clone-webkit
    TARGET_PHASE
      POST_BUILD
    COMMENT
      "Removing unicode"
    COMMAND
      ${CMAKE_COMMAND} -E rm -rf ${WEBKIT_INCLUDE_PATH}/unicode
  )
endif()

add_dependencies(${bun} clone-webkit)
