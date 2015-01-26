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
  Classes,
  SysUtils,
  Generics.Collections,
  SummerFW.Utils.RTL;

type
  TLog = class
  type
    Formatter = class;
    Level     = TOpenEnum;

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

    Silencer    = reference to function(Event: TLog.Event): Boolean;
    Silencers   = TDictionary<string, Silencer>;
    WriterClass = class of Writer;

    Writer = class
    private
      FFormatter: TLog.Formatter;
      FSilencers: Silencers;
    protected
      function FormatEvent(Event: TLog.Event): string;
      procedure DoWriteEvent(Event: TLog.Event); virtual; abstract;
    public
      constructor Create(FormatterClass: TLog.FormatterClass = nil);
      procedure AddSilencer(name: string; Silencer: TLog.Silencer);
      procedure RemoveSilencer(name: string);
      destructor Destroy; override;
      procedure Write(Event: TLog.Event);
    end;

    Writers = TObjectList<Writer>;

  public const
    All: TLog.Level   = (FValue: low(Integer); FID: 'ALL');
    Trace: TLog.Level = (FValue: 0; FID: 'TRACE');
    Debug: TLog.Level = (FValue: 100; FID: 'DEBUG');
    Info: TLog.Level  = (FValue: 200; FID: 'INFO');
    Warn: TLog.Level  = (FValue: 300; FID: 'WARN');
    Error: TLog.Level = (FValue: 400; FID: 'ERROR');
    Fatal: TLog.Level = (FValue: 500; FID: 'FATAL');
    Off: TLog.Level   = (FValue: high(Integer); FID: 'OFF');
  end;

  TLogger = class
  public type
    Childs       = TObjectDictionary<string, TLogger>;
    RequestEvent = reference to procedure(AEvent: TLog.Event);
  private
  var
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
    procedure Log(AEvent: TLog.Event); overload;
    procedure Log(RequestedLevel: TLog.Level; Msg: string); overload;
    function GetChild(name: string): TLogger;
  public
    class function GetRootLogger: TLogger;
    class function GetLogger(name: string): TLogger;
    class property OnRequestEvent: RequestEvent read FOnRequestEvent write FOnRequestEvent;

    constructor Create(AParent: TLogger; AName: string);
    destructor Destroy; override;
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);

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

    property name: string
      read FName;
    property Parent: TLogger
      read FParent;
    property Category: string
      read GetCategory;
    property Level: TLog.Level
      read GetLevel
      write SetLevel;
    property Additivity: Boolean
      read FAdditivity
      write SetAdditivity;
    property IsRoot: Boolean
      read GetIsRoot;
  end;

  {$REGION 'Abstract Writers'}

  TWriteTextLogWriter = class(TLog.Writer)
  protected
    procedure DoWriteText(Text: string); virtual; abstract;
    procedure DoWriteEvent(Event: TLog.Event); override;
  end;

  TTextProcLogWriter = class(TWriteTextLogWriter)
  public type
    TTextProc = reference to procedure(Text: string);
  private
    FWriterProc: TTextProc;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(AWriterProc: TTextProc; FormatterClass: TLog.FormatterClass = nil);
    property WriterProc: TTextProc
      read FWriterProc
      write FWriterProc;
  end;
  {$ENDREGION}

  TTextFileLogWriter = class(TWriteTextLogWriter)
  private
    FFilename: string;
    FFileStream: TFileStream;
    FFileEncoding: TEncoding;
  protected
    class function GetEncoding(const Stream: TStream): TEncoding; static;
    procedure ConvertFileToUTF8;
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(FileName: string; FormatterClass: TLog.FormatterClass = nil);
    destructor Destroy; override;
    property FileName: string
      read FFilename;
  end;

  TStringsLogWriter = class(TWriteTextLogWriter)
  private
    FStrings: TStrings;
    FCapacity: Integer;
  protected
    procedure DoWriteText(Text: string); override;
  public
    constructor Create(Strings: TStrings; const Capacity: Integer = 0; FormatterClass: TLog.FormatterClass = nil);
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
    procedure DoGetWindowsEventInfo(Event: TLog.Event; out WinEventType: Word; out WinEventCategory: Word); virtual;
  public
    procedure DoWriteEvent(Event: TLog.Event); override;
    constructor Create(SourceName: string; FormatterClass: TLog.FormatterClass = nil);
    destructor Destroy; override;
    property SourceName: string
      read FSourceName;
  end;
  {$ENDIF}

var
  Logger: TLogger;

implementation

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
{$ENDIF MSWINDOWS}
{$IFDEF IOS}
  iOSapi.Foundation,
{$ENDIF IOS}

  System.RTLConsts,
  System.IOUtils,
  System.Math;

{ TLog.Formatter }

function TLog.Formatter.Format(Event: TLog.Event): string;
const
  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV%CT] %TX';
// HINT: conditional formating feature using syntax ??{,}  Sample:
//  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV??{%CT,@%CT}] %TX';
var
  Temp: string;
begin
  Result := StringReplace(FmtSt, '%TH', IntToStr(Event.ThreadID), [rfReplaceAll]);
  Result := StringReplace(Result, '%LV', Event.Level.ToString, [rfReplaceAll]);

  if not Event.Category.IsEmpty then
    Temp := ' @' + Event.Category
  else
    Temp := '';

  Result := StringReplace(Result, '%CT', Temp, [rfReplaceAll]);

  if System.Pos('%TS:', Result) > 0 then begin
    Result := StringReplace(Result, '%TS:', '"', [rfReplaceAll]);
    Result := StringReplace(Result, '/%', '"', [rfReplaceAll]);
    Result := '"' + Result + '"';
    Result := FormatDateTime(Result, Event.TimeStamp);
  end;

  Result := StringReplace(Result, '%TX', Event.Text, [rfReplaceAll]);
end;

{ TLog.Writer }

constructor TLog.Writer.Create(FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create;
  FSilencers := Silencers.Create;
  if FormatterClass = nil then FormatterClass := TLog.Formatter;
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

procedure TLogger.Log(AEvent: TLog.Event);
var
  Writer: TLog.Writer;
begin
  if (AEvent.Level >= Level) then
    for Writer in FWriters do Writer.Write(AEvent);
  if Additivity and Assigned(FParent) then FParent.Log(AEvent);
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
  if Assigned(FOnRequestEvent) then OnRequestEvent(Event);
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

function TLogger.GetCategory: string;
begin
  if IsRoot then Exit(name)
  else if Parent.IsRoot then Exit(name)
  else Exit(Parent.name + '.' + name);
end;

function TLogger.GetChild(name: string): TLogger;
var
  DotIdx: Integer;
  ChildName: string;
  ChildTail: string;
begin
  name := name + '.';
  DotIdx := Pos('.', name);
  ChildName := Copy(name, 1, DotIdx - 1);
  if ChildName = '' then Exit(nil);
  ChildTail := Copy(name, DotIdx + 1, Length(name) - 1);

  if not FChilds.TryGetValue(ChildName, Result) then begin
    FChilds.Add(ChildName, TLogger.Create(Self, ChildName));
    Result := FChilds[ChildName];
  end;

  if ChildTail <> '' then Result := Result.GetChild(ChildTail);
end;

class function TLogger.GetLogger(name: string): TLogger;
begin
  if name = '' then Result := GetRootLogger
  else Result := GetRootLogger.GetChild(name);
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
  if not Assigned(FWriterProc) then raise EArgumentNilException.Create('AWriterProc: ' + SArgumentNil);
end;

procedure TTextProcLogWriter.DoWriteText(Text: string);
begin
  FWriterProc(Text);
end;

{ TStringsLogger }

constructor TStringsLogWriter.Create(Strings: TStrings; const Capacity: Integer = 0;
  FormatterClass: TLog.FormatterClass = nil);
begin
  inherited Create(FormatterClass);
  FStrings := Strings;
  FCapacity := Capacity;
end;

procedure TStringsLogWriter.DoWriteText(Text: string);
begin
  TThread.Queue(nil, procedure
    begin
      FStrings.Add(Text);
      if (FCapacity > 0) then
        while (FCapacity < FStrings.Count) do FStrings.Delete(0);
    end);
end;

{ TConsoleLogWriter }

procedure TConsoleLogWriter.DoWriteText(Text: string);
begin
  inherited;
  System.WriteLn(Text);
end;

{ TOutputDebugLogWriter }

{$IFDEF IOS}
function NSStrPtr(AString: string): Pointer;
begin
  Result := TNSString.OCClass.stringWithUTF8String
    (MarshaledAString(UTF8Encode(AString)));
end;
{$ENDIF IOS}

procedure TOutputDebugLogWriter.DoWriteText(Text: string);
begin
  TMonitor.Enter(Self);
  try
{$IFDEF IOS}
    NSLog(NSStrPtr(Text));
{$ENDIF IOS}

{$IFDEF MSWINDOWS}
    OutputDebugString(PWideChar(Text));
{$ENDIF MSWINDOWS}
  finally
    TMonitor.Exit(Self);
  end;
end;


{$IFDEF MSWINDOWS}
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

procedure TWindowsEventLogWriter.DoGetWindowsEventInfo(Event: TLog.Event; out WinEventType: Word;
out WinEventCategory: Word);
begin
  WinEventCategory := 0;
  if Event.Level = TLog.Trace then WinEventType := EVENTLOG_AUDIT_SUCCESS
  else if Event.Level = TLog.Debug then WinEventType := EVENTLOG_AUDIT_SUCCESS
  else if Event.Level = TLog.Warn then WinEventType := EVENTLOG_WARNING_TYPE
  else if Event.Level = TLog.Error then WinEventType := EVENTLOG_ERROR_TYPE
  else if Event.Level = TLog.Fatal then WinEventType := EVENTLOG_ERROR_TYPE
  else WinEventType := EVENTLOG_INFORMATION_TYPE;
end;

procedure TWindowsEventLogWriter.DoWriteEvent(Event: TLog.Event);
const
  UserSecurityID = nil; // no user security identifier
  EventID        = 0;
  NoEventData    = 0;
  PtrToData      = nil;

var
  WinEventType: Word;
  WinEventCategory: Word;
  ss: array [0 .. 0] of PChar;
begin
  if FEventLogHandle = 0 then Exit;
  ss[0] := PChar(FormatEvent(Event));

  DoGetWindowsEventInfo(Event, WinEventType, WinEventCategory);
  ReportEvent(FEventLogHandle, WinEventType, WinEventCategory, EventID, UserSecurityID, 1, // one substitution string
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

constructor TTextFileLogWriter.Create(FileName: string; FormatterClass: TLog.FormatterClass);
var
  fileMode: Word;
begin
  inherited Create(FormatterClass);
  FFilename := FileName;
  if FileExists(Self.FileName) then fileMode := fmOpenReadWrite
  else fileMode := fmCreate;
  FFileStream := TFileStream.Create(Self.FileName, fileMode + fmShareDenyNone);
  FFileEncoding := GetEncoding(FFileStream);
end;

destructor TTextFileLogWriter.Destroy;
begin
  FFileStream.Free;
  inherited;
end;

procedure TTextFileLogWriter.ConvertFileToUTF8;
var
  Buff: TBytes;
  Preamble: TBytes;
begin
  FFileStream.Seek(0, TSeekOrigin.soBeginning);
  SetLength(Buff, FFileStream.Size);
  FFileStream.ReadBuffer(Buff, Length(Buff));
  Buff := TEncoding.Convert(FFileEncoding, TEncoding.UTF8, Buff);

  FFileStream.Size := Length(Buff);
  FFileStream.Seek(0, TSeekOrigin.soBeginning);
  Preamble := TEncoding.UTF8.GetPreamble;
  FFileStream.WriteBuffer(Preamble, Length(Preamble));
  FFileStream.WriteBuffer(Buff, Length(Buff));
end;

procedure TTextFileLogWriter.DoWriteText(Text: string);
var
  Buff: TBytes;
begin
  try
    Buff := FFileEncoding.GetBytes(Text + sLineBreak);
    TMonitor.Enter(FFileStream);
    try
      FFileStream.Seek(0, TSeekOrigin.soEnd);
      FFileStream.WriteBuffer(Buff, Length(Buff));
    finally
      TMonitor.Exit(FFileStream);
    end;
  except
    on E: EFileStreamError do raise EInOutError.Create(E.Message);
  end;
end;

initialization

Logger := TLogger.Create(nil, '');
Logger.Level := TLog.Info;

finalization

Logger.Free;

end.
