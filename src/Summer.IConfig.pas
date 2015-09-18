unit Summer.IConfig;

interface

uses System.JSON, System.Rtti;

type
  IConfiguration = interface
    ['{9312D4E1-72E2-4DF6-AB56-54F01ACAD6EA}']
    function GetCount: Integer;
    function GetPair(const Index: Integer): TJSONPair;
    function GetChild(const Name: string): IConfiguration;
    function GetValue(const Name: string): TValue;
    procedure SetValue(const Name: string; const Value: TValue);
    function GetFileName: string;
    procedure LoadFromFile(const AFileName:string='');
    procedure SaveToFile(const AFileName:string='');
    function GetEnumerator: TJSONPairEnumerator;
    function AddPair(const Str: string; const Val: TJSONValue): TJSONObject;
    function RemovePair(const PairName: string): TJSONPair;
    function Clone: IConfiguration;
    function ToString: string;
    function GetAsJSON: string;
    procedure SetAsJSON(const Value: string);
    function GetAsObject: TJSONObject;
    procedure SetAsObject(const Value: TJSONObject);
    function GetDefaults: IConfiguration;
    procedure SetDefaults(Value: IConfiguration);
    property AsJSON: string read GetAsJSON write SetAsJSON;
    property AsObject: TJSONObject read GetAsObject write SetAsObject;
    property FileName: string read GetFileName;
    property Count: Integer read GetCount;
    property Pairs[const Index: Integer]: TJSONPair read GetPair;
    property Values[const Name: string]: TValue read GetValue write SetValue;default;
    property Childs[const Name: string]: IConfiguration read GetChild;
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
  end;

implementation

end.
