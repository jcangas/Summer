unit SummerFW.Utils.RTL;

interface
uses SysUtils, Classes, Controls;

type
  TEnumerated = record
  strict private
    FCode: Integer;
    FID: string;
  public
    class operator Equal(A: TEnumerated; B: TEnumerated): Boolean;
    class operator NotEqual(A: TEnumerated; B: TEnumerated): Boolean;
    class operator GreaterThan(A: TEnumerated; B: TEnumerated): Boolean;
    class operator GreaterThanOrEqual(A: TEnumerated; B: TEnumerated): Boolean;
    class operator LessThan(A: TEnumerated; B: TEnumerated): Boolean;
    class operator LessThanOrEqual(A: TEnumerated; B: TEnumerated): Boolean;
    class operator Implicit(Enum: TEnumerated): string;
    class operator Implicit(Enum: TEnumerated): Integer;
    function ToString: string;
    property Code: Integer read FCode;
    property ID: string read FID;
  end;

  Sync = class
  public
    class procedure Lock(obj: TObject; P: TProc);overload;static;
    class function Lock<T>(obj: TObject; F: TFunc<T>): T;overload;static;
  end;

  TUnprotectControl = class(Controls.TControl)
  public
    property Caption;
    property Text;
  end;


  TFreeNotifier = class(TComponent)
  private
    FOnfree: TNotifyEvent;
  published
  public
    constructor Create(AOwner: TObject); reintroduce;
    property OnFree: TNotifyEvent read FOnfree write FOnFree;
    destructor Destroy; override;
  end;


function &Set(Values: array of TEnumerated): TIntegerSet;
function InterlockedIncrement(var Addend: Integer): Integer;
function InterlockedDecrement(var Addend: Integer): Integer;

implementation

// copied from System Unit
function InterlockedAdd(var Addend: Integer; Increment: Integer): Integer;
asm
      MOV   ECX,EAX
      MOV   EAX,EDX
 LOCK XADD  [ECX],EAX
      ADD   EAX,EDX
end;

function InterlockedIncrement(var Addend: Integer): Integer;
asm
      MOV   EDX,1
      JMP   InterlockedAdd
end;

function InterlockedDecrement(var Addend: Integer): Integer;
asm
      MOV   EDX,-1
      JMP   InterlockedAdd
end;

{ Sync }

class procedure Sync.Lock(obj: TObject; P: TProc);
begin
  TMonitor.Enter(obj);
  try
    P;
  finally
    TMonitor.Exit(obj);
  end;
end;

class function Sync.Lock<T>(obj: TObject; F: TFunc<T>): T;
begin
  TMonitor.Enter(obj);
  try
    Result := F;
  finally
    TMonitor.Exit(obj);
  end;
end;


{ TFreeNotifier }

constructor TFreeNotifier.Create(AOwner: TObject);
begin
  inherited Create(AOwner as TComponent);
end;

destructor TFreeNotifier.Destroy;
begin
  if Assigned(FOnFree) then
    FOnfree(Self);
  inherited;
end;

{ TEnumerated}

class operator TEnumerated.Equal(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode = B.FCode;
end;

class operator TEnumerated.NotEqual(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode <> B.FCode;
end;

function TEnumerated.ToString: string;
begin
  Result := FID;
end;

class operator TEnumerated.GreaterThan(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode > B.FCode;
end;

class operator TEnumerated.GreaterThanOrEqual(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode >= B.FCode;
end;

class operator TEnumerated.LessThan(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode < B.FCode;
end;

class operator TEnumerated.LessThanOrEqual(A, B: TEnumerated): Boolean;
begin
  Result := A.FCode <= B.FCode;
end;

class operator TEnumerated.Implicit(Enum: TEnumerated): Integer;
begin
  Result := Enum.FCode;
end;

class operator TEnumerated.Implicit(Enum: TEnumerated): string;
begin
  Result := Enum.ToString;
end;

function &Set(Values: array of TEnumerated): TIntegerSet;
var
  V: TEnumerated;
begin
  Result := [];
  for V in Values do
    Include(Result, Ord(V));
end;

end.
