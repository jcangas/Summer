{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Win.SvcCtrl;

interface

uses
  System.Classes,
  Summer.Win.ISvcCtrl;

type
  TWinServiceControl = class(TInterfacedObject, IWinServiceControl)
  strict private
    FServiceExePath: string;
    FDisplayName: string;
    FServiceName: string;
    function GetStatus(const ServiceName: string; const MachineName: string=''): Cardinal; overload;
    procedure Exec(const Args: string);
    function GetDisplayName: string;
    function GetServiceName: string;
  public
    constructor Create(const ServiceExePath: string; const ServiceName: string; const DisplayName: string);
    function GetStatus: Cardinal;overload;
    procedure Install;
    procedure Start;
    procedure Stop;
    procedure Uninstall;
    property ServiceExePath: string read FServiceExePath;
    property ServiceName: string read GetServiceName;
    property DisplayName: string read GetDisplayName;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
{$IFDEF MSWINDOWS}
  WinApi.WinSvc,
{$ENDIF MSWINDOWS}
  Summer.Utils;

{ WinServiceControl }

constructor TWinServiceControl.Create(const ServiceExePath: string; const ServiceName: string; const DisplayName: string);
begin
  inherited Create;
  FServiceExePath := ServiceExePath;
  FServiceName := ServiceName;
  FDisplayName := DisplayName;
  if FDisplayName.IsEmpty then
    FDisplayName := ServiceName;
end;

procedure TWinServiceControl.Exec(const Args: string);
begin
{$IFDEF MSWINDOWS}
  TOSShell.RunAs('sc', Args, TOSShell.ShowMode.Hide);
{$ENDIF MSWINDOWS}
end;

procedure TWinServiceControl.Install;
begin
  Exec(Format('create %s DisplayName= "%s" binPath= "%s"', [ServiceName,  DisplayName, ExpandUNCFileName(ServiceExePath)]));
end;

procedure TWinServiceControl.Start;
begin
  Exec('start ' + ServiceName);
end;

procedure TWinServiceControl.Stop;
begin
  Exec('stop ' + ServiceName);
end;

procedure TWinServiceControl.Uninstall;
begin
  Exec('delete ' + ServiceName);
end;

function TWinServiceControl.GetDisplayName: string;
begin
  Result := FDisplayName;
end;

function TWinServiceControl.GetServiceName: string;
begin
  Result := FServiceName;
end;

function TWinServiceControl.GetStatus: Cardinal;
begin
  Result := GetStatus(ServiceName);
end;


// return: See WinServiceStatus
function TWinServiceControl.GetStatus(const ServiceName: string; const MachineName: string=''): Cardinal;
{$IFDEF MSWINDOWS}
var
  SCManagerHandle, WinServiceHandle: SC_Handle;
  ServiceStatus: TServiceStatus;
begin
  Result := WinServiceStatus.UNKNOWN;
  SCManagerHandle := OpenSCManager(PChar(MachineName), Nil, SC_MANAGER_CONNECT);
  if not(SCManagerHandle > 0) then
    Exit;
  try
    // open a handle to the specified service
    WinServiceHandle := OpenService(SCManagerHandle, PChar(ServiceName),
      SERVICE_QUERY_STATUS);
    if not(WinServiceHandle > 0) then
      Exit;
    try
      if (QueryServiceStatus(WinServiceHandle, ServiceStatus)) then
        Result := ServiceStatus.dwCurrentState;
    finally
      CloseServiceHandle(WinServiceHandle);
    end;
  finally
    CloseServiceHandle(SCManagerHandle);
  end;
end;
{$ELSE}
begin
  Result := 0;
end;

{$ENDIF MSWINDOWS}

end.
