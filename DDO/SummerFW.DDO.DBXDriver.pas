unit SummerFW.DDO.DBXDriver;

interface
uses RTTI,
  SummerFW.DDO.OQL,
  SummerFW.DDO.Mappers,
  DB,
  SqlExpr;

type
  IStoreReader = interface
    procedure Reset;
    function MoveNext: Boolean;
    function ReadValue(Name: string): TValue;
  end;

  IDDODriver = interface
    function CreateReader(Qry: OQL): IStoreReader;
    function Exec(Qry: OQL): Integer;
    function ExecSingleValue(Qry: OQL): TValue;
    function Connection: TSQLConnection;
  end;

function CreateDriver(ConnectionStr: string): IDDODriver;overload;

implementation
uses SummerFW.Utils.Log;

type
  TDBXDriver = class(TInterfacedObject, IDDODriver)
  private
    FConnection: TSQLConnection;
    function Exec(Qry: OQL): Integer;
    function ExecSingleValue(Qry: OQL): TValue;
  protected
    function CreateReader(Qry: OQL): IStoreReader;
    function Connection: TSQLConnection;
  public
    constructor Create(ConnectionStr: string);
    destructor Destroy;override;
  end;

  TDBXStoreReader = class(TInterfacedObject, IStoreReader)
  strict private
    FDriver: TDBXDriver;
    FReturnsFirst: Boolean;
    FDataset: TDataset;
  private
    function ReadValue(Name: string): TValue;
  protected
    function MoveNext: Boolean;
    procedure Reset;
  public
    constructor Create(Driver: TDBXDriver; Qry: OQL);
    destructor Destroy;override;
  end;

function CreateDriver(ConnectionStr: string): IDDODriver;
begin
  Result := TDBXDriver.Create(ConnectionStr);
end;


{ TDBXDriver }

function TDBXDriver.Connection: TSQLConnection;
begin
  Result := FConnection;
end;

constructor TDBXDriver.Create(ConnectionStr: string);
begin
  inherited Create;
  FConnection := TSQLConnection.Create(nil);
  FConnection.Params.CommaText := ConnectionStr;
  FConnection.DriverName := FConnection.Params.Values['drivername'];
  FConnection.Params.CommaText := ConnectionStr;
  FConnection.LoginPrompt := False;
end;

destructor TDBXDriver.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TDBXDriver.Exec(Qry: OQL): Integer;
var
  SQL: string;
begin
  SQL := Qry.ToSQL;
  Logger.Trace('DDO-SQL: ' + SQL);
  Result := FConnection.ExecuteDirect(SQL);
end;

function TDBXDriver.ExecSingleValue(Qry: OQL): TValue;
var
  RS: TDataset;
  SQL: string;
begin
  SQL := Qry.ToSQL;
  Logger.Trace('DDO-SQL: ' + SQL);
  FConnection.Execute(Qry.ToSQL, nil, @RS);
  Result := TValue.FromVariant(RS.Fields[0].Value);
  RS.Free;
end;

function TDBXDriver.CreateReader(Qry: OQL): IStoreReader;
begin
  Result := TDBXStoreReader.Create(Self, Qry);
end;

{ TDBXStoreReader }

constructor TDBXStoreReader.Create(Driver: TDBXDriver; Qry: OQL);
var
  SQL: string;
begin
  inherited Create;
  FDriver := Driver;
  SQL := Qry.ToSQL;
  Logger.Trace('DDO-SQL: ' + SQL);
  FDriver.FConnection.Execute(Qry.ToSQL, nil, @FDataset);
  Reset;
end;

destructor TDBXStoreReader.Destroy;
begin
  FDataset.Free;
  inherited;
end;

procedure TDBXStoreReader.Reset;
begin
  FDataset.First;
  FReturnsFirst := True;
end;

function TDBXStoreReader.MoveNext: Boolean;
begin
  if FReturnsFirst then
    FReturnsFirst := False
  else
    FDataset.Next;

  Result := not FDataset.Eof;
end;

function TDBXStoreReader.ReadValue(Name: string): TValue;
var
  Field: TField;
begin
  Field := FDataset.FindField(Name);
  if not Assigned(Field) then
    Result := TValue.Empty
  else
    Result := TValue.FromVariant(Field.Value);
end;


end.
