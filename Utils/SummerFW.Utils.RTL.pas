unit SummerFW.Utils.RTL;

interface
uses SysUtils, Classes, Controls;

type
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

  DynA = class
    class function From<T>(Items: array of T): TArray<T>;
  end;

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

class function DynA.From<T>(Items: array of T): TArray<T>;
var
  idx: Integer;
  x: T;
begin
  Setlength(Result, Length(Items));
  idx := 0;
  for x in Items do begin
    Result[idx] := Items[idx];
    Inc(idx);
  end;
end;

end.
