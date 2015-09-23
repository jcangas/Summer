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
  System.Rtti,
  System.JSON,
  Data.DB;

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
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DoOnDestroy; virtual;
    procedure DoOnFreeNotification(Sender: TComponent); virtual;
  public
    destructor Destroy; override;
    property OnFreeNotification: TProc<TComponent> read FOnFreeNotification
      write FOnFreeNotification;
    property OnDestroy: TProc<TComponent> read FOnDestroy write FOnDestroy;
  end;

  TValueHelper = record helper for TValue
  private
    function ArrayToJSON(const AArray: TValue): TJSONArray;
    class function JSONToArray(const AArray: TJSONArray): TValue; static;
  public
    class function FromJSON(Value: TJSONValue): TValue; static;
    function Convert(ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
    function AsArray: TArray<TValue>;
    function AsJSON: TJSONValue;
    function IsEnum: Boolean;
    function IsNumber: Boolean;
    function IsInteger: Boolean;
    function IsFloat: Boolean;
    function IsString: Boolean;
    function IsBoolean: Boolean;
    function IsChar: Boolean;
    function IsDate: Boolean;
    function IsTime: Boolean;
    function IsDateTime: Boolean;
    function AsDef<T>(Def: T): T;
  end;

type
  TOSShell = class
  public type
    TShowMode = (Hide, Normal);
  class function Open(Command: string; Parameters: string = '';
    const Mode: TShowMode = Normal): Integer;
  // TODO: impl for MACOS ??
  class function RunAs(Command: string; Parameters: string = '';
    const Mode: TShowMode = Normal): Cardinal;
  end;

  TDebugger = class
  public
    class procedure Output(const FmtText: string;
      Args: array of const); overload;
    class procedure Output(Text: string); overload;
    class function IsEnabled: Boolean;
  end;

  TJSON = class
  public
    class function ToJSONObject(const AObject: TObject): TJSONObject;
    class function ToJSONArray(const ObjectList): TJSONArray;
  end;

  TEncrypt = class
  public
    /// A very simple symetric encrypt
    function Simple(const Value: TBytes): TBytes;
  end;

  TVoteQuality = (vqRequires, vqPrefers);
  TVote = record
  const
    VETO = Integer.MinValue;
  var
    Value: Integer;
    class operator Implicit(AQuality: TVoteQuality): TVote;
    class operator Implicit(AInteger: Integer): TVote;
    class operator Implicit(AVote: TVote): Integer;
  end;
  TVoteFunc = reference to function(const Method: TRttiMethod): TVote;
  TMethodVoter = record helper for TMethod
    class function KindIs(const AMethodKind: TMethodKind;Quality: TVoteQuality = vqRequires): TVoteFunc;static;
    class function NameIs(const AName: string;Quality: TVoteQuality = vqRequires): TVoteFunc;static;
    class function NoArgs(Quality: TVoteQuality = vqRequires): TVoteFunc;static;
    class function ArgsMatch(const SomeArgs: TArray<TValue>;Quality: TVoteQuality = vqRequires): TVoteFunc;static;
  end;

  TInvokeHelper = class helper for TObject
  private
    class function Voting(Method: TRttiMethod; Voters: TArray<TVoteFunc>): TVote;
  public
    class function IsObjectList: Boolean;
    class function DefaultCtor: TRttiMethod;
    class function TryInvokeDefaultCtor(out ResultValue: TObject): Boolean;
    class function InvokeDefaultCtor: TObject;
    class function MethodBy(Voters: TArray<TVoteFunc>): TRttiMethod;
    class function ClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
    class function TryClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
    function TryInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
    function Invoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
  end;

  TSlice = record
  public type
    PItem = ^TItem;
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
    class var RC: TRTTIContext;
  strict private
    FForClass: TClass;
    FItems: TArray<TItem>;
    function GetItemOf(Name: string): PItem;
    procedure SetForClass(const Value: TClass);

  public
    constructor Create(const ANames: array of string; const AClass: TClass = nil); overload;
    constructor Create(const ANames: array of string; const Instance: TObject); overload;
    constructor Create(const Instance: TObject); overload;
    constructor Create(const Value: TJSONObject);overload;
    function ToJSONObject: TJSONObject;
    class operator Implicit(const Value: TSlice): TJSONObject;
    class operator Implicit(const Value: TJSONObject): TSlice;
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

  TValuesInjector = class
  private
  public
    class procedure InjectFields(Target: TObject; Source: TDataset);
    class procedure InjectItems(Target: TObject; Source: TSlice);
    class procedure InjectProps(Target: TObject; Source: TObject);
  end;

  TTextComparer = class(TInterfacedObject, IEqualityComparer<string>)
  public
    function Equals(const Left, Right: string): Boolean; reintroduce;
    function GetHashCode(const Value: string): Integer; reintroduce;
  end;


implementation

uses
  Summer.Config,
{$IF DEFINED(IOS)}
  iOSapi.Foundation,
{$ENDIF}
{$IF DEFINED(ANDROID)}
  Androidapi.Log,
{$ENDIF}
{$IF DEFINED(MSWINDOWS)}
  Winapi.ShellAPI, Winapi.Windows
{$ENDIF}
{$IF DEFINED(POSIX)}
    Posix.Stdlib
{$ENDIF POSIX}
    ;

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

{ TVote }

class operator TVote.Implicit(AInteger: Integer): TVote;
begin
  Result.Value := AInteger;
end;

class operator TVote.Implicit(AVote: TVote): Integer;
begin
  Result := AVote.Value
end;


class operator TVote.Implicit(AQuality: TVoteQuality): TVote;
begin
  if (AQuality = vqRequires) then
    Result := VETO
  else
    Result := 0;  
end;

{ TInvokeHelper }

class function TInvokeHelper.IsObjectList: Boolean;
begin
  Result := False;
  if Self = nil then Exit;
  if Self = TObject then Exit;
  Result := Classname.StartsWith('TObjectList') or ClassParent.IsObjectList;
end;

class function TInvokeHelper.Voting(Method: TRttiMethod; Voters: TArray<TVoteFunc>): TVote;
var
  Vote: Integer;
  Voter: TVoteFunc;
begin
  Result := 0;
  for Voter in Voters do begin
    Vote := Voter(Method);
    if TVote.VETO = Vote then
      Exit(TVote.VETO);
    Result := Result.Value + Vote;
  end;
end;

class function TInvokeHelper.ClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
begin
  if not TryClassInvoke(Args, Voters, Result) then
    raise Exception.Create('Method for Invoke not found');
end;

class function TInvokeHelper.TryClassInvoke(Args: TArray<TValue>;  Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
var
  Method: TRTTIMethod;
begin
  Result := False;
  Method := Self.MethodBy(Voters + [TMethod.ArgsMatch(Args)]);
  if Method = nil then Exit;
  ResultValue := Method.Invoke(Self, Args).AsObject;
  Result := True;
end;

class function TInvokeHelper.DefaultCtor: TRttiMethod;
begin
  Result := MethodBy([TMethod.KindIs(mkConstructor), TMethod.NoArgs, TMethod.NameIs('Create', vqPrefers)]);
end;

class function TInvokeHelper.TryInvokeDefaultCtor(out ResultValue: TObject): Boolean;
var
  Method: TRTTIMethod;
begin
  Result := False;
  Method := DefaultCtor;
  if Method = nil then Exit;
  ResultValue := Method.Invoke(Self, []).AsObject;
  Result := True;
end;

function TInvokeHelper.Invoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
begin
  if not TryInvoke(Args, Voters, Result) then
    raise Exception.Create('Method for Invoke not found');
end;

class function TInvokeHelper.InvokeDefaultCtor: TObject;
begin
  if not TryInvokeDefaultCtor(Result) then
    raise Exception.Create('No default constructor found');
end;

function TInvokeHelper.TryInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
var
  Method: TRTTIMethod;
begin
  Result := False;
  if Self = nil then Exit;
  Method := Self.ClassType.MethodBy(Voters + [TMethod.ArgsMatch(Args)]);
  if Method = nil then Exit;
  ResultValue := Method.Invoke(Self, Args);
  Result := True;
end;


class function TInvokeHelper.MethodBy(Voters: TArray<TVoteFunc>): TRttiMethod;
var
  RC: TRttiContext;
  RType: TRttiInstanceType;
  Method: TRttiMethod;
  Points: Integer;
  BetterPoints: Integer;

begin
  Result := nil;
  if Self = nil then Exit;
  BetterPoints := Integer.MinValue;
  RType := RC.GetType(Self) as TRttiInstanceType;
  for Method in RType.GetMethods do begin
    Points := Voting(Method, Voters);
    if Points > BetterPoints then begin
      Result := Method;
      BetterPoints := Points;
    end;
  end;
end;

{ TMethodVoter }

class function TMethodVoter.KindIs(const AMethodKind: TMethodKind;
  Quality: TVoteQuality = vqRequires): TVoteFunc;
begin
  Result := function(const Method: TRttiMethod): TVote
    begin
      Result := Quality;
      if not(Method.MethodKind = AMethodKind) then Exit;
      Result := 1;
    end;
end;

class function TMethodVoter.NameIs(const AName: string;
  Quality: TVoteQuality): TVoteFunc;
begin
  Result := function(const Method: TRttiMethod): TVote
    begin
      Result := Quality;
      if not SameText(AName, Method.Name) then Exit;
      Result := 1;
    end;
end;

class function TMethodVoter.NoArgs(Quality: TVoteQuality): TVoteFunc;
begin
  Result := ArgsMatch([], Quality);
end;

class function TMethodVoter.ArgsMatch(const SomeArgs: TArray<TValue>; Quality: TVoteQuality = vqRequires): TVoteFunc;
var
  CopyArgs: TArray<TValue>;
begin
  CopyArgs := SomeArgs;
  Result := function(const Method: TRttiMethod): TVote
    var
      Parms: TArray<TRttiParameter>;
      idx: Integer;
    begin
      Result := Quality;
      Parms := Method.GetParameters;
      if (Length(Parms) <> Length(CopyArgs)) then
        Exit;
      for idx := 0 to high(CopyArgs) do
        if CopyArgs[idx].TypeInfo <> Parms[idx].ParamType.Handle then
          Exit;
      Result := 1;
    end;
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

procedure TFreeNotifier.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if Operation = opRemove then
    DoOnFreeNotification(AComponent);
  inherited;
end;

{ TOpenEnum }

class function TOpenEnum.&Set(Values: array of TOpenEnum): TOpenEnum.CodeSet;
var
  idx: Integer;
begin
  SetLength(Result, 1 + High(Values));
  for idx := Low(Values) to High(Values) do
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
  for I := Low(Codes) to High(Codes) do
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

{ TValueHelper }

class function TValueHelper.FromJSON(Value: TJSONValue): TValue;
begin
  if (Value = nil) or Value.Null then
    Result := TValue.Empty
  else if Value.InheritsFrom(TJSONTrue) then
    Result := True
  else if Value.InheritsFrom(TJSONFalse) then
    Result := False
  else if Value.InheritsFrom(TJSONNumber) then
  begin
    if Value.Value.Contains(GetJSONFormat.DecimalSeparator) then
      Result := (Value as TJSONNumber).AsDouble
    else
      Result := (Value as TJSONNumber).AsInt64
  end
  else if Value.InheritsFrom(TJSONArray) then
    Result := JSONToArray(Value as TJSONArray)
  else if Value.InheritsFrom(TJSONObject) then
    Result := (Value as TJSONObject)
  else // string
    Result := Value.Value
end;

function TValueHelper.ArrayToJSON(const AArray: TValue): TJSONArray;
var
  idx: Integer;
begin
  Result := TJSONArray.Create;
  for idx := 0 to AArray.GetArrayLength - 1 do
  begin
    Result.AddElement(AArray.GetArrayElement(idx).AsJSON);
  end;
end;

class function TValueHelper.JSONToArray(const AArray: TJSONArray): TValue;
var
  Ary: TArray<TValue>;
  idx: Integer;
  Item: TJSONValue;
begin
  SetLength(Ary, AArray.Count);
  for idx := 0 to Length(Ary) - 1 do
  begin
    Item := AArray.Items[idx];
    Ary[idx] := FromJSON(Item);
  end;
  Result := TValue.From < TArray < TValue >> (Ary);
end;

function TValueHelper.AsArray: TArray<TValue>;
var
  idx: Integer;
begin
  if TryAsType < TArray < TValue >> (Result) then
    Exit;

  SetLength(Result, GetArrayLength);
  for idx := 0 to GetArrayLength - 1 do
  begin
    Result[idx] := GetArrayElement(idx);
  end;
end;

function String2Integer(const Value: TValue; out Converted: TValue): Boolean;
var
  Aux: Integer;
begin
  Result := TryStrToInt(Value.ToString, Aux);
  if Result then
    Converted := Aux;
end;

function String2Float(const Value: TValue; out Converted: TValue): Boolean;
var
  Aux: Extended;
begin
  Result := TryStrToFloat(Value.ToString, Aux);
  if Result then
    Converted := Aux;
end;

function String2Enum(const Value: TValue; ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
var
  Aux: Integer;
begin
  Aux := System.TypInfo.GetEnumValue(ATypeInfo, Value.ToString);
  Result := Aux >= 0;
  if Result then
    Converted := Aux
end;

function StringConvert(const Value: TValue; ATypeInfo: PTypeInfo;  out Converted: TValue): Boolean;
begin
  Converted := TValue.Empty.Cast(ATypeInfo);
  if Converted.IsInteger then
    Result := String2Integer(Value, Converted)
  else if Converted.IsFloat then
    Result := String2Float(Value, Converted)
  else if Converted.IsEnum then
    Result := String2Enum(Value, ATypeInfo, Converted)
  else
    Result := False;
end;

function Ordinal2Enum(const Value: TValue; ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
var
  Aux: Integer;
begin
  Aux := Value.AsOrdinal;
  with GetTypeData(ATypeInfo)^ do
    Result := (MinValue <= Aux) and (MaxValue >= Aux);
  if Result then
    TValue.Make(@Aux, ATypeInfo, Converted);
end;

function OrdinalConvert(const Value: TValue; ATypeInfo: PTypeInfo;  out Converted: TValue): Boolean;
begin
  Converted := TValue.Empty.Cast(ATypeInfo);
  Result := Converted.IsEnum;
  if Result then
    Result := Ordinal2Enum(Value, ATypeInfo, Converted)
end;

function TValueHelper.Convert(ATypeInfo: PTypeInfo;  out Converted: TValue): Boolean;
begin
  Result := TryCast(ATypeInfo, Converted);
  if Result then Exit;
  if Self.IsString then
     Result := StringConvert(Self, ATypeInfo, Converted)
  else if Self.IsOrdinal then
     Result := OrdinalConvert(Self, ATypeInfo, Converted);
end;

function TValueHelper.AsDef<T>(Def: T): T;
var
  Aux: TValue;
begin
  Aux := TValue.From<T>(Def);
  if TryAsType<T>(Result) then
    Exit;

  if Self.IsString then
  begin
    if Aux.IsInteger then
      Aux := StrToIntDef(Self.ToString, Aux.AsInteger)
    else if Aux.IsFloat then
      Aux := StrToFloatDef(Self.ToString, Aux.AsExtended);
  end;
  Result := Aux.AsType<T>;
end;

function EncodeJSONString(Value : String) : String;
var
  i: integer;
begin
  Result := Value;
  i := 1;
  while i < length(Result) do
  begin
    if Result[i] in ['"','\','/',#8,#9,#10,#12,#13] then
    begin
      case Result[i] of
        #8:  Result[i] := 'b';
        #9:  Result[i] := 't';
        #10: Result[i] := 'r';
        #12: Result[i] := 'f';
        #13: Result[i] := 'n';
      end;
      insert('\',Result,i);
      inc(i);
    end;
    inc(i);
  end;
end;

function TValueHelper.AsJSON: TJSONValue;
var
  ObjList: TObject;
begin
  if IsEmpty then
    Result := TJSONNull.Create
  else if IsString then begin
    Result := TJSONString.Create(EncodeJSONString(AsString))
  end
  else if IsBoolean then
  begin
    if AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else if IsInteger then
    Result := TJSONNumber.Create(AsInt64)
  else if IsFloat then
    Result := TJSONNumber.Create(AsExtended)
  else if IsObject then begin
    if (AsObject.IsObjectList) then begin
      ObjList := AsObject;
      Result := TJSON.ToJSONArray(ObjList)
    end
    else
      Result := TJSON.ToJSONObject(AsObject);
  end
  else if IsArray then
    Result := ArrayToJSON(Self)
  else
    Result := TJSONString.Create(ToString)
end;

function TValueHelper.IsString: Boolean;
begin
  Result := Kind in [tkString, tkLString, tkWString, tkUString];
end;

function TValueHelper.IsChar: Boolean;
begin
  Result := Kind in [tkChar, tkWChar];
end;

function TValueHelper.IsTime: Boolean;
begin
  Result := (TypeInfo = System.TypeInfo(TTime));
end;

function TValueHelper.IsDate: Boolean;
begin
  Result := (TypeInfo = System.TypeInfo(TDate));
end;

function TValueHelper.IsDateTime: Boolean;
begin
  Result := (TypeInfo = System.TypeInfo(TDateTime));
end;

function TValueHelper.IsEnum: Boolean;
begin
  Result := Kind in [tkEnumeration];
end;

function TValueHelper.IsNumber: Boolean;
begin
  Result := Kind in [tkInteger, tkFloat, tkInt64];
end;

function TValueHelper.IsInteger: Boolean;
begin
  Result := Kind in [tkInteger, tkInt64];
end;

function TValueHelper.IsFloat: Boolean;
begin
  Result := Kind in [tkFloat];
end;

function TValueHelper.IsBoolean: Boolean;
begin
  Result := (TypeInfo = System.TypeInfo(Boolean));
end;

class function TOSShell.Open(Command: string; Parameters: string = '';
  const Mode: TShowMode = Normal): Integer;
{$IF DEFINED(MSWINDOWS)}
const
  SWMODE: array [TShowMode] of ShortInt = (SW_HIDE, SW_SHOWNORMAL);
{$ENDIF}
begin
{$IF DEFINED(MSWINDOWS)}
  Result := ShellExecute(0, 'OPEN', PChar(Command), PChar(Parameters), '',
    SWMODE[Mode]);
{$ELSEIF DEFINED(MACOS)}
  Result := _system(PAnsiChar('open ' + AnsiString(sCommand + ' ' + Options)));
{$ELSE}
  Result := -1;
{$ENDIF}
end;

{$IF DEFINED(MSWINDOWS)}

class function TOSShell.RunAs(Command: string; Parameters: string;
  const Mode: TShowMode): Cardinal;
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
  if Mode = TShowMode.Hide then
    ShellExecInfo.nShow := SW_HIDE
  else
    ShellExecInfo.nShow := SW_SHOWNORMAL;
  ShellExecuteEx(@ShellExecInfo);
  Result := GetLastError;
end;
{$ELSE}

class function TOSShell.RunAs(Command: string; Parameters: string = '';
  const Mode: TShowMode = Normal): Cardinal;
begin
  Result := 0;
end;
{$ENDIF}
{ TJSON }

class function TJSON.ToJSONArray(const ObjectList): TJSONArray;
var
  List: TObjectList<TObject>;
  Elem: TObject;
begin
  List := TObjectList<TObject>(ObjectList);
  Result := TJSONArray.Create;
  for Elem in List do
    Result.AddElement(TJSON.ToJSONObject(Elem));
end;

class function TJSON.ToJSONObject(const AObject: TObject): TJSONObject;
var
  RC: TRttiContext;
  RTSource: TRttiInstanceType;
  PropSource: TRttiProperty;
  Pair: TJSONPair;
  V: TValue;
begin
  if AObject is TJSONAncestor then
    Exit(AObject as TJSONObject);

  if AObject is TJSONProperties then
    Exit((AObject as TJSONProperties).AsObject.Clone as TJSONObject);

  Result := TJSONObject.Create;
  Result.Owned := False;

  if AObject = nil then
    Exit;
  RTSource := RC.GetType(AObject.ClassType) as TRttiInstanceType;
  for PropSource in RTSource.GetProperties do
  begin
    // PropSource.GetAttributes skip JSONMarshalled(False)
    Pair := TJSONPair.Create;
    Pair.JsonString := TJSONString.Create(PropSource.Name);
    V := PropSource.GetValue(AObject);
    Pair.JsonValue := V.AsJSON;
    Result.AddPair(Pair)
  end;
end;

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

{ TEncrypt }

function TEncrypt.Simple(const Value: TBytes): TBytes;
var
  idx: Integer;
begin
  Result := Value;
  for idx := 1 to Length(Value) do
    Result[idx] := not(Value[idx] + idx);
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
  RC: TRttiContext;
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
      if (RProperties[idx].Visibility in  [mvPublic, mvPublished]) then
        Inc(FoundCount);
    SetLength(FItems, FoundCount);
    FoundCount := 0;
    for idx := 0 to Length(RProperties) - 1 do begin
      if not (RProperties[idx].Visibility in  [mvPublic, mvPublished]) then
        Continue;
      FItems[FoundCount].FIndex := FoundCount;
      FItems[FoundCount].FIsStored := True;
      FItems[FoundCount].FName := RProperties[idx].Name;
      FItems[FoundCount].FRtti := RProperties[idx] as TRttiInstanceProperty;
      Inc(FoundCount);
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
    if SameText(FItems[idx].FName, AName) then Exit(idx);
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
    if StopEnum then Break;
  end;
end;

function TSlice.GetItemOf(Name: string): PItem;
var
  idx: Integer;
begin
  idx := IndexOf(name);
  if idx = -1 then raise Exception.CreateFmt('%s not found', [name]);
  Result := @FItems[idx]
end;

function TSlice.GetNames: TArray<string>;
var
  idx: Integer;
begin
  SetLength(Result, Count);
  for idx := 0 to Count - 1 do Result[idx] := FItems[idx].Name
end;

function TSlice.GetValues: TArray<Variant>;
var
  idx: Integer;
begin
  SetLength(Result, Count);
  for idx := 0 to Count - 1 do Result[idx] := FItems[idx].AsVariant;
end;

function TSlice.Count: Integer;
begin
  Result := System.Length(FItems);
end;

constructor TSlice.Create(const Value: TJSONObject);
var
  idx: Integer;
begin
  SetLength(FItems, Value.Count);
  for idx := 0 to Value.Count - 1 do begin
    FItems[idx].FName := Value.Pairs[idx].JsonString.Value;
    FItems[idx].FValue := TValue.FromJSON(Value.Pairs[idx].JSONValue);
  end;
end;

{ TValuesInjector }

class procedure TValuesInjector.InjectProps(Target: TObject; Source: TObject);
var
  RC: TRttiContext;
  RTSource: TRttiInstanceType;
  RTTarget: TRttiInstanceType;
  PropSource: TRttiProperty;
  PropTarget: TRttiInstanceProperty;
begin
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  RTSource := RC.GetType(Source.ClassType) as TRttiInstanceType;
  PropSource := nil;
  try
    for PropSource in RTSource.GetProperties do begin
      if PropSource.PropertyType.IsInstance then Continue;
      PropTarget := RTTarget.GetProperty(PropSource.Name) as TRttiInstanceProperty;
      if not PropTarget.IsWritable then Continue;
      if Assigned(PropTarget) then PropTarget.SetValue(Target, PropSource.GetValue(Source));
    end;
  except
    raise Exception.CreateFmt('Error on inject %s.%s = %s from %s', [RTTarget.Name, PropSource.Name, PropSource.GetValue(Source).ToString, RTSource.Name]);
  end;
end;

class procedure TValuesInjector.InjectFields(Target: TObject; Source: TDataset);
var
  RC: TRttiContext;
  RTTarget: TRttiInstanceType;
  PropTarget: TRttiInstanceProperty;
  Field: TField;
begin
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  for Field in Source.Fields do begin
    PropTarget := RTTarget.GetProperty(Field.FieldName) as TRttiInstanceProperty;
    if PropTarget = nil then Continue;
    if Field.IsNull then PropTarget.SetValue(Target, TValue.Empty)
    else SetPropValue(Target, PropTarget.PropInfo, Field.AsVariant);
  end;
end;

class procedure TValuesInjector.InjectItems(Target: TObject; Source: TSlice);
var
  RC: TRttiContext;
  RTTarget: TRttiInstanceType;
  PropTarget: TRttiInstanceProperty;
begin
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  Source.ForEach(
    procedure(var Item: TSlice.Titem; var StopEnum: Boolean)
    begin
      PropTarget := RTTarget.GetProperty(Item.Name) as TRttiInstanceProperty;
      if Assigned(PropTarget) then
        SetPropValue(Target, PropTarget.PropInfo, Item.Value.AsVariant);
    end
  );
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
end.
