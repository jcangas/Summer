{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}


/// A logging service totally inspired by Log4J http://logging.apache.org/log4j/1.2/

unit Summer.ILogger;

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  Summer.Utils;

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

  strict protected
    class var FStdLevels: TArray<TLog.Level>;
    class constructor ClassCreate;
  public const
    All: TLog.Level   = (FValue: Low(Integer); FID: 'ALL');
    Trace: TLog.Level = (FValue: 0; FID: 'TRACE');
    Debug: TLog.Level = (FValue: 100; FID: 'DEBUG');
    Info: TLog.Level  = (FValue: 200; FID: 'INFO');
    Warn: TLog.Level  = (FValue: 300; FID: 'WARN');
    Error: TLog.Level = (FValue: 400; FID: 'ERROR');
    Fatal: TLog.Level = (FValue: 500; FID: 'FATAL');
    Off: TLog.Level   = (FValue: High(Integer); FID: 'OFF');

    class function ToLevel(const LevelID: string): TLog.Level;overload;
    class function ToLevel(const LevelID: string; DefaultLevel: TLog.Level): TLog.Level;overload;
    class function ToLevel(const LevelValue: Integer): TLog.Level;overload;
    class function ToLevel(const LevelValue: Integer; DefaultLevel: TLog.Level): TLog.Level;overload;
    class property StdLevels: TArray<TLog.Level> read FStdLevels;
  end;

  ILogger = interface
    ['{3DFFFFBC-8059-4DB2-93A5-15A0082C35E1}']
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);
    function GetLogger(Name: string): ILogger;

    function Accept(RequestedLevel: TLog.Level): Boolean;
    procedure Log(AEvent: TLog.Event);overload;
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

    function GetCategory: string;
    function GetName: string;
    function GetParent: ILogger;
    function GetLevel: TLog.Level;
    procedure SetLevel(const Value: TLog.Level);
    function GetAdditivity: Boolean;
    procedure SetAdditivity(const Value: Boolean);
    function GetIsRoot: Boolean;

    property Name: string read GetName;
    property Parent: ILogger read GetParent;
    property Category: string read GetCategory;
    property Level: TLog.Level read GetLevel write SetLevel;
    property Additivity: Boolean read GetAdditivity
      write SetAdditivity;
    property IsRoot: Boolean
      read GetIsRoot;
  end;

implementation

{ TLog.Formatter }

function TLog.Formatter.Format(Event: TLog.Event): string;
const
  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV%CT] %TX';
// HINT: conditional formating feature using syntax ??{,}  Sample:
//  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV??{%CT,@%CT}] %TX';
var
  Temp: string;
begin
  
  
  Result := StringReplace(FmtSt, '%TH', SysUtils.Format('%6.6d', [Event.ThreadID]), [rfReplaceAll]);
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

{ TLog }

class constructor TLog.ClassCreate;
begin
  FStdLevels := [TLog.All, TLog.Trace, TLog.Debug, TLog.Info, TLog.Warn, TLog.Error, TLog.Fatal, TLog.Off];
end;

class function TLog.ToLevel(const LevelID: string): TLog.Level;
begin
  Result := TLog.ToLevel(LevelID, TLog.Off);
end;

class function TLog.ToLevel(const LevelID: string; DefaultLevel: TLog.Level): TLog.Level;
var
  Level: TLog.Level;
begin
  for Level in FStdLevels do
    if SameText(Level.ID, LevelID) then Exit(Level);
  Result := DefaultLevel;
end;

class function TLog.ToLevel(const LevelValue: Integer): TLog.Level;
begin
  Result := TLog.ToLevel(LevelValue, TLog.Off);
end;

class function TLog.ToLevel(const LevelValue: Integer; DefaultLevel: TLog.Level): TLog.Level;
var
  Level: TLog.Level;
begin
  for Level in FStdLevels do
    if (Level.Value = LevelValue) then Exit(Level);
  Result := DefaultLevel;
end;

end.
