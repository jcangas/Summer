unit SummerFW.DDD.Query;

interface

uses
  Data.DB,
  SummerFW.DDD.Utils;

type

  TFieldType = Data.DB.TFieldType;
  TSQLParams = TArray<variant>;
  TSQLTypes = TArray<TFieldType>;

  TCriteria = record
    Columns: TArray<string>;
    function ToSQL: string;
  end;

  TFrom = record
    TableName: string;
    function ToSQL: string;
  end;

  TTake = record
    Value: Integer;
    function ToSQL: string;
  end;

  TSkip = record
    Value: Integer;
    function ToSQL: string;
  end;

  TColumnOrder = record
    Ascending: Boolean;
    Column: string;
    function ToSQL: string;
  end;

  TOrderBy = record
    Orders: TArray<TColumnOrder>;
    function ToSQL: string;
  end;

  TQuery = record
  private
    FFrom: TFrom;
    FWhere: TCriteria;
    FTake: TTake;
    FSkip: TSkip;
    FOrderBy: TOrderBy;
    FParams: TSQLParams;
    FParamNames: TArray<string>;
    FParamTypes: TSQLTypes;
  public
    constructor From(const TableName: string);
    function Take(const Value: Integer): TQuery;
    function Skip(const Value: Integer): TQuery;
    function OrderBy(Orders: TArray<TColumnOrder>): TQuery;
    function Where(Columns: TArray<string>; Params: TSQLParams): TQuery;
    property Params: TSQLParams
      read FParams
      write FParams;
    property ParamNames: TArray<string>
      read FParamNames
      write FParamNames;
    property ParamTypes: TSQLTypes
      read FParamTypes
      write FParamTypes;
    function ToSQL: string;
  end;

implementation

uses
  System.SysUtils;

{ TCriteria }

function TCriteria.ToSQL: string;
var
  idx: Integer;
begin
  if Length(Columns) = 0 then
    Exit('');
  Result := 'WHERE' + sLineBreak;
  for idx := low(Columns) to high(Columns) do begin
    Result := Result + Format('(%s = ?)', [Columns[idx]]);
    if idx < high(Columns) then
      Result := Result + sLineBreak + 'AND ';
  end;
  Result := Result + sLineBreak;
end;

{ TQuery }

constructor TQuery.From(const TableName: string);
begin
  FFrom.TableName := TableName;
  FTake.Value := 0;
  FSkip.Value := 0;
end;

function TQuery.OrderBy(Orders: TArray<TColumnOrder>): TQuery;
begin
  FOrderBy.Orders := Orders;
  Result := Self;
end;

function TQuery.Skip(const Value: Integer): TQuery;
begin
  FSkip.Value := Value;
  Result := Self;
end;

function TQuery.Take(const Value: Integer): TQuery;
begin
  FTake.Value := Value;
  Result := Self;
end;

function TQuery.Where(Columns: TArray<string>; Params: TSQLParams): TQuery;
begin
  FWhere.Columns := Columns;
  FParamNames := Columns;
  FParams := Params;
  SetLength(FParamTypes, Length(FParams));
  Result := Self;
end;

function TQuery.ToSQL: string;
begin
  Result := 'SELECT *' + sLineBreak + FFrom.ToSQL + FWhere.ToSQL + FTake.ToSQL + FSkip.ToSQL + FOrderBy.ToSQL;
end;

{ TFrom }

function TFrom.ToSQL: string;
begin
  if TableName.IsEmpty then
    Exit('');
  Result := Format('FROM %s', [TableName]) + sLineBreak;
end;

{ TTake }

function TTake.ToSQL: string;
begin
  if Value = 0 then
    Exit('');
  Result := Format('LIMIT %d', [Value]);
end;

{ TSkip }

function TSkip.ToSQL: string;
begin
  if Value = 0 then
    Exit('');
  Result := Format('OFFSET %d', [Value]);
end;

{ TColumnOrder }

function TColumnOrder.ToSQL: string;
const
  Mode: array [Boolean] of string = ('DESC', 'ASC');
begin
  Result := Format('%s %s', [Column, Mode[Ascending]]);
end;

{ TOrderBy }

function TOrderBy.ToSQL: string;
var
  Connector: string;
  Order: TColumnOrder;
begin
  if Length(Orders) = 0 then Exit;
  Connector := '';
  Result := 'ORDER BY ';
  for Order in Orders do begin
    Result := Result + Connector + Order.ToSQL;
    if Connector.IsEmpty then
      Connector := ', ';
  end;
  Result := Result + sLineBreak;
end;

end.
