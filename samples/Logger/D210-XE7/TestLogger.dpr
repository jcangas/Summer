program TestLogger;

uses
  System.StartUpCopy,
  FMX.Forms,
  SummerFW.Utils.RTL,
  TestLogger.MainForm in '..\TestLogger.MainForm.pas' {MainForm};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := IsDebuggerEnabled;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
