unit SummerFW.DDD.ViewModel;

interface

uses
  Generics.Collections,
  System.UITypes,
  System.Classes,
  System.Actions,
  System.TypInfo,
  Data.Bind.ObjectScope,
  PureMVC.Patterns.Mediator,
  SummerFW.DDD.View;

type

{$M+}

  TViewModel = class(TMediator)
  public const
    UseComponentName = '*';
  strict private
    FAdapter: TObjectBindSourceAdapter;
  private
    procedure CreateAdapter;
  protected
    function TryGetComponent<T: TComponent>(const Name: string; out Component: T): Boolean; overload;
    function TryGetComponent(const Name: string; out Component: TComponent): Boolean; overload;
    function TryGetBindSource(const SourceName: string; out BindSource: TAdapterBindSource): Boolean;
    procedure UpdateAdapterObject(const BindSourceName: string; const Value: TObject);
    procedure SetSourceAdapter(const BindSourceName: string; Adapter: TBindSourceAdapter);
    procedure UpdateAdapterList(const BindSourceName: string; const Value: TObject);
    procedure BindEvent(const Name: string; const EventName: string; MethodPrefix: string = UseComponentName; const DoBind: Boolean = True); overload;
    procedure BindEvent(const Component: TComponent; const EventName: string; MethodPrefix: string = UseComponentName; const DoBind: Boolean = True); overload;
    procedure BindEvent(const Name: string; const EventName: string; const DoBind: Boolean); overload;
    procedure BindEvent(const Component: TComponent; const EventName: string; const DoBind: Boolean); overload;
    procedure BindActions(const DoBind: Boolean = True);
    procedure BindView(const DoBind: Boolean = True);
    procedure BindNotify;
    function GetViewModelClass: TClass; virtual;
    function GetViewModel: TObject; virtual;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
    function View: TCoreView;
    procedure UpdateViewState; virtual;
    procedure ReportViewStateMsg(const Text: string);
    procedure OnRegister; override;
  published
    procedure ViewOnDestroy(Sender: TObject);
    procedure ViewOnClose(Sender: TObject; var Action: TCloseAction);
    procedure ActionListOnUpdate(Action: TBasicAction; var Handled: Boolean);
  end;

{$M-}

implementation

{ TViewModel }

procedure TViewModel.ActionListOnUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  UpdateViewState;
end;

procedure TViewModel.AfterConstruction;
begin
  inherited;
  ReportViewStateMsg('');
  CreateAdapter;
  BindView;
  BindActions;
end;

destructor TViewModel.Destroy;
var
  AView: TCoreView;
begin
  if View <> nil then begin
    AView := View;
    BindView(False);
    BindActions(False);
    ViewComponent := nil;
    AView.Release;
  end;
  inherited;
end;

procedure TViewModel.ViewOnClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TViewModel.ViewOnDestroy(Sender: TObject);
begin
  Facade.RemoveMediator(Self);
end;

function TViewModel.View: TCoreView;
begin
  Result := GetViewComponent as TCoreView;
end;

procedure TViewModel.OnRegister;
begin
  UpdateAdapterObject('BindSource', GetViewModel);
  inherited;
end;

procedure TViewModel.ReportViewStateMsg(const Text: string);
begin
  if (View <> nil) then
    View.ReportViewStateMsg(Text);
end;

function TViewModel.TryGetComponent(const Name: string; out Component: TComponent): Boolean;
begin
  Component := View.FindComponent(name);
  Result := Assigned(Component);
end;

function TViewModel.TryGetComponent<T>(const Name: string; out Component: T): Boolean;
var
  Found: TComponent;
begin
  Component := nil;
  Result := TryGetComponent(name, Found) and (Found is T);
  if Result then
    Component := T(Found)
end;

function TViewModel.TryGetBindSource(const SourceName: string; out BindSource: TAdapterBindSource): Boolean;
begin
  Result := TryGetComponent<TAdapterBindSource>(SourceName, BindSource);
end;

procedure TViewModel.SetSourceAdapter(const BindSourceName: string; Adapter: TBindSourceAdapter);
var
  Source: TAdapterBindSource;
begin
  if TryGetBindSource(BindSourceName, Source) then
    Source.Adapter := Adapter;
end;

procedure TViewModel.UpdateAdapterList(const BindSourceName: string; const Value: TObject);
var
  Source: TAdapterBindSource;
begin
  if TryGetBindSource(BindSourceName, Source) then
    if Source.Adapter is TListBindSourceAdapter then
      with TListBindSourceAdapter(Source.Adapter) do begin
        Active := False;
        SetList(TObjectList<TObject>(Value), False);
        Active := (TObjectList<TObject>(Value) <> nil);
      end;
end;

procedure TViewModel.UpdateAdapterObject(const BindSourceName: string; const Value: TObject);
var
  Source: TAdapterBindSource;
begin
  if TryGetBindSource(BindSourceName, Source) then
    if Source.Adapter is TObjectBindSourceAdapter then
      with TObjectBindSourceAdapter(Source.Adapter) do begin
        Active := False;
        SetDataObject(Value, False);
        Active := (Value <> nil);
      end;
end;

procedure TViewModel.UpdateViewState;
begin

end;

procedure TViewModel.BindEvent(const Name: string; const EventName: string; const DoBind: Boolean);
var
  Component: TComponent;
begin
  if TryGetComponent(Name, Component) then BindEvent(Component.Name, EventName, DoBind);
end;

procedure TViewModel.BindEvent(const Component: TComponent; const EventName: string; const DoBind: Boolean);
begin
  BindEvent(Component, EventName, UseComponentName, DoBind);
end;

procedure TViewModel.BindEvent(const Name: string; const EventName: string; MethodPrefix: string = UseComponentName; const DoBind: Boolean = True);
var
  Component: TComponent;
begin
  if TryGetComponent(Name, Component) then
  BindEvent(Component, EventName, MethodPrefix, DoBind);
end;

procedure TViewModel.BindEvent(const Component: TComponent; const EventName: string; MethodPrefix: string = UseComponentName; const DoBind: Boolean = True);
var
  Method: TMethod;
begin
  if not Assigned(Component) then
    Exit;

  Method.Data := nil;
  Method.Code := nil;
  if MethodPrefix = UseComponentName then
    MethodPrefix := Component.Name;

  if DoBind then begin
    Method.Data := Self;
    Method.Code := MethodAddress(MethodPrefix + EventName);
    if not Assigned(Method.Code) then
      Exit;
  end;
  SetMethodProp(Component, EventName, Method);
end;

procedure TViewModel.BindView(const DoBind: Boolean = True);
begin
  BindEvent(View, 'OnClose', 'View', DoBind);
  BindEvent(View, 'OnDestroy', 'View', DoBind);
end;

procedure TViewModel.BindActions(const DoBind: Boolean = True);
var
  idx: Integer;
  Action: TContainedAction;
begin
  BindEvent(View.ActionList, 'OnUpdate', DoBind);
  for idx := 0 to View.ActionList.ActionCount - 1 do begin
    Action := View.ActionList.Actions[idx];
    BindEvent(Action, 'OnExecute', DoBind);
    BindEvent(Action, 'OnUpdate', DoBind);
  end;
end;

function TViewModel.GetViewModel: TObject;
begin
  Result := Self;
end;

function TViewModel.GetViewModelClass: TClass;
begin
  Result := Self.ClassType;
end;

procedure TViewModel.BindNotify;
begin
  View.BindSource.Refresh
end;

procedure TViewModel.CreateAdapter;
begin
  FAdapter := TObjectBindSourceAdapter.Create(View, nil, GetViewModelClass, False);
  FAdapter.AutoEdit := True;
  FAdapter.AutoPost := True;
  FAdapter.Active := False;
  View.BindSource.Adapter := FAdapter;
end;

end.
