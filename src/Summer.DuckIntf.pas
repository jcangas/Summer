{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.DuckIntf;

interface
uses
  System.TypInfo,
  System.RTTI;

type
  /// <summary> Delegación dinámica de una interface.
  /// Busca si un método esta implementado en un objeto delegado; si lo encuentra
  ///  invoca esa implementación, en caso contrario se invoca MethodMissing.
  ///  Si no especificamos objeto delegado, se delega en Self.
  /// </summary>
  TDuckInterface = class(TVirtualInterface)
  strict private
    class var FContext: TRTTIContext;
  strict private
    FDelegated: TObject;
  private
    FOnMethodMissing: TVirtualInterfaceInvokeEvent;
  protected
    procedure DefaultInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
  /// <summary> Busca el método en el objeto FDelegated y lo invoca si lo encuentra.
  ///  Retorna True si invoca y Faalse si no invoca.
  /// </summary>
    function Delegate(Method: TRttiMethod; const Args: TArray<TValue>; out MethodResult: TValue): Boolean;
  /// <summary> Si no se logra invocar el método en FDeleagated, se invoca este
  ///  método que las clases descendientes pueden redefinir. La implmemntación aqui
  ///  delega en el evento OnMethodMissing.
  /// </summary>
    procedure MethodMissing(Method: TRttiMethod; const Args: TArray<TValue>;out Result: TValue); virtual;
  public
    class function GetGUID(PIID: PTypeInfo): TGUID;
    constructor Create(PIID: PTypeInfo; Delegated: TObject = nil);
    property Delegated: TObject read FDelegated;
    property OnMethodMissing: TVirtualInterfaceInvokeEvent read FOnMethodMissing write FOnMethodMissing;
  end;

implementation

uses System.SysUtils;

{ TMethodDelegator }

procedure TDuckInterface.MethodMissing(Method: TRttiMethod;
  const Args: TArray<TValue>; out Result: TValue);
begin
  if Assigned(FOnMethodMissing) then
  OnMethodMissing(Method, Args, Result);
end;

constructor TDuckInterface.Create(PIID: PTypeInfo; Delegated: TObject = nil);
begin
  inherited Create(PIID, DefaultInvoke);
  if Delegated = nil then
    FDelegated := Self
  else
    FDelegated := Delegated;
end;

function TDuckInterface.Delegate(Method: TRttiMethod;
  const Args: TArray<TValue>; out MethodResult: TValue): Boolean;
var
  RT: TRTTIType;
  MT: TRttiMethod;
begin
  if not Assigned(FDelegated) then
    Exit(False);
  RT := FContext.GetType(FDelegated.ClassType);
  MT := RT.GetMethod(Method.Name);
  if not Assigned(MT) then
    Exit(False);
  // Args[0] is Sender
  MethodResult := MT.Invoke(FDelegated, Copy(Args, 1, Length(Args) - 1));
  Result := True;
end;

procedure TDuckInterface.DefaultInvoke(Method: TRttiMethod;
  const Args: TArray<TValue>; out Result: TValue);
begin
  if not Delegate(Method, Args, Result) then
    MethodMissing(Method, Args, Result);
end;

class function TDuckInterface.GetGUID(PIID: PTypeInfo): TGUID;
var
  RType: TRttiInterfaceType;
begin
  RType := FContext.GetType(PIID) as TRttiInterfaceType;
  if not Assigned(RType) then
    raise Exception.Create('No GUID found for type ' + string(PIID.NameFld.ToString));
  Result := RType.GUID;
end;

end.
