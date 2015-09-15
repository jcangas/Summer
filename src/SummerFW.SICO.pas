// A Simple Injection Container

unit SummerFW.SICO;

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
    FIsSingleton: Boolean;
    FOnCreate: TFunc<TObject>;
    FSingleton: TObject;
  private
    class function GetRTTI(Info: PTypeInfo): TRTTIType;
    constructor Create(Container: TDIContainer; ImplementorType: PTypeInfo);
    function ForServiceType(const AType: PTypeInfo;
      const Name: string = ''): TDIRule;
    function Build: TValue;
    function DefaultOnCreate: TObject;
    property Name: string read FName;
    property ImplementorType: PTypeInfo read FImplementorType;
    property ServiceType: PTypeInfo read FServiceType;
    property IsSingleton: Boolean read FIsSingleton write FIsSingleton;
  public
    destructor Destroy; override;
    function Factory(Builder: TFunc<TObject>): TDIRule;
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
    function AsSingleton: TDIRule<T>;
  end;

  TDIRules = TObjectDictionary<PTypeInfo, TDIRuleList>;

  TDIContainer = class
  private
    class var FDIContainer: TDIContainer;
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

function SICO: TDIContainer; inline;

implementation
uses SummerFW.Utils;

function SICO: TDIContainer;
begin
  Result := TDIContainer.FDIContainer;
end;

{ TDIRule }

function TDIRule.Build: TValue;
var
  Instance: TObject;
  Intf: IInterface;
begin
  if IsSingleton and Assigned(FSingleton) then
    Instance := FSingleton
  else
  begin
    Instance := FOnCreate;
    if IsSingleton then
    begin
      FSingleton := Instance;
      if Supports(Instance, IInterface, Intf) then
        Intf._AddRef;
    end;
  end;
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
  AClass: TClass;
begin
  AClass := (GetRTTI(ImplementorType) as TRttiInstanceType).MetaclassType;
  Result := AClass.InvokeDefaultCtor;
end;

destructor TDIRule.Destroy;
var
  Intf: IInterface;
begin
  // workaround for compiler bug: FBuilder is not released !
  TFunc<TObject>(FOnCreate) := nil;
  if IsSingleton then
  begin
    if Supports(FSingleton, IInterface, Intf) then
      Intf._Release
    else
      FSingleton.Free;
  end;
  inherited;
end;

function TDIRule.ForServiceType(const AType: PTypeInfo;
  const Name: string): TDIRule;
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

function TDIRule<T>.AsSingleton: TDIRule<T>;
begin
  Result := Self;
  Result.IsSingleton := True;
end;

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

function TDIContainer.Returns<T>: TDIRule<T>;
begin
  TMonitor.Enter(Self);
  try
    Result := TDIRule<T>.Create(Self);
    Result.ForServiceType(TypeInfo(T));
  finally
    TMonitor.Exit(Self);
  end;
end;

function TDIContainer.GetService<TService>(Name: string = ''): TService;
var
  Instance: TValue;
  Rule: TDIRule;
  RService: TRTTIType;
begin
  TMonitor.Enter(Self);
  try
    RService := TDIRule.GetRTTI(TypeInfo(TService));
    Rule := FindRule(RService.Handle, Name);
    Instance := Rule.Build;
    // No usar TValue.IsType !!!
   // if (RService is TRttiInterfaceType) and (Instance.IsType<TVirtualInterface>)
   // Si se usa IsType en combinación con RT pacakges, se produce un AV si se ejecuta
   // desde el IDE en modo Debug !!!!!
    if (RService is TRttiInterfaceType) and (Instance.AsObject is TVirtualInterface)
    then
      Supports(Instance.AsObject, TRttiInterfaceType(RService).GUID, Result)
    else
      Result := Instance.AsType<TService>;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TDIContainer.GetRules(ServiceType: PTypeInfo): TDIRuleList;
begin
  if FDIRules.TryGetValue(ServiceType, Result) then
    Exit;
  Result := TDIRuleList.Create(ServiceType);
  FDIRules.Add(ServiceType, Result);
end;

function TDIContainer.FindRule(ServiceType: PTypeInfo;
  Name: string = ''): TDIRule;
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

procedure TDIContainer.BeforeUpdate(Rule: TDIRule);
begin
  if ContainsRule(Rule) then
    RemoveRule(Rule);
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
  for I := 0 to Count - 1 do
    Objects[I].DisposeOf;
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
  if not Find(Rule.Name, Pos) then
    Exit;
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
    raise Exception.CreateFmt('Dependency Injection Rule for %s<%s> not found',
      [name, ServiceType.Name]);
end;

function TDIRuleList.FindRule(const Name: string): TDIRule;
var
  Pos: Integer;
begin
  if not Find(name, Pos) then
    Exit(nil);
  Result := Objects[Pos] as TDIRule;
end;

initialization

TDIContainer.FDIContainer := TDIContainer.Create;

finalization

TDIContainer.FDIContainer.Free;

end.
