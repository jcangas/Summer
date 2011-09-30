unit SummerFW.DDO.Mappers;

interface

uses TypInfo, RTTI, Generics.Collections;

type
  TObjectStoreAttribute = class(TCustomAttribute)
  end;
  StorageNameAttribute = class(TObjectStoreAttribute)
  private
    FName: string;
  public
    constructor Create(Name: string);
    property Name: string read FName;
  end;

  /// TODO: Añadir RelatedProp / Foreignkey
  Relationttribute = class(StorageNameAttribute)
  private
    FRelatedClass: TClass;
  public
    constructor Create(Name: string; RelatedClass: TClass); overload;
    constructor Create(Name: string; RelatedClass: string); overload;
    property RelatedClass: TClass read FRelatedClass;
  end;

  HasManyAttribute = class(Relationttribute)
  private
    FRelatedProp: string;
  public
    constructor Create(Name: string; RelatedClass: TClass; RelatedProp: string ); overload;
    constructor Create(Name: string; RelatedClass: string; RelatedProp: string ); overload;
    property RelatedProp: string read FRelatedProp;
  end;

  TBasicMapper = class
  strict private
    FMapped: TRttiNamedObject;
    FStorageName: string;
  protected
    procedure SetMapped(Value: TRttiNamedObject);
  public
    constructor Create(RttiObj: TRttiNamedObject);
    function GetMapped: TRttiNamedObject;
    property StorageName: string read FStorageName;
  end;

  TCustomMapper<T: TRttiNamedObject> = class(TBasicMapper)
  private
    function GetMapped: T;
  public
    property Mapped: T read GetMapped;
  end;

  TPropMapper = class(TCustomMapper<TRttiInstanceProperty>)
  strict private
    FPropField: TRttiField;
    FRelation: Relationttribute;
  private
    function GetRelatedClass: TClass;
  public
    constructor Create(ForProp: TRttiInstanceProperty);
    property PropField: TRttiField read FPropField;
    function GetValue(Obj: TObject) : TValue;
    procedure SetValue(Obj: TObject; AValue: TValue);
    function CanRead: Boolean;
    function CanWrite: Boolean;
    function IsStored(AtObj: TObject): Boolean;
    function IsID: Boolean;
    function IsRelation: Boolean;
    function IsReference: Boolean;
    function IsPlain: Boolean;
    property Relation: Relationttribute read FRelation;
    property RelatedClass: TClass read GetRelatedClass;
  end;

  TPropMappers = TObjectDictionary<string, TPropMapper>;

  TBaseLoader = class
  protected
    function GetInstance: TObject;virtual;abstract;
    function GetMapper: TPropMapper;virtual;abstract;
  public
    procedure Load;virtual;abstract;
    property Instance: TObject read GetInstance;
    property Mapper: TPropMapper read GetMapper;
  end;

  TInstanceManager = class;
  TMapper = class(TCustomMapper<TRttiInstanceType>)
  private
    class var RC: TRttiContext;
    class var RCCount: Integer;
    procedure BeginRTTI;
    procedure EndRTTI;
  strict private
    FClass: TClass;
    FManager: TInstanceManager;
    FPropMappers: TPropMappers;
  private
    procedure CreatePropMappers;
    function GetPropMappers(PropName: string): TPropMapper;
    function GetPropMapperCount: Integer;
    procedure SetInterceptorEnabled(const Value: Boolean);
    function GetInterceptorEnabled: Boolean;
  protected
  public
    class function GetFor(Klass: TClass): TMapper; overload;
    class function GetFor(Obj: TObject): TMapper; overload;
    constructor Create(ForClass: TClass);
    destructor Destroy; override;
    function GetEnumerator: TPropMappers.TValueEnumerator;
    procedure Proxify(AInstance: TObject);
    procedure LazzyLoadBy(Loader: TBaseLoader);overload;

    property  InterceptorEnabled: Boolean read GetInterceptorEnabled write SetInterceptorEnabled;
    property ForClass: TClass read FClass;
    property PropMapperCount: Integer read GetPropMapperCount;
    property PropMappers[PropName: string]: TPropMapper
      read GetPropMappers; default;
  end;

  TVirtualMethodInterceptorEx = class(TVirtualMethodInterceptor)
  public
    procedure UnProxify(AInstance: TObject);
  end;

  TPropAccessorKind = (paNone, paGetter, paSetter);
  TInstanceManager = class
  private
    FLoaders: TObjectList<TBaseLoader>;
    FInterceptor: TVirtualMethodInterceptorEx;
    FInterceptorEnabled: Boolean;
    procedure AfterInterceptorNotify(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; var Result: TValue);
    procedure BeforeInterceptorNotify(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; out DoInvoke: boolean; out Result: TValue);
  protected
    function GetAccesorKind(Instance: TObject; Method: TRttiMethod): TPropAccessorKind;
    function GetGetter(Instance: TObject; PropInfo: PPropInfo): Pointer;
    function GetSetter(Instance: TObject; PropInfo: PPropInfo): Pointer;
    function FindLazzyLoader(Instance: TObject; Method: TRttiMethod; out Loader: TBaseLoader): Boolean;
    function IsAccesor(Instance: TObject; Method: TRttiMethod): Boolean;inline;
    function IsGetter(Instance: TObject; Method: TRttiMethod): Boolean;inline;
    function IsSetter(Instance: TObject; Method: TRttiMethod): Boolean;inline;
    procedure SetInterceptorEnabled(const Value: Boolean);
  public
    constructor Create(AClass: TClass);
    destructor Destroy; override;
    procedure Proxify(AInstance: TObject);
    procedure AddLazzy(Loader: TBaseLoader);
    property  InterceptorEnabled: Boolean read FInterceptorEnabled write SetInterceptorEnabled;
  end;

implementation

uses SysUtils, SysConst,
  SummerFW.DDO.StoreInfo;

var
  FMappers: TDictionary<string, TMapper>;


class function TMapper.GetFor(Obj: TObject): TMapper;
begin
  Result := GetFor(Obj.ClassType);
end;

class function TMapper.GetFor(Klass: TClass): TMapper;
begin
  if not FMappers.ContainsKey(Klass.ClassName) then
    FMappers.Add(Klass.ClassName, TMapper.Create(Klass));
  Result := FMappers[Klass.ClassName];
end;


type
  TVirtualMethodInterceptorCracked = class
  protected type
    TInterceptInfo = class
    private
      {$HINTS OFF}
      FImpl: TMethodImplementation;
     {$HINTS ON}
      FOriginalCode: Pointer;
      FProxyCode: Pointer;
      FMethod: TRttiMethod;
    public
      property OriginalCode: Pointer read FOriginalCode;
      property ProxyCode: Pointer read FProxyCode;
      property Method: TRttiMethod read FMethod;
    end;
  public
    FContext: TRttiContext;
    FOriginalClass: TClass;
    FProxyClass: TClass;
    FProxyClassData: Pointer;
    FIntercepts: TObjectList<TInterceptInfo>;
  end;

constructor StorageNameAttribute.Create(Name: string);
begin
  inherited Create;
  FName := Name;
end;

{ Relationttribute }
constructor Relationttribute.Create(Name: string; RelatedClass: TClass);
begin
  inherited Create(Name);
  FRelatedClass := RelatedClass;
end;

constructor Relationttribute.Create(Name, RelatedClass: string);
begin
  with TRttiContext.Create do begin
    Self.Create(Name, (FindType(RelatedClass) as TRttiInstanceType)
      .MetaclassType);
    Free;
  end;
end;

{ TBasicMapper }
constructor TBasicMapper.Create(RttiObj: TRttiNamedObject);
begin
  inherited Create;
  SetMapped(RttiObj);
end;

function TBasicMapper.GetMapped: TRttiNamedObject;
begin
  Result := FMapped;
end;

procedure TBasicMapper.SetMapped(Value: TRttiNamedObject);
var
  Attr: TCustomAttribute;
begin
  FMapped := Value;
  FStorageName := '';
  if FMapped = nil then
    Exit;
  for Attr in FMapped.GetAttributes() do begin
    if not(Attr is StorageNameAttribute) then
      Continue;
    FStorageName := StorageNameAttribute(Attr).Name;
    Exit;
  end;
  FStorageName := FMapped.Name;
end;

{ TCustomMapper<T> }

function TCustomMapper<T>.GetMapped: T;
begin
  Result := T( inherited GetMapped);
end;

{ TPropMapper }

procedure TPropMapper.SetValue(Obj: TObject; AValue: TValue);
begin
  if CanWrite then
    PropField.SetValue(Obj, AValue);
end;

function TPropMapper.GetRelatedClass: TClass;
begin
  if Relation = nil then
    Result := nil
  else
    Result := FRelation.RelatedClass;
end;

function TPropMapper.GetValue(Obj: TObject): TValue;
begin
  if CanRead then
    Result := PropField.GetValue(Obj);
end;

function TPropMapper.CanRead: Boolean;
begin
  Result := Assigned(PropField);
end;

function TPropMapper.CanWrite: Boolean;
begin
  Result := Assigned(PropField);
end;

constructor TPropMapper.Create(ForProp: TRttiInstanceProperty);
var
  Attr: TCustomAttribute;
begin
  inherited Create(ForProp);
  FPropField := Mapped.Parent.GetField('F' + Mapped.Name);
  for Attr in Mapped.GetAttributes do
    if Attr is Relationttribute then begin
      FRelation := Relationttribute(Attr);
    end;
end;

function TPropMapper.IsPlain: Boolean;
begin
  Result := not IsReference and not IsRelation;
end;

function TPropMapper.IsReference: Boolean;
begin
  Result := Mapped.PropertyType.IsInstance;
end;

function TPropMapper.IsRelation: Boolean;
begin
  Result := (FRelation <> nil);
end;

function TPropMapper.IsID: Boolean;
begin
  Result := SameText(Mapped.Name, 'ID');
end;

function TPropMapper.IsStored(AtObj: TObject): Boolean;
begin
  Result := CanRead and CanWrite and IsStoredProp(AtObj, Mapped.PropInfo);
end;

constructor TMapper.Create(ForClass: TClass);
begin
  BeginRTTI;
  inherited Create(RC.GetType(ForClass));
  FClass := ForClass;
  FManager := TInstanceManager.Create(ForClass);
  FPropMappers := TPropMappers.Create([doOwnsValues]);
  CreatePropMappers;
  InterceptorEnabled := True;
end;

destructor TMapper.Destroy;
begin
  InterceptorEnabled := False;
  FPropMappers.Free;
  FManager.Free;
  EndRTTI;
  inherited;
end;

procedure TMapper.BeginRTTI;
begin
  if RCCount = 0 then
    RC := TRttiContext.Create;
  Inc(RCCount);
end;

procedure TMapper.EndRTTI;
begin
  Dec(RCCount);
  if RCCount = 0 then
    RC.Free;
end;

function TMapper.GetEnumerator: TPropMappers.TValueEnumerator;
begin
  Result := FPropMappers.Values.GetEnumerator;
end;

function TMapper.GetPropMapperCount: Integer;
begin
  Result := FPropMappers.Count;
end;

function TMapper.GetPropMappers(PropName: string): TPropMapper;
begin
  Result := FPropMappers[PropName];
end;

procedure TMapper.LazzyLoadBy(Loader: TBaseLoader);
begin
  FManager.AddLazzy(Loader);
end;

procedure TMapper.Proxify(AInstance: TObject);
begin
  FManager.Proxify(AInstance);
end;

function TMapper.GetInterceptorEnabled: Boolean;
begin
  Result := FManager.InterceptorEnabled;
end;

procedure TMapper.SetInterceptorEnabled(const Value: Boolean);
begin
  FManager.InterceptorEnabled := Value;
end;

procedure TMapper.CreatePropMappers;
var
  RProp: TRttiProperty;
begin
  for RProp in Mapped.GetProperties do begin
    FPropMappers.Add(RProp.Name, TPropMapper.Create(RProp as TRttiInstanceProperty));
  end;
end;

{ HasManyAttribute }

constructor HasManyAttribute.Create(Name: string; RelatedClass: TClass;
  RelatedProp: string);
begin
  inherited Create(Name, RelatedClass);
  FRelatedProp := RelatedProp;
end;

constructor HasManyAttribute.Create(Name, RelatedClass, RelatedProp: string);
begin
  inherited Create(Name, RelatedClass);
  FRelatedProp := RelatedProp;
end;


{ TInstanceManager }

procedure TInstanceManager.AddLazzy(Loader: TBaseLoader);
begin
  FLoaders.Add(Loader);
end;

constructor TInstanceManager.Create(AClass: TClass);
begin
  inherited Create;
  FInterceptor := TVirtualMethodInterceptorEx.Create(AClass);
  FLoaders := TObjectList<TBaseLoader>.Create(True);
  FInterceptorEnabled := False;
end;

destructor TInstanceManager.Destroy;
begin
  FLoaders.Free;
  FInterceptor.Free;
  inherited;
end;

function TInstanceManager.GetSetter(Instance: TObject;
  PropInfo: PPropInfo): Pointer;
var
  setter: Integer;
begin
  Result := nil;
  setter := Integer(PropInfo^.SetProc);
  if (setter and $FF000000) = $FF000000 then
    Exit; // Field
  if (setter and $FF000000) = $FE000000 then
    // Virtual dispatch, but with offset, not slot
    Result := PPointer(PInteger(Instance)^ + Smallint(setter))^
  else
    // Static dispatch
    Result := Pointer(setter);
end;

function TInstanceManager.GetGetter(Instance: TObject;
  PropInfo: PPropInfo): Pointer;
var
  getter: Integer;
begin
  Result := nil;
  getter := Integer(PropInfo^.GetProc);
  if (getter and $FF000000) = $FF000000 then
    Exit; // Field
  if (getter and $FF000000) = $FE000000 then
    // Virtual dispatch, but with offset, not slot
    Result := PPointer(PInteger(Instance)^ + Smallint(getter))^
  else
    // Static dispatch
    Result := Pointer(getter);
end;

function TInstanceManager.GetAccesorKind(Instance: TObject; Method: TRttiMethod): TPropAccessorKind;
var
  RProp: TRttiProperty;
  PInfo: PPropInfo;
  idx: Integer;
  Code: Pointer;
  Found: Boolean;
begin
  Result := paNone;
  Found := False;
  with TVirtualMethodInterceptorCracked(FInterceptor) do begin
    for idx := 0 to FIntercepts.Count - 1 do begin
      Found := FIntercepts[idx].Method = Method;
      if Found then Break;
    end;
    if not Found then Exit;
    Code := FIntercepts[idx].ProxyCode;
    for RProp in Method.Parent.GetProperties do begin
      PInfo := (RProp as TRttiInstanceProperty).PropInfo;
      if (Code = GetSetter(Instance, PInfo)) then
        Result := paSetter
      else if (Code = GetGetter(Instance, PInfo)) then
        Result := paGetter;
      if Result <> paNone then Exit;
    end;
  end;
end;

function TInstanceManager.IsAccesor(Instance: TObject; Method: TRttiMethod): Boolean;
begin
  Result := GetAccesorKind(Instance, Method) <> paNone;
end;

function TInstanceManager.IsGetter(Instance: TObject; Method: TRttiMethod): Boolean;
begin
  Result := GetAccesorKind(Instance, Method) = paGetter;
end;

function TInstanceManager.IsSetter(Instance: TObject; Method: TRttiMethod): Boolean;
begin
  Result := GetAccesorKind(Instance, Method) = paSetter;
end;

procedure TInstanceManager.AfterInterceptorNotify(Instance: TObject;
  Method: TRttiMethod; const Args: TArray<TValue>; var Result: TValue);
begin
  if IsSetter(Instance, Method) then begin
    TStoreInfo.MakeUpdated(Instance);
  end;
end;

procedure TInstanceManager.BeforeInterceptorNotify(Instance: TObject;
  Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: boolean; out Result: TValue);
var
  Loader: TBaseLoader;
begin
  if (Method.Name = 'FreeInstance') then
    TStoreInfo.Destroy(Instance);
  if IsGetter(Instance, Method) then begin
    Loader := nil;
    if FindLazzyLoader(Instance, Method, Loader) then begin
      Loader.Load;
      FLoaders.Remove(Loader);
    end;
  end;
end;

function TInstanceManager.FindLazzyLoader(Instance: TObject; Method: TRttiMethod; out Loader: TBaseLoader): Boolean;
var
  L: TBaseLoader;
begin
  for L in FLoaders do begin
    Result := (L.Instance = Instance) and ('Get' + L.Mapper.Mapped.Name = Method.Name);
    if not Result then Continue;
    Loader := L;
    Exit;
 end;
  Result := False;
  Loader := nil;
end;

procedure TInstanceManager.Proxify(AInstance: TObject);
begin
  FInterceptor.Proxify(AInstance);
end;

procedure TInstanceManager.SetInterceptorEnabled(const Value: Boolean);
begin
  FInterceptorEnabled := Value;
  if FInterceptorEnabled then begin
    FInterceptor.OnBefore := BeforeInterceptorNotify;
    FInterceptor.OnAfter := AfterInterceptorNotify;
  end
  else begin
    FInterceptor.OnBefore := nil;
    FInterceptor.OnAfter := nil;
  end;

end;

{ TVirtualMethodInterceptorEx }

procedure TVirtualMethodInterceptorEx.UnProxify(AInstance: TObject);
begin
  if PPointer(AInstance)^ <> ProxyClass then
    raise EInvalidCast.CreateRes(@SInvalidCast);
  PPointer(AInstance)^ := OriginalClass;
end;

initialization
  FMappers := TObjectDictionary<string, TMapper>.Create([doOwnsValues]);
finalization
  FMappers.Free;
end.
