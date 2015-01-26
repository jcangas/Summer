{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit SummerFW.Utils.RTL;

interface
uses SysUtils, Classes;

type
  TOpenEnum = record
  type
    Code = Integer;
    CodeSet = array of Code;
  public  // yes! in order we can declare as initialized const
    FValue: Code;
    FID: string;
  public
    constructor Create(AValue: Code; AID: string);
    class function &Set(Values: array of TOpenEnum): CodeSet;static;
    class operator Equal(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator NotEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator GreaterThan(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator GreaterThanOrEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator LessThan(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator LessThanOrEqual(A: TOpenEnum; B: TOpenEnum): Boolean;
    class operator Implicit(Enum: TOpenEnum): string;
    class operator Implicit(Enum: TOpenEnum): Integer;
    function ToString: string;
    function MemberOf(Codes: CodeSet): Boolean;
    property Value: Code read FValue;
    property ID: string read FID;
  end;

  TFreeNotifier = class(TComponent)
  private
    FOnFreeNotification: TProc<TComponent>;
    FOnDestroy: TProc<TComponent>;
  protected
    procedure DoOnDestroy;virtual;
    procedure DoOnFree(Sender: TComponent); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;
    property OnFreeNotification: TProc<TComponent> read FOnFreeNotification write FOnFreeNotification;
    property OnDestroy: TProc<TComponent> read FOnDestroy write FOnDestroy;
  end;



implementation


{ TFreeNotifier }

destructor TFreeNotifier.Destroy;
begin
  DoOnDestroy;
  FOnFreeNotification := nil;
  FOnDestroy := nil;
  inherited;
end;

procedure TFreeNotifier.DoOnFree(Sender: TComponent);
begin
  if Assigned(FOnFreeNotification) then
    FOnFreeNotification(Self);
end;

procedure TFreeNotifier.DoOnDestroy;
begin
  if Assigned(FOnDestroy) then
    FOnDestroy(Self);
end;

procedure TFreeNotifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
    DoOnFree(AComponent);
  inherited;
end;


{ TEnumerated}

class function TOpenEnum.&Set(Values: array of TOpenEnum): TOpenEnum.CodeSet;
var
  idx: Integer;
begin
  SetLength(Result, 1 + High(Values));
  for idx := Low(Values) to High(Values) do
    Result[idx] := Values[idx];
end;

constructor TOpenEnum.Create(AValue: TOpenEnum.Code; AID: string);
begin
  FValue := AValue;
  FID := AID;
end;

class operator TOpenEnum.Equal(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue = B.FValue;
end;

class operator TOpenEnum.NotEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue <> B.FValue;
end;

function TOpenEnum.ToString: string;
begin
  Result := FID;
end;

function TOpenEnum.MemberOf(Codes: TOpenEnum.CodeSet): Boolean;
var
  I: Integer;
begin
  for I := Low(Codes) to High(Codes) do
    if (Value = Codes[I]) then Exit(True);
  Result := False;
end;
class operator TOpenEnum.GreaterThan(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue > B.FValue;
end;

class operator TOpenEnum.GreaterThanOrEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue >= B.FValue;
end;

class operator TOpenEnum.LessThan(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue < B.FValue;
end;

class operator TOpenEnum.LessThanOrEqual(A, B: TOpenEnum): Boolean;
begin
  Result := A.FValue <= B.FValue;
end;

class operator TOpenEnum.Implicit(Enum: TOpenEnum): Integer;
begin
  Result := Enum.FValue;
end;

class operator TOpenEnum.Implicit(Enum: TOpenEnum): string;
begin
  Result := Enum.ToString;
end;

end.
