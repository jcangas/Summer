unit Summer.Config;

interface
uses System.JSON,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Rtti,
  Summer.IConfig;

type
  TJSONProperties = class(TInterfacedObject)
  strict private
    FFileName: string;
    FJSONObject: TJSONObject;
    FOwnValues: Boolean;
    FDefaults: IConfiguration;
  private
  protected
    function GetCount: Integer;
    function GetPair(const Index: Integer): TJSONPair;
    function GetValue(const Name: string): TValue;
    function GetChild(const Name: string): IConfiguration;
    procedure SetValue(const Name: string; const Value: TValue);
    function GetFileName: string;
    function GetDefaults: IConfiguration;
    procedure SetDefaults(Value: IConfiguration);
    constructor Create(Values: TJSONObject; const OwnValues: Boolean);overload;
  public
    constructor Create;overload;
    destructor Destroy;override;
    procedure LoadFromFile(const AFileName:string='');
    procedure SaveToFile(const AFileName:string='');
    function GetEnumerator: TJSONPairEnumerator;
    function AddPair(const Str: string; const Val: TJSONValue): TJSONObject;
    function RemovePair(const PairName: string): TJSONPair;
    function Clone: IConfiguration;
    function ToString: string; override;
    function GetAsJSON: string;
    procedure SetAsJSON(const Value: string);
    function GetAsObject: TJSONObject;
    procedure SetAsObject(const Value: TJSONObject);
    procedure Clear;
    property AsJSON: string read GetAsJSON write SetAsJSON;
    property AsObject: TJSONObject read GetAsObject write SetAsObject;
    property FileName: string read GetFileName;
    property Count: Integer read GetCount;
    property Pairs[const Index: Integer]: TJSONPair read GetPair;
    property Values[const Name: string]: TValue read GetValue write SetValue;default;
    property Childs[const Name: string]: IConfiguration read GetChild;
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
  end;

  TConfiguration = class(TJSONProperties, IConfiguration);

implementation
uses
  Summer.Utils;

constructor TJSONProperties.Create(Values: TJSONObject; const OwnValues: Boolean);
begin
  inherited Create;
  FJSONObject := Values;
  FOwnValues := OwnValues;
  if FJSONObject = nil then begin
    FJSONObject := TJSONObject.Create;
    FOwnValues := True;
  end;
end;

constructor TJSONProperties.Create;
begin
  Create(nil, True);
end;

destructor TJSONProperties.Destroy;
begin
  if FOwnValues then
    FJSONObject.Free;
  inherited;
end;

procedure TJSONProperties.SetDefaults(Value: IConfiguration);
begin
  FDefaults := Value.Clone;
end;

procedure TJSONProperties.Clear;
var
  Pair: TJSONPair;
begin
  //  SetPairs perfroms a Free of list members
  // but don't honors Pair.GetOwned
  for Pair in Self do begin
    if Pair.GetOwned then
        Pair.DisposeOf;
  end;
  FJSONObject.SetPairs(nil);
  FJSONObject.Create;
end;

function TJSONProperties.Clone: IConfiguration;
begin
  Result := TConfiguration.Create(FJSONObject.Clone as TJSONObject, True);
end;

function TJSONProperties.GetCount: Integer;
begin
  Result := FJSONObject.Count;
end;

function TJSONProperties.GetEnumerator: TJSONPairEnumerator;
begin
  Result := FJSONObject.GetEnumerator;
end;

function TJSONProperties.GetFileName: string;
begin
  Result := FFileName;
end;

function TJSONProperties.GetPair(const Index: Integer): TJSONPair;
begin
  Result := FJSONObject.Pairs[Index];
end;

function TJSONProperties.GetChild(const Name: string): IConfiguration;
var
  JSONValue: TJSONObject;
begin
  if FJSONObject.TryGetValue<TJSONObject>(Name, JSONValue) then
    Result := TConfiguration.Create(JSONValue, False)
  else if Assigned(FDefaults) then
    Result := FDefaults.Childs[Name]
  else
    Result := nil;
end;

function TJSONProperties.GetValue(const Name: string): TValue;
var
  JSONValue: TJSONValue;
begin
  if FJSONObject.TryGetValue<TJSONValue>(Name, JSONValue) then
    Result := TValue.FromJSON(JSONValue)
  else if Assigned(FDefaults) then
    Result := FDefaults.Values[Name]
  else
    Result := nil;
end;

function DeepChild(Obj: TJSONObject; var Path: TArray<string>): TJSONObject;
var
  Child: TJSONObject;
  Len: Integer;
begin
  Child := nil;
  Len := Length(Path);
  if Len > 1 then begin
    if not Obj.TryGetValue<TJSONObject>(Path[0], Child) then begin
      Child := TJSONObject.Create;
      Obj.RemovePair(Path[0]);
      Obj.AddPair(Path[0], Child);
    end;
    Path := Copy(Path, 1, Len);
    Result := DeepChild(Child, Path);
  end else
    Result := Obj;
end;

procedure TJSONProperties.SetValue(const Name: string; const Value: TValue);
var
  KeyPath: TArray<string>;
  Target: TJSONObject;
begin
  KeyPath := Name.Split(['.']);
  Target := DeepChild(FJSONObject, KeyPath);
  Target.RemovePair(KeyPath[0]);
  Target.AddPair(KeyPath[0], Value.AsJSON);
end;

procedure TJSONProperties.LoadFromFile(const AFileName:string);
begin
  if not AFileName.IsEmpty then
    FFileName := AFileName;
  if not TFile.Exists(FileName)then Exit;
  AsJSON := TFile.ReadAllText(FileName, TEncoding.UTF8);
end;

procedure TJSONProperties.SaveToFile(const AFileName:string='');
begin
  if not AFileName.IsEmpty then
    FFileName := AFileName;

  TFile.WriteAllText(FileName, GetAsJSON, TEncoding.UTF8);
end;

function TJSONProperties.GetDefaults: IConfiguration;
begin
  if FDefaults = nil then
    FDefaults := TConfiguration.Create;
  Result := FDefaults;
end;

function TJSONProperties.GetAsJSON: string;
begin
  Result := FJSONObject.ToJSON
end;

procedure TJSONProperties.SetAsJSON(const Value: string);
var
  NewJsonObject: TJSOnObject;
begin
  NewJsonObject := TJSONObject.ParseJSONValue(Value) as TJSONObject;
  AsObject := NewJsonObject;
  NewJsonObject.Free;
end;

procedure TJSONProperties.SetAsObject(const Value: TJSONObject);
var
  Pair: TJSONPair;
  NewPair: TJSONPair;
begin
  Clear;
  for Pair in Value do begin
    NewPair := Pair.Clone as TJSONPair;
    NewPair.Owned := Pair.GetOwned;
    FJSONObject.AddPair(NewPair);
  end;
end;

function TJSONProperties.GetAsObject: TJSONObject;
begin
  Result := FJSONObject;
end;

function TJSONProperties.ToString: string;
begin
  Result := GetAsJSON;
end;


function TJSONProperties.AddPair(const Str: string;
  const Val: TJSONValue): TJSONObject;
begin
  Result := FJSONObject.AddPair(Str, Val);
end;

function TJSONProperties.RemovePair(const PairName: string): TJSONPair;
begin
  Result := FJSONObject.RemovePair(PairName)
end;

end.
