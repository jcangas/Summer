unit SummerFW.DDD.Repository;

interface

uses
  Generics.Collections,
  System.TypInfo,
  System.Rtti,
  System.SysUtils,
  PureMVC.Interfaces.IProxy,
  PureMVC.Patterns.Proxy,
  PureMVC.Patterns.Facade,
  SummerFW.DDD.Utils,
  SummerFW.DDD.IStore,
  SummerFW.DDD.Query;

type
  TRepository<T: class, constructor> = class(TProxy < TDataList < T >> )
  private
    FStore: IStore;
  protected
    procedure SetParamTypes(Query: TQuery); virtual;
  public
    class function Retrieve(const ProxyName: string): IProxy;
    class function RetrieveOrCreate(const ProxyName: string; const Store: IStore): IProxy;
    class function GetDBType(RProp: TRttiInstanceProperty): TFieldType; overload;
    class function GetDBType(TInfo: PTypeInfo): TFieldType; overload; virtual;
    class function NombreTabla: string; virtual;
    class function ClavePrimaria(const Instance: TObject): TSlice; virtual;
    procedure AfterConstruction; override;
    function Where(Columns: TArray<string>; Params: TSQLParams): TQuery;
    function Desc(const Column: string): TColumnOrder;
    function Asc(const Column: string): TColumnOrder;
    function Find(const Query: TQuery): Boolean;
    function First(const Query: TQuery): Boolean;
    function FindAll: Boolean;
    function Find_By_PK(const PK: TSlice): Boolean;
    procedure Insert(Model: TObject); virtual;
    procedure Update(Model: TObject); virtual;
    procedure Delete(Model: TObject); virtual;
    property Store: IStore
      read FStore
      write FStore;
  end;

implementation

uses
  System.StrUtils,
  System.Variants;

{ TCoreProxy<T> }

function TRepository<T>.Where(Columns: TArray<string>; Params: TSQLParams): TQuery;
begin
  Result := TQuery.From(NombreTabla).Where(Columns, Params);
end;

function TRepository<T>.First(const Query: TQuery): Boolean;
begin
  Query.Take(1);
  Result := Find(Query);
end;

procedure TRepository<T>.AfterConstruction;
begin
  DataObject := TDataList<T>.Create;
  inherited;
end;

procedure TRepository<T>.SetParamTypes(Query: TQuery);
var
  Slice: TSlice;
begin
  Slice := TSlice.From(Query.ParamNames, T);
  Slice.ForEach(procedure(var Item: TSlice.Titem; var StopEnum: Boolean) begin
    Query.ParamTypes[Item.index] := GetDBType(Item.Rtti);
  end);
end;

function TRepository<T>.Find(const Query: TQuery): Boolean;
var
  DataList: TDataList<T>;
begin
  SetParamTypes(Query);
  Result := Store.Fill(Query, TDataList<T>, DataList);
  DataObject := DataList;
end;

function TRepository<T>.FindAll: Boolean;
begin
  Result := Find(TQuery.From(NombreTabla));
end;

class function TRepository<T>.NombreTabla: string;
begin
  Result := T.ClassName;
  // Remove 'T' prefix
  Result := Result.Remove(0, 1);
  // Pluralize
  Result := Result + 's';
end;

class function TRepository<T>.Retrieve(const ProxyName: string): IProxy;
begin
  Result := TFacade.Instance.RetrieveProxy(ProxyName);
end;

class function TRepository<T>.RetrieveOrCreate(const ProxyName: string; const Store: IStore): IProxy;
begin
  Result := Retrieve(ProxyName);
  if Assigned(Result) then
    Exit;
  Result := Self.Create(ProxyName);
  (Result as TRepository<T>).Store := Store;
  TFacade.Instance.RegisterProxy(Result);
end;

class function TRepository<T>.GetDBType(TInfo: PTypeInfo): TFieldType;
begin
  case TInfo.Kind of
    tkInteger, tkInt64, tkEnumeration:
      Result := TFieldType.ftInteger;
    tkFloat: begin
        if TInfo = TypeInfo(TDate) then
          Result := TFieldType.ftDate
        else if TInfo = TypeInfo(TTime) then
          Result := TFieldType.ftTime
        else if TInfo = TypeInfo(TDateTime) then
          Result := TFieldType.ftDateTime
        else
          Result := TFieldType.ftSingle;
      end;
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString:
      Result := TFieldType.ftString;
  else
    Result := TFieldType.ftUnknown;
  end;
end;

class function TRepository<T>.GetDBType(RProp: TRttiInstanceProperty): TFieldType;
begin
  Result := GetDBType(RProp.PropInfo.PropType^);
end;

function TRepository<T>.Desc(const Column: string): TColumnOrder;
begin
  Result.Ascending := False;
  Result.Column := Column;
end;

function TRepository<T>.Asc(const Column: string): TColumnOrder;
begin
  Result.Ascending := True;
  Result.Column := Column;
end;

class function TRepository<T>.ClavePrimaria(const Instance: TObject): TSlice;
begin
  Result.From(['ID'], Instance);
end;

procedure TRepository<T>.Insert(Model: TObject);
var
  SQL: string;
  Params: TArray<Variant>;
  Types: TArray<TFieldType>;
  Conector: string;
  Slice: TSlice;
begin
  SetLength(Params, 0);
  SetLength(Types, 0);
  SQL := Format('insert into %s (' + sLineBreak, [NombreTabla]);
  Conector := '';
  Slice := TSlice.From(Model);
  Slice.ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      if not Item.IsStored then
        Exit;
      SQL := SQL + Conector + Item.Name;
      if Conector.IsEmpty then
        Conector := sLineBreak + ', ';
    end);

  SQL := SQL + ') VALUES (' + sLineBreak;

  Conector := '';
  Slice.ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      if not Item.IsStored then
        Exit;
      SQL := SQL + Conector + ':' + Item.Name;
      Params := Params + [Item.Value];
      Types := Types + [GetDBType(Item.Rtti)];
      if Conector.IsEmpty then
        Conector := sLineBreak + ', ';
    end);
  SQL := SQL + ')';
  Store.ExecSQL(SQL, Params, Types);
end;

procedure TRepository<T>.Update(Model: TObject);
var
  SQL: string;
  Params: TArray<Variant>;
  Types: TArray<TFieldType>;
  Conector: string;
  PK: TSlice;
  Prop: TRttiInstanceProperty;
begin
  SetLength(Params, 0);
  SetLength(Types, 0);
  PK := ClavePrimaria(Model);
  SQL := Format('update %s set' + sLineBreak, [NombreTabla]);
  Conector := '';
  TSlice.From(Model).ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      if not Item.IsStored then
        Exit;
      if PK.Contains(Item.Name) then
        Exit;
      SQL := SQL + Conector + Format('%0:s = :%0:s', [Item.Name]);
      Params := Params + [Item.Value];
      Types := Types + [GetDBType(Item.Rtti)];
      if Conector.IsEmpty then
        Conector := sLineBreak + ', ';
    end);

  SQL := SQL + sLineBreak + 'WHERE' + sLineBreak;

  Conector := '';
  PK.ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      SQL := SQL + Conector + Format('(%0:s = :%0:s)', [Item.Name]);
      Params := Params + [Item.Value];
      Types := Types + [GetDBType(Item.Rtti)];
      if Conector.IsEmpty then
        Conector := sLineBreak + ', ';
    end);
  Store.ExecSQL(SQL, Params, Types);
end;

procedure TRepository<T>.Delete(Model: TObject);
var
  SQL: string;
  Params: TArray<Variant>;
  Types: TArray<TFieldType>;
  Conector: string;
  PK: TSlice;
  Prop: TRttiInstanceProperty;
begin
  SetLength(Params, 0);
  SetLength(Types, 0);
  PK := ClavePrimaria(Model);
  SQL := Format('delete from %s' + sLineBreak, [NombreTabla]);
  SQL := SQL + sLineBreak + 'WHERE' + sLineBreak;
  Conector := '';
  PK.ForEach(
    procedure(var Item: TSlice.TItem; var StopEnum: Boolean)
    begin
      SQL := SQL + Conector + Format('(%0:s = :%0:s)', [Item.Name]);
      Params := Params + [Item.Value];
      Types := Types + [GetDBType(Item.Rtti)];
      if Conector.IsEmpty then
        Conector := sLineBreak + ', ';
    end);
  Store.ExecSQL(SQL, Params, Types);
end;

function TRepository<T>.Find_By_PK(const PK: TSlice): Boolean;
begin
  Result := First(Where(PK.GetNames, PK.GetValues));
end;

end.
