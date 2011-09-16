unit SummerFW.Utils.Log;

interface

uses
  Classes, SysUtils, SummerFW.Utils.Collections;

type

  TLog = class
  type
    Formatter = class;
    Level = record
    strict private
      FCode: Integer;
      FID: string;
    public
      class operator Equal(A: TLog.Level; B: TLog.Level): Boolean;
      class operator NotEqual(A: TLog.Level; B: TLog.Level): Boolean;
      class operator GreaterThan(A: TLog.Level; B: TLog.Level): Boolean;
      class operator GreaterThanOrEqual(A: TLog.Level; B: TLog.Level): Boolean;
      class operator LessThan(A: TLog.Level; B: TLog.Level): Boolean;
      class operator LessThanOrEqual(A: TLog.Level; B: TLog.Level): Boolean;
      class operator Implicit(A: TLog.Level): string;
      function ToString: string;
      property Code: Integer read FCode;
      property ID: string read FID;
    end;

    Event = class
    public
      TimeStamp: TDateTime;
      ThreadID: TThreadID;
      Level: TLog.Level;
      Category: string;
      Text: string;
    end;
    History = TObjectList<Event>;

    FormatterClass = class of Formatter;
    Formatter = class
      function Format(Event: TLog.Event): string; virtual;
    end;

    Silencer = reference to function(Event: TLog.Event): Boolean;
    Silencers = TDictionary<string, Silencer>;
    WriterClass = class of Writer;
    Writer = class
    private
      FFormatter: TLog.Formatter;
      FWantHistory: Boolean;
      FSilencers: Silencers;
    protected
      function FormatEvent(Event: TLog.Event): string;
      procedure DoWriteEvent(Event: TLog.Event); virtual;abstract;
    public
      constructor Create(FormatterClass: TLog.FormatterClass; WantHistory: Boolean);overload;
      constructor Create(FormatterClass: TLog.FormatterClass);overload;
      constructor Create(WantHistory: Boolean= False);overload;
      procedure AddSilencer(name: string; Silencer: TLog.Silencer);
      procedure RemoveSilencer(name: string);
      destructor Destroy; override;
      procedure Write(Event: TLog.Event);
      property WantHistory: Boolean read FWantHistory;
    end;
    Writers = TObjectList<Writer>;

  public const
    All: TLog.Level   = (FCode: low(Integer); FID: 'ALL');
    Trace: TLog.Level = (FCode: 0; FID: 'TRACE');
    Debug: TLog.Level = (FCode: 100; FID: 'DEBUG');
    Info: TLog.Level  = (FCode: 200; FID: 'INFO');
    Warn: TLog.Level  = (FCode: 300; FID: 'WARN');
    Error: TLog.Level = (FCode: 400; FID: 'ERROR');
    Fatal: TLog.Level = (FCode: 500; FID: 'FATAL');
    Off: TLog.Level   = (FCode: high(Integer); FID: 'OFF');
  end;

  TLogger = class
  private
  var
    FWriters: TLog.Writers;
    FHistory: TLog.History;
    FLevel: TLog.Level;
    FHistoryEnabled: Boolean;
  protected
    procedure Write(RequestedLevel: TLog.Level; Msg: string);
  public
    class function GetLogger(Category: string): TLogger;
    destructor Destroy;override;
    property Level: TLog.Level read FLevel write FLevel;
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);
    property HistoryEnabled: Boolean read FHistoryEnabled write FHistoryEnabled;
    procedure SendHistoryTo(Writer: TLog.Writer);

    procedure Debug(Msg: string); overload;
    procedure Debug(Fmt: string; Args: array of const ); overload;
    procedure Trace(Msg: string); overload;
    procedure Trace(Fmt: string; Args: array of const ); overload;
    procedure Info(Msg: string); overload;
    procedure Info(Fmt: string; Args: array of const ); overload;
    procedure Warn(Msg: string); overload;
    procedure Warn(Fmt: string; Args: array of const ); overload;
    procedure Error(Msg: string); overload;
    procedure Error(Fmt: string; Args: array of const ); overload;
    procedure Fatal(Msg: string); overload;
    procedure Fatal(Fmt: string; Args: array of const ); overload;
  end;

  TWriteTextLogWriter = class(TLog.Writer)
  protected
    procedure DoWriteText(Text: string); virtual;abstract;
    procedure DoWriteEvent(Event: TLog.Event); override;
  end;

  TTextProcLogWriter = class(TWriteTextLogWriter)
  public type
    TTextProc = Reference to procedure(Text: string);
  private
    FWriterProc: TTextProc;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(AWriterProc: TTextProc; FormatterClass: TLog.FormatterClass = nil);
    property WriterProc: TTextProc read FWriterProc write FWriterProc;
  end;

  TTextFileLogWriter = class(TWriteTextLogWriter)
  private
    FFilename: string;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(FileName: string; FormatterClass: TLog.FormatterClass = nil);
    property Filename: string read FFilename;
  end;

  TStringsLogWriter = class(TWriteTextLogWriter)
  private
    FStrings: TStrings;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(Strings: TStrings; FormatterClass: TLog.FormatterClass = nil);
  end;

  TConsoleLogWriter = class(TWriteTextLogWriter)
  protected
    procedure DoWriteText(Text: string); override;
  public
  end;

  TOutputDebugLogWriter = class(TWriteTextLogWriter)
  protected
    procedure DoWriteText(Text: string); override;
  public
  end;

  TWindowsEventLogWriter = class(TLog.Writer)
  private
    FEventLogHandle: THandle;
    FSourceName: string;
  protected
    procedure DoGetWindowsEventInfo(Event: TLog.Event; out WinEventType: Word; out WinEventCategory: Word);virtual;
  public
    procedure DoWriteEvent(Event: TLog.Event); override;
    constructor Create(SourceName: string; FormatterClass: TLog.FormatterClass = nil);
    destructor Destroy;override;
    property SourceName: string read FSourceName;
  end;

var
  Logger: TLogger;

implementation

uses
  IOUtils, Windows;

{ TLog.Level }

class operator TLog.Level.Equal(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode = B.FCode;
end;

class operator TLog.Level.NotEqual(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode <> B.FCode;
end;

function TLog.Level.ToString: string;
begin
  Result := FID;
end;

class operator TLog.Level.GreaterThan(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode > B.FCode;
end;

class operator TLog.Level.GreaterThanOrEqual(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode >= B.FCode;
end;

class operator TLog.Level.Implicit(A: TLog.Level): string;
begin
  Result := A.ToString;
end;

class operator TLog.Level.LessThan(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode < B.FCode;
end;

class operator TLog.Level.LessThanOrEqual(A, B: TLog.Level): Boolean;
begin
  Result := A.FCode <= B.FCode;
end;

{ TLog.Formatter }

function TLog.Formatter.Format(Event: TLog.Event): string;
begin
  with Event do
    Result := SysUtils.Format('%s #%d [%s] %s - %s',
        [FormatDateTime('yyyy mmm dd "|" hh:nn:ss:zzz', TimeStamp), ThreadID,
        Level.ToString, Category, Text]);
end;

{ TLog.Writer }

constructor TLog.Writer.Create(FormatterClass: TLog.FormatterClass; WantHistory: Boolean);
begin
  inherited Create;
  FSilencers := Silencers.Create;
  if FormatterClass = nil then
    FormatterClass := TLog.Formatter;
  FFormatter := FormatterClass.Create;
  FWantHistory := WantHistory;
end;

constructor TLog.Writer.Create(FormatterClass: TLog.FormatterClass);
begin
  Create(FormatterClass, False);
end;

constructor TLog.Writer.Create(WantHistory: Boolean = False);
begin
  Create(nil, WantHistory);
end;

destructor TLog.Writer.Destroy;
begin
  FSilencers.Free;
  FFormatter.Free;
  inherited;
end;

procedure TLog.Writer.AddSilencer(name: string; Silencer: TLog.Silencer);
begin
  FSilencers.Add(name, Silencer);
end;

procedure TLog.Writer.RemoveSilencer(name: string);
begin
  FSilencers.Remove(name);
end;

procedure TLog.Writer.Write(Event: TLog.Event);
var
  Silencer: TLog.Silencer;
begin
  for Silencer in FSilencers.Values do
    if Silencer(Event) then Exit;
  DoWriteEvent(Event);
end;

function TLog.Writer.FormatEvent(Event: TLog.Event): string;
begin
  Result := FFormatter.Format(Event);
end;

{ TLogger }

procedure TLogger.AddWriter(W: TLog.Writer);
begin
  FWriters.Add(W);
  if W.WantHistory then
    SendHistoryTo(W);
end;

procedure TLogger.RemoveWriter(W: TLog.Writer);
begin
  FWriters.Remove(W);
end;

procedure TLogger.ExtractWriter(W: TLog.Writer);
begin
  FWriters.Extract(W);
end;

procedure TLogger.Write(RequestedLevel: TLog.Level; Msg: string);
var
  Writer: TLog.Writer;
  CurrentEvent: TLog.Event;
begin
  if not (RequestedLevel >= Level) then
    Exit;

  CurrentEvent := TLog.Event.Create;
  try
    CurrentEvent.Level := RequestedLevel;
    CurrentEvent.TimeStamp := Now;
    CurrentEvent.ThreadID := TThread.CurrentThread.ThreadID;
    CurrentEvent.Text:= Msg;
    for Writer in FWriters do begin
      Writer.Write(CurrentEvent);
    end;
  finally
    if HistoryEnabled then
      FHistory.Add(CurrentEvent)
    else
      CurrentEvent.Free;
  end;
end;

procedure TLogger.SendHistoryTo(Writer: TLog.Writer);
var
  Event: TLog.Event;
begin
  if Writer = nil then Exit;
  for Event in FHistory do begin
    Writer.Write(Event);
  end;
end;

procedure TLogger.Debug(Msg: string);
begin
  Write(TLog.Debug, Msg);
end;

procedure TLogger.Debug(Fmt: string; Args: array of const );
begin
  Debug(Format(Fmt, Args));
end;

destructor TLogger.Destroy;
begin
  FWriters.Free;
  FHistory.Free;
  inherited;
end;

procedure TLogger.Trace(Msg: string);
begin
  Write(TLog.Trace, Msg);
end;

procedure TLogger.Trace(Fmt: string; Args: array of const );
begin
  Trace(Format(Fmt, Args));
end;

procedure TLogger.Info(Msg: string);
begin
  Write(TLog.Info, Msg);
end;

procedure TLogger.Info(Fmt: string; Args: array of const );
begin
  Info(Format(Fmt, Args));
end;

procedure TLogger.Warn(Msg: string);
begin
  Write(TLog.Warn, Msg);
end;

procedure TLogger.Warn(Fmt: string; Args: array of const );
begin
  Warn(Format(Fmt, Args));
end;

procedure TLogger.Error(Msg: string);
begin
  Write(TLog.Error, Msg);
end;

procedure TLogger.Error(Fmt: string; Args: array of const );
begin
  Error(Format(Fmt, Args));
end;

procedure TLogger.Fatal(Msg: string);
begin
  Write(TLog.Fatal, Msg);
end;

procedure TLogger.Fatal(Fmt: string; Args: array of const );
begin
  Fatal(Format(Fmt, Args));
end;

class function TLogger.GetLogger(Category: string): TLogger;
begin
  Result := Logger;
end;

{ TWriteTextLogWriter }

procedure TWriteTextLogWriter.DoWriteEvent(Event: TLog.Event);
begin
  DoWriteText(FormatEvent(Event));
end;

{ TWriterProcLogWriter }

constructor TTextProcLogWriter.Create(AWriterProc: TTextProc; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FWriterProc := AWriterProc;
end;

procedure TTextProcLogWriter.DoWriteText(Text: string);
begin
  if Assigned(FWriterProc) then
    FWriterProc(Text);
end;

{ TStringsLogger }

constructor TStringsLogWriter.Create(Strings: TStrings; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FStrings := Strings;
end;

procedure TStringsLogWriter.DoWriteText(Text: string);
begin
  FStrings.Add(Text);
end;

{ TConsoleLogWriter }

procedure TConsoleLogWriter.DoWriteText(Text: string);
begin
  inherited;
  System.WriteLn(Text);
end;

{ TOutputDebugLogWriter }

procedure TOutputDebugLogWriter.DoWriteText(Text: string);
begin
  OutputDebugString(PChar(Text));
end;

{ TWindowsEventLogWriter }

constructor TWindowsEventLogWriter.Create(SourceName: string; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FSourceName := SourceName;
  FEventLogHandle := RegisterEventSource(nil, PChar(SourceName)); // nil => local computer
end;

destructor TWindowsEventLogWriter.Destroy;
begin
  DeregisterEventSource(FEventLogHandle);
  inherited;
end;

procedure TWindowsEventLogWriter.DoGetWindowsEventInfo(Event: TLog.Event;
  out WinEventType: Word; out WinEventCategory: Word);
begin
  WinEventCategory := 0;
  if Event.Level = TLog.Debug then
    WinEventType := EVENTLOG_AUDIT_SUCCESS
  else if Event.Level = TLog.Trace then
    WinEventType := EVENTLOG_AUDIT_SUCCESS
  else if Event.Level = TLog.Warn then
    WinEventType := EVENTLOG_WARNING_TYPE
  else if Event.Level = TLog.Error then
    WinEventType := EVENTLOG_ERROR_TYPE
  else if Event.Level = TLog.Fatal then
    WinEventType := EVENTLOG_ERROR_TYPE
  else
      WinEventType := EVENTLOG_INFORMATION_TYPE;
end;

procedure TWindowsEventLogWriter.DoWriteEvent(Event: TLog.Event);
const
  UserSecurityID = nil; // no user security identifier
  EventID = 0;
  NoEventData = 0;
  PtrToData = nil;

var
  WinEventType: Word;
  WinEventCategory: Word;
  ss: array [0..0] of pchar;
begin
  if FEventLogHandle = 0 then Exit;
  ss[0] := PChar(FormatEvent(Event));

  DoGetWindowsEventInfo(Event, WinEventType, WinEventCategory);
  ReportEvent(FEventLogHandle, WinEventType, WinEventCategory,  EventID,
            UserSecurityID, 1, // one substitution string
            NoEventData, @ss, PtrToData);
end;

{ TTextFileLogWriter }

constructor TTextFileLogWriter.Create(FileName: string; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FFilename := FileName;
end;

procedure TTextFileLogWriter.DoWriteText(Text: string);
begin
  TFile.AppendAllText(Filename, Text);
end;

initialization
  Logger := TLogger.Create;
  Logger.Level := TLog.Info;
  Logger.HistoryEnabled := True;
  Logger.FHistory :=  TLog.History.Create;
  Logger.FWriters := TLog.Writers.Create;

finalization
  Logger.Free;
end.
