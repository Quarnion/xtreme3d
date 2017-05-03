library xtreme3d;
uses
  Windows, Messages, Classes, Controls, StdCtrls, ExtCtrls, Dialogs, SysUtils, TypInfo,
  GLScene, GLObjects, GLWin32FullScreenViewer, GLMisc, GLGraph,
  GLCollision, GLTexture, OpenGL1x, VectorGeometry, Graphics,
  GLVectorFileObjects, GLWin32Viewer, GLSpaceText, GLGeomObjects, GLCadencer,
  Jpeg, Tga, DDS, PNG, GLProcTextures, Spin, GLVfsPAK, GLCanvas, GLGraphics, GLPortal,
  GLHUDObjects, GLBitmapFont, GLWindowsFont, GLImposter, VectorTypes, GLUtils,
  GLPolyhedron, GLTeapot, GLzBuffer, GLFile3DS, GLFileGTS, GLFileLWO, GLFileMD2,
  GLFileMD3, Q3MD3, GLFileMS3D, GLFileMD5, GLFileNMF, GLFileNurbs, GLFileObj, GLFileOCT,
  GLFilePLY, GLFileQ3BSP, GLFileSMD, GLFileSTL, GLFileTIN, GLFileB3D,
  GLFileMDC, GLFileVRML, GLFileLOD, GLFileX, GLFileCSM, GLFileLMTS, GLFileASE, GLFileDXS,
  GLPhongShader, VectorLists, GLThorFX, GLFireFX,
  GLTexCombineShader, GLBumpShader, GLCelShader, GLContext, GLTerrainRenderer, GLHeightData,
  GLBlur, GLSLShader, GLMultiMaterialShader, GLOutlineShader, GLHiddenLineShader,
  ApplicationFileIO, GLMaterialScript, GLWaterPlane, GeometryBB, GLExplosionFx,
  GLSkyBox, GLShadowPlane, GLShadowVolume, GLSkydome, GLLensFlare, GLDCE,
  GLNavigator, GLFPSMovement, GLMirror, SpatialPartitioning, GLSpatialPartitioning,
  GLTrail, GLTree, GLMultiProxy, GLODEManager, dynode, GLODECustomColliders,
  GLShadowMap, MeshUtils, pngimage, GLRagdoll, GLODERagdoll, GLMovement, GLHUDShapes,
  GLFBO, Hashes, Freetype, GLFreetypeFont, GLClippingPlane, Keyboard, Forms, Squall, CrystalLUA;

type
   TEmpty = class(TComponent)
    private
   end;

const
   {$I 'bumpshader'}
   {$I 'phongshader'}

var
  scene: TGLScene;
  matlib: TGLMaterialLibrary;
  memviewer: TGLMemoryViewer;
  cadencer: TGLCadencer;
  empty: TEmpty;

  collisionPoint: TVector;
  collisionNormal: TVector;

  ode: TGLODEManager;
  odeRagdollWorld: TODERagdollWorld;
  jointList: TGLODEJointList;

{$R *.res}

function LoadStringFromFile2(const fileName : String) : String;
var
   n : Cardinal;
	fs : TStream;
begin
   if FileStreamExists(fileName) then begin
   	fs:=CreateFileStream(fileName, fmOpenRead+fmShareDenyNone);
      try
         n:=fs.Size;
   	   SetLength(Result, n);
         if n>0 then
         	fs.Read(Result[1], n);
      finally
   	   fs.Free;
      end;
   end else Result:='';
end;

function VectorDivide(const v1 : TAffineVector; delta : Single) : TAffineVector;
begin
   Result[0]:=v1[0]/delta;
   Result[1]:=v1[1]/delta;
   Result[2]:=v1[2]/delta;
end;

function VectorMultiply(const v1 : TAffineVector; delta : Single) : TAffineVector;
begin
   Result[0]:=v1[0]*delta;
   Result[1]:=v1[1]*delta;
   Result[2]:=v1[2]*delta;
end;

function IsExtensionSupported(v: TGLSceneViewer; const Extension: string): Boolean;
var
   Buffer : String;
   ExtPos: Integer;
begin
   v.Buffer.RenderingContext.Activate;
   Buffer := StrPas(glGetString(GL_EXTENSIONS));
   // First find the position of the extension string as substring in Buffer.
   ExtPos := Pos(Extension, Buffer);
   Result := ExtPos > 0;
   // Now check that it isn't only a substring of another extension.
   if Result then
     Result := ((ExtPos + Length(Extension) - 1)= Length(Buffer))
               or (Buffer[ExtPos + Length(Extension)]=' ');
   v.Buffer.RenderingContext.Deactivate;
end;

procedure GenMeshTangents(mesh: TMeshObject);
var
   i,j: Integer;
   v,t: array[0..2] of TAffineVector;

   x1, x2, y1, y2, z1, z2, t1, t2, s1, s2: Single;
   sDir, tDir: TAffineVector;
   sTan, tTan: TAffineVectorList;
   tangents, bitangents: TVectorList;
   sv, tv: array[0..2] of TAffineVector;
   r, oneOverR: Single;
   n, ta: TAffineVector;
   tang: TAffineVector;

   tangent,
   binormal   : array[0..2] of TVector;
   vt,tt      : TAffineVector;
   interp,dot : Single;

begin
   mesh.Tangents.Clear;
   mesh.Binormals.Clear;
   mesh.Tangents.Count:=mesh.Vertices.Count;
   mesh.Binormals.Count:=mesh.Vertices.Count;

   tangents := TVectorList.Create;
   tangents.Count:=mesh.Vertices.Count;

   bitangents := TVectorList.Create;
   bitangents.Count:=mesh.Vertices.Count; 

   sTan := TAffineVectorList.Create;
   tTan := TAffineVectorList.Create;
   sTan.Count := mesh.Vertices.Count;
   tTan.Count := mesh.Vertices.Count;

   for i:=0 to mesh.TriangleCount-1 do begin
      sv[0] := AffineVectorMake(0, 0, 0);
      tv[0] := AffineVectorMake(0, 0, 0);
      sv[1] := AffineVectorMake(0, 0, 0);
      tv[1] := AffineVectorMake(0, 0, 0);
      sv[2] := AffineVectorMake(0, 0, 0);
      tv[2] := AffineVectorMake(0, 0, 0);

      mesh.SetTriangleData(i,sTan,sv[0],sv[1],sv[2]);
      mesh.SetTriangleData(i,tTan,tv[0],tv[1],tv[2]);
   end;

   for i:=0 to mesh.TriangleCount-1 do begin
      mesh.GetTriangleData(i,mesh.Vertices,v[0],v[1],v[2]);
      mesh.GetTriangleData(i,mesh.TexCoords,t[0],t[1],t[2]);

      x1 := v[1][0] - v[0][0];
      x2 := v[2][0] - v[0][0];
      y1 := v[1][1] - v[0][1];
      y2 := v[2][1] - v[0][1];
      z1 := v[1][2] - v[0][2];
      z2 := v[2][2] - v[0][2];

      s1 := t[1][0] - t[0][0];
      s2 := t[2][0] - t[0][0];
      t1 := t[1][1] - t[0][1];
      t2 := t[2][1] - t[0][1];

      r := (s1 * t2) - (s2 * t1);

      if r = 0.0 then
        r := 1.0;

      oneOverR := 1.0 / r;

      sDir[0] := (t2 * x1 - t1 * x2) * oneOverR;
      sDir[1] := (t2 * y1 - t1 * y2) * oneOverR;
      sDir[2] := (t2 * z1 - t1 * z2) * oneOverR;

      tDir[0] := (s1 * x2 - s2 * x1) * oneOverR;
      tDir[1] := (s1 * y2 - s2 * y1) * oneOverR;
      tDir[2] := (s1 * z2 - s2 * z1) * oneOverR;

      mesh.GetTriangleData(i,sTan,sv[0],sv[1],sv[2]);
      mesh.GetTriangleData(i,tTan,tv[0],tv[1],tv[2]);

      sv[0] := VectorAdd(sv[0], sDir);
      tv[0] := VectorAdd(tv[0], tDir);
      sv[1] := VectorAdd(sv[1], sDir);
      tv[1] := VectorAdd(tv[1], tDir);
      sv[2] := VectorAdd(sv[2], sDir);
      tv[2] := VectorAdd(tv[2], tDir);

      mesh.SetTriangleData(i,sTan,sv[0],sv[1],sv[2]);
      mesh.SetTriangleData(i,tTan,tv[0],tv[1],tv[2]);
   end;

   for i:=0 to mesh.Vertices.Count-1 do begin
      n := mesh.Normals[i];
      ta := sTan[i];
      tang := VectorSubtract(ta, VectorMultiply(n, VectorDotProduct(n, ta)));
      tang := VectorNormalize(tang);

      tangents[i] := VectorMake(tang, 1);
      bitangents[i] := VectorMake(VectorCrossProduct(n, tang), 1);
   end;

   mesh.Tangents := tangents;
   mesh.Binormals := bitangents;
end;

function getODEBehaviour(obj: TGLBaseSceneObject): TGLODEBehaviour;
begin
  result := TGLODEBehaviour(obj.Behaviours.GetByClass(TGLODEBehaviour));
end;

function getJointAxisParams(j: TODEJointBase; axis: Integer): TODEJointParams;
var
  res: TODEJointParams;
begin
  if j is TODEJointHinge then
  begin
    if axis = 1 then
      res := TODEJointHinge(j).AxisParams;
  end
  else if j is TODEJointHinge2 then
  begin
    if axis = 1 then
      res := TODEJointHinge2(j).Axis1Params
    else if axis = 2 then
      res := TODEJointHinge2(j).Axis2Params;
  end
  else if j is TODEJointUniversal then
  begin
    if axis = 1 then
      res := TODEJointUniversal(j).Axis1Params
    else if axis = 2 then
      res := TODEJointUniversal(j).Axis2Params;
  end;
  result := res;
end;

{$I 'xtreme3d/engine'}
{$I 'xtreme3d/viewer'}
{$I 'xtreme3d/dummycube'}
{$I 'xtreme3d/camera'}
{$I 'xtreme3d/light'}
{$I 'xtreme3d/fonttext'}
{$I 'xtreme3d/sprite'}
{$I 'xtreme3d/hudshapes'}
{$I 'xtreme3d/primitives'}
{$I 'xtreme3d/actor'}
{$I 'xtreme3d/freeform'}
{$I 'xtreme3d/object'}
{$I 'xtreme3d/polygon'}
{$I 'xtreme3d/material'}
{$I 'xtreme3d/shaders'}
{$I 'xtreme3d/thorfx'}
{$I 'xtreme3d/firefx'}
{$I 'xtreme3d/lensflare'}
{$I 'xtreme3d/terrain'}
{$I 'xtreme3d/blur'}
{$I 'xtreme3d/skybox'}
{$I 'xtreme3d/trail'}
{$I 'xtreme3d/shadowplane'}
{$I 'xtreme3d/shadowvolume'}
{$I 'xtreme3d/skydome'}
{$I 'xtreme3d/water'}
{$I 'xtreme3d/lines'}
{$I 'xtreme3d/tree'}
{$I 'xtreme3d/navigator'}
{$I 'xtreme3d/movement'}
{$I 'xtreme3d/dce'}
{$I 'xtreme3d/fps'}
{$I 'xtreme3d/mirror'}
{$I 'xtreme3d/partition'}
{$I 'xtreme3d/memviewer'}
{$I 'xtreme3d/fbo'}
{$I 'xtreme3d/proxy'}
{$I 'xtreme3d/text'}
{$I 'xtreme3d/objecthash'}
{$I 'xtreme3d/grid'}
{$I 'xtreme3d/shadowmap'}
{$I 'xtreme3d/ode'}

function EngineDestroy: real; stdcall;
begin
  cadencer.Enabled := false;
  cadencer.Scene := nil;
  cadencer.Free;
  scene.Free;
  empty.Free;
  memviewer.Free;
  result:=1;
end;

function FreeformGenTangents(ff: real): real; stdcall;
var
  GLFreeForm1: TGLFreeForm;
  mesh1: TMeshObject;
  mi: Integer;
begin
  GLFreeForm1:=TGLFreeForm(trunc64(ff));
  for mi:=0 to GLFreeForm1.MeshObjects.Count-1 do begin
      mesh1 := GLFreeForm1.MeshObjects[mi];
      if (mesh1.Vertices.Count > 0) and (mesh1.TexCoords.Count > 0) then
        GenMeshTangents(mesh1);
  end;
  GLFreeForm1.StructureChanged;
  GLFreeForm1.NotifyChange(nil);
  result:=1.0;
end;

function OdeDynamicSetVelocity(obj, x, y, z: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  dyna.SetVelocity(AffineVectorMake(x, y, z));
  result := 1.0;
end;

function OdeDynamicSetAngularVelocity(obj, x, y, z: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  dyna.SetAngularVelocity(AffineVectorMake(x, y, z));
  result := 1.0;
end;

function OdeDynamicGetVelocity(obj, ind: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  result := dyna.GetVelocity[trunc64(ind)];
end;

function OdeDynamicGetAngularVelocity(obj, ind: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  result := dyna.GetAngularVelocity[trunc64(ind)];
end;

function OdeDynamicSetPosition(obj, x, y, z: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  dyna.SetPosition(AffineVectorMake(x, y, z));
  result := 1.0;
end;

function OdeDynamicSetRotationQuaternion(obj, x, y, z, w: real): real; stdcall;
var
  dyna: TGLODEDynamic;
begin
  dyna := GetOdeDynamic(TGLBaseSceneObject(trunc64(obj)));
  dyna.SetRotation(x, y, z, w);
  result := 1.0;
end;

function ClipPlaneCreate(parent: real): real; stdcall;
var
  cp: TGLClipPlane;
begin
  if not (parent = 0) then
    cp := TGLClipPlane.CreateAsChild(TGLBaseSceneObject(trunc64(parent)))
  else
    cp := TGLClipPlane.CreateAsChild(scene.Objects);
  result := Integer(cp);
end;

function ClipPlaneEnable(cplane, mode: real): real; stdcall;
var
  cp: TGLClipPlane;
begin
  cp := TGLClipPlane(trunc64(cplane));
  cp.ClipPlaneEnabled := Boolean(trunc64(mode));
  result := 1;
end;

function ClipPlaneSetPlane(cplane, px, py, pz, nx, ny, nz: real): real; stdcall;
var
  cp: TGLClipPlane;
begin
  cp := TGLClipPlane(trunc64(cplane));
  cp.SetClipPlane(AffineVectorMake(px, py, pz), AffineVectorMake(nx, ny, nz));
  result := 1;
end;

function MaterialCullFrontFaces(mtrl: pchar; culff: real): real; stdcall;
var
  mat:TGLLibMaterial;
begin
  mat:=matlib.Materials.GetLibMaterialByName(mtrl);
  mat.Material.CullFrontFaces := Boolean(trunc64(culff));
  result:=1;
end;

function MaterialSetZWrite(mtrl: pchar; zwrite: real): real; stdcall;
var
  mat:TGLLibMaterial;
begin
  mat:=matlib.Materials.GetLibMaterialByName(mtrl);
  mat.Material.ZWrite := Boolean(trunc64(zwrite));
  result:=1;
end;

// New in Xtreme3D 3.6:

function MouseSetPosition(mx, my: real): real; stdcall;
begin
  SetCursorPos(trunc64(mx), trunc64(my));
  Result := 1;
end;

function MouseGetPositionX: real; stdcall;
var
  mouse : TPoint;
begin
  GetCursorPos(mouse);
  Result := Integer(mouse.X);
end;

function MouseGetPositionY: real; stdcall;
var
  mouse : TPoint;
begin
  GetCursorPos(mouse);
  Result := Integer(mouse.Y);
end;

function MouseShowCursor(mode: real): real; stdcall;
begin
  ShowCursor(LongBool(trunc64(mode)));
  Result := 1;
end;

function KeyIsPressed(key: real): real; stdcall;
begin
  Result := Integer(IsKeyDown(trunc64(key)));
end;

function WindowCreate(x, y, w, h, resizeable: real): real; stdcall;
var
  frm: TForm;
begin
  frm := TForm.Create(nil);
  frm.Width := trunc64(w);
  frm.Height := trunc64(h);
  frm.Left := trunc64(x);
  frm.Top := trunc64(y);
  if trunc64(resizeable) = 0 then
    frm.BorderStyle := bsSingle;
  frm.Show;
  result := Integer(frm);
end;

function WindowGetHandle(w: real): real; stdcall;
var
  frm: TForm;
begin
  frm := TForm(trunc64(w));
  result := Integer(frm.Handle);
end;

function WindowSetTitle(w: real; title: pchar): real; stdcall;
var
  frm: TForm;
begin
  frm := TForm(trunc64(w));
  frm.Caption := String(title);
  result := 1;
end;

function WindowDestroy(w: real): real; stdcall;
var
  frm: TForm;
begin
  frm := TForm(trunc64(w));
  frm.Free;
  result := 1;
end;

function ObjectCopy(obj, parent: real): real; stdcall;
var
  obj1, obj2, par: TGLBaseSceneObject;
begin
  obj1 := TGLBaseSceneObject(trunc64(obj));
  if not (parent=0) then
    par := TGLBaseSceneObject(trunc64(parent))
  else
    par := scene.Objects;
  obj2 := TGLBaseSceneObject(obj1.NewInstance).CreateAsChild(par);
  result:=Integer(obj2);
end;

function SquallInit: real; stdcall;
var
  r: boolean;
begin
  r := InitSquall('squall.dll');
  if r then
    result := SQUALL_Init(nil)
  else
    result := 0;
end;

function SquallAddSound(filename: pchar): real; stdcall;
var
  s: Integer;
begin
  s := SQUALL_Sample_LoadFile(filename, 1, nil);
  result := s;
end;

function SquallPlay(snd, loop: real): real; stdcall;
var
  ch: Integer;
begin
  ch := SQUALL_Sample_Play(trunc64(snd), trunc64(loop), 0, 1);
  result := ch;
end;

function SquallStop(chan: real): real; stdcall;
begin
  SQUALL_Channel_Stop(trunc64(chan));
  result := 1.0;
end;

{$I 'xtreme3d/lua_wrappers'}

procedure luaRegX3DFunctions(lua: TLua);
begin
  // Register Engine functions
  lua.RegProc('EngineCreate', @lua_EngineCreate, 0);
  lua.RegProc('EngineDestroy', @lua_EngineDestroy, 0);
  lua.RegProc('EngineSetObjectsSorting', @lua_EngineSetObjectsSorting, 1);
  lua.RegProc('EngineSetCulling', @lua_EngineSetCulling, 1);
  lua.RegProc('SetPakArchive', @lua_SetPakArchive, 1);
  lua.RegProc('Update', @lua_Update, 1);

  // Register Object functions
  lua.RegProc('ObjectHide', @lua_ObjectHide, 1);
  lua.RegProc('ObjectShow', @lua_ObjectShow, 1);
  lua.RegProc('ObjectIsVisible', @lua_ObjectIsVisible, 1);
  lua.RegProc('ObjectCopy', @lua_ObjectCopy, 2);
  lua.RegProc('ObjectDestroy', @lua_ObjectDestroy, 1);
  lua.RegProc('ObjectDestroyChildren', @lua_ObjectDestroyChildren, 1);
  lua.RegProc('ObjectSetPosition', @lua_ObjectSetPosition, 4);
  lua.RegProc('ObjectGetPosition', @lua_ObjectGetPosition, 2);
  lua.RegProc('ObjectGetAbsolutePosition', @lua_ObjectGetAbsolutePosition, 2);
  lua.RegProc('ObjectSetPositionOfObject', @lua_ObjectSetPositionOfObject, 2);
  lua.RegProc('ObjectAlignWithObject', @lua_ObjectAlignWithObject, 2);
  lua.RegProc('ObjectSetPositionX', @lua_ObjectSetPositionX, 2);
  lua.RegProc('ObjectSetPositionY', @lua_ObjectSetPositionY, 2);
  lua.RegProc('ObjectSetPositionZ', @lua_ObjectSetPositionZ, 2);
  lua.RegProc('ObjectGetPositionX', @lua_ObjectGetPositionX, 1);
  lua.RegProc('ObjectGetPositionY', @lua_ObjectGetPositionY, 1);
  lua.RegProc('ObjectGetPositionZ', @lua_ObjectGetPositionZ, 1);
  lua.RegProc('ObjectSetAbsolutePosition', @lua_ObjectSetAbsolutePosition, 4);
  lua.RegProc('ObjectSetDirection', @lua_ObjectSetDirection, 4);
  lua.RegProc('ObjectGetDirection', @lua_ObjectGetDirection, 2);
  lua.RegProc('ObjectSetAbsoluteDirection', @lua_ObjectSetAbsoluteDirection, 4);
  lua.RegProc('ObjectGetPitch', @lua_ObjectGetPitch, 1);
  lua.RegProc('ObjectGetTurn', @lua_ObjectGetTurn, 1);
  lua.RegProc('ObjectGetRoll', @lua_ObjectGetRoll, 1);
  lua.RegProc('ObjectSetRotation', @lua_ObjectSetRotation, 4);
  lua.RegProc('ObjectMove', @lua_ObjectMove, 2);
  lua.RegProc('ObjectLift', @lua_ObjectLift, 2);
  lua.RegProc('ObjectStrafe', @lua_ObjectStrafe, 2);
  lua.RegProc('ObjectTranslate', @lua_ObjectTranslate, 4);
  lua.RegProc('ObjectRotate', @lua_ObjectRotate, 4);
  lua.RegProc('ObjectScale', @lua_ObjectScale, 4);
  lua.RegProc('ObjectSetScale', @lua_ObjectSetScale, 4);
  lua.RegProc('ObjectSetUpVector', @lua_ObjectSetUpVector, 4);
  lua.RegProc('ObjectPointToObject', @lua_ObjectPointToObject, 2);
  lua.RegProc('ObjectShowAxes', @lua_ObjectShowAxes, 2);
  lua.RegProc('ObjectGetGroundHeight', @lua_ObjectGetGroundHeight, 2);
  lua.RegProc('ObjectSceneRaycast', @lua_ObjectSceneRaycast, 2);
  lua.RegProc('ObjectRaycast', @lua_ObjectRaycast, 2);
  lua.RegProc('ObjectGetCollisionPosition', @lua_ObjectGetCollisionPosition, 1);
  lua.RegProc('ObjectGetCollisionNormal', @lua_ObjectGetCollisionNormal, 1);
  lua.RegProc('ObjectSetMaterial', @lua_ObjectSetMaterial, 2);
  lua.RegProc('ObjectGetDistance', @lua_ObjectGetDistance, 2);
  lua.RegProc('ObjectCheckCubeVsCube', @lua_ObjectCheckCubeVsCube, 2);
  lua.RegProc('ObjectCheckSphereVsSphere', @lua_ObjectCheckSphereVsSphere, 2);
  lua.RegProc('ObjectCheckSphereVsCube', @lua_ObjectCheckSphereVsCube, 2);
  lua.RegProc('ObjectCheckCubeVsFace', @lua_ObjectCheckCubeVsFace, 2);
  lua.RegProc('ObjectCheckFaceVsFace', @lua_ObjectCheckFaceVsFace, 2);
  lua.RegProc('ObjectIsPointInObject', @lua_ObjectIsPointInObject, 4);
  lua.RegProc('ObjectSetCulling', @lua_ObjectSetCulling, 2);
  lua.RegProc('ObjectSetName', @lua_ObjectSetName, 2);
  lua.RegProc('ObjectGetName', @lua_ObjectGetName, 1);
  lua.RegProc('ObjectGetClassName', @lua_ObjectGetClassName, 1);
  lua.RegProc('ObjectSetTag', @lua_ObjectSetTag, 2);
  lua.RegProc('ObjectGetTag', @lua_ObjectGetTag, 1);
  lua.RegProc('ObjectGetParent', @lua_ObjectGetParent, 1);
  lua.RegProc('ObjectGetChildCount', @lua_ObjectGetChildCount, 1);
  lua.RegProc('ObjectGetChild', @lua_ObjectGetChild, 2);
  lua.RegProc('ObjectGetIndex', @lua_ObjectGetIndex, 1);
  lua.RegProc('ObjectFindChild', @lua_ObjectFindChild, 2);
  lua.RegProc('ObjectGetBoundingSphereRadius', @lua_ObjectGetBoundingSphereRadius, 1);
  lua.RegProc('ObjectGetAbsoluteUp', @lua_ObjectGetAbsoluteUp, 2);
  lua.RegProc('ObjectSetAbsoluteUp', @lua_ObjectSetAbsoluteUp, 4);
  lua.RegProc('ObjectGetAbsoluteRight', @lua_ObjectGetAbsoluteRight, 2);
  lua.RegProc('ObjectGetAbsoluteXVector', @lua_ObjectGetAbsoluteXVector, 2);
  lua.RegProc('ObjectGetAbsoluteYVector', @lua_ObjectGetAbsoluteYVector, 2);
  lua.RegProc('ObjectGetAbsoluteZVector', @lua_ObjectGetAbsoluteZVector, 2);
  lua.RegProc('ObjectMoveChildUp', @lua_ObjectMoveChildUp, 2);
  lua.RegProc('ObjectMoveChildDown', @lua_ObjectMoveChildDown, 2);
  lua.RegProc('ObjectSetParent', @lua_ObjectSetParent, 2);
  lua.RegProc('ObjectRemoveChild', @lua_ObjectRemoveChild, 3);
  lua.RegProc('ObjectMoveObjectAround', @lua_ObjectMoveObjectAround, 4);
  lua.RegProc('ObjectPitch', @lua_ObjectPitch, 2);
  lua.RegProc('ObjectTurn', @lua_ObjectTurn, 2);
  lua.RegProc('ObjectRoll', @lua_ObjectRoll, 2);
  lua.RegProc('ObjectGetUp', @lua_ObjectGetUp, 2);
  lua.RegProc('ObjectRotateAbsolute', @lua_ObjectRotateAbsolute, 4);
  lua.RegProc('ObjectRotateAbsoluteVector', @lua_ObjectRotateAbsoluteVector, 5);
  lua.RegProc('ObjectSetMatrixColumn', @lua_ObjectSetMatrixColumn, 6);
  lua.RegProc('ObjectExportMatrix', @lua_ObjectExportMatrix, 2);
  lua.RegProc('ObjectExportAbsoluteMatrix', @lua_ObjectExportAbsoluteMatrix, 2);

  // Register Input functions
  lua.RegProc('KeyIsPressed', @lua_KeyIsPressed, 1);
end;

function LuaManagerCreate: real; stdcall;
var
  lua: TLua;
begin
  lua := TLua.Create();
  luaRegX3DFunctions(lua);
  result := Integer(lua);
end;

function LuaManagerSetConstantReal(lu: real; name: pchar; val: real): real; stdcall;
var
  lua: TLua;
begin
  lua := TLua(trunc64(lu));
  lua.RegConst(string(name), val);
  result := 1;
end;

function LuaManagerSetConstantString(lu: real; name, val: pchar): real; stdcall;
var
  lua: TLua;
begin
  lua := TLua(trunc64(lu));
  lua.RegConst(string(name), string(val));
  result := 1;
end;

function LuaManagerRunScript(lu: real; script: pchar): real; stdcall;
var
  lua: TLua;
begin
  result := 1;
  lua := TLua(trunc64(lu));
  try
   lua.RunScript(script);
  except
    On E: Exception do
    begin
      ShowMessage(E.Message);
      result := 0;
    end;
  end;
end;

function LuaManagerCallFunction(lu: real; name: pchar): real; stdcall;
var
  lua: TLua;
begin
  lua := TLua(trunc64(lu));
  result := 0;
  if lua.ProcExists(string(name)) then
  begin
    result := 1;
    try
      lua.Call(string(name), LuaArgs(0));
    except
      On E: Exception do
      begin
        ShowMessage(E.Message);
        result := 0;
      end;
    end;
  end;
end;

exports

//Engine
EngineCreate, EngineDestroy, EngineSetObjectsSorting, EngineSetCulling,
SetPakArchive,
Update, TrisRendered,
//Viewer
ViewerCreate, ViewerSetCamera, ViewerEnableVSync, ViewerRenderToFile,
ViewerRender, ViewerSetAutoRender, ViewerRenderEx,
ViewerResize, ViewerSetVisible, ViewerGetPixelColor, ViewerGetPixelDepth,
ViewerSetLighting, ViewerSetBackgroundColor, ViewerSetAmbientColor, ViewerEnableFog,
ViewerSetFogColor, ViewerSetFogDistance, ViewerScreenToWorld, ViewerWorldToScreen,
ViewerCopyToTexture, ViewerGetFramesPerSecond, ViewerGetPickedObject,
ViewerScreenToVector, ViewerVectorToScreen, ViewerPixelToDistance, ViewerGetPickedObjectsList,
ViewerSetAntiAliasing,
ViewerSetOverrideMaterial,
ViewerIsOpenGLExtensionSupported,
ViewerGetGLSLSupported, ViewerGetFBOSupported, ViewerGetVBOSupported,
ViewerGetSize, ViewerGetPosition,
//Dummycube
DummycubeCreate, DummycubeAmalgamate, DummycubeSetCameraMode, DummycubeSetVisible,
DummycubeSetEdgeColor, DummycubeSetCubeSize,
//Camera
CameraCreate, CameraSetStyle, CameraSetFocal, CameraSetSceneScale,
CameraScaleScene, CameraSetViewDepth, CameraSetTargetObject,
CameraMoveAroundTarget, CameraSetDistanceToTarget, CameraGetDistanceToTarget,
CameraCopyToTexture, CameraGetNearPlane, CameraSetNearPlaneBias,
CameraAbsoluteVectorToTarget, CameraAbsoluteRightVectorToTarget, CameraAbsoluteUpVectorToTarget,
CameraZoomAll, CameraScreenDeltaToVector, CameraScreenDeltaToVectorXY, CameraScreenDeltaToVectorXZ,
CameraScreenDeltaToVectorYZ, CameraAbsoluteEyeSpaceVector, CameraSetAutoLeveling,
CameraMoveInEyeSpace, CameraMoveTargetInEyeSpace, CameraPointInFront, CameraGetFieldOfView,
//Light
LightCreate, LightSetAmbientColor, LightSetDiffuseColor, LightSetSpecularColor,
LightSetAttenuation, LightSetShining, LightSetSpotCutoff, LightSetSpotExponent,
LightSetSpotDirection, LightSetStyle,
//Font & Text
BmpFontCreate, BmpFontLoad,
TTFontCreate, TTFontSetLineGap,
WindowsBitmapfontCreate,
HUDTextCreate, FlatTextCreate,
HUDTextSetRotation, SpaceTextCreate, SpaceTextSetExtrusion, HUDTextSetFont,
FlatTextSetFont, SpaceTextSetFont, HUDTextSetColor, FlatTextSetColor, HUDTextSetText,
FlatTextSetText, SpaceTextSetText,
//Sprite
HUDSpriteCreate, SpriteCreate, SpriteSetSize, SpriteScale, SpriteSetRotation,
SpriteRotate, SpriteMirror, SpriteNoZWrite,
SpriteCreateEx, HUDSpriteCreateEx, SpriteSetBounds, SpriteSetBoundsUV,
SpriteSetOrigin,
//HUDShapes
HUDShapeRectangleCreate, HUDShapeCircleCreate, HUDShapeLineCreate, HUDShapeMeshCreate,
HUDShapeSetRotation, HUDShapeSetColor,
HUDShapeRotate, HUDShapeSetOrigin, HUDShapeSetSize, HUDShapeScale,
HUDShapeCircleSetRadius, HUDShapeCircleSetSlices, HUDShapeCircleSetAngles,
HUDShapeLineSetPoints, HUDShapeLineSetWidth,
HUDShapeMeshAddVertex, HUDShapeMeshAddTriangle,
HUDShapeMeshSetVertex, HUDShapeMeshSetTexCoord,
//Primitives
CubeCreate, CubeSetNormalDirection, PlaneCreate, SphereCreate, SphereSetAngleLimits,
CylinderCreate, ConeCreate, AnnulusCreate, TorusCreate, DiskCreate, FrustrumCreate,
DodecahedronCreate, IcosahedronCreate, TeapotCreate,
//Actor
ActorCreate, ActorCopy, ActorSetAnimationRange, ActorGetCurrentFrame, ActorSwitchToAnimation,
ActorSwitchToAnimationName, ActorSynchronize, ActorSetInterval, ActorSetAnimationMode,
ActorSetFrameInterpolation, ActorAddObject, ActorGetCurrentAnimation, ActorGetFrameCount,
ActorGetBoneCount, ActorGetBoneByName, ActorGetBoneRotation, ActorGetBonePosition,
ActorBoneExportMatrix, ActorMakeSkeletalTranslationStatic, ActorMakeSkeletalRotationDelta, 
ActorShowSkeleton, 
AnimationBlenderCreate, AnimationBlenderSetActor, AnimationBlenderSetAnimation,
AnimationBlenderSetRatio,
ActorLoadQ3TagList, ActorLoadQ3Animations, ActorQ3TagExportMatrix,
ActorMeshObjectsCount, ActorFaceGroupsCount, ActorFaceGroupGetMaterialName,
ActorFaceGroupSetMaterial,
//Freeform
FreeformCreate, FreeformCreateEmpty,
FreeformAddMesh, FreeformMeshAddFaceGroup, 
FreeformMeshAddVertex, FreeformMeshAddNormal,
FreeformMeshAddTexCoord, FreeformMeshAddSecondTexCoord,
FreeformMeshAddTangent, FreeformMeshAddBinormal,

FreeformMeshGetVertex, FreeformMeshGetNormal,
FreeformMeshGetTexCoord, FreeformMeshGetSecondTexCoord,
FreeformMeshGetTangent, FreeformMeshGetBinormal,
FreeformMeshFaceGroupGetIndex,

FreeformMeshSetVertex, FreeformMeshSetNormal,
FreeformMeshSetTexCoord, FreeformMeshSetSecondTexCoord,
FreeformMeshSetTangent, FreeformMeshSetBinormal,
FreeformMeshFaceGroupSetIndex,

FreeformMeshFaceGroupAddTriangle,
FreeformMeshFaceGroupGetMaterial, FreeformMeshFaceGroupSetMaterial,
FreeformMeshGenNormals, FreeformMeshGenTangents,
FreeformMeshVerticesCount, FreeformMeshTriangleCount, 
FreeformMeshObjectsCount, FreeformMeshSetVisible,
FreeformMeshSetSecondCoords,
FreeformMeshFaceGroupsCount, FreeformMeshFaceGroupTriangleCount,
FreeformMeshSetMaterial, FreeformUseMeshMaterials,
FreeformSphereSweepIntersect, FreeformPointInMesh,
FreeformToFreeforms,
FreeformMeshTranslate, FreeformMeshRotate, FreeformMeshScale,
FreeformSave,

FreeformGenTangents, FreeformBuildOctree,

FreeformCreateExplosionFX, FreeformExplosionFXReset,
FreeformExplosionFXEnable, FreeformExplosionFXSetSpeed,
//Terrain
BmpHDSCreate, BmpHDSSetInfiniteWarp, BmpHDSInvert,
TerrainCreate, TerrainSetHeightData, TerrainSetTileSize, TerrainSetTilesPerTexture,
TerrainSetQualityDistance, TerrainSetQualityStyle, TerrainSetMaxCLodTriangles,
TerrainSetCLodPrecision, TerrainSetOcclusionFrameSkip, TerrainSetOcclusionTesselate,
TerrainGetHeightAtObjectPosition, TerrainGetLastTriCount,
//Object
ObjectHide, ObjectShow, ObjectIsVisible,
ObjectCopy, ObjectDestroy, ObjectDestroyChildren,
ObjectSetPosition, ObjectGetPosition, ObjectGetAbsolutePosition,
ObjectSetPositionOfObject, ObjectAlignWithObject,
ObjectSetPositionX, ObjectSetPositionY, ObjectSetPositionZ,
ObjectGetPositionX, ObjectGetPositionY, ObjectGetPositionZ,
ObjectSetAbsolutePosition,
ObjectSetDirection, ObjectGetDirection,
ObjectSetAbsoluteDirection, ObjectGetAbsoluteDirection,
ObjectGetPitch, ObjectGetTurn, ObjectGetRoll, ObjectSetRotation,
ObjectMove, ObjectLift, ObjectStrafe, ObjectTranslate, ObjectRotate,
ObjectScale, ObjectSetScale,
ObjectSetUpVector, ObjectPointToObject, 
ObjectShowAxes,
ObjectGetGroundHeight, ObjectSceneRaycast, ObjectRaycast,
ObjectGetCollisionPosition, ObjectGetCollisionNormal, 
ObjectSetMaterial,
ObjectGetDistance,
ObjectCheckCubeVsCube, ObjectCheckSphereVsSphere, ObjectCheckSphereVsCube,
ObjectCheckCubeVsFace, ObjectCheckFaceVsFace,
ObjectIsPointInObject,
ObjectSetCulling,
ObjectSetName, ObjectGetName, ObjectGetClassName,
ObjectSetTag, ObjectGetTag,
ObjectGetParent, ObjectGetChildCount, ObjectGetChild, ObjectGetIndex, ObjectFindChild,
ObjectGetBoundingSphereRadius,
ObjectGetAbsoluteUp, ObjectSetAbsoluteUp, ObjectGetAbsoluteRight,
ObjectGetAbsoluteXVector, ObjectGetAbsoluteYVector, ObjectGetAbsoluteZVector,
ObjectGetRight,
ObjectMoveChildUp, ObjectMoveChildDown,
ObjectSetParent, ObjectRemoveChild,
ObjectMoveObjectAround,
ObjectPitch, ObjectTurn, ObjectRoll,
ObjectGetUp,
ObjectRotateAbsolute, ObjectRotateAbsoluteVector,
ObjectSetMatrixColumn,
ObjectExportMatrix, ObjectExportAbsoluteMatrix,
//Polygon
PolygonCreate, PolygonAddVertex, PolygonSetVertexPosition, PolygonDeleteVertex,
//Material
MaterialLibraryCreate, MaterialLibraryActivate, MaterialLibrarySetTexturePaths,
MaterialLibraryClear, MaterialLibraryDeleteUnused,
MaterialLibraryHasMaterial, MaterialLibraryLoadScript, 
MaterialCreate,
MaterialAddCubeMap, MaterialCubeMapLoadImage, MaterialCubeMapGenerate, MaterialCubeMapFromScene,
MaterialSaveTexture, MaterialSetBlendingMode, MaterialSetOptions,
MaterialSetTextureMappingMode, MaterialSetTextureMode,
MaterialSetShader, MaterialSetSecondTexture,
MaterialSetDiffuseColor, MaterialSetAmbientColor, MaterialSetSpecularColor, MaterialSetEmissionColor,
MaterialSetShininess,
MaterialSetPolygonMode, MaterialSetTextureImageAlpha,
MaterialSetTextureScale, MaterialSetTextureOffset,
MaterialSetTextureFilter, MaterialEnableTexture,
MaterialGetCount, MaterialGetName,
MaterialSetFaceCulling,
MaterialSetTexture, MaterialSetSecondTexture,
MaterialSetTextureFormat, MaterialSetTextureCompression,
MaterialTextureRequiredMemory, MaterialSetFilteringQuality,
MaterialAddTextureEx, MaterialTextureExClear, MaterialTextureExDelete,
MaterialNoiseCreate, MaterialNoiseAnimate, MaterialNoiseSetDimensions,
MaterialNoiseSetMinCut, MaterialNoiseSetSharpness, MaterialNoiseSetSeamless,
MaterialNoiseRandomSeed,
MaterialGenTexture, MaterialSetTextureWrap,
MaterialGetTextureWidth, MaterialGetTextureHeight,
MaterialLoadTexture,
MaterialLoadTextureEx, MaterialSetTextureEx, MaterialGenTextureEx,
MaterialEnableTextureEx, MaterialHasTextureEx,
MaterialCullFrontFaces, MaterialSetZWrite,
//Shaders
ShaderEnable, 
BumpShaderCreate,
BumpShaderSetDiffuseTexture, BumpShaderSetNormalTexture, BumpShaderSetHeightTexture,
BumpShaderSetMaxLights, BumpShaderUseParallax, BumpShaderSetParallaxOffset,
BumpShaderSetShadowMap, BumpShaderSetShadowBlurRadius, BumpShaderUseAutoTangentSpace,
CelShaderCreate, CelShaderSetLineColor, CelShaderSetLineWidth, CelShaderSetOptions,
MultiMaterialShaderCreate,
HiddenLineShaderCreate, HiddenLineShaderSetLineSmooth, HiddenLineShaderSetSolid,
HiddenLineShaderSetSurfaceLit, HiddenLineShaderSetFrontLine, HiddenLineShaderSetBackLine,
OutlineShaderCreate, OutlineShaderSetLineColor, OutlineShaderSetLineWidth,
TexCombineShaderCreate, TexCombineShaderAddCombiner,
TexCombineShaderMaterial3, TexCombineShaderMaterial4,
PhongShaderCreate, PhongShaderUseTexture, PhongShaderSetMaxLights,
GLSLShaderCreate, GLSLShaderCreateParameter,
GLSLShaderSetParameter1i, GLSLShaderSetParameter1f, GLSLShaderSetParameter2f,
GLSLShaderSetParameter3f, GLSLShaderSetParameter4f,
GLSLShaderSetParameterTexture, GLSLShaderSetParameterSecondTexture,
GLSLShaderSetParameterMatrix, GLSLShaderSetParameterInvMatrix,
GLSLShaderSetParameterShadowTexture, GLSLShaderSetParameterShadowMatrix,
GLSLShaderSetParameterFBOColorTexture, GLSLShaderSetParameterFBODepthTexture,
GLSLShaderSetParameterViewMatrix, GLSLShaderSetParameterInvViewMatrix,
GLSLShaderSetParameterHasTextureEx,
//ThorFX
ThorFXManagerCreate, ThorFXSetColor, ThorFXEnableCore, ThorFXEnableGlow,
ThorFXSetMaxParticles, ThorFXSetGlowSize, ThorFXSetVibrate, ThorFXSetWildness,
ThorFXSetTarget, ThorFXCreate,
// FireFX
FireFXManagerCreate, FireFXCreate,
FireFXSetColor, FireFXSetMaxParticles, FireFXSetParticleSize,
FireFXSetDensity, FireFXSetEvaporation, FireFXSetCrown,
FireFXSetLife, FireFXSetBurst, FireFXSetRadius, FireFXExplosion,
//Lensflare
LensflareCreate, LensflareSetSize, LensflareSetSeed, LensflareSetSqueeze,
LensflareSetStreaks, LensflareSetStreakWidth, LensflareSetSecs,
LensflareSetResolution, LensflareSetElements, LensflareSetGradients,
//Skydome
SkydomeCreate, SkydomeSetOptions, SkydomeSetDeepColor, SkydomeSetHazeColor,
SkydomeSetNightColor, SkydomeSetSkyColor, SkydomeSetSunDawnColor, SkydomeSetSunZenithColor,
SkydomeSetSunElevation, SkydomeSetTurbidity,
SkydomeAddRandomStars, SkydomeAddStar, SkydomeClearStars, SkydomeTwinkleStars, 
//Water
WaterCreate, WaterCreateRandomRipple,
WaterCreateRippleAtGridPosition, WaterCreateRippleAtWorldPosition,
WaterCreateRippleAtObjectPosition,
WaterSetMask, WaterSetActive, WaterReset,
WaterSetRainTimeInterval, WaterSetRainForce,
WaterSetViscosity, WaterSetElastic, WaterSetResolution,
WaterSetLinearWaveHeight, WaterSetLinearWaveFrequency,
//Blur
BlurCreate, BlurSetPreset, BlurSetOptions, BlurSetResolution,
BlurSetColor, BlurSetBlendingMode,
//Skybox
SkyboxCreate, SkyboxSetMaterial, SkyboxSetClouds, SkyboxSetStyle,
//Lines
LinesCreate, LinesAddNode, LinesDeleteNode, LinesSetColors, LinesSetSize,
LinesSetSplineMode, LinesSetNodesAspect, LinesSetDivision,
//Tree
TreeCreate, TreeSetMaterials, TreeSetBranchFacets, TreeBuildMesh,
TreeSetBranchNoise, TreeSetBranchAngle, TreeSetBranchSize, TreeSetBranchRadius,
TreeSetBranchTwist, TreeSetDepth, TreeSetLeafSize, TreeSetLeafThreshold, TreeSetSeed,
//Trail
TrailCreate, TrailSetObject, TrailSetAlpha, TrailSetLimits, TrailSetMinDistance,
TrailSetUVScale, TrailSetMarkStyle, TrailSetMarkWidth, TrailSetEnabled, TrailClearMarks,
//Shadowplane
ShadowplaneCreate, ShadowplaneSetLight, ShadowplaneSetObject, ShadowplaneSetOptions,
//Shadowvolume
ShadowvolumeCreate, ShadowvolumeSetActive,
ShadowvolumeAddLight, ShadowvolumeRemoveLight,
ShadowvolumeAddOccluder, ShadowvolumeRemoveOccluder,
ShadowvolumeSetDarkeningColor, ShadowvolumeSetMode, ShadowvolumeSetOptions,
//Navigator
NavigatorCreate, NavigatorSetObject, NavigatorSetUseVirtualUp, NavigatorSetVirtualUp,  
NavigatorTurnHorizontal, NavigatorTurnVertical, NavigatorMoveForward,
NavigatorStrafeHorizontal, NavigatorStrafeVertical, NavigatorStraighten,
NavigatorFlyForward, NavigatorMoveUpWhenMovingForward, NavigatorInvertHorizontalWhenUpsideDown,
NavigatorSetAngleLock, NavigatorSetAngles,
//Movement
MovementCreate, MovementStart, MovementStop, MovementAutoStartNextPath, 
MovementAddPath, MovementSetActivePath, MovementPathSetSplineMode,
MovementPathAddNode,
MovementPathNodeSetPosition, MovementPathNodeSetRotation,
MovementPathNodeSetSpeed,
//DCE
DceManagerCreate, DceManagerStep, DceManagerSetGravity, DceManagerSetWorldDirection,
DceManagerSetWorldScale, DceManagerSetMovementScale,
DceManagerSetLayers, DceManagerSetManualStep,
DceDynamicSetManager, DceDynamicSetActive, DceDynamicIsActive,
DceDynamicSetUseGravity, DceDynamicSetLayer, DceDynamicGetLayer,
DceDynamicSetSolid, DceDynamicSetFriction, DceDynamicSetBounce,
DceDynamicSetSize, DceDynamicSetSlideOrBounce,
DceDynamicApplyAcceleration, DceDynamicApplyAbsAcceleration,
DceDynamicStopAcceleration, DceDynamicStopAbsAcceleration,
DceDynamicJump, DceDynamicMove, DceDynamicMoveTo,
DceDynamicSetVelocity, DceDynamicGetVelocity,
DceDynamicSetAbsVelocity, DceDynamicGetAbsVelocity,
DceDynamicApplyImpulse, DceDynamicApplyAbsImpulse,
DceDynamicInGround, DceDynamicSetMaxRecursionDepth,
DceStaticSetManager, DceStaticSetActive, DceStaticSetShape, DceStaticSetLayer,
DceStaticSetSize, DceStaticSetSolid, DceStaticSetFriction, DceStaticSetBounceFactor,
//FPSManager
FpsManagerCreate, FpsManagerSetNavigator, FpsManagerSetMovementScale,
FpsManagerAddMap, FpsManagerRemoveMap, FpsManagerMapSetCollisionGroup,
FpsSetManager, FpsSetCollisionGroup, FpsSetSphereRadius, FpsSetGravity,
FpsMove, FpsStrafe, FpsLift, FpsGetVelocity,
//Mirror
MirrorCreate, MirrorSetObject, MirrorSetOptions,
MirrorSetShape, MirrorSetDiskOptions,
//Partition
OctreeCreate, QuadtreeCreate, PartitionDestroy, PartitionAddLeaf,
PartitionLeafChanged, PartitionQueryFrustum, PartitionQueryLeaf,
PartitionQueryAABB, PartitionQueryBSphere, PartitionGetNodeTests,
PartitionGetNodeCount, PartitionGetResult, PartitionGetResultCount,
PartitionResultShow, PartitionResultHide,
//Proxy
ProxyObjectCreate, ProxyObjectSetOptions, ProxyObjectSetTarget,
MultiProxyObjectCreate, MultiProxyObjectAddTarget,
//Text
TextRead, TextConvertANSIToUTF8,
//ObjectHash
ObjectHashCreate, ObjectHashSetItem, ObjectHashGetItem,
ObjectHashDeleteItem, ObjectHashGetItemCount,
ObjectHashClear, ObjectHashDestroy,
//Grid
GridCreate, GridSetLineStyle, GridSetLineSmoothing, GridSetParts,
GridSetColor, GridSetSize, GridSetPattern,
//ClipPlane
ClipPlaneCreate, ClipPlaneEnable, ClipPlaneSetPlane,
//MemoryViewer
MemoryViewerCreate, MemoryViewerSetCamera, MemoryViewerRender,
MemoryViewerSetViewport, MemoryViewerCopyToTexture,
//FBO
FBOCreate, FBOSetCamera, FBOSetViewer,
FBORenderObject, FBORenderObjectEx,
FBOSetOverrideMaterial,
FBOSetColorTextureFormat,
//ShadowMap
ShadowMapCreate, ShadowMapSetCamera, ShadowMapSetCaster,
ShadowMapSetProjectionSize, ShadowMapSetZScale, ShadowMapSetZClippingPlanes,
ShadowMapSetFBO,
ShadowMapRender,
//ODE
OdeManagerCreate, OdeManagerDestroy, OdeManagerStep, OdeManagerGetNumContactJoints,
OdeManagerSetGravity, OdeManagerSetSolver, OdeManagerSetIterations,
OdeManagerSetMaxContacts, OdeManagerSetVisible, OdeManagerSetGeomColor,
OdeWorldSetAutoDisableFlag, OdeWorldSetAutoDisableLinearThreshold,
OdeWorldSetAutoDisableAngularThreshold, OdeWorldSetAutoDisableSteps, OdeWorldSetAutoDisableTime,
OdeStaticCreate, OdeDynamicCreate, OdeTerrainCreate,
OdeDynamicCalculateMass, OdeDynamicCalibrateCenterOfMass,
OdeDynamicAlignObject, OdeDynamicEnable, OdeDynamicSetAutoDisableFlag,
OdeDynamicSetAutoDisableLinearThreshold, OdeDynamicSetAutoDisableAngularThreshold,
OdeDynamicSetAutoDisableSteps, OdeDynamicSetAutoDisableTime,
OdeDynamicAddForce, OdeDynamicAddForceAtPos, OdeDynamicAddForceAtRelPos, 
OdeDynamicAddRelForce, OdeDynamicAddRelForceAtPos, OdeDynamicAddRelForceAtRelPos,
OdeDynamicAddTorque, OdeDynamicAddRelTorque,
OdeDynamicGetContactCount, OdeStaticGetContactCount,
OdeAddBox, OdeAddSphere, OdeAddPlane, OdeAddCylinder, OdeAddCone, OdeAddCapsule, OdeAddTriMesh,
OdeElementSetDensity,
OdeSurfaceEnableRollingFrictionCoeff, OdeSurfaceSetRollingFrictionCoeff,
OdeSurfaceSetMode, OdeSurfaceSetMu, OdeSurfaceSetMu2,
OdeSurfaceSetBounce, OdeSurfaceSetBounceVel, OdeSurfaceSetSoftERP, OdeSurfaceSetSoftCFM,
OdeSurfaceSetMotion1, OdeSurfaceSetMotion2, OdeSurfaceSetSlip1, OdeSurfaceSetSlip2,
OdeAddJointBall, OdeAddJointFixed, OdeAddJointHinge, OdeAddJointHinge2,
OdeAddJointSlider, OdeAddJointUniversal, 
OdeJointSetObjects, OdeJointEnable, OdeJointInitialize,
OdeJointSetAnchor, OdeJointSetAnchorAtObject, OdeJointSetAxis1, OdeJointSetAxis2,
OdeJointSetBounce, OdeJointSetCFM, OdeJointSetFMax, OdeJointSetFudgeFactor,
OdeJointSetHiStop, OdeJointSetLoStop, OdeJointSetStopCFM, OdeJointSetStopERP, OdeJointSetVel,
OdeRagdollCreate, OdeRagdollHingeJointCreate, OdeRagdollUniversalJointCreate,
OdeRagdollDummyJointCreate, OdeRagdollBoneCreate,
OdeRagdollBuild, OdeRagdollEnable, OdeRagdollUpdate,

OdeDynamicSetVelocity, OdeDynamicSetAngularVelocity,
OdeDynamicGetVelocity, OdeDynamicGetAngularVelocity,
OdeDynamicSetPosition, OdeDynamicSetRotationQuaternion, 
{
OdeVehicleCreate, OdeVehicleSetScene, OdeVehicleSetForwardForce,
OdeVehicleAddSuspension, OdeVehicleSuspensionGetWheel, OdeVehicleSuspensionSetSteeringAngle;
}
// Input
MouseSetPosition, MouseGetPositionX, MouseGetPositionY, MouseShowCursor, 
KeyIsPressed,
// Window
WindowCreate, WindowGetHandle, WindowSetTitle, WindowDestroy,
// Squall
SquallInit, SquallAddSound, SquallPlay, SquallStop,
// Lua
LuaManagerCreate, LuaManagerSetConstantReal, LuaManagerSetConstantString,
LuaManagerRunScript, LuaManagerCallFunction;

begin
end.
