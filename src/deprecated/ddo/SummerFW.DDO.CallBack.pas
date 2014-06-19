unit SummerFW.DDO.CallBack;

interface
uses Generics.Collections;

type
  TCallback = class
  private type
    TCallbackProc = reference to procedure(Observer: TCallback);
    class var Registry: TObjectList<TCallback>;
    class procedure CallBack(Obj: TObject; Proc: TCallbackProc);
  protected
    // Usar Classname porque las classes estan falseadas por el Interceptor
    // if Observed.ClassName = Obj.ClassType.ClassName then ...
    function Accept(Obj: TObject): boolean; virtual;
  public
    class procedure CallBeforeNew(Obj: TObject);
    class procedure CallAfterNew(Obj: TObject);
    class procedure CallBeforeUpdate(Obj: TObject);
    class procedure CallAfterUpdate(Obj: TObject);
    class procedure CallBeforeDelete(Obj: TObject);
    class procedure CallAfterDelete(Obj: TObject);
    class procedure CallBeforeSave(Obj: TObject);
    class procedure CallAfterSave(Obj: TObject);
  public
    destructor Destroy; override;
    procedure Register;
    procedure BeforeNew(Obj: TObject); virtual;
    procedure AfterNew(Obj: TObject); virtual;
    procedure BeforeUpdate(Obj: TObject); virtual;
    procedure AfterUpdate(Obj: TObject); virtual;
    procedure BeforeDelete(Obj: TObject); virtual;
    procedure AfterDelete(Obj: TObject); virtual;
    procedure BeforeSave(Obj: TObject); virtual;
    procedure AfterSave(Obj: TObject); virtual;
  end;

implementation

{ TCallback }
class procedure TCallback.CallBack(Obj: TObject; Proc: TCallbackProc);
var
  Observer: TCallback;
begin
  for Observer in Registry do begin
    if Observer.Accept(Obj) then
      Proc(Observer);
  end;
end;

class procedure TCallback.CallBeforeDelete(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.BeforeDelete
    (Obj); end);
end;

class procedure TCallback.CallBeforeNew(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.BeforeNew
    (Obj); end);
end;

class procedure TCallback.CallBeforeSave(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.BeforeSave
    (Obj); end);
end;

class procedure TCallback.CallBeforeUpdate(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.AfterUpdate
    (Obj); end);
end;

class procedure TCallback.CallAfterDelete(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.AfterDelete
    (Obj); end);
end;

class procedure TCallback.CallAfterNew(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.AfterNew
    (Obj); end);
end;

class procedure TCallback.CallAfterSave(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.AfterSave
    (Obj); end);
end;

class procedure TCallback.CallAfterUpdate(Obj: TObject);
begin
  CallBack(Obj, procedure(Observer: TCallback)begin Observer.BeforeUpdate
    (Obj); end);
end;

function TCallback.Accept(Obj: TObject): boolean;
begin
  Result := True;
end;

procedure TCallback.AfterDelete(Obj: TObject);
begin
end;

procedure TCallback.AfterNew(Obj: TObject);
begin
end;

procedure TCallback.AfterSave(Obj: TObject);
begin
end;

procedure TCallback.AfterUpdate(Obj: TObject);
begin
end;

procedure TCallback.BeforeDelete(Obj: TObject);
begin
end;

procedure TCallback.BeforeNew(Obj: TObject);
begin
end;

procedure TCallback.BeforeSave(Obj: TObject);
begin
end;

procedure TCallback.BeforeUpdate(Obj: TObject);
begin
end;

destructor TCallback.Destroy;
begin
  if Registry.Contains(Self) then
    Registry.Extract(Self);
  inherited;
end;

procedure TCallback.Register;
begin
  Registry.Add(Self);
end;

initialization

TCallback.Registry := TObjectList<TCallback>.Create;

finalization

TCallback.Registry.Free;

end.
