/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.xtreme3d.types;

// Game Maker color constants:
enum double c_black = 0.0;
enum double c_dkgray = 4210752.0;
enum double c_gray = 8421504.0;
enum double c_ltgray = 12632256.0;
enum double c_white = 16777215.0;
enum double c_aqua = 16776960.0;
enum double c_blue = 16711680.0;
enum double c_fuchsia = 16711935.0;
enum double c_green = 32768.0;
enum double c_lime = 65280.0;
enum double c_maroon = 128.0;
enum double c_navy = 8388608.0;
enum double c_olive = 32896.0;
enum double c_purple = 8388736.0;
enum double c_red = 255.0;
enum double c_silver = 12632256.0;
enum double c_teal = 8421376.0;
enum double c_yellow = 65535.0;
enum double c_orange = 33023.0;

// Xtreme3D constants:

// Object sorting
enum double osInherited = 0;
enum double osNone = 1;
enum double osRenderFarthestFirst = 2;
enum double osRenderBlendedLast = 3;
enum double osRenderNearestFirst = 4;

// Visibility culling
enum double vcNone = 0;
enum double vcInherited = 1;
enum double vcObjectBased = 2;
enum double vcHierarchical = 3;

// VSync
enum double vsmSync = 0;
enum double vsmNoSync = 1;

// Antialiasing
enum double aaDefault = 0;
enum double aaNone = 1;
enum double aa2x = 2;
enum double aa2xHQ = 3;
enum double aa4x = 4;
enum double aa4xHQ = 5;

// Dummycube invariance
enum double cimNone = 0;
enum double cimPosition = 1;
enum double cimOrientation = 2;

// Camera projection style
enum double csPerspective = 0;
enum double csOrthogonal = 1;
enum double csOrtho2D = 2;
enum double csInfinitePerspective = 3;

// Light source type
enum double lsSpot = 0;
enum double lsOmni = 1;
enum double lsParallel = 2;

// Normal direction
enum double ndOutside = 0;
enum double ndInside = 1;

// Animation mode
enum double aamNone = 0;
enum double aamPlayOnce = 1;
enum double aamLoop = 2;
enum double aamBounceForward = 3;
enum double aamBounceBackward = 4;
enum double aamLoopBackward = 5;

// Frame interpolation
enum double afpNone = 0;
enum double afpLinear = 1;

// Terrain quality style
enum double hrsFullGeometry = 0;
enum double hrsTesselated = 1;

// Terrain occlusion tesselate
enum double totTesselateAlways = 0;
enum double totTesselateIfVisible = 1;

//
enum double scNoOverlap = 0;
enum double scContainsFully = 1;
enum double scContainsPartially = 2;

// Polygon mode
enum double pmFill = 0;
enum double pmLines = 1;
enum double pmPoints = 2;

// Texture mapping mode
enum double tmmUser = 0;
enum double tmmObjectLinear = 1;
enum double tmmEyeLinear = 2;
enum double tmmSphere = 3;
enum double tmmCubeMapReflection = 4;
enum double tmmCubeMapNormal = 5;
enum double tmmCubeMapLight0 = 6;
enum double tmmCubeMapCamera = 7;

// Texture image alpha
enum double tiaDefault = 0;
enum double tiaAlphaFromIntensity = 1;
enum double tiaSuperBlackTransparent = 2;
enum double tiaLuminance = 3;
enum double tiaLuminanceSqrt = 4;
enum double tiaOpaque = 5;
enum double tiaTopLeftPointColorTransparent = 6;
enum double tiaInverseLuminance = 7;
enum double iaInverseLuminanceSqrt = 8;

// Texture mode
enum double tmDecal = 0;
enum double tmModulate = 1;
enum double tmBlend = 2;
enum double tmReplace = 3;

// Blending mode
enum double bmOpaque = 0;
enum double bmTransparency = 1;
enum double bmAdditive = 2;
enum double bmAlphaTest50 = 3;
enum double bmAlphaTest100 = 4;
enum double bmModulate = 5;

// Texture filter
enum double miNearest = 0;
enum double miLinear = 1;
enum double miNearestMipmapNearest = 2;
enum double miLinearMipmapNearest = 3;
enum double miNearestMipmapLinear = 4;
enum double miLinearMipmapLinear = 5;
enum double maNearest = 0;
enum double maLinear = 1;

// Face culling
enum double fcBufferDefault = 0;
enum double fcCull = 1;
enum double fcNoCull = 2;

// Texture format
enum double tfDefault = 0;
enum double tfRGB = 1;
enum double tfRGBA = 2;
enum double tfRGB16 = 3;
enum double tfRGBA16 = 4;
enum double tfAlpha = 5;
enum double tfLuminance = 6;
enum double tfLuminanceAlpha = 7;
enum double tfIntensity = 8;
enum double tfNormalMap = 9;
enum double tfRGBAFloat16 = 10;
enum double tfRGBAFloat32 = 11;

// Texture compression
enum double tcDefault = 0;
enum double tcNone = 1;
enum double tcStandard = 2;
enum double tcHighQuality = 3;
enum double tcHighSpeed = 4;

// Texture filtering quality
enum double tfIsotropic = 0;
enum double tfAnisotropic = 1;

// Blur preset
enum double pNone = 0;
enum double pGlossy = 1;
enum double pBeastView = 2;
enum double pOceanDepth = 3;
enum double pDream = 4;
enum double pOverBlur = 5;

// Skybox material
enum double sbmTop = 0;
enum double sbmBottom = 1;
enum double sbmLeft = 2;
enum double sbmRight = 3;
enum double sbmFront = 4;
enum double sbmBack = 5;
enum double sbmClouds = 6;

// Skybox style
enum double sbsFull = 0;
enum double sbsTopHalf = 1;
enum double sbsBottomHalf = 2;
enum double sbsTopTwoThirds = 3;
enum double sbsTopHalfClamped = 4;

// Lines spline mode
enum double lsmLines = 0;
enum double lsmCubicSpline = 1;
enum double lsmBezierSpline = 2;
enum double lsmNURBSCurve = 3;
enum double lsmSegments = 4;

// Lines nodes aspect
enum double lnaInvisible = 0;
enum double lnaAxes = 1;
enum double lnaCube = 2;
enum double lnaDodecahedron = 3;

// Trail mark style
enum double msUp = 0;
enum double msDirection = 1;
enum double msFaceCamera = 2;

// Shadowvolume mode
enum double svmAccurate = 0;
enum double svmDarkening = 1;
enum double svmOff = 2;

// Mirror shape
enum double msRect = 0;
enum double msDisk = 1;

// 
enum double ccsDCEStandard = 0;
enum double ccsCollisionStandard = 1;
enum double ccsHybrid = 2;

// DCE slide or bounce
enum double csbSlide = 0;
enum double csbBounce = 1;

// DCE collider shape
enum double csEllipsoid = 0;
enum double csBox = 1;
enum double csFreeform = 2;
enum double csTerrain = 3;

// ODE step
enum double osmStep = 0;
enum double osmStepFast = 1;
enum double osmQuickStep = 2;

// Partition culling
enum double cmFineCulling = 0;
enum double cmGrossCulling = 1;

// Grid line style
enum double glsSegments = 0;
enum double glsLine = 1;

// Grid parts
enum double gpXY = 0;
enum double gpYZ = 1;
enum double gpXZ = 2;
enum double gpXYZ = 3;

// Font
enum double teUTF8 = 0;
enum double teWindows = 1;

