unit SummerFW.DDO.Store;

interface

uses Rtti, Classes, SysUtils,
  SummerFW.Utils.Collections,
  SummerFW.DDO.OQL,
  SummerFW.DDO.CallBack,
  SummerFW.DDO.StoreInfo,
  SummerFW.DDO.Mappers,
  SummerFW.DDO.DBXDriver;

type
  TDDOStore = class
  strict private
    FCache: TObjectDictionary<TValue, TObject>;
    FDriver: IDDODriver;
  private
    function GetFromCache(Klass: TClass; ID: TValue; out Obj: TObject): Boolean;
    procedure SaveNew(Obj: TObject);
    procedure SaveModified(Obj: TObject);
    procedure SaveDeleted(Obj: TObject);
    function GenObjID(Klass: TClass): TValue;
  public
    constructor Create(ConnectionStr: string);
    destructor Destroy; override;
    property Driver: IDDODriver read FDriver;
    function FindByID(Klass: TClass; ID: TValue): TObject;
    function From<T: class, constructor>(Klass: TClass = nil): IQueryable<T>;
    procedure Save(Obj: TObject);
  end;

type
  TQueryable<T: class, constructor> = class(TInterfacedObject, IQueryable<T>)
  strict private
    FDataStore: TDDOStore;
    FClass: TClass;
    FQuery: OQL;
    FMap: TMapper;
    FDriver: IDDODriver;
  public
    constructor Create(ADataStore: TDDOStore; FromClass: TClass = nil);
    destructor Destroy; override;
    function SELECT: IEnumerable<T>;
    function FIRST: T;
    function COUNT: Int64;
    function WHERE(Expr: OQL.TkBoolExpr): IQueryable<T>;
    function INSERT(Expr: OQL.TkLetExprList): Integer;
    function UPDATE(Expr: OQL.TkLetExprList): Integer;
    function DELETE: Integer;
  end;

  TCursorEnumerator<T: class, constructor> = class(TInterfacedEnumerator, IEnumerator<T>)
  strict private
    FStore: TDDOStore;
    FReader: IStoreReader;
    FMap: TMapper;
  private
    function ReadObject: TObject;
    function ReadPlainProp(Obj: TObject; Prop: TPropMapper): TValue;
    procedure ReadReferenceProp(Obj: TObject; Prop: TPropMapper);

    function ReadStoredValue(Name: string): TValue;
  protected
    function DoGetCurrent: TObject; override;
    function MoveNext: Boolean; override;
    procedure Reset; override;
    function GetCurrent: T;
  public
    constructor Create(Store: TDDOStore; Map: TMapper;
      Reader: IStoreReader); overload;
  end;

  //TCursor<T: class, constructor> = class(TInterfacedEnumerable<T>, IEnumerable<T>)
  TCursor<T: class, constructor> = class(TList<T>, IEnumerable<T>, IEnumerable)
  strict private
    FStore: TDDOStore;
    FMap: TMapper;
    FQry: OQL;
  public
    function GetEnumerator: IEnumerator<T>; override;
    constructor Create(Store: TDDOStore; Map: TMapper; Qry: OQL);
  end;

  TLazzyLoader = class(TBaseLoader)
  private
    FPropMapper: TPropMapper;
    FInstance: TObject;
    FStore: TObject;
    procedure ReadRelationProp(Obj: TObject; Prop: TPropMapper);
  protected
    function GetInstance: TObject;override;
    function GetMapper: TPropMapper;override;
  public
    constructor Create(Obj: TObject; Prop: TPropMapper; AStore: TObject);
    procedure Load;override;
    property Mapper: TPropMapper read GetMapper;
  end;

implementation
uses DBPlatform;

{ TLazyLoader }

constructor TLazzyLoader.Create(Obj: TObject; Prop: TPropMapper; AStore: TObject);
begin
  inherited Create;
  FStore := AStore;
  FInstance := Obj;
  FPropMapper := Prop;
end;

procedure TLazzyLoader.ReadRelationProp(Obj: TObject;Prop: TPropMapper);
var
  List: TList<TObject>;
  ClassReferenced: TClass;
  ReferenceKey: string;
begin
  ClassReferenced := Prop.RelatedClass;
  List := TList<TObject>.Create;
  List._AddRef;
  if not (Prop.Relation is HasManyAttribute) then Exit;
  ReferenceKey := TMapper.GetFor(ClassReferenced)[HasManyAttribute(Prop.Relation).RelatedProp].StorageName;
  with OQL do
    List.AddRange((FStore as TDDOStore).From<TObject>(ClassReferenced)
      .WHERE(EQ(ReferenceKey, TStoreInfo.GetID(Obj))).SELECT);

  Prop.SetValue(Obj, List);
end;

function TLazzyLoader.GetInstance: TObject;
begin
  Result := FInstance;
end;

function TLazzyLoader.GetMapper: TPropMapper;
begin
  Result := FPropMapper;
end;

procedure TLazzyLoader.Load;
begin
  ReadRelationProp(FInstance, FPropMapper);
end;

{ TDDOStore }

constructor TDDOStore.Create(ConnectionStr: string);
begin
  FDriver := CreateDriver(ConnectionStr);
  FCache := TObjectDictionary<TValue, TObject>.Create([doOwnsValues]);
end;

destructor TDDOStore.Destroy;
begin
  FCache.Free;
  inherited;
end;

function TDDOStore.GenObjID(Klass: TClass): TValue;
begin
  Result := FDriver.ExecSingleValue
    (OQL.Raw('SELECT NEXT VALUE FOR GEN_NEXT_ID FROM RDB$DATABASE'));
end;

function TDDOStore.GetFromCache(Klass: TClass; ID: TValue;
  out Obj: TObject): Boolean;
begin
  Result := FCache.ContainsKey(ID);
  if not Result then
    FCache.Add(ID, Klass.NewInstance);
  Obj := FCache[ID];
end;

function TDDOStore.FindByID(Klass: TClass; ID: TValue): TObject;
begin
  if GetFromCache(Klass, ID, Result) then
    Exit;
  Result := From<TObject>(Klass).WHERE(OQL.EQ('ID', ID)).FIRST;
end;

function TDDOStore.From<T>(Klass: TClass = nil): IQueryable<T>;
begin
  Result := TQueryable<T>.Create(Self, Klass);
end;

{ TQueryable<T> }

constructor TQueryable<T>.Create(ADataStore: TDDOStore;
  FromClass: TClass = nil);
begin
  inherited Create;
  if not Assigned(FromClass) then
    FromClass := T;
  FClass := FromClass;

  FDataStore := ADataStore;
  FDriver := FDataStore.Driver;
  FMap := TMapper.GetFor(FClass);
  FQuery := OQL.Create;
  FQuery.From(FMap.StorageName);
end;

destructor TQueryable<T>.Destroy;
begin
  FreeAndNil(FQuery);
  inherited;
end;

function TQueryable<T>.FIRST: T;
var
  C: IEnumerable<TObject>;
  Obj: TObject;
begin
  FQuery.TAKE(1).SELECT;
  C := TCursor<TObject>.Create(FDataStore, FMap, FQuery);
  Obj := nil;
  for Obj in C do
    break;
  Result := T(Obj);
end;

function TQueryable<T>.COUNT: Int64;
begin
  FQuery.COUNT;
  Result := FDriver.ExecSingleValue(FQuery).AsInt64;
end;

function TQueryable<T>.SELECT: IEnumerable<T>;
begin
  FQuery.SELECT;
  Result := TCursor<T>.Create(FDataStore, FMap, FQuery);
end;

function TQueryable<T>.INSERT(Expr: OQL.TkLetExprList): Integer;
begin
  FQuery.INSERT(Expr);
  Result := FDriver.Exec(FQuery);
end;

function TQueryable<T>.UPDATE(Expr: OQL.TkLetExprList): Integer;
begin
  FQuery.UPDATE(Expr);
  Result := FDriver.Exec(FQuery);
end;

function TQueryable<T>.DELETE: Integer;
begin
  FQuery.DELETE;
  Result := FDriver.Exec(FQuery);
end;

function TQueryable<T>.WHERE(Expr: OQL.TkBoolExpr): IQueryable<T>;
begin
  FQuery.WHERE(Expr);
  Result := Self;
end;

{ TCursor<T> }

constructor TCursor<T>.Create(Store: TDDOStore; Map: TMapper; Qry: OQL);
begin
  inherited Create;
  FStore := Store;
  FMap := Map;
  FQry := Qry;
end;

function TCursor<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := TCursorEnumerator<T>.Create(FStore, FMap, FStore.Driver.CreateReader(FQry));
end;

procedure TDDOStore.Save(Obj: TObject);
begin
  TCallback.CallBeforeSave(Obj);
  if TStoreInfo.IsUpdated(Obj) then
    SaveModified(Obj)
  else if TStoreInfo.IsNew(Obj) then
    SaveNew(Obj)
  else if TStoreInfo.IsDeleted(Obj) then
    SaveDeleted(Obj);
  TStoreInfo.MakeSaved(Obj);
  TCallback.CallAfterSave(Obj);
end;

procedure TDDOStore.SaveDeleted(Obj: TObject);
begin
  with OQL do
    Self.From<TObject>(Obj.ClassType).WHERE(EQ('ID', TStoreInfo.GetID(Obj))).DELETE;
end;

procedure TDDOStore.SaveModified(Obj: TObject);
var
  M: TPropMapper;
  LetExpr: OQL.TkLetExprList;
begin
  LetExpr := OQL.TkLetExprList.Create;

  for M in TMapper.GetFor(Obj) do begin
    if not M.IsStored(Obj) then
      Continue;
    if M.IsID then
      Continue;
    if M.IsRelation then
    Continue;
    if M.IsReference then
      LetExpr.Add(OQL.Let(M.StorageName, TStoreInfo.GetID(M.GetValue(Obj).AsObject)))
    else
      LetExpr.Add(OQL.Let(M.StorageName, M.GetValue(Obj)))
  end;
  with OQL do
    Self.From<TObject>(Obj.ClassType).WHERE(EQ('ID', TStoreInfo.GetID(Obj)))
      .UPDATE(LetExpr);
end;

procedure TDDOStore.SaveNew(Obj: TObject);
var
  M: TPropMapper;
  LetExpr: OQL.TkLetExprList;
begin
  LetExpr := OQL.TkLetExprList.Create;
  for M in TMapper.GetFor(Obj) do begin
    if not M.IsStored(Obj) then
      Continue;
    if M.IsID then
      Continue;
    M.SetValue(Obj, GenObjID(Obj.ClassType));
    LetExpr.Add(OQL.Let(M.StorageName, M.GetValue(Obj)));
  end;
  with OQL do
    Self.From<TObject>(Obj.ClassType).WHERE(EQ('ID', TStoreInfo.GetID(Obj)))
      .INSERT(LetExpr);
end;

{ TCursorEnumerator }

constructor TCursorEnumerator<T>.Create(Store: TDDOStore; Map: TMapper;
  Reader: IStoreReader);
begin
  FStore := Store;
  FMap := Map;
  FReader := Reader;
  Reset;
end;

function TCursorEnumerator<T>.MoveNext: Boolean;
begin
  Result := FReader.MoveNext;
end;

function TCursorEnumerator<T>.DoGetCurrent: TObject;
begin
  Result := ReadObject;
end;

function TCursorEnumerator<T>.GetCurrent: T;
begin
  Result := T(DoGetCurrent);
end;

procedure TCursorEnumerator<T>.Reset;
begin
  FReader.Reset;
end;

function TCursorEnumerator<T>.ReadStoredValue(Name: string): TValue;
begin
  Result := FReader.ReadValue(Name);
end;

function TCursorEnumerator<T>.ReadPlainProp(Obj: TObject;
  Prop: TPropMapper): TValue;
begin
  Result := ReadStoredValue(Prop.StorageName);
  Prop.SetValue(Obj, Result);
end;

procedure TCursorEnumerator<T>.ReadReferenceProp(Obj: TObject; Prop: TPropMapper);
var
  IDReferenced: TValue;
  ClassReferenced: TClass;
  Referenced: TObject;
begin
  IDReferenced := ReadStoredValue(Prop.StorageName);

  if IDReferenced.IsEmpty then
    Exit;
//  Prop.RelatedClass ??
  ClassReferenced := TClass(TRttiInstanceType(Prop.Mapped.PropertyType)
    .MetaclassType);
  Referenced := FStore.FindByID(ClassReferenced, IDReferenced);

  Prop.SetValue(Obj, Referenced);
end;

function TCursorEnumerator<T>.ReadObject: TObject;
var
  M: TPropMapper;
begin
  if FStore.GetFromCache(FMap.ForClass, ReadStoredValue(FMap['ID'].StorageName),
    Result) then
    Exit;

  FMap['ID'].SetValue(Result, ReadStoredValue(FMap['ID'].StorageName));

  for M in FMap do begin
    if not M.IsStored(Result) then
      Continue;

    if M.IsRelation then
      FMap.LazzyLoadBy(TLazzyLoader.Create(Result, M, FStore))
    else if M.IsReference then
      ReadReferenceProp(Result, M)
    else if M.IsPlain then
      ReadPlainProp(Result, M)
  end;

  TStoreInfo.MakeStoredClean(Result);
  FMap.Proxify(Result);
end;

end.
