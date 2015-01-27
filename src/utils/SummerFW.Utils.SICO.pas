
// A Simple Injection Container

unit SummerFW.Utils.SICO;

interface

uses
  System.Classes,
  System.TypInfo,
  System.RTTI,
  System.SysUtils,
  Generics.Collections;

type
  TDIContainer = class;
  TDIRule = class(TObject)
  private
    class var FRTTIContext: TRTTIContext;
  strict private
    FContainer: TDIContainer;
    FImplementorType: PTypeInfo;
    FServiceType: PTypeInfo;
    FName: string;
    FOnCreate: TFunc<TObject>;
  private
    class function GetRTTI(Info: PTypeInfo): TRTTIType;
    constructor Create(Container: TDIContainer; ImplementorType: PTypeInfo);
    function ForServiceType(const AType: PTypeInfo; const Name: string = ''): TDIRule;
    function Build: TValue;
    function DefaultOnCreate: TObject;
  public
    destructor Destroy; override;
    function Factory(Builder: TFunc<TObject>): TDIRule;
    property Name: string read FName;
    property ImplementorType: PTypeInfo read FImplementorType;
    property ServiceType: PTypeInfo read FServiceType;
  end;

  TDIRuleList = class(TStringList)
  private
    FServiceType: PTypeInfo;
    function GetRule(const Name: string): TDIRule;
  public
    constructor Create(ServiceType: PTypeInfo);
    destructor Destroy; override;
    function FindRule(const Name: string): TDIRule;
    function ContainsRule(Rule: TDIRule): Boolean;
    procedure RemoveRule(Rule: TDIRule);
    procedure AddRule(Rule: TDIRule);
    property ServiceType: PTypeInfo read FServiceType;
    property Rules[const Name: string]: TDIRule read GetRule; default;
  end;

  TDIRule<T: class> = class(TDIRule)
  private
    constructor Create(Container: TDIContainer);
  public
    // Fluent api
    function ForService<TService>(const Name: string = ''): TDIRule<T>;
    function Factory(Builder: TFunc<T>): TDIRule<T>;
  end;

  TDIRules = TObjectDictionary<PTypeInfo, TDIRuleList>;

  TDIContainer = class
  private class var
    FDIContainer: TDIContainer;
  strict private
    FDIRules: TDIRules;
    function GetRules(ServiceType: PTypeInfo): TDIRuleList;
  protected
    function FindRule(ServiceType: PTypeInfo; Name: string = ''): TDIRule;
    function ContainsRule(Rule: TDIRule): Boolean;
    procedure AddRule(Rule: TDIRule);
    procedure RemoveRule(Rule: TDIRule);
    procedure BeforeUpdate(Rule: TDIRule);
    procedure AfterUpdate(Rule: TDIRule);
    property Rules[ServiceType: PTypeInfo]: TDIRuleList read GetRules; default;
  public
    constructor Create;
    destructor Destroy; override;
    function Returns<T: class>: TDIRule<T>;
    function GetService<TService>(Name: string = ''): TService;
  end;

function SICO: TDIContainer;inline;

implementation

function SICO: TDIContainer;
begin
  Result := TDIContainer.FDIContainer;
end;

{ TDIRule }

function TDIRule.Build: TValue;
var
  Instance: TObject;
begin
  Instance := FOnCreate;
  TValue.Make(@Instance, FImplementorType, Result);
end;

constructor TDIRule.Create(Container: TDIContainer; ImplementorType: PTypeInfo);
begin
  inherited Create;
  FContainer := Container;
  FImplementorType := ImplementorType;
  FOnCreate := DefaultOnCreate;
end;

function TDIRule.DefaultOnCreate: TObject;
var
  Method: TRTTIMethod;
  DefaultCtor: TRTTIMethod;
  Klass: TClass;
  RType: TRttiInstanceType;
begin
  DefaultCtor := nil;
  RType := GetRTTI(ImplementorType) as TRttiInstanceType;
  for Method in RType.GetMethods do begin
    if not Method.IsConstructor then Continue;
    if Length(Method.GetParameters) > 0 then Continue;
    // Prefer first ctor and prefer the first named Create
    if not Assigned(DefaultCtor) then DefaultCtor := Method;
    if SameText(Method.Name, 'Create') then begin
      DefaultCtor := Method;
      Break;
    end;
  end;
  if not Assigned(DefaultCtor) then
      raise Exception.CreateFmt('No default Constructor found for type %s', [RType.QualifiedName]);
  Klass := RType.MetaclassType;
  Result := DefaultCtor.Invoke(Klass, []).AsObject;
end;

destructor TDIRule.Destroy;
begin
  // workaround for compiler bug: FBuilder is not released !
  TFunc<TObject>(FOnCreate) := nil;

  inherited;
end;

function TDIRule.ForServiceType(const AType: PTypeInfo; const Name: string): TDIRule;
begin
  FContainer.BeforeUpdate(Self);
  Result := Self;
  Result.FServiceType := AType;
  Result.FName := name;
  FContainer.AfterUpdate(Self);
end;

function TDIRule.Factory(Builder: TFunc<TObject>): TDIRule;
begin
  Result := Self;
  FOnCreate := Builder;
end;

class function TDIRule.GetRTTI(Info: PTypeInfo): TRTTIType;
begin
  Result := FRTTIContext.GetType(Info);
end;

{ TDIRule<T> }

constructor TDIRule<T>.Create(Container: TDIContainer);
begin
  inherited Create(Container, TypeInfo(T));
end;

function TDIRule<T>.ForService<TService>(const Name: string = ''): TDIRule<T>;
begin
  Result := ForServiceType(TypeInfo(TService), name) as TDIRule<T>;
end;

function TDIRule<T>.Factory(Builder: TFunc<T>): TDIRule<T>;
begin
  Result := Self;
  inherited Factory(TFunc<TObject>(Builder));
end;

{ TDIContainer }

constructor TDIContainer.Create;
begin
  inherited Create;
  FDIRules := TDIRules.Create([doOwnsValues]);
end;

destructor TDIContainer.Destroy;
begin
  FDIRules.Free;
  inherited;
end;

function TDIContainer.GetService<TService>(Name: string = ''): TService;
var
  Instance: TValue;
  Rule: TDIRule;
  RService: TRTTIType;
begin
  RService := TDIRule.GetRTTI(TypeInfo(TService));
  Rule := FindRule(RService.Handle, name);
  Instance := Rule.Build;
  if (RService is TRttiInterfaceType) and (Instance.IsType<TVirtualInterface>) then
      Supports(Instance.AsObject, TRttiInterfaceType(RService).GUID, Result)
  else Result := Instance.AsType<TService>;
end;

function TDIContainer.GetRules(ServiceType: PTypeInfo): TDIRuleList;
begin
  if FDIRules.TryGetValue(ServiceType, Result) then Exit;
  Result := TDIRuleList.Create(ServiceType);
  FDIRules.Add(ServiceType, Result);
end;

function TDIContainer.FindRule(ServiceType: PTypeInfo; Name: string = ''): TDIRule;
begin
  Result := Self[ServiceType][name];
end;

procedure TDIContainer.AddRule(Rule: TDIRule);
begin
  Self[Rule.ServiceType].AddRule(Rule);
end;

function TDIContainer.ContainsRule(Rule: TDIRule): Boolean;
begin
  Result := Self[Rule.ServiceType].ContainsRule(Rule);
end;

procedure TDIContainer.RemoveRule(Rule: TDIRule);
begin
  Self[Rule.ServiceType].RemoveRule(Rule);
end;

function TDIContainer.Returns<T>: TDIRule<T>;
begin
  Result := TDIRule<T>.Create(Self);
  Result.ForServiceType(TypeInfo(T));
end;

procedure TDIContainer.BeforeUpdate(Rule: TDIRule);
begin
  if ContainsRule(Rule) then RemoveRule(Rule);
end;

procedure TDIContainer.AfterUpdate(Rule: TDIRule);
begin
  AddRule(Rule);
end;

{ TDIRuleList }

constructor TDIRuleList.Create(ServiceType: PTypeInfo);
begin
  inherited Create;
  FServiceType := ServiceType;
  Duplicates := dupError;
  Sorted := True;
end;

destructor TDIRuleList.Destroy;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do Objects[I].DisposeOf;
  inherited;
end;

procedure TDIRuleList.AddRule(Rule: TDIRule);
begin
  AddObject(Rule.Name, Rule)
end;

procedure TDIRuleList.RemoveRule(Rule: TDIRule);
var
  Pos: Integer;
begin
  if not Find(Rule.Name, Pos) then Exit;
  Delete(Pos);
end;

function TDIRuleList.ContainsRule(Rule: TDIRule): Boolean;
begin
  Result := FindRule(Rule.Name) <> nil;
end;

function TDIRuleList.GetRule(const Name: string): TDIRule;
begin
  Result := FindRule(name);
  if not Assigned(Result) then
      raise Exception.CreateFmt('Dependency Injection Rule for %s<%s> not found', [name, ServiceType.Name]);
end;

function TDIRuleList.FindRule(const Name: string): TDIRule;
var
  Pos: Integer;
begin
  if not Find(name, Pos) then Exit(nil);
  Result := Objects[Pos] as TDIRule;
end;

initialization
  TDIContainer.FDIContainer := TDIContainer.Create;

finalization;
  TDIContainer.FDIContainer.Free;
end.
