{ == License ==
  - "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
  -  Summer for Delphi - http://github.com/jcangas/Summer
  -  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
  -  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

/// <summary>
/// SICO Implementa un Dependency Injection Container https://en.wikipedia.org/wiki/Dependency_injection
/// SICO es acrónimo de Simple Injection Container. La aparición del término simple,
/// está motivada porque se ha buscado una implmentación simple combinando
/// los patrones Fluent Interface (https://en.wikipedia.org/wiki/Fluent_interface) y
/// Strategy (https://en.wikipedia.org/wiki/Strategy_pattern).
/// </summary>
unit Summer.SICO;

interface

uses
  System.TypInfo,
  System.RTTI,
  System.SysUtils,
  System.Generics.Collections;

const
  ByNameKey = '{965183D2-1A23-4BC5-850D-B8D2B7A137C4}';

type
  TDIContainer = class;
  TFactoryKind = (fkPure, fkByName);
  /// <summary>
  /// Regla para injectar una dependencia. Los objetos de esta clase
  /// son las estrategias definidas para crear las instancias de las
  /// dependencias.
  /// Una regla captura en esencia 3 conceptos
  /// * El tipo que se pretende instanciar
  /// property ServiceType: PTypeInfo read FServiceType write SetServiceType;
  /// * El tipo usado como implementción. El objet devuelto será realmente de este tipo
  /// property ImplementorType: PTypeInfo;
  /// Un algortimo (la "strategy") para instanciar el ImplementorType.
  /// El implmentor puede ser por nombnre o anónimo
  /// property ByNameStrategy: TFunc<string, TObject> read FByNameStrategy write SetByNameStrategy;
  /// Lo más común para instanciar el Implmentor será invocar su constructor
  /// sin argumentos. Esta es la opción por defecto.
  /// Si se necesitan argumentos, se puden capturar usando Construct([...])
  /// Si la instanciación es compleja, podemoos usar Factory(...)
  /// Finalmente, la regla, captura modelo de ciclo de vida para el Implmentor
  /// Singleton: Solo hay una unica instancia del Implmentor y cada vez
  /// que se solicita la dependencia, se retorna dicha instancia.
  /// El Singleton se destruye al ser destruido la instancia de SICO
  /// ThreadSingleton. **No implmentado aún**. En este caso SICO, mantiente un Singleton
  /// para cada thread que solicita la dependencia.
  /// En otro caso, SICO fabrica una instancia cada vez que se solicita la dependencia.
  /// </summary>
  TDIRule = class(TObject)
  private
    class var FRTTIContext: TRTTIContext;
    class function GetRTTI(Info: PTypeInfo): TRTTIType;
  strict private
    FContainer: TDIContainer;
    FImplementorType: PTypeInfo;
    FServiceType: PTypeInfo;
    FFordwardToType: PTypeInfo;
    FName: string;
    FIsSingleton: Boolean;
    FSingleton: TObject;
    FArgs: TArray<TValue>;
    FFactoryKind: TFactoryKind;
    FBuildStrategy: TFunc<TObject>;
    FByNameStrategy: TFunc<string, TObject>;
    FUpdateCount: Integer;
    procedure SetBuildStrategy(const Value: TFunc<TObject>);
    procedure SetByNameStrategy(const Value: TFunc<string, TObject>);
    procedure SetName(const Value: string);
    procedure SetImplementorType(const Value: PTypeInfo);
    procedure SetServiceType(const Value: PTypeInfo);
  protected
    constructor Create(Container: TDIContainer; ImplementorType: PTypeInfo);
    function GetImplmentor(Name: string): TObject;
    procedure BeginUpdate;
    procedure EndUpdate;
    function DefaultCtorStrategy: TObject;
    function FordwardStrategy(Name: string): TObject;
    property Name: string read FName write SetName;
    property ImplementorType: PTypeInfo read FImplementorType write SetImplementorType;
    property ServiceType: PTypeInfo read FServiceType write SetServiceType;
    property IsSingleton: Boolean read FIsSingleton write FIsSingleton;
  public
    destructor Destroy; override;
    /// Fluent Api: Delega la creación de un servicio en otro
    function FordwardTo(const AType: PTypeInfo): TDIRule;
    /// Fluent Api: captura el Tipo de la dependencia
    function ForService(const AType: PTypeInfo; const Name: string = ''): TDIRule;
    /// Fluent Api: captura el algoritmo par instanciar una dependencia anonima
    function Factory(Builder: TFunc<TObject>): TDIRule; overload;
    /// Fluent Api: captura el algoritmo par instanciar una dependencia nombrada
    function Factory(Builder: TFunc<string, TObject>): TDIRule; overload;
    /// Fluent Api: caso simple de Factory, si simplemente se pretende invocar el construtor
    function Construct(Args: TArray<TValue>): TDIRule; overload;
    /// Fluent Api: Construct de un solo argumento para evitar el uso de []
    function Construct(Arg: TValue): TDIRule; overload;
    /// Fluent Api: mark implmentor as a singleton
    function AsSingleton: TDIRule;

    // Pending to implement:
    // function AsThreadSingleton: TDIRule;

    /// Argumentos capturados usando Construct
    property Args: TArray<TValue> read FArgs write FArgs;
    /// Contiene el algoritmo de creacion definido mediante Factory/Construct
    property BuildStrategy: TFunc<TObject> read FBuildStrategy write SetBuildStrategy;
    /// Contiene el algoritmo de creacion por nombre definido mediante Factory/Construct
    property ByNameStrategy: TFunc<string, TObject> read FByNameStrategy write SetByNameStrategy;
  end;

  /// Colección de reglas posibles para instanciar una misma dependencia
  TServiceRules = class
  private
    FServiceType: PTypeInfo;
    FRules: TObjectDictionary<string, TDIRule>;
    function ContainsRule(Rule: TDIRule): Boolean;
  public
    constructor Create(ServiceType: PTypeInfo);
    destructor Destroy; override;
    function GetRule(const Name: string): TDIRule;
    function FindRule(const Name: string): TDIRule; overload;
    function TryGetRule(const Name: string; out Rule: TDIRule): Boolean; overload;
    procedure Remove(Rule: TDIRule);
    procedure Add(Rule: TDIRule);
    property ServiceType: PTypeInfo read FServiceType;
  end;

  /// Clase genérica para facilitar la creacicón de Reglas para un tipo dado
  /// T representa el Implementor Type
  /// Notar que las instancias de esta clase se crean mediante el meétodo factoria
  /// "Returns" de la clase TDIContainer
  ///
  TDIRule<T: class> = class(TDIRule)
  private
  public
    constructor Create(Container: TDIContainer);
    function FordwardTo<TService>: TDIRule<T>;
    function ForService<TService>(const Name: string = ''): TDIRule<T>; overload;
    function Factory(Builder: TFunc<T>): TDIRule<T>; overload;
    function Factory(Builder: TFunc<string, T>): TDIRule<T>; overload;
    function AsSingleton: TDIRule<T>;
    function Construct(Arg: TValue): TDIRule<T>; overload;
    function Construct(Args: TArray<TValue>): TDIRule<T>; overload;
  end;

  /// Colección de todas las reglas conocidas por SICO
  TDIRules = TObjectDictionary<PTypeInfo, TServiceRules>;

  /// Un contenedor para injección de dependencias
  TDIContainer = class
  private
    class var FDIContainer: TDIContainer;
  strict private
    FRules: TDIRules;
  protected
    function GetService(out Intf; ServiceType: PTypeInfo; Name: string = ''): Boolean; overload;
    function GetServiceRulesOrDefault(ServiceType: PTypeInfo): TServiceRules;
    function GetServiceRule(ServiceType: PTypeInfo; Name: string): TDIRule;
    function ContainsRule(Rule: TDIRule): Boolean;
    procedure AddRule(Rule: TDIRule);
    procedure RemoveRule(Rule: TDIRule);
    procedure BeforeUpdate(Rule: TDIRule);
    procedure AfterUpdate(Rule: TDIRule);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    class function NoCtorFoundError(ServiceType: PTypeInfo; Name: string): Exception;
    class function NoRuleFoundError(ServiceType: PTypeInfo; Name: string): Exception;
    /// <summary> Crea una regla que usa ImplmentorType </summary>
    function Returns(ImplmentorType: PTypeInfo): TDIRule; overload;
    /// <summary> Crea una regla que usa TImplmentor </summary>
    function Returns<TImplementor: class>: TDIRule<TImplementor>; overload;
    /// <summary> Retorna la dependencia usando las reglas definidas mediante Returns</summary>
    function GetService<TService: IInterface>(Name: string = ''): TService; overload;
    /// <summary> Retorna la dependencia usando las reglas definidas mediante Returns</summary>
    function GetService(Info: PTypeInfo; Name: string = ''): TValue; overload;
  end;

  /// Returns the global injection container
function SICO: TDIContainer; inline;

implementation

uses
  Summer.Utils,
  Summer.RTTI;

resourcestring
  StrSICOErrorNoCtor = 'SICO error: No constructor found %s for service <%s>';
  StrSICOErrorNoInjec = 'SICO error: No injection Rule %s for service <%s>';

function ArgMatch(Arg: TValue; Param: TRttiParameter): Boolean;
begin
  Result := (Arg.TypeInfo = Param.ParamType.Handle) or
    ((Arg.TypeInfo = TypeInfo(string)) and (Param.ParamType is TRttiInterfaceType));
end;

function SICOArgsMatch(const SomeArgs: TArray<TValue>; Quality: TVoteQuality = TVoteQuality.vqRequires): TVoteFunc;
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
        if not ArgMatch(CopyArgs[idx], Parms[idx]) then
          Exit;
      Result := 1;
    end;
end;

function SICOSolveArgs(Method: TRttiMethod; const Args: TArray<TValue>): TArray<TValue>;
var
  Params: TArray<TRttiParameter>;
  idx: Integer;
  Service: TValue;
  Intf: IInterface;
begin
  Result := [];
  Params := Method.GetParameters;
  if (Length(Params) <> Length(Args)) then
    Exit;
  for idx := 0 to high(Args) do begin
    if (Params[idx].ParamType is TRttiInterfaceType) and (Args[idx].TypeInfo = TypeInfo(string)) then begin
      if SICO.GetService(Intf, Params[idx].ParamType.Handle, Args[idx].ToString) then
        TValue.Make(@Intf, Params[idx].ParamType.Handle, Service)
      else
        Service := nil;
      Result := Result + [Service];
    end
    else
      Result := Result + [Args[idx]];
  end;
end;

function SICO: TDIContainer;
begin
  Result := TDIContainer.FDIContainer;
end;

{ TDIRule }

function TDIRule.GetImplmentor(Name: string): TObject;
var
  Intf: IInterface;
begin
  if IsSingleton and Assigned(FSingleton) then
    Result := FSingleton
  else begin
    case FFactoryKind of
      fkByName:
        Result := ByNameStrategy(Name)
    else
      Result := BuildStrategy();
    end;

    if IsSingleton then begin
      FSingleton := Result;
      if Supports(Result, IInterface, Intf) then
        Intf._AddRef;
    end;
  end;
end;

function TDIRule.Construct(Args: TArray<TValue>): TDIRule;
begin
  Result := Self;
  Result.Args := Args;
end;

function TDIRule.Construct(Arg: TValue): TDIRule;
var
  Args: TArray<TValue>;
begin
  Args := [Arg];
  Result := Construct(Args);
end;

constructor TDIRule.Create(Container: TDIContainer; ImplementorType: PTypeInfo);
begin
  inherited Create;
  FContainer := Container;
  FImplementorType := ImplementorType;
  BuildStrategy := DefaultCtorStrategy;
end;

function TDIRule.DefaultCtorStrategy: TObject;
var
  AClass: TClass;
  Method: TRttiMethod;
  CallArgs: TArray<TValue>;
begin
  AClass := (GetRTTI(ImplementorType) as TRttiInstanceType).MetaclassType;
  Method := AClass.MethodBy([TMethod.KindIs([mkConstructor]), SICOArgsMatch(Args),
    TMethod.NameIs('Create', TVoteQuality.vqPrefers)]);
  if Method = nil then
    raise TDIContainer.NoCtorFoundError(ServiceType, Name);

  CallArgs := SICOSolveArgs(Method, Args);
  Result := Method.Invoke(AClass, CallArgs).AsObject;
end;

destructor TDIRule.Destroy;
var
  Intf: IInterface;
begin
  // workaround for XE compiler bug: FBuilder is not released !
  TFunc<TObject>(FBuildStrategy) := nil;
  TFunc<TObject>(FByNameStrategy) := nil;
  if IsSingleton then begin
    if Supports(FSingleton, IInterface, Intf) then
      Intf._Release
    else
      FSingleton.Free;
  end;
  inherited;
end;

function TDIRule.FordwardStrategy(Name: string): TObject;
begin
  Result := FContainer.GetServiceRule(FFordwardToType, Name).GetImplmentor(Name);
end;

function TDIRule.FordwardTo(const AType: PTypeInfo): TDIRule;
begin
  Result := Self;
  Result.FFordwardToType := AType;
  Result.ByNameStrategy := FordwardStrategy;
end;

function TDIRule.ForService(const AType: PTypeInfo; const Name: string): TDIRule;
begin
  Result := Self;
  BeginUpdate;
  Result.ServiceType := AType;
  Result.Name := Name;
  EndUpdate;
end;

function TDIRule.Factory(Builder: TFunc<string, TObject>): TDIRule;
begin
  Result := Self;
  ByNameStrategy := Builder;
end;

function TDIRule.Factory(Builder: TFunc<TObject>): TDIRule;
begin
  Result := Self;
  BuildStrategy := Builder;
end;

class function TDIRule.GetRTTI(Info: PTypeInfo): TRTTIType;
begin
  Result := FRTTIContext.GetType(Info);
end;

function TDIRule.AsSingleton: TDIRule;
begin
  Result := Self;
  IsSingleton := True;
end;

procedure TDIRule.BeginUpdate;
begin
  Inc(FUpdateCount);
  if FUpdateCount = 1 then
    FContainer.BeforeUpdate(Self);
end;

procedure TDIRule.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
    FContainer.AfterUpdate(Self);
end;

procedure TDIRule.SetName(const Value: string);
begin
  BeginUpdate;
  FName := Value;
  EndUpdate;
end;

procedure TDIRule.SetServiceType(const Value: PTypeInfo);
begin
  BeginUpdate;
  FServiceType := Value;
  EndUpdate;
end;

procedure TDIRule.SetImplementorType(const Value: PTypeInfo);
begin
  FImplementorType := Value;
end;

procedure TDIRule.SetByNameStrategy(const Value: TFunc<string, TObject>);
begin
  Name := ByNameKey;
  FByNameStrategy := Value;
  FFactoryKind := fkByName;
end;

procedure TDIRule.SetBuildStrategy(const Value: TFunc<TObject>);
begin
  FBuildStrategy := Value;
  FFactoryKind := fkPure;
end;

{ TDIRule<T> }

function TDIRule<T>.AsSingleton: TDIRule<T>;
begin
  Result := Self;
  inherited AsSingleton;
end;

function TDIRule<T>.Construct(Args: TArray<TValue>): TDIRule<T>;
begin
  Result := Self;
  Result.Args := Args;
end;

function TDIRule<T>.Construct(Arg: TValue): TDIRule<T>;
var
  Args: TArray<TValue>;
begin
  Args := [Arg];
  Result := Construct(Args);
end;

constructor TDIRule<T>.Create(Container: TDIContainer);
begin
  inherited Create(Container, TypeInfo(T));
end;

function TDIRule<T>.FordwardTo<TService>: TDIRule<T>;
begin
  Result := Self;
  inherited FordwardTo(TypeInfo(TService));
end;

function TDIRule<T>.ForService<TService>(const Name: string = ''): TDIRule<T>;
begin
  Result := ForService(TypeInfo(TService), Name) as TDIRule<T>;
end;

function TDIRule<T>.Factory(Builder: TFunc<T>): TDIRule<T>;
begin
  Result := Self;
  inherited Factory(TFunc<TObject>(Builder));
end;

function TDIRule<T>.Factory(Builder: TFunc<string, T>): TDIRule<T>;
begin
  Result := Self;
  inherited Factory(TFunc<string, TObject>(Builder));
end;

{ TDIContainer }

constructor TDIContainer.Create;
begin
  inherited Create;
  FRules := TDIRules.Create([doOwnsValues]);
end;

procedure TDIContainer.Clear;
begin
  FRules.Clear;
end;

destructor TDIContainer.Destroy;
begin
  FRules.Free;
  inherited;
end;

function TDIContainer.Returns(ImplmentorType: PTypeInfo): TDIRule;
begin
  TMonitor.Enter(Self);
  try
    Result := TDIRule.Create(Self, ImplmentorType);
    Result.ForService(ImplmentorType);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TDIContainer.Returns<TImplementor>: TDIRule<TImplementor>;
begin
  TMonitor.Enter(Self);
  try
    Result := TDIRule<TImplementor>.Create(Self);
    Result.ForService(TypeInfo(TImplementor));
  finally
    TMonitor.Exit(Self);
  end;
end;

class function TDIContainer.NoCtorFoundError(ServiceType: PTypeInfo; Name: string): Exception;
begin
  Result := Exception.CreateFmt(StrSICOErrorNoCtor, [Name, ServiceType.Name]);
end;

class function TDIContainer.NoRuleFoundError(ServiceType: PTypeInfo; Name: string): Exception;
begin
  Result := Exception.CreateFmt(StrSICOErrorNoInjec, [Name, ServiceType.Name]);
end;

function TDIContainer.GetServiceRule(ServiceType: PTypeInfo; Name: string): TDIRule;
var
  ServiceRules: TServiceRules;
begin
  ServiceRules := GetServiceRulesOrDefault(ServiceType);
  if not(ServiceRules.TryGetRule(Name, Result) or ServiceRules.TryGetRule(ByNameKey, Result)) then
    raise TDIContainer.NoRuleFoundError(ServiceType, Name);
end;

function TDIContainer.GetService(out Intf; ServiceType: PTypeInfo; Name: string): Boolean;
var
  Rule: TDIRule;
  ServiceGuid: TGuid;
  Implementor: TObject;
begin
  TMonitor.Enter(Self);
  try
    Rule := GetServiceRule(ServiceType, Name);
    Implementor := Rule.GetImplmentor(Name);
    ServiceGuid := GetTypeData(ServiceType)^.Guid;
    Result := Supports(Implementor, ServiceGuid, Intf);
    if not Result then
      IInterface(Intf) := nil;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TDIContainer.GetService<TService>(Name: string = ''): TService;
begin
  GetService(Result, TypeInfo(TService), Name);
end;

function TDIContainer.GetService(Info: PTypeInfo; Name: string = ''): TValue;
var
  VirtIntf: IInterface;
begin
  TMonitor.Enter(Self);
  try
    if GetService(VirtIntf, Info, Name) then
      TValue.Make(@VirtIntf, Info, Result);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TDIContainer.GetServiceRulesOrDefault(ServiceType: PTypeInfo): TServiceRules;
begin
  if FRules.TryGetValue(ServiceType, Result) then
    Exit;
  Result := TServiceRules.Create(ServiceType);
  FRules.Add(ServiceType, Result);
end;

procedure TDIContainer.AddRule(Rule: TDIRule);
begin
  GetServiceRulesOrDefault(Rule.ServiceType).Add(Rule);
end;

function TDIContainer.ContainsRule(Rule: TDIRule): Boolean;
begin
  Result := GetServiceRulesOrDefault(Rule.ServiceType).ContainsRule(Rule);
end;

procedure TDIContainer.RemoveRule(Rule: TDIRule);
begin
  GetServiceRulesOrDefault(Rule.ServiceType).Remove(Rule);
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

constructor TServiceRules.Create(ServiceType: PTypeInfo);
begin
  inherited Create;
  FServiceType := ServiceType;
  FRules := TObjectDictionary<string, TDIRule>.Create(TTextComparer.Create);
end;

type
  TCrackObjectDictionary = class(TDictionary<string, TObject>)
  public
    FOwnerships: TDictionaryOwnerships;
  end;

destructor TServiceRules.Destroy;
begin
  TCrackObjectDictionary(FRules).FOwnerships := [doOwnsValues];
  FRules.Free;
  inherited;
end;

procedure TServiceRules.Add(Rule: TDIRule);
begin
  FRules.AddOrSetValue(Rule.Name, Rule);
end;

procedure TServiceRules.Remove(Rule: TDIRule);
begin
  FRules.Remove(Rule.Name);
end;

function TServiceRules.ContainsRule(Rule: TDIRule): Boolean;
begin
  Result := FRules.ContainsKey(Rule.Name);
end;

function TServiceRules.GetRule(const Name: string): TDIRule;
begin
  if not TryGetRule(Name, Result) then
    raise TDIContainer.NoRuleFoundError(ServiceType, Name);
end;

function TServiceRules.FindRule(const Name: string): TDIRule;
begin
  TryGetRule(Name, Result);
end;

function TServiceRules.TryGetRule(const Name: string; out Rule: TDIRule): Boolean;
begin
  Result := FRules.TryGetValue(Name, Rule);
end;

initialization

TDIContainer.FDIContainer := TDIContainer.Create;

finalization

TDIContainer.FDIContainer.Free;

end.
