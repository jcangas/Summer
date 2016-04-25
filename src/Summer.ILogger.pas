{ == License ==
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
  /// <summary>
  /// Un Log representa un registro continuo de mensajes acerca de un sistema.
  /// El log registra la hora en que se recibe el mensaje y alguna información de contexto
  /// adicional como el ThreadID que originó el mensaje, una Category que permite
  /// clasificar el mensaje y un Level que indica la "importancia" del mensaje.
  /// </summary>
  TLog = class
  type
    Formatter = class;
    Level = TOpenEnum;

    /// <summary>Un Evento de Log.
    /// Los valores de TimeStamp, ThreadID son rellenados automaticamente. </summary>
    Event = record
    public
      TimeStamp: TDateTime;
      ThreadID: TThreadID;
      Level: TLog.Level;
      Category: string;
      Text: string;
    end;

    /// <summary>
    /// Clase para Formatear la salida. Especifica como un Event es transformado en un texto.
    /// Habitualmente se busca que el texto sea fácil de leer por un humano pero tambien
    /// fácil de analizar por una máquina. Esto permite hacer una explotación de la infomración
    /// recogida en el Log.
    /// </summary>
    FormatterClass = class of Formatter;

    Formatter = class
      function Format(Event: TLog.Event): string; virtual;
    end;

    /// <summary>
    /// Silencer: Un silenciador permite ignorar mensajes de Log filtrando un criterio arbitrario.
    /// Si el silenciador devuelve True para un Evento, el Log ignora el Evento, como
    /// si no se hubiera producido
    /// </summary>
    Silencer = reference to function(Event: TLog.Event): Boolean;
    Silencers = TDictionary<string, Silencer>;

    /// <summary>
    /// Writer: Un escritor es quien recibe los Eventos enviados al Log.
    /// El escritor decide dónde se escribirá el evento y con que formato.
    /// De esta forma un Writer puede guardar los eventos en un fichero,
    /// otro puede enviarlos a la consola, tranasmitirlos por red, etc.
    /// </summary>
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
    /// Niveles estandard: ver Log4j
    All: TLog.Level = (FValue: Low(Integer); FID: 'ALL');
    Trace: TLog.Level = (FValue: 0; FID: 'TRACE');
    Debug: TLog.Level = (FValue: 100; FID: 'DEBUG');
    Info: TLog.Level = (FValue: 200; FID: 'INFO');
    Warn: TLog.Level = (FValue: 300; FID: 'WARN');
    Error: TLog.Level = (FValue: 400; FID: 'ERROR');
    Fatal: TLog.Level = (FValue: 500; FID: 'FATAL');
    Off: TLog.Level = (FValue: High(Integer); FID: 'OFF');

    /// Some conversion utils
    class function ToLevel(const LevelID: string): TLog.Level; overload;
    class function ToLevel(const LevelID: string; DefaultLevel: TLog.Level): TLog.Level; overload;
    class function ToLevel(const LevelValue: Integer): TLog.Level; overload;
    class function ToLevel(const LevelValue: Integer; DefaultLevel: TLog.Level): TLog.Level; overload;
    class property StdLevels: TArray<TLog.Level> read FStdLevels;
  end;

  /// Interface para un servicio de Log. Se pueden anidar multiples loggers como relación Parent/Child.
  /// Cada child debe tener un nombre único.
  ILogger = interface
    ['{3DFFFFBC-8059-4DB2-93A5-15A0082C35E1}']
    /// Manage Writers list
    procedure AddWriter(W: TLog.Writer);
    procedure RemoveWriter(W: TLog.Writer);
    procedure ExtractWriter(W: TLog.Writer);
    /// <summary>
    /// Obtiene un Logger mediante nombre. Concatenando nombres con '.' podemos recuperar un hijo
    /// Si Name = '' retorna el Logger raiz
    /// </summary>
    function GetLogger(name: string): ILogger;

    /// <summary>
    /// Un Logger tiene asignado un nivel de respuesta: ignora Events con un level menor
    /// </summary>
    function Accept(RequestedLevel: TLog.Level): Boolean;

    /// <summary>
    /// Envia un evento al Logger
    /// </summary>
    procedure Log(AEvent: TLog.Event); overload;
    /// <summary>
    /// Consturye un Evento y se delega en el anterior
    /// </summary>
    procedure Log(RequestedLevel: TLog.Level; Text: string); overload;

     ///<summary> Envia evento con un Level Debug </summary>
    procedure Debug(Msg: string); overload;
     ///<summary> Envia evento con un Level Debug usando máscara Format </summary>
    procedure Debug(Fmt: string; Args: array of const); overload;
     ///<summary> Envia evento con un Level Trace </summary>
    procedure Trace(Msg: string); overload;
     ///<summary> Envia evento con un Level Trace usando máscara Format </summary>
    procedure Trace(Fmt: string; Args: array of const); overload;
     ///<summary> Envia evento con un Level Info </summary>
    procedure Info(Msg: string); overload;
     ///<summary> Envia evento con un Level Info usando máscara Format </summary>
    procedure Info(Fmt: string; Args: array of const); overload;
     ///<summary> Envia evento con un Level Warn </summary>
    procedure Warn(Msg: string); overload;
     ///<summary> Envia evento con un Level Warn usando máscara Format </summary>
    procedure Warn(Fmt: string; Args: array of const); overload;
     ///<summary> Envia evento con un Level Error </summary>
    procedure Error(Msg: string); overload;
     ///<summary> Envia evento con un Level Error usando máscara Format </summary>
    procedure Error(Fmt: string; Args: array of const); overload;
     ///<summary> Envia evento con un Level Fatal </summary>
    procedure Fatal(Msg: string); overload;
     ///<summary> Envia evento con un Level Fatal usando máscara Format </summary>
    procedure Fatal(Fmt: string; Args: array of const); overload;

    /// <summary> Category = Parent.Category + 'Name'. Ver Log4j </summary>
    function GetCategory: string;
    function GetName: string;
    function GetParent: ILogger;
    function GetLevel: TLog.Level;
    procedure SetLevel(const Value: TLog.Level);

    /// Decide si los enventos enviados a este Logger son propagados a su Parent.
    function GetAdditivity: Boolean;
    procedure SetAdditivity(const Value: Boolean);

    /// True si es el Logger raiz. Su nombre siempres es ''
    function GetIsRoot: Boolean;

    property Name: string read GetName;
    property Parent: ILogger read GetParent;
    property Category: string read GetCategory;
    property Level: TLog.Level read GetLevel write SetLevel;
    property Additivity: Boolean read GetAdditivity write SetAdditivity;
    property IsRoot: Boolean read GetIsRoot;
  end;

implementation

{ TLog.Formatter }

function TLog.Formatter.Format(Event: TLog.Event): string;
const
  FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV%CT] %TX';
  // TIP: conditional formating feature using syntax ??{,}  Sample:
  // FmtSt = '%TS:yyyy mmm dd/% | %TS:hh:nn:ss:zzz/% #%TH [%LV??{%CT,@%CT}] %TX';
  // TIP: Quiza lo mejor es una sintaxis tipo Liquid {{ }}

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
    if Silencer(Event) then
      Exit;
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
    if SameText(Level.ID, LevelID) then
      Exit(Level);
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
    if (Level.Value = LevelValue) then
      Exit(Level);
  Result := DefaultLevel;
end;

end.
