unit SummerFW.DDD.QLTable;

interface

type
  TQLTable = Variant;
function QLTable(AClass: TClass; Alias: string = ''): TQLTable;
implementation

uses
  System.TypInfo,
  System.Sysutils,
  System.Variants,
  SummerFW.DDD.QL;

type
  TVarQLTableType = class(TInvokeableVariantType)
  private
    function HasProperty(const Name: string): Boolean;

  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    function GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean; override;
  end;

type
  TVarQLTableData = packed record
    VType: TVarType;
    Reserved1, Reserved2, Reserved3: Word;
    AClass: TClass;
    Alias: string;
  end;

var
  VarQLTableType: TVarQLTableType = nil;

function VarQLTable: TVarType;
begin
  Result := VarQLTableType.VarType;
end;

function QLTable(AClass: TClass; Alias: string = ''): TQLTable;
begin
  VarClear(Result);
  TVarQLTableData(Result).VType := VarQLTable;
  TVarQLTableData(Result).AClass := AClass;
  if Alias.IsEmpty then
    Alias := AClass.ClassName;
  TVarQLTableData(Result).Alias := Alias;
end;

procedure TVarQLTableType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TVarQLTableType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  SimplisticCopy(Dest, Source, Indirect);
end;

function TVarQLTableType.HasProperty(const Name: string): Boolean;
begin
  Result := True; // TODO using RTTI
end;

function TVarQLTableType.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
begin
//  Variant(dest) := QLCol(TVarQLTableData(V).Alias, Name).QLAst;
end;

initialization
  VarQLTableType := TVarQLTableType.Create;
finalization
  FreeAndNil(VarQLTableType);
end.
