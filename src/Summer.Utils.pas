{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit Summer.Utils;

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  System.TypInfo,
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.Rtti,
  System.JSON;

{$SCOPEDENUMS ON}

type
  TOpenEnum = record
  type
    Code = Integer;
    CodeSet = array of Code;
  public // yes! in order we can declare as initialized const
    FValue: Code;
    FID: string;
  public
    constructor Create(AValue: Code; AID: string);
    class function &Set(Values: array of TOpenEnum): CodeSet; static;
    class operator Equal(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator NotEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator GreaterThan(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator GreaterThanOrEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator LessThan(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator LessThanOrEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator Implicit(Enum: TOpenEnum): string;
    class operator Implicit(Enum: TOpenEnum): Integer;
    function ToString: string;
    function MemberOf(Codes: CodeSet): Boolean;
    property Value: Code read FValue;
    property ID: string read FID;
  end;

  TFreeNotifier = class(TComponent)
  private
    FOnFreeNotification: TProc<TComponent>;
    FOnDestroy: TProc<TComponent>;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoOnDestroy; virtual;
    procedure DoOnFreeNotification(Sender: TComponent); virtual;
  public
    destructor Destroy; override;
    property OnFreeNotification: TProc<TComponent> read FOnFreeNotification write FOnFreeNotification;
    property OnDestroy: TProc<TComponent> read FOnDestroy write FOnDestroy;
  end;

  IOwnedList = interface
    ['{60FA02D9-7CC9-40D8-9CC2-7CF085E6F761}']
    procedure Clear;
    procedure Add(Owned: TObject);
    function Contains(Value: TObject): Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
  end;

  TOwnedList = class(TInterfacedObject, IOwnedList)
  strict private
    FOwneds: TObjectList<TObject>;
  private
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(Owned: TObject);
    function Contains(Value: TObject): Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
  end;

  TPurgatory = record
  private
    FOwneList: IOwnedList;
    function OwneList: IOwnedList;
  public
    procedure Clear;
    procedure Add(Owned: TObject);
    function Contains(Value: TObject): Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
  end;

  TWeakInterfaced = class(TInterfacedObject, IInterface)
  private
    FWeakRef: Boolean;
  public
    function WeakRef(const Value: Boolean): TWeakInterfaced;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  TOSShell = class
  public type
    ShowMode = (Hide, Normal);

  public
    class function Open(Command: string; Parameters: string = ''; const Mode: ShowMode = ShowMode.Normal): Integer;
    // TODO: impl for MACOS ??
    class function RunAs(Command: string; Parameters: string = ''; const Mode: ShowMode = ShowMode.Normal): Cardinal;
  end;

  TDebugger = class
  public
    class procedure Output(const FmtText: string; Args: array of const); overload;
    class procedure Output(Text: string); overload;
    class function IsEnabled: Boolean;
  end;

  TSlice = record
  public type
    PItem = ^TItem;
    PSlice = ^TSlice;

    TItem = record
    private
      FIndex: Integer;
      FName: string;
      FValue: TValue;
      FRtti: TRttiInstanceProperty;
      FIsStored: Boolean;
      function GetIsProperty: Boolean;
      function GetAsVariant: Variant;
      function GetAsJSONValue: TJSONValue;
      procedure SetValue(const Value: TValue);
    public
      property index: Integer read FIndex;
      property Name: string read FName;
      property Value: TValue read FValue write SetValue;
      property AsVariant: Variant read GetAsVariant;
      property AsJSONValue: TJSONValue read GetAsJSONValue;
      property IsStored: Boolean read FIsStored;
      property Rtti: TRttiInstanceProperty read FRtti;
      property IsProperty: Boolean read GetIsProperty;
    end;

  TEnumProc = reference to procedure(var Item: TItem; var StopEnum: Boolean);
  private
  strict private
    RC: TRTTIContext;
    FForClass: TClass;
    FItems: TArray<TItem>;
    function GetItemOf(Name: string): PItem;
    procedure SetForClass(const Value: TClass);

  public
    constructor Create(const ANames: array of string; const AClass: TClass = nil); overload;
    constructor Create(const ANames: array of string; const Instance: TObject); overload;
    constructor Create(const Instance: TObject); overload;
    constructor Create(const AClass: TClass);overload;
    constructor Create(const JSONObj: TJSONObject); overload;
    constructor Create(Name: string; Value: TValue);overload;
    function ToJSONObject: TJSONObject;
    class operator Implicit(const Value: TSlice): TJSONObject;
    class operator Implicit(const Value: TJSONObject): TSlice;
    function Add(Name: string): TSlice;overload;
    function Add(AName: string; AValue: TValue): TSlice;overload;
    function Count: Integer;
    function IndexOf(const AName: string): Integer;
    function Contains(const AName: string): Boolean;
    function GetNames: TArray<string>;
    function GetValues: TArray<Variant>;
    procedure Read(Instance: TObject);
    procedure ForEach(Proc: TEnumProc);
    property ForClass: TClass read FForClass write SetForClass;
    property Items: TArray<TItem> read FItems;
    property ItemOf[index: string]: PItem read GetItemOf; default;
  end;

  TTextComparer = class(TInterfacedObject, IEqualityComparer<string>)
  public
    function Equals(const Left, Right: string): Boolean; reintroduce;
    function GetHashCode(const Value: string): Integer; reintroduce;
  end;

  /// Compiler don't supports Helpers for generics. Best guest:
  TObjectListHelper<T: class, constructor> = class(TObjectList<T>)
  public
    function IsEmpty: Boolean;
    function First: T;
    function Last: T;
    function AsJSON: TJSONArray;
  end;

  /// Used to cast generic TObjectList<T> types:
  /// Don't add state fields, no virtual methods !!!
  /// FItemClass is special: Summer.RTTI use it in TryObjListItemClass
  TAnyObjecList = class(TObjectListHelper<TObject>)
  strict private
    FItemClass: TClass;
  private
    function GetItemClass: TClass;
  public
    constructor Create(ItemClass: TClass = nil);
    property ItemClass: TClass read GetItemClass;
  end;

  TAnyObjecListClass = class of TAnyObjecList;

  TBenchmark = class
  public
    class function Measure(P: TProc): Int64;
    class function StopWatch(P: TProc): TStopWatch;
  end;

implementation

uses
  Summer.Rtti,
  Summer.JSON,
  {$IF DEFINED(IOS)}
  iOSapi.Foundation,
  {$ENDIF}
  {$IF DEFINED(ANDROID)}
  Androidapi.Log,
  {$ENDIF}
  {$IF DEFINED(MSWINDOWS)}
  Winapi.ShellAPI,
  Winapi.Windows
  {$ENDIF}
  {$IF DEFINED(POSIX)}
    Posix.Stdlib
  {$ENDIF POSIX}
    ;

class function TBenchmark.Measure(P: TProc): Int64;
begin
  Result := StopWatch(P).ElapsedMilliseconds;
end;

class function TBenchmark.StopWatch(P: TProc): TStopWatch;
begin
  Result := TStopWatch.StartNew;
  P();
  Result.Stop;
end;

{$IF DEFINED(IOS)}

procedure PlatformOutputDebug(const Text: string);
begin
  NSLog((StrToNSStr(Text) as ILocalObject).GetObjectID);
end;
{$ENDIF}
{$IF DEFINED(ANDROID)}

procedure PlatformOutputDebug(const Text: string);
var
  M: TMarshaller;
begin
  LOGI(M.AsAnsi(Text).ToPointer);
end;
{$ENDIF}
{$IF DEFINED(MACOS)}

procedure PlatformOutputDebug(const Text: string);
begin
  WriteLn(Text);
end;
{$ENDIF}
{$IF DEFINED(MSWINDOWS)}

procedure PlatformOutputDebug(const Text: string);
begin
  OutputDebugString(PChar(Text));
end;
{$ENDIF}

{ TOwnedList }

procedure TOwnedList.Clear;
begin
  FOwneds.Clear;
end;

function TOwnedList.Contains(Value: TObject): Boolean;
begin
  Result := FOwneds.Contains(Value);
end;

function TOwnedList.Count: Integer;
begin
  Result := FOwneds.Count;
end;

constructor TOwnedList.Create;
begin
  inherited Create;
  FOwneds := TObjectList<TObject>.Create(True);
end;

destructor TOwnedList.Destroy;
begin
  FOwneds.Free;
  inherited;
end;

function TOwnedList.IsEmpty: Boolean;
begin
  Result := FOwneds.Count = 0;
end;

procedure TOwnedList.Add(Owned: TObject);
begin
  FOwneds.Add(Owned);
end;

{ TPurgatory }

procedure TPurgatory.Add(Owned: TObject);
begin
  OwneList.Add(Owned);
end;

procedure TPurgatory.Clear;
begin
  OwneList.Clear;
end;

function TPurgatory.Contains(Value: TObject): Boolean;
begin
  Result := OwneList.Contains(Value);
end;

function TPurgatory.Count: Integer;
begin
  Result := OwneList.Count
end;

function TPurgatory.IsEmpty: Boolean;
begin
  Result := OwneList.IsEmpty;
end;

function TPurgatory.OwneList: IOwnedList;
begin
  if FOwneList = nil then
    FOwneList := TOwnedList.Create;
  Result := FOwneList;
end;

{ TFreeNotifier }

destructor TFreeNotifier.Destroy;
begin
  DoOnDestroy;
  FOnFreeNotification := nil;
  FOnDestroy := nil;
  inherited;
end;

procedure TFreeNotifier.DoOnFreeNotification(Sender: TComponent);
begin
  if Assigned(FOnFreeNotification) then
    FOnFreeNotification(Self);
end;

procedure TFreeNotifier.DoOnDestroy;
begin
  if Assigned(FOnDestroy) then
    FOnDestroy(Self);
end;

procedure TFreeNotifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
    DoOnFreeNotification(AComponent);
  inherited;
end;

{ TWeakInterfaced }

function TWeakInterfaced.WeakRef(const Value: Boolean): TWeakInterfaced;
begin
  Result := Self;
  FWeakRef := Value;
  if FWeakRef then
    FRefCount := 0
  else
    FRefCount := 1;
end;

function TWeakInterfaced._AddRef: Integer;
begin
  if not FWeakRef then
    inherited;
  Result := RefCount
end;

function TWeakInterfaced._Release: Integer;
begin
  if not FWeakRef then
    inherited;
  Result := RefCount
end;

{ TOpenEnum }

class function TOpenEnum.&Set(Values: array of TOpenEnum): TOpenEnum.CodeSet;
var
  idx: Integer;
begin
  SetLength(Result, 1 + high(Values));
  for idx := low(Values) to high(Values) do
    Result[idx] := Values[idx];
end;

constructor TOpenEnum.Create(AValue: TOpenEnum.Code; AID: string);
begin
  FValue := AValue;
  FID := AID;
end;

class operator TOpenEnum.Equal(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue = B.FValue;
end;

class operator TOpenEnum.NotEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue <> B.FValue;
end;

function TOpenEnum.ToString: string;
begin
  Result := FID;
end;

function TOpenEnum.MemberOf(Codes: TOpenEnum.CodeSet): Boolean;
var
  I: Integer;
begin
  for I := low(Codes) to high(Codes) do
    if (Value = Codes[I]) then
      Exit(True);
  Result := False;
end;

class operator TOpenEnum.GreaterThan(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue > B.FValue;
end;

class operator TOpenEnum.GreaterThanOrEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue >= B.FValue;
end;

class operator TOpenEnum.LessThan(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue < B.FValue;
end;

class operator TOpenEnum.LessThanOrEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue <= B.FValue;
end;

class operator TOpenEnum.Implicit(Enum: TOpenEnum): Integer;
begin
  Result := Enum.FValue;
end;

class operator TOpenEnum.Implicit(Enum: TOpenEnum): string;
begin
  Result := Enum.ToString;
end;

{ TOSShell }

class function TOSShell.Open(Command: string; Parameters: string = ''; const Mode: ShowMode = ShowMode.Normal): Integer;
{$IF DEFINED(MSWINDOWS)}
const
  SWMODE: array [ShowMode] of ShortInt = (SW_HIDE, SW_SHOWNORMAL);
  {$ENDIF}
begin
  {$IF DEFINED(MSWINDOWS)}
  Result := ShellExecute(0, 'OPEN', PChar(Command), PChar(Parameters), '', SWMODE[Mode]);
  {$ELSEIF DEFINED(MACOS)}
  Result := _system(PAnsiChar('open ' + AnsiString(sCommand + ' ' + Options)));
  {$ELSE}
  Result := -1;
  {$ENDIF}
end;

{$IF DEFINED(MSWINDOWS)}

class function TOSShell.RunAs(Command: string; Parameters: string; const Mode: ShowMode): Cardinal;
var
  ShellExecInfo: TShellExecuteInfo;
begin
  ZeroMemory(@ShellExecInfo, SizeOf(ShellExecInfo));
  ShellExecInfo.cbSize := SizeOf(TShellExecuteInfo);
  ShellExecInfo.Wnd := 0;
  ShellExecInfo.fMask := SEE_MASK_NOASYNC or SEE_MASK_FLAG_NO_UI;
  ShellExecInfo.lpVerb := PChar('runas');
  ShellExecInfo.lpFile := PChar(Command);
  if Parameters <> '' then
    ShellExecInfo.lpParameters := PChar(Parameters);
  if Mode = ShowMode.Hide then
    ShellExecInfo.nShow := SW_HIDE
  else
    ShellExecInfo.nShow := SW_SHOWNORMAL;
  ShellExecuteEx(@ShellExecInfo);
  Result := GetLastError;
end;

{$ELSE}

class function TOSShell.RunAs(Command: string; Parameters: string; const Mode: ShowMode): Cardinal;
begin
  Result := 0;
end;
{$ENDIF}
{ TDebugger }

class function TDebugger.IsEnabled: Boolean;
begin
  {$WARNINGS  OFF}
  Result := Boolean(DebugHook);
  {$WARNINGS  ON}
end;

class procedure TDebugger.Output(const FmtText: string; Args: array of const);
begin
  Output(Format(FmtText, Args));
end;

class procedure TDebugger.Output(Text: string);
begin
  PlatformOutputDebug(Text);
end;

{ TSlice.TItem }

function TSlice.TItem.GetAsJSONValue: TJSONValue;
begin
  Result := Value.AsJSON
end;

function TSlice.TItem.GetAsVariant: Variant;
begin
  Result := FValue.AsVariant;
end;

function TSlice.TItem.GetIsProperty: Boolean;
begin
  Result := Assigned(FRtti);
end;

procedure TSlice.TItem.SetValue(const Value: TValue);
var
  Temp: TValue;
begin
  Temp := Value;
  if Assigned(Rtti) then
    Value.Convert(Rtti.PropertyType.Handle, Temp);
  FValue := Temp;
end;

{ TSlice }

constructor TSlice.Create(const AClass: TClass);
begin
  Create([], AClass);
end;

constructor TSlice.Create(const Instance: TObject);
begin
  Create([], Instance);
end;

constructor TSlice.Create(const ANames: array of string; const AClass: TClass = nil);
var
  idx: Integer;
begin
  SetLength(FItems, System.Length(ANames));
  for idx := 0 to Length(ANames) - 1 do begin
    FItems[idx].FIndex := idx;
    FItems[idx].FIsStored := True;
    FItems[idx].FName := ANames[idx];
  end;
  ForClass := AClass;
end;

constructor TSlice.Create(const ANames: array of string; const Instance: TObject);
begin
  Assert(Instance <> nil);
  Create(ANames, Instance.ClassType);
  Read(Instance);
end;

constructor TSlice.Create(const JSONObj: TJSONObject);
var
  idx: Integer;
begin
  SetLength(FItems, JSONObj.Count);
  for idx := 0 to JSONObj.Count - 1 do begin
    FItems[idx].FIndex := idx;
    FItems[idx].FIsStored := True;
    FItems[idx].FName := JSONObj.Pairs[idx].JsonString.Value;
    FItems[idx].FValue := TValue.FromJSON(JSONObj.Pairs[idx].JsonValue);
  end;
end;

constructor TSlice.Create(Name: string; Value: TValue);
begin
  Create([]);
  Add(Name, Value);
end;

procedure TSlice.Read(Instance: TObject);
var
  RInstance: TRttiInstanceType;
  RProp: TRttiInstanceProperty;
begin
  if Instance = nil then
    Exit;
  if Count = 0 then
    ForClass := Instance.ClassType;

  RInstance := RC.GetType(ForClass) as TRttiInstanceType;
  ForEach(
    procedure(var Item: TItem; var StopEnum: Boolean)
    begin
      RProp := RInstance.GetProperty(Item.Name) as TRttiInstanceProperty;
      if RProp = nil then
        Exit;
      Item.FValue := RProp.GetValue(Instance);
      Item.FIsStored := IsStoredProp(Instance, RProp.PropInfo)
    end);
end;

procedure TSlice.SetForClass(const Value: TClass);
var
  idx: Integer;
  RC: TRTTIContext;
  RInstance: TRttiInstanceType;
  RProperties: TArray<TRttiProperty>;
  FoundCount: Integer;
  HasItems: Boolean;
begin
  FForClass := Value;
  if FForClass = nil then
    Exit;

  RInstance := RC.GetType(FForClass) as TRttiInstanceType;
  HasItems := (Count > 0);
  FoundCount := 0;
  if not HasItems then begin
    RProperties := RInstance.GetProperties;
    for idx := 0 to Length(RProperties) - 1 do
      if (RProperties[idx].Visibility in [mvPublic, mvPublished]) then
        inc(FoundCount);
    SetLength(FItems, FoundCount);
    FoundCount := 0;
    for idx := 0 to Length(RProperties) - 1 do begin
      if not(RProperties[idx].Visibility in [mvPublic, mvPublished]) then
        Continue;
      FItems[FoundCount].FIndex := FoundCount;
      FItems[FoundCount].FIsStored := True;
      FItems[FoundCount].FName := RProperties[idx].Name;
      FItems[FoundCount].FRtti := RProperties[idx] as TRttiInstanceProperty;
      inc(FoundCount);
    end;
  end;

  ForEach(
    procedure(var Item: TItem; var StopEnum: Boolean)
    begin
      Item.FRtti := RInstance.GetProperty(Item.Name) as TRttiInstanceProperty;
    end);
end;

function TSlice.ToJSONObject: TJSONObject;
var
  JSONObject: TJSONObject;
begin
  JSONObject := TJSONObject.Create;
  ForEach(
    procedure(var Item: TItem; var DoStop: Boolean)
    begin
      JSONObject.AddPair(TJSONPair.Create(Item.Name, Item.Value.AsJSON))
    end);
  Result := JSONObject;
end;

function TSlice.Add(Name: string): TSlice;
begin
  Result := Add(Name, nil);
end;

function TSlice.Add(AName: string; AValue: TValue): TSlice;
begin
  SetLength(FItems, Length(FItems) + 1);
  with FItems[Length(FItems) - 1] do begin
    FIndex := Length(FItems) - 1;
    FName := AName;
    FIsStored := True;
    FValue := AValue;
  end;
  Result := Self;
end;

function TSlice.Contains(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > -1;
end;

class operator TSlice.Implicit(const Value: TSlice): TJSONObject;
begin
  Result := Value.ToJSONObject;
end;

class operator TSlice.Implicit(const Value: TJSONObject): TSlice;
begin
  Result := TSlice.Create(Value);
end;

function TSlice.IndexOf(const AName: string): Integer;
var
  idx: Integer;
begin
  for idx := 0 to Count - 1 do
    if SameText(FItems[idx].FName, AName) then
      Exit(idx);
  Result := -1
end;

procedure TSlice.ForEach(Proc: TEnumProc);
var
  idx: Integer;
  StopEnum: Boolean;
begin
  StopEnum := False;
  for idx := 0 to Count - 1 do begin
    Proc(FItems[idx], StopEnum);
    if StopEnum then
      Break;
  end;
end;

function TSlice.GetItemOf(Name: string): PItem;
var
  idx: Integer;
begin
  idx := IndexOf(name);
  if idx = -1 then
    raise Exception.CreateFmt('%s not found', [name]);
  Result := @FItems[idx]
end;

function TSlice.GetNames: TArray<string>;
var
  idx: Integer;
begin
  SetLength(Result, Count);
  for idx := 0 to Count - 1 do
    Result[idx] := FItems[idx].Name
end;

function TSlice.GetValues: TArray<Variant>;
var
  idx: Integer;
begin
  SetLength(Result, Count);
  for idx := 0 to Count - 1 do
    Result[idx] := FItems[idx].AsVariant;
end;

function TSlice.Count: Integer;
begin
  Result := System.Length(FItems);
end;

{ TTextComparer }

function TTextComparer.Equals(const Left, Right: string): Boolean;
begin
  Result := CompareText(Left, Right) = 0;
end;

function TTextComparer.GetHashCode(const Value: string): Integer;
begin
  Result := Value.GetHashCode;
end;

{ TAnyObjecList }

constructor TAnyObjecList.Create(ItemClass: TClass);
begin
  inherited Create;
  if ItemClass = nil then
    FItemClass := TObject
  else
    FItemClass := ItemClass;
end;

{ TDataList<T> }

function TObjectListHelper<T>.IsEmpty: Boolean;
begin
  Result := (Self = nil) or (Count = 0);
end;

function TObjectListHelper<T>.AsJSON: TJSONArray;
begin
  Result := TJSON.ToJSONArray(Self);
end;

function TObjectListHelper<T>.First: T;
begin
  if IsEmpty then
    Exit(nil);
  Result := inherited;
end;

function TObjectListHelper<T>.Last: T;
begin
  if IsEmpty then
    Exit(nil);
  Result := inherited;
end;

function TAnyObjecList.GetItemClass: TClass;
begin
  // Check no invoke from a Cast of TObjectList<T>
  if Self.InheritsFrom(TAnyObjecList) then
    Result := FItemClass
  else
    Result := ClassType.ObjListItemClass
end;

end.
