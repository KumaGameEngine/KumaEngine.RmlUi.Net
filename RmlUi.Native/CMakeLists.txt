cmake_minimum_required(VERSION 3.14...3.23)

project(RmlUiNative VERSION 1.0 LANGUAGES CXX)

# Configure output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DCMAKE_GENERATOR_PLATFORM})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Platform-specific compiler setups
if(WIN32)    
    set(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE "x64")

    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
        # Automatically select MultiThreadedDebug for Debug and MultiThreaded for Release configs
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
elseif(LINUX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -I. -Wall -Werror")
endif()

# Add external libraries
add_subdirectory("ext/freetype")
set(FREETYPE_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/build/lib/Debug/freetyped.lib")
set(FREETYPE_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/ext/freetype/include")

set(BUILD_SHARED_LIBS OFF)
add_subdirectory("ext/RmlUi")

# Main library target
add_library(${PROJECT_NAME} SHARED
    "src/Context.cpp"
    "src/Element.cpp"
    "src/ElementDocument.cpp"
    "src/ElementFormControlInput.cpp"
    "src/ElementCustom.cpp"
    "src/ElementInstancer.cpp"
    "src/Variant.cpp"
    "src/VariableDefinition.cpp"
    "src/StructHandle.cpp"
    "src/Dictionary.cpp"
    "src/DataVariable.cpp"
    "src/DataModelHandle.cpp"
    "src/DataModelConstructor.cpp"
    "src/Event.cpp"
    "src/EventInstancer.cpp"
    "src/EventListener.h"
    "src/EventListenerInstancer.cpp"
    "src/Box.cpp"
    "src/RenderManager.cpp"
    "src/RenderInterface.cpp"
    "src/SystemInterface.cpp"
    "src/FileInterface.cpp"
    "src/Plugin.cpp"
    "src/StyleSheetContainer.cpp"
    "src/StyleSheetSpecification.cpp"
    "src/XMLAttributes.cpp"
    "src/PropertyDefinition.cpp"
    "src/Property.cpp"
    "src/Rml.cpp"
    "src/Debugger.cpp"
    "src/Util.h"
    "src/Buffer.cpp"
    "include/Buffer.h"
)

# Include directories configuration
include_directories(${PROJECT_NAME}
    PRIVATE include
)

# Compile Definitions
target_compile_definitions(${PROJECT_NAME} PUBLIC "RMLUI_STATIC_LIB")

# Link Dependencies
target_link_libraries(${PROJECT_NAME}
    freetype
    RmlUi::Core
    RmlUi::Debugger
)

# Apply Windows linker options cleanly to our target only
if(WIN32)
    target_link_options(${PROJECT_NAME} PRIVATE "/SUBSYSTEM:WINDOWS" "/DEBUG:FASTLINK")
endif()