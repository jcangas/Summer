unit LoggerBenchmark.MainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  Summer.ILogger, FMX.Layouts, FMX.Memo, FMX.Controls.Presentation,
  FMX.Edit, FMX.EditBox, FMX.NumberBox;

type
  TTestInfo = record
    Writer: TLog.Writer;
    Descrip: string;
  end;

  TMainForm = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    ToolBar1: TToolBar;
    NumberBox: TNumberBox;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    FLoggersToTest: array of TTestInfo;
    procedure SetupLoggersToTest;
    function TestLogger(const RepeatCount: Integer; const Writer: TLog.Writer): Int64;
    procedure ReportWrite(const Text: string);overload;
    procedure ReportWrite(const FmtText: string; Args: array of const);overload;
    procedure ReportReset;
    procedure ClearLoggersToTest;
    procedure TestLoggers;
    function GetLogFileName(const Basename: string): string;
    function RepeatCount: Integer;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
  System.Diagnostics,
  System.IOUtils,
  Summer.CLI,
  Summer.Logger;

{$R *.fmx}

function TestInfo(Logger: TLog.Writer; Descrip: string = ''): TTestInfo;
begin
  Result.Writer := Logger;
  if Descrip.IsEmpty then
    Result.Descrip := Logger.ClassName
  else
    Result.Descrip := Descrip;
end;

procedure TMainForm.ReportReset;
begin
  Memo1.Lines.Clear;
end;

procedure TMainForm.ReportWrite(const FmtText: string; Args: array of const);
begin
  ReportWrite(Format(FmtText, Args));
end;

function TMainForm.GetLogFileName(const Basename: string): string;
begin
  Result := Format('%s-%s.%s',[ParamStr(0), Basename, 'log'])
end;

procedure TMainForm.SetupLoggersToTest;
var
  FileWriter: TLog.Writer;
begin
  FLoggersToTest := FLoggersToTest + [TestInfo(TConsoleLogWriter.Create)];
  FLoggersToTest := FLoggersToTest + [TestInfo(TOutputDebugLogWriter.Create)];
  FileWriter := TTextFileLogWriter.Create(GetLogFileName('TTextFileLogWriter'));
  FLoggersToTest := FLoggersToTest + [TestInfo(FileWriter, 'FileWriter default')];
  FileWriter := TTextFileLogWriter.Create(GetLogFileName('TTextFileLogWriter'), [swoCloseOnWrite]);
  FLoggersToTest := FLoggersToTest + [TestInfo(FileWriter, 'FileWriter with close')];
  FileWriter := TTextFileLogWriter.Create(GetLogFileName('TTextFileLogWriter'), [swoConsumerThread]);
  FLoggersToTest := FLoggersToTest + [TestInfo(FileWriter, 'FileWriter with delayed')];
end;

procedure TMainForm.ClearLoggersToTest;
begin
  SetLength(FLoggersToTest, 0);
end;

procedure TMainForm.ReportWrite(const Text: string);
begin
  TThread.Queue(nil, procedure begin
    Memo1.Lines.Add(Format('%s - %s', [FormatDateTime('hh:mm:ss', Now), Text]));
  end);
end;

function TMainForm.RepeatCount: Integer;
begin
  Result := Trunc(NumberBox.Value);
end;

procedure TMainForm.TestLoggers;
var
  Info: TTestInfo;
  ElapsedMs: Int64;
begin
  CLI.CheckConsole([coRequired, coAllocate]);
  ReportReset;
  SetupLoggersToTest;
  try
    ReportWrite('Preparados %d TLogWriters para test con %s mensajes', [Length(FloggersToTest), FormatFloat('###,##0', RepeatCount)]);
    for Info in FLoggersToTest do begin
      ReportWrite('');
      ReportWrite('Ejecutando test usando %s ...', [Info.Descrip]);
      ElapsedMs := TestLogger(RepeatCount, Info.Writer);
      ReportWrite('Tiempo empleado Total= %sms | media= %sms', [FormatFloat('###,##0', ElapsedMs), FormatFloat('###,##0', ElapsedMs / RepeatCount)]);
    end;
  finally
    ClearLoggersToTest;
    ReportWrite('Test finalizado');
  end;
end;

function TMainForm.TestLogger(const RepeatCount: Integer; const Writer: TLog.Writer): Int64;
var
  Chrono: TStopwatch;
  i: Integer;
  UsedFilename: string;
begin
  Logger.AddWriter(Writer);
  Chrono := TStopwatch.StartNew;
  for i := 1 to RepeatCount do
    Logger.Info('test logger msg nro: %d', [i]);
  Result := Chrono.ElapsedMilliseconds;
  if Writer is TTextFileLogWriter then
    UsedFilename := TTextFileLogWriter(Writer).FileName
  else
    UsedFilename := '';
  Logger.RemoveWriter(Writer);
  if TFile.Exists(UsedFilename) then TFile.Delete(UsedFilename);

end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  TThread.CreateAnonymousThread(TestLoggers).Start
end;

end.
