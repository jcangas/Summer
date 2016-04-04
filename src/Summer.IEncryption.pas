{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.IEncryption;

interface

uses
  System.SysUtils,
  System.Rtti;

type
	///<summary>
	/// Encapsula un servicio de encriptación arbitrario. Para configurar el algoritmo de encriptación usado
	/// el servicio dispone de un mode de trabajo. Se puede activar un modo por defecto o bien pasarlo bajo demanda
	/// al encriptar/desencriptar.
	/// El conjunto de datos a encriptar puede pasarse como TBytes, o como string, en cuyo caso es convertido internamente a TBytes
	/// usando SysUtils.StringOf
	///</summary>
  IEncrypter = interface
    ['{B4102D93-DD0C-4B44-8816-F6F459EE8D4E}']
    /// Encriptar value usando la configuración establecida mediante ActiveMode
    function Encrypt(const Value: TBytes): TBytes; overload;
    function Encrypt(const Value: string): string; overload;

    /// Cambia temporalmente ActiveMode Encripta value y restaura ActiveMode
    function Encrypt(const Value: TBytes; Mode: TValue): TBytes; overload;
    function Encrypt(const Value: string; Mode: TValue): string; overload;

    /// Desencripta usando la configuración establecida mediante ActiveMode
    function Decrypt(const Value: TBytes): TBytes; overload;
    function Decrypt(const Value: string): string; overload;

    /// Cambia temporalmente ActiveMode Desencripta value y restaura ActiveMode
    function Decrypt(const Value: TBytes; Mode: TValue): TBytes; overload;
    function Decrypt(const Value: string; Mode: TValue): string; overload;

	// Accessors para la propiedad ActiveMode
    function GetActiveMode: TValue;
    procedure SetActiveMode(Value: TValue);
	property ActiveMode: TValue read GetActiveMode write SetActiveMode;

  end;

implementation

end.
