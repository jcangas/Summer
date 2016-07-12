unit TestSummer.SICO;

interface

uses
  DUnitX.TestFramework;

type
  TestSICO = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  end;

  [TestFixture]
  TestSICOBasic = class(TestSICO)
  public
    [Test]
    procedure TestLocate;
    [Test]
    procedure TestCreateInstanceCount;
    [Test]
    procedure TestCreateAndFreeInstanceCount;

    [Test]
    procedure TestSingleton;
    [Test]
    procedure TestSingletonInstanceCount;
  end;

  [TestFixture]
  TestSICOLocate = class(TestSICO)
  public
    [Test]
    procedure TestDefaultWithArg;
    [Test]
    procedure TestWithArg;
    [Test]
    procedure TestNamedWithArg;
    [Test]
    procedure TestNamedSingletonWithArg;
    [Test]
    procedure TestFactory;
  end;

  [TestFixture]
  TestSICOComplexLocate = class(TestSICO)
  private
  public
    [Test]
    procedure TestSolveDependency;
    [Test]
    procedure TestSolveDependencyByName;
  end;

implementation

uses
  Summer.SICO,
  TestSummer.SICO.Steps;

{ TestSICO }

procedure TestSICO.Setup;
begin
  SICO.Clear;
end;

procedure TestSICO.TearDown;
begin

end;

{ TestSICOBasic }

procedure TestSICOBasic.TestLocate;
var
  Service: ISICOService;
begin
  GIVEN_.A_service_registered;

  WHEN_.I_locate_the_service(Service);

  THEN_.Implmentor_class_is(Service, TSICOImplementor);
end;

procedure TestSICOBasic.TestCreateInstanceCount;
var
  Service1: ISICOService;
  Service2: ISICOService;
begin
  GIVEN_.A_service_registered;

  WHEN_.I_locate_the_service(Service1);
  AND_.I_locate_the_service(Service2);

  THEN_.Implmentors_are_not_same(Service1, Service2);
  ALSO_.Implmentor_count_is(2);
end;

procedure TestSICOBasic.TestCreateAndFreeInstanceCount;
var
  Service1: ISICOService;
  Service2: ISICOService;
begin
  GIVEN_.A_service_registered;

  WHEN_.I_locate_the_service(Service1);
  AND_.I_locate_the_service(Service2);
  AND_.I_free_the_service(Service1);

  THEN_.Implmentor_count_is(1);
end;

procedure TestSICOBasic.TestSingleton;
var
  Service1: ISICOService;
  Service2: ISICOService;
begin
  GIVEN_.A_service_registered_as_singleton;

  WHEN_.I_locate_the_service(Service1);
  AND_.I_locate_the_service(Service2);

  THEN_.Implmentors_are_same(Service1, Service2);
end;

procedure TestSICOBasic.TestSingletonInstanceCount;
var
  Service1: ISICOService;
  Service2: ISICOService;
begin
  GIVEN_.A_service_registered_as_singleton;

  WHEN_.I_locate_the_service(Service1);
  AND_.I_locate_the_service(Service2);

  THEN_.Implmentor_count_is(1);
end;

{ TestSICOLocate }

procedure TestSICOLocate.TestDefaultWithArg;
var
  Service: ISICOService;
begin
  GIVEN_.A_service_registered_with_arg;

  WHEN_.I_locate_the_service(Service);

  THEN_.Implementor_is_not_creeated_with_arg(Service);
end;

procedure TestSICOLocate.TestWithArg;
var
  Service: ISICOService;
begin
  GIVEN_.A_service_registered_with_arg(1);

  WHEN_.I_locate_the_service(Service);

  THEN_.Implementor_is_creeated_with_arg(Service);
  ALSO_.Implementor_argvalue_is(Service, 1);
end;

procedure TestSICOLocate.TestNamedWithArg;
var
  ServiceA: ISICOService;
  ServiceB: ISICOService;
begin
  GIVEN_.A_service_registered_with_arg_by_name('A', 1);
  AND_GIVEN_.A_service_registered_with_arg_by_name('B', 2);

  WHEN_.I_locate_the_service_named('A', ServiceA);
  AND_.I_locate_the_service_named('B', ServiceB);

  THEN_.Implementor_argvalue_is(ServiceA, 1);
  ALSO_.Implementor_argvalue_is(ServiceB, 2);
end;

procedure TestSICOLocate.TestFactory;
var
  Service: ISICOService;
begin
  GIVEN_.A_service_registered.Factory(
  function : TObject begin
    Result := TSICOImplementorWitArg.Create(101);
  end);

  WHEN_.I_locate_the_service(Service);

  THEN_.Implementor_argvalue_is(Service, 101);

end;

procedure TestSICOLocate.TestNamedSingletonWithArg;
var
  ServiceA1: ISICOService;
  ServiceA2: ISICOService;
  ServiceB: ISICOService;
begin
  GIVEN_.A_service_registered_with_arg_by_name_as_singleton('A', 1);
  AND_GIVEN_.A_service_registered_with_arg_by_name_as_singleton('B', 2);

  WHEN_.I_locate_the_service_named('A', ServiceA1);
  AND_.I_locate_the_service_named('A', ServiceA2);
  AND_.I_locate_the_service_named('B', ServiceB);

  THEN_.Implmentors_are_same(ServiceA1, ServiceA2);
  ALSO_.Implementor_argvalue_is(ServiceA1, 1);
  ALSO_.Implementor_argvalue_is(ServiceB, 2);
end;

{ TestSICOComplexLocate }

procedure TestSICOComplexLocate.TestSolveDependency;
var
  Service: ISICOService;
  ComplexService: ISICOComplexService;
begin
  GIVEN_.A_service_instance(Service);
  AND_GIVEN_.A_complex_service_registered_using(Service);

  WHEN_.I_locate_the_complexservice(ComplexService);

  THEN_.ComplexService_uses_the_service(ComplexService, Service);

end;

procedure TestSICOComplexLocate.TestSolveDependencyByName;
var
  ComplexService: ISICOComplexService;
  Service: ISICOService;
begin
  GIVEN_.A_service_registered_with_arg_by_name_as_singleton('A', 1);
  AND_GIVEN_.A_complex_service_registered_using('A');

  WHEN_.I_locate_the_complexservice(ComplexService);
  AND_.I_locate_the_service_named('A', Service);

  THEN_.ComplexService_uses_the_service(ComplexService, Service);

end;

end.
