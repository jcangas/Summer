unit SummerFW.DDO.StoreInfo;

interface
uses SummerFW.DDO.State;

type
  PPStoreInfo = ^PStoreInfo;
  PStoreInfo = ^TStoreInfo;

  TStoreInfo = record
  private
    FState: TStoreStateClass;
    class function GetFieldAddress(AObject: TObject): PPStoreInfo;
      static; inline;
  public
    class function GetFor(AObject: TObject): PStoreInfo; static;
    class function Create: PStoreInfo; static;
    class procedure Destroy(AObject: TObject); overload; static;

    class function GetID(Obj: TObject): Int64; static;
    class function HumanClass(Obj: TObject): string; static;
    class function HumanKey(Obj: TObject): string; static;
    class function HumanPath(Obj: TObject): string; static;
    class function IDKey(Obj: TObject): string; static;

    class function IsTransient(Obj: TObject): Boolean; static;
    class function IsStored(Obj: TObject): Boolean; static;
    class function IsNew(Obj: TObject): Boolean; static;
    class function IsUpdated(Obj: TObject): Boolean; static;
    class function IsDeleted(Obj: TObject): Boolean; static;
    class function IsDirty(Obj: TObject): Boolean; static;

    class function MakeStoredClean(Obj: TObject): TObject; static;
    class function MakeStored(Obj: TObject): TObject; static;
    class function MakeUpdated(Obj: TObject): TObject; static;
    class function MakeDeleted(Obj: TObject): TObject; static;
    class function MakeSaved(Obj: TObject): TObject; static;

    procedure Destroy; overload;
    property State: TStoreStateClass read FState write FState;
  end;


implementation
uses SummerFW.DDO.CallBack;

type
  TInt64Method = function: Int64 of object;
  TStringMethod = function: string of object;

function CallStringMethod(Obj: TObject; Name: string): string;
var
  M: TMethod;
begin
  M.Data := Obj;
  M.Code := Obj.MethodAddress(Name);
  if M.Code = nil then
    Result := ''
  else
    Result := TStringMethod(M);
end;

function CallInt64Method(Obj: TObject; Name: string): Int64;
var
  M: TMethod;
begin
  M.Data := Obj;
  M.Code := Obj.MethodAddress(Name);
  if M.Code = nil then
    Result := -1
  else
    Result := TInt64Method(M);
end;

function InterlockedCompareExchangePointer(var Destination: Pointer;
  Exchange: Pointer; Comparand: Pointer): Pointer; stdcall;
begin
  Result := Destination;
  if Result = Comparand then
    Destination := Exchange;
end;

{ TStoreInfo }

class function TStoreInfo.Create: PStoreInfo;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
  Result.FState := Transient;
end;

class procedure TStoreInfo.Destroy(AObject: TObject);
var
  StoreInfoFld: PPStoreInfo;
  StoreInfo: PStoreInfo;
begin
  StoreInfoFld := GetFieldAddress(AObject);
  if StoreInfoFld^ = nil then
    Exit;
  StoreInfo := StoreInfoFld^;
  StoreInfoFld^ := nil;
  StoreInfo.Destroy;
end;

procedure TStoreInfo.Destroy;
begin
  Self.FState := nil;
  Dispose(@Self);
end;

class function TStoreInfo.GetFieldAddress(AObject: TObject): PPStoreInfo;
begin
  // Copied from TMonitor.GetFieldAddress(Obj: TObject)
  Result := PPStoreInfo(NativeInt(AObject) + AObject.InstanceSize - hfFieldSize
    + hfMonitorOffset);
end;

class function TStoreInfo.GetFor(AObject: TObject): PStoreInfo;
var
  StoreInfoField: PPStoreInfo;
  StoreInfo: PStoreInfo;
begin
  StoreInfoField := GetFieldAddress(AObject);
  Result := StoreInfoField^;
  if Result = nil then begin
    StoreInfo := TStoreInfo.Create;
    Result := InterlockedCompareExchangePointer(Pointer(StoreInfoField^),
      StoreInfo, nil);
    if Result = nil then
      Result := StoreInfo
    else
      Dispose(StoreInfo);
  end;
end;

class function TStoreInfo.GetID(Obj: TObject): Int64;
begin
  Result := CallInt64Method(Obj, 'GetID')
end;

class function TStoreInfo.IDKey(Obj: TObject): string;
begin
  Result := CallStringMethod(Obj, 'IDKey')
end;

class function TStoreInfo.HumanKey(Obj: TObject): string;
begin
  Result := CallStringMethod(Obj, 'HumanKey')
end;

class function TStoreInfo.HumanClass(Obj: TObject): string;
begin
  Result := Obj.ClassName;
end;

class function TStoreInfo.HumanPath(Obj: TObject): string;
begin
  Result := HumanClass(Obj) + ':' + HumanKey(Obj);
end;

class function TStoreInfo.IsDeleted(Obj: TObject): Boolean;
begin
  Result := GetFor(Obj).State.IsDeleted;
end;

class function TStoreInfo.IsDirty(Obj: TObject): Boolean;
begin
  with GetFor(Obj).State do
    Result := IsUpdated or IsNew or IsDeleted;
end;

class function TStoreInfo.IsNew(Obj: TObject): Boolean;
begin
  Result := GetFor(Obj).State.IsNew;
end;

class function TStoreInfo.IsStored(Obj: TObject): Boolean;
begin
  Result := GetFor(Obj).State.InheritsFrom(Stored)
end;

class function TStoreInfo.IsTransient(Obj: TObject): Boolean;
begin
  Result := GetFor(Obj).State.InheritsFrom(Transient)
end;

class function TStoreInfo.IsUpdated(Obj: TObject): Boolean;
begin
  Result := GetFor(Obj).State.IsUpdated;
end;

class function TStoreInfo.MakeDeleted(Obj: TObject): TObject;
begin
  Result := Obj;
  if IsDeleted(Obj) then Exit;
  TCallback.CallBeforeDelete(Obj);
  with GetFor(Obj)^ do
    State := State.MakeDeleted;
  TCallback.CallAfterDelete(Obj);
end;

class function TStoreInfo.MakeSaved(Obj: TObject): TObject;
begin
  Result := Obj;
  with GetFor(Obj)^ do
    State := State.MakeSaved;
end;

class function TStoreInfo.MakeStoredClean(Obj: TObject): TObject;
begin
  Result := Obj;
  with GetFor(Obj)^ do
    State := State.MakeStoredClean;
end;

class function TStoreInfo.MakeStored(Obj: TObject): TObject;
begin
  Result := Obj;
  if IsStored(Obj) then Exit;
  TCallback.CallBeforeNew(Obj);
  with GetFor(Obj)^ do
    State := State.MakeStored;
  TCallback.CallAfterNew(Obj);
end;

class function TStoreInfo.MakeUpdated(Obj: TObject): TObject;
begin
  Result := Obj;
  TCallback.CallBeforeUpdate(Obj);
  with GetFor(Obj)^ do
    State := State.MakeUpdated;
  TCallback.CallAfterUpdate(Obj);
end;

end.
