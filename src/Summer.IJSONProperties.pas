unit Summer.IJSONProperties;

interface

uses
  System.JSON
  , System.Rtti
  , System.Classes;

type
  ///<summary>
  ///  A JSON persistent map of string to TValue.
  ///  Easy use with TValue or TJSONValue.
  ///  Support "nested properties": a key can be mapped to another IJSONProperties.
  ///  Support "key navigation", so MyProps['key.subkey'] is equivalent to
  ///  MyProps['key']['subkey'] if MyProps['key'] contains a IJSONProperties.
  ///</summary>
  IJSONProperties = interface
    ['{93C26BFE-A8DA-4DF9-9AC8-0AF63B16E098}']
    function GetCount: Integer;
    function GetPair(const Index: Integer): TJSONPair;
    function GetChild(const Name: string): IJSONProperties;
    function GetValue(const Name: string): TValue;
    procedure SetValue(const Name: string; const Value: TValue);
    function GetFileName: string;
    procedure LoadFromFile(const AFileName:string='');
    procedure SaveToFile(const AFileName:string='');
    procedure LoadFromStream(const AStream : TStream);
    procedure SaveToStream(const AStream : TStream);
    function GetEnumerator: TJSONPairEnumerator;
    function AddPair(const Str: string; const Val: TJSONValue): TJSONObject;
    function RemovePair(const PairName: string): TJSONPair;
    function Clone: IJSONProperties;
    function ToString: string;
    function GetAsJSON: string;
    procedure SetAsJSON(const Value: string);
    function GetAsObject: TJSONObject;
    procedure SetAsObject(const Value: TJSONObject);
    function Contains(const Name: string): Boolean;
    property AsJSON: string read GetAsJSON write SetAsJSON;
    property AsObject: TJSONObject read GetAsObject write SetAsObject;
    property FileName: string read GetFileName;
    property Count: Integer read GetCount;
    property Pairs[const Index: Integer]: TJSONPair read GetPair;
    property Values[const Name: string]: TValue read GetValue write SetValue;default;
    property Childs[const Name: string]: IJSONProperties read GetChild;
  end;


implementation

end.
