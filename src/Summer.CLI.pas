{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit Summer.CLI;

interface

uses Classes, SysUtils, RTTI;

type
  /// Win Command Line Interface. EXPERIMENTAL
  CLI = class(TObject)
  public type
    TConsoleMode = (cmUnknown, cmConsoleApp, cmFromParent, cmAllocated, cmGUIApp);
    TConsoleOption = (coRequired, coAllocate, coForceNew);
    TConsoleOptions = set of TConsoleOption;
    TArgs = TArray<TValue>;
    TExecuteEvent = reference to procedure(Cmd: string; Args: TArgs);
    TErrorEvent = reference to procedure(Cmd: string; Args: TArgs; E: Exception);
  strict private class var
    FConsoleMode: TConsoleMode;
    FCommand: string;
    FCommandArgs: TArgs;
    FOnExecute: TExecuteEvent;
    FOnBeforeExecute: TExecuteEvent;
    FOnAfterExecute: TExecuteEvent;
    FOnError: TErrorEvent;
  protected
    class procedure DoBeforeExecute;
    class procedure DoAfterExecute;
    class procedure DoExecute;
    class procedure DoError(E: Exception);
  public
    class function CheckConsole(Options: TConsoleOptions = []): TConsoleMode;
    class function ConsoleApp: Boolean; static;
    class function CreateConsole: Boolean;static;
    class function AttachParentConsole: Boolean;static;
    class function ParseCmd: Boolean;
    class function Run: Boolean;
    class property OnBeforeExecute: TExecuteEvent read FOnBeforeExecute write FOnBeforeExecute;
    class property OnAfterExecute: TExecuteEvent read FOnAfterExecute write FOnAfterExecute;
    class property OnExecute: TExecuteEvent read FOnExecute write FOnExecute;
    class property OnError: TErrorEvent read FOnError write FOnError;
  end;

resourcestring
  SProgrammNeedsConsole = 'Programm needs a console';

implementation

function AttachConsole(dwProcessId: LongWord): Boolean; stdcall;external 'kernel32';
function AllocConsole: Boolean;stdcall;external 'kernel32';

{ TCommandLineParser }

class function CLI.ParseCmd;
var
  idxPrm: Integer;
begin
  FCommand := '';
  Result := ParamCount > 0;
  if not Result then Exit;
  FCommand := ParamStr(1);
  SetLength(FCommandArgs, ParamCount - 1);
  for idxPrm := 0 to High(FCommandArgs) do
    FCommandArgs[idxPrm] := ParamStr(2 + idxPrm);
end;

class function CLI.Run: Boolean;
begin
  Result := ParseCmd;
  if not Result then Exit;
  DoBeforeExecute;
  try
    try
      DoExecute;
    finally
      DoAfterExecute;
    end;
  except
    on E: Exception do
      DoError(E);
  end;
end;

class procedure CLI.DoAfterExecute;
begin
  if not Assigned(FOnAfterExecute) then Exit;
  FOnAfterExecute(FCommand, FCommandArgs);
end;

class procedure CLI.DoBeforeExecute;
begin
  if not Assigned(FOnBeforeExecute) then Exit;
  FOnBeforeExecute(FCommand, FCommandArgs);
end;

class procedure CLI.DoExecute;
begin
  if not Assigned(FOnExecute) then Exit;
  FOnExecute(FCommand, FCommandArgs);
end;

class function CLI.ConsoleApp: Boolean;
begin
  Result := System.IsConsole;
  if Result then FConsoleMode := cmConsoleApp;
end;

class function CLI.CreateConsole: Boolean;
begin
  if FConsoleMode = cmAllocated then Exit(True);
  Result := AllocConsole;
  if Result then FConsoleMode := cmAllocated;
end;

class function CLI.AttachParentConsole: Boolean;
const
  ATTACH_PARENT_PROCESS = $FFFFFFFF;
begin
  Result := AttachConsole(ATTACH_PARENT_PROCESS);
  if Result then FConsoleMode := cmFromParent;
end;

class function CLI.CheckConsole(Options: TConsoleOptions = []): TConsoleMode;
var
  HasConsole: Boolean;
begin
  HasConsole := not (coForceNew in Options) and (ConsoleApp or AttachParentConsole)
            or (FConsoleMode = cmAllocated) or ((coAllocate in Options) and CreateConsole);
  if not HasConsole then begin
    FConsoleMode := cmGUIApp;
    if (coRequired in Options)then
      raise Exception.Create(SProgrammNeedsConsole);
  end;
  Result := FConsoleMode;
end;

class procedure CLI.DoError(E: Exception);
begin
  if not Assigned(FOnError) then Exit;
  FOnError(FCommand, FCommandArgs, E);
end;

end.
