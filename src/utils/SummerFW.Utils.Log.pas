{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

/// A logging service totally inspired by Log4J http://logging.apache.org/log4j/1.2/

{TODO: 
* JSON config
}

unit SummerFW.Utils.Log;

interface

uses
  Classes, SysUtils,
  Generics.Collections,
  SummerFW.Utils.RTL;

type
  TLog = class
  type
    Formatter = class;
    Level = TOpenEnum;
    Event = record
    public
      TimeStamp: TDateTime;
      ThreadID: TThreadID;
      Level: TLog.Level;
      Category: string;
      Text: string;
    end;

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
      FSilencers: Silencers;
    protected
      function FormatEvent(Event: TLog.Event): string;
      procedure DoWriteEvent(Event: TLog.Event); virtual;abstract;
    public
      constructor Create(FormatterClass: TLog.FormatterClass = nil);
      procedure AddSilencer(name: string; Silencer: TLog.Silencer);
      procedure RemoveSilencer(name: string);
      destructor Destroy; override;
      procedure Write(Event: TLog.Event);
    end;
    Writers = TObjectList<Writer>;

  public const
    All: TLog.Level   = (FValue: Low(Integer); FID: 'ALL');
    Trace: TLog.Level = (FValue: 0; FID: 'TRACE');
    Debug: TLog.Level = (FValue: 100; FID: 'DEBUG');
    Info: TLog.Level  = (FValue: 200; FID: 'INFO');
    Warn: TLog.Level  = (FValue: 300; FID: 'WARN');
    Error: TLog.Level = (FValue: 400; FID: 'ERROR');
    Fatal: TLog.Level = (FValue: 500; FID: 'FATAL');
    Off: TLog.Level   = (FValue: High(Integer); FID: 'OFF');
  end;

  TLogger = class
  public type
    Childs = TObjectDictionary<string, TLogger>;
    RequestEvent = reference to procedure (AEvent: Tlog.Event);
  private var
    FName: string;
    FParent: TLogger;
    FAdditivity: Boolean;
    FLevel: TLog.Level;
    FLevelAssigned: Boolean;
    FWriters: TLog.Writers;
    FChilds: TLogger.Childs;
    class var FOnRequestEvent: RequestEvent;
    function GetLevel: TLog.Level;
    procedure SetLevel(const Value: TLog.Level);
    procedure SetAdditivity(const Value: Boolean);
    function GetCategory: string;
    function GetIsRoot: Boolean;
  protected
    procedure Log(AEvent: Tlog.Event);overload;
    procedure Log(RequestedLevel: TLog.Level; Msg: string);overload;
    function GetChild(Name: string): TLogger;
  public
    class function GetRootLogger: TLogger;
    class function GetLogger(Name: string): TLogger;
    class property OnRequestEvent: RequestEvent read FOnRequestEvent write FOnRequestEvent;

    constructor Create(AParent: TLogger; AName: string);
    destructor Destroy;override;
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);

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

    property Name: string read FName;
    property Parent: TLogger read FParent;
    property Category: string read GetCategory;
    property Level: TLog.Level read GetLevel write SetLevel;
    property Additivity: Boolean read FAdditivity write SetAdditivity;
    property IsRoot: Boolean read GetIsRoot;
  end;

  {$REGION 'Abstract Writers'}
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
  {$ENDREGION}

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

  {$IFDEF MSWINDOWS}
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
  {$ENDIF}

var
  Logger: TLogger;

implementation

uses
 {$IFDEF MSWINDOWS} Windows, {$ENDIF}
  RTLConsts, IOUtils;

{ TLog.Formatter }

function TLog.Formatter.Format(Event: TLog.Event): string;
const
  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV] %CT: %TX';
begin
  Result := StringReplace(FmtSt, '%TH', IntToStr(Event.ThreadID), [rfReplaceAll]);
  Result := StringReplace(Result, '%LV', Event.Level.ToString,[rfReplaceAll]);
  Result := StringReplace(Result, '%CT', Event.Category,[rfReplaceAll]);

  if System.Pos('%TS:', Result) > 0 then begin
   Result := StringReplace(Result, '%TS:', '"',[rfReplaceAll]);
   Result := StringReplace(Result, '/%', '"',[rfReplaceAll]);
   Result := '"' + Result + '"';
   Result := FormatDateTime(Result, Event.TimeStamp);
  end;

  Result := StringReplace(Result, '%TX', Event.Text,[rfReplaceAll]);
end;

{ TLog.Writer }

constructor TLog.Writer.Create(FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create;
  FSilencers := Silencers.Create;
  if FormatterClass = nil then
    FormatterClass := TLog.Formatter;
  FFormatter := FormatterClass.Create;
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
end;

procedure TLogger.RemoveWriter(W: TLog.Writer);
begin
  FWriters.Remove(W);
end;

procedure TLogger.ExtractWriter(W: TLog.Writer);
begin
  FWriters.Extract(W);
end;

procedure TLogger.Log(AEvent: Tlog.Event);
var
  Writer: TLog.Writer;
begin
  if (AEvent.Level >= Level) then
    for Writer in FWriters do
      Writer.Write(AEvent);
  if Additivity and Assigned(FParent) then
    FParent.Log(AEvent);
end;

procedure TLogger.Log(RequestedLevel: TLog.Level; Msg: string);
var
  Event: TLog.Event;
begin
  Event.Level := RequestedLevel;
  Event.TimeStamp := Now;
  Event.ThreadID := TThread.CurrentThread.ThreadID;
  Event.Category := Category;
  Event.Text:= Msg;
  if Assigned(FOnRequestEvent) then
    OnRequestEvent(Event);
  Log(Event);
end;

function TLogger.GetLevel: TLog.Level;
begin
  if FLevelAssigned then Exit(FLevel);
  Result := FParent.Level;
end;

procedure TLogger.SetAdditivity(const Value: Boolean);
begin
  FAdditivity := Value;
end;

procedure TLogger.SetLevel(const Value: TLog.Level);
begin
  FLevel := Value;
  FLevelAssigned := True;
end;

procedure TLogger.Debug(Msg: string);
begin
  Log(TLog.Debug, Msg);
end;

procedure TLogger.Debug(Fmt: string; Args: array of const );
begin
  Debug(Format(Fmt, Args));
end;

constructor TLogger.Create(AParent: TLogger; AName: string);
begin
  inherited Create;
  FParent := AParent;
  FName := AName;
  FAdditivity := True;
  FChilds := Childs.Create([doOwnsValues]);
  FWriters := TLog.Writers.Create;
end;

destructor TLogger.Destroy;
begin
  FWriters.Free;
  FChilds.Free;
  inherited;
end;

procedure TLogger.Trace(Msg: string);
begin
  Log(TLog.Trace, Msg);
end;

procedure TLogger.Trace(Fmt: string; Args: array of const );
begin
  Trace(Format(Fmt, Args));
end;

procedure TLogger.Info(Msg: string);
begin
  Log(TLog.Info, Msg);
end;

procedure TLogger.Info(Fmt: string; Args: array of const );
begin
  Info(Format(Fmt, Args));
end;

function TLogger.GetIsRoot: Boolean;
begin
  Result := Parent = nil;
end;

procedure TLogger.Warn(Msg: string);
begin
  Log(TLog.Warn, Msg);
end;

procedure TLogger.Warn(Fmt: string; Args: array of const );
begin
  Warn(Format(Fmt, Args));
end;

procedure TLogger.Error(Msg: string);
begin
  Log(TLog.Error, Msg);
end;

procedure TLogger.Error(Fmt: string; Args: array of const );
begin
  Error(Format(Fmt, Args));
end;

procedure TLogger.Fatal(Msg: string);
begin
  Log(TLog.Fatal, Msg);
end;

procedure TLogger.Fatal(Fmt: string; Args: array of const );
begin
  Fatal(Format(Fmt, Args));
end;

function TLogger.GetCategory: string;
begin
  if IsRoot then Exit(Name)
  else if Parent.IsRoot then Exit(Name)
  else Exit(Parent.Name + '.' + Name);
end;

function TLogger.GetChild(Name: string): TLogger;
var
  DotIdx: Integer;
  ChildName: string;
  ChildTail: string;
begin
  Name := Name + '.';
  DotIdx := Pos('.', Name);
  ChildName := Copy(Name, 1, DotIdx - 1);
  if ChildName = '' then Exit(nil);
  ChildTail := Copy(Name, DotIdx + 1, Length(Name) - 1);

  if not FChilds.TryGetValue(ChildName, Result) then begin
    FChilds.Add(ChildName, TLogger.Create(Self,  ChildName));
    Result := FChilds[ChildName];
  end;

  if ChildTail <> '' then
    Result := Result.GetChild(ChildTail);
end;

class function TLogger.GetLogger(Name: string): TLogger;
begin
  if Name = '' then
    Result := GetRootLogger
  else
    Result := GetRootLogger.GetChild(Name);
end;

class function TLogger.GetRootLogger: TLogger;
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
  if not Assigned(FWriterProc) then
    raise EArgumentNilException.Create('AWriterProc: ' + SArgumentNil);
end;

procedure TTextProcLogWriter.DoWriteText(Text: string);
begin
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

{ TTextFileLogWriter }

constructor TTextFileLogWriter.Create(FileName: string; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FFilename := FileName;
end;

procedure TTextFileLogWriter.DoWriteText(Text: string);
begin
  TFile.AppendAllText(Filename, Text + sLineBreak);
end;

{$IFDEF MSWINDOWS}

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
  if Event.Level = TLog.Trace then
    WinEventType := EVENTLOG_AUDIT_SUCCESS
  else if Event.Level = TLog.Debug then
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
{$ENDIF}

initialization
  Logger := TLogger.Create(nil, '');
  Logger.Level := TLog.Info;
finalization
  Logger.Free;
end.
