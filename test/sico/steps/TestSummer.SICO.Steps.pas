unit TestSummer.SICO.Steps;

interface

uses
  DUnitX.TestFramework,
  Summer.SICO;

type
  ISICOService = interface
    ['{867CDC2B-5EE9-4567-9D34-F393DB96D56D}']
  end;

  ISICOComplexService = interface
    ['{71887D8D-BD5A-44F8-9C39-1C46D3437F33}']
    function Using: ISICOService;
  end;

  TSICOImplementor = class(TInterfacedObject, ISICOService)
  private
    class var FInstanceCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    class property InstanceCount: Integer read FInstanceCount;
  end;

  TSICOImplementorWitArg = class(TSICOImplementor)
  private
    FCreatedWithArg: Boolean;
    FArgValue: Integer;
  public
    constructor Create(const Arg: Integer);
    property CreatedWithArg: Boolean read FCreatedWithArg;
    property ArgValue: Integer read FArgValue;
  end;

  TSICOComplexImplementor = class(TInterfacedObject, ISICOComplexService)
  private
    FUsing: ISICOService;
    FArg2: string;
    FArg1: Integer;
  public
    constructor Create(Using: ISICOService; Arg1: Integer; Arg2: string);
    function Using: ISICOService;
    property Arg1: Integer read FArg1;
    property Arg2: string read FArg2;
  end;

  GIVEN_ = class
  private
    class function Register_ISICOService<T: class>(Name: string = ''): TDIRule<T>;
    class function Register_ISICOComplexService<T: class>(Name: string = ''): TDIRule<T>;
  public
    class procedure A_service_instance(out Service: ISICOService);
    class function A_service_registered: TDIRule;
    class function A_service_registered_by_name(Name: string): TDIRule;
    class function A_service_registered_as_singleton: TDIRule;

    class function A_service_registered_with_arg: TDIRule; overload;
    class function A_service_registered_with_arg(Arg: Integer): TDIRule; overload;
    class function A_service_registered_with_arg_by_name(Name: string; Arg: Integer): TDIRule;
    class function A_service_registered_with_arg_by_name_as_singleton(Name: string; Arg: Integer): TDIRule;

    class function A_complex_service_registered: TDIRule;
    class function A_complex_service_registered_using(Dependency: ISICOService): TDIRule;overload;
    class function A_complex_service_registered_using(Dependency: string): TDIRule;overload;
  end;

  AND_GIVEN_ = GIVEN_;

  WHEN_ = class
  public
    class procedure I_locate_the_service(out Service: ISICOService);
    class procedure I_locate_the_complexservice(out Service: ISICOComplexService);
    class procedure I_locate_the_service_named(Name: string; out Service: ISICOService);
    class procedure I_free_the_service(var Service);
  end;

  AND_ = WHEN_;

  THEN_ = class
  public
    class procedure Implmentor_class_is(Service: ISICOService; ImplmentorClass: TClass);
    class procedure Implmentor_count_is(Value: Integer);
    class procedure Implementor_is_creeated_with_arg(Service: ISICOService);
    class procedure Implementor_is_not_creeated_with_arg(Service: ISICOService);
    class procedure Implmentors_are_same(Service1, Service2: ISICOService);
    class procedure Implmentors_are_not_same(Service1, Service2: ISICOService);
    class procedure Implementor_argvalue_is(Service: ISICOService; Arg: Integer);

    class procedure ComplexService_uses_the_service(ComplexService: ISICOComplexService; Service: ISICOService);
  end;

  ALSO_ = THEN_;

implementation
uses System.Rtti;

{ GIVEN_ }

class function GIVEN_.Register_ISICOService<T>(Name: string= ''): TDIRule<T>;
begin
  Result := SICO.Returns<T>.ForService<ISICOService>(Name);
end;

class function GIVEN_.Register_ISICOComplexService<T>(Name: string): TDIRule<T>;
begin
  Result := SICO.Returns<T>.ForService<ISICOComplexService>(Name);
end;

class procedure GIVEN_.A_service_instance(out Service: ISICOService);
begin
  Service := TSICOImplementor.Create;
end;

class function GIVEN_.A_service_registered: TDIRule;
begin
  Result := Register_ISICOService<TSICOImplementor>;
end;

class function GIVEN_.A_service_registered_by_name(Name: string): TDIRule;
begin
  Result := Register_ISICOService<TSICOImplementor>(Name);
end;

class function GIVEN_.A_service_registered_as_singleton: TDIRule;
begin
  Result := A_service_registered.AsSingleton;
end;

class function GIVEN_.A_service_registered_with_arg_by_name(Name: string; Arg: Integer): TDIRule;
begin
  Result := SICO.Returns<TSICOImplementorWitArg>.ForService<ISICOService>(Name).Construct(Arg);
end;

class function GIVEN_.A_service_registered_with_arg_by_name_as_singleton(Name: string; Arg: Integer): TDIRule;
begin
  Result := A_service_registered_with_arg_by_name(Name, Arg).AsSingleton;
end;

class function GIVEN_.A_service_registered_with_arg: TDIRule;
begin
  Result := Register_ISICOService<TSICOImplementorWitArg>;
end;

class function GIVEN_.A_service_registered_with_arg(Arg: Integer): TDIRule;
begin
  Result := A_service_registered_with_arg.Construct(Arg);
end;

class function GIVEN_.A_complex_service_registered: TDIRule;
begin
  Result := Register_ISICOComplexService<TSICOComplexImplementor>;
end;

class function GIVEN_.A_complex_service_registered_using(Dependency: ISICOService): TDIRule;
begin
  Result := A_complex_service_registered.Construct([TValue.From(Dependency), 666, 'AFixture']);
end;

class function GIVEN_.A_complex_service_registered_using(Dependency: string): TDIRule;
begin
  Result := A_complex_service_registered.Construct([Dependency, 666, 'AFixture'])
end;

{ WHEN_ }

class procedure WHEN_.I_locate_the_service(out Service: ISICOService);
begin
  Service := SICO.GetService<ISICOService>;
end;

class procedure WHEN_.I_locate_the_service_named(Name: string; out Service: ISICOService);
begin
  Service := SICO.GetService<ISICOService>(Name);
end;

class procedure WHEN_.I_free_the_service(var Service);
begin
  ISICOService(Service) := nil;
end;

class procedure WHEN_.I_locate_the_complexservice(out Service: ISICOComplexService);
begin
  Service := SICO.GetService<ISICOComplexService>;
end;

{ THEN_ }

class procedure THEN_.Implementor_is_creeated_with_arg(Service: ISICOService);
begin
  Assert.IsTrue(TSICOImplementorWitArg(Service).CreatedWithArg)
end;

class procedure THEN_.Implementor_is_not_creeated_with_arg(Service: ISICOService);
begin
  Assert.IsFalse(TSICOImplementorWitArg(Service).CreatedWithArg);
end;

class procedure THEN_.Implmentors_are_same(Service1, Service2: ISICOService);
begin
  Assert.AreSame(TObject(Service1), TObject(Service2));
end;

class procedure THEN_.Implmentors_are_not_same(Service1, Service2: ISICOService);
begin
  Assert.AreNotSame(TObject(Service1), TObject(Service2));
end;

class procedure THEN_.ComplexService_uses_the_service(ComplexService: ISICOComplexService; Service: ISICOService);
begin
  Assert.AreSame(Service, ComplexService.Using)
end;

class procedure THEN_.Implementor_argvalue_is(Service: ISICOService; Arg: Integer);
begin
  Assert.AreEqual(Arg, TSICOImplementorWitArg(Service).ArgValue);
end;

class procedure THEN_.Implmentor_count_is(Value: Integer);
begin
  Assert.AreEqual(Value, TSICOImplementor.InstanceCount);
end;

class procedure THEN_.Implmentor_class_is(Service: ISICOService; ImplmentorClass: TClass);
begin
  Assert.AreEqual(ImplmentorClass, TObject(Service).ClassType);
end;

{ TSICOTestImplmentor }

constructor TSICOImplementor.Create;
begin
  inherited Create;
  Inc(FInstanceCount)
end;

destructor TSICOImplementor.Destroy;
begin
  Dec(FInstanceCount);
  inherited;
end;

{ TSICOTestImplementorWitArgInt }

constructor TSICOImplementorWitArg.Create(const Arg: Integer);
begin
  inherited Create;
  FCreatedWithArg := True;
  FArgValue := Arg;
end;

{ TSICOComplexImplementor }

constructor TSICOComplexImplementor.Create(Using: ISICOService; Arg1: Integer; Arg2: string);
begin
  inherited Create;
  FUsing := Using;
  FArg1 := Arg1;
  FArg2 := Arg2;
end;

function TSICOComplexImplementor.Using: ISICOService;
begin
  Result := FUsing;
end;

end.
