unit SummerFW.DDD.AppFacade;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Messaging,
  FMX.Platform,
  PureMVC.Patterns.Facade,
  SummerFW.DDD.IAppFacade;

type
  TApplicationFacade = class(TFacade, IApplicationFacade)
  strict private
    FRunMode: TRunMode;
    SubscriptionId: Integer;
    aFMXApplicationEventService: IFMXApplicationEventService;
  private
    procedure HandleException(Sender: TObject; E: Exception);
    procedure HandleMainCaptionChanged(const Sender: TObject; const M: TMessage);
    function HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
    procedure HandleOnIdle(Sender: TObject; var Done: Boolean);
  protected
    procedure InitializeFacade;override;
    procedure DoOnException(E: Exception);virtual;
    procedure DoOnIdle(Sender: TObject; var Done: Boolean); virtual;
    function DoAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;virtual;
    procedure DoMainFormReady; virtual;
    function GetRunMode: TRunMode;virtual;
    procedure SetRunMode(const Value: TRunMode);virtual;
  public
    class function Instance: IApplicationFacade;
    procedure Initialize;virtual;
    procedure Run; virtual;
    function MainForm: TObject;
    procedure CreateForm(const InstanceClass: TComponentClass; var Reference);
    procedure ProccessMessages;
    property RunMode: TRunMode read GetRunMode write SetRunMode;
  end;

implementation

uses
  System.IOUtils,
  SummerFW.Utils.Log,
  FMX.Forms;

{ TApplicationFacade<IPaths> }

function TApplicationFacade.MainForm: TObject;
begin
  Result := Application.MainForm;
end;

procedure TApplicationFacade.Run;
begin
  Application.Run;
end;

procedure TApplicationFacade.HandleMainCaptionChanged(const Sender: TObject; const M: TMessage);
begin
  TMessageManager.DefaultManager.Unsubscribe(TMainCaptionChangedMessage, SubscriptionId, True);
  DoMainFormReady;
end;

procedure TApplicationFacade.Initialize;
begin

end;

procedure TApplicationFacade.InitializeFacade;
var
  EnvSwitch: string;
begin
  inherited;
  SubscriptionId := TMessageManager.DefaultManager.SubscribeToMessage(TMainCaptionChangedMessage, HandleMainCaptionChanged);
  Application.OnIdle := HandleOnIdle;
  Application.OnException := HandleException;
  if FindCmdLineSwitch('env', EnvSwitch) then begin
    if EnvSwitch = 'dev' then begin
      EnvironmentMode.Name := rmDevelopment;
      EnvironmentMode.RelativeRootPath := '../../../..';
    end;
  end;
  SetRunMode(EnvironmentMode);
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(aFMXApplicationEventService)) then
    aFMXApplicationEventService.SetApplicationEventHandler(HandleAppEvent)
end;

class function TApplicationFacade.Instance: IApplicationFacade;
begin
  Result := inherited Instance as IApplicationFacade
end;

procedure TApplicationFacade.ProccessMessages;
begin
  Application.ProcessMessages;
end;

procedure TApplicationFacade.DoMainFormReady;
begin

end;

procedure TApplicationFacade.CreateForm(const InstanceClass: TComponentClass; var Reference);
begin
  Application.CreateForm(InstanceClass, Reference);
end;

function TApplicationFacade.DoAppEvent(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  Result := True;
end;

procedure TApplicationFacade.DoOnIdle(Sender: TObject; var Done: Boolean);
begin

end;

procedure TApplicationFacade.DoOnException(E: Exception);
begin
  Application.ShowException(E);
end;

function TApplicationFacade.GetRunMode: TRunMode;
begin
  Result := FRunMode;
end;

procedure TApplicationFacade.SetRunMode(const Value: TRunMode);
begin
  FRunMode := Value;
end;

procedure TApplicationFacade.HandleException(Sender: TObject; E: Exception);
begin

end;

procedure TApplicationFacade.HandleOnIdle(Sender: TObject; var Done: Boolean);
begin
  DoOnIdle(Sender, Done);
end;

function TApplicationFacade.HandleAppEvent(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  Result := DoAppEvent(AAppEvent, AContext);
end;

end.
