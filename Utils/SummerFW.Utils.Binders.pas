{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit SummerFW.Utils.Binders;

interface

uses
  Grids, SysUtils, Classes, RTTI, Controls, StdCtrls, ActnList,
  SummerFW.Utils.RTL, SummerFW.Utils.Collections;

type
  TUpdateModelEvent = procedure(Context: TRttiObject; Value: TValue) of object;

  TBinder = class abstract(TComponent)
  strict private
    FTarget: TComponent;
    FInUpdateTargetCount: Integer;
    FDelegated: TObject;
    FSavedEvents: TDictionary<string, TMethod>;
    FContext: TRttiObject;
  private
    FParam: TRttiObject;
  protected
    procedure SetDelegated(const Value: TObject);
    procedure SetTarget(Value: TComponent);
    procedure SetContext(Value: TRttiObject);
    procedure SetParam(Value: TRttiObject);
    procedure ReleaseEvents;
    procedure BeginUpdateTarget;
    procedure EndUpdateTarget;
    function InUpdateTarget: Boolean;
    procedure ReleaseEvent(EventName: string);
    procedure CaptureEvent(EventName: string);

    procedure Validate; virtual;
    procedure Bind; virtual;
    procedure UnBind; virtual;
    procedure DoUpdateTarget(Value: TValue); virtual;
    procedure DoUpdateModel(Value: TValue); virtual;

    procedure Notification(AComponent: TComponent;
        Operation: TOperation); override;
  public
    class function BindTo(ADelegated: TObject; ATarget: TComponent;
        AContext: TRttiObject = nil; AParam: TRttiObject = nil)
        : TBinder; overload;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanUpdateModel: Boolean; virtual;
    function CanUpdateTarget: Boolean; virtual;
    procedure UpdateTarget(Value: TValue);
    procedure UpdateModel(Value: TValue);
    property Delegated: TObject read FDelegated;
    property Target: TComponent read FTarget;
    property Context: TRttiObject read FContext;
    property Param: TRttiObject read FParam;
  end;

  TBinders = TObjectList<TBinder>;

  TCustomBinder<T: TComponent> = class(TBinder)
  protected
    procedure Validate; override;
  public
    function Client: T;
  end;

  TActionBinder = class(TCustomBinder<TAction>)
  protected
    procedure Bind; override;
  public
    function CanUpdateModel: Boolean; override;
    function CanUpdateTarget: Boolean; override;
  end;

  TPropertyBinder<T: TControl> = class(TCustomBinder<T>)
  strict private
    SavedMethod: TMethod;
  protected
    procedure Validate; override;
    function GetTargetValue: TValue; virtual; abstract;
    procedure SetTargetValue(Value: TValue); virtual; abstract;
    procedure OnTargetChange(Sender: TObject);

    function GetBindEventName: string; virtual; abstract;
    procedure Bind; override;
    procedure UnBind; override;
    procedure DoUpdateTarget(Value: TValue); override;
    procedure Notification(AComponent: TComponent;
        Operation: TOperation); override;
  public
    property BindEventName: string read GetBindEventName;
  end;

  TCheckBoxBinder = class(TPropertyBinder<TCheckBox>)
  private
  protected
    function GetBindEventName: string; override;
  public
    function GetTargetValue: TValue; override;
    procedure SetTargetValue(Value: TValue); override;
  end;

  TEditControlBinder = class(TPropertyBinder<TCustomEdit>)
  private
  protected
    function GetBindEventName: string; override;
  public
    function GetTargetValue: TValue; override;
    procedure SetTargetValue(Value: TValue); override;
  end;

  TComboBoxBinder = class(TPropertyBinder<TCustomComboBox>)
  private
  protected
    function GetBindEventName: string; override;
  public
    function GetTargetValue: TValue; override;
    procedure SetTargetValue(Value: TValue); override;
  end;

  TListBinder<T: TControl> = class(TCustomBinder<T>)
  strict private
    FModel: IObjectList;
  protected
    procedure Validate; override;
    function GetModel: IObjectList;
    function GetRType: TRttiType;
  public
    destructor Destroy; override;
    procedure DoUpdateTarget(Value: TValue); override;
    property Model: IObjectList read GetModel;
    property RType: TRttiType read GetRType;
  end;

implementation

uses
  TypInfo, Windows;
type
  TGridBinder = class(TListBinder<TStringGrid>)
  public
    procedure DoUpdateTarget(Value: TValue); override;
  end;
  { Binder }

constructor TBinder.Create(AOwner: TComponent);
begin
  inherited;
  FSavedEvents := TDictionary<string, TMethod>.Create;
end;

destructor TBinder.Destroy;
begin
  UnBind;
  FSavedEvents.Free;
  inherited;
end;

procedure TBinder.SetContext(Value: TRttiObject);
begin
  FContext := Value;
end;

procedure TBinder.SetParam(Value: TRttiObject);
begin
  FParam := Value;
end;

procedure TBinder.SetDelegated(const Value: TObject);
begin
  FDelegated := Value;
end;

procedure TBinder.SetTarget(Value: TComponent);
begin
  if FTarget = Value then
    Exit;
  FTarget := Value;
end;

procedure TBinder.Bind;
begin
  Validate;
end;

procedure TBinder.UnBind;
begin
  ReleaseEvents;
end;

procedure TBinder.UpdateModel(Value: TValue);
begin
  if CanUpdateModel then
    DoUpdateModel(Value);
end;

procedure TBinder.DoUpdateModel(Value: TValue);
var
  DelegatedMethod: TMethod;
begin
  DelegatedMethod.Code := Delegated.MethodAddress('OnUpdateModel');
  DelegatedMethod.Data := Delegated;
  if DelegatedMethod.Code = nil then
    Exit;
  TUpdateModelEvent(DelegatedMethod)(Context, Value);
end;

procedure TBinder.DoUpdateTarget(Value: TValue);
begin

end;

procedure TBinder.UpdateTarget(Value: TValue);
begin
  BeginUpdateTarget;
  try
    DoUpdateTarget(Value);
  finally
    EndUpdateTarget;
  end;
end;

procedure TBinder.BeginUpdateTarget;
begin
  Inc(FInUpdateTargetCount);
end;

function TBinder.InUpdateTarget: Boolean;
begin
  Result := FInUpdateTargetCount > 0;
end;

procedure TBinder.EndUpdateTarget;
begin
  Dec(FInUpdateTargetCount);
end;

procedure TBinder.Validate;
begin
  if not Assigned(Target) then
    raise EArgumentNilException.CreateFmt('%s requires a Target', [ClassName]);
end;

class function TBinder.BindTo(ADelegated: TObject; ATarget: TComponent;
    AContext, AParam: TRttiObject): TBinder;
begin
  Result := Create(ATarget);
  with Result do begin
    SetDelegated(ADelegated);
    SetTarget(ATarget);
    SetContext(AContext);
    SetParam(AParam);
    Bind;
  end;
end;

procedure TBinder.ReleaseEvent(EventName: string);
var
  SavedMethod: TMethod;
begin
  if not FSavedEvents.TryGetValue(EventName, SavedMethod) then
    Exit;
  if SavedMethod.Data <> nil then
    (TObject(SavedMethod.Data) as TComponent).RemoveFreeNotification(Self);
  FSavedEvents.Remove(EventName);
  SetMethodProp(Target, EventName, SavedMethod);
end;

function TBinder.CanUpdateModel: Boolean;
begin
  Result := True;
end;

function TBinder.CanUpdateTarget: Boolean;
begin
  Result := True;
end;

procedure TBinder.CaptureEvent(EventName: string);
var
  SavedMethod, TargetMethod: TMethod;
begin
  SavedMethod := GetMethodProp(Target, EventName);
  FSavedEvents.Add(EventName, SavedMethod);
  if SavedMethod.Data <> nil then
    (TObject(SavedMethod.Data) as TComponent).FreeNotification(Self);
  TargetMethod.Data := FDelegated;
  TargetMethod.Code := FDelegated.MethodAddress(Target.Name + EventName);
  SetMethodProp(Target, EventName, TargetMethod);
end;

procedure TBinder.ReleaseEvents;
var
  EventName: string;
begin
  for EventName in FSavedEvents.Keys do begin
    ReleaseEvent(EventName);
  end;
end;

procedure TBinder.Notification(AComponent: TComponent; Operation: TOperation);
var
  EventName: string;
  SavedMethod: TMethod;
  Affecteds: TStringList;
begin
  Affecteds := TStringList.Create;
  try
    if Operation = OpRemove then begin
      for EventName in FSavedEvents.Keys do begin
        SavedMethod := FSavedEvents[EventName];
        if SavedMethod.Data = AComponent then
          Affecteds.Add(EventName);
      end;
      for EventName in Affecteds do
        FSavedEvents.Remove(EventName);
    end;
  finally
    Affecteds.Free;
    inherited;
  end;
end;

{ TCustomBinder<T> }

function TCustomBinder<T>.Client: T;
begin
  Result := T(Target);
end;

procedure TCustomBinder<T>.Validate;
begin
  inherited;
  if not Target.InheritsFrom(T) then
    raise EInvalidCast.CreateFmt('Invalid Target class: %s.',
        [Target.ClassName]);
end;

{ TPropertyBinder<T> }

procedure TPropertyBinder<T>.OnTargetChange(Sender: TObject);
begin
  if InUpdateTarget then
    Exit;
  UpdateModel(GetTargetValue);
  if SavedMethod.Data = nil then
    Exit;
  TNotifyEvent(SavedMethod)(Sender);
end;

procedure TPropertyBinder<T>.Bind;
var
  OnTargetChangeMethod: TMethod;
begin
  inherited;
  SavedMethod := GetMethodProp(Target, BindEventName);
  TNotifyEvent(OnTargetChangeMethod) := OnTargetChange;
  SetMethodProp(Target, BindEventName, OnTargetChangeMethod);
  if SavedMethod.Data = nil then
    Exit;
  (TObject(SavedMethod.Data) as TComponent).FreeNotification(Self);
end;

procedure TPropertyBinder<T>.UnBind;
begin
  SetMethodProp(Target, BindEventName, SavedMethod);
end;

procedure TPropertyBinder<T>.Validate;
begin
  inherited;
  if Context = nil then
    raise EArgumentNilException.CreateFmt('%s requires context.', [ClassName]);
end;

procedure TPropertyBinder<T>.DoUpdateTarget(Value: TValue);
begin
  SetTargetValue(Value);
end;

procedure TPropertyBinder<T>.Notification(AComponent: TComponent;
    Operation: TOperation);
begin
  if Operation = OpRemove then begin
    if SavedMethod.Data = AComponent then begin
      SavedMethod.Code := nil;
      SavedMethod.Data := nil;
    end;
  end;
  inherited;
end;

{ TCheckBoxBinder }

function TCheckBoxBinder.GetBindEventName: string;
begin
  Result := 'OnClick';
end;

function TCheckBoxBinder.GetTargetValue: TValue;
begin
  Result := Client.Checked;
end;

procedure TCheckBoxBinder.SetTargetValue(Value: TValue);
begin
  Client.Checked := Value.AsBoolean;
end;

{ TEditControlBinder }

function TEditControlBinder.GetBindEventName: string;
begin
  Result := 'OnChange'
end;

function TEditControlBinder.GetTargetValue: TValue;
begin
  Result := Client.Text;
end;

procedure TEditControlBinder.SetTargetValue(Value: TValue);
begin
  Client.Text := Value.ToString;
end;

{ TListBinder<T> }

function TListBinder<T>.GetRType: TRttiType;
begin
  if Param is TRttiType then
    Result := (Param as TRttiType)
  else if Context is TRttiType then
    Result := (Context as TRttiType)
end;

procedure TListBinder<T>.Validate;
begin
  inherited;
  if Context = nil then
    raise EArgumentNilException.CreateFmt('%s requires context.', [ClassName]);
end;

destructor TListBinder<T>.Destroy;
begin
  FModel := nil;
  inherited;
end;

function TListBinder<T>.GetModel: IObjectList;
begin
  Result := FModel;
end;

procedure TListBinder<T>.DoUpdateTarget(Value: TValue);
begin
  if Value.IsType < TList < TObject >> then
    FModel := Value.AsType < TList < TObject >>
end;

{ TGridBinder }

type
  THackedStringGrid = class(TDrawGrid)
  private
    FUpdating: Boolean;
    FNeedsUpdating: Boolean;
  public
    procedure SetUpdateState(Updating: Boolean);
  end;

procedure THackedStringGrid.SetUpdateState(Updating: Boolean);
begin
  FUpdating := Updating;
  if not Updating and FNeedsUpdating then begin
    InvalidateGrid;
    FNeedsUpdating := False;
  end;
end;

procedure TGridBinder.DoUpdateTarget(Value: TValue);
var
  RProp: TRttiProperty;
  Col, Row: Integer;
  Obj: TObject;
  Text: string;
  Properties: TArray<TRttiProperty>;
begin
  inherited;
  THackedStringGrid(Client).SetUpdateState(True);
  LockWindowUpdate(Client.Handle);
  try
    Col := Client.FixedCols;
    Properties := RType.GetProperties;
    for RProp in Properties do begin
      if RProp.PropertyType.IsInstance then
        Continue;

      Client.Cells[Col, 0] := RProp.Name;
      Client.Objects[Col, 0] := RProp;
      Inc(Col);
    end;
    Client.ColCount := Col - Client.FixedCols;

    Row := Client.FixedRows;
    for Obj in GetModel do begin
      Col := Client.FixedCols;
      Client.Objects[0, Row] := Obj;
      for RProp in Properties do begin
        if RProp.PropertyType.IsInstance then
          Continue;
        Text := RProp.GetValue(Obj).ToString;
        Client.Cells[Col, Row] := Text;
        Inc(Col);
      end;
      Inc(Row);
      if Row = Client.RowCount then
        Client.RowCount := Client.RowCount + 1;
    end;
  finally
    THackedStringGrid(Client).SetUpdateState(False);
    LockWindowUpdate(0);
  end;
end;

{ TActionBinder }

procedure TActionBinder.Bind;
begin
  inherited;
  CaptureEvent('OnExecute');
  CaptureEvent('OnUpdate');
end;

function TActionBinder.CanUpdateModel: Boolean;
begin
  Result := False;
end;

function TActionBinder.CanUpdateTarget: Boolean;
begin
  Result := False;
end;

{ TComboBoxBinder }

function TComboBoxBinder.GetBindEventName: string;
begin
  Result := 'OnChange';
end;

function GetEnumPrefix(TypeInfo: PTypeInfo): string;
var
  FirstIdent: string;
  Ident: string;
  idxIdent: Integer;
  p: Integer;
begin
  Result := '';
  FirstIdent := TypInfo.GetEnumName(TypeInfo, 0);
  p := 0;
  while p < Length(FirstIdent) do begin
    inc(p);
    for idxIdent := 1 + GetTypeData(TypeInfo).MinValue to GetTypeData(TypeInfo).MaxValue do begin
      Ident := TypInfo.GetEnumName(TypeInfo, idxIdent);
      if FirstIdent[p] <> Ident[p] then Exit;
    end;
    Result := Result + FirstIdent[p];
  end;
end;

function TComboBoxBinder.GetTargetValue: TValue;
var
  Prop: TRttiInstanceProperty;
  RType: TRttiType;
begin
  Prop := (Context as TRttiInstanceProperty);
  RType := Prop.PropertyType;
  if (RType is TRttiEnumerationType) then begin
    Result :=
    TValue.FromOrdinal(RType.Handle, GetEnumValue(RType.Handle, TUnprotectControl(Client).Text))
  end
  else
    Result := TUnprotectControl(Client).Text;
end;

procedure TComboBoxBinder.SetTargetValue(Value: TValue);
begin
  TUnprotectControl(Client).Text := Value.ToString;
end;

end.
