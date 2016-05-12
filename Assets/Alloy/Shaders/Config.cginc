// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Config.cginc
/// @brief User configuration options.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_CONFIG_CGINC
#define ALLOY_CONFIG_CGINC

#include "Assets/Alloy/Shaders/Unity/UnityStandardConfig.cginc"

/// Flag provided for third-party integration.
#define ALLOY_VERSION 3.27

/// Enables clamping of all shader outputs to prevent blending and bloom errors.
#define ALLOY_CONFIG_ENABLE_HDR_CLAMP 1

/// Max HDR intensity for lighting and emission.
#define ALLOY_CONFIG_HDR_CLAMP_MAX_INTENSITY 100.0

/// Enables capping tessellation quality via the global _MinEdgeLength property.
#define ALLOY_CONFIG_ENABLE_TESSELLATION_MIN_EDGE_LENGTH 0

/// Enables the legacy behavior for the CarPaint shader flake map.
#define ALLOY_CONFIG_LEGACY_CARPAINT_FLAKES 0

#endif // ALLOY_CONFIG_CGINC
