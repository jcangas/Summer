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
  IEncrypter = interface
    ['{B4102D93-DD0C-4B44-8816-F6F459EE8D4E}']
    function GetActiveMode: TValue;
    procedure SetActiveMode(Value: TValue);
    /// Encrypt value using active mode
    function Encrypt(const Value: TBytes): TBytes; overload;
    /// Call previous using SysUtils BytesOf/StringOf
    function Encrypt(const Value: string): string; overload;
    /// Change active mode to Mode, encrypt and restores active mode
    function Encrypt(const Value: TBytes; Mode: TValue): TBytes; overload;
    /// Call previous using SysUtils BytesOf/StringOf
    function Encrypt(const Value: string; Mode: TValue): string; overload;
    /// Decrypt value using active mode
    function Decrypt(const Value: TBytes): TBytes; overload;
    /// Call previous using SysUtils BytesOf/StringOf
    function Decrypt(const Value: string): string; overload;
    /// Change active mode to Mode, decrypt and restores active mode
    function Decrypt(const Value: TBytes; Mode: TValue): TBytes; overload;
    /// Call previous using SysUtils BytesOf/StringOf
    function Decrypt(const Value: string; Mode: TValue): string; overload;
    property ActiveMode: TValue read GetActiveMode write SetActiveMode;
  end;

implementation

end.
