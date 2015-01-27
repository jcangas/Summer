unit SummerFW.DDD.Store;

interface

uses
  Generics.Collections,
  System.SysUtils,
  System.Classes,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.FMXUI.Wait,
  FireDAC.Comp.UI,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  SummerFW.DDD.IStore,
  SummerFW.DDD.Query;

type
  TStore = class(TInterfacedObject, IStore)
  private
    FConnection: TFDConnection;
    FOnExecSQL: TOnExecSQLEvent;
    FBeforeConnect: TStoreNotify;
    FAfterConnect: TStoreNotify;
  protected
    procedure DoOnExecSQL(const ASQL: string; const AParams: array of Variant);
    function Connection: TFDConnection;
    procedure DoBeforeConnect(Sender: TObject);
    procedure DoAfterConnect(Sender: TObject);
  public
    destructor Destroy; override;
    function GetOnExecSQL: TOnExecSQLEvent;
    procedure SetOnExecSQL(const Value: TOnExecSQLEvent);
    function GetBeforeConnect: TStoreNotify;
    procedure SetBeforeConnect(const Value: TStoreNotify);
    function GetAfterConnect: TStoreNotify;
    procedure SetAfterConnect(const Value: TStoreNotify);

    function GetConnectionString: string;
    procedure SetConnectionString(const Value: string);
    function GetConnectionDefFileName: string;
    procedure SetConnectionDefFileName(const Value: string);
    function GetConnectionDefName: string;
    procedure SetConnectionDefName(const Value: string);

    function Fill(const Query: TQuery; T: TClass; out List): Boolean;
    function ExecSQL(const ASQL: string; out DataSet: TDataSet; const AParams: TSQLParams = nil; const ATypes: TSQLTypes = nil)
      : Boolean; overload;
    function ExecSQL(const ASQL: string; const AParams: TSQLParams; const ATypes: TSQLTypes = nil)
      : LongInt; overload;
    property ConnectionString: string read GetConnectionString write SetConnectionString;
    property OnExecSQL: TOnExecSQLEvent read GetOnExecSQL write SetOnExecSQL;
    property BeforeConnect: TStoreNotify read GetBeforeConnect write SetBeforeConnect;
    property AfterConnect: TStoreNotify read GetAfterConnect write SetAfterConnect;
  end;

implementation

uses
  SummerFW.DDD.Utils;

function TStore.Fill(const Query: TQuery; T: TClass; out List): Boolean;
var
  Data: TDataSet;
  Item: TObject;
  DataList: TDataList;
begin
  DataList := TDataListClass(T).Create;
  TObject(List) := DataList;
  try
    Result := ExecSQL(Query.ToSQL, Data, Query.Params, Query.ParamTypes);
    if not Result then
      Exit;
    while not Data.Eof do begin
      Item := TDataListClass(T).NewItem;
      DataList.Add(Item);
      TPropsInjector.InjectFields(Item, Data);
      Data.Next;
    end;
  finally
    FreeAndNil(Data);
  end;
end;

function TStore.ExecSQL(const ASQL: string; out DataSet: TDataSet; const AParams: TSQLParams = nil; const ATypes: TSQLTypes = nil): Boolean;
var
  Query: TFDQuery;
  i: Integer;
begin
  TMonitor.Enter(Self);
  DataSet := nil;
  try
    DoOnExecSQL(ASQL, AParams);
    Query := TFDQuery.Create(nil);
    DataSet := Query;
    Query.FetchOptions.Mode := fmAll;
    Query.Connection := Connection;
    Query.SQL.Text := ASQL;

    if Length(AParams) = Query.Params.Count then
      for i := Low(AParams) to High(AParams) do begin
        Query.Params.Items[i].DataType := ATypes[i];
        Query.Params.Items[i].Value := AParams[i];
      end;

    Query.Active := True;
    Result := not Query.IsEmpty;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TStore.Connection: TFDConnection;
begin
  if FConnection = nil then begin
    FConnection := TFDConnection.Create(nil);
    FConnection.BeforeConnect := DoBeforeConnect;
    FConnection.AfterConnect := DoAfterConnect;
  end;
  Result := FConnection;
end;

destructor TStore.Destroy;
begin
  FConnection.Free;
  inherited;
end;

procedure TStore.DoAfterConnect(Sender: TObject);
begin
  if Assigned(FAfterConnect) then
    FAfterConnect(Self);
end;

procedure TStore.DoBeforeConnect(Sender: TObject);
begin
  if Assigned(FBeforeConnect) then
    FBeforeConnect(Self);
end;

procedure TStore.DoOnExecSQL(const ASQL: string; const AParams: array of Variant);
begin
  if Assigned(FOnExecSQL) then
    FOnExecSQL(Self, ASQL, AParams);
end;

function TStore.ExecSQL(const ASQL: string; const AParams: TSQLParams;
  const ATypes: TSQLTypes): LongInt;
begin
  TMonitor.Enter(Self);
  try
    DoOnExecSQL(ASQL, AParams);
    Result := Connection.ExecSQL(ASQL, AParams, ATypes);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TStore.GetAfterConnect: TStoreNotify;
begin
  Result := FAfterConnect;
end;

function TStore.GetBeforeConnect: TStoreNotify;
begin
  Result := FBeforeConnect;
end;

function TStore.GetConnectionDefFileName: string;
begin
  Result := FDManager.ConnectionDefFileName
end;

procedure TStore.SetAfterConnect(const Value: TStoreNotify);
begin
  FAfterConnect := Value;
end;

procedure TStore.SetBeforeConnect(const Value: TStoreNotify);
begin
  FBeforeConnect := Value;
end;

procedure TStore.SetConnectionDefFileName(const Value: string);
begin
  FDManager.ConnectionDefFileName := Value
end;

function TStore.GetConnectionDefName: string;
begin
  Result := Connection.ConnectionDefName;
end;

procedure TStore.SetConnectionDefName(const Value: string);
begin
  Connection.ConnectionDefName := Value;
end;

function TStore.GetConnectionString: string;
begin
  Result := Connection.ConnectionString;
end;

procedure TStore.SetConnectionString(const Value: string);
begin
  Connection.ConnectionString := Value;
end;

function TStore.GetOnExecSQL: TOnExecSQLEvent;
begin
  Result := FOnExecSQL;
end;

procedure TStore.SetOnExecSQL(const Value: TOnExecSQLEvent);
begin
  FOnExecSQL := Value;
end;

end.
