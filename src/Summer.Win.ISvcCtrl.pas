{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Win.ISvcCtrl;

interface

uses
  System.Classes;

type

  WinServiceStatus = class
  public const
    UNKNOWN = 0;
    // Constanss Copied from  WinApi.WinSvc
    STOPPED                = $00000001;
    START_PENDING          = $00000002;
    STOP_PENDING           = $00000003;
    RUNNING                = $00000004;
    CONTINUE_PENDING       = $00000005;
    PAUSE_PENDING          = $00000006;
    PAUSED                 = $00000007;
    class function ToString(const Status: Cardinal): string;reintroduce;
  end;

  IWinServiceControl = interface
    ['{B4F5E2DC-6714-42F5-9CE5-1F92FEA5D8DE}']
    function GetStatus: Cardinal;
    procedure Install;
    procedure Start;
    procedure Stop;
    procedure Uninstall;
  end;

implementation

resourcestring
  StrDetenido = 'Detenido';
  StrIniciando = 'Iniciando';
  StrDeteniendo = 'Deteniendo';
  StrEnEjecución = 'En ejecución';
  StrContinuando = 'Continuando';
  StrPausando = 'Pausando';
  StrPausado = 'Pausado';
  StrNoInstalado = 'No instalado';

{ WinServiceStatus }

class function WinServiceStatus.ToString(const Status: Cardinal): string;
begin
  case Status of
      STOPPED :   Result := StrDetenido;
      START_PENDING:   Result := StrIniciando;
      STOP_PENDING:   Result := StrDeteniendo;
      RUNNING:   Result := StrEnEjecución;
      CONTINUE_PENDING:   Result := StrContinuando;
      PAUSE_PENDING:   Result := StrPausando;
      PAUSED:   Result := StrPausado;
  else
    Result := StrNoInstalado;
  end;
end;

end.
