// GLExtrusion
{: Egg<p>

	Extrusion objects for GLScene. Extrusion objects are solids defined by the
   surface described by a moving curve.<p>

	<b>Historique : </b><font size=-1><ul>
      <li>26/02/01 - Egg - Minor update to RenderSides by Michael Schuricht
      <li>21/02/01 - Egg - New RenderSides code by Michael Schuricht,
                           now XOpenGL based (multitexture)
      <li>10/01/01 - Egg - Better aspect when nodeN = NodeN-2 in lines mode
                           (should have only beend encountered when editing)
	   <li>06/08/00 - Egg - Creation (from split of GLObjects), Added TGLPipe
	</ul></font>
}
unit GLExtrusion;

interface

uses Classes, GLObjects, GLScene, GLMisc, GLTexture;

type

   // TRevolutionSolidParts
   //
   TRevolutionSolidPart = (rspOutside, rspInside, rspStartPolygon, rspStopPolygon);
   TRevolutionSolidParts = set of TRevolutionSolidPart;

   // TRevolutionSolid
   //
   {: A solid object generated by rotating a curve along the Y axis.<p>
      The curve is described by the Nodes and SplineMode properties, and it is
      rotated in the trigonometrical direction (CCW when seen from Y->INF).<p>
      The TRevolutionSolid can also be used to render regular helicoidions, by
      setting a non-null YOffsetPerTurn, and adjusting start/finish angles to
      make more than one revolution.<p>
      If you want top/bottom caps, just add a first/last node that will make
      the curve start/finish on the Y axis. }
   TRevolutionSolid = class(TPolygonBase)
      private
			{ Private Declarations }
         FSlices : Integer;
         FStartAngle, FStopAngle : Single;
         FNormals : TNormalSmoothing;
         FYOffsetPerTurn : Single;
         FTriangleCount : Integer;
         FNormalDirection : TNormalDirection;
         FParts : TRevolutionSolidParts;

		protected
			{ Protected Declarations }
         procedure SetStartAngle(const val : Single);
         procedure SetStopAngle(const val : Single);
         function  StoreStopAngle : Boolean;
         procedure SetSlices(const val : Integer);
         procedure SetNormals(const val : TNormalSmoothing);
         procedure SetYOffsetPerTurn(const val : Single);
         procedure SetNormalDirection(const val : TNormalDirection);
         procedure SetParts(const val : TRevolutionSolidParts);

      public
			{ Public Declarations }
         constructor Create(AOwner: TComponent); override;
         destructor Destroy; override;
         procedure Assign(Source: TPersistent); override;
         procedure BuildList(var rci : TRenderContextInfo); override;

         {: Number of triangles used for rendering. }
         property TriangleCount : Integer read FTriangleCount;

      published
			{ Published Declarations }
         {: Parts of the rotation solid to be generated for rendering.<p>
            rspInside and rspOutside are generated from the curve and make the
            inside/outside as long as NormalDirection=ndOutside and the solid
            is described by the curve that goes from top to bottom.<p>
            Start/StopPolygon are tesselated from the curve (considered as closed). }
         property Parts : TRevolutionSolidParts read FParts write SetParts default [rspOutside];

         property StartAngle : Single read FStartAngle write SetStartAngle;
         property StopAngle : Single read FStopAngle write SetStopAngle stored StoreStopAngle;
         {: Y offset applied to the curve position for each turn.<p>
            This amount is applied proportionnally, for instance if your curve
            is a small circle, off from the Y axis, with a YOffset set to 0 (zero),
            you will get a torus, but with a non null value, you will get a
            small helicoidal spring.<p>
            This can be useful for rendering, lots of helicoidal objects from
            screws, to nails to stairs etc. }
         property YOffsetPerTurn : Single read FYOffsetPerTurn write SetYOffsetPerTurn;
         {: Number of slices per turn (360�). }
         property Slices : Integer read FSlices write SetSlices default 16;

         property Normals : TNormalSmoothing read FNormals write SetNormals default nsFlat;
         property NormalDirection : TNormalDirection read FNormalDirection write SetNormalDirection default ndOutside;
   end;

	// TGLPipeNode
	//
	TGLPipeNode = class (TGLNode)
	   private
	      { Private Declarations }
         FRadiusFactor : Single;

	   protected
	      { Protected Declarations }
         function GetDisplayName : String; override;
         procedure SetRadiusFactor(const val : Single);
         function StoreRadiusFactor : Boolean;

      public
	      { Public Declarations }
	      constructor Create(Collection : TCollection); override;
	      destructor Destroy; override;
	      procedure Assign(Source: TPersistent); override;

	   published
	      { Published Declarations }
         property RadiusFactor : Single read FRadiusFactor write SetRadiusFactor stored StoreRadiusFactor;

	end;

	// TGLPipeNodes
	//
	TGLPipeNodes = class (TGLLinesNodes)
	   protected
	      { Protected Declarations }
         procedure SetItems(index : Integer; const val : TGLPipeNode);
	      function GetItems(index : Integer) : TGLPipeNode;

      public
	      { Public Declarations }
	      constructor Create(AOwner : TComponent);
         function Add: TGLPipeNode;
	      function FindItemID(ID: Integer): TGLPipeNode;
	      property Items[index : Integer] : TGLPipeNode read GetItems write SetItems; default;
   end;

   // TPipeParts
   //
   TPipePart = (ppOutside, ppInside, ppStartDisk, ppStopDisk);
   TPipeParts = set of TPipePart;

   // TPipe
   //
   {: A solid object generated by extruding a circle along a trajectory.<p>
      Texture coordinates NOT supported yet. }
   TPipe = class(TPolygonBase)
      private
			{ Private Declarations }
         FSlices : Integer;
         FParts : TPipeParts;
         FTriangleCount : Integer;
         FRadius : Single;

		protected
			{ Protected Declarations }
         procedure CreateNodes; override;
         procedure SetSlices(const val : Integer);
         procedure SetParts(const val : TPipeParts);
         procedure SetRadius(const val : Single);
         function StoreRadius : Boolean;

      public
			{ Public Declarations }
         constructor Create(AOwner: TComponent); override;
         destructor Destroy; override;
         procedure Assign(Source: TPersistent); override;
         procedure BuildList(var rci : TRenderContextInfo); override;

         {: Number of triangles used for rendering. }
         property TriangleCount : Integer read FTriangleCount;

      published
			{ Published Declarations }
         property Parts : TPipeParts read FParts write SetParts default [ppOutside];
         property Slices : Integer read FSlices write SetSlices default 16;
         property Radius : Single read FRadius write SetRadius;
   end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses SysUtils, Geometry, OpenGL12, Spline, XOpenGL;

// ------------------
// ------------------ TRevolutionSolid ------------------
// ------------------

// Create
//
constructor TRevolutionSolid.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FStartAngle:=0;
   FStopAngle:=360;
   FSlices:=16;
   FNormals:=nsFlat;
   FNormalDirection:=ndOutside;
   FParts:=[rspOutside];
end;

// Destroy
//
destructor TRevolutionSolid.Destroy;
begin
   inherited Destroy;
end;

// SetStartAngle
//
procedure TRevolutionSolid.SetStartAngle(const val : Single);
begin
   if FStartAngle<>val then begin
      FStartAngle:=val;
      if FStartAngle>FStopAngle then FStopAngle:=FStartAngle;
      StructureChanged;
   end;
end;

// SetStopAngle
//
procedure TRevolutionSolid.SetStopAngle(const val : Single);
begin
   if FStopAngle<>val then begin
      FStopAngle:=val;
      if FStopAngle<FStartAngle then FStartAngle:=FStopAngle;
      StructureChanged;
   end;
end;

// StoreStopAngle
//
function TRevolutionSolid.StoreStopAngle : Boolean;
begin
   Result:=(FStopAngle<>360);
end;

// SetSlices
//
procedure TRevolutionSolid.SetSlices(const val : Integer);
begin
   if (val<>FSlices) and (val>0) then begin
      FSlices:=val;
      StructureChanged;
   end;
end;

// SetNormals
//
procedure TRevolutionSolid.SetNormals(const val : TNormalSmoothing);
begin
   if FNormals<>val then begin
      FNormals:=val;
      StructureChanged;
   end;
end;

// SetYOffsetPerTurn
//
procedure TRevolutionSolid.SetYOffsetPerTurn(const val : Single);
begin
   if FYOffsetPerTurn<>val then begin
      FYOffsetPerTurn:=val;
      StructureChanged;
   end;
end;

// SetNormalDirection
//
procedure TRevolutionSolid.SetNormalDirection(const val : TNormalDirection);
begin
   if FNormalDirection<>val then begin
      FNormalDirection:=val;
      StructureChanged;
   end;
end;

// SetParts
//
procedure TRevolutionSolid.SetParts(const val : TRevolutionSolidParts);
begin
   if FParts<>val then begin
      FParts:=val;
      StructureChanged;
   end;
end;

// Assign
//
procedure TRevolutionSolid.Assign(Source: TPersistent);
begin
   if Source is TRevolutionSolid then begin
      FStartAngle:=TRevolutionSolid(Source).FStartAngle;
      FStopAngle:=TRevolutionSolid(Source).FStopAngle;
      FSlices:=TRevolutionSolid(Source).FSlices;
      FNormals:=TRevolutionSolid(Source).FNormals;
      FYOffsetPerTurn:=TRevolutionSolid(Source).FYOffsetPerTurn;
      FNormalDirection:=TRevolutionSolid(Source).FNormalDirection;
      FParts:=TRevolutionSolid(Source).FParts;
   end;
   inherited Assign(Source);
end;

// BuildList
//
procedure TRevolutionSolid.BuildList(var rci : TRenderContextInfo);
var
   deltaAlpha, startAlpha, stopAlpha, alpha : Single;
   deltaS : Single;
   deltaYOffset, yOffset, startYOffset : Single;
   lastNormals : PAffineVectorArray;
   firstStep, gotYDeltaOffset : Boolean;

   procedure CalcNormal(const ptTop, ptBottom : PAffineVector; var normal : TAffineVector);
   var
      tb : TAffineVector;
      mx, mz : Single;
   begin
      mx:=ptBottom[0]+ptTop[0];
      mz:=ptBottom[2]+ptTop[2];
      VectorSubtract(ptBottom^, ptTop^, tb);
      normal[0]:=-tb[1]*mx;
      normal[1]:=mx*tb[0]+mz*tb[2];
      normal[2]:=-mz*tb[1];
      NormalizeVector(normal);
   end;

   procedure BuildStep(ptTop, ptBottom : PAffineVector; invertNormals : Boolean;
                       topT, bottomT : Single);
   var
      i : Integer;
      topBase, topNext, bottomBase, bottomNext, normal : TAffineVector;
      topTPBase, topTPNext, bottomTPBase, bottomTPNext : TTexPoint;
      nextAlpha : Single;
      ptBuffer : PAffineVector;
   begin
      // to invert normals, we just need to flip top & bottom
      if invertNormals then begin
         ptBuffer:=ptTop;
         ptTop:=ptBottom;
         ptBottom:=ptBuffer;
      end;
      // generate triangle strip for a level
      // TODO : support for triangle fans (when ptTop or ptBottom is on the Y Axis)
      alpha:=startAlpha;
      i:=1;
      yOffset:=startYOffset;
      topTPBase.S:=0;         bottomTPBase.S:=0;
      topTPBase.T:=topT;      bottomTPBase.T:=bottomT;
      VectorRotateAroundY(ptTop^, alpha, topBase);
      VectorRotateAroundY(ptBottom^, alpha, bottomBase);
      if gotYDeltaOffset then begin
         topBase[1]:=topBase[1]+yOffset;
         bottomBase[1]:=bottomBase[1]+yOffset;
      end;
      CalcNormal(@topBase, @bottomBase, normal);
      topTPNext:=topTPBase;
      bottomTPNext:=bottomTPBase;
      glBegin(GL_TRIANGLE_STRIP);
      case FNormals of
         nsFlat :
            glNormal3fv(@normal);
         nsSmooth : begin
            if firstStep then glNormal3fv(@normal) else glNormal3fv(@lastNormals[0]);
            lastNormals[0]:=normal;
         end;
      end;
      xglTexCoord2fv(@topTPBase);
      glVertex3fv(@topBase);
      while alpha<stopAlpha do begin
         if FNormals=nsSmooth then glNormal3fv(@normal);
         xglTexCoord2fv(@bottomTPBase);
         glVertex3fv(@bottomBase);
         nextAlpha:=alpha+deltaAlpha;
         topTPNext.S:=topTPNext.S+deltaS;
         bottomTPNext.S:=bottomTPNext.S+deltaS;
         VectorRotateAroundY(ptTop^, nextAlpha, topNext);
         VectorRotateAroundY(ptBottom^, nextAlpha, bottomNext);
         if gotYDeltaOffset then begin
            topNext[1]:=topNext[1]+yOffset;
            bottomNext[1]:=bottomNext[1]+yOffset;
            yOffset:=yOffset+deltaYOffset
         end;
         CalcNormal(@topNext, @bottomNext, normal);
         xglTexCoord2fv(@topTPNext);
         case FNormals of
            nsFlat : begin
               glNormal3fv(@normal);
               glVertex3fv(@topNext);
            end;
            nsSmooth : begin
               if firstStep then glNormal3fv(@normal) else glNormal3fv(@lastNormals[i]);
               glVertex3fv(@topNext);
               lastNormals[i]:=normal;
               Inc(i);
            end;
         end;
         alpha:=nextAlpha;
         topBase:=topNext;          topTPBase:=topTPNext;
         bottomBase:=bottomNext;    bottomTPBase:=bottomTPNext;
      end;
      if FNormals=nsSmooth then glNormal3fv(@normal);
      xglTexCoord2fv(@bottomTPBase);
      glVertex3fv(@bottomBase);
      glEnd;
      firstStep:=False;
   end;

var
   i, nbSteps, nbDivisions : Integer;
   splinePos, lastSplinePos, bary, polygonNormal : TAffineVector;
   f : Single;
   spline : TCubicSpline;
   invertedNormals : Boolean;
   polygon : TGLNodes;
begin
   if (Nodes.Count>1) and (FStopAngle>FStartAngle) then begin
      startAlpha:=FStartAngle*cPIdiv180;
      stopAlpha:=FStopAngle*cPIdiv180;
      nbSteps:=Round(((stopAlpha-startAlpha)/(2*PI))*FSlices);
      // drop 0.1% to slice count to care for precision losses
      deltaAlpha:=(stopAlpha-startAlpha)/(nbSteps*0.999);
      deltaS:=(stopAlpha-startAlpha)/(2*PI*nbSteps);
      gotYDeltaOffset:=FYOffsetPerTurn<>0;
      if gotYDeltaOffset then
         deltaYOffset:=(FYOffsetPerTurn*(stopAlpha-startAlpha)/(2*PI))/nbSteps
      else deltaYOffset:=0;
      startYOffset:=YOffsetPerTurn*startAlpha/(2*PI);
      invertedNormals:=(FNormalDirection=ndInside);
      FTriangleCount:=0;
      // generate sides
      if (rspInside in FParts) or (rspOutside in FParts) then begin
         // allocate lastNormals buffer (if smoothing)
         if FNormals=nsSmooth then begin
            GetMem(lastNormals, (FSlices+2)*SizeOf(TAffineVector));
            firstStep:=True;
         end;
         // start working
         if (Division<2) or (SplineMode=lsmLines) then begin
            // standard line(s), draw directly
            for i:=0 to Nodes.Count-2 do with Nodes[i] do begin
               if rspInside in Parts then
                  BuildStep(PAffineVector(Nodes[i].AsAddress),
                            PAffineVector(Nodes[i+1].AsAddress), not invertedNormals,
                            i/(Nodes.Count-1), (i+1)/(Nodes.Count-1));
               if rspOutside in Parts then
                  BuildStep(PAffineVector(Nodes[i].AsAddress),
                            PAffineVector(Nodes[i+1].AsAddress), invertedNormals,
                            i/(Nodes.Count-1), (i+1)/(Nodes.Count-1));
            end;
            FTriangleCount:=nbSteps*Nodes.Count*2;
         end else begin
            // cubic spline
            Spline:=Nodes.CreateNewCubicSpline;
            Spline.SplineAffineVector(0, lastSplinePos);
            f:=1/Division;
            nbDivisions:=(Nodes.Count-1)*Division;
            for i:=1 to nbDivisions do begin
               Spline.SplineAffineVector(i*f, splinePos);
               if rspInside in Parts then
                  BuildStep(@lastSplinePos, @splinePos, not invertedNormals,
                            (i-1)/nbDivisions, i/nbDivisions);
               if rspOutside in Parts then
                  BuildStep(@lastSplinePos, @splinePos, invertedNormals,
                            (i-1)/nbDivisions, i/nbDivisions);
               lastSplinePos:=splinePos;
            end;
            Spline.Free;
            FTriangleCount:=nbSteps*nbDivisions*2;
         end;
         if (rspInside in FParts) and (rspOutside in FParts) then
            FTriangleCount:=FTriangleCount*2;
         xglTexCoord2fv(@NullTexPoint);
         // release lastNormals buffer (if smoothing)
         if FNormals=nsSmooth then
            FreeMem(lastNormals);
      end;
      // tessellate start/stop polygons
      if (rspStartPolygon in FParts) or (rspStopPolygon in FParts) then begin
         bary:=Nodes.Barycenter; bary[1]:=0;
         NormalizeVector(bary);
         // tessellate start polygon
         if rspStartPolygon in FParts then begin
            polygon:=Nodes.CreateCopy(nil);
            with polygon do begin
               RotateAroundY(startAlpha);
               Translate(AffineVectorMake(0, startYOffset, 0));
               if invertedNormals then
                  alpha:=startAlpha+PI/2
               else alpha:=startAlpha+PI+PI/2;
               polygonNormal:=VectorRotateAroundY(bary, alpha);
               if SplineMode=lsmLines then
                  RenderTesselatedPolygon(False, @polygonNormal, 1)
               else RenderTesselatedPolygon(False, @polygonNormal, Division);
               Free;
            end;
            // estimated count
            FTriangleCount:=FTriangleCount+Nodes.Count+(Nodes.Count shr 1);
         end;
         // tessellate stop polygon
         if rspStopPolygon in FParts then begin
            polygon:=Nodes.CreateCopy(nil);
            with polygon do begin
               RotateAroundY(stopAlpha);
               Translate(AffineVectorMake(0, startYOffset+(stopAlpha-startAlpha)*YOffsetPerTurn/(2*PI), 0));
               if invertedNormals then
                  alpha:=stopAlpha+PI+PI/2
               else alpha:=stopAlpha+PI/2;
               polygonNormal:=VectorRotateAroundY(bary, alpha);
               if SplineMode=lsmLines then
                  RenderTesselatedPolygon(False, @polygonNormal, 1)
               else RenderTesselatedPolygon(False, @polygonNormal, Division);
               Free;
            end;
            // estimated count
            FTriangleCount:=FTriangleCount+Nodes.Count+(Nodes.Count shr 1);
         end;
      end;
   end;
end;

// ------------------
// ------------------ TGLPipeNode ------------------
// ------------------

constructor TGLPipeNode.Create(Collection : TCollection);
begin
	inherited Create(Collection);
   FRadiusFactor:=1.0;
end;

destructor TGLPipeNode.Destroy;
begin
	inherited Destroy;
end;

procedure TGLPipeNode.Assign(Source: TPersistent);
begin
	if Source is TGLPipeNode then begin
      FRadiusFactor:=TGLPipeNode(Source).FRadiusFactor
	end;
	inherited Destroy;
end;

// GetDisplayName
//
function TGLPipeNode.GetDisplayName : String;
begin
	Result:=Format('%s / rf = %.3f', [inherited GetDisplayName, RadiusFactor]);;
end;

// SetRadiusFactor
//
procedure TGLPipeNode.SetRadiusFactor(const val : Single);
begin
   if FRadiusFactor<>val then begin
      FRadiusFactor:=val;
      (Collection as TGLNodes).NotifyChange;
   end;
end;

// StoreRadiusFactor
//
function TGLPipeNode.StoreRadiusFactor : Boolean;
begin
	Result:=(FRadiusFactor<>1.0);
end;

// ------------------
// ------------------ TGLPipeNodes ------------------
// ------------------

constructor TGLPipeNodes.Create(AOwner : TComponent);
begin
	inherited OldCreate(AOwner, TGLPipeNode);
end;

procedure TGLPipeNodes.SetItems(index : Integer; const val : TGLPipeNode);
begin
	inherited Items[index]:=val;
end;

function TGLPipeNodes.GetItems(index : Integer) : TGLPipeNode;
begin
	Result:=TGLPipeNode(inherited Items[index]);
end;

function TGLPipeNodes.Add: TGLPipeNode;
begin
	Result:=(inherited Add) as TGLPipeNode;
end;

function TGLPipeNodes.FindItemID(ID: Integer): TGLPipeNode;
begin
	Result:=(inherited FindItemID(ID)) as TGLPipeNode;
end;

// ------------------
// ------------------ TPipe ------------------
// ------------------

// Create
//
constructor TPipe.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FSlices:=16;
   FParts:=[ppOutside];
   FRadius:=1.0;
   FTriangleCount:=0;
end;

// CreateNodes
//
procedure TPipe.CreateNodes;
begin
   FNodes:=TGLPipeNodes.Create(Self);
end;

// Destroy
//
destructor TPipe.Destroy;
begin
   inherited Destroy;
end;

// SetSlices
//
procedure TPipe.SetSlices(const val : Integer);
begin
   if (val<>FSlices) and (val>0) then begin
      FSlices:=val;
      StructureChanged;
   end;
end;

// SetParts
//
procedure TPipe.SetParts(const val : TPipeParts);
begin
   if FParts<>val then begin
      FParts:=val;
      StructureChanged;
   end;
end;

// SetRadius
//
procedure TPipe.SetRadius(const val : Single);
begin
   if FRadius<>val then begin
      FRadius:=val;
      StructureChanged;
   end;
end;

// StoreRadius
//
function TPipe.StoreRadius : Boolean;
begin
   Result:=(FRadius<>1);
end;

// Assign
//
procedure TPipe.Assign(Source: TPersistent);
begin
   if Source is TPipe then begin
      FSlices:=TPipe(Source).FSlices;
      FParts:=TPipe(Source).FParts;
   end;
   inherited Assign(Source);
end;

// BuildList
//
procedure TPipe.BuildList(var rci : TRenderContextInfo);
type
   TNodeData = record
      pos : TAffineVector;
      normal : TAffineVector;
   end;
var
   sinCache, cosCache : array of Single;

   procedure CalculateRow(var row : array of TNodeData;
                          const center, normal : TAffineVector; radius : Single);
   var
      i : Integer;
      vx, vy : TAffineVector;
   begin
      // attempt to use object's Z as Y vector
      VectorCrossProduct(ZVector, normal, vx);
      if VectorNorm(vx)<1e-7 then begin
         // bad luck, the X vector will do (unless it's or normal that was null)
         if VectorNorm(normal)<1e-7 then begin
            SetVector(vx, XVector);
            SetVector(vy, ZVector);
         end else begin
            VectorCrossProduct(XVector, normal, vx);
            NormalizeVector(vx);
            VectorCrossProduct(normal, vx, vy);
         end;
      end else begin
         NormalizeVector(vx);
         VectorCrossProduct(normal, vx, vy);
      end;
      NormalizeVector(vy);
      ScaleVector(vx, FRadius);
      ScaleVector(vy, FRadius);
      // generate the circle
      for i:=0 to High(row) do begin
         row[i].normal:=VectorCombine(vx, vy, cosCache[i], sinCache[i]);
         row[i].pos:=VectorCombine(PAffineVector(@center)^, row[i].normal, 1, radius);
      end;
   end;

   procedure RenderDisk(var row : array of TNodeData;
                        const center : TVector; const normal : TAffineVector;
                        invert : Boolean);
   var
      i : Integer;
   begin
      glBegin(GL_TRIANGLE_FAN);
         glNormal3fv(@normal);
         glVertex3fv(@center);
         if invert then
            for i:=High(Row) downto 0 do glVertex3fv(@row[i].pos)
         else for i:=0 to High(Row) do glVertex3fv(@row[i].pos);
      glEnd;
   end;

   procedure RenderSides(curRow, prevRow : array of TNodeData);
   var
      j, k, kp, m, n, kx, ky, kz, kpx, kpy, kpz : Integer;
      deltaNormal, deltaPos : array of Double;
   begin
      kx:=1;   ky:=1;   kz:=1;
      kpx:=1;  kpy:=1;  kpz:=1;
      for j:=0 to Slices do begin
         if Sign(curRow[j].normal[0])<>Sign(prevRow[j].normal[0]) then Inc(kx);
         if Sign(curRow[j].normal[1])<>Sign(prevRow[j].normal[1]) then Inc(ky);
         if Sign(curRow[j].normal[2])<>Sign(prevRow[j].normal[2]) then Inc(kz);
         if Sign(curRow[j].pos[0])<>Sign(prevRow[j].pos[0]) then Inc(kpx);
         if Sign(curRow[j].pos[1])<>Sign(prevRow[j].pos[1]) then Inc(kpy);
         if Sign(curRow[j].pos[2])<>Sign(prevRow[j].pos[2]) then Inc(kpz);
      end;
      // k is a Value, which indicate the similarity of the normal vectors
      // between curRow and PrevRow
      k:=kx*ky*kz;
      // kp is a Value, which indicate the similarity of the positon vectors
      // between curRow and PrevRow
      kp:=kpx*kpy*kpz;
      // I hope, so i can distinguish, if the curRow must rotate
      if (k>Sqr(Slices div 2)) or (kp>Sqr(Slices div 2)) then begin
         SetLength(deltanormal, Slices);
         SetLength(deltapos, Slices);
         for k:=0 to Slices-1 do begin    //rotate index for curRow
            deltanormal[k]:=0;             //sum of difference for normal vector
            deltapos[k]:=0;                //sum of difference for pos vector
            for j:=0 to Slices-1 do begin  //over all places
               n:=(j+k) mod Slices;
               deltanormal[k]:=deltanormal[k]+VectorSpacing(curRow[n].normal, prevRow[j].normal);
               deltapos[k]   :=deltapos[k]   +VectorSpacing(curRow[n].pos,    prevRow[j].pos);
            end;
         end;
         //Search minimum
         // only search in deltapos, if i would search in deltanormal,
         // the same index of minimum would be found
         m:=0;
         for k:=1 to Slices-1 do
            if deltapos[m]>deltapos[k] then m:=k;
         // rotate count
         for k:=1 to m do begin
            // rotate the values of curRow
            curRow[Slices]:=curRow[0];
            System.Move(curRow[1], curRow[0], SizeOf(TNodeData)*Slices);
            curRow[Slices]:=curRow[0];
         end;
      end;
      // goon
      glBegin(GL_TRIANGLE_STRIP);
         glNormal3fv(@prevRow[0].normal);
         glVertex3fv(@prevRow[0].pos);
         for j:=0 to Slices-1 do begin
            glNormal3fv(@curRow[j].normal);
            glVertex3fv(@curRow[j].pos);
            glNormal3fv(@prevRow[j+1].normal);
            glVertex3fv(@prevRow[j+1].pos);
         end;
         glNormal3fv(@curRow[Slices].normal);
         glVertex3fv(@curRow[Slices].pos);
      glEnd;
   end;

{   procedure RenderSides(var curRow, prevRow : array of TNodeData);
   var
      j : Integer;
   begin
      glBegin(GL_TRIANGLE_STRIP);
         glNormal3fv(@prevRow[0].normal);
         glVertex3fv(@prevRow[0].pos);
         for j:=0 to Slices-1 do begin
            glNormal3fv(@curRow[j].normal);
            glVertex3fv(@curRow[j].pos);
            glNormal3fv(@prevRow[j+1].normal);
            glVertex3fv(@prevRow[j+1].pos);
         end;
         glNormal3fv(@curRow[Slices].normal);
         glVertex3fv(@curRow[Slices].pos);
      glEnd;
   end;}

var
   i, curRow, nbDivisions : Integer;
   normal, splinePos : TAffineVector;
   rows : array [0..1] of array of TNodeData;
   ra : PFloatArray;
   posSpline, rSpline : TCubicSpline;
   f, t : Single;
begin
   FTriangleCount:=0;
   if Nodes.Count=0 then Exit;
   SetLength(rows[0], Slices+1);
   SetLength(rows[1], Slices+1);
   SetLength(sinCache, Slices+1);
   SetLength(cosCache, Slices+1);
   PrepareSinCosCache(sinCache, cosCache, 0, 360);
   if (SplineMode=lsmCubicSpline) and (Nodes.Count>1) then begin
      posSpline:=Nodes.CreateNewCubicSpline;
      GetMem(ra, SizeOf(TGLFloat)*Nodes.Count);
      for i:=0 to Nodes.Count-1 do
         ra[i]:=TGLPipeNode(Nodes[i]).RadiusFactor;
      rSpline:=TCubicSpline.Create(ra, nil, nil, nil, Nodes.Count);
      FreeMem(ra);
      normal:=posSpline.SplineSlopeVector(0);
   end else begin
      normal:=Nodes.Vector(0);
      posSpline:=nil;
      rSpline:=nil;
   end;
   CalculateRow(rows[0], PAffineVector(@Nodes[0].AsVector)^, normal,
                TGLPipeNode(Nodes[0]).RadiusFactor);
   if ppStartDisk in Parts then begin
      NegateVector(normal);
      RenderDisk(rows[0], Nodes[0].AsVector, normal, True);
      FTriangleCount:=FTriangleCount+Slices+1;
   end;
   if (Nodes.Count>1) then begin
      if SplineMode=lsmCubicSpline then begin
         f:=1/Division;
         nbDivisions:=(Nodes.Count-1)*Division;
         for i:=1 to nbDivisions do begin
            t:=i*f;
            posSpline.SplineAffineVector(t, splinePos);
            normal:=posSpline.SplineSlopeVector(t);
            NormalizeVector(normal);
            curRow:=(i and 1);
            CalculateRow(rows[curRow], splinePos, normal,
                         rSpline.SplineX(t));
            if ppOutside in Parts then
               RenderSides(rows[curRow xor 1], rows[curRow]);
            if ppInside in Parts then
               RenderSides(rows[curRow], rows[curRow xor 1]);
         end;
         i:=nbDivisions*(Slices+1)*2;
         if ppOutside in Parts then Inc(FTriangleCount, i);
         if ppInside in Parts then Inc(FTriangleCount, i);
      end else begin
         for i:=1 to Nodes.Count-1 do begin
            curRow:=(i and 1);
            CalculateRow(rows[curRow], PAffineVector(@Nodes[i].AsVector)^,
                         Nodes.Vector(i), TGLPipeNode(Nodes[i]).RadiusFactor);
            if ppOutside in Parts then
               RenderSides(rows[curRow xor 1], rows[curRow]);
            if ppInside in Parts then
               RenderSides(rows[curRow], rows[curRow xor 1]);
         end;
         i:=Nodes.Count*(Slices+1)*2;
         if ppOutside in Parts then Inc(FTriangleCount, i);
         if ppInside in Parts then Inc(FTriangleCount, i);
      end;
   end;
   if ppStopDisk in Parts then begin
      i:=Nodes.Count-1;
      if SplineMode=lsmCubicSpline then
         normal:=posSpline.SplineSlopeVector(Nodes.Count-1)
      else normal:=Nodes.Vector(i);
      CalculateRow(rows[0], PAffineVector(@Nodes[i].AsVector)^, normal,
                   TGLPipeNode(Nodes[i]).RadiusFactor);
      RenderDisk(rows[0], Nodes[i].AsVector, normal, False);
      FTriangleCount:=FTriangleCount+Slices+1;
   end;
   if SplineMode=lsmCubicSpline then begin
      posSpline.Free;
      rSpline.Free;
   end;
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

	// class registrations
   RegisterClasses([TRevolutionSolid, TPipe]);

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
finalization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

end.

