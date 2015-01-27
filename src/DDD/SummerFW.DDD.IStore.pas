unit SummerFW.DDD.IStore;

interface

uses
  Generics.Collections,
  Data.DB,
  SummerFW.DDD.Query;

type

  TDataList<T: class, constructor> = class(TObjectList<T>)
  public
    constructor Create; virtual;
    class function ItemClass: TClass; virtual;
    class function NewItem: T; virtual;
    function IsEmpty: Boolean;
    function First: T;
    function Last: T;
  end;

  TDataList = class(TDataList<TObject>);
  TDataListClass = class of TDataList;

  IStore = interface;
  TStoreNotify = reference to procedure(const Sendeer: IStore);
  TOnExecSQLEvent = reference to procedure(const Sendeer: IStore; const SQL: string; const AParams: array of variant);

  IStore = interface
    ['{2E215345-D8C2-4864-B9BF-D0DDA58E1798}']
    function GetOnExecSQL: TOnExecSQLEvent;
    procedure SetOnExecSQL(const Value: TOnExecSQLEvent);

    function Fill(const Query: TQuery; DataObjectClass: TClass; out List): Boolean;
    function ExecSQL(const ASQL: String; out DataSet: TDataSet; const AParams: TSQLParams = nil; const ATypes: TSQLTypes = nil): Boolean; overload;
    function ExecSQL(const ASQL: String; const AParams: TSQLParams; const ATypes: TSQLTypes = nil): LongInt; overload;

    function GetConnectionDefFileName: string;
    procedure SetConnectionDefFileName(const Value: string);
    function GetConnectionString: string;
    procedure SetConnectionString(const Value: string);
    function GetConnectionDefName: string;
    procedure SetConnectionDefName(const Value: string);
    function GetBeforeConnect: TStoreNotify;
    procedure SetBeforeConnect(const Value: TStoreNotify);
    function GetAfterConnect: TStoreNotify;
    procedure SetAfterConnect(const Value: TStoreNotify);
    property ConnectionDefFileName: string read GetConnectionDefFileName write SetConnectionDefFileName;
    property ConnectionDefName: string read GetConnectionDefName write SetConnectionDefName;
    property ConnectionString: string read GetConnectionString write SetConnectionString;
    property OnExecSQL: TOnExecSQLEvent read GetOnExecSQL write SetOnExecSQL;
    property BeforeConnect: TStoreNotify read GetBeforeConnect write SetBeforeConnect;
    property AfterConnect: TStoreNotify read GetAfterConnect write SetAfterConnect;
  end;

implementation

{ TDataObject<T> }

function TDataList<T>.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

class function TDataList<T>.NewItem: T;
begin
  Result := T.Create;
end;

class function TDataList<T>.ItemClass: TClass;
begin
  Result := T;
end;

constructor TDataList<T>.Create;
begin
  inherited Create;
end;

function TDataList<T>.First: T;
begin
  if IsEmpty then
    Exit(nil);
  Result := inherited;
end;

function TDataList<T>.Last: T;
begin
  if IsEmpty then
    Exit(nil);
  Result := inherited;
end;

end.
