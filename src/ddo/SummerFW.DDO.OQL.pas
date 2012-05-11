unit SummerFW.DDO.OQL;

interface

uses Rtti, SysUtils, Generics.Collections;

type

  TToken = class;
  OQLTokenClass = class of TToken;
  OQLPredicate = TFunc<TValue, TToken, Boolean>;
  TTokenFormater = reference to function(Token: TToken; IsLast: Boolean): string;
  TToken = class(TObjectList<TToken>)
  private
  protected
    procedure Append(var SQL: string; Text: string);overload;
    procedure Append(var SQL: string; Tk: TToken; Tail: string = '');overload;
    procedure Append(var SQL: string; TkClass: OQLTokenClass; Connector: string = '');overload;
    procedure Append(var SQL: string; TkClasses: array of OQLTokenClass);overload;
  public
    constructor Create(Parent: TToken = nil);
    function FindBy(Criteria: OQLPredicate; Args: TValue): TToken;
    function ToSQL: string; virtual; abstract;
    function MoveTo(Dest: TToken): TToken;
    function MoveFrom(Src: TToken): TToken;
    procedure Inject(var SQL: string; TkClass: OQLTokenClass; Proc: TTokenFormater);
  end;

  OQL = class(TToken)
  type
    TkFrom = class(TToken)
    private
      FTableName: string;
      FAlias: string;
    public
      constructor Create(const TableName, Alias: string);
      function ToSQL: string; override;
      property TableName: string read FTableName;
      property Alias: string read FAlias;
    end;

    TkUpdSet = class(TToken)
    private
      FTableName: string;
    public
      constructor Create(const TableName: string);
      function ToSQL: string; override;
      property TableName: string read FTableName;
    end;

    TkInto = class(TkUpdSet)
    public
      function ToSQL: string; override;
    end;

    TkColumnDef = class(TToken)
    private
      FExpr: string;
      FAlias: string;
    public
      constructor Create(Expr: string; Name: string = '');
      function ToSQL: string; override;
      property Expr: string read FExpr;
      property Alias: string read FAlias;
    end;

    TkBinaryExpr = class(TToken)
    private
      FColumn: string;
      FOperation: string;
      FValue: TValue;
    public
      constructor Create(Column: string; Operation: string; Value: TValue);overload;
      function ValueToSQL: string;
      function ToSQL: string; override;
      property Column: string read FColumn;
      property Operation: string read FOperation;
      property Value: TValue read FValue;
    end;

    TkLetExpr = class(TkBinaryExpr);
    TkLetExprList = class(TkLetExpr)
    public
      constructor Create;
      function ToSQL: string; override;
    end;
    TkBoolExpr = class(TkBinaryExpr)
    public
      function ToSQL: string; override;
    end;

    TkWhere = class(TToken)
      FExpr: OQL.TkBoolExpr;
    public
      constructor Create(const Value: OQL.TkBoolExpr);
      destructor Destroy;override;
      function ToSQL: string; override;
      property Expr: OQL.TkBoolExpr read FExpr;
    end;

    TkTake = class(TToken)
      FValue: Cardinal;
    public
      constructor Create(const Value: Cardinal);
      function ToSQL: string; override;
      property Value: Cardinal read FValue;
    end;
  public
    class function ByClass(TokenClass: TValue; F: TToken): Boolean;
    class function EQ(Column: string; Value: TValue): OQL.TkBoolExpr;
    class function Let(Column: string; Value: TValue): OQL.TkLetExpr;
    function ToSQL: string; override;
    function From(const TableName: string; const Alias: string = ''): OQL;

    class function Raw(Expr: string): OQL;
    function Select: OQL;
    function Count: OQL;
    function Take(Value: Cardinal): OQL;
    function Where(Expr: OQL.TkBoolExpr): OQL;
    function Insert(Expr: TkLetExprList): OQL;
    function Update(Expr: TkLetExprList): OQL;
    function Delete: OQL;
  end;

  TkRawSQL = class(OQL)
  private
    FValue: string;
  public
    constructor Create(const Value: string);
    function ToSQL: string; override;
  end;

  TkSelect = class(OQL)
  public
    function ToSQL: string; override;
  end;

  TkUpdate = class(OQL)
  public
    constructor Create(const LetExpr: OQL.TkLetExprList);
    function ToSQL: string; override;
  end;

  TkInsert = class(TkUpdate)
  public
    function ToSQL: string; override;
  end;

  TkDelete = class(OQL)
  private
  public
    function ToSQL: string; override;
  end;

  IQueryable<T: class, constructor> = interface
    function SELECT: IEnumerable<T>;
    function WHERE(Expr: OQL.TkBoolExpr): IQueryable<T>;
    function FIRST: T;
    function COUNT: Int64;
    function INSERT(SetExpr: OQL.TkLetExprList): Integer;
    function UPDATE(SetExpr: OQL.TkLetExprList): Integer;
    function DELETE: Integer;
  end;

implementation

uses TypInfo;

{ TToken}

constructor TToken.Create(Parent: TToken);
begin
  inherited Create;
  if Assigned(Parent) then
    Parent.Add(Self);
end;

function TToken.FindBy(Criteria: OQLPredicate; Args: TValue): TToken;
begin
  for Result in Self do
    if Criteria(Args, Result) then
      Exit;
  Result := nil;
end;

function TToken.MoveTo(Dest: TToken): TToken;
begin
  Dest.AddRange(Self.ToArray);
  Self.OwnsObjects := False;
  Self.Clear;
  Self.OwnsObjects := True;
  Result := Self;
end;

function TToken.MoveFrom(Src: TToken): TToken;
begin
  Src.MoveTo(Self);
  Result := Self;
end;

procedure TToken.Append(var SQL: string; Text: string);
begin
  SQL := SQL + ' ' + Text;
end;

procedure TToken.Append(var SQL: string; Tk: TToken; Tail: string = '');
begin
  if Tk = nil then Exit;
  Append(SQL, Tk.ToSQL + Tail);
end;

procedure TToken.Inject(var SQL: string; TkClass: OQLTokenClass; Proc: TTokenFormater);
var
  Token: TToken;
begin
  for Token in Self do begin
    if not OQL.ByClass(TkClass, Token) then Continue;
    Append(SQL, Proc(Token, Self.Last = Token));
  end;
end;

procedure TToken.Append(var SQL: string; TkClass: OQLTokenClass;
  Connector: string = '');
var
  Token: TToken;
  Modified: Boolean;
begin
  Modified := False;
  for Token in Self do begin
    if not OQL.ByClass(TkClass, Token) then Continue;
    Append(SQL, Token, Connector);
    Modified := True;
  end;
  if Modified and (Connector <> '') then
    System.Delete(SQL, Length(SQL) - Length(Connector) + 1, Length(Connector));
end;

procedure TToken.Append(var SQL: string; TkClasses: array of OQLTokenClass);
var
  Tk: OQLTokenClass;
begin
  for Tk in TkClasses do
    Append(SQL, Tk);
end;


{ OQL }

function OQL.From(const TableName, Alias: string): OQL;
begin
  Result := Self;
  Add(TkFrom.Create(TableName, Alias));
end;

class function OQL.EQ(Column: string; Value: TValue): OQL.TkBoolExpr;
begin
  Result := TkBoolExpr.Create(Column, '=', Value);
end;

class function OQL.Let(Column: string; Value: TValue): OQL.TkLetExpr;
begin
  Result := TkLetExpr.Create(Column, '=', Value);
end;

class function OQL.Raw(Expr: string): OQL;
begin
  Result := TkRawSQL.Create(Expr);
end;

function OQL.Select: OQL;
var
  Tk: TkSelect;
begin
  Result := Self;
  Tk := TkSelect.Create;
  Tk.MoveFrom(Self);
  Tk.Add(TkColumnDef.Create('*'));
  Add(Tk);
end;

function OQL.Count: OQL;
var
  Tk: TkSelect;
begin
  Result := Self;
  Tk := TkSelect.Create;
  Tk.MoveFrom(Self);
  Tk.Add(TkColumnDef.Create('Count(*)'));
  Add(Tk);
end;

function OQL.Insert(Expr: TkLetExprList): OQL;
var
  Tk: TkInsert;
  Found: TkFrom;
begin
  Result := Self;
  Tk := TkInsert.Create(Expr);
  Tk.MoveFrom(Self);
  Found := Tk.FindBy(ByClass, TkFrom) as TkFrom;
  Tk.Add(TkInto.Create(Found.TableName));
  Add(Tk);
end;

function OQL.Update(Expr: TkLetExprList): OQL;
var
  Tk: TkUpdate;
  Found: TkFrom;
begin
  Result := Self;
  Tk := TkUpdate.Create(Expr);
  Tk.MoveFrom(Self);
  Found := Tk.FindBy(ByClass, TkFrom) as TkFrom;
  Tk.Add(TkUpdSet.Create(Found.TableName));
  Tk.Remove(Found);
  Add(Tk);
end;

function OQL.Delete: OQL;
var
  Tk: TkDelete;
begin
  Result := Self;
  Tk := TkDelete.Create;
  Tk.MoveFrom(Self);
  Add(Tk);
end;

function OQL.Where(Expr: TkBoolExpr): OQL;
begin
  Result := Self;
  Add(TkWhere.Create(Expr));
end;

function OQL.Take(Value: Cardinal): OQL;
begin
  Result := Self;
  Add(TkTake.Create(Value));
end;

function OQL.ToSQL: string;
var
  Tk: TToken;
begin
  Result := '';
  for Tk in Self do
    Append(Result, Tk);
end;

class function OQL.ByClass(TokenClass: TValue; F: TToken): Boolean;
begin
  Result := F.ClassInfo = TokenClass.AsClass.ClassInfo;
end;

{ OQL.TkFrom}

constructor OQL.TkFrom.Create(const TableName, Alias: string);
begin
  inherited Create;
  FTableName := TableName;
  FAlias := Alias;
end;

{ OQL.TkTake}

constructor OQL.TkTake.Create(const Value: Cardinal);
begin
  inherited Create;
  FValue := Value;
end;

function OQL.TkTake.ToSQL: string;
begin
  Result := Trim(Format('FIRST %d', [Value]));
end;

{ OQL.TkColumnDef }

constructor OQL.TkColumnDef.Create(Expr, Name: string);
begin
  inherited Create;
  FExpr := Expr;
  FAlias := Alias;
end;

function OQL.TkColumnDef.ToSQL: string;
begin
  Result := Trim(Format('%s %s', [Expr, Alias]));
end;

{ OQL.TkWhere }

constructor OQL.TkWhere.Create(const Value: TkBoolExpr);
begin
  inherited Create;
  FExpr := Value;
end;

destructor OQL.TkWhere.Destroy;
begin
  FExpr.Free;
  inherited;
end;

function OQL.TkWhere.ToSQL: string;
begin
  Result := Trim(Format('WHERE %s', [Expr.ToSQL]));
end;

{ OQL.TkBinaryExpr }

constructor OQL.TkBinaryExpr.Create(Column, Operation: string; Value: TValue);
begin
  inherited Create;
  FColumn := Column;
  FOperation := Operation;
  FValue := Value;
end;

function OQL.TkFrom.ToSQL: string;
begin
  Result := Trim(Format('FROM %s %s', [TableName, Alias]));
end;

function OQL.TkBinaryExpr.ToSQL: string;
begin
  Result := Trim(Format('%s %s %s', [Column, Operation, ValueToSQL]));
end;

function OQL.TkBinaryExpr.ValueToSQL: string;
var
  ValueMask: string;
begin
  ValueMask := '%s';
  if Value.Kind in [tkChar, tkString, tkWChar, tkLString, tkWString,  tkUString] then
    ValueMask := QuotedStr(ValueMask);
  Result := Format(ValueMask, [Value.ToString]);
end;

{ OQL.TkUpdSet }

constructor OQL.TkUpdSet.Create(const TableName: string);
begin
  inherited Create;
  FTableName := TableName;
end;

function OQL.TkUpdSet.ToSQL: string;
begin
  Result := Trim(Format('%s SET', [TableName]));
end;

{ OQL.TkInto }

function OQL.TkInto.ToSQL: string;
begin
  Result := Trim(Format('INTO %s', [TableName]));
end;

{ OQL.TkBoolExpr }

function OQL.TkBoolExpr.ToSQL: string;
begin
  Result := Trim(Format('(%s)', [inherited ToSQL]));
end;

{ OQL.TkLetExprList }

constructor OQL.TkLetExprList.Create;
begin
  inherited Create;
end;

function OQL.TkLetExprList.ToSQL: string;
begin
  Result := '';
  Append(Result, TkLetExpr, ', ');
end;

{ TkSelect }

function TkSelect.ToSQL: string;
begin
  Result := 'SELECT';
  Append(Result, [TkTake, TkColumnDef, TkFrom, TkWhere]);
end;


{ TkUpdate }

constructor TkUpdate.Create(const LetExpr: OQL.TkLetExprList);
begin
  inherited Create;
  Add(LetExpr);
end;

function TkUpdate.ToSQL: string;
begin
  Result := 'UPDATE';
  Append(Result, [TkUpdSet, TkLetExprList, TkWhere]);
end;

{ TkInsert }

function TkInsert.ToSQL: string;
var
  Found: TkLetExprList;
begin
  Result := 'INSERT';
  Append(Result, [TkInto]);
  Append(Result, '(');
  Found := FindBy(ByClass, TkLetExprList) as TkLetExprList;
  Found.Inject(Result, TkLetExpr,
    function (Tk: TToken; IsLast: Boolean): string
    const
      Conector: array[Boolean] of string = (', ','');
    begin
      Result := TkLetExpr(Tk).Column + Conector[IsLast];
    end
  );
  Append(Result, ') VALUES (');
  Found.Inject(Result, TkLetExpr,
    function (Tk: TToken; IsLast: Boolean): string
    const
      Conector: array[Boolean] of string = (', ','');
    begin
      Result := TkLetExpr(Tk).ValueToSQL + Conector[IsLast];
    end
  );
  Append(Result, ')');
end;

{ TkDelete }

function TkDelete.ToSQL: string;
begin
  Result := 'DELETE';
  Append(Result, [TkFrom, TkWhere]);
end;

{ TkRawSQL }

constructor TkRawSQL.Create(const Value: string);
begin
  inherited Create;
  FValue := Value;
end;

function TkRawSQL.ToSQL: string;
begin
  Result := FValue;
end;

end.
