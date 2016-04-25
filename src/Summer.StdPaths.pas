{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.StdPaths;

interface

uses
  System.TypInfo,
  System.Rtti,
  Summer.DuckIntf;

type
  /// <summary> API Para manejo de Paths estandar.
  /// Los paths se introducen con el separador / y se convierten
  /// al separador de la plataforma al ser usados. </summary>
  IStandardPaths = interface(IInvokable)
    ['{227DF8F5-E517-4611-89E7-A850D515CA80}']
  /// <summary> Devuelve el Path completo del ejecutable. Opcionalmente con la
  /// extension cambiada. </summary>
    function FullExeName(const NewExtension: string = '*'): string;
    function ExeFileName(const NewExtension: string = '*'): string;
  /// <summary> Devuelve el Path usando / como separador </summary>
    function ToStandardPath(const Path: string): string;
  ///<summary> Devuelve el Path usando el separador nativo de la plataforma </summary>
    function ToPlatformPath(const Path: string): string;
  ///<summary> El path Root se usa para calcular todos los paths relativos.</summary>
    function RootPath(const NestedPath: string = ''): string;
  ///<summary> Expande un path relativo a Root</summary>
    function ExpandPath(const Path: string): string;
  ///<summary> Path donde se encuentra el ejecutable de la aplicación</summary>
    function BinPath(const NestedPath: string = ''): string;

 {$REGION 'Paths estandar en IOUtils'}
    function TempPath(const NestedPath: string = ''): string;
    function HomePath(const NestedPath: string = ''): string;
    function DocumentsPath(const NestedPath: string = ''): string;
    function SharedDocumentsPath(const NestedPath: string = ''): string;
    function LibraryPath(const NestedPath: string = ''): string;
    function CachePath(const NestedPath: string = ''): string;
    function PublicPath(const NestedPath: string = ''): string;
    function PicturesPath(const NestedPath: string = ''): string;
    function SharedPicturesPath(const NestedPath: string = ''): string;
    function CameraPath(const NestedPath: string = ''): string;
    function SharedCameraPath(const NestedPath: string = ''): string;
    function MusicPath(const NestedPath: string = ''): string;
    function SharedMusicPath(const NestedPath: string = ''): string;
    function MoviesPath(const NestedPath: string = ''): string;
    function SharedMoviesPath(const NestedPath: string = ''): string;
    function AlarmsPath(const NestedPath: string = ''): string;
    function SharedAlarmsPath(const NestedPath: string = ''): string;
    function DownloadsPath(const NestedPath: string = ''): string;
    function SharedDownloadsPath(const NestedPath: string = ''): string;
    function RingtonesPath(const NestedPath: string = ''): string;
    function SharedRingtonesPath(const NestedPath: string = ''): string;
  {$ENDREGION}
  end;

type
  TStandardPaths = class(TDuckInterface)
  strict private
    FRootPath: string;
  protected
  /// Si el método invocado termina en 'Path', quita esta terminación
  /// y considera el resto un nombre de carpeta dentro de RootPath.
  /// Crea la carpeta especificada si no existe.
    procedure MethodMissing(Method: TRttiMethod; const Args: TArray<TValue>;
      out Result: TValue); override;
  public
    constructor Create(PIID: PTypeInfo; const RootPath: string);
  /// Establace el path Root. Si se pasa un path relativo, se referencian
  ///  desde BinPath.
    procedure SetRootPath(const Value: string);
    function ExeFileName(const NewExtension: string = '*'): string;
    function FullExeName(const NewExtension: string = '*'): string;
    function ToPlatformPath(const Path: string): string;
    function ToStandardPath(const Path: string): string;
    function ExpandPath(const Path: string): string;
    function RootPath(const NestedPath: string = ''): string;
    function BinPath(const NestedPath: string = ''): string;
    function TempPath(const NestedPath: string = ''): string;
    function HomePath(const NestedPath: string = ''): string;
    function DocumentsPath(const NestedPath: string = ''): string;
    function SharedDocumentsPath(const NestedPath: string = ''): string;
    function LibraryPath(const NestedPath: string = ''): string;
    function CachePath(const NestedPath: string = ''): string;
    function PublicPath(const NestedPath: string = ''): string;
    function PicturesPath(const NestedPath: string = ''): string;
    function SharedPicturesPath(const NestedPath: string = ''): string;
    function CameraPath(const NestedPath: string = ''): string;
    function SharedCameraPath(const NestedPath: string = ''): string;
    function MusicPath(const NestedPath: string = ''): string;
    function SharedMusicPath(const NestedPath: string = ''): string;
    function MoviesPath(const NestedPath: string = ''): string;
    function SharedMoviesPath(const NestedPath: string = ''): string;
    function AlarmsPath(const NestedPath: string = ''): string;
    function SharedAlarmsPath(const NestedPath: string = ''): string;
    function DownloadsPath(const NestedPath: string = ''): string;
    function SharedDownloadsPath(const NestedPath: string = ''): string;
    function RingtonesPath(const NestedPath: string = ''): string;
    function SharedRingtonesPath(const NestedPath: string = ''): string;
  end;

  /// Clase para extender los paths estandar con otros especificos
  ///  en nuestra aplicacion
  TStandardPaths<T: IStandardPaths> = class(TStandardPaths)
    constructor Create(const RootPath: string);
  end;

function ToStandardPath(const Path: string): string;
function ToPlatformPath(const Path: string): string;
implementation

uses
  System.SysUtils,
  System.IOUtils;

function ToStandardPath(const Path: string): string;
begin
  Result := StringReplace(Path, TPath.DirectorySeparatorChar, '/',
    [rfReplaceAll]);
end;

function ToPlatformPath(const Path: string): string;
begin
  Result := StringReplace(Path, '/', TPath.DirectorySeparatorChar, [rfReplaceAll]);
end;

{ TStandardPaths }

constructor TStandardPaths.Create(PIID: PTypeInfo; const RootPath: string);
begin
  inherited Create(PIID, Self);
  SetRootPath(RootPath);
end;

procedure TStandardPaths.MethodMissing(Method: TRttiMethod;
  const Args: TArray<TValue>; out Result: TValue);
var
  PathStr: string;
begin
  if not Method.Name.EndsWith('Path') then
  begin
    inherited MethodMissing(Method, Args, Result);
    Exit;
  end;

  PathStr := RootPath(Copy(Method.Name, 1, Method.Name.Length - Length('Path')));
  TDirectory.CreateDirectory(PathStr);
  Result := ToPlatformPath(TPath.Combine(PathStr, Args[1].ToString));
end;

function TStandardPaths.FullExeName(const NewExtension: string = '*'): string;
begin
  // ToDo: ParamStr(0) don't works in all platforms
  Result := ParamStr(0);
  if Result.IsEmpty then Exit;

  if NewExtension = '*' then
    Exit;
  if NewExtension = '' then
    Exit(TPath.GetFileNameWithoutExtension(Result));
  Result := TPath.ChangeExtension(Result, NewExtension)
end;

function TStandardPaths.ExeFileName(const NewExtension: string = '*'): string;
begin
  Result := TPath.GetFileName(FullExeName(NewExtension));
end;

function TStandardPaths.ToStandardPath(const Path: string): string;
begin
  Result := Summer.StdPaths.ToStandardPath(Path);
end;

function TStandardPaths.ToPlatformPath(const Path: string): string;
begin
  Result := Summer.StdPaths.ToPlatformPath(Path);
end;

procedure TStandardPaths.SetRootPath(const Value: string);
begin
  if TPath.IsRelativePath(Value) and not BinPath.IsEmpty then
    FRootPath := TPath.GetFullPath(TPath.Combine(BinPath, ToPlatformPath(Value)))
  else
    FRootPath := Value;
end;

function TStandardPaths.ExpandPath(const Path: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(FRootPath, ToPlatformPath(Path)));
end;

function TStandardPaths.RootPath(const NestedPath: string): string;
begin
  Result := ExpandPath('./' + NestedPath);
end;

function TStandardPaths.BinPath(const NestedPath: string): string;
begin
  // BinPath is fixed by EXE path
  Result := TPath.GetDirectoryName(FullExeName);
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.TempPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetTempPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.HomePath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetHomePath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.LibraryPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetLibraryPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.CachePath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetCachePath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.CameraPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetCameraPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.DocumentsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetDocumentsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.DownloadsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetDownloadsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.MoviesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetMoviesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.MusicPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetMusicPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.PicturesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetPicturesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.PublicPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetPublicPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedAlarmsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedAlarmsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedCameraPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedCameraPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedDocumentsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedDocumentsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedDownloadsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedDownloadsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedMoviesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedMoviesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedMusicPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedMusicPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedPicturesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedPicturesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.SharedRingtonesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetSharedRingtonesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.RingtonesPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetRingtonesPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

function TStandardPaths.AlarmsPath(const NestedPath: string = ''): string;
begin
  Result := TPath.GetAlarmsPath;
  Result := ToPlatformPath(TPath.Combine(Result, NestedPath));
end;

{ TStandardPaths<T> }

constructor TStandardPaths<T>.Create(const RootPath: string);
begin
  inherited Create(TypeInfo(T), RootPath);
end;

end.
