{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.IConfig;

interface

uses
  Summer.IJSONProperties, System.Rtti;

type
  /// <summary>
  ///  This interface define a global configuration service for
  ///  an Application, so you can use it with SICO.
  ///
  ///  Can register "default values" for missing keys; so
  ///  MyConfig['key'] returns previous assgined value or
  ///  the value assigned to MyConfig.Defaults['key'].
  ///  </summary>
  IConfiguration = interface(IJSONProperties)
    ['{9312D4E1-72E2-4DF6-AB56-54F01ACAD6EA}']
    function GetDefaults: IConfiguration;
    function GetChild(const Name: string): IConfiguration;
    function Clone : IConfiguration; overload;
    procedure SetDefaults(Value: IConfiguration);
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
    property Childs[const Name: string]: IConfiguration read GetChild;
  end;

implementation

end.
