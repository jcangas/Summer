{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}


unit Summer.RTTI;

interface

uses
  System.TypInfo,
  System.RTTI,
  System.JSON,
  System.SysUtils,
  System.RegularExpressions,
  Data.DB,
  Summer.Utils;

{$SCOPEDENUMS ON}


type
  TTypeInfoHelper = record helper for TTypeInfo
    function IsNullableType: Boolean;
  end;

  TRttiTypeHelper = class helper for TRttiType
  private
  public
    function IsNullableType: Boolean; overload;
    function IsPlainType: Boolean;
    function IsCollectionType: Boolean;
    function IsReferenceType: Boolean;
  end;

  TValueHelper = record helper for TValue
  private
    class function JSONToArray(const AArray: TJSONArray): TValue; static;

  public
    class function FromJSON(Value: TJSONValue): TValue; static;
    function Convert(ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
    function TryGetNullable(out Value: TValue): Boolean;
    procedure SetNullable(const Value: TValue);

    function AsArray: TArray<TValue>;
    function AsJSON: TJSONValue;
    function AsDef<T>(Def: T): T;

    function ArrayToJSON: TJSONArray;

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
    function IsNullable: Boolean;
    function AsDate: TDate;
    function AsTime: TTime;
    function AsDateTime: TDateTime;
  end;

  TValuesInjector = class
  private
  public
    class procedure InjectFields(Target: TObject; Source: TDataset);
    class procedure InjectItems(Target: TObject; Source: TSlice);
    class procedure InjectProps(Target: TObject; Source: TObject);overload;
    class procedure InjectProps(Target: TObject; Source: TObject; Names: array of string);overload;
  end;

  TVoteQuality = (VqRequires, VqPrefers);

  TVote = record
  const
    VETO = Integer.MinValue;

  var
    Value: Integer;
    class operator Implicit(AQuality: TVoteQuality): TVote;
    class operator Implicit(AInteger: Integer): TVote;
    class operator Implicit(AVote: TVote): Integer;
  end;

  TVoteFunc = Reference to function(const Method: TRttiMethod): TVote;
  TMethodKinds = set of TMethodKind;

  TMethodVoter = record helper for TMethod
    class function KindIs(const AMethodKinds: TMethodKinds; Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc; static;
    class function NameIs(const AName: string; Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc; static;
    class function NoArgs(Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc; static;
    class function ArgsMatch(const SomeArgs: TArray<TValue>; Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc; static;
  end;

  TObjectHelper = class helper for TObject
  private
    class function Voting(Method: TRttiMethod; Voters: TArray<TVoteFunc>): TVote;
  public
    class function IsObjList: Boolean;
    class function ObjListItemClass: TClass;
    class function TyrObjListItemClass(out ItemClass: TClass): Boolean; overload;
    class function DefaultCtor: TRttiMethod;
    class function TryInvokeDefaultCtor(out ResultValue: TObject): Boolean;
    class function InvokeDefaultCtor: TObject;
    class function MethodBy(Voters: TArray<TVoteFunc>): TRttiMethod;
    class function ClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
    class function TryClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
    function TryInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
    function Invoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
  end;

  TGroupCollectionHelper = record helper for System.RegularExpressions.TGroupCollection
  public
    function TryItem(Index: Variant): Boolean; overload;
    function TryItem(Index: Variant; out Group: TGroup): Boolean; overload;
  end;

implementation

uses
  System.Variants,
  System.RegularExpressionsCore,
  System.StrUtils,
  Summer.JSON,
  Summer.Nullable;

{ TValueHelper }

class function TValueHelper.FromJSON(Value: TJSONValue): TValue;
begin
  if (Value = nil) or Value.Null then
    Result := TValue.Empty
  else if Value.InheritsFrom(TJSONTrue) then
    Result := True
  else if Value.InheritsFrom(TJSONFalse) then
    Result := False
  else if Value.InheritsFrom(TJSONNumber) then begin
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

function TValueHelper.ArrayToJSON: TJSONArray;
var
  Idx: Integer;
begin
  Result := TJSONArray.Create;
  for Idx := 0 to GetArrayLength - 1 do begin
    Result.AddElement(GetArrayElement(Idx).AsJSON);
  end;
end;

class function TValueHelper.JSONToArray(const AArray: TJSONArray): TValue;
var
  Ary: TArray<TValue>;
  Idx: Integer;
  Item: TJSONValue;
begin
  SetLength(Ary, AArray.Count);
  for Idx := 0 to Length(Ary) - 1 do begin
    Item := AArray.Items[Idx];
    Ary[Idx] := FromJSON(Item);
  end;
  Result := TValue.From < TArray < TValue >> (Ary);
end;

function TValueHelper.AsArray: TArray<TValue>;
var
  Idx: Integer;
begin
  if TryAsType < TArray < TValue >> (Result) then
    Exit;

  SetLength(Result, GetArrayLength);
  for Idx := 0 to GetArrayLength - 1 do begin
    Result[Idx] := GetArrayElement(Idx);
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

function StringConvert(const Value: TValue; ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
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

function OrdinalConvert(const Value: TValue; ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
begin
  Converted := TValue.Empty.Cast(ATypeInfo);
  Result := Converted.IsEnum;
  if Result then
    Result := Ordinal2Enum(Value, ATypeInfo, Converted)
end;

function TValueHelper.Convert(ATypeInfo: PTypeInfo; out Converted: TValue): Boolean;
begin
  Result := TryCast(ATypeInfo, Converted);
  if Result then
    Exit;
  if ATypeInfo.IsNullableType then begin
    Converted := TValue.Empty.Cast(ATypeInfo);
    Converted.SetNullable(Self);
    Result := True;
  end
  else if Self.IsString then
    Result := StringConvert(Self, ATypeInfo, Converted)
  else if Self.IsOrdinal then
    Result := OrdinalConvert(Self, ATypeInfo, Converted);
end;

function TValueHelper.AsDate: TDate;
begin
  Result := AsType<TDate>;
end;

function TValueHelper.AsTime: TTime;
begin
  Result := AsType<TTime>;
end;

function TValueHelper.AsDateTime: TDateTime;
begin
  Result := AsType<TDateTime>;
end;

function TValueHelper.AsDef<T>(Def: T): T;
var
  Aux: TValue;
begin
  if Convert(System.TypeInfo(T), Aux) then
    Result := Aux.AsType<T>
  else
    Result := Def;
end;

function TValueHelper.AsJSON: TJSONValue;
begin
  Result := TJSON.ToJSON(Self);
end;

function TValueHelper.IsString: Boolean;
begin
  Result := Kind in [TkString, TkLString, TkWString, TkUString];
end;

function TValueHelper.IsChar: Boolean;
begin
  Result := Kind in [TkChar, TkWChar];
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
  Result := Kind in [TkEnumeration];
end;

procedure TValueHelper.SetNullable(const Value: TValue);
var
  RContext: TRttiContext;
  RType: TRttiType;
  RField: TRttiField;
  Instance: PNullable;
begin
  if not IsNullable then
    raise Exception.Create('Type is not Nullable');

  Instance := GetReferenceToRawData;

  RType := RContext.GetType(TypeInfo);
  RField := RType.GetField('FValue');
  if not Assigned(RField) then
    raise Exception.Create('FValue field not found in TNullable');
  if Value.IsEmpty then
    Instance.HasValue := False
  else begin
    Instance.HasValue := True;
    RField.SetValue(Instance, Value);
  end;
end;

function TValueHelper.TryGetNullable(out Value: TValue): Boolean;
var
  RContext: TRttiContext;
  RType: TRttiType;
  RField: TRttiField;
  Instance: PNullable;
begin
  Result := IsNullable;
  if not Result then
    Exit;

  Instance := GetReferenceToRawData;
  RType := RContext.GetType(TypeInfo);
  RField := RType.GetField('FValue');
  if not Assigned(RField) then
    raise Exception.Create('FValue field not found in TNullable');

  if Instance.IsNull then
    Value := nil
  else
    Value := RField.GetValue(Instance);
end;

function TValueHelper.IsNullable: Boolean;
begin
  Result := Self.TypeInfo.IsNullableType
end;

function TValueHelper.IsNumber: Boolean;
begin
  Result := Kind in [TkInteger, TkFloat, TkInt64];
end;

function TValueHelper.IsInteger: Boolean;
begin
  Result := Kind in [TkInteger, TkInt64];
end;

function TValueHelper.IsFloat: Boolean;
begin
  Result := Kind in [TkFloat];
end;

function TValueHelper.IsBoolean: Boolean;
begin
  Result := (TypeInfo = System.TypeInfo(Boolean));
end;

{ TValuesInjector }

class procedure TValuesInjector.InjectProps(Target: TObject; Source: TObject);
begin
  InjectProps(Target, Source, []);
end;

class procedure TValuesInjector.InjectProps(Target, Source: TObject;
  Names: array of string);
var
  RC: TRttiContext;
  RTSource: TRttiInstanceType;
  RTTarget: TRttiInstanceType;
  PropSource: TRttiProperty;
  PropTarget: TRttiInstanceProperty;
begin
  if Target = nil then
    Exit;
  if Source = nil then
    Exit;
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  RTSource := RC.GetType(Source.ClassType) as TRttiInstanceType;
  PropSource := nil;
  try
    for PropSource in RTSource.GetProperties do begin
      if PropSource.PropertyType.IsInstance then
        Continue;
      if (Length(Names) > 0) and (IndexText(PropSource.Name, Names) = -1) then Continue;
      PropTarget := RTTarget.GetProperty(PropSource.Name) as TRttiInstanceProperty;
      if Assigned(PropTarget) and PropTarget.IsWritable then
        PropTarget.SetValue(Target, PropSource.GetValue(Source));
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
  if Target = nil then
    Exit;
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  for Field in Source.Fields do begin
    PropTarget := RTTarget.GetProperty(Field.FieldName) as TRttiInstanceProperty;
    if PropTarget = nil then
      Continue;
    if Field.IsNull then
      PropTarget.SetValue(Target, TValue.Empty)
    else
      SetPropValue(Target, PropTarget.PropInfo, Field.AsVariant);
  end;
end;

class procedure TValuesInjector.InjectItems(Target: TObject; Source: TSlice);
var
  RC: TRttiContext;
  RTTarget: TRttiInstanceType;
  PropTarget: TRttiInstanceProperty;
begin
  if Target = nil then
    Exit;
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  Source.ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      PropTarget := RTTarget.GetProperty(Item.Name) as TRttiInstanceProperty;
      if Assigned(PropTarget) then
        SetPropValue(Target, PropTarget.PropInfo, Item.Value.AsVariant);
    end);
end;

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
  if (AQuality = TVoteQuality.VqRequires) then
    Result := VETO
  else
    Result := 0;
end;

{ TMethodVoter }

class function TMethodVoter.KindIs(const AMethodKinds: TMethodKinds; Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc;
begin
  Result := function(const Method: TRttiMethod): TVote
    begin
      Result := Quality;
      if not(Method.MethodKind in AMethodKinds) then
        Exit;
      Result := 1;
    end;
end;

class function TMethodVoter.NameIs(const AName: string; Quality: TVoteQuality): TVoteFunc;
begin
  Result := function(const Method: TRttiMethod): TVote
    begin
      Result := Quality;
      if not SameText(AName, Method.Name) then
        Exit;
      Result := 1;
    end;
end;

class function TMethodVoter.NoArgs(Quality: TVoteQuality): TVoteFunc;
begin
  Result := ArgsMatch([], Quality);
end;

class function TMethodVoter.ArgsMatch(const SomeArgs: TArray<TValue>; Quality: TVoteQuality = TVoteQuality.VqRequires): TVoteFunc;
var
  CopyArgs: TArray<TValue>;
begin
  CopyArgs := SomeArgs;
  Result := function(const Method: TRttiMethod): TVote
    var
      Parms: TArray<TRttiParameter>;
      Idx: Integer;
    begin
      Result := Quality;
      Parms := Method.GetParameters;
      if (Length(Parms) <> Length(CopyArgs)) then
        Exit;
      for Idx := 0 to high(CopyArgs) do
        if CopyArgs[Idx].TypeInfo <> Parms[Idx].ParamType.Handle then
          Exit;
      Result := 1;
    end;
end;

{ TInvokeHelper }

class function TObjectHelper.IsObjList: Boolean;
var
  ItemType: TClass;
begin
  Result := TyrObjListItemClass(ItemType);
end;

class function TObjectHelper.TyrObjListItemClass(out ItemClass: TClass): Boolean;
const
  ObjectListTag = 'System.Generics.Collections.TObjectList';

var
  ItemTypeName: string;
  RContext: TRttiContext;
  QClassName: string;
begin
  Result := False;
  ItemClass := nil;

  if (Self = nil) or (Self = TObject) then
    Exit;

  QClassName := QualifiedClassName;
  Result := True;
  if QClassName.StartsWith(ObjectListTag) then begin
    ItemTypeName := QClassName.Substring(Length(ObjectListTag));
    ItemTypeName := ItemTypeName.Substring(1, Length(ItemTypeName) - 2);
    ItemClass := (RContext.FindType(ItemTypeName) as TRttiInstanceType).MetaclassType;
  end
  else
    Result := ClassParent.TyrObjListItemClass(ItemClass);
end;

class function TObjectHelper.ObjListItemClass: TClass;
begin
  if not TyrObjListItemClass(Result) then
    Exit(nil);
end;

class function TObjectHelper.Voting(Method: TRttiMethod; Voters: TArray<TVoteFunc>): TVote;
var
  Vote: Integer;
  Voter: TVoteFunc;
begin
  Result := 0;
  for Voter in Voters do begin
    Vote := Voter(Method);
    if Vote = TVote.VETO then
      Exit(TVote.VETO);
    Result := Result.Value + Vote;
  end;
end;

class function TObjectHelper.ClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
begin
  if not TryClassInvoke(Args, Voters, Result) then
    raise Exception.Create('Method for Invoke not found');
end;

class function TObjectHelper.TryClassInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
var
  Method: TRttiMethod;
begin
  Result := False;
  SetLength(Voters, 2 + Length(Voters));
  Voters[Length(Voters) - 2] := TMethod.KindIs([MkClassProcedure, MkClassFunction, MkClassConstructor, MkClassDestructor]);
  Voters[Length(Voters) - 1] := TMethod.ArgsMatch(Args);
  Method := MethodBy(Voters);
  if Method = nil then
    Exit;
  ResultValue := Method.Invoke(Self, Args);
  Result := True;
end;

class function TObjectHelper.DefaultCtor: TRttiMethod;
begin
  Result := MethodBy([TMethod.KindIs([MkConstructor]), TMethod.NoArgs, TMethod.NameIs('Create', TVoteQuality.VqPrefers)]);
end;

class function TObjectHelper.TryInvokeDefaultCtor(out ResultValue: TObject): Boolean;
var
  Method: TRttiMethod;
begin
  Result := False;
  Method := DefaultCtor;
  if Method = nil then
    Exit;
  ResultValue := Method.Invoke(Self, []).AsObject;
  Result := True;
end;

function TObjectHelper.Invoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>): TValue;
begin
  if not TryInvoke(Args, Voters, Result) then
    raise Exception.Create('Method for Invoke not found');
end;

class function TObjectHelper.InvokeDefaultCtor: TObject;
begin
  if not TryInvokeDefaultCtor(Result) then
    raise Exception.Create('No default constructor found');
end;

function TObjectHelper.TryInvoke(Args: TArray<TValue>; Voters: TArray<TVoteFunc>; out ResultValue: TValue): Boolean;
var
  Method: TRttiMethod;
begin
  Result := False;
  if Self = nil then
    Exit;
  SetLength(Voters, 1 + Length(Voters));
  Voters[Length(Voters) - 1] := TMethod.ArgsMatch(Args);
  Method := Self.ClassType.MethodBy(Voters);
  if Method = nil then
    Exit;
  ResultValue := Method.Invoke(Self, Args);
  Result := True;
end;

class function TObjectHelper.MethodBy(Voters: TArray<TVoteFunc>): TRttiMethod;
var
  RC: TRttiContext;
  RType: TRttiInstanceType;
  Method: TRttiMethod;
  Points: Integer;
  BestPoints: Integer;

begin
  Result := nil;
  if Self = nil then
    Exit;
  BestPoints := Integer.MinValue;
  RType := RC.GetType(Self) as TRttiInstanceType;
  for Method in RType.GetMethods do begin
    Points := Voting(Method, Voters);
    if Points > BestPoints then begin
      Result := Method;
      BestPoints := Points;
    end;
  end;
end;

{ TTypeInfoHelper }

function TTypeInfoHelper.IsNullableType: Boolean;
begin
  Result := GetTypeName(@Self).Contains('TNullable');
end;

{ TRttiTypeHelper }

function TRttiTypeHelper.IsNullableType: Boolean;
begin
  Result := Self.Handle.IsNullableType;
end;

function TRttiTypeHelper.IsPlainType: Boolean;
begin
  Result := not(Self is TRttiStructuredType) or IsNullableType;
end;

function TRttiTypeHelper.IsReferenceType: Boolean;
begin
  Result := not IsPlainType and not IsCollectionType;
end;

function TRttiTypeHelper.IsCollectionType: Boolean;
var
  Klass: TClass;
begin
  if not IsInstance then
    Exit(False);
  Klass := AsInstance.MetaclassType;
  Result := Klass.IsObjList;
end;

{ TGroupCollectionHelper }
// Helper to extract RegEx object
type
  TScopeExitNotifierCraked = class(TInterfacedObject)
  private
    FRegEx: TPerlRegEx;
  end;

function GetRegEx(Notifier: IInterface): TPerlRegEx; inline;
begin
  Result := TScopeExitNotifierCraked(TObject(Notifier)).FRegEx;
end;

function TGroupCollectionHelper.TryItem(Index: Variant): Boolean;
var
  Dummy: TGroup;
begin
  Result := TryItem(index, Dummy);
end;

function TGroupCollectionHelper.TryItem(Index: Variant; out Group: TGroup): Boolean;
type
  TGroupCollectionCraked = record
  public
    FList: TArray<TGroup>;
    FNotifier: IInterface;
  end;

var
  LIndex: Integer;

begin
  Result := False;
  with TGroupCollectionCraked(Self) do begin
    case VarType(index) of
      VarString, VarUString, VarOleStr:
        LIndex := GetRegEx(FNotifier).NamedGroup(string(index));
      VarByte, VarSmallint, VarInteger, VarShortInt, VarWord, VarLongWord:
        LIndex := index;
    else
      Exit;
    end;

    if (LIndex >= 0) and (LIndex < Length(FList)) then begin
      Group := FList[LIndex];
      Result := Group.Length > 0;
    end;
  end;
end;

end.
