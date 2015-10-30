unit Summer.DataSet;

interface

uses
  Data.DB,
  System.JSON;

type
  TDataSetHelper = class Helper for TDataSet
  public
    function ToJSON: TJSONObject;
  end;

implementation

uses
  Summer.JSON;

{ TDataSetHelper }

function TDataSetHelper.ToJSON: TJSONObject;
begin
  if Self = nil then
     Result := nil
  else
     Result := TJSON.DataSetToJSON(Self);
end;

end.
