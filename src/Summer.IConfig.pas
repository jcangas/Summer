unit Summer.IConfig;

interface

uses
  Summer.IJSONProperties, System.Rtti;

type
  IConfiguration = interface(IJSONProperties)
    ['{9312D4E1-72E2-4DF6-AB56-54F01ACAD6EA}']
    function GetDefaults: IConfiguration;
    function Clone : IConfiguration; overload;
    procedure SetDefaults(Value: IConfiguration);
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
  end;

implementation

end.
