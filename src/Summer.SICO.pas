// A Simple Injection Container

unit Summer.SICO;

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
    class function GetRTTI(Info: PTypeInfo): TRTTIType;
  strict private
    FContainer: TDIContainer;
    FImplementorType: PTypeInfo;
    FServiceType: PTypeInfo;
    FFordwardToType: PTypeInfo;
    FName: string;
    FBuildStrategy: TFunc<TObject>;
    FIsSingleton: Boolean;
    FSingleton: TObject;
    FArgs: TArray<TValue>;
  private
    constructor Create(Container: TDIContainer; ImplementorType: PTypeInfo);
    function Build: TObject;
    function DefaultCtorStrategy: TObject;
    function FordwardStrategy: TObject;
    property Name: string read FName;
    property ImplementorType: PTypeInfo read FImplementorType;
    property ServiceType: PTypeInfo read FServiceType;
    property IsSingleton: Boolean read FIsSingleton write FIsSingleton;
  public
    destructor Destroy; override;
    function FordwardTo(const AType: PTypeInfo): TDIRule;
    function ForServiceType(const AType: PTypeInfo; const Name: string = ''): TDIRule;
    function Factory(Builder: TFunc<TObject>): TDIRule;
    property Args: TArray<TValue> read FArgs write FArgs;
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
   // function FordwardTo<TService>: TDIRule<T>;
    function Factory(Builder: TFunc<T>): TDIRule<T>;
    function AsSingleton: TDIRule<T>;
    function Construct(Arg: TValue): TDIRule<T>;overload;
    function Construct(Args: TArray<TValue>): TDIRule<T>;overload;
  end;

  TDIRules = TObjectDictionary<PTypeInfo, TDIRuleList>;
  TDIContainer = class
  private
    class var FDIContainer: TDIContainer;
    function GetService(out Intf; Info: PTypeInfo; Name: string=''): Boolean;overload;
    function GetService(Info: PTypeInfo; Name: string=''): TValue;overload;
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
    function GetService<TService: IInterface>(Name: string = ''): TService;overload;
  end;

function SICO: TDIContainer; inline;

implementation
uses Summer.Utils;

function ArgMatch(Arg: TValue; Param: TRttiParameter): Boolean;
begin
  Result := (Arg.TypeInfo = Param.ParamType.Handle)
            or ((Arg.TypeInfo = TypeInfo(string)) and (Param.ParamType is TRttiInterfaceType));
end;

function SICOArgsMatch(const SomeArgs: TArray<TValue>; Quality: TVoteQuality = vqRequires): TVoteFunc;
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
        if not ArgMatch(CopyArgs[idx], Parms[idx]) then Exit;
      Result := 1;
    end;
end;

function SICOSolveArgs(Method: TRttiMethod; const Args: TArray<TValue>): TArray<TValue>;
var
  Params: TArray<TRttiParameter>;
  idx: Integer;
  Implementor: TObject;
  Service: TValue;
  Intf: IInterface;
begin
  Result := [];
  Params := Method.GetParameters;
  if (Length(Params) <> Length(Args)) then
    Exit;
  for idx := 0 to high(Args) do begin
    if (Params[idx].ParamType is TRttiInterfaceType) and (Args[idx].TypeInfo = TypeInfo(string)) then begin
      Implementor := SICO.GetService(Params[idx].ParamType.Handle, Args[idx].ToString).AsObject;
      Supports(Implementor, TRttiInterfaceType(Params[idx].ParamType).GUID, Intf);
      TValue.Make(@Intf, Params[idx].ParamType.Handle, Service);
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

function TDIRule.Build: TObject;
var
  Intf: IInterface;
begin
  if IsSingleton and Assigned(FSingleton) then
    Result := FSingleton
  else
  begin
    Result := FBuildStrategy();
    if IsSingleton then
    begin
      FSingleton := Result;
      if Supports(Result, IInterface, Intf) then
        Intf._AddRef;
    end;
  end;
end;

constructor TDIRule.Create(Container: TDIContainer; ImplementorType: PTypeInfo);
begin
  inherited Create;
  FContainer := Container;
  FImplementorType := ImplementorType;
  FBuildStrategy := DefaultCtorStrategy;
end;

function TDIRule.DefaultCtorStrategy: TObject;
var
  AClass: TClass;
  Method: TRTTIMethod;
  CallArgs: TArray<TValue>;
begin
  AClass := (GetRTTI(ImplementorType) as TRttiInstanceType).MetaclassType;
  Method := AClass.MethodBy([TMethod.KindIs(mkConstructor),
    SICOArgsMatch(Args),
    TMethod.NameIs('Create', vqPrefers)]
  );
  if Method = nil then Exit(nil); // raise??

  CallArgs := SICOSolveArgs(Method, Args);
  Result := Method.Invoke(AClass, CallArgs).AsObject;
end;

destructor TDIRule.Destroy;
var
  Intf: IInterface;
begin
  // workaround for compiler bug: FBuilder is not released !
  TFunc<TObject>(FBuildStrategy) := nil;
  if IsSingleton then
  begin
    if Supports(FSingleton, IInterface, Intf) then
      Intf._Release
    else
      FSingleton.Free;
  end;
  inherited;
end;

function TDIRule.FordwardStrategy: TObject;
begin
  Result := FContainer.FindRule(FFordwardToType, Name).Build;
end;

function TDIRule.FordwardTo(const AType: PTypeInfo): TDIRule;
begin
  Result := Self;
  Result.FFordwardToType := AType;
  Result.FBuildStrategy := FordwardStrategy;
end;

function TDIRule.ForServiceType(const AType: PTypeInfo;
  const Name: string): TDIRule;
begin
  FContainer.BeforeUpdate(Self);
  Result := Self;
  Result.FServiceType := AType;
  Result.FName := Name;
  FContainer.AfterUpdate(Self);
end;

function TDIRule.Factory(Builder: TFunc<TObject>): TDIRule;
begin
  Result := Self;
  FBuildStrategy := Builder;
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

function TDIRule<T>.Construct(Args: TArray<TValue>): TDIRule<T>;
begin
  Result := Self;
  Result.Args := Args;
end;

function TDIRule<T>.Construct(Arg: TValue): TDIRule<T>;
var
  Args: TArray<TVAlue>;
begin
  Args := [Arg];
  Result := Construct(Args);
end;

constructor TDIRule<T>.Create(Container: TDIContainer);
begin
  inherited Create(Container, TypeInfo(T));
end;

(*
function TDIRule<T>.FordwardTo<TService>: TDIRule<T>;
begin
  Result := Self;
  inherited FordwardTo(TypeInfo(TService));
end;
*)

function TDIRule<T>.ForService<TService>(const Name: string = ''): TDIRule<T>;
begin
  Result := ForServiceType(TypeInfo(TService), Name) as TDIRule<T>;
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

function TDIContainer.GetService(out Intf; Info: PTypeInfo; Name: string): Boolean;
var
  Rule: TDIRule;
  ServiceGuid: TGuid;
  Instance: TObject;
begin
  TMonitor.Enter(Self);
  try
    Rule := FindRule(Info, Name);
    Instance := Rule.Build;
    ServiceGuid := GetTypeData(Info)^.Guid;
    Result := Supports(Instance, ServiceGuid, Intf);
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
  Result := Self[ServiceType][Name];
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
      [Name, ServiceType.Name]);
end;

function TDIRuleList.FindRule(const Name: string): TDIRule;
var
  Pos: Integer;
begin
  if not Find(Name, Pos) then
    Exit(nil);
  Result := Objects[Pos] as TDIRule;
end;

initialization

TDIContainer.FDIContainer := TDIContainer.Create;

finalization

TDIContainer.FDIContainer.Free;

end.
