unit SummerFW.DDD.Utils;

interface

uses
  Generics.Collections,
  System.Rtti,
  Data.DB;

type
  TSlice = record
  public type
    TItem = record
    private
      FIndex: Integer;
      FName: string;
      FValue: Variant;
      FRtti: TRttiInstanceProperty;
      FIsStored: Boolean;
      function GetIsProperty: Boolean;
    public
      property
        index: Integer
        read FIndex;
      property name: string
        read FName;
      property Value: Variant
        read FValue;
      property IsStored: Boolean
        read FIsStored;
      property Rtti: TRttiInstanceProperty
        read FRtti;
      property IsProperty: Boolean
        read GetIsProperty;
    end;

    TEnumProc = reference to procedure(var Item: TItem; var StopEnum: Boolean);
  strict private
    FForClass: TClass;
    FItems: TArray<TItem>;
    function GetItemOf(Name: string): TItem;
    procedure SetForClass(const Value: TClass);
  public
    constructor From(const ANames: array of string; const AClass: TClass = nil); overload;
    constructor From(const ANames: array of string; const Instance: TObject); overload;
    constructor From(const Instance: TObject); overload;
    function Count: Integer;
    function IndexOf(const AName: string): Integer;
    function Contains(const AName: string): Boolean;
    function GetNames: TArray<string>;
    function GetValues: TArray<Variant>;
    procedure Read(Instance: TObject);
    procedure ForEach(Proc: TEnumProc);
    property ForClass: TClass
      read FForClass
      write SetForClass;
    property Items: TArray<TItem>
      read FItems;
    property ItemOf[index: string]: TItem
      read GetItemOf;
      default;
  end;

type
  TPropsInjector = class
  private
  public
    class procedure InjectFields(Target: TObject; Data: TDataset);
    class procedure InjectProps(Target: TObject; Source: TObject);
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo;

{ TSlice.TItem }

function TSlice.TItem.GetIsProperty: Boolean;
begin
  Result := Assigned(FRtti);
end;

{ TSlice }

constructor TSlice.From(const Instance: TObject);
begin
  From([], Instance);
end;

constructor TSlice.From(const ANames: array of string; const AClass: TClass = nil);
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

constructor TSlice.From(const ANames: array of string; const Instance: TObject);
begin
  Assert(Instance <> nil);
  From(ANames, Instance.ClassType);
  Read(Instance);
end;

procedure TSlice.Read(Instance: TObject);
var
  RC: TRttiContext;
  RInstance: TRttiInstanceType;
  RProp: TRttiInstanceProperty;
begin
  if Instance = nil then Exit;
  if Count = 0 then ForClass := Instance.ClassType;

  RInstance := RC.GetType(ForClass) as TRttiInstanceType;
  ForEach(
    procedure(var Item: TItem; var StopEnum: Boolean)
    begin
      RProp := RInstance.GetProperty(Item.Name) as TRttiInstanceProperty;
      if RProp = nil then Exit;
      Item.FValue := RProp.GetValue(Instance).AsVariant;
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
  if FForClass = nil then Exit;

  RInstance := RC.GetType(FForClass) as TRttiInstanceType;
  HasItems := (Count > 0);
  FoundCount := 0;
  if not HasItems then begin
    RProperties := RInstance.GetProperties;
    for idx := 0 to Length(RProperties) - 1 do
      if IsPublishedProp(ForClass, RProperties[idx].Name) then Inc(FoundCount);
    Setlength(FItems, FoundCount);
    FoundCount := 0;
    for idx := 0 to Length(RProperties) - 1 do begin
      if not IsPublishedProp(ForClass, RProperties[idx].Name) then Continue;
      FItems[FoundCount].FIndex := FoundCount;
      FItems[FoundCount].FIsStored := True;
      FItems[FoundCount].FName := RProperties[idx].Name;
      FItems[FoundCount].FRtti := RProperties[idx] as TRttiInstanceProperty;
      Inc(FoundCount);
    end;
  end;

  ForEach(procedure(var Item: TItem; var StopEnum: Boolean) begin
    Item.FRtti := RInstance.GetProperty(Item.Name) as TRttiInstanceProperty;
  end);

end;

function TSlice.Contains(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > -1;
end;

function TSlice.IndexOf(const AName: string): Integer;
var
  idx: Integer;
begin
  for idx := 0 to Count - 1 do
    if FItems[idx].FName = AName then
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

function TSlice.GetItemOf(Name: string): TItem;
var
  idx: Integer;
begin
  idx := IndexOf(name);
  if idx = -1 then
    raise Exception.CreateFmt('%s not found', [name]);
  Result := FItems[idx]
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
    Result[idx] := FItems[idx].Value
end;

function TSlice.Count: Integer;
begin
  Result := System.Length(FItems);
end;

{ TPropsInjector }

class procedure TPropsInjector.InjectProps(Target: TObject; Source: TObject);
var
  RC: TRttiContext;
  RTSource: TRttiInstanceType;
  RTTarget: TRttiInstanceType;
  PropSource: TRttiProperty;
  PropTarget: TRttiInstanceProperty;
begin
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  RTSource := RC.GetType(Source.ClassType) as TRttiInstanceType;
  for PropSource in RTSource.GetProperties do begin
    if PropSource.PropertyType.IsInstance then
      Continue;
    PropTarget := RTTarget.GetProperty(PropSource.Name) as TRttiInstanceProperty;
    if Assigned(PropTarget) then
      PropTarget.SetValue(Target, PropSource.GetValue(Source));
  end;
end;

class procedure TPropsInjector.InjectFields(Target: TObject; Data: TDataset);
var
  RC: TRttiContext;
  RTTarget: TRttiInstanceType;
  PropTarget: TRttiInstanceProperty;
  Field: TField;
begin
  RTTarget := RC.GetType(Target.ClassType) as TRttiInstanceType;
  for Field in Data.Fields do begin
    PropTarget := RTTarget.GetProperty(Field.FieldName) as TRttiInstanceProperty;
    if Field.IsNull then
      PropTarget.SetValue(Target, TValue.Empty)
    else
      SetPropValue(Target, PropTarget.PropInfo, Field.AsVariant);
  end;
end;

end.
