program LoggerBenchmark;

uses
  System.StartUpCopy,
  FMX.Forms,
  Summer.Utils,
  LoggerBenchmark.MainForm in '..\LoggerBenchmark.MainForm.pas' {MainForm};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := TDebugger.IsEnabled;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
