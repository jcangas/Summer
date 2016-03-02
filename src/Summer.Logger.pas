{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

/// A logging service totally inspired by Log4J http://logging.apache.org/log4j/1.2/

unit Summer.Logger;

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  Summer.Utils,
  Summer.ILogger;

type
  TLogger = class(TInterfacedObject, ILogger)
  public type
    Childs = TDictionary<string, ILogger>;
    RequestEvent = reference to procedure(AEvent: TLog.Event);
  private
    class var FRootLogger: ILogger;
    class var GLock: TObject;
  var
    FName: string;
    [WEAK] // ILogger;
    FParent: TInterfacedObject;
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
    function GetName: string;
    function GetParent: ILogger;
    function GetAdditivity: Boolean;
  protected
    function ILogger.GetLogger = GetChild;
    function GetChild(Name: string): ILogger;
  public
    class function GetRootLogger: ILogger;
    class function GetLogger(Name: string = ''): ILogger;
    class property OnRequestEvent: RequestEvent read FOnRequestEvent
      write FOnRequestEvent;

    constructor Create(AParent: TLogger = nil; AName: string = '');
    destructor Destroy; override;
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);

    function Accept(RequestedLevel: TLog.Level): Boolean;
    procedure Log(AEvent: TLog.Event); overload;
    procedure Log(RequestedLevel: TLog.Level; Msg: string); overload;
    procedure Debug(Msg: string); overload;
    procedure Debug(Fmt: string; Args: array of const); overload;
    procedure Trace(Msg: string); overload;
    procedure Trace(Fmt: string; Args: array of const); overload;
    procedure Info(Msg: string); overload;
    procedure Info(Fmt: string; Args: array of const); overload;
    procedure Warn(Msg: string); overload;
    procedure Warn(Fmt: string; Args: array of const); overload;
    procedure Error(Msg: string); overload;
    procedure Error(Fmt: string; Args: array of const); overload;
    procedure Fatal(Msg: string); overload;
    procedure Fatal(Fmt: string; Args: array of const); overload;

    property Name: string read GetName;
    property Parent: ILogger read GetParent;
    property Category: string read GetCategory;
    property Level: TLog.Level read GetLevel write SetLevel;
    property Additivity: Boolean read GetAdditivity write SetAdditivity;
    property IsRoot: Boolean read GetIsRoot;
  end;

{$REGION 'Abstract Writers'}

  TWriteTextLogWriter = class(TLog.Writer)
  protected
    procedure DoWriteText(Text: string); virtual; abstract;
    procedure DoWriteEvent(Event: TLog.Event); override;
  end;

  TTextWriterProc = TProc<string>;
  TTextProcLogWriter = class(TWriteTextLogWriter)
  private
    FWriterProc: TTextWriterProc;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(AWriterProc: TTextWriterProc;
      FormatterClass: TLog.FormatterClass = nil);
    property WriterProc: TTextWriterProc read FWriterProc write FWriterProc;
  end;

{$ENDREGION}

  TStreamWriterOption = (swoCloseOnWrite, swoConsumerThread);
  TStreamWriterOptions = set of TStreamWriterOption;
  TWriterQueue = class
  private
    FQueue: TQueue<string>;
    FDelayed: Boolean;
    FWriterProc: TTextWriterProc;
    FConsuming: Boolean;
    procedure Consume;
    function HasWork: Boolean;
    procedure AcquireLock;
    procedure ReleaseLock;
  public
    constructor Create(WriterProc: TTextWriterProc; const Delayed: Boolean = False);
    destructor Destroy; override;
    property Delayed: Boolean read FDelayed;
    procedure Execute(Arg: string);
  end;

  TTextFileLogWriter = class(TWriteTextLogWriter)
  private
    FFilename: string;
    FStream: TFileStream;
    FStreamUse: Integer;
    FFileEncoding: TEncoding;
    FOptions: TStreamWriterOptions;
    FQueue: TWriterQueue;
    procedure CreateStream;
    procedure DestroyStream;
    procedure RealWriteText(Text: string);
  protected
    class function GetEncoding(const Stream: TStream): TEncoding; static;
    procedure ConvertFileToUTF8;
    procedure DoWriteText(Text: string); override;
    procedure AcquireStream;
    procedure ReleaseStream;
  public
    constructor Create(FileName: string; const Options: TStreamWriterOptions = [];
      FormatterClass: TLog.FormatterClass = nil);
    destructor Destroy; override;
    property FileName: string read FFilename;
    property Stream: TFileStream read FStream;
  end;

  TStringsLogWriter = class(TWriteTextLogWriter)
  private
    FStrings: TStrings;
    FCapacity: Integer;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(Strings: TStrings; const Capacity: Integer = 0;
      FormatterClass: TLog.FormatterClass = nil);
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

{$IFDEF MSWINDOWS}

  TWindowsEventLogWriter = class(TLog.Writer)
  private
    FEventLogHandle: THandle;
    FSourceName: string;
  protected
    procedure DoGetWindowsEventInfo(Event: TLog.Event; out WinEventType: Word;
      out WinEventCategory: Word); virtual;
  public
    procedure DoWriteEvent(Event: TLog.Event); override;
    constructor Create(SourceName: string;
      FormatterClass: TLog.FormatterClass = nil);
    destructor Destroy; override;
    property SourceName: string read FSourceName;
  end;

{$ENDIF}

function Logger: ILogger;

implementation

uses

{$IFDEF MSWINDOWS}
  WinApi.Windows,

{$ENDIF MSWINDOWS}
  System.RTLConsts,
  System.IOUtils,
  System.Math;

function Logger: ILogger;
begin
  Result := TLogger.GetRootLogger;
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

function TLogger.Accept(RequestedLevel: TLog.Level): Boolean;
begin
  Result := RequestedLevel >= Self.Level
end;

procedure TLogger.Log(AEvent: TLog.Event);
var
  Writer: TLog.Writer;
begin
  TMonitor.Enter(TLogger.GLock);
  try
    if Assigned(FOnRequestEvent) then
      OnRequestEvent(AEvent);
    if Accept(AEvent.Level) then
      for Writer in FWriters do
        Writer.Write(AEvent);
    if Additivity and Assigned(Parent) then
      Parent.Log(AEvent);
  finally
    TMonitor.Exit(TLogger.GLock);
  end;
end;

procedure TLogger.Log(RequestedLevel: TLog.Level; Msg: string);
var
  Event: TLog.Event;
begin
  Event.Level := RequestedLevel;
  Event.TimeStamp := Now;
  Event.ThreadID := TThread.CurrentThread.ThreadID;
  Event.Category := Category;
  Event.Text := Msg;
  Log(Event);
end;

function TLogger.GetLevel: TLog.Level;
begin
  if FLevelAssigned then
    Exit(FLevel);
  Result := Parent.Level;
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

procedure TLogger.Debug(Fmt: string; Args: array of const);
begin
  Debug(Format(Fmt, Args));
end;

constructor TLogger.Create(AParent: TLogger; AName: string);
begin
  inherited Create;
  FParent := AParent;
  FName := AName;
  FAdditivity := True;
  FChilds := Childs.Create;
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

procedure TLogger.Trace(Fmt: string; Args: array of const);
begin
  Trace(Format(Fmt, Args));
end;

procedure TLogger.Info(Msg: string);
begin
  Log(TLog.Info, Msg);
end;

procedure TLogger.Info(Fmt: string; Args: array of const);
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

procedure TLogger.Warn(Fmt: string; Args: array of const);
begin
  Warn(Format(Fmt, Args));
end;

procedure TLogger.Error(Msg: string);
begin
  Log(TLog.Error, Msg);
end;

procedure TLogger.Error(Fmt: string; Args: array of const);
begin
  Error(Format(Fmt, Args));
end;

procedure TLogger.Fatal(Msg: string);
begin
  Log(TLog.Fatal, Msg);
end;

procedure TLogger.Fatal(Fmt: string; Args: array of const);
begin
  Fatal(Format(Fmt, Args));
end;

function TLogger.GetAdditivity: Boolean;
begin
  Result := FAdditivity
end;

function TLogger.GetCategory: string;
begin
  if IsRoot then
    Exit(name)
  else if Parent.IsRoot then
    Exit(name)
  else
    Exit(Parent.Name + '.' + name);
end;

function TLogger.GetChild(Name: string): ILogger;
var
  DotIdx: Integer;
  ChildName: string;
  ChildTail: string;
begin
  name := name + '.';
  DotIdx := Pos('.', name);
  ChildName := Copy(name, 1, DotIdx - 1);
  if ChildName = '' then
    Exit(nil);
  ChildTail := Copy(name, DotIdx + 1, Length(name) - 1);

  if not FChilds.TryGetValue(ChildName, Result) then
  begin
    FChilds.Add(ChildName, TLogger.Create(Self, ChildName));
    Result := FChilds[ChildName];
  end;

  if ChildTail <> '' then
    Result := Result.GetLogger(ChildTail);
end;

class function TLogger.GetLogger(Name: string = ''): ILogger;
begin
  if name.IsEmpty then
    Result := GetRootLogger
  else
    Result := GetRootLogger.GetLogger(name);
end;

function TLogger.GetName: string;
begin
  Result := FName;
end;

function TLogger.GetParent: ILogger;
begin
  Result := (FParent as ILogger);
end;

class function TLogger.GetRootLogger: ILogger;
begin
  if FRootLogger = nil then
  begin
    GLock := TObject.Create;
    FRootLogger := TLogger.Create;
    FRootLogger.Level := TLog.Info;
  end;
  Result := FRootLogger;
end;

{ TWriteTextLogWriter }

procedure TWriteTextLogWriter.DoWriteEvent(Event: TLog.Event);
begin
  DoWriteText(FormatEvent(Event));
end;

{ TWriterProcLogWriter }

constructor TTextProcLogWriter.Create(AWriterProc: TTextWriterProc;
  FormatterClass: TLog.FormatterClass = nil);
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

constructor TStringsLogWriter.Create(Strings: TStrings;
  const Capacity: Integer = 0; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FStrings := Strings;
  FCapacity := Capacity;
end;

procedure TStringsLogWriter.DoWriteText(Text: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      FStrings.Add(Text);
      if (FCapacity > 0) then begin
        FStrings.BeginUpdate;
        while (FCapacity < FStrings.Count) do begin
          //FStrings.Clear; // Fix-ZAVA
          FStrings.Delete(0);
        end;
        FStrings.EndUpdate;
      end;
    end);
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
  TDebugger.Output(Text);
end;

{$IFDEF MSWINDOWS}
{ TWindowsEventLogWriter }

constructor TWindowsEventLogWriter.Create(SourceName: string;
FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FSourceName := SourceName;
  FEventLogHandle := RegisterEventSource(nil, PChar(SourceName));
  // nil => local computer
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
  ss: array [0 .. 0] of PChar;
begin
  if FEventLogHandle = 0 then
    Exit;
  ss[0] := PChar(FormatEvent(Event));

  DoGetWindowsEventInfo(Event, WinEventType, WinEventCategory);
  ReportEvent(FEventLogHandle, WinEventType, WinEventCategory, EventID,
    UserSecurityID, 1, // one substitution string
  NoEventData, @ss, PtrToData);
end;

{$ENDIF}
{ TTextFileLogWriter }

class function TTextFileLogWriter.GetEncoding(const Stream: TStream): TEncoding;
const
  CMaxPreambleLen = 4;
var
  Buff: TBytes;
begin
  Result := nil;
  Stream.Seek(0, TSeekOrigin.soBeginning);
  SetLength(Buff, Min(Stream.Size, CMaxPreambleLen));
  Stream.ReadBuffer(Buff, Length(Buff));
  TEncoding.GetBufferEncoding(Buff, Result);
end;

constructor TTextFileLogWriter.Create(FileName: string;
const Options: TStreamWriterOptions = []; FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FFilename := FileName;
  FOptions := Options;
  FQueue := TWriterQueue.Create(RealWriteText, (swoConsumerThread in Options));
end;

destructor TTextFileLogWriter.Destroy;
begin
  FQueue.Free;
  DestroyStream;
  inherited;
end;

procedure TTextFileLogWriter.CreateStream;
const
  FileMode: array [Boolean] of Word = (fmCreate, fmOpenReadWrite);
begin
  FStream := TFileStream.Create(Self.FileName, FileMode[FileExists(FileName)] +
    fmShareDenyNone);
  FFileEncoding := GetEncoding(FStream);
end;

procedure TTextFileLogWriter.DestroyStream;
begin
  FStream.Free;
  FStream := nil;
end;

procedure TTextFileLogWriter.AcquireStream;
begin
  if FStream = nil then
    CreateStream;
  Inc(FStreamUse);
end;

procedure TTextFileLogWriter.ReleaseStream;
begin
  Dec(FStreamUse);
  if (FStreamUse = 0) and (swoCloseOnWrite in FOptions) then
    DestroyStream;
end;

procedure TTextFileLogWriter.ConvertFileToUTF8;
var
  Buff: TBytes;
  Preamble: TBytes;
begin
  AcquireStream;
  try
    Stream.Seek(0, TSeekOrigin.soBeginning);
    SetLength(Buff, Stream.Size);
    Stream.ReadBuffer(Buff, Length(Buff));
    Buff := TEncoding.Convert(FFileEncoding, TEncoding.UTF8, Buff);

    Stream.Size := Length(Buff);
    Stream.Seek(0, TSeekOrigin.soBeginning);
    Preamble := TEncoding.UTF8.GetPreamble;
    Stream.WriteBuffer(Preamble, Length(Preamble));
    Stream.WriteBuffer(Buff, Length(Buff));
  finally
    ReleaseStream
  end;
end;

procedure TTextFileLogWriter.DoWriteText(Text: string);
begin
  FQueue.Execute(Text);
end;

procedure TTextFileLogWriter.RealWriteText(Text: string);
var
  Buff: TBytes;
begin
  AcquireStream;
  try
    Buff := FFileEncoding.GetBytes(Text + sLineBreak);
    Stream.Seek(0, TSeekOrigin.soEnd);
    Stream.WriteBuffer(Buff, Length(Buff));
  finally
    ReleaseStream;
  end;
end;

{ TWriterQueue }

constructor TWriterQueue.Create(WriterProc: TTextWriterProc;
const Delayed: Boolean = False);
begin
  inherited Create;
  FQueue := TQueue<string>.Create;
  FWriterProc := WriterProc;
  FDelayed := Delayed;
  if Delayed then
    TThread.CreateAnonymousThread(Consume).Start;
end;

destructor TWriterQueue.Destroy;
var
  ForDestroy: TObject;
begin
  ForDestroy := FQueue;
  AcquireLock;
  try
    FDelayed := False;
    FQueue := nil;
  finally
    ReleaseLock;
  end;
  repeat
  until (not FConsuming);
  ForDestroy.Free;
  inherited;
end;

function TWriterQueue.HasWork: Boolean;
begin
  AcquireLock;
  Result := Assigned(FQueue) and (FQueue.Count > 0);
  ReleaseLock;
end;

procedure TWriterQueue.AcquireLock;
begin
  TMonitor.Enter(Self);
end;

procedure TWriterQueue.ReleaseLock;
begin
  TMonitor.Exit(Self);
end;

procedure TWriterQueue.Consume;
begin
  FConsuming := True;
  while Delayed do
  begin
    if not HasWork then
      Sleep(500)
    else
    begin
      AcquireLock;
      try
        while HasWork do
          FWriterProc(FQueue.Dequeue);
      finally
        ReleaseLock;
      end;
    end;
  end;
  FConsuming := False;
end;

procedure TWriterQueue.Execute(Arg: string);
begin
  if Delayed then
  begin
    AcquireLock;
    try
      FQueue.Enqueue(Arg);
    finally
      ReleaseLock;
    end;
  end
  else
    FWriterProc(Arg);
end;

initialization

finalization

TLogger.GLock.Free;

end.
